extends SceneTree

const InteractableScript := preload("res://scripts/gameplay/interaction/g41_interactable.gd")
const GroundLootEntityScript := preload("res://scripts/gameplay/loot/g41_ground_loot_entity.gd")
const RoomRuntimeViewScript := preload("res://scripts/gameplay/runtime/g41_room_runtime_view.gd")
const WorldObjectProjectionScript := preload("res://scripts/gameplay/runtime/g41_world_object_projection.gd")
const ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")
const ItemVisualCatalogScript := preload("res://scripts/presentation/art24/art24_item_visual_catalog.gd")
const ItemRarityDescriptorScript := preload("res://scripts/presentation/item_rarity_descriptor.gd")
const MapCellLayerLayoutScript := preload("res://scripts/ui/map_shared/map_cell_layer_layout.gd")
const RunSurfaceScript := preload("res://scripts/ui/run_surface/run_surface.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")
const PlayerScene := preload("res://scenes/player/player.tscn")
const MiniMapScene := preload("res://scenes/ui/minimap/minimap_panel.tscn")

const EXPECTED_RARITY_COLORS := {
	&"tier_1": Color("d0d8e0"),
	&"tier_2": Color("78dcaa"),
	&"tier_3": Color("5fa5ff"),
	&"tier_4": Color("be78ff"),
	&"tier_5": Color("ffc346"),
	&"tier_6": Color("fa5f55"),
	&"unique": Color("f6e079"),
	&"unknown": Color("a9b0ad"),
}

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check_rarity_palette_and_item_resolver()
	_check_map_cell_layer_contract()
	await _check_texture_fallback_and_world_drop()
	await _check_collision_visible_correspondence()
	await _check_protocol_and_left_density()
	await _check_player_contact_shadow()
	await _check_ground_depth_and_floor_reachability()
	_check_clear_world_loot_placement()
	await _check_minimap_texture_bounds()
	await _check_readable_compact_minimap()
	await _check_compact_corner_counts()
	await _check_scaled_capacity_text()
	await _check_world_item_summary_fit()
	await _check_debug_chest_spawn()
	_finish()


func _check_world_item_summary_fit() -> void:
	var popup := G41WorldContextPopup.new()
	root.add_child(popup)
	var item := {"instance_id": "summary_fit", "item_id": "col_10", "display_name": "旧工具头", "item_type": "collectible", "rarity": &"tier_3", "collectible_level": 3, "weight": 1}
	popup.apply_context({"interaction_kind": &"ground_loot", "world_pos": Vector2(640, 360), "items": [item], "backpack_remaining": 10})
	var button := popup.find_child("ContextItemInfo", true, false) as Button
	await _wait_until(func() -> bool: return button != null and button.size.x > 156.0, "world item summary row sized")
	var icon_width := minf(button.icon.get_width(), button.size.y - button.get_theme_stylebox("normal").get_minimum_size().y) if button.icon != null else 0.0
	var text_width := button.size.x - button.get_theme_stylebox("normal").get_minimum_size().x - icon_width - button.get_theme_constant("h_separation")
	var summary := button.text.split("\n")[1]
	_check(summary.contains("3") and summary.contains("重1"), "World item summary lost collection level or weight")
	_check(button.get_theme_font("font").get_string_size(summary, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x <= text_width, "World item summary clips its weight behind the pickup action")
	popup.queue_free()
	await popup.tree_exited


func _check_scaled_capacity_text() -> void:
	var settings := root.get_node("SettingsManager")
	var original_percent := int(settings.applied.get("ui_scale_percent", 100))
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)
	var surface = RunSurfaceScript.new()
	canvas.add_child(surface)
	surface.build()
	for factor in [1.0, 1.25, 1.5]:
		settings.begin_transaction()
		_check(settings.set_draft_value(&"ui_scale_percent", int(round(factor * 100))), "Scale transaction rejected valid percentage")
		_check(settings.apply_draft(), "Scale transaction failed to apply")
		var profile := UILayoutProfileScript.profile_for_resolution(&"1280x720")
		profile["ui_scale_factor"] = factor
		surface.set_ui_scale_factor(factor)
		surface.apply_layout_profile(profile)
		for dimensions in [Vector2i(5, 5), Vector2i(7, 7), Vector2i(10, 10), Vector2i(13, 13), Vector2i(13, 7), Vector2i(7, 13)]:
			for count in [0, 4]:
				var model := _surface_model(profile, _sample_items(count), 5, 100)
				model["map_dimensions"] = dimensions
				surface.apply_surface_model(model)
				var minimap_model := MiniMapViewModel.new()
				minimap_model.width = dimensions.x
				minimap_model.height = dimensions.y
				surface.minimap_panel.apply_view_model(minimap_model)
				await process_frame
				await process_frame
				var capacity := surface.backpack_capacity_label as Label
				var detail := surface.backpack_detail_label as Label
				var detail_text_height := detail.get_line_height() * mini(3, detail.get_line_count()) + detail.get_theme_constant("line_spacing") * mini(2, maxi(0, detail.get_line_count() - 1))
				_check(detail.size.y >= detail_text_height + detail.get_theme_stylebox("normal").get_minimum_size().y, "Backpack detail text exceeds its allocation at UI scale %s" % factor)
				_check(detail.get_global_rect().end.y + 4.0 <= capacity.get_global_rect().position.y, "Backpack detail overlaps the capacity line")
				_check(surface.left_rail_art.get_global_rect().end.x <= 270.0, "Permanent left rail exceeds the compact 1280px budget at scale %s" % factor)
				_check(surface.minimap_panel.size.y <= 200.0, "Permanent scanner exceeds its 720p height budget")
				_check(is_equal_approx(surface.ui_scale_factor, factor), "Capacity probe did not use requested scale")
				_check(capacity.size.y >= capacity.get_line_height(), "HUD capacity line is clipped at scale %s: height=%s line=%s" % [factor, capacity.size.y, capacity.get_line_height()])
				_check(capacity.get_global_rect().end.y <= 708.0, "Actual-size map pushed capacity off screen")
				_check(surface.minimap_panel.get_global_rect().end.y < surface.resource_backdrop.get_global_rect().position.y, "Actual-size map overlaps the resource band")
				var grid := surface.minimap_panel.get_node("Grid") as GridContainer
				_check(Rect2(Vector2.ZERO, surface.minimap_panel.size).encloses(grid.get_rect()), "Actual-size map escapes the left rail at UI scale %s" % factor)
				_check(grid.get_child_count() == dimensions.x * dimensions.y, "HUD cropped the actual map at UI scale %s" % factor)
				if count == 4:
					_check(surface.backpack_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "Scaled map made backpack overflow inaccessible")
	var high_profile := UILayoutProfileScript.profile_for_resolution(&"2560x1440")
	high_profile["ui_scale_factor"] = 1.5
	surface.apply_layout_profile(high_profile)
	surface.apply_surface_model(_surface_model(high_profile, [], 5, 100))
	await process_frame
	_check(surface.scanner_title_label.size.y >= surface.scanner_title_label.get_line_height(), "High-resolution overview title is clipped at 150 percent")
	settings.set_draft_value(&"ui_scale_percent", original_percent)
	settings.apply_draft()
	settings.close_transaction()
	canvas.queue_free()
	await canvas.tree_exited


