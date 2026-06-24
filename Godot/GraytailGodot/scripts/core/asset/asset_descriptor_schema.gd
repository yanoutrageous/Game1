extends RefCounted
class_name AssetDescriptorSchema

const AssetDomainContractScript := preload("res://scripts/core/asset/asset_domain_contract.gd")

const SCHEMA_VERSION := 1
const SCHEMA_KIND := &"AssetDescriptor"


static func default_descriptor(asset_id: String = "", category: StringName = AssetDomainContractScript.CATEGORY_ITEM) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": SCHEMA_KIND,
		"asset_ref": AssetDomainContractScript.default_asset_ref(asset_id, category),
		"display_name_key": "asset.%s.name" % asset_id if not asset_id.is_empty() else "asset.preview.name",
		"description_key": "asset.%s.description" % asset_id if not asset_id.is_empty() else "asset.preview.description",
		"icon_key": "asset.%s.icon" % asset_id if not asset_id.is_empty() else "asset.preview.icon",
		"rarity_key": "asset.rarity.preview",
		"category": AssetDomainContractScript.default_category(category),
		"tags": [],
		"policy": AssetDomainContractScript.default_policy(),
		"source_context_id": "",
		"status_line": "AssetDescriptor preview only.",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func normalize_descriptor(data: Dictionary = {}) -> Dictionary:
	var result := default_descriptor()
	for key in data.keys():
		result[key] = _copy_value(data[key])
	result["schema_version"] = SCHEMA_VERSION
	result["schema_kind"] = SCHEMA_KIND
	result["asset_ref"] = AssetDomainContractScript.normalize_asset_ref(_dictionary_from(result.get("asset_ref", {})))
	result["category"] = AssetDomainContractScript.default_category(StringName((_dictionary_from(result.get("asset_ref", {}))).get("category", AssetDomainContractScript.CATEGORY_ITEM)))
	if result.get("category") is Dictionary and data.has("category"):
		var category_data := _dictionary_from(data.get("category", {}))
		var category_result: Dictionary = result["category"]
		for key in category_data.keys():
			category_result[key] = _copy_value(category_data[key])
		result["category"] = category_result
	result["tags"] = _normalize_tags(result.get("tags", []))
	result["policy"] = AssetDomainContractScript.normalize_policy(_dictionary_from(result.get("policy", {})))
	result["display_name_key"] = str(result.get("display_name_key", "asset.preview.name"))
	result["description_key"] = str(result.get("description_key", "asset.preview.description"))
	result["icon_key"] = str(result.get("icon_key", "asset.preview.icon"))
	result["rarity_key"] = str(result.get("rarity_key", "asset.rarity.preview"))
	result["status_line"] = str(result.get("status_line", "AssetDescriptor preview only."))
	result["read_only"] = true
	result["display_only"] = true
	result["preview"] = true
	return result


static func validate_descriptor(data: Dictionary) -> Dictionary:
	var descriptor := normalize_descriptor(data)
	var warnings: Array[String] = []
	var ref_validation: Dictionary = AssetDomainContractScript.validate_asset_ref(descriptor.get("asset_ref", {}))
	for warning in ref_validation.get("warnings", []):
		warnings.append("asset_ref:%s" % str(warning))
	if str(descriptor.get("display_name_key", "")).is_empty():
		warnings.append("missing_display_name_key")
	if not bool(descriptor.get("read_only", false)):
		warnings.append("descriptor_must_be_read_only")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func sample_descriptors() -> Array:
	return [
		default_descriptor("field_knife", AssetDomainContractScript.CATEGORY_ITEM),
		default_descriptor("first_aid", AssetDomainContractScript.CATEGORY_ITEM),
		default_descriptor("sealed_relic", AssetDomainContractScript.CATEGORY_COLLECTIBLE),
		default_descriptor("service_token", AssetDomainContractScript.CATEGORY_RESOURCE),
	]


static func _normalize_tags(value: Variant) -> Array:
	var tags: Array = []
	if not (value is Array):
		return tags
	for entry in value:
		if entry is Dictionary:
			var tag_data: Dictionary = entry
			tags.append(AssetDomainContractScript.default_tag(str(tag_data.get("tag_id", "")), StringName(tag_data.get("tag_type", &"state"))))
		else:
			tags.append(AssetDomainContractScript.default_tag(str(entry)))
	return tags


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}


static func _copy_value(value: Variant) -> Variant:
	if (value is Dictionary) or (value is Array):
		return value.duplicate(true)
	return value
