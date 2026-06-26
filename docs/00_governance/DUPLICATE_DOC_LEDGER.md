# DOC-GOV-001 Duplicate Document Ledger

文档状态：当前治理台账
适用范围：重复文档、历史入口、外部快照、当前权威入口的状态登记
最后更新：2026/06/26

本台账只登记状态和引用关系，不删除、不移动、不重命名、不归档任何文件。

## 1. 处理原则

```text
当前入口：用于新对话、审计和下一步决策。
历史扩展证据：保留上下文，不作为第一入口。
历史快照：保留当时状态，不替代当前来源。
外部原件：仓库外只读来源，不参与仓库去重。
```

## 2. 当前入口重复组

| 文档 | 当前状态 | 处理 |
| --- | --- | --- |
| `docs/README.md` | 当前文档树第一入口 | 当前权威入口 |
| `docs/INDEX.md` | 当前索引入口 | 保持短索引，指向 G36 和目录职责 |
| `docs/10_current/CURRENT_STATE.md` | 当前事实摘要 | 收口到 G36 |
| `docs/10_current/NEXT_ACTION.md` | 当前下一步 | 收口到 DOC-GOV-001 审计复查 / G36 后续 gate |
| `docs/10_current/CAPABILITY_MATRIX.yaml` | 当前能力矩阵 | 收口到 G36 |
| `docs/DOCS_INDEX.md` | 旧导航 | 历史扩展证据 |
| `docs/PROJECT_BASELINE.md` | 旧扩展基线 | 历史扩展证据 |
| `docs/ENGINEERING_STATUS.md` | 旧工程状态 | 历史扩展证据 |
| `docs/NEXT_HANDOFF.md` | 旧下一步 / handoff 聚合 | 历史扩展证据 |

## 3. 治理目录重复组

| 文档组 | 当前状态 | 处理 |
| --- | --- | --- |
| `docs/00_governance/**` | 当前治理入口 | 当前权威治理目录 |
| `docs/project_governance/**` | G20 历史治理证据 | 保留，不作为当前治理入口 |

## 4. 仓库 docs 与 Base Docs_Governance 快照重复组

| 文档组 | 当前状态 | 处理 |
| --- | --- | --- |
| `D:\AGAME1\_repo_cache\Game1_work\docs` | 当前仓库文档事实入口 | 当前仓库内权威入口 |
| `D:\AGAME1\Base Docs_Governance\06_工程仓库docs参考\docs` | 2026/06/22 历史快照 | 只读参考，不作为当前仓库事实源 |

## 5. Godot docs 与仓库 docs 边界重复组

| 文档组 | 当前状态 | 处理 |
| --- | --- | --- |
| `Godot/GraytailGodot/docs` | 工程历史 / 环境证据 | 只读证据，非当前治理入口 |
| `Game1_work/docs` | 当前仓库文档主入口 | 新文档优先写入此处 |

## 6. 阶段证据重复组

| 文档组 | 当前状态 | 处理 |
| --- | --- | --- |
| `docs/validation/**` | 阶段验证原文 | 保留原位，由 validation index 指向 |
| `docs/handoff/**` | 阶段 handoff 原文 | 保留原位，由 stage index / docs index 指向 |
| `docs/stage_summaries/**` | G10-G19 阶段摘要 | 历史证据 |
| `docs/branch_changes/**` | 早期分支变化记录 | 历史证据 |
| `docs/audits/**` | 早期审计记录 | 历史证据 |

## 7. 产品来源重复组

| 文档组 | 当前状态 | 处理 |
| --- | --- | --- |
| `D:\AGAME1\Base Docs` | 外部策划原件 / 用户留档 | 不参与去重，不写入、不移动、不删除 |
| `docs/20_product/**` | 当前仓库产品契约 | 当前仓库内契约入口 |
| `docs/design_sources/**` | G20 历史导入参考 | 不自动同步 Base Docs 当前原件 |
| `docs/70_sources/**` | 外部来源登记 / 历史快照 | 只登记和引用来源，不替代外部原件 |

## 8. 当前待复查点

```text
1. G30-G36 contract / validation / handoff 已补中文摘要，需审计确认摘要未引入新规则。
2. Base Docs_Governance 快照关系需审计确认没有被写成当前事实源。
3. docs/INDEX.md 是否足够短，需后续使用验证。
4. 旧入口是否还需要更显著的顶部状态说明，可由审计框复查后决定。
```
