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
		marker = build_cell_view_model(marker, player_pos)
		model.room_markers.append(marker)
	return model


static func build_from_run_map_snapshot(snapshot: Dictionary) -> MiniMapViewModel:
	var model := MiniMapViewModel.new()
	model.map_snapshot = snapshot.duplicate(true)
	var run_map: Dictionary = snapshot.get("RunMap", {})
	model.width = int(run_map.get("width", 0))
	model.height = int(run_map.get("height", 0))
	var player_pos: Vector2i = run_map.get("player_pos", Vector2i(-1, -1))
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
		marker = build_cell_view_model(marker, player_pos)
		model.room_markers.append(marker)
	return model


static func build_cell_view_model(raw_marker: Dictionary, player_pos: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var marker := raw_marker.duplicate(true)
	var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
	var known_state := StringName(marker.get("known_state", marker.get("state", &"unknown")))
	var revealed := bool(marker.get("revealed", false)) or known_state in [&"explored", &"cleared"]
	var explored := bool(marker.get("explored", false)) or known_state in [&"explored", &"cleared"]
	var cleared := bool(marker.get("cleared", false)) or known_state == &"cleared"
	var scanned := bool(marker.get("scanned", false)) or known_state == &"scanned"
	var flagged := bool(marker.get("flagged", false))
	var is_current := bool(marker.get("is_current", false)) or (player_pos.x >= 0 and pos == player_pos)
	var distance: int = abs(pos.x - player_pos.x) + abs(pos.y - player_pos.y) if player_pos.x >= 0 else -1
	var return_eligibility: Dictionary = marker.get("return_eligibility", {})
	var room_type := StringName(marker.get("room_type", &"Unknown"))
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
	marker["tooltip"] = "%s\n%s" % [String(marker.get("tooltip", "")), String(marker.get("detail_text", ""))]
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
	if explored and bool(return_eligibility.get("eligible", return_eligibility.get("fast_return", false))) and room_type != &"Mine":
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
	var lines: Array[String] = [
		"格子 (%d,%d) | 状态 %s | 房型 %s" % [pos.x, pos.y, _known_state_label(state), _room_type_label(room_type)],
		"周边雷险：%s | 与当前位置距离：%s" % [str(adjacent) if adjacent >= 0 else "未知", str(distance) if distance >= 0 else "未知"],
		"动作：%s%s" % [action_label, "" if reason == "" else "（%s）" % _reason_label(reason)],
	]
	if bool(marker.get("flagged", false)):
		lines.append("标记：疑似危险；再次点击可取消标记。")
	elif not bool(marker.get("revealed", false)):
		lines.append("未知格：不能直接进入；相邻时请通过移动探索，非相邻可先标记。")
	elif bool(marker.get("scanned", false)) and not bool(marker.get("explored", false)):
		lines.append("已扫描未探索：信息可见，但不能回传。")
	elif bool(marker.get("explored", false)):
		lines.append("已探索：安全公开房间可尝试回传，雷险房只允许查看。")
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
			return room_type


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
	var return_eligibility: Dictionary = cell.get("return_eligibility", {})
	return "RoomState %s at (%d,%d), return_eligibility=%s" % [
		String(cell.get("known_state", "unknown")),
		pos.x,
		pos.y,
		String(return_eligibility.get("reason_code", "unknown")),
	]
