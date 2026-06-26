# Validation Index

文档状态：验证索引
适用范围：仓库验证记录入口
最后更新：2026/06/26

验证记录只证明其明确验证范围。Godot headless project-load/parser smoke PASS 不等于 gameplay runtime PASS；manual playtest 未运行时不得写成 PASS。

## 1. 当前验证读取顺序

| stage | evidence | boundary |
| --- | --- | --- |
| DOC-GOV-001 | `docs/00_governance/DOC_GOV_001_EXECUTION_REPORT.md` | docs-only governance 自检；不运行 Godot；不提交；不 push |
| G36 | `docs/validation/G36_RUNTIME_ARCHITECTURE_SAVE_PROFILE_VALIDATION.md` | runtime architecture / save profile foundation；不声明 gameplay runtime PASS / manual playtest PASS |
| G35 | `docs/validation/G35_RUNTIME_SAFETY_OWNERSHIP_CLEANUP_VALIDATION.md` | runtime safety / ownership cleanup |
| G34 | `docs/validation/G34_RULE_EFFECT_MODIFIER_CONTENT_DELIVERY_COMMON_SYSTEM_VALIDATION.md` | rule/effect/modifier/content-delivery preview content |
| G33 | `docs/validation/G33_ROOM_TYPE_TAG_ENCOUNTER_COMMON_RULE_VALIDATION.md` | room type/tag/encounter common-rule preview content |
| G32 | `docs/validation/G32_RUN_FLOW_STATE_TRANSITION_FULL_CONTENT_VALIDATION.md` | run flow/state transition preview content |
| G31 | `docs/validation/G31_RUN_MAP_DOMAIN_ROOM_STATE_FOUNDATION_VALIDATION.md` | run map/room-state preview content |
| G30 | `docs/validation/G30_LONG_TERM_SYSTEM_ASSET_INTERFACE_FULL_CONTENT_VALIDATION.md` | LongTerm asset interface preview content |
| G27A-G29 | `docs/validation/` and `docs/handoff/` | historical / closed evidence |
| G20-G26 | `docs/validation/` and `docs/handoff/` | historical / closed evidence |

## 2. 使用边界

```text
1. validation 原文保留原位。
2. 本索引不复制完整验证正文。
3. 本索引不扩大验证结论。
4. gameplay runtime PASS 和 manual playtest PASS 必须有对应实际验证记录，否则不得声明。
5. DOC-GOV-001 不运行 Godot，不新增工程验证结论。
```
