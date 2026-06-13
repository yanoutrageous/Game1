extends RefCounted
class_name RunSurfaceModel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const PresentationTheme := preload("res://scripts/presentation/presentation_theme.gd")


static func build(snapshot: Dictionary, minimap_view_model: MiniMapViewModel, layout_profile: Dictionary, last_command_result: Dictionary) -> Dictionary:
	var position: Vector2i = snapshot.get("position", snapshot.get("player_pos", Vector2i.ZERO))
	var room_type := StringName(snapshot.get("current_room", &"Unknown"))
	var adjacent_mines := int(snapshot.get("adjacent_mines", 0))
	var event_state: Dictionary = _dict_from(snapshot, "event_state")
	var search_data: Dictionary = _dict_from(snapshot, "search_state_data")
	var reward: Dictionary = _dict_from(snapshot, "last_reward")
	var last_message := String(snapshot.get("last_message", ""))
	var command_feedback := RunUIViewModel.command_result_text(last_command_result)
	if command_feedback == "":
		command_feedback = _player_message(last_message)

	return {
		"room_title": _room_label(room_type),
		"room_type": room_type,
		"room_position": position,
		"room_coordinate": "(%d,%d)" % [position.x, position.y],
		"room_summary": _room_summary(snapshot, room_type, adjacent_mines),
		"current_objective": _objective_for_room(room_type, search_data, event_state),
		"protocol_level": snapshot.get("protocol_level", 5),
		"pressure": snapshot.get("pressure", 0),
		"danger_label": _danger_label(room_type, adjacent_mines),
		"danger_theme_key": PresentationTheme.risk_key(adjacent_mines, room_type),
		"event_summary": _event_summary(event_state),
		"search_summary": _search_summary(search_data, String(snapshot.get("search_state", "blocked"))),
		"reward_summary": RunUIViewModel.reward_text(reward, last_message),
		"backpack_summary": _backpack_summary(snapshot),
		"resource_summary": _resource_summary(snapshot),
		"command_feedback": command_feedback,
		"scanner_summary": _scanner_summary(minimap_view_model, position),
		"scanner_markers": _scanner_markers(minimap_view_model),
		"action_buttons": _action_buttons(snapshot, search_data, event_state, room_type),
		"layout_profile": layout_profile.duplicate(true),
	}


static func _action_buttons(snapshot: Dictionary, search_data: Dictionary, event_state: Dictionary, room_type: StringName) -> Array[Dictionary]:
	var run_active := bool(snapshot.get("run_active", false))
	var phase := StringName(snapshot.get("phase", &"idle"))
	var has_event := not event_state.is_empty()
	var can_search := bool(search_data.get("can_search", false))
	var floor_count := int(snapshot.get("room_floor_item_count", 0))
	return [
		_action(&"interact", "搜索 / 交互", run_active and (can_search or has_event or room_type == &"Exit"), _interact_hint(room_type, search_data, has_event)),
		_action(&"inventory", "背包", run_active, "查看背包和装备摘要。"),
		_action(&"ground_loot", "地面物品", run_active and floor_count > 0, "查看当前房间地面物品。"),
		_action(&"map", "区域扫描", run_active, "打开大地图扫描视图。"),
		_action(&"combat", "清理威胁", run_active and room_type == &"Monster", "当前房间存在可清理威胁时可用。"),
		_action(&"extract", "撤离", run_active and (room_type == &"Exit" or phase == &"confirm_extract"), "在撤离点请求或确认撤离。"),
		_action(&"pause", "暂停", run_active, "打开暂停和设置入口。"),
	]


static func _action(action_id: StringName, label: String, enabled: bool, description: String) -> Dictionary:
	return {
		"id": action_id,
		"label": label,
		"enabled": enabled,
		"description": description,
	}


static func _room_summary(snapshot: Dictionary, room_type: StringName, adjacent_mines: int) -> String:
	var lines: Array[String] = []
	lines.append("模式：%s | 阶段：%s" % [String(snapshot.get("mode", &"")), String(snapshot.get("phase", &""))])
	lines.append("房间：%s | 周边危险：%s" % [_room_label(room_type), adjacent_mines])
	lines.append("状态：%s | 地面物品：%s" % [String(snapshot.get("outcome", "Running")), snapshot.get("room_floor_item_count", 0)])
	return _join_lines(lines)


