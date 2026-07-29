extends SceneTree

const MiniMapViewModelScript := preload("res://scripts/ui/minimap/minimap_view_model.gd")
const MiniMapScene := preload("res://scenes/ui/minimap/minimap_panel.tscn")
const MapOverlayScene := preload("res://scenes/ui/map_overlay/map_overlay_panel.tscn")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")

var failures: Array[String] = []
var mini_open_count := 0
var emitted_actions: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)
	for map_size in [7, 10, 13]:
		await _check_local_minimap(canvas, map_size)
	await _check_expanded_map(canvas, 10)
	canvas.queue_free()
	await _frames(2)
	_finish()


func _check_local_minimap(canvas: Control, map_size: int) -> void:
	var view_model := MiniMapViewModelScript.build_from_run_map_snapshot(_public_snapshot(map_size))
	var retained := var_to_str(view_model.map_snapshot)
	_check(not retained.contains("TruthMap") and not retained.contains("internal-secret"), "%dx%d minimap retained an internal field" % [map_size, map_size])
	var panel := MiniMapScene.instantiate() as MiniMapPanel
	panel.position = Vector2(20, 20)
	panel.size = Vector2(260, 220)
	panel.open_map_requested.connect(func() -> void: mini_open_count += 1)
	canvas.add_child(panel)
	panel.apply_layout_profile(UILayoutProfileScript.profile_for_resolution(&"1280x720"))
	panel.apply_view_model(view_model)
	await _frames(2)
	var grid := panel.get_node("Grid") as GridContainer
	_check(panel.visible_map_rect.size == Vector2i(5, 5), "%dx%d minimap is not a 5x5 local context window" % [map_size, map_size])
	_check(grid.get_child_count() == 25 and grid.columns == 5, "%dx%d minimap rendered the full map instead of 25 local cells" % [map_size, map_size])
	_check(panel.marker_size.x >= 40.0 and panel.marker_size.y >= 36.0, "%dx%d local minimap cells became unreadably small" % [map_size, map_size])
	_check(panel.get_node_or_null("Grid/MiniMapCell_0_0") == null, "%dx%d local minimap still includes a distant corner" % [map_size, map_size])
	var current := _current_pos(map_size)
	var monster_pos := current + Vector2i(-1, 0)
	var mine_pos := current + Vector2i(1, 0)
	var monster_cell := panel.get_node_or_null("Grid/MiniMapCell_%d_%d" % [monster_pos.x, monster_pos.y]) as Control
	var mine_cell := panel.get_node_or_null("Grid/MiniMapCell_%d_%d" % [mine_pos.x, mine_pos.y]) as Control
	_check(monster_cell != null and StringName(monster_cell.get_meta("map_marker_state", &"")) == &"monster", "%dx%d minimap lost the Monster semantic" % [map_size, map_size])
	_check(mine_cell != null and StringName(mine_cell.get_meta("map_marker_state", &"")) == &"mine", "%dx%d minimap lost the Mine semantic" % [map_size, map_size])
	var monster_icon := monster_cell.get_node_or_null("SemanticMarker") as TextureRect if monster_cell != null else null
	var mine_icon := mine_cell.get_node_or_null("SemanticMarker") as TextureRect if mine_cell != null else null
	_check(monster_icon != null and mine_icon != null and monster_icon.texture != mine_icon.texture, "%dx%d minimap Monster and Mine do not have distinct rendered icons" % [map_size, map_size])
	if map_size == 7:
		panel.grab_focus()
		var gamepad_accept := InputEventAction.new()
		gamepad_accept.action = &"ui_accept"
		gamepad_accept.pressed = true
		panel.call("_gui_input", gamepad_accept)
		_check(mini_open_count == 1, "Focused minimap did not preserve abstract keyboard/gamepad accept")
	panel.queue_free()
	await _frames(1)


