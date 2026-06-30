extends RefCounted
class_name DeployConfig

const AssetDomainContractScript := preload("res://scripts/core/asset/asset_domain_contract.gd")
const AssetProjectionSchemaScript := preload("res://scripts/core/asset/asset_projection_schema.gd")
const WarehouseViewSchemaScript := preload("res://scripts/core/asset/warehouse_view_schema.gd")
const WarehouseViewContentSchemaScript := preload("res://scripts/core/asset/warehouse_view_content_schema.gd")
const M3RItemUsabilityModelScript := preload("res://scripts/core/content/m3r_item_usability_model.gd")

const CONFIG_VERSION := 4
const START_MODE_STANDARD_PREVIEW := &"standard_preview"
const MAP_MODE_CLASSIC_PREVIEW := &"classic_minesweeper_preview"
const DIFFICULTY_NORMAL := &"normal"
const REGION_GRAYTAIL_EDGE := &"graytail_edge_preview"
const SEED_POLICY_DEFER := &"defer_until_run_start"
const RUN_ORIGIN_PREVIEW := &"deploy_prep_m3r"


static func default_config(sequence: int = 1, meta_summary: Dictionary = {}) -> Dictionary:
	var m3r_fields: Dictionary = M3RItemUsabilityModelScript.build_run_start_fields(meta_summary)
	var config := {
		"config_id": "deploy_m3r_%04d" % maxi(sequence, 1),
		"config_version": CONFIG_VERSION,
		"start_mode": START_MODE_STANDARD_PREVIEW,
		"map_mode": MAP_MODE_CLASSIC_PREVIEW,
		"map_mode_label": "Classic Minesweeper",
		"difficulty": DIFFICULTY_NORMAL,
		"difficulty_label": "Normal",
		"region_id": REGION_GRAYTAIL_EDGE,
		"region_label": "Graytail Edge",
		"seed_policy": SEED_POLICY_DEFER,
		"selected_loadout": _array_copy(m3r_fields.get("selected_equipment_ids", [])),
		"carried_consumables": _array_copy(m3r_fields.get("selected_consumable_ids", [])),
		"enabled_claims": [],
		"selected_objective_id": &"objective_recover_cache",
		"selected_objective_label": "Recover Cache",
		"enabled_services": [],
		"enabled_work_permits": [],
		"enabled_intel_flags": [],
		"bag_used": int(m3r_fields.get("bag_used", 0)),
		"bag_limit": int(m3r_fields.get("bag_limit", 10)),
		"source_page": &"deploy_prep",
		"created_at_or_sequence": maxi(sequence, 1),
		"run_origin": RUN_ORIGIN_PREVIEW,
		"deploy_summary": "M3R minimal real deploy config reads warehouse_items, selects carry-in equipment/consumables, and starts the existing standard_10x10 route.",
		"selected_map_summary": "Classic Minesweeper / Normal / Graytail Edge; true map layout is still generated after run start.",
		"selected_difficulty": DIFFICULTY_NORMAL,
		"selected_permits": [],
		"selected_services": [],
		"selected_objective_summary": "Recover Cache objective placeholder; M3R does not implement a complete objective/reward system.",
		"profile_snapshot_ref": &"m3r_profile_minimal",
		"unlock_snapshot_ref": &"m3r_unlock_minimal",
		"asset_attendance_preview": _asset_attendance_preview(),
		"warehouse_attendance_preview": m3r_fields.get("warehouse_lite", _warehouse_attendance_preview()),
		"claim_preview": _claim_preview(),
		"objective_preview": _objective_preview(),
		"loadout_preview": _loadout_from_m3r(m3r_fields),
		"permit_preview": m3r_fields.get("profile_fields", _permission_interface_preview()),
		"permission_interface_preview": m3r_fields.get("profile_fields", _permission_interface_preview()),
		"backpack_capacity_preview": _capacity_from_m3r(m3r_fields),
		"config_validity_preview": _config_validity_preview(),
		"action_intent_boundaries": _action_intent_boundaries_preview(),
		"active_run_preview": active_run_preview(false),
		"deploy_prep_projection": deploy_prep_projection_preview(),
		"deploy_asset_view_preview": WarehouseViewSchemaScript.default_deploy_asset_view(),
		"warehouse_view_snapshot": WarehouseViewSchemaScript.default_warehouse_view_snapshot(),
		"warehouse_view_content_snapshot": WarehouseViewContentSchemaScript.build_deploy_prep_content_view(),
		"long_term_asset_interface_preview": _long_term_asset_interface_preview(),
		"art09_asset_refs": _deploy_prep_asset_refs(),
		"preview": false,
		"display_only": false,
		"read_only": true,
	}
	for key in m3r_fields.keys():
		config[key] = m3r_fields[key]
	config["initial_bag_summary"] = {
		"used": int(config.get("bag_used", 0)),
		"limit": int(config.get("bag_limit", 10)),
		"label": "Carry weight %d / %d" % [int(config.get("bag_used", 0)), int(config.get("bag_limit", 10))],
	}
	config["right_summary_preview"] = right_summary_preview(config)
	config["risk_summary"] = {"level": &"m3r", "label": "M3R risk summary", "lines": _array_copy(config["right_summary_preview"].get("risk", []))}
	config["effect_summary"] = {"label": "M3R effect summary", "lines": _array_copy(config["right_summary_preview"].get("effect", []))}
	config["initial_risk_summary"] = _dictionary_copy(config["risk_summary"])
	config["initial_effect_summary"] = _dictionary_copy(config["effect_summary"])
	config["history_metadata"] = history_metadata_for(config)
	return config


