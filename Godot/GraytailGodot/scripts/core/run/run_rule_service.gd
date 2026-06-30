extends RefCounted
class_name RunRuleService

# Default rule interface for G8.1.
# RuleResult dictionaries describe outcomes; EffectSpec dictionaries describe asset mutations.

const DEFAULT_ACTOR_ID := &"player"
const EncounterResolverScript := preload("res://scripts/core/run/encounter/encounter_resolver.gd")
const RuleEffectModifierSchemaScript := preload("res://scripts/core/rules/rule_effect_modifier_schema.gd")
const ContentDeliverySchemaScript := preload("res://scripts/core/content/content_delivery_schema.gd")
const RunEffectApplierScript := preload("res://scripts/core/run/run_effect_applier.gd")


static func make_rule_result(ok: bool, status: StringName, actor_id: StringName = DEFAULT_ACTOR_ID, reason: String = "", effects: Array = [], messages: Array[String] = [], snapshot_delta: Dictionary = {}, settlement_log_entry: Dictionary = {}, rule_request_id: String = "", produced_events: Array = [], produced_transactions: Array = []) -> Dictionary:
	return {
		"ok": ok,
		"status": status,
		"rule_result": status,
		"rule_request_id": rule_request_id,
		"reason": reason,
		"blocked_reason": reason if not ok else "",
		"actor_id": actor_id,
		"effects": effects.duplicate(true),
		"produced_effects": effects.duplicate(true),
		"produced_events": produced_events.duplicate(true),
		"produced_transactions": produced_transactions.duplicate(true),
		"messages": messages.duplicate(true),
		"snapshot_delta": snapshot_delta.duplicate(true),
		"settlement_log_entry": settlement_log_entry.duplicate(true),
		"RulePreviewSummary": RuleEffectModifierSchemaScript.build_rule_preview_summary({
			"ok": ok,
			"status": status,
			"rule_result": status,
			"blocked_reason": reason if not ok else "",
			"effects": effects.duplicate(true),
		}, {"rule_id": status, "actor_id": actor_id, "rule_request_id": rule_request_id}),
		"EffectResultPreview": RuleEffectModifierSchemaScript.build_effect_result_summary([], effects.duplicate(true), reason if not ok else ""),
		"ContentDeliveryPreview": ContentDeliverySchemaScript.build_content_delivery_preview({}, {"context_id": "rule_result.%s" % str(status)}),
		"read_only_preview_summary": true,
	}


