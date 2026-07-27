extends RefCounted
class_name RunSceneInputRouter

const RuntimeInputProfileScript := preload("res://scripts/core/input/runtime_input_profile.gd")

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

const RUN_ACTION_BINDINGS := [
	{"input_action": &"interact", "route_action": ACTION_INTERACT},
	{"input_action": &"attack", "route_action": ACTION_FIGHT},
	{"input_action": &"flag_cell", "route_action": ACTION_FLAG_CURRENT},
	{"input_action": &"open_inventory", "route_action": ACTION_OPEN_INVENTORY},
	{"input_action": &"open_ground_loot", "route_action": ACTION_OPEN_GROUND_LOOT},
	{"input_action": &"request_extract", "route_action": ACTION_REQUEST_EXTRACT},
	{"input_action": &"open_map", "route_action": ACTION_OPEN_MAP},
	{"input_action": &"debug_restart_run", "route_action": ACTION_DEBUG_RESTART_RUN},
]


static func cancel_action(event: InputEvent) -> StringName:
	if (
		RuntimeInputProfileScript.event_pressed(event, RuntimeInputProfileScript.ACTION_CANCEL)
		or RuntimeInputProfileScript.event_pressed(event, RuntimeInputProfileScript.ACTION_PAUSE)
	):
		return ACTION_CANCEL
	return ACTION_NONE


static func run_action(event: InputEvent) -> StringName:
	if event == null:
		return ACTION_NONE
	for binding: Dictionary in RUN_ACTION_BINDINGS:
		if RuntimeInputProfileScript.event_pressed(event, StringName(binding["input_action"])):
			return StringName(binding["route_action"])
	return ACTION_NONE


static func movement_direction(event: InputEvent) -> Vector2:
	return RuntimeInputProfileScript.movement_direction(event)
