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


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	for resolution_id: StringName in RESOLUTIONS:
		var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(resolution_id)
		var viewport_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
		profile["actual_viewport_size"] = viewport_size
		root.size = viewport_size
		var canvas := Control.new()
		canvas.size = viewport_size
		root.add_child(canvas)
		var overlay := MapOverlayScene.instantiate() as MapOverlayPanel
		canvas.add_child(overlay)
		overlay.apply_layout_profile(profile)
		overlay.apply_view_model(_full_map_model())
		overlay.show_overlay()
		await _frames(4)
		_assert_controls_inside_panel(overlay, resolution_id, viewport_size, failures)
		var close_event := InputEventKey.new()
		close_event.keycode = KEY_M
		close_event.pressed = true
		overlay.call("_input", close_event)
		if overlay.visible:
			failures.append("%s map_toggle_m_did_not_close" % resolution_id)
		overlay.show_overlay()
		await _frames(2)
		overlay.selected_marker = {
			"pos": Vector2i(5, 8),
			"detail_text": "第一行：状态与房型\n第二行：风险与动作",
		}
		overlay.selected_feedback_text = "second footer line"
		overlay.call("_rebuild_grid")
		await _frames(4)
		_assert_controls_inside_panel(overlay, StringName("%s-selected" % resolution_id), viewport_size, failures)
		_assert_player_facing_labels(resolution_id, failures)
		var detail := overlay.get_node("Panel/Content/Detail") as Label
		if not detail.visible or detail.text == "" or detail.get_theme_font_size("font_size") < 18:
			failures.append("%s selected_detail_not_readable" % resolution_id)
		canvas.queue_free()
		await _frames(2)
	if failures.is_empty():
		print("ART24_MAP_OVERLAY_SCENE=PASS resolutions=5 states=overview,selected detail=visible controls=inside_panel toggle=m_close")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("ART24_MAP_OVERLAY_SCENE=FAIL failures=%d" % failures.size())
		quit(2)


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
		var rect := control.get_global_rect()
		if rect.position.y < panel_rect.position.y - 0.5 or rect.end.y > panel_rect.end.y + 0.5:
			failures.append("%s %s_y=%s..%s panel=%s..%s" % [state_id, control.name, rect.position.y, rect.end.y, panel_rect.position.y, panel_rect.end.y])
		if rect.position.x < panel_rect.position.x - 0.5 or rect.end.x > panel_rect.end.x + 0.5:
			failures.append("%s %s_x=%s..%s panel=%s..%s" % [state_id, control.name, rect.position.x, rect.end.x, panel_rect.position.x, panel_rect.end.x])


func _assert_player_facing_labels(resolution_id: StringName, failures: Array[String]) -> void:
	var unknown := MiniMapViewModelScript.build_cell_view_model({
		"pos": Vector2i(4, 5),
		"known_state": &"unknown",
		"room_type": &"Unknown",
	}, Vector2i(5, 8))
	var detail := String(unknown.get("detail_text", ""))
	if detail.contains("Unknown") or detail.contains("Normal") or detail.contains("runtime"):
		failures.append("%s raw_enum_leaked=%s" % [resolution_id, detail])
	if detail.count("\n") != 1:
		failures.append("%s detail_line_count=%d" % [resolution_id, detail.count("\n") + 1])


func _full_map_model() -> MiniMapViewModel:
	var model := MiniMapViewModelScript.new() as MiniMapViewModel
	model.width = 10
	model.height = 10
	for y in range(10):
		for x in range(10):
			model.room_markers.append({
				"pos": Vector2i(x, y),
				"label": "P" if x == 5 and y == 8 else "?",
				"known_state": &"unknown",
				"room_type": &"Normal",
				"is_current": x == 5 and y == 8,
				"revealed": x == 5 and y == 8,
				"detail_text": "cell",
			})
	return model


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame
