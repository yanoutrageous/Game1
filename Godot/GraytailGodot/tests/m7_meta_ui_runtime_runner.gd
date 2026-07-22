extends SceneTree

const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")
const CommandBusScript := preload("res://scripts/core/command/command_bus.gd")

var failures: Array[String] = []
var deploy_prep_model_script: GDScript
var long_term_model_script: GDScript


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	deploy_prep_model_script = load("res://scripts/ui/deploy_prep/deploy_prep_model.gd") as GDScript
	long_term_model_script = load("res://scripts/ui/long_term/long_term_model.gd") as GDScript
	_check(deploy_prep_model_script != null, "deploy_model_load_failed")
	_check(long_term_model_script != null, "long_term_model_load_failed")
	_test_long_term_real_content()
	_test_deploy_refresh_and_sale_confirmation()
	_test_deploy_real_meta_transactions()
	_test_map_open_progress_fact()
	if failures.is_empty():
		print("M7_META_UI_RUNTIME:PASS long_term=PASS deploy_refresh=PASS sale_confirm=PASS meta_transactions=PASS map_fact=PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("M7_META_UI_RUNTIME:%s" % failure)
		quit(1)


func _test_long_term_real_content() -> void:
	var adapter: MetaProgressAdapter = _adapter("user://tests/m7_meta_ui_long_term.json", "m7_meta_ui_long_term")
	adapter.data["gold"] = 500
	for item_id in ["mon_old_gear_set", "sp_altar_residue", "mon_loader_black_box"]:
		var item := M7ContentCatalogScript.item_definition(item_id)
		item["instance_id"] = "m7_ui_%s" % item_id
		adapter.data["warehouse_items"].append(item)
	_check(adapter.save(), "long_term_seed_save")
	var before: Dictionary = adapter.get_summary()
	var research_model: Dictionary = long_term_model_script.build_from_snapshot(&"research", {"meta_progress_summary": before})
	var groups: Dictionary = research_model.get("m7_cards_by_group", {})
	var research_cards: Array = groups.get("research/research_entry", [])
	_check(research_cards.size() == 3, "research_card_count")
	_check(not (research_cards[0] as Dictionary).get("action", {}).is_empty(), "research_action_missing")
	_check(bool(research_model.get("m7_real_module", false)), "research_still_preview_only")
	var shell_script := load("res://scripts/ui/long_term/long_term_shell.gd") as GDScript
	var shell := shell_script.new() as Control
	shell.size = Vector2(1280, 720)
	root.add_child(shell)
	var emitted_actions: Array[Dictionary] = []
	shell.connect("meta_action_requested", func(action: Dictionary) -> void: emitted_actions.append(action.duplicate(true)))
	shell.call("build")
	shell.call("apply_snapshot", {"meta_progress_summary": before})
	shell.call("_apply_module_immediately", &"research")
	shell.call("show_secondary", &"research_entry")
	var action_button := shell.get("content_action_button") as Button
	_check(action_button != null and action_button.visible and action_button.text.contains("研究"), "research_confirm_button_missing")
	action_button.emit_signal("pressed")
	_check(not emitted_actions.is_empty() and StringName(emitted_actions[0].get("action", &"")) == &"complete_research", "research_confirm_action_missing")
	shell.call("_apply_module_immediately", &"codex")
	shell.call("show_secondary", &"map")
	var next_button := shell.get("content_next_button") as Button
	_check(next_button != null and not next_button.visible, "codex_legacy_pagination_visible")
	var scrollable_cards: Array = shell.get("long_term_card_buttons")
	_check(scrollable_cards.size() == 8, "codex_scrollable_record_count")
	_check(not scrollable_cards.is_empty() and int((scrollable_cards[scrollable_cards.size() - 1] as Button).get_meta("card_index", -1)) == 7, "codex_last_record_unreachable")
	shell.free()
	_check(bool(adapter.complete_research("research_anomaly_structure").get("ok", false)), "research_complete_failed")
	var after: Dictionary = adapter.get_summary()
	_check((after.get("unread_codex_ids", []) as Array).has("monster:drone"), "research_codex_unread_missing")
	var codex_model: Dictionary = long_term_model_script.build_from_snapshot(&"codex", {"meta_progress_summary": after})
	var codex_groups: Dictionary = codex_model.get("m7_cards_by_group", {})
	_check((codex_groups.get("codex/map", []) as Array).size() == 8, "codex_map_count")
	_check((codex_groups.get("codex/monster", []) as Array).size() == 4, "codex_monster_count")
	_check((codex_groups.get("collection_appearance/display_content", []) as Array).size() == 3, "collection_set_count")
	var gacha_model: Dictionary = long_term_model_script.build_from_snapshot(&"gacha", {"meta_progress_summary": after})
	_check(not bool(gacha_model.get("m7_real_module", true)), "gacha_should_remain_locked")
	adapter.clear()


func _test_deploy_refresh_and_sale_confirmation() -> void:
	var adapter: MetaProgressAdapter = _adapter("user://tests/m7_meta_ui_deploy.json", "m7_meta_ui_deploy")
	adapter.data["gold"] = 500
	var collectible := M7ContentCatalogScript.item_definition("col_01")
	collectible["instance_id"] = "m7_ui_collectible"
	adapter.data["warehouse_items"].append(collectible)
	_check(adapter.save(), "deploy_seed_save")
	var snapshot := {"run_active": false, "meta_progress_summary": adapter.get_summary()}
	var model: Dictionary = deploy_prep_model_script.build(snapshot)
	var config: Dictionary = model.get("config", {})
	var map_result := DeployConfigScript.apply_card_action(config, &"map", &"m7_map_classic_10x10_standard")
	config = map_result.get("config", config)
	var candidates: Array = config.get("commission_candidates", [])
	if candidates.size() > 1:
		var commission_id := str((candidates[1] as Dictionary).get("id", ""))
		config = DeployConfigScript.apply_card_action(config, &"objective", StringName("m7_commission_%s" % commission_id)).get("config", config)
	var warehouse_items: Array = (config.get("warehouse_lite", {}) as Dictionary).get("groups", {}).get("equipment", [])
	if not warehouse_items.is_empty():
		var instance_id := str((warehouse_items[0] as Dictionary).get("instance_id", ""))
		config = DeployConfigScript.apply_card_action(config, &"warehouse", StringName("m3r_%s" % instance_id)).get("config", config)
	model = deploy_prep_model_script.model_with_config(model, config, &"", "")
	var selected_map := str(config.get("map_config_id", ""))
	var selected_commission := str(config.get("selected_objective_id", ""))
	var selected_equipment: Array = config.get("selected_equipment_ids", [])
	_check(bool(adapter.purchase_item("con_ration").get("ok", false)), "refresh_purchase_failed")
	model = deploy_prep_model_script.refresh_from_snapshot(model, {"run_active": false, "meta_progress_summary": adapter.get_summary()})
	var refreshed: Dictionary = model.get("config", {})
	_check(str(refreshed.get("map_config_id", "")) == selected_map, "refresh_lost_map")
	_check(str(refreshed.get("selected_objective_id", "")) == selected_commission, "refresh_lost_commission")
	_check((refreshed.get("selected_equipment_ids", []) as Array) == selected_equipment, "refresh_lost_loadout")
	var first_sale := DeployConfigScript.apply_card_action(refreshed, &"warehouse", &"m3r_m7_ui_collectible")
	_check(bool(first_sale.get("changed", false)) and first_sale.get("meta_action", {}).is_empty(), "sale_first_click_not_confirmation")
	var second_sale := DeployConfigScript.apply_card_action(first_sale.get("config", refreshed), &"warehouse", &"m3r_m7_ui_collectible")
	var action: Dictionary = second_sale.get("meta_action", {})
	_check(StringName(action.get("action", &"")) == &"sell_collectible", "sale_second_click_missing_action")
	adapter.clear()


func _test_deploy_real_meta_transactions() -> void:
	var adapter: MetaProgressAdapter = _adapter("user://tests/m7_meta_ui_transactions.json", "m7_meta_ui_transactions")
	adapter.data["gold"] = 500
	var collectible := M7ContentCatalogScript.item_definition("col_01")
	collectible["instance_id"] = "m7_ui_transaction_collectible"
	adapter.data["warehouse_items"].append(collectible)
	_check(adapter.save(), "meta_transaction_seed_save")
	var controller := RunRuntimeControllerScript.new()
	controller.bind_meta_progress_adapter(adapter)

	var model: Dictionary = deploy_prep_model_script.build({
		"run_active": false,
		"meta_progress_summary": adapter.get_summary(),
	})
	var config: Dictionary = model.get("config", {})
	config = DeployConfigScript.apply_card_action(config, &"map", &"m7_map_classic_10x10_standard").get("config", config)
	var candidates: Array = config.get("commission_candidates", [])
	if candidates.size() > 1:
		var commission_id := str((candidates[1] as Dictionary).get("id", ""))
		config = DeployConfigScript.apply_card_action(config, &"objective", StringName("m7_commission_%s" % commission_id)).get("config", config)
	var warehouse_groups: Dictionary = (config.get("warehouse_lite", {}) as Dictionary).get("groups", {})
	for group_id in ["equipment", "consumable"]:
		var items: Array = warehouse_groups.get(group_id, [])
		if items.is_empty():
			continue
		var instance_id := str((items[0] as Dictionary).get("instance_id", ""))
		config = DeployConfigScript.apply_card_action(config, &"warehouse", StringName("m3r_%s" % instance_id)).get("config", config)
	model = deploy_prep_model_script.model_with_config(model, config, &"", "")
	var draft_before := _deploy_draft_signature(config)
	_check(not (draft_before.get("selected_equipment_ids", []) as Array).is_empty(), "meta_transaction_draft_equipment_missing")
	_check(not (draft_before.get("selected_consumable_ids", []) as Array).is_empty(), "meta_transaction_draft_consumable_missing")

	var purchase_action := {
		"request_id": "m7_meta_purchase_1",
		"source_page": &"deploy_prep",
		"action": &"purchase",
		"item_id": "con_ration",
	}
	var purchase_before := _economy_state(adapter.get_summary())
	var purchase_result: Dictionary = controller.execute_meta_action(purchase_action)
	var purchase_after := _economy_state(adapter.get_summary())
	var purchase_payload: Dictionary = purchase_result.get("result", {})
	var purchased_item: Dictionary = purchase_payload.get("item", {})
	var purchased_instance_id := str(purchased_item.get("instance_id", ""))
	var purchase_price := int(M7ContentCatalogScript.shop_definition("con_ration").get("price", -1))
	var expected_purchase_ids: Array[String] = _instance_ids(purchase_before.get("warehouse_items", []))
	expected_purchase_ids.append(purchased_instance_id)
	expected_purchase_ids.sort()
	_check(bool(purchase_result.get("ok", false)) and StringName(purchase_result.get("status", &"")) == &"purchased", "meta_purchase_not_completed")
	_check(purchase_price >= 0 and int(purchase_after.get("gold", -1)) == int(purchase_before.get("gold", 0)) - purchase_price, "meta_purchase_gold_delta")
	_check(not purchased_instance_id.is_empty() and str(purchased_item.get("item_id", "")) == "con_ration", "meta_purchase_instance_missing")
	_check(_instance_ids(purchase_after.get("warehouse_items", [])) == expected_purchase_ids, "meta_purchase_inventory_delta")
	_check(_economy_state(purchase_result.get("meta_progress_summary", {})) == purchase_after, "meta_purchase_envelope_not_authoritative")
	model = deploy_prep_model_script.refresh_from_snapshot(model, {"run_active": false, "meta_progress_summary": adapter.get_summary()})
	_check(_deploy_draft_signature(model.get("config", {})) == draft_before, "meta_purchase_refresh_lost_draft")

	var duplicate_result: Dictionary = controller.execute_meta_action(purchase_action)
	_check(bool(duplicate_result.get("ok", false)) and bool(duplicate_result.get("duplicate", false)), "meta_purchase_duplicate_not_cached")
	_check(str((duplicate_result.get("result", {}) as Dictionary).get("item", {}).get("instance_id", "")) == purchased_instance_id, "meta_purchase_duplicate_result_changed")
	_check(_economy_state(adapter.get_summary()) == purchase_after, "meta_purchase_duplicate_mutated_economy")

	var locked_before := _economy_state(adapter.get_summary())
	var locked_result: Dictionary = controller.execute_meta_action({
		"request_id": "m7_meta_purchase_locked",
		"source_page": &"deploy_prep",
		"action": &"purchase",
		"item_id": "eq_goggles",
	})
	_check(not bool(locked_result.get("ok", true)) and StringName(locked_result.get("status", &"")) == &"locked", "meta_purchase_locked_status")
	_check(_economy_state(adapter.get_summary()) == locked_before, "meta_purchase_failure_mutated_economy")

	var blocked_sale_before := _economy_state(adapter.get_summary())
	var blocked_sale_result: Dictionary = controller.execute_meta_action({
		"request_id": "m7_meta_sale_blocked",
		"source_page": &"deploy_prep",
		"action": &"sell_collectible",
		"instance_id": "m7_ui_transaction_collectible",
		"blocked_instance_ids": ["m7_ui_transaction_collectible"],
	})
	_check(not bool(blocked_sale_result.get("ok", true)) and StringName(blocked_sale_result.get("status", &"")) == &"configured_item_blocked", "meta_sale_blocked_status")
	_check(_economy_state(adapter.get_summary()) == blocked_sale_before, "meta_sale_failure_mutated_economy")

	var sale_action := {
		"request_id": "m7_meta_sale_1",
		"source_page": &"deploy_prep",
		"action": &"sell_collectible",
		"instance_id": "m7_ui_transaction_collectible",
	}
	var sale_before := _economy_state(adapter.get_summary())
	var sale_result: Dictionary = controller.execute_meta_action(sale_action)
	var sale_after := _economy_state(adapter.get_summary())
	var sale_value := int(collectible.get("base_value", -1))
	var expected_sale_ids := _instance_ids(sale_before.get("warehouse_items", []))
	expected_sale_ids.erase("m7_ui_transaction_collectible")
	_check(bool(sale_result.get("ok", false)) and StringName(sale_result.get("status", &"")) == &"sold", "meta_sale_not_completed")
	_check(sale_value >= 0 and int(sale_after.get("gold", -1)) == int(sale_before.get("gold", 0)) + sale_value, "meta_sale_gold_delta")
	_check(int((sale_result.get("result", {}) as Dictionary).get("gold_gained", -1)) == sale_value, "meta_sale_reported_value")
	_check(_instance_ids(sale_after.get("warehouse_items", [])) == expected_sale_ids, "meta_sale_inventory_delta")
	_check(_economy_state(sale_result.get("meta_progress_summary", {})) == sale_after, "meta_sale_envelope_not_authoritative")
	model = deploy_prep_model_script.refresh_from_snapshot(model, {"run_active": false, "meta_progress_summary": adapter.get_summary()})
	_check(_deploy_draft_signature(model.get("config", {})) == draft_before, "meta_sale_refresh_lost_draft")

	var duplicate_sale_result: Dictionary = controller.execute_meta_action(sale_action)
	_check(bool(duplicate_sale_result.get("ok", false)) and bool(duplicate_sale_result.get("duplicate", false)), "meta_sale_duplicate_not_cached")
	_check(_economy_state(adapter.get_summary()) == sale_after, "meta_sale_duplicate_mutated_economy")
	controller.bind_meta_progress_adapter(null)
	controller.in_run_runtime.bind(null)
	controller.command_bus.bind_runtime_controller(null)
	var terminal_callback := Callable(controller, "_on_terminal_result_available")
	if controller.command_bus.result_available.is_connected(terminal_callback):
		controller.command_bus.result_available.disconnect(terminal_callback)
	adapter.clear()


func _test_map_open_progress_fact() -> void:
	var context := RunContextScript.new()
	context.start_run(M7ContentCatalogScript.map_runtime_config("classic_7x7_simple", 71, {"map_config_id": "classic_7x7_simple"}))
	var bus := CommandBusScript.new()
	bus.bind_context(context)
	_check(int(context.run_stats.get("map_open_count", 0)) == 0, "map_open_count_not_zero")
	bus.dispatch(&"open_map")
	_check(int(context.run_stats.get("map_open_count", 0)) == 1, "map_open_not_recorded")


func _adapter(path: String, profile_id: String) -> MetaProgressAdapter:
	var adapter := MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(path, profile_id)
	adapter.clear()
	adapter.load_or_create_default()
	return adapter


func _economy_state(summary: Dictionary) -> Dictionary:
	return {
		"gold": int(summary.get("gold", 0)),
		"warehouse_items": (summary.get("warehouse_items", []) as Array).duplicate(true),
	}


func _instance_ids(raw_items: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_items is Array:
		for raw_item in raw_items as Array:
			if raw_item is Dictionary:
				result.append(str((raw_item as Dictionary).get("instance_id", "")))
	result.sort()
	return result


func _deploy_draft_signature(config: Dictionary) -> Dictionary:
	return {
		"map_config_id": str(config.get("map_config_id", "")),
		"selected_objective_id": str(config.get("selected_objective_id", "")),
		"selected_equipment_ids": _sorted_strings(config.get("selected_equipment_ids", [])),
		"selected_consumable_ids": _sorted_strings(config.get("selected_consumable_ids", [])),
	}


func _sorted_strings(raw_values: Variant) -> Array[String]:
	var result: Array[String] = []
	if raw_values is Array:
		for raw_value in raw_values as Array:
			result.append(str(raw_value))
	result.sort()
	return result


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
