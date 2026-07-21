extends SceneTree

const CombatSimulationScript := preload("res://scripts/gameplay/combat/g41_combat_simulation.gd")
const RuntimeActorViewScript := preload("res://scripts/gameplay/runtime/g41_runtime_actor_view.gd")
const RuntimeTextureCacheScript := preload("res://scripts/presentation/runtime_texture_cache.gd")

const PASS_MARKER := "I2_COMBAT_FRAME_BASELINE=PASS"
const SMOKE_PASS_MARKER := "I2_COMBAT_FRAME_BASELINE_SMOKE=PASS"
const FAIL_MARKER := "I2_COMBAT_FRAME_BASELINE=FAIL"
const VISIBLE_MARKER := "I2_COMBAT_FRAME_VISIBLE=MEASURED_NOT_ACCEPTED"
const WORKLOAD_SCHEMA := "v2"
const FORMAL_WARMUP_FRAMES := 300
const FORMAL_SAMPLE_FRAMES := 3600
const SMOKE_WARMUP_FRAMES := 30
const SMOKE_SAMPLE_FRAMES := 120
const FIXED_DELTA := 1.0 / 60.0
const VISIBLE_MIN_SECONDS := 60.0
const PROJECTILE_PEAK_COUNT := 15
const PLAYER_DURABLE_HP := 1000000
const MEMORY_SAMPLE_INTERVAL := 60
const PRODUCTION_COMBAT_TEXTURE_COUNT := 71
const MIN_TEARDOWN_RESOURCE_RELEASE := 64

var failures: Array[String] = []
var smoke_mode := false
var visible_mode := false
var warmup_frames := FORMAL_WARMUP_FRAMES
var sample_frames := FORMAL_SAMPLE_FRAMES
var main: Node
var run_scene: Node
var runtime_controller: Variant
var context: Variant
var command_bus: Variant
var in_run_runtime: Variant
var room_runtime_view: Variant
var player_controller: Variant
var original_max_fps := 0
var original_vsync_mode := DisplayServer.VSYNC_DISABLED
var lifecycle_before: Dictionary = {}
var lifecycle_runtime_loaded: Dictionary = {}
var lifecycle_after: Dictionary = {}
var lifecycle_repeat_loaded: Dictionary = {}
var lifecycle_repeat_after: Dictionary = {}
var prewarm_report: Dictionary = {}
var authority_preflight_report: Dictionary = {}
var repeat_prewarm_report: Dictionary = {}
var repeat_authority_preflight_report: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_parse_mode()
	if not failures.is_empty():
		_finish([])
		return
	_freeze_engine_schedule()
	RuntimeTextureCacheScript.clear_for_tests()
	lifecycle_before = _lifecycle_metrics()
	root.size = Vector2i(1280, 720)
	if not await _build_production_runtime():
		_restore_engine_schedule()
		_finish([])
		return
	lifecycle_runtime_loaded = _lifecycle_metrics()

	var results: Array[Dictionary] = []
	for scenario in _scenario_definitions():
		var result := await _run_scenario(scenario)
		results.append(result)

	await _release_production_runtime()
	lifecycle_after = _lifecycle_metrics()
	await _run_repeat_lifecycle_probe()
	_apply_teardown_gates()
	_restore_engine_schedule()
	_finish(results)


func _parse_mode() -> void:
	for argument in OS.get_cmdline_user_args():
		match argument:
			"--i2-perf-smoke":
				smoke_mode = true
			"--i2-perf-visible":
				visible_mode = true
			_:
				failures.append("unknown user argument: %s" % argument)
	if smoke_mode:
		warmup_frames = SMOKE_WARMUP_FRAMES
		sample_frames = SMOKE_SAMPLE_FRAMES
	if visible_mode and smoke_mode:
		failures.append("visible measurement cannot use the shortened smoke workload")
	var display_name := DisplayServer.get_name().to_lower()
	if visible_mode and display_name == "headless":
		failures.append("visible measurement was requested with the headless display driver")
	if not visible_mode and display_name != "headless":
		failures.append("non-headless execution requires explicit --i2-perf-visible")


func _freeze_engine_schedule() -> void:
	original_max_fps = Engine.max_fps
	Engine.max_fps = 60 if visible_mode else 0
	if visible_mode:
		original_vsync_mode = DisplayServer.window_get_vsync_mode()
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)


func _restore_engine_schedule() -> void:
	Engine.max_fps = original_max_fps
	if visible_mode:
		DisplayServer.window_set_vsync_mode(original_vsync_mode)


