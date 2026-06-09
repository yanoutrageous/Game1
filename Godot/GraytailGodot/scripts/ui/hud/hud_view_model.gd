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
	var model := HUDViewModel.new()
	if context == null:
		model.status_text = "暂无出勤。"
		model.protocol_text = "锁定压力：--"
		model.hint_text = "行动记录：--"
		return model

	var snapshot := context.get_status_snapshot()
	var pos: Vector2i = snapshot.get("position", Vector2i.ZERO)
	model.run_label = "%s / %s" % [String(snapshot.get("run_id", &"")), String(snapshot.get("mode", &""))]
	model.status_text = "生命：%s/%s\n战斗力：%s\n结算币：待结算 %s / 安全 %s\n回收物：%s\n坐标：(%d,%d)\n房间：%s\n周围雷险：%s\n搜索：%s" % [
		snapshot.get("hp", 0),
		snapshot.get("max_hp", 0),
		snapshot.get("power", 0),
		snapshot.get("pending_gold", 0),
		snapshot.get("safe_gold", 0),
		snapshot.get("parts", 0),
		pos.x,
		pos.y,
		String(snapshot.get("current_room", &"Unknown")),
		snapshot.get("adjacent_mines", 0),
		String(snapshot.get("search_state", "blocked")),
	]
	model.protocol_text = "锁定压力：%s / 100\n协议等级：%s\n阶段：%s\n状态：%s" % [
		snapshot.get("pressure", 0),
		snapshot.get("protocol_level", 5),
		String(snapshot.get("phase", &"idle")),
		snapshot.get("outcome", "Running"),
	]
	var popup: Dictionary = snapshot.get("tutorial_popup", {})
	var event_state: Dictionary = snapshot.get("event_state", {})
	var enemy_state: Dictionary = snapshot.get("enemy_state", {})
	var popup_text := ""
	if not popup.is_empty():
		popup_text = "\n教程：%s\n%s" % [String(popup.get("id", "")), String(popup.get("message", ""))]
	var event_text := ""
	if not event_state.is_empty():
		event_text = "\n事件：%s" % String(event_state.get("event_type", ""))
	var enemy_text := ""
	if not enemy_state.is_empty():
		enemy_text = "\n异常体战力：%s / 我方战力：%s" % [enemy_state.get("enemy_power", 0), enemy_state.get("player_power", 0)]
	model.room_hint = PresentationMapping.hint_for_snapshot(snapshot)
	model.risk_key = PresentationTheme.risk_key(int(snapshot.get("adjacent_mines", 0)), StringName(snapshot.get("current_room", &"Unknown")))
	model.hint_text = "房间提示：%s\n行动记录：%s%s%s%s" % [
		model.room_hint,
		String(snapshot.get("last_message", "")),
		event_text,
		enemy_text,
		popup_text,
	]
	return model
