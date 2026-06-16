# G18 阶段总结

## 阶段目标

G18 目标是 DeployPrepShell / DeployConfig / RunStartConfig Foundation：在 G17 AppShell 上新增出发准备 shell、公开 config preview 和 preview-only deploy start intent。G18 不启动 RunScene，不是真实出发探索。

## 实际完成

- 新增 `DeployPrepShell` foundation。
- 新增 `DeployConfig` / `RunStartConfig` preview helpers。
- 出发准备页包含五个 placeholder tabs：地图、仓库、申领、出勤配置、作业许可。
- 右侧显示 summary/config/effect/risk sections，来源为 public preview data。
- AppShell deploy route 集成到 DeployPrepShell。
- `deploy_start_intent` 仅为 preview，不启动或继续 RunScene。

## 关键提交

- `59ea57caf1baa977e727da2697cac014cbd7429e` `feat(godot): add deploy prep shell foundation`
- `285695cda0141322b0672d65998f3d3f9aa32654` `docs: close G18 deploy prep foundation`
- `0e44c261f399a197d6e6eec277eb51ce72e1ba8c` `docs: mark G18 merged to main`

## 新增系统 / 修改系统

- 新增 DeployPrepShell foundation。
- 新增 public DeployConfig / RunStartConfig preview dictionaries。
- 修改 AppShell deploy route。
- 不 dispatch CommandBus，不读 private run state，不生成真实地图，不读真实 warehouse 数据，不执行 requisition transaction，不应用 work permit rules。

## 验证状态

- `docs/validation/G18_DEPLOY_PREP_FOUNDATION_VALIDATION.md` 记录 boundary、R4 acceptance、Godot headless project-load/parser smoke PASS 和 fast-forward main merge status。
- `Godot headless project-load/parser smoke PASS` 不等于 complete gameplay runtime PASS。
- 未声明 manual playtest PASS。

## 明确未完成

- 未启动或继续 RunScene。
- 未实现真实地图、warehouse/requisition/permit rules、settlement reports/history、long-term systems、lottery、MetaProgress、Deploy persistence。

## 后续承接点

- 后续真实 run-start handoff 需要独立阶段和验证。
- Asset Contract / Warehouse 等资源线不能直接从 G18 placeholder 扩展为真实经济系统。

## 主要风险

- deploy start intent preview 可能被误读成真实出发启动。
- placeholder tabs 可能被误读成 warehouse/requisition/permit 系统已经存在。
- parser smoke 可能被误读成 gameplay runtime PASS。

## 是否已合并 main

是。事实源记录 G18 fast-forward merged to main。

## 对后续路线的影响

G18 在 AppShell 下保留了出发准备的页面位置和 config preview 合同，但刻意不启动 RunScene，为未来 Asset Contract、Warehouse、Permit、真实 run-start 留出独立审计空间。

## 事实来源

- `docs/PROJECT_BASELINE.md`
- `docs/NEXT_HANDOFF.md`
- `docs/ENGINEERING_STATUS.md`
- `docs/MILESTONES.md`
- `docs/validation/G18_DEPLOY_PREP_FOUNDATION_VALIDATION.md`
- `docs/handoff/HANDOFF_G18_DEPLOY_PREP_FOUNDATION.md`
- `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
- Git commit log
