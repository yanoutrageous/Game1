extends "res://scripts/gameplay/interaction/g41_interactable.gd"
class_name G41ChestInteractable

signal open_commit_requested(interaction_id: String)

const OPENING_SECONDS := 0.28
const CHEST_TEXTURE := preload("res://assets/props/chest_closed.png")
const CHEST_OPEN_TEXTURE := preload("res://assets/props/art07/00_baoxiang_kai.png")
const OPENING_FX_ROOT := "res://assets/art24/fx/chest_opening_"
const OPENING_FX_FRAMES := 6

var opening_remaining: float = 0.0
var container_open: bool = false


func configure_chest(room_key: String, opened: bool, spawn_local_pos: Vector2 = Vector2(0.68, 0.53)) -> void:
	if opened:
		visual_state = &"opened"
		opening_remaining = 0.0
	elif visual_state != &"opening":
		visual_state = &"closed"
		container_open = false
	configure_interactable({
		"interaction_id": "chest:" + room_key,
		"interaction_kind": &"chest",
		"local_pos": spawn_local_pos,
		"interaction_radius": 0.18,
		"enabled": visual_state != &"opening",
		"visual_state": visual_state,
		"prompt_text": "关闭箱子" if opened and container_open else ("查看物资箱" if opened else "打开物资箱"),
		"payload": {"room_key": room_key},
	})
	var placeholder := get_node_or_null("VisualRoot/ProgramPlaceholder") as Polygon2D
	if placeholder != null:
		placeholder.polygon = PackedVector2Array([Vector2(-20, -11), Vector2(20, -11), Vector2(20, 13), Vector2(-20, 13)])
	_ensure_art_visuals()
	_apply_visual_state()


func begin_opening() -> bool:
	if not enabled:
		return false
	if visual_state == &"opened":
		container_open = not container_open
		_apply_visual_state()
		return true
	if visual_state != &"closed":
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
	enabled = true
	container_open = true
	opening_remaining = 0.0
	_apply_visual_state()


func cancel_opening() -> void:
	if visual_state != &"opening":
		return
	visual_state = &"closed"
	enabled = true
	opening_remaining = 0.0
	_apply_visual_state()


func set_focused(next_focused: bool) -> void:
	super.set_focused(next_focused)
	if not focused and container_open:
		container_open = false
		_apply_visual_state()


func toggle_container() -> bool:
	if visual_state != &"opened":
		return false
	container_open = not container_open
	_apply_visual_state()
	return true


func is_opened() -> bool:
	return visual_state == &"opened"


func is_container_open() -> bool:
	return is_opened() and container_open


func _ensure_art_visuals() -> void:
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root == null:
		return
	if visual_root.get_node_or_null("ArtVisual") == null:
		var art_visual := Sprite2D.new()
		art_visual.name = "ArtVisual"
		art_visual.texture = CHEST_TEXTURE
		art_visual.scale = Vector2.ONE * 0.22
		art_visual.position = Vector2(0, -5)
		visual_root.add_child(art_visual)
	if visual_root.get_node_or_null("OpeningFx") == null:
		var opening_fx := Sprite2D.new()
		opening_fx.name = "OpeningFx"
		opening_fx.scale = Vector2.ONE * 0.26
		opening_fx.position = Vector2(0, -14)
		opening_fx.visible = false
		visual_root.add_child(opening_fx)


func _apply_visual_state() -> void:
	super._apply_visual_state()
	var art_visual := get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	var opening_fx := get_node_or_null("VisualRoot/OpeningFx") as Sprite2D
	if art_visual != null:
		art_visual.texture = CHEST_OPEN_TEXTURE if visual_state == &"opened" and container_open else CHEST_TEXTURE
		art_visual.modulate = Color(1.08, 0.94, 0.70, 1.0) if focused else Color.WHITE
		if visual_state == &"opened":
			art_visual.modulate = Color(0.82, 0.78, 0.66, 1.0) if not container_open else Color(1.08, 0.90, 0.54, 1.0)
			art_visual.position.y = -12.0 if container_open else -5.0
			art_visual.scale = Vector2.ONE * (0.24 if container_open else 0.22)
		else:
			art_visual.position.y = -5.0
			art_visual.scale = Vector2.ONE * 0.22
	if opening_fx != null:
		opening_fx.visible = visual_state == &"opening"
		if opening_fx.visible:
			var progress := 1.0 - clampf(opening_remaining / OPENING_SECONDS, 0.0, 1.0)
			var frame := mini(OPENING_FX_FRAMES - 1, int(progress * float(OPENING_FX_FRAMES)))
			opening_fx.texture = load("%s%d.png" % [OPENING_FX_ROOT, frame]) as Texture2D
	var prompt := get_node_or_null("PromptAnchor/InteractionPrompt") as Label
	if prompt != null:
		prompt.visible = false


func _placeholder_color() -> Color:
	match visual_state:
		&"opening":
			return Color(1.0, 0.75, 0.22, 1.0)
		&"opened":
			return Color(0.42, 0.31, 0.18, 0.82)
	return Color(0.72, 0.43, 0.18, 1.0) if not focused else Color(1.0, 0.84, 0.32, 1.0)
