extends SceneTree

const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const TutorialMapCatalogScript := preload("res://scripts/core/run/tutorial_map_catalog.gd")

const PASS_MARKER := "I3R_TUTORIAL_PLAYER_JOURNEY=PASS"
const FAIL_MARKER := "I3R_TUTORIAL_PLAYER_JOURNEY=FAIL"
const FRAME_STEP := 0.02

var failures: Array[String] = []
var evidence: Array[Dictionary] = []
var main: Node
var run_scene: Node
var adapter
var baseline_data: Dictionary = {}
var completed_data: Dictionary = {}
var save_path := "user://tests/i3r_tutorial_player_journey/meta_progress.json"
var evidence_path := "user://tests/i3r_tutorial_player_journey/journey.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production_main_missing")
	if packed == null:
		await _finish()
		return
	main = packed.instantiate()
	root.add_child(main)
	await _frames(14)
	run_scene = main.get_node_or_null("RunScene")
	_require(run_scene != null, "production_run_scene_missing")
	if run_scene == null:
		await _finish()
		return
	_bind_isolated_meta_progress()
	_record("main_ready")
	_require(StringName(run_scene.get("screen_state")) == &"main_menu", "journey_not_on_main_menu")
	await _tap_key(KEY_ENTER)
	_require(await _wait_screen(&"deploy_shell", 6.0), "main_enter_did_not_reach_deploy")
	_record("deploy_ready")

	for cycle in range(2):
		var replay := cycle == 1
		_require(await _select_tutorial_from_visible_catalog(replay), "tutorial_catalog_selection_failed:%d" % cycle)
		var deploy_page := _deploy_page()
		var start_button := deploy_page.find_child("DeployPrimaryAction", true, false) as Button if deploy_page != null else null
		_require(start_button != null and start_button.visible and not start_button.disabled, "tutorial_start_button_unreachable:%d" % cycle)
		if start_button == null:
			break
		await _click_control(start_button)
		_require(await _wait_screen(&"run", 6.0), "tutorial_standard_route_did_not_start:%d" % cycle)
		if StringName(run_scene.get("screen_state")) != &"run":
			break
		_require(await _play_tutorial_to_result(cycle), "tutorial_player_path_failed:%d" % cycle)
		if not _result_visible():
			break
		_validate_tutorial_result(cycle)
		var result_panel := run_scene.get("result_panel") as Control
		var return_button := (
			result_panel.get("return_deploy_button") as Button
			if cycle == 0
			else result_panel.get("return_main_button") as Button
		)
		_require(return_button != null and return_button.visible and not return_button.disabled, "tutorial_result_return_unreachable:%d" % cycle)
		if return_button == null:
			break
		await _click_control(return_button)
		var expected_screen := &"deploy_shell" if cycle == 0 else &"main_menu"
		_require(await _wait_screen(expected_screen, 5.0), "tutorial_result_return_failed:%d" % cycle)
		_record("completion_returned_to_deploy" if cycle == 0 else "replay_returned_to_main")

	await _finish()


func _bind_isolated_meta_progress() -> void:
	adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(save_path, "i3r_tutorial_player_journey")
	adapter.clear()
	adapter.data["gold"] = 321
	adapter.data["run_count"] = 8
	adapter.data["extract_count"] = 3
	adapter.data["fail_count"] = 2
	adapter.data["abandon_count"] = 1
	adapter.data["history_records"] = [{"history_id": "production_before"}]
	adapter.data["commission_history"] = [{"result_id": "production_before"}]
	adapter.data["map_success_counts"] = {"classic_7x7_simple": 2}
	adapter.data["tutorial_completed"] = false
	_require(adapter.save(), "isolated_meta_seed_save_failed")
	adapter.load_or_create_default()
	baseline_data = adapter.data.duplicate(true)
	var controller = run_scene.get("runtime_controller")
	_require(controller != null, "production_runtime_controller_missing")
	if controller != null:
		controller.bind_meta_progress_adapter(adapter)
	run_scene.set("meta_progress_adapter", adapter)


