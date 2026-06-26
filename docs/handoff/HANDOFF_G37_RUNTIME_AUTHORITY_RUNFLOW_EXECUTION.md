# Handoff G37 Runtime Authority / RunFlow Execution Consolidation

Document status: handoff
Stage: G37-R2 Runtime Authority / RunFlow Execution Consolidation
Date: 2026/06/26

## 1. What Changed

G37 consolidates the M1 runtime authority path:

- Added `RunRuntimeController` as owner of the active context and command bus.
- Added `RunStateMachine` for lifecycle transitions.
- Updated `CommandBus` to delegate start / extract / fail lifecycle transitions.
- Updated `RunScene` to use the runtime controller instead of constructing a separate runtime pair.
- Routed combat HP depletion, fatal mine, and event trap failure through `RunRuntimeController` / `RunStateMachine`.
- Updated validation to reject direct `context.fail_run(...)` outside `RunContext`, `RunStateMachine`, and the runtime-controller wrapper boundary.
- Kept `RunFlowStateContract` projection-only.
- Kept `GameKernel` hard-disabled as a runtime driver.

## 2. Preserved Boundaries

G37 does not add new gameplay systems, SaveManager active-run persistence, Objective / Reward / Pool runtime, warehouse writes, reward grants, settlement economy changes, scene files, resources, or import metadata.

## 3. Validation Handoff

G37-R2 local validation has passed with:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_g35_runtime_safety.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g36_runtime_architecture.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g37_runtime_authority.ps1
```

Then run Godot headless project-load / parser smoke and scene-load smoke from the repo root using the correct project path:

```text
D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot
```

Observed notes: G35, G36, and G37 validation scripts passed. Godot project-load / parser and scene-load smoke exited successfully. Scene-load emitted ObjectDB/resource leak warnings, but no gameplay runtime PASS or manual playtest PASS is claimed.

## 4. Non-Claims

- No gameplay runtime PASS is claimed.
- No manual playtest PASS is claimed.
- No main merge is performed in G37-R2.
- No main push is performed in G37-R2.

## 5. Next Recommended Gate

Proceed to unified G37-R3 audit / release gate after branch push validation is reviewed.
