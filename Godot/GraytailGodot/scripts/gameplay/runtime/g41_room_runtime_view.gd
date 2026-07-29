extends Node2D
class_name G41RoomRuntimeView

signal context_action_requested(action: StringName, payload: Dictionary)
signal room_entry_feedback_requested(feedback: Dictionary)

const GroundLootEntityScript := preload("res://scripts/gameplay/loot/g41_ground_loot_entity.gd")
const ChestInteractableScript := preload("res://scripts/gameplay/interactables/g41_chest_interactable.gd")
const ActorViewScript := preload("res://scripts/gameplay/runtime/g41_runtime_actor_view.gd")
const WorldContextPopupScript := preload("res://scripts/gameplay/interaction/g41_world_context_popup.gd")
const WorldObjectProjectionScript := preload("res://scripts/gameplay/runtime/g41_world_object_projection.gd")
const InteractableScript := preload("res://scripts/gameplay/interaction/g41_interactable.gd")
const Art24MotionSettingsScript := preload("res://scripts/presentation/art24/art24_motion_settings.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art24InRunAssetContractScript := preload("res://scripts/presentation/art24/art24_in_run_asset_contract.gd")
const CombatSimulationScript := preload("res://scripts/gameplay/combat/g41_combat_simulation.gd")
const EVENT_BADGE_TEXTURES := {
	&"trader": preload("res://assets/ui/art25/content/long_term/event/trader.png"),
	&"dice": preload("res://assets/ui/art25/content/long_term/event/dice.png"),
	&"altar": preload("res://assets/ui/art25/content/long_term/event/altar.png"),
	&"trap": preload("res://assets/ui/art25/content/long_term/event/trap.png"),
}
const MINE_TRAP_TEXTURE := preload("res://assets/props/mine_trap.png")
const MINE_BURST_TEXTURES := [
	preload("res://assets/art24/fx/mine_burst_0.png"),
	preload("res://assets/art24/fx/mine_burst_1.png"),
	preload("res://assets/art24/fx/mine_burst_2.png"),
	preload("res://assets/art24/fx/mine_burst_3.png"),
	preload("res://assets/art24/fx/mine_burst_4.png"),
	preload("res://assets/art24/fx/mine_burst_5.png"),
]
const BEACON_PULSE_TEXTURES := [
	preload("res://assets/art24/fx/beacon_pulse_0.png"),
	preload("res://assets/art24/fx/beacon_pulse_1.png"),
	preload("res://assets/art24/fx/beacon_pulse_2.png"),
	preload("res://assets/art24/fx/beacon_pulse_3.png"),
	preload("res://assets/art24/fx/beacon_pulse_4.png"),
	preload("res://assets/art24/fx/beacon_pulse_5.png"),
	preload("res://assets/art24/fx/beacon_pulse_6.png"),
	preload("res://assets/art24/fx/beacon_pulse_7.png"),
]
const COMBAT_SLASH_TEXTURES := [
	preload("res://assets/art24/fx/combat_slash_0.png"),
	preload("res://assets/art24/fx/combat_slash_1.png"),
	preload("res://assets/art24/fx/combat_slash_2.png"),
	preload("res://assets/art24/fx/combat_slash_3.png"),
	preload("res://assets/art24/fx/combat_slash_4.png"),
	preload("res://assets/art24/fx/combat_slash_5.png"),
]
const COMBAT_LOCK_TEXTURE := preload("res://assets/art24/ui/ue/stat_locked.png")
const MINE_FEEDBACK_DURATION := 0.27
const MINE_BURST_FRAME_DURATION := 0.045
const MINE_RESOLVED_MODULATE := Color(0.30, 0.42, 0.44, 0.48)
const MINE_RESOLVED_FOCUSED_MODULATE := Color(0.42, 0.56, 0.56, 0.62)
const EXIT_PULSE_FRAME_DURATION := 0.085
const FOCUS_EXIT_MARGIN := 0.025
const FOCUS_SWITCH_MARGIN := 0.025
const FOCUS_MIN_RESIDENCE_SECONDS := 0.12
const FOCUS_LOST_GRACE_SECONDS := 0.10
const EXIT_PULSE_FRAME_COUNT := 8
const MINE_BURST_FRAME_COUNT := 6
const DOOR_FOREGROUND_Z := 60
const ALTAR_FOREGROUND_Z := 40
const ACTOR_FOREGROUND_Z := 50
const ATTACK_FX_Z := 20
const COMBAT_LOCK_ICON_SIZE := 36.0
const SIDE_DOOR_PROMPT_LIFT_LOCAL := 0.16
const SOUTH_DOOR_PROMPT_LIFT_LOCAL := 0.09
# The generated slash frames are centered on the ellipse at (131, 95).
# Sprite2D is centered on the texture, so the authored origin must be mapped
# back onto the authoritative attack origin instead of subtracting it twice.
const SLASH_SOURCE_ORIGIN := Vector2(131.0, 95.0)
const SLASH_SOURCE_RADIUS := 113.0
var room_key: String = ""
var projection_room_key: String = ""
var room_type: StringName = &"Unknown"
var chest
var ground_loot_entities: Dictionary = {}
var departing_ground_loot_entities: Dictionary = {}
var enemy_views: Dictionary = {}
var projectile_views: Dictionary = {}
var special_entities: Dictionary = {}
var focused_interaction_id: String = ""
var focus_residence_elapsed := 0.0
var focus_lost_elapsed := 0.0
var combat_snapshot: Dictionary = {}
var latest_room_snapshot: Dictionary = {}
var world_projection: Dictionary = {}
var door_projections: Array[Dictionary] = []
var door_visuals: Dictionary = {}
var foreground_occluders: Dictionary = {}
var logical_obstacles: Array[Rect2] = []
var obstacle_descriptors: Array[Dictionary] = []
var context_popup: G41WorldContextPopup
var last_door_locked: bool = false
var last_combat_geometry_visible := false
var door_projection_revision: int = 0
var context_ui_suppressed: bool = false
var last_player_local_pos := Vector2(0.5, 0.5)
var last_room_entry_result: Dictionary = {}
var last_room_entry_signature := ""
var mine_feedback_remaining := 0.0
var mine_feedback_elapsed := 0.0
var mine_feedback_frame := -1
var exit_pulse_elapsed := 0.0
var exit_pulse_frame := -1
var nearby_available_door := Vector2i.ZERO
var nearby_door_direction := Vector2i.ZERO
var nearby_door_state: StringName = &""


func _ready() -> void:
	_ensure_layers()


func configure_room(snapshot: Dictionary) -> void:
	latest_room_snapshot = snapshot.duplicate(true)
	var pos: Vector2i = snapshot.get("position", Vector2i.ZERO)
	if not last_room_entry_result.is_empty() and Vector2i(last_room_entry_result.get("position", pos)) != pos:
		last_room_entry_result.clear()
		last_room_entry_signature = ""
	room_key = "%d,%d" % [pos.x, pos.y]
	room_type = StringName(snapshot.get("current_room", &"Unknown"))
	if room_type != &"Mine":
		mine_feedback_remaining = 0.0
		var mine_burst := get_node_or_null("SpecialRoomFx/MineBurst") as Sprite2D
		if mine_burst != null:
			mine_burst.visible = false
	if room_type != &"Exit":
		exit_pulse_elapsed = 0.0
		exit_pulse_frame = -1
	_ensure_layers()
	_rebuild_world_projection()
	_update_available_door_cue(last_player_local_pos)
	_update_visual_depths(last_player_local_pos)
	if room_type == &"Mine" and not last_room_entry_result.is_empty():
		_present_room_entry_result(last_room_entry_result)
	_update_door_prompt()
	queue_redraw()


func advance(delta: float, player_local_pos: Vector2, next_combat_snapshot: Dictionary = {}) -> void:
	last_player_local_pos = player_local_pos
	if chest != null:
		chest.advance(delta)
	_advance_special_visuals(delta)
	_update_focus(player_local_pos, delta)
	apply_combat_snapshot(next_combat_snapshot)
	_update_available_door_cue(player_local_pos)
	_update_visual_depths(player_local_pos)


func set_context_ui_suppressed(suppressed: bool) -> void:
	context_ui_suppressed = suppressed
	if context_ui_suppressed and context_popup != null:
		context_popup.clear_context()
	for special in special_entities.values():
		_apply_special_focus_visual(special)
	if not context_ui_suppressed:
		_update_focus(last_player_local_pos)


func request_nearest_interaction(player_local_pos: Vector2, allow_visible_focus_grace: bool = false) -> Dictionary:
	var nearest = _nearest_actionable_interactable(player_local_pos, allow_visible_focus_grace)
	if nearest == null:
		return {
			"accepted": false,
			"reason": &"no_interactable_in_range",
			"interaction_kind": &"none",
		}
	var request: Dictionary = nearest.build_interaction_request()
	if StringName(request.get("interaction_kind", &"none")) == &"chest":
		if chest == null:
			return {"accepted": false, "reason": &"chest_unavailable", "interaction_kind": &"chest"}
		return chest.build_search_intent()
	return request


func apply_room_entry_result(entry_result: Dictionary) -> void:
	if StringName(entry_result.get("room_type", &"Unknown")) != &"Mine":
		return
	last_room_entry_result = entry_result.duplicate(true)
	if room_type == &"Mine":
		_present_room_entry_result(last_room_entry_result)


func show_pickup_result(instance_id: String, ok: bool) -> void:
	var entity = ground_loot_entities.get(instance_id)
	if entity == null:
		entity = departing_ground_loot_entities.get(instance_id)
	if entity != null:
		entity.set_pickup_result(ok)


func show_context_result(result: Dictionary) -> void:
	if context_popup != null:
		context_popup.show_command_result(result)


func activate_context_primary() -> bool:
	return context_popup != null and context_popup.activate_primary()


func apply_chest_search_result(result: Dictionary, snapshot: Dictionary) -> void:
	configure_room(snapshot)
	if chest == null:
		return
	chest.apply_search_result(bool(result.get("ok", false)))
	_refresh_context_popup(last_player_local_pos, chest if chest.can_interact_from(last_player_local_pos) else null)


func apply_combat_snapshot(snapshot: Dictionary) -> void:
	var next_door_locked := bool(snapshot.get("door_locked", false))
	var door_state_changed := door_projections.is_empty() or next_door_locked != last_door_locked
	var next_combat_geometry_visible := _has_visible_combat_geometry(snapshot)
	var combat_geometry_changed := next_combat_geometry_visible or last_combat_geometry_visible
	combat_snapshot = snapshot
	var active_ids: Dictionary = {}
	for raw_enemy in (snapshot.get("enemies", []) as Array):
		if not (raw_enemy is Dictionary):
			continue
		var enemy := raw_enemy as Dictionary
		var enemy_id := String(enemy.get("enemy_id", ""))
		if enemy_id.is_empty():
			continue
		active_ids[enemy_id] = true
		var view = enemy_views.get(enemy_id)
		if view == null:
			view = ActorViewScript.new()
			view.name = _safe_node_name("Enemy_" + enemy_id)
			get_node("CombatVisuals/Enemies").add_child(view)
			enemy_views[enemy_id] = view
		view.configure(StringName(enemy.get("monster_type", &"slime")), enemy)
		_apply_actor_depth(view, Vector2(enemy.get("pos", Vector2(0.5, 0.5))))
	_remove_missing_views(enemy_views, active_ids)

	active_ids.clear()
	for raw_projectile in (snapshot.get("projectiles", []) as Array):
		if not (raw_projectile is Dictionary):
			continue
		var projectile := raw_projectile as Dictionary
		var projectile_id := String(projectile.get("projectile_id", ""))
		if projectile_id.is_empty():
			continue
		active_ids[projectile_id] = true
		var view = projectile_views.get(projectile_id)
		if view == null:
			view = ActorViewScript.new()
			view.name = _safe_node_name("Projectile_" + projectile_id)
			get_node("CombatVisuals/Projectiles").add_child(view)
			projectile_views[projectile_id] = view
		view.configure_projectile(projectile)
		_apply_actor_depth(view, Vector2(projectile.get("pos", Vector2(0.5, 0.5))))
	_remove_missing_views(projectile_views, active_ids)
	_sync_player_attack_visual(snapshot)
	if door_state_changed:
		_rebuild_door_projection()
		_update_available_door_cue(last_player_local_pos)
		_update_door_prompt()
	if door_state_changed or combat_geometry_changed:
		queue_redraw()
	last_door_locked = next_door_locked
	last_combat_geometry_visible = next_combat_geometry_visible


func build_read_only_snapshot() -> Dictionary:
	var interactables: Array[Dictionary] = []
	if chest != null:
		interactables.append(chest.build_snapshot())
	for instance_id in ground_loot_entities:
		var entity = ground_loot_entities[instance_id]
		if entity != null:
			interactables.append(entity.build_snapshot())
	for projection_id in special_entities:
		var special = special_entities[projection_id]
		if special != null:
			interactables.append(special.build_snapshot())
	return {
		"room_key": room_key,
		"room_type": room_type,
		"focused_interaction_id": focused_interaction_id,
		"departing_ground_loot_ids": departing_ground_loot_entities.keys(),
		"interactables": interactables,
		"combat": combat_snapshot.duplicate(true),
		"door_locked": bool(combat_snapshot.get("door_locked", false)),
		"world_projection": world_projection.duplicate(true),
		"doors": door_projections.duplicate(true),
		"door_projection_revision": door_projection_revision,
		"nearby_available_door": nearby_available_door,
		"nearby_door_direction": nearby_door_direction,
		"nearby_door_state": nearby_door_state,
		"logical_obstacles": logical_obstacles.duplicate(),
		"obstacle_descriptors": obstacle_descriptors.duplicate(true),
		"room_entry_result": last_room_entry_result.duplicate(true),
		"mine_feedback_active": mine_feedback_remaining > 0.0,
		"visual_contract_id": &"g41.runtime_visual.v1",
	}


func attach_context_popup(ui_parent: Control) -> void:
	if context_popup == null or ui_parent == null:
		return
	if context_popup.get_parent() == ui_parent:
		return
	context_popup.reparent(ui_parent, false)
	context_popup.z_as_relative = true
	context_popup.z_index = 80


func get_logical_obstacles() -> Array[Rect2]:
	return logical_obstacles.duplicate()


func get_obstacle_descriptors() -> Array[Dictionary]:
	return obstacle_descriptors.duplicate(true)


func get_door_projections() -> Array[Dictionary]:
	return door_projections.duplicate(true)


func clear_runtime() -> void:
	latest_room_snapshot.clear()
	combat_snapshot.clear()
	world_projection.clear()
	door_projections.clear()
	door_projection_revision = 0
	room_key = ""
	projection_room_key = ""
	room_type = &"Unknown"
	logical_obstacles.clear()
	obstacle_descriptors.clear()
	focused_interaction_id = ""
	focus_residence_elapsed = 0.0
	focus_lost_elapsed = 0.0
	last_door_locked = false
	last_combat_geometry_visible = false
	nearby_available_door = Vector2i.ZERO
	nearby_door_direction = Vector2i.ZERO
	nearby_door_state = &""
	last_room_entry_result.clear()
	last_room_entry_signature = ""
	mine_feedback_remaining = 0.0
	mine_feedback_elapsed = 0.0
	mine_feedback_frame = -1
	exit_pulse_elapsed = 0.0
	exit_pulse_frame = -1
	if chest != null:
		chest.queue_free()
		chest = null
	for dictionary in [door_visuals, foreground_occluders, ground_loot_entities, departing_ground_loot_entities, special_entities, enemy_views, projectile_views]:
		for key in dictionary.keys():
			var node := dictionary[key] as Node
			if node != null:
				node.queue_free()
		dictionary.clear()
	if context_popup != null:
		context_popup.clear_context()
	var attack_fx := get_node_or_null("AttackFx") as CanvasItem
	if attack_fx != null:
		attack_fx.visible = false
	_update_visual_depths(last_player_local_pos)
	_update_door_prompt()
	queue_redraw()


func _rebuild_world_projection() -> void:
	var same_room := not projection_room_key.is_empty() and projection_room_key == room_key
	if not same_room:
		focused_interaction_id = ""
		focus_residence_elapsed = 0.0
		focus_lost_elapsed = 0.0
	world_projection = WorldObjectProjectionScript.build(latest_room_snapshot, combat_snapshot)
	_merge_room_entry_result_into_projection()
	door_projections = _dictionary_array(world_projection.get("doors", []))
	door_projection_revision += 1
	_sync_door_visuals()
	_sync_foreground_occluders(_dictionary_array(world_projection.get("occluders", [])))
	var objects := _dictionary_array(world_projection.get("world_objects", []))
	_sync_chest(objects)
	_sync_ground_loot(objects, same_room)
	_sync_special_objects(objects)
	projection_room_key = room_key
	_rebuild_obstacle_projection()


func _rebuild_door_projection() -> void:
	if latest_room_snapshot.is_empty():
		door_projections.clear()
		_sync_door_visuals()
		return
	var updated := WorldObjectProjectionScript.build(latest_room_snapshot, combat_snapshot)
	door_projections = _dictionary_array(updated.get("doors", []))
	world_projection["doors"] = door_projections.duplicate(true)
	door_projection_revision += 1
	_sync_door_visuals()


func _sync_door_visuals() -> void:
	_ensure_layers()
	var active_ids: Dictionary = {}
	for door in door_projections:
		var projection_id := String(door.get("projection_id", ""))
		if projection_id.is_empty():
			continue
		active_ids[projection_id] = true
		var sprite := door_visuals.get(projection_id) as Sprite2D
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.name = "Door_" + _safe_node_name(String(door.get("orientation", "unknown")))
			sprite.centered = false
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			get_node("DoorVisuals").add_child(sprite)
			door_visuals[projection_id] = sprite
		_apply_door_visual(sprite, door)
	for projection_id in door_visuals.keys():
		if active_ids.has(projection_id):
			continue
		var stale := door_visuals[projection_id] as Node
		if stale != null:
			stale.queue_free()
		door_visuals.erase(projection_id)


func _apply_door_visual(sprite: Sprite2D, door: Dictionary) -> void:
	var visual_key := StringName(door.get("visual_key", &""))
	var texture := Art24InRunAssetContractScript.texture(visual_key)
	sprite.texture = texture
	sprite.visible = texture != null
	sprite.set_meta("projection_id", String(door.get("projection_id", "")))
	sprite.set_meta("visual_key", visual_key)
	sprite.set_meta("pivot_normalized", Vector2(door.get("pivot_normalized", Vector2(0.5, 0.5))))
	sprite.set_meta("body_rect", Rect2(door.get("body_rect", Rect2())))
	if texture == null:
		sprite.region_enabled = false
		return
	var texture_size := texture.get_size()
	var normalized_region := Rect2(door.get(
		"texture_region_normalized",
		Rect2(Vector2.ZERO, Vector2.ONE)
	))
	var source_rect := Rect2(
		normalized_region.position * texture_size,
		normalized_region.size * texture_size
	)
	var visual_rect := _door_visual_rect_local(door)
	var world_size := G41RuntimeLayout.local_size_to_world(visual_rect.size)
	sprite.region_enabled = true
	sprite.region_rect = source_rect
	sprite.position = ActorViewScript.local_to_world(visual_rect.position)
	sprite.scale = Vector2(
		world_size.x / maxf(1.0, source_rect.size.x),
		world_size.y / maxf(1.0, source_rect.size.y)
	)
	sprite.set_meta("texture_region_normalized", normalized_region)
	sprite.set_meta("resolved_texture_path", texture.resource_path)
	_apply_combat_lock_overlay(sprite, door, source_rect)


func _apply_combat_lock_overlay(sprite: Sprite2D, door: Dictionary, source_rect: Rect2) -> void:
	var overlay := sprite.get_node_or_null("StateOverlay") as Sprite2D
	if overlay == null:
		overlay = Sprite2D.new()
		overlay.name = "StateOverlay"
		overlay.texture = COMBAT_LOCK_TEXTURE
		overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		overlay.z_index = 2
		sprite.add_child(overlay)
	var locked := StringName(door.get("visual_state", &"")) == &"combat_restricted"
	overlay.visible = locked
	sprite.set_meta("state_overlay_kind", &"texture" if locked else &"none")
	if not locked or overlay.texture == null:
		return
	overlay.position = source_rect.size * 0.5
	var source_size := overlay.texture.get_size()
	overlay.scale = Vector2(
		COMBAT_LOCK_ICON_SIZE / maxf(1.0, source_size.x * absf(sprite.scale.x)),
		COMBAT_LOCK_ICON_SIZE / maxf(1.0, source_size.y * absf(sprite.scale.y))
	)
	overlay.modulate = Color(1.0, 0.86, 0.72, 0.98)


func _door_visual_rect_local(door: Dictionary) -> Rect2:
	var anchor := Vector2(door.get("ground_anchor_local", door.get("local_pos", Vector2(0.5, 0.5))))
	var display_size := Vector2(door.get("display_size_local", Vector2(0.10, 0.10)))
	var pivot := Vector2(door.get("pivot_normalized", Vector2(0.5, 0.5)))
	return Rect2(anchor - display_size * pivot, display_size)


func _sync_foreground_occluders(occluders: Array[Dictionary]) -> void:
	_ensure_layers()
	var active_ids: Dictionary = {}
	for descriptor in occluders:
		var projection_id := String(descriptor.get("projection_id", ""))
		if projection_id.is_empty():
			continue
		active_ids[projection_id] = true
		var sprite := foreground_occluders.get(projection_id) as Sprite2D
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.name = "Occluder_" + _safe_node_name(projection_id)
			sprite.centered = false
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			get_node("ForegroundOccluders").add_child(sprite)
			foreground_occluders[projection_id] = sprite
		_apply_foreground_occluder(sprite, descriptor)
	for projection_id in foreground_occluders.keys():
		if active_ids.has(projection_id):
			continue
		var stale := foreground_occluders[projection_id] as Node
		if stale != null:
			stale.queue_free()
		foreground_occluders.erase(projection_id)


func _apply_foreground_occluder(sprite: Sprite2D, descriptor: Dictionary) -> void:
	var texture := Art24InRunAssetContractScript.texture(StringName(descriptor.get("visual_key", &"")))
	sprite.texture = texture
	sprite.visible = texture != null
	if texture == null:
		sprite.region_enabled = false
		return
	var texture_region := Rect2(descriptor.get("texture_region_normalized", Rect2()))
	var texture_size := texture.get_size()
	var source_rect := Rect2(
		texture_region.position * texture_size,
		texture_region.size * texture_size
	)
	var visual_rect := Rect2(descriptor.get("visual_rect_local", Rect2()))
	var world_size := G41RuntimeLayout.local_size_to_world(visual_rect.size)
	sprite.region_enabled = true
	sprite.region_rect = source_rect
	sprite.position = ActorViewScript.local_to_world(visual_rect.position)
	sprite.scale = Vector2(
		world_size.x / maxf(1.0, source_rect.size.x),
		world_size.y / maxf(1.0, source_rect.size.y)
	)
	var payload: Dictionary = descriptor.get("payload", {})
	sprite.set_meta("projection_id", String(descriptor.get("projection_id", "")))
	sprite.set_meta("occlusion_rect_local", Rect2(payload.get(
		"occlusion_rect_local",
		descriptor.get("body_rect", Rect2())
	)))
	sprite.set_meta("depth_split_local_y", float(payload.get(
		"depth_split_local_y",
		Rect2(descriptor.get("body_rect", Rect2())).end.y
	)))
	sprite.set_meta("masks_combat_geometry", bool(payload.get("masks_combat_geometry", true)))
	sprite.set_meta("resolved_texture_path", texture.resource_path)


func _sync_player_attack_visual(snapshot: Dictionary) -> void:
	var attack_fx := get_node_or_null("AttackFx") as Node2D
	var mask := get_node_or_null("AttackFx/AttackVisibilityMask") as Polygon2D
	var slash := get_node_or_null("AttackFx/AttackVisibilityMask/CombatSlash") as Sprite2D
	if attack_fx == null or mask == null or slash == null:
		return
	var geometry: Dictionary = snapshot.get("player_attack_geometry", {})
	if geometry.is_empty() or not bool(geometry.get("visible", false)):
		attack_fx.visible = false
		return
	var origin := ActorViewScript.local_to_world(Vector2(geometry.get("origin", Vector2.ZERO)))
	var arc := _player_attack_arc_world_points(geometry)
	if arc.size() < 2:
		attack_fx.visible = false
		return
	var visibility_polygon := PackedVector2Array([origin])
	for point in arc:
		visibility_polygon.append(point)
	mask.polygon = visibility_polygon
	var frame := _combat_slash_frame(snapshot, geometry)
	slash.texture = COMBAT_SLASH_TEXTURES[frame]
	var facing := Vector2(geometry.get("facing", Vector2.RIGHT)).normalized()
	if facing.length_squared() <= 0.000001:
		facing = Vector2.RIGHT
	var range_local := maxf(0.0, float(geometry.get("range", 0.0)))
	var range_pixels := G41RuntimeLayout.local_size_to_world(Vector2(range_local, range_local)).x
	var uniform_scale := range_pixels / SLASH_SOURCE_RADIUS
	var rotation := facing.angle()
	slash.scale = Vector2.ONE * uniform_scale
	slash.rotation = rotation
	var source_center := slash.texture.get_size() * 0.5
	var source_origin_offset := (SLASH_SOURCE_ORIGIN - source_center) * uniform_scale
	slash.position = origin - source_origin_offset.rotated(rotation)
	slash.modulate = Color(1.0, 1.0, 1.0, 0.94)
	mask.set_meta("occlusion_contract", geometry.get("occlusion_contract", &""))
	mask.set_meta("authoritative_visible_arc_points", geometry.get("visible_arc_points", []))
	attack_fx.visible = true


func _combat_slash_frame(snapshot: Dictionary, geometry: Dictionary) -> int:
	if Art24MotionSettingsScript.reduce_motion_enabled():
		return 4
	var tick := int(snapshot.get("tick", geometry.get("started_tick", 0)))
	var started_tick := int(geometry.get("started_tick", tick))
	var elapsed_ticks := maxi(0, tick - started_tick)
	var visible_ticks := maxi(1, int(ceil(
		(
			CombatSimulationScript.PLAYER_ATTACK_WINDUP
			+ CombatSimulationScript.PLAYER_ATTACK_ACTIVE
		) / CombatSimulationScript.FIXED_STEP
	)))
	return clampi(int(float(elapsed_ticks) / float(visible_ticks) * COMBAT_SLASH_TEXTURES.size()), 0, COMBAT_SLASH_TEXTURES.size() - 1)


func _update_visual_depths(player_local_pos: Vector2) -> void:
	var split_y := _foreground_depth_split()
	var has_foreground := room_type == &"Monster" and split_y < INF
	var player := _production_player_canvas_item()
	if player != null:
		player.z_index = ACTOR_FOREGROUND_Z if has_foreground and player_local_pos.y >= split_y else 0
	for view in enemy_views.values():
		if view is CanvasItem:
			_apply_actor_depth(view as CanvasItem, _actor_local_position(view))
	for view in projectile_views.values():
		if view is CanvasItem:
			_apply_actor_depth(view as CanvasItem, _actor_local_position(view))


func _apply_actor_depth(actor: CanvasItem, local_pos: Vector2) -> void:
	if actor == null:
		return
	var split_y := _foreground_depth_split()
	actor.z_index = (
		ACTOR_FOREGROUND_Z
		if room_type == &"Monster" and split_y < INF and local_pos.y >= split_y
		else 0
	)


func _foreground_depth_split() -> float:
	for sprite in foreground_occluders.values():
		if sprite is CanvasItem and (sprite as CanvasItem).is_visible():
			return float((sprite as CanvasItem).get_meta("depth_split_local_y", INF))
	return INF


func _actor_local_position(actor: Variant) -> Vector2:
	if actor is Node2D:
		var world_position := (actor as Node2D).position
		return Vector2(
			(world_position.x - G41RuntimeLayout.ROOM_RECT.position.x) / G41RuntimeLayout.ROOM_RECT.size.x,
			(world_position.y - G41RuntimeLayout.ROOM_RECT.position.y) / G41RuntimeLayout.ROOM_RECT.size.y
		)
	return Vector2.ZERO


func _production_player_canvas_item() -> CanvasItem:
	var room_layer := get_parent()
	var run_scene := room_layer.get_parent() if room_layer != null else null
	if run_scene == null:
		return null
	return run_scene.get_node_or_null("PlayerLayer/PlayerController") as CanvasItem


func _sync_chest(objects: Array[Dictionary]) -> void:
	var chest_projection := _first_projection(objects, &"chest")
	if chest_projection.is_empty():
		if chest != null:
			chest.queue_free()
			chest = null
		return
	if chest == null:
		chest = ChestInteractableScript.new()
		chest.name = "ChestInteractable"
		get_node("WorldInteractables").add_child(chest)
	chest.configure_chest(chest_projection)


func _sync_ground_loot(objects: Array[Dictionary], same_room: bool) -> void:
	if not same_room:
		for departing_id in departing_ground_loot_entities.keys():
			var departing_entity := departing_ground_loot_entities[departing_id] as Node
			if departing_entity != null:
				departing_entity.queue_free()
		departing_ground_loot_entities.clear()
	var active_ids: Dictionary = {}
	for projection in objects:
		if StringName(projection.get("interaction_kind", &"")) != &"ground_loot":
			continue
		var instance_id := String(projection.get("projection_id", ""))
		if instance_id.is_empty():
			continue
		active_ids[instance_id] = true
		var entity = ground_loot_entities.get(instance_id)
		if entity == null:
			var stale_departing := departing_ground_loot_entities.get(instance_id) as Node
			if stale_departing != null:
				stale_departing.queue_free()
				departing_ground_loot_entities.erase(instance_id)
			entity = GroundLootEntityScript.new()
			entity.name = _safe_node_name("GroundLoot_" + instance_id)
			get_node("WorldInteractables").add_child(entity)
			entity.feedback_finished.connect(_on_ground_loot_feedback_finished)
			ground_loot_entities[instance_id] = entity
		entity.configure_item(projection)
	for existing_id in ground_loot_entities.keys():
		if active_ids.has(existing_id):
			continue
		var entity = ground_loot_entities[existing_id]
		ground_loot_entities.erase(existing_id)
		if entity != null:
			if same_room:
				departing_ground_loot_entities[existing_id] = entity
				entity.begin_pickup_feedback()
			else:
				entity.queue_free()


func _on_ground_loot_feedback_finished(instance_id: String) -> void:
	var active_entity = ground_loot_entities.get(instance_id)
	if active_entity != null and active_entity.is_retiring():
		ground_loot_entities.erase(instance_id)
	departing_ground_loot_entities.erase(instance_id)


func _sync_special_objects(objects: Array[Dictionary]) -> void:
	var active_ids: Dictionary = {}
	for projection in objects:
		var kind := StringName(projection.get("interaction_kind", &""))
		if kind not in [&"event", &"mine", &"exit"]:
			continue
		var projection_id := String(projection.get("projection_id", ""))
		if projection_id.is_empty():
			continue
		active_ids[projection_id] = true
		var entity = special_entities.get(projection_id)
		if entity == null:
			entity = InteractableScript.new()
			entity.name = _safe_node_name("Special_" + projection_id)
			get_node("WorldInteractables").add_child(entity)
			special_entities[projection_id] = entity
		# Projection payloads are live read-only summaries. Reconfigure existing
		# nodes as Event completion or Exit resources change; this owns no command.
		entity.configure_interactable(projection)
		_apply_special_art(entity, projection)
	for existing_id in special_entities.keys():
		if active_ids.has(existing_id):
			continue
		var entity := special_entities[existing_id] as Node
		if entity != null:
			entity.queue_free()
		special_entities.erase(existing_id)


func _apply_special_art(entity, projection: Dictionary) -> void:
	if entity == null:
		return
	var visual_root := entity.get_node_or_null("VisualRoot") as Node2D
	if visual_root == null:
		return
	var sprite := visual_root.get_node_or_null("ArtVisual") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "ArtVisual"
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual_root.add_child(sprite)
	var kind := StringName(projection.get("interaction_kind", &""))
	var texture: Texture2D
	var uses_projected_geometry := false
	match kind:
		&"event":
			var event_type := StringName((projection.get("payload", {}) as Dictionary).get("event_type", &"trader"))
			texture = EVENT_BADGE_TEXTURES.get(event_type, EVENT_BADGE_TEXTURES[&"trader"]) as Texture2D
			sprite.scale = Vector2.ONE * 1.22
		&"mine":
			texture = MINE_TRAP_TEXTURE
			uses_projected_geometry = true
		&"exit":
			texture = BEACON_PULSE_TEXTURES[0]
			sprite.scale = Vector2.ONE * 0.32
	if texture != null and sprite.texture != texture and (kind != &"exit" or sprite.texture == null):
		sprite.texture = texture
	if uses_projected_geometry:
		_apply_projected_special_geometry(sprite, projection)
	var placeholder := visual_root.get_node_or_null("ProgramPlaceholder") as Polygon2D
	if placeholder != null:
		placeholder.visible = texture == null
	_apply_special_focus_visual(entity)


func _apply_projected_special_geometry(sprite: Sprite2D, projection: Dictionary) -> void:
	if sprite == null or sprite.texture == null:
		return
	var local_pos := Vector2(projection.get("local_pos", Vector2.ZERO))
	var ground_anchor := Vector2(projection.get("ground_anchor_local", local_pos))
	var pivot := Vector2(projection.get("pivot_normalized", Vector2(0.5, 0.5)))
	var display_size := Vector2(projection.get("display_size_local", Vector2.ZERO))
	var desired_size := G41RuntimeLayout.local_size_to_world(display_size)
	var texture_size := sprite.texture.get_size()
	sprite.scale = Vector2(
		desired_size.x / maxf(1.0, texture_size.x),
		desired_size.y / maxf(1.0, texture_size.y)
	)
	sprite.position = ActorViewScript.local_to_world(ground_anchor) - ActorViewScript.local_to_world(local_pos) + Vector2(
		(0.5 - pivot.x) * desired_size.x,
		(0.5 - pivot.y) * desired_size.y
	)
	sprite.rotation = 0.0


func _apply_special_focus_visual(entity) -> void:
	if entity == null:
		return
	var sprite := entity.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	if sprite == null:
		return
	var payload: Dictionary = entity.payload
	if StringName(entity.interaction_kind) == &"mine" and bool(payload.get("triggered", false)):
		sprite.modulate = MINE_RESOLVED_FOCUSED_MODULATE if bool(entity.focused) else MINE_RESOLVED_MODULATE
		_apply_special_prompt_visibility(entity)
		return
	var alpha := 1.0
	if StringName(entity.interaction_kind) == &"event" and bool(payload.get("completed", false)):
		alpha = 0.55
	sprite.modulate = Color(1.0, 0.96, 0.82, alpha) if entity.focused else Color(1.0, 1.0, 1.0, alpha)
	_apply_special_prompt_visibility(entity)


func _apply_special_prompt_visibility(entity) -> void:
	var payload: Dictionary = entity.payload
	var prompt := entity.get_node_or_null("PromptAnchor/InteractionPrompt") as Label
	if prompt != null:
		prompt.visible = (
			not context_ui_suppressed
			and bool(entity.focused)
			and bool(entity.enabled)
			and not bool(payload.get("display_only", false))
			and not _context_popup_owns_prompt(StringName(entity.interaction_kind))
		)


func _context_popup_owns_prompt(kind: StringName) -> bool:
	return (
		context_popup != null
		and context_popup.visible
		and context_popup.context_kind == kind
	)


func _refresh_special_prompt_visibility() -> void:
	for special in special_entities.values():
		_apply_special_focus_visual(special)


func _update_focus(player_local_pos: Vector2, delta: float = 0.0) -> void:
	var safe_delta := maxf(delta, 0.0)
	var nearest = _nearest_interactable(player_local_pos)
	var locked = _interactable_by_id(focused_interaction_id)
	if locked != null and _can_hold_focus(locked, player_local_pos):
		focus_lost_elapsed = 0.0
		focus_residence_elapsed += safe_delta
		if nearest == null:
			nearest = locked
		elif nearest != locked:
			var challenger_is_clearer := (
				float(nearest.distance_to_local(player_local_pos)) + FOCUS_SWITCH_MARGIN
				< float(locked.distance_to_local(player_local_pos))
			)
			if focus_residence_elapsed < FOCUS_MIN_RESIDENCE_SECONDS or not challenger_is_clearer:
				nearest = locked
	elif locked != null:
		focus_lost_elapsed += safe_delta
		if focus_lost_elapsed < FOCUS_LOST_GRACE_SECONDS:
			nearest = locked
	var next_focus_id := "" if nearest == null else String(nearest.interaction_id)
	if next_focus_id != focused_interaction_id:
		focus_residence_elapsed = 0.0
		focus_lost_elapsed = 0.0
	focused_interaction_id = next_focus_id
	if chest != null:
		chest.set_focused(chest == nearest)
	for instance_id in ground_loot_entities:
		var entity = ground_loot_entities[instance_id]
		if entity != null:
			entity.set_focused(entity == nearest)
	for projection_id in special_entities:
		var special = special_entities[projection_id]
		if special != null:
			special.set_focused(special == nearest)
			_apply_special_focus_visual(special)
	_refresh_context_popup(player_local_pos, nearest)


func _update_available_door_cue(player_local_pos: Vector2) -> void:
	var next_direction := Vector2i.ZERO
	var next_state: StringName = &""
	var nearest_distance := INF
	for door in door_projections:
		var body_rect: Rect2 = door.get("body_rect", Rect2())
		var anchor := Vector2(door.get("ground_anchor_local", body_rect.get_center()))
		var interaction_radius := maxf(0.0, float(door.get("interaction_radius", 0.0)))
		var distance := anchor.distance_to(player_local_pos)
		if distance > interaction_radius and not body_rect.has_point(player_local_pos):
			continue
		if distance >= nearest_distance:
			continue
		nearest_distance = distance
		next_direction = Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO))
		next_state = StringName(door.get("visual_state", &"blocked_out_of_bounds"))
	var next_available := next_direction if next_state == &"available" else Vector2i.ZERO
	if nearby_door_direction == next_direction and nearby_door_state == next_state and nearby_available_door == next_available:
		return
	nearby_door_direction = next_direction
	nearby_door_state = next_state
	nearby_available_door = next_available
	_update_door_prompt()
	queue_redraw()