func _select_tutorial_from_visible_catalog(replay: bool) -> bool:
	var deploy_page := _deploy_page()
	if deploy_page == null:
		return false
	var map_split := deploy_page.get("map_split_view") as Control
	if map_split == null:
		return false
	var scale_buttons := map_split.get("scale_buttons") as Dictionary
	var scale_button := scale_buttons.get(&"5x5") as Button
	if scale_button == null or not scale_button.is_visible_in_tree() or scale_button.disabled:
		return false
	await _click_control(scale_button)
	var difficulty_ready := await _wait_until(func() -> bool:
		var current_split := deploy_page.get("map_split_view") as Control
		if current_split == null:
			return false
		var buttons := current_split.get("difficulty_buttons") as Dictionary
		return buttons.has(StringName(TutorialMapCatalogScript.MAP_ID))
	, 2.0)
	if not difficulty_ready:
		return false
	map_split = deploy_page.get("map_split_view") as Control
	var difficulty_buttons := map_split.get("difficulty_buttons") as Dictionary
	var tutorial_button := difficulty_buttons.get(StringName(TutorialMapCatalogScript.MAP_ID)) as Button
	if tutorial_button == null or not tutorial_button.is_visible_in_tree() or tutorial_button.disabled:
		return false
	await _click_control(tutorial_button)
	var selected_map_id := StringName(map_split.get("selected_map_id"))
	if selected_map_id != StringName(TutorialMapCatalogScript.MAP_ID):
		var select_button := map_split.get("select_action_button") as Button
		if select_button == null or not select_button.is_visible_in_tree() or select_button.disabled:
			return false
		await _click_control(select_button)
		var selected := await _wait_until(func() -> bool:
			var model: Dictionary = deploy_page.get("current_model")
			var config := model.get("config", {}) as Dictionary
			return str(config.get("map_config_id", "")) == TutorialMapCatalogScript.MAP_ID
		, 2.0)
		if not selected:
			return false
	map_split = deploy_page.get("map_split_view") as Control
	var detail := map_split.get("selected_detail") as Dictionary
	_require(str(detail.get("map_config_id", "")) == TutorialMapCatalogScript.MAP_ID, "tutorial_detail_not_selected")
	if replay:
		_require(bool(detail.get("tutorial_completed", false)), "replay_catalog_missing_completion_marker")
		_require(str(detail.get("completion_label", "")).contains("可重播"), "replay_catalog_missing_player_copy")
	_record("tutorial_catalog_replay" if replay else "tutorial_catalog_initial")
	return true


