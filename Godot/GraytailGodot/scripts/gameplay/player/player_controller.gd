extends Node2D
class_name PlayerController

const DEFAULT_ROOM_RECT := G41RuntimeLayout.ROOM_RECT
const LOCAL_MOVE_SPEED := 0.74
const LOCAL_ACCELERATION := 8.0
const LOCAL_DECELERATION := 12.0
const PLAYER_RADIUS := 0.055
const DOOR_ALIGN_HALF := 0.16
const DOOR_ENTRY_INSET := 0.005
const DOOR_ENTRY_MOTION_MARGIN_PX := 3.0
const STEP_PREVIEW_SECONDS := 0.20
const HURT_FEEDBACK_MODULATE := Color(1.0, 0.62, 0.58, 1.0)
# The UE prototype presents the player in a 64 px slot inside a 560 px room.
# The first 0.40 pass measured only about 51 visible pixels in the running
# 1280x720 build because the imported frame and room transforms both affect
# the final silhouette. 0.50 restores the observed 62-65 px target while the
# logical collider and movement radius remain unchanged.
const PLAYER_ART_SCALE := 0.50
const Art24MotionSettingsScript := preload("res://scripts/presentation/art24/art24_motion_settings.gd")
const RuntimeAnimationCatalog := preload("res://scripts/presentation/art24/art24_runtime_animation_catalog.gd")
const TextureCache := preload("res://scripts/presentation/runtime_texture_cache.gd")

var input_enabled := true
var appearance_id: StringName = RuntimeAnimationCatalog.DEFAULT_PLAYER_APPEARANCE_ID
var appearance_selection_id: StringName = RuntimeAnimationCatalog.DEFAULT_PLAYER_APPEARANCE_ID
var appearance_modulate := Color.WHITE
var animation_set_id: StringName = RuntimeAnimationCatalog.DEFAULT_PLAYER_ANIMATION_SET_ID
var animation_set: Dictionary = {}
var local_pos := Vector2(0.30, 0.5)
var local_velocity := Vector2.ZERO
var facing_vector := Vector2.RIGHT
var visual_state: StringName = &"idle"
var logical_obstacles: Array[Rect2] = []
var door_projections: Array[Dictionary] = []
var room_rect := DEFAULT_ROOM_RECT
var facing: StringName = &"down"
var animation_elapsed := 0.0
var animation_frame := 0
var visual_clock := 0.0
var step_preview_remaining := 0.0
var last_texture_path := ""
var pending_visual_state: StringName = &""
var transient_state_remaining := 0.0
var authoritative_combat_facing_locked := false


func set_input_enabled(enabled: bool) -> void:
	if input_enabled == enabled:
		if not enabled:
			local_velocity = Vector2.ZERO
		return
	input_enabled = enabled
	if not enabled:
		local_velocity = Vector2.ZERO
		step_preview_remaining = 0.0
		if visual_state == &"move":
			set_runtime_visual_state(&"idle")


func get_move_vector() -> Vector2:
	if not input_enabled:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.18)


func reset_local_position() -> void:
	local_velocity = Vector2.ZERO
	# The normal-room center is a program-owned obstacle in G41. Spawn on the
	# left safe floor so production input is live from the first frame.
	set_local_position(Vector2(0.30, 0.5))


func set_local_position(next_local_pos: Vector2) -> void:
	local_pos = Vector2(
		clampf(next_local_pos.x, PLAYER_RADIUS, 1.0 - PLAYER_RADIUS),
		clampf(next_local_pos.y, PLAYER_RADIUS, 1.0 - PLAYER_RADIUS)
	)
	_apply_local_position()


func get_local_position() -> Vector2:
	return local_pos


func get_facing_vector() -> Vector2:
	return facing_vector


func set_facing_vector(next_facing: Vector2) -> void:
	if next_facing.length_squared() > 0.0001:
		_set_facing_from_vector(next_facing)


func sync_authoritative_combat_facing(next_facing: Vector2, lock_input_facing: bool) -> void:
	authoritative_combat_facing_locked = lock_input_facing
	set_facing_vector(next_facing)


func release_authoritative_combat_facing() -> void:
	authoritative_combat_facing_locked = false


