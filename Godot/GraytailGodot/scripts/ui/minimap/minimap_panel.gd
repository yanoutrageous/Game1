extends Control
class_name MiniMapPanel

const ContentDBAccessScript := preload("res://scripts/core/content/content_db_access.gd")
const RuntimeInputProfileScript := preload("res://scripts/core/input/runtime_input_profile.gd")
const SemanticActionHintScript := preload("res://scripts/core/input/semantic_action_hint.gd")
const MapCellLayerLayoutScript := preload("res://scripts/ui/map_shared/map_cell_layer_layout.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")

# UI reads MiniMapViewModel only. UI must not read TruthMap directly.

signal open_map_requested

var view_model: MiniMapViewModel
var layout_profile: Dictionary = {}
var marker_size: Vector2 = Vector2(28, 28)
var marker_font_size: int = 13
var visible_map_rect: Rect2i = Rect2i()
const LEGACY_MINIMAP_VALIDATION_MARKER := "MiniMap: icons fallback to text"
const G10_MINIMAP_CLICK_VALIDATION_MARKER := "MiniMapPanel click opens MapOverlay"
const LOCAL_WINDOW_SIZE := 5
const UNKNOWN_CELL_ASSET_ID := &"ui.art21.map.cell.unknown"
const EXPLORED_CELL_ASSET_ID := &"ui.art21r2.minimap.hud.explored"
const SCANNED_CELL_ASSET_ID := &"ui.art21r2.minimap.hud.scanned"
const FLAGGED_CELL_ASSET_ID := &"icon.minimap.flag"
const PLAYER_MARKER_ASSET_ID := &"ui.art21r2.minimap.hud.player"
const EXIT_MARKER_ASSET_ID := &"ui.art21r2.minimap.hud.exit"
const MINE_MARKER_ASSET_ID := &"ui.art21r2.minimap.hud.mine"
const MONSTER_MARKER_ASSET_ID := &"icon.room.monster"
const CHEST_MARKER_ASSET_ID := &"ui.art21r2.minimap.hud.chest"
const EVENT_MARKER_ASSET_ID := &"ui.art21.map.marker.event"


func apply_view_model(next_view_model: MiniMapViewModel) -> void:
	view_model = next_view_model
	refresh_input_hints()
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
	add_to_group(RuntimeInputProfileScript.HINT_CONSUMER_GROUP)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	refresh_input_hints()
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	var placeholder := get_node_or_null("PlaceholderLabel") as Label
	if placeholder != null:
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild_grid()


func refresh_input_hints() -> void:
	var map_hint := SemanticActionHintScript.current_binding_label(&"open_map")
	tooltip_text = (
		"区域地图 · %s / 点击展开" % map_hint
		if not map_hint.is_empty()
		else "区域地图 · 点击展开"
	)


func _gui_input(event: InputEvent) -> void:
	_emit_open_map_from_mouse_event(event)


func _draw() -> void:
	if has_focus():
		draw_rect(Rect2(Vector2(1.0, 1.0), size - Vector2(2.0, 2.0)), Color(0.88, 0.64, 0.24, 0.95), false, 2.0)


func _rebuild_grid() -> void:
	var grid := get_node_or_null("Grid") as GridContainer
	var placeholder := get_node_or_null("PlaceholderLabel") as Label
	if grid == null:
		return
	_apply_child_layout()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	if view_model == null:
		visible_map_rect = Rect2i()
		if placeholder != null:
			placeholder.visible = true
			placeholder.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
			placeholder.add_theme_font_size_override("font_size", marker_font_size)
			placeholder.text = "点击展开地图"
		return

	if view_model.room_markers.is_empty():
		if view_model.width > 0 and view_model.height > 0:
			visible_map_rect = _local_window_rect()
			_apply_marker_scale_for_view_model(visible_map_rect.size)
			grid.columns = max(1, visible_map_rect.size.x)
			for y in range(visible_map_rect.position.y, visible_map_rect.end.y):
				for x in range(visible_map_rect.position.x, visible_map_rect.end.x):
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

	visible_map_rect = _local_window_rect()
	_apply_marker_scale_for_view_model(visible_map_rect.size)
	grid.columns = max(1, visible_map_rect.size.x)
	if view_model.width > 0 and view_model.height > 0:
		var markers_by_pos := _markers_by_position(view_model.room_markers)
		for y in range(visible_map_rect.position.y, visible_map_rect.end.y):
			for x in range(visible_map_rect.position.x, visible_map_rect.end.x):
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


