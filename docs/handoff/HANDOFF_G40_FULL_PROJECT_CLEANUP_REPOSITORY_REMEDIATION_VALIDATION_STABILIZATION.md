# Handoff G40 Full Project Cleanup / Repository Remediation / Validation Stabilization

Status: in-progress handoff after G40 Slice 21.

Chinese summary: G40 has established current topology, repo docs entrypoints, dirty-state tooling, a validation entrypoint, Slice 9A report consolidation, restricted Slice 9B stale-checkout archive execution, and pushed G40 branch commits. Slice 12 restored `project.godot` to HEAD by audit decision, leaving the active repo clean. Slice 13 ran the approved in-boundary non-Godot validation chain. Slice 14 moved the remaining root `Godot` shell and 20260622 root audit reports into their canonical G40 areas. Slice 15 removed five clean non-active registered worktrees with `git worktree remove` without `--force`. Slice 16 resolved and removed the remaining dirty generated-metadata registered worktree. Slice 17 refreshed duplicate-state evidence after those topology/worktree changes. Slice 18 policy-closed 10002 workflow Edge CDP generated-cache duplicate rows as `generated-ignore / processed_by_policy_no_delete`, with no deletion, movement, archive, copy, or cache cleanup. Slice 19 classified 3003 canonical/protected-source residual duplicate rows as final non-destructive dispositions. Slice 20 classified 94 workflow blocker rows as retained workflow/generated evidence. Slice 21 classified the remaining 109 tracked active-repo duplicate-review rows as retained final dispositions for G40 accounting. Future physical consolidation is a separate asset-reference migration / art asset dedupe topic, not a G40 blocker.

## Current State

```text
active_root: D:\AGAME1
active_repo: D:\AGAME1\_repo_cache\Game1_work
branch: godot/g40-full-project-cleanup-validation-stabilization
slice_20_base_head: e4d5c1fdbe3dde1532d9d13da9cb3228b3b38d5a
origin_branch_head_at_slice_20_start: e4d5c1fdbe3dde1532d9d13da9cb3228b3b38d5a
main_origin_main: aa57a4270e047ef83020c333b30af225aa1a5ffb
validation_entrypoint: tools/validate_current_project.ps1
expected_marker: G40_UNIFIED_VALIDATION=PASS_WITH_NOTES
registered_worktree_topology: active_only
```

## Next Required Gates

1. Physical active-repo asset dedupe cannot run without a later dedicated asset-reference migration / art asset dedupe gate. Slice 21 only closed G40 duplicate accounting by retained disposition.
2. Optional Godot/M5/G39 runtime validation requires a later explicit validation gate and an allowed in-boundary Godot executable path.
3. No main merge/push is authorized by this handoff.
4. No final completion claim is authorized until remaining G40 notes are resolved or explicitly accepted.

## Do Not Stage Without Later Approval

```text
Godot/GraytailGodot/project.godot
*.translation
*.uid
*.import
scene/resource files
external source or handoff content
stale worktree files
generated metadata
```

## Current Unresolved Items

- `project.godot` was restored to HEAD in Slice 12 after audit approval; prior patch evidence remains at `D:\AGAME1\reports\g40\project_godot_dirty.patch`.
- Root G40 working reports are consolidated into `D:\AGAME1\reports\g40`.
- Slice 9B archived `Game_git_compare` and `Game_feature_editor_playable_prototype` to `D:\AGAME1\archive\stale_checkouts`.
- Slice 15 removed five clean non-active registered worktrees.
- Slice 16 resolved the remaining dirty generated-metadata registered worktree and removed it; current registered worktree topology is active-only.
- Slice 17 refreshed duplicate-state evidence after worktree cleanup:
  - previous current-path manifest rows: 23306
  - currently existing rows: 13208
  - no-longer-present rows after topology/worktree cleanup: 10098
  - remaining `needs_manual_decision`: 109
  - remaining `blocked_by_reference`: 155
  - protected source rows still present: 670
  - active repo rows still present: 1394
  - workflow/cache/report rows still present: 11136
- Slice 17 evidence files:
  - `D:\AGAME1\reports\g40\duplicate_resolution_plan_current_paths_after_slice16.csv`
  - `D:\AGAME1\reports\g40\duplicate_current_state_summary_after_slice16.md`
  - `D:\AGAME1\reports\g40\remaining_manual_decisions_after_slice16.md`
  - `D:\AGAME1\reports\g40\remaining_reference_blockers_after_slice16.md`
- Slice 18 classified 10002 workflow Edge CDP generated-cache duplicate rows as `generated-ignore / processed_by_policy_no_delete`:
  - deleted: false
  - archived: false
  - moved: false
  - cache/profile cleanup: false
  - existing rows not policy-closed by Slice 18: 3206
  - evidence: `D:\AGAME1\reports\g40\generated_cache_duplicate_policy_closure_after_slice17.md`
  - evidence CSV: `D:\AGAME1\reports\g40\generated_cache_duplicate_policy_closure_after_slice17.csv`
  - summary: `D:\AGAME1\reports\g40\duplicate_current_state_summary_after_slice18.md`
