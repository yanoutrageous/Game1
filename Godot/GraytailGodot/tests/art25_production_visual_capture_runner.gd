extends SceneTree

const WorldObjectProjectionScript := preload("res://scripts/gameplay/runtime/g41_world_object_projection.gd")
const EventServiceScript := preload("res://scripts/core/run/event_service.gd")

# Diagnostic capture only. This runner instantiates main.tscn and operates the
# production RunScene nodes; it is evidence for iteration, never a substitute
# for the frozen Computer Use acceptance pass.


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var width := int(options.get("width", 1280))
	var height := int(options.get("height", 720))
	var state := StringName(options.get("state", "run"))
	var output := String(options.get("output", "res://art25_production_capture.png"))
	# Each invocation is a disposable capture process. Pinning the setting here
	# makes normal and reduced-motion evidence deterministic without persisting a
	# player preference or replacing any production presentation node.
	ProjectSettings.set_setting("accessibility/reduce_motion", state in [&"reduced_motion", &"monster_reduced_motion"])
	root.size = Vector2i(width, height)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.transparent_bg = false

	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	if main_scene == null:
		_fail("main.tscn could not be loaded")
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	await _frames(16)
	var run_scene := main.get_node_or_null("RunScene")
	if run_scene == null:
		_fail("RunScene missing")
		return
	run_scene.call("_start_standard_from_ui")
	await _frames(18)
	if state in [&"inventory_items", &"exit_confirm"]:
		if not _seed_item_preview_inventory(run_scene):
			return
		run_scene.call("_refresh_view_models")
		await _frames(5)

	match state:
		&"run":
			pass
		&"map":
			run_scene.call("_open_map_from_ui", &"art25_capture")
		&"inventory", &"inventory_items":
			run_scene.call("_show_inventory_panel")
		&"chest", &"chest_open":
			if not await _teleport_and_focus(run_scene, &"Chest", WorldObjectProjectionScript.CHEST_LOCAL_POS):
				return
			if state == &"chest_open":
				run_scene.call("_handle_interact_pressed")
				await _frames(4)
		&"event", &"event_options":
			if not await _teleport_and_focus(run_scene, &"Event", WorldObjectProjectionScript.EVENT_LOCAL_POS):
				return
			if state == &"event_options":
				run_scene.call("_handle_interact_pressed")
				await _frames(4)
		&"event_merchant":
			if not await _teleport_and_focus(run_scene, &"Event", WorldObjectProjectionScript.EVENT_LOCAL_POS):
				return
			if not await _configure_full_merchant(run_scene):
				return
		&"monster", &"reduced_motion", &"monster_reduced_motion":
			if not await _teleport_to_room(run_scene, &"Monster"):
				return
			if state in [&"reduced_motion", &"monster_reduced_motion"] and not _has_reduced_motion_enemy(run_scene):
				_fail("production Monster view did not enter reduced-motion presentation")
				return
		&"mine":
			if not await _teleport_and_focus(run_scene, &"Mine", WorldObjectProjectionScript.MINE_LOCAL_POS):
				return
		&"exit", &"exit_confirm":
			if not await _teleport_and_focus(run_scene, &"Exit", WorldObjectProjectionScript.EXIT_LOCAL_POS):
				return
			if state == &"exit_confirm":
				run_scene.call("_handle_interact_pressed")
				await _frames(5)
		&"ground_loot":
			var loot_view = run_scene.get("room_runtime_view")
			var loot_player = run_scene.get("player_controller")
			var run_context = run_scene.get("run_context")
			if loot_view != null and loot_player != null and run_context != null:
				var snapshot: Dictionary = run_context.get_status_snapshot()
				snapshot["room_floor_items"] = [{
					"instance_id": "art25_capture_emergency_bandage",
					"item_id": "emergency_bandage",
					"display_name": "应急绷带",
					"short_description": "恢复少量生命的作业消耗品。",
					"rarity": "普通",
					"weight": 1,
					"base_value": 16,
				}]
				snapshot["backpack_remaining"] = 8
				snapshot["inventory_items"] = []
				loot_view.configure_room(snapshot)
				await _frames(3)
				var entity = loot_view.ground_loot_entities.get("art25_capture_emergency_bandage")
				if entity != null:
					loot_player.set_local_position(entity.local_pos)
					loot_view.advance(0.0, loot_player.get_local_position(), {})
		&"result_success", &"result_success_empty", &"result_failure", &"result_salvage", &"result_failure_empty", &"result_failure_mixed", &"result_failure_final", &"result_failure_final_empty", &"result_abandon", &"result_abandon_empty", &"result_save_failed", &"result_save_recovered":
			var result_panel = run_scene.get("result_panel")
			if result_panel == null:
				_fail("production ResultPanel missing")
				return
			if state == &"result_save_recovered":
				var failed_snapshot := _result_snapshot(&"result_save_failed")
				failed_snapshot["result_id"] = "art25-result-save-retry"
				result_panel.show_summary(failed_snapshot)
				await _frames(3)
				var recovered_snapshot := failed_snapshot.duplicate(true)
				recovered_snapshot["persistence_state"] = &"committed"
				recovered_snapshot["normal_exit_allowed"] = true
				recovered_snapshot["retry_save_allowed"] = false
				recovered_snapshot["discard_unsaved_allowed"] = false
				recovered_snapshot["meta_progress_commit"] = {"ok": true, "status": &"committed", "committed": true}
				result_panel.update_persistence_state(recovered_snapshot)
			else:
				result_panel.show_summary(_result_snapshot(state))
			var result_focus := result_panel.preferred_focus_control() as Control
			if result_focus == null:
				_fail("production ResultPanel exposed no preferred focus for %s" % String(state))
				return
			result_focus.grab_focus()
		_:
			_fail("unknown state: %s" % String(state))
			return
	await _frames(14)
	if state.begins_with("result_"):
		var production_result = run_scene.get("result_panel")
		var expected_focus := production_result.preferred_focus_control() as Control if production_result != null else null
		if expected_focus == null or root.gui_get_focus_owner() != expected_focus:
			_fail("production ResultPanel focus is not visible for %s" % String(state))
			return
		if state == &"result_abandon" and _has_partially_visible_result_section(production_result):
			_fail("result_abandon leaves a half-clipped item section in the initial viewport")
			return
		if not _result_layout_is_safe(production_result, state, Vector2i(width, height)):
			return
	if state == &"event_merchant" and not _merchant_layout_is_safe(run_scene):
		return
	if state == &"inventory_items" and not _inventory_item_preview_is_safe(run_scene):
		return
	if state == &"exit_confirm" and not _extract_item_preview_is_safe(run_scene):
		return

	var image := root.get_texture().get_image()
	if image == null:
		_fail("renderer returned no image")
		return
	if image.get_width() != width or image.get_height() != height:
		_fail("capture size mismatch: requested=%dx%d actual=%dx%d" % [width, height, image.get_width(), image.get_height()])
		return
	var output_path := output if output.is_absolute_path() else ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var result := image.save_png(output_path)
	if result != OK:
		_fail("capture failed: %s" % error_string(result))
		return
	print("ART25_PRODUCTION_CAPTURE=PASS state=%s size=%dx%d output=%s" % [String(state), image.get_width(), image.get_height(), output_path])
	quit(0)


func _result_snapshot(state: StringName) -> Dictionary:
	var kept_rare := _result_item("capture_kept_rare", "密封记录盒", &"tier_5", 2, &"collectible", 5)
	var kept_common := _result_item("capture_kept_common", "旧齿轮组", &"tier_2", 1, &"collectible", 2)
	var floor_item := _result_item("capture_floor", "遗落线圈", &"tier_3", 1, &"collectible", 3)
	var consumable := _result_item("capture_consumable", "应急药剂", &"tier_1", 1, &"consumable")
	var failure_salvaged := _result_item("capture_salvaged", "稀有测绘仪", &"tier_4", 2, &"collectible", 4)
	var failure_lost := _result_item("capture_lost", "旧式继电器", &"tier_2", 1, &"collectible", 2)
	var failure_floor := _result_item("capture_failure_floor", "遗落样本", &"tier_3", 1, &"collectible", 3)
	match state:
		&"result_success":
			return {
				"outcome": "Extracted", "terminal_reason_code": &"extracted", "run_black_coin": 36, "backpack_used": 3, "backpack_capacity": 10,
				"settlement": {"outcome": "success", "black_coin_converted": 36, "gold_coin_gained": 36, "safe_yield": 36, "warehouse_items": [kept_rare, kept_common], "room_floor_lost_items": [floor_item], "cleared_consumables": [consumable], "salvaged_items": [], "lost_items": [], "lost_item_count": 0, "finalized": true},
				"event_log": [], "transaction_log": [], "meta_progress_commit": {"status": &"committed"},
			}
		&"result_success_empty":
			return {
				"outcome": "Extracted", "terminal_reason_code": &"extracted", "run_black_coin": 0, "backpack_used": 0, "backpack_capacity": 10,
				"settlement": {"outcome": "success", "black_coin_converted": 0, "gold_coin_gained": 0, "safe_yield": 0, "warehouse_items": [], "room_floor_lost_items": [], "cleared_consumables": [], "salvaged_items": [], "lost_items": [], "lost_item_count": 0, "finalized": true},
				"event_log": [], "transaction_log": [], "meta_progress_commit": {"status": &"committed"},
			}
		&"result_failure_empty":
			return {
				"outcome": "Failed", "terminal_reason_code": &"fatal_mine", "run_black_coin": 0, "backpack_used": 0, "backpack_capacity": 10,
				"settlement": {"outcome": "failure", "black_coin_lost": 0, "gold_coin_gained": 0, "salvaged_items": [], "lost_items": [], "room_floor_lost_items": [], "requires_salvage_selection": true, "finalized": false, "salvage_capacity": 2, "settlement_pool": []},
				"event_log": [], "transaction_log": [], "meta_progress_commit": {"status": &"awaiting_salvage_confirmation"},
			}
		&"result_salvage", &"result_failure_mixed":
			return {
				"outcome": "Failed", "terminal_reason_code": &"fatal_mine", "run_black_coin": 36, "backpack_used": 4, "backpack_capacity": 10,
				"settlement": {"outcome": "failure", "black_coin_lost": 36, "gold_coin_gained": 0, "salvaged_items": [], "lost_items": [], "room_floor_lost_items": [failure_floor], "requires_salvage_selection": true, "finalized": false, "salvage_capacity": 2, "settlement_pool": [failure_salvaged, failure_lost, kept_common]},
				"event_log": [], "transaction_log": [], "meta_progress_commit": {"status": &"awaiting_salvage_confirmation"},
			}
		&"result_abandon":
			return {
				"outcome": "Abandoned", "terminal_reason_code": &"player_pause_exit_current_run", "run_black_coin": 18, "backpack_used": 2, "backpack_capacity": 10,
				"settlement": {"outcome": "abandon", "black_coin_lost": 18, "gold_coin_gained": 0, "salvaged_items": [], "lost_items": [failure_lost], "room_floor_lost_items": [floor_item], "cleared_consumables": [consumable], "lost_item_count": 1, "finalized": true},
				"event_log": [], "transaction_log": [], "meta_progress_commit": {"status": &"duplicate_ignored"},
			}
		&"result_save_failed":
			return {
				"outcome": "Failed", "terminal_reason_code": &"runtime_combat_defeat", "run_black_coin": 36, "backpack_used": 0, "backpack_capacity": 10,
				"settlement": {"outcome": "failure", "black_coin_lost": 36, "gold_coin_gained": 0, "salvaged_items": [failure_salvaged], "lost_items": [failure_lost], "room_floor_lost_items": [failure_floor], "cleared_consumables": [consumable], "lost_item_count": 1, "finalized": true},
				"event_log": [], "transaction_log": [],
				"persistence_state": &"save_failed", "normal_exit_allowed": false, "retry_save_allowed": true, "discard_unsaved_allowed": true,
				"meta_progress_commit": {"ok": false, "status": &"save_failed", "committed": false},
			}
		&"result_failure_final_empty":
			return {
				"outcome": "Failed", "terminal_reason_code": &"runtime_combat_defeat", "run_black_coin": 0, "backpack_used": 0, "backpack_capacity": 10,
				"settlement": {"outcome": "failure", "black_coin_lost": 0, "gold_coin_gained": 0, "salvaged_items": [], "lost_items": [], "room_floor_lost_items": [], "cleared_consumables": [], "lost_item_count": 0, "finalized": true},
				"event_log": [], "transaction_log": [], "meta_progress_commit": {"status": &"committed"},
			}
		&"result_abandon_empty":
			return {
				"outcome": "Abandoned", "terminal_reason_code": &"player_pause_exit_current_run", "run_black_coin": 0, "backpack_used": 0, "backpack_capacity": 10,
				"settlement": {"outcome": "abandon", "black_coin_lost": 0, "gold_coin_gained": 0, "salvaged_items": [], "lost_items": [], "room_floor_lost_items": [], "cleared_consumables": [], "lost_item_count": 0, "finalized": true},
				"event_log": [], "transaction_log": [], "meta_progress_commit": {"status": &"duplicate_ignored"},
			}
		_: # result_failure and result_failure_final are committed final failures.
			return {
				"outcome": "Failed", "terminal_reason_code": &"fatal_mine", "run_black_coin": 36, "backpack_used": 0, "backpack_capacity": 10,
				"settlement": {"outcome": "failure", "black_coin_lost": 36, "gold_coin_gained": 0, "salvaged_items": [failure_salvaged], "lost_items": [failure_lost], "room_floor_lost_items": [failure_floor], "cleared_consumables": [consumable], "lost_item_count": 1, "finalized": true},
				"event_log": [], "transaction_log": [], "meta_progress_commit": {"status": &"committed"},
			}


