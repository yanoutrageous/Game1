# GODOT_CURRENT_STATUS

## Updated

`2026-06-08`

## Branch

This project copy is on repository branch `godot/lua-parity-p0`. It contains the G3 Lua Parity P0 implementation plus G3.5 runtime repair and G4 playable graybox v0.1.

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
- Player-facing start buttons are available for `Start Tutorial 5x5` and `Start Standard 10x10`.
- Keyboard play is available through movement, E interact/search/extract, Space/J fight, F flag, and R restart.
- ResultPanel displays extraction, failure, or training complete summaries.

## Validation

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
```

Godot headless editor/runtime smoke should be run with:

```powershell
D:\Godot\downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\AGAME2\repo\Game1\Godot\GraytailGodot --editor --quit
D:\Godot\downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\AGAME2\repo\Game1\Godot\GraytailGodot --quit-after 1
```

## Boundary

No real art migration, no full MetaProgress, no Deploy UI, and no action combat were implemented in G3 P0. Do not merge to `main` or start the next stage automatically.

## Playable Graybox v0.1 Status

- Current Godot state: Playable Graybox v0.1.
- G3 Lua Parity P0 validation: PASS.
- G3.5 runtime repair validation: PASS.
- G4 playable graybox validation: PASS.
- Godot headless editor on Computer 2: PASS.
- Runtime smoke on Computer 2: PASS.
- Tutorial manual start: YES.
- Standard manual start: YES.
- HUD/MiniMap/ResultPanel readable: YES.

## Current Unfinished Items

- Real art asset migration remains excluded.
- Full MetaProgress remains excluded.
- Action combat remains excluded.
- Deploy UI remains excluded.
- Event trader/dice/altar/trap content remains future work.
- Failure settlement and deeper rewards remain future work.
- MapOverlay polish and manual playtest feedback remain future work.

## Next Stage Recommendation

Resume on `godot/lua-parity-p0` from Computer 1. The recommended next stage is G5 content system P1 after separate user authorization. Do not merge to `main` and do not migrate real art assets unless a separate art/export or art-integration branch is planned.
