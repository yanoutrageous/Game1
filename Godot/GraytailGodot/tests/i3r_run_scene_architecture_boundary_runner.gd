extends SceneTree

const RunSceneResponsibilityBudgetScript := preload("res://scripts/core/run/run_scene_responsibility_budget.gd")
const RunSceneModalControllerScript := preload("res://scripts/core/run/run_scene_modal_controller.gd")

const PASS_MARKER := "I3R_RUN_SCENE_ARCHITECTURE_BOUNDARY=PASS"
const FAIL_MARKER := "I3R_RUN_SCENE_ARCHITECTURE_BOUNDARY=FAIL"
const RUN_SCENE_PATH := "res://scripts/core/run/run_scene.gd"
const RUNTIME_CONTROLLER_PATH := "res://scripts/core/run/run_runtime_controller.gd"
const STATE_MACHINE_PATH := "res://scripts/core/run/run_state_machine.gd"
const RESULT_CONTROLLER_PATH := "res://scripts/core/run/run_scene_result_controller.gd"
const MODAL_CONTROLLER_PATH := "res://scripts/core/run/run_scene_modal_controller.gd"
const DEBUG_PANEL_CONTROLLER_PATH := "res://scripts/core/run/run_scene_debug_panel_controller.gd"
const FROZEN_I3R_SOURCE_LINE_BASELINE := 2959
const FROZEN_I3R_MAX_SOURCE_LINES := 2980
const FROZEN_I3R_MAX_FUNCTIONS := 176

var failures: Array[String] = []


class RunSurfaceSpy:
	extends RefCounted

	var top_modal_id := &"unset"

	func apply_modal_visibility_policy(modal_id: StringName) -> void:
		top_modal_id = modal_id


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var run_scene_source := _read_source(RUN_SCENE_PATH)
	var runtime_controller_source := _read_source(RUNTIME_CONTROLLER_PATH)
	var state_machine_source := _read_source(STATE_MACHINE_PATH)
	var result_controller_source := _read_source(RESULT_CONTROLLER_PATH)
	var modal_controller_source := _read_source(MODAL_CONTROLLER_PATH)
	var debug_panel_controller_source := _read_source(DEBUG_PANEL_CONTROLLER_PATH)
	_test_quantitative_budget(run_scene_source)
	_test_authority_boundary(
		run_scene_source,
		runtime_controller_source,
		state_machine_source,
		result_controller_source
	)
	_test_modal_extraction(run_scene_source, modal_controller_source)
	_test_debug_panel_extraction(run_scene_source, debug_panel_controller_source)
	await _test_modal_controller_runtime()
	await _test_production_wiring()
	_finish(run_scene_source)


func _test_quantitative_budget(run_scene_source: String) -> void:
	var budget: Dictionary = RunSceneResponsibilityBudgetScript.describe()
	var source_lines := _physical_line_count(run_scene_source)
	var function_count := _top_level_function_count(run_scene_source)
	_require(
		source_lines <= int(budget.get("max_source_lines", 0)),
		"RunScene source-line budget exceeded: %d > %d" % [
			source_lines,
			int(budget.get("max_source_lines", 0)),
		]
	)
	_require(
		function_count <= int(budget.get("max_function_count", 0)),
		"RunScene function budget exceeded: %d > %d" % [
			function_count,
			int(budget.get("max_function_count", 0)),
		]
	)
	_require(
		int(budget.get("source_line_baseline", 0)) == FROZEN_I3R_SOURCE_LINE_BASELINE
		and int(budget.get("max_source_lines", 0)) == FROZEN_I3R_MAX_SOURCE_LINES
		and int(budget.get("max_function_count", 0)) == FROZEN_I3R_MAX_FUNCTIONS,
		"RunScene budget constants changed without revising the frozen I3R architecture contract"
	)
	_require(StringName(budget.get("runtime_owner", &"")) == &"RunRuntimeController", "runtime owner budget drifted")
	_require(StringName(budget.get("lifecycle_owner", &"")) == &"RunStateMachine", "lifecycle owner budget drifted")
	_require(
		StringName(budget.get("modal_coordination_owner", &"")) == &"RunSceneModalController",
		"modal coordination owner budget drifted"
	)
	_require(bool(budget.get("no_persistence", false)), "RunScene persistence prohibition is missing")


