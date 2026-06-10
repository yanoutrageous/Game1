extends RefCounted
class_name RunRuleContent

# Minimal content-definition fallback for G8.1 rule hardening.
# Later ContentDB/Content Pack stages can replace these definitions by stable IDs.


static func default_search_black_coin(context: RunContext, pos: Vector2i, adjacent_mines: int, is_chest: bool) -> int:
	var base: int = absi((pos.x * 19 + pos.y * 23 + context.seed_value + context.turn) % 3)
	if is_chest:
		return mini(11, 3 + absi((pos.x * 29 + pos.y * 11 + context.seed_value) % 5) + adjacent_mines)
	return mini(4, base + int(floor(float(adjacent_mines) / 2.0)))


static func default_search_items(pos: Vector2i, adjacent_mines: int, is_chest: bool, black_coin: int) -> Array[Dictionary]:
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


static func item_def(item_id: String, display_name: String, item_type: StringName, value: int, rarity: StringName, tags: Array) -> Dictionary:
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