static func with_active_run_preview(config: Dictionary, has_active_run: bool) -> Dictionary:
	var result := config.duplicate(true)
	result["active_run_preview"] = active_run_preview(has_active_run)
	result["right_summary_preview"] = right_summary_preview(result)
	result["risk_summary"] = {"level": &"m3r", "label": "M3R risk summary", "lines": _array_copy(result["right_summary_preview"].get("risk", []))}
	result["effect_summary"] = {"label": "M3R effect summary", "lines": _array_copy(result["right_summary_preview"].get("effect", []))}
	return result


static func build_run_start_config(config: Dictionary) -> Dictionary:
	var source := config.duplicate(true)
	return {
		"config_id": str(source.get("config_id", "")),
		"config_version": int(source.get("config_version", CONFIG_VERSION)),
		"start_mode": StringName(source.get("start_mode", START_MODE_STANDARD_PREVIEW)),
		"map_mode": StringName(source.get("map_mode", MAP_MODE_CLASSIC_PREVIEW)),
		"map_mode_label": str(source.get("map_mode_label", "Classic Minesweeper")),
		"difficulty": StringName(source.get("difficulty", DIFFICULTY_NORMAL)),
		"difficulty_label": str(source.get("difficulty_label", "Normal")),
		"region_id": StringName(source.get("region_id", REGION_GRAYTAIL_EDGE)),
		"region_label": str(source.get("region_label", "Graytail Edge")),
		"seed_policy": StringName(source.get("seed_policy", SEED_POLICY_DEFER)),
		"selected_loadout": _array_copy(source.get("selected_loadout", [])),
		"carried_consumables": _array_copy(source.get("carried_consumables", [])),
		"selected_equipment_items": _array_copy(source.get("selected_equipment_items", [])),
		"selected_consumable_items": _array_copy(source.get("selected_consumable_items", [])),
		"selected_equipment_ids": _array_copy(source.get("selected_equipment_ids", source.get("selected_loadout", []))),
		"selected_consumable_ids": _array_copy(source.get("selected_consumable_ids", source.get("carried_consumables", []))),
		"equipment_effects": _array_copy(source.get("equipment_effects", [])),
		"warehouse_lite": _dictionary_copy(source.get("warehouse_lite", {})),
		"codex_lite": _dictionary_copy(source.get("codex_lite", {})),
		"enabled_claims": _array_copy(source.get("enabled_claims", [])),
		"selected_objective_id": StringName(source.get("selected_objective_id", &"objective_recover_cache")),
		"selected_objective_label": str(source.get("selected_objective_label", "Recover Cache")),
		"enabled_services": _array_copy(source.get("enabled_services", [])),
		"enabled_work_permits": _array_copy(source.get("enabled_work_permits", [])),
		"enabled_intel_flags": _array_copy(source.get("enabled_intel_flags", [])),
		"bag_used": int(source.get("bag_used", 0)),
		"bag_limit": int(source.get("bag_limit", 10)),
		"backpack_capacity": int(source.get("backpack_capacity", source.get("bag_limit", 10))),
		"failure_salvage_capacity": int(source.get("failure_salvage_capacity", 1)),
		"profile_fields": _dictionary_copy(source.get("profile_fields", {})),
		"talent_interface": _array_copy(source.get("talent_interface", [])),
		"active_talent_effects": _array_copy(source.get("active_talent_effects", [])),
		"profile_level": int(source.get("profile_level", 1)),
		"profile_exp": int(source.get("profile_exp", 0)),
		"permit_level": int(source.get("permit_level", 1)),
		"protocol_difficulty": int(source.get("protocol_difficulty", 5)),
		"mine_dmg_reduce": int(source.get("mine_dmg_reduce", 0)),
		"risk_summary": _dictionary_copy(source.get("risk_summary", {})),
		"effect_summary": _dictionary_copy(source.get("effect_summary", {})),
		"source_page": StringName(source.get("source_page", &"deploy_prep")),
		"created_at_or_sequence": source.get("created_at_or_sequence", 1),
		"run_origin": StringName(source.get("run_origin", RUN_ORIGIN_PREVIEW)),
		"deploy_summary": str(source.get("deploy_summary", "")),
		"selected_map_summary": str(source.get("selected_map_summary", "")),
		"selected_difficulty": StringName(source.get("selected_difficulty", source.get("difficulty", DIFFICULTY_NORMAL))),
		"selected_permits": _array_copy(source.get("selected_permits", [])),
		"selected_services": _array_copy(source.get("selected_services", [])),
		"selected_objective_summary": str(source.get("selected_objective_summary", "")),
		"initial_bag_summary": _dictionary_copy(source.get("initial_bag_summary", {})),
		"initial_risk_summary": _dictionary_copy(source.get("initial_risk_summary", source.get("risk_summary", {}))),
		"initial_effect_summary": _dictionary_copy(source.get("initial_effect_summary", source.get("effect_summary", {}))),
		"asset_attendance_preview": _dictionary_copy(source.get("asset_attendance_preview", {})),
		"warehouse_attendance_preview": _dictionary_copy(source.get("warehouse_attendance_preview", {})),
		"claim_preview": _dictionary_copy(source.get("claim_preview", {})),
		"objective_preview": _dictionary_copy(source.get("objective_preview", _objective_preview())),
		"loadout_preview": _dictionary_copy(source.get("loadout_preview", {})),
		"permit_preview": _dictionary_copy(source.get("permit_preview", _permission_interface_preview())),
		"permission_interface_preview": _dictionary_copy(source.get("permission_interface_preview", _permission_interface_preview())),
		"backpack_capacity_preview": _dictionary_copy(source.get("backpack_capacity_preview", _backpack_capacity_preview())),
		"config_validity_preview": _dictionary_copy(source.get("config_validity_preview", _config_validity_preview())),
		"action_intent_boundaries": _dictionary_copy(source.get("action_intent_boundaries", _action_intent_boundaries_preview())),
		"active_run_preview": _dictionary_copy(source.get("active_run_preview", active_run_preview(false))),
		"deploy_prep_projection": _dictionary_copy(source.get("deploy_prep_projection", deploy_prep_projection_preview())),
		"deploy_asset_view_preview": _dictionary_copy(source.get("deploy_asset_view_preview", WarehouseViewSchemaScript.default_deploy_asset_view())),
		"warehouse_view_snapshot": _dictionary_copy(source.get("warehouse_view_snapshot", WarehouseViewSchemaScript.default_warehouse_view_snapshot())),
		"warehouse_view_content_snapshot": _dictionary_copy(source.get("warehouse_view_content_snapshot", WarehouseViewContentSchemaScript.build_deploy_prep_content_view())),
		"long_term_asset_interface_preview": _dictionary_copy(source.get("long_term_asset_interface_preview", _long_term_asset_interface_preview())),
		"art09_asset_refs": _dictionary_copy(source.get("art09_asset_refs", _deploy_prep_asset_refs())),
		"right_summary_preview": _dictionary_copy(source.get("right_summary_preview", right_summary_preview(source))),
		"history_metadata": history_metadata_for(source),
		"profile_snapshot_ref": source.get("profile_snapshot_ref", &"m3r_profile_minimal"),
		"unlock_snapshot_ref": source.get("unlock_snapshot_ref", &"m3r_unlock_minimal"),
		"preview": false,
		"display_only": false,
		"read_only": false,
	}


