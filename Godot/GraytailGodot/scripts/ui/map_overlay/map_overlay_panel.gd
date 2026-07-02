extends Control
class_name MapOverlayPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")

signal cell_action_requested(marker: Dictionary)

var view_model: MiniMapViewModel
var selected_feedback_text: String = ""
var selected_marker: Dictionary = {}
var layout_profile: Dictionary = {}
var marker_size: Vector2 = Vector2(42, 42)
var title_font_size: int = 20
var footer_font_size: int = 13
const LEGACY_MAP_OVERLAY_VALIDATION_MARKER := "Click hidden cells to flag"


func apply_view_model(next_view_model: MiniMapViewModel) -> void:
	view_model = next_view_model
	_rebuild_grid()


func apply_layout_profile(profile: Dictionary) -> void:
	layout_profile = profile.duplicate(true)
	var is_low := bool(layout_profile.get("is_low_resolution", false))
	var is_high := bool(layout_profile.get("is_high_resolution", false))
	var supported_size: Vector2 = layout_profile.get("supported_size", Vector2(1280, 720))
	var actual_size: Vector2i = layout_profile.get("actual_viewport_size", Vector2i(int(supported_size.x), int(supported_size.y)))
	var width: float = float(max(1, actual_size.x))
	var height: float = float(max(1, actual_size.y))
	title_font_size = 16 if is_low else (20 if is_high else 18)
	footer_font_size = 11 if is_low else (13 if is_high else 12)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	var dimmer := get_node_or_null("Dimmer") as ColorRect
	if dimmer != null:
		dimmer.color = Color(0.0, 0.0, 0.0, 0.58)
	var panel := get_node_or_null("Panel") as Control
	if panel != null:
		var panel_width: float = min(width * 0.74, 980.0 if is_high else 760.0)
		var panel_height: float = min(height * 0.86, 820.0 if is_high else 620.0)
		panel_width = max(panel_width, 620.0 if not is_low else 540.0)
		panel_height = max(panel_height, 500.0 if not is_low else 440.0)
		var cell_width: float = floor((panel_width - 84.0) / 10.0)
		var cell_height: float = floor((panel_height - 140.0) / 10.0)
		var cell_size: float = maxf(42.0, min(cell_width, cell_height))
		marker_size = Vector2(cell_size, cell_size)
		panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_set_rect(panel, Rect2((width - panel_width) * 0.5, (height - panel_height) * 0.5, panel_width, panel_height))
		_apply_overlay_panel_style(panel)
	_rebuild_grid()


func show_overlay() -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if get_parent() != null:
		get_parent().move_child(self, get_parent().get_child_count() - 1)
	_rebuild_grid()


func hide_overlay() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().gui_release_focus()


func toggle_overlay() -> void:
	if visible:
		hide_overlay()
	else:
		show_overlay()


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_layer_order()
	_rebuild_grid()