func _apply_marker_scale_for_view_model(grid_size: Vector2i) -> void:
	if view_model == null:
		return
	var panel_size := size
	if panel_size.x <= 0.0:
		panel_size.x = 260.0
	if panel_size.y <= 0.0:
		panel_size.y = 220.0
	var columns: float = float(max(1, grid_size.x))
	var rows: float = float(max(1, grid_size.y))
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
		asset_ref = ContentDBAccessScript.get_asset_ref(asset_id)
	var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
	var cell := Control.new()
	cell.name = "MiniMapCell_%d_%d" % [pos.x, pos.y]
	cell.set_meta("map_marker_state", PresentationMapping.map_marker_state(marker))
	cell.custom_minimum_size = size
	cell.clip_contents = true
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.tooltip_text = String(marker.get("detail_text", marker.get("tooltip", "")))
	cell.gui_input.connect(Callable(self, "_emit_open_map_from_mouse_event"))
	var adjacent := _public_adjacent_mines(marker)
	var layer_layout := MapCellLayerLayoutScript.calculate(size, adjacent >= 0)
	cell.set_meta("map_cell_layer_layout", layer_layout.duplicate(true))
	cell.set_meta("map_cell_clip_contract", true)
	if asset_ref is Texture2D:
		var base_icon := TextureRect.new()
		base_icon.name = "CellBase"
		base_icon.texture = asset_ref
		MapCellLayerLayoutScript.apply_rect(base_icon, Rect2(layer_layout.get("base_rect", Rect2())))
		base_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		base_icon.stretch_mode = TextureRect.STRETCH_SCALE
		base_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		base_icon.z_index = int(layer_layout.get("base_z", 0))
		cell.add_child(base_icon)
	var overlay_id := _overlay_asset_id_for_marker(marker)
	var overlay_ref := ContentDBAccessScript.get_asset_ref(overlay_id) if overlay_id != &"" else null
	if overlay_ref is Texture2D:
		var overlay_icon := TextureRect.new()
		overlay_icon.name = "SemanticMarker"
		overlay_icon.texture = overlay_ref
		MapCellLayerLayoutScript.apply_rect(overlay_icon, Rect2(layer_layout.get("semantic_rect", Rect2())))
		overlay_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		overlay_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay_icon.z_index = int(layer_layout.get("semantic_z", 20))
		cell.add_child(overlay_icon)
	elif not (asset_ref is Texture2D) or PresentationMapping.map_marker_state(marker) not in [&"unknown", &"scanned", &"explored"]:
		var label := Label.new()
		label.name = "SemanticFallback"
		var label_text := String(marker.get("label", "?"))
		MapCellLayerLayoutScript.apply_rect(label, Rect2(layer_layout.get("semantic_rect", Rect2())))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_index = int(layer_layout.get("semantic_z", 20))
		var marker_color := PresentationTheme.color_for_key(theme_key)
		if label_text == "?":
			marker_color = Color(0.72, 0.94, 0.82, 0.92)
		label.add_theme_color_override("font_color", marker_color)
		label.add_theme_font_size_override("font_size", marker_font_size)
		label.text = label_text
		cell.add_child(label)
	_add_adjacent_mine_count(cell, marker, layer_layout)
	grid.add_child(cell)


