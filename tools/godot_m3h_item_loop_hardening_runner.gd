extends SceneTree

const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")
const RunAssetLedgerScript := preload("res://scripts/core/run/run_asset_ledger.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RunFlowStateContractScript := preload("res://scripts/core/run/run_flow_state_contract.gd")

var failures: Array[String] = []


func _init() -> void:
	_validate_in_run_equipment_requires_extraction()
	_validate_carry_in_equipment_remains_active()
	_validate_unused_consumable_failure_salvage_candidate()
	_validate_abandon_settlement_branch()
	if failures.is_empty():
		print("M3H_ITEM_LOOP_HARDENING=PASS")
		quit(0)
	else:
		for failure: String in failures:
			printerr("M3H_ITEM_LOOP_HARDENING=FAIL:%s" % failure)
		quit(1)


func _validate_in_run_equipment_requires_extraction() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	_require_ok(bus.dispatch(&"start_standard_run"), "start standard run for in-run equipment")
	var context = controller.context
	var reward_equipment: Dictionary = M3ItemCatalogScript.equipment_items()[0].duplicate(true)
	reward_equipment["reward_location"] = RunAssetLedgerScript.LOCATION_EQUIPPED
	var reward_result: Dictionary = context.asset_ledger.add_reward_items(
		[reward_equipment],
		RunAssetLedgerScript.LOCATION_INVENTORY,
		context.get_current_pos(),
		"m3h_in_run_equipment"
	)
	var inventory_items: Array = reward_result.get("inventory_items", [])
	if inventory_items.is_empty():
		_fail("in-run equipment did not enter inventory for registration block test")
		return
	if not (reward_result.get("blocked_reasons", []) as Array).has("equipment_requires_extraction_registration"):
		_fail("in-run equipment reward did not report extraction registration boundary")
	var instance_id := String((inventory_items[0] as Dictionary).get("instance_id", ""))
	var equip_result: Dictionary = bus.dispatch(&"equip_item", {"instance_id": instance_id})
	if bool(equip_result.get("ok", false)):
		_fail("in-run acquired equipment was equipped before extraction registration")
	if String(equip_result.get("reason", "")) != "equipment_requires_extraction_registration":
		_fail("in-run equipment equip rejection used wrong reason: %s" % JSON.stringify(equip_result))
	for item in context.asset_ledger.get_items_by_location(RunAssetLedgerScript.LOCATION_EQUIPPED):
		if String((item as Dictionary).get("instance_id", "")) == instance_id:
			_fail("blocked in-run equipment still appeared in equipped list")


func _validate_carry_in_equipment_remains_active() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	var carry_in_equipment: Dictionary = M3ItemCatalogScript.equipment_items()[2].duplicate(true)
	carry_in_equipment["instance_id"] = "m3h_carry_in_equipment"
	var start_payload := {
		"run_start_config": {
			"selected_equipment_items": [carry_in_equipment],
			"selected_consumable_items": [],
			"backpack_capacity": 10,
			"failure_salvage_capacity": 2,
		}
	}
	_require_ok(bus.dispatch(&"start_standard_run", start_payload), "start standard run with carry-in equipment")
	var equipped: Array = controller.context.asset_ledger.get_items_by_location(RunAssetLedgerScript.LOCATION_EQUIPPED)
	if equipped.is_empty():
		_fail("carry-in equipment did not enter equipped state")
		return
	var item: Dictionary = equipped[0]
	if not bool(item.get("carry_in_equipment", false)):
		_fail("carry-in equipped item missing carry_in_equipment flag")
	if not bool(item.get("registered_for_run", false)):
		_fail("carry-in equipped item missing registered_for_run flag")
	if not bool(item.get("equip_allowed_now", false)):
		_fail("carry-in equipped item missing equip_allowed_now flag")


func _validate_unused_consumable_failure_salvage_candidate() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	var consumable: Dictionary = M3ItemCatalogScript.consumable_items()[0].duplicate(true)
	consumable["instance_id"] = "m3h_unused_consumable"
	consumable["weight"] = 1
	var start_payload := {
		"run_start_config": {
			"selected_equipment_items": [],
			"selected_consumable_items": [consumable],
			"backpack_capacity": 10,
			"failure_salvage_capacity": 2,
		}
	}
	_require_ok(bus.dispatch(&"start_standard_run", start_payload), "start standard run with salvage consumable")
	var fail_result: Dictionary = controller.fail_run("m3h_failure_salvage")
	_require_ok(fail_result, "runtime failure settlement")
	var settlement: Dictionary = controller.context.failure_salvage.duplicate(true)
	var salvaged: Array = settlement.get("salvaged_items", [])
	var found := false
	for item in salvaged:
		if String((item as Dictionary).get("instance_id", "")) == "m3h_unused_consumable":
			found = true
	if not found:
		_fail("unused carry-in consumable was not available as failure salvage candidate")


func _validate_abandon_settlement_branch() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	_require_ok(bus.dispatch(&"start_standard_run"), "start standard run for abandon")
	controller.context.asset_ledger.add_currency(RunAssetLedgerScript.CURRENCY_BLACK, 12, "m3h_abandon_test")
	controller.context.asset_ledger.add_currency(RunAssetLedgerScript.CURRENCY_SAFE_YIELD, 3, "m3h_abandon_test")
	var preview_before: Dictionary = RunFlowStateContractScript.build_abandon_intent_preview(controller.context)
	if not bool(preview_before.get("supported_now", false)):
		_fail("active run abandon preview is not supported")
	if StringName(preview_before.get("settlement_branch", &"")) != &"settle_abandon":
		_fail("abandon preview missing settle_abandon branch")
	if String(preview_before.get("boundary", "")).find("no real abandon settlement") >= 0:
		_fail("abandon preview still contains outdated no-real-settlement wording")
	var abandon_result: Dictionary = bus.dispatch(&"abandon_run", {"reason": "m3h_abandon"})
	_require_ok(abandon_result, "abandon through CommandBus/runtime authority")
	var settlement: Dictionary = controller.context.result_snapshot.get("settlement", {})
	if StringName(settlement.get("outcome", &"")) != &"abandon":
		_fail("abandon snapshot outcome was not abandon")
	if StringName(settlement.get("settlement_outcome", &"")) != &"abandon":
		_fail("abandon settlement_outcome was not abandon")
	if int(settlement.get("long_term_gold_gained", -1)) != 0:
		_fail("abandon granted long_term_gold")
	if StringName(settlement.get("safe_yield_state", &"")) != &"pending_undecided":
		_fail("abandon safe_yield_state was not pending_undecided")
	if settlement.has("extracted_items") or settlement.has("warehouse_items"):
		_fail("abandon exposed success extraction/warehouse write fields")
	var run_state: Dictionary = RunFlowStateContractScript.build_run_state(controller.context)
	if not bool(run_state.get("abandoned", false)):
		_fail("RunFlowStateContract did not expose abandoned state")


func _require_ok(result: Dictionary, label: String) -> void:
	if not bool(result.get("ok", false)):
		_fail("%s failed: %s" % [label, JSON.stringify(result)])


func _fail(message: String) -> void:
	failures.append(message)
