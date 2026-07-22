extends SceneTree

const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")

const PASS_MARKER := "I3_PRODUCTION_INPUT_JOURNEY=PASS"
const FAIL_MARKER := "I3_PRODUCTION_INPUT_JOURNEY=FAIL"
const FIXED_SEED := 13
const FRAME_STEP := 0.02

var failures: Array[String] = []
var evidence_rows: Array[Dictionary] = []
var transition_measurements: Array[Dictionary] = []
var evidence_contract := "I3 production main.tscn genuine-input success/save-retry journey"
var evidence_dir := "user://tests/i3_production_input_journey"
var screenshot_count := 0
var main: Node
var run_scene: Node
var journey_started_msec := 0
var blocker_path := ""
var require_screenshots := false
var quit_scheduled := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	evidence_dir = _option("evidence-dir", evidence_dir)
	require_screenshots = _bool_option("require-screenshots", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_dir))
	journey_started_msec = Time.get_ticks_msec()

	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production main.tscn could not be loaded")
	if packed == null:
		_finish()
		return
	main = packed.instantiate()
	root.add_child(main)
	await _frames(12)
	run_scene = main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing")
	if run_scene == null:
		_finish()
		return

	await _configure_isolated_save_failure_fixture()
	await _checkpoint("01_main_menu", "production entry ready")
	_require(StringName(run_scene.get("screen_state")) == &"main_menu", "journey did not begin on the production main menu")
	_require(_focus_name().begins_with("MainMenuEntry_deploy"), "main menu did not expose deploy as the default keyboard focus")

	_require(
		await _enter_deploy_through_cave_transition("01b_main_enter_cave_motion"),
		"real Enter input did not complete the measured enter-cave transition"
	)
	await _checkpoint("02_deploy", "main-to-deploy transition completed")
	var deploy_page := _deploy_page()
	_require(deploy_page != null, "production deploy page is missing")
	if deploy_page == null:
		_finish()
		return
	_set_only_fixed_seed(deploy_page)
	var start_button := deploy_page.find_child("DeployPrimaryAction", true, false) as Button
	_require(start_button != null and start_button.visible and not start_button.disabled, "deploy primary action is not reachable")
	if start_button == null:
		_finish()
		return
	await _click_control(start_button, "deploy.confirm_start")
	_require(await _wait_screen(&"run", 6.0), "real pointer input did not start the production run")
	await _frames(8)
	var started := _status()
	_require(int(run_scene.get("run_context").get("seed_value")) == FIXED_SEED, "fixed seed did not reach the authoritative run")
	_require(Vector2i(started.get("position", Vector2i(-1, -1))) == Vector2i(2, 6), "seed-13 run did not start at the audited spawn")
	await _checkpoint("03_run_spawn", "run admitted through deploy")

	await _tap_key(KEY_M, "run.map_open")
	_require(_map_visible(), "real M input did not open the expanded map")
	await _checkpoint("04_map_open", "expanded map visible")
	await _click_point(Vector2(10, 10), "run.map_outside_click")
	_require(await _wait_until(func() -> bool: return not _map_visible(), 2.0), "outside pointer click did not close the expanded map")
	await _tap_key(KEY_M, "run.map_reopen")
	_require(_map_visible(), "map could not be reopened after outside-click close")
	await _tap_key(KEY_ESCAPE, "run.map_escape_close")
	_require(await _wait_until(func() -> bool: return not _map_visible(), 2.0), "Esc did not close the expanded map")

	_require(await _transition_room(Vector2i.RIGHT, Vector2i(3, 6), &"Chest"), "real movement did not enter the audited chest room")
	await _move_axis(&"x", 0.53)
	_require(await _wait_context(&"chest", 2.0), "chest proximity did not automatically expose its context")
	var before_chest := _status()
	_require(not bool((before_chest.get("search_state_data", {}) as Dictionary).get("searched", false)), "chest was already open before explicit input")
	await _checkpoint("05_chest_first_proximity", "closed chest context visible")
	await _tap_key(KEY_E, "chest.open")
	_require(await _wait_until(func() -> bool: return bool((_status().get("search_state_data", {}) as Dictionary).get("searched", false)), 3.0), "real E input did not open the chest")
	await _frames(20)
	_require(_context_kind() == &"chest" and _context_opened_once(), "opened chest did not expose stable container contents")
	_require(_context_item_count() > 0, "opened chest did not present its authoritative contents")
	await _checkpoint("06_chest_opened", "opened contents stable")
	await _move_axis(&"x", 0.28)
	_require(await _wait_until(func() -> bool: return _context_kind() == &"none", 2.0), "leaving chest proximity did not clear the context")
	await _move_axis(&"x", 0.53)
	_require(await _wait_context(&"chest", 2.0), "returning to the opened chest did not restore its contents")
	_require(_context_opened_once() and _context_item_count() > 0, "repeat chest proximity regressed to explanatory/closed state")
	await _checkpoint("07_chest_repeat_proximity", "opened contents restored without a second search")
	var inventory_before_pickup := (_status().get("inventory_items", []) as Array).size()
	await _tap_key(KEY_G, "chest.pickup_first_item")
	_require(await _wait_until(func() -> bool: return (_status().get("inventory_items", []) as Array).size() > inventory_before_pickup, 3.0), "real G input did not pick an opened chest item")

	_require(await _transition_room(Vector2i.UP, Vector2i(3, 5), &"Event"), "real movement did not enter the audited event room")
	await _move_axis(&"y", 0.58)
	_require(await _wait_context(&"event", 2.0), "event proximity did not expose player-facing context")
	await _checkpoint("08_event_proximity", "event decision available")
	await _tap_key(KEY_E, "event.open")
	var event_panel := run_scene.get("event_panel") as Control
	_require(await _wait_until(func() -> bool: return event_panel != null and event_panel.visible, 2.0), "real E input did not open the event decision modal")
	var event_choice := _first_enabled_button(run_scene.get("event_options_box") as Control)
	_require(event_choice != null, "event modal exposed no enabled player decision")
	if event_choice != null:
		await _click_control(event_choice, "event.choose_first_enabled")
	_require(await _wait_until(func() -> bool: return bool((_status().get("event_state", {}) as Dictionary).get("completed", false)), 3.0), "real event choice did not settle the authoritative event")
	await _close_optional_runtime_modal("event.reward_close")
	await _checkpoint("09_event_resolved", "event settlement visible")

	_require(await _transition_room(Vector2i.UP, Vector2i(3, 4), &"Normal"), "real movement did not enter the audited normal room")
	var carried_before_drop := (_status().get("inventory_items", []) as Array).size()
	_require(carried_before_drop > 0, "no carried item remained for the ground-loot journey")
	await _tap_key(KEY_Q, "inventory.open_for_drop")
	var inventory_panel := run_scene.get("inventory_panel") as Control
	_require(await _wait_until(func() -> bool: return inventory_panel != null and inventory_panel.visible, 2.0), "real Q input did not open the inventory")
	var drop_button := inventory_panel.find_child("InventoryDropButton", true, false) as Button
	_require(drop_button != null and not drop_button.disabled, "inventory exposed no droppable carried item")
	if drop_button != null:
		await _click_control(drop_button, "inventory.drop_item")
	_require(await _wait_until(func() -> bool: return (_status().get("inventory_items", []) as Array).size() < carried_before_drop, 3.0), "real inventory drop input did not create a floor item")
	await _tap_key(KEY_Q, "inventory.close_after_drop")
	_require(await _wait_until(func() -> bool: return inventory_panel != null and not inventory_panel.visible, 2.0), "Q did not close the inventory drawer")
	var ground_target := _first_interactable_position(&"ground_loot")
	_require(ground_target.x >= 0.0, "dropped item did not project as ground loot")
	if ground_target.x >= 0.0:
		await _move_axis(&"x", ground_target.x)
		await _move_axis(&"y", minf(0.86, ground_target.y + 0.10))
	_require(await _wait_context(&"ground_loot", 2.0), "approaching ground loot did not automatically show its contents")
	await _checkpoint("10_ground_loot_auto", "ground item visible before pickup")
	var inventory_before_ground_pickup := (_status().get("inventory_items", []) as Array).size()
	await _tap_key(KEY_G, "ground.pickup")
	_require(await _wait_until(func() -> bool: return (_status().get("inventory_items", []) as Array).size() > inventory_before_ground_pickup, 3.0), "real G input did not pick the ground item")

	_require(await _transition_room(Vector2i.LEFT, Vector2i(2, 4), &"Monster"), "real movement did not enter the audited combat room")
	_require(await _wait_until(func() -> bool: return _combat_active(), 3.0), "monster entry did not start production combat")
	await _checkpoint("11_combat_enter", "combat active and doors locked")
	_require(await _move_to_combat_door(Vector2i.UP), "real combat movement did not reach the north door")
	await _tap_key(KEY_T, "combat.flee_preview")
	var extract_panel := run_scene.get("extract_panel") as Control
	_require(await _wait_until(func() -> bool: return extract_panel != null and extract_panel.visible, 2.0), "T at a combat door did not open explicit flee confirmation")
	await _checkpoint("12_combat_flee_confirm", "explicit combat leave decision visible")
	var extract_cancel := run_scene.get("extract_cancel_button") as Button
	await _click_control(extract_cancel, "combat.flee_cancel")
	_require(await _wait_until(func() -> bool: return extract_panel != null and not extract_panel.visible, 2.0), "combat flee cancellation did not return to combat")
	_require(_combat_active(), "cancelling combat flee ended combat")
	await _tap_key(KEY_T, "combat.flee_reopen")
	var extract_confirm := run_scene.get("extract_confirm_button") as Button
	_require(await _wait_until(func() -> bool: return extract_panel != null and extract_panel.visible, 2.0), "combat flee confirmation could not be reopened")
	await _click_control(extract_confirm, "combat.flee_confirm")
	_require(await _wait_room(Vector2i(2, 3), &"Mine", 4.0), "explicit combat flee did not enter the audited mine room")
	var mine_room_snapshot := (run_scene.get("room_runtime_view") as Node).call("build_read_only_snapshot") as Dictionary
	_require(bool(mine_room_snapshot.get("mine_feedback_active", false)), "mine entry did not expose its entry feedback")
	await _checkpoint("13_mine_entry", "mine consequence feedback active")
	await _move_axis(&"y", 0.69)
	_require(await _wait_context(&"mine", 2.0), "mine proximity did not expose readable hazard state")
	await _tap_key(KEY_E, "mine.inspect")
	_require(_run_feedback_text().contains("机关") or _run_feedback_text().contains("雷区"), "mine inspect input did not return player-facing status")

	_require(await _transition_room(Vector2i.DOWN, Vector2i(2, 4), &"Monster"), "real movement did not return to the combat room")
	_require(await _wait_until(func() -> bool: return _combat_active(), 3.0), "re-entered monster room did not retain authoritative combat")
	_require(await _move_to_combat_door(Vector2i.LEFT), "real combat movement did not reach the west door")
	await _tap_key(KEY_T, "combat.second_flee_preview")
	_require(await _wait_until(func() -> bool: return extract_panel != null and extract_panel.visible, 2.0), "second explicit combat flee decision did not open")
	await _click_control(extract_confirm, "combat.second_flee_confirm")
	_require(await _wait_room(Vector2i(1, 4), &"Normal", 4.0), "second explicit combat flee did not reach the west normal room")
	_require(await _transition_room(Vector2i.LEFT, Vector2i(0, 4), &"Exit"), "real movement did not reach the audited exit room")
	await _move_axis(&"x", 0.68)
	_require(await _wait_context(&"exit", 2.0), "exit proximity did not automatically expose benefit/left-behind/objective context")
	await _checkpoint("14_exit_proximity", "exit summary visible")
	await _tap_key(KEY_E, "exit.preview")
	_require(await _wait_until(func() -> bool: return extract_panel != null and extract_panel.visible, 2.0), "real exit interaction did not open extraction preview")
	_require(StringName(_status().get("phase", &"")) == &"confirm_extract", "exit preview did not enter confirm_extract authority state")
	await _checkpoint("15_exit_preview", "extract summary and decisions visible")
	await _click_control(extract_cancel, "exit.cancel")
	_require(await _wait_until(func() -> bool: return extract_panel != null and not extract_panel.visible, 2.0), "exit cancel did not close the confirmation")
	_require(StringName(_status().get("phase", &"")) == &"running", "exit cancel did not resume the run")
	await _tap_key(KEY_E, "exit.preview_again")
	_require(await _wait_until(func() -> bool: return extract_panel != null and extract_panel.visible, 2.0), "exit confirmation could not be reopened")
	await _click_control(extract_confirm, "exit.confirm")
	var result_panel := run_scene.get("result_panel") as Control
	_require(await _wait_until(func() -> bool: return result_panel != null and result_panel.visible, 5.0), "confirmed extraction did not open the production result")
	var result_snapshot: Dictionary = run_scene.get("run_context").get("result_snapshot")
	_require(StringName(result_snapshot.get("outcome", &"")) == &"Extracted", "success journey did not settle as Extracted")
	_require(result_panel.call("retry_save_allowed"), "isolated save blocker did not expose real save retry")
	await _checkpoint("16_result_save_failed", "successful extraction visible with save failure")
	var retry_button := result_panel.get("retry_save_button") as Button
	await _click_control(retry_button, "result.retry_while_blocked")
	_require(result_panel.call("retry_save_allowed"), "blocked save retry incorrectly unlocked ordinary exits")
	_require(DirAccess.remove_absolute(ProjectSettings.globalize_path(blocker_path)) == OK, "could not release the isolated save blocker")
	await _click_control(retry_button, "result.retry_after_release")
	_require(await _wait_until(func() -> bool: return bool(result_panel.call("normal_exit_allowed")), 4.0), "real retry input did not persist the same terminal snapshot")
	await _checkpoint("17_result_saved", "same terminal snapshot persisted after retry")
	var return_main := result_panel.get("return_main_button") as Button
	_require(return_main != null and return_main.visible and not return_main.disabled, "saved result did not expose return-to-main")
	await _click_control(return_main, "result.return_main")
	_require(await _wait_screen(&"main_menu", 4.0), "real result input did not return outside the run")
	await _checkpoint("18_return_main", "success journey closed outside")
	_finish()


