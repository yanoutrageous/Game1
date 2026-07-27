extends SceneTree

const ProjectionScript := preload("res://scripts/gameplay/runtime/g41_world_object_projection.gd")
const PresentationDescriptor := preload("res://scripts/gameplay/runtime/g41_world_object_presentation_descriptor.gd")
const ChestInteractableScript := preload("res://scripts/gameplay/interactables/g41_chest_interactable.gd")
const RoomRuntimeViewScript := preload("res://scripts/gameplay/runtime/g41_room_runtime_view.gd")
const PlayerControllerScript := preload("res://scripts/gameplay/player/player_controller.gd")
const RuntimeLayout := preload("res://scripts/gameplay/runtime/g41_runtime_layout.gd")
const AssetContract := preload("res://scripts/presentation/art24/art24_in_run_asset_contract.gd")

const PASS_MARKER := "I3R_WORLD_OBJECT_PRESENTATION_CONTRACT=PASS"
const FAIL_MARKER := "I3R_WORLD_OBJECT_PRESENTATION_CONTRACT=FAIL"
const TOLERANCE := 0.001

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_chest_descriptor_and_responsive_projection()
	await _check_chest_visual_and_revisit()
	await _check_mine_floor_depth_contract()
	await _check_door_geometry_states_and_proximity()
	_check_door_room_texture_routing()
	await _check_legacy_prop_is_presentation_inert()
	_check_manifest_bindings()
	_finish()


func _check_chest_descriptor_and_responsive_projection() -> void:
	var closed := _chest_descriptor(false)
	var opened := _chest_descriptor(true)
	for field in [
		"presentation_contract",
		"visual_key",
		"visual_state",
		"pivot_normalized",
		"ground_anchor_local",
		"display_size_local",
		"visual_rect_local",
		"body_rect",
		"interaction_radius",
		"context_anchor_local",
	]:
		_require(closed.has(field), "closed chest omitted presentation field %s" % field)
		_require(opened.has(field), "opened chest omitted presentation field %s" % field)
	_require(StringName(closed.get("presentation_contract", &"")) == PresentationDescriptor.CONTRACT_ID, "chest did not use the I3R presentation contract")
	_require(is_equal_approx(Vector2(closed.get("local_pos", Vector2.ZERO)).x, 0.5), "chest is not centered on the room carrier")
	_require(Vector2(closed.get("ground_anchor_local", Vector2.ZERO)).is_equal_approx(Vector2(opened.get("ground_anchor_local", Vector2.INF))), "open and closed chest states use different ground anchors")
	_require(Vector2(closed.get("pivot_normalized", Vector2.ZERO)).is_equal_approx(Vector2(0.5, 1.0)), "chest does not use a bottom-centre pivot")
	_require(_rect_bottom_matches_anchor(closed, "visual_rect_local"), "closed chest visual bottom does not match its ground anchor")
	_require(_rect_bottom_matches_anchor(opened, "visual_rect_local"), "opened chest visual bottom does not match its ground anchor")
	_require(_rect_bottom_matches_anchor(closed, "body_rect"), "chest body footprint does not terminate at its ground anchor")
	_require(Rect2(closed.get("body_rect", Rect2())).size.x <= Rect2(closed.get("visual_rect_local", Rect2())).size.x, "chest body is wider than its presented art")
	_require(Vector2(closed.get("context_anchor_local", Vector2.INF)).y < Rect2(closed.get("visual_rect_local", Rect2())).position.y, "chest context anchor is not above the visible art")
	_require(Vector2(opened.get("context_anchor_local", Vector2.INF)).y < Rect2(opened.get("visual_rect_local", Rect2())).position.y, "opened chest context anchor is not above the raised lid")

	var closed_display := Vector2(closed.get("display_size_local", Vector2.ZERO))
	var opened_display := Vector2(opened.get("display_size_local", Vector2.ZERO))
	_require(is_equal_approx(closed_display.x, closed_display.y), "closed chest presentation distorts its source perspective")
	_require(is_equal_approx(opened_display.x, opened_display.y), "opened chest presentation distorts its source perspective")
	_require(opened_display.x > closed_display.x * 1.20, "opened chest did not compensate for its tighter source framing")
	var closed_subject := _presented_subject_rect_local(closed)
	var opened_subject := _presented_subject_rect_local(opened)
	_require(absf(closed_subject.size.x - opened_subject.size.x) <= TOLERANCE, "open and closed visible chest widths are not continuous")
	_require(absf(closed_subject.get_center().x - opened_subject.get_center().x) <= TOLERANCE, "open and closed visible chest centers drift")
	_require(absf(closed_subject.end.y - opened_subject.end.y) <= TOLERANCE, "open and closed visible chest contact lines drift")
	_require(opened_subject.size.y > closed_subject.size.y * 1.20, "opened chest does not gain the raised-lid height that distinguishes its state")
	var closed_base := _presented_calibration_rect_local(closed, "source_base_rect_px")
	var opened_base := _presented_calibration_rect_local(opened, "source_base_rect_px")
	_require(absf(closed_base.size.x - opened_base.size.x) <= TOLERANCE, "open and closed permanent chest bases use different widths")
	_require(absf(closed_base.size.y - opened_base.size.y) <= 3.0 / 560.0, "open and closed permanent chest bases use visibly different heights")
	_require(absf(closed_base.get_center().x - opened_base.get_center().x) <= TOLERANCE, "open and closed permanent chest bases drift sideways")
	_require(absf(closed_base.end.y - opened_base.end.y) <= TOLERANCE, "open and closed permanent chest bases leave different floor contact lines")
	_require(_asset_subject_rect_matches(&"visual.art24.prop.chest_closed"), "closed chest subject metadata does not match its admitted texture")
	_require(_asset_subject_rect_matches(&"visual.art24.prop.chest_open_state"), "opened chest subject metadata does not match its admitted texture")

	for viewport_size in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(1366, 768), Vector2(1024, 768)]:
		for descriptor in [closed, opened]:
			var visual_rect := PresentationDescriptor.visual_rect_for_viewport(descriptor, viewport_size)
			var body_rect := PresentationDescriptor.body_rect_for_viewport(descriptor, viewport_size)
			var anchor := PresentationDescriptor.ground_anchor_for_viewport(descriptor, viewport_size)
			_require(absf(visual_rect.end.y - anchor.y) <= TOLERANCE, "viewport %s broke the chest visual baseline" % viewport_size)
			_require(absf(body_rect.end.y - anchor.y) <= TOLERANCE, "viewport %s broke the chest collision baseline" % viewport_size)
			_require(visual_rect.size.x > body_rect.size.x and visual_rect.size.y > body_rect.size.y, "viewport %s collapsed visual/body proportions" % viewport_size)


