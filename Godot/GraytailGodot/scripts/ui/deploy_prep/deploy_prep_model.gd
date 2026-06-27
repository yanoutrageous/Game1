extends RefCounted
class_name DeployPrepModel

const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const DeployTabModelScript := preload("res://scripts/ui/deploy_prep/deploy_tab_model.gd")


static func build(snapshot: Dictionary = {}) -> Dictionary:
	var run_active := bool(snapshot.get("run_active", snapshot.get("has_active_run", false)))
	var config := DeployConfigScript.with_active_run_preview(DeployConfigScript.default_config(), run_active)
	var active_tab := DeployTabModelScript.DEFAULT_TAB
	var selected_filter := DeployTabModelScript.default_filter_for(active_tab)
	var selected_card := DeployTabModelScript.default_card_for(active_tab)
	return _build_model(config, run_active, active_tab, selected_filter, selected_card, false, "")


static func model_with_tab(model: Dictionary, tab_id: StringName) -> Dictionary:
	var config := _config_from(model)
	var run_active := _has_active_run(config)
	var selected_filter := DeployTabModelScript.default_filter_for(tab_id)
	var selected_card := DeployTabModelScript.default_card_for(tab_id)
	return _build_model(config, run_active, tab_id, selected_filter, selected_card, false, "")


static func model_with_filter(model: Dictionary, filter_id: StringName) -> Dictionary:
	var config := _config_from(model)
	var run_active := _has_active_run(config)
	var active_tab := StringName(model.get("active_tab", DeployTabModelScript.DEFAULT_TAB))
	var cards := DeployTabModelScript.filter_cards(active_tab, filter_id)
	var selected_card := &""
	if not cards.is_empty():
		selected_card = StringName((cards[0] as Dictionary).get("id", &""))
	return _build_model(config, run_active, active_tab, filter_id, selected_card, false, "")


static func model_with_card(model: Dictionary, card_id: StringName) -> Dictionary:
	var config := _config_from(model)
	var run_active := _has_active_run(config)
	var active_tab := StringName(model.get("active_tab", DeployTabModelScript.DEFAULT_TAB))
	var selected_filter := StringName(model.get("selected_filter", DeployTabModelScript.default_filter_for(active_tab)))
	return _build_model(config, run_active, active_tab, selected_filter, card_id, false, "")


static func model_with_action_message(model: Dictionary, message: String, confirm_visible: bool = false) -> Dictionary:
	var result := model.duplicate(true)
	result["action_message"] = message
	result["abandon_confirm_visible"] = confirm_visible
	return result


static func _build_model(
	config: Dictionary,
	run_active: bool,
	active_tab: StringName,
	selected_filter: StringName,
	selected_card: StringName,
	confirm_visible: bool,
	action_message: String
) -> Dictionary:
	var tab := DeployTabModelScript.find_tab(active_tab)
	var cards := DeployTabModelScript.filter_cards(active_tab, selected_filter)
	if cards.is_empty() and selected_filter != DeployTabModelScript.FILTER_ALL:
		cards = DeployTabModelScript.filter_cards(active_tab, DeployTabModelScript.FILTER_ALL)
	var selected_detail := DeployTabModelScript.find_card(active_tab, selected_card)
	if selected_detail.is_empty() and not cards.is_empty():
		selected_detail = (cards[0] as Dictionary).duplicate(true)
		selected_card = StringName(selected_detail.get("id", &""))
	var preview := DeployConfigScript.build_preview_lines(config)
	return {
		"title": "出发探索",
		"subtitle": "修正案 v0.2 / 地图、仓库、申领、目标、出勤配置 / preview",
		"boundary": "G29-R2 落地出发探索修正案 v0.2 的页面结构、内容模型、状态汇总和交互边界；作业许可降级为后续接口，不实现真实仓库、资产写入、扣费、结算、RunBootstrapper 或完整 RunFlow。",
		"tabs": DeployTabModelScript.build_tabs(),
		"active_tab": active_tab,
		"selected_filter": selected_filter,
		"selected_card": selected_card,
		"active_tab_data": tab,
		"visible_cards": cards,
		"selected_card_detail": selected_detail,
		"config": config,
		"run_start_config": DeployConfigScript.build_run_start_config(config),
		"local_draft_preview": _local_draft_preview(config),
		"run_flow_route_preview": _run_flow_route_preview(config, run_active),
		"asset_domain_preview": {
			"deploy_asset_view_preview": (config.get("deploy_asset_view_preview", {}) as Dictionary).duplicate(true),
			"warehouse_view_snapshot": (config.get("warehouse_view_snapshot", {}) as Dictionary).duplicate(true),
			"warehouse_view_content_snapshot": (config.get("warehouse_view_content_snapshot", {}) as Dictionary).duplicate(true),
			"long_term_asset_interface_preview": (config.get("long_term_asset_interface_preview", {}) as Dictionary).duplicate(true),
			"objective_preview": (config.get("objective_preview", {}) as Dictionary).duplicate(true),
			"config_validity_preview": (config.get("config_validity_preview", {}) as Dictionary).duplicate(true),
			"action_intent_boundaries": (config.get("action_intent_boundaries", {}) as Dictionary).duplicate(true),
			"summary": "G27/G28 AssetDescriptor / WarehouseViewSnapshot / ItemAssetContentPreview / WarehouseViewContentSnapshot are display sources only and do not write assets.",
			"read_only": true,
			"display_only": true,
			"preview": true,
		},
		"preview_lines": preview,
		"abandon_confirm_visible": confirm_visible,
		"action_message": action_message,
		"actions": _actions(run_active),
		"preview": true,
		"display_only": true,
		"read_only": true,
	}


