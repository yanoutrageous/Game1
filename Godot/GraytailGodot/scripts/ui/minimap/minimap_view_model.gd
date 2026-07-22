extends RefCounted
class_name MiniMapViewModel

# MiniMapViewModel is built from KnownMap/IntelMap public cells only. It keeps a
# deliberately reduced copy of that public projection so UI consumers cannot
# accidentally retain or inspect internal map layers.

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
		marker = build_cell_view_model(marker, player_pos)
		model.room_markers.append(marker)
	return model


static func build_from_run_map_snapshot(snapshot: Dictionary) -> MiniMapViewModel:
	var model := MiniMapViewModel.new()
	var known_map: Dictionary = snapshot.get("KnownMap", {})
	var public_cells: Array = known_map.get("public_cells", [])
	model.width = int(known_map.get("width", _public_extent(public_cells, true)))
	model.height = int(known_map.get("height", _public_extent(public_cells, false)))
	var player_pos: Vector2i = known_map.get("player_pos", Vector2i(-1, -1))
	model.map_summary_preview = {
		"width": model.width,
		"height": model.height,
		"public_cell_count": public_cells.size(),
		"read_only": true,
	}
	var sanitized_public_cells: Array[Dictionary] = []
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
			"flagged": bool(cell.get("flagged", false)),
			"scanned": bool(cell.get("scanned", false)),
			"revealed": bool(cell.get("revealed", false)),
			"explored": bool(cell.get("explored", false)),
			"cleared": bool(cell.get("cleared", false)),
			"is_current": bool(cell.get("is_current", false)),
			"adjacent_mines": int(cell.get("adjacent_mines", -1)),
			"return_eligibility": cell.get("return_eligibility", {}),
			"display_only": true,
			"read_only": true,
			"preview": true,
		}
		marker = build_cell_view_model(marker, player_pos)
		model.room_markers.append(marker)
		sanitized_public_cells.append({
			"pos": marker.get("pos", Vector2i.ZERO),
			"is_current": bool(marker.get("is_current", false)),
			"known_state": marker.get("known_state", &"unknown"),
			"visibility": marker.get("visibility", &"unknown"),
			"room_type": marker.get("room_type", &"Unknown"),
			"adjacent_mines": int(marker.get("adjacent_mines", -1)),
			"flagged": bool(marker.get("flagged", false)),
			"scanned": bool(marker.get("scanned", false)),
			"revealed": bool(marker.get("revealed", false)),
			"explored": bool(marker.get("explored", false)),
			"cleared": bool(marker.get("cleared", false)),
			"return_eligibility": (marker.get("return_eligibility", {}) as Dictionary).duplicate(true),
			"read_only": true,
			"display_only": true,
		})
		if bool(marker.get("is_current", false)):
			model.return_eligibility_preview = (marker.get("return_eligibility", {}) as Dictionary).duplicate(true)
	model.map_snapshot = {
		"KnownMap": {
			"width": model.width,
			"height": model.height,
			"player_pos": player_pos,
			"public_cells": sanitized_public_cells,
			"read_only": true,
			"display_only": true,
		}
	}
	return model


