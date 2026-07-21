# Audit Entrypoint

文档状态：I2 当前审计入口；阶段 active，运行时实现尚未声明。
最后更新：2026-07-22

## 读取顺序

1. `docs/README.md`
2. `docs/INDEX.md`
3. `docs/50_stages/active/STAGE_INDEX.md`
4. `docs/10_current/CURRENT_STATE.md`
5. `docs/00_governance/I2_PRE_EXECUTION_SCOPE_RISK_AUDIT.md`
6. `docs/20_product/I2_REFACTOR_DIRECTION_AND_INCREMENTAL_BASELINE_CONTRACT.md`
7. `docs/20_product/I2_PLAYER_FEEDBACK_TRACEABILITY_MATRIX.md`
8. `docs/00_governance/I2_SLICE_GATE_LEDGER.md`
9. `docs/30_engineering/architecture/I2_TARGET_ARCHITECTURE_AND_MIGRATION_PLAN.md`
10. `docs/30_engineering/godot/I2_VALIDATION_PREVIEW_AND_MANUAL_REVIEW_PLAN.md`
11. `docs/10_current/CAPABILITY_MATRIX.yaml`
12. `docs/10_current/NEXT_ACTION.md`

I1 继承材料：

- 契约：`docs/20_product/I1_INCREMENTAL_DEVELOPMENT_BASELINE_CONTRACT.md`
- 评估：`docs/10_current/I1_BASELINE_ASSESSMENT.md`
- 架构：`docs/30_engineering/architecture/I1_ARCHITECTURE_BASELINE.md`
- 操作：`docs/30_engineering/godot/I1_DEVELOPMENT_PREVIEW_VALIDATION_RUNBOOK.md`
- 验证：`docs/validation/I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md`
- 交接：`docs/handoff/HANDOFF_I1_INCREMENTAL_DEVELOPMENT_BASELINE.md`

## 当前审计起点

```text
active_repo: git rev-parse --show-toplevel
observed_worktree: E:\AGAME1\.tmp\worktrees\i2
observed_branch: codex/i2-player-experience-refactor
entry_head: b77132b9de655b36f71c930a35a191c383b55522
entry_tree: 1d26f1415851755f1a8cc57f4804dfb12d9cea4d
observed_base_ref: origin/main at b77132b9de655b36f71c930a35a191c383b55522
stage: I2 ACTIVE / implementation not yet claimed
current_slice: I2.1A/I2.1B foundation and isolated I2.5A ready; I2.0 accepted with notes
latest_closed_non_art_baseline: I1
latest_closed_art_stage: ART21
later_accepted_page_ui_evidence: ART23
I2_runtime_capability_delta: none claimed
```

## I2 起点证据

```text
full/head report: E:\AGAME1\.tmp\worktrees\i2\.tmp\i1\20260721T193513816Z_48329748\report.json
report sha256: 2072F1DBD067C607E82220F06DEFE15F410ED68807BFAA4EF36B5202007167E8
result: 39/39 PASS; 17 plain PASS; 22 cleanup-classified; 0 blocking
duration: 254980 ms

preview report: E:\AGAME1\.tmp\i1\20260721T181135224Z_4a0a6ca0\preview_report.json
preview sha256: 575113D718A4E1D399FA0EB4EA6C1BE0C0E38B881348C134450E6FF43E77F9FF
result: 27/27 captured; PASS_WITH_VISUAL_REVIEW_REQUIRED; visual_acceptance=NOT_RUN
```

两个报告都保持未版本化。full/head 证明进入回归基线；preview 证明可生成对照图。它们都不证明 I2 实现、动态手感、输入、真实性能或最终视觉。

## 当前审计顺序

1. 动态解析 Git root，核对 branch、HEAD、origin、dirty、staged、untracked、stash 和其他 worktree；禁止根据盘符选择活动仓库。
2. 核对当前切片在 `I2_SLICE_GATE_LEDGER.md` 的状态、反馈 ID、allowed/protected paths、产品决策、回退和停止条件。
3. 以当前 Godot 代码/运行事实优先，核对用户观察；UE 只读概念参考不能覆盖 Godot 事实和产品冻结约束。
4. 核对 Deploy 地图仍在同一页面：左地图名称/比例规模，右难度/详情；现有 8 ID 不变、没有 region→difficulty 分步 route。
5. 核对 I1 phase/ledger/terminal settlement/save/idempotency 不变量和 UI/动画非权威边界。
6. 按切片运行 targeted + quick/core/ui/full，并分别复核 CAP、DYN、INPUT、PERF、FAIL、ASSET、TEXT；未运行项写 `NOT_RUN`。
7. 资源/scene/project/metadata 变更必须复核 source/license/hash/manifest/import 和精确暂存清单。
8. 对比另一个主工作树的受保护 `project.godot` 与七个 `.translation`，确认 I2 没有吸收、清理或覆盖它们。
9. 切片 review 只更新门账，不创建 I2 validation/handoff；仅 I2.7 综合审计可进入单一 closeout。

## I2.0 已接受边界

I2.0 只更新启动审计、契约、起点评估、追踪矩阵、目标架构、验证计划、门账和必要当前入口，已通过独立 claim review 与 quick/worktree 21/21。它没有修改 Godot、tools、assets、validation、handoff、closed stage index 或外部 source pack，也没有 capability promotion。后续运行切片仍须先在门账冻结自己的精确边界。

## 声明边界

- I2 当前 `ACTIVE` 不等于程序、美术、交互或性能已改善。
- I1 仍是最新闭合非美术基线；ART21 仍是项目级最新闭合美术阶段。
- Godot 是实现目标；`E:\UE` 只借语义/交互/视觉概念，不移植架构、烤字固定布局或未知许可素材。
- 自动化、截图、动态人工、输入/焦点、性能、来源许可、CI、导出/发布证据不能互相替代。
- combat refresh 微基准不是 FPS；production capture 成功不是视觉 PASS；worktree PASS 不是 exact HEAD PASS。
- 未知 dirty、语义 `project.godot`、staged metadata 或范围外写入是阻断项，必须回到风险审计。