func _build_production_runtime() -> bool:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production main scene could not be loaded")
	if packed == null:
		return false
	main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	run_scene = main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing")
	if run_scene == null:
		return false
	runtime_controller = run_scene.get("runtime_controller")
	context = run_scene.get("run_context")
	command_bus = run_scene.get("command_bus")
	in_run_runtime = run_scene.get("in_run_runtime")
	room_runtime_view = run_scene.get("room_runtime_view")
	player_controller = run_scene.get("player_controller")
	_require(runtime_controller != null, "RunRuntimeController was not initialized")
	_require(context != null and command_bus != null, "run authority was not initialized")
	_require(in_run_runtime != null, "G41InRunRuntime was not initialized")
	_require(room_runtime_view != null, "G41RoomRuntimeView was not initialized")
	_require(player_controller != null, "production PlayerController was not initialized")
	if not failures.is_empty():
		return false
	_require(not bool(context.run_active), "run authority was active before production asset admission")
	authority_preflight_report = run_scene.call("_run_start_asset_admission")
	_require(bool(authority_preflight_report.get("ok", false)), "production combat asset admission failed before authority commit")
	_require(int(authority_preflight_report.get("declared", -1)) == PRODUCTION_COMBAT_TEXTURE_COUNT, "production combat asset admission did not declare exactly %d textures" % PRODUCTION_COMBAT_TEXTURE_COUNT)
	_require(int(authority_preflight_report.get("cached", -1)) == PRODUCTION_COMBAT_TEXTURE_COUNT, "production combat asset admission did not cache every declared texture")
	_require(not bool(context.run_active), "production asset admission committed run authority")
	var start_result: Dictionary = command_bus.dispatch(&"start_demo_run")
	_require(bool(start_result.get("ok", false)), "demo run could not be started")
	run_scene.call("_show_run_screen")
	prewarm_report = (run_scene.get("last_combat_texture_prewarm_report") as Dictionary).duplicate(true)
	_require(bool(prewarm_report.get("ok", false)), "production combat prewarm report was not successful")
	_require(int(prewarm_report.get("declared", -1)) == PRODUCTION_COMBAT_TEXTURE_COUNT, "production combat prewarm did not declare exactly %d textures" % PRODUCTION_COMBAT_TEXTURE_COUNT)
	_require(int(prewarm_report.get("cached", -1)) == PRODUCTION_COMBAT_TEXTURE_COUNT, "production combat prewarm did not cache every declared texture")
	_require(int(prewarm_report.get("missing", -1)) == 0, "production combat prewarm declared missing textures")
	_require(int(prewarm_report.get("failures", -1)) == 0, "production combat prewarm failed to load textures")
	_require(int(prewarm_report.get("rejected", -1)) == 0, "production combat prewarm rejected an invalid path")
	context.max_hp = PLAYER_DURABLE_HP
	context.hp = PLAYER_DURABLE_HP
	var combat_pos: Vector2i = context.get_current_pos()
	context.truth_map.set_room_type(combat_pos, &"Monster")
	command_bus.room_resolver.enter_room(context)
	_require(context.current_room_type == &"Monster", "production Monster room setup failed")
	# The runner owns the outer schedule so simulation, snapshot and presentation
	# can be timed separately without adding probes to production scripts.
	run_scene.set_process(false)
	player_controller.set_process(false)
	await process_frame
	_require(not player_controller.is_processing(), "production PlayerController retained automatic processing")
	return failures.is_empty()


func _scenario_definitions() -> Array[Dictionary]:
	return [
		{
			"id": "enemy_1",
			"seed": 21001,
			"monster_types": [&"slime"],
			"expected_enemies": 1,
			"projectile_peak": false,
		},
		{
			"id": "enemy_3",
			"seed": 21003,
			"monster_types": [&"slime", &"bat", &"drone"],
			"expected_enemies": 3,
			"projectile_peak": false,
		},
		{
			"id": "enemy_5",
			"seed": 21005,
			"monster_types": [&"slime", &"bat", &"drone", &"bat", &"drone"],
			"expected_enemies": 5,
			"projectile_peak": false,
		},
		{
			"id": "projectile_peak",
			"seed": 21115,
			"monster_types": [&"drone"],
			"expected_enemies": 1,
			"projectile_peak": true,
		},
	]


