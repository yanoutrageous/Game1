extends SceneTree

const CommandBusScript := preload("res://scripts/core/command/command_bus.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")
const M3RItemUsabilityModelScript := preload("res://scripts/core/content/m3r_item_usability_model.gd")
const RunAssetLedgerScript := preload("res://scripts/core/run/run_asset_ledger.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")

var failures: Array[String] = []


func _init() -> void:
	_validate_models_from_meta_summary()
	_validate_deploy_prep_run_start_config()
	_validate_runtime_carry_in_loop()
	if failures.is_empty():
		print("M3R_ITEM_USABILITY_COMPLETION=PASS")
		quit(0)
	else:
		for failure: String in failures:
			printerr("M3R_ITEM_USABILITY_COMPLETION=FAIL:%s" % failure)
		quit(1)


func _validate_models_from_meta_summary() -> void:
	var meta_summary := _sample_meta_summary()
	var warehouse: Dictionary = M3RItemUsabilityModelScript.build_warehouse_lite(meta_summary)
	var codex: Dictionary = M3RItemUsabilityModelScript.build_codex_lite(meta_summary)
	var loadout: Dictionary = M3RItemUsabilityModelScript.build_default_loadout(meta_summary)
	if int(warehouse.get("item_count", 0)) < 4:
		_fail("warehouse_lite did not read sample warehouse_items")
	if _group_size(warehouse, &"equipment") < 1:
		_fail("warehouse_lite missing equipment group")
	if _group_size(warehouse, &"consumable") < 1:
		_fail("warehouse_lite missing consumable group")
	if _group_size(warehouse, &"collectible") < 1:
		_fail("warehouse_lite missing collectible group")
	if int(codex.get("discovered_count", 0)) < 1:
		_fail("codex_lite did not derive discoveries from warehouse_items")
	if not (loadout.get("selected_equipment", []) as Array).is_empty():
		_fail("default loadout bypassed explicit equipment selection authority")
	if not (loadout.get("selected_consumables", []) as Array).is_empty():
		_fail("default loadout bypassed explicit consumable selection authority")


func _validate_deploy_prep_run_start_config() -> void:
	var default_config: Dictionary = DeployConfigScript.default_config(1, _sample_meta_summary())
	if not (default_config.get("selected_equipment_items", []) as Array).is_empty():
		_fail("default deploy config silently selected equipment")
	if not (default_config.get("selected_consumable_items", []) as Array).is_empty():
		_fail("default deploy config silently selected consumables")
	var deploy_config: Dictionary = _selected_deploy_config(default_config)
	var run_start: Dictionary = DeployConfigScript.build_run_start_config(deploy_config)
	if bool(run_start.get("preview", true)):
		_fail("RunStartConfig still marked preview")
	if bool(run_start.get("display_only", true)):
		_fail("RunStartConfig still marked display_only")
	if (run_start.get("selected_equipment_items", []) as Array).is_empty():
		_fail("RunStartConfig missing selected_equipment_items")
	if (run_start.get("selected_consumable_items", []) as Array).is_empty():
		_fail("RunStartConfig missing selected_consumable_items")
	if int(run_start.get("backpack_capacity", 0)) < 10:
		_fail("RunStartConfig missing backpack capacity")
	if not run_start.has("profile_fields") or not run_start.has("protocol_difficulty"):
		_fail("RunStartConfig missing profile/protocol fields")


