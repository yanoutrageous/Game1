# M2 Lua / UE Effect-First Playable Loop Validation

中文摘要：本文记录 M2-R2 的验证口径。M2 只声明 effect-first 可玩闭环与轻量可维护化，不声明完整玩法系统、manual playtest PASS 或未执行的 gameplay runtime PASS。

## Validation Scope

- Contract includes a Lua / UE / Godot alignment table and placeholder catalog key list.
- DeployPrep start intent routes to `standard_run`, not legacy demo route.
- `RunBalanceCatalog`, `RunContentCatalog`, and `RunTextCatalog` exist and are consumed by runtime services.
- `RunEffectApplier` exists and handles HP, protocol pressure, room marks, run fail/extract, debug marker, and asset-effect handoff.
- Event HP / pressure deltas are applied as real effects, not display-only fields.
- Mine and explore pressure changes route through the effect boundary.
- Search rewards and event rewards still route through `RunAssetLedger`.
- `RunResultBuilder` exposes `RunResult` and `SettlementInput`; result UI and MetaProgress do not recalculate rewards.
- LongTerm remains display-only and does not write history, rewards, objectives, assets, or saves.
- Protected Godot metadata dirty is not staged or submitted as part of M2-R2.

## Commands

```powershell
git diff --check
powershell -ExecutionPolicy Bypass -File tools/validate_m2_lua_ue_effect_first_loop.ps1
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --quit
"D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --script "D:\AGAME1\_repo_cache\Game1_work\tools\godot_m2_lua_ue_effect_first_runner.gd"
```

## Expected Result

- Static script: PASS.
- Godot project-load/parser smoke: PASS when executed successfully.
- M2 headless runner: PASS when it prints `M2_LUA_UE_EFFECT_FIRST_LOOP=PASS`.
- Staged files must not include `project.godot`, `.translation`, `.uid`, `.import`, scene, resource, cache, or save files.

## Executed Result

- Static script: PASS (`tools/validate_m2_lua_ue_effect_first_loop.ps1`).
- Godot project-load/parser smoke: PASS; Godot reported shutdown resource-leak warnings only.
- M2 headless runner: PASS (`M2_LUA_UE_EFFECT_FIRST_LOOP=PASS`); Godot reported shutdown resource-leak warnings only.
- Visible Computer Use smoke: PARTIAL.
  - A visible Godot window was launched from the correct project path.
  - F1 from the main menu entered the `standard_10x10` RunScene; scanner, current room panel, and room art were visible.
  - Follow-up key coverage could not be reliably observed through Computer Use because the Godot canvas screenshot channel intermittently returned empty frames and OS-level screenshots were affected by foreground focus.
  - This is not a manual playtest PASS and does not replace later visible QA.
- Added a minimal main-menu F1/F2 shortcut handler so visible smoke can enter the existing shortcut routes even when fixed 1280 layout content is partially offscreen in a smaller window.

## M2-R2.1 Release Cleanup / Validation Alignment

- 中文摘要：本节记录 M2 effect-first 发布前清理与验证门对齐；Godot metadata 不进入提交，Debug heal 改为 effect-first，G37 runtime authority 与 M2 回归脚本已同步覆盖新路径。
- Metadata cleanup: tracked `project.godot` and tracked `asset_manifest.*.translation` were restored to HEAD; untracked `asset_manifest.*.translation` and generated `.gd.uid` files were removed by exact path list. No metadata was staged or committed.
- Validation alignment: `tools/validate_g37_runtime_authority.ps1` now accepts the M2 event path `EventService -> RunRuleService.apply_event_rule_result -> RunEffectApplier` while preserving the runtime authority checks for `context.phase`, `context.fail_run`, `RunFlowStateContract`, and CommandBus ownership.
- Debug heal cleanup: `CommandBus.debug_heal_full()` now applies HP restoration through `RunEffectApplier.effect_hp_delta(...)`; it no longer directly writes `context.hp = context.max_hp`.
- Regression expansion: `tools/godot_m2_lua_ue_effect_first_runner.gd` now covers `standard_10x10`, `hp_delta`, protocol pressure, normal search reward, chest reward, ground loot pickup, event hp/pressure/gold/item effects, combat damage/reward, mine damage/pressure, extract, fail, `RunResult`, `SettlementInput`, and `ui_recalculation_allowed=false`.
- M2 validation script now checks the expanded runner coverage and the debug heal effect-first boundary.

## Not Claimed

- No manual playtest PASS unless visible/manual coverage is actually executed.
- Visible Computer Use smoke must be recorded as PASS, PARTIAL, FAIL, or NOT RUN; headless PASS cannot substitute for it.
- No complete Objective / Reward / Pool completion.
- No complete LongTerm / Warehouse / Rule Engine completion.
- No full content-pool or formal art replacement completion.