func _run_scenario(definition: Dictionary) -> Dictionary:
	var cache_before_scenario: Dictionary = RuntimeTextureCacheScript.metrics()
	await _prepare_scenario(definition)
	var simulation: Variant = in_run_runtime.simulation
	var expected_enemies := int(definition.get("expected_enemies", 0))
	var projectile_peak := bool(definition.get("projectile_peak", false))
	var fixture_usec := 0
	var visual_contract := {
		"player_steps": 0,
		"actor_steps": 0,
		"actor_expected_steps": 0,
		"auto_process_violations": 0,
	}
	for frame_index in range(warmup_frames):
		await _drive_frame(simulation, frame_index, false, {}, projectile_peak, visual_contract)

	var cache_after_warmup: Dictionary = RuntimeTextureCacheScript.metrics()
	var measurements := _new_measurements()
	var visible_started_usec := Time.get_ticks_usec()
	var measured_frames := 0
	while measured_frames < sample_frames or (visible_mode and float(Time.get_ticks_usec() - visible_started_usec) / 1000000.0 < VISIBLE_MIN_SECONDS):
		fixture_usec += int(await _drive_frame(simulation, measured_frames, true, measurements, projectile_peak, visual_contract))
		var snapshot: Dictionary = measurements.get("last_snapshot", {})
		_require(_alive_enemy_count(snapshot) == expected_enemies, "%s enemy count drifted at frame %d" % [definition.get("id", "unknown"), measured_frames])
		if projectile_peak:
			_require((snapshot.get("projectiles", []) as Array).size() == PROJECTILE_PEAK_COUNT, "projectile_peak did not expose exactly %d projectiles at frame %d" % [PROJECTILE_PEAK_COUNT, measured_frames])
		measured_frames += 1

	var cache_after_sample: Dictionary = RuntimeTextureCacheScript.metrics()
	var result := _summarize_scenario(
		String(definition.get("id", "unknown")),
		measurements,
		cache_before_scenario,
		cache_after_warmup,
		cache_after_sample,
		fixture_usec,
		measured_frames,
		float(Time.get_ticks_usec() - visible_started_usec) / 1000000.0,
		visual_contract
	)
	_require(int(result.get("cache_failures", -1)) == 0, "%s encountered texture cache failures" % result.get("id", "unknown"))
	_require(int(result.get("cache_loads_delta", -1)) == 0, "%s loaded a combat actor texture after the production Run-entry prewarm" % result.get("id", "unknown"))
	_require(int(result.get("cache_failures_delta", -1)) == 0, "%s added texture cache failures after production prewarm" % result.get("id", "unknown"))
	_require(int(result.get("cache_entries_delta", -1)) == 0, "%s grew the combat actor texture cache after production prewarm" % result.get("id", "unknown"))
	_require(int(result.get("fixed_step_zero_frames", -1)) == 0, "%s produced zero-step sample frames" % result.get("id", "unknown"))
	_require(int(result.get("fixed_step_catch_up_frames", -1)) == 0, "%s unexpectedly entered catch-up under the steady schedule" % result.get("id", "unknown"))
	_require(int(result.get("fixed_step_saturated_frames", -1)) == 0, "%s saturated the 12-step catch-up cap" % result.get("id", "unknown"))
	_require(measured_frames >= sample_frames, "%s did not collect the frozen sample count" % result.get("id", "unknown"))
	_require(float((result.get("accumulator_ticks", {}) as Dictionary).get("max", 1.0)) <= 0.0001, "%s retained fixed-step accumulator backlog" % result.get("id", "unknown"))
	_require(int(result.get("player_visual_steps", -1)) == warmup_frames + measured_frames, "%s did not advance PlayerController exactly once per fixed frame" % result.get("id", "unknown"))
	_require(int(result.get("actor_visual_steps", -1)) == int(result.get("actor_visual_expected_steps", -2)), "%s did not advance every active ActorView exactly once per fixed frame" % result.get("id", "unknown"))
	_require(int(result.get("auto_process_violations", -1)) == 0, "%s left PlayerController or ActorView on the uncapped SceneTree clock" % result.get("id", "unknown"))
	if not smoke_mode:
		_apply_formal_scenario_gates(result)
	return result


func _prepare_scenario(definition: Dictionary) -> void:
	room_runtime_view.call("clear_runtime")
	await process_frame
	await process_frame
	if context.run_event_log != null:
		context.run_event_log.reset()
	if context.transaction_log != null:
		context.transaction_log.reset()
	context.max_hp = PLAYER_DURABLE_HP
	context.hp = PLAYER_DURABLE_HP
	var simulation := CombatSimulationScript.new()
	simulation.start({
		"seed": int(definition.get("seed", 1)),
		"player_pos": Vector2(0.50, 0.50),
		"player_facing": Vector2.RIGHT,
		"player_hp": PLAYER_DURABLE_HP,
		"player_max_hp": PLAYER_DURABLE_HP,
		"player_power": 10,
		"monster_types": definition.get("monster_types", []),
	})
	in_run_runtime.simulation = simulation
	in_run_runtime.current_room_key = context.cell_key(context.get_current_pos())
	in_run_runtime.paused = false
	in_run_runtime.flee_authorized = false
	in_run_runtime.recent_domain_events.clear()
	room_runtime_view.call("configure_room", context.get_status_snapshot())
	if bool(definition.get("projectile_peak", false)):
		_refill_projectile_peak(simulation)
	var snapshot: Dictionary = in_run_runtime.build_read_only_snapshot()
	room_runtime_view.call("apply_combat_snapshot", snapshot)
	player_controller.call("set_local_position", in_run_runtime.get_player_local_position(Vector2(0.50, 0.50)))
	player_controller.set_process(false)
	_disable_actor_auto_process()
	await process_frame
	_require(not player_controller.is_processing() and _count_processing_actor_views() == 0, "%s scenario setup retained automatic visual processing" % definition.get("id", "unknown"))


func _drive_frame(simulation: Variant, frame_index: int, record: bool, measurements: Dictionary, maintain_projectile_peak: bool, visual_contract: Dictionary) -> int:
	visual_contract["auto_process_violations"] = int(visual_contract.get("auto_process_violations", 0)) + int(player_controller.is_processing()) + _count_processing_actor_views()
	var move_input := _input_for_frame(frame_index)
	var aim_input := move_input if move_input.length_squared() > 0.0001 else Vector2.RIGHT
	simulation.set_player_input(move_input, aim_input)
	var frame_started := Time.get_ticks_usec()
	var simulation_started := frame_started
	var fixed_steps: int = simulation.advance_frame(FIXED_DELTA)
	var simulation_usec := Time.get_ticks_usec() - simulation_started
	var fixture_started := Time.get_ticks_usec()
	if maintain_projectile_peak:
		_refill_projectile_peak(simulation)
	var fixture_usec := Time.get_ticks_usec() - fixture_started
	var domain_started := Time.get_ticks_usec()
	var events: Array[Dictionary] = simulation.drain_events()
	in_run_runtime.call("_consume_domain_events", events)
	var domain_usec := Time.get_ticks_usec() - domain_started
	var snapshot_started := Time.get_ticks_usec()
	var snapshot: Dictionary = in_run_runtime.build_read_only_snapshot()
	var snapshot_usec := Time.get_ticks_usec() - snapshot_started
	var presentation_started := Time.get_ticks_usec()
	var combat_player: Dictionary = snapshot.get("player", {})
	player_controller.call("set_local_position", in_run_runtime.get_player_local_position(Vector2(0.50, 0.50)))
	player_controller.call("set_facing_vector", Vector2(combat_player.get("facing", aim_input)))
	player_controller.call("set_runtime_visual_state", StringName(combat_player.get("state", &"idle")))
	room_runtime_view.call("advance", FIXED_DELTA, in_run_runtime.get_player_local_position(Vector2(0.50, 0.50)), snapshot)
	player_controller.set_process(false)
	player_controller.call("_process", FIXED_DELTA)
	visual_contract["player_steps"] = int(visual_contract.get("player_steps", 0)) + 1
	var actor_tick: Dictionary = _advance_actor_views_fixed()
	visual_contract["actor_steps"] = int(visual_contract.get("actor_steps", 0)) + int(actor_tick.get("actual", 0))
	visual_contract["actor_expected_steps"] = int(visual_contract.get("actor_expected_steps", 0)) + int(actor_tick.get("expected", 0))
	visual_contract["auto_process_violations"] = int(visual_contract.get("auto_process_violations", 0)) + int(actor_tick.get("auto_process_violations", 0))
	var presentation_usec := Time.get_ticks_usec() - presentation_started
	var frame_work_usec := Time.get_ticks_usec() - frame_started - fixture_usec
	var before_process_frame := Time.get_ticks_usec()
	visual_contract["auto_process_violations"] = int(visual_contract.get("auto_process_violations", 0)) + int(player_controller.is_processing()) + _count_processing_actor_views()
	await process_frame
	var process_frame_interval_usec := Time.get_ticks_usec() - before_process_frame
	if not record:
		return fixture_usec
	(measurements.get("frame_work_usec", []) as Array).append(frame_work_usec)
	(measurements.get("simulation_usec", []) as Array).append(simulation_usec)
	(measurements.get("domain_event_usec", []) as Array).append(domain_usec)
	(measurements.get("snapshot_usec", []) as Array).append(snapshot_usec)
	(measurements.get("presentation_usec", []) as Array).append(presentation_usec)
	(measurements.get("process_frame_interval_usec", []) as Array).append(process_frame_interval_usec)
	(measurements.get("frame_total_usec", []) as Array).append(frame_work_usec + process_frame_interval_usec)
	(measurements.get("engine_process_usec", []) as Array).append(int(round(Performance.get_monitor(Performance.TIME_PROCESS) * 1000000.0)))
	(measurements.get("fixed_steps", []) as Array).append(fixed_steps)
	(measurements.get("enemy_count", []) as Array).append(_alive_enemy_count(snapshot))
	(measurements.get("projectile_count", []) as Array).append((snapshot.get("projectiles", []) as Array).size())
	(measurements.get("laser_count", []) as Array).append((snapshot.get("lasers", []) as Array).size())
	(measurements.get("accumulator_ticks", []) as Array).append(float(simulation.accumulator) / FIXED_DELTA)
	measurements["last_snapshot"] = snapshot
	if int((measurements.get("frame_work_usec", []) as Array).size()) % MEMORY_SAMPLE_INTERVAL == 0:
		(measurements.get("memory_static_bytes", []) as Array).append(int(Performance.get_monitor(Performance.MEMORY_STATIC)))
		(measurements.get("memory_static_max_bytes", []) as Array).append(int(Performance.get_monitor(Performance.MEMORY_STATIC_MAX)))
		(measurements.get("node_count", []) as Array).append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		(measurements.get("resource_count", []) as Array).append(int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)))
		(measurements.get("orphan_node_count", []) as Array).append(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
		(measurements.get("os_static_memory_bytes", []) as Array).append(int(OS.get_static_memory_usage()))
		(measurements.get("os_static_memory_peak_bytes", []) as Array).append(int(OS.get_static_memory_peak_usage()))
		var cache_metrics: Dictionary = RuntimeTextureCacheScript.metrics()
		(measurements.get("cache_load_count", []) as Array).append(int(cache_metrics.get("loads", 0)))
		(measurements.get("cache_failure_count", []) as Array).append(int(cache_metrics.get("failures", 0)))
	return fixture_usec


func _advance_actor_views_fixed() -> Dictionary:
	var expected := 0
	var actual := 0
	var auto_process_violations := 0
	for actor in _actor_view_nodes():
		actor.set_process(false)
		if actor.is_processing():
			auto_process_violations += 1
		if actor.is_queued_for_deletion():
			continue
		expected += 1
		actor.call("_process", FIXED_DELTA)
		actual += 1
	return {
		"expected": expected,
		"actual": actual,
		"auto_process_violations": auto_process_violations,
	}


func _disable_actor_auto_process() -> void:
	for actor in _actor_view_nodes():
		actor.set_process(false)


func _count_processing_actor_views() -> int:
	var count := 0
	for actor in _actor_view_nodes():
		if actor.is_processing():
			count += 1
	return count


func _actor_view_nodes() -> Array[Node]:
	var result: Array[Node] = []
	if room_runtime_view == null or not is_instance_valid(room_runtime_view):
		return result
	for layer_path in ["CombatVisuals/Enemies", "CombatVisuals/Projectiles"]:
		var layer := room_runtime_view.get_node_or_null(layer_path) as Node
		if layer == null:
			continue
		for child in layer.get_children():
			var actor := child as Node
			if actor != null and actor.get_script() == RuntimeActorViewScript:
				result.append(actor)
	return result


func _refill_projectile_peak(simulation: Variant) -> void:
	var refill_index := 0
	while simulation.projectiles.size() < PROJECTILE_PEAK_COUNT:
		var slot: int = int(simulation.projectiles.size())
		var row: int = slot % 5
		var from_top: bool = slot % 2 == 0
		var origin := Vector2(0.16 + float(row) * 0.15, 0.18 if from_top else 0.82)
		var direction := Vector2(0.60 if slot % 3 == 0 else -0.60, 1.0 if from_top else -1.0).normalized()
		simulation.call("_spawn_projectile", "i2_peak_fixture", origin, direction, 1)
		refill_index += 1
		if refill_index > PROJECTILE_PEAK_COUNT:
			break


func _input_for_frame(frame_index: int) -> Vector2:
	match (frame_index / 120) % 4:
		0:
			return Vector2.RIGHT
		1:
			return Vector2.DOWN
		2:
			return Vector2.LEFT
		_:
			return Vector2.UP


func _new_measurements() -> Dictionary:
	return {
		"frame_work_usec": [],
		"simulation_usec": [],
		"domain_event_usec": [],
		"snapshot_usec": [],
		"presentation_usec": [],
		"process_frame_interval_usec": [],
		"frame_total_usec": [],
		"engine_process_usec": [],
		"fixed_steps": [],
		"enemy_count": [],
		"projectile_count": [],
		"laser_count": [],
		"accumulator_ticks": [],
		"memory_static_bytes": [],
		"memory_static_max_bytes": [],
		"os_static_memory_bytes": [],
		"os_static_memory_peak_bytes": [],
		"node_count": [],
		"resource_count": [],
		"orphan_node_count": [],
		"cache_load_count": [],
		"cache_failure_count": [],
		"last_snapshot": {},
	}


func _summarize_scenario(
	scenario_id: String,
	measurements: Dictionary,
	cache_before_scenario: Dictionary,
	cache_after_warmup: Dictionary,
	cache_after_sample: Dictionary,
	fixture_usec: int,
	measured_frames: int,
	wall_seconds: float,
	visual_contract: Dictionary
) -> Dictionary:
	var steps: Array = measurements.get("fixed_steps", [])
	var zero_steps := 0
	var catch_up_frames := 0
	var saturated_frames := 0
	var max_steps := 0
	for raw_steps in steps:
		var value := int(raw_steps)
		max_steps = maxi(max_steps, value)
		if value == 0:
			zero_steps += 1
		if value > 1:
			catch_up_frames += 1
		if value >= 12:
			saturated_frames += 1
	return {
		"id": scenario_id,
		"measured_frames": measured_frames,
		"wall_seconds": snappedf(wall_seconds, 0.001),
		"frame_work": _distribution(measurements.get("frame_work_usec", [])),
		"simulation": _distribution(measurements.get("simulation_usec", [])),
		"domain_event": _distribution(measurements.get("domain_event_usec", [])),
		"snapshot": _distribution(measurements.get("snapshot_usec", [])),
		"presentation_sync": _distribution(measurements.get("presentation_usec", [])),
		"process_frame_interval": _distribution(measurements.get("process_frame_interval_usec", [])),
		"frame_total": _distribution(measurements.get("frame_total_usec", [])),
		"engine_process": _distribution(measurements.get("engine_process_usec", [])),
		"enemy_count": _distribution(measurements.get("enemy_count", [])),
		"projectile_count": _distribution(measurements.get("projectile_count", [])),
		"laser_count": _distribution(measurements.get("laser_count", [])),
		"fixed_step_zero_frames": zero_steps,
		"fixed_step_catch_up_frames": catch_up_frames,
		"fixed_step_saturated_frames": saturated_frames,
		"fixed_step_max": max_steps,
		"accumulator_ticks": _float_distribution(measurements.get("accumulator_ticks", [])),
		"fixture_usec": fixture_usec,
		"player_visual_steps": int(visual_contract.get("player_steps", 0)),
		"actor_visual_steps": int(visual_contract.get("actor_steps", 0)),
		"actor_visual_expected_steps": int(visual_contract.get("actor_expected_steps", 0)),
		"auto_process_violations": int(visual_contract.get("auto_process_violations", 0)),
		"cache_warmup_loads": int(cache_after_warmup.get("loads", 0)) - int(cache_before_scenario.get("loads", 0)),
		"cache_loads_after_warmup": int(cache_after_sample.get("loads", 0)) - int(cache_after_warmup.get("loads", 0)),
		"cache_loads_delta": int(cache_after_sample.get("loads", 0)) - int(cache_before_scenario.get("loads", 0)),
		"cache_requests_after_warmup": int(cache_after_sample.get("requests", 0)) - int(cache_after_warmup.get("requests", 0)),
		"cache_hits_after_warmup": int(cache_after_sample.get("cache_hits", 0)) - int(cache_after_warmup.get("cache_hits", 0)),
		"cache_failures": int(cache_after_sample.get("failures", 0)),
		"cache_failures_delta": int(cache_after_sample.get("failures", 0)) - int(cache_before_scenario.get("failures", 0)),
		"cache_entries_delta": int(cache_after_sample.get("entries", 0)) - int(cache_before_scenario.get("entries", 0)),
		"memory_static": _series_summary(measurements.get("memory_static_bytes", [])),
		"memory_static_max": _series_summary(measurements.get("memory_static_max_bytes", [])),
		"os_static_memory": _series_summary(measurements.get("os_static_memory_bytes", [])),
		"os_static_memory_peak": _series_summary(measurements.get("os_static_memory_peak_bytes", [])),
		"node_count": _series_summary(measurements.get("node_count", [])),
		"resource_count": _series_summary(measurements.get("resource_count", [])),
		"orphan_node_count": _series_summary(measurements.get("orphan_node_count", [])),
		"cache_load_count": _series_summary(measurements.get("cache_load_count", [])),
		"cache_failure_count": _series_summary(measurements.get("cache_failure_count", [])),
	}


func _distribution(raw_samples: Variant) -> Dictionary:
	var samples: Array = raw_samples if raw_samples is Array else []
	if samples.is_empty():
		return {"min": -1, "p50": -1, "p95": -1, "p99": -1, "max": -1, "count": 0}
	var sorted := samples.duplicate()
	sorted.sort()
	return {
		"min": sorted[0],
		"p50": int(sorted[_percentile_index(sorted.size(), 0.50)]),
		"p95": int(sorted[_percentile_index(sorted.size(), 0.95)]),
		"p99": int(sorted[_percentile_index(sorted.size(), 0.99)]),
		"max": int(sorted[sorted.size() - 1]),
		"count": sorted.size(),
	}


func _float_distribution(raw_samples: Variant) -> Dictionary:
	var samples: Array = raw_samples if raw_samples is Array else []
	if samples.is_empty():
		return {"min": -1.0, "p50": -1.0, "p95": -1.0, "p99": -1.0, "max": -1.0, "count": 0}
	var sorted := samples.duplicate()
	sorted.sort()
	return {
		"min": snappedf(float(sorted[0]), 0.0001),
		"p50": snappedf(float(sorted[_percentile_index(sorted.size(), 0.50)]), 0.0001),
		"p95": snappedf(float(sorted[_percentile_index(sorted.size(), 0.95)]), 0.0001),
		"p99": snappedf(float(sorted[_percentile_index(sorted.size(), 0.99)]), 0.0001),
		"max": snappedf(float(sorted[sorted.size() - 1]), 0.0001),
		"count": sorted.size(),
	}


func _series_summary(raw_samples: Variant) -> Dictionary:
	var samples: Array = raw_samples if raw_samples is Array else []
	if samples.is_empty():
		return {"first": -1, "last": -1, "delta": 0, "max": -1, "first_10_median": -1, "last_10_median": -1, "window_delta": 0, "last_10_delta": 0, "count": 0}
	var maximum := int(samples[0])
	for raw_value in samples:
		maximum = maxi(maximum, int(raw_value))
	var window_size := mini(10, maxi(1, samples.size() / 2))
	var first_window := samples.slice(0, window_size)
	var last_window := samples.slice(samples.size() - window_size, samples.size())
	var first_median := _median(first_window)
	var last_median := _median(last_window)
	return {
		"first": int(samples[0]),
		"last": int(samples[samples.size() - 1]),
		"delta": int(samples[samples.size() - 1]) - int(samples[0]),
		"max": maximum,
		"first_10_median": first_median,
		"last_10_median": last_median,
		"window_delta": last_median - first_median,
		"last_10_delta": int(samples[samples.size() - 1]) - int(samples[maxi(0, samples.size() - 10)]),
		"count": samples.size(),
	}


func _median(raw_samples: Array) -> int:
	if raw_samples.is_empty():
		return -1
	var sorted := raw_samples.duplicate()
	sorted.sort()
	return int(sorted[sorted.size() / 2])


func _percentile_index(size: int, percentile: float) -> int:
	return clampi(int(ceil(float(size - 1) * percentile)), 0, size - 1)


func _alive_enemy_count(snapshot: Dictionary) -> int:
	var count := 0
	for raw_enemy in (snapshot.get("enemies", []) as Array):
		if raw_enemy is Dictionary and int((raw_enemy as Dictionary).get("hp", 0)) > 0:
			count += 1
	return count


func _require(condition: bool, message: String) -> void:
	if not condition and failures.size() < 64:
		failures.append(message)


func _apply_formal_scenario_gates(result: Dictionary) -> void:
	var scenario_id := String(result.get("id", "unknown"))
	var memory: Dictionary = result.get("memory_static", {})
	var os_memory: Dictionary = result.get("os_static_memory", {})
	var nodes: Dictionary = result.get("node_count", {})
	var resources: Dictionary = result.get("resource_count", {})
	var orphans: Dictionary = result.get("orphan_node_count", {})
	var cache_loads: Dictionary = result.get("cache_load_count", {})
	var cache_failures: Dictionary = result.get("cache_failure_count", {})
	_require(int(memory.get("window_delta", 0)) <= 2 * 1024 * 1024, "%s Performance static memory grew by more than 2 MiB between the first and last ten seconds" % scenario_id)
	_require(int(os_memory.get("window_delta", 0)) <= 2 * 1024 * 1024, "%s OS static memory grew by more than 2 MiB between the first and last ten seconds" % scenario_id)
	_require(absi(int(nodes.get("window_delta", 0))) <= 64, "%s node-count median drift exceeded the 64-node transient-actor tolerance" % scenario_id)
	_require(int(resources.get("window_delta", 0)) <= 8, "%s resource-count median drift exceeded eight resources" % scenario_id)
	_require(int(orphans.get("max", 0)) == 0, "%s produced orphan nodes" % scenario_id)
	_require(int(cache_loads.get("last_10_delta", 0)) == 0, "%s texture cache did not reach a load plateau during the last ten seconds" % scenario_id)
	_require(int(cache_failures.get("max", 0)) == 0, "%s texture cache failure counter became non-zero" % scenario_id)


func _lifecycle_metrics() -> Dictionary:
	return {
		"memory_static_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"memory_static_max_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC_MAX)),
		"os_static_memory_bytes": int(OS.get_static_memory_usage()),
		"os_static_memory_peak_bytes": int(OS.get_static_memory_peak_usage()),
		"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"resource_count": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"orphan_node_count": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
	}


func _apply_teardown_gates() -> void:
	_require(int(lifecycle_after.get("node_count", 0)) <= int(lifecycle_before.get("node_count", 0)) + 4, "production teardown exceeded the four-node scheduling tolerance")
	_require(
		int(lifecycle_runtime_loaded.get("resource_count", 0)) - int(lifecycle_after.get("resource_count", 0)) >= MIN_TEARDOWN_RESOURCE_RELEASE,
		"production teardown did not release at least %d runtime resources" % MIN_TEARDOWN_RESOURCE_RELEASE
	)
	_require(int(lifecycle_after.get("orphan_node_count", 0)) <= int(lifecycle_before.get("orphan_node_count", 0)), "production teardown retained orphan nodes")
	_require(not lifecycle_repeat_after.is_empty(), "repeat production lifecycle probe did not complete")
	_require(int(lifecycle_repeat_after.get("node_count", 0)) <= int(lifecycle_after.get("node_count", 0)) + 4, "repeat production teardown grew the stable node platform")
	_require(int(lifecycle_repeat_after.get("resource_count", 0)) <= int(lifecycle_after.get("resource_count", 0)) + 8, "repeat production teardown grew the stable resource-cache platform")
	_require(int(lifecycle_repeat_after.get("orphan_node_count", 0)) <= int(lifecycle_after.get("orphan_node_count", 0)), "repeat production teardown retained new orphan nodes")
	_require(bool(repeat_prewarm_report.get("ok", false)), "repeat production lifecycle could not satisfy combat texture prewarm")
	_require(bool(repeat_authority_preflight_report.get("ok", false)), "repeat production lifecycle could not satisfy pre-authority asset admission")


func _run_repeat_lifecycle_probe() -> void:
	var first_prewarm_report := prewarm_report.duplicate(true)
	var first_authority_preflight_report := authority_preflight_report.duplicate(true)
	if not await _build_production_runtime():
		prewarm_report = first_prewarm_report
		authority_preflight_report = first_authority_preflight_report
		return
	lifecycle_repeat_loaded = _lifecycle_metrics()
	repeat_prewarm_report = prewarm_report.duplicate(true)
	repeat_authority_preflight_report = authority_preflight_report.duplicate(true)
	await _release_production_runtime()
	lifecycle_repeat_after = _lifecycle_metrics()
	prewarm_report = first_prewarm_report
	authority_preflight_report = first_authority_preflight_report


func _release_production_runtime() -> void:
	if room_runtime_view != null and is_instance_valid(room_runtime_view):
		room_runtime_view.call("clear_runtime")
	if in_run_runtime != null:
		in_run_runtime.call("bind", null)
	if command_bus != null:
		command_bus.call("bind_runtime_controller", null)
	if main != null and is_instance_valid(main):
		main.queue_free()
	for _unused in range(4):
		await process_frame
	RuntimeTextureCacheScript.clear_for_tests()
	await process_frame


func _finish(results: Array[Dictionary]) -> void:
	var details := {
		"workload_schema": WORKLOAD_SCHEMA,
		"mode": "visible" if visible_mode else ("headless_smoke" if smoke_mode else "headless_formal"),
		"display_driver": DisplayServer.get_name(),
		"warmup_frames": warmup_frames,
		"sample_frames_minimum": sample_frames,
		"fixed_hz": 60,
		"fixture_injected": true,
		"production_encounter_bootstrap_covered": false,
		"fixture_boundary": "roster_and_projectile_maintenance",
		"visual_clock": "manual_fixed_60hz",
		"scenario_isolation": "same_process_fresh_simulation_view_and_logs",
		"projectile_peak_count": PROJECTILE_PEAK_COUNT,
		"combat_texture_prewarm": prewarm_report,
		"run_start_asset_admission": authority_preflight_report,
		"engine_schedule": {
			"max_fps": 60 if visible_mode else 0,
			"vsync": "enabled" if visible_mode else "headless_not_applicable",
		},
		"lifecycle": {
			"before": lifecycle_before,
			"runtime_loaded": lifecycle_runtime_loaded,
			"after": lifecycle_after,
			"repeat_runtime_loaded": lifecycle_repeat_loaded,
			"repeat_after": lifecycle_repeat_after,
		},
		"repeat_combat_texture_prewarm": repeat_prewarm_report,
		"repeat_run_start_asset_admission": repeat_authority_preflight_report,
		"results": results,
	}
	print("I2_COMBAT_FRAME_DETAILS %s" % JSON.stringify(details))
	if not failures.is_empty():
		for failure in failures:
			print("I2_COMBAT_FRAME_FAILURE %s" % failure)
		print(FAIL_MARKER)
		quit(1)
		return
	if visible_mode:
		print("%s workload_schema=%s" % [VISIBLE_MARKER, WORKLOAD_SCHEMA])
		quit(0)
		return
	print(SMOKE_PASS_MARKER if smoke_mode else PASS_MARKER)
	quit(0)
