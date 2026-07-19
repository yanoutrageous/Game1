extends Control
class_name MiniMapPanel

# UI reads MiniMapViewModel only. UI must not read TruthMap directly.

signal open_map_requested

var view_model: MiniMapViewModel
var layout_profile: Dictionary = {}
var marker_size: Vector2 = Vector2(28, 28)
var marker_font_size: int = 13
const LEGACY_MINIMAP_VALIDATION_MARKER := "MiniMap: icons fallback to text"
const G10_MINIMAP_CLICK_VALIDATION_MARKER := "MiniMapPanel click opens MapOverlay"
const UNKNOWN_CELL_ASSET_ID := &"ui.art21.map.cell.unknown"
const EXPLORED_CELL_ASSET_ID := &"ui.art21r2.minimap.hud.explored"
const SCANNED_CELL_ASSET_ID := &"ui.art21r2.minimap.hud.scanned"
const FLAGGED_CELL_ASSET_ID := &"icon.minimap.flag"
const PLAYER_MARKER_ASSET_ID := &"ui.art21r2.minimap.hud.player"
const EXIT_MARKER_ASSET_ID := &"ui.art21r2.minimap.hud.exit"
const MINE_MARKER_ASSET_ID := &"ui.art21r2.minimap.hud.mine"
const CHEST_MARKER_ASSET_ID := &"ui.art21r2.minimap.hud.chest"
const EVENT_MARKER_ASSET_ID := &"ui.art21.map.marker.event"


func apply_view_model(next_view_model: MiniMapViewModel) -> void:
	view_model = next_view_model
	_rebuild_grid()
	queue_redraw()


func apply_layout_profile(profile: Dictionary) -> void:
	layout_profile = profile.duplicate(true)
	var is_low := bool(layout_profile.get("is_low_resolution", false))
	var is_high := bool(layout_profile.get("is_high_resolution", false))
	marker_size = Vector2(30, 30) if is_low else (Vector2(42, 42) if is_high else Vector2(36, 36))
	marker_font_size = 13 if is_low else (17 if is_high else 15)
	_apply_child_layout()
	_rebuild_grid()
	queue_redraw()


func clear() -> void:
	view_model = null
	_rebuild_grid()
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = ""
	var placeholder := get_node_or_null("PlaceholderLabel") as Label
	if placeholder != null:
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild_grid()


func _gui_input(event: InputEvent) -> void:
	_emit_open_map_from_mouse_event(event)


func _rebuild_grid() -> void:
	var grid := get_node_or_null("Grid") as GridContainer
	var placeholder := get_node_or_null("PlaceholderLabel") as Label
	if grid == null:
		return
	_apply_child_layout()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in grid.get_children():
		child.queue_free()

	if view_model == null:
		if placeholder != null:
			placeholder.visible = true
			placeholder.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
			placeholder.add_theme_font_size_override("font_size", marker_font_size)
			placeholder.text = "点击展开地图"
		return

	if view_model.room_markers.is_empty():
		if view_model.width > 0 and view_model.height > 0:
			_apply_marker_scale_for_view_model()
			grid.columns = max(1, view_model.width)
			for y in range(view_model.height):
				for x in range(view_model.width):
					_add_marker_node(grid, {
						"pos": Vector2i(x, y),
						"label": "?",
						"asset_id": UNKNOWN_CELL_ASSET_ID,
						"theme_key": &"mini.normal",
						"display_only": true,
						"read_only": true,
					}, marker_size)
			if placeholder != null:
				placeholder.visible = false
			return
		if placeholder != null:
			placeholder.visible = true
			placeholder.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
			placeholder.add_theme_font_size_override("font_size", marker_font_size)
			placeholder.text = "地图未公开"
		return

	_apply_marker_scale_for_view_model()
	grid.columns = max(1, view_model.width)
	if view_model.width > 0 and view_model.height > 0:
		var markers_by_pos := _markers_by_position(view_model.room_markers)
		for y in range(view_model.height):
			for x in range(view_model.width):
				var pos := Vector2i(x, y)
				var marker := _public_marker_or_unknown(markers_by_pos, pos)
				_add_marker_node(grid, marker, marker_size)
	else:
		for marker in view_model.room_markers:
			_add_marker_node(grid, marker, marker_size)

	if placeholder != null:
		placeholder.visible = false
		placeholder.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
		placeholder.add_theme_font_size_override("font_size", marker_font_size)
		placeholder.text = ""


func _apply_marker_scale_for_view_model() -> void:
	if view_model == null:
		return
	var panel_size := size
	if panel_size.x <= 0.0:
		panel_size.x = 260.0
	if panel_size.y <= 0.0:
		panel_size.y = 220.0
	var columns: float = float(max(1, view_model.width))
	var rows: float = float(max(1, view_model.height))
	var grid_gap: float = 2.0
	var cell_width: float = floor((panel_size.x - 16.0 - grid_gap * maxf(0.0, columns - 1.0)) / columns)
	var cell_height: float = floor((panel_size.y - 16.0 - grid_gap * maxf(0.0, rows - 1.0)) / rows)
	marker_size = Vector2(clampf(cell_width, 14.0, 56.0), clampf(cell_height, 14.0, 48.0))
	marker_font_size = clampi(int(min(marker_size.x, marker_size.y) * 0.62), 9, 20)


