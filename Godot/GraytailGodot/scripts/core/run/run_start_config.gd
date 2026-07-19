extends RefCounted
class_name RunStartConfig

const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")

const SUPPORTED_ROUTE_MODES := [&"standard_run", &"demo_run", &"tutorial_run"]
const SUPPORTED_PREVIEW_FIELDS := [
	"config_id",
	"config_version",
	"map_config_id",
	"map_display_name",
	"seed_value",
	"start_mode",
	"map_mode",
	"difficulty",
	"region_id",
	"source_page",
	"run_origin",
	"selected_loadout",
	"carried_consumables",
	"selected_equipment_items",
	"selected_consumable_items",
	"selected_equipment_ids",
	"selected_consumable_ids",
	"commission_candidates",
	"selected_objective_id",
	"selected_objective_label",
	"equipment_effects",
	"warehouse_lite",
	"codex_lite",
	"bag_used",
	"bag_limit",
	"backpack_capacity",
	"failure_salvage_capacity",
	"profile_fields",
	"talent_interface",
	"active_talent_effects",
	"profile_level",
	"profile_exp",
	"permit_level",
	"protocol_difficulty",
	"mine_dmg_reduce",
	"protocol_pressure_reduce",
	"search_reward_bonus",
	"scan_hint_bonus",
	"preview",
	"display_only",
	"read_only",
]


static func default_config() -> Dictionary:
	return {
		"schema_version": 1,
		"route_mode": &"standard_run",
		"source_page": &"unknown",
		"profile_id": "default",
		"config_id": "standard_10x10",
		"map_config_id": "classic_10x10_standard",
		"map_display_name": "10×10 标准",
		"seed_value": 0,
		"uses_existing_route": true,
		"unsupported_config_fields": [],
		"fallback_reason": "",
		"selected_equipment_items": [],
		"selected_consumable_items": [],
		"selected_equipment_ids": [],
		"selected_consumable_ids": [],
		"commission_candidates": [],
		"selected_objective_id": &"commission_recover_supply",
		"selected_objective_label": "回收补给箱",
		"equipment_effects": [],
		"warehouse_lite": {},
		"codex_lite": {},
		"bag_used": 0,
		"bag_limit": 10,
		"backpack_capacity": 10,
		"failure_salvage_capacity": 4,
		"profile_fields": {},
		"talent_interface": [],
		"active_talent_effects": [],
		"profile_level": 1,
		"profile_exp": 0,
		"permit_level": 1,
		"protocol_difficulty": 5,
		"mine_dmg_reduce": 0,
		"protocol_pressure_reduce": 0,
		"search_reward_bonus": 0,
		"scan_hint_bonus": 0,
		"preview": false,
		"display_only": false,
		"read_only": false,
	}


static func normalize(payload: Dictionary) -> Dictionary:
	var result := default_config()
	for key in result.keys():
		if payload.has(key):
			result[key] = payload[key]
	var preview := _dictionary_from(payload.get("run_start_config_preview", payload.get("run_start_config", {})))
	var unsupported: Array[String] = []
	for key in preview.keys():
		if not SUPPORTED_PREVIEW_FIELDS.has(str(key)):
			unsupported.append(str(key))
	if payload.has("unsupported_config_fields"):
		for item in _array_from(payload.get("unsupported_config_fields", [])):
			var item_text := str(item)
			if item_text != "" and not unsupported.has(item_text):
				unsupported.append(item_text)
	result["unsupported_config_fields"] = unsupported
	result["source_page"] = StringName(payload.get("source_page", result.get("source_page", &"unknown")))
	result["profile_id"] = str(payload.get("profile_id", result.get("profile_id", "default")))
	result["config_id"] = str(preview.get("config_id", payload.get("config_id", result.get("config_id", "standard_10x10"))))
	for key in SUPPORTED_PREVIEW_FIELDS:
		if preview.has(key):
			result[key] = preview[key]
	var requested_route := StringName(payload.get("route_mode", _route_mode_from_preview(preview)))
	if not SUPPORTED_ROUTE_MODES.has(requested_route):
		result["fallback_reason"] = "unsupported_route_mode:%s" % str(requested_route)
		requested_route = &"standard_run"
	elif not unsupported.is_empty() and str(result.get("fallback_reason", "")) == "":
		result["fallback_reason"] = "unsupported_config_fields"
	result["route_mode"] = requested_route
	result["uses_existing_route"] = true
	result["preview"] = bool(preview.get("preview", false))
	result["display_only"] = bool(preview.get("display_only", false))
	result["read_only"] = bool(preview.get("read_only", false))
	return result


static func validate(config: Dictionary) -> Dictionary:
	var normalized := normalize(config)
	var issues: Array[String] = []
	if not bool(normalized.get("uses_existing_route", false)):
		issues.append("route_must_use_existing_start_path")
	if not SUPPORTED_ROUTE_MODES.has(StringName(normalized.get("route_mode", &""))):
		issues.append("unsupported_route_mode")
	var known_map := false
	for definition in M7ContentCatalogScript.map_definitions():
		if str(definition.get("id", "")) == str(normalized.get("map_config_id", "")):
			known_map = true
			break
	if not known_map:
		issues.append("unknown_map_config_id")
	var equipment := _array_from(normalized.get("selected_equipment_items", []))
	var consumables := _array_from(normalized.get("selected_consumable_items", []))
	if equipment.size() > 2:
		issues.append("equipment_count_exceeds_2")
	if consumables.size() > 3:
		issues.append("consumable_count_exceeds_3")
	var instance_ids: Dictionary = {}
	var equipment_slots: Dictionary = {}
	for raw_item in equipment:
		var item := _dictionary_from(raw_item)
		var instance_id := str(item.get("instance_id", ""))
		if instance_id == "" or instance_ids.has(instance_id):
			issues.append("duplicate_or_empty_equipment_instance")
		else:
			instance_ids[instance_id] = true
		if item.has("can_equip") and not bool(item.get("can_equip", false)):
			issues.append("non_equipment_in_equipment_selection")
		var slot := str(item.get("equipment_slot", ""))
		if slot != "" and equipment_slots.has(slot):
			issues.append("duplicate_equipment_slot:%s" % slot)
		elif slot != "":
			equipment_slots[slot] = true
	var carried_weight := 0
	for raw_item in consumables:
		var item := _dictionary_from(raw_item)
		var instance_id := str(item.get("instance_id", ""))
		if instance_id == "" or instance_ids.has(instance_id):
			issues.append("duplicate_or_empty_consumable_instance")
		else:
			instance_ids[instance_id] = true
		if item.has("can_consume") and not bool(item.get("can_consume", false)):
			issues.append("non_consumable_in_consumable_selection")
		carried_weight += maxi(0, int(item.get("weight", 0)))
	if carried_weight > int(normalized.get("backpack_capacity", normalized.get("bag_limit", 10))):
		issues.append("carry_weight_exceeds_backpack_capacity")
	return {
		"ok": issues.is_empty(),
		"issues": issues,
		"config": normalized,
		"read_only": bool(normalized.get("read_only", false)),
		"display_only": bool(normalized.get("display_only", false)),
		"preview": bool(normalized.get("preview", false)),
	}


static func _route_mode_from_preview(preview: Dictionary) -> StringName:
	var start_mode := StringName(preview.get("start_mode", &"standard_preview"))
	match start_mode:
		&"demo", &"demo_run", &"demo_preview":
			return &"demo_run"
		&"tutorial", &"tutorial_run":
			return &"tutorial_run"
		_:
			return &"standard_run"


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


static func _array_from(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []
