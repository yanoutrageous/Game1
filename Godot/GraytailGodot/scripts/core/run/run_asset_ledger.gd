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
const LOCATION_CONSUMED := &"consumed"
const LOCATION_CLEARED := &"cleared"

const CURRENCY_BLACK := &"black_coin"
const CURRENCY_GOLD := &"gold_coin"
const CURRENCY_SAFE_YIELD := &"gold_coin"
const CURRENCY_LONG_TERM_GOLD := &"long_term_gold"
const RARITY_TIERS := [&"common", &"good", &"rare", &"epic", &"legendary", &"mythic", &"unique"]

var currency_definitions: Dictionary = {}
var currency_balances: Dictionary = {}
var item_instances: Dictionary = {}
var room_floor_items: Dictionary = {}
var status_effects: Array[Dictionary] = []
var settlement_log: Array[Dictionary] = []
var warehouse_lite: Array[Dictionary] = []
var backpack_capacity: int = 10
var failure_salvage_capacity: int = 4
var black_to_gold_rate: float = 1.0
var next_instance_index: int = 1


func setup(config: Dictionary) -> void:
	reset()
	backpack_capacity = int(config.get("backpack_capacity", 10))
	failure_salvage_capacity = int(config.get("failure_salvage_capacity", 4))
	black_to_gold_rate = float(config.get("black_to_gold_rate", 1.0))
	_define_default_currencies()
	_add_starting_loadout(config)


func reset() -> void:
	currency_definitions.clear()
	currency_balances.clear()
	item_instances.clear()
	room_floor_items.clear()
	status_effects.clear()
	settlement_log.clear()
	warehouse_lite.clear()
	backpack_capacity = 10
	failure_salvage_capacity = 4
	black_to_gold_rate = 1.0
	next_instance_index = 1


func _define_default_currencies() -> void:
	define_currency(CURRENCY_BLACK, "Black Coin", &"run", true, true, false, &"convert_on_extract")
	define_currency(CURRENCY_GOLD, "Gold", &"settlement", true, true, true, &"retain_on_terminal_result")
	define_currency(CURRENCY_LONG_TERM_GOLD, "Long Term Gold", &"meta", false, false, true, &"write_after_settlement")
	currency_balances[CURRENCY_BLACK] = int(currency_balances.get(CURRENCY_BLACK, 0))
	currency_balances[CURRENCY_GOLD] = int(currency_balances.get(CURRENCY_GOLD, 0))
	currency_balances[CURRENCY_LONG_TERM_GOLD] = int(currency_balances.get(CURRENCY_LONG_TERM_GOLD, 0))


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
	var item_type := StringName(item_def.get("item_type", &"collectible"))
	var unique_item := rarity == &"unique" or bool(item_def.get("is_unique", false))
	var normalized := {
		"instance_id": instance_id,
		"item_id": String(item_def.get("item_id", item_def.get("id", "unknown_item"))),
		"display_name": String(item_def.get("display_name", item_def.get("item_id", item_def.get("id", "Unknown Item")))),
		"short_description": String(item_def.get("short_description", "")),
		"icon_fallback": String(item_def.get("icon_fallback", "")),
		"item_type": item_type,
		"main_type": StringName(item_def.get("main_type", item_type)),
		"rarity": rarity,
		"collectible_level": int(item_def.get("collectible_level", 0)),
		"weight": maxi(0, int(item_def.get("weight", 1))),
		"value_state": StringName(item_def.get("value_state", &"known_value")),
		"base_value": maxi(0, int(item_def.get("base_value", item_def.get("value", 0)))),
		"tags": item_def.get("tags", []).duplicate(true),
		"can_sell": false if unique_item else bool(item_def.get("can_sell", true)),
		"can_store": bool(item_def.get("can_store", true)),
		"can_equip": bool(item_def.get("can_equip", false)),
		"can_consume": bool(item_def.get("can_consume", false)),
		"effect_kind": String(item_def.get("effect_kind", "")),
		"effect_amount": int(item_def.get("effect_amount", 0)),
		"pressure_amount": int(item_def.get("pressure_amount", 0)),
		"equipment_slot": String(item_def.get("equipment_slot", "")),
		"is_unique": unique_item,
		"unique_drop_allowed": bool(item_def.get("unique_drop_allowed", false)),
		"source": String(item_def.get("source", "")),
		"source_label": String(item_def.get("source_label", item_def.get("source", ""))),
		"carry_in_equipment": bool(item_def.get("carry_in_equipment", false)),
		"carry_in_consumable": bool(item_def.get("carry_in_consumable", false)),
		"temporary_claim": bool(item_def.get("temporary_claim", false)),
		"registered_for_run": bool(item_def.get("registered_for_run", false)),
		"acquired_in_run": bool(item_def.get("acquired_in_run", false)),
		"equip_allowed_now": bool(item_def.get("equip_allowed_now", false)),
		"visual_only": bool(item_def.get("visual_only", false)),
		"location_state": location_state,
		"room_pos": room_pos,
	}
	if bool(normalized.get("carry_in_equipment", false)):
		normalized["registered_for_run"] = true
		normalized["equip_allowed_now"] = true
		normalized["acquired_in_run"] = false
	if bool(normalized.get("carry_in_consumable", false)):
		normalized["registered_for_run"] = true
		normalized["acquired_in_run"] = false
	if bool(normalized.get("acquired_in_run", false)) and bool(normalized.get("can_equip", false)):
		normalized["equip_allowed_now"] = false
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
		if not bool(item_def.get("registered_for_run", false)):
			item_def["acquired_in_run"] = true
			item_def["equip_allowed_now"] = false
		var target_location := StringName(item_def.get("reward_location", preferred_location))
		if bool(item_def.get("is_unique", false)) and not bool(item_def.get("unique_drop_allowed", false)):
			blocked_reasons.append("unique_not_allowed_in_ordinary_drop")
			continue
		if target_location == LOCATION_ROOM_FLOOR:
			ground_items.append(create_item_instance(item_def, LOCATION_ROOM_FLOOR, room_pos))
			continue
		if target_location == LOCATION_EQUIPPED and bool(item_def.get("can_equip", false)):
			target_location = LOCATION_INVENTORY
			blocked_reasons.append("equipment_requires_extraction_registration")
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


