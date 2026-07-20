extends SceneTree

const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")
const M3RItemUsabilityModelScript := preload("res://scripts/core/content/m3r_item_usability_model.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const RunAssetLedgerScript := preload("res://scripts/core/run/run_asset_ledger.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RunEffectApplierScript := preload("res://scripts/core/run/run_effect_applier.gd")
const RunRuleServiceScript := preload("res://scripts/core/run/run_rule_service.gd")
const RunSceneResultControllerScript := preload("res://scripts/core/run/run_scene_result_controller.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const SaveAdapterScript := preload("res://scripts/core/save/save_adapter.gd")

var failures: Array[String] = []


func _init() -> void:
	_validate_catalog_reachability()
	_validate_starter_and_manual_deploy()
	_validate_runtime_equipment_effects()
	_validate_terminal_settlement_and_history()
	if failures.is_empty():
		print("M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP=PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP=FAIL:%s" % failure)
		quit(1)


func _validate_catalog_reachability() -> void:
	var reachable: Dictionary = {}
	for table_id in [&"search", &"chest", &"monster", &"event", &"altar"]:
		for item in M3ItemCatalogScript.drop_table(table_id):
			reachable[String(item.get("item_id", ""))] = String(table_id)
	for item in M3ItemCatalogScript.all_items():
		var item_id := String(item.get("item_id", ""))
		if bool(item.get("is_virtual_record", false)):
			if bool(item.get("can_store", true)):
				_fail("virtual record can enter warehouse: %s" % item_id)
			continue
		if bool(item.get("is_unique", false)):
			continue
		if not reachable.has(item_id):
			_fail("physical non-unique item has no executable source: %s" % item_id)
	for unique_item in M3ItemCatalogScript.unique_concept_items():
		if StringName(unique_item.get("item_type", &"")) != M3ItemCatalogScript.TYPE_COLLECTIBLE:
			_fail("unique placeholder is not classified as collectible")
		if bool(unique_item.get("ordinary_drop_allowed", true)):
			_fail("unique placeholder entered ordinary acquisition")


func _validate_starter_and_manual_deploy() -> void:
	var save_adapter = SaveAdapterScript.new()
	var meta: Dictionary = save_adapter.default_meta_progress()
	var starters: Array = meta.get("warehouse_items", [])
	_require_equal(starters.size(), 6, "starter instance count")
	_require_equal(_count_item(starters, "eq_goggles"), 1, "starter goggles")
	_require_equal(_count_item(starters, "eq_insulated_sleeve"), 1, "starter insulated sleeve")
	_require_equal(_count_item(starters, "con_ration"), 2, "starter ration")
	_require_equal(_count_item(starters, "con_tape_roll"), 1, "starter tape")
	_require_equal(_count_item(starters, "con_scan_pin"), 1, "starter scan pin")

	var expanded_warehouse := starters.duplicate(true)
	var extra_equipment := _catalog_item("eq_old_vest")
	extra_equipment["instance_id"] = "m6_test:eq_old_vest:1"
	expanded_warehouse.append(extra_equipment)
	var deploy := DeployConfigScript.default_config(1, {"warehouse_items": expanded_warehouse})
	if not (deploy.get("selected_equipment_items", []) as Array).is_empty() or not (deploy.get("selected_consumable_items", []) as Array).is_empty():
		_fail("DeployPrep auto-selected warehouse instances")

	deploy = _changed_config(DeployConfigScript.apply_card_action(deploy, &"warehouse", StringName("m3r_m6_starter:eq_goggles:1")), "select starter goggles")
	deploy = _changed_config(DeployConfigScript.apply_card_action(deploy, &"warehouse", StringName("m3r_m6_starter:eq_insulated_sleeve:1")), "select starter sleeve")
	var third_equipment := DeployConfigScript.apply_card_action(deploy, &"warehouse", &"m3r_m6_test:eq_old_vest:1")
	if bool(third_equipment.get("changed", false)):
		_fail("third equipped item bypassed M6 maximum of two")

	for instance_id in ["m6_starter:con_ration:1", "m6_starter:con_ration:2", "m6_starter:con_tape_roll:1"]:
		deploy = _changed_config(DeployConfigScript.apply_card_action(deploy, &"warehouse", StringName("m3r_%s" % instance_id)), "select carried consumable")
	var fourth_consumable := DeployConfigScript.apply_card_action(deploy, &"warehouse", &"m3r_m6_starter:con_scan_pin:1")
	if bool(fourth_consumable.get("changed", false)):
		_fail("fourth carried consumable bypassed M6 maximum of three")
	var claim_while_full := DeployConfigScript.apply_card_action(deploy, &"claim", &"claim_emergency_ration")
	if bool(claim_while_full.get("changed", false)):
		_fail("emergency ration bypassed full consumable slots")

	deploy = _changed_config(DeployConfigScript.apply_card_action(deploy, &"warehouse", &"m3r_m6_starter:con_tape_roll:1"), "remove carried consumable")
	deploy = _changed_config(DeployConfigScript.apply_card_action(deploy, &"claim", &"claim_emergency_ration"), "claim emergency ration")
	var claimed := _find_item(deploy.get("selected_consumable_items", []), "claim:deploy_m3r_0001:con_ration")
	if claimed.is_empty() or not bool(claimed.get("temporary_claim", false)):
		_fail("emergency ration did not become a temporary run instance")
	var run_start := DeployConfigScript.build_run_start_config(deploy)
	_require_equal((run_start.get("selected_equipment_items", []) as Array).size(), 2, "run start selected equipment")
	_require_equal((run_start.get("selected_consumable_items", []) as Array).size(), 3, "run start selected consumables")
	_require_equal(int(run_start.get("scan_hint_bonus", 0)), 1, "goggles scan bonus")
	_require_equal(int(run_start.get("protocol_pressure_reduce", 0)), 3, "sleeve pressure reduction")
	var invalid_start := run_start.duplicate(true)
	var invalid_equipment: Array = invalid_start.get("selected_equipment_items", [])
	invalid_equipment.append(_instance("eq_old_vest", "m6_invalid_third_equipment"))
	invalid_start["selected_equipment_items"] = invalid_equipment
	var invalid_controller = RunRuntimeControllerScript.new()
	var blocked_start: Dictionary = invalid_controller.command_bus.dispatch(&"start_standard_run", {"run_start_config": invalid_start})
	if bool(blocked_start.get("ok", false)):
		_fail("CommandBus accepted an invalid three-equipment RunStartConfig")


func _validate_runtime_equipment_effects() -> void:
	var meta := {"warehouse_items": [_instance("eq_old_vest", "m6_effect:vest"), _instance("eq_edge_opener", "m6_effect:opener")]}
	var deploy := DeployConfigScript.default_config(2, meta)
	deploy = _changed_config(DeployConfigScript.apply_card_action(deploy, &"warehouse", &"m3r_m6_effect:vest"), "select old vest")
	deploy = _changed_config(DeployConfigScript.apply_card_action(deploy, &"warehouse", &"m3r_m6_effect:opener"), "select edge opener")
	var run_start := DeployConfigScript.build_run_start_config(deploy)
	_require_equal(int(run_start.get("mine_dmg_reduce", 0)), 10, "old vest mine reduction")
	_require_equal(int(run_start.get("search_reward_bonus", 0)), 1, "edge opener search bonus")
	var controller = _start_controller(run_start)
	var context = controller.context
	_require_equal(context.asset_ledger.backpack_capacity, 10, "equipment effects applied exactly once")
	var before_black: int = context.asset_ledger.get_currency(RunAssetLedgerScript.CURRENCY_BLACK)
	var search_result := RunRuleServiceScript.apply_search_reward(context, context.get_current_pos(), 0, false)
	_require_ok(search_result, "runtime search with equipment")
	if context.asset_ledger.get_currency(RunAssetLedgerScript.CURRENCY_BLACK) - before_black < 1:
		_fail("edge opener did not affect executable search reward")

	var support_meta := {"warehouse_items": [_instance("eq_goggles", "m6_effect:goggles"), _instance("eq_insulated_sleeve", "m6_effect:sleeve")]}
	var support_deploy := DeployConfigScript.default_config(3, support_meta)
	support_deploy = _changed_config(DeployConfigScript.apply_card_action(support_deploy, &"warehouse", &"m3r_m6_effect:goggles"), "select goggles")
	support_deploy = _changed_config(DeployConfigScript.apply_card_action(support_deploy, &"warehouse", &"m3r_m6_effect:sleeve"), "select sleeve")
	var support_controller = _start_controller(DeployConfigScript.build_run_start_config(support_deploy))
	var support_context = support_controller.context
	RunEffectApplierScript.apply_effects(support_context, [RunEffectApplierScript.effect_protocol_pressure_delta(5, "m6_pressure_test")], support_controller)
	_require_equal(support_context.pressure, 2, "insulated sleeve actual pressure reduction")
	_require_equal(support_context.scan_hint_bonus, 1, "goggles actual scan hint state")


func _validate_terminal_settlement_and_history() -> void:
	var save_adapter = SaveAdapterScript.new()
	var starter_meta: Dictionary = save_adapter.default_meta_progress()
	var deploy := DeployConfigScript.default_config(4, starter_meta)
	deploy = _changed_config(DeployConfigScript.apply_card_action(deploy, &"warehouse", &"m3r_m6_starter:eq_goggles:1"), "failure carry goggles")
	deploy = _changed_config(DeployConfigScript.apply_card_action(deploy, &"warehouse", &"m3r_m6_starter:con_ration:1"), "failure carry ration")
	var controller = _start_controller(DeployConfigScript.build_run_start_config(deploy))
	var context = controller.context
	var loot := _instance("col_01", "m6_failure_loot")
	loot["reward_location"] = RunAssetLedgerScript.LOCATION_INVENTORY
	context.asset_ledger.add_reward_items([loot], RunAssetLedgerScript.LOCATION_INVENTORY, context.get_current_pos(), "m6_runner")
	context.asset_ledger.add_currency(RunAssetLedgerScript.CURRENCY_BLACK, 9, "m6_runner")
	context.asset_ledger.add_currency(RunAssetLedgerScript.CURRENCY_GOLD, 3, "m6_runner")
	_require_ok(controller.fail_run("m6_runner_failure"), "enter failure salvage")
	var pending: Dictionary = context.result_snapshot.get("settlement", {})
	if not bool(pending.get("requires_salvage_selection", false)) or bool(pending.get("finalized", true)):
		_fail("failure did not pause on manual salvage selection")
	if not (pending.get("salvaged_items", []) as Array).is_empty():
		_fail("failure preview silently auto-selected salvage")
	if StringName(context.asset_ledger.item_instances["m6_failure_loot"].get("location_state", &"")) != RunAssetLedgerScript.LOCATION_INVENTORY:
		_fail("failure preview mutated item ownership before confirmation")
	var invalid: Dictionary = controller.confirm_failure_salvage(["m6_failure_loot", "unknown_instance"])
	if bool(invalid.get("ok", false)):
		_fail("invalid salvage selection was accepted")
	var final_result: Dictionary = controller.confirm_failure_salvage(["m6_failure_loot"])
	_require_ok(final_result, "confirm manual failure salvage")
	var settlement: Dictionary = context.result_snapshot.get("settlement", {})
	if not bool(settlement.get("finalized", false)):
		_fail("confirmed failure settlement is not final")
	_require_equal(int(settlement.get("salvaged_item_count", 0)), 1, "manual salvaged item count")
	_require_equal(int(settlement.get("cleared_consumable_count", 0)), 1, "failure cleared consumable count")
	_require_equal(int(settlement.get("gold_coin_gained", 0)), 3, "failure retained direct gold")

	var adapter = MetaProgressAdapterScript.new()
	var temp_path := "user://m6_validation/meta_%d.json" % Time.get_ticks_usec()
	adapter.active_meta_progress_path = temp_path
	adapter.data = save_adapter.default_meta_progress()
	var display_pending := RunSceneResultControllerScript.build_result_display_snapshot({
		"result_id": "m6_pending_guard",
		"outcome": "Failed",
		"settlement": {"requires_salvage_selection": true, "finalized": false},
	}, adapter.get_summary(), {})
	if bool((display_pending.get("meta_progress_commit", {}) as Dictionary).get("committed", true)):
		_fail("pending failure reached MetaProgress commit")
	var commit := adapter.apply_settlement(context.result_snapshot)
	_require_ok(commit, "atomic failure MetaProgress commit")
	_require_equal(int(adapter.get_summary().get("history_record_count", 0)), 1, "persisted history count")
	var warehouse_after: Array = adapter.get_summary().get("warehouse_items", [])
	if _find_item(warehouse_after, "m6_starter:eq_goggles:1").size() > 0:
		_fail("unsalvaged carry-in equipment returned to warehouse")
	if _find_item(warehouse_after, "m6_starter:con_ration:1").size() > 0:
		_fail("carry-in consumable returned to warehouse")
	if _find_item(warehouse_after, "m6_failure_loot").is_empty():
		_fail("selected failure salvage did not enter warehouse")
	var duplicate := adapter.apply_settlement(context.result_snapshot)
	if String(duplicate.get("status", "")) != "duplicate_ignored":
		_fail("duplicate result was not ignored")
	_require_equal(int(adapter.get_summary().get("history_record_count", 0)), 1, "idempotent history count")
	var reloaded_adapter = MetaProgressAdapterScript.new()
	reloaded_adapter.set_active_profile_path(temp_path, "m6_validation")
	_require_equal(int(reloaded_adapter.get_summary().get("history_record_count", 0)), 1, "reloaded history count")
	if _find_item(reloaded_adapter.get_summary().get("warehouse_items", []), "m6_failure_loot").is_empty():
		_fail("reloaded MetaProgress lost the selected salvage instance")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))

	var abandon_ledger = RunAssetLedgerScript.new()
	abandon_ledger.setup({"selected_consumable_items": [_instance("con_ration", "m6_abandon_ration")]})
	abandon_ledger.add_currency(RunAssetLedgerScript.CURRENCY_BLACK, 5, "m6_abandon")
	abandon_ledger.add_currency(RunAssetLedgerScript.CURRENCY_GOLD, 2, "m6_abandon")
	var abandon := abandon_ledger.settle_abandon("m6_runner")
	_require_equal(int(abandon.get("salvage_capacity", -1)), 0, "abandon salvage capacity")
	_require_equal(int(abandon.get("gold_coin_gained", 0)), 2, "abandon retained direct gold")
	_require_equal(int(abandon.get("cleared_consumable_count", 0)), 1, "abandon cleared consumable")

	var success_ledger = RunAssetLedgerScript.new()
	success_ledger.setup({"selected_equipment_items": [_instance("eq_goggles", "m6_success_goggles")], "selected_consumable_items": [_instance("con_scan_pin", "m6_success_scan")]})
	success_ledger.add_currency(RunAssetLedgerScript.CURRENCY_BLACK, 4, "m6_success")
	success_ledger.add_currency(RunAssetLedgerScript.CURRENCY_GOLD, 2, "m6_success")
	var success := success_ledger.settle_success()
	_require_equal(int(success.get("gold_coin_gained", 0)), 6, "success currency settlement")
	_require_equal(int(success.get("cleared_consumable_count", 0)), 1, "success cleared consumable")
	if _find_item(success.get("warehouse_items", []), "m6_success_goggles").is_empty():
		_fail("success did not return carried equipment")
	if not _find_item(success.get("warehouse_items", []), "m6_success_scan").is_empty():
		_fail("success returned unused consumable")