func _play_tutorial_to_result(cycle: int) -> bool:
	var context = run_scene.get("run_context")
	if context == null:
		return false
	_require(StringName(context.get("mode")) == &"tutorial", "production_tutorial_mode_missing:%d" % cycle)
	_require(str((context.get("run_start_config") as Dictionary).get("map_config_id", "")) == TutorialMapCatalogScript.MAP_ID, "production_tutorial_map_id_missing:%d" % cycle)
	_require(int(context.get("seed_value")) == TutorialMapCatalogScript.FIXED_SEED, "production_tutorial_seed_drift:%d" % cycle)
	_require(Vector2i(_status().get("position", Vector2i(-1, -1))) == Vector2i(0, 0), "tutorial_spawn_drift:%d" % cycle)
	_require(await _wait_popup(&"spawn_intro", true, 2.0), "spawn_popup_missing:%d" % cycle)
	var confirm_button := (run_scene.get("tutorial_popup_panel") as Control).find_child("ConfirmButton", true, false) as Button
	_require(confirm_button != null and root.gui_get_focus_owner() == confirm_button, "spawn_popup_focus_missing:%d" % cycle)
	var blocked_position := Vector2i(_status().get("position", Vector2i(-1, -1)))
	var blocked_local := _player_local_pos()
	await _hold_key(KEY_W, 0.25)
	_require(Vector2i(_status().get("position", Vector2i(-1, -1))) == blocked_position, "blocking_popup_allowed_room_move:%d" % cycle)
	_require(_player_local_pos().distance_to(blocked_local) <= 0.001, "blocking_popup_allowed_local_move:%d" % cycle)
	await _tap_key(KEY_ENTER)
	_require(await _wait_until(func() -> bool: return not _blocking_popup_active(), 2.0), "spawn_popup_keyboard_confirm_failed:%d" % cycle)
	_record("spawn_confirmed_%d" % cycle)

	if not await _transition_room(Vector2i.DOWN, Vector2i(0, 1), &"Normal"):
		return false
	_require(_popup_id() == &"number_rule", "number_rule_not_reached:%d" % cycle)
	if not await _transition_room(Vector2i.DOWN, Vector2i(0, 2), &"Mine"):
		return false
	_require(_popup_id() == &"mine_rule", "mine_rule_not_reached:%d" % cycle)
	_require(int((_status().get("stats", {}) as Dictionary).get("mine_hits", 0)) >= 1, "mine_effect_not_applied:%d" % cycle)
	if not await _transition_room(Vector2i.DOWN, Vector2i(0, 3), &"Event"):
		return false
	_require(_popup_id() in [&"event_rule", &"dice_rule", &"altar_rule", &"trap_rule"], "event_rule_not_reached:%d" % cycle)
	if not await _transition_room(Vector2i.DOWN, Vector2i(0, 4), &"Monster"):
		return false
	_require(await _wait_until(func() -> bool: return _combat_active(), 3.0), "tutorial_monster_did_not_start_combat:%d" % cycle)
	# The production monster room has a visible central altar. Route around its
	# top-right corner before aligning with the east flee door.
	if not await _move_axis(&"x", 0.80):
		_require(false, "tutorial_combat_altar_bypass_x_failed:%d" % cycle)
		return false
	if not await _move_axis(&"y", 0.50):
		_require(false, "tutorial_combat_altar_bypass_y_failed:%d" % cycle)
		return false
	if not await _move_axis(&"x", 0.91):
		_require(false, "tutorial_combat_east_door_alignment_failed:%d" % cycle)
		return false
	await _tap_key(KEY_T)
	var extract_panel := run_scene.get("extract_panel") as Control
	_require(await _wait_until(func() -> bool: return extract_panel != null and extract_panel.visible, 2.0), "tutorial_combat_flee_confirm_missing:%d" % cycle)
	var extract_confirm := run_scene.get("extract_confirm_button") as Button
	if extract_confirm == null:
		return false
	await _click_control(extract_confirm)
	_require(await _wait_room(Vector2i(1, 4), &"Chest", 4.0), "tutorial_combat_flee_did_not_reach_chest:%d" % cycle)
	_require(_popup_id() == &"chest_rule", "chest_rule_not_reached:%d" % cycle)
	if not await _transition_room(Vector2i.RIGHT, Vector2i(2, 4), &"Normal"):
		return false
	_require(_popup_id() == &"map_rule", "map_rule_not_reached:%d" % cycle)
	await _tap_key(KEY_M)
	_require(_map_visible(), "tutorial_map_semantic_input_failed:%d" % cycle)
	await _tap_key(KEY_ESCAPE)
	_require(await _wait_until(func() -> bool: return not _map_visible(), 2.0), "tutorial_map_escape_failed:%d" % cycle)
	if not await _transition_room(Vector2i.RIGHT, Vector2i(3, 4), &"Normal"):
		return false
	_require(_popup_id() == &"route_rule", "route_rule_not_reached:%d" % cycle)
	if not await _transition_room(Vector2i.RIGHT, Vector2i(4, 4), &"Exit"):
		return false
	_require(await _wait_popup(&"exit_goal", true, 2.0), "exit_goal_popup_missing:%d" % cycle)
	await _tap_key(KEY_ENTER)
	_require(await _wait_until(func() -> bool: return not _blocking_popup_active(), 2.0), "exit_goal_keyboard_confirm_failed:%d" % cycle)
	var exit_target := _first_interactable_position(&"exit")
	if exit_target.x < 0.0:
		exit_target = Vector2(0.68, 0.50)
	await _move_axis(&"y", exit_target.y)
	await _move_axis(&"x", exit_target.x)
	_require(await _wait_until(func() -> bool: return _context_kind() == &"exit", 2.0), "tutorial_exit_context_missing:%d" % cycle)
	await _tap_key(KEY_T)
	_require(await _wait_until(func() -> bool: return extract_panel != null and extract_panel.visible, 2.0), "tutorial_extract_preview_missing:%d" % cycle)
	extract_confirm = run_scene.get("extract_confirm_button") as Button
	if extract_confirm == null:
		return false
	await _click_control(extract_confirm)
	_require(await _wait_until(func() -> bool: return _result_visible(), 5.0), "tutorial_result_missing:%d" % cycle)
	_record("tutorial_result_%d" % cycle)
	return _result_visible()


