extends RefCounted
class_name RunStartConfig

const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const M3RItemUsabilityModelScript := preload("res://scripts/core/content/m3r_item_usability_model.gd")
const PlayerAppearanceConfigScript := preload("res://scripts/core/content/player_appearance_config.gd")

const SUPPORTED_ROUTE_MODES := [&"standard_run", &"demo_run"]
const SUPPORTED_PREVIEW_FIELDS := [
	"config_id",
	"config_version",
	"map_config_id",
	"map_display_name",
	"seed_value",
	"start_mode",
	"map_mode",
	"difficulty",
	"difficulty_label",
	"selected_difficulty",
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
	"player_appearance",
	"tutorial_map",
	"tutorial_completed",
	"persistence_policy",
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
		"difficulty": &"standard",
		"difficulty_label": "标准",
		"selected_difficulty": &"standard",
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
		"player_appearance": PlayerAppearanceConfigScript.default_config(),
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


static func authorize_with_meta(config: Dictionary, meta_summary: Dictionary) -> Dictionary:
	var structural := validate(config)
	var normalized := _dictionary_from(structural.get("config", {}))
	var issues: Array[String] = []
	for raw_issue in _array_from(structural.get("issues", [])):
		issues.append(str(raw_issue))
	var map_id := str(normalized.get("map_config_id", ""))
	var map_definition := M7ContentCatalogScript.map_definition_exact(map_id)
	if map_definition.is_empty():
		if not issues.has("unknown_map_config_id"):
			issues.append("unknown_map_config_id")
	else:
		var unlocked_map_ids := _array_from(meta_summary.get("unlocked_map_ids", []))
		if not unlocked_map_ids.has(map_id):
			issues.append("map_not_unlocked")
		var expected_difficulty := StringName(map_definition.get("difficulty", &""))
		var requested_difficulty := StringName(normalized.get("difficulty", &""))
		if requested_difficulty != &"" and requested_difficulty != expected_difficulty:
			issues.append("difficulty_mismatch")

	var raw_warehouse: Array = []
	var raw_warehouse_value: Variant = meta_summary.get("warehouse_items", [])
	if not raw_warehouse_value is Array:
		issues.append("warehouse_items_not_array")
	else:
		raw_warehouse = (raw_warehouse_value as Array).duplicate(true)
	var raw_warehouse_instance_ids: Dictionary = {}
	for raw_index in range(raw_warehouse.size()):
		var raw_item_value: Variant = raw_warehouse[raw_index]
		if not raw_item_value is Dictionary:
			issues.append("warehouse_item_not_dictionary:%d" % raw_index)
			continue
		var raw_item := raw_item_value as Dictionary
		var raw_instance_id := str(raw_item.get("instance_id", "")).strip_edges()
		if raw_instance_id == "":
			issues.append("warehouse_instance_id_empty:%d" % raw_index)
		elif raw_warehouse_instance_ids.has(raw_instance_id):
			issues.append("warehouse_instance_id_duplicate:%s" % raw_instance_id)
		else:
			raw_warehouse_instance_ids[raw_instance_id] = true

	var warehouse_items := M3RItemUsabilityModelScript.normalize_warehouse_items(meta_summary)
	var warehouse_by_instance: Dictionary = {}
	for item in warehouse_items:
		var instance_id := str(item.get("instance_id", ""))
		if instance_id != "":
			warehouse_by_instance[instance_id] = item.duplicate(true)

	var selected_equipment_ids := _selected_instance_ids(
		normalized.get("selected_equipment_ids", []),
		normalized.get("selected_equipment_items", [])
	)
	var selected_consumable_ids := _selected_instance_ids(
		normalized.get("selected_consumable_ids", []),
		normalized.get("selected_consumable_items", [])
	)
	var selected_instance_ids: Dictionary = {}
	var selected_equipment: Array[Dictionary] = []
	var selected_consumables: Array[Dictionary] = []
	for instance_id in selected_equipment_ids:
		if selected_instance_ids.has(instance_id):
			issues.append("duplicate_selected_instance:%s" % instance_id)
			continue
		selected_instance_ids[instance_id] = true
		var item := _dictionary_from(warehouse_by_instance.get(instance_id, {}))
		if item.is_empty():
			issues.append("equipment_instance_not_in_warehouse:%s" % instance_id)
		elif str(item.get("item_type", "")) != "equipment" or not bool(item.get("can_equip", false)):
			issues.append("warehouse_instance_not_equipment:%s" % instance_id)
		else:
			selected_equipment.append(item)
	for instance_id in selected_consumable_ids:
		if selected_instance_ids.has(instance_id):
			issues.append("duplicate_selected_instance:%s" % instance_id)
			continue
		selected_instance_ids[instance_id] = true
		var item := _dictionary_from(warehouse_by_instance.get(instance_id, {}))
		if item.is_empty():
			issues.append("consumable_instance_not_in_warehouse:%s" % instance_id)
		elif str(item.get("item_type", "")) != "consumable" or not bool(item.get("can_consume", false)):
			issues.append("warehouse_instance_not_consumable:%s" % instance_id)
		else:
			selected_consumables.append(item)

	if selected_equipment.size() > 2:
		issues.append("equipment_count_exceeds_2")
	if selected_consumables.size() > 3:
		issues.append("consumable_count_exceeds_3")
	var equipment_slots: Dictionary = {}
	for item in selected_equipment:
		var slot := str(item.get("equipment_slot", ""))
		if slot != "" and equipment_slots.has(slot):
			issues.append("duplicate_equipment_slot:%s" % slot)
		elif slot != "":
			equipment_slots[slot] = true

	var profile := M3RItemUsabilityModelScript.build_profile_interfaces(meta_summary)
	var equipment_effects := M3RItemUsabilityModelScript.build_equipment_effects(selected_equipment)
	var backpack_capacity := int(profile.get(
		"backpack_capacity",
		M3RItemUsabilityModelScript.BASE_BACKPACK_CAPACITY
	))
	var failure_salvage_capacity := int(profile.get(
		"failure_salvage_capacity",
		M3RItemUsabilityModelScript.BASE_FAILURE_SALVAGE_CAPACITY
	))
	var mine_dmg_reduce := int(profile.get("mine_dmg_reduce", 0))
	var protocol_pressure_reduce := int(profile.get("protocol_pressure_reduce", 0))
	var search_reward_bonus := int(profile.get("search_reward_bonus", 0))
	var scan_hint_bonus := int(profile.get("scan_hint_bonus", 0))
	for effect in equipment_effects:
		match str(effect.get("effect_kind", "")):
			"backpack_capacity":
				backpack_capacity += int(effect.get("effect_amount", 0))
			"salvage_capacity":
				failure_salvage_capacity += int(effect.get("effect_amount", 0))
			"mine_damage_reduce":
				mine_dmg_reduce += int(effect.get("effect_amount", 0))
			"protocol_pressure_reduce":
				protocol_pressure_reduce += int(effect.get("effect_amount", 0))
			"search_reward":
				search_reward_bonus += int(effect.get("effect_amount", 0))
			"scan_hint":
				scan_hint_bonus += int(effect.get("effect_amount", 0))
	var carried_weight := 0
	for item in selected_consumables:
		carried_weight += maxi(0, int(item.get("weight", 0)))
	if carried_weight > backpack_capacity:
		issues.append("carry_weight_exceeds_authoritative_capacity")

	var commission_offer_seed := M7ContentCatalogScript.commission_offer_seed(
		map_id,
		int(meta_summary.get("run_count", 0))
	)
	var commission_candidates := M7ContentCatalogScript.commission_offer_candidates(
		map_id,
		int(meta_summary.get("run_count", 0)),
		3
	)
	var commission_candidate_ids: Dictionary = {}
	for raw_candidate in commission_candidates:
		commission_candidate_ids[str(raw_candidate.get("id", ""))] = true
	var selected_objective_id := str(normalized.get("selected_objective_id", ""))
	if bool(map_definition.get("tutorial_map", false)):
		selected_objective_id = ""
	elif not _commission_is_legal(selected_objective_id, map_id):
		issues.append("objective_not_legal_for_map")
	elif not commission_candidate_ids.has(selected_objective_id):
		issues.append("objective_not_in_commission_offer")

	if not issues.is_empty():
		return {
			"ok": false,
			"issues": issues,
			"config": normalized,
		}

	normalized["map_display_name"] = str(map_definition.get("display_name", map_id))
	normalized["difficulty"] = StringName(map_definition.get("difficulty", &""))
	normalized["difficulty_label"] = str(map_definition.get("difficulty_label", ""))
	normalized["selected_difficulty"] = normalized["difficulty"]
	normalized["selected_equipment_items"] = selected_equipment.duplicate(true)
	normalized["selected_consumable_items"] = selected_consumables.duplicate(true)
	normalized["selected_equipment_ids"] = selected_equipment_ids.duplicate()
	normalized["selected_consumable_ids"] = selected_consumable_ids.duplicate()
	normalized["selected_loadout"] = selected_equipment_ids.duplicate()
	normalized["carried_consumables"] = selected_consumable_ids.duplicate()
	normalized["equipment_effects"] = equipment_effects.duplicate(true)
	normalized["warehouse_lite"] = M3RItemUsabilityModelScript.build_warehouse_lite(meta_summary)
	normalized["codex_lite"] = M3RItemUsabilityModelScript.build_codex_lite(meta_summary)
	normalized["bag_used"] = carried_weight
	normalized["bag_limit"] = backpack_capacity
	normalized["backpack_capacity"] = backpack_capacity
	normalized["failure_salvage_capacity"] = failure_salvage_capacity
	normalized["profile_fields"] = profile.duplicate(true)
	normalized["talent_interface"] = _array_from(profile.get("talent_directions", []))
	normalized["active_talent_effects"] = _array_from(profile.get("active_talent_effects", []))
	normalized["profile_id"] = str(meta_summary.get("profile_id", normalized.get("profile_id", "default")))
	normalized["profile_level"] = int(profile.get("profile_level", 1))
	normalized["profile_exp"] = int(profile.get("profile_exp", 0))
	normalized["permit_level"] = int(profile.get("permit_level", 1))
	normalized["protocol_difficulty"] = int(profile.get("protocol_difficulty", 5))
	normalized["mine_dmg_reduce"] = mine_dmg_reduce
	normalized["protocol_pressure_reduce"] = protocol_pressure_reduce
	normalized["search_reward_bonus"] = search_reward_bonus
	normalized["scan_hint_bonus"] = scan_hint_bonus
	# The route preview may display an appearance, but only the persisted
	# selected entry inside the owned set is admitted into the run snapshot.
	normalized["player_appearance"] = PlayerAppearanceConfigScript.normalize(
		meta_summary.get("player_appearance", {})
	)
	normalized["selected_objective_id"] = StringName(selected_objective_id)
	if selected_objective_id == "":
		normalized["selected_objective_label"] = "教学目标"
		normalized["commission_candidates"] = []
	else:
		var objective := M7ContentCatalogScript.commission_definition(selected_objective_id)
		normalized["selected_objective_label"] = str(objective.get("display_name", selected_objective_id))
		normalized["commission_candidate_seed"] = commission_offer_seed
		normalized["commission_candidates"] = commission_candidates.duplicate(true)
	normalized["authority"] = &"meta_progress"
	return {
		"ok": true,
		"issues": [],
		"config": normalized,
	}


static func _route_mode_from_preview(preview: Dictionary) -> StringName:
	var start_mode := StringName(preview.get("start_mode", &"standard_preview"))
	match start_mode:
		&"demo", &"demo_run", &"demo_preview":
			return &"demo_run"
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


static func _selected_instance_ids(raw_ids: Variant, raw_items: Variant) -> Array[String]:
	var result: Array[String] = []
	var seen: Dictionary = {}
	if raw_ids is Array:
		for raw_id in raw_ids as Array:
			var instance_id := str(raw_id).strip_edges()
			if instance_id != "" and not seen.has(instance_id):
				seen[instance_id] = true
				result.append(instance_id)
	if result.is_empty() and raw_items is Array:
		for raw_item in raw_items as Array:
			var item := _dictionary_from(raw_item)
			var instance_id := str(item.get("instance_id", "")).strip_edges()
			if instance_id != "" and not seen.has(instance_id):
				seen[instance_id] = true
				result.append(instance_id)
	return result


static func _commission_is_legal(commission_id: String, map_id: String) -> bool:
	if commission_id == "":
		return false
	for definition in M7ContentCatalogScript.commission_definitions():
		if str(definition.get("id", "")) != commission_id:
			continue
		var map_ids := _array_from(definition.get("map_ids", []))
		return map_ids.is_empty() or map_ids.has(map_id)
	return false
