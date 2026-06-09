extends RefCounted
class_name MiniMapViewModel

# MiniMapViewModel is built from IntelMap public cells only.

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
	for cell in intel_map.get_visible_map():
		var marker := PresentationMapping.minimap_marker_from_cell(cell, player_pos)
		model.room_markers.append(marker)
	return model
