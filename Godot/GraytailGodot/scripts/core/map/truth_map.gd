extends RefCounted
class_name TruthMap

# TruthMap owns real map truth. UI must read IntelMap/ViewModels only.

const RoomCommonRuleSchemaScript := preload("res://scripts/core/run/encounter/room_encounter_common_rule_schema.gd")

const MAP_KIND_CLASSIC_RECT := &"classic_rect_minesweeper"
const ROOM_SPAWN := &"Spawn"
const ROOM_NORMAL := &"Normal"
const ROOM_MINE := &"Mine"
const ROOM_MONSTER := &"Monster"
const ROOM_CHEST := &"Chest"
const ROOM_EVENT := &"Event"
const ROOM_EXIT := &"Exit"
const ROOM_BOSS := &"Boss"
const ROOM_SPECIAL_RULE := &"SpecialRule"
const ROOM_UNKNOWN := &"Unknown"
const ROOM_STATE_UNKNOWN := &"unknown"
const ROOM_STATE_SCANNED := &"scanned"
const ROOM_STATE_EXPLORED := &"explored"
const ROOM_STATE_CLEARED := &"cleared"
const RETURN_OK := &"eligible"
const RETURN_BLOCKED_UNKNOWN := &"room_unknown"
const RETURN_BLOCKED_SCANNED_ONLY := &"room_scanned_only"
const RETURN_BLOCKED_LOCKED := &"run_state_locked"
const RETURN_BLOCKED_OUTSIDE := &"outside_map"

var rooms: Dictionary = {}
var width: int = 0
var height: int = 0
var spawn_pos: Vector2i = Vector2i.ZERO
var exits: Array[Vector2i] = []
var map_profile: Dictionary = {}
var generation_log: Array[Dictionary] = []
var mutation_log: Array[Dictionary] = []


func clear() -> void:
	rooms.clear()
	width = 0
	height = 0
	spawn_pos = Vector2i.ZERO
	exits.clear()
	map_profile.clear()
	generation_log.clear()
	mutation_log.clear()


func setup_from_config(config: Dictionary) -> void:
	map_profile = default_map_gen_profile(config)
	if config.has("manual_map"):
		setup_manual_map(config)
	else:
		setup_standard_map(config)


func setup_manual_map(config: Dictionary) -> void:
	clear()
	map_profile = default_map_gen_profile(config)
	width = int(config.get("width", 5))
	height = int(config.get("height", 5))
	_build_empty_grid()
	_append_generation_log(&"manual_grid_initialized", {"width": width, "height": height})
	var manual_map: Dictionary = config.get("manual_map", {})
	spawn_pos = manual_map.get("spawn", Vector2i.ZERO)
	_set_cell(spawn_pos, {"spawn": true, "room_type": ROOM_NORMAL})
	for pos in manual_map.get("mines", []):
		_set_cell(pos, {"mine": true, "room_type": ROOM_MINE})
	for pos in manual_map.get("events", []):
		_set_cell(pos, {"room_type": ROOM_EVENT})
	for pos in manual_map.get("monsters", []):
		_set_cell(pos, {"room_type": ROOM_MONSTER})
	for pos in manual_map.get("chests", []):
		_set_cell(pos, {"room_type": ROOM_CHEST})
	for exit_def in manual_map.get("exits", []):
		var pos: Vector2i = exit_def.get("pos", Vector2i.ZERO)
		_set_cell(pos, {
			"room_type": ROOM_EXIT,
			"exit_id": StringName(exit_def.get("exit_id", &"tutorial_exit")),
			"random_exit": bool(exit_def.get("random_exit", false)),
		})
		exits.append(pos)
	_compute_adjacency()
	_refresh_room_contracts()
	_append_generation_log(&"manual_map_loaded", {"room_counts": _room_counts(), "validation": validate_map()})


func setup_standard_map(config: Dictionary) -> void:
	clear()
	map_profile = default_map_gen_profile(config)
	width = int(config.get("width", 10))
	height = int(config.get("height", 10))
	_build_empty_grid()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.get("seed", 1001))
	_append_generation_log(&"standard_grid_initialized", {"width": width, "height": height, "seed": rng.seed})
	spawn_pos = _take_random_candidate(_all_positions(), rng)
	_set_cell(spawn_pos, {"spawn": true, "room_type": ROOM_NORMAL, "reserved": true})
	_place_rooms(ROOM_MINE, int(config.get("mine_count", 20)), rng)
	_place_rooms(ROOM_MONSTER, int(config.get("monster_room_count", 10)), rng)
	_place_rooms(ROOM_CHEST, int(config.get("chest_room_count", 10)), rng)
	_place_rooms(ROOM_EVENT, int(config.get("event_room_count", 10)), rng)
	for i in range(int(config.get("visible_exit_count", 0))):
		var pos := _take_random_candidate(_safe_normal_candidates(), rng)
		_set_cell(pos, {"room_type": ROOM_EXIT, "exit_id": StringName("visible_%d" % [i + 1]), "random_exit": false})
		exits.append(pos)
	for i in range(int(config.get("random_exit_count", 2))):
		var pos := _take_random_candidate(_safe_normal_candidates(), rng)
		_set_cell(pos, {"room_type": ROOM_EXIT, "exit_id": StringName("random_%d" % [i + 1]), "random_exit": true})
		exits.append(pos)
	_compute_adjacency()
	_refresh_room_contracts()
	_append_generation_log(&"standard_map_generated", {"room_counts": _room_counts(), "validation": validate_map()})


func setup_demo_map() -> void:
	setup_from_config({
		"width": 7,
		"height": 7,
		"manual_map": {
			"spawn": Vector2i(3, 3),
			"mines": [Vector2i(2, 2), Vector2i(4, 2), Vector2i(5, 5)],
			"events": [Vector2i(5, 1)],
			"monsters": [Vector2i(1, 5)],
			"chests": [Vector2i(1, 1)],
			"exits": [{"pos": Vector2i(6, 6), "exit_id": &"demo_exit", "random_exit": false}],
		},
	})


func get_cell(pos: Vector2i) -> Dictionary:
	return rooms.get(_key(pos), {}).duplicate(true)


func get_room_type(pos: Vector2i) -> StringName:
	return StringName(rooms.get(_key(pos), {}).get("room_type", &"Unknown"))


func set_room_type(pos: Vector2i, room_type: StringName) -> void:
	_set_cell(pos, {"room_type": room_type, "mine": room_type == ROOM_MINE})
	_compute_adjacency()
	_apply_room_contract(pos)
	_append_mutation_log(&"room_type_changed", pos, {"room_type": room_type, "preview_only": true})


func is_mine(pos: Vector2i) -> bool:
	return bool(rooms.get(_key(pos), {}).get("mine", false))


func get_adjacent_mine_count(pos: Vector2i) -> int:
	return int(rooms.get(_key(pos), {}).get("adjacent_mines", 0))


func get_exits() -> Array[Vector2i]:
	return exits.duplicate()


func get_visible_exits(intel_map: IntelMap) -> Array[Vector2i]:
	var visible: Array[Vector2i] = []
	for pos in exits:
		var cell := get_cell(pos)
		if not bool(cell.get("random_exit", false)):
			visible.append(pos)
		elif intel_map != null and intel_map.is_revealed(pos):
			visible.append(pos)
	return visible


func get_exit_id(pos: Vector2i) -> StringName:
	return StringName(rooms.get(_key(pos), {}).get("exit_id", &""))


func is_random_exit(pos: Vector2i) -> bool:
	return bool(rooms.get(_key(pos), {}).get("random_exit", false))


func mark_explored(pos: Vector2i) -> void:
	_set_cell(pos, {"explored": true})
	_append_mutation_log(&"room_explored", pos, {"state": ROOM_STATE_EXPLORED})


func mark_cleared(pos: Vector2i) -> void:
	_set_cell(pos, {"cleared": true})
	_append_mutation_log(&"room_cleared", pos, {"state": ROOM_STATE_CLEARED})


func mark_triggered(pos: Vector2i) -> void:
	_set_cell(pos, {"triggered": true})
	_append_mutation_log(&"room_triggered", pos, {"triggered": true})


