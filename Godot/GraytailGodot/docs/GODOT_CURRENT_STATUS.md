# GODOT_CURRENT_STATUS

## Updated

`2026-06-09`

## Branch

Current G7 work branch: `godot/g7-lua-ux-flow-parity-p2`.

Base branch: `godot/g6-lua-playable-parity-p1-core`.

Base commit: `ee43cfa272d247c57fceda1ff4a43e39e44f7ae1`.

## Current Capability

- Tutorial P0 mode remains a 5x5 fixed Lua-derived map.
- Standard P0 mode remains a 10x10 generated map.
- TruthMap stores real map state.
- IntelMap stores player-known public state only.
- CommandBus remains the only player and Debug UI command entry.
- HUD, MiniMap, MapOverlay, TutorialPopup, and ResultPanel consume snapshots/ViewModels.
- AssetCatalog and ContentDB load assets through `data/assets/asset_manifest.csv`.
- PresentationMapping and PresentationTheme isolate asset ids, labels, hints, colors, and visual roles from core rules.
- G5 migrated a first audited asset batch for minimap icons, HUD panels, player idle sprites, room backgrounds, and room props.
- G6 separates map room coordinates from room-local player coordinates.
- Formal movement changes room-local position; room coordinates change only after transition commands.
- Event rooms resolve P1 trader, dice, altar, and trap outcomes.
- Result snapshots include carried item value and failure salvage details.
- G7 adds a main menu shell and read-only deploy shell foundation.
- G7 run UI separates left HUD/MiniMap, center room, right protocol/debug rail, and bottom action bar.
- Event option, loot result, and extraction confirmation panels are available.
- Player-facing start buttons remain available through the main/deploy shell.
- Keyboard play remains room-local movement, E interact/search/extract, Space/J fight, F flag, M/Tab map overlay, and R restart.

## Validation

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_ux_flow_parity_g7.ps1
```

Do not run Godot/editor/import unless separately authorized.

## Current Unfinished Items

- No full MetaProgress.
- No Deploy UI.
- No video/music/font migration.
- No full MetaProgress/Deploy progression economy.
- No action combat.
- No final event economy tuning.
- No persistence-backed deploy economy.
- No merge to `main`.