func _configure_isolated_save_failure_fixture() -> void:
	var fixture_root := "%s/save_retry" % evidence_dir
	var blocked_save_path := "%s/meta_progress.json" % fixture_root
	blocker_path = blocked_save_path
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(fixture_root))
	if FileAccess.file_exists(blocker_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(blocker_path))
	_require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(blocker_path)) == OK, "could not create isolated save blocker directory")
	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(blocked_save_path, "i3_production_input_journey")
	run_scene.get("runtime_controller").bind_meta_progress_adapter(adapter)
	run_scene.set("meta_progress_adapter", adapter)
	await process_frame


func _enter_deploy_through_cave_transition(checkpoint_id: String) -> bool:
	var app_shell = run_scene.get("ui_shell") if run_scene != null else null
	var main_page := app_shell.call("get_main_page") as Control if app_shell != null else null
	var character := main_page.get("character_texture") as TextureRect if main_page != null else null
	_require(app_shell != null, "production app shell is missing for enter-cave measurement")
	_require(main_page != null and main_page.visible, "main page is not visible before enter-cave input")
	_require(character != null and character.visible, "main character is missing before enter-cave input")
	if app_shell == null or main_page == null or character == null:
		return false

	var initial_position := character.position
	var initial_scale := character.scale
	var started_msec := Time.get_ticks_msec()
	var saw_playing := false
	var saw_expected_profile := false
	var mid_motion_recorded := false
	var max_displacement := 0.0
	var max_upward_travel := 0.0
	var min_scale_ratio := 1.0
	var observed_character_frames: Dictionary = {}
	await _tap_key(KEY_ENTER, "main.accept_deploy")
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() <= deadline and StringName(run_scene.get("screen_state")) != &"deploy_shell":
		var transition_snapshot: Dictionary = app_shell.call("get_navigation_transition_snapshot")
		if bool(transition_snapshot.get("busy", false)):
			saw_playing = saw_playing or StringName(transition_snapshot.get("state", &"")) == &"playing"
			saw_expected_profile = saw_expected_profile or StringName(transition_snapshot.get("profile_id", &"")) == &"enter_cave"
			if StringName(transition_snapshot.get("profile_id", &"")) == &"enter_cave" and character.texture != null:
				var frame_key := character.texture.resource_path
				if frame_key == "":
					frame_key = str(character.texture.get_instance_id())
				observed_character_frames[frame_key] = true
		var displacement := character.position.distance_to(initial_position)
		max_displacement = maxf(max_displacement, displacement)
		max_upward_travel = maxf(max_upward_travel, initial_position.y - character.position.y)
		if absf(initial_scale.x) > 0.001:
			min_scale_ratio = minf(min_scale_ratio, absf(character.scale.x / initial_scale.x))
		if not mid_motion_recorded and displacement >= 30.0:
			mid_motion_recorded = true
			await _checkpoint(checkpoint_id, "enter_cave character travel visible before route commit")
		await create_timer(FRAME_STEP).timeout

	var duration_msec := Time.get_ticks_msec() - started_msec
	var final_transition: Dictionary = app_shell.call("get_navigation_transition_snapshot")
	var last_result: Dictionary = final_transition.get("last_result", {})
	var measurement := {
		"profile": "enter_cave",
		"duration_msec": duration_msec,
		"max_character_displacement": max_displacement,
		"max_character_upward_travel": max_upward_travel,
		"min_character_scale_ratio": min_scale_ratio,
		"observed_character_frame_count": observed_character_frames.size(),
		"mid_motion_checkpoint": mid_motion_recorded,
		"saw_playing_state": saw_playing,
		"route_outcome": String(last_result.get("outcome", &"")),
		"route_page": String(last_result.get("page", &"")),
		"commit_count": int(last_result.get("commit_count", 0)),
	}
	transition_measurements.append(measurement.duplicate(true))
	var measurement_row := _evidence_snapshot("main.enter_cave.measurement", "measurement")
	measurement_row["input"] = measurement.duplicate(true)
	measurement_row["visible_feedback"] = "strict character displacement, scale and timing measurement"
	evidence_rows.append(measurement_row)

	_require(saw_playing and saw_expected_profile, "enter-cave playback/profile was not observed before routing")
	_require(mid_motion_recorded, "enter-cave route committed without an observable in-scene motion checkpoint")
	_require(max_displacement >= 90.0, "enter-cave character displacement was below 90 logical pixels")
	_require(max_upward_travel >= 75.0, "enter-cave character did not materially travel into the cave")
	_require(min_scale_ratio <= 0.70, "enter-cave character did not visibly recede into the cave")
	_require(observed_character_frames.size() >= 3, "enter-cave playback exposed fewer than three distinct character frames")
	_require(duration_msec >= 560, "enter-cave route committed before a non-trivial transition duration")
	_require(duration_msec <= 3000, "enter-cave transition exceeded the bounded presentation window")
	_require(StringName(run_scene.get("screen_state")) == &"deploy_shell", "enter-cave transition did not route to deploy")
	_require(StringName(last_result.get("outcome", &"")) == &"committed", "enter-cave route was not committed")
	_require(StringName(last_result.get("page", &"")) == &"deploy_prep", "enter-cave route committed to the wrong page")
	_require(int(last_result.get("commit_count", 0)) == 1, "enter-cave route did not commit exactly once")
	return StringName(run_scene.get("screen_state")) == &"deploy_shell"


func _set_only_fixed_seed(deploy_page: Control) -> void:
	var current_model: Dictionary = deploy_page.get("current_model")
	var config: Dictionary = (current_model.get("config", {}) as Dictionary).duplicate(true)
	config["seed_value"] = FIXED_SEED
	current_model["config"] = config
	deploy_page.set("current_model", current_model)


func _transition_room(direction: Vector2i, expected_pos: Vector2i, expected_type: StringName) -> bool:
	var before := Vector2i(_status().get("position", Vector2i(-1, -1)))
	if direction.x != 0:
		await _move_axis(&"y", 0.22)
		await _move_axis(&"x", 0.82 if direction.x > 0 else 0.18)
		await _move_axis(&"y", 0.50)
		await _hold_until(KEY_D if direction.x > 0 else KEY_A, func() -> bool: return Vector2i(_status().get("position", before)) != before, 2.5, "move.room_horizontal")
	else:
		await _move_axis(&"x", 0.22)
		await _move_axis(&"y", 0.82 if direction.y > 0 else 0.18)
		await _move_axis(&"x", 0.50)
		await _hold_until(KEY_S if direction.y > 0 else KEY_W, func() -> bool: return Vector2i(_status().get("position", before)) != before, 2.5, "move.room_vertical")
	return await _wait_room(expected_pos, expected_type, 2.0)


