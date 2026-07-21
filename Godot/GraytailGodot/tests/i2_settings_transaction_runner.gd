extends SceneTree

const SettingsManagerScript := preload("res://scripts/core/settings/settings_manager.gd")
const SettingsStoreScript := preload("res://scripts/core/settings/settings_store.gd")

const PASS_MARKER := "I2_SETTINGS_TRANSACTION=PASS"
const FAIL_MARKER := "I2_SETTINGS_TRANSACTION=FAIL"
const TEST_PATH := "user://i2_tests/settings_transaction.cfg"
const FUTURE_PATH := "user://i2_tests/settings_future.cfg"
const BLOCKED_PARENT_PATH := "user://i2_tests/settings_blocked_parent"
const REDUCE_MOTION_KEY := "accessibility/reduce_motion"

var failures: Array[String] = []
var had_reduce_motion_setting := false
var previous_reduce_motion_value: Variant = null


class FakeClock:
	extends RefCounted
	var now := 1000

	func now_msec() -> int:
		return now


class FakeDisplayAdapter:
	extends RefCounted
	var calls: Array[Dictionary] = []
	var sizes: Array[Vector2i] = []

	func apply_settings(settings: Dictionary, resolution_size: Vector2i) -> Dictionary:
		calls.append(settings.duplicate(true))
		sizes.append(resolution_size)
		return {"ok": true}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	had_reduce_motion_setting = ProjectSettings.has_setting(REDUCE_MOTION_KEY)
	previous_reduce_motion_value = ProjectSettings.get_setting(REDUCE_MOTION_KEY, false)
	_cleanup_test_files(TEST_PATH)
	_cleanup_test_files(FUTURE_PATH)
	_cleanup_test_files(BLOCKED_PARENT_PATH)
	_check_transaction_and_atomic_store()
	_check_persistence_failure_rolls_back()
	_check_future_schema_protection()
	ProjectSettings.set_setting(
		REDUCE_MOTION_KEY,
		previous_reduce_motion_value if had_reduce_motion_setting else null
	)
	_cleanup_test_files(TEST_PATH)
	_cleanup_test_files(FUTURE_PATH)
	_cleanup_test_files(BLOCKED_PARENT_PATH)
	_finish()


func _check_transaction_and_atomic_store() -> void:
	var direct_store = SettingsStoreScript.new(TEST_PATH)
	var incomplete_save: Dictionary = direct_store.save_settings({"window_mode": "windowed"})
	_require(not bool(incomplete_save.get("ok", false)), "store accepted an incomplete settings payload")
	_require(not FileAccess.file_exists(TEST_PATH), "invalid settings payload created a file")

	var clock := FakeClock.new()
	var adapter := FakeDisplayAdapter.new()
	var manager = SettingsManagerScript.new(TEST_PATH, adapter, Callable(clock, "now_msec"))
	root.add_child(manager)

	var expected_fields := Array(SettingsStoreScript.field_names())
	expected_fields.sort()
	var actual_fields := manager.get_applied_settings().keys()
	actual_fields.sort()
	_require_equal(actual_fields, expected_fields, "frozen settings fields")
	_require_equal(manager.get_transaction_state(), &"idle", "initial transaction state")
	_require_equal(manager.get_applied_settings()["resolution_id"], "auto", "initial resolution")
	_require(not manager.set_draft_value(&"music_volume", 0.5), "unsupported audio field was accepted")

	_require(manager.begin_transaction(), "non-dangerous transaction did not begin")
	_require(manager.set_draft_value(&"frame_limit", 120), "frame limit draft was rejected")
	_require(manager.set_draft_value(&"reduce_motion", true), "reduce-motion draft was rejected")
	_require(manager.apply_draft(), "non-dangerous apply failed")
	_require_equal(manager.get_persisted_settings()["frame_limit"], 120, "non-dangerous persistence")
	_require_equal(manager.get_persisted_settings()["reduce_motion"], true, "reduce-motion persistence")
	_require(FileAccess.file_exists(TEST_PATH), "settings file was not created")
	_require(not FileAccess.file_exists(TEST_PATH + ".tmp"), "temporary file remained after save")
	manager.close_transaction()

	var rollback_baseline: Dictionary = manager.get_applied_settings()
	_require(manager.begin_transaction(), "dangerous transaction did not begin")
	_require(manager.set_draft_value(&"resolution_id", "1600x900"), "resolution draft was rejected")
	_require(manager.set_draft_value(&"frame_limit", 144), "combined frame-limit draft was rejected")
	_require(manager.set_draft_value(&"reduce_motion", false), "combined accessibility draft was rejected")
	_require(manager.apply_draft(), "dangerous preview apply failed")
	_require(manager.is_confirmation_pending(), "dangerous display change skipped confirmation")
	_require_equal(manager.confirmation_seconds_remaining(), 15, "confirmation countdown start")
	_require_equal(manager.get_persisted_settings(), rollback_baseline, "dangerous preview persisted before confirmation")
	_require_equal(manager.get_rollback_settings(), rollback_baseline, "complete rollback snapshot")
	clock.now = 16001
	manager.call("_process", 0.0)
	_require(not manager.is_confirmation_pending(), "display preview did not time out")
	_require_equal(manager.get_applied_settings(), rollback_baseline, "timeout did not restore every field")
	_require_equal(adapter.calls[adapter.calls.size() - 1], rollback_baseline, "adapter did not receive full rollback")
	manager.close_transaction()

	clock.now = 20000
	_require(manager.begin_transaction(), "confirmed transaction did not begin")
	_require(manager.set_draft_value(&"window_mode", "borderless"), "window-mode draft was rejected")
	_require(manager.set_draft_value(&"resolution_id", "1600x900"), "confirmed resolution draft was rejected")
	_require(manager.apply_draft(), "confirmed display preview failed")
	_require(manager.confirm_pending_changes(), "display confirmation did not persist")
	_require_equal(manager.get_persisted_settings()["window_mode"], "borderless", "confirmed window mode")
	_require_equal(manager.get_persisted_settings()["resolution_id"], "1600x900", "confirmed resolution")
	_require(FileAccess.file_exists(TEST_PATH + ".bak"), "atomic save did not keep a backup")
	_require(not FileAccess.file_exists(TEST_PATH + ".tmp"), "temporary file remained after confirmation")
	manager.close_transaction()
	manager.free()

	var corrupt_config := ConfigFile.new()
	corrupt_config.set_value("meta", "schema_version", SettingsStoreScript.CURRENT_SCHEMA_VERSION)
	corrupt_config.set_value("display", "window_mode", "windowed")
	corrupt_config.set_value("display", "resolution_id", "auto")
	corrupt_config.set_value("display", "vsync_mode", "enabled")
	corrupt_config.set_value("display", "frame_limit", "not-an-integer")
	corrupt_config.set_value("accessibility", "reduce_motion", false)
	_require_equal(corrupt_config.save(TEST_PATH), OK, "could not create invalid-primary fixture")
	var recovered_adapter := FakeDisplayAdapter.new()
	var recovered = SettingsManagerScript.new(TEST_PATH, recovered_adapter)
	root.add_child(recovered)
	_require_equal(recovered.load_status, &"recovered_and_repaired", "backup recovery status")
	_require_equal(recovered.get_persisted_settings(), rollback_baseline, "backup recovery payload")
	_require(FileAccess.file_exists(TEST_PATH + ".corrupt"), "corrupt primary was not preserved")
	var repaired := ConfigFile.new()
	_require_equal(repaired.load(TEST_PATH), OK, "repaired primary config")
	_require_equal(
		int(repaired.get_value("meta", "schema_version", -1)),
		SettingsStoreScript.CURRENT_SCHEMA_VERSION,
		"repaired schema version"
	)
	recovered.free()