func _refresh_context_popup(player_local_pos: Vector2, nearest = null) -> void:
	if context_popup == null:
		return
	if context_ui_suppressed:
		context_popup.clear_context()
		return
	if nearest == null:
		nearest = _nearest_interactable(player_local_pos)
	if nearest == null:
		context_popup.clear_context()
		return
	var items: Array[Dictionary] = []
	var kind := StringName(nearest.interaction_kind)
	if kind == &"ground_loot":
		for instance_id in ground_loot_entities:
			var entity = ground_loot_entities[instance_id]
			if entity != null and (entity == nearest or entity.can_interact_from(player_local_pos)):
				items.append(entity.item.duplicate(true))
	elif kind == &"chest" and chest != null and chest.is_opened():
		for raw_item in (world_projection.get("chest_contents", []) as Array):
			if raw_item is Dictionary:
				items.append((raw_item as Dictionary).duplicate(true))
	var public_payload: Dictionary = nearest.payload.duplicate(true)
	if kind == &"mine" and not last_room_entry_result.is_empty():
		public_payload["entry_result"] = last_room_entry_result.duplicate(true)
		public_payload["triggered"] = bool(public_payload.get("triggered", false)) or bool(last_room_entry_result.get("first_trigger", false)) or StringName(last_room_entry_result.get("cause", &"")) == &"mine_inactive"
	var anchor_ui: Vector2 = nearest.get_context_anchor_world()
	var player_ui: Vector2 = anchor_ui
	var gameplay_focus_ui_rect := Rect2()
	var nearest_canvas := nearest as CanvasItem
	var popup_parent := context_popup.get_parent() as CanvasItem
	if nearest_canvas != null and popup_parent != null:
		# Interactables are transformed by the ScaleToFit room layer, while the
		# popup is reparented to an unscaled full-screen UI overlay.  Passing the
		# interactable's room-local position directly made the card avoid a phantom
		# target and cover the item in the actual game.  Convert both through canvas
		# space so the visual entity is the target used by the layout decision.
		# get_global_transform_with_canvas() also includes the final stretch from
		# the 1280x720 logical viewport into the embedded/native window.  UI Control
		# positions are still authored in logical pixels, so including that stretch
		# scales the anchor twice.  The regular global transforms put both branches
		# in the same logical coordinate system.
		var target_local_position: Vector2 = nearest.get_context_anchor_world()
		var nearest_parent := nearest.get_parent() as CanvasItem
		var target_logical_position := nearest_canvas.get_global_transform().origin
		if nearest_parent != null:
			target_logical_position = nearest_parent.get_global_transform() * target_local_position
		anchor_ui = popup_parent.get_global_transform().affine_inverse() * target_logical_position
		var player_logical_position := get_global_transform() * ActorViewScript.local_to_world(player_local_pos)
		player_ui = popup_parent.get_global_transform().affine_inverse() * player_logical_position
		var popup_inverse := popup_parent.get_global_transform().affine_inverse()
		var room_top_left := popup_inverse * (get_global_transform() * G41RuntimeLayout.ROOM_RECT.position)
		var room_bottom_right := popup_inverse * (get_global_transform() * G41RuntimeLayout.ROOM_RECT.end)
		gameplay_focus_ui_rect = Rect2(
			Vector2(
				minf(room_top_left.x, room_bottom_right.x),
				minf(room_top_left.y, room_bottom_right.y)
			),
			Vector2(
				absf(room_bottom_right.x - room_top_left.x),
				absf(room_bottom_right.y - room_top_left.y)
			)
		)
	var overlay_size := Vector2(1280, 720)
	var popup_parent_control := context_popup.get_parent() as Control
	if popup_parent_control != null and popup_parent_control.size.x > 0.0 and popup_parent_control.size.y > 0.0:
		overlay_size = popup_parent_control.size
	context_popup.apply_context({
		"interaction_kind": kind,
		"world_pos": anchor_ui,
		"player_world_pos": player_ui,
		"room_bounds": G41RuntimeLayout.context_ui_rect_for_viewport(overlay_size),
		"gameplay_focus_rect": gameplay_focus_ui_rect,
		"reserved_rects": G41RuntimeLayout.context_reserved_rects_for_viewport(overlay_size),
		"items": items,
		"opened_once": chest != null and chest.is_opened() if kind == &"chest" else false,
		"container_open": chest != null and chest.is_opened() if kind == &"chest" else false,
		"backpack_remaining": int(latest_room_snapshot.get("backpack_remaining", 0)),
		"inventory_items": latest_room_snapshot.get("inventory_items", []),
		"payload": public_payload,
	})


