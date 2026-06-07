# Monumentum - Cast Recruiter

This repository contains the code for the **Monumentum Cast Recruiter** (Cast Builder), a web application built using Google Apps Script (GAS) and deployed as a Google Web App. It allows players to build and validate game rosters ("casts") for the tabletop game **Monumentum**, utilizing card data pulled directly from an active Google Sheet.

---

## 📂 Project Structure

- **`main.gs`**: The primary backend entry point. Contains the `doGet(e)` routing for the Web App, `doPost(e)` for receiving webhooks (e.g., from Tabletop Simulator), and an implementation of `getCardDatabase()`.
- **`CardDatabase.gs`**: An alternative/helper script file containing another implementation of `getCardDatabase()`.
- **`CastRecruiter.html`**: A single-file frontend SPA containing the HTML layout, CSS styling (using CSS custom properties), and vanilla JavaScript logic for application state, UI rendering, validation, and JSON export.

---

## 🏛️ Architecture & Data Flow

### 1. Backend Data Sources
The backend extracts data from the active spreadsheet containing two specific tabs:
- **`IN Cha-Tal`**: Contains Character (Champion, Familiar, Minion, Talisman) card details.
- **`IN SP`**: Contains Special Action card details.

### 2. Frontend-Backend Communication
The web app is loaded via `doGet(e)` using Apps Script's `HtmlService` and HTML templates:
- **Template Evaluation**: `HtmlService.createTemplateFromFile('CastRecruiter').evaluate()` allows embedding server-side data, though current communication is handled asynchronously.
- **Asynchronous Data Fetching**: The frontend requests the database upon page load using:
  ```javascript
  google.script.run
    .withSuccessHandler(function(data) { ... })
    .withFailureHandler(function(error) { ... })
    .getCardDatabase();
  ```

### 3. Database Schema (Expected by Frontend)
The frontend expects a clean JSON structure of the following schema from `getCardDatabase()`:
```json
{
  "dominions": ["Rhavlika", "Iro-Si-Khar", "Voisira", ...],
  "champions": [
    { "id": "champ_0", "name": "Flint Dross", "dominion": "Rhavlika" }
  ],
  "units": [
    { "id": "unit_1", "name": "Obduron", "dominion": "Rhavlika", "class": "Familiar", "cost": 6, "isLoyal": true, "tiedChampionId": "champ_0" }
  ],
  "specials": [
    { "id": "sp_0", "name": "Thermal Venting", "dominion": "Rhavlika", "cost": 0, "isSignature": false, "tiedChampionId": null }
  ]
}
```

---

## ⚠️ Important Architectural Warnings & Gotchas

### 🚨 Double Definition of `getCardDatabase()`
There are currently **two** implementations of `getCardDatabase()` in the project:
1. One in **`CardDatabase.gs`** (which processes raw sheets, standardises headers, and returns a flat mapped array of objects).
2. One in **`main.gs`** (which parses columns explicitly, structures them into the categorical schema expected by the frontend: `champions`, `units`, `specials`, etc.).

> **Crucial Apps Script Behavior:** Google Apps Script runs all `.gs` files in a **single shared global namespace**. Having multiple functions with the same name (`getCardDatabase`) results in a collision where **one function silently overrides the other**, depending on execution/compilation order.
> 
> *Action:* Always ensure the implementation in `main.gs` is used, or refactor/merge them under distinct names so the frontend gets the structured database layout it expects.

---

## 🎨 Styling & Design Guidelines

- **Vanilla Stack**: The frontend uses standard HTML5, modern vanilla CSS, and vanilla ES6 JavaScript. Avoid importing external frameworks (React, Vue) or CSS libraries unless specifically requested.
- **CSS Variables**: Maintain the clean CSS custom properties block defined in `:root` to ensure consistent theme colouring (`--primary-colour`, `--accent-colour`, etc.).
- **Responsiveness**: The UI is styled with a maximum width of `600px` for optimal viewing inside embedded iFrames or mobile views. Keep panels self-contained.

---

## ⚙️ Development & Deployment Workflow

### Deploying the Web App
To publish or update the Cast Recruiter:
1. Open the bounded Google Spreadsheet.
2. Go to **Extensions** > **Apps Script**.
3. Copy/paste the contents of the `.gs` and `.html` files into the Apps Script editor.
4. Click **Deploy** > **New deployment**.
5. Select **Web app** as the deployment type:
   - **Execute as**: Me (User access control)
   - **Who has access**: Anyone
6. Copy the Web App URL for distribution or embedding.

### Local Development / Syncing
Because Google Apps Script does not run locally out-of-the-box, developers can use Google's `clasp` (Command Line Apps Script Projects) tool to pull/push files:
```bash
# Example clasp usage
clasp login
clasp clone <scriptId>
clasp push
```
