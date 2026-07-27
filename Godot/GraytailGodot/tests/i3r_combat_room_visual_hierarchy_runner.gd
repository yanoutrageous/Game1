extends SceneTree

const CombatSimulationScript := preload("res://scripts/gameplay/combat/g41_combat_simulation.gd")
const ProjectionScript := preload("res://scripts/gameplay/runtime/g41_world_object_projection.gd")
const RoomRuntimeViewScript := preload("res://scripts/gameplay/runtime/g41_room_runtime_view.gd")
const RuntimeLayout := preload("res://scripts/gameplay/runtime/g41_runtime_layout.gd")
const AssetContract := preload("res://scripts/presentation/art24/art24_in_run_asset_contract.gd")

const PASS_MARKER := "I3R_COMBAT_ROOM_VISUAL_HIERARCHY=PASS"
const FAIL_MARKER := "I3R_COMBAT_ROOM_VISUAL_HIERARCHY=FAIL"
const PLAYER_PROMPT_CLEARANCE_PIXELS := 6.0
const RECT_EPSILON := 0.5

var failures: Array[String] = []
var main: Node
var run_scene: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production_main_scene_missing")
	if packed == null:
		_finish()
		return
	main = packed.instantiate()
	root.add_child(main)
	await _frames(18)
	run_scene = main.get_node_or_null("RunScene")
	_require(run_scene != null, "production_run_scene_missing")
	if run_scene == null:
		_finish()
		return

	run_scene.call("_start_standard_from_ui")
	await _frames(20)
	_require(_activate_production_combat(), "production_monster_room_activation_failed")
	if not _production_nodes_ready():
		_finish()
		return
	await _frames(4)

	# Freeze only the production coordinator while the test places deterministic
	# presentation fixtures. All inspected nodes are the nodes used by main.tscn.
	run_scene.set_process(false)
	var view = run_scene.get("room_runtime_view")
	var player = run_scene.get("player_controller")
	var snapshot := _monster_public_snapshot()
	var combat := _combat_visual_fixture()
	view.call("configure_room", snapshot)
	view.call("apply_combat_snapshot", combat)
	player.call("set_logical_obstacles", view.call("get_logical_obstacles"))
	player.call("set_door_projections", view.call("get_door_projections"))
	player.set_process(false)
	await _frames(2)

	_check_production_room_plate()
	_check_player_door_and_prompt_hierarchy(view, player, snapshot, combat)
	_check_lock_overlay_material(view, snapshot)
	_check_major_occluder_projection_and_rendering(view, combat)
	_check_enemy_identity_readability(view)
	_check_attack_cooldown_presentation()
	_check_authored_combat_fx(view, combat)
	_check_no_visible_debug_primitives(view)
	_finish()


func _activate_production_combat() -> bool:
	var controller = run_scene.get("runtime_controller")
	var context = run_scene.get("run_context")
	var bus = run_scene.get("command_bus")
	if controller == null or context == null or bus == null:
		return false
	context.max_hp = 10000
	context.hp = 10000
	var combat_pos: Vector2i = context.get_current_pos()
	context.truth_map.set_room_type(combat_pos, &"Monster")
	bus.room_resolver.enter_room(context)
	controller.in_run_runtime.sync_room(Vector2(0.50, 0.50))
	if context.current_room_type != &"Monster" or not controller.in_run_runtime.has_active_combat():
		return false
	run_scene.call("_refresh_view_models")
	return true


func _production_nodes_ready() -> bool:
	var view = run_scene.get("room_runtime_view")
	var player = run_scene.get("player_controller")
	var room_controller = run_scene.get("room_controller")
	_require(view != null, "production_room_runtime_view_missing")
	_require(player != null, "production_player_controller_missing")
	_require(room_controller != null, "production_room_controller_missing")
	return view != null and player != null and room_controller != null


