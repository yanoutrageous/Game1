extends Node2D
class_name PlayerController

const ROOM_RECT := Rect2(Vector2(420, 220), Vector2(440, 360))
const LOCAL_MOVE_SPEED := 0.74
const LOCAL_ACCELERATION := 8.0
const LOCAL_DECELERATION := 12.0
const PLAYER_RADIUS := 0.055
const DOOR_ALIGN_HALF := 0.16
const BLOCKED_EDGE_REBOUND := 0.035

var input_enabled := true
var facing_asset_id: StringName = &"sprite.player.default"
var local_pos := Vector2(0.5, 0.5)
var local_velocity := Vector2.ZERO
var facing_vector := Vector2.RIGHT
var visual_state: StringName = &"idle"
var logical_obstacles: Array[Rect2] = []


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
	set_local_position(Vector2(0.5, 0.5))


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
		facing_vector = next_facing.normalized()


func set_runtime_visual_state(next_state: StringName) -> void:
	if G41RuntimeVisualContract.supports_state(&"player", next_state):
		visual_state = next_state
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
		facing_vector = direction.normalized()
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
	position = ROOM_RECT.position + Vector2(local_pos.x * ROOM_RECT.size.x, local_pos.y * ROOM_RECT.size.y)


func _apply_visual() -> void:
	var texture_ref: Variant = null
	if is_inside_tree():
		var content_db := get_node_or_null("/root/ContentDB")
		if content_db != null and content_db.has_method("get_asset_ref"):
			texture_ref = content_db.call("get_asset_ref", facing_asset_id)
	var sprite := get_node_or_null("Sprite") as Sprite2D
	var body := get_node_or_null("Body") as Polygon2D
	if texture_ref is Texture2D:
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.name = "Sprite"
			add_child(sprite)
			move_child(sprite, 0)
		sprite.texture = texture_ref
		sprite.scale = Vector2(0.45, 0.45)
		if body != null:
			body.visible = false


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
