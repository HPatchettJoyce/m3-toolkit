# Monumentum - Cast Recruiter

Web app for building and validating game rosters ("casts") for the tabletop game **Monumentum**, backed by card data from a Google Sheet. Built on Google Apps Script (GAS), deployed as a Google Web App. Lives in `webapp/`.

## Stack

- Backend: Google Apps Script (`.gs` files run in a single shared global namespace — no per-file scoping).
- Frontend: single-file vanilla SPA (`webapp/CastRecruiter.html`) — HTML + CSS custom properties + vanilla ES6 JS. No frameworks (React/Vue) or CSS libraries unless explicitly requested.
- Sync: [`clasp`](https://github.com/google/clasp) for local development, since GAS doesn't run locally (`webapp/.clasp.json`, `webapp/appsscript.json`).

## Architecture

- `webapp/main.gs` — primary entry point: `doGet(e)` routes the Web App, `doPost(e)` receives webhooks (e.g. from Tabletop Simulator), and holds one implementation of `getCardDatabase()`.
- `webapp/CardDatabase.gs` — a second, alternate implementation of `getCardDatabase()`.
- `webapp/CastRecruiter.html` — the frontend SPA: layout, styling, state, validation, JSON export.
- `webapp/CardImages.gs` — card image handling.

Data flow: the frontend loads via `doGet` → `HtmlService.createTemplateFromFile('CastRecruiter').evaluate()`, then asynchronously calls `google.script.run.withSuccessHandler(...).withFailureHandler(...).getCardDatabase()`.

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

- **`getCardDatabase()` collision**: two implementations exist (`main.gs` and `CardDatabase.gs`). GAS's shared namespace means whichever loads last silently wins. Always ensure `main.gs`'s version (the structured `champions`/`units`/`specials` schema) is the one in effect — when editing, either work in `main.gs` or rename one implementation to avoid the collision.
- Keep the `:root` CSS custom properties block intact (`--primary-colour`, `--accent-colour`, etc.) for consistent theming.
- UI max-width is `600px` — it's designed to sit in embedded iframes/mobile views; keep panels self-contained.

## Other repo contents

- `dextrous/` — card data JSON exports and `generate_card_images.py` for producing card art.
- `tts/` — Lua scripts for the Tabletop Simulator integration (loader, trackers, deploy scripts).
- `*.csv` at repo root — raw card data pulled from the Google Sheet tabs described above.

## Deployment

1. Open the bound Google Spreadsheet → **Extensions > Apps Script**.
2. Copy the contents of `webapp/*.gs` and `webapp/CastRecruiter.html` into the Apps Script editor (or `clasp push` from `webapp/`).
3. **Deploy > New deployment > Web app**, execute as Me, access "Anyone".
