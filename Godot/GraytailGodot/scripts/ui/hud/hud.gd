extends Control
class_name Hud

# UI reads HudViewModel only. UI must not read TruthMap directly.

var view_model: HUDViewModel


func apply_view_model(next_view_model: HUDViewModel) -> void:
	view_model = next_view_model
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

	if status_panel != null:
		status_panel.custom_minimum_size = Vector2(380, 210)
		status_panel.add_theme_color_override("font_color", PresentationTheme.text_color())
		status_panel.text = view_model.status_text if view_model != null else "HP: --"
	if protocol_panel != null:
		protocol_panel.custom_minimum_size = Vector2(380, 110)
		protocol_panel.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.warning"))
		protocol_panel.text = view_model.protocol_text if view_model != null else "Pressure: --"
	if hint_panel != null:
		hint_panel.custom_minimum_size = Vector2(560, 100)
		var hint_color := PresentationTheme.color_for_key(view_model.risk_key) if view_model != null else PresentationTheme.text_color()
		hint_panel.add_theme_color_override("font_color", hint_color)
		hint_panel.text = view_model.hint_text if view_model != null else "Last Message: --"


func _ensure_asset_backdrops() -> void:
	_ensure_texture_backdrop("StatusBackdrop", &"ui.hud.panel.left", Rect2(8, 224, 392, 224))
	_ensure_texture_backdrop("ProtocolBackdrop", &"ui.hud.panel.protocol", Rect2(8, 264, 392, 128))
	_ensure_texture_backdrop("HintBackdrop", &"ui.hud.bottom_bar", Rect2(392, 600, 560, 104))


func _ensure_texture_backdrop(node_name: String, asset_id: StringName, rect: Rect2) -> void:
	if get_node_or_null(node_name) != null:
		return
	var asset_ref := ContentDB.get_asset_ref(asset_id)
	if asset_ref is Texture2D:
		var texture_rect := TextureRect.new()
		texture_rect.name = node_name
		texture_rect.texture = asset_ref
		texture_rect.position = rect.position
		texture_rect.size = rect.size
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(texture_rect)
		move_child(texture_rect, 0)
