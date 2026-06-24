extends RefCounted
class_name AssetEventPreviewSchema

const AssetDomainContractScript := preload("res://scripts/core/asset/asset_domain_contract.gd")
const AssetDescriptorSchemaScript := preload("res://scripts/core/asset/asset_descriptor_schema.gd")

const SCHEMA_VERSION := 1
const EVENT_KIND := &"AssetEventPreview"
const SOURCE_KIND := &"AssetSourceContext"


static func default_source_context(source_id: String = "preview.source") -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": SOURCE_KIND,
		"source_context_id": source_id,
		"source_system": &"preview",
		"source_label": "Asset source preview",
		"source_display_key": "asset.source.preview",
		"run_ref": "",
		"settlement_ref": "",
		"history_ref": "",
		"long_term_ref": "",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_event_preview(event_id: String = "asset.event.preview") -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": EVENT_KIND,
		"event_id": event_id,
		"event_type": &"preview_only",
		"source_context": default_source_context(),
		"asset_descriptor": AssetDescriptorSchemaScript.default_descriptor(),
		"change_summary": "AssetEventPreview describes possible source/change only.",
		"asset_delta_preview": {},
		"policy": AssetDomainContractScript.default_policy(AssetDomainContractScript.POLICY_BLOCKED_REAL_ACTION),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_asset_write": true,
		"no_warehouse_write": true,
		"no_reward_grant": true,
		"no_event_dispatch": true,
	}


static func normalize_source_context(data: Dictionary = {}) -> Dictionary:
	var result := default_source_context()
	for key in data.keys():
		result[key] = _copy_value(data[key])
	result["schema_version"] = SCHEMA_VERSION
	result["schema_kind"] = SOURCE_KIND
	result["source_context_id"] = str(result.get("source_context_id", "preview.source"))
	result["source_system"] = StringName(result.get("source_system", &"preview"))
	result["source_label"] = str(result.get("source_label", "Asset source preview"))
	_apply_boundary_flags(result)
	return result


static func normalize_event_preview(data: Dictionary = {}) -> Dictionary:
	var result := default_event_preview()
	for key in data.keys():
		result[key] = _copy_value(data[key])
	result["schema_version"] = SCHEMA_VERSION
	result["schema_kind"] = EVENT_KIND
	result["event_id"] = str(result.get("event_id", "asset.event.preview"))
	result["event_type"] = StringName(result.get("event_type", &"preview_only"))
	result["source_context"] = normalize_source_context(_dictionary_from(result.get("source_context", {})))
	result["asset_descriptor"] = AssetDescriptorSchemaScript.normalize_descriptor(_dictionary_from(result.get("asset_descriptor", {})))
	result["policy"] = AssetDomainContractScript.normalize_policy(_dictionary_from(result.get("policy", {})))
	result["no_asset_write"] = true
	result["no_warehouse_write"] = true
	result["no_reward_grant"] = true
	result["no_event_dispatch"] = true
	_apply_boundary_flags(result)
	return result


static func validate_event_preview(data: Dictionary) -> Dictionary:
	var event := normalize_event_preview(data)
	var warnings: Array[String] = []
	if str(event.get("event_id", "")).is_empty():
		warnings.append("missing_event_id")
	if not bool(event.get("read_only", false)):
		warnings.append("event_preview_must_be_read_only")
	if not bool(event.get("no_asset_write", false)):
		warnings.append("event_preview_must_not_write_assets")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func _apply_boundary_flags(target: Dictionary) -> void:
	target["read_only"] = true
	target["display_only"] = true
	target["preview"] = true


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}


static func _copy_value(value: Variant) -> Variant:
	if (value is Dictionary) or (value is Array):
		return value.duplicate(true)
	return value