func _start_controller(run_start_config: Dictionary):
	var controller = RunRuntimeControllerScript.new()
	_require_ok(controller.command_bus.dispatch(&"start_standard_run", {"run_start_config": run_start_config}), "start M6 standard run")
	return controller


func _catalog_item(item_id: String) -> Dictionary:
	return M3RItemUsabilityModelScript.item_definition(item_id)


func _instance(item_id: String, instance_id: String) -> Dictionary:
	var item := _catalog_item(item_id)
	item["instance_id"] = instance_id
	return item


func _find_item(items: Array, instance_id: String) -> Dictionary:
	for raw_item in items:
		if raw_item is Dictionary and String((raw_item as Dictionary).get("instance_id", "")) == instance_id:
			return (raw_item as Dictionary).duplicate(true)
	return {}


func _count_item(items: Array, item_id: String) -> int:
	var count := 0
	for raw_item in items:
		if raw_item is Dictionary and String((raw_item as Dictionary).get("item_id", "")) == item_id:
			count += 1
	return count


func _changed_config(action: Dictionary, label: String) -> Dictionary:
	if not bool(action.get("changed", false)):
		_fail("%s did not change config: %s" % [label, JSON.stringify(action)])
	return (action.get("config", {}) as Dictionary).duplicate(true)


func _require_equal(actual: int, expected: int, label: String) -> void:
	if actual != expected:
		_fail("%s expected %d got %d" % [label, expected, actual])


func _require_ok(result: Dictionary, label: String) -> void:
	if not bool(result.get("ok", false)):
		_fail("%s failed: %s" % [label, JSON.stringify(result)])


func _fail(message: String) -> void:
	failures.append(message)
