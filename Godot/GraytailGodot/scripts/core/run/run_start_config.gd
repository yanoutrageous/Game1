extends RefCounted
class_name RunStartConfig

const SUPPORTED_ROUTE_MODES := [&"standard_run", &"demo_run", &"tutorial_run"]
const SUPPORTED_PREVIEW_FIELDS := [
	"config_id",
	"config_version",
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
		"uses_existing_route": true,
		"unsupported_config_fields": [],
		"fallback_reason": "",
		"selected_equipment_items": [],
		"selected_consumable_items": [],
		"selected_equipment_ids": [],
		"selected_consumable_ids": [],
		"equipment_effects": [],
		"warehouse_lite": {},
		"codex_lite": {},
		"bag_used": 0,
		"bag_limit": 10,
		"backpack_capacity": 10,
		"failure_salvage_capacity": 1,
		"profile_fields": {},
		"talent_interface": [],
		"active_talent_effects": [],
		"profile_level": 1,
		"profile_exp": 0,
		"permit_level": 1,
		"protocol_difficulty": 5,
		"mine_dmg_reduce": 0,
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
