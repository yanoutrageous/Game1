extends Node2D
class_name ExitBeaconPlaceholder

signal exit_requested


func request_exit() -> void:
	exit_requested.emit()