func _check_chest_visual_and_revisit() -> void:
	var closed := _chest_descriptor(false)
	var opened := _chest_descriptor(true)
	var chest = ChestInteractableScript.new()
	root.add_child(chest)
	chest.configure_chest(closed)
	await process_frame
	var art := chest.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	_require(art != null and art.texture != null, "closed chest art was not created")
	var closed_bottom := _sprite_bottom(art) if art != null else INF
	var closed_subject := _sprite_subject_rect(art, &"visual.art24.prop.chest_closed")
	_require(absf(closed_bottom) <= TOLERANCE, "closed chest art does not land on the descriptor ground baseline")
	_require(art != null and (art.texture.get_size() * art.scale).is_equal_approx(Vector2(80.0, 80.0)), "closed chest did not use the exact 80x80 presentation size")
	_require(art != null and is_equal_approx(art.scale.x, art.scale.y), "closed chest source perspective was distorted")

	chest.apply_search_result(true)
	_require(chest.is_opened() and chest.is_container_open(), "successful first open did not expose container authority immediately")
	art = chest.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	var opened_subject := _sprite_subject_rect(art, &"visual.art24.prop.chest_open_state")
	_require(art != null and art.texture != null and art.texture.resource_path.ends_with("/art07/00_baoxiang_kai.png"), "successful first open did not switch to the admitted opened texture immediately")
	_require(absf(_sprite_bottom(art) - closed_bottom) <= TOLERANCE, "opened chest texture jumped off the closed-state baseline")
	_require(art != null and is_equal_approx(art.scale.x, art.scale.y), "opened chest source perspective was distorted")
	_require(absf(opened_subject.size.x - closed_subject.size.x) <= TOLERANCE, "opened chest visibly shrank relative to the closed chest")
	_require(absf(opened_subject.get_center().x - closed_subject.get_center().x) <= TOLERANCE, "opened chest visibly shifted sideways")
	_require(absf(opened_subject.end.y - closed_subject.end.y) <= TOLERANCE, "opened chest left the shared floor contact line")
	_require(opened_subject.size.y > closed_subject.size.y * 1.20, "opened chest lost its raised-lid silhouette")
	var opening_fx := chest.get_node_or_null("VisualRoot/OpeningFx") as Sprite2D
	_require(opening_fx != null and opening_fx.visible, "successful chest open omitted the opening cue")
	if opening_fx != null and opening_fx.texture != null:
		_require((opening_fx.texture.get_size() * opening_fx.scale).is_equal_approx(Vector2(96.0, 96.0)), "source-framing compensation incorrectly enlarged the opening FX")
	chest.advance(ChestInteractableScript.OPENING_SECONDS)
	_require(chest.visual_state == &"opened", "opening presentation did not settle to opened")

	chest.configure_chest(opened)
	art = chest.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	_require(chest.is_opened() and chest.is_container_open(), "opened chest lost authority after revisit")
	_require(absf(_sprite_bottom(art) - closed_bottom) <= TOLERANCE, "revisited chest changed its baseline")
	_require(_sprite_subject_rect(art, &"visual.art24.prop.chest_open_state").is_equal_approx(opened_subject), "revisited chest changed its calibrated visible geometry")
	chest.free()


