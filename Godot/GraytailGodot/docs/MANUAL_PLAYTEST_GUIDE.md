# Manual Playtest Guide

## Scope

This guide treats the older G4-G7 routes as historical foundations and points manual smoke toward the current mainline G14 legacy Demo run surface baseline, the G15 encounter contract foundation, and the G16 combat encounter foundation now merged to main. Do not run Godot unless the user explicitly authorizes editor/runtime execution.

Legacy static validation aliases: `Start Tutorial 5x5`, `Start Standard 10x10`.

Current baseline smoke should cover the three-page shell, the G14 run surface shell and R4 surface refinements, formal InventoryPanel, formal GroundLootPanel, pickup/drop through CommandBus, blocked reason display, MiniMap click-to-map, MapOverlay feedback, Pause/Settings overlay, dev-only diagnostics hiding, ResultPanel settlement/return routes, Chinese readable text, local typography/readability, the five supported fixed 16:9 resolution tiers, the G15 public encounter contract / EncounterSlot fields, and G16 Monster `attack_basic` encounter fields. The current baseline is not a complete final UI, complete MetaProgress, complete Deploy persistence, complete long-term system completion, complete 1:1 legacy Demo reproduction, Boss/action combat, complete gameplay runtime PASS, or manual playtest PASS.

G17 mainline note: `godot/g17-app-shell-main-menu` added a formal AppShell / NavigationIntent / PageRouter / MainMenuShell slice and has been fast-forward merged to `main`. G17-R3 ran Godot headless project-load/parser smoke PASS, but this is not complete gameplay runtime PASS and not manual playtest PASS. Manual validation must still confirm the main menu only navigates to placeholder routes and does not directly start or continue RunScene.

G18 mainline note: `godot/g18-deploy-prep-foundation` added a formal DeployPrepShell foundation only and has been fast-forward merged to `main`. G18-R4 ran Godot headless project-load/parser smoke PASS, but this is not complete gameplay runtime PASS and not manual playtest PASS. Manual validation must still confirm DeployPrep only previews config / deploy_start_intent and does not start or continue RunScene.

G19 branch note: `godot/g19-long-term-shell-foundation` adds a LongTermShell foundation only. It exposes six modules: `目标`, `图鉴`, `研究`, `个人资历`, `抽奖`, and `收藏 / 外观`. G19-R4B records Godot headless project-load/parser smoke PASS on the branch, but this is not complete gameplay runtime PASS and not manual playtest PASS. G19 is not merged to main and G20 has not started.

## G19 LongTermShell Foundation Static Checklist

Use this checklist for G19-R3 static/manual review after explicit runtime authorization. Static inspection alone is not runtime PASS.

- Confirm the AppShell long-term route opens `LongTermShell` rather than the old placeholder page.
- Confirm the long-term page shows exactly six top-level modules: `目标`, `图鉴`, `研究`, `个人资历`, `抽奖`, `收藏 / 外观`.
- Confirm `目标` shows child preview groups for `任务`, `成就`, and `委托记录` only.
- Confirm `个人资历` shows child preview groups for `资历等级`, `历史战绩`, `数据统计`, `里程碑`, `称号 / 徽章`, and `资历奖励` only.
- Confirm `研究` and `抽奖` display disabled reasons and do not execute unlocks, rolls, costs, or result generation.
- Confirm snapshot and interface sections are display-only previews.
- Confirm LongTermShell does not dispatch CommandBus and does not read RunContext, Encounter, Combat, Ledger, or TruthMap.
- Confirm no `project.godot`, `.tscn`, resources, fonts, import products, `.uid`, or `.translation` files changed.
- Record whether Godot/editor/game/import was run. For G19-R4B the expected record is "headless project-load/parser smoke PASS only".

## G18 DeployPrep Foundation Static Checklist

Use this checklist for G18-R3 static/manual review after explicit runtime authorization. Static inspection alone is not runtime PASS.

