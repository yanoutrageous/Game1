extends SceneTree

const RunSurfaceScript := preload("res://scripts/ui/run_surface/run_surface.gd")
const RunSurfaceModelScript := preload("res://scripts/ui/run_surface/run_surface_model.gd")
const RunUIViewModelScript := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory/inventory_panel.gd")
const GroundLootPanelScript := preload("res://scripts/ui/ground_loot/ground_loot_panel.gd")
const WorldContextPopupScript := preload("res://scripts/gameplay/interaction/g41_world_context_popup.gd")
const PlayerControllerScript := preload("res://scripts/gameplay/player/player_controller.gd")
const RuntimeAnimationCatalogScript := preload("res://scripts/presentation/art24/art24_runtime_animation_catalog.gd")
const RuntimeInputProfileScript := preload("res://scripts/core/input/runtime_input_profile.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")

const PASS_MARKER := "I3_HUD_ITEM_INPUT_CHARACTER=PASS"
const FAIL_MARKER := "I3_HUD_ITEM_INPUT_CHARACTER=FAIL"

var failures: Array[String] = []
var item_action_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	RuntimeInputProfileScript.install()
	await _check_hud_actions_and_items()
	await _check_input_and_character_profile()
	await _check_production_gamepad_propagation()
	_finish()


