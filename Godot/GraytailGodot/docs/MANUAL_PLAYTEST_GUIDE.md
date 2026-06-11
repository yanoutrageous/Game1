# Manual Playtest Guide

## Scope

This guide now treats the older G4-G7 routes as historical foundations and points manual smoke toward the G9 UI core flow baseline in current `main`. Do not run Godot unless the user explicitly authorizes editor/runtime execution.

Legacy static validation aliases: `Start Tutorial 5x5`, `Start Standard 10x10`.

Current baseline smoke should cover the three-page shell, formal InventoryPanel, formal GroundLootPanel, pickup/drop through CommandBus, blocked reason display, and ResultPanel settlement explanation. The current baseline is not a complete final UI, complete MetaProgress, complete Deploy persistence, or complete long-term system completion.

## Main Menu / Deploy Shell

- Use the main menu `出发探索` entry to open the read-only DeployShell.
- Use deploy tabs to inspect warehouse, requisition, loadout, recovery, and talents shell content.
- Use `确认出发` in DeployShell to start a standard run.
- Use `新手教程` from the main menu to start tutorial directly.

Expected G7 visuals:

- Menu and DeployShell hide the room and player layers.
- DeployShell does not write save data or persistent progression.
- Starting a run switches to the run overlay with no menu buttons covering the room.

## Tutorial Run

Use `新手教程` to verify the fixed tutorial route and tutorial popup.

### Tutorial recommended route

- Move inside the current room with W/A/S/D or arrow keys.
- Walk through a centered door or boundary to change rooms.
- Use E to search, interact, request extraction, or confirm extraction.
- Use Space/J to fight when the current room is Monster.
- Use F to flag the current cell.
- Use M/Tab to toggle MapOverlay.
- Use R to restart.

Expected G5 visuals:

- HUD uses left/protocol/bottom presentation panels.
- MiniMap shows manifest-backed icons or text fallback.
- Tutorial popup appears as a panel rather than only HUD text.
- Room visual updates as the public current room changes.
- Player marker updates position without changing rules.

Expected G6 behavior:

- MiniMap current room changes only after a room transition.
- Blocking tutorial popups pause formal movement until confirmed.
- Search, event, monster, mine, extract, and failure result text updates are reflected in HUD/ResultPanel snapshots.

Expected G7 behavior:

- HUD and MiniMap remain inside the left sidebar.
- Protocol stays in the right rail, while Debug/Grid Move is collapsed behind its own toggle.
- Bottom action bar exposes search/interact, flag, fight, map, and restart actions.
- Search or combat opens a compact result panel instead of relying only on HUD text.

## Standard Run

Use `出发探索` -> `确认出发` for the Standard smoke route.

### Standard smoke route

- Start a standard run.
- Move several rooms.
- Confirm room-local movement does not move the MiniMap current cell until a door/boundary transition succeeds.
- Flag a cell.
- Open MapOverlay, flag a hidden cell, and teleport to an explored safe cell.
- Search a Normal or Chest room.
- Fight a Monster if reached.
- Confirm extraction only from an Exit room.

Expected G5 visuals:

- MiniMap and MapOverlay share the same ViewModel.
- Room/player visuals update from snapshots.
- ResultPanel still shows extraction/failure/training summaries.

Expected G6 behavior:

- Event rooms resolve one of trader, dice, altar, or trap outcomes.
- Monster rooms show deterministic fight state and update after combat.
- Failure results include pending-gold loss and salvage details.

Expected G7 behavior:

- Event rooms open an EventOptionPanel with selectable options.
- Exit rooms open an ExtractConfirmPanel before final result.
- ResultPanel has enough space for extraction/failure summaries.
- The old event placeholder prompt should not appear.

## Known limits

- No Godot import/runtime smoke is part of the static G5 validation.
- No full MetaProgress, persistence-backed Deploy economy, action combat, video, music, or font migration.
- Some migrated icons remain internal placeholders until final art approval.
