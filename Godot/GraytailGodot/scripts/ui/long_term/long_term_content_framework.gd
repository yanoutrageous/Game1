extends RefCounted
class_name LongTermContentFramework

const LongTermContentSlotModelScript := preload("res://scripts/ui/long_term/long_term_content_slot_model.gd")

const STATE_PREVIEW := &"preview"
const STATE_DISABLED := &"disabled"


static func build_modules() -> Array:
	return [
		_module(
			&"goals",
			"目标",
			"目标模块保留任务、成就、委托记录三类内容入口。",
			STATE_PREVIEW,
			[
				_group("任务", ["日常任务 preview", "阶段任务 preview", "目标筛选 preview"], "long_term.goals.task.group_icon"),
				_group("成就", ["成就分类 preview", "达成条件 preview", "展示奖励 preview"], "long_term.goals.achievement.group_icon"),
				_group("委托记录", ["委托历史 preview", "委托状态 preview", "委托来源 preview"], "long_term.goals.commission.group_icon"),
			],
			[
				_card("goals_task_card", "任务 preview card", "只展示任务入口和目标摘要，不计算进度。", "任务", LongTermContentSlotModelScript.SLOT_OBJECTIVE),
				_card("goals_achievement_card", "成就 preview card", "只展示成就分类和后续奖励接口，不判断达成。", "成就", LongTermContentSlotModelScript.SLOT_REWARD_EVENT),
				_card("goals_commission_card", "委托记录 preview card", "只展示委托记录入口，不接取或结算委托。", "委托记录", LongTermContentSlotModelScript.SLOT_OBJECTIVE),
			],
			[
				_link("图鉴", "目标相关条目未来可跳转图鉴；当前只显示 cross-link preview。"),
				_link("个人资历", "目标完成后的资历展示后置；当前不写资历。"),
			]
		),
		_module(
			&"codex",
			"图鉴",
			"图鉴模块保留地图、怪物、藏品、装备、消耗品、事件、规则和世界观分类。",
			STATE_PREVIEW,
			[
				_group("地图", ["地图条目 preview", "区域线索 preview"], "long_term.codex.map.group_icon"),
				_group("怪物", ["怪物条目 preview", "遭遇来源 preview"], "long_term.codex.monster.group_icon"),
				_group("藏品", ["藏品条目 preview", "唯一藏品展示 preview"], "long_term.codex.collectible.group_icon"),
				_group("装备", ["装备记录 preview", "来源记录 preview"], "long_term.codex.equipment.group_icon"),
				_group("消耗品", ["消耗品记录 preview", "使用提示 preview"], "long_term.codex.consumable.group_icon"),
				_group("事件", ["事件条目 preview", "事件来源 preview"], "long_term.codex.event.group_icon"),
				_group("规则", ["规则说明 preview", "系统提示 preview"], "long_term.codex.rule.group_icon"),
				_group("世界观", ["背景条目 preview", "文本线索 preview"], "long_term.codex.lore.group_icon"),
			],
			[
				_card("codex_category_card", "图鉴分类 preview card", "只展示分类和条目位，不生成图鉴数据。", "图鉴", LongTermContentSlotModelScript.SLOT_CODEX_UNLOCK),
				_card("codex_unlock_card", "解锁来源 preview card", "只展示解锁来源字段，不写图鉴解锁。", "图鉴", LongTermContentSlotModelScript.SLOT_ASSET_EVENT),
			],
			[
				_link("研究", "研究节点未来可引用图鉴条目；当前不触发研究解锁。"),
				_link("收藏 / 外观", "收藏展示可引用图鉴条目；当前不打开收藏本体。"),
			]
		),
		_module(
			&"research",
			"研究",
			"研究模块保留功能解锁接口和研究入口 preview。",
			STATE_DISABLED,
			[
				_group("功能解锁接口", ["研究节点 preview", "条件字段 preview", "效果摘要 preview"], "long_term.research.unlock.group_icon"),
				_group("研究入口 preview", ["入口状态 preview", "资源提示 preview", "后续数据表 preview"], "long_term.research.entry.group_icon"),
			],
			[
				_card("research_node_card", "研究节点 preview card", "只展示研究节点外壳，不解锁、不消耗。", "研究", LongTermContentSlotModelScript.SLOT_RESEARCH_UNLOCK),
				_card("research_effect_card", "研究效果 preview card", "只展示效果文本位，不应用效果。", "研究", LongTermContentSlotModelScript.SLOT_RESEARCH_UNLOCK),
			],
			[
				_link("图鉴", "研究未来可依赖图鉴发现；当前只显示关系。"),
				_link("出发探索", "研究未来可影响出发配置；当前不改出发配置。"),
			]
		),
		_module(
			&"profile",
			"个人资历",
			"个人资历模块保留等级、历史战绩、统计、里程碑、称号和徽章。",
			STATE_PREVIEW,
			[
				_group("资历等级", ["等级摘要 preview", "经验来源 preview"], "long_term.profile.level.group_icon"),
				_group("历史战绩", ["历史战绩卡片 preview", "筛选入口 preview"], "long_term.profile.history.group_icon"),
				_group("数据统计", ["探索统计 preview", "收益统计 preview"], "long_term.profile.stat.group_icon"),
				_group("里程碑", ["里程碑列表 preview", "阶段提示 preview"], "long_term.profile.milestone.group_icon"),
				_group("称号", ["称号展示 preview", "称号来源 preview"], "long_term.profile.title.group_icon"),
				_group("徽章", ["徽章墙 preview", "徽章状态 preview"], "long_term.profile.badge.group_icon"),
			],
			[
				_card("profile_history_card", "历史战绩 preview card", "消费 G23 历史快照 preview，不写历史记录。", "个人资历", LongTermContentSlotModelScript.SLOT_HISTORY_RECORD),
				_card("profile_qualification_card", "资历变化 preview card", "只展示资历变化接口，不升级资历。", "个人资历", LongTermContentSlotModelScript.SLOT_QUALIFICATION),
				_card("profile_badge_card", "徽章称号 preview card", "只展示称号和徽章位置，不发放奖励。", "个人资历", LongTermContentSlotModelScript.SLOT_REWARD_EVENT),
			],
			[
				_link("结算历史", "历史战绩未来消费 settlement/history snapshot；当前 display-only。"),
				_link("目标", "目标达成未来可影响资历；当前不写目标或资历。"),
			]
		),
		_module(
			&"gacha",
			"抽奖",
			"抽奖模块保留奖池、消耗和结果入口 preview。",
			STATE_DISABLED,
			[
				_group("奖池", ["奖池主题 preview", "奖池状态 preview"], "long_term.gacha.pool.group_icon"),
				_group("消耗", ["票券需求 preview", "资源提示 preview"], "long_term.gacha.cost.group_icon"),
				_group("结果入口 preview", ["结果展示 preview", "历史入口 preview"], "long_term.gacha.result.group_icon"),
			],
			[
				_card("gacha_pool_card", "奖池 preview card", "只展示奖池主题，不计算概率。", "抽奖", LongTermContentSlotModelScript.SLOT_GACHA_POOL),
				_card("gacha_cost_card", "消耗 preview card", "只展示消耗字段，不扣资源。", "抽奖", LongTermContentSlotModelScript.SLOT_GACHA_COST),
				_card("gacha_result_card", "结果入口 preview card", "只展示结果入口，不生成结果。", "抽奖", LongTermContentSlotModelScript.SLOT_GACHA_RESULT),
			],
			[
				_link("奖励", "抽奖未来可产生奖励事件；当前不发放。"),
				_link("收藏 / 外观", "抽奖未来可关联收藏或外观；当前不写收藏。"),
			]
		),
		_module(
			&"collection_appearance",
			"收藏 / 外观",
			"收藏 / 外观模块保留唯一展示、外观配置、展示内容、徽章称号和结算展示。",
			STATE_PREVIEW,
			[
				_group("唯一展示", ["唯一藏品卡 preview", "特殊展示位 preview"], "long_term.collection.unique.group_icon"),
				_group("外观配置", ["外观库 preview", "装备状态 preview"], "long_term.collection.cosmetic.group_icon"),
				_group("展示内容", ["展示墙 preview", "展示排序 preview"], "long_term.collection.display.group_icon"),
				_group("徽章称号", ["徽章称号展示 preview", "来源说明 preview"], "long_term.collection.badge_title.group_icon"),
				_group("结算展示", ["结算卡面 preview", "历史引用 preview"], "long_term.collection.settlement.group_icon"),
			],
			[
				_card("collection_unique_card", "唯一展示 preview card", "只展示唯一藏品槽位，不获得藏品。", "收藏 / 外观", LongTermContentSlotModelScript.SLOT_UNIQUE_COLLECTIBLE),
				_card("collection_cosmetic_card", "外观配置 preview card", "只展示外观配置入口，不应用外观。", "收藏 / 外观", LongTermContentSlotModelScript.SLOT_COSMETIC),
				_card("collection_display_card", "展示内容 preview card", "只展示展示位和卡面 key，不写收藏。", "收藏 / 外观", LongTermContentSlotModelScript.SLOT_COLLECTION_DISPLAY),
			],
			[
				_link("图鉴", "收藏条目未来可回链图鉴；当前只显示说明。"),
				_link("个人资历", "徽章称号未来可关联资历；当前不写资历。"),
			]
		),
	]


static func default_module_id() -> StringName:
	return &"goals"


static func find_module(module_id: StringName) -> Dictionary:
	for module: Dictionary in build_modules():
		if StringName(module.get("module_id", &"")) == module_id:
			return module.duplicate(true)
	return build_modules()[0].duplicate(true)


static func module_summaries(modules: Array = []) -> Dictionary:
	var source := modules if not modules.is_empty() else build_modules()
	var summaries := {}
	for module: Dictionary in source:
		summaries[String(module.get("module_id", &""))] = {
			"display_name": module.get("display_name", ""),
			"preview_state": module.get("preview_state", STATE_PREVIEW),
			"secondary_group_count": (module.get("secondary_groups", []) as Array).size(),
			"card_count": (module.get("cards", []) as Array).size(),
			"slot_count": (module.get("event_slots_preview", []) as Array).size(),
			"read_only": true,
			"display_only": true,
			"preview": true,
		}
	return summaries


static func _module(
	module_id: StringName,
	display_name: String,
	description: String,
	preview_state: StringName,
	secondary_groups: Array,
	cards: Array,
	cross_links: Array
) -> Dictionary:
	var id_text := String(module_id)
	var event_slots := LongTermContentSlotModelScript.build_slots_for_module(module_id)
	return {
		"module_id": module_id,
		"id": module_id,
		"display_name": display_name,
		"title": display_name,
		"description": description,
		"module_icon_key": "long_term.%s.module_icon" % id_text,
		"module_banner_key": "long_term.%s.module_banner" % id_text,
		"tab_icon_key": "long_term.%s.tab_icon" % id_text,
		"description_key": "ui.long_term.%s.description" % id_text,
		"localization_key": "ui.long_term.%s.title" % id_text,
		"ui_group_key": "long_term.module.%s" % id_text,
		"preview_state": preview_state,
		"state": preview_state,
		"display_only": true,
		"read_only": true,
		"preview": true,
		"secondary_groups": secondary_groups.duplicate(true),
		"cards": cards.duplicate(true),
		"detail_preview": {
			"title": "%s detail preview" % display_name,
			"message": "G24 只提供内容框架、卡片和 slot 预留，不实现真实系统。",
			"read_only": true,
			"display_only": true,
			"preview": true,
		},
		"cross_links_preview": cross_links.duplicate(true),
		"event_slots_preview": event_slots.duplicate(true),
		"art_slots_preview": _art_slots(module_id),
		"ui_art_data_keys": _ui_art_data_keys(module_id),
		"future_data_ref": "future.long_term.%s.content_framework" % id_text,
		"data_source_ref": "preview.long_term.%s.content_framework" % id_text,
	}


static func _group(title: String, items: Array, group_icon_key: String) -> Dictionary:
	var item_entries := []
	for item in items:
		item_entries.append({
			"title": String(item),
			"card_icon_key": "%s.item_icon" % group_icon_key,
			"read_only": true,
			"display_only": true,
			"preview": true,
		})
	return {
		"title": title,
		"group_icon_key": group_icon_key,
		"ui_group_key": "long_term.group.%s" % group_icon_key,
		"items": item_entries,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _card(card_id: String, title: String, description: String, group_title: String, preview_slot: StringName) -> Dictionary:
	return {
		"card_id": card_id,
		"title": title,
		"description": description,
		"group_title": group_title,
		"preview_slot": preview_slot,
		"card_icon_key": "long_term.%s.card_icon" % card_id,
		"reward_icon_key": "long_term.%s.reward_icon" % card_id,
		"rarity_frame_key": "long_term.%s.rarity_frame" % card_id,
		"badge_icon_key": "long_term.%s.badge_icon" % card_id,
		"title_icon_key": "long_term.%s.title_icon" % card_id,
		"art_placeholder_id": "placeholder.%s" % card_id,
		"localization_key": "ui.long_term.card.%s.title" % card_id,
		"description_key": "ui.long_term.card.%s.description" % card_id,
		"future_data_ref": "future.long_term.card.%s" % card_id,
		"data_source_ref": "preview.long_term.card.%s" % card_id,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _link(target: String, message: String) -> Dictionary:
	return {
		"target": target,
		"message": message,
		"state": STATE_PREVIEW,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _art_slots(module_id: StringName) -> Array:
	var id_text := String(module_id)
	return [
		_art_slot("module_icon", "模块 icon", "long_term.%s.module_icon" % id_text),
		_art_slot("module_banner", "模块 banner", "long_term.%s.module_banner" % id_text),
		_art_slot("card_frame", "卡片边框", "long_term.%s.card_frame" % id_text),
		_art_slot("state_badge", "状态标记", "long_term.%s.state_badge" % id_text),
		_art_slot("empty_state", "空状态图", "long_term.%s.empty_state" % id_text),
	]


static func _art_slot(slot_id: String, display_name: String, key: String) -> Dictionary:
	return {
		"slot_id": slot_id,
		"display_name": display_name,
		"art_key": key,
		"art_placeholder_id": "placeholder.%s" % key,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _ui_art_data_keys(module_id: StringName) -> Dictionary:
	var id_text := String(module_id)
	return {
		"module_icon_key": "long_term.%s.module_icon" % id_text,
		"tab_icon_key": "long_term.%s.tab_icon" % id_text,
		"group_icon_key": "long_term.%s.group_icon" % id_text,
		"card_icon_key": "long_term.%s.card_icon" % id_text,
		"reward_icon_key": "long_term.%s.reward_icon" % id_text,
		"rarity_frame_key": "long_term.%s.rarity_frame" % id_text,
		"badge_icon_key": "long_term.%s.badge_icon" % id_text,
		"title_icon_key": "long_term.%s.title_icon" % id_text,
		"gacha_pool_art_key": "long_term.%s.gacha_pool_art" % id_text,
		"gacha_ticket_icon_key": "long_term.%s.gacha_ticket_icon" % id_text,
		"collection_slot_art_key": "long_term.%s.collection_slot_art" % id_text,
		"codex_category_icon_key": "long_term.%s.codex_category_icon" % id_text,
		"research_node_icon_key": "long_term.%s.research_node_icon" % id_text,
		"profile_badge_icon_key": "long_term.%s.profile_badge_icon" % id_text,
		"history_card_icon_key": "long_term.%s.history_card_icon" % id_text,
		"art_placeholder_id": "placeholder.long_term.%s" % id_text,
		"localization_key": "ui.long_term.%s.title" % id_text,
		"description_key": "ui.long_term.%s.description" % id_text,
		"ui_group_key": "long_term.module.%s" % id_text,
		"future_data_ref": "future.long_term.%s" % id_text,
		"data_source_ref": "preview.long_term.%s" % id_text,
	}