static func build_preview_lines(config: Dictionary) -> Dictionary:
	var right_summary := _dictionary_copy(config.get("right_summary_preview", right_summary_preview(config)))
	return {
		"summary": _array_copy(right_summary.get("summary", [])),
		"config": _array_copy(right_summary.get("config", [])),
		"effect": _array_copy(right_summary.get("effect", [])),
		"risk": _array_copy(right_summary.get("risk", [])),
	}


static func right_summary_preview(config: Dictionary) -> Dictionary:
	var loadout := _dictionary_copy(config.get("loadout_preview", _loadout_preview()))
	var warehouse := _dictionary_copy(config.get("warehouse_attendance_preview", _warehouse_attendance_preview()))
	var objective := _dictionary_copy(config.get("objective_preview", _objective_preview()))
	var validity := _dictionary_copy(config.get("config_validity_preview", _config_validity_preview()))
	var capacity := _dictionary_copy(config.get("backpack_capacity_preview", _backpack_capacity_preview()))
	var active_run := _dictionary_copy(config.get("active_run_preview", active_run_preview(false)))
	return {
		"summary": [
			str(config.get("deploy_summary", "")),
			"路线：%s / %s" % [str(config.get("map_mode_label", "")), str(config.get("difficulty_label", ""))],
			"目标：%s" % str(objective.get("selected_label", config.get("selected_objective_label", ""))),
			"背包：%s" % str(capacity.get("label", "")),
			"状态：%s" % str(validity.get("label", "")),
			"当局：%s" % str(active_run.get("label", "")),
		],
		"config": [
			"装备：%s" % _join_array(loadout.get("equipped", []), "无"),
			"消耗品：%s" % _join_array(loadout.get("carried_consumables", []), "无"),
			"背包：%d/%d" % [int(config.get("bag_used", 0)), int(config.get("bag_limit", 10))],
			"仓库：%d 件" % int(warehouse.get("item_count", 0)),
		],
		"effect": [
			"装备将在本次探索生效",
			"消耗品带入背包",
			"未使用补给按结果结算",
			"天赋影响背包与回收",
		],
		"risk": [
			"路线细节进入当局后确认",
			"仓库经济暂未完整开放",
			"目标奖励仍为基础池",
			"继续 / 终止逻辑后续接入",
		],
	}


static func active_run_preview(has_active_run: bool) -> Dictionary:
	if has_active_run:
		return {
			"has_active_run": true,
			"label": "active run present",
			"start_disabled": true,
			"continue_disabled": false,
			"abandon_disabled": false,
			"config_lock_note": "Start is disabled while an active run exists.",
			"abandon_requires_confirm": true,
			"abandon_confirm_text": "Abandon remains display-only in M3R.",
			"preview": true,
			"display_only": true,
			"read_only": true,
		}
	return {
		"has_active_run": false,
		"label": "no active run",
		"start_disabled": false,
		"continue_disabled": true,
		"abandon_disabled": true,
		"config_lock_note": "M3R can start a new standard_10x10 route from the current minimal loadout.",
		"abandon_requires_confirm": false,
		"abandon_confirm_text": "No active run to abandon.",
		"preview": false,
		"display_only": false,
		"read_only": true,
	}


static func deploy_prep_projection_preview() -> Dictionary:
	var projection := AssetProjectionSchemaScript.default_deploy_prep_projection()
	projection["source_system"] = &"deploy_prep"
	projection["summary"] = {
		"label": "M3R DeployPrep minimal real loadout bridge",
		"read_only_note": "DeployPrep reads warehouse_items and builds RunStartConfig; it does not write warehouse economy state.",
		"seed_policy": SEED_POLICY_DEFER,
	}
	projection["link_targets"] = [
		{"target": &"warehouse_lite", "label": "Warehouse Lite"},
		{"target": &"codex_lite", "label": "Codex Lite"},
		{"target": &"run_start_config", "label": "RunStartConfig"},
	]
	projection["extra"] = {
		"draft_actions": ["select_equipment", "select_consumable", "start_standard_10x10"],
		"non_goals": ["sell", "purchase", "reward_grant", "complete_warehouse_economy"],
	}
	return projection


