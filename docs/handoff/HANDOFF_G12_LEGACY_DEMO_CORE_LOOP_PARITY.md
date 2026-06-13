# Handoff G12 Legacy Demo Core Loop Parity

## Stage Identity

- Historical label: G12
- Formal name: Legacy Demo Core Loop, Chinese Readability & Typography Parity
- Chinese name: 旧 Demo 核心体验、中文可读性与字体排版轻量对齐
- Branch: `main`
- Main HEAD after G12-R3: `2855ca9889e394fb79d22c468b1355cd3871fd39`
- Remote live main after G12-R3: `2855ca9889e394fb79d22c468b1355cd3871fd39`
- G12-R3 commit: `2855ca9 fix(godot): align G12 core loop readability with legacy demo`
- Status: complete, pushed, and closed after G12-R4 docs-only closeout

## Current Fact Source

- Repo: `D:\AGAME1\_repo_cache\Game1_work`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Current branch: `main`
- Primary docs: `docs/PROJECT_BASELINE.md`, `docs/NEXT_HANDOFF.md`, `docs/DOCS_INDEX.md`, `docs/ENGINEERING_STATUS.md`, `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`
- Validation record: `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md`
- Manual route checklist: `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`

## Completed

- Current fact-source and status docs were calibrated for G12.
- G12 validation and manual playtest guidance were added or updated.
- Existing player-visible UI wording was aligned toward legacy Demo core-loop readability.
- Chinese readability, tooltip wording, empty-state wording, local font size, line spacing, color, and autowrap usage were lightly improved.
- MiniMap/MapOverlay scan feedback, HUD protocol/pressure text, Inventory/GroundLoot capacity and loot wording, ResultPanel settlement text, and presentation mapping were adjusted within existing UI surfaces.

## Explicitly Not Done

- No 1:1 legacy Demo remake.
- No new gameplay, new systems, new levels, new enemies, new economy, or full event library.
- No complete MetaProgress, Deploy persistence, long-term systems, action combat, complete final UI, complete settings, or complete diagnostics platform.
- No full font system, no downloaded/copied/source-unknown fonts, no font files committed, no full theme rewrite, and no full art migration.
- No Godot runtime/editor/game/import run, and no runtime PASS is claimed.

## Validation Results

- G12-R3 static validation included diff/stat/check/status, staged range checks, text/readability grep, font/resource/import-product checks, and remote live main confirmation.
- G12-R3 did not modify `run_scene.gd`.
- G12-R3 did not add font files, resources, or import products.
- G12-R3 did not commit the existing Godot dirty whitelist.
- Remaining dirty is expected to remain limited to tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.

## Risks And Debt

- Runtime/playable verification was not run in G12 and requires explicit authorization before claiming PASS.
- The old Demo was used as a lightweight experience reference, not as frame-by-frame parity evidence.
- Larger parity, system, persistence, art, or font work remains outside G12.

## Next Stage Candidates

- Runtime smoke / playable verification.
- MetaProgress / long-term progression systems.
- Deploy persistence / save and deployment continuity.
- Main gameplay deepening.
- More complete legacy Demo experience reproduction.

These are candidates only. G13 is not started by this handoff.

## Safety Boundaries

- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not use `git pull`, `git fetch`, `git rebase`, `git reset`, `git clean`, or `git stash` unless a later explicit task changes the rules.
- Do not run Godot/editor/game/import unless explicitly authorized.
- Dirty whitelist: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
