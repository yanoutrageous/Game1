extends Node2D
class_name PlayerController

const ROOM_RECT := Rect2(Vector2(420, 220), Vector2(440, 360))
const LOCAL_MOVE_SPEED := 0.74
const PLAYER_RADIUS := 0.055
const DOOR_ALIGN_HALF := 0.16

var input_enabled := true
var facing_asset_id: StringName = &"sprite.player.default"
var local_pos := Vector2(0.5, 0.5)


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled


func get_move_vector() -> Vector2:
	if not input_enabled:
		return Vector2.ZERO

	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func reset_local_position() -> void:
	set_local_position(Vector2(0.5, 0.5))


func set_local_position(next_local_pos: Vector2) -> void:
	local_pos = Vector2(
		clampf(next_local_pos.x, PLAYER_RADIUS, 1.0 - PLAYER_RADIUS),
		clampf(next_local_pos.y, PLAYER_RADIUS, 1.0 - PLAYER_RADIUS)
	)
	_apply_local_position()


func get_local_position() -> Vector2:
	return local_pos


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
		set_local_position(Vector2(1.0 - PLAYER_RADIUS, local_pos.y))
	elif direction.x < 0:
		set_local_position(Vector2(PLAYER_RADIUS, local_pos.y))
	elif direction.y > 0:
		set_local_position(Vector2(local_pos.x, 1.0 - PLAYER_RADIUS))
	elif direction.y < 0:
		set_local_position(Vector2(local_pos.x, PLAYER_RADIUS))


func move_local(move_vector: Vector2, delta: float) -> Dictionary:
	if not input_enabled or move_vector.length() <= 0.01:
		return {"status": &"idle"}

	var direction := move_vector.normalized()
	var next_pos := local_pos + direction * LOCAL_MOVE_SPEED * delta
	var transition := _transition_for_next_pos(next_pos, direction)
	if transition != Vector2i.ZERO:
		return {"status": &"transition", "direction": transition}

	set_local_position(next_pos)
	return {"status": &"moved"}


func set_visual_asset(asset_id: StringName) -> void:
	facing_asset_id = asset_id
	_apply_visual()


func set_grid_position(pos: Vector2i) -> void:
	position = Vector2(420 + pos.x * 36, 220 + pos.y * 36)


func _ready() -> void:
	_apply_visual()
	_apply_local_position()


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


func _apply_local_position() -> void:
	position = ROOM_RECT.position + Vector2(local_pos.x * ROOM_RECT.size.x, local_pos.y * ROOM_RECT.size.y)


func _apply_visual() -> void:
	var texture_ref := ContentDB.get_asset_ref(facing_asset_id)
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
