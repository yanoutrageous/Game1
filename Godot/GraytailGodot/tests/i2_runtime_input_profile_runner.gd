extends SceneTree

const RuntimeInputProfileScript := preload("res://scripts/core/input/runtime_input_profile.gd")

const PASS_MARKER := "I2_RUNTIME_INPUT_PROFILE=PASS"
const FAIL_MARKER := "I2_RUNTIME_INPUT_PROFILE=FAIL"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var keyboard_counts_before := {}
	for action_name in ["move_up", "move_down", "move_left", "move_right", "interact", "attack", "open_map", "open_inventory", "flag_cell", "cancel", "pause"]:
		keyboard_counts_before[action_name] = _event_type_count(action_name, "InputEventKey")

	RuntimeInputProfileScript.install()
	var counts_after_first := _all_action_event_counts()
	var second_result: Dictionary = RuntimeInputProfileScript.install()
	var counts_after_second := _all_action_event_counts()
	_require_equal(int(second_result.get("events_added", -1)), 0, "idempotent event install")
	_require_equal(counts_after_second, counts_after_first, "idempotent action event counts")

	for action_name in keyboard_counts_before:
		_require(int(keyboard_counts_before[action_name]) > 0, "keyboard baseline is missing from %s" % action_name)
		_require(
			_event_type_count(action_name, "InputEventKey") >= int(keyboard_counts_before[action_name]),
			"keyboard mapping was removed from %s" % action_name
		)
	_require(_has_button("interact", JOY_BUTTON_A), "A did not map to interact")
	_require(_has_button("ui_accept", JOY_BUTTON_A), "A did not map to ui_accept")
	_require(_has_button("cancel", JOY_BUTTON_B), "B did not map to cancel")
	_require(_has_button("ui_cancel", JOY_BUTTON_B), "B did not map to ui_cancel")
	_require(_has_button("attack", JOY_BUTTON_X), "X did not map to attack")
	_require(_has_button("open_map", JOY_BUTTON_Y), "Y did not map to open_map")
	_require(_has_button("open_inventory", JOY_BUTTON_LEFT_SHOULDER), "LB did not map to open_inventory")
	_require(_has_button("flag_cell", JOY_BUTTON_RIGHT_SHOULDER), "RB did not map to flag_cell")
	_require(_has_button("pause", JOY_BUTTON_START), "Start did not map to pause")

	_require(_has_axis("move_up", JOY_AXIS_LEFT_Y, -1.0), "left stick up mapping")
	_require(_has_axis("move_down", JOY_AXIS_LEFT_Y, 1.0), "left stick down mapping")
	_require(_has_axis("move_left", JOY_AXIS_LEFT_X, -1.0), "left stick left mapping")
	_require(_has_axis("move_right", JOY_AXIS_LEFT_X, 1.0), "left stick right mapping")
	_require(_has_button("move_up", JOY_BUTTON_DPAD_UP), "D-pad up mapping")
	_require(_has_button("move_down", JOY_BUTTON_DPAD_DOWN), "D-pad down mapping")
	_require(_has_button("move_left", JOY_BUTTON_DPAD_LEFT), "D-pad left mapping")
	_require(_has_button("move_right", JOY_BUTTON_DPAD_RIGHT), "D-pad right mapping")
	_finish()


func _all_action_event_counts() -> Dictionary:
	var result := {}
	for action_name in RuntimeInputProfileScript.BUTTON_BINDINGS:
		result[action_name] = InputMap.action_get_events(action_name).size()
	for action_name in RuntimeInputProfileScript.DIRECTION_BINDINGS:
		result[action_name] = InputMap.action_get_events(action_name).size()
	return result


func _event_type_count(action_name: String, expected_class: String) -> int:
	var count := 0
	for event in InputMap.action_get_events(action_name):
		if event.get_class() == expected_class:
			count += 1
	return count


func _has_button(action_name: String, button_index: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton and event.button_index == button_index:
			return true
	return false


func _has_axis(action_name: String, axis: int, axis_value: float) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, axis_value):
			return true
	return false


func _require_equal(actual: Variant, expected: Variant, label: String) -> void:
	_require(actual == expected, "%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print(PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error("I2 runtime input profile failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
