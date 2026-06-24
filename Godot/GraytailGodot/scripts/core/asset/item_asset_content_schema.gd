extends RefCounted
class_name ItemAssetContentSchema

const SCHEMA_VERSION := 1
const CONTENT_KIND := &"ItemAssetContentPreview"

const CATEGORY_RESOURCE := &"resource"
const CATEGORY_EQUIPMENT := &"equipment"
const CATEGORY_CONSUMABLE := &"consumable"
const CATEGORY_MATERIAL := &"material"
const CATEGORY_COLLECTIBLE := &"collectible"
const CATEGORY_UNLOCK := &"unlock"
const CATEGORY_APPEARANCE := &"appearance"
const CATEGORY_SPECIAL := &"special"
const CONTENT_CATEGORIES := [
	CATEGORY_RESOURCE,
	CATEGORY_EQUIPMENT,
	CATEGORY_CONSUMABLE,
	CATEGORY_MATERIAL,
	CATEGORY_COLLECTIBLE,
	CATEGORY_UNLOCK,
	CATEGORY_APPEARANCE,
	CATEGORY_SPECIAL,
]

const SOURCE_DEPLOY := &"deploy"
const SOURCE_MAP := &"map"
const SOURCE_ROOM := &"room"
const SOURCE_EVENT := &"event"
const SOURCE_COMBAT := &"combat"
const SOURCE_CHEST := &"chest"
const SOURCE_OBJECTIVE := &"objective"
const SOURCE_SETTLEMENT := &"settlement"
const SOURCE_HISTORY := &"history"
const SOURCE_GACHA := &"gacha"
const SOURCE_CONTEXTS := [
	SOURCE_DEPLOY,
	SOURCE_MAP,
	SOURCE_ROOM,
	SOURCE_EVENT,
	SOURCE_COMBAT,
	SOURCE_CHEST,
	SOURCE_OBJECTIVE,
	SOURCE_SETTLEMENT,
	SOURCE_HISTORY,
	SOURCE_GACHA,
]

const POLICY_PREVIEW_ONLY := &"preview_only"
const POLICY_DISPLAY_ONLY := &"display_only"
const POLICY_BLOCKED_RUNTIME := &"blocked_runtime"


static func default_content_preview(asset_id: String = "preview_asset", category: StringName = CATEGORY_SPECIAL) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": CONTENT_KIND,
		"asset_id": asset_id,
		"asset_category": category,
		"item_main_type": category,
		"display_name_key": "asset.%s.name" % asset_id,
		"description_key": "asset.%s.description" % asset_id,
		"icon_key": "asset.%s.icon" % asset_id,
		"rarity_key": "asset.rarity.preview",
		"source_context": default_source_context(SOURCE_DEPLOY),
		"content_tags": [],
		"display_policy": default_policy("display_policy"),
		"warehouse_view_policy": default_policy("warehouse_view_policy"),
		"deploy_policy": default_policy("deploy_policy"),
		"settlement_policy": default_policy("settlement_policy"),
		"history_policy": default_policy("history_policy"),
		"reward_reference_policy": default_policy("reward_reference_policy"),
		"run_presence_policy": default_policy("run_presence_policy"),
		"map_visibility_policy": default_policy("map_visibility_policy"),
		"room_loot_policy": default_policy("room_loot_policy"),
		"fixture_note": "ItemAssetContentPreview is a review fixture, not runtime catalog or ContentDB.",
		"preview_only": true,
		"display_only": true,
		"read_only": true,
		"no_persistence": true,
		"not_runtime_catalog": true,
		"not_ContentDB": true,
	}


static func default_source_context(source_type: StringName = SOURCE_DEPLOY) -> Dictionary:
	return {
		"source_type": source_type,
		"source_id": "source.%s.preview" % str(source_type),
		"source_label_key": "asset.source.%s" % str(source_type),
		"preview_only": true,
		"display_only": true,
		"read_only": true,
	}


static func default_policy(policy_name: String = "policy") -> Dictionary:
	return {
		"policy_name": policy_name,
		"policy_state": POLICY_PREVIEW_ONLY,
		"display_key": "asset.%s.preview" % policy_name,
		"allows_runtime_mutation": false,
		"allows_reward_grant": false,
		"allows_persistence": false,
		"preview_only": true,
		"display_only": true,
		"read_only": true,
	}


static func build_preview_fixtures() -> Array:
	return [
		default_content_preview("black_coin_preview", CATEGORY_RESOURCE),
		default_content_preview("field_knife_preview", CATEGORY_EQUIPMENT),
		default_content_preview("first_aid_preview", CATEGORY_CONSUMABLE),
		default_content_preview("ore_sample_preview", CATEGORY_MATERIAL),
		default_content_preview("sealed_relic_preview", CATEGORY_COLLECTIBLE),
		default_content_preview("codex_unlock_preview", CATEGORY_UNLOCK),
		default_content_preview("cloak_appearance_preview", CATEGORY_APPEARANCE),
		default_content_preview("commission_token_preview", CATEGORY_SPECIAL),
	]


static func normalize_content_preview(data: Dictionary = {}) -> Dictionary:
	var result := default_content_preview()
	for key in data.keys():
		result[key] = _copy_value(data[key])
	result["schema_version"] = SCHEMA_VERSION
	result["schema_kind"] = CONTENT_KIND
	result["asset_id"] = str(result.get("asset_id", "preview_asset"))
	result["asset_category"] = StringName(result.get("asset_category", CATEGORY_SPECIAL))
	result["item_main_type"] = StringName(result.get("item_main_type", result.get("asset_category", CATEGORY_SPECIAL)))
	result["display_name_key"] = str(result.get("display_name_key", "asset.preview.name"))
	result["description_key"] = str(result.get("description_key", "asset.preview.description"))
	result["icon_key"] = str(result.get("icon_key", "asset.preview.icon"))
	result["rarity_key"] = str(result.get("rarity_key", "asset.rarity.preview"))
	result["source_context"] = normalize_source_context(_dictionary_from(result.get("source_context", {})))
	result["content_tags"] = _array_from(result.get("content_tags", []))
	for policy_key in _policy_keys():
		result[policy_key] = normalize_policy(_dictionary_from(result.get(policy_key, default_policy(policy_key))))
	_apply_boundary_flags(result)
	return result


static func normalize_source_context(data: Dictionary = {}) -> Dictionary:
	var result := default_source_context()
	for key in data.keys():
		result[key] = _copy_value(data[key])
	result["source_type"] = StringName(result.get("source_type", SOURCE_DEPLOY))
	result["source_id"] = str(result.get("source_id", "source.preview"))
	result["source_label_key"] = str(result.get("source_label_key", "asset.source.preview"))
	_apply_boundary_flags(result)
	return result


static func normalize_policy(data: Dictionary = {}) -> Dictionary:
	var result := default_policy()
	for key in data.keys():
		result[key] = _copy_value(data[key])
	result["policy_name"] = str(result.get("policy_name", "policy"))
	result["policy_state"] = StringName(result.get("policy_state", POLICY_PREVIEW_ONLY))
	result["allows_runtime_mutation"] = false
	result["allows_reward_grant"] = false
	result["allows_persistence"] = false
	_apply_boundary_flags(result)
	return result


static func validate_content_preview(data: Dictionary) -> Dictionary:
	var content := normalize_content_preview(data)
	var warnings: Array[String] = []
	if not CONTENT_CATEGORIES.has(StringName(content.get("asset_category", &""))):
		warnings.append("unknown_asset_category")
	var source_context: Dictionary = content.get("source_context", {})
	if not SOURCE_CONTEXTS.has(StringName(source_context.get("source_type", &""))):
		warnings.append("unknown_source_context")
	if not bool(content.get("read_only", false)):
		warnings.append("content_preview_must_be_read_only")
	if not bool(content.get("not_runtime_catalog", false)):
		warnings.append("content_preview_must_not_be_runtime_catalog")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func _policy_keys() -> Array:
	return [
		"display_policy",
		"warehouse_view_policy",
		"deploy_policy",
		"settlement_policy",
		"history_policy",
		"reward_reference_policy",
		"run_presence_policy",
		"map_visibility_policy",
		"room_loot_policy",
	]


static func _apply_boundary_flags(target: Dictionary) -> void:
	target["preview_only"] = true
	target["display_only"] = true
	target["read_only"] = true
	target["no_persistence"] = true
	target["not_runtime_catalog"] = true
	target["not_ContentDB"] = true


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}


static func _array_from(value: Variant) -> Array:
	if value is Array:
		return value.duplicate(true)
	return []


static func _copy_value(value: Variant) -> Variant:
	if (value is Dictionary) or (value is Array):
		return value.duplicate(true)
	return value
