extends RefCounted
class_name LongTermContentFramework

const AssetDomainContractScript := preload("res://scripts/core/asset/asset_domain_contract.gd")
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
				_group(&"task", "任务", ["日常任务", "阶段任务", "目标筛选"], "long_term.goals.task.group_icon"),
				_group(&"achievement", "成就", ["成就分类", "达成条件", "展示奖励"], "long_term.goals.achievement.group_icon"),
				_group(&"commission_record", "委托记录", ["委托历史", "委托状态", "委托来源"], "long_term.goals.commission.group_icon"),
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
				_group(&"map", "地图", ["地图档案", "区域线索"], "long_term.codex.map.group_icon"),
				_group(&"monster", "怪物", ["怪物条目", "遭遇来源"], "long_term.codex.monster.group_icon"),
				_group(&"collectible", "藏品", ["藏品条目", "唯一藏品展示"], "long_term.codex.collectible.group_icon"),
				_group(&"equipment", "装备", ["装备记录", "来源记录"], "long_term.codex.equipment.group_icon"),
				_group(&"consumable", "消耗品", ["消耗品记录", "使用提示"], "long_term.codex.consumable.group_icon"),
				_group(&"event", "事件", ["事件条目", "事件来源"], "long_term.codex.event.group_icon"),
				_group(&"rule", "规则", ["规则说明", "系统提示"], "long_term.codex.rule.group_icon"),
				_group(&"lore", "世界观", ["背景条目", "文本线索"], "long_term.codex.lore.group_icon"),
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
				_group(&"unlock_interface", "功能解锁接口", ["研究节点", "条件字段", "效果摘要"], "long_term.research.unlock.group_icon"),
				_group(&"research_entry", "研究入口", ["入口状态", "资源提示", "后续数据表"], "long_term.research.entry.group_icon"),
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
				_group(&"qualification_level", "资历等级", ["等级摘要", "经验来源"], "long_term.profile.level.group_icon"),
				_group(&"history", "历史战绩", ["历史战绩卡片", "筛选入口"], "long_term.profile.history.group_icon"),
				_group(&"statistics", "数据统计", ["探索统计", "收益统计"], "long_term.profile.stat.group_icon"),
				_group(&"milestone", "里程碑", ["里程碑列表", "阶段提示"], "long_term.profile.milestone.group_icon"),
				_group(&"title", "称号", ["称号展示", "称号来源"], "long_term.profile.title.group_icon"),
				_group(&"badge", "徽章", ["徽章墙", "徽章状态"], "long_term.profile.badge.group_icon"),
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
				_group(&"pool", "奖池", ["奖池主题", "奖池状态"], "long_term.gacha.pool.group_icon"),
				_group(&"cost", "消耗", ["票券需求", "资源提示"], "long_term.gacha.cost.group_icon"),
				_group(&"result_entry", "结果入口", ["结果展示", "历史入口"], "long_term.gacha.result.group_icon"),
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
				_group(&"unique_display", "唯一展示", ["唯一藏品卡", "特殊展示位"], "long_term.collection.unique.group_icon"),
				_group(&"appearance_config", "外观配置", ["外观库", "装备状态"], "long_term.collection.cosmetic.group_icon"),
				_group(&"display_content", "展示内容", ["展示墙", "展示排序"], "long_term.collection.display.group_icon"),
				_group(&"badge_title", "徽章称号", ["徽章称号展示", "来源说明"], "long_term.collection.badge_title.group_icon"),
				_group(&"settlement_display", "结算展示", ["结算卡面", "历史引用"], "long_term.collection.settlement.group_icon"),
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
	var reward_bundle := AssetDomainContractScript.default_reward_bundle_preview("long_term.%s.reward_bundle.preview" % id_text, &"long_term")
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
		"preview_only": true,
		"no_persistence": true,
		"no_reward_grant": true,
		"no_asset_write": true,
		"module_scope": _module_scope(module_id),
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
		"event_flow_preview": _event_flow_preview(module_id),
		"reward_bundle_preview": reward_bundle,
		"red_dot_policy": AssetDomainContractScript.default_red_dot_policy(StringName("long_term.%s.red_dot_policy" % id_text)),
		"jump_targets": _jump_targets(module_id),
		"asset_interface_preview": _asset_interface_preview(module_id),
		"current_landable_scope": _current_landable_scope(module_id),
		"deferred_scope": _deferred_scope(module_id),
		"art_slots_preview": _art_slots(module_id),
		"ui_art_data_keys": _ui_art_data_keys(module_id),
		"future_data_ref": "future.long_term.%s.content_framework" % id_text,
		"data_source_ref": "preview.long_term.%s.content_framework" % id_text,
	}


static func _group(group_id: StringName, title: String, items: Array, group_icon_key: String) -> Dictionary:
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
		"group_id": group_id,
		"id": group_id,
		"title": title,
		"group_icon_key": group_icon_key,
		"ui_group_key": "long_term.group.%s" % group_icon_key,
		"items": item_entries,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _card(card_id: String, title: String, description: String, group_title: String, preview_slot: StringName) -> Dictionary:
	var card_ref := AssetDomainContractScript.default_asset_ref(card_id, AssetDomainContractScript.CATEGORY_RECORD_UNLOCK)
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
		"status_chips": ["preview_only", "display_only", "read_only"],
		"asset_refs": [card_ref],
		"reward_summary": "RewardBundle preview only; no reward grant.",
		"reward_bundle_preview": AssetDomainContractScript.default_reward_bundle_preview("long_term.card.%s.reward_bundle.preview" % card_id, &"long_term"),
		"red_dot_policy": AssetDomainContractScript.default_red_dot_policy(StringName("long_term.card.%s.red_dot_policy" % card_id)),
		"jump_targets": [
			AssetDomainContractScript.default_jump_target(&"warehouse", "Warehouse reference preview"),
			AssetDomainContractScript.default_jump_target(&"codex", "Codex reference preview"),
		],
		"read_only": true,
		"display_only": true,
		"preview": true,
		"preview_only": true,
		"no_persistence": true,
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