func is_triggered(pos: Vector2i) -> bool:
	return bool(rooms.get(_key(pos), {}).get("triggered", false))


func is_cleared(pos: Vector2i) -> bool:
	return bool(rooms.get(_key(pos), {}).get("cleared", false))


func count_room_type(room_type: StringName) -> int:
	var count := 0
	for cell in rooms.values():
		if StringName(cell.get("room_type", &"Normal")) == room_type:
			count += 1
	return count


func is_inside(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height


static func default_map_gen_profile(config: Dictionary = {}) -> Dictionary:
	return {
		"schema_kind": &"MapGenProfile",
		"map_kind": MAP_KIND_CLASSIC_RECT,
		"future_map_interfaces": [&"hex", &"multi_layer", &"special_rules"],
		"seed": int(config.get("seed", 1001)),
		"width": int(config.get("width", 10)),
		"height": int(config.get("height", 10)),
		"generation_mode": &"manual" if config.has("manual_map") else &"seeded_profile",
		"constraints": {
			"single_base_room_type": true,
			"classic_rect_8_neighbors": true,
			"spawn_not_mine": true,
			"exit_room_type_exclusive": true,
		},
		"modifiers": _array_from_variant(config.get("map_modifiers", [])),
		"validation_policy": {
			"validate_dimensions": true,
			"validate_spawn_inside": true,
			"validate_exit_inside": true,
			"repair_or_retry_preview": true,
		},
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


func validate_map() -> Dictionary:
	var warnings: Array[String] = []
	if width <= 0 or height <= 0:
		warnings.append("invalid_dimensions")
	if not is_inside(spawn_pos):
		warnings.append("spawn_outside_map")
	elif is_mine(spawn_pos):
		warnings.append("spawn_is_mine")
	for exit_pos in exits:
		if not is_inside(exit_pos):
			warnings.append("exit_outside_map:%s" % _key(exit_pos))
	var has_spawn := is_inside(spawn_pos)
	return {
		"schema_kind": &"MapGenerationValidation",
		"valid": warnings.is_empty() and has_spawn,
		"warnings": warnings,
		"repair_policy": &"record_only_no_runtime_repair",
		"retry_policy": &"future_generator_hook",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


func build_final_map_snapshot() -> Dictionary:
	return {
		"schema_kind": &"FinalMapSnapshot",
		"map_kind": MAP_KIND_CLASSIC_RECT,
		"profile": map_profile.duplicate(true),
		"width": width,
		"height": height,
		"spawn_pos": spawn_pos,
		"exits": _position_array(exits),
		"room_counts": _room_counts(),
		"validation": validate_map(),
		"generation_log": generation_log.duplicate(true),
		"rooms": _truth_room_summaries(),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


func build_run_map_snapshot(intel_map: IntelMap = null, player_pos: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var known_snapshot := intel_map.build_known_map_snapshot(self, player_pos) if intel_map != null else {}
	return {
		"schema_kind": &"RunMapSnapshot",
		"RunMap": {
			"map_kind": MAP_KIND_CLASSIC_RECT,
			"width": width,
			"height": height,
			"spawn_pos": spawn_pos,
			"player_pos": player_pos,
			"truth_map_access": &"internal_only",
		},
		"TruthMap": {
			"access": &"internal_only",
			"room_count": rooms.size(),
			"room_counts": _room_counts(),
		},
		"KnownMap": known_snapshot,
		"ScanLayer": known_snapshot.get("ScanLayer", {}),
		"MarkMap": known_snapshot.get("MarkMap", {}),
		"RunMapState": {
			"current_room": get_room_state(player_pos, intel_map) if is_inside(player_pos) else {},
			"mutation_log_count": mutation_log.size(),
			"return_eligibility": get_return_eligibility(player_pos, intel_map),
		},
		"InfoReliabilityLayer": known_snapshot.get("InfoReliabilityLayer", {}),
		"FinalMapSnapshot": {
			"snapshot_ref": &"truth_map_internal_final_snapshot",
			"validation": validate_map(),
			"generation_log_count": generation_log.size(),
		},
		"map_summary_preview": _map_summary_preview(),
		"room_common_rule_summary_preview": RoomCommonRuleSchemaScript.default_common_rule_summary(),
		"objective_context_preview": _context_placeholder(&"objective_context_preview"),
		"modifier_context_preview": _context_placeholder(&"modifier_context_preview"),
		"room_loot_context_preview": _context_placeholder(&"room_loot_context_preview"),
		"run_result_context_preview": _context_placeholder(&"run_result_context_preview"),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


func build_map_result(intel_map: IntelMap = null, player_pos: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var known_summary := _known_summary(intel_map)
	return {
		"schema_kind": &"MapResult",
		"map_kind": MAP_KIND_CLASSIC_RECT,
		"width": width,
		"height": height,
		"spawn_pos": spawn_pos,
		"exit_count": exits.size(),
		"room_counts": _room_counts(),
		"known_summary": known_summary,
		"player_pos": player_pos,
		"map_summary_preview": _map_summary_preview(),
		"room_resolution_summary_preview": RoomCommonRuleSchemaScript.room_resolution_summary_preview(get_room_state(player_pos, intel_map) if is_inside(player_pos) else {}),
		"history_reference_preview": {
			"final_map_snapshot_ref": &"FinalMapSnapshot",
			"known_map_snapshot_ref": &"KnownMap",
			"mutation_log_ref": &"MapMutationLog",
		},
		"settlement_context_preview": _context_placeholder(&"settlement_map_summary_preview"),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


func get_room_state(pos: Vector2i, intel_map: IntelMap = null) -> Dictionary:
	if not is_inside(pos):
		return {
			"schema_kind": &"RoomState",
			"pos": pos,
			"room_type": ROOM_UNKNOWN,
			"known_state": ROOM_STATE_UNKNOWN,
			"reason": &"outside_map",
			"read_only": true,
			"display_only": true,
			"preview": true,
		}
	var cell := get_cell(pos)
	var known_state := _known_state_for(pos, intel_map)
	var room_type := _normalized_room_type(cell, pos)
	var room_state_source := {
		"known_state": known_state,
		"scanned": known_state == ROOM_STATE_SCANNED,
		"explored": bool(cell.get("explored", false)),
		"triggered": bool(cell.get("triggered", false)),
		"cleared": bool(cell.get("cleared", false)),
		"blocked": bool(cell.get("blocked", false)),
	}
	var room_contract: Dictionary = RoomCommonRuleSchemaScript.build_room_contract(room_type, pos, room_state_source)
	return {
		"schema_kind": &"RoomState",
		"pos": pos,
		"room_type": room_type,
		"room_type_key": _room_type_key(room_type),
		"RoomType": room_contract.get("RoomType", {}),
		"RoomPolicy": cell.get("RoomPolicy", room_contract.get("RoomPolicy", {})).duplicate(true),
		"RoomTag": _array_from_variant(cell.get("RoomTag", room_contract.get("RoomTag", []))),
		"RoomContentSlot": cell.get("RoomContentSlot", room_contract.get("RoomContentSlot", {})).duplicate(true),
		"EncounterEntry": cell.get("EncounterEntry", room_contract.get("EncounterEntry", {})).duplicate(true),
		"EncounterPreview": cell.get("EncounterPreview", room_contract.get("EncounterPreview", {})).duplicate(true),
		"RoomRulePreview": cell.get("RoomRulePreview", room_contract.get("RoomRulePreview", {})).duplicate(true),
		"RoomCondition": cell.get("RoomCondition", room_contract.get("RoomCondition", {})).duplicate(true),
		"RoomResolutionPreview": room_contract.get("RoomResolutionPreview", {}).duplicate(true),
		"RoomResultPreview": room_contract.get("RoomResultPreview", {}).duplicate(true),
		"GroundLoot": room_contract.get("GroundLoot", {}).duplicate(true),
		"RoomLootContainer": room_contract.get("RoomLootContainer", {}).duplicate(true),
		"known_state": known_state,
		"visibility": _visibility_for(known_state),
		"scanned": known_state == ROOM_STATE_SCANNED,
		"explored": bool(cell.get("explored", false)),
		"cleared": bool(cell.get("cleared", false)),
		"triggered": bool(cell.get("triggered", false)),
		"blocked": bool(cell.get("blocked", false)),
		"adjacent_mines": int(cell.get("adjacent_mines", 0)),
		"return_eligibility": get_return_eligibility(pos, intel_map),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


func get_return_eligibility(pos: Vector2i, intel_map: IntelMap = null, lock_context: Dictionary = {}) -> Dictionary:
	var reason := RETURN_OK
	var eligible := true
	var intent_state := &"fast_return_intent_preview"
	if not is_inside(pos):
		eligible = false
		reason = RETURN_BLOCKED_OUTSIDE
	elif bool(lock_context.get("locked", false)):
		eligible = false
		reason = RETURN_BLOCKED_LOCKED
	elif intel_map != null and not intel_map.is_revealed(pos):
		var public_cell := intel_map.get_cell_info(pos)
		if bool(public_cell.get("scanned", false)):
			eligible = false
			reason = RETURN_BLOCKED_SCANNED_ONLY
		else:
			eligible = false
			reason = RETURN_BLOCKED_UNKNOWN
	return {
		"schema_kind": &"return_eligibility",
		"fast_return": eligible,
		"eligible": eligible,
		"reason_code": reason,
		"intent_state": intent_state,
		"rule_summary": "Only explored / revealed public rooms may be fast-return targets; scanned-only and unknown rooms are blocked.",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_runtime_teleport": true,
	}


func get_generation_log() -> Array[Dictionary]:
	return generation_log.duplicate(true)


func get_mutation_log() -> Array[Dictionary]:
	return mutation_log.duplicate(true)


func _build_empty_grid() -> void:
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var cell := {
				"pos": pos,
				"mine": false,
				"room_type": ROOM_NORMAL,
				"spawn": false,
				"exit_id": &"",
				"random_exit": false,
				"reserved": false,
				"path": false,
				"adjacent_mines": 0,
				"explored": false,
				"cleared": false,
				"triggered": false,
				"blocked": false,
			}
			cell["RoomPolicy"] = _room_policy_for(ROOM_NORMAL)
			cell["RoomTag"] = _room_tags_for(ROOM_NORMAL)
			rooms[_key(pos)] = cell


func _place_rooms(room_type: StringName, count: int, rng: RandomNumberGenerator) -> void:
	for _i in range(count):
		var pos := _take_random_candidate(_safe_normal_candidates(), rng)
		_set_cell(pos, {"room_type": room_type, "mine": room_type == &"Mine"})


func _safe_normal_candidates() -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var cell: Dictionary = rooms[_key(pos)]
			if bool(cell.get("spawn", false)):
				continue
			if bool(cell.get("mine", false)):
				continue
			if StringName(cell.get("room_type", ROOM_NORMAL)) != ROOM_NORMAL:
				continue
			candidates.append(pos)
	return candidates


func _all_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			positions.append(Vector2i(x, y))
	return positions


func _take_random_candidate(candidates: Array[Vector2i], rng: RandomNumberGenerator) -> Vector2i:
	if candidates.is_empty():
		return Vector2i.ZERO
	var index := rng.randi_range(0, candidates.size() - 1)
	return candidates[index]


func _compute_adjacency() -> void:
	for key in rooms.keys():
		var cell: Dictionary = rooms[key]
		var pos: Vector2i = cell.get("pos", Vector2i.ZERO)
		var count := 0
		for offset in _neighbor_offsets():
			var next_pos := pos + offset
			if is_inside(next_pos) and is_mine(next_pos):
				count += 1
		cell["adjacent_mines"] = count
		rooms[key] = cell


func _set_cell(pos: Vector2i, values: Dictionary) -> void:
	if not is_inside(pos):
		return
	var key := _key(pos)
	var cell: Dictionary = rooms.get(key, {"pos": pos})
	for value_key in values.keys():
		cell[value_key] = values[value_key]
	var normalized_type := _normalized_room_type(cell, pos)
	_apply_common_rule_contract_to_cell(cell, normalized_type, pos)
	rooms[key] = cell


func _key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]


func _neighbor_offsets() -> Array[Vector2i]:
	return [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]


func _refresh_room_contracts() -> void:
	for key in rooms.keys():
		var cell: Dictionary = rooms[key]
		var pos: Vector2i = cell.get("pos", Vector2i.ZERO)
		var room_type := _normalized_room_type(cell, pos)
		cell["RoomPolicy"] = _room_policy_for(room_type)
		cell["RoomTag"] = _room_tags_for(room_type)
		cell["RoomContentSlot"] = RoomCommonRuleSchemaScript.room_content_slot_for(room_type)
		cell["EncounterEntry"] = RoomCommonRuleSchemaScript.encounter_entry_for(room_type, pos)
		cell["EncounterPreview"] = RoomCommonRuleSchemaScript.encounter_preview_for(room_type, pos)
		cell["RoomRulePreview"] = RoomCommonRuleSchemaScript.room_rule_preview_for(room_type)
		cell["RoomCondition"] = RoomCommonRuleSchemaScript.room_condition_for(room_type)
		rooms[key] = cell


func _apply_room_contract(pos: Vector2i) -> void:
	if not is_inside(pos):
		return
	var key := _key(pos)
	var cell: Dictionary = rooms.get(key, {})
	var room_type := _normalized_room_type(cell, pos)
	_apply_common_rule_contract_to_cell(cell, room_type, pos)
	rooms[key] = cell


func _room_policy_for(room_type: StringName) -> Dictionary:
	return RoomCommonRuleSchemaScript.room_policy_for(room_type)


func _policy(return_policy: StringName, search_policy: StringName, loot_policy: StringName, repeat_policy: StringName) -> Dictionary:
	return {
		"schema_kind": &"RoomPolicy",
		"return_policy": return_policy,
		"search_policy": search_policy,
		"loot_policy": loot_policy,
		"repeat_policy": repeat_policy,
		"visibility_policy": &"known_map_only",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


func _room_tags_for(room_type: StringName) -> Array:
	return RoomCommonRuleSchemaScript.room_tags_for(room_type)


func _normalized_room_type(cell: Dictionary, pos: Vector2i) -> StringName:
	if bool(cell.get("spawn", false)) or pos == spawn_pos:
		return ROOM_SPAWN
	return StringName(cell.get("room_type", ROOM_NORMAL))


func _room_type_key(room_type: StringName) -> StringName:
	match room_type:
		ROOM_SPAWN:
			return &"spawn"
		ROOM_NORMAL:
			return &"normal"
		ROOM_MINE:
			return &"mine"
		ROOM_MONSTER:
			return &"monster"
		ROOM_CHEST:
			return &"chest"
		ROOM_EVENT:
			return &"event"
		ROOM_EXIT:
			return &"exit"
		ROOM_BOSS:
			return &"boss"
		ROOM_SPECIAL_RULE:
			return &"special_rule"
		_:
			return &"unknown"


func _known_state_for(pos: Vector2i, intel_map: IntelMap = null) -> StringName:
	var cell := get_cell(pos)
	if bool(cell.get("cleared", false)):
		return ROOM_STATE_CLEARED
	if bool(cell.get("explored", false)):
		return ROOM_STATE_EXPLORED
	if intel_map != null:
		var public_cell := intel_map.get_cell_info(pos)
		if bool(public_cell.get("revealed", false)):
			return ROOM_STATE_EXPLORED
		if bool(public_cell.get("scanned", false)):
			return ROOM_STATE_SCANNED
	return ROOM_STATE_UNKNOWN


func _visibility_for(known_state: StringName) -> StringName:
	match known_state:
		ROOM_STATE_CLEARED, ROOM_STATE_EXPLORED:
			return &"known"
		ROOM_STATE_SCANNED:
			return &"partial"
		_:
			return &"unknown"


func _room_counts() -> Dictionary:
	var counts := {
		"spawn": 0,
		"normal": 0,
		"mine": 0,
		"monster": 0,
		"chest": 0,
		"event": 0,
		"exit": 0,
	}
	for key in rooms.keys():
		var cell: Dictionary = rooms[key]
		var pos: Vector2i = cell.get("pos", Vector2i.ZERO)
		var room_key := String(_room_type_key(_normalized_room_type(cell, pos)))
		counts[room_key] = int(counts.get(room_key, 0)) + 1
	return counts


func _truth_room_summaries() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var cell := get_cell(pos)
			var room_type := _normalized_room_type(cell, pos)
			list.append({
				"pos": pos,
				"room_type": room_type,
				"room_type_key": _room_type_key(room_type),
				"adjacent_mines": int(cell.get("adjacent_mines", 0)),
				"RoomPolicy": cell.get("RoomPolicy", _room_policy_for(room_type)).duplicate(true),
				"RoomTag": _array_from_variant(cell.get("RoomTag", _room_tags_for(room_type))),
				"read_only": true,
				"display_only": true,
				"preview": true,
			})
	return list


func _known_summary(intel_map: IntelMap = null) -> Dictionary:
	if intel_map == null:
		return {"unknown": rooms.size(), "scanned": 0, "explored": 0, "cleared": 0}
	var result := {"unknown": 0, "scanned": 0, "explored": 0, "cleared": 0}
	for cell_variant in intel_map.get_all_cells():
		var public_cell: Dictionary = cell_variant
		var state := String(public_cell.get("known_state", public_cell.get("public_state", "unknown")))
		if not result.has(state):
			result[state] = 0
		result[state] = int(result[state]) + 1
	return result


func _map_summary_preview() -> Dictionary:
	return {
		"schema_kind": &"map_summary_preview",
		"map_kind": MAP_KIND_CLASSIC_RECT,
		"dimensions": "%dx%d" % [width, height],
		"room_counts": _room_counts(),
		"room_common_rule_summary_preview": RoomCommonRuleSchemaScript.default_common_rule_summary(),
		"generation_log_count": generation_log.size(),
		"mutation_log_count": mutation_log.size(),
		"layers": [&"TruthMap", &"KnownMap", &"ScanLayer", &"MarkMap", &"RunMapState", &"InfoReliabilityLayer"],
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


func _apply_common_rule_contract_to_cell(cell: Dictionary, room_type: StringName, pos: Vector2i) -> void:
	cell["RoomPolicy"] = _room_policy_for(room_type)
	cell["RoomTag"] = _room_tags_for(room_type)
	cell["RoomContentSlot"] = RoomCommonRuleSchemaScript.room_content_slot_for(room_type)
	cell["EncounterEntry"] = RoomCommonRuleSchemaScript.encounter_entry_for(room_type, pos)
	cell["EncounterPreview"] = RoomCommonRuleSchemaScript.encounter_preview_for(room_type, pos)
	cell["RoomRulePreview"] = RoomCommonRuleSchemaScript.room_rule_preview_for(room_type)
	cell["RoomCondition"] = RoomCommonRuleSchemaScript.room_condition_for(room_type)


func _context_placeholder(context_id: StringName) -> Dictionary:
	return {
		"context_id": context_id,
		"state": &"reserved_preview",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


func _append_generation_log(event_id: StringName, payload: Dictionary) -> void:
	generation_log.append({
		"schema_kind": &"MapGenerationLog",
		"event_id": event_id,
		"payload": payload.duplicate(true),
		"read_only": true,
		"display_only": true,
		"preview": true,
	})


func _append_mutation_log(event_id: StringName, pos: Vector2i, payload: Dictionary) -> void:
	mutation_log.append({
		"schema_kind": &"MapMutationLog",
		"event_id": event_id,
		"pos": pos,
		"payload": payload.duplicate(true),
		"known_information_policy": &"append_only_no_silent_rewrite",
		"read_only": true,
		"display_only": true,
		"preview": true,
	})


func _position_array(source: Array[Vector2i]) -> Array:
	var result: Array = []
	for pos in source:
		result.append(pos)
	return result


static func _array_from_variant(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []
