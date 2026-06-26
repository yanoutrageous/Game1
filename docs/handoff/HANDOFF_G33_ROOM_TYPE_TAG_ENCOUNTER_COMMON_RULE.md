# Handoff: G33 Room Type / Tag / Encounter Common Rule

## 中文交接摘要（DOC-GOV-001）

G33 记录房间类型、标签与遭遇通用规则的 preview / display-only 内容。它说明 RoomType、RoomTag、RoomPolicy、RoomState、EncounterEntry、RoomRulePreview、RoomResultPreview、GroundLoot 和 RoomLootContainer 的语义预览边界；不实现 battle runtime、monster AI、事件链 runtime、真实掉落/背包、规则引擎、奖励发放、结算仓库写入、SaveManager、CommandBus mutation、gameplay runtime PASS 或 manual playtest PASS。

本交接摘要只帮助阅读 handoff，不授权后续实现，不替代下一阶段 gate。


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
