extends SceneTree

const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RunEffectApplierScript := preload("res://scripts/core/run/run_effect_applier.gd")
const RunRuleServiceScript := preload("res://scripts/core/run/run_rule_service.gd")
const RunContentCatalogScript := preload("res://scripts/core/run/run_content_catalog.gd")
const CombatStateScript := preload("res://scripts/core/run/combat_state.gd")


func _init() -> void:
	var controller = _start_standard_controller()
	var context = controller.context
	_validate_standard_context(context)

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

	_validate_chest_reward_path(context)
	_validate_ground_pickup_path(context, controller)
	_validate_event_effect_path(context, controller)
	_validate_combat_reward_path(context, controller)
	_validate_mine_effect_path(context, controller)
	var status_snapshot: Dictionary = context.get_status_snapshot()
	if not status_snapshot.has("RunResult"):
		_fail("status snapshot missing RunResult")
	if not status_snapshot.has("SettlementInput"):
		_fail("status snapshot missing SettlementInput")

	_validate_extract_path()
	_validate_fail_path()

	print("M2_LUA_UE_EFFECT_FIRST_LOOP=PASS")
	quit(0)


func _start_standard_controller():
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	_require_ok(bus.dispatch(&"start_standard_run"), "start_standard_run")
	return controller


func _validate_standard_context(context) -> void:
	if context == null:
		_fail("missing RunContext")
	if context.mode != &"standard":
		_fail("expected standard mode, got %s" % str(context.mode))
	if context.width != 10 or context.height != 10:
		_fail("expected standard_10x10, got %sx%s" % [context.width, context.height])
	if context.asset_ledger == null:
		_fail("missing RunAssetLedger")
	if context.rule_pipeline == null:
		_fail("missing RunRulePipeline")


func _validate_chest_reward_path(context) -> void:
	var before_black: int = context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK)
	var before_items: int = context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY).size()
	var chest_result: Dictionary = RunRuleServiceScript.apply_search_reward(context, Vector2i(1, 1), 2, true)
	_require_ok(chest_result, "chest search reward")
	if context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK) <= before_black:
		_fail("chest reward did not update black coin")
	if context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY).size() <= before_items:
		_fail("chest reward did not add backpack item")


func _validate_ground_pickup_path(context, controller) -> void:
	var item_def := RunContentCatalogScript.item_def("m2_runner_floor_item", "M2 Runner Floor Item", &"runner_test", 1, &"common", ["m2_runner"])
	var add_result: Dictionary = RunEffectApplierScript.apply_effects(context, [
		RunEffectApplierScript.effect(RunEffectApplierScript.EFFECT_GROUND_LOOT_ADD, "m2_runner_ground", {"item_defs": [item_def]}, context.get_current_pos()),
	], controller)
	_require_ok(add_result, "ground loot add")
	var floor_items: Array = context.asset_ledger.get_room_floor_items(context.get_current_pos())
	if floor_items.is_empty():
		_fail("ground loot add did not create floor item")
	var before_inventory: int = context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY).size()
	var pickup_result: Dictionary = RunRuleServiceScript.pickup_ground_item(context, String(floor_items[0].get("instance_id", "")))
	_require_ok(pickup_result, "pickup ground item")
	if context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY).size() <= before_inventory:
		_fail("pickup did not move ground item into backpack")


func _validate_event_effect_path(context, controller) -> void:
	var before_hp: int = context.hp
	var before_pressure: int = context.pressure
	var before_black: int = context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK)
	var before_items: int = context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY).size()
	var event_item := RunContentCatalogScript.item_def("m2_runner_event_item", "M2 Runner Event Item", &"runner_test", 2, &"common", ["m2_runner", "event"])
	var result: Dictionary = RunRuleServiceScript.apply_event_rule_result(context, &"trap", {
		"ok": true,
		"completed": true,
		"event_type": &"trap",
		"hp_delta": -1,
		"protocol_pressure_delta": 2,
		"black_coin_delta": 3,
		"item_defs": [event_item],
		"message": "M2 runner event resolved.",
	}, controller)
	_require_ok(result, "event effect result")
	if context.hp != before_hp - 1:
		_fail("event hp_delta did not change HP")
	if context.pressure != before_pressure + 2:
		_fail("event protocol pressure did not change")
	if context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK) <= before_black:
		_fail("event black coin did not change")
	if context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY).size() <= before_items:
		_fail("event item effect did not add backpack item")


