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
		model.status_text = "No active run."
		model.protocol_text = "Pressure: -"
		model.hint_text = "Last Action: -"
		return model

	var snapshot := context.get_status_snapshot()
	var pos: Vector2i = snapshot.get("position", Vector2i.ZERO)
	var inventory_items: Array = snapshot.get("inventory_items", [])
	var equipped_items: Array = snapshot.get("equipped_items", [])
	var status_effects: Array = snapshot.get("status_effects", [])
	model.run_label = "%s / %s" % [String(snapshot.get("run_id", &"")), String(snapshot.get("mode", &""))]
	model.status_text = "HP: %s/%s\nPower: %s\nPending Gold: %s / Safe Gold: %s\nBlack Coin: %s / Gold Coin: %s\nItems: %s inventory / %s equipped\nBag: %s/%s (%s left)\nFloor Items: %s\nPosition: (%d,%d)\nRoom: %s\nAdjacent Mines: %s\nSearch: %s" % [
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
		String(snapshot.get("current_room", &"Unknown")),
		snapshot.get("adjacent_mines", 0),
		String(snapshot.get("search_state", "blocked")),
	]
	model.protocol_text = "Pressure: %s / 100\nProtocol: %s\nPhase: %s\nOutcome: %s\nEncounter: %s\nBuffs/Debuffs: %s" % [
		snapshot.get("pressure", 0),
		snapshot.get("protocol_level", 5),
		String(snapshot.get("phase", &"idle")),
		snapshot.get("outcome", "Running"),
		String(snapshot.get("encounter_type", &"none")),
		status_effects.size(),
	]
	var popup: Dictionary = snapshot.get("tutorial_popup", {})
	var event_state: Dictionary = snapshot.get("event_state", {})
	var enemy_state: Dictionary = snapshot.get("enemy_state", {})
	var popup_text := ""
	if not popup.is_empty():
		popup_text = "\nTutorial: %s\n%s" % [String(popup.get("id", "")), String(popup.get("message", ""))]
	var event_text := ""
	if not event_state.is_empty():
		event_text = "\nEvent: %s" % String(event_state.get("event_type", ""))
	var enemy_text := ""
	if not enemy_state.is_empty():
		enemy_text = "\nEnemy Power: %s / Player Power: %s" % [enemy_state.get("enemy_power", 0), enemy_state.get("player_power", 0)]
	var blocked_text := ""
	if String(snapshot.get("blocked_reason", "")) != "":
		blocked_text = "\nBlocked: %s" % String(snapshot.get("blocked_reason", ""))
	model.room_hint = PresentationMapping.hint_for_snapshot(snapshot)
	model.risk_key = PresentationTheme.risk_key(int(snapshot.get("adjacent_mines", 0)), StringName(snapshot.get("current_room", &"Unknown")))
	model.hint_text = "Enemy/Event/Exit Hint: %s\nLast Action: %s%s%s%s%s" % [
		model.room_hint,
		String(snapshot.get("last_message", "")),
		event_text,
		enemy_text,
		popup_text,
		blocked_text,
	]
	return model