func _validate_runtime_carry_in_loop() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	var deploy_config := _selected_deploy_config(DeployConfigScript.default_config(1, _sample_meta_summary()))
	var run_start: Dictionary = DeployConfigScript.build_run_start_config(deploy_config)
	var start_result: Dictionary = bus.dispatch(&"start_standard_run", {"run_start_config": run_start})
	_require_ok(start_result, "start standard run with M3R loadout")
	var context = controller.context
	var equipped: Array = context.asset_ledger.get_items_by_location(RunAssetLedgerScript.LOCATION_EQUIPPED)
	var inventory: Array = context.asset_ledger.get_items_by_location(RunAssetLedgerScript.LOCATION_INVENTORY)
	if equipped.is_empty():
		_fail("selected equipment did not enter equipped state")
	if inventory.is_empty():
		_fail("selected consumables did not enter inventory")
	if int(context.asset_ledger.failure_salvage_capacity) < 2:
		_fail("equipment/talent salvage capacity hook did not apply")
	if int(context.mine_dmg_reduce) < 5:
		_fail("mine damage reduction hook not visible in runtime context")
	var consumable_id := str((inventory[0] as Dictionary).get("instance_id", ""))
	var use_result: Dictionary = bus.dispatch(&"use_consumable", {"instance_id": consumable_id})
	_require_ok(use_result, "use carry-in consumable")
	var consumed_item: Dictionary = context.asset_ledger.item_instances.get(consumable_id, {})
	if StringName(consumed_item.get("location_state", &"")) != RunAssetLedgerScript.LOCATION_CONSUMED:
		_fail("carry-in consumable was not consumed through ledger")
	var snapshot: Dictionary = context.asset_ledger.get_public_snapshot(context.player_pos)
	if (snapshot.get("equipped_items", []) as Array).is_empty():
		_fail("runtime snapshot missing equipped items")
	if not snapshot.has("warehouse_lite"):
		_fail("runtime snapshot missing warehouse_lite field")


func _sample_meta_summary() -> Dictionary:
	return {
		"warehouse_items": [
			_item_with_instance(M3ItemCatalogScript.equipment_items()[0], "wh_eq_old_vest"),
			_item_with_instance(M3ItemCatalogScript.equipment_items()[4], "wh_eq_signal_pin"),
			_item_with_instance(M3ItemCatalogScript.consumable_items()[0], "wh_con_med_patch"),
			_item_with_instance(M3ItemCatalogScript.consumable_items()[4], "wh_con_rescue_tag"),
			_item_with_instance(M3ItemCatalogScript.collectible_items()[0], "wh_col_relic"),
			_item_with_instance(M3ItemCatalogScript.monster_drop_items()[0], "wh_monster_sample"),
		],
		"profile_level": 2,
		"profile_exp": 25,
		"permit_level": 1,
		"protocol_difficulty": 5,
	}


func _selected_deploy_config(config: Dictionary) -> Dictionary:
	var selected := _changed_config(
		DeployConfigScript.apply_card_action(config, &"warehouse", &"m3r_wh_eq_old_vest"),
		"select old vest"
	)
	selected = _changed_config(
		DeployConfigScript.apply_card_action(selected, &"warehouse", &"m3r_wh_eq_signal_pin"),
		"select signal pin"
	)
	return _changed_config(
		DeployConfigScript.apply_card_action(selected, &"warehouse", &"m3r_wh_con_med_patch"),
		"select medical patch"
	)


func _changed_config(result: Dictionary, label: String) -> Dictionary:
	if not bool(result.get("changed", false)):
		_fail("%s did not change deploy config: %s" % [label, JSON.stringify(result)])
	return (result.get("config", {}) as Dictionary).duplicate(true)


func _item_with_instance(source_item: Dictionary, instance_id: String) -> Dictionary:
	var item: Dictionary = source_item.duplicate(true)
	item["instance_id"] = instance_id
	return item


func _group_size(warehouse: Dictionary, group_id: StringName) -> int:
	var groups: Dictionary = warehouse.get("groups", {})
	if groups.has(group_id):
		return (groups.get(group_id, []) as Array).size()
	var text_id := str(group_id)
	if groups.has(text_id):
		return (groups.get(text_id, []) as Array).size()
	return 0


func _require_ok(result: Dictionary, label: String) -> void:
	if not bool(result.get("ok", false)):
		_fail("%s failed: %s" % [label, JSON.stringify(result)])


func _fail(message: String) -> void:
	failures.append(message)
