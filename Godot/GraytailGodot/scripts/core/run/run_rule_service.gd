extends RefCounted
class_name RunRuleService

# Default rule interface for G8. Encounters build RuleResult dictionaries;
# the ledger applies assets, locations, settlement pools, and compatibility mirrors.


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
		return {"ok": false, "message": "No active asset ledger."}
	var black_coin := _default_search_black_coin(context, pos, adjacent_mines, is_chest)
	var item_defs := _default_search_items(context, pos, adjacent_mines, is_chest, black_coin)
	context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, black_coin, "search")
	var item_result := context.asset_ledger.add_reward_items(item_defs, RunAssetLedger.LOCATION_INVENTORY, pos, "search")
	var combined_items := _combine_item_results(item_result)
	context.asset_ledger.sync_compat_fields(context)
	var result := {
		"ok": true,
		"rule_result": &"search_reward",
		"gold": black_coin,
		"black_coin_delta": black_coin,
		"items": combined_items,
		"inventory_items": item_result.get("inventory_items", []),
		"equipped_items": item_result.get("equipped_items", []),
		"ground_items": item_result.get("ground_items", []),
		"blocked_reason": item_result.get("blocked_reason", ""),
	}
	context.asset_ledger.settlement_log.append({"type": &"rule_result", "rule_result": &"search_reward", "black_coin": black_coin, "items": combined_items.size()})
	return result


static func apply_combat_reward(context: RunContext, pos: Vector2i, reward_gold: int) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {"ok": false, "message": "No active asset ledger."}
	var item_defs: Array[Dictionary] = []
	if reward_gold >= 10:
		item_defs.append(_item_def("monster_trophy_%d_%d" % [pos.x, pos.y], "Monster Trophy", &"recovered", maxi(1, int(floor(float(reward_gold) / 2.0))), &"good", ["monster", "combat"]))
	context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, reward_gold, "combat")
	var item_result := context.asset_ledger.add_reward_items(item_defs, RunAssetLedger.LOCATION_INVENTORY, pos, "combat")
	context.asset_ledger.sync_compat_fields(context)
	return {
		"ok": true,
		"rule_result": &"combat_reward",
		"reward_gold": reward_gold,
		"black_coin_delta": reward_gold,
		"items": _combine_item_results(item_result),
		"ground_items": item_result.get("ground_items", []),
		"blocked_reason": item_result.get("blocked_reason", ""),
	}


static func apply_event_rule_result(context: RunContext, event_type: StringName, rule_result: Dictionary) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {"ok": false, "message": "No active asset ledger."}
	var result := rule_result.duplicate(true)
	if result.has("spend_black_coin"):
		var spend_result := context.asset_ledger.spend_currency(RunAssetLedger.CURRENCY_BLACK, int(result.get("spend_black_coin", 0)), "event_%s" % String(event_type))
		if not bool(spend_result.get("ok", false)):
			context.asset_ledger.sync_compat_fields(context)
			return spend_result
	if result.has("black_coin_delta"):
		context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, int(result.get("black_coin_delta", 0)), "event_%s" % String(event_type))
	if result.has("gold_coin_delta"):
		context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_GOLD, int(result.get("gold_coin_delta", 0)), "event_%s" % String(event_type))
	var item_defs: Array = result.get("item_defs", [])
	if not item_defs.is_empty():
		var reward_location := StringName(result.get("reward_location", RunAssetLedger.LOCATION_INVENTORY))
		if bool(result.get("drop_on_floor", false)):
			reward_location = RunAssetLedger.LOCATION_ROOM_FLOOR
		var item_result := context.asset_ledger.add_reward_items(item_defs, reward_location, context.get_current_pos(), "event_%s" % String(event_type))
		result["items"] = _combine_item_results(item_result)
		result["inventory_items"] = item_result.get("inventory_items", [])
		result["equipped_items"] = item_result.get("equipped_items", [])
		result["ground_items"] = item_result.get("ground_items", [])
		result["blocked_reason"] = item_result.get("blocked_reason", "")
	var effects: Array = result.get("status_effects", [])
	for effect in effects:
		context.asset_ledger.add_status_effect(effect)
	context.asset_ledger.sync_compat_fields(context)
	context.asset_ledger.settlement_log.append({"type": &"rule_result", "rule_result": &"event", "event_type": event_type, "result": result.duplicate(true)})
	return result


static func execute_trader_sell_best(context: RunContext) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {"ok": false, "message": "No active asset ledger."}
	var sold := context.asset_ledger.sell_best_inventory_item()
	context.asset_ledger.sync_compat_fields(context)
	if not bool(sold.get("ok", false)):
		return {"ok": false, "message": "No sellable inventory item.", "blocked_reason": sold.get("reason", "no_sellable_inventory_item")}
	var gold_coin := int(sold.get("gold_coin", 0))
	return {"ok": true, "completed": true, "event_type": &"trader", "gold_coin_delta": gold_coin, "safe_gold": gold_coin, "sold_item": sold.get("sold_item", {}), "message": "Trader sale complete: gold_coin +%d." % gold_coin}


