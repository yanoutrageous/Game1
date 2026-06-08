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
	var summary := "Outcome: %s\nPending Gold: %s\nFinal HP: %s\nFinal Pressure: %s\nFinal Position: (%d,%d)" % [
		snapshot.get("outcome", "Unknown"),
		snapshot.get("pending_gold", 0),
		snapshot.get("hp", 0),
		snapshot.get("pressure", 0),
		pos.x,
		pos.y,
	]
	set_result_summary("Run Result", summary)
	visible = true


func hide_result() -> void:
	visible = false
