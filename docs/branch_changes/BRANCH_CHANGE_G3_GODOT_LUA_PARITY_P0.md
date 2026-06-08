# BRANCH_CHANGE_G3_GODOT_LUA_PARITY_P0

## Summary

Implemented the G3 Godot Lua Parity P0 runtime loop on `godot/lua-parity-p0`. This stage adds Tutorial 5x5 and Standard 10x10 run entry points, TruthMap/IntelMap public-state parity, CommandBus-only player commands, P0 room resolution, fallback UI status, and a Lua parity validator.

## Branch

- Branch: `godot/lua-parity-p0`
- Base commit: `1ca472b98a44ab40116751192b7afef6ae62c0fe`
- Target commit: see final `git log -1 --oneline`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Time: `2026-06-08 19:55:38 +08:00`

## Main Changes

- Added P0 runtime support scripts for run configs, protocol, inventory, combat, and tutorial triggers.
- Extended `TruthMap`, `IntelMap`, `RunContext`, `CommandBus`, and `RoomResolver` for Tutorial/Standard parity rules.
- Updated HUD, MiniMap, ResultPanel, and Debug UI to use snapshots/ViewModels and CommandBus entry points.
- Added `Godot/GraytailGodot/tools/validate_lua_parity_p0.ps1`.
- Updated handoff, audit, engineering status, and Godot current-status documents.

## Scope Guard

- No real art assets were migrated.
- No full MetaProgress, action combat, or Deploy UI was implemented.
- `main` was not modified.
- `lua-prototype-main` was not modified.
- No force push was used.
- No old `Game.git` push was used.