static func make_effect_spec(effect_type: StringName, source: String, target: Variant, payload: Dictionary, actor_id: StringName = DEFAULT_ACTOR_ID, command_id: String = "", rule_request_id: String = "", effect_id: String = "") -> Dictionary:
	var normalized_effect_id: String = effect_id
	if normalized_effect_id == "":
		var suffix: String = rule_request_id if rule_request_id != "" else String(actor_id)
		normalized_effect_id = "effect_%s_%s" % [String(effect_type).replace(".", "_"), suffix]
	return {
		"effect_id": normalized_effect_id,
		"type": effect_type,
		"source": source,
		"target": target,
		"payload": payload.duplicate(true),
		"actor_id": actor_id,
		"command_id": command_id,
		"rule_request_id": rule_request_id,
		"EffectDescriptor": RuleEffectModifierSchemaScript.default_effect_descriptor(effect_type),
		"EffectPreview": RuleEffectModifierSchemaScript.default_effect_preview(RuleEffectModifierSchemaScript.default_effect_descriptor(effect_type)),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func encounter_for_room(context: RunContext, room_type: StringName, pos: Vector2i) -> Dictionary:
	return EncounterResolverScript.get_encounter_identity(context, room_type, pos)


static func apply_search_reward(context: RunContext, pos: Vector2i, adjacent_mines: int, is_chest: bool) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"search_reward", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var request: Dictionary = _make_rule_request(context, &"search_reward", "search", {"pos": pos, "adjacent_mines": adjacent_mines, "is_chest": is_chest})
	var black_coin: int = RunRuleContent.default_search_black_coin(context, pos, adjacent_mines, is_chest)
	var modifier_black_coin_delta: int = _numeric_modifier_delta(context, &"search_reward", "black_coin")
	black_coin = maxi(0, black_coin + modifier_black_coin_delta)
	var item_defs: Array[Dictionary] = RunRuleContent.default_search_items(pos, adjacent_mines, is_chest, black_coin)
	var effects: Array = [
		_effect_for_request(request, 1, RunAssetEffectHandler.EFFECT_ADD_CURRENCY, "search", pos, {"currency_id": RunAssetLedger.CURRENCY_BLACK, "amount": black_coin}),
		_effect_for_request(request, 2, RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS, "search", pos, {"item_defs": item_defs, "preferred_location": RunAssetLedger.LOCATION_ROOM_FLOOR, "room_pos": pos}),
	]
	var applied: Dictionary = RunAssetEffectHandler.apply_effects(context, effects)
	var item_result: Dictionary = _effect_result(applied, RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS)
	var combined_items: Array = _combine_item_results(item_result)
	var log_entry: Dictionary = {"type": &"rule_result", "rule_result": &"search_reward", "black_coin": black_coin, "items": combined_items.size()}
	_append_rule_log(context, log_entry)
	var result: Dictionary = make_rule_result(true, &"search_reward", DEFAULT_ACTOR_ID, "", effects, ["Search reward resolved."], {}, log_entry)
	result["gold"] = black_coin
	result["black_coin_delta"] = black_coin
	result["modifier_black_coin_delta"] = modifier_black_coin_delta
	result["items"] = combined_items
	result["inventory_items"] = item_result.get("inventory_items", [])
	result["equipped_items"] = item_result.get("equipped_items", [])
	result["ground_items"] = item_result.get("ground_items", [])
	result["blocked_reason"] = item_result.get("blocked_reason", "")
	result["effect_results"] = applied.get("effect_results", [])
	return _finalize_rule(context, request, result, applied)


static func apply_combat_reward(context: RunContext, pos: Vector2i, reward_gold: int) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"combat_reward", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var request: Dictionary = _make_rule_request(context, &"combat_reward", "combat", {"pos": pos, "reward_gold": reward_gold})
	var item_defs: Array[Dictionary] = []
	if reward_gold >= 10:
		item_defs.append(RunRuleContent.monster_trophy(pos, reward_gold))
	var effects: Array = [
		_effect_for_request(request, 1, RunAssetEffectHandler.EFFECT_ADD_CURRENCY, "combat", pos, {"currency_id": RunAssetLedger.CURRENCY_BLACK, "amount": reward_gold}),
		_effect_for_request(request, 2, RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS, "combat", pos, {"item_defs": item_defs, "preferred_location": RunAssetLedger.LOCATION_ROOM_FLOOR, "room_pos": pos}),
	]
	var applied: Dictionary = RunAssetEffectHandler.apply_effects(context, effects)
	var item_result: Dictionary = _effect_result(applied, RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS)
	var result: Dictionary = make_rule_result(true, &"combat_reward", DEFAULT_ACTOR_ID, "", effects, ["Combat reward resolved."])
	result["reward_gold"] = reward_gold
	result["black_coin_delta"] = reward_gold
	result["items"] = _combine_item_results(item_result)
	result["ground_items"] = item_result.get("ground_items", [])
	result["blocked_reason"] = item_result.get("blocked_reason", "")
	result["effect_results"] = applied.get("effect_results", [])
	return _finalize_rule(context, request, result, applied)


static func apply_event_rule_result(context: RunContext, event_type: StringName, rule_result: Dictionary, fail_authority = null) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"event", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var request: Dictionary = _make_rule_request(context, &"event", "event_%s" % String(event_type), {"event_type": event_type, "rule_result": rule_result})
	var result: Dictionary = rule_result.duplicate(true)
	var run_effects: Array = []
	if result.has("hp_delta"):
		run_effects.append(RunEffectApplierScript.effect_hp_delta(int(result.get("hp_delta", 0)), "event_%s" % String(event_type)))
	if result.has("pressure_delta"):
		run_effects.append(RunEffectApplierScript.effect_protocol_pressure_delta(int(result.get("pressure_delta", 0)), "event_%s" % String(event_type)))
	if result.has("protocol_pressure_delta"):
		run_effects.append(RunEffectApplierScript.effect_protocol_pressure_delta(int(result.get("protocol_pressure_delta", 0)), "event_%s" % String(event_type)))
	var run_applied: Dictionary = RunEffectApplierScript.apply_effects(context, run_effects, fail_authority)
	if not bool(run_applied.get("ok", true)):
		var run_blocked: Dictionary = make_rule_result(false, &"event", DEFAULT_ACTOR_ID, String(run_applied.get("reason", "blocked")), run_effects, [String(result.get("message", "Event blocked."))])
		run_blocked["event_type"] = event_type
		run_blocked["effect_results"] = run_applied.get("effect_results", [])
		return run_blocked
	var effects: Array = []
	var effect_index: int = 1
	if result.has("spend_black_coin"):
		effects.append(_effect_for_request(request, effect_index, RunAssetEffectHandler.EFFECT_SPEND_CURRENCY, "event_%s" % String(event_type), context.get_current_pos(), {"currency_id": RunAssetLedger.CURRENCY_BLACK, "amount": int(result.get("spend_black_coin", 0))}))
		effect_index += 1
	if result.has("black_coin_delta"):
		effects.append(_effect_for_request(request, effect_index, RunAssetEffectHandler.EFFECT_ADD_CURRENCY, "event_%s" % String(event_type), context.get_current_pos(), {"currency_id": RunAssetLedger.CURRENCY_BLACK, "amount": int(result.get("black_coin_delta", 0))}))
		effect_index += 1
	if result.has("gold_coin_delta"):
		effects.append(_effect_for_request(request, effect_index, RunAssetEffectHandler.EFFECT_ADD_CURRENCY, "event_%s" % String(event_type), context.get_current_pos(), {"currency_id": RunAssetLedger.CURRENCY_GOLD, "amount": int(result.get("gold_coin_delta", 0))}))
		effect_index += 1
	var item_defs: Array = result.get("item_defs", [])
	if not item_defs.is_empty():
		var reward_location: StringName = StringName(result.get("reward_location", RunAssetLedger.LOCATION_ROOM_FLOOR))
		if bool(result.get("drop_on_floor", false)):
			reward_location = RunAssetLedger.LOCATION_ROOM_FLOOR
		effects.append(_effect_for_request(request, effect_index, RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS, "event_%s" % String(event_type), context.get_current_pos(), {"item_defs": item_defs, "preferred_location": reward_location, "room_pos": context.get_current_pos()}))
		effect_index += 1
	var status_effects: Array = result.get("status_effects", [])
	for effect in status_effects:
		effects.append(_effect_for_request(request, effect_index, RunAssetEffectHandler.EFFECT_ADD_STATUS_EFFECT, "event_%s" % String(event_type), context.get_current_pos(), {"effect": effect}))
		effect_index += 1
	var applied: Dictionary = RunAssetEffectHandler.apply_effects(context, effects)
	if not bool(applied.get("ok", false)):
		var blocked: Dictionary = make_rule_result(false, &"event", DEFAULT_ACTOR_ID, String(applied.get("reason", "blocked")), effects, [String(result.get("message", "Event blocked."))])
		blocked["event_type"] = event_type
		return blocked
	var item_result: Dictionary = _effect_result(applied, RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS)
	if not item_result.is_empty():
		result["items"] = _combine_item_results(item_result)
		result["inventory_items"] = item_result.get("inventory_items", [])
		result["equipped_items"] = item_result.get("equipped_items", [])
		result["ground_items"] = item_result.get("ground_items", [])
		result["blocked_reason"] = item_result.get("blocked_reason", "")
	var log_entry: Dictionary = {"type": &"rule_result", "rule_result": &"event", "event_type": event_type, "result": result.duplicate(true)}
	_append_rule_log(context, log_entry)
	var all_effects: Array = run_effects + effects
	result.merge(make_rule_result(bool(result.get("ok", true)), &"event", DEFAULT_ACTOR_ID, String(result.get("blocked_reason", "")), all_effects, [String(result.get("message", "Event resolved."))], {}, log_entry), false)
	result["effect_results"] = run_applied.get("effect_results", []) + applied.get("effect_results", [])
	var combined_applied: Dictionary = {
		"produced_transactions": run_applied.get("produced_transactions", []) + applied.get("produced_transactions", []),
		"transactions": run_applied.get("transactions", []) + applied.get("transactions", []),
		"effect_results": result["effect_results"],
	}
	return _finalize_rule(context, request, result, combined_applied)


static func execute_trader_sell_best(context: RunContext, confirm_high_value: bool = false) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"trader_sell", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var request: Dictionary = _make_rule_request(context, &"trader_sell", "event_trader", {"pos": context.get_current_pos(), "confirm_high_value": confirm_high_value})
	var effects: Array = [_effect_for_request(request, 1, RunAssetEffectHandler.EFFECT_SELL_BEST_INVENTORY_ITEM, "event_trader", context.get_current_pos(), {"confirm_high_value": confirm_high_value})]
	var applied: Dictionary = RunAssetEffectHandler.apply_effects(context, effects)
	var sold: Dictionary = _dictionary_from_variant(applied.get("last_result", {}))
	if not bool(sold.get("ok", false)):
		var reason: String = String(sold.get("reason", "no_sellable_inventory_item"))
		var blocked := make_rule_result(false, &"trader_sell", DEFAULT_ACTOR_ID, reason, effects, ["Trader sale blocked: %s." % reason])
		blocked["candidate_item"] = sold.get("candidate_item", {})
		blocked["message"] = "Trader sale blocked: %s." % reason
		return blocked
	var gold_coin: int = int(sold.get("gold_coin", 0))
	var result: Dictionary = make_rule_result(true, &"trader_sell", DEFAULT_ACTOR_ID, "", effects, ["Trader sale complete."])
	result["completed"] = true
	result["event_type"] = &"trader"
	result["gold_coin_delta"] = gold_coin
	result["safe_yield_delta"] = gold_coin
	result["safe_yield"] = context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_GOLD)
	result["safe_gold"] = gold_coin
	result["sold_item"] = sold.get("sold_item", {})
	result["message"] = "Trader sale complete: safe_yield +%d. Long-term gold writes only at settlement." % gold_coin
	return _finalize_rule(context, request, result, applied)


