extends RefCounted
class_name IntelMap

# IntelMap owns player-known information. UI must not read TruthMap directly.
# It exposes public semantic state only; PresentationMapping assigns asset ids.

var known_rooms: Dictionary = {}
var width: int = 0
var height: int = 0
var scan_layer: Dictionary = {}
var mark_map: Dictionary = {}
var info_reliability_layer: Dictionary = {}


func clear() -> void:
	known_rooms.clear()
	scan_layer.clear()
	mark_map.clear()
	info_reliability_layer.clear()
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
			scan_layer[_key(pos)] = _base_scan_cell(pos)
			mark_map[_key(pos)] = _base_mark_cell(pos)
			info_reliability_layer[_key(pos)] = _base_reliability_cell(pos)


func reveal_cell(pos: Vector2i, truth_map: TruthMap = null) -> void:
	if not _has_cell(pos):
		return
	var cell := build_public_cell(pos, truth_map, true)
	cell["revealed"] = true
	cell["flagged"] = bool(known_rooms[_key(pos)].get("flagged", false))
	cell["known_state"] = &"explored"
	cell["public_state"] = &"explored"
	cell["visibility"] = &"known"
	if bool(cell["flagged"]):
		cell["state"] = &"flagged"
	known_rooms[_key(pos)] = cell
	info_reliability_layer[_key(pos)] = _reliability_cell(pos, &"direct_explore", 1.0)


