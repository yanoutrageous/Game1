# AUDIT_G3_GODOT_LUA_PARITY_P0

## Scope

Audit G3 Godot Lua Parity P0 implementation against the imported specs under `docs/lua_audit`.

## Required Sources Read

- `docs/HANDOFF_TWO_PC.md`
- `docs/REPO_POLICY.md`
- `docs/ENGINEERING_STATUS.md`
- `docs/HANDOFF_TWO_PC_CURRENT_BRANCHES.md`
- `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`
- `docs/lua_audit/LUA_DEEP_AUDIT_REPORT.md`
- `docs/lua_audit/LUA_TO_GODOT_PARITY_SPEC.md`
- `docs/lua_audit/LUA_SYSTEM_CALLGRAPH.md`
- `docs/lua_audit/LUA_PARITY_TASKS_FOR_GODOT.csv`

## P0 Coverage

- Tutorial mode: 5x5, seed 777, fixed Lua-derived 0-based map, 4 mines, 4 events, 5 monsters, 4 chests, 1 fixed exit.
- Standard mode: 10x10, 20 mines, 10 monsters, 10 chests, 10 events, 2 hidden random exits.
- TruthMap/IntelMap: real map truth and player-known public state remain separated.
- CommandBus: player and Debug UI commands route through CommandBus.
- RoomResolver: movement entry effects, mine first-hit only, search/chest once-only rewards, event placeholder, deterministic monster fight, and exit-only extraction are implemented.
- UI: HUD, MiniMap, and ResultPanel consume snapshots/ViewModels and do not directly read TruthMap.

## Not In Scope

- Real art asset migration.
- Full MetaProgress.
- Deploy UI.
- Action combat.
- P1/P2 event detail expansion beyond P0 accessible placeholders.

## Validation

Required validation commands:

```powershell
git remote -v
git branch --show-current
git status --short
git log -1 --oneline
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
```

Godot headless checks should run only if a local Godot executable is available without install or global config changes.

## Result

G3 P0 is ready for validation and handoff on `godot/lua-parity-p0`. Next stages must not begin automatically.
