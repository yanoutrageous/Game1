extends SceneTree

const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const ResultPanelScene := preload("res://scenes/ui/result/result_panel.tscn")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RunSceneResultControllerScript := preload("res://scripts/core/run/run_scene_result_controller.gd")

var failures: Array[String] = []
var blocker_path := "user://i2_terminal_commit_recovery/not_a_directory"
var blocked_save_path := blocker_path + "/meta_progress.json"
var result_signal_count: int = 0
var retry_request_count: int = 0
var discard_request_count: int = 0
var production_retry_command_count: int = 0
var production_result_signal_count: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	_validate_run_id_compatibility()
	var recovery_fixture := _validate_failed_commit_and_retry()
	await _validate_result_panel_guards(recovery_fixture)
	_cleanup()
	await _validate_production_run_scene_guards(recovery_fixture)
	_cleanup()
	if failures.is_empty():
		print("I2_TERMINAL_COMMIT_RECOVERY=PASS nonce=128bit legacy_ids=compatible save_failure=rollback retry=same_snapshot duplicate=idempotent result_signals=unchanged exits=guarded discard_confirmations=2")
		quit(0)
		return
	for failure in failures:
		printerr("I2_TERMINAL_COMMIT_RECOVERY=FAIL:%s" % failure)
	quit(1)


func _validate_run_id_compatibility() -> void:
	var seen: Dictionary = {}
	for index in range(12):
		var controller = RunRuntimeControllerScript.new()
		_require(bool(controller.start_demo_run(null).get("ok", false)), "run-id fixture %d did not start" % index)
		var run_id := String(controller.context.run_id)
		_require(not seen.has(run_id), "new controllers generated duplicate run id: %s" % run_id)
		seen[run_id] = true
		var pieces := run_id.split("_")
		var nonce := String(pieces[pieces.size() - 1]) if not pieces.is_empty() else ""
		_require(nonce.length() == 32 and _is_lower_hex(nonce), "run id nonce is not 128-bit hex: %s" % run_id)

	var legacy_id := "demo_1234_1:Abandoned:0"
	var legacy_adapter = MetaProgressAdapterScript.new()
	legacy_adapter.data = legacy_adapter.save_adapter.default_meta_progress()
	legacy_adapter.data["committed_result_ids"] = [legacy_id]
	var legacy_duplicate := legacy_adapter.apply_settlement({
		"result_id": legacy_id,
		"run_id": "demo_1234_1",
		"outcome": "Abandoned",
		"turn": 0,
		"settlement": {"outcome": &"abandon", "finalized": true},
	})
	_require(str(legacy_duplicate.get("status", "")) == "duplicate_ignored", "legacy result id was not preserved as opaque id")
	_require((legacy_adapter.data.get("committed_result_ids", []) as Array) == [legacy_id], "legacy committed id was migrated or rewritten")


