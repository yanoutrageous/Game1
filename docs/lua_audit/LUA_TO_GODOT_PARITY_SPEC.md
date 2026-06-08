# LUA_TO_GODOT_PARITY_SPEC

## Purpose

This document extracts migration-ready rules from `D:\2026.6\GAME` for aligning `D:\Godot\GraytailGodot` with the Lua playable prototype. It is a specification, not an instruction to copy source code. The target is Godot parity for the Lua tutorial and standard run loops while preserving the S2 architecture boundaries:

- `TruthMap` owns real map truth.
- `IntelMap` owns player-known information.
- UI reads ViewModels/snapshots, not TruthMap.
- Commands go through `CommandBus`.
- Room behavior goes through `RoomResolver`.
- Content references go through `ContentDB`.

## Systems Godot Must Align First

P0 systems for first Lua parity pass:

1. `RunConfig` / mode config resource: represent tutorial and standard mode parameters.
2. `TruthMap`: support manual map and generated standard map, with real cell state.
3. `IntelMap`: support visible/public cell state equivalent to `Minefield:_PublicCell()`.
4. `RunContext`: hold run phase, turn, player, stats, inventory, combat, protocol, and settlement state.
5. `MinefieldService`: implement 1-step cardinal movement support, 8-neighbor mine count, random placement, hidden exits, reveal/flag/explore/clear.
6. `CommandBus`: expose start tutorial, start standard, move, flag, search, interact, attack/fight, extract confirm/cancel, open map, teleport to explored.
7. `RoomResolver`: apply enter/search/event/combat/mine/extract rules.
8. `RunInventory`: pending/safe gold, carried items, search rewards, chest rewards, failure salvage, extraction reward.
9. `ProtocolService`: 0..100 pressure and levels 5..1.
10. `HUDViewModel`, `MiniMapViewModel`, `ResultViewModel`: match Lua visible status, not TruthMap internals.

P1 systems:

- Event option UI and full trader/dice/altar/trap flows.
- Deterministic combat and monster clear rewards.
- MapOverlay interaction: flag hidden, teleport explored safe cells.
- Tutorial popup text/presentation.

P2 systems:

- Full MetaProgress: warehouse, recovery history, shop, equipment, consumables, talents.
- Action combat timing/positioning.
- Deploy terminal UI.

## 5x5 Tutorial Mode Migration Tasks

### Required Config

Create a Godot tutorial run config equivalent to `Tutorial.GetMapConfig()`:

- mode: `tutorial`
- width: 5
- height: 5
- seed: 777
- mine_count: 4
- random_exit_count: 0
- mine_hits_are_fatal: false
- reveal_on_move: true
- move_requires_revealed: false
- use_loadout: false
- apply_meta_progress: false
- allow_warehouse_rewards: false
- allow_failure_rewards: false

### Required Manual Map

Godot coordinates should choose one convention. Recommended: internal Godot coordinates stay 0-based, while imported Lua specs are converted at load time. If converted to 0-based:

| Lua 1-based | Godot 0-based | Type |
|---|---|---|
| `(1,1)` | `(0,0)` | Spawn/Normal |
| `(1,3)`, `(2,2)`, `(3,1)`, `(4,4)` | `(0,2)`, `(1,1)`, `(2,0)`, `(3,3)` | Mine |
| `(1,4)`, `(2,3)`, `(3,2)`, `(4,1)` | `(0,3)`, `(1,2)`, `(2,1)`, `(3,0)` | Event |
| `(1,5)`, `(2,4)`, `(3,3)`, `(4,2)`, `(5,1)` | `(0,4)`, `(1,3)`, `(2,2)`, `(3,1)`, `(4,0)` | Monster |
| `(2,5)`, `(3,4)`, `(4,3)`, `(5,2)` | `(1,4)`, `(2,3)`, `(3,2)`, `(4,1)` | Chest |
| `(5,5)` | `(4,4)` | Exit `tutorial_exit` |

### Required Tutorial Trigger Data

Add `TutorialService` or data-driven tutorial triggers:

- `spawn_intro`: `(1,1)`
- `number_rule`: `(1,2)`, `(2,1)`
- `mine_rule`: `(1,3)`, `(2,2)`, `(3,1)`
- `event_rule`: `(1,4)`, `(2,3)`, `(3,2)`, `(4,1)`
- `monster_rule`: `(1,5)`, `(2,4)`, `(3,3)`, `(4,2)`, `(5,1)`
- `chest_rule`: `(2,5)`, `(3,4)`, `(4,3)`, `(5,2)`
- `map_rule`: `(3,5)`, `(5,3)`
- `mine_review`: `(4,4)`
- `route_rule`: `(4,5)`, `(5,4)`
- `exit_goal`: `(5,5)`

Behavior:

- Do not retrigger when still in same room.
- `once` popups should mark shown ids.
- Blocking popup locks input until confirm.
- Delayed popup can be shown after room effect resolution.
- Exact popup body text is a content task; trigger ids and semantics are P0.

## 10x10 Standard Mode Migration Tasks

### Required Config

Create a standard run config equivalent to `StartNewGame()` defaults:

| Field | Required Value |
|---|---:|
| width | 10 |
| height | 10 |
| mine_count | 20 |
| spawn_safe_radius | 0 |
| path_width | 0 |
| random_exit_count | 2 |
| monster_room_count | 10 |
| chest_room_count | 10 |
| event_room_count | 10 |
| mine_hits_are_fatal | false |
| reveal_on_move | true |
| move_requires_revealed | false |

### Required Generator Semantics

Implement deterministic generation close to Lua:

1. Seeded RNG.
2. Random spawn in normal mode if spawn is not locked.
3. Build empty grid.
4. Reserve critical cells.
5. Place mines on non-reserved cells.
6. Assign special rooms from safe non-spawn, non-exit, normal candidates.
7. Assignment order: monsters, chests, events, random exits.
8. Random exits are hidden until revealed.
9. Compute 8-neighbor mine adjacency after mines/special rooms are placed.

If exact RNG parity is not required for the first pass, Godot may use its own deterministic RNG but must satisfy count/visibility/one-time trigger invariants.

## TruthMap / IntelMap / RunContext Additions

### TruthMap Additions

Add true per-cell data:

- `pos`
- `mine: bool`
- `room_type: StringName` with `Normal`, `Mine`, `Chest`, `Event`, `Monster`, `Exit`
- `spawn: bool`
- `exit_id: StringName`
- `random_exit: bool`
- `reserved: bool`
- `path: bool`
- `adjacent_mines: int`
- `revealed: bool` may live in IntelMap if strict separation is desired; Lua keeps it in Minefield.
- `flagged: bool` should live in IntelMap.
- `explored: bool`
- `cleared: bool`

Required methods:

- `setup_from_config(config)`
- `setup_manual_map(config)`
- `setup_standard_map(config)`
- `get_cell(pos)`
- `set_room_type(pos, room_type)`
- `is_mine(pos)`
- `get_adjacent_mine_count(pos)`
- `get_exits()`
- `get_visible_exits(intel_map)`
- `mark_explored(pos)`
- `mark_cleared(pos)`

### IntelMap Additions

IntelMap should be the Godot version of Lua `Minefield:_PublicCell()`:

- `state`: `hidden`, `flagged`, `mine`, `empty`, `number`
- `revealed`
- `flagged`
- `adjacent_mines`: only when revealed
- `room_type`: only when revealed
- `mine`: only when revealed or debug reveal
- `exit_id`: non-random exits visible; random exits visible only after revealed
- `random_exit`: only if exit id visible
- `explored`
- `cleared`
- `asset_id` / fallback label for UI

Required methods:

- `setup(width, height)`
- `reveal_cell(pos, truth_map)`
- `toggle_flag(pos)`
- `get_cell_info(pos)`
- `get_visible_map()`
- `build_public_cell(pos, truth_map, reveal_mines=false)`

### RunContext Additions

Current S2 fields are enough for sandbox but not parity. Add:

