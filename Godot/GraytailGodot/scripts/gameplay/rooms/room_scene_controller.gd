extends Node2D
class_name RoomSceneController

var room_data: Dictionary = {}


func configure(next_room_data: Dictionary) -> void:
	room_data = next_room_data.duplicate(true)