func _check_expanded_map(canvas: Control, map_size: int) -> void:
	var view_model := MiniMapViewModelScript.build_from_run_map_snapshot(_public_snapshot(map_size))
	var return_button := Button.new()
	return_button.text = "返回"
	return_button.focus_mode = Control.FOCUS_ALL
	canvas.add_child(return_button)
	var overlay := MapOverlayScene.instantiate() as MapOverlayPanel
	overlay.cell_action_requested.connect(func(marker: Dictionary) -> void: emitted_actions.append(marker.duplicate(true)))
	canvas.add_child(overlay)
	overlay.apply_layout_profile(UILayoutProfileScript.profile_for_resolution(&"1280x720"))
	overlay.apply_view_model(view_model)
	return_button.grab_focus()
	overlay.show_overlay()
	await _frames(3)
	var grid := overlay.get_node("Panel/Content/Grid") as GridContainer
	var detail := overlay.get_node("Panel/Content/Detail") as Label
	var action_button := overlay.get_node("Panel/Content/SelectedAction") as Button
	var footer := overlay.get_node("Panel/Content/Footer") as Label
	_check(grid.get_child_count() == map_size * map_size, "Expanded map did not retain the full public overview")
	_check(detail.visible and detail.text != "" and detail.get_theme_font_size("font_size") >= 18, "Expanded map lacks a synchronized large summary")
	_check(not detail.text.contains("\n") and footer != null and not footer.text.contains("\n"), "Expanded map reintroduced multiline detail/footer strips")
	_check(action_button.focus_mode == Control.FOCUS_ALL, "Explicit map action is not keyboard/gamepad focusable")
	_check(not action_button.visible, "Disabled current-room action remains visible")
	_check(grid.get_global_rect().end.y <= detail.get_global_rect().position.y + 0.5, "Expanded-map detail appears above or over the grid")
	if action_button.visible:
		_check(detail.get_global_rect().end.y <= action_button.get_global_rect().position.y + 0.5, "Expanded-map action appears above or over its detail")
	var current := _current_pos(map_size)
	var monster_button := grid.get_node("MapCell_%d_%d" % [current.x - 1, current.y]) as Button
	var mine_button := grid.get_node("MapCell_%d_%d" % [current.x + 1, current.y]) as Button
	_check(StringName(monster_button.get_meta("map_marker_state", &"")) == &"monster", "Expanded map collapsed Monster into another semantic")
	_check(StringName(mine_button.get_meta("map_marker_state", &"")) == &"mine", "Expanded map lost the Mine semantic")
	# I4-R043 replaces the legacy Button.icon assertion: semantic art now has a
	# dedicated, clipped layer so it cannot collide with count/focus layers.
	var monster_icon := monster_button.get_node_or_null("SemanticMarker") as TextureRect
	var mine_icon := mine_button.get_node_or_null("SemanticMarker") as TextureRect
	_check(
		monster_icon != null
		and mine_icon != null
		and monster_icon.texture != null
		and mine_icon.texture != null
		and monster_icon.texture != mine_icon.texture,
		"Expanded map Monster and Mine do not have distinct rendered semantic-layer icons"
	)
	monster_button.grab_focus()
	await _frames(1)
	_check(Vector2i(overlay.selected_marker.get("pos", Vector2i(-1, -1))) == current + Vector2i(-1, 0), "Focus movement did not synchronize selection")
	_check(emitted_actions.is_empty(), "Focus movement executed a map action")
	await _activate_focused_semantic(monster_button)
	_check(emitted_actions.is_empty(), "Disabled focused-cell semantic activation emitted a domain request")
	var flag_pos := current + Vector2i(0, -1)
	var flag_button := grid.get_node("MapCell_%d_%d" % [flag_pos.x, flag_pos.y]) as Button
	await _click_control(flag_button)
	_check(emitted_actions.size() == 1, "One pointer click did not emit exactly one unflag action")
	if emitted_actions.size() == 1:
		_check(StringName(emitted_actions[0].get("action_id", &"")) == &"toggle_flag", "Pointer activation emitted the wrong map action")
		_check(bool(emitted_actions[0].get("flagged", false)), "Pointer activation did not preserve the selected flagged-cell projection")
	_check(not action_button.disabled and action_button.text in ["标记雷险", "取消标记"], "Selected flag action was not exposed through a compact explicit confirmation")
	_check(not action_button.text.contains("确认"), "Selected map action repeats the confirmation instruction in its label")
	var unknown_button := grid.get_node("MapCell_0_0") as Button
	await _activate_focused_semantic(unknown_button)
	_check(emitted_actions.size() == 2, "One semantic focus activation did not emit exactly one flag action")
	if emitted_actions.size() == 2:
		_check(StringName(emitted_actions[1].get("action_id", &"")) == &"toggle_flag", "Semantic activation emitted the wrong map action")
		_check(not bool(emitted_actions[1].get("flagged", false)), "Semantic activation did not preserve the selected unknown-cell projection")
	var return_pos := current + Vector2i(-1, -1)
	var return_cell := grid.get_node("MapCell_%d_%d" % [return_pos.x, return_pos.y]) as Button
	await _click_control(return_cell)
	_check(emitted_actions.size() == 3, "One pointer click did not emit exactly one fast-return action")
	if emitted_actions.size() == 3:
		_check(StringName(emitted_actions[2].get("action_id", &"")) == &"fast_return", "Explored-cell pointer activation did not request fast return")
	var bottom_button := grid.get_node("MapCell_0_%d" % (map_size - 1)) as Button
	if bottom_button != null:
		var bottom_neighbor := bottom_button.get_node_or_null(bottom_button.focus_neighbor_bottom) as Control
		_check(bottom_neighbor == action_button, "Bottom-row focus does not move downward to the visually lower confirmation button")
	var hidden_button := grid.get_node("MapCell_0_0") as Button
	_check(StringName(hidden_button.get_meta("map_marker_state", &"")) == &"unknown", "Expanded map leaked a hidden decoy room semantic")
	var outside_click := InputEventMouseButton.new()
	outside_click.button_index = MOUSE_BUTTON_LEFT
	outside_click.pressed = true
	outside_click.position = Vector2(5, 5)
	overlay.call("_gui_input", outside_click)
	await _frames(2)
	_check(not overlay.visible and return_button.has_focus(), "Outside-click close or focus restoration regressed")
	overlay.queue_free()
	return_button.queue_free()
	await _frames(1)