func set_runtime_visual_state(next_state: StringName) -> void:
	if not G41RuntimeVisualContract.supports_state(&"player", next_state):
		return
	if visual_state == &"hurt" and transient_state_remaining > 0.0 and next_state not in [&"hurt", &"dead"]:
		pending_visual_state = next_state
		_update_state_label()
		return
	pending_visual_state = &""
	_set_visual_state_now(next_state)


func _set_visual_state_now(next_state: StringName) -> void:
	if visual_state == next_state:
		_update_state_label()
		return
	visual_state = next_state
	animation_elapsed = 0.0
	animation_frame = 0
	last_texture_path = ""
	transient_state_remaining = RuntimeAnimationCatalog.minimum_visible_seconds(visual_state)
	_update_state_label()


func _update_state_label() -> void:
	var state_label := get_node_or_null("PromptAnchor/RuntimeState") as Label
	if state_label != null:
		# Keep the state text available to runtime diagnostics, but never render
		# internal state ids above the player. Combat timing is communicated by
		# the character animation and attack geometry.
		state_label.text = String(visual_state)
		state_label.visible = false


func set_logical_obstacles(next_obstacles: Array) -> void:
	logical_obstacles.clear()
	for raw_obstacle in next_obstacles:
		if raw_obstacle is Rect2:
			logical_obstacles.append(raw_obstacle)


func set_door_projections(next_doors: Array) -> void:
	door_projections.clear()
	for raw_door in next_doors:
		if not raw_door is Dictionary:
			continue
		var door := (raw_door as Dictionary).duplicate(true)
		var direction := Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO))
		var body_rect := Rect2(door.get("body_rect", Rect2()))
		if direction == Vector2i.ZERO or body_rect.size.x <= 0.0 or body_rect.size.y <= 0.0:
			continue
		door_projections.append(door)


func get_door_projections() -> Array[Dictionary]:
	return door_projections.duplicate(true)


func requested_transition(move_vector: Vector2) -> Vector2i:
	if not input_enabled or move_vector.length_squared() <= 0.0001:
		return Vector2i.ZERO
	var direction := move_vector.normalized()
	return _transition_for_next_pos(local_pos + direction * 0.02, direction)


func set_room_rect(next_room_rect: Rect2) -> void:
	if next_room_rect.size.x <= 1.0 or next_room_rect.size.y <= 1.0:
		return
	room_rect = next_room_rect
	_apply_local_position()


func play_step(direction: Vector2) -> void:
	if direction.length() <= 0.01 or authoritative_combat_facing_locked:
		return
	var starts_walk_cycle := (
		visual_state == &"idle"
		and local_velocity.length_squared() <= 0.0001
		and step_preview_remaining <= 0.0
	)
	_set_facing_from_vector(direction)
	step_preview_remaining = STEP_PREVIEW_SECONDS
	# Input events may prime presentation, but movement authority stays in the
	# continuous process path. Only idle-to-walk starts on a contact pose;
	# changing direction during a walk keeps the existing cadence.
	if starts_walk_cycle:
		animation_elapsed = 0.0
		animation_frame = 0
	_apply_art24_frame(true)
	_apply_idle_motion(true)


func entry_local_position(direction: Vector2i) -> Vector2:
	var entry_door := _door_projection_for_direction(-direction)
	if not entry_door.is_empty():
		var body_rect := Rect2(entry_door.get("body_rect", Rect2()))
		var visual_rect := Rect2(entry_door.get(
			"visual_rect_local",
			_door_visual_rect_local(entry_door)
		))
		var player_visual_bounds := presentation_bounds_local()
		var collision_clearance := body_rect.grow(PLAYER_RADIUS)
		var center := body_rect.get_center()
		if direction.x > 0:
			return Vector2(maxf(
				visual_rect.end.x + DOOR_ENTRY_INSET - player_visual_bounds.position.x,
				collision_clearance.end.x + DOOR_ENTRY_INSET
			), center.y)
		elif direction.x < 0:
			return Vector2(minf(
				visual_rect.position.x - DOOR_ENTRY_INSET - player_visual_bounds.end.x,
				collision_clearance.position.x - DOOR_ENTRY_INSET
			), center.y)
		elif direction.y > 0:
			return Vector2(center.x, maxf(
				visual_rect.end.y + DOOR_ENTRY_INSET - player_visual_bounds.position.y,
				collision_clearance.end.y + DOOR_ENTRY_INSET
			))
		elif direction.y < 0:
			return Vector2(center.x, minf(
				visual_rect.position.y - DOOR_ENTRY_INSET - player_visual_bounds.end.y,
				collision_clearance.position.y - DOOR_ENTRY_INSET
			))
	var visual_bounds := presentation_bounds_local()
	if direction.x > 0:
		return Vector2(DOOR_ENTRY_INSET - visual_bounds.position.x, 0.5)
	elif direction.x < 0:
		return Vector2(1.0 - DOOR_ENTRY_INSET - visual_bounds.end.x, 0.5)
	elif direction.y > 0:
		return Vector2(0.5, DOOR_ENTRY_INSET - visual_bounds.position.y)
	elif direction.y < 0:
		return Vector2(0.5, 1.0 - DOOR_ENTRY_INSET - visual_bounds.end.y)
	return Vector2(0.30, 0.5)


