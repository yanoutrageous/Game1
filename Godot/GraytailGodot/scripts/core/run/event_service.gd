extends RefCounted
class_name EventService

const EVENT_TYPES := [&"trader", &"dice", &"altar", &"trap"]
const DICE_BET := 20
const TRAP_POWER_REQ := 8


static func get_event_type(context: RunContext, pos: Vector2i) -> StringName:
	if context == null:
		return &"trader"
	var index := absi((pos.x * 73 + pos.y * 137 + context.seed_value * 31) % EVENT_TYPES.size())
	return EVENT_TYPES[index]


static func get_event_state(context: RunContext, pos: Vector2i) -> Dictionary:
	var event_type := get_event_type(context, pos)
	var completed := context != null and context.interacted_cells.has(context.cell_key(pos))
	return {
		"event_type": event_type,
		"completed": completed,
		"options": get_event_options(context, pos, event_type, completed),
	}


static func get_event_options(context: RunContext, pos: Vector2i, event_type: StringName, completed: bool) -> Array[Dictionary]:
	if completed:
		return [{"id": &"leave", "label": "Close", "enabled": true}]
	match event_type:
		&"trader":
			return [
				{"id": &"sell_best_item", "label": "Sell top inventory", "enabled": context != null and context.carried_items.size() > 0},
				{"id": &"leave", "label": "Leave market", "enabled": true},
			]
		&"dice":
			return [
				{"id": &"bet_small", "label": "Wager 20 black coin", "enabled": context != null and context.pending_gold >= DICE_BET},
				{"id": &"leave", "label": "Leave dice table", "enabled": true},
			]
		&"altar":
			return [
				{"id": &"offer_hp", "label": "Pay 10 HP", "enabled": context != null and context.hp > 10},
				{"id": &"leave", "label": "Leave altar", "enabled": true},
			]
		&"trap":
			return [
				{"id": &"disarm", "label": "Try mechanism", "enabled": true},
				{"id": &"leave", "label": "Leave mechanism", "enabled": true},
			]
	return [{"id": &"leave", "label": "Leave event", "enabled": true}]


static func execute_default(context: RunContext, pos: Vector2i) -> Dictionary:
	var event_type := get_event_type(context, pos)
	match event_type:
		&"trader":
			return execute_option(context, pos, &"sell_best_item")
		&"dice":
			return execute_option(context, pos, &"bet_small")
		&"altar":
			return execute_option(context, pos, &"offer_hp")
		&"trap":
			return execute_option(context, pos, &"disarm")
	return execute_option(context, pos, &"leave")


static func execute_option(context: RunContext, pos: Vector2i, option_id: StringName) -> Dictionary:
	if context == null:
		return {"ok": false, "message": "No active run."}
	var key := context.cell_key(pos)
	var event_type := get_event_type(context, pos)
	if context.interacted_cells.has(key):
		context.event_state = get_event_state(context, pos)
		context.last_message = "Event already resolved."
		return {"ok": true, "completed": true, "message": context.last_message}
	if option_id == &"leave":
		context.last_message = "Event left unresolved."
		context.event_state = get_event_state(context, pos)
		return {"ok": true, "completed": false, "message": context.last_message}

	var result := {}
	match event_type:
		&"trader":
			result = _execute_trader(context, option_id)
		&"dice":
			result = _execute_dice(context, pos, option_id)
		&"altar":
			result = _execute_altar(context, option_id)
		&"trap":
			result = _execute_trap(context, option_id)
		_:
			result = {"ok": false, "message": "Unknown event type."}

	if bool(result.get("completed", false)):
		context.interacted_cells[key] = true
		context.run_stats["events_completed"] = int(context.run_stats.get("events_completed", 0)) + 1
		context.run_stats["events_%s" % String(event_type)] = int(context.run_stats.get("events_%s" % String(event_type), 0)) + 1
	context.event_state = get_event_state(context, pos)
	context.blocked_reason = String(result.get("blocked_reason", ""))
	context.last_reward = result.duplicate(true)
	context.last_message = String(result.get("message", "Event resolved."))
	return result


static func _execute_trader(context: RunContext, option_id: StringName) -> Dictionary:
	if option_id != &"sell_best_item":
		return {"ok": false, "message": "Unknown trader option."}
	return RunRuleService.execute_trader_sell_best(context)


static func _execute_dice(context: RunContext, pos: Vector2i, option_id: StringName) -> Dictionary:
	if option_id != &"bet_small":
		return {"ok": false, "message": "Unknown dice option."}
	return RunRuleService.execute_dice_bet(context, pos, DICE_BET)


static func _execute_altar(context: RunContext, option_id: StringName) -> Dictionary:
	if option_id != &"offer_hp":
		return {"ok": false, "message": "Unknown altar option."}
	if context.hp <= 10:
		return {"ok": false, "message": "Not enough HP.", "blocked_reason": "blocked_hp"}
	context.hp -= 10
	return RunRuleService.apply_event_rule_result(context, &"altar", {
		"ok": true,
		"completed": true,
		"event_type": &"altar",
		"hp_delta": -10,
		"black_coin_delta": 8,
		"pending_gold_delta": 8,
		"item_defs": [{
			"item_id": "altar_relic_%d" % context.turn,
			"display_name": "Altar Relic",
			"item_type": &"recovered",
			"rarity": &"unique",
			"weight": 1,
			"base_value": 8,
			"value_state": &"known_value",
			"tags": ["altar", "event", "collection"],
		}],
		"status_effects": [{
			"effect_id": "altar_focus",
			"duration_type": &"current_run",
			"remaining": 1,
			"tags": ["buff", "event"],
		}],
		"message": "Altar exchange complete: HP -10, black_coin +8, item +1.",
	})


static func _execute_trap(context: RunContext, option_id: StringName) -> Dictionary:
	if option_id != &"disarm":
		return {"ok": false, "message": "Unknown mechanism option."}
	if context.power >= TRAP_POWER_REQ:
		var item_defs: Array[Dictionary] = [
			{"item_id": "trap_cache_common_%d" % context.turn, "display_name": "Mechanism Cache", "item_type": &"recovered", "rarity": &"good", "weight": 1, "base_value": 4, "value_state": &"known_value", "tags": ["trap", "event"]},
			{"item_id": "trap_cache_low_%d" % context.turn, "display_name": "Mechanism Parts", "item_type": &"recovered", "rarity": &"common", "weight": 1, "base_value": 2, "value_state": &"known_value", "tags": ["trap", "event"]},
		]
		return RunRuleService.apply_event_rule_result(context, &"trap", {"ok": true, "completed": true, "event_type": &"trap", "black_coin_delta": 25, "pending_gold_delta": 25, "item_defs": item_defs, "message": "Mechanism opened: black_coin +25, item +2."})
	CombatState.apply_damage(context, 1, "event_trap")
	ProtocolService.add_pressure(context, 5)
	return {"ok": true, "completed": true, "event_type": &"trap", "hp_delta": -1, "pressure_delta": 5, "message": "Mechanism triggered: HP -1, pressure +5."}
