# Branch Change: G8.2 Kernel Protocol Hardening

## Branch

`godot/g8-2-kernel-protocol-hardening`

## Base

`main` after G8.1 merge commit `91ddf591b04923520834e72eab99a8b6d8702aa4`.

## Purpose

G8.2 hardens the kernel protocols that sit between UI, rules, effects, events, transactions, modifiers, and content definitions. It is not a new gameplay stage.

## Implemented

- Command envelope remains the formal entry through `CommandBus.dispatch`.
- `CommandResult` standardizes accepted/rejected command output with `reason_code`, `message_key`, produced events, produced transactions, and snapshot refresh hints.
- `RunQueryFacade` exposes event log, transaction log, and content definition snapshots as read-only copies.
- `RunEventLog` records fact events including run_started, room_entered, room_searched, item_gained, item_picked_up, item_dropped, combat_resolved, event_option_selected, extraction_found, extraction_success, run_failed, and settlement_completed.
- `RunTransactionLog` records asset-related transactions with command/effect correlation.
- EffectSpec now carries `effect_id`, `command_id`, and `rule_request_id`.
- `RunRulePipeline` and `RunModifierSpec` reserve stable RuleRequest, RuleContext, DefaultRuleResult, ModifierSpec application, Final RuleResult, and produced EffectSpec/Event/Transaction protocol hooks.
- `ContentDefRegistry` reserves stable ContentDef fields for CurrencyDef, ItemDef, EncounterDef, EffectDef, ModifierDef, and LootTableDef.
- `validate_kernel_protocol_g8_2.ps1` verifies the G8.2 protocol boundary.

## Not Implemented

- No full MetaProgress.
- No Deploy persistence.
- No action combat.
- No full Warehouse UI.
- No task, codex, or relic repair system.
- No new gameplay content or UI polish.
- No Godot editor/runtime/import run in this stage.