func _validate_failed_commit_and_retry() -> Dictionary:
	var base_dir := blocker_path.get_base_dir()
	_require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_dir)) == OK, "could not create recovery fixture directory")
	var blocker := FileAccess.open(blocker_path, FileAccess.WRITE)
	_require(blocker != null, "could not create deterministic save blocker")
	if blocker == null:
		return {}
	blocker.store_string("this file intentionally blocks the settlement save parent")
	blocker.close()

	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(blocked_save_path, "i2_terminal_commit_recovery")
	var before_data: Dictionary = adapter.data.duplicate(true)
	var controller = RunRuntimeControllerScript.new()
	controller.bind_meta_progress_adapter(adapter)
	controller.command_bus.result_available.connect(func(_snapshot: Dictionary) -> void: result_signal_count += 1)
	_require(bool(controller.start_demo_run(null).get("ok", false)), "save-recovery fixture did not start")
	controller.context.asset_ledger.create_item_instance({
		"instance_id": "recovery_keep",
		"item_id": "recovery_keep",
		"display_name": "恢复测试样本",
		"short_description": "用于验证保存失败恢复。",
		"item_type": &"collectible",
		"rarity": &"tier_4",
		"weight": 2,
		"base_value": 30,
		"can_store": true,
	}, RunAssetLedger.LOCATION_INVENTORY)
	controller.context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, 17, "i2_recovery")
	_require(bool(controller.debug_force_extract().get("ok", false)), "save-recovery fixture did not reach terminal result")
	var terminal_snapshot: Dictionary = controller.context.result_snapshot.duplicate(true)
	controller.command_bus.result_available.emit(terminal_snapshot)
	_require(result_signal_count == 1, "initial terminal result signal count mismatch")
	_require(str(controller.last_meta_commit.get("status", "")) == "save_failed", "deterministic settlement save failure did not occur")
	_require(adapter.data == before_data, "save failure did not roll back complete meta data")
	_require(not (terminal_snapshot.get("result_id", "") in (adapter.data.get("committed_result_ids", []) as Array)), "failed save retained committed result id")
	var failed_display := RunSceneResultControllerScript.build_result_display_snapshot(terminal_snapshot, adapter.get_summary(), controller.last_meta_commit)
	_require(StringName(failed_display.get("persistence_state", &"")) == &"save_failed", "save failure display state was normalized incorrectly")
	_require(not bool(failed_display.get("normal_exit_allowed", true)), "save failure allowed normal exit")
	_require(bool(failed_display.get("retry_save_allowed", false)), "save failure did not expose retry")

	var still_blocked := controller.retry_terminal_commit()
	_require(str(still_blocked.get("status", "")) == "save_failed", "retry while blocked returned wrong status")
	_require(result_signal_count == 1, "retry re-emitted terminal result signal")
	_require(adapter.data == before_data, "blocked retry changed meta data")

	_require(DirAccess.remove_absolute(ProjectSettings.globalize_path(blocker_path)) == OK, "could not remove deterministic save blocker")
	var recovered := controller.retry_terminal_commit()
	_require(bool(recovered.get("ok", false)) and str(recovered.get("status", "")) == "committed", "same-snapshot retry did not recover")
	_require(result_signal_count == 1, "successful retry re-emitted terminal result signal")
	var committed_summary: Dictionary = adapter.get_summary()
	_require(int(committed_summary.get("run_count", 0)) == int(before_data.get("run_count", 0)) + 1, "recovered retry run count mismatch")
	_require(int(committed_summary.get("history_record_count", 0)) == (before_data.get("history_records", []) as Array).size() + 1, "recovered retry history count mismatch")
	_require(_warehouse_has(committed_summary.get("warehouse_items", []), "recovery_keep"), "recovered retry lost warehouse item")
	var committed_data: Dictionary = adapter.data.duplicate(true)
	var duplicate := controller.retry_terminal_commit()
	_require(str(duplicate.get("status", "")) == "duplicate_ignored", "second retry was not idempotent")
	_require(result_signal_count == 1, "duplicate retry re-emitted terminal result signal")
	_require(adapter.data == committed_data, "duplicate retry changed meta data")
	return {
		"snapshot": terminal_snapshot,
		"summary": adapter.get_summary(),
	}


func _validate_result_panel_guards(fixture: Dictionary) -> void:
	if fixture.is_empty():
		return
	var panel := ResultPanelScene.instantiate() as ResultPanel
	root.add_child(panel)
	await process_frame
	panel.retry_save_requested.connect(func() -> void: retry_request_count += 1)
	panel.discard_unsaved_result_requested.connect(func() -> void: discard_request_count += 1)
	var snapshot: Dictionary = fixture.get("snapshot", {})
	var display := RunSceneResultControllerScript.build_result_display_snapshot(snapshot, fixture.get("summary", {}), {"ok": false, "status": &"save_failed"})
	panel.show_summary(display)
	await process_frame
	_require(not panel.normal_exit_allowed(), "result panel allowed normal exit while unsaved")
	_require(panel.retry_save_allowed(), "result panel did not expose save retry")
	_require(panel.discard_unsaved_allowed(), "result panel did not expose guarded discard")
	_require(not panel.return_deploy_button.visible and panel.return_deploy_button.disabled, "unsaved result exposed deploy exit")
	_require(not panel.return_main_button.visible and panel.return_main_button.disabled, "unsaved result exposed main-menu exit")
	_require(panel.retry_save_button.is_visible_in_tree() and not panel.retry_save_button.disabled, "unsaved result retry action is not reachable")
	_require(panel.retry_save_button.focus_mode == Control.FOCUS_ALL, "unsaved result retry action is not keyboard focusable")
	_require(panel.discard_unsaved_button.is_visible_in_tree() and not panel.discard_unsaved_button.disabled, "unsaved result discard action is not reachable")
	_require(panel.discard_unsaved_button.focus_mode == Control.FOCUS_ALL, "unsaved result discard action is not keyboard focusable")
	panel.retry_save_button.grab_focus()
	await process_frame
	_require(root.gui_get_focus_owner() == panel.retry_save_button, "unsaved result retry action could not take focus")
	panel.retry_save_button.pressed.emit()
	panel.retry_save_button.pressed.emit()
	_require(retry_request_count == 1, "result panel emitted duplicate retry requests")
	panel.mark_retry_complete()
	panel.call("_request_discard_unsaved_result")
	_require(panel.discard_unsaved_confirmation_step == 1 and discard_request_count == 0, "first discard confirmation escaped or did not arm")
	panel.call("_request_discard_unsaved_result")
	panel.call("_request_discard_unsaved_result")
	_require(discard_request_count == 1, "discard escape did not require exactly two confirmations")

	var committed_display := RunSceneResultControllerScript.build_result_display_snapshot(snapshot, fixture.get("summary", {}), {"ok": true, "status": &"committed"})
	panel.show_summary(committed_display)
	await process_frame
	_require(panel.normal_exit_allowed(), "legacy-style committed snapshot did not restore normal exit")
	_require(panel.return_deploy_button.is_visible_in_tree() and not panel.return_deploy_button.disabled, "committed result deploy exit is not reachable")
	_require(panel.return_main_button.is_visible_in_tree() and not panel.return_main_button.disabled, "committed result main-menu exit is not reachable")
	_require(panel.return_deploy_button.focus_mode == Control.FOCUS_ALL and panel.return_main_button.focus_mode == Control.FOCUS_ALL, "committed result exit actions are not keyboard focusable")
	_require(not panel.retry_save_button.visible and panel.retry_save_button.disabled, "committed result retained retry action")
	_require(not panel.discard_unsaved_button.visible and panel.discard_unsaved_button.disabled, "committed result retained discard action")
	panel.return_deploy_button.grab_focus()
	await process_frame
	_require(root.gui_get_focus_owner() == panel.return_deploy_button, "committed result primary exit could not take focus")
	panel.queue_free()
	await process_frame


func _validate_production_run_scene_guards(fixture: Dictionary) -> void:
	if fixture.is_empty():
		return
	var blocker := FileAccess.open(blocker_path, FileAccess.WRITE)
	_require(blocker != null, "could not recreate production save blocker")
	if blocker == null:
		return
	blocker.store_string("this file intentionally blocks the production result retry save parent")
	blocker.close()

	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production Main scene could not be loaded for result recovery")
	if packed == null:
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var run_scene := main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing for result recovery")
	if run_scene == null:
		main.queue_free()
		return
	var runtime_controller = run_scene.get("runtime_controller")
	var run_context = run_scene.get("run_context")
	var command_bus = run_scene.get("command_bus")
	var panel = run_scene.get("result_panel")
	_require(runtime_controller != null and run_context != null and command_bus != null and panel != null, "production result recovery authority was not initialized")
	if runtime_controller == null or run_context == null or command_bus == null or panel == null:
		main.queue_free()
		return

	var isolated_adapter = MetaProgressAdapterScript.new()
	isolated_adapter.set_active_profile_path(blocked_save_path, "i2_terminal_commit_recovery_production")
	runtime_controller.bind_meta_progress_adapter(isolated_adapter)
	var terminal_snapshot: Dictionary = (fixture.get("snapshot", {}) as Dictionary).duplicate(true)
	run_context.result_snapshot = terminal_snapshot.duplicate(true)
	runtime_controller.last_meta_commit = {"ok": false, "status": &"save_failed", "committed": false}
	command_bus.command_requested.connect(_on_production_command_requested)
	command_bus.result_available.connect(_on_production_result_available)
	_require(bool(run_scene.call("_show_run_screen")), "production RunScene could not enter the run surface")
	var run_screen: StringName = StringName(run_scene.get("screen_state"))
	run_scene.call("_on_result_available", terminal_snapshot)
	await process_frame
	_require(bool(run_scene.call("_runtime_modal_is_top", &"result")), "production result modal was not registered as stack top")
	_require(not panel.normal_exit_allowed(), "production result panel allowed exit after save failure")

	# All ordinary routes, including the stack cancel used by Esc, must remain
	# locked while the authoritative settlement has not been persisted.
	run_scene.call("_return_from_result_to_main")
	run_scene.call("_return_from_result_to_deploy")
	run_scene.call("_cancel_result_modal", &"input_cancel")
	run_scene.call("_close_top_runtime_modal")
	_require(StringName(run_scene.get("screen_state")) == run_screen, "unsaved production result changed screen through an ordinary exit")
	_require(bool(run_scene.call("_runtime_modal_is_top", &"result")), "unsaved production result escaped through return or Esc")

	run_scene.call("_retry_terminal_commit_from_result")
	await process_frame
	_require(production_retry_command_count == 1, "production retry did not dispatch exactly one retry command")
	_require(production_result_signal_count == 0, "failed production retry re-emitted result_available")
	_require(not panel.normal_exit_allowed() and bool(run_scene.call("_runtime_modal_is_top", &"result")), "failed production retry unlocked or dismissed the result")
	_require(root.gui_get_focus_owner() == panel.retry_save_button, "failed production retry did not restore focus to retry")
	_require(DirAccess.remove_absolute(ProjectSettings.globalize_path(blocker_path)) == OK, "could not release production save blocker")
	run_scene.call("_retry_terminal_commit_from_result")
	await process_frame
	_require(production_retry_command_count == 2, "successful production retry did not dispatch exactly one additional command")
	_require(production_result_signal_count == 0, "successful production retry re-emitted result_available")
	_require(panel.normal_exit_allowed(), "successful production retry did not restore normal exits")
	_require(root.gui_get_focus_owner() == panel.return_deploy_button, "successful production retry did not move focus to the primary exit")
	run_scene.call("_return_from_result_to_deploy")
	_require(StringName(run_scene.get("screen_state")) == &"deploy_shell" and not bool(run_scene.call("_runtime_modal_is_top", &"result")), "saved production result did not return through Deploy authority")

	# Re-open an explicitly unsaved presentation and exercise the wired two-step
	# escape hatch. It must route only after the second confirmation and submit
	# no domain command.
	runtime_controller.last_meta_commit = {"ok": false, "status": &"save_failed", "committed": false}
	run_scene.set("screen_state", &"run")
	run_scene.call("_on_result_available", terminal_snapshot)
	await process_frame
	_require(StringName(run_scene.get("screen_state")) == &"run", "unsaved result setup did not begin from the production run route")
	panel.call("_request_discard_unsaved_result")
	_require(bool(run_scene.call("_runtime_modal_is_top", &"result")), "first production discard confirmation escaped the result")
	_require(StringName(run_scene.get("screen_state")) == &"run", "first production discard confirmation changed route")
	panel.call("_request_discard_unsaved_result")
	_require(not bool(run_scene.call("_runtime_modal_is_top", &"result")), "second production discard confirmation did not release the result")
	_require(StringName(run_scene.get("screen_state")) == &"deploy_shell", "production discard did not return to Deploy")
	_require(production_retry_command_count == 2, "production discard submitted a domain command")

	if command_bus.command_requested.is_connected(_on_production_command_requested):
		command_bus.command_requested.disconnect(_on_production_command_requested)
	if command_bus.result_available.is_connected(_on_production_result_available):
		command_bus.result_available.disconnect(_on_production_result_available)
	main.queue_free()
	for _unused in range(10):
		await process_frame


func _on_production_command_requested(command_name: StringName, _payload: Dictionary) -> void:
	if command_name == &"retry_terminal_commit":
		production_retry_command_count += 1


func _on_production_result_available(_snapshot: Dictionary) -> void:
	production_result_signal_count += 1


func _warehouse_has(items: Variant, instance_id: String) -> bool:
	if items is Array:
		for raw_item in items:
			if raw_item is Dictionary and String(raw_item.get("instance_id", "")) == instance_id:
				return true
	return false


func _is_lower_hex(value: String) -> bool:
	for index in range(value.length()):
		if "0123456789abcdef".find(value.substr(index, 1)) < 0:
			return false
	return true


func _cleanup() -> void:
	for path in [blocked_save_path, blocked_save_path + ".tmp", blocked_save_path + ".bak", blocked_save_path + ".corrupt", blocker_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var blocked_dir := ProjectSettings.globalize_path(blocker_path)
	if DirAccess.dir_exists_absolute(blocked_dir):
		DirAccess.remove_absolute(blocked_dir)


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