static func execute_trader_treatment(context: RunContext, cost: int, hp_restore: int) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"trader_treatment", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	if context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK) < cost:
		return make_rule_result(false, &"trader_treatment", DEFAULT_ACTOR_ID, "not_enough_black_coin", [], ["Trader treatment needs black_coin."])
	if context.hp >= context.max_hp:
		return make_rule_result(false, &"trader_treatment", DEFAULT_ACTOR_ID, "hp_already_full", [], ["Trader treatment needs missing HP."])
	return apply_event_rule_result(context, &"trader", {
		"ok": true,
		"completed": true,
		"event_type": &"trader",
		"spend_black_coin": cost,
		"hp_delta": hp_restore,
		"message": RunTextCatalog.trader_treatment_result(cost, hp_restore),
	})


static func execute_trader_info(context: RunContext, cost: int) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"trader_info", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	if context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK) < cost:
		return make_rule_result(false, &"trader_info", DEFAULT_ACTOR_ID, "not_enough_black_coin", [], ["Trader info needs black_coin."])
	return apply_event_rule_result(context, &"trader", {
		"ok": true,
		"completed": true,
		"event_type": &"trader",
		"spend_black_coin": cost,
		"status_effects": [{
			"effect_id": "trader_info_hint",
			"duration_type": &"current_run",
			"remaining": 1,
			"tags": ["info", "event", "trader"],
		}],
		"message": RunTextCatalog.trader_info_result(cost),
	})