func _check_hud_actions_and_items() -> void:
	var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(&"1280x720")
	profile["actual_viewport_size"] = Vector2i(1280, 720)
	var item := _sample_item("i3_shared_item", "沉星罗盘", 3, 4)
	var snapshot := {
		"run_active": true,
		"mode": &"RAW_MODE",
		"phase": &"RAW_PHASE",
		"outcome": "RAW_OUTCOME",
		"position": Vector2i(2, 1),
		"current_room": &"Monster",
		"adjacent_mines": 3,
		"protocol_level": 4,
		"pressure": 20,
		"inventory_items": [item],
		"backpack_used": 4,
		"backpack_capacity": 12,
		"room_floor_item_count": 1,
		"combat_runtime": {"active": true},
		"search_state_data": {"can_search": false, "searched": false},
	}
	var model := RunSurfaceModelScript.build(snapshot, null, profile, {})
	var actions: Array = model.get("action_buttons", [])
	_require(actions.size() == 7, "HUD did not retain exactly seven action descriptors")
	var ids: Dictionary = {}
	var saw_disabled := false
	for index in range(actions.size()):
		var action: Dictionary = actions[index]
		var action_id := StringName(action.get("id", &""))
		ids[action_id] = true
		var enabled := bool(action.get("enabled", false))
		if not enabled:
			saw_disabled = true
		elif saw_disabled:
			_require(false, "enabled HUD action appeared after disabled context actions")
		_require(int(action.get("context_rank", -1)) == index, "HUD context rank drifted at %d" % index)
	_require(ids.size() == 7, "HUD action IDs are not unique")
	_require(StringName((actions[0] as Dictionary).get("id", &"")) == &"combat", "combat room did not place its executable primary action first")
	_require(bool((actions[0] as Dictionary).get("is_primary", false)), "first executable HUD action is not marked primary")
	_require(not String(model.get("action_hint", "")).contains("暂不可用"), "default HUD guidance selected a disabled action")
	var player_copy := "%s\n%s" % [model.get("room_summary", ""), "\n".join(model.get("status_lines", []))]
	for forbidden in ["RAW_MODE", "RAW_PHASE", "RAW_OUTCOME", "Running", "运行状态"]:
		_require(not player_copy.contains(forbidden), "HUD leaked engineering copy: %s" % forbidden)
	_require(String((model.get("mine_risk", {}) as Dictionary).get("display_text", "")).contains("周围雷险"), "HUD lost the authoritative nearby-mine descriptor")
	_require(RunSurfaceModelScript.protocol_title_for_level(5) == "正常作业", "authoritative protocol-5 title was renamed")

	var host := Control.new()
	host.size = Vector2(1280, 720)
	root.add_child(host)
	var surface := RunSurfaceScript.new()
	host.add_child(surface)
	surface.build()
	surface.apply_layout_profile(profile)
	surface.apply_surface_model(model)
	await _frames(3)
	var first_action := surface.action_bar.get_child(0) as Button
	_require(first_action != null and first_action.name == "RunAction_combat", "production HUD did not apply contextual action order")
	_require(first_action != null and bool(first_action.get_meta("context_primary", false)), "production HUD did not visually mark its primary action")
	for raw_button in surface.action_buttons.values():
		var button := raw_button as Button
		if button == null:
			continue
		_require(
			button.focus_mode == (Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL),
			"HUD action %s has focus mode %s while disabled=%s" % [button.name, button.focus_mode, button.disabled]
		)
	_require(surface.resource_label.text.contains("周围雷险"), "production HUD omitted 周围雷险")
	_require(not surface.resource_label.text.contains("正常作业"), "left HUD rail retained the redundant normal-operation label")

	var descriptor := RunUIViewModelScript.item_presentation(item)
	_require(bool(descriptor.get("read_only", false)), "shared item presentation is not read-only")
	_require(String(descriptor.get("display_name", "")) == "沉星罗盘", "shared item name drifted")
	_require(int(descriptor.get("quantity", 0)) == 3 and int(descriptor.get("weight", 0)) == 4, "shared item quantity/weight drifted")
	_require(String(descriptor.get("detail_text", "")).contains("[T6] 秘藏"), "shared item detail omitted non-color rarity")
	_require(not String(descriptor.get("detail_text", "")).contains("raw_internal_item_id"), "shared item detail leaked item_id")
	var quick_button := surface.backpack_strip.get_child(0) as Button
	_require(quick_button != null and quick_button.tooltip_text == String(descriptor.get("detail_text", "")), "quick bag bypassed the shared item detail")
	_require(surface.backpack_detail_label.text == String(descriptor.get("detail_text", "")), "quick bag focus detail drifted from the shared descriptor")
	_require(surface.backpack_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "quick bag real-item area is not scrollable")
	_require(surface.backpack_capacity_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "quick bag burden is not bottom-centered")
	_require(not _tree_text(surface.backpack_strip).contains("空位"), "quick bag rendered fake empty slots")

	var inventory := InventoryPanelScript.new()
	var ground := GroundLootPanelScript.new()
	host.add_child(inventory)
	host.add_child(ground)
	await _frames(2)
	_require(String(inventory.call("_item_summary_text", item)) == String(descriptor.get("summary_text", "")), "inventory summary bypassed the shared descriptor")
	_require(String(inventory.call("_item_detail_text", item)) == String(descriptor.get("detail_text", "")), "inventory detail bypassed the shared descriptor")
	_require(String(ground.call("_item_summary_text", item)) == String(descriptor.get("summary_text", "")), "ground-loot summary bypassed the shared descriptor")
	_require(String(ground.call("_item_detail_text", item)) == String(descriptor.get("detail_text", "")), "ground-loot detail bypassed the shared descriptor")
	var result_item := RunUIViewModelScript.result_item_model(item)
	_require(String(result_item.get("display_name", "")) == String(descriptor.get("display_name", "")), "result item name bypassed the shared descriptor")
	_require(int(result_item.get("weight", -1)) == int(descriptor.get("weight", -2)), "result item weight bypassed the shared descriptor")
	var drop_envelope := {
		"accepted": true,
		"ok": true,
		"status": &"dropped",
		"action_result": {"ok": true, "status": &"dropped", "item": item.duplicate(true)},
	}
	_require(
		RunUIViewModelScript.command_result_text(drop_envelope) == "已放下：沉星罗盘。",
		"item command feedback ignored the authoritative item inside the CommandResult envelope"
	)

	var world_popup := WorldContextPopupScript.new()
	host.add_child(world_popup)
	await _frames(2)
	world_popup.pickup_requested.connect(_count_item_action)
	world_popup.replace_requested.connect(func(_ground_id: String, _drop_id: String) -> void: item_action_count += 1)
	var candidate_without_level := _sample_item("i3_candidate_no_level", "普通绷带", 1, 1)
	candidate_without_level.erase("collectible_level")
	world_popup.apply_context({
		"interaction_kind": &"ground_loot",
		"world_pos": Vector2(620, 360),
		"player_world_pos": Vector2(560, 360),
		"room_bounds": Rect2(300, 20, 960, 650),
		"items": [item],
		"inventory_items": [
			_sample_item("i3_candidate", "旧式罗盘", 1, 2),
			candidate_without_level,
		],
		"backpack_remaining": 1,
		"pickup_allowed": true,
	})
	await _frames(2)
	var world_info := world_popup.find_child("ContextItemInfo", true, false) as Button
	var world_marker := world_popup.find_child("WorldContextItemRarityMarker", true, false) as ColorRect
	for expected in [
		String(descriptor.get("display_name", "")),
		String(descriptor.get("rarity_text", "")),
		String(descriptor.get("collectible_level_text", "")),
		"重%s" % descriptor.get("weight", 0),
	]:
		_require(world_info != null and world_info.text.contains(expected), "world item compact summary omitted shared descriptor field: %s" % expected)
	_require(world_info != null and world_info.tooltip_text == String(descriptor.get("detail_text", "")), "world item detail bypassed the shared descriptor")
	_require(world_marker != null and world_marker.color.is_equal_approx(Color((descriptor.get("rarity", {}) as Dictionary).get("color"))), "world item independent rarity marker bypassed the shared descriptor")
	if world_info != null:
		world_info.mouse_entered.emit()
		world_info.grab_focus()
	await process_frame
	_require(item_action_count == 0, "world item hover/focus emitted a command")
	world_popup.call("_begin_replacement", "i3_shared_item")
	await _frames(2)
	var replacement_info := world_popup.find_child("ReplacementCandidateInfo", true, false) as Button
	var replacement_name := replacement_info.find_child("ReplacementCandidateName", true, false) as Label if replacement_info != null else null
	var replacement_meta := replacement_info.find_child("ReplacementCandidateMeta", true, false) as Label if replacement_info != null else null
	var candidate_descriptor := RunUIViewModelScript.item_presentation(_sample_item("i3_candidate", "旧式罗盘", 1, 2))
	_require(replacement_info != null and replacement_info.text.is_empty(), "replacement candidate retained clipped single-control copy")
	_require(
		replacement_info != null and replacement_info.get_meta("replacement_layout", &"") == &"two_line",
		"replacement candidate did not expose the two-line layout contract"
	)
	_require(
		replacement_name != null
		and replacement_name.text == "%s ×%d" % [
			candidate_descriptor.get("display_name", ""),
			candidate_descriptor.get("quantity", 0),
		],
		"replacement candidate name/count line drifted from the shared descriptor"
	)
	for expected in [
		String(candidate_descriptor.get("rarity_text", "")).replace("] ", "]"),
		String(candidate_descriptor.get("collectible_level_text", "")).replace(" ", ""),
		"重%s" % candidate_descriptor.get("weight", 0),
	]:
		_require(replacement_meta != null and replacement_meta.text.contains(expected), "replacement metadata line omitted shared descriptor field: %s" % expected)
	_require(
		replacement_name != null
		and replacement_meta != null
		and not replacement_name.text.contains("\n")
		and not replacement_meta.text.contains("\n")
		and replacement_name.get_global_rect().end.y <= replacement_meta.get_global_rect().end.y,
		"replacement candidate did not retain a readable two-line hierarchy"
	)
	_require(
		replacement_name != null and _label_text_fits(replacement_name),
		"replacement name/count line is visually clipped (text %.1f / available %.1f)" % [
			_label_text_width(replacement_name),
			replacement_name.size.x if replacement_name != null else 0.0,
		]
	)
	_require(
		replacement_meta != null and _label_text_fits(replacement_meta),
		"replacement quality/level/weight line is visually clipped (text %.1f / available %.1f)" % [
			_label_text_width(replacement_meta),
			replacement_meta.size.x if replacement_meta != null else 0.0,
		]
	)
	_require(
		replacement_meta != null
		and int(replacement_meta.get_meta("collectible_level", -1)) == int(candidate_descriptor.get("collectible_level", 0)),
		"replacement candidate did not preserve the authoritative collectible level"
	)
	var level_less_info: Button
	for raw_candidate in world_popup.find_children("ReplacementCandidateInfo", "", true, false):
		var candidate := raw_candidate as Button
		if candidate != null and String(candidate.get_meta("item_instance_id", "")) == "i3_candidate_no_level":
			level_less_info = candidate
			break
	var level_less_meta := level_less_info.find_child("ReplacementCandidateMeta", true, false) as Label if level_less_info != null else null
	_require(
		level_less_meta != null
		and int(level_less_meta.get_meta("collectible_level", -1)) == 0
		and not level_less_meta.text.contains("收藏等级"),
		"replacement candidate invented a collectible level for an item without one"
	)
	var replacement_marker := replacement_info.find_child("WorldContextItemRarityMarker", true, false) as ColorRect if replacement_info != null else null
	_require(replacement_marker != null, "replacement candidate lost its independent rarity marker")
	_require(replacement_info != null and replacement_info.tooltip_text == String(candidate_descriptor.get("detail_text", "")), "replacement detail bypassed the shared descriptor")

	host.queue_free()
	await _frames(3)