func _check_mine_floor_depth_contract() -> void:
	var stage := Node2D.new()
	stage.name = "MineProductionLayerFixture"
	root.add_child(stage)
	var room_layer := Node2D.new()
	room_layer.name = "RoomLayer"
	stage.add_child(room_layer)
	var player_layer := Node2D.new()
	player_layer.name = "PlayerLayer"
	stage.add_child(player_layer)
	var view = RoomRuntimeViewScript.new()
	view.name = "G41RoomRuntimeView"
	room_layer.add_child(view)
	var player = PlayerControllerScript.new()
	player.name = "PlayerController"
	player_layer.add_child(player)
	await process_frame

	var snapshot := _public_snapshot(Vector2i(1, 1))
	snapshot["current_room"] = &"Mine"
	snapshot["current_room_detail"] = {"room_type_key": &"mine", "triggered": false}
	view.configure_room(snapshot)
	var mine_entity = _special_entity_for_kind(view, &"mine")
	var mine_projection := _projection_for_kind(ProjectionScript.build(snapshot), &"mine")
	var mine_sprite := (
		mine_entity.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
		if mine_entity != null
		else null
	)
	_require(mine_entity != null and mine_sprite != null and mine_sprite.texture != null, "production Mine art was not materialized")
	var armed_modulate := mine_sprite.modulate if mine_sprite != null else Color.TRANSPARENT
	_require(StringName(mine_projection.get("depth_key", &"")) == &"world.interactable.mine", "Mine lost its governed depth semantic")
	_require(Vector2(mine_projection.get("pivot_normalized", Vector2.INF)).is_equal_approx(Vector2(0.5, 0.5)), "Mine does not use its floor-centre pivot")
	_require(Vector2(mine_projection.get("display_size_local", Vector2.ZERO)).is_equal_approx(ProjectionScript.MINE_DISPLAY_SIZE), "Mine descriptor omitted its display footprint")
	var visual_rect := Rect2(mine_projection.get("visual_rect_local", Rect2()))
	var body_rect := Rect2(mine_projection.get("body_rect", Rect2()))
	_require(visual_rect.encloses(body_rect), "Mine trigger body escaped its visible floor footprint")
	_require(mine_sprite != null and (mine_sprite.texture.get_size() * mine_sprite.scale).is_equal_approx(Vector2(72.0, 72.0)), "production Mine ignored descriptor display geometry")
	_require(mine_entity != null and mine_entity.z_index == 0, "static Mine is not on the shared floor z")
	_require(player.z_index == 0, "Mine room unexpectedly raised or lowered the player z")
	_require(room_layer.get_index() < player_layer.get_index(), "production branch order no longer draws the floor before the player")
	_require(not room_layer.y_sort_enabled and not player_layer.y_sort_enabled, "floor-hazard ordering was delegated to incompatible Y-sort")

	player.set_local_position(ProjectionScript.MINE_LOCAL_POS + Vector2(-0.14, 0.0))
	view.advance(0.0, player.get_local_position(), {})
	await process_frame
	_require(not _sprite_opaque_rect(mine_sprite).intersects(_sprite_opaque_rect(player.get_node_or_null("Sprite") as Sprite2D)), "Mine approach fixture already overlaps the player")

	player.set_local_position(ProjectionScript.MINE_LOCAL_POS)
	view.advance(0.0, player.get_local_position(), {})
	await process_frame
	_require(_sprite_opaque_rect(mine_sprite).intersects(_sprite_opaque_rect(player.get_node_or_null("Sprite") as Sprite2D)), "Mine overlap fixture does not exercise the reported crossing")
	_require(mine_entity.z_index == player.z_index and room_layer.get_index() < player_layer.get_index(), "static Mine can draw over the overlapping player")
	view.apply_room_entry_result({
		"position": Vector2i(1, 1),
		"room_type": &"Mine",
		"cause": &"mine_triggered",
		"first_trigger": true,
		"hp_delta": -10,
		"pressure_delta": 1,
		"fatal": false,
	})
	var burst := view.get_node_or_null("SpecialRoomFx/MineBurst") as Sprite2D
	_require(burst != null and burst.visible, "Mine trigger omitted its transient consequence FX")
	_require(burst != null and burst.get_parent() is CanvasItem and (burst.get_parent() as CanvasItem).z_index > player.z_index, "Mine consequence FX is not isolated above the static floor art")
	_require(mine_entity.z_index == 0, "Mine trigger promoted the static grate over the player")
	_require(mine_sprite != null and mine_sprite.modulate.a < armed_modulate.a * 0.70, "resolved Mine retained the armed-state luminance")
	_require(mine_sprite != null and mine_sprite.modulate.r < armed_modulate.r * 0.50, "resolved Mine retained the armed red warning emphasis")

	player.set_local_position(ProjectionScript.MINE_LOCAL_POS + Vector2(0.22, 0.0))
	view.advance(0.30, player.get_local_position(), {})
	await process_frame
	_require(not _sprite_opaque_rect(mine_sprite).intersects(_sprite_opaque_rect(player.get_node_or_null("Sprite") as Sprite2D)), "leaving the Mine retained a false visual overlap")
	_require(burst != null and not burst.visible, "Mine consequence FX outlived its bounded feedback duration")
	_require(mine_entity.z_index == 0 and player.z_index == 0, "Mine/player depth changed after leaving the overlap")
	_require(mine_sprite != null and mine_sprite.modulate.is_equal_approx(RoomRuntimeViewScript.MINE_RESOLVED_MODULATE), "resolved Mine did not retain its inactive visual after departure")
	stage.free()


