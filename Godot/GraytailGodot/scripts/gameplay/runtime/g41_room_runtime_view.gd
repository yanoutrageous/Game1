extends Node2D
class_name G41RoomRuntimeView

signal interaction_commit_requested(interaction_kind: StringName, payload: Dictionary)

const GroundLootEntityScript := preload("res://scripts/gameplay/loot/g41_ground_loot_entity.gd")
const ChestInteractableScript := preload("res://scripts/gameplay/interactables/g41_chest_interactable.gd")
const ActorViewScript := preload("res://scripts/gameplay/runtime/g41_runtime_actor_view.gd")
var room_key: String = ""
var room_type: StringName = &"Unknown"
var chest
var ground_loot_entities: Dictionary = {}
var enemy_views: Dictionary = {}
var projectile_views: Dictionary = {}
var focused_interaction_id: String = ""
var combat_snapshot: Dictionary = {}
var latest_room_snapshot: Dictionary = {}
var logical_obstacles: Array[Rect2] = []


func _ready() -> void:
	_ensure_layers()


func configure_room(snapshot: Dictionary) -> void:
	latest_room_snapshot = snapshot.duplicate(true)
	var pos: Vector2i = snapshot.get("position", Vector2i.ZERO)
	room_key = "%d,%d" % [pos.x, pos.y]
	room_type = StringName(snapshot.get("current_room", &"Unknown"))
	logical_obstacles = _obstacles_for_room(room_type)
	_ensure_layers()
	_sync_chest(snapshot)
	_sync_ground_loot(snapshot.get("room_floor_items", []))
	queue_redraw()


func advance(delta: float, player_local_pos: Vector2, next_combat_snapshot: Dictionary = {}) -> void:
	if chest != null:
		chest.advance(delta)
	_update_focus(player_local_pos)
	apply_combat_snapshot(next_combat_snapshot)


func request_nearest_interaction(player_local_pos: Vector2) -> Dictionary:
	var nearest = _nearest_interactable(player_local_pos)
	if nearest == null:
		return {
			"accepted": false,
			"reason": &"no_interactable_in_range",
			"interaction_kind": &"none",
		}
	var request: Dictionary = nearest.build_interaction_request()
	if StringName(request.get("interaction_kind", &"none")) == &"chest":
		if chest == null or not chest.begin_opening():
			return {"accepted": false, "reason": &"chest_unavailable", "interaction_kind": &"chest"}
		request["pending"] = true
		request["visual_state"] = &"opening"
	return request


func show_pickup_result(instance_id: String, ok: bool) -> void:
	var entity = ground_loot_entities.get(instance_id)
	if entity != null:
		entity.set_pickup_result(ok)


func resolve_chest_commit(ok: bool) -> void:
	if chest == null:
		return
	if ok:
		chest.mark_opened()
	else:
		chest.cancel_opening()


func apply_combat_snapshot(snapshot: Dictionary) -> void:
	combat_snapshot = snapshot.duplicate(true)
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
		view.configure(&"projectile", projectile)
	_remove_missing_views(projectile_views, active_ids)
	_update_door_prompt()
	queue_redraw()


func build_read_only_snapshot() -> Dictionary:
	var interactables: Array[Dictionary] = []
	if chest != null:
		interactables.append(chest.build_snapshot())
	for instance_id in ground_loot_entities:
		var entity = ground_loot_entities[instance_id]
		if entity != null:
			interactables.append(entity.build_snapshot())
	return {
		"room_key": room_key,
		"room_type": room_type,
		"focused_interaction_id": focused_interaction_id,
		"interactables": interactables,
		"combat": combat_snapshot.duplicate(true),
		"door_locked": bool(combat_snapshot.get("active", false)),
		"logical_obstacles": logical_obstacles.duplicate(),
		"visual_contract_id": &"g41.runtime_visual.v1",
	}


func get_logical_obstacles() -> Array[Rect2]:
	return logical_obstacles.duplicate()


func clear_runtime() -> void:
	latest_room_snapshot.clear()
	combat_snapshot.clear()
	room_key = ""
	room_type = &"Unknown"
	logical_obstacles.clear()
	focused_interaction_id = ""
	if chest != null:
		chest.queue_free()
		chest = null
	for dictionary in [ground_loot_entities, enemy_views, projectile_views]:
		for key in dictionary.keys():
			var node := dictionary[key] as Node
			if node != null:
				node.queue_free()
		dictionary.clear()
	_update_door_prompt()
	queue_redraw()


func _sync_chest(snapshot: Dictionary) -> void:
	if room_type != &"Chest":
		if chest != null:
			chest.queue_free()
			chest = null
		return
	if chest == null:
		chest = ChestInteractableScript.new()
		chest.name = "ChestInteractable"
		chest.open_commit_requested.connect(_on_chest_open_commit_requested)
		get_node("WorldInteractables").add_child(chest)
	var search_state: Dictionary = snapshot.get("search_state_data", {})
	chest.configure_chest(room_key, bool(search_state.get("searched", false)))


func _sync_ground_loot(raw_items: Variant) -> void:
	var active_ids: Dictionary = {}
	if raw_items is Array:
		for raw_item in raw_items as Array:
			if not (raw_item is Dictionary):
				continue
			var item := raw_item as Dictionary
			var instance_id := String(item.get("instance_id", ""))
			if instance_id.is_empty():
				continue
			active_ids[instance_id] = true
			var entity = ground_loot_entities.get(instance_id)
			if entity == null:
				entity = GroundLootEntityScript.new()
				entity.name = _safe_node_name("GroundLoot_" + instance_id)
				get_node("WorldInteractables").add_child(entity)
				ground_loot_entities[instance_id] = entity
			entity.configure_item(item, _loot_position_for(instance_id))
	for existing_id in ground_loot_entities.keys():
		if active_ids.has(existing_id):
			continue
		var entity := ground_loot_entities[existing_id] as Node
		if entity != null:
			entity.queue_free()
		ground_loot_entities.erase(existing_id)


func _update_focus(player_local_pos: Vector2) -> void:
	var nearest = _nearest_interactable(player_local_pos)
	focused_interaction_id = "" if nearest == null else nearest.interaction_id
	if chest != null:
		chest.set_focused(chest == nearest)
	for instance_id in ground_loot_entities:
		var entity = ground_loot_entities[instance_id]
		if entity != null:
			entity.set_focused(entity == nearest)


func _nearest_interactable(player_local_pos: Vector2):
	var nearest = null
	var nearest_distance := INF
	var candidates: Array = []
	if chest != null:
		candidates.append(chest)
	for instance_id in ground_loot_entities:
		var entity = ground_loot_entities[instance_id]
		if entity != null:
			candidates.append(entity)
	for candidate in candidates:
		var distance: float = float(candidate.distance_to_local(player_local_pos))
		if not candidate.can_interact_from(player_local_pos) or distance >= nearest_distance:
			continue
		nearest = candidate
		nearest_distance = distance
	return nearest


func _on_chest_open_commit_requested(_interaction_id: String) -> void:
	interaction_commit_requested.emit(&"chest", {"room_key": room_key})


func _ensure_layers() -> void:
	if get_node_or_null("WorldInteractables") == null:
		var interactables := Node2D.new()
		interactables.name = "WorldInteractables"
		add_child(interactables)
	if get_node_or_null("CombatVisuals") == null:
		var combat := Node2D.new()
		combat.name = "CombatVisuals"
		add_child(combat)
	for layer_name in ["Enemies", "Projectiles"]:
		if get_node_or_null("CombatVisuals/" + layer_name) == null:
			var layer := Node2D.new()
			layer.name = layer_name
			get_node("CombatVisuals").add_child(layer)
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
	var locked := bool(combat_snapshot.get("active", false))
	prompt.visible = locked
	prompt.text = "Combat active - reaching a door flees the encounter"
	prompt.add_theme_color_override("font_color", Color(1.0, 0.60, 0.28, 1.0))


func _remove_missing_views(views: Dictionary, active_ids: Dictionary) -> void:
	for actor_id in views.keys():
		if active_ids.has(actor_id):
			continue
		var view := views[actor_id] as Node
		if view != null:
			view.queue_free()
		views.erase(actor_id)


func _loot_position_for(instance_id: String) -> Vector2:
	var hash_value := absi(instance_id.hash())
	var column := hash_value % 4
	var row := (hash_value / 4) % 3
	return Vector2(0.38 + float(column) * 0.085, 0.58 + float(row) * 0.075)


func _obstacles_for_room(next_room_type: StringName) -> Array[Rect2]:
	match next_room_type:
		&"Chest":
			return [Rect2(Vector2(0.25, 0.28), Vector2(0.13, 0.12))]
		&"Event":
			return [Rect2(Vector2(0.46, 0.32), Vector2(0.10, 0.18))]
		&"Normal":
			return [Rect2(Vector2(0.44, 0.38), Vector2(0.12, 0.12))]
	return []


func _safe_node_name(value: String) -> String:
	return value.replace("/", "_").replace(":", "_").replace(".", "_")


func _draw() -> void:
	var room_rect := G41RuntimeLayout.ROOM_RECT
	for obstacle in logical_obstacles:
		var world_rect := Rect2(
			ActorViewScript.local_to_world(obstacle.position),
			G41RuntimeLayout.local_size_to_world(obstacle.size)
		)
		draw_rect(world_rect, Color(0.18, 0.22, 0.26, 0.58), true)
		draw_rect(world_rect, Color(0.55, 0.62, 0.68, 0.75), false, 2.0)
	if bool(combat_snapshot.get("active", false)):
		var color := Color(0.95, 0.25, 0.18, 0.85)
		var room_center := room_rect.get_center()
		draw_line(Vector2(room_rect.position.x, room_center.y), Vector2(room_rect.position.x + 18.0, room_center.y), color, 4.0)
		draw_line(Vector2(room_rect.end.x - 18.0, room_center.y), Vector2(room_rect.end.x, room_center.y), color, 4.0)
		draw_line(Vector2(room_center.x, room_rect.position.y), Vector2(room_center.x, room_rect.position.y + 18.0), color, 4.0)
		draw_line(Vector2(room_center.x, room_rect.end.y - 18.0), Vector2(room_center.x, room_rect.end.y), color, 4.0)
	for raw_laser in (combat_snapshot.get("lasers", []) as Array):
		if not (raw_laser is Dictionary):
			continue
		var laser := raw_laser as Dictionary
		var origin := ActorViewScript.local_to_world(Vector2(laser.get("origin", Vector2.ZERO)))
		var direction := Vector2(laser.get("direction", Vector2.LEFT)).normalized()
		var endpoint := origin + Vector2(direction.x * room_rect.size.x, direction.y * room_rect.size.y) * 2.0
		draw_line(origin, endpoint, Color(1.0, 0.20, 0.14, 0.88), 3.0)
