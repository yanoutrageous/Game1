extends RefCounted
class_name RoomResolver

# Room behavior goes through RoomResolver. UI reads emitted snapshots only.
# G6 replaces the G4 text "Event placeholder resolved" with EventService outcomes.

const RunStateMachineScript := preload("res://scripts/core/run/run_state_machine.gd")
const RunBalanceCatalogScript := preload("res://scripts/core/run/run_balance_catalog.gd")
const RunEffectApplierScript := preload("res://scripts/core/run/run_effect_applier.gd")
const RunTextCatalogScript := preload("res://scripts/core/run/run_text_catalog.gd")

var runtime_controller


func bind_runtime_controller(next_controller) -> void:
	runtime_controller = next_controller


func resolve_entry(_room_id: StringName, _context: Variant = null) -> Dictionary:
	return {}


func enter_room(context: RunContext) -> Dictionary:
	if context == null or context.truth_map == null or context.intel_map == null:
		return {"ok": false, "message": "No active run."}

	var pos := context.get_current_pos()
	if context.reveal_on_move:
		context.intel_map.reveal_cell(pos, context.truth_map)
	context.truth_map.mark_explored(pos)
	context.current_room_type = context.truth_map.get_room_type(pos)
	context.current_adjacent_mines = context.minefield_service.count_adjacent_mines(context.truth_map, pos)
	context.exit_id = context.truth_map.get_exit_id(pos)
	context.visited_cells[context.cell_key(pos)] = true
	context.event_state = {}
	context.enemy_state = {}
	context.blocked_reason = ""
	var encounter := RunRuleService.encounter_for_room(context, context.current_room_type, pos)
	context.encounter_type = StringName(encounter.get("encounter_type", &"none"))
	context.encounter_tags = encounter.get("encounter_tags", []).duplicate(true)
	_record_room_event(context, RunEventLog.EVENT_ROOM_ENTERED, {"position": pos, "room_type": context.current_room_type, "encounter_type": context.encounter_type})

	var first_explore := not context.explored_cells.has(context.cell_key(pos))
	if first_explore:
		RunEffectApplierScript.apply_effects(context, [
			RunEffectApplierScript.effect_room_mark_explored(pos),
			RunEffectApplierScript.effect_protocol_pressure_delta(RunBalanceCatalogScript.EXPLORE_PRESSURE_DELTA, "room_explore"),
		], runtime_controller)

	if context.current_room_type == &"Mine":
		var mine_result := _enter_mine(context, pos)
		_maybe_trigger_tutorial(context, pos)
		return mine_result

	if context.current_room_type == &"Exit":
		_record_room_event(context, RunEventLog.EVENT_EXTRACTION_FOUND, {"position": pos, "exit_id": context.exit_id})
		context.last_message = RunTextCatalogScript.exit_ready()
	elif context.current_room_type == &"Monster" and not context.truth_map.is_cleared(pos):
		context.enemy_state = CombatState.build_enemy_state(context, pos, context.current_adjacent_mines)
		context.last_message = RunTextCatalogScript.monster_available()
	elif context.current_room_type == &"Event" and not context.interacted_cells.has(context.cell_key(pos)):
		context.event_state = EventService.get_event_state(context, pos)
		context.last_message = RunTextCatalogScript.event_available(context.event_state.get("event_type", &"event"))
	elif context.current_room_type == &"Chest" and not context.searched_cells.has(context.cell_key(pos)):
		context.last_message = RunTextCatalogScript.chest_searchable()
	else:
		context.last_message = RunTextCatalogScript.entered_room(context.current_room_type, context.current_adjacent_mines)
	_maybe_trigger_tutorial(context, pos)
	return {"ok": true, "message": context.last_message}


func search_current_room(context: RunContext) -> Dictionary:
	if context == null or not context.run_active:
		return {"ok": false, "reason": "run_not_active", "blocked_reason": "run_not_active", "message": "Run is not active."}
	var pos := context.get_current_pos()
	var key := context.cell_key(pos)
	if context.searched_cells.has(key):
		context.last_message = "This room was already searched."
		return {"ok": true, "message": context.last_message}
	if not context.intel_map.is_revealed(pos):
		context.last_message = "Cannot search unrevealed room."
		return {"ok": false, "reason": "room_unrevealed", "blocked_reason": "room_unrevealed", "message": context.last_message}
	if not (context.current_room_type in [&"Normal", &"Chest"]):
		context.last_message = "This room cannot be searched."
		return {"ok": false, "reason": "room_not_searchable", "blocked_reason": "room_not_searchable", "message": context.last_message}
	if pos == context.truth_map.spawn_pos:
		context.last_message = "Spawn cannot be searched."
		return {"ok": false, "reason": "spawn_not_searchable", "blocked_reason": "spawn_not_searchable", "message": context.last_message}

	var is_chest := context.current_room_type == &"Chest"
	var reward := RunInventory.add_search_reward(context, pos, context.current_adjacent_mines, is_chest)
	context.searched_cells[key] = true
	context.last_reward = reward
	context.blocked_reason = String(reward.get("blocked_reason", ""))
	if is_chest:
		context.truth_map.mark_cleared(pos)
	context.intel_map.refresh_revealed_cell(pos, context.truth_map)
	_record_room_event(context, RunEventLog.EVENT_ROOM_SEARCHED, {"position": pos, "is_chest": is_chest, "reward": reward.duplicate(true)})
	var reward_items: Array = reward.get("items", [])
	var floor_items: Array = reward.get("ground_items", [])
	context.last_message = RunTextCatalogScript.search_complete(int(reward.get("gold", 0)), reward_items.size(), floor_items.size(), context.blocked_reason)
	return {"ok": true, "message": context.last_message}


func interact_current_room(context: RunContext) -> Dictionary:
	if context == null or not context.run_active:
		return {"ok": false, "reason": "run_not_active", "blocked_reason": "run_not_active", "message": "Run is not active."}
	var pos := context.get_current_pos()
	var key := context.cell_key(pos)
	match context.current_room_type:
		&"Chest":
			return search_current_room(context)
		&"Normal":
			return search_current_room(context)
		&"Event":
			var result := EventService.execute_default(context, pos, runtime_controller)
			if bool(result.get("completed", false)):
				context.truth_map.mark_cleared(pos)
				context.intel_map.refresh_revealed_cell(pos, context.truth_map)
			return result
		&"Monster":
			context.last_message = "Monster requires fight command."
		&"Exit":
			context.last_message = "Exit ready. Request extraction."
		&"Mine":
			context.last_message = "Mine room has no safe interaction."
		_:
			context.last_message = "Nothing to interact with here."
	return {"ok": true, "message": context.last_message}


func select_event_option(context: RunContext, option_id: StringName) -> Dictionary:
	if context == null or not context.run_active:
		return {"ok": false, "reason": "run_not_active", "blocked_reason": "run_not_active", "message": "Run is not active."}
	var pos := context.get_current_pos()
	if context.current_room_type != &"Event":
		context.last_message = "No event option is available here."
		return {"ok": false, "reason": "event_option_unavailable", "blocked_reason": "event_option_unavailable", "message": context.last_message}
	var event_type := EventService.get_event_type(context, pos)
	var result := EventService.execute_option(context, pos, option_id, runtime_controller)
	_record_room_event(context, RunEventLog.EVENT_EVENT_OPTION_SELECTED, {"position": pos, "event_type": event_type, "option_id": option_id, "result": result.duplicate(true)})
	if bool(result.get("completed", false)):
		context.truth_map.mark_cleared(pos)
		context.intel_map.refresh_revealed_cell(pos, context.truth_map)
	if context.failed:
		return result
	return result


func fight_current_enemy(context: RunContext) -> Dictionary:
	if context == null or not context.run_active:
		return {"ok": false, "reason": "run_not_active", "blocked_reason": "run_not_active", "message": "Run is not active."}
	var pos := context.get_current_pos()
	if context.current_room_type != &"Monster":
		context.last_message = "No monster to fight here."
		return {"ok": false, "reason": "combat_unavailable", "blocked_reason": "combat_unavailable", "message": context.last_message}
	if context.truth_map.is_cleared(pos):
		context.last_message = "Monster already cleared."
		return {"ok": true, "message": context.last_message}
	var result := CombatState.fight_enemy(context, pos, context.current_adjacent_mines, runtime_controller)
	if bool(result.get("cleared", false)):
		context.truth_map.mark_cleared(pos)
		context.intel_map.refresh_revealed_cell(pos, context.truth_map)
	context.last_reward = result
	context.blocked_reason = String(result.get("blocked_reason", ""))
	context.enemy_state = result.duplicate(true)
	context.last_message = RunTextCatalogScript.monster_cleared(int(result.get("damage", 0)), int(result.get("reward_gold", 0)))
	_record_room_event(context, RunEventLog.EVENT_COMBAT_RESOLVED, {"position": pos, "result": result.duplicate(true)})
	return result


