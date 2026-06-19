--[[ Tabletop Simulator End Game Controller Script
     Written for Monumentum Cast Recruiter
     Date: Sunday, 7 June 2026
     
     INSTRUCTIONS:
     1. Attach this script to a dedicated token or object on your table.
     2. Enter the GUID of your Cast Loader token in CAST_LOADER_GUID below.
     3. Enter your Google Web App URL in WEBHOOK_URL below.
     4. Click Save & Play!
--]]

-- =============== CONFIGURATION (REQUIRED) ===============
-- GUID of the main Cast Loader token/object
CAST_LOADER_GUID = "eea0da"

-- Your Google Web App URL where the compiled match data will be POSTed.
WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbzJ_rRo1MT81RSvWaqHqFvRzJ9utCt0stRyWUT6TguOIscMNviKVxogu8qwfqyxaBbT/exec"


-- =============== STATE VARIABLES ===============
declaredWinner = nil -- Selected winner ("Red", "Blue", or "Draw")
showMenu = false     -- Toggle to show selection menu or single "End Game" button

function onLoad()
    print("Monumentum End Game Controller initialised.")
    self.setName("Monumentum End Game Controller")
    self.setDescription("Declares the winner and submits game results to the web database.")
    
    -- Draw the 3D control buttons flat on the token surface
    drawButtons()
end

-- Renders the 3D buttons on top of the tile
function drawButtons()
    self.clearButtons()
    
    if not showMenu then
        -- Draw only ONE button: "End Game"
        self.createButton({
            click_function = "btnEndGame",
            function_owner = self,
            label          = "End Game",
            position       = {0, 0.2, 0},
            rotation       = {0, 0, 0},
            width          = 1440,
            height         = 400,
            font_size      = 200,
            color          = {39/255, 174/255, 96/255}, -- Green
            font_color     = {1, 1, 1}
        })
    else
        -- Button 1: Red Won
        self.createButton({
            click_function = "btnSelectRed",
            function_owner = self,
            label          = "Red Won",
            position       = {0, 0.2, -1.35},
            rotation       = {0, 0, 0},
            width          = 1440,
            height         = 360,
            font_size      = 160,
            color          = {231/255, 76/255, 60/255}, -- Red
            font_color     = {1, 1, 1}
        })

        -- Button 2: Blue Won
        self.createButton({
            click_function = "btnSelectBlue",
            function_owner = self,
            label          = "Blue Won",
            position       = {0, 0.2, -0.45},
            rotation       = {0, 0, 0},
            width          = 1440,
            height         = 360,
            font_size      = 160,
            color          = {52/255, 152/255, 219/255}, -- Blue
            font_color     = {1, 1, 1}
        })

        -- Button 3: Draw
        self.createButton({
            click_function = "btnSelectDraw",
            function_owner = self,
            label          = "Draw",
            position       = {0, 0.2, 0.45},
            rotation       = {0, 0, 0},
            width          = 1440,
            height         = 360,
            font_size      = 160,
            color          = {149/255, 165/255, 166/255}, -- Grey
            font_color     = {1, 1, 1}
        })

        -- Button 4: Cancel (Resets menu)
        self.createButton({
            click_function = "btnCancel",
            function_owner = self,
            label          = "Cancel",
            position       = {0, 0.2, 1.35},
            rotation       = {0, 0, 0},
            width          = 1440,
            height         = 360,
            font_size      = 160,
            color          = {80/255, 80/255, 80/255}, -- Dark grey
            font_color     = {1, 1, 1}
        })
    end
end

-- Opens the Winner Selection Menu
function btnEndGame(obj, player_color, alt_click)
    local player = Player[player_color]
    if not player.host then
        broadcastToColor("Only the Host can declare end game.", player_color, {1, 0, 0})
        return
    end
    showMenu = true
    drawButtons()
end

-- Resets Selection State
function btnCancel(obj, player_color, alt_click)
    local player = Player[player_color]
    if not player.host then
        broadcastToColor("Only the Host can cancel.", player_color, {1, 0, 0})
        return
    end
    showMenu = false
    declaredWinner = nil
    drawButtons()
end