func _check_minimap_texture_bounds() -> void:
	var minimap = MiniMapScene.instantiate()
	root.add_child(minimap)
	minimap.size = Vector2(248, 200)
	var model := MiniMapViewModel.new()
	model.width = 7
	model.height = 7
	model.set_room_markers([{"pos": Vector2i(3, 3), "is_current": true, "known_state": &"explored", "adjacent_mines": 2}])
	minimap.apply_view_model(model)
	await process_frame
	await process_frame
	for cell in minimap.get_node("Grid").get_children():
		var base := cell.get_node("CellBase") as TextureRect
		var intended := Rect2((cell.get_meta("map_cell_layer_layout") as Dictionary)["base_rect"])
		_check(base.get_rect().is_equal_approx(intended), "Minimap texture retained its native minimum size: %s expected=%s" % [base.get_rect(), intended])
		_check(Rect2(Vector2.ZERO, cell.size).encloses(base.get_rect()), "Minimap cell clips its base texture")
		var semantic := cell.get_node_or_null("SemanticMarker") as TextureRect
		if semantic != null:
			var semantic_rect := Rect2((cell.get_meta("map_cell_layer_layout") as Dictionary)["semantic_rect"])
			_check(semantic.get_rect().is_equal_approx(semantic_rect), "Minimap semantic marker retained its native minimum size")
	_check(minimap.get_node("Grid/MiniMapCell_3_3/SemanticMarker") != null, "Minimap bound check lacks a public player marker")
	minimap.queue_free()
	await minimap.tree_exited


func _check_readable_compact_minimap() -> void:
	for edge in [7, 10]:
		var minimap = MiniMapScene.instantiate()
		root.add_child(minimap)
		minimap.size = Vector2(212, 200)
		var model := MiniMapViewModel.new()
		model.width = edge
		model.height = edge
		model.set_room_markers([
			{"pos": Vector2i(3, 3), "is_current": true, "known_state": &"explored", "adjacent_mines": 2},
			{"pos": Vector2i(2, 3), "room_type": &"Normal", "known_state": &"explored", "adjacent_mines": 2},
		])
		minimap.apply_view_model(model)
		await process_frame
		await process_frame
		var grid := minimap.get_node("Grid") as GridContainer
		_check(grid.get_child_count() == edge * edge, "Readable minimap lost complete map dimensions")
		var first := grid.get_child(0) as Control
		var second := grid.get_child(1) as Control
		_check(is_equal_approx(first.get_rect().end.x, second.position.x), "Compact minimap cells still have an empty gutter")
		_check(first.get_node("CellBase").get_rect().is_equal_approx(Rect2(Vector2.ZERO, first.size)), "Compact minimap base still wastes cell area on fixed insets")
		var current := grid.get_node("MiniMapCell_3_3") as Control
		var icon := current.get_node("SemanticMarker") as TextureRect
		_check(icon.size.x >= current.size.x - 2.0 and icon.size.y >= current.size.y - 2.0, "Compact minimap icon is reduced to a tiny central patch")
		var count := grid.get_node("MiniMapCell_2_3").get_node_or_null("AdjacentMineCount") as Label
		_check(count != null and count.text == "2", "Plain known minimap room hides its public risk number")
		if count != null:
			_check(count.size.y >= count.get_line_height(), "Compact public risk number is vertically clipped")
		minimap.queue_free()
		await minimap.tree_exited


func _check_compact_corner_counts() -> void:
	for edge in [7, 10]:
		var panel = MiniMapScene.instantiate()
		root.add_child(panel)
		panel.size = Vector2(212, 200)
		var model := MiniMapViewModel.new()
		model.width = edge
		model.height = edge
		var types := [&"Normal", &"Chest", &"Monster", &"Mine", &"Event", &"Exit", &"Normal", &"Unknown", &"Normal"]
		var markers: Array[Dictionary] = []
		for value in range(9):
			markers.append({"pos": Vector2i(value % 5 + 1, value / 5 + 1), "room_type": types[value], "known_state": &"scanned" if value == 7 else &"explored", "is_current": value == 0, "flagged": value == 8, "adjacent_mines": value})
		model.set_room_markers(markers)
		panel.apply_view_model(model)
		await process_frame
		await process_frame
		for marker in markers:
			var cell: Control = panel.get_node("Grid/MiniMapCell_%d_%d" % [marker.pos.x, marker.pos.y])
			var count := cell.get_node_or_null("AdjacentMineCount") as Label
			_check(count != null and count.text == str(marker.adjacent_mines), "Compact minimap lost public count on %s" % marker.room_type)
			if count != null:
				_check(count.get_rect().end.is_equal_approx(cell.size), "Public count is not anchored at the cell bottom-right")
				_check(count.z_index > 20, "Public count does not float above room content")
				_check(count.size.y >= count.get_line_height(), "Corner count clips its digit")
		panel.queue_free()
		await panel.tree_exited


