extends RefCounted
class_name RunAssetLedger

# G8 rules layer: single run-scoped asset ledger.
# Warehouse Lite is a settlement snapshot only; this class performs no persistence.

const LOCATION_INVENTORY := &"inventory"
const LOCATION_EQUIPPED := &"equipped"
const LOCATION_ROOM_FLOOR := &"room_floor"
const LOCATION_WAREHOUSE := &"warehouse"
const LOCATION_SETTLEMENT_POOL := &"settlement_pool"
const LOCATION_LOST := &"lost"

const CURRENCY_BLACK := &"black_coin"
const CURRENCY_GOLD := &"gold_coin"
const RARITY_TIERS := [&"common", &"good", &"rare", &"epic", &"legendary", &"mythic", &"unique"]

var currency_definitions: Dictionary = {}
var currency_balances: Dictionary = {}
var item_instances: Dictionary = {}
var room_floor_items: Dictionary = {}
var status_effects: Array[Dictionary] = []
var settlement_log: Array[Dictionary] = []
var warehouse_lite: Array[Dictionary] = []
var backpack_capacity: int = 10
var failure_salvage_capacity: int = 1
var black_to_gold_rate: float = 1.0
var next_instance_index: int = 1


func setup(config: Dictionary) -> void:
	reset()
	backpack_capacity = int(config.get("backpack_capacity", 10))
	failure_salvage_capacity = int(config.get("failure_salvage_capacity", 1))
	black_to_gold_rate = float(config.get("black_to_gold_rate", 1.0))
	_define_default_currencies()


func reset() -> void:
	currency_definitions.clear()
	currency_balances.clear()
	item_instances.clear()
	room_floor_items.clear()
	status_effects.clear()
	settlement_log.clear()
	warehouse_lite.clear()
	backpack_capacity = 10
	failure_salvage_capacity = 1
	black_to_gold_rate = 1.0
	next_instance_index = 1


func _define_default_currencies() -> void:
	define_currency(CURRENCY_BLACK, "Black Coin", &"run", true, true, false, &"convert_on_extract")
	define_currency(CURRENCY_GOLD, "Gold Coin", &"meta", false, true, true, &"persist_or_snapshot")
	currency_balances[CURRENCY_BLACK] = int(currency_balances.get(CURRENCY_BLACK, 0))
	currency_balances[CURRENCY_GOLD] = int(currency_balances.get(CURRENCY_GOLD, 0))


func define_currency(currency_id: StringName, display_name: String, scope: StringName, can_gain_in_run: bool, can_spend_in_run: bool, can_persist_to_meta: bool, settlement_rule: StringName) -> void:
	currency_definitions[currency_id] = {
		"currency_id": currency_id,
		"display_name": display_name,
		"scope": scope,
		"can_gain_in_run": can_gain_in_run,
		"can_spend_in_run": can_spend_in_run,
		"can_persist_to_meta": can_persist_to_meta,
		"settlement_rule": settlement_rule,
	}


func add_currency(currency_id: StringName, amount: int, source: String = "") -> Dictionary:
	var next_amount: int = int(currency_balances.get(currency_id, 0)) + amount
	currency_balances[currency_id] = maxi(0, next_amount)
	var entry := {"type": &"currency_delta", "currency_id": currency_id, "amount": amount, "source": source}
	settlement_log.append(entry)
	return entry


func spend_currency(currency_id: StringName, amount: int, source: String = "") -> Dictionary:
	var current := int(currency_balances.get(currency_id, 0))
	if current < amount:
		return {"ok": false, "status": &"blocked_currency", "reason": "not_enough_%s" % String(currency_id), "currency_id": currency_id, "required": amount, "available": current}
	add_currency(currency_id, -amount, source)
	return {"ok": true, "currency_id": currency_id, "spent": amount}


func get_currency(currency_id: StringName) -> int:
	return int(currency_balances.get(currency_id, 0))


