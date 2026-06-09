# Handoff: G6 Lua Playable Parity P1 Core

## Status

G6 implementation branch: `godot/g6-lua-playable-parity-p1-core`.

Base: `godot/g5-asset-ui-presentation` at `95a14b0d6905d0fadd5ad56cd399cd52f7b02721`.

## What Changed

- Formal WASD/arrow input now moves inside the current room through `PlayerController.move_local`.
- Room coordinates now change through `CommandBus.attempt_room_transition` only after a door/boundary transition request.
- MapOverlay can flag hidden cells and teleport to explored safe cells.
- Event rooms now resolve trader, dice, altar, and trap outcomes.
- Monster rooms expose deterministic enemy state and fight results.
- Search/chest rewards, mine re-entry, extraction, failure salvage, and ResultPanel snapshots are richer.
- Tutorial popup state now supports once/blocking semantics and locks formal input while blocking.
- Added G6 static validation.

## Required Validation

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
```

## Safety

- Do not modify `D:\AGAME1`.
- Do not run Godot/editor/import unless separately authorized.
- Do not merge to `main`.
- Do not force push.
- Push only the G6 branch to `https://github.com/yanoutrageous/Game1.git`.
