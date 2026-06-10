extends Node

const CommandBusScript := preload("res://scripts/core/command/command_bus.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")

var current_run_context
var command_bus


func _ready() -> void:
	current_run_context = RunContextScript.new()
	command_bus = CommandBusScript.new()
	print_verbose("GameKernel ready")


func reset_run() -> void:
	current_run_context = RunContextScript.new()


func dispatch_command(command_name: StringName, payload: Dictionary = {}) -> Dictionary:
	if command_bus == null:
		command_bus = CommandBusScript.new()

	return command_bus.dispatch(command_name, payload)
