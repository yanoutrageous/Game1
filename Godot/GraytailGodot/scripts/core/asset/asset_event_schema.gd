extends RefCounted
class_name AssetEventSchema

const AssetContractScript := preload("res://scripts/core/asset/asset_contract.gd")

const SCHEMA_VERSION := 1
const EVENT_KIND := &"AssetEvent"

const EVENT_TYPE_RESOURCE := &"ResourceEvent"
const EVENT_TYPE_ITEM := &"ItemEvent"
const EVENT_TYPE_UNLOCK := &"UnlockEvent"
const EVENT_TYPE_HISTORY_RECORD := &"HistoryRecordEvent"
const EVENT_TYPES := [
	EVENT_TYPE_RESOURCE,
	EVENT_TYPE_ITEM,
	EVENT_TYPE_UNLOCK,
	EVENT_TYPE_HISTORY_RECORD,
]

const EVENT_ACTION_GAIN := &"gain"
const EVENT_ACTION_SPEND := &"spend"
const EVENT_ACTION_CONVERT := &"convert"
const EVENT_ACTION_MOVE := &"move"
const EVENT_ACTION_UNLOCK := &"unlock"
const EVENT_ACTION_RECORD := &"record"
const EVENT_ACTION_CLEAR := &"clear"
const EVENT_ACTION_RESERVE := &"reserve"
const EVENT_ACTIONS := [
	EVENT_ACTION_GAIN,
	EVENT_ACTION_SPEND,
	EVENT_ACTION_CONVERT,
	EVENT_ACTION_MOVE,
	EVENT_ACTION_UNLOCK,
	EVENT_ACTION_RECORD,
	EVENT_ACTION_CLEAR,
	EVENT_ACTION_RESERVE,
]


static func default_asset_event() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": EVENT_KIND,
		"event_id": "",
		"event_type": EVENT_TYPE_ITEM,
		"event_action": EVENT_ACTION_GAIN,
		"asset_type": AssetContractScript.ASSET_TYPE_ENTITY_ITEM,
		"asset_id": "",
		"definition_id": "",
		"instance_id": "",
		"stack_id": "",
		"quantity": 0,
		"source_system": AssetContractScript.SOURCE_SYSTEM_UNKNOWN,
		"source_run_id": "",
		"source_encounter_id": "",
		"source_task_id": "",
		"source_commission_id": "",
		"source_gacha_id": "",
		"from_location": AssetContractScript.LOCATION_UNKNOWN,
		"to_location": AssetContractScript.LOCATION_UNKNOWN,
		"reason": "",
		"timestamp": "",
		"idempotency_key": "",
		"payload": {},
		"extra": {},
		"unknown_fields": {},
		"deprecated_fields": {},
		"validation_warnings": [],
	}


static func normalize_asset_event(raw_event: Dictionary = {}) -> Dictionary:
	var result := _normalize_with_defaults(raw_event, default_asset_event())
	result["event_type"] = StringName(result.get("event_type", EVENT_TYPE_ITEM))
	result["event_action"] = StringName(result.get("event_action", EVENT_ACTION_GAIN))
	result["asset_type"] = StringName(result.get("asset_type", AssetContractScript.ASSET_TYPE_ENTITY_ITEM))
	result["quantity"] = int(result.get("quantity", 0))
	result["source_system"] = StringName(result.get("source_system", AssetContractScript.SOURCE_SYSTEM_UNKNOWN))
	result["from_location"] = StringName(result.get("from_location", AssetContractScript.LOCATION_UNKNOWN))
	result["to_location"] = StringName(result.get("to_location", AssetContractScript.LOCATION_UNKNOWN))
	if not (result.get("payload", {}) is Dictionary):
		result["payload"] = {"value": result.get("payload")}
	return result


static func validate_asset_event(asset_event: Dictionary) -> Dictionary:
	var warnings: Array[String] = []
	if int(asset_event.get("schema_version", 0)) != SCHEMA_VERSION:
		warnings.append("schema_version_mismatch")
	if String(asset_event.get("event_id", "")).is_empty():
		warnings.append("missing_event_id")
	if not EVENT_TYPES.has(StringName(asset_event.get("event_type", &""))):
		warnings.append("unknown_event_type")
	if not EVENT_ACTIONS.has(StringName(asset_event.get("event_action", &""))):
		warnings.append("unknown_event_action")
	if not AssetContractScript.asset_types().has(StringName(asset_event.get("asset_type", &""))):
		warnings.append("unknown_asset_type")
	if int(asset_event.get("quantity", 0)) < 0:
		warnings.append("negative_quantity")
	if String(asset_event.get("source_system", "")).is_empty():
		warnings.append("missing_source_system")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func event_types() -> Array:
	return EVENT_TYPES.duplicate()


static func event_actions() -> Array:
	return EVENT_ACTIONS.duplicate()


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


static func _copy_value(value: Variant) -> Variant:
	if (value is Dictionary) or (value is Array):
		return value.duplicate(true)
	return value
