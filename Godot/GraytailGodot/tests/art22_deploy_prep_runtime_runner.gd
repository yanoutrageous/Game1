extends SceneTree

var failures: Array[String] = []
var route_intents: Array[Dictionary] = []
var start_intents: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)

	var shell_script := load("res://scripts/ui/deploy_prep/deploy_prep_shell.gd")
	_check(shell_script != null, "DeployPrepShell could not be loaded")
	if shell_script == null:
		_finish()
		return
	var shell := shell_script.new() as Control
	shell.name = "Art22RuntimeDeployPrep"
	shell.size = Vector2(1280, 720)
	canvas.add_child(shell)
	shell.connect("navigation_intent_requested", _on_route_intent)
	shell.connect("deploy_start_intent_requested", _on_start_intent)
	shell.call("build")
	await _frames(12)

	_check(shell.size == Vector2(1280, 720), "DeployPrep does not fill the design canvas")
	for root_name in [
		"BackgroundRoot", "DecorationRoot", "CharacterRoot", "MainContentRoot",
		"SideStatusRoot", "PrimaryActionRoot", "FloatingInfoRoot", "OverlayRoot", "ModalRoot"
	]:
		_check(shell.get_node_or_null(root_name) != null, "Missing layer root: " + root_name)
	_check_texture_size(shell, "BackgroundRoot/DeployPrepSceneCleanPlate", Vector2(1280, 720))
	_check_texture_size(shell, "MainContentRoot/DeployParchmentGroup/DeployParchment", Vector2(688, 692))
	_check_texture_size(shell, "SideStatusRoot/DeploySummaryBoard", Vector2(252, 494))
	_check(shell.get_node_or_null("CharacterRoot/DeployCharacter") is TextureRect, "Environment-integrated character is missing")
	_check(shell.get_node_or_null("PrimaryActionRoot/DeployNavMain") is Button, "Main menu plaque is missing")
	_check(shell.get_node_or_null("PrimaryActionRoot/DeployNavLongTerm") is Button, "Long-term plaque is missing")
	_check(shell.get_node_or_null("MainContentRoot/DeployCollapseHandle") is Button, "Parchment collapse handle is missing")
	_check((shell.get("tab_buttons") as Dictionary).size() == 5, "Primary tab count must remain five")
	_check((shell.get("summary_buttons") as Dictionary).size() == 4, "Summary board must expose four pages")
	_check((shell.get("filter_buttons") as Dictionary).size() == 6, "Default map filters must expose six entries")
	_check(not ((shell.get("primary_tab_button_group") as ButtonGroup).allow_unpress), "Primary tabs can be visually unselected")
	_check(not ((shell.get("filter_button_group") as ButtonGroup).allow_unpress), "Secondary filters can be visually unselected")
	_check(not ((shell.get("summary_button_group") as ButtonGroup).allow_unpress), "Summary tabs can be visually unselected")
	var active_filter_before := (shell.get("filter_buttons") as Dictionary)[&"all"] as Button
	shell.call("_on_filter_pressed", &"all")
	await _frames(3)
	var active_filter_after := (shell.get("filter_buttons") as Dictionary)[&"all"] as Button
	_check(active_filter_before == active_filter_after, "Selecting a secondary filter rebuilt the clicked button")
	_check(active_filter_after.button_pressed and active_filter_after.text == "全部", "Reselecting the active filter lost its selected state or label")
	_check((shell.get("card_views") as Array).size() == 8, "M7 default map cards must expose all eight playable entries")
	_check_motion_contract(shell)

	var card_views := shell.get("card_views") as Array
	var initial_height := (card_views[0] as Control).size.y
	var card_button := (card_views[1] as Control).call("focus_button") as Button
	card_button.emit_signal("pressed")
	await _frames(2)
	_check((shell.get("card_views") as Array).size() == 8, "Card selection rebuilt or dropped M7 map cards")
	_check(is_equal_approx((shell.get("card_views") as Array)[1].size.y, initial_height), "Selected card changed fixed row height")

	var parchment := shell.get("parchment_group") as Control
	shell.call("set_parchment_collapsed", true, false)
	_check(parchment.position == Vector2(0, -706), "Collapsed parchment did not fully clear the environment")
	_check((shell.get_node("BackgroundRoot/DeployPrepSceneCleanPlate") as CanvasItem).visible, "Collapse hides the exploration background")
	shell.call("set_parchment_collapsed", false, false)
	_check(parchment.position == Vector2.ZERO, "Parchment did not restore to its layout contract")

	var expected_counts := {
		&"map": [6, 8],
		&"warehouse": [6, 1],
		&"claim": [6, 5],
		&"objective": [6, 1],
		&"loadout": [10, 5],
	}
	var secondary_state_count := 0
	for tab_id in expected_counts:
		shell.call("show_tab", tab_id)
		await _frames(3)
		var expected := expected_counts[tab_id] as Array
		_check((shell.get("filter_buttons") as Dictionary).size() == int(expected[0]), "Filter count mismatch for " + String(tab_id))
		_check((shell.get("card_views") as Array).size() >= int(expected[1]), "Card coverage is incomplete for " + String(tab_id))
		_check(((shell.get("tab_buttons") as Dictionary)[tab_id] as Button).button_pressed, "Primary tab lacks selected feedback: " + String(tab_id))
		var filter_ids := (shell.get("filter_buttons") as Dictionary).keys()
		for raw_filter_id in filter_ids:
			var filter_id := StringName(raw_filter_id)
			var filter_button := (shell.get("filter_buttons") as Dictionary)[filter_id] as Button
			filter_button.emit_signal("pressed")
			await _frames(2)
			secondary_state_count += 1
			_check(StringName((shell.get("current_model") as Dictionary).get("selected_filter", &"")) == filter_id, "Secondary filter did not become active: %s/%s" % [String(tab_id), String(filter_id)])
			_check(((shell.get("filter_buttons") as Dictionary)[filter_id] as Button).button_pressed, "Secondary filter lacks selected feedback: %s/%s" % [String(tab_id), String(filter_id)])
			_check(not (shell.get("card_views") as Array).is_empty(), "Secondary filter produced an unreachable empty surface: %s/%s" % [String(tab_id), String(filter_id)])
			_check_card_layout(shell, tab_id, filter_id)
			for raw_row in shell.get("summary_row_labels") as Array:
				var row_label := raw_row as Label
				_check(row_label != null and not row_label.text.strip_edges().is_empty(), "Summary row is empty for %s/%s" % [String(tab_id), String(filter_id)])
	_check(secondary_state_count == 34, "Expected 34 primary/secondary combinations, got %d" % secondary_state_count)

	shell.call("show_tab", &"loadout")
	await _frames(3)
	var loadout_scroll := shell.get("filter_scroll") as ScrollContainer
	loadout_scroll.scroll_horizontal = 0
	shell.call("_on_filter_pressed", &"loadout_map")
	await _frames(4)
	_check_filter_is_visible(shell, &"loadout_map")
	shell.call("_on_filter_pressed", &"loadout_permission_interface")
	await _frames(4)
	_check_filter_is_visible(shell, &"loadout_permission_interface")
	_check(loadout_scroll.scroll_horizontal > 0, "Last loadout filter did not auto-scroll into view")
	shell.call("_on_filter_pressed", &"loadout_map")
	await _frames(4)
	_check_filter_is_visible(shell, &"loadout_map")

	shell.call("show_tab", &"map")
	await _frames(3)
	var start_button := shell.get("primary_action_button") as Button
	_check(start_button.text == "确认出发", "No-run primary action is not confirm deploy")
	start_button.emit_signal("pressed")
	await process_frame
	_check(start_intents.size() == 1, "Confirm deploy did not emit exactly one run intent")
	if start_intents.size() == 1:
		var intent := start_intents[0]
		var payload := (intent.get("payload", {}) as Dictionary)
		_check(StringName(intent.get("target", &"")) == &"run", "Deploy intent target is not run")
		_check(bool(payload.get("uses_existing_route", false)), "Deploy intent no longer uses the existing playable route")
		_check(not bool(payload.get("preview_only", true)), "Deploy intent regressed to preview-only")

	shell.call("apply_snapshot", {"run_active": true})
	await _frames(4)
	var cancel_button := shell.get("cancel_action_button") as Button
	_check(start_button.text == "继续探索", "Active-run primary action is not continue")
	_check(cancel_button.visible, "Active run does not expose cancel current exploration")
	cancel_button.emit_signal("pressed")
	await _frames(2)
	var modal := shell.get("modal_layer") as Control
	_check(modal.visible, "Cancel action did not open the strong-confirm boundary")
	_check(not (shell.get("modal_confirm_button") as Button).disabled, "M6 real abandon settlement is not confirmable")
	(shell.get("modal_cancel_button") as Button).emit_signal("pressed")
	await _frames(2)
	_check(not modal.visible, "Cancel modal did not close")
	cancel_button.emit_signal("pressed")
	await _frames(2)
	(shell.get("modal_confirm_button") as Button).emit_signal("pressed")
	await _frames(2)
	_check(start_intents.size() == 2, "Confirmed abandon did not emit one additional run intent")
	if start_intents.size() == 2:
		var abandon_payload := (start_intents[1].get("payload", {}) as Dictionary)
		_check(bool(abandon_payload.get("abandon_active_run", false)), "Confirmed abandon intent lacks M6 runtime authority marker")

	var appearance := shell.get_node("PrimaryActionRoot/DeployAppearanceButton") as Button
	appearance.emit_signal("pressed")
	await process_frame
	_check(route_intents.size() == 1, "Appearance hook did not emit one navigation intent")
	if route_intents.size() == 1:
		var payload := (route_intents[0].get("payload", {}) as Dictionary)
		_check(StringName(payload.get("module_id", &"")) == &"collection_appearance", "Appearance hook routes to the wrong long-term module")

	var result_scene := load("res://scenes/ui/result/result_panel.tscn") as PackedScene
	_check(result_scene != null, "M6 ResultPanel scene could not be loaded")
	if result_scene != null:
		var result_panel = result_scene.instantiate()
		canvas.add_child(result_panel)
		await _frames(2)
		result_panel.show_summary({
			"outcome": "Failed",
			"settlement": {
				"outcome": &"failure",
				"requires_salvage_selection": true,
				"finalized": false,
				"salvage_capacity": 4,
				"settlement_pool": [{"instance_id": "art22_m6_candidate", "display_name": "M6 Candidate", "weight": 1}],
			},
		})
		await _frames(2)
		_check(result_panel.requires_salvage_confirmation(), "M6 failure result does not expose manual salvage selection")
		var result_actions := result_panel.get_node_or_null("ResultActions") as HBoxContainer
		_check(result_actions != null and not result_actions.visible, "M6 failure result allows leaving before salvage confirmation")
		result_panel.show_summary({"outcome": "Failed", "settlement": {"outcome": &"failure", "requires_salvage_selection": false, "finalized": true}})
		await _frames(2)
		_check(not result_panel.requires_salvage_confirmation(), "M6 failure selector remains after settlement confirmation")
		_check(result_actions != null and result_actions.visible, "M6 final result does not restore navigation actions")
		result_panel.queue_free()
		await _frames(2)

	_check_focus_neighbors(shell)
	_finish()


func _check_focus_neighbors(shell: Control) -> void:
	var tabs := shell.get("tab_buttons") as Dictionary
	for raw_button in tabs.values():
		var button := raw_button as Button
		_check(not button.focus_neighbor_left.is_empty(), "Tab lacks left focus neighbor")
		_check(not button.focus_neighbor_right.is_empty(), "Tab lacks right focus neighbor")
	var card_views := shell.get("card_views") as Array
	if card_views.size() >= 2:
		var first := card_views[0].call("focus_button") as Button
		_check(not first.focus_neighbor_top.is_empty(), "Card lacks top focus neighbor")
		_check(not first.focus_neighbor_bottom.is_empty(), "Card lacks bottom focus neighbor")


func _check_filter_is_visible(shell: Control, filter_id: StringName) -> void:
	var scroll := shell.get("filter_scroll") as ScrollContainer
	var button := (shell.get("filter_buttons") as Dictionary).get(filter_id) as Button
	_check(scroll != null and button != null, "Cannot inspect filter visibility: " + String(filter_id))
	if scroll == null or button == null:
		return
	var left := float(scroll.scroll_horizontal)
	var right := left + scroll.size.x
	_check(button.position.x >= left - 1.0 and button.position.x + button.size.x <= right + 1.0, "Selected filter is outside the visible row: " + String(filter_id))