func _apply_layer_order() -> void:
	z_as_relative = true
	z_index = 0
	var dimmer := get_node_or_null("Dimmer") as CanvasItem
	if dimmer != null:
		dimmer.z_as_relative = true
		dimmer.z_index = 0
		if dimmer is Control:
			(dimmer as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := get_node_or_null("Panel") as CanvasItem
	if panel != null:
		panel.z_as_relative = true
		panel.z_index = 10


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel") or _event_matches_key(event, [KEY_ESCAPE]):
		hide_overlay()
		get_viewport().set_input_as_handled()


func _rebuild_grid() -> void:
	var grid := get_node_or_null("Panel/Content/Grid") as GridContainer
	var title := get_node_or_null("Panel/Content/Title") as Label
	var detail := _ensure_detail_label()
	var footer := get_node_or_null("Panel/Content/Footer") as Label
	if grid == null:
		return
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	for child in grid.get_children():
		child.queue_free()

	if title != null:
		title.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
		title.add_theme_font_size_override("font_size", title_font_size)
		title.text = "区域地图"
	if detail != null:
		detail.add_theme_color_override("font_color", PresentationTheme.text_color())
		detail.add_theme_font_size_override("font_size", 11 if footer_font_size <= 12 else 12)
		detail.add_theme_constant_override("line_spacing", 2)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.text = _selected_detail_text()
	if footer != null:
		footer.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
		footer.add_theme_font_size_override("font_size", footer_font_size)
		footer.add_theme_constant_override("line_spacing", 2)
		footer.text = "Esc 关闭 · 点击格子查看 / 标记"

	if footer != null and selected_feedback_text != "":
		footer.text += "\n" + selected_feedback_text

	if view_model == null:
		return

	grid.columns = max(1, view_model.width)
	for marker in view_model.room_markers:
		_add_marker_node(grid, marker)


func _add_marker_node(grid: GridContainer, marker: Dictionary) -> void:
	var theme_key := StringName(marker.get("theme_key", &"mini.normal"))
	var label_text := String(marker.get("label", "?"))
	var button := Button.new()
	button.custom_minimum_size = marker_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.text = label_text
	button.tooltip_text = ""
	var marker_color := PresentationTheme.color_for_key(theme_key)
	if label_text == "?":
		marker_color = Color(0.58, 0.72, 0.68, 0.74)
	button.add_theme_color_override("font_color", marker_color)
	button.add_theme_font_size_override("font_size", maxi(12, int(min(marker_size.x, marker_size.y) * 0.52)))
	_apply_marker_button_style(button, theme_key)
	var texture := Art09ManifestAssetMappingScript.resolve_texture(Art21UIPlacementContractScript.map_ref(_art21_marker_state(marker)))
	if texture != null:
		button.icon = texture
		button.expand_icon = false
		button.add_theme_constant_override("icon_max_width", int(min(marker_size.x, marker_size.y) * 0.78))
		button.text = "" if label_text != "P" else "P"
	button.pressed.connect(func() -> void: _select_marker(marker))
	grid.add_child(button)


func _set_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y


func _apply_overlay_panel_style(control: Control) -> void:
	if not (control is PanelContainer):
		return
	var panel := control as PanelContainer
	panel.add_theme_stylebox_override("panel", Art10UISkinKitScript.panel_style(&"deep"))


func _apply_marker_button_style(button: Button, theme_key: StringName) -> void:
	var border := PresentationTheme.color_for_key(theme_key)
	button.add_theme_stylebox_override("normal", _marker_style(Color(0.030, 0.035, 0.044, 0.98), border, 1))
	button.add_theme_stylebox_override("hover", _marker_style(Color(0.064, 0.070, 0.086, 1.0), border, 2))
	button.add_theme_stylebox_override("pressed", _marker_style(Color(0.082, 0.078, 0.054, 1.0), PresentationTheme.color_for_key(&"ui.warning"), 2))
	button.add_theme_color_override("font_color", border)


func _art21_marker_state(marker: Dictionary) -> StringName:
	var asset_id := String(marker.get("asset_id", "")).to_lower()
	var room_type := String(marker.get("room_type", "")).to_lower()
	if bool(marker.get("is_current", false)) or asset_id.find("player") >= 0:
		return &"player"
	if bool(marker.get("flagged", false)) or asset_id.find("flag") >= 0:
		return &"flagged"
	if room_type == "event" or asset_id.find("event") >= 0:
		return &"event"
	if room_type == "mine" or room_type == "monster" or asset_id.find("mine") >= 0 or asset_id.find("monster") >= 0:
		return &"mine"
	if room_type == "chest" or asset_id.find("chest") >= 0:
		return &"chest"
	if room_type == "exit" or asset_id.find("exit") >= 0 or asset_id.find("extract") >= 0:
		return &"exit"
	if not bool(marker.get("revealed", true)) or String(marker.get("label", "")) == "?":
		return &"unknown"
	if bool(marker.get("scanned", false)) or int(marker.get("adjacent_mines", -1)) > 0:
		return &"scanned"
	return &"explored"


func _marker_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	return style


func _event_matches_key(event: InputEvent, keycodes: Array) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	for keycode: int in keycodes:
		if key_event.physical_keycode == keycode or key_event.keycode == keycode:
			return true
	return false


func show_action_feedback(marker: Dictionary, result: Dictionary) -> void:
	selected_marker = marker.duplicate(true)
	var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
	var accepted: bool = bool(result.get("accepted", result.get("ok", false)))
	var reason: String = String(result.get("reason_code", result.get("reason", "")))
	if accepted:
		selected_feedback_text = "地图记录：已选择 (%d,%d)，操作已确认。" % [pos.x, pos.y]
	else:
		selected_feedback_text = "地图记录：已选择 (%d,%d)，%s" % [pos.x, pos.y, RunUIViewModel.reason_label(reason)]
	_rebuild_grid()


func show_open_feedback(source: StringName) -> void:
	selected_feedback_text = "地图已展开。"
	_rebuild_grid()


func _select_marker(marker: Dictionary) -> void:
	selected_marker = marker.duplicate(true)
	selected_feedback_text = ""
	cell_action_requested.emit(marker.duplicate(true))
	_rebuild_grid()


func _ensure_detail_label() -> Label:
	var content := get_node_or_null("Panel/Content") as VBoxContainer
	if content == null:
		return null
	var detail := get_node_or_null("Panel/Content/Detail") as Label
	if detail != null:
		return detail
	detail = Label.new()
	detail.name = "Detail"
	detail.custom_minimum_size = Vector2(0, 34)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(detail)
	var grid := get_node_or_null("Panel/Content/Grid")
	if grid != null:
		content.move_child(detail, grid.get_index())
	return detail


func _selected_detail_text() -> String:
	if selected_marker.is_empty():
		return "点击格子查看状态。"
	return String(selected_marker.get("detail_text", "选中格详情不可用。"))
