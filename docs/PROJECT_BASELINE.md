# Project Baseline

## Current Authority

- Stage: G13 Fixed Resolution Layout Adaptation complete; docs-only closeout/handoff/status is being recorded.
- Repository path: `D:\AGAME1\_repo_cache\Game1_work`.
- Remote: `https://github.com/yanoutrageous/Game1.git`.
- Main branch: `main`.
- Current main HEAD: `5afdb05fefe65031da1486507b0b39bdd2f1cea7`.
- Current remote live main HEAD: `5afdb05fefe65031da1486507b0b39bdd2f1cea7`.
- Closed G10 branch: `godot/g10-progress-art-smoke-foundation` at `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.
- G10 closeout status: complete, merged to main, and closed.
- G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.
- G10 closeout follow-up commit: `53a4e122376998d2f6d0a2a617b753a3d382b2f0`.
- G11-R3 commit: `e261ac7 fix(godot): improve G11 mainline UX readability`.
- G11 closeout commit: `4be0010 docs: close G11 mainline UX readability pass`.
- G12-R3 commit: `2855ca9 fix(godot): align G12 core loop readability with legacy demo`.
- G12 closeout commit: `e90bd27 docs: close G12 legacy demo parity pass`.
- G13 baseline commit: `e90bd27 docs: close G12 legacy demo parity pass`.
- G13-R3 commit: `5afdb05 feat(godot): add fixed resolution layout support`.
- Old UE repository `Game.git`: read-only reference only.
- `lua-prototype-main`: read-only historical prototype baseline.

This file is the current engineering fact source. Use `docs/NEXT_HANDOFF.md` for the shortest next-chat context and `docs/DOCS_INDEX.md` for document navigation.

## Current Mainline Capability

- G7 Playable Flow Baseline is in `main`.
- G8 Asset Ledger & Settlement Core is in `main`.
- G8.1 Architecture Hardening is in `main`.
- G8.2 Kernel Protocol Baseline and runtime parse hotfix are in `main`.
- G9 UI Presentation Layering Contracts are in `main`.
- G9 UI core flow baseline is in `main`.
- Current UI includes the three-page shell, formal InventoryPanel, formal GroundLootPanel, pickup/drop through CommandBus, CommandResult reason display, and ResultPanel settlement explanation.
- G10 Progress & Art Smoke Foundation is complete and in `main`.
- G10 added bounded progress整理, interaction fixes, dev-only diagnostics gating, art smoke registry/fallback checks, and responsive layout contracts on top of the G9 UI core flow baseline.
- G11-R3 completed the narrow mainline testability and UX readability repair for current UI text, tooltips, hand-test coverage, and status documentation.
- G12 is complete and closed for lightweight legacy Demo core-loop feel, Chinese readability, typography/readability, and current UI feedback alignment on existing systems.
- G13-R3 is complete, pushed, and statically validated for fixed 16:9 resolution tiers, runtime-only display selection, resize locking, and bounded layout adaptation. G13-R5 is docs-only closeout/handoff/status alignment.

## Current Validation Chain

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_ux_flow_parity_g7.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_rules_g8.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_architecture_hardening_g8_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_kernel_protocol_g8_2.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_ui_presentation_layering_g9.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_ui_final_g9.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_baseline_docs_pre_g10.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_g10_progress_art_smoke.ps1
```

## Playable Range

- Tutorial and standard run flows are available.
- Movement, room transitions, search, event selection, monster resolution, extraction, failure, and settlement summaries are present.
- Inventory and current-room ground loot can be inspected through formal UI panels.
- Pickup/drop can be triggered from player-facing UI and returns CommandResult feedback.
- ResultPanel has explicit return actions to main and expedition shell.
- The run screen has a pause/settings overlay for player-facing interruption without persistence writes.
- MiniMapPanel direct click opens MapOverlay through the existing `open_map` command path.
- MapOverlay provides minimal open-source and selected/action feedback.
- Dev diagnostics are shell-only, gated by a build-channel/UIVisibilityPolicy equivalent, hidden and disabled in the default player channel.
- A small art smoke registry validates manifest asset IDs and fallback IDs for panel, button, icon, character placeholder, and theme overlay roles.
- `UILayoutProfile` now includes fixed-tier G13 layout fields while retaining earlier desktop/narrow compatibility.

