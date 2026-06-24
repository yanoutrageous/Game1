extends RefCounted
class_name SettlementSnapshotSchema

const AssetDomainContractScript := preload("res://scripts/core/asset/asset_domain_contract.gd")
const WarehouseViewSchemaScript := preload("res://scripts/core/asset/warehouse_view_schema.gd")
const WarehouseViewContentSchemaScript := preload("res://scripts/core/asset/warehouse_view_content_schema.gd")

const SCHEMA_VERSION := 1
const SNAPSHOT_KIND := &"SettlementSnapshot"

const RESULT_SUCCESS := &"success"
const RESULT_FAILED := &"failed"
const RESULT_ABANDONED := &"abandoned"
const RESULT_SPECIAL := &"special"
const RESULT_TYPES := [
	RESULT_SUCCESS,
	RESULT_FAILED,
	RESULT_ABANDONED,
	RESULT_SPECIAL,
]


static func default_snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"snapshot_type": SNAPSHOT_KIND,
		"run_id": "",
		"run_label": "Preview run",
		"result_type": RESULT_SUCCESS,
		"map_summary": _default_map_summary(),
		"run_map_snapshot_preview": _default_run_map_snapshot_preview(),
		"map_result_preview": _default_map_result_preview(),
		"settlement_trigger_preview": _default_settlement_trigger_preview(),
		"run_outcome_preview": _default_run_outcome_preview(),
		"run_result_draft_preview": _default_run_result_draft_preview(),
		"deploy_summary": _default_deploy_summary(),
		"result_summary": _default_result_summary(),
		"item_result_preview": _default_result_bucket(),
		"settlement_asset_delta_preview": WarehouseViewSchemaScript.default_settlement_asset_delta(),
		"settlement_content_snapshot": WarehouseViewContentSchemaScript.build_settlement_content_view(),
		"history_asset_reference_preview": WarehouseViewSchemaScript.default_history_asset_reference(),
		"resource_result_preview": _default_resource_preview(),
		"objective_result_preview": _default_named_preview("objective"),
		"reward_bundle_preview": AssetDomainContractScript.default_reward_bundle_preview("settlement.reward_bundle.preview", &"settlement"),
		"resource_event_preview": AssetDomainContractScript.default_resource_event_preview("settlement.resource_event.preview"),
		"item_event_preview": AssetDomainContractScript.default_item_event_preview("settlement.item_event.preview"),
		"unlock_event_preview": AssetDomainContractScript.default_unlock_event_preview("settlement.unlock_event.preview"),
		"objective_event_preview": AssetDomainContractScript.default_objective_event_preview("settlement.objective_event.preview"),
		"commission_result_preview": _default_named_preview("commission"),
		"codex_unlock_preview": _default_named_preview("codex"),
		"qualification_delta_preview": _default_named_preview("qualification"),
		"asset_event_preview": _default_event_preview("asset_event_preview"),
		"settlement_event_preview": _default_event_preview("settlement_event_preview"),
		"history_record_event_preview": _default_event_preview("history_record_event_preview"),
		"ui_metadata": _default_ui_metadata(),
		"future_data_ref": "",
		"data_source_ref": "",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"extra": {},
		"unknown_fields": {},
		"deprecated_fields": {},
		"validation_warnings": [],
	}


