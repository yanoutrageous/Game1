extends SceneTree

const PlayerControllerScript := preload("res://scripts/gameplay/player/player_controller.gd")
const RuntimeAnimationCatalog := preload("res://scripts/presentation/art24/art24_runtime_animation_catalog.gd")
const REDUCE_MOTION_SETTING := "accessibility/reduce_motion"
const SAMPLE_RATES: Array[int] = [30, 60, 144]
const EXPECTED_MOVE_PHASES: Array[StringName] = [&"walk_a", &"idle_a", &"walk_b", &"idle_b"]

var failures: Array[String] = []
var had_reduce_motion_setting := false
var previous_reduce_motion_value: Variant = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	had_reduce_motion_setting = ProjectSettings.has_setting(REDUCE_MOTION_SETTING)
	previous_reduce_motion_value = ProjectSettings.get_setting(REDUCE_MOTION_SETTING, false)
	ProjectSettings.set_setting(REDUCE_MOTION_SETTING, false)
	_check_four_phase_walk_catalog()
	_check_frame_rate_projection()
	_check_reduced_motion_pose()
	_check_presentation_does_not_change_displacement()
	_check_collision_and_door_contract()
	_restore_reduce_motion_setting()
	_finish()


func _check_four_phase_walk_catalog() -> void:
	_check(RuntimeAnimationCatalog.player_frame_count(&"move") == 4, "move cycle does not expose four phases")
	var move_frame_seconds := RuntimeAnimationCatalog.player_frame_duration(&"move")
	_check(is_zero_approx(RuntimeAnimationCatalog.player_walk_bob_offset(0.0, false)), "walk_a contact pose is not grounded")
	_check(is_equal_approx(RuntimeAnimationCatalog.player_walk_bob_offset(move_frame_seconds, false), -RuntimeAnimationCatalog.PLAYER_MOVE_BOB_AMPLITUDE), "idle_a passing pose lost its fixed lift amplitude")
	_check(is_zero_approx(RuntimeAnimationCatalog.player_walk_bob_offset(move_frame_seconds * 2.0, false)), "walk_b contact pose is not grounded")
	_check(is_equal_approx(RuntimeAnimationCatalog.player_walk_bob_offset(move_frame_seconds * 3.0, false), -RuntimeAnimationCatalog.PLAYER_MOVE_BOB_AMPLITUDE), "idle_b passing pose lost its fixed lift amplitude")
	for frame_index in range(EXPECTED_MOVE_PHASES.size()):
		var motion: StringName = RuntimeAnimationCatalog.player_motion(&"move", frame_index, false)
		_check(motion == EXPECTED_MOVE_PHASES[frame_index], "move phase %d mapped to %s" % [frame_index, String(motion)])
		for facing: StringName in RuntimeAnimationCatalog.PLAYER_FACINGS:
			var path := RuntimeAnimationCatalog.player_texture_path(facing, &"move", frame_index, false)
			_check(ResourceLoader.exists(path, "Texture2D"), "missing registered movement pose %s" % path)


func _check_frame_rate_projection() -> void:
	for sample_rate in SAMPLE_RATES:
		var player = _new_player()
		player.set_runtime_visual_state(&"move")
		var seen_phases: Dictionary = {}
		var delta := 1.0 / float(sample_rate)
		for _sample in range(sample_rate):
			player.call("_process", delta)
			var frame_index: int = player.animation_frame
			seen_phases[frame_index] = true
			_check(frame_index >= 0 and frame_index < EXPECTED_MOVE_PHASES.size(), "%d Hz produced invalid phase %d" % [sample_rate, frame_index])
			var expected_motion: StringName = RuntimeAnimationCatalog.player_motion(&"move", frame_index, false)
			_check(player.last_texture_path.ends_with("_%s.png" % String(expected_motion)), "%d Hz texture escaped phase %d" % [sample_rate, frame_index])
			var expected_y := -20.0 + RuntimeAnimationCatalog.player_walk_bob_offset(player.animation_elapsed, false)
			var sprite := player.get_node("Sprite") as Sprite2D
			_check(is_equal_approx(sprite.position.y, expected_y), "%d Hz bob lost animation phase" % sample_rate)
		_check(seen_phases.size() == EXPECTED_MOVE_PHASES.size(), "%d Hz did not sample all four movement phases" % sample_rate)
		player.free()


func _check_reduced_motion_pose() -> void:
	ProjectSettings.set_setting(REDUCE_MOTION_SETTING, true)
	var player = _new_player()
	player.set_runtime_visual_state(&"move")
	for sample_rate in SAMPLE_RATES:
		player.call("_process", 1.0 / float(sample_rate))
		var sprite := player.get_node("Sprite") as Sprite2D
		_check(player.animation_frame == 0, "%d Hz reduced motion advanced movement pose" % sample_rate)
		_check(is_zero_approx(player.animation_elapsed), "%d Hz reduced motion advanced animation clock" % sample_rate)
		_check(player.last_texture_path.ends_with("_walk_a.png"), "%d Hz reduced motion did not retain readable contact pose" % sample_rate)
		_check(is_equal_approx(sprite.position.y, -20.0), "%d Hz reduced motion retained bob" % sample_rate)
	player.free()
	ProjectSettings.set_setting(REDUCE_MOTION_SETTING, false)


func _check_presentation_does_not_change_displacement() -> void:
	_check(is_equal_approx(PlayerControllerScript.LOCAL_MOVE_SPEED, 0.74), "logical move speed changed")
	_check(is_equal_approx(PlayerControllerScript.LOCAL_ACCELERATION, 8.0), "logical acceleration changed")
	_check(is_equal_approx(PlayerControllerScript.LOCAL_DECELERATION, 12.0), "logical deceleration changed")
	var held_endpoints: Dictionary = {}
	for sample_rate in SAMPLE_RATES:
		var logic_only = _new_player()
		var with_projection = _new_player()
		var delta := 1.0 / float(sample_rate)
		for _sample in range(sample_rate / 2):
			logic_only.move_local(Vector2.RIGHT, delta)
			with_projection.move_local(Vector2.RIGHT, delta)
			with_projection.call("_process", delta)
		_check(logic_only.get_local_position().is_equal_approx(with_projection.get_local_position()), "%d Hz presentation changed logical displacement" % sample_rate)
		_check(logic_only.local_velocity.is_equal_approx(with_projection.local_velocity), "%d Hz presentation changed logical velocity" % sample_rate)
		held_endpoints[sample_rate] = logic_only.get_local_position()
		logic_only.free()
		with_projection.free()
	var reference_endpoint: Vector2 = held_endpoints.get(SAMPLE_RATES[0], Vector2.ZERO)
	for sample_rate in SAMPLE_RATES:
		var endpoint: Vector2 = held_endpoints.get(sample_rate, Vector2.ZERO)
		_check(
			endpoint.distance_to(reference_endpoint) <= 0.00001,
			"%d Hz held-input travel drifted from the 30 Hz reference by %.7f" % [
				sample_rate,
				endpoint.distance_to(reference_endpoint),
			]
		)


func _check_collision_and_door_contract() -> void:
	_check(is_equal_approx(PlayerControllerScript.PLAYER_RADIUS, 0.055), "logical player radius changed")
	_check(is_equal_approx(PlayerControllerScript.DOOR_ALIGN_HALF, 0.16), "door alignment threshold changed")
	for sample_rate in SAMPLE_RATES:
		var logic_only = _new_player()
		var with_projection = _new_player()
		var obstacle := Rect2(0.48, 0.40, 0.10, 0.20)
		logic_only.set_logical_obstacles([obstacle])
		with_projection.set_logical_obstacles([obstacle])
		var delta := 1.0 / float(sample_rate)
		for _sample in range(sample_rate):
			logic_only.move_local(Vector2.RIGHT, delta)
			with_projection.move_local(Vector2.RIGHT, delta)
			with_projection.call("_process", delta)
		_check(logic_only.get_local_position().is_equal_approx(with_projection.get_local_position()), "%d Hz presentation changed collision stop" % sample_rate)
		_check(logic_only.get_local_position().x < obstacle.position.x - PlayerControllerScript.PLAYER_RADIUS, "%d Hz collision crossed the protected body" % sample_rate)
		logic_only.set_local_position(Vector2(PlayerControllerScript.PLAYER_RADIUS + 0.01, 0.5))
		with_projection.set_local_position(Vector2(PlayerControllerScript.PLAYER_RADIUS + 0.01, 0.5))
		_check(logic_only.requested_transition(Vector2.LEFT) == Vector2i.LEFT, "%d Hz aligned door threshold changed" % sample_rate)
		_check(with_projection.requested_transition(Vector2.LEFT) == Vector2i.LEFT, "%d Hz projected aligned door threshold changed" % sample_rate)
		logic_only.set_local_position(Vector2(PlayerControllerScript.PLAYER_RADIUS + 0.01, 0.5 + PlayerControllerScript.DOOR_ALIGN_HALF + 0.001))
		with_projection.set_local_position(Vector2(PlayerControllerScript.PLAYER_RADIUS + 0.01, 0.5 + PlayerControllerScript.DOOR_ALIGN_HALF + 0.001))
		_check(logic_only.requested_transition(Vector2.LEFT) == Vector2i.ZERO, "%d Hz misaligned door threshold changed" % sample_rate)
		_check(with_projection.requested_transition(Vector2.LEFT) == Vector2i.ZERO, "%d Hz projected misaligned door threshold changed" % sample_rate)
		logic_only.free()
		with_projection.free()


func _new_player():
	var player = PlayerControllerScript.new()
	root.add_child(player)
	player.set_process(false)
	player.set_local_position(Vector2(0.30, 0.50))
	return player


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _restore_reduce_motion_setting() -> void:
	ProjectSettings.set_setting(
		REDUCE_MOTION_SETTING,
		previous_reduce_motion_value if had_reduce_motion_setting else null
	)


func _finish() -> void:
	if failures.is_empty():
		print("I2_PLAYER_MOTION_PROJECTION=PASS phases=4 sample_hz=30,60,144 held_travel=stable reduced_motion=fixed_pose_zero_bob authority=presentation_only displacement=unchanged")
		quit(0)
		return
	for failure in failures:
		push_error("I2 player motion projection failure: " + failure)
	print("I2_PLAYER_MOTION_PROJECTION=FAIL failures=%d" % failures.size())
	quit(1)
