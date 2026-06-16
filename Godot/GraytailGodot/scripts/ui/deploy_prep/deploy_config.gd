extends RefCounted
class_name DeployConfig

const CONFIG_VERSION := 1
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
		"selected_loadout": [],
		"carried_consumables": [],
		"enabled_claims": [],
		"enabled_services": [],
		"enabled_work_permits": [],
		"enabled_intel_flags": [],
		"bag_used": 0,
		"bag_limit": 12,
		"risk_summary": {
			"level": &"pending",
			"label": "风险待评估",
			"lines": [
				"地图、作业许可、保险和托运规则尚未接入。",
				"当前只保留出勤准备摘要，不生成真实地图或收益。",
			],
		},
		"effect_summary": {
			"label": "效果待配置",
			"lines": [
				"仓库、申领和作业许可效果后置。",
				"本预览不会修改运行状态、存档或长期系统。",
			],
		},
		"source_page": &"deploy_prep",
		"created_at_or_sequence": max(sequence, 1),
		"run_origin": RUN_ORIGIN_PREVIEW,
		"deploy_summary": "出勤准备预览：标准探索配置尚未正式启动。",
		"selected_map_summary": "地图：占位；真实地图生成后置。",
		"selected_difficulty": DIFFICULTY_NORMAL,
		"selected_permits": [],
		"selected_services": [],
		"initial_bag_summary": {
			"used": 0,
			"limit": 12,
			"label": "背包占用 0 / 12；真实仓库装载后置。",
		},
		"initial_risk_summary": {},
		"initial_effect_summary": {},
		"profile_snapshot_ref": &"placeholder_profile_snapshot",
		"unlock_snapshot_ref": &"placeholder_unlock_snapshot",
	}
	config["initial_risk_summary"] = (config["risk_summary"] as Dictionary).duplicate(true)
	config["initial_effect_summary"] = (config["effect_summary"] as Dictionary).duplicate(true)
	config["history_metadata"] = history_metadata_for(config)
	return config


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
		"history_metadata": history_metadata_for(source),
		"profile_snapshot_ref": source.get("profile_snapshot_ref", &"placeholder_profile_snapshot"),
		"unlock_snapshot_ref": source.get("unlock_snapshot_ref", &"placeholder_unlock_snapshot"),
	}


static func build_preview_lines(config: Dictionary) -> Dictionary:
	var run_start := build_run_start_config(config)
	return {
		"summary": [
			String(run_start.get("deploy_summary", "")),
			String(run_start.get("selected_map_summary", "")),
			"开局来源：%s" % String(run_start.get("run_origin", RUN_ORIGIN_PREVIEW)),
		],
		"config": [
			"难度：%s" % String(run_start.get("selected_difficulty", DIFFICULTY_NORMAL)),
			"区域：%s" % String(run_start.get("region_id", REGION_PLACEHOLDER)),
			"Seed 策略：%s" % String(run_start.get("seed_policy", SEED_POLICY_DEFER)),
		],
		"effect": _summary_lines(run_start.get("effect_summary", {})),
		"risk": _summary_lines(run_start.get("risk_summary", {})),
	}


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
		"run_origin": StringName(config.get("run_origin", RUN_ORIGIN_PREVIEW)),
	}


static func _summary_lines(summary: Variant) -> Array:
	if summary is Dictionary:
		var raw_lines: Variant = (summary as Dictionary).get("lines", [])
		if raw_lines is Array:
			return (raw_lines as Array).duplicate(true)
	return []


static func _array_copy(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


static func _dictionary_copy(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
