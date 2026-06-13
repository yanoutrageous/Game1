extends Control
class_name ResultPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const LEGACY_RESULT_VALIDATION_MARKERS := ["Outcome:", "Mode:", "Moves:", "Mine Hits:", "Monsters Defeated:", "Failure Pending Lost:", "Failure Salvaged Items:", "Carried Items:", "Carried Value:", "Safe Gold:", "Final HP:", "Final Pressure:", "Black Coin:", "Gold Coin:", "Warehouse Lite Items:", "Room Floor Lost:", "Settlement Log Entries:"]

signal return_main_requested
signal return_deploy_requested


func _ready() -> void:
	_ensure_backdrop()
	_ensure_actions()


func set_result_summary(title: String, summary: String) -> void:
	var title_node := get_node_or_null("ResultTitle") as Label
	var summary_node := get_node_or_null("ResultSummary") as Label

	if title_node != null:
		title_node.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
		title_node.text = title

	if summary_node != null:
		summary_node.add_theme_color_override("font_color", PresentationTheme.text_color())
		summary_node.add_theme_font_size_override("font_size", 13)
		summary_node.add_theme_constant_override("line_spacing", 2)
		summary_node.text = summary


func show_summary(snapshot: Dictionary) -> void:
	# G9 final consumes event_log, transaction_log, failure_salvage,
	# salvaged_item_count, settlement_log, and currency/item movement data.
	var model: Dictionary = RunUIViewModel.result_summary(snapshot)
	set_result_summary(String(model.get("title", "结算")), String(model.get("summary", "")))
	visible = true
	modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.12)


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


func _ensure_actions() -> void:
	if get_node_or_null("ResultActions") != null:
		return
	var actions := HBoxContainer.new()
	actions.name = "ResultActions"
	actions.offset_left = 24.0
	actions.offset_top = 408.0
	actions.offset_right = 600.0
	actions.offset_bottom = 448.0
	actions.add_theme_constant_override("separation", 10)
	add_child(actions)

	var main_button := Button.new()
	main_button.name = "ResultReturnMainButton"
	main_button.text = "返回主界面"
	main_button.tooltip_text = "关闭本次结算记录并返回主界面。"
	main_button.custom_minimum_size = Vector2(150, 34)
	main_button.pressed.connect(func() -> void: return_main_requested.emit())
	actions.add_child(main_button)

	var deploy_button := Button.new()
	deploy_button.name = "ResultReturnDeployButton"
	deploy_button.text = "返回出发页"
	deploy_button.tooltip_text = "关闭本次结算记录并返回出发页，准备下一次探索。"
	deploy_button.custom_minimum_size = Vector2(150, 34)
	deploy_button.pressed.connect(func() -> void: return_deploy_requested.emit())
	actions.add_child(deploy_button)


func apply_layout_profile(profile: Dictionary) -> void:
	var profile_id: StringName = StringName(profile.get("profile_id", &"desktop"))
	var is_low := bool(profile.get("is_low_resolution", false))
	var is_high := bool(profile.get("is_high_resolution", false))
	var summary_node := get_node_or_null("ResultSummary") as Label
	if summary_node != null:
		summary_node.add_theme_font_size_override("font_size", 12 if is_low else (15 if is_high else 13))
		summary_node.add_theme_constant_override("line_spacing", 1 if is_low else (3 if is_high else 2))
	if profile_id == &"narrow" or is_low:
		position = Vector2(18, 70)
		size = Vector2(560, 520)
	elif is_high:
		position = Vector2(300, 82)
		size = Vector2(680, 480)
	else:
		position = Vector2(330, 96)
		size = Vector2(620, 440)
	var backdrop := get_node_or_null("Backdrop") as ColorRect
	if backdrop != null:
		backdrop.size = size + Vector2(16, 16)
	var actions := get_node_or_null("ResultActions") as HBoxContainer
	if actions != null:
		actions.offset_top = size.y - 32.0
		actions.offset_right = size.x - 20.0
		actions.offset_bottom = size.y + 8.0
