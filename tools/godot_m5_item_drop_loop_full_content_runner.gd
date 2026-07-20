extends SceneTree

const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RunRuleServiceScript := preload("res://scripts/core/run/run_rule_service.gd")
const RunAssetLedgerScript := preload("res://scripts/core/run/run_asset_ledger.gd")
const RunEffectApplierScript := preload("res://scripts/core/run/run_effect_applier.gd")
const EventServiceScript := preload("res://scripts/core/run/event_service.gd")
const RunBalanceCatalogScript := preload("res://scripts/core/run/run_balance_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	_validate_catalog_content()
	_validate_ground_loot_replace_and_consumable()
	_validate_trader_dice_altar()
	_validate_settlement_branches()
	if failures.is_empty():
		print("M5_ITEM_DROP_LOOP_FULL_CONTENT=PASS")
		quit(0)
	else:
		for failure: String in failures:
			printerr("M5_ITEM_DROP_LOOP_FULL_CONTENT=FAIL:%s" % failure)
		quit(1)


func _validate_catalog_content() -> void:
	_require_equal(M3ItemCatalogScript.equipment_items().size(), 6, "M5 equipment count")
	_require_equal(M3ItemCatalogScript.consumable_items().size(), 6, "M5 consumable count")
	_require_equal(M3ItemCatalogScript.collectible_items().size(), 24, "M5 collectible count")
	if M3ItemCatalogScript.monster_drop_items().size() < 3:
		_fail("M5 monster drops below minimum")
	var unique_items := M3ItemCatalogScript.unique_concept_items()
	if unique_items.is_empty():
		_fail("M5 unique concept list missing")
	for unique_item in unique_items:
		if bool(unique_item.get("ordinary_drop_allowed", true)):
			_fail("unique concept allowed ordinary drop")
	for table_id in [&"search", &"chest", &"monster", &"event", &"altar"]:
		for drop_item in M3ItemCatalogScript.drop_table(table_id):
			if bool(drop_item.get("is_unique", false)):
				_fail("ordinary drop table contains unique item: %s" % str(table_id))


func _validate_ground_loot_replace_and_consumable() -> void:
	var controller = _start_controller()
	var context = controller.context
	var pos: Vector2i = context.get_current_pos()
	context.asset_ledger.backpack_capacity = 1
	var carried := M3ItemCatalogScript.consumable_items()[0].duplicate(true)
	carried["instance_id"] = "m5_replace_carried"
	carried["reward_location"] = RunAssetLedgerScript.LOCATION_INVENTORY
	context.asset_ledger.add_reward_items([carried], RunAssetLedgerScript.LOCATION_INVENTORY, pos, "m5_replace")
	var ground := M3ItemCatalogScript.collectible_items()[8].duplicate(true)
	ground["instance_id"] = "m5_replace_ground"
	ground["weight"] = 1
	context.asset_ledger.add_reward_items([ground], RunAssetLedgerScript.LOCATION_ROOM_FLOOR, pos, "m5_replace")
	var pickup_blocked: Dictionary = RunRuleServiceScript.pickup_ground_item(context, "m5_replace_ground")
	if bool(pickup_blocked.get("ok", false)):
		_fail("pickup should block when backpack is full")
	var replaced: Dictionary = RunRuleServiceScript.replace_ground_item(context, "m5_replace_ground", "m5_replace_carried")
	_require_ok(replaced, "replace ground item")
	if StringName(context.asset_ledger.item_instances["m5_replace_ground"].get("location_state", &"")) != RunAssetLedgerScript.LOCATION_INVENTORY:
		_fail("replacement did not pick ground item into inventory")
	if StringName(context.asset_ledger.item_instances["m5_replace_carried"].get("location_state", &"")) != RunAssetLedgerScript.LOCATION_ROOM_FLOOR:
		_fail("replacement did not drop selected backpack item to floor")

	var candy := M3ItemCatalogScript.consumable_items()[4].duplicate(true)
	candy["instance_id"] = "m5_calm_candy"
	candy["reward_location"] = RunAssetLedgerScript.LOCATION_INVENTORY
	context.asset_ledger.backpack_capacity = 10
	context.asset_ledger.add_reward_items([candy], RunAssetLedgerScript.LOCATION_INVENTORY, pos, "m5_consumable")
	RunEffectApplierScript.apply_effects(context, [
		RunEffectApplierScript.effect_hp_delta(-10, "m5_damage"),
		RunEffectApplierScript.effect_protocol_pressure_delta(12, "m5_pressure"),
	], controller)
	var hp_before: int = context.hp
	var pressure_before: int = context.pressure
	var used: Dictionary = RunRuleServiceScript.use_consumable(context, "m5_calm_candy")
	_require_ok(used, "use calm candy")
	if context.hp <= hp_before:
		_fail("calm candy did not restore HP")
	if context.pressure >= pressure_before:
		_fail("calm candy did not reduce pressure")


func _validate_trader_dice_altar() -> void:
	var controller = _start_controller()
	var context = controller.context
	var pos: Vector2i = context.get_current_pos()
	var sellable := M3ItemCatalogScript.collectible_items()[0].duplicate(true)
	sellable["instance_id"] = "m5_trader_sellable"
	sellable["reward_location"] = RunAssetLedgerScript.LOCATION_INVENTORY
	context.asset_ledger.add_reward_items([sellable], RunAssetLedgerScript.LOCATION_INVENTORY, pos, "m5_trader")
	var sale: Dictionary = RunRuleServiceScript.execute_trader_sell_best(context)
	_require_ok(sale, "trader sale")
	if context.asset_ledger.get_currency(RunAssetLedgerScript.CURRENCY_GOLD) <= 0:
		_fail("trader sale did not create safe_yield")

	context.asset_ledger.add_currency(RunAssetLedgerScript.CURRENCY_BLACK, 40, "m5_dice")
	var dice: Dictionary = RunRuleServiceScript.execute_dice_bet(context, pos, EventServiceScript.DICE_BET)
	_require_ok(dice, "dice bet")
	if not dice.has("roll") or not dice.has("black_coin_delta"):
		_fail("dice result missing roll or black_coin_delta")

	RunEffectApplierScript.apply_effects(context, [RunEffectApplierScript.effect_hp_delta(-20, "m5_treatment_damage")], controller)
	var treatment: Dictionary = RunRuleServiceScript.execute_trader_treatment(context, 12, 18)
	_require_ok(treatment, "trader treatment")
	var info: Dictionary = RunRuleServiceScript.execute_trader_info(context, 6)
	_require_ok(info, "trader info")

	var altar_pos := _find_event_pos(context, &"altar")
	if altar_pos == Vector2i(-1, -1):
		_fail("could not find deterministic altar event position")
		return
	for i in range(5):
		var hp_cost := RunBalanceCatalogScript.altar_hp_cost_for_stage(i)
		if context.hp - hp_cost < 1:
			RunEffectApplierScript.apply_effects(context, [RunEffectApplierScript.effect_hp_delta(context.max_hp - context.hp, "m5_altar_runner_heal")], controller)
		var before_hp: int = context.hp
		var altar: Dictionary = EventServiceScript.execute_option(context, altar_pos, &"offer_hp", controller)
		_require_ok(altar, "altar stage %d" % [i + 1])
		if context.hp >= before_hp:
			_fail("altar stage did not spend HP")
		if i < 4 and bool(altar.get("completed", false)):
			_fail("altar completed before stage 5")
		if i == 4 and not bool(altar.get("completed", false)):
			_fail("altar did not complete on stage 5")


func _validate_settlement_branches() -> void:
	var success_controller = _start_controller()
	var success_context = success_controller.context
	success_context.asset_ledger.add_currency(RunAssetLedgerScript.CURRENCY_BLACK, 10, "m5_success")
	success_context.asset_ledger.add_currency(RunAssetLedgerScript.CURRENCY_GOLD, 4, "m5_success")
	success_context.asset_ledger.add_reward_items([_inventory_item_def(M3ItemCatalogScript.collectible_items()[2], "m5_success_item")], RunAssetLedgerScript.LOCATION_INVENTORY, success_context.get_current_pos(), "m5_success")
	var exits: Array = success_context.truth_map.get_exits()
	if exits.is_empty():
		_fail("standard map missing exits")
		return
	success_context.player_pos = exits[0]
	success_context.current_pos = exits[0]
	success_controller.command_bus.room_resolver.enter_room(success_context)
	_require_ok(success_controller.command_bus.dispatch(&"request_extract"), "request extract")
	_require_ok(success_controller.command_bus.dispatch(&"confirm_extract"), "confirm extract")
	var success_settlement: Dictionary = success_context.result_snapshot.get("settlement", {})
	if StringName(success_settlement.get("outcome", &"")) != &"success":
		_fail("success settlement outcome mismatch")
	if int(success_settlement.get("long_term_gold_gained", 0)) < 14:
		_fail("success did not convert run black coin plus safe yield")

	var failure_controller = _start_controller()
	var failure_context = failure_controller.context
	failure_context.asset_ledger.add_currency(RunAssetLedgerScript.CURRENCY_BLACK, 9, "m5_failure")
	failure_context.asset_ledger.add_currency(RunAssetLedgerScript.CURRENCY_GOLD, 3, "m5_failure")
	failure_context.asset_ledger.add_reward_items([_inventory_item_def(M3ItemCatalogScript.collectible_items()[5], "m5_failure_item")], RunAssetLedgerScript.LOCATION_INVENTORY, failure_context.get_current_pos(), "m5_failure")
	_require_ok(failure_controller.fail_run("m5_failure"), "fail run")
	var failure_settlement: Dictionary = failure_context.result_snapshot.get("settlement", {})
	if StringName(failure_settlement.get("outcome", &"")) != &"failure":
		_fail("failure settlement outcome mismatch")
	if int(failure_settlement.get("black_coin_lost", 0)) < 9:
		_fail("failure did not lose run black coin")
	if int(failure_settlement.get("salvage_capacity", 0)) < 4:
		_fail("failure salvage capacity did not use M5 capacity default")

	var abandon_controller = _start_controller()
	var abandon_context = abandon_controller.context
	abandon_context.asset_ledger.add_currency(RunAssetLedgerScript.CURRENCY_BLACK, 5, "m5_abandon")
	abandon_context.asset_ledger.add_currency(RunAssetLedgerScript.CURRENCY_GOLD, 2, "m5_abandon")
	_require_ok(abandon_controller.abandon_run("m5_abandon"), "abandon run")
	var abandon_settlement: Dictionary = abandon_context.result_snapshot.get("settlement", {})
	if StringName(abandon_settlement.get("outcome", &"")) != &"abandon":
		_fail("abandon settlement outcome mismatch")
	if StringName(abandon_settlement.get("safe_yield_state", &"")) != &"retained":
		_fail("abandon safe yield state was not retained")
	if int(abandon_settlement.get("long_term_gold_gained", -1)) != 2:
		_fail("abandon did not retain direct gold as long-term gold")


func _start_controller():
	var controller = RunRuntimeControllerScript.new()
	_require_ok(controller.command_bus.dispatch(&"start_standard_run", {
		"run_start_config": {
			"seed_value": 1001,
		},
	}), "start standard run")
	return controller


func _inventory_item_def(item: Dictionary, instance_id: String) -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	result["instance_id"] = instance_id
	result["reward_location"] = RunAssetLedgerScript.LOCATION_INVENTORY
	return result


func _find_event_pos(context: RunContext, event_type: StringName) -> Vector2i:
	if context == null or context.truth_map == null:
		return Vector2i(-1, -1)
	for x in range(context.width):
		for y in range(context.height):
			var pos := Vector2i(x, y)
			if StringName(context.truth_map.get_room_type(pos)) != &"Event":
				continue
			if EventServiceScript.get_event_type(context, pos) == event_type:
				return pos
	return Vector2i(-1, -1)


func _require_equal(actual: int, expected: int, label: String) -> void:
	if actual != expected:
		_fail("%s expected %d got %d" % [label, expected, actual])


func _require_ok(result: Dictionary, label: String) -> void:
	if not bool(result.get("ok", false)):
		_fail("%s failed: %s" % [label, JSON.stringify(result)])


func _fail(message: String) -> void:
	failures.append(message)
