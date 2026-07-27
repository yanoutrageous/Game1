extends SceneTree

const TutorialPopupScene := preload("res://scenes/ui/tutorial/tutorial_popup_panel.tscn")
const TutorialServiceScript := preload("res://scripts/core/run/tutorial_service.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")
const RunSurfaceScript := preload("res://scripts/ui/run_surface/run_surface.gd")
const RunSurfaceModelScript := preload("res://scripts/ui/run_surface/run_surface_model.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")

const PASS_MARKER := "I3R_TUTORIAL_RESPONSIVE_LAYOUT=PASS"
const FAIL_MARKER := "I3R_TUTORIAL_RESPONSIVE_LAYOUT=FAIL"
const PHYSICAL_SIZES := [Vector2i(1280, 720), Vector2i(1920, 1080)]
const UI_SCALES := [1.0, 1.25, 1.5]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_factor = 1.0
	for physical_size in PHYSICAL_SIZES:
		root.size = physical_size
		await _frames(2)
		for ui_scale in UI_SCALES:
			await _check_case(physical_size, ui_scale)
	_finish()


func _check_case(physical_size: Vector2i, ui_scale: float) -> void:
	_check(is_equal_approx(root.content_scale_factor, 1.0), "canvas_scale_mutated")
	Art10UISkinKitScript.set_runtime_ui_scale_factor(ui_scale)
	var viewport_size := root.get_visible_rect().size
	var profile := UILayoutProfileScript.profile_for_size(viewport_size)
	profile["actual_viewport_size"] = Vector2i(int(round(viewport_size.x)), int(round(viewport_size.y)))
	profile["ui_scale_factor"] = ui_scale
	var viewport_rect := Rect2(Vector2.ZERO, viewport_size)

	var canvas := Control.new()
	canvas.name = "TutorialResponsiveCanvas_%dx%d_%d" % [
		physical_size.x,
		physical_size.y,
		int(round(ui_scale * 100.0)),
	]
	canvas.size = viewport_size
	root.add_child(canvas)

	var surface := RunSurfaceScript.new() as RunSurface
	canvas.add_child(surface)
	surface.build()
	surface.set_ui_scale_factor(ui_scale)
	surface.apply_layout_profile(profile)
	surface.apply_surface_model(_surface_model(profile))

	var popup := TutorialPopupScene.instantiate() as TutorialPopupPanel
	surface.get_overlay_slot().add_child(popup)
	popup.set_ui_scale_factor(ui_scale)
	popup.apply_layout_profile(profile)
	popup.apply_popup(_spawn_popup())
	await _frames(4)

	var snapshot := popup.layout_snapshot()
	var geometry := snapshot.get("geometry", {}) as Dictionary
	var panel_rect: Rect2 = snapshot.get("panel_rect", Rect2())
	var message_rect: Rect2 = snapshot.get("message_rect", Rect2())
	var button_rect: Rect2 = snapshot.get("button_rect", Rect2())
	var left_hud_rect: Rect2 = geometry.get("left_hud_rect", Rect2())
	var room_stage_rect: Rect2 = geometry.get("room_stage_rect", Rect2())
	var footer_rect: Rect2 = geometry.get("footer_rect", Rect2())
	var right_status_rect: Rect2 = geometry.get("right_status_rect", Rect2())
	var panel := popup.get_node_or_null("Panel") as Panel
	var title := popup.get_node_or_null("Panel/Content/Title") as Label
	var message := popup.get_node_or_null("Panel/Content/Message") as RichTextLabel
	var button := popup.get_node_or_null("Panel/Content/ConfirmButton") as Button

	_check(viewport_rect.encloses(panel_rect), _case_error(physical_size, ui_scale, "panel_outside_viewport:%s" % panel_rect))
	_check(not panel_rect.intersects(left_hud_rect), _case_error(physical_size, ui_scale, "panel_overlaps_left_hud"))
	_check(not panel_rect.intersects(room_stage_rect), _case_error(physical_size, ui_scale, "panel_overlaps_room_stage"))
	_check(not panel_rect.intersects(footer_rect), _case_error(physical_size, ui_scale, "panel_overlaps_footer"))
	_check(not panel_rect.intersects(right_status_rect), _case_error(physical_size, ui_scale, "panel_overlaps_protocol"))
	_check(room_stage_rect.size.x >= 320.0 and room_stage_rect.size.y >= 320.0, _case_error(physical_size, ui_scale, "room_stage_too_small:%s" % room_stage_rect))
	_check(panel_rect.encloses(message_rect), _case_error(physical_size, ui_scale, "message_escapes_panel:%s" % message_rect))
	_check(panel_rect.encloses(button_rect), _case_error(physical_size, ui_scale, "button_escapes_panel:%s" % button_rect))
	_check(message != null and message.scroll_active, _case_error(physical_size, ui_scale, "message_not_scrollable"))
	_check(message != null and message.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, _case_error(physical_size, ui_scale, "message_not_wrapped"))
	if message != null and message.get_content_height() > message.size.y + 0.5:
		_check(message.scroll_active, _case_error(physical_size, ui_scale, "overflow_without_scroll"))
	_check(title != null and title.get_line_count() == 1, _case_error(physical_size, ui_scale, "tutorial_title_wrapped"))
	_check(
		title != null and title.get_combined_minimum_size().x <= title.size.x + 0.5,
		_case_error(physical_size, ui_scale, "tutorial_title_clipped")
	)
	_check(panel != null and panel.get_theme_stylebox(&"panel") is StyleBoxTexture, _case_error(physical_size, ui_scale, "tutorial_frame_not_textured"))
	_check(button != null and button.text.find(" / ") < 0, _case_error(physical_size, ui_scale, "button_uses_full_binding_list"))
	_check(button != null and button.tooltip_text.find(" / ") >= 0, _case_error(physical_size, ui_scale, "full_binding_missing_from_tooltip"))
	_check(
		button != null and button.get_combined_minimum_size().x <= button.size.x + 0.5,
		_case_error(physical_size, ui_scale, "button_text_visually_truncated")
	)

	var risk_rect := surface.mine_risk_tag_art.get_global_rect()
	var info_rect := surface.command_feedback_art.get_global_rect()
	var key_rect := surface.bottom_overlay_art.get_global_rect()
	_check(surface.mine_risk_label.text == "周围雷险：3", _case_error(physical_size, ui_scale, "mine_risk_count_missing"))
	_check(not surface.command_feedback_art.visible, _case_error(physical_size, ui_scale, "steady_feedback_frame_visible"))
	_check(not surface.command_feedback_label.visible, _case_error(physical_size, ui_scale, "steady_feedback_copy_visible"))
	_check(not surface.action_hint_label.visible, _case_error(physical_size, ui_scale, "steady_action_hint_visible"))
	_check(not panel_rect.intersects(risk_rect), _case_error(physical_size, ui_scale, "tutorial_overlaps_mine_risk"))
	_check(not panel_rect.intersects(key_rect), _case_error(physical_size, ui_scale, "tutorial_overlaps_hotbar"))
	_check(info_rect.encloses(surface.command_feedback_label.get_global_rect()), _case_error(physical_size, ui_scale, "feedback_copy_escapes_frame"))
	_check(key_rect.encloses(surface.action_bar.get_global_rect()), _case_error(physical_size, ui_scale, "action_bar_escapes_frame"))
	_check(surface.scanner_title_label.visible and surface.scanner_title_label.text == "区域扫描图", _case_error(physical_size, ui_scale, "scanner_title_missing"))
	_check(
		surface.scanner_title_label.get_combined_minimum_size().y <= surface.scanner_title_label.size.y + 0.5,
		_case_error(
			physical_size,
			ui_scale,
			"scanner_title_clipped:min=%s rect=%s"
			% [surface.scanner_title_label.get_combined_minimum_size(), surface.scanner_title_label.get_global_rect()]
		)
	)
	_check(surface.right_title_label.visible and surface.right_title_label.text == "协议 5", _case_error(physical_size, ui_scale, "protocol_title_missing"))
	_check(
		surface.right_title_label.get_combined_minimum_size().y <= surface.right_title_label.size.y + 0.5,
		_case_error(
			physical_size,
			ui_scale,
			"protocol_title_clipped:min=%s rect=%s"
			% [surface.right_title_label.get_combined_minimum_size(), surface.right_title_label.get_global_rect()]
		)
	)
	var status_art_rect := surface.status_card_art.get_global_rect()
	var protocol_title_rect := surface.right_title_label.get_global_rect()
	var protocol_body_rect := surface.right_body_label.get_global_rect()
	_check(
		protocol_title_rect.end.y + 1.0 <= protocol_body_rect.position.y,
		_case_error(physical_size, ui_scale, "protocol_title_overlaps_body")
	)
	var protocol_left_safe := maxf(
		float(surface.status_card_art.get_patch_margin(SIDE_LEFT)),
		status_art_rect.size.x * 0.18
	)
	var protocol_top_safe := float(surface.status_card_art.get_patch_margin(SIDE_TOP))
	_check(
		protocol_title_rect.position.x >= status_art_rect.position.x + protocol_left_safe - 0.5
		and protocol_title_rect.position.y >= status_art_rect.position.y + protocol_top_safe - 0.5,
		_case_error(
			physical_size,
			ui_scale,
			"protocol_title_enters_art_border:frame=%s title=%s"
			% [status_art_rect, protocol_title_rect]
		)
	)
	for action_button_variant in surface.action_buttons.values():
		var action_button := action_button_variant as Button
		_check(
			action_button != null and surface.action_bar.get_global_rect().encloses(action_button.get_global_rect()),
			_case_error(physical_size, ui_scale, "action_button_escapes_hotbar")
		)
	popup.apply_popup(_tutorial_popup(&"exit_goal"))
	await _frames(2)
	var exit_snapshot := popup.layout_snapshot()
	var exit_panel_rect: Rect2 = exit_snapshot.get("panel_rect", Rect2())
	var exit_message_rect: Rect2 = exit_snapshot.get("message_rect", Rect2())
	var exit_button_rect: Rect2 = exit_snapshot.get("button_rect", Rect2())
	var exit_button := popup.get_node_or_null("Panel/Content/ConfirmButton") as Button
	_check(viewport_rect.encloses(exit_panel_rect), _case_error(physical_size, ui_scale, "exit_panel_outside_viewport"))
	_check(not exit_panel_rect.intersects(left_hud_rect), _case_error(physical_size, ui_scale, "exit_panel_overlaps_left_hud"))
	_check(not exit_panel_rect.intersects(footer_rect), _case_error(physical_size, ui_scale, "exit_panel_overlaps_footer"))
	_check(exit_panel_rect.encloses(exit_message_rect), _case_error(physical_size, ui_scale, "exit_message_escapes_panel"))
	_check(exit_panel_rect.encloses(exit_button_rect), _case_error(physical_size, ui_scale, "exit_button_escapes_panel"))
	_check(exit_button != null and exit_button.text.find(" / ") < 0, _case_error(physical_size, ui_scale, "exit_button_uses_full_binding_list"))
	_check(
		exit_button != null and exit_button.get_combined_minimum_size().x <= exit_button.size.x + 0.5,
		_case_error(physical_size, ui_scale, "exit_button_text_visually_truncated")
	)
	popup.apply_popup(_tutorial_popup(&"number_rule"))
	await _frames(2)
	var info_snapshot := popup.layout_snapshot()
	var info_button := popup.get_node_or_null("Panel/Content/ConfirmButton") as Button
	_check(
		info_button != null and info_button.visible and info_button.text == "点击关闭",
		_case_error(physical_size, ui_scale, "nonblocking_close_affordance_missing")
	)
	_check(
		info_button != null and info_button.focus_mode == Control.FOCUS_NONE,
		_case_error(physical_size, ui_scale, "nonblocking_close_stole_keyboard_focus")
	)
	_check(
		(info_snapshot.get("panel_rect", Rect2()) as Rect2).encloses(
			info_snapshot.get("button_rect", Rect2()) as Rect2
		),
		_case_error(physical_size, ui_scale, "nonblocking_close_escapes_panel")
	)

	print(
		"I3R_TUTORIAL_RESPONSIVE_CASE physical=%dx%d logical=%dx%d ui=%d panel=%s room=%s footer=%s message_content=%s"
		% [
			physical_size.x,
			physical_size.y,
			int(round(viewport_size.x)),
			int(round(viewport_size.y)),
			int(round(ui_scale * 100.0)),
			panel_rect,
			room_stage_rect,
			footer_rect,
			snapshot.get("message_content_height", 0.0),
		]
	)
	canvas.queue_free()
	await _frames(3)


func _spawn_popup() -> Dictionary:
	return _tutorial_popup(&"spawn_intro")


func _tutorial_popup(popup_id: StringName) -> Dictionary:
	var context := RunContextScript.new()
	context.mode = &"tutorial"
	context.tutorial_triggers = {"0,0": popup_id}
	TutorialServiceScript.trigger_for(context, Vector2i.ZERO)
	return context.tutorial_popup.duplicate(true)


func _surface_model(profile: Dictionary) -> Dictionary:
	var model := RunSurfaceModelScript.build({
		"position": Vector2i(0, 0),
		"current_room": &"Normal",
		"protocol_level": 5,
		"pressure": 0,
		"adjacent_mines": 3,
		"inventory_items": [],
		"backpack_used": 0,
		"backpack_capacity": 10,
		"hp": 100,
		"max_hp": 100,
		"power": 5,
		"black_coin": 0,
		"gold_coin": 0,
		"run_active": true,
		"search_state_data": {"can_search": false, "searched": false},
		"run_map_snapshot": {"KnownMap": {"width": 5, "height": 5, "public_cells": []}},
	}, null, profile, {})
	model["command_feedback"] = "已进入普通房间。"
	model["action_hint"] = "靠近可交互目标后再行动。"
	return model


func _case_error(physical_size: Vector2i, ui_scale: float, detail: String) -> String:
	return "%dx%d@%d:%s" % [
		physical_size.x,
		physical_size.y,
		int(round(ui_scale * 100.0)),
		detail,
	]


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	Art10UISkinKitScript.set_runtime_ui_scale_factor(1.0)
	if failures.is_empty():
		print(
			"%s cases=1280x720@100,125,150;1920x1080@100,125,150 route=deploy_standard safe_zones=left_hud,room,protocol,footer text=wrapped_scroll footer=mine_risk,hotbar_compact feedback=transient"
			% PASS_MARKER
		)
		quit(0)
		return
	for failure in failures:
		push_error("I3R tutorial responsive layout failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
