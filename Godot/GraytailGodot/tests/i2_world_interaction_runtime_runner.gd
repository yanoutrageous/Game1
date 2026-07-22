extends SceneTree

const ProjectionScript := preload("res://scripts/gameplay/runtime/g41_world_object_projection.gd")
const RoomView := preload("res://scripts/gameplay/runtime/g41_room_runtime_view.gd")
const GroundLootEntity := preload("res://scripts/gameplay/loot/g41_ground_loot_entity.gd")
const AssetContract := preload("res://scripts/presentation/art24/art24_in_run_asset_contract.gd")
const ItemVisualCatalog := preload("res://scripts/presentation/art24/art24_item_visual_catalog.gd")
const ItemCatalog := preload("res://scripts/core/content/m3_item_catalog.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	_check_projection_contract()
	_check_item_visual_contract()
	await _check_projection_consumers_and_proximity()
	await _check_production_run_scene()
	_finish()


func _check_projection_contract() -> void:
	var chest_snapshot := _public_snapshot(&"Chest", Vector2i(1, 1), true)
	chest_snapshot["room_floor_items"] = [_item("chest-a"), _item("chest-b")]
	var chest_projection: Dictionary = ProjectionScript.build(chest_snapshot, {"door_locked": false})
	var chest_objects: Array = chest_projection.get("world_objects", [])
	_check(chest_objects.size() == 1, "Chest room must project exactly one world object")
	_check((chest_projection.get("chest_contents", []) as Array).size() == 2, "Chest ledger contents were not retained in the container projection")
	_check(_count_kind(chest_objects, &"ground_loot") == 0, "Chest ledger contents were duplicated as ground loot")
	if not chest_objects.is_empty():
		var chest: Dictionary = chest_objects[0]
		for field in ["projection_id", "interaction_kind", "local_pos", "interaction_radius", "body_rect", "context_anchor_local", "visual_state", "visual_key", "depth_key"]:
			_check(chest.has(field), "Unified chest projection omitted %s" % field)
		_check(StringName(chest.get("visual_state", &"")) == &"opened", "Searched Chest did not project the opened state")

	var normal_snapshot := _public_snapshot(&"Normal", Vector2i(1, 1), false)
	normal_snapshot["room_floor_items"] = [_item("floor-a"), _item("floor-b")]
	var normal_projection: Dictionary = ProjectionScript.build(normal_snapshot, {"door_locked": false})
	_check(_count_kind(normal_projection.get("world_objects", []), &"ground_loot") == 2, "Non-Chest room did not project ledger items one-to-one")
	_check((normal_projection.get("chest_contents", []) as Array).is_empty(), "Non-Chest room retained a phantom container ledger")

	var doors: Array = chest_projection.get("doors", [])
	_check(doors.size() == 4, "Door projection did not expose all four directions")
	_check(_door_state(doors, Vector2i.UP) == &"available", "Revealed north door was not available")
	_check(_door_state(doors, Vector2i.RIGHT) == &"blocked_flagged", "Flagged east door did not remain blocked")
	_check(_door_state(doors, Vector2i.DOWN) == &"blocked_hidden", "Hidden south door did not honor move_requires_revealed")
	_check(_door_state(doors, Vector2i.LEFT) == &"available", "Revealed west door was not available")
	var combat_doors: Array = ProjectionScript.build(chest_snapshot, {"door_locked": true, "active": false}).get("doors", [])
	_check(_door_state(combat_doors, Vector2i.UP) == &"combat_restricted", "Explicit combat door lock was not projected")
	var active_without_lock: Array = ProjectionScript.build(chest_snapshot, {"door_locked": false, "active": true}).get("doors", [])
	_check(_door_state(active_without_lock, Vector2i.UP) == &"available", "Door view inferred lock from combat.active instead of door_locked")
	var corner_snapshot := _public_snapshot(&"Normal", Vector2i.ZERO, false)
	var corner_doors: Array = ProjectionScript.build(corner_snapshot, {"door_locked": false}).get("doors", [])
	_check(_door_state(corner_doors, Vector2i.UP) == &"blocked_out_of_bounds", "North boundary did not project out-of-bounds")
	_check(_door_state(corner_doors, Vector2i.LEFT) == &"blocked_out_of_bounds", "West boundary did not project out-of-bounds")

	var projection_source := FileAccess.get_file_as_string("res://scripts/gameplay/runtime/g41_world_object_projection.gd")
	_check(not projection_source.contains("TruthMap"), "World projection references hidden TruthMap")
	_check(not projection_source.contains("dispatch("), "World projection dispatches a domain command")
	_check(not projection_source.contains("attempt_room_transition") and not projection_source.contains("request_flee"), "Door projection owns transition/flee authority")


func _check_item_visual_contract() -> void:
	var manifest_source := FileAccess.get_file_as_string("res://data/assets/asset_manifest.csv")
	var index := 0
	for raw_item in ItemCatalog.all_items():
		var item := raw_item.duplicate(true)
		item["instance_id"] = "visual-contract-%d" % index
		index += 1
		var snapshot := _public_snapshot(&"Normal", Vector2i(1, 1), false)
		snapshot["room_floor_items"] = [item]
		var objects: Array = ProjectionScript.build(snapshot).get("world_objects", [])
		_check(objects.size() == 1, "Formal item did not produce one ground projection: %s" % String(item.get("item_id", "")))
		if objects.is_empty():
			continue
		var projection := objects[0] as Dictionary
		var expected_key := ItemVisualCatalog.visual_key(item)
		var expected_path := ItemVisualCatalog.texture_path_for_visual_key(expected_key)
		_check(StringName(projection.get("visual_key", &"")) == expected_key, "Ground projection exposed a false visual key for %s" % String(item.get("item_id", "")))
		_check(ResourceLoader.exists(expected_path, "Texture2D"), "Ground visual path is not loadable: %s" % expected_path)
		_check(manifest_source.contains(String(expected_key)) and manifest_source.contains(expected_path), "Ground visual is not represented by the governed manifest: %s" % String(expected_key))
		var entity = GroundLootEntity.new()
		root.add_child(entity)
		entity.configure_item(projection)
		var sprite := entity.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
		_check(sprite != null and sprite.texture != null and sprite.texture.resource_path == expected_path, "Ground consumer ignored the projected visual key for %s" % String(item.get("item_id", "")))
		_check(entity.reveal_remaining > 0.0, "New ground entity skipped its reveal feedback for %s" % String(item.get("item_id", "")))
		entity.free()
	var ground_source := FileAccess.get_file_as_string("res://scripts/gameplay/loot/g41_ground_loot_entity.gd")
	_check(ground_source.contains("PICKUP_BEAM_TEXTURES"), "Ground feedback frames are not preloaded")
	_check(not ground_source.contains("beam.texture = load("), "Ground feedback still performs repeated runtime loads")


func _check_projection_consumers_and_proximity() -> void:
	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	root.add_child(overlay)
	var view = RoomView.new()
	root.add_child(view)
	view.attach_context_popup(overlay)
	var opened_snapshot := _public_snapshot(&"Chest", Vector2i(1, 1), true)
	opened_snapshot["room_floor_items"] = [_item("remaining-a"), _item("remaining-b")]
	view.configure_room(opened_snapshot)
	var unchanged_door_revision: int = int(view.door_projection_revision)
	for _sample in range(12):
		view.apply_combat_snapshot({"door_locked": false})
	_check(view.door_projection_revision == unchanged_door_revision, "Unchanged combat snapshots rebuilt door projections every frame")
	view.apply_combat_snapshot({"door_locked": true})
	_check(view.door_projection_revision == unchanged_door_revision + 1, "Changed door_locked state did not rebuild its projection once")
	view.apply_combat_snapshot({"door_locked": true})
	_check(view.door_projection_revision == unchanged_door_revision + 1, "Stable locked state rebuilt its projection again")
	view.apply_combat_snapshot({"door_locked": false})
	_check(view.door_projection_revision == unchanged_door_revision + 2, "Unlocked state did not rebuild its projection once")
	view.advance(0.0, ProjectionScript.CHEST_LOCAL_POS, {"door_locked": false})
	await _frames(2)
	_check(view.chest != null, "Projected Chest was not consumed by the runtime view")
	if view.chest != null:
		var descriptor: Dictionary = (view.world_projection.get("world_objects", []) as Array)[0]
		var consumed: Dictionary = view.chest.build_snapshot()
		for field in ["projection_id", "local_pos", "interaction_radius", "body_rect", "context_anchor_local", "visual_key", "depth_key"]:
			_check(consumed.get(field) == descriptor.get(field), "Chest consumer drifted from unified %s" % field)
		_check(view.get_logical_obstacles().has(descriptor.get("body_rect")), "Chest collision did not consume the unified body_rect")
	_check(view.ground_loot_entities.is_empty(), "Chest contents created duplicate ground entity nodes")
	_check(view.context_popup != null and view.context_popup.visible, "Opened Chest proximity did not automatically show contents")
	_check(view.context_popup.context_items.size() == 2, "Opened Chest proximity popup did not show exact remaining contents")
	view.advance(0.04, Vector2(0.05, 0.05), {"door_locked": false})
	_check(view.context_popup.visible, "Chest popup ignored the short lost-focus grace window")
	view.advance(0.08, Vector2(0.05, 0.05), {"door_locked": false})
	_check(not view.context_popup.visible, "Leaving Chest proximity did not hide the popup after the grace window")
	view.advance(0.0, ProjectionScript.CHEST_LOCAL_POS, {"door_locked": false})
	_check(view.context_popup.visible and view.context_popup.context_items.size() == 2, "Re-entering Chest proximity did not restore remaining contents")
	var empty_snapshot := opened_snapshot.duplicate(true)
	empty_snapshot["room_floor_items"] = []
	view.configure_room(empty_snapshot)
	view.advance(0.0, ProjectionScript.CHEST_LOCAL_POS, {"door_locked": false})
	_check(view.context_popup.visible and view.context_popup.context_items.is_empty(), "Empty opened Chest did not present an exact empty container state")

	var normal_snapshot := _public_snapshot(&"Normal", Vector2i(1, 1), false)
	normal_snapshot["room_floor_items"] = [_item("nearby-floor")]
	view.configure_room(normal_snapshot)
	var entity = view.ground_loot_entities.get("nearby-floor")
	_check(entity != null, "Ground-loot descriptor did not create an entity")
	if entity != null:
		var before_snapshot := normal_snapshot.duplicate(true)
		view.advance(0.0, entity.local_pos, {"door_locked": false})
		_check(view.context_popup.visible and view.context_popup.context_items.size() == 1, "Ground-loot proximity did not show the nearby item")
		_check(normal_snapshot == before_snapshot, "Ground-loot proximity mutated its source snapshot")

	var focus_snapshot := _public_snapshot(&"Normal", Vector2i(1, 1), false)
	focus_snapshot["room_floor_items"] = [_item("focus-a"), _item("focus-b")]
	view.configure_room(focus_snapshot)
	var focus_a = view.ground_loot_entities.get("focus-a")
	var focus_b = view.ground_loot_entities.get("focus-b")
	_check(focus_a != null and focus_b != null, "Focus-residency fixture did not create both ground entities")
	if focus_a != null and focus_b != null:
		focus_a.local_pos = Vector2(0.45, 0.50)
		focus_b.local_pos = Vector2(0.55, 0.50)
		focus_a.interaction_radius = 0.14
		focus_b.interaction_radius = 0.14
		view.advance(0.01, Vector2(0.47, 0.50), {"door_locked": false})
		_check(view.focused_interaction_id == "focus-a", "Nearest ground entity did not acquire focus")
		view.advance(0.14, Vector2(0.47, 0.50), {"door_locked": false})
		view.advance(0.01, Vector2(0.505, 0.50), {"door_locked": false})
		_check(view.focused_interaction_id == "focus-a", "Focus switched on midpoint jitter without a clear distance advantage")
		var locked_request: Dictionary = view.request_nearest_interaction(Vector2(0.505, 0.50))
		_check(String(locked_request.get("interaction_id", "")) == "focus-a", "Explicit pickup input diverged from the stable focused target")
		view.advance(0.01, Vector2(0.54, 0.50), {"door_locked": false})
		_check(view.focused_interaction_id == "focus-b", "Focus did not switch after residence and a clear distance advantage")
		view.advance(0.04, Vector2(0.90, 0.90), {"door_locked": false})
		_check(view.focused_interaction_id == "focus-b" and view.context_popup.visible, "Ground focus did not survive a brief boundary excursion")
		view.advance(0.08, Vector2(0.90, 0.90), {"door_locked": false})
		_check(view.focused_interaction_id.is_empty() and not view.context_popup.visible, "Ground focus survived beyond its lost-target grace window")

	var after_pickup_snapshot := focus_snapshot.duplicate(true)
	after_pickup_snapshot["room_floor_items"] = [_item("focus-b")]
	view.configure_room(after_pickup_snapshot)
	_check(not view.ground_loot_entities.has("focus-a"), "Removed ledger item remained actionable")
	_check(view.departing_ground_loot_entities.has("focus-a"), "Pickup feedback was destroyed with the authoritative entity refresh")
	var departing = view.departing_ground_loot_entities.get("focus-a")
	if departing != null:
		_check(departing.is_retiring() and not departing.enabled, "Departing pickup visual remained interactable")
		view.show_pickup_result("focus-a", true)
		departing.call("_process", GroundLootEntity.PICKUP_FEEDBACK_SECONDS + 0.01)
		await _frames(2)
		_check(not view.departing_ground_loot_entities.has("focus-a"), "Completed pickup feedback retained a stale departure entity")
	view.free()
	overlay.free()


func _check_production_run_scene() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	_check(main_scene != null, "main.tscn could not be loaded")
	if main_scene == null:
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	await _frames(12)
	var run_scene = main.get_node_or_null("RunScene")
	_check(run_scene != null, "Production RunScene missing")
	if run_scene == null:
		main.free()
		return
	run_scene.call("_start_standard_from_ui")
	await _frames(10)
	run_scene.call("_debug_teleport_to_room_type", &"Chest")
	await _frames(8)
	var room_controller = run_scene.get("room_controller")
	var room_view = run_scene.get("room_runtime_view")
	var player = run_scene.get("player_controller")
	var context = run_scene.get("run_context")
	var bus = run_scene.get("command_bus")
	_check(room_controller != null and room_view != null and player != null and context != null and bus != null, "Production Chest composition is incomplete")
	if room_controller != null:
		var background := room_controller.get_node_or_null("Background/BackgroundSprite") as Sprite2D
		var legacy_prop := room_controller.get_node_or_null("Interactables/PropSprite") as Sprite2D
		_check(background != null and background.texture != null and background.texture.resource_path.ends_with("/room_normal.png"), "Production Chest still uses the baked room_chest background")
		_check(legacy_prop != null and not legacy_prop.visible, "Production Chest still renders the legacy PropSprite")
	if room_view != null:
		_check(room_view.chest != null and room_view.ground_loot_entities.is_empty(), "Production Chest is not the unique dynamic world object")
	var command_before := int(bus.command_sequence) if bus != null else -1
	if run_scene != null:
		run_scene.call("_handle_interact_pressed")
	_check(bus.command_sequence == command_before + 1, "Explicit production Chest input did not submit search exactly once")
	_check(context.searched_cells.has(context.cell_key(context.get_current_pos())), "Production Chest search waited for animation before committing")
	var floor_after_open: Array = context.asset_ledger.get_room_floor_items(context.get_current_pos())
	_check(not floor_after_open.is_empty(), "Production Chest search produced no ledger contents")
	_check(room_view.context_popup.visible and room_view.context_popup.context_items.size() == floor_after_open.size(), "First successful Chest input did not immediately reveal exact contents")
	_check(not room_view.context_popup.status_label.visible, "Successful Chest input retained a redundant engineering-style status sentence")
	var popup_rect := Rect2(room_view.context_popup.position, room_view.context_popup.size * room_view.context_popup.scale)
	var player_clearance := Rect2(
		room_view.context_popup.player_world - Vector2(44.0, 64.0) * room_view.context_popup.scale,
		Vector2(88.0, 128.0) * room_view.context_popup.scale
	)
	_check(not popup_rect.intersects(player_clearance), "Production Chest popup covered the player: popup=%s player=%s anchor=%s" % [popup_rect, player_clearance, room_view.context_popup.anchor_world])
	run_scene.call("_handle_interact_pressed")
	_check(bus.command_sequence == command_before + 1, "Rapid repeated Chest input submitted a second search")
	if room_view != null and player != null:
		room_view.advance(0.5, player.get_local_position(), {"door_locked": false})
		room_view.configure_room(context.get_status_snapshot())
	_check(bus.command_sequence == command_before + 1, "Repeat input, animation advance, or rebuild submitted a second Chest search")
	if room_view != null:
		_check(room_view.ground_loot_entities.is_empty(), "Production opened Chest duplicated ledger contents on the floor")
		_check((room_view.world_projection.get("chest_contents", []) as Array).size() == floor_after_open.size(), "Production opened Chest does not mirror the remaining ledger")
	if not floor_after_open.is_empty():
		var activated: bool = bool(room_view.context_popup.activate_primary())
		_check(activated, "Opened Chest popup did not route its primary item action")
		var remaining: Array = context.asset_ledger.get_room_floor_items(context.get_current_pos())
		_check(remaining.size() == floor_after_open.size() - 1, "Explicit Chest-content pickup was rejected")
		room_view.configure_room(context.get_status_snapshot())
		room_view.advance(0.0, player.get_local_position(), {"door_locked": false})
		_check((room_view.world_projection.get("chest_contents", []) as Array).size() == remaining.size(), "Chest contents did not follow ledger after pickup")
		_check(room_view.context_popup.context_items.size() == remaining.size(), "Chest popup did not follow ledger after pickup")
		_check(not room_view.context_popup.status_label.visible, "Successful Chest-content pickup exposed an engineering-style command message")

	var chest_source := FileAccess.get_file_as_string("res://scripts/gameplay/interactables/g41_chest_interactable.gd")
	var contract_source := FileAccess.get_file_as_string("res://scripts/presentation/art24/art24_in_run_asset_contract.gd")
	var manifest_source := FileAccess.get_file_as_string("res://data/assets/asset_manifest.csv")
	var run_source := FileAccess.get_file_as_string("res://scripts/core/run/run_scene.gd")
	var capture_source := FileAccess.get_file_as_string("res://tests/art25_production_visual_capture_runner.gd")
	var open_chest_path := AssetContract.path_for(&"visual.art24.prop.chest_open_state")
	var closed_chest_path := AssetContract.path_for(&"visual.art24.prop.chest_closed")
	_check(open_chest_path.ends_with("/art07/00_baoxiang_kai.png"), "Opened Chest state is not bound to the revalidated open texture")
	_check(open_chest_path != closed_chest_path and ResourceLoader.exists(open_chest_path, "Texture2D"), "Opened Chest texture is missing or aliases the closed texture")
	_check(contract_source.contains("00_baoxiang_kai.png"), "Open-Chest contract lost its governed runtime path")
	_check(manifest_source.contains("sources.zip!/sources/draw/30_game_ready/props/00_baoxiang_kai.png"), "Open-Chest source-pack member is absent from the asset gate")
	_check(manifest_source.contains("A1035F69C412680016E6FB1C4FB181E77E75A517FDB252D6EBBC76D7F7957E71"), "Open-Chest source-pack hash is absent from the asset gate")
	_check(manifest_source.contains("3A4D3445312B5611B7F9FA9066FBE7FB666C48A074579BE7D303003CC9C0180A"), "Open-Chest member/runtime hash is absent from the asset gate")
	_check(manifest_source.contains("scripts/gameplay/interactables/g41_chest_interactable.gd") and manifest_source.contains("i3_source_pack_revalidated"), "Open-Chest consumer or review status is absent from the asset gate")
	_check(chest_source.contains("AssetContract.texture(StringName(\"visual.art24.fx.chest_opening.%d\" % frame))"), "Chest opening FX bypasses the registered runtime key")
	_check(not run_source.contains("interaction_commit_requested") and not run_source.contains("_on_g41_interaction_commit_requested"), "RunScene still accepts an animation-driven Chest commit")
	_check(not capture_source.contains("chest_view.chest.mark_opened()"), "Production capture still cheats the opened Chest state")
	main.free()


func _public_snapshot(room_type: StringName, position: Vector2i, searched: bool) -> Dictionary:
	var cells: Array[Dictionary] = []
	for y in range(3):
		for x in range(3):
			var pos := Vector2i(x, y)
			cells.append({"pos": pos, "revealed": true, "flagged": false})
	for cell in cells:
		var pos: Vector2i = cell.get("pos", Vector2i.ZERO)
		if pos == Vector2i(2, 1):
			cell["flagged"] = true
		elif pos == Vector2i(1, 2):
			cell["revealed"] = false
	return {
		"position": position,
		"player_pos": position,
		"width": 3,
		"height": 3,
		"current_room": room_type,
		"run_start_config": {"move_requires_revealed": true},
		"search_state_data": {"searched": searched, "can_search": not searched},
		"room_floor_items": [],
		"backpack_remaining": 10,
		"inventory_items": [],
		"run_map_snapshot": {"KnownMap": {"public_cells": cells, "read_only": true}},
	}


func _item(instance_id: String) -> Dictionary:
	return {
		"instance_id": instance_id,
		"item_id": "emergency_bandage",
		"display_name": "应急绷带",
		"short_description": "恢复少量生命。",
		"rarity": &"common",
		"weight": 1,
		"base_value": 16,
	}


func _count_kind(objects: Array, kind: StringName) -> int:
	var count := 0
	for raw_object in objects:
		if raw_object is Dictionary and StringName((raw_object as Dictionary).get("interaction_kind", &"")) == kind:
			count += 1
	return count


func _door_state(doors: Array, direction: Vector2i) -> StringName:
	for raw_door in doors:
		if not (raw_door is Dictionary):
			continue
		var door := raw_door as Dictionary
		var payload: Dictionary = door.get("payload", {})
		if Vector2i(payload.get("direction", Vector2i.ZERO)) == direction:
			return StringName(door.get("visual_state", &"missing"))
	return &"missing"


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("I2_WORLD_INTERACTION_RUNTIME=PASS chest=single_projection command=before_animation proximity=display_only doors=public_snapshot asset=open_png_revalidated")
		print("I3_SEARCH_WORLD_FEEDBACK=PASS sequence=search,reveal,stable,pickup chest=open_asset proximity=automatic focus=hysteresis,lock loads=preloaded authority=preserved")
		quit(0)
		return
	for failure in failures:
		push_error("I2 world interaction failure: " + failure)
	print("I2_WORLD_INTERACTION_RUNTIME=FAIL failures=%d" % failures.size())
	quit(1)
