extends RefCounted
class_name M3RItemUsabilityModel

const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")

const GROUP_EQUIPMENT := &"equipment"
const GROUP_CONSUMABLE := &"consumable"
const GROUP_COLLECTIBLE := &"collectible"
const GROUP_SPECIAL := &"special"

const BASE_BACKPACK_CAPACITY := 10
const BASE_FAILURE_SALVAGE_CAPACITY := 4


static func normalize_warehouse_items(meta_summary: Dictionary = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen: Dictionary = {}
	for raw_item in _array_from(meta_summary.get("warehouse_items", [])):
		var item := normalize_item(raw_item)
		if item.is_empty():
			continue
		var instance_id := str(item.get("instance_id", item.get("item_id", "")))
		if instance_id == "" or seen.has(instance_id):
			instance_id = "%s_%03d" % [str(item.get("item_id", "item")), result.size() + 1]
			item["instance_id"] = instance_id
		seen[instance_id] = true
		result.append(item)
	return result


static func normalize_item(raw_item: Variant) -> Dictionary:
	var source := _dictionary_from(raw_item)
	if source.is_empty():
		return {}
	var item_id := str(source.get("item_id", source.get("id", "")))
	var definition := item_definition(item_id)
	var result := definition.duplicate(true)
	for key in source.keys():
		result[key] = source[key]
	if item_id == "":
		item_id = str(result.get("item_id", "warehouse_item"))
	result["item_id"] = item_id
	result["instance_id"] = str(result.get("instance_id", item_id))
	result["display_name"] = str(result.get("display_name", item_id))
	result["short_description"] = str(result.get("short_description", "Warehouse item."))
	var item_type := _normalize_item_type(result.get("item_type", result.get("main_type", GROUP_COLLECTIBLE)))
	result["item_type"] = item_type
	result["main_type"] = item_type
	result["weight"] = maxi(0, int(result.get("weight", 0)))
	result["base_value"] = maxi(0, int(result.get("base_value", result.get("value", 0))))
	result["collectible_level"] = int(result.get("collectible_level", 0))
	result["source"] = str(result.get("source", "warehouse"))
	result["source_label"] = str(result.get("source_label", result.get("source", "warehouse")))
	result["tags"] = _array_from(result.get("tags", []))
	result["can_equip"] = bool(result.get("can_equip", item_type == GROUP_EQUIPMENT))
	result["can_consume"] = bool(result.get("can_consume", item_type == GROUP_CONSUMABLE))
	result["can_sell"] = bool(result.get("can_sell", item_type == GROUP_COLLECTIBLE))
	result["can_carry"] = bool(result.get("can_equip", false)) or bool(result.get("can_consume", false))
	result["can_store"] = bool(result.get("can_store", true))
	result["location_state"] = StringName(result.get("location_state", &"warehouse"))
	result["effect_kind"] = str(result.get("effect_kind", _default_effect_kind(item_id, item_type)))
	result["effect_amount"] = int(result.get("effect_amount", _default_effect_amount(item_id, item_type)))
	result["equipment_slot"] = str(result.get("equipment_slot", _default_equipment_slot(item_id)))
	result["warehouse_lite"] = true
	return result


static func item_definition(item_id: String) -> Dictionary:
	for item in M3ItemCatalogScript.all_items():
		if str(item.get("item_id", "")) == item_id:
			var result: Dictionary = item.duplicate(true)
			_apply_default_item_effects(result)
			return result
	return {}


static func build_warehouse_lite(meta_summary: Dictionary = {}) -> Dictionary:
	var items := normalize_warehouse_items(meta_summary)
	var groups := {
		GROUP_EQUIPMENT: [],
		GROUP_CONSUMABLE: [],
		GROUP_COLLECTIBLE: [],
		GROUP_SPECIAL: [],
	}
	for item in items:
		var item_type := _normalize_item_type(item.get("item_type", GROUP_COLLECTIBLE))
		if not groups.has(item_type):
			item_type = GROUP_SPECIAL
		(groups[item_type] as Array).append(item)
	var loadout := build_default_loadout(meta_summary)
	return {
		"title": "Warehouse Lite",
		"summary": "Reads real MetaProgress warehouse_items and derives carry-in candidates.",
		"item_count": items.size(),
		"groups": groups,
		"group_counts": {
			"equipment": (groups[GROUP_EQUIPMENT] as Array).size(),
			"consumable": (groups[GROUP_CONSUMABLE] as Array).size(),
			"collectible": (groups[GROUP_COLLECTIBLE] as Array).size(),
			"special": (groups[GROUP_SPECIAL] as Array).size(),
		},
		"selected_equipment": loadout.get("selected_equipment", []),
		"selected_consumables": loadout.get("selected_consumables", []),
		"capacity": loadout.get("capacity", {}),
		"read_only": true,
		"display_only": false,
		"preview": false,
	}


static func build_codex_lite(meta_summary: Dictionary = {}) -> Dictionary:
	var warehouse_items := normalize_warehouse_items(meta_summary)
	var discovered: Array[Dictionary] = []
	var discovered_ids: Dictionary = {}
	for item in warehouse_items:
		var item_type := _normalize_item_type(item.get("item_type", GROUP_COLLECTIBLE))
		var tags := _array_from(item.get("tags", []))
		var is_codex_item := item_type == GROUP_COLLECTIBLE or item_type == GROUP_SPECIAL or tags.has("monster") or tags.has("sample") or tags.has("trophy")
		if not is_codex_item:
			continue
		var codex_id := str(item.get("item_id", item.get("instance_id", "")))
		discovered_ids[codex_id] = true
		discovered.append({
			"codex_id": codex_id,
			"item_id": codex_id,
			"display_name": str(item.get("display_name", codex_id)),
			"discovered": true,
			"source": str(item.get("source", "warehouse")),
			"source_label": str(item.get("source_label", item.get("source", "warehouse"))),
			"level": int(item.get("collectible_level", 0)),
			"summary": str(item.get("short_description", "")),
			"tags": tags,
		})
	var undiscovered: Array[Dictionary] = []
	for catalog_item in M3ItemCatalogScript.collectible_items().slice(0, 6):
		var catalog_id := str(catalog_item.get("item_id", ""))
		if discovered_ids.has(catalog_id):
			continue
		undiscovered.append({
			"codex_id": catalog_id,
			"item_id": catalog_id,
			"display_name": "Unknown collectible",
			"discovered": false,
			"source": str(catalog_item.get("source", "unknown")),
			"level": int(catalog_item.get("collectible_level", 0)),
			"summary": "Undiscovered entry placeholder.",
		})
	for catalog_item in M3ItemCatalogScript.monster_drop_items().slice(0, 3):
		var catalog_id := str(catalog_item.get("item_id", ""))
		if discovered_ids.has(catalog_id):
			continue
		undiscovered.append({
			"codex_id": catalog_id,
			"item_id": catalog_id,
			"display_name": "Unknown monster sample",
			"discovered": false,
			"source": M3ItemCatalogScript.SOURCE_MONSTER,
			"level": int(catalog_item.get("collectible_level", 0)),
			"summary": "Monster material not yet recovered.",
		})
	for unique_item in M3ItemCatalogScript.unique_concept_items():
		var unique_id := str(unique_item.get("item_id", ""))
		undiscovered.append({
			"codex_id": unique_id,
			"item_id": unique_id,
			"display_name": str(unique_item.get("display_name", "Locked unique")),
			"discovered": false,
			"source": "gacha_only_future",
			"level": int(unique_item.get("collectible_level", 7)),
			"rarity": "unique",
			"summary": "Unique concept is locked to future gacha-only acquisition; ordinary search, chest, monster, event, and altar drops cannot create it.",
			"locked_reason": "unique_gacha_only_future",
		})
	return {
		"title": "Codex Lite",
		"summary": "Derives discoveries from real warehouse_items; no research, reward, or red-dot system.",
		"discovered_entries": discovered,
		"undiscovered_entries": undiscovered,
		"discovered_count": discovered.size(),
		"total_visible_count": discovered.size() + undiscovered.size(),
		"read_only": true,
		"display_only": false,
		"preview": false,
	}


static func build_default_loadout(meta_summary: Dictionary = {}) -> Dictionary:
	var profile := build_profile_interfaces(meta_summary)
	var capacity := int(profile.get("backpack_capacity", BASE_BACKPACK_CAPACITY))
	var selected_equipment: Array[Dictionary] = []
	var selected_consumables: Array[Dictionary] = []
	var used := 0
	var equipment_effects := build_equipment_effects(selected_equipment)
	return {
		"selected_equipment": selected_equipment,
		"selected_consumables": selected_consumables,
		"selected_equipment_ids": _item_ids(selected_equipment),
		"selected_consumable_ids": _item_ids(selected_consumables),
		"equipment_effects": equipment_effects,
		"capacity": {
			"used": used,
			"limit": capacity,
			"remaining": maxi(0, capacity - used),
			"failure_salvage_capacity": int(profile.get("failure_salvage_capacity", BASE_FAILURE_SALVAGE_CAPACITY)),
		},
		"profile_interfaces": profile,
	}


static func build_equipment_effects(items: Array) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for raw_item in items:
		var item := normalize_item(raw_item)
		var effect_kind := str(item.get("effect_kind", ""))
		var amount := int(item.get("effect_amount", 0))
		if effect_kind == "" or amount == 0:
			continue
		effects.append({
			"item_id": str(item.get("item_id", "")),
			"instance_id": str(item.get("instance_id", "")),
			"display_name": str(item.get("display_name", "")),
			"effect_kind": effect_kind,
			"effect_amount": amount,
			"source": "warehouse_loadout",
		})
	return effects


static func build_profile_interfaces(meta_summary: Dictionary = {}) -> Dictionary:
	var profile_level := maxi(1, int(meta_summary.get("profile_level", 1)))
	var permit_level := maxi(1, int(meta_summary.get("permit_level", 1)))
	var protocol_difficulty := maxi(1, int(meta_summary.get("protocol_difficulty", 5)))
	var talents := [
		_talent("talent_carry_rigging", "Carry Rigging", "backpack_capacity", 1),
		_talent("talent_salvage_clause", "Salvage Clause", "salvage_capacity", 1),
		_talent("talent_shock_training", "Shock Training", "mine_damage_reduce", 5),
		_talent("talent_pressure_reading", "Pressure Reading", "protocol_pressure_reduce", 2),
		_talent("talent_trader_notes", "Trader Notes", "trader_safe_yield_bonus", 1),
		_talent("talent_scan_discipline", "Scan Discipline", "scan_hint", 1),
	]
	var backpack_capacity := BASE_BACKPACK_CAPACITY
	var failure_salvage_capacity := BASE_FAILURE_SALVAGE_CAPACITY
	var mine_dmg_reduce := 0
	var pressure_reduce := 0
	var active_talents: Array[Dictionary] = []
	var talent_flags := _array_from(meta_summary.get("talent_flags", []))
	for talent in talents:
		if not talent_flags.has(str(talent.get("talent_id", ""))):
			continue
		active_talents.append(talent.duplicate(true))
		match str(talent.get("effect_kind", "")):
			"backpack_capacity":
				backpack_capacity += int(talent.get("effect_amount", 0))
			"salvage_capacity":
				failure_salvage_capacity += int(talent.get("effect_amount", 0))
			"mine_damage_reduce":
				mine_dmg_reduce += int(talent.get("effect_amount", 0))
			"protocol_pressure_reduce":
				pressure_reduce += int(talent.get("effect_amount", 0))
	return {
		"profile_id": str(meta_summary.get("profile_id", "default")),
		"profile_level": profile_level,
		"profile_exp": int(meta_summary.get("profile_exp", 0)),
		"permit_level": permit_level,
		"protocol_difficulty": protocol_difficulty,
		"talent_directions": talents,
		"active_talent_effects": active_talents,
		"backpack_capacity": backpack_capacity,
		"failure_salvage_capacity": failure_salvage_capacity,
		"mine_dmg_reduce": mine_dmg_reduce,
		"protocol_pressure_reduce": pressure_reduce,
		"read_only": true,
		"display_only": false,
		"preview": false,
	}


static func build_run_start_fields(meta_summary: Dictionary = {}) -> Dictionary:
	var warehouse := build_warehouse_lite(meta_summary)
	var codex := build_codex_lite(meta_summary)
	var loadout := build_default_loadout(meta_summary)
	var profile: Dictionary = loadout.get("profile_interfaces", build_profile_interfaces(meta_summary))
	var selected_equipment: Array = loadout.get("selected_equipment", [])
	var selected_consumables: Array = loadout.get("selected_consumables", [])
	var capacity: Dictionary = loadout.get("capacity", {})
	return {
		"warehouse_lite": warehouse,
		"codex_lite": codex,
		"selected_equipment_items": _duplicate_array(selected_equipment),
		"selected_consumable_items": _duplicate_array(selected_consumables),
		"selected_equipment_ids": _item_ids(selected_equipment),
		"selected_consumable_ids": _item_ids(selected_consumables),
		"equipment_effects": _duplicate_array(loadout.get("equipment_effects", [])),
		"backpack_capacity": int(capacity.get("limit", profile.get("backpack_capacity", BASE_BACKPACK_CAPACITY))),
		"failure_salvage_capacity": int(capacity.get("failure_salvage_capacity", profile.get("failure_salvage_capacity", BASE_FAILURE_SALVAGE_CAPACITY))),
		"bag_used": int(capacity.get("used", 0)),
		"bag_limit": int(capacity.get("limit", BASE_BACKPACK_CAPACITY)),
		"profile_fields": profile.duplicate(true),
		"talent_interface": _duplicate_array(profile.get("talent_directions", [])),
		"active_talent_effects": _duplicate_array(profile.get("active_talent_effects", [])),
		"profile_level": int(profile.get("profile_level", 1)),
		"profile_exp": int(profile.get("profile_exp", 0)),
		"permit_level": int(profile.get("permit_level", 1)),
		"protocol_difficulty": int(profile.get("protocol_difficulty", 5)),
		"mine_dmg_reduce": int(profile.get("mine_dmg_reduce", 0)),
		"protocol_pressure_reduce": int(profile.get("protocol_pressure_reduce", 0)),
		"search_reward_bonus": 0,
		"scan_hint_bonus": 0,
		"read_only": false,
		"display_only": false,
		"preview": false,
	}


static func runtime_config_patch(run_start_config: Dictionary = {}) -> Dictionary:
	var equipment: Array = _array_from(run_start_config.get("selected_equipment_items", []))
	var consumables: Array = _array_from(run_start_config.get("selected_consumable_items", []))
	return {
		"selected_equipment_items": _duplicate_array(equipment),
		"selected_consumable_items": _duplicate_array(consumables),
		"selected_equipment_ids": _item_ids(equipment),
		"selected_consumable_ids": _item_ids(consumables),
		"equipment_effects": _duplicate_array(run_start_config.get("equipment_effects", build_equipment_effects(equipment))),
		"backpack_capacity": int(run_start_config.get("backpack_capacity", BASE_BACKPACK_CAPACITY)),
		"failure_salvage_capacity": int(run_start_config.get("failure_salvage_capacity", BASE_FAILURE_SALVAGE_CAPACITY)),
		"profile_fields": _dictionary_from(run_start_config.get("profile_fields", {})),
		"profile_level": int(run_start_config.get("profile_level", 1)),
		"profile_exp": int(run_start_config.get("profile_exp", 0)),
		"permit_level": int(run_start_config.get("permit_level", 1)),
		"protocol_difficulty": int(run_start_config.get("protocol_difficulty", 5)),
		"mine_dmg_reduce": int(run_start_config.get("mine_dmg_reduce", 0)),
		"protocol_pressure_reduce": int(run_start_config.get("protocol_pressure_reduce", 0)),
		"search_reward_bonus": int(run_start_config.get("search_reward_bonus", 0)),
		"scan_hint_bonus": int(run_start_config.get("scan_hint_bonus", 0)),
		"run_start_config": run_start_config.duplicate(true),
		"loadout_source": "m3r_warehouse_lite",
	}


static func _apply_default_item_effects(item: Dictionary) -> void:
	var item_id := str(item.get("item_id", ""))
	var item_type := _normalize_item_type(item.get("item_type", GROUP_COLLECTIBLE))
	item["effect_kind"] = str(item.get("effect_kind", _default_effect_kind(item_id, item_type)))
	item["effect_amount"] = int(item.get("effect_amount", _default_effect_amount(item_id, item_type)))
	if item_type == GROUP_EQUIPMENT:
		item["equipment_slot"] = str(item.get("equipment_slot", _default_equipment_slot(item_id)))


static func _default_effect_kind(item_id: String, item_type: StringName) -> String:
	if item_type == GROUP_EQUIPMENT:
		match item_id:
			"eq_recovery_bag":
				return "backpack_capacity"
			"eq_signal_pin":
				return "salvage_capacity"
			"eq_old_vest":
				return "mine_damage_reduce"
			"eq_insulated_sleeve":
				return "protocol_pressure_reduce"
			"eq_goggles":
				return "scan_hint"
			"eq_edge_opener":
				return "safe_yield"
	return ""


static func _default_effect_amount(item_id: String, item_type: StringName) -> int:
	if item_type == GROUP_EQUIPMENT:
		match item_id:
			"eq_recovery_bag":
				return 2
			"eq_signal_pin":
				return 1
			"eq_old_vest":
				return 10
			"eq_insulated_sleeve":
				return 3
			"eq_goggles":
				return 1
			"eq_edge_opener":
				return 2
	return 0


static func _default_equipment_slot(item_id: String) -> String:
	match item_id:
		"eq_old_vest":
			return "armor"
		"eq_recovery_bag":
			return "rig"
		"eq_goggles", "eq_signal_pin":
			return "device"
	return "tool"


static func _talent(talent_id: String, display_name: String, effect_kind: String, effect_amount: int) -> Dictionary:
	return {
		"talent_id": talent_id,
		"display_name": display_name,
		"effect_kind": effect_kind,
		"effect_amount": effect_amount,
		"hook_state": "minimal_real",
		"read_only": true,
		"display_only": false,
		"preview": false,
	}


static func _normalize_item_type(value: Variant) -> StringName:
	var type_text := str(value)
	match type_text:
		"equipment", "gear", "loadout_equipment":
			return GROUP_EQUIPMENT
		"consumable", "carry_consumable", "run_consumable":
			return GROUP_CONSUMABLE
		"collectible", "relic", "trophy", "sample":
			return GROUP_COLLECTIBLE
		"special", "quest", "commission":
			return GROUP_SPECIAL
	return GROUP_COLLECTIBLE


static func _item_ids(items: Array) -> Array[String]:
	var ids: Array[String] = []
	for raw_item in items:
		var item := _dictionary_from(raw_item)
		var item_id := str(item.get("item_id", ""))
		if item_id != "":
			ids.append(item_id)
	return ids


static func _duplicate_array(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


static func _array_from(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
