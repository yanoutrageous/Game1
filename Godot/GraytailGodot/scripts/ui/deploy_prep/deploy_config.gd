extends RefCounted
class_name DeployConfig

const AssetProjectionSchemaScript := preload("res://scripts/core/asset/asset_projection_schema.gd")

const CONFIG_VERSION := 2
const START_MODE_STANDARD_PREVIEW := &"standard_preview"
const MAP_MODE_PLACEHOLDER := &"map_placeholder"
const DIFFICULTY_NORMAL := &"normal"
const REGION_PLACEHOLDER := &"region_unassigned"
const SEED_POLICY_DEFER := &"defer_until_run_start"
const RUN_ORIGIN_PREVIEW := &"deploy_prep_preview"


static func default_config(sequence: int = 1) -> Dictionary:
	var config := {
		"config_id": "deploy_preview_%04d" % max(sequence, 1),
		"config_version": CONFIG_VERSION,
		"start_mode": START_MODE_STANDARD_PREVIEW,
		"map_mode": MAP_MODE_PLACEHOLDER,
		"difficulty": DIFFICULTY_NORMAL,
		"region_id": REGION_PLACEHOLDER,
		"seed_policy": SEED_POLICY_DEFER,
		"selected_loadout": ["field_knife"],
		"carried_consumables": ["first_aid"],
		"enabled_claims": [],
		"enabled_services": [],
		"enabled_work_permits": ["permit_basic"],
		"enabled_intel_flags": [],
		"bag_used": 2,
		"bag_limit": 12,
		"source_page": &"deploy_prep",
		"created_at_or_sequence": max(sequence, 1),
		"run_origin": RUN_ORIGIN_PREVIEW,
		"deploy_summary": "出发探索准备 preview：只展示本局出勤草案，不启动探索。",
		"selected_map_summary": "地图：灰尾外围占位；真实地图生成后置。",
		"selected_difficulty": DIFFICULTY_NORMAL,
		"selected_permits": ["permit_basic"],
		"selected_services": [],
		"profile_snapshot_ref": &"placeholder_profile_snapshot",
		"unlock_snapshot_ref": &"placeholder_unlock_snapshot",
		"asset_attendance_preview": _asset_attendance_preview(),
		"warehouse_attendance_preview": _warehouse_attendance_preview(),
		"claim_preview": _claim_preview(),
		"loadout_preview": _loadout_preview(),
		"permit_preview": _permit_preview(),
		"active_run_preview": active_run_preview(false),
		"deploy_prep_projection": deploy_prep_projection_preview(),
	}
	config["initial_bag_summary"] = {
		"used": int(config.get("bag_used", 0)),
		"limit": int(config.get("bag_limit", 12)),
		"label": "背包占用 %d / %d；只来自出勤草案。" % [int(config.get("bag_used", 0)), int(config.get("bag_limit", 12))],
	}
	config["right_summary_preview"] = right_summary_preview(config)
	config["risk_summary"] = {
		"level": &"preview",
		"label": "风险 preview",
		"lines": _array_copy((config["right_summary_preview"] as Dictionary).get("risk", [])),
	}
	config["effect_summary"] = {
		"label": "效果 preview",
		"lines": _array_copy((config["right_summary_preview"] as Dictionary).get("effect", [])),
	}
	config["initial_risk_summary"] = (config["risk_summary"] as Dictionary).duplicate(true)
	config["initial_effect_summary"] = (config["effect_summary"] as Dictionary).duplicate(true)
	config["history_metadata"] = history_metadata_for(config)
	return config


static func with_active_run_preview(config: Dictionary, has_active_run: bool) -> Dictionary:
	var result := config.duplicate(true)
	result["active_run_preview"] = active_run_preview(has_active_run)
	result["right_summary_preview"] = right_summary_preview(result)
	result["risk_summary"] = {
		"level": &"preview",
		"label": "风险 preview",
		"lines": _array_copy((result["right_summary_preview"] as Dictionary).get("risk", [])),
	}
	result["effect_summary"] = {
		"label": "效果 preview",
		"lines": _array_copy((result["right_summary_preview"] as Dictionary).get("effect", [])),
	}
	return result


