# Game1 Docs

本目录是当前仓库文档入口。I4 是当前用户已授权的 `ACTIVE` 生产交互收敛阶段；
I3R 保留为被 I4 接管前的历史机器/静态证据。ART21 仍是项目级最新闭合美术阶段，
ART23 仍只提供较晚且有范围的页面/UI 验收证据。

## 第一读取顺序

1. docs/50_stages/active/STAGE_INDEX.md
2. docs/10_current/CURRENT_STATE.md
3. docs/10_current/NEXT_ACTION.md
4. docs/20_product/I4_PRODUCTION_INTERACTION_CONVERGENCE_CONTRACT.md
5. docs/00_governance/I4_EXECUTION_LEDGER.md
6. docs/00_governance/I4_REQUIREMENT_MATRIX.md
7. docs/40_validation/VALIDATION_INDEX.md
8. tools/i4/README.md

`docs/INDEX.md` 提供全目录导航；I3 与 I1 validation/handoff 保留为冻结历史证据。

## 当前基线口径

- I4：当前活动阶段；入口为
  `4127bd27a05b75cb5e3071cf6dc87d9287f679a9`，当前状态为
  `ACTIVE / PLAN_AUDIT`。
- I3R：96/96 worktree full、132/125/12 矩阵与 269/269 静态复核保持历史证据；
  用户后续生产反馈的字体、遮挡、摘要、数量和任务链问题由 I4 接管。
- I3：冻结历史，入口为 `09aaafe283aa2e4c2f30708c5f88b89ebf7753eb`。
- I2：最新闭合非美术基线；其 validation/handoff 不因后续返工而改写。
- I1：更早闭合非美术基线；其 validation/handoff 继续保留为历史证据。
- ART21：项目级最新闭合美术阶段。
- ART23：较晚的页面/UI 运行证据切片，不提升为项目级美术阶段权威。
- ART24R2：FAIL（24/61 PASS）后的失败封存，不是合格美术基线。

## 当前 I4 入口

| 类型 | 文档 |
| --- | --- |
| 活动阶段 | docs/50_stages/active/STAGE_INDEX.md |
| 契约 | docs/20_product/I4_PRODUCTION_INTERACTION_CONVERGENCE_CONTRACT.md |
| 执行台账 | docs/00_governance/I4_EXECUTION_LEDGER.md |
| 需求矩阵 | docs/00_governance/I4_REQUIREMENT_MATRIX.md |
| 验证索引 | docs/40_validation/VALIDATION_INDEX.md |
| 操作说明 | tools/i4/README.md |

## I3 历史证据入口

| 类型 | 文档 |
| --- | --- |
| 契约 | docs/20_product/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_CONTRACT.md |
| 切片门账 | docs/00_governance/I3_SLICE_GATE_LEDGER.md |
| 用户反馈处置 | docs/00_governance/I3_USER_FEEDBACK_DISPOSITION_MATRIX.md |
| validation | docs/validation/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md |
| handoff | docs/handoff/HANDOFF_I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION.md |
| Base 审计 | docs/00_governance/I3_BASE_RETENTION_AND_DEDUP_AUDIT.md |
| 原始策划关系 | docs/70_sources/base_docs/I3_ORIGINAL_PLANNING_RELATIONSHIP_REGISTRY.md |

I3 历史 worktree full 为 75/75 PASS，报告 SHA-256 为
5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D；冻结证据见 I3
validation/handoff。它不得替代 I3R 当前验证；I3R 的候选提交 exact-head/full 与
push 后远端 SHA 由本次最终交付结果提供，仓库文档不预写未知值。

## 目录职责

| 目录 | 职责 |
| --- | --- |
| 00_governance/ | 当前治理、来源、去重、生命周期与切片账本 |
| 10_current/ | 当前事实、能力、范围、下一步和未完成系统 |
| 20_product/ | 产品与阶段契约 |
| 30_engineering/ | 工程、架构、Godot registry 与操作手册 |
| 40_validation/ | 当前验证索引 |
| 50_stages/ | active / closed 阶段索引 |
| validation/ | 阶段验证原文 |
| handoff/ | 阶段交接原文 |
| art/ | 美术契约、审计、关闭和证据 |
| 60_interfaces/、70_sources/ | 外部协作和来源登记 |
| 90_archive/ | 历史与旧入口说明 |

## 规则

- 路径由 git rev-parse --show-toplevel 解析，不绑定盘符。
- `E:\Godot` 与 `E:\UE\Game` 仅为本机观测；传入 `-UERoot` 的值必须是可解析且
  精确匹配的 UE Git 根。UE 是只读参考，不是 Godot 架构、代码、性能或素材许可权威。
- 新长期文档先按 docs/00_governance/DOC_PLACEMENT_STANDARD.md 落位。
- static、headless、rendered、manual、performance、CI、export 和 release 分别声明。
- Base 的 25 份原始策划与 1407 个 art/draw 来源已建立可追溯基线；Base art 仍为
  not_admitted，不能因进入 Git 自动成为运行时素材。
- I3 未验收最终审美、动画/音频手感、目标设备 GPU/FPS、长局、导出或发布；退出
  cleanup 分类仍是明确债务，六次 production 均为 18-resource 子集。
