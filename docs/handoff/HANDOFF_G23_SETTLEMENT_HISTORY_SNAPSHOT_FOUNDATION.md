# Handoff: G23 Settlement / History Snapshot Foundation

## Status

- Branch: `godot/g23-settlement-history-snapshot-foundation`.
- G23 implementation commit: `f20ddf60513f17ef72afe8e5c99a4e1a22fccd0e`.
- Static validation PASS.
- Godot headless project-load/parser smoke PASS.
- Smoke left the working tree with only the expected G23 implementation files before commit and no new dirty side effects.

## Scope

G23 establishes schema / preview / projection foundation only:

- `SettlementSnapshotSchema`.
- `HistoryRecordSnapshot` schema.
- `SettlementHistoryPreview` adapter from settlement preview to history preview.
- LongTerm personal profile / history display-only preview consumer.

## Boundaries

This stage does not implement real settlement, real history persistence, reward grant, asset mutation, resource economy, event bus, SaveManager, RunScene end flow, complete LongTerm, complete Warehouse, or complete Gacha.

No gameplay runtime PASS or manual playtest PASS is claimed.
