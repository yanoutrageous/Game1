# Game1 Docs

本目录是当前仓库文档入口。I1 已以提交态 full/head 39/39、Git 交付和远端 quick 成功关闭为 `PASS_WITH_NOTES`；I0、ART21 及其前后历史 validation / handoff / closeout 保留原文，不被当前摘要重写。

## 第一读取顺序

1. `docs/README.md`
2. `docs/INDEX.md`
3. `docs/10_current/CURRENT_STATE.md`
4. `docs/10_current/CAPABILITY_MATRIX.yaml`
5. `docs/10_current/NEXT_ACTION.md`

## 当前基线口径

- 最新闭合非美术基线：I1。
- 项目级最新闭合美术阶段：ART21 主菜单场景重构。
- ART23：较晚且已验收的页面/UI 运行证据切片，可用于具体页面回归，但不提升为项目级 art-stage authority。
- ART24R2：`FAIL (24/61 PASS)` 后封存的历史美术尝试。
- I1：当前最新闭合的跨程序、美术、验证与治理基线，状态 `CLOSED / PASS_WITH_NOTES`；当前无自动授权的后继阶段。

## 目录职责

| 目录 | 职责 |
| --- | --- |
| `00_governance/` | 当前治理、路径、来源、生命周期、重复和编码规则 |
| `10_current/` | 当前事实、能力、评估、下一步和未完成系统 |
| `20_product/` | 产品与阶段契约 |
| `30_engineering/` | 工程、架构、Godot registry 与操作手册 |
| `40_validation/` | 当前验证索引 |
| `50_stages/` | active / closed 阶段索引 |
| `validation/` | 阶段验证原文 |
| `handoff/` | 阶段交接原文 |
| `art/` | 美术契约、审计、关闭和证据 |
| `60_interfaces/`、`70_sources/` | 外部协作和来源登记 |
| `90_archive/` | 历史与旧入口说明 |

## I1 直接入口

| 类型 | 文档 |
| --- | --- |
| 契约 | `docs/20_product/I1_INCREMENTAL_DEVELOPMENT_BASELINE_CONTRACT.md` |
| 评估 | `docs/10_current/I1_BASELINE_ASSESSMENT.md` |
| 架构 | `docs/30_engineering/architecture/I1_ARCHITECTURE_BASELINE.md` |
| 开发/预览/验证手册 | `docs/30_engineering/godot/I1_DEVELOPMENT_PREVIEW_VALIDATION_RUNBOOK.md` |
| validation | `docs/validation/I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md` |
| handoff | `docs/handoff/HANDOFF_I1_INCREMENTAL_DEVELOPMENT_BASELINE.md` |

## 规则

- 路径由 `git rev-parse --show-toplevel` 解析，不绑定盘符。
- 当前机器 `E:\Godot` 只作为本地 Godot 观测/命令示例，跨机器由 I1 runner 解析并验证。
- 新长期文档先按 `docs/00_governance/DOC_PLACEMENT_STANDARD.md` 落位。
- 旧评估在阶段关闭后冻结；新事实写入当前摘要或新的 approved assessment。
- 自动化、capture、人工、性能、CI 与发布证据必须分别声明，不得相互替代。
