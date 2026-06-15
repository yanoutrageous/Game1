# Handoff: G16 Combat Encounter Foundation

## Identity

- Stage: G16 combat_basic / monster_basic encounter foundation.
- Branch: `godot/g16-combat-encounter-foundation`.
- Baseline main: `a28ae4c0c96f0b964602fd6fe7b88fa254354763 docs: mark G15 merged to main`.
- R3 commit: `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a feat(godot): add combat encounter foundation`.
- R4 status: accepted.
- R5 status: docs-only branch closeout.
- Parser blocker fix commit: `4637e8fa0eeec6859df4eab26d5a961868e4c071 fix(godot): expose encounter parser classes`.
- Merged to main: yes, by fast-forward.
- Main HEAD after fast-forward and before this post-merge status commit: `4637e8fa0eeec6859df4eab26d5a961868e4c071`.
- Remote main before final push: `a28ae4c0c96f0b964602fd6fe7b88fa254354763`.

## Completed

- `combat_basic`, `monster_basic`, and `attack_basic` public encounter foundation.
- Monster rooms expose public `encounter_view_model` data through the G15 Encounter framework.
- Public Monster summary, risk summary, reward preview, and combat result summary.
- `select_encounter_option` additively bridges Monster `attack_basic` to the existing `fight_current_enemy` deterministic combat path.
- `CombatState` only adds summary / preview helpers; existing fight settlement semantics remain unchanged.
- `RunSurfaceModel` only adds display-only combat/monster field mapping.
- `RunSurface` remains unchanged.
- `run_scene.gd` keeps the same orchestration behavior; the parser blocker fix only removes dependency on the `RunSurface` global class name for type resolution.
- Validation, manual checklist, and status docs are updated.
- Godot headless project-load/parser smoke passed after the parser blocker fix.

## Not Completed

- Complete gameplay runtime PASS.
- Manual playtest PASS.
- Boss, elite, multi-monster combat, skills, passive systems, leave confirmation, teleport restriction, combat animation, complete monster library, complete drop economy, codex system, action combat, real-time combat, lottery, out-of-run progression, MetaProgress, or Deploy persistence.

## Validation Boundary

- Godot headless project-load/parser smoke was run with `D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe` and passed.
- No complete gameplay runtime PASS or manual playtest PASS is claimed.
- Godot editor, gameplay/manual run, and import were not run.
- `project.godot`, resources, fonts, import products, `.uid`, `.translation`, and user planning docs are not part of the G16 merge.
- Planning source files now live under `D:\AGAME1\Base Docs` and are not part of this repository commit.
- `docs/可行性判断.md` and `docs/难度判断.md` were moved by the user to `D:\AGAME1\Base Docs`; their repository deletions are authorized docs relocation deletions.

## Next Candidates

- Later combat-room enhancement stage.
- Later deploy / expedition-prep or main-menu planning.

These are candidates only. G17 is not started by this handoff.
