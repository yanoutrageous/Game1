extends RefCounted

const GAMEPAD_DEVICE := -1

const BUTTON_BINDINGS := {
	"interact": JOY_BUTTON_A,
	"ui_accept": JOY_BUTTON_A,
	"cancel": JOY_BUTTON_B,
	"ui_cancel": JOY_BUTTON_B,
	"attack": JOY_BUTTON_X,
	"open_map": JOY_BUTTON_Y,
	"open_inventory": JOY_BUTTON_LEFT_SHOULDER,
	"flag_cell": JOY_BUTTON_RIGHT_SHOULDER,
	"pause": JOY_BUTTON_START,
}

const DIRECTION_BINDINGS := {
	"move_up": {"axis": JOY_AXIS_LEFT_Y, "value": -1.0, "button": JOY_BUTTON_DPAD_UP},
	"move_down": {"axis": JOY_AXIS_LEFT_Y, "value": 1.0, "button": JOY_BUTTON_DPAD_DOWN},
	"move_left": {"axis": JOY_AXIS_LEFT_X, "value": -1.0, "button": JOY_BUTTON_DPAD_LEFT},
	"move_right": {"axis": JOY_AXIS_LEFT_X, "value": 1.0, "button": JOY_BUTTON_DPAD_RIGHT},
	"ui_up": {"axis": JOY_AXIS_LEFT_Y, "value": -1.0, "button": JOY_BUTTON_DPAD_UP},
	"ui_down": {"axis": JOY_AXIS_LEFT_Y, "value": 1.0, "button": JOY_BUTTON_DPAD_DOWN},
	"ui_left": {"axis": JOY_AXIS_LEFT_X, "value": -1.0, "button": JOY_BUTTON_DPAD_LEFT},
	"ui_right": {"axis": JOY_AXIS_LEFT_X, "value": 1.0, "button": JOY_BUTTON_DPAD_RIGHT},
}


static func install() -> Dictionary:
	var actions_added := 0
	var events_added := 0
	for action_name in BUTTON_BINDINGS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.5)
			actions_added += 1
		var button_event := _button_event(int(BUTTON_BINDINGS[action_name]))
		if _add_event_if_missing(action_name, button_event):
			events_added += 1
	for action_name in DIRECTION_BINDINGS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.5)
			actions_added += 1
		var binding: Dictionary = DIRECTION_BINDINGS[action_name]
		var axis_event := _axis_event(int(binding["axis"]), float(binding["value"]))
		var dpad_event := _button_event(int(binding["button"]))
		if _add_event_if_missing(action_name, axis_event):
			events_added += 1
		if _add_event_if_missing(action_name, dpad_event):
			events_added += 1
	return {
		"actions_added": actions_added,
		"events_added": events_added,
		"semantic_actions": BUTTON_BINDINGS.size() + DIRECTION_BINDINGS.size(),
	}


static func semantic_profile() -> Dictionary:
	return {
		"a": PackedStringArray(["interact", "ui_accept"]),
		"b": PackedStringArray(["cancel", "ui_cancel"]),
		"x": PackedStringArray(["attack"]),
		"y": PackedStringArray(["open_map"]),
		"lb": PackedStringArray(["open_inventory"]),
		"rb": PackedStringArray(["flag_cell"]),
		"start": PackedStringArray(["pause"]),
		"left_stick_and_dpad": PackedStringArray(["move_up", "move_down", "move_left", "move_right"]),
	}


static func _button_event(button_index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = GAMEPAD_DEVICE
	event.button_index = button_index
	return event


static func _axis_event(axis: int, axis_value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = GAMEPAD_DEVICE
	event.axis = axis
	event.axis_value = axis_value
	return event


static func _add_event_if_missing(action_name: String, candidate: InputEvent) -> bool:
	for existing_event in InputMap.action_get_events(action_name):
		if _events_match(existing_event, candidate):
			return false
	InputMap.action_add_event(action_name, candidate)
	return true


static func _events_match(first: InputEvent, second: InputEvent) -> bool:
	if first is InputEventJoypadButton and second is InputEventJoypadButton:
		return first.device == second.device and first.button_index == second.button_index
	if first is InputEventJoypadMotion and second is InputEventJoypadMotion:
		return (
			first.device == second.device
			and first.axis == second.axis
			and is_equal_approx(first.axis_value, second.axis_value)
		)
	return false
