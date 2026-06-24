extends RefCounted
class_name WarehouseViewSchema

const AssetDomainContractScript := preload("res://scripts/core/asset/asset_domain_contract.gd")
const AssetDescriptorSchemaScript := preload("res://scripts/core/asset/asset_descriptor_schema.gd")
const AssetEventPreviewSchemaScript := preload("res://scripts/core/asset/asset_event_preview_schema.gd")

const SCHEMA_VERSION := 1
const OWNED_ASSET_KIND := &"OwnedAssetSnapshot"
const WAREHOUSE_VIEW_KIND := &"WarehouseViewSnapshot"
const DEPLOY_ASSET_VIEW_KIND := &"DeployAssetView"
const CARRY_INTENT_KIND := &"CarryIntent"
const SETTLEMENT_DELTA_KIND := &"SettlementAssetDelta"
const HISTORY_REFERENCE_KIND := &"HistoryAssetReference"


static func default_owned_asset_snapshot(asset_id: String = "", category: StringName = AssetDomainContractScript.CATEGORY_ITEM) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": OWNED_ASSET_KIND,
		"asset_descriptor": AssetDescriptorSchemaScript.default_descriptor(asset_id, category),
		"ownership_state": &"preview_owned",
		"warehouse_group": category,
		"source_context": AssetEventPreviewSchemaScript.default_source_context("warehouse.preview"),
		"state_tags": [],
		"quantity": 1,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_asset_write": true,
		"no_warehouse_write": true,
	}


static func normalize_owned_asset_snapshot(data: Dictionary = {}) -> Dictionary:
	var result := default_owned_asset_snapshot()
	for key in data.keys():
		result[key] = _copy_value(data[key])
	result["schema_version"] = SCHEMA_VERSION
	result["schema_kind"] = OWNED_ASSET_KIND
	result["asset_descriptor"] = AssetDescriptorSchemaScript.normalize_descriptor(_dictionary_from(result.get("asset_descriptor", {})))
	result["source_context"] = AssetEventPreviewSchemaScript.normalize_source_context(_dictionary_from(result.get("source_context", {})))
	result["warehouse_group"] = StringName(result.get("warehouse_group", AssetDomainContractScript.CATEGORY_ITEM))
	result["state_tags"] = _array_from(result.get("state_tags", []))
	result["quantity"] = max(0, int(result.get("quantity", 1)))
	_apply_boundary_flags(result)
	result["no_asset_write"] = true
	result["no_warehouse_write"] = true
	return result


static func default_warehouse_view_snapshot() -> Dictionary:
	var items := [
		default_owned_asset_snapshot("field_knife", AssetDomainContractScript.CATEGORY_ITEM),
		default_owned_asset_snapshot("first_aid", AssetDomainContractScript.CATEGORY_ITEM),
		default_owned_asset_snapshot("sealed_relic", AssetDomainContractScript.CATEGORY_COLLECTIBLE),
		default_owned_asset_snapshot("service_token", AssetDomainContractScript.CATEGORY_RESOURCE),
	]
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": WAREHOUSE_VIEW_KIND,
		"view_id": "warehouse.preview",
		"title": "WarehouseViewSnapshot preview",
		"summary": "Read-only warehouse view over asset snapshots; not a real warehouse.",
		"categories": _default_categories(),
		"owned_asset_snapshots": items,
		"asset_event_preview": AssetEventPreviewSchemaScript.default_event_preview(),
		"available_preview_actions": ["inspect_preview", "filter_preview", "link_preview"],
		"blocked_real_actions": ["asset_write", "warehouse_write", "sale", "equipment_change", "carry_commit", "reward_grant"],
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func normalize_warehouse_view_snapshot(data: Dictionary = {}) -> Dictionary:
	var result := default_warehouse_view_snapshot()
	for key in data.keys():
		result[key] = _copy_value(data[key])
	result["schema_version"] = SCHEMA_VERSION
	result["schema_kind"] = WAREHOUSE_VIEW_KIND
	result["categories"] = _array_from(result.get("categories", []))
	result["owned_asset_snapshots"] = _normalize_owned_assets(result.get("owned_asset_snapshots", []))
	result["asset_event_preview"] = AssetEventPreviewSchemaScript.normalize_event_preview(_dictionary_from(result.get("asset_event_preview", {})))
	_apply_boundary_flags(result)
	return result


static func default_deploy_asset_view() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": DEPLOY_ASSET_VIEW_KIND,
		"view_id": "deploy.asset.preview",
		"warehouse_view_snapshot": default_warehouse_view_snapshot(),
		"carry_intent_preview": default_carry_intent(),
		"summary_lines": [
			"DeployAssetView is display-only.",
			"CarryIntent reserves a future deploy boundary and does not change loadout.",
		],
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_carry_intent(asset_id: String = "") -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": CARRY_INTENT_KIND,
		"intent_id": "carry.preview.%s" % asset_id if not asset_id.is_empty() else "carry.preview",
		"asset_ref": AssetDomainContractScript.default_asset_ref(asset_id),
		"intent_state": &"preview_only",
		"can_commit": false,
		"reason": "CarryIntent reserves deploy carry boundary only.",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_settlement_asset_delta() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": SETTLEMENT_DELTA_KIND,
		"delta_id": "settlement.asset.delta.preview",
		"returned": [],
		"lost": [],
		"cleared": [],
		"rescued": [],
		"converted": [],
		"asset_event_preview": AssetEventPreviewSchemaScript.default_event_preview("settlement.asset.event.preview"),
		"summary": "SettlementAssetDelta references result assets only; it does not change warehouse state.",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_history_asset_reference(asset_id: String = "") -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": HISTORY_REFERENCE_KIND,
		"history_ref_id": "history.asset.reference.preview",
		"asset_descriptor": AssetDescriptorSchemaScript.default_descriptor(asset_id),
		"source_run_id": "",
		"historical_state": &"recorded_at_run_result",
		"summary": "HistoryAssetReference keeps the run result display independent from current warehouse state.",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_long_term_asset_reference_view() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"LongTermAssetReferenceView",
		"collection_reference": default_history_asset_reference("sealed_relic"),
		"appearance_reference": default_history_asset_reference("appearance_preview"),
		"gacha_reference": default_history_asset_reference("gacha_pool_preview"),
		"summary": "LongTerm may reference assets without merging with the warehouse.",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func validate_warehouse_view_snapshot(data: Dictionary) -> Dictionary:
	var view := normalize_warehouse_view_snapshot(data)
	var warnings: Array[String] = []
	if not bool(view.get("read_only", false)):
		warnings.append("warehouse_view_must_be_read_only")
	if not bool(view.get("display_only", false)):
		warnings.append("warehouse_view_must_be_display_only")
	if not bool(view.get("preview", false)):
		warnings.append("warehouse_view_must_be_preview")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func _default_categories() -> Array:
	return [
		AssetDomainContractScript.default_category(AssetDomainContractScript.CATEGORY_ITEM),
		AssetDomainContractScript.default_category(AssetDomainContractScript.CATEGORY_RESOURCE),
		AssetDomainContractScript.default_category(AssetDomainContractScript.CATEGORY_COLLECTIBLE),
		AssetDomainContractScript.default_category(AssetDomainContractScript.CATEGORY_SPECIAL),
	]


static func _normalize_owned_assets(value: Variant) -> Array:
	var result: Array = []
	if not (value is Array):
		return result
	for item in value:
		if item is Dictionary:
			result.append(normalize_owned_asset_snapshot(item))
	return result


static func _apply_boundary_flags(target: Dictionary) -> void:
	target["read_only"] = true
	target["display_only"] = true
	target["preview"] = true


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
