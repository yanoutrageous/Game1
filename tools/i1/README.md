# I1-V1 unified headless validation

`invoke_i1.ps1` is the I1 baseline entry point for repeatable, isolated Godot checks. It validates a worktree or `HEAD` snapshot without writing generated Godot state, saves, logs, or reports into the source tree.

## Requirements

- Windows PowerShell 5.1 Desktop (`powershell.exe`), not PowerShell 7 (`pwsh`).
- Git available on `PATH`.
- The Godot 4.6.3 Windows standard build identified by `tools/i0/toolchain.lock.json`. The entry point verifies executable names, sizes, SHA-256 values, and `--version` output before running project code.

Godot resolution order is:

1. `-GodotExe`
2. `I1_GODOT_EXE`, then `GODOT4`, then `GODOT_EXE`
3. the command names registered in `validation_manifest.json` on `PATH`

The resolved directory must contain both pinned main and console executables. The harness hardlinks those two files into the isolated run directory without copying `_sc_`, so `user://` remains inside the run sandbox.

For this machine, the explicitly supplied local path is:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\i1\invoke_i1.ps1 `
  -Profile quick `
  -SourceMode worktree `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

The `E:\Godot` location is only a local example, not a repository default. A portable environment-variable setup is:

```powershell
$env:I1_GODOT_EXE = 'X:\portable\godot\Godot_v4.6.3-stable_win64_console.exe'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\i1\invoke_i1.ps1 -Profile quick
```

## Profiles and source modes

- `preflight`: manifest/inventory, mirror, locked toolchain, import, and `res://`/`user://` isolation only.
- `quick`: short cross-layer smoke covering core, meta, I1 safety/reliability/state authority, animation runtime, routes, and the current in-run surface.
- `core`: all I0 characterization cases plus M6, G41, M7, I1 program invariants/state authority, and the blocking combat-refresh microbenchmark.
- `ui`: UI/runtime route contracts, animation/reduced-motion behavior, and deterministic ART24 layout probes.
- `full`: every required blocking runner registered in the manifest.

`-SourceMode worktree` includes tracked and untracked source edits. `-SourceMode head` exports the current commit through an isolated Git index and rejects the run unless the active setup manifest, `.gitattributes`, `invoke_i1.ps1`, and the loaded I0 library are byte-for-byte identical to their mirrored `HEAD` copies. The I1 harness must therefore exist unchanged in `HEAD` before this mode can run. `.gitattributes` fixes these control-plane files to LF so Git checkout cannot create a false byte mismatch. Both setup/execution SHA-256 values and every control-plane file binding are recorded in `report.json`.

## Outputs and pass rules

Every run is retained under:

```text
.tmp/i1/<UTC-run-id>/
  worktree/             isolated source mirror
  process_env/          isolated APPDATA, LOCALAPPDATA, TEMP, HOME, and user:// roots
  logs/                 Godot logs
  artifacts/            static-validation report
  report.json           unified machine-readable report
```

The final console lines are `I1_REPORT_JSON=<absolute path>` and `I1_TEST_STATUS=PASS|FAIL`. `report.json` records source/mirror Git and business-snapshot timings plus the worktree mirror's pruned source inspection, copy process, and complete destination reparse inspection so harness overhead remains attributable. A runner passes only when it exits successfully, emits exactly one configured full-line PASS marker, emits no FAIL marker, does not time out, and produces no blocking engine diagnostic. Known shutdown cleanup diagnostics are fixed as exact, case-sensitive strings per runner; bootstrap and environment isolation expect none. A missing, additional, unknown, or numerically changed cleanup diagnostic fails the case instead of falling through a broad regex exemption. If a known cleanup leak is fixed, capture a new accepted full-run result and deliberately update its manifest baseline; the unexpected improvement is not silently reclassified.

The manifest derives completeness from required IDs and discovered runner/probe files; it does not freeze a total runner count or an asset-manifest row count. `I1_COMBAT_REFRESH` is the only registered performance microbenchmark. Capture/preview workflows, broader production performance acceptance, and visible interaction/animation-feel acceptance are recorded as `EXCLUDED_NON_SLICE`, never as PASS.

Before and after execution, the entry point compares the full Git state and hashes the required `Godot/GraytailGodot` and `tools` roots. Static validation requires every runner and harness/support input to fall under those roots. `.tmp`, `reports`, and `tools/runtimes` are excluded from the source mirror, and any Git or business-file pollution makes the run fail.

## Static self-test

Use this after changing the manifest or adding a runner/probe:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\tools\i1\validate_static.ps1 `
  -RepoRoot (git rev-parse --show-toplevel) `
  -GitRepoRoot (git rev-parse --show-toplevel) `
  -SourceMode worktree
```

The command must emit exactly one `I1_STATIC_VALIDATION_JSON=...` line and exit zero. Any newly discovered runner/probe must be registered as blocking or explicitly documented as a non-slice exclusion.

## Production-scene preview captures

`invoke_i1_preview.ps1` generates rapid-review PNG evidence from the production `scenes/main/main.tscn`. It delegates mirror creation, locked-Godot resolution, import, and environment isolation to the unified headless `preflight` profile, then runs the excluded capture runner inside that same `.tmp/i1/<run-id>` sandbox. PNG capture uses the real Windows/OpenGL renderer because Godot's headless display driver is a dummy renderer with no viewport texture; a short-lived game window may therefore appear during each capture.

The default is one `run` image at `1280x720`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\i1\invoke_i1_preview.ps1 `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

Several selected scenes can share one preflight/mirror:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\i1\invoke_i1_preview.ps1 `
  -Scene run,combat,result_failure `
  -Resolution 1280x720 `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

`-All` captures the complete cross-product of these production states and resolutions:

- States: `main_menu`, `deploy`, `long_term`, `run`, `combat`, `inventory`, `map`, `result_success`, `result_failure`.
- Resolutions: `1280x720`, `1600x900`, `1920x1080`.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\i1\invoke_i1_preview.ps1 -All
```

PNG files are written to `.tmp/i1/<run-id>/previews/`. Each generated file emits exactly one line in this form:

```text
I1_PRODUCTION_PREVIEW=PASS scene=<scene> size=<width>x<height> output=<absolute-png-path>
```

The wrapper writes `preview_report.json` and finishes with `I1_PREVIEW_STATUS=PASS_WITH_VISUAL_REVIEW_REQUIRED` when generation and pollution checks pass. This status only proves that the production scene rendered and a PNG was saved. The manifest deliberately records `i1_production_preview_capture_runner.gd` as `EXCLUDED_NON_SLICE`; composition, readability, animation feel, and interaction quality still require human review and are never reported as automated visual PASS.

An empty scene or resolution selection is rejected. After preflight, the wrapper loads the mirrored manifest and rejects any manifest, preview-wrapper, main-entry, or I0-library byte mismatch. `preview_report.json` embeds the source `HEAD`/tree identity, manifest and control-plane SHA-256 bindings, the preflight report hash, capture-runner hash, and a SHA-256 value for every generated PNG. Preview cleanup diagnostics are also exact per scene because the production states have distinct known resource counts.
