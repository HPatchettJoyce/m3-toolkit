--[[ Tabletop Simulator Grid Controller Script
     Written for Monumentum Cast Recruiter
     Date: Sunday, 7 June 2026
     
     INSTRUCTIONS:
     1. Attach this script to a dedicated Grid Controller token/object on your table.
     2. Create a Scripting Trigger Zone (Tools > Scripting Trigger Zone) over where the Path Tiles Deck is kept.
     3. Enter the GUID of this scripting zone below in TILE_ZONE_GUID.
     4. Click Save & Play!
--]]

-- =============== CONFIGURATION GUIDs (REQUIRED) ===============
-- GUID of the Scripting Zone containing the Path/Grid deck/tiles.
TILE_ZONE_GUID = "193b90"

-- =============== PHYSICAL LAYOUT CONFIGURATION ===============
GRID_COLS = 6 -- Number of columns in the full map grid
GRID_ROWS = 6 -- Number of rows in the full map grid
SPACING = 4.0 -- Spacing distance between tiles on the table grid
START_POS = { x = -10, y = 0.21, z = 10 } -- Top-left corner spawn coordinate

-- =============== STATE VARIABLES ===============
deployedTiles = {}
savedDeckJSON = nil

function onLoad()
    print("Monumentum Grid Controller initialised.")
    self.setName("Monumentum Grid Controller")
    self.setDescription("Deploys a randomized 6x6 grid of path tiles.")
    
    -- Seed the random number generator
    math.randomseed(os.time())
    
    -- Draw the 3D control button flat on the token surface
    drawButtons()
end

-- Renders the 3D button on top of the tile
function drawButtons()
    self.clearButtons()
    
    local isDeployed = checkDeployed()
    local btnLabel = isDeployed and "Recall Board" or "Construct Board"
    local btnColor = isDeployed and {231/255, 76/255, 60/255} or {41/255, 128/255, 185/255} -- Red / Blue
    
    self.createButton({
        click_function = "btnToggleBoard",
        function_owner = self,
        label          = btnLabel,
        position       = {0, 0.2, 0},
        rotation       = {0, 0, 0},
        width          = 2200,
        height         = 400,
        font_size      = 180,
        color          = btnColor,
        font_color     = {1, 1, 1}
    })
end

-- Checks if there are currently valid active board tiles deployed on the table
function checkDeployed()
    local count = 0
    for _, tile in pairs(deployedTiles) do
        if tile ~= nil and not tile.isDestroyed() then
            count = count + 1
        end
    end
    return count > 0
end

-- Action Handler: Toggles constructing or recalling/resetting the 6x6 path board
function btnToggleBoard(obj, player_color, alt_click)
    local player = Player[player_color]
    if not player.host then
        broadcastToColor("Only the Host can construct or recall the board.", player_color, {1, 0, 0})
        return
    end

    local isDeployed = checkDeployed()
    local zone = getObjectFromGUID(TILE_ZONE_GUID)
    if zone == nil then
        broadcastToColor("Error: Grid Scripting Zone not found! Check your TILE_ZONE_GUID config.", player_color, {1, 0, 0})
        return
    end

    if isDeployed then
        -- RECALL LOGIC (The Digital Reset)
        broadcastToAll("Recalling and resetting deployed path tiles...", {0.9, 0.9, 0.2})
        
        -- 1. Delete all deployed path tiles
        for _, tile in pairs(deployedTiles) do
            if tile ~= nil and not tile.isDestroyed() then
                destroyObject(tile)
            end
        end
        deployedTiles = {}
        
        -- 2. Clear any leftover/stray path cards/decks inside the zone to prevent stack duplication
        clearZone(zone)
        
        -- 3. Respawn the pristine deck slightly above the table surface
        if savedDeckJSON ~= nil then
            local zonePos = zone.getPosition()
            spawnObjectJSON({
                json = savedDeckJSON,
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
            broadcastToColor("Error: No Path/Grid deck found in the designated Scripting Zone!", player_color, {1, 0, 0})
            return
        end

        local cards = deck.getObjects()
        local neededCount = GRID_COLS * GRID_ROWS
        if #cards < neededCount then
            broadcastToColor("Error: The deck in the zone only has " .. #cards .. " cards. You need at least " .. neededCount .. ".", player_color, {1, 0, 0})
            return
        end
        
        broadcastToAll("Constructing randomized 6x6 game board...", {0.1, 0.8, 0.1})
        
        -- Save the pristine state of the deck before taking tiles
        savedDeckJSON = deck.getJSON()

        local count = 0
        for row = 0, GRID_ROWS - 1 do
            for col = 0, GRID_COLS - 1 do
                count = count + 1
                if count > neededCount then break end

                local targetPos = {
                    x = START_POS.x + (col * SPACING),
                    y = START_POS.y,
                    z = START_POS.z - (row * SPACING) 
                }

                -- Randomize tile orientation (0, 90, 180, 270 degrees)
                local randomMultiplier = math.random(0, 3)
                local targetRotY = randomMultiplier * 90
                
                local currentRot = deck.getRotation()
                local targetRot = {x = currentRot.x, y = targetRotY, z = currentRot.z}
                
                local specificIndex = count

                deck.takeObject({
                    position = targetPos,
                    rotation = targetRot,
                    smooth   = true,
                    callback_function = function(obj) 
                        obj.setLock(true) 
                        deployedTiles[specificIndex] = obj
                        
                        -- Redraw UI on final spawn to reflect correct 'Recall' state
                        if specificIndex == neededCount then
                            Wait.time(function() drawButtons() end, 0.5)
                        end
                    end
                })
            end
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
