extends RefCounted
class_name AssetDomainContract

const SCHEMA_VERSION := 1

const ASSET_REF_KIND := &"AssetRef"
const ASSET_CATEGORY_KIND := &"AssetCategory"
const ASSET_TAG_KIND := &"AssetTag"
const ASSET_POLICY_KIND := &"AssetPolicy"

const CATEGORY_ITEM := &"item"
const CATEGORY_RESOURCE := &"resource"
const CATEGORY_COLLECTIBLE := &"collectible"
const CATEGORY_SPECIAL := &"special"
const CATEGORY_COSMETIC_UNLOCK := &"cosmetic_unlock"
const CATEGORY_RECORD_UNLOCK := &"record_unlock"
const CATEGORIES := [
	CATEGORY_ITEM,
	CATEGORY_RESOURCE,
	CATEGORY_COLLECTIBLE,
	CATEGORY_SPECIAL,
	CATEGORY_COSMETIC_UNLOCK,
	CATEGORY_RECORD_UNLOCK,
]

const POLICY_DISPLAY_ONLY := &"display_only"
const POLICY_ALLOWED_PREVIEW := &"allowed_preview"
const POLICY_BLOCKED_REAL_ACTION := &"blocked_real_action"


static func boundary_flags() -> Dictionary:
	return {
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_asset_ref(asset_id: String = "", category: StringName = CATEGORY_ITEM) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": ASSET_REF_KIND,
		"asset_id": asset_id,
		"definition_id": asset_id,
		"instance_id": "",
		"category": category,
		"display_key": "asset.%s" % asset_id if not asset_id.is_empty() else "asset.preview",
		"source_context_id": "",
		"state_tags": [],
		"quantity": 1,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_category(category_id: StringName = CATEGORY_ITEM) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": ASSET_CATEGORY_KIND,
		"category_id": category_id,
		"display_key": "asset.category.%s" % str(category_id),
		"description_key": "asset.category.%s.description" % str(category_id),
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_tag(tag_id: String = "", tag_type: StringName = &"state") -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": ASSET_TAG_KIND,
		"tag_id": tag_id,
		"tag_type": tag_type,
		"display_key": "asset.tag.%s" % tag_id if not tag_id.is_empty() else "asset.tag.preview",
		"source_context_id": "",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_policy(policy_id: StringName = POLICY_DISPLAY_ONLY) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": ASSET_POLICY_KIND,
		"policy_id": policy_id,
		"display_key": "asset.policy.%s" % str(policy_id),
		"can_show": true,
		"can_filter": true,
		"can_reference": true,
		"can_mutate_asset": false,
		"can_write_warehouse": false,
		"can_grant_reward": false,
		"can_run_gacha": false,
		"can_write_settlement": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func normalize_asset_ref(data: Dictionary = {}) -> Dictionary:
	var result := default_asset_ref()
	_merge_known(result, data)
	result["schema_version"] = SCHEMA_VERSION
	result["schema_kind"] = ASSET_REF_KIND
	result["asset_id"] = str(result.get("asset_id", ""))
	result["definition_id"] = str(result.get("definition_id", result.get("asset_id", "")))
	result["instance_id"] = str(result.get("instance_id", ""))
	result["category"] = StringName(result.get("category", CATEGORY_ITEM))
	result["display_key"] = str(result.get("display_key", "asset.preview"))
	result["state_tags"] = _array_from(result.get("state_tags", []))
	result["quantity"] = max(0, int(result.get("quantity", 1)))
	_apply_boundary_flags(result)
	return result


static func validate_asset_ref(data: Dictionary) -> Dictionary:
	var normalized := normalize_asset_ref(data)
	var warnings: Array[String] = []
	if not CATEGORIES.has(StringName(normalized.get("category", &""))):
		warnings.append("unknown_asset_category")
	if str(normalized.get("asset_id", "")).is_empty() and str(normalized.get("definition_id", "")).is_empty():
		warnings.append("missing_asset_identifier")
	if not bool(normalized.get("read_only", false)):
		warnings.append("asset_ref_must_be_read_only")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func normalize_policy(data: Dictionary = {}) -> Dictionary:
	var result := default_policy()
	_merge_known(result, data)
	result["policy_id"] = StringName(result.get("policy_id", POLICY_DISPLAY_ONLY))
	_apply_boundary_flags(result)
	result["can_mutate_asset"] = false
	result["can_write_warehouse"] = false
	result["can_grant_reward"] = false
	result["can_run_gacha"] = false
	result["can_write_settlement"] = false
	return result


static func _merge_known(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		target[key] = _copy_value(source[key])


static func _apply_boundary_flags(target: Dictionary) -> void:
	target["read_only"] = true
	target["display_only"] = true
	target["preview"] = true


static func _array_from(value: Variant) -> Array:
	if value is Array:
		return value.duplicate(true)
	return []


static func _copy_value(value: Variant) -> Variant:
	if (value is Dictionary) or (value is Array):
		return value.duplicate(true)
	return value
