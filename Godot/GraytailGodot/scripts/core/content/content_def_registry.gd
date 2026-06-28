extends RefCounted
class_name ContentDefRegistry

# G8.2 stable ContentDef registry. Definitions are data only and never mutate state.

const ContentDeliverySchemaScript := preload("res://scripts/core/content/content_delivery_schema.gd")
const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")

const KIND_CURRENCY := &"CurrencyDef"
const KIND_ITEM := &"ItemDef"
const KIND_ENCOUNTER := &"EncounterDef"
const KIND_EFFECT := &"EffectDef"
const KIND_MODIFIER := &"ModifierDef"
const KIND_LOOT_TABLE := &"LootTableDef"

var definitions: Dictionary = {}


func setup_defaults() -> void:
	definitions.clear()
	register_content_def("currency.black_coin", KIND_CURRENCY, "currency.black_coin", ["currency", "run"], {"currency_id": &"black_coin", "scope": &"run"})
	register_content_def("currency.gold_coin", KIND_CURRENCY, "currency.gold_coin", ["currency", "meta"], {"currency_id": &"gold_coin", "scope": &"meta"})
	register_content_def("currency.safe_yield", KIND_CURRENCY, "currency.safe_yield", ["currency", "safe_yield"], {"currency_id": &"safe_yield", "scope": &"settlement"})
	register_content_def("currency.long_term_gold", KIND_CURRENCY, "currency.long_term_gold", ["currency", "meta"], {"currency_id": &"long_term_gold", "scope": &"meta"})
	for item_def in M3ItemCatalogScript.all_items():
		var item_id := String(item_def.get("item_id", "unknown"))
		register_content_def("item.%s" % item_id, KIND_ITEM, "item.%s" % item_id, item_def.get("tags", []), item_def)
	register_content_def("encounter.search_basic", KIND_ENCOUNTER, "encounter.search_basic", ["encounter", "search"], {"room_type": &"Normal"})
	register_content_def("encounter.chest_basic", KIND_ENCOUNTER, "encounter.chest_basic", ["encounter", "loot"], {"room_type": &"Chest"})
	register_content_def("effect.asset.add_currency", KIND_EFFECT, "effect.asset.add_currency", ["effect", "asset"], {"type": &"asset.add_currency"})
	register_content_def("effect.asset.move_item", KIND_EFFECT, "effect.asset.move_item", ["effect", "asset"], {"type": &"asset.move_item"})
	register_content_def("effect.asset.consume_item", KIND_EFFECT, "effect.asset.consume_item", ["effect", "asset", "consumable"], {"type": &"asset.consume_inventory_item"})
	register_content_def("modifier.capacity.none", KIND_MODIFIER, "modifier.capacity.none", ["modifier", "noop"], {"target_rule": &"pickup_ground_item", "operation": &"none"})
	for table_id in [&"search", &"chest", &"monster", &"event", &"altar", &"debug"]:
		var entries: Array[String] = []
		for item_def in M3ItemCatalogScript.drop_table(table_id):
			entries.append("item.%s" % String(item_def.get("item_id", "unknown")))
		register_content_def("loot.%s.default" % String(table_id), KIND_LOOT_TABLE, "loot.%s.default" % String(table_id), ["loot", String(table_id)], {"entries": entries, "default_location": &"room_floor", "unique_drop_allowed": false})


func register_content_def(content_id: String, kind: StringName, display_name_key: String, tags: Array, definition: Dictionary, schema_version: int = 1, deprecated_state: StringName = &"active") -> Dictionary:
	var content_def: Dictionary = {
		"content_id": content_id,
		"schema_version": schema_version,
		"kind": kind,
		"display_name_key": display_name_key,
		"tags": tags.duplicate(true),
		"definition": definition.duplicate(true),
		"deprecated_state": deprecated_state,
	}
	definitions[content_id] = content_def
	return content_def.duplicate(true)


func get_content_def(content_id: String) -> Dictionary:
	if not definitions.has(content_id):
		return {}
	return definitions[content_id].duplicate(true)


func get_defs_by_kind(kind: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for content_def in definitions.values():
		if StringName(content_def.get("kind", &"")) == kind:
			result.append(content_def.duplicate(true))
	return result


func snapshot() -> Dictionary:
	return definitions.duplicate(true)


func content_pool_preview() -> Dictionary:
	return ContentDeliverySchemaScript.build_registry_pool_preview(snapshot())


func content_delivery_preview(context: Dictionary = {}) -> Dictionary:
	return ContentDeliverySchemaScript.build_content_delivery_preview(content_pool_preview(), context)