static func _objective_for_room(room_type: StringName, search_data: Dictionary, event_state: Dictionary) -> String:
	if not event_state.is_empty():
		return "处理当前事件选项，或关闭后继续探索。"
	if bool(search_data.get("can_search", false)):
		return "搜索当前房间，回收可用物资。"
	match room_type:
		&"Exit":
			return "撤离点已发现，确认带出资源。"
		&"Monster":
			return "清理威胁后继续推进。"
		&"Mine":
			return "雷险区域，谨慎穿越并观察扫描器。"
		&"Spawn":
			return "从出发点向未知区域推进。"
		_:
			return "继续移动、扫描和记录区域状态。"


static func _danger_label(room_type: StringName, adjacent_mines: int) -> String:
	if room_type == &"Mine":
		return "雷险确认"
	if room_type == &"Monster":
		return "威胁接触"
	if adjacent_mines >= 3:
		return "高危邻近"
	if adjacent_mines >= 1:
		return "风险邻近"
	return "暂稳"


static func _event_summary(event_state: Dictionary) -> String:
	if event_state.is_empty():
		return "事件：无待处理事件。"
	var event_type := String(event_state.get("event_type", event_state.get("type", "event")))
	var option_count := 0
	var options: Variant = event_state.get("options", [])
	if options is Array:
		option_count = (options as Array).size()
	return "事件：%s | 可选项：%s" % [event_type, option_count]


static func _search_summary(search_data: Dictionary, search_state: String) -> String:
	if search_data.is_empty():
		return "搜索：暂无公开搜索状态。"
	if bool(search_data.get("searched", false)):
		return "搜索：当前房间已搜索。"
	if bool(search_data.get("can_search", false)):
		return "搜索：可执行，原因 %s。" % String(search_data.get("reason", search_state))
	return "搜索：不可执行，原因 %s。" % String(search_data.get("reason", search_state))


static func _backpack_summary(snapshot: Dictionary) -> String:
	var inventory_items: Array = _array_from(snapshot, "inventory_items")
	var equipped_items: Array = _array_from(snapshot, "equipped_items")
	return "背包：%s/%s | 物品 %s | 装备 %s" % [
		snapshot.get("backpack_used", 0),
		snapshot.get("backpack_capacity", 0),
		inventory_items.size(),
		equipped_items.size(),
	]


static func _resource_summary(snapshot: Dictionary) -> String:
	return "黑币 %s | 金币 %s | 零件 %s | HP %s/%s" % [
		snapshot.get("black_coin", 0),
		snapshot.get("gold_coin", 0),
		snapshot.get("parts", 0),
		snapshot.get("hp", 0),
		snapshot.get("max_hp", 0),
	]


static func _scanner_summary(minimap_view_model: MiniMapViewModel, position: Vector2i) -> String:
	if minimap_view_model == null:
		return "扫描器：等待公开地图数据。"
	return "扫描器：%sx%s | 当前坐标 %s,%s | 已知格 %s" % [
		minimap_view_model.width,
		minimap_view_model.height,
		position.x,
		position.y,
		minimap_view_model.room_markers.size(),
	]


static func _scanner_markers(minimap_view_model: MiniMapViewModel) -> Array:
	if minimap_view_model == null:
		return []
	return minimap_view_model.room_markers.duplicate(true)


static func _interact_hint(room_type: StringName, search_data: Dictionary, has_event: bool) -> String:
	if has_event:
		return "打开当前事件选项。"
	if bool(search_data.get("can_search", false)):
		return "搜索当前房间。"
	if room_type == &"Exit":
		return "请求撤离。"
	return "当前房间暂无可交互目标。"


static func _room_label(room_type: StringName) -> String:
	match room_type:
		&"Spawn":
			return "出发点"
		&"Normal":
			return "普通房间"
		&"Mine":
			return "雷险房间"
		&"Chest":
			return "物资箱"
		&"Event":
			return "事件房间"
		&"Monster":
			return "威胁房间"
		&"Exit":
			return "撤离点"
		_:
			return String(room_type)


static func _player_message(message: String) -> String:
	var text := message.strip_edges()
	if text == "":
		return "操作反馈：等待输入。"
	return "操作反馈：%s" % text


static func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


static func _dict_from(source: Dictionary, key: String) -> Dictionary:
	var raw: Variant = source.get(key, {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return {}


static func _join_lines(lines: Array[String]) -> String:
	var text := ""
	for index in range(lines.size()):
		if index > 0:
			text += "\n"
		text += lines[index]
	return text
