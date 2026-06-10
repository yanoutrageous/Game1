extends RefCounted
class_name RoomResolver

# Room behavior goes through RoomResolver. UI reads emitted snapshots only.
# G6 replaces the G4 text "Event placeholder resolved" with EventService outcomes.


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
		context.explored_cells[context.cell_key(pos)] = true
		ProtocolService.add_pressure(context, 2)

	if context.current_room_type == &"Mine":
		var mine_result := _enter_mine(context, pos)
		_maybe_trigger_tutorial(context, pos)
		return mine_result

	if context.current_room_type == &"Exit":
		_record_room_event(context, RunEventLog.EVENT_EXTRACTION_FOUND, {"position": pos, "exit_id": context.exit_id})
		context.last_message = "Exit room ready. Request extraction."
	elif context.current_room_type == &"Monster" and not context.truth_map.is_cleared(pos):
		context.enemy_state = CombatState.build_enemy_state(context, pos, context.current_adjacent_mines)
		context.last_message = "Monster present. Fight is available."
	elif context.current_room_type == &"Event" and not context.interacted_cells.has(context.cell_key(pos)):
		context.event_state = EventService.get_event_state(context, pos)
		context.last_message = "Event available: %s." % String(context.event_state.get("event_type", &"event"))
	elif context.current_room_type == &"Chest" and not context.searched_cells.has(context.cell_key(pos)):
		context.last_message = "Chest can be searched."
	else:
		context.last_message = "Entered %s room. Adjacent mines: %d." % [String(context.current_room_type), context.current_adjacent_mines]
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
	if context.blocked_reason != "":
		context.last_message = "Search complete: +%d black coin, %d items, %d on room floor (%s)." % [int(reward.get("gold", 0)), reward_items.size(), floor_items.size(), context.blocked_reason]
	else:
		context.last_message = "Search complete: +%d black coin, +%d items." % [int(reward.get("gold", 0)), reward_items.size()]
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
			var result := EventService.execute_default(context, pos)
			if bool(result.get("completed", false)):
				context.truth_map.mark_cleared(pos)
				context.intel_map.refresh_revealed_cell(pos, context.truth_map)
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
	var result := EventService.execute_option(context, pos, option_id)
	_record_room_event(context, RunEventLog.EVENT_EVENT_OPTION_SELECTED, {"position": pos, "option_id": option_id, "result": result.duplicate(true)})
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
	var result := CombatState.fight_enemy(context, pos, context.current_adjacent_mines)
	if bool(result.get("cleared", false)):
		context.truth_map.mark_cleared(pos)
		context.intel_map.refresh_revealed_cell(pos, context.truth_map)
	context.last_reward = result
	context.blocked_reason = String(result.get("blocked_reason", ""))
	context.enemy_state = result.duplicate(true)
	context.last_message = "Monster cleared: damage %d, reward +%d black coin." % [int(result.get("damage", 0)), int(result.get("reward_gold", 0))]
	_record_room_event(context, RunEventLog.EVENT_COMBAT_RESOLVED, {"position": pos, "result": result.duplicate(true)})
	return result


func can_extract(context: RunContext) -> bool:
	if context == null or context.truth_map == null:
		return false
	return context.current_room_type == &"Exit" and context.truth_map.get_exit_id(context.get_current_pos()) != &""


func _enter_mine(context: RunContext, pos: Vector2i) -> Dictionary:
	var key := context.cell_key(pos)
	if not context.entered_cells.has(key):
		context.entered_cells[key] = true
		context.truth_map.mark_triggered(pos)
		var damage := CombatState.take_mine_hit(context)
		ProtocolService.add_pressure(context, 10)
		context.run_stats["mine_hits"] = int(context.run_stats.get("mine_hits", 0)) + 1
		context.intel_map.refresh_revealed_cell(pos, context.truth_map)
		context.last_message = "Mine triggered: -%d HP, +10 pressure." % damage
		if context.mine_hits_are_fatal and not context.failed:
			context.fail_run("fatal_mine")
	else:
		context.last_message = "Triggered mine re-entered; no damage."
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
