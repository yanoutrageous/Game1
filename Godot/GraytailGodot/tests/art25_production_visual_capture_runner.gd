extends SceneTree

const WorldObjectProjectionScript := preload("res://scripts/gameplay/runtime/g41_world_object_projection.gd")
const EventServiceScript := preload("res://scripts/core/run/event_service.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const WAIT_TIMEOUT_MS := 5000

# Diagnostic capture only. This runner instantiates main.tscn and operates the
# production RunScene nodes; it is evidence for iteration, never a substitute
# for the frozen Computer Use acceptance pass.

var batch_mode := false
var batch_failure := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	if options.has("batch-manifest"):
		batch_mode = true
		await _capture_batch(options)
		return
	await _capture_one(options)


func _capture_batch(options: Dictionary) -> void:
	var manifest_path := String(options.get("batch-manifest", ""))
	if not manifest_path.is_absolute_path():
		manifest_path = ProjectSettings.globalize_path(manifest_path)
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		_fail("batch manifest could not be opened: %s" % manifest_path)
		quit(2)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("batch manifest root is not an object")
		quit(2)
		return
	var requests := (parsed as Dictionary).get("requests", []) as Array
	if requests.is_empty():
		_fail("batch manifest contains no requests")
		quit(2)
		return
	var captured := 0
	for raw_request in requests:
		if not raw_request is Dictionary:
			_fail("batch request %d is not an object" % captured)
			break
		batch_failure = ""
		await _capture_one((raw_request as Dictionary).duplicate(true))
		if not batch_failure.is_empty():
			break
		captured += 1
	if not batch_failure.is_empty() or captured != requests.size():
		printerr(
			"ART25_PRODUCTION_BATCH=FAIL captured=%d requested=%d reason=%s"
			% [captured, requests.size(), batch_failure]
		)
		quit(2)
		return
	print(
		"ART25_PRODUCTION_BATCH=PASS states=%d manifest=%s"
		% [captured, manifest_path]
	)
	quit(0)


func _capture_one(options: Dictionary) -> void:
	var width := int(options.get("width", 1280))
	var height := int(options.get("height", 720))
	var ui_scale := Art10UISkinKitScript.set_runtime_ui_scale_factor(
		float(options.get("ui-scale", 1.0))
	)
	var state := StringName(options.get("state", "run"))
	var output := String(options.get("output", "res://art25_production_capture.png"))
	var debug_state := state in [
		&"debug_settings",
		&"debug_sandbox",
		&"debug_panel",
		&"debug_matrix",
		&"debug_scenario_quad",
	]
	var debug_panel_requested := (
		state == &"debug_panel"
		or (
			state == &"debug_matrix"
			and String(options.get("panel", "collapsed")) == "expanded"
		)
	)
	# Each invocation is a disposable capture process. Pinning the setting here
	# makes normal and reduced-motion evidence deterministic without persisting a
	# player preference or replacing any production presentation node.
	ProjectSettings.set_setting("accessibility/reduce_motion", state in [&"reduced_motion", &"monster_reduced_motion"])
	ProjectSettings.set_setting("application/run/m1_debug_tools_enabled", debug_state)
	root.size = Vector2i(width, height)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.transparent_bg = false

	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	if main_scene == null:
		_fail("main.tscn could not be loaded")
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	if not await _await_condition(
		func() -> bool: return main.get_node_or_null("RunScene") != null,
		"production RunScene creation"
	):
		return
	var run_scene := main.get_node_or_null("RunScene")
	if run_scene == null:
		_fail("RunScene missing")
		return
	if not bool(run_scene.call("set_ui_scale_factor", ui_scale)):
		_fail("production RunScene rejected requested UI scale %.2f" % ui_scale)
		return
	if not await _await_condition(
		func() -> bool:
			var app_shell = run_scene.get("ui_shell")
			return (
				is_equal_approx(float(run_scene.call("get_ui_scale_factor")), ui_scale)
				and app_shell != null
				and is_equal_approx(float(app_shell.call("get_ui_scale_factor")), ui_scale)
			),
		"production UI scale %.2f" % ui_scale
	):
		return
	if state == &"main_menu":
		if not await _await_condition(
			func() -> bool: return StringName(run_scene.get("screen_state")) == &"main_menu",
			"production main menu"
		):
			return
	elif state == &"settings":
		if not bool(run_scene.call("_show_settings_shell")):
			_fail("production settings could not open")
			return
		if not await _await_condition(
			func() -> bool: return StringName(run_scene.get("screen_state")) == &"settings_shell",
			"production settings"
		):
			return
	elif debug_state:
		if not await _prepare_debug_state(run_scene, state, options):
			return
	else:
		run_scene.call("_start_standard_from_ui")
		if not await _await_condition(
			func() -> bool:
				var context = run_scene.get("run_context")
				return StringName(run_scene.get("screen_state")) == &"run" and context != null and bool(context.get("run_active")),
			"standard run admission"
		):
			return
	if state in [&"inventory_items", &"exit_confirm"]:
		if not _seed_item_preview_inventory(run_scene):
			return
		run_scene.call("_refresh_view_models")
		if not await _await_layout_stable(run_scene, "seeded item preview"):
			return
	if state in [
		&"quick_bag_empty",
		&"quick_bag_one",
		&"quick_bag_three",
		&"quick_bag_overflow",
	]:
		var row_count := int({
			&"quick_bag_empty": 0,
			&"quick_bag_one": 1,
			&"quick_bag_three": 3,
			&"quick_bag_overflow": 4,
		}.get(state, 0))
		if not _seed_quick_bag_inventory(run_scene, row_count):
			return
		run_scene.call("_refresh_view_models")
		if not await _await_layout_stable(run_scene, "quick-bag fixture %s" % String(state)):
			return
	if state == &"debug_scenario_quad":
		if not await _capture_debug_scenario_quad(
			run_scene,
			options,
			width,
			height,
			ui_scale
		):
			return
		if batch_mode:
			main.queue_free()
			await main.tree_exited
			await process_frame
			return
		quit(0)
		return

	match state:
		&"run", &"main_menu", &"settings":
			pass
		&"debug_settings", &"debug_sandbox", &"debug_panel", &"debug_matrix":
			pass
		&"quick_bag_empty", &"quick_bag_one", &"quick_bag_three", &"quick_bag_overflow":
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
				if not await _await_condition(
					func() -> bool:
						var context = run_scene.get("run_context")
						var room_view = run_scene.get("room_runtime_view")
						var popup = room_view.get("context_popup") if room_view != null else null
						var snapshot: Dictionary = context.get_status_snapshot() if context != null else {}
						var search_data: Dictionary = snapshot.get("search_state_data", {})
						return (
							bool(search_data.get("searched", false))
							and popup != null
							and popup.visible
							and popup.context_kind == &"chest"
							and bool(popup.current_context.get("opened_once", false))
							and popup.context_items.size() > 0
						),
					"opened chest contextual contents"
				):
					return
		&"event", &"event_options":
			if not await _teleport_and_focus(run_scene, &"Event", WorldObjectProjectionScript.EVENT_LOCAL_POS):
				return
			if state == &"event_options":
				run_scene.call("_handle_interact_pressed")
				if not await _await_condition(
					func() -> bool: return bool(run_scene.call("_runtime_modal_is_top", &"event")),
					"event option modal"
				):
					return
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
				if not await _await_condition(
					func() -> bool: return bool(run_scene.call("_runtime_modal_is_top", &"extract_confirm")),
					"extract confirmation modal"
				):
					return
		&"ground_loot", &"ground_loot_visual":
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
				if not await _await_condition(
					func() -> bool: return loot_view.ground_loot_entities.has("art25_capture_emergency_bandage"),
					"ground-loot world entity"
				):
					return
				var entity = loot_view.ground_loot_entities.get("art25_capture_emergency_bandage")
				if entity != null:
					var target_pos: Vector2 = entity.local_pos
					if state == &"ground_loot_visual":
						target_pos.x = clampf(target_pos.x - 0.18, 0.12, 0.88)
					loot_player.set_local_position(target_pos)
					loot_view.advance(0.0, loot_player.get_local_position(), {})
		&"pause":
			run_scene.call("_show_pause_panel")
			if not await _await_condition(
				func() -> bool: return bool(run_scene.call("_runtime_modal_is_top", &"pause")),
				"pause modal"
			):
				return
		&"pause_settings":
			run_scene.call("_show_pause_panel")
			if not await _await_condition(
				func() -> bool: return bool(run_scene.call("_runtime_modal_is_top", &"pause")),
				"pause modal before settings"
			):
				return
			run_scene.call("_open_settings_from_pause")
			if not await _await_condition(
				func() -> bool: return bool(run_scene.call("_runtime_modal_is_top", &"settings")),
				"run settings modal"
			):
				return
		&"result_success", &"result_success_empty", &"result_failure", &"result_salvage", &"result_failure_empty", &"result_failure_mixed", &"result_failure_final", &"result_failure_final_empty", &"result_abandon", &"result_abandon_empty", &"result_save_failed", &"result_save_recovered":
			var result_panel = run_scene.get("result_panel")
			if result_panel == null:
				_fail("production ResultPanel missing")
				return
			if state == &"result_save_recovered":
				var failed_snapshot := _result_snapshot(&"result_save_failed")
				failed_snapshot["result_id"] = "art25-result-save-retry"
				result_panel.show_summary(failed_snapshot)
				if not await _await_layout_stable(result_panel, "save-failed result"):
					return
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
	if not await _await_layout_stable(run_scene, "capture state %s" % String(state)):
		return
	if state.begins_with("result_"):
		var production_result = run_scene.get("result_panel")
		var expected_focus := production_result.preferred_focus_control() as Control if production_result != null else null
		if expected_focus == null or root.gui_get_focus_owner() != expected_focus:
			_fail("production ResultPanel focus is not visible for %s" % String(state))
			return
		if state == &"result_abandon":
			var partial_section := _partially_visible_result_section(production_result)
			if not partial_section.is_empty():
				_fail(
					"result_abandon leaves a half-clipped item section: viewport=%s section=%s index=%d"
					% [
						partial_section.get("viewport_rect", Rect2()),
						partial_section.get("section_rect", Rect2()),
						int(partial_section.get("section_index", -1)),
					]
				)
				return
		if not _result_layout_is_safe(production_result, state, Vector2i(width, height)):
			return
	if state == &"event_merchant" and not _merchant_layout_is_safe(run_scene):
		return
	if state == &"inventory_items" and not _inventory_item_preview_is_safe(run_scene):
		return
	if state == &"exit_confirm" and not _extract_item_preview_is_safe(run_scene):
		return
	if debug_panel_requested and not _debug_panel_layout_is_safe(run_scene, Vector2i(width, height)):
		return
	if (
		StringName(run_scene.get("screen_state")) == &"run"
		and not _folded_minimap_layout_is_safe(run_scene)
	):
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
	print(
		"ART25_PRODUCTION_CAPTURE=PASS state=%s size=%dx%d ui_scale=%d output=%s"
		% [
			String(state),
			image.get_width(),
			image.get_height(),
			int(round(ui_scale * 100.0)),
			output_path,
		]
	)
	if batch_mode:
		main.queue_free()
		await main.tree_exited
		await process_frame
		return
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


func _seed_quick_bag_inventory(run_scene: Node, row_count: int) -> bool:
	var run_context = run_scene.get("run_context")
	if run_context == null or run_context.get("asset_ledger") == null:
		_fail("quick-bag fixture has no RunAssetLedger")
		return false
	var ledger = run_context.get("asset_ledger")
	ledger.item_instances.clear()
	ledger.room_floor_items.clear()
	var item_ids := ["con_ration", "con_tape_roll", "con_scan_pin", "eq_goggles"]
	var rarity_ids := [&"tier_1", &"tier_2", &"tier_3", &"tier_4"]
	for index in range(clampi(row_count, 0, item_ids.size())):
		var definition := M7ContentCatalogScript.item_definition(item_ids[index])
		if definition.is_empty():
			_fail("quick-bag fixture item is absent from M7: %s" % item_ids[index])
			return false
		definition["instance_id"] = "capture_quick_bag_%d_%s" % [index, item_ids[index]]
		definition["rarity"] = rarity_ids[index]
		ledger.create_item_instance(definition, RunAssetLedger.LOCATION_INVENTORY)
	var actual_count: int = ledger.get_items_by_location(
		RunAssetLedger.LOCATION_INVENTORY
	).size()
	if actual_count != row_count:
		_fail("quick-bag fixture expected %d rows, created %d" % [row_count, actual_count])
		return false
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
	if meta == null or not meta.text.contains("收藏等级 4") or not meta.text.contains("珍贵") or meta.text.contains("[T4]") or marker == null:
		_fail("production extract confirmation omitted rarity or collectible-level identity")
		return false
	return true


func _debug_panel_layout_is_safe(run_scene: Node, viewport_size: Vector2i) -> bool:
	var panel = run_scene.get("debug_panel") as Control
	var run_surface = run_scene.get("run_surface")
	var action_bar = run_surface.get("action_bar") as Control if run_surface != null else null
	var protocol = run_surface.get("right_backdrop") as Control if run_surface != null else null
	var player = run_scene.get("player_controller")
	if panel == null or action_bar == null or protocol == null or player == null:
		_fail("debug-panel visual check is missing production controls")
		return false
	var panel_rect := panel.get_global_rect()
	if panel_rect.size.x > float(viewport_size.x) * 0.28 + 0.5:
		_fail(
			"expanded debug panel exceeded 28%% viewport width: actual=%.1f limit=%.1f rect=%s viewport=%s"
			% [
				panel_rect.size.x,
				float(viewport_size.x) * 0.28,
				str(panel_rect),
				str(viewport_size),
			]
		)
		return false
	if panel_rect.size.y > float(viewport_size.y) * 0.75 + 0.5:
		_fail(
			"expanded debug panel exceeded 75%% viewport height: actual=%.1f limit=%.1f rect=%s viewport=%s"
			% [
				panel_rect.size.y,
				float(viewport_size.y) * 0.75,
				str(panel_rect),
				str(viewport_size),
			]
		)
		return false
	var action_rect := action_bar.get_global_rect()
	if panel_rect.intersects(action_rect, true):
		_fail(
			"expanded debug panel overlapped the production action dock: panel=%s action=%s"
			% [str(panel_rect), str(action_rect)]
		)
		return false
	var protocol_rect := protocol.get_global_rect()
	if panel_rect.intersects(protocol_rect, true):
		_fail(
			"expanded debug panel overlapped the production protocol card: panel=%s protocol=%s"
			% [str(panel_rect), str(protocol_rect)]
		)
		return false
	var focus_owner := root.gui_get_focus_owner()
	if focus_owner == null or not panel.is_ancestor_of(focus_owner):
		_fail("expanded debug panel did not own keyboard/gamepad focus")
		return false
	if bool(player.get("input_enabled")):
		_fail("expanded debug panel left production movement input enabled")
		return false
	return true


func _folded_minimap_layout_is_safe(run_scene: Node) -> bool:
	var run_surface = run_scene.get("run_surface")
	var panel = run_surface.get_minimap_panel() as Control if run_surface != null else null
	var grid := panel.get_node_or_null("Grid") as GridContainer if panel != null else null
	if panel == null or grid == null:
		_fail("folded minimap visual check is missing production controls")
		return false
	if not panel.clip_contents:
		_fail("folded minimap host does not clip its cell layers")
		return false
	var visible_rect: Rect2i = panel.get("visible_map_rect")
	var expected_cells := visible_rect.size.x * visible_rect.size.y
	if expected_cells <= 0 or grid.get_child_count() != expected_cells:
		_fail(
			"folded minimap cell count drifted: expected=%d actual=%d"
			% [expected_cells, grid.get_child_count()]
		)
		return false
	var panel_rect := panel.get_global_rect().grow(0.5)
	var grid_rect := grid.get_global_rect().grow(0.5)
	if not panel_rect.encloses(grid_rect):
		_fail(
			"folded minimap grid escaped its host: panel=%s grid=%s"
			% [panel.get_global_rect(), grid.get_global_rect()]
		)
		return false
	for raw_cell in grid.get_children():
		var cell := raw_cell as Control
		if cell == null or not cell.is_visible_in_tree():
			continue
		var cell_rect := cell.get_global_rect()
		if not panel_rect.encloses(cell_rect) or not grid_rect.encloses(cell_rect):
			_fail(
				"folded minimap exposes a clipped cell %s: panel=%s grid=%s cell=%s"
				% [
					cell.name,
					panel.get_global_rect(),
					grid.get_global_rect(),
					cell_rect,
				]
			)
			return false
		if not cell.clip_contents:
			_fail("folded minimap cell %s does not clip its local layers" % cell.name)
			return false
	return true


func _teleport_to_room(run_scene, room_type: StringName) -> bool:
	run_scene.call("_debug_teleport_to_room_type", room_type)
	var run_context = run_scene.get("run_context")
	if run_context == null:
		_fail("production RunContext missing for %s capture" % String(room_type))
		return false
	if not await _await_condition(
		func() -> bool:
			var current: Dictionary = run_context.get_status_snapshot()
			return StringName(current.get("current_room", &"Unknown")) == room_type,
		"enter %s room" % String(room_type)
	):
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
	return await _await_layout_stable(run_scene, "%s proximity focus" % String(room_type))


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
	if not await _await_condition(
		func() -> bool:
			var context_popup = room_view.get("context_popup") if room_view != null else null
			return context_popup != null and context_popup.visible and context_popup.context_kind == &"event",
		"merchant proximity entry"
	):
		return false
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
	if not await _await_condition(
		func() -> bool: return bool(run_scene.call("_runtime_modal_is_top", &"event")),
		"merchant decision modal"
	):
		return false
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


func _partially_visible_result_section(result_panel) -> Dictionary:
	if result_panel == null:
		return {}
	var scroll := result_panel.get_node_or_null("ResultItemSectionsScroll") as ScrollContainer
	var sections := result_panel.get_node_or_null("ResultItemSectionsScroll/ResultItemSections") as VBoxContainer
	if scroll == null or sections == null:
		return {
			"section_index": -1,
			"viewport_rect": Rect2(),
			"section_rect": Rect2(),
		}
	var viewport_rect := scroll.get_global_rect()
	for section_index in range(sections.get_child_count()):
		var child := sections.get_child(section_index)
		if not (child is Control) or not (child as Control).visible:
			continue
		var section_rect := (child as Control).get_global_rect()
		var intersects := section_rect.end.y > viewport_rect.position.y + 0.5 and section_rect.position.y < viewport_rect.end.y - 0.5
		if intersects and (section_rect.position.y < viewport_rect.position.y - 0.5 or section_rect.end.y > viewport_rect.end.y + 0.5):
			return {
				"section_index": section_index,
				"viewport_rect": viewport_rect,
				"section_rect": section_rect,
			}
	return {}


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


func _prepare_debug_state(
	run_scene: Node,
	state: StringName,
	options: Dictionary
) -> bool:
	if not bool(run_scene.call("_show_settings_shell")):
		_fail("production settings could not open for debug test-room capture")
		return false
	var ui_shell = run_scene.get("ui_shell")
	if not await _await_condition(
		func() -> bool:
			var panel = ui_shell.call("get_settings_panel") if ui_shell != null else null
			return StringName(run_scene.get("screen_state")) == &"settings_shell" and panel != null and panel.is_visible_in_tree(),
		"debug settings entry"
	):
		return false
	var settings_panel = ui_shell.call("get_settings_panel") if ui_shell != null else null
	var test_room_button = settings_panel.get("test_room_button") as Button if settings_panel != null else null
	if test_room_button == null or not test_room_button.is_visible_in_tree():
		_fail("debug build settings omitted the isolated test-room entry")
		return false
	if state == &"debug_settings":
		return await _await_layout_stable(ui_shell, "debug settings")
	var scenario_id := StringName(options.get("scenario", "demo_7x7"))
	var seed := int(options.get("seed", 1001))
	if state in [&"debug_matrix", &"debug_scenario_quad"]:
		run_scene.call("_on_app_shell_host_route_requested", {
			"target": &"run",
			"source": &"settings_test_room",
			"payload": {
				"entry_id": &"i4_debug_test_room",
				"entry_label": "隔离测试场",
				"source_page": &"settings_placeholder",
				"route_mode": &"demo_run",
				"debug_test_room": true,
				"scenario_id": scenario_id,
				"seed_value": seed,
				"playable_route": true,
				"preview_only": false,
			},
			"requires_confirm": false,
			"blocked_reason": &"",
		})
	else:
		test_room_button.pressed.emit()
	if not await _await_condition(
		func() -> bool:
			var controller = run_scene.get("debug_panel_controller")
			return (
				StringName(run_scene.get("screen_state")) == &"run"
				and controller != null
				and bool(controller.call("is_test_room_active"))
			),
		"isolated test-room admission"
	):
		return false
	var banner := run_scene.find_child("DebugSandboxBanner", true, false) as Label
	if banner == null or not banner.is_visible_in_tree():
		_fail("isolated test room omitted its profile/scenario/seed/save banner")
		return false
	var controller = run_scene.get("debug_panel_controller")
	var session_snapshot: Dictionary = (
		controller.call("test_room_snapshot")
		if controller != null
		else {}
	)
	if (
		StringName(session_snapshot.get("scenario_id", &"")) != scenario_id
		or int(session_snapshot.get("seed", 0)) != seed
	):
		_fail(
			"isolated test room identity drifted: expected=%s/%d actual=%s/%d"
			% [
				String(scenario_id),
				seed,
				String(session_snapshot.get("scenario_id", "")),
				int(session_snapshot.get("seed", 0)),
			]
		)
		return false
	if bool(session_snapshot.get("tainted", true)):
		_fail("deterministic scenario fixture did not establish a CLEAN baseline")
		return false
	if not _debug_fixture_matches(session_snapshot, scenario_id):
		return false
	var taint_requested := (
		state in [&"debug_matrix", &"debug_scenario_quad"]
		and String(options.get("taint", "clean")) == "tainted"
	)
	if taint_requested:
		var taint_result: Dictionary = run_scene.call(
			"_dispatch_command",
			&"debug_add_run_black_coin",
			{"source": "i4_capture_taint", "amount": 1},
			false,
			false
		)
		if not bool(taint_result.get("ok", false)):
			_fail("debug matrix taint command was rejected")
			return false
		controller.call("sync_coordinates")
		if not await _await_condition(
			func() -> bool:
				var active_controller = run_scene.get("debug_panel_controller")
				return (
					active_controller != null
					and bool(
						(active_controller.call("test_room_snapshot") as Dictionary)
						.get("tainted", false)
					)
				),
			"debug matrix taint banner"
		):
			return false
		if not banner.text.contains("TAINTED"):
			_fail("debug matrix taint state did not update the visible session banner")
			return false
	var panel_requested := (
		state == &"debug_panel"
		or (
			state == &"debug_matrix"
			and String(options.get("panel", "collapsed")) == "expanded"
		)
	)
	if panel_requested:
		run_scene.call("_open_debug_panel")
		if not await _await_condition(
			func() -> bool:
				var panel = run_scene.get("debug_panel")
				return panel != null and panel.is_visible_in_tree(),
			"expanded debug panel"
		):
			return false
	elif state in [&"debug_matrix", &"debug_scenario_quad"]:
		var debug_panel = run_scene.get("debug_panel") as Control
		if debug_panel == null or debug_panel.visible:
			_fail("collapsed debug matrix state exposed the diagnostics panel")
			return false
	return await _await_layout_stable(run_scene, String(state))


func _capture_debug_scenario_quad(
	run_scene: Node,
	options: Dictionary,
	width: int,
	height: int,
	ui_scale: float
) -> bool:
	var scenario_id := StringName(options.get("scenario", "demo_7x7"))
	var output_dir := String(options.get("output-dir", ""))
	if output_dir.is_empty():
		_fail("debug scenario quad omitted output-dir")
		return false
	if not output_dir.is_absolute_path():
		output_dir = ProjectSettings.globalize_path(output_dir)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if mkdir_error != OK and not DirAccess.dir_exists_absolute(output_dir):
		_fail("debug scenario quad could not create output-dir: %s" % output_dir)
		return false
	var controller = run_scene.get("debug_panel_controller")
	var banner := run_scene.find_child("DebugSandboxBanner", true, false) as Label
	var panel = run_scene.get("debug_panel") as Control
	if controller == null or banner == null or panel == null:
		_fail("debug scenario quad is missing production controls")
		return false
	if bool((controller.call("test_room_snapshot") as Dictionary).get("tainted", true)):
		_fail("debug scenario quad did not start CLEAN")
		return false
	if panel.visible or not banner.text.contains("CLEAN"):
		_fail("debug scenario quad clean/collapsed state drifted")
		return false
	if not _folded_minimap_layout_is_safe(run_scene):
		return false
	if not _save_debug_quad_image(
		output_dir,
		scenario_id,
		&"clean",
		&"collapsed",
		width,
		height,
		ui_scale
	):
		return false

	run_scene.call("_open_debug_panel")
	if not await _await_condition(
		func() -> bool: return panel.is_visible_in_tree(),
		"debug quad clean expanded panel"
	):
		return false
	if not await _await_layout_stable(run_scene, "debug quad clean expanded"):
		return false
	if not _debug_panel_layout_is_safe(run_scene, Vector2i(width, height)):
		return false
	if not _save_debug_quad_image(
		output_dir,
		scenario_id,
		&"clean",
		&"expanded",
		width,
		height,
		ui_scale
	):
		return false

	controller.call("close_panel")
	if not await _await_condition(
		func() -> bool: return not panel.is_visible_in_tree(),
		"debug quad close before taint"
	):
		return false
	var taint_result: Dictionary = run_scene.call(
		"_dispatch_command",
		&"debug_add_run_black_coin",
		{"source": "i4_capture_taint", "amount": 1},
		false,
		false
	)
	if not bool(taint_result.get("ok", false)):
		_fail("debug scenario quad taint command was rejected")
		return false
	controller.call("sync_coordinates")
	if not await _await_condition(
		func() -> bool:
			return (
				bool(
					(controller.call("test_room_snapshot") as Dictionary)
					.get("tainted", false)
				)
				and banner.text.contains("TAINTED")
			),
		"debug quad tainted identity"
	):
		return false
	if not await _await_layout_stable(run_scene, "debug quad tainted collapsed"):
		return false
	if not _save_debug_quad_image(
		output_dir,
		scenario_id,
		&"tainted",
		&"collapsed",
		width,
		height,
		ui_scale
	):
		return false

	run_scene.call("_open_debug_panel")
	if not await _await_condition(
		func() -> bool: return panel.is_visible_in_tree(),
		"debug quad tainted expanded panel"
	):
		return false
	if not await _await_layout_stable(run_scene, "debug quad tainted expanded"):
		return false
	if not _debug_panel_layout_is_safe(run_scene, Vector2i(width, height)):
		return false
	if not _save_debug_quad_image(
		output_dir,
		scenario_id,
		&"tainted",
		&"expanded",
		width,
		height,
		ui_scale
	):
		return false
	print(
		"ART25_DEBUG_QUAD=PASS scenario=%s states=4 size=%dx%d ui_scale=%d output=%s"
		% [
			String(scenario_id),
			width,
			height,
			int(round(ui_scale * 100.0)),
			output_dir,
		]
	)
	return true


func _save_debug_quad_image(
	output_dir: String,
	scenario_id: StringName,
	taint_state: StringName,
	panel_state: StringName,
	width: int,
	height: int,
	ui_scale: float
) -> bool:
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail(
			"debug scenario quad returned no image for %s/%s/%s"
			% [String(scenario_id), String(taint_state), String(panel_state)]
		)
		return false
	if image.get_size() != Vector2i(width, height):
		_fail(
			"debug scenario quad size mismatch for %s/%s/%s"
			% [String(scenario_id), String(taint_state), String(panel_state)]
		)
		return false
	var file_name := "%s__%s__%s__%dx%d__ui%d.png" % [
		String(scenario_id),
		String(taint_state),
		String(panel_state),
		width,
		height,
		int(round(ui_scale * 100.0)),
	]
	var save_error := image.save_png(output_dir.path_join(file_name))
	if save_error != OK:
		_fail(
			"debug scenario quad save failed for %s: %s"
			% [file_name, error_string(save_error)]
		)
		return false
	return true


func _debug_fixture_matches(
	session_snapshot: Dictionary,
	scenario_id: StringName
) -> bool:
	var fixture := session_snapshot.get("fixture", {}) as Dictionary
	if (
		not bool(fixture.get("ok", false))
		or StringName(fixture.get("scenario_id", &"")) != scenario_id
	):
		_fail(
			"debug scenario fixture was not admitted: scenario=%s fixture=%s"
			% [String(scenario_id), fixture]
		)
		return false
	var current_room := StringName(fixture.get("current_room_type", &"Unknown"))
	var backpack_count := int(fixture.get("backpack_count", -1))
	var ground_count := int(fixture.get("ground_count", -1))
	var matches := true
	match scenario_id:
		&"demo_7x7":
			matches = int(fixture.get("applied_command_count", -1)) == 0
		&"combat_room":
			matches = current_room == &"Monster"
		&"full_backpack":
			matches = backpack_count >= 10 and ground_count >= 1
		&"duplicate_items":
			matches = backpack_count >= 3
		&"terminal_success_failure":
			matches = current_room == &"Exit"
		&"persistence_failure":
			matches = bool(fixture.get("failure_injection_armed", false))
		_:
			matches = false
	if not matches:
		_fail(
			"debug scenario fixture content drifted: scenario=%s fixture=%s"
			% [String(scenario_id), fixture]
		)
	return matches


func _await_condition(
	predicate: Callable,
	label: String,
	timeout_ms: int = WAIT_TIMEOUT_MS
) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() <= deadline:
		await process_frame
		if bool(predicate.call()):
			return true
	_fail("semantic wait timed out: %s" % label)
	return false


func _await_layout_stable(
	subject: Node,
	label: String,
	timeout_ms: int = WAIT_TIMEOUT_MS
) -> bool:
	var previous := ""
	var stable_submissions := 0
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() <= deadline:
		await process_frame
		var current := _visible_layout_fingerprint(subject)
		if not current.is_empty() and current == previous:
			stable_submissions += 1
		else:
			stable_submissions = 0
		previous = current
		if stable_submissions >= 3:
			return true
	_fail("layout did not stabilize for three submissions: %s" % label)
	return false


func _visible_layout_fingerprint(subject: Node) -> String:
	var rows: PackedStringArray = []
	for candidate in subject.find_children("*", "Control", true, false):
		var control := candidate as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		var text := ""
		if control is Label:
			text = (control as Label).text
		elif control is Button:
			text = (control as Button).text
		rows.append("%s|%.2f,%.2f,%.2f,%.2f|%.3f|%s" % [
			String(control.get_path()),
			rect.position.x,
			rect.position.y,
			rect.size.x,
			rect.size.y,
			control.modulate.a,
			text,
		])
	rows.sort()
	return "\n".join(rows)


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
	if batch_mode:
		if batch_failure.is_empty():
			batch_failure = message
		return
	quit(2)