func _check_door_geometry_states_and_proximity() -> void:
	var snapshot := _public_snapshot(Vector2i(1, 1))
	var doors: Array = ProjectionScript.build(snapshot, {"door_locked": false}).get("doors", [])
	_require(doors.size() == 4, "door projection did not expose four baked doorway descriptors")
	_require(_door_state(doors, Vector2i.UP) == &"available", "north available state is wrong")
	_require(_door_state(doors, Vector2i.RIGHT) == &"blocked_flagged", "east flagged state is wrong")
	_require(_door_state(doors, Vector2i.DOWN) == &"blocked_hidden", "south hidden state is wrong")
	_require(_door_state(doors, Vector2i.LEFT) == &"available", "west available state is wrong")

	for raw_door in doors:
		var door := raw_door as Dictionary
		var body := Rect2(door.get("body_rect", Rect2()))
		var anchor := Vector2(door.get("ground_anchor_local", Vector2.INF))
		var direction := Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO))
		_require(body.get_center().is_equal_approx(anchor), "door %s overlay/collision center drifted from the baked doorway anchor" % direction)
		_require(String(door.get("visual_key", "")).contains(String(door.get("orientation", &"none"))), "door visual key omitted its baked orientation")
		_require(String(door.get("visual_key", "")).contains(String(door.get("visual_state", &"missing"))), "door visual key omitted its state")
		_require(String(door.get("visual_key", "")).begins_with("visual.art24.door.normal."), "door visual key does not resolve through the admitted in-run asset contract")
		var texture_region := Rect2(door.get("texture_region_normalized", Rect2()))
		_require(texture_region.size.x > 0.0 and texture_region.size.y > 0.0, "door %s has no admitted texture region" % direction)
		_require(texture_region.position.x >= 0.0 and texture_region.position.y >= 0.0 and texture_region.end.x <= 1.0 and texture_region.end.y <= 1.0, "door %s texture region escaped the room plate" % direction)
		_require(texture_region.is_equal_approx(Rect2(door.get("visual_rect_local", Rect2()))), "door %s texture crop and pivoted visual rectangle disagree" % direction)
		_require(float(door.get("interaction_radius", 0.0)) > 0.0, "door %s has no near-distance cue radius" % direction)
		var texture := AssetContract.texture(StringName(door.get("visual_key", &"")))
		_require(texture != null and texture.resource_path.ends_with("/assets/rooms/room_normal.png"), "door %s visual key did not resolve to the admitted room door texture" % direction)
		if direction.y != 0:
			_require(body.size.x > body.size.y, "north/south doorway body is not horizontal")
		else:
			_require(body.size.y > body.size.x, "east/west doorway body is not vertical")

	var combat_doors: Array = ProjectionScript.build(snapshot, {"door_locked": true}).get("doors", [])
	_require(_door_state(combat_doors, Vector2i.UP) == &"combat_restricted", "combat seal did not replace an otherwise available doorway state")
	var corner_doors: Array = ProjectionScript.build(_public_snapshot(Vector2i.ZERO), {"door_locked": false}).get("doors", [])
	_require(_door_state(corner_doors, Vector2i.UP) == &"blocked_out_of_bounds", "north boundary state is not explicit")
	_require(_door_state(corner_doors, Vector2i.LEFT) == &"blocked_out_of_bounds", "west boundary state is not explicit")

	var view = RoomRuntimeViewScript.new()
	root.add_child(view)
	view.configure_room(snapshot)
	await process_frame
	for raw_door in doors:
		var door := raw_door as Dictionary
		var projection_id := String(door.get("projection_id", ""))
		var direction := Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO))
		var sprite := view.door_visuals.get(projection_id) as Sprite2D
		_require(sprite != null and sprite.visible and sprite.texture != null, "production view did not materialize door %s as a texture-backed Sprite2D" % direction)
		if sprite == null or sprite.texture == null:
			continue
		var texture_region := Rect2(door.get("texture_region_normalized", Rect2()))
		var expected_source := Rect2(
			texture_region.position * sprite.texture.get_size(),
			texture_region.size * sprite.texture.get_size()
		)
		_require(sprite.region_enabled and sprite.region_rect.is_equal_approx(expected_source), "production view did not consume door %s texture crop" % direction)
		var pivot := Vector2(door.get("pivot_normalized", Vector2.ZERO))
		var anchor := Vector2(door.get("ground_anchor_local", Vector2.ZERO))
		var display_size := Vector2(door.get("display_size_local", Vector2.ZERO))
		var expected_visual_rect := Rect2(anchor - display_size * pivot, display_size)
		_require(sprite.position.is_equal_approx(RuntimeLayout.local_to_world(expected_visual_rect.position)), "production view ignored door %s pivot/anchor placement" % direction)
		_require((sprite.region_rect.size * sprite.scale).is_equal_approx(RuntimeLayout.local_size_to_world(expected_visual_rect.size)), "production view ignored door %s display size" % direction)
		_require(String(sprite.get_meta("visual_key", &"")) == String(door.get("visual_key", &"")), "production view lost door %s visual-key authority" % direction)

	var player = PlayerControllerScript.new()
	root.add_child(player)
	player.set_door_projections(view.get_door_projections())
	_require(player.get_door_projections() == view.get_door_projections(), "production player did not retain the view's door geometry")
	for raw_door in doors:
		var door := raw_door as Dictionary
		var body := Rect2(door.get("body_rect", Rect2()))
		var direction := Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO))
		var aligned_pos := _door_approach_position(body, direction, false)
		player.set_local_position(aligned_pos)
		_require(player.requested_transition(Vector2(direction)) == direction, "player transition did not consume door %s body geometry" % direction)
		player.set_local_position(_door_approach_position(body, direction, true))
		_require(player.requested_transition(Vector2(direction)) == Vector2i.ZERO, "player transition ignored door %s alignment boundary" % direction)
	for entry_direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var entry_door := _door_for(doors, -entry_direction)
		var entry_body := Rect2(entry_door.get("body_rect", Rect2()))
		var door_visual_rect := Rect2(entry_door.get("visual_rect_local", Rect2()))
		var landing := player.place_from_entry(entry_direction)
		var relative_visual_bounds := player.presentation_bounds_local()
		var landed_visual_rect := Rect2(
			landing + relative_visual_bounds.position,
			relative_visual_bounds.size
		)
		_require(
			not entry_body.grow(PlayerControllerScript.PLAYER_RADIUS).has_point(landing),
			"entry landing %s still intersects the opposite door body clearance" % entry_direction
		)
		_require(
			not landed_visual_rect.intersects(door_visual_rect),
			"entry landing %s leaves the player silhouette under the opposite door visual" % entry_direction
		)
		_require(
			Vector2(entry_direction).dot(landing - entry_body.get_center()) > 0.0,
			"entry landing %s was placed on the exterior side of the opposite door" % entry_direction
		)
		_require(
			player.requested_transition(Vector2(-entry_direction)) == Vector2i.ZERO,
			"entry landing %s immediately retriggered the opposite doorway" % entry_direction
		)
	player.free()

	view.advance(0.0, Vector2(0.5, 0.5), {"door_locked": false})
	_require(view.nearby_door_direction == Vector2i.ZERO and view.nearby_available_door == Vector2i.ZERO, "available doorway cue is visible away from a doorway")
	var north := _door_for(doors, Vector2i.UP)
	view.advance(0.0, Vector2(north.get("ground_anchor_local", Vector2.ZERO)), {"door_locked": false})
	_require(view.nearby_door_direction == Vector2i.UP and view.nearby_available_door == Vector2i.UP and view.nearby_door_state == &"available", "near north doorway did not expose the available cue")
	var door_prompt := view.get_node_or_null("DoorPrompt") as Label
	_require(door_prompt != null and door_prompt.visible, "near available doorway did not expose a player prompt")
	var east := _door_for(doors, Vector2i.RIGHT)
	view.advance(0.0, Vector2(east.get("ground_anchor_local", Vector2.ZERO)), {"door_locked": false})
	_require(view.nearby_door_state == &"blocked_flagged" and view.nearby_available_door == Vector2i.ZERO, "flagged doorway leaked the available cue")
	view.advance(0.0, Vector2(0.5, 0.5), {"door_locked": false})
	_require(door_prompt != null and not door_prompt.visible, "door prompt remained visible after leaving proximity")
	view.free()

	var room_source := FileAccess.get_file_as_string("res://scripts/gameplay/runtime/g41_room_runtime_view.gd")
	_require(not room_source.contains("Color(color.r, color.g, color.b"), "door states still render as colored collision rectangles")
	_require(room_source.contains("_draw_available_door_cue") and room_source.contains("_draw_blocked_door_cue"), "player-readable door cue renderers are absent")
	var run_source := FileAccess.get_file_as_string("res://scripts/core/run/run_scene.gd")
	_require(run_source.contains("player_controller.set_door_projections(room_runtime_view.get_door_projections())"), "production RunScene does not wire the view's door geometry into PlayerController")


