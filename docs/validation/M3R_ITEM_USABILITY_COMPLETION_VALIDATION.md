# M3R Item Usability Completion Validation

中文摘要：本文记录 M3R 的验证口径。M3R 验证重点是证明 M3 的最小物品包不再停留在“入仓后不可用”：仓库可读、图鉴可派生、出发可携带装备/消耗品、下一局 runtime 可见、生效和结算不回退。本文件不声明完整 gameplay runtime PASS 或 manual long playtest PASS。

## 1. Scope

Validation covers:

- Warehouse Lite reads real `warehouse_items`
- Codex Lite derives discovered entries from warehouse items
- `equip_item` / `unequip_item` command authority path exists
- DeployPrep loadout is not preview-only for the M3R minimal start route
- `RunStartConfig` / `RunConfig` carry selected equipment and consumables
- carry-in equipment enters runtime equipped state
- carry-in consumables enter runtime inventory and can be consumed
- success/failure settlement preserves M3 income and salvage boundaries
- profile / permit / protocol / talent minimum fields exist
- forbidden Godot metadata/project/scene/resource/import paths are not part of the diff

## 2. Validation Commands

Run from repository root:

```powershell
git diff --check
powershell -ExecutionPolicy Bypass -File tools/validate_g35_runtime_safety.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g36_runtime_architecture.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g37_runtime_authority.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_g38_runtime_architecture_finalization.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_m3_minimum_item_drop_loop.ps1
powershell -ExecutionPolicy Bypass -File tools/validate_m3r_item_usability_completion.ps1
```

Godot commands:

```powershell
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --quit
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --script "D:\AGAME1\_repo_cache\Game1_work\tools\godot_m3_minimum_item_drop_loop_runner.gd"
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --script "D:\AGAME1\_repo_cache\Game1_work\tools\godot_m3r_item_usability_completion_runner.gd"
```

## 3. Expected Evidence

The M3R runner must print:

```text
M3R_ITEM_USABILITY_COMPLETION=PASS
```

The PowerShell validator must print:

```text
M3R item usability completion validation: PASS
```

Any Godot shutdown resource warnings are recorded as shutdown warnings only if project load and script execution complete without parser/runtime assertion failure.

## 4. Visible Smoke Requirement

Visible smoke should use Computer Use if the GUI control plugin is usable. It should inspect the minimum route:

```text
item -> warehouse_items -> Warehouse Lite / Codex Lite -> DeployPrep loadout -> next run runtime state -> consumable use -> failure or success settlement
```

If Computer Use / GUI control is unavailable, this validation must record `visible smoke NOT RUN` with the reason. No unapproved foreground automation should be used to bypass that boundary.

## 5. Boundary

This validation does not prove:

- complete Warehouse economy
- complete LongTerm system
- complete Codex research
- complete equipment strengthening
- complete Objective / Reward / Pool
- complete Rule Engine
- gameplay runtime PASS
- manual long playtest PASS

## 6. Final Result Slot

Final command outputs and commit hash are recorded in the execution report after validation and branch push.
