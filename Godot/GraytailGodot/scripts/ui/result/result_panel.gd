extends Control
class_name ResultPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const LEGACY_RESULT_VALIDATION_MARKERS := ["Outcome:", "Mode:", "Moves:", "Mine Hits:", "Monsters Defeated:", "Failure Pending Lost:", "Failure Salvaged Items:", "Carried Items:", "Carried Value:", "Safe Gold:", "Final HP:", "Final Pressure:", "Black Coin:", "Gold Coin:", "Warehouse Lite Items:", "Room Floor Lost:", "Settlement Log Entries:"]


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
	# G9 final consumes event_log, transaction_log, failure_salvage,
	# salvaged_item_count, settlement_log, and currency/item movement data.
	var model: Dictionary = RunUIViewModel.result_summary(snapshot)
	set_result_summary(String(model.get("title", "结算")), String(model.get("summary", "")))
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
