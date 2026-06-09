extends Control
class_name ResultPanel

const LEGACY_RESULT_VALIDATION_MARKERS := ["Outcome:", "Mode:", "Moves:", "Mine Hits:", "Monsters Defeated:", "Failure Pending Lost:", "Failure Salvaged Items:", "Carried Items:", "Carried Value:", "Safe Gold:", "Final HP:", "Final Pressure:"]


func _ready() -> void:
	_ensure_backdrop()


func set_result_summary(title: String, summary: String) -> void:
	var title_node := get_node_or_null("ResultTitle") as Label
	var summary_node := get_node_or_null("ResultSummary") as Label

	if title_node != null:
		title_node.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
		title_node.text = title

	if summary_node != null:
		summary_node.add_theme_color_override("font_color", PresentationTheme.text_color())
		summary_node.text = summary


func show_summary(snapshot: Dictionary) -> void:
	var pos: Vector2i = snapshot.get("position", Vector2i.ZERO)
	var stats: Dictionary = snapshot.get("stats", {})
	var salvage: Dictionary = snapshot.get("failure_salvage", {})
	var title := "撤离结算"
	if String(snapshot.get("outcome", "Running")) != "Extracted":
		title = "信号中断"
	var summary := "结果：%s\n模式：%s\n安全回收：%s\n待结算：%s\n回收物：%s\n携带物品：%s\n携带价值：%s\n失败损失待结算：%s\n失败抢救物资：%s\n最终生命：%s/%s\n最终压力：%s\n协议：%s\n最终坐标：(%d,%d)\n移动：%s\n搜索：%s\n触雷：%s\n击败异常体：%s\n完成事件：%s" % [
		snapshot.get("outcome", "Unknown"),
		String(snapshot.get("mode", &"")),
		snapshot.get("safe_gold", 0),
		snapshot.get("pending_gold", 0),
		snapshot.get("parts", 0),
		snapshot.get("carried_item_count", 0),
		snapshot.get("carried_item_value", 0),
		salvage.get("pending_gold_lost", 0),
		salvage.get("salvaged_item_count", 0),
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
	set_result_summary(title, summary)
	visible = true


func hide_result() -> void:
	visible = false


func _ensure_backdrop() -> void:
	if get_node_or_null("Backdrop") != null:
		return
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = PresentationTheme.panel_color()
	backdrop.position = Vector2(-8, -8)
	backdrop.size = Vector2(636, 456)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	move_child(backdrop, 0)
