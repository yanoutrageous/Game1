# G16 Combat Encounter Foundation Validation

## Scope

- Stage: G16-R3 combat_basic / monster_basic encounter foundation.
- Branch: `godot/g16-combat-encounter-foundation`.
- Baseline main: `a28ae4c0c96f0b964602fd6fe7b88fa254354763 docs: mark G15 merged to main`.
- G15 status: complete, merged to `main`, and closed.
- Godot/editor/game/import: not run.
- Runtime/parser PASS: not claimed.

## Implementation Record

- Adds public `combat_basic` / `monster_basic` encounter constants and `attack_basic` option identity.
- Adds additive Monster summary, reward preview, risk summary, and combat result summary helpers.
- Monster rooms expose public `monster_summary` and `combat_encounter_state` through `encounter_view_model`.
- Monster rooms expose an `attack_basic` EncounterOption with public `command_payload`.
- `select_encounter_option` delegates Monster `attack_basic` to the existing deterministic `fight_current_enemy` command path.
- `RunSurfaceModel` only adds display-only labels and summaries for combat/monster fields.

## Rule Boundary

- Existing `CombatState.fight_enemy()` settlement semantics are not changed.
- Existing `RoomResolver.fight_current_enemy()` settlement semantics are not changed.
- Existing `RunRuleService.apply_combat_reward()` settlement semantics are not changed.
- Search, chest, event, extract, loot, settlement, and old command behavior remain on their previous paths.
- UI does not read `TruthMap`, `RunRuleService`, Ledger, AssetLedger, RunAssetLedger, RunContext private state, or other private rule objects.
- UI does not dispatch CommandBus directly; it consumes public snapshot data and option payloads only.

## Explicit Non-Goals

- No Boss, elite, multi-monster combat, skills, passive systems, leave confirmation, teleport restriction, combat animation, full drop economy, codex, action combat, real-time combat, lottery, out-of-run progression, MetaProgress, Deploy persistence, full event library, runtime PASS, or main merge is included in G16-R3.
- Local user planning docs are not part of this commit: `docs/主菜单策划案.md`, `docs/战斗房与怪物遭遇通用规则策划案.md`, and `docs/出发探索界面与出勤准备规则策划案.md`.

## Static Validation Commands

Run from repository root:

```powershell
git diff --stat
git diff --check
git status --short
git diff --name-only
rg -n "TruthMap|RunRuleService|RunAssetLedger|AssetLedger|Ledger|RunContext|truth_map|intel_map" Godot/GraytailGodot/scripts/ui
rg -n "CommandBus\\.dispatch|fight_current_enemy|fight_enemy|CombatRuleService|select_encounter_option|attack_basic|combat_basic|monster_basic|encounter_view_model|encounter_result_summary" Godot/GraytailGodot/scripts
rg -n "lottery|pity|pool|unique collectible|warehouse|codex|appearance|MetaProgress|Deploy persistence|action combat|real-time combat|Boss|boss|elite|skill tree" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs
git diff --cached --name-only
```

## Expected Static Result

- `attack_basic` appears only as an encounter option routed through `select_encounter_option`.
- Monster combat option resolution reaches existing deterministic `fight_current_enemy`.
- No UI file references private rule objects or private run state.
- No `RunSurface` or `run_scene.gd` modification is required for G16-R3.
- No `project.godot`, resources, fonts, import products, `.uid`, `.translation`, or local user planning docs are staged or committed.
- Godot/editor/game/import remains not run; runtime PASS remains unclaimed.
