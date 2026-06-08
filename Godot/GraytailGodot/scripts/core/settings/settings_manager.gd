extends Node

# TruthMap = 真实地图
# IntelMap = 玩家已知情报
# MiniMapViewModel = UI 可读数据
# UI 不得直接读取 TruthMap

var values: Dictionary = {}


func _ready() -> void:
	print_verbose("SettingsManager ready")


func get_value(key: StringName, default_value: Variant = null) -> Variant:
	return values.get(key, default_value)


func set_value(key: StringName, value: Variant) -> void:
	values[key] = value


func reset_to_defaults() -> void:
	values.clear()
