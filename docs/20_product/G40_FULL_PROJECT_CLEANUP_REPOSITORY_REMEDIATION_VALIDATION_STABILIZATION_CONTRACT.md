# G40 Full Project Cleanup / Repository Remediation / Validation Stabilization Contract

> Historical frozen contract (2026-07-26 clarification): this file preserves
> the G40 machine layout and closeout-era wording. Its `D:\AGAME1` paths and
> “in progress” status are not current authority. Resolve the active repository
> with `git rev-parse --show-toplevel`; use `docs/10_current/CURRENT_STATE.md`
> and the stage indexes for current status.

Status: in progress / PASS_WITH_NOTES after G40 Slice 12.

Chinese summary: G40 is the project cleanup and validation-stabilization stage. It reorganizes current entrypoints, documents source boundaries, records duplicate and dirty-state policy, and prepares reliable validation gates. The G40 branch has been committed and pushed, and Slice 12 restored `project.godot` to HEAD. G40 remains PASS_WITH_NOTES because residual duplicate/manual/reference decisions and optional runtime validations remain unresolved.

## Objective

G40 must make the project easier to verify and continue from by:

1. Establishing the current `D:\AGAME1` topology.
2. Clarifying the active Game1 repository entrypoint.
3. Separating protected sources, handoff material, workflow material, reports, and active engineering work.
4. Recording duplicate-file decisions without unapproved deletion.
5. Classifying dirty state without hiding unresolved metadata/config changes.
6. Providing a current validation entrypoint.

## Current Canonical Entrypoints

```text
Root entrypoint: D:\AGAME1\README_CURRENT_ENTRYPOINTS.md
Active repo: D:\AGAME1\_repo_cache\Game1_work
Godot project: D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot
Repo docs: D:\AGAME1\_repo_cache\Game1_work\docs
Current validation entrypoint: tools/validate_current_project.ps1
Current G40 branch head: ad883310232ca9756371fb68eb3d0176a56e809e
Current origin G40 branch head: ad883310232ca9756371fb68eb3d0176a56e809e
Main/origin main baseline: aa57a4270e047ef83020c333b30af225aa1a5ffb
```

## Topology Rules

Current canonical top-level partitions:

```text
D:\AGAME1\active
D:\AGAME1\sources
D:\AGAME1\handoff
D:\AGAME1\archive
D:\AGAME1\reports
D:\AGAME1\workflow
D:\AGAME1\tools
D:\AGAME1\external
```

Legacy paths are retained only as labeled moved/superseded mappings. They are not current canonical paths.

## Source And Handoff Rules

- Source originals live under `D:\AGAME1\sources`.
- Connection handoff material lives under `D:\AGAME1\handoff\connection`.
- Repo docs may register and cite external source paths, but must not copy source bodies to solve reference problems.
- Base Docs / art / handoff content is protected from unapproved rewrite, move, delete, or import.

## Duplicate Decision Policy

- `D:\AGAME1\reports\g40\duplicate_resolution_plan.csv` is evidence, not deletion authorization.
- Duplicate archive/delete execution remains pending until a later audited cleanup slice.
- Reference-blocked rows must be rechecked after path migration before any move/archive/delete.
- Manual-decision rows remain blocked until a user or audit gate resolves them.

## Dirty-State Policy

`Godot/GraytailGodot/project.godot` was pre-existing dirty at G40 start.

Slice 12 policy:

```text
status: restored_to_head
patch evidence: D:\AGAME1\reports\g40\project_godot_dirty.patch
decision: restore rather than accept unowned Godot 4.6 editor/config rewrite
current active repo dirty count: 0
```

Generated metadata cleanup tools are dry-run by default unless a later explicit gate approves mutation.

## Report Consolidation Policy

G40 working reports are consolidated under:

```text
D:\AGAME1\reports\g40
```

This consolidation is evidence organization only. It does not authorize duplicate deletion, stale worktree removal, or historical report archive actions.

## Slice 9B Cleanup Execution Policy

Slice 9B executed only audit-approved cleanup:

```text
D:\AGAME1\_repo_cache\Game_git_compare -> D:\AGAME1\archive\stale_checkouts\Game_git_compare
D:\AGAME1\_repo_cache\Game_feature_editor_playable_prototype -> D:\AGAME1\archive\stale_checkouts\Game_feature_editor_playable_prototype
```

No files were deleted, no registered Git worktree was removed, and no active repository content was cleaned.

## Branch Commit / Push Status

Slice 10 committed and pushed the G40 docs/tools validation entrypoint state:

```text
commit: ad883310232ca9756371fb68eb3d0176a56e809e
message: chore(project): stabilize G40 cleanup validation entrypoints
branch: origin/godot/g40-full-project-cleanup-validation-stabilization
```

Slice 11 records this status only. It does not merge or push main.

## Validation Policy

Current validation command:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_current_project.ps1
```

Expected current result:

```text
G40_UNIFIED_VALIDATION=PASS_WITH_NOTES
```

`PASS_WITH_NOTES` is expected because cleanup is still in progress.

## Non-Goals

G40 does not:

1. Implement gameplay features.
2. Claim gameplay runtime PASS.
3. Claim manual playtest PASS.
4. Complete LongTerm, Warehouse, Objective / Reward / Pool, or Rule Engine.
5. Import art or resources.
6. Rewrite external source/handoff bodies.
7. Delete or archive duplicates without later approval.
8. Clean `project.godot` or generated metadata without a later gate.

## Pending Before Final Completion

- Later cleanup gates: registered worktree lifecycle, generated cache/profile policy, active repo duplicate review, reference-blocked rows, and manual decisions.
- Slice 10 branch commit/push is complete.
- Later main merge/push gate, if G40 is accepted.
- Godot smoke, if later gate approves it.
- Optional later Godot 4.6/project config adoption gate, if a product/config owner wants to accept the restored diff deliberately.
