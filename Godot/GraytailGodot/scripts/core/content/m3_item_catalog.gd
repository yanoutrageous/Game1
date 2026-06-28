extends RefCounted
class_name M3ItemCatalog

# M3 minimum item pack. Data is centralized so tuning later does not scatter
# display names, weights, value placeholders, source labels, or drop tables.

const TYPE_EQUIPMENT := &"equipment"
const TYPE_CONSUMABLE := &"consumable"
const TYPE_COLLECTIBLE := &"collectible"
const TYPE_SPECIAL := &"special"

const SOURCE_SEARCH := "search_drop"
const SOURCE_CHEST := "chest_drop"
const SOURCE_MONSTER := "monster_drop"
const SOURCE_EVENT := "event_drop"
const SOURCE_ALTAR := "altar_special_event"
const SOURCE_DEBUG := "debug_drop"


static func all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.append_array(equipment_items())
	result.append_array(consumable_items())
	result.append_array(collectible_items())
	result.append_array(monster_drop_items())
	result.append_array(special_items())
	return result


static func equipment_items() -> Array[Dictionary]:
	return [
		item("eq_scanner_frame", "Field Scanner Frame", TYPE_EQUIPMENT, "Reveals nearby risk hints when supported.", 2, 36, &"tier_2", ["equipment", "scanner"], SOURCE_CHEST, {"can_equip": true, "equipment_slot": "tool"}),
		item("eq_pressure_gasket", "Pressure Gasket", TYPE_EQUIPMENT, "A rugged seal that can support later pressure mitigation.", 2, 32, &"tier_2", ["equipment", "pressure"], SOURCE_CHEST, {"can_equip": true, "equipment_slot": "gear"}),
		item("eq_salvage_hook", "Salvage Hook", TYPE_EQUIPMENT, "Improves recovery handling in later tuning.", 2, 30, &"tier_2", ["equipment", "salvage"], SOURCE_SEARCH, {"can_equip": true, "equipment_slot": "tool"}),
		item("eq_shock_liner", "Shock Liner", TYPE_EQUIPMENT, "Protective liner reserved for mine damage tuning.", 3, 42, &"tier_3", ["equipment", "mine"], SOURCE_MONSTER, {"can_equip": true, "equipment_slot": "armor"}),
		item("eq_black_box", "Black Box Recorder", TYPE_EQUIPMENT, "Records loss and salvage context for settlement.", 2, 44, &"tier_3", ["equipment", "record"], SOURCE_EVENT, {"can_equip": true, "equipment_slot": "device"}),
		item("eq_carry_rig", "Carry Rig", TYPE_EQUIPMENT, "Backpack capacity interface placeholder.", 3, 48, &"tier_3", ["equipment", "capacity"], SOURCE_ALTAR, {"can_equip": true, "equipment_slot": "rig"}),
	]


static func consumable_items() -> Array[Dictionary]:
	return [
		item("con_med_patch", "Med Patch", TYPE_CONSUMABLE, "Use: restore HP through the effect path.", 1, 14, &"tier_1", ["consumable", "heal"], SOURCE_SEARCH, {"can_consume": true, "effect_kind": "heal", "effect_amount": 20}),
		item("con_sweep_charge", "Sweep Charge", TYPE_CONSUMABLE, "Use: creates scan feedback and logs a sweep transaction.", 1, 12, &"tier_1", ["consumable", "scan"], SOURCE_CHEST, {"can_consume": true, "effect_kind": "scan", "effect_amount": 1}),
		item("con_mine_shunt", "Mine Shunt", TYPE_CONSUMABLE, "Use: grants one mine immunity charge.", 1, 18, &"tier_2", ["consumable", "mine_immunity"], SOURCE_SEARCH, {"can_consume": true, "effect_kind": "mine_immunity", "effect_amount": 1}),
		item("con_pressure_foam", "Pressure Foam", TYPE_CONSUMABLE, "Use: reduces protocol pressure through the effect path.", 1, 16, &"tier_2", ["consumable", "pressure_reduce"], SOURCE_EVENT, {"can_consume": true, "effect_kind": "pressure_reduce", "effect_amount": 8}),
		item("con_rescue_tag", "Rescue Tag", TYPE_CONSUMABLE, "Use: increases failure salvage capacity for this run.", 1, 22, &"tier_3", ["consumable", "salvage_capacity"], SOURCE_MONSTER, {"can_consume": true, "effect_kind": "salvage_capacity", "effect_amount": 1}),
		item("con_secure_voucher", "Secure Voucher", TYPE_CONSUMABLE, "Use: converts a small run reward into safe yield.", 1, 20, &"tier_3", ["consumable", "safe_yield"], SOURCE_CHEST, {"can_consume": true, "effect_kind": "safe_yield", "effect_amount": 10}),
	]


static func collectible_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var names := [
		"Cracked Watch", "Broken Compass", "Tin Badge", "Faded Ticket",
		"Signal Marble", "Rust Key", "Old Ledger", "Glass Flower",
		"Amber Fuse", "Mercury Seal", "Hollow Coin", "Blue Thread",
		"Burnt Photograph", "Ivory Toggle", "Warm Fuse", "Copper Prayer",
		"Silent Bell", "Ceramic Eye", "Silver Wing", "Deep Archive Plate",
		"Golden Transit Token", "Red Station Seal", "Pale Crown Fragment", "Blacksite Relic Shard",
	]
	for index in range(names.size()):
		var level := int(floor(float(index) / 4.0)) + 1
		level = clampi(level, 1, 6)
		result.append(item(
			"col_%02d" % [index + 1],
			names[index],
			TYPE_COLLECTIBLE,
			"Collectible level %d salvage record." % level,
			1 + int(level >= 4),
			8 + level * 6,
			StringName("tier_%d" % level),
			["collectible", "level_%d" % level],
			SOURCE_SEARCH,
			{"collectible_level": level, "can_sell": true}
		))
	return result


