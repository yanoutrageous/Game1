extends SceneTree

const CombatSimulationScript := preload("res://scripts/gameplay/combat/g41_combat_simulation.gd")
const MonsterCatalogScript := preload("res://scripts/gameplay/combat/g41_monster_catalog.gd")
const PlayerControllerScript := preload("res://scripts/gameplay/player/player_controller.gd")
const RuntimeActorViewScript := preload("res://scripts/gameplay/runtime/g41_runtime_actor_view.gd")
const RuntimeLayoutScript := preload("res://scripts/gameplay/runtime/g41_runtime_layout.gd")
const RoomRuntimeViewScript := preload("res://scripts/gameplay/runtime/g41_room_runtime_view.gd")
const RuntimeAnimationCatalogScript := preload("res://scripts/presentation/art24/art24_runtime_animation_catalog.gd")
const RunSceneCommandFeedbackScript := preload("res://scripts/core/run/run_scene_command_feedback.gd")
const RunSceneRouteControllerScript := preload("res://scripts/core/run/run_scene_route_controller.gd")
const InRunRuntimeScript := preload("res://scripts/core/run/g41_in_run_runtime.gd")
const CombatStateScript := preload("res://scripts/core/run/combat_state.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")

const PASS_MARKER := "I3R_COMBAT_ATTACK_CONTRACT=PASS"
const FAIL_MARKER := "I3R_COMBAT_ATTACK_CONTRACT=FAIL"
const TOLERANCE := 0.0001

var failures: Array[String] = []
var captured_feedback_cues: Array[Dictionary] = []
var captured_command_feedback: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_production_encounter_composition()
	_check_enemy_power_contract()
	_check_enemy_entry_grace()
	_check_melee_cadence()
	_check_finite_attack_buffer()
	_check_runtime_attack_status()
	_check_attack_interruption()
	_check_frozen_attack_contract()
	_check_queued_pointer_facing_contract()
	_check_player_perceptible_attack_timeline()
	_check_attack_presentation_contract()
	_check_diagonal_attack_visual_alignment()
	_check_hit_and_hurt_feedback()
	_check_hurt_state_visibility()
	_check_maximum_frame_delta_has_no_debt()
	_check_melee_circle_sector_boundaries()
	_check_degenerate_circle_sector_semantics()
	_check_moving_and_multiple_targets()
	_check_enemy_melee_warning_matches_hit_radius()
	await _check_projectile_and_laser_geometry()
	_check_bounded_laser_turn()
	_check_production_arena_contract()
	_check_transition_attempt_gate()
	_check_outer_schedule_determinism()
	_finish()


func _check_production_encounter_composition() -> void:
	var runtime = InRunRuntimeScript.new()
	var observed_types: Array[StringName] = []
	for seed in range(12):
		var encounter: Array = runtime.call("_encounter_types", seed)
		_require(encounter.size() == 1, "production encounter did not keep one mother enemy for seed %d" % seed)
		if encounter.size() != 1:
			continue
		var monster_type := StringName(encounter[0])
		_require(
			monster_type in [
				MonsterCatalogScript.TYPE_SLIME,
				MonsterCatalogScript.TYPE_BAT,
				MonsterCatalogScript.TYPE_DRONE,
			],
			"production encounter selected an unsupported mother enemy for seed %d" % seed
		)
		if not observed_types.has(monster_type):
			observed_types.append(monster_type)
	_require(observed_types.size() == 3, "production encounter seed mapping no longer reaches all three mother-enemy types")


func _check_enemy_power_contract() -> void:
	var context := RunContextScript.new()
	context.seed_value = 1001
	context.power = 5
	var position := Vector2i(1, 5)
	var identity := CombatStateScript.build_enemy_state(context, position, 3)
	_require(int(identity.get("identity_hash", -1)) == 657, "enemy identity hash drifted from the current UE/Lua cell contract")
	_require(int(identity.get("base_power", -1)) == 6, "enemy base power drifted for the known cell vector")
	_require(int(identity.get("adjacent_power_bonus", -1)) == 6, "nearby-mine power bonus is not two per mine")
	_require(int(identity.get("enemy_power", -1)) == 12, "nearby-mine count did not reach enemy power")
	_require(String(identity.get("enemy_name", "")) == "失控搬运机", "known cell vector selected the wrong authored enemy name")
	_require(
		CombatStateScript.reward_gold_for_enemy_power(12) == 0
		and CombatStateScript.reward_gold_for_enemy_power(15) == 3,
		"combat reward is not derived from the mother enemy power"
	)

	var types: Array[StringName] = [
		MonsterCatalogScript.TYPE_SLIME,
		MonsterCatalogScript.TYPE_BAT,
		MonsterCatalogScript.TYPE_DRONE,
	]
	for monster_type in types:
		var definition := MonsterCatalogScript.definition(monster_type)
		var profile := MonsterCatalogScript.runtime_profile(monster_type, 12, "测试异常体")
		var simulation = CombatSimulationScript.new()
		simulation.start({
			"seed": 901,
			"monster_types": [monster_type],
			"enemy_profiles": [profile],
		})
		var enemy: Dictionary = simulation.enemies[0]
		_require(
			int(enemy.get("max_hp", 0)) == int(definition.get("max_hp", 0)) + 12,
			"%s HP did not add the authoritative enemy power" % String(monster_type)
		)
		_require(
			int(enemy.get("damage", 0)) == MonsterCatalogScript.damage_for_power(12, monster_type),
			"%s damage did not derive from enemy power and archetype multiplier" % String(monster_type)
		)
		_require(
			int(enemy.get("enemy_power", -1)) == 12
			and String(enemy.get("enemy_name", "")) == "测试异常体",
			"%s simulation snapshot lost the production enemy identity" % String(monster_type)
		)

	var fixture = CombatSimulationScript.new()
	fixture.start({"seed": 902, "monster_types": [&"slime", &"bat"]})
	_require(
		int(fixture.enemies[0].get("max_hp", 0)) == int(MonsterCatalogScript.definition(&"slime").get("max_hp", 0))
		and int(fixture.enemies[1].get("max_hp", 0)) == int(MonsterCatalogScript.definition(&"bat").get("max_hp", 0)),
		"explicit multi-enemy fixture without profiles changed its legacy HP contract"
	)

	var mother_profile := MonsterCatalogScript.runtime_profile(&"slime", 20, "滞留工偶")
	var split = CombatSimulationScript.new()
	split.start({
		"seed": 903,
		"player_power": 100,
		"monster_types": [&"slime"],
		"enemy_profiles": [mother_profile],
	})
	split.call("_damage_enemy", 0, 1000)
	var living_children: Array[Dictionary] = []
	for enemy in split.enemies:
		if StringName(enemy.get("monster_type", &"")) == MonsterCatalogScript.TYPE_SLIMELING:
			living_children.append(enemy)
	_require(living_children.size() == 2, "profiled slime did not create exactly two child enemies")
	for child in living_children:
		_require(
			int(child.get("enemy_power", -1)) == 9
			and int(child.get("max_hp", 0)) == 18
			and int(child.get("damage", 0)) == MonsterCatalogScript.damage_for_power(9, &"slimeling"),
			"slimeling did not inherit the mother's 0.45 power profile"
		)

	var runtime = InRunRuntimeScript.new()
	var first_type: Array = runtime.call("_encounter_types", 1001, position, 3)
	var reentry_type: Array = runtime.call("_encounter_types", 1001, position, 3)
	_require(
		first_type == reentry_type and first_type.size() == 1,
		"same-cell encounter identity changed across simulated re-entry"
	)


func _check_enemy_entry_grace() -> void:
	var simulation = CombatSimulationScript.new()
	simulation.start({
		"seed": 4807,
		"player_pos": Vector2(0.20, 0.20),
		"player_hp": 100,
		"player_max_hp": 100,
		"monster_types": [&"bat"],
	})
	var enemy_start := Vector2(simulation.enemies[0].get("pos", Vector2.ZERO))
	simulation.drain_events()
	var grace_ticks := int(ceil(
		MonsterCatalogScript.ENTRY_GRACE_SECONDS / CombatSimulationScript.FIXED_STEP
	))
	simulation.advance_ticks(grace_ticks - 1)
	var during_grace: Dictionary = simulation.enemies[0]
	var grace_events: Array = simulation.drain_events()
	_require(StringName(during_grace.get("state", &"")) == &"arrival", "enemy left arrival before the authored grace elapsed")
	_require(
		Vector2(during_grace.get("pos", Vector2.INF)).is_equal_approx(enemy_start),
		"enemy moved during its simulation-authoritative arrival grace"
	)
	_require(_event_count(grace_events, &"ranged_aim_started") == 0, "ranged enemy aimed during arrival grace")
	_require(_event_count(grace_events, &"ranged_fired") == 0, "ranged enemy fired during arrival grace")
	_require(simulation.projectiles.is_empty() and simulation.lasers.is_empty(), "enemy produced damage geometry during arrival grace")
	simulation.advance_ticks(1)
	_require(StringName(simulation.enemies[0].get("state", &"")) == &"idle", "enemy did not settle into idle after arrival grace")
	_require(_event_count(simulation.drain_events(), &"ranged_aim_started") == 0, "enemy began aiming on the arrival-completion tick")
	simulation.advance_ticks(1)
	_require(StringName(simulation.enemies[0].get("state", &"")) == &"aim", "ranged enemy did not begin its readable aim after arrival")
	_require(_event_count(simulation.drain_events(), &"ranged_aim_started") == 1, "post-arrival aim emitted no authoritative cue")


