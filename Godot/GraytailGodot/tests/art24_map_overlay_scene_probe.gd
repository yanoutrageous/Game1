extends SceneTree

const MapOverlayScene := preload("res://scenes/ui/map_overlay/map_overlay_panel.tscn")
const MiniMapViewModelScript := preload("res://scripts/ui/minimap/minimap_view_model.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")

const RESOLUTIONS := [
	&"1280x720",
	&"1366x768",
	&"1600x900",
	&"1920x1080",
	&"2560x1440",
]
const GRID_EDGES := [5, 7, 10, 13]
const UI_SCALE_RESOLUTIONS := [&"1280x720", &"1920x1080"]
const UI_SCALES := [1.0, 1.25, 1.5]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	for resolution_id: StringName in RESOLUTIONS:
		var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(resolution_id)
		var viewport_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
		profile["actual_viewport_size"] = viewport_size
		root.size = viewport_size
		_assert_player_facing_labels(resolution_id, failures)
		for grid_edge: int in GRID_EDGES:
			var canvas := Control.new()
			canvas.size = viewport_size
			root.add_child(canvas)
			var overlay := MapOverlayScene.instantiate() as MapOverlayPanel
			canvas.add_child(overlay)
			overlay.apply_layout_profile(profile)
			overlay.apply_view_model(_full_map_model(grid_edge))
			overlay.show_overlay()
			await _frames(4)
			_force_single_line_detail(overlay)
			await _frames(2)
			var overview_id := StringName("%s-%dx%d-overview" % [resolution_id, grid_edge, grid_edge])
			_assert_controls_inside_panel(overlay, overview_id, viewport_size, failures)
			_assert_transparent_hierarchy_and_pixel_tiles(overlay, overview_id, viewport_size, failures)
			_assert_text_content_budget(overlay, overview_id, failures)
			var selected_action := overlay.get_node("Panel/Content/SelectedAction") as Button
			if selected_action.visible:
				failures.append("%s disabled_current_action_is_visible" % overview_id)
			var selectable := overlay.get_node_or_null("Panel/Content/Grid/MapCell_0_0") as Button
			if selectable != null:
				selectable.pressed.emit()
				await _frames(2)
			if selected_action == null or not selected_action.visible or selected_action.disabled:
				failures.append("%s enabled_map_action_is_not_visible" % overview_id)
			if grid_edge == 10:
				var close_event := InputEventKey.new()
				close_event.keycode = KEY_M
				close_event.physical_keycode = KEY_M
				close_event.pressed = true
				overlay.call("_input", close_event)
				if overlay.visible:
					failures.append("%s map_toggle_m_did_not_close" % resolution_id)
				overlay.show_overlay()
				await _frames(2)
			overlay.selected_feedback_text = "当前动作不可执行"
			overlay.call("_rebuild_grid")
			await _frames(4)
			_force_single_line_detail(overlay)
			await _frames(2)
			var selected_id := StringName("%s-%dx%d-selected" % [resolution_id, grid_edge, grid_edge])
			_assert_controls_inside_panel(overlay, selected_id, viewport_size, failures)
			_assert_transparent_hierarchy_and_pixel_tiles(overlay, selected_id, viewport_size, failures)
			_assert_text_content_budget(overlay, selected_id, failures)
			var detail := overlay.get_node("Panel/Content/Detail") as Label
			if not detail.visible or detail.text == "" or detail.get_theme_font_size("font_size") < 18:
				failures.append("%s selected_detail_not_readable" % selected_id)
			canvas.queue_free()
			await _frames(2)
	await _assert_ui_scale_cases(failures)
	if failures.is_empty():
		print("ART24_MAP_OVERLAY_SCENE=PASS resolutions=5 grids=5x5,7x7,10x10,13x13 ui_scale=1280,1920@100,125,150 hierarchy=title,grid,detail,action,footer host=transparent tiles=pixel text=single_line toggle=m_close")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("ART24_MAP_OVERLAY_SCENE=FAIL failures=%d" % failures.size())
		quit(2)