func _result_item(instance_id: String, display_name: String, rarity: StringName, weight: int, item_type: StringName = &"collectible", collectible_level: int = 0) -> Dictionary:
	var item := {
		"instance_id": instance_id,
		"item_id": instance_id,
		"display_name": display_name,
		"short_description": "用于生产结算画面检查的权威夹具物资。",
		"item_type": item_type,
		"rarity": rarity,
		"weight": weight,
		"base_value": 20,
	}
	if collectible_level > 0:
		item["collectible_level"] = collectible_level
	return item


func _seed_item_preview_inventory(run_scene: Node) -> bool:
	var run_context = run_scene.get("run_context")
	if run_context == null or run_context.get("asset_ledger") == null:
		_fail("production item-preview state has no RunAssetLedger")
		return false
	var ledger = run_context.get("asset_ledger")
	ledger.create_item_instance({
		"instance_id": "capture_preview_collectible",
		"item_id": "sealed_field_archive",
		"display_name": "密封现场档案",
		"short_description": "撤离后进入仓库的现场藏品。",
		"item_type": &"collectible",
		"rarity": &"tier_4",
		"collectible_level": 4,
		"weight": 2,
		"base_value": 48,
	}, RunAssetLedger.LOCATION_INVENTORY)
	ledger.create_item_instance({
		"instance_id": "capture_preview_consumable",
		"item_id": "emergency_bandage",
		"display_name": "应急绷带",
		"short_description": "没有收藏等级的现场消耗品。",
		"item_type": &"consumable",
		"rarity": &"tier_1",
		"weight": 1,
		"base_value": 12,
		"can_consume": true,
	}, RunAssetLedger.LOCATION_INVENTORY)
	return true