static func monster_drop_items() -> Array[Dictionary]:
	return [
		item("mon_chitin_sample", "Chitin Sample", TYPE_SPECIAL, "Monster-only sample for later codex or research use.", 1, 24, &"tier_2", ["monster", "sample"], SOURCE_MONSTER),
		item("mon_echo_gland", "Echo Gland", TYPE_SPECIAL, "Recovered from an anomaly after combat.", 1, 30, &"tier_3", ["monster", "sample"], SOURCE_MONSTER),
		item("mon_iron_spine", "Iron Spine", TYPE_SPECIAL, "A heavy monster trophy with clear source provenance.", 2, 40, &"tier_3", ["monster", "trophy"], SOURCE_MONSTER),
		item("mon_pale_core", "Pale Core", TYPE_SPECIAL, "Rare monster core, still not a unique ordinary drop.", 2, 52, &"tier_4", ["monster", "core"], SOURCE_MONSTER),
		item("mon_storm_eye", "Storm Eye", TYPE_SPECIAL, "High-value monster material for later systems.", 2, 60, &"tier_4", ["monster", "core"], SOURCE_MONSTER),
	]


static func special_items() -> Array[Dictionary]:
	return [
		item("sp_altar_residue", "Altar Residue", TYPE_SPECIAL, "Special event material; unique rewards are reserved for future reward interfaces.", 1, 28, &"tier_3", ["special", "altar"], SOURCE_ALTAR),
		item("sp_trader_receipt", "Trader Receipt", TYPE_SPECIAL, "Safe-yield provenance record from a trader sale.", 0, 1, &"tier_1", ["special", "trader"], "trader"),
	]


static func drop_table(table_id: StringName) -> Array[Dictionary]:
	match table_id:
		&"search":
			return _take([collectible_items()[0], collectible_items()[4], consumable_items()[0], equipment_items()[2]], 4)
		&"chest":
			return _take([collectible_items()[8], collectible_items()[12], consumable_items()[1], consumable_items()[5], equipment_items()[0]], 5)
		&"monster":
			return monster_drop_items()
		&"event":
			return _take([collectible_items()[5], collectible_items()[9], consumable_items()[3], equipment_items()[4]], 4)
		&"altar":
			return [special_items()[0], consumable_items()[4], equipment_items()[5]]
		&"debug":
			return [debug_item()]
	return []


static func deterministic_drop(table_id: StringName, pos: Vector2i, seed_value: int, count: int = 1) -> Array[Dictionary]:
	var table := drop_table(table_id)
	var result: Array[Dictionary] = []
	if table.is_empty():
		return result
	for index in range(maxi(1, count)):
		var pick_index := absi(pos.x * 131 + pos.y * 71 + seed_value * 17 + index * 29 + String(table_id).hash()) % table.size()
		var picked := table[pick_index].duplicate(true)
		picked["drop_table_id"] = table_id
		picked["source"] = source_for_table(table_id)
		picked["reward_location"] = &"room_floor"
		result.append(picked)
	return result


static func debug_item() -> Dictionary:
	return item("debug_m3_test_cache", "Debug Test Cache", TYPE_COLLECTIBLE, "Debug-generated M3 test item; defaults to GroundLoot.", 1, 25, &"tier_2", ["debug", "collectible"], SOURCE_DEBUG)


static func item(item_id: String, display_name: String, item_type: StringName, short_description: String, weight: int, base_value: int, rarity: StringName, tags: Array, source: String, extra: Dictionary = {}) -> Dictionary:
	var result := {
		"item_id": item_id,
		"display_name": display_name,
		"short_description": short_description,
		"icon_fallback": "icon.%s.%s" % [String(item_type), item_id],
		"item_type": item_type,
		"main_type": item_type,
		"rarity": rarity,
		"collectible_level": int(extra.get("collectible_level", 0)),
		"weight": maxi(0, weight),
		"value_state": &"known_value",
		"base_value": maxi(0, base_value),
		"tags": tags.duplicate(true),
		"source": source,
		"source_label": source,
		"can_sell": bool(extra.get("can_sell", item_type == TYPE_COLLECTIBLE)),
		"can_store": true,
		"can_equip": bool(extra.get("can_equip", item_type == TYPE_EQUIPMENT)),
		"can_consume": bool(extra.get("can_consume", item_type == TYPE_CONSUMABLE)),
		"effect_kind": String(extra.get("effect_kind", "")),
		"effect_amount": int(extra.get("effect_amount", 0)),
		"is_unique": false,
		"unique_drop_allowed": false,
		"reward_location": &"room_floor",
	}
	for key in extra.keys():
		result[key] = extra[key]
	result["is_unique"] = false
	result["unique_drop_allowed"] = false
	return result


static func source_for_table(table_id: StringName) -> String:
	match table_id:
		&"search":
			return SOURCE_SEARCH
		&"chest":
			return SOURCE_CHEST
		&"monster":
			return SOURCE_MONSTER
		&"event":
			return SOURCE_EVENT
		&"altar":
			return SOURCE_ALTAR
		&"debug":
			return SOURCE_DEBUG
	return "unknown_drop"


static func _take(items: Array, _count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_value in items:
		if item_value is Dictionary:
			result.append((item_value as Dictionary).duplicate(true))
	return result
