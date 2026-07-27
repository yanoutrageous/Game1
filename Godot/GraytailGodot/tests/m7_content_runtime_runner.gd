extends SceneTree

const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const TruthMapScript := preload("res://scripts/core/map/truth_map.gd")
const IntelMapScript := preload("res://scripts/core/intel/intel_map.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")

var failures: Array[String] = []


func _initialize() -> void:
	_test_map_matrix()
	_test_meta_transactions_and_progression()
	if failures.is_empty():
		print("M7_CONTENT_RUNTIME:PASS maps=9 seeds_per_map=100 tutorial=fixed_5x5 transactions=PASS progression=PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("M7_CONTENT_RUNTIME:%s" % failure)
		quit(1)


func _test_map_matrix() -> void:
	var maps := M7ContentCatalogScript.map_definitions()
	_check(maps.size() == 9, "map_count_expected_9")
	for definition in maps:
		var map_id := str(definition.get("id", ""))
		for seed_value in range(1, 101):
			var config := M7ContentCatalogScript.map_runtime_config(map_id, seed_value, {"map_config_id": map_id})
			var truth := TruthMapScript.new()
			truth.setup_from_config(config)
			var final_snapshot: Dictionary = truth.build_final_map_snapshot()
			var counts: Dictionary = final_snapshot.get("room_counts", {})
			_check(bool(truth.validate_map().get("valid", false)), "%s_seed_%d_invalid" % [map_id, seed_value])
			_check(truth.width == int(definition.get("width", 0)) and truth.height == int(definition.get("height", 0)), "%s_seed_%d_dimensions" % [map_id, seed_value])
			_check(int(counts.get("mine", -1)) == int(definition.get("mine_count", 0)), "%s_seed_%d_mines" % [map_id, seed_value])
			_check(int(counts.get("event", -1)) == int(definition.get("event_room_count", definition.get("content_room_count", 0))), "%s_seed_%d_events" % [map_id, seed_value])
			_check(int(counts.get("chest", -1)) == int(definition.get("chest_room_count", definition.get("content_room_count", 0))), "%s_seed_%d_chests" % [map_id, seed_value])
			_check(int(counts.get("monster", -1)) == int(definition.get("monster_room_count", definition.get("content_room_count", 0))), "%s_seed_%d_monsters" % [map_id, seed_value])
			var exit_count := int(definition.get("visible_exit_count", 0)) + int(definition.get("hidden_exit_count", 0))
			_check(int(counts.get("exit", -1)) == exit_count, "%s_seed_%d_exits" % [map_id, seed_value])
			var duplicate_truth := TruthMapScript.new()
			duplicate_truth.setup_from_config(config)
			_check(_room_signature(truth) == _room_signature(duplicate_truth), "%s_seed_%d_not_deterministic" % [map_id, seed_value])
			if bool(definition.get("visible_exit_position_known", false)):
				var intel := IntelMapScript.new()
				intel.setup(truth.width, truth.height)
				for pos in truth.get_visible_exits(null):
					intel.register_visible_exit(pos, truth.get_exit_id(pos))
					var public_detail := intel.get_public_room_detail(pos, truth)
					_check(StringName(public_detail.get("room_type", &"Unknown")) == &"Exit", "%s_seed_%d_visible_exit_hidden" % [map_id, seed_value])
					_check(not bool(public_detail.get("explored", false)), "%s_seed_%d_visible_exit_auto_explored" % [map_id, seed_value])


func _test_meta_transactions_and_progression() -> void:
	var save_path := "user://tests/m7_content_runtime_meta.json"
	var adapter := MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(save_path, "m7_runtime_test")
	adapter.clear()
	adapter.data["gold"] = 500
	_check(adapter.save(), "seed_save_failed")

	var purchase := adapter.purchase_item("con_ration")
	_check(bool(purchase.get("ok", false)), "purchase_failed")
	var purchased_item: Dictionary = purchase.get("item", {})
	_check(int(adapter.get_summary().get("gold", -1)) == 488, "purchase_gold_wrong")
	_check(str(purchased_item.get("instance_id", "")) != "", "purchase_instance_missing")

	var collectible := M7ContentCatalogScript.item_definition("col_01")
	collectible["instance_id"] = "m7_test_collectible"
	adapter.data["warehouse_items"].append(collectible)
	adapter.save()
	var blocked_sale := adapter.sell_collectible("m7_test_collectible", ["m7_test_collectible"])
	_check(not bool(blocked_sale.get("ok", false)), "configured_sale_not_blocked")
	var sale := adapter.sell_collectible("m7_test_collectible")
	_check(bool(sale.get("ok", false)) and int(sale.get("gold_gained", 0)) == 13, "collectible_sale_failed")

	for item_id in ["mon_old_gear_set", "sp_altar_residue", "mon_loader_black_box"]:
		var item := M7ContentCatalogScript.item_definition(item_id)
		item["instance_id"] = "m7_test_%s" % item_id
		adapter.data["warehouse_items"].append(item)
	adapter.data["gold"] = 500
	adapter.save()
	_check(bool(adapter.complete_research("research_anomaly_structure").get("ok", false)), "research_1_failed")
	_check(bool(adapter.complete_research("research_protocol_formula").get("ok", false)), "research_2_failed")
	_check(bool(adapter.complete_research("research_extraction_signal").get("ok", false)), "research_3_failed")
	_check((adapter.get_summary().get("unlocked_map_ids", []) as Array).has("classic_13x13_normal"), "research_map_unlock_missing")

	var result := _success_result("m7_result_standard", "classic_10x10_standard", "commission_recover_supply", 3, 1)
	var commit := adapter.apply_settlement(result)
	_check(bool(commit.get("ok", false)) and str(commit.get("status", "")) == "committed", "standard_commit_failed")
	var after_standard := adapter.get_summary()
	_check((after_standard.get("unlocked_map_ids", []) as Array).has("classic_10x10_hard"), "hard_10_unlock_missing")
	_check(str(((after_standard.get("achievement_states", {}) as Dictionary).get("achievement_critical_return", {}) as Dictionary).get("status", "")) == "claimable", "critical_achievement_missing")
	var duplicate := adapter.apply_settlement(result)
	_check(str(duplicate.get("status", "")) == "duplicate_ignored", "settlement_not_idempotent")
	var claim := adapter.claim_goal_reward("achievement", "achievement_critical_return")
	_check(bool(claim.get("ok", false)) and str(claim.get("status", "")) == "claimed", "achievement_claim_failed")
	_check(str(adapter.claim_goal_reward("achievement", "achievement_critical_return").get("status", "")) == "duplicate_ignored", "achievement_claim_not_idempotent")

	adapter.apply_settlement(_success_result("m7_result_13_normal", "classic_13x13_normal", "commission_open_crates", 4, 3))
	_check((adapter.get_summary().get("unlocked_map_ids", []) as Array).has("classic_13x13_hard"), "hard_13_unlock_missing")
	adapter.apply_settlement(_success_result("m7_result_13_hard", "classic_13x13_hard", "commission_open_crates", 4, 3))
	_check((adapter.get_summary().get("unlocked_map_ids", []) as Array).has("classic_13x13_hell"), "hell_13_unlock_missing")

	var before_pending := adapter.get_summary()
	var pending_failure := {
		"result_id": "m7_pending_failure",
		"mode": "standard",
		"outcome": "Failed",
		"settlement": {"outcome": "failure", "requires_salvage_selection": true, "finalized": false},
	}
	var pending_commit := adapter.apply_settlement(pending_failure)
	_check(str(pending_commit.get("status", "")) == "awaiting_salvage_selection", "pending_failure_not_blocked")
	_check(int(adapter.get_summary().get("run_count", -1)) == int(before_pending.get("run_count", -2)), "pending_failure_mutated_meta")

	var absolute_path := ProjectSettings.globalize_path(save_path)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(absolute_path)


func _success_result(result_id: String, map_id: String, commission_id: String, chest_count: int, protocol_level: int) -> Dictionary:
	var map_def := M7ContentCatalogScript.map_definition(map_id)
	var recovered := []
	for index in range(2):
		var item := M7ContentCatalogScript.item_definition("col_%02d" % [index + 1])
		item["instance_id"] = "%s:item:%d" % [result_id, index]
		recovered.append(item)
	return {
		"result_id": result_id,
		"run_id": result_id,
		"mode": "standard",
		"outcome": "Extracted",
		"hp": 8,
		"protocol_level": protocol_level,
		"unique_rooms_explored": 16,
		"run_start_config": {
			"map_config_id": map_id,
			"map_display_name": map_def.get("display_name", map_id),
			"difficulty": map_def.get("difficulty", &"normal"),
			"difficulty_label": map_def.get("difficulty_label", "普通"),
			"selected_objective_id": commission_id,
			"selected_objective_label": M7ContentCatalogScript.commission_definition(commission_id).get("display_name", commission_id),
			"selected_equipment_items": [],
			"selected_consumable_items": [],
		},
		"run_stats": {
			"mine_hits": 0,
			"chest_rooms": chest_count,
			"monsters_defeated": 4,
			"events_completed": 2,
			"events_trader": 1,
			"events_dice": 1,
			"events_altar": 1,
			"events_trap": 1,
			"map_open_count": 1,
			"flags_placed": 1,
		},
		"run_events": [
			{"event_type": &"item_picked_up", "sequence": 1, "payload": {}},
			{"event_type": &"combat_resolved", "sequence": 2, "payload": {"monster_type": &"slime"}},
			{"event_type": &"event_option_selected", "sequence": 3, "payload": {"event_type": &"trader"}},
		],
		"settlement": {"outcome": "success", "finalized": true, "warehouse_lite": recovered, "gold_coin_gained": 0},
		"warehouse_lite": recovered,
	}


func _room_signature(truth) -> String:
	var parts: Array[String] = []
	for y in range(truth.height):
		for x in range(truth.width):
			var pos := Vector2i(x, y)
			parts.append("%d,%d:%s:%s" % [x, y, str(truth.get_room_type(pos)), str(truth.get_exit_id(pos))])
	return "|".join(parts)


func _check(condition: bool, message: String) -> void:
	if not condition and not failures.has(message):
		failures.append(message)