func _validate_tutorial_result(cycle: int) -> void:
	var context = run_scene.get("run_context")
	var snapshot: Dictionary = context.get("result_snapshot") if context != null else {}
	var settlement := snapshot.get("settlement", {}) as Dictionary
	_require(StringName(snapshot.get("outcome", &"")) == &"Training Complete", "tutorial_result_outcome_wrong:%d" % cycle)
	_require(bool(settlement.get("tutorial_completion_only", false)), "tutorial_result_policy_missing:%d" % cycle)
	_require(bool(settlement.get("finalized", false)), "tutorial_result_not_finalized:%d" % cycle)
	_require(not bool(settlement.get("requires_salvage_selection", true)), "tutorial_result_exposed_salvage:%d" % cycle)
	for field in ["gold_coin", "run_black_coin", "gold_coin_gained", "long_term_gold_gained", "black_coin_converted"]:
		_require(int(settlement.get(field, -1)) == 0, "tutorial_result_currency_pollution:%d:%s" % [cycle, field])
	for field in ["warehouse_items", "settlement_pool", "salvaged_items", "lost_items", "extracted_items"]:
		var value: Variant = settlement.get(field, null)
		_require(value is Array and (value as Array).is_empty(), "tutorial_result_item_pollution:%d:%s" % [cycle, field])
	var result_panel := run_scene.get("result_panel") as Control
	var model := result_panel.get("current_result_model") as Dictionary
	var expected_state := &"tutorial_completed" if cycle == 0 else &"tutorial_replay_complete"
	_require(StringName(model.get("persistence_state", &"")) == expected_state, "tutorial_result_persistence_state_wrong:%d" % cycle)
	_require(bool(model.get("normal_exit_allowed", false)), "tutorial_result_exit_blocked:%d" % cycle)
	_require(not bool(model.get("retry_save_allowed", true)), "tutorial_result_retry_exposed:%d" % cycle)
	_require(not str(model.get("persistence_text", "")).contains("请重试"), "tutorial_result_false_retry_copy:%d" % cycle)
	var current_data: Dictionary = adapter.data.duplicate(true)
	if cycle == 0:
		_require(bool(current_data.get("tutorial_completed", false)), "production_completion_marker_not_saved")
		var normalized := current_data.duplicate(true)
		normalized["tutorial_completed"] = false
		_require(normalized == baseline_data, "production_completion_polluted_non_tutorial_meta")
		completed_data = current_data.duplicate(true)
	else:
		_require(current_data == completed_data, "production_replay_polluted_meta")
	var reloaded := MetaProgressAdapterScript.new()
	reloaded.set_active_profile_path(save_path, "i3r_tutorial_player_journey_reload")
	var current_normalized: Variant = _json_normalized(current_data)
	var reloaded_normalized: Variant = _json_normalized(reloaded.data)
	_require(
		reloaded_normalized == current_normalized,
		"production_tutorial_save_not_reloadable:%d" % cycle
	)