func apply_runtime_combat_damage(context: RunContext, payload: Dictionary) -> Dictionary:
	if context == null or not context.run_active:
		return {"ok": false, "reason": "run_not_active", "blocked_reason": "run_not_active"}
	if context.current_room_type != &"Monster" or context.truth_map == null or context.truth_map.is_cleared(context.get_current_pos()):
		return {"ok": false, "reason": "runtime_combat_unavailable", "blocked_reason": "runtime_combat_unavailable"}
	var damage := maxi(0, int(payload.get("damage", 0)))
	if damage <= 0:
		return {"ok": true, "status": &"runtime_combat_damage_ignored", "damage": 0, "hp": context.hp}
	var applied := RunEffectApplierScript.apply_effects(context, [
		RunEffectApplierScript.effect_hp_delta(-damage, "runtime_combat_%s" % String(payload.get("damage_kind", &"damage"))),
	], runtime_controller)
	context.run_stats["combat_damage"] = int(context.run_stats.get("combat_damage", 0)) + damage
	context.enemy_state["runtime_combat_tick"] = int(payload.get("combat_tick", 0))
	context.last_message = "Combat hit: -%d HP." % damage
	_record_room_event(context, &"runtime_combat_damage", {
		"position": context.get_current_pos(),
		"damage": damage,
		"damage_kind": payload.get("damage_kind", &"damage"),
		"source_id": payload.get("source_id", ""),
		"combat_tick": payload.get("combat_tick", 0),
	})
	return {
		"ok": bool(applied.get("ok", false)),
		"status": &"runtime_combat_damage_applied",
		"damage": damage,
		"hp": context.hp,
		"failed": context.failed,
		"effect_results": applied.get("effect_results", []),
	}


func resolve_runtime_combat(context: RunContext, payload: Dictionary) -> Dictionary:
	if context == null or not context.run_active:
		return {"ok": false, "reason": "run_not_active", "blocked_reason": "run_not_active"}
	var pos := context.get_current_pos()
	if context.current_room_type != &"Monster" or context.truth_map == null:
		return {"ok": false, "reason": "runtime_combat_unavailable", "blocked_reason": "runtime_combat_unavailable"}
	if context.truth_map.is_cleared(pos):
		return {"ok": true, "status": &"runtime_combat_already_resolved", "reward_committed": false}
	var combat_snapshot: Dictionary = payload.get("combat_snapshot", {})
	if not bool(combat_snapshot.get("cleared", false)):
		return {"ok": false, "reason": "combat_not_cleared", "blocked_reason": "combat_not_cleared"}
	var reward_gold := CombatState.preview_reward_gold(context, pos)
	var reward_result := RunRuleService.apply_combat_reward(context, pos, reward_gold)
	RunEffectApplierScript.apply_effects(context, [RunEffectApplierScript.effect(RunEffectApplierScript.EFFECT_MONSTER_MARK_DEFEATED, "runtime_combat_cleared", {"position": pos}, pos)], runtime_controller)
	context.last_reward = reward_result.duplicate(true)
	context.blocked_reason = String(reward_result.get("blocked_reason", ""))
	context.enemy_state = combat_snapshot.duplicate(true)
	context.enemy_state["reward_committed"] = true
	context.enemy_state["combat_seed"] = int(payload.get("combat_seed", 0))
	context.last_message = RunTextCatalogScript.monster_cleared(0, reward_gold)
	var monster_types: Array[String] = []
	for raw_enemy in combat_snapshot.get("enemies", []):
		var enemy: Dictionary = raw_enemy if raw_enemy is Dictionary else {}
		var monster_type := str(enemy.get("monster_type", ""))
		if monster_type != "" and not monster_types.has(monster_type):
			monster_types.append(monster_type)
	_record_room_event(context, RunEventLog.EVENT_COMBAT_RESOLVED, {
		"position": pos,
		"runtime": true,
		"combat_tick": payload.get("combat_tick", 0),
		"combat_seed": payload.get("combat_seed", 0),
		"monster_types": monster_types,
		"reward": reward_result.duplicate(true),
	})
	return {
		"ok": true,
		"status": &"runtime_combat_resolved",
		"reward_committed": true,
		"reward_gold": reward_gold,
		"reward": reward_result,
		"ground_items": reward_result.get("ground_items", []),
	}