func _nearest_interactable(player_local_pos: Vector2):
	# Chest rooms intentionally suppress floor entities for their container
	# contents, so the single projected chest remains the only focus target.
	if chest != null and chest.can_interact_from(player_local_pos):
		return chest
	var nearest = null
	var nearest_distance := INF
	var candidates: Array = []
	if chest != null:
		candidates.append(chest)
	for instance_id in ground_loot_entities:
		var entity = ground_loot_entities[instance_id]
		if entity != null:
			candidates.append(entity)
	for projection_id in special_entities:
		var special = special_entities[projection_id]
		if special != null:
			candidates.append(special)
	for candidate in candidates:
		var distance: float = float(candidate.distance_to_local(player_local_pos))
		if not candidate.can_interact_from(player_local_pos) or distance >= nearest_distance:
			continue
		nearest = candidate
		nearest_distance = distance
	return nearest


func _nearest_actionable_interactable(player_local_pos: Vector2, allow_visible_focus_grace: bool = false):
	# The proximity surface may focus read-only hazards, but an explicit input
	# must never turn that observation into an implicit room command.
	var locked = _interactable_by_id(focused_interaction_id)
	# Focus deliberately has a small exit margin to keep the visible context card
	# and a brief lost-target grace period to prevent flicker. While that
	# actionable card is still visibly locked, the real keyboard interaction may
	# opt into the same contract. Legacy buttons and domain callers keep the
	# default strict radius so stale UI cannot bypass proximity authority.
	if (
		_is_actionable_interactable(locked)
		and (
			locked.can_interact_from(player_local_pos)
			or (
				allow_visible_focus_grace
				and context_popup != null
				and context_popup.visible
			)
		)
	):
		return locked
	var nearest = null
	var nearest_distance := INF
	var candidates: Array = []
	if chest != null:
		candidates.append(chest)
	for instance_id in ground_loot_entities:
		var ground = ground_loot_entities[instance_id]
		if ground != null:
			candidates.append(ground)
	for projection_id in special_entities:
		var special = special_entities[projection_id]
		if special != null and not bool(special.payload.get("display_only", false)):
			candidates.append(special)
	for candidate in candidates:
		var distance: float = float(candidate.distance_to_local(player_local_pos))
		if not candidate.can_interact_from(player_local_pos) or distance >= nearest_distance:
			continue
		nearest = candidate
		nearest_distance = distance
	return nearest