static func execute_dice_bet(context: RunContext, pos: Vector2i, bet: int) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"dice_bet", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var request: Dictionary = _make_rule_request(context, &"dice_bet", "dice_bet", {"pos": pos, "bet": bet})
	var spend_effect: Dictionary = _effect_for_request(request, 1, RunAssetEffectHandler.EFFECT_SPEND_CURRENCY, "dice_bet", pos, {"currency_id": RunAssetLedger.CURRENCY_BLACK, "amount": bet})
	var spend_applied: Dictionary = RunAssetEffectHandler.apply_effects(context, [spend_effect])
	if not bool(spend_applied.get("ok", false)):
		var reason: String = String(spend_applied.get("reason", "blocked_currency"))
		var blocked: Dictionary = make_rule_result(false, &"dice_bet", DEFAULT_ACTOR_ID, reason, [spend_effect], ["Dice needs %d black_coin." % bet])
		blocked["message"] = "Dice needs %d black_coin." % bet
		return blocked
	var roll: int = absi((pos.x * 197 + pos.y * 83 + context.seed_value * 59 + context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK)) % 6) + 1
	var gain: int = 0
	if roll == 5:
		gain = bet + 20
	elif roll == 6:
		gain = bet + 60
	var gain_effect: Dictionary = _effect_for_request(request, 2, RunAssetEffectHandler.EFFECT_ADD_CURRENCY, "dice_reward", pos, {"currency_id": RunAssetLedger.CURRENCY_BLACK, "amount": gain})
	var gain_applied: Dictionary = RunAssetEffectHandler.apply_effects(context, [gain_effect])
	var delta: int = gain - bet
	var result: Dictionary = make_rule_result(true, &"dice_bet", DEFAULT_ACTOR_ID, "", [spend_effect, gain_effect], ["Dice bet resolved."])
	result["completed"] = true
	result["event_type"] = &"dice"
	result["roll"] = roll
	result["pending_gold_delta"] = delta
	result["black_coin_delta"] = delta
	result["message"] = "Dice roll %d: black_coin delta %d." % [roll, delta]
	result["effect_results"] = spend_applied.get("effect_results", []) + gain_applied.get("effect_results", [])
	var combined_applied: Dictionary = {
		"produced_transactions": spend_applied.get("produced_transactions", []) + gain_applied.get("produced_transactions", []),
		"transactions": spend_applied.get("transactions", []) + gain_applied.get("transactions", []),
	}
	return _finalize_rule(context, request, result, combined_applied)