func _validate_combat_reward_path(context, controller) -> void:
	var before_hp: int = context.hp
	CombatStateScript.apply_damage(context, 2, "m2_runner_combat", controller)
	if context.hp != before_hp - 2:
		_fail("combat damage did not use HP effect path")
	var before_black: int = context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK)
	var result: Dictionary = RunRuleServiceScript.apply_combat_reward(context, context.get_current_pos(), 12)
	_require_ok(result, "combat reward")
	if context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK) <= before_black:
		_fail("combat reward did not update black coin")


func _validate_mine_effect_path(context, controller) -> void:
	var before_hp: int = context.hp
	var before_pressure: int = context.pressure
	var applied: Dictionary = RunEffectApplierScript.apply_effects(context, [
		RunEffectApplierScript.effect_hp_delta(-5, "m2_runner_mine"),
		RunEffectApplierScript.effect_protocol_pressure_delta(10, "m2_runner_mine"),
		RunEffectApplierScript.effect_mine_mark_triggered(context.get_current_pos()),
	], controller)
	_require_ok(applied, "mine effect bundle")
	if context.hp != before_hp - 5:
		_fail("mine hp effect did not change HP")
	if context.pressure != before_pressure + 10:
		_fail("mine pressure effect did not change pressure")


func _validate_extract_path() -> void:
	var controller = _start_standard_controller()
	var context = controller.context
	var bus = controller.command_bus
	var exits: Array = context.truth_map.get_exits()
	if exits.is_empty():
		_fail("standard run missing exit")
	context.player_pos = exits[0]
	context.current_pos = exits[0]
	bus.room_resolver.enter_room(context)
	_require_ok(bus.dispatch(&"request_extract"), "request_extract")
	_require_ok(bus.dispatch(&"confirm_extract"), "confirm_extract")
	if not context.extracted:
		_fail("extract path did not mark context extracted")
	_validate_result_snapshot(context.result_snapshot, "extract result")


func _validate_fail_path() -> void:
	var controller = _start_standard_controller()
	var context = controller.context
	var applied: Dictionary = RunEffectApplierScript.apply_effects(context, [
		RunEffectApplierScript.effect(RunEffectApplierScript.EFFECT_RUN_FAIL, "m2_runner_fail", {"reason": "m2_runner_forced_failure"}),
	], controller)
	_require_ok(applied, "runtime fail effect")
	if not context.failed:
		_fail("fail effect did not mark context failed")
	_validate_result_snapshot(context.result_snapshot, "fail result")


func _validate_result_snapshot(result_snapshot: Dictionary, label: String) -> void:
	if not result_snapshot.has("RunResult"):
		_fail("%s missing RunResult" % label)
	if not result_snapshot.has("SettlementInput"):
		_fail("%s missing SettlementInput" % label)
	if not bool(result_snapshot.get("settlement_reads_run_result_only", false)):
		_fail("settlement input boundary flag missing")
	var run_result: Dictionary = result_snapshot.get("RunResult", {})
	if bool(run_result.get("ui_recalculation_allowed", true)):
		_fail("RunResult allows UI recalculation")
	if not bool(run_result.get("settlement_single_input", false)):
		_fail("RunResult is not marked as settlement input")


func _require_ok(result: Dictionary, label: String) -> void:
	if not bool(result.get("ok", false)):
		_fail("%s failed: %s" % [label, JSON.stringify(result)])


func _fail(message: String) -> void:
	printerr("M2_LUA_UE_EFFECT_FIRST_LOOP=FAIL:%s" % message)
	quit(1)
