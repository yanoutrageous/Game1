extends SceneTree

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

	match state:
		&"run":
			pass
		&"map":
			run_scene.call("_open_map_from_ui", &"art25_capture")
		&"inventory":
			run_scene.call("_show_inventory_panel")
		&"chest", &"chest_open":
			run_scene.call("_debug_teleport_to_room_type", &"Chest")
			await _frames(10)
			var chest_view = run_scene.get("room_runtime_view")
			var chest_player = run_scene.get("player_controller")
			if state == &"chest_open":
				run_scene.call("_handle_interact_pressed")
				await _frames(4)
			if chest_view != null and chest_player != null:
				chest_view.advance(0.0, chest_player.get_local_position(), {})
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
		&"result_success", &"result_failure", &"result_salvage":
			var result_panel = run_scene.get("result_panel")
			if result_panel == null:
				_fail("production ResultPanel missing")
				return
			result_panel.show_summary(_result_snapshot(state))
		_:
			_fail("unknown state: %s" % String(state))
			return
	await _frames(14)

	var image := root.get_texture().get_image()
	if image == null:
		_fail("renderer returned no image")
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
	var item := {
		"instance_id": "art25_capture_item",
		"item_id": "old_gear_set",
		"display_name": "旧齿轮组",
		"short_description": "用于生产结算画面检查的真实 M7 物品定义。",
		"weight": 1,
	}
	if state == &"result_success":
		return {
			"outcome": "Extracted", "run_black_coin": 36, "backpack_used": 3, "backpack_capacity": 10,
			"settlement": {"outcome": "success", "black_coin_converted": 36, "gold_coin_gained": 36, "safe_yield": 36, "warehouse_items": [item], "warehouse_lite": [item], "salvaged_items": [], "lost_items": [], "lost_item_count": 0, "finalized": true},
			"event_log": [], "transaction_log": [], "meta_progress_commit": {"status": &"committed"},
		}
	if state == &"result_salvage":
		return {
			"outcome": "Failed", "run_black_coin": 36, "backpack_used": 3, "backpack_capacity": 10,
			"settlement": {"outcome": "failure", "black_coin_lost": 36, "gold_coin_gained": 0, "warehouse_items": [], "salvaged_items": [], "lost_items": [], "lost_item_count": 0, "requires_salvage_selection": true, "finalized": false, "salvage_capacity": 2, "settlement_pool": [item]},
			"event_log": [], "transaction_log": [], "meta_progress_commit": {"status": &"awaiting_salvage_confirmation"},
		}
	return {
		"outcome": "Failed", "run_black_coin": 36, "backpack_used": 0, "backpack_capacity": 10,
		"settlement": {"outcome": "failure", "black_coin_lost": 36, "gold_coin_gained": 0, "warehouse_items": [], "salvaged_items": [], "lost_items": [item], "lost_item_count": 1, "finalized": true},
		"event_log": [], "transaction_log": [], "meta_progress_commit": {"status": &"committed"},
	}


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
