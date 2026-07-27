--[[ Tabletop Simulator Font Controller Script
     Written for Monumentum Cast Recruiter
     Date: Sunday, 7 June 2026
     
     INSTRUCTIONS:
     1. Attach this script to a dedicated Font Controller token/object on your table.
     2. Create a Scripting Trigger Zone (Tools > Scripting Trigger Zone) over where the Font Deck is kept.
     3. Enter the GUID of this scripting zone below in FONT_ZONE_GUID.
     4. Click Save & Play!
--]]

-- =============== CONFIGURATION GUIDs (REQUIRED) ===============
-- GUID of the Scripting Zone containing the Font deck/tiles.
FONT_ZONE_GUID = "547581"

-- =============== PHYSICAL LAYOUT CONFIGURATION ===============
SPACING = 4.0 -- Spacing distance between tiles on the table grid
START_POS = { x = -10, y = 0.21, z = 10 } -- Top-left corner spawn coordinate
-- Fonts sit on top of the path tiles, so they spawn slightly above the grid plane.
-- Must match the lift used by deployScenarioMap() in TTS_Loader.lua.
FONT_Y_OFFSET = 0.05

-- =============== STATE VARIABLES & LAYOUTS ===============
LAYOUTS = { "Orthogonal", "Diagonal", "Spiral" }
currentLayoutIndex = 1
deployedFonts = {}
savedFontDeckJSON = nil

-- Coordinates of the 5 fonts relative to the grid start (col, row).
-- Row increases downwards (decreases Z), Col increases rightwards (increases X)
LAYOUT_COORDINATES = {
    -- 1. Orthogonal (Cross pattern) - Index 1 is always the center
    { {2.5, 2.5}, {0.5, 2.5}, {2.5, 0.5}, {4.5, 2.5}, {2.5, 4.5} },
    -- 2. Diagonal (X pattern)
    { {2.5, 2.5}, {0.5, 0.5}, {4.5, 0.5}, {4.5, 4.5}, {0.5, 4.5} },
    -- 3. Spiral (Offset path pattern)
    { {2.5, 2.5}, {1.5, 0.5}, {4.5, 1.5}, {3.5, 4.5}, {0.5, 3.5} }
}

function onLoad()
    print("Monumentum Font Controller initialised.")
    self.setName("Monumentum Font Controller")
    self.setDescription("Deploys and cycles Font tiles dynamically on the board.")
    
    -- Draw the 3D control buttons flat on the token surface
    drawButtons()
end

-- Renders the 3D buttons on top of the tile
function drawButtons()
    self.clearButtons()
    
    local isDeployed = checkDeployed()
    local btn1Label = isDeployed and "Recall Fonts" or "Deploy Fonts"
    local btn1Color = isDeployed and {231/255, 76/255, 60/255} or {46/255, 204/255, 113/255} -- Red / Green
    
    -- Button 1: Deploy / Recall (Top half)
    self.createButton({
        click_function = "btnToggleFonts",
        function_owner = self,
        label          = btn1Label,
        position       = {0, 0.2, -0.55},
        rotation       = {0, 0, 0},
        width          = 1600,
        height         = 350,
        font_size      = 170,
        color          = btn1Color,
        font_color     = {1, 1, 1}
    })

    -- Button 2: Cycle Layout (Bottom half)
    self.createButton({
        click_function = "btnCycleLayout",
        function_owner = self,
        label          = "Layout: " .. LAYOUTS[currentLayoutIndex],
        position       = {0, 0.2, 0.55},
        rotation       = {0, 0, 0},
        width          = 1600,
        height         = 350,
        font_size      = 170,
        color          = {52/255, 73/255, 94/255}, -- Dark Slate / Navy Blue
        font_color     = {1, 1, 1}
    })
end

-- Checks if there are currently valid active font tiles deployed on the table
function checkDeployed()
    local count = 0
    for _, font in pairs(deployedFonts) do
        if font ~= nil and not font.isDestroyed() then
            count = count + 1
        end
    end
    return count > 0
end

-- Action Handler: Toggles Deploying or Recalling/Resetting Font Tiles
function btnToggleFonts(obj, player_color, alt_click)
    local player = Player[player_color]
    if not player.host then
        broadcastToColor("Only the Host can deploy or recall fonts.", player_color, {1, 0, 0})
        return
    end

    local isDeployed = checkDeployed()
    local zone = getObjectFromGUID(FONT_ZONE_GUID)
    if zone == nil then
        broadcastToColor("Error: Font Scripting Zone not found! Check your FONT_ZONE_GUID config.", player_color, {1, 0, 0})
        return
    end

    if isDeployed then
        -- RECALL LOGIC (The Digital Reset)
        broadcastToAll("Recalling and resetting deployed Font tiles...", {0.9, 0.9, 0.2})
        
        -- 1. Delete all deployed font tiles
        for _, font in pairs(deployedFonts) do
            if font ~= nil and not font.isDestroyed() then
                destroyObject(font)
            end
        end
        deployedFonts = {} 
        
        -- 2. Clear any leftover/stray font cards/decks inside the zone to prevent stack duplication
        clearZone(zone)
        
        -- 3. Respawn the pristine deck slightly above the table surface
        if savedFontDeckJSON ~= nil then
            local zonePos = zone.getPosition()
            spawnObjectJSON({
                json = savedFontDeckJSON,
                position = {zonePos.x, START_POS.y + 0.2, zonePos.z}
            })
        else
            print("Warning: Pristine deck JSON was not cached. Cannot auto-respawn deck.")
        end
        
        drawButtons()
        return
    else
        -- DEPLOY LOGIC
        local deck = findDeckInZone(zone)
        if deck == nil then
            broadcastToColor("Error: No Font deck found in the designated Scripting Zone!", player_color, {1, 0, 0})
            return
        end

        local cards = deck.getObjects()
        if #cards ~= 5 then
            broadcastToColor("Error: The font deck must contain exactly 5 tiles (found " .. #cards .. ").", player_color, {1, 0, 0})
            return
        end
        
        broadcastToAll("Deploying 5 Font tiles in '" .. LAYOUTS[currentLayoutIndex] .. "' configuration...", {0.1, 0.8, 0.1})
        
        -- Save the pristine state of the deck before taking tiles
        savedFontDeckJSON = deck.getJSON()

        local coords = LAYOUT_COORDINATES[currentLayoutIndex]

        for i = 1, 5 do
            local targetPos = {
                x = START_POS.x + (coords[i][1] * SPACING),
                y = START_POS.y + FONT_Y_OFFSET,
                z = START_POS.z - (coords[i][2] * SPACING)
            }

            local currentRot = deck.getRotation()
            local specificIndex = i 
            
            deck.takeObject({
                position = targetPos,
                rotation = currentRot,
                smooth   = true,
                callback_function = function(obj) 
                    obj.setLock(true) 
                    deployedFonts[specificIndex] = obj
                    
                    -- Redraw UI on final spawn to reflect correct 'Recall' state
                    if i == 5 then
                        Wait.time(function() drawButtons() end, 0.5)
                    end
                end
            })
        end
    end
end

-- Action Handler: Cycles layout configuration index and moves deployed fonts smoothly
function btnCycleLayout(obj, player_color, alt_click)
    local player = Player[player_color]
    if not player.host then
        broadcastToColor("Only the Host can change the font layout.", player_color, {1, 0, 0})
        return
    end

    currentLayoutIndex = currentLayoutIndex + 1
    if currentLayoutIndex > #LAYOUTS then
        currentLayoutIndex = 1
    end
    
    print("Changed Font layout configuration to: " .. LAYOUTS[currentLayoutIndex])
    drawButtons()

    -- If fonts are currently deployed, smoothly reposition them to the new layout
    moveDeployedFonts()
end

-- Repositions deployed font tiles on the table smoothly
function moveDeployedFonts()
    local count = 0
    for _, font in pairs(deployedFonts) do
        if font ~= nil and not font.isDestroyed() then 
            count = count + 1 
        end
    end
    -- Must have exactly 5 deployed tiles to execute layout shift
    if count ~= 5 then return end

    local coords = LAYOUT_COORDINATES[currentLayoutIndex]
    
    for i = 1, 5 do
        local fontTile = deployedFonts[i]
        
        if fontTile ~= nil and not fontTile.isDestroyed() then
            -- Unlock briefly to allow smooth translation physics
            fontTile.setLock(false)
            
            local targetPos = {
                x = START_POS.x + (coords[i][1] * SPACING),
                y = START_POS.y + FONT_Y_OFFSET,
                z = START_POS.z - (coords[i][2] * SPACING)
            }

            fontTile.setPositionSmooth(targetPos, false, true)
            
            -- Lock back down once translation completes
            Wait.time(function()
                if fontTile ~= nil and not fontTile.isDestroyed() then
                    fontTile.setLock(true)
                end
            end, 1.5)
        end
    end
end

-- Helper: Locates a Deck container inside a Scripting Zone
function findDeckInZone(zone)
    if zone == nil then return nil end
    for _, obj in ipairs(zone.getObjects()) do
        if obj.type == "Deck" then return obj end
    end
    return nil
end

-- Helper: Deletes any Decks/Cards left in the zone during recall
function clearZone(zone)
    if zone == nil then return end
    for _, obj in ipairs(zone.getObjects()) do
        if obj.type == "Deck" or obj.type == "Card" then
            destroyObject(obj)
        end
    end
end