func _inventory_item_preview_is_safe(run_scene: Node) -> bool:
	var inventory = run_scene.get("inventory_panel") as Control
	var marker := inventory.find_child("InventoryItemRarityMarker", true, false) as ColorRect if inventory != null else null
	var detail := inventory.get("tooltip_label") as Label if inventory != null else null
	if inventory == null or not inventory.visible or marker == null or detail == null:
		_fail("production inventory item preview is incomplete")
		return false
	if not detail.text.contains("收藏等级：4"):
		_fail("production inventory omitted the authoritative collectible level")
		return false
	return true


func _extract_item_preview_is_safe(run_scene: Node) -> bool:
	var extract_panel = run_scene.get("extract_panel") as Control
	var rows := extract_panel.find_children("ExtractCarriedItemRow*", "", true, false) if extract_panel != null else []
	if extract_panel == null or not extract_panel.visible or rows.size() < 2:
		_fail("production extract confirmation omitted carried item rows")
		return false
	var first := rows[0] as PanelContainer
	var meta := first.find_child("ExtractItemMeta", true, false) as Label
	var marker := first.find_child("ExtractItemRarityMarker", true, false) as ColorRect
	if meta == null or not meta.text.contains("收藏等级 4") or not meta.text.contains("[T4] 珍贵") or marker == null:
		_fail("production extract confirmation omitted rarity or collectible-level identity")
		return false
	return true


func _teleport_to_room(run_scene, room_type: StringName) -> bool:
	run_scene.call("_debug_teleport_to_room_type", room_type)
	await _frames(8)
	var run_context = run_scene.get("run_context")
	if run_context == null:
		_fail("production RunContext missing for %s capture" % String(room_type))
		return false
	var snapshot: Dictionary = run_context.get_status_snapshot()
	if StringName(snapshot.get("current_room", &"Unknown")) != room_type:
		_fail("production map could not enter %s room" % String(room_type))
		return false
	return true


