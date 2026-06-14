# Manual Playtest Guide

## Scope

This guide treats the older G4-G7 routes as historical foundations and points manual smoke toward the current mainline G14 legacy Demo run surface baseline. Do not run Godot unless the user explicitly authorizes editor/runtime execution.

Legacy static validation aliases: `Start Tutorial 5x5`, `Start Standard 10x10`.

Current baseline smoke should cover the three-page shell, the G14 run surface shell and R4 surface refinements, formal InventoryPanel, formal GroundLootPanel, pickup/drop through CommandBus, blocked reason display, MiniMap click-to-map, MapOverlay feedback, Pause/Settings overlay, dev-only diagnostics hiding, ResultPanel settlement/return routes, Chinese readable text, local typography/readability, and the five supported fixed 16:9 resolution tiers. The current baseline is not a complete final UI, complete MetaProgress, complete Deploy persistence, complete long-term system completion, complete 1:1 legacy Demo reproduction, G15, or runtime PASS.

G14 closeout fact: current main before G14-R5 docs closeout is `fc2b86b6b6b2af9a6c249230621482617b594775` (`fc2b86b fix(godot): resolve RunSurface parser type inference`). G14-R4 is `cc652e5 feat(godot): refine legacy demo run surface presentation`, G14-R3 follow-up is `39b51f1 docs: record G14 run surface acceptance follow-up`, and G14-R3 feature work is `1d33c89 feat(godot): add legacy demo run surface shell`. G14 was not run in Godot/editor/game/import and is not runtime PASS. `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf` is only the G13 closeout / G14-R3 baseline history.

## Main Menu / Deploy Shell

- Use the main menu `出发探索` entry to open the read-only DeployShell.
- Use deploy tabs to inspect warehouse, requisition, loadout, recovery, and talents shell content.
- Use `确认出发` in DeployShell to start a standard run.
- Use `新手教程` from the main menu to start tutorial directly.

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

Safety note for future manual or CodeX follow-up: do not create temporary scripts, logs, caches, or derived files outside `D:\AGAME2\repo\Game1`. G14-R3 execution reported an outside-repository temporary-script incident that was cleaned as necessary deletion; do not scan outside-repository paths unless the user provides a concrete path and explicit authorization.

If later UI and rules work proceed in parallel, branch from latest `main` into separate branches. Do not have two computers push directly to `main` in parallel. Rules-line work must not directly modify UI surface code, and UI-line work must not directly read rules private state. High-conflict ownership is required for `run_scene.gd`, `run_ui_view_model.gd`, `presentation_mapping.gd`, and global status / handoff / validation docs.

## Known limits

- No Godot import/runtime smoke is part of the static G5 validation.
- No arbitrary aspect-ratio responsiveness, mobile support, ultrawide support, 4K support, full DPI parity, complete settings system, full MetaProgress, persistence-backed Deploy economy, action combat, video, music, or font migration.
- No complete 1:1 legacy Demo reproduction, full event library, full talent/card system, full art migration, or G15 scope.
- Some migrated icons remain internal placeholders until final art approval.