func _check_player_contact_shadow() -> void:
	var player = PlayerScene.instantiate()
	root.add_child(player)
	var sprite := player.get_node_or_null("Sprite") as Sprite2D
	var shadow := player.get_node_or_null("GroundShadow") as Sprite2D
	_check(shadow != null and shadow.texture != null, "Player lacks a textured contact shadow")
	if shadow != null and shadow.texture != null and sprite != null:
		var foot_y := sprite.position.y + sprite.get_rect().end.y * sprite.scale.y
		_check(absf(foot_y) <= 5.0 and shadow.position.length() <= 1.0, "Player feet and contact shadow are not grounded at the collision origin")
		_check(absf(shadow.position.y - foot_y) <= 5.0, "Contact shadow is detached from the authored feet")
		_check(shadow.z_index < sprite.z_index, "Contact shadow draws over the actor")
		var width := shadow.texture.get_width() * shadow.scale.x
		_check(width >= 24.0 and width <= sprite.texture.get_width() * sprite.scale.x, "Contact shadow exceeds the actor silhouette")
		var original_obstacles: Array = player.logical_obstacles.duplicate()
		var offset := shadow.position
		player.set_local_position(Vector2(0.25, 0.75))
		_check(shadow.global_position.is_equal_approx(player.global_position + offset), "Contact shadow did not follow the real player position")
		_check(player.logical_obstacles == original_obstacles, "Contact shadow changed collision authority")
		player.call("_apply_visual")
		_check(player.get_node("GroundShadow") == shadow, "Refreshing appearance duplicated the contact shadow")
	player.queue_free()
	await player.tree_exited


func _check_ground_depth_and_floor_reachability() -> void:
	var scene := Node2D.new()
	var room_layer := Node2D.new()
	room_layer.name = "RoomLayer"
	scene.add_child(room_layer)
	var player_layer := Node2D.new()
	player_layer.name = "PlayerLayer"
	scene.add_child(player_layer)
	var view = RoomRuntimeViewScript.new()
	room_layer.add_child(view)
	var player = PlayerScene.instantiate()
	player.name = "PlayerController"
	player_layer.add_child(player)
	root.add_child(scene)
	view.configure_room(_room_snapshot(&"Chest", Vector2i.ZERO))
	view.call("_update_visual_depths", Vector2(0.50, 0.43))
	_check(player.z_index < view.chest.z_index, "Player behind the chest draws over its lid")
	view.call("_update_visual_depths", Vector2(0.50, 0.635))
	_check(player.z_index > view.chest.z_index, "Chest cuts through the player standing in front")
	var rear_actor := Node2D.new()
	var front_actor := Node2D.new()
	view.add_child(rear_actor)
	view.add_child(front_actor)
	view.call("_apply_actor_depth", rear_actor, Vector2(0.50, 0.43))
	view.call("_apply_actor_depth", front_actor, Vector2(0.50, 0.70))
	_check(rear_actor.z_index < player.z_index and front_actor.z_index > player.z_index, "Nearby actors do not share the player's foot-depth order")
	view.configure_room(_room_snapshot(&"Normal", Vector2i.ZERO))
	player.set_logical_obstacles(view.get_logical_obstacles())
	player.set_door_projections(view.get_door_projections())
	for entry_direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var landing: Vector2 = player.place_from_entry(entry_direction)
		_check(WorldObjectProjectionScript.room_floor_interior().grow(-player.PLAYER_RADIUS).has_point(landing), "Door entry did not clear the wall thickness for lateral movement")
		_check(not player.call("_position_hits_obstacle", landing), "Door entry landed inside a solid body")
	for blocked in [Vector2(0.30, 0.10), Vector2(0.10, 0.30), Vector2(0.18, 0.23)]:
		_check(player.call("_position_hits_obstacle", blocked), "Visible wall or corner prop has no body at %s" % blocked)
	for floor_point in [Vector2(0.30, 0.32), Vector2(0.50, 0.50), Vector2(0.65, 0.72), Vector2(0.43, 0.10), Vector2(0.57, 0.10), Vector2(0.10, 0.43), Vector2(0.10, 0.57)]:
		_check(not player.call("_position_hits_obstacle", floor_point), "Clear floor or door lane is blocked at %s" % floor_point)
	player.set_local_position(Vector2(0.35, 0.72))
	for index in range(25):
		player.move_local(Vector2.RIGHT, 1.0 / 60.0)
	_check(player.get_local_position().x > 0.60, "Held movement could not cross clear interior floor")
	player.local_velocity = Vector2.ZERO
	player.set_local_position(Vector2(0.30, 0.50))
	for index in range(60):
		player.move_local(Vector2.UP, 1.0 / 60.0)
	_check(player.get_local_position().y >= 0.20, "Player walked through the visible north wall")
	view.configure_room(_room_snapshot(&"Event", Vector2i.ZERO))
	player.set_logical_obstacles(view.get_logical_obstacles())
	_check(player.call("_position_hits_obstacle", Vector2(0.50, 0.535)), "Event table remains walkable while its detached badge blocks floor")
	_check(not player.call("_position_hits_obstacle", Vector2(0.50, 0.70)), "Event table blocks the clear floor in front")
	scene.queue_free()
	await scene.tree_exited


