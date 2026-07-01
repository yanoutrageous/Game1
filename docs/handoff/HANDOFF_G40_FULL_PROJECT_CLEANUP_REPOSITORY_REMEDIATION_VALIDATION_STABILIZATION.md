# Handoff G40 Full Project Cleanup / Repository Remediation / Validation Stabilization

Status: in-progress handoff after G40 Slice 11.

Chinese summary: G40 has established current topology, repo docs entrypoints, dirty-state tooling, a validation entrypoint, Slice 9A report consolidation, restricted Slice 9B stale-checkout archive execution, and a pushed G40 docs/tools branch commit. Registered worktree, cache/profile, active repo duplicate, reference-blocked, and `project.godot` config decisions still require later gates.

## Current State

```text
active_root: D:\AGAME1
active_repo: D:\AGAME1\_repo_cache\Game1_work
branch: godot/g40-full-project-cleanup-validation-stabilization
branch_head: ad883310232ca9756371fb68eb3d0176a56e809e
origin_branch_head: ad883310232ca9756371fb68eb3d0176a56e809e
main_origin_main: aa57a4270e047ef83020c333b30af225aa1a5ffb
validation_entrypoint: tools/validate_current_project.ps1
expected_marker: G40_UNIFIED_VALIDATION=PASS_WITH_NOTES
```

## Next Required Gates

1. Remaining duplicate / registered-worktree / cache-profile cleanup cannot run without later audit approval.
2. `project.godot` remediation requires a separate metadata/config decision gate.
3. Optional Godot/M5/G39 runtime validation requires a later explicit validation gate.
4. No main merge/push is authorized by this handoff.
5. No final completion claim is authorized until remaining G40 notes are resolved or explicitly accepted.

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

- `project.godot` is pre-existing dirty and unresolved.
- Root G40 working reports are consolidated into `D:\AGAME1\reports\g40`.
- Slice 9B archived `Game_git_compare` and `Game_feature_editor_playable_prototype` to `D:\AGAME1\archive\stale_checkouts`.
- Registered worktrees were not removed.
- Generated/browser cache/profile duplicate content remains manual, not deleted.
- Reference-blocked duplicate rows remain unresolved.
- Godot smoke is not run in G40 Slice 11.
- G40 branch commit and push are complete at `ad883310232ca9756371fb68eb3d0176a56e809e`.
- Main was not merged or pushed.

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
