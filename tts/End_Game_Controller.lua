--[[ Tabletop Simulator End Game Controller Script
     Written for Monumentum Cast Recruiter
     Date: Friday, 19 June 2026
     
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

function onLoad()
    print("Monumentum End Game Controller initialised.")
    self.setName("Monumentum End Game Controller")
    self.setDescription("Declares the winner and submits game results to the web database.")
    
    -- Draw the 3D control button flat on the token surface
    drawButtons()
end

-- Renders the main tactile 3D button on top of the tile
function drawButtons()
    self.clearButtons()
    
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
end

-- 3D Button Click Handler: Triggers the screen-space XML pop-up on the main Cast Loader
function btnEndGame(obj, player_color, alt_click)
    local player = Player[player_color]
    if not player.host then
        broadcastToColor("Only the Host can declare end game.", player_color, {1, 0, 0})
        return
    end
    
    -- Find and query the Cast Loader object
    local loader = getObjectFromGUID(CAST_LOADER_GUID)
    if not loader then
        broadcastToColor("Error: Could not find the Cast Loader token. Please check your CAST_LOADER_GUID configuration.", player_color, {1, 0, 0})
        return
    end
    
    -- Request the Cast Loader to show the screen-space End Game Panel
    loader.call("showScreenSpaceEndGamePanel", { controller_guid = self.getGUID() })
end

-- API function called by the Cast Loader when a selection is made in the screen-space pop-up
function declareWinnerAndSubmit(params)
    if not params or not params.winner then return end
    declaredWinner = params.winner
    submitGame(params.player_color)
end

-- Submission Function (Internally processes the results and POSTs via WebRequest.custom)
function submitGame(player_color)
    if declaredWinner == nil then
        broadcastToColor("Error: Please declare a winner before submitting.", player_color, {1, 0, 0})
        return
    end
    
    -- Find and query the Cast Loader object
    local loader = getObjectFromGUID(CAST_LOADER_GUID)
    if not loader then
        broadcastToColor("Error: Could not find the Cast Loader token. Please check your CAST_LOADER_GUID configuration.", player_color, {1, 0, 0})
        declaredWinner = nil
        return
    end
    
    -- Retrieve match data as a JSON string to avoid cross-script ownership errors
    local success, matchDataJson = pcall(function()
        return loader.call("getMatchDataJson")
    end)
    
    if not success or not matchDataJson then
        broadcastToColor("Error: Failed to fetch match data from the Cast Loader. Make sure the Cast Loader has the latest script.", player_color, {1, 0, 0})
        declaredWinner = nil
        return
    end
    
    -- Decode the JSON string locally so the resulting tables are fully owned by this script's sandbox
    local decodeSuccess, matchData = pcall(function()
        return JSON.decode(matchDataJson)
    end)
    
    if not decodeSuccess or not matchData then
        broadcastToColor("Error: Failed to parse match data received from the Cast Loader.", player_color, {1, 0, 0})
        declaredWinner = nil
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
        declaredWinner = nil
        return
    end
    
    -- Explicitly configure JSON headers to ensure Google Apps Script doPost(e) parses correctly as raw contents!
    local headers = {
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json"
    }
    
    -- Send JSON string to Google Web App URL using WebRequest.custom() (Positional Params)
    WebRequest.custom(WEBHOOK_URL, "POST", false, jsonString, headers, function(request)
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
        -- Reset the winner state
        declaredWinner = nil
    end)
end
