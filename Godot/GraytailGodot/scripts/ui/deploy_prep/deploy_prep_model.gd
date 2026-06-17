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
		"subtitle": "本局准备中心 / 五模块内容 preview / display_only",
		"boundary": "G22-R2 只补全地图、仓库、申领、出勤配置、作业许可的内容 preview；不实现完整出发探索、真实仓库、真实资产写入、真实扣费、真实探索执行或真实记录。",
		"tabs": DeployTabModelScript.build_tabs(),
		"active_tab": active_tab,
		"selected_filter": selected_filter,
		"selected_card": selected_card,
		"active_tab_data": tab,
		"visible_cards": cards,
		"selected_card_detail": selected_detail,
		"config": config,
		"run_start_config": DeployConfigScript.build_run_start_config(config),
		"preview_lines": preview,
		"abandon_confirm_visible": confirm_visible,
		"action_message": action_message,
		"actions": _actions(run_active),
		"preview": true,
		"display_only": true,
		"read_only": true,
	}


static func _actions(run_active: bool) -> Dictionary:
	return {
		"start": {
			"label": "开始探索 preview",
			"tooltip": "只刷新 DeployConfig / RunStartConfig preview；完整出发配置启动未接入。当前可玩探索请从主菜单快速开始进入。",
			"disabled": run_active,
			"preview": true,
			"display_only": true,
			"read_only": true,
		},
		"continue": {
			"label": "继续探索 preview",
			"tooltip": "继续入口只保留 read_only preview；真实继续流程后置。",
			"disabled": not run_active,
			"has_active_run": run_active,
			"preview": true,
			"display_only": true,
			"read_only": true,
		},
		"abandon": {
			"label": "放弃探索 preview",
			"tooltip": "放弃必须强确认；本页只显示强确认 preview，不执行放弃。",
			"disabled": not run_active,
			"requires_confirm": run_active,
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
