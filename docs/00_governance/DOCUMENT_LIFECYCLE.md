# DOC-GOV-001 Document Lifecycle

文档状态：当前治理规则
适用范围：仓库 `docs` 文档生命周期、重复文档状态、阶段完成文档落位
最后更新：2026/06/26

本文件是 DOC-GOV-001 后的仓库文档生命周期规则。P2 历史规则保留其证据价值，但当前治理入口以 `docs/README.md`、`docs/INDEX.md`、`docs/00_governance/DOC_PLACEMENT_STANDARD.md` 和本文件为准。

## 1. 生命周期类型

| 类型 | 含义 | 维护规则 |
| --- | --- | --- |
| `current_entry` | 当前必读入口 | 保持短、可审计，不超过 5 个第一入口 |
| `current_state` | 当前事实摘要 | 只汇总已验证事实和明确边界 |
| `baseline_assessment` | 获批准阶段形成的详细基线评估 | 阶段关闭后冻结；未来变化通过新的当前摘要或新评估表达 |
| `draft_contract` | 产品契约草案 | 必须标注草案 / 待确认 |
| `external_live_reference` | 外部当前只读来源 | 每次按当前外部目录只读定位；仓库只登记路径和观测信息 |
| `historical_authorized_snapshot` | 此前获授权的冻结历史快照 | 不自动同步；不替代当前外部原件；无新授权不得刷新 |
| `ui_reference` | UI 图片参考 | 只登记类型，不作为规则权威 |
| `connection_external_only` | Connection 外部并行交接资料 | 仓库只登记路径/哈希；内容不进入 Git 或 Godot |
| `validation_evidence` | 验证记录 | 只证明记录中明确验证过的范围 |
| `stage_evidence` | 阶段 handoff / summary | 保留历史证据，不批量重写 |
| `archive` | 历史归档或旧体系说明 | 先登记，后迁移；不直接删除 |
| `external_governance_snapshot` | 外部治理快照 | 只读参考；不替代当前仓库事实源 |
| `duplicate_registered` | 重复文档已登记 | 不删除；由 `DUPLICATE_DOC_LEDGER.md` 说明状态 |

## 2. 当前入口维护规则

```text
1. INDEX.md 只负责入口和阅读顺序。
2. CURRENT_STATE.md 只写当前事实摘要，不复制全部历史正文。
3. NEXT_ACTION.md 只写下一步和闸门，不自动启动 G26。
4. CAPABILITY_MATRIX.yaml 只登记能力状态，不定玩法规则。
5. SOURCE_REGISTRY.md 负责来源归属，不替代来源文件。
6. DOC_PLACEMENT_STANDARD.md 负责新文档落位规则。
7. DUPLICATE_DOC_LEDGER.md 负责重复组状态登记。
```

## 3. 旧文档处理规则

```text
1. 旧入口文档保留为 expanded_evidence 或 historical_navigation。
2. 历史 handoff / validation / stage summaries 不删除。
3. 如需移动旧文档，必须先登记归档说明并获得确认。
4. 如需把外部来源转成正式规则，必须另起确认流程。
5. Base Docs 文件名或归档位置变化时，按主题、相近名称、更新时间和文档状态重新定位。
6. 不因外部并行更新而回滚、清理或覆盖 Base Docs / Connection。
7. `Base Docs_Governance/06_工程仓库docs参考` 是历史快照，不参与当前仓库去重执行。
8. `Godot/GraytailGodot/docs` 是工程历史 / 环境证据，不再作为当前阶段治理主入口。
```

## 4. 阶段完成文档规则

```text
1. contract / validation / handoff 原文保留原位。
2. 当前入口只保留摘要、链接、边界和下一步。
3. validation index 登记验证证据，不复制全文。
4. stage index 登记 active / closed / historical 状态。
5. G30-G36 当前关键英文文档至少保留中文摘要，摘要只解释既有内容。
6. 禁止为了统一入口而删除、移动、重命名历史文档。
```