static func pickup_ground_item(context: RunContext, instance_id: String = "") -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"pickup_ground_item", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var target_id: String = instance_id
	if target_id == "":
		var floor_items: Array[Dictionary] = context.asset_ledger.get_room_floor_items(context.get_current_pos())
		if floor_items.is_empty():
			return make_rule_result(false, &"pickup_ground_item", DEFAULT_ACTOR_ID, "no_room_floor_items", [], ["No room floor items."])
		target_id = String(floor_items[0].get("instance_id", ""))
	var request: Dictionary = _make_rule_request(context, &"pickup_ground_item", "pickup", {"instance_id": target_id, "room_pos": context.get_current_pos()})
	var effect: Dictionary = _effect_for_request(request, 1, RunAssetEffectHandler.EFFECT_PICKUP_GROUND_ITEM, "pickup", context.get_current_pos(), {"instance_id": target_id, "room_pos": context.get_current_pos()})
	var applied: Dictionary = RunAssetEffectHandler.apply_effects(context, [effect])
	var result: Dictionary = _dictionary_from_variant(applied.get("last_result", {}))
	result.merge(make_rule_result(bool(result.get("ok", false)), &"pickup_ground_item", DEFAULT_ACTOR_ID, String(result.get("reason", "")), [effect], [String(result.get("message", "Pickup resolved."))]), false)
	result["effect_results"] = applied.get("effect_results", [])
	return _finalize_rule(context, request, result, applied)


static func replace_ground_item(context: RunContext, ground_instance_id: String = "", drop_instance_id: String = "") -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"replace_ground_item", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var target_ground_id: String = ground_instance_id
	if target_ground_id == "":
		var floor_items: Array[Dictionary] = context.asset_ledger.get_room_floor_items(context.get_current_pos())
		if floor_items.is_empty():
			return make_rule_result(false, &"replace_ground_item", DEFAULT_ACTOR_ID, "no_room_floor_items", [], ["No room floor items."])
		target_ground_id = String(floor_items[0].get("instance_id", ""))
	var request: Dictionary = _make_rule_request(context, &"replace_ground_item", "replace", {"ground_instance_id": target_ground_id, "drop_instance_id": drop_instance_id, "room_pos": context.get_current_pos()})
	var effect: Dictionary = _effect_for_request(request, 1, RunAssetEffectHandler.EFFECT_REPLACE_GROUND_ITEM, "replace", context.get_current_pos(), {"ground_instance_id": target_ground_id, "drop_instance_id": drop_instance_id, "room_pos": context.get_current_pos()})
	var applied: Dictionary = RunAssetEffectHandler.apply_effects(context, [effect])
	var result: Dictionary = _dictionary_from_variant(applied.get("last_result", {}))
	result.merge(make_rule_result(bool(result.get("ok", false)), &"replace_ground_item", DEFAULT_ACTOR_ID, String(result.get("reason", "")), [effect], [String(result.get("message", "Replace resolved."))]), false)
	result["effect_results"] = applied.get("effect_results", [])
	return _finalize_rule(context, request, result, applied)


static func drop_inventory_item(context: RunContext, instance_id: String = "") -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"drop_inventory_item", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var target_id: String = instance_id
	if target_id == "":
		var inventory_items: Array[Dictionary] = context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY)
		if inventory_items.is_empty():
			return make_rule_result(false, &"drop_inventory_item", DEFAULT_ACTOR_ID, "no_inventory_items", [], ["No inventory items."])
		target_id = String(inventory_items[0].get("instance_id", ""))
	var request: Dictionary = _make_rule_request(context, &"drop_inventory_item", "drop", {"instance_id": target_id, "room_pos": context.get_current_pos()})
	var effect: Dictionary = _effect_for_request(request, 1, RunAssetEffectHandler.EFFECT_DROP_INVENTORY_ITEM, "drop", context.get_current_pos(), {"instance_id": target_id, "room_pos": context.get_current_pos()})
	var applied: Dictionary = RunAssetEffectHandler.apply_effects(context, [effect])
	var result: Dictionary = _dictionary_from_variant(applied.get("last_result", {}))
	result.merge(make_rule_result(bool(result.get("ok", false)), &"drop_inventory_item", DEFAULT_ACTOR_ID, String(result.get("reason", "")), [effect], [String(result.get("message", "Drop resolved."))]), false)
	result["effect_results"] = applied.get("effect_results", [])
	return _finalize_rule(context, request, result, applied)


