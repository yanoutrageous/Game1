extends RefCounted
class_name RunRuleContent

# Minimal content-definition fallback for G8.1 rule hardening.
# Later ContentDB/Content Pack stages can replace these definitions by stable IDs.

const RunBalanceCatalogScript := preload("res://scripts/core/run/run_balance_catalog.gd")
const RunContentCatalogScript := preload("res://scripts/core/run/run_content_catalog.gd")


static func default_search_black_coin(context: RunContext, pos: Vector2i, adjacent_mines: int, is_chest: bool) -> int:
	return RunBalanceCatalogScript.search_black_coin(context, pos, adjacent_mines, is_chest)


static func default_search_items(pos: Vector2i, adjacent_mines: int, is_chest: bool, black_coin: int) -> Array[Dictionary]:
	return RunContentCatalogScript.search_items(pos, adjacent_mines, is_chest, black_coin)


static func monster_trophy(pos: Vector2i, reward_gold: int) -> Dictionary:
	return RunContentCatalogScript.monster_trophy(pos, reward_gold)


static func item_def(item_id: String, display_name: String, item_type: StringName, value: int, rarity: StringName, tags: Array) -> Dictionary:
	return RunContentCatalogScript.item_def(item_id, display_name, item_type, value, rarity, tags)
