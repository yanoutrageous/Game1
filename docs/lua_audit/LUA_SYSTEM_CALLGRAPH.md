# LUA_SYSTEM_CALLGRAPH

## Overview

This callgraph summarizes the main gameplay paths in `D:\2026.6\GAME`. It omits UrhoX rendering boilerplate except where UI refresh is part of gameplay flow.

## main.lua -> Systems

| main.lua responsibility | Called system/file | Main functions/data | Purpose |
|---|---|---|---|
| Run creation | `systems.ExtractionRun` | `ExtractionRun.New` | Owns run phase, player position, turn, extraction. |
| Map rules | `systems.Minefield` | `Minefield.New`, `Generate`, `Reveal`, `GetVisibleMap`, `Explore`, `ClearRoom` | Owns grid, mines, room types, exits, public visible state. |
| Loot and run economy | `systems.RunInventory` | `Reset`, `SearchCurrentRoom`, `GetTotals`, `GetRunStats`, `GetExtractionReward`, `GetFailureSalvageOptions` | Owns pending/safe gold, carried items, searched cells, run stats. |
| Combat | `systems.Combat` | `Reset`, `TakeMineHit`, `TrySpawnEnemy`, `FightEnemy`, `PlayerAttackEnemy`, `UpdateEnemy`, `GetStatus` | Owns HP/power/enemies/mine damage/combat. |
| Events | `systems.EventSystem` | `Reset`, `GetEventType`, `GetEnterMessage`, `GetOptions`, `ExecuteOptionById`, `IsCompleted` | Owns event type assignment, options, results, completion. |
| Pressure | `systems.Protocol` | `Reset`, `AddPressure`, `GetStatus` | Owns pressure and protocol level. |
| Meta | `systems.MetaProgress` | `Init`, `ValidateLoadout`, `ConsumeLoadoutForRun`, `GetEquipBonus`, `GetTalentEffects`, `RecordExtractionReward` | Owns outside-run economy/equipment/talents/warehouse. |
| Tutorial | `systems.Tutorial` | `GetMapConfig`, `Start`, `OnEnterRoom`, `FlushPendingPopup`, `ConfirmPopup` | Owns fixed tutorial map triggers and popup/input-lock state. |
| Text/balance | `systems.GameText`, `systems.Balance` | constants/data | Owns display text and numeric constants. |
| HUD | `ui.HUD` | `ComputeLayout`, `DrawLeftSidebar`, `DrawProtocolPanel`, `GetInteractHint`, `DrawTutorialPopup` | Draws run UI from public context. |
| MiniMap | `ui.MiniMap` | `ComputeLayout`, `SetHighlight`, `Draw` | Draws compact map from `visibleMap`. |
| Map overlay | `ui.MapOverlay` | `ComputeLayout`, `Draw`, `HandleClick`, callbacks | Draws expanded map, flag/teleport interactions. |
| Room scene | `scenes.DungeonRoom` | `ResetPlayer`, `PlacePlayerFromEntry`, visual triggers | UrhoX scene/player feedback. |

## Startup / Menu / Deploy Chain

1. `Start()` in `scripts/main.lua`
   - Calls `MetaProgress.Init()`.
   - Registers `MapOverlay.onClose`, `MapOverlay.onFlag`, `MapOverlay.onTeleport` callbacks.
   - Builds UI and menu/deploy state.

2. `OpenDeployTerminal()` / `OpenTutorial()` / menu handlers
   - Calls page refresh functions or `StartTutorialRun()`.

3. `ConfirmDeploy()` in `main.lua`
   - Calls `MetaProgress.ValidateLoadout()`.
   - Adjusts consumable loadout if stock is insufficient.
   - Calls `StartNormalRun()`.

## StartNewGame Chain

### Standard Run

`ConfirmDeploy()` -> `StartNormalRun()` -> `StartNewGame(override)`

Call sequence:

1. `StartNormalRun()` (`main.lua`)
   - `Tutorial.Reset()`.
   - Calls `StartNewGame()` with mode normal and meta rewards enabled.