func _check_motion_contract(shell: Control) -> void:
	var frames := shell.get("character_frames") as Array
	_check(frames.size() == 8, "Character motion must load eight source frames")
	var unique_paths := {}
	for frame in frames:
		if frame is Texture2D:
			var texture := frame as Texture2D
			var identity := texture.resource_path if not texture.resource_path.is_empty() else texture.resource_name
			unique_paths[identity] = true
	_check(unique_paths.size() == 8, "Character motion frames are not resource-distinct")
	_check((shell.get("ambient_animations") as Array).size() == 8, "Expected eight ambient frame animations")
	_check((shell.get("ambient_particles") as Array).size() == 2, "Expected two ambient particle fields")
	for raw_particles in shell.get("ambient_particles") as Array:
		var particles := raw_particles as CPUParticles2D
		_check(particles != null and particles.emitting, "Ambient particle field is not live")
	var observed_frames := {}
	var observed_sway := false
	var character := shell.get("character_texture") as TextureRect
	for _index in range(48):
		shell.call("_process", 0.36)
		if character != null and character.texture != null:
			var identity := character.texture.resource_path if not character.texture.resource_path.is_empty() else character.texture.resource_name
			observed_frames[identity] = true
		var summary_root := shell.get_node_or_null("SideStatusRoot") as Control
		if summary_root != null and summary_root.position != Vector2.ZERO:
			observed_sway = true
	_check(observed_frames.size() == 8, "Character cadence did not expose all eight distinct frames")
	_check(observed_sway, "Hanging summary board did not produce subtle sway")