func _check_input_and_character_profile() -> void:
	var player := PlayerControllerScript.new()
	root.add_child(player)
	await _frames(2)
	player.set_local_position(Vector2(0.25, 0.25))
	var before_preview: Vector2 = player.get_local_position()
	player.play_step(Vector2.RIGHT)
	_require(player.get_local_position().is_equal_approx(before_preview), "key-down preview added an extra displacement")
	var move_result: Dictionary = player.move_local(Vector2.RIGHT, 1.0 / 60.0)
	_require(StringName(move_result.get("status", &"")) == &"moved", "continuous movement did not own the first displacement")
	_require(player.get_local_position().x > before_preview.x, "continuous movement did not change player position")

	var default_set := RuntimeAnimationCatalogScript.default_player_animation_set()
	var fixture_set := default_set.duplicate(true)
	fixture_set["appearance_id"] = &"graytail_field_coat"
	fixture_set["source_status"] = &"audited_runtime_fixture"
	var position_before_profile: Vector2 = player.get_local_position()
	player.set_presentation_profile(&"graytail_field_coat", &"i3_fixture_set", {&"i3_fixture_set": fixture_set})
	var presentation: Dictionary = player.presentation_snapshot()
	_require(StringName(presentation.get("appearance_id", &"")) == &"graytail_field_coat", "appearance replacement API did not apply")
	_require(StringName(presentation.get("animation_set_id", &"")) == &"i3_fixture_set", "animation-set replacement API did not apply")
	_require(String(presentation.get("animation_root", "")) == RuntimeAnimationCatalogScript.PLAYER_ROOT, "animation-set API did not retain the audited runtime root")
	_require(player.get_local_position().is_equal_approx(position_before_profile), "presentation replacement mutated gameplay position")
	for forbidden_key in ["inventory", "equipped", "owned", "save", "authority"]:
		_require(not presentation.has(forbidden_key), "presentation snapshot gained gameplay authority: %s" % forbidden_key)
	var fixture_path := RuntimeAnimationCatalogScript.player_texture_path(&"right", &"move", 0, false, false, fixture_set)
	_require(fixture_path == "res://assets/art24/actors/player/right_walk_a.png", "audited runtime walking frame did not resolve through the replacement API")
	_require(RuntimeAnimationCatalogScript.player_walk_bob_offset(0.1, true, fixture_set) == 0.0, "reduced motion no longer suppresses character bob")
	var fallback := RuntimeAnimationCatalogScript.resolve_player_animation_set(&"missing_i3_set")
	_require(bool(fallback.get("used_fallback", false)), "missing animation set did not fail closed to the audited default")
	_require(String(fallback.get("root", "")) == RuntimeAnimationCatalogScript.PLAYER_ROOT, "animation fallback escaped the audited runtime root")
	player.queue_free()
	await _frames(2)