-- Selection Handlers (Declares and automatically submits results)
function btnSelectRed(obj, player_color, alt_click)
    local player = Player[player_color]
    if not player.host then
        broadcastToColor("Only the Host can declare the winner.", player_color, {1, 0, 0})
        return
    end
    declaredWinner = "Red"
    print("Winner declared as: Red")
    submitGame(player_color)
end

function btnSelectBlue(obj, player_color, alt_click)
    local player = Player[player_color]
    if not player.host then
        broadcastToColor("Only the Host can declare the winner.", player_color, {1, 0, 0})
        return
    end
    declaredWinner = "Blue"
    print("Winner declared as: Blue")
    submitGame(player_color)
end

function btnSelectDraw(obj, player_color, alt_click)
    local player = Player[player_color]
    if not player.host then
        broadcastToColor("Only the Host can declare the winner.", player_color, {1, 0, 0})
        return
    end
    declaredWinner = "Draw"
    print("Winner declared as: Draw")
    submitGame(player_color)
end

-- Submission Function (Internally processes the results)
function submitGame(player_color)
    if declaredWinner == nil then
        broadcastToColor("Error: Please declare a winner before submitting.", player_color, {1, 0, 0})
        showMenu = false
        drawButtons()
        return
    end
    
    -- Find and query the Cast Loader object
    local loader = getObjectFromGUID(CAST_LOADER_GUID)
    if not loader then
        broadcastToColor("Error: Could not find the Cast Loader token. Please check your CAST_LOADER_GUID configuration.", player_color, {1, 0, 0})
        showMenu = false
        declaredWinner = nil
        drawButtons()
        return
    end
    
    -- Retrieve match data as a JSON string to avoid cross-script ownership errors
    local success, matchDataJson = pcall(function()
        return loader.call("getMatchDataJson")
    end)
    
    if not success or not matchDataJson then
        broadcastToColor("Error: Failed to fetch match data from the Cast Loader. Make sure the Cast Loader has the latest script.", player_color, {1, 0, 0})
        showMenu = false
        declaredWinner = nil
        drawButtons()
        return
    end
    
    -- Decode the JSON string locally so the resulting tables are fully owned by this script's sandbox
    local decodeSuccess, matchData = pcall(function()
        return JSON.decode(matchDataJson)
    end)
    
    if not decodeSuccess or not matchData then
        broadcastToColor("Error: Failed to parse match data received from the Cast Loader.", player_color, {1, 0, 0})
        showMenu = false
        declaredWinner = nil
        drawButtons()
        return
    end
    
    broadcastToAll("Submitting game results to the Google Web App...", {0.9, 0.9, 0.2})
    
    -- Compile the final payload
    local payload = {
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"), -- UTC ISO 8601 timestamp
        winner = declaredWinner,
        loadedCasts = matchData.loadedCasts,
        casts = matchData.loadedCasts,
        specialActionsLog = matchData.specialActionsLog
    }
    
    -- Convert Lua table to JSON string
    local encodeSuccess, jsonString = pcall(function()
        return JSON.encode(payload)
    end)
    
    if not encodeSuccess or jsonString == nil then
        broadcastToColor("Error: Failed to serialise match data to JSON.", player_color, {1, 0, 0})
        showMenu = false
        declaredWinner = nil
        drawButtons()
        return
    end
    
    -- Send JSON string to Google Web App URL using WebRequest.post()
    WebRequest.post(WEBHOOK_URL, jsonString, function(request)
        if request.is_error then
            broadcastToAll("Error: Game submission failed. Network error occurred.", {1, 0, 0})
            print("Webhook transmission failed: " .. request.error)
        else
            local responseText = request.text or ""
            print("Google Web App Response: " .. tostring(responseText))
            
            -- If Google returned an HTML page, it usually indicates a Google Account login redirect,
            -- a permissions warning, or a deployment error.
            if responseText:match("<!DOCTYPE") or responseText:match("<html") or responseText:match("<body") then
                broadcastToAll("Warning: Match results sent, but received an HTML response from Google.", {1, 0.5, 0})
                broadcastToAll("Please ensure the Web App is deployed with 'Who has access' set to 'Anyone'.", {1, 0.5, 0})
            else
                broadcastToAll("Success: Game results successfully submitted and logged!", {0.1, 0.9, 0.1})
            end
        end
        -- Reset menu and winner state
        showMenu = false
        declaredWinner = nil
        drawButtons()
    end)
end