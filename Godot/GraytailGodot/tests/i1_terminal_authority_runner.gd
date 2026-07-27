extends SceneTree

const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")

var failures: Array[String] = []
var save_path := "user://i1_terminal_authority/meta_progress.json"


func _init() -> void:
	_cleanup()
	_validate_terminal_commit_without_ui()
	_validate_pending_failure_guard()
	_cleanup()
	if failures.is_empty():
		print("I1_TERMINAL_AUTHORITY=PASS no_ui_commit=PASS exactly_once=PASS pending_failure=PASS")
		quit(0)
		return
	for failure in failures:
		printerr("I1_TERMINAL_AUTHORITY=FAIL:%s" % failure)
	quit(1)


func _validate_terminal_commit_without_ui() -> void:
	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(save_path, "i1_terminal_authority")
	var controller = RunRuntimeControllerScript.new()
	controller.bind_meta_progress_adapter(adapter)
	var start_result: Dictionary = controller.command_bus.dispatch(&"start_demo_run")
	_require(bool(start_result.get("ok", false)), "demo start failed")
	var unconfirmed_result: Dictionary = controller.command_bus.dispatch(&"abandon_run", {"reason": "i1_no_ui"})
	_require(not bool(unconfirmed_result.get("ok", true)), "unconfirmed abandon terminal command was accepted")
	_require(
		StringName(unconfirmed_result.get("status", &"")) == &"abandon_confirmation_required",
		"unconfirmed abandon used the wrong rejection"
	)
	_require(bool(controller.context.run_active), "unconfirmed abandon changed active-run state")
	var abandon_result: Dictionary = controller.command_bus.dispatch(
		&"abandon_run",
		{"reason": "i1_no_ui", "confirmed": true}
	)
	_require(bool(abandon_result.get("ok", false)), "abandon terminal command failed")
	var summary: Dictionary = adapter.get_summary()
	_require(int(summary.get("run_count", 0)) == 1, "terminal result was not committed without RunScene")
	_require(int(summary.get("abandon_count", 0)) == 1, "abandon count was not committed")
	_require(str(controller.last_meta_commit.get("status", "")) == "committed", "runtime controller did not own terminal commit")

	controller.command_bus.result_available.emit(controller.context.result_snapshot)
	var duplicate_summary: Dictionary = adapter.get_summary()
	_require(int(duplicate_summary.get("run_count", 0)) == 1, "duplicate terminal signal committed twice")
	_require(str(controller.last_meta_commit.get("status", "")) == "duplicate_ignored", "duplicate terminal result was not identified")


func _validate_pending_failure_guard() -> void:
	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(save_path, "i1_terminal_authority")
	var before_runs := int(adapter.get_summary().get("run_count", 0))
	var controller = RunRuntimeControllerScript.new()
	controller.bind_meta_progress_adapter(adapter)
	controller.start_demo_run(null)
	controller.fail_run("i1_pending_failure")
	controller.command_bus.result_available.emit(controller.context.result_snapshot)
	_require(str(controller.last_meta_commit.get("status", "")) == "awaiting_salvage_confirmation", "pending failure reached persistence")
	_require(int(adapter.get_summary().get("run_count", 0)) == before_runs, "pending failure changed meta progress")
	var finalized: Dictionary = controller.confirm_failure_salvage([])
	_require(bool(finalized.get("ok", false)), "empty valid salvage confirmation failed")
	controller.command_bus.result_available.emit(controller.context.result_snapshot)
	_require(int(adapter.get_summary().get("run_count", 0)) == before_runs + 1, "finalized failure did not commit")
	_require(int(adapter.get_summary().get("fail_count", 0)) >= 1, "finalized failure did not update failure count")


func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		var path: String = save_path + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
