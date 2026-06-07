--[[ Tabletop Simulator Cast Loader Script
     Written for Monumentum Cast Recruiter
     Date: Sunday, 7 June 2026
     
     INSTRUCTIONS:
     1. Right-click your scripting token in TTS and select Scripting > Scripting Editor.
     2. Paste this entire LUA code into the editor.
     3. Create two Scripting Trigger Zones (Tools > Scripting Trigger Zone) on your table:
        - Place Zone 1 where the Characters & Talismans deck is kept.
        - Place Zone 2 where the Special Actions deck is kept.
     4. Paste the GUIDs of these trigger zones below in CHARACTERS_ZONE_GUID and SPECIALS_ZONE_GUID.
     5. Click Save & Play!
--]]

-- =============== CONFIGURATION GUIDs (REQUIRED) ===============
-- Place scripting zones over your decks on the table and enter their GUIDs below.
CHARACTERS_ZONE_GUID = "83f62b" -- Zone containing the Characters & Talismans deck
SPECIALS_ZONE_GUID   = "b609e4" -- Zone containing the Special Actions deck
MODELS_ZONE_GUID     = "fe2114" -- Zone containing the 3D Models Bag (Task 3)


-- =============== PLAYER LAYOUT CONFIGURATION ===============
-- [Zones Option] You can specify scripting zones where each player's characters should spawn on the table!
-- Leave them as "XXXXXX" and "YYYYYY" to use the fallback raw coordinates instead.
PLAYER_CONFIG = {
    [1] = { -- Player 1 (Red / Bottom)
        character_zone_guid = "e493d9", -- Zone where characters are spawned face up (DO NOT EDIT)
        special_zone_guid   = "XXXXXX", -- Zone where Special Actions are placed (Leave as "XXXXXX" to deal to hand instead)
        table_zone = { x = -15, y = 1.5, z = -5 },   -- Fallback coordinates if zone is not set
        special_dest = { x = -25, y = 2.0, z = -15 }, -- Fallback specials hand/dest area
        color = "Red"                                 -- TTS Player Seat color
    },
    [2] = { -- Player 2 (Blue / Top)
        character_zone_guid = "7faf07", -- Zone where characters are spawned face up (DO NOT EDIT)
        special_zone_guid   = "YYYYYY", -- Zone where Special Actions are placed
        table_zone = { x = 15, y = 1.5, z = 5 },
        special_dest = { x = 25, y = 2.0, z = 15 },
        color = "Blue"
    }
}

-- Temp spawning height offset to prevent collisions
SPAWN_HEIGHT_OFFSET = 3.0

-- Time (in seconds) to wait between card spawns inside active layout zones
ZONE_LAYOUT_DELAY = 0.3

-- =============== ONBOARDING UI CANVAS POSITIONING ===============
-- Adjusts the position, rotation, and scale of the Onboarding panel relative to the loader pad token.
-- Position coordinates: "X Y Z" (X: left/right, Y: height above token, Z: forward/backward)
ONBOARDING_UI_POSITION = "0 10 -15" -- Raised up (Y=10) and pulled closer to Red player (Z=-15) to prevent occlusion
ONBOARDING_UI_ROTATION = "90 180 0" -- Flat on the table facing the Red player directly (rotated 180 on Y)
ONBOARDING_UI_SCALE    = "0.1 0.1 0.1"

