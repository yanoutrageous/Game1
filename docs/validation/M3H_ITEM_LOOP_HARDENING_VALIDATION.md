# M3H Item Loop Hardening Validation

中文摘要：M3H 验证覆盖局内装备注册边界、带入装备、失败抢救、abandon 分支、收益命名和 metadata hygiene。Godot headless 仅代表 project-load/parser 或 runner 结果，不代表 gameplay runtime PASS 或 manual playtest PASS。

## Validation Targets

- `tools/validate_m3h_item_loop_hardening.ps1`
- `tools/godot_m3h_item_loop_hardening_runner.gd`
- existing M3/M3R validators and runners
- Godot headless project-load/parser smoke

## Required Assertions

1. In-run acquired equipment cannot be equipped immediately.
2. Carry-in equipment remains equipped / active.
3. Unused carry-in consumable can be a failure salvage candidate.
4. Abandon routes to real `settle_abandon` but is not success / normal failure.
5. `safe_yield_state = pending_undecided` for abandon.
6. `black_coin`, `safe_yield`, and `long_term_gold` semantics are present in snapshots / settlement output.
7. `CommandBus.equip_item` delegates to `RunAssetLedger.equip_inventory_item`.
8. `project.godot`, `.uid`, `.translation`, `.import`, scenes and resources are not part of the M3H diff.

## Expected Commands

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_m3_minimum_item_drop_loop.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_m3r_item_usability_completion.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_m3h_item_loop_hardening.ps1
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --script "D:\AGAME1\_repo_cache\Game1_work\tools\godot_m3_minimum_item_drop_loop_runner.gd"
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --script "D:\AGAME1\_repo_cache\Game1_work\tools\godot_m3r_item_usability_completion_runner.gd"
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --script "D:\AGAME1\_repo_cache\Game1_work\tools\godot_m3h_item_loop_hardening_runner.gd"
```

## Boundary

This validation does not claim gameplay runtime PASS or manual playtest PASS.
