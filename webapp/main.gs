/**
 * Tabletop Simulator Match Logger & Cast Recruiter API
 * Apps Script Backend
 * Date: Sunday, 7 June 2026
 */

// Global Sheet configuration names
var MATCH_SHEET_NAME = "IN TTS";
var CHAR_SHEET_NAME = "IN Cha-Tal";
var SP_SHEET_NAME = "IN SP";

/**
 * Serves the HTML frontend interface to clients.
 */
function doGet() {
  return HtmlService.createHtmlOutputFromFile('CastRecruiter')
      .setTitle('Monumentum Cast Recruiter')
      .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL)
      .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

/**
 * Handles incoming match logs POSTed by the TTS End Game Controller webhook.
 */
function doPost(e) {
  var lock = LockService.getScriptLock();
  try {
    // Acquire a 30-second lock to prevent concurrent write collisions in Google Sheets!
    lock.waitLock(30000);
    
    var rawContent = e && e.postData ? e.postData.contents : "";
    if (!rawContent) {
      return ContentService.createTextOutput(JSON.stringify({
        status: "error",
        message: "Request payload was empty."
      })).setMimeType(ContentService.MimeType.JSON);
    }

    var payload = null;
    
    // Resilient Parser: Supports standard application/json, form-urlencoded, or raw serialised payloads
    try {
      payload = JSON.parse(rawContent);
    } catch (jsonErr) {
      if (e && e.parameter) {
        payload = e.parameter;
      } else {
        var parsedParams = parseFormUrlEncoded(rawContent);
        if (Object.keys(parsedParams).length > 0) {
          payload = parsedParams;
        }
      }
    }

    if (!payload) {
      return ContentService.createTextOutput(JSON.stringify({
        status: "error",
        message: "Failed to parse parameters from POST body."
      })).setMimeType(ContentService.MimeType.JSON);
    }

    // Decode nested JSON strings if they were double-serialised by Tabletop Simulator's WebRequest Custom client
    if (typeof payload === 'string') {
      try { payload = JSON.parse(payload); } catch (e) {}
    }

    var winner = payload.winner || "";
    var matchDataJson = payload.matchData || "";
    var matchData = {};

    if (matchDataJson) {
      try {
        matchData = JSON.parse(matchDataJson);
      } catch (err) {
        console.warn("Could not parse nested matchData JSON: " + err.message);
      }
    } else {
      // Direct assignment fallback
      matchData = payload;
    }

    var loadedCasts = matchData.loadedCasts || {};
    var specialActionsLog = matchData.specialActionsLog || [];

    // Map Player Red & Blue cast definitions
    var redCast = loadedCasts.Red || {};
    var blueCast = loadedCasts.Blue || {};

    var redChampion = redCast.champion || "";
    var redDominion = redCast.dominion || "";
    var blueChampion = blueCast.champion || "";
    var blueDominion = blueCast.dominion || "";

    // Open active spreadsheet
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheet = ss.getSheetByName(MATCH_SHEET_NAME);
    
    // Resilient creation of tracking sheet tab if not present
    if (!sheet) {
      sheet = ss.insertSheet(MATCH_SHEET_NAME);
      // Append standard column headers
      sheet.appendRow([
        "Timestamp (UTC)",
        "Winner",
        "Red Champion",
        "Red Dominion",
        "Red Cast JSON",
        "Blue Champion",
        "Blue Dominion",
        "Blue Cast JSON",
        "Special Actions Log JSON"
      ]);
      sheet.getRange(1, 1, 1, 9).setFontWeight("bold").setBackground("#f1c40f");
    }

    // Append standard row record
    sheet.appendRow([
      new Date().toISOString(), // Standardised ISO timestamp
      winner,
      redChampion,
      redDominion,
      JSON.stringify(redCast),
      blueChampion,
      blueDominion,
      JSON.stringify(blueCast),
      JSON.stringify(specialActionsLog)
    ]);

    return ContentService.createTextOutput(JSON.stringify({
      status: "success",
      message: "Match results logged successfully!"
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (globalErr) {
    console.error("Critical Post Error: " + globalErr.toString());
    return ContentService.createTextOutput(JSON.stringify({
      status: "error",
      message: globalErr.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  } finally {
    lock.releaseLock();
  }
}

/**
 * Manual URL Parameter Decoder
 */
function parseFormUrlEncoded(rawString) {
  var obj = {};
  if (!rawString) return obj;
  var pairs = rawString.split('&');
  for (var i = 0; i < pairs.length; i++) {
    var parts = pairs[i].split('=');
    if (parts.length === 2) {
      var key = decodeURIComponent(parts[0].replace(/\+/g, ' '));
      var value = decodeURIComponent(parts[1].replace(/\+/g, ' '));
      obj[key] = value;
    }
  }
  return obj;
}

/**
 * Compiles and returns character and special database objects, merged with image coordinates.
 */
function getCardDatabase() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var charSheet = ss.getSheetByName(CHAR_SHEET_NAME);
  var spSheet = ss.getSheetByName(SP_SHEET_NAME);

  if (!charSheet || !spSheet) {
    throw new Error("Missing required source spreadsheet tabs.");
  }

  var imageMappings = {};
  try {
    imageMappings = getCardImageMappings();
  } catch (err) {
    console.warn("getCardImageMappings is undefined. Falling back to default styling: " + err.message);
  }

  var db = {
    dominions: [],
    champions: [],
    units: [],
    specials: []
  };

  var uniqueDominions = new Set();
  var championNameToId = {};

  var getHeaderMap = function(headers) {
    var map = {};
    headers.forEach(function(h, idx) { map[h.trim()] = idx; });
    return map;
  };

  var findColumnIndex = function(map, keys) {
    for (var i = 0; i < keys.length; i++) {
      if (map.hasOwnProperty(keys[i])) return map[keys[i]];
    }
    return -1;
  };

  // --- Parse Characters & Talismans ---
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
      if (!cardIdVal && name) {
        cardIdVal = "SYN-" + name.replace(/[^a-zA-Z0-9]/g, "").toUpperCase();
      }
      
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
      if (!cardIdVal && name) {
        cardIdVal = "SYN-" + name.replace(/[^a-zA-Z0-9]/g, "").toUpperCase();
      }
      
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
      if (!spCardIdVal && name) {
        spCardIdVal = "SYN-" + name.replace(/[^a-zA-Z0-9]/g, "").toUpperCase();
      }
      
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
