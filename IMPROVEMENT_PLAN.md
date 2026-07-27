# M3 Toolkit — Code Review Follow-ups (tracking doc)

This is a temporary working checklist generated from a full toolkit code review
(TTS Lua scripts + Google Apps Script web app), not permanent project documentation.

**When every item below is done (or explicitly deferred by the user), fold a short
summary of what changed into `PROJECT_NOTES.md`, then delete this file.**

## Pending Fixes

- [x] **1. Fix card art generator writing to the wrong path (real bug, highest priority)** — DONE
  - `output_path` in `dextrous/generate_card_images.py` now points at
    `webapp/CardImages.gs` (was `<repo root>/CardImages.gs`), so PROJECT_NOTES.md's
    workflow claim is finally true. Also replaced the hardcoded
    `Generated on: Friday, 5 June 2026` header with `datetime.date.today()`, since that
    line existed to say when the file was generated and had been lying for ~7 weeks.
  - Re-ran the generator against the existing `MonuMentuM Characters/Specials 08-06-2026.json`
    exports and the two root CSVs. Results:
    - **The stale file was the deployed one.** The regenerated output is byte-identical
      to the orphaned root-level `CardImages.gs` apart from the date header — i.e. the root
      file was always the *fresh* output, and `webapp/CardImages.gs` (the copy GAS actually
      serves) had been frozen since 5 June.
    - The real drift is exactly **4 Firebase Storage download tokens** across all 176 URL
      entries (80 characters + 96 specials). Every `cols`/`rows`/`idx` sprite coordinate is
      unchanged, so no card art was re-laid-out — the web app was just requesting images
      with tokens that had since been rotated.
    - The run made no changes to the source deck JSONs (`Nickname`/`GMNotes` were already
      injected and matched the CSVs), confirming the injector half of the script is idempotent.
  - Deleted the now-orphaned root-level `CardImages.gs`. Verified nothing referenced it
    first: `getCardImageMappings()` is called only from `webapp/main.gs:177`, and the only
    writer of the root path was the buggy line just fixed. PROJECT_NOTES.md's repo tree
    never listed a root-level copy, so the docs are now accurate as-written.
  - **Follow-up for the user:** `clasp push` from `webapp/` to actually ship the refreshed
    tokens — until then the live web app keeps serving the stale ones.

- [x] **2. Finish the double-load guard in `tts/TTS_Loader.lua`** — DONE
  - Added `isLoadingCast = false` immediately before every `return` in `loadCastCoroutine()`.
    Note: there were actually **5** exit points, not the 4 originally listed here — the plan's
    own suggested grep (`return 1$`) missed the early `if not params then return 1 end` (doesn't
    end in `return 1`, ends in `return 1 end`) and never accounted for the
    "Characters deck vanished or was moved during loading" return inside the champion-dealing
    block. All 5 (params-nil check, char-deck-missing check, spec-deck-missing check,
    champion-deck-vanished check, final success) now reset the lock.
  - Why it matters: `Model_ID_Injector.lua` already has this exact pattern via its
    `isProcessing` flag; without it here, clicking "Load" twice while a cast is mid-load
    fails the second click silently (TTS only allows one active coroutine per object).