func _check_production_gamepad_propagation() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production main scene could not be loaded for gamepad propagation")
	if packed == null:
		return
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(5)
	var run_scene := main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing")
	if run_scene == null:
		main.queue_free()
		await _frames(2)
		return
	var bus: Variant = run_scene.get("command_bus")
	_require(bus != null, "production CommandBus is missing")
	if bus == null:
		main.queue_free()
		await _frames(2)
		return
	var start_result: Dictionary = bus.dispatch(&"start_demo_run")
	_require(bool(start_result.get("ok", false)), "production run could not start")
	run_scene.call("_show_run_screen")
	await _frames(5)
	var production_player := run_scene.get("player_controller") as PlayerController
	var inventory_panel := run_scene.get("inventory_panel") as Control
	_require(production_player != null and inventory_panel != null, "production input fixtures are missing")
	if production_player != null:
		production_player.set_local_position(Vector2(0.25, 0.25))
		var before_gamepad := production_player.get_local_position()
		_parse_joy_button(JOY_BUTTON_DPAD_RIGHT, true)
		await _frames(8)
		_parse_joy_button(JOY_BUTTON_DPAD_RIGHT, false)
		await _frames(2)
		_require(production_player.get_local_position().x > before_gamepad.x, "D-pad input did not propagate through production continuous movement")
	_parse_joy_button(JOY_BUTTON_LEFT_SHOULDER, true)
	await process_frame
	_parse_joy_button(JOY_BUTTON_LEFT_SHOULDER, false)
	await _frames(3)
	_require(inventory_panel != null and inventory_panel.visible, "LB InputEventJoypadButton did not open the production inventory")
	_parse_joy_button(JOY_BUTTON_B, true)
	await process_frame
	_parse_joy_button(JOY_BUTTON_B, false)
	await _frames(3)
	_require(inventory_panel == null or not inventory_panel.visible, "B InputEventJoypadButton did not close the production inventory")
	main.queue_free()
	await _frames(4)


