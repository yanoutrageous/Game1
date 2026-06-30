# Handoff G39 Navigation Boundary Route Closure

中文摘要：G39 收口 RunScene / AppShell 导航边界与关键 route 闭环。后续审计应重点确认 G39 commit 未混入 ART 资源、ART 截图、Godot metadata 或 asset manifest 副作用。

## Implementation Target

G39 should leave the branch with:

- MainMenu / DeployPrep / LongTerm route transitions mediated by `NavigationIntent` / `PageRouter`.
- DeployPrep start run emitted as a host route for RunScene.
- RunScene pause panel covering continue, settings placeholder, guarded return route, and two-step exit current run.
- Exit current run routed through CommandBus/runtime authority via `abandon_run`.
- Result page returning to DeployPrep or MainMenu without recalculating settlement.
- Basic modal/Esc priority for map overlay, inventory, ground loot, event, loot, extract, result, pause, diagnostics, and debug surfaces.

## Validation Target

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_g39_navigation_boundary.ps1
D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot --script D:\AGAME1\_repo_cache\Game1_work\tools\godot_g39_navigation_boundary_runner.gd
```

Also re-run G35/G36/G37/G38 and M3/M3R/M3H validators before final branch push. If they fail only on pre-existing metadata dirty, record that as a worktree hygiene blocker outside G39 staged content.

## Dirty Worktree Handoff

Known dirty categories to keep out of G39:

- ART15 / ART17 docs, screenshots, scripts, and visual resources.
- Godot generated metadata including `.gd.uid` and `.translation`.
- `project.godot`.
- `asset_manifest` generated side effects.

Only G39 allowlisted program, validation, and docs files should be staged.

## Non-Goals

Do not merge main in G39.

Do not push main in G39.

Do not implement a complete settings system, Save/Profile UI, Objective/Reward/Pool, complete warehouse, complete Rule engine, new gameplay, or ART import.

Do not claim full gameplay runtime PASS or manual long playtest PASS.

## Recommended Next Gate

Proceed to G39 audit / release gate after the branch commit is pushed.