- [x] **3. Delete dead code: `webapp/CardDatabase.gs`** — DONE
  - Deleted `webapp/CardDatabase.gs`. Re-confirmed before removing: `getRawCardDatabase()`
    was defined in that one file and called from nowhere in the repo (grep across all
    tracked files — `webapp/CastRecruiter.html:798` calls `getCardDatabase()`, which is
    defined only at `webapp/main.gs:166`). `.clasp.json`'s `filePushOrder` is empty, so no
    push configuration referenced the file either.
  - Docs updated to match: removed the file from `PROJECT_NOTES.md`'s repo tree, and rewrote
    both the PROJECT_NOTES "Global Namespace Collision Warning" and the equivalent
    `CLAUDE.md` gotcha. Neither now describes a live collision (there isn't one); each keeps
    the flat-global-scope hazard as a forward-looking caution against reintroducing a second
    card-fetching implementation, which is the part that was actually worth remembering.
  - **Follow-up for the user:** `clasp push` from `webapp/` also removes the file from the
    live Apps Script project. Until then the deployed script still carries the dead function
    — harmless (nothing calls it), just not yet in sync.

- [x] **4. Reconcile a small position-value drift across the map-deploy scripts** — DONE
  - **The plan's suggested fix was wrong, and doing it literally would have been a small
    regression.** The `0.22` in `Deploy_Font_Tiles.lua:18` was not arbitrary drift: font
    tiles stack *on top of* path tiles, so they have to spawn above the grid plane.
    `TTS_Loader.lua:1196` does exactly this and says so — it deploys scenario fonts at
    `MAP_START_POS.y + 0.05` while path tiles go at `MAP_START_POS.y` (line 1151).
    `Deploy_Font_Tiles.lua` was expressing the same intent, but by baking a *different*
    lift (0.01) into the shared origin constant instead of applying it at spawn. Setting
    it to a flat `0.21` would have made standalone-deployed fonts coplanar with the path
    tiles underneath them.
  - Fix applied: `START_POS.y` is now `0.21` in all three scripts (one canonical grid
    origin), and `Deploy_Font_Tiles.lua` gained an explicit `FONT_Y_OFFSET = 0.05`
    constant applied at the two places fonts get positioned — the initial `deck.takeObject`
    in `btnToggleFonts()` and the `setPositionSmooth` in `moveDeployedFonts()` (the layout
    cycler, which previously would also have dropped them flat). Net effect: fonts now sit
    0.05 above the board via both the standalone controller and the loader's scenario
    deployment, where before the two routes disagreed (0.01 vs 0.05).
  - The deck-respawn-on-recall positions were left alone: all three scripts already used
    `START_POS.y + 0.2` consistently, and that value now resolves to 0.41 everywhere
    instead of 0.42 in one place.
  - **Judgment call on the 3-way duplication: left as-is deliberately.** Consolidating
    would defeat the design — `Deploy_Font_Tiles.lua` and `Deploy_Path_Tiles.lua` exist to
    be dropped onto a table token *without* the loader, and TTS has no module/require
    system, so "sharing" would mean copy-pasting a config block anyway (which is what
    `Model_ID_Injector.lua` already does with its embedded health tracker). Documented the
    shared origin in `PROJECT_NOTES.md` instead, so the next change knows all three copies
    need updating together.
  - Not verified in-game: there's no Lua toolchain in this environment, so the change is
    reviewed-by-eye only. Worth a quick visual check in TTS that fonts still seat correctly
    on the path tiles.

- [ ] **5. (Optional, low priority) Escape spreadsheet text before `innerHTML` injection**
  - `webapp/CastRecruiter.html` (~lines 1442, 1454): `statsEl.innerHTML` and
    `effectEl.innerHTML` are set directly from card data before a bold/italic markup
    regex pass. Low real risk since only the developer edits the sheet, but a one-line
    escape pass first would close the gap for defense-in-depth.

- [ ] **6. (Optional, low priority) `doPost` lock edge case in `webapp/main.gs`**
  - The lock is released in a `finally` block even on the path where `waitLock` itself
    throws (i.e. before the lock was ever acquired). Harmless today for a single-editor
    sheet, but worth a guard if this ever gets a second concurrent writer.

## Already completed this session (context only — no action needed)

- Removed the redundant `TILE_DEFAULT_HEALTH` tier from `tts/Floating_Health_Tracker.lua`;
  `resolveDefaultHealth()` now determines starting health from card class (Minion vs. not)
  alone. Tile/Standee shape detection (`isTileObject`/`OBJECT_TYPE`) was deliberately kept,
  since it's a separate concern still needed for UI position/rotation selection and
  face-down-hide behavior. Re-synced the embedded copy inside `tts/Model_ID_Injector.lua`
  (verified byte-identical).
- Fixed a stale tile UI position value in `PROJECT_NOTES.md` (`-35` → `-175`) and added
  a bullet documenting the new class-based default-health behavior.
- Fixed 3 stale claims in `CLAUDE.md`: the `getCardDatabase()` collision text (superseded
  by item 3 above), `doGet`'s actual `HtmlService.createHtmlOutputFromFile(...)` call
  (was documented as `createTemplateFromFile(...).evaluate()`), and the UI max-width
  (`.container` is `1200px` on desktop; `600px` is only a mobile breakpoint).
