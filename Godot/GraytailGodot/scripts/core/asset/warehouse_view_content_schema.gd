extends RefCounted
class_name WarehouseViewContentSchema

const ItemAssetContentSchemaScript := preload("res://scripts/core/asset/item_asset_content_schema.gd")

const SCHEMA_VERSION := 1
const SNAPSHOT_KIND := &"WarehouseViewContentSnapshot"


static func default_content_snapshot() -> Dictionary:
	var fixtures := ItemAssetContentSchemaScript.build_preview_fixtures()
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": SNAPSHOT_KIND,
		"snapshot_id": "warehouse.content.preview",
		"title": "WarehouseViewContentSnapshot preview",
		"item_asset_content_previews": fixtures,
		"category_groups": _group_by_category(fixtures),
		"source_context_groups": _group_by_source_context(fixtures),
		"reserved_slots": {
			"room_loot": _reserved_slot("room_loot"),
			"ground_loot": _reserved_slot("ground_loot"),
			"run_bag_item": _reserved_slot("run_bag_item"),
			"settlement_candidate": _reserved_slot("settlement_candidate"),
			"history_reference": _reserved_slot("history_reference"),
		},
		"display_summary": [
			"WarehouseViewContentSnapshot groups content previews only.",
			"It is not a real warehouse, runtime catalog, or ContentDB.",
		],
		"preview_only": true,
		"display_only": true,
		"read_only": true,
		"no_persistence": true,
		"not_runtime_catalog": true,
		"not_ContentDB": true,
	}


static func normalize_content_snapshot(data: Dictionary = {}) -> Dictionary:
	var result := default_content_snapshot()
	for key in data.keys():
		result[key] = _copy_value(data[key])
	result["schema_version"] = SCHEMA_VERSION
	result["schema_kind"] = SNAPSHOT_KIND
	result["item_asset_content_previews"] = _normalize_contents(result.get("item_asset_content_previews", []))
	result["category_groups"] = _group_by_category(result["item_asset_content_previews"])
	result["source_context_groups"] = _group_by_source_context(result["item_asset_content_previews"])
	_apply_boundary_flags(result)
	return result


static func build_deploy_prep_content_view() -> Dictionary:
	var snapshot := default_content_snapshot()
	snapshot["consumer"] = &"deploy_prep"
	snapshot["display_summary"] = [
		"DeployPrep may display carry/equipment/consumable content previews.",
		"It does not carry, equip, buy, claim, or mutate assets.",
	]
	return normalize_content_snapshot(snapshot)


static func build_long_term_content_view() -> Dictionary:
	var snapshot := default_content_snapshot()
	snapshot["consumer"] = &"long_term"
	snapshot["display_summary"] = [
		"LongTerm may display collection, appearance, codex, research, and gacha asset references.",
		"It does not own warehouse state or unlock content.",
	]
	return normalize_content_snapshot(snapshot)


static func build_settlement_content_view() -> Dictionary:
	var snapshot := default_content_snapshot()
	snapshot["consumer"] = &"settlement"
	snapshot["display_summary"] = [
		"Settlement may display candidates, returned, lost, cleared, converted, rescued, and history references.",
		"It does not write warehouse state.",
	]
	return normalize_content_snapshot(snapshot)


static func validate_content_snapshot(data: Dictionary) -> Dictionary:
	var snapshot := normalize_content_snapshot(data)
	var warnings: Array[String] = []
	if not bool(snapshot.get("read_only", false)):
		warnings.append("snapshot_must_be_read_only")
	if not bool(snapshot.get("not_runtime_catalog", false)):
		warnings.append("snapshot_must_not_be_runtime_catalog")
	var contents: Array = snapshot.get("item_asset_content_previews", [])
	for content in contents:
		if content is Dictionary:
			var validation: Dictionary = ItemAssetContentSchemaScript.validate_content_preview(content)
			for warning in validation.get("warnings", []):
				warnings.append("content:%s" % str(warning))
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func _reserved_slot(slot_id: String) -> Dictionary:
	return {
		"slot_id": slot_id,
		"state": &"reserved_preview",
		"message": "%s is interface reservation only." % slot_id,
		"preview_only": true,
		"display_only": true,
		"read_only": true,
		"no_persistence": true,
		"not_runtime_catalog": true,
	}


static func _normalize_contents(value: Variant) -> Array:
	var result: Array = []
	if not (value is Array):
		return result
	for item in value:
		if item is Dictionary:
			result.append(ItemAssetContentSchemaScript.normalize_content_preview(item))
	return result


static func _group_by_category(contents: Array) -> Dictionary:
	var groups := {}
	for category in ItemAssetContentSchemaScript.CONTENT_CATEGORIES:
		groups[str(category)] = []
	for content in contents:
		if content is Dictionary:
			var category_key := str(StringName(content.get("asset_category", ItemAssetContentSchemaScript.CATEGORY_SPECIAL)))
			if not groups.has(category_key):
				groups[category_key] = []
			(groups[category_key] as Array).append(str(content.get("asset_id", "")))
	return groups


static func _group_by_source_context(contents: Array) -> Dictionary:
	var groups := {}
	for source in ItemAssetContentSchemaScript.SOURCE_CONTEXTS:
		groups[str(source)] = []
	for content in contents:
		if content is Dictionary:
			var source_context: Dictionary = content.get("source_context", {})
			var source_key := str(StringName(source_context.get("source_type", ItemAssetContentSchemaScript.SOURCE_DEPLOY)))
			if not groups.has(source_key):
				groups[source_key] = []
			(groups[source_key] as Array).append(str(content.get("asset_id", "")))
	return groups


static func _apply_boundary_flags(target: Dictionary) -> void:
	target["preview_only"] = true
	target["display_only"] = true
	target["read_only"] = true
	target["no_persistence"] = true
	target["not_runtime_catalog"] = true
	target["not_ContentDB"] = true


static func _copy_value(value: Variant) -> Variant:
	if (value is Dictionary) or (value is Array):
		return value.duplicate(true)
	return value
