# DOC-GOV-001 Document Placement Standard

文档状态：当前治理规则
适用范围：仓库文档入口、阶段完成文档、重复文档状态、外部来源边界
最后更新：2026/06/26

本文件只规定仓库文档如何落位、引用和标记状态；不新增玩法规则，不替代产品契约、验证记录、Base Docs 原件或用户确认。

## 1. 权威入口

| 区域 | 当前定位 | 写入规则 |
| --- | --- | --- |
| `D:\AGAME1\_repo_cache\Game1_work\docs` | 当前仓库文档事实入口 | 新增仓库文档默认直接按类型落位 |
| `D:\AGAME1\_repo_cache\Game1_work\docs\README.md` | 文档树第一阅读入口 | 说明目录职责和写入边界 |
| `D:\AGAME1\_repo_cache\Game1_work\docs\INDEX.md` | 当前索引入口 | 保持短索引，不长期堆叠完整阶段正文 |
| `D:\AGAME1\_repo_cache\Game1_work\docs\10_current` | 当前事实摘要和下一步 | 只记录当前状态、下一 gate、能力状态 |
| `D:\AGAME1\_repo_cache\Game1_work\docs\00_governance` | 当前文档治理入口 | 保存来源、生命周期、重复台账、落位标准 |

## 2. 外部来源边界

```text
Base Docs = 用户注入内容 / 外部策划原件 / 个人阅读与留档区。
Base Docs_Governance = Base Docs 的非破坏式整理副本区 / 索引区 / 历史快照区。
Connection = 外部并行交接区。
Godot/GraytailGodot/docs = Godot 工程历史 / 环境证据区。
```

- `D:\AGAME1\Base Docs` 不参与仓库去重，不由仓库覆盖，不移动、不重命名、不删除、不改写正文。
- `D:\AGAME1\Base Docs_Governance` 不替代当前仓库事实源；其中 `06_工程仓库docs参考` 是历史参考快照。
- `D:\AGAME1\Connection` 只作为外部交接资料读取，不复制内容入库，不写入 Git，不导入 Godot。
- `Godot/GraytailGodot/docs` 只保留工程历史和环境证据；当前阶段治理入口在仓库 `docs`。

## 3. 新增文档落位规则

| 文档类型 | 落位 |
| --- | --- |
| 当前入口 / 当前状态 | `docs/10_current/` |
| 文档治理规则、来源、重复台账 | `docs/00_governance/` |
| 产品契约 / 内容边界 | `docs/20_product/` |
| 工程说明、ADR、Godot 文档注册 | `docs/30_engineering/` |
| 验证索引 | `docs/40_validation/` |
| 阶段索引 | `docs/50_stages/active/` 或 `docs/50_stages/closed/` |
| Connection 外部接口登记 | `docs/60_interfaces/connection/` |
| Base Docs / UI reference 来源登记 | `docs/70_sources/` |
| 历史说明 / 生成报告 / 旧体系入口 | `docs/90_archive/` |
| 阶段验证原文 | `docs/validation/` |
| 阶段 handoff 原文 | `docs/handoff/` |

仅来源不明、外部导入待判定或需要用户确认归属的材料可进入临时 inbox；不得长期堆积。当前仓库未设置常驻 inbox 时，不新建 inbox。

## 4. 阶段完成文档规则

每个阶段完成后至少保留：

```text
1. product / contract 文档，若该阶段产生产品或工程契约。
2. validation 文档，记录实际验证命令、结果和边界。
3. handoff 文档，记录下一 gate、未实现内容和禁止误读项。
4. stage index 记录，标明 active / closed / historical。
```

原始 validation / handoff 不搬迁、不覆盖；通过 `docs/40_validation/VALIDATION_INDEX.md` 和 `docs/50_stages/*/STAGE_INDEX.md` 指向。

## 5. 重复文档处理规则

```text
1. 重复文档不删除，先登记状态。
2. 当前入口中文优先。
3. 历史英文文档不强制全文翻译。
4. 当前 contract / validation / handoff 至少应有中文摘要。
5. 旧入口可追加短状态说明，但不全文重写历史正文。
6. 历史快照只作证据，不作为当前事实源。
```

## 6. 禁止项

```text
1. 不从 UI 图片反推规则。
2. 不从工程临时实现反推策划定案。
3. 不把 Base Docs_Governance 快照写成当前事实源。
4. 不把历史文档改写成新规则。
5. 不新增玩法规则。
6. 不把未确认内容写成定案。
```