func _assert_ui_scale_cases(failures: Array[String]) -> void:
	for resolution_id: StringName in UI_SCALE_RESOLUTIONS:
		var previous_title_font := 0
		var previous_action_size := Vector2.ZERO
		var previous_text_width := 0.0
		for ui_scale: float in UI_SCALES:
			var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(resolution_id)
			var viewport_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
			profile["actual_viewport_size"] = viewport_size
			root.size = viewport_size
			var canvas := Control.new()
			canvas.size = viewport_size
			root.add_child(canvas)
			var overlay := MapOverlayScene.instantiate() as MapOverlayPanel
			canvas.add_child(overlay)
			overlay.set_ui_scale_factor(ui_scale)
			overlay.apply_layout_profile(profile)
			overlay.apply_view_model(_full_map_model(13))
			overlay.show_overlay()
			await _frames(3)
			var selectable := overlay.get_node_or_null("Panel/Content/Grid/MapCell_0_0") as Button
			if selectable != null:
				selectable.pressed.emit()
			await _frames(2)
			var case_id := StringName("%s-13x13-ui%d" % [resolution_id, int(round(ui_scale * 100.0))])
			_assert_controls_inside_panel(overlay, case_id, viewport_size, failures)
			var title := overlay.get_node("Panel/Content/Title") as Label
			var action := overlay.get_node("Panel/Content/SelectedAction") as Button
			var title_font := title.get_theme_font_size("font_size")
			var action_size := action.get_combined_minimum_size()
			var text_width := float(overlay.layout_metrics.get("text_width", 0.0))
			if not is_equal_approx(overlay.get_ui_scale_factor(), ui_scale):
				failures.append("%s getter=%s" % [case_id, overlay.get_ui_scale_factor()])
			if float(overlay.marker_size.x) < 28.0:
				failures.append("%s marker_below_floor=%s" % [case_id, overlay.marker_size.x])
			if title_font < previous_title_font:
				failures.append("%s title_font_not_monotonic=%d<%d" % [case_id, title_font, previous_title_font])
			if action_size.x + 0.5 < previous_action_size.x or action_size.y + 0.5 < previous_action_size.y:
				failures.append("%s action_hit_area_not_monotonic=%s<%s" % [case_id, action_size, previous_action_size])
			if text_width + 0.5 < previous_text_width:
				failures.append("%s text_width_not_monotonic=%s<%s" % [case_id, text_width, previous_text_width])
			previous_title_font = title_font
			previous_action_size = action_size
			previous_text_width = text_width
			canvas.queue_free()
			await _frames(2)


func _assert_controls_inside_panel(overlay: MapOverlayPanel, state_id: StringName, viewport_size: Vector2i, failures: Array[String]) -> void:
	var panel := overlay.get_node("Panel") as Control
	var panel_rect := panel.get_global_rect()
	var requested_panel_rect: Rect2 = overlay.layout_metrics.get("panel_rect", Rect2())
	var control_heights: Array[String] = []
	for debug_path in ["Panel/Content/Title", "Panel/Content/Detail", "Panel/Content/SelectedAction", "Panel/Content/Grid", "Panel/Content/Footer"]:
		var debug_control := overlay.get_node(debug_path) as Control
		control_heights.append("%s=%.1f/min%.1f" % [debug_control.name, debug_control.size.y, debug_control.get_combined_minimum_size().y])
	var bottom_reserve := float(overlay.layout_metrics.get("bottom_reserve", 0.0))
	if panel_rect.position.y < float(overlay.layout_metrics.get("top_reserve", 0.0)) - 0.5:
		failures.append("%s panel_top=%s requested=%s marker=%s children=%s" % [state_id, panel_rect.position.y, requested_panel_rect, overlay.marker_size.y, ",".join(control_heights)])
	if panel_rect.end.y > float(viewport_size.y) - bottom_reserve + 0.5:
		failures.append("%s panel_bottom=%s safe_bottom=%s requested=%s marker=%s children=%s" % [state_id, panel_rect.end.y, float(viewport_size.y) - bottom_reserve, requested_panel_rect, overlay.marker_size.y, ",".join(control_heights)])
	for path in ["Panel/Content/Title", "Panel/Content/Detail", "Panel/Content/SelectedAction", "Panel/Content/Grid", "Panel/Content/Footer"]:
		var control := overlay.get_node(path) as Control
		if not control.visible:
			continue
		var rect := control.get_global_rect()
		if rect.position.y < panel_rect.position.y - 0.5 or rect.end.y > panel_rect.end.y + 0.5:
			failures.append("%s %s_y=%s..%s panel=%s..%s" % [state_id, control.name, rect.position.y, rect.end.y, panel_rect.position.y, panel_rect.end.y])
		if rect.position.x < panel_rect.position.x - 0.5 or rect.end.x > panel_rect.end.x + 0.5:
			failures.append("%s %s_x=%s..%s panel=%s..%s" % [state_id, control.name, rect.position.x, rect.end.x, panel_rect.position.x, panel_rect.end.x])


