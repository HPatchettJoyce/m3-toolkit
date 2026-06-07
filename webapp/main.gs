/**
 * The required routing function for a Google Web App.
 */
function doGet(e) {
  return HtmlService.createTemplateFromFile('CastRecruiter')
    .evaluate()
    .setTitle('Monumentum - Cast Recruiter')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

/**
 * The webhook receiver for Tabletop Simulator.
 * Receives game results and logs them to the "IN TTS" sheet tab for balance analysis.
 */
function doPost(e) {
  try {
    // 1. Parse the incoming JSON payload from Tabletop Simulator
    var postData;
    var contents = e.postData ? e.postData.contents : "";
    
    // Check if the contents are in e.parameter or URL-encoded
    if (e.parameter && e.parameter.payload) {
      postData = JSON.parse(e.parameter.payload);
    } else if (contents) {
      // Decode if it is URL-encoded (starts with %7b or similar)
      if (contents.indexOf('%') === 0 || contents.indexOf('%7b') === 0 || contents.indexOf('%7B') === 0) {
        contents = decodeURIComponent(contents);
      }
      
      // Handle key-value format (e.g. payload=JSON or simply =JSON)
      if (contents.indexOf('=') !== -1 && contents.indexOf('{') !== 0) {
        var parts = contents.split('=');
        if (parts.length > 1) {
          contents = decodeURIComponent(parts[1]);
        } else {
          contents = decodeURIComponent(parts[0]);
        }
      }
      
      postData = JSON.parse(contents);
    } else {
      throw new Error("No payload found in request.");
    }
    
    // 2. Open the spreadsheet and access the 'IN TTS' tab
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheet = ss.getSheetByName("IN TTS");
    
    if (!sheet) {
      // If the sheet doesn't exist, create it with standard headers
      sheet = ss.insertSheet("IN TTS");
      var headers = [
        "Timestamp (UTC)",
        "Winner",
        "Red Champion",
        "Red Dominion",
        "Red Cast JSON",
        "Blue Champion",
        "Blue Dominion",
        "Blue Cast JSON",
        "Special Actions Log JSON"
      ];
      sheet.appendRow(headers);
      sheet.getRange(1, 1, 1, headers.length).setFontWeight("bold");
    }
    
    // 3. Extract player casts
    var casts = postData.casts || {};
    var redCast = casts["Red"] || {};
    var blueCast = casts["Blue"] || {};
    
    // 4. Compile the row values
    var timestamp = postData.timestamp || new Date().toISOString();
    var winner = postData.winner || "Unknown";
    
    var redChampion = redCast.champion || "N/A";
    var redDominion = redCast.dominion || "N/A";
    var redCastJson = JSON.stringify(redCast);
    
    var blueChampion = blueCast.champion || "N/A";
    var blueDominion = blueCast.dominion || "N/A";
    var blueCastJson = JSON.stringify(blueCast);
    
    var specialLogJson = JSON.stringify(postData.specialActionsLog || []);
    
    var rowData = [
      timestamp,
      winner,
      redChampion,
      redDominion,
      redCastJson,
      blueChampion,
      blueDominion,
      blueCastJson,
      specialLogJson
    ];
    
    // 5. Append the match record row to the sheet
    sheet.appendRow(rowData);
    
    return ContentService.createTextOutput(JSON.stringify({
      status: "success",
      message: "Webhook successfully received. Match results logged to sheet 'IN TTS'."
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    // Graceful error logging and reporting
    Logger.log("Webhook error: " + error.toString());
    return ContentService.createTextOutput(JSON.stringify({
      status: "error",
      message: "Webhook processing failed: " + error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * This function is called by the frontend via google.script.run
 * It fetches and parses the active spreadsheet data into a JSON object.
 */
function getCardDatabase() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var charSheet = ss.getSheetByName("IN Cha-Tal");
  var spSheet = ss.getSheetByName("IN SP");
  
  if (!charSheet || !spSheet) {
    throw new Error("Could not find the required tabs: 'IN Cha-Tal' or 'IN SP'. Please check the sheet names.");
  }

  // Retrieve image mappings if available
  var imageMappings = null;
  try {
    imageMappings = getCardImageMappings();
  } catch (e) {
    Logger.log("No card image mappings found or failed to load: " + e.message);
  }

  var db = {
    dominions: [],
    champions: [],
    units: [],
    specials: []
  };

  var uniqueDominions = new Set();
  var championNameToId = {};

  // Helper to map headers to their index
  function getHeaderMap(headers) {
    var map = {};
    headers.forEach(function(header, index) {
      if (header) {
        var cleanHeader = String(header).trim().toLowerCase();
        map[cleanHeader] = index;
      }
    });
    return map;
  }

  // Helper to find column index from potential matches
  function findColumnIndex(headerMap, possibleNames) {
    for (var i = 0; i < possibleNames.length; i++) {
      var name = possibleNames[i].toLowerCase();
      if (headerMap[name] !== undefined) {
        return headerMap[name];
      }
    }
    return -1;
  }

  // --- Parse Characters and Talismans ---
  var charData = charSheet.getDataRange().getValues();
  if (charData.length > 1) {
    var charHeaders = charData[0];
    var charRows = charData.slice(1);
    var charHeaderMap = getHeaderMap(charHeaders);

    var nameIdx = findColumnIndex(charHeaderMap, ["Name (str)", "Name"]);
    var domIdx = findColumnIndex(charHeaderMap, ["Dominion (str)", "Dominion"]);
    var classIdx = findColumnIndex(charHeaderMap, ["Class (str)", "Class"]);
    var roleIdx = findColumnIndex(charHeaderMap, ["Role (str)", "Role"]);
    var etherIdx = findColumnIndex(charHeaderMap, ["Ether (int)", "Ether (Cost)", "Ether", "Cost"]);
    var idIdx = findColumnIndex(charHeaderMap, ["ID (str)", "ID"]);

    // First Pass: Parse and index Champions
    charRows.forEach(function(row, index) {
      if (nameIdx === -1 || domIdx === -1 || classIdx === -1) return;
      var name = String(row[nameIdx]).trim();
      var dominion = String(row[domIdx]).trim();
      var unitClass = String(row[classIdx]).trim();
      var cardIdVal = idIdx !== -1 ? String(row[idIdx]).trim() : "";
      
      if (!name || !dominion) return;
      
      uniqueDominions.add(dominion);

      if (unitClass === "Champion") {
        var champId = "champ_" + index;
        var imageInfo = (imageMappings && imageMappings.characters && imageMappings.characters[index]) ? imageMappings.characters[index] : null;
        db.champions.push({
          id: champId,
          name: name,
          dominion: dominion,
          uniqueId: cardIdVal,
          image: imageInfo
        });
        championNameToId[name.toLowerCase()] = champId;
      }
    });

    // Second Pass: Parse Familiars, Minions, and Talismans
    charRows.forEach(function(row, index) {
      if (nameIdx === -1 || domIdx === -1 || classIdx === -1) return;
      var name = String(row[nameIdx]).trim();
      var dominion = String(row[domIdx]).trim();
      var unitClass = String(row[classIdx]).trim();
      var cost = etherIdx !== -1 ? (parseInt(row[etherIdx]) || 0) : 0;
      var cardIdVal = idIdx !== -1 ? String(row[idIdx]).trim() : "";
      
      if (!name || !dominion) return;
      if (unitClass === "Champion") return; // Already processed

      if (unitClass === "Familiar" || unitClass === "Minion" || unitClass === "Talisman") {
        var isLoyal = false;
        var tiedChampId = null;

        if (roleIdx !== -1) {
          var role = String(row[roleIdx]).trim();
          if (role) {
            var match = role.match(/^(.*?)(?:'s|')\s*Loyal Companion$/i);
            if (match) {
              isLoyal = true;
              var champName = match[1].trim();
              if (championNameToId[champName.toLowerCase()]) {
                tiedChampId = championNameToId[champName.toLowerCase()];
              }
            }
          }
        }

        var imageInfo = (imageMappings && imageMappings.characters && imageMappings.characters[index]) ? imageMappings.characters[index] : null;
        db.units.push({
          id: "unit_" + index,
          name: name,
          dominion: dominion,
          class: unitClass,
          cost: cost,
          isLoyal: isLoyal,
          tiedChampionId: tiedChampId,
          uniqueId: cardIdVal,
          image: imageInfo
        });
      }
    });
  }

  db.dominions = Array.from(uniqueDominions);

  // --- Parse Special Actions ---
  var spData = spSheet.getDataRange().getValues();
  if (spData.length > 1) {
    var spHeaders = spData[0];
    var spRows = spData.slice(1);
    var spHeaderMap = getHeaderMap(spHeaders);

    var spNameIdx = findColumnIndex(spHeaderMap, ["Name (str)", "Name"]);
    var spDomIdx = findColumnIndex(spHeaderMap, ["Dominion (str)", "Dominion"]);
    var spClassIdx = findColumnIndex(spHeaderMap, ["Class (str)", "Class"]);
    var spRoleIdx = findColumnIndex(spHeaderMap, ["Role (str)", "Role"]);
    var spEtherIdx = findColumnIndex(spHeaderMap, ["Ether (int)", "Ether (Cost)", "Ether", "Cost"]);
    var spIdIdx = findColumnIndex(spHeaderMap, ["ID (str)", "ID"]);

    spRows.forEach(function(row, index) {
      if (spNameIdx === -1 || spDomIdx === -1 || spClassIdx === -1) return;
      var name = String(row[spNameIdx]).trim();
      var dominion = String(row[spDomIdx]).trim();
      var unitClass = String(row[spClassIdx]).trim();
      var cost = spEtherIdx !== -1 ? (parseInt(row[spEtherIdx]) || 0) : 0;
      var spCardIdVal = spIdIdx !== -1 ? String(row[spIdIdx]).trim() : "";
      
      if (!name || !dominion || unitClass !== "Special Action") return;

      var isSignature = false;
      var tiedChampId = null;

      if (spRoleIdx !== -1) {
        var role = String(row[spRoleIdx]).trim();
        if (role) {
          var match = role.match(/^(.*?)(?:'s|')\s*Signature Action$/i);
          if (match) {
            isSignature = true;
            var champName = match[1].trim();
            if (championNameToId[champName.toLowerCase()]) {
              tiedChampId = championNameToId[champName.toLowerCase()];
            }
          }
        }
      }

      var imageInfo = (imageMappings && imageMappings.specials && imageMappings.specials[index]) ? imageMappings.specials[index] : null;
      db.specials.push({
        id: "sp_" + index,
        name: name,
        dominion: dominion,
        cost: cost,
        isSignature: isSignature,
        tiedChampionId: tiedChampId,
        uniqueId: spCardIdVal,
        image: imageInfo
      });
    });
  }

  // This stringify and parse trick strips out any hidden Google Sheet objects 
  // and guarantees the data is perfectly clean for the web browser.
  return JSON.parse(JSON.stringify(db));
}