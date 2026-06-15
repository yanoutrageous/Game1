# Handoff: G16 Combat Encounter Foundation

## Identity

- Stage: G16 combat_basic / monster_basic encounter foundation.
- Branch: `godot/g16-combat-encounter-foundation`.
- Baseline main: `a28ae4c0c96f0b964602fd6fe7b88fa254354763 docs: mark G15 merged to main`.
- R3 commit: `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a feat(godot): add combat encounter foundation`.
- R4 status: accepted.
- R5 status: docs-only closeout.
- Merged to main: no.
- Remote main at closeout precheck: `a28ae4c0c96f0b964602fd6fe7b88fa254354763`.

## Completed

- `combat_basic`, `monster_basic`, and `attack_basic` public encounter foundation.
- Monster rooms expose public `encounter_view_model` data through the G15 Encounter framework.
- Public Monster summary, risk summary, reward preview, and combat result summary.
- `select_encounter_option` additively bridges Monster `attack_basic` to the existing `fight_current_enemy` deterministic combat path.
- `CombatState` only adds summary / preview helpers; existing fight settlement semantics remain unchanged.
- `RunSurfaceModel` only adds display-only combat/monster field mapping.
- `RunSurface` is unchanged.
- `run_scene.gd` is unchanged.
- Validation, manual checklist, and status docs are updated.

## Not Completed

- Runtime/parser PASS.
- Main merge.
- Boss, elite, multi-monster combat, skills, passive systems, leave confirmation, teleport restriction, combat animation, complete monster library, complete drop economy, codex system, action combat, real-time combat, lottery, out-of-run progression, MetaProgress, or Deploy persistence.

## Validation Boundary

- Godot/editor/game/import was not run.
- No runtime PASS or parser PASS is claimed.
- `project.godot`, resources, fonts, import products, `.uid`, `.translation`, and user local planning docs are not part of G16-R5.
- Local user planning docs remain untracked inputs only:
  - `docs/主菜单策划案.md`
  - `docs/战斗房与怪物遭遇通用规则策划案.md`
  - `docs/出发探索界面与出勤准备规则策划案.md`

## Next Candidates

- G16 branch-to-main integration.
- User-authorized runtime/parser smoke.
- Later combat-room enhancement stage.
- Later deploy / expedition-prep or main-menu planning.

These are candidates only. G17 is not started by this handoff.