func _public_snapshot(map_size: int) -> Dictionary:
	var current := _current_pos(map_size)
	var public_cells: Array[Dictionary] = []
	for y in range(map_size):
		for x in range(map_size):
			var pos := Vector2i(x, y)
			var cell := {
				"pos": pos,
				"known_state": &"unknown",
				"room_type": &"Monster",
				"adjacent_mines": 8,
				"internal-secret": "must be discarded",
			}
			if pos == current:
				cell.merge({"known_state": &"explored", "revealed": true, "explored": true, "is_current": true, "room_type": &"Normal", "adjacent_mines": 2}, true)
			elif pos == current + Vector2i(-1, 0):
				cell.merge({"known_state": &"explored", "revealed": true, "explored": true, "room_type": &"Monster", "adjacent_mines": 1}, true)
			elif pos == current + Vector2i(1, 0):
				cell.merge({"known_state": &"explored", "revealed": true, "explored": true, "room_type": &"Mine", "adjacent_mines": 2}, true)
			elif pos == current + Vector2i(-1, -1):
				cell.merge({
					"known_state": &"explored",
					"revealed": true,
					"explored": true,
					"room_type": &"Normal",
					"adjacent_mines": 1,
					"return_eligibility": {"eligible": true, "reason_code": &""},
				}, true)
			elif pos == current + Vector2i(0, -1):
				cell.merge({"flagged": true, "room_type": &"Event"}, true)
			public_cells.append(cell)
	return {
		"TruthMap": {"internal-secret": true, "width": 99, "height": 99},
		"KnownMap": {
			"width": map_size,
			"height": map_size,
			"player_pos": current,
			"public_cells": public_cells,
			"read_only": true,
		},
	}


func _current_pos(map_size: int) -> Vector2i:
	return Vector2i(map_size / 2, map_size - 2)


func _click_control(control: Control) -> void:
	if control == null:
		return
	var center := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	motion.global_position = center
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = center
		event.global_position = center
		Input.parse_input_event(event)
		await process_frame


func _activate_focused_semantic(control: Control) -> void:
	if control == null:
		return
	control.grab_focus()
	await process_frame
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = &"ui_accept"
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("I3_MAP_LOCAL_CONTEXT_INTERACTION=PASS sizes=7,10,13 minimap=5x5 semantics=monster,mine,flag,fast_return activation=pointer,ui_accept exactly_once=PASS focus=selection_only authority=signal_boundary known_map=sealed close=outside_click")
		quit(0)
		return
	for failure in failures:
		push_error("I3 map local-context/interaction failure: " + failure)
	print("I3_MAP_LOCAL_CONTEXT_INTERACTION=FAIL failures=%d" % failures.size())
	quit(1)
