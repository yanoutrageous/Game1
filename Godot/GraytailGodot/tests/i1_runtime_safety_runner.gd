extends SceneTree

const CommandBusScript := preload("res://scripts/core/command/command_bus.gd")
const DebugGateScript := preload("res://scripts/core/debug/debug_gate.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RunSceneInputRouterScript := preload("res://scripts/core/run/run_scene_input_router.gd")
const RunStateMachineScript := preload("res://scripts/core/run/run_state_machine.gd")

const PASS_MARKER := "I1_RUNTIME_SAFETY=PASS"
const FAIL_MARKER := "I1_RUNTIME_SAFETY=FAIL"

var failures: Array[String] = []


class DisabledDebugCommandBus:
	extends CommandBus

	func _debug_tools_enabled() -> bool:
		return false


class CountingRuntimeController:
	extends RefCounted

	var context: RunContext
	var restart_count: int = 0

	func _init() -> void:
		context = RunContext.new()
		context.start_tutorial_run()

	func restart_run(_room_resolver: RoomResolver) -> Dictionary:
		restart_count += 1
		var result: Dictionary = RunStateMachineScript.new().restart_tutorial_run(context)
		result["actor_id"] = &"player"
		return result


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_router_identity()
	_test_plain_restart_requires_confirmation()
	_test_active_run_start_commands_are_blocked()
	_test_restart_preserves_run_identity()
	await _test_disabled_debug_input_path()
	var enabled_coverage := _test_current_engine_debug_path()
	await _finish(enabled_coverage)


func _test_router_identity() -> void:
	var action := RunSceneInputRouterScript.run_action(_debug_restart_event())
	_require_equal(action, RunSceneInputRouterScript.ACTION_DEBUG_RESTART_RUN, "router debug action")
	_require_equal(action, &"debug_restart_run", "router command identity")
	_require(action != &"restart_run", "router downgraded debug restart to ordinary restart")
	var run_scene_source := FileAccess.get_file_as_string("res://scripts/core/run/run_scene.gd")
	_require(run_scene_source.contains("RunSceneInputRouterScript.ACTION_DEBUG_RESTART_RUN:\n\t\t\t_debug_restart_run_from_ui()"), "RunScene does not route the debug input identity to its debug handler")


func _test_plain_restart_requires_confirmation() -> void:
	var controller := CountingRuntimeController.new()
	var bus := DisabledDebugCommandBus.new()
	bus.bind_runtime_controller(controller)
	var original_run_id: StringName = controller.context.run_id
	var result: Dictionary = bus.dispatch(&"restart_run")
	_require(not bool(result.get("ok", true)), "ordinary restart unexpectedly succeeded")
	_require_equal(String(result.get("reason_code", "")), "restart_confirmation_required", "ordinary restart reason")
	_require_equal(StringName(result.get("status", &"")), &"restart_confirmation_required", "ordinary restart status")
	_require_equal(StringName(result.get("command_name", &"")), &"restart_run", "ordinary restart command identity")
	_require_equal(controller.restart_count, 0, "ordinary restart controller calls")
	_require_equal(controller.context.run_id, original_run_id, "ordinary restart active run")


func _test_active_run_start_commands_are_blocked() -> void:
	var controller = RunRuntimeControllerScript.new()
	var resolver := RoomResolver.new()
	var initial: Dictionary = controller.start_demo_run(resolver)
	_require(bool(initial.get("ok", false)), "active-run bypass setup failed")
	var original_run_id: StringName = controller.context.run_id
	for command_name: StringName in [&"start_demo_run", &"start_tutorial_run", &"start_standard_run"]:
		var result: Dictionary = controller.command_bus.dispatch(command_name)
		_require(not bool(result.get("ok", true)), "%s replaced an active run" % command_name)
		_require_equal(StringName(result.get("status", &"")), &"active_run_exists", "%s active-run status" % command_name)
		_require_equal(controller.context.run_id, original_run_id, "%s active-run identity" % command_name)
		_require_equal(controller.context.mode, &"demo", "%s active-run mode" % command_name)


func _test_restart_preserves_run_identity() -> void:
	var controller = RunRuntimeControllerScript.new()
	var resolver := RoomResolver.new()
	var standard_config := {
		"map_profile_id": &"map_13x13_hard",
		"difficulty_id": &"hard",
		"selected_objective_ids": [&"commission_route_survey"],
		"selected_equipment_items": [],
		"selected_consumable_items": [],
		"backpack_capacity": 12,
		"failure_salvage_capacity": 5,
	}
	var start_result: Dictionary = controller.start_standard_run(resolver, standard_config)
	_require(bool(start_result.get("ok", false)), "standard run setup failed")
	var original_run_id: StringName = controller.context.run_id
	var expected_config: Dictionary = controller.context.run_start_config.duplicate(true)
	var restart_result: Dictionary = controller.restart_run(resolver)
	_require(bool(restart_result.get("ok", false)), "standard restart failed")
	_require_equal(StringName(restart_result.get("transition", &"")), &"restart", "standard restart transition")
	_require_equal(controller.context.mode, &"standard", "standard restart mode")
	_require(controller.context.run_id != original_run_id, "standard restart kept run id")
	_require_equal(controller.context.run_start_config, expected_config, "standard restart config")

	var demo_controller = RunRuntimeControllerScript.new()
	var demo_start: Dictionary = demo_controller.start_demo_run(resolver)
	_require(bool(demo_start.get("ok", false)), "demo run setup failed")
	var demo_restart: Dictionary = demo_controller.restart_run(resolver)
	_require(bool(demo_restart.get("ok", false)), "demo restart failed")
	_require_equal(StringName(demo_restart.get("transition", &"")), &"restart", "demo restart transition")
	_require_equal(demo_controller.context.mode, &"demo", "demo restart mode")

	demo_controller.context.mode = &"unsupported_i1_mode"
	var blocked: Dictionary = demo_controller.restart_run(resolver)
	_require(not bool(blocked.get("ok", true)), "unknown restart mode unexpectedly succeeded")
	_require_equal(StringName(blocked.get("status", &"")), &"restart_mode_unsupported", "unknown restart status")


func _test_disabled_debug_input_path() -> void:
	var controller := CountingRuntimeController.new()
	var bus := DisabledDebugCommandBus.new()
	bus.bind_runtime_controller(controller)
	var original_run_id: StringName = controller.context.run_id

	var run_scene_script := load("res://scripts/core/run/run_scene.gd") as Script
	_require(run_scene_script != null and run_scene_script.can_instantiate(), "RunScene script could not be instantiated")
	if run_scene_script == null or not run_scene_script.can_instantiate():
		return
	var run_scene_node := Node2D.new()
	root.add_child(run_scene_node)
	run_scene_node.set_script(run_scene_script)
	_require(run_scene_node.has_method("_debug_restart_run_from_ui"), "RunScene debug restart handler is unavailable")
	if not run_scene_node.has_method("_debug_restart_run_from_ui"):
		run_scene_node.queue_free()
		await process_frame
		return
	run_scene_node.set("run_context", controller.context)
	run_scene_node.set("command_bus", bus)

	run_scene_node.call("_debug_restart_run_from_ui")
	var result: Dictionary = run_scene_node.get("last_command_result")
	_require_equal(StringName(result.get("command_name", &"")), &"debug_restart_run", "RunScene command identity")
	_require_equal(String(result.get("reason_code", "")), DebugGateScript.DEBUG_DISABLED_REASON, "disabled debug reason")
	_require(not bool(result.get("ok", true)), "disabled debug restart unexpectedly succeeded")
	_require_equal(controller.restart_count, 0, "disabled debug restart controller calls")
	_require_equal(controller.context.run_id, original_run_id, "disabled debug active run")

	run_scene_node.queue_free()
	await process_frame


func _test_current_engine_debug_path() -> String:
	var controller := CountingRuntimeController.new()
	var bus := CommandBusScript.new()
	bus.bind_runtime_controller(controller)
	var original_run_id: StringName = controller.context.run_id
	var result: Dictionary = bus.dispatch(&"debug_restart_run")
	if DebugGateScript.is_debug_tools_enabled():
		_require(bool(result.get("ok", false)), "enabled debug restart was rejected")
		_require_equal(StringName(result.get("command_name", &"")), &"debug_restart_run", "enabled debug command identity")
		_require_equal(controller.restart_count, 1, "enabled debug restart controller calls")
		_require(controller.context.run_id != original_run_id, "enabled debug restart kept the original active run")
		return "executed"
	_require(not bool(result.get("ok", true)), "current disabled engine accepted debug restart")
	_require_equal(String(result.get("reason_code", "")), DebugGateScript.DEBUG_DISABLED_REASON, "current disabled engine reason")
	_require_equal(controller.restart_count, 0, "current disabled engine restart calls")
	_require_equal(controller.context.run_id, original_run_id, "current disabled engine active run")
	return "unavailable"


func _debug_restart_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"debug_restart_run"
	event.pressed = true
	return event


func _require_equal(actual: Variant, expected: Variant, label: String) -> void:
	_require(actual == expected, "%s expected=%s actual=%s" % [label, str(expected), str(actual)])


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(enabled_coverage: String) -> void:
	if failures.is_empty():
		print(PASS_MARKER)
		print("I1_RUNTIME_SAFETY_DETAILS router=debug_restart_run ordinary=restart_confirmation_required restart_identity=preserved debug_disabled=blocked debug_enabled=%s" % enabled_coverage)
		quit(0)
		return
	for failure in failures:
		print("I1_RUNTIME_SAFETY_FAILURE %s" % failure)
	print(FAIL_MARKER)
	quit(1)
