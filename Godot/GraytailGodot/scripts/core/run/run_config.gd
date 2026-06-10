extends RefCounted
class_name RunConfig


static func tutorial_5x5() -> Dictionary:
	return {
		"id": &"tutorial_5x5",
		"mode": &"tutorial",
		"width": 5,
		"height": 5,
		"seed": 777,
		"mine_count": 4,
		"event_room_count": 4,
		"monster_room_count": 5,
		"chest_room_count": 4,
		"random_exit_count": 0,
		"mine_hits_are_fatal": false,
		"reveal_on_move": true,
		"move_requires_revealed": false,
		"backpack_capacity": 10,
		"failure_salvage_capacity": 1,
		"black_to_gold_rate": 1.0,
		"use_loadout": false,
		"apply_meta_progress": false,
		"allow_warehouse_rewards": false,
		"allow_failure_rewards": false,
		"manual_map": _tutorial_manual_map(),
		"tutorial_triggers": _tutorial_triggers(),
	}


static func standard_10x10() -> Dictionary:
	return {
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
		"failure_salvage_capacity": 1,
		"black_to_gold_rate": 1.0,
	}


static func _tutorial_manual_map() -> Dictionary:
	return {
		"spawn": Vector2i(0, 0),
		"mines": [Vector2i(0, 2), Vector2i(1, 1), Vector2i(2, 0), Vector2i(3, 3)],
		"events": [Vector2i(0, 3), Vector2i(1, 2), Vector2i(2, 1), Vector2i(3, 0)],
		"monsters": [Vector2i(0, 4), Vector2i(1, 3), Vector2i(2, 2), Vector2i(3, 1), Vector2i(4, 0)],
		"chests": [Vector2i(1, 4), Vector2i(2, 3), Vector2i(3, 2), Vector2i(4, 1)],
		"exits": [{"pos": Vector2i(4, 4), "exit_id": &"tutorial_exit", "random_exit": false}],
	}


static func _tutorial_triggers() -> Dictionary:
	return {
		"0,0": &"spawn_intro",
		"0,1": &"number_rule",
		"1,0": &"number_rule",
		"0,2": &"mine_rule",
		"1,1": &"mine_rule",
		"2,0": &"mine_rule",
		"0,3": &"event_rule",
		"1,2": &"event_rule",
		"2,1": &"event_rule",
		"3,0": &"event_rule",
		"0,4": &"monster_rule",
		"1,3": &"monster_rule",
		"2,2": &"monster_rule",
		"3,1": &"monster_rule",
		"4,0": &"monster_rule",
		"1,4": &"chest_rule",
		"2,3": &"chest_rule",
		"3,2": &"chest_rule",
		"4,1": &"chest_rule",
		"2,4": &"map_rule",
		"4,2": &"map_rule",
		"3,3": &"mine_review",
		"3,4": &"route_rule",
		"4,3": &"route_rule",
		"4,4": &"exit_goal",
	}