func _check_melee_cadence() -> void:
	var simulation = CombatSimulationScript.new()
	simulation.start({
		"seed": 4811,
		"player_pos": Vector2(0.50, 0.50),
		"player_hp": 100,
		"player_max_hp": 100,
		"monster_types": [&"slime"],
	})
	var enemy: Dictionary = simulation.enemies[0]
	enemy["pos"] = Vector2(0.62, 0.50)
	simulation.enemies[0] = enemy
	simulation.call("_capture_previous_transforms")
	simulation.drain_events()
	var grace_ticks := int(ceil(
		MonsterCatalogScript.ENTRY_GRACE_SECONDS / CombatSimulationScript.FIXED_STEP
	))
	var idle_seconds := float(
		MonsterCatalogScript.definition(MonsterCatalogScript.TYPE_SLIME).get("idle_seconds", 0.0)
	)
	var idle_ticks := int(ceil(idle_seconds / CombatSimulationScript.FIXED_STEP))
	simulation.advance_ticks(grace_ticks + idle_ticks - 1)
	_require(
		_event_count(simulation.drain_events(), &"melee_warning_started") == 0,
		"melee warning started before arrival plus authored idle cadence elapsed"
	)
	simulation.advance_ticks(2)
	_require(
		_event_count(simulation.drain_events(), &"melee_warning_started") == 1,
		"melee warning did not start after the authored idle cadence"
	)
	var slimeling_definition := MonsterCatalogScript.definition(MonsterCatalogScript.TYPE_SLIMELING)
	_require(
		is_equal_approx(float(slimeling_definition.get("idle_seconds", 0.0)), idle_seconds)
		and is_equal_approx(
			float(slimeling_definition.get("warning_seconds", 0.0)),
			float(MonsterCatalogScript.definition(MonsterCatalogScript.TYPE_SLIME).get("warning_seconds", 0.0))
		)
		and is_equal_approx(
			float(slimeling_definition.get("active_seconds", 0.0)),
			float(MonsterCatalogScript.definition(MonsterCatalogScript.TYPE_SLIME).get("active_seconds", 0.0))
		)
		and is_equal_approx(
			float(slimeling_definition.get("cooldown_seconds", 0.0)),
			float(MonsterCatalogScript.definition(MonsterCatalogScript.TYPE_SLIME).get("cooldown_seconds", 0.0))
		),
		"slimeling cadence drifted from the authored melee warning/active/cooldown contract"
	)


func _check_finite_attack_buffer() -> void:
	var simulation = _stationary_melee_simulation(
		Vector2(0.20, 0.20),
		[Vector2(0.85, 0.85)],
		Vector2.RIGHT
	)
	_require(simulation.queue_player_attack(), "initial attack request was rejected")
	simulation.advance_ticks(1)
	for _press in range(4):
		_require(
			not simulation.queue_player_attack(),
			"early cooldown press was accepted outside the finite attack-buffer window"
		)
		simulation.advance_ticks(1)
	var attack_input: Dictionary = simulation.build_snapshot().get("attack_input", {})
	_require(not bool(attack_input.get("buffered", true)), "rejected cooldown presses created a hidden attack buffer")
	_require(
		not bool(attack_input.get("buffer_window_open", true)),
		"early cooldown incorrectly advertised the late input-buffer window"
	)

	var wait_ticks := 0
	while wait_ticks < 90:
		attack_input = simulation.build_snapshot().get("attack_input", {})
		if bool(attack_input.get("buffer_window_open", false)):
			break
		simulation.advance_ticks(1)
		wait_ticks += 1
	_require(wait_ticks < 90, "attack cooldown never opened its documented late buffer window")
	_require(simulation.queue_player_attack(Vector2.UP), "late cooldown press was rejected inside the attack-buffer window")
	attack_input = simulation.build_snapshot().get("attack_input", {})
	_require(bool(attack_input.get("buffered", false)), "accepted late attack did not expose its buffered state")
	_require(
		Vector2(attack_input.get("facing", Vector2.ZERO)).is_equal_approx(Vector2.UP),
		"late attack buffer lost the click-time facing"
	)
	var events_before_second: Array = simulation.drain_events()
	_require(
		_event_count(events_before_second, &"player_attack_started") == 1,
		"early cooldown presses produced an extra delayed attack"
	)
	simulation.advance_ticks(20)
	var second_events: Array = simulation.drain_events()
	_require(
		_event_count(second_events, &"player_attack_started") == 1,
		"late buffered input did not produce exactly one follow-up attack"
	)
	var second_started := _first_event(second_events, &"player_attack_started")
	_require(
		Vector2(second_started.get("facing", Vector2.ZERO)).is_equal_approx(Vector2.UP),
		"follow-up attack did not retain the late buffered facing"
	)

	var pause_simulation = _stationary_melee_simulation(
		Vector2(0.20, 0.20),
		[Vector2(0.85, 0.85)],
		Vector2.RIGHT
	)
	_require(pause_simulation.queue_player_attack(), "attack request before pause was rejected")
	pause_simulation.set_paused(true)
	attack_input = pause_simulation.build_snapshot().get("attack_input", {})
	_require(not bool(attack_input.get("buffered", true)), "pausing did not clear the attack input buffer")
	pause_simulation.set_paused(false)
	pause_simulation.advance_ticks(20)
	_require(_event_count(pause_simulation.drain_events(), &"player_attack_started") == 0, "unpausing replayed an attack buffered before pause")

	simulation.sync_player_durable_stats(0, 100, 10)
	_require(not simulation.queue_player_attack(), "defeated combat accepted a new attack request")
	attack_input = simulation.build_snapshot().get("attack_input", {})
	_require(not bool(attack_input.get("buffered", true)), "terminated combat retained attack input")


func _check_attack_interruption() -> void:
	var interrupted = _stationary_melee_simulation(
		Vector2(0.20, 0.20),
		[Vector2(0.85, 0.85)],
		Vector2.RIGHT
	)
	var target_hp := int(interrupted.enemies[0].get("hp", 0))
	interrupted.queue_player_attack()
	interrupted.advance_ticks(1)
	interrupted.call("_damage_player", 3, "interrupt-fixture", &"melee")
	interrupted.advance_ticks(20)
	var interrupted_events: Array = interrupted.drain_events()
	_require(
		_event_count(interrupted_events, &"player_attack_interrupted") == 1,
		"pre-impact damage emitted no single attack-interrupted event"
	)
	_require(
		_event_count(interrupted_events, &"player_attack_resolved") == 0,
		"interrupted pre-impact attack still resolved"
	)
	_require(
		int(interrupted.enemies[0].get("hp", 0)) == target_hp,
		"interrupted pre-impact attack damaged its target"
	)

	var resolved = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.58, 0.50)],
		Vector2.RIGHT
	)
	resolved.queue_player_attack()
	resolved.advance_ticks(8)
	resolved.call("_damage_player", 3, "post-impact-fixture", &"melee")
	var resolved_events: Array = resolved.drain_events()
	_require(
		_event_count(resolved_events, &"player_attack_resolved") == 1,
		"post-impact fixture did not reach its authoritative settlement"
	)
	_require(
		_event_count(resolved_events, &"player_attack_interrupted") == 0,
		"damage after impact falsely reported an attack interruption"
	)


func _check_runtime_attack_status() -> void:
	var runtime = InRunRuntimeScript.new()
	runtime.simulation = _stationary_melee_simulation(
		Vector2(0.20, 0.20),
		[Vector2(0.85, 0.85)],
		Vector2.RIGHT
	)
	var first: Dictionary = runtime.request_attack(Vector2.RIGHT)
	_require(
		bool(first.get("ok", false))
		and StringName(first.get("status", &"")) == &"attack_queued",
		"ready attack request did not report immediate queueing"
	)
	runtime.simulation.advance_ticks(1)
	var early: Dictionary = runtime.request_attack(Vector2.LEFT)
	_require(
		not bool(early.get("ok", true))
		and StringName(early.get("status", &"")) == &"attack_cooling_down"
		and float(early.get("retry_after_seconds", 0.0)) > 0.0,
		"early cooldown request did not return a specific retry contract"
	)
	var wait_ticks := 0
	while wait_ticks < 90:
		var attack_input: Dictionary = runtime.simulation.build_snapshot().get("attack_input", {})
		if bool(attack_input.get("buffer_window_open", false)):
			break
		runtime.simulation.advance_ticks(1)
		wait_ticks += 1
	var buffered: Dictionary = runtime.request_attack(Vector2.UP)
	_require(
		bool(buffered.get("ok", false))
		and StringName(buffered.get("status", &"")) == &"attack_buffered",
		"late cooldown request did not report its accepted buffer state"
	)


