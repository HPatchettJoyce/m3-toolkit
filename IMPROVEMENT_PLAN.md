# M3 Toolkit — Code Review Follow-ups (tracking doc)

This is a temporary working checklist generated from a full toolkit code review
(TTS Lua scripts + Google Apps Script web app), not permanent project documentation.

**When every item below is done (or explicitly deferred by the user), fold a short
summary of what changed into `PROJECT_NOTES.md`, then delete this file.**

## Pending Fixes

- [ ] **1. Fix card art generator writing to the wrong path (real bug, highest priority)**
  - File: `dextrous/generate_card_images.py` (lines ~47-48, ~151-152)
  - Problem: `output_path` is built from `parent_dir` (the repo root), so running the
    script produces `/m3-toolkit/CardImages.gs` instead of `/m3-toolkit/webapp/CardImages.gs`.
    PROJECT_NOTES.md's workflow section claims the script "updates `webapp/CardImages.gs`" —
    that's false today. Confirmed the two files have already drifted (different Firebase
    Storage tokens), meaning the deployed web app is likely serving stale card art right now.
  - Fix: point `output_path` at `webapp/CardImages.gs` directly. Re-run the generator once
    fixed (needs the source `MonuMentuM Characters/Specials *.json` exports and the two
    root-level CSVs present), diff the regenerated file against the current `webapp/CardImages.gs`
    to confirm what's actually stale, then decide whether to delete the now-orphaned
    root-level `CardImages.gs` or keep it (currently unclear if anything else reads it —
    check for references before deleting).

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

- [ ] **3. Delete dead code: `webapp/CardDatabase.gs`**
  - `getRawCardDatabase()` is never called anywhere (confirmed via grep across
    `webapp/*.gs` and `webapp/*.html` — only `main.gs`'s `getCardDatabase()` is used).
  - This function used to collide with `main.gs`'s `getCardDatabase()` under GAS's shared
    global namespace; the collision was already resolved by renaming it, but nobody removed
    the now-pointless leftover file afterward.
  - Fix: delete `webapp/CardDatabase.gs` entirely. `CLAUDE.md` already documents this as
    dead code (updated this session) — once deleted, simplify that note too.

- [ ] **4. Reconcile a small position-value drift across the map-deploy scripts**
  - `tts/Deploy_Font_Tiles.lua:18` uses `y = 0.22`; `tts/TTS_Loader.lua:27` and
    `tts/Deploy_Path_Tiles.lua:20` both use `y = 0.21`. Only 0.01 world units apart
    (near-invisible), but it's live proof that the map-deployment logic — duplicated
    across `TTS_Loader.lua`'s own `deployScenarioMap`/`captureMapDecks`/`recallMapDeployed`
    and the two standalone `Deploy_*.lua` scripts — has already drifted once.
  - Fix: pick one canonical value (0.21, to match the majority) and update
    `Deploy_Font_Tiles.lua`. Separately worth a judgment call: leave the 3-way duplication
    as-is (each script is meant to be usable standalone) or consolidate — not required,
    just flagging the tradeoff.

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
