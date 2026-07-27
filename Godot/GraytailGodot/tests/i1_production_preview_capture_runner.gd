extends SceneTree

# Evidence generation only. This runner always instantiates the production
# main.tscn and production UI/runtime nodes. A successful PNG is not a visual
# acceptance result; tools/i1/validation_manifest.json keeps it non-blocking.

const PASS_MARKER := "I1_PRODUCTION_PREVIEW=PASS"
const FAIL_MARKER := "I1_PRODUCTION_PREVIEW=FAIL"
const ALLOWED_SCENES: Array[StringName] = [
	&"main_menu",
	&"deploy",
	&"long_term",
	&"run",
	&"combat",
	&"inventory",
	&"map",
	&"result_success",
	&"result_failure",
]
const ALLOWED_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var scene_id := StringName(String(options.get("scene", "run")))
	var viewport_size := Vector2i(int(options.get("width", 1280)), int(options.get("height", 720)))
	var ui_scale_percent := int(options.get("ui-scale", 100))
	var output_argument := String(options.get("output", ""))
	if not ALLOWED_SCENES.has(scene_id):
		_fail("unsupported scene=%s" % String(scene_id))
		return
	if not ALLOWED_RESOLUTIONS.has(viewport_size):
		_fail("unsupported size=%dx%d" % [viewport_size.x, viewport_size.y])
		return
	if output_argument.is_empty():
		_fail("missing --output")
		return

	root.size = viewport_size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.transparent_bg = false

	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	if main_scene == null:
		_fail("production main.tscn could not be loaded")
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	await _frames(18)
	var run_scene := main.get_node_or_null("RunScene")
	if run_scene == null:
		_fail("production RunScene is missing")
		return
	if run_scene.has_method("set_ui_scale_factor"):
		run_scene.call("set_ui_scale_factor", float(ui_scale_percent) / 100.0)
	var scene_applied: bool = await _apply_scene(run_scene, scene_id)
	if not scene_applied:
		return
	await _frames(16)

	var image := root.get_texture().get_image()
	if image == null:
		_fail("renderer returned no image")
		return
	if image.get_width() != viewport_size.x or image.get_height() != viewport_size.y:
		_fail("renderer size=%dx%d expected=%dx%d" % [image.get_width(), image.get_height(), viewport_size.x, viewport_size.y])
		return
	var output_path := output_argument if output_argument.is_absolute_path() else ProjectSettings.globalize_path(output_argument)
	var mkdir_result := DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	if mkdir_result != OK:
		_fail("output directory failed: %s" % error_string(mkdir_result))
		return
	var save_result := image.save_png(output_path)
	if save_result != OK:
		_fail("PNG save failed: %s" % error_string(save_result))
		return
	print("%s scene=%s size=%dx%d output=%s" % [PASS_MARKER, String(scene_id), image.get_width(), image.get_height(), output_path])
	quit(0)


func _apply_scene(run_scene: Node, scene_id: StringName) -> bool:
	match scene_id:
		&"main_menu":
			run_scene.call("_show_main_menu")
		&"deploy":
			run_scene.call("_show_deploy_shell", &"config")
		&"long_term":
			run_scene.call("_show_long_term_shell", &"tasks")
		&"run", &"inventory", &"map", &"result_success", &"result_failure", &"combat":
			run_scene.call("_start_standard_from_ui")
			await _frames(20)
			match scene_id:
				&"inventory":
					run_scene.call("_show_inventory_panel")
				&"map":
					run_scene.call("_open_map_from_ui", &"i1_production_preview")
				&"result_success", &"result_failure":
					var result_panel = run_scene.get("result_panel")
					if result_panel == null:
						_fail("production ResultPanel is missing")
						return false
					var result_snapshot := _result_snapshot(scene_id)
					var runtime_controller = run_scene.get("runtime_controller")
					if runtime_controller != null:
						runtime_controller.set("last_meta_commit", result_snapshot.get("meta_progress_commit", {}))
					run_scene.call("_on_result_available", result_snapshot)
				&"combat":
					if not _activate_combat(run_scene):
						return false
				_:
					pass
		_:
			_fail("unsupported scene route=%s" % String(scene_id))
			return false
	return true


func _activate_combat(run_scene: Node) -> bool:
	var controller = run_scene.get("runtime_controller")
	var context = run_scene.get("run_context")
	var bus = run_scene.get("command_bus")
	if controller == null or context == null or bus == null:
		_fail("production combat authority is missing")
		return false
	context.max_hp = 10000
	context.hp = 10000
	var combat_pos: Vector2i = context.get_current_pos()
	context.truth_map.set_room_type(combat_pos, &"Monster")
	bus.room_resolver.enter_room(context)
	controller.in_run_runtime.sync_room(Vector2(0.50, 0.50))
	if context.current_room_type != &"Monster" or not controller.in_run_runtime.has_active_combat():
		_fail("production combat runtime did not activate")
		return false
	run_scene.call("_refresh_view_models")
	return true


func _result_snapshot(scene_id: StringName) -> Dictionary:
	var item := {
		"instance_id": "i1_preview_item",
		"item_id": "old_gear_set",
		"display_name": "Recovered Gear Set",
		"short_description": "Production preview settlement item.",
		"rarity": "Common",
		"weight": 1,
	}
	if scene_id == &"result_success":
		return {
			"outcome": "Extracted",
			"run_black_coin": 36,
			"backpack_used": 3,
			"backpack_capacity": 10,
			"settlement": {
				"outcome": "success",
				"black_coin_converted": 36,
				"gold_coin_gained": 36,
				"safe_yield": 36,
				"warehouse_items": [item],
				"warehouse_lite": [item],
				"salvaged_items": [],
				"lost_items": [],
				"lost_item_count": 0,
				"finalized": true,
			},
			"event_log": [],
			"transaction_log": [],
			"meta_progress_commit": {"status": &"committed"},
		}
	return {
		"outcome": "Failed",
		"run_black_coin": 36,
		"backpack_used": 0,
		"backpack_capacity": 10,
		"settlement": {
			"outcome": "failure",
			"black_coin_lost": 36,
			"gold_coin_gained": 0,
			"warehouse_items": [],
			"salvaged_items": [],
			"lost_items": [item],
			"lost_item_count": 1,
			"finalized": true,
		},
		"event_log": [],
		"transaction_log": [],
		"meta_progress_commit": {"status": &"committed"},
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
	push_error("%s %s" % [FAIL_MARKER, message])
	print("%s reason=%s" % [FAIL_MARKER, message.replace("\n", " ")])
	quit(2)