func create_item_instance(item_def: Dictionary, location_state: StringName, room_pos: Vector2i = Vector2i(-999, -999)) -> Dictionary:
	var instance_id := String(item_def.get("instance_id", "item_%04d_%s" % [next_instance_index, String(item_def.get("item_id", "unknown"))]))
	next_instance_index += 1
	var rarity := _normalize_rarity(StringName(item_def.get("rarity", &"common")))
	var item_type := StringName(item_def.get("item_type", &"recovered"))
	var unique_item := rarity == &"unique" or bool(item_def.get("is_unique", false))
	var normalized := {
		"instance_id": instance_id,
		"item_id": String(item_def.get("item_id", item_def.get("id", "unknown_item"))),
		"display_name": String(item_def.get("display_name", item_def.get("item_id", item_def.get("id", "Unknown Item")))),
		"item_type": item_type,
		"rarity": rarity,
		"weight": maxi(0, int(item_def.get("weight", 1))),
		"value_state": StringName(item_def.get("value_state", &"known_value")),
		"base_value": maxi(0, int(item_def.get("base_value", item_def.get("value", 0)))),
		"tags": item_def.get("tags", []).duplicate(true),
		"can_sell": false if unique_item else bool(item_def.get("can_sell", true)),
		"can_store": bool(item_def.get("can_store", true)),
		"can_equip": bool(item_def.get("can_equip", false)),
		"can_consume": bool(item_def.get("can_consume", false)),
		"is_unique": unique_item,
		"source": String(item_def.get("source", "")),
		"visual_only": bool(item_def.get("visual_only", false)),
		"location_state": location_state,
		"room_pos": room_pos,
	}
	item_instances[instance_id] = normalized
	if location_state == LOCATION_ROOM_FLOOR:
		_register_room_floor_item(instance_id, room_pos)
	return normalized.duplicate(true)


func add_reward_items(item_defs: Array, preferred_location: StringName, room_pos: Vector2i, source: String = "") -> Dictionary:
	var inventory_items: Array[Dictionary] = []
	var equipped_items: Array[Dictionary] = []
	var ground_items: Array[Dictionary] = []
	var blocked_reasons: Array[String] = []
	for raw_def in item_defs:
		var item_def: Dictionary = raw_def.duplicate(true)
		if source != "":
			item_def["source"] = source
		var target_location := StringName(item_def.get("reward_location", preferred_location))
		if target_location == LOCATION_ROOM_FLOOR:
			ground_items.append(create_item_instance(item_def, LOCATION_ROOM_FLOOR, room_pos))
			continue
		if target_location == LOCATION_EQUIPPED and bool(item_def.get("can_equip", false)):
			equipped_items.append(create_item_instance(item_def, LOCATION_EQUIPPED, room_pos))
			continue
		var capacity_check := can_fit_item(item_def)
		if bool(capacity_check.get("ok", false)):
			inventory_items.append(create_item_instance(item_def, LOCATION_INVENTORY, room_pos))
		else:
			var floor_item := create_item_instance(item_def, LOCATION_ROOM_FLOOR, room_pos)
			ground_items.append(floor_item)
			blocked_reasons.append(String(capacity_check.get("reason", "blocked_capacity")))
	return {
		"inventory_items": inventory_items,
		"equipped_items": equipped_items,
		"ground_items": ground_items,
		"blocked_reasons": blocked_reasons,
		"blocked_reason": "" if blocked_reasons.is_empty() else blocked_reasons[0],
	}


func can_fit_item(item_def: Dictionary) -> Dictionary:
	var weight := maxi(0, int(item_def.get("weight", 1)))
	var used := get_backpack_used()
	if used + weight > backpack_capacity:
		return {"ok": false, "status": &"blocked_capacity", "reason": "blocked_capacity", "used": used, "weight": weight, "capacity": backpack_capacity}
	return {"ok": true, "used": used, "weight": weight, "capacity": backpack_capacity}