func _check_production_room_plate() -> void:
	var room_controller = run_scene.get("room_controller")
	var background := room_controller.get_node_or_null("Background/BackgroundSprite") as Sprite2D
	_require(
		background != null
		and background.texture != null
		and background.texture.resource_path.ends_with("/assets/rooms/room_monster.png"),
		"production_combat_room_plate_not_monster_art"
	)


func _check_player_door_and_prompt_hierarchy(
	view: Node,
	player: Node,
	snapshot: Dictionary,
	combat: Dictionary
) -> void:
	var player_sprite := player.get_node_or_null("Sprite") as Sprite2D
	_require(player_sprite != null and player_sprite.texture != null, "production_player_sprite_missing")
	if player_sprite == null or player_sprite.texture == null:
		return
	var overlap_failures: Array[String] = []
	var prompt_failures: Array[String] = []
	for raw_door in view.call("get_door_projections") as Array:
		if not raw_door is Dictionary:
			continue
		var door := raw_door as Dictionary
		if StringName(door.get("visual_state", &"")) != &"combat_restricted":
			continue
		var direction := Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO))
		var orientation := String(door.get("orientation", &"unknown"))
		var body := Rect2(door.get("body_rect", Rect2()))
		var contact := _door_approach_position(body, direction)
		player.call("set_local_position", contact)
		view.call("advance", 0.0, contact, combat)
		var door_sprite := view.get("door_visuals").get(String(door.get("projection_id", ""))) as Sprite2D
		if door_sprite == null or not door_sprite.visible or door_sprite.texture == null:
			overlap_failures.append("%s:door_visual_missing" % orientation)
			continue
		var player_rect := _transformed_sprite_rect(player_sprite)
		var door_rect := _transformed_sprite_rect(door_sprite)
		if (
			_rects_overlap_with_area(player_rect, door_rect)
			and not _draws_after(door_sprite, player_sprite)
		):
			overlap_failures.append(
				"%s:player=%s:door=%s:z=%d/%d" % [
					orientation,
					player_rect,
					door_rect,
					_effective_z(player_sprite),
					_effective_z(door_sprite),
				]
			)
		var prompt := view.get_node_or_null("DoorPrompt") as Label
		if prompt == null or not prompt.visible:
			prompt_failures.append("%s:prompt_missing" % orientation)
			continue
		var prompt_rect := prompt.get_global_rect()
		if _rects_overlap_with_area(player_rect.grow(PLAYER_PROMPT_CLEARANCE_PIXELS), prompt_rect):
			prompt_failures.append(
				"%s:player=%s:prompt=%s" % [orientation, player_rect, prompt_rect]
			)
	_require(
		overlap_failures.is_empty(),
		"player_door_occlusion_missing %s" % ", ".join(overlap_failures)
	)
	_require(
		prompt_failures.is_empty(),
		"combat_exit_prompt_overlaps_player clearance=%.1f %s" % [
			PLAYER_PROMPT_CLEARANCE_PIXELS,
			", ".join(prompt_failures),
		]
	)


func _check_lock_overlay_material(view: Node, snapshot: Dictionary) -> void:
	var available_doors: Array = ProjectionScript.build(snapshot, {"door_locked": false}).get("doors", [])
	var overlay_failures: Array[String] = []
	for raw_door in view.call("get_door_projections") as Array:
		if not raw_door is Dictionary:
			continue
		var door := raw_door as Dictionary
		if StringName(door.get("visual_state", &"")) != &"combat_restricted":
			continue
		var direction := Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO))
		var orientation := String(door.get("orientation", &"unknown"))
		var available := _door_for(available_doors, direction)
		var sprite := view.get("door_visuals").get(String(door.get("projection_id", ""))) as Sprite2D
		if not _has_authored_lock_overlay(sprite, door, available):
			overlay_failures.append(orientation)
	_require(
		overlay_failures.is_empty(),
		"combat_lock_overlay_not_authored directions=%s" % ",".join(overlay_failures)
	)
	var source := FileAccess.get_file_as_string("res://scripts/gameplay/runtime/g41_room_runtime_view.gd")
	var seal_source := _function_source(source, "_draw_combat_seal_segment")
	_require(
		not seal_source.contains("draw_line("),
		"combat_lock_overlay_still_uses_procedural_line_strip"
	)


func _check_major_occluder_projection_and_rendering(view: Node, combat: Dictionary) -> void:
	var altar: Rect2 = CombatSimulationScript.production_arena_obstacles()[0]
	var read_only: Dictionary = view.call("build_read_only_snapshot")
	var world_projection: Dictionary = read_only.get("world_projection", {})
	var occluders: Array = world_projection.get("occluders", [])
	var altar_descriptor := _matching_occluder_descriptor(occluders, altar)
	_require(
		not altar_descriptor.is_empty(),
		"monster_world_projection_missing_major_occluder altar=%s" % altar
	)

	var enemy_view := view.get("enemy_views").get("hierarchy_enemy") as Node2D
	var enemy_art := (
		enemy_view.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
		if enemy_view != null
		else null
	)
	_require(enemy_art != null and enemy_art.texture != null, "combat_enemy_art_missing")
	var altar_in_view := Rect2(
		RuntimeLayout.local_to_world(altar.position),
		RuntimeLayout.local_size_to_world(altar.size)
	)
	var altar_world := _transformed_rect(altar_in_view, (view as CanvasItem).get_global_transform())
	var enemy_rect := _transformed_sprite_rect(enemy_art) if enemy_art != null else Rect2()
	var render_occluder := _matching_render_occluder(view.get_parent(), altar)
	if enemy_art != null and _rects_overlap_with_area(enemy_rect, altar_world):
		_require(
			render_occluder != null and _draws_after(render_occluder, enemy_art),
			"enemy_art_crosses_major_occluder enemy=%s altar=%s foreground_occluder=%s" % [
				enemy_rect,
				altar_world,
				"<missing>" if render_occluder == null else render_occluder.get_path(),
			]
		)

	var warning_enemy := _enemy_for(combat.get("enemies", []), "hierarchy_enemy")
	var warning_radius := float(warning_enemy.get("warning_radius", 0.0))
	var warning_center := Vector2(warning_enemy.get("pos", Vector2.ZERO))
	var warning_bounds := Rect2(
		warning_center - Vector2.ONE * warning_radius,
		Vector2.ONE * warning_radius * 2.0
	)
	if warning_bounds.intersects(altar):
		var clipped_points: Array = warning_enemy.get("visible_warning_outline_points", [])
		var warning_contract := StringName(warning_enemy.get("warning_occlusion_contract", &""))
		var occluder_masks_geometry := (
			render_occluder != null
			and bool(render_occluder.get_meta("masks_combat_geometry", false))
			and _draws_after(render_occluder, view as CanvasItem)
		)
		_require(
			(
				warning_contract == CombatSimulationScript.ARENA_CONTRACT_ID
				and clipped_points.size() >= 3
			)
			or occluder_masks_geometry,
			"enemy_warning_crosses_major_occluder contract=%s points=%d altar=%s" % [
				warning_contract,
				clipped_points.size(),
				altar,
			]
		)


func _check_no_visible_debug_primitives(view: Node) -> void:
	var combat_root := view.get_node_or_null("CombatVisuals")
	var debug_primitives: Array[String] = []
	if combat_root != null:
		_collect_visible_debug_primitives(combat_root, debug_primitives)
	_require(
		debug_primitives.is_empty(),
		"visible_isolated_debug_primitives %s" % ",".join(debug_primitives)
	)
	_require(
		not bool(ProjectSettings.get_setting("application/run/show_g41_collision_debug", false)),
		"collision_debug_enabled_in_production"
	)


