extends Node2D
class_name PlayerController

const DEFAULT_ROOM_RECT := G41RuntimeLayout.ROOM_RECT
const LOCAL_MOVE_SPEED := 0.74
const LOCAL_ACCELERATION := 8.0
const LOCAL_DECELERATION := 12.0
const PLAYER_RADIUS := 0.055
const DOOR_ALIGN_HALF := 0.16
const BLOCKED_EDGE_REBOUND := 0.035
const STEP_PREVIEW_SECONDS := 0.20
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
var facing_asset_id: StringName = &"sprite.player.default"
var local_pos := Vector2(0.30, 0.5)
var local_velocity := Vector2.ZERO
var facing_vector := Vector2.RIGHT
var visual_state: StringName = &"idle"
var logical_obstacles: Array[Rect2] = []
var room_rect := DEFAULT_ROOM_RECT
var facing: StringName = &"down"
var animation_elapsed := 0.0
var animation_frame := 0
var visual_clock := 0.0
var step_preview_remaining := 0.0
var last_texture_path := ""
var pending_visual_state: StringName = &""
var transient_state_remaining := 0.0


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled


func get_move_vector() -> Vector2:
	if not input_enabled:
		return Vector2.ZERO

	var left_pressed := Input.is_action_pressed("move_left") or Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right_pressed := Input.is_action_pressed("move_right") or Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var up_pressed := Input.is_action_pressed("move_up") or Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var down_pressed := Input.is_action_pressed("move_down") or Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var x_axis := float(int(right_pressed) - int(left_pressed))
	var y_axis := float(int(down_pressed) - int(up_pressed))
	var movement := Vector2(x_axis, y_axis)
	if movement.length_squared() < 0.0001:
		return Vector2.ZERO
	return movement.normalized()


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
		state_label.text = String(visual_state)
		state_label.visible = visual_state in [&"attack_windup", &"attack_active", &"hurt", &"dead"]


func set_logical_obstacles(next_obstacles: Array) -> void:
	logical_obstacles.clear()
	for raw_obstacle in next_obstacles:
		if raw_obstacle is Rect2:
			logical_obstacles.append(raw_obstacle)


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
	if direction.length() <= 0.01:
		return
	_set_facing_from_vector(direction)
	step_preview_remaining = STEP_PREVIEW_SECONDS
	animation_elapsed = RuntimeAnimationCatalog.player_frame_duration(&"move")


func place_from_entry(direction: Vector2i) -> void:
	if direction.x > 0:
		set_local_position(Vector2(PLAYER_RADIUS + 0.04, 0.5))
	elif direction.x < 0:
		set_local_position(Vector2(1.0 - PLAYER_RADIUS - 0.04, 0.5))
	elif direction.y > 0:
		set_local_position(Vector2(0.5, PLAYER_RADIUS + 0.04))
	elif direction.y < 0:
		set_local_position(Vector2(0.5, 1.0 - PLAYER_RADIUS - 0.04))
	else:
		reset_local_position()


func block_transition(direction: Vector2i) -> void:
	if direction.x > 0:
		set_local_position(Vector2(1.0 - PLAYER_RADIUS - BLOCKED_EDGE_REBOUND, local_pos.y))
	elif direction.x < 0:
		set_local_position(Vector2(PLAYER_RADIUS + BLOCKED_EDGE_REBOUND, local_pos.y))
	elif direction.y > 0:
		set_local_position(Vector2(local_pos.x, 1.0 - PLAYER_RADIUS - BLOCKED_EDGE_REBOUND))
	elif direction.y < 0:
		set_local_position(Vector2(local_pos.x, PLAYER_RADIUS + BLOCKED_EDGE_REBOUND))


func move_local(move_vector: Vector2, delta: float) -> Dictionary:
	if not input_enabled:
		local_velocity = Vector2.ZERO
		return {"status": &"idle"}
	var direction := move_vector.limit_length(1.0)
	if direction.length_squared() > 0.0001:
		_set_facing_from_vector(direction)
	var target_velocity := direction * LOCAL_MOVE_SPEED
	var acceleration := LOCAL_ACCELERATION if direction.length_squared() > 0.0001 else LOCAL_DECELERATION
	local_velocity = local_velocity.move_toward(target_velocity, acceleration * delta)
	if local_velocity.length_squared() < 0.000001:
		local_velocity = Vector2.ZERO
		set_runtime_visual_state(&"idle")
		return {"status": &"idle"}
	var next_pos := local_pos + local_velocity * delta
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


func set_visual_asset(asset_id: StringName) -> void:
	facing_asset_id = asset_id
	_apply_visual()


func set_grid_position(pos: Vector2i) -> void:
	position = Vector2(420 + pos.x * 36, 220 + pos.y * 36)


func _ready() -> void:
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
	if is_moving:
		_set_facing_from_vector(move_vector)
		step_preview_remaining = STEP_PREVIEW_SECONDS
	else:
		step_preview_remaining = maxf(0.0, step_preview_remaining - delta)
	var show_walk := visual_state == &"move" or is_moving or step_preview_remaining > 0.0
	if reduce_motion:
		animation_elapsed = 0.0
		animation_frame = 0
	else:
		animation_elapsed += delta
		var frame_duration := RuntimeAnimationCatalog.player_frame_duration(visual_state, show_walk)
		var frame_count := maxi(1, RuntimeAnimationCatalog.player_frame_count(visual_state, show_walk))
		var next_frame := int(animation_elapsed / frame_duration)
		if RuntimeAnimationCatalog.player_loops(&"move" if show_walk and visual_state == &"idle" else visual_state):
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
	if next_pos.x <= PLAYER_RADIUS and abs(local_pos.y - 0.5) <= DOOR_ALIGN_HALF:
		return Vector2i(-1, 0)
	if next_pos.x >= 1.0 - PLAYER_RADIUS and abs(local_pos.y - 0.5) <= DOOR_ALIGN_HALF:
		return Vector2i(1, 0)
	if next_pos.y <= PLAYER_RADIUS and abs(local_pos.x - 0.5) <= DOOR_ALIGN_HALF:
		return Vector2i(0, -1)
	if next_pos.y >= 1.0 - PLAYER_RADIUS and abs(local_pos.x - 0.5) <= DOOR_ALIGN_HALF:
		return Vector2i(0, 1)
	return Vector2i.ZERO


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
		walking
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
	var uses_walk_cycle := RuntimeAnimationCatalog.player_uses_walk_cycle(visual_state, walking)
	var bob_offset := 0.0
	var scale_pulse := 1.0
	if uses_walk_cycle:
		bob_offset = RuntimeAnimationCatalog.player_walk_bob_offset(animation_elapsed, reduce_motion)
		var lift_ratio := -bob_offset / RuntimeAnimationCatalog.PLAYER_MOVE_BOB_AMPLITUDE
		scale_pulse += lift_ratio * 0.008
	elif not reduce_motion:
		var pulse := sin(visual_clock * (11.0 if action_visual else 2.4))
		bob_offset = pulse * 0.8
		scale_pulse += pulse * 0.006
	sprite.position.y = -20.0 + bob_offset
	sprite.scale = Vector2.ONE * PLAYER_ART_SCALE * scale_pulse
	sprite.modulate = Color(1.0, 0.62, 0.58, 1.0) if visual_state == &"hurt" else Color.WHITE
	sprite.rotation = -0.18 if visual_state == &"dead" else 0.0


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
