extends RefCounted
class_name SaveAdapter

const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")
const M7ProgressionServiceScript := preload("res://scripts/core/progression/m7_progression_service.gd")
const M7TalentCatalogScript := preload("res://scripts/core/progression/m7_talent_catalog.gd")

const M1_META_PROGRESS_PATH := "user://graytail_m1_meta_progress.json"
const SAVE_ROOT_DIR := "user://saves"
const SAVE_MANIFEST_PATH := "user://saves/manifest.json"
const SAVE_PROFILES_DIR := "user://saves/profiles"
const DEFAULT_PROFILE_ID := "default"
const DEFAULT_PROFILE_META_PROGRESS_PATH := "user://saves/profiles/default/meta_progress.json"
const DEFAULT_PROFILE_RUN_CHECKPOINT_PATH := "user://saves/profiles/default/run_checkpoint.json"
const DEFAULT_PROFILE_PREVIEW_PATH := "user://saves/profiles/default/preview.json"
const ATOMIC_TEMP_SUFFIX := ".tmp"
const LAST_VALID_BACKUP_SUFFIX := ".bak"
const CORRUPT_RECOVERY_SUFFIX := ".corrupt"

var last_error: String = ""
var last_load_status: String = ""
var last_load_result: Dictionary = {}


func build_run_save_snapshot(context: RunContext) -> Dictionary:
	if context == null:
		return {}
	return {
		"adapter_id": &"save_adapter_g8_1",
		"schema_version": 1,
		"run_id": context.run_id,
		"seed": context.seed_value,
		"mode": context.mode,
		"status_snapshot": context.get_status_snapshot(),
	}


func can_write_persistence() -> bool:
	return true


func describe_boundary() -> Dictionary:
	return {
		"adapter_id": &"save_adapter_m1",
		"writes_storage": true,
		"scope": &"m1_meta_progress_json",
		"path": DEFAULT_PROFILE_META_PROGRESS_PATH,
		"legacy_path": M1_META_PROGRESS_PATH,
		"profile_manifest_path": SAVE_MANIFEST_PATH,
	}


func default_meta_progress() -> Dictionary:
	var result := {
		"schema_version": 5,
		"gold": 0,
		"warehouse_items": _starter_warehouse_items(),
		"starter_grant_version": 1,
		"history_records": [],
		"profile_level": 1,
		"profile_exp": 0,
		"permit_level": 1,
		"protocol_difficulty": 5,
		"talent_points": 0,
		"talent_flags": [],
		"talent_budget_granted": 0,
		"talent_catalog_version": M7TalentCatalogScript.CATALOG_VERSION,
		"run_count": 0,
		"extract_count": 0,
		"fail_count": 0,
		"abandon_count": 0,
		"debug_used": false,
		"debug_commands": [],
		"committed_result_ids": [],
		"meta_action_receipts": {},
	}
	for key in M7ProgressionServiceScript.default_meta_fields().keys():
		result[key] = M7ProgressionServiceScript.default_meta_fields()[key]
	return result


func load_json_or_default(path: String = M1_META_PROGRESS_PATH, default_data: Dictionary = {}, normalize_meta_progress: bool = true) -> Dictionary:
	var result := load_json_result(path, default_data, normalize_meta_progress)
	return _dictionary_from(result.get("data", default_meta_progress()))


func load_json_result(path: String = M1_META_PROGRESS_PATH, default_data: Dictionary = {}, normalize_meta_progress: bool = true) -> Dictionary:
	last_error = ""
	last_load_status = ""
	var fallback := default_meta_progress() if default_data.is_empty() else default_data.duplicate(true)
	var primary := _read_json_file(path)
	if not bool(primary.get("exists", false)):
		var missing_backup := _read_json_file(path + LAST_VALID_BACKUP_SUFFIX)
		if bool(missing_backup.get("ok", false)):
			var missing_backup_dict := _dictionary_from(missing_backup.get("data", {}))
			var missing_backup_schema := int(missing_backup_dict.get("schema_version", fallback.get("schema_version", 1)))
			if missing_backup_schema <= int(fallback.get("schema_version", 1)):
				var missing_recovered_data := _normalize_meta_progress(missing_backup_dict, fallback) if normalize_meta_progress else missing_backup_dict.duplicate(true)
				return _recovered_load_result(missing_recovered_data, path + LAST_VALID_BACKUP_SUFFIX, "missing")
			last_error = "future_schema:%d" % missing_backup_schema
			return _load_result(false, "future_schema", fallback, last_error)
		return _load_result(true, "missing", fallback, "")
	if bool(primary.get("ok", false)):
		var parsed_dict := _dictionary_from(primary.get("data", {}))
		var schema_version := int(parsed_dict.get("schema_version", fallback.get("schema_version", 1)))
		if schema_version > int(fallback.get("schema_version", 1)):
			last_error = "future_schema:%d" % schema_version
			return _load_result(false, "future_schema", fallback, last_error)
		var loaded_data := _normalize_meta_progress(parsed_dict, fallback) if normalize_meta_progress else parsed_dict.duplicate(true)
		return _load_result(true, "loaded", loaded_data, "")
	var backup_path := path + LAST_VALID_BACKUP_SUFFIX
	var backup := _read_json_file(backup_path)
	if bool(backup.get("ok", false)):
		var backup_dict := _dictionary_from(backup.get("data", {}))
		var backup_schema := int(backup_dict.get("schema_version", fallback.get("schema_version", 1)))
		if backup_schema <= int(fallback.get("schema_version", 1)):
			var recovered_data := _normalize_meta_progress(backup_dict, fallback) if normalize_meta_progress else backup_dict.duplicate(true)
			return _recovered_load_result(recovered_data, backup_path, str(primary.get("status", "parse_failed")))
		last_error = "future_schema:%d" % backup_schema
		return _load_result(false, "future_schema", fallback, last_error)
	last_error = str(primary.get("error", primary.get("status", "parse_failed")))
	return _load_result(false, str(primary.get("status", "parse_failed")), fallback, last_error)


func save_json(data: Dictionary, path: String = M1_META_PROGRESS_PATH, normalize_meta_progress: bool = true) -> bool:
	last_error = ""
	_ensure_parent_dir(path)
	var temp_path := path + ATOMIC_TEMP_SUFFIX
	var backup_path := path + LAST_VALID_BACKUP_SUFFIX
	var corrupt_path := path + CORRUPT_RECOVERY_SUFFIX
	_remove_file_if_exists(temp_path)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		last_error = "open_failed:%s" % FileAccess.get_open_error()
		return false
	var output := _normalize_meta_progress(data, default_meta_progress()) if normalize_meta_progress else data.duplicate(true)
	file.store_string(JSON.stringify(output, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		last_error = "write_failed:%s" % write_error
		_remove_file_if_exists(temp_path)
		return false
	var staged := _read_json_file(temp_path)
	if not bool(staged.get("ok", false)):
		last_error = "staged_validation_failed:%s" % staged.get("status", "parse_failed")
		_remove_file_if_exists(temp_path)
		return false
	var staged_data := _dictionary_from(staged.get("data", {}))
	var staged_schema := int(staged_data.get("schema_version", 0))
	for protected_path in [path, backup_path]:
		var protected := _read_json_file(protected_path)
		if not bool(protected.get("ok", false)):
			continue
		var protected_data := _dictionary_from(protected.get("data", {}))
		var protected_schema := int(protected_data.get("schema_version", 0))
		if protected_schema > 0 and protected_schema > staged_schema:
			last_error = "future_schema_write_blocked:%d" % protected_schema
			_remove_file_if_exists(temp_path)
			return false

	var previous_location := ""
	if FileAccess.file_exists(path):
		var existing := _read_json_file(path)
		if bool(existing.get("ok", false)):
			_remove_file_if_exists(backup_path)
			if not _rename_file(path, backup_path):
				last_error = "backup_replace_failed"
				_remove_file_if_exists(temp_path)
				return false
			previous_location = backup_path
		else:
			_remove_file_if_exists(corrupt_path)
			if not _rename_file(path, corrupt_path):
				last_error = "corrupt_preserve_failed"
				_remove_file_if_exists(temp_path)
				return false
			previous_location = corrupt_path

	if not _rename_file(temp_path, path):
		last_error = "atomic_replace_failed"
		_restore_previous_file(previous_location, path)
		_remove_file_if_exists(temp_path)
		return false
	var committed := _read_json_file(path)
	if not bool(committed.get("ok", false)):
		last_error = "committed_validation_failed:%s" % committed.get("status", "parse_failed")
		_remove_file_if_exists(path)
		_restore_previous_file(previous_location, path)
		return false
	return true


func clear(path: String = M1_META_PROGRESS_PATH) -> bool:
	return save_json(default_meta_progress(), path)


func _ensure_parent_dir(path: String) -> void:
	var base_dir := path.get_base_dir()
	if base_dir == "" or base_dir == ".":
		return
	DirAccess.make_dir_recursive_absolute(base_dir)


func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"exists": false, "ok": false, "status": "missing", "error": ""}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var open_error := "open_failed:%s" % FileAccess.get_open_error()
		return {"exists": true, "ok": false, "status": "open_failed", "error": open_error}
	var text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {"exists": true, "ok": false, "status": "parse_failed", "error": "parse_failed"}
	var parsed: Variant = parser.data
	if not (parsed is Dictionary):
		return {"exists": true, "ok": false, "status": "parse_failed", "error": "parse_failed"}
	return {"exists": true, "ok": true, "status": "loaded", "error": "", "data": (parsed as Dictionary).duplicate(true)}


func _rename_file(source_path: String, target_path: String) -> bool:
	var source_absolute := ProjectSettings.globalize_path(source_path)
	var target_absolute := ProjectSettings.globalize_path(target_path)
	return DirAccess.rename_absolute(source_absolute, target_absolute) == OK


func _remove_file_if_exists(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _restore_previous_file(previous_path: String, target_path: String) -> void:
	if previous_path == "" or not FileAccess.file_exists(previous_path) or FileAccess.file_exists(target_path):
		return
	_rename_file(previous_path, target_path)


func _recovered_load_result(data: Dictionary, recovery_path: String, primary_status: String) -> Dictionary:
	last_load_status = "recovered_backup"
	last_load_result = {
		"ok": true,
		"status": "recovered_backup",
		"data": data.duplicate(true),
		"error": "",
		"read_only_fallback": false,
		"writes_storage": false,
		"recovery_path": recovery_path,
		"primary_status": primary_status,
	}
	return last_load_result.duplicate(true)


func _normalize_meta_progress(data: Dictionary, fallback: Dictionary) -> Dictionary:
	var result := fallback.duplicate(true)
	result["schema_version"] = maxi(int(data.get("schema_version", 1)), int(result.get("schema_version", 5)))
	result["gold"] = maxi(0, int(data.get("gold", result.get("gold", 0))))
	result["warehouse_items"] = _array_from(data.get("warehouse_items", result.get("warehouse_items", [])))
	var starter_version := maxi(0, int(data.get("starter_grant_version", 0)))
	if starter_version < 1:
		var warehouse_items: Array = result.get("warehouse_items", [])
		_append_missing_starter_items(warehouse_items)
		result["warehouse_items"] = warehouse_items
		starter_version = 1
	result["starter_grant_version"] = starter_version
	var history_records := _array_from(data.get("history_records", result.get("history_records", [])))
	while history_records.size() > 50:
		history_records.pop_front()
	result["history_records"] = history_records
	result["profile_level"] = maxi(1, int(data.get("profile_level", result.get("profile_level", 1))))
	result["profile_exp"] = maxi(0, int(data.get("profile_exp", result.get("profile_exp", 0))))
	result["permit_level"] = maxi(1, int(data.get("permit_level", result.get("permit_level", 1))))
	result["protocol_difficulty"] = maxi(1, int(data.get("protocol_difficulty", result.get("protocol_difficulty", 5))))
	result["talent_points"] = maxi(0, int(data.get("talent_points", result.get("talent_points", 0))))
	result["talent_flags"] = _array_from(data.get("talent_flags", result.get("talent_flags", [])))
	result["talent_budget_granted"] = maxi(0, int(data.get("talent_budget_granted", result.get("talent_budget_granted", 0))))
	result["talent_catalog_version"] = maxi(0, int(data.get("talent_catalog_version", result.get("talent_catalog_version", 0))))
	M7TalentCatalogScript.sync_progress(result, not data.has("talent_budget_granted"))
	result["run_count"] = maxi(0, int(data.get("run_count", result.get("run_count", 0))))
	result["extract_count"] = maxi(0, int(data.get("extract_count", result.get("extract_count", 0))))
	result["fail_count"] = maxi(0, int(data.get("fail_count", result.get("fail_count", 0))))
	result["abandon_count"] = maxi(0, int(data.get("abandon_count", result.get("abandon_count", 0))))
	result["debug_used"] = bool(data.get("debug_used", result.get("debug_used", false)))
	result["debug_commands"] = _array_from(data.get("debug_commands", result.get("debug_commands", [])))
	result["committed_result_ids"] = _array_from(data.get("committed_result_ids", result.get("committed_result_ids", [])))
	result["meta_action_receipts"] = _dictionary_from(data.get("meta_action_receipts", result.get("meta_action_receipts", {})))
	for key in M7ProgressionServiceScript.default_meta_fields().keys():
		if data.has(key):
			result[key] = data[key]
	return M7ProgressionServiceScript.normalize_meta(result)


func _starter_warehouse_items() -> Array:
	var result: Array = []
	var quantities := {
		"eq_goggles": 1,
		"eq_insulated_sleeve": 1,
		"con_ration": 2,
		"con_tape_roll": 1,
		"con_scan_pin": 1,
	}
	for item_id in quantities.keys():
		var definition := _catalog_item(str(item_id))
		for index in range(int(quantities[item_id])):
			var item := definition.duplicate(true)
			item["instance_id"] = "m6_starter:%s:%d" % [str(item_id), index + 1]
			item["source"] = "m6_starter_grant"
			item["source_label"] = "M6 初始整备"
			item["location_state"] = &"warehouse"
			result.append(item)
	return result


func _append_missing_starter_items(items: Array) -> void:
	var known: Dictionary = {}
	for raw_item in items:
		var item := _dictionary_from(raw_item)
		known[str(item.get("instance_id", ""))] = true
	for raw_starter in _starter_warehouse_items():
		var starter := _dictionary_from(raw_starter)
		if not known.has(str(starter.get("instance_id", ""))):
			items.append(starter)


func _catalog_item(item_id: String) -> Dictionary:
	for raw_item in M3ItemCatalogScript.all_items():
		var item := _dictionary_from(raw_item)
		if str(item.get("item_id", "")) == item_id:
			return item
	return {"item_id": item_id, "display_name": item_id, "item_type": "special", "weight": 1, "base_value": 0}


func _load_result(ok: bool, status: String, data: Dictionary, error: String) -> Dictionary:
	last_load_status = status
	last_load_result = {
		"ok": ok,
		"status": status,
		"data": data.duplicate(true),
		"error": error,
		"read_only_fallback": not ok,
		"writes_storage": false,
	}
	return last_load_result.duplicate(true)


func _array_from(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