func _teleport_and_focus(run_scene, room_type: StringName, local_pos: Vector2) -> bool:
	if not await _teleport_to_room(run_scene, room_type):
		return false
	var room_view = run_scene.get("room_runtime_view")
	var player = run_scene.get("player_controller")
	if room_view == null or player == null:
		_fail("production room/player view missing for %s capture" % String(room_type))
		return false
	player.set_local_position(local_pos)
	room_view.advance(0.0, player.get_local_position(), {})
	await _frames(3)
	return true


func _configure_full_merchant(run_scene) -> bool:
	var context = run_scene.get("run_context")
	if context == null:
		_fail("production RunContext missing for merchant capture")
		return false
	var original_seed := int(context.seed_value)
	for seed_offset in range(4):
		context.seed_value = original_seed + seed_offset
		if EventServiceScript.get_event_type(context, context.current_pos) == &"trader":
			break
	var actual_event_type := EventServiceScript.get_event_type(context, context.current_pos)
	if actual_event_type != &"trader":
		_fail("merchant fixture did not resolve a production trader event_type")
		return false
	var all_options := EventServiceScript.get_event_options(context, context.current_pos, &"trader", false)
	if all_options.size() != 5:
		_fail("production trader option authority exposed %d options instead of five" % all_options.size())
		return false
	context.event_state = {
		"event_type": actual_event_type,
		"completed": false,
		"options": all_options.duplicate(true),
	}
	run_scene.call("_apply_full_view_models")
	var room_view = run_scene.get("room_runtime_view")
	var player = run_scene.get("player_controller")
	if room_view != null and player != null:
		room_view.advance(0.0, player.get_local_position(), {})
	await _frames(5)
	var run_surface = run_scene.get("run_surface")
	var steady_buttons: Array = run_surface.get("encounter_option_buttons") if run_surface != null else []
	if not steady_buttons.is_empty():
		_fail("production merchant duplicated %d decisions in the steady HUD" % steady_buttons.size())
		return false
	var popup = room_view.get("context_popup") if room_view != null else null
	if popup == null or not popup.visible or popup.context_kind != &"event":
		_fail("production merchant did not expose its proximity context entry")
		return false
	if not bool(popup.activate_primary()):
		_fail("production merchant context entry did not open its decision modal")
		return false
	await _frames(5)
	if not bool(run_scene.call("_runtime_modal_is_top", &"event")):
		_fail("production merchant decision modal is not authoritative")
		return false
	var event_options = run_scene.get("event_options_box") as Control
	var modal_buttons: Array[Button] = []
	if event_options != null:
		for child in event_options.get_children():
			if child is Button:
				modal_buttons.append(child as Button)
	if modal_buttons.size() != 5:
		_fail("production merchant modal exposed %d options instead of all five" % modal_buttons.size())
		return false
	return true


func _merchant_layout_is_safe(run_scene) -> bool:
	var run_surface = run_scene.get("run_surface")
	if run_surface == null:
		_fail("production RunSurface missing for merchant layout check")
		return false
	var panel := run_scene.get("event_panel") as Control
	var action_bar := run_surface.get("action_bar") as Control
	var stable_panel := run_surface.get("encounter_backdrop") as Control
	var stable_grid := run_surface.get("encounter_options_box") as Control
	var stable_buttons: Array = run_surface.get("encounter_option_buttons")
	var option_box := run_scene.get("event_options_box") as Control
	var buttons: Array[Button] = []
	if option_box != null:
		for child in option_box.get_children():
			if child is Button:
				buttons.append(child as Button)
	if panel == null or action_bar == null or stable_panel == null or stable_grid == null or option_box == null or buttons.size() != 5:
		_fail("merchant layout check is missing production controls")
		return false
	if not bool(run_scene.call("_runtime_modal_is_top", &"event")) or not panel.visible:
		_fail("merchant decisions are not hosted by the focused Event modal")
		return false
	if not stable_buttons.is_empty() or stable_panel.visible or stable_grid.visible:
		_fail("merchant Event modal left a duplicate steady-HUD decision strip")
		return false
	if action_bar.is_visible_in_tree():
		_fail("merchant Event modal left the stable action dock visible underneath")
		return false
	var panel_rect := panel.get_global_rect()
	var option_copies: Dictionary = {}
	for button in buttons:
		if button == null or not panel_rect.encloses(button.get_global_rect()):
			_fail("merchant option escaped the focused Event modal")
			return false
		if button.focus_mode != Control.FOCUS_ALL:
			_fail("merchant modal option is not keyboard/gamepad focusable")
			return false
		option_copies[button.text] = true
	if option_copies.size() != 5:
		_fail("merchant options do not expose all five distinct player-facing decisions")
		return false
	return true


