# Handoff G18 DeployPrep Foundation

## 阶段事实

- 阶段：G18 DeployPrepShell / DeployConfig / RunStartConfig Foundation
- 分支：`godot/g18-deploy-prep-foundation`
- 基线 main：`eeffe5800864c05f8b000e406609fa7ca3323cb5 docs: mark G17 merged to main`
- G18-R3 实现提交：`59ea57caf1baa977e727da2697cac014cbd7429e feat(godot): add deploy prep shell foundation`
- G18-R4 状态：验收通过，Godot headless project-load/parser smoke PASS，docs-only closeout 已完成在当前分支。
- G18 是否合并 main：否。
- G19 是否启动：否。

## 完成内容

G18 建立了出发探索 / 出勤准备的最小 foundation：

- `DeployPrepShell` 接入 AppShell 的 deploy route。
- 五个一级 tab：地图、仓库、申领、出勤配置、作业许可。
- 每个 tab 当前仅为 placeholder / boundary text。
- 右侧摘要显示 summary / config / effect / risk 占位信息。
- `DeployConfig` / `RunStartConfig` 为 public `Dictionary` helper / DTO。
- 开始探索按钮只生成 preview / `deploy_start_intent`，不启动 RunScene。
- 继续探索 / 放弃探索仍为 disabled / placeholder。

## 明确未完成

G18 不代表完整出发探索，不实现真实地图、仓库、申领、作业许可、保险、托运、本局结算报告、历史战绩、长期系统、抽奖、MetaProgress、Deploy persistence 或完整 gameplay runtime PASS。

G18 未修改 `run_scene.gd`，未修改 G15/G16 encounter/combat 规则语义，未修改 CommandBus、RunContext、project settings、场景、资源、字体、导入产物、`.uid` 或 `.translation`。

## 验证记录

- 静态验收确认 diff 限于 G18 目标范围。
- `DeployPrepShell` 不 dispatch CommandBus，不读取 RunContext / Encounter / Combat / Ledger / TruthMap。
- `DeployConfig` 是 RefCounted public helper，不包含 Node / Resource / RunContext / UI 控件 / 存档对象引用。
- Godot headless project-load/parser smoke PASS。
- Smoke 前后 `git status --short` 为空，未产生副作用 dirty。
- 该 smoke 不是完整 gameplay runtime PASS，也不是 manual playtest PASS。

## 下一步建议

下一步应进入 main 合并前决策。若合并，应只做 fast-forward/merge 决策与必要 post-merge 文档校准；不要在 G18 分支继续追加新功能。G19 不应启动，除非用户另行明确授权。

## 安全边界

- 不修改 Base Docs。
- 不修改旧 UE/Game.git。
- 不修改 `lua-prototype-main`。
- 不触碰保护性 stash。
- 不 force push。
- 不 pull / rebase / reset / clean / stash。
- 不把 parser smoke 写成完整 gameplay runtime PASS 或 manual playtest PASS。