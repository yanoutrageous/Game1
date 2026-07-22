extends SceneTree

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const PageRouterScript := preload("res://scripts/ui/app_shell/page_router.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")

var failures: Array[String] = []


func _init() -> void:
	_validate_page_router_targets()
	_validate_navigation_intent_payloads()
	_validate_runtime_abandon_authority()
	if failures.is_empty():
		print("G39_NAVIGATION_BOUNDARY=PASS")
		quit(0)
	else:
		for failure: String in failures:
			printerr("G39_NAVIGATION_BOUNDARY=FAIL:%s" % failure)
		quit(1)


func _validate_page_router_targets() -> void:
	_require_equal(
		PageRouterScript.route_for_intent(NavigationIntentScript.make_deploy(&"test")).get("page"),
		PageRouterScript.PAGE_DEPLOY_PREP,
		"deploy intent routes to DeployPrep"
	)
	_require_equal(
		PageRouterScript.route_for_intent(NavigationIntentScript.make_long_term(&"test", &"profile")).get("page"),
		PageRouterScript.PAGE_LONG_TERM,
		"long-term intent routes to LongTerm"
	)
	_require_equal(
		PageRouterScript.route_for_intent(NavigationIntentScript.make_run(&"test", {"uses_existing_route": true})).get("page"),
		PageRouterScript.PAGE_RUN,
		"run intent routes to run"
	)


func _validate_navigation_intent_payloads() -> void:
	var deploy_intent: Dictionary = NavigationIntentScript.make_deploy(&"long_term", {"tab": &"config", "preview_only": false})
	_require_equal(NavigationIntentScript.target(deploy_intent), NavigationIntentScript.TARGET_DEPLOY, "deploy intent target")
	_require_equal(StringName(NavigationIntentScript.payload(deploy_intent).get("tab", &"")), &"config", "deploy intent tab payload")
	var long_term_intent: Dictionary = NavigationIntentScript.make_long_term(&"deploy_prep", &"goals", {"preview_only": false})
	_require_equal(NavigationIntentScript.target(long_term_intent), NavigationIntentScript.TARGET_LONG_TERM, "long-term intent target")
	_require_equal(StringName(NavigationIntentScript.payload(long_term_intent).get("module_id", &"")), &"task_archive", "long-term module payload")
	var run_intent: Dictionary = NavigationIntentScript.make_run(&"deploy_prep", {"uses_existing_route": true, "entry_id": &"standard_10x10"})
	_require_equal(NavigationIntentScript.target(run_intent), NavigationIntentScript.TARGET_RUN, "run intent target")
	_require_equal(StringName(NavigationIntentScript.payload(run_intent).get("entry_id", &"")), &"standard_10x10", "run entry payload")


func _validate_runtime_abandon_authority() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	var start_result: Dictionary = bus.dispatch(&"start_standard_run")
	_require_ok(start_result, "start standard run")
	var abandon_result: Dictionary = bus.dispatch(&"abandon_run", {"reason": "g39_navigation_boundary_runner"})
	_require_ok(abandon_result, "abandon through CommandBus/runtime authority")
	var snapshot: Dictionary = controller.context.result_snapshot
	if String(snapshot.get("outcome", "")) != "Abandoned":
		_fail("abandon result snapshot outcome was not Abandoned")
	var settlement: Dictionary = snapshot.get("settlement", {})
	if StringName(settlement.get("outcome", &"")) != &"abandon":
		_fail("abandon settlement outcome was not abandon")


func _require_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_fail("%s expected=%s actual=%s" % [label, str(expected), str(actual)])


func _require_ok(result: Dictionary, label: String) -> void:
	if not bool(result.get("ok", false)):
		_fail("%s failed: %s" % [label, JSON.stringify(result)])


func _fail(message: String) -> void:
	failures.append(message)
