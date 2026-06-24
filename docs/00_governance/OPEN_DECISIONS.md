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