static func use_consumable(context: RunContext, instance_id: String = "") -> Dictionary:
	if context == null or context.asset_ledger == null:
		return make_rule_result(false, &"use_consumable", DEFAULT_ACTOR_ID, "no_active_asset_ledger", [], ["No active asset ledger."])
	var target_id: String = instance_id
	if target_id == "":
		for item in context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY):
			if bool(item.get("can_consume", false)):
				target_id = String(item.get("instance_id", ""))
				break
	if target_id == "":
		return make_rule_result(false, &"use_consumable", DEFAULT_ACTOR_ID, "no_consumable_item", [], ["No consumable item in backpack."])
	var item_before := _find_inventory_item(context, target_id)
	if item_before.is_empty():
		return make_rule_result(false, &"use_consumable", DEFAULT_ACTOR_ID, "item_not_in_inventory", [], ["Item is not in backpack."])
	if not bool(item_before.get("can_consume", false)):
		return make_rule_result(false, &"use_consumable", DEFAULT_ACTOR_ID, "item_not_consumable", [], ["Item is not consumable."])
	var request: Dictionary = _make_rule_request(context, &"use_consumable", "consumable", {"instance_id": target_id, "item": item_before})
	var effects: Array = [_effect_for_request(request, 1, RunAssetEffectHandler.EFFECT_CONSUME_INVENTORY_ITEM, "consumable", context.get_current_pos(), {"instance_id": target_id})]
	var applied: Dictionary = RunAssetEffectHandler.apply_effects(context, effects)
	var consume_result: Dictionary = _dictionary_from_variant(applied.get("last_result", {}))
	if not bool(consume_result.get("ok", false)):
		var reason := String(consume_result.get("reason", "consume_blocked"))
		return make_rule_result(false, &"use_consumable", DEFAULT_ACTOR_ID, reason, effects, ["Consumable use blocked."])
	var run_effects: Array = []
	var extra_result: Dictionary = _apply_consumable_effect(context, item_before, run_effects)
	var log_entry: Dictionary = {"type": &"rule_result", "rule_result": &"use_consumable", "item": item_before.duplicate(true), "effect_kind": item_before.get("effect_kind", ""), "effect_result": extra_result.duplicate(true)}
	_append_rule_log(context, log_entry)
	var result: Dictionary = make_rule_result(true, &"use_consumable", DEFAULT_ACTOR_ID, "", effects + run_effects, ["Consumable used."], {}, log_entry)
	result["item"] = item_before.duplicate(true)
	result["consumed_item"] = consume_result.get("item", item_before)
	result["effect_kind"] = String(item_before.get("effect_kind", ""))
	result["effect_amount"] = int(item_before.get("effect_amount", 0))
	result["effect_result"] = extra_result
	result["effect_results"] = applied.get("effect_results", []) + extra_result.get("effect_results", [])
	result["message"] = _consumable_message(item_before, extra_result)
	return _finalize_rule(context, request, result, applied)


static func settle_success(context: RunContext) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {}
	var request: Dictionary = _make_rule_request(context, &"settle_success", "settlement", {"outcome": &"success"})
	var effect: Dictionary = _effect_for_request(request, 1, RunAssetEffectHandler.EFFECT_SETTLE_SUCCESS, "settlement", context.get_current_pos(), {})
	var applied: Dictionary = RunAssetEffectHandler.apply_effects(context, [effect])
	var result: Dictionary = _dictionary_from_variant(applied.get("last_result", {}))
	result.merge(make_rule_result(true, &"settle_success", DEFAULT_ACTOR_ID, "", [effect], ["Success settlement resolved."]), false)
	return _finalize_rule(context, request, result, applied)