- Confirm the AppShell deploy route opens DeployPrepShell rather than the old deploy placeholder.
- Confirm DeployPrepShell shows exactly five tabs: `地图`, `仓库`, `申领`, `出勤配置`, `作业许可`.
- Confirm each tab is placeholder-only and does not generate a real map, read real warehouse data, perform requisition transactions, or apply work permit rules.
- Confirm the right side shows `摘要`, `配置`, `效果`, and `风险` sections from public preview data.
- Confirm `开始探索` only generates DeployConfig / RunStartConfig preview or `deploy_start_intent`; it must not start or continue RunScene.
- Confirm `继续探索` and `放弃探索` remain disabled / placeholder and do not perform settlement.
- Confirm DeployPrepShell does not dispatch CommandBus and does not read private run state.
- Confirm no `project.godot`, `.tscn`, resources, fonts, import products, `.uid`, or `.translation` files changed.
- Record whether Godot/editor/game/import was run. If not run, write "not run" and do not claim parser PASS, complete gameplay runtime PASS, or manual playtest PASS.

## G17 AppShell / MainMenu Static Checklist

Use this checklist for G17 static/manual review. G17-R3 already has parser smoke PASS, but this checklist is not full gameplay runtime PASS and not manual playtest PASS.

- Confirm the formal main menu shows exactly four main entries: `出发探索`, `长期系统`, `设置`, `退出游戏`.
- Confirm `出发探索`, `长期系统`, and `设置` enter placeholder pages only.
- Confirm the main menu does not show金币、黑币、抽奖券、任务进度、资历经验、仓库容量 or 背包容量.
- Confirm the main menu does not show `开始探索`, `继续探索`, `教学局`, `标准局`, or `确认出发`.
- Confirm `退出游戏` opens a confirmation layer and does not offer abandon-run behavior.
- Confirm MainMenuShell only emits `NavigationIntent`; AppShell / PageRouter decide page switching.
- Confirm MainMenuShell and AppShell do not dispatch CommandBus and do not read RunContext, Encounter, Combat, Ledger, TruthMap, or RunRuleService private state.
- Confirm G17 does not implement formal DeployConfig, LongTermSnapshot, warehouse, codex, lottery, MetaProgress, Deploy persistence, or full settings.
- Record whether full manual gameplay testing was run. Parser smoke alone must not be recorded as manual playtest PASS.

G14 closeout fact: G14 is closed at `d6c03c6ff8ca9884f992a61e27728bdddf3a637a` (`d6c03c6 docs: close G14 legacy demo UI surface pass`). G14 hotfix is `fc2b86b fix(godot): resolve RunSurface parser type inference`, G14-R4 is `cc652e5 feat(godot): refine legacy demo run surface presentation`, G14-R3 follow-up is `39b51f1 docs: record G14 run surface acceptance follow-up`, and G14-R3 feature work is `1d33c89 feat(godot): add legacy demo run surface shell`. G14 was not run in Godot/editor/game/import and is not runtime PASS. `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf` is only the G13 closeout / G14-R3 baseline history.

G15 fact: G15-R3 starts from `d6c03c6ff8ca9884f992a61e27728bdddf3a637a` (`d6c03c6 docs: close G14 legacy demo UI surface pass`) on branch `godot/g15-encounter-contract-foundation`. G15-R3 completed the rules-layer public encounter contract at `aca5b958a588879a16da97616484424da795da7f`; G15-R4 completed the UI EncounterSlot adapter at `1887385af81624ebcd84342ca765d75e6fbf20eb`; G15-R5 closed the branch at `e72d3a5dc4a57122d42f881f391f2b47389fcdad`. G15 is now fast-forward merged to main, and Godot/editor/game/import was not run, so this is not runtime PASS.

