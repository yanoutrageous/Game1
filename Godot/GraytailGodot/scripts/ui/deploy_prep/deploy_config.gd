extends RefCounted
class_name DeployConfig

const AssetDomainContractScript := preload("res://scripts/core/asset/asset_domain_contract.gd")
const AssetProjectionSchemaScript := preload("res://scripts/core/asset/asset_projection_schema.gd")
const WarehouseViewSchemaScript := preload("res://scripts/core/asset/warehouse_view_schema.gd")
const WarehouseViewContentSchemaScript := preload("res://scripts/core/asset/warehouse_view_content_schema.gd")

const CONFIG_VERSION := 3
const START_MODE_STANDARD_PREVIEW := &"standard_preview"
const MAP_MODE_CLASSIC_PREVIEW := &"classic_minesweeper_preview"
const DIFFICULTY_NORMAL := &"normal"
const REGION_GRAYTAIL_EDGE := &"graytail_edge_preview"
const SEED_POLICY_DEFER := &"defer_until_run_start"
const RUN_ORIGIN_PREVIEW := &"deploy_prep_preview"


static func default_config(sequence: int = 1) -> Dictionary:
	var config := {
		"config_id": "deploy_preview_%04d" % max(sequence, 1),
		"config_version": CONFIG_VERSION,
		"start_mode": START_MODE_STANDARD_PREVIEW,
		"map_mode": MAP_MODE_CLASSIC_PREVIEW,
		"map_mode_label": "常规扫雷",
		"difficulty": DIFFICULTY_NORMAL,
		"difficulty_label": "普通",
		"region_id": REGION_GRAYTAIL_EDGE,
		"region_label": "灰尾外围",
		"seed_policy": SEED_POLICY_DEFER,
		"selected_loadout": ["field_knife", "patched_vest"],
		"carried_consumables": ["first_aid", "flare_pack"],
		"enabled_claims": [],
		"selected_objective_id": &"objective_recover_cache",
		"selected_objective_label": "回收补给箱",
		"enabled_services": [],
		"enabled_work_permits": [],
		"enabled_intel_flags": [],
		"bag_used": 3,
		"bag_limit": 12,
		"source_page": &"deploy_prep",
		"created_at_or_sequence": max(sequence, 1),
		"run_origin": RUN_ORIGIN_PREVIEW,
		"deploy_summary": "出发探索准备中心 preview：只展示本局出勤草案，不启动探索。",
		"selected_map_summary": "地图：常规扫雷 / 普通 / 灰尾外围；真实地图生成后置。",
		"selected_difficulty": DIFFICULTY_NORMAL,
		"selected_permits": [],
		"selected_services": [],
		"selected_objective_summary": "目标：回收补给箱；类型：回收类；地图匹配：可用；奖励类型：资源 / 藏品引用 preview。",
		"profile_snapshot_ref": &"placeholder_profile_snapshot",
		"unlock_snapshot_ref": &"placeholder_unlock_snapshot",
		"asset_attendance_preview": _asset_attendance_preview(),
		"warehouse_attendance_preview": _warehouse_attendance_preview(),
		"claim_preview": _claim_preview(),
		"objective_preview": _objective_preview(),
		"loadout_preview": _loadout_preview(),
		"permit_preview": _permission_interface_preview(),
		"permission_interface_preview": _permission_interface_preview(),
		"backpack_capacity_preview": _backpack_capacity_preview(),
		"config_validity_preview": _config_validity_preview(),
		"action_intent_boundaries": _action_intent_boundaries_preview(),
		"active_run_preview": active_run_preview(false),
		"deploy_prep_projection": deploy_prep_projection_preview(),
		"deploy_asset_view_preview": WarehouseViewSchemaScript.default_deploy_asset_view(),
		"warehouse_view_snapshot": WarehouseViewSchemaScript.default_warehouse_view_snapshot(),
		"warehouse_view_content_snapshot": WarehouseViewContentSchemaScript.build_deploy_prep_content_view(),
		"long_term_asset_interface_preview": _long_term_asset_interface_preview(),
		"preview": true,
		"display_only": true,
		"read_only": true,
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
		"map_mode": StringName(source.get("map_mode", MAP_MODE_CLASSIC_PREVIEW)),
		"map_mode_label": String(source.get("map_mode_label", "常规扫雷")),
		"difficulty": StringName(source.get("difficulty", DIFFICULTY_NORMAL)),
		"difficulty_label": String(source.get("difficulty_label", "普通")),
		"region_id": StringName(source.get("region_id", REGION_GRAYTAIL_EDGE)),
		"region_label": String(source.get("region_label", "灰尾外围")),
		"seed_policy": StringName(source.get("seed_policy", SEED_POLICY_DEFER)),
		"selected_loadout": _array_copy(source.get("selected_loadout", [])),
		"carried_consumables": _array_copy(source.get("carried_consumables", [])),
		"enabled_claims": _array_copy(source.get("enabled_claims", [])),
		"selected_objective_id": StringName(source.get("selected_objective_id", &"objective_recover_cache")),
		"selected_objective_label": String(source.get("selected_objective_label", "回收补给箱")),
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
		"selected_objective_summary": String(source.get("selected_objective_summary", "")),
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
		"right_summary_preview": _dictionary_copy(source.get("right_summary_preview", right_summary_preview(source))),
		"history_metadata": history_metadata_for(source),
		"profile_snapshot_ref": source.get("profile_snapshot_ref", &"placeholder_profile_snapshot"),
		"unlock_snapshot_ref": source.get("unlock_snapshot_ref", &"placeholder_unlock_snapshot"),
		"preview": true,
		"display_only": true,
		"read_only": true,
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
	var warehouse := _dictionary_copy(config.get("warehouse_attendance_preview", _warehouse_attendance_preview()))
	var claim := _dictionary_copy(config.get("claim_preview", _claim_preview()))
	var objective := _dictionary_copy(config.get("objective_preview", _objective_preview()))
	var validity := _dictionary_copy(config.get("config_validity_preview", _config_validity_preview()))
	var capacity := _dictionary_copy(config.get("backpack_capacity_preview", _backpack_capacity_preview()))
	var permission_interface := _dictionary_copy(config.get("permission_interface_preview", _permission_interface_preview()))
	var bag := _dictionary_copy(config.get("initial_bag_summary", {}))
	return {
		"summary": [
			String(config.get("deploy_summary", "")),
			"当前地图模式 / 难度 / 区域：%s / %s / %s" % [String(config.get("map_mode_label", "常规扫雷")), String(config.get("difficulty_label", "普通")), String(config.get("region_label", "灰尾外围"))],
			"当前目标：%s" % String(objective.get("selected_label", config.get("selected_objective_label", "未选择目标"))),
			"背包容量：%s" % String(capacity.get("label", bag.get("label", "背包容量未计算"))),
			"配置合法性：%s" % String(validity.get("label", "preview 校验未计算")),
			"进行中探索 preview：%s" % String(active_run.get("label", "无进行中探索")),
			"真实开始未接入：这里只生成出勤 preview / intent / display_only 数据。",
		],
		"config": [
			"地图 / 难度：%s / %s" % [String(config.get("map_mode_label", "常规扫雷")), String(config.get("difficulty_label", "普通"))],
			"目标摘要：%s" % String(config.get("selected_objective_summary", "")),
			"已穿戴装备：%s" % _join_array(loadout.get("equipped", []), "未选择"),
			"本局携带消耗品：%s" % _join_array(loadout.get("carried_consumables", []), "未选择"),
			"已带特殊物：%s" % _join_array(loadout.get("carried_specials", []), "未选择"),
			"购买但未带入：%s" % _join_array(loadout.get("purchased_not_carried", []), "无"),
			"已配置物品数量：%d" % int(loadout.get("configured_item_count", 0)),
			"背包容量：%d / %d" % [int(config.get("bag_used", 0)), int(config.get("bag_limit", 12))],
			"本局携带消耗品将在本局结束后默认清空。",
		],
		"effect": [
			"装备效果 preview：只显示效果类型，不显示正式数值。",
			"消耗品效果 preview：探测相邻房间会按当前地图拓扑解释。",
			"特殊物效果 preview：只显示目标 / 委托相关提示。",
			"背包效果 preview：容量变化只显示在右侧摘要，不写真实背包。",
			"撤离效果 preview：撤离点位置不披露，失败保护未实现。",
			"目标效果 preview：奖励类型摘要只读显示，不发放奖励。",
			"申领目录：%s" % String(claim.get("label", "catalog-first preview")),
			"仓库视角：%s" % String(warehouse.get("label", "ownership-first preview")),
		],
		"risk": [
			"真实地图未生成；Boss / 撤离点 / 房间内容未探明。",
			"高风险目标失败可能失去目标奖励；本轮不实现奖励系统。",
			"本局携带消耗品将在本局结束后默认清空。",
			"放弃不等于成功撤离；真实放弃结算未接入。",
			"作业许可 / 保险 / 托运：%s" % String(permission_interface.get("state_label", "后续接口 / locked state")),
			"真实资产 / 存档 / 结算未接入，不会写入仓库或历史。",
			"如已有进行中探索，配置入口应弱化；放弃必须强确认 preview。",
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
			"config_lock_note": "已有探索时配置应锁定或弱化；当前只显示 preview，不执行继续。",
			"abandon_requires_confirm": true,
			"abandon_confirm_text": "放弃当前探索需要强确认；本轮不执行真实放弃。",
			"preview": true,
			"display_only": true,
			"read_only": true,
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
		"preview": true,
		"display_only": true,
		"read_only": true,
	}


static func deploy_prep_projection_preview() -> Dictionary:
	var projection := AssetProjectionSchemaScript.default_deploy_prep_projection()
	projection["source_system"] = &"deploy_prep"
	projection["summary"] = {
		"label": "Deploy Prep full module content preview",
		"read_only_note": "只描述出发前资产出勤视角，不写入资产状态。",
		"seed_policy": SEED_POLICY_DEFER,
	}
	projection["asset_refs"] = [
		{"asset_id": "field_knife", "definition_id": "field_knife", "asset_type": &"entity_item"},
		{"asset_id": "patched_vest", "definition_id": "patched_vest", "asset_type": &"entity_item"},
		{"asset_id": "first_aid", "definition_id": "first_aid", "asset_type": &"entity_item"},
		{"asset_id": "sealed_relic", "definition_id": "sealed_relic", "asset_type": &"entity_item"},
	]
	projection["link_targets"] = [
		{"target": &"codex", "label": "前往图鉴说明", "preview_only": true},
		{"target": &"research", "label": "前往研究说明", "preview_only": true},
		{"target": &"long_term", "label": "前往长期系统说明", "preview_only": true},
	]
	projection["extra"] = {
		"draft_actions": ["加入出勤", "移出出勤", "穿戴", "卸下", "领取", "购买", "回收 / 出售 preview", "购买并加入出勤", "选择目标"],
		"non_goals": ["不真实出售", "不整理仓库", "不发放奖励", "不扣金币", "不写领取记录", "不建立独立情报 / 服务系统"],
		"display_only": true,
		"read_only": true,
	}
	return AssetProjectionSchemaScript.normalize_projection(projection)


static func history_metadata_for(config: Dictionary) -> Dictionary:
	return {
		"config_id": String(config.get("config_id", "")),
		"config_version": int(config.get("config_version", CONFIG_VERSION)),
		"start_mode": StringName(config.get("start_mode", START_MODE_STANDARD_PREVIEW)),
		"map_mode": StringName(config.get("map_mode", MAP_MODE_CLASSIC_PREVIEW)),
		"difficulty": StringName(config.get("difficulty", DIFFICULTY_NORMAL)),
		"region_id": StringName(config.get("region_id", REGION_GRAYTAIL_EDGE)),
		"seed_policy": StringName(config.get("seed_policy", SEED_POLICY_DEFER)),
		"selected_difficulty": StringName(config.get("selected_difficulty", config.get("difficulty", DIFFICULTY_NORMAL))),
		"selected_permits": _array_copy(config.get("selected_permits", [])),
		"selected_services": _array_copy(config.get("selected_services", [])),
		"selected_objective_id": StringName(config.get("selected_objective_id", &"objective_recover_cache")),
		"selected_objective_label": String(config.get("selected_objective_label", "回收补给箱")),
		"selected_objective_summary": String(config.get("selected_objective_summary", "")),
		"initial_bag_summary": _dictionary_copy(config.get("initial_bag_summary", {})),
		"initial_risk_summary": _dictionary_copy(config.get("initial_risk_summary", config.get("risk_summary", {}))),
		"initial_effect_summary": _dictionary_copy(config.get("initial_effect_summary", config.get("effect_summary", {}))),
		"asset_attendance_preview": _dictionary_copy(config.get("asset_attendance_preview", {})),
		"run_origin": StringName(config.get("run_origin", RUN_ORIGIN_PREVIEW)),
	}


static func _asset_attendance_preview() -> Dictionary:
	return {
		"label": "出发探索资产出勤视角",
		"primary_tabs": ["地图", "仓库", "申领", "目标", "出勤配置"],
		"draft_actions": ["加入出勤", "移出出勤", "穿戴", "卸下", "领取", "购买", "回收 / 出售", "购买并加入出勤", "选择目标"],
		"permission_note": "作业许可降级为后续接口 / locked state，不再作为当前一级页签。",
		"display_only": true,
		"read_only": true,
	}


static func _warehouse_attendance_preview() -> Dictionary:
	return {
		"label": "仓库出勤 preview",
		"main_item_types": ["装备", "消耗品", "藏品", "特殊物"],
		"metadata_only": ["唯一", "外观", "抽奖物", "任务物", "委托物", "样本", "未判断价值", "图鉴条目", "研究解锁"],
		"consumable_note": "本局携带消耗品将在本局结束后默认清空。",
		"allowed_draft_actions": ["加入出勤", "移出出勤", "穿戴", "卸下", "出售 preview", "查看详情", "只读跳转"],
		"blocked_actions": ["真实出售", "批量整理", "真实仓库写入"],
		"display_only": true,
		"read_only": true,
	}


static func _claim_preview() -> Dictionary:
	return {
		"label": "申领 catalog-first preview",
		"groups": ["可购买", "可领取", "可回收", "未解锁", "推荐"],
		"preview_actions": ["领取", "购买", "回收 / 出售 preview", "购买并加入出勤"],
		"cost_labels": ["金币", "凭证", "回收目录", "解锁条件"],
		"blocked_actions": ["真实扣费", "奖励领取", "资源发放", "资产入仓", "领取记录写入"],
		"display_only": true,
		"read_only": true,
	}


static func _objective_preview() -> Dictionary:
	return {
		"selected_id": &"objective_recover_cache",
		"selected_label": "回收补给箱",
		"objective_type": &"recovery",
		"available_count": 2,
		"max_select_count": 1,
		"map_match": "灰尾外围 / 常规扫雷可用",
		"difficulty_match": "普通可用",
		"required_asset_tags": ["探测类消耗品推荐"],
		"completion_conditions": ["带回目标记录物", "成功撤离或满足结算记录条件"],
		"failure_conditions": ["未带回目标记录物", "放弃 / 中止时目标一般视为失败或未完成"],
		"reward_type_summary": ["资源引用", "藏品引用", "历史记录引用"],
		"blocked_actions": ["runtime progress", "reward grant", "long-term objective write"],
		"display_only": true,
		"read_only": true,
		"preview": true,
	}


static func _loadout_preview() -> Dictionary:
	return {
		"equipped": ["野外短刀", "补丁防护背心"],
		"carried_consumables": ["简易急救包 x2", "照明棒组 x1"],
		"carried_specials": ["委托标记物"],
		"selected_objective": "回收补给箱",
		"purchased_not_carried": ["应急口粮"],
		"configured_item_count": 4,
		"bag_summary": "背包容量 3 / 12",
		"preset_note": "预设、清空、重置只保留 preview 口径。",
		"consumable_note": "本局携带消耗品将在本局结束后默认清空。",
		"display_only": true,
		"read_only": true,
	}


static func _permission_interface_preview() -> Dictionary:
	return {
		"state_label": "作业许可 / 保险 / 托运为后续接口 locked state",
		"hidden_primary_tab": true,
		"locked_interfaces": ["required_permission", "unlock_condition", "future_permission_hook", "protection_policy", "settlement_policy", "rescue_policy"],
		"not_current_features": [
			"许可槽",
			"许可容量",
			"许可主动启用",
			"许可消耗",
			"许可互斥",
		],
		"display_only": true,
		"read_only": true,
		"preview": true,
	}


static func _backpack_capacity_preview() -> Dictionary:
	return {
		"used": 3,
		"limit": 12,
		"label": "背包容量 3 / 12",
		"capacity_scope": "本次出勤携带物；仓库库存本身不占出勤背包容量。",
		"purchased_not_carried_note": "购买或领取但未加入出勤的物品进入仓库 preview，不进入本局启动配置。",
		"display_only": true,
		"read_only": true,
		"preview": true,
	}


static func _config_validity_preview() -> Dictionary:
	return {
		"label": "可开始 preview / 未接真实 RunBootstrapper",
		"checks": [
			"地图已选择",
			"难度已选择",
			"目标可用",
			"背包容量未超限",
			"未发现不可出勤物",
			"未接真实资源检查",
		],
		"can_start_preview": true,
		"blocked_real_actions": ["RunBootstrapper", "active_run_persistence", "settlement"],
		"display_only": true,
		"read_only": true,
		"preview": true,
	}


static func _action_intent_boundaries_preview() -> Dictionary:
	return {
		"start_intent": "只生成 DeployConfig / RunStartConfig preview，不启动真实探索。",
		"continue_intent": "仅按 active_run_preview 显示继续状态，不恢复真实探索。",
		"abandon_intent": "显示强确认 preview，不执行真实放弃或结算。",
		"requires_confirm": ["abandon"],
		"blocked_actions": ["real_start", "real_continue", "real_abandon", "run_bootstrapper", "active_run_persistence"],
		"display_only": true,
		"read_only": true,
		"preview": true,
	}


static func _long_term_asset_interface_preview() -> Dictionary:
	return {
		"title": "G30 LongTerm asset interface consumer preview",
		"reward_bundle_preview": AssetDomainContractScript.default_reward_bundle_preview("deploy_prep.objective.reward_bundle.preview", &"deploy_prep"),
		"red_dot_policy": AssetDomainContractScript.default_red_dot_policy(&"deploy_prep.objective.red_dot_policy"),
		"jump_targets": [
			AssetDomainContractScript.default_jump_target(&"long_term_goals", "LongTerm goals preview"),
			AssetDomainContractScript.default_jump_target(&"warehouse", "Warehouse asset reference preview"),
		],
		"boundary": "DeployPrep reads objective/reward/asset interface preview only; it does not write objective progress, rewards, or assets.",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"preview_only": true,
		"no_persistence": true,
		"no_asset_write": true,
		"no_reward_grant": true,
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