## Unfinished Range

- This does not represent a complete final UI.
- This does not represent complete MetaProgress.
- This does not represent complete Deploy persistence.
- This does not represent complete long-term system completion.
- Warehouse economy, full tasks, codex, achievements, research, character system, outfit system, final art import, final UI polish, action combat, and new gameplay remain unfinished.

## Current Non-Goals

- G10 is closed. Do not reopen or expand it into complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, full art replacement, or broad architecture reshaping.
- Do not treat G10 art smoke as real art migration.
- Do not treat G10 responsive hooks as complete mobile/touch support.
- Do not move, delete, or rename historical documentation during this phase.

## Recommended Next Step

G13 is closing after fixed 16:9 resolution tiers, minimal runtime display settings, and bounded layout adaptation across the current UI surfaces. Keep future branch or fix-batch handoff files current.

## G13 Boundary

G13 covers exactly these fixed resolution tiers: `1280x720`, `1366x768`, `1600x900`, `1920x1080`, and `2560x1440`. G13-R3 added runtime-only display selection, startup auto recommendation, manual apply/reset, resize locking, `UILayoutProfile` fixed-tier fields, and small panel/text sizing changes for existing UI.

G13 did not run Godot/editor/game/import, did not submit `project.godot`, did not submit resources/import products/font files, and did not submit the existing Godot dirty whitelist. Closeout is static-validation only and must not be read as runtime PASS.

G13 must not become arbitrary aspect-ratio responsiveness, mobile support, ultrawide support, 4K support, full platform DPI parity, complete final UI, complete settings, Deploy persistence, MetaProgress, action combat, new gameplay, new resources, full art migration, broad UI rewrite, broad architecture reshaping, or a claim that runtime/manual verification is complete.

## G12 Boundary

G12 covered lightweight legacy Demo core-loop parity on top of current Godot main: main menu/deploy/tutorial path readability, room scan/map feedback, room/event/search/reward feedback, Inventory/GroundLoot/ResultPanel readability, Chinese-visible text cleanup, and local typography/readability tweaks using existing theme/color/font-size/tooltip/autowrap settings.

G12 is complete, pushed, and closed. It did not run Godot/editor/game/import, did not add font files/resources/import products, did not modify `run_scene.gd`, and did not commit the existing Godot dirty whitelist.

G12 must not be read as 1:1 legacy Demo remake, complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, new levels, new enemies, new economy systems, full event library, full art migration, complete final UI, complete settings, complete diagnostics, complete font system, downloaded/copied/source-unknown fonts, broad theme rewrite, broad architecture reshaping, or broad formatting.

## G11 Boundary

G11 covered current mainline testability, manual smoke checklist clarity, current fact-source calibration, and small UI text/tooltip/empty-state/disabled-reason/return-path readability fixes. G11 is complete and closed at `4be0010dd68abe1b0e74966775db64f736d78e15`.

G11 must not cover complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, new levels, new enemies, new economy systems, full art migration, complete final UI, complete settings, complete diagnostics, mobile adaptation, broad architecture reshaping, or broad formatting.

## Next Stage Candidates

- Runtime smoke / playable verification.
- Five-tier resolution manual smoke.
- DisplayServer window behavior verification.
- MetaProgress / long-term progression systems.
- Deploy persistence / save and deployment continuity.
- Main gameplay deepening.
- More complete legacy Demo experience reproduction.

These are candidates only. They require separate approval, are not part of G13 closeout, and do not start G14.

## G10 Boundary

G10 covered current progress整理, stability/BUG fixes, UI interaction optimization, dev-only diagnostics, art intake smoke, responsive/mobile reservation, and future content planning.

G10 is complete, merged to main, and closed. It must not be continued as complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, large real-art migration, or broad architecture reshaping unless a later separately approved phase changes the boundary.

## Safety Boundary Summary

- Only operate in the current Game1 repository.
- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not run `git rebase`, `git reset`, `git clean`, or `git stash`.
- Do not run Godot/editor/game/import unless separately authorized.
- Dirty handling whitelist: tracked `project.godot`, tracked or untracked `asset_manifest.*.translation`, and untracked `*.gd.uid` only.