func _check_clear_world_loot_placement() -> void:
	for room_type in [&"Normal", &"Monster", &"Event", &"Mine", &"Exit"]:
		var snapshot := _room_snapshot(room_type, Vector2i.ZERO)
		var items: Array[Dictionary] = []
		for index in range(48):
			items.append({"instance_id": "floor_clearance_%d" % index, "item_id": "tool_blade", "display_name": "测试物资"})
		snapshot["room_floor_items"] = items
		var projection := WorldObjectProjectionScript.build(snapshot)
		var floor_count := 0
		var positions: Dictionary = {}
		for object in projection["world_objects"]:
			if object["interaction_kind"] != &"ground_loot":
				continue
			floor_count += 1
			var point: Vector2 = object["local_pos"]
			positions[point] = true
			for solid in WorldObjectProjectionScript.room_solid_rects(room_type):
				_check(not solid.grow(G41RuntimeLayout.PLAYER_BODY_RADIUS).has_point(point), "%s loot is on furniture or unreachable floor: %s" % [room_type, point])
		_check(floor_count == items.size(), "%s geometry adjustment lost ledger instances" % room_type)
		_check(positions.size() == 12, "%s geometry adjustment collapsed the existing twelve floor slots" % room_type)


func _check_debug_chest_spawn() -> void:
	var manager := root.get_node("SettingsManager")
	var original_resolution: String = str(manager.applied.get("resolution_id", "auto"))
	manager.begin_transaction()
	manager.set_draft_value(&"resolution_id", "1280x720")
	manager.apply_draft()
	manager.confirm_pending_changes()
	manager.close_transaction()
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	# Let the freshly attached scene finish its deferred anchor layout before
	# dispatching a route from this same frame's component-test teardown.
	await process_frame
	var run_scene := main.get_node("RunScene")
	await _wait_until(func() -> bool: return run_scene.get("result_panel").is_node_ready(), "main scene controls ready")
	run_scene.call("_show_settings_shell")
	var settings = run_scene.get("ui_shell").get("settings_panel")
	settings.get("test_room_button").pressed.emit()
	if not await _wait_until(func() -> bool: return run_scene.get("screen_state") == &"run", "original sandbox entry"):
		run_scene.get("in_run_runtime").bind(null)
		run_scene.get("command_bus").bind_runtime_controller(null)
		main.queue_free()
		await main.tree_exited
		return
	run_scene.get("debug_panel_controller").call("teleport_to_room_type", &"Chest")
	var view = run_scene.get("room_runtime_view")
	await _wait_until(func() -> bool: return view.get("room_type") == &"Chest", "original debug Chest teleport")
	var player = run_scene.get("player_controller")
	var map_player_position: Vector2 = player.get_local_position()
	run_scene.call("_open_map_from_ui", &"keyboard")
	var overlay = run_scene.get("map_overlay_panel")
	await _wait_until(func() -> bool: return root.gui_get_focus_owner() is Button and overlay.is_ancestor_of(root.gui_get_focus_owner()), "map initial cell focus")
	var map_start: Vector2i = overlay.selected_marker.get("pos", Vector2i.ZERO)
	for step in [{"key": KEY_LEFT, "offset": Vector2i.LEFT}, {"key": KEY_RIGHT, "offset": Vector2i.ZERO}, {"key": KEY_DOWN, "offset": Vector2i.DOWN}, {"key": KEY_UP, "offset": Vector2i.ZERO}]:
		await _tap_map_key(step.key)
		var expected: Vector2i = map_start + Vector2i(step.offset)
		var expected_cell := overlay.get_node("Panel/Content/Grid/MapCell_%d_%d" % [expected.x, expected.y]) as Button
		_check(root.gui_get_focus_owner() == expected_cell, "Map direction key escaped the adjacent cell onto the overlay root")
		_check(overlay.visible and expected_cell.is_visible_in_tree(), "Map vanished during keyboard navigation")
	for key in [KEY_LEFT, KEY_UP, KEY_RIGHT, KEY_DOWN]:
		for index in range(8):
			await _tap_map_key(key)
			var focus := root.gui_get_focus_owner()
			_check(focus != null and overlay.is_ancestor_of(focus), "Map edge navigation escaped to the background HUD")
			_check(overlay.visible and overlay.get_node("Panel/Content/Grid").get_child_count() == 49, "Map content disappeared at a directional edge")
			var selected_outlines := 0
			for cell in overlay.get_node("Panel/Content/Grid").get_children():
				if cell.get_node("FocusSelectionOutline").visible:
					selected_outlines += 1
			_check(selected_outlines == 1, "Map navigation left stale selection outlines on previous cells")
	await _tap_map_key(KEY_LEFT)
	var flag_target: Vector2i = overlay.selected_marker.pos
	var original_flags := _map_flag_positions(overlay)
	var expected_flags := original_flags.duplicate()
	expected_flags.append(str(flag_target))
	expected_flags.sort()
	await _tap_map_key(KEY_ENTER)
	await _wait_until(func() -> bool: return _map_flag_positions(overlay) == expected_flags, "keyboard flag changes only the selected cell")
	await _tap_map_key(KEY_ENTER)
	await _wait_until(func() -> bool: return _map_flag_positions(overlay) == original_flags, "keyboard flag cancellation restores only the selected cell")
	_check(player.get_local_position().is_equal_approx(map_player_position) and not player.input_enabled, "Map navigation moved the character or left gameplay input enabled")
	await _tap_map_key(KEY_ESCAPE)
	for close_key in [{"key": KEY_TAB, "shift": false}, {"key": KEY_TAB, "shift": true}, {"key": KEY_ESCAPE, "shift": false}]:
		await _tap_map_key(KEY_M)
		await _wait_until(func() -> bool: return overlay.visible and not player.input_enabled, "keyboard map reopen blocks movement")
		await _tap_map_key(close_key.key, close_key.shift)
		await _wait_until(func() -> bool: return not overlay.visible and player.input_enabled, "existing map close shortcut restores gameplay input")
	var move_input := InputEventKey.new()
	move_input.keycode = KEY_D
	move_input.physical_keycode = KEY_D
	move_input.pressed = true
	Input.parse_input_event(move_input)
	await _wait_until(func() -> bool: return player.get_local_position().x > map_player_position.x + 0.02, "held movement resumes after closing the map")
	move_input.pressed = false
	Input.parse_input_event(move_input)
	var before: Vector2 = player.get_local_position()
	var banner := main.find_child("DebugSandboxBanner", true, false) as Label
	var room_bounds: Rect2 = view.get_global_transform_with_canvas() * G41RuntimeLayout.ROOM_RECT
	_check(banner != null and not banner.get_global_rect().intersects(room_bounds), "Sandbox status banner covers the traversable room and player")
	_check(not banner.text.contains("commit=") and not banner.text.contains("save=") and banner.text.split("\n").size() <= 2, "Sandbox banner repeats detailed diagnostic identity")
	var identity := main.find_child("DebugSessionIdentity", true, false) as Label
	_check(identity != null and identity.text.contains("commit=") and identity.text.contains("profile=") and identity.text.contains("scenario=") and identity.text.contains("seed=") and identity.text.contains("save="), "Diagnostic panel lost the sandbox identity fields")
	_check(identity != null and not identity.is_visible_in_tree(), "Detailed sandbox identity is visible outside diagnostics")
	run_scene.get("debug_panel_controller").open_panel()
	_check(identity != null and identity.is_visible_in_tree(), "Existing diagnostic panel cannot reveal the full sandbox identity")
	_check(not banner.is_visible_in_tree(), "Redundant sandbox marker covers the open diagnostic panel header")
	run_scene.get("debug_panel_controller").close_panel()
	_check(banner.is_visible_in_tree(), "Closing diagnostics did not restore the sandbox marker")
	await _wait_until(func() -> bool: return view.context_popup.visible and banner.size.y <= 300.0, "sandbox banner and Chest context layout")
	_check(Rect2(Vector2.ZERO, root.size).encloses(banner.get_global_rect()), "Sandbox banner extends beyond the visible viewport")
	_check(not banner.get_global_rect().intersects(view.context_popup.get_global_rect()), "Chest action card covers the sandbox identity")
	var original_scale := int(manager.applied.get("ui_scale_percent", 100))
	var protocol_card := main.find_child("Art21RunStatusCard", true, false) as Control
	for scale_percent in [125, 150, 100]:
		manager.begin_transaction()
		manager.set_draft_value(&"ui_scale_percent", scale_percent)
		manager.apply_draft()
		await _wait_until(func() -> bool:
			return (
				banner.get_global_rect().position.y >= protocol_card.get_global_rect().end.y + 11.0
				and not banner.get_global_rect().intersects(view.get_global_transform() * G41RuntimeLayout.ROOM_RECT)
			)
		, "sandbox banner follows room and protocol scale")
		_check(not banner.get_global_rect().intersects(protocol_card.get_global_rect()), "Sandbox banner overlaps the scaled protocol card")
		_check(not protocol_card.get_global_rect().intersects(view.get_global_transform() * G41RuntimeLayout.ROOM_RECT), "Protocol card covers the playable room at %d%%" % scale_percent)
		_check(not banner.get_global_rect().intersects(view.get_global_transform() * G41RuntimeLayout.ROOM_RECT), "UI scaling moved the banner into the room")
	manager.begin_transaction()
	manager.set_draft_value(&"ui_scale_percent", original_scale)
	manager.apply_draft()
	_check(not player.call("_position_hits_obstacle", map_player_position), "Debug Chest teleport placed the player inside a solid body")
	_check(view.chest.can_interact_from(map_player_position), "Debug Chest inspection spawn is outside interaction reach")
	for index in range(20):
		player.move_local(Vector2.RIGHT, 1.0 / 60.0)
	_check(player.get_local_position().x - before.x > 0.10, "Debug Chest spawn remains stuck under held movement")
	run_scene.get("in_run_runtime").bind(null)
	run_scene.get("command_bus").bind_runtime_controller(null)
	var main_instance_id := main.get_instance_id()
	main.queue_free()
	await main.tree_exited
	await _wait_until(func() -> bool: return not is_instance_id_valid(main_instance_id), "main scene released before restoring settings")
	manager.begin_transaction()
	manager.set_draft_value(&"resolution_id", original_resolution)
	manager.apply_draft()
	manager.confirm_pending_changes()
	manager.close_transaction()


