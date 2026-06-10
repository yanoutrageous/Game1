extends RefCounted
class_name RunRuleService

# Default rule interface for G8.1.
# RuleResult dictionaries describe outcomes; EffectSpec dictionaries describe asset mutations.

const DEFAULT_ACTOR_ID := &"player"


static func make_rule_result(ok: bool, status: StringName, actor_id: StringName = DEFAULT_ACTOR_ID, reason: String = "", effects: Array = [], messages: Array[String] = [], snapshot_delta: Dictionary = {}, settlement_log_entry: Dictionary = {}) -> Dictionary:
	return {
		"ok": ok,
		"status": status,
		"rule_result": status,
		"reason": reason,
		"blocked_reason": reason if not ok else "",
		"actor_id": actor_id,
		"effects": effects.duplicate(true),
		"messages": messages.duplicate(true),
		"snapshot_delta": snapshot_delta.duplicate(true),
		"settlement_log_entry": settlement_log_entry.duplicate(true),
	}


static func make_effect_spec(effect_type: StringName, source: String, target: Variant, payload: Dictionary, actor_id: StringName = DEFAULT_ACTOR_ID) -> Dictionary:
	return {
		"type": effect_type,
		"source": source,
		"target": target,
		"payload": payload.duplicate(true),
		"actor_id": actor_id,
	}


static func encounter_for_room(context: RunContext, room_type: StringName, pos: Vector2i) -> Dictionary:
	var encounter_type := StringName(String(room_type).to_lower())
	var tags: Array = []
	match room_type:
		&"Event":
			encounter_type = EventService.get_event_type(context, pos)
			tags = [&"event_like", encounter_type]
		&"Chest":
			encounter_type = &"chest_basic"
			tags = [&"loot", &"container"]
		&"Monster":
			encounter_type = &"monster_basic"
			tags = [&"combat", &"loot"]
		&"Exit":
			encounter_type = &"exit_beacon"
			tags = [&"settlement", &"extract"]
		&"Mine":
			encounter_type = &"mine_trap"
			tags = [&"hazard"]
		&"Normal":
			encounter_type = &"search_basic"
			tags = [&"search", &"loot"]
		_:
			tags = [&"room"]
	return {"encounter_type": encounter_type, "encounter_tags": tags}


static func apply_search_reward(context: RunContext, pos: Vector2i, adjacent_mines: int, is_chest: bool) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"search_reward", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var black_coin := RunRuleContent.default_search_black_coin(context, pos, adjacent_mines, is_chest)
	var item_defs := RunRuleContent.default_search_items(pos, adjacent_mines, is_chest, black_coin)
	var effects := [
		make_effect_spec(RunAssetEffectHandler.EFFECT_ADD_CURRENCY, "search", pos, {"currency_id": RunAssetLedger.CURRENCY_BLACK, "amount": black_coin}),
		make_effect_spec(RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS, "search", pos, {"item_defs": item_defs, "preferred_location": RunAssetLedger.LOCATION_INVENTORY, "room_pos": pos}),
	]
	var applied := RunAssetEffectHandler.apply_effects(context, effects)
	var item_result := _effect_result(applied, RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS)
	var combined_items := _combine_item_results(item_result)
	var log_entry := {"type": &"rule_result", "rule_result": &"search_reward", "black_coin": black_coin, "items": combined_items.size()}
	_append_rule_log(context, log_entry)
	var result := make_rule_result(true, &"search_reward", DEFAULT_ACTOR_ID, "", effects, ["Search reward resolved."], {}, log_entry)
	result["gold"] = black_coin
	result["black_coin_delta"] = black_coin
	result["items"] = combined_items
	result["inventory_items"] = item_result.get("inventory_items", [])
	result["equipped_items"] = item_result.get("equipped_items", [])
	result["ground_items"] = item_result.get("ground_items", [])
	result["blocked_reason"] = item_result.get("blocked_reason", "")
	result["effect_results"] = applied.get("effect_results", [])
	return result


