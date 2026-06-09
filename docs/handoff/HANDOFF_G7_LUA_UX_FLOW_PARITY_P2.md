# Handoff: G7 Lua UX Flow Parity P2

## Status

G7 implementation branch: `godot/g7-lua-ux-flow-parity-p2`.

Base: `godot/g6-lua-playable-parity-p1-core` at `ee43cfa272d247c57fceda1ff4a43e39e44f7ae1`.

## What Changed

- Added a main menu shell before entering runs.
- Added a read-only deploy shell with warehouse, requisition, loadout, recovery, and talent tabs.
- Moved run UI into stable zones: left HUD/MiniMap, center room, right protocol/debug rail, bottom action bar.
- Added event option, loot result, and extraction confirmation panels.
- Kept formal movement room-local and Debug grid movement separated.
- Added G7 static validation.

## Required Validation

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_ux_flow_parity_g7.ps1
```

## Safety

- Do not modify `D:\AGAME1`.
- Do not run Godot/editor/import unless separately authorized.
- Do not merge to `main`.
- Do not force push.
- Push only the G7 branch to `https://github.com/yanoutrageous/Game1.git`.