func _check_enemy_identity_readability(view: Node) -> void:
	var enemy_view := view.get("enemy_views").get("hierarchy_enemy") as Node2D
	_require(enemy_view != null, "combat_enemy_identity_actor_missing")
	if enemy_view == null:
		return
	var identity := enemy_view.get_node_or_null("HealthBarAnchor/IdentityLabel") as Label
	var health_background := enemy_view.get_node_or_null("HealthBarAnchor/HealthBackground") as ColorRect
	var health_fill := enemy_view.get_node_or_null("HealthBarAnchor/HealthFill") as ColorRect
	_require(
		identity != null
		and identity.visible
		and identity.text == "滞留工偶  战力 12",
		"enemy identity label did not expose player-facing name and power"
	)
	if identity != null:
		_require(
			identity.has_theme_font_override("font")
			and StringName(identity.get_meta("ui_composition_role", &"")) == &"status",
			"enemy identity label did not use the explicit pixel-font composition contract"
		)
	_require(
		health_background != null
		and health_fill != null
		and health_background.size.x >= 72.0
		and health_background.size.y >= 7.0
		and health_fill.size.y >= 5.0,
		"enemy health bar remained below the readable combat footprint"
	)


func _check_attack_cooldown_presentation() -> void:
	var surface = run_scene.get("run_surface")
	_require(surface != null, "production_run_surface_missing_for_attack_cooldown")
	if surface == null:
		return
	var action_buttons: Dictionary = surface.get("action_buttons")
	var combat_button := action_buttons.get(&"combat") as Button
	var action_bar := surface.get("action_bar") as Control
	_require(combat_button != null and action_bar != null, "existing_combat_action_button_missing")
	if combat_button == null or action_bar == null:
		return
	var original_text := combat_button.text
	var original_child_count := action_bar.get_child_count()
	surface.call("apply_combat_attack_state", {
		"ready": false,
		"buffer_window_open": false,
		"cooldown_remaining_seconds": 0.60,
	})
	_require(
		combat_button.modulate != Color.WHITE
		and combat_button.text == original_text
		and action_bar.get_child_count() == original_child_count,
		"attack cooldown did not dim only the existing attack button"
	)
	surface.call("apply_combat_attack_state", {
		"ready": false,
		"buffer_window_open": true,
		"cooldown_remaining_seconds": 0.10,
	})
	_require(
		combat_button.modulate == Color.WHITE
		and action_bar.get_child_count() == original_child_count,
		"late attack-buffer window did not restore the existing button without adding UI"
	)


func _check_authored_combat_fx(view: Node, combat: Dictionary) -> void:
	var attack_fx := view.get_node_or_null("AttackFx") as CanvasItem
	var mask := view.get_node_or_null("AttackFx/AttackVisibilityMask") as Polygon2D
	var slash := view.get_node_or_null("AttackFx/AttackVisibilityMask/CombatSlash") as Sprite2D
	_require(
		attack_fx != null and attack_fx.is_visible_in_tree(),
		"authored_player_attack_fx_missing"
	)
	_require(
		slash != null
		and slash.texture != null
		and slash.centered
		and slash.texture.resource_path.contains("/assets/art24/fx/combat_slash_")
		and slash.texture.resource_path.ends_with(".png"),
		"player_attack_not_using_centered_audited_slash_frames"
	)
	var attack: Dictionary = combat.get("player_attack_geometry", {})
	var authored_points: Array = attack.get("visible_arc_points", [])
	var mask_matches := mask != null and mask.polygon.size() == authored_points.size() + 1
	if mask_matches:
		var expected_origin := RuntimeLayout.local_to_world(Vector2(attack.get("origin", Vector2.ZERO)))
		mask_matches = mask.polygon[0].is_equal_approx(expected_origin)
		for index in range(authored_points.size()):
			var expected_point := RuntimeLayout.local_to_world(Vector2(authored_points[index]))
			mask_matches = mask_matches and mask.polygon[index + 1].is_equal_approx(expected_point)
	_require(mask_matches, "player_attack_mask_not_authoritative")
	if slash != null and slash.texture != null:
		var source_center := slash.texture.get_size() * 0.5
		var source_offset := (
			RoomRuntimeViewScript.SLASH_SOURCE_ORIGIN - source_center
		) * slash.scale
		var mapped_origin := slash.position + source_offset.rotated(slash.rotation)
		var expected_origin := RuntimeLayout.local_to_world(Vector2(attack.get("origin", Vector2.ZERO)))
		_require(
			mapped_origin.distance_to(expected_origin) <= 0.5,
			"player_attack_slash_origin_misaligned mapped=%s expected=%s" % [
				mapped_origin,
				expected_origin,
			]
		)
		var visibility_samples := _slash_visibility_samples(slash, mask)
		_require(
			int(visibility_samples.get("opaque", 0)) > 0
			and int(visibility_samples.get("inside_mask", 0)) >= 8,
			"player_attack_slash_has_no_renderable_pixels_inside_mask samples=%s"
			% visibility_samples
		)
		var enemy_view := view.get("enemy_views").get("hierarchy_enemy") as Node2D
		var identity := (
			enemy_view.get_node_or_null("HealthBarAnchor/IdentityLabel") as CanvasItem
			if enemy_view != null
			else null
		)
		var health := (
			enemy_view.get_node_or_null("HealthBarAnchor/HealthBackground") as CanvasItem
			if enemy_view != null
			else null
		)
		_require(
			_draws_after(identity, slash) and _draws_after(health, slash),
			"player_attack_fx_draws_over_enemy_status"
		)
	var source := FileAccess.get_file_as_string("res://scripts/gameplay/runtime/g41_room_runtime_view.gd")
	var draw_source := _function_source(source, "_draw_player_attack_geometry")
	_require(
		not draw_source.contains("draw_colored_polygon(")
		and not draw_source.contains("draw_arc("),
		"player_attack_still_uses_program_colored_sector"
	)

	var projectile_view := view.get("projectile_views").get("hierarchy_projectile") as Node2D
	var projectile_art := (
		projectile_view.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
		if projectile_view != null
		else null
	)
	var projectile_placeholder := (
		projectile_view.get_node_or_null("VisualRoot/ProgramPlaceholder") as CanvasItem
		if projectile_view != null
		else null
	)
	_require(
		projectile_art != null
		and projectile_art.texture != null
		and projectile_art.texture.resource_path.ends_with("/assets/art24/fx/ue_bat_bolt.png"),
		"projectile_not_using_audited_bolt_texture"
	)
	_require(
		projectile_placeholder == null or not projectile_placeholder.is_visible_in_tree(),
		"projectile_program_placeholder_visible"
	)


func _slash_visibility_samples(slash: Sprite2D, mask: Polygon2D) -> Dictionary:
	if slash == null or slash.texture == null or mask == null or mask.polygon.size() < 3:
		return {"opaque": 0, "inside_mask": 0}
	var image := slash.texture.get_image()
	if image == null or image.is_empty():
		return {"opaque": 0, "inside_mask": 0}
	var opaque := 0
	var inside_mask := 0
	var texture_size := Vector2(slash.texture.get_size())
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			if image.get_pixel(x, y).a <= 0.10:
				continue
			opaque += 1
			var sprite_local := Vector2(float(x) + 0.5, float(y) + 0.5)
			if slash.centered:
				sprite_local -= texture_size * 0.5
			var mask_local := mask.to_local(slash.to_global(sprite_local))
			if Geometry2D.is_point_in_polygon(mask_local, mask.polygon):
				inside_mask += 1
	return {
		"opaque": opaque,
		"inside_mask": inside_mask,
	}


func _has_authored_lock_overlay(
	sprite: Sprite2D,
	locked_door: Dictionary,
	available_door: Dictionary
) -> bool:
	if sprite == null or sprite.texture == null:
		return false
	var locked_path := AssetContract.path_for(StringName(locked_door.get("visual_key", &"")))
	var available_path := AssetContract.path_for(StringName(available_door.get("visual_key", &"")))
	if not locked_path.is_empty() and locked_path != available_path:
		return true
	if sprite.material is ShaderMaterial:
		return true
	for child in sprite.get_children():
		if child is Sprite2D and (child as Sprite2D).texture != null:
			return true
		if child is AnimatedSprite2D and (child as AnimatedSprite2D).sprite_frames != null:
			return true
		if child is CanvasItem and (child as CanvasItem).material is ShaderMaterial:
			return true
	return false


