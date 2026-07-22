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
const MINE_FEEDBACK_DURATION := 0.27
const MINE_BURST_FRAME_DURATION := 0.045
const EXIT_PULSE_FRAME_DURATION := 0.085
const AVAILABLE_DOOR_CUE_MARGIN := 0.075
const FOCUS_EXIT_MARGIN := 0.025
const FOCUS_SWITCH_MARGIN := 0.025
const FOCUS_MIN_RESIDENCE_SECONDS := 0.12
const FOCUS_LOST_GRACE_SECONDS := 0.10
const EXIT_PULSE_FRAME_COUNT := 8
const MINE_BURST_FRAME_COUNT := 6
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
var logical_obstacles: Array[Rect2] = []
var context_popup: G41WorldContextPopup
var last_door_locked: bool = false
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


func set_context_ui_suppressed(suppressed: bool) -> void:
	context_ui_suppressed = suppressed
	if context_ui_suppressed and context_popup != null:
		context_popup.clear_context()
	for special in special_entities.values():
		_apply_special_focus_visual(special)
	if not context_ui_suppressed:
		_update_focus(last_player_local_pos)


func request_nearest_interaction(player_local_pos: Vector2) -> Dictionary:
	var nearest = _nearest_actionable_interactable(player_local_pos)
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
	_remove_missing_views(projectile_views, active_ids)
	if door_state_changed:
		_rebuild_door_projection()
		_update_available_door_cue(last_player_local_pos)
		_update_door_prompt()
	if door_state_changed or not (combat_snapshot.get("lasers", []) as Array).is_empty():
		queue_redraw()
	last_door_locked = next_door_locked


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
		"logical_obstacles": logical_obstacles.duplicate(),
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
	focused_interaction_id = ""
	focus_residence_elapsed = 0.0
	focus_lost_elapsed = 0.0
	last_door_locked = false
	nearby_available_door = Vector2i.ZERO
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
	for dictionary in [ground_loot_entities, departing_ground_loot_entities, special_entities, enemy_views, projectile_views]:
		for key in dictionary.keys():
			var node := dictionary[key] as Node
			if node != null:
				node.queue_free()
		dictionary.clear()
	if context_popup != null:
		context_popup.clear_context()
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
	var objects := _dictionary_array(world_projection.get("world_objects", []))
	_sync_chest(objects)
	_sync_ground_loot(objects, same_room)
	_sync_special_objects(objects)
	projection_room_key = room_key
	logical_obstacles = _obstacles_for_room(room_type)
	if chest != null:
		logical_obstacles.append(chest.body_rect)


func _rebuild_door_projection() -> void:
	if latest_room_snapshot.is_empty():
		door_projections.clear()
		return
	var updated := WorldObjectProjectionScript.build(latest_room_snapshot, combat_snapshot)
	door_projections = _dictionary_array(updated.get("doors", []))
	world_projection["doors"] = door_projections.duplicate(true)
	door_projection_revision += 1


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
		visual_root.add_child(sprite)
	var kind := StringName(projection.get("interaction_kind", &""))
	var texture: Texture2D
	match kind:
		&"event":
			var event_type := StringName((projection.get("payload", {}) as Dictionary).get("event_type", &"trader"))
			texture = EVENT_BADGE_TEXTURES.get(event_type, EVENT_BADGE_TEXTURES[&"trader"]) as Texture2D
			sprite.scale = Vector2.ONE * 1.22
		&"mine":
			texture = MINE_TRAP_TEXTURE
			sprite.scale = Vector2.ONE * 0.28
		&"exit":
			texture = BEACON_PULSE_TEXTURES[0]
			sprite.scale = Vector2.ONE * 0.32
	if texture != null and sprite.texture != texture and (kind != &"exit" or sprite.texture == null):
		sprite.texture = texture
	var placeholder := visual_root.get_node_or_null("ProgramPlaceholder") as Polygon2D
	if placeholder != null:
		placeholder.visible = texture == null
	_apply_special_focus_visual(entity)


func _apply_special_focus_visual(entity) -> void:
	if entity == null:
		return
	var sprite := entity.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	if sprite == null:
		return
	var payload: Dictionary = entity.payload
	var alpha := 1.0
	if StringName(entity.interaction_kind) == &"event" and bool(payload.get("completed", false)):
		alpha = 0.55
	elif StringName(entity.interaction_kind) == &"mine" and bool(payload.get("triggered", false)):
		alpha = 0.72
	sprite.modulate = Color(1.0, 0.96, 0.82, alpha) if entity.focused else Color(1.0, 1.0, 1.0, alpha)
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
	var nearest_distance := INF
	for door in door_projections:
		if StringName(door.get("visual_state", &"")) != &"available":
			continue
		var body_rect: Rect2 = door.get("body_rect", Rect2())
		if not body_rect.grow(AVAILABLE_DOOR_CUE_MARGIN).has_point(player_local_pos):
			continue
		var distance := Vector2(door.get("local_pos", body_rect.get_center())).distance_to(player_local_pos)
		if distance >= nearest_distance:
			continue
		nearest_distance = distance
		next_direction = Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO))
	if nearby_available_door == next_direction:
		return
	nearby_available_door = next_direction
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
	var overlay_size := Vector2(1280, 720)
	var popup_parent_control := context_popup.get_parent() as Control
	if popup_parent_control != null and popup_parent_control.size.x > 0.0 and popup_parent_control.size.y > 0.0:
		overlay_size = popup_parent_control.size
	context_popup.apply_context({
		"interaction_kind": kind,
		"world_pos": anchor_ui,
		"player_world_pos": player_ui,
		"room_bounds": G41RuntimeLayout.context_ui_rect_for_viewport(overlay_size),
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


func _nearest_actionable_interactable(player_local_pos: Vector2):
	# The proximity surface may focus read-only hazards, but an explicit input
	# must never turn that observation into an implicit room command.
	var locked = _interactable_by_id(focused_interaction_id)
	if _is_actionable_interactable(locked) and locked.can_interact_from(player_local_pos):
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
	if get_node_or_null("WorldInteractables") == null:
		var interactables := Node2D.new()
		interactables.name = "WorldInteractables"
		add_child(interactables)
	if get_node_or_null("CombatVisuals") == null:
		var combat := Node2D.new()
		combat.name = "CombatVisuals"
		add_child(combat)
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
		label.position = Vector2(500, 555)
		label.size = Vector2(280, 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		add_child(label)


func _update_door_prompt() -> void:
	var prompt := get_node_or_null("DoorPrompt") as Label
	if prompt == null:
		return
	var restricted := false
	for door in door_projections:
		if StringName(door.get("visual_state", &"")) == &"combat_restricted":
			restricted = true
			break
	prompt.visible = restricted
	prompt.text = "战斗封锁中 · 靠近出口可尝试撤离"
	prompt.add_theme_color_override("font_color", Color(1.0, 0.60, 0.28, 1.0))


func _remove_missing_views(views: Dictionary, active_ids: Dictionary) -> void:
	for actor_id in views.keys():
		if active_ids.has(actor_id):
			continue
		var view := views[actor_id] as Node
		if view != null:
			view.queue_free()
		views.erase(actor_id)


func _obstacles_for_room(next_room_type: StringName) -> Array[Rect2]:
	match next_room_type:
		&"Event":
			return [Rect2(Vector2(0.46, 0.32), Vector2(0.10, 0.18))]
		&"Normal":
			return [Rect2(Vector2(0.44, 0.38), Vector2(0.12, 0.12))]
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
	for raw_laser in (combat_snapshot.get("lasers", []) as Array):
		if not (raw_laser is Dictionary):
			continue
		var laser := raw_laser as Dictionary
		var origin := ActorViewScript.local_to_world(Vector2(laser.get("origin", Vector2.ZERO)))
		var direction := Vector2(laser.get("direction", Vector2.LEFT)).normalized()
		var endpoint := _ray_endpoint_inside_room(origin, direction, room_rect)
		# The combat laser remains a room-scale threat, but its presentation must
		# never spill into the scan rail or bottom HUD. Layered strokes read as an
		# energy beam instead of a debug geometry line.
		draw_line(origin, endpoint, Color(0.75, 0.02, 0.01, 0.22), 8.0, true)
		draw_line(origin, endpoint, Color(1.0, 0.10, 0.06, 0.82), 3.0, true)
		draw_line(origin, endpoint, Color(1.0, 0.74, 0.42, 0.96), 1.0, true)
		draw_circle(origin, 4.0, Color(1.0, 0.34, 0.12, 0.92))
		draw_circle(endpoint, 4.5, Color(0.92, 0.08, 0.035, 0.75))


func _draw_door_projection(door: Dictionary) -> void:
	var body_rect: Rect2 = door.get("body_rect", Rect2())
	var world_rect := Rect2(
		ActorViewScript.local_to_world(body_rect.position),
		G41RuntimeLayout.local_size_to_world(body_rect.size)
	)
	var state := StringName(door.get("visual_state", &"blocked_out_of_bounds"))
	if state == &"combat_restricted":
		var horizontal := world_rect.size.x >= world_rect.size.y
		var from := Vector2(world_rect.position.x, world_rect.get_center().y) if horizontal else Vector2(world_rect.get_center().x, world_rect.position.y)
		var to := Vector2(world_rect.end.x, world_rect.get_center().y) if horizontal else Vector2(world_rect.get_center().x, world_rect.end.y)
		_draw_combat_seal_segment(from, to)
		return
	if state == &"available":
		var direction := Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO))
		if direction == Vector2i.ZERO or direction != nearby_available_door:
			return
	var color := Color(0.22, 0.70, 0.58, 0.72)
	match state:
		&"blocked_flagged":
			color = Color(0.96, 0.42, 0.20, 0.86)
		&"blocked_hidden":
			color = Color(0.78, 0.63, 0.24, 0.72)
		&"blocked_out_of_bounds":
			color = Color(0.20, 0.23, 0.24, 0.62)
	draw_rect(world_rect, Color(color.r, color.g, color.b, color.a * 0.24), true)
	draw_rect(world_rect, color, false, 2.0)


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


func _draw_combat_seal_segment(from: Vector2, to: Vector2) -> void:
	var direction := (to - from).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var midpoint := (from + to) * 0.5
	# Layered strokes retain the UE prototype's red danger language without
	# reading as a debug collision line. Values are centralized here so art can
	# tune the seal without touching combat or door rules.
	draw_line(from, to, Color(0.68, 0.04, 0.02, 0.18), 13.0, true)
	draw_line(from, to, Color(0.30, 0.015, 0.008, 0.92), 7.0, true)
	draw_line(from, to, Color(0.95, 0.16, 0.055, 0.96), 3.5, true)
	draw_line(from, to, Color(1.0, 0.66, 0.28, 0.92), 1.2, true)
	for endpoint in [from, to]:
		draw_circle(endpoint, 4.2, Color(0.28, 0.01, 0.005, 0.95))
		draw_circle(endpoint, 2.2, Color(1.0, 0.38, 0.10, 0.96))
	var rune := PackedVector2Array([
		midpoint - direction * 5.0,
		midpoint + normal * 5.0,
		midpoint + direction * 5.0,
		midpoint - normal * 5.0,
	])
	draw_colored_polygon(rune, Color(0.92, 0.12, 0.035, 0.92))
	draw_polyline(PackedVector2Array([rune[0], rune[1], rune[2], rune[3], rune[0]]), Color(1.0, 0.70, 0.26, 0.96), 1.2, true)
