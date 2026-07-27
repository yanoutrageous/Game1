extends RefCounted
class_name RunConfig

const M3RItemUsabilityModelScript := preload("res://scripts/core/content/m3r_item_usability_model.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const TutorialMapCatalogScript := preload("res://scripts/core/run/tutorial_map_catalog.gd")


static func tutorial_5x5(run_start_config: Dictionary = {}) -> Dictionary:
	return TutorialMapCatalogScript.runtime_config(run_start_config)


static func standard_10x10(run_start_config: Dictionary = {}) -> Dictionary:
	var config := {
		"id": &"standard_10x10",
		"mode": &"standard",
		"width": 10,
		"height": 10,
		"seed": 1001,
		"mine_count": 20,
		"event_room_count": 10,
		"monster_room_count": 10,
		"chest_room_count": 10,
		"random_exit_count": 2,
		"spawn_safe_radius": 0,
		"path_width": 0,
		"mine_hits_are_fatal": false,
		"reveal_on_move": true,
		"move_requires_revealed": false,
		"backpack_capacity": 10,
		"failure_salvage_capacity": 4,
		"black_to_gold_rate": 1.0,
		"rule_modifiers": [
			RunModifierSpec.make(
				"m2_standard_search_black_coin_bonus",
				"standard_10x10_m2_minimum_loop",
				50,
				&"reward",
				&"search_reward",
				&"add_black_coin",
				1,
				{"scope": &"run"},
				&"stack",
				[&"m2_minimum_loop"],
				"M2 limited real modifier: search reward black_coin +1."
			),
		],
	}
	if not run_start_config.is_empty():
		var patch := M3RItemUsabilityModelScript.runtime_config_patch(run_start_config)
		for key in patch.keys():
			config[key] = patch[key]
	return config

static func m7_map(run_start_config: Dictionary = {}) -> Dictionary:
	var map_id := str(run_start_config.get("map_config_id", "classic_10x10_standard"))
	if map_id == "tutorial_5x5":
		return tutorial_5x5(run_start_config)
	var seed_value := int(run_start_config.get("seed_value", 0))
	if seed_value == 0:
		seed_value = absi(int(Time.get_unix_time_from_system()) * 1009 + int(Time.get_ticks_msec()) * 9176)
	var config := M7ContentCatalogScript.map_runtime_config(map_id, seed_value, run_start_config)
	if map_id == "classic_10x10_standard":
		config["rule_modifiers"] = [
			RunModifierSpec.make(
				"m2_standard_search_black_coin_bonus",
				"standard_10x10_m2_minimum_loop",
				50,
				&"reward",
				&"search_reward",
				&"add_black_coin",
				1,
				{"scope": &"run"},
				&"stack",
				[&"m2_minimum_loop"],
				"M2 limited real modifier: search reward black_coin +1."
			),
		]
	var patch := M3RItemUsabilityModelScript.runtime_config_patch(run_start_config)
	for key in patch.keys():
		config[key] = patch[key]
	return config
