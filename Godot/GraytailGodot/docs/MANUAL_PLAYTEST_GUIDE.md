# Manual Playtest Guide

## Scope

This guide covers the G4 playable graybox loop plus G5 Asset/UI/Visual Parity surfaces. Do not run Godot unless the user explicitly authorizes editor/runtime execution.

## Start Tutorial 5x5

Use `Start Tutorial 5x5` to verify the fixed tutorial route and tutorial popup.

### Tutorial recommended route

- Move with W/A/S/D or arrow keys.
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

## Start Standard 10x10

Use `Start Standard 10x10` for the Standard smoke route.

### Standard smoke route

- Start a standard run.
- Move several rooms.
- Flag a cell.
- Open and close MapOverlay.
- Search a Normal or Chest room.
- Fight a Monster if reached.
- Confirm extraction only from an Exit room.

Expected G5 visuals:

- MiniMap and MapOverlay share the same ViewModel.
- Room/player visuals update from snapshots.
- ResultPanel still shows extraction/failure/training summaries.

## Known limits

- No Godot import/runtime smoke is part of the static G5 validation.
- No full MetaProgress, Deploy UI, action combat, video, music, or font migration.
- Some migrated icons remain internal placeholders until final art approval.
