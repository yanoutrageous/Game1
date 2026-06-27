extends RefCounted
class_name EventService

const EVENT_TYPES := [&"trader", &"dice", &"altar", &"trap"]
const RunBalanceCatalogScript := preload("res://scripts/core/run/run_balance_catalog.gd")
const RunContentCatalogScript := preload("res://scripts/core/run/run_content_catalog.gd")
const RunTextCatalogScript := preload("res://scripts/core/run/run_text_catalog.gd")

const DICE_BET := RunBalanceCatalogScript.DICE_BET
const TRAP_POWER_REQ := RunBalanceCatalogScript.TRAP_POWER_REQUIREMENT


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


static func execute_default(context: RunContext, pos: Vector2i, fail_authority = null) -> Dictionary:
	var event_type := get_event_type(context, pos)
	match event_type:
		&"trader":
			return execute_option(context, pos, &"sell_best_item", fail_authority)
		&"dice":
			return execute_option(context, pos, &"bet_small", fail_authority)
		&"altar":
			return execute_option(context, pos, &"offer_hp", fail_authority)
		&"trap":
			return execute_option(context, pos, &"disarm", fail_authority)
	return execute_option(context, pos, &"leave", fail_authority)


static func execute_option(context: RunContext, pos: Vector2i, option_id: StringName, fail_authority = null) -> Dictionary:
	if context == null:
		return {"ok": false, "message": "No active run."}
	var key := context.cell_key(pos)
	var event_type := get_event_type(context, pos)
	if context.interacted_cells.has(key):
		context.event_state = get_event_state(context, pos)
		context.last_message = RunTextCatalogScript.event_already_resolved()
		return {"ok": true, "completed": true, "message": context.last_message}
	if option_id == &"leave":
		context.last_message = RunTextCatalogScript.event_left()
		context.event_state = get_event_state(context, pos)
		return {"ok": true, "completed": false, "message": context.last_message}
	var option_available := false
	var option_enabled := false
	for option in get_event_options(context, pos, event_type, false):
		if StringName(option.get("id", &"")) == option_id:
			option_available = true
			option_enabled = bool(option.get("enabled", true))
			break
	if not option_available or not option_enabled:
		context.blocked_reason = "event_option_unavailable"
		context.event_state = get_event_state(context, pos)
		context.last_message = RunTextCatalogScript.event_option_unavailable()
		return {"ok": false, "completed": false, "blocked_reason": "event_option_unavailable", "reason": "event_option_unavailable", "message": context.last_message}

	var result := {}
	match event_type:
		&"trader":
			result = _execute_trader(context, option_id)
		&"dice":
			result = _execute_dice(context, pos, option_id)
		&"altar":
			result = _execute_altar(context, option_id, fail_authority)
		&"trap":
			result = _execute_trap(context, option_id, fail_authority)
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


static func _execute_altar(context: RunContext, option_id: StringName, fail_authority = null) -> Dictionary:
	if option_id != &"offer_hp":
		return {"ok": false, "message": "Unknown altar option."}
	if context.hp <= 10:
		return {"ok": false, "message": "Not enough HP.", "blocked_reason": "blocked_hp"}
	return RunRuleService.apply_event_rule_result(context, &"altar", {
		"ok": true,
		"completed": true,
		"event_type": &"altar",
		"hp_delta": -RunBalanceCatalogScript.ALTAR_HP_COST,
		"black_coin_delta": RunBalanceCatalogScript.ALTAR_BLACK_COIN_REWARD,
		"pending_gold_delta": RunBalanceCatalogScript.ALTAR_BLACK_COIN_REWARD,
		"item_defs": [RunContentCatalogScript.altar_relic(context)],
		"status_effects": [{
			"effect_id": "altar_focus",
			"duration_type": &"current_run",
			"remaining": 1,
			"tags": ["buff", "event"],
		}],
		"message": RunTextCatalogScript.altar_result(),
	}, fail_authority)


static func _execute_trap(context: RunContext, option_id: StringName, fail_authority = null) -> Dictionary:
	if option_id != &"disarm":
		return {"ok": false, "message": "Unknown mechanism option."}
	if context.power >= TRAP_POWER_REQ:
		return RunRuleService.apply_event_rule_result(context, &"trap", {"ok": true, "completed": true, "event_type": &"trap", "black_coin_delta": 25, "pending_gold_delta": 25, "item_defs": RunContentCatalogScript.trap_cache(context), "message": RunTextCatalogScript.trap_success()}, fail_authority)
	return RunRuleService.apply_event_rule_result(context, &"trap", {
		"ok": true,
		"completed": true,
		"event_type": &"trap",
		"hp_delta": -RunBalanceCatalogScript.TRAP_FAILURE_DAMAGE,
		"pressure_delta": RunBalanceCatalogScript.TRAP_PRESSURE_DELTA,
		"message": RunTextCatalogScript.trap_failure(),
	}, fail_authority)