func _tap_map_key(key: int, shift: bool = false) -> void:
	var input := InputEventKey.new()
	input.keycode = key
	input.physical_keycode = key
	input.shift_pressed = shift
	input.pressed = true
	Input.parse_input_event(input)
	await process_frame
	input.pressed = false
	Input.parse_input_event(input)
	await process_frame


func _map_flag_positions(overlay: Control) -> Array[String]:
	var result: Array[String] = []
	for marker in overlay.get("view_model").room_markers:
		if bool(marker.get("flagged", false)):
			result.append(str(marker.pos))
	result.sort()
	return result


func _check_rarity_palette_and_item_resolver() -> void:
	for rarity_key in EXPECTED_RARITY_COLORS:
		var actual := Color(ItemRarityDescriptorScript.describe(rarity_key).get("color", Color.TRANSPARENT))
		var expected := Color(EXPECTED_RARITY_COLORS[rarity_key])
		_check(_color_within_channel_tolerance(actual, expected), "Rarity palette drifted for %s" % String(rarity_key))
	for raw_item in ItemCatalogScript.all_items():
		var item := (raw_item as Dictionary).duplicate(true)
		var world_resolution := ItemVisualCatalogScript.resolve(item, &"world_ground_drop")
		var backpack_resolution := ItemVisualCatalogScript.resolve(item, &"run_backpack")
		for field in [
			"requested_key",
			"requested_path",
			"resolved_key",
			"resolved_path",
			"resolved_size",
			"explicit_mapping",
			"fallback_used",
			"reason",
			"consumer",
		]:
			_check(world_resolution.has(field), "Item resolver omitted %s for %s" % [field, item.get("item_id", "")])
		_check(bool(world_resolution.get("resolved", false)), "Formal item texture did not resolve for %s" % item.get("item_id", ""))
		_check(
			world_resolution.get("resolved_key") == backpack_resolution.get("resolved_key")
			and world_resolution.get("resolved_path") == backpack_resolution.get("resolved_path"),
			"Item consumers resolved different art for %s" % item.get("item_id", "")
		)
	var explicit_world := ItemVisualCatalogScript.resolve({
		"item_id": "anomaly_shard",
		"item_type": "special",
	}, &"probe")
	_check(bool(explicit_world.get("explicit_mapping", false)), "ART24 anomaly_shard is not treated as an explicit mapping")
	_check(
		String(explicit_world.get("resolved_key", "")).ends_with(".anomaly_shard"),
		"ART24 anomaly_shard fell back to a generic type texture"
	)
	var unknown := ItemVisualCatalogScript.resolve({
		"item_id": "i4_unknown_fixture",
		"item_type": "consumable",
	}, &"probe")
	_check(
		bool(unknown.get("fallback_used", false))
		and String(unknown.get("resolved_key", "")).ends_with(".emergency_bandage")
		and bool(unknown.get("resolved", false)),
		"Unknown consumable did not receive the visible typed fallback"
	)


