extends RefCounted
class_name LongTermModuleProjection


const MODULE_WORKSPACE := {
	&"task_archive": {
		"kind": &"task_archive",
		"list_label": "档案条目",
		"detail_label": "进度与奖励",
		"empty_title": "暂无档案记录",
		"empty_description": "当前分类尚未登记任务、成就或委托结果。",
	},
	&"codex": {
		"kind": &"codex_index",
		"list_label": "图鉴索引",
		"detail_label": "发现详情",
		"empty_title": "暂无图鉴条目",
		"empty_description": "当前分类没有可展示的已登记或未知条目。",
	},
	&"research": {
		"kind": &"research_chain",
		"list_label": "研究解锁树",
		"detail_label": "节点条件与效果",
		"empty_title": "暂无研究课题",
		"empty_description": "当前研究分类没有已定义的课题。",
	},
	&"talent": {
		"kind": &"talent_tree",
		"list_label": "三分支天赋树",
		"detail_label": "前置、成本与新局效果",
		"empty_title": "暂无天赋节点",
		"empty_description": "权威天赋目录当前没有可展示的节点。",
	},
	&"profile": {
		"kind": &"profile_archive",
		"list_label": "资历记录",
		"detail_label": "角色档案事实",
		"empty_title": "暂无资历记录",
		"empty_description": "完成探索或达到资历阈值后，这里会登记真实记录。",
	},
	&"collection_appearance": {
		"kind": &"collection_archive",
		"list_label": "收藏索引",
		"detail_label": "永久记录",
		"empty_title": "暂无收藏记录",
		"empty_description": "当前分类没有可展示的永久收藏记录。",
	},
}

const GROUP_EMPTY_COPY := {
	"task_archive/task": ["暂无任务", "当前没有可展示的任务定义或进度记录。"],
	"task_archive/achievement": ["暂无成就", "当前没有可展示的成就定义或进度记录。"],
	"task_archive/commission_record": ["暂无委托记录", "完成探索后，真实委托结果会在这里登记。"],
	"profile/history": ["暂无探索历史", "完成一局并提交结算后，历史记录会在这里登记。"],
	"profile/title": ["暂无已获称号", "达到对应资历阈值后，称号会永久登记。"],
	"profile/badge": ["暂无已获徽章", "达到对应资历阈值后，徽章会永久登记。"],
	"collection_appearance/appearance_config": ["尚无可配置外观", "目前没有可配置的角色外观；已登记的收藏仍可在收藏档案查看。"],
	"collection_appearance/badge_title": ["暂无资历展示", "已获得的称号与徽章会在这里汇总展示。"],
	"collection_appearance/settlement_display": ["暂无结算档案", "完成一局并提交结算后，可在这里回看对应记录。"],
	"talent/tree": ["暂无天赋节点", "权威天赋目录当前没有可展示的节点。"],
}


static func build(
	module_id: StringName,
	group: Dictionary,
	model: Dictionary,
	page_summary: String = ""
) -> Dictionary:
	var safe_module_id := module_id if MODULE_WORKSPACE.has(module_id) else &"task_archive"
	var group_id := StringName(group.get("group_id", group.get("id", &"")))
	var group_key := "%s/%s" % [String(safe_module_id), String(group_id)]
	var workspace: Dictionary = (MODULE_WORKSPACE[safe_module_id] as Dictionary).duplicate(true)
	var records: Array[Dictionary] = []
	var cards_by_group: Dictionary = model.get("m7_cards_by_group", {})
	for raw_card in cards_by_group.get(group_key, []):
		if raw_card is Dictionary:
			records.append((raw_card as Dictionary).duplicate(true))
	var display_cards := records.duplicate(true)
	if display_cards.is_empty():
		display_cards.append(_empty_card(group_key, workspace))
	workspace.merge({
		"module_id": safe_module_id,
		"group_id": group_id,
		"group_key": group_key,
		"group_title": str(group.get("title", "档案")),
		"summary": page_summary,
		"records": records,
		"display_cards": display_cards,
		"record_count": records.size(),
		"empty": records.is_empty(),
		"read_only_selection": true,
		"explicit_action_only": true,
	}, true)
	if group_key == "research/unlock_interface":
		workspace["kind"] = &"research_unlock_tree"
		workspace["list_label"] = "研究解锁树"
		workspace["detail_label"] = "节点条件与效果"
		workspace["tree_contract"] = (model.get("research_tree_contract", {}) as Dictionary).duplicate(true)
	elif group_key == "talent/tree":
		workspace["kind"] = &"talent_unlock_tree"
		workspace["list_label"] = "三分支天赋树"
		workspace["detail_label"] = "前置、成本与新局效果"
		workspace["tree_contract"] = (model.get("talent_tree_contract", {}) as Dictionary).duplicate(true)
	return workspace


static func _empty_card(group_key: String, workspace: Dictionary) -> Dictionary:
	var title := str(workspace.get("empty_title", "暂无记录"))
	var description := str(workspace.get("empty_description", "当前分类没有可展示记录。"))
	if GROUP_EMPTY_COPY.has(group_key):
		var copy: Array = GROUP_EMPTY_COPY[group_key]
		title = str(copy[0])
		description = str(copy[1])
	return {
		"id": "empty:%s" % group_key,
		"title": title,
		"state": "暂无记录",
		"description": description,
		"facts": ["记录数：0"],
		"empty_state": true,
		"read_only": true,
	}
