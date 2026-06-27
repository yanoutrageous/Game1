# DOC-GOV-002 Duplicate Document Ledger

文档状态：当前治理台账
适用范围：重复文档、历史入口、外部快照、当前权威入口的状态登记
最后更新：2026/06/27

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
| `docs/INDEX.md` | 当前索引入口 | 保持短索引，指向 G38 / G37S / G37 / G36 和目录职责 |
| `docs/10_current/CURRENT_STATE.md` | 当前事实摘要 | 收口到 G38 / G37S / G37 / DOC-GOV-002 口径 |
| `docs/10_current/NEXT_ACTION.md` | 当前下一步 | 收口到 DOC-GOV-002 后续审计 / Git gate / 下一策划主题准备 |
| `docs/10_current/CAPABILITY_MATRIX.yaml` | 当前能力矩阵 | 收口到 G38 / G37S / G37 / G36 摘要 |
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

## 8. DOC-GOV-001 历史复查备注

```text
以下为 DOC-GOV-001 阶段遗留的复查备注，DOC-GOV-002 中仅保留历史上下文。
它们不作为 DOC-GOV-002 当前阻塞项，也不授权改写历史正文。

1. G30-G36 contract / validation / handoff 中文摘要曾需审计确认摘要未引入新规则。
2. Base Docs_Governance 快照关系曾需审计确认没有被写成当前事实源。
3. docs/INDEX.md 是否足够短，曾需后续使用验证。
4. 旧入口是否还需要更显著的顶部状态说明，曾建议由审计框复查后决定。
```

## 9. DOC-GOV-002 根目录旧文件状态登记

本表只登记 `docs` 根目录旧文件的当前阅读状态，不移动、不删除、不重命名、不改写旧文件正文。

| 根目录文件 | 状态分类 | 处理说明 |
| --- | --- | --- |
| `docs/CODEX_TASKS.md` | deprecated_reference | 旧任务聚合参考，不作为当前任务入口 |
| `docs/design-integration-delta.md` | legacy_integration | early integration plan / delta 历史证据 |
| `docs/design-integration-plan.md` | legacy_integration | early integration plan 历史证据 |
| `docs/dev-plan.md` | legacy_design | 旧开发计划参考，不作为当前路线入口 |
| `docs/DOCS_INDEX.md` | deprecated_reference | 旧导航，当前入口为 `docs/INDEX.md` |
| `docs/ENGINEERING_STATUS.md` | historical_status | 旧工程状态扩展正文，当前摘要见 `docs/10_current/` |
| `docs/game-design.md` | legacy_design | 旧设计参考，不反推当前规则 |
| `docs/GAMEPLAY_LOGIC_MVP_STATUS.md` | historical_status | 旧 MVP 状态记录，不声明当前 runtime PASS |
| `docs/HANDOFF_TWO_PC.md` | historical_handoff | 旧 two-PC handoff 证据 |
| `docs/HANDOFF_TWO_PC_CURRENT_BRANCHES.md` | historical_handoff | 旧 two-PC branch handoff 证据 |
| `docs/HANDOFF_TWO_PC_GODOT_BRANCH.md` | historical_handoff | 旧 Godot branch handoff 证据 |
| `docs/HANDOFF_TWO_PC_GODOT_LUA_PARITY_P0.md` | historical_handoff | 旧 Lua parity handoff 证据 |
| `docs/HANDOFF_TWO_PC_GODOT_PLAYABLE_GRAYBOX.md` | historical_handoff | 旧 playable graybox handoff 证据 |
| `docs/integration-self-check.md` | legacy_integration | early integration self-check 历史证据 |
| `docs/LUA_BASELINE_STATUS.md` | legacy_lua | Lua baseline 历史证据，不作为当前 Godot 事实源 |
| `docs/MILESTONES.md` | historical_status | 旧里程碑记录，当前状态见 `docs/10_current/` |
| `docs/NEXT_HANDOFF.md` | historical_handoff | 旧下一步 / handoff 聚合，当前下一步见 `docs/10_current/NEXT_ACTION.md` |
| `docs/PROJECT_BASELINE.md` | historical_status | 旧扩展基线，当前摘要见 `docs/10_current/CURRENT_STATE.md` |
| `docs/REFACTOR_ARCHITECTURE.md` | deprecated_reference | 旧重构架构参考，不作为当前工程契约 |
| `docs/REPO_POLICY.md` | historical_status | 旧仓库策略参考，当前文档治理见 `docs/00_governance/` |
| `docs/UE_FOUNDATION_STATUS.md` | legacy_ue | UE 旧路线历史证据 |
| `docs/UE_REFACTOR_IMPLEMENTATION.md` | legacy_ue | UE 旧重构历史证据 |
| `docs/ui-layout-implementation-plan.md` | legacy_design | 旧 UI layout 实施参考，不反推当前 UI 规则 |
| `docs/v0.3-progress-assessment.md` | needs_archive_decision | v0.3 历史报告，未来可评估归档但不得直接移动 |
| `docs/v03-balance-port-self-check.md` | needs_archive_decision | v03 balance port 历史报告，未来可评估归档但不得直接移动 |

`current_entry` 只保留给 `docs/README.md`、`docs/INDEX.md`、`docs/10_current/*` 和 `docs/00_governance/*`。根目录旧文件不得重新声明为当前第一入口。

## 10. DOC-GOV-002 归档候选清单

以下仅为未来治理候选，不是删除建议，不是立即移动建议：

| 候选组 | 包含范围 | 当前处理 |
| --- | --- | --- |
| UE 旧路线 | `UE_FOUNDATION_STATUS.md`、`UE_REFACTOR_IMPLEMENTATION.md` | 仅登记为 legacy_ue |
| Lua 旧审计 / baseline | `LUA_BASELINE_STATUS.md`、`docs/lua_audit/**` | 仅登记为 legacy_lua |
| early integration plan | `design-integration-*.md`、`integration-self-check.md` | 仅登记为 legacy_integration |
| old two-PC handoff | `HANDOFF_TWO_PC*.md` | 仅登记为 historical_handoff |
| v0.3 / v03 报告 | `v0.3-progress-assessment.md`、`v03-balance-port-self-check.md` | 仅登记为 needs_archive_decision |
| 旧 root design/dev 文件 | `game-design.md`、`dev-plan.md`、`ui-layout-implementation-plan.md` | 仅登记为 legacy_design |

## 11. DOC-GOV-002 命名与摘要执行约束

本台账登记重复与归档候选状态时采用以下约束：

```text
1. 新 contract 优先使用 Gxx_主题_CONTRACT.md。
2. 新 validation 优先使用 Gxx_主题_VALIDATION.md。
3. 新 handoff 优先使用 HANDOFF_Gxx_主题.md。
4. ART 主题文档优先使用 ARTxx_主题.md。
5. 文档治理文档优先使用 DOC_GOV_xxx_主题.md。
6. 当前入口中文优先；当前 contract / validation / handoff 至少提供中文摘要。
7. 历史英文文档不强制全文翻译。
8. 旧文件不强制重命名。
9. 归档候选不得移动、不得删除，只能等待未来治理阶段确认。
```
