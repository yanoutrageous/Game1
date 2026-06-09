# GODOT_CURRENT_STATUS

## Updated

`2026-06-09`

## Branch

Current G5 work branch: `godot/g5-asset-ui-presentation`.

Base branch: `godot/lua-parity-p0`.

Base commit: `688f3bc72be6a0f521956001eeb9657fa4c43e26`.

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
- Player-facing start buttons remain available for `Start Tutorial 5x5` and `Start Standard 10x10`.
- Keyboard play remains movement, E interact/search/extract, Space/J fight, F flag, M/Tab map overlay, and R restart.

## Validation

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
```

Do not run Godot/editor/import unless separately authorized.

## Current Unfinished Items

- No full MetaProgress.
- No Deploy UI.
- No action combat.
- No video/music/font migration.
- No full event trader/dice/altar/trap parity.
- No push or merge to `main`.
