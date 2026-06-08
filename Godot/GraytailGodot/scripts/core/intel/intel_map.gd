extends RefCounted
class_name IntelMap

# TruthMap = 真实地图
# IntelMap = 玩家已知情报
# MiniMapViewModel = UI 可读数据
# UI 不得直接读取 TruthMap

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
			known_rooms[_key(pos)] = {
				"pos": pos,
				"revealed": false,
				"flagged": false,
				"room_type": &"Unknown",
				"adjacent_mines": -1,
				"asset_id": &"",
				"label": "?",
			}


func reveal_cell(pos: Vector2i, truth_map: TruthMap = null) -> void:
	if not _has_cell(pos):
		return
	var cell: Dictionary = known_rooms[_key(pos)]
	cell["revealed"] = true
	if truth_map != null:
		var room_type := truth_map.get_room_type(pos)
		cell["room_type"] = room_type
		cell["adjacent_mines"] = truth_map.get_adjacent_mine_count(pos)
		cell["asset_id"] = _asset_id_for_room(room_type)
		cell["label"] = _label_for_room(room_type, int(cell["adjacent_mines"]))
	known_rooms[_key(pos)] = cell


func flag_cell(pos: Vector2i) -> void:
	if not _has_cell(pos):
		return
	var cell: Dictionary = known_rooms[_key(pos)]
	cell["flagged"] = not bool(cell.get("flagged", false))
	if bool(cell["flagged"]):
		cell["asset_id"] = &"icon.minimap.flag"
		cell["label"] = "F"
	elif bool(cell.get("revealed", false)):
		var room_type := StringName(cell.get("room_type", &"Unknown"))
		cell["asset_id"] = _asset_id_for_room(room_type)
		cell["label"] = _label_for_room(room_type, int(cell.get("adjacent_mines", -1)))
	else:
		cell["asset_id"] = &""
		cell["label"] = "?"
	known_rooms[_key(pos)] = cell


func is_revealed(pos: Vector2i) -> bool:
	if not _has_cell(pos):
		return false
	return bool(known_rooms[_key(pos)].get("revealed", false))


func get_cell_info(pos: Vector2i) -> Dictionary:
	if not _has_cell(pos):
		return {}
	return known_rooms[_key(pos)].duplicate(true)


func get_all_cells() -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	for y in range(height):
		for x in range(width):
			cells.append(get_cell_info(Vector2i(x, y)))
	return cells


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
