extends RefCounted
class_name DebugScenarioCatalog

const DEFAULT_SCENARIO_ID := &"demo_7x7"

const SCENARIOS := [
	{
		"id": &"demo_7x7",
		"label": "基础房型与移动",
		"seed": 1001,
		"coverage": [&"room_types", &"movement", &"search"],
		"setup_commands": [],
	},
	{
		"id": &"combat_room",
		"label": "固定战斗房",
		"seed": 1101,
		"coverage": [&"combat", &"terminal_failure"],
		"setup_commands": [
			{"command": &"debug_find_room", "payload": {"room_type": &"Monster"}},
		],
	},
	{
		"id": &"full_backpack",
		"label": "满背包替换",
		"seed": 1201,
		"coverage": [&"full_backpack", &"replace_item", &"exact_instance"],
		"setup_commands": [
			{"command": &"debug_spawn_test_item_backpack", "repeat": 10},
			{"command": &"debug_spawn_test_item_floor", "repeat": 1},
		],
	},
	{
		"id": &"duplicate_items",
		"label": "重复物品聚合",
		"seed": 1301,
		"coverage": [&"duplicate_items", &"aggregation", &"single_instance_use"],
		"setup_commands": [
			{"command": &"debug_spawn_test_item_backpack", "repeat": 3},
		],
	},
	{
		"id": &"terminal_success_failure",
		"label": "成功与失败终局",
		"seed": 1401,
		"coverage": [&"extract", &"failure", &"settlement"],
		"setup_commands": [
			{"command": &"debug_teleport_to_exit", "repeat": 1},
		],
	},
	{
		"id": &"persistence_failure",
		"label": "保存失败回滚",
		"seed": 1501,
		"coverage": [&"save_failure", &"rollback", &"failure_bundle"],
		"setup_commands": [],
		"requires_failure_injection": true,
	},
]


static func all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_scenario in SCENARIOS:
		result.append((raw_scenario as Dictionary).duplicate(true))
	return result


static func find(scenario_id: StringName) -> Dictionary:
	for raw_scenario in SCENARIOS:
		var scenario := raw_scenario as Dictionary
		if StringName(scenario.get("id", &"")) == scenario_id:
			return scenario.duplicate(true)
	return {}


static func normalize_id(scenario_id: StringName) -> StringName:
	return scenario_id if not find(scenario_id).is_empty() else DEFAULT_SCENARIO_ID


static func seed_for(scenario_id: StringName, requested_seed: int = 0) -> int:
	if requested_seed != 0:
		return requested_seed
	var scenario := find(normalize_id(scenario_id))
	return int(scenario.get("seed", 1001))


static func coverage_report() -> Dictionary:
	var coverage := {}
	for scenario in all():
		for raw_key in scenario.get("coverage", []) as Array:
			coverage[StringName(raw_key)] = true
	return {
		"ok": (
			coverage.has(&"room_types")
			and coverage.has(&"combat")
			and coverage.has(&"full_backpack")
			and coverage.has(&"duplicate_items")
			and coverage.has(&"settlement")
			and coverage.has(&"save_failure")
		),
		"scenario_count": SCENARIOS.size(),
		"coverage": coverage,
	}
