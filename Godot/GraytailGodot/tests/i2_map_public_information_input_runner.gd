extends SceneTree

const MiniMapViewModelScript := preload("res://scripts/ui/minimap/minimap_view_model.gd")
const MiniMapScene := preload("res://scenes/ui/minimap/minimap_panel.tscn")
const MapOverlayScene := preload("res://scenes/ui/map_overlay/map_overlay_panel.tscn")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")

var failures: Array[String] = []
var mini_open_count := 0
var map_cell_action_count := 0
var map_close_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var snapshot := _public_snapshot_with_internal_decoys()
	var view_model := MiniMapViewModelScript.build_from_run_map_snapshot(snapshot)
	_check_public_projection(view_model)
	var markers_before := view_model.room_markers.duplicate(true)
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)
	await _check_minimap(canvas, view_model)
	await _check_overlay(canvas, view_model)
	_check(view_model.room_markers == markers_before, "Map open/focus/close mutated the public marker projection")
	_check_production_sources_are_read_only()
	canvas.queue_free()
	await _frames(2)
	_finish()


func _check_public_projection(view_model: MiniMapViewModel) -> void:
	_check(view_model.width == 3 and view_model.height == 2, "Map dimensions did not come from KnownMap")
	var retained := var_to_str(view_model.map_snapshot)
	_check(not retained.contains("TruthMap") and not retained.contains("internal-secret"), "MiniMapViewModel retained an internal map layer")
	var hidden := _marker_at(view_model, Vector2i(0, 0))
	_check(StringName(hidden.get("room_type", &"Mine")) == &"Unknown", "Unknown cell leaked its hidden room type")
	_check(int(hidden.get("adjacent_mines", 99)) == -1, "Unknown cell leaked its hidden adjacent-mine count")
	_check(not String(hidden.get("detail_text", "")).contains("8"), "Unknown-cell detail leaked a hidden adjacent-mine count")
	var scanned := _marker_at(view_model, Vector2i(1, 0))
	_check(StringName(scanned.get("room_type", &"Mine")) == &"Unknown", "Scanned-only cell leaked a hidden room type")
	_check(int(scanned.get("adjacent_mines", -1)) == 3, "Scanned public adjacent-mine count was discarded")
	var explored := _marker_at(view_model, Vector2i(2, 0))
	_check(StringName(explored.get("room_type", &"Unknown")) == &"Chest", "Explored public room type was discarded")
	_check(int(explored.get("adjacent_mines", -1)) == 0, "Explored zero adjacent-mine count was discarded")
	var visible_exit := _marker_at(view_model, Vector2i(0, 1))
	_check(StringName(visible_exit.get("room_type", &"Unknown")) == &"Exit", "Public visible exit was hidden")


func _check_minimap(canvas: Control, view_model: MiniMapViewModel) -> void:
	var panel := MiniMapScene.instantiate() as MiniMapPanel
	panel.position = Vector2(20, 20)
	panel.size = Vector2(260, 220)
	panel.open_map_requested.connect(func() -> void: mini_open_count += 1)
	canvas.add_child(panel)
	panel.apply_view_model(view_model)
	await _frames(2)
	_check(panel.focus_mode == Control.FOCUS_ALL, "MiniMapPanel is not keyboard/gamepad focusable")
	var hidden_cell := panel.get_node_or_null("Grid/MiniMapCell_0_0") as Control
	var scanned_cell := panel.get_node_or_null("Grid/MiniMapCell_1_0") as Control
	var explored_cell := panel.get_node_or_null("Grid/MiniMapCell_2_0") as Control
	_check(hidden_cell != null and hidden_cell.get_node_or_null("AdjacentMineCount") == null, "Unknown minimap cell rendered a hidden adjacent-mine number")
	_check(_adjacent_label_text(scanned_cell) == "3", "Scanned minimap cell omitted its bottom-right adjacent-mine number")
	_check(_adjacent_label_text(explored_cell) == "0", "Explored minimap cell omitted public zero adjacent-mine number")
	panel.grab_focus()
	var enter_event := InputEventKey.new()
	enter_event.keycode = KEY_ENTER
	enter_event.pressed = true
	panel.call("_gui_input", enter_event)
	_check(mini_open_count == 1, "Focused minimap did not emit one explicit open request")
	panel.queue_free()
	await _frames(1)


