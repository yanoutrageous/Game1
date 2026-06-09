# Handoff: G7 Lua UX Flow Parity P2

## Status

G7 implementation branch: `godot/g7-lua-ux-flow-parity-p2`.

Base: `godot/g6-lua-playable-parity-p1-core` at `ee43cfa272d247c57fceda1ff4a43e39e44f7ae1`.

## What Changed

- Added a localized main menu shell before entering runs.
- Added a read-only deploy shell with warehouse, requisition, loadout, recovery, talent, and settings tabs.
- Moved run UI into stable zones: left HUD/MiniMap, center room, right protocol rail, collapsed Debug/Grid Move controls, bottom action bar.
- Added placeholder-free event option, loot result, and extraction confirmation panels.
- Localized tutorial popup, HUD hint, MapOverlay, and result panel flow copy.
- Kept formal movement room-local and Debug grid movement separated.
- Added G7 static validation for main/deploy flow, event placeholder removal, result/tutorial flow, collapsed Debug UI, and UI/TruthMap boundaries.

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
