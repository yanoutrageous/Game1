extends RefCounted
class_name SemanticActionHint

const RuntimeInputProfileScript := preload("res://scripts/core/input/runtime_input_profile.gd")

const DESCRIPTOR_TYPE := &"action_hint"
const SCHEMA_VERSION := 1
const DEVICE_ALL := &"all"
const DEVICE_KEYBOARD_MOUSE := &"keyboard_mouse"
const DEVICE_GAMEPAD := &"gamepad"

const FALLBACK_LABELS := {
	&"move_up": "向上移动",
	&"move_down": "向下移动",
	&"move_left": "向左移动",
	&"move_right": "向右移动",
	&"interact": "交互",
	&"attack": "攻击",
	&"open_map": "地图",
	&"open_inventory": "背包",
	&"open_ground_loot": "拾取",
	&"request_extract": "撤离",
	&"flag_cell": "标记",
	&"ui_accept": "确认",
	&"ui_cancel": "返回",
	&"cancel": "返回",
	&"pause": "暂停",
	&"menu_shortcut_primary": "主入口快捷键",
	&"menu_shortcut_secondary": "次入口快捷键",
}

const JOYPAD_BUTTON_LABELS := {
	JOY_BUTTON_A: "手柄 A",
	JOY_BUTTON_B: "手柄 B",
	JOY_BUTTON_X: "手柄 X",
	JOY_BUTTON_Y: "手柄 Y",
	JOY_BUTTON_LEFT_SHOULDER: "手柄 LB",
	JOY_BUTTON_RIGHT_SHOULDER: "手柄 RB",
	JOY_BUTTON_START: "手柄菜单键",
	JOY_BUTTON_DPAD_UP: "十字键上",
	JOY_BUTTON_DPAD_DOWN: "十字键下",
	JOY_BUTTON_DPAD_LEFT: "十字键左",
	JOY_BUTTON_DPAD_RIGHT: "十字键右",
}

const JOYPAD_AXIS_LABELS := {
	Vector2i(JOY_AXIS_LEFT_X, -1): "左摇杆左",
	Vector2i(JOY_AXIS_LEFT_X, 1): "左摇杆右",
	Vector2i(JOY_AXIS_LEFT_Y, -1): "左摇杆上",
	Vector2i(JOY_AXIS_LEFT_Y, 1): "左摇杆下",
}

const KEY_LABELS := {
	KEY_ESCAPE: "Esc",
	KEY_SPACE: "空格",
	KEY_TAB: "Tab",
	KEY_ENTER: "Enter",
	KEY_KP_ENTER: "小键盘 Enter",
}


static func display_label(action_id: StringName, preferred_device: StringName = DEVICE_ALL) -> String:
	var descriptor_data := descriptor(action_id, preferred_device)
	return str(descriptor_data.get("display_label", FALLBACK_LABELS.get(action_id, String(action_id))))


static func compact_display_label(action_id: StringName, preferred_device: StringName = DEVICE_ALL) -> String:
	return compact_label_from_descriptor(descriptor(action_id, preferred_device), preferred_device)


static func current_device() -> StringName:
	return RuntimeInputProfileScript.current_input_device()


static func current_display_label(action_id: StringName) -> String:
	return display_label(action_id, current_device())


static func current_compact_display_label(action_id: StringName) -> String:
	return compact_display_label(action_id, current_device())


static func current_binding_label(action_id: StringName) -> String:
	var descriptor_data := descriptor(action_id, current_device())
	var joined_labels := str(
		descriptor_data.get(
			"gamepad_label" if current_device() == DEVICE_GAMEPAD else "keyboard_mouse_label",
			""
		)
	)
	return _first_binding_label(joined_labels)


static func compact_label_from_descriptor(
	descriptor_data: Dictionary,
	preferred_device: StringName = DEVICE_ALL
) -> String:
	var labels: Array[String] = []
	var keyboard_label := _first_binding_label(str(descriptor_data.get("keyboard_mouse_label", "")))
	var gamepad_label := _first_binding_label(str(descriptor_data.get("gamepad_label", "")))
	match preferred_device:
		DEVICE_KEYBOARD_MOUSE:
			if not keyboard_label.is_empty():
				labels.append(keyboard_label)
		DEVICE_GAMEPAD:
			if not gamepad_label.is_empty():
				labels.append(gamepad_label)
		_:
			if not keyboard_label.is_empty():
				labels.append(keyboard_label)
			if not gamepad_label.is_empty():
				labels.append(gamepad_label)
	if labels.is_empty():
		return str(descriptor_data.get("semantic_label", descriptor_data.get("display_label", "")))
	return " · ".join(labels)


