# G32 Open Decisions Update

G32-R2 run flow / state transition open decisions:

- `OD-G32-001`: exact active-run persistence and continue recovery model remains open; G32 exposes disabled/preview state only.
- `OD-G32-002`: real abandon settlement outcome remains open; G32 exposes strong-confirm intent only.
- `OD-G32-003`: DeployPrep full RunBootstrapper and config legality bridge remains open; G32 uses the existing demo/standard run route only.
- `OD-G32-004`: final RoomActionResult vocabulary for RoomLoot, Objective, Reward, and Modifier remains open.
- `OD-G32-005`: SettlementTriggerPreview to real settlement report handoff remains open; G32 does not write warehouse state.
- `OD-G32-006`: CommandBus command-list expansion remains explicitly deferred to a separate audited gate.
- Any G31 / older open-decision wording below this update is historical unless explicitly reopened.

# G31 Open Decisions Update

G31-R2 run map / room-state open decisions:

- `OD-G31-001`: exact map generator repair/retry policy remains open; G31 records preview validation and log fields only.
- `OD-G31-002`: final fast-return lock conditions remain open; G31 exposes eligibility / reason code / intent only.
- `OD-G31-003`: scan reliability vocabulary and UI depth remain open; G31 reserves InfoReliabilityLayer fields.
- `OD-G31-004`: future hex / multi-layer / special-rule map interface depth remains open.
- `OD-G31-005`: MapResult handoff depth for Settlement / History / Objective remains open; G31 reserves map-facing previews only.
- `OD-G31-006`: event-driven map mutation runtime remains open and deferred.
- Any G30 / older open-decision wording below this update is historical unless explicitly reopened.

# G30 Open Decisions Update

G30-R2 long-term system / asset interface open decisions:

- `OD-G30-001`: LongTerm six-module final naming remains open: 目标 / 图鉴 / 研究 / 个人资历 / 抽奖 / 收藏 / 外观 may still receive final display names.
- `OD-G30-002`: history record default priority inside 个人资历 remains open.
- `OD-G30-003`: RewardBundle ownership and claim location remain open; G30 only models preview fields.
- `OD-G30-004`: red_dot_policy clear granularity remains open; G30 models preview reasons and clear-policy names only.
- `OD-G30-005`: gacha pool display depth, owned/unowned display, and result jump priority remain open.
- `OD-G30-006`: collection / appearance display depth and unique collectible duplicate policy remain open.
- `OD-G30-007`: research line visibility and whether research remains a primary module remain open.
- `OD-G30-008`: jump_target priority and return-path UX remain open.
- Any G29 / older open-decision wording below this update is historical unless explicitly reopened.

# G29 Open Decisions Update

G29-R2 deploy prep revision open decisions:

- `OD-G29-001`: default number of selectable run objectives remains open; current preview assumes 0-1.
- `OD-G29-002`: whether purchase-and-add-to-attendance is exposed as a shortcut remains open; G29 models it as two future events.
- `OD-G29-003`: warehouse sale confirmation and configured-item sale conflict behavior remain open.
- `OD-G29-004`: abandon exploration retained-record rules remain open.
- `OD-G29-005`: insurance, consignment, and 作业许可 remain future interface / locked state.
- `OD-G29-006`: exact topology effect text for consumables remains open; G29 only reserves the display boundary.
- Any G28A / older open-decision wording below this update is historical unless explicitly reopened.

# G28A Open Decisions Update

G28A docs-only open decisions:

- `OD-G28A-001`: preview fixture row count and review depth remain open.
- `OD-G28A-002`: whether `material` remains a content category only or later becomes a runtime economy concept remains open.
- `OD-G28A-003`: appearance display depth for LongTerm collection / appearance views remains open.
- `OD-G28A-004`: `room_loot`, `ground_loot`, and `run_bag_item` are reserved concepts only; future gate must decide whether they stay interface-only or become runtime contracts.
- `OD-G28A-005`: G29 naming remains open: Objective / Reward / Pool Contract Foundation or a later split name.
- Any G27A / prior G27 open-decision wording below this update is historical / superseded / resolved unless explicitly reopened.

# G27A Open Decisions Update

G27A docs-only decision posture:

- G27A asset-domain / warehouse-view contract wording is a documentation foundation, not runtime implementation approval.
- G27B requires a separate gate before any Godot asset or warehouse schema code is added.
- G27C requires a separate gate before any display-only warehouse UI consumer is added.
- Objective / Reward / Pool contract work remains deferred to G28 or later unless the roadmap is explicitly changed.
- Real warehouse, asset mutation, reward grant, gacha execution, settlement mutation, persistence, and gameplay/runtime validation remain out of scope.
- Any remaining P2 / G26 / prior G27 decision rows below this update are historical / superseded / resolved unless explicitly reopened by a future gate.

# Open Decisions

文档状态：待确认事项台账
适用范围：G27A 当前未决事项；P2 未决事项为 historical / superseded unless explicitly reopened
最后更新：2026/06/23

| decision_id | domain | item | current_status | required_confirmation |
| --- | --- | --- | --- | --- |
| OD-P2-001 | stage_boundary | P2 是否进入审计复查 | 待确认 | 用户确认 P2 文档治理是否交给审计复查 |
| OD-P2-002 | stage_boundary | G26 是否启动 | historical / resolved | G26 已完成并进入历史；不再作为未启动事项 |
| OD-P2-003 | product_contract | 产品契约草案是否可作为后续计划输入 | 草案 / 待确认 | 用户确认哪些内容可进入正式产品契约 |
| OD-P2-004 | base_docs | Base Docs 当前归档中的 `截至26.6.22报告.md` 后续归属 | 外部只读来源 / 待确认 | 用户确认是否纳入当前事实或仅作历史报告 |
| OD-P2-005 | ui_reference | UI 图片是否需要进一步分级 | 已登记为参考 | 用户确认是否补充确定图 / 示例图 / 问题截图的权威关系 |
| OD-P2-006 | connection | Connection Program / Art 资料是否转为正式任务 | 外部并行交接 / 待确认 | 用户确认是否另起流程生成接口任务；不得直接复制 Connection 内容入库 |
| OD-P2-007 | warehouse | 仓库完整策划案创建时机 | open decision retained for G27A | 仓库系统与资产视图规则策划案仍缺失；需未来 gate 决定是否创建 |
| OD-P2-008 | comfortable_loop | 舒适闭环原型 v1 范围创建时机 | 缺失待建 | 用户确认是否进入后续策划任务 |

## 使用边界

```text
待确认事项不得写成已确认规则。
```