static func _local_draft_preview(config: Dictionary) -> Dictionary:
	return {
		"map": {
			"summary": String(config.get("selected_map_summary", "")),
			"map_mode": String(config.get("map_mode_label", "常规扫雷")),
			"difficulty": String(config.get("difficulty_label", "普通")),
			"region": String(config.get("region_label", "灰尾外围")),
		},
		"warehouse": (config.get("warehouse_attendance_preview", {}) as Dictionary).duplicate(true),
		"claim": (config.get("claim_preview", {}) as Dictionary).duplicate(true),
		"objective": (config.get("objective_preview", {}) as Dictionary).duplicate(true),
		"loadout": (config.get("loadout_preview", {}) as Dictionary).duplicate(true),
		"backpack_capacity": (config.get("backpack_capacity_preview", {}) as Dictionary).duplicate(true),
		"validity": (config.get("config_validity_preview", {}) as Dictionary).duplicate(true),
		"permission_interface": (config.get("permission_interface_preview", {}) as Dictionary).duplicate(true),
		"linkage_note": "地图、仓库、申领、目标、出勤配置共享同一个 local draft preview；不会写真实仓库、目标进度或 RunStartConfig 锁定状态。",
		"preview": true,
		"display_only": true,
		"read_only": true,
	}


static func _run_flow_route_preview(config: Dictionary, run_active: bool) -> Dictionary:
	return {
		"schema_kind": &"RunIntent",
		"start_bridge": {
			"target_route": &"run",
			"route_mode": &"standard_run",
			"entry_id": &"deploy_prep_start_bridge",
			"deploy_config_bridge": true,
			"uses_existing_route": true,
			"does_not_create_run_bootstrapper": true,
			"config_ref": String(DeployConfigScript.build_run_start_config(config).get("config_id", "")),
		},
		"continue": {
			"disabled": not run_active,
			"disabled_reason": &"" if run_active else &"no_active_run_persistence",
			"preview": true,
		},
		"abandon": {
			"disabled": true,
			"disabled_reason": &"settlement_runtime_not_connected",
			"strong_confirm_required": run_active,
			"preview": true,
		},
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _actions(run_active: bool) -> Dictionary:
	return {
		"start": {
			"label": "开始探索",
			"tooltip": "Build DeployConfig / RunStartConfig and route into the existing standard_10x10 playable run; full deploy bootstrap remains future work.",
			"disabled": run_active,
			"run_intent": {
				"target_route": &"run",
				"route_mode": &"standard_run",
				"entry_id": &"deploy_prep_start_bridge",
				"deploy_config_bridge": true,
				"uses_existing_route": true,
			},
			"preview": true,
			"display_only": true,
			"read_only": true,
		},
		"continue": {
			"label": "继续探索 preview",
			"tooltip": "继续入口只保留 read_only preview；真实继续流程后置。",
			"disabled": not run_active,
			"has_active_run": run_active,
			"disabled_reason": &"" if run_active else &"no_active_run_persistence",
			"preview": true,
			"display_only": true,
			"read_only": true,
		},
		"abandon": {
			"label": "放弃探索 preview",
			"tooltip": "放弃必须强确认；本页只显示强确认 preview，不执行放弃。",
			"disabled": not run_active,
			"requires_confirm": run_active,
			"disabled_reason": &"settlement_runtime_not_connected",
			"confirm_copy": "强确认 preview：放弃当前探索会在真实系统中损失本局状态，但本轮不执行。",
			"preview": true,
			"display_only": true,
			"read_only": true,
		},
	}


static func _config_from(model: Dictionary) -> Dictionary:
	var raw: Variant = model.get("config", {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return DeployConfigScript.default_config()


static func _has_active_run(config: Dictionary) -> bool:
	var active_run: Variant = config.get("active_run_preview", {})
	if active_run is Dictionary:
		return bool((active_run as Dictionary).get("has_active_run", false))
	return false
