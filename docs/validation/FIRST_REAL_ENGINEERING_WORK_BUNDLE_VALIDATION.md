# FIRST-REAL-ENGINEERING-WORK-BUNDLE-001 Validation

Stage: `FIRST-REAL-ENGINEERING-WORK-BUNDLE-001`

This record documents the first controlled real program-lane engineering bundle. The bundle is intentionally limited to static validation tooling and validation documentation.

## Exact Allowlist

Created paths:

- `tools/validate_lua_require_graph.ps1`
- `tools/validate_lua_selftest_registry.ps1`
- `docs/validation/FIRST_REAL_ENGINEERING_WORK_BUNDLE_VALIDATION.md`

Explicitly out of scope:

- `README.md`
- Godot project/runtime/import files
- protected dirty translation/project files
- Git staging, commit, push, reset, clean, stash, checkout, or switch
- npm package fetch or external package install

## Validation Commands

PowerShell parser check:

```powershell
$paths = @(
  'D:\AGAME1\_repo_cache\Game1_work\tools\validate_lua_require_graph.ps1',
  'D:\AGAME1\_repo_cache\Game1_work\tools\validate_lua_selftest_registry.ps1'
)
foreach ($p in $paths) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile($p, [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) { exit 1 }
}
```

Result:

```text
PARSE_PASS=D:\AGAME1\_repo_cache\Game1_work\tools\validate_lua_require_graph.ps1
PARSE_PASS=D:\AGAME1\_repo_cache\Game1_work\tools\validate_lua_selftest_registry.ps1
```

Lua require graph static validation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\AGAME1\_repo_cache\Game1_work\tools\validate_lua_require_graph.ps1
```

Result:

```text
LUA_REQUIRE_GRAPH_VALIDATION=PASS
REPO_ROOT=D:\AGAME1\_repo_cache\Game1_work
SCRIPTS_ROOT=D:\AGAME1\_repo_cache\Game1_work\scripts
CHECKED_FILES=24
REQUIRE_COUNT=47
PROJECT_REQUIRE_COUNT=45
EXTERNAL_REQUIRE_COUNT=2
```

Lua selftest registry static validation:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\AGAME1\_repo_cache\Game1_work\tools\validate_lua_selftest_registry.ps1
```

Result:

```text
LUA_SELFTEST_REGISTRY_VALIDATION=PASS
REPO_ROOT=D:\AGAME1\_repo_cache\Game1_work
TEST_FILE=D:\AGAME1\_repo_cache\Game1_work\scripts\tests\minefield_selftest.lua
DEFINED_TESTS=58
REGISTERED_TESTS=58
```

## Safety Notes

- No Godot runtime, editor, import, or smoke test was run.
- No npm package fetch or external package install was performed.
- No Git write operation was performed.
- No Git add, commit, push, reset, clean, stash, checkout, or switch was performed.
- No README update was performed.
- The existing protected dirty baseline remains excluded from this bundle.

This validation record is not project acceptance, release readiness, Git push authorization, or Godot runtime validation.
