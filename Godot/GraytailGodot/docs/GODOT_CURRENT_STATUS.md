# GODOT_CURRENT_STATUS

## Updated

`2026-06-08 19:55:38 +08:00`

## Branch

This project copy is on repository branch `godot/lua-parity-p0`. It contains the G3 Godot Lua Parity P0 implementation slice.

## Project Path

Repository project path:

```text
Godot/GraytailGodot/project.godot
```

## Current Capability

- Tutorial P0 mode: 5x5 fixed Lua-derived map, seed 777, fixed mine/event/monster/chest/exit layout.
- Standard P0 mode: 10x10 generated map with 20 mines, 10 monsters, 10 chests, 10 events, and 2 hidden random exits.
- TruthMap stores real map state.
- IntelMap stores player-known public state.
- CommandBus is the only player and Debug UI command entry.
- HUD, MiniMap, and ResultPanel consume snapshots/ViewModels.
- Fallback labels/placeholders remain in use; no real art migration occurred.

## Validation

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
```

Godot headless editor/runtime smoke may be run only with a local existing Godot executable and without installation or global config changes.

## Boundary

No real art migration, no full MetaProgress, no Deploy UI, and no action combat were implemented in G3 P0. Do not merge to `main` or start the next stage automatically.