- `mode`
- `seed_value`
- `phase`: `running`, `confirm_extract`, `extracted`, `failed`, `event`, `battle`
- `turn`
- `exit_id`
- `mine_hits_are_fatal`
- `move_requires_revealed`
- `reveal_on_move`
- `visited_cells` or `explored_cells`
- `searched_cells`
- `entered_cells`
- `interacted_cells`
- `pending_gold`
- `safe_gold`
- `parts`
- `carried_items`
- `consumables`
- `hp`, `max_hp`, `power`
- `mine_immunity`, `mine_dmg_reduce`
- `pressure`, `protocol_level`, `max_pressure`
- `run_stats`: moves, searched rooms, chest rooms, mine hits, monsters defeated, combat damage, trades, events completed, turns
- `current_room_type`
- `current_adjacent_mines`
- `last_message`
- `last_reward`
- `result_snapshot`

## CommandBus Additions

Current S2 commands: `start_demo_run`, `move_by`, `flag_current_cell`, `interact`, `extract`, `restart_run`.

Add P0/P1 commands:

| Command | Purpose |
|---|---|
| `start_tutorial_run` | Start 5x5 fixed tutorial mode. |
| `start_standard_run` | Start 10x10 generated standard mode. |
| `move_by(delta)` | Keep exact cardinal/blocked/reveal/mine/exit result semantics. |
| `toggle_flag_cell(pos=current)` | Allow current cell or target cell, for MapOverlay. |
| `search_current_room` | Search normal/chest rooms. |
| `interact_current_room` | Dispatch event/trader/chest/monster/exit context. |
| `select_event_option(option_id)` | Execute event option. |
| `fight_current_enemy` | Deterministic combat clear. |
| `attack_current_enemy` | Later action-combat mode. |
| `open_map_overlay` | Build overlay ViewModel. |
| `teleport_to_explored(pos)` | MapOverlay return to explored safe cell. |
| `request_extract` | Enter confirm extract state. |
| `confirm_extract` | Apply settlement and show result. |
| `cancel_extract` | Return to running. |
| `confirm_tutorial_popup` | Release input lock and mark shown. |
| `use_consumable(item_id)` | P1/P2, emergency bandage parity. |

## RoomResolver Additions

Current S2 `RoomResolver` handles small placeholders. Add rule branches:

### Enter Room

- reveal unknown cell if `reveal_on_move`.
- mark first explore and add pressure +2.
- if mine and first trigger: damage through Combat/RunContext, pressure +10, mark mine revealed, block repeat damage.
- if monster: spawn deterministic enemy, show enemy hint.
- if event: assign deterministic event type, show enter message.
- if chest: expose searchable chest state.
- if exit: expose extraction availability.
- normal/spawn: expose adjacent mine count and search state.

### Search Room

- Reject unrevealed/mine/spawn/exit/monster/event/searched.
- Normal search: gold 0..2 + floor(adjacent/2), cap 4, possible item.
- Chest search: gold 3..7 + adjacent, cap 11, guaranteed 1-2 item-backed drops.
- Mark searched once.
- Chest clear should mark room cleared.

### Events

- Event types: trader, dice, altar, trap.
- Completed events cannot repeat reward.
- Event results can change pending/safe gold, carried items, HP, power, pressure, completion state.

### Combat

First parity should implement `FightEnemy`:

- if player power >= enemy power: no damage.
- else damage = enemyPower - playerPower.
- enemy clears either way.
- reward 0..3 pending gold.
- monster kill power gain +1, capped +5 per run.

Action-combat update/attack can be a later mode.

### Extraction and Failure

- Request extraction only on visible/revealed exit cell with `exit_id`.
- Confirm extraction sets phase extracted and creates settlement result.
- Tutorial writes no outside reward.
- Failure loses pending gold and loose parts; safe gold can be retained; salvage behavior should keep one highest-value carried item if implementing failure recovery.

## MiniMapViewModel / HUDViewModel Additions

### MiniMapViewModel

Fields should mirror public visible map:

- `width`, `height`
- `markers` array with `pos`, `state`, `label`, `asset_id`
- `player_pos`
- `highlight_cells`
- per cell: `revealed`, `flagged`, `adjacent_mines`, `room_type`, `exit_id`, `random_exit`, `explored`, `cleared`
- fallback labels: `?`, `F`, `*`, numbers, `P`, `M`, `C`, `E`, `G`, `X`, `!`, or project-specific labels.

Critical rule: MiniMapViewModel must be built from IntelMap/public cells, not from TruthMap directly.

### HUDViewModel

Add structured fields instead of only multiline text:

- HP/max HP
- power
- protocol level/description/pressure/max
- pending gold
- safe gold
- carried item count/value/summary
- consumables summary
- position
- room type visible name
- adjacent mines
- search state: can search, searched, reason, is chest
- event state: event name, completed, options count
- enemy state: enemy name/power/HP, alive
- exit state: can extract, exit id
- last message
- tutorial popup state
- interaction hint

### Result Snapshot

Add:

- outcome: extracted / failed / training_complete
- pending gold, safe gold, total gold
- carried item count/value/summary
- searched rooms, explored rooms, events completed, mine hits, monsters defeated, trades, turns
- final HP, final pressure, final position
- failure salvage details if failed.

## Lua Rules to Carry Over Exactly

Carry over as close as possible:

- 5x5 tutorial map coordinates and popup trigger ids.
- 10x10 standard counts: 20 mines, 10 monsters, 10 chests, 10 events, 2 hidden random exits.
- Non-fatal mine entry and once-only mine damage.
- 8-neighbor adjacency counts real mines only.
- Hidden random exit visibility rule.
- Search eligibility rules.
- Search/chest reward ranges and caps.
- Event type set and option outcomes.
- Protocol pressure thresholds.
- Extraction only from exit cell.
- Tutorial disables meta loadout/reward effects.
- UI must receive public/Intel view only.

## Lua Rules to Use as Reference, Not Direct Copy

- Exact RNG implementation can be approximated if counts and deterministic seed behavior are preserved.
- UrhoX layout/hit rectangles and NanoVG rendering should be replaced with Godot UI.
- Action combat timers/positions can be deferred; deterministic combat is enough for first parity.
- MetaProgress can be deferred unless the milestone requires shop/equipment/talents.
- Text strings should be curated in Godot resources rather than copied blindly.

## Lua / UrhoX Glue Not to Migrate

Do not port:

- `uiRoot_` node lookup logic.
- NanoVG immediate-mode drawing functions.
- CG/video startup/skip code.
- `.meta` sidecar handling.
- `.cli` tools.
- UrhoX-specific asset paths.
- GM/debug grant/reset functions, except as optional Godot debug commands later.
- UE migration code and resources.

## Recommended Godot Implementation Order

1. Add data configs for tutorial and standard modes.
2. Extend TruthMap/IntelMap to represent public cell state and hidden random exits.
3. Implement generator/manual map setup.
4. Extend RunContext with phase/turn/inventory/combat/protocol/stats.
5. Add CommandBus commands for tutorial/standard/search/fight/event/extract.
6. Extend RoomResolver for enter/search/mine/chest/event/monster/exit/failure.
7. Expand HUD/MiniMap/Result ViewModels.
8. Add static validation for parity invariants.
9. Add Godot headless and runtime smoke tests after implementation.

## Acceptance Criteria for First Parity Pass

- Tutorial mode starts as 5x5 with exact Lua room layout.
- Standard mode starts as 10x10 and validates counts: 20 mines, 10 monsters, 10 chests, 10 events, 2 hidden exits.
- Moving into a hidden safe room reveals it and updates IntelMap/HUD/MiniMap.
- Moving into a mine damages once and never retriggers on re-entry.
- Searching normal/chest rooms grants one-time rewards using Lua ranges.
- Event rooms expose trader/dice/altar/trap options and one-time completion.
- Monster rooms support deterministic fight and room clear.
- Extraction only works on exit and produces settlement result.
- UI scripts still do not directly read TruthMap.

## Self Check

- This is a migration specification only.
- No Lua source was modified.
- No Godot code was modified.
- No assets were copied.
- No Git operations beyond read-only status/search were required.