func _sample_item(instance_id: String, display_name: String, quantity: int, weight: int) -> Dictionary:
	return {
		"instance_id": instance_id,
		"item_id": "raw_internal_item_id",
		"display_name": display_name,
		"item_type": "collectible",
		"rarity": &"tier_6",
		"collectible_level": 6,
		"quantity": quantity,
		"weight": weight,
		"base_value": 17,
		"short_description": "指针会记录穿过的回廊与回声。",
		"pickup_allowed": true,
	}


func _parse_joy_button(button_index: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button_index
	event.pressed = pressed
	event.pressure = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


func _count_item_action(_instance_id: String) -> void:
	item_action_count += 1


func _tree_text(node: Node) -> String:
	var parts: Array[String] = []
	if node is Label:
		parts.append((node as Label).text)
	elif node is Button:
		parts.append((node as Button).text)
	for child in node.get_children():
		parts.append(_tree_text(child))
	return "\n".join(parts)


func _label_text_fits(label: Label) -> bool:
	return _label_text_width(label) <= label.size.x + 0.5


func _label_text_width(label: Label) -> float:
	if label == null:
		return INF
	var font := label.get_theme_font("font")
	if font == null:
		return INF
	return font.get_string_size(
		label.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		label.get_theme_font_size("font_size")
	).x


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("%s hud=primary_action,mine_risk actions=7,context_order items=shared_descriptor,scroll replacement=two_line,no_clip,authoritative_level input=single_path,gamepad_propagated character=appearance,animation_set reduced_motion=preserved" % PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error("I3 HUD/item/input/character failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