func _check_persistence_failure_rolls_back() -> void:
	var base_directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(BLOCKED_PARENT_PATH.get_base_dir())
	)
	_require(base_directory_error in [OK, ERR_ALREADY_EXISTS], "blocked-parent fixture directory")
	var blocking_file := FileAccess.open(BLOCKED_PARENT_PATH, FileAccess.WRITE)
	_require(blocking_file != null, "blocked-parent fixture file")
	if blocking_file != null:
		blocking_file.store_string("not a directory")
		blocking_file = null
	var adapter := FakeDisplayAdapter.new()
	var manager = SettingsManagerScript.new(BLOCKED_PARENT_PATH + "/settings.cfg", adapter)
	root.add_child(manager)
	var before: Dictionary = manager.get_applied_settings()
	_require(manager.begin_transaction(), "write-failure transaction did not begin")
	_require(manager.set_draft_value(&"frame_limit", 120), "write-failure draft")
	_require(not manager.apply_draft(), "persistence failure masqueraded as success")
	_require_equal(manager.get_applied_settings(), before, "persistence failure rollback")
	_require_equal(manager.get_persisted_settings(), before, "persistence failure changed committed settings")
	_require(not manager.last_persistence_error.is_empty(), "persistence failure did not expose an error")
	manager.free()
	_cleanup_test_files(BLOCKED_PARENT_PATH)


func _check_future_schema_protection() -> void:
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FUTURE_PATH.get_base_dir()))
	_require(directory_error in [OK, ERR_ALREADY_EXISTS], "future-schema fixture directory")
	var future_config := ConfigFile.new()
	future_config.set_value("meta", "schema_version", SettingsStoreScript.CURRENT_SCHEMA_VERSION + 10)
	future_config.set_value("display", "window_mode", "windowed")
	future_config.set_value("display", "resolution_id", "auto")
	future_config.set_value("display", "vsync_mode", "enabled")
	future_config.set_value("display", "frame_limit", 0)
	future_config.set_value("accessibility", "reduce_motion", false)
	_require_equal(future_config.save(FUTURE_PATH), OK, "future-schema fixture save")

	var manager = SettingsManagerScript.new(FUTURE_PATH, FakeDisplayAdapter.new())
	root.add_child(manager)
	_require(manager.is_persistence_read_only(), "future schema did not enter read-only mode")
	_require_equal(manager.get_transaction_state(), &"read_only", "future-schema transaction state")
	_require(not manager.begin_transaction(), "future schema allowed a write transaction")
	_require(not FileAccess.file_exists(FUTURE_PATH + ".tmp"), "future schema created a temporary overwrite")
	var reloaded := ConfigFile.new()
	_require_equal(reloaded.load(FUTURE_PATH), OK, "future schema reload")
	_require_equal(
		int(reloaded.get_value("meta", "schema_version", -1)),
		SettingsStoreScript.CURRENT_SCHEMA_VERSION + 10,
		"future schema was overwritten"
	)
	manager.free()


func _cleanup_test_files(base_path: String) -> void:
	for suffix: String in ["", ".tmp", ".bak", ".corrupt"]:
		var path: String = base_path + suffix
		if not FileAccess.file_exists(path):
			continue
		var directory := DirAccess.open(path.get_base_dir())
		if directory != null:
			directory.remove(path.get_file())


func _require_equal(actual: Variant, expected: Variant, label: String) -> void:
	_require(actual == expected, "%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print(PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error("I2 settings transaction failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
