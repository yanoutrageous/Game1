extends SceneTree

const DebugGateScript := preload("res://scripts/core/debug/debug_gate.gd")
const DebugFailureBundleScript := preload("res://scripts/core/debug/debug_failure_bundle.gd")
const DebugSandboxSessionScript := preload("res://scripts/core/debug/debug_sandbox_session.gd")
const DebugScenarioCatalogScript := preload("res://scripts/core/debug/debug_scenario_catalog.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const RunSceneMetaCommitterScript := preload("res://scripts/core/run/run_scene_meta_committer.gd")
const SaveManagerScript := preload("res://scripts/core/save/save_manager.gd")
const SaveProfileManifestScript := preload("res://scripts/core/save/save_profile_manifest.gd")
const SettingsPanelScript := preload("res://scripts/ui/settings/settings_panel.gd")
const RuntimeModalLayoutModelScript := preload("res://scripts/ui/run_surface/runtime_modal_layout_model.gd")

const PASS_MARKER := "I4_DEBUG_SANDBOX=PASS"
const FAIL_MARKER := "I4_DEBUG_SANDBOX=FAIL"
const TEST_PRODUCTION_PROFILE_ID := "i4_test_production"

var failures: Array[String] = []
var original_debug_setting: Variant


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	original_debug_setting = ProjectSettings.get_setting(DebugGateScript.ENABLE_SETTING, false)
	ProjectSettings.set_setting(DebugGateScript.ENABLE_SETTING, true)
	_cleanup()
	_check_profile_isolation_and_taint_guard()
	_check_reproduction_foundation()
	_check_debug_panel_geometry()
	await _check_settings_entry()
	_cleanup()
	ProjectSettings.set_setting(DebugGateScript.ENABLE_SETTING, original_debug_setting)
	if failures.is_empty():
		print(
			"%s profile=dev_sandbox taint_guard=PASS settings_entry=PASS "
			% PASS_MARKER
			+ "scenario_fixture=PASS save_injection=one_shot"
		)
		quit(0)
		return
	for failure in failures:
		printerr("%s:%s" % [FAIL_MARKER, failure])
	quit(1)


func _check_profile_isolation_and_taint_guard() -> void:
	var manager = SaveManagerScript.new()
	manager.manifest = SaveProfileManifestScript.default_manifest()
	var selected_test_profile := manager.switch_profile(
		TEST_PRODUCTION_PROFILE_ID,
		false
	)
	_require(
		bool(selected_test_profile.get("ok", false)),
		"could not select the disposable production-profile fixture"
	)
	var adapter = MetaProgressAdapterScript.new()
	manager.configure_meta_adapter(adapter)
	adapter.data["gold"] = 73
	_require(adapter.save(), "could not seed production profile")
	var before_hash := DebugSandboxSessionScript.profile_storage_hash(
		TEST_PRODUCTION_PROFILE_ID
	)

	var session = DebugSandboxSessionScript.new()
	var began: Dictionary = session.begin(
		manager,
		adapter,
		false,
		&"demo_7x7",
		1001
	)
	_require(bool(began.get("ok", false)), "sandbox session did not start")
	_require(
		str(adapter.active_profile_id) == SaveProfileManifestScript.DEBUG_SANDBOX_PROFILE_ID,
		"meta adapter did not switch to dev_sandbox"
	)
	var sandbox_hash_before_failure := DebugSandboxSessionScript.profile_storage_hash(
		SaveProfileManifestScript.DEBUG_SANDBOX_PROFILE_ID
	)
	var injection: Dictionary = adapter.debug_inject_next_save_failure()
	_require(
		bool(injection.get("ok", false)) and adapter.debug_save_failure_armed(),
		"sandbox could not arm one-shot persistence failure"
	)
	adapter.data["gold"] = 11
	_require(not adapter.save(), "injected sandbox persistence failure unexpectedly saved")
	_require(
		adapter.last_error == "debug_injected_next_save_failure",
		"injected sandbox persistence failure lost its exact reason"
	)
	_require(
		not adapter.debug_save_failure_armed(),
		"one-shot sandbox persistence failure remained armed after rejection"
	)
	_require(
		DebugSandboxSessionScript.profile_storage_hash(
			SaveProfileManifestScript.DEBUG_SANDBOX_PROFILE_ID
		) == sandbox_hash_before_failure,
		"injected failed save changed the sandbox file"
	)
	_require(adapter.save(), "sandbox did not recover on the save after one-shot rejection")
	adapter.data["gold"] = 0
	_require(adapter.save(), "sandbox could not restore its post-injection baseline")
	var debug_summary: Dictionary = adapter.add_gold(1000, "i4_debug_sandbox_runner")
	_require(int(debug_summary.get("gold", 0)) == 1000, "sandbox debug gold did not apply")
	_require(bool(debug_summary.get("debug_used", false)), "sandbox debug write did not taint meta")
	_require(
		DebugSandboxSessionScript.profile_storage_hash(
			TEST_PRODUCTION_PROFILE_ID
		) == before_hash,
		"sandbox debug write changed production profile"
	)
	var ended: Dictionary = session.end(manager, adapter, false)
	_require(bool(ended.get("ok", false)), "sandbox session did not close cleanly")
	_require(bool(ended.get("production_unchanged", false)), "production hash changed")
	_require(
		str(adapter.active_profile_id) == TEST_PRODUCTION_PROFILE_ID,
		"production profile was not restored"
	)
	var production_injection: Dictionary = adapter.debug_inject_next_save_failure()
	_require(
		not bool(production_injection.get("ok", true))
			and not adapter.debug_save_failure_armed(),
		"one-shot save failure injection escaped the dev_sandbox profile"
	)

	var blocked_debug_summary: Dictionary = adapter.add_gold(5, "default_profile_probe")
	_require(
		str(blocked_debug_summary.get("last_error", "")).begins_with(
			"debug_sandbox_profile_required"
		),
		"default profile accepted a direct debug write"
	)
	_require(
		DebugSandboxSessionScript.profile_storage_hash(
			TEST_PRODUCTION_PROFILE_ID
		) == before_hash,
		"blocked direct debug write changed production profile"
	)

	var read_before := DebugSandboxSessionScript.profile_storage_hash(
		TEST_PRODUCTION_PROFILE_ID
	)
	var read_summary := RunSceneMetaCommitterScript.debug_read_summary(
		adapter,
		"i4_read_only_probe"
	)
	var read_after := DebugSandboxSessionScript.profile_storage_hash(
		TEST_PRODUCTION_PROFILE_ID
	)
	_require(bool(read_summary.get("read_only_diagnostic", false)), "read diagnostic was not marked read-only")
	_require(
		read_after == read_before,
		"read-only diagnostic changed production profile: before=%s after=%s"
		% [read_before, read_after]
	)

	var tainted_result := {
		"result_id": "i4_debug_default:Abandoned:1",
		"outcome": "Abandoned",
		"debug_used": true,
		"debug_commands": [{"command": "debug_force_fail"}],
		"settlement": {
			"outcome": "abandon",
			"finalized": true,
			"long_term_gold_gained": 0,
		},
	}
	var blocked_settlement: Dictionary = adapter.apply_settlement(tainted_result)
	_require(
		str(blocked_settlement.get("status", "")) == "debug_tainted_production_profile_blocked",
		"tainted settlement was not blocked on production profile"
	)
	_require(
		DebugSandboxSessionScript.profile_storage_hash(
			TEST_PRODUCTION_PROFILE_ID
		) == before_hash,
		"blocked tainted settlement changed production profile"
	)


func _check_settings_entry() -> void:
	var panel = SettingsPanelScript.new()
	root.add_child(panel)
	await _wait_until(
		func() -> bool: return panel.get("test_room_button") is Button,
		"debug settings test-room entry"
	)
	var button: Button = panel.get("test_room_button")
	_require(button != null, "debug build settings did not expose the test-room entry")
	if button != null:
		_require(button.text == "进入隔离测试场", "test-room entry copy drifted")
		_require(
			button.tooltip_text.contains("dev_sandbox"),
			"test-room entry did not disclose the isolated profile"
		)
	panel.queue_free()
	await panel.tree_exited


func _check_reproduction_foundation() -> void:
	var coverage := DebugScenarioCatalogScript.coverage_report()
	_require(bool(coverage.get("ok", false)), "fixed scenario catalog misses required coverage")
	_require(int(coverage.get("scenario_count", 0)) >= 6, "fixed scenario catalog is incomplete")
	var session_snapshot := {
		"scenario_id": &"persistence_failure",
		"seed": 1501,
		"profile_id": SaveProfileManifestScript.DEBUG_SANDBOX_PROFILE_ID,
		"save_target": "user://profiles/dev_sandbox/meta_progress.json",
		"tainted": true,
		"production_hash_before": "before",
		"production_hash_after": "before",
	}
	var result := DebugFailureBundleScript.capture(
		null,
		session_snapshot,
		{"event_log": [{"event": "probe"}], "transaction_log": [{"transaction": "probe"}]},
		{"command": &"forced_save_failure"},
		{"modal_stack": [&"debug"]},
		7,
		"user://i4_failure_bundle_probe"
	)
	_require(bool(result.get("ok", false)), "failure bundle could not be written")
	var bundle: Dictionary = result.get("bundle", {})
	var validation := DebugFailureBundleScript.validate(bundle)
	_require(bool(validation.get("ok", false)), "failure bundle omitted reproduction fields")
	_require(str(bundle.get("reproduce", "")).contains("--scenario=persistence_failure"), "failure bundle lacks exact scenario command")
	_require(str(bundle.get("save_before", "")) == str(bundle.get("save_after", "")), "failure bundle lost save hash evidence")


func _check_debug_panel_geometry() -> void:
	for viewport_size in [
		Vector2i(1280, 720),
		Vector2i(1366, 768),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
	]:
		var layout := RuntimeModalLayoutModelScript.build({
			"supported_size": Vector2(viewport_size),
			"actual_viewport_size": viewport_size,
		})
		var rect: Rect2 = layout.get("debug", Rect2())
		_require(
			rect.size.x <= float(viewport_size.x) * 0.28 + 0.01,
			"debug panel exceeded 28%% width at %s" % viewport_size
		)
		_require(
			rect.size.y <= float(viewport_size.y) * 0.75 + 0.01,
			"debug panel exceeded 75%% height at %s" % viewport_size
		)
		_require(
			rect.position.y >= 104.0,
			"debug panel entered the protocol vertical safe band at %s" % viewport_size
		)
		_require(
			rect.end.y <= float(viewport_size.y) - 64.0,
			"debug panel entered the action-dock vertical safe band at %s" % viewport_size
		)
	var controller_source := FileAccess.get_file_as_string(
		"res://scripts/core/run/run_scene_debug_panel_controller.gd"
	)
	_require(controller_source.contains("\"CLEAN\""), "sandbox watermark omitted explicit CLEAN state")
	_require(controller_source.contains("commit=%s"), "sandbox watermark omitted commit identity")
	_require(controller_source.contains("profile=%s"), "sandbox watermark omitted profile identity")
	_require(controller_source.contains("scenario=%s"), "sandbox watermark omitted scenario identity")
	_require(controller_source.contains("save=%s"), "sandbox watermark omitted save-target identity")


func _cleanup() -> void:
	for profile_id in [
		TEST_PRODUCTION_PROFILE_ID,
		SaveProfileManifestScript.DEBUG_SANDBOX_PROFILE_ID,
	]:
		var path := str(
			SaveProfileManifestScript.profile_paths(profile_id).get("meta_progress", "")
		)
		for suffix in ["", ".tmp", ".bak", ".corrupt"]:
			var candidate: String = path + str(suffix)
			if FileAccess.file_exists(candidate):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _wait_until(predicate: Callable, label: String, timeout_ms: int = 5000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() <= deadline:
		if bool(predicate.call()):
			return true
		await process_frame
	failures.append("timed out waiting for semantic state: %s" % label)
	return false
