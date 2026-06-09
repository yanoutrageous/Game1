# Manual Playtest Guide

## Scope

This guide covers the G4 playable graybox loop, G5 Asset/UI/Visual Parity surfaces, and G6 Lua Playable Parity P1 core behavior. Do not run Godot unless the user explicitly authorizes editor/runtime execution.

## Start Tutorial 5x5

Use `Start Tutorial 5x5` to verify the fixed tutorial route and tutorial popup.

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

## Start Standard 10x10

Use `Start Standard 10x10` for the Standard smoke route.

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

## Known limits

- No Godot import/runtime smoke is part of the static G5 validation.
- No full MetaProgress, Deploy UI, action combat, video, music, or font migration.
- Some migrated icons remain internal placeholders until final art approval.