-- =============== ONBOARDING SCENARIOS CONFIGURATION ===============
-- Pre-configured cast lists for the learning scenarios (Task 5).
-- You can modify these lists of IDs to customize the onboarding scenarios.
ONBOARDING_SCENARIOS = {
    ["Flint"] = { -- Rhavlika Dominion
        [1] = {
            championId = "01RHA-01CHP-001",
            unitIdsRecruited = { ["01RHA-02FAM-002"] = 1, ["01RHA-02FAM-003"] = 1 }, -- Obduron, etc.
            talismanIdsEquipped = {},
            specialIds = { "01RHA-04SP-001", "01RHA-04SP-002" },
            dominion = "Rhavlika",
            champion = "Flint Dross"
        },
        [2] = {
            championId = "01RHA-01CHP-001",
            unitIdsRecruited = { ["01RHA-02FAM-002"] = 1, ["01RHA-02FAM-003"] = 1, ["01RHA-03MIN-004"] = 1 },
            talismanIdsEquipped = {},
            specialIds = { "01RHA-04SP-001", "01RHA-04SP-002" },
            dominion = "Rhavlika",
            champion = "Flint Dross"
        },
        [3] = {
            championId = "01RHA-01CHP-001",
            unitIdsRecruited = { ["01RHA-02FAM-002"] = 2, ["01RHA-02FAM-003"] = 1, ["01RHA-03MIN-004"] = 2 },
            talismanIdsEquipped = {},
            specialIds = { "01RHA-04SP-001", "01RHA-04SP-002", "01RHA-04SP-003" },
            dominion = "Rhavlika",
            champion = "Flint Dross"
        },
        [4] = {
            championId = "01RHA-01CHP-001",
            unitIdsRecruited = { ["01RHA-02FAM-002"] = 2, ["01RHA-02FAM-003"] = 2, ["01RHA-03MIN-004"] = 2 },
            talismanIdsEquipped = {},
            specialIds = { "01RHA-04SP-001", "01RHA-04SP-002", "01RHA-04SP-003" },
            dominion = "Rhavlika",
            champion = "Flint Dross"
        }
    },
    ["Ripple"] = { -- Iro-Si-Khar Dominion
        [1] = {
            championId = "02IRO-01CHP-005",
            unitIdsRecruited = { ["02IRO-02FAM-006"] = 1, ["02IRO-02FAM-007"] = 1 }, -- Ripple, Driplet, etc.
            talismanIdsEquipped = {},
            specialIds = { "02IRO-04SP-001", "02IRO-04SP-002" },
            dominion = "Iro-Si-Khar",
            champion = "Ripple"
        },
        [2] = {
            championId = "02IRO-01CHP-005",
            unitIdsRecruited = { ["02IRO-02FAM-006"] = 1, ["02IRO-02FAM-007"] = 1, ["02IRO-02FAM-008"] = 1 },
            talismanIdsEquipped = {},
            specialIds = { "02IRO-04SP-001", "02IRO-04SP-002" },
            dominion = "Iro-Si-Khar",
            champion = "Ripple"
        },
        [3] = {
            championId = "02IRO-01CHP-005",
            unitIdsRecruited = { ["02IRO-02FAM-006"] = 2, ["02IRO-02FAM-007"] = 1, ["02IRO-02FAM-008"] = 2 },
            talismanIdsEquipped = {},
            specialIds = { "02IRO-04SP-001", "02IRO-04SP-002", "02IRO-04SP-003" },
            dominion = "Iro-Si-Khar",
            champion = "Ripple"
        },
        [4] = {
            championId = "02IRO-01CHP-005",
            unitIdsRecruited = { ["02IRO-02FAM-006"] = 2, ["02IRO-02FAM-007"] = 2, ["02IRO-02FAM-008"] = 2 },
            talismanIdsEquipped = {},
            specialIds = { "02IRO-04SP-001", "02IRO-04SP-002", "02IRO-04SP-003" },
            dominion = "Iro-Si-Khar",
            champion = "Ripple"
        }
    },
    ["Lark"] = { -- Voisira Dominion
        [1] = {
            championId = "03VOI-01CHP-010",
            unitIdsRecruited = { ["03VOI-02FAM-011"] = 1, ["03VOI-02FAM-012"] = 1 },
            talismanIdsEquipped = {},
            specialIds = { "03VOI-04SP-001", "03VOI-04SP-002" },
            dominion = "Voisira",
            champion = "Lark"
        },
        [2] = {
            championId = "03VOI-01CHP-010",
            unitIdsRecruited = { ["03VOI-02FAM-011"] = 1, ["03VOI-02FAM-012"] = 1, ["03VOI-02FAM-013"] = 1 },
            talismanIdsEquipped = {},
            specialIds = { "03VOI-04SP-001", "03VOI-04SP-002" },
            dominion = "Voisira",
            champion = "Lark"
        },
        [3] = {
            championId = "03VOI-01CHP-010",
            unitIdsRecruited = { ["03VOI-02FAM-011"] = 2, ["03VOI-02FAM-012"] = 1, ["03VOI-03MIN-014"] = 2 },
            talismanIdsEquipped = {},
            specialIds = { "03VOI-04SP-001", "03VOI-04SP-002", "03VOI-04SP-003" },
            dominion = "Voisira",
            champion = "Lark"
        },
        [4] = {
            championId = "03VOI-01CHP-010",
            unitIdsRecruited = { ["03VOI-02FAM-011"] = 2, ["03VOI-02FAM-012"] = 2, ["03VOI-03MIN-014"] = 2 },
            talismanIdsEquipped = {},
            specialIds = { "03VOI-04SP-001", "03VOI-04SP-002", "03VOI-04SP-003" },
            dominion = "Voisira",
            champion = "Lark"
        }
    }
}


