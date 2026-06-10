# Handoff: G8.2 Kernel Protocol Hardening

## Current Branch

`godot/g8-2-kernel-protocol-hardening`

## Current Stage

G8.2 kernel protocol hardening. This branch extends the G8.1 architecture boundary and prepares safe follow-up work for UI, rules, content, persistence adapters, and audits.

## What Changed

- UI and debug entries dispatch command envelopes through `CommandBus.dispatch`.
- `CommandResult` exposes command rejection and produced event/transaction data.
- `RunEventLog` records fact events for run, room, item, combat, event, extraction, failure, and settlement milestones.
- `RunTransactionLog` records asset transactions and correlation data.
- EffectSpec includes `effect_id`, `command_id`, and `rule_request_id`.
- `RunRulePipeline` and `RunModifierSpec` reserve the rule modification protocol.
- `ContentDefRegistry` reserves stable ContentDef IDs and schema fields.
- `RunQueryFacade` exposes snapshots for event log, transaction log, and content definitions.

## Follow-Up Rules

UI line:

- Dispatch commands only through `CommandBus.dispatch`.
- Read state only through ViewModel/snapshot data.
- Do not read or write `RunAssetLedger`, `TruthMap`, or private run state.
- HUD/ViewModel should consume `reason_code` and `message_key` instead of inferring failures.

Rules line:

- Extend `RunRulePipeline`, `RunModifierSpec`, and `RunAssetEffectHandler`.
- Produce RuleResult and EffectSpec data.
- Do not write UI state from rule code.
- Do not bypass `RunAssetLedger` for asset changes.

Content line:

- Register declarative ContentDef entries with stable `content_id`, `schema_version`, `kind`, `tags`, and `definition`.
- Do not put state mutation code in ContentDef.
- JSON or dictionary fallback remains acceptable until a later Resource migration.

MetaProgress/Deploy line:

- Later persistence work must enter through `SaveAdapter` and `MetaProgressAdapter`.
- This branch does not implement full MetaProgress, Deploy persistence, Warehouse UI, or storage writes.

## Validation Commands

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_ux_flow_parity_g7.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_rules_g8.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_architecture_hardening_g8_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_kernel_protocol_g8_2.ps1
```

## Known Limits

- No full MetaProgress.
- No Deploy persistence.
- No action combat.
- No full Warehouse UI.
- No task, codex, or relic repair system.
- No Godot/editor/game/import run in this stage.
