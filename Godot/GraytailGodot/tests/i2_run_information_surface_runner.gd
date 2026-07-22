extends SceneTree

const RunSurfaceScript := preload("res://scripts/ui/run_surface/run_surface.gd")
const RunSurfaceModelScript := preload("res://scripts/ui/run_surface/run_surface_model.gd")
const ItemRarityDescriptor := preload("res://scripts/presentation/item_rarity_descriptor.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")

var failures: Array[String] = []
var unexpected_actions := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_read_only_descriptors()
	root.size = Vector2i(1280, 720)
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)
	var surface := RunSurfaceScript.new() as RunSurface
	canvas.add_child(surface)
	surface.build()
	_connect_action_counters(surface)
	var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(&"1280x720")
	surface.apply_layout_profile(profile)
	await _check_quick_bag(surface, profile)
	await _check_mine_risk_and_protocol(surface, profile)
	canvas.queue_free()
	await _frames(2)
	_finish()


func _check_read_only_descriptors() -> void:
	var unknown := RunSurfaceModelScript.mine_risk_descriptor(-1)
	_check(not bool(unknown.get("known", true)), "Missing adjacent-mine data was not kept unknown")
	_check(String(unknown.get("display_text", "")).contains("未知"), "Unknown mine-risk text is not player-facing")
	for adjacent in range(9):
		var descriptor := RunSurfaceModelScript.mine_risk_descriptor(adjacent)
		_check(bool(descriptor.get("known", false)), "Known adjacent-mine count %d became unknown" % adjacent)
		_check(int(descriptor.get("count", -1)) == adjacent, "Mine-risk descriptor changed count %d" % adjacent)
		_check(String(descriptor.get("display_text", "")).contains(str(adjacent)), "Mine-risk descriptor omitted count %d" % adjacent)
		_check(String(descriptor.get("badge", "")) != "", "Mine-risk descriptor %d lacks a non-color badge" % adjacent)
	var expected_titles := {1: "最终建议", 2: "返程建议", 3: "风险作业", 4: "轻度警戒", 5: "正常作业"}
	for level in range(1, 6):
		_check(RunSurfaceModelScript.protocol_title_for_level(level) == expected_titles[level], "Protocol title drifted at level %d" % level)
	var no_public_count := RunSurfaceModelScript.build({"current_room": &"Normal"}, null, {}, {})
	_check(not bool((no_public_count.get("mine_risk", {}) as Dictionary).get("known", true)), "Absent public adjacent-mine field defaulted to zero")


