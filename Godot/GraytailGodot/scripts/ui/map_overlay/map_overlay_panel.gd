extends Control
class_name MapOverlayPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const Art24MapOverlayLayoutScript := preload("res://scripts/presentation/art24/art24_map_overlay_layout.gd")

signal cell_action_requested(marker: Dictionary)

var view_model: MiniMapViewModel
var selected_feedback_text: String = ""
var selected_marker: Dictionary = {}
var layout_profile: Dictionary = {}
var layout_metrics: Dictionary = {}
var marker_size: Vector2 = Vector2(42, 42)
var title_font_size: int = 20
var footer_font_size: int = 13
const LEGACY_MAP_OVERLAY_VALIDATION_MARKER := "Click hidden cells to flag"
const ART21R2_MAP_PANEL_FRAME_VISUAL_KEY := &"art21r2.modal.inventory.frame"
const ART21R2_MAP_TITLE_PLATE_VISUAL_KEY := &"art21r2.modal.title_plate"
const ART21R2_MAP_DETAIL_PANEL_VISUAL_KEY := &"art21r2.modal.section.panel"
const ART21R2_MAP_FOOTER_STRIP_VISUAL_KEY := &"art21r2.modal.action_strip"


func apply_view_model(next_view_model: MiniMapViewModel) -> void:
	view_model = next_view_model
	if not layout_profile.is_empty():
		apply_layout_profile(layout_profile)
	else:
		_rebuild_grid()


func apply_layout_profile(profile: Dictionary) -> void:
	layout_profile = profile.duplicate(true)
	var is_low := bool(layout_profile.get("is_low_resolution", false))
	var is_high := bool(layout_profile.get("is_high_resolution", false))
	var grid_size := Vector2i(
		maxi(1, view_model.width if view_model != null else 10),
		maxi(1, view_model.height if view_model != null else 10)
	)
	layout_metrics = Art24MapOverlayLayoutScript.calculate(layout_profile, grid_size)
	title_font_size = 16 if is_low else (20 if is_high else 18)
	footer_font_size = 11 if is_low else (13 if is_high else 12)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	var dimmer := get_node_or_null("Dimmer") as ColorRect
	if dimmer != null:
		dimmer.color = Color(0.0, 0.0, 0.0, 0.70)
	var panel := get_node_or_null("Panel") as Control
	if panel != null:
		# Budget the real M7 grid dimensions plus title, feedback and frame
		# padding. This keeps 7x7, 10x10 and 13x13 maps inside the same ART24
		# fullscreen composition without returning to a narrow dialog.
		var cell_size := float(layout_metrics.get("marker_size", 36.0))
		marker_size = Vector2(cell_size, cell_size)
		panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_set_rect(panel, layout_metrics.get("panel_rect", Rect2(120, 18, 1040, 604)))
		_apply_overlay_panel_style(panel)
	var content := get_node_or_null("Panel/Content") as VBoxContainer
	if content != null:
		content.add_theme_constant_override("separation", int(layout_metrics.get("content_gap", 5)))
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
	var right_click := event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT and (event as InputEventMouseButton).pressed
	var toggle_map := event.is_action_pressed("open_map") or _event_matches_key(event, [KEY_M])
	if event.is_action_pressed("cancel") or _event_matches_key(event, [KEY_ESCAPE]) or toggle_map or right_click:
		hide_overlay()
		get_viewport().set_input_as_handled()


