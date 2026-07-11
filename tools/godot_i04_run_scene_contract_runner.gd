extends SceneTree

const RunSceneInputRouterScript := preload("res://scripts/core/run/run_scene_input_router.gd")
const DebugGateScript := preload("res://scripts/core/debug/debug_gate.gd")

const CASE_CONTRACT := &"contract"
const CASE_NO_FLAGS := &"no_flags"
const CASE_MODAL := &"modal"
const CASE_FULL_MAP := &"full_map"
const CASE_SPARSE_MAP := &"sparse_map"

const SAVE_PATHS := [
	"user://saves/manifest.json",
	"user://saves/profiles/default/meta_progress.json",
	"user://saves/profiles/default/run_checkpoint.json",
	"user://saves/profiles/default/preview.json",
	"user://graytail_m1_meta_progress.json",
]

var failures: Array[String] = []
var case_id: StringName = CASE_CONTRACT
var had_debug_setting: bool = false
var previous_debug_setting: Variant = null
var debug_setting_captured: bool = false
var scene: Node = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	case_id = _requested_case()
	_validate_requested_case()
	if not failures.is_empty():
		await _finish()
		return
	if not _validate_isolated_user_root():
		await _finish()
		return
	if not _require_no_save_files("before scene load"):
		await _finish()
		return
	had_debug_setting = ProjectSettings.has_setting(DebugGateScript.ENABLE_SETTING)
	previous_debug_setting = ProjectSettings.get_setting(DebugGateScript.ENABLE_SETTING, false)
	debug_setting_captured = true
	if case_id != CASE_CONTRACT:
		ProjectSettings.set_setting(DebugGateScript.ENABLE_SETTING, true)

	var packed := load("res://scenes/run/run_scene.tscn") as PackedScene
	_require(packed != null, "run_scene.tscn did not load as PackedScene")
	if packed == null:
		await _finish()
		return
	scene = packed.instantiate()
	_require(scene != null, "run_scene.tscn did not instantiate")
	if scene == null:
		await _finish()
		return
	root.add_child(scene)
	await process_frame
	await process_frame

	_validate_scene_shape()
	_validate_runtime_ownership()
	_validate_initial_screen()
	_validate_connections()
	_validate_input_contract()

	scene.call("_start_standard_from_ui")
	await process_frame
	await process_frame
	_validate_started_run()
	_validate_smoke_case()
	if case_id == CASE_CONTRACT:
		_validate_modal_and_cancel_contract()
		_validate_debug_toggle_contract()

	_require_no_save_files("after characterization")
	print("I04_RUN_SCENE_SNAPSHOT=%s" % JSON.stringify(_canonical_snapshot()))
	await _finish()


func _requested_case() -> StringName:
	for arg in OS.get_cmdline_user_args():
		var text := String(arg)
		if text.begins_with("--i04-case="):
			return StringName(text.trim_prefix("--i04-case="))
	return CASE_CONTRACT


func _validate_requested_case() -> void:
	_require(case_id in [CASE_CONTRACT, CASE_NO_FLAGS, CASE_MODAL, CASE_FULL_MAP, CASE_SPARSE_MAP], "unsupported case: %s" % case_id)
	var args := OS.get_cmdline_user_args()
	var modal_flag := "--art21r2-seed-modal-items" in args
	var full_flag := "--art21r2-seed-map-markers" in args
	var sparse_flag := "--art21r2-seed-map-sparse-markers" in args
	match case_id:
		CASE_CONTRACT, CASE_NO_FLAGS:
			_require(not modal_flag and not full_flag and not sparse_flag, "no-flag case received an ART21R2 smoke flag")
		CASE_MODAL:
			_require(modal_flag and not full_flag and not sparse_flag, "modal case flag set mismatch")
		CASE_FULL_MAP:
			_require(full_flag and not modal_flag and not sparse_flag, "full-map case flag set mismatch")
		CASE_SPARSE_MAP:
			_require(sparse_flag and not modal_flag and not full_flag, "sparse-map case flag set mismatch")


func _validate_isolated_user_root() -> bool:
	var user_root := ProjectSettings.globalize_path("user://").replace("\\", "/").trim_suffix("/")
	var approved_roots: Array[String] = []
	for variable_name: String in ["GODOT_USER_HOME", "APPDATA", "LOCALAPPDATA", "XDG_DATA_HOME"]:
		var value := OS.get_environment(variable_name).replace("\\", "/").trim_suffix("/")
		if value != "":
			approved_roots.append(value)
	var isolated := false
	for approved_root: String in approved_roots:
		if user_root.to_lower().begins_with(approved_root.to_lower() + "/"):
			isolated = true
			break
	if not isolated:
		_fail("user:// escaped isolated process roots: %s" % user_root)
	return isolated


func _validate_scene_shape() -> void:
	_require(scene.name == &"RunScene", "scene root name changed")
	_require(scene is Node2D, "scene root is not Node2D")
	_require(scene.get_node_or_null("RoomLayer") is Node2D, "RoomLayer path/type changed")
	_require(scene.get_node_or_null("PlayerLayer") is Node2D, "PlayerLayer path/type changed")
	_require(scene.get_node_or_null("UILayer") is CanvasLayer, "UILayer path/type changed")
	_require(scene.get_node_or_null("RoomLayer/RoomSceneController") != null, "RoomSceneController missing")
	_require(scene.get_node_or_null("PlayerLayer/PlayerController") != null, "PlayerController missing")
	_require(scene.get_node_or_null("UILayer/G9FinalUIRoot") != null, "G9FinalUIRoot missing")


func _validate_runtime_ownership() -> void:
	var runtime_controller: Variant = scene.get("runtime_controller")
	var run_context: Variant = scene.get("run_context")
	var command_bus: Variant = scene.get("command_bus")
	_require(runtime_controller != null, "runtime_controller is null")
	_require(run_context != null, "run_context is null")
	_require(command_bus != null, "command_bus is null")
	if runtime_controller != null:
		_require(run_context == runtime_controller.context, "RunScene context is not controller context")
		_require(command_bus == runtime_controller.command_bus, "RunScene bus is not controller bus")


func _validate_initial_screen() -> void:
	_require(StringName(scene.get("screen_state")) == &"main_menu", "initial screen is not main_menu")
	var run_overlay := scene.get("run_overlay_root") as Control
	var ui_shell := scene.get("ui_shell") as Control
	_require(run_overlay != null and not run_overlay.visible, "run overlay should start hidden")
	_require(ui_shell != null and ui_shell.visible, "AppShell should start visible")
	_require(not (scene.get_node("RoomLayer") as Node2D).visible, "RoomLayer should start hidden")
	_require(not (scene.get_node("PlayerLayer") as Node2D).visible, "PlayerLayer should start hidden")


func _validate_connections() -> void:
	var command_bus: Object = scene.get("command_bus")
	_require_connected(command_bus, &"state_changed")
	_require_connected(command_bus, &"result_available")
	_require_connected(scene.get("ui_shell"), &"host_route_requested")
	var run_surface: Object = scene.get("run_surface")
	for signal_name: StringName in [
		&"interact_requested",
		&"inventory_requested",
		&"ground_loot_requested",
		&"map_requested",
		&"combat_requested",
		&"extract_requested",
		&"pause_requested",
		&"encounter_option_selected",
	]:
		_require_connected(run_surface, signal_name)
	_require_connected(scene.get("inventory_panel"), &"close_requested")
	_require_connected(scene.get("ground_loot_panel"), &"close_requested")
	_require_connected(scene.get("result_panel"), &"return_main_requested")
	_require_connected(scene.get("result_panel"), &"return_deploy_requested")
	_require_connected(scene.get("map_overlay_panel"), &"cell_action_requested")
	_require_connected(scene.get("tutorial_popup_panel"), &"confirmed")


