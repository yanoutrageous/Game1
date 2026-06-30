# G39 Navigation Boundary Route Closure Contract

中文摘要：G39 收口 RunScene / AppShell 的页面导航边界，明确 `NavigationIntent` / `PageRouter` 是主菜单、出发整备、长期系统和开始当局的页面 route 事实来源。RunScene 暂停、退出当前局、Result 返回和基础 modal 关闭规则只做关键闭环，不扩展新玩法系统。

## Scope

G39 closes the critical navigation routes that became fragile after the M2/M3 and runtime-authority work:

- MainMenu -> DeployPrep.
- DeployPrep -> MainMenu.
- DeployPrep -> LongTerm.
- LongTerm -> DeployPrep.
- LongTerm -> MainMenu.
- DeployPrep -> Start Run.
- RunScene Pause -> Continue current run.
- RunScene Pause -> Settings placeholder.
- RunScene Pause -> Exit current run with abandon confirmation.
- Result -> DeployPrep / MainMenu.

## Route Ownership

- `NavigationIntent` describes navigation target, source, and route payload.
- `PageRouter` maps `NavigationIntent` to AppShell pages.
- `AppShell` owns page visibility and emits host route intents for the actual run start.
- `DeployPrepShell` and `LongTermShell` emit navigation intents instead of directly calling parent page methods.
- `RunScene` handles run-hosted route transitions and delegates current-run abandon to CommandBus/runtime authority.

## RunScene Pause / Exit Boundary

The pause panel may show:

- Continue current run.
- Settings placeholder.
- Return to DeployPrep / MainMenu only when no active run needs abandonment.
- Exit current run with a two-step confirmation.

Exit current run must call the existing `abandon_run` command path. The UI must not directly mutate `RunContext`, save data, settlement state, or meta progress.

## Result Boundary

Result UI consumes existing result display snapshots and emits return requests. It must not recalculate settlement, re-grant rewards, write warehouse data, or write save state.

## Modal / Overlay Boundary

RunScene owns the basic close priority for debug, map overlay, inventory, ground loot, event, loot, extract, result, pause, and diagnostics panels. Closing a panel releases GUI focus back to the correct runtime layer.

## Non-Goals

G39 does not implement a full settings system, Save/Profile UI, warehouse/codex/equipment progression, Objective/Reward/Pool, Loot/Inventory expansion, Settlement expansion, new gameplay content, project metadata changes, scene/resource changes, ART resources, or ART screenshot submission.

G39 validation may include Godot project-load/parser, a focused route runner, and visible route smoke. It does not claim full gameplay runtime PASS or manual long playtest PASS.