func _check_legacy_prop_is_presentation_inert() -> void:
	var room_scene := load("res://scenes/room/room_scene.tscn") as PackedScene
	var room_controller = room_scene.instantiate()
	root.add_child(room_controller)
	await process_frame
	room_controller.configure({
		"title": "Chest",
		"hint": "",
		"background_asset_id": &"room.background.normal",
		"prop_asset_id": &"prop.chest.closed",
		"risk_key": &"ui.text",
	})
	var legacy_prop := room_controller.get_node_or_null("Interactables/PropSprite") as Sprite2D
	_require(legacy_prop != null and not legacy_prop.visible and legacy_prop.texture == null, "legacy PropSprite retained texture/visibility authority")
	var background := room_controller.get_node_or_null("Background/BackgroundSprite") as Sprite2D
	_require(background != null and background.texture != null, "production room plate was not materialized")
	if background != null and background.texture != null:
		_require(background.position.is_equal_approx(RuntimeLayout.ROOM_RECT.get_center()), "room plate center drifted from the runtime geometry authority")
		_require((background.texture.get_size() * background.scale).is_equal_approx(RuntimeLayout.ROOM_RECT.size), "room plate scale drifted from the texture-slice/body geometry authority")
	room_controller.free()


func _check_door_room_texture_routing() -> void:
	for fixture in [
		{"room_type": &"Normal", "token": "normal", "path": "/assets/rooms/room_normal.png"},
		{"room_type": &"Chest", "token": "normal", "path": "/assets/rooms/room_normal.png"},
		{"room_type": &"Mine", "token": "mine", "path": "/assets/rooms/room_mine.png"},
		{"room_type": &"Event", "token": "event", "path": "/assets/rooms/room_event.png"},
		{"room_type": &"Monster", "token": "monster", "path": "/assets/rooms/room_monster.png"},
		{"room_type": &"Exit", "token": "exit", "path": "/assets/rooms/room_exit.png"},
	]:
		var snapshot := _public_snapshot(Vector2i(1, 1))
		snapshot["current_room"] = fixture["room_type"]
		var doors: Array = ProjectionScript.build(snapshot, {"door_locked": false}).get("doors", [])
		var north := _door_for(doors, Vector2i.UP)
		var visual_key := StringName(north.get("visual_key", &""))
		var texture := AssetContract.texture(visual_key)
		_require(String(visual_key).begins_with("visual.art24.door.%s." % fixture["token"]), "%s room door key selected the wrong room plate" % fixture["room_type"])
		_require(texture != null and texture.resource_path.ends_with(fixture["path"]), "%s room door did not resolve to its admitted room texture" % fixture["room_type"])