func _validate_input_contract() -> void:
	var expected := {
		KEY_Q: RunSceneInputRouterScript.ACTION_OPEN_INVENTORY,
		KEY_G: RunSceneInputRouterScript.ACTION_OPEN_GROUND_LOOT,
		KEY_T: RunSceneInputRouterScript.ACTION_REQUEST_EXTRACT,
		KEY_E: RunSceneInputRouterScript.ACTION_INTERACT,
		KEY_SPACE: RunSceneInputRouterScript.ACTION_FIGHT,
		KEY_J: RunSceneInputRouterScript.ACTION_FIGHT,
		KEY_F: RunSceneInputRouterScript.ACTION_FLAG_CURRENT,
		KEY_M: RunSceneInputRouterScript.ACTION_OPEN_MAP,
		KEY_TAB: RunSceneInputRouterScript.ACTION_OPEN_MAP,
	}
	for keycode: Key in expected.keys():
		_require_equal(RunSceneInputRouterScript.run_action(_key_event(keycode)), expected[keycode], "router key %s" % keycode)
	_require_equal(RunSceneInputRouterScript.cancel_action(_key_event(KEY_ESCAPE)), RunSceneInputRouterScript.ACTION_CANCEL, "router escape")
	_require_equal(RunSceneInputRouterScript.run_action(null), RunSceneInputRouterScript.ACTION_NONE, "router null")
	_require_equal(RunSceneInputRouterScript.run_action(_key_event(KEY_Q, false)), RunSceneInputRouterScript.ACTION_NONE, "router release")
	_require_equal(RunSceneInputRouterScript.run_action(_key_event(KEY_Q, true, true)), RunSceneInputRouterScript.ACTION_NONE, "router echo")
	for action_name: StringName in [&"open_inventory", &"open_ground_loot", &"request_extract"]:
		_require(InputMap.has_action(action_name), "InputMap action missing: %s" % action_name)
		_require(not InputMap.action_get_events(action_name).is_empty(), "InputMap action has no events: %s" % action_name)


func _validate_started_run() -> void:
	_require(StringName(scene.get("screen_state")) == &"run", "standard start did not enter run screen")
	var context: Variant = scene.get("run_context")
	_require(context != null and bool(context.get_status_snapshot().get("run_active", false)), "standard start did not activate run")
	var run_overlay := scene.get("run_overlay_root") as Control
	var ui_shell := scene.get("ui_shell") as Control
	_require(run_overlay != null and run_overlay.visible, "run overlay is not visible after start")
	_require(ui_shell != null and not ui_shell.visible, "AppShell is still visible after start")
	_require((scene.get_node("RoomLayer") as Node2D).visible, "RoomLayer is hidden after start")
	_require((scene.get_node("PlayerLayer") as Node2D).visible, "PlayerLayer is hidden after start")


func _validate_modal_and_cancel_contract() -> void:
	var run_surface: Object = scene.get("run_surface")
	var inventory := scene.get("inventory_panel") as Control
	var ground := scene.get("ground_loot_panel") as Control
	var map_overlay := scene.get("map_overlay_panel") as Control
	var pause := scene.get("pause_panel") as Control
	run_surface.emit_signal("inventory_requested")
	_require(inventory.visible and not ground.visible, "inventory signal did not enforce modal exclusivity")
	run_surface.emit_signal("ground_loot_requested")
	_require(ground.visible and not inventory.visible, "ground-loot signal did not enforce modal exclusivity")
	_require(bool(scene.call("_handle_cancel_input", _key_event(KEY_ESCAPE))), "Esc did not handle ground-loot close")
	_require(not ground.visible, "Esc did not close ground-loot panel")
	_require(bool(scene.call("_handle_cancel_input", _key_event(KEY_ESCAPE))), "Esc did not open pause")
	_require(pause.visible, "Esc did not open pause with no modal")
	_require(bool(scene.call("_handle_cancel_input", _key_event(KEY_ESCAPE))), "Esc did not close pause")
	_require(not pause.visible, "second Esc did not close pause")
	run_surface.emit_signal("map_requested", &"i04_runner")
	_require(map_overlay.visible, "map signal did not open overlay")
	_require(bool(scene.call("_handle_cancel_input", _key_event(KEY_ESCAPE))), "Esc did not handle map close")
	_require(not map_overlay.visible, "Esc did not close map overlay")


func _validate_debug_toggle_contract() -> void:
	var debug_panel := scene.get("debug_panel") as Control
	var enabled := DebugGateScript.is_debug_tools_enabled()
	scene.call("_toggle_debug_panel")
	_require(debug_panel.visible == enabled, "debug toggle visibility does not match DebugGate")
	if enabled:
		scene.call("_toggle_debug_panel")
		_require(not debug_panel.visible, "second enabled debug toggle did not close panel")


