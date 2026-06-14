extends RefCounted
class_name RunQueryFacade

# Read-only query and snapshot boundary for run state.
# UI and presentation code should consume these snapshots instead of private run state.


func build_result_snapshot(context: RunContext) -> Dictionary:
	var ledger_snapshot: Dictionary = get_asset_snapshot(context)
	var event_log_snapshot: Array[Dictionary] = get_event_log_snapshot(context)
	var transaction_log_snapshot: Array[Dictionary] = get_transaction_log_snapshot(context)
	return {
		"outcome": context.outcome,
		"mode": context.mode,
		"position": context.player_pos,
		"hp": context.hp,
		"max_hp": context.max_hp,
		"power": context.power,
		"pressure": context.pressure,
		"protocol_level": context.protocol_level,
		"black_coin": ledger_snapshot.get("black_coin", context.pending_gold),
		"gold_coin": ledger_snapshot.get("gold_coin", context.safe_gold),
		"pending_gold": context.pending_gold,
		"safe_gold": context.safe_gold,
		"parts": context.parts,
		"backpack_capacity": ledger_snapshot.get("backpack_capacity", 0),
		"backpack_used": ledger_snapshot.get("backpack_used", 0),
		"backpack_remaining": ledger_snapshot.get("backpack_remaining", 0),
		"carried_item_count": context.carried_items.size(),
		"carried_item_value": RunInventory.get_carried_item_value(context),
		"carried_items": context.carried_items.duplicate(true),
		"inventory_items": ledger_snapshot.get("inventory_items", []),
		"equipped_items": ledger_snapshot.get("equipped_items", []),
		"room_floor_items": ledger_snapshot.get("room_floor_items", []),
		"room_floor_item_count": ledger_snapshot.get("room_floor_item_count", 0),
		"warehouse_lite": ledger_snapshot.get("warehouse_lite", []),
		"settlement_log": ledger_snapshot.get("settlement_log", []),
		"event_log": event_log_snapshot,
		"event_count": event_log_snapshot.size(),
		"transaction_log": transaction_log_snapshot,
		"transaction_count": transaction_log_snapshot.size(),
		"status_effects": ledger_snapshot.get("status_effects", []),
		"failure_salvage": context.failure_salvage.duplicate(true),
		"stats": context.run_stats.duplicate(true),
		"final_room": context.current_room_type,
		"encounter_type": context.encounter_type,
		"encounter_tags": context.encounter_tags.duplicate(true),
		"blocked_reason": context.blocked_reason,
		"turn": context.turn,
	}


func build_status_snapshot(context: RunContext) -> Dictionary:
	var ledger_snapshot: Dictionary = get_asset_snapshot(context)
	var event_log_snapshot: Array[Dictionary] = get_event_log_snapshot(context)
	var transaction_log_snapshot: Array[Dictionary] = get_transaction_log_snapshot(context)
	var content_def_snapshot: Dictionary = get_content_def_snapshot(context)
	return {
		"run_id": context.run_id,
		"mode": context.mode,
		"phase": context.phase,
		"run_started": context.run_started,
		"width": context.width,
		"height": context.height,
		"player_pos": context.player_pos,
		"hp": context.hp,
		"max_hp": context.max_hp,
		"power": context.power,
		"pressure": context.pressure,
		"protocol_level": context.protocol_level,
		"black_coin": ledger_snapshot.get("black_coin", context.pending_gold),
		"gold_coin": ledger_snapshot.get("gold_coin", context.safe_gold),
		"pending_gold": context.pending_gold,
		"safe_gold": context.safe_gold,
		"parts": context.parts,
		"backpack_capacity": ledger_snapshot.get("backpack_capacity", 0),
		"backpack_used": ledger_snapshot.get("backpack_used", 0),
		"backpack_remaining": ledger_snapshot.get("backpack_remaining", 0),
		"inventory_items": ledger_snapshot.get("inventory_items", []),
		"equipped_items": ledger_snapshot.get("equipped_items", []),
		"room_floor_items": ledger_snapshot.get("room_floor_items", []),
		"room_floor_item_count": ledger_snapshot.get("room_floor_item_count", 0),
		"warehouse_lite": ledger_snapshot.get("warehouse_lite", []),
		"settlement_log": ledger_snapshot.get("settlement_log", []),
		"event_log": event_log_snapshot,
		"event_count": event_log_snapshot.size(),
		"transaction_log": transaction_log_snapshot,
		"transaction_count": transaction_log_snapshot.size(),
		"content_definitions": content_def_snapshot,
		"content_definition_count": content_def_snapshot.size(),
		"status_effects": ledger_snapshot.get("status_effects", []),
		"position": context.player_pos,
		"current_room": context.current_room_type,
		"encounter_type": context.encounter_type,
		"encounter_tags": context.encounter_tags.duplicate(true),
		"blocked_reason": context.blocked_reason,
		"adjacent_mines": context.current_adjacent_mines,
		"search_state": get_search_state_label(context),
		"search_state_data": get_search_state_data(context),
		"encounter_view_model": get_encounter_view_model(context),
		"encounter_result_summary": get_encounter_result_summary(context),
		"event_state": context.event_state.duplicate(true),
		"enemy_state": context.enemy_state.duplicate(true),
		"last_message": context.last_message,
		"last_reward": context.last_reward.duplicate(true),
		"outcome": context.outcome,
		"run_active": context.run_active,
		"extracted": context.extracted,
		"failed": context.failed,
		"exit_id": context.exit_id,
		"tutorial_popup": context.tutorial_popup.duplicate(true),
		"result_snapshot": context.result_snapshot.duplicate(true),
		"failure_salvage": context.failure_salvage.duplicate(true),
		"stats": context.run_stats.duplicate(true),
	}