func _check_frozen_attack_contract() -> void:
	var simulation = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.64, 0.50)],
		Vector2.RIGHT
	)
	var hp_before := int(simulation.enemies[0].get("hp", 0))
	_require(simulation.queue_player_attack(), "frozen-contract attack request was rejected")
	simulation.advance_ticks(1)
	var started_geometry: Dictionary = simulation.build_snapshot().get("player_attack_geometry", {})
	var frozen_origin := Vector2(started_geometry.get("origin", Vector2.ZERO))
	var frozen_facing := Vector2(started_geometry.get("facing", Vector2.ZERO))
	_require(not started_geometry.is_empty() and bool(started_geometry.get("visible", false)), "windup did not expose visible authoritative attack geometry")
	_require(frozen_facing.is_equal_approx(Vector2.RIGHT), "attack did not capture its starting facing")

	simulation.set_player_input(Vector2.LEFT, Vector2.LEFT)
	simulation.advance_ticks(7)
	var active_geometry: Dictionary = simulation.build_snapshot().get("player_attack_geometry", {})
	_require(Vector2(active_geometry.get("origin", Vector2.INF)).is_equal_approx(frozen_origin), "attack origin moved during windup/active")
	_require(Vector2(active_geometry.get("facing", Vector2.ZERO)).is_equal_approx(frozen_facing), "attack facing changed after the player turned")
	_require(Vector2(simulation.player.get("facing", Vector2.ZERO)).is_equal_approx(frozen_facing), "player presentation facing changed during the frozen attack")
	_require(Vector2(simulation.player.get("pos", Vector2.INF)).is_equal_approx(frozen_origin), "player locomotion detached the actor from the frozen attack origin")
	_require(int(simulation.enemies[0].get("hp", 0)) < hp_before, "frozen right-facing attack failed after a left-facing input arrived during windup")
	var events: Array = simulation.drain_events()
	var started := _first_event(events, &"player_attack_started")
	var resolved := _first_event(events, &"player_attack_resolved")
	_require(Vector2(started.get("origin", Vector2.INF)).is_equal_approx(Vector2(resolved.get("origin", Vector2.ZERO))), "start and resolve events disagreed on attack origin")
	_require(Vector2(started.get("facing", Vector2.ZERO)).is_equal_approx(Vector2(resolved.get("facing", Vector2.INF))), "start and resolve events disagreed on attack facing")
	var position_before_recovery := Vector2(simulation.player.get("pos", Vector2.ZERO))
	var recovery_wait := 0
	while (
		StringName(simulation.player.get("state", &"")) != &"attack_recovery"
		and recovery_wait < 20
	):
		simulation.advance_ticks(1)
		recovery_wait += 1
	_require(recovery_wait < 20, "attack never entered its authored recovery phase")
	simulation.advance_ticks(2)
	var recovery_geometry: Dictionary = simulation.build_snapshot().get("player_attack_geometry", {})
	_require(
		Vector2(simulation.player.get("pos", Vector2.ZERO)).x < position_before_recovery.x,
		"attack recovery kept locomotion locked after damaging frames ended"
	)
	_require(
		not bool(recovery_geometry.get("visible", true)),
		"mobile recovery exposed damaging-looking attack geometry"
	)
	_require(
		Vector2(simulation.player.get("facing", Vector2.ZERO)).is_equal_approx(frozen_facing),
		"mobile recovery changed the authored attack facing before recovery ended"
	)


func _check_queued_pointer_facing_contract() -> void:
	var simulation = _stationary_melee_simulation(
		Vector2(0.50, 0.50),
		[Vector2(0.50, 0.31)],
		Vector2.RIGHT
	)
	var hp_before := int(simulation.enemies[0].get("hp", 0))
	_require(
		simulation.queue_player_attack(Vector2.UP),
		"pointer-facing attack request was rejected"
	)
	# Movement may change between the click and the next fixed step. The queued
	# pointer intent must remain the atomic facing authority for this attack.
	simulation.set_player_input(Vector2.LEFT, Vector2.LEFT)
	simulation.advance_ticks(1)
	var geometry: Dictionary = simulation.build_snapshot().get("player_attack_geometry", {})
	_require(
		Vector2(geometry.get("facing", Vector2.ZERO)).is_equal_approx(Vector2.UP),
		"queued pointer facing was overwritten by movement before attack start"
	)
	_require(
		Vector2(simulation.player.get("facing", Vector2.ZERO)).is_equal_approx(Vector2.UP),
		"player presentation did not follow the queued pointer-facing contract"
	)
	simulation.advance_ticks(8)
	_require(
		int(simulation.enemies[0].get("hp", 0)) < hp_before,
		"pointer-facing attack did not hit the target in its authored direction"
	)


func _check_player_perceptible_attack_timeline() -> void:
	var simulation = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.58, 0.50)],
		Vector2.RIGHT
	)
	var enemy_id := String(simulation.enemies[0].get("enemy_id", ""))
	var hp_before := int(simulation.enemies[0].get("hp", 0))
	var expected_damage := int(simulation.player.get("power", 0))
	var observed_phases: Array[StringName] = []
	var events: Array = []
	var active_tick := 0
	var resolution_active_tick := -1
	var resolution_phase: StringName = &""
	var damage_phase: StringName = &""
	var completed := false
	_require(simulation.queue_player_attack(), "player-perceptible timeline attack request was rejected")
	for _tick in range(40):
		simulation.advance_ticks(1)
		var state := StringName(simulation.player.get("state", &""))
		if observed_phases.is_empty() or observed_phases.back() != state:
			observed_phases.append(state)
		if state == &"attack_active":
			active_tick += 1
		var geometry: Dictionary = simulation.build_snapshot().get("player_attack_geometry", {})
		match state:
			&"attack_windup":
				_require(
					int(simulation.enemies[0].get("hp", 0)) == hp_before,
					"enemy took damage during player attack windup"
				)
				_require(
					not geometry.is_empty()
					and bool(geometry.get("visible", false))
					and StringName(geometry.get("phase", &"")) == state,
					"windup did not expose the matching visible attack phase"
				)
			&"attack_active":
				_require(
					not geometry.is_empty()
					and bool(geometry.get("visible", false))
					and StringName(geometry.get("phase", &"")) == state,
					"active frames did not expose the matching visible attack phase"
				)
			&"attack_recovery":
				_require(
					not geometry.is_empty()
					and not bool(geometry.get("visible", true))
					and StringName(geometry.get("phase", &"")) == state,
					"recovery retained a damaging-looking sector or lost its phase contract"
				)
			&"idle":
				_require(geometry.is_empty(), "completed attack retained stale visible geometry")
				completed = true
		var tick_events: Array = simulation.drain_events()
		for raw_event in tick_events:
			if not raw_event is Dictionary:
				continue
			var event := raw_event as Dictionary
			events.append(event)
			var event_type := StringName(event.get("event_type", &""))
			if event_type == &"player_attack_resolved":
				resolution_phase = state
				resolution_active_tick = active_tick
			elif event_type == &"enemy_damaged":
				damage_phase = state
		if completed:
			break

	_require(completed, "player attack did not complete within its bounded phase window")
	_require(
		observed_phases == [&"attack_windup", &"attack_active", &"attack_recovery", &"idle"],
		"player attack phase order was not windup -> active -> recovery -> idle: %s" % [observed_phases]
	)
	_require(_event_count(events, &"player_attack_started") == 1, "one input did not produce exactly one attack start")
	_require(_event_count(events, &"player_attack_resolved") == 1, "one uninterrupted attack did not produce exactly one settlement")
	_require(_event_count(events, &"enemy_damaged") == 1, "one attack applied damage more or less than once")
	_require(resolution_phase == &"attack_active", "attack settlement occurred outside the active phase")
	_require(damage_phase == &"attack_active", "enemy damage occurred outside the active phase")
	_require(
		hp_before - int(simulation.enemies[0].get("hp", 0)) == expected_damage,
		"one attack did not apply exactly one authored player-power settlement"
	)
	var started := _first_event(events, &"player_attack_started")
	var resolved := _first_event(events, &"player_attack_resolved")
	_require(
		String(started.get("attack_id", "")) == String(resolved.get("attack_id", "")),
		"attack start and settlement did not share one attack id"
	)
	_require(
		int(resolved.get("tick", -1)) > int(started.get("tick", -1)),
		"attack settled before a perceptible windup elapsed"
	)
	_require(
		int(resolved.get("hit_count", 0)) == 1
		and (resolved.get("hit_enemy_ids", []) as Array).has(enemy_id),
		"attack settlement did not identify its one damaged target"
	)

	var active_motions: Array = RuntimeAnimationCatalogScript.PLAYER_MOTIONS.get(&"attack_active", [])
	var impact_frame_index := active_motions.find(&"attack_impact")
	var active_frame_seconds := RuntimeAnimationCatalogScript.player_frame_duration(&"attack_active")
	var first_visible_impact_tick := maxi(
		1,
		int(ceil(float(maxi(impact_frame_index, 0)) * active_frame_seconds / CombatSimulationScript.FIXED_STEP))
	)
	_require(
		impact_frame_index >= 0 and resolution_active_tick >= first_visible_impact_tick,
		"attack settled on active tick %d before authored attack_impact becomes visible on tick %d"
		% [resolution_active_tick, first_visible_impact_tick]
	)