func _check_map_cell_layer_contract() -> void:
	for cell_size in [Vector2(36, 36), Vector2(42, 42), Vector2(56, 48)]:
		var layout := MapCellLayerLayoutScript.calculate(cell_size, true)
		var cell_rect := Rect2(layout.get("cell_rect", Rect2()))
		var semantic_rect := Rect2(layout.get("semantic_rect", Rect2()))
		var count_rect := Rect2(layout.get("count_rect", Rect2()))
		var focus_rect := Rect2(layout.get("focus_rect", Rect2()))
		_check(
			int(layout.get("base_z", -1)) == 0
			and int(layout.get("semantic_z", -1)) == 20
			and int(layout.get("count_z", -1)) == 30
			and int(layout.get("focus_z", -1)) == 40,
			"Map-cell z order drifted at %s" % cell_size
		)
		_check(
			cell_rect.encloses(semantic_rect)
			and cell_rect.encloses(count_rect)
			and cell_rect.encloses(focus_rect),
			"Map-cell child allocation spills beyond %s" % cell_size
		)
		var overlap := semantic_rect.intersection(count_rect)
		_check(overlap.size.x * overlap.size.y == 0.0, "Map semantic/count allocations overlap at %s" % cell_size)
		_check(
			count_rect.size.x >= 12.0
			and count_rect.size.x <= 18.0
			and is_equal_approx(count_rect.size.x, count_rect.size.y),
			"Map count badge is outside the 12..18 px square rule at %s" % cell_size
		)


func _check_texture_fallback_and_world_drop() -> void:
	var interactable = InteractableScript.new()
	root.add_child(interactable)
	interactable.configure_interactable({
		"projection_id": "i4-null-texture",
		"interaction_kind": &"fixture",
		"body_rect": Rect2(0.45, 0.45, 0.10, 0.10),
		"visual_rect_local": Rect2(0.45, 0.45, 0.10, 0.10),
	})
	var null_sprite := Sprite2D.new()
	null_sprite.name = "ArtVisual"
	interactable.get_node("VisualRoot").add_child(null_sprite)
	interactable.call("_apply_visual_state")
	var placeholder := interactable.get_node("VisualRoot/ProgramPlaceholder") as Polygon2D
	_check(placeholder.visible, "A present ArtVisual node with texture=null hid the program fallback")
	_check(interactable.has_visible_collision_correspondence(), "Null-texture interactable has no visible collision fallback")
	interactable.queue_free()

	var item := {
		"instance_id": "i4-ground-drop",
		"item_id": "anomaly_shard",
		"item_type": "special",
		"display_name": "异常核心碎片",
		"rarity": &"tier_4",
		"weight": 1,
	}
	var snapshot := _room_snapshot(&"Normal", Vector2i(1, 1))
	snapshot["room_floor_items"] = [item]
	var projection := (WorldObjectProjectionScript.build(snapshot).get("world_objects", []) as Array)[0] as Dictionary
	var entity = GroundLootEntityScript.new()
	root.add_child(entity)
	entity.configure_item(projection)
	await _wait_until(
		func() -> bool:
			var candidate_art := entity.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
			var candidate_beam := entity.get_node_or_null("VisualRoot/PickupBeam") as Sprite2D
			return (
				candidate_art != null
				and candidate_art.texture != null
				and candidate_art.visible
				and candidate_beam != null
				and candidate_beam.visible
			),
		"ground-drop body and rarity beam"
	)
	var art := entity.get_node("VisualRoot/ArtVisual") as Sprite2D
	var beam := entity.get_node("VisualRoot/PickupBeam") as Sprite2D
	var rarity_color := Color(ItemRarityDescriptorScript.describe_item(item).get("color", Color.TRANSPARENT))
	_check(art.texture != null and art.visible, "Ground drop rendered without an item body texture")
	_check(
		_is_same_rgb(beam.modulate, rarity_color),
		"Ground-drop beam does not use the shared item rarity color"
	)
	entity.set_pickup_result(false)
	var blocked_marker := entity.get_node("VisualRoot/BlockedMarker") as Label
	_check(blocked_marker.visible and _is_same_rgb(beam.modulate, rarity_color), "Blocked feedback overwrote the ground-drop rarity channel")
	entity.queue_free()
	await entity.tree_exited


