extends Control
class_name Hud

# UI reads HudViewModel only. UI must not read TruthMap directly.

var view_model: HUDViewModel
var layout_profile: Dictionary = {}


func apply_view_model(next_view_model: HUDViewModel) -> void:
	view_model = next_view_model
	_apply_labels()


func apply_layout_profile(profile: Dictionary) -> void:
	layout_profile = profile.duplicate(true)
	_apply_labels()


func clear() -> void:
	view_model = null
	_apply_labels()


func _ready() -> void:
	_ensure_asset_backdrops()
	_apply_labels()


func _apply_labels() -> void:
	var status_panel := get_node_or_null("StatusPanel") as Label
	var protocol_panel := get_node_or_null("ProtocolPanel") as Label
	var hint_panel := get_node_or_null("HintPanel") as Label
	var is_low := bool(layout_profile.get("is_low_resolution", false))
	var is_high := bool(layout_profile.get("is_high_resolution", false))
	var font_size := 12 if is_low else (15 if is_high else 13)
	var line_spacing := 1 if is_low else (3 if is_high else 2)

	if status_panel != null:
		status_panel.custom_minimum_size = Vector2(332, 146) if is_low else (Vector2(360, 170) if is_high else Vector2(344, 158))
		status_panel.add_theme_color_override("font_color", PresentationTheme.text_color())
		status_panel.add_theme_font_size_override("font_size", font_size)
		status_panel.add_theme_constant_override("line_spacing", line_spacing)
		status_panel.text = view_model.status_text if view_model != null else "生命：--"
	if protocol_panel != null:
		protocol_panel.custom_minimum_size = Vector2(332, 86) if is_low else (Vector2(360, 108) if is_high else Vector2(344, 92))
		protocol_panel.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.warning"))
		protocol_panel.add_theme_font_size_override("font_size", font_size)
		protocol_panel.add_theme_constant_override("line_spacing", line_spacing)
		protocol_panel.text = view_model.protocol_text if view_model != null else "压力：--"
	if hint_panel != null:
		hint_panel.custom_minimum_size = Vector2(332, 116) if is_low else (Vector2(360, 138) if is_high else Vector2(344, 124))
		var hint_color := PresentationTheme.color_for_key(view_model.risk_key) if view_model != null else PresentationTheme.text_color()
		hint_panel.add_theme_color_override("font_color", hint_color)
		hint_panel.add_theme_font_size_override("font_size", font_size)
		hint_panel.add_theme_constant_override("line_spacing", line_spacing)
		hint_panel.text = view_model.hint_text if view_model != null else "最新记录：--"


func _ensure_asset_backdrops() -> void:
	_ensure_panel_backdrop("StatusBackdrop", Rect2(8, 246, 356, 164))
	_ensure_panel_backdrop("ProtocolBackdrop", Rect2(8, 418, 356, 100))
	_ensure_panel_backdrop("HintBackdrop", Rect2(8, 526, 356, 154))


func _ensure_panel_backdrop(node_name: String, rect: Rect2) -> void:
	if get_node_or_null(node_name) != null:
		return
	var backdrop := ColorRect.new()
	backdrop.name = node_name
	backdrop.color = PresentationTheme.panel_color()
	backdrop.position = rect.position
	backdrop.size = rect.size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	move_child(backdrop, 0)