func pickup_ground_item(instance_id: String, room_pos: Vector2i) -> Dictionary:
	if not item_instances.has(instance_id):
		return {"ok": false, "status": &"not_found", "reason": "item_not_found"}
	var item: Dictionary = item_instances[instance_id]
	if StringName(item.get("location_state", &"")) != LOCATION_ROOM_FLOOR:
		return {"ok": false, "status": &"not_on_floor", "reason": "item_not_on_room_floor"}
	if item.get("room_pos", Vector2i.ZERO) != room_pos:
		return {"ok": false, "status": &"wrong_room", "reason": "item_in_other_room"}
	var capacity_check := can_fit_item(item)
	if not bool(capacity_check.get("ok", false)):
		return {"ok": false, "status": &"blocked_capacity", "reason": "blocked_capacity", "item": item.duplicate(true), "capacity": get_capacity_snapshot()}
	_unregister_room_floor_item(instance_id, room_pos)
	item["location_state"] = LOCATION_INVENTORY
	item_instances[instance_id] = item
	settlement_log.append({"type": &"pickup", "instance_id": instance_id, "room_pos": room_pos})
	return {"ok": true, "status": &"picked_up", "item": item.duplicate(true), "capacity": get_capacity_snapshot()}


func drop_inventory_item(instance_id: String, room_pos: Vector2i) -> Dictionary:
	if not item_instances.has(instance_id):
		return {"ok": false, "status": &"not_found", "reason": "item_not_found"}
	var item: Dictionary = item_instances[instance_id]
	if StringName(item.get("location_state", &"")) != LOCATION_INVENTORY:
		return {"ok": false, "status": &"not_in_inventory", "reason": "item_not_in_inventory"}
	item["location_state"] = LOCATION_ROOM_FLOOR
	item["room_pos"] = room_pos
	item_instances[instance_id] = item
	_register_room_floor_item(instance_id, room_pos)
	settlement_log.append({"type": &"drop", "instance_id": instance_id, "room_pos": room_pos})
	return {"ok": true, "status": &"dropped", "item": item.duplicate(true), "capacity": get_capacity_snapshot()}


func equip_inventory_item(instance_id: String) -> Dictionary:
	if not item_instances.has(instance_id):
		return {"ok": false, "status": &"not_found", "reason": "item_not_found"}
	var item: Dictionary = item_instances[instance_id]
	if StringName(item.get("location_state", &"")) != LOCATION_INVENTORY:
		return {"ok": false, "status": &"not_in_inventory", "reason": "item_not_in_inventory"}
	if not bool(item.get("can_equip", false)):
		return {"ok": false, "status": &"blocked_type", "reason": "item_not_equippable"}
	item["location_state"] = LOCATION_EQUIPPED
	item_instances[instance_id] = item
	settlement_log.append({"type": &"equip", "instance_id": instance_id})
	return {"ok": true, "status": &"equipped", "item": item.duplicate(true), "capacity": get_capacity_snapshot()}


func unequip_item(instance_id: String) -> Dictionary:
	if not item_instances.has(instance_id):
		return {"ok": false, "status": &"not_found", "reason": "item_not_found"}
	var item: Dictionary = item_instances[instance_id]
	if StringName(item.get("location_state", &"")) != LOCATION_EQUIPPED:
		return {"ok": false, "status": &"not_equipped", "reason": "item_not_equipped"}
	var capacity_check := can_fit_item(item)
	if not bool(capacity_check.get("ok", false)):
		return {"ok": false, "status": &"blocked_capacity", "reason": "blocked_capacity", "item": item.duplicate(true), "capacity": get_capacity_snapshot()}
	item["location_state"] = LOCATION_INVENTORY
	item_instances[instance_id] = item
	settlement_log.append({"type": &"unequip", "instance_id": instance_id})
	return {"ok": true, "status": &"unequipped", "item": item.duplicate(true), "capacity": get_capacity_snapshot()}


