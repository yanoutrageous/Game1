# Project Baseline

## Current Authority

- Stage: G10 Progress & Art Smoke Foundation.
- Repository path: `D:\AGAME1\_repo_cache\Game1_work`.
- Remote: `https://github.com/yanoutrageous/Game1.git`.
- Main branch: `main`.
- Current main HEAD: `a13a6fae3208850ae43e4b511511e008eb311a3e`.
- Current remote main HEAD: `a13a6fae3208850ae43e4b511511e008eb311a3e`.
- Active G10 branch: `godot/g10-progress-art-smoke-foundation`.
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
- G10 adds bounded progress整理, interaction fixes, dev-only diagnostics gating, art smoke registry/fallback checks, and responsive layout contracts on top of the G9 UI core flow baseline.

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
- Dev diagnostics are shell-only, gated by a build-channel/UIVisibilityPolicy equivalent, hidden and disabled in the default player channel.
- A small art smoke registry validates manifest asset IDs and fallback IDs for panel, button, icon, character placeholder, and theme overlay roles.
- `UILayoutProfile` reserves desktop/narrow layout behavior for future responsive/mobile work.

## Unfinished Range

- This does not represent a complete final UI.
- This does not represent complete MetaProgress.
- This does not represent complete Deploy persistence.
- This does not represent complete long-term system completion.
- Warehouse economy, full tasks, codex, achievements, research, character system, outfit system, final art import, final UI polish, action combat, and new gameplay remain unfinished.

## Current Non-Goals

- Do not expand G10 into complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, full art replacement, or broad architecture reshaping.
- Do not treat G10 art smoke as real art migration.
- Do not treat G10 responsive hooks as complete mobile/touch support.
- Do not move, delete, or rename historical documentation during this phase.

## Recommended Next Step

After G10, use this baseline for targeted stabilization, BUG-fix batches, final UI readability passes, art production planning, and future content planning. Keep handoff files current for every branch or fix batch.

## G10 Boundary

G10 covers current progress整理, stability/BUG fixes, UI interaction optimization, dev-only diagnostics, art intake smoke, responsive/mobile reservation, and future content planning.

G10 must not cover complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, large real-art migration, or broad architecture reshaping unless a later plan explicitly changes the boundary.

## Safety Boundary Summary

- Only operate in the current Game1 repository.
- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not run `git rebase`, `git reset`, `git clean`, or `git stash`.
- Do not run Godot/editor/game/import unless separately authorized.
- Dirty handling whitelist: tracked `project.godot`, tracked or untracked `asset_manifest.*.translation`, and untracked `*.gd.uid` only.
