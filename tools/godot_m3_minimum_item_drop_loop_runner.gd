extends SceneTree

const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RunRuleServiceScript := preload("res://scripts/core/run/run_rule_service.gd")
const RunEffectApplierScript := preload("res://scripts/core/run/run_effect_applier.gd")
const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	_validate_catalog_counts()
	_validate_ground_loot_and_inventory_loop()
	_validate_consumable_use()
	_validate_trader_safe_yield()
	_validate_success_settlement()
	_validate_failure_settlement()
	_validate_abandon_settlement()
	if failures.is_empty():
		print("M3_MINIMUM_ITEM_DROP_LOOP=PASS")
		quit(0)
	else:
		for failure: String in failures:
			printerr("M3_MINIMUM_ITEM_DROP_LOOP=FAIL:%s" % failure)
		quit(1)


func _start_standard_controller():
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	_require_ok(bus.dispatch(&"start_standard_run"), "start_standard_run")
	return controller


func _validate_catalog_counts() -> void:
	if M3ItemCatalogScript.equipment_items().size() < 6:
		_fail("expected at least 6 equipment items")
	if M3ItemCatalogScript.consumable_items().size() < 6:
		_fail("expected at least 6 consumable items")
	var collectible_count: int = M3ItemCatalogScript.collectible_items().size()
	if collectible_count < 18 or collectible_count > 24:
		_fail("expected 18-24 collectibles")
	if M3ItemCatalogScript.monster_drop_items().size() < 3:
		_fail("expected at least 3 monster drops")
	for item: Dictionary in M3ItemCatalogScript.all_items():
		if str(item.get("display_name", "")).is_empty():
			_fail("item missing display_name")
		if str(item.get("icon_fallback", "")).is_empty():
			_fail("item missing icon_fallback")
		if bool(item.get("is_unique", false)) and not bool(item.get("unique_drop_allowed", false)):
			_fail("ordinary catalog must not expose unique drops")


func _validate_ground_loot_and_inventory_loop() -> void:
	var controller = _start_standard_controller()
	var context = controller.context
	var pos: Vector2i = context.get_current_pos()
	var floor_before: int = context.asset_ledger.get_room_floor_items(pos).size()
	var result: Dictionary = RunRuleServiceScript.apply_search_reward(context, pos, 0, false)
	_require_ok(result, "search reward")
	var floor_items: Array = context.asset_ledger.get_room_floor_items(pos)
	if floor_items.size() <= floor_before:
		_fail("search reward did not create GroundLoot")
	var target_id: String = str(floor_items[0].get("instance_id", ""))
	var pickup: Dictionary = RunRuleServiceScript.pickup_ground_item(context, target_id)
	_require_ok(pickup, "pickup GroundLoot")
	if context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY).is_empty():
		_fail("pickup did not move item into backpack")
	var drop: Dictionary = RunRuleServiceScript.drop_inventory_item(context, target_id)
	_require_ok(drop, "drop inventory item")
	if context.asset_ledger.get_room_floor_items(pos).is_empty():
		_fail("drop did not return item to GroundLoot")
	var repick: Dictionary = RunRuleServiceScript.pickup_ground_item(context, target_id)
	_require_ok(repick, "repick GroundLoot")


func _validate_consumable_use() -> void:
	var controller = _start_standard_controller()
	var context = controller.context
	RunEffectApplierScript.apply_effects(context, [RunEffectApplierScript.effect_hp_delta(-10, "m3_runner_damage")], controller)
	var damaged_hp: int = context.hp
	var consumable: Dictionary = _inventory_item_def(M3ItemCatalogScript.consumable_items()[0])
	var add_result: Dictionary = context.asset_ledger.add_reward_items([consumable], RunAssetLedger.LOCATION_INVENTORY, context.get_current_pos(), "m3_runner_consumable")
	var inventory_items: Array = add_result.get("inventory_items", [])
	if inventory_items.is_empty():
		_fail("could not add consumable to backpack")
		return
	var instance_id: String = str((inventory_items[0] as Dictionary).get("instance_id", ""))
	var use_result: Dictionary = RunRuleServiceScript.use_consumable(context, instance_id)
	_require_ok(use_result, "use consumable")
	if context.hp <= damaged_hp:
		_fail("consumable did not apply HP recovery")
	var consumed_item: Dictionary = context.asset_ledger.item_instances.get(instance_id, {})
	if StringName(consumed_item.get("location_state", &"")) != RunAssetLedger.LOCATION_LOST:
		_fail("consumable was not consumed from backpack")


func _validate_trader_safe_yield() -> void:
	var controller = _start_standard_controller()
	var context = controller.context
	var sellable: Dictionary = _inventory_item_def(M3ItemCatalogScript.collectible_items()[0])
	context.asset_ledger.add_reward_items([sellable], RunAssetLedger.LOCATION_INVENTORY, context.get_current_pos(), "m3_runner_trader")
	var safe_before: int = context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_GOLD)
	var result: Dictionary = RunRuleServiceScript.execute_trader_sell_best(context)
	_require_ok(result, "trader sell")
	if not bool(result.get("ok", false)):
		return
	if context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_GOLD) <= safe_before:
		_fail("trader sell did not add safe_yield")
	if int(result.get("safe_yield_delta", 0)) <= 0:
		_fail("trader result missing safe_yield_delta")


