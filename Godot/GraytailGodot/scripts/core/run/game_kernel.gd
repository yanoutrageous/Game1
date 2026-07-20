extends Node

const CommandBusScript := preload("res://scripts/core/command/command_bus.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")

const G37_GAME_KERNEL_RUNTIME_DRIVER_ENABLED := false
const G38_GAME_KERNEL_COMPATIBILITY_FACADE := true
const G38_GAME_KERNEL_REMOVAL_CONDITION := "remove_autoload_in_project_metadata_only_in_a_future_project_godot_gate"
const I1_GAME_KERNEL_AUTOLOAD_STATUS := "removed_from_project_autoload_by_i1_metadata_gate"

var current_run_context
var command_bus
var authoritative_runtime: bool = false


func _ready() -> void:
	print_verbose("GameKernel compatibility facade inactive: RunRuntimeController owns the active runtime.")


func reset_run() -> void:
	if not authoritative_runtime or not G37_GAME_KERNEL_RUNTIME_DRIVER_ENABLED:
		return
	current_run_context = RunContextScript.new()


func dispatch_command(command_name: StringName, payload: Dictionary = {}) -> Dictionary:
	if not authoritative_runtime or not G37_GAME_KERNEL_RUNTIME_DRIVER_ENABLED:
		return {
			"ok": false,
			"status": &"inactive_kernel",
			"reason": "runtime_controller_authoritative",
			"message": "GameKernel is a compatibility facade; RunRuntimeController and RunStateMachine own active runtime lifecycle.",
			"autoload_status": I1_GAME_KERNEL_AUTOLOAD_STATUS,
			"historical_g38_removal_condition": G38_GAME_KERNEL_REMOVAL_CONDITION,
		}
	if command_bus == null:
		command_bus = CommandBusScript.new()

	return command_bus.dispatch(command_name, payload)


func describe_ownership() -> Dictionary:
	return {
		"kernel_authoritative": authoritative_runtime,
		"compatibility_facade": G38_GAME_KERNEL_COMPATIBILITY_FACADE,
		"active_owner": "RunRuntimeController" if not authoritative_runtime else "GameKernel",
		"lifecycle_owner": "RunStateMachine" if not authoritative_runtime else "GameKernel",
		"boundary": "I1 removed the inactive GameKernel autoload; this script remains only as a non-authoritative historical compatibility facade.",
		"legacy_marker": "RunScene owns the authoritative scene orchestration marker; active runtime ownership is RunRuntimeController.",
		"autoload_status": I1_GAME_KERNEL_AUTOLOAD_STATUS,
		"historical_g38_removal_condition": G38_GAME_KERNEL_REMOVAL_CONDITION,
	}
