extends RefCounted
class_name G41InRunRuntime

const CombatSimulationScript := preload("res://scripts/gameplay/combat/g41_combat_simulation.gd")
const DeterministicRngScript := preload("res://scripts/gameplay/combat/g41_deterministic_rng.gd")

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


func request_attack() -> Dictionary:
	if simulation == null or not simulation.active:
		return {"ok": false, "reason": &"combat_not_active"}
	var queued := simulation.queue_player_attack()
	return {
		"ok": queued,
		"status": &"attack_queued" if queued else &"attack_blocked",
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
	simulation = CombatSimulationScript.new() as G41CombatSimulation
	simulation.start({
		"seed": seed,
		"player_pos": player_local_pos,
		"player_facing": Vector2.RIGHT,
		"player_hp": context.hp,
		"player_max_hp": context.max_hp,
		"player_power": context.power,
		"monster_types": _encounter_types(seed),
	})
	simulation.set_paused(paused)
	_consume_domain_events(simulation.drain_events())


func _encounter_types(seed: int) -> Array[StringName]:
	match absi(seed) % 4:
		0:
			return [&"slime"]
		1:
			return [&"slime", &"bat"]
		2:
			return [&"bat", &"drone"]
		_:
			return [&"slime", &"bat", &"drone"]


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
	if command_bus == null or simulation == null or simulation.reward_emitted:
		return
	var result: Dictionary = command_bus.dispatch(&"resolve_runtime_combat", {
		"source": "g41_combat_simulation",
		"combat_tick": int(event.get("tick", simulation.tick_index)),
		"combat_seed": simulation.encounter_seed,
		"combat_snapshot": simulation.build_snapshot(),
	})
	if bool(result.get("ok", false)):
		simulation.mark_reward_committed()


func _commit_player_defeated(event: Dictionary) -> void:
	if context == null or context.failed or command_bus == null:
		return
	# Damage is committed first. This fallback covers zero-HP projections that
	# were already synchronized by another authoritative effect.
	command_bus.dispatch(&"resolve_runtime_combat_defeat", {
		"source": "g41_combat_simulation",
		"combat_tick": int(event.get("tick", 0)),
	})
