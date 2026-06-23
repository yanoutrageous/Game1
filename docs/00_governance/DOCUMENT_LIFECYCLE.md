# P2 Document Lifecycle

文档状态：当前治理规则
适用范围：P2 后仓库 `docs` 文档生命周期
最后更新：2026/06/23

## 1. 生命周期类型

| 类型 | 含义 | 维护规则 |
| --- | --- | --- |
| `current_entry` | 当前必读入口 | 保持短、可审计，不超过 5 个第一入口 |
| `current_state` | 当前事实摘要 | 只汇总已验证事实和明确边界 |
| `draft_contract` | 产品契约草案 | 必须标注草案 / 待确认 |
| `external_live_reference` | 外部当前只读来源 | 每次按当前外部目录只读定位；仓库只登记路径和观测信息 |
| `historical_authorized_snapshot` | 此前获授权的冻结历史快照 | 不自动同步；不替代当前外部原件；无新授权不得刷新 |
| `ui_reference` | UI 图片参考 | 只登记类型，不作为规则权威 |
| `connection_external_only` | Connection 外部并行交接资料 | 仓库只登记路径/哈希；内容不进入 Git 或 Godot |
| `validation_evidence` | 验证记录 | 只证明记录中明确验证过的范围 |
| `stage_evidence` | 阶段 handoff / summary | 保留历史证据，不批量重写 |
| `archive` | 历史归档或旧体系说明 | 先登记，后迁移；不直接删除 |

## 2. 当前入口维护规则

```text
1. INDEX.md 只负责入口和阅读顺序。
2. CURRENT_STATE.md 只写当前事实摘要，不复制全部历史正文。
3. NEXT_ACTION.md 只写下一步和闸门，不自动启动 G26。
4. CAPABILITY_MATRIX.yaml 只登记能力状态，不定玩法规则。
5. SOURCE_REGISTRY.md 负责来源归属，不替代来源文件。
```

## 3. 旧文档处理规则

```text
1. 旧入口文档保留为 expanded_evidence 或 historical_navigation。
2. 历史 handoff / validation / stage summaries 不删除。
3. 如需移动旧文档，必须先登记归档说明并获得确认。
4. 如需把外部来源转成正式规则，必须另起确认流程。
5. Base Docs 文件名或归档位置变化时，按主题、相近名称、更新时间和文档状态重新定位。
6. 不因外部并行更新而回滚、清理或覆盖 Base Docs / Connection。
```
