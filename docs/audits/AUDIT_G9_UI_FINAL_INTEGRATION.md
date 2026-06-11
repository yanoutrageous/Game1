# Audit: G9 UI Final Integration

## Scope

G9 UI Final Integration creates a formal player flow for the current Godot prototype. It is not a full final UI, final art pass, full MetaProgress, Deploy persistence, or action combat stage.

## Formal Player Flow

- Main page presents `出发探索`, `长期系统`, and `设置` as primary entries.
- Tutorial and standard run remain accessible without becoming the only flow.
- Expedition page exposes map, warehouse, claim, loadout, talents, character/outfit placeholders, summary, tutorial, standard, and confirm deploy entries.
- Long-term page exposes task, codex, achievement, profile, and research placeholders.
- Debug remains folded and dev-only.

## Inventory And Ground Loot

- InventoryPanel reads snapshot data only.
- GroundLootPanel reads snapshot data only.
- Pickup/drop requests emit signals back to run scene, which dispatches CommandBus commands.
- Panels display capacity, item tooltip, and CommandResult reason text.

## Result Explanation

- ResultPanel consumes a RunUIViewModel summary.
- The summary includes success/failure outcome, currency, carried items, room floor leftovers, Warehouse Lite count, salvage data, settlement log count, EventLog summary, and TransactionLog summary.

## Boundaries

- UI scripts do not write persistence.
- UI scripts do not directly read `RunAssetLedger` or `TruthMap`.
- `PresentationLayerContracts` remains contract-only.
- Long-term systems, character/outfit, and map overlay themes remain shell/interface work only.

## Known Limits

- Runtime smoke verifies the baseline, but this branch does not target final layout polish.
- No real art import.
- No complete settings persistence.
- No complete warehouse economy.
- No action combat.
- No full MetaProgress.
- No Deploy persistence.