func get_asset_snapshot(context: RunContext) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {}
	return context.asset_ledger.get_public_snapshot(context.player_pos)


func get_event_log_snapshot(context: RunContext) -> Array[Dictionary]:
	if context == null or context.run_event_log == null:
		return []
	return context.run_event_log.snapshot()


func get_transaction_log_snapshot(context: RunContext) -> Array[Dictionary]:
	if context == null or context.transaction_log == null:
		return []
	return context.transaction_log.snapshot()


func get_content_def_snapshot(context: RunContext) -> Dictionary:
	if context == null or context.content_defs == null:
		return {}
	return context.content_defs.snapshot()


func get_inventory_summary(context: RunContext) -> Dictionary:
	var snapshot: Dictionary = get_asset_snapshot(context)
	return {
		"backpack_capacity": snapshot.get("backpack_capacity", 0),
		"backpack_used": snapshot.get("backpack_used", 0),
		"backpack_remaining": snapshot.get("backpack_remaining", 0),
		"inventory_items": snapshot.get("inventory_items", []),
		"equipped_items": snapshot.get("equipped_items", []),
		"room_floor_items": snapshot.get("room_floor_items", []),
		"room_floor_item_count": snapshot.get("room_floor_item_count", 0),
	}


func get_encounter_summary(context: RunContext) -> Dictionary:
	if context == null:
		return {"encounter_type": &"none", "encounter_tags": []}
	var identity: Dictionary = EncounterResolver.get_encounter_identity(context, context.current_room_type, context.get_current_pos())
	identity["blocked_reason"] = context.blocked_reason
	return identity


func get_encounter_view_model(context: RunContext) -> Dictionary:
	return EncounterResolver.build_view_model(context)


func get_encounter_result_summary(context: RunContext) -> Dictionary:
	return EncounterResolver.build_result_summary(context)


func get_search_state_label(context: RunContext) -> String:
	if context == null:
		return "blocked"
	if context.searched_cells.has(context.cell_key(context.player_pos)):
		return "searched"
	match context.current_room_type:
		&"Normal":
			return "searchable"
		&"Chest":
			return "chest"
		_:
			return "blocked"


func get_search_state_data(context: RunContext) -> Dictionary:
	if context == null or context.truth_map == null:
		return {"can_search": false, "searched": false, "reason": "not_ready", "is_chest": false}
	var key: String = context.cell_key(context.player_pos)
	var searched: bool = context.searched_cells.has(key)
	var can_search: bool = false
	var reason: String = "blocked"
	var is_chest: bool = false
	if searched:
		reason = "searched"
	elif context.player_pos == context.truth_map.spawn_pos:
		reason = "spawn"
	elif context.current_room_type == &"Normal":
		can_search = true
		reason = "searchable"
	elif context.current_room_type == &"Chest":
		can_search = true
		reason = "chest"
		is_chest = true
	elif context.current_room_type == &"Event":
		reason = "event"
	elif context.current_room_type == &"Monster":
		reason = "monster"
	elif context.current_room_type == &"Exit":
		reason = "exit"
	elif context.current_room_type == &"Mine":
		reason = "mine"
	return {
		"can_search": can_search,
		"searched": searched,
		"reason": reason,
		"is_chest": is_chest,
	}
