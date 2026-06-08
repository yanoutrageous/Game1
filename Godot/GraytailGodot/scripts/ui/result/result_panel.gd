extends Control
class_name ResultPanel


func set_result_summary(title: String, summary: String) -> void:
	var title_node := get_node_or_null("ResultTitle") as Label
	var summary_node := get_node_or_null("ResultSummary") as Label

	if title_node != null:
		title_node.text = title

	if summary_node != null:
		summary_node.text = summary


func show_summary(snapshot: Dictionary) -> void:
	var pos: Vector2i = snapshot.get("position", Vector2i.ZERO)
	var stats: Dictionary = snapshot.get("stats", {})
	var summary := "Outcome: %s\nMode: %s\nSafe Gold: %s\nPending Gold: %s\nParts: %s\nFinal HP: %s/%s\nFinal Pressure: %s\nProtocol: %s\nFinal Position: (%d,%d)\nMoves: %s\nSearches: %s\nMine Hits: %s\nMonsters Defeated: %s\nEvents Completed: %s" % [
		snapshot.get("outcome", "Unknown"),
		String(snapshot.get("mode", &"")),
		snapshot.get("safe_gold", 0),
		snapshot.get("pending_gold", 0),
		snapshot.get("parts", 0),
		snapshot.get("hp", 0),
		snapshot.get("max_hp", 0),
		snapshot.get("pressure", 0),
		snapshot.get("protocol_level", 5),
		pos.x,
		pos.y,
		stats.get("moves", 0),
		stats.get("searched_rooms", 0),
		stats.get("mine_hits", 0),
		stats.get("monsters_defeated", 0),
		stats.get("events_completed", 0),
	]
	set_result_summary("Run Result", summary)
	visible = true


func hide_result() -> void:
	visible = false