func sell_best_inventory_item() -> Dictionary:
	var best_id := ""
	var best_value := -1
	for instance_id in item_instances.keys():
		var item: Dictionary = item_instances[instance_id]
		if StringName(item.get("location_state", &"")) != LOCATION_INVENTORY:
			continue
		if bool(item.get("can_sell", true)) == false:
			continue
		var value := int(item.get("base_value", 0))
		if value > best_value:
			best_value = value
			best_id = String(instance_id)
	if best_id == "":
		return {"ok": false, "status": &"no_item", "reason": "no_sellable_inventory_item"}
	var sold_item: Dictionary = item_instances[best_id]
	sold_item["location_state"] = LOCATION_LOST
	item_instances[best_id] = sold_item
	var price := maxi(1, int(floor(float(best_value) * 0.75)))
	add_currency(CURRENCY_GOLD, price, "trader")
	settlement_log.append({"type": &"sell_item", "instance_id": best_id, "gold_coin": price})
	return {"ok": true, "sold_item": sold_item.duplicate(true), "gold_coin": price}


func build_failure_preview() -> Dictionary:
	var candidates := _settlement_candidate_items()
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("base_value", 0)) > int(b.get("base_value", 0))
	)
	var remaining := failure_salvage_capacity
	var salvaged: Array[Dictionary] = []
	for item in candidates:
		var weight := int(item.get("weight", 1))
		if weight <= remaining:
			salvaged.append(item.duplicate(true))
			remaining -= weight
	return {
		"gold_coin": get_currency(CURRENCY_GOLD),
		"black_coin_lost": get_currency(CURRENCY_BLACK),
		"pending_gold_lost": get_currency(CURRENCY_BLACK),
		"salvage_capacity": failure_salvage_capacity,
		"salvaged_items": salvaged,
		"salvaged_item": {} if salvaged.is_empty() else salvaged[0],
		"salvaged_item_count": salvaged.size(),
		"settlement_pool": candidates,
		"lost_item_count": candidates.size(),
		"lost_item_value": _sum_item_value(candidates),
	}


func settle_success() -> Dictionary:
	var black_before := get_currency(CURRENCY_BLACK)
	var converted_gold := int(floor(float(black_before) * black_to_gold_rate))
	currency_balances[CURRENCY_BLACK] = 0
	if converted_gold > 0:
		add_currency(CURRENCY_GOLD, converted_gold, "extract_settlement")
	var extracted_items: Array[Dictionary] = []
	var consumed_items: Array[Dictionary] = []
	var floor_lost_items: Array[Dictionary] = []
	for instance_id in item_instances.keys():
		var item: Dictionary = item_instances[instance_id]
		var location := StringName(item.get("location_state", &""))
		if location in [LOCATION_INVENTORY, LOCATION_EQUIPPED]:
			if bool(item.get("can_consume", false)) or StringName(item.get("item_type", &"")) == &"consumable":
				item["location_state"] = LOCATION_LOST
				consumed_items.append(item.duplicate(true))
			else:
				item["location_state"] = LOCATION_WAREHOUSE
				extracted_items.append(item.duplicate(true))
				warehouse_lite.append(item.duplicate(true))
			item_instances[instance_id] = item
		elif location == LOCATION_ROOM_FLOOR:
			_unregister_room_floor_item(String(instance_id), item.get("room_pos", Vector2i.ZERO))
			item["location_state"] = LOCATION_LOST
			floor_lost_items.append(item.duplicate(true))
			item_instances[instance_id] = item
	var effect_result := settle_status_effects()
	settlement_log.append({"type": &"settle_success", "black_coin_converted": black_before, "gold_coin_gained": converted_gold})
	return {
		"outcome": &"success",
		"black_coin_converted": black_before,
		"gold_coin_gained": converted_gold,
		"currency_delta": {"black_coin": -black_before, "gold_coin": converted_gold},
		"extracted_items": extracted_items,
		"consumables_cleared": consumed_items,
		"room_floor_lost_items": floor_lost_items,
		"warehouse_lite": warehouse_lite.duplicate(true),
		"status_effects": effect_result,
		"settlement_log": settlement_log.duplicate(true),
	}