func _check_overlay(canvas: Control, view_model: MiniMapViewModel) -> void:
	var return_button := Button.new()
	return_button.name = "MapReturnFocusProbe"
	return_button.text = "返回焦点"
	return_button.focus_mode = Control.FOCUS_ALL
	return_button.position = Vector2(20, 660)
	return_button.size = Vector2(120, 40)
	canvas.add_child(return_button)
	var overlay := MapOverlayScene.instantiate() as MapOverlayPanel
	overlay.cell_action_requested.connect(func(_marker: Dictionary) -> void: map_cell_action_count += 1)
	overlay.close_requested.connect(func() -> void: map_close_count += 1)
	canvas.add_child(overlay)
	var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(&"1280x720")
	overlay.apply_layout_profile(profile)
	overlay.apply_view_model(view_model)
	return_button.grab_focus()
	overlay.show_overlay()
	await _frames(3)
	var preferred := overlay.preferred_focus_control()
	_check(preferred != null and preferred.has_focus(), "Expanded map did not move focus into its grid")
	var selected_action := overlay.get_node_or_null("Panel/Content/SelectedAction") as Button
	_check(selected_action != null and not selected_action.visible, "Expanded map keeps a disabled action button visible")
	var hidden_button := overlay.get_node_or_null("Panel/Content/Grid/MapCell_0_0") as Button
	var scanned_button := overlay.get_node_or_null("Panel/Content/Grid/MapCell_1_0") as Button
	var explored_button := overlay.get_node_or_null("Panel/Content/Grid/MapCell_2_0") as Button
	_check(hidden_button != null and hidden_button.get_node_or_null("AdjacentMineCount") == null, "Unknown expanded-map cell rendered a hidden adjacent-mine number")
	_check(_adjacent_label_text(scanned_button) == "3", "Expanded scanned cell omitted public adjacent-mine number")
	_check(_adjacent_label_text(explored_button) == "0", "Expanded explored cell omitted public zero adjacent-mine number")
	if scanned_button != null:
		scanned_button.grab_focus()
		await _frames(1)
	_check(map_cell_action_count == 0, "Expanded-map focus movement emitted a cell action")
	var footer := overlay.get_node_or_null("Panel/Content/Footer") as Label
	_check(footer != null and not footer.text.contains("\n") and footer.text.contains("点击外部"), "Expanded-map footer lacks compact single-line outside-click guidance")
	var panel_internal_outside := _find_panel_internal_outside_point(overlay)
	_check(panel_internal_outside.x >= 0.0, "Expanded map has no panel-internal lane outside its actual visible controls")
	var outside_click := InputEventMouseButton.new()
	outside_click.button_index = MOUSE_BUTTON_LEFT
	outside_click.pressed = true
	outside_click.position = panel_internal_outside if panel_internal_outside.x >= 0.0 else Vector2(5, 5)
	outside_click.global_position = outside_click.position
	Input.parse_input_event(outside_click)
	await _frames(2)
	var outside_release := outside_click.duplicate() as InputEventMouseButton
	outside_release.pressed = false
	Input.parse_input_event(outside_release)
	_check(not overlay.visible and map_close_count == 1, "Outside left click did not close exactly one expanded map")
	_check(return_button.has_focus(), "Outside-click close did not restore prior focus")
	_check(map_cell_action_count == 0, "Outside-click close emitted a map cell action")

	return_button.grab_focus()
	overlay.show_overlay()
	await _frames(2)
	var escape_event := InputEventAction.new()
	escape_event.action = &"cancel"
	escape_event.pressed = true
	overlay.call("_input", escape_event)
	await _frames(2)
	_check(not overlay.visible and map_close_count == 2, "Esc did not close exactly one expanded map")
	_check(return_button.has_focus(), "Esc close did not restore prior focus")

	overlay.show_overlay()
	await _frames(2)
	overlay.hide_overlay()
	await _frames(1)
	_check(map_close_count == 2, "Programmatic map hide emitted a user-close request")
	_check(map_cell_action_count == 0, "Map open/focus/close path emitted a cell action")
	overlay.queue_free()
	return_button.queue_free()
	await _frames(1)