func _test_authority_boundary(
	run_scene_source: String,
	runtime_controller_source: String,
	state_machine_source: String,
	result_controller_source: String
) -> void:
	var forbidden_patterns: Array[Dictionary] = [
		{
			"label": "construct RunContext",
			"pattern": r"RunContextScript\s*\.\s*new\s*\(",
		},
		{
			"label": "construct CommandBus",
			"pattern": r"CommandBusScript\s*\.\s*new\s*\(",
		},
		{
			"label": "write run lifecycle phase",
			"pattern": r"(?m)(?:run_)?context\s*\.\s*phase\s*=(?!=)",
		},
		{
			"label": "invoke lifecycle failure primitive",
			"pattern": r"(?m)(?:run_)?context\s*\.\s*(?:fail_run|_apply_failure)\s*\(",
		},
		{
			"label": "invoke state machine directly",
			"pattern": r"(?:RunStateMachineScript|state_machine\s*\.)",
		},
		{
			"label": "invoke rule service directly",
			"pattern": r"(?:RunRuleServiceScript|run_rule_service\s*\.|RoomRuleServiceScript)",
		},
		{
			"label": "write result snapshot",
			"pattern": r"(?m)(?:run_)?context\s*\.\s*result_snapshot\s*(?:=|\[|\.clear\s*\()",
		},
		{
			"label": "commit settlement directly",
			"pattern": r"(?:apply_settlement|RunSceneMetaCommitterScript\s*\.\s*commit_result)",
		},
		{
			"label": "write persistence directly",
			"pattern": r"(?m)(?:meta_progress_adapter|save_manager)\s*\.\s*(?:save|write|commit|purchase_item|sell_collectible|claim_goal_reward|unlock_talent|complete_research)\s*\(",
		},
		{
			"label": "access filesystem directly",
			"pattern": r"(?:FileAccess|user://)",
		},
	]
	for contract: Dictionary in forbidden_patterns:
		_require(
			not _regex_matches(run_scene_source, String(contract.get("pattern", ""))),
			"RunScene may not %s" % String(contract.get("label", "perform forbidden authority work"))
		)
	_require(
		run_scene_source.contains("RunRuntimeControllerScript.new()"),
		"RunScene does not obtain runtime authority through RunRuntimeController"
	)
	_require(
		run_scene_source.contains("RunSceneResultControllerScript.build_result_display_snapshot"),
		"RunScene bypasses the result presentation controller"
	)
	_require(
		runtime_controller_source.contains("context = RunContextScript.new()")
		and runtime_controller_source.contains("command_bus = CommandBusScript.new()")
		and runtime_controller_source.contains("meta_progress_adapter.apply_settlement"),
		"RunRuntimeController no longer owns context, command bus, and terminal settlement commit"
	)
	_require(
		state_machine_source.contains("context._apply_failure(reason)"),
		"RunStateMachine no longer owns the failure transition primitive"
	)
	_require(
		result_controller_source.contains("commit_authority")
		and result_controller_source.contains("\"RunRuntimeController\""),
		"result presentation no longer declares RunRuntimeController commit authority"
	)