static func execute_dice_bet(context: RunContext, pos: Vector2i, bet: int) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {"ok": false, "message": "No active asset ledger."}
	var spend_result := context.asset_ledger.spend_currency(RunAssetLedger.CURRENCY_BLACK, bet, "dice_bet")
	if not bool(spend_result.get("ok", false)):
		context.asset_ledger.sync_compat_fields(context)
		return {"ok": false, "message": "Dice needs %d black_coin." % bet, "blocked_reason": spend_result.get("reason", "blocked_currency")}
	var roll := absi((pos.x * 197 + pos.y * 83 + context.seed_value * 59 + context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK)) % 6) + 1
	var gain := 0
	if roll == 5:
		gain = bet + 20
	elif roll == 6:
		gain = bet + 60
	context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, gain, "dice_reward")
	context.asset_ledger.sync_compat_fields(context)
	var delta := gain - bet
	return {"ok": true, "completed": true, "event_type": &"dice", "roll": roll, "pending_gold_delta": delta, "black_coin_delta": delta, "message": "Dice roll %d: black_coin delta %d." % [roll, delta]}


static func pickup_ground_item(context: RunContext, instance_id: String = "") -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {"ok": false, "message": "No active asset ledger."}
	var target_id := instance_id
	if target_id == "":
		var floor_items := context.asset_ledger.get_room_floor_items(context.get_current_pos())
		if floor_items.is_empty():
			return {"ok": false, "status": &"not_found", "reason": "no_room_floor_items", "message": "No room floor items."}
		target_id = String(floor_items[0].get("instance_id", ""))
	var result := context.asset_ledger.pickup_ground_item(target_id, context.get_current_pos())
	context.asset_ledger.sync_compat_fields(context)
	return result


static func drop_inventory_item(context: RunContext, instance_id: String = "") -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {"ok": false, "message": "No active asset ledger."}
	var target_id := instance_id
	if target_id == "":
		var inventory_items := context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY)
		if inventory_items.is_empty():
			return {"ok": false, "status": &"not_found", "reason": "no_inventory_items", "message": "No inventory items."}
		target_id = String(inventory_items[0].get("instance_id", ""))
	var result := context.asset_ledger.drop_inventory_item(target_id, context.get_current_pos())
	context.asset_ledger.sync_compat_fields(context)
	return result


static func settle_success(context: RunContext) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {}
	var result := context.asset_ledger.settle_success()
	context.asset_ledger.sync_compat_fields(context)
	return result


static func settle_failure(context: RunContext) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {}
	var result := context.asset_ledger.settle_failure()
	context.asset_ledger.sync_compat_fields(context)
	return result


static func _default_search_black_coin(context: RunContext, pos: Vector2i, adjacent_mines: int, is_chest: bool) -> int:
	var base: int = absi((pos.x * 19 + pos.y * 23 + context.seed_value + context.turn) % 3)
	if is_chest:
		return mini(11, 3 + absi((pos.x * 29 + pos.y * 11 + context.seed_value) % 5) + adjacent_mines)
	return mini(4, base + int(floor(float(adjacent_mines) / 2.0)))


static func _default_search_items(_context: RunContext, pos: Vector2i, adjacent_mines: int, is_chest: bool, black_coin: int) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	if is_chest:
		items.append(_item_def("chest_part_%d_%d" % [pos.x, pos.y], "Chest Salvage", &"recovered", maxi(1, black_coin), &"good", ["loot", "container"]))
		if adjacent_mines >= 2:
			items.append(_item_def("risk_find_%d_%d" % [pos.x, pos.y], "Risk Salvage", &"recovered", adjacent_mines, &"rare", ["loot", "risk"]))
	elif adjacent_mines >= 2:
		items.append(_item_def("scrap_%d_%d" % [pos.x, pos.y], "Locked Scrap", &"recovered", maxi(1, adjacent_mines), &"common", ["loot"]))
	return items


static func _item_def(item_id: String, display_name: String, item_type: StringName, value: int, rarity: StringName, tags: Array) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"item_type": item_type,
		"rarity": rarity,
		"weight": 1,
		"value_state": &"known_value",
		"base_value": value,
		"tags": tags,
		"can_sell": rarity != &"unique",
		"can_store": true,
		"can_equip": false,
		"can_consume": false,
		"is_unique": rarity == &"unique",
	}


static func _combine_item_results(item_result: Dictionary) -> Array:
	var combined: Array = []
	combined.append_array(item_result.get("inventory_items", []))
	combined.append_array(item_result.get("equipped_items", []))
	combined.append_array(item_result.get("ground_items", []))
	return combined
