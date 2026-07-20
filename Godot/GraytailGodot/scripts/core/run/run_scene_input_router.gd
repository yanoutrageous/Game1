extends RefCounted
class_name RunSceneInputRouter

const ACTION_NONE := &"none"
const ACTION_CANCEL := &"cancel"
const ACTION_INTERACT := &"interact"
const ACTION_FIGHT := &"fight"
const ACTION_FLAG_CURRENT := &"flag_current_cell"
const ACTION_OPEN_MAP := &"open_map"
const ACTION_OPEN_INVENTORY := &"open_inventory"
const ACTION_OPEN_GROUND_LOOT := &"open_ground_loot"
const ACTION_REQUEST_EXTRACT := &"request_extract"
const ACTION_DEBUG_RESTART_RUN := &"debug_restart_run"


static func cancel_action(event: InputEvent) -> StringName:
	if event == null:
		return ACTION_NONE
	if event.is_action_pressed("cancel") or _event_matches_key(event, [KEY_ESCAPE]):
		return ACTION_CANCEL
	return ACTION_NONE


static func run_action(event: InputEvent) -> StringName:
	if event == null:
		return ACTION_NONE
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.echo:
			return ACTION_NONE
	if event.is_action_pressed("interact") or _event_matches_key(event, [KEY_E]):
		return ACTION_INTERACT
	if event.is_action_pressed("attack") or _event_matches_key(event, [KEY_SPACE, KEY_J]):
		return ACTION_FIGHT
	if event.is_action_pressed("flag_cell") or _event_matches_key(event, [KEY_F]):
		return ACTION_FLAG_CURRENT
	if event.is_action_pressed("open_inventory") or _event_matches_key(event, [KEY_Q]):
		return ACTION_OPEN_INVENTORY
	if event.is_action_pressed("open_ground_loot") or _event_matches_key(event, [KEY_G]):
		return ACTION_OPEN_GROUND_LOOT
	if event.is_action_pressed("request_extract") or _event_matches_key(event, [KEY_T]):
		return ACTION_REQUEST_EXTRACT
	if event.is_action_pressed("open_map") or _event_matches_key(event, [KEY_M, KEY_TAB]):
		return ACTION_OPEN_MAP
	if event.is_action_pressed("debug_restart_run"):
		return ACTION_DEBUG_RESTART_RUN
	return ACTION_NONE


static func _event_matches_key(event: InputEvent, keycodes: Array) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	for keycode: int in keycodes:
		if key_event.physical_keycode == keycode or key_event.keycode == keycode:
			return true
	return false
