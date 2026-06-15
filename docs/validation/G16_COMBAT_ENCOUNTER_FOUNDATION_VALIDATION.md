# G16 Combat Encounter Foundation Validation

## Scope

- Stage: G16 combat_basic / monster_basic encounter foundation.
- Branch: `godot/g16-combat-encounter-foundation`.
- Baseline main: `a28ae4c0c96f0b964602fd6fe7b88fa254354763 docs: mark G15 merged to main`.
- R3 commit: `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a feat(godot): add combat encounter foundation`.
- R4 status: accepted.
- R5 status: docs-only closeout / handoff / status calibration.
- G15 status: complete, merged to `main`, and closed.
- G16 branch merged to main: no.
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

## R5 Closeout Record

- G16-R1: battle room / monster encounter audit and architecture boundary review.
- G16-R2: `combat_basic` / `monster_basic` execution plan.
- G16-R3: implementation and push at `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a`.
- G16-R4: acceptance passed.
- G16-R5: current docs-only branch closeout; no business code, runtime/UI/rule code, resource, font, import product, `.uid`, `.translation`, or `project.godot` changes.
- Remote main remains `a28ae4c0c96f0b964602fd6fe7b88fa254354763`.
- The branch is not merged to `main`.
- Local user planning docs remain untracked and uncommitted: `docs/主菜单策划案.md`, `docs/战斗房与怪物遭遇通用规则策划案.md`, and `docs/出发探索界面与出勤准备规则策划案.md`.

## R5 Static Validation Commands

Run from repository root:

```powershell
git diff --stat
git diff --check
git status --short
git diff --name-only
rg -n "G16|combat_basic|monster_basic|attack_basic|runtime PASS|parser PASS|Godot/editor/game/import|main|merged|Boss|boss|elite|skill|action combat|real-time combat|lottery|MetaProgress|Deploy persistence" docs Godot/GraytailGodot/docs
```

Expected R5 static result:

- Diff is docs-only.
- No runtime/parser PASS is claimed.
- G17 is not started.
- Boss, elite, multi-monster combat, skills, passive systems, action combat, real-time combat, lottery, out-of-run progression, MetaProgress, and Deploy persistence remain unimplemented.
- G16 remains a branch-level closeout until a later authorized branch-to-main integration.

## Parser Blocker Fix Record

- Blocker: Godot headless project-load/parser smoke reported parser-visible class reference failures for `EncounterContract`, `EncounterResolver`, and `RunSurface`.
- Fix scope: parser-safe class visibility only.
- Code semantics: no combat settlement, damage, reward, room-clearing, stats, CommandBus routing, encounter field semantics, UI behavior, resource, or project setting changes.
- Fix details:
  - `command_bus.gd`, `run_query_facade.gd`, `run_rule_service.gd`, and `encounter_resolver.gd` now use explicit preload aliases for G15/G16 encounter helper scripts.
  - `run_scene.gd` no longer depends on the `RunSurface` global class name for parser type resolution; it still instantiates the same `RunSurfaceScript`.
- Smoke command:

```powershell
D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot --quit
```

- Result: Godot headless project-load/parser smoke PASS.
- This is not a complete gameplay runtime PASS and not a manual playtest PASS.
- Smoke produced no new dirty files; `project.godot`, resources, fonts, import products, `.uid`, and `.translation` remain untouched.