func _check_manifest_bindings() -> void:
	var manifest := FileAccess.get_file_as_string("res://data/assets/asset_manifest.csv")
	_require(manifest.contains("prop.chest.closed") and manifest.contains("res://assets/props/chest_closed.png"), "closed chest asset is absent from the governed manifest")
	_require(manifest.contains("prop.art07.00_baoxiang_kai") and manifest.contains("visual.art24.prop.chest_open_state"), "opened chest asset or semantic key is absent from the governed manifest")
	var closed := AssetContract.world_presentation_for(&"visual.art24.prop.chest_closed")
	var opened := AssetContract.world_presentation_for(&"visual.art24.prop.chest_open_state")
	_require(Vector2(closed.get("pivot_normalized", Vector2.INF)).is_equal_approx(Vector2(opened.get("pivot_normalized", Vector2.ZERO))), "asset contract does not bind chest states to one ground pivot")
	_require(Vector2(closed.get("fx_footprint_local", Vector2.INF)).is_equal_approx(Vector2(opened.get("fx_footprint_local", Vector2.ZERO))), "asset contract lets source framing inflate the chest opening FX")
	_require(Rect2(closed.get("source_subject_rect_px", Rect2())).size.x > Rect2(opened.get("source_subject_rect_px", Rect2())).size.x, "asset contract lost the source-framing mismatch it must compensate")


