# Game1 Docs

本目录是当前仓库文档入口。I3 已关闭为 CLOSED / PASS_WITH_NOTES，是最新闭合非美术
基线；当前没有 active stage，也没有自动授权的后继阶段。ART21 仍是项目级最新闭合
美术阶段，ART23 仍只提供较晚且有范围的页面/UI 验收证据。

## 第一读取顺序

1. docs/README.md
2. docs/INDEX.md
3. docs/50_stages/closed/STAGE_INDEX.md
4. docs/10_current/CURRENT_STATE.md
5. docs/validation/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md
6. docs/handoff/HANDOFF_I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION.md
7. docs/10_current/CAPABILITY_MATRIX.yaml
8. docs/10_current/NEXT_ACTION.md

## 当前基线口径

- I3：最新闭合非美术基线，CLOSED / PASS_WITH_NOTES。
- I2：前序闭合非美术基线；其历史 validation/handoff 不因 I3 关闭而改写。
- ART21：项目级最新闭合美术阶段。
- ART23：较晚的页面/UI 运行证据切片，不提升为项目级美术阶段权威。
- ART24R2：FAIL（24/61 PASS）后的失败封存，不是合格美术基线。

## I3 收口入口

| 类型 | 文档 |
| --- | --- |
| 契约 | docs/20_product/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_CONTRACT.md |
| 切片门账 | docs/00_governance/I3_SLICE_GATE_LEDGER.md |
| 用户反馈处置 | docs/00_governance/I3_USER_FEEDBACK_DISPOSITION_MATRIX.md |
| validation | docs/validation/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md |
| handoff | docs/handoff/HANDOFF_I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION.md |
| Base 审计 | docs/00_governance/I3_BASE_RETENTION_AND_DEDUP_AUDIT.md |
| 原始策划关系 | docs/70_sources/base_docs/I3_ORIGINAL_PLANNING_RELATIONSHIP_REGISTRY.md |

I3 最终 worktree full 为 75/75 PASS，报告 SHA-256 为
5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D。exact-head/full
与 push 后远端 SHA 一致是外部交付条件；交付记录若失败，本次关闭无效。仓库文档不
预写未知候选提交 SHA。

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
- E:\Godot 与 E:\UE 仅为本机观测；UE 是只读参考，不是 Godot 架构、代码、性能或
  素材许可权威。
- 新长期文档先按 docs/00_governance/DOC_PLACEMENT_STANDARD.md 落位。
- static、headless、rendered、manual、performance、CI、export 和 release 分别声明。
- Base 的 25 份原始策划与 1407 个 art/draw 来源已建立可追溯基线；Base art 仍为
  not_admitted，不能因进入 Git 自动成为运行时素材。
- I3 未验收最终审美、动画/音频手感、目标设备 GPU/FPS、长局、导出或发布；退出
  cleanup 分类仍是明确债务，六次 production 均为 18-resource 子集。