-- =============== WEBHOOK & GAME RECORD CONFIGURATION ===============
-- Global tables for tracking match state and logged actions
loadedCasts = {}          -- Loaded cast configurations keyed by player colour
specialActionsLog = {}    -- Chronological record of Special Actions played

-- Global parameter storage to pass arguments safely into the coroutine
local activeCoroutineParams = nil

-- Global lock to synchronize asynchronous card-cloning operations
local isCloning = false

function onLoad()
    print("Monumentum Cast Loader initialised.")
    self.setName("Monumentum Cast Loader")
    self.setDescription("Drafts your Cast lists on the table using zones.")
    
    -- Setup Onboarding XML UI dynamically (Task 5)
    setupXmlUi()
    
    -- Draw classic 3D Lua buttons flat on the token surface (Matching your exact tile style!)
    drawButtons()
end

function drawButtons()
    self.clearButtons()
    
    -- Load Player 1 Button (Red / Top) - Shifted forward (Z = -0.7)
    self.createButton({
        click_function = "btnLoadPlayer1",
        function_owner = self,
        label          = "Load Red Player",
        position       = {0, 0.2, -0.7},
        rotation       = {0, 0, 0},
        width          = 1600,
        height         = 350,
        font_size      = 170,
        color          = {192/255, 57/255, 43/255}, -- Red color
        font_color     = {1, 1, 1}
    })

    -- Load Player 2 Button (Blue / Middle) - Shifted backward (Z = 0)
    self.createButton({
        click_function = "btnLoadPlayer2",
        function_owner = self,
        label          = "Load Blue Player",
        position       = {0, 0.2, 0},
        rotation       = {0, 0, 0},
        width          = 1600,
        height         = 350,
        font_size      = 170,
        color          = {41/255, 128/255, 185/255}, -- Blue color
        font_color     = {1, 1, 1}
    })

    -- Launch Onboarding Menu Button (Purple / Bottom-most) - Shifted further backward (Z = 0.7)
    self.createButton({
        click_function = "btnToggleOnboarding",
        function_owner = self,
        label          = "Onboarding Menu",
        position       = {0, 0.2, 0.7},
        rotation       = {0, 0, 0},
        width          = 1600,
        height         = 350,
        font_size      = 170,
        color          = {155/255, 89/255, 182/255}, -- Purple color
        font_color     = {1, 1, 1}
    })
end

-- Load Player 1 (Red) Trigger
function btnLoadPlayer1(obj, player_color, alt_click)
    -- Native TTS Player Input Prompt Box (using Lua function callbacks)
    Player[player_color].showInputDialog("Player 1 (Red): Paste Cast JSON", "", function(text, color)
        submitCast1(text, color)
    end)
end

-- Load Player 2 (Blue) Trigger
function btnLoadPlayer2(obj, player_color, alt_click)
    Player[player_color].showInputDialog("Player 2 (Blue): Paste Cast JSON", "", function(text, color)
        submitCast2(text, color)
    end)
end

-- Native Submit Callbacks
function submitCast1(text, color)
    processPastedCast(1, Player[color], text)
end

-- Native Submit Callbacks
function submitCast2(text, color)
    processPastedCast(2, Player[color], text)
end

function processPastedCast(playerNum, player, jsonText)
    if jsonText == nil or jsonText == "" then
        broadcastToColor("Paste field was empty! Please copy the exported JSON from your cast builder.", player.color, {1,0,0})
        return
    end
    
    -- Parse JSON
    local success, castData = pcall(function() return JSON.decode(jsonText) end)
    if not success or not castData then
        broadcastToColor("Error: Invalid JSON format. Make sure you copied the entire exported text from your browser.", player.color, {1,0,0})
        return
    end
    
    -- Store the parsed cast data into our global tracking table
    local playerColour = PLAYER_CONFIG[playerNum].color
    loadedCasts[playerColour] = castData
    
    -- Store arguments in global parameter storage before running coroutine
    activeCoroutineParams = {playerNum = playerNum, clickerColor = player.color, castData = castData}
    
    -- Run Loader Coroutine
    startLuaCoroutine(self, "loadCastCoroutine")
end