2. `StartNewGame(override)` (`main.lua`)
   - Merges defaults with override.
   - `MetaProgress.ConsumeLoadoutForRun()` if enabled.
   - `ExtractionRun.New(config)`.
   - `ExtractionRun:Init(config)`.
   - `Minefield.New(config)`.
   - `Minefield:Generate()`.
   - `minefield:GetSpawn()`.
   - `minefield:Explore(spawn.x, spawn.y)`.
   - `RunInventory.Reset()`.
   - `RunInventory.SetConsumables(loadoutReceipt.consumables)`.
   - `Combat.Reset()`.
   - `Protocol.Reset()`.
   - `DungeonRoom.ResetPlayer()`.
   - `EventSystem.Reset(minefield.seed)`.
   - `MetaProgress.GetEquipBonus()` and `MetaProgress.GetTalentEffects()` if enabled.
   - `MetaProgress.RecordRun()` if enabled.
   - `MiniMap.ComputeLayout(width,height)`.
   - `ShowMessage(...)`.
   - `UpdateHUD()`.

### Tutorial Run

`OpenTutorial()` / `StartTutorial()` -> `StartTutorialRun()` -> `Tutorial.GetMapConfig()` -> `StartNewGame(config)` -> `Tutorial.Start()` -> `Tutorial.OnEnterRoom(spawn)`

Key calls:

- `Tutorial.Reset()` clears previous popup/input-lock state.
- `Tutorial.GetMapConfig()` returns fixed 5x5 manual map.
- `StartNewGame(config)` starts run with meta/loadout/reward writing disabled.
- `Tutorial.Start()` activates tutorial state.
- `Tutorial.OnEnterRoom(spawn.x, spawn.y, nil, "spawn")` triggers spawn popup.

## Minefield Generation Chain

`ExtractionRun.New(config)` -> `ExtractionRun:Init(config)` -> `Minefield.New(config)` -> `Minefield:Init(config)` -> `Minefield:Generate()`

Manual/tutorial path:

1. `Minefield:Generate()` detects `manualMap` or judge mode.
2. `_GenerateManual()`.
3. `_BuildEmptyGrid()`.
4. Apply spawn.
5. Apply manual mines.
6. Register manual exits.
7. Apply monsters/chests/events/manual rooms.
8. Set `targetMineCount`, `safeCellCount`.
9. `_ComputeAdjacency()`.

Standard random path:

1. `Minefield:Generate()` loops attempts.
2. Normal mode may `_ChooseRandomSpawn()`.
3. `_BuildEmptyGrid()`.
4. `_ReserveCriticalCells()`.
5. `_PlaceMines()`.
6. `_AssignSpecialRooms()`.
7. `_ComputeAdjacency()`.
8. Legacy mode may verify `HasPathToAllExits()`; normal mode accepts generation once built.

## Move Chain

Input handlers or scene movement -> `MovePlayer(dx,dy)` in `main.lua`.

1. `MovePlayer(dx,dy)` checks `phase == PHASE.PLAYING` and `run` exists.
2. Calls `run:Move(dx,dy)` (`ExtractionRun.lua`).
3. `ExtractionRun:Move` validates:
   - running phase,
   - cardinal direction,
   - target inside map,
   - target not flagged,
   - hidden movement allowed by config.
4. If target mine:
   - reveal if first trigger,
   - move player for non-fatal mode,
   - increment turn,
   - return status `hit_mine` or `entered_triggered_mine`.
5. If target safe:
   - reveal target if `revealOnMove`,
   - move player,
   - increment turn,
   - return status `moved` or `at_exit`.
6. Back in `MovePlayer` on success:
   - `RunInventory.RecordMove()`.
   - `DungeonRoom.PlacePlayerFromEntry(...)`.
   - `Tutorial.NotifyAction("move")` compatibility no-op.
   - mark `visitedCells`.
   - `minefield:Explore(p.x,p.y)`.
   - if first explore: `Protocol.AddPressure(Balance.pressure.explore)`.
   - if protocol penalty hook reports death: `Combat.ApplyDamage(1)`, possible `ShowFailurePanel()`.
   - talent map highlight may call `MiniMap.SetHighlight(neighbors)`.
7. If mine hit:
   - `Combat.TakeMineHit()`.
   - if fresh trigger: `RunInventory.RecordMineHit()` and `Protocol.AddPressure(Balance.pressure.mine)`.
   - visual mine feedback.
   - if dead: `ShowFailurePanel(...)`.
8. If not mine:
   - maybe highlight expanded reveal cells.
   - `Combat.TrySpawnEnemy(minefield,p.x,p.y)`.
   - `Combat.GetEnemy(p.x,p.y)`.
   - if exit: exit pulse and extract message.
   - else event/search/adjacent/safe messages.
