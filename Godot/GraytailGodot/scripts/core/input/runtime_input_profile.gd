extends RefCounted

const GAMEPAD_DEVICE := -1
const DEVICE_KEYBOARD_MOUSE := &"keyboard_mouse"
const DEVICE_GAMEPAD := &"gamepad"
const HINT_CONSUMER_GROUP := &"runtime_input_hint_consumers"
const JOYPAD_MOTION_DEVICE_THRESHOLD := 0.5

const ACTION_MOVE_UP := &"move_up"
const ACTION_MOVE_DOWN := &"move_down"
const ACTION_MOVE_LEFT := &"move_left"
const ACTION_MOVE_RIGHT := &"move_right"
const ACTION_INTERACT := &"interact"
const ACTION_ATTACK := &"attack"
const ACTION_OPEN_MAP := &"open_map"
const ACTION_OPEN_INVENTORY := &"open_inventory"
const ACTION_OPEN_GROUND_LOOT := &"open_ground_loot"
const ACTION_REQUEST_EXTRACT := &"request_extract"
const ACTION_FLAG_CELL := &"flag_cell"
const ACTION_CANCEL := &"cancel"
const ACTION_PAUSE := &"pause"
const ACTION_DEBUG_RESTART_RUN := &"debug_restart_run"
const ACTION_MENU_PRIMARY := &"menu_shortcut_primary"
const ACTION_MENU_SECONDARY := &"menu_shortcut_secondary"

const KEY_BINDINGS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"interact": [KEY_E],
	"attack": [KEY_SPACE, KEY_J],
	"open_map": [KEY_M, KEY_TAB],
	"open_inventory": [KEY_Q],
	"open_ground_loot": [KEY_G],
	"request_extract": [KEY_T],
	"flag_cell": [KEY_F],
	"cancel": [KEY_ESCAPE],
	"pause": [KEY_ESCAPE],
	"debug_restart_run": [KEY_R],
	"menu_shortcut_primary": [KEY_F1],
	"menu_shortcut_secondary": [KEY_F2],
}

const MOUSE_BUTTON_BINDINGS := {
	"attack": MOUSE_BUTTON_LEFT,
}

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

static var _current_input_device: StringName = DEVICE_KEYBOARD_MOUSE
static var _current_joypad_device: int = -1


static func install() -> Dictionary:
	var actions_added := 0
	var events_added := 0
	for action_name in KEY_BINDINGS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.5)
			actions_added += 1
		for keycode: Key in KEY_BINDINGS[action_name]:
			if _add_event_if_missing(action_name, _key_event(keycode)):
				events_added += 1
	for action_name in MOUSE_BUTTON_BINDINGS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.5)
			actions_added += 1
		if _add_event_if_missing(action_name, _mouse_button_event(int(MOUSE_BUTTON_BINDINGS[action_name]))):
			events_added += 1
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
		"semantic_actions": semantic_action_names().size(),
	}


static func semantic_action_names() -> PackedStringArray:
	var result := PackedStringArray()
	for action_name in KEY_BINDINGS:
		if not result.has(action_name):
			result.append(action_name)
	for action_name in MOUSE_BUTTON_BINDINGS:
		if not result.has(action_name):
			result.append(action_name)
	for action_name in BUTTON_BINDINGS:
		if not result.has(action_name):
			result.append(action_name)
	for action_name in DIRECTION_BINDINGS:
		if not result.has(action_name):
			result.append(action_name)
	return result


static func semantic_profile() -> Dictionary:
	return {
		"a": PackedStringArray(["interact", "ui_accept"]),
		"b": PackedStringArray(["cancel", "ui_cancel"]),
		"x": PackedStringArray(["attack"]),
		"mouse_primary": PackedStringArray(["attack"]),
		"y": PackedStringArray(["open_map"]),
		"lb": PackedStringArray(["open_inventory"]),
		"rb": PackedStringArray(["flag_cell"]),
		"start": PackedStringArray(["pause"]),
		"left_stick_and_dpad": PackedStringArray(["move_up", "move_down", "move_left", "move_right"]),
	}


static func observe_input_event(event: InputEvent) -> bool:
	var next_device := _device_for_event(event)
	if next_device == &"":
		return false
	if next_device == DEVICE_GAMEPAD and event != null:
		_current_joypad_device = event.device
	var changed := next_device != _current_input_device
	_current_input_device = next_device
	return changed


static func current_input_device() -> StringName:
	return _current_input_device


static func current_joypad_device() -> int:
	return _current_joypad_device


static func event_pressed(event: InputEvent, action_name: StringName) -> bool:
	if event == null or event.is_echo() or not InputMap.has_action(String(action_name)):
		return false
	return event.is_action_pressed(String(action_name), false, true)


static func movement_direction(event: InputEvent) -> Vector2:
	if event_pressed(event, ACTION_MOVE_LEFT):
		return Vector2.LEFT
	if event_pressed(event, ACTION_MOVE_RIGHT):
		return Vector2.RIGHT
	if event_pressed(event, ACTION_MOVE_UP):
		return Vector2.UP
	if event_pressed(event, ACTION_MOVE_DOWN):
		return Vector2.DOWN
	return Vector2.ZERO


static func _device_for_event(event: InputEvent) -> StringName:
	if event == null:
		return &""
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return DEVICE_KEYBOARD_MOUSE if key_event.pressed and not key_event.echo else &""
	if event is InputEventMouseButton:
		return DEVICE_KEYBOARD_MOUSE if (event as InputEventMouseButton).pressed else &""
	if event is InputEventMouseMotion:
		return DEVICE_KEYBOARD_MOUSE if not (event as InputEventMouseMotion).relative.is_zero_approx() else &""
	if event is InputEventJoypadButton:
		return DEVICE_GAMEPAD if (event as InputEventJoypadButton).pressed else &""
	if event is InputEventJoypadMotion:
		return DEVICE_GAMEPAD if absf((event as InputEventJoypadMotion).axis_value) >= JOYPAD_MOTION_DEVICE_THRESHOLD else &""
	return &""


static func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.device = -1
	event.physical_keycode = keycode
	return event


static func _button_event(button_index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = GAMEPAD_DEVICE
	event.button_index = button_index
	return event


static func _mouse_button_event(button_index: int) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.device = -1
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
	if first is InputEventKey and second is InputEventKey:
		var first_key := first as InputEventKey
		var second_key := second as InputEventKey
		var first_code := first_key.physical_keycode if first_key.physical_keycode != KEY_NONE else first_key.keycode
		var second_code := second_key.physical_keycode if second_key.physical_keycode != KEY_NONE else second_key.keycode
		return first_code == second_code
	if first is InputEventJoypadButton and second is InputEventJoypadButton:
		return first.button_index == second.button_index
	if first is InputEventMouseButton and second is InputEventMouseButton:
		return first.button_index == second.button_index
	if first is InputEventJoypadMotion and second is InputEventJoypadMotion:
		return (
			first.axis == second.axis
			and is_equal_approx(first.axis_value, second.axis_value)
		)
	return false
