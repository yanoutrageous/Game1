extends RefCounted
class_name MiniMapViewModel

# MiniMapViewModel is built from IntelMap public cells only.

var room_markers: Array[Dictionary] = []
var width: int = 0
var height: int = 0
var map_snapshot: Dictionary = {}
var map_summary_preview: Dictionary = {}
var return_eligibility_preview: Dictionary = {}


func set_room_markers(markers: Array[Dictionary]) -> void:
	room_markers = markers.duplicate(true)


func clear() -> void:
	room_markers.clear()
	map_snapshot.clear()
	map_summary_preview.clear()
	return_eligibility_preview.clear()
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
		marker["known_state"] = cell.get("known_state", cell.get("public_state", &"unknown"))
		marker["visibility"] = cell.get("visibility", &"unknown")
		marker["scanned"] = bool(cell.get("scanned", false))
		marker["display_only"] = true
		marker["read_only"] = true
		marker["preview"] = true
		model.room_markers.append(marker)
	return model


static func build_from_run_map_snapshot(snapshot: Dictionary) -> MiniMapViewModel:
	var model := MiniMapViewModel.new()
	model.map_snapshot = snapshot.duplicate(true)
	var run_map: Dictionary = snapshot.get("RunMap", {})
	model.width = int(run_map.get("width", 0))
	model.height = int(run_map.get("height", 0))
	model.map_summary_preview = snapshot.get("map_summary_preview", {}).duplicate(true)
	var run_map_state: Dictionary = snapshot.get("RunMapState", {})
	model.return_eligibility_preview = run_map_state.get("return_eligibility", {}).duplicate(true)
	var known_map: Dictionary = snapshot.get("KnownMap", {})
	var public_cells: Array = known_map.get("public_cells", [])
	for cell_variant in public_cells:
		if not (cell_variant is Dictionary):
			continue
		var cell: Dictionary = cell_variant
		var marker := {
			"pos": cell.get("pos", Vector2i.ZERO),
			"label": _label_for_known_state(StringName(cell.get("known_state", &"unknown"))),
			"tooltip": _tooltip_for_public_cell(cell),
			"asset_id": &"",
			"theme_key": _theme_for_known_state(StringName(cell.get("known_state", &"unknown"))),
			"room_type": cell.get("room_type", &"Unknown"),
			"known_state": cell.get("known_state", &"unknown"),
			"visibility": cell.get("visibility", &"unknown"),
			"return_eligibility": cell.get("return_eligibility", {}),
			"display_only": true,
			"read_only": true,
			"preview": true,
		}
		model.room_markers.append(marker)
	return model


static func _label_for_known_state(state: StringName) -> String:
	match state:
		&"cleared":
			return "C"
		&"explored":
			return "E"
		&"scanned":
			return "S"
		_:
			return "?"


static func _theme_for_known_state(state: StringName) -> StringName:
	match state:
		&"cleared":
			return &"mini.safe"
		&"explored":
			return &"mini.normal"
		&"scanned":
			return &"mini.warning"
		_:
			return &"mini.hidden"


static func _tooltip_for_public_cell(cell: Dictionary) -> String:
	var pos: Vector2i = cell.get("pos", Vector2i.ZERO)
	var return_eligibility: Dictionary = cell.get("return_eligibility", {})
	return "RoomState %s at (%d,%d), return_eligibility=%s" % [
		String(cell.get("known_state", "unknown")),
		pos.x,
		pos.y,
		String(return_eligibility.get("reason_code", "unknown")),
	]