func _assert_transparent_hierarchy_and_pixel_tiles(
	overlay: MapOverlayPanel,
	state_id: StringName,
	viewport_size: Vector2i,
	failures: Array[String]
) -> void:
	var panel := overlay.get_node("Panel") as Control
	var panel_rect := panel.get_global_rect()
	if panel.get_theme_stylebox(&"panel") is StyleBoxTexture:
		failures.append("%s outer_host_is_still_a_texture_frame" % state_id)
	for path in ["Panel/Content/Title", "Panel/Content/Detail", "Panel/Content/Footer"]:
		var control := overlay.get_node(path) as Control
		if control.get_theme_stylebox(&"normal") is StyleBoxTexture:
			failures.append("%s %s_is_still_a_full_texture_strip" % [state_id, control.name])
	var controls: Array[Control] = [
		overlay.get_node("Panel/Content/Title") as Control,
		overlay.get_node("Panel/Content/Grid") as Control,
		overlay.get_node("Panel/Content/Detail") as Control,
		overlay.get_node("Panel/Content/SelectedAction") as Control,
		overlay.get_node("Panel/Content/Footer") as Control,
	]
	var previous_visible: Control = null
	for control in controls:
		if not control.visible:
			continue
		if previous_visible != null and previous_visible.get_global_rect().end.y > control.get_global_rect().position.y + 0.5:
			failures.append("%s visual_order_overlap=%s>%s" % [state_id, previous_visible.name, control.name])
		previous_visible = control
	var grid := controls[1] as GridContainer
	if grid.size.y < panel.size.y * 0.68:
		failures.append("%s grid_not_visual_focus=%s panel=%s" % [state_id, grid.size.y, panel.size.y])
	var side_lane := minf(panel_rect.position.x, float(viewport_size.x) - panel_rect.end.x)
	if side_lane < 100.0:
		failures.append("%s outside_click_lane_too_small=%s" % [state_id, side_lane])
	for child in grid.get_children():
		if not (child is Button):
			continue
		var tile_style := (child as Button).get_theme_stylebox(&"normal")
		if not (tile_style is StyleBoxTexture):
			failures.append("%s %s_lost_pixel_tile_material" % [state_id, child.name])
		break


func _force_single_line_detail(overlay: MapOverlayPanel) -> void:
	var detail := overlay.get_node("Panel/Content/Detail") as Label
	detail.text = "(6,7) · 已探索 · 普通房 · 距离 2 · 周围雷险 1"


func _assert_text_content_budget(overlay: MapOverlayPanel, state_id: StringName, failures: Array[String]) -> void:
	for entry: Dictionary in [
		{"path": "Panel/Content/Title", "lines": 1},
		{"path": "Panel/Content/Detail", "lines": 1},
		{"path": "Panel/Content/Footer", "lines": 1},
	]:
		var label := overlay.get_node(String(entry["path"])) as Label
		var actual_lines := label.get_line_count()
		var expected_lines := int(entry["lines"])
		if actual_lines != expected_lines:
			failures.append("%s %s_lines=%d expected=%d" % [state_id, label.name, actual_lines, expected_lines])
			continue
		var font := label.get_theme_font(&"font")
		var font_size := label.get_theme_font_size(&"font_size")
		var line_spacing := label.get_theme_constant(&"line_spacing")
		var required_height := font.get_height(font_size) * float(actual_lines)
		required_height += float(line_spacing * maxi(0, actual_lines - 1))
		var available_height := label.size.y
		if available_height + 0.5 < required_height:
			failures.append("%s %s_text_height=%.1f available=%.1f lines=%d font=%d spacing=%d" % [
				state_id,
				label.name,
				required_height,
				available_height,
				actual_lines,
				font_size,
				line_spacing,
			])


func _assert_player_facing_labels(resolution_id: StringName, failures: Array[String]) -> void:
	var unknown := MiniMapViewModelScript.build_cell_view_model({
		"pos": Vector2i(4, 5),
		"known_state": &"unknown",
		"room_type": &"Unknown",
	}, Vector2i(5, 8))
	var detail := String(unknown.get("detail_text", ""))
	if detail.contains("Unknown") or detail.contains("Normal") or detail.contains("runtime"):
		failures.append("%s raw_enum_leaked=%s" % [resolution_id, detail])
	if detail.contains("\n"):
		failures.append("%s detail_line_count=%d" % [resolution_id, detail.count("\n") + 1])


func _full_map_model(grid_edge: int) -> MiniMapViewModel:
	var model := MiniMapViewModelScript.new() as MiniMapViewModel
	model.width = grid_edge
	model.height = grid_edge
	var current := Vector2i(grid_edge / 2, grid_edge / 2)
	for y in range(grid_edge):
		for x in range(grid_edge):
			model.room_markers.append({
				"pos": Vector2i(x, y),
				"label": "P" if Vector2i(x, y) == current else "?",
				"known_state": &"unknown",
				"room_type": &"Normal",
				"is_current": Vector2i(x, y) == current,
				"revealed": Vector2i(x, y) == current,
				"action_id": &"current" if Vector2i(x, y) == current else &"toggle_flag",
				"action_label": "当前位置" if Vector2i(x, y) == current else "标记雷险",
				"action_enabled": Vector2i(x, y) != current,
				"disabled_reason": "current_room" if Vector2i(x, y) == current else "",
				"detail_text": "cell",
			})
	return model


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame
