extends Node

# TruthMap = 真实地图
# IntelMap = 玩家已知情报
# MiniMapViewModel = UI 可读数据
# UI 不得直接读取 TruthMap

const ASSET_MANIFEST_PATH := "res://data/assets/asset_manifest.csv"

var asset_records: Dictionary = {}
var data_records: Dictionary = {}


func _ready() -> void:
	load_asset_manifest()
	print_verbose("ContentDB ready")


func load_asset_manifest() -> void:
	asset_records.clear()
	if not FileAccess.file_exists(ASSET_MANIFEST_PATH):
		return

	var manifest_file := FileAccess.open(ASSET_MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		return

	var header: PackedStringArray = []
	while not manifest_file.eof_reached():
		var line := manifest_file.get_line().strip_edges()
		if line.is_empty():
			continue
		var columns := line.split(",", false)
		if header.is_empty():
			header = columns
			continue

		var record: Dictionary = {}
		for index in range(header.size()):
			var key := String(header[index])
			record[key] = String(columns[index]) if index < columns.size() else ""

		var asset_id := String(record.get("asset_id", ""))
		if not asset_id.is_empty():
			asset_records[StringName(asset_id)] = record


func has_asset(asset_id: StringName) -> bool:
	var record := get_asset(asset_id)
	var godot_path := String(record.get("godot_path", ""))
	return not godot_path.is_empty() and ResourceLoader.exists(godot_path)


func get_asset(asset_id: StringName) -> Dictionary:
	return asset_records.get(asset_id, {})


func get_asset_ref(asset_id: StringName) -> Resource:
	var record := get_asset(asset_id)
	var godot_path := String(record.get("godot_path", ""))
	if godot_path.is_empty() or not ResourceLoader.exists(godot_path):
		return null
	return load(godot_path)


func get_placeholder_label(asset_id: StringName) -> String:
	var record := get_asset(asset_id)
	if record.is_empty():
		return String(asset_id)
	var usage := String(record.get("usage", ""))
	if usage.is_empty():
		return String(asset_id)
	return usage


func has_data(data_id: StringName) -> bool:
	return data_records.has(data_id)


func get_data(data_id: StringName) -> Dictionary:
	return data_records.get(data_id, {})
