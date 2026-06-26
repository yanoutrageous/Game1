# G35 Runtime Safety / Ownership Cleanup Validation

## 中文结论摘要（DOC-GOV-001）

G35 记录 runtime safety 与 ownership cleanup。它说明 MetaProgress read-only fallback、DebugGate、CommandBus debug hard gate、EventService result return、RunScene 当前 runtime owner 和 GameKernel inactive/bootstrap placeholder 的边界；不实现完整 SaveManager、active-run persistence、完整 RunFlow、真实 DeployPrep RunBootstrapper、新 gameplay systems、gameplay runtime PASS 或 manual playtest PASS。

本验证摘要只概括原 validation 的验证对象、边界和未声明项。具体 PASS/命令以原 validation 正文为准；不得把 parser/headless smoke 写成 gameplay runtime PASS 或 manual playtest PASS。


Stage: G35-R2 Engineering Stabilization / Runtime Ownership Cleanup.

## Scope

G35 hardens existing M1 runtime seams without adding new gameplay systems.

- Persistence safety: `MetaProgressAdapter` no longer writes storage during `_init()` or `load_or_create_default()`.
- Save parsing safety: `SaveAdapter.load_json_result()` returns explicit status, error, and read-only fallback data for parse/open/future-schema failures.
- Debug safety: `DebugGate` gates dev tools by debug/editor or explicit project setting; `CommandBus` rejects debug-source commands when disabled.
- Event result safety: `RoomResolver.interact_current_room()` returns the real `EventService.execute_default()` result.
- Ownership safety: `GameKernel` is explicitly inactive while `RunScene` owns the current authoritative `RunContext` / `CommandBus`.
- DeployPrep boundary: existing RunBootstrapper wording remains preview/boundary text only.

## Validation Commands

```powershell
git diff --check
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_g35_runtime_safety.ps1
```

Godot headless project-load/parser smoke is required before commit when the local Godot executable is available.

## Boundaries

- No Base Docs or Connection writes.
- No `project.godot`, scene, resource, import, `.uid`, or `.translation` changes.
- No `core/command` command surface expansion beyond debug execution gating.
- No complete SaveManager, active-run persistence redesign, complete RunFlow rewrite, or DeployPrep RunBootstrapper implementation.
- No gameplay runtime PASS claimed.
- No manual playtest PASS claimed.