func _json_normalized(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func _transition_room(direction: Vector2i, expected_pos: Vector2i, expected_type: StringName) -> bool:
	var before := Vector2i(_status().get("position", Vector2i(-1, -1)))
	if direction.x != 0:
		await _move_axis(&"y", 0.22)
		await _move_axis(&"x", 0.82 if direction.x > 0 else 0.18)
		await _move_axis(&"y", 0.50)
		var key := KEY_D if direction.x > 0 else KEY_A
		await _hold_until(key, func() -> bool: return Vector2i(_status().get("position", before)) != before, 2.5)
	else:
		await _move_axis(&"x", 0.22)
		await _move_axis(&"y", 0.82 if direction.y > 0 else 0.18)
		await _move_axis(&"x", 0.50)
		var key := KEY_S if direction.y > 0 else KEY_W
		await _hold_until(key, func() -> bool: return Vector2i(_status().get("position", before)) != before, 2.5)
	return await _wait_room(expected_pos, expected_type, 2.0)


func _move_axis(axis: StringName, target: float) -> bool:
	for _attempt in range(3):
		var current := _player_local_pos()
		var value := current.x if axis == &"x" else current.y
		if absf(value - target) <= 0.035:
			return true
		var increasing := target > value
		var key := KEY_D if axis == &"x" and increasing else (KEY_A if axis == &"x" else (KEY_S if increasing else KEY_W))
		var reached := await _hold_until(key, func() -> bool:
			var next := _player_local_pos()
			var next_value := next.x if axis == &"x" else next.y
			return next_value >= target if increasing else next_value <= target
		, 1.9)
		await create_timer(0.08).timeout
		if not reached:
			return false
	var resolved := _player_local_pos()
	return absf((resolved.x if axis == &"x" else resolved.y) - target) <= 0.09


func _hold_until(keycode: int, condition: Callable, timeout_seconds: float) -> bool:
	_parse_key(keycode, true)
	var reached := await _wait_until(condition, timeout_seconds)
	_parse_key(keycode, false)
	await _frames(2)
	return reached


func _hold_key(keycode: int, seconds: float) -> void:
	_parse_key(keycode, true)
	await create_timer(seconds).timeout
	_parse_key(keycode, false)
	await _frames(2)


func _tap_key(keycode: int) -> void:
	_parse_key(keycode, true)
	await process_frame
	_parse_key(keycode, false)
	await _frames(3)


func _parse_key(keycode: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.unicode = keycode if keycode >= 32 and keycode <= 126 else 0
	event.pressed = pressed
	event.echo = false
	Input.parse_input_event(event)


func _click_control(control: Control) -> void:
	if control == null:
		return
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await _frames(3)


func _wait_popup(expected_id: StringName, blocking: bool, timeout_seconds: float) -> bool:
	return await _wait_until(func() -> bool:
		var panel := run_scene.get("tutorial_popup_panel") as Control if run_scene != null else null
		return panel != null and panel.visible and _popup_id() == expected_id and _blocking_popup_active() == blocking
	, timeout_seconds)


func _wait_screen(expected: StringName, timeout_seconds: float) -> bool:
	return await _wait_until(func() -> bool: return StringName(run_scene.get("screen_state")) == expected, timeout_seconds)


func _wait_room(expected_pos: Vector2i, expected_type: StringName, timeout_seconds: float) -> bool:
	return await _wait_until(func() -> bool:
		var snapshot := _status()
		return Vector2i(snapshot.get("position", Vector2i(-1, -1))) == expected_pos and StringName(snapshot.get("current_room", &"Unknown")) == expected_type
	, timeout_seconds)


func _wait_until(predicate: Callable, timeout_seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() <= deadline:
		if bool(predicate.call()):
			return true
		await create_timer(FRAME_STEP).timeout
	return bool(predicate.call())


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _deploy_page() -> Control:
	var shell = run_scene.get("ui_shell") if run_scene != null else null
	return shell.call("get_deploy_page") as Control if shell != null else null


func _status() -> Dictionary:
	var context = run_scene.get("run_context") if run_scene != null else null
	return context.get_status_snapshot() if context != null else {}


func _player_local_pos() -> Vector2:
	var player = run_scene.get("player_controller") if run_scene != null else null
	return player.get_local_position() if player != null else Vector2(-1, -1)


func _combat_active() -> bool:
	var runtime = run_scene.get("in_run_runtime") if run_scene != null else null
	return runtime != null and runtime.has_active_combat()


func _map_visible() -> bool:
	var panel := run_scene.get("map_overlay_panel") as Control if run_scene != null else null
	return panel != null and panel.visible


func _result_visible() -> bool:
	var panel := run_scene.get("result_panel") as Control if run_scene != null else null
	return panel != null and panel.visible


func _popup_id() -> StringName:
	var context = run_scene.get("run_context") if run_scene != null else null
	var popup: Dictionary = context.get("tutorial_popup") if context != null else {}
	return StringName(popup.get("id", &""))


func _blocking_popup_active() -> bool:
	var context = run_scene.get("run_context") if run_scene != null else null
	return context != null and context.has_blocking_tutorial_popup()


func _context_kind() -> StringName:
	var view = run_scene.get("room_runtime_view") if run_scene != null else null
	var popup = view.get("context_popup") if view != null else null
	return StringName(popup.get("context_kind")) if popup != null and popup.visible else &"none"


func _first_interactable_position(kind: StringName) -> Vector2:
	var view = run_scene.get("room_runtime_view") if run_scene != null else null
	if view == null:
		return Vector2(-1, -1)
	var snapshot: Dictionary = view.call("build_read_only_snapshot")
	for raw in snapshot.get("interactables", []) as Array:
		if raw is Dictionary and StringName((raw as Dictionary).get("interaction_kind", &"")) == kind:
			return Vector2((raw as Dictionary).get("local_pos", Vector2(-1, -1)))
	return Vector2(-1, -1)


func _record(step: String) -> void:
	var status := _status()
	evidence.append({
		"step": step,
		"screen": String(run_scene.get("screen_state")) if run_scene != null else "missing",
		"position": {
			"x": int((status.get("position", Vector2i(-1, -1)) as Vector2i).x),
			"y": int((status.get("position", Vector2i(-1, -1)) as Vector2i).y),
		},
		"room": String(status.get("current_room", &"Unknown")),
		"phase": String(status.get("phase", &"")),
		"popup": String(_popup_id()),
	})


func _write_evidence() -> String:
	var absolute_path := ProjectSettings.globalize_path(evidence_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		failures.append("tutorial_journey_evidence_write_failed")
		return absolute_path
	file.store_string(JSON.stringify({
		"contract": "production main.tscn Deploy-catalog tutorial completion and replay",
		"route": "tutorial_5x5 -> standard_run",
		"fixed_seed": TutorialMapCatalogScript.FIXED_SEED,
		"input_transport": "Input.parse_input_event",
		"cycles": ["tutorial_completed", "tutorial_replay_complete"],
		"zero_growth_pollution": completed_data == adapter.data,
		"steps": evidence,
		"failures": failures,
	}, "\t"))
	file.close()
	return absolute_path


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	var written_evidence := _write_evidence()
	if main != null and is_instance_valid(main):
		main.free()
	main = null
	run_scene = null
	adapter = null
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = save_path + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	await _frames(2)
	if failures.is_empty():
		print("%s host=main.tscn route=deploy_catalog_to_standard_run cycles=completion,replay input=parsed zero_pollution=true return=main evidence=%s" % [PASS_MARKER, written_evidence])
		quit(0)
		return
	for failure in failures:
		push_error("I3R tutorial player journey failure: " + failure)
	print("%s count=%d evidence=%s" % [FAIL_MARKER, failures.size(), written_evidence])
	quit(1)
