# M3 Minimum Item Pack & Drop Loop Validation

中文摘要：本文记录 M3 最小物品包与掉落闭环的验证口径。M3 验证必须覆盖物品分类、GroundLoot-first 掉落、背包拾取/丢弃、消耗品使用、三层收益、成功/失败/放弃结算、UI 只读展示与 metadata 排除边界。

## 1. Validation Scope

Validation covers:

- `M3ItemCatalog` item groups and ordinary unique-drop guard;
- search / chest / monster / event / altar GroundLoot-first semantics;
- GroundLoot pickup, drop, and repick;
- consumable use through command / rule / ledger flow;
- `run_black_coin`, `safe_yield`, and `long_term_gold` separation;
- success, failure, and abandon settlement snapshots;
- DeployPrep / inventory / GroundLoot / result display wording;
- no `project.godot`, scene, resource, uid, translation, or import metadata staged as M3 implementation.

## 2. Validation Commands

Run from repository root:

```powershell
git diff --check
powershell -ExecutionPolicy Bypass -File tools/validate_g35_runtime_safety.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g36_runtime_architecture.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g37_runtime_authority.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g37_runtime_authority_supplement.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g38_runtime_architecture_finalization.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_m2_lua_ue_effect_first_loop.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_m3_minimum_item_drop_loop.ps1
```

Godot headless runners:

```powershell
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --quit
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --script "D:\AGAME1\_repo_cache\Game1_work\tools\godot_g37_command_sequence_runner.gd"
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --script "D:\AGAME1\_repo_cache\Game1_work\tools\godot_m2_lua_ue_effect_first_runner.gd"
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --script "D:\AGAME1\_repo_cache\Game1_work\tools\godot_m3_minimum_item_drop_loop_runner.gd"
```

## 3. Pass Criteria

- Static validators pass.
- M3 runner prints `M3_MINIMUM_ITEM_DROP_LOOP=PASS`.
- M2 runner remains compatible with M3 GroundLoot-first reward semantics.
- Godot project-load/parser smoke passes.
- No metadata dirty is staged.
- UI display remains read-only for settlement/meta values.

## 4. Boundaries

Parser or headless runner PASS is not manual playtest PASS. It is also not a claim that complete warehouse, complete equipment, full Objective / Reward / Pool, or full Rule Engine is implemented.

## 5. Known Follow-Up

P2 follow-up candidates:

- richer warehouse management;
- more item content tuning;
- final unique collectible policy;
- full equipment loadout;
- Objective / Reward / Pool integration;
- visible manual playtest after audit gate.

## 6. Current Run Result

Actual validation run in this implementation slice:

- `git diff --check`: PASS with LF/CRLF warnings only.
- `tools/validate_g35_runtime_safety.ps1`: PASS.
- `tools/validate_g36_runtime_architecture.ps1`: PASS.
- `tools/validate_g37_runtime_authority.ps1`: PASS.
- `tools/validate_g37_runtime_authority_supplement.ps1`: not directly PASS under active M3 diff because the supplement script intentionally rejects files outside its G37/G38 architecture allowlist. The base G37 authority checks inside it pass before the diff allowlist blocker.
- `tools/validate_g38_runtime_architecture_finalization.ps1`: PASS.
- `tools/validate_m2_lua_ue_effect_first_loop.ps1`: PASS.
- `tools/validate_m3_minimum_item_drop_loop.ps1`: PASS.
- Godot headless project-load/parser smoke: PASS; shutdown emitted existing ObjectDB/resource-leak warnings.
- `tools/godot_g37_command_sequence_runner.gd`: PASS; shutdown emitted existing ObjectDB/resource-leak warnings.
- `tools/godot_m2_lua_ue_effect_first_runner.gd`: PASS; shutdown emitted existing ObjectDB/resource-leak warnings.
- `tools/godot_m3_minimum_item_drop_loop_runner.gd`: PASS; shutdown emitted existing ObjectDB/resource-leak warnings.

No gameplay runtime PASS or manual playtest PASS is claimed.
