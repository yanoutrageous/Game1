extends SceneTree

const RunSurfaceScript := preload("res://scripts/ui/run_surface/run_surface.gd")
const RunSurfaceModelScript := preload("res://scripts/ui/run_surface/run_surface_model.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const RuntimeLayoutScript := preload("res://scripts/gameplay/runtime/g41_runtime_layout.gd")
const WorldContextPopupScript := preload("res://scripts/gameplay/interaction/g41_world_context_popup.gd")

const PASS_MARKER := "I3R_RUN_FOCUS_LAYOUT=PASS"
const FAIL_MARKER := "I3R_RUN_FOCUS_LAYOUT=FAIL"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for resolution_id in [&"1280x720", &"1366x768", &"1600x900", &"1920x1080"]:
		await _check_footer_and_mine_risk(resolution_id)
	await _check_transient_feedback_contract()
	await _check_redundant_basic_encounter_actions_hidden()
	await _check_world_popup_focus_clearance()
	_finish()


func _check_footer_and_mine_risk(resolution_id: StringName) -> void:
	var profile := UILayoutProfileScript.profile_for_resolution(resolution_id)
	var supported_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
	var canvas := Control.new()
	canvas.name = "RunFocusLayoutCanvas_%s" % resolution_id
	canvas.size = Vector2(supported_size)
	root.add_child(canvas)
	var surface := RunSurfaceScript.new() as RunSurface
	canvas.add_child(surface)
	surface.build()
	surface.apply_layout_profile(profile)
	surface.apply_surface_model(_surface_model(profile, 3, [_long_detail_item()]))
	await _frames(2)

	var footer := UILayerContractScript.run_footer_geometry(profile)
	var risk_rect := surface.mine_risk_tag_art.get_rect()
	var risk_label_rect := surface.mine_risk_label.get_rect()
	var key_rect := surface.bottom_overlay_art.get_rect()
	var detail_rect := surface.backpack_detail_label.get_global_rect()
	var capacity_rect := surface.backpack_capacity_label.get_global_rect()
	var detail_capacity_gap := capacity_rect.position.y - detail_rect.end.y
	var rail_rect := surface.left_rail_art.get_rect()
	var scanner_title_rect := surface.scanner_title_label.get_rect()
	var resource_style := surface.resource_backdrop.get_theme_stylebox(&"panel")
	var backpack_style := surface.scanner_text_mask.get_theme_stylebox(&"panel")
	_check(surface.mine_risk_tag_art.visible, "%s known mine-risk plate is hidden" % resolution_id)
	_check(surface.mine_risk_label.visible, "%s known mine-risk text is hidden" % resolution_id)
	_check(surface.mine_risk_label.text == "周围雷险：3", "%s mine-risk copy/count drifted" % resolution_id)
	_check(surface.mine_risk_tag_art.texture != null, "%s mine-risk art is unbound" % resolution_id)
	_check(not surface.resource_label.visible, "%s duplicated the mine-risk signal in the left rail" % resolution_id)
	_check(absf(risk_rect.position.y - float(footer.get("mine_risk_top", -1.0))) <= 0.1, "%s risk plate escaped footer contract" % resolution_id)
	_check(not surface.command_feedback_art.visible, "%s steady state retained a permanent command-feedback frame" % resolution_id)
	_check(not surface.command_feedback_label.visible, "%s steady state retained permanent command-feedback copy" % resolution_id)
	_check(not surface.action_hint_label.visible, "%s steady state retained permanent action-guidance copy" % resolution_id)
	_check(resource_style is StyleBoxFlat, "%s resource section retained a second textured frame" % resolution_id)
	_check(backpack_style is StyleBoxFlat, "%s backpack section retained a second textured frame" % resolution_id)
	if resource_style is StyleBoxFlat:
		var flat_resource := resource_style as StyleBoxFlat
		_check(
			flat_resource.border_width_left + flat_resource.border_width_top
			+ flat_resource.border_width_right + flat_resource.border_width_bottom == 0,
			"%s resource section retained a complete inner outline" % resolution_id
		)
	if backpack_style is StyleBoxFlat:
		var flat_backpack := backpack_style as StyleBoxFlat
		_check(
			flat_backpack.border_width_left + flat_backpack.border_width_top
			+ flat_backpack.border_width_right + flat_backpack.border_width_bottom == 0,
			"%s backpack section retained a complete inner outline" % resolution_id
		)
	_check(
		scanner_title_rect.position.x >= rail_rect.position.x + 20.0
		and scanner_title_rect.position.y >= rail_rect.position.y + 24.0
		and scanner_title_rect.end.x <= rail_rect.end.x - 12.0,
		"%s scanner title enters the authored rail ornament safe zone: title=%s rail=%s" % [
			resolution_id,
			scanner_title_rect,
			rail_rect,
		]
	)
	_check(
		surface.scanner_title_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER,
		"%s scanner title is not centered inside the rail header" % resolution_id
	)
	_check(
		risk_rect.end.y <= key_rect.position.y
		and key_rect.position.y - risk_rect.end.y <= 6.0,
		"%s mine-risk plate is not directly adjacent to the key dock: gap=%.1f" % [
			resolution_id,
			key_rect.position.y - risk_rect.end.y,
		]
	)
	_check(risk_rect.encloses(risk_label_rect), "%s mine-risk text escapes its authored plate" % resolution_id)
	_check(
		surface.backpack_detail_label.text.length() >= 60,
		"%s long quick-bag item did not reach the detail presentation" % resolution_id
	)
	_check(not detail_rect.intersects(capacity_rect), "%s long quick-bag detail overlaps the burden label" % resolution_id)
	_check(
		detail_capacity_gap >= 8.0,
		"%s long quick-bag detail lacks safe spacing above burden: gap=%.1f" % [
			resolution_id,
			detail_capacity_gap,
		]
	)

	var stable_reserved_rect := risk_rect
	surface.apply_surface_model(_surface_model(profile, -1))
	await _frames(1)
	_check(not surface.mine_risk_tag_art.visible and not surface.mine_risk_label.visible, "%s unknown mine-risk state leaked a number" % resolution_id)
	_check(surface.mine_risk_tag_art.get_rect().is_equal_approx(stable_reserved_rect), "%s unknown state collapsed the reserved risk slot" % resolution_id)
	for adjacent in [0, 1, 8]:
		surface.apply_surface_model(_surface_model(profile, adjacent))
		await _frames(1)
		_check(surface.mine_risk_label.text == "周围雷险：%d" % adjacent, "%s omitted adjacent count %d" % [resolution_id, adjacent])

	canvas.queue_free()
	await _frames(2)


func _check_transient_feedback_contract() -> void:
	var profile := UILayoutProfileScript.profile_for_resolution(&"1280x720")
	var canvas := Control.new()
	canvas.name = "RunTransientFeedbackCanvas"
	canvas.size = Vector2(profile.get("supported_size", Vector2i(1280, 720)))
	root.add_child(canvas)
	var surface := RunSurfaceScript.new() as RunSurface
	canvas.add_child(surface)
	surface.build()
	surface.apply_layout_profile(profile)
	surface.apply_surface_model(_surface_model(profile, 3))
	await _frames(2)

	var has_show_method := surface.has_method("show_command_feedback")
	var has_advance_method := surface.has_method("advance_command_feedback")
	_check(has_show_method, "run surface lacks the command-feedback presentation entrypoint")
	_check(has_advance_method, "run surface lacks deterministic transient-feedback advancement")
	if has_show_method and has_advance_method:
		var risk_before := surface.mine_risk_tag_art.get_rect()
		var key_before := surface.bottom_overlay_art.get_rect()
		surface.call("show_command_feedback", {
			"ok": true,
			"accepted": true,
			"message": "Transient pickup feedback.",
		})
		await _frames(1)
		_check(not surface.command_feedback_art.visible, "successful action recreated the retired feedback frame")
		_check(not surface.command_feedback_label.visible, "successful action duplicated its authoritative presentation in global feedback")
		surface.call("show_command_feedback", {
			"ok": false,
			"accepted": false,
			"message": "Move closer before interacting.",
		})
		await _frames(1)
		var feedback_text := surface.command_feedback_label.text
		var toast_rect := surface.command_feedback_label.get_global_rect()
		var viewport_rect := Rect2(Vector2.ZERO, canvas.size)
		_check(surface.command_feedback_label.visible, "rejection feedback did not become visible")
		_check(not surface.command_feedback_art.visible, "rejection feedback recreated a full-width framed bar")
		_check(not feedback_text.is_empty(), "rejection feedback became visible without player-facing copy")
		_check(viewport_rect.encloses(toast_rect), "unframed rejection feedback escaped the viewport")
		_check(not toast_rect.intersects(surface.left_rail_art.get_global_rect()), "unframed rejection feedback overlaps the left rail")
		_check(not toast_rect.intersects(surface.status_card_art.get_global_rect()), "unframed rejection feedback overlaps the protocol card")
		_check(not toast_rect.intersects(surface.mine_risk_tag_art.get_global_rect()), "unframed rejection feedback overlaps the mine-risk plate")
		_check(not toast_rect.intersects(surface.bottom_overlay_art.get_global_rect()), "unframed rejection feedback overlaps the key dock")
		surface.call("advance_command_feedback", 0.25)
		await _frames(1)
		_check(surface.command_feedback_label.visible, "rejection feedback expired before its minimum readable interval")
		_check(surface.command_feedback_label.text == feedback_text, "rejection feedback copy changed during its readable interval")
		surface.call("advance_command_feedback", 3.0)
		await _frames(1)
		_check(not surface.command_feedback_label.visible, "rejection feedback did not expire within the short toast window")
		_check(not surface.command_feedback_art.visible, "expired rejection feedback left a permanent frame")
		_check(surface.mine_risk_tag_art.get_rect().is_equal_approx(risk_before), "rejection feedback moved the mine-risk plate")
		_check(surface.bottom_overlay_art.get_rect().is_equal_approx(key_before), "rejection feedback moved the key dock")

	canvas.queue_free()
	await _frames(2)


func _check_redundant_basic_encounter_actions_hidden() -> void:
	var profile := UILayoutProfileScript.profile_for_resolution(&"1280x720")
	var canvas := Control.new()
	canvas.name = "RunBasicEncounterDedupCanvas"
	canvas.size = Vector2(profile.get("supported_size", Vector2i(1280, 720)))
	root.add_child(canvas)
	var surface := RunSurfaceScript.new() as RunSurface
	canvas.add_child(surface)
	surface.build()
	surface.apply_layout_profile(profile)
	var model := _surface_model(profile, 0)
	model["encounter_section"] = {
		"encounter_type": &"search_basic",
		"title": "基础行动",
		"body": "这些行动已经由底部操作栏或靠近物体的上下文交互承载。",
		"options": [
			_encounter_option(&"search", "搜索房间"),
			_encounter_option(&"open_chest", "开启物资箱"),
			_encounter_option(&"attack_basic", "基础攻击"),
		],
	}
	surface.apply_surface_model(model)
	await _frames(2)
	_check(surface.encounter_option_buttons.is_empty(), "basic search/chest/attack actions were duplicated in a floating encounter frame")
	_check(not surface.encounter_backdrop.visible and not surface.encounter_options_box.visible, "empty basic encounter frame still covers the room")
	_check(
		not surface.encounter_title_label.visible
		and not surface.encounter_body_label.visible
		and not surface.encounter_result_label.visible,
		"deprecated steady-HUD encounter copy leaked into the viewport"
	)
	_check(
		not surface.room_body_label.visible
		and not surface.objective_label.visible
		and not surface.player_tag_label.visible,
		"deprecated room copy leaked into the viewport"
	)

	for event_type in [&"trader", &"dice", &"altar", &"trap"]:
		model["encounter_section"] = {
			"title": "事件抉择",
			"body": "靠近事件标记后处理。",
			"encounter_type": event_type,
			"options": [_encounter_option(&"leave", "离开事件")],
		}
		surface.apply_surface_model(model)
		await _frames(2)
		_check(surface.encounter_option_buttons.is_empty(), "%s decision remained duplicated in the steady HUD" % event_type)
		_check(not surface.encounter_backdrop.visible and not surface.encounter_options_box.visible, "%s encounter left its HUD strip or frame visible" % event_type)

	model["encounter_section"] = {
		"title": "后续事件",
		"body": "由 event_like 标签路由至事件模态窗。",
		"encounter_type": &"future_event",
		"encounter_tags": [&"event_like"],
		"options": [_encounter_option(&"leave", "离开事件")],
	}
	surface.apply_surface_model(model)
	await _frames(2)
	_check(surface.encounter_option_buttons.is_empty(), "tagged future event remained duplicated in the steady HUD")
	_check(not surface.encounter_backdrop.visible and not surface.encounter_options_box.visible, "tagged future event left its HUD strip or frame visible")

	model["encounter_section"] = {
		"title": "规则终端",
		"body": "选择规则处理方式。",
		"encounter_type": &"rule_modifier",
		"encounter_tags": [&"rule"],
		"options": [_encounter_option(&"activate_relay", "启动中继")],
	}
	surface.apply_surface_model(model)
	await _frames(2)
	_check(surface.encounter_option_buttons.size() == 1, "non-event encounter compatibility was removed with event-modal deduplication")
	_check(surface.encounter_backdrop.visible and surface.encounter_options_box.visible, "non-event encounter lost its compatible HUD presentation")

	canvas.queue_free()
	await _frames(2)


func _encounter_option(option_id: StringName, title: String) -> Dictionary:
	return {
		"id": option_id,
		"title": title,
		"summary": "玩家可见的行动说明。",
		"disabled": false,
		"requires_confirm": false,
		"command_payload": {"option_id": option_id},
	}


func _check_world_popup_focus_clearance() -> void:
	var viewport_size := Vector2(1280, 720)
	var profile := UILayoutProfileScript.profile_for_resolution(&"1280x720")
	var footer := UILayerContractScript.run_footer_geometry(profile)
	var safe_rect := RuntimeLayoutScript.context_ui_rect_for_viewport(viewport_size)
	var reserved_rects := RuntimeLayoutScript.context_reserved_rects_for_viewport(viewport_size)
	var gameplay_rect := Rect2(Vector2(515, 8), Vector2(545, 545))
	var canvas := Control.new()
	canvas.name = "WorldPopupFocusCanvas"
	canvas.size = viewport_size
	root.add_child(canvas)
	var popup := WorldContextPopupScript.new() as G41WorldContextPopup
	canvas.add_child(popup)
	await _frames(2)
	var contexts := [
		{
			"interaction_kind": &"chest",
			"world_pos": safe_rect.get_center(),
			"player_world_pos": safe_rect.get_center() + Vector2(34, 8),
			"opened_once": false,
			"container_open": false,
			"items": [],
		},
		{
			"interaction_kind": &"ground_loot",
			"world_pos": safe_rect.position + safe_rect.size * Vector2(0.34, 0.52),
			"player_world_pos": safe_rect.position + safe_rect.size * Vector2(0.38, 0.55),
			"opened_once": true,
			"container_open": true,
			"items": [_sample_item("focus_item_a"), _sample_item("focus_item_b")],
		},
		{
			"interaction_kind": &"chest",
			"world_pos": safe_rect.position + safe_rect.size * Vector2(0.72, 0.46),
			"player_world_pos": safe_rect.position + safe_rect.size * Vector2(0.68, 0.51),
			"opened_once": true,
			"container_open": true,
			"items": [_sample_item("focus_item_c")],
		},
	]
	for context_fixture in contexts:
		var context: Dictionary = context_fixture.duplicate(true)
		context["room_bounds"] = safe_rect
		context["gameplay_focus_rect"] = gameplay_rect
		context["reserved_rects"] = reserved_rects
		context["inventory_items"] = []
		context["backpack_remaining"] = 10
		popup.apply_context(context)
		await _frames(3)
		var placement_rect: Rect2 = popup.get_meta("placement_rect", Rect2())
		var object_clearance: Rect2 = popup.get_meta("object_clearance_rect", Rect2())
		var player_clearance: Rect2 = popup.get_meta("player_clearance_rect", Rect2())
		_check(popup.get_meta("placement_mode", &"") == &"contextual_anchor", "world popup did not use contextual anchor placement")
		_check(safe_rect.encloses(placement_rect), "world popup escaped its safe lane: %s" % placement_rect)
		_check(not placement_rect.intersects(object_clearance), "world popup obscures the interacted object: %s" % placement_rect)
		_check(not placement_rect.intersects(player_clearance), "world popup obscures the player: %s" % placement_rect)
		_check(placement_rect.end.y < float(footer.get("mine_risk_top", 0.0)), "world popup entered the mine-risk/footer band")
		_check(
			placement_rect.end.y <= safe_rect.end.y + 0.1,
			"world popup entered the reserved command-feedback lane"
		)
		_check(popup.get_theme_stylebox(&"panel") is StyleBoxTexture, "world popup retained a flat plastic frame")
		for reserved_rect in reserved_rects:
			_check(not placement_rect.intersects(reserved_rect), "world popup overlaps a reserved HUD frame: %s" % reserved_rect)
		var gameplay_overlap_ratio := (
			placement_rect.intersection(gameplay_rect).get_area() / maxf(1.0, placement_rect.get_area())
			if placement_rect.intersects(gameplay_rect)
			else 0.0
		)
		_check(gameplay_overlap_ratio <= 0.45, "world popup covers too much of the room image: %.3f" % gameplay_overlap_ratio)
	canvas.queue_free()
	await _frames(2)


func _surface_model(profile: Dictionary, adjacent: int, items: Array = []) -> Dictionary:
	var model := RunSurfaceModelScript.build({
		"position": Vector2i(2, 2),
		"current_room": &"Normal",
		"protocol_level": 5,
		"pressure": 0,
		"adjacent_mines": adjacent,
		"inventory_items": items,
		"backpack_used": 6 if not items.is_empty() else 0,
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
	model["command_feedback"] = ""
	model["action_hint"] = ""
	return model


func _long_detail_item() -> Dictionary:
	return {
		"instance_id": "i3r_focus_long_detail",
		"item_id": "field_sustainment_bundle",
		"display_name": "远征维生与精密修复组合物资",
		"short_description": "包含应急止血、过滤、固定与精密修复组件；用于验证三行长详情不会贴住或遮挡底部负重标签。",
		"rarity": &"tier_4",
		"weight": 6,
		"quantity": 1,
		"pickup_allowed": true,
	}


func _sample_item(instance_id: String) -> Dictionary:
	return {
		"instance_id": instance_id,
		"item_id": "emergency_bandage",
		"display_name": "应急止血贴",
		"short_description": "可带回的医疗物资。",
		"rarity": &"tier_2",
		"weight": 1,
		"quantity": 1,
		"pickup_allowed": true,
	}


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("%s resolutions=1280x720,1366x768,1600x900,1920x1080 mine_risk=unknown,0,1,3,8 footer=steady_compact toast=success_suppressed,rejection_unframed_transient hud=single_frame_interior_bands quick_bag=long_detail_safe_gap encounter=basic_deduplicated,event_modal_only,non_event_preserved popup=peripheral_textured_focus_clear" % PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error("I3R run focus layout failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