static func build_cell_view_model(raw_marker: Dictionary, player_pos: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var marker := raw_marker.duplicate(true)
	var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
	var known_state := StringName(marker.get("known_state", marker.get("state", &"unknown")))
	var explicitly_revealed := bool(marker.get("revealed", false)) or bool(marker.get("explored", false)) or known_state in [&"explored", &"cleared"]
	var publicly_scanned := bool(marker.get("scanned", false)) or known_state == &"scanned"
	var room_type := StringName(marker.get("room_type", &"Unknown"))
	# A visible exit is the one public room-type exception for an otherwise
	# unknown cell. Every other unrevealed type is reduced to Unknown here even
	# if a malformed fixture accidentally forwards an internal value.
	if not explicitly_revealed and room_type != &"Exit":
		room_type = &"Unknown"
	var adjacent := int(marker.get("adjacent_mines", -1))
	if known_state == &"unknown" or (not publicly_scanned and not explicitly_revealed) or adjacent < 0 or adjacent > 8:
		adjacent = -1
	marker["room_type"] = room_type
	marker["adjacent_mines"] = adjacent
	var return_eligibility: Dictionary = marker.get("return_eligibility", {})
	var eligible_return := bool(return_eligibility.get("eligible", return_eligibility.get("fast_return", false)))
	var revealed := bool(marker.get("revealed", false)) or eligible_return or known_state in [&"explored", &"cleared"]
	var explored := bool(marker.get("explored", false)) or eligible_return or known_state in [&"explored", &"cleared"]
	var cleared := bool(marker.get("cleared", false)) or known_state == &"cleared"
	var scanned := publicly_scanned
	var flagged := bool(marker.get("flagged", false))
	var is_current := bool(marker.get("is_current", false)) or (player_pos.x >= 0 and pos == player_pos)
	var distance: int = abs(pos.x - player_pos.x) + abs(pos.y - player_pos.y) if player_pos.x >= 0 else -1
	var action := _action_for_cell(is_current, flagged, revealed, explored, cleared, scanned, room_type, distance, return_eligibility)
	marker["is_current"] = is_current
	marker["distance_to_player"] = distance
	marker["revealed"] = revealed
	marker["explored"] = explored
	marker["cleared"] = cleared
	marker["scanned"] = scanned
	marker["action_id"] = action.get("id", &"inspect")
	marker["action_label"] = action.get("label", "查看")
	marker["action_enabled"] = bool(action.get("enabled", false))
	marker["disabled_reason"] = String(action.get("reason", ""))
	marker["detail_text"] = _detail_text(marker, action)
	marker["tooltip"] = String(marker.get("detail_text", ""))
	return marker


static func action_result_for_marker(marker: Dictionary) -> Dictionary:
	return {
		"accepted": bool(marker.get("action_enabled", false)),
		"ok": bool(marker.get("action_enabled", false)),
		"command_id": marker.get("action_id", &"inspect"),
		"reason_code": String(marker.get("disabled_reason", "")),
	}


static func _action_for_cell(is_current: bool, flagged: bool, revealed: bool, explored: bool, cleared: bool, scanned: bool, room_type: StringName, distance: int, return_eligibility: Dictionary) -> Dictionary:
	if is_current:
		return {"id": &"current", "label": "当前位置", "enabled": false, "reason": "current_room"}
	if flagged:
		return {"id": &"toggle_flag", "label": "取消标记", "enabled": true, "reason": ""}
	if not revealed:
		if scanned:
			return {"id": &"inspect", "label": "已扫描，需探索", "enabled": false, "reason": "scanned_not_explored"}
		return {"id": &"toggle_flag", "label": "标记风险", "enabled": true, "reason": ""}
	if explored and bool(return_eligibility.get("eligible", return_eligibility.get("fast_return", false))):
		return {"id": &"fast_return", "label": "回传到此房间", "enabled": true, "reason": ""}
	if explored and room_type == &"Mine":
		return {"id": &"inspect", "label": "雷险房仅查看", "enabled": false, "reason": "mine_not_fast_return"}
	if distance == 1:
		return {"id": &"inspect", "label": "相邻格，移动探索", "enabled": false, "reason": "use_movement_to_explore"}
	return {"id": &"inspect", "label": "查看详情", "enabled": false, "reason": String(return_eligibility.get("reason_code", "not_fast_return_target"))}


static func _detail_text(marker: Dictionary, action: Dictionary) -> String:
	var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
	var state := String(marker.get("known_state", marker.get("state", "unknown")))
	var room_type := String(marker.get("room_type", "Unknown"))
	var adjacent := int(marker.get("adjacent_mines", -1))
	var distance := int(marker.get("distance_to_player", -1))
	var action_label := String(action.get("label", "查看"))
	var reason := String(action.get("reason", ""))
	# The expanded map has one compact status band above a large 10x10 grid.
	# Keep the player-facing summary to two lines instead of forwarding the old
	# four-line diagnostic dump, which both leaked raw enum values and crushed
	# the type hierarchy at 1280x720.
	var lines: Array[String] = [
		"格子 (%d,%d) · %s · %s · 距离 %s" % [pos.x, pos.y, _known_state_label(state), _room_type_label(room_type), str(distance) if distance >= 0 else "未知"],
		"周边雷险 %s · %s%s" % [str(adjacent) if adjacent >= 0 else "未知", action_label, "" if reason == "" else "（%s）" % _reason_label(reason)],
	]
	if bool(marker.get("flagged", false)):
		lines[1] += " · 已标记疑似危险，再次点击取消"
	elif not bool(marker.get("revealed", false)):
		lines[1] += " · 未知格需移动探索"
	elif bool(marker.get("scanned", false)) and not bool(marker.get("explored", false)):
		lines[1] += " · 尚不可回传"
	elif bool(marker.get("explored", false)) and StringName(action.get("id", &"inspect")) == &"fast_return":
		lines[1] += " · 可回传"
	elif bool(marker.get("explored", false)):
		lines[1] += " · 已公开，当前仅查看"
	return _join_lines(lines)


static func _known_state_label(state: String) -> String:
	match state:
		"cleared":
			return "已清理"
		"explored":
			return "已探索"
		"scanned":
			return "已扫描"
		"unknown":
			return "未知"
		_:
			return state


static func _room_type_label(room_type: String) -> String:
	match room_type:
		"Unknown", "unknown", "":
			return "未知房间"
		"Spawn":
			return "出发点"
		"Normal":
			return "普通房"
		"Mine":
			return "雷险房"
		"Monster":
			return "怪物房"
		"Chest":
			return "宝箱房"
		"Event":
			return "事件房"
		"Exit":
			return "撤离点"
		_:
			return "未知房间"


static func _reason_label(reason: String) -> String:
	match reason:
		"current_room":
			return "当前所在房间"
		"scanned_not_explored":
			return "已扫描但未探索"
		"mine_not_fast_return":
			return "雷险房不可回传"
		"use_movement_to_explore":
			return "使用移动进入探索"
		"blocked_unknown":
			return "未知房间不可回传"
		"blocked_scanned_only":
			return "仅扫描不可回传"
		"not_fast_return_target":
			return "不是可回传目标"
		_:
			return reason


static func _join_lines(lines: Array[String]) -> String:
	var text := ""
	for index in range(lines.size()):
		if index > 0:
			text += "\n"
		text += lines[index]
	return text


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
	var known_state := String(cell.get("known_state", "unknown"))
	var adjacent := int(cell.get("adjacent_mines", -1))
	if known_state == "unknown" or adjacent < 0 or adjacent > 8:
		adjacent = -1
	return "格子 (%d,%d) · %s\n周围雷险 %s" % [
		pos.x,
		pos.y,
		_known_state_label(known_state),
		str(adjacent) if adjacent >= 0 else "未知",
	]


static func _public_extent(public_cells: Array, horizontal: bool) -> int:
	var extent := 0
	for cell_variant in public_cells:
		if not (cell_variant is Dictionary):
			continue
		var pos: Vector2i = (cell_variant as Dictionary).get("pos", Vector2i(-1, -1))
		var coordinate := pos.x if horizontal else pos.y
		if coordinate >= 0:
			extent = maxi(extent, coordinate + 1)
	return extent