func _test_modal_extraction(run_scene_source: String, modal_controller_source: String) -> void:
	for required_fragment: String in [
		"RunSceneModalControllerScript",
		"modal_controller = RunSceneModalControllerScript.new()",
		"modal_controller.bind_views(",
		"modal_controller.preferred_focus(modal_root)",
	]:
		_require(run_scene_source.contains(required_fragment), "RunScene modal delegation missing: %s" % required_fragment)
	for forbidden_fragment: String in [
		"func _on_runtime_modal_stack_changed",
		"func _runtime_modal_root",
		"func _first_focusable_descendant",
		"var modal_focus_stack",
		"modal_focus_stack.",
	]:
		_require(not run_scene_source.contains(forbidden_fragment), "RunScene retained modal coordination: %s" % forbidden_fragment)
	for forbidden_fragment: String in [
		"var focus_stack",
		"func focus_stack",
		"func get_focus_stack",
	]:
		_require(
			not modal_controller_source.contains(forbidden_fragment),
			"modal controller exposed its mutable stack: %s" % forbidden_fragment
		)
	for required_fragment: String in [
		"class_name RunSceneModalController",
		"owns_modal_root_registry",
		"owns_input_shield_routing",
		"owns_preferred_focus_resolution",
		"func _route_input_shield",
		"func _first_focusable_descendant",
		"func request_cancel_top",
	]:
		_require(modal_controller_source.contains(required_fragment), "modal controller contract missing: %s" % required_fragment)


func _test_debug_panel_extraction(run_scene_source: String, debug_panel_controller_source: String) -> void:
	for required_fragment: String in [
		"RunSceneDebugPanelControllerScript",
		"debug_panel_controller = RunSceneDebugPanelControllerScript.new()",
		"debug_panel_controller.bind_targets(",
		"debug_panel_controller.toggle_panel()",
		"debug_panel_controller.teleport_to_room_type(room_type)",
	]:
		_require(run_scene_source.contains(required_fragment), "RunScene debug-panel delegation missing: %s" % required_fragment)
	for forbidden_fragment: String in [
		"func _debug_meta_",
		"func _debug_search_and_show_loot",
		"func _debug_toggle_reduced_motion",
		"func _sync_debug_coordinates",
		"func _debug_target_pos",
		"RunSceneDebugBridgeScript",
	]:
		_require(not run_scene_source.contains(forbidden_fragment), "RunScene retained debug-panel responsibility: %s" % forbidden_fragment)
	for required_fragment: String in [
		"class_name RunSceneDebugPanelController",
		"RunSceneDebugBridgeScript",
		"func bind_targets(",
		"func toggle_panel()",
		"func teleport_to_room_type(",
		"func meta_add_gold()",
		"func meta_summary()",
	]:
		_require(debug_panel_controller_source.contains(required_fragment), "debug-panel controller contract missing: %s" % required_fragment)


func _test_modal_controller_runtime() -> void:
	var host := Control.new()
	host.name = "ArchitectureBoundaryModalHost"
	root.add_child(host)
	var input_shield := ColorRect.new()
	input_shield.name = "InputShield"
	host.add_child(input_shield)
	var modal_root := Control.new()
	modal_root.name = "EventModal"
	host.add_child(modal_root)
	var preferred_button := Button.new()
	preferred_button.name = "PreferredButton"
	preferred_button.focus_mode = Control.FOCUS_ALL
	modal_root.add_child(preferred_button)
	modal_root.hide()
	var run_surface_spy := RunSurfaceSpy.new()
	var input_sync_count := [0]
	var controller: RefCounted = RunSceneModalControllerScript.new()
	controller.bind_views(
		input_shield,
		run_surface_spy,
		{&"event": modal_root},
		func() -> void: input_sync_count[0] = int(input_sync_count[0]) + 1
	)
	_require(controller.preferred_focus(modal_root) == preferred_button, "modal controller did not resolve preferred focus")
	_require(
		bool(controller.push(&"event", modal_root, preferred_button)),
		"modal controller rejected a valid production modal"
	)
	var unregistered_modal := Control.new()
	unregistered_modal.name = "UnregisteredModal"
	host.add_child(unregistered_modal)
	_require(
		not bool(controller.push(&"unknown", unregistered_modal)),
		"modal controller accepted an unregistered modal id"
	)
	_require(
		not bool(controller.push(&"event", unregistered_modal)),
		"modal controller accepted a root that disagreed with its registry"
	)
	await process_frame
	_require(controller.top_modal_id() == &"event", "modal controller did not own stack top")
	_require(run_surface_spy.top_modal_id == &"event", "modal controller did not route surface visibility policy")
	_require(input_shield.visible, "modal controller did not expose the input shield")
	_require(input_shield.get_parent() == modal_root.get_parent(), "modal controller moved the input shield to the wrong layer")
	_require(input_shield.get_index() < modal_root.get_index(), "modal controller did not order the shield below the modal")
	_require(int(input_sync_count[0]) >= 2, "modal controller did not synchronize player input on bind and push")
	_require(bool(controller.pop(&"event")), "modal controller did not close its top modal")
	await process_frame
	_require(controller.depth() == 0, "modal controller retained a closed modal")
	_require(not input_shield.visible, "modal controller retained the input shield without a modal")
	host.free()


