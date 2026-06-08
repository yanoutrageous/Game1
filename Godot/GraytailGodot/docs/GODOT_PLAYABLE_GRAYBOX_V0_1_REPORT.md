# GODOT_PLAYABLE_GRAYBOX_V0_1_REPORT

## Summary

G4 playable graybox v0.1 makes the G3 Lua parity slice manually playable after G3.5 runtime repair.

## Godot

- Console path: `D:\Godot\downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe`
- Version: `4.6.3.stable.official.7d41c59c4`
- Self-contained marker: enabled in the existing Godot directory.

## Runtime Validation

- Headless editor: PASS with Godot `4.6.3.stable.official.7d41c59c4`.
- Runtime smoke: PASS with Godot `4.6.3.stable.official.7d41c59c4`.
- Static validators: PASS.

Validated commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_playable_graybox_v0_1.ps1
D:\Godot\downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\AGAME2\repo\Game1\Godot\GraytailGodot --editor --quit
D:\Godot\downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\AGAME2\repo\Game1\Godot\GraytailGodot --quit-after 1
```

## Playable Surface

- Tutorial manual start: `Start Tutorial 5x5`.
- Standard manual start: `Start Standard 10x10`.
- Movement: W/A/S/D or arrows.
- Search/interact/extract: E.
- Fight: Space or J.
- Flag: F.
- Restart: R.

## UI Readability

- HUD shows HP, Power, Pressure, Gold, Position, Room, Adjacent Mines, Search State, and Enemy/Event/Exit Hint.
- MiniMap shows 5x5 or 10x10 public IntelMap cells with fallback text.
- ResultPanel shows outcome and run statistics for extraction, failure, or tutorial completion.

## Boundaries

- No real art assets were migrated.
- No full MetaProgress was implemented.
- No action combat was implemented.
- No Deploy UI was implemented.
- Debug buttons remain available but are not the only way to play.

## Known Limits

- Event rooms are placeholder interactions.
- Monster encounters use deterministic command combat.
- Standard exits are hidden random exits until discovered.
