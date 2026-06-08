extends RefCounted
class_name RoomResolver

# Room behavior goes through RoomResolver. UI reads emitted snapshots only.


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

	var first_explore := not context.explored_cells.has(context.cell_key(pos))
	if first_explore:
		context.explored_cells[context.cell_key(pos)] = true
		ProtocolService.add_pressure(context, 2)

	if context.current_room_type == &"Mine":
		return _enter_mine(context, pos)

	var trigger_id := TutorialService.trigger_for(context, pos)
	if context.current_room_type == &"Exit":
		context.last_message = "Exit room ready. Request extraction."
	elif context.current_room_type == &"Monster" and not context.truth_map.is_cleared(pos):
		context.last_message = "Monster present. Fight is available."
	elif context.current_room_type == &"Event" and not context.interacted_cells.has(context.cell_key(pos)):
		context.last_message = "Event placeholder is available."
	elif context.current_room_type == &"Chest" and not context.searched_cells.has(context.cell_key(pos)):
		context.last_message = "Chest can be searched."
	else:
		context.last_message = "Entered %s room. Adjacent mines: %d." % [String(context.current_room_type), context.current_adjacent_mines]
	if trigger_id != &"":
		context.last_message += " Tutorial popup: %s." % String(trigger_id)
	return {"ok": true, "message": context.last_message}


func search_current_room(context: RunContext) -> Dictionary:
	if context == null or not context.run_active:
		return {"ok": false, "message": "Run is not active."}
	var pos := context.get_current_pos()
	var key := context.cell_key(pos)
	if context.searched_cells.has(key):
		context.last_message = "This room was already searched."
		return {"ok": true, "message": context.last_message}
	if not context.intel_map.is_revealed(pos):
		context.last_message = "Cannot search unrevealed room."
		return {"ok": false, "message": context.last_message}
	if not (context.current_room_type in [&"Normal", &"Chest"]):
		context.last_message = "This room cannot be searched."
		return {"ok": false, "message": context.last_message}
	if pos == context.truth_map.spawn_pos:
		context.last_message = "Spawn cannot be searched."
		return {"ok": false, "message": context.last_message}

	var is_chest := context.current_room_type == &"Chest"
	var reward := RunInventory.add_search_reward(context, pos, context.current_adjacent_mines, is_chest)
	context.searched_cells[key] = true
	context.last_reward = reward
	if is_chest:
		context.truth_map.mark_cleared(pos)
	context.intel_map.refresh_revealed_cell(pos, context.truth_map)
	var reward_items: Array = reward.get("items", [])
	context.last_message = "Search complete: +%d pending gold, +%d items." % [int(reward.get("gold", 0)), reward_items.size()]
	return {"ok": true, "message": context.last_message}


func interact_current_room(context: RunContext) -> Dictionary:
	if context == null or not context.run_active:
		return {"ok": false, "message": "Run is not active."}
	var pos := context.get_current_pos()
	var key := context.cell_key(pos)
	match context.current_room_type:
		&"Chest":
			return search_current_room(context)
		&"Normal":
			return search_current_room(context)
		&"Event":
			if context.interacted_cells.has(key):
				context.last_message = "Event already completed."
			else:
				context.interacted_cells[key] = true
				context.pending_gold += 2
				context.run_stats["events_completed"] = int(context.run_stats.get("events_completed", 0)) + 1
				context.truth_map.mark_cleared(pos)
				context.intel_map.refresh_revealed_cell(pos, context.truth_map)
				context.last_message = "Event placeholder resolved: +2 pending gold."
		&"Monster":
			context.last_message = "Monster requires fight command."
		&"Exit":
			context.last_message = "Exit ready. Request extraction."
		&"Mine":
			context.last_message = "Mine room has no safe interaction."
		_:
			context.last_message = "Nothing to interact with here."
	return {"ok": true, "message": context.last_message}


func fight_current_enemy(context: RunContext) -> Dictionary:
	if context == null or not context.run_active:
		return {"ok": false, "message": "Run is not active."}
	var pos := context.get_current_pos()
	if context.current_room_type != &"Monster":
		context.last_message = "No monster to fight here."
		return {"ok": false, "message": context.last_message}
	if context.truth_map.is_cleared(pos):
		context.last_message = "Monster already cleared."
		return {"ok": true, "message": context.last_message}
	var result := CombatState.fight_enemy(context, pos, context.current_adjacent_mines)
	context.truth_map.mark_cleared(pos)
	context.intel_map.refresh_revealed_cell(pos, context.truth_map)
	context.last_reward = result
	context.last_message = "Monster cleared: damage %d, reward +%d pending gold." % [int(result.get("damage", 0)), int(result.get("reward_gold", 0))]
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
