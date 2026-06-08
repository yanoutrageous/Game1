extends RefCounted
class_name MiniMapViewModel

# TruthMap = 真实地图
# IntelMap = 玩家已知情报
# MiniMapViewModel = UI 可读数据
# UI 不得直接读取 TruthMap

var room_markers: Array[Dictionary] = []
var width: int = 0
var height: int = 0


func set_room_markers(markers: Array[Dictionary]) -> void:
	room_markers = markers.duplicate(true)


func clear() -> void:
	room_markers.clear()
	width = 0
	height = 0


static func build_from_intel(intel_map: IntelMap, player_pos: Vector2i = Vector2i(-1, -1)) -> MiniMapViewModel:
	var model := MiniMapViewModel.new()
	if intel_map == null:
		return model
	model.width = intel_map.width
	model.height = intel_map.height
	for cell in intel_map.get_all_cells():
		var marker := cell.duplicate(true)
		var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
		if pos == player_pos:
			marker["asset_id"] = &"icon.minimap.player"
			marker["label"] = "P"
		model.room_markers.append(marker)
	return model
