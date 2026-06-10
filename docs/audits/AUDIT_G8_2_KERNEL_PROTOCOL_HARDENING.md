# Audit: G8.2 Kernel Protocol Hardening

## Scope

G8.2 verifies the kernel boundary after G8.1. The goal is to prevent later UI, rule, and content work from bypassing command, query, effect, event, transaction, modifier, and content definition contracts.

## Command Boundary

- Formal entry is `CommandBus.dispatch`.
- The command envelope contains `command_id`, `actor_id`, `source`, `payload`, and `sequence`.
- Direct methods such as `move_by`, `search_current_room`, `confirm_extract`, `pickup_ground_item`, and `drop_inventory_item` remain as compatibility wrappers inside `CommandBus`.
- Formal UI/debug buttons call `dispatch` and receive `CommandResult`.

## Query Boundary

- `RunQueryFacade` owns public status/result snapshots.
- UI reads HUD, result, map, event, inventory, event log, transaction log, and ContentDef data from snapshots/ViewModels.
- Query code returns duplicated arrays/dictionaries and does not mutate state.

## Mutation Boundary

- Asset state remains owned by `RunAssetLedger`.
- Asset mutations are applied by `RunAssetEffectHandler` from EffectSpec dictionaries.
- `RunEventLog` records facts only and does not mutate run state.
- `RunTransactionLog` records applied asset changes and does not decide rules.
- ModifierSpec is a rule rewrite contract only; it does not write ledger or UI state.
- ContentDef data is declarative only.

## CommandResult And Rejection

`CommandResult` standardizes:

- `accepted`
- `reason_code`
- `message_key`
- `command_id`
- `produced_events`
- `produced_transactions`
- `snapshot_delta`

Covered rejection reasons include invalid_direction, blocked_flagged, out_of_bounds, blocked_hidden, tutorial_lock, blocked_capacity, no_room_floor_items, no_inventory_items, cannot_extract, no_extract_request, combat_unavailable, and event_option_unavailable.

## Event And Transaction Audit

- `RunEventLog` covers run_started, room_entered, room_searched, item_gained, item_picked_up, item_dropped, combat_resolved, event_option_selected, extraction_found, extraction_success, run_failed, and settlement_completed.
- `RunTransactionLog` covers currency deltas, item moves, pickup, drop, sale, success settlement, and failure settlement.
- The correlation chain is command_id -> rule_request_id -> effect_id -> transaction_id -> event_id.

## RulePipeline, ModifierSpec, ContentDef

- `RunRulePipeline` reserves RuleRequest, RuleContext, DefaultRuleResult, ModifierSpec application, Final RuleResult, produced EffectSpec, produced Event, and produced Transaction hooks.
- `RunModifierSpec` has stable ordering through phase + priority + sequence.
- `ContentDefRegistry` reserves stable ContentDef fields: `content_id`, `schema_version`, `kind`, `display_name_key`, `tags`, `definition`, and `deprecated_state`.
- Reserved content kinds: CurrencyDef, ItemDef, EncounterDef, EffectDef, ModifierDef, LootTableDef.

## Non-Goals Confirmed

- No full MetaProgress or Deploy persistence.
- No action combat.
- No full Warehouse UI.
- No new gameplay stage.
- No Godot/editor/game/import run required for this audit.