-- Coroutine to handle step-by-step take, clone, and return operations smoothly
function loadCastCoroutine()
    -- Safely retrieve parameters from global storage (TTS coroutines do not accept arguments)
    local params = activeCoroutineParams
    activeCoroutineParams = nil -- Clear immediately
    
    if not params then return 1 end
    
    local playerNum = params.playerNum
    local clickerColor = params.clickerColor
    local castData = params.castData
    
    local config = PLAYER_CONFIG[playerNum]
    local spawnPos = config.special_dest -- Safe temporary spawn coordinates before dealing to hand
    
    broadcastToAll("Loading Cast for Player " .. playerNum .. " (" .. (castData.dominion or "Unknown") .. " - " .. (castData.champion or "Unknown") .. ")...", {0.1, 0.8, 0.1})
    
    -- Initial verification: Verify decks are strictly present in trigger zones before loading
    local initialCharDeck, initialSpecDeck = findDecks()
    if not initialCharDeck then
        broadcastToColor("Error: Could not find any Deck/Card in the Characters Trigger Zone. Check your CHARACTERS_ZONE_GUID.", clickerColor, {1,0,0})
        return 1
    end
    if not initialSpecDeck then
        broadcastToColor("Error: Could not find any Deck/Card in the Specials Trigger Zone. Check your SPECIALS_ZONE_GUID.", clickerColor, {1,0,0})
        return 1
    end
    
    -- 2. Extract and deal Champion to Hand
    local champName = castData.champion
    local champId = castData.championId
    if champName or champId then
        -- Fresh lookup to ensure valid Unity object references
        local charDeck, specDeck = findDecks()
        if not charDeck then
            broadcastToColor("Error: Characters deck vanished or was moved during loading.", clickerColor, {1,0,0})
            return 1
        end

        isCloning = true
        local success = cloneCardFromDeck(charDeck, champName, champId, spawnPos, {0, 180, 180}, true, config.color)
        if success then
            -- Wait for the asynchronous clone callback to finish returning the card before proceeding!
            while isCloning do
                coroutine.yield(0)
            end
            yieldSeconds(0.2)
        else
            isCloning = false
            print("Warning: Champion card not found: " .. (champName or "Unnamed") .. " / " .. (champId or "No ID"))
        end
    end
    
    -- 3. Extract Units, deal 1 Card to Hand, and spawn recruited Models
    local modelsBag = getBagFromZone(MODELS_ZONE_GUID)
    if not modelsBag then
        print("Warning: Models Bag not found in trigger zone " .. MODELS_ZONE_GUID .. ". Models will not be spawned.")
    end

    local unitIndex = 0

    -- 3a. Spawn Champion Standee (Task 3 Improvement - Champion as Character 1)
    local champId = castData.championId
    if champId and modelsBag then
        unitIndex = unitIndex + 1
        local spawnTarget = getSpawnPositionForModels(config)
        
        local xStart = (config.color == "Red") and -23.5 or 23.5
        local zStart = (config.color == "Red") and -5.0 or 5.0
        local xDirection = (config.color == "Red") and 1 or -1
        local zDirection = (config.color == "Red") and -1 or 1
        local zSpacing = 2.5
        
        local unitSpawnPos = {
            x = xStart,
            y = spawnTarget.y,
            z = zStart + (unitIndex * zSpacing * zDirection)
        }

        isCloning = true
        -- Spawn exactly 1 copy of the Champion standee
        local modelSuccess = cloneModelFromBag(modelsBag, champId, 1, unitSpawnPos, {0, 90, 0}, xDirection, false)
        if modelSuccess then
            while isCloning do
                coroutine.yield(0)
            end
            yieldSeconds(0.2)
        else
            isCloning = false
        end
    end

    -- 3b. Loop and spawn recruited Unit Standees
    if castData.unitIdsRecruited and next(castData.unitIdsRecruited) then
        for unitId, qty in pairs(castData.unitIdsRecruited) do
            unitIndex = unitIndex + 1
            local charDeck, specDeck = findDecks()
            if not charDeck then
                print("Error: Characters deck vanished during units loop.")
                break
            end

            -- Clone Card to Hand
            isCloning = true
            local success = cloneCardFromDeck(charDeck, "", unitId, spawnPos, {0, 180, 180}, true, config.color)
            if success then
                while isCloning do
                    coroutine.yield(0)
                end
                yieldSeconds(0.2)
            else
                isCloning = false
                print("Warning: Unit card ID not found: " .. unitId)
            end

            -- Clone 3D Models to Layout Zone
            if modelsBag and qty and qty > 0 then
                local spawnTarget = getSpawnPositionForModels(config)
                
                local xStart = (config.color == "Red") and -23.5 or 23.5
                local zStart = (config.color == "Red") and -5.0 or 5.0
                local xDirection = (config.color == "Red") and 1 or -1
                local zDirection = (config.color == "Red") and -1 or 1
                local zSpacing = 2.5
                
                local unitSpawnPos = {
                    x = xStart,
                    y = spawnTarget.y,
                    z = zStart + (unitIndex * zSpacing * zDirection)
                }

                isCloning = true
                -- Rotate standees by 90 degrees around Y so they face the players directly
                local modelSuccess = cloneModelFromBag(modelsBag, unitId, qty, unitSpawnPos, {0, 90, 0}, xDirection, false)
                if modelSuccess then
                    while isCloning do
                        coroutine.yield(0)
                    end
                    yieldSeconds(0.2)
                else
                    isCloning = false
                end
            end
        end
    end

    -- 3c. Auto-Spawn 12 Stacked Minions (Driplet / Huskling Lot for Iro-Si-Khar & Ahéserec)
    if castData.dominion == "Iro-Si-Khar" or castData.dominion == "Ahéserec" or castData.dominion == "Aheserec" then
        if modelsBag then
            unitIndex = unitIndex + 1
            local minionId = (castData.dominion == "Iro-Si-Khar") and "02IRO-03MIN-009" or "05AHS-03MIN-022"
            local spawnTarget = getSpawnPositionForModels(config)
            
            local xStart = (config.color == "Red") and -23.5 or 23.5
            local zStart = (config.color == "Red") and -5.0 or 5.0
            local xDirection = (config.color == "Red") and 1 or -1
            local zDirection = (config.color == "Red") and -1 or 1
            local zSpacing = 2.5
            
            local minionSpawnPos = {
                x = xStart,
                y = spawnTarget.y,
                z = zStart + (unitIndex * zSpacing * zDirection)
            }

            isCloning = true
            -- Spawn exactly 12 copies and stack them vertically (isStacked = true)
            local modelSuccess = cloneModelFromBag(modelsBag, minionId, 12, minionSpawnPos, {0, 90, 0}, xDirection, true)
            if modelSuccess then
                while isCloning do
                    coroutine.yield(0)
                end
                yieldSeconds(0.2)
            else
                isCloning = false
            end
        end
    end
    
    -- 4. Extract and deal Talismans to Hand (Task 4)
    if castData.talismanIdsEquipped and next(castData.talismanIdsEquipped) then
        for talId, attachment in pairs(castData.talismanIdsEquipped) do
            local charDeck, specDeck = findDecks()
            if not charDeck then
                print("Error: Characters deck vanished during talismans loop.")
                break
            end

            isCloning = true
            local success = cloneCardFromDeck(charDeck, "", talId, spawnPos, {0, 180, 180}, true, config.color)
            if success then
                while isCloning do
                    coroutine.yield(0)
                end
                yieldSeconds(0.2)
            else
                isCloning = false
                print("Warning: Talisman card ID not found: " .. talId)
            end
        end
    end
    
    -- 4.5 Auto-Summon Minions (Task 1)
    if castData.dominion == "Iro-Si-Khar" or castData.dominion == "Ahéserec" or castData.dominion == "Aheserec" then
        local minionName = (castData.dominion == "Iro-Si-Khar") and "Driplet" or "Huskling"
        local minionId = (castData.dominion == "Iro-Si-Khar") and "02IRO-03MIN-009" or "05AHS-03MIN-022"
        local charDeck, specDeck = findDecks()
        if charDeck then
            isCloning = true
            local success = cloneCardFromDeck(charDeck, minionName, minionId, spawnPos, {0, 180, 180}, true, config.color)
            if success then
                while isCloning do
                    coroutine.yield(0)
                end
                yieldSeconds(0.2)
            else
                isCloning = false
                print("Warning: Auto-summon minion card not found: " .. minionName .. " (" .. minionId .. ")")
            end
        end
    end
    
    -- 5. Extract and deal Special Action cards to player's Hand (Task 4)
    if castData.specialIds and #castData.specialIds > 0 then
        for i, specId in ipairs(castData.specialIds) do
            local charDeck, specDeck = findDecks()
            if not specDeck then
                print("Error: Specials deck vanished during specials loop.")
                break
            end

            isCloning = true
            local success = cloneCardFromDeck(specDeck, "", specId, spawnPos, {0, 180, 180}, true, config.color)
            if success then
                while isCloning do
                    coroutine.yield(0)
                end
                yieldSeconds(0.2)
            else
                isCloning = false
                print("Warning: Special card ID not found: " .. specId)
            end
        end
    end
    
    broadcastToAll("Cast for Player " .. playerNum .. " loaded successfully!", {0.1, 0.9, 0.1})
    return 1