static func history_metadata_for(config: Dictionary) -> Dictionary:
	return {
		"schema": &"DeployConfigHistoryMetadata",
		"config_id": str(config.get("config_id", "")),
		"config_version": int(config.get("config_version", CONFIG_VERSION)),
		"selected_map_summary": str(config.get("selected_map_summary", "")),
		"selected_objective_label": str(config.get("selected_objective_label", "Recover Cache")),
		"selected_equipment_ids": _array_copy(config.get("selected_equipment_ids", config.get("selected_loadout", []))),
		"selected_consumable_ids": _array_copy(config.get("selected_consumable_ids", config.get("carried_consumables", []))),
		"bag_used": int(config.get("bag_used", 0)),
		"bag_limit": int(config.get("bag_limit", 10)),
		"read_only": true,
		"display_only": false,
		"preview": false,
	}


static func _asset_attendance_preview() -> Dictionary:
	return {
		"title": "M3R asset attendance",
		"main_item_types": ["equipment", "consumable", "collectible", "special"],
		"metadata_only": ["unique", "cosmetic", "task_item", "commission_item", "sample"],
		"consumable_note": "Unused carry-in consumables follow settlement result: success returns, failure salvage candidate.",
		"display_only": false,
		"read_only": true,
		"preview": false,
	}


static func _warehouse_attendance_preview() -> Dictionary:
	return {
		"label": "Warehouse Lite",
		"summary": "No warehouse_items found yet.",
		"item_count": 0,
		"display_only": false,
		"read_only": true,
		"preview": false,
	}


static func _claim_preview() -> Dictionary:
	return {
		"label": "Claim catalog placeholder",
		"groups": ["purchase", "receive", "recycle", "locked", "recommended"],
		"preview_actions": ["purchase", "claim", "recycle"],
		"display_only": true,
		"read_only": true,
		"preview": true,
	}


static func _objective_preview() -> Dictionary:
	return {
		"selected_id": &"objective_recover_cache",
		"selected_label": "Recover Cache",
		"objective_type": &"recover",
		"map_match": true,
		"difficulty_match": "normal",
		"reward_type_preview": ["resource", "collectible_ref"],
		"display_only": true,
		"read_only": true,
		"preview": true,
	}


static func _loadout_preview() -> Dictionary:
	return {
		"equipped": [],
		"carried_consumables": [],
		"carried_specials": [],
		"selected_objective": "Recover Cache",
		"purchased_not_carried": [],
		"configured_item_count": 0,
		"preset_note": "No warehouse loadout selected.",
		"consumable_note": "Unused carry-in consumables follow M3 settlement rules.",
		"display_only": false,
		"read_only": true,
		"preview": false,
	}


static func _loadout_from_m3r(m3r_fields: Dictionary) -> Dictionary:
	var equipment: Array = m3r_fields.get("selected_equipment_items", [])
	var consumables: Array = m3r_fields.get("selected_consumable_items", [])
	return {
		"equipped": _item_display_names(equipment),
		"carried_consumables": _item_display_names(consumables),
		"carried_specials": [],
		"selected_objective": "Recover Cache",
		"purchased_not_carried": [],
		"configured_item_count": equipment.size() + consumables.size(),
		"preset_note": "M3R derives this minimal loadout from real warehouse_items.",
		"consumable_note": "Unused carry-in consumables return on success and enter failure salvage candidates on failure.",
		"display_only": false,
		"read_only": true,
		"preview": false,
	}


