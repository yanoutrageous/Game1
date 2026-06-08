extends Node2D
class_name ChestPlaceholder

signal interaction_requested


func request_interaction() -> void:
	interaction_requested.emit()
