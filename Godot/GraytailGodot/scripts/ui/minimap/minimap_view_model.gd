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
		var marker := cell.duplicate(true)
		var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
		if pos == player_pos:
			marker["asset_id"] = &"icon.minimap.player"
			marker["label"] = "P"
		elif bool(marker.get("flagged", false)):
			marker["label"] = "F"
		elif not bool(marker.get("revealed", false)) and StringName(marker.get("exit_id", &"")) == &"":
			marker["label"] = "?"
		model.room_markers.append(marker)
	return model
