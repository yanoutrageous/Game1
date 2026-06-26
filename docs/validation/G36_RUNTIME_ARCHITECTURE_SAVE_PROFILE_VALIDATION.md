# G36 Runtime Architecture / Save Profile Validation

Stage: G36-R2 Runtime Architecture Consolidation & Save/Profile Foundation.

## Validation Targets

- `MetaProgressAdapter` blocks writes when loaded through read-only fallback.
- Save profile paths are represented by `SaveProfileManifest` and consumed through `SaveManager`.
- RunScene delegates meta commits to `RunSceneMetaCommitter`.
- RunScene delegates debug room lookup to `RunSceneDebugBridge`.
- RunScene delegates surface/minimap view-model assembly to `RunSceneUIBridge`.
- Run start payloads are normalized by `RunStartRouteAdapter` / `RunStartConfig`.
- DeployPrep/AppShell use the bounded route payload and do not create a RunBootstrapper.
- `CommandBus` still gates debug commands through `DebugGate`.
- No `project.godot`, scene, resource, uid, translation, import metadata, Base Docs, or Connection changes are included.

## Commands

Expected validation commands:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_g35_runtime_safety.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g36_runtime_architecture.ps1
git diff --check
```

Godot headless project-load/parser smoke should be recorded when run. It must not be reported as gameplay runtime PASS or manual playtest PASS.

## G36-R2 Result

- `tools/validate_g35_runtime_safety.ps1`: PASS.
- `tools/validate_g36_runtime_architecture.ps1`: PASS.
- `git diff --check`: no whitespace errors; LF/CRLF warnings only.
- Godot headless import smoke: PASS.
- Godot headless project-load/parser smoke: PASS.
- Godot headless scene-load smoke for `res://scenes/run/run_scene.tscn`: PASS.
- Godot import generated translation / `.gd.uid` metadata; tracked translation was restored and untracked metadata was precisely removed without `git clean`.
- No `project.godot`, scene, resource, uid, translation, import metadata, Base Docs, or Connection changes remain in the planned diff.

## Not Implemented

G36 does not implement full active-run persistence, complete SaveManager UI, runtime profile switching, full RunBootstrapper, real warehouse/objective/reward/settlement writes, new gameplay content, gameplay runtime PASS, or manual playtest PASS.
