# M2 Latest Planning Minimum Gameplay & Meta Loop Contract

中文摘要：M2 将 M1 已有可玩闭环校准到最新策划案的最小玩法与长期闭环骨架。它不是完整 Objective / Reward / Pool、完整长期系统、完整仓库、完整装备消耗品或完整 Rule Engine 阶段。

## Source Placement

- 仓库文档入口遵循 `docs/README.md`、`docs/INDEX.md`、`docs/00_governance/DOC_PLACEMENT_STANDARD.md`。
- Base Docs 只作为外部策划来源登记，不复制正文、不改写、不参与仓库去重。
- Connection 只作为外部交接区，不复制内容入库。

## Planning Sources

- `D:\AGAME1\Base Docs\局内地图本体与生成规则策划案.md`
- `D:\AGAME1\Base Docs\局内流程与状态流转规则策划案.md`
- `D:\AGAME1\Base Docs\房间类型、标签与遭遇通用规则策划案.md`
- `D:\AGAME1\Base Docs\规则、效果、Modifier 与内容投放通用系统策划案.md`
- `D:\AGAME1\Base Docs\出发探索界面与出勤准备规则策划修正案.md`
- `D:\AGAME1\Base Docs\本局结算报告与历史战绩系统.md`
- `D:\AGAME1\Base Docs\长期系统玩法与界面规划案.md`

## Scope

M2 aligns the existing Godot M1 loop:

1. MainMenu / DeployPrep can start the current playable `standard_10x10` route through existing RunStartConfig and route adapter boundaries.
2. RunScene keeps TruthMap / IntelMap separation and presents KnownMap, minimap, map overlay, current room, HUD, inventory, ground loot, and debug feedback.
3. Move, scan, explore, search, event, chest, monster, mine, extract, fail, and settlement remain the real M1 loop.
4. Fast return is controlled by TruthMap `return_eligibility`, not by UI guesses.
5. Rule / Modifier remains intentionally limited, but `standard_10x10` now carries a minimum real search reward modifier that changes the search black coin effect before the ledger is updated.
6. RunResult is exposed as the settlement input; settlement and MetaProgress consume snapshots instead of UI recalculation.
7. LongTerm consumes MetaProgress / latest RunResult as display-only profile/history context without writing history, rewards, objectives, assets, or saves.

## Explicit Non-goals

- No `demo_7x7` implementation.
- No full Objective / Reward / Pool system.
- No full LongTerm system.
- No full warehouse, equipment, consumable loadout, research, codex, collection, or gacha.
- No full Rule Engine, expression language, AI Director, complete content pool, or full modifier stack runtime.
- No active-run persistence rewrite.
- No SaveManager ownership migration.
- No formal art import or Godot resource/scene metadata changes.

## Boundaries

- DeployPrep is a five-tab preparation surface: map, warehouse, claim, objective, loadout/config.
- DeployPrep does not write warehouse, objective progress, claim records, or asset state.
- RunScene uses CommandBus / runtime state flow; debug remains command-gated.
- UI does not directly write saves.
- Result UI does not recalculate rewards.
- Settlement reads `RunResult` / result snapshot.
- LongTerm is a display-only consumer in M2.

## Validation Expectations

- `tools/validate_m2_latest_planning_minimum_loop.ps1`
- `git diff --check`
- Godot headless project-load / parser smoke
- Headless short runtime or command-sequence smoke when available
- Visible smoke when Computer Use / local GUI is available

Gameplay runtime PASS and manual playtest PASS must only be claimed when actually executed.
