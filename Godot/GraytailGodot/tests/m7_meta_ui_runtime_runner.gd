extends SceneTree

const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
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
	_test_map_open_progress_fact()
	if failures.is_empty():
		print("M7_META_UI_RUNTIME:PASS long_term=PASS deploy_refresh=PASS sale_confirm=PASS map_fact=PASS")
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
	_check(next_button != null and next_button.visible and not next_button.disabled, "codex_pagination_missing")
	next_button.emit_signal("pressed")
	var paged_cards: Array = shell.get("long_term_card_buttons")
	_check(not paged_cards.is_empty() and int((paged_cards[0] as Button).get_meta("card_index", -1)) == 3, "codex_second_page_unreachable")
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


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