static func build_run_start_config(config: Dictionary) -> Dictionary:
	var source := config.duplicate(true)
	return {
		"config_id": String(source.get("config_id", "")),
		"config_version": int(source.get("config_version", CONFIG_VERSION)),
		"start_mode": StringName(source.get("start_mode", START_MODE_STANDARD_PREVIEW)),
		"map_mode": StringName(source.get("map_mode", MAP_MODE_PLACEHOLDER)),
		"difficulty": StringName(source.get("difficulty", DIFFICULTY_NORMAL)),
		"region_id": StringName(source.get("region_id", REGION_PLACEHOLDER)),
		"seed_policy": StringName(source.get("seed_policy", SEED_POLICY_DEFER)),
		"selected_loadout": _array_copy(source.get("selected_loadout", [])),
		"carried_consumables": _array_copy(source.get("carried_consumables", [])),
		"enabled_claims": _array_copy(source.get("enabled_claims", [])),
		"enabled_services": _array_copy(source.get("enabled_services", [])),
		"enabled_work_permits": _array_copy(source.get("enabled_work_permits", [])),
		"enabled_intel_flags": _array_copy(source.get("enabled_intel_flags", [])),
		"bag_used": int(source.get("bag_used", 0)),
		"bag_limit": int(source.get("bag_limit", 12)),
		"risk_summary": _dictionary_copy(source.get("risk_summary", {})),
		"effect_summary": _dictionary_copy(source.get("effect_summary", {})),
		"source_page": StringName(source.get("source_page", &"deploy_prep")),
		"created_at_or_sequence": source.get("created_at_or_sequence", 1),
		"run_origin": StringName(source.get("run_origin", RUN_ORIGIN_PREVIEW)),
		"deploy_summary": String(source.get("deploy_summary", "")),
		"selected_map_summary": String(source.get("selected_map_summary", "")),
		"selected_difficulty": StringName(source.get("selected_difficulty", source.get("difficulty", DIFFICULTY_NORMAL))),
		"selected_permits": _array_copy(source.get("selected_permits", [])),
		"selected_services": _array_copy(source.get("selected_services", [])),
		"initial_bag_summary": _dictionary_copy(source.get("initial_bag_summary", {})),
		"initial_risk_summary": _dictionary_copy(source.get("initial_risk_summary", source.get("risk_summary", {}))),
		"initial_effect_summary": _dictionary_copy(source.get("initial_effect_summary", source.get("effect_summary", {}))),
		"asset_attendance_preview": _dictionary_copy(source.get("asset_attendance_preview", {})),
		"warehouse_attendance_preview": _dictionary_copy(source.get("warehouse_attendance_preview", {})),
		"claim_preview": _dictionary_copy(source.get("claim_preview", {})),
		"loadout_preview": _dictionary_copy(source.get("loadout_preview", {})),
		"permit_preview": _dictionary_copy(source.get("permit_preview", {})),
		"active_run_preview": _dictionary_copy(source.get("active_run_preview", active_run_preview(false))),
		"deploy_prep_projection": _dictionary_copy(source.get("deploy_prep_projection", deploy_prep_projection_preview())),
		"right_summary_preview": _dictionary_copy(source.get("right_summary_preview", right_summary_preview(source))),
		"history_metadata": history_metadata_for(source),
		"profile_snapshot_ref": source.get("profile_snapshot_ref", &"placeholder_profile_snapshot"),
		"unlock_snapshot_ref": source.get("unlock_snapshot_ref", &"placeholder_unlock_snapshot"),
	}


static func build_preview_lines(config: Dictionary) -> Dictionary:
	var run_start := build_run_start_config(config)
	var right_summary := _dictionary_copy(run_start.get("right_summary_preview", {}))
	return {
		"summary": _array_copy(right_summary.get("summary", [])),
		"config": _array_copy(right_summary.get("config", [])),
		"effect": _array_copy(right_summary.get("effect", [])),
		"risk": _array_copy(right_summary.get("risk", [])),
	}


static func right_summary_preview(config: Dictionary) -> Dictionary:
	var active_run := _dictionary_copy(config.get("active_run_preview", active_run_preview(false)))
	var loadout := _dictionary_copy(config.get("loadout_preview", _loadout_preview()))
	var permit := _dictionary_copy(config.get("permit_preview", _permit_preview()))
	var warehouse := _dictionary_copy(config.get("warehouse_attendance_preview", _warehouse_attendance_preview()))
	var claim := _dictionary_copy(config.get("claim_preview", _claim_preview()))
	return {
		"summary": [
			String(config.get("deploy_summary", "")),
			String(config.get("selected_map_summary", "")),
			"出勤资产视角：%s" % String(warehouse.get("label", "仓库出勤 preview")),
			"当前探索状态：%s" % String(active_run.get("label", "无进行中探索")),
		],
		"config": [
			"已穿戴：%s" % _join_array(loadout.get("equipped", []), "未选择"),
			"携带消耗品：%s" % _join_array(loadout.get("carried_consumables", []), "未选择"),
			"已启用许可：%s" % _join_array(permit.get("enabled", []), "未启用"),
			"背包占用：%d / %d" % [int(config.get("bag_used", 0)), int(config.get("bag_limit", 12))],
		],
		"effect": [
			"仓库动作：加入/移出出勤、穿戴/卸下均为 draft preview。",
			"申领入口：%s" % String(claim.get("label", "补给 / 服务 / 情报 preview")),
			"作业许可：只显示容量和效果摘要，不应用真实规则。",
			"G21 projection：只读 display-only schema shape。",
		],
		"risk": [
			"真实地图、仓库、申领、许可和容量规则尚未接入。",
			"当前不会产生资源、事件、记录或持久状态。",
			"若已有探索，配置入口应弱化；放弃必须强确认。",
		],
	}


static func active_run_preview(has_active_run: bool) -> Dictionary:
	if has_active_run:
		return {
			"has_active_run": true,
			"label": "存在进行中探索",
			"start_disabled": true,
			"continue_disabled": false,
			"abandon_disabled": false,
			"config_lock_note": "已有探索时配置应锁定或弱化，当前只显示 preview。",
			"abandon_requires_confirm": true,
			"abandon_confirm_text": "放弃当前探索需要强确认；本轮不执行真实放弃。",
		}
	return {
		"has_active_run": false,
		"label": "无进行中探索",
		"start_disabled": false,
		"continue_disabled": true,
		"abandon_disabled": true,
		"config_lock_note": "未开始探索时允许编辑出勤草案 preview。",
		"abandon_requires_confirm": false,
		"abandon_confirm_text": "没有可放弃的探索。",
	}


static func deploy_prep_projection_preview() -> Dictionary:
	var projection := AssetProjectionSchemaScript.default_deploy_prep_projection()
	projection["source_system"] = &"deploy_prep"
	projection["summary"] = {
		"label": "Deploy Prep asset attendance projection preview",
		"read_only_note": "只描述出发前资产出勤视角，不写入资产状态。",
	}
	projection["asset_refs"] = [
		{"asset_id": "field_knife", "definition_id": "field_knife", "asset_type": &"entity_item"},
		{"asset_id": "first_aid", "definition_id": "first_aid", "asset_type": &"entity_item"},
		{"asset_id": "sealed_relic", "definition_id": "sealed_relic", "asset_type": &"entity_item"},
	]
	projection["link_targets"] = [
		{"target": &"codex", "label": "前往图鉴说明", "preview_only": true},
		{"target": &"research", "label": "前往研究说明", "preview_only": true},
		{"target": &"long_term", "label": "前往长期系统说明", "preview_only": true},
	]
	projection["extra"] = {
		"draft_actions": ["加入出勤", "移出出勤", "穿戴", "卸下"],
		"non_goals": ["不出售", "不整理仓库", "不发放奖励"],
	}
	return AssetProjectionSchemaScript.normalize_projection(projection)


static func history_metadata_for(config: Dictionary) -> Dictionary:
	return {
		"config_id": String(config.get("config_id", "")),
		"config_version": int(config.get("config_version", CONFIG_VERSION)),
		"start_mode": StringName(config.get("start_mode", START_MODE_STANDARD_PREVIEW)),
		"map_mode": StringName(config.get("map_mode", MAP_MODE_PLACEHOLDER)),
		"difficulty": StringName(config.get("difficulty", DIFFICULTY_NORMAL)),
		"region_id": StringName(config.get("region_id", REGION_PLACEHOLDER)),
		"seed_policy": StringName(config.get("seed_policy", SEED_POLICY_DEFER)),
		"selected_difficulty": StringName(config.get("selected_difficulty", config.get("difficulty", DIFFICULTY_NORMAL))),
		"selected_permits": _array_copy(config.get("selected_permits", [])),
		"selected_services": _array_copy(config.get("selected_services", [])),
		"initial_bag_summary": _dictionary_copy(config.get("initial_bag_summary", {})),
		"initial_risk_summary": _dictionary_copy(config.get("initial_risk_summary", config.get("risk_summary", {}))),
		"initial_effect_summary": _dictionary_copy(config.get("initial_effect_summary", config.get("effect_summary", {}))),
		"asset_attendance_preview": _dictionary_copy(config.get("asset_attendance_preview", {})),
		"run_origin": StringName(config.get("run_origin", RUN_ORIGIN_PREVIEW)),
	}


static func _asset_attendance_preview() -> Dictionary:
	return {
		"label": "出发探索资产出勤视角",
		"primary_tabs": ["地图", "仓库", "申领", "出勤配置", "作业许可"],
		"draft_actions": ["加入出勤", "移出出勤", "穿戴", "卸下"],
		"display_only": true,
	}


static func _warehouse_attendance_preview() -> Dictionary:
	return {
		"label": "仓库出勤 preview",
		"categories": ["装备", "消耗品", "藏品", "特殊物", "未判断价值"],
		"allowed_draft_actions": ["加入出勤", "移出出勤", "穿戴", "卸下", "查看详情", "只读跳转"],
		"blocked_actions": ["出售", "批量整理", "真实仓库写入"],
	}


static func _claim_preview() -> Dictionary:
	return {
		"label": "补给 / 服务 / 情报 / 基础装备 preview",
		"groups": ["补给", "服务", "情报", "基础装备"],
		"blocked_actions": ["商店交易", "奖励领取", "资源发放"],
	}


static func _loadout_preview() -> Dictionary:
	return {
		"equipped": ["野外短刀"],
		"carried_consumables": ["简易急救包 x2"],
		"enabled_permits": ["基础作业许可"],
		"service_interfaces": [],
		"preset_note": "预设、清空、重置只保留 preview 口径。",
	}


static func _permit_preview() -> Dictionary:
	return {
		"unlocked": ["基础作业许可"],
		"locked": ["深层作业许可"],
		"enabled": ["基础作业许可"],
		"capacity": {"used": 1, "limit": 2},
		"effect_summary": ["许可效果只进入右侧摘要，不应用真实规则。"],
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
	var parts := []
	for item in items:
		parts.append(String(item))
	return "、".join(parts)
