# Active Stage Index

文档状态：I2 active stage 入口；实现尚未声明。
最后更新：2026-07-22

## 当前阶段

| Item | Current fact |
| --- | --- |
| Stage | I2 Player-experience Refactor and Incremental Baseline |
| Status | `ACTIVE / implementation not yet claimed` |
| Stage type | user-authorized cross-line integration baseline exception |
| Active repo | `git rev-parse --show-toplevel` |
| Observed worktree | `E:\AGAME1\.tmp\worktrees\i2` |
| Observed branch | `codex/i2-player-experience-refactor` |
| Entry HEAD | `b77132b9de655b36f71c930a35a191c383b55522` |
| Entry tree | `1d26f1415851755f1a8cc57f4804dfb12d9cea4d` |
| Entry regression | `full/head 39/39 PASS`; no I2 capability claim |
| Implementation target | `<active_repo>/Godot/GraytailGodot` |
| Read-only reference | `E:\UE\Game\UE\Graytail` concept/interaction/visual only |
| Latest closed non-art baseline | I1 / `CLOSED / PASS_WITH_NOTES` |
| Latest closed art stage | ART21 |
| Later accepted page/UI evidence | ART23 |
| Current slice | I2.1A/I2.1B foundation and isolated I2.5A ready; I2.0 accepted with notes |
| Runtime slices | I2.1–I2.7 not authorized until their gates pass |

## 阶段目标

在不破坏 I1 权威、保存、结算和快速回归基线的前提下，对主菜单、出发探索、长期系统、局内、特殊房和结果解释进行面向玩家体验的受控重构，使后续新增与修改可以快速生产预览、自动测试、动态复核并附明确操作说明。

I2 是单一阶段。I2.0–I2.7 只是内部切片；任何局部通过不能被写成 I2 已关闭。

## 当前 I2.0

I2.0 只建立：

- pre-execution scope/risk audit；
- refactor/incremental baseline contract；
- exact entry baseline assessment；
- 43 条玩家反馈/跨域判断追踪矩阵；
- target architecture/migration plan；
- validation/preview/manual review plan；
- slice gate ledger 与当前入口。

I2.0 不修改 Godot、资产、项目设置、tools、validation 或 handoff，不提升 capability。

## 冻结约束

- Godot 是实现目标；UE 只读借鉴概念，拒绝 UE 架构、烤字固定布局与未知许可素材。
- Deploy 地图保持同一页面：左地图名称+比例/规模，右难度+详情；保留 8 个现有 ID，不做 region→difficulty 分步页。
- `RunStateMachine`、`RunAssetLedger`、terminal settlement、`SaveAdapter`、失败保全和幂等继承 I1。
- 素材先复用已登记 Godot 内容，再审计外部来源；只有确认缺口后才走批准的生成门。
- 性能必须测真实工作负载；combat refresh 微基准不能代表 FPS。
- 键鼠/手柄/焦点、reduced motion/颜色冗余、长文本/本地化和生命周期/保存失败进入相关切片验收。

## 当前门与下一步

| Gate | Status |
| --- | --- |
| I2 entry exact full/head | PASS 39/39 at `b77132b` |
| I2.0 docs self-check | `ACCEPTED_WITH_NOTES`; allowed paths / 43 IDs / refs / UTF-8 / YAML basic / diff / static PASS；quick/worktree 21/21 PASS |
| I2.1 scope/risk/paths | READY for exact I2.1A and I2.1B foundation allowlists; integration remains gated |
| I2.5 asset binding | READY only for exact I2.5A existing-result/protocol/item binding allowlist |
| I2 runtime implementation | NOT_STARTED |
| I2 visual/manual/performance acceptance | NOT_RUN |
| I2 validation/handoff | NOT_CREATED |
| I2 capability promotion | NONE |

下一步是执行互不重叠的 I2.1A、I2.1B foundation 与 I2.5A，主审统一登记 runner 并完成交叉回归；任何 AppShell/Run 设置集成或其他局内改动仍需新门。详细状态见 `docs/00_governance/I2_SLICE_GATE_LEDGER.md`。

## 进入材料

- `docs/00_governance/I2_PRE_EXECUTION_SCOPE_RISK_AUDIT.md`
- `docs/20_product/I2_REFACTOR_DIRECTION_AND_INCREMENTAL_BASELINE_CONTRACT.md`
- `docs/10_current/I2_PRE_EXECUTION_BASELINE_ASSESSMENT.md`
- `docs/20_product/I2_PLAYER_FEEDBACK_TRACEABILITY_MATRIX.md`
- `docs/30_engineering/architecture/I2_TARGET_ARCHITECTURE_AND_MIGRATION_PLAN.md`
- `docs/30_engineering/godot/I2_VALIDATION_PREVIEW_AND_MANUAL_REVIEW_PLAN.md`
- `docs/00_governance/I2_SLICE_GATE_LEDGER.md`
