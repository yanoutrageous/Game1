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
	_finish()


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
		{"type": &"Normal", "position": Vector2i(0, 0), "expected": 0},
		{"type": &"Monster", "position": Vector2i(1, 0), "expected": 1},
		{"type": &"Event", "position": Vector2i(2, 0), "expected": 1},
		{"type": &"Chest", "position": Vector2i(3, 0), "expected": 1},
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
		_check(detail.size.y >= 44.0 and detail.size.y <= 56.0, "Backpack detail height is outside 44..56 px")
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
		_check(
			_rect_encloses_with_tolerance(safe_rect, (control as Control).get_global_rect()),
			"Protocol content escaped the measured safe rectangle: %s" % (control as Control).name
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
			+ " collision=normal0,monster1,event1,chest1"
			+ " drops=body+rarity_beam+failure_marker"
			+ " hud=protocol_safe_rect+bag_0,1,4"
		)
		quit(0)
		return
	for failure in failures:
		push_error("I4 in-run visual/physics failure: " + failure)
	print("I4_IN_RUN_VISUAL_PHYSICS=FAIL failures=%d" % failures.size())
	quit(1)
