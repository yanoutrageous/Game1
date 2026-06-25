extends Control
class_name MapOverlayPanel

signal cell_action_requested(marker: Dictionary)

var view_model: MiniMapViewModel
var selected_feedback_text: String = ""
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
	marker_size = Vector2(38, 38) if is_low else (Vector2(48, 48) if is_high else Vector2(42, 42))
	title_font_size = 18 if is_low else (22 if is_high else 20)
	footer_font_size = 12 if is_low else (15 if is_high else 13)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	var panel := get_node_or_null("Panel") as Control
	if panel != null:
		var panel_width: float = min(width - 48.0, 560.0 if is_low else (640.0 if is_high else 600.0))
		var panel_height: float = min(height - 48.0, 560.0 if is_low else (680.0 if is_high else 600.0))
		panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_set_rect(panel, Rect2((width - panel_width) * 0.5, (height - panel_height) * 0.5, panel_width, panel_height))
	_rebuild_grid()


func show_overlay() -> void:
	visible = true
	_rebuild_grid()


func hide_overlay() -> void:
	visible = false


func toggle_overlay() -> void:
	if visible:
		hide_overlay()
	else:
		show_overlay()


func _ready() -> void:
	visible = false
	_rebuild_grid()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cancel") or _event_matches_key(event, [KEY_ESCAPE]):
		hide_overlay()
		get_viewport().set_input_as_handled()


func _rebuild_grid() -> void:
	var grid := get_node_or_null("Panel/Content/Grid") as GridContainer
	var title := get_node_or_null("Panel/Content/Title") as Label
	var footer := get_node_or_null("Panel/Content/Footer") as Label
	if grid == null:
		return

	for child in grid.get_children():
		child.queue_free()

	if title != null:
		title.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
		title.add_theme_font_size_override("font_size", title_font_size)
		title.text = "区域扫描器回顾"
	if footer != null:
		footer.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
		footer.add_theme_font_size_override("font_size", footer_font_size)
		footer.add_theme_constant_override("line_spacing", 2)
		footer.text = "点击未知房间标记风险；点击已探索安全房间尝试快速返回。"

	if footer != null and selected_feedback_text != "":
		footer.text += "\n" + selected_feedback_text

	if view_model == null:
		return

	grid.columns = max(1, view_model.width)
	for marker in view_model.room_markers:
		_add_marker_node(grid, marker)


func _add_marker_node(grid: GridContainer, marker: Dictionary) -> void:
	var asset_id := StringName(marker.get("asset_id", &""))
	var asset_ref := ContentDB.get_asset_ref(asset_id)
	var theme_key := StringName(marker.get("theme_key", &"mini.normal"))
	var button := Button.new()
	button.custom_minimum_size = marker_size
	button.focus_mode = Control.FOCUS_NONE
	button.text = String(marker.get("label", "?"))
	button.tooltip_text = String(marker.get("tooltip", "cell"))
	button.add_theme_color_override("font_color", PresentationTheme.color_for_key(theme_key))
	if asset_ref is Texture2D:
		button.icon = asset_ref
		button.expand_icon = true
	button.pressed.connect(func() -> void: cell_action_requested.emit(marker.duplicate(true)))
	grid.add_child(button)


func _set_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y


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
	var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
	var accepted: bool = bool(result.get("accepted", result.get("ok", false)))
	var reason: String = String(result.get("reason_code", result.get("reason", "")))
	var command_id: String = String(result.get("command_id", "map_action"))
	if accepted:
		selected_feedback_text = "扫描记录：已选择 (%d,%d)，命令 %s 已接受。" % [pos.x, pos.y, command_id]
	else:
		selected_feedback_text = "扫描记录：已选择 (%d,%d)，命令 %s 被阻止：%s" % [pos.x, pos.y, command_id, reason]
	_rebuild_grid()


func show_open_feedback(source: StringName) -> void:
	selected_feedback_text = "扫描记录：从 %s 打开。未知房间可标记，已探索安全房间可尝试快速返回。" % String(source)
	_rebuild_grid()
