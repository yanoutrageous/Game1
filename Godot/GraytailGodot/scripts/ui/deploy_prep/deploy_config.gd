extends RefCounted
class_name DeployConfig

const AssetDomainContractScript := preload("res://scripts/core/asset/asset_domain_contract.gd")
const AssetProjectionSchemaScript := preload("res://scripts/core/asset/asset_projection_schema.gd")
const WarehouseViewSchemaScript := preload("res://scripts/core/asset/warehouse_view_schema.gd")
const WarehouseViewContentSchemaScript := preload("res://scripts/core/asset/warehouse_view_content_schema.gd")
const M3RItemUsabilityModelScript := preload("res://scripts/core/content/m3r_item_usability_model.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")

const CONFIG_VERSION := 6
const START_MODE_STANDARD_PREVIEW := &"standard_preview"
const MAP_MODE_CLASSIC_PREVIEW := &"classic_minesweeper_preview"
const DIFFICULTY_NORMAL := &"normal"
const REGION_GRAYTAIL_EDGE := &"graytail_edge_preview"
const SEED_POLICY_DEFER := &"defer_until_run_start"
const RUN_ORIGIN_PREVIEW := &"deploy_prep_m3r"
const MAX_EQUIPPED_ITEMS := 2
const MAX_CARRIED_CONSUMABLES := 3
const EMERGENCY_CLAIM_ID := &"m6_emergency_ration"
const ACTIVE_RUN_CANONICAL_FIELDS := [
	"map_config_id",
	"map_display_name",
	"map_mode",
	"map_mode_label",
	"difficulty",
	"difficulty_label",
	"selected_difficulty",
	"selected_map_summary",
	"region_id",
	"region_label",
	"selected_objective_id",
	"selected_objective_label",
	"selected_objective_summary",
	"commission_candidates",
	"selected_equipment_items",
	"selected_consumable_items",
	"selected_equipment_ids",
	"selected_consumable_ids",
	"selected_loadout",
	"carried_consumables",
	"equipment_effects",
	"bag_used",
	"bag_limit",
	"backpack_capacity",
	"failure_salvage_capacity",
	"mine_dmg_reduce",
	"protocol_pressure_reduce",
	"search_reward_bonus",
	"scan_hint_bonus",
	"loadout_preview",
	"backpack_capacity_preview",
	"config_validity_preview",
	"initial_bag_summary",
]


