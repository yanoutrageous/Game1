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
			var best_sell := _best_sellable_item(context)
			var has_sellable := not best_sell.is_empty()
			var high_value := has_sellable and int(best_sell.get("base_value", 0)) >= RunBalanceCatalogScript.TRADER_HIGH_VALUE_CONFIRM_THRESHOLD
			var black_coin := _run_black_coin(context)
			var missing_hp := context != null and context.hp < context.max_hp
			return [
				{"id": &"sell_best_item", "label": "Sell top backpack item", "enabled": has_sellable and not high_value, "disabled_reason": "high_value_sale_requires_confirmation" if high_value else "no_sellable_inventory_item"},
				{"id": &"confirm_high_value_sale", "label": "Confirm high-value sale", "enabled": high_value, "disabled_reason": "no_high_value_sale_candidate"},
				{"id": &"buy_treatment", "label": "Buy treatment", "enabled": black_coin >= RunBalanceCatalogScript.TRADER_TREATMENT_COST and missing_hp, "disabled_reason": "need_black_coin_or_missing_hp"},
				{"id": &"buy_info", "label": "Buy route info", "enabled": black_coin >= RunBalanceCatalogScript.TRADER_INFO_COST, "disabled_reason": "need_black_coin"},
				{"id": &"leave", "label": "Leave market", "enabled": true},
			]
		&"dice":
			var dice_coin := _run_black_coin(context)
			return [
				{"id": &"bet_small", "label": "Wager 20 black coin", "enabled": dice_coin >= DICE_BET, "disabled_reason": "need_20_run_black_coin"},
				{"id": &"leave", "label": "Leave dice table", "enabled": true},
			]
		&"altar":
			var stage_index := _altar_stage_index(context)
			var hp_cost := RunBalanceCatalogScript.altar_hp_cost_for_stage(stage_index)
			var stage_label := "Offer %d HP (stage %d/5)" % [hp_cost, stage_index + 1]
			return [
				{"id": &"offer_hp", "label": stage_label, "enabled": context != null and context.hp - hp_cost >= 1, "disabled_reason": "hp_must_remain_at_least_1"},
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
	match option_id:
		&"sell_best_item":
			return RunRuleService.execute_trader_sell_best(context, false)
		&"confirm_high_value_sale":
			return RunRuleService.execute_trader_sell_best(context, true)
		&"buy_treatment":
			return RunRuleService.execute_trader_treatment(context, RunBalanceCatalogScript.TRADER_TREATMENT_COST, 18)
		&"buy_info":
			return RunRuleService.execute_trader_info(context, RunBalanceCatalogScript.TRADER_INFO_COST)
	return {"ok": false, "message": "Unknown trader option."}


static func _execute_dice(context: RunContext, pos: Vector2i, option_id: StringName) -> Dictionary:
	if option_id != &"bet_small":
		return {"ok": false, "message": "Unknown dice option."}
	return RunRuleService.execute_dice_bet(context, pos, DICE_BET)


static func _execute_altar(context: RunContext, option_id: StringName, fail_authority = null) -> Dictionary:
	if option_id != &"offer_hp":
		return {"ok": false, "message": "Unknown altar option."}
	var stage_index := _altar_stage_index(context)
	var hp_cost := RunBalanceCatalogScript.altar_hp_cost_for_stage(stage_index)
	var black_coin_reward := RunBalanceCatalogScript.altar_black_coin_reward_for_stage(stage_index)
	if context.hp - hp_cost < 1:
		return {"ok": false, "message": "Not enough HP.", "blocked_reason": "blocked_hp"}
	context.run_stats["altar_stage"] = stage_index + 1
	var completed := stage_index + 1 >= RunBalanceCatalogScript.ALTAR_HP_COSTS.size()
	return RunRuleService.apply_event_rule_result(context, &"altar", {
		"ok": true,
		"completed": completed,
		"event_type": &"altar",
		"altar_stage": stage_index + 1,
		"hp_delta": -hp_cost,
		"black_coin_delta": black_coin_reward,
		"pending_gold_delta": black_coin_reward,
		"item_defs": [RunContentCatalogScript.altar_relic(context, stage_index + 1)],
		"status_effects": [{
			"effect_id": "altar_focus",
			"duration_type": &"current_run",
			"remaining": 1,
			"tags": ["buff", "event"],
		}],
		"message": RunTextCatalogScript.altar_stage_result(stage_index + 1, hp_cost, black_coin_reward, completed),
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


static func _run_black_coin(context: RunContext) -> int:
	if context == null:
		return 0
	if context.asset_ledger != null:
		return context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK)
	return int(context.pending_gold)


static func _best_sellable_item(context: RunContext) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {}
	return context.asset_ledger.get_best_sellable_inventory_item()


static func _altar_stage_index(context: RunContext) -> int:
	if context == null:
		return 0
	return clampi(int(context.run_stats.get("altar_stage", 0)), 0, RunBalanceCatalogScript.ALTAR_HP_COSTS.size() - 1)
