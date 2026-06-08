extends RefCounted
class_name TruthMap

# TruthMap owns real map truth. UI must read IntelMap/ViewModels only.

var rooms: Dictionary = {}
var width: int = 0
var height: int = 0
var spawn_pos: Vector2i = Vector2i.ZERO
var exits: Array[Vector2i] = []


func clear() -> void:
	rooms.clear()
	width = 0
	height = 0
	spawn_pos = Vector2i.ZERO
	exits.clear()


func setup_from_config(config: Dictionary) -> void:
	if config.has("manual_map"):
		setup_manual_map(config)
	else:
		setup_standard_map(config)


func setup_manual_map(config: Dictionary) -> void:
	clear()
	width = int(config.get("width", 5))
	height = int(config.get("height", 5))
	_build_empty_grid()
	var manual_map: Dictionary = config.get("manual_map", {})
	spawn_pos = manual_map.get("spawn", Vector2i.ZERO)
	_set_cell(spawn_pos, {"spawn": true, "room_type": &"Normal"})
	for pos in manual_map.get("mines", []):
		_set_cell(pos, {"mine": true, "room_type": &"Mine"})
	for pos in manual_map.get("events", []):
		_set_cell(pos, {"room_type": &"Event"})
	for pos in manual_map.get("monsters", []):
		_set_cell(pos, {"room_type": &"Monster"})
	for pos in manual_map.get("chests", []):
		_set_cell(pos, {"room_type": &"Chest"})
	for exit_def in manual_map.get("exits", []):
		var pos: Vector2i = exit_def.get("pos", Vector2i.ZERO)
		_set_cell(pos, {
			"room_type": &"Exit",
			"exit_id": StringName(exit_def.get("exit_id", &"tutorial_exit")),
			"random_exit": bool(exit_def.get("random_exit", false)),
		})
		exits.append(pos)
	_compute_adjacency()


func setup_standard_map(config: Dictionary) -> void:
	clear()
	width = int(config.get("width", 10))
	height = int(config.get("height", 10))
	_build_empty_grid()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.get("seed", 1001))
	spawn_pos = _take_random_candidate(_all_positions(), rng)
	_set_cell(spawn_pos, {"spawn": true, "room_type": &"Normal", "reserved": true})
	_place_rooms(&"Mine", int(config.get("mine_count", 20)), rng)
	_place_rooms(&"Monster", int(config.get("monster_room_count", 10)), rng)
	_place_rooms(&"Chest", int(config.get("chest_room_count", 10)), rng)
	_place_rooms(&"Event", int(config.get("event_room_count", 10)), rng)
	for i in range(int(config.get("random_exit_count", 2))):
		var pos := _take_random_candidate(_safe_normal_candidates(), rng)
		_set_cell(pos, {"room_type": &"Exit", "exit_id": StringName("random_%d" % [i + 1]), "random_exit": true})
		exits.append(pos)
	_compute_adjacency()


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
	_set_cell(pos, {"room_type": room_type, "mine": room_type == &"Mine"})
	_compute_adjacency()


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


func mark_cleared(pos: Vector2i) -> void:
	_set_cell(pos, {"cleared": true})


func mark_triggered(pos: Vector2i) -> void:
	_set_cell(pos, {"triggered": true})


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


func _build_empty_grid() -> void:
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			rooms[_key(pos)] = {
				"pos": pos,
				"mine": false,
				"room_type": &"Normal",
				"spawn": false,
				"exit_id": &"",
				"random_exit": false,
				"reserved": false,
				"path": false,
				"adjacent_mines": 0,
				"explored": false,
				"cleared": false,
				"triggered": false,
			}


func _place_rooms(room_type: StringName, count: int, rng: RandomNumberGenerator) -> void:
	for _i in range(count):
		var pos := _take_random_candidate(_safe_normal_candidates(), rng)
		_set_cell(pos, {"room_type": room_type, "mine": room_type == &"Mine"})


func _safe_normal_candidates() -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			var cell := rooms[_key(pos)]
			if bool(cell.get("spawn", false)):
				continue
			if bool(cell.get("mine", false)):
				continue
			if StringName(cell.get("room_type", &"Normal")) != &"Normal":
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
	rooms[key] = cell


func _key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]


func _neighbor_offsets() -> Array[Vector2i]:
	return [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]
