extends RefCounted
class_name HistorySnapshotSchema

const SCHEMA_VERSION := 1
const SNAPSHOT_KIND := &"HistoryRecordSnapshot"

const RECORD_PREVIEW := &"preview"
const RECORD_ARCHIVED := &"archived"
const RECORD_STATES := [
	RECORD_PREVIEW,
	RECORD_ARCHIVED,
]

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


static func default_record() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"snapshot_type": SNAPSHOT_KIND,
		"history_record_id": "",
		"source_run_id": "",
		"record_state": RECORD_PREVIEW,
		"result_type": RESULT_SUCCESS,
		"recorded_at_label": "Preview record",
		"display_date_label": "Preview date",
		"summary_line": "HistoryRecordSnapshot preview",
		"map_summary": _default_map_summary(),
		"settlement_summary_ref": {},
		"historical_item_preview": _default_historical_preview("item"),
		"historical_resource_preview": _default_historical_preview("resource"),
		"historical_objective_preview": _default_historical_preview("objective"),
		"historical_codex_preview": _default_historical_preview("codex"),
		"historical_qualification_preview": _default_historical_preview("qualification"),
		"event_flow_preview": _default_event_flow_preview(),
		"ui_metadata": _default_ui_metadata(),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"history_independence_note": "This record describes one finished run and does not depend on current warehouse state.",
		"extra": {},
		"unknown_fields": {},
		"deprecated_fields": {},
		"validation_warnings": [],
	}


static func normalize_record(data: Dictionary = {}) -> Dictionary:
	var result := _normalize_with_defaults(data, default_record())
	result["record_state"] = StringName(result.get("record_state", RECORD_PREVIEW))
	result["result_type"] = StringName(result.get("result_type", RESULT_SUCCESS))
	result["map_summary"] = _dictionary_from(result.get("map_summary", {}), _default_map_summary())
	result["settlement_summary_ref"] = _dictionary_from(result.get("settlement_summary_ref", {}), {})
	result["historical_item_preview"] = _dictionary_from(result.get("historical_item_preview", {}), _default_historical_preview("item"))
	result["historical_resource_preview"] = _dictionary_from(result.get("historical_resource_preview", {}), _default_historical_preview("resource"))
	result["historical_objective_preview"] = _dictionary_from(result.get("historical_objective_preview", {}), _default_historical_preview("objective"))
	result["historical_codex_preview"] = _dictionary_from(result.get("historical_codex_preview", {}), _default_historical_preview("codex"))
	result["historical_qualification_preview"] = _dictionary_from(result.get("historical_qualification_preview", {}), _default_historical_preview("qualification"))
	result["event_flow_preview"] = _dictionary_from(result.get("event_flow_preview", {}), _default_event_flow_preview())
	result["ui_metadata"] = _dictionary_from(result.get("ui_metadata", {}), _default_ui_metadata())
	result["read_only"] = bool(result.get("read_only", true))
	result["display_only"] = bool(result.get("display_only", true))
	result["preview"] = bool(result.get("preview", true))
	return result


static func validate_record(data: Dictionary) -> Dictionary:
	var warnings: Array[String] = []
	if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		warnings.append("schema_version_mismatch")
	if StringName(data.get("snapshot_type", &"")) != SNAPSHOT_KIND:
		warnings.append("snapshot_type_mismatch")
	if not RECORD_STATES.has(StringName(data.get("record_state", &""))):
		warnings.append("unknown_record_state")
	if not RESULT_TYPES.has(StringName(data.get("result_type", &""))):
		warnings.append("unknown_result_type")
	if not bool(data.get("read_only", false)):
		warnings.append("record_must_be_read_only")
	if not bool(data.get("display_only", false)):
		warnings.append("record_must_be_display_only")
	if not bool(data.get("preview", false)):
		warnings.append("record_must_be_preview")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func _default_map_summary() -> Dictionary:
	return {
		"map_mode": "",
		"difficulty": "",
		"region": "",
		"map_display_key": "",
		"difficulty_display_key": "",
		"region_display_key": "",
	}


static func _default_historical_preview(kind: String) -> Dictionary:
	return {
		"kind": kind,
		"items": [],
		"summary": "",
		"%s_display_key" % kind: "history.%s.preview" % kind,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _default_event_flow_preview() -> Dictionary:
	return {
		"asset_event_preview": {},
		"settlement_event_preview": {},
		"history_record_event_preview": {},
		"summary": "Event fields are preview refs only.",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _default_ui_metadata() -> Dictionary:
	return {
		"ui_group_key": "profile.history.preview",
		"history_card_icon_key": "history.card.preview",
		"art_placeholder_id": "history_record_placeholder",
		"localization_key": "history.preview.title",
		"description_key": "history.preview.description",
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