end

-- Retrieve Deck/Card from Scripting Zone
function getDeckFromZone(zoneGuid)
    if zoneGuid == "XXXXXX" or zoneGuid == "" or zoneGuid == nil then return nil end
    local zone = getObjectFromGUID(zoneGuid)
    if not zone then return nil end
    
    for _, obj in ipairs(zone.getObjects()) do
        if obj.type == "Deck" or obj.type == "Card" then
            return obj
        end
    end
    return nil
end

-- Find the Characters and Specials decks strictly from the designated Scripting Zones
function findDecks()
    local charDeck = getDeckFromZone(CHARACTERS_ZONE_GUID)
    local specDeck = getDeckFromZone(SPECIALS_ZONE_GUID)
    
    if not charDeck then
        print("Error: Could not find any Deck or Card inside the Characters Trigger Zone (" .. CHARACTERS_ZONE_GUID .. ").")
    end
    if not specDeck then
        print("Error: Could not find any Deck or Card inside the Specials Trigger Zone (" .. SPECIALS_ZONE_GUID .. ").")
    end
    
    return charDeck, specDeck
end

-- Core Function: Clones a specific card by name OR unique ID (GM Notes) from a deck, and drops original back
function cloneCardFromDeck(deck, cardName, cardId, targetPos, targetRot, isSpecial, playerColor)
    -- Handle single Card container vs Deck container
    if deck.type == "Card" then
        local matched = false
        local objId = deck.getGMNotes()
        if cardId ~= nil and cardId ~= "" and objId == cardId then
            matched = true
        else
            local objName = deck.getName()
            if objName == "" or objName == nil then objName = deck.getDescription() end
            if objName:lower() == cardName:lower() then
                matched = true
            end
        end
        
        if matched then
            local clonedObj = deck.clone({
                position = {x = targetPos.x, y = targetPos.y, z = targetPos.z},
                rotation = targetRot
            })
            if isSpecial then
                Wait.frames(function()
                    if clonedObj ~= nil and not clonedObj.isDestroyed() then
                        clonedObj.deal(1, playerColor)
                    end
                end, 2)
            end
            -- Release coroutine immediately for single cards
            isCloning = false
            return true
        end
        isCloning = false
        return false
    end

    -- Standard Deck search
    for _, objInfo in ipairs(deck.getObjects()) do
        local matched = false
        local objId = objInfo.gm_notes
        
        if cardId ~= nil and cardId ~= "" and objId == cardId then
            matched = true
        else
            local objName = objInfo.nickname
            if objName == "" or objName == nil then objName = objInfo.name end
            if objName:lower() == cardName:lower() then
                matched = true
            end
        end
        
        if matched then
            -- Take original card out briefly
            local spawnedCard = deck.takeObject({
                index = objInfo.index,
                position = {x = targetPos.x, y = targetPos.y + SPAWN_HEIGHT_OFFSET, z = targetPos.z},
                rotation = targetRot,
                smooth = false,
                callback_function = function(cardObj)
                    -- Clone it to its exact destination
                    local clonedObj = cardObj.clone({
                        position = {x = targetPos.x, y = targetPos.y, z = targetPos.z},
                        rotation = targetRot
                    })
                    
                    -- If special action, deal directly into the player's Hand after a small frame delay
                    if isSpecial then
                        Wait.frames(function()
                            if clonedObj ~= nil and not clonedObj.isDestroyed() then
                                clonedObj.deal(1, playerColor)
                            end
                        end, 2)
                    end
                    
                    -- Return original card to the deck after a 3-frame delay to let clone spawn safely first
                    Wait.frames(function()
                        local ok, err = pcall(function()
                            if cardObj ~= nil and not cardObj.isDestroyed() and deck ~= nil and not deck.isDestroyed() then
                                -- Instant teleport back to the deck's physical position to prevent physical drift/clashing across the table!
                                cardObj.setPosition(deck.getPosition())
                                deck.putObject(cardObj)
                            end
                        end)
                        if not ok then
                            print("Error returning card to deck: " .. tostring(err))
                        end
                        -- ALWAYS release the coroutine thread lock, even if putObject failed!
                        isCloning = false
                    end, 3)
                end
            })
            return true
        end
    end
    isCloning = false
    return false
end

-- Helper function to yield coroutine execution for TTS
function yieldSeconds(seconds)
    local start = os.clock()
    while os.clock() - start < seconds do
        coroutine.yield(0)
    end
end

-- ================= END GAME API & WEBHOOK SUPPORT =================

-- Global function to record a Special Action played during the game
-- This can be called from individual card scripts, trigger zones, or manual inputs
function logSpecialAction(playerColour, cardName, cardId)
    local entry = {
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"), -- UTC timestamp in ISO 8601 format
        player = playerColour,
        name = cardName,
        id = cardId
    }
    table.insert(specialActionsLog, entry)
    print("Logged Special Action: " .. tostring(cardName) .. " (" .. tostring(cardId) .. ") played by " .. tostring(playerColour))
end

-- Exposes match data as a JSON string to avoid Tabletop Simulator cross-script sandboxing/ownership errors
function getMatchDataJson()
    local matchData = {
        loadedCasts = loadedCasts,
        specialActionsLog = specialActionsLog
    }
    return JSON.encode(matchData)
end

-- ================= TASK 3 MODEL SPAWNING HELPERS =================

-- Retrieve Bag from Scripting Zone
function getBagFromZone(zoneGuid)
    if zoneGuid == "XXXXXX" or zoneGuid == "" or zoneGuid == nil then return nil end
    local zone = getObjectFromGUID(zoneGuid)
    if not zone then return nil end
    
    for _, obj in ipairs(zone.getObjects()) do
        if obj.type == "Bag" or obj.type == "Infinite" then
            return obj
        end
    end
    return nil
