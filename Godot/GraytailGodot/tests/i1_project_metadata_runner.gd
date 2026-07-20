extends SceneTree

const PASS_MARKER := "I1_PROJECT_METADATA=PASS"
const FAIL_MARKER := "I1_PROJECT_METADATA=FAIL"
const RuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_require(not ProjectSettings.has_setting("autoload/GameKernel"), "inactive GameKernel remains an autoload")
	_require(
		ProjectSettings.get_setting("application/run/main_scene", "") == "res://scenes/main/main.tscn",
		"production main scene changed"
	)
	_require(
		ProjectSettings.get_setting("autoload/ContentDB", "") == "*res://scripts/core/content/content_db.gd",
		"ContentDB autoload path or enabled state changed"
	)
	_require(
		ProjectSettings.get_setting("autoload/SettingsManager", "") == "*res://scripts/core/settings/settings_manager.gd",
		"SettingsManager autoload path or enabled state changed"
	)
	var content_db := root.get_node_or_null("ContentDB")
	var settings_manager := root.get_node_or_null("SettingsManager")
	var content_records: Dictionary = content_db.get("asset_records") if content_db != null else {}
	_require(content_db != null and not content_records.is_empty(), "ContentDB autoload did not initialize the asset manifest")
	_require(settings_manager != null, "SettingsManager autoload did not initialize")
	_require(InputMap.has_action("debug_restart_run"), "debug_restart_run input action is missing")
	var features: PackedStringArray = ProjectSettings.get_setting("application/config/features", PackedStringArray())
	_require(features.has("4.6"), "project feature target is not Godot 4.6")
	var controller = RuntimeControllerScript.new()
	var ownership: Dictionary = controller.describe_ownership()
	_require(ownership.get("runtime_owner", "") == "RunRuntimeController", "runtime controller ownership changed")
	_require(ownership.get("lifecycle_owner", "") == "RunStateMachine", "state-machine ownership changed")
	if failures.is_empty():
		print(PASS_MARKER)
		print("I1_PROJECT_METADATA_DETAILS main_scene=main.tscn features=4.6 autoloads=ContentDB,SettingsManager debug_restart_run=present runtime=RunRuntimeController")
		quit(0)
		return
	for failure in failures:
		print("I1_PROJECT_METADATA_FAILURE %s" % failure)
	print(FAIL_MARKER)
	quit(1)


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
