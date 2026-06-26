extends RefCounted
class_name SaveAdapter

const M1_META_PROGRESS_PATH := "user://graytail_m1_meta_progress.json"
const SAVE_ROOT_DIR := "user://saves"
const SAVE_MANIFEST_PATH := "user://saves/manifest.json"
const SAVE_PROFILES_DIR := "user://saves/profiles"
const DEFAULT_PROFILE_ID := "default"
const DEFAULT_PROFILE_META_PROGRESS_PATH := "user://saves/profiles/default/meta_progress.json"
const DEFAULT_PROFILE_RUN_CHECKPOINT_PATH := "user://saves/profiles/default/run_checkpoint.json"
const DEFAULT_PROFILE_PREVIEW_PATH := "user://saves/profiles/default/preview.json"

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
	return {
		"schema_version": 1,
		"gold": 0,
		"warehouse_items": [],
		"run_count": 0,
		"extract_count": 0,
		"fail_count": 0,
		"debug_used": false,
		"debug_commands": [],
		"committed_result_ids": [],
	}


func load_json_or_default(path: String = M1_META_PROGRESS_PATH, default_data: Dictionary = {}, normalize_meta_progress: bool = true) -> Dictionary:
	var result := load_json_result(path, default_data, normalize_meta_progress)
	return _dictionary_from(result.get("data", default_meta_progress()))


func load_json_result(path: String = M1_META_PROGRESS_PATH, default_data: Dictionary = {}, normalize_meta_progress: bool = true) -> Dictionary:
	last_error = ""
	last_load_status = ""
	var fallback := default_meta_progress() if default_data.is_empty() else default_data.duplicate(true)
	if not FileAccess.file_exists(path):
		return _load_result(true, "missing", fallback, "")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "open_failed:%s" % FileAccess.get_open_error()
		return _load_result(false, "open_failed", fallback, last_error)
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		var parsed_dict := parsed as Dictionary
		var schema_version := int(parsed_dict.get("schema_version", fallback.get("schema_version", 1)))
		if schema_version > int(fallback.get("schema_version", 1)):
			last_error = "future_schema:%d" % schema_version
			return _load_result(false, "future_schema", fallback, last_error)
		var loaded_data := _normalize_meta_progress(parsed_dict, fallback) if normalize_meta_progress else parsed_dict.duplicate(true)
		return _load_result(true, "loaded", loaded_data, "")
	last_error = "parse_failed"
	return _load_result(false, "parse_failed", fallback, last_error)


func save_json(data: Dictionary, path: String = M1_META_PROGRESS_PATH, normalize_meta_progress: bool = true) -> bool:
	last_error = ""
	_ensure_parent_dir(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_error = "open_failed:%s" % FileAccess.get_open_error()
		return false
	var output := _normalize_meta_progress(data, default_meta_progress()) if normalize_meta_progress else data.duplicate(true)
	file.store_string(JSON.stringify(output, "\t"))
	file.close()
	return true


func clear(path: String = M1_META_PROGRESS_PATH) -> bool:
	return save_json(default_meta_progress(), path)


func _ensure_parent_dir(path: String) -> void:
	var base_dir := path.get_base_dir()
	if base_dir == "" or base_dir == ".":
		return
	DirAccess.make_dir_recursive_absolute(base_dir)


func _normalize_meta_progress(data: Dictionary, fallback: Dictionary) -> Dictionary:
	var result := fallback.duplicate(true)
	result["schema_version"] = int(data.get("schema_version", result.get("schema_version", 1)))
	result["gold"] = maxi(0, int(data.get("gold", result.get("gold", 0))))
	result["warehouse_items"] = _array_from(data.get("warehouse_items", result.get("warehouse_items", [])))
	result["run_count"] = maxi(0, int(data.get("run_count", result.get("run_count", 0))))
	result["extract_count"] = maxi(0, int(data.get("extract_count", result.get("extract_count", 0))))
	result["fail_count"] = maxi(0, int(data.get("fail_count", result.get("fail_count", 0))))
	result["debug_used"] = bool(data.get("debug_used", result.get("debug_used", false)))
	result["debug_commands"] = _array_from(data.get("debug_commands", result.get("debug_commands", [])))
	result["committed_result_ids"] = _array_from(data.get("committed_result_ids", result.get("committed_result_ids", [])))
	return result


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
