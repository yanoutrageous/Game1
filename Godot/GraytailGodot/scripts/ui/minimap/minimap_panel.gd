extends Control
class_name MiniMapPanel

# UI reads MiniMapViewModel only. UI must not read TruthMap directly.

signal open_map_requested

var view_model: MiniMapViewModel
const LEGACY_MINIMAP_VALIDATION_MARKER := "MiniMap: icons fallback to text"
const G10_MINIMAP_CLICK_VALIDATION_MARKER := "MiniMapPanel click opens MapOverlay"


func apply_view_model(next_view_model: MiniMapViewModel) -> void:
	view_model = next_view_model
	_rebuild_grid()
	queue_redraw()


func clear() -> void:
	view_model = null
	_rebuild_grid()
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "点击打开区域扫描器回顾"
	var placeholder := get_node_or_null("PlaceholderLabel") as Label
	if placeholder != null:
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild_grid()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			open_map_requested.emit()
			accept_event()


func _rebuild_grid() -> void:
	var grid := get_node_or_null("Grid") as GridContainer
	var placeholder := get_node_or_null("PlaceholderLabel") as Label
	if grid == null:
		return
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in grid.get_children():
		child.queue_free()

	if view_model == null:
		if placeholder != null:
			placeholder.add_theme_font_size_override("font_size", 13)
			placeholder.text = "区域扫描图：暂无情报"
		return

	grid.columns = max(1, view_model.width)
	for marker in view_model.room_markers:
		_add_marker_node(grid, marker, Vector2(28, 28))

	if placeholder != null:
		placeholder.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
		placeholder.add_theme_font_size_override("font_size", 13)
		placeholder.text = "区域扫描图：点击打开回顾；数字为周围雷险"


func _add_marker_node(grid: GridContainer, marker: Dictionary, size: Vector2) -> void:
	var asset_id := StringName(marker.get("asset_id", &""))
	var asset_ref: Resource = null
	var theme_key := StringName(marker.get("theme_key", &"mini.normal"))
	if asset_id != &"":
		asset_ref = ContentDB.get_asset_ref(asset_id)

	if asset_ref is Texture2D:
		var icon := TextureRect.new()
		icon.texture = asset_ref
		icon.custom_minimum_size = size
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.tooltip_text = String(marker.get("tooltip", ContentDB.get_placeholder_label(asset_id)))
		grid.add_child(icon)
	else:
		var label := Label.new()
		label.custom_minimum_size = size
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", PresentationTheme.color_for_key(theme_key))
		label.add_theme_font_size_override("font_size", 13)
		label.text = String(marker.get("label", "?"))
		label.tooltip_text = String(marker.get("tooltip", ContentDB.get_placeholder_label(asset_id) if asset_id != &"" else "未知房间"))
		grid.add_child(label)
