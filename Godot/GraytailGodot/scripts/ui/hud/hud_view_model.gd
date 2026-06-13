extends RefCounted
class_name HUDViewModel

# HUD receives public snapshots only. It must not read TruthMap.

var run_label: String = ""
var status_text: String = ""
var protocol_text: String = ""
var hint_text: String = ""
var room_hint: String = ""
var risk_key: StringName = &"ui.accent"
const LEGACY_STATUS_VALIDATION_MARKERS := ["HP:", "Power:", "Pressure:", "Position:", "Room:", "Adjacent Mines:", "Enemy/Event/Exit Hint:", "Search:"]


func clear() -> void:
	run_label = ""
	status_text = ""
	protocol_text = ""
	hint_text = ""
	room_hint = ""
	risk_key = &"ui.accent"


static func build_status(context: RunContext) -> HUDViewModel:
	if context == null:
		var model := HUDViewModel.new()
		model.status_text = "暂无进行中的探索。"
		model.protocol_text = "压力：-"
		model.hint_text = "最新记录：-"
		return model
	return build_from_snapshot(context.get_status_snapshot())


static func build_from_snapshot(snapshot: Dictionary) -> HUDViewModel:
	var model := HUDViewModel.new()
	var pos: Vector2i = snapshot.get("position", Vector2i.ZERO)
	var inventory_items: Array = snapshot.get("inventory_items", [])
	var equipped_items: Array = snapshot.get("equipped_items", [])
	var status_effects: Array = snapshot.get("status_effects", [])
	model.run_label = "%s / %s" % [String(snapshot.get("run_id", &"")), String(snapshot.get("mode", &""))]
	model.status_text = "生命：%s/%s\n作业强度：%s\n待结算黑币：%s / 安全金币：%s\n黑币：%s / 金币：%s\n物品：背包 %s / 装备 %s\n背包：%s/%s（剩余 %s）\n地面物品：%s\n位置：(%d,%d)\n房间：%s\n周围雷险：%s\n搜索状态：%s" % [
		snapshot.get("hp", 0),
		snapshot.get("max_hp", 0),
		snapshot.get("power", 0),
		snapshot.get("pending_gold", 0),
		snapshot.get("safe_gold", 0),
		snapshot.get("black_coin", snapshot.get("pending_gold", 0)),
		snapshot.get("gold_coin", snapshot.get("safe_gold", 0)),
		inventory_items.size(),
		equipped_items.size(),
		snapshot.get("backpack_used", 0),
		snapshot.get("backpack_capacity", 0),
		snapshot.get("backpack_remaining", 0),
		snapshot.get("room_floor_item_count", 0),
		pos.x,
		pos.y,
		_room_type_label(StringName(snapshot.get("current_room", &"Unknown"))),
		snapshot.get("adjacent_mines", 0),
		_search_state_label(String(snapshot.get("search_state", "blocked"))),
	]
	model.protocol_text = "压力：%s / 100\n协议等级：%s\n阶段：%s\n结果：%s\n遭遇：%s\n状态效果：%s" % [
		snapshot.get("pressure", 0),
		snapshot.get("protocol_level", 5),
		_phase_label(StringName(snapshot.get("phase", &"idle"))),
		_outcome_label(String(snapshot.get("outcome", "Running"))),
		_encounter_label(StringName(snapshot.get("encounter_type", &"none"))),
		status_effects.size(),
	]
	var popup: Dictionary = snapshot.get("tutorial_popup", {})
	var event_state: Dictionary = snapshot.get("event_state", {})
	var enemy_state: Dictionary = snapshot.get("enemy_state", {})
	var popup_text := ""
	if not popup.is_empty():
		popup_text = "\n教学提示：%s\n%s" % [String(popup.get("id", "")), String(popup.get("message", ""))]
	var event_text := ""
	if not event_state.is_empty():
		event_text = "\n事件：%s" % _event_label(StringName(event_state.get("event_type", &"event")))
	var enemy_text := ""
	if not enemy_state.is_empty():
		enemy_text = "\n异常体强度：%s / 作业强度：%s" % [enemy_state.get("enemy_power", 0), enemy_state.get("player_power", 0)]
	var blocked_text := ""
	if String(snapshot.get("blocked_reason", "")) != "":
		blocked_text = "\n阻塞：%s" % String(snapshot.get("blocked_reason", ""))
	model.room_hint = PresentationMapping.hint_for_snapshot(snapshot)
	model.risk_key = PresentationTheme.risk_key(int(snapshot.get("adjacent_mines", 0)), StringName(snapshot.get("current_room", &"Unknown")))
	model.hint_text = "房间提示：%s\n最新记录：%s%s%s%s%s" % [
		model.room_hint,
		_player_message(String(snapshot.get("last_message", ""))),
		event_text,
		enemy_text,
		popup_text,
		blocked_text,
	]
	return model


static func _room_type_label(room_type: StringName) -> String:
	match room_type:
		&"Spawn":
			return "出发点"
		&"Normal":
			return "普通房间"
		&"Mine":
			return "雷险房间"
		&"Chest":
			return "物资箱房间"
		&"Event":
			return "事件房间"
		&"Monster":
			return "异常体房间"
		&"Exit":
			return "撤离点"
		_:
			return String(room_type)


static func _search_state_label(search_state: String) -> String:
	match search_state:
		"available":
			return "可搜索"
		"searched":
			return "已搜索"
		"blocked":
			return "不可搜索"
		_:
			return search_state


static func _phase_label(phase: StringName) -> String:
	match phase:
		&"idle":
			return "待命"
		&"running":
			return "探索中"
		&"result":
			return "结算"
		_:
			return String(phase)


static func _outcome_label(outcome: String) -> String:
	match outcome:
		"Running":
			return "探索中"
		"Extracted":
			return "已撤离"
		"Failed":
			return "信号中断"
		_:
			return outcome


static func _encounter_label(encounter_type: StringName) -> String:
	match encounter_type:
		&"none":
			return "无"
		&"mine":
			return "雷险"
		&"event":
			return "事件"
		&"monster":
			return "异常体"
		&"chest":
			return "物资箱"
		_:
			return String(encounter_type)


static func _event_label(event_type: StringName) -> String:
	match event_type:
		&"trader":
			return "临时交易"
		&"dice":
			return "风险骰子"
		&"altar":
			return "协议祭坛"
		&"trap":
			return "机关陷阱"
		_:
			return String(event_type)


static func _player_message(message: String) -> String:
	var text := message.strip_edges()
	if text == "":
		return "-"
	text = text.replace("Exit room ready. Request extraction.", "撤离点已就绪：可请求撤离。")
	text = text.replace("Monster present. Fight is available.", "发现异常体：可执行清理。")
	text = text.replace("Chest can be searched.", "发现未登记物资箱：可搜索。")
	text = text.replace("Search complete:", "搜索完成：")
	text = text.replace("Monster cleared:", "异常体已清理：")
	text = text.replace("Mine triggered:", "雷险触发：")
	text = text.replace("Event available:", "发现事件：")
	text = text.replace("Entered ", "进入")
	text = text.replace(" room. Adjacent mines:", "房间；周围雷险：")
	text = text.replace("black coin", "待结算黑币")
	text = text.replace("items", "物品")
	text = text.replace("on room floor", "留在地面")
	text = text.replace("damage", "伤害")
	text = text.replace("reward", "奖励")
	text = text.replace("pressure", "压力")
	text = text.replace("HP", "生命")
	return text
