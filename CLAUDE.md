# Monumentum - Cast Recruiter

Web app for building and validating game rosters ("casts") for the tabletop game **Monumentum**, backed by card data from a Google Sheet. Built on Google Apps Script (GAS), deployed as a Google Web App. Lives in `webapp/`.

## Stack

- Backend: Google Apps Script (`.gs` files run in a single shared global namespace — no per-file scoping).
- Frontend: single-file vanilla SPA (`webapp/CastRecruiter.html`) — HTML + CSS custom properties + vanilla ES6 JS. No frameworks (React/Vue) or CSS libraries unless explicitly requested.
- Sync: [`clasp`](https://github.com/google/clasp) for local development, since GAS doesn't run locally (`webapp/.clasp.json`, `webapp/appsscript.json`).

## Architecture

- `webapp/main.gs` — primary entry point: `doGet(e)` routes the Web App, `doPost(e)` receives webhooks (e.g. from Tabletop Simulator), and defines `getCardDatabase()`.
- `webapp/CardDatabase.gs` — an alternate, unused implementation (`getRawCardDatabase()`, never called from `CastRecruiter.html`) — a leftover from before the collision below was resolved by renaming.
- `webapp/CastRecruiter.html` — the frontend SPA: layout, styling, state, validation, JSON export.
- `webapp/CardImages.gs` — card image handling.

Data flow: the frontend loads via `doGet` → `HtmlService.createHtmlOutputFromFile('CastRecruiter')`, then asynchronously calls `google.script.run.withSuccessHandler(...).withFailureHandler(...).getCardDatabase()`.

Backend data source: the active spreadsheet's `IN Cha-Tal` tab (Champion/Familiar/Minion/Talisman cards) and `IN SP` tab (Special Action cards).

Expected `getCardDatabase()` schema:
```json
{
  "dominions": ["Rhavlika", "Iro-Si-Khar", "Voisira", ...],
  "champions": [{ "id": "champ_0", "name": "Flint Dross", "dominion": "Rhavlika" }],
  "units": [{ "id": "unit_1", "name": "Obduron", "dominion": "Rhavlika", "class": "Familiar", "cost": 6, "isLoyal": true, "tiedChampionId": "champ_0" }],
  "specials": [{ "id": "sp_0", "name": "Thermal Venting", "dominion": "Rhavlika", "cost": 0, "isSignature": false, "tiedChampionId": null }]
}
```

## Conventions & gotchas

- **`getCardDatabase()` collision (historical)**: `main.gs` and `CardDatabase.gs` used to both define `getCardDatabase()`, colliding in GAS's shared namespace. That's now resolved — `CardDatabase.gs`'s copy was renamed to `getRawCardDatabase()` — but the renamed function is dead code (nothing calls it). Consider deleting `CardDatabase.gs` outright rather than keeping an unused alternate implementation around.
- Keep the `:root` CSS custom properties block intact (`--primary-colour`, `--accent-colour`, etc.) for consistent theming.
- UI `.container` max-width is `1200px` on desktop, stepping down through breakpoints at 1100px/900px/600px for mobile — keep panels self-contained at all sizes.

## Other repo contents

- `dextrous/` — card data JSON exports and `generate_card_images.py` for producing card art.
- `tts/` — Lua scripts for the Tabletop Simulator integration (loader, trackers, deploy scripts).
- `*.csv` at repo root — raw card data pulled from the Google Sheet tabs described above.

## Deployment

1. Open the bound Google Spreadsheet → **Extensions > Apps Script**.
2. Copy the contents of `webapp/*.gs` and `webapp/CastRecruiter.html` into the Apps Script editor (or `clasp push` from `webapp/`).
3. **Deploy > New deployment > Web app**, execute as Me, access "Anyone".