func place_from_entry(direction: Vector2i) -> Vector2:
	local_velocity = Vector2.ZERO
	step_preview_remaining = 0.0
	if direction != Vector2i.ZERO:
		set_facing_vector(Vector2(direction))
	set_runtime_visual_state(&"idle")
	set_local_position(entry_local_position(direction))
	return local_pos


func presentation_bounds_local() -> Rect2:
	var fallback := Rect2(
		Vector2(-PLAYER_RADIUS, -PLAYER_RADIUS),
		Vector2.ONE * PLAYER_RADIUS * 2.0
	)
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		return fallback
	var texture_size := sprite.texture.get_size()
	var scaled_size := Vector2(
		texture_size.x * absf(sprite.scale.x),
		texture_size.y * absf(sprite.scale.y)
	)
	if scaled_size.x <= 0.0 or scaled_size.y <= 0.0:
		return fallback
	var pixel_position := sprite.position
	if sprite.centered:
		pixel_position -= scaled_size * 0.5
	var margin_local := Vector2(
		DOOR_ENTRY_MOTION_MARGIN_PX / room_rect.size.x,
		DOOR_ENTRY_MOTION_MARGIN_PX / room_rect.size.y
	)
	var local_position := Vector2(
		pixel_position.x / room_rect.size.x,
		pixel_position.y / room_rect.size.y
	) - margin_local
	var local_size := Vector2(
		scaled_size.x / room_rect.size.x,
		scaled_size.y / room_rect.size.y
	) + margin_local * 2.0
	return Rect2(local_position, local_size)


func block_transition(direction: Vector2i) -> void:
	if direction == Vector2i.ZERO:
		return
	# The attempted transition was rejected before movement authority changed
	# rooms. Stop the pending movement without manufacturing a reverse step.
	local_velocity = Vector2.ZERO
	step_preview_remaining = 0.0
	set_runtime_visual_state(&"idle")


func move_local(move_vector: Vector2, delta: float) -> Dictionary:
	if not input_enabled:
		local_velocity = Vector2.ZERO
		return {"status": &"idle"}
	var direction := move_vector.limit_length(1.0)
	if direction.length_squared() > 0.0001:
		_set_facing_from_vector(direction)
	var target_velocity := direction * LOCAL_MOVE_SPEED
	var acceleration := LOCAL_ACCELERATION if direction.length_squared() > 0.0001 else LOCAL_DECELERATION
	var integration := _integrate_velocity(local_velocity, target_velocity, acceleration, maxf(0.0, delta))
	local_velocity = integration.get("velocity", Vector2.ZERO)
	if local_velocity.length_squared() < 0.000001:
		local_velocity = Vector2.ZERO
		step_preview_remaining = 0.0
		set_runtime_visual_state(&"idle")
		return {"status": &"idle"}
	var next_pos := local_pos + Vector2(integration.get("displacement", Vector2.ZERO))
	var transition := _transition_for_next_pos(next_pos, local_velocity.normalized())
	if transition != Vector2i.ZERO:
		local_velocity = Vector2.ZERO
		return {"status": &"transition", "direction": transition}
	var resolved_pos := _resolve_obstacle_motion(local_pos, next_pos)
	if resolved_pos.is_equal_approx(local_pos) and not next_pos.is_equal_approx(local_pos):
		local_velocity = Vector2.ZERO
		set_runtime_visual_state(&"idle")
		return {"status": &"blocked_obstacle"}
	set_local_position(resolved_pos)
	set_runtime_visual_state(&"move")
	return {"status": &"moved", "velocity": local_velocity, "facing": facing_vector}


