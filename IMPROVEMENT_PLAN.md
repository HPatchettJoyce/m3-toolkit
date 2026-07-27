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