static func default_config(sequence: int = 1, meta_summary: Dictionary = {}) -> Dictionary:
	var m3r_fields: Dictionary = M3RItemUsabilityModelScript.build_run_start_fields(meta_summary)
	var unlocked_maps: Array = _array_copy(meta_summary.get("unlocked_map_ids", M7ContentCatalogScript.DEFAULT_UNLOCKED_MAPS))
	var default_map_id := "classic_7x7_simple" if unlocked_maps.has("classic_7x7_simple") else str(unlocked_maps[0] if not unlocked_maps.is_empty() else "classic_10x10_standard")
	var map_definition := M7ContentCatalogScript.map_definition(default_map_id)
	var candidate_seed := maxi(1, sequence * 1009 + int(meta_summary.get("run_count", 0)) * 97 + int(meta_summary.get("gold", 0)) * 13)
	var commission_candidates := M7ContentCatalogScript.commission_candidates(default_map_id, candidate_seed)
	var selected_commission: Dictionary = commission_candidates[0] if not commission_candidates.is_empty() else M7ContentCatalogScript.commission_definition("commission_recover_supply")
	var config := {
		"config_id": "deploy_m3r_%04d" % maxi(sequence, 1),
		"config_version": CONFIG_VERSION,
		"start_mode": START_MODE_STANDARD_PREVIEW,
		"map_mode": MAP_MODE_CLASSIC_PREVIEW,
		"map_mode_label": "常规扫雷",
		"map_config_id": default_map_id,
		"map_display_name": str(map_definition.get("display_name", "7×7 简单")),
		"difficulty": StringName(map_definition.get("difficulty", DIFFICULTY_NORMAL)),
		"difficulty_label": str(map_definition.get("difficulty_label", "简单")),
		"region_id": REGION_GRAYTAIL_EDGE,
		"region_label": "Graytail Edge",
		"seed_policy": SEED_POLICY_DEFER,
		"selected_loadout": _array_copy(m3r_fields.get("selected_equipment_ids", [])),
		"carried_consumables": _array_copy(m3r_fields.get("selected_consumable_ids", [])),
		"enabled_claims": [],
		"selected_objective_id": StringName(selected_commission.get("id", "commission_recover_supply")),
		"selected_objective_label": str(selected_commission.get("display_name", "回收补给箱")),
		"commission_candidates": commission_candidates,
		"commission_candidate_seed": candidate_seed,
		"unlocked_map_ids": unlocked_maps,
		"meta_progress_summary": meta_summary.duplicate(true),
		"enabled_services": [],
		"enabled_work_permits": [],
		"enabled_intel_flags": [],
		"bag_used": int(m3r_fields.get("bag_used", 0)),
		"bag_limit": int(m3r_fields.get("bag_limit", 10)),
		"source_page": &"deploy_prep",
		"created_at_or_sequence": maxi(sequence, 1),
		"run_origin": RUN_ORIGIN_PREVIEW,
		"deploy_summary": "M7 出勤配置读取真实仓库实例、已解锁地图与本局委托。",
		"selected_map_summary": "%s；地图真相在确认出发后生成。" % str(map_definition.get("display_name", "7×7 简单")),
		"selected_difficulty": StringName(map_definition.get("difficulty", DIFFICULTY_NORMAL)),
		"selected_permits": [],
		"selected_services": [],
		"selected_objective_summary": "%s：%s" % [str(selected_commission.get("display_name", "回收补给箱")), str(selected_commission.get("description", ""))],
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
	result["active_run_locked"] = has_active_run
	result["right_summary_preview"] = right_summary_preview(result)
	result["risk_summary"] = {"level": &"m3r", "label": "M3R risk summary", "lines": _array_copy(result["right_summary_preview"].get("risk", []))}
	result["effect_summary"] = {"label": "M3R effect summary", "lines": _array_copy(result["right_summary_preview"].get("effect", []))}
	return result


static func with_active_run_config(config: Dictionary, run_start_config: Dictionary) -> Dictionary:
	var equipment := _array_copy(run_start_config.get("selected_equipment_items", []))
	var consumables := _array_copy(run_start_config.get("selected_consumable_items", []))
	var recalculated := _recalculate_loadout(config, equipment, consumables)
	var result: Dictionary = recalculated.get("config", config.duplicate(true))
	for field in ACTIVE_RUN_CANONICAL_FIELDS:
		if run_start_config.has(field):
			var canonical_value: Variant = run_start_config[field]
			if canonical_value is Dictionary:
				result[field] = (canonical_value as Dictionary).duplicate(true)
			elif canonical_value is Array:
				result[field] = (canonical_value as Array).duplicate(true)
			else:
				result[field] = canonical_value
	result["active_run_preview"] = active_run_preview(true)
	result["active_run_locked"] = true
	result["active_run_id"] = str(run_start_config.get("run_id", ""))
	result["right_summary_preview"] = right_summary_preview(result)
	return result


static func refresh_from_meta(config: Dictionary, meta_summary: Dictionary, has_active_run: bool = false) -> Dictionary:
	var sequence := maxi(1, int(config.get("created_at_or_sequence", 1)))
	var refreshed := default_config(sequence, meta_summary)
	refreshed["commission_candidate_seed"] = int(config.get("commission_candidate_seed", refreshed.get("commission_candidate_seed", 1)))
	var previous_map_id := str(config.get("map_config_id", "classic_7x7_simple"))
	if (refreshed.get("unlocked_map_ids", []) as Array).has(previous_map_id):
		refreshed = _dictionary_copy(_select_m7_map(refreshed, previous_map_id).get("config", refreshed))
	var previous_commission_id := str(config.get("selected_objective_id", ""))
	var commission_result := _select_m7_commission(refreshed, previous_commission_id)
	if bool(commission_result.get("changed", false)):
		refreshed = _dictionary_copy(commission_result.get("config", refreshed))
	var equipment: Array = []
	var consumables: Array = []
	for raw_item in _array_copy(config.get("selected_equipment_items", [])):
		var previous_item := _dictionary_copy(raw_item)
		var current_item := _find_warehouse_item(refreshed, str(previous_item.get("instance_id", "")))
		if not current_item.is_empty() and bool(current_item.get("can_equip", false)):
			equipment.append(current_item)
	for raw_item in _array_copy(config.get("selected_consumable_items", [])):
		var previous_item := _dictionary_copy(raw_item)
		var current_item := _find_warehouse_item(refreshed, str(previous_item.get("instance_id", "")))
		if not current_item.is_empty() and bool(current_item.get("can_consume", false)):
			consumables.append(current_item)
	var recalculated := _recalculate_loadout(refreshed, equipment, consumables)
	if bool(recalculated.get("valid", false)):
		refreshed = _dictionary_copy(recalculated.get("config", refreshed))
	return with_active_run_preview(refreshed, has_active_run)


static func apply_card_action(config: Dictionary, tab_id: StringName, card_id: StringName) -> Dictionary:
	if bool(config.get("active_run_locked", false)) and _mutates_active_run_projection(tab_id, card_id):
		return {
			"config": config.duplicate(true),
			"changed": false,
			"reason_code": &"active_run_locked",
			"message": "当前探索进行中，地图、委托与出勤配置均以当局记录为准。",
		}
	if tab_id == &"map" and String(card_id).begins_with("m7_map_"):
		return _select_m7_map(config, String(card_id).trim_prefix("m7_map_"))
	if tab_id == &"objective" and String(card_id).begins_with("m7_commission_"):
		return _select_m7_commission(config, String(card_id).trim_prefix("m7_commission_"))
	if tab_id == &"claim" and String(card_id).begins_with("m7_shop_"):
		return {
			"config": config.duplicate(true),
			"changed": false,
			"message": "正在提交基地购买。",
			"meta_action": {"action": &"purchase", "item_id": String(card_id).trim_prefix("m7_shop_")},
		}
	if tab_id == &"warehouse" and String(card_id).begins_with("m3r_") and card_id != &"m3r_warehouse_status":
		return _toggle_warehouse_item(config, String(card_id).trim_prefix("m3r_"))
	if tab_id == &"claim" and card_id == &"claim_emergency_ration":
		return _toggle_emergency_claim(config)
	return {
		"config": config.duplicate(true),
		"changed": false,
		"message": "该条目仅用于查看。",
	}


static func _mutates_active_run_projection(tab_id: StringName, card_id: StringName) -> bool:
	if tab_id == &"map" and String(card_id).begins_with("m7_map_"):
		return true
	if tab_id == &"objective" and String(card_id).begins_with("m7_commission_"):
		return true
	if tab_id == &"warehouse" and String(card_id).begins_with("m3r_") and card_id != &"m3r_warehouse_status":
		return true
	if tab_id == &"claim" and (String(card_id).begins_with("m7_shop_") or card_id == &"claim_emergency_ration"):
		return true
	return false


static func _select_m7_map(config: Dictionary, map_id: String) -> Dictionary:
	var unlocked: Array = _array_copy(config.get("unlocked_map_ids", []))
	if not unlocked.has(map_id):
		return {"config": config.duplicate(true), "changed": false, "message": "该地图尚未解锁。"}
	var result := config.duplicate(true)
	var definition := M7ContentCatalogScript.map_definition(map_id)
	result["map_config_id"] = map_id
	result["map_display_name"] = str(definition.get("display_name", map_id))
	result["difficulty"] = definition.get("difficulty", &"normal")
	result["difficulty_label"] = str(definition.get("difficulty_label", "普通"))
	result["selected_difficulty"] = result["difficulty"]
	result["selected_map_summary"] = "%s；地图真相在确认出发后生成。" % str(definition.get("display_name", map_id))
	var candidate_seed := int(result.get("commission_candidate_seed", 1)) + map_id.hash()
	var candidates := M7ContentCatalogScript.commission_candidates(map_id, candidate_seed)
	result["commission_candidates"] = candidates
	if not candidates.is_empty():
		var selected: Dictionary = candidates[0]
		result["selected_objective_id"] = StringName(selected.get("id", "commission_recover_supply"))
		result["selected_objective_label"] = str(selected.get("display_name", "回收补给箱"))
		result["selected_objective_summary"] = "%s：%s" % [str(selected.get("display_name", "")), str(selected.get("description", ""))]
	result["right_summary_preview"] = right_summary_preview(result)
	return {"config": result, "changed": true, "message": "已选择 %s。" % str(definition.get("display_name", map_id))}


static func _select_m7_commission(config: Dictionary, commission_id: String) -> Dictionary:
	var available := false
	var selected := {}
	for raw_candidate in _array_copy(config.get("commission_candidates", [])):
		var candidate := _dictionary_copy(raw_candidate)
		if str(candidate.get("id", "")) == commission_id:
			available = true
			selected = candidate
			break
	if not available:
		return {"config": config.duplicate(true), "changed": false, "message": "该委托不在本局候选中。"}
	var result := config.duplicate(true)
	result["selected_objective_id"] = StringName(commission_id)
	result["selected_objective_label"] = str(selected.get("display_name", commission_id))
	result["selected_objective_summary"] = "%s：%s" % [str(selected.get("display_name", "")), str(selected.get("description", ""))]
	result["right_summary_preview"] = right_summary_preview(result)
	return {"config": result, "changed": true, "message": "已选择委托：%s。" % str(selected.get("display_name", commission_id))}


static func _toggle_warehouse_item(config: Dictionary, instance_id: String) -> Dictionary:
	var item := _find_warehouse_item(config, instance_id)
	if not item.is_empty() and str(item.get("item_type", "")) == "collectible":
		if not bool(item.get("can_sell", false)) or bool(item.get("is_unique", false)):
			return {"config": config.duplicate(true), "changed": false, "message": "该藏品不可出售。"}
		if str(config.get("sell_confirm_pending_instance_id", "")) != instance_id:
			var pending := config.duplicate(true)
			pending["sell_confirm_pending_instance_id"] = instance_id
			return {
				"config": pending,
				"changed": true,
				"message": "再次点击确认出售 %s，获得 %d 金币。" % [str(item.get("display_name", item.get("item_id", "藏品"))), int(item.get("base_value", 0))],
			}
		return {
			"config": config.duplicate(true),
			"changed": false,
			"message": "正在提交单件藏品出售。",
			"meta_action": {"action": &"sell_collectible", "instance_id": instance_id},
		}
	if item.is_empty() or not bool(item.get("can_carry", false)):
		return {"config": config.duplicate(true), "changed": false, "message": "该物品不能加入本次出勤。"}
	var result := config.duplicate(true)
	var equipment := _array_copy(result.get("selected_equipment_items", []))
	var consumables := _array_copy(result.get("selected_consumable_items", []))
	var target := equipment if bool(item.get("can_equip", false)) else consumables
	var existing_index := _index_of_instance(target, instance_id)
	if existing_index >= 0:
		target.remove_at(existing_index)
		var recalculated := _recalculate_loadout(result, equipment, consumables)
		if not bool(recalculated.get("valid", false)):
			return {"config": config.duplicate(true), "changed": false, "message": str(recalculated.get("message", "移出后配置不合法。"))}
		return {"config": recalculated.get("config", result), "changed": true, "message": "%s 已移出本次出勤。" % str(item.get("display_name", item.get("item_id", "物品")))}
	if bool(item.get("can_equip", false)):
		if equipment.size() >= MAX_EQUIPPED_ITEMS:
			return {"config": config.duplicate(true), "changed": false, "message": "最多穿戴 %d 件装备。" % MAX_EQUIPPED_ITEMS}
		var slot := str(item.get("equipment_slot", ""))
		for raw_equipment in equipment:
			var equipped := _dictionary_copy(raw_equipment)
			if slot != "" and str(equipped.get("equipment_slot", "")) == slot:
				return {"config": config.duplicate(true), "changed": false, "message": "同一装备部位不能重复穿戴。"}
		equipment.append(item.duplicate(true))
	else:
		if consumables.size() >= MAX_CARRIED_CONSUMABLES:
			return {"config": config.duplicate(true), "changed": false, "message": "出发前最多携带 %d 件补给。" % MAX_CARRIED_CONSUMABLES}
		consumables.append(item.duplicate(true))
	var recalculated := _recalculate_loadout(result, equipment, consumables)
	if not bool(recalculated.get("valid", false)):
		return {"config": config.duplicate(true), "changed": false, "message": str(recalculated.get("message", "配置不合法。"))}
	return {"config": recalculated.get("config", result), "changed": true, "message": "%s 已加入本次出勤。" % str(item.get("display_name", item.get("item_id", "物品")))}


static func _toggle_emergency_claim(config: Dictionary) -> Dictionary:
	var result := config.duplicate(true)
	var claims := _array_copy(result.get("enabled_claims", []))
	var equipment := _array_copy(result.get("selected_equipment_items", []))
	var consumables := _array_copy(result.get("selected_consumable_items", []))
	var claim_instance_id := "claim:%s:con_ration" % str(result.get("config_id", "m6"))
	var index := _index_of_instance(consumables, claim_instance_id)
	if index >= 0:
		consumables.remove_at(index)
		claims.erase(EMERGENCY_CLAIM_ID)
		result["enabled_claims"] = claims
		var removed := _recalculate_loadout(result, equipment, consumables)
		return {"config": removed.get("config", result), "changed": true, "message": "已取消本次应急压缩饼。"}
	if consumables.size() >= MAX_CARRIED_CONSUMABLES:
		return {"config": config.duplicate(true), "changed": false, "message": "补给栏已满，请先移出一件补给。"}
	var ration := M3RItemUsabilityModelScript.normalize_item(M3RItemUsabilityModelScript.item_definition("con_ration"))
	ration["instance_id"] = claim_instance_id
	ration["source"] = "m6_emergency_claim"
	ration["source_label"] = "本局应急申领"
	ration["temporary_claim"] = true
	consumables.append(ration)
	claims.append(EMERGENCY_CLAIM_ID)
	result["enabled_claims"] = claims
	var recalculated := _recalculate_loadout(result, equipment, consumables)
	if not bool(recalculated.get("valid", false)):
		return {"config": config.duplicate(true), "changed": false, "message": str(recalculated.get("message", "无法申领。"))}
	return {"config": recalculated.get("config", result), "changed": true, "message": "已为本次探索申领压缩饼；终局后不会进入仓库。"}


static func _recalculate_loadout(config: Dictionary, equipment: Array, consumables: Array) -> Dictionary:
	var result := config.duplicate(true)
	var profile := _dictionary_copy(result.get("profile_fields", {}))
	var capacity := int(profile.get("backpack_capacity", M3RItemUsabilityModelScript.BASE_BACKPACK_CAPACITY))
	var salvage_capacity := int(profile.get("failure_salvage_capacity", M3RItemUsabilityModelScript.BASE_FAILURE_SALVAGE_CAPACITY))
	var mine_dmg_reduce := int(profile.get("mine_dmg_reduce", 0))
	var pressure_reduce := int(profile.get("protocol_pressure_reduce", 0))
	var search_reward_bonus := 0
	var scan_hint_bonus := 0
	var effects := M3RItemUsabilityModelScript.build_equipment_effects(equipment)
	for raw_effect in effects:
		var effect := _dictionary_copy(raw_effect)
		match str(effect.get("effect_kind", "")):
			"backpack_capacity": capacity += int(effect.get("effect_amount", 0))
			"salvage_capacity": salvage_capacity += int(effect.get("effect_amount", 0))
			"mine_damage_reduce": mine_dmg_reduce += int(effect.get("effect_amount", 0))
			"protocol_pressure_reduce": pressure_reduce += int(effect.get("effect_amount", 0))
			"search_reward": search_reward_bonus += int(effect.get("effect_amount", 0))
			"scan_hint": scan_hint_bonus += int(effect.get("effect_amount", 0))
	var used := 0
	for raw_item in consumables:
		used += maxi(0, int(_dictionary_copy(raw_item).get("weight", 0)))
	if used > capacity:
		return {"config": config.duplicate(true), "valid": false, "message": "背包超重：%d / %d。" % [used, capacity]}
	result["selected_equipment_items"] = _array_copy(equipment)
	result["selected_consumable_items"] = _array_copy(consumables)
	result["selected_equipment_ids"] = _instance_ids(equipment)
	result["selected_consumable_ids"] = _instance_ids(consumables)
	result["selected_loadout"] = _instance_ids(equipment)
	result["carried_consumables"] = _instance_ids(consumables)
	result["equipment_effects"] = effects
	result["bag_used"] = used
	result["bag_limit"] = capacity
	result["backpack_capacity"] = capacity
	result["failure_salvage_capacity"] = salvage_capacity
	result["mine_dmg_reduce"] = mine_dmg_reduce
	result["protocol_pressure_reduce"] = pressure_reduce
	result["search_reward_bonus"] = search_reward_bonus
	result["scan_hint_bonus"] = scan_hint_bonus
	result["loadout_preview"] = _loadout_from_m3r(result)
	result["backpack_capacity_preview"] = _capacity_from_m3r(result)
	result["config_validity_preview"] = _config_validity_for(result)
	result["right_summary_preview"] = right_summary_preview(result)
	result["risk_summary"] = {"level": &"m7", "label": "M7 risk summary", "lines": _array_copy(result["right_summary_preview"].get("risk", []))}
	result["effect_summary"] = {"label": "M7 effect summary", "lines": _array_copy(result["right_summary_preview"].get("effect", []))}
	result["initial_bag_summary"] = {"used": used, "limit": capacity, "label": "Carry weight %d / %d" % [used, capacity]}
	return {"config": result, "valid": true, "message": "配置已更新。"}


static func _find_warehouse_item(config: Dictionary, instance_id: String) -> Dictionary:
	var warehouse := _dictionary_copy(config.get("warehouse_lite", {}))
	var groups := _dictionary_copy(warehouse.get("groups", {}))
	for raw_group in groups.values():
		for raw_item in _array_copy(raw_group):
			var item := _dictionary_copy(raw_item)
			if str(item.get("instance_id", "")) == instance_id:
				return item
	return {}


static func _index_of_instance(items: Array, instance_id: String) -> int:
	for index in range(items.size()):
		if str(_dictionary_copy(items[index]).get("instance_id", "")) == instance_id:
			return index
	return -1


static func _instance_ids(items: Array) -> Array[String]:
	var result: Array[String] = []
	for raw_item in items:
		var instance_id := str(_dictionary_copy(raw_item).get("instance_id", ""))
		if instance_id != "":
			result.append(instance_id)
	return result


static func build_run_start_config(config: Dictionary) -> Dictionary:
	var source := config.duplicate(true)
	return {
		"config_id": str(source.get("config_id", "")),
		"config_version": int(source.get("config_version", CONFIG_VERSION)),
		"map_config_id": str(source.get("map_config_id", "classic_7x7_simple")),
		"map_display_name": str(source.get("map_display_name", "7×7 简单")),
		"seed_value": int(source.get("seed_value", 0)),
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
		"commission_candidates": _array_copy(source.get("commission_candidates", [])),
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
		"failure_salvage_capacity": int(source.get("failure_salvage_capacity", 4)),
		"profile_fields": _dictionary_copy(source.get("profile_fields", {})),
		"talent_interface": _array_copy(source.get("talent_interface", [])),
		"active_talent_effects": _array_copy(source.get("active_talent_effects", [])),
		"profile_level": int(source.get("profile_level", 1)),
		"profile_exp": int(source.get("profile_exp", 0)),
		"permit_level": int(source.get("permit_level", 1)),
		"protocol_difficulty": int(source.get("protocol_difficulty", 5)),
		"mine_dmg_reduce": int(source.get("mine_dmg_reduce", 0)),
		"protocol_pressure_reduce": int(source.get("protocol_pressure_reduce", 0)),
		"search_reward_bonus": int(source.get("search_reward_bonus", 0)),
		"scan_hint_bonus": int(source.get("scan_hint_bonus", 0)),
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
	var map_label := str(config.get("map_mode_label", "Classic Minesweeper"))
	var difficulty_label := str(config.get("difficulty_label", "Normal"))
	var region_label := str(config.get("region_label", "Graytail Edge"))
	var equipment_ids := _array_copy(config.get("selected_equipment_ids", []))
	var consumable_ids := _array_copy(config.get("selected_consumable_ids", []))
	var active_run := _dictionary_copy(config.get("active_run_preview", active_run_preview(false)))
	return {
		"map": ["地图：%s" % map_label, "难度：%s" % difficulty_label, "区域：%s" % region_label],
		"objective": ["委托：%s" % str(config.get("selected_objective_label", "回收补给箱")), "达成条件并成功撤离后自动发放奖励", "当前探索：%s" % str(active_run.get("label", "no active run"))],
		"config": ["装备实例：%s" % _join_array(equipment_ids, "无"), "消耗品实例：%s" % _join_array(consumable_ids, "无"), "背包：%d/%d" % [int(config.get("bag_used", 0)), int(config.get("bag_limit", 10))]],
		"effect": ["已选装备在本局生效且不占背包", "携入消耗品占用背包", "所有消耗品在任意终局清除", "失败保全按重量由玩家确认"],
		"risk": ["黑色资源仅成功时转为金色资源", "放弃不保全物品但保留直接获得的金色资源", "当前进程可返回整备并继续同一局", "失败抢救确认前不会写入局外进度"],
	}


static func _legacy_right_summary_preview(config: Dictionary) -> Dictionary:
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
			"abandon_confirm_text": "Abandon loses black resources and all items, retains direct gold, and cannot be undone.",
			"preview": false,
			"display_only": false,
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
		"consumable_note": "All carry-in and in-run consumables clear on success, failure, or abandon; they never return to the warehouse or enter salvage.",
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
		"preset_note": "M6 uses only the warehouse instances selected by the player.",
		"consumable_note": "Carry-in and in-run consumables are cleared when the run ends, even when unused.",
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
		"failure_salvage_capacity": int(m3r_fields.get("failure_salvage_capacity", 4)),
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
	return _config_validity_for({"bag_used": 0, "bag_limit": 10})


static func _config_validity_for(config: Dictionary) -> Dictionary:
	var used := int(config.get("bag_used", 0))
	var limit := int(config.get("bag_limit", 10))
	var valid := used <= limit
	return {
		"label": "M6 出勤配置合法" if valid else "背包超重，不能出发",
		"checks": [
			"map selected",
			"difficulty selected",
			"warehouse instances selected by player",
			"equipment slots and carried supplies validated",
			"carry weight %d / %d" % [used, limit],
			"RunStartConfig can be handed to the existing route adapter",
		],
		"can_start": valid,
		"blocked_real_actions": ["complete_deploy_economy", "insurance", "shipping"],
		"display_only": false,
		"read_only": true,
		"preview": false,
	}


static func _action_intent_boundaries_preview() -> Dictionary:
	return {
		"start_intent": "Builds a real minimal RunStartConfig and routes it into the existing standard_10x10 start path.",
		"continue_intent": "An active in-process run can return from DeployPrep without creating a second run.",
		"abandon_intent": "Abandon requires strong confirmation and routes to the real zero-salvage settlement branch.",
		"requires_confirm": ["abandon"],
		"blocked_actions": ["full_process_restart_persistence"],
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