func settle_failure() -> Dictionary:
	var black_before := get_currency(CURRENCY_BLACK)
	currency_balances[CURRENCY_BLACK] = 0
	var candidates := _settlement_candidate_items()
	for candidate in candidates:
		var candidate_id := String(candidate.get("instance_id", ""))
		if item_instances.has(candidate_id):
			var pool_item: Dictionary = item_instances[candidate_id]
			pool_item["location_state"] = LOCATION_SETTLEMENT_POOL
			item_instances[candidate_id] = pool_item
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("base_value", 0)) > int(b.get("base_value", 0))
	)
	var remaining := failure_salvage_capacity
	var salvaged_items: Array[Dictionary] = []
	var lost_items: Array[Dictionary] = []
	var consumables_cleared: Array[Dictionary] = []
	var room_floor_lost_items: Array[Dictionary] = []
	for instance_id in item_instances.keys():
		var item: Dictionary = item_instances[instance_id]
		var location := StringName(item.get("location_state", &""))
		if location == LOCATION_ROOM_FLOOR:
			_unregister_room_floor_item(String(instance_id), item.get("room_pos", Vector2i.ZERO))
			item["location_state"] = LOCATION_LOST
			room_floor_lost_items.append(item.duplicate(true))
			item_instances[instance_id] = item
		elif location in [LOCATION_INVENTORY, LOCATION_EQUIPPED] and (bool(item.get("can_consume", false)) or StringName(item.get("item_type", &"")) == &"consumable"):
			item["location_state"] = LOCATION_LOST
			consumables_cleared.append(item.duplicate(true))
			item_instances[instance_id] = item
	for candidate in candidates:
		var candidate_id := String(candidate.get("instance_id", ""))
		if not item_instances.has(candidate_id):
			continue
		var item: Dictionary = item_instances[candidate_id]
		var weight := int(item.get("weight", 1))
		if weight <= remaining:
			item["location_state"] = LOCATION_WAREHOUSE
			salvaged_items.append(item.duplicate(true))
			warehouse_lite.append(item.duplicate(true))
			remaining -= weight
		else:
			item["location_state"] = LOCATION_LOST
			lost_items.append(item.duplicate(true))
		item_instances[candidate_id] = item
	var effect_result := settle_status_effects()
	settlement_log.append({"type": &"settle_failure", "black_coin_lost": black_before, "salvaged_item_count": salvaged_items.size()})
	return {
		"outcome": &"failure",
		"black_coin_lost": black_before,
		"pending_gold_lost": black_before,
		"gold_coin_retained": get_currency(CURRENCY_GOLD),
		"salvage_capacity": failure_salvage_capacity,
		"settlement_pool": candidates,
		"salvaged_items": salvaged_items,
		"salvaged_item": {} if salvaged_items.is_empty() else salvaged_items[0],
		"salvaged_item_count": salvaged_items.size(),
		"lost_items": lost_items,
		"lost_item_count": lost_items.size() + room_floor_lost_items.size() + consumables_cleared.size(),
		"lost_item_value": _sum_item_value(lost_items) + _sum_item_value(room_floor_lost_items) + _sum_item_value(consumables_cleared),
		"room_floor_lost_items": room_floor_lost_items,
		"consumables_cleared": consumables_cleared,
		"warehouse_lite": warehouse_lite.duplicate(true),
		"status_effects": effect_result,
		"settlement_log": settlement_log.duplicate(true),
	}


func settle_status_effects() -> Array[Dictionary]:
	var next_effects: Array[Dictionary] = []
	var settled: Array[Dictionary] = []
	for effect in status_effects:
		var next_effect := effect.duplicate(true)
		if StringName(next_effect.get("duration_type", &"current_run")) == &"current_run":
			next_effect["expired"] = true
		elif StringName(next_effect.get("duration_type", &"")) == &"run_count":
			next_effect["remaining"] = maxi(0, int(next_effect.get("remaining", 0)) - 1)
			next_effect["expired"] = int(next_effect.get("remaining", 0)) <= 0
		else:
			next_effect["expired"] = false
		settled.append(next_effect.duplicate(true))
		if not bool(next_effect.get("expired", false)):
			next_effects.append(next_effect)
	status_effects = next_effects
	return settled


func add_status_effect(effect: Dictionary) -> void:
	var normalized := {
		"effect_id": String(effect.get("effect_id", "effect_%d" % status_effects.size())),
		"duration_type": StringName(effect.get("duration_type", &"current_run")),
		"remaining": int(effect.get("remaining", 1)),
		"tags": effect.get("tags", []).duplicate(true),
		"can_persist_later": bool(effect.get("can_persist_later", false)),
	}
	status_effects.append(normalized)


func get_room_floor_items(pos: Vector2i) -> Array[Dictionary]:
	var key := room_key(pos)
	var items: Array[Dictionary] = []
	for instance_id in room_floor_items.get(key, []):
		if item_instances.has(instance_id):
			items.append(item_instances[instance_id].duplicate(true))
	return items


func get_items_by_location(location_state: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in item_instances.values():
		if StringName(item.get("location_state", &"")) == location_state:
			result.append(item.duplicate(true))
	return result


func get_inventory_and_equipped_items(include_consumables: bool = true) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in item_instances.values():
		var location := StringName(item.get("location_state", &""))
		if location in [LOCATION_INVENTORY, LOCATION_EQUIPPED]:
			if include_consumables or (not bool(item.get("can_consume", false)) and StringName(item.get("item_type", &"")) != &"consumable"):
				result.append(item.duplicate(true))
	return result


func get_backpack_used() -> int:
	var used := 0
	for item in item_instances.values():
		if StringName(item.get("location_state", &"")) == LOCATION_INVENTORY:
			used += int(item.get("weight", 0))
	return used


func get_capacity_snapshot() -> Dictionary:
	var used := get_backpack_used()
	return {"used": used, "capacity": backpack_capacity, "remaining": maxi(0, backpack_capacity - used)}


func get_public_snapshot(current_pos: Vector2i) -> Dictionary:
	var current_floor_items := get_room_floor_items(current_pos)
	return {
		"currencies": currency_balances.duplicate(true),
		"currency_definitions": currency_definitions.duplicate(true),
		"black_coin": get_currency(CURRENCY_BLACK),
		"gold_coin": get_currency(CURRENCY_GOLD),
		"backpack_capacity": backpack_capacity,
		"backpack_used": get_backpack_used(),
		"backpack_remaining": maxi(0, backpack_capacity - get_backpack_used()),
		"inventory_items": get_items_by_location(LOCATION_INVENTORY),
		"equipped_items": get_items_by_location(LOCATION_EQUIPPED),
		"room_floor_items": current_floor_items,
		"room_floor_item_count": current_floor_items.size(),
		"status_effects": status_effects.duplicate(true),
		"settlement_log": settlement_log.duplicate(true),
		"warehouse_lite": warehouse_lite.duplicate(true),
	}


func sync_compat_fields(context: RunContext) -> void:
	if context == null:
		return
	context.pending_gold = get_currency(CURRENCY_BLACK)
	context.safe_gold = get_currency(CURRENCY_GOLD)
	var compat_items := get_inventory_and_equipped_items(false)
	context.parts = compat_items.size()
	context.carried_items = compat_items


func room_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]


func _register_room_floor_item(instance_id: String, pos: Vector2i) -> void:
	var key := room_key(pos)
	if not room_floor_items.has(key):
		room_floor_items[key] = []
	if not room_floor_items[key].has(instance_id):
		room_floor_items[key].append(instance_id)


func _unregister_room_floor_item(instance_id: String, pos: Vector2i) -> void:
	var key := room_key(pos)
	if not room_floor_items.has(key):
		return
	room_floor_items[key].erase(instance_id)


func _settlement_candidate_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in item_instances.values():
		var location := StringName(item.get("location_state", &""))
		if not (location in [LOCATION_INVENTORY, LOCATION_EQUIPPED]):
			continue
		if bool(item.get("can_consume", false)) or StringName(item.get("item_type", &"")) == &"consumable":
			continue
		result.append(item.duplicate(true))
	return result


func _sum_item_value(items: Array) -> int:
	var total := 0
	for item in items:
		total += int(item.get("base_value", item.get("value", 0)))
	return total


func _normalize_rarity(rarity: StringName) -> StringName:
	if RARITY_TIERS.has(rarity):
		return rarity
	return &"common"
