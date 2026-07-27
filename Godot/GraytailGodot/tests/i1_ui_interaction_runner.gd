extends SceneTree

const PASS_MARKER := "I1_UI_INTERACTION=PASS"
const FAIL_MARKER := "I1_UI_INTERACTION=FAIL"
const RESOLUTIONS: Array[StringName] = [
	&"1280x720",
	&"1600x900",
	&"1920x1080",
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert_shared_button_factories()
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production main scene could not be loaded")
	if packed == null:
		_finish()
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var run_scene := main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing")
	if run_scene == null:
		main.queue_free()
		await process_frame
		_finish()
		return
	var bus: Variant = run_scene.get("command_bus")
	_require(bus != null, "production CommandBus was not initialized")
	if bus != null:
		var start_result: Dictionary = bus.dispatch(&"start_demo_run")
		_require(bool(start_result.get("ok", false)), "demo run could not be started")
	run_scene.call("_show_run_screen")
	await process_frame
	await process_frame

	for resolution_id in RESOLUTIONS:
		await _assert_production_resolution(run_scene, resolution_id)

	main.queue_free()
	await process_frame
	await process_frame
	_finish()


func _assert_shared_button_factories() -> void:
	var art10_ui_skin_kit_script := load("res://scripts/presentation/art10_ui_skin_kit.gd")
	_require(art10_ui_skin_kit_script != null, "shared UI skin kit could not be loaded")
	if art10_ui_skin_kit_script == null:
		return
	var buttons: Array[Button] = [
		art10_ui_skin_kit_script.make_large_nav_button("I1"),
		art10_ui_skin_kit_script.make_small_button("I1"),
		art10_ui_skin_kit_script.make_tab_button("I1"),
		art10_ui_skin_kit_script.make_bottom_key_button("I1", "E"),
	]
	for button in buttons:
		_require(button.focus_mode == Control.FOCUS_ALL, "shared button factory produced an unreachable control")
		_require(button.get_theme_font_size("font_size") >= 13, "shared button factory produced sub-13px text")
		button.free()


func _assert_production_resolution(run_scene: Node, resolution_id: StringName) -> void:
	var ui_layout_profile_script := load("res://scripts/ui/shell/ui_layout_profile.gd")
	var profile: Dictionary = ui_layout_profile_script.profile_for_resolution(resolution_id)
	var viewport_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
	profile["actual_viewport_size"] = viewport_size
	root.size = viewport_size
	await process_frame
	run_scene.call("_refresh_view_models")
	await process_frame
	await process_frame

	var run_surface: Control = run_scene.get("run_surface") as Control
	var inventory_panel: Control = run_scene.get("inventory_panel") as Control
	var room_runtime_view: Variant = run_scene.get("room_runtime_view")
	var ground_loot_popup: Control = room_runtime_view.get("context_popup") as Control if room_runtime_view != null else null
	var map_overlay_panel: Control = run_scene.get("map_overlay_panel") as Control
	var result_panel: Control = run_scene.get("result_panel") as Control
	_require(run_surface != null, "%s production RunSurface is missing" % resolution_id)
	_require(inventory_panel != null, "%s production InventoryPanel is missing" % resolution_id)
	_require(ground_loot_popup != null, "%s production ground-loot context popup is missing" % resolution_id)
	_require(map_overlay_panel != null, "%s production MapOverlayPanel is missing" % resolution_id)
	_require(result_panel != null, "%s production ResultPanel is missing" % resolution_id)
	if run_surface == null or inventory_panel == null or ground_loot_popup == null or map_overlay_panel == null or result_panel == null:
		return

	await _assert_run_surface(run_surface, profile, viewport_size, resolution_id)
	await _assert_inventory(inventory_panel, profile, viewport_size, resolution_id)
	await _assert_ground_loot(ground_loot_popup, viewport_size, resolution_id)
	await _assert_map_overlay(map_overlay_panel, profile, viewport_size, resolution_id)
	await _assert_result(result_panel, profile, viewport_size, resolution_id)


func _assert_run_surface(run_surface: Control, profile: Dictionary, viewport_size: Vector2i, resolution_id: StringName) -> void:
	run_surface.call("apply_layout_profile", profile)
	var action_fixture: Array[Dictionary] = [
		{"id": &"interact", "label": "E 搜索/交互", "enabled": false, "description": "当前没有可搜索或交互的目标。", "disabled_reason": "当前没有可搜索或交互的目标。", "tone": &"primary"},
		{"id": &"inventory", "label": "背包", "enabled": true, "description": "查看背包、装备与负重详情。", "disabled_reason": "", "tone": &"secondary", "is_primary": true},
		{"id": &"ground_loot", "label": "地面物品", "enabled": false, "description": "当前房间没有可拾取物。", "disabled_reason": "当前房间没有可拾取物。", "tone": &"warning"},
		{"id": &"map", "label": "M/Tab 扫描图", "enabled": true, "description": "打开完整区域扫描图。", "disabled_reason": "", "tone": &"secondary"},
		{"id": &"combat", "label": "Space/J 清理", "enabled": false, "description": "当前房间没有需要清理的威胁。", "disabled_reason": "当前房间没有需要清理的威胁。", "tone": &"danger"},
		{"id": &"extract", "label": "撤离", "enabled": false, "description": "需到达撤离信标；战斗中可在有效门边确认撤离。", "disabled_reason": "需到达撤离信标；战斗中可在有效门边确认撤离。", "tone": &"danger"},
		{"id": &"pause", "label": "Esc 暂停", "enabled": true, "description": "打开暂停菜单和设置入口。", "disabled_reason": "", "tone": &"secondary"},
	]
	run_surface.call("apply_surface_model", {
		"command_feedback": "路线已更新，返回撤离信标即可结算。",
		"action_hint": "撤离暂不可用：尚未到达撤离点",
		"action_buttons": action_fixture,
		"encounter_section": {
			"encounter_type": &"rule_modifier",
			"title": "规则终端",
			"body": "选择本次规则处理方式。",
			"result_summary": "等待选择",
			"options": [
				{"id": &"sell_best_item", "title": "出售物资", "summary": "所得计入安全收益。", "disabled": false, "requires_confirm": false, "command_payload": {"option_id": &"sell_best_item"}},
				{"id": &"confirm_high_value_sale", "title": "确认出售", "summary": "确认出售高价值物资。", "disabled": true, "disabled_reason": "当前没有高价值物资。", "requires_confirm": true, "command_payload": {"option_id": &"confirm_high_value_sale"}},
				{"id": &"buy_treatment", "title": "购买治疗", "summary": "恢复本次探索生命。", "disabled": true, "disabled_reason": "黑币不足。", "requires_confirm": false, "command_payload": {"option_id": &"buy_treatment"}},
				{"id": &"buy_info", "title": "购买路线情报", "summary": "揭示一条可用路线。", "disabled": true, "disabled_reason": "黑币不足。", "requires_confirm": false, "command_payload": {"option_id": &"buy_info"}},
				{"id": &"leave", "title": "离开旅商", "summary": "保留资源继续探索。", "disabled": false, "requires_confirm": false, "command_payload": {"option_id": &"leave"}},
			],
		},
		"layout_profile": profile,
	})
	await process_frame
	var feedback := run_surface.get("command_feedback_label") as Label
	var hint := run_surface.get("action_hint_label") as Label
	var feedback_panel := run_surface.get("command_feedback_art") as Control
	var encounter_panel := run_surface.get("encounter_backdrop") as Control
	var action_buttons: Dictionary = run_surface.get("action_buttons")
	var encounter_grid := run_surface.get("encounter_options_box") as GridContainer
	var encounter_buttons: Array = run_surface.get("encounter_option_buttons")
	_require(feedback != null and not feedback.visible, "%s model refresh recreated permanent command feedback" % resolution_id)
	_require(hint != null and not hint.visible and hint.text.contains("查看背包、装备与负重详情"), "%s hidden guidance state did not retain the first executable action" % resolution_id)
	if feedback != null:
		_assert_font(feedback, "%s RunCommandFeedback" % resolution_id)
	if hint != null:
		_assert_font(hint, "%s RunActionHint" % resolution_id)
	_require(encounter_buttons.size() == 5, "%s compatible five-option non-event layout is incomplete" % resolution_id)
	_require(encounter_grid != null and encounter_grid.columns == 3, "%s five-option non-event encounter does not wrap through a three-column grid" % resolution_id)
	for raw_encounter_button in encounter_buttons:
		var encounter_button := raw_encounter_button as Button
		if encounter_button == null:
			continue
		_assert_inside_viewport(encounter_button, viewport_size, "%s encounter option" % resolution_id)
		_assert_font(encounter_button, "%s encounter option" % resolution_id)
		_require(encounter_button.focus_mode == Control.FOCUS_ALL, "%s encounter option is not focusable" % resolution_id)
		if feedback != null and feedback.visible:
			_require(not encounter_button.get_global_rect().intersects(feedback.get_global_rect()), "%s encounter option overlaps command feedback" % resolution_id)
		if hint != null and hint.visible:
			_require(not encounter_button.get_global_rect().intersects(hint.get_global_rect()), "%s encounter option overlaps action hint" % resolution_id)
		if encounter_panel != null:
			_require(
				encounter_panel.get_global_rect().encloses(encounter_button.get_global_rect()),
				"%s encounter option escapes its encounter panel: panel=%s button=%s"
				% [resolution_id, encounter_panel.get_global_rect(), encounter_button.get_global_rect()]
			)
	_assert_left_status_spacing(run_surface, resolution_id)
	var default_hint := hint.text if hint != null else ""
	for action_data in action_fixture:
		var action_id := StringName(action_data.get("id", &""))
		var guided_button := action_buttons.get(action_id) as Button
		_require(guided_button != null, "%s run action %s is missing from the complete production set" % [resolution_id, action_id])
		if guided_button == null or hint == null:
			continue
		var expected_detail := String(action_data.get("description", "")) if bool(action_data.get("enabled", true)) else String(action_data.get("disabled_reason", ""))
		_require(not guided_button.tooltip_text.is_empty() and guided_button.tooltip_text.contains(expected_detail), "%s run action %s has no complete tooltip guidance" % [resolution_id, action_id])
		guided_button.mouse_entered.emit()
		await process_frame
		_require(not hint.visible and hint.text.contains(expected_detail), "%s hidden hover guidance state does not describe run action %s: %s" % [resolution_id, action_id, hint.text])
		guided_button.mouse_exited.emit()
		await process_frame
		_require(hint.text == default_hint, "%s leaving run action %s did not restore default guidance" % [resolution_id, action_id])
		if not guided_button.disabled:
			guided_button.grab_focus()
			await process_frame
			_require(root.gui_get_focus_owner() == guided_button and not hint.visible and hint.text.contains(expected_detail), "%s keyboard focus does not preserve hidden guidance for run action %s" % [resolution_id, action_id])
			guided_button.release_focus()
			await process_frame
			_require(hint.text == default_hint, "%s leaving keyboard focus on %s did not restore default guidance" % [resolution_id, action_id])
	for action_id in action_buttons.keys():
		var button := action_buttons[action_id] as Button
		if button == null:
			continue
		var expected_focus := Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
		_require(button.focus_mode == expected_focus, "%s run action %s has incorrect context focus mode" % [resolution_id, action_id])
		_assert_font(button, "%s run action %s" % [resolution_id, action_id])
		_assert_inside_viewport(button, viewport_size, "%s run action %s" % [resolution_id, action_id])
	run_surface.call("show_command_feedback", {"ok": true, "accepted": true})
	_require(feedback != null and not feedback.visible and not feedback.text.contains("已确认"), "%s generic accepted acknowledgement leaked into player guidance" % resolution_id)
	run_surface.call("show_command_feedback", {"ok": true, "accepted": true, "message": "已拾取应急药剂。"})
	_require(feedback != null and not feedback.visible, "%s successful action duplicated its authoritative presentation in global feedback" % resolution_id)
	run_surface.call("show_command_feedback", {"ok": false, "accepted": false, "message": "请靠近物资后再拾取。"})
	_require(feedback != null and feedback.visible and feedback.text.contains("靠近物资"), "%s rejected action lacks player-facing feedback" % resolution_id)
	if feedback != null and feedback_panel != null:
		_require(not feedback_panel.visible, "%s rejected action recreated the retired full-width feedback frame" % resolution_id)
		_assert_inside_viewport(feedback, viewport_size, "%s unframed RunCommandFeedback" % resolution_id)
		_assert_single_line_fits(feedback, "%s rejected RunCommandFeedback" % resolution_id)
	run_surface.call("advance_command_feedback", 3.0)
	_require(feedback != null and not feedback.visible, "%s transient command feedback did not expire" % resolution_id)


func _assert_left_status_spacing(run_surface: Control, resolution_id: StringName) -> void:
	var legend := run_surface.get("scanner_legend_label") as Label
	var legacy_status := run_surface.get("resource_label") as Label
	var bag_title := run_surface.get("scanner_detail_label") as Label
	var status_backdrop := run_surface.get("resource_backdrop") as Control
	var bag_backdrop := run_surface.get("scanner_text_mask") as Control
	_require(legend != null and legacy_status != null and bag_title != null, "%s left status labels are missing" % resolution_id)
	if legend == null or legacy_status == null or bag_title == null:
		return
	_require(not legend.get_global_rect().intersects(bag_title.get_global_rect()), "%s left status overlaps bag title" % resolution_id)
	_require(legend.visible and not legend.text.strip_edges().is_empty(), "%s left status is not readable" % resolution_id)
	_require(not legacy_status.visible, "%s retired duplicate resource label is visible" % resolution_id)
	if status_backdrop != null:
		_require(status_backdrop.get_global_rect().encloses(legend.get_global_rect()), "%s left status escapes status panel" % resolution_id)
	if bag_backdrop != null:
		_require(bag_backdrop.get_global_rect().encloses(bag_title.get_global_rect()), "%s bag title escapes bag panel" % resolution_id)


func _assert_inventory(panel: Control, profile: Dictionary, viewport_size: Vector2i, resolution_id: StringName) -> void:
	panel.call("apply_layout_profile", profile)
	panel.call("apply_snapshot", {
		"inventory_items": [_sample_item("i1-inventory", true)],
		"equipped_items": [_sample_item("i1-equipped", false)],
		"backpack_used": 2,
		"backpack_capacity": 8,
		"run_black_coin": 12,
		"gold_coin": 3,
	})
	panel.call("show_panel")
	await process_frame
	_assert_inside_viewport(panel, viewport_size, "%s InventoryPanel" % resolution_id)
	_assert_focusable_buttons(panel, "%s InventoryPanel" % resolution_id)
	_assert_visible_fonts(panel, "%s InventoryPanel" % resolution_id)
	panel.call("hide_panel")



func _assert_ground_loot(panel: Control, viewport_size: Vector2i, resolution_id: StringName) -> void:
	var popup_parent := panel.get_parent() as Control
	var popup_bounds := Vector2(viewport_size)
	if popup_parent != null and popup_parent.size.x > 1.0 and popup_parent.size.y > 1.0:
		popup_bounds = popup_parent.size
	panel.call("apply_context", {
		"interaction_kind": &"ground_loot",
		"world_pos": popup_bounds * 0.5,
		"room_bounds": Rect2(Vector2.ZERO, popup_bounds),
		"items": [_sample_item("i1-ground", false)],
		"inventory_items": [],
		"backpack_remaining": 6,
	})
	await process_frame
	await process_frame
	_assert_inside_viewport(panel, viewport_size, "%s ground-loot context popup" % resolution_id)
	_assert_focusable_buttons(panel, "%s ground-loot context popup" % resolution_id)
	_assert_visible_fonts(panel, "%s ground-loot context popup" % resolution_id)
	panel.call("clear_context")


func _assert_map_overlay(panel: Control, profile: Dictionary, viewport_size: Vector2i, resolution_id: StringName) -> void:
	panel.call("apply_layout_profile", profile)
	panel.call("apply_view_model", _map_model())
	panel.call("show_overlay")
	await process_frame
	await process_frame
	var map_frame := panel.get_node_or_null("Panel") as Control
	_assert_inside_viewport(map_frame, viewport_size, "%s MapOverlayPanel" % resolution_id)
	_assert_focusable_buttons(panel, "%s MapOverlayPanel" % resolution_id)
	_assert_visible_fonts(panel, "%s MapOverlayPanel" % resolution_id)
	panel.call("hide_overlay")


func _assert_result(panel: Control, profile: Dictionary, viewport_size: Vector2i, resolution_id: StringName) -> void:
	panel.call("apply_layout_profile", profile)
	panel.call("show_summary", _success_result())
	await process_frame
	await process_frame
	_assert_inside_viewport(panel, viewport_size, "%s ResultPanel" % resolution_id)
	_assert_focusable_buttons(panel, "%s ResultPanel" % resolution_id)
	_assert_visible_fonts(panel, "%s ResultPanel" % resolution_id)
	panel.call("hide_result")


func _assert_focusable_buttons(node: Node, scope: String) -> void:
	var buttons := node.find_children("*", "Button", true, false)
	_require(not buttons.is_empty(), "%s has no production buttons" % scope)
	for raw_button in buttons:
		var button := raw_button as Button
		if button == null or not button.is_visible_in_tree():
			continue
		_require(button.focus_mode == Control.FOCUS_ALL, "%s/%s is not focusable" % [scope, button.name])
		_assert_font(button, "%s/%s" % [scope, button.name])


func _assert_visible_fonts(node: Node, scope: String) -> void:
	for raw_control in node.find_children("*", "Control", true, false):
		var control := raw_control as Control
		if control == null or not control.is_visible_in_tree():
			continue
		if control is Label or control is Button:
			_assert_font(control, "%s/%s" % [scope, control.name])


func _assert_font(control: Control, scope: String) -> void:
	_require(control.get_theme_font_size("font_size") >= 13, "%s uses a font below 13px" % scope)


func _assert_single_line_fits(label: Label, scope: String) -> void:
	if label == null:
		return
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var measured_width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_require(measured_width <= label.size.x + 0.5, "%s text is clipped: measured=%.1f available=%.1f text=%s" % [scope, measured_width, label.size.x, label.text])


func _assert_inside_viewport(control: Control, viewport_size: Vector2i, scope: String) -> void:
	_require(control != null, "%s is missing" % scope)
	if control == null:
		return
	var rect := control.get_global_rect()
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
	_require(rect.size.x > 0.5 and rect.size.y > 0.5, "%s has no visible layout area" % scope)
	_require(viewport_rect.encloses(rect), "%s escapes viewport: %s outside %s" % [scope, rect, viewport_rect])


func _sample_item(instance_id: String, consumable: bool) -> Dictionary:
	return {
		"instance_id": instance_id,
		"item_id": "i1_ui_probe_item",
		"display_name": "交互验证物品",
		"short_description": "用于验证生产交互控件。",
		"item_type": &"consumable" if consumable else &"collectible",
		"rarity": &"tier_2",
		"weight": 1,
		"base_value": 10,
		"can_consume": consumable,
	}


func _map_model():
	var mini_map_view_model_script := load("res://scripts/ui/minimap/minimap_view_model.gd")
	var model: Variant = mini_map_view_model_script.new()
	model.width = 3
	model.height = 3
	for y in range(3):
		for x in range(3):
			model.room_markers.append({
				"pos": Vector2i(x, y),
				"label": "P" if x == 1 and y == 1 else "?",
				"room_type": &"Normal",
				"is_current": x == 1 and y == 1,
				"revealed": x == 1 and y == 1,
			})
	return model


func _success_result() -> Dictionary:
	return {
		"outcome": "Extracted",
		"settlement": {
			"outcome": "success",
			"black_coin_converted": 12,
			"gold_coin_gained": 12,
			"warehouse_items": [],
			"salvaged_items": [],
			"lost_item_count": 0,
			"finalized": true,
		},
		"meta_progress_commit": {"status": &"committed"},
	}


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print(PASS_MARKER)
		print("I1_UI_INTERACTION_DETAILS production=main resolutions=1280x720,1600x900,1920x1080 focus=PASS fonts=PASS feedback=transient disabled_reason=PASS")
		quit(0)
		return
	for failure in failures:
		print("I1_UI_INTERACTION_FAILURE %s" % failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
