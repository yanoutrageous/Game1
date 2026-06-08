# AUDIT_G3_PREP_LUA_AUDIT_IMPORT

## Scope

Audit the G3-Prep docs-only import of Lua audit and parity specification files into the Game1 repository.

## Inputs

- Repository: `D:\AGAME2\repo\Game1`
- Source files: `D:\AGAME2\Base`
- Target branch: `godot/lua-parity-p0`
- Base branch: `godot/prototype-foundation`
- Base commit: `43501afd5e9ae27338051a119bcbce67b956a713`

## Import Check

The following files were imported to `docs\lua_audit`:

- `LUA_DEEP_AUDIT_REPORT.md`
- `LUA_TO_GODOT_PARITY_SPEC.md`
- `LUA_SYSTEM_CALLGRAPH.md`
- `LUA_PARITY_TASKS_FOR_GODOT.csv`

Import behavior:

- If a target file already exists, compare SHA256 first.
- If hashes match, skip the copy.
- If hashes differ, stop and report.
- Do not overwrite mismatched audit files.

For this run, the target files were newly copied and no overwrite was performed.

## Scope Guard

Allowed changed paths for this stage:

- `docs\lua_audit\LUA_DEEP_AUDIT_REPORT.md`
- `docs\lua_audit\LUA_TO_GODOT_PARITY_SPEC.md`
- `docs\lua_audit\LUA_SYSTEM_CALLGRAPH.md`
- `docs\lua_audit\LUA_PARITY_TASKS_FOR_GODOT.csv`
- `docs\branch_changes\BRANCH_CHANGE_G3_PREP_LUA_AUDIT_IMPORT.md`
- `docs\audits\AUDIT_G3_PREP_LUA_AUDIT_IMPORT.md`
- `docs\ENGINEERING_STATUS.md`

Forbidden and not performed:

- Godot launch
- Godot P0 code implementation
- real art asset migration
- modification to `main`
- modification to `lua-prototype-main`
- force push
- push to old `Game.git`
- remote modification
- deletion

## Result

The branch `godot/lua-parity-p0` is prepared with the Lua audit/parity source files required before G3 implementation. G3 implementation should remain blocked until the user explicitly starts it.
