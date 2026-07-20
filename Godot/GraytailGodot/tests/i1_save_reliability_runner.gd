extends SceneTree

const SaveAdapterScript := preload("res://scripts/core/save/save_adapter.gd")

var failures: Array[String] = []
var save_path := "user://i1_save_reliability/meta_progress.json"


func _init() -> void:
	_cleanup()
	_validate_atomic_round_trip()
	_validate_backup_recovery()
	_validate_future_schema_guard()
	_cleanup()
	if failures.is_empty():
		print("I1_SAVE_RELIABILITY=PASS atomic_replace=PASS backup_recovery=PASS future_schema=PASS")
		quit(0)
		return
	for failure in failures:
		printerr("I1_SAVE_RELIABILITY=FAIL:%s" % failure)
	quit(1)


func _validate_atomic_round_trip() -> void:
	var adapter = SaveAdapterScript.new()
	var first: Dictionary = adapter.default_meta_progress()
	first["gold"] = 11
	_require(adapter.save_json(first, save_path), "initial atomic save failed: %s" % adapter.last_error)
	_require(not FileAccess.file_exists(save_path + SaveAdapterScript.ATOMIC_TEMP_SUFFIX), "initial save left temp file")
	var first_load: Dictionary = adapter.load_json_result(save_path, adapter.default_meta_progress())
	_require(bool(first_load.get("ok", false)), "initial save did not load")
	_require(int((first_load.get("data", {}) as Dictionary).get("gold", -1)) == 11, "initial save changed payload")

	var second := first.duplicate(true)
	second["gold"] = 22
	_require(adapter.save_json(second, save_path), "replacement save failed: %s" % adapter.last_error)
	_require(FileAccess.file_exists(save_path + SaveAdapterScript.LAST_VALID_BACKUP_SUFFIX), "replacement save did not retain backup")
	_require(not FileAccess.file_exists(save_path + SaveAdapterScript.ATOMIC_TEMP_SUFFIX), "replacement save left temp file")
	var second_load: Dictionary = adapter.load_json_result(save_path, adapter.default_meta_progress())
	_require(int((second_load.get("data", {}) as Dictionary).get("gold", -1)) == 22, "replacement save did not commit new payload")
	var backup_load: Dictionary = adapter.load_json_result(save_path + SaveAdapterScript.LAST_VALID_BACKUP_SUFFIX, adapter.default_meta_progress())
	_require(int((backup_load.get("data", {}) as Dictionary).get("gold", -1)) == 11, "backup did not preserve previous valid payload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var interrupted_load: Dictionary = adapter.load_json_result(save_path, adapter.default_meta_progress())
	_require(str(interrupted_load.get("status", "")) == "recovered_backup", "missing primary did not recover interrupted replacement backup")
	_require(int((interrupted_load.get("data", {}) as Dictionary).get("gold", -1)) == 11, "interrupted replacement recovered wrong payload")
	second["gold"] = 22
	_require(adapter.save_json(second, save_path), "could not restore primary after interruption probe")


func _validate_backup_recovery() -> void:
	var corrupt := FileAccess.open(save_path, FileAccess.WRITE)
	_require(corrupt != null, "could not open primary for corruption probe")
	if corrupt == null:
		return
	corrupt.store_string("{broken-json")
	corrupt.close()
	var adapter = SaveAdapterScript.new()
	var recovered: Dictionary = adapter.load_json_result(save_path, adapter.default_meta_progress())
	_require(bool(recovered.get("ok", false)), "valid backup was not recovered")
	_require(str(recovered.get("status", "")) == "recovered_backup", "backup recovery status missing")
	_require(int((recovered.get("data", {}) as Dictionary).get("gold", -1)) == 11, "backup recovery returned wrong payload")

	var healed: Dictionary = recovered.get("data", {}).duplicate(true)
	healed["gold"] = 33
	_require(adapter.save_json(healed, save_path), "save after backup recovery failed: %s" % adapter.last_error)
	_require(FileAccess.file_exists(save_path + SaveAdapterScript.CORRUPT_RECOVERY_SUFFIX), "corrupt primary was not preserved")
	_require(not FileAccess.file_exists(save_path + SaveAdapterScript.ATOMIC_TEMP_SUFFIX), "recovery save left temp file")
	var healed_load: Dictionary = adapter.load_json_result(save_path, adapter.default_meta_progress())
	_require(int((healed_load.get("data", {}) as Dictionary).get("gold", -1)) == 33, "recovery save did not commit healed payload")


func _validate_future_schema_guard() -> void:
	var future := FileAccess.open(save_path, FileAccess.WRITE)
	_require(future != null, "could not open primary for future schema probe")
	if future == null:
		return
	future.store_string(JSON.stringify({"schema_version": 999, "gold": 999}))
	future.close()
	var adapter = SaveAdapterScript.new()
	var result: Dictionary = adapter.load_json_result(save_path, adapter.default_meta_progress())
	_require(not bool(result.get("ok", true)), "future schema unexpectedly loaded")
	_require(str(result.get("status", "")) == "future_schema", "future schema guard used backup instead of read-only fallback")
	var reread := FileAccess.open(save_path, FileAccess.READ)
	_require(reread != null, "future schema primary disappeared")
	var future_text := ""
	if reread != null:
		future_text = reread.get_as_text()
		var parsed: Variant = JSON.parse_string(future_text)
		reread.close()
		_require(parsed is Dictionary and int((parsed as Dictionary).get("schema_version", 0)) == 999, "future schema primary was modified")
	var downgrade := adapter.default_meta_progress()
	downgrade["gold"] = 1
	_require(not adapter.save_json(downgrade, save_path), "future schema was overwritten by a downgrade save")
	_require(adapter.last_error.begins_with("future_schema_write_blocked:"), "future schema write guard returned the wrong error")
	var after_block := FileAccess.open(save_path, FileAccess.READ)
	_require(after_block != null, "future schema primary disappeared after blocked write")
	if after_block != null:
		_require(after_block.get_as_text() == future_text, "blocked downgrade changed future schema bytes")
		after_block.close()
	_require(not FileAccess.file_exists(save_path + SaveAdapterScript.ATOMIC_TEMP_SUFFIX), "blocked future schema write left temp file")
	if FileAccess.file_exists(save_path + SaveAdapterScript.LAST_VALID_BACKUP_SUFFIX):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + SaveAdapterScript.LAST_VALID_BACKUP_SUFFIX))
	_require(
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(save_path),
			ProjectSettings.globalize_path(save_path + SaveAdapterScript.LAST_VALID_BACKUP_SUFFIX)
		) == OK,
		"could not stage future-schema interruption probe"
	)
	var missing_future: Dictionary = adapter.load_json_result(save_path, adapter.default_meta_progress())
	_require(not bool(missing_future.get("ok", true)), "missing primary recovered a future-schema backup")
	_require(str(missing_future.get("status", "")) == "future_schema", "future-schema backup did not keep storage read-only")
	_require(not adapter.save_json(downgrade, save_path), "missing primary allowed future-schema backup downgrade")
	_require(not FileAccess.file_exists(save_path), "blocked future-schema backup write created a downgraded primary")


func _cleanup() -> void:
	for suffix in ["", SaveAdapterScript.ATOMIC_TEMP_SUFFIX, SaveAdapterScript.LAST_VALID_BACKUP_SUFFIX, SaveAdapterScript.CORRUPT_RECOVERY_SUFFIX]:
		var path: String = save_path + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