func replace_ground_item_with_inventory_item(ground_instance_id: String, drop_instance_id: String, room_pos: Vector2i) -> Dictionary:
	var target_ground_id := ground_instance_id
	if target_ground_id == "":
		var floor_items := get_room_floor_items(room_pos)
		if floor_items.is_empty():
			return {"ok": false, "status": &"not_found", "reason": "no_room_floor_items"}
		target_ground_id = String(floor_items[0].get("instance_id", ""))
	if not item_instances.has(target_ground_id):
		return {"ok": false, "status": &"not_found", "reason": "ground_item_not_found"}
	var ground_item: Dictionary = item_instances[target_ground_id]
	if StringName(ground_item.get("location_state", &"")) != LOCATION_ROOM_FLOOR:
		return {"ok": false, "status": &"not_on_floor", "reason": "ground_item_not_on_room_floor"}
	if ground_item.get("room_pos", Vector2i.ZERO) != room_pos:
		return {"ok": false, "status": &"wrong_room", "reason": "ground_item_in_other_room"}
	var target_drop_id := drop_instance_id
	if target_drop_id == "":
		target_drop_id = _replacement_drop_candidate_id(ground_item)
	if target_drop_id == "":
		return {"ok": false, "status": &"blocked_capacity", "reason": "no_replace_candidate", "ground_item": ground_item.duplicate(true), "capacity": get_capacity_snapshot()}
	if not item_instances.has(target_drop_id):
		return {"ok": false, "status": &"not_found", "reason": "drop_item_not_found"}
	var drop_item: Dictionary = item_instances[target_drop_id]
	if StringName(drop_item.get("location_state", &"")) != LOCATION_INVENTORY:
		return {"ok": false, "status": &"not_in_inventory", "reason": "drop_item_not_in_inventory"}
	var projected_used := get_backpack_used() - int(drop_item.get("weight", 0)) + int(ground_item.get("weight", 0))
	if projected_used > backpack_capacity:
		return {"ok": false, "status": &"blocked_capacity", "reason": "replacement_still_over_capacity", "ground_item": ground_item.duplicate(true), "drop_item": drop_item.duplicate(true), "capacity": get_capacity_snapshot()}
	var drop_result := drop_inventory_item(target_drop_id, room_pos)
	if not bool(drop_result.get("ok", false)):
		return drop_result
	var pickup_result := pickup_ground_item(target_ground_id, room_pos)
	if not bool(pickup_result.get("ok", false)):
		pickup_result["drop_result"] = drop_result
		return pickup_result
	var picked_item: Dictionary = pickup_result.get("item", ground_item)
	var dropped_item: Dictionary = drop_result.get("item", drop_item)
	settlement_log.append({"type": &"replace_ground_item", "picked_instance_id": target_ground_id, "dropped_instance_id": target_drop_id, "room_pos": room_pos})
	return {"ok": true, "status": &"replaced", "item": picked_item.duplicate(true), "dropped_item": dropped_item.duplicate(true), "ground_item": picked_item.duplicate(true), "capacity": get_capacity_snapshot()}


