# M2 Latest Planning Minimum Gameplay & Meta Loop Validation

中文摘要：本文件记录 M2 最小玩法与长期闭环落地的验证口径。M2 不声明完整玩法系统完成，也不声明未执行的 manual playtest PASS。

## Validation Scope

- DeployPrep start intent routes to `standard_run`, not legacy demo route.
- RunStartConfig / RunStartRouteAdapter remains the bridge to existing playable route.
- Minimap / map overlay return action uses `return_eligibility`.
- CommandBus fast return uses TruthMap authority.
- `standard_10x10` includes a minimum real modifier configuration.
- RunRulePipeline exposes limited numeric modifier execution.
- RunRuleService applies the search reward modifier before ledger effects.
- RunQueryFacade exposes `RunResult` as `settlement_input`.
- LongTerm consumes MetaProgress and latest RunResult as display-only.
- Protected Godot metadata dirty is not part of this validation and must not be staged.

## Commands

```powershell
git diff --check
powershell -ExecutionPolicy Bypass -File tools/validate_m2_latest_planning_minimum_loop.ps1
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --quit
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --script "D:\AGAME1\_repo_cache\Game1_work\tools\godot_m2_minimum_loop_runner.gd"
```

## Expected Result

- Static script: PASS.
- Godot project-load/parser smoke: PASS if executed successfully.
- M2 minimum loop runner: PASS if it prints `M2_MINIMUM_LOOP_REGRESSION=PASS`.
- No stage includes `project.godot`, `.translation`, `.uid`, `.import`, scene, resource, cache, or save files.

## Not Claimed

- No gameplay runtime PASS unless runtime smoke is actually executed.
- No manual playtest PASS unless visible/manual coverage is actually executed.
- No full Objective / Reward / Pool completion.
- No full LongTerm / Warehouse / Rule Engine completion.