func _check_collision_visible_correspondence() -> void:
	var view = RoomRuntimeViewScript.new()
	root.add_child(view)
	for room_case in [
		{"type": &"Normal", "position": Vector2i(0, 0), "expected": 12},
		{"type": &"Monster", "position": Vector2i(1, 0), "expected": 9},
		{"type": &"Event", "position": Vector2i(2, 0), "expected": 9},
		{"type": &"Chest", "position": Vector2i(3, 0), "expected": 13},
	]:
		var snapshot := _room_snapshot(room_case["type"], room_case["position"])
		if room_case["type"] == &"Event":
			snapshot["event_state"] = {"event_type": &"altar", "completed": false}
		if room_case["type"] == &"Chest":
			snapshot["search_state_data"] = {"searched": false}
		var room_position := Vector2i(room_case["position"])
		var expected_room_key := "%d,%d" % [room_position.x, room_position.y]
		view.configure_room(snapshot)
		await _wait_until(
			func() -> bool:
				return (
					String(view.get("room_key")) == expected_room_key
					and view.get_obstacle_descriptors().size() == int(room_case["expected"])
				),
			"%s room obstacle projection commit" % String(room_case["type"])
		)
		var descriptors := view.get_obstacle_descriptors()
		_check(
			descriptors.size() == int(room_case["expected"]),
			"%s room projected %d collision descriptors; expected %d" % [
				String(room_case["type"]),
				descriptors.size(),
				int(room_case["expected"]),
			]
		)
		_check(
			view.get_logical_obstacles().size() == int(room_case["expected"]),
			"%s room retained an anonymous or disabled collision" % String(room_case["type"])
		)
		for descriptor in descriptors:
			for field in [
				"obstacle_id",
				"source_projection_id",
				"source_kind",
				"room_type",
				"body_rect",
				"visual_key",
				"resolved_texture_path",
				"resolved_texture_size",
				"visual_footprint",
				"visual_node_path",
				"visible_alpha",
				"body_center_inside_visual",
				"visual_body_coverage_ratio",
				"collision_enabled",
				"disable_reason",
			]:
				_check(descriptor.has(field), "%s collision descriptor omitted %s" % [room_case["type"], field])
			_check(bool(descriptor.get("collision_enabled", false)), "%s collision lacks visible correspondence" % room_case["type"])
			_check(float(descriptor.get("visible_alpha", 0.0)) >= 0.25, "%s collision visual alpha is below 0.25" % room_case["type"])
			_check(bool(descriptor.get("body_center_inside_visual", false)), "%s collision center is outside its visual" % room_case["type"])
			_check(float(descriptor.get("visual_body_coverage_ratio", 0.0)) >= 0.90, "%s collision coverage is below 0.90" % room_case["type"])
	view.queue_free()
	await view.tree_exited


func _check_protocol_and_left_density() -> void:
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)
	var surface = RunSurfaceScript.new()
	canvas.add_child(surface)
	surface.build()
	var profile := UILayoutProfileScript.profile_for_resolution(&"1280x720")
	surface.apply_layout_profile(profile)
	for count in [0, 1, 4]:
		surface.apply_surface_model(_surface_model(profile, _sample_items(count), 5, 100))
		await _wait_until(
			func() -> bool:
				var layout := surface.scanner_text_mask.get_meta("content_layout_rects", {}) as Dictionary
				return (
					int(surface.scanner_text_mask.get_meta("content_item_count", -1)) == count
					and layout.has("panel")
					and layout.has("header")
					and layout.has("list")
					and layout.has("detail")
					and layout.has("capacity")
				),
			"backpack content-driven layout for %d items" % count
		)
		var geometry := surface.scanner_text_mask.get_meta("content_layout_rects", {}) as Dictionary
		var panel := Rect2(geometry.get("panel", Rect2()))
		var header := Rect2(geometry.get("header", Rect2()))
		var list := Rect2(geometry.get("list", Rect2()))
		var detail := Rect2(geometry.get("detail", Rect2()))
		var capacity := Rect2(geometry.get("capacity", Rect2()))
		var rail: Rect2 = surface.left_rail_art.get_rect()
		_check(header.size.y >= 24.0 and header.size.y <= 34.0, "Backpack header height is outside its compact band")
		_check(detail.size.y >= 44.0 and detail.encloses(surface.backpack_detail_label.get_rect()), "Backpack detail allocation does not contain its actual text control")
		_check(capacity.size.y >= 24.0 and capacity.size.y <= 30.0, "Backpack capacity height is outside 24..30 px")
		_check(_vertical_gap(header, list) >= 4.0 and _vertical_gap(header, list) <= 8.0, "Backpack header/list gap is outside 4..8 px")
		_check(_vertical_gap(list, detail) >= 4.0 and _vertical_gap(list, detail) <= 8.0, "Backpack list/detail gap is outside 4..8 px")
		_check(_vertical_gap(detail, capacity) >= 4.0 and _vertical_gap(detail, capacity) <= 8.0, "Backpack detail/capacity gap is outside 4..8 px")
		_check(panel.end.y - capacity.end.y <= 16.0, "Backpack panel retains a semantic tail blank larger than 16 px")
		_check(
			rail.end.y - panel.end.y >= 0.0 and rail.end.y - panel.end.y <= 16.0,
			"Visible left rail retains a semantic tail blank larger than 16 px"
		)
		if count == 0:
			_check(not surface.backpack_scroll.visible, "Empty backpack retains a fixed empty scroll surface")
			_check(surface.backpack_empty_watermark.visible and list.size.y >= 44.0 and list.size.y <= 56.0, "Empty backpack lacks the compact 44..56 px state")
		elif count == 1:
			_check(surface.backpack_scroll.visible and list.size.y >= 44.0 and list.size.y <= 52.0, "One-item backpack did not fit one compact row")
			_check(surface.backpack_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "One-item backpack exposes unnecessary scrolling")
		else:
			_check(surface.backpack_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "Four-item backpack is not scrollable")
			_check(list.size.y >= 140.0 and list.size.y <= 164.0, "Four-item backpack does not expose three complete rows")
	var safe_rect := Rect2(surface.status_card_art.get_meta("protocol_safe_rect", Rect2()))
	for control in [surface.right_title_label, surface.right_body_label, surface.protocol_pressure_track]:
		var control_rect := (control as Control).get_global_rect()
		_check(
			_rect_encloses_with_tolerance(safe_rect, control_rect),
			"Protocol content escaped the measured safe rectangle: %s safe=%s actual=%s"
			% [(control as Control).name, safe_rect, control_rect]
		)
	var title_body_gap := _vertical_gap(surface.right_title_label.get_global_rect(), surface.right_body_label.get_global_rect())
	var body_track_gap := _vertical_gap(surface.right_body_label.get_global_rect(), surface.protocol_pressure_track.get_global_rect())
	_check(title_body_gap >= 3.5, "Protocol title/body gap is below 4 px (measured %.2f)" % title_body_gap)
	_check(
		body_track_gap >= 5.5,
		"Protocol body/track gap is below 6 px (measured %.2f, body=%s, track=%s)"
		% [
			body_track_gap,
			surface.right_body_label.get_global_rect(),
			surface.protocol_pressure_track.get_global_rect(),
		]
	)
	_check(
		surface.right_body_label.max_lines_visible == 1
		and surface.right_body_label.autowrap_mode == TextServer.AUTOWRAP_OFF
		and not surface.right_body_label.clip_text,
		"Protocol body is not a single unclipped line"
	)
	canvas.queue_free()
	await canvas.tree_exited