static func _capacity_from_m3r(m3r_fields: Dictionary) -> Dictionary:
	var used := int(m3r_fields.get("bag_used", 0))
	var limit := int(m3r_fields.get("bag_limit", m3r_fields.get("backpack_capacity", 10)))
	return {
		"used": used,
		"limit": limit,
		"label": "Carry weight %d / %d" % [used, limit],
		"failure_salvage_capacity": int(m3r_fields.get("failure_salvage_capacity", 1)),
		"capacity_scope": "Carry-in consumables use capacity; equipment enters equipped/runtime passive context.",
		"display_only": false,
		"read_only": true,
		"preview": false,
	}


static func _permission_interface_preview() -> Dictionary:
	return {
		"title": "Profile / permit / protocol minimal interface",
		"profile_level": 1,
		"permit_level": 1,
		"protocol_difficulty": 5,
		"state_label": "minimal fields only",
		"display_only": false,
		"read_only": true,
		"preview": false,
	}


static func _backpack_capacity_preview() -> Dictionary:
	return {
		"used": 0,
		"limit": 10,
		"label": "Carry weight 0 / 10",
		"display_only": false,
		"read_only": true,
		"preview": false,
	}


static func _config_validity_preview() -> Dictionary:
	return {
		"label": "M3R minimal start ready / uses existing standard_10x10 route",
		"checks": [
			"map selected",
			"difficulty selected",
			"warehouse_items read through Warehouse Lite",
			"selected equipment and consumables normalized",
			"carry weight within minimal capacity",
			"RunStartConfig can be handed to the existing route adapter",
		],
		"can_start": true,
		"blocked_real_actions": ["full_run_bootstrapper", "active_run_persistence", "complete_deploy_economy"],
		"display_only": false,
		"read_only": true,
		"preview": false,
	}


static func _action_intent_boundaries_preview() -> Dictionary:
	return {
		"start_intent": "Builds a real minimal RunStartConfig and routes it into the existing standard_10x10 start path.",
		"continue_intent": "Continue remains a read-only active_run status display; active run persistence is not implemented in M3R.",
		"abandon_intent": "Abandon remains confirm/display-only; M3R does not implement abandon settlement.",
		"requires_confirm": ["abandon"],
		"blocked_actions": ["real_continue", "real_abandon", "full_run_bootstrapper", "active_run_persistence"],
		"display_only": false,
		"read_only": true,
		"preview": false,
	}


static func _long_term_asset_interface_preview() -> Dictionary:
	return {
		"title": "M3R LongTerm asset interface bridge",
		"reward_bundle_preview": AssetDomainContractScript.default_reward_bundle_preview("deploy_prep.objective.reward_bundle.preview", &"deploy_prep"),
		"red_dot_policy": AssetDomainContractScript.default_red_dot_policy(&"deploy_prep.objective.red_dot_policy"),
		"jump_targets": [
			AssetDomainContractScript.default_jump_target(&"warehouse_lite", "Warehouse Lite"),
			AssetDomainContractScript.default_jump_target(&"codex_lite", "Codex Lite"),
		],
		"boundary": "DeployPrep exposes minimal warehouse/codex/loadout data; it does not write objectives, rewards, or assets.",
		"read_only": true,
		"display_only": false,
		"preview": false,
	}


static func _deploy_prep_asset_refs() -> Dictionary:
	return {
		"screen": "ui.deploy_prep.m3r",
		"warehouse": "ui.deploy_prep.warehouse_lite",
		"codex": "ui.deploy_prep.codex_lite",
		"loadout": "ui.deploy_prep.loadout",
		"start": "ui.deploy_prep.start_standard_10x10",
	}


static func _array_copy(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


static func _dictionary_copy(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


static func _join_array(value: Variant, fallback: String) -> String:
	var items := _array_copy(value)
	if items.is_empty():
		return fallback
	var parts: Array[String] = []
	for item in items:
		parts.append(str(item))
	return ", ".join(parts)


static func _item_display_names(items: Array) -> Array[String]:
	var names: Array[String] = []
	for raw_item in items:
		if raw_item is Dictionary:
			var item := raw_item as Dictionary
			names.append(str(item.get("display_name", item.get("item_id", "item"))))
		else:
			names.append(str(raw_item))
	return names
