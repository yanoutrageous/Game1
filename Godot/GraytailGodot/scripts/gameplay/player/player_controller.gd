extends Node2D
class_name PlayerController

var input_enabled := true
var facing_asset_id: StringName = &"sprite.player.default"


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled


func get_move_vector() -> Vector2:
	if not input_enabled:
		return Vector2.ZERO

	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func set_visual_asset(asset_id: StringName) -> void:
	facing_asset_id = asset_id
	_apply_visual()


func set_grid_position(pos: Vector2i) -> void:
	position = Vector2(420 + pos.x * 36, 220 + pos.y * 36)


func _ready() -> void:
	_apply_visual()


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
