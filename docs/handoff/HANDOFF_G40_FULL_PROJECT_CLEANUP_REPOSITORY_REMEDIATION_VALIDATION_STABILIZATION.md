# Handoff G40 Full Project Cleanup / Repository Remediation / Validation Stabilization

Status: in-progress handoff after G40 Slice 13.

Chinese summary: G40 has established current topology, repo docs entrypoints, dirty-state tooling, a validation entrypoint, Slice 9A report consolidation, restricted Slice 9B stale-checkout archive execution, and pushed G40 branch commits. Slice 12 restored `project.godot` to HEAD by audit decision, leaving the active repo clean. Slice 13 ran the approved in-boundary non-Godot validation chain. Registered worktree, cache/profile, active repo duplicate, and reference-blocked decisions still require later gates.

## Current State

```text
active_root: D:\AGAME1
active_repo: D:\AGAME1\_repo_cache\Game1_work
branch: godot/g40-full-project-cleanup-validation-stabilization
slice_13_validation_base_head: 7a8ed12108a857264aeec4ed3b06f126dc9df7d5
origin_branch_head_at_slice_13_validation: 7a8ed12108a857264aeec4ed3b06f126dc9df7d5
main_origin_main: aa57a4270e047ef83020c333b30af225aa1a5ffb
validation_entrypoint: tools/validate_current_project.ps1
expected_marker: G40_UNIFIED_VALIDATION=PASS_WITH_NOTES
```

## Next Required Gates

1. Remaining duplicate / registered-worktree / cache-profile cleanup cannot run without later audit approval.
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
- Registered worktrees were not removed.
- Generated/browser cache/profile duplicate content remains manual, not deleted.
- Reference-blocked duplicate rows remain unresolved.
- Godot smoke is not run in G40 Slice 13 because no `D:\AGAME1`-local Godot executable is available and `D:\Godot` is forbidden by the G40 boundary.
- M5/G39 static validators passed in Slice 13; their runtime runners were not run and are not claimed.
- G40 branch commit and push are complete through Slice 12 at `7a8ed12108a857264aeec4ed3b06f126dc9df7d5`.
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
- Do not claim gameplay runtime PASS or manual playtest PASS.
