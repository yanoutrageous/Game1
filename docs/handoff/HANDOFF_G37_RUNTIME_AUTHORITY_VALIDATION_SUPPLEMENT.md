# Handoff G37S Runtime Authority Validation / Handoff Supplement

Document status: handoff supplement
Stage: G37S-R2 Runtime Authority Validation / Handoff Supplement
Date: 2026/06/26

## 1. What G37S Does

G37S only strengthens validation and handoff evidence for G37. It does not modify runtime implementation code.

This supplement exists to prevent future regressions back to multiple runtime fact sources or direct lifecycle mutation outside runtime authority.

## 2. Confirmed G37 Authority Boundaries

- `RunRuntimeController` is the active runtime owner.
- `RunStateMachine` owns lifecycle transitions.
- `CommandBus` delegates lifecycle transitions.
- `RunScene` is orchestration-only for runtime construction.
- `RunFlowStateContract` is projection-only.
- `GameKernel` remains inactive / non-authoritative.
- `DebugGate` remains the guard for debug force extract / fail commands.

## 3. Deferred To G38+

G37S explicitly leaves these unresolved and hands them off:

- RunScene decomposition.
- GameKernel deprecation or full ownership handoff decision.
- Modifier / Effect migration from preview into real execution.
- TruthMap split / deeper runtime map ownership.
- `.gitattributes`, LFS, and binary asset policy.

Recommended next stage:

```text
G38: RunScene Decomposition / App Runtime Boundary Cleanup
```

## 4. Required Validation Before G38

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_g35_runtime_safety.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g36_runtime_architecture.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g37_runtime_authority.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g37_runtime_authority_supplement.ps1
```

Godot project-load/parser smoke may be run if available. It is not gameplay runtime PASS and not manual playtest PASS.
