extends RefCounted
class_name MinefieldService

# TruthMap = 真实地图
# IntelMap = 玩家已知情报
# MiniMapViewModel = UI 可读数据
# UI 不得直接读取 TruthMap


func has_mine(_room_id: StringName) -> bool:
	return false


func count_adjacent_mines(truth_map: TruthMap, pos: Vector2i) -> int:
	if truth_map == null:
		return 0
	return truth_map.get_adjacent_mine_count(pos)


func get_neighbors_8(pos: Vector2i, width: int, height: int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for offset in _neighbor_offsets():
		var next_pos := pos + offset
		if next_pos.x >= 0 and next_pos.y >= 0 and next_pos.x < width and next_pos.y < height:
			neighbors.append(next_pos)
	return neighbors


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
