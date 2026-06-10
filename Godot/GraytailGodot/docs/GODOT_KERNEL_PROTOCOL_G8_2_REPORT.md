# Godot Kernel Protocol G8.2 Report

## Stage

G8.2 Kernel Protocol Hardening: command, query, event, effect, modifier, and content definition closure.

## Branch

`godot/g8-2-kernel-protocol-hardening`

## Summary

G8.2 keeps G8/G8.1 gameplay behavior intact and hardens the protocol surface for later work. It does not add a new gameplay stage.

## Runtime Protocols

- Command envelope: `command_id`, `actor_id`, `source`, `payload`, `sequence`.
- CommandResult: `accepted`, `reason_code`, `message_key`, `command_id`, `produced_events`, `produced_transactions`, `snapshot_delta`.
- EventLog: fact-only events for run, room, item, combat, event, extraction, failure, and settlement.
- TransactionLog: asset transaction entries with before/after summaries, currency delta, item moves, and sequence.
- EffectSpec: `effect_id`, `type`, `source`, `target`, `payload`, `actor_id`, `command_id`, `rule_request_id`.
- ModifierSpec: `modifier_id`, `source`, `priority`, `phase`, `target_rule`, `operation`, `value`, `duration`, `stack_rule`, `conflict_tags`, `reason`.
- ContentDef: `content_id`, `schema_version`, `kind`, `display_name_key`, `tags`, `definition`, `deprecated_state`.

## Boundary

- UI dispatches commands and consumes snapshots/ViewModels.
- Rules produce RuleResult and EffectSpec data.
- Asset changes go through EffectHandler and Ledger.
- EventLog and TransactionLog record facts and applied changes; neither is a mutation entry point.
- ContentDef is declarative only.

## Validation

`validate_kernel_protocol_g8_2.ps1` checks the new protocol in addition to all previous G7/G8/G8.1 validators.

## Non-Goals

- No full MetaProgress.
- No Deploy persistence.
- No action combat.
- No full Warehouse UI.
- No UI polish or new gameplay content.
- No Godot/editor/game/import run.