func _validate_success_settlement() -> void:
	var controller = _start_standard_controller()
	var context = controller.context
	context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, 10, "m3_runner_success")
	context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_GOLD, 5, "m3_runner_success_safe")
	context.asset_ledger.add_reward_items([_inventory_item_def(M3ItemCatalogScript.equipment_items()[0])], RunAssetLedger.LOCATION_INVENTORY, context.get_current_pos(), "m3_runner_success")
	context.asset_ledger.add_reward_items([M3ItemCatalogScript.collectible_items()[1]], RunAssetLedger.LOCATION_ROOM_FLOOR, context.get_current_pos(), "m3_runner_floor_left")
	var exits: Array = context.truth_map.get_exits()
	if exits.is_empty():
		_fail("standard map missing exits")
	context.player_pos = exits[0]
	context.current_pos = exits[0]
	controller.command_bus.room_resolver.enter_room(context)
	_require_ok(controller.command_bus.dispatch(&"request_extract"), "request_extract")
	_require_ok(controller.command_bus.dispatch(&"confirm_extract"), "confirm_extract")
	var settlement: Dictionary = context.result_snapshot.get("settlement", {})
	if str(settlement.get("outcome", "")) != "success":
		_fail("success settlement did not report success")
	if int(settlement.get("long_term_gold_gained", 0)) < 15:
		_fail("success did not convert run_black_coin + safe_yield to long_term_gold")
	if (settlement.get("warehouse_lite", []) as Array).is_empty():
		_fail("success did not move backpack item to warehouse_lite")
	if (settlement.get("room_floor_lost_items", []) as Array).is_empty():
		_fail("success did not lose unpicked GroundLoot")
	_validate_run_result_boundary(context.result_snapshot, "success")


func _validate_failure_settlement() -> void:
	var controller = _start_standard_controller()
	var context = controller.context
	context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, 20, "m3_runner_failure")
	context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_GOLD, 7, "m3_runner_failure_safe")
	context.asset_ledger.add_reward_items([_inventory_item_def(M3ItemCatalogScript.consumable_items()[1])], RunAssetLedger.LOCATION_INVENTORY, context.get_current_pos(), "m3_runner_failure")
	context.asset_ledger.add_reward_items([M3ItemCatalogScript.collectible_items()[2]], RunAssetLedger.LOCATION_ROOM_FLOOR, context.get_current_pos(), "m3_runner_floor_lost")
	var applied: Dictionary = RunEffectApplierScript.apply_effects(context, [
		RunEffectApplierScript.effect(RunEffectApplierScript.EFFECT_RUN_FAIL, "m3_runner_fail", {"reason": "m3_runner_failure"}),
	], controller)
	_require_ok(applied, "runtime failure")
	var settlement: Dictionary = context.result_snapshot.get("settlement", {})
	if str(settlement.get("outcome", "")) != "failure":
		_fail("failure settlement did not report failure")
	if int(settlement.get("black_coin_lost", 0)) < 20:
		_fail("failure did not lose run_black_coin")
	if int(settlement.get("long_term_gold_gained", 0)) < 7:
		_fail("failure did not retain safe_yield to long_term_gold")
	if (settlement.get("salvaged_items", []) as Array).is_empty():
		_fail("failure did not salvage an inventory candidate")
	if (settlement.get("room_floor_lost_items", []) as Array).is_empty():
		_fail("failure did not lose unpicked GroundLoot")
	_validate_run_result_boundary(context.result_snapshot, "failure")


func _validate_abandon_settlement() -> void:
	var controller = _start_standard_controller()
	var context = controller.context
	context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, 20, "m3_runner_abandon")
	context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_GOLD, 7, "m3_runner_abandon_safe")
	var result: Dictionary = controller.abandon_run("m3_runner_abandon")
	_require_ok(result, "abandon run")
	if not context.abandoned:
		_fail("context was not marked abandoned")
	var settlement: Dictionary = context.result_snapshot.get("settlement", {})
	if str(settlement.get("outcome", "")) != "abandon":
		_fail("abandon settlement did not report abandon")
	if int(settlement.get("black_coin_lost", 0)) < 20:
		_fail("abandon did not lose run_black_coin")
	if int(settlement.get("long_term_gold_gained", 0)) != 0:
		_fail("abandon must not convert safe_yield this stage")
	if str(settlement.get("safe_yield_state", "")) != "pending_undecided":
		_fail("abandon safe_yield state not explicit")
	_validate_run_result_boundary(context.result_snapshot, "abandon")


func _inventory_item_def(item: Dictionary) -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	result["reward_location"] = RunAssetLedger.LOCATION_INVENTORY
	return result


func _validate_run_result_boundary(result_snapshot: Dictionary, label: String) -> void:
	if not result_snapshot.has("RunResult"):
		_fail("%s missing RunResult" % label)
	if not result_snapshot.has("SettlementInput"):
		_fail("%s missing SettlementInput" % label)
	var run_result: Dictionary = result_snapshot.get("RunResult", {})
	if bool(run_result.get("ui_recalculation_allowed", true)):
		_fail("%s RunResult allows UI recalculation" % label)
	if not bool(run_result.get("settlement_single_input", false)):
		_fail("%s RunResult missing settlement_single_input" % label)


func _require_ok(result: Dictionary, label: String) -> void:
	if not bool(result.get("ok", false)):
		_fail("%s failed: %s" % [label, JSON.stringify(result)])


func _fail(message: String) -> void:
	failures.append(message)
