/**
 * Retrieves and parses Monumentum card data from specific tabs in the active Google Sheet.
 * Designed to be called as a helper or for raw data inspections.
 * @returns {Array<Object>|Object} An array of combined card objects or an error object.
 */
function getRawCardDatabase() {
  try {
    // Connect to the active Google Sheet where the script is bound
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    
    // Define the specific tabs to draw data from
    const sheetNames = ['IN Cha-Tal', 'IN SP'];
    let combinedDatabase = [];
    
    sheetNames.forEach(function(sheetName) {
      const sheet = ss.getSheetByName(sheetName);
      
      // Verify the tab exists to prevent null reference errors
      if (!sheet) {
        throw new Error('The tab named "' + sheetName + '" could not be found.');
      }
      
      // Retrieve all data from the tab as a 2D array
      const data = sheet.getDataRange().getValues();
      
      // If the sheet is completely empty or only has a header row, skip it
      if (data.length <= 1) {
        return; 
      }
      
      // Extract headers to use as object keys
      const headers = data[0];
      const rows = data.slice(1);
      
      // Convert the remaining rows into an array of objects
      const sheetData = rows.map(function(row) {
        let cardObject = {};
        
        headers.forEach(function(header, index) {
          // Standardise the header to string and trim whitespace
          const cleanHeader = String(header).trim();
          
          // Assign the corresponding row value to the header key
          cardObject[cleanHeader] = row[index];
        });
        
        return cardObject;
      });
      
      // Append the parsed data from this tab to the master array
      combinedDatabase = combinedDatabase.concat(sheetData);
    });
    
    // Return the comprehensive list of cards from both tabs
    return combinedDatabase;
    
  } catch (error) {
    // Log the error in the Apps Script execution log for debugging
    Logger.log('Error fetching Monumentum card database: ' + error.message);
    
    // Return a clear error message to the frontend application
    return { 
      error: 'Failed to retrieve the card database. ' + error.message 
    };
  }
}