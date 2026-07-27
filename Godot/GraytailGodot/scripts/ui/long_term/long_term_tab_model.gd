extends RefCounted
class_name LongTermTabModel

const LongTermContentFrameworkScript := preload("res://scripts/ui/long_term/long_term_content_framework.gd")

const STATE_PREVIEW := &"preview"
const STATE_DISABLED := &"disabled"
const STATE_AVAILABLE := &"available"
const STATE_ARCHIVE := &"archive"


static func build_modules() -> Array:
	return [
		_module(
			&"task_archive",
			"任务档案",
			"任务 / 成就 / 委托记录",
			STATE_PREVIEW,
			"读取现有任务、成就与委托记录，不重算进度或奖励。",
			{
				"module": "task_archive",
				"state": "preview",
				"message": "任务、成就与委托记录共用任务档案入口。",
			},
			[
				_group("任务", ["任务列表位置", "任务进度摘要位置", "任务筛选位置"]),
				_group("成就", ["成就分类位置", "完成条件说明位置", "展示奖励说明位置"]),
				_group("委托记录", ["委托历史入口", "委托状态摘要", "后续记录筛选"]),
			],
			{
				"label": "任务档案关联入口",
				"message": "任务、成就或委托记录可切换到对应档案页。",
			},
			"进度、领取与奖励发放继续由现有局外进度事务负责。"
		),
		_module(
			&"codex",
			"图鉴",
			"怪物、区域、事件和收集线索的展示入口",
			STATE_PREVIEW,
			"当前仅展示图鉴入口，不读取或生成图鉴数据。",
			{
				"module": "codex",
				"state": "preview",
				"message": "图鉴只作为导航和字段预留。",
			},
			[
				_group("图鉴分类", ["怪物条目位置", "区域条目位置", "事件条目位置"]),
				_group("发现摘要", ["发现数量位置", "未知条目提示", "后续筛选入口"]),
			],
			{
				"label": "图鉴链接",
				"message": "只显示未来跳转说明，不打开图鉴本体。",
			},
			"后续阶段再接入发现规则和条目详情。"
		),
		_module(
			&"research",
			"研究解锁",
			"沿现有前置关系逐项开放研究内容",
			STATE_AVAILABLE,
			"读取现有研究链、前置、消耗、效果与完成状态；只有条件满足的课题可显式确认。",
			{
				"module": "research",
				"state": "available",
				"message": "选择节点只更新详情；确认研究后才会提交资源消耗。",
			},
			[
				_group("研究解锁树", ["课题节点", "前置关系", "资源与效果"]),
			],
			{
				"label": "解锁关系",
				"message": "解锁树与课题档案读取同一组研究记录。",
			},
			"研究条件与效果以基地档案中的现有课题记录为准。"
		),
		_module(
			&"talent",
			"天赋",
			"在整备、安全与勘探三条两级分支中分配永久天赋点",
			STATE_AVAILABLE,
			"每次资历升级获得 1 点；节点只改变确认出发后生成的新一局配置。",
			{
				"module": "talent",
				"state": "available",
				"message": "选择节点只查看前置、成本与精确效果；明确确认后才会保存解锁。",
			},
			[
				_group("天赋树", ["整备分支", "安全分支", "勘探分支"]),
			],
			{
				"label": "新局效果",
				"message": "已解锁效果只通过 RunStartConfig 进入之后确认出发的新一局。",
			},
			"天赋目录只包含已有真实运行时消费者的六个节点。"
		),
		_module(
			&"profile",
			"个人资历",
			"角色等级、探索履历、统计、里程碑、称号和徽章",
			STATE_ARCHIVE,
			"读取已保存的角色成长与探索结算；浏览档案不会修改进度。",
			{
				"module": "profile",
				"state": "archive",
				"message": "角色档案读取真实资历、统计和最近五十次探索记录。",
			},
			[
				_group("资历等级", ["当前等级", "累计经验", "下一资历阈值"]),
				_group("历史战绩", ["失败原因", "携入物资", "保全与损失"]),
				_group("数据统计", ["探索次数", "撤离率", "长期金币"]),
				_group("里程碑", ["等级门槛", "距离下一阶段", "永久登记"]),
				_group("称号 / 徽章", ["已获称号", "已获徽章", "获得来源"]),
			],
			{
				"label": "角色档案",
				"message": "探索结算成功写入后，可在历史战绩中回看本局事实。",
			},
			"外观装备仍需独立的拥有与应用事务；角色档案本身已经读取真实保存数据。"
		),
		_module(
			&"collection_appearance",
			"收藏 / 外观",
			"收藏品、外观库和展示配置入口",
			STATE_PREVIEW,
			"当前仅展示收藏与外观结构，不装备外观，不读取收藏数据。",
			{
				"module": "collection_appearance",
				"state": "preview",
				"message": "收藏与外观只作为 display-only 入口预览。",
			},
			[
				_group("收藏", ["收藏品分类位置", "获得来源说明", "展示墙入口"]),
				_group("外观", ["角色外观位置", "展示配置位置", "未解锁提示位置"]),
			],
			{
				"label": "收藏 / 外观链接",
				"message": "只显示未来跳转说明，不切换或应用外观。",
			},
			"后续阶段再接入收藏来源、外观库和展示配置。"
		),
	]


static func default_module_id() -> StringName:
	return &"task_archive"


static func normalize_module_id(module_id: StringName) -> StringName:
	match module_id:
		&"", &"overview", &"goals", &"tasks", &"task_archive":
			return &"task_archive"
		_:
			return module_id


static func find_module(modules: Array, module_id: StringName) -> Dictionary:
	var normalized_module_id := normalize_module_id(module_id)
	for module: Dictionary in modules:
		if StringName(module.get("id", &"")) == normalized_module_id:
			return module.duplicate(true)
	return (modules[0] as Dictionary).duplicate(true) if not modules.is_empty() else {}


static func module_summaries(modules: Array) -> Dictionary:
	var summaries := {}
	for module: Dictionary in modules:
		summaries[String(module.get("id", &""))] = (module.get("summary", {}) as Dictionary).duplicate(true)
	return summaries


static func _module(
	id: StringName,
	title: String,
	subtitle: String,
	state: StringName,
	reason: String,
	summary: Dictionary,
	child_preview_groups: Array,
	link_preview: Dictionary,
	next_stage_note: String
) -> Dictionary:
	var content_preview: Dictionary = LongTermContentFrameworkScript.find_module(id)
	var merged_summary := summary.duplicate(true)
	var interactive := state == STATE_AVAILABLE
	var landed := state in [STATE_AVAILABLE, STATE_ARCHIVE]
	merged_summary["content_framework_state"] = content_preview.get("preview_state", STATE_PREVIEW)
	merged_summary["content_card_count"] = (content_preview.get("cards", []) as Array).size()
	merged_summary["content_slot_count"] = (content_preview.get("event_slots_preview", []) as Array).size()
	return {
		"id": id,
		"title": title,
		"subtitle": subtitle,
		"description": subtitle,
		"state": state,
		"reason": reason,
		"summary": merged_summary,
		"child_preview_groups": child_preview_groups.duplicate(true),
		"link_preview": link_preview.duplicate(true),
		"next_stage_note": next_stage_note,
		"module_icon_key": content_preview.get("module_icon_key", ""),
		"module_banner_key": content_preview.get("module_banner_key", ""),
		"tab_icon_key": content_preview.get("tab_icon_key", ""),
		"description_key": content_preview.get("description_key", ""),
		"localization_key": content_preview.get("localization_key", ""),
		"ui_group_key": content_preview.get("ui_group_key", ""),
		"secondary_groups": (content_preview.get("secondary_groups", []) as Array).duplicate(true),
		"content_cards": (content_preview.get("cards", []) as Array).duplicate(true),
		"detail_preview": (content_preview.get("detail_preview", {}) as Dictionary).duplicate(true),
		"cross_links_preview": (content_preview.get("cross_links_preview", []) as Array).duplicate(true),
		"event_slots_preview": (content_preview.get("event_slots_preview", []) as Array).duplicate(true),
		"art_slots_preview": (content_preview.get("art_slots_preview", []) as Array).duplicate(true),
		"future_data_ref": content_preview.get("future_data_ref", ""),
		"data_source_ref": content_preview.get("data_source_ref", ""),
		"display_only": not interactive,
		"read_only": not interactive,
		"preview": not landed,
	}


static func _group(title: String, items: Array) -> Dictionary:
	return {
		"title": title,
		"items": items.duplicate(true),
	}