static func settle_failure(context: RunContext) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {}
	var request: Dictionary = _make_rule_request(context, &"settle_failure", "settlement", {"outcome": &"failure"})
	var effect: Dictionary = _effect_for_request(request, 1, RunAssetEffectHandler.EFFECT_SETTLE_FAILURE, "settlement", context.get_current_pos(), {})
	var applied: Dictionary = RunAssetEffectHandler.apply_effects(context, [effect])
	var result: Dictionary = _dictionary_from_variant(applied.get("last_result", {}))
	result.merge(make_rule_result(true, &"settle_failure", DEFAULT_ACTOR_ID, "", [effect], ["Failure settlement resolved."]), false)
	return _finalize_rule(context, request, result, applied)


static func settle_abandon(context: RunContext, reason: String = "abandoned") -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {}
	var request: Dictionary = _make_rule_request(context, &"settle_abandon", "settlement", {"outcome": &"abandon", "reason": reason})
	var effect: Dictionary = _effect_for_request(request, 1, RunAssetEffectHandler.EFFECT_SETTLE_ABANDON, "settlement", context.get_current_pos(), {"reason": reason})
	var applied: Dictionary = RunAssetEffectHandler.apply_effects(context, [effect])
	var result: Dictionary = _dictionary_from_variant(applied.get("last_result", {}))
	result.merge(make_rule_result(true, &"settle_abandon", DEFAULT_ACTOR_ID, "", [effect], ["Abandon settlement resolved."]), false)
	return _finalize_rule(context, request, result, applied)


static func _find_inventory_item(context: RunContext, instance_id: String) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {}
	for item in context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY):
		if String(item.get("instance_id", "")) == instance_id:
			return item.duplicate(true)
	return {}


static func _apply_consumable_effect(context: RunContext, item: Dictionary, run_effects: Array) -> Dictionary:
	var effect_kind := String(item.get("effect_kind", ""))
	var amount := maxi(0, int(item.get("effect_amount", 0)))
	match effect_kind:
		"heal":
			run_effects.append(RunEffectApplierScript.effect_hp_delta(amount, "consumable_heal"))
			return RunEffectApplierScript.apply_effects(context, run_effects)
		"pressure_reduce":
			run_effects.append(RunEffectApplierScript.effect_protocol_pressure_delta(-amount, "consumable_pressure_reduce"))
			return RunEffectApplierScript.apply_effects(context, run_effects)
		"heal_pressure_reduce":
			run_effects.append(RunEffectApplierScript.effect_hp_delta(amount, "consumable_heal"))
			run_effects.append(RunEffectApplierScript.effect_protocol_pressure_delta(-maxi(0, int(item.get("pressure_amount", amount))), "consumable_pressure_reduce"))
			return RunEffectApplierScript.apply_effects(context, run_effects)
		"scan":
			var revealed := _reveal_nearby_for_consumable(context)
			context.record_event(&"consumable_scan", String(context.active_command.get("command_id", "")), DEFAULT_ACTOR_ID, "consumable", {"revealed": revealed, "item_id": item.get("item_id", "")})
			return {"ok": true, "status": &"scan_applied", "revealed": revealed, "effect_results": []}
		"mine_immunity":
			context.mine_immunity += maxi(1, amount)
			context.record_event(&"consumable_mine_immunity", String(context.active_command.get("command_id", "")), DEFAULT_ACTOR_ID, "consumable", {"mine_immunity": context.mine_immunity, "item_id": item.get("item_id", "")})
			return {"ok": true, "status": &"mine_immunity_applied", "mine_immunity": context.mine_immunity, "effect_results": []}
		"salvage_capacity":
			context.asset_ledger.failure_salvage_capacity += maxi(1, amount)
			context.asset_ledger.sync_compat_fields(context)
			context.record_event(&"consumable_salvage_capacity", String(context.active_command.get("command_id", "")), DEFAULT_ACTOR_ID, "consumable", {"failure_salvage_capacity": context.asset_ledger.failure_salvage_capacity, "item_id": item.get("item_id", "")})
			return {"ok": true, "status": &"salvage_capacity_applied", "failure_salvage_capacity": context.asset_ledger.failure_salvage_capacity, "effect_results": []}
		"safe_yield":
			context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_GOLD, amount, "consumable_safe_yield")
			context.asset_ledger.sync_compat_fields(context)
			context.record_event(&"consumable_safe_yield", String(context.active_command.get("command_id", "")), DEFAULT_ACTOR_ID, "consumable", {"safe_yield_delta": amount, "item_id": item.get("item_id", "")})
			return {"ok": true, "status": &"safe_yield_applied", "safe_yield_delta": amount, "safe_yield": context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_GOLD), "effect_results": []}
	return {"ok": true, "status": &"no_effect", "effect_kind": effect_kind, "effect_results": []}


