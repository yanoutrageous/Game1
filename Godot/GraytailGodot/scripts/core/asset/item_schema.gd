extends RefCounted
class_name ItemSchema

const AssetContractScript := preload("res://scripts/core/asset/asset_contract.gd")

const SCHEMA_VERSION := 1
const ITEM_DEFINITION_KIND := &"ItemDefinition"
const ITEM_INSTANCE_KIND := &"ItemInstance"
const ITEM_STACK_KIND := &"ItemStack"

const RARITY_COMMON := &"common"
const RARITY_UNCOMMON := &"uncommon"
const RARITY_RARE := &"rare"
const RARITY_EPIC := &"epic"
const RARITY_LEGENDARY := &"legendary"
const RARITY_UNIQUE := &"unique"
const RARITIES := [
	RARITY_COMMON,
	RARITY_UNCOMMON,
	RARITY_RARE,
	RARITY_EPIC,
	RARITY_LEGENDARY,
	RARITY_UNIQUE,
]

const IDENTIFICATION_UNKNOWN := &"unknown"
const IDENTIFICATION_IDENTIFIED := &"identified"
const IDENTIFICATION_UNJUDGED_VALUE := &"unjudged_value"
const IDENTIFICATION_STATES := [
	IDENTIFICATION_UNKNOWN,
	IDENTIFICATION_IDENTIFIED,
	IDENTIFICATION_UNJUDGED_VALUE,
]

const UNIQUE_DUPLICATE_UNSPECIFIED := &"unspecified"
const UNIQUE_DUPLICATE_BLOCK := &"block_duplicate"
const UNIQUE_DUPLICATE_CONVERT_RESOURCE := &"convert_resource"
const UNIQUE_DUPLICATE_CONVERT_TICKET := &"convert_ticket"
const UNIQUE_DUPLICATE_SPECIAL_REWARD := &"convert_special_reward"


static func default_item_definition() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": ITEM_DEFINITION_KIND,
		"asset_category": AssetContractScript.ASSET_CATEGORY_ITEM,
		"asset_type": AssetContractScript.ASSET_TYPE_ENTITY_ITEM,
		"definition_id": "",
		"item_id": "",
		"item_main_type": AssetContractScript.ITEM_MAIN_TYPE_SPECIAL,
		"item_sub_type": "",
		"rarity": RARITY_COMMON,
		"display_name": "",
		"short_description": "",
		"detail_description": "",
		"codex_text": "",
		"weight": 0,
		"base_value": 0,
		"stack_policy": &"unspecified",
		"sell_policy": &"unspecified",
		"deploy_policy": &"unspecified",
		"equip_policy": &"unspecified",
		"use_policy": &"unspecified",
		"end_run_policy": &"unspecified",
		"settlement_policy": &"unspecified",
		"display_policy": &"unspecified",
		"codex_policy": &"unspecified",
		"research_policy": &"unspecified",
		"duplicate_policy": &"unspecified",
		"preserve_policy": &"unspecified",
		"policy": AssetContractScript.default_policy(),
		"tags": [],
		"default_tags": [],
		"codex_ref": "",
		"research_ref": "",
		"display_ref": "",
		"attached_cosmetic_ref": "",
		"identification_state": IDENTIFICATION_UNKNOWN,
		"unique_duplicate_policy": UNIQUE_DUPLICATE_UNSPECIFIED,
		"extra": {},
		"unknown_fields": {},
		"deprecated_fields": {},
		"validation_warnings": [],
	}


static func default_item_instance() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": ITEM_INSTANCE_KIND,
		"asset_category": AssetContractScript.ASSET_CATEGORY_ITEM,
		"asset_type": AssetContractScript.ASSET_TYPE_ENTITY_ITEM,
		"definition_id": "",
		"item_id": "",
		"instance_id": "",
		"stack_id": "",
		"item_main_type": AssetContractScript.ITEM_MAIN_TYPE_SPECIAL,
		"item_sub_type": "",
		"rarity": RARITY_COMMON,
		"quantity": 1,
		"location": AssetContractScript.LOCATION_UNKNOWN,
		"source_system": AssetContractScript.SOURCE_SYSTEM_UNKNOWN,
		"source_run_id": "",
		"source_event_id": "",
		"state_summary": {},
		"policy": AssetContractScript.default_policy(),
		"tags": [],
		"extra": {},
		"unknown_fields": {},
		"deprecated_fields": {},
		"validation_warnings": [],
	}


static func default_item_stack() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": ITEM_STACK_KIND,
		"asset_category": AssetContractScript.ASSET_CATEGORY_ITEM,
		"asset_type": AssetContractScript.ASSET_TYPE_ENTITY_ITEM,
		"definition_id": "",
		"item_id": "",
		"stack_id": "",
		"instance_ids": [],
		"item_main_type": AssetContractScript.ITEM_MAIN_TYPE_SPECIAL,
		"item_sub_type": "",
		"rarity": RARITY_COMMON,
		"quantity": 0,
		"location": AssetContractScript.LOCATION_UNKNOWN,
		"source_system": AssetContractScript.SOURCE_SYSTEM_UNKNOWN,
		"policy": AssetContractScript.default_policy(),
		"tags": [],
		"extra": {},
		"unknown_fields": {},
		"deprecated_fields": {},
		"validation_warnings": [],
	}


