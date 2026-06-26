extends RefCounted
class_name MetaProgressAdapter

const SaveAdapterScript := preload("res://scripts/core/save/save_adapter.gd")
const SaveProfileManifestScript := preload("res://scripts/core/save/save_profile_manifest.gd")

var save_adapter: SaveAdapter = SaveAdapterScript.new()
var data: Dictionary = {}
var last_commit: Dictionary = {}
var last_error: String = ""
var last_load_status: String = ""
var last_load_result: Dictionary = {}
var active_profile_id: String = SaveProfileManifestScript.DEFAULT_PROFILE_ID
var active_meta_progress_path: String = SaveProfileManifestScript.default_meta_progress_path()
var write_blocked: bool = false
var write_block_reason: String = ""


func _init() -> void:
	load_or_create_default()


func build_settlement_export(result_snapshot: Dictionary) -> Dictionary:
	return {
		"adapter_id": &"meta_progress_adapter_m1",
		"schema_version": 1,
		"writes_storage": true,
		"settlement": result_snapshot.get("settlement", {}),
		"warehouse_lite": result_snapshot.get("warehouse_lite", []),
		"gold_coin": result_snapshot.get("gold_coin", 0),
		"black_coin": result_snapshot.get("black_coin", 0),
	}


func can_write_persistence() -> bool:
	return not write_blocked


func describe_boundary() -> Dictionary:
	return {
		"adapter_id": &"meta_progress_adapter_m1",
		"writes_storage": can_write_persistence(),
		"scope": &"m1_minimal_meta_progress",
		"profile_id": active_profile_id,
		"path": active_meta_progress_path,
		"legacy_path": SaveAdapter.M1_META_PROGRESS_PATH,
		"write_blocked": write_blocked,
		"write_block_reason": write_block_reason,
	}

func set_active_profile_path(path: String, profile_id: String = SaveProfileManifestScript.DEFAULT_PROFILE_ID) -> void:
	active_profile_id = SaveProfileManifestScript.sanitize_profile_id(profile_id)
	active_meta_progress_path = path if path != "" else SaveProfileManifestScript.profile_paths(active_profile_id).get("meta_progress", SaveProfileManifestScript.default_meta_progress_path())
	load_or_create_default()


func load_or_create_default() -> Dictionary:
	last_error = ""
	var result := save_adapter.load_json_result(active_meta_progress_path, save_adapter.default_meta_progress())
	last_load_result = result.duplicate(true)
	last_load_status = str(result.get("status", ""))
	data = _dictionary_from(result.get("data", save_adapter.default_meta_progress()))
	write_blocked = bool(result.get("read_only_fallback", false))
	write_block_reason = "meta_progress_read_only_fallback" if write_blocked else ""
	if not bool(result.get("ok", false)):
		last_error = str(result.get("error", save_adapter.last_error))
	return data.duplicate(true)


func save() -> bool:
	if not _ensure_writable("save"):
		return false
	var ok := save_adapter.save_json(data, active_meta_progress_path)
	last_error = save_adapter.last_error
	return ok


func clear() -> Dictionary:
	if not _ensure_writable("clear"):
		return get_summary()
	data = save_adapter.default_meta_progress()
	save()
	return get_summary()