func _interactable_by_id(interaction_id: String):
	if interaction_id.is_empty():
		return null
	if chest != null and chest.interaction_id == interaction_id:
		return chest
	var ground = ground_loot_entities.get(interaction_id)
	if ground != null:
		return ground
	for special in special_entities.values():
		if special != null and special.interaction_id == interaction_id:
			return special
	return null


func _can_hold_focus(candidate, player_local_pos: Vector2) -> bool:
	return (
		candidate != null
		and bool(candidate.enabled)
		and float(candidate.distance_to_local(player_local_pos)) <= float(candidate.interaction_radius) + FOCUS_EXIT_MARGIN
	)


func _is_actionable_interactable(candidate) -> bool:
	return (
		candidate != null
		and bool(candidate.enabled)
		and not bool(candidate.payload.get("display_only", false))
	)


func _present_room_entry_result(entry_result: Dictionary) -> void:
	if room_type != &"Mine" or not _entry_result_matches_current(entry_result):
		return
	_merge_room_entry_result_into_projection()
	var objects := _dictionary_array(world_projection.get("world_objects", []))
	var mine_projection := _first_projection(objects, &"mine")
	if not mine_projection.is_empty():
		var mine_entity = special_entities.get(String(mine_projection.get("projection_id", "")))
		if mine_entity != null:
			mine_entity.configure_interactable(mine_projection)
			_apply_special_art(mine_entity, mine_projection)
	var signature := _room_entry_signature(entry_result)
	if signature == last_room_entry_signature:
		_refresh_context_popup(last_player_local_pos)
		return
	last_room_entry_signature = signature
	var feedback := entry_result.duplicate(true)
	feedback["presentation_only"] = true
	room_entry_feedback_requested.emit(feedback)
	if bool(entry_result.get("first_trigger", false)) and int(entry_result.get("hp_delta", 0)) < 0:
		_start_mine_feedback()
	_refresh_context_popup(last_player_local_pos)


