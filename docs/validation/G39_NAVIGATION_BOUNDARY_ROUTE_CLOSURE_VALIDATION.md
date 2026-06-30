# G39 Navigation Boundary Route Closure Validation

中文摘要：本文件记录 G39 的验证目标、边界和实际结果。G39 验证导航边界、关键 route 闭环、暂停退出当前局、Result 返回与基础 modal 关闭规则；不声明完整 gameplay runtime PASS 或 manual long playtest PASS。

## Required Checks

Run from repository root:

```powershell
git diff --check
powershell -ExecutionPolicy Bypass -File tools/validate_g35_runtime_safety.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g36_runtime_architecture.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g37_runtime_authority.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g38_runtime_architecture_finalization.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_m3_minimum_item_drop_loop.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_m3r_item_usability_completion.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_m3h_item_loop_hardening.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g39_navigation_boundary.ps1
D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot --quit
D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe --headless --path D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot --script D:\AGAME1\_repo_cache\Game1_work\tools\godot_g39_navigation_boundary_runner.gd
```

## Actual Results

- `git diff --check`: PASS, LF/CRLF warnings only.
- `tools/validate_g35_runtime_safety.ps1`: PASS.
- `tools/validate_g39_navigation_boundary.ps1`: PASS.
- Godot headless project-load/parser: PASS, with non-blocking ObjectDB/resource leak warnings at exit.
- Godot headless G39 route runner: PASS, with non-blocking ObjectDB/resource leak warnings at exit.
- Visible smoke via Computer Use: PASS for MainMenu, DeployPrep, LongTerm, start run, Pause, Settings placeholder, active-run return guard, two-step exit current run, Result return, and map overlay Esc close. Evidence screenshots are under `docs/validation/g39/`.
- `tools/validate_g36_runtime_architecture.ps1`, `tools/validate_g37_runtime_authority.ps1`, `tools/validate_g38_runtime_architecture_finalization.ps1`, `tools/validate_m3_minimum_item_drop_loop.ps1`, `tools/validate_m3r_item_usability_completion.ps1`, and `tools/validate_m3h_item_loop_hardening.ps1` were run and failed only on pre-existing Godot generated metadata / `project.godot` / `.translation` / `.gd.uid` dirty that is outside G39 and not staged.

## Static Evidence

- `NavigationIntent` has main menu, deploy prep, long-term, settings, exit, and run targets.
- `PageRouter` maps those targets to page ids.
- `AppShell` connects MainMenu / DeployPrep / LongTerm navigation intent signals.
- `DeployPrepShell` and `LongTermShell` do not directly call parent `show_main`, `show_deploy`, or `show_long_term`.
- Run start remains a host route emitted from AppShell.
- Pause exit current run uses the existing `abandon_run` command path.
- Result return uses existing ResultPanel return signals.
- Map overlay, inventory, ground loot, event, loot, extract, result, pause, diagnostics, and debug panels have basic close priority.

## Dirty Worktree Boundary

The G39 validator checks forbidden staged paths rather than forbidding every pre-existing dirty path, because ART lane resources/screenshots and Godot generated metadata may exist in the worktree but must not enter the G39 commit.

Forbidden for G39 submission:

- `project.godot`.
- `*.tscn`, `*.tres`, `*.res`, `*.uid`, `*.translation`, `*.import`.
- ART resources and screenshots.
- `docs/art/**`.
- `asset_manifest` generated side effects.

## Not Claimed

G39 does not claim full gameplay runtime PASS.

G39 does not claim manual long playtest PASS.

G39 does not close ART lanes or Godot metadata hygiene.
