extends RefCounted
class_name AssetProjectionSchema

const AssetContractScript := preload("res://scripts/core/asset/asset_contract.gd")

const SCHEMA_VERSION := 1
const PROJECTION_KIND := &"AssetProjection"


static func default_projection(projection_type: StringName = AssetContractScript.PROJECTION_WAREHOUSE) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": PROJECTION_KIND,
		"projection_type": projection_type,
		"source_system": AssetContractScript.SOURCE_SYSTEM_UNKNOWN,
		"asset_refs": [],
		"summary": {},
		"display_policy": &"display_only",
		"link_targets": [],
		"read_only": true,
		"extra": {},
		"unknown_fields": {},
		"deprecated_fields": {},
		"validation_warnings": [],
	}


static func default_warehouse_projection() -> Dictionary:
	return default_projection(AssetContractScript.PROJECTION_WAREHOUSE)


static func default_deploy_prep_projection() -> Dictionary:
	return default_projection(AssetContractScript.PROJECTION_DEPLOY_PREP)


static func default_settlement_projection() -> Dictionary:
	return default_projection(AssetContractScript.PROJECTION_SETTLEMENT)


static func default_history_projection() -> Dictionary:
	return default_projection(AssetContractScript.PROJECTION_HISTORY)


static func default_codex_projection() -> Dictionary:
	return default_projection(AssetContractScript.PROJECTION_CODEX)


static func default_research_projection() -> Dictionary:
	return default_projection(AssetContractScript.PROJECTION_RESEARCH)


static func default_gacha_projection() -> Dictionary:
	return default_projection(AssetContractScript.PROJECTION_GACHA)


static func default_objective_projection() -> Dictionary:
	return default_projection(AssetContractScript.PROJECTION_OBJECTIVE)


static func default_long_term_projection() -> Dictionary:
	return default_projection(AssetContractScript.PROJECTION_LONG_TERM)


static func default_all_projection_schemas() -> Dictionary:
	var projections := {}
	for projection_type in AssetContractScript.projection_targets():
		projections[projection_type] = default_projection(projection_type)
	return projections


static func normalize_projection(raw_projection: Dictionary = {}) -> Dictionary:
	var projection_type := StringName(raw_projection.get("projection_type", AssetContractScript.PROJECTION_WAREHOUSE))
	var result := _normalize_with_defaults(raw_projection, default_projection(projection_type))
	result["projection_type"] = StringName(result.get("projection_type", projection_type))
	result["source_system"] = StringName(result.get("source_system", AssetContractScript.SOURCE_SYSTEM_UNKNOWN))
	result["asset_refs"] = _normalize_asset_refs(result.get("asset_refs", []))
	result["summary"] = _dictionary_from(result.get("summary", {}))
	result["link_targets"] = _array_from(result.get("link_targets", []))
	result["read_only"] = bool(result.get("read_only", true))
	return result


static func validate_projection(projection: Dictionary) -> Dictionary:
	var warnings: Array[String] = []
	if int(projection.get("schema_version", 0)) != SCHEMA_VERSION:
		warnings.append("schema_version_mismatch")
	if not AssetContractScript.projection_targets().has(StringName(projection.get("projection_type", &""))):
		warnings.append("unknown_projection_type")
	if not bool(projection.get("read_only", false)):
		warnings.append("projection_must_be_read_only")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func _normalize_asset_refs(raw_refs: Variant) -> Array:
	var refs: Array = []
	if not (raw_refs is Array):
		return refs
	for raw_ref in raw_refs:
		if raw_ref is Dictionary:
			refs.append(AssetContractScript.normalize_asset_ref(raw_ref))
	return refs


static func _normalize_with_defaults(raw_data: Dictionary, defaults: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	var unknown_fields: Dictionary = result.get("unknown_fields", {})
	var warnings: Array = result.get("validation_warnings", [])
	for key in raw_data.keys():
		if result.has(key):
			result[key] = _copy_value(raw_data[key])
		else:
			unknown_fields[String(key)] = _copy_value(raw_data[key])
			warnings.append("unknown_field:%s" % String(key))
	result["unknown_fields"] = unknown_fields
	result["validation_warnings"] = warnings
	return result


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