func _check_card_layout(shell: Control, tab_id: StringName, filter_id: StringName) -> void:
	for raw_view in shell.get("card_views") as Array:
		var view := raw_view as Control
		_check(is_equal_approx(view.size.y, 112.0), "Card height drifted for %s/%s" % [String(tab_id), String(filter_id)])
		var title := view.get_node_or_null("CardTitle") as Label
		var summary := view.get_node_or_null("CardSummary") as Label
		var state := view.get_node_or_null("CardState") as Label
		_check(title != null and title.clip_text, "Card title is not bounded for %s/%s" % [String(tab_id), String(filter_id)])
		_check(summary != null and summary.autowrap_mode != TextServer.AUTOWRAP_OFF, "Card summary is not wrapped for %s/%s" % [String(tab_id), String(filter_id)])
		_check(state != null and state.clip_text, "Card state is not bounded for %s/%s" % [String(tab_id), String(filter_id)])


func _on_route_intent(intent: Dictionary) -> void:
	route_intents.append(intent.duplicate(true))


func _on_start_intent(intent: Dictionary) -> void:
	start_intents.append(intent.duplicate(true))


func _check_texture_size(parent: Node, path: String, expected: Vector2) -> void:
	var node := parent.get_node_or_null(path) as TextureRect
	if node == null or node.texture == null:
		failures.append("Texture is absent: " + path)
		return
	_check(node.texture.get_size() == expected, "Texture size mismatch for %s: %s" % [path, node.texture.get_size()])


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("ART22_DEPLOY_PREP_RUNTIME=PASS tabs=5 secondary_states=34 summary_pages=4 states=expanded,collapsed,active_run,cancel_modal character_frames=8 ambient_tracks=10")
		quit(0)
		return
	for failure in failures:
		push_error("ART22 runtime failure: " + failure)
	print("ART22_DEPLOY_PREP_RUNTIME=FAIL count=%d" % failures.size())
	quit(1)
