extends SceneTree

const CombatSimulationScript := preload("res://scripts/gameplay/combat/g41_combat_simulation.gd")
const MonsterCatalogScript := preload("res://scripts/gameplay/combat/g41_monster_catalog.gd")
const RuntimeLayoutScript := preload("res://scripts/gameplay/runtime/g41_runtime_layout.gd")

const PASS_MARKER := "I3R_PRODUCTION_COMBAT_OBSTACLE_JOURNEY=PASS"
const FAIL_MARKER := "I3R_PRODUCTION_COMBAT_OBSTACLE_JOURNEY=FAIL"
const FIXED_SEED := 13
const FRAME_STEP := 0.02

var failures: Array[String] = []
var main: Node
var run_scene: Node
var parsed_input_count := 0
var quit_scheduled := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production main.tscn could not be loaded")
	if packed == null:
		_finish()
		return
	main = packed.instantiate()
	root.add_child(main)
	await _frames(12)
	run_scene = main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing")
	if run_scene == null:
		_finish()
		return

	await _tap_key(KEY_ENTER)
	_require(await _wait_screen(&"deploy_shell", 6.0), "real Enter input did not reach the production deploy page")
	var deploy_page := _deploy_page()
	_require(deploy_page != null, "production deploy page is missing")
	if deploy_page == null:
		_finish()
		return
	_set_only_fixed_seed(deploy_page)
	var start_button := deploy_page.find_child("DeployPrimaryAction", true, false) as Button
	_require(start_button != null and start_button.visible and not start_button.disabled, "deploy primary action is not reachable")
	if start_button == null:
		_finish()
		return
	await _click_control(start_button)
	_require(await _wait_screen(&"run", 6.0), "real pointer input did not start the production run")
	await _frames(8)
	_require(int(run_scene.get("run_context").get("seed_value")) == FIXED_SEED, "fixed seed did not reach the authoritative run")
	_require(await _transition_room(Vector2i.RIGHT, Vector2i(3, 6), &"Chest"), "real movement did not enter the chest room")
	_require(await _transition_room(Vector2i.UP, Vector2i(3, 5), &"Event"), "real movement did not enter the event room")
	_require(await _transition_room(Vector2i.UP, Vector2i(3, 4), &"Normal"), "real movement did not enter the normal room")
	_require(await _transition_room(Vector2i.LEFT, Vector2i(2, 4), &"Monster"), "real movement did not enter the production monster room")
	_require(await _wait_until(func() -> bool: return _combat_active(), 3.0), "monster-room entry did not start production combat")
	if not _combat_active():
		_finish()
		return

	var runtime = run_scene.get("in_run_runtime")
	var simulation = runtime.get("simulation") if runtime != null else null
	_require(simulation != null, "production in-run runtime exposed no combat simulation")
	if simulation == null:
		_finish()
		return
	var arena: Array = simulation.get("arena_obstacles")
	_require(arena == CombatSimulationScript.production_arena_obstacles(), "production combat did not receive the shared visible-obstacle contract")
	var view = run_scene.get("room_runtime_view")
	var view_snapshot: Dictionary = view.call("build_read_only_snapshot") if view != null else {}
	var production_player = run_scene.get("player_controller")
	var combat_entry_pos := _player_local_pos()
	var east_entry_door := _door_for_direction(
		view_snapshot.get("doors", []),
		Vector2i.RIGHT
	)
	_require(
		production_player != null
		and not east_entry_door.is_empty()
		and _player_is_visually_clear_of_door(
			production_player,
			combat_entry_pos,
			east_entry_door
		),
		"real combat transition left the player silhouette inside the east entry doorway"
	)
	_require(
		Vector2(simulation.player.get("pos", Vector2.INF)).distance_to(combat_entry_pos) <= 0.003,
		"combat simulation restored the old-room exit after production entry placement"
	)
	_require(
		StringName((run_scene.get("last_command_result") as Dictionary).get("reason", &""))
		!= &"combat_door_locked",
		"held entry input immediately retriggered the opposite combat-locked door"
	)
	_require(
		(view_snapshot.get("logical_obstacles", []) as Array).has(CombatSimulationScript.production_arena_obstacles()[0]),
		"production monster-room view did not expose the combat altar as a movement obstacle"
	)

	# Real D input must stop at the same visible altar that will later occlude
	# attacks. Enemy state is frozen only to keep this input measurement stable.
	_arrange_single_enemy(simulation, &"bat", Vector2(0.84, 0.82), &"hurt", 50)
	_place_player(simulation, Vector2(0.20, 0.50), Vector2.RIGHT)
	await _hold_key_seconds(KEY_D, 0.85)
	var altar: Rect2 = CombatSimulationScript.production_arena_obstacles()[0]
	var blocked_x := _player_local_pos().x
	_require(
		blocked_x <= altar.position.x - CombatSimulationScript.PLAYER_RADIUS + 0.002,
		"real player movement crossed the visible altar"
	)
	_require(blocked_x >= 0.27, "real player movement did not reach the visible altar before the collision assertion")

	# Holding into a combat-locked door must produce one rejection and then wait
	# for release. The run event count is the production dispatch boundary.
	_arrange_single_enemy(simulation, &"bat", Vector2(0.20, 0.20), &"hurt", 50)
	_place_player(simulation, Vector2(CombatSimulationScript.ROOM_MAX, 0.50), Vector2.RIGHT)
	var feedback_service = run_scene.get("player_feedback_service")
	var feedback_before := (feedback_service.call("history") as Array).size() if feedback_service != null else 0
	var dispatch_before := int(_status().get("event_count", 0))
	_parse_key(KEY_D, true)
	await _seconds(0.65)
	var feedback_during_hold := (feedback_service.call("history") as Array).size() if feedback_service != null else 0
	var dispatch_during_hold := int(_status().get("event_count", 0))
	_require(absf(_player_local_pos().x - CombatSimulationScript.ROOM_MAX) <= 0.002, "held combat-door direction changed the blocked player position")
	_require(feedback_during_hold - feedback_before == 1, "held combat-door direction presented more than one rejection")
	_require(dispatch_during_hold == dispatch_before, "held combat-door direction dispatched a room transition")
	_require(bool(run_scene.get("_transition_rejection_awaiting_release")), "combat-door retry gate did not wait for direction release")
	_parse_key(KEY_D, false)
	await _frames(3)
	_require(not bool(run_scene.get("_transition_rejection_awaiting_release")), "combat-door retry gate did not reopen after direction release")

	# The warning is produced by the real production _process chain and must be
	# visible in the same room view used by the player.
	var event_floor := _latest_combat_event_index(runtime)
	_arrange_single_enemy(simulation, &"slime", Vector2(0.75, 0.50), &"idle", 50)
	_place_player(simulation, Vector2(0.88, 0.50), Vector2.LEFT)
	var warning_event := await _wait_combat_event(runtime, &"melee_warning_started", event_floor, 2.0)
	_require(not warning_event.is_empty(), "production enemy emitted no melee warning")
	view_snapshot = view.call("build_read_only_snapshot") if view != null else {}
	var warning_combat: Dictionary = view_snapshot.get("combat", {})
	_require(
		view != null and bool(view.call("_has_visible_combat_geometry", warning_combat)),
		"production enemy warning was not visible in the room view"
	)

	# Leave a real melee enemy active on the opposite side of the altar. The
	# production process chain, rather than direct test ticks, must first make
	# tangential progress and then regain a clear approach to the player.
	_arrange_single_enemy(simulation, &"slime", Vector2(0.82, 0.50), &"idle", 50)
	_place_player(simulation, Vector2(0.20, 0.50), Vector2.RIGHT)
	var melee_start := Vector2(simulation.enemies[0].get("pos", Vector2.ZERO))
	var made_tangential_progress := await _wait_until(
		func() -> bool:
			var enemy_pos := Vector2(simulation.enemies[0].get("pos", Vector2.ZERO))
			return (
				enemy_pos.distance_to(melee_start) >= 0.12
				and absf(enemy_pos.y - melee_start.y) >= 0.08
			),
		3.0
	)
	_require(made_tangential_progress, "production melee enemy remained frozen against the opposite altar face")
	var completed_melee_route := await _wait_until(
		func() -> bool:
			var enemy: Dictionary = simulation.enemies[0]
			var enemy_pos := Vector2(enemy.get("pos", Vector2.ZERO))
			var player_pos := Vector2(simulation.player.get("pos", Vector2.ZERO))
			var body_radius := float(enemy.get("body_radius", 0.0))
			return (
				enemy_pos.distance_to(player_pos) <= 0.24
				and not bool(simulation.call("_line_occluded", enemy_pos, player_pos, body_radius))
				and not bool(simulation.call("_position_hits_obstacle", enemy_pos, body_radius))
			),
		5.0
	)
	_require(completed_melee_route, "production melee enemy did not route around the altar to a clear approach")

	# During one real Space attack, reverse movement input must not turn the
	# player sprite away from the frozen authoritative attack sector. Windup
	# and active stay fixed; recovery returns movement while retaining the
	# authored facing until the pose ends.
	_arrange_single_enemy(simulation, &"bat", Vector2(0.84, 0.20), &"hurt", 50)
	_place_player(simulation, Vector2(0.20, 0.78), Vector2.RIGHT)
	_parse_key(KEY_SPACE, true)
	_require(
		await _wait_until(
			func() -> bool:
				var player = run_scene.get("player_controller")
				return (
					StringName(simulation.player.get("state", &"")) == &"attack_windup"
					and player != null
					and String(player.get("last_texture_path")).contains("/right_attack_")
				),
			0.8
		),
		"production attack did not enter a visible right-facing windup"
	)
	_parse_key(KEY_SPACE, false)
	_parse_key(KEY_A, true)
	var attack_phases_seen: Dictionary = {}
	var recovery_start_x := INF
	var recovery_moved := false
	var attack_deadline := Time.get_ticks_msec() + 1400
	while Time.get_ticks_msec() <= attack_deadline:
		var combat_state := StringName(simulation.player.get("state", &"idle"))
		if combat_state not in [&"attack_windup", &"attack_active", &"attack_recovery"]:
			break
		attack_phases_seen[combat_state] = true
		if combat_state == &"attack_recovery":
			if is_inf(recovery_start_x):
				recovery_start_x = float((simulation.player.get("pos", Vector2.ZERO) as Vector2).x)
			elif float((simulation.player.get("pos", Vector2.ZERO) as Vector2).x) < recovery_start_x - 0.002:
				recovery_moved = true
		var attack_geometry: Dictionary = simulation.build_snapshot().get("player_attack_geometry", {})
		var player = run_scene.get("player_controller")
		_require(
			Vector2(simulation.player.get("facing", Vector2.ZERO)).is_equal_approx(Vector2.RIGHT),
			"reverse input changed authoritative facing during %s" % combat_state
		)
		_require(
			StringName(attack_geometry.get("phase", &"")) == combat_state
			and Vector2(attack_geometry.get("facing", Vector2.ZERO)).is_equal_approx(Vector2.RIGHT),
			"visible attack geometry detached from authoritative facing during %s" % combat_state
		)
		_require(
			player != null
			and bool(player.get("authoritative_combat_facing_locked"))
			and Vector2(player.call("get_facing_vector")).is_equal_approx(Vector2.RIGHT)
			and StringName(player.get("facing")) == &"right"
			and String(player.get("last_texture_path")).contains("/right_attack_"),
			"player presentation turned away from the frozen attack during %s" % combat_state
		)
		await create_timer(FRAME_STEP).timeout
	_require(
		attack_phases_seen.has(&"attack_windup")
		and attack_phases_seen.has(&"attack_active")
		and attack_phases_seen.has(&"attack_recovery"),
		"production attack journey did not observe every authoritative attack phase"
	)
	_require(recovery_moved, "real reverse input did not move the player during non-damaging attack recovery")
	_require(
		await _wait_until(
			func() -> bool:
				var player = run_scene.get("player_controller")
				return (
					Vector2(simulation.player.get("facing", Vector2.ZERO)).is_equal_approx(Vector2.LEFT)
					and player != null
					and not bool(player.get("authoritative_combat_facing_locked"))
					and Vector2(player.call("get_facing_vector")).is_equal_approx(Vector2.LEFT)
					and StringName(player.get("facing")) == &"left"
				),
			0.8
		),
		"held reverse input did not turn simulation and presentation after attack recovery"
	)
	_parse_key(KEY_A, false)

	# Consume the natural cooldown left by the attack above through real pointer
	# input. An early click must not rotate the actor or open the full-width
	# feedback strip; a late click inside the authored buffer window must start
	# exactly one follow-up attack with the click-time aim.
	var surface = run_scene.get("run_surface")
	if surface != null:
		surface.call("advance_command_feedback", 999.0)
	var facing_before_reject := Vector2(simulation.player.get("facing", Vector2.ZERO))
	var cooldown_before_reject := float(simulation.player.get("attack_cooldown", 0.0))
	_require(
		cooldown_before_reject > CombatSimulationScript.PLAYER_ATTACK_BUFFER_SECONDS,
		"early pointer fixture was already inside the late buffer window: %.3f"
		% cooldown_before_reject
	)
	var event_floor_before_reject := _latest_combat_event_index(runtime)
	var reject_targeted := await _click_playfield_local(Vector2(0.50, 0.50))
	_require(reject_targeted, "early cooldown pointer fixture was outside the production playfield")
	var rejected_result: Dictionary = run_scene.get("last_command_result")
	_require(
		StringName(rejected_result.get("status", &"")) == &"attack_cooling_down"
		and not bool(rejected_result.get("ok", true)),
		"real early pointer attack did not report the cooldown-specific rejection: %s"
		% rejected_result
	)
	_require(
		Vector2(simulation.player.get("facing", Vector2.ZERO)).is_equal_approx(facing_before_reject),
		"rejected pointer attack changed the authoritative player facing"
	)
	var player_after_reject = run_scene.get("player_controller")
	_require(
		player_after_reject != null
		and Vector2(player_after_reject.call("get_facing_vector")).is_equal_approx(facing_before_reject),
		"rejected pointer attack changed the presented player facing"
	)
	_require(
		_latest_event_of_type_after(runtime, &"player_attack_started", event_floor_before_reject).is_empty(),
		"rejected early pointer attack still started a hidden attack"
	)
	var feedback_label = surface.get("command_feedback_label") if surface != null else null
	_require(
		feedback_label == null or not bool(feedback_label.visible),
		"cooldown rejection opened the full-width command feedback strip"
	)
	var combat_button := (
		(surface.get("action_buttons") as Dictionary).get(&"combat") as Button
		if surface != null
		else null
	)
	_require(
		combat_button != null and combat_button.modulate != Color.WHITE,
		"natural cooldown did not dim the existing attack button"
	)
	_require(
		await _wait_until(
			func() -> bool:
				var attack_input: Dictionary = simulation.build_snapshot().get("attack_input", {})
				return bool(attack_input.get("buffer_window_open", false)),
			1.0
		),
		"natural cooldown never exposed its late input-buffer window"
	)
	var event_floor_before_buffer := _latest_combat_event_index(runtime)
	var player_before_buffer := _player_local_pos()
	var buffered_pointer_target := Vector2(0.50, 0.28)
	var expected_buffered_aim := (buffered_pointer_target - player_before_buffer).normalized()
	var buffer_targeted := await _click_playfield_local(buffered_pointer_target)
	_require(buffer_targeted, "late-buffer pointer fixture was outside the production playfield")
	var buffered_result: Dictionary = run_scene.get("last_command_result")
	_require(
		StringName(buffered_result.get("status", &"")) == &"attack_buffered"
		and bool(buffered_result.get("ok", false)),
		"real late pointer attack did not enter the authored buffer: %s"
		% buffered_result
	)
	var buffered_started := await _wait_combat_event(
		runtime,
		&"player_attack_started",
		event_floor_before_buffer,
		1.0
	)
	_require(not buffered_started.is_empty(), "real buffered pointer attack never started")
	_require(
		Vector2(buffered_started.get("facing", Vector2.ZERO)).dot(expected_buffered_aim) >= 0.98,
		"buffered pointer attack lost its click-time aim"
	)
	_require(
		await _wait_until(
			func() -> bool:
				var attack_input: Dictionary = simulation.build_snapshot().get("attack_input", {})
				return (
					bool(attack_input.get("ready", false))
					and StringName(simulation.player.get("state", &"")) in [&"idle", &"move"]
				),
			1.5
		),
		"buffered follow-up attack did not return to a ready state"
	)

	# Arrange a target across the altar corner. The position fixture is bounded
	# to battlefield state; the attack itself travels through the production
	# input router via Input.parse_input_event.
	event_floor = _latest_combat_event_index(runtime)
	_arrange_single_enemy(simulation, &"bat", Vector2(0.42, 0.33), &"hurt", 50)
	_place_player(simulation, Vector2(0.285, 0.42), Vector2(0.135, -0.09))
	var hp_before_blocked := int(simulation.enemies[0].get("hp", 0))
	_parse_key(KEY_SPACE, true)
	await process_frame
	_parse_key(KEY_SPACE, false)
	var clipped_visual_visible := await _wait_until(
		func() -> bool:
			var snapshot: Dictionary = view.call("build_read_only_snapshot") if view != null else {}
			var geometry: Dictionary = (snapshot.get("combat", {}) as Dictionary).get("player_attack_geometry", {})
			return (
				bool(geometry.get("visible", false))
				and bool(geometry.get("occluded", false))
				and int(geometry.get("occluded_sample_count", 0)) > 0
			),
		0.8
	)
	_require(clipped_visual_visible, "production room view never received the altar-clipped attack sector")
	view_snapshot = view.call("build_read_only_snapshot") if view != null else {}
	var production_attack_geometry: Dictionary = (
		(view_snapshot.get("combat", {}) as Dictionary).get("player_attack_geometry", {})
	)
	_require(
		StringName(production_attack_geometry.get("occlusion_contract", &""))
		== CombatSimulationScript.ARENA_CONTRACT_ID,
		"production attack visual did not cite the shared altar obstacle authority"
	)
	var production_samples: Array = production_attack_geometry.get("occlusion_samples", [])
	var production_arc: Array = production_attack_geometry.get("visible_arc_points", [])
	_require(
		not production_samples.is_empty()
		and production_samples.size() == production_arc.size(),
		"production attack visual exposed incomplete clipped geometry"
	)
	if not production_samples.is_empty():
		var center_sample: Dictionary = production_samples[production_samples.size() / 2]
		_require(
			bool(center_sample.get("occluded", false))
			and Vector2(center_sample.get("endpoint", Vector2.ZERO)).distance_to(
				Vector2(production_attack_geometry.get("origin", Vector2.ZERO))
			)
			< Vector2(center_sample.get("full_endpoint", Vector2.ZERO)).distance_to(
				Vector2(production_attack_geometry.get("origin", Vector2.ZERO))
			),
			"production attack visual still covered the altar's blocked center ray"
		)
	var presented_arc: PackedVector2Array = view.call(
		"_player_attack_arc_world_points",
		production_attack_geometry
	) if view != null else PackedVector2Array()
	_require(
		presented_arc.size() == production_arc.size(),
		"production room renderer did not consume the simulation's clipped attack points"
	)
	var blocked_event := await _wait_combat_event(runtime, &"player_attack_resolved", event_floor, 2.0)
	_require(not blocked_event.is_empty(), "real Space input produced no resolved player attack")
	_require(int(simulation.enemies[0].get("hp", 0)) == hp_before_blocked, "production player attack damaged an enemy through the visible altar")
	_require(int(blocked_event.get("blocked_count", 0)) == 1 and int(blocked_event.get("hit_count", -1)) == 0, "production occluded attack did not report a clear blocked result")
	_require(
		await _wait_until(func() -> bool: return _run_feedback_text().contains("障碍"), 1.0),
		"occluded production attack exposed no player-facing blocked feedback"
	)

	_require(
		await _wait_until(
			func() -> bool:
				return bool((simulation.build_snapshot().get("attack_input", {}) as Dictionary).get("ready", false)),
			1.5
		),
		"occluded attack cooldown did not naturally return to ready"
	)
	# Prove an unobstructed real-input attack can kill the final non-splitting
	# target and settle the room without a test-only cooldown reset.
	event_floor = _latest_combat_event_index(runtime)
	var lethal_hp := maxi(1, int(simulation.player.get("power", 1)))
	_arrange_single_enemy(simulation, &"bat", Vector2(0.72, 0.50), &"hurt", lethal_hp)
	_place_player(simulation, Vector2(0.88, 0.50), Vector2.LEFT)
	await _tap_key(KEY_SPACE)
	var hit_event := await _wait_combat_event(runtime, &"player_attack_resolved", event_floor, 2.0)
	_require(int(hit_event.get("hit_count", 0)) == 1, "unobstructed real-input player attack did not report one hit")
	_require(
		await _wait_until(
			func() -> bool:
				var context = run_scene.get("run_context")
				return context != null and context.get("truth_map").is_cleared(Vector2i(2, 4)),
			3.0
		),
		"lethal production attack did not settle the monster room"
	)
	_require(not _combat_active(), "settled monster room remained combat-locked")
	_require(
		await _transition_room(Vector2i.RIGHT, Vector2i(3, 4), &"Normal"),
		"real movement could not leave the settled monster room"
	)
	_finish()


func _arrange_single_enemy(simulation, monster_type: StringName, position: Vector2, state: StringName, hp: int) -> void:
	for enemy_index in range(simulation.enemies.size()):
		var inactive_enemy: Dictionary = simulation.enemies[enemy_index]
		inactive_enemy["hp"] = 0
		inactive_enemy["state"] = &"dead"
		simulation.enemies[enemy_index] = inactive_enemy
	var enemy: Dictionary = simulation.enemies[0]
	var definition := MonsterCatalogScript.definition(monster_type)
	enemy["monster_type"] = monster_type
	enemy["pos"] = position
	enemy["hp"] = hp
	enemy["max_hp"] = maxi(hp, int(definition.get("max_hp", hp)))
	enemy["body_radius"] = float(definition.get("body_radius", 0.03))
	enemy["attack_radius"] = float(definition.get("attack_radius", 0.0))
	enemy["warning_radius"] = float(definition.get("attack_radius", 0.0))
	enemy["state"] = state
	enemy["state_timer"] = 999.0 if state == &"hurt" else 0.0
	enemy["attack_done"] = false
	enemy.erase("avoidance_waypoint")
	enemy.erase("avoidance_last_waypoint")
	enemy.erase("wander_direction")
	enemy.erase("wander_timer")
	simulation.enemies[0] = enemy
	simulation.projectiles.clear()
	simulation.lasers.clear()
	simulation.active = true
	simulation.cleared = false
	simulation.defeated = false
	simulation.call("_capture_previous_transforms")


func _place_player(simulation, position: Vector2, facing: Vector2) -> void:
	var normalized_facing := facing.normalized() if facing.length_squared() > 0.000001 else Vector2.RIGHT
	simulation.player["pos"] = position
	simulation.player["velocity"] = Vector2.ZERO
	simulation.player["facing"] = normalized_facing
	simulation.player["state"] = &"idle"
	simulation.player["state_timer"] = 0.0
	simulation.player["invulnerability"] = 0.0
	simulation.aim_input = normalized_facing
	simulation.move_input = Vector2.ZERO
	simulation.call("_capture_previous_transforms")
	var player = run_scene.get("player_controller")
	if player != null:
		player.call("set_local_position", position)
		player.call("set_facing_vector", normalized_facing)


func _door_for_direction(raw_doors: Variant, direction: Vector2i) -> Dictionary:
	if not raw_doors is Array:
		return {}
	for raw_door in raw_doors as Array:
		if not raw_door is Dictionary:
			continue
		var door := raw_door as Dictionary
		if Vector2i((door.get("payload", {}) as Dictionary).get("direction", Vector2i.ZERO)) == direction:
			return door
	return {}


func _player_is_visually_clear_of_door(
	player,
	player_local_pos: Vector2,
	door: Dictionary
) -> bool:
	var body := Rect2(door.get("body_rect", Rect2()))
	var visual_rect := Rect2(door.get("visual_rect_local", Rect2()))
	var relative_player_rect := Rect2(player.call("presentation_bounds_local"))
	var player_rect := Rect2(
		player_local_pos + relative_player_rect.position,
		relative_player_rect.size
	)
	return (
		not body.grow(CombatSimulationScript.PLAYER_RADIUS).has_point(player_local_pos)
		and not player_rect.intersects(visual_rect)
	)


func _latest_combat_event_index(runtime) -> int:
	var latest := -1
	for raw_event in runtime.get("recent_domain_events") as Array:
		if raw_event is Dictionary:
			latest = maxi(latest, int((raw_event as Dictionary).get("event_index", -1)))
	return latest


func _wait_combat_event(runtime, event_type: StringName, after_index: int, timeout_seconds: float) -> Dictionary:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() <= deadline:
		for raw_event in runtime.get("recent_domain_events") as Array:
			if not raw_event is Dictionary:
				continue
			var event := raw_event as Dictionary
			if int(event.get("event_index", -1)) <= after_index:
				continue
			if StringName(event.get("event_type", &"")) == event_type:
				return event.duplicate(true)
		await create_timer(FRAME_STEP).timeout
	return {}


func _latest_event_of_type_after(runtime, event_type: StringName, after_index: int) -> Dictionary:
	var found_event: Dictionary = {}
	for raw_event in runtime.get("recent_domain_events") as Array:
		if not raw_event is Dictionary:
			continue
		var event := raw_event as Dictionary
		if (
			int(event.get("event_index", -1)) > after_index
			and StringName(event.get("event_type", &"")) == event_type
		):
			found_event = event.duplicate(true)
	return found_event


func _set_only_fixed_seed(deploy_page: Control) -> void:
	var current_model: Dictionary = deploy_page.get("current_model")
	var config: Dictionary = (current_model.get("config", {}) as Dictionary).duplicate(true)
	config["seed_value"] = FIXED_SEED
	current_model["config"] = config
	deploy_page.set("current_model", current_model)


func _transition_room(direction: Vector2i, expected_pos: Vector2i, expected_type: StringName) -> bool:
	var before := Vector2i(_status().get("position", Vector2i(-1, -1)))
	if direction.x != 0:
		await _move_axis(&"y", 0.22)
		await _move_axis(&"x", 0.82 if direction.x > 0 else 0.18)
		await _move_axis(&"y", 0.50)
		await _hold_until(
			KEY_D if direction.x > 0 else KEY_A,
			func() -> bool: return Vector2i(_status().get("position", before)) != before,
			2.5
		)
	else:
		await _move_axis(&"x", 0.22)
		await _move_axis(&"y", 0.82 if direction.y > 0 else 0.18)
		await _move_axis(&"x", 0.50)
		await _hold_until(
			KEY_S if direction.y > 0 else KEY_W,
			func() -> bool: return Vector2i(_status().get("position", before)) != before,
			2.5
		)
	return await _wait_until(func() -> bool:
		var snapshot := _status()
		return (
			Vector2i(snapshot.get("position", Vector2i(-1, -1))) == expected_pos
			and StringName(snapshot.get("current_room", &"Unknown")) == expected_type
		)
	, 2.0)


func _move_axis(axis: StringName, target: float) -> bool:
	for _attempt in range(3):
		var current := _player_local_pos()
		var value := current.x if axis == &"x" else current.y
		if absf(value - target) <= 0.035:
			return true
		var increasing := target > value
		var key := KEY_D if axis == &"x" and increasing else (KEY_A if axis == &"x" else (KEY_S if increasing else KEY_W))
		var reached := await _hold_until(key, func() -> bool:
			var next := _player_local_pos()
			var next_value := next.x if axis == &"x" else next.y
			return next_value >= target if increasing else next_value <= target
		, 1.9)
		await _seconds(0.10)
		if not reached:
			return false
	return absf((_player_local_pos().x if axis == &"x" else _player_local_pos().y) - target) <= 0.09


func _hold_until(keycode: int, condition: Callable, timeout_seconds: float) -> bool:
	_parse_key(keycode, true)
	var reached := await _wait_until(condition, timeout_seconds)
	_parse_key(keycode, false)
	await _frames(2)
	return reached


func _hold_key_seconds(keycode: int, duration: float) -> void:
	_parse_key(keycode, true)
	await _seconds(duration)
	_parse_key(keycode, false)
	await _frames(2)


func _tap_key(keycode: int) -> void:
	_parse_key(keycode, true)
	await process_frame
	_parse_key(keycode, false)
	await _frames(3)


func _parse_key(keycode: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.unicode = keycode if keycode >= 32 and keycode <= 126 else 0
	event.pressed = pressed
	event.echo = false
	Input.parse_input_event(event)
	parsed_input_count += 1


func _click_control(control: Control) -> void:
	if control == null:
		return
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		parsed_input_count += 1
		await process_frame
	await _frames(3)


func _click_playfield_local(local_position: Vector2) -> bool:
	var view = run_scene.get("room_runtime_view") if run_scene != null else null
	if view == null:
		return false
	var point: Vector2 = view.to_global(RuntimeLayoutScript.local_to_world(local_position))
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	var targeted := false
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		if pressed:
			targeted = bool(run_scene.call("_pointer_targets_playfield", event))
		Input.parse_input_event(event)
		parsed_input_count += 1
		await process_frame
	await _frames(2)
	return targeted


func _wait_screen(expected: StringName, timeout_seconds: float) -> bool:
	return await _wait_until(func() -> bool: return StringName(run_scene.get("screen_state")) == expected, timeout_seconds)


func _wait_until(predicate: Callable, timeout_seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() <= deadline:
		if bool(predicate.call()):
			return true
		await create_timer(FRAME_STEP).timeout
	return bool(predicate.call())


func _seconds(duration: float) -> void:
	if duration > 0.0:
		await create_timer(duration).timeout


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _deploy_page() -> Control:
	var shell = run_scene.get("ui_shell") if run_scene != null else null
	return shell.call("get_deploy_page") as Control if shell != null else null


func _status() -> Dictionary:
	var context = run_scene.get("run_context") if run_scene != null else null
	return context.call("get_status_snapshot") as Dictionary if context != null else {}


func _player_local_pos() -> Vector2:
	var player = run_scene.get("player_controller") if run_scene != null else null
	return player.call("get_local_position") as Vector2 if player != null else Vector2(-1, -1)


func _combat_active() -> bool:
	var runtime = run_scene.get("in_run_runtime") if run_scene != null else null
	return runtime != null and bool(runtime.call("has_active_combat"))


func _run_feedback_text() -> String:
	var surface = run_scene.get("run_surface") if run_scene != null else null
	var label = surface.get("command_feedback_label") if surface != null else null
	return String(label.text) if label is Label else ""


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if main != null and is_instance_valid(main):
		main.free()
	main = null
	run_scene = null
	if failures.is_empty():
		print("%s seed=%d input=parsed movement=blocked recovery=mobile melee_navigation=progressing door_hold=single_dispatch warning=visible facing=locked_then_released cooldown=early_rejected_no_turn,late_buffered attack=occluded_visual_clipped,hit settlement=cleared leave=normal inputs=%d" % [PASS_MARKER, FIXED_SEED, parsed_input_count])
		_schedule_quit(0)
		return
	for failure in failures:
		push_error("I3R production combat obstacle journey failure: " + failure)
	print("%s failures=%d inputs=%d" % [FAIL_MARKER, failures.size(), parsed_input_count])
	_schedule_quit(1)


func _schedule_quit(exit_code: int) -> void:
	if quit_scheduled:
		return
	quit_scheduled = true
	call_deferred("_quit_after_cleanup", exit_code)


func _quit_after_cleanup(exit_code: int) -> void:
	await process_frame
	await process_frame
	quit(exit_code)