G16 fact: G16-R3 starts from `a28ae4c0c96f0b964602fd6fe7b88fa254354763` (`a28ae4c docs: mark G15 merged to main`) on branch `godot/g16-combat-encounter-foundation`. G16-R3 is complete at `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a` and is limited to Monster `monster_basic` / `combat_basic` public encounter data, `attack_basic` option data, deterministic risk/reward preview, and combat result summary. G16-R4 acceptance passed. G16-R5 is docs-only branch closeout, parser blocker fix is `4637e8f fix(godot): expose encounter parser classes`, and G16 is fast-forward merged to main. Godot headless project-load/parser smoke PASS was recorded before merge, but this is not complete gameplay runtime PASS or manual playtest PASS.

## Legacy Main Menu / Deploy Shell

- Historical route note: before G17-R2, the legacy main menu `出发探索` entry opened the read-only DeployShell.
- Use deploy tabs to inspect warehouse, requisition, loadout, recovery, and talents shell content.
- Use `确认出发` in DeployShell to start a standard run.
- Historical route note: legacy `新手教程` from the main menu started tutorial directly. G17 formal MainMenuShell must not expose this direct-start entry.

Expected G7 visuals:

- Menu and DeployShell hide the room and player layers.
- DeployShell does not write save data or persistent progression.
- Starting a run switches to the run overlay with no menu buttons covering the room.

## Tutorial Run

Use `新手教程` to verify the fixed tutorial route and tutorial popup.

### Tutorial recommended route

- Move inside the current room with W/A/S/D or arrow keys.
- Walk through a centered door or boundary to change rooms.
- Use E to search, interact, request extraction, or confirm extraction.
- Use Space/J to fight when the current room is Monster.
- Use F to flag the current cell.
- Use M/Tab to toggle MapOverlay.
- Use R to restart.

Expected G5 visuals:

- HUD uses left/protocol/bottom presentation panels.
- MiniMap shows manifest-backed icons or text fallback.
- Tutorial popup appears as a panel rather than only HUD text.
- Room visual updates as the public current room changes.
- Player marker updates position without changing rules.

Expected G6 behavior:

- MiniMap current room changes only after a room transition.
- Blocking tutorial popups pause formal movement until confirmed.
- Search, event, monster, mine, extract, and failure result text updates are reflected in HUD/ResultPanel snapshots.

Expected G7 behavior:

- HUD and MiniMap remain inside the left sidebar.
- Protocol stays in the right rail, while Debug/Grid Move is collapsed behind its own toggle.
- Bottom action bar exposes search/interact, flag, fight, map, and restart actions.
- Search or combat opens a compact result panel instead of relying only on HUD text.

## Standard Run

Use `出发探索` -> `确认出发` for the Standard smoke route.

### Standard smoke route

- Start a standard run.
- Move several rooms.
- Confirm room-local movement does not move the MiniMap current cell until a door/boundary transition succeeds.
- Flag a cell.
- Open MapOverlay, flag a hidden cell, and teleport to an explored safe cell.
- Search a Normal or Chest room.
- Fight a Monster if reached.
- Confirm extraction only from an Exit room.

Expected G5 visuals:

- MiniMap and MapOverlay share the same ViewModel.
- Room/player visuals update from snapshots.
- ResultPanel still shows extraction/failure/training summaries.

Expected G6 behavior:

- Event rooms resolve one of trader, dice, altar, or trap outcomes.
- Monster rooms show deterministic fight state and update after combat.
- Failure results include pending-gold loss and salvage details.

Expected G7 behavior:

- Event rooms open an EventOptionPanel with selectable options.
- Exit rooms open an ExtractConfirmPanel before final result.
- ResultPanel has enough space for extraction/failure summaries.
- The old event placeholder prompt should not appear.

## G11 Mainline UX Readability Smoke

Use this route for the current mainline readability pass. This checklist is valid for manual testing only; do not mark it PASS unless the route was actually played.

