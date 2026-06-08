# LUA_DEEP_AUDIT_REPORT

## Scope

- Lua prototype: `D:\2026.6\GAME`
- Godot project checked for parity gap: `D:\Godot\GraytailGodot`
- Report output: `D:\AGAME1\_codex_reports`
- Execution mode: source and document read only; no game/runtime/tool execution.

## Read Files

Key Lua files read and cross-checked:

- `scripts/main.lua`
- `scripts/systems/Minefield.lua`
- `scripts/systems/ExtractionRun.lua`
- `scripts/systems/RunInventory.lua`
- `scripts/systems/Combat.lua`
- `scripts/systems/EventSystem.lua`
- `scripts/systems/Protocol.lua`
- `scripts/systems/MetaProgress.lua`
- `scripts/systems/Tutorial.lua`
- `scripts/systems/Balance.lua`
- `scripts/systems/GameText.lua` by dependency and symbol references
- `scripts/ui/HUD.lua`
- `scripts/ui/MiniMap.lua`
- `scripts/ui/MapOverlay.lua`
- `scripts/tests/minefield_selftest.lua`
- related docs under `docs/`, especially `design-integration-plan.md`, `integration-self-check.md`, `v03-balance-port-self-check.md`, `CODEX_TASKS.md`, and `难度判断.md`.

Godot S2 files read for gap analysis:

- `docs/S1_INTERFACE_CONTRACTS.md`
- `docs/S2_RULE_LOOP_REPORT.md`
- `scripts/core/run/run_context.gd`
- `scripts/core/map/truth_map.gd`
- `scripts/core/intel/intel_map.gd`
- `scripts/core/command/command_bus.gd`
- `scripts/core/run/room_resolver.gd`
- `scripts/core/content/content_db.gd`
- `scripts/ui/hud/hud_view_model.gd`
- `scripts/ui/minimap/minimap_view_model.gd`
- `scripts/ui/result/result_panel.gd`

## Lua Prototype Current Maturity

The Lua prototype is a mature playable prototype, not just a sketch. It has a complete minesweeper + extraction loop, a fixed tutorial mode, a tuned 10x10 standard mode, event/combat/search/extraction/failure settlement, HUD/minimap/map overlay, and a sizable meta-progression layer. The codebase is still prototype-shaped: `scripts/main.lua` is a large orchestration file that mixes flow control, UrhoX UI glue, rendering hooks, input handlers, and gameplay calls. The system modules contain the reusable game rules that should be treated as the Godot migration source of truth.

Maturity categories:

| Area | Status | Notes |
|---|---|---|
| Core run loop | Complete/playable | Start run, reveal, move, search, fight, event, extract, fail. |
| Minefield generation | Complete/playable | Random 10x10 and manual 5x5 maps, hidden exits, special room counts, adjacency. |
| Tutorial | Complete prototype | Fixed 5x5 manual map, coordinate popups, blocking/non-blocking popup flow. |
| Run inventory | Complete prototype | Pending/safe gold, carried items, search/chest rewards, failure salvage, extraction reward. |
| Combat | Playable with two styles | Direct deterministic fight and room-local action combat; normal search power-up disabled. |
| Events | Playable prototype | Trader, dice, altar, trap with deterministic assignment and one-time completion. |
| Protocol/pressure | Complete lightweight system | 0-100 pressure, levels 5 to 1. Extra penalty flag currently false. |
| HUD/MiniMap/MapOverlay | Complete prototype UI | NanoVG render layer and UrhoX-specific assets/fallbacks. |
| MetaProgress | Broad prototype | Economy, equipment, consumables, talents, warehouse, recovery history. P2 for Godot. |
| UrhoX glue | Prototype glue | Should not be directly migrated; extract behavior contracts only. |

## main.lua Runtime Flow

`main.lua` is the runtime orchestrator. It imports system modules, initializes meta progress and UI, enters menu/deploy screens, and launches runs through `StartNormalRun`, `StartTutorialRun`, `StartJudgeDemo`, and `StartNewGame`.

High-level flow:

1. `Start()` initializes meta progress, UI/theme/layout, event handlers, menu state, minimap/map overlay callbacks, and deploy terminal state.
2. Menu/deploy functions choose tutorial, normal run, settings, or meta screens.
3. `ConfirmDeploy()` validates loadout through `MetaProgress.ValidateLoadout()`, then calls `StartNormalRun()`.
4. `StartNormalRun()` resets tutorial state and calls `StartNewGame()` with normal/meta enabled.
5. `StartTutorialRun()` gets `Tutorial.GetMapConfig()`, disables loadout/meta rewards, calls `StartNewGame(config)`, starts tutorial, and triggers spawn popup.
6. `StartNewGame(override)` merges config, consumes loadout if enabled, constructs `ExtractionRun.New(config)`, receives `minefield`, initializes visited/explored state, resets run systems, applies equipment/talents, enters `PHASE.PLAYING`, computes minimap layout, shows opening message, hides menu/end panels, and calls `UpdateHUD()`.
7. Player input calls `MovePlayer`, `SearchCurrentRoom`, `DoTrade`, `DoExtract`, `MapOverlay` actions, or combat functions.
8. `RefreshMapData()` supplies `MapOverlay.visibleMap = minefield:GetVisibleMap()` and player coordinates.
9. Render code builds HUD context from RunInventory/Protocol/Combat/EventSystem/Minefield and draws HUD, minimap, room, event panel, result panels, map overlay, and tutorial popup.

Important architecture finding: `main.lua` should not be ported line-by-line. The Godot migration should port the system contracts and replace the UrhoX/UI/input/render glue with Godot nodes, signals, resources, and ViewModels.

## StartNewGame / Tutorial / Standard Entry Chains

### Normal / Standard Run

`ConfirmDeploy()` -> `StartNormalRun()` -> `StartNewGame({ mode="normal", useLoadout=true, applyMetaProgress=true, allowWarehouseRewards=true, allowFailureRewards=true })`

`StartNewGame()` default normal config:

| Field | Value |
|---|---:|
| `width` | 10 |
| `height` | 10 |
| `mineCount` | 20 |
| `spawnSafeRadius` | 0 |
| `pathWidth` | 0 |
| `randomExitCount` | 2 |
| `monsterRoomRatio` | 0.10 |
| `chestRoomRatio` | 0.10 |
| `eventRoomRatio` | 0.10 |
| `minMonsterRooms` / `maxMonsterRooms` | 10 / 10 |
| `minChestRooms` / `maxChestRooms` | 10 / 10 |
| `minEventRooms` / `maxEventRooms` | 10 / 10 |
| `mineHitsAreFatal` | false |
| `revealOnMove` | true |
| `moveRequiresRevealed` | false |

The self-test explicitly asserts the tuned 10x10 standard counts: 20 mines, 10 monster rooms, 10 chest rooms, 10 event rooms, and 2 exits.

### Tutorial Run

`OpenTutorial()` or `StartTutorial()` -> `StartTutorialRun()` -> `Tutorial.GetMapConfig()` -> `StartNewGame(config)` -> `Tutorial.Start()` -> `Tutorial.OnEnterRoom(spawn)`

Tutorial overrides:

| Field | Value |
|---|---:|
| `mode` | tutorial |
| `width` | 5 |
| `height` | 5 |
| `mineCount` | 4 |
| `randomExitCount` | 0 |
| `maxMonsterRooms` / `minMonsterRooms` | 5 / 5 |
| `maxChestRooms` / `minChestRooms` | 4 / 4 |
| `maxEventRooms` / `minEventRooms` | 4 / 4 |
| `mineHitsAreFatal` | false |
| `revealOnMove` | true |
| `moveRequiresRevealed` | false |
| `seed` | 777 |
| `useLoadout` | false |
| `applyMetaProgress` | false |
| `allowWarehouseRewards` | false |
| `allowFailureRewards` | false |
| `skipLoadout` | true |

## 5x5 Tutorial Map Complete Specification

Coordinate convention in Lua is 1-based: `x=1..5`, `y=1..5`. Spawn is at upper-left, exit at lower-right.

### Map Cells

| y/x | 1 | 2 | 3 | 4 | 5 |
|---:|---|---|---|---|---|
| 1 | Spawn/Normal | Normal | Mine | Event | Monster |
| 2 | Normal | Mine | Event | Monster | Chest |
| 3 | Mine | Event | Monster | Chest | Normal |
| 4 | Event | Monster | Chest | Mine | Normal |
| 5 | Monster | Chest | Map hint / Normal | Route hint / Normal | Exit |

Raw room lists from `Tutorial.GetMapConfig()`:

- Spawn: `(1,1)`
- Mines: `(1,3)`, `(2,2)`, `(3,1)`, `(4,4)`
- Events: `(1,4)`, `(2,3)`, `(3,2)`, `(4,1)`
- Monsters: `(1,5)`, `(2,4)`, `(3,3)`, `(4,2)`, `(5,1)`
- Chests: `(2,5)`, `(3,4)`, `(4,3)`, `(5,2)`
- Exit: `(5,5)` with id `tutorial_exit`
- Other normal/tutorial hint cells: `(1,2)`, `(2,1)`, `(3,5)`, `(5,3)`, `(4,5)`, `(5,4)`

### Tutorial Popup Triggers

`Tutorial.roomPopups` maps coordinate to popup id. Repeated entry into the same room does not retrigger unless the popup definition allows it. `once=true` popups are recorded in `Tutorial.shown`. `blocking=true` popups lock input until confirmation. `showAfterRoomEffect=true` popups are delayed until `Tutorial.FlushPendingPopup()` after room effect resolution.

| Coordinates | Popup id | Purpose |
|---|---|---|
| `(1,1)` | `spawn_intro` | Spawn intro. |
| `(1,2)`, `(2,1)` | `number_rule` | Explain adjacent mine number rule. |
| `(1,3)`, `(2,2)`, `(3,1)` | `mine_rule` | Explain mine hazard. |
| `(1,4)`, `(2,3)`, `(3,2)`, `(4,1)` | `event_rule` | Explain event interaction. |
| `(1,5)`, `(2,4)`, `(3,3)`, `(4,2)`, `(5,1)` | `monster_rule` | Explain monster room. |
| `(2,5)`, `(3,4)`, `(4,3)`, `(5,2)` | `chest_rule` | Explain chest/search rewards. |
| `(3,5)`, `(5,3)` | `map_rule` | Explain minimap/map operations. |
| `(4,4)` | `mine_review` | Reinforce mine hazard. |
| `(4,5)`, `(5,4)` | `route_rule` | Explain route planning. |
| `(5,5)` | `exit_goal` | Explain extraction goal. |

### Expected Player Path

The code does not enforce a single tutorial path. The popup layout implies a safe teaching path from spawn through safe number cells, then progressively through hazard/event/monster/chest/map/route/exit cells. Because mines are non-fatal and `moveRequiresRevealed=false`, the player may step on any adjacent room. Recommended Godot tutorial path for parity should be staged as:

1. Spawn `(1,1)`.
2. Safe number tutorial via `(1,2)` or `(2,1)`.
3. Mine rule via `(1,3)`, `(2,2)`, or `(3,1)`.
4. Event rule via one of the event diagonal cells.
5. Monster rule via one of the monster diagonal cells.
6. Chest rule via one of the chest diagonal cells.
7. Map rule via `(3,5)` or `(5,3)`.
8. Mine review at `(4,4)`.
9. Route rule at `(4,5)` or `(5,4)`.
10. Exit at `(5,5)`.

Unconfirmed: popup text content is stored through `GameText`/popup definitions and was not exhaustively decoded in this audit due console encoding, but ids, triggering, blocking semantics, and coordinate mapping are confirmed.

## 10x10 Standard Run Complete Specification

### Map Generation Parameters

The standard run uses `StartNewGame()` defaults and `Minefield:Generate()` normal-mode random generation. The spawn is randomized in normal mode when not locked. The minefield is regenerated up to `maxAttempts` using deterministic RNG based on seed and attempt.

Standard parameters:

- Size: 10x10.
- Mines: exactly 20.
- Spawn: random safe cell; not mine, not special, not exit.
- Spawn safe radius: 0.
- Movement reveal: true.
- Movement into hidden cells: allowed.
- Mine hits fatal: false.
- Random exits: 2.
- Monster rooms: exactly 10 in the main `StartNewGame` tuned config.
- Chest rooms: exactly 10.
- Event rooms: exactly 10.

### Placement Rules

`Minefield:_PlaceMines()` selects from non-reserved candidates and sets `mine=true`, `roomType="mine"`.

`Minefield:_AssignSpecialRooms()` then selects from safe candidates where all of these are true:

- not a mine,
- not spawn,
- not exit,
- `roomType == "normal"`,
- not reserved.

Assignment order is monsters, chests, events, then random exits. This means the exact 10/10/10 counts are assigned before exits. Random exits are taken from remaining safe candidates and become `roomType="exit"`, `exitId="random_i"`, `randomExit=true`.

### Hidden Exit Rule

Random exits are intentionally hidden until revealed. `Minefield:_PublicCell()` only exposes `exitId` for random exits after the cell is revealed. Fixed/non-random exits are visible earlier.

### Adjacency Rule

`Minefield:_ComputeAdjacency()` counts only real mines in 8-neighborhood. Monster/chest/event/exit rooms are not counted as mines.

## Single Run State Fields

### ExtractionRun

- `minefield`
- `player = { x, y }`
- `phase = "running" | "failed" | "extracted"`
- `exitId`
- `turn`
- `mineHitsAreFatal`
- `moveRequiresRevealed`
- `revealOnMove`

### Minefield / Cell State

Global minefield fields include:

- `width`, `height`, `seed`, `mode`, `manualMap`
- `spawn`
- `exits`, `exitLookup`
- `mineCount`, `targetMineCount`, `safeCellCount`, `revealedSafeCount`, `flaggedCount`
- `monsterCount`, `chestCount`, `eventCount`, `generatedRandomExitCount`

Cell fields inferred through `_PublicCell()` and generation:

- `x`, `y`
- `mine`
- `flagged`
- `revealed`
- `adjacent`
- `spawn`
- `exitId`
- `randomExit`
- `reserved`
- `path`
- `roomType`
- `explored`
- `cleared`

Public view fields intentionally hide `roomType`, `adjacent`, mine identity, and random exit id until visible/revealed.

### RunInventory

- `gold` alias for pending gold
- `pendingGold`
- `safeGold`
- `parts`
- `searchedRooms`
- `carriedItems`
- `consumables`
- `failureSalvage`
- `searchBonus`
- `stats`: moves, searchedRooms, chestRooms, mineHits, mineImmunityUsed, monstersDefeated, combatDamage, trades, eventsCompleted, diceEvents, altarEvents, trapEvents.

### Combat

- `hp`, `maxHp`, `power`
- `enemies` keyed by cell
- `monsterPowerBonus`
- `mineImmunity`
- `mineDmgReduce`
- Enemy fields include name, power, alive, monsterHP/maxHP, damage, attack phase/timers, player attack cooldown/invincibility.

### Protocol

- `level`: starts 5, decreases as pressure rises.
- `pressure`: 0..100.
- `maxPressure`.
- `lastChanged`, `lastPressureDelta`.
- thresholds: 0 => level 5, 20 => 4, 40 => 3, 60 => 2, 80 => 1.

### Event System

- `completedEvents`
- `assignedEvents`
- `interactedEvents`
- `optionState`
- event types: trader, dice, altar, trap.

## Room Entry Flow

`MovePlayer(dx, dy)` calls `run:Move(dx, dy)`.

`ExtractionRun:Move` rules:

1. Reject if not running.
2. Reject if not exactly one cardinal step.
3. Reject out of bounds.
4. Reject flagged target.
5. If `moveRequiresRevealed` is true, reject hidden target. Standard/tutorial set it false.
6. If target is a mine:
   - If first entry: reveal mine, move player into mine, increment turn, status `hit_mine`, `mineTriggered=true`.
   - If already revealed/triggered: move player into mine, status `entered_triggered_mine`, `mineTriggered=false`.
   - If `mineHitsAreFatal=true`, fail run and reveal all mines. Standard/tutorial use non-fatal.
7. If target is not a mine and `revealOnMove=true`, reveal it.
8. Move player, increment turn.
9. Return status `at_exit` if current cell can extract, else `moved`.

`main.lua:MovePlayer` adds gameplay side effects:

- records move in RunInventory,
- updates scene player placement,
- marks visited and calls `minefield:Explore`,
- on first explore adds protocol pressure by `Balance.pressure.explore` (=2),
- applies protocol penalty hook if present; tests show current protocol does not report extra penalty,
- applies map-highlight talent if unlocked,
- on fresh mine hit calls `Combat.TakeMineHit`, records mine hit, adds mine pressure by 10, visual feedback, and failure if HP reaches 0,
- generates enemy for monster rooms through `Combat.TrySpawnEnemy`,
- shows exit/search/event/adjacent/safe messages,
- triggers tutorial room popup and delayed popup flush,
- refreshes map data and HUD.

## Search / Chest / Event / Monster / Mine / Extract / Failure Rules

### Search and Chest

`RunInventory.GetSearchState` allows search only if current cell is revealed, not mine, not spawn, not exit, not monster, not event, and not already searched. Chest cells are searchable and marked as `isChest`.

Normal search reward:

- Gold range: `Balance.search.baseMin=0` to `baseMax=2` plus floor(adjacent / 2), capped at 4.
- Item drop table: none/low/common/rare, with bonus to rare chance when adjacent mines are high.

Chest reward:

- Gold range: `Balance.chest.baseMin=3` to `baseMax=7` plus adjacent, capped at 11.
- Item drop table: common/rare/precious/abnormal.
- Guaranteed 1-2 item-backed parts.

Search is one-time per cell. Repeating returns `status="searched"` and should not grant rewards again.

### Event Rooms

Event rooms cannot be searched. Entering event room shows `EventSystem.GetEnterMessage`. Interaction uses options generated by event type:

- Trader: sells one concrete carried item at floor(base value * 0.75), minimum 1, adding safe/locked gold and removing the item.
- Dice: requires pending gold >= 20; roll 1-4 loses 20, roll 5 gains +20, roll 6 gains +60.
- Altar: step sequence costs HP `{10,15,25,35,50}` and rewards pending gold/item quality. It may remain open until sequence completion.
- Trap: if power >= 8, grants +25 pending gold and two reward item descriptors; otherwise HP -1 and pressure +5.

Completed events are marked once and clear the room in Minefield. Stats record event type.

### Monster Rooms

Only `roomType="monster"` spawns enemies. Spawn and exit do not spawn enemies. Enemy power is deterministic from seed and coordinate plus adjacent mine bonus. Combat supports:

- `Combat.FightEnemy`: deterministic immediate resolution. If player power >= enemy power, no damage; if lower, damage = enemyPower - playerPower. Enemy is cleared either way. Reward gold is small, based on `Balance.monster.goldMin=0`, `goldMax=3`.
- `Combat.PlayerAttackEnemy` / `Combat.UpdateEnemy`: room-local action combat with monster HP, attack warning/active/cooldown phases, player range, cooldown, invincibility, and damage.

On monster clear, `Combat.GrantMonsterKillPower` can grant +1 power up to +5 per run; `RunInventory.RecordCombat` records stats and reward. Godot can initially implement deterministic `FightEnemy`, leaving action combat as P1/P2.

### Mine Rooms

Mine room entry is allowed in standard/tutorial. First entry reveals and triggers the mine. It calls `Combat.TakeMineHit()`:

- Base mine damage: 30.
- Equipment/talent can reduce damage, but minimum damage is 5.
- First mine immunity may absorb one hit.
- Fresh mine hit adds pressure +10.
- Re-entering an already triggered mine does not retrigger damage.

### Extraction

Extraction is allowed only when `run:CanExtract()` is true, meaning current cell has `exitId`. `DoExtract()` opens confirm panel with pending/safe gold, carried item estimate, total reward, exploration/search/event stats, and protocol level. `ConfirmExtract()` calls `run:Extract()`, sets phase extracted, computes `RunInventory.GetExtractionReward()`, and records meta reward only if warehouse rewards are allowed.

Tutorial disables warehouse/meta reward writing, so completion shows a training message and grants no outside reward.

### Failure

Failure can be caused by HP <= 0 from mine/combat/event/protocol penalty hook. `ShowFailurePanel()` computes totals, stats, salvage options, and protocol state. If failure rewards are disabled, tutorial does not write recovery. Failure salvage keeps safe gold and, according to tests, can auto-keep one highest-value carried item in failure recovery. Pending gold is lost on failure.

## HUD / MiniMap / MapOverlay Display and Refresh

### HUD

HUD is drawn through NanoVG and receives a context assembled in `main.lua` render path. Key display areas:

- Left sidebar with minimap and minesweeper rule legend.
- Protocol panel with level, title/description, pressure bar, and flash on level change.
- Nearby danger indicator.
- Bottom bar with interaction hints, inventory/reward summaries, consumables/equipment effects.
- Tutorial dialog/popup overlay.
- Center toast message.

`HUD.GetInteractHint(context)` picks messages from current room facts: exit, enemy, event/trader, searched chest, searchable chest/normal, or none.

### MiniMap

MiniMap draws from `visibleMap = minefield:GetVisibleMap()`. It does not read true hidden room type. It shows:

- hidden, flagged, mine, empty, number states,
- player marker,
- exit marker only when `exitId` is visible,
- chest/monster/event/mine room icons only after revealed,
- cleared marker for cleared monster/event,
- number badges on special rooms,
- highlight cells with temporary pulse.

It has fallback primitive drawing/text if icon images fail. It automatically enlarges maps whose max dimension is <= 6, which is relevant for the 5x5 tutorial.

### MapOverlay

MapOverlay is the expanded map. It uses `visibleMap`, player coordinates, visited/explored cells, and map layout. It displays a dark overlay, title, grid states, exits, special icons, flags, mine marks, number badges, player, and bottom hints.

