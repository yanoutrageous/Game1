# Branch Change: G9 UI Final Integration

## Branch

`godot/g9-ui-final-integration`

## Base

`main` at `aa5a93ed68a9a755293b97e65d4b9ffa4881054e`.

## Purpose

G9 UI Final Integration compresses the remaining G9 UI work into one playable baseline. It is a UI baseline, not a full final UI.

## Implemented

- Three-page shell: main menu, expedition page, and long-term system page.
- Product title correction to `灰尾回收` with `五四三二一` as project subtitle.
- Expedition shell entries for map, warehouse, claim, loadout, talents, character/outfit, tutorial run, standard run, and confirm deploy.
- Long-term shell entries for task, codex, achievement, profile, and research placeholders.
- Formal player InventoryPanel and GroundLootPanel.
- Pickup and drop through CommandBus dispatch from formal UI, no longer debug-only.
- CommandResult blocked reason display.
- ResultPanel settlement explanation through EventLog and TransactionLog summaries.
- `validate_ui_final_g9.ps1`.

## Not Implemented

- No drag/drop, sorting, or full filtering set.
- No complete warehouse economy.
- No insurance or consignment system.
- No full MetaProgress persistence.
- No Deploy persistence.
- No full task, codex, achievement, or research backend.
- No complete character or outfit system.
- No action combat.
- No large art migration.