9. Tutorial post-entry:
   - `Tutorial.OnEnterRoom(...)`.
   - `Tutorial.FlushPendingPopup()`.
10. Always calls `RefreshMapData()` and `UpdateHUD()` at end.

## Search Chain

Input `F` or UI search -> `SearchCurrentRoom()`.

1. `SearchCurrentRoom()` checks playing phase and run.
2. Calls `RunInventory.SearchCurrentRoom(minefield, run)`.
3. `RunInventory.GetSearchState(minefield, run)` checks:
   - run and minefield ready,
   - current cell exists, revealed, not mine,
   - not spawn,
   - not exit,
   - not monster,
   - not event,
   - not already searched.
4. `RunInventory.GetReward(minefield,x,y)` calculates reward:
   - normal search: tuned 0..4 pending gold cap,
   - chest: tuned 3..11 pending gold cap and guaranteed item-backed rewards.
5. `SearchCurrentRoom` marks searched, adds pending gold, parts and carried items, updates stats.
6. Back in `main.lua`:
   - `DungeonRoom.TriggerChestOpen(reward)`.
   - `Tutorial.NotifyAction("search")` compatibility no-op.
   - `Combat.TryPowerUp(...)` returns 0 in current prototype.
   - chest search clears room through `minefield:ClearRoom`.
   - `OpenLootResultPanel(reward,powerUp)`.
   - `UpdateHUD()`.

## Event / Interact Chain

Entering event room only shows a message. Interacting opens/executed event options.

1. `MovePlayer` sees `cell.roomType == "event"` and calls `EventSystem.GetEnterMessage(x,y)`.
2. Input `T`/mouse path calls `DoTrade()` in `main.lua`.
3. `DoTrade()` opens event panel and calls `RefreshEventPanel()`.
4. `RefreshEventPanel()` calls `EventSystem.GetOptions(x,y,GetEventContext())`.
5. `GetEventContext()` gathers:
   - RunInventory totals and tradable items,
   - Combat hp/maxHp/power,
   - active talent trade price.
6. EventSystem flow:
   - `GetEventType(x,y)` assigns deterministic type from seed/coord and weights.
   - `GetEventState(x,y)` returns completion and option state.
   - `GetOptions(...)` builds trader/dice/altar/trap options.
7. `ConfirmEventOption()` calls `EventSystem.ExecuteOptionById(...)`.
8. `ApplyEventResult(result,x,y)` applies deltas:
   - pending/safe gold,
   - parts/items,
   - HP/power,
   - pressure,
   - completion/clear room,
   - event stats,
   - failure if HP <= 0.
9. Updates HUD and closes/refreshes panel.

## Combat Chain

### Entering Monster Room

`MovePlayer` -> `Combat.TrySpawnEnemy(minefield,x,y)` -> `Combat.GetEnemy(x,y)` -> show enemy message.

`TrySpawnEnemy` only spawns if the visible cell is `roomType == "monster"`, not spawn, not exit, and no enemy record already exists for the cell.

### Deterministic Fight

1. `ForceFightCurrentEnemy()` or battle UI calls `StartBattle(enemy,x,y)`.
2. `ResolveBattle()` calls `Combat.FightEnemy(x,y)`.
3. `FinishBattle()`:
   - `Combat.GrantMonsterKillPower(result)`.
   - `RunInventory.RecordCombat(result)`.
   - `Protocol.AddPressure(result.pressureDelta)` if present.
   - `minefield:ClearRoom(x,y)` through completion helper.
   - possible failure if HP <= 0.
   - `UpdateHUD()`.

### Action Combat

- `AttackCurrentEnemy()` calls `Combat.PlayerAttackEnemy(x,y, DungeonRoom.GetPlayerPosition())`.
- `UpdateCurrentMonsterCombat(dt)` calls `Combat.UpdateEnemy(x,y,dt,playerPos)`.
- Active warning area can damage the player once per active phase.

First Godot parity can implement deterministic fight first.

## Extract / Settlement Chain

### Request Extract

Input `E` on exit -> `DoExtract()`.

1. `DoExtract()` checks `run:CanExtract()`.
2. Sets `phase = PHASE.CONFIRM_EXTRACT`.
3. `DungeonRoom.TriggerExitPulse()`.
4. Reads:
   - `RunInventory.GetTotals()`.
   - `RunInventory.GetRunStats(run)`.
   - `Protocol.GetStatus()`.
   - `RunInventory.GetExtractionReward()`.