func _check_quick_bag(surface: RunSurface, profile: Dictionary) -> void:
	for item_count in [0, 1, 4, 5, 8]:
		var items := _sample_items(item_count)
		surface.apply_surface_model(_surface_model(profile, items, 5, 0, 2))
		await _frames(2)
		var buttons := _active_backpack_buttons(surface.backpack_strip)
		_check(buttons.size() == item_count, "Quick bag count %d rendered %d real rows" % [item_count, buttons.size()])
		_check(not _tree_text(surface.backpack_strip).contains("空位"), "Quick bag count %d rendered a fake empty slot" % item_count)
		for index in range(buttons.size()):
			var button := buttons[index]
			_check(button.focus_mode == Control.FOCUS_ALL, "Quick bag row %d is not keyboard/gamepad focusable" % index)
			_check(not button.text.contains("tier_"), "Quick bag row %d leaked a raw rarity key" % index)
			_check(String(button.get_meta("rarity_border_token", "")) != "", "Quick bag row %d omitted its rarity border token" % index)
		if item_count > 0:
			var first_button := buttons[0]
			var before_actions := unexpected_actions
			first_button.grab_focus()
			await _frames(1)
			_check(unexpected_actions == before_actions, "Quick-bag focus emitted a run action")
			var first_item: Dictionary = items[0]
			var rarity := ItemRarityDescriptor.describe_item(first_item)
			var detail := surface.backpack_detail_label.text
			_check(detail.contains(String(first_item.get("display_name", ""))), "Quick-bag focus detail omitted item name")
			_check(detail.contains(String(rarity.get("display_text", ""))), "Quick-bag focus detail omitted non-color rarity")
			_check(detail.contains("数量") and detail.contains("重量"), "Quick-bag focus detail omitted quantity or weight")
	if surface.backpack_scroll != null:
		_check(surface.backpack_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "Quick bag is not vertically scrollable")
		_check(surface.backpack_strip.get_combined_minimum_size().y > surface.backpack_scroll.size.y, "Eight-item quick bag did not exceed the viewport for scrolling")
	else:
		_check(false, "Quick-bag ScrollContainer is missing")
	_check(surface.backpack_capacity_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Burden summary is not centered")
	_check(surface.backpack_capacity_label.text.contains("负重"), "Burden summary is missing")


func _check_mine_risk_and_protocol(surface: RunSurface, profile: Dictionary) -> void:
	for adjacent in [-1, 0, 1, 3, 6, 8]:
		surface.apply_surface_model(_surface_model(profile, [], 5, 0, adjacent))
		await _frames(1)
		var expected := String(RunSurfaceModelScript.mine_risk_descriptor(adjacent).get("display_text", ""))
		_check(surface.resource_label.text == expected, "HUD mine-risk surface drifted for %d" % adjacent)
		_check(not surface.resource_label.text.contains("【正常作业】"), "Legacy normal-operation placeholder remains in the left rail")
	var expected_titles := {1: "最终建议", 2: "返程建议", 3: "风险作业", 4: "轻度警戒", 5: "正常作业"}
	var pressures := {1: 80, 2: 60, 3: 40, 4: 20, 5: 0}
	for level in range(1, 6):
		surface.apply_surface_model(_surface_model(profile, [], level, pressures[level], 2))
		await _frames(1)
		_check(surface.right_title_label.text.contains(expected_titles[level]), "HUD omitted protocol title at level %d" % level)
		_check(surface.right_title_label.text.contains(str(level)), "HUD omitted protocol level %d" % level)
		var expected_color: Color = surface.call("_protocol_level_color", level)
		_check(surface.protocol_pressure_fill.color.is_equal_approx(expected_color), "Protocol pressure color is not derived from level %d" % level)
		_check(surface.right_title_label.get_theme_color("font_color").is_equal_approx(expected_color), "Protocol title accent is not derived from level %d" % level)


func _surface_model(profile: Dictionary, items: Array[Dictionary], protocol_level: int, pressure: int, adjacent: int) -> Dictionary:
	var snapshot := {
		"position": Vector2i(1, 1),
		"current_room": &"Normal",
		"protocol_level": protocol_level,
		"pressure": pressure,
		"adjacent_mines": adjacent,
		"inventory_items": items.duplicate(true),
		"backpack_used": items.size(),
		"backpack_capacity": 12,
		"hp": 8,
		"max_hp": 10,
		"power": 3,
		"black_coin": 4,
		"gold_coin": 2,
		"run_active": true,
		"search_state_data": {"can_search": false, "searched": false},
		"run_map_snapshot": {"KnownMap": {"width": 3, "height": 3, "public_cells": []}},
	}
	var model := RunSurfaceModelScript.build(snapshot, null, profile, {})
	model["command_feedback"] = ""
	model["action_hint"] = ""
	return model


func _sample_items(count: int) -> Array[Dictionary]:
	var rarities := [&"tier_1", &"tier_2", &"tier_3", &"tier_4", &"tier_5", &"tier_6", &"unique", &"unknown"]
	var items: Array[Dictionary] = []
	for index in range(count):
		items.append({
			"instance_id": "i2-quick-%d" % index,
			"item_id": "emergency_bandage",
			"display_name": "验证物资%d" % (index + 1),
			"short_description": "公开说明 %d" % (index + 1),
			"rarity": rarities[index % rarities.size()],
			"quantity": index + 1,
			"weight": index + 1,
			"base_value": 10,
		})
	return items


func _connect_action_counters(surface: RunSurface) -> void:
	surface.interact_requested.connect(func() -> void: unexpected_actions += 1)
	surface.inventory_requested.connect(func() -> void: unexpected_actions += 1)
	surface.ground_loot_requested.connect(func() -> void: unexpected_actions += 1)
	surface.map_requested.connect(func(_source: StringName) -> void: unexpected_actions += 1)
	surface.combat_requested.connect(func() -> void: unexpected_actions += 1)
	surface.extract_requested.connect(func() -> void: unexpected_actions += 1)
	surface.pause_requested.connect(func() -> void: unexpected_actions += 1)


func _active_backpack_buttons(container: GridContainer) -> Array[Button]:
	var buttons: Array[Button] = []
	for child in container.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child as Button)
	return buttons


func _tree_text(node: Node) -> String:
	var text := ""
	if node is Label:
		text += (node as Label).text
	elif node is Button:
		text += (node as Button).text
	for child in node.get_children():
		text += _tree_text(child)
	return text


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("I2_RUN_INFORMATION_SURFACE=PASS quick_bag=0,1,4,5,8 scroll=all_items hover_focus=display_only mine_risk=unknown,0-8 protocol=levels_1-5")
		quit(0)
		return
	for failure in failures:
		push_error("I2 run information surface failure: " + failure)
	print("I2_RUN_INFORMATION_SURFACE=FAIL failures=%d" % failures.size())
	quit(1)
