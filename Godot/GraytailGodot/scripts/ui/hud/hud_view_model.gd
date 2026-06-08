extends RefCounted
class_name HUDViewModel

# TruthMap = 真实地图
# IntelMap = 玩家已知情报
# MiniMapViewModel = UI 可读数据
# UI 不得直接读取 TruthMap

var run_label: String = ""
var status_text: String = ""
var protocol_text: String = ""
var hint_text: String = ""


func clear() -> void:
	run_label = ""
	status_text = ""
	protocol_text = ""
	hint_text = ""


static func build_status(context: RunContext) -> HUDViewModel:
	var model := HUDViewModel.new()
	if context == null:
		model.status_text = "No active run."
		model.protocol_text = "Pressure: --"
		model.hint_text = "Last Message: --"
		return model

	var snapshot := context.get_status_snapshot()
	var pos: Vector2i = snapshot.get("position", Vector2i.ZERO)
	model.run_label = String(snapshot.get("run_id", &""))
	model.status_text = "HP: %s/%s\nPending Gold: %s\nPosition: (%d,%d)\nRoom: %s\nAdjacent Mines: %s" % [
		snapshot.get("hp", 0),
		snapshot.get("max_hp", 0),
		snapshot.get("pending_gold", 0),
		pos.x,
		pos.y,
		String(snapshot.get("current_room", &"Unknown")),
		snapshot.get("adjacent_mines", 0),
	]
	model.protocol_text = "Pressure: %s\nOutcome: %s" % [
		snapshot.get("pressure", 0),
		snapshot.get("outcome", "Running"),
	]
	model.hint_text = "Last Message: %s" % String(snapshot.get("last_message", ""))
	return model