static func replace_tokens(
	template: String,
	action_ids: Array[StringName],
	preferred_device: StringName = DEVICE_ALL
) -> String:
	var result := template
	for action_id in action_ids:
		result = result.replace("{%s}" % String(action_id), display_label(action_id, preferred_device))
	return result


static func replace_tokens_compact(
	template: String,
	action_ids: Array[StringName],
	preferred_device: StringName = DEVICE_ALL
) -> String:
	var result := template
	for action_id in action_ids:
		result = result.replace("{%s}" % String(action_id), compact_display_label(action_id, preferred_device))
	return result


static func descriptor(action_id: StringName, preferred_device: StringName = DEVICE_ALL) -> Dictionary:
	var keyboard_labels: Array[String] = []
	var gamepad_labels: Array[String] = []
	if InputMap.has_action(String(action_id)):
		for event in InputMap.action_get_events(String(action_id)):
			var label := _event_label(event)
			if label.is_empty():
				continue
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				if not gamepad_labels.has(label):
					gamepad_labels.append(label)
			elif not keyboard_labels.has(label):
				keyboard_labels.append(label)
	if action_id == RuntimeInputProfileScript.ACTION_ATTACK and keyboard_labels.has("鼠标左键"):
		# The production combat path treats pointer attack as the primary PC
		# gesture while Space/J remain accessibility alternatives.
		keyboard_labels.erase("鼠标左键")
		keyboard_labels.push_front("鼠标左键")
	var keyboard_label := " / ".join(keyboard_labels)
	var gamepad_label := " / ".join(gamepad_labels)
	var combined_labels: Array[String] = []
	match preferred_device:
		DEVICE_KEYBOARD_MOUSE:
			if not keyboard_label.is_empty():
				combined_labels.append(keyboard_label)
		DEVICE_GAMEPAD:
			if not gamepad_label.is_empty():
				combined_labels.append(gamepad_label)
		_:
			if not keyboard_label.is_empty():
				combined_labels.append(keyboard_label)
			if not gamepad_label.is_empty():
				combined_labels.append(gamepad_label)
	if combined_labels.is_empty():
		if not keyboard_label.is_empty():
			combined_labels.append(keyboard_label)
		elif not gamepad_label.is_empty():
			combined_labels.append(gamepad_label)
	var fallback := str(FALLBACK_LABELS.get(action_id, String(action_id)))
	return {
		"descriptor_type": DESCRIPTOR_TYPE,
		"schema_version": SCHEMA_VERSION,
		"action_id": action_id,
		"semantic_label": fallback,
		"display_label": " · ".join(combined_labels) if not combined_labels.is_empty() else fallback,
		"keyboard_mouse_label": keyboard_label,
		"gamepad_label": gamepad_label,
		"available_devices": PackedStringArray(
			([] if keyboard_label.is_empty() else [String(DEVICE_KEYBOARD_MOUSE)])
			+ ([] if gamepad_label.is_empty() else [String(DEVICE_GAMEPAD)])
		),
		"preferred_device": preferred_device,
		"source": &"input_map",
	}


static func _first_binding_label(joined_labels: String) -> String:
	var parts := joined_labels.split(" / ", false, 1)
	return str(parts[0]).strip_edges() if not parts.is_empty() else ""


static func _event_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var keycode := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
		return str(KEY_LABELS.get(keycode, OS.get_keycode_string(keycode)))
	if event is InputEventJoypadButton:
		var joy_event := event as InputEventJoypadButton
		return str(JOYPAD_BUTTON_LABELS.get(joy_event.button_index, "手柄按钮 %d" % joy_event.button_index))
	if event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		var direction := -1 if motion_event.axis_value < 0.0 else 1
		return str(JOYPAD_AXIS_LABELS.get(Vector2i(motion_event.axis, direction), "手柄轴 %d" % motion_event.axis))
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return "鼠标左键" if mouse_event.button_index == MOUSE_BUTTON_LEFT else "鼠标键 %d" % mouse_event.button_index
	return ""