func _validate_smoke_case() -> void:
	var context: Variant = scene.get("run_context")
	if context == null or context.intel_map == null or context.truth_map == null or context.asset_ledger == null:
		_fail("smoke case dependencies are missing")
		return
	var counts := _map_counts(context)
	var debug_items := _debug_item_counts(context)
	match case_id:
		CASE_CONTRACT, CASE_NO_FLAGS:
			_require(debug_items.total == 0, "no-flag case seeded debug items")
			_require(counts.revealed < context.width * context.height, "no-flag case revealed the full map")
		CASE_MODAL:
			_require(debug_items.total == 2, "modal flag did not seed exactly two debug items")
			_require(debug_items.room_floor == 2, "modal seed baseline no longer has two floor items")
			_require(debug_items.inventory == 0, "modal seed baseline unexpectedly placed an item in inventory")
		CASE_FULL_MAP:
			_require(counts.revealed == context.width * context.height, "full-map flag did not reveal every cell")
			var full_event := _full_event_pos(context)
			var full_flag := _full_flag_pos(context, full_event)
			if full_event != context.get_current_pos():
				_require(StringName(context.truth_map.get_room_type(full_event)) == &"Event", "full-map event position was not set to Event")
			if full_flag != context.get_current_pos() and full_flag != full_event:
				_require(context.intel_map.is_flagged(full_flag), "full-map flag position was not flagged")
		CASE_SPARSE_MAP:
			_require(counts.revealed < context.width * context.height, "sparse-map flag performed a full reveal")
			var sparse_event := _clamped_pos(context, 2, 1)
			var sparse_flag := _clamped_pos(context, 4, 4)
			if sparse_event != context.get_current_pos():
				_require(StringName(context.truth_map.get_room_type(sparse_event)) == &"Event", "sparse-map event position was not set to Event")
				_require(context.intel_map.is_revealed(sparse_event), "sparse-map event position was not revealed")
			if sparse_flag != context.get_current_pos() and sparse_flag != sparse_event:
				_require(context.intel_map.is_flagged(sparse_flag), "sparse-map flag position was not flagged")
			for scan_pos: Vector2i in [_clamped_pos(context, 3, 1), _clamped_pos(context, 3, 2), _clamped_pos(context, 4, 2)]:
				if scan_pos != sparse_event and scan_pos != sparse_flag:
					_require(bool(context.intel_map.get_cell_info(scan_pos).get("scanned", false)), "sparse-map scan position missing: %s" % scan_pos)


func _canonical_snapshot() -> Dictionary:
	var context: Variant = scene.get("run_context")
	var counts := _map_counts(context)
	var debug_items := _debug_item_counts(context)
	return {
		"schema_version": 1,
		"case_id": String(case_id),
		"run_active": bool(context.get_status_snapshot().get("run_active", false)),
		"width": int(context.width),
		"height": int(context.height),
		"current_pos": "%d,%d" % [context.get_current_pos().x, context.get_current_pos().y],
		"revealed_count": counts.revealed,
		"scanned_count": counts.scanned,
		"flagged_count": counts.flagged,
		"debug_item_count": debug_items.total,
		"debug_floor_count": debug_items.room_floor,
		"debug_inventory_count": debug_items.inventory,
		"save_files_created": _existing_save_paths(),
	}


func _map_counts(context: Variant) -> Dictionary:
	var result := {"revealed": 0, "scanned": 0, "flagged": 0}
	if context == null or context.intel_map == null:
		return result
	for x in range(context.width):
		for y in range(context.height):
			var cell: Dictionary = context.intel_map.get_cell_info(Vector2i(x, y))
			if bool(cell.get("revealed", false)):
				result.revealed += 1
			if bool(cell.get("scanned", false)):
				result.scanned += 1
			if bool(cell.get("flagged", false)):
				result.flagged += 1
	return result


func _debug_item_counts(context: Variant) -> Dictionary:
	var result := {"total": 0, "room_floor": 0, "inventory": 0}
	if context == null or context.asset_ledger == null:
		return result
	for item: Dictionary in context.asset_ledger.item_instances.values():
		if String(item.get("source", "")) != "debug_command":
			continue
		result.total += 1
		match StringName(item.get("location_state", &"")):
			&"room_floor":
				result.room_floor += 1
			&"inventory":
				result.inventory += 1
	return result


func _full_event_pos(context: Variant) -> Vector2i:
	var current: Vector2i = context.get_current_pos()
	var result := Vector2i(mini(2, maxi(0, context.width - 1)), 0)
	if result == current:
		result = Vector2i(mini(2, maxi(0, context.width - 1)), mini(1, maxi(0, context.height - 1)))
	if result == current:
		result = Vector2i(0, mini(2, maxi(0, context.height - 1)))
	return result


