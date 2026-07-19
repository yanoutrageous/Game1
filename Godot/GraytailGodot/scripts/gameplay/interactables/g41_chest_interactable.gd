extends "res://scripts/gameplay/interaction/g41_interactable.gd"
class_name G41ChestInteractable

signal open_commit_requested(interaction_id: String)

const OPENING_SECONDS := 0.28

var opening_remaining: float = 0.0


func configure_chest(room_key: String, opened: bool, spawn_local_pos: Vector2 = Vector2(0.68, 0.53)) -> void:
	if opened:
		visual_state = &"opened"
		opening_remaining = 0.0
	elif visual_state != &"opening":
		visual_state = &"closed"
	configure_interactable({
		"interaction_id": "chest:" + room_key,
		"interaction_kind": &"chest",
		"local_pos": spawn_local_pos,
		"interaction_radius": 0.18,
		"enabled": not opened and visual_state != &"opening",
		"visual_state": visual_state,
		"prompt_text": "Open chest",
		"payload": {"room_key": room_key},
	})
	var placeholder := get_node_or_null("VisualRoot/ProgramPlaceholder") as Polygon2D
	if placeholder != null:
		placeholder.polygon = PackedVector2Array([Vector2(-20, -11), Vector2(20, -11), Vector2(20, 13), Vector2(-20, 13)])


func begin_opening() -> bool:
	if not enabled or visual_state != &"closed":
		return false
	visual_state = &"opening"
	enabled = false
	opening_remaining = OPENING_SECONDS
	_apply_visual_state()
	return true


func advance(delta: float) -> void:
	if visual_state != &"opening":
		return
	if opening_remaining < 0.0:
		return
	opening_remaining = maxf(0.0, opening_remaining - delta)
	if opening_remaining <= 0.0:
		opening_remaining = -1.0
		open_commit_requested.emit(interaction_id)


func mark_opened() -> void:
	visual_state = &"opened"
	enabled = false
	opening_remaining = 0.0
	_apply_visual_state()


func cancel_opening() -> void:
	if visual_state != &"opening":
		return
	visual_state = &"closed"
	enabled = true
	opening_remaining = 0.0
	_apply_visual_state()


func _placeholder_color() -> Color:
	match visual_state:
		&"opening":
			return Color(1.0, 0.75, 0.22, 1.0)
		&"opened":
			return Color(0.42, 0.31, 0.18, 0.82)
	return Color(0.72, 0.43, 0.18, 1.0) if not focused else Color(1.0, 0.84, 0.32, 1.0)
