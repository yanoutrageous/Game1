extends RefCounted
class_name RunInventory


static func setup_stats(context: RunContext) -> void:
	if context == null:
		return
	context.run_stats = {
		"moves": 0,
		"searched_rooms": 0,
		"chest_rooms": 0,
		"mine_hits": 0,
		"mine_immunity_used": 0,
		"monsters_defeated": 0,
		"monster_power_bonus": 0,
		"combat_damage": 0,
		"events_completed": 0,
		"turns": 0,
	}


static func record_move(context: RunContext) -> void:
	if context == null:
		return
	context.turn += 1
	context.run_stats["moves"] = int(context.run_stats.get("moves", 0)) + 1
	context.run_stats["turns"] = context.turn


static func add_search_reward(context: RunContext, pos: Vector2i, adjacent_mines: int, is_chest: bool) -> Dictionary:
	if context == null:
		return {"ok": false}
	var base := abs((pos.x * 19 + pos.y * 23 + context.seed_value + context.turn) % 3)
	var gold := min(4, base + int(floor(float(adjacent_mines) / 2.0)))
	var items: Array[Dictionary] = []
	if is_chest:
		gold = min(11, 3 + abs((pos.x * 29 + pos.y * 11 + context.seed_value) % 5) + adjacent_mines)
		items.append({"id": "chest_part_%d_%d" % [pos.x, pos.y], "value": max(1, gold)})
		if adjacent_mines >= 2:
			items.append({"id": "risk_find_%d_%d" % [pos.x, pos.y], "value": adjacent_mines})
		context.run_stats["chest_rooms"] = int(context.run_stats.get("chest_rooms", 0)) + 1
	context.pending_gold += gold
	context.parts += items.size()
	context.carried_items.append_array(items)
	context.run_stats["searched_rooms"] = int(context.run_stats.get("searched_rooms", 0)) + 1
	return {"ok": true, "gold": gold, "items": items}


static func get_reward_summary(context: RunContext) -> Dictionary:
	if context == null:
		return {}
	return {
		"pending_gold": context.pending_gold,
		"safe_gold": context.safe_gold,
		"parts": context.parts,
		"carried_items": context.carried_items.size(),
		"stats": context.run_stats.duplicate(true),
	}
