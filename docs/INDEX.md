# Game1 Docs Index

文档状态：I3 已关闭的当前导航；无 active stage。
最后更新：2026-07-23

## 第一入口

1. docs/README.md
2. docs/INDEX.md
3. docs/50_stages/closed/STAGE_INDEX.md
4. docs/10_current/CURRENT_STATE.md
5. docs/validation/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md
6. docs/handoff/HANDOFF_I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION.md
7. docs/10_current/CAPABILITY_MATRIX.yaml
8. docs/10_current/NEXT_ACTION.md

## 当前权威材料

| 类型 | 文档 | 状态 |
| --- | --- | --- |
| 当前事实 | docs/10_current/CURRENT_STATE.md | current |
| 当前能力 | docs/10_current/CAPABILITY_MATRIX.yaml | current |
| 当前范围 | docs/10_current/AUDIT_SCOPE.md | current |
| 当前未完成 | docs/10_current/KNOWN_UNFINISHED_SYSTEMS.md | current |
| Active stages | docs/50_stages/active/STAGE_INDEX.md | NO_ACTIVE_STAGE |
| Closed stages | docs/50_stages/closed/STAGE_INDEX.md | I3 latest non-art |
| I3 契约 | docs/20_product/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_CONTRACT.md | closed contract |
| I3 切片门账 | docs/00_governance/I3_SLICE_GATE_LEDGER.md | closeout gate authority |
| I3 用户反馈处置 | docs/00_governance/I3_USER_FEEDBACK_DISPOSITION_MATRIX.md | frozen closeout disposition |
| I3 validation | docs/validation/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md | CLOSED / PASS_WITH_NOTES |
| I3 handoff | docs/handoff/HANDOFF_I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION.md | CLOSED / PASS_WITH_NOTES |
| I3 Base 审计 | docs/00_governance/I3_BASE_RETENTION_AND_DEDUP_AUDIT.md | accepted Base gate |
| 原始策划关系 | docs/70_sources/base_docs/I3_ORIGINAL_PLANNING_RELATIONSHIP_REGISTRY.md | 25 originals |
| Runtime 晋级登记 | docs/00_governance/I3_RUNTIME_ASSET_PROMOTION_REGISTRY.csv | admission boundary |
| 来源注册 | docs/00_governance/SOURCE_REGISTRY.md | current |
| 验证索引 | docs/40_validation/VALIDATION_INDEX.md | current |

## 当前事实

- I3 是最新闭合非美术基线；I2、I1 和更早阶段保留为历史继承证据。
- ART21 仍是项目级最新闭合美术阶段；ART23 只是较晚的页面/UI 范围证据。
- 最终 worktree full 为 75/75 PASS；首次 quick/full 失败与补救链见 I3 validation
  原文，不在导航重复。
- I3 的三条生产 runner 各以 headless/rendered 运行一次，共 47 张 1280×720 PNG 和
  6 组 JSON/CSV，覆盖成功、失败、放弃、满包替换、保存重试和空间转场。
- Base 保留 25 份原名原字节原始策划；1407 个 art/draw member 按 SHA 折叠为
  1012 个对象与 395 个 alias。该结论不等于运行时准入。

## 解释规则

- exact-head/full 与 push 后远端 SHA 一致是关闭的外部交付条件；任一失败都使 I3
  关闭无效并重新打开 I3.7。未知提交 SHA 不写入候选文档。
- 生产旅程和渲染截图证明覆盖路线、布局与信息闭环，不证明最终审美、音频、动画手感、
  长局或目标设备性能。
- enemy1 低基数 CPU 残余与退出 cleanup 诊断均保留为 PASS_WITH_NOTES 内容；六次 production 属于 18-resource 子集，全量 runner 以 manifest 分类为准。
- Deploy 地图保持出发探索同页双栏，禁止回退为区域到难度的分步页面。
- 当前没有 active stage；I3 关闭不自动授权 I4、ART22 或其他后继工作。