func _test_production_wiring() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production main scene did not load")
	if packed == null:
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var run_scene := main.get_node_or_null("RunScene")
	_require(run_scene != null, "production main scene does not contain RunScene")
	if run_scene != null:
		var controller: Variant = run_scene.get("modal_controller")
		_require(controller != null, "production RunScene did not construct the modal controller")
		if controller != null:
			var authority_variant: Variant = controller.call("describe_authority")
			var authority: Dictionary = authority_variant as Dictionary if authority_variant is Dictionary else {}
			_require(bool(authority.get("views_bound", false)), "production modal controller views were not bound")
			var registered_modal_ids: Array = authority.get("registered_modal_ids", [])
			_require(registered_modal_ids.size() == 10, "production modal registry is incomplete")
			_require(not bool(authority.get("mutates_game_state", true)), "modal controller claims game-state authority")
			_require(not bool(authority.get("persists_state", true)), "modal controller claims persistence authority")
		var shell_snapshot_variant: Variant = run_scene.call("_shell_snapshot")
		var shell_snapshot: Dictionary = shell_snapshot_variant as Dictionary if shell_snapshot_variant is Dictionary else {}
		var published_budget: Dictionary = shell_snapshot.get("run_scene_responsibility_budget", {})
		_require(
			StringName(published_budget.get("modal_coordination_owner", &"")) == &"RunSceneModalController",
			"production shell snapshot did not publish the modal ownership budget"
		)
	main.free()


func _read_source(path: String) -> String:
	var source := FileAccess.get_file_as_string(path)
	_require(not source.is_empty(), "required architecture source is empty: %s" % path)
	return source


func _physical_line_count(source: String) -> int:
	var normalized := source.replace("\r\n", "\n")
	if normalized.ends_with("\n"):
		normalized = normalized.left(-1)
	return normalized.split("\n").size() if not normalized.is_empty() else 0


func _top_level_function_count(source: String) -> int:
	var count := 0
	for line: String in source.replace("\r\n", "\n").split("\n"):
		if line.begins_with("func "):
			count += 1
	return count


func _regex_matches(source: String, pattern: String) -> bool:
	var expression := RegEx.new()
	var compile_error := expression.compile(pattern)
	_require(compile_error == OK, "architecture regex did not compile: %s" % pattern)
	return compile_error == OK and expression.search(source) != null


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(run_scene_source: String) -> void:
	if failures.is_empty():
		print(
			"%s lines=%d functions=%d runtime=RunRuntimeController lifecycle=RunStateMachine modal=RunSceneModalController wiring=production_main forbidden=0" % [
				PASS_MARKER,
				_physical_line_count(run_scene_source),
				_top_level_function_count(run_scene_source),
			]
		)
		quit(0)
		return
	for failure: String in failures:
		push_error("I3R RunScene architecture boundary failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
