extends SceneTree

const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RunEffectApplierScript := preload("res://scripts/core/run/run_effect_applier.gd")


func _init() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	_require_ok(bus.dispatch(&"start_standard_run"), "start_standard_run")
	var context = controller.context
	if context == null:
		_fail("missing RunContext")
	if context.mode != &"standard":
		_fail("expected standard mode, got %s" % str(context.mode))
	if context.asset_ledger == null:
		_fail("missing RunAssetLedger")
	if context.rule_pipeline == null:
		_fail("missing RunRulePipeline")

	var before_hp: int = context.hp
	RunEffectApplierScript.apply_effects(context, [RunEffectApplierScript.effect_hp_delta(-1, "m2_runner")], controller)
	if context.hp != before_hp - 1:
		_fail("hp_delta did not change HP")

	var before_pressure: int = context.pressure
	RunEffectApplierScript.apply_effects(context, [RunEffectApplierScript.effect_protocol_pressure_delta(3, "m2_runner")], controller)
	if context.pressure != before_pressure + 3:
		_fail("protocol pressure delta did not change pressure")

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

	var status_snapshot: Dictionary = context.get_status_snapshot()
	if not status_snapshot.has("RunResult"):
		_fail("status snapshot missing RunResult")
	if not status_snapshot.has("SettlementInput"):
		_fail("status snapshot missing SettlementInput")

	_require_ok(controller.fail_run("m2_runner_forced_failure"), "runtime fail")
	var result_snapshot: Dictionary = context.result_snapshot
	if not result_snapshot.has("RunResult"):
		_fail("terminal result snapshot missing RunResult")
	if not result_snapshot.has("SettlementInput"):
		_fail("terminal result snapshot missing SettlementInput")
	if not bool(result_snapshot.get("settlement_reads_run_result_only", false)):
		_fail("settlement input boundary flag missing")
	var run_result: Dictionary = result_snapshot.get("RunResult", {})
	if bool(run_result.get("ui_recalculation_allowed", true)):
		_fail("RunResult allows UI recalculation")
	if not bool(run_result.get("settlement_single_input", false)):
		_fail("RunResult is not marked as settlement input")

	print("M2_LUA_UE_EFFECT_FIRST_LOOP=PASS")
	quit(0)


func _require_ok(result: Dictionary, label: String) -> void:
	if not bool(result.get("ok", false)):
		_fail("%s failed: %s" % [label, JSON.stringify(result)])


func _fail(message: String) -> void:
	printerr("M2_LUA_UE_EFFECT_FIRST_LOOP=FAIL:%s" % message)
	quit(1)
