# G17 阶段总结

## 阶段目标

G17 目标是 AppShell / NavigationIntent / PageRouter / MainMenuShell foundation：先拆出应用级导航所有权，让 main menu 只负责导航、氛围、轻提示和 shortcut，不直接启动或继续 RunScene。G17 不是完整主菜单功能总成。

## 实际完成

- 新增 `NavigationIntent`、`PageRouter`、`AppShell`、`MainMenuShell` 和 static `MainMenuModel`。
- `run_scene.gd` 只挂载 AppShell，并保留既有 run orchestration。
- expedition、long-term、settings 在本阶段保持 placeholder 或 legacy routes。
- MainMenuShell 只发出 `NavigationIntent`，由 AppShell/PageRouter 决定页面切换。

## 关键提交

- `368a7be5c2fb919db47421a026ddf417df9c1b1c` `feat(godot): add app shell main menu foundation`
- `baa57fa41167c86ad226b5b8be4d540ff114269f` `docs: close G17 app shell main menu foundation`
- `eeffe5800864c05f8b000e406609fa7ca3323cb5` `docs: mark G17 merged to main`

## 新增系统 / 修改系统

- 新增 AppShell / NavigationIntent / PageRouter / MainMenuShell foundation。
- 修改顶层入口路由。
- 不实现 formal DeployConfig、LongTermSnapshot、warehouse、codex、lottery、MetaProgress、Deploy persistence 或 full settings。

## 验证状态

- `docs/validation/G17_APP_SHELL_MAIN_MENU_VALIDATION.md` 记录 G17 boundary 和 R3 Godot headless project-load/parser smoke PASS。
- parser smoke 不是 complete gameplay runtime PASS。
- 未声明 manual playtest PASS。

## 明确未完成

- 未完成完整主菜单功能总成。
- 未完成出发准备真实系统。
- 未完成长期系统、warehouse、codex、lottery、MetaProgress、Deploy persistence、full settings。

## 后续承接点

- G18 在 AppShell 上接入 DeployPrepShell foundation。
- G19 在 AppShell 上接入 LongTermShell foundation。

## 主要风险

- MainMenuShell 可能被误扩展为直接启动 RunScene。
- AppShell foundation 可能被误读成完整 app shell。
- placeholder routes 可能被误写成真实系统。

## 是否已合并 main

是。事实源记录 G17 fast-forward merged to main。

## 对后续路线的影响

G17 把 top-level navigation 从 run orchestration 中拆出，使 G18/G19 可以分别承接出发准备与长期系统 shell，而不把这些入口继续塞进 `run_scene.gd`。

## 事实来源

- `docs/PROJECT_BASELINE.md`
- `docs/NEXT_HANDOFF.md`
- `docs/ENGINEERING_STATUS.md`
- `docs/MILESTONES.md`
- `docs/validation/G17_APP_SHELL_MAIN_MENU_VALIDATION.md`
- `docs/handoff/HANDOFF_G17_APP_SHELL_MAIN_MENU.md`
- `docs/handoff/HANDOFF_POST_G16_ARCHITECTURE_DIRECTION.md`
- Git commit log