func consume_inventory_item(instance_id: String) -> Dictionary:
	if not item_instances.has(instance_id):
		return {"ok": false, "status": &"not_found", "reason": "item_not_found"}
	var item: Dictionary = item_instances[instance_id]
	if StringName(item.get("location_state", &"")) != LOCATION_INVENTORY:
		return {"ok": false, "status": &"not_in_inventory", "reason": "item_not_in_inventory"}
	if not bool(item.get("can_consume", false)):
		return {"ok": false, "status": &"blocked_type", "reason": "item_not_consumable", "item": item.duplicate(true)}
	item["location_state"] = LOCATION_CONSUMED
	item_instances[instance_id] = item
	settlement_log.append({"type": &"consume_item", "instance_id": instance_id, "item_id": item.get("item_id", ""), "effect_kind": item.get("effect_kind", "")})
	return {"ok": true, "status": &"consumed", "item": item.duplicate(true), "capacity": get_capacity_snapshot()}


func equip_inventory_item(instance_id: String) -> Dictionary:
	if not item_instances.has(instance_id):
		return {"ok": false, "status": &"not_found", "reason": "item_not_found"}
	var item: Dictionary = item_instances[instance_id]
	if StringName(item.get("location_state", &"")) != LOCATION_INVENTORY:
		return {"ok": false, "status": &"not_in_inventory", "reason": "item_not_in_inventory"}
	if not bool(item.get("can_equip", false)):
		return {"ok": false, "status": &"blocked_type", "reason": "item_not_equippable"}
	if not bool(item.get("registered_for_run", false)) and not bool(item.get("carry_in_equipment", false)):
		return {"ok": false, "status": &"blocked_registration", "reason": "equipment_requires_extraction_registration", "item": item.duplicate(true), "capacity": get_capacity_snapshot()}
	if not bool(item.get("equip_allowed_now", false)):
		return {"ok": false, "status": &"blocked_registration", "reason": "equipment_requires_extraction_registration", "item": item.duplicate(true), "capacity": get_capacity_snapshot()}
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


func get_best_sellable_inventory_item() -> Dictionary:
	var best_item: Dictionary = {}
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
			best_item = item.duplicate(true)
	return best_item


func sell_best_inventory_item(confirm_high_value: bool = false) -> Dictionary:
	var best_item := get_best_sellable_inventory_item()
	var best_id := String(best_item.get("instance_id", ""))
	var best_value := int(best_item.get("base_value", -1))
	if best_id == "":
		return {"ok": false, "status": &"no_item", "reason": "no_sellable_inventory_item"}
	if best_value >= RunBalanceCatalog.TRADER_HIGH_VALUE_CONFIRM_THRESHOLD and not confirm_high_value:
		return {"ok": false, "status": &"confirmation_required", "reason": "high_value_sale_requires_confirmation", "candidate_item": best_item, "threshold": RunBalanceCatalog.TRADER_HIGH_VALUE_CONFIRM_THRESHOLD}
	var sold_item: Dictionary = item_instances[best_id]
	sold_item["location_state"] = LOCATION_LOST
	item_instances[best_id] = sold_item
	var price := maxi(1, int(floor(float(best_value) * 0.75)))
	add_currency(CURRENCY_GOLD, price, "trader")
	settlement_log.append({"type": &"sell_item", "instance_id": best_id, "gold_coin": price})
	return {"ok": true, "sold_item": sold_item.duplicate(true), "gold_coin": price}