func _has_reduced_motion_enemy(run_scene) -> bool:
	var room_view = run_scene.get("room_runtime_view")
	if room_view == null:
		return false
	for enemy_view in room_view.enemy_views.values():
		if enemy_view != null and enemy_view.has_method("appearance_snapshot"):
			var appearance: Dictionary = enemy_view.appearance_snapshot()
			if bool(appearance.get("reduced_motion", false)):
				return true
	return false


func _has_partially_visible_result_section(result_panel) -> bool:
	if result_panel == null:
		return false
	var scroll := result_panel.get_node_or_null("ResultItemSectionsScroll") as ScrollContainer
	var sections := result_panel.get_node_or_null("ResultItemSectionsScroll/ResultItemSections") as VBoxContainer
	if scroll == null or sections == null:
		return true
	var viewport_rect := scroll.get_global_rect()
	for child in sections.get_children():
		if not (child is Control) or not (child as Control).visible:
			continue
		var section_rect := (child as Control).get_global_rect()
		var intersects := section_rect.end.y > viewport_rect.position.y + 0.5 and section_rect.position.y < viewport_rect.end.y - 0.5
		if intersects and (section_rect.position.y < viewport_rect.position.y - 0.5 or section_rect.end.y > viewport_rect.end.y + 0.5):
			return true
	return false


func _result_layout_is_safe(result_panel, state: StringName, viewport_size: Vector2i) -> bool:
	if result_panel == null:
		_fail("result layout validation has no ResultPanel")
		return false
	var modal := result_panel.get_node_or_null("ResultModalFrame") as Control
	var banner := result_panel.get_node_or_null("ResultTitlePlate") as TextureRect
	var title := result_panel.get_node_or_null("ResultTitle") as Label
	var summary := result_panel.get_node_or_null("ResultSummary") as Label
	var items := result_panel.get_node_or_null("ResultItemSectionsScroll") as ScrollContainer
	if modal == null or banner == null or title == null or summary == null or items == null:
		_fail("result layout validation is missing a required surface")
		return false
	var source_ratio := 520.0 / 120.0
	var banner_ratio := banner.size.x / maxf(1.0, banner.size.y)
	if absf(banner_ratio - source_ratio) / source_ratio > 0.02 or title.get_theme_font_size("font_size") < 24:
		_fail("result banner/title hierarchy drifted for %s" % String(state))
		return false
	if summary.visible and summary.get_global_rect().position.y - banner.get_global_rect().end.y > 16.0:
		_fail("result summary detached from banner for %s" % String(state))
		return false
	var empty_final := state in [&"result_success_empty", &"result_failure_final_empty", &"result_abandon_empty"]
	if empty_final and (items.visible or (viewport_size == Vector2i(1280, 720) and modal.size.y > 500.0)):
		_fail("empty final result retained an item well or oversized modal for %s" % String(state))
		return false
	if state == &"result_failure_empty":
		var empty_notice := result_panel.find_child("FailureSalvageEmptyNotice", true, false) as Control
		var confirm := result_panel.get("salvage_confirm_button") as Button
		if empty_notice == null or confirm == null or confirm.get_global_rect().position.y - empty_notice.get_global_rect().end.y > 48.0:
			_fail("empty salvage confirmation is detached from its explanation")
			return false
	if state == &"result_save_recovered":
		if not result_panel.normal_exit_allowed() or result_panel.retry_save_button.visible or not result_panel.return_deploy_button.visible:
			_fail("save retry visual did not transition to committed actions")
			return false
	return true


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var result := {}
	for argument in arguments:
		var token := String(argument)
		if not token.begins_with("--") or not token.contains("="):
			continue
		var separator := token.find("=")
		result[token.substr(2, separator - 2)] = token.substr(separator + 1)
	return result


func _fail(message: String) -> void:
	push_error("ART25_PRODUCTION_CAPTURE:%s" % message)
	quit(2)
