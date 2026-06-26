# Game1 Docs

文档状态：当前文档树入口
适用范围：仓库 `docs` 阅读顺序、目录职责、写入边界、后续 CodeX 文档落位
最后更新：2026/06/26

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

## 2. 目录职责

| 目录 | 职责 |
| --- | --- |
| `00_governance/` | 文档治理、来源、生命周期、重复台账、落位标准 |
| `10_current/` | 当前状态、下一步、能力矩阵 |
| `20_product/` | 产品 / 工程契约和内容边界 |
| `30_engineering/` | 工程文档入口、ADR、Godot docs 注册 |
| `40_validation/` | 验证索引 |
| `50_stages/` | active / closed 阶段索引 |
| `60_interfaces/` | Connection 外部接口与交接登记 |
| `70_sources/` | Base Docs / UI reference 外部来源登记 |
| `90_archive/` | 历史、旧体系和生成报告说明 |
| `validation/` | 阶段验证原文 |
| `handoff/` | 阶段 handoff 原文 |
| `project_governance/` | G20 历史治理证据 |
| `design_sources/` | G20 历史设计源导入参考 |

## 3. 写入规则

```text
1. 新增文档必须按类型直接落位。
2. 不把新文档长期堆在 docs 根目录。
3. 当前入口中文优先。
4. 历史英文文档不强制全文翻译。
5. 当前 contract / validation / handoff 至少保留中文摘要。
6. 重复文档不删除，先登记到 DUPLICATE_DOC_LEDGER.md。
7. validation / handoff 原文保留原位，通过索引指向。
```

## 4. 禁止写入位置

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
```

## 5. 外部来源说明

- `Base Docs` 是用户注入内容 / 外部策划原件 / 个人留档，不参与仓库去重。
- `Base Docs_Governance` 是外部治理快照区，不替代当前仓库事实源。
- `Connection` 是外部并行交接区，不复制内容入库。
- UI 图片只作为确定图、示例图或问题截图登记，不作为规则权威。
