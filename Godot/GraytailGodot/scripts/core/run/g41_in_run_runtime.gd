extends RefCounted
class_name G41InRunRuntime

const CombatSimulationScript := preload("res://scripts/gameplay/combat/g41_combat_simulation.gd")
const DeterministicRngScript := preload("res://scripts/gameplay/combat/g41_deterministic_rng.gd")
const MonsterCatalogScript := preload("res://scripts/gameplay/combat/g41_monster_catalog.gd")

var runtime_controller
var context: RunContext
var command_bus: CommandBus
var simulation: G41CombatSimulation
var current_room_key: String = ""
var encounter_ordinals: Dictionary = {}
var recent_domain_events: Array[Dictionary] = []
var paused: bool = false
var flee_authorized: bool = false


func bind(next_runtime_controller) -> void:
	runtime_controller = next_runtime_controller
	context = null if runtime_controller == null else runtime_controller.context
	command_bus = null if runtime_controller == null else runtime_controller.command_bus


func reset() -> void:
	simulation = null
	current_room_key = ""
	encounter_ordinals.clear()
	recent_domain_events.clear()
	paused = false
	flee_authorized = false


func sync_room(player_local_pos: Vector2) -> void:
	if context == null or not context.run_active or context.truth_map == null:
		reset()
		return
	var next_room_key := context.cell_key(context.get_current_pos())
	if next_room_key != current_room_key:
		simulation = null
		current_room_key = next_room_key
		flee_authorized = false
	if context.current_room_type != &"Monster" or context.truth_map.is_cleared(context.get_current_pos()):
		simulation = null
		return
	# A successful explicit flee ends this room's simulation before the room
	# transition is committed.  Keep that authorization stable until the
	# authoritative room key changes so a failed transition cannot restart the
	# encounter or charge the flee cost a second time.
	if flee_authorized:
		simulation = null
		return
	if simulation == null:
		_start_current_encounter(player_local_pos)
	elif simulation.active:
		simulation.sync_player_durable_stats(context.hp, context.max_hp, context.power)


func set_paused(next_paused: bool) -> void:
	paused = next_paused
	if simulation != null:
		simulation.set_paused(next_paused)


func advance_frame(delta: float, move_input: Vector2, aim_input: Vector2) -> Dictionary:
	if simulation == null:
		return build_read_only_snapshot()
	simulation.set_paused(paused)
	simulation.set_player_input(move_input, aim_input)
	simulation.advance_frame(delta)
	_consume_domain_events(simulation.drain_events())
	if context == null or not context.run_active:
		reset()
	return build_read_only_snapshot()


func request_attack(requested_facing: Vector2 = Vector2.ZERO) -> Dictionary:
	if simulation == null or not simulation.active:
		return {"ok": false, "reason": &"combat_not_active"}
	var player_state := StringName(simulation.player.get("state", &"idle"))
	var cooldown_before := float(simulation.player.get("attack_cooldown", 0.0))
	var immediate := player_state in [&"idle", &"move"] and cooldown_before <= simulation.EPSILON
	var buffer_window_open := (
		cooldown_before > simulation.EPSILON
		and cooldown_before <= simulation.PLAYER_ATTACK_BUFFER_SECONDS + simulation.EPSILON
	)
	var queued := simulation.queue_player_attack(requested_facing)
	var status := &"attack_blocked"
	if queued:
		status = &"attack_queued" if immediate else &"attack_buffered"
	elif (
		player_state not in [&"hurt", &"dead"]
		and cooldown_before > simulation.PLAYER_ATTACK_BUFFER_SECONDS + simulation.EPSILON
	):
		status = &"attack_cooling_down"
	return {
		"ok": queued,
		"status": status,
		"retry_after_seconds": maxf(0.0, cooldown_before - simulation.PLAYER_ATTACK_BUFFER_SECONDS),
		"buffer_window_open": buffer_window_open,
		"authority": &"G41CombatSimulation",
	}


func request_flee() -> Dictionary:
	if simulation == null or not simulation.active or command_bus == null:
		return {"ok": false, "reason": &"combat_not_active"}
	var result: Dictionary = command_bus.dispatch(&"flee_runtime_combat", {
		"source": "g41_in_run_runtime",
		"combat_tick": simulation.tick_index,
		"combat_seed": simulation.encounter_seed,
	})
	if bool(result.get("ok", false)):
		flee_authorized = true
		simulation = null
	return result


func has_active_combat() -> bool:
	return simulation != null and simulation.active


func is_door_locked() -> bool:
	return has_active_combat() and not flee_authorized


func get_player_local_position(fallback: Vector2) -> Vector2:
	if simulation == null:
		return fallback
	return Vector2(simulation.player.get("pos", fallback))


