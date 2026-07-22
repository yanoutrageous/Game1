extends SceneTree

const SettingsManagerScript := preload("res://scripts/core/settings/settings_manager.gd")
const SettingsPanelScript := preload("res://scripts/ui/settings/settings_panel.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art24MotionSettingsScript := preload("res://scripts/presentation/art24/art24_motion_settings.gd")

const PASS_MARKER := "I2_ACCESSIBILITY_RUNTIME=PASS"
const FAIL_MARKER := "I2_ACCESSIBILITY_RUNTIME=FAIL"
const TEST_PATH := "user://i2_tests/accessibility_runtime.cfg"
const REDUCE_MOTION_KEY := "accessibility/reduce_motion"

var failures: Array[String] = []
var had_reduce_motion_setting := false
var previous_reduce_motion_value: Variant = null


class FakeDisplayAdapter:
	extends RefCounted
	var calls: Array[Dictionary] = []

	func apply_settings(settings: Dictionary, _resolution_size: Vector2i) -> Dictionary:
		calls.append(settings.duplicate(true))
		return {"ok": true}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	had_reduce_motion_setting = ProjectSettings.has_setting(REDUCE_MOTION_KEY)
	previous_reduce_motion_value = ProjectSettings.get_setting(REDUCE_MOTION_KEY, false)
	_cleanup_test_files()

	var adapter := FakeDisplayAdapter.new()
	var manager = SettingsManagerScript.new(TEST_PATH, adapter)
	root.add_child(manager)
	_require(manager.begin_transaction(), "accessibility transaction did not begin")
	_require(manager.set_draft_value(&"reduce_motion", true), "reduce-motion field was rejected")
	_require(manager.apply_draft(), "reduce-motion apply failed")
	_require_equal(ProjectSettings.get_setting(REDUCE_MOTION_KEY, false), true, "runtime reduce-motion setting")
	_require(Art10UISkinKitScript.reduce_motion_enabled(), "shared UI consumer did not see reduce motion")
	_require(Art24MotionSettingsScript.reduce_motion_enabled(), "in-run motion consumer did not see reduce motion")
	manager.close_transaction()

	var panel = SettingsPanelScript.new()
	root.add_child(panel)
	panel.bind_settings_manager(manager)
	_require(panel.open_panel(), "settings panel did not open a transaction")
	var expected_fields := ["frame_limit", "master_volume", "reduce_motion", "resolution_id", "vsync_mode", "window_mode"]
	var actual_fields := Array(panel.field_control_names())
	actual_fields.sort()
	_require_equal(actual_fields, expected_fields, "settings panel field contract")
	var master_volume_slider := panel.get("master_volume_slider") as HSlider
	var master_volume_value_label := panel.get("master_volume_value_label") as Label
	_require(master_volume_slider != null, "supported master-volume slider was not exposed")
	_require(master_volume_value_label != null, "supported master-volume value was not exposed")
	if master_volume_slider != null:
		_require_equal(master_volume_slider.min_value, 0.0, "master-volume minimum")
		_require_equal(master_volume_slider.max_value, 100.0, "master-volume maximum")
		_require_equal(master_volume_slider.step, 5.0, "master-volume step")
		_require_equal(int(round(master_volume_slider.value)), 80, "master-volume initial value")
	if master_volume_value_label != null:
		_require_equal(master_volume_value_label.text, "80%", "master-volume player value")
	var visible_copy := _collect_control_copy(panel).to_lower()
	_require(visible_copy.contains("主音量"), "supported master-volume copy was not exposed")
	for forbidden_text in [
		"music volume",
		"sound effect volume",
		"ui scale",
		"screen shake",
		"high contrast",
		"音乐音量",
		"音效音量",
		"界面缩放",
		"屏幕震动",
		"高对比",
		"色盲",
	]:
		_require(not visible_copy.contains(forbidden_text), "unsupported setting was exposed: %s" % forbidden_text)

	_require(manager.set_draft_value(&"reduce_motion", false), "dirty close fixture")
	_require(manager.set_draft_value(&"master_volume", 35), "dirty master-volume close fixture")
	panel.close_panel()
	_require_equal(manager.get_applied_settings()["reduce_motion"], true, "closing panel committed an unapplied draft")
	_require_equal(manager.get_applied_settings()["master_volume"], 80, "closing panel committed unapplied master volume")
	_require_equal(ProjectSettings.get_setting(REDUCE_MOTION_KEY, false), true, "closing panel changed applied accessibility")

	_require(panel.open_panel(), "settings panel did not reopen")
	_require(manager.set_draft_value(&"resolution_id", "1600x900"), "dangerous close fixture")
	_require(manager.set_draft_value(&"master_volume", 55), "combined master-volume close fixture")
	_require(manager.set_draft_value(&"reduce_motion", false), "combined close fixture")
	_require(manager.apply_draft(), "dangerous close preview")
	_require(manager.is_confirmation_pending(), "dangerous panel change skipped confirmation")
	_require_equal(manager.get_applied_settings()["master_volume"], 55, "dangerous preview master volume")
	panel.close_panel()
	_require_equal(manager.get_applied_settings()["resolution_id"], "auto", "panel close did not restore resolution")
	_require_equal(manager.get_applied_settings()["master_volume"], 80, "panel close did not restore master volume")
	_require_equal(manager.get_applied_settings()["reduce_motion"], true, "panel close did not restore complete rollback")
	_require_equal(ProjectSettings.get_setting(REDUCE_MOTION_KEY, false), true, "runtime accessibility rollback")
	_require(adapter.calls.size() >= 4, "display adapter did not observe apply/rollback lifecycle")

	panel.free()
	manager.free()
	ProjectSettings.set_setting(
		REDUCE_MOTION_KEY,
		previous_reduce_motion_value if had_reduce_motion_setting else null
	)
	_cleanup_test_files()
	_finish()


func _collect_control_copy(node: Node) -> String:
	var copy := ""
	if node is Label or node is Button or node is CheckButton:
		copy += String(node.get("text")) + "\n"
	for child in node.get_children():
		copy += _collect_control_copy(child)
	return copy


func _cleanup_test_files() -> void:
	for suffix: String in ["", ".tmp", ".bak", ".corrupt"]:
		var path := TEST_PATH + suffix
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
		push_error("I2 accessibility runtime failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
