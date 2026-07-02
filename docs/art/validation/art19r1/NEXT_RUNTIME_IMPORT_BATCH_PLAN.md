# 下一批 Runtime UI 素材导入计划

## 0. 文档定位

本文是 ART-19R1 Slice 5 产物，用于规划下一批 UI runtime 素材导入的优先级、来源候选、命名、asset_id、visual_key 和治理动作。
本文不是导入授权，不修改 `asset_manifest.csv`，不修改 Godot UI 代码，不新增 runtime asset。

## 1. 计划原则

- 优先修正 ART-19 已接入素材的命名和语义风险。
- 优先补齐四核心界面和 Run HUD / MapOverlay 的最小组件集。
- 只把已确认存在的来源文件或真实存在的文件集合列为 `confirmed_existing`。
- 对需要人工视觉判断的候选，标记为 `needs_source_selection` 或 `select_or_defer`，不得伪装成确定导入项。
- 后续导入前必须完成切片规格、source hash、target path、asset_id、visual_key 和 manifest 变更审查。

## 2. source_status 口径

| source_status | 含义 | 是否可直接进入导入 |
| --- | --- | --- |
| `confirmed_existing` | 单个候选文件已确认存在。 | 可在完成切片与命名后进入导入 gate。 |
| `confirmed_existing_set` | 通配符或同目录候选集合已确认存在且数量大于 0。 | 需先选定具体文件和状态组合。 |
| `needs_source_selection` | 存在多个真实备选，但语义或用途需审查选择。 | 不可直接导入，需先选源。 |
| `needs_visual_fit_review` | 文件存在，但是否符合页面语义不确定。 | 不可直接导入，可延后或另找来源。 |
| `reserved_or_defer` | 暂缓项或低优先级项。 | 不进入下一批 P0。 |

## 3. 批次统计

| batch | 数量 | 定位 |
| --- | ---: | --- |
| `B1_P0_governance_fix` | 8 | 修正 ART-19 已接入素材的命名、语义和复用风险。 |
| `B2_P0_core_pages` | 11 | 补齐主菜单、出发探索、长期系统、Run HUD、MapOverlay 的核心组件。 |
| `B3_P1_followup_pages` | 4 | 背包、地面拾取、页面语义背景等跟随组件。 |
| `B4_P2_result` | 1 | 结果界面标题牌集合，低于核心页面优先级。 |

## 4. 下一批计划表

| batch | priority | item | source candidate | source status | action | target runtime path | asset_id | visual_key | replaces / limits |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `B1_P0_governance_fix` | `P0` | `generic_selected_tab_set` | `sources/draw/30_game_ready/ui_deploy_button/ui_button_nav_talent_selected.png` 与同目录 nav 按钮集合 | `confirmed_existing_set` | `recut_or_rename_before_import` | `res://assets/ui/shared/tabs/ui_shared_tab_primary_selected.png` | `ui.shared.tab.primary.selected` | `shared.tab.primary.selected` | 限制 `ui.art19.button.selected_tab` 的错误泛化。 |
| `B1_P0_governance_fix` | `P0` | `shared_summary_card_set` | `sources/draw/30_game_ready/ui_deploy_panel/ui_panel_deploy_summary_blank.png` | `confirmed_existing` | `cut_9slice_then_import` | `res://assets/ui/shared/panels/ui_shared_panel_summary_card_normal.png` | `ui.shared.panel.summary_card.normal` | `shared.panel.summary_card.normal` | 限制 `ui.art19.panel.deploy_summary` 的页面误用。 |
| `B1_P0_governance_fix` | `P0` | `shared_large_frame_set` | `sources/draw/30_game_ready/ui_panel/ui_panel_terminal_main.png` | `confirmed_existing` | `cut_9slice_then_import` | `res://assets/ui/shared/panels/ui_shared_panel_large_frame_normal.png` | `ui.shared.panel.large_frame.normal` | `shared.panel.large_frame.normal` | 替代 `terminal_main` 的过宽语义。 |
| `B1_P0_governance_fix` | `P0` | `shared_primary_gold_button_set` | `sources/draw/30_game_ready/ui_deploy_button/ui_button_confirm_deploy_large.png` | `confirmed_existing` | `cut_9slice_then_import` | `res://assets/ui/shared/buttons/ui_shared_button_primary_gold_normal.png` | `ui.shared.button.primary_gold.normal` | `shared.button.primary_gold.normal` | 保留 deploy confirm 来源，但建立通用 primary 命名。 |
| `B1_P0_governance_fix` | `P0` | `map_overlay_event_marker_64` | `sources/draw/30_game_ready/icons/64/04_biaoji_qi.png`; 备选 `sources/draw/30_game_ready/map_icon/map_icon_event.png` | `needs_source_selection` | `select_source_then_import` | `res://assets/ui/map_overlay/cells/ui_map_overlay_cell_event_64.png` | `ui.map_overlay.cell.event.64` | `map_overlay.cell.event` | 修正 `ui.art19.map64.scanned` 被当作 event alias 的风险。 |
| `B1_P0_governance_fix` | `P0` | `run_hud_bottom_info_bar_states` | `sources/draw/30_game_ready/ui_summary_bar/ui_bar_blank_dark.png` | `confirmed_existing` | `cut_9slice_then_import` | `res://assets/ui/run_hud/bottom/ui_run_hud_bottom_info_normal.png` | `ui.run_hud.bottom_info.normal` | `run_hud.bottom_info.normal` | 限制 summary bar 在 keybar / info bar 中混用。 |
| `B1_P0_governance_fix` | `P0` | `shared_keycap_set_e_q_f_m_t_esc` | `sources/draw/30_game_ready/ui_key_prompt/ui_key_*.png`，已确认 6 个文件 | `confirmed_existing_set` | `import_named_set` | `res://assets/ui/shared/key_prompts/ui_shared_keycap_e_normal.png` | `ui.shared.keycap.e.normal` | `shared.keycap.e.normal` | 替代纯文字 keybar。 |
| `B1_P0_governance_fix` | `P0` | `shared_slot_frame_states` | `sources/draw/30_game_ready/ui_deploy_panel/ui_frame_highlight.png` | `confirmed_existing` | `cut_state_set_then_import` | `res://assets/ui/shared/slots/ui_shared_slot_frame_selected.png` | `ui.shared.slot.frame.selected` | `shared.slot.frame.selected` | 为 deploy / inventory / longterm 的 slot 与 card 提供状态基础。 |
| `B2_P0_core_pages` | `P0` | `main_menu_background_base_hall` | `sources/draw/30_game_ready/main_menu/main_menu_bg_no_text.png` | `confirmed_existing` | `import_after_crop_policy` | `res://assets/ui/main_menu/backgrounds/ui_main_menu_background_base_hall.png` | `ui.main_menu.background.base_hall` | `main_menu.background.base_hall` | 替代脚本纯色或通用背景 fallback。 |
| `B2_P0_core_pages` | `P0` | `main_menu_entry_button_primary` | `sources/draw/30_game_ready/ui_button_blank/ui_button_blank_dark.png` | `confirmed_existing` | `cut_9slice_then_import` | `res://assets/ui/main_menu/buttons/ui_main_menu_button_entry_primary_normal.png` | `ui.main_menu.button.entry.primary.normal` | `main_menu.button.entry.primary.normal` | 右侧实体大入口按钮。 |
| `B2_P0_core_pages` | `P0` | `deploy_route_card_states` | `sources/draw/30_game_ready/ui_deploy_panel/ui_panel_deploy_main_blank.png`; `sources/draw/30_game_ready/ui_deploy_panel/ui_frame_highlight.png` | `confirmed_existing_set` | `cut_9slice_then_import` | `res://assets/ui/deploy/cards/ui_deploy_route_card_selected.png` | `ui.deploy.card.route.selected` | `deploy.route_card.selected` | 替代纯文本路线卡。 |
| `B2_P0_core_pages` | `P0` | `deploy_primary_tabs` | `sources/draw/30_game_ready/ui_deploy_button/ui_button_nav_*.png`，已确认 5 个文件 | `confirmed_existing_set` | `import_named_tab_set` | `res://assets/ui/deploy/tabs/ui_deploy_tab_loadout_normal.png` | `ui.deploy.tab.loadout.normal` | `deploy.tab.loadout.normal` | 统一一级 tab，不再换行挤占详情区。 |
| `B2_P0_core_pages` | `P0` | `deploy_equipment_slot_and_icons` | `sources/draw/30_game_ready/ui_deploy_icon/ui_icon_*.png`; `item_equipment/*.png`; `item_consumable/*.png` | `confirmed_existing_set` | `import_slot_and_icon_set` | `res://assets/ui/deploy/slots/ui_deploy_slot_equipment_selected.png` | `ui.deploy.slot.equipment.selected` | `deploy.slot.equipment.selected` | 支撑右侧装备和消耗品区域。 |
| `B2_P0_core_pages` | `P0` | `longterm_collection_card_states` | `sources/draw/30_game_ready/ui_panel/ui_panel_terminal_main.png`; `sources/draw/30_game_ready/ui_deploy_panel/ui_frame_highlight.png` | `confirmed_existing_set` | `cut_card_set_then_import` | `res://assets/ui/long_term/cards/ui_longterm_collection_card_locked.png` | `ui.longterm.card.collection.locked` | `longterm.collection_card.locked` | 替代长期系统中间占位格。 |
| `B2_P0_core_pages` | `P0` | `longterm_archive_short_modules` | `sources/draw/30_game_ready/ui_deploy_panel/ui_panel_deploy_summary_blank.png`; `sources/draw/30_game_ready/ui_summary_bar/ui_bar_blank_dark.png` | `confirmed_existing_set` | `cut_9slice_then_import` | `res://assets/ui/long_term/archive_modules/ui_longterm_archive_module_level_normal.png` | `ui.longterm.archive.module.level.normal` | `longterm.archive.level.normal` | 拆分等级、主线、资历、资源、奖励短模块。 |
| `B2_P0_core_pages` | `P0` | `run_hud_left_rail_frame` | `sources/draw/30_game_ready/ui_panel/ui_panel_terminal_main.png`; `sources/draw/30_game_ready/ui_summary_bar/ui_bar_blank_dark.png` | `confirmed_existing_set` | `cut_9slice_then_import` | `res://assets/ui/run_hud/left_rail/ui_run_hud_left_rail_frame.png` | `ui.run_hud.left_rail.frame` | `run_hud.left_rail.frame` | 支撑左侧固定信息栏。 |
| `B2_P0_core_pages` | `P0` | `run_hud_top_right_status_card` | `sources/draw/30_game_ready/ui_deploy_panel/ui_panel_deploy_summary_blank.png` | `confirmed_existing` | `cut_9slice_then_import` | `res://assets/ui/run_hud/status_card/ui_run_hud_status_card_pressure_normal.png` | `ui.run_hud.status_card.pressure.normal` | `run_hud.status_card.pressure.normal` | 替代右侧整列状态栏。 |
| `B2_P0_core_pages` | `P0` | `run_hud_object_tooltip` | `sources/draw/30_game_ready/ui_summary_bar/ui_bar_blank_dark.png` | `confirmed_existing` | `cut_9slice_then_import` | `res://assets/ui/run_hud/tooltips/ui_run_hud_tooltip_object_interaction.png` | `ui.run_hud.tooltip.object_interaction` | `run_hud.tooltip.object_interaction` | 替代大面积中心提示。 |
| `B2_P0_core_pages` | `P0` | `map_overlay_expanded_panel` | `sources/draw/30_game_ready/ui_panel/ui_panel_terminal_main.png` | `confirmed_existing` | `cut_9slice_then_import` | `res://assets/ui/map_overlay/panels/ui_map_overlay_panel_expanded_map.png` | `ui.map_overlay.panel.expanded_map` | `map_overlay.panel.expanded_map` | 支撑小地图展开后的可见大地图面板。 |
| `B3_P1_followup_pages` | `P1` | `deploy_background_staging_hall` | `sources/draw/30_game_ready/rooms/fangjian_jichu_1024.png` | `needs_visual_fit_review` | `select_or_defer` | `res://assets/ui/deploy/backgrounds/ui_deploy_background_staging_hall.png` | `ui.deploy.background.staging_hall` | `deploy.background.staging_hall` | 文件存在，但是否符合准备大厅语义待审；不合适则延后。 |
| `B3_P1_followup_pages` | `P1` | `longterm_background_archive_room` | `sources/draw/30_game_ready/rooms/fangjian_jichu_1024.png` | `needs_visual_fit_review` | `select_or_defer` | `res://assets/ui/long_term/backgrounds/ui_longterm_background_archive_room.png` | `ui.longterm.background.archive_room` | `longterm.background.archive_room` | 文件存在，但是否符合档案室语义待审；不合适则延后。 |
| `B3_P1_followup_pages` | `P1` | `inventory_backpack_panel` | `sources/draw/30_game_ready/ui_panel/ui_panel_terminal_main.png` | `confirmed_existing` | `cut_9slice_then_import` | `res://assets/ui/inventory/panels/ui_inventory_panel_backpack.png` | `ui.inventory.panel.backpack` | `inventory.panel.backpack` | 背包面板跟随 shared panel 体系。 |
| `B3_P1_followup_pages` | `P1` | `ground_loot_pickup_card` | `sources/draw/30_game_ready/ui_summary_bar/ui_bar_blank_dark.png`; `sources/draw/30_game_ready/props/*.png`，props 已确认 13 个文件但具体物品未选定 | `needs_source_selection` | `select_source_then_import` | `res://assets/ui/ground_loot/cards/ui_ground_loot_card_pickup_normal.png` | `ui.ground_loot.card.pickup.normal` | `ground_loot.card.pickup.normal` | 地面拾取卡需要先选择具体 props 来源，并和 Run tooltip 区分。 |
| `B4_P2_result` | `P2` | `result_title_plate_set` | `sources/draw/30_game_ready/ui_title_plate/ui_title_*.png`，已确认 3 个文件 | `confirmed_existing_set` | `import_named_title_set` | `res://assets/ui/result/title_plates/ui_result_title_extraction_success.png` | `ui.result.title.extraction_success` | `result.title.extraction_success` | 结果界面标题牌，低优先级。 |

## 5. P0 重点说明

- `B1_P0_governance_fix` 用于纠偏 ART-19 已接入素材的命名和复用边界。
- `B2_P0_core_pages` 用于补齐四核心界面的基础组件。
- P0 中仍标记 `needs_source_selection` 的项目不能直接导入，必须先做来源选择。
- 所有 P0 项目在真实导入前仍需生成 source hash、runtime hash、manifest diff 和截图验证。

## 6. 暂缓或需选择内容

- `deploy_background_staging_hall` 与 `longterm_background_archive_room` 只能作为 P1 待审候选，不能把普通房间图硬说成准备大厅或档案室。
- `ground_loot_pickup_card` 中的 props 候选需要先确认具体物品语义。
- `result_title_plate_set` 是 P2，不阻塞核心页面组件治理。
- `scrollbar_vertical` 继续 reserved/defer，不进入本轮下一批导入。
- `debug_detected_boxes.png` 和检测框类图片不进入 runtime。

## 7. 后续导入前检查清单

后续进入真实 runtime 导入前，必须逐项确认：

- source 文件存在且记录 source sha256。
- source_status 不是 `needs_source_selection` 或 `needs_visual_fit_review`，除非审计已单独放行。
- 切片规格存在并确认尺寸、九宫格、拉伸策略。
- runtime 文件名符合命名规范。
- target runtime path 未冲突。
- asset_id 唯一。
- visual_key 不误导页面职责。
- manifest diff 可审计。
- UI 代码不直接读取 `sources/art` 或 `sources/draw`。
- 1280x720 截图确认没有错位、遮挡、文字溢出或错误复用。