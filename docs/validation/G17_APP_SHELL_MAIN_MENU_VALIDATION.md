# G17 AppShell / MainMenu Validation

## 定位

本文件记录 G17-R2 `AppShell / NavigationIntent / PageRouter / MainMenuShell` 最小切片的静态验证边界，以及 G17-R3 验收 / parser smoke 结果。

G17-R2 只建立顶层应用壳和主菜单导航协议：

- `MainMenuShell` 只展示主菜单并发出 `NavigationIntent`。
- `AppShell` / `PageRouter` 决定页面切换。
- `出发探索`、`长期系统`、`设置` 在本轮只进入 placeholder route。
- `退出游戏` 只打开确认层。
- 主菜单不直接 start / continue `RunScene`。
- 主菜单不读取 `RunContext`、Encounter、Combat、Ledger、TruthMap 或规则私有状态。
- G17-R2 不实现正式出发探索、长期系统、仓库、图鉴、抽奖、MetaProgress 或 Deploy persistence。

## G17-R2 修改范围

- 新增 `scripts/ui/app_shell/navigation_intent.gd`。
- 新增 `scripts/ui/app_shell/page_router.gd`。
- 新增 `scripts/ui/app_shell/app_shell.gd`。
- 新增 `scripts/ui/main_menu/main_menu_model.gd`。
- 新增 `scripts/ui/main_menu/main_menu_shell.gd`。
- `run_scene.gd` 只做最小挂载：正式 shell 从 legacy G9 shell 切到 `AppShell`，保留既有 run flow、CommandBus、modal、ResultPanel、Encounter / Combat 行为。
- 文档更新仅用于记录 G17 active branch、validation 和 manual checklist。

## 静态验证命令

```powershell
git diff --stat
git diff --check
git status --short
git diff --name-only
rg -n "start_tutorial_requested|start_standard_requested|start_tutorial_run|start_standard_run|command_bus\\.dispatch|RunContext|Encounter|Combat|fight_current_enemy|fight_enemy" Godot/GraytailGodot/scripts/ui/app_shell Godot/GraytailGodot/scripts/ui/main_menu
rg -n "NavigationIntent|PageRouter|MainMenuShell|deploy_placeholder|long_term_placeholder|exit_confirm" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs
rg -n "_show_main_menu|_show_deploy_shell|_show_long_term_shell|_show_settings_shell|_show_run_screen|G9ShellPanel|AppShell" Godot/GraytailGodot/scripts/core/run/run_scene.gd
```

## 验收标准

- `app_shell` / `main_menu` 目录内不得出现 direct start run、CommandBus dispatch、RunContext / Encounter / Combat 私有读取。
- `run_scene.gd` 只允许出现 AppShell 挂载和兼容 wrapper，不改 run flow、screen run behavior、event / loot / extract / combat 旧逻辑。
- 不修改 `project.godot`、场景资源、字体、导入产物、`.uid`、`.translation`。
- 不修改 `D:\AGAME1\Base Docs`。
- 不声明 full gameplay runtime PASS。
- 不声明 manual playtest PASS。
- 不启动 G18 / G19 / G20。

## G17-R3 验收记录

G17-R3 只做验收、Godot headless project-load/parser smoke、docs-only closeout，不修改业务代码，不实现新功能。

- 验收结果：通过。
- Godot smoke：`Godot headless project-load/parser smoke PASS`。
- smoke 命令退出成功，输出不含 parser / compile / load script error。
- smoke 前后 `git status --short` 均为空。
- 未产生 `project.godot`、`.uid`、`.translation`、import metadata、资源、字体或导入产物 dirty。
- G17-R3 itself did not perform mainline integration; G17 final later fast-forward merged the branch to `main`.
- No G18 work began in R3.

## Runtime 边界

G17-R3 的 smoke 只能记录为 Godot headless project-load/parser smoke，不得写成完整 gameplay runtime PASS 或 manual playtest PASS。