- Start from the main menu, choose `出发探索`, inspect the deploy shell, then start a standard run with `确认出发`.
- Click MiniMap directly and confirm MapOverlay opens without using only the keyboard shortcut.
- In MapOverlay, click an unknown cell and confirm the feedback line names the selected coordinate, command id, and accepted/blocked state.
- In MapOverlay, click an explored safe cell and confirm the feedback line remains readable before the overlay closes or the return action completes.
- Open InventoryPanel and confirm empty state, item tooltip, command result, and disabled drop reason are readable.
- Open GroundLootPanel and confirm empty state, pickup tooltip, capacity hint, and `blocked_capacity` reason are understandable.
- Complete or fail a run and confirm ResultPanel explains the outcome and exposes clear return routes to main menu and deploy page.
- Open Pause/Settings overlay during a run and confirm the text explains that continue returns to the current run and settings do not write local preferences.
- Open the settings shell and confirm dev-only diagnostics remains hidden or disabled in the default player channel.
- Record whether Godot/editor/game/import was run; if not run, record "not run" rather than claiming runtime PASS.

## G12 Legacy Demo Core Loop Readability Smoke

Use this route for G12 only after a human or explicitly authorized runtime smoke starts the game. Do not mark PASS from static inspection alone.

- From the main menu, confirm `出发探索` and `新手教程` are readable and lead to the expected deploy or tutorial route.
- In tutorial or standard run, confirm the left scan/minimap area reads as a region scanner rather than an engineering debug view.
- Click MiniMap and confirm MapOverlay opens with readable scan/review instructions, selected coordinate feedback, command id, and blocked reason when relevant.
- Move through several rooms and confirm HUD room, position, adjacent danger, search state, protocol level, pressure, event/enemy/exit hint, and latest action are readable Chinese.
- Trigger or inspect Event, Chest, Monster, Normal search, Mine, and Exit states when reachable; confirm text explains the room state without changing rules.
- Search a room and inspect the reward panel; confirm black coin, gold coin, item count, ground loot, damage, roll, and blocked reason labels are understandable.
- Open Inventory and GroundLoot; confirm capacity, empty states, tooltip text, pickup/drop labels, and `blocked_capacity` are readable.
- Extract or fail the run and confirm ResultPanel explains success/failure, salvage/loss, warehouse-lite movement, logs, and return paths.
- Check Chinese readability on dark panels: no obvious mojibake, no missing glyph blocks, no unreadable contrast, and no clipped button text in the tested viewport.
- Record whether Godot/editor/game/import was run. If it was not run, write "not run" and do not claim runtime PASS.

## G13 Fixed Resolution Layout Smoke

Use this route for G13 only after a human or explicitly authorized runtime smoke starts the game. Do not mark PASS from static inspection alone.

- Confirm the first launch or auto reset chooses the largest supported tier that fits the current display area.
- Confirm the Settings page only lists `1280x720`, `1366x768`, `1600x900`, `1920x1080`, and `2560x1440`.
- Confirm applying each supported tier changes the window to that fixed size and the status text updates.
- Confirm restoring automatic recommendation returns to the best supported tier for the current display area.
- Confirm the window cannot be freely resized by dragging and that unsupported aspect ratios are not offered.
- At `1280x720`, confirm HUD, MiniMap, MapOverlay, Inventory, GroundLoot, ResultPanel, tooltips, and Chinese text do not clip in the expected route.
- At `1366x768`, confirm the extra height does not leave important controls misaligned or clipped.
- At `1600x900` and `1920x1080`, confirm standard UI density remains readable and centered enough for the controlled 16:9 layout.
- At `2560x1440`, confirm text is not unreasonably small and panel spacing remains readable.
- Record whether Godot/editor/game/import was run. If it was not run, write "not run" and do not claim runtime PASS.

## G14 Legacy Demo Run Surface Smoke

Use this route for G14 only after a human or explicitly authorized runtime smoke starts the game. Do not mark PASS from static inspection alone.

