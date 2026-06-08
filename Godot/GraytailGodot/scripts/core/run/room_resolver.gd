extends RefCounted
class_name RoomResolver

# TruthMap = 真实地图
# IntelMap = 玩家已知情报
# MiniMapViewModel = UI 可读数据
# UI 不得直接读取 TruthMap


func resolve_entry(_room_id: StringName, _context: Variant = null) -> Dictionary:
	return {}


func enter_room(context: RunContext) -> Dictionary:
	if context == null or context.truth_map == null or context.intel_map == null:
		return {"ok": false, "message": "No active run."}

	var pos := context.get_current_pos()
	context.intel_map.reveal_cell(pos, context.truth_map)
	context.current_room_type = context.truth_map.get_room_type(pos)
	context.current_adjacent_mines = context.minefield_service.count_adjacent_mines(context.truth_map, pos)

	var key := context.cell_key(pos)
	if context.current_room_type == &"Mine" and not context.entered_cells.has(key):
		context.entered_cells[key] = true
		context.hp = max(0, context.hp - 25)
		context.pressure += 10
		context.last_message = "Mine room triggered: -25 HP, +10 Pressure."
		if context.hp <= 0:
			context.failed = true
			context.run_active = false
			context.outcome = "Failed"
	else:
		context.last_message = "Entered %s room." % String(context.current_room_type)

	return {"ok": true, "message": context.last_message}


func interact_current_room(context: RunContext) -> Dictionary:
	if context == null or not context.run_active:
		return {"ok": false, "message": "Run is not active."}

	var pos := context.get_current_pos()
	var key := context.cell_key(pos)
	if context.interacted_cells.has(key):
		context.last_message = "This room has already been resolved."
		return {"ok": true, "message": context.last_message}

	match context.current_room_type:
		&"Chest":
			context.pending_gold += 10
			context.interacted_cells[key] = true
			context.last_message = "Chest opened: +10 Pending Gold."
		&"Event":
			context.interacted_cells[key] = true
			context.last_message = "Event placeholder resolved."
		&"Monster":
			context.interacted_cells[key] = true
			context.last_message = "Monster placeholder resolved."
			if context.hp <= 0:
				context.failed = true
				context.run_active = false
				context.outcome = "Failed"
		&"Exit":
			context.last_message = "Exit room ready. Use Extract."
		&"Mine":
			context.last_message = "Mine room has no safe interaction."
		_:
			context.last_message = "Nothing to interact with here."

	return {"ok": true, "message": context.last_message}
