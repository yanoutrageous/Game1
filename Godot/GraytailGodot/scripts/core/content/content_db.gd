extends Node

# ContentDB remains the project-wide facade for asset and data lookup.
# Asset manifest parsing is delegated to AssetCatalog.

const ASSET_MANIFEST_PATH := "res://data/assets/asset_manifest.csv"

var asset_records: Dictionary = {}
var data_records: Dictionary = {}
var asset_catalog := AssetCatalog.new()


func _ready() -> void:
	load_asset_manifest()
	print_verbose("ContentDB ready")


func load_asset_manifest() -> void:
	asset_catalog.load_from_manifest(ASSET_MANIFEST_PATH)
	asset_records = asset_catalog.asset_records


func has_asset(asset_id: StringName) -> bool:
	return asset_catalog.has_asset(asset_id)


func get_asset(asset_id: StringName) -> Dictionary:
	return asset_catalog.get_asset(asset_id)


func get_asset_ref(asset_id: StringName) -> Resource:
	return asset_catalog.get_asset_ref(asset_id)


func get_placeholder_label(asset_id: StringName) -> String:
	return asset_catalog.get_usage(asset_id)


func get_theme_key(asset_id: StringName) -> StringName:
	return asset_catalog.get_theme_key(asset_id)


func has_data(data_id: StringName) -> bool:
	return data_records.has(data_id)


func get_data(data_id: StringName) -> Dictionary:
	return data_records.get(data_id, {})
