extends RefCounted
class_name AssetCatalog

# AssetCatalog owns manifest parsing and asset_id to Resource lookup.
# Core gameplay rules must not depend on AssetCatalog.

var asset_records: Dictionary = {}
var duplicate_asset_ids: Array[StringName] = []
var missing_asset_paths: Array[StringName] = []


func load_from_manifest(manifest_path: String) -> void:
	asset_records.clear()
	duplicate_asset_ids.clear()
	missing_asset_paths.clear()

	if not FileAccess.file_exists(manifest_path):
		return

	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
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

		var record := _record_from_columns(header, columns)
		var asset_id := StringName(String(record.get("asset_id", "")))
		if asset_id == &"":
			continue
		if asset_records.has(asset_id):
			duplicate_asset_ids.append(asset_id)
		asset_records[asset_id] = record

		var godot_path := String(record.get("godot_path", ""))
		var replacement_needed := String(record.get("replacement_needed", "false")).to_lower() == "true"
		if not godot_path.is_empty() and not ResourceLoader.exists(godot_path) and not replacement_needed:
			missing_asset_paths.append(asset_id)


func has_asset(asset_id: StringName) -> bool:
	var godot_path := get_godot_path(asset_id)
	return not godot_path.is_empty() and ResourceLoader.exists(godot_path)


func get_asset(asset_id: StringName) -> Dictionary:
	return asset_records.get(asset_id, {})


func get_godot_path(asset_id: StringName) -> String:
	var record := get_asset(asset_id)
	return String(record.get("godot_path", ""))


func get_asset_ref(asset_id: StringName) -> Resource:
	var godot_path := get_godot_path(asset_id)
	if godot_path.is_empty() or not ResourceLoader.exists(godot_path):
		return null
	return load(godot_path)


func get_usage(asset_id: StringName) -> String:
	var record := get_asset(asset_id)
	return String(record.get("usage", asset_id))


func get_theme_key(asset_id: StringName) -> StringName:
	var record := get_asset(asset_id)
	return StringName(String(record.get("theme_key", "")))


func get_records_for_role(role: StringName) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for record in asset_records.values():
		if StringName(String(record.get("presentation_role", ""))) == role:
			records.append(record.duplicate(true))
	return records


func validate_manifest_contract() -> Array[String]:
	var failures: Array[String] = []
	if duplicate_asset_ids.size() > 0:
		failures.append("duplicate asset ids: %s" % duplicate_asset_ids)
	if missing_asset_paths.size() > 0:
		failures.append("missing asset paths: %s" % missing_asset_paths)
	return failures


func _record_from_columns(header: PackedStringArray, columns: PackedStringArray) -> Dictionary:
	var record: Dictionary = {}
	for index in range(header.size()):
		var key := String(header[index])
		record[key] = String(columns[index]) if index < columns.size() else ""
	return record
