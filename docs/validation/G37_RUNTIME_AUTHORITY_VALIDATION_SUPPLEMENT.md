# G37S Runtime Authority Validation / Handoff Supplement

Document status: validation supplement
Stage: G37S-R2 Runtime Authority Validation / Handoff Supplement
Date: 2026/06/26

## 1. Supplement Scope

G37S is not G38 and is not a redo of G37. It supplements validation and handoff evidence for the runtime authority work that already landed in G37.

No core runtime code, UI code, scene/resource files, project metadata, Base Docs, or Connection files are modified by G37S.

## 2. G37 Facts Locked By This Supplement

- `RunRuntimeController` owns the active `RunContext`, `CommandBus`, and `RunStateMachine`.
- `RunStateMachine` owns run lifecycle transitions: start, request extract, confirm extract, cancel extract, fail, and force extract.
- `CommandBus` delegates lifecycle transitions to runtime authority and does not directly write `context.phase`.
- `combat_state.gd` and `room_resolver.gd` fail paths route through runtime authority.
- `RunScene` no longer directly constructs `RunContext` / `CommandBus`.
- `RunFlowStateContract` is projection-only and must not dispatch, persist, grant rewards, or write assets.
- `GameKernel` remains inactive / non-authoritative and cannot drive a second active runtime.
- Debug force extract / fail remain protected by `DebugGate` and route through runtime authority.

## 3. Supplement Validation

New supplement script:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_g37_runtime_authority_supplement.ps1
```

It reuses the base G37 validation and adds checks for:

- `context.phase =` only in `RunStateMachine` / `RunContext` primitive paths.
- `context.fail_run(` only in `RunStateMachine` / `RunContext` primitive paths.
- `RunRuntimeController` owns context, state machine, and command bus construction.
- `RunScene` does not directly construct a second runtime pair.
- `GameKernel` remains hard-disabled.
- `RunFlowStateContract` remains projection-only.
- Debug force extract / fail route through `DebugGate` and runtime authority.
- Existing command-sequence regression covers start / move / search / request extract / confirm extract; force-fail coverage is enforced by authority-path checks.
- The supplement diff does not contain core runtime code, UI code, project metadata, scene/resource files, UID, translation, or import metadata.

Observed G37S-R2 results:

- `tools/validate_g35_runtime_safety.ps1`: PASS
- `tools/validate_g36_runtime_architecture.ps1`: PASS
- `tools/validate_g37_runtime_authority.ps1`: PASS
- `tools/validate_g37_runtime_authority_supplement.ps1`: PASS
- `git diff --check`: no whitespace error
- Godot headless project-load / parser smoke: PASS with ObjectDB/resource leak warnings
- No project / scene / resource / UID / translation / import metadata diff was produced by smoke.

## 4. Explicit Non-Claims

- No gameplay runtime PASS is claimed.
- No manual playtest PASS is claimed.
- No visible playtest is required by G37S.
- No RunScene decomposition is implemented.
- No GameKernel ownership migration is implemented.
- No Modifier / Effect real execution migration is implemented.
- No TruthMap split is implemented.
- No `.gitattributes`, LFS, or binary asset policy is implemented.

## 5. Next Recommended Gate

Proceed to G38 only after G37S is accepted:

```text
G38: RunScene Decomposition / App Runtime Boundary Cleanup
```