func _check_attack_presentation_contract() -> void:
	var expected_motions := {
		&"attack_windup": [&"attack_windup"],
		&"attack_active": [&"attack_swing", &"attack_impact"],
		&"attack_recovery": [&"attack_recover"],
	}
	var expected_phase_seconds := {
		&"attack_windup": CombatSimulationScript.PLAYER_ATTACK_WINDUP,
		&"attack_active": CombatSimulationScript.PLAYER_ATTACK_ACTIVE,
		&"attack_recovery": CombatSimulationScript.PLAYER_ATTACK_RECOVERY,
	}
	for state in expected_motions:
		var motions: Array = RuntimeAnimationCatalogScript.PLAYER_MOTIONS.get(state, [])
		_require(motions == expected_motions[state], "%s does not map to its authored readable attack poses" % state)
		var presented_seconds := (
			RuntimeAnimationCatalogScript.player_frame_duration(state)
			* float(RuntimeAnimationCatalogScript.player_frame_count(state))
		)
		_require(
			is_equal_approx(presented_seconds, float(expected_phase_seconds[state])),
			"%s presentation duration %.3f differs from simulation duration %.3f"
			% [state, presented_seconds, float(expected_phase_seconds[state])]
		)
		for facing in RuntimeAnimationCatalogScript.PLAYER_FACINGS:
			for frame_index in range(motions.size()):
				var texture_path := RuntimeAnimationCatalogScript.player_texture_path(
					facing,
					state,
					frame_index,
					false
				)
				_require(
					ResourceLoader.exists(texture_path, "Texture2D"),
					"attack presentation texture is missing: %s" % texture_path
				)


func _check_diagonal_attack_visual_alignment() -> void:
	var origin := Vector2(0.20, 0.20)
	var facing := Vector2(1.0, 0.40).normalized()
	var target_pos := origin + facing * 0.18
	var simulation = _stationary_melee_simulation(origin, [target_pos], facing)
	var hp_before := int(simulation.enemies[0].get("hp", 0))
	_require(simulation.queue_player_attack(), "diagonal visual-alignment attack request was rejected")
	simulation.advance_ticks(1)
	var geometry: Dictionary = simulation.build_snapshot().get("player_attack_geometry", {})
	var arc_points: Array = geometry.get("visible_arc_points", [])
	_require(
		Vector2(geometry.get("facing", Vector2.ZERO)).is_equal_approx(facing),
		"visible attack geometry lost the authored diagonal facing"
	)
	_require(
		arc_points.size() == CombatSimulationScript.ATTACK_VISIBILITY_SEGMENTS + 1,
		"visible diagonal attack arc did not expose the full authoritative sample count"
	)
	if not arc_points.is_empty():
		var midpoint := Vector2(arc_points[arc_points.size() / 2])
		var midpoint_offset := midpoint - origin
		_require(
			midpoint_offset.normalized().is_equal_approx(facing),
			"visible attack centerline did not point along the authoritative facing"
		)
		_require(
			is_equal_approx(midpoint_offset.length(), CombatSimulationScript.PLAYER_ATTACK_RANGE),
			"visible attack centerline range differed from the hit-test range"
		)
		var room_view = RoomRuntimeViewScript.new()
		var world_arc: PackedVector2Array = room_view.call("_player_attack_arc_world_points", geometry)
		_require(
			world_arc.size() == arc_points.size()
			and world_arc[world_arc.size() / 2].is_equal_approx(RuntimeActorViewScript.local_to_world(midpoint)),
			"room presentation did not consume the authoritative diagonal attack arc"
		)
		room_view.free()
	simulation.advance_ticks(7)
	_require(
		int(simulation.enemies[0].get("hp", 0)) < hp_before,
		"target centered inside the visible diagonal attack arc was not hit"
	)


func _check_hit_and_hurt_feedback() -> void:
	var hit_simulation = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.58, 0.50)],
		Vector2.RIGHT
	)
	hit_simulation.queue_player_attack()
	hit_simulation.advance_ticks(8)
	var resolved := _first_event(hit_simulation.drain_events(), &"player_attack_resolved")
	_require(not resolved.is_empty(), "hit fixture emitted no attack settlement for feedback routing")
	if not resolved.is_empty():
		captured_feedback_cues.clear()
		captured_command_feedback.clear()
		RunSceneCommandFeedbackScript.route_combat_attack_resolution(
			resolved,
			"i3r:combat:hit",
			&"hit",
			Callable(self, "_capture_feedback_cue"),
			Callable(self, "_capture_command_feedback")
		)
		_require(captured_feedback_cues.size() == 1, "successful attack settlement emitted no single hit cue")
		_require(captured_command_feedback.is_empty(), "successful hit also emitted a contradictory miss message")
		if captured_feedback_cues.size() == 1:
			var cue: Dictionary = captured_feedback_cues[0]
			var metadata: Dictionary = cue.get("metadata", {})
			_require(StringName(cue.get("cue_id", &"")) == &"hit", "successful settlement routed the wrong feedback cue")
			_require(
				String(metadata.get("attack_id", "")) == String(resolved.get("attack_id", "")),
				"hit feedback lost the settled attack identity"
			)

	var miss_simulation = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.20, 0.50)],
		Vector2.RIGHT
	)
	miss_simulation.queue_player_attack()
	miss_simulation.advance_ticks(8)
	var missed := _first_event(miss_simulation.drain_events(), &"player_attack_resolved")
	captured_feedback_cues.clear()
	captured_command_feedback.clear()
	RunSceneCommandFeedbackScript.route_combat_attack_resolution(
		missed,
		"i3r:combat:miss",
		&"hit",
		Callable(self, "_capture_feedback_cue"),
		Callable(self, "_capture_command_feedback")
	)
	_require(captured_feedback_cues.is_empty(), "missed attack emitted a false hit cue")
	_require(
		captured_command_feedback.size() == 1
		and StringName(captured_command_feedback[0].get("status", &"")) == &"attack_missed",
		"missed attack emitted no readable miss feedback"
	)

	var player = PlayerControllerScript.new()
	root.add_child(player)
	player.set_process(false)
	player.set_input_enabled(false)
	player.set_runtime_visual_state(&"hurt")
	player.call("_process", 0.0)
	var player_sprite := player.get_node("Sprite") as Sprite2D
	_require(
		player.last_texture_path.ends_with("_hit.png")
		and player_sprite.modulate.is_equal_approx(PlayerControllerScript.HURT_FEEDBACK_MODULATE),
		"player hurt state did not produce its authored pose and visible damage tint"
	)
	player.free()

	var enemy_hurt = _stationary_melee_simulation(
		Vector2(0.20, 0.20),
		[Vector2(0.85, 0.85)],
		Vector2.RIGHT
	)
	enemy_hurt.call("_damage_enemy", 0, 1)
	var actor = RuntimeActorViewScript.new()
	root.add_child(actor)
	actor.set_process(false)
	actor.configure(&"slime", enemy_hurt.enemies[0])
	var enemy_sprite := actor.get_node("VisualRoot/ArtVisual") as Sprite2D
	_require(
		enemy_sprite != null and not enemy_sprite.modulate.is_equal_approx(Color.WHITE),
		"enemy hurt state produced no visible hit response"
	)
	actor.free()


func _check_hurt_state_visibility() -> void:
	var player_hurt = _stationary_melee_simulation(
		Vector2(0.20, 0.20),
		[Vector2(0.85, 0.85)],
		Vector2.RIGHT
	)
	player_hurt.call("_damage_player", 3, "i3r-hurt-fixture", &"melee")
	_require(StringName(player_hurt.player.get("state", &"")) == &"hurt", "player damage did not enter hurt state")
	player_hurt.advance_ticks(1)
	_require(StringName(player_hurt.player.get("state", &"")) == &"hurt", "player hurt state was overwritten on the next simulation tick")
	player_hurt.advance_ticks(7)
	_require(StringName(player_hurt.player.get("state", &"")) == &"idle", "player hurt state did not release after its authored duration")

	var enemy_hurt = _stationary_melee_simulation(
		Vector2(0.20, 0.20),
		[Vector2(0.85, 0.85)],
		Vector2.RIGHT
	)
	enemy_hurt.call("_damage_enemy", 0, 1)
	_require(StringName(enemy_hurt.enemies[0].get("state", &"")) == &"hurt", "enemy damage did not enter hurt state")
	enemy_hurt.advance_ticks(1)
	_require(StringName(enemy_hurt.enemies[0].get("state", &"")) == &"hurt", "enemy hurt state was overwritten by AI in the damage tick")
	enemy_hurt.advance_ticks(7)
	_require(StringName(enemy_hurt.enemies[0].get("state", &"")) == &"idle", "enemy hurt state did not release after its authored duration")


func _check_maximum_frame_delta_has_no_debt() -> void:
	var simulation = _stationary_melee_simulation(
		Vector2(0.20, 0.20),
		[Vector2(0.85, 0.85)],
		Vector2.RIGHT
	)
	var expected_steps := int(round(CombatSimulationScript.MAX_FRAME_DELTA / CombatSimulationScript.FIXED_STEP))
	for frame_index in range(4):
		var advanced: int = simulation.advance_frame(CombatSimulationScript.MAX_FRAME_DELTA)
		_require(advanced == expected_steps, "maximum accepted frame delta advanced %d of %d fixed steps on frame %d" % [advanced, expected_steps, frame_index])
		_require(absf(simulation.accumulator) <= TOLERANCE, "maximum accepted frame delta retained permanent accumulator debt on frame %d" % frame_index)
	_require(simulation.tick_index == expected_steps * 4, "repeated maximum frame deltas lost authoritative simulation time")


