extends Control
class_name MapOverlayPanel

signal cell_action_requested(marker: Dictionary)

var view_model: MiniMapViewModel
var selected_feedback_text: String = ""
const LEGACY_MAP_OVERLAY_VALIDATION_MARKER := "Click hidden cells to flag"


func apply_view_model(next_view_model: MiniMapViewModel) -> void:
	view_model = next_view_model
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
		title.text = "区域扫描图"
	if footer != null:
		footer.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
		footer.text = "点击未知房间插旗；点击已探索安全房间快速返回。"

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
	button.custom_minimum_size = Vector2(42, 42)
	button.text = String(marker.get("label", "?"))
	button.tooltip_text = String(marker.get("tooltip", "cell"))
	button.add_theme_color_override("font_color", PresentationTheme.color_for_key(theme_key))
	if asset_ref is Texture2D:
		button.icon = asset_ref
		button.expand_icon = true
	button.pressed.connect(func() -> void: cell_action_requested.emit(marker.duplicate(true)))
	grid.add_child(button)


func show_action_feedback(marker: Dictionary, result: Dictionary) -> void:
	var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
	var accepted: bool = bool(result.get("accepted", result.get("ok", false)))
	var reason: String = String(result.get("reason_code", result.get("reason", "")))
	var command_id: String = String(result.get("command_id", "map_action"))
	if accepted:
		selected_feedback_text = "MapOverlay selection: (%d,%d) command=%s accepted" % [pos.x, pos.y, command_id]
	else:
		selected_feedback_text = "MapOverlay selection: (%d,%d) command=%s blocked=%s" % [pos.x, pos.y, command_id, reason]
	_rebuild_grid()