func _matching_occluder_descriptor(occluders: Array, expected: Rect2) -> Dictionary:
	for raw_occluder in occluders:
		if not raw_occluder is Dictionary:
			continue
		var occluder := raw_occluder as Dictionary
		var rect := Rect2(occluder.get("body_rect", occluder.get("occlusion_rect_local", Rect2())))
		if rect.is_equal_approx(expected):
			return occluder
	return {}


func _matching_render_occluder(root_node: Node, expected: Rect2) -> CanvasItem:
	for child in root_node.find_children("*", "CanvasItem", true, false):
		if not child is CanvasItem:
			continue
		var item := child as CanvasItem
		if not item.has_meta("occlusion_rect_local"):
			continue
		var rect := Rect2(item.get_meta("occlusion_rect_local", Rect2()))
		if rect.is_equal_approx(expected) and item.is_visible_in_tree():
			return item
	return null


func _collect_visible_debug_primitives(node: Node, result: Array[String]) -> void:
	for child in node.get_children():
		if (
			child is CanvasItem
			and (child as CanvasItem).is_visible_in_tree()
			and String(child.name) in ["ProgramPlaceholder", "StateLabel", "RuntimeState", "Body"]
		):
			result.append(String(child.get_path()))
		_collect_visible_debug_primitives(child, result)


func _transformed_sprite_rect(sprite: Sprite2D) -> Rect2:
	if sprite == null or sprite.texture == null:
		return Rect2()
	return _transformed_rect(sprite.get_rect(), sprite.get_global_transform())


func _transformed_rect(local_rect: Rect2, transform: Transform2D) -> Rect2:
	var corners := [
		transform * local_rect.position,
		transform * Vector2(local_rect.end.x, local_rect.position.y),
		transform * local_rect.end,
		transform * Vector2(local_rect.position.x, local_rect.end.y),
	]
	var minimum: Vector2 = corners[0]
	var maximum: Vector2 = corners[0]
	for point in corners:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


func _rects_overlap_with_area(a: Rect2, b: Rect2) -> bool:
	var overlap := a.intersection(b)
	return overlap.size.x > RECT_EPSILON and overlap.size.y > RECT_EPSILON


func _draws_after(candidate: CanvasItem, reference: CanvasItem) -> bool:
	if candidate == null or reference == null:
		return false
	var candidate_z := _effective_z(candidate)
	var reference_z := _effective_z(reference)
	if candidate_z != reference_z:
		return candidate_z > reference_z
	return candidate.is_greater_than(reference)


func _effective_z(item: CanvasItem) -> int:
	var total := 0
	var current: CanvasItem = item
	while current != null:
		total += current.z_index
		if not current.z_as_relative:
			break
		current = current.get_parent() as CanvasItem
	return total


func _door_approach_position(body: Rect2, direction: Vector2i) -> Vector2:
	var position := body.get_center()
	if direction.x < 0:
		position.x = body.end.x + 0.01
	elif direction.x > 0:
		position.x = body.position.x - 0.01
	elif direction.y < 0:
		position.y = body.end.y + 0.01
	elif direction.y > 0:
		position.y = body.position.y - 0.01
	return position


func _door_for(doors: Array, direction: Vector2i) -> Dictionary:
	for raw_door in doors:
		if not raw_door is Dictionary:
			continue
		var door := raw_door as Dictionary
		if Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO)) == direction:
			return door
	return {}