func _check_melee_circle_sector_boundaries() -> void:
	var body_radius := float(MonsterCatalogScript.definition(&"slime").get("body_radius", 0.0))
	var radial_inside = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.40 + CombatSimulationScript.PLAYER_ATTACK_RANGE + body_radius - 0.0001, 0.50)],
		Vector2.RIGHT
	)
	var hp_before := int(radial_inside.enemies[0].get("hp", 0))
	radial_inside.queue_player_attack()
	radial_inside.advance_ticks(8)
	_require(int(radial_inside.enemies[0].get("hp", 0)) < hp_before, "enemy body radius was not included at the radial attack boundary")

	var radial_outside = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.40 + CombatSimulationScript.PLAYER_ATTACK_RANGE + body_radius + 0.001, 0.50)],
		Vector2.RIGHT
	)
	hp_before = int(radial_outside.enemies[0].get("hp", 0))
	radial_outside.queue_player_attack()
	radial_outside.advance_ticks(8)
	_require(int(radial_outside.enemies[0].get("hp", 0)) == hp_before, "attack crossed the enemy-radius radial boundary")

	var half_angle := acos(CombatSimulationScript.PLAYER_ATTACK_CONE_DOT)
	var angular_inside = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.40, 0.50) + Vector2.from_angle(half_angle) * 0.18],
		Vector2.RIGHT
	)
	_set_enemy_body_radius(angular_inside, 0, 0.0)
	hp_before = int(angular_inside.enemies[0].get("hp", 0))
	angular_inside.queue_player_attack()
	angular_inside.advance_ticks(8)
	_require(int(angular_inside.enemies[0].get("hp", 0)) < hp_before, "exact cone boundary was excluded")

	var angular_outside = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.40, 0.50) + Vector2.from_angle(half_angle + deg_to_rad(1.0)) * 0.18],
		Vector2.RIGHT
	)
	_set_enemy_body_radius(angular_outside, 0, 0.0)
	hp_before = int(angular_outside.enemies[0].get("hp", 0))
	angular_outside.queue_player_attack()
	angular_outside.advance_ticks(8)
	_require(int(angular_outside.enemies[0].get("hp", 0)) == hp_before, "attack crossed the zero-radius angular boundary")

	var corner_direction := Vector2.from_angle(half_angle)
	var sector_corner := Vector2(0.40, 0.50) + corner_direction * CombatSimulationScript.PLAYER_ATTACK_RANGE
	var corner_outward := (corner_direction + corner_direction.rotated(PI * 0.5)).normalized()
	var corner_grazing = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[sector_corner + corner_outward * (body_radius - 0.0001)],
		Vector2.RIGHT
	)
	hp_before = int(corner_grazing.enemies[0].get("hp", 0))
	corner_grazing.queue_player_attack()
	corner_grazing.advance_ticks(8)
	_require(int(corner_grazing.enemies[0].get("hp", 0)) < hp_before, "enemy circle grazing the finite-sector corner was excluded")

	var corner_outside = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[sector_corner + corner_outward * (body_radius + 0.003)],
		Vector2.RIGHT
	)
	hp_before = int(corner_outside.enemies[0].get("hp", 0))
	corner_outside.queue_player_attack()
	corner_outside.advance_ticks(8)
	_require(int(corner_outside.enemies[0].get("hp", 0)) == hp_before, "independent radial and angular padding leaked past the finite-sector corner")


func _check_degenerate_circle_sector_semantics() -> void:
	var simulation = CombatSimulationScript.new()
	var origin := Vector2(0.40, 0.50)
	var facing := Vector2.RIGHT

	_require(
		simulation.call("_circle_intersects_attack_sector", origin, facing, 0.0, 1.0, origin, 0.0),
		"zero-range point sector excluded its origin"
	)
	_require(
		not simulation.call("_circle_intersects_attack_sector", origin, facing, 0.0, 1.0, origin + Vector2(0.02, 0.0), 0.0),
		"zero-range point sector included a separate point"
	)
	_require(
		simulation.call("_circle_intersects_attack_sector", origin, facing, 0.0, 1.0, origin + Vector2(0.20, 0.0), 0.20),
		"zero-range point sector excluded a target circle touching its origin"
	)
	_require(
		simulation.call("_circle_intersects_attack_sector", origin, facing, 0.0, 1.0, origin + Vector2(0.20, 0.0), 0.25),
		"target circle containing the attack origin was excluded"
	)
	_require(
		not simulation.call("_circle_intersects_attack_sector", origin, facing, 0.0, 1.0, origin + Vector2(0.20, 0.0), 0.19),
		"zero-range point sector included a target circle separated from its origin"
	)

	_require(
		simulation.call("_circle_intersects_attack_sector", origin, facing, 0.50, 1.0, origin + Vector2(0.50, 0.0), 0.0),
		"cone_dot=1 ray excluded its closed endpoint"
	)
	_require(
		not simulation.call("_circle_intersects_attack_sector", origin, facing, 0.50, 1.0, origin + Vector2(0.25, 0.02), 0.0),
		"cone_dot=1 ray included an off-ray point"
	)
	_require(
		simulation.call("_circle_intersects_attack_sector", origin, facing, 0.50, 1.0, origin + Vector2(0.25, 0.10), 0.10),
		"cone_dot=1 ray excluded a tangent target circle"
	)

	_require(
		simulation.call("_circle_intersects_attack_sector", origin, facing, 0.50, -1.0, origin + Vector2(-0.50, 0.0), 0.0),
		"cone_dot=-1 full circle excluded its rear radial boundary"
	)
	_require(
		simulation.call("_circle_intersects_attack_sector", origin, facing, 0.50, -1.0, origin + Vector2(0.0, 0.25), 0.0),
		"cone_dot=-1 full circle excluded a perpendicular interior point"
	)
	_require(
		not simulation.call("_circle_intersects_attack_sector", origin, facing, 0.50, -1.0, origin + Vector2(-0.52, 0.0), 0.0),
		"cone_dot=-1 full circle crossed its radial boundary"
	)

	_require(
		not simulation.call("_circle_intersects_attack_sector", origin, facing, -0.50, -1.0, origin + Vector2(0.02, 0.0), 0.0),
		"negative attack range was not normalized to zero"
	)
	_require(
		not simulation.call("_circle_intersects_attack_sector", origin, facing, 0.0, -1.0, origin + Vector2(0.02, 0.0), -0.50),
		"negative target radius was not normalized to zero"
	)


func _check_moving_and_multiple_targets() -> void:
	var enters = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.20, 0.50)],
		Vector2.RIGHT
	)
	var hp_before := int(enters.enemies[0].get("hp", 0))
	enters.queue_player_attack()
	enters.advance_ticks(1)
	_set_enemy_position(enters, 0, Vector2(0.58, 0.50))
	enters.advance_ticks(7)
	_require(int(enters.enemies[0].get("hp", 0)) < hp_before, "moving target that entered the frozen sector before active frames was not hit")

	var leaves = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.58, 0.50)],
		Vector2.RIGHT
	)
	hp_before = int(leaves.enemies[0].get("hp", 0))
	leaves.queue_player_attack()
	leaves.advance_ticks(1)
	_set_enemy_position(leaves, 0, Vector2(0.20, 0.50))
	leaves.advance_ticks(7)
	_require(int(leaves.enemies[0].get("hp", 0)) == hp_before, "moving target that left the frozen sector was still hit")

	var multiple = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.57, 0.46), Vector2(0.58, 0.54), Vector2(0.20, 0.50)],
		Vector2.RIGHT
	)
	multiple.queue_player_attack()
	multiple.advance_ticks(8)
	var resolved := _first_event(multiple.drain_events(), &"player_attack_resolved")
	var hit_ids: Array = resolved.get("hit_enemy_ids", [])
	_require(int(resolved.get("hit_count", 0)) == 2, "multi-target sector did not resolve exactly the two intersecting enemies")
	_require(String(multiple.enemies[0].get("enemy_id", "")) in hit_ids, "first intersecting enemy was absent from the multi-target result")
	_require(String(multiple.enemies[1].get("enemy_id", "")) in hit_ids, "second intersecting enemy was absent from the multi-target result")
	_require(String(multiple.enemies[2].get("enemy_id", "")) not in hit_ids, "enemy behind the player leaked into the multi-target result")


