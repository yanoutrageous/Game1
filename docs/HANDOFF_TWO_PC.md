# HANDOFF_TWO_PC

## Current Status

- Updated: `2026-06-09`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Work repository on this PC: `D:\AGAME2\repo\Game1`
- G4 baseline branch: `godot/lua-parity-p0`
- G4 baseline commit: `688f3bc72be6a0f521956001eeb9657fa4c43e26`
- Current G5 branch: `godot/g5-asset-ui-presentation`
- Lua baseline branch: `lua-prototype-main`
- Lua baseline commit: `d53d117af8c786014292c2981b7edfdaf11182ea`

## Branches To Use

- `godot/g5-asset-ui-presentation`: current G5 implementation branch.
- `godot/lua-parity-p0`: read-only G4/P0 baseline for comparison.
- `lua-prototype-main`: read-only Lua prototype baseline.
- `main`: do not use for G5.

## Required Checks

```powershell
git remote -v
git branch --show-current
git status --short
git log -1 --oneline
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
```

## Push Safety

Never push to `https://github.com/yanoutrageous/Game.git`. Never force push. Do not push or merge G5 without explicit user approval.

## Stage Documents

- `Godot/GraytailGodot/docs/GODOT_ASSET_UI_PARITY_G5_REPORT.md`
- `docs/branch_changes/G5_ASSET_UI_PRESENTATION_BRANCH.md`
- `docs/audits/G5_ASSET_UI_PARITY_AUDIT.md`
- `docs/handoff/HANDOFF_G5_ASSET_UI_PRESENTATION.md`
