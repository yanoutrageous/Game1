extends RefCounted
class_name AssetContract

const SCHEMA_VERSION := 1

const ASSET_CATEGORY_RESOURCE := &"resource"
const ASSET_CATEGORY_ITEM := &"item"
const ASSET_CATEGORY_COSMETIC_UNLOCK := &"cosmetic_unlock"
const ASSET_CATEGORY_RECORD_OR_FUNCTION_UNLOCK := &"record_or_function_unlock"
const ASSET_CATEGORIES := [
	ASSET_CATEGORY_RESOURCE,
	ASSET_CATEGORY_ITEM,
	ASSET_CATEGORY_COSMETIC_UNLOCK,
	ASSET_CATEGORY_RECORD_OR_FUNCTION_UNLOCK,
]

const ASSET_TYPE_RESOURCE := &"resource"
const ASSET_TYPE_ENTITY_ITEM := &"entity_item"
const ASSET_TYPE_COSMETIC_UNLOCK := &"cosmetic_unlock"
const ASSET_TYPE_CODEX_RECORD := &"codex_record"
const ASSET_TYPE_RESEARCH_UNLOCK := &"research_unlock"
const ASSET_TYPE_HISTORY_RECORD := &"history_record"
const ASSET_TYPE_PROFILE_UNLOCK := &"profile_unlock"
const ASSET_TYPES := [
	ASSET_TYPE_RESOURCE,
	ASSET_TYPE_ENTITY_ITEM,
	ASSET_TYPE_COSMETIC_UNLOCK,
	ASSET_TYPE_CODEX_RECORD,
	ASSET_TYPE_RESEARCH_UNLOCK,
	ASSET_TYPE_HISTORY_RECORD,
	ASSET_TYPE_PROFILE_UNLOCK,
]

const ITEM_MAIN_TYPE_EQUIPMENT := &"equipment"
const ITEM_MAIN_TYPE_CONSUMABLE := &"consumable"
const ITEM_MAIN_TYPE_COLLECTIBLE := &"collectible"
const ITEM_MAIN_TYPE_SPECIAL := &"special"
const ITEM_MAIN_TYPES := [
	ITEM_MAIN_TYPE_EQUIPMENT,
	ITEM_MAIN_TYPE_CONSUMABLE,
	ITEM_MAIN_TYPE_COLLECTIBLE,
	ITEM_MAIN_TYPE_SPECIAL,
]

const NON_MAIN_TYPE_MAPPINGS := {
	&"unique": {
		"maps_to": ITEM_MAIN_TYPE_COLLECTIBLE,
		"field": &"rarity_or_special_kind",
		"reason": "unique_is_collectible_variant",
	},
	&"cosmetic": {
		"maps_to": ASSET_CATEGORY_COSMETIC_UNLOCK,
		"field": &"asset_category",
		"reason": "cosmetic_unlock_not_item_main_type",
	},
	&"gacha_item": {
		"maps_to": &"source_system",
		"field": &"source_system",
		"reason": "gacha_is_source_not_item_main_type",
	},
	&"task_item": {
		"maps_to": ITEM_MAIN_TYPE_SPECIAL,
		"field": &"item_main_type_with_task_tag",
		"reason": "task_item_is_special_with_metadata",
	},
	&"commission_item": {
		"maps_to": ITEM_MAIN_TYPE_SPECIAL,
		"field": &"item_main_type_or_collectible_with_source",
		"reason": "commission_item_is_source_mapping",
	},
	&"sample": {
		"maps_to": ITEM_MAIN_TYPE_SPECIAL,
		"field": &"item_sub_type_with_sample_tag",
		"reason": "sample_is_special_item_sub_type",
	},
	&"unidentified_value": {
		"maps_to": &"identification_state",
		"field": &"identification_state",
		"reason": "reserved_identification_state",
	},
	&"codex_entry": {
		"maps_to": ASSET_CATEGORY_RECORD_OR_FUNCTION_UNLOCK,
		"field": &"asset_category",
		"reason": "codex_entry_is_record",
	},
	&"research_unlock": {
		"maps_to": ASSET_CATEGORY_RECORD_OR_FUNCTION_UNLOCK,
		"field": &"asset_category",
		"reason": "research_unlock_is_function_unlock",
	},
}

