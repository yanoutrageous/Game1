extends Node2D
class_name PlayerController

var input_enabled := true


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled


func get_move_vector() -> Vector2:
	if not input_enabled:
		return Vector2.ZERO

	return Input.get_vector("move_left", "move_right", "move_up", "move_down")
