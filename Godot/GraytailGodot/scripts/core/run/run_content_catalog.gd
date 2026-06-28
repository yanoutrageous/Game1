extends RefCounted
class_name RunContentCatalog

# M2 effect-first content boundary.
# IDs and placeholder rewards are centralized here so Lua/UE parity tuning does not scatter.

const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")


static func search_items(pos: Vector2i, adjacent_mines: int, is_chest: bool, black_coin: int) -> Array[Dictionary]:
	var seed_value := adjacent_mines * 11 + black_coin
	if is_chest:
		return M3ItemCatalogScript.deterministic_drop(&"chest", pos, seed_value, 2 if adjacent_mines >= 2 else 1)
	if adjacent_mines >= 2:
		return M3ItemCatalogScript.deterministic_drop(&"search", pos, seed_value, 1)
	return M3ItemCatalogScript.deterministic_drop(&"search", pos, seed_value + 3, 1)


static func monster_trophy(pos: Vector2i, reward_gold: int) -> Dictionary:
	var drops := M3ItemCatalogScript.deterministic_drop(&"monster", pos, reward_gold, 1)
	if drops.is_empty():
		return {}
	var drop: Dictionary = drops[0]
	drop["instance_id"] = "monster_drop_%d_%d_%s" % [pos.x, pos.y, String(drop.get("item_id", "item"))]
	return drop


static func altar_relic(context: RunContext) -> Dictionary:
	var turn := 0 if context == null else context.turn
	var drops := M3ItemCatalogScript.deterministic_drop(&"altar", Vector2i(turn, turn), turn, 1)
	if drops.is_empty():
		return {}
	var drop: Dictionary = drops[0]
	drop["instance_id"] = "altar_drop_%d_%s" % [turn, String(drop.get("item_id", "item"))]
	return drop


static func trap_cache(context: RunContext) -> Array[Dictionary]:
	var turn := 0 if context == null else context.turn
	return M3ItemCatalogScript.deterministic_drop(&"event", Vector2i(turn, turn + 1), turn, 2)


static func item_def(item_id: String, display_name: String, item_type: StringName, value: int, rarity: StringName, tags: Array) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"short_description": "M3 compatibility item definition.",
		"icon_fallback": "icon.%s.%s" % [String(item_type), item_id],
		"item_type": item_type,
		"main_type": item_type,
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
		"unique_drop_allowed": false,
		"reward_location": RunAssetLedger.LOCATION_ROOM_FLOOR,
	}