func build_failure_preview() -> Dictionary:
	var candidates := _settlement_candidate_items()
	var cleared_consumables := _terminal_consumables()
	return {
		"ok": true,
		"outcome": &"failure",
		"settlement_outcome": &"failure",
		"requires_salvage_selection": true,
		"finalized": false,
		"gold_coin": get_currency(CURRENCY_GOLD),
		"safe_yield": get_currency(CURRENCY_GOLD),
		"black_coin_lost": get_currency(CURRENCY_BLACK),
		"pending_gold_lost": get_currency(CURRENCY_BLACK),
		"salvage_capacity": failure_salvage_capacity,
		"selected_salvage_weight": 0,
		"salvaged_items": [],
		"salvaged_item": {},
		"salvaged_item_count": 0,
		"settlement_pool": candidates,
		"cleared_consumables": cleared_consumables,
		"cleared_consumable_count": cleared_consumables.size(),
		"lost_item_count": candidates.size(),
		"lost_item_value": _sum_item_value(candidates),
	}


func settle_success() -> Dictionary:
	var black_before := get_currency(CURRENCY_BLACK)
	var safe_before := get_currency(CURRENCY_GOLD)
	var converted_gold := int(floor(float(black_before) * black_to_gold_rate))
	var long_term_gold_gained := converted_gold + safe_before
	currency_balances[CURRENCY_BLACK] = 0
	if converted_gold > 0:
		add_currency(CURRENCY_GOLD, converted_gold, "extract_settlement")
	if long_term_gold_gained > 0:
		add_currency(CURRENCY_LONG_TERM_GOLD, long_term_gold_gained, "settlement_writeback_preview")
	var cleared_consumables := _clear_terminal_consumables()
	var extracted_items: Array[Dictionary] = []
	var floor_lost_items: Array[Dictionary] = []
	for instance_id in item_instances.keys():
		var item: Dictionary = item_instances[instance_id]
		var location := StringName(item.get("location_state", &""))
		if location in [LOCATION_INVENTORY, LOCATION_EQUIPPED]:
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
	settlement_log.append({"type": &"settle_success", "black_coin_converted": black_before, "safe_yield_retained": safe_before, "long_term_gold_gained": long_term_gold_gained})
	return {
		"ok": true,
		"finalized": true,
		"outcome": &"success",
		"settlement_outcome": &"success",
		"run_black_coin": black_before,
		"black_coin_converted": black_before,
		"run_black_coin_converted": black_before,
		"safe_yield": safe_before,
		"safe_yield_retained": safe_before,
		"safe_yield_state": &"retained",
		"gold_coin_gained": long_term_gold_gained,
		"long_term_gold_gained": long_term_gold_gained,
		"currency_semantics": _currency_semantics(),
		"currency_delta": {"black_coin": -black_before, "gold_coin": converted_gold, "safe_yield": safe_before, "long_term_gold": long_term_gold_gained},
		"extracted_items": extracted_items,
		"warehouse_items": extracted_items,
		"cleared_consumables": cleared_consumables,
		"cleared_consumable_count": cleared_consumables.size(),
		"room_floor_lost_items": floor_lost_items,
		"warehouse_lite": warehouse_lite.duplicate(true),
		"status_effects": effect_result,
		"settlement_log": settlement_log.duplicate(true),
	}