func _check_enemy_melee_warning_matches_hit_radius() -> void:
	var attack_radius := float(MonsterCatalogScript.definition(&"slime").get("attack_radius", 0.0))
	var hits = _stationary_melee_simulation(
		Vector2(0.50 + attack_radius, 0.50),
		[Vector2(0.50, 0.50)],
		Vector2.LEFT,
		false
	)
	hits.advance_ticks(1)
	var warning_snapshot: Dictionary = hits.build_snapshot().get("enemies", [])[0]
	_require(StringName(warning_snapshot.get("state", &"")) == &"warning", "enemy did not warn at its documented hit boundary")
	_require(is_equal_approx(float(warning_snapshot.get("warning_radius", -1.0)), attack_radius), "enemy snapshot warning radius differs from its hit radius")
	hits.advance_ticks(50)
	_require(int(hits.player.get("hp", 100)) < 100, "enemy failed to hit at the same radius that triggered its warning")
	var warning_event := _first_event(hits.drain_events(), &"melee_warning_started")
	_require(is_equal_approx(float(warning_event.get("radius", -1.0)), attack_radius), "warning event did not publish the authoritative hit radius")

	var misses = _stationary_melee_simulation(
		Vector2(0.50 + attack_radius, 0.50),
		[Vector2(0.50, 0.50)],
		Vector2.LEFT,
		false
	)
	misses.advance_ticks(1)
	misses.player["pos"] = Vector2(0.50 + attack_radius + 0.001, 0.50)
	misses.advance_ticks(50)
	_require(int(misses.player.get("hp", 100)) == 100, "enemy active frame exceeded the radius shown by its warning")


func _check_projectile_and_laser_geometry() -> void:
	var projectile_radius := CombatSimulationScript.PROJECTILE_RADIUS
	var actor = RuntimeActorViewScript.new()
	root.add_child(actor)
	actor.configure_projectile({
		"projectile_id": "i3r-geometry-projectile",
		"pos": Vector2(0.5, 0.5),
		"radius": projectile_radius,
		"visual_radius": projectile_radius,
		"state": &"active",
	})
	var polygon := actor.get_node("VisualRoot/ProgramPlaceholder") as Polygon2D
	var expected_pixels := RuntimeLayoutScript.local_size_to_world(Vector2(projectile_radius, projectile_radius)).x
	var rendered_radius := 0.0
	for point in polygon.polygon:
		rendered_radius = maxf(rendered_radius, absf(point.x))
	_require(is_equal_approx(rendered_radius, expected_pixels), "projectile presentation radius differs from its collision snapshot")
	actor.free()
	await process_frame

	var projectile_hit = _stationary_melee_simulation(
		Vector2(0.50, 0.50),
		[Vector2(0.85, 0.85)],
		Vector2.RIGHT
	)
	projectile_hit.projectiles.append({
		"projectile_id": "i3r-swept-hit",
		"owner_id": "fixture",
		"pos": Vector2(0.20, 0.50 + CombatSimulationScript.PLAYER_RADIUS + projectile_radius - 0.0001),
		"velocity": Vector2(30.0, 0.0),
		"radius": projectile_radius,
		"visual_radius": projectile_radius,
		"damage": 3,
		"state": &"active",
	})
	projectile_hit.advance_ticks(1)
	_require(int(projectile_hit.player.get("hp", 100)) == 97, "swept projectile missed at the visible circle-contact boundary")

	var projectile_miss = _stationary_melee_simulation(
		Vector2(0.50, 0.50),
		[Vector2(0.85, 0.85)],
		Vector2.RIGHT
	)
	projectile_miss.projectiles.append({
		"projectile_id": "i3r-swept-miss",
		"owner_id": "fixture",
		"pos": Vector2(0.20, 0.50 + CombatSimulationScript.PLAYER_RADIUS + projectile_radius + 0.001),
		"velocity": Vector2(30.0, 0.0),
		"radius": projectile_radius,
		"visual_radius": projectile_radius,
		"damage": 3,
		"state": &"active",
	})
	projectile_miss.advance_ticks(1)
	_require(int(projectile_miss.player.get("hp", 100)) == 100, "swept projectile crossed the visible circle-contact boundary")

	var laser_radius := CombatSimulationScript.LASER_RADIUS
	var laser_hit = _laser_fixture(CombatSimulationScript.PLAYER_RADIUS + laser_radius - 0.0001, 0.0)
	laser_hit.advance_ticks(1)
	_require(int(laser_hit.player.get("hp", 100)) == 92, "laser missed at the visible beam-contact boundary")
	var laser_snapshot: Dictionary = laser_hit.build_snapshot().get("lasers", [])[0]
	_require(is_equal_approx(float(laser_snapshot.get("visual_radius", -1.0)), float(laser_snapshot.get("radius", -2.0))), "laser visual radius differs from its collision radius")

	var laser_miss = _laser_fixture(CombatSimulationScript.PLAYER_RADIUS + laser_radius + 0.001, 0.0)
	laser_miss.advance_ticks(1)
	_require(int(laser_miss.player.get("hp", 100)) == 100, "laser crossed the visible beam-contact boundary")

	var room_view = RoomRuntimeViewScript.new()
	root.add_child(room_view)
	var draw_snapshot: Dictionary = laser_hit.build_snapshot()
	draw_snapshot["player_attack_geometry"] = {
		"attack_id": "i3r-draw-contract",
		"origin": Vector2(0.45, 0.50),
		"facing": Vector2.RIGHT,
		"range": CombatSimulationScript.PLAYER_ATTACK_RANGE,
		"half_angle_radians": acos(CombatSimulationScript.PLAYER_ATTACK_CONE_DOT),
		"phase": &"attack_active",
		"visible": true,
	}
	draw_snapshot["enemies"] = [{
		"enemy_id": "i3r-warning-contract",
		"monster_type": &"slime",
		"pos": Vector2(0.65, 0.50),
		"state": &"warning",
		"hp": 10,
		"max_hp": 10,
		"attack_radius": 0.20,
		"warning_radius": 0.20,
	}]
	room_view.apply_combat_snapshot(draw_snapshot)
	_require(bool(room_view.call("_has_visible_combat_geometry", draw_snapshot)), "runtime view ignored authoritative attack, warning, and laser geometry")
	await process_frame
	await process_frame
	room_view.free()
	await process_frame


func _check_bounded_laser_turn() -> void:
	var simulation = _laser_fixture(-0.30, 24.0)
	simulation.player["pos"] = Vector2(0.20, 0.20)
	var enemy: Dictionary = simulation.enemies[0]
	enemy["pos"] = Vector2(0.20, 0.50)
	simulation.enemies[0] = enemy
	var laser: Dictionary = simulation.lasers[0]
	laser["origin"] = Vector2(0.20, 0.50)
	laser["direction"] = Vector2.RIGHT
	laser["remaining"] = 5.0
	simulation.lasers[0] = laser
	simulation.advance_ticks(60)
	var direction := Vector2(simulation.lasers[0].get("direction", Vector2.ZERO))
	_require(absf(rad_to_deg(direction.angle()) + 24.0) <= 0.01, "laser turn rate was not bounded to 24 degrees per second")


func _check_production_arena_contract() -> void:
	var arena: Array[Rect2] = CombatSimulationScript.production_arena_obstacles()
	_require(arena.size() == 1, "production monster-room arena did not expose its finite visible altar obstacle")
	var room_view = RoomRuntimeViewScript.new()
	var view_obstacles: Array[Rect2] = room_view.call("_obstacles_for_room", &"Monster")
	_require(view_obstacles == arena, "monster-room presentation and combat simulation do not share one obstacle contract")
	room_view.free()

	var movement = _arena_simulation(Vector2(0.20, 0.50), Vector2(0.82, 0.50), &"slime")
	movement.set_player_input(Vector2.RIGHT, Vector2.RIGHT)
	movement.advance_ticks(180)
	var altar := arena[0]
	var expected_player_edge := altar.position.x - CombatSimulationScript.PLAYER_RADIUS
	_require(
		float((movement.player.get("pos", Vector2.ZERO) as Vector2).x) <= expected_player_edge + TOLERANCE,
		"player movement crossed the visible altar obstacle"
	)
	_require(
		not bool(movement.call(
			"_position_hits_obstacle",
			Vector2(movement.player.get("pos", Vector2.ZERO)),
			CombatSimulationScript.PLAYER_RADIUS
		)),
		"player collision resolution ended inside the visible altar"
	)

	var melee_navigation = _active_arena_melee_simulation()
	var melee_start := Vector2(melee_navigation.enemies[0].get("pos", Vector2.ZERO))
	melee_navigation.advance_ticks(120)
	var melee_tangent_progress := Vector2(melee_navigation.enemies[0].get("pos", Vector2.ZERO))
	_require(
		melee_tangent_progress.distance_to(melee_start) >= 0.12,
		"natural melee AI remained frozen against the opposite altar face"
	)
	_require(
		absf(melee_tangent_progress.y - melee_start.y) >= 0.08,
		"natural melee AI made no visible tangential progress around the altar"
	)
	melee_navigation.advance_ticks(240)
	var melee_end := Vector2(melee_navigation.enemies[0].get("pos", Vector2.ZERO))
	var melee_radius := float(melee_navigation.enemies[0].get("body_radius", 0.0))
	_require(
		melee_end.distance_to(Vector2(melee_navigation.player.get("pos", Vector2.ZERO))) <= 0.24,
		"natural melee AI did not complete its route around the altar: start=%s tangent=%s end=%s"
		% [melee_start, melee_tangent_progress, melee_end]
	)
	_require(
		not bool(melee_navigation.call("_position_hits_obstacle", melee_end, melee_radius)),
		"melee obstacle avoidance ended inside the visible altar"
	)
	_require(
		not bool(melee_navigation.call(
			"_line_occluded",
			melee_end,
			Vector2(melee_navigation.player.get("pos", Vector2.ZERO)),
			melee_radius
		)),
		"melee obstacle avoidance did not regain a clear path to the player: end=%s" % melee_end
	)
	var navigation_at_30 := _run_navigation_schedule([1.0 / 30.0])
	var navigation_at_60 := _run_navigation_schedule([1.0 / 60.0])
	var navigation_at_144 := _run_navigation_schedule([1.0 / 144.0])
	var navigation_with_hitch := _run_navigation_schedule([0.20, 1.0 / 60.0, 1.0 / 30.0, 1.0 / 144.0])
	for navigation_result in [navigation_at_30, navigation_at_144, navigation_with_hitch]:
		_require(
			navigation_result.get("state", {}) == navigation_at_60.get("state", {}),
			"outer-frame schedule changed the fixed-tick melee obstacle route"
		)
		_require(
			navigation_result.get("events", []) == navigation_at_60.get("events", []),
			"outer-frame schedule changed melee obstacle-route event order"
		)

	var blocked_attack = _arena_simulation(Vector2(0.285, 0.42), Vector2(0.42, 0.33), &"bat")
	var target: Dictionary = blocked_attack.enemies[0]
	target["state"] = &"hurt"
	target["state_timer"] = 999.0
	blocked_attack.enemies[0] = target
	var target_hp := int(target.get("hp", 0))
	var target_direction := Vector2(target.get("pos", Vector2.ZERO)) - Vector2(blocked_attack.player.get("pos", Vector2.ZERO))
	blocked_attack.set_player_input(Vector2.ZERO, target_direction)
	blocked_attack.queue_player_attack()
	blocked_attack.advance_ticks(1)
	var attack_geometry: Dictionary = blocked_attack.build_snapshot().get("player_attack_geometry", {})
	var visibility_samples: Array = attack_geometry.get("occlusion_samples", [])
	var visible_arc_points: Array = attack_geometry.get("visible_arc_points", [])
	_require(
		StringName(attack_geometry.get("occlusion_contract", &"")) == CombatSimulationScript.ARENA_CONTRACT_ID,
		"player attack visibility did not cite the authoritative arena obstacle contract"
	)
	_require(
		StringName(attack_geometry.get("visual_contract", &"")) == &"occlusion_clipped_sector_v1",
		"player attack snapshot omitted its clipped-sector visual contract"
	)
	_require(
		visibility_samples.size() == CombatSimulationScript.ATTACK_VISIBILITY_SEGMENTS + 1
		and visible_arc_points.size() == visibility_samples.size(),
		"player attack visibility samples were incomplete"
	)
	_require(
		int(attack_geometry.get("occluded_sample_count", 0)) > 0
		and bool(attack_geometry.get("occluded", false)),
		"altar-blocked attack did not expose clipped visual samples"
	)
	var center_sample: Dictionary = visibility_samples[visibility_samples.size() / 2]
	var center_full_endpoint := Vector2(center_sample.get("full_endpoint", Vector2.ZERO))
	var expected_hit_fraction := float(blocked_attack.call(
		"_first_obstacle_hit_fraction",
		Vector2(attack_geometry.get("origin", Vector2.ZERO)),
		center_full_endpoint,
		0.0
	))
	var expected_visible_endpoint := Vector2(attack_geometry.get("origin", Vector2.ZERO)).lerp(
		center_full_endpoint,
		clampf(expected_hit_fraction, 0.0, 1.0)
	)
	_require(bool(center_sample.get("occluded", false)), "altar did not clip the attack's center visual ray")
	_require(
		Vector2(center_sample.get("endpoint", Vector2.INF)).is_equal_approx(expected_visible_endpoint),
		"attack visual endpoint did not use the authoritative obstacle hit fraction"
	)
	_require(
		Vector2(center_sample.get("endpoint", Vector2.ZERO)).distance_to(Vector2(attack_geometry.get("origin", Vector2.ZERO)))
		< Vector2(center_sample.get("full_endpoint", Vector2.ZERO)).distance_to(Vector2(attack_geometry.get("origin", Vector2.ZERO))),
		"blocked visual sector still extended its center ray behind the altar"
	)
	var attack_view = RoomRuntimeViewScript.new()
	var presentation_arc: PackedVector2Array = attack_view.call("_player_attack_arc_world_points", attack_geometry)
	_require(
		presentation_arc.size() == visible_arc_points.size(),
		"room presentation discarded authoritative attack-visibility points"
	)
	for point_index in range(mini(presentation_arc.size(), visible_arc_points.size())):
		_require(
			presentation_arc[point_index].is_equal_approx(
				RuntimeActorViewScript.local_to_world(Vector2(visible_arc_points[point_index]))
			),
			"room presentation recomputed attack occlusion instead of consuming simulation geometry"
		)
	attack_view.free()
	blocked_attack.advance_ticks(7)
	var attack_event := _first_event(blocked_attack.drain_events(), &"player_attack_resolved")
	_require(int(blocked_attack.enemies[0].get("hp", 0)) == target_hp, "player sector damaged an enemy through the visible altar")
	_require(int(attack_event.get("hit_count", -1)) == 0, "occluded player attack reported a hit")
	_require(int(attack_event.get("blocked_count", 0)) == 1, "occluded player attack did not report its blocked target")

	var projectile_block = _arena_simulation(Vector2(0.80, 0.50), Vector2(0.20, 0.20), &"slime")
	projectile_block.projectiles.append({
		"projectile_id": "i3r-arena-projectile",
		"owner_id": "fixture",
		"pos": Vector2(0.20, 0.50),
		"velocity": Vector2(40.0, 0.0),
		"radius": CombatSimulationScript.PROJECTILE_RADIUS,
		"visual_radius": CombatSimulationScript.PROJECTILE_RADIUS,
		"damage": 7,
		"state": &"active",
	})
	projectile_block.advance_ticks(1)
	_require(int(projectile_block.player.get("hp", 100)) == 100, "projectile damaged the player through the visible altar")
	_require(projectile_block.projectiles.is_empty(), "projectile survived impact with the visible altar")
	_require(
		not _first_event(projectile_block.drain_events(), &"projectile_blocked").is_empty(),
		"projectile obstacle impact emitted no authoritative blocked event"
	)

	var laser_block = _arena_simulation(Vector2(0.80, 0.50), Vector2(0.20, 0.50), &"drone")
	var drone: Dictionary = laser_block.enemies[0]
	drone["state"] = &"fire"
	drone["state_timer"] = 999.0
	laser_block.enemies[0] = drone
	laser_block.lasers.append({
		"owner_id": String(drone.get("enemy_id", "")),
		"origin": Vector2(0.20, 0.50),
		"direction": Vector2.RIGHT,
		"remaining": 5.0,
		"tick_timer": 0.0,
		"tick_seconds": 0.30,
		"turn_speed_degrees": 0.0,
		"damage": 8,
		"radius": CombatSimulationScript.LASER_RADIUS,
		"visual_radius": CombatSimulationScript.LASER_RADIUS,
	})
	laser_block.advance_ticks(1)
	_require(int(laser_block.player.get("hp", 100)) == 100, "laser damaged the player through the visible altar")
	var laser_snapshot: Dictionary = laser_block.build_snapshot().get("lasers", [])[0]
	_require(bool(laser_snapshot.get("occluded", false)), "laser snapshot did not expose visible obstacle clipping")
	_require(
		float((laser_snapshot.get("endpoint", Vector2.ZERO) as Vector2).x) < altar.position.x,
		"laser presentation endpoint crossed the visible altar edge"
	)
	var arena_snapshot: Dictionary = laser_block.build_snapshot()
	_require(StringName(arena_snapshot.get("arena_contract", &"")) == CombatSimulationScript.ARENA_CONTRACT_ID, "combat snapshot omitted the arena authority id")
	_require((arena_snapshot.get("arena_obstacles", []) as Array) == arena, "combat snapshot obstacle geometry differs from the production view contract")