func _enemy_for(enemies: Array, enemy_id: String) -> Dictionary:
	for raw_enemy in enemies:
		if raw_enemy is Dictionary and String((raw_enemy as Dictionary).get("enemy_id", "")) == enemy_id:
			return raw_enemy as Dictionary
	return {}


func _function_source(source: String, function_name: String) -> String:
	var marker := "func %s(" % function_name
	var start := source.find(marker)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + marker.length())
	return source.substr(start) if next < 0 else source.substr(start, next - start)


func _monster_public_snapshot() -> Dictionary:
	var cells: Array[Dictionary] = []
	for y in range(3):
		for x in range(3):
			cells.append({
				"pos": Vector2i(x, y),
				"revealed": true,
				"flagged": false,
			})
	return {
		"position": Vector2i(1, 1),
		"player_pos": Vector2i(1, 1),
		"width": 3,
		"height": 3,
		"current_room": &"Monster",
		"run_start_config": {"move_requires_revealed": false},
		"room_floor_items": [],
		"inventory_items": [],
		"run_map_snapshot": {"KnownMap": {"public_cells": cells, "read_only": true}},
	}


func _combat_visual_fixture() -> Dictionary:
	var attack_origin := Vector2(0.285, 0.33)
	var attack_facing := Vector2.RIGHT
	var attack_half_angle := acos(CombatSimulationScript.PLAYER_ATTACK_CONE_DOT)
	var visibility_simulation = CombatSimulationScript.new()
	visibility_simulation.set_arena_obstacles(CombatSimulationScript.production_arena_obstacles())
	var visibility: Dictionary = visibility_simulation.call(
		"_build_attack_visibility_contract",
		attack_origin,
		attack_facing,
		CombatSimulationScript.PLAYER_ATTACK_RANGE,
		attack_half_angle
	)
	return {
		"tick": 18,
		"door_locked": true,
		"arena_contract": CombatSimulationScript.ARENA_CONTRACT_ID,
		"arena_obstacles": CombatSimulationScript.production_arena_obstacles(),
		"player_attack_geometry": {
			"attack_id": "hierarchy_attack",
			"origin": attack_origin,
			"facing": attack_facing,
			"range": CombatSimulationScript.PLAYER_ATTACK_RANGE,
			"half_angle_radians": attack_half_angle,
			"phase": &"attack_active",
			"visible": true,
			"started_tick": 14,
			"occlusion_contract": CombatSimulationScript.ARENA_CONTRACT_ID,
			"visible_arc_points": visibility.get("visible_arc_points", []),
			"occlusion_samples": visibility.get("occlusion_samples", []),
			"occluded_sample_count": int(visibility.get("occluded_sample_count", 0)),
		},
		"enemies": [
			{
				"enemy_id": "hierarchy_enemy",
				"monster_type": &"slime",
				"pos": Vector2(0.50, 0.33),
				"hp": 20,
				"max_hp": 20,
				"enemy_name": "滞留工偶",
				"enemy_power": 12,
				"body_radius": 0.03,
				"attack_radius": 0.14,
				"warning_radius": 0.14,
				"state": &"warning",
			},
		],
		"projectiles": [
			{
				"projectile_id": "hierarchy_projectile",
				"pos": Vector2(0.74, 0.28),
				"radius": CombatSimulationScript.PROJECTILE_RADIUS,
				"visual_radius": CombatSimulationScript.PROJECTILE_RADIUS,
				"velocity": Vector2(-0.30, 0.10),
				"state": &"active",
			},
		],
		"lasers": [],
	}


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if main != null and is_instance_valid(main):
		main.free()
	main = null
	run_scene = null
	if failures.is_empty():
		print(
			PASS_MARKER
			+ " room=production monster hierarchy=door_occluded,prompt_clear,authored_lock"
			+ " occluders=altar,warning enemy_hud=name,power,readable_hp"
			+ " attack_cooldown=existing_button_only fx=slash,bolt debug_primitives=none"
		)
		quit(0)
		return
	for failure in failures:
		push_error("I3R combat-room visual hierarchy failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(2)