func _chest_descriptor(opened: bool) -> Dictionary:
	var objects: Array = ProjectionScript.build(_public_snapshot(Vector2i(1, 1), opened), {"door_locked": false}).get("world_objects", [])
	return objects[0] as Dictionary if not objects.is_empty() else {}


func _public_snapshot(position: Vector2i, searched: bool = false) -> Dictionary:
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
		"current_room": &"Chest",
		"run_start_config": {"move_requires_revealed": true},
		"search_state_data": {"searched": searched, "can_search": not searched},
		"room_floor_items": [],
		"inventory_items": [],
		"run_map_snapshot": {"KnownMap": {"public_cells": cells, "read_only": true}},
	}


func _door_for(doors: Array, direction: Vector2i) -> Dictionary:
	for raw_door in doors:
		var door := raw_door as Dictionary
		if Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO)) == direction:
			return door
	return {}


func _door_state(doors: Array, direction: Vector2i) -> StringName:
	return StringName(_door_for(doors, direction).get("visual_state", &"missing"))


func _projection_for_kind(projection: Dictionary, kind: StringName) -> Dictionary:
	for raw_object in (projection.get("world_objects", []) as Array):
		if raw_object is Dictionary and StringName((raw_object as Dictionary).get("interaction_kind", &"")) == kind:
			return raw_object as Dictionary
	return {}


func _special_entity_for_kind(view, kind: StringName):
	if view == null:
		return null
	for entity in view.special_entities.values():
		if entity != null and StringName(entity.interaction_kind) == kind:
			return entity
	return null


func _door_approach_position(body: Rect2, direction: Vector2i, misaligned: bool) -> Vector2:
	var position := body.get_center()
	if direction.x < 0:
		position.x = body.end.x + 0.01
	elif direction.x > 0:
		position.x = body.position.x - 0.01
	elif direction.y < 0:
		position.y = body.end.y + 0.01
	else:
		position.y = body.position.y - 0.01
	if misaligned:
		if direction.x != 0:
			position.y = body.end.y + 0.002
		else:
			position.x = body.end.x + 0.002
	return position


func _rect_bottom_matches_anchor(descriptor: Dictionary, rect_key: String) -> bool:
	var rect := Rect2(descriptor.get(rect_key, Rect2()))
	var anchor := Vector2(descriptor.get("ground_anchor_local", Vector2.INF))
	return absf(rect.end.y - anchor.y) <= TOLERANCE


func _sprite_bottom(sprite: Sprite2D) -> float:
	if sprite == null or sprite.texture == null:
		return INF
	return sprite.position.y + sprite.texture.get_size().y * sprite.scale.y * 0.5


func _presented_subject_rect_local(descriptor: Dictionary) -> Rect2:
	return _presented_calibration_rect_local(descriptor, "source_subject_rect_px")


func _presented_calibration_rect_local(descriptor: Dictionary, source_rect_key: String) -> Rect2:
	var visual_key := StringName(descriptor.get("visual_key", &""))
	var presentation := AssetContract.world_presentation_for(visual_key)
	var source_rect := Rect2(presentation.get(source_rect_key, Rect2()))
	var texture := AssetContract.texture(visual_key)
	if texture == null or source_rect.size.x <= 0.0 or source_rect.size.y <= 0.0:
		return Rect2()
	var texture_size := texture.get_size()
	var display_size := Vector2(descriptor.get("display_size_local", Vector2.ZERO))
	var pivot := Vector2(descriptor.get("pivot_normalized", Vector2(0.5, 1.0)))
	var anchor := Vector2(descriptor.get("ground_anchor_local", Vector2.ZERO))
	var canvas_rect := Rect2(anchor - display_size * pivot, display_size)
	return Rect2(
		canvas_rect.position + source_rect.position / texture_size * display_size,
		source_rect.size / texture_size * display_size
	)


func _sprite_subject_rect(sprite: Sprite2D, visual_key: StringName) -> Rect2:
	if sprite == null or sprite.texture == null:
		return Rect2()
	var presentation := AssetContract.world_presentation_for(visual_key)
	var source_rect := Rect2(presentation.get("source_subject_rect_px", Rect2()))
	var canvas_size := sprite.texture.get_size() * sprite.scale
	var canvas_position := sprite.position - canvas_size * 0.5
	return Rect2(
		canvas_position + source_rect.position * sprite.scale,
		source_rect.size * sprite.scale
	)


func _asset_subject_rect_matches(visual_key: StringName) -> bool:
	var presentation := AssetContract.world_presentation_for(visual_key)
	var expected := Rect2(presentation.get("source_subject_rect_px", Rect2()))
	var texture := AssetContract.texture(visual_key)
	if texture == null:
		return false
	var image := texture.get_image()
	if image == null:
		return false
	return Rect2(image.get_used_rect()).is_equal_approx(expected)


func _sprite_opaque_rect(sprite: Sprite2D) -> Rect2:
	if sprite == null or sprite.texture == null:
		return Rect2()
	var image := sprite.texture.get_image()
	if image == null:
		return Rect2()
	var used := Rect2(image.get_used_rect())
	var local_rect := Rect2(used.position - sprite.texture.get_size() * 0.5, used.size)
	var transform := sprite.get_global_transform_with_canvas()
	var points := [
		transform * local_rect.position,
		transform * Vector2(local_rect.end.x, local_rect.position.y),
		transform * local_rect.end,
		transform * Vector2(local_rect.position.x, local_rect.end.y),
	]
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for point: Vector2 in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print(PASS_MARKER + " descriptor=v1 chest=center,baseline,subject_width,uniform_scale,open,revisit mine=floor,descriptor,player_above,fx_transient,resolved_distinct doors=4,state,texture,pivot,player_geometry,proximity,overlay resolutions=1280x720,1920x1080,1366x768,1024x768 legacy_prop=inert manifest=bound")
		quit(0)
		return
	for failure in failures:
		push_error("I3R world-object presentation failure: " + failure)
	print(FAIL_MARKER + " failures=%d" % failures.size())
	quit(1)
