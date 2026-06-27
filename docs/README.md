# Game1 Docs

文档状态：当前文档树入口
适用范围：仓库 `docs` 阅读顺序、目录职责、写入边界、后续 CodeX 文档落位
最后更新：2026/06/27

本目录是当前仓库文档事实入口。外部 `Base Docs`、`Base Docs_Governance` 和 `Connection` 不在本目录内，不由仓库文档治理自动改写或去重。

## 1. 第一阅读顺序

```text
1. docs/README.md
2. docs/INDEX.md
3. docs/10_current/CURRENT_STATE.md
4. docs/10_current/NEXT_ACTION.md
5. docs/10_current/CAPABILITY_MATRIX.yaml
6. docs/00_governance/SOURCE_REGISTRY.md
7. docs/00_governance/DOC_PLACEMENT_STANDARD.md
8. docs/00_governance/DUPLICATE_DOC_LEDGER.md
```

## 2. 当前阶段摘要

```text
DOC-GOV-002 = 当前 docs 入口、索引、README 与历史层归属治理。
DOC-GOV-001 = completed / historical governance。
G38 / G37S / G37 = 当前仓库文档中存在的最新工程证据链。
G36 = 较早 runtime architecture / save profile 工程证据。
```

这些阶段不在本文件中新增玩法规则，不声明 gameplay runtime PASS 或 manual playtest PASS。

## 3. 一级目录职责

| 目录 | 职责 | 新增规则 |
| --- | --- | --- |
| `00_governance/` | 文档治理、来源、生命周期、重复台账、落位标准 | 允许新增治理文档 |
| `10_current/` | 当前状态、下一步、能力矩阵 | 只放当前摘要，不复制完整历史 |
| `20_product/` | 产品 / 工程契约和内容边界 | 新 contract 直接落位 |
| `30_engineering/` | 工程文档入口、ADR、Godot docs 注册 | 工程说明 / ADR / registry 落位 |
| `40_validation/` | 验证索引 | 只维护 `VALIDATION_INDEX.md` |
| `50_stages/` | active / closed 阶段索引 | 只维护阶段索引 |
| `60_interfaces/` | Connection 外部接口与交接登记 | 只登记来源，不复制内容 |
| `70_sources/` | Base Docs / UI reference 外部来源登记 | 只登记来源和历史快照 |
| `90_archive/` | 历史、旧体系和生成报告说明 | 不移动旧文档，仅说明归档候选 |
| `art/` | 美术流程、资产导入和表现层历史证据 | 保留历史；新增 ART 文档需按主题审查 |
| `audits/` | 早期审计记录 | 历史证据；不改写为当前结论 |
| `branch_changes/` | 早期分支变化记录 | 历史证据；不作为当前入口 |
| `bugs/` | 缺陷记录与 backlog | 只记录问题，不直接授权实现 |
| `design/` | 早期设计与工程设计材料 | 历史 / 设计参考 |
| `design_sources/` | G20 历史设计源导入参考 | 不自动同步 Base Docs 当前原件 |
| `handoff/` | 阶段交接原文 | 新 handoff 直接落位，不复制到根目录 |
| `lua_audit/` | Lua 原型审计与迁移参考 | 历史证据，不作为当前 Godot 事实源 |
| `project_governance/` | G20 历史治理证据 | 当前治理入口在 `00_governance/` |
| `route_analysis/` | 路线分析、阶段依赖、系统边界 | 保留路线证据，不替代 current |
| `stage_summaries/` | G10-G19 阶段摘要 | 历史证据 |
| `validation/` | 阶段验证原文 | 新 validation 直接落位，不扩大验证结论 |

## 4. 写入规则

```text
1. 能判断类型时，生成时直接按规范落位。
2. 不长期堆在 docs 根目录。
3. 不复制 Base Docs 正文解决引用问题。
4. 重复内容先登记到 DUPLICATE_DOC_LEDGER.md，不直接删除。
5. 当前入口中文优先；历史英文文档不强制全文翻译。
6. 新 contract / validation / handoff 至少提供中文摘要。
7. 不把旧 validation / handoff 改写成当前事实，只通过索引降级或标注历史状态。
```

## 5. 禁止写入位置

```text
D:\AGAME1\Base Docs
D:\AGAME1\Base Docs_Governance
D:\AGAME1\Base Art
D:\AGAME1\Connection
Godot/GraytailGodot/scripts
Godot/GraytailGodot/scenes
Godot/GraytailGodot/data
Godot/GraytailGodot/project.godot
Godot/GraytailGodot/**/*.uid
Godot/GraytailGodot/**/*.translation
Godot import metadata
```

## 6. 根目录旧文件状态

`docs` 根目录仍保留若干历史文件。DOC-GOV-002 不移动、不删除、不重命名这些文件，只在治理台账中登记状态：

```text
current_entry：仅限 docs/README.md、docs/INDEX.md、docs/10_current/*、docs/00_governance/*。
historical_status：PROJECT_BASELINE.md、ENGINEERING_STATUS.md、MILESTONES.md、REPO_POLICY.md 等旧状态记录。
historical_handoff：NEXT_HANDOFF.md、HANDOFF_TWO_PC*.md 等旧交接记录。
legacy_design：game-design.md、dev-plan.md、ui-layout-implementation-plan.md 等旧设计 / 开发参考。
legacy_ue：UE_FOUNDATION_STATUS.md、UE_REFACTOR_IMPLEMENTATION.md。
legacy_lua：LUA_BASELINE_STATUS.md。
legacy_integration：design-integration-*.md、integration-self-check.md。
deprecated_reference：DOCS_INDEX.md、CODEX_TASKS.md、REFACTOR_ARCHITECTURE.md。
needs_archive_decision：v0.3-progress-assessment.md、v03-balance-port-self-check.md。
```

完整登记以 `docs/00_governance/DUPLICATE_DOC_LEDGER.md` 和 `docs/00_governance/SOURCE_REGISTRY.md` 为准。

## 7. 命名与摘要规则

```text
Gxx_主题_CONTRACT.md
Gxx_主题_VALIDATION.md
HANDOFF_Gxx_主题.md
ARTxx_主题.md
DOC_GOV_xxx_主题.md
README.md
*_INDEX.md
*_REGISTRY.md
```

当前入口中文优先；新 contract / validation / handoff 至少提供中文摘要。历史英文文档不强制全文翻译。旧文件不强制重命名；归档候选不得移动、不得删除，只能在未来治理阶段另行处理。

## 8. 一句话规则

其它路线只产出到仓库 `docs` 的对应分类目录；外部资料只登记来源，不搬运、不覆盖、不反推为当前规则。
