extends RefCounted
class_name IntelMap

# IntelMap owns player-known information. UI must not read TruthMap directly.

var known_rooms: Dictionary = {}
var width: int = 0
var height: int = 0


func clear() -> void:
	known_rooms.clear()
	width = 0
	height = 0


func setup(next_width: int, next_height: int) -> void:
	clear()
	width = next_width
	height = next_height
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			known_rooms[_key(pos)] = _base_public_cell(pos)


func reveal_cell(pos: Vector2i, truth_map: TruthMap = null) -> void:
	if not _has_cell(pos):
		return
	var cell := build_public_cell(pos, truth_map, true)
	cell["revealed"] = true
	cell["flagged"] = bool(known_rooms[_key(pos)].get("flagged", false))
	if bool(cell["flagged"]):
		cell["state"] = &"flagged"
		cell["asset_id"] = &"icon.minimap.flag"
		cell["label"] = "F"
	known_rooms[_key(pos)] = cell


func toggle_flag(pos: Vector2i) -> void:
	if not _has_cell(pos):
		return
	var cell: Dictionary = known_rooms[_key(pos)]
	cell["flagged"] = not bool(cell.get("flagged", false))
	if bool(cell["flagged"]):
		cell["state"] = &"flagged"
		cell["asset_id"] = &"icon.minimap.flag"
		cell["label"] = "F"
	elif bool(cell.get("revealed", false)):
		cell["state"] = cell.get("state_before_flag", &"empty")
		cell["asset_id"] = cell.get("asset_before_flag", &"")
		cell["label"] = cell.get("label_before_flag", ".")
	else:
		cell["state"] = &"hidden"
		cell["asset_id"] = &""
		cell["label"] = "?"
	known_rooms[_key(pos)] = cell


func flag_cell(pos: Vector2i) -> void:
	toggle_flag(pos)


func is_revealed(pos: Vector2i) -> bool:
	return _has_cell(pos) and bool(known_rooms[_key(pos)].get("revealed", false))


func is_flagged(pos: Vector2i) -> bool:
	return _has_cell(pos) and bool(known_rooms[_key(pos)].get("flagged", false))


func get_cell_info(pos: Vector2i) -> Dictionary:
	if not _has_cell(pos):
		return {}
	return known_rooms[_key(pos)].duplicate(true)


func get_visible_map() -> Array[Dictionary]:
	return get_all_cells()


func get_all_cells() -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	for y in range(height):
		for x in range(width):
			cells.append(get_cell_info(Vector2i(x, y)))
	return cells


func build_public_cell(pos: Vector2i, truth_map: TruthMap, reveal_mines: bool = false) -> Dictionary:
	var cell := _base_public_cell(pos)
	if truth_map == null or not truth_map.is_inside(pos):
		return cell
	var truth := truth_map.get_cell(pos)
	var room_type := StringName(truth.get("room_type", &"Normal"))
	if bool(truth.get("spawn", false)):
		room_type = &"Spawn"
	var random_exit := bool(truth.get("random_exit", false))
	var exit_id := StringName(truth.get("exit_id", &""))
	var revealed := is_revealed(pos) or bool(cell.get("revealed", false))

	if room_type == &"Exit" and not random_exit:
		cell["exit_id"] = exit_id
		cell["random_exit"] = false

	if not revealed and not reveal_mines:
		return cell

	cell["revealed"] = true
	cell["room_type"] = room_type
	cell["mine"] = bool(truth.get("mine", false))
	cell["adjacent_mines"] = int(truth.get("adjacent_mines", 0))
	cell["exit_id"] = exit_id
	cell["random_exit"] = random_exit
	cell["explored"] = bool(truth.get("explored", false))
	cell["cleared"] = bool(truth.get("cleared", false))
	cell["asset_id"] = _asset_id_for_room(room_type)
	cell["label"] = _label_for_room(room_type, int(cell["adjacent_mines"]))
	if bool(cell["mine"]):
		cell["state"] = &"mine"
	elif int(cell["adjacent_mines"]) > 0:
		cell["state"] = &"number"
	else:
		cell["state"] = &"empty"
	cell["state_before_flag"] = cell["state"]
	cell["asset_before_flag"] = cell["asset_id"]
	cell["label_before_flag"] = cell["label"]
	return cell


func refresh_revealed_cell(pos: Vector2i, truth_map: TruthMap) -> void:
	if is_revealed(pos):
		reveal_cell(pos, truth_map)


func _base_public_cell(pos: Vector2i) -> Dictionary:
	return {
		"pos": pos,
		"state": &"hidden",
		"revealed": false,
		"flagged": false,
		"room_type": &"Unknown",
		"mine": false,
		"adjacent_mines": -1,
		"exit_id": &"",
		"random_exit": false,
		"explored": false,
		"cleared": false,
		"asset_id": &"",
		"label": "?",
	}


func _has_cell(pos: Vector2i) -> bool:
	return known_rooms.has(_key(pos))


func _key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]


func _asset_id_for_room(room_type: StringName) -> StringName:
	match room_type:
		&"Spawn":
			return &"icon.room.spawn"
		&"Mine":
			return &"icon.room.mine"
		&"Chest":
			return &"icon.room.chest"
		&"Event":
			return &"icon.room.event"
		&"Monster":
			return &"icon.room.monster"
		&"Exit":
			return &"icon.room.exit"
		_:
			return &"icon.room.normal"


func _label_for_room(room_type: StringName, adjacent_mines: int) -> String:
	match room_type:
		&"Spawn":
			return "G"
		&"Mine":
			return "M"
		&"Chest":
			return "C"
		&"Event":
			return "E"
		&"Monster":
			return "!"
		&"Exit":
			return "X"
		_:
			if adjacent_mines >= 0:
				return str(adjacent_mines)
			return "."
