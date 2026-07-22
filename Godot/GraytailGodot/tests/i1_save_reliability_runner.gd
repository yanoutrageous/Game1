extends SceneTree

const SaveAdapterScript := preload("res://scripts/core/save/save_adapter.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const M7ProgressionServiceScript := preload("res://scripts/core/progression/m7_progression_service.gd")

var failures: Array[String] = []
var save_path := "user://i1_save_reliability/meta_progress.json"
var long_term_save_path := "user://i1_save_reliability/long_term_meta_progress.json"
var blocked_parent_path := "user://i1_save_reliability/not_a_directory"
var blocked_long_term_save_path := blocked_parent_path + "/meta_progress.json"


func _init() -> void:
	_cleanup()
	_validate_atomic_round_trip()
	_validate_backup_recovery()
	_validate_future_schema_guard()
	_cleanup()
	_validate_long_term_view_transaction()
	_cleanup()
	if failures.is_empty():
		print("I1_SAVE_RELIABILITY=PASS atomic_replace=PASS backup_recovery=PASS future_schema=PASS long_term_view_rollback=PASS")
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


func _validate_long_term_view_transaction() -> void:
	var root_path := save_path.get_base_dir()
	_require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root_path)) == OK, "could not create long-term transaction test directory")
	var blocker := FileAccess.open(blocked_parent_path, FileAccess.WRITE)
	_require(blocker != null, "could not create deterministic save-failure blocker")
	if blocker == null:
		return
	blocker.store_string("this file intentionally blocks a child save path")
	blocker.close()

	var failing_adapter = MetaProgressAdapterScript.new()
	failing_adapter.set_active_profile_path(blocked_long_term_save_path, "i1_save_reliability_failure")
	_seed_long_term_unread_state(failing_adapter)
	var before_failure: Dictionary = failing_adapter.data.duplicate(true)
	var failure_result: Dictionary = failing_adapter.mark_long_term_viewed("all")
	_require(not bool(failure_result.get("ok", true)), "long-term viewed save failure unexpectedly succeeded")
	_require(str(failure_result.get("status", "")) == "save_failed", "long-term viewed save failure returned wrong status")
	_require(failing_adapter.data == before_failure, "long-term viewed save failure did not restore the complete in-memory data")
	var failure_summary: Dictionary = failure_result.get("summary", {})
	_require(failure_summary.get("unread_codex_ids", []) == before_failure.get("unread_codex_ids", []), "save-failure summary did not restore codex unread ids")
	_require(failure_summary.get("unread_history_ids", []) == before_failure.get("unread_history_ids", []), "save-failure summary did not restore history unread ids")
	_require(failure_summary.get("unread_collection_set_ids", []) == before_failure.get("unread_collection_set_ids", []), "save-failure summary did not restore collection unread ids")
	_require(failure_summary.get("red_dot_state", {}) == before_failure.get("red_dot_state", {}), "save-failure summary did not restore derived red dots")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_parent_path))
	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(long_term_save_path, "i1_save_reliability_success")
	for view_kind in ["codex", "history", "collection", "all"]:
		_seed_long_term_unread_state(adapter)
		var success_result: Dictionary = adapter.mark_long_term_viewed(view_kind)
		_require(bool(success_result.get("ok", false)), "valid long-term view kind failed to save: %s" % view_kind)
		_require(str(success_result.get("status", "")) == "viewed", "valid long-term view kind returned wrong status: %s" % view_kind)
		_validate_view_kind_cleared(adapter.data, view_kind)

	_seed_long_term_unread_state(adapter)
	var before_unknown: Dictionary = adapter.data.duplicate(true)
	var unknown_result: Dictionary = adapter.mark_long_term_viewed("task_archive")
	_require(not bool(unknown_result.get("ok", true)), "unknown long-term view kind unexpectedly succeeded")
	_require(str(unknown_result.get("status", "")) == "unknown_view_kind", "unknown long-term view kind returned wrong status")
	_require(adapter.data == before_unknown, "unknown long-term view kind changed in-memory data")


func _seed_long_term_unread_state(adapter) -> void:
	adapter.data["unread_codex_ids"] = ["codex:test"]
	adapter.data["unread_history_ids"] = ["history:test"]
	adapter.data["unread_collection_set_ids"] = ["collection:test"]
	M7ProgressionServiceScript.refresh_red_dots(adapter.data)
	_require(int((adapter.data.get("red_dot_state", {}) as Dictionary).get("new_codex", 0)) == 1, "codex red-dot fixture was not active")
	_require(int((adapter.data.get("red_dot_state", {}) as Dictionary).get("new_history", 0)) == 1, "history red-dot fixture was not active")
	_require(int((adapter.data.get("red_dot_state", {}) as Dictionary).get("collection_completed", 0)) == 1, "collection red-dot fixture was not active")


func _validate_view_kind_cleared(data: Dictionary, view_kind: String) -> void:
	var red_dots: Dictionary = data.get("red_dot_state", {})
	_require(data.get("unread_codex_ids", []).is_empty() == (view_kind in ["codex", "all"]), "codex unread state mismatch after view kind: %s" % view_kind)
	_require(data.get("unread_history_ids", []).is_empty() == (view_kind in ["history", "all"]), "history unread state mismatch after view kind: %s" % view_kind)
	_require(data.get("unread_collection_set_ids", []).is_empty() == (view_kind in ["collection", "all"]), "collection unread state mismatch after view kind: %s" % view_kind)
	_require((int(red_dots.get("new_codex", 0)) == 0) == (view_kind in ["codex", "all"]), "codex red dot mismatch after view kind: %s" % view_kind)
	_require((int(red_dots.get("new_history", 0)) == 0) == (view_kind in ["history", "all"]), "history red dot mismatch after view kind: %s" % view_kind)
	_require((int(red_dots.get("collection_completed", 0)) == 0) == (view_kind in ["collection", "all"]), "collection red dot mismatch after view kind: %s" % view_kind)


func _cleanup() -> void:
	for base_path in [save_path, long_term_save_path, blocked_long_term_save_path]:
		for suffix in ["", SaveAdapterScript.ATOMIC_TEMP_SUFFIX, SaveAdapterScript.LAST_VALID_BACKUP_SUFFIX, SaveAdapterScript.CORRUPT_RECOVERY_SUFFIX]:
			var path: String = base_path + str(suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if FileAccess.file_exists(blocked_parent_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_parent_path))


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