- G14-R3 static acceptance says `RunSurface` is UI surface composition only and `RunSurfaceModel` is display-only.
- G14-R4 static acceptance adds only display/presentation refinement; it does not prove runtime PASS.
- G14 hotfix static acceptance only resolves a `run_surface.gd` parser type inference issue; it does not prove runtime PASS.
- G14-R5 closes documentation, handoff, status, and validation only; it does not run Godot/editor/game/import.
- Confirm runtime behavior only after explicit authorization; static docs do not prove visual PASS.
- Start tutorial and standard runs through the existing shell routes.
- Confirm the run screen has a clear old Demo-style information hierarchy: left region scanner, center current room/objective, right protocol/danger/status, bottom action bar, and lower-left resource/backpack summary.
- Confirm the MiniMap still opens MapOverlay through the existing command path.
- Confirm InventoryPanel and GroundLootPanel still open, show snapshot data, and route pickup/drop through CommandBus.
- Trigger or inspect Event, Chest/Search, Monster, Exit, loot, extract, and result states when reachable; confirm EventOptionPanel, LootResultPanel, ExtractConfirmPanel, ResultPanel, TutorialPopup, and Pause overlay still use existing routes and are hosted above the surface.
- Confirm EventOptionPanel, LootResultPanel, and ExtractConfirmPanel have clearer dark-panel hierarchy, titles, risk/reward text, and button layering without changing the decisions they trigger.
- Confirm the scanner legend distinguishes current, unknown, flagged, dangerous, event, reward, and exit markers using existing MiniMap data only.
- Confirm bottom action buttons show readable enabled/disabled state and tooltip reasons, and that disabled buttons do not introduce new actions.
- Confirm the right protocol rail makes protocol, pressure, danger, room state, search state, recent event, loot, and command feedback easier to scan.
- Confirm the surface buttons do not introduce new gameplay rules and only call the existing run scene orchestration paths.
- Confirm no visible text, button, or panel clips at the G13 fixed tiers before any runtime PASS claim.
- Record whether Godot/editor/game/import was run. If it was not run, write "not run" and do not claim runtime PASS.

Safety note for future manual or CodeX follow-up: do not create temporary scripts, logs, caches, or derived files outside `D:\AGAME1\_repo_cache\Game1_work` for the current computer-two Game1 worktree. G14-R3 execution reported an outside-repository temporary-script incident that was cleaned as necessary deletion; do not scan outside-repository paths unless the user provides a concrete path and explicit authorization.

If later UI and rules work proceed in parallel, branch from latest `main` into separate branches. Do not have two computers push directly to `main` in parallel. Rules-line work must not directly modify UI surface code, and UI-line work must not directly read rules private state. High-conflict ownership is required for `run_scene.gd`, `run_ui_view_model.gd`, `presentation_mapping.gd`, and global status / handoff / validation docs.

## G15 Encounter Contract Static Checklist

Use this checklist for G15-R3/G15-R5 static review. It is not runtime PASS.

- Confirm `encounter_view_model` and `encounter_result_summary` are exposed from `RunQueryFacade` snapshots.
- Confirm options include `id`, `title`, `cost`, `expected_reward`, `risk`, `one_shot`, `requires_confirm`, `disabled`, `disabled_reason`, `command_name`, and `command_payload`.
- Confirm search/chest options route through additive `select_encounter_option` and then the existing `search_current_room()` path.
- Confirm existing event options route through additive `select_encounter_option` and then the existing `select_event_option()` path.
- Confirm `request_extract`, `confirm_extract`, event resolution, loot panels, combat, settlement, and UI surface code are not migrated in G15-R3.
- Confirm `lottery` is only a deferred encounter type name; no probability, pity, pool, unique collectible, warehouse, codex, appearance library, duplicate compensation, MetaProgress, or Deploy persistence is implemented.
- Confirm Godot/editor/game/import was not run; if not run, record "not run" and do not claim runtime PASS.

## G15-R4 EncounterSlot UI Checklist