func _merge_room_entry_result_into_projection() -> void:
	if last_room_entry_result.is_empty() or room_type != &"Mine" or not _entry_result_matches_current(last_room_entry_result):
		return
	var objects := _dictionary_array(world_projection.get("world_objects", []))
	for index in range(objects.size()):
		if StringName(objects[index].get("interaction_kind", &"")) != &"mine":
			continue
		var projection := objects[index].duplicate(true)
		var payload: Dictionary = projection.get("payload", {})
		payload["triggered"] = true
		payload["summary"] = "已触发，不会再次造成伤害。"
		payload["entry_result"] = last_room_entry_result.duplicate(true)
		projection["payload"] = payload
		projection["visual_state"] = &"resolved"
		objects[index] = projection
		break
	world_projection["world_objects"] = objects


func _entry_result_matches_current(entry_result: Dictionary) -> bool:
	if StringName(entry_result.get("room_type", &"Unknown")) != &"Mine":
		return false
	var current_pos: Vector2i = latest_room_snapshot.get("position", Vector2i.ZERO)
	return Vector2i(entry_result.get("position", current_pos)) == current_pos


func _room_entry_signature(entry_result: Dictionary) -> String:
	var pos: Vector2i = entry_result.get("position", Vector2i.ZERO)
	return "%s|%d,%d|%s|%s|%d|%d|%s" % [
		room_key,
		pos.x,
		pos.y,
		String(entry_result.get("cause", &"")),
		str(entry_result.get("first_trigger", false)),
		int(entry_result.get("hp_delta", 0)),
		int(entry_result.get("pressure_delta", 0)),
		str(entry_result.get("fatal", false)),
	]


func _start_mine_feedback() -> void:
	mine_feedback_remaining = MINE_FEEDBACK_DURATION
	mine_feedback_elapsed = 0.0
	mine_feedback_frame = -1
	var burst := get_node_or_null("SpecialRoomFx/MineBurst") as Sprite2D
	if burst == null:
		return
	var mine_entity = _special_entity_for_kind(&"mine")
	burst.position = mine_entity.position if mine_entity != null else ActorViewScript.local_to_world(Vector2(0.50, 0.51))
	burst.visible = true
	_update_mine_burst_frame(2 if Art24MotionSettingsScript.reduce_motion_enabled() else 0)
	queue_redraw()


func _advance_special_visuals(delta: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	var reduce_motion := Art24MotionSettingsScript.reduce_motion_enabled()
	var exit_entity = _special_entity_for_kind(&"exit")
	if exit_entity != null:
		if reduce_motion:
			exit_pulse_elapsed = 0.0
			_update_exit_pulse_frame(exit_entity, 0)
		else:
			exit_pulse_elapsed += safe_delta
			_update_exit_pulse_frame(exit_entity, int(exit_pulse_elapsed / EXIT_PULSE_FRAME_DURATION) % EXIT_PULSE_FRAME_COUNT)
	if mine_feedback_remaining <= 0.0:
		return
	mine_feedback_remaining = maxf(0.0, mine_feedback_remaining - safe_delta)
	mine_feedback_elapsed += safe_delta
	if reduce_motion:
		_update_mine_burst_frame(2)
	else:
		_update_mine_burst_frame(mini(int(mine_feedback_elapsed / MINE_BURST_FRAME_DURATION), MINE_BURST_FRAME_COUNT - 1))
	if mine_feedback_remaining <= 0.0:
		var burst := get_node_or_null("SpecialRoomFx/MineBurst") as Sprite2D
		if burst != null:
			burst.visible = false
	queue_redraw()


func _update_mine_burst_frame(frame: int) -> void:
	if frame == mine_feedback_frame:
		return
	mine_feedback_frame = frame
	var burst := get_node_or_null("SpecialRoomFx/MineBurst") as Sprite2D
	if burst != null:
		burst.texture = MINE_BURST_TEXTURES[clampi(frame, 0, MINE_BURST_TEXTURES.size() - 1)]


func _update_exit_pulse_frame(entity, frame: int) -> void:
	if frame == exit_pulse_frame:
		return
	exit_pulse_frame = frame
	var sprite := entity.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	if sprite != null:
		sprite.texture = BEACON_PULSE_TEXTURES[clampi(frame, 0, BEACON_PULSE_TEXTURES.size() - 1)]


func _special_entity_for_kind(kind: StringName):
	for projection_id in special_entities:
		var entity = special_entities[projection_id]
		if entity != null and StringName(entity.interaction_kind) == kind:
			return entity
	return null

func _ensure_layers() -> void:
	if get_node_or_null("DoorVisuals") == null:
		var doors := Node2D.new()
		doors.name = "DoorVisuals"
		# Repainting the admitted doorway crop above actors masks the character
		# at a blocked threshold instead of letting it cut through the door lip.
		doors.z_index = DOOR_FOREGROUND_Z
		add_child(doors)
	if get_node_or_null("WorldInteractables") == null:
		var interactables := Node2D.new()
		interactables.name = "WorldInteractables"
		add_child(interactables)
	if get_node_or_null("CombatVisuals") == null:
		var combat := Node2D.new()
		combat.name = "CombatVisuals"
		add_child(combat)
	if get_node_or_null("AttackFx") == null:
		var attack_fx := Node2D.new()
		attack_fx.name = "AttackFx"
		attack_fx.z_index = ATTACK_FX_Z
		attack_fx.visible = false
		add_child(attack_fx)
		var visibility_mask := Polygon2D.new()
		visibility_mask.name = "AttackVisibilityMask"
		visibility_mask.color = Color.WHITE
		visibility_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		attack_fx.add_child(visibility_mask)
		var slash := Sprite2D.new()
		slash.name = "CombatSlash"
		# The authored frame origin is measured from the texture center; keep
		# Sprite2D centered so the placement formula maps opaque slash pixels
		# into the authoritative visibility mask.
		slash.centered = true
		slash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visibility_mask.add_child(slash)
	if get_node_or_null("ForegroundOccluders") == null:
		var occluders := Node2D.new()
		occluders.name = "ForegroundOccluders"
		occluders.z_index = ALTAR_FOREGROUND_Z
		add_child(occluders)
	if get_node_or_null("SpecialRoomFx") == null:
		var special_fx := Node2D.new()
		special_fx.name = "SpecialRoomFx"
		special_fx.z_index = 48
		add_child(special_fx)
		var mine_burst := Sprite2D.new()
		mine_burst.name = "MineBurst"
		mine_burst.visible = false
		mine_burst.scale = Vector2.ONE * 0.42
		special_fx.add_child(mine_burst)
	for layer_name in ["Enemies", "Projectiles"]:
		if get_node_or_null("CombatVisuals/" + layer_name) == null:
			var layer := Node2D.new()
			layer.name = layer_name
			get_node("CombatVisuals").add_child(layer)
	if context_popup == null:
		context_popup = WorldContextPopupScript.new()
		context_popup.name = "WorldContextPopup"
		context_popup.visibility_changed.connect(_refresh_special_prompt_visibility)
		context_popup.pickup_requested.connect(func(instance_id: String) -> void:
			context_action_requested.emit(&"pickup", {"instance_id": instance_id})
		)
		context_popup.replace_requested.connect(func(ground_instance_id: String, drop_instance_id: String) -> void:
			context_action_requested.emit(&"replace", {"instance_id": ground_instance_id, "drop_instance_id": drop_instance_id})
		)
		context_popup.chest_open_requested.connect(func() -> void:
			context_action_requested.emit(&"chest_open", {"room_key": room_key})
		)
		context_popup.event_open_requested.connect(func(payload: Dictionary) -> void:
			context_action_requested.emit(&"event_open", payload.duplicate(true))
		)
		context_popup.exit_requested.connect(func(payload: Dictionary) -> void:
			context_action_requested.emit(&"exit_request", payload.duplicate(true))
		)
		add_child(context_popup)
	if get_node_or_null("DoorPrompt") == null:
		var label := Label.new()
		label.name = "DoorPrompt"
		label.size = Vector2(280, 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		Art10UISkinKitScript.apply_player_ui_font(label, &"display")
		label.z_index = DOOR_FOREGROUND_Z + 5
		add_child(label)


func _update_door_prompt() -> void:
	var prompt := get_node_or_null("DoorPrompt") as Label
	if prompt == null:
		return
	var nearby_door := _door_projection_for_direction(nearby_door_direction)
	if nearby_door.is_empty() or nearby_door_state == &"":
		prompt.visible = false
		return
	var anchor_local := _door_prompt_anchor_local(nearby_door)
	prompt.position = ActorViewScript.local_to_world(anchor_local) - prompt.size * 0.5
	prompt.visible = true
	match nearby_door_state:
		&"available":
			prompt.text = "继续前进"
			prompt.add_theme_color_override("font_color", Color(0.42, 0.92, 0.76, 1.0))
		&"combat_restricted":
			prompt.text = "战斗中，出口已封锁"
			prompt.add_theme_color_override("font_color", Color(1.0, 0.46, 0.20, 1.0))
		&"blocked_flagged":
			prompt.text = "该方向已标记为雷区"
			prompt.add_theme_color_override("font_color", Color(1.0, 0.58, 0.22, 1.0))
		&"blocked_hidden":
			prompt.text = "先扫描该方向"
			prompt.add_theme_color_override("font_color", Color(0.94, 0.78, 0.34, 1.0))
		_:
			prompt.text = "道路不通"
			prompt.add_theme_color_override("font_color", Color(0.58, 0.62, 0.64, 1.0))


func _door_prompt_anchor_local(door: Dictionary) -> Vector2:
	var anchor := Vector2(door.get(
		"context_anchor_local",
		door.get("local_pos", Vector2(0.5, 0.5))
	))
	var direction := Vector2i((door.get("payload", {}) as Dictionary).get(
		"direction",
		Vector2i.ZERO
	))
	if direction.x != 0:
		anchor.y -= SIDE_DOOR_PROMPT_LIFT_LOCAL
	elif direction.y > 0:
		anchor.y -= SOUTH_DOOR_PROMPT_LIFT_LOCAL
	return anchor


func _door_projection_for_direction(direction: Vector2i) -> Dictionary:
	if direction == Vector2i.ZERO:
		return {}
	for door in door_projections:
		var payload: Dictionary = door.get("payload", {})
		if Vector2i(payload.get("direction", Vector2i.ZERO)) == direction:
			return door
	return {}


func _remove_missing_views(views: Dictionary, active_ids: Dictionary) -> void:
	for actor_id in views.keys():
		if active_ids.has(actor_id):
			continue
		var view := views[actor_id] as Node
		if view != null:
			view.queue_free()
		views.erase(actor_id)


func _rebuild_obstacle_projection() -> void:
	obstacle_descriptors.clear()
	logical_obstacles.clear()
	if room_type == &"Monster":
		for raw_occluder in (world_projection.get("occluders", []) as Array):
			if not raw_occluder is Dictionary:
				continue
			var occluder := raw_occluder as Dictionary
			var projection_id := String(occluder.get("projection_id", ""))
			var sprite := foreground_occluders.get(projection_id) as Sprite2D
			_append_texture_obstacle_descriptor(occluder, sprite, true)
	elif room_type == &"Event":
		for entity in special_entities.values():
			if entity != null and entity.interaction_kind == &"event":
				_append_interactable_obstacle_descriptor(entity, true)
	elif room_type == &"Chest" and chest != null:
		_append_interactable_obstacle_descriptor(chest, true)
	for descriptor in obstacle_descriptors:
		if bool(descriptor.get("collision_enabled", false)):
			logical_obstacles.append(Rect2(descriptor.get("body_rect", Rect2())))
	world_projection["obstacle_descriptors"] = obstacle_descriptors.duplicate(true)


func _append_texture_obstacle_descriptor(
	source: Dictionary,
	sprite: Sprite2D,
	required_visual: bool
) -> void:
	var body_rect := Rect2(source.get("body_rect", Rect2()))
	var visual_rect := Rect2(source.get("visual_rect_local", body_rect))
	var texture := sprite.texture if sprite != null else null
	var texture_resolved := texture != null and texture.get_size().x > 0.0 and texture.get_size().y > 0.0
	var alpha := sprite.modulate.a * sprite.self_modulate.a if sprite != null else 0.0
	var visible := sprite != null and sprite.visible and alpha >= 0.25
	_append_obstacle_descriptor({
		"obstacle_id": String(source.get("projection_id", "obstacle:%s" % room_key)),
		"source_projection_id": String(source.get("projection_id", "")),
		"source_kind": StringName(source.get("interaction_kind", &"visual_occluder")),
		"room_type": room_type,
		"body_rect": body_rect,
		"visual_key": StringName(source.get("visual_key", &"runtime.missing")),
		"resolved_texture_path": texture.resource_path if texture != null else "",
		"resolved_texture_size": texture.get_size() if texture != null else Vector2.ZERO,
		"texture_resolved": texture_resolved,
		"visual_footprint": visual_rect,
		"visual_node_path": String(sprite.get_path()) if sprite != null else "",
		"visual_visible": visible,
		"visible_alpha": alpha,
		"fallback_visible": false,
		"required_visual": required_visual,
	})


func _append_interactable_obstacle_descriptor(entity, required_visual: bool) -> void:
	var snapshot: Dictionary = entity.build_snapshot()
	var resolution: Dictionary = snapshot.get("visual_resolution", {})
	var art_visual := entity.get_node_or_null("VisualRoot/ArtVisual") as CanvasItem
	var fallback := entity.get_node_or_null("VisualRoot/ProgramPlaceholder") as Polygon2D
	var fallback_visible := fallback != null and fallback.visible and fallback.color.a >= 0.25
	var alpha := 0.0
	var visual_node_path := ""
	if art_visual != null and art_visual.visible:
		alpha = art_visual.modulate.a * art_visual.self_modulate.a
		visual_node_path = String(art_visual.get_path())
	elif fallback_visible:
		alpha = fallback.color.a
		visual_node_path = String(fallback.get_path())
	_append_obstacle_descriptor({
		"obstacle_id": String(snapshot.get("projection_id", "obstacle:%s" % room_key)),
		"source_projection_id": String(snapshot.get("projection_id", "")),
		"source_kind": StringName(snapshot.get("interaction_kind", &"unknown")),
		"room_type": room_type,
		"body_rect": Rect2(snapshot.get("body_rect", Rect2())),
		"visual_key": StringName(snapshot.get("visual_key", &"runtime.missing")),
		"resolved_texture_path": String(resolution.get("resolved_texture_path", "")),
		"resolved_texture_size": Vector2(resolution.get("resolved_texture_size", Vector2.ZERO)),
		"texture_resolved": bool(resolution.get("texture_resolved", false)),
		"visual_footprint": Rect2(snapshot.get("visual_rect_local", snapshot.get("body_rect", Rect2()))),
		"visual_node_path": visual_node_path,
		"visual_visible": entity.has_visible_collision_correspondence(),
		"visible_alpha": alpha,
		"fallback_visible": fallback_visible,
		"required_visual": required_visual,
	})


func _append_obstacle_descriptor(values: Dictionary) -> void:
	var descriptor := values.duplicate(true)
	var body_rect := Rect2(descriptor.get("body_rect", Rect2()))
	var visual_footprint := Rect2(descriptor.get("visual_footprint", Rect2()))
	var body_area := maxf(0.0, body_rect.size.x) * maxf(0.0, body_rect.size.y)
	var intersection := body_rect.intersection(visual_footprint)
	var intersection_area := maxf(0.0, intersection.size.x) * maxf(0.0, intersection.size.y)
	var coverage_ratio := intersection_area / body_area if body_area > 0.0 else 0.0
	var center_inside := visual_footprint.has_point(body_rect.get_center())
	var visual_correspondence := (
		bool(descriptor.get("visual_visible", false))
		and float(descriptor.get("visible_alpha", 0.0)) >= 0.25
		and center_inside
		and coverage_ratio >= 0.90
		and (
			bool(descriptor.get("texture_resolved", false))
			or bool(descriptor.get("fallback_visible", false))
		)
	)
	descriptor["body_center_inside_visual"] = center_inside
	descriptor["visual_body_coverage_ratio"] = coverage_ratio
	descriptor["collision_enabled"] = visual_correspondence
	descriptor["disable_reason"] = &"none" if visual_correspondence else &"visible_correspondence_failed"
	obstacle_descriptors.append(descriptor)


func _obstacles_for_room(next_room_type: StringName) -> Array[Rect2]:
	# Legacy characterization helper for the combat arena contract. Production
	# movement consumes obstacle_descriptors, never anonymous room-type rects.
	match next_room_type:
		&"Monster":
			return CombatSimulationScript.production_arena_obstacles()
	return []


func _first_projection(objects: Array[Dictionary], kind: StringName) -> Dictionary:
	for projection in objects:
		if StringName(projection.get("interaction_kind", &"")) == kind:
			return projection
	return {}


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for raw_value in value as Array:
			if raw_value is Dictionary:
				result.append((raw_value as Dictionary).duplicate(true))
	return result


func _safe_node_name(value: String) -> String:
	return value.replace("/", "_").replace(":", "_").replace(".", "_")


func _draw() -> void:
	var room_rect := G41RuntimeLayout.ROOM_RECT
	if mine_feedback_remaining > 0.0:
		var feedback_ratio := clampf(mine_feedback_remaining / MINE_FEEDBACK_DURATION, 0.0, 1.0)
		# This flash is presentation-only and remains clipped to the room plate.
		# Reduced motion keeps one static, low-intensity frame instead of pulsing.
		var feedback_alpha := 0.13 if Art24MotionSettingsScript.reduce_motion_enabled() else 0.20 * feedback_ratio
		draw_rect(room_rect, Color(0.72, 0.035, 0.02, feedback_alpha), true)
	# Collision rectangles are program-owned and remain active, but are not
	# production art. They are visible only behind an explicit debug setting.
	if bool(ProjectSettings.get_setting("application/run/show_g41_collision_debug", false)):
		for obstacle in logical_obstacles:
			var world_rect := Rect2(
				ActorViewScript.local_to_world(obstacle.position),
				G41RuntimeLayout.local_size_to_world(obstacle.size)
			)
			draw_rect(world_rect, Color(0.18, 0.22, 0.26, 0.58), true)
			draw_rect(world_rect, Color(0.55, 0.62, 0.68, 0.75), false, 2.0)
	for door in door_projections:
		_draw_door_projection(door)
	_draw_enemy_melee_geometry()
	_draw_player_attack_geometry()
	for raw_laser in (combat_snapshot.get("lasers", []) as Array):
		if not (raw_laser is Dictionary):
			continue
		var laser := raw_laser as Dictionary
		var origin := ActorViewScript.local_to_world(Vector2(laser.get("origin", Vector2.ZERO)))
		var direction := Vector2(laser.get("direction", Vector2.LEFT)).normalized()
		var endpoint := (
			ActorViewScript.local_to_world(Vector2(laser.get("endpoint", Vector2.ZERO)))
			if laser.has("endpoint")
			else _ray_endpoint_inside_room(origin, direction, room_rect)
		)
		var radius := maxf(0.0, float(laser.get("visual_radius", laser.get("radius", 0.0))))
		var radius_pixels := maxf(1.0, G41RuntimeLayout.local_size_to_world(Vector2(radius, radius)).x)
		var beam_width := radius_pixels * 2.0
		# Every stroke is derived from the authoritative radius. The outer stroke
		# is the damaging beam boundary; brighter inner strokes add material
		# contrast without implying a narrower safe lane.
		draw_line(origin, endpoint, Color(0.75, 0.02, 0.01, 0.24), beam_width, true)
		draw_line(origin, endpoint, Color(1.0, 0.10, 0.06, 0.84), maxf(2.0, beam_width * 0.46), true)
		draw_line(origin, endpoint, Color(1.0, 0.74, 0.42, 0.96), maxf(1.0, beam_width * 0.16), true)
		draw_circle(origin, radius_pixels, Color(1.0, 0.34, 0.12, 0.92))
		draw_circle(endpoint, radius_pixels, Color(0.92, 0.08, 0.035, 0.75))


func _draw_door_projection(door: Dictionary) -> void:
	var body_rect: Rect2 = door.get("body_rect", Rect2())
	var direction_i := Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO))
	if direction_i == Vector2i.ZERO:
		return
	var state := StringName(door.get("visual_state", &"blocked_out_of_bounds"))
	if state == &"available" and direction_i != nearby_available_door:
		return
	var direction := Vector2(direction_i).normalized()
	var tangent := Vector2(-direction.y, direction.x)
	var center := ActorViewScript.local_to_world(body_rect.get_center())
	var body_size := G41RuntimeLayout.local_size_to_world(body_rect.size)
	var half_span := (body_size.x if absf(tangent.x) > 0.5 else body_size.y) * 0.5
	var from := center - tangent * half_span
	var to := center + tangent * half_span
	match state:
		&"available":
			_draw_available_door_cue(center, from, to, direction, tangent)
		&"combat_restricted":
			# The admitted texture child on the doorway owns the lock state.
			pass
		&"blocked_flagged":
			_draw_blocked_door_cue(center, from, to, direction, tangent, Color(0.96, 0.42, 0.20, 0.92), &"flagged")
		&"blocked_hidden":
			_draw_blocked_door_cue(center, from, to, direction, tangent, Color(0.86, 0.68, 0.24, 0.84), &"hidden")
		&"blocked_out_of_bounds":
			_draw_blocked_door_cue(center, from, to, direction, tangent, Color(0.34, 0.38, 0.39, 0.82), &"boundary")