func resolve_runtime_combat_defeat(context: RunContext, payload: Dictionary) -> Dictionary:
	if context == null:
		return {"ok": false, "reason": "run_not_active"}
	if context.failed:
		return {"ok": true, "status": &"runtime_combat_defeat_already_resolved"}
	context.hp = 0
	var result := _fail_run(context, "runtime_combat_defeat")
	result["combat_tick"] = int(payload.get("combat_tick", 0))
	return result


func flee_runtime_combat(context: RunContext, _payload: Dictionary = {}) -> Dictionary:
	if context == null or not context.run_active:
		return {"ok": false, "reason": "run_not_active", "blocked_reason": "run_not_active"}
	var pos := context.get_current_pos()
	if context.current_room_type != &"Monster" or context.truth_map == null or context.truth_map.is_cleared(pos):
		return {"ok": false, "reason": "runtime_combat_unavailable", "blocked_reason": "runtime_combat_unavailable"}
	var result := RunRuleService.apply_combat_flee(context, pos)
	context.last_reward = result.duplicate(true)
	context.blocked_reason = String(result.get("blocked_reason", ""))
	context.enemy_state = {"fled": true, "room_uncleared": true}
	context.last_message = "Fled combat: lost %d pending black coin; %d item(s) left on this room floor." % [
		int(result.get("black_coin_loss", 0)),
		int(result.get("items_moved_to_room_floor", 0)),
	]
	_record_room_event(context, &"runtime_combat_fled", {
		"position": pos,
		"black_coin_loss": result.get("black_coin_loss", 0),
		"dropped_instance_ids": result.get("dropped_instance_ids", []),
	})
	return result


func can_extract(context: RunContext) -> bool:
	if context == null or context.truth_map == null:
		return false
	return context.current_room_type == &"Exit" and context.truth_map.get_exit_id(context.get_current_pos()) != &""


func _enter_mine(context: RunContext, pos: Vector2i) -> Dictionary:
	var key := context.cell_key(pos)
	if not context.entered_cells.has(key):
		context.entered_cells[key] = true
		RunEffectApplierScript.apply_effects(context, [RunEffectApplierScript.effect_mine_mark_triggered(pos)], runtime_controller)
		var damage := CombatState.take_mine_hit(context, runtime_controller)
		RunEffectApplierScript.apply_effects(context, [RunEffectApplierScript.effect_protocol_pressure_delta(RunBalanceCatalogScript.MINE_PRESSURE_DELTA, "mine_triggered")], runtime_controller)
		context.run_stats["mine_hits"] = int(context.run_stats.get("mine_hits", 0)) + 1
		context.intel_map.refresh_revealed_cell(pos, context.truth_map)
		context.last_message = RunTextCatalogScript.mine_triggered(damage, RunBalanceCatalogScript.MINE_PRESSURE_DELTA)
		if context.mine_hits_are_fatal and not context.failed:
			_fail_run(context, "fatal_mine")
	else:
		context.last_message = RunTextCatalogScript.mine_reentered()
	return {"ok": true, "message": context.last_message}


func _maybe_trigger_tutorial(context: RunContext, pos: Vector2i) -> void:
	var trigger_id := TutorialService.trigger_for(context, pos)
	if trigger_id != &"":
		context.last_message += " Tutorial popup: %s." % String(trigger_id)


func _record_room_event(context: RunContext, event_type: StringName, payload: Dictionary) -> void:
	if context == null:
		return
	var command := context.active_command
	context.record_event(event_type, String(command.get("command_id", "")), StringName(command.get("actor_id", &"player")), String(command.get("source", "room_resolver")), payload)


func _fail_run(context: RunContext, reason: String) -> Dictionary:
	if runtime_controller != null and runtime_controller.has_method("fail_run"):
		return runtime_controller.fail_run(reason)
	var fallback_state_machine = RunStateMachineScript.new()
	return fallback_state_machine.fail_run(context, reason)