func _move_to_combat_door(direction: Vector2i) -> bool:
	if direction == Vector2i.UP:
		await _move_axis(&"y", 0.18)
		await _move_axis(&"x", 0.50)
		await _move_axis(&"y", 0.09)
	elif direction == Vector2i.LEFT:
		await _move_axis(&"x", 0.18)
		await _move_axis(&"y", 0.50)
		await _move_axis(&"x", 0.09)
	var pos := _player_local_pos()
	if direction == Vector2i.UP:
		return pos.y <= 0.14 and absf(pos.x - 0.5) <= 0.16
	return pos.x <= 0.14 and absf(pos.y - 0.5) <= 0.16


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
		, 1.9, "move.axis_%s" % String(axis))
		await _seconds(0.10)
		if not reached:
			return false
	return absf((_player_local_pos().x if axis == &"x" else _player_local_pos().y) - target) <= 0.09


func _hold_until(keycode: int, condition: Callable, timeout_seconds: float, action: String) -> bool:
	_record_input(action + ".down", {"keycode": keycode})
	_parse_key(keycode, true)
	var reached := await _wait_until(condition, timeout_seconds)
	_parse_key(keycode, false)
	_record_input(action + ".up", {"keycode": keycode, "condition_reached": reached})
	await _frames(2)
	return reached