func _rebuild_grid() -> void:
	var grid := get_node_or_null("Panel/Content/Grid") as GridContainer
	var title := get_node_or_null("Panel/Content/Title") as Label
	var detail := _ensure_detail_label()
	var footer := get_node_or_null("Panel/Content/Footer") as Label
	if grid == null:
		return
	var grid_gap := int(layout_metrics.get("grid_gap", 3 if marker_size.x <= 38.0 else 5))
	grid.add_theme_constant_override("h_separation", grid_gap)
	grid.add_theme_constant_override("v_separation", grid_gap)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	for child in grid.get_children():
		child.queue_free()

	_apply_overlay_text_hierarchy(title, detail, footer)
	if title != null:
		title.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
		title.add_theme_font_size_override("font_size", title_font_size)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.text = "区域扫描图（点击格子标记雷险 / 回传）"
	if detail != null:
		detail.visible = false
		detail.custom_minimum_size = Vector2.ZERO
		detail.text = ""
	if footer != null:
		footer.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
		footer.add_theme_font_size_override("font_size", 12 if bool(layout_profile.get("is_low_resolution", false)) else maxi(13, footer_font_size))
		footer.add_theme_constant_override("line_spacing", 2)
		footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		footer.text = "左键：未知格标记雷险 / 取消 · 已探索格回传 · M / Esc / 右键关闭"

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
	button.add_theme_font_size_override("font_size", maxi(9, int(min(marker_size.x, marker_size.y) * 0.52)))
	var state := _art21_marker_state(marker)
	var selected := _is_selected_marker(marker)
	_apply_marker_button_style(button, theme_key, state, selected)
	var texture := Art09ManifestAssetMappingScript.resolve_texture(_map_overlay_asset_ref_for_marker(marker))
	if texture != null:
		button.icon = texture
		# Every icon must be allowed to shrink with the tile. Leaving the default
		# map icons at native size silently raises Button's minimum height and makes
		# the ten-row GridContainer expand the whole modal at 720p.
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", _icon_width_for_marker_state(state, marker_size))
		button.text = "" if label_text != "P" else "P"
	button.modulate = _modulate_for_marker_state(state, selected)
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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.005, 0.012, 0.014, 0.16)
	style.content_margin_left = 16
	style.content_margin_top = float(layout_metrics.get("frame_vertical_padding", 24.0)) * 0.5
	style.content_margin_right = 16
	style.content_margin_bottom = float(layout_metrics.get("frame_vertical_padding", 24.0)) * 0.5
	panel.add_theme_stylebox_override("panel", style)


func _apply_overlay_text_hierarchy(title: Label, detail: Label, footer: Label) -> void:
	var label_padding := int(layout_metrics.get("label_padding", 8))
	if title != null:
		title.custom_minimum_size = Vector2(620, float(layout_metrics.get("title_height", 32)))
		title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		title.add_theme_stylebox_override("normal", _transparent_text_style(label_padding))
	if detail != null:
		detail.custom_minimum_size = Vector2(620, float(layout_metrics.get("detail_height", 72)))
		detail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		detail.add_theme_stylebox_override("normal", _style_box_for_visual_key(ART21R2_MAP_DETAIL_PANEL_VISUAL_KEY, label_padding, 18))
	if footer != null:
		footer.custom_minimum_size = Vector2(620, float(layout_metrics.get("footer_height", 48)))
		footer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		footer.add_theme_stylebox_override("normal", _style_box_for_visual_key(ART21R2_MAP_FOOTER_STRIP_VISUAL_KEY, label_padding, 18))


