# Validation Index

Status: current validation index after G40 Slice 11.

## Current Validation Entrypoint

Run from the active repository:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_current_project.ps1
```

Expected current result during G40:

```text
G40_UNIFIED_VALIDATION=PASS_WITH_NOTES
```

`PASS_WITH_NOTES` is intentional while G40 is still in progress. It means the current state is explainable, not fully clean.

Known PASS_WITH_NOTES reasons:

```text
pre_existing_project_godot_dirty=true
g40_cleanup_in_progress=true
duplicate_execution_partial=true
duplicate_remaining_manual_and_reference_review=true
manual_playtest_claimed=false
gameplay_runtime_pass_claimed=false
```

## G40 Helper Tools

| Tool | Role | Mutation policy |
| --- | --- | --- |
| `tools/inspect_dirty_state.ps1` | Classifies dirty/staged/untracked state. | Read-only |
| `tools/scan_g40_path_references.ps1` | Classifies legacy path references. | Read-only |
| `tools/validate_g40_cleanup_topology.ps1` | Validates G40 topology in in-progress mode. | Read-only |
| `tools/clean_generated_dirty_state.ps1` | Lists generated dirty candidates. | Dry-run by default; no `-Apply` in Slice 7 |
| `tools/prepare_validation_clean_state.ps1` | Reports validation blockers and suggested future actions. | Dry-run only in Slice 7 |

## Validation Claim Boundary

- Godot headless project-load/parser smoke PASS is not gameplay runtime PASS.
- Gameplay runtime PASS must cite an actual runtime validation run.
- Manual playtest PASS must cite an actual manual playtest record.
- G40 does not claim new gameplay capability.
- G40 does not clean `project.godot` unless a later metadata/config remediation gate approves it.

## Historical Validation Originals

Historical validation originals remain in:

```text
docs/validation/
docs/handoff/
```

This index does not rewrite historical validation or handoff originals into current facts.

Recent historical/current evidence pointers:

| Stage | Evidence | Boundary |
| --- | --- | --- |
| G40 | `docs/validation/G40_FULL_PROJECT_CLEANUP_VALIDATION.md` | Current cleanup validation is IN_PROGRESS / PASS_WITH_NOTES; branch commit/push complete at `ad883310232ca9756371fb68eb3d0176a56e809e`; `project.godot`, residual duplicate decisions, and smoke remain pending later gates |
| M5 | `docs/validation/M5_MINIMUM_ITEM_PACK_DROP_LOOP_FULL_CONTENT_VALIDATION.md` | Latest gameplay baseline before G40; no manual playtest PASS unless explicitly recorded |
| G39 | `docs/validation/G39_NAVIGATION_BOUNDARY_ROUTE_CLOSURE_VALIDATION.md` | Navigation boundary closure; no full settings/Profile UI |
| G38 | `docs/validation/G38_RUNTIME_ARCHITECTURE_FINALIZATION_VALIDATION.md` | Runtime architecture finalization evidence |
| G37 | `docs/validation/G37_RUNTIME_AUTHORITY_RUNFLOW_EXECUTION_VALIDATION.md` | Runtime authority / RunFlow execution evidence |
| G36 and earlier | `docs/validation/` and `docs/handoff/` | Historical evidence, not current acceptance by this index |
