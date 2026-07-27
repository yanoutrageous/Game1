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

## Evidence retention and disk cleanup

Each invocation intentionally creates a complete source mirror. Repeated dirty-worktree runs can therefore consume substantial space even when their reports and logs are small. Use `prune_i1_evidence.ps1` after a validation checkpoint instead of deleting run directories by hand.

The default is a dry run. It plans removal of only reproducible transient content: the isolated `process_env`, the per-run Godot hardlink view, and the mirrored project's `.godot` cache. It does not remove `*.import` sidecars, reports, manifests, logs, previews, or artifacts.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\i1\prune_i1_evidence.ps1 `
  -RunsRoot (Join-Path (git rev-parse --show-toplevel) '.tmp\i1')
```

Review the single `I1_EVIDENCE_PRUNE_JSON=...` result, then repeat with `-Apply`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\i1\prune_i1_evidence.ps1 `
  -RunsRoot (Join-Path (git rev-parse --show-toplevel) '.tmp\i1') `
  -Apply
```

A mirrored worktree is never removed implicitly. `-RemoveDuplicateWorktreeRunId <run-id>` requires an explicit run ID and an existing report-backed replacement with the same business fingerprint and file count. The replacement must either share the source commit or be a clean committed snapshot. `-RemoveCommittedWorktreeRunId <run-id>` accepts only a clean `head`-mode report whose source commit is still reachable. The command refuses a unique dirty snapshot. Explicit non-run scratch directories can be reviewed with `-RemoveScratchDirectoryName <name>`; directories containing retained report entry points are rejected.

Retention policy:

- During an active dirty stage, retain at least one full mirror for every unique business fingerprint.
- After every checkpoint, prune transient content and fingerprint-equivalent duplicate mirrors.
- Keep every referenced `report.json`, preview report, manifest, log, artifact, and rendered-review file.
- Only retire the final unique mirror after its state is reproducible from a reachable commit or a separately verified archive.
- Treat the original source pack, Base content, and imported runtime assets as project inputs, never as validation cache.

## Verified snapshot archive and governed worktree retirement

Unique worktree mirrors may be retired only through this four-tool chain:

```text
archive_i1_worktrees.ps1
  -> verify_i1_snapshot_archive.ps1
  -> restore_i1_worktree_archive.ps1
  -> prune_i1_archived_worktrees.ps1
```

The tools resolve the selected repository from Git and constrain the archive to
the Git-common workspace's `.tmp/i1_snapshot_archive`. `RunsRoot` must be the
selected worktree's exact `.tmp/i1` directory. Use a stable `Namespace` for each
source runs root and pass every `RunId` explicitly; no tool discovers deletion
targets from a wildcard.

All four tools are dry-run by default. `-Apply` is always explicit. A `PASS`
dry-run does not authorize or imply a later mutation: review its resolved
repository, runs root, archive root, namespace, target IDs, manifest identities,
index SHA-256, and proof SHA-256 first.

### 1. Archive explicit mirrors

```powershell
$repo = (git rev-parse --show-toplevel).Trim()
$runsRoot = Join-Path $repo '.tmp\i1'
$namespace = 'i3r'
$runIds = @('<run-id-1>', '<run-id-2>')

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\archive_i1_worktrees.ps1 `
  -RunsRoot $runsRoot `
  -Namespace $namespace `
  -RunId $runIds
```

The dry run emits exactly one
`I1_SNAPSHOT_ARCHIVE_JSON=<json>` marker. Review `status`, `mode`,
`archive_root`, `snapshot_count`, every manifest path/SHA-256, and the retained
evidence counts. Repeat the same command with `-Apply` to write immutable
manifests, SHA-256 sidecars, the content-addressed object store, and
`index.json`/`index.sha256`.

`-AllowMissingReportRunId` is an exception for an explicitly named legacy run;
do not use it to hide a missing report. Although the archiver retains the older
`-RestoreProof`/`-RemoveAfterVerify` interface, the governed retirement path
does not delete from the archive command. Use the separate pruner below so the
global proof, V2 restore proof, all-target preflight, locks, and transaction
receipts are enforced.

### 2. Verify the complete archive and pin its identity

Use the exact `archive_root` returned by the archive marker:

```powershell
$archiveRoot = '<I1_SNAPSHOT_ARCHIVE_JSON.archive_root>'

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\verify_i1_snapshot_archive.ps1 `
  -ArchiveRoot $archiveRoot

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\verify_i1_snapshot_archive.ps1 `
  -ArchiveRoot $archiveRoot `
  -Apply
```

Each invocation emits exactly one
`I1_SNAPSHOT_ARCHIVE_VERIFY_JSON=<json>` marker. Dry-run verifies the index,
every manifest and sidecar, every referenced CAS object, retained evidence,
path boundaries, reparse-point rejection, and alternate-data-stream rejection.
`-Apply` additionally publishes
`verification_proofs/archive-verification.json` and its SHA-256 sidecar
atomically.

Capture the `index_sha256` and `proof_sha256` from that exact successful Apply
marker. They are pins, not labels for "whatever is latest":

```powershell
$expectedIndexSha256 = '<I1_SNAPSHOT_ARCHIVE_VERIFY_JSON.index_sha256>'
$expectedGlobalProofSha256 = '<I1_SNAPSHOT_ARCHIVE_VERIFY_JSON.proof_sha256>'
```

If the archive index or a proof-bound governance tool changes, stop and produce
a new full verification/proof. Never substitute a newly observed SHA-256 into a
previously reviewed prune command without repeating the restore-proof gate.

### 3. Prove an independent V2 restore

First dry-run an explicit representative snapshot from each namespace, then
perform a real copy-based restore. `-RemoveRestoredAfterVerify` is recommended
for a deletion-gate proof because it leaves no duplicate restored tree:

```powershell
$representativeRunId = '<representative-run-id>'

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\restore_i1_worktree_archive.ps1 `
  -ArchiveRoot $archiveRoot `
  -Namespace $namespace `
  -RunId $representativeRunId

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\restore_i1_worktree_archive.ps1 `
  -ArchiveRoot $archiveRoot `
  -Namespace $namespace `
  -RunId $representativeRunId `
  -Apply `
  -RemoveRestoredAfterVerify
```

The marker is `I1_SNAPSHOT_RESTORE_JSON=<json>`. A real Apply uses
`System.IO.File.Copy`, never hardlinks, and verifies the entire restored tree
twice before publishing an immutable schema-V2 proof. Its filename binds the
manifest SHA-256, pinned index SHA-256, and restore-tool SHA-256:

```text
restore_proofs/<namespace>/<run-id>/
  <manifest>.<index>.<restore-tool>.v2.json
  <manifest>.<index>.<restore-tool>.v2.sha256
```

Record the representative manifest SHA-256 and the V2 proof file SHA-256 from
the successful Apply marker. A dry run does not write a proof and cannot satisfy
the deletion gate.

### 4. Prune only against pinned proofs

The representative proof argument binds both identities:

```powershell
$representativeManifestSha256 = '<manifest_sha256>'
$representativeProofSha256 = '<proof_sha256>'
$representativeProof = (
  "$namespace/$representativeRunId=" +
  "$representativeManifestSha256@$representativeProofSha256"
)

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\prune_i1_archived_worktrees.ps1 `
  -RunsRoot $runsRoot `
  -Namespace $namespace `
  -RunId $runIds `
  -ArchiveRoot $archiveRoot `
  -ExpectedIndexSha256 $expectedIndexSha256 `
  -ExpectedGlobalProofSha256 $expectedGlobalProofSha256 `
  -RepresentativeRestoreProof $representativeProof
```

Review the single `I1_ARCHIVED_WORKTREE_PRUNE_JSON=<json>` marker. A valid dry
run has `status=PASS`, `mode=dry_run`,
`preflight_completed_for_all_targets=true`, and no removal. Repeat the exact
reviewed command with `-Apply`. Apply preflights every requested target before
renaming or deleting any target, holds the index/proof/manifest/CAS bindings,
atomically renames each worktree to a same-volume tombstone, and re-verifies the
CAS after the batch.

Per-target immutable transaction receipts are retained under:

```text
<archive_root>/prune_transactions/<namespace>/<run-id>/<manifest-sha256>/
  01-planned.json
  02-tombstoned.json
  03-delete_started.json
  04-removed.json
```

Each JSON receipt has a same-stem `.sha256` sidecar and binds the preceding
receipt, so recovery must validate the chain rather than trusting filenames.
The worktree's run directory, `report.json`, logs, artifacts, previews, and
other registered evidence remain in place. Only the explicit `worktree`
directory is retired.

### Interrupted prune recovery

Never manually delete a `.archived_worktree_prune_*` tombstone or discard its
transaction receipts. Stop concurrent archive/prune work and inspect the
receipt chain, SHA-256 sidecars, exact manifest-bound paths, original worktree
existence, and tombstone existence.

- Latest `01-planned`: no rename should have happened. The original worktree
  must still exist and no tombstone may exist.
- Latest `02-tombstoned`, with no `03-delete_started`: after revalidating the
  pinned archive, manifest, receipt chain, and exact paths, the recoverable
  rollback is a same-volume atomic rename of the intact tombstone back to the
  exact `worktree` path. Preserve the transaction directory by renaming it with
  an `.interrupted_<UTC>` suffix, then rerun only that RunId.
- `03-delete_started` without `04-removed`: deletion may be partial. Do not move,
  copy, delete, or rerun the target. Preserve all state, re-verify the archive,
  and treat it as an explicit recovery incident.
- `04-removed`: verify that both worktree and tombstone are absent and that all
  retained evidence still matches before considering the target complete.

After a completed prune batch, run
`verify_i1_snapshot_archive.ps1 -Apply` again to publish a post-retirement
archive proof, then measure disk usage. Do not predeclare a final project size.

The original `sources.zip`, `sources/base`, the unmodified original planning
documents, Base art/draw inputs, and admitted runtime assets are not caches.
Neither evidence pruning nor snapshot retirement authorizes their deletion,
deduplication, relocation, or rewrite.

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