static func apply_combat_reward(context: RunContext, pos: Vector2i, reward_gold: int) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"combat_reward", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var item_defs: Array[Dictionary] = []
	if reward_gold >= 10:
		item_defs.append(RunRuleContent.monster_trophy(pos, reward_gold))
	var effects := [
		make_effect_spec(RunAssetEffectHandler.EFFECT_ADD_CURRENCY, "combat", pos, {"currency_id": RunAssetLedger.CURRENCY_BLACK, "amount": reward_gold}),
		make_effect_spec(RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS, "combat", pos, {"item_defs": item_defs, "preferred_location": RunAssetLedger.LOCATION_INVENTORY, "room_pos": pos}),
	]
	var applied := RunAssetEffectHandler.apply_effects(context, effects)
	var item_result := _effect_result(applied, RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS)
	var result := make_rule_result(true, &"combat_reward", DEFAULT_ACTOR_ID, "", effects, ["Combat reward resolved."])
	result["reward_gold"] = reward_gold
	result["black_coin_delta"] = reward_gold
	result["items"] = _combine_item_results(item_result)
	result["ground_items"] = item_result.get("ground_items", [])
	result["blocked_reason"] = item_result.get("blocked_reason", "")
	result["effect_results"] = applied.get("effect_results", [])
	return result


static func apply_event_rule_result(context: RunContext, event_type: StringName, rule_result: Dictionary) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"event", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var result := rule_result.duplicate(true)
	var effects: Array = []
	if result.has("spend_black_coin"):
		effects.append(make_effect_spec(RunAssetEffectHandler.EFFECT_SPEND_CURRENCY, "event_%s" % String(event_type), context.get_current_pos(), {"currency_id": RunAssetLedger.CURRENCY_BLACK, "amount": int(result.get("spend_black_coin", 0))}))
	if result.has("black_coin_delta"):
		effects.append(make_effect_spec(RunAssetEffectHandler.EFFECT_ADD_CURRENCY, "event_%s" % String(event_type), context.get_current_pos(), {"currency_id": RunAssetLedger.CURRENCY_BLACK, "amount": int(result.get("black_coin_delta", 0))}))
	if result.has("gold_coin_delta"):
		effects.append(make_effect_spec(RunAssetEffectHandler.EFFECT_ADD_CURRENCY, "event_%s" % String(event_type), context.get_current_pos(), {"currency_id": RunAssetLedger.CURRENCY_GOLD, "amount": int(result.get("gold_coin_delta", 0))}))
	var item_defs: Array = result.get("item_defs", [])
	if not item_defs.is_empty():
		var reward_location := StringName(result.get("reward_location", RunAssetLedger.LOCATION_INVENTORY))
		if bool(result.get("drop_on_floor", false)):
			reward_location = RunAssetLedger.LOCATION_ROOM_FLOOR
		effects.append(make_effect_spec(RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS, "event_%s" % String(event_type), context.get_current_pos(), {"item_defs": item_defs, "preferred_location": reward_location, "room_pos": context.get_current_pos()}))
	var status_effects: Array = result.get("status_effects", [])
	for effect in status_effects:
		effects.append(make_effect_spec(RunAssetEffectHandler.EFFECT_ADD_STATUS_EFFECT, "event_%s" % String(event_type), context.get_current_pos(), {"effect": effect}))
	var applied := RunAssetEffectHandler.apply_effects(context, effects)
	if not bool(applied.get("ok", false)):
		var blocked := make_rule_result(false, &"event", DEFAULT_ACTOR_ID, String(applied.get("reason", "blocked")), effects, [String(result.get("message", "Event blocked."))])
		blocked["event_type"] = event_type
		return blocked
	var item_result := _effect_result(applied, RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS)
	if not item_result.is_empty():
		result["items"] = _combine_item_results(item_result)
		result["inventory_items"] = item_result.get("inventory_items", [])
		result["equipped_items"] = item_result.get("equipped_items", [])
		result["ground_items"] = item_result.get("ground_items", [])
		result["blocked_reason"] = item_result.get("blocked_reason", "")
	var log_entry := {"type": &"rule_result", "rule_result": &"event", "event_type": event_type, "result": result.duplicate(true)}
	_append_rule_log(context, log_entry)
	result.merge(make_rule_result(bool(result.get("ok", true)), &"event", DEFAULT_ACTOR_ID, String(result.get("blocked_reason", "")), effects, [String(result.get("message", "Event resolved."))], {}, log_entry), false)
	result["effect_results"] = applied.get("effect_results", [])
	return result


static func execute_trader_sell_best(context: RunContext) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"trader_sell", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var effects := [make_effect_spec(RunAssetEffectHandler.EFFECT_SELL_BEST_INVENTORY_ITEM, "event_trader", context.get_current_pos(), {})]
	var applied := RunAssetEffectHandler.apply_effects(context, effects)
	var sold := applied.get("last_result", {})
	if not bool(sold.get("ok", false)):
		var reason := String(sold.get("reason", "no_sellable_inventory_item"))
		return make_rule_result(false, &"trader_sell", DEFAULT_ACTOR_ID, reason, effects, ["No sellable inventory item."])
	var gold_coin := int(sold.get("gold_coin", 0))
	var result := make_rule_result(true, &"trader_sell", DEFAULT_ACTOR_ID, "", effects, ["Trader sale complete."])
	result["completed"] = true
	result["event_type"] = &"trader"
	result["gold_coin_delta"] = gold_coin
	result["safe_gold"] = gold_coin
	result["sold_item"] = sold.get("sold_item", {})
	result["message"] = "Trader sale complete: gold_coin +%d." % gold_coin
	return result


static func execute_dice_bet(context: RunContext, pos: Vector2i, bet: int) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"dice_bet", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var spend_effect := make_effect_spec(RunAssetEffectHandler.EFFECT_SPEND_CURRENCY, "dice_bet", pos, {"currency_id": RunAssetLedger.CURRENCY_BLACK, "amount": bet})
	var spend_applied := RunAssetEffectHandler.apply_effects(context, [spend_effect])
	if not bool(spend_applied.get("ok", false)):
		var reason := String(spend_applied.get("reason", "blocked_currency"))
		var blocked := make_rule_result(false, &"dice_bet", DEFAULT_ACTOR_ID, reason, [spend_effect], ["Dice needs %d black_coin." % bet])
		blocked["message"] = "Dice needs %d black_coin." % bet
		return blocked
	var roll := absi((pos.x * 197 + pos.y * 83 + context.seed_value * 59 + context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK)) % 6) + 1
	var gain := 0
	if roll == 5:
		gain = bet + 20
	elif roll == 6:
		gain = bet + 60
	var gain_effect := make_effect_spec(RunAssetEffectHandler.EFFECT_ADD_CURRENCY, "dice_reward", pos, {"currency_id": RunAssetLedger.CURRENCY_BLACK, "amount": gain})
	var gain_applied := RunAssetEffectHandler.apply_effects(context, [gain_effect])
	var delta := gain - bet
	var result := make_rule_result(true, &"dice_bet", DEFAULT_ACTOR_ID, "", [spend_effect, gain_effect], ["Dice bet resolved."])
	result["completed"] = true
	result["event_type"] = &"dice"
	result["roll"] = roll
	result["pending_gold_delta"] = delta
	result["black_coin_delta"] = delta
	result["message"] = "Dice roll %d: black_coin delta %d." % [roll, delta]
	result["effect_results"] = spend_applied.get("effect_results", []) + gain_applied.get("effect_results", [])
	return result


