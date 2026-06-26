extends RefCounted
class_name RunRuntimeController

const CommandBusScript := preload("res://scripts/core/command/command_bus.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")
const RunStateMachineScript := preload("res://scripts/core/run/run_state_machine.gd")

var context
var command_bus
var state_machine


func _init() -> void:
	context = RunContextScript.new()
	state_machine = RunStateMachineScript.new()
	command_bus = CommandBusScript.new()
	command_bus.bind_runtime_controller(self)


func describe_ownership() -> Dictionary:
	return {
		"runtime_owner": "RunRuntimeController",
		"context_owner": "RunRuntimeController",
		"command_bus_owner": "RunRuntimeController",
		"scene_owner": "RunScene orchestration only",
		"writable_context_instances": 1,
		"read_only": false,
	}


func start_demo_run(room_resolver: RoomResolver) -> Dictionary:
	var result: Dictionary = state_machine.start_demo_run(context)
	_enter_room_after_start(room_resolver)
	return _with_actor(result)


func start_tutorial_run(room_resolver: RoomResolver) -> Dictionary:
	var result: Dictionary = state_machine.start_tutorial_run(context)
	_enter_room_after_start(room_resolver)
	return _with_actor(result)


func start_standard_run(room_resolver: RoomResolver) -> Dictionary:
	var result: Dictionary = state_machine.start_standard_run(context)
	_enter_room_after_start(room_resolver)
	return _with_actor(result)


func request_extract(room_resolver: RoomResolver, command_id: String, actor_id: StringName) -> Dictionary:
	var result: Dictionary = state_machine.request_extract(context, room_resolver != null and room_resolver.can_extract(context), command_id, actor_id)
	return _with_actor(result)


func confirm_extract(room_resolver: RoomResolver) -> Dictionary:
	var result: Dictionary = state_machine.confirm_extract(context, room_resolver != null and room_resolver.can_extract(context))
	return _with_actor(result)


func cancel_extract() -> Dictionary:
	return _with_actor(state_machine.cancel_extract(context))


func extract(room_resolver: RoomResolver, command_id: String, actor_id: StringName) -> Dictionary:
	var request_result := request_extract(room_resolver, command_id, actor_id)
	if context != null and context.phase == &"confirm_extract":
		return confirm_extract(room_resolver)
	return request_result


func restart_run(room_resolver: RoomResolver) -> Dictionary:
	if context != null and context.mode == &"standard":
		return start_standard_run(room_resolver)
	return start_tutorial_run(room_resolver)


func debug_force_extract() -> Dictionary:
	return _with_actor(state_machine.force_extract(context))


func fail_run(reason: String = "forced_failure") -> Dictionary:
	return _with_actor(state_machine.fail_run(context, reason))


func debug_force_fail(reason: String = "debug_forced_failure") -> Dictionary:
	var result: Dictionary = fail_run(reason)
	if context != null:
		context.last_message = "Debug forced failure through RunStateMachine."
	return result


func _enter_room_after_start(room_resolver: RoomResolver) -> void:
	if room_resolver != null and context != null:
		room_resolver.enter_room(context)


func _with_actor(result: Dictionary) -> Dictionary:
	var output := result.duplicate(true)
	if not output.has("actor_id"):
		output["actor_id"] = &"player"
	output["runtime_authority"] = "RunRuntimeController"
	return output