func settle_failure(selected_instance_ids: Array = []) -> Dictionary:
	var candidates := _settlement_candidate_items()
	var validation := _validate_salvage_selection(candidates, selected_instance_ids)
	if not bool(validation.get("ok", false)):
		return validation
	var black_before := get_currency(CURRENCY_BLACK)
	var safe_before := get_currency(CURRENCY_GOLD)
	currency_balances[CURRENCY_BLACK] = 0
	if safe_before > 0:
		add_currency(CURRENCY_LONG_TERM_GOLD, safe_before, "failure_safe_yield_writeback_preview")
	var selected_ids: Array = validation.get("selected_instance_ids", [])
	var selected_lookup: Dictionary = {}
	for selected_id in selected_ids:
		selected_lookup[String(selected_id)] = true
	var cleared_consumables := _clear_terminal_consumables()
	for candidate in candidates:
		var candidate_id := String(candidate.get("instance_id", ""))
		if item_instances.has(candidate_id):
			var pool_item: Dictionary = item_instances[candidate_id]
			pool_item["location_state"] = LOCATION_SETTLEMENT_POOL
			item_instances[candidate_id] = pool_item
	var salvaged_items: Array[Dictionary] = []
	var lost_items: Array[Dictionary] = []
	var room_floor_lost_items: Array[Dictionary] = []
	for instance_id in item_instances.keys():
		var item: Dictionary = item_instances[instance_id]
		var location := StringName(item.get("location_state", &""))
		if location == LOCATION_ROOM_FLOOR:
			_unregister_room_floor_item(String(instance_id), item.get("room_pos", Vector2i.ZERO))
			item["location_state"] = LOCATION_LOST
			room_floor_lost_items.append(item.duplicate(true))
			item_instances[instance_id] = item
	for candidate in candidates:
		var candidate_id := String(candidate.get("instance_id", ""))
		if not item_instances.has(candidate_id):
			continue
		var item: Dictionary = item_instances[candidate_id]
		if selected_lookup.has(candidate_id):
			item["location_state"] = LOCATION_WAREHOUSE
			salvaged_items.append(item.duplicate(true))
			warehouse_lite.append(item.duplicate(true))
		else:
			item["location_state"] = LOCATION_LOST
			lost_items.append(item.duplicate(true))
		item_instances[candidate_id] = item
	var effect_result := settle_status_effects()
	settlement_log.append({"type": &"settle_failure", "black_coin_lost": black_before, "safe_yield_retained": safe_before, "salvaged_item_count": salvaged_items.size()})
	return {
		"ok": true,
		"finalized": true,
		"requires_salvage_selection": false,
		"outcome": &"failure",
		"settlement_outcome": &"failure",
		"run_black_coin": black_before,
		"black_coin_lost": black_before,
		"pending_gold_lost": black_before,
		"safe_yield": safe_before,
		"safe_yield_retained": safe_before,
		"safe_yield_state": &"retained",
		"gold_coin_retained": safe_before,
		"gold_coin_gained": safe_before,
		"long_term_gold_gained": safe_before,
		"currency_semantics": _currency_semantics(),
		"salvage_capacity": failure_salvage_capacity,
		"selected_salvage_weight": int(validation.get("selected_weight", 0)),
		"settlement_pool": candidates,
		"salvaged_items": salvaged_items,
		"salvaged_item": {} if salvaged_items.is_empty() else salvaged_items[0],
		"salvaged_item_count": salvaged_items.size(),
		"lost_items": lost_items,
		"cleared_consumables": cleared_consumables,
		"cleared_consumable_count": cleared_consumables.size(),
		"lost_item_count": lost_items.size() + room_floor_lost_items.size() + cleared_consumables.size(),
		"lost_item_value": _sum_item_value(lost_items) + _sum_item_value(room_floor_lost_items) + _sum_item_value(cleared_consumables),
		"room_floor_lost_items": room_floor_lost_items,
		"warehouse_lite": warehouse_lite.duplicate(true),
		"status_effects": effect_result,
		"settlement_log": settlement_log.duplicate(true),
	}


