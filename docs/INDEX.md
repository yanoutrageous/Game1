# Game1 Docs Index

文档状态：I4 `ACTIVE` 当前导航；I3R 作为被 I4 接管前的历史机器证据保留。
最后更新：2026-07-30

## 第一入口

1. docs/50_stages/active/STAGE_INDEX.md
2. docs/10_current/CURRENT_STATE.md
3. docs/10_current/NEXT_ACTION.md
4. docs/20_product/I4_PRODUCTION_INTERACTION_CONVERGENCE_CONTRACT.md
5. docs/00_governance/I4_EXECUTION_LEDGER.md
6. docs/00_governance/I4_REQUIREMENT_MATRIX.md
7. docs/40_validation/VALIDATION_INDEX.md
8. tools/i4/README.md

## 当前权威材料

| 类型 | 文档 | 状态 |
| --- | --- | --- |
| 当前事实 | docs/10_current/CURRENT_STATE.md | current |
| 当前能力 | docs/10_current/CAPABILITY_MATRIX.yaml | current |
| 当前范围 | docs/10_current/AUDIT_SCOPE.md | current |
| 当前未完成 | docs/10_current/KNOWN_UNFINISHED_SYSTEMS.md | current |
| Active stages | docs/50_stages/active/STAGE_INDEX.md | I4 ACTIVE |
| Closed stages | docs/50_stages/closed/STAGE_INDEX.md | I2 latest closed non-art |
| I4 契约 | docs/20_product/I4_PRODUCTION_INTERACTION_CONVERGENCE_CONTRACT.md | active contract |
| I4 执行台账 | docs/00_governance/I4_EXECUTION_LEDGER.md | active gate authority |
| I4 需求矩阵 | docs/00_governance/I4_REQUIREMENT_MATRIX.md | active requirement status |
| I4 操作说明 | tools/i4/README.md | current runner entry |
| I3R 契约 | docs/20_product/I3R_PLAYER_EXPERIENCE_REWORK_CONTRACT.md | historical superseded contract |
| I3 契约 | docs/20_product/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_CONTRACT.md | historical contract |
| I3 切片门账 | docs/00_governance/I3_SLICE_GATE_LEDGER.md | frozen historical ledger |
| I3 用户反馈处置 | docs/00_governance/I3_USER_FEEDBACK_DISPOSITION_MATRIX.md | frozen historical disposition |
| I3 validation | docs/validation/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md | historical evidence |
| I3 handoff | docs/handoff/HANDOFF_I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION.md | historical evidence |
| I3 Base 审计 | docs/00_governance/I3_BASE_RETENTION_AND_DEDUP_AUDIT.md | accepted Base gate |
| 原始策划关系 | docs/70_sources/base_docs/I3_ORIGINAL_PLANNING_RELATIONSHIP_REGISTRY.md | 25 originals |
| Runtime 晋级登记 | docs/00_governance/I3_RUNTIME_ASSET_PROMOTION_REGISTRY.csv | admission boundary |
| 来源注册 | docs/00_governance/SOURCE_REGISTRY.md | current |
| 验证索引 | docs/40_validation/VALIDATION_INDEX.md | current |

## 当前事实

- I4 是当前 `ACTIVE / PLAN_AUDIT` 阶段，入口为 `4127bd2`；用户已明确授权执行、
  测试、完成审计与 push。
- I3R 最终工作树 full 96/96、132/125/12 矩阵与 269/269 静态复核保持历史证据；
  用户后续生产反馈未接受其字体、遮挡、摘要、数量与任务链体验，这些项目由 I4 接管。
- I3R 实现入口为 `35189aaf524157761d1ab9cdddc39e76baa0d7ca`；I3 历史入口为
  `09aaafe283aa2e4c2f30708c5f88b89ebf7753eb`。I2 是最新闭合非美术基线；I3、
  I1 与更早材料只保留为冻结继承证据。
- 最终状态画廊 12/12、生产预览 132/132、长期系统 125/125 均已生成，
  269/269 张静态图完成 Codex 复核。exact-head 与 Git 远端一致性由本次最终交付结果
  提供；真实设备/控制器/音频、目标 GPU 长局和动态玩家/视觉签收仍待完成。
- ART21 仍是项目级最新闭合美术阶段；ART23 只是较晚的页面/UI 范围证据。
- I3 冻结 worktree full 为 75/75 PASS；首次 quick/full 失败与补救链见 I3 validation
  原文，不在导航重复。
- I3 的三条冻结生产 runner 各以 headless/rendered 运行一次，共 47 张 1280×720 PNG 和
  6 组 JSON/CSV，覆盖成功、失败、放弃、满包替换、保存重试和空间转场。
- I3 Base 冻结记录保留 25 份原名原字节原始策划；1407 个 art/draw member 按 SHA 折叠为
  1012 个对象与 395 个 alias。该结论不等于运行时准入。

## 解释规则

- 同一候选提交的 exact-head/full 与 push 后远端 SHA 一致是关闭外部交付条件；
  工作树 full 不替代该门，未知提交 SHA 不写入候选文档。
- 生产旅程和渲染截图证明覆盖路线、布局与信息闭环，不证明最终审美、音频、动画手感、
  长局或目标设备性能。
- enemy1 低基数 CPU 残余与退出 cleanup 诊断均保留为 PASS_WITH_NOTES 内容；六次 production 属于 18-resource 子集，全量 runner 以 manifest 分类为准。
- Deploy 地图保持出发探索同页双栏，禁止回退为区域到难度的分步页面。
- I4 是当前 active stage；其授权不自动授权新内容、新美术阶段、发布或其他后继工作。