5. Updates extract confirmation panel labels.

### Confirm Extract

1. `ConfirmExtract()` calls `run:Extract()`.
2. If ok:
   - `phase = PHASE.EXTRACTED`.
   - `RunInventory.GetExtractionReward()`.
   - `RunInventory.GetRunStats(run)`.
   - if rewards allowed and not already recorded: `MetaProgress.RecordExtractionReward(reward, stats)`.
   - show win panel.
   - write result lines for gold, carried item conversion/storage, stats, risk.

Tutorial mode disables outside reward writing.

## Failure / Salvage Chain

Possible failure sources:

- Mine damage through `Combat.TakeMineHit()`.
- Combat damage through `Combat.FightEnemy()` or action combat update.
- Event HP delta through `ApplyEventResult()`.
- Protocol penalty hook in main.lua, though current `Protocol.AddPressure()` returns `penalty=false`.

Failure flow:

1. Call `ShowFailurePanel(reason)`.
2. Reads `RunInventory.GetTotals()`.
3. Reads `RunInventory.GetRunStats(run)`.
4. Reads `RunInventory.GetFailureSalvageOptions()`.
5. Reads `Protocol.GetStatus()`.
6. Shows failure panel and optional salvage controls.
7. `ApplyFailureSalvage(choice)` calls `RunInventory.ApplyFailureSalvage(choice)`, may add retained gold and recovered item through MetaProgress if allowed.

## HUD / MiniMap / MapOverlay Refresh Chain

### RefreshMapData

`RefreshMapData()`:

- `MapOverlay.visibleMap = minefield:GetVisibleMap()`.
- `MapOverlay.playerX = run.player.x`.
- `MapOverlay.playerY = run.player.y`.
- `MapOverlay.visitedCells = visitedCells`.

Called after movement, teleport, opening map, and render paths.

### Render HUD Context

Render path reads:

- `Combat.GetStatus()`.
- `RunInventory.GetTotals()`.
- `Protocol.GetStatus()`.
- `RunInventory.GetHUDSummary(context)`.
- `Combat.GetEnemyAny(p.x,p.y)`.
- `EventSystem.IsCompleted(x,y)`.
- `EventSystem.GetEventDef(EventSystem.GetEventType(x,y))` for visible event context.
- `GetSearchState()`.

Then draws:

- `HUD.DrawLeftSidebar(...)` including MiniMap.
- `HUD.DrawProtocolPanel(...)`.
- `HUD.DrawNearbyDanger(...)`.
- `HUD.DrawBottomBar(...)`.
- `HUD.DrawTutorialPopup(...)` if tutorial popup is active.
- `MapOverlay.Draw(...)` if overlay visible.

### MapOverlay Callbacks

Set in `Start()`:

- `MapOverlay.onClose` -> `Tutorial.NotifyAction("close_map")`.
- `MapOverlay.onFlag(x,y)` -> `run:ToggleFlag(x,y)`, refresh map, tutorial notify.
- `MapOverlay.onTeleport(x,y)` -> `TeleportTo(x,y)`.

`TeleportTo(x,y)` requires explored safe cell semantics, hides overlay, refreshes map/HUD, and triggers tutorial enter popup if active.

## Test-Backed Invariants

From `scripts/tests/minefield_selftest.lua`:

- Non-fatal first mine entry moves player and reports `hit_mine`/`mineTriggered=true`.
- Re-entering triggered mine reports `entered_triggered_mine` and does not retrigger.
- Protocol starts level 5 at pressure 0; thresholds 20/40/60/80 map to levels 4/3/2/1.
- `Protocol.AddPressure` currently does not apply extra penalty flag.
- Normal search reward is 0..4 and does not grant attack power.
- Chest reward is stronger and grants at least one carried item.
- Event rooms are not searchable.
- Normal mode random exits are hidden before reveal and visible after reveal.
- 10x10 tuned standard counts are 20 mines, 10 monsters, 10 chests, 10 events, 2 exits.
- Tutorial config is 5x5, seed 777, manual map, 4 mines, 4 events, 5 monsters, 4 chests, 1 exit.
- Combat stronger player wins with no damage; weaker player pays power gap damage; enemy clears either way.
- Action combat respects range, cooldown, monster active hit phase, and invincibility.
- Event trader/dice/altar/trap outcomes match Balance values.

## Self Check

- This file is a read-only-derived callgraph.
- It does not include long source excerpts.
- No source or project code was modified.
