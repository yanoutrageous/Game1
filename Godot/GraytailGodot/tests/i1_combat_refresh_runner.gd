extends SceneTree

const PASS_MARKER := "I1_COMBAT_REFRESH=PASS"
const FAIL_MARKER := "I1_COMBAT_REFRESH=FAIL"
const DAMAGE_SAMPLES := 180
const FULL_SAMPLES := 40

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production main scene could not be loaded")
	if packed == null:
		_finish([], [])
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var run_scene := main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing")
	if run_scene == null:
		main.queue_free()
		await process_frame
		_finish([], [])
		return
	var controller: Variant = run_scene.get("runtime_controller")
	var context: Variant = run_scene.get("run_context")
	var bus: Variant = run_scene.get("command_bus")
	_require(controller != null and context != null and bus != null, "runtime authority was not initialized")
	if controller == null or context == null or bus == null:
		main.queue_free()
		await process_frame
		_finish([], [])
		return

	var start_result: Dictionary = bus.dispatch(&"start_demo_run")
	_require(bool(start_result.get("ok", false)), "demo run could not be started")
	run_scene.call("_show_run_screen")
	context.max_hp = 10000
	context.hp = 10000
	var combat_pos: Vector2i = context.get_current_pos()
	context.truth_map.set_room_type(combat_pos, &"Monster")
	bus.room_resolver.enter_room(context)
	controller.in_run_runtime.sync_room(Vector2(0.50, 0.50))
	_require(context.current_room_type == &"Monster", "combat room setup failed")
	_require(controller.in_run_runtime.has_active_combat(), "production combat runtime did not activate")
	run_scene.call("_refresh_view_models")

	var observed_scopes: Array[StringName] = []
	bus.state_changed.connect(func(snapshot: Dictionary) -> void:
		observed_scopes.append(StringName(snapshot.get("_change_scope", &"missing")))
	)

	for warmup_index in range(8):
		bus.dispatch(&"apply_runtime_combat_damage", _damage_payload(warmup_index))
	run_scene.call("reset_refresh_metrics")
	observed_scopes.clear()

	var combat_samples: Array[int] = []
	for sample_index in range(DAMAGE_SAMPLES):
		var started_usec := Time.get_ticks_usec()
		var result: Dictionary = bus.dispatch(&"apply_runtime_combat_damage", _damage_payload(sample_index + 8))
		combat_samples.append(Time.get_ticks_usec() - started_usec)
		_require(bool(result.get("ok", false)), "combat damage command failed at sample %d" % sample_index)

	var combat_metrics: Dictionary = run_scene.call("get_refresh_metrics")
	_require(int(combat_metrics.get("combat_count", -1)) == DAMAGE_SAMPLES, "damage did not use exactly one combat refresh per command")
	_require(int(combat_metrics.get("full_count", -1)) == 0, "damage still triggered a full RunScene refresh")
	_require(StringName(combat_metrics.get("last_scope", &"missing")) == &"combat", "combat refresh scope was not retained")
	_require(observed_scopes.size() == DAMAGE_SAMPLES, "state signal count diverged from damage command count")
	for scope in observed_scopes:
		_require(scope == &"combat", "damage emitted a non-combat state scope")
	var run_surface: Variant = run_scene.get("run_surface")
	var combat_status_label: Variant = run_surface.get("scanner_legend_label") if run_surface != null else null
	_require(combat_status_label != null, "production combat status label is missing")
	if combat_status_label != null:
		var expected_hp_ratio := String(run_surface.call(
			"_compact_stat_token",
			"%s/%s" % [context.hp, context.max_hp]
		))
		_require(String(combat_status_label.text).contains(expected_hp_ratio), "lightweight combat refresh did not expose current HP")

	for warmup_index in range(4):
		bus.call("_emit_state")
	run_scene.call("reset_refresh_metrics")
	var full_samples: Array[int] = []
	for _sample_index in range(FULL_SAMPLES):
		var started_usec := Time.get_ticks_usec()
		bus.call("_emit_state")
		full_samples.append(Time.get_ticks_usec() - started_usec)
	var full_metrics: Dictionary = run_scene.call("get_refresh_metrics")
	_require(int(full_metrics.get("full_count", -1)) == FULL_SAMPLES, "full refresh control sample count diverged")
	_require(int(full_metrics.get("combat_count", -1)) == 0, "full refresh control unexpectedly used combat scope")

	var combat_p95 := _percentile(combat_samples, 0.95)
	var full_p95 := _percentile(full_samples, 0.95)
	_require(combat_p95 <= 8000, "combat refresh p95 exceeded 8 ms: %d usec" % combat_p95)
	_require(combat_p95 < full_p95, "combat refresh p95 was not lower than full refresh p95")

	main.queue_free()
	await process_frame
	await process_frame
	_finish(combat_samples, full_samples)


func _damage_payload(index: int) -> Dictionary:
	return {
		"source": "g41_combat_simulation",
		"damage": 1,
		"damage_kind": &"i1_refresh_probe",
		"source_id": "i1_probe",
		"combat_tick": index,
	}


func _percentile(samples: Array[int], percentile: float) -> int:
	if samples.is_empty():
		return -1
	var sorted := samples.duplicate()
	sorted.sort()
	var index := clampi(int(ceil(float(sorted.size() - 1) * percentile)), 0, sorted.size() - 1)
	return sorted[index]


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(combat_samples: Array[int], full_samples: Array[int]) -> void:
	var detail := "combat_p50=%dus combat_p95=%dus combat_p99=%dus combat_max=%dus full_p95=%dus samples=%d/%d" % [
		_percentile(combat_samples, 0.50),
		_percentile(combat_samples, 0.95),
		_percentile(combat_samples, 0.99),
		_percentile(combat_samples, 1.0),
		_percentile(full_samples, 0.95),
		combat_samples.size(),
		full_samples.size(),
	]
	if failures.is_empty():
		print(PASS_MARKER)
		print("I1_COMBAT_REFRESH_DETAILS %s" % detail)
		quit(0)
		return
	for failure in failures:
		print("I1_COMBAT_REFRESH_FAILURE %s" % failure)
	print("%s %s" % [FAIL_MARKER, detail])
	quit(1)