end

-- Get central physical spawn position for models
function getSpawnPositionForModels(config)
    if config.character_zone_guid and config.character_zone_guid ~= "XXXXXX" and config.character_zone_guid ~= "" then
        local zone = getObjectFromGUID(config.character_zone_guid)
        if zone then
            return zone.getPosition()
        end
    end
    return config.table_zone
end

-- Core Function: Clones a specific model by ID from a bag N times, arranging them to the right, and returns original to the bag
function cloneModelFromBag(bag, modelId, qty, targetPos, targetRot, xDirection, isStacked)
    if not bag then return false end
    
    for _, objInfo in ipairs(bag.getObjects()) do
        if objInfo.gm_notes == modelId then
            -- Take original model out briefly
            local spawnedModel = bag.takeObject({
                guid = objInfo.guid,
                position = {x = targetPos.x, y = targetPos.y + SPAWN_HEIGHT_OFFSET, z = targetPos.z},
                rotation = targetRot,
                smooth = false,
                callback_function = function(modelObj)
                    -- Clone it qty times
                    for q = 1, qty do
                        local modelPos
                        if isStacked then
                            -- Stack vertically: same X and Z, increased Y height per copy
                            modelPos = {
                                x = targetPos.x,
                                y = targetPos.y + ((q - 1) * 0.4), -- perfect vertical stack height spacing
                                z = targetPos.z
                            }
                        else
                            -- Place models: first copy at targetPos.x, subsequent copies build inwards
                            modelPos = {
                                x = targetPos.x + ((q - 1) * 1.8 * xDirection),
                                y = targetPos.y,
                                z = targetPos.z
                            }
                        end
                        
                        local clonedObj = modelObj.clone({
                            position = modelPos,
                            rotation = targetRot
                        })
                    end
                    
                    -- Return original model to the bag after a small frame delay to let clones spawn safely first
                    Wait.frames(function()
                        local ok, err = pcall(function()
                            if modelObj ~= nil and not modelObj.isDestroyed() and bag ~= nil and not bag.isDestroyed() then
                                modelObj.setPosition(bag.getPosition())
                                bag.putObject(modelObj)
                            end
                        end)
                        if not ok then
                            print("Error returning model to bag: " .. tostring(err))
                        end
                        isCloning = false
                    end, 3)
                end
            })
            return true
        end
    end
    isCloning = false
    return false
end

-- ================= TASK 5 NATIVE ONBOARDING FEATURES =================

-- Onboarding XML UI State
selectedChamp = "Flint"
selectedScenario = 1
selectedPlayer = 1

