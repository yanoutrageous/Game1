# G37 Runtime Authority / RunFlow Execution Validation

Document status: validation record
Stage: G37-R2 Runtime Authority / RunFlow Execution Consolidation
Date: 2026/06/26

## 1. Scope Validated

G37 validates that the current M1 runtime authority is consolidated around:

- `RunRuntimeController`
- `RunStateMachine`
- `CommandBus` lifecycle delegation
- `RunScene` orchestration-only construction
- projection-only `RunFlowStateContract`
- hard-disabled `GameKernel` runtime driver

## 2. Static Validation Targets

Observed PASS commands:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_g35_runtime_safety.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g36_runtime_architecture.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g37_runtime_authority.ps1
git diff --check
```

`tools/validate_g37_runtime_authority.ps1` checks:

- `RunRuntimeController` owns active `RunContext` and `CommandBus`
- `CommandBus` delegates start/extract/fail lifecycle paths
- `combat_state.gd`, `room_resolver.gd`, `command_bus.gd`, and other non-authority files do not call `context.fail_run(...)` directly
- HP depletion, fatal mine, event trap, and debug force failure route through `RunRuntimeController` / `RunStateMachine`
- `RunScene` no longer directly constructs `RunContext` / `CommandBus`
- `RunFlowStateContract` remains projection-only
- `GameKernel` cannot drive a second runtime context in G37
- no forbidden metadata diff is present
- command-sequence regression returns `G37_COMMAND_SEQUENCE_REGRESSION=PASS`

## 3. Godot Headless Validation Targets

Observed PASS commands:

```powershell
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --quit
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" "res://scenes/run/run_scene.tscn" --quit
```

These are project-load / parser / scene-load checks only.

Observed notes:

- `tools/validate_g37_runtime_authority.ps1` returned `G37_RUNTIME_AUTHORITY_VALIDATION=PASS`.
- The G37 command-sequence runner returned `G37_COMMAND_SEQUENCE_REGRESSION=PASS`.
- Godot project-load / parser smoke exited successfully.
- Godot scene-load smoke exited successfully with ObjectDB/resource leak warnings; these warnings are recorded and are not gameplay runtime PASS.
- Smoke produced no committed metadata diff.

## 6. R3 Blocker Fix Coverage

G37-R2 follow-up fixes the R3 blocker where `combat_state.gd` and `room_resolver.gd` could call `context.fail_run(...)` directly. Failure lifecycle transitions now route through runtime authority:

- combat HP depletion passes a fail authority into `CombatState`.
- fatal mine failure in `RoomResolver` calls runtime authority.
- event trap HP depletion carries the same fail authority through `EventService`.
- `CommandBus` binds `RoomResolver` to the current `RunRuntimeController`.
- `context.fail_run(...)` is allowed only in the `RunContext` primitive and the `RunStateMachine` authority path.

## 4. Explicit Non-Claims

- Gameplay runtime PASS is not claimed.
- Manual playtest PASS is not claimed.
- Complete RunFlow rewrite is not claimed.
- SaveManager active-run persistence is not implemented.
- Main merge / main push are not part of G37-R2.

## 5. Metadata Result Policy

Any Godot metadata generated during smoke must be excluded from the staged diff. `project.godot`, scene/resource files, `*.uid`, `*.translation`, and `*.import` must not be committed in G37.

The final commit hash and final PASS/FAIL command results are recorded in the execution report.