func _integrate_velocity(from_velocity: Vector2, target_velocity: Vector2, acceleration: float, delta: float) -> Dictionary:
	if delta <= 0.0:
		return {"velocity": from_velocity, "displacement": Vector2.ZERO}
	var velocity_delta := target_velocity - from_velocity
	var distance := velocity_delta.length()
	if distance <= 0.000001 or acceleration <= 0.0:
		return {"velocity": target_velocity, "displacement": target_velocity * delta}
	var acceleration_direction := velocity_delta / distance
	var time_to_target := distance / acceleration
	if time_to_target >= delta:
		var next_velocity := from_velocity + acceleration_direction * acceleration * delta
		return {
			"velocity": next_velocity,
			"displacement": (from_velocity + next_velocity) * 0.5 * delta,
		}
	# Integrate the accelerating segment and then the constant-velocity segment.
	# This keeps identical held-input travel stable at 30/60/144 Hz.
	var accelerating_displacement := (
		from_velocity * time_to_target
		+ acceleration_direction * 0.5 * acceleration * time_to_target * time_to_target
	)
	return {
		"velocity": target_velocity,
		"displacement": accelerating_displacement + target_velocity * (delta - time_to_target),
	}


func set_presentation_profile(
	next_appearance_id: StringName,
	next_animation_set_id: StringName,
	registered_sets: Dictionary = {},
	next_selection_id: StringName = &"",
	next_visual_modulate: Color = Color.WHITE
) -> void:
	animation_set = RuntimeAnimationCatalog.resolve_player_animation_set(next_animation_set_id, registered_sets)
	animation_set_id = StringName(animation_set.get("id", RuntimeAnimationCatalog.DEFAULT_PLAYER_ANIMATION_SET_ID))
	appearance_id = next_appearance_id if next_appearance_id != &"" else StringName(animation_set.get("appearance_id", RuntimeAnimationCatalog.DEFAULT_PLAYER_APPEARANCE_ID))
	appearance_selection_id = next_selection_id if next_selection_id != &"" else appearance_id
	appearance_modulate = next_visual_modulate
	last_texture_path = ""
	_apply_visual()


func presentation_snapshot() -> Dictionary:
	var descriptor := _animation_set_descriptor()
	var sprite := get_node_or_null("Sprite") as Sprite2D
	return {
		"selection_id": appearance_selection_id,
		"appearance_id": appearance_id,
		"animation_set_id": animation_set_id,
		"animation_root": String(descriptor.get("root", RuntimeAnimationCatalog.PLAYER_ROOT)),
		"texture_path": last_texture_path,
		"visual_modulate": appearance_modulate,
		"sprite_modulate": sprite.modulate if sprite != null else Color.WHITE,
		"source_status": StringName(descriptor.get("source_status", &"audited_runtime")),
		"used_fallback": bool(descriptor.get("used_fallback", false)),
		"read_only": true,
	}


func set_grid_position(pos: Vector2i) -> void:
	position = Vector2(420 + pos.x * 36, 220 + pos.y * 36)


func _ready() -> void:
	if animation_set.is_empty():
		animation_set = RuntimeAnimationCatalog.resolve_player_animation_set(animation_set_id)
	_ensure_runtime_contract_nodes()
	_apply_visual()
	_apply_local_position()
	set_runtime_visual_state(&"idle")
	set_process(true)


func _process(delta: float) -> void:
	_advance_transient_state(delta)
	var reduce_motion := Art24MotionSettingsScript.reduce_motion_enabled()
	if not reduce_motion:
		visual_clock += delta
	var move_vector := get_move_vector()
	var is_moving := move_vector.length() > 0.01
	var presentation_movement := is_moving and not authoritative_combat_facing_locked
	if presentation_movement:
		_set_facing_from_vector(move_vector)
		step_preview_remaining = STEP_PREVIEW_SECONDS
	else:
		step_preview_remaining = maxf(0.0, step_preview_remaining - delta)
	var show_walk := visual_state == &"move" or presentation_movement or step_preview_remaining > 0.0
	if reduce_motion:
		animation_elapsed = 0.0
		animation_frame = 0
	else:
		animation_elapsed += delta
		var frame_duration := RuntimeAnimationCatalog.player_frame_duration(visual_state, show_walk, _animation_set_descriptor())
		var frame_count := maxi(1, RuntimeAnimationCatalog.player_frame_count(visual_state, show_walk, _animation_set_descriptor()))
		var next_frame := int(animation_elapsed / frame_duration)
		if RuntimeAnimationCatalog.player_loops(&"move" if show_walk and visual_state == &"idle" else visual_state, _animation_set_descriptor()):
			next_frame %= frame_count
		else:
			next_frame = mini(next_frame, frame_count - 1)
		animation_frame = next_frame
	_apply_art24_frame(show_walk)
	_apply_idle_motion(show_walk)


func _advance_transient_state(delta: float) -> void:
	if transient_state_remaining <= 0.0:
		return
	transient_state_remaining = maxf(0.0, transient_state_remaining - delta)
	if transient_state_remaining > 0.0 or pending_visual_state == &"":
		return
	var next_state := pending_visual_state
	pending_visual_state = &""
	_set_visual_state_now(next_state)


func _transition_for_next_pos(next_pos: Vector2, direction: Vector2) -> Vector2i:
	if not door_projections.is_empty():
		for door in door_projections:
			var door_direction := Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO))
			if door_direction == Vector2i.ZERO or Vector2(door_direction).dot(direction) <= 0.5:
				continue
			var body_rect := Rect2(door.get("body_rect", Rect2()))
			if _door_body_reached(body_rect, door_direction, next_pos):
				return door_direction
		return Vector2i.ZERO
	if next_pos.x <= PLAYER_RADIUS and abs(local_pos.y - 0.5) <= DOOR_ALIGN_HALF:
		return Vector2i(-1, 0)
	if next_pos.x >= 1.0 - PLAYER_RADIUS and abs(local_pos.y - 0.5) <= DOOR_ALIGN_HALF:
		return Vector2i(1, 0)
	if next_pos.y <= PLAYER_RADIUS and abs(local_pos.x - 0.5) <= DOOR_ALIGN_HALF:
		return Vector2i(0, -1)
	if next_pos.y >= 1.0 - PLAYER_RADIUS and abs(local_pos.x - 0.5) <= DOOR_ALIGN_HALF:
		return Vector2i(0, 1)
	return Vector2i.ZERO


func _door_projection_for_direction(direction: Vector2i) -> Dictionary:
	for door in door_projections:
		if Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO)) == direction:
			return door
	return {}


func _door_visual_rect_local(door: Dictionary) -> Rect2:
	var anchor := Vector2(door.get(
		"ground_anchor_local",
		door.get("local_pos", Vector2(0.5, 0.5))
	))
	var display_size := Vector2(door.get("display_size_local", Vector2.ZERO))
	var pivot := Vector2(door.get("pivot_normalized", Vector2(0.5, 0.5)))
	return Rect2(anchor - display_size * pivot, display_size)


func _door_body_reached(body_rect: Rect2, direction: Vector2i, next_pos: Vector2) -> bool:
	if direction.x != 0:
		if next_pos.y < body_rect.position.y or next_pos.y > body_rect.end.y:
			return false
		return next_pos.x <= body_rect.end.x if direction.x < 0 else next_pos.x >= body_rect.position.x
	if next_pos.x < body_rect.position.x or next_pos.x > body_rect.end.x:
		return false
	return next_pos.y <= body_rect.end.y if direction.y < 0 else next_pos.y >= body_rect.position.y


func _resolve_obstacle_motion(from: Vector2, to: Vector2) -> Vector2:
	if not _position_hits_obstacle(to):
		return to
	var x_only := Vector2(to.x, from.y)
	if not _position_hits_obstacle(x_only):
		return x_only
	var y_only := Vector2(from.x, to.y)
	if not _position_hits_obstacle(y_only):
		return y_only
	return from


func _position_hits_obstacle(test_pos: Vector2) -> bool:
	for obstacle in logical_obstacles:
		var inflated := obstacle.grow(PLAYER_RADIUS)
		if inflated.has_point(test_pos):
			return true
	return false


func _apply_local_position() -> void:
	position = room_rect.position + Vector2(local_pos.x * room_rect.size.x, local_pos.y * room_rect.size.y)


func _apply_visual() -> void:
	var sprite := get_node_or_null("Sprite") as Sprite2D
	var body := get_node_or_null("Body") as Polygon2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		add_child(sprite)
		move_child(sprite, 0)
	sprite.scale = Vector2.ONE * PLAYER_ART_SCALE
	sprite.position = Vector2(0, -20)
	if body != null:
		body.visible = false
	_apply_art24_frame(false)
	_apply_appearance_modulate(sprite)


func _set_facing_from_vector(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	facing_vector = direction.normalized()
	if absf(direction.x) > absf(direction.y):
		facing = &"right" if direction.x > 0.0 else &"left"
	else:
		facing = &"down" if direction.y > 0.0 else &"up"


func _apply_art24_frame(walking: bool) -> void:
	var texture_path := RuntimeAnimationCatalog.player_texture_path(
		facing,
		visual_state,
		animation_frame,
		Art24MotionSettingsScript.reduce_motion_enabled(),
		walking,
		_animation_set_descriptor()
	)
	if texture_path == last_texture_path:
		return
	var texture := TextureCache.texture(texture_path)
	if texture == null:
		return
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	sprite.texture = texture
	last_texture_path = texture_path


func _apply_idle_motion(walking: bool) -> void:
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	var reduce_motion := Art24MotionSettingsScript.reduce_motion_enabled()
	var action_visual := visual_state in [&"attack_windup", &"attack_active", &"attack_recovery", &"hurt", &"dead"]
	var uses_walk_cycle := RuntimeAnimationCatalog.player_uses_walk_cycle(visual_state, walking, _animation_set_descriptor())
	var bob_offset := 0.0
	var scale_pulse := 1.0
	if uses_walk_cycle:
		bob_offset = RuntimeAnimationCatalog.player_walk_bob_offset(animation_elapsed, reduce_motion, _animation_set_descriptor())
		var lift_ratio := -bob_offset / RuntimeAnimationCatalog.PLAYER_MOVE_BOB_AMPLITUDE
		scale_pulse += lift_ratio * 0.008
	elif not reduce_motion:
		var pulse := sin(visual_clock * (11.0 if action_visual else 2.4))
		bob_offset = pulse * 0.8
		scale_pulse += pulse * 0.006
	sprite.position.y = -20.0 + bob_offset
	sprite.scale = Vector2.ONE * PLAYER_ART_SCALE * scale_pulse
	_apply_appearance_modulate(sprite)
	sprite.rotation = -0.18 if visual_state == &"dead" else 0.0


func _apply_appearance_modulate(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	# Feedback is layered over the selected appearance instead of replacing it,
	# so a hit remains legible without erasing the player's visual identity.
	sprite.modulate = appearance_modulate * HURT_FEEDBACK_MODULATE if visual_state == &"hurt" else appearance_modulate


func _animation_set_descriptor() -> Dictionary:
	if animation_set.is_empty():
		animation_set = RuntimeAnimationCatalog.resolve_player_animation_set(animation_set_id)
	return animation_set


func _ensure_runtime_contract_nodes() -> void:
	if get_node_or_null("VisualRoot") == null:
		var visual_root := Node2D.new()
		visual_root.name = "VisualRoot"
		add_child(visual_root)
	for anchor_name: StringName in G41RuntimeVisualContract.REQUIRED_ANCHORS:
		if anchor_name == &"VisualRoot" or get_node_or_null(String(anchor_name)) != null:
			continue
		var anchor := Node2D.new()
		anchor.name = String(anchor_name)
		add_child(anchor)
	if get_node_or_null("PromptAnchor/RuntimeState") == null:
		var label := Label.new()
		label.name = "RuntimeState"
		label.position = Vector2(-52, -42)
		label.size = Vector2(104, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.visible = false
		get_node("PromptAnchor").add_child(label)
