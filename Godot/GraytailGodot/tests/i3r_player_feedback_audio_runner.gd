extends SceneTree

const PlayerFeedbackServiceScript := preload("res://scripts/presentation/player_feedback_service.gd")
const SettingsManagerScript := preload("res://scripts/core/settings/settings_manager.gd")
const SettingsStoreScript := preload("res://scripts/core/settings/settings_store.gd")
const SettingsPanelScript := preload("res://scripts/ui/settings/settings_panel.gd")

const PASS_MARKER := "I3R_PLAYER_FEEDBACK_AUDIO=PASS"
const FAIL_MARKER := "I3R_PLAYER_FEEDBACK_AUDIO=FAIL"
const TEST_PATH := "user://i3r_tests/player_feedback_settings.cfg"
const SCHEMA_TWO_PATH := "user://i3r_tests/player_feedback_schema_two.cfg"
const REGISTRY_PATH := "res://../../docs/00_governance/I3R_UE_GENERATED_SFX_IMPORT_REGISTRY.csv"
const MANIFEST_PATH := "res://data/assets/asset_manifest.csv"
const REDUCE_MOTION_KEY := "accessibility/reduce_motion"
const HAPTICS_KEY := "accessibility/haptics_enabled"

var failures: Array[String] = []
var playback_reports: Array[Dictionary] = []
var vibration_reports: Array[Dictionary] = []
var fake_devices: Array[int] = []
var now_msec := 1000

var previous_master_db := 0.0
var previous_master_mute := false
var effects_bus_existed := false
var previous_effects_db := 0.0
var previous_effects_mute := false
var had_reduce_motion := false
var previous_reduce_motion: Variant
var had_haptics := false
var previous_haptics: Variant


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_capture_runtime_state()
	_cleanup_settings(TEST_PATH)
	_cleanup_settings(SCHEMA_TWO_PATH)
	_check_registry_and_routes()
	await _check_service_and_settings_transaction()
	_check_schema_two_migration()
	await _check_run_scene_feedback_bridge()
	_restore_runtime_state()
	_cleanup_settings(TEST_PATH)
	_cleanup_settings(SCHEMA_TWO_PATH)
	_finish()


func _check_registry_and_routes() -> void:
	var routes: Dictionary = PlayerFeedbackServiceScript.ROUTES
	_require_equal(routes.size(), 13, "player-facing cue route count")
	var expected_assets := [
		"audio.sfx.attack",
		"audio.sfx.click",
		"audio.sfx.death",
		"audio.sfx.explosion",
		"audio.sfx.extract",
		"audio.sfx.heal",
		"audio.sfx.hit",
		"audio.sfx.hurt",
		"audio.sfx.pickup",
	]
	var actual_assets: Array[String] = []
	for route in routes.values():
		var asset_key := String((route as Dictionary).get("asset_key", &""))
		if not actual_assets.has(asset_key):
			actual_assets.append(asset_key)
		var runtime_path := String((route as Dictionary).get("path", ""))
		_require(ResourceLoader.exists(runtime_path), "cue runtime stream is missing: %s" % runtime_path)
	actual_assets.sort()
	expected_assets.sort()
	_require_equal(actual_assets, expected_assets, "nine admitted SFX are the complete route asset set")

	var manifest_text := FileAccess.get_file_as_string(MANIFEST_PATH)
	for asset_id in expected_assets:
		_require(manifest_text.contains("\n%s," % asset_id), "asset manifest is missing %s" % asset_id)
	_require(manifest_text.count("\naudio.sfx.") == 9, "asset manifest does not contain exactly nine SFX rows")

	var registry_absolute := ProjectSettings.globalize_path(REGISTRY_PATH)
	_require(FileAccess.file_exists(registry_absolute), "I3R SFX source registry is missing")
	if FileAccess.file_exists(registry_absolute):
		var registry_text := FileAccess.get_file_as_string(registry_absolute)
		_require(registry_text.count("\naudio.sfx.") == 9, "source registry does not contain exactly nine SFX rows")
		_require(not registry_text.to_lower().contains("bgm"), "source registry admitted an unapproved BGM")

	var run_scene_source := FileAccess.get_file_as_string("res://scripts/core/run/run_scene.gd")
	for bridge_token in [
		"player_attack_started",
		"player_attack_resolved",
		"player_damaged",
		"enemy_defeated",
		"mine_triggered",
		"CUE_CHEST_OPEN",
		"CUE_SEARCH_REVEAL",
		"CUE_PICKUP",
		"CUE_EXTRACTION_SUCCESS",
		"CUE_EXTRACTION_FAILURE",
	]:
		_require(run_scene_source.contains(bridge_token), "RunScene feedback bridge is missing %s" % bridge_token)


func _check_service_and_settings_transaction() -> void:
	var manager := SettingsManagerScript.new(TEST_PATH)
	manager.name = "I3RFeedbackSettingsManager"
	root.add_child(manager)
	var service = PlayerFeedbackServiceScript.new()
	service.name = "I3RPlayerFeedbackService"
	service.set_test_adapters(
		Callable(self, "_fake_now_msec"),
		Callable(self, "_capture_playback"),
		Callable(self, "_fake_joypads"),
		Callable(self, "_capture_vibration")
	)
	service.bind_settings_manager(manager)
	root.add_child(service)
	await process_frame

	var no_device: Dictionary = service.emit_cue(
		PlayerFeedbackServiceScript.CUE_UI_CONFIRM,
		"domain:ui:1",
		{"fixture": &"no_device"}
	)
	_require(bool(no_device.get("accepted", false)), "first UI cue was rejected")
	_require(bool(no_device.get("audio_played", false)), "audible UI cue did not reach playback")
	_require(not bool(no_device.get("vibration_played", true)), "no-device path attempted vibration")
	_require_equal(playback_reports.size(), 1, "first cue playback count")

	var duplicate: Dictionary = service.emit_cue(
		PlayerFeedbackServiceScript.CUE_UI_CONFIRM,
		"domain:ui:1",
		{"fixture": &"duplicate"}
	)
	_require_equal(StringName(duplicate.get("reason", &"")), &"duplicate_domain_event", "duplicate event reason")
	_require_equal(playback_reports.size(), 1, "duplicate cue replayed audio")
	now_msec += 10000
	var delayed_duplicate: Dictionary = service.emit_cue(
		PlayerFeedbackServiceScript.CUE_UI_CONFIRM,
		"domain:ui:1",
		{"fixture": &"delayed_duplicate"}
	)
	_require_equal(StringName(delayed_duplicate.get("reason", &"")), &"duplicate_domain_event", "delayed duplicate event reason")
	_require_equal(playback_reports.size(), 1, "delayed duplicate cue replayed audio")

	fake_devices = [7]
	service.set_active_joypad_device(7)
	var hurt: Dictionary = service.emit_cue(
		PlayerFeedbackServiceScript.CUE_PLAYER_HURT,
		"domain:combat:hurt:1"
	)
	_require(bool(hurt.get("vibration_played", false)), "connected-device hurt cue skipped vibration")
	_require_equal(int(hurt.get("joypad_device", -1)), 7, "active semantic joypad device")
	_require_equal(vibration_reports.size(), 1, "connected-device vibration count")

	_require(manager.begin_transaction(), "audio settings transaction did not begin")
	_require(manager.set_draft_value(&"master_volume", 55), "master volume draft rejected")
	_require(manager.set_draft_value(&"effects_volume", 35), "effects volume draft rejected")
	_require(manager.set_draft_value(&"haptics_enabled", false), "haptics draft rejected")
	_require(manager.apply_draft(), "audio settings apply failed")
	var applied: Dictionary = manager.get_applied_settings()
	_require_equal(applied.get("master_volume"), 55, "master volume applied")
	_require_equal(applied.get("effects_volume"), 35, "effects volume applied")
	_require_equal(applied.get("haptics_enabled"), false, "haptics applied")
	var service_snapshot: Dictionary = service.debug_snapshot()
	_require_equal(service_snapshot.get("master_volume"), 55, "service master volume update")
	_require_equal(service_snapshot.get("effects_volume"), 35, "service effects volume update")
	_require_equal(service_snapshot.get("haptics_enabled"), false, "service haptics update")
	_require_equal(ProjectSettings.get_setting(HAPTICS_KEY, true), false, "runtime haptics ProjectSetting")
	_check_bus_percent(&"Master", 55)
	_check_bus_percent(&"Effects", 35)

	var vibration_count_before_disabled := vibration_reports.size()
	service.emit_cue(PlayerFeedbackServiceScript.CUE_HIT, "domain:combat:hit:disabled")
	_require_equal(vibration_reports.size(), vibration_count_before_disabled, "disabled haptics still vibrated")

	manager.close_transaction()
	_require(manager.begin_transaction(), "dangerous rollback transaction did not begin")
	_require(manager.set_draft_value(&"resolution_id", "1600x900"), "rollback resolution draft rejected")
	_require(manager.set_draft_value(&"effects_volume", 10), "rollback effects draft rejected")
	_require(manager.set_draft_value(&"haptics_enabled", true), "rollback haptics draft rejected")
	_require(manager.set_draft_value(&"reduce_motion", true), "rollback reduced-motion draft rejected")
	_require(manager.apply_draft(), "dangerous preview apply failed")
	_require(manager.is_confirmation_pending(), "dangerous preview skipped confirmation")
	service_snapshot = service.debug_snapshot()
	_require_equal(service_snapshot.get("effects_volume"), 10, "service did not receive preview effects volume")
	_require_equal(service_snapshot.get("haptics_enabled"), true, "service did not receive preview haptics")
	_require_equal(service_snapshot.get("reduce_motion"), true, "service did not receive preview reduced motion")

	var reduced: Dictionary = service.emit_cue(
		PlayerFeedbackServiceScript.CUE_MINE_EXPLOSION,
		"domain:mine:reduced"
	)
	var reduced_vibration: Dictionary = reduced.get("vibration", {})
	_require(bool(reduced.get("audio_played", false)), "reduced motion incorrectly muted necessary audio")
	_require(float(reduced_vibration.get("weak", 1.0)) <= 0.12001, "reduced motion kept strong weak-motor vibration")
	_require(float(reduced_vibration.get("strong", 1.0)) <= 0.12001, "reduced motion kept strong strong-motor vibration")
	_require(float(reduced_vibration.get("duration", 1.0)) <= 0.08001, "reduced motion kept long vibration")

	_require(manager.revert_pending_changes(&"i3r_runner"), "dangerous preview rollback failed")
	service_snapshot = service.debug_snapshot()
	_require_equal(service_snapshot.get("effects_volume"), 35, "rollback did not restore service effects volume")
	_require_equal(service_snapshot.get("haptics_enabled"), false, "rollback did not restore service haptics")
	_require_equal(service_snapshot.get("reduce_motion"), false, "rollback did not restore service reduced motion")
	_check_bus_percent(&"Effects", 35)

	manager.close_transaction()
	_require(manager.begin_transaction(), "zero-volume transaction did not begin")
	_require(manager.set_draft_value(&"effects_volume", 0), "zero effects draft rejected")
	_require(manager.apply_draft(), "zero effects apply failed")
	var muted: Dictionary = service.emit_cue(PlayerFeedbackServiceScript.CUE_PICKUP, "domain:pickup:muted")
	_require(not bool(muted.get("audio_played", true)), "zero effects volume still played audio")
	_require_equal(StringName(muted.get("audio_suppressed", &"")), &"volume_zero", "zero-volume suppression reason")
	var effects_index := AudioServer.get_bus_index(&"Effects")
	_require(effects_index >= 0 and AudioServer.is_bus_mute(effects_index), "zero effects volume did not mute Effects bus")

	manager.close_transaction()
	service.queue_free()
	manager.queue_free()
	await process_frame


func _check_schema_two_migration() -> void:
	var legacy := ConfigFile.new()
	legacy.set_value("meta", "schema_version", 2)
	legacy.set_value("display", "window_mode", "windowed")
	legacy.set_value("display", "resolution_id", "1366x768")
	legacy.set_value("display", "vsync_mode", "enabled")
	legacy.set_value("display", "frame_limit", 60)
	legacy.set_value("audio", "master_volume", 65)
	legacy.set_value("accessibility", "reduce_motion", true)
	_require_equal(legacy.save(SCHEMA_TWO_PATH), OK, "schema-two fixture save")
	var manager := SettingsManagerScript.new(SCHEMA_TWO_PATH)
	root.add_child(manager)
	var migrated: Dictionary = manager.get_persisted_settings()
	_require_equal(migrated.get("master_volume"), 65, "schema-two master volume preserved")
	_require_equal(migrated.get("effects_volume"), 80, "schema-two effects volume default")
	_require_equal(migrated.get("haptics_enabled"), true, "schema-two haptics default")
	_require_equal(migrated.get("reduce_motion"), true, "schema-two reduced motion preserved")
	var repaired := ConfigFile.new()
	_require_equal(repaired.load(SCHEMA_TWO_PATH), OK, "schema-two repaired reload")
	_require_equal(
		int(repaired.get_value("meta", "schema_version", -1)),
		SettingsStoreScript.CURRENT_SCHEMA_VERSION,
		"schema-two migrated schema"
	)
	_require_equal(int(repaired.get_value("audio", "effects_volume", -1)), 80, "schema-two persisted effects default")
	_require_equal(bool(repaired.get_value("accessibility", "haptics_enabled", false)), true, "schema-two persisted haptics default")
	manager.free()


func _check_run_scene_feedback_bridge() -> void:
	playback_reports.clear()
	vibration_reports.clear()
	fake_devices.clear()
	var run_scene_resource := load("res://scenes/run/run_scene.tscn") as PackedScene
	_require(run_scene_resource != null, "production RunScene resource could not load")
	if run_scene_resource == null:
		return
	var run_scene := run_scene_resource.instantiate()
	root.add_child(run_scene)
	await process_frame
	await process_frame
	var service = run_scene.get("player_feedback_service")
	_require(service != null, "production RunScene did not own PlayerFeedbackService")
	if service == null:
		run_scene.queue_free()
		await process_frame
		return
	service.set_test_adapters(
		Callable(self, "_fake_now_msec"),
		Callable(self, "_capture_playback"),
		Callable(self, "_fake_joypads"),
		Callable(self, "_capture_vibration")
	)
	service.apply_settings({
		"master_volume": 80,
		"effects_volume": 80,
		"haptics_enabled": false,
		"reduce_motion": false,
	})
	service.clear_history_and_deduplication()
	var combat_snapshot := {
		"room_key": "2:3",
		"seed": 71,
		"defeated": false,
		"recent_events": [
			{"event_type": &"player_attack_started", "event_index": 1, "tick": 10},
			{"event_type": &"player_attack_resolved", "event_index": 2, "tick": 15, "hit_count": 1},
			{"event_type": &"player_damaged", "event_index": 3, "tick": 20, "damage": 4},
			{"event_type": &"enemy_defeated", "event_index": 4, "tick": 25, "enemy_id": "enemy_1"},
		],
	}
	run_scene.call("_route_combat_domain_feedback", combat_snapshot)
	var history: Array = service.history()
	_require_equal(history.size(), 4, "production combat bridge cue count")
	_require_equal(_history_cues(history), [&"attack", &"hit", &"player_hurt", &"enemy_death"], "production combat bridge cue order")
	run_scene.call("_route_combat_domain_feedback", combat_snapshot)
	_require_equal((service.history() as Array).size(), 4, "production combat recent-event replay was not suppressed")

	run_scene.call("_apply_room_entry_result", {
		"room_entry_result": {
			"room_type": &"Mine",
			"cause": &"mine_triggered",
			"first_trigger": true,
			"position": Vector2i(1, 1),
			"hp_delta": -8,
			"pressure_delta": 1,
			"fatal": false,
		},
	})
	history = service.history()
	_require_equal(StringName((history[history.size() - 1] as Dictionary).get("cue_id", &"")), &"mine_explosion", "production mine bridge cue")

	run_scene.call(
		"_show_command_feedback",
		{"ok": false, "command_id": &"fixture_reject", "status": &"blocked"},
		&"",
		"domain:ui:reject"
	)
	history = service.history()
	_require_equal(StringName((history[history.size() - 1] as Dictionary).get("cue_id", &"")), &"ui_reject", "production command reject bridge cue")
	run_scene.queue_free()
	await process_frame
	await process_frame


func _history_cues(history: Array) -> Array[StringName]:
	var cues: Array[StringName] = []
	for raw_entry in history:
		if raw_entry is Dictionary:
			cues.append(StringName((raw_entry as Dictionary).get("cue_id", &"")))
	return cues


func _capture_runtime_state() -> void:
	var master_index := AudioServer.get_bus_index(&"Master")
	if master_index < 0:
		master_index = 0
	previous_master_db = AudioServer.get_bus_volume_db(master_index)
	previous_master_mute = AudioServer.is_bus_mute(master_index)
	var effects_index := AudioServer.get_bus_index(&"Effects")
	effects_bus_existed = effects_index >= 0
	if effects_bus_existed:
		previous_effects_db = AudioServer.get_bus_volume_db(effects_index)
		previous_effects_mute = AudioServer.is_bus_mute(effects_index)
	had_reduce_motion = ProjectSettings.has_setting(REDUCE_MOTION_KEY)
	previous_reduce_motion = ProjectSettings.get_setting(REDUCE_MOTION_KEY, false)
	had_haptics = ProjectSettings.has_setting(HAPTICS_KEY)
	previous_haptics = ProjectSettings.get_setting(HAPTICS_KEY, true)


func _restore_runtime_state() -> void:
	var master_index := AudioServer.get_bus_index(&"Master")
	if master_index < 0:
		master_index = 0
	AudioServer.set_bus_volume_db(master_index, previous_master_db)
	AudioServer.set_bus_mute(master_index, previous_master_mute)
	var effects_index := AudioServer.get_bus_index(&"Effects")
	if effects_bus_existed:
		if effects_index >= 0:
			AudioServer.set_bus_volume_db(effects_index, previous_effects_db)
			AudioServer.set_bus_mute(effects_index, previous_effects_mute)
	elif effects_index >= 0:
		AudioServer.remove_bus(effects_index)
	if had_reduce_motion:
		ProjectSettings.set_setting(REDUCE_MOTION_KEY, previous_reduce_motion)
	else:
		ProjectSettings.clear(REDUCE_MOTION_KEY)
	if had_haptics:
		ProjectSettings.set_setting(HAPTICS_KEY, previous_haptics)
	else:
		ProjectSettings.clear(HAPTICS_KEY)


func _check_bus_percent(bus_name: StringName, expected_percent: int) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	_require(bus_index >= 0, "%s bus is missing" % String(bus_name))
	if bus_index < 0:
		return
	var expected_linear := float(expected_percent) / 100.0
	var actual_linear := db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	_require(
		is_equal_approx(actual_linear, expected_linear),
		"%s bus volume expected %.3f got %.3f" % [String(bus_name), expected_linear, actual_linear]
	)
	_require_equal(AudioServer.is_bus_mute(bus_index), expected_percent <= 0, "%s bus mute" % String(bus_name))


func _fake_now_msec() -> int:
	return now_msec


func _capture_playback(report: Dictionary) -> void:
	playback_reports.append(report.duplicate(true))


func _fake_joypads() -> Array[int]:
	return fake_devices.duplicate()


func _capture_vibration(device_id: int, vibration: Dictionary, report: Dictionary) -> void:
	vibration_reports.append({
		"device_id": device_id,
		"vibration": vibration.duplicate(true),
		"cue_id": report.get("cue_id", &""),
	})


func _cleanup_settings(path: String) -> void:
	for raw_suffix in ["", ".tmp", ".bak", ".corrupt"]:
		var suffix := String(raw_suffix)
		var candidate: String = path + suffix
		if not FileAccess.file_exists(candidate):
			continue
		var directory := DirAccess.open(candidate.get_base_dir())
		if directory != null:
			directory.remove(candidate.get_file())


func _require_equal(actual: Variant, expected: Variant, label: String) -> void:
	_require(actual == expected, "%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print(
			"%s cues=13 assets=9 settings=schema3,transaction,rollback volume=master,effects haptics=device,no_device,reduced_motion dedupe=domain_event"
			% PASS_MARKER
		)
		quit(0)
		return
	for failure in failures:
		push_error("I3R player feedback failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
