# G18 DeployPrep Foundation Validation

本文件记录 G18-R3 `DeployPrepShell / DeployConfig / RunStartConfig foundation` 的静态验证边界。

## Scope

G18-R3 只建立出发探索准备页的最小 foundation：

- `DeployPrepShell` 作为 AppShell deploy route 的页面壳层。
- 五个一级 tab：地图、仓库、申领、出勤配置、作业许可。
- 每个 tab 只显示 placeholder / boundary text。
- 右侧显示摘要、配置、效果、风险四段占位。
- `DeployConfig` / `RunStartConfig` 只作为 public `Dictionary` helper / DTO。
- `开始探索` 只生成 preview / `deploy_start_intent`，不启动 RunScene。
- `继续探索` 和 `放弃探索` 只保留 disabled / placeholder 入口。

## Non-Goals

G18-R3 不实现完整出发探索，不生成真实地图，不实现真实仓库、申领、作业许可、保险、托运、本局结算报告、历史战绩、长期系统、抽奖、MetaProgress 或 Deploy persistence。

G18-R3 不修改 `run_scene.gd`、CommandBus、RunContext、Encounter / Combat 规则、`project.godot`、`.tscn`、资源、字体、导入产物、`.uid` 或 `.translation`。

## Static Validation Commands

Recommended validation from repository root:

```powershell
git diff --stat
git diff --check
git status --short
git diff --name-only

rg -n "CommandBus\\.dispatch|command_bus\\.dispatch|RunContext|Encounter|Combat|fight_current_enemy|fight_enemy|_show_run_screen|start_standard|start_tutorial" Godot/GraytailGodot/scripts/ui/deploy_prep Godot/GraytailGodot/scripts/ui/app_shell

rg -n "DeployConfig|RunStartConfig|DeployPrepShell|DeployPrepModel|DeployTabModel|RunPresenceSnapshot|deploy_start_intent|history_metadata|config_version" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs

rg -n "project.godot|\\.tscn|\\.uid|\\.translation" .
```

## Acceptance Notes

- Deploy prep UI must not dispatch CommandBus or call legacy run-start paths.
- Deploy prep UI must not read private run rule state.
- `DeployConfig` must remain a public dictionary helper, not a Node, Resource, save object, or UI control wrapper.
- History metadata is only an opening-config summary for later SettlementAdapter / report work.
- Godot/editor/game/import was not run in G18-R3.
- This record does not claim parser PASS, complete gameplay runtime PASS, or manual playtest PASS.
- G18 is not closeout in R3; later acceptance / smoke / closeout requires separate authorization.