static func normalize_item_definition(raw_definition: Dictionary = {}) -> Dictionary:
	var result := _normalize_with_defaults(raw_definition, default_item_definition())
	result["asset_category"] = StringName(result.get("asset_category", AssetContractScript.ASSET_CATEGORY_ITEM))
	result["asset_type"] = StringName(result.get("asset_type", AssetContractScript.ASSET_TYPE_ENTITY_ITEM))
	result["item_main_type"] = StringName(result.get("item_main_type", AssetContractScript.ITEM_MAIN_TYPE_SPECIAL))
	result["rarity"] = StringName(result.get("rarity", RARITY_COMMON))
	result["identification_state"] = StringName(result.get("identification_state", IDENTIFICATION_UNKNOWN))
	result["policy"] = AssetContractScript.normalize_policy(_dictionary_from(result.get("policy", {})))
	result["tags"] = AssetContractScript.normalize_tags(result.get("tags", []))
	result["default_tags"] = AssetContractScript.normalize_tags(result.get("default_tags", []))
	return result


static func normalize_item_instance(raw_instance: Dictionary = {}) -> Dictionary:
	var result := _normalize_with_defaults(raw_instance, default_item_instance())
	result["asset_category"] = StringName(result.get("asset_category", AssetContractScript.ASSET_CATEGORY_ITEM))
	result["asset_type"] = StringName(result.get("asset_type", AssetContractScript.ASSET_TYPE_ENTITY_ITEM))
	result["item_main_type"] = StringName(result.get("item_main_type", AssetContractScript.ITEM_MAIN_TYPE_SPECIAL))
	result["rarity"] = StringName(result.get("rarity", RARITY_COMMON))
	result["quantity"] = int(result.get("quantity", 1))
	result["location"] = StringName(result.get("location", AssetContractScript.LOCATION_UNKNOWN))
	result["source_system"] = StringName(result.get("source_system", AssetContractScript.SOURCE_SYSTEM_UNKNOWN))
	result["policy"] = AssetContractScript.normalize_policy(_dictionary_from(result.get("policy", {})))
	result["tags"] = AssetContractScript.normalize_tags(result.get("tags", []))
	return result


static func normalize_item_stack(raw_stack: Dictionary = {}) -> Dictionary:
	var result := _normalize_with_defaults(raw_stack, default_item_stack())
	result["asset_category"] = StringName(result.get("asset_category", AssetContractScript.ASSET_CATEGORY_ITEM))
	result["asset_type"] = StringName(result.get("asset_type", AssetContractScript.ASSET_TYPE_ENTITY_ITEM))
	result["item_main_type"] = StringName(result.get("item_main_type", AssetContractScript.ITEM_MAIN_TYPE_SPECIAL))
	result["rarity"] = StringName(result.get("rarity", RARITY_COMMON))
	result["quantity"] = int(result.get("quantity", 0))
	result["location"] = StringName(result.get("location", AssetContractScript.LOCATION_UNKNOWN))
	result["source_system"] = StringName(result.get("source_system", AssetContractScript.SOURCE_SYSTEM_UNKNOWN))
	result["policy"] = AssetContractScript.normalize_policy(_dictionary_from(result.get("policy", {})))
	result["tags"] = AssetContractScript.normalize_tags(result.get("tags", []))
	return result


static func validate_item_definition(item_definition: Dictionary) -> Dictionary:
	var warnings := _base_item_warnings(item_definition)
	if String(item_definition.get("definition_id", "")).is_empty():
		warnings.append("missing_definition_id")
	var rarity := StringName(item_definition.get("rarity", RARITY_COMMON))
	var main_type := StringName(item_definition.get("item_main_type", &""))
	if rarity == RARITY_UNIQUE and main_type != AssetContractScript.ITEM_MAIN_TYPE_COLLECTIBLE:
		warnings.append("unique_must_remain_collectible")
	if not IDENTIFICATION_STATES.has(StringName(item_definition.get("identification_state", IDENTIFICATION_UNKNOWN))):
		warnings.append("unknown_identification_state")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func validate_item_instance(item_instance: Dictionary) -> Dictionary:
	var warnings := _base_item_warnings(item_instance)
	if String(item_instance.get("instance_id", "")).is_empty():
		warnings.append("missing_instance_id")
	if int(item_instance.get("quantity", 0)) < 0:
		warnings.append("negative_quantity")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func validate_item_stack(item_stack: Dictionary) -> Dictionary:
	var warnings := _base_item_warnings(item_stack)
	if String(item_stack.get("stack_id", "")).is_empty():
		warnings.append("missing_stack_id")
	if int(item_stack.get("quantity", 0)) < 0:
		warnings.append("negative_quantity")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func _base_item_warnings(item_data: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	if int(item_data.get("schema_version", 0)) != SCHEMA_VERSION:
		warnings.append("schema_version_mismatch")
	if StringName(item_data.get("asset_category", &"")) != AssetContractScript.ASSET_CATEGORY_ITEM:
		warnings.append("asset_category_must_be_item")
	if not AssetContractScript.item_main_types().has(StringName(item_data.get("item_main_type", &""))):
		warnings.append("unknown_item_main_type")
	if not RARITIES.has(StringName(item_data.get("rarity", RARITY_COMMON))):
		warnings.append("unknown_rarity")
	return warnings


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


static func _copy_value(value: Variant) -> Variant:
	if (value is Dictionary) or (value is Array):
		return value.duplicate(true)
	return value
