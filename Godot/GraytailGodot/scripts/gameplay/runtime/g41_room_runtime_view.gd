extends Node2D
class_name G41RoomRuntimeView

signal interaction_commit_requested(interaction_kind: StringName, payload: Dictionary)
signal context_action_requested(action: StringName, payload: Dictionary)

const GroundLootEntityScript := preload("res://scripts/gameplay/loot/g41_ground_loot_entity.gd")
const ChestInteractableScript := preload("res://scripts/gameplay/interactables/g41_chest_interactable.gd")
const ActorViewScript := preload("res://scripts/gameplay/runtime/g41_runtime_actor_view.gd")
const WorldContextPopupScript := preload("res://scripts/gameplay/interaction/g41_world_context_popup.gd")
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
var context_popup: G41WorldContextPopup
var last_door_locked: bool = false
var context_ui_suppressed: bool = false


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


func set_context_ui_suppressed(suppressed: bool) -> void:
	context_ui_suppressed = suppressed
	if context_ui_suppressed and context_popup != null:
		context_popup.clear_context()


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
		if chest == null:
			return {"accepted": false, "reason": &"chest_unavailable", "interaction_kind": &"chest"}
		if chest.is_opened():
			chest.toggle_container()
			request["container_toggled"] = true
			request["container_open"] = chest.is_container_open()
			return request
		if not chest.begin_opening():
			return {"accepted": false, "reason": &"chest_unavailable", "interaction_kind": &"chest"}
		request["pending"] = true
		request["visual_state"] = &"opening"
	return request


func show_pickup_result(instance_id: String, ok: bool) -> void:
	var entity = ground_loot_entities.get(instance_id)
	if entity != null:
		entity.set_pickup_result(ok)


func show_context_result(result: Dictionary) -> void:
	if context_popup != null:
		context_popup.show_command_result(result)


func activate_context_primary() -> bool:
	return context_popup != null and context_popup.activate_primary()


func resolve_chest_commit(ok: bool) -> void:
	if chest == null:
		return
	if ok:
		chest.mark_opened()
	else:
		chest.cancel_opening()


func apply_combat_snapshot(snapshot: Dictionary) -> void:
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
		view.configure(&"projectile", projectile)
	_remove_missing_views(projectile_views, active_ids)
	_update_door_prompt()
	var door_locked := bool(combat_snapshot.get("active", false))
	if door_locked != last_door_locked or not (combat_snapshot.get("lasers", []) as Array).is_empty():
		queue_redraw()
	last_door_locked = door_locked


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
	room_key = ""
	room_type = &"Unknown"
	logical_obstacles.clear()
	focused_interaction_id = ""
	last_door_locked = false
	if chest != null:
		chest.queue_free()
		chest = null
	for dictionary in [ground_loot_entities, enemy_views, projectile_views]:
		for key in dictionary.keys():
			var node := dictionary[key] as Node
			if node != null:
				node.queue_free()
		dictionary.clear()
	if context_popup != null:
		context_popup.clear_context()
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
	_refresh_context_popup(player_local_pos, nearest)


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
			if entity != null and entity.can_interact_from(player_local_pos):
				items.append(entity.item.duplicate(true))
	elif kind == &"chest" and chest != null and chest.is_container_open():
		for raw_item in (latest_room_snapshot.get("room_floor_items", []) as Array):
			if raw_item is Dictionary:
				items.append((raw_item as Dictionary).duplicate(true))
	var anchor_ui: Vector2 = nearest.position
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
		var target_logical_position := nearest_canvas.get_global_transform().origin
		anchor_ui = popup_parent.get_global_transform().affine_inverse() * target_logical_position
	var overlay_size := Vector2(1280, 720)
	var popup_parent_control := context_popup.get_parent() as Control
	if popup_parent_control != null and popup_parent_control.size.x > 0.0 and popup_parent_control.size.y > 0.0:
		overlay_size = popup_parent_control.size
	context_popup.apply_context({
		"interaction_kind": kind,
		"world_pos": anchor_ui,
		"room_bounds": G41RuntimeLayout.context_ui_rect_for_viewport(overlay_size),
		"items": items,
		"opened_once": chest != null and chest.is_opened() if kind == &"chest" else false,
		"container_open": chest != null and chest.is_container_open() if kind == &"chest" else false,
		"backpack_remaining": int(latest_room_snapshot.get("backpack_remaining", 0)),
		"inventory_items": latest_room_snapshot.get("inventory_items", []),
	})


func _nearest_interactable(player_local_pos: Vector2):
	# Keep the chest's reversible open/close interaction authoritative while the
	# player remains in its radius.  Chest rewards may also have one-to-one world
	# projections in the shared room-floor ledger, but those must not steal focus
	# and strand an already-opened chest in the closed state.
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
	if context_popup == null:
		context_popup = WorldContextPopupScript.new()
		context_popup.name = "WorldContextPopup"
		context_popup.pickup_requested.connect(func(instance_id: String) -> void:
			context_action_requested.emit(&"pickup", {"instance_id": instance_id})
		)
		context_popup.replace_requested.connect(func(ground_instance_id: String, drop_instance_id: String) -> void:
			context_action_requested.emit(&"replace", {"instance_id": ground_instance_id, "drop_instance_id": drop_instance_id})
		)
		context_popup.chest_toggle_requested.connect(func() -> void:
			context_action_requested.emit(&"chest_toggle", {"room_key": room_key})
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
	var locked := bool(combat_snapshot.get("active", false))
	prompt.visible = locked
	prompt.text = "威胁未清除 · 靠近出口将尝试脱离战斗"
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
	if bool(combat_snapshot.get("active", false)):
		var room_center := room_rect.get_center()
		_draw_combat_seal_segment(Vector2(room_rect.position.x, room_center.y), Vector2(room_rect.position.x + 26.0, room_center.y))
		_draw_combat_seal_segment(Vector2(room_rect.end.x - 26.0, room_center.y), Vector2(room_rect.end.x, room_center.y))
		_draw_combat_seal_segment(Vector2(room_center.x, room_rect.position.y), Vector2(room_center.x, room_rect.position.y + 26.0))
		_draw_combat_seal_segment(Vector2(room_center.x, room_rect.end.y - 26.0), Vector2(room_center.x, room_rect.end.y))
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