func _room_snapshot(room_type: StringName, position: Vector2i) -> Dictionary:
	return {
		"position": position,
		"player_pos": position,
		"width": 5,
		"height": 5,
		"current_room": room_type,
		"room_floor_items": [],
		"run_map_snapshot": {
			"KnownMap": {
				"width": 5,
				"height": 5,
				"player_pos": position,
				"public_cells": [],
			},
		},
		"run_start_config": {"move_requires_revealed": false},
	}


func _surface_model(
	profile: Dictionary,
	items: Array[Dictionary],
	protocol_level: int,
	pressure: int
) -> Dictionary:
	return {
		"layout_profile": profile,
		"backpack_items": items,
		"backpack_used": items.size(),
		"backpack_capacity": 12,
		"resource_summary": "生命 10/10 | 作业强度 3 | 待结算黑币 0 | 安全金币 0",
		"mine_risk": {"count": 0},
		"protocol_level": protocol_level,
		"protocol_title": "正常作业",
		"pressure": pressure,
		"status_lines": [],
		"action_buttons": [],
		"encounter_section": {},
	}


func _sample_items(count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(count):
		result.append({
			"instance_id": "i4-density-%d" % index,
			"item_id": "emergency_bandage",
			"item_type": "consumable",
			"display_name": "验证物资 %d" % (index + 1),
			"rarity": StringName("tier_%d" % ((index % 6) + 1)),
			"quantity": 1,
			"weight": 1,
		})
	return result


func _color_within_channel_tolerance(actual: Color, expected: Color) -> bool:
	var tolerance := 1.0 / 255.0 + 0.000001
	return (
		absf(actual.r - expected.r) <= tolerance
		and absf(actual.g - expected.g) <= tolerance
		and absf(actual.b - expected.b) <= tolerance
		and absf(actual.a - expected.a) <= tolerance
	)


func _is_same_rgb(first: Color, second: Color) -> bool:
	var tolerance := 1.0 / 255.0 + 0.000001
	return (
		absf(first.r - second.r) <= tolerance
		and absf(first.g - second.g) <= tolerance
		and absf(first.b - second.b) <= tolerance
	)


func _vertical_gap(upper: Rect2, lower: Rect2) -> float:
	return lower.position.y - upper.end.y


func _rect_encloses_with_tolerance(outer: Rect2, inner: Rect2) -> bool:
	return (
		inner.position.x >= outer.position.x - 0.5
		and inner.position.y >= outer.position.y - 0.5
		and inner.end.x <= outer.end.x + 0.5
		and inner.end.y <= outer.end.y + 0.5
	)


func _wait_until(predicate: Callable, label: String, timeout_ms: int = 5000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() <= deadline:
		if bool(predicate.call()):
			return true
		await process_frame
	failures.append("timed out waiting for semantic state: %s" % label)
	return false


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print(
			"I4_IN_RUN_VISUAL_PHYSICS=PASS"
			+ " palette=8 resolver=formal_same_path+typed_fallback"
			+ " map=base,semantic,count,focus"
			+ " collision=normal12,monster9,event9,chest13"
			+ " drops=body+rarity_beam+failure_marker"
			+ " hud=protocol_safe_rect+bag_0,1,4"
		)
		quit(0)
		return
	for failure in failures:
		push_error("I4 in-run visual/physics failure: " + failure)
	print("I4_IN_RUN_VISUAL_PHYSICS=FAIL failures=%d" % failures.size())
	quit(1)