func _add_marker_node(grid: GridContainer, marker: Dictionary, size: Vector2) -> void:
	var asset_id := _base_asset_id_for_marker(marker)
	var asset_ref: Resource = null
	var theme_key := StringName(marker.get("theme_key", &"mini.normal"))
	if asset_id != &"":
		asset_ref = ContentDB.get_asset_ref(asset_id)

	if asset_ref is Texture2D:
		var cell := Control.new()
		cell.custom_minimum_size = size
		cell.mouse_filter = Control.MOUSE_FILTER_STOP
		cell.tooltip_text = ""
		cell.gui_input.connect(Callable(self, "_emit_open_map_from_mouse_event"))
		var base_icon := TextureRect.new()
		base_icon.texture = asset_ref
		base_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		base_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		base_icon.stretch_mode = TextureRect.STRETCH_SCALE
		base_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(base_icon)
		var overlay_id := _overlay_asset_id_for_marker(marker)
		if overlay_id != &"":
			var overlay_ref := ContentDB.get_asset_ref(overlay_id)
			if overlay_ref is Texture2D:
				var overlay_icon := TextureRect.new()
				overlay_icon.texture = overlay_ref
				overlay_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
				overlay_icon.offset_left = -4.0
				overlay_icon.offset_top = -4.0
				overlay_icon.offset_right = 4.0
				overlay_icon.offset_bottom = 4.0
				overlay_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				overlay_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				overlay_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
				cell.add_child(overlay_icon)
		grid.add_child(cell)
	else:
		var label := Label.new()
		var label_text := String(marker.get("label", "?"))
		label.custom_minimum_size = size
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		var marker_color := PresentationTheme.color_for_key(theme_key)
		if label_text == "?":
			marker_color = Color(0.72, 0.94, 0.82, 0.92)
		label.add_theme_color_override("font_color", marker_color)
		label.add_theme_font_size_override("font_size", marker_font_size)
		label.text = label_text
		label.tooltip_text = ""
		label.gui_input.connect(Callable(self, "_emit_open_map_from_mouse_event"))
		grid.add_child(label)


func _markers_by_position(markers: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {}
	for marker in markers:
		var pos: Vector2i = marker.get("pos", Vector2i(-1, -1))
		if pos.x < 0 or pos.y < 0:
			continue
		result[_pos_key(pos)] = marker.duplicate(true)
	return result


func _public_marker_or_unknown(markers_by_pos: Dictionary, pos: Vector2i) -> Dictionary:
	var key := _pos_key(pos)
	if markers_by_pos.has(key):
		return (markers_by_pos[key] as Dictionary).duplicate(true)
	return {
		"pos": pos,
		"label": "?",
		"asset_id": UNKNOWN_CELL_ASSET_ID,
		"theme_key": &"mini.normal",
		"display_only": true,
		"read_only": true,
		"preview": true,
	}


func _base_asset_id_for_marker(marker: Dictionary) -> StringName:
	var known_state := StringName(marker.get("known_state", marker.get("state", &"unknown")))
	if bool(marker.get("scanned", false)) or known_state == &"scanned":
		return SCANNED_CELL_ASSET_ID
	if bool(marker.get("is_current", false)) or bool(marker.get("explored", false)) or known_state in [&"explored", &"cleared"]:
		return EXPLORED_CELL_ASSET_ID
	return UNKNOWN_CELL_ASSET_ID


func _overlay_asset_id_for_marker(marker: Dictionary) -> StringName:
	if bool(marker.get("is_current", false)):
		return PLAYER_MARKER_ASSET_ID
	if bool(marker.get("flagged", false)):
		return FLAGGED_CELL_ASSET_ID
	var room_type := StringName(marker.get("room_type", &"Unknown"))
	if room_type == &"Exit":
		return EXIT_MARKER_ASSET_ID
	if room_type == &"Mine":
		return MINE_MARKER_ASSET_ID
	if room_type == &"Chest":
		return CHEST_MARKER_ASSET_ID
	if room_type == &"Event":
		return EVENT_MARKER_ASSET_ID
	return &""


func _pos_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]


func _emit_open_map_from_mouse_event(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			open_map_requested.emit()
			accept_event()


func _apply_child_layout() -> void:
	var grid := get_node_or_null("Grid") as GridContainer
	var placeholder := get_node_or_null("PlaceholderLabel") as Label
	var panel_size := size
	if panel_size.x <= 0.0:
		panel_size.x = 220.0
	if panel_size.y <= 0.0:
		panel_size.y = 220.0
	if grid != null:
		grid.offset_left = 8.0
		grid.offset_top = 8.0
		grid.offset_right = panel_size.x - 8.0
		grid.offset_bottom = panel_size.y - 8.0
		grid.add_theme_constant_override("h_separation", 2)
		grid.add_theme_constant_override("v_separation", 2)
	if placeholder != null:
		placeholder.offset_left = 8.0
		placeholder.offset_top = panel_size.y - 30.0
		placeholder.offset_right = panel_size.x - 8.0
		placeholder.offset_bottom = panel_size.y - 4.0