func _add_adjacent_mine_count(cell: Control, marker: Dictionary, layer_layout: Dictionary = {}) -> void:
	var adjacent := _public_adjacent_mines(marker)
	if adjacent < 0:
		return
	if layer_layout.is_empty():
		layer_layout = MapCellLayerLayoutScript.calculate(cell.custom_minimum_size, true)
	var count_rect := Rect2(layer_layout.get("count_rect", Rect2()))
	var badge_background := ColorRect.new()
	badge_background.name = "AdjacentMineBadgeBackground"
	badge_background.color = Color(0.015, 0.025, 0.028, 0.92)
	badge_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_background.z_index = int(layer_layout.get("count_z", 30))
	MapCellLayerLayoutScript.apply_rect(badge_background, count_rect)
	cell.add_child(badge_background)
	var count_label := Label.new()
	count_label.name = "AdjacentMineCount"
	cell.add_child(count_label)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count_label.z_index = int(layer_layout.get("count_z", 30)) + 1
	var count_font := Art10UISkinKitScript.pixel_font()
	if count_font is Font:
		count_label.add_theme_font_override("font", count_font as Font)
	count_label.add_theme_font_size_override("font_size", clampi(int(count_rect.size.y * 0.62), 9, 15))
	count_label.add_theme_constant_override("line_spacing", 0)
	count_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.78, 1.0))
	count_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.03, 1.0))
	count_label.add_theme_constant_override("outline_size", 1)
	count_label.text = str(adjacent)
	MapCellLayerLayoutScript.apply_rect(count_label, count_rect)
	# Entering the themed tree can temporarily retain Label's previous minimum
	# height. Re-assert the authored badge extent at idle before the next draw.
	count_label.set_deferred("size", count_rect.size)


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
	match PresentationMapping.map_marker_state(marker):
		&"unknown":
			return UNKNOWN_CELL_ASSET_ID
		&"scanned":
			return SCANNED_CELL_ASSET_ID
		_:
			return EXPLORED_CELL_ASSET_ID


func _overlay_asset_id_for_marker(marker: Dictionary) -> StringName:
	match PresentationMapping.map_marker_state(marker):
		&"player":
			return PLAYER_MARKER_ASSET_ID
		&"flagged":
			return FLAGGED_CELL_ASSET_ID
		&"exit":
			return EXIT_MARKER_ASSET_ID
		&"mine":
			return MINE_MARKER_ASSET_ID
		&"monster":
			return MONSTER_MARKER_ASSET_ID
		&"chest":
			return CHEST_MARKER_ASSET_ID
		&"event":
			return EVENT_MARKER_ASSET_ID
		_:
			return &""


func _pos_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]


func _emit_open_map_from_mouse_event(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			open_map_requested.emit()
			accept_event()
		return
	if (
		RuntimeInputProfileScript.event_pressed(event, RuntimeInputProfileScript.ACTION_OPEN_MAP)
		or event.is_action_pressed("ui_accept")
	):
		open_map_requested.emit()
		accept_event()


func _public_adjacent_mines(marker: Dictionary) -> int:
	return PresentationMapping.public_adjacent_mines(marker)


func _local_window_rect() -> Rect2i:
	if view_model == null or view_model.width <= 0 or view_model.height <= 0:
		return Rect2i()
	var window_size := Vector2i(
		mini(LOCAL_WINDOW_SIZE, view_model.width),
		mini(LOCAL_WINDOW_SIZE, view_model.height)
	)
	var center := _current_map_position()
	if center.x < 0 or center.y < 0:
		center = Vector2i(window_size.x / 2, window_size.y / 2)
	center.x = clampi(center.x, 0, view_model.width - 1)
	center.y = clampi(center.y, 0, view_model.height - 1)
	var start := Vector2i(
		clampi(center.x - window_size.x / 2, 0, view_model.width - window_size.x),
		clampi(center.y - window_size.y / 2, 0, view_model.height - window_size.y)
	)
	return Rect2i(start, window_size)


func _current_map_position() -> Vector2i:
	if view_model == null:
		return Vector2i(-1, -1)
	for marker in view_model.room_markers:
		if bool(marker.get("is_current", false)):
			return Vector2i(marker.get("pos", Vector2i(-1, -1)))
	var known_map: Dictionary = view_model.map_snapshot.get("KnownMap", {})
	return Vector2i(known_map.get("player_pos", Vector2i(-1, -1)))


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