func toggle_flag(pos: Vector2i) -> void:
	if not _has_cell(pos):
		return
	var cell: Dictionary = known_rooms[_key(pos)]
	cell["flagged"] = not bool(cell.get("flagged", false))
	if bool(cell["flagged"]):
		cell["state"] = &"flagged"
	elif bool(cell.get("revealed", false)):
		cell["state"] = cell.get("state_before_flag", &"empty")
	else:
		cell["state"] = &"hidden"
	known_rooms[_key(pos)] = cell
	mark_map[_key(pos)] = {
		"schema_kind": &"MarkMap",
		"pos": pos,
		"marked": bool(cell.get("flagged", false)),
		"mark_type": &"risk_flag" if bool(cell.get("flagged", false)) else &"none",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


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


func scan_cell(pos: Vector2i, truth_map: TruthMap = null, scan_hint: StringName = &"limited", reliability: float = 0.65) -> Dictionary:
	if not _has_cell(pos):
		return {}
	var cell: Dictionary = known_rooms[_key(pos)]
	if not bool(cell.get("revealed", false)):
		cell["scanned"] = true
		cell["known_state"] = &"scanned"
		cell["public_state"] = &"scanned"
		cell["visibility"] = &"partial"
		if truth_map != null and truth_map.is_inside(pos):
			var truth := truth_map.get_cell(pos)
			cell["scan_hint"] = scan_hint
			cell["scan_room_type_hint"] = truth.get("room_type", &"Unknown") if scan_hint == &"room_type" else &"unknown"
		known_rooms[_key(pos)] = cell
	scan_layer[_key(pos)] = {
		"schema_kind": &"ScanLayer",
		"pos": pos,
		"scanned": true,
		"scan_hint": scan_hint,
		"reliability": reliability,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}
	info_reliability_layer[_key(pos)] = _reliability_cell(pos, &"scan", reliability)
	return get_cell_info(pos)


func set_manual_mark(pos: Vector2i, mark_type: StringName, note: String = "") -> Dictionary:
	if not _has_cell(pos):
		return {}
	mark_map[_key(pos)] = {
		"schema_kind": &"MarkMap",
		"pos": pos,
		"marked": mark_type != &"none",
		"mark_type": mark_type,
		"note": note,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}
	return mark_map[_key(pos)].duplicate(true)


func get_visible_map() -> Array[Dictionary]:
	return get_all_cells()


func get_all_cells() -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	for y in range(height):
		for x in range(width):
			cells.append(get_cell_info(Vector2i(x, y)))
	return cells


func build_known_map_snapshot(truth_map: TruthMap = null, player_pos: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var public_cells: Array[Dictionary] = []
	var scan_cells: Array[Dictionary] = []
	var mark_cells: Array[Dictionary] = []
	var reliability_cells: Array[Dictionary] = []
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			public_cells.append(get_public_room_detail(pos, truth_map, player_pos))
			scan_cells.append(scan_layer.get(_key(pos), _base_scan_cell(pos)).duplicate(true))
			mark_cells.append(mark_map.get(_key(pos), _base_mark_cell(pos)).duplicate(true))
			reliability_cells.append(info_reliability_layer.get(_key(pos), _base_reliability_cell(pos)).duplicate(true))
	return {
		"schema_kind": &"KnownMap",
		"width": width,
		"height": height,
		"player_pos": player_pos,
		"public_cells": public_cells,
		"ScanLayer": {
			"schema_kind": &"ScanLayer",
			"cells": scan_cells,
			"read_only": true,
			"display_only": true,
			"preview": true,
		},
		"MarkMap": {
			"schema_kind": &"MarkMap",
			"cells": mark_cells,
			"read_only": true,
			"display_only": true,
			"preview": true,
		},
		"InfoReliabilityLayer": {
			"schema_kind": &"InfoReliabilityLayer",
			"cells": reliability_cells,
			"default_policy": &"direct_explore_highest_reliability",
			"read_only": true,
			"display_only": true,
			"preview": true,
		},
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


func get_public_room_detail(pos: Vector2i, truth_map: TruthMap = null, player_pos: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	if not _has_cell(pos):
		return {}
	var cell := get_cell_info(pos)
	var known_state := StringName(cell.get("known_state", cell.get("public_state", &"unknown")))
	var detail := {
		"schema_kind": &"RoomDetailPreview",
		"pos": pos,
		"is_current": pos == player_pos,
		"known_state": known_state,
		"visibility": cell.get("visibility", &"unknown"),
		"room_type": cell.get("room_type", &"Unknown") if bool(cell.get("revealed", false)) else &"Unknown",
		"adjacent_mines": cell.get("adjacent_mines", -1),
		"flagged": bool(cell.get("flagged", false)),
		"scanned": bool(cell.get("scanned", false)),
		"revealed": bool(cell.get("revealed", false)),
		"explored": bool(cell.get("explored", false)),
		"cleared": bool(cell.get("cleared", false)),
		"return_eligibility": {},
		"read_only": true,
		"display_only": true,
		"preview": true,
	}
	if truth_map != null:
		detail["return_eligibility"] = truth_map.get_return_eligibility(pos, self)
	return detail


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
	var previous: Dictionary = known_rooms.get(_key(pos), _base_public_cell(pos))
	var revealed := is_revealed(pos) or bool(previous.get("revealed", false))
	cell["scanned"] = bool(previous.get("scanned", false))
	cell["known_state"] = previous.get("known_state", &"unknown")
	cell["public_state"] = previous.get("public_state", &"unknown")
	cell["visibility"] = previous.get("visibility", &"unknown")

	if room_type == &"Exit" and not random_exit:
		cell["exit_id"] = exit_id
		cell["random_exit"] = false

	if not revealed and not reveal_mines:
		return cell

	cell["revealed"] = true
	cell["known_state"] = &"explored"
	cell["public_state"] = &"explored"
	cell["visibility"] = &"known"
	cell["room_type"] = room_type
	cell["mine"] = bool(truth.get("mine", false))
	cell["adjacent_mines"] = int(truth.get("adjacent_mines", 0))
	cell["exit_id"] = exit_id
	cell["random_exit"] = random_exit
	cell["explored"] = bool(truth.get("explored", false))
	cell["cleared"] = bool(truth.get("cleared", false))
	if bool(cell["mine"]):
		cell["state"] = &"mine"
	elif int(cell["adjacent_mines"]) > 0:
		cell["state"] = &"number"
	else:
		cell["state"] = &"empty"
	cell["state_before_flag"] = cell["state"]
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
		"scanned": false,
		"known_state": &"unknown",
		"public_state": &"unknown",
		"visibility": &"unknown",
		"scan_hint": &"",
		"scan_room_type_hint": &"unknown",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


func _has_cell(pos: Vector2i) -> bool:
	return known_rooms.has(_key(pos))


func _key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]


func _base_scan_cell(pos: Vector2i) -> Dictionary:
	return {
		"schema_kind": &"ScanLayer",
		"pos": pos,
		"scanned": false,
		"scan_hint": &"none",
		"reliability": 0.0,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


func _base_mark_cell(pos: Vector2i) -> Dictionary:
	return {
		"schema_kind": &"MarkMap",
		"pos": pos,
		"marked": false,
		"mark_type": &"none",
		"note": "",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


func _base_reliability_cell(pos: Vector2i) -> Dictionary:
	return _reliability_cell(pos, &"unknown", 0.0)


func _reliability_cell(pos: Vector2i, source: StringName, reliability: float) -> Dictionary:
	return {
		"schema_kind": &"InfoReliabilityLayer",
		"pos": pos,
		"source": source,
		"reliability": clampf(reliability, 0.0, 1.0),
		"read_only": true,
		"display_only": true,
		"preview": true,
	}
