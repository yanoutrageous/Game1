# G40 Full Project Cleanup / Repository Remediation / Validation Stabilization Contract

Status: in progress after G40 Slice 9B.

Chinese summary: G40 is the project cleanup and validation-stabilization stage. It reorganizes current entrypoints, documents source boundaries, records duplicate and dirty-state policy, and prepares reliable validation gates. It does not implement gameplay features and does not claim final cleanup completion yet.

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

`Godot/GraytailGodot/project.godot` is pre-existing dirty at G40 start.

Current policy:

```text
status: pre_existing_unresolved
patch evidence: D:\AGAME1\reports\g40\project_godot_dirty.patch
not cleaned by Slice 6/7/8
not staged unless a later metadata/config remediation gate approves it
```

Generated metadata cleanup tools are dry-run by default. Slice 9A does not execute any metadata cleanup.

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
- Slice 10: audited final validation and commit/push gate.
- Godot smoke, if later gate approves it.
- Final decision on `project.godot` dirty handling.