func _draw_available_door_cue(center: Vector2, from: Vector2, to: Vector2, direction: Vector2, tangent: Vector2) -> void:
	var color := Color(0.24, 0.88, 0.68, 0.94)
	var shadow := Color(0.015, 0.08, 0.065, 0.90)
	draw_line(from, to, shadow, 6.0, true)
	draw_line(from, to, color, 2.4, true)
	for endpoint in [from, to]:
		draw_line(endpoint, endpoint - direction * 9.0, shadow, 5.0, true)
		draw_line(endpoint, endpoint - direction * 9.0, color, 2.0, true)
	var arrow_center := center + direction * 8.0
	var arrow := PackedVector2Array([
		arrow_center + direction * 7.0,
		arrow_center - direction * 4.0 + tangent * 5.0,
		arrow_center - direction * 4.0 - tangent * 5.0,
	])
	draw_colored_polygon(arrow, color)


func _draw_blocked_door_cue(
	center: Vector2,
	from: Vector2,
	to: Vector2,
	direction: Vector2,
	tangent: Vector2,
	color: Color,
	kind: StringName
) -> void:
	var shadow := Color(0.025, 0.025, 0.02, 0.90)
	draw_line(from, to, shadow, 7.0, true)
	if kind == &"hidden":
		var segment := (to - from) / 5.0
		for index in range(0, 5, 2):
			draw_line(from + segment * index, from + segment * (index + 1), color, 2.6, true)
	else:
		draw_line(from, to, color, 2.8, true)
	if kind == &"flagged":
		draw_line(center - tangent * 7.0 - direction * 7.0, center + tangent * 7.0 + direction * 7.0, shadow, 6.0, true)
		draw_line(center + tangent * 7.0 - direction * 7.0, center - tangent * 7.0 + direction * 7.0, shadow, 6.0, true)
		draw_line(center - tangent * 7.0 - direction * 7.0, center + tangent * 7.0 + direction * 7.0, color, 2.4, true)
		draw_line(center + tangent * 7.0 - direction * 7.0, center - tangent * 7.0 + direction * 7.0, color, 2.4, true)
	elif kind == &"hidden":
		var diamond := PackedVector2Array([
			center + direction * 7.0,
			center + tangent * 7.0,
			center - direction * 7.0,
			center - tangent * 7.0,
			center + direction * 7.0,
		])
		draw_polyline(diamond, color, 2.2, true)
		draw_circle(center, 1.8, color)
	else:
		draw_line(from - direction * 5.0, to - direction * 5.0, color.darkened(0.28), 2.2, true)


func _ray_endpoint_inside_room(origin: Vector2, direction: Vector2, room_rect: Rect2) -> Vector2:
	var closest_distance := INF
	if absf(direction.x) > 0.0001:
		for boundary_x in [room_rect.position.x, room_rect.end.x]:
			var distance_x: float = (boundary_x - origin.x) / direction.x
			if distance_x <= 0.0:
				continue
			var y_at_boundary := origin.y + direction.y * distance_x
			if y_at_boundary >= room_rect.position.y and y_at_boundary <= room_rect.end.y:
				closest_distance = minf(closest_distance, distance_x)
	if absf(direction.y) > 0.0001:
		for boundary_y in [room_rect.position.y, room_rect.end.y]:
			var distance_y: float = (boundary_y - origin.y) / direction.y
			if distance_y <= 0.0:
				continue
			var x_at_boundary := origin.x + direction.x * distance_y
			if x_at_boundary >= room_rect.position.x and x_at_boundary <= room_rect.end.x:
				closest_distance = minf(closest_distance, distance_y)
	if is_inf(closest_distance):
		return origin
	return origin + direction * closest_distance


func _draw_player_attack_geometry() -> void:
	# AttackFx consumes the same authoritative arc as a clipping mask around the
	# audited combat-slash frames. No program-colored sector is drawn here.
	return


func _player_attack_arc_world_points(geometry: Dictionary) -> PackedVector2Array:
	var authored_points: Array = geometry.get("visible_arc_points", [])
	var result := PackedVector2Array()
	if not authored_points.is_empty():
		for raw_point in authored_points:
			if raw_point is Vector2:
				result.append(ActorViewScript.local_to_world(raw_point))
		return result

	# Compatibility for hand-authored snapshots in older focused runners. The
	# production simulation always supplies visibility-clipped points.
	var origin := ActorViewScript.local_to_world(Vector2(geometry.get("origin", Vector2.ZERO)))
	var facing := Vector2(geometry.get("facing", Vector2.RIGHT)).normalized()
	if facing.length_squared() <= 0.000001:
		facing = Vector2.RIGHT
	var half_angle := maxf(0.0, float(geometry.get("half_angle_radians", PI / 3.0)))
	var range_local := maxf(0.0, float(geometry.get("range", 0.0)))
	var range_pixels := G41RuntimeLayout.local_size_to_world(Vector2(range_local, range_local)).x
	var facing_angle := facing.angle()
	for index in range(21):
		var ratio := float(index) / 20.0
		result.append(
			origin
			+ Vector2.from_angle(facing_angle + lerpf(-half_angle, half_angle, ratio)) * range_pixels
		)
	return result


func _draw_enemy_melee_geometry() -> void:
	for raw_enemy in (combat_snapshot.get("enemies", []) as Array):
		if not raw_enemy is Dictionary:
			continue
		var enemy := raw_enemy as Dictionary
		var state := StringName(enemy.get("state", &"idle"))
		if state not in [&"warning", &"active"]:
			continue
		var radius_local := maxf(0.0, float(enemy.get("warning_radius", enemy.get("attack_radius", 0.0))))
		if radius_local <= 0.0:
			continue
		var center_local := Vector2(enemy.get("pos", Vector2.ZERO))
		var samples := _clipped_radial_samples(center_local, radius_local, 64)
		var outline_points := PackedVector2Array()
		for sample in samples:
			outline_points.append(Vector2((sample as Dictionary).get("world_point", Vector2.ZERO)))
		if outline_points.size() < 3:
			continue
		var fill := Color(0.92, 0.18, 0.06, 0.035 if state == &"warning" else 0.12)
		var outline := Color(1.0, 0.52, 0.18, 0.78 if state == &"warning" else 0.96)
		draw_colored_polygon(outline_points, fill)
		# Only draw the real outer danger perimeter. Closing the clipped polygon
		# drew obstacle intersections as hard L-shaped debug lines across the
		# floor. Missing perimeter segments now communicate that the altar
		# blocks the attack without fabricating an internal boundary.
		for index in range(samples.size()):
			var next_index := (index + 1) % samples.size()
			var current := samples[index] as Dictionary
			var following := samples[next_index] as Dictionary
			if bool(current.get("blocked", false)) or bool(following.get("blocked", false)):
				continue
			if state == &"warning" and int(index / 3) % 2 == 1:
				continue
			draw_line(
				Vector2(current.get("world_point", Vector2.ZERO)),
				Vector2(following.get("world_point", Vector2.ZERO)),
				outline,
				1.6 if state == &"warning" else 2.4,
				true
			)


func _clipped_radial_outline(center: Vector2, radius: float, segment_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for sample in _clipped_radial_samples(center, radius, segment_count):
		points.append(Vector2((sample as Dictionary).get("world_point", Vector2.ZERO)))
	return points


func _clipped_radial_samples(center: Vector2, radius: float, segment_count: int) -> Array[Dictionary]:
	var samples: Array[Dictionary] = []
	for index in range(maxi(3, segment_count)):
		var direction := Vector2.from_angle(TAU * float(index) / float(maxi(3, segment_count)))
		var endpoint := center + direction * radius
		var hit_fraction := 1.0
		for obstacle in logical_obstacles:
			hit_fraction = minf(
				hit_fraction,
				_segment_rect_hit_fraction(center, endpoint, obstacle)
			)
		samples.append({
			"world_point": ActorViewScript.local_to_world(center.lerp(endpoint, hit_fraction)),
			"blocked": hit_fraction < 1.0 - 0.00001,
		})
	return samples


func _segment_rect_hit_fraction(start: Vector2, finish: Vector2, rect: Rect2) -> float:
	var delta := finish - start
	var entry := 0.0
	var exit := 1.0
	for raw_slab in [
		Vector3(-delta.x, start.x - rect.position.x, 0.0),
		Vector3(delta.x, rect.end.x - start.x, 0.0),
		Vector3(-delta.y, start.y - rect.position.y, 0.0),
		Vector3(delta.y, rect.end.y - start.y, 0.0),
	]:
		var slab := raw_slab as Vector3
		var p: float = slab.x
		var q: float = slab.y
		if absf(p) <= 0.000001:
			if q < 0.0:
				return 1.0
			continue
		var ratio: float = q / p
		if p < 0.0:
			entry = maxf(entry, ratio)
		else:
			exit = minf(exit, ratio)
		if entry > exit:
			return 1.0
	if entry < 0.0 or entry > 1.0:
		return 1.0
	return clampf(entry, 0.0, 1.0)


func _has_visible_combat_geometry(snapshot: Dictionary) -> bool:
	var attack: Dictionary = snapshot.get("player_attack_geometry", {})
	if not attack.is_empty() and bool(attack.get("visible", false)):
		return true
	if not (snapshot.get("lasers", []) as Array).is_empty():
		return true
	for raw_enemy in (snapshot.get("enemies", []) as Array):
		if not raw_enemy is Dictionary:
			continue
		var enemy := raw_enemy as Dictionary
		var state := StringName(enemy.get("state", &"idle"))
		if state in [&"warning", &"active"]:
			return true
	return false
