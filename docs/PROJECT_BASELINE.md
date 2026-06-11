# Project Baseline

## Current Authority

- Stage: Pre-G10 Project Baseline Consolidation.
- Repository path: `D:\AGAME1\_repo_cache\Game1_work`.
- Remote: `https://github.com/yanoutrageous/Game1.git`.
- Main branch: `main`.
- Current main HEAD: `eb9f5d6a9df18bd019b424b1fca3000e56e20f3b`.
- Current remote main HEAD: `eb9f5d6a9df18bd019b424b1fca3000e56e20f3b`.
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
```

## Playable Range

- Tutorial and standard run flows are available.
- Movement, room transitions, search, event selection, monster resolution, extraction, failure, and settlement summaries are present.
- Inventory and current-room ground loot can be inspected through formal UI panels.
- Pickup/drop can be triggered from player-facing UI and returns CommandResult feedback.

## Unfinished Range

- This does not represent a complete final UI.
- This does not represent complete MetaProgress.
- This does not represent complete Deploy persistence.
- This does not represent complete long-term system completion.
- Warehouse economy, full tasks, codex, achievements, research, character system, outfit system, final art import, final UI polish, action combat, and new gameplay remain unfinished.

## Current Non-Goals

- Do not start G10 implementation during this baseline consolidation.
- Do not do BUG fixes, UI optimization, code refactors, gameplay changes, MetaProgress, Deploy persistence, action combat, or new gameplay in this phase.
- Do not move, delete, or rename historical documentation during this phase.

## Recommended Next Step

Use this baseline for a G10 planning pass focused on stability analysis, BUG-fix batching, UI readability optimization, interaction blocker triage, validation-chain credibility, code convergence, documentation clarity, and future content planning.

## G10 Boundary

G10 may cover stability analysis, BUG fixes, UI readability optimization, interaction blocker fixes, validation-chain trust checks, code convergence, documentation clarity, and future content planning.

G10 must not cover complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, large real-art migration, or broad architecture reshaping unless a later plan explicitly changes the boundary.

## Safety Boundary Summary

- Only operate in the current Game1 repository.
- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not run `git rebase`, `git reset`, `git clean`, or `git stash`.
- Do not run Godot/editor/game/import unless separately authorized.
- Dirty handling whitelist: tracked `project.godot`, tracked or untracked `asset_manifest.*.translation`, and untracked `*.gd.uid` only.