static func _reveal_nearby_for_consumable(context: RunContext) -> Array[Dictionary]:
	var revealed: Array[Dictionary] = []
	if context == null or context.truth_map == null or context.intel_map == null:
		return revealed
	var center: Vector2i = context.get_current_pos()
	var deltas: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for delta: Vector2i in deltas:
		var target: Vector2i = center + delta
		if not context.is_inside(target):
			continue
		context.intel_map.reveal_cell(target, context.truth_map)
		revealed.append({"x": target.x, "y": target.y, "room_type": context.truth_map.get_room_type(target)})
	return revealed


static func _consumable_message(item: Dictionary, effect_result: Dictionary) -> String:
	var name := String(item.get("display_name", item.get("item_id", "Consumable")))
	var effect_kind := String(item.get("effect_kind", ""))
	match effect_kind:
		"heal":
			return "Used %s: HP restored." % name
		"pressure_reduce":
			return "Used %s: protocol pressure reduced." % name
		"heal_pressure_reduce":
			return "Used %s: HP restored and protocol pressure reduced." % name
		"scan":
			return "Used %s: nearby rooms scanned." % name
		"mine_immunity":
			return "Used %s: mine immunity charge ready." % name
		"salvage_capacity":
			return "Used %s: failure salvage capacity increased." % name
		"safe_yield":
			return "Used %s: safe_yield +%d." % [name, int(effect_result.get("safe_yield_delta", 0))]
	return "Used %s." % name


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


static func _make_rule_request(context: RunContext, rule_id: StringName, source: String, payload: Dictionary = {}) -> Dictionary:
	var command: Dictionary = {}
	if context != null:
		command = context.active_command
	var actor_id: StringName = StringName(command.get("actor_id", DEFAULT_ACTOR_ID))
	var command_id: String = String(command.get("command_id", ""))
	if context != null and context.rule_pipeline != null:
		return context.rule_pipeline.make_rule_request(rule_id, actor_id, source, payload, command_id)
	return {
		"rule_request_id": "rule_%s_%s" % [String(rule_id), command_id],
		"rule_id": rule_id,
		"actor_id": actor_id,
		"source": source,
		"payload": payload.duplicate(true),
		"command_id": command_id,
		"sequence": 0,
	}


static func _numeric_modifier_delta(context: RunContext, rule_id: StringName, field_id: String) -> int:
	if context == null or context.rule_pipeline == null:
		return 0
	return context.rule_pipeline.numeric_delta_for_rule(rule_id, field_id)


static func _effect_for_request(request: Dictionary, index: int, effect_type: StringName, source: String, target: Variant, payload: Dictionary) -> Dictionary:
	var rule_request_id: String = String(request.get("rule_request_id", ""))
	return make_effect_spec(
		effect_type,
		source,
		target,
		payload,
		StringName(request.get("actor_id", DEFAULT_ACTOR_ID)),
		String(request.get("command_id", "")),
		rule_request_id,
		"%s_fx_%02d" % [rule_request_id, index]
	)


static func _finalize_rule(context: RunContext, request: Dictionary, result: Dictionary, applied: Dictionary = {}) -> Dictionary:
	var final_result: Dictionary = result.duplicate(true)
	var transactions: Array = _array_from_variant(applied.get("produced_transactions", applied.get("transactions", [])))
	final_result["rule_request_id"] = String(request.get("rule_request_id", ""))
	final_result["produced_transactions"] = transactions.duplicate(true)
	final_result["produced_events"] = []
	if context != null and context.rule_pipeline != null:
		var rule_context: Dictionary = context.rule_pipeline.make_rule_context(context, request)
		final_result = context.rule_pipeline.apply_modifiers(rule_context, final_result)
	final_result["RulePreviewSummary"] = RuleEffectModifierSchemaScript.build_rule_preview_summary(final_result, _dictionary_from_variant(final_result.get("rule_context", {})))
	final_result["EffectResultPreview"] = RuleEffectModifierSchemaScript.build_effect_result_summary(_array_from_variant(final_result.get("effect_results", [])), _array_from_variant(final_result.get("effects", [])), String(final_result.get("blocked_reason", final_result.get("reason", ""))))
	final_result["ContentDeliveryPreview"] = ContentDeliverySchemaScript.build_content_delivery_preview({}, {"context_id": "rule_result.%s" % str(final_result.get("rule_result", "preview"))})
	return final_result


static func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}


static func _array_from_variant(value: Variant) -> Array:
	if value is Array:
		return value.duplicate(true)
	return []