- Confirm Monster rooms still use public `encounter_view_model` / `encounter_result_summary` and do not expose private rule objects.
- Confirm disabled EncounterSlot options remain disabled and show `disabled_reason`.
- Confirm `requires_confirm` remains display-only unless a later stage explicitly adds a confirmation flow.

## G16 Combat Encounter Foundation Checklist

Use this route only after a human or explicitly authorized runtime smoke starts the game. Do not mark PASS from static inspection alone.

- Closeout fact: G16-R5 only updates docs/handoff/status/validation. G16 final later ran Godot headless project-load/parser smoke and fast-forward merged the branch to `main`.
- Confirm branch status before testing: G16 is merged to `main`; any later manual gameplay smoke is separate from the parser smoke.

- Reach or seed a Monster room and confirm EncounterSlot shows a Monster / combat encounter rather than a reserved-only placeholder.
- Confirm the slot displays Monster target name, player power, enemy/current/base power, risk summary, reward preview, and `attack_basic`.
- Confirm `attack_basic` uses public `select_encounter_option` data and does not expose `TruthMap`, `RunRuleService`, Ledger, AssetLedger, RunAssetLedger, or RunContext private state.
- Trigger `attack_basic` only during an authorized runtime smoke and confirm it follows the existing deterministic `fight_current_enemy` result path.
- Confirm result text summarizes damage, black coin reward, clear state, and player win/loss without claiming action combat.
- Confirm cleared Monster rooms show completed/disabled state and do not offer repeat reward farming.
- Confirm Boss, elite, multi-monster, skills, passive systems, leave confirmation, teleport restrictions, combat animation, full drop economy, codex, action combat, real-time combat, lottery, MetaProgress, and Deploy persistence are not present.
- Record whether gameplay/manual testing was run. The recorded G16 parser smoke is not complete gameplay runtime PASS or manual playtest PASS.

Use this checklist only after G15-R4 UI adapter changes are present. It is not runtime PASS unless a later authorized runtime smoke actually starts the game.

- Confirm RunSurface shows an EncounterSlot inside the existing run surface, without replacing EventOptionPanel, LootResultPanel, ExtractConfirmPanel, Inventory, GroundLoot, ResultPanel, or MapOverlay routes.
- Confirm EncounterSlot displays the public encounter title, type/state, short description, option list, option title, cost, expected reward, risk, disabled state, disabled reason, requires-confirm marker, and recent result summary.
- Confirm enabled EncounterSlot options emit only the public option id and public `command_payload`, then run_scene routes through CommandBus `select_encounter_option`.
- Confirm disabled options remain visible with disabled reason and cannot dispatch a selection.
- Confirm `requires_confirm` is only a visible marker in G15-R4; no new confirmation modal or new rule branch is introduced.
- Confirm search and chest encounter options still resolve through existing search/current-room behavior and show existing loot feedback when rewards are produced.
- Confirm event encounter options still resolve through existing event rules; old EventOptionPanel behavior remains available through the existing interaction path.
- Confirm Monster/combat, extract-only, lottery, out-of-run progression, MetaProgress, Deploy persistence, and action combat remain deferred or out of scope.
- Confirm UI code does not read `TruthMap`, `RunRuleService`, Ledger, `AssetLedger`, `RunAssetLedger`, or `RunContext` private rule objects.
- Record whether Godot/editor/game/import was run. If it was not run, write "not run" and do not claim runtime PASS.

## Known limits

- No Godot import/runtime smoke is part of the static G5 validation.
- No arbitrary aspect-ratio responsiveness, mobile support, ultrawide support, 4K support, full DPI parity, complete settings system, full MetaProgress, persistence-backed Deploy economy, action combat, video, music, or font migration.
- No complete 1:1 legacy Demo reproduction, full event library, full talent/card system, full art migration, full combat room, lottery, out-of-run progression, or G16 scope.
- Some migrated icons remain internal placeholders until final art approval.
