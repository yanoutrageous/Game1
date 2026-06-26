extends Node

const CommandBusScript := preload("res://scripts/core/command/command_bus.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")

const G37_GAME_KERNEL_RUNTIME_DRIVER_ENABLED := false

var current_run_context
var command_bus
var authoritative_runtime: bool = false


func _ready() -> void:
	print_verbose("GameKernel inactive: RunScene owns the authoritative M1 RunContext/CommandBus.")


func reset_run() -> void:
	if not authoritative_runtime or not G37_GAME_KERNEL_RUNTIME_DRIVER_ENABLED:
		return
	current_run_context = RunContextScript.new()


func dispatch_command(command_name: StringName, payload: Dictionary = {}) -> Dictionary:
	if not authoritative_runtime or not G37_GAME_KERNEL_RUNTIME_DRIVER_ENABLED:
		return {
			"ok": false,
			"status": &"inactive_kernel",
			"reason": "run_scene_authoritative",
			"message": "RunScene owns the active RunContext/CommandBus in the current runtime.",
		}
	if command_bus == null:
		command_bus = CommandBusScript.new()

	return command_bus.dispatch(command_name, payload)


func describe_ownership() -> Dictionary:
	return {
		"kernel_authoritative": authoritative_runtime,
		"active_owner": "RunScene" if not authoritative_runtime else "GameKernel",
		"boundary": "G35 keeps GameKernel as an inactive bootstrap placeholder until a later ownership migration.",
	}