func _tap_key(keycode: int, action: String) -> void:
	_record_input(action, {"keycode": keycode})
	_parse_key(keycode, true)
	await process_frame
	_parse_key(keycode, false)
	await _frames(3)


func _parse_key(keycode: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	# Match a real keyboard event closely enough that text/shortcut consumers do
	# not attempt to decode the default NUL codepoint for printable keys.
	event.unicode = keycode if keycode >= 32 and keycode <= 126 else 0
	event.pressed = pressed
	event.echo = false
	Input.parse_input_event(event)


func _click_control(control: Control, action: String) -> void:
	if control == null:
		_require(false, "cannot click missing control for %s" % action)
		return
	await _click_point(control.get_global_rect().get_center(), action)


func _click_point(point: Vector2, action: String) -> void:
	_record_input(action, {"x": point.x, "y": point.y})
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


func _close_optional_runtime_modal(action: String) -> void:
	var stack = run_scene.get("modal_focus_stack")
	if stack == null or stack.depth() <= 0:
		return
	await _tap_key(KEY_ESCAPE, action)
	await _wait_until(func() -> bool: return stack.depth() == 0, 2.0)


func _wait_screen(expected: StringName, timeout_seconds: float) -> bool:
	return await _wait_until(func() -> bool: return StringName(run_scene.get("screen_state")) == expected, timeout_seconds)


func _wait_room(expected_pos: Vector2i, expected_type: StringName, timeout_seconds: float) -> bool:
	return await _wait_until(func() -> bool:
		var snapshot := _status()
		return Vector2i(snapshot.get("position", Vector2i(-1, -1))) == expected_pos and StringName(snapshot.get("current_room", &"Unknown")) == expected_type
	, timeout_seconds)


func _wait_context(kind: StringName, timeout_seconds: float) -> bool:
	return await _wait_until(func() -> bool: return _context_kind() == kind, timeout_seconds)


func _wait_until(predicate: Callable, timeout_seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() <= deadline:
		if bool(predicate.call()):
			return true
		await create_timer(FRAME_STEP).timeout
	return bool(predicate.call())


func _seconds(duration: float) -> void:
	if duration > 0.0:
		await create_timer(duration).timeout


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _status() -> Dictionary:
	var context = run_scene.get("run_context") if run_scene != null else null
	return context.get_status_snapshot() if context != null else {}


func _player_local_pos() -> Vector2:
	var player = run_scene.get("player_controller") if run_scene != null else null
	return player.get_local_position() if player != null else Vector2(-1, -1)


func _combat_active() -> bool:
	var runtime = run_scene.get("in_run_runtime") if run_scene != null else null
	return runtime != null and runtime.has_active_combat()


func _deploy_page() -> Control:
	var shell = run_scene.get("ui_shell") if run_scene != null else null
	return shell.call("get_deploy_page") as Control if shell != null else null


func _map_visible() -> bool:
	var overlay := run_scene.get("map_overlay_panel") as Control if run_scene != null else null
	return overlay != null and overlay.visible


func _context_popup():
	var view = run_scene.get("room_runtime_view") if run_scene != null else null
	return view.get("context_popup") if view != null else null


func _context_kind() -> StringName:
	var popup = _context_popup()
	return StringName(popup.get("context_kind")) if popup != null and popup.visible else &"none"


func _context_opened_once() -> bool:
	var popup = _context_popup()
	var context: Dictionary = popup.get("current_context") if popup != null else {}
	return bool(context.get("opened_once", false))


func _context_item_count() -> int:
	var popup = _context_popup()
	return (popup.get("context_items") as Array).size() if popup != null else 0


func _first_interactable_position(kind: StringName) -> Vector2:
	var view = run_scene.get("room_runtime_view") if run_scene != null else null
	if view == null:
		return Vector2(-1, -1)
	var snapshot: Dictionary = view.call("build_read_only_snapshot")
	for raw in snapshot.get("interactables", []) as Array:
		if raw is Dictionary and StringName((raw as Dictionary).get("interaction_kind", &"")) == kind:
			return Vector2((raw as Dictionary).get("local_pos", Vector2(-1, -1)))
	return Vector2(-1, -1)


func _first_enabled_button(parent: Control) -> Button:
	if parent == null:
		return null
	for child in parent.get_children():
		if child is Button and (child as Button).visible and not (child as Button).disabled:
			return child as Button
	return null


func _focus_name() -> String:
	var focus := root.gui_get_focus_owner()
	return String(focus.name) if focus != null else ""


func _run_feedback_text() -> String:
	var surface = run_scene.get("run_surface") if run_scene != null else null
	var label = surface.get("command_feedback_label") if surface != null else null
	return String(label.text) if label is Label else ""


func _record_input(action: String, detail: Dictionary = {}) -> void:
	var row := _evidence_snapshot(action, "input")
	row["input"] = detail.duplicate(true)
	evidence_rows.append(row)


func _checkpoint(id: String, feedback: String) -> void:
	await _frames(2)
	var screenshot_path := "%s/%s.png" % [evidence_dir, id]
	var screenshot_status := "unavailable"
	if DisplayServer.get_name() != "headless":
		var image := root.get_texture().get_image()
		if image != null and image.get_width() > 0 and image.get_height() > 0:
			var absolute_path := ProjectSettings.globalize_path(screenshot_path)
			DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
			if image.save_png(absolute_path) == OK:
				screenshot_count += 1
				screenshot_status = screenshot_path
	var row := _evidence_snapshot(id, "checkpoint")
	row["visible_feedback"] = feedback
	row["screenshot"] = screenshot_status
	evidence_rows.append(row)


func _evidence_snapshot(action: String, kind: String) -> Dictionary:
	var status := _status()
	var stack = run_scene.get("modal_focus_stack") if run_scene != null else null
	var result_snapshot: Dictionary = run_scene.get("run_context").get("result_snapshot") if run_scene != null and run_scene.get("run_context") != null else {}
	return {
		"sequence": evidence_rows.size() + 1,
		"elapsed_msec": Time.get_ticks_msec() - journey_started_msec,
		"kind": kind,
		"action": action,
		"screen": String(run_scene.get("screen_state")) if run_scene != null else "not_ready",
		"position": _vector2i_json(Vector2i(status.get("position", Vector2i(-1, -1)))),
		"room": String(status.get("current_room", &"Unknown")),
		"phase": String(status.get("phase", &"")),
		"run_active": bool(status.get("run_active", false)),
		"focus": _focus_name(),
		"modal": String(stack.top_modal_id()) if stack != null and stack.depth() > 0 else "none",
		"result": String(result_snapshot.get("outcome", "")),
		"terminal_reason_code": String(result_snapshot.get("terminal_reason_code", &"")),
		"backpack_used": int(status.get("backpack_used", 0)),
		"backpack_capacity": int(status.get("backpack_capacity", 0)),
	}


func _vector2i_json(value: Vector2i) -> Dictionary:
	return {"x": value.x, "y": value.y}


func _option(name: String, fallback: String) -> String:
	var prefix := "--%s=" % name
	for raw in OS.get_cmdline_user_args():
		var argument := String(raw)
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return fallback


func _bool_option(name: String, fallback: bool) -> bool:
	var value := _option(name, "true" if fallback else "false").to_lower()
	return value in ["1", "true", "yes", "on"]


func _write_evidence() -> String:
	var path := "%s/journey.json" % evidence_dir
	var absolute_path := ProjectSettings.globalize_path(path)
	var csv_path := "%s/journey.csv" % evidence_dir
	var csv_absolute_path := ProjectSettings.globalize_path(csv_path)
	_write_evidence_csv(csv_absolute_path)
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write journey evidence JSON")
		return absolute_path
	file.store_string(JSON.stringify({
		"contract": evidence_contract,
		"fixed_seed": FIXED_SEED,
		"input_transport": "Input.parse_input_event",
		"forbidden_shortcuts_used": false,
		"direct_setup_exceptions": ["fixed seed", "isolated save adapter/path"],
		"duration_msec": Time.get_ticks_msec() - journey_started_msec,
		"screenshot_count": screenshot_count,
		"csv_evidence": csv_absolute_path,
		"transition_measurements": transition_measurements,
		"steps": evidence_rows,
		"failures": failures,
	}, "\t"))
	file.close()
	return absolute_path


func _write_evidence_csv(absolute_path: String) -> void:
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write journey evidence CSV")
		return
	file.store_csv_line(PackedStringArray([
		"sequence", "elapsed_msec", "kind", "action", "screen", "position_x", "position_y",
		"room", "phase", "run_active", "focus", "modal", "result", "terminal_reason_code",
		"backpack_used", "backpack_capacity", "input_json", "visible_feedback", "screenshot",
	]))
	for row in evidence_rows:
		var position: Dictionary = row.get("position", {})
		file.store_csv_line(PackedStringArray([
			str(row.get("sequence", "")),
			str(row.get("elapsed_msec", "")),
			str(row.get("kind", "")),
			str(row.get("action", "")),
			str(row.get("screen", "")),
			str(position.get("x", "")),
			str(position.get("y", "")),
			str(row.get("room", "")),
			str(row.get("phase", "")),
			str(row.get("run_active", "")),
			str(row.get("focus", "")),
			str(row.get("modal", "")),
			str(row.get("result", "")),
			str(row.get("terminal_reason_code", "")),
			str(row.get("backpack_used", "")),
			str(row.get("backpack_capacity", "")),
			JSON.stringify(row.get("input", {})),
			str(row.get("visible_feedback", "")),
			str(row.get("screenshot", "")),
		]))
	file.close()


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if blocker_path != "" and (FileAccess.file_exists(blocker_path) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(blocker_path))):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(blocker_path))
	if require_screenshots:
		_require(screenshot_count >= 13, "dynamic journey emitted fewer than 13 screenshots")
	var evidence_path := _write_evidence()
	_dispose_main_immediately()
	if failures.is_empty():
		print("%s seed=%d checkpoints=19 screenshots=%d inputs=%d result=Extracted save_retry=real return=main evidence=%s csv=%s" % [PASS_MARKER, FIXED_SEED, screenshot_count, evidence_rows.size(), evidence_path, ProjectSettings.globalize_path("%s/journey.csv" % evidence_dir)])
		_schedule_quit(0)
		return
	for failure in failures:
		push_error("I3 production input journey failure: " + failure)
	print("%s failures=%d screenshots=%d evidence=%s" % [FAIL_MARKER, failures.size(), screenshot_count, evidence_path])
	_schedule_quit(1)


func _dispose_main_immediately() -> void:
	if main != null and is_instance_valid(main):
		main.free()
	main = null
	run_scene = null


func _schedule_quit(exit_code: int) -> void:
	if quit_scheduled:
		return
	quit_scheduled = true
	call_deferred("_quit_after_cleanup", exit_code)


func _quit_after_cleanup(exit_code: int) -> void:
	# Let the calling journey coroutine unwind so local PackedScene/Control
	# references are released before SceneTree performs its leak diagnostics.
	await process_frame
	await process_frame
	quit(exit_code)