static func normalize_snapshot(data: Dictionary = {}) -> Dictionary:
	var result := _normalize_with_defaults(data, default_snapshot())
	result["result_type"] = StringName(result.get("result_type", RESULT_SUCCESS))
	result["map_summary"] = _dictionary_from(result.get("map_summary", {}), _default_map_summary())
	result["run_map_snapshot_preview"] = _dictionary_from(result.get("run_map_snapshot_preview", {}), _default_run_map_snapshot_preview())
	result["map_result_preview"] = _dictionary_from(result.get("map_result_preview", {}), _default_map_result_preview())
	result["settlement_trigger_preview"] = _dictionary_from(result.get("settlement_trigger_preview", {}), _default_settlement_trigger_preview())
	result["run_outcome_preview"] = _dictionary_from(result.get("run_outcome_preview", {}), _default_run_outcome_preview())
	result["run_result_draft_preview"] = _dictionary_from(result.get("run_result_draft_preview", {}), _default_run_result_draft_preview())
	result["deploy_summary"] = _dictionary_from(result.get("deploy_summary", {}), _default_deploy_summary())
	result["result_summary"] = _dictionary_from(result.get("result_summary", {}), _default_result_summary())
	result["item_result_preview"] = _dictionary_from(result.get("item_result_preview", {}), _default_result_bucket())
	result["settlement_asset_delta_preview"] = _dictionary_from(result.get("settlement_asset_delta_preview", {}), WarehouseViewSchemaScript.default_settlement_asset_delta())
	result["settlement_content_snapshot"] = _dictionary_from(result.get("settlement_content_snapshot", {}), WarehouseViewContentSchemaScript.build_settlement_content_view())
	result["history_asset_reference_preview"] = _dictionary_from(result.get("history_asset_reference_preview", {}), WarehouseViewSchemaScript.default_history_asset_reference())
	result["resource_result_preview"] = _dictionary_from(result.get("resource_result_preview", {}), _default_resource_preview())
	result["objective_result_preview"] = _dictionary_from(result.get("objective_result_preview", {}), _default_named_preview("objective"))
	result["reward_bundle_preview"] = AssetDomainContractScript.normalize_reward_bundle_preview(_dictionary_from(result.get("reward_bundle_preview", {}), AssetDomainContractScript.default_reward_bundle_preview("settlement.reward_bundle.preview", &"settlement")))
	result["resource_event_preview"] = _dictionary_from(result.get("resource_event_preview", {}), AssetDomainContractScript.default_resource_event_preview("settlement.resource_event.preview"))
	result["item_event_preview"] = _dictionary_from(result.get("item_event_preview", {}), AssetDomainContractScript.default_item_event_preview("settlement.item_event.preview"))
	result["unlock_event_preview"] = _dictionary_from(result.get("unlock_event_preview", {}), AssetDomainContractScript.default_unlock_event_preview("settlement.unlock_event.preview"))
	result["objective_event_preview"] = _dictionary_from(result.get("objective_event_preview", {}), AssetDomainContractScript.default_objective_event_preview("settlement.objective_event.preview"))
	result["commission_result_preview"] = _dictionary_from(result.get("commission_result_preview", {}), _default_named_preview("commission"))
	result["codex_unlock_preview"] = _dictionary_from(result.get("codex_unlock_preview", {}), _default_named_preview("codex"))
	result["qualification_delta_preview"] = _dictionary_from(result.get("qualification_delta_preview", {}), _default_named_preview("qualification"))
	result["asset_event_preview"] = _dictionary_from(result.get("asset_event_preview", {}), _default_event_preview("asset_event_preview"))
	result["settlement_event_preview"] = _dictionary_from(result.get("settlement_event_preview", {}), _default_event_preview("settlement_event_preview"))
	result["history_record_event_preview"] = _dictionary_from(result.get("history_record_event_preview", {}), _default_event_preview("history_record_event_preview"))
	result["ui_metadata"] = _dictionary_from(result.get("ui_metadata", {}), _default_ui_metadata())
	result["read_only"] = bool(result.get("read_only", true))
	result["display_only"] = bool(result.get("display_only", true))
	result["preview"] = bool(result.get("preview", true))
	return result


static func validate_snapshot(data: Dictionary) -> Dictionary:
	var warnings: Array[String] = []
	if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		warnings.append("schema_version_mismatch")
	if StringName(data.get("snapshot_type", &"")) != SNAPSHOT_KIND:
		warnings.append("snapshot_type_mismatch")
	if not RESULT_TYPES.has(StringName(data.get("result_type", &""))):
		warnings.append("unknown_result_type")
	if not bool(data.get("read_only", false)):
		warnings.append("snapshot_must_be_read_only")
	if not bool(data.get("display_only", false)):
		warnings.append("snapshot_must_be_display_only")
	if not bool(data.get("preview", false)):
		warnings.append("snapshot_must_be_preview")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func _default_map_summary() -> Dictionary:
	return {
		"map_mode": "",
		"difficulty": "",
		"region": "",
		"map_display_key": "",
		"difficulty_display_key": "",
		"region_display_key": "",
		"RunMapSnapshot": "preview-only map-facing summary source",
		"MapResult": "preview-only settlement/history map output source",
	}