func apply_settlement(result_snapshot: Dictionary) -> Dictionary:
	if data.is_empty():
		load_or_create_default()
	if not _ensure_writable("apply_settlement"):
		last_commit = {
			"ok": false,
			"status": "write_blocked",
			"reason": write_block_reason,
			"result_id": _result_id(result_snapshot),
			"summary": get_summary(),
			"error": last_error,
		}
		return last_commit.duplicate(true)
	var result_id := _result_id(result_snapshot)
	var committed_ids: Array = _array_from(data.get("committed_result_ids", []))
	if result_id in committed_ids:
		last_commit = {
			"ok": true,
			"status": "duplicate_ignored",
			"duplicate": true,
			"result_id": result_id,
			"summary": get_summary(),
		}
		return last_commit.duplicate(true)

	var previous_data := data.duplicate(true)
	var settlement: Dictionary = _dictionary_from(result_snapshot.get("settlement", {}))
	var outcome := str(result_snapshot.get("outcome", settlement.get("outcome", "")))
	var settlement_outcome := str(settlement.get("outcome", ""))
	var is_success := outcome == "Extracted" or outcome == "Training Complete" or settlement_outcome == "success"
	var is_failure := outcome == "Failed" or settlement_outcome == "failure"

	data["run_count"] = int(data.get("run_count", 0)) + 1
	if is_success:
		data["extract_count"] = int(data.get("extract_count", 0)) + 1
		data["gold"] = int(data.get("gold", 0)) + _settlement_gold(result_snapshot, settlement)
		var warehouse_items: Array = _array_from(data.get("warehouse_items", []))
		for item in _array_from(settlement.get("warehouse_lite", result_snapshot.get("warehouse_lite", []))):
			warehouse_items.append(_minimal_item_record(item))
		data["warehouse_items"] = warehouse_items
	elif is_failure:
		data["fail_count"] = int(data.get("fail_count", 0)) + 1
		var salvage: Array = _array_from(settlement.get("salvaged_items", []))
		if salvage.is_empty():
			var failure_salvage: Dictionary = _dictionary_from(result_snapshot.get("failure_salvage", {}))
			salvage = _array_from(failure_salvage.get("salvaged_items", []))
		if not salvage.is_empty():
			var warehouse_items: Array = _array_from(data.get("warehouse_items", []))
			for item in salvage:
				warehouse_items.append(_minimal_item_record(item))
			data["warehouse_items"] = warehouse_items
	var run_debug_commands: Array = _array_from(result_snapshot.get("debug_commands", []))
	if not run_debug_commands.is_empty():
		for debug_entry in run_debug_commands:
			var debug_record: Dictionary = _dictionary_from(debug_entry)
			_record_debug_marker("run_%s" % str(debug_record.get("command", "debug_command")), _dictionary_from(debug_record.get("payload", debug_record)))
	elif bool(result_snapshot.get("debug_command_used", false)):
		var command: Dictionary = _dictionary_from(result_snapshot.get("result_source_command", {}))
		_record_debug_marker(str(command.get("command_name", "debug_result")), _dictionary_from(command.get("payload", {})))
	committed_ids.append(result_id)
	data["committed_result_ids"] = committed_ids
	var saved := save()
	if not saved:
		data = previous_data
	last_commit = {
		"ok": saved,
		"status": "committed" if saved else "save_failed",
		"duplicate": false,
		"result_id": result_id,
		"outcome": outcome,
		"summary": get_summary(),
		"error": last_error,
	}
	return last_commit.duplicate(true)


func get_summary() -> Dictionary:
	if data.is_empty():
		load_or_create_default()
	var warehouse_items: Array = _array_from(data.get("warehouse_items", []))
	return {
		"schema_version": int(data.get("schema_version", 1)),
		"gold": int(data.get("gold", 0)),
		"warehouse_items_count": warehouse_items.size(),
		"warehouse_items": warehouse_items.duplicate(true),
		"run_count": int(data.get("run_count", 0)),
		"extract_count": int(data.get("extract_count", 0)),
		"fail_count": int(data.get("fail_count", 0)),
		"debug_used": bool(data.get("debug_used", false)),
		"debug_commands": _array_from(data.get("debug_commands", [])),
		"last_commit": last_commit.duplicate(true),
		"last_load_status": last_load_status,
		"write_blocked": write_blocked,
		"write_block_reason": write_block_reason,
		"profile_id": active_profile_id,
		"last_error": last_error,
		"path": active_meta_progress_path,
	}


func mark_debug_command(command: String, payload: Dictionary = {}) -> Dictionary:
	if data.is_empty():
		load_or_create_default()
	if not _ensure_writable("mark_debug_command"):
		return get_summary()
	data["debug_used"] = true
	var commands: Array = _array_from(data.get("debug_commands", []))
	commands.append({
		"command": command,
		"payload": _json_safe(payload),
		"index": commands.size() + 1,
	})
	data["debug_commands"] = commands
	save()
	return get_summary()


func add_gold(amount: int, source: String = "debug") -> Dictionary:
	if data.is_empty():
		load_or_create_default()
	if not _ensure_writable("add_gold"):
		return get_summary()
	data["gold"] = maxi(0, int(data.get("gold", 0)) + amount)
	mark_debug_command("meta_add_gold", {"amount": amount, "source": source})
	return get_summary()


func set_gold(amount: int, source: String = "debug") -> Dictionary:
	if data.is_empty():
		load_or_create_default()
	if not _ensure_writable("set_gold"):
		return get_summary()
	data["gold"] = maxi(0, amount)
	mark_debug_command("meta_set_gold", {"amount": amount, "source": source})
	return get_summary()


func clear_gold() -> Dictionary:
	if data.is_empty():
		load_or_create_default()
	if not _ensure_writable("clear_gold"):
		return get_summary()
	data["gold"] = 0
	mark_debug_command("meta_clear_gold", {"source": "debug"})
	return get_summary()


func add_warehouse_item(item: Dictionary) -> Dictionary:
	if data.is_empty():
		load_or_create_default()
	if not _ensure_writable("add_warehouse_item"):
		return get_summary()
	var items: Array = _array_from(data.get("warehouse_items", []))
	items.append(_minimal_item_record(item))
	data["warehouse_items"] = items
	mark_debug_command("meta_add_warehouse_item", item)
	return get_summary()


func clear_warehouse(source: String = "debug") -> Dictionary:
	if data.is_empty():
		load_or_create_default()
	if not _ensure_writable("clear_warehouse"):
		return get_summary()
	data["warehouse_items"] = []
	mark_debug_command("meta_clear_warehouse", {"source": source})
	return get_summary()


func _result_id(result_snapshot: Dictionary) -> String:
	var explicit_id := str(result_snapshot.get("result_id", ""))
	if explicit_id != "":
		return explicit_id
	var run_id := str(result_snapshot.get("run_id", result_snapshot.get("mode", "run")))
	return "%s:%s:%s" % [run_id, str(result_snapshot.get("outcome", "")), int(result_snapshot.get("turn", 0))]


func _settlement_gold(result_snapshot: Dictionary, settlement: Dictionary) -> int:
	if settlement.has("gold_coin_gained"):
		return maxi(0, int(settlement.get("gold_coin_gained", 0)))
	if result_snapshot.has("extracted_pending_gold"):
		return maxi(0, int(result_snapshot.get("extracted_pending_gold", 0)))
	return maxi(0, int(result_snapshot.get("gold_coin", 0)))


func _minimal_item_record(item: Variant) -> Dictionary:
	var source := _dictionary_from(item)
	if source.is_empty():
		return {}
	return {
		"instance_id": str(source.get("instance_id", source.get("item_id", "item"))),
		"item_id": str(source.get("item_id", source.get("id", "item"))),
		"display_name": str(source.get("display_name", source.get("item_id", "item"))),
		"rarity": str(source.get("rarity", "common")),
		"base_value": maxi(0, int(source.get("base_value", source.get("value", 0)))),
		"source": str(source.get("source", "settlement")),
	}


func _record_debug_marker(command: String, payload: Dictionary = {}) -> void:
	if write_blocked:
		last_error = write_block_reason
		return
	data["debug_used"] = true
	var commands: Array = _array_from(data.get("debug_commands", []))
	commands.append({
		"command": command,
		"payload": _json_safe(payload),
		"index": commands.size() + 1,
	})
	data["debug_commands"] = commands


func _array_from(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _ensure_writable(operation: String = "write") -> bool:
	if write_blocked:
		last_error = "%s:%s" % [write_block_reason, operation]
		return false
	return true


func _json_safe(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		var dict_value := value as Dictionary
		for key in dict_value.keys():
			result[str(key)] = _json_safe(dict_value[key])
		return result
	if value is Array:
		var result: Array = []
		var array_value := value as Array
		for item in array_value:
			result.append(_json_safe(item))
		return result
	if value is Vector2i:
		var pos := value as Vector2i
		return {"x": pos.x, "y": pos.y}
	if value is Vector2:
		var vector := value as Vector2
		return {"x": vector.x, "y": vector.y}
	if value is StringName:
		return str(value)
	return value