const SOURCE_SYSTEM_UNKNOWN := &"unknown"
const SOURCE_SYSTEM_RUN := &"run"
const SOURCE_SYSTEM_WAREHOUSE := &"warehouse"
const SOURCE_SYSTEM_DEPLOY_PREP := &"deploy_prep"
const SOURCE_SYSTEM_SETTLEMENT := &"settlement"
const SOURCE_SYSTEM_HISTORY := &"history"
const SOURCE_SYSTEM_CODEX := &"codex"
const SOURCE_SYSTEM_RESEARCH := &"research"
const SOURCE_SYSTEM_GACHA := &"gacha"
const SOURCE_SYSTEM_OBJECTIVE := &"objective"
const SOURCE_SYSTEM_LONG_TERM := &"long_term"
const SOURCE_SYSTEMS := [
	SOURCE_SYSTEM_UNKNOWN,
	SOURCE_SYSTEM_RUN,
	SOURCE_SYSTEM_WAREHOUSE,
	SOURCE_SYSTEM_DEPLOY_PREP,
	SOURCE_SYSTEM_SETTLEMENT,
	SOURCE_SYSTEM_HISTORY,
	SOURCE_SYSTEM_CODEX,
	SOURCE_SYSTEM_RESEARCH,
	SOURCE_SYSTEM_GACHA,
	SOURCE_SYSTEM_OBJECTIVE,
	SOURCE_SYSTEM_LONG_TERM,
]

const LOCATION_UNKNOWN := &"unknown"
const LOCATION_RUN_BAG := &"run_bag"
const LOCATION_RUN_FLOOR := &"run_floor"
const LOCATION_WAREHOUSE := &"warehouse"
const LOCATION_DISPLAY := &"display"
const LOCATION_SETTLEMENT := &"settlement"
const LOCATION_HISTORY := &"history"
const LOCATION_LOST := &"lost"
const LOCATIONS := [
	LOCATION_UNKNOWN,
	LOCATION_RUN_BAG,
	LOCATION_RUN_FLOOR,
	LOCATION_WAREHOUSE,
	LOCATION_DISPLAY,
	LOCATION_SETTLEMENT,
	LOCATION_HISTORY,
	LOCATION_LOST,
]

const PROJECTION_WAREHOUSE := &"warehouse_projection"
const PROJECTION_DEPLOY_PREP := &"deploy_prep_projection"
const PROJECTION_SETTLEMENT := &"settlement_projection"
const PROJECTION_HISTORY := &"history_projection"
const PROJECTION_CODEX := &"codex_projection"
const PROJECTION_RESEARCH := &"research_projection"
const PROJECTION_GACHA := &"gacha_projection"
const PROJECTION_OBJECTIVE := &"objective_projection"
const PROJECTION_LONG_TERM := &"long_term_projection"
const PROJECTION_TARGETS := [
	PROJECTION_WAREHOUSE,
	PROJECTION_DEPLOY_PREP,
	PROJECTION_SETTLEMENT,
	PROJECTION_HISTORY,
	PROJECTION_CODEX,
	PROJECTION_RESEARCH,
	PROJECTION_GACHA,
	PROJECTION_OBJECTIVE,
	PROJECTION_LONG_TERM,
]

const POLICY_KEYS := [
	&"sell_policy",
	&"deploy_policy",
	&"equip_policy",
	&"use_policy",
	&"stack_policy",
	&"settlement_policy",
	&"end_run_policy",
	&"display_policy",
	&"codex_policy",
	&"research_policy",
	&"duplicate_policy",
	&"preserve_policy",
]

const TAG_KEYS := [
	&"source",
	&"display",
	&"filter",
	&"routing",
	&"record",
]

const SCHEMA_KEY_VERSION := &"schema_version"
const SCHEMA_KEY_EXTRA := &"extra"
const SCHEMA_KEY_UNKNOWN_FIELDS := &"unknown_fields"
const SCHEMA_KEY_DEPRECATED_FIELDS := &"deprecated_fields"
const SCHEMA_KEY_VALIDATION_WARNINGS := &"validation_warnings"


static func schema_version() -> int:
	return SCHEMA_VERSION


static func asset_categories() -> Array:
	return ASSET_CATEGORIES.duplicate()


static func asset_types() -> Array:
	return ASSET_TYPES.duplicate()


static func item_main_types() -> Array:
	return ITEM_MAIN_TYPES.duplicate()


static func non_main_type_mappings() -> Dictionary:
	return NON_MAIN_TYPE_MAPPINGS.duplicate(true)


static func source_systems() -> Array:
	return SOURCE_SYSTEMS.duplicate()


static func locations() -> Array:
	return LOCATIONS.duplicate()


static func projection_targets() -> Array:
	return PROJECTION_TARGETS.duplicate()


static func policy_keys() -> Array:
	return POLICY_KEYS.duplicate()


static func tag_keys() -> Array:
	return TAG_KEYS.duplicate()


static func default_schema_base(schema_kind: StringName = &"asset_contract") -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": schema_kind,
		"extra": {},
		"unknown_fields": {},
		"deprecated_fields": {},
		"validation_warnings": [],
	}


static func default_policy(default_value: StringName = &"unspecified") -> Dictionary:
	var policy := {}
	for key in POLICY_KEYS:
		policy[key] = default_value
	return policy


static func default_tag_entry(tag_id: StringName = &"", tag_type: StringName = &"display") -> Dictionary:
	return {
		"tag_id": tag_id,
		"tag_type": tag_type,
		"label": "",
		"source_system": SOURCE_SYSTEM_UNKNOWN,
		"metadata": {},
	}


static func default_asset_ref(asset_category: StringName = ASSET_CATEGORY_ITEM, asset_type: StringName = ASSET_TYPE_ENTITY_ITEM) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"asset_category": asset_category,
		"asset_type": asset_type,
		"asset_id": "",
		"definition_id": "",
		"instance_id": "",
		"stack_id": "",
		"quantity": 0,
		"source_system": SOURCE_SYSTEM_UNKNOWN,
		"location": LOCATION_UNKNOWN,
		"extra": {},
		"unknown_fields": {},
		"deprecated_fields": {},
		"validation_warnings": [],
	}


static func normalize_policy(raw_policy: Dictionary = {}) -> Dictionary:
	var policy := default_policy()
	for key in raw_policy.keys():
		if POLICY_KEYS.has(StringName(key)):
			policy[StringName(key)] = raw_policy[key]
		else:
			if not policy.has("unknown_fields"):
				policy["unknown_fields"] = {}
			policy["unknown_fields"][String(key)] = _copy_value(raw_policy[key])
	return policy


static func normalize_tags(raw_tags: Variant = []) -> Array:
	var tags: Array = []
	if not (raw_tags is Array):
		return tags
	for entry in raw_tags:
		if entry is Dictionary:
			tags.append(_normalize_with_defaults(entry, default_tag_entry()))
		else:
			tags.append(default_tag_entry(StringName(String(entry))))
	return tags


static func normalize_asset_ref(raw_ref: Dictionary = {}) -> Dictionary:
	var result := _normalize_with_defaults(raw_ref, default_asset_ref())
	result["asset_category"] = StringName(result.get("asset_category", ASSET_CATEGORY_ITEM))
	result["asset_type"] = StringName(result.get("asset_type", ASSET_TYPE_ENTITY_ITEM))
	result["source_system"] = StringName(result.get("source_system", SOURCE_SYSTEM_UNKNOWN))
	result["location"] = StringName(result.get("location", LOCATION_UNKNOWN))
	result["quantity"] = int(result.get("quantity", 0))
	return result


static func validate_asset_ref(asset_ref: Dictionary) -> Dictionary:
	var warnings: Array[String] = []
	var asset_category := StringName(asset_ref.get("asset_category", &""))
	var asset_type := StringName(asset_ref.get("asset_type", &""))
	if int(asset_ref.get("schema_version", 0)) != SCHEMA_VERSION:
		warnings.append("schema_version_mismatch")
	if not ASSET_CATEGORIES.has(asset_category):
		warnings.append("unknown_asset_category:%s" % String(asset_category))
	if not ASSET_TYPES.has(asset_type):
		warnings.append("unknown_asset_type:%s" % String(asset_type))
	if int(asset_ref.get("quantity", 0)) < 0:
		warnings.append("negative_quantity")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func is_asset_category(value: Variant) -> bool:
	return ASSET_CATEGORIES.has(StringName(value))


static func is_item_main_type(value: Variant) -> bool:
	return ITEM_MAIN_TYPES.has(StringName(value))


static func is_projection_target(value: Variant) -> bool:
	return PROJECTION_TARGETS.has(StringName(value))


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