func place_player_from_room_entry(player_local_pos: Vector2, entry_direction: Vector2i) -> Dictionary:
	if simulation == null or not simulation.active:
		return {
			"applied": false,
			"reason": &"combat_not_active",
			"position": player_local_pos,
		}
	return simulation.place_player_from_room_entry(
		player_local_pos,
		Vector2(entry_direction)
	)


func build_read_only_snapshot() -> Dictionary:
	var combat: Dictionary = {
		"active": false,
		"paused": paused,
		"cleared": false,
		"defeated": false,
		"player": {},
		"enemies": [],
		"projectiles": [],
		"lasers": [],
	}
	if simulation != null:
		combat = simulation.build_snapshot()
	combat["room_key"] = current_room_key
	combat["door_locked"] = is_door_locked()
	combat["flee_authorized"] = flee_authorized
	combat["authority"] = &"G41CombatSimulation"
	combat["fixed_hz"] = 60
	combat["recent_events"] = recent_domain_events.duplicate(true)
	return combat


func _start_current_encounter(player_local_pos: Vector2) -> void:
	var ordinal := int(encounter_ordinals.get(current_room_key, 0)) + 1
	encounter_ordinals[current_room_key] = ordinal
	var room_pos := context.get_current_pos()
	var seed := DeterministicRngScript.derive_seed(context.seed_value, room_pos, ordinal)
	var monster_types := _encounter_types(
		context.seed_value,
		room_pos,
		context.current_adjacent_mines
	)
	var identity := CombatState.build_enemy_state(
		context,
		room_pos,
		context.current_adjacent_mines
	)
	var mother_profile := MonsterCatalogScript.runtime_profile(
		monster_types[0],
		int(identity.get("enemy_power", 0)),
		String(identity.get("enemy_name", "异常体"))
	)
	mother_profile.merge(identity, true)
	context.enemy_state = mother_profile.duplicate(true)
	simulation = CombatSimulationScript.new() as G41CombatSimulation
	simulation.start({
		"seed": seed,
		"player_pos": player_local_pos,
		"player_facing": Vector2.RIGHT,
		"player_hp": context.hp,
		"player_max_hp": context.max_hp,
		"player_power": context.power,
		"monster_types": monster_types,
		"enemy_profiles": [mother_profile],
		"arena_obstacles": CombatSimulationScript.production_arena_obstacles(),
	})
	simulation.set_paused(paused)
	_consume_domain_events(simulation.drain_events())


func _encounter_types(
	run_seed: int,
	room_pos: Vector2i = Vector2i.ZERO,
	adjacent_mines: int = 0
) -> Array[StringName]:
	return [MonsterCatalogScript.pick_type_for_cell(run_seed, room_pos, adjacent_mines)]


func _consume_domain_events(events: Array[Dictionary]) -> void:
	for event in events:
		var event_copy := event.duplicate(true)
		recent_domain_events.append(event_copy)
		if recent_domain_events.size() > 32:
			recent_domain_events.pop_front()
		match StringName(event.get("event_type", &"")):
			&"player_damaged":
				_commit_damage_event(event)
			&"combat_cleared":
				_commit_combat_cleared(event)
			&"player_defeated":
				_commit_player_defeated(event)


func _commit_damage_event(event: Dictionary) -> void:
	if command_bus == null:
		return
	command_bus.dispatch(&"apply_runtime_combat_damage", {
		"source": "g41_combat_simulation",
		"damage": int(event.get("damage", 0)),
		"damage_kind": StringName(event.get("damage_kind", &"combat")),
		"source_id": String(event.get("source_id", "")),
		"combat_tick": int(event.get("tick", 0)),
	})


func _commit_combat_cleared(event: Dictionary) -> void:
	var completed_simulation := simulation
	if command_bus == null or completed_simulation == null or completed_simulation.reward_emitted:
		return
	var result: Dictionary = command_bus.dispatch(&"resolve_runtime_combat", {
		"source": "g41_combat_simulation",
		"combat_tick": int(event.get("tick", completed_simulation.tick_index)),
		"combat_seed": completed_simulation.encounter_seed,
		"combat_snapshot": completed_simulation.build_snapshot(),
	})
	if bool(result.get("ok", false)):
		# Resolving the room synchronously refreshes the run context and may clear
		# the runtime's current simulation. Commit against the encounter that
		# emitted the event instead of dereferencing the refreshed field.
		completed_simulation.mark_reward_committed()


func _commit_player_defeated(event: Dictionary) -> void:
	if context == null or context.failed or command_bus == null:
		return
	# Damage is committed first. This fallback covers zero-HP projections that
	# were already synchronized by another authoritative effect.
	command_bus.dispatch(&"resolve_runtime_combat_defeat", {
		"source": "g41_combat_simulation",
		"combat_tick": int(event.get("tick", 0)),
	})
