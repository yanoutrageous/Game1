extends SceneTree

const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")


func _init() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	_require_ok(bus.dispatch(&"start_standard_run"), "start_standard_run")
	var context = controller.context
	if context == null:
		_fail("missing RunContext")
	if context.mode != &"standard":
		_fail("expected standard mode, got %s" % str(context.mode))
	var modifier_delta: int = context.rule_pipeline.numeric_delta_for_rule(&"search_reward", "black_coin")
	if modifier_delta <= 0:
		_fail("expected positive search_reward modifier delta")
	var before_black: int = context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK)
	var reward_result: Dictionary = RunRuleService.apply_search_reward(context, context.get_current_pos(), 0, false)
	_require_ok(reward_result, "apply_search_reward")
	if int(reward_result.get("modifier_black_coin_delta", 0)) != modifier_delta:
		_fail("search reward did not report modifier delta")
	var after_black: int = context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK)
	if after_black <= before_black:
		_fail("search reward did not update run black coin")
	var current_pos: Vector2i = context.get_current_pos()
	var eligibility: Dictionary = context.truth_map.get_return_eligibility(current_pos, context.intel_map)
	if not bool(eligibility.get("eligible", false)):
		_fail("current explored room is not return eligible")
	_require_ok(bus.dispatch(&"teleport_to_explored", {"pos": current_pos}), "teleport_to_explored")
	var status_snapshot: Dictionary = context.get_status_snapshot()
	if not status_snapshot.has("RunResult"):
		_fail("status snapshot missing RunResult")
	var result_snapshot: Dictionary = context.build_result_snapshot()
	if not result_snapshot.has("settlement_input"):
		_fail("result snapshot missing settlement_input")
	if not bool(result_snapshot.get("settlement_reads_run_result_only", false)):
		_fail("settlement input boundary flag missing")
	print("M2_MINIMUM_LOOP_REGRESSION=PASS")
	quit(0)


func _require_ok(result: Dictionary, label: String) -> void:
	if not bool(result.get("ok", false)):
		_fail("%s failed: %s" % [label, JSON.stringify(result)])


func _fail(message: String) -> void:
	printerr("M2_MINIMUM_LOOP_REGRESSION=FAIL:%s" % message)
	quit(1)
