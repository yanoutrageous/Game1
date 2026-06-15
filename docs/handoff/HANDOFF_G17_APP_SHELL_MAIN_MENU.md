# Handoff G17 AppShell / MainMenuShell

## 阶段定位

G17 是 `AppShell / NavigationIntent / PageRouter / MainMenuShell` 基础阶段。它不是完整主菜单实现，不是正式出发探索实现，不是长期系统实现，也不是新玩法阶段。

本阶段在 G16 后的架构方向基线上建立最小顶层应用壳：

- `NavigationIntent`：导航意图字典与读取 helper。
- `PageRouter`：把导航意图映射到页面 route。
- `AppShell`：应用级页面容器与 placeholder route 所有者。
- `MainMenuShell`：只展示主菜单、轻量氛围和入口按钮。
- `MainMenuModel`：静态主菜单 display model。

## 当前事实源

- 仓库：`D:\AGAME1\_repo_cache\Game1_work`
- Remote：`https://github.com/yanoutrageous/Game1.git`
- 分支：`godot/g17-app-shell-main-menu`
- G17-R2 commit：`368a7be5c2fb919db47421a026ddf417df9c1b1c feat(godot): add app shell main menu foundation`
- G17 baseline main：`80c0d0653db0ec486c1b8f97b4787d8107dd2a0f docs: add post-G16 architecture direction baseline`
- G17 branch remains separate from main; no mainline integration was performed in this closeout.
- No G18 work began in this closeout.

## G17-R2 完成内容

- 新增 `Godot/GraytailGodot/scripts/ui/app_shell/navigation_intent.gd`。
- 新增 `Godot/GraytailGodot/scripts/ui/app_shell/page_router.gd`。
- 新增 `Godot/GraytailGodot/scripts/ui/app_shell/app_shell.gd`。
- 新增 `Godot/GraytailGodot/scripts/ui/main_menu/main_menu_model.gd`。
- 新增 `Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd`。
- `run_scene.gd` 只做最小挂接：从 legacy G9 shell 挂载切到 `AppShell`，并保留既有 run flow、CommandBus、modal、Encounter、Combat 行为。
- 出发探索、长期系统、设置仍是 placeholder / legacy route，不是完整功能页。

## G17-R3 验收

只读验收确认：

- diff 范围符合 G17-R2 目标。
- 未修改 `project.godot`。
- 未修改 `.tscn`。
- 未修改资源、字体、导入产物、`.uid`、`.translation`。
- 未修改 Base Docs。
- 未修改 G15 / G16 Encounter / Combat 规则语义。
- `MainMenuShell` 不直接 start / continue RunScene。
- `MainMenuShell` 不 dispatch CommandBus。
- `MainMenuShell` 不读取 RunContext / Encounter / Combat / Ledger / TruthMap / RunRuleService。
- `AppShell` 不 dispatch CommandBus。
- `run_scene.gd` 只做最小挂接，没有改 run flow / CommandBus / modal / Encounter / Combat 行为。

## Parser Smoke

G17-R3 已运行：

```text
Godot headless project-load/parser smoke PASS
```

该 smoke 使用 Godot `4.6.3` headless project-load/parser 路径。它不是完整 gameplay runtime PASS，也不是 manual playtest PASS。

smoke 前后 `git status --short` 均为空，未产生 `project.godot`、`.uid`、`.translation`、import metadata、资源、字体或导入产物 dirty。

## 非目标

G17 未实现：

- 完整主菜单。
- 正式出发探索。
- 正式长期系统。
- 完整设置系统。
- 仓库、图鉴、研究、成就、抽奖。
- MetaProgress。
- Deploy persistence。
- 新玩法。
- action combat。
- 正式美术迁移。

## 下一步建议

下一步应先做 mainline integration 决策：是否将 `godot/g17-app-shell-main-menu` 作为独立分支纳入 main。

如进入后续阶段，应从最新 main 派生，并继续保持：

- 主菜单只负责导航、氛围、轻量提示与跳转。
- 出发探索通过后续 `RunStartConfig / DeployConfig` 接入。
- 长期系统通过后续 `PlayerProfileSnapshot / LongTermSnapshot / UnlockSnapshot` 接入。
- Run 继续只消费出发配置，不承载局外长期系统。
- G15/G16 Encounter / Combat 语义默认冻结，只做 additive 扩展。