static func pickup_ground_item(context: RunContext, instance_id: String = "") -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"pickup_ground_item", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var target_id := instance_id
	if target_id == "":
		var floor_items := context.asset_ledger.get_room_floor_items(context.get_current_pos())
		if floor_items.is_empty():
			return make_rule_result(false, &"pickup_ground_item", DEFAULT_ACTOR_ID, "no_room_floor_items", [], ["No room floor items."])
		target_id = String(floor_items[0].get("instance_id", ""))
	var effect := make_effect_spec(RunAssetEffectHandler.EFFECT_PICKUP_GROUND_ITEM, "pickup", context.get_current_pos(), {"instance_id": target_id, "room_pos": context.get_current_pos()})
	var applied := RunAssetEffectHandler.apply_effects(context, [effect])
	var result: Dictionary = applied.get("last_result", {})
	result.merge(make_rule_result(bool(result.get("ok", false)), &"pickup_ground_item", DEFAULT_ACTOR_ID, String(result.get("reason", "")), [effect], [String(result.get("message", "Pickup resolved."))]), false)
	result["effect_results"] = applied.get("effect_results", [])
	return result


static func drop_inventory_item(context: RunContext, instance_id: String = "") -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"drop_inventory_item", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var target_id := instance_id
	if target_id == "":
		var inventory_items := context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY)
		if inventory_items.is_empty():
			return make_rule_result(false, &"drop_inventory_item", DEFAULT_ACTOR_ID, "no_inventory_items", [], ["No inventory items."])
		target_id = String(inventory_items[0].get("instance_id", ""))
	var effect := make_effect_spec(RunAssetEffectHandler.EFFECT_DROP_INVENTORY_ITEM, "drop", context.get_current_pos(), {"instance_id": target_id, "room_pos": context.get_current_pos()})
	var applied := RunAssetEffectHandler.apply_effects(context, [effect])
	var result: Dictionary = applied.get("last_result", {})
	result.merge(make_rule_result(bool(result.get("ok", false)), &"drop_inventory_item", DEFAULT_ACTOR_ID, String(result.get("reason", "")), [effect], [String(result.get("message", "Drop resolved."))]), false)
	result["effect_results"] = applied.get("effect_results", [])
	return result


static func settle_success(context: RunContext) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {}
	var effect := make_effect_spec(RunAssetEffectHandler.EFFECT_SETTLE_SUCCESS, "settlement", context.get_current_pos(), {})
	var applied := RunAssetEffectHandler.apply_effects(context, [effect])
	var result: Dictionary = applied.get("last_result", {})
	result.merge(make_rule_result(true, &"settle_success", DEFAULT_ACTOR_ID, "", [effect], ["Success settlement resolved."]), false)
	return result


static func settle_failure(context: RunContext) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {}
	var effect := make_effect_spec(RunAssetEffectHandler.EFFECT_SETTLE_FAILURE, "settlement", context.get_current_pos(), {})
	var applied := RunAssetEffectHandler.apply_effects(context, [effect])
	var result: Dictionary = applied.get("last_result", {})
	result.merge(make_rule_result(true, &"settle_failure", DEFAULT_ACTOR_ID, "", [effect], ["Failure settlement resolved."]), false)
	return result


static func _effect_result(applied: Dictionary, effect_type: StringName) -> Dictionary:
	for effect_result in applied.get("effect_results", []):
		if StringName(effect_result.get("effect_type", &"")) == effect_type:
			return effect_result
	return {}


static func _append_rule_log(context: RunContext, entry: Dictionary) -> void:
	if context != null and context.asset_ledger != null:
		context.asset_ledger.settlement_log.append(entry)


static func _combine_item_results(item_result: Dictionary) -> Array:
	var combined: Array = []
	combined.append_array(item_result.get("inventory_items", []))
	combined.append_array(item_result.get("equipped_items", []))
	combined.append_array(item_result.get("ground_items", []))
	return combined