-- Build the screen-space XML panel dynamically on load (Task 5 Improvements)
function setupXmlUi()
    -- Format with our positioning variables to let users adjust them effortlessly at the top of the script
    local xml = string.format([[
<Canvas position="%s" rotation="%s" scale="%s" width="450" height="300">
    <Defaults>
        <Button class="start-btn" width="180" height="40" fontSize="16" color="#2ecc71" textColor="#ffffff" fontStyle="Bold" />
        <Button class="close-btn" width="100" height="40" fontSize="16" color="#95a5a6" textColor="#ffffff" />
        <Text class="header" fontSize="18" fontStyle="Bold" color="#ffffff" alignment="Inferred" />
    </Defaults>
    <Panel id="onboardPanel" active="false" width="450" height="300" color="#2c3e50" padding="20" showAnimation="SlideIn_Bottom" hideAnimation="SlideOut_Bottom">
        <VerticalLayout spacing="15">
            <Text class="header" alignment="MiddleCenter">Monumentum Onboarding Setup</Text>
            
            <HorizontalLayout spacing="10" height="35">
                <Text color="#ffffff" fontSize="15" alignment="MiddleLeft">Champion:</Text>
                <Dropdown id="ddChamp" onValueChanged="onChampSelected" width="220" height="30">
                    <option selected="true">Flint</option>
                    <option>Ripple</option>
                    <option>Lark</option>
                </Dropdown>
            </HorizontalLayout>
            
            <HorizontalLayout spacing="10" height="35">
                <Text color="#ffffff" fontSize="15" alignment="MiddleLeft">Scenario:</Text>
                <Dropdown id="ddScenario" onValueChanged="onScenarioSelected" width="220" height="30">
                    <option selected="true">Scenario 1</option>
                    <option>Scenario 2</option>
                    <option>Scenario 3</option>
                    <option>Scenario 4</option>
                </Dropdown>
            </HorizontalLayout>

            <HorizontalLayout spacing="10" height="35">
                <Text color="#ffffff" fontSize="15" alignment="MiddleLeft">Load For:</Text>
                <Dropdown id="ddPlayer" onValueChanged="onPlayerSelected" width="220" height="30">
                    <option selected="true">Red Player</option>
                    <option>Blue Player</option>
                </Dropdown>
            </HorizontalLayout>
            
            <HorizontalLayout spacing="20" height="50" alignment="MiddleCenter">
                <Button class="start-btn" onClick="btnSpawnOnboarding">LOAD SCENARIO</Button>
                <Button class="close-btn" onClick="btnHideOnboard">CLOSE</Button>
            </HorizontalLayout>
        </VerticalLayout>
    </Panel>
</Canvas>
]], ONBOARDING_UI_POSITION, ONBOARDING_UI_ROTATION, ONBOARDING_UI_SCALE)
    self.UI.setXml(xml)
end

-- Toggles Onboarding UI visibility
function btnToggleOnboarding(obj, player_color, alt_click)
    local active = self.UI.getAttribute("onboardPanel", "active")
    if active == "true" then
        self.UI.setAttribute("onboardPanel", "active", "false")
    else
        self.UI.setAttribute("onboardPanel", "active", "true")
    end
end

-- Closes Onboarding UI
function btnHideOnboard(player, value, id)
    self.UI.setAttribute("onboardPanel", "active", "false")
end

-- Dropdown Selection Callbacks
function onChampSelected(player, value, id)
    selectedChamp = value
end

function onScenarioSelected(player, value, id)
    local num = value:match("%d+")
    selectedScenario = tonumber(num) or 1
end

function onPlayerSelected(player, value, id)
    if value == "Red Player" then
        selectedPlayer = 1
    else
        selectedPlayer = 2
    end
end

-- Submits selected onboarding configurations to the main coroutine loader
function btnSpawnOnboarding(player, value, id)
    if not player.host then
        broadcastToColor("Only the Host can load onboarding scenarios.", player.color, {1, 0, 0})
        return
    end
    
    local scenarioData = ONBOARDING_SCENARIOS[selectedChamp][selectedScenario]
    if not scenarioData then
        broadcastToColor("Error: Scenario not configured yet.", player.color, {1, 0, 0})
        return
    end
    
    -- Hide Onboarding Menu
    self.UI.setAttribute("onboardPanel", "active", "false")
    
    -- Pass scenario serialized configuration directly into our robust loading pipeline!
    processPastedCast(selectedPlayer, player, JSON.encode(scenarioData))
end