static func _default_run_map_snapshot_preview() -> Dictionary:
	return {
		"schema_kind": &"RunMapSnapshot",
		"map_summary_preview": {},
		"objective_context_preview": {},
		"modifier_context_preview": {},
		"room_loot_context_preview": {},
		"run_result_context_preview": {},
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _default_map_result_preview() -> Dictionary:
	return {
		"schema_kind": &"MapResult",
		"known_summary": {},
		"history_reference_preview": {},
		"settlement_context_preview": {},
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _default_settlement_trigger_preview() -> Dictionary:
	return {
		"schema_kind": &"SettlementTriggerPreview",
		"trigger_state": &"not_ready",
		"source_lifecycle_state": &"initialized",
		"writes_warehouse": false,
		"grants_reward": false,
		"persists_history": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _default_run_outcome_preview() -> Dictionary:
	return {
		"schema_kind": &"RunOutcomePreview",
		"outcome": "Idle",
		"lifecycle_state": &"initialized",
		"result_type": &"running",
		"writes_assets": false,
		"advances_objectives": false,
		"grants_rewards": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _default_run_result_draft_preview() -> Dictionary:
	return {
		"schema_kind": &"RunResult",
		"draft_only": true,
		"settlement_trigger_ref": &"SettlementTriggerPreview",
		"objective_context_preview": _default_named_preview("objective_context"),
		"reward_context_preview": _default_named_preview("reward_context"),
		"room_loot_context_preview": _default_named_preview("room_loot_context"),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _default_deploy_summary() -> Dictionary:
	return {
		"loadout": [],
		"carried_consumables": [],
		"enabled_services": [],
		"enabled_intel": [],
		"enabled_permits": [],
		"capacity_summary": {},
	}


static func _default_result_summary() -> Dictionary:
	return {
		"outcome_title": "SettlementSnapshot preview",
		"outcome_description": "display_only settlement result preview",
		"outcome_icon_key": "settlement.preview",
		"extraction_state": "",
	}


static func _default_result_bucket() -> Dictionary:
	return {
		"returned": [],
		"lost": [],
		"cleared": [],
		"rescued": [],
		"converted": [],
		"item_result_icon_key": "settlement.item.preview",
		"display_only": true,
		"preview": true,
	}


static func _default_resource_preview() -> Dictionary:
	return {
		"black_coin": {"amount": 0, "display_key": "resource.black_coin.preview"},
		"gold": {"amount": 0, "display_key": "resource.gold.preview"},
		"voucher": {"amount": 0, "display_key": "resource.voucher.preview"},
		"ticket": {"amount": 0, "display_key": "resource.ticket.preview"},
		"display_only": true,
		"preview": true,
	}


static func _default_named_preview(name: String) -> Dictionary:
	return {
		"items": [],
		"summary": "",
		"%s_display_key" % name: "%s.preview" % name,
		"display_only": true,
		"preview": true,
	}


static func _default_event_preview(kind: String) -> Dictionary:
	return {
		"event_display_key": kind,
		"event_refs": [],
		"summary": "preview-only event handoff",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _default_ui_metadata() -> Dictionary:
	return {
		"ui_group_key": "settlement.history.preview",
		"history_card_icon_key": "history.card.preview",
		"art_placeholder_id": "settlement_history_placeholder",
		"localization_key": "settlement.preview.title",
		"description_key": "settlement.preview.description",
	}


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


static func _dictionary_from(value: Variant, defaults: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	if value is Dictionary:
		for key in value.keys():
			result[key] = _copy_value(value[key])
	return result


static func _copy_value(value: Variant) -> Variant:
	if (value is Dictionary) or (value is Array):
		return value.duplicate(true)
	return value
