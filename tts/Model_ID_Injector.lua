--[[ Tabletop Simulator Model ID Injector Script
     Written for Monumentum Cast Recruiter
     Date: Sunday, 7 June 2026
     
     INSTRUCTIONS:
     1. Attach this script to a dedicated token or object on your table.
     2. Create two Scripting Trigger Zones on your table:
        - Zone 1: Over the Characters Deck (that has IDs in GMNotes).
        - Zone 2: Over the Bag containing the raw 3D Models.
     3. Enter their GUIDs in CHARACTERS_ZONE_GUID and MODELS_BAG_ZONE_GUID below.
     4. Click the "Inject IDs to Models" button.
     5. The script will take each model out of the bag, clean its name, clear its description, assign its GMNotes, and return it.
     6. Once complete, you can right-click and save the Bag as a customized game component!
--]]

-- =============== CONFIGURATION GUIDs (REQUIRED) ===============
CHARACTERS_ZONE_GUID = "83f62b"  -- Zone containing the Characters Deck
MODELS_BAG_ZONE_GUID = "fe2114"  -- Zone containing the Raw Models Bag


local isProcessing = false

function onLoad()
    self.setName("Monumentum Model ID Injector")
    self.setDescription("Standalone utility to permanently inject Card IDs, clean nicknames, and strip stats from 3D models in a bag.")
    
    -- Render Inject Button
    self.createButton({
        click_function = "btnStartInjection",
        function_owner = self,
        label          = "Inject IDs to Models",
        position       = {0, 0.2, 0},
        rotation       = {0, 0, 0},
        width          = 2200,
        height         = 450,
        font_size      = 180,
        color          = {155/255, 89/255, 182/255}, -- Purple
        font_color     = {1, 1, 1}
    })
end

-- Trigger Injection Process
function btnStartInjection(obj, player_color, alt_click)
    local player = Player[player_color]
    if not player.host then
        broadcastToColor("Only the Host can run this utility.", player_color, {1, 0, 0})
        return
    end
    
    if isProcessing then
        broadcastToColor("An injection process is already running!", player_color, {1, 0, 0})
        return
    end
    
    startLuaCoroutine(self, "injectIdsCoroutine")
end

-- Helper: Clean model nickname by stripping trailing parenthesized numbers (e.g. "Obduron (6)" -> "Obduron")
function cleanModelName(name)
    if not name then return "" end
    -- Remove optional whitespace and trailing parentheses containing numbers
    local cleaned = name:gsub("%s*%(%d+%)", "")
    -- Trim any leading or trailing spaces
    cleaned = cleaned:match("^%s*(.-)%s*$") or cleaned
    return cleaned
end

-- Coroutine to safely handle async taking, updating, and returning
function injectIdsCoroutine()
    isProcessing = true
    
    local deck = getObjectFromZone(CHARACTERS_ZONE_GUID)
    local bag = getObjectFromZone(MODELS_BAG_ZONE_GUID)
    
    if not deck then
        broadcastToAll("Error: Could not find any Deck or Card in the Characters Trigger Zone.", {1, 0, 0})
        isProcessing = false
        return 1
    end
    
    if not bag or (bag.type ~= "Bag" and bag.type ~= "Infinite") then
        broadcastToAll("Error: Could not find any Bag in the Models Bag Trigger Zone.", {1, 0, 0})
        isProcessing = false
        return 1
    end
    
    broadcastToAll("Extracting Card ID mappings from the Characters Deck...", {0.9, 0.9, 0.2})
    
    -- 1. Extract Name-to-ID mapping from the Deck
    local nameToId = {}
    if deck.type == "Card" then
        local name = deck.getName()
        if name == "" or name == nil then name = deck.getDescription() end
        local id = deck.getGMNotes()
        if name and name ~= "" and id and id ~= "" then
            nameToId[name:lower()] = id
        end
    else
        for _, cardInfo in ipairs(deck.getObjects()) do
            local name = cardInfo.nickname
            if name == "" or name == nil then name = cardInfo.name end
            local id = cardInfo.gm_notes
            if name and name ~= "" and id and id ~= "" then
                nameToId[name:lower()] = id
            end
        end
    end
    
    -- 2. Build items list to process from the Bag
    local bagObjects = bag.getObjects()
    local itemsToProcess = {}
    local unmatchedModels = {}
    
    for _, bObj in ipairs(bagObjects) do
        local rawName = bObj.nickname
        if rawName == "" or rawName == nil then rawName = bObj.name end
        
        if rawName and rawName ~= "" then
            local modelName = cleanModelName(rawName)
            local matchedId = nameToId[modelName:lower()]
            if matchedId then
                table.insert(itemsToProcess, { 
                    guid = bObj.guid, 
                    rawName = rawName, 
                    cleanName = modelName, 
                    id = matchedId 
                })
            else
                table.insert(unmatchedModels, rawName)
            end
        end
    end
    
    -- Print out diagnostic information for unmatched models
    if #unmatchedModels > 0 then
        print("Diagnostic: " .. #unmatchedModels .. " models in the bag could not be matched with any card in the Characters Deck:")
        local maxPrint = math.min(#unmatchedModels, 15)
        for idx = 1, maxPrint do
            print("  - [Unmatched]: " .. unmatchedModels[idx])
        end
        if #unmatchedModels > maxPrint then
            print("  - ... and " .. (#unmatchedModels - maxPrint) .. " more unmatched models.")
        end
    end
    
    if #itemsToProcess == 0 then
        broadcastToAll("No matching models found in the bag that correspond to cards in the Characters Deck.", {1, 0.5, 0})
        isProcessing = false
        return 1
    end
    
    broadcastToAll("Found " .. #itemsToProcess .. " models inside the bag to update. Starting injection...", {0.1, 0.8, 0.1})
    
    -- 3. Sequentially take each model, clean name, clear description, set GM Notes, and return to Bag
    for i, item in ipairs(itemsToProcess) do
        local spawned = bag.takeObject({
            guid = item.guid,
            position = {x = 0, y = 15, z = 0}, -- High up to avoid clashing
            smooth = false,
            callback_function = function(obj)
                -- 3a. Inject database ID
                obj.setGMNotes(item.id)
                -- 3b. Rename to clean Name (removes "(6)" etc.)
                obj.setName(item.cleanName)
                -- 3c. Clear the description (removes prowess/fortitude stats)
                obj.setDescription("")
                
                Wait.frames(function()
                    if obj ~= nil and not obj.isDestroyed() and bag ~= nil and not bag.isDestroyed() then
                        bag.putObject(obj)
                    end
                end, 3)
            end
        })
        
        -- Yield execution to allow physics and callbacks to settle
        for f = 1, 15 do
            coroutine.yield(0)
        end
    end
    
    broadcastToAll("Success: " .. #itemsToProcess .. " models successfully updated! Re-named to clean names, cleared descriptions, and injected with Database IDs. Please save the updated Bag.", {0.1, 0.9, 0.1})
    isProcessing = false
    return 1
end

-- Helper: Retrieve Object from Trigger Zone
function getObjectFromZone(zoneGuid)
    if zoneGuid == "XXXXXX" or zoneGuid == "" or zoneGuid == nil then return nil end
    local zone = getObjectFromGUID(zoneGuid)
    if not zone then return nil end
    
    for _, obj in ipairs(zone.getObjects()) do
        if obj.type == "Deck" or obj.type == "Card" or obj.type == "Bag" or obj.type == "Infinite" then
            return obj
        end
    end
    return nil
end
