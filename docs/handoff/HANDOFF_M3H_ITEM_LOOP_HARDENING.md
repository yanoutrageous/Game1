# Handoff M3H Item Loop Hardening

中文摘要：M3H 收紧 M3/M3R 物品循环的运行边界，修复局内获得装备可立即装备、abandon 文案落后于真实分支、safe_yield/gold_coin 命名混淆，以及 Godot metadata 不应进入本次提交的问题。

## What Changed

- Added registration flags to run item instances.
- Blocked in-run acquired equipment from immediate equip with `equipment_requires_extraction_registration`.
- Kept carry-in equipment active through run start configuration.
- Kept unused consumables eligible for failure salvage.
- Updated abandon intent preview to reflect the real `settle_abandon` branch.
- Added currency semantic fields for `black_coin`, `safe_yield`, historical `gold_coin`, and `long_term_gold`.
- Added `tools/godot_m3h_item_loop_hardening_runner.gd`.
- Added `tools/validate_m3h_item_loop_hardening.ps1`.

## Follow-Up

Recommended next gate: G38 / future item-loop audit should verify the M3H runner together with the existing M3 and M3R runners.

## Explicit Non-Claims

- No complete warehouse economy.
- No complete equipment strengthening.
- No full Objective / Reward / Pool.
- No complete Rule Engine.
- No gameplay runtime PASS.
- No manual playtest PASS.
- No Godot metadata/resource changes.
