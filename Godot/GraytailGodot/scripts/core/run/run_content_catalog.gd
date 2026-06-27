extends RefCounted
class_name RunContentCatalog

# M2 effect-first content boundary.
# IDs and placeholder rewards are centralized here so Lua/UE parity tuning does not scatter.


static func search_items(pos: Vector2i, adjacent_mines: int, is_chest: bool, black_coin: int) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	if is_chest:
		items.append(item_def("chest_part_%d_%d" % [pos.x, pos.y], "Chest Salvage", &"recovered", maxi(1, black_coin), &"good", ["loot", "container"]))
		if adjacent_mines >= 2:
			items.append(item_def("risk_find_%d_%d" % [pos.x, pos.y], "Risk Salvage", &"recovered", adjacent_mines, &"rare", ["loot", "risk"]))
	elif adjacent_mines >= 2:
		items.append(item_def("scrap_%d_%d" % [pos.x, pos.y], "Locked Scrap", &"recovered", maxi(1, adjacent_mines), &"common", ["loot"]))
	return items


static func monster_trophy(pos: Vector2i, reward_gold: int) -> Dictionary:
	return item_def("monster_trophy_%d_%d" % [pos.x, pos.y], "Monster Trophy", &"recovered", maxi(1, int(floor(float(reward_gold) / 2.0))), &"good", ["monster", "combat"])


static func altar_relic(context: RunContext) -> Dictionary:
	var turn := 0 if context == null else context.turn
	return item_def("altar_relic_%d" % turn, "Altar Relic", &"recovered", 8, &"unique", ["altar", "event", "collection"])


static func trap_cache(context: RunContext) -> Array[Dictionary]:
	var turn := 0 if context == null else context.turn
	return [
		item_def("trap_cache_common_%d" % turn, "Mechanism Cache", &"recovered", 4, &"good", ["trap", "event"]),
		item_def("trap_cache_low_%d" % turn, "Mechanism Parts", &"recovered", 2, &"common", ["trap", "event"]),
	]


static func item_def(item_id: String, display_name: String, item_type: StringName, value: int, rarity: StringName, tags: Array) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"item_type": item_type,
		"rarity": rarity,
		"weight": 1,
		"value_state": &"known_value",
		"base_value": value,
		"tags": tags.duplicate(true),
		"can_sell": rarity != &"unique",
		"can_store": true,
		"can_equip": false,
		"can_consume": false,
		"is_unique": rarity == &"unique",
	}