static func _module_scope(module_id: StringName) -> Dictionary:
	match module_id:
		&"goals":
			return _scope(["tasks", "achievements", "commission_records"], ["objective progress preview", "RewardBundle preview", "claim state preview"])
		&"codex":
			return _scope(["maps", "monsters", "items", "events", "rules", "lore"], ["discovery state preview", "asset reference preview"])
		&"research":
			return _scope(["research lines", "unlock entry preview"], ["research unlock preview", "requirement preview"])
		&"profile":
			return _scope(["profile level", "history records", "statistics", "milestones", "titles", "badges"], ["HistoryRecordEvent preview", "qualification preview"])
		&"gacha":
			return _scope(["pool descriptor", "cost descriptor", "result ownership preview"], ["pool preview", "RewardBundle preview"])
		&"collection_appearance":
			return _scope(["unique display", "appearance config intent", "badges", "settlement display"], ["asset display preview", "cosmetic unlock preview"])
		_:
			return _scope([], [])


static func _scope(responsibilities: Array, interfaces: Array) -> Dictionary:
	return {
		"responsibilities": responsibilities.duplicate(true),
		"interfaces": interfaces.duplicate(true),
		"boundary": "LongTerm content only; no real backend, no persistence, no asset mutation.",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"preview_only": true,
	}


static func _event_flow_preview(module_id: StringName) -> Dictionary:
	var id_text := String(module_id)
	return {
		"module_id": module_id,
		"events": [
			AssetDomainContractScript.default_resource_event_preview("long_term.%s.resource_event.preview" % id_text),
			AssetDomainContractScript.default_item_event_preview("long_term.%s.item_event.preview" % id_text),
			AssetDomainContractScript.default_unlock_event_preview("long_term.%s.unlock_event.preview" % id_text),
			AssetDomainContractScript.default_history_record_event_preview("long_term.%s.history_record_event.preview" % id_text),
			AssetDomainContractScript.default_objective_event_preview("long_term.%s.objective_event.preview" % id_text),
		],
		"summary": "ResourceEvent / ItemEvent / UnlockEvent / HistoryRecordEvent / ObjectiveEvent preview only.",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"preview_only": true,
	}


static func _asset_interface_preview(module_id: StringName) -> Dictionary:
	var id_text := String(module_id)
	return {
		"module_id": module_id,
		"asset_refs": [
			AssetDomainContractScript.default_asset_ref("%s_asset_reference_preview" % id_text, AssetDomainContractScript.CATEGORY_RECORD_UNLOCK),
		],
		"warehouse_relationship": "Warehouse remains independent; LongTerm stores references and jump intent only.",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"preview_only": true,
		"no_asset_write": true,
	}


static func _jump_targets(module_id: StringName) -> Array:
	match module_id:
		&"goals":
			return [
				AssetDomainContractScript.default_jump_target(&"deploy_prep", "Open DeployPrep objective selection preview"),
				AssetDomainContractScript.default_jump_target(&"warehouse", "Open reward asset reference preview"),
			]
		&"codex":
			return [
				AssetDomainContractScript.default_jump_target(&"warehouse", "Open owned-state reference preview"),
				AssetDomainContractScript.default_jump_target(&"profile", "Open first discovery history preview"),
			]
		&"research":
			return [
				AssetDomainContractScript.default_jump_target(&"codex", "Open codex requirement preview"),
				AssetDomainContractScript.default_jump_target(&"deploy_prep", "Open future unlock consumer preview"),
			]
		&"profile":
			return [
				AssetDomainContractScript.default_jump_target(&"history", "Open history record preview"),
				AssetDomainContractScript.default_jump_target(&"collection_appearance", "Open badge/title display preview"),
			]
		&"gacha":
			return [
				AssetDomainContractScript.default_jump_target(&"collection_appearance", "Open result display preview"),
				AssetDomainContractScript.default_jump_target(&"warehouse", "Open item result preview"),
			]
		&"collection_appearance":
			return [
				AssetDomainContractScript.default_jump_target(&"codex", "Open source codex preview"),
				AssetDomainContractScript.default_jump_target(&"warehouse", "Open unique collectible body preview"),
			]
		_:
			return []


static func _current_landable_scope(module_id: StringName) -> Array:
	match module_id:
		&"goals":
			return ["display objective categories", "display reward state preview", "display red_dot_policy preview"]
		&"codex":
			return ["display codex categories", "display asset/codex relation preview"]
		&"research":
			return ["display disabled research lines", "display unlock interface preview"]
		&"profile":
			return ["display profile/history preview", "display milestone/title/badge preview"]
		&"gacha":
			return ["display disabled pool/cost/result preview"]
		&"collection_appearance":
			return ["display collection/cosmetic/unique preview", "display asset reference preview"]
		_:
			return []


static func _deferred_scope(module_id: StringName) -> Array:
	return [
		"real backend state",
		"real reward delivery",
		"real gacha result",
		"real objective progress",
		"real asset mutation",
		"real persistence for %s" % String(module_id),
	]