func settle_abandon(reason: String = "abandoned") -> Dictionary:
	var black_before := get_currency(CURRENCY_BLACK)
	var safe_before := get_currency(CURRENCY_GOLD)
	currency_balances[CURRENCY_BLACK] = 0
	if safe_before > 0:
		add_currency(CURRENCY_LONG_TERM_GOLD, safe_before, "abandon_gold_writeback_preview")
	var cleared_consumables := _clear_terminal_consumables()
	var lost_items: Array[Dictionary] = []
	var room_floor_lost_items: Array[Dictionary] = []
	for instance_id in item_instances.keys():
		var item: Dictionary = item_instances[instance_id]
		var location := StringName(item.get("location_state", &""))
		if location == LOCATION_ROOM_FLOOR:
			_unregister_room_floor_item(String(instance_id), item.get("room_pos", Vector2i.ZERO))
			item["location_state"] = LOCATION_LOST
			room_floor_lost_items.append(item.duplicate(true))
			item_instances[instance_id] = item
		elif location in [LOCATION_INVENTORY, LOCATION_EQUIPPED]:
			item["location_state"] = LOCATION_LOST
			lost_items.append(item.duplicate(true))
			item_instances[instance_id] = item
	var effect_result := settle_status_effects()
	settlement_log.append({"type": &"settle_abandon", "reason": reason, "black_coin_lost": black_before, "gold_coin_retained": safe_before})
	return {
		"ok": true,
		"finalized": true,
		"outcome": &"abandon",
		"settlement_outcome": &"abandon",
		"reason": reason,
		"run_black_coin": black_before,
		"black_coin_lost": black_before,
		"safe_yield": safe_before,
		"safe_yield_retained": safe_before,
		"safe_yield_state": &"retained",
		"gold_coin_retained": safe_before,
		"gold_coin_gained": safe_before,
		"long_term_gold_gained": safe_before,
		"currency_semantics": _currency_semantics(),
		"salvage_capacity": 0,
		"salvaged_items": [],
		"salvaged_item_count": 0,
		"lost_items": lost_items,
		"cleared_consumables": cleared_consumables,
		"cleared_consumable_count": cleared_consumables.size(),
		"lost_item_count": lost_items.size() + room_floor_lost_items.size() + cleared_consumables.size(),
		"lost_item_value": _sum_item_value(lost_items) + _sum_item_value(room_floor_lost_items) + _sum_item_value(cleared_consumables),
		"room_floor_lost_items": room_floor_lost_items,
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


func _add_starting_loadout(config: Dictionary) -> void:
	var selected_equipment: Array = config.get("selected_equipment_items", [])
	var selected_consumables: Array = config.get("selected_consumable_items", [])
	for raw_item in selected_equipment:
		if raw_item is Dictionary:
			var item := create_item_instance(_starting_item_def(raw_item, "carry_in_equipment"), LOCATION_EQUIPPED)
			_apply_equipment_passive(item)
			settlement_log.append({"type": &"carry_in_equipment", "instance_id": item.get("instance_id", ""), "item_id": item.get("item_id", "")})
	for raw_item in selected_consumables:
		if raw_item is Dictionary:
			var item_def := _starting_item_def(raw_item, "carry_in_consumable")
			var capacity_check := can_fit_item(item_def)
			if bool(capacity_check.get("ok", false)):
				var item := create_item_instance(item_def, LOCATION_INVENTORY)
				settlement_log.append({"type": &"carry_in_consumable", "instance_id": item.get("instance_id", ""), "item_id": item.get("item_id", "")})
			else:
				settlement_log.append({"type": &"carry_in_blocked", "item_id": item_def.get("item_id", ""), "reason": capacity_check.get("reason", "blocked_capacity")})
	var talent_effects: Array = config.get("active_talent_effects", [])
	for effect in talent_effects:
		if effect is Dictionary:
			_apply_talent_passive(effect)


func _starting_item_def(raw_item: Dictionary, source: String) -> Dictionary:
	var result := raw_item.duplicate(true)
	result["source"] = String(result.get("source", source))
	result["source_label"] = String(result.get("source_label", source))
	result["reward_location"] = &"inventory"
	result["registered_for_run"] = true
	result["acquired_in_run"] = false
	result["equip_allowed_now"] = source == "carry_in_equipment"
	result["carry_in_equipment"] = source == "carry_in_equipment"
	result["carry_in_consumable"] = source == "carry_in_consumable"
	return result


func _apply_equipment_passive(item: Dictionary) -> void:
	var effect_kind := String(item.get("effect_kind", ""))
	var amount := int(item.get("effect_amount", 0))
	if effect_kind == "" or amount == 0:
		return
	# DeployConfig has already folded selected equipment into the final capacities.
	add_status_effect({
		"effect_id": "equipment_%s_%s" % [String(item.get("item_id", "item")), effect_kind],
		"duration_type": &"current_run",
		"remaining": 1,
		"tags": ["equipment", effect_kind],
	})
	settlement_log.append({"type": &"equipment_passive", "item_id": item.get("item_id", ""), "effect_kind": effect_kind, "effect_amount": amount})


func _apply_talent_passive(effect: Dictionary) -> void:
	var effect_kind := String(effect.get("effect_kind", ""))
	var amount := int(effect.get("effect_amount", 0))
	# DeployConfig has already folded active talents into the final capacities.
	if effect_kind != "" and amount != 0:
		add_status_effect({
			"effect_id": "talent_%s" % String(effect.get("talent_id", effect_kind)),
			"duration_type": &"current_run",
			"remaining": 1,
			"tags": ["talent", effect_kind],
		})
		settlement_log.append({"type": &"talent_passive", "talent_id": effect.get("talent_id", ""), "effect_kind": effect_kind, "effect_amount": amount})


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
		"currency_semantics": _currency_semantics(),
		"black_coin": get_currency(CURRENCY_BLACK),
		"gold_coin": get_currency(CURRENCY_GOLD),
		"run_black_coin": get_currency(CURRENCY_BLACK),
		"safe_yield": get_currency(CURRENCY_GOLD),
		"long_term_gold": get_currency(CURRENCY_LONG_TERM_GOLD),
		"long_term_gold_preview": get_currency(CURRENCY_LONG_TERM_GOLD),
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
	var compat_items := get_inventory_and_equipped_items(true)
	context.parts = compat_items.size()
	context.carried_items = compat_items


func _currency_semantics() -> Dictionary:
	return {
		"black_coin": "run black coin; converted or lost by settlement outcome",
		"safe_yield": "compatibility alias for gold_coin inside the run ledger",
		"gold_coin": "gold gained directly in-run; retained on every terminal outcome",
		"long_term_gold": "meta progression currency written after settlement",
	}


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
		if _is_consumable(item):
			continue
		result.append(item.duplicate(true))
	return result


func _terminal_consumables() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in item_instances.values():
		var location := StringName(item.get("location_state", &""))
		if location in [LOCATION_INVENTORY, LOCATION_EQUIPPED] and _is_consumable(item):
			result.append(item.duplicate(true))
	return result


func _clear_terminal_consumables() -> Array[Dictionary]:
	var cleared: Array[Dictionary] = []
	for instance_id in item_instances.keys():
		var item: Dictionary = item_instances[instance_id]
		var location := StringName(item.get("location_state", &""))
		if not (location in [LOCATION_INVENTORY, LOCATION_EQUIPPED]) or not _is_consumable(item):
			continue
		item["location_state"] = LOCATION_CLEARED
		item_instances[instance_id] = item
		cleared.append(item.duplicate(true))
		settlement_log.append({"type": &"clear_terminal_consumable", "instance_id": instance_id, "item_id": item.get("item_id", ""), "temporary_claim": item.get("temporary_claim", false)})
	return cleared


func _validate_salvage_selection(candidates: Array[Dictionary], selected_instance_ids: Array) -> Dictionary:
	var candidate_lookup: Dictionary = {}
	for item in candidates:
		candidate_lookup[String(item.get("instance_id", ""))] = item
	var normalized_ids: Array[String] = []
	var selected_weight := 0
	for raw_id in selected_instance_ids:
		var instance_id := String(raw_id)
		if instance_id == "" or normalized_ids.has(instance_id):
			return {"ok": false, "status": &"invalid_salvage_selection", "reason": "duplicate_or_empty_instance_id", "requires_salvage_selection": true, "finalized": false}
		if not candidate_lookup.has(instance_id):
			return {"ok": false, "status": &"invalid_salvage_selection", "reason": "instance_not_in_settlement_pool", "instance_id": instance_id, "requires_salvage_selection": true, "finalized": false}
		normalized_ids.append(instance_id)
		selected_weight += int((candidate_lookup[instance_id] as Dictionary).get("weight", 1))
	if selected_weight > failure_salvage_capacity:
		return {"ok": false, "status": &"blocked_salvage_capacity", "reason": "selected_weight_exceeds_salvage_capacity", "selected_weight": selected_weight, "salvage_capacity": failure_salvage_capacity, "requires_salvage_selection": true, "finalized": false}
	return {"ok": true, "selected_instance_ids": normalized_ids, "selected_weight": selected_weight}


func _is_consumable(item: Dictionary) -> bool:
	return bool(item.get("can_consume", false)) or StringName(item.get("item_type", &"")) == &"consumable"


func _sum_item_value(items: Array) -> int:
	var total := 0
	for item in items:
		total += int(item.get("base_value", item.get("value", 0)))
	return total


func _replacement_drop_candidate_id(ground_item: Dictionary) -> String:
	var ground_weight := int(ground_item.get("weight", 1))
	var current_used := get_backpack_used()
	var best_id := ""
	var best_value := 2147483647
	var best_weight := -1
	for instance_id in item_instances.keys():
		var item: Dictionary = item_instances[instance_id]
		if StringName(item.get("location_state", &"")) != LOCATION_INVENTORY:
			continue
		var item_weight := int(item.get("weight", 0))
		if current_used - item_weight + ground_weight > backpack_capacity:
			continue
		var item_value := int(item.get("base_value", 0))
		if item_value < best_value or (item_value == best_value and item_weight > best_weight):
			best_value = item_value
			best_weight = item_weight
			best_id = String(instance_id)
	return best_id


func _normalize_rarity(rarity: StringName) -> StringName:
	if RARITY_TIERS.has(rarity):
		return rarity
	return &"common"
