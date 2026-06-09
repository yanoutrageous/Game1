# Handoff: G5 Asset UI Presentation

## Status

G5 implementation branch: `godot/g5-asset-ui-presentation`.

Base: `godot/lua-parity-p0` at `688f3bc72be6a0f521956001eeb9657fa4c43e26`.

## What Changed

- Added AssetCatalog and manifest-backed asset lookup.
- Added PresentationMapping and PresentationTheme.
- Migrated a limited audited asset batch to the Godot project.
- Added MapOverlay and TutorialPopup UI surfaces.
- Updated HUD, MiniMap, ResultPanel, room visual, and player visual presentation.
- Added G5 static validation.

## Required Validation

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
```

## Safety

- Do not modify `D:\AGAME1`.
- Do not push without user approval.
- Do not run Godot/editor/import unless separately authorized.
- Do not merge to `main`.
