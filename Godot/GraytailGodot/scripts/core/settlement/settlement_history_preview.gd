extends RefCounted
class_name SettlementHistoryPreview

const SettlementSnapshotSchemaScript := preload("res://scripts/core/settlement/settlement_snapshot_schema.gd")
const HistorySnapshotSchemaScript := preload("res://scripts/core/settlement/history_snapshot_schema.gd")


static func default_preview() -> Dictionary:
	var settlement := SettlementSnapshotSchemaScript.default_snapshot()
	var history := build_history_preview(settlement)
	return {
		"schema_version": 1,
		"preview_type": &"settlement_history_preview",
		"settlement_snapshot_preview": settlement,
		"history_record_snapshot_preview": history,
		"long_term_history_preview": build_long_term_history_preview(history),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
		"no_asset_mutation": true,
		"no_reward_grant": true,
		"no_event_bus_dispatch": true,
	}


static func build_history_preview(settlement_snapshot: Dictionary = {}) -> Dictionary:
	var settlement := SettlementSnapshotSchemaScript.normalize_snapshot(settlement_snapshot)
	var record := HistorySnapshotSchemaScript.default_record()
	record["history_record_id"] = "preview:%s" % String(settlement.get("run_id", ""))
	record["source_run_id"] = String(settlement.get("run_id", ""))
	record["result_type"] = settlement.get("result_type", &"success")
	record["summary_line"] = String((settlement.get("result_summary", {}) as Dictionary).get("outcome_title", "SettlementSnapshot preview"))
	record["map_summary"] = (settlement.get("map_summary", {}) as Dictionary).duplicate(true)
	record["settlement_summary_ref"] = (settlement.get("result_summary", {}) as Dictionary).duplicate(true)
	record["historical_item_preview"] = {
		"kind": "item",
		"items": (settlement.get("item_result_preview", {}) as Dictionary).duplicate(true),
		"settlement_asset_delta_preview": (settlement.get("settlement_asset_delta_preview", {}) as Dictionary).duplicate(true),
		"history_asset_reference_preview": (settlement.get("history_asset_reference_preview", {}) as Dictionary).duplicate(true),
		"summary": "history keeps the original run item result preview",
		"item_display_key": "history.item.preview",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}
	record["historical_resource_preview"] = {
		"kind": "resource",
		"items": (settlement.get("resource_result_preview", {}) as Dictionary).duplicate(true),
		"summary": "history keeps the original run resource result preview",
		"resource_display_key": "history.resource.preview",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}
	record["historical_objective_preview"] = (settlement.get("objective_result_preview", {}) as Dictionary).duplicate(true)
	record["historical_codex_preview"] = (settlement.get("codex_unlock_preview", {}) as Dictionary).duplicate(true)
	record["historical_qualification_preview"] = (settlement.get("qualification_delta_preview", {}) as Dictionary).duplicate(true)
	record["event_flow_preview"] = {
		"asset_event_preview": (settlement.get("asset_event_preview", {}) as Dictionary).duplicate(true),
		"settlement_event_preview": (settlement.get("settlement_event_preview", {}) as Dictionary).duplicate(true),
		"history_record_event_preview": (settlement.get("history_record_event_preview", {}) as Dictionary).duplicate(true),
		"summary": "preview-only settlement to history event refs",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}
	var default_ui_metadata: Dictionary = (HistorySnapshotSchemaScript.default_record().get("ui_metadata", {}) as Dictionary).duplicate(true)
	var settlement_ui_metadata: Dictionary = (settlement.get("ui_metadata", {}) as Dictionary).duplicate(true)
	record["ui_metadata"] = _merge_dictionaries(default_ui_metadata, settlement_ui_metadata)
	return HistorySnapshotSchemaScript.normalize_record(record)


static func build_long_term_history_preview(history_record: Dictionary = {}) -> Dictionary:
	var record := HistorySnapshotSchemaScript.normalize_record(history_record)
	return {
		"title": "历史战绩 preview",
		"module": "个人资历",
		"state": "display_only",
		"summary_line": String(record.get("summary_line", "")),
		"source_run_id": String(record.get("source_run_id", "")),
		"result_type": record.get("result_type", &"success"),
		"map_summary": (record.get("map_summary", {}) as Dictionary).duplicate(true),
		"historical_item_preview": (record.get("historical_item_preview", {}) as Dictionary).duplicate(true),
		"history_asset_reference_preview": ((record.get("historical_item_preview", {}) as Dictionary).get("history_asset_reference_preview", {}) as Dictionary).duplicate(true),
		"historical_resource_preview": (record.get("historical_resource_preview", {}) as Dictionary).duplicate(true),
		"historical_objective_preview": (record.get("historical_objective_preview", {}) as Dictionary).duplicate(true),
		"historical_codex_preview": (record.get("historical_codex_preview", {}) as Dictionary).duplicate(true),
		"historical_qualification_preview": (record.get("historical_qualification_preview", {}) as Dictionary).duplicate(true),
		"event_flow_preview": (record.get("event_flow_preview", {}) as Dictionary).duplicate(true),
		"ui_metadata": (record.get("ui_metadata", {}) as Dictionary).duplicate(true),
		"history_card_icon_key": String((record.get("ui_metadata", {}) as Dictionary).get("history_card_icon_key", "history.card.preview")),
		"art_placeholder_id": String((record.get("ui_metadata", {}) as Dictionary).get("art_placeholder_id", "history_record_placeholder")),
		"future_data_ref": "future.history.snapshot",
		"data_source_ref": "preview.settlement.history",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func validate_preview(data: Dictionary) -> Dictionary:
	var warnings: Array[String] = []
	if not bool(data.get("read_only", false)):
		warnings.append("preview_must_be_read_only")
	if not bool(data.get("display_only", false)):
		warnings.append("preview_must_be_display_only")
	if not bool(data.get("preview", false)):
		warnings.append("preview_flag_required")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func _merge_dictionaries(base: Dictionary, override: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key in override.keys():
		result[key] = _copy_value(override[key])
	return result


static func _copy_value(value: Variant) -> Variant:
	if (value is Dictionary) or (value is Array):
		return value.duplicate(true)
	return value
