extends RefCounted
class_name TruthMap

# TruthMap = 真实地图
# IntelMap = 玩家已知情报
# MiniMapViewModel = UI 可读数据
# UI 不得直接读取 TruthMap

var rooms: Dictionary = {}
var width: int = 0
var height: int = 0
var spawn_pos: Vector2i = Vector2i.ZERO


func clear() -> void:
	rooms.clear()
	width = 0
	height = 0
	spawn_pos = Vector2i.ZERO


func setup_demo_map() -> void:
	clear()
	width = 7
	height = 7
	spawn_pos = Vector2i(3, 3)

	for y in range(height):
		for x in range(width):
			set_room_type(Vector2i(x, y), &"Normal")

	set_room_type(spawn_pos, &"Spawn")
	set_room_type(Vector2i(2, 2), &"Mine")
	set_room_type(Vector2i(4, 2), &"Mine")
	set_room_type(Vector2i(5, 5), &"Mine")
	set_room_type(Vector2i(1, 1), &"Chest")
	set_room_type(Vector2i(5, 1), &"Event")
	set_room_type(Vector2i(1, 5), &"Monster")
	set_room_type(Vector2i(6, 6), &"Exit")


func get_room_type(pos: Vector2i) -> StringName:
	return rooms.get(_key(pos), &"Unknown")


func set_room_type(pos: Vector2i, room_type: StringName) -> void:
	if is_inside(pos):
		rooms[_key(pos)] = room_type


func is_mine(pos: Vector2i) -> bool:
	return get_room_type(pos) == &"Mine"


func get_adjacent_mine_count(pos: Vector2i) -> int:
	var count := 0
	for offset in _neighbor_offsets():
		var next_pos := pos + offset
		if is_inside(next_pos) and is_mine(next_pos):
			count += 1
	return count


func is_inside(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height


func _key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]


func _neighbor_offsets() -> Array[Vector2i]:
	return [
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
		Vector2i(1, 1),
	]
