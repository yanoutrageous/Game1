# Active Stage Index

Status: no active art stage assigned after ART21 closeout.

## Active Stage

| Stage | Lane | Status | Evidence | Boundary |
| --- | --- | --- | --- | --- |
| None | art / UI runtime | ART21 closed; successor not yet named | `docs/art/ART21_CLOSEOUT_MAIN_MENU_SCENE_RECONSTRUCTION.md`; `docs/art/validation/art21/` | Do not infer or start ART22 without an explicit new requirement. |

## Current Baselines

| Item | Current fact |
| --- | --- |
| Active repo | Resolve with `git rev-parse --show-toplevel`; no drive-letter authority |
| Active implementation branch | `art/art21-main-menu-scene-reconstruction` |
| Upstream implementation base | `origin/art/art21r1-ue-parity-existing-assets` |
| Base head at continuation start | `3dbb843e34f16a9a10b7122a0e094c457a7057c6` |
| Main baseline at continuation start | `ecc628d15838288aae17f250ac0298fc79cb15c7` |
| Godot project | `<git-worktree-root>/Godot/GraytailGodot` |
| Main-menu design canvas | 1280×720 |
| Latest closed art stage | ART21 main-menu scene reconstruction |
| Latest closed non-art stage | I0; project-stage authority confirmed by the user, while I0 evidence artifacts are not present on this ART21 branch |

## Stage Interpretation

- ART21 placement-contract work and ART21R1 UE-parity repair are preliminary
  slices retained as evidence.
- The full main-menu scene reconstruction, including the preliminary slices,
  closed as ART21 after live assembly, motion, multi-resolution evidence and
  validation passed.
- G40 is a historical repository-cleanup stage and is not the active execution
  stage on this branch.
- I0 is the latest project progress outside the art lane. This branch records
  that stage authority without fabricating I0 implementation or validation
  evidence that has not yet been synchronized here.
- Gameplay content expansion, economy changes, save-model changes, and new
  area/difficulty routing screens are outside ART21.

## Path Authority

`D:\AGAME1` references in historical reports describe another machine. Current
scripts and active documents must resolve repository paths relative to the active
worktree and must accept external source roots as explicit parameters when they
are genuinely needed.
