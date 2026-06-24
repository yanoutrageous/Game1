# Handoff: G33 Room Type / Tag / Encounter Common Rule

Stage: G33-R2 Room Type / Tag / Encounter Common Rule Full Content Implementation.

Branch: `godot/g33-room-type-tag-encounter-common-rule`

## Product Contract

Primary contract:

- `docs/20_product/ROOM_TYPE_TAG_ENCOUNTER_COMMON_RULE_CONTRACT.md`

## Implementation Summary

G33 adds a unified room and encounter common-rule preview layer:

- `RoomEncounterCommonRuleSchema` defines RoomType, RoomTag, RoomPolicy, RoomState, RoomContentSlot, EncounterEntry, EncounterPreview, RoomRulePreview, RoomCondition, RoomResolutionPreview, RoomResultPreview, GroundLoot, and RoomLootContainer.
- `TruthMap` exposes these fields through public room state and map/result previews.
- `EncounterResolver` exposes EncounterEntry / EncounterPreview / RoomRulePreview without changing option execution.
- `RunFlowStateContract` carries room resolution and room result preview into RunFlowSnapshot.
- `RunQueryFacade`, Settlement snapshot, RunSurface, and HUD consume display-only summaries.

## Boundaries

All new data remains:

```text
read_only
display_only
preview
no_persistence
```

G33 does not implement battle runtime, event-chain runtime, RoomLoot/GroundLoot runtime, Rule/Modifier engine, Objective/Reward/Pool runtime, settlement warehouse write, SaveManager, AssetLedger mutation, RunAssetLedger mutation, CommandBus mutation, FileAccess/user:// persistence, or resource import.

## Validation Record

- Static validation PASS.
- `git diff --check` PASS with LF/CRLF conversion warnings only and no whitespace errors.
- Negative grep safe-hit review PASS; hits were existing runtime/preload/UI construction code, existing run systems outside the G33 delta, display text, and preview/no_persistence fields.
- Positive grep evidence PASS for room type/tag/policy/state, encounter entry/preview, room content slot, rule/condition/resolution/result preview, GroundLoot, RoomLootContainer, and preview/display-only/read-only fields.
- Godot headless project-load/parser smoke PASS.
- Godot smoke produced no new metadata dirty side effects.

The Godot smoke only represents project-load/parser validation. It is not gameplay runtime PASS and not manual playtest PASS.

## Next Recommended Gate

Run unified G33-R3 audit / release confirmation. Do not merge main until that gate confirms branch state, remote state, validation record, and no forbidden path changes.