func _full_flag_pos(context: Variant, event_pos: Vector2i) -> Vector2i:
	var current: Vector2i = context.get_current_pos()
	var result := Vector2i(mini(4, maxi(0, context.width - 1)), mini(4, maxi(0, context.height - 1)))
	if result == current or result == event_pos:
		result = Vector2i(mini(3, maxi(0, context.width - 1)), mini(4, maxi(0, context.height - 1)))
	if result == current or result == event_pos:
		result = Vector2i(mini(4, maxi(0, context.width - 1)), mini(3, maxi(0, context.height - 1)))
	return result


func _clamped_pos(context: Variant, x: int, y: int) -> Vector2i:
	return Vector2i(clampi(x, 0, maxi(0, context.width - 1)), clampi(y, 0, maxi(0, context.height - 1)))


func _key_event(keycode: Key, pressed: bool = true, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = echo
	return event


func _require_connected(emitter: Variant, signal_name: StringName) -> void:
	if not (emitter is Object):
		_fail("signal emitter missing for %s" % signal_name)
		return
	if not emitter.has_signal(signal_name):
		_fail("signal missing: %s" % signal_name)
		return
	_require(not emitter.get_signal_connection_list(signal_name).is_empty(), "signal has no connections: %s" % signal_name)


func _require_no_save_files(label: String) -> bool:
	var existing := _existing_save_paths()
	_require(existing.is_empty(), "%s created or reused save files: %s" % [label, existing])
	return existing.is_empty()


func _existing_save_paths() -> Array[String]:
	var result: Array[String] = []
	_collect_save_files("user://saves", result)
	if FileAccess.file_exists("user://graytail_m1_meta_progress.json"):
		result.append("user://graytail_m1_meta_progress.json")
	for path: String in SAVE_PATHS:
		if FileAccess.file_exists(path) and not result.has(path):
			result.append(path)
	result.sort()
	return result


func _collect_save_files(directory_path: String, result: Array[String]) -> void:
	if not DirAccess.dir_exists_absolute(directory_path):
		return
	var directory := DirAccess.open(directory_path)
	if directory == null:
		result.append("%s/<unreadable>" % directory_path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var child_path := "%s/%s" % [directory_path.trim_suffix("/"), entry]
			if directory.current_is_dir():
				_collect_save_files(child_path, result)
			else:
				result.append(child_path)
		entry = directory.get_next()
	directory.list_dir_end()


func _require_equal(actual: Variant, expected: Variant, label: String) -> void:
	_require(actual == expected, "%s expected=%s actual=%s" % [label, str(expected), str(actual)])


func _require(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures.append(message)


func _restore_debug_setting() -> void:
	if not debug_setting_captured:
		return
	if had_debug_setting:
		ProjectSettings.set_setting(DebugGateScript.ENABLE_SETTING, previous_debug_setting)
	else:
		ProjectSettings.set_setting(DebugGateScript.ENABLE_SETTING, null)


func _pass_marker() -> String:
	match case_id:
		CASE_NO_FLAGS:
			return "I04_ART21R2_NO_FLAGS=PASS"
		CASE_MODAL:
			return "I04_ART21R2_MODAL=PASS"
		CASE_FULL_MAP:
			return "I04_ART21R2_FULL_MAP=PASS"
		CASE_SPARSE_MAP:
			return "I04_ART21R2_SPARSE_MAP=PASS"
		_:
			return "I04_RUN_SCENE_CONTRACT=PASS"


func _fail_marker() -> String:
	match case_id:
		CASE_NO_FLAGS:
			return "I04_ART21R2_NO_FLAGS=FAIL"
		CASE_MODAL:
			return "I04_ART21R2_MODAL=FAIL"
		CASE_FULL_MAP:
			return "I04_ART21R2_FULL_MAP=FAIL"
		CASE_SPARSE_MAP:
			return "I04_ART21R2_SPARSE_MAP=FAIL"
		_:
			return "I04_RUN_SCENE_CONTRACT=FAIL"


func _finish() -> void:
	_restore_debug_setting()
	if is_instance_valid(scene):
		scene.queue_free()
		await process_frame
		await process_frame
	if failures.is_empty():
		print(_pass_marker())
		quit(0)
		return
	printerr("%s:%s" % [_fail_marker(), " | ".join(failures)])
	quit(1)