- Slice 19 classified 3003 canonical/protected-source residual rows as final non-destructive dispositions:
  - physical action: none
  - active repo duplicate-review rows still requiring asset-reference audit before Slice 21: 109
  - historical/reference/workflow-state rows still requiring later decision: 94
  - true unresolved rows after Slice 19 classification: 203
  - evidence: `D:\AGAME1\reports\g40\residual_duplicate_final_disposition_after_slice19.md`
  - evidence CSV: `D:\AGAME1\reports\g40\residual_duplicate_final_disposition_after_slice19.csv`
  - active repo blocker CSV: `D:\AGAME1\reports\g40\active_repo_duplicate_review_remaining_after_slice19.csv`
  - reference/workflow blocker CSV: `D:\AGAME1\reports\g40\reference_or_workflow_state_blockers_remaining_after_slice19.csv`
  - summary: `D:\AGAME1\reports\g40\duplicate_current_state_summary_after_slice19.md`
- Slice 20 classified the 94 workflow blocker rows as retained workflow/generated evidence:
  - Edge/CDP transport generated/reference-retained rows: 81
  - workflow state/policy/receipt/report retained rows: 13
  - physical action: none
  - evidence: `D:\AGAME1\reports\g40\workflow_blocker_final_disposition_after_slice20.md`
  - evidence CSV: `D:\AGAME1\reports\g40\workflow_blocker_final_disposition_after_slice20.csv`
  - summary: `D:\AGAME1\reports\g40\duplicate_current_state_summary_after_slice20.md`
- Slice 21 classified the 109 tracked active-repo duplicate-review rows as retained final dispositions:
  - active runtime assets retained: 75
  - legacy/reference assets retained for future migration decision: 14
  - validation screenshot evidence retained: 9
  - UE placeholder `.gitkeep` rows retained: 10
  - runtime font retained: 1
  - physical action: none
  - delete/move/archive/copy approvals: 0
  - unresolved duplicate-review rows for G40 accounting: 0
  - evidence: `D:\AGAME1\reports\g40\active_repo_duplicate_final_disposition_after_slice21.md`
  - evidence CSV: `D:\AGAME1\reports\g40\active_repo_duplicate_final_disposition_after_slice21.csv`
  - summary: `D:\AGAME1\reports\g40\duplicate_current_state_summary_after_slice21.md`
- Godot smoke is not run in G40 Slice 13 because no `D:\AGAME1`-local Godot executable is available and `D:\Godot` is forbidden by the G40 boundary.
- M5/G39 static validators passed in Slice 13; their runtime runners were not run and are not claimed.
- Slice 14 moved `D:\AGAME1\Godot` to `D:\AGAME1\external\godot_reference\Godot`; this is not the active Godot project.
- Slice 14 moved `D:\AGAME1\AGAME1_code_audit_delivery_report_20260622.*` to `D:\AGAME1\reports\code_audit_20260622`.
- G40 branch commit and push were complete through Slice 19 at `e4d5c1fdbe3dde1532d9d13da9cb3228b3b38d5a` before this Slice 20 status update.
- Main was not merged or pushed.

## Slice 13 Validation Evidence

```text
git status --short --branch: clean G40 branch tracking origin
git diff --check: PASS
tools/inspect_dirty_state.ps1: G40_DIRTY_STATE_INSPECTION=PASS_WITH_NOTES
tools/validate_current_project.ps1: G40_UNIFIED_VALIDATION=PASS_WITH_NOTES
tools/validate_g40_cleanup_topology.ps1: G40_TOPOLOGY_VALIDATION_RESULT=PASS_WITH_NOTES
tools/scan_g40_path_references.ps1: G40_PATH_REFERENCE_SCAN=PASS_WITH_NOTES
tools/prepare_validation_clean_state.ps1: G40_VALIDATION_CLEAN_STATE_DRY_RUN=PASS_WITH_NOTES
tools/clean_generated_dirty_state.ps1: G40_GENERATED_DIRTY_DRY_RUN=PASS
tools/validate_m3_minimum_item_drop_loop.ps1: PASS
tools/validate_m3r_item_usability_completion.ps1: PASS
tools/validate_m3h_item_loop_hardening.ps1: PASS
tools/validate_m4s_metadata_branch_clean_checkout.ps1: PASS
tools/validate_m5_item_drop_loop_full_content.ps1: PASS
tools/validate_g36_runtime_architecture.ps1: PASS
tools/validate_g37_runtime_authority.ps1: PASS
tools/validate_g37_runtime_authority_supplement.ps1: PASS
tools/validate_g38_runtime_architecture_finalization.ps1: PASS
tools/validate_g39_navigation_boundary.ps1: PASS
```

## Validation Command

Run from `D:\AGAME1\_repo_cache\Game1_work`:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_current_project.ps1
```

Expected current result:

```text
G40_UNIFIED_VALIDATION=PASS_WITH_NOTES
```

## Safety Boundary

- Do not run `git clean`, `git reset --hard`, `git stash *`, `git pull`, `git fetch`, or `git rebase`.
- Do not run Godot unless a later validation gate explicitly approves it.
- Do not modify `D:\AGAME1\sources` or `D:\AGAME1\handoff` source bodies.
- Do not delete or archive files based only on duplicate evidence.
- Do not use stale Slice 9B duplicate counts for cleanup decisions; use the Slice 17-21 refreshed reports.
- Slice 21 retained active-repo duplicate assets; do not describe them as physically deduplicated, removed, cleaned, or safe to delete.
- Do not claim gameplay runtime PASS or manual playtest PASS.
