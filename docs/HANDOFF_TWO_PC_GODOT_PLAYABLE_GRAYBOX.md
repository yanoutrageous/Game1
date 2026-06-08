# HANDOFF_TWO_PC_GODOT_PLAYABLE_GRAYBOX

## Branch

Continue from:

```text
godot/lua-parity-p0
```

## Current Stage

Godot playable graybox v0.1 on top of G3 Lua parity P0.

## How To Validate On Computer 2

From:

```text
D:\AGAME2\repo\Game1\Godot\GraytailGodot
```

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_playable_graybox_v0_1.ps1
```

Godot headless:

```powershell
D:\Godot\downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\AGAME2\repo\Game1\Godot\GraytailGodot --editor --quit
D:\Godot\downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\AGAME2\repo\Game1\Godot\GraytailGodot --quit-after 1
```

## Manual Play Entry

- Use `Start Tutorial 5x5` for the fixed training map.
- Use `Start Standard 10x10` for the generated standard map.

## Boundaries

- Do not start the next stage automatically.
- Do not merge into `main`.
- Do not push `main` or `lua-prototype-main`.
- Do not force push.
- Do not migrate real art assets.
- Do not implement full MetaProgress, action combat, or Deploy UI as part of this stage.