Clicks are intended to:

- flag hidden cells,
- teleport/return to explored safe cells,
- close with right click/ESC.

Godot should preserve the core behavior but replace NanoVG drawing with Control/GridContainer or TileMap UI.

## Complete / Semi-Implemented / Placeholder / Glue List

### Complete or Playable

- 5x5 tutorial map config and room-triggered popup flow.
- 10x10 tuned standard mode with 20 mines, 10 monsters, 10 chests, 10 events, 2 hidden exits.
- Minefield state, reveal, flag, adjacency, visible map, explored/cleared states.
- ExtractionRun movement, reveal-on-move, non-fatal mine entry, extraction state.
- Search and chest reward loop, one-time search guard.
- EventSystem with trader/dice/altar/trap.
- Protocol pressure levels.
- Extraction success settlement.
- Failure salvage/recovery behavior.
- HUD/minimap/map overlay prototype UI.
- MetaProgress economy, warehouse, equipment, consumables, talents.

### Semi-Implemented / Needs Godot Design Decision

- Combat has both deterministic room resolution and action-combat behavior. Pick deterministic combat for first parity, then action combat later.
- Tutorial popup text and presentation should be reviewed in `GameText`; trigger rules are clear.
- Protocol level 1 penalty hook exists in `main.lua`, but tests assert `Protocol.AddPressure` currently does not set `penalty=true`.
- `Combat.TryPowerUp` currently returns 0; historical power-up hook remains but is disabled.
- `Minefield.expandZeroCells` exists but defaults false; 0-adjacent BFS expansion is not active in standard config.

### Placeholders / Prototype Glue

- UrhoX UI node lookups and NanoVG drawing.
- Video/CG startup/skip logic.
- Deploy terminal visual layout and hit rect glue.
- Direct string/UI label mutations in `main.lua`.
- Asset image paths under UrhoX/NanoVG.
- GM/debug menu actions.

### Should Not Be Directly Ported

- UrhoX-specific event handlers and `uiRoot_` lookups.
- NanoVG primitive drawing code as-is.
- `.meta` resource sidecars.
- `.cli` tooling.
- Generated image/video/marketing assets until license is confirmed.
- UE code/resources.

## Godot Current S2 Gap

Godot S2 currently implements a minimal fixed 7x7 sandbox. It has the correct architecture boundary names but not Lua parity yet.

| Feature | Lua prototype | Godot S2 | Gap |
|---|---|---|---|
| Map mode | 5x5 tutorial and 10x10 standard | fixed 7x7 demo | Need map config/mode support. |
| Coordinates | 1-based Lua | 0-based `Vector2i` in Godot | Need consistent adapter/convention. |
| Minefield generation | random/manual, hidden exits, counts | fixed hand-authored cells | Need generator/resource-driven maps. |
| Truth/Intel split | PublicCell hides unknown fields | TruthMap/IntelMap exists | Need full `state`, `revealed`, `flagged`, `explored`, `cleared`, `exit visible` rules. |
| Run state | ExtractionRun + systems | RunContext minimal | Need phase, turn, seed, mode, inventory, combat, protocol, stats. |
| Movement | full ExtractionRun rules | cardinal move + reveal | Need flagged block, hidden allow config, mine re-entry status, exit ids. |
| Search/chest | full reward and one-time guard | chest placeholder +10 gold | Need RunInventory-like system. |
| Events | trader/dice/altar/trap | placeholder string | Need event data/options/results. |
| Combat | deterministic + action combat | monster placeholder | Need deterministic first parity. |
| Pressure | 0-100 thresholds | simple pressure number | Need Protocol thresholds and messages. |
| HUD | rich summary/context | minimal text | Need structured ViewModel fields. |
| MiniMap | visible map states/icons/fallbacks/highlights | fallback labels | Need full visible map marker rules. |
| Result | extraction/failure settlement | basic result snapshot | Need reward/failure salvage details. |

## Unconfirmed Items

- Full tutorial popup body text and exact blocking flags require reading `GameText` definitions with encoding verification.
- Exact map overlay click behavior should be checked around `MapOverlay.HandleClick` and main callbacks before implementing teleport parity.
- Final intended combat mode for Godot parity: deterministic combat is recommended first, but action combat may be part of desired demo feel.
- Whether MetaProgress should be included in the first Godot parity pass or kept P2.

## Self Check

- Source files modified: no.
- Assets copied: no.
- Git commit/push/init: no.
- Game/Godot/runtime tools executed: no.
- Report generated in allowed directory: yes.
