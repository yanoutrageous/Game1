extends Control
class_name MapOverlayPanel

var view_model: MiniMapViewModel


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
		title.text = "Map Overlay"
	if footer != null:
		footer.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
		footer.text = "M/Tab toggles map. F flags current cell."

	if view_model == null:
		return

	grid.columns = max(1, view_model.width)
	for marker in view_model.room_markers:
		_add_marker_node(grid, marker)


func _add_marker_node(grid: GridContainer, marker: Dictionary) -> void:
	var asset_id := StringName(marker.get("asset_id", &""))
	var asset_ref := ContentDB.get_asset_ref(asset_id)
	var theme_key := StringName(marker.get("theme_key", &"mini.normal"))
	if asset_ref is Texture2D:
		var icon := TextureRect.new()
		icon.texture = asset_ref
		icon.custom_minimum_size = Vector2(42, 42)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = String(marker.get("tooltip", ContentDB.get_placeholder_label(asset_id)))
		grid.add_child(icon)
	else:
		var label := Label.new()
		label.custom_minimum_size = Vector2(42, 42)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", PresentationTheme.color_for_key(theme_key))
		label.text = String(marker.get("label", "?"))
		label.tooltip_text = String(marker.get("tooltip", "cell"))
		grid.add_child(label)