func _transparent_text_style(padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style


func _style_box_for_visual_key(visual_key: StringName, padding: int = 8, texture_margin: int = 18) -> StyleBox:
	var style := StyleBoxFlat.new()
	var is_title := visual_key == ART21R2_MAP_TITLE_PLATE_VISUAL_KEY
	var is_footer := visual_key == ART21R2_MAP_FOOTER_STRIP_VISUAL_KEY
	style.bg_color = Color(0.014, 0.040, 0.043, 0.94)
	style.border_color = Color(0.18, 0.50, 0.47, 0.78)
	if is_title:
		style.border_color = Color(0.88, 0.64, 0.24, 0.90)
	elif is_footer:
		style.bg_color = Color(0.010, 0.025, 0.028, 0.96)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style


func _apply_marker_button_style(button: Button, theme_key: StringName, state: StringName, selected: bool) -> void:
	var border := PresentationTheme.color_for_key(theme_key)
	# A confirmed flag/unflag action must keep the cell's semantic state visible.
	# Selection is represented by a restrained brightness lift and by hover/
	# pressed styles; it must not replace the UE-like red flag tile with cyan.
	var tile_style := _art24_map_tile_style(state, false)
	button.add_theme_stylebox_override("normal", tile_style)
	button.add_theme_stylebox_override("hover", _art24_map_tile_style(state, true))
	button.add_theme_stylebox_override("pressed", _art24_map_tile_style(state, true))
	button.add_theme_stylebox_override("disabled", Art10UISkinKitScript.transparent_style_box(0))
	button.add_theme_color_override("font_color", border)


func _art24_map_tile_style(state: StringName, selected: bool) -> StyleBox:
	# Selection may brighten neutral/unknown cells, but it must never replace a
	# semantic marker (flag, player, hazard, chest, exit or event) with the cyan
	# generic selected tile.
	var semantic_state := state in [&"flagged", &"event", &"player", &"mine", &"chest", &"exit"]
	var token := "selected" if selected and not semantic_state else "explored"
	if not selected or semantic_state:
		match state:
			&"unknown":
				token = "unknown"
			&"scanned":
				token = "scanned"
			&"flagged", &"event":
				token = "flagged"
			&"player":
				token = "player"
			&"mine":
				token = "danger"
	var texture := load("res://assets/art24/ui/map_tile_%s.png" % token) as Texture2D
	if texture == null:
		return Art10UISkinKitScript.transparent_style_box(0)
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 8
	style.texture_margin_top = 8
	style.texture_margin_right = 8
	style.texture_margin_bottom = 8
	style.draw_center = true
	if token == "flagged":
		# UE communicates a player-authored danger flag with a red cell field.  The
		# source tile remains copper/yellow and reusable; tint only the background
		# style so the separately rendered flag icon keeps its gold identity.
		style.modulate_color = Color(1.20, 0.42, 0.42, 1.0)
	return style


func _icon_width_for_marker_state(state: StringName, size: Vector2) -> int:
	var base: float = minf(size.x, size.y)
	match state:
		&"flagged", &"event":
			return int(base * 0.92)
		&"player", &"exit", &"mine", &"chest":
			return int(base * 0.82)
		&"scanned":
			return int(base * 0.72)
		&"unknown":
			return int(base * 0.58)
		_:
			return int(base * 0.70)


func _modulate_for_marker_state(state: StringName, selected: bool) -> Color:
	if selected:
		return Color(1.14, 1.14, 1.06, 1.0)
	match state:
		&"unknown":
			return Color(0.72, 0.78, 0.74, 0.58)
		&"explored":
			return Color(0.88, 0.96, 0.91, 0.82)
		&"scanned":
			return Color(0.94, 1.0, 0.96, 0.96)
		&"flagged", &"event", &"player":
			return Color(1.0, 1.0, 1.0, 1.0)
		_:
			return Color(0.96, 1.0, 0.96, 0.92)


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
	if bool(marker.get("scanned", false)) or int(marker.get("adjacent_mines", -1)) > 0:
		return &"scanned"
	if not bool(marker.get("revealed", true)) or String(marker.get("label", "")) == "?":
		return &"unknown"
	return &"explored"


func _map_overlay_asset_ref_for_marker(marker: Dictionary) -> Dictionary:
	var state := _art21_marker_state(marker)
	match state:
		&"flagged", &"event":
			return Art21UIPlacementContractScript.map_ref(state)
		_:
			return Art09ManifestAssetMappingScript.art19_map64_ref(state)


func _is_selected_marker(marker: Dictionary) -> bool:
	if selected_marker.is_empty():
		return false
	var marker_pos: Vector2i = marker.get("pos", Vector2i(-9999, -9999))
	var selected_pos: Vector2i = selected_marker.get("pos", Vector2i(-8888, -8888))
	return marker_pos == selected_pos


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


func show_open_feedback(_source: StringName) -> void:
	# The UE overview keeps its status row quiet until the player acts. Opening
	# the map is already visually explicit; repeating it added an unnecessary
	# second footer line and competed with the control hint.
	selected_feedback_text = ""
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
	detail.visible = false
	detail.custom_minimum_size = Vector2.ZERO
	content.add_child(detail)
	var grid := get_node_or_null("Panel/Content/Grid")
	if grid != null:
		content.move_child(detail, grid.get_index())
	return detail


func _selected_detail_text() -> String:
	if selected_marker.is_empty():
		return "点击格子查看状态。"
	# Keep the scan grid dominant. Technical models may provide four diagnostic
	# lines, but the UE overlay presents selection status as one compact band.
	return String(selected_marker.get("detail_text", "选中格详情不可用。")).replace("\n", " · ")