func _check_production_sources_are_read_only() -> void:
	var view_model_source := FileAccess.get_file_as_string("res://scripts/ui/minimap/minimap_view_model.gd")
	var minimap_source := FileAccess.get_file_as_string("res://scripts/ui/minimap/minimap_panel.gd")
	var overlay_source := FileAccess.get_file_as_string("res://scripts/ui/map_overlay/map_overlay_panel.gd")
	for source in [view_model_source, minimap_source, overlay_source]:
		_check(not source.contains("dispatch("), "Map presentation source dispatches a domain command")
		_check(not source.contains("attempt_room_transition") and not source.contains("request_flee"), "Map presentation source owns movement/combat authority")
	_check(not view_model_source.contains("\"TruthMap\""), "MiniMapViewModel reads the internal map layer")


func _public_snapshot_with_internal_decoys() -> Dictionary:
	return {
		"TruthMap": {"internal-secret": true, "width": 99, "height": 99},
		"RunMap": {"width": 99, "height": 99, "player_pos": Vector2i(9, 9)},
		"KnownMap": {
			"width": 3,
			"height": 2,
			"player_pos": Vector2i(1, 1),
			"public_cells": [
				{"pos": Vector2i(0, 0), "known_state": &"unknown", "room_type": &"Mine", "adjacent_mines": 8},
				{"pos": Vector2i(1, 0), "known_state": &"scanned", "scanned": true, "room_type": &"Monster", "adjacent_mines": 3},
				{"pos": Vector2i(2, 0), "known_state": &"explored", "revealed": true, "explored": true, "room_type": &"Chest", "adjacent_mines": 0},
				{"pos": Vector2i(0, 1), "known_state": &"unknown", "room_type": &"Exit", "adjacent_mines": -1},
				{"pos": Vector2i(1, 1), "known_state": &"explored", "revealed": true, "explored": true, "is_current": true, "room_type": &"Normal", "adjacent_mines": 2},
				{"pos": Vector2i(2, 1), "known_state": &"unknown", "flagged": true, "room_type": &"Event", "adjacent_mines": 7},
			],
			"read_only": true,
		},
	}


func _marker_at(view_model: MiniMapViewModel, pos: Vector2i) -> Dictionary:
	for marker in view_model.room_markers:
		if Vector2i(marker.get("pos", Vector2i(-1, -1))) == pos:
			return marker
	return {}


func _adjacent_label_text(cell: Control) -> String:
	if cell == null:
		return ""
	var label := cell.get_node_or_null("AdjacentMineCount") as Label
	return label.text if label != null else ""


func _find_panel_internal_outside_point(overlay: MapOverlayPanel) -> Vector2:
	var panel := overlay.get_node_or_null("Panel") as Control
	if panel == null:
		return Vector2(-1, -1)
	var panel_rect := panel.get_global_rect()
	for y in range(int(panel_rect.position.y) + 1, int(panel_rect.end.y), 4):
		for x in range(int(panel_rect.position.x) + 1, int(panel_rect.end.x), 4):
			var point := Vector2(x, y)
			if not bool(overlay.call("_point_hits_map_content", point)):
				return point
	return Vector2(-1, -1)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("I2_MAP_PUBLIC_INFORMATION_INPUT=PASS source=KnownMap adjacent=known_only minimap=focusable overlay=outside_click,esc focus_restore=PASS presentation_commands=0")
		quit(0)
		return
	for failure in failures:
		push_error("I2 map public information/input failure: " + failure)
	print("I2_MAP_PUBLIC_INFORMATION_INPUT=FAIL failures=%d" % failures.size())
	quit(1)