func _check_transition_attempt_gate() -> void:
	var direction := Vector2i.RIGHT
	_require(
		not RunSceneRouteControllerScript.transition_attempt_is_suppressed(direction, Vector2i.ZERO, 0.0, false),
		"first door transition attempt was suppressed"
	)
	_require(
		RunSceneRouteControllerScript.transition_attempt_is_suppressed(direction, direction, 0.35, true),
		"held direction did not suppress repeated door transition attempts"
	)
	_require(
		RunSceneRouteControllerScript.transition_attempt_is_suppressed(direction, direction, 0.20, false),
		"door transition cooldown did not suppress a released-but-immediate retry"
	)
	_require(
		RunSceneRouteControllerScript.transition_attempt_is_suppressed(direction, direction, 0.0, true),
		"held direction retried after cooldown without a release"
	)
	_require(
		not RunSceneRouteControllerScript.transition_attempt_is_suppressed(direction, direction, 0.0, false),
		"released direction remained suppressed after cooldown"
	)
	_require(
		not RunSceneRouteControllerScript.transition_attempt_is_suppressed(Vector2i.UP, direction, 0.35, true),
		"one rejected edge suppressed a different door direction"
	)
	var entry_simulation = CombatSimulationScript.new()
	entry_simulation.start({
		"seed": 313,
		"player_pos": Vector2(0.50, CombatSimulationScript.ROOM_MAX),
		"player_facing": Vector2.UP,
		"player_hp": 67,
		"player_max_hp": 100,
		"player_power": 9,
		"monster_types": [MonsterCatalogScript.TYPE_BAT],
		"arena_obstacles": CombatSimulationScript.production_arena_obstacles(),
	})
	var enemies_before: Array = entry_simulation.enemies.duplicate(true)
	var entry_landing := Vector2(0.50, 0.23)
	var entry_result: Dictionary = entry_simulation.place_player_from_room_entry(
		entry_landing,
		Vector2.DOWN
	)
	_require(bool(entry_result.get("applied", false)), "tick-zero combat entry placement was rejected")
	_require(
		Vector2(entry_simulation.player.get("pos", Vector2.ZERO)).is_equal_approx(entry_landing)
		and entry_simulation.previous_player_pos.is_equal_approx(entry_landing),
		"combat entry placement retained the old-room exit or an interpolation trail"
	)
	_require(
		Vector2(entry_simulation.player.get("velocity", Vector2.INF)).is_zero_approx()
		and Vector2(entry_simulation.player.get("facing", Vector2.ZERO)).is_equal_approx(Vector2.DOWN),
		"combat entry placement retained outbound motion or facing"
	)
	_require(
		int(entry_simulation.player.get("hp", 0)) == 67
		and int(entry_simulation.player.get("power", 0)) == 9
		and entry_simulation.enemies == enemies_before,
		"combat entry placement changed durable combat state or enemy state"
	)


func _check_outer_schedule_determinism() -> void:
	var at_30 := _run_attack_schedule([1.0 / 30.0])
	var at_60 := _run_attack_schedule([1.0 / 60.0])
	var at_144 := _run_attack_schedule([1.0 / 144.0])
	var with_hitch := _run_attack_schedule([0.20, 1.0 / 60.0, 1.0 / 30.0, 1.0 / 144.0])
	for result in [at_30, at_144, with_hitch]:
		_require(result.get("state", {}) == at_60.get("state", {}), "30/144/hitch schedule changed the authoritative attack state")
		_require(result.get("events", []) == at_60.get("events", []), "30/144/hitch schedule changed attack event order or geometry")


func _stationary_melee_simulation(
	player_pos: Vector2,
	enemy_positions: Array[Vector2],
	player_facing: Vector2,
	force_warning: bool = true
):
	var monster_types: Array[StringName] = []
	for _position in enemy_positions:
		monster_types.append(&"slime")
	var simulation = CombatSimulationScript.new()
	simulation.start({
		"seed": 31031,
		"player_pos": player_pos,
		"player_facing": player_facing,
		"player_hp": 100,
		"player_max_hp": 100,
		"player_power": 5,
		"monster_types": monster_types,
	})
	for index in range(enemy_positions.size()):
		var enemy: Dictionary = simulation.enemies[index]
		enemy["pos"] = enemy_positions[index]
		enemy["entry_grace_remaining"] = 0.0
		if force_warning:
			enemy["state"] = &"warning"
			enemy["state_timer"] = 999.0
		else:
			enemy["state"] = &"idle"
			enemy["state_timer"] = 0.0
		simulation.enemies[index] = enemy
	simulation.call("_capture_previous_transforms")
	return simulation


func _arena_simulation(player_pos: Vector2, enemy_pos: Vector2, enemy_type: StringName):
	var simulation = CombatSimulationScript.new()
	simulation.start({
		"seed": 17417,
		"player_pos": player_pos,
		"player_facing": Vector2.RIGHT,
		"player_hp": 100,
		"player_max_hp": 100,
		"player_power": 10,
		"monster_types": [enemy_type],
		"arena_obstacles": CombatSimulationScript.production_arena_obstacles(),
	})
	var enemy: Dictionary = simulation.enemies[0]
	enemy["pos"] = enemy_pos
	enemy["entry_grace_remaining"] = 0.0
	enemy["state"] = &"hurt"
	enemy["state_timer"] = 999.0
	simulation.enemies[0] = enemy
	simulation.call("_capture_previous_transforms")
	return simulation


func _active_arena_melee_simulation():
	var simulation = _arena_simulation(Vector2(0.20, 0.50), Vector2(0.82, 0.50), &"slime")
	var enemy: Dictionary = simulation.enemies[0]
	enemy["state"] = &"idle"
	enemy["state_timer"] = 0.0
	enemy["attack_done"] = false
	simulation.enemies[0] = enemy
	simulation.call("_capture_previous_transforms")
	return simulation


func _run_navigation_schedule(schedule: Array[float]) -> Dictionary:
	var simulation = _active_arena_melee_simulation()
	_advance_exact(simulation, schedule, 6.0)
	return {
		"state": simulation.build_canonical_snapshot(),
		"events": simulation.drain_events(),
	}


func _laser_fixture(player_y_offset: float, turn_speed_degrees: float):
	var simulation = CombatSimulationScript.new()
	simulation.start({
		"seed": 9301,
		"player_pos": Vector2(0.50, 0.50 + player_y_offset),
		"player_facing": Vector2.LEFT,
		"player_hp": 100,
		"player_max_hp": 100,
		"monster_types": [&"drone"],
	})
	var enemy: Dictionary = simulation.enemies[0]
	enemy["pos"] = Vector2(0.20, 0.50)
	enemy["entry_grace_remaining"] = 0.0
	enemy["state"] = &"fire"
	enemy["state_timer"] = 999.0
	simulation.enemies[0] = enemy
	simulation.lasers.clear()
	simulation.lasers.append({
		"owner_id": String(enemy.get("enemy_id", "")),
		"origin": Vector2(0.20, 0.50),
		"direction": Vector2.RIGHT,
		"remaining": 5.0,
		"tick_timer": 0.0,
		"tick_seconds": 0.30,
		"turn_speed_degrees": turn_speed_degrees,
		"damage": 8,
		"radius": CombatSimulationScript.LASER_RADIUS,
		"visual_radius": CombatSimulationScript.LASER_RADIUS,
	})
	simulation.call("_capture_previous_transforms")
	return simulation


func _run_attack_schedule(schedule: Array[float]) -> Dictionary:
	var simulation = _stationary_melee_simulation(
		Vector2(0.40, 0.50),
		[Vector2(0.60, 0.50)],
		Vector2.RIGHT
	)
	simulation.set_player_input(Vector2.LEFT, Vector2.LEFT)
	simulation.queue_player_attack()
	_advance_exact(simulation, schedule, 1.20)
	return {
		"state": simulation.build_canonical_snapshot(),
		"events": simulation.drain_events(),
	}


func _advance_exact(simulation, schedule: Array[float], seconds: float) -> void:
	var remaining := seconds
	var schedule_index := 0
	while remaining > 0.00000001:
		var frame_delta := minf(schedule[schedule_index % schedule.size()], remaining)
		simulation.advance_frame(frame_delta)
		remaining -= frame_delta
		schedule_index += 1


func _set_enemy_position(simulation, enemy_index: int, position: Vector2) -> void:
	var enemy: Dictionary = simulation.enemies[enemy_index]
	enemy["pos"] = position
	simulation.enemies[enemy_index] = enemy


func _set_enemy_body_radius(simulation, enemy_index: int, radius: float) -> void:
	var enemy: Dictionary = simulation.enemies[enemy_index]
	enemy["body_radius"] = radius
	simulation.enemies[enemy_index] = enemy


func _event_count(events: Array, event_type: StringName) -> int:
	var count := 0
	for event in events:
		if event is Dictionary and StringName((event as Dictionary).get("event_type", &"")) == event_type:
			count += 1
	return count


func _first_event(events: Array, event_type: StringName) -> Dictionary:
	for event in events:
		if event is Dictionary and StringName((event as Dictionary).get("event_type", &"")) == event_type:
			return event as Dictionary
	return {}


func _capture_feedback_cue(cue_id: StringName, event_id: String, metadata: Dictionary) -> void:
	captured_feedback_cues.append({
		"cue_id": cue_id,
		"event_id": event_id,
		"metadata": metadata.duplicate(true),
	})


func _capture_command_feedback(result: Dictionary) -> void:
	captured_command_feedback.append(result.duplicate(true))


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("%s encounter=single_mother_stable power=mine_linked hp_damage=profiled split=0.45 arrival=0.45s melee_cadence=1.10,0.75,0.28,0.55 buffer=late_only interruption=explicit phases=ordered active_hit=impact_aligned settlement=once attack=frozen windup_active=locked recovery=mobile visual=authoritative feedback=perceptible hurt=timed max_delta=debt_free circle_sector=radius_aware enemy_warning=exact projectile=swept_visible laser=bounded_visible schedules=30,60,144,hitch" % PASS_MARKER)
		print("I3R_COMBAT_ARENA_CONTRACT=PASS authority=shared movement=blocked melee_navigation=deterministic attack=occluded_visual_clipped projectile=blocked laser=clipped")
		print("I3R_TRANSITION_ATTEMPT_GATE=PASS held=suppressed cooldown=suppressed release=required")
		quit(0)
		return
	for failure in failures:
		printerr("I3R_COMBAT_ATTACK_FAILURE %s" % failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
