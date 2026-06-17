extends RefCounted
class_name LongTermSnapshot

const LongTermContentFrameworkScript := preload("res://scripts/ui/long_term/long_term_content_framework.gd")
const LongTermContentSlotModelScript := preload("res://scripts/ui/long_term/long_term_content_slot_model.gd")
const SettlementHistoryPreviewScript := preload("res://scripts/core/settlement/settlement_history_preview.gd")

const SCHEMA_VERSION := 1


static func default_snapshot(module_summaries: Dictionary = {}, source: StringName = &"long_term_shell") -> Dictionary:
	var content_framework_modules: Array = LongTermContentFrameworkScript.build_modules()
	var content_preview_slots: Array = LongTermContentSlotModelScript.build_all_preview_slots()
	var settlement_history_preview: Dictionary = SettlementHistoryPreviewScript.default_preview()
	var history_record_preview: Dictionary = settlement_history_preview.get("history_record_snapshot_preview", {})
	var long_term_history_preview: Dictionary = settlement_history_preview.get("long_term_history_preview", {})
	return {
		"schema_version": SCHEMA_VERSION,
		"profile_snapshot": {
			"title": "个人资历摘要",
			"state": "display_only",
			"lines": [
				"当前仅展示资历入口、等级文案与后续接口位置。",
				"不读取角色档案，不写入成长数据。",
			],
		},
		"unlock_snapshot": {
			"title": "解锁摘要",
			"state": "display_only",
			"lines": [
				"当前仅展示解锁信息的只读位置。",
				"不判断解锁条件，不改变任何解锁状态。",
			],
		},
		"history_snapshot": {
			"title": "历史摘要",
			"state": "display_only",
			"lines": [
				"当前仅展示历史战绩入口与字段预览。",
				"不读取记录，不生成新记录。",
			],
		},
		"settlement_snapshot_preview": settlement_history_preview.get("settlement_snapshot_preview", {}).duplicate(true),
		"history_record_snapshot_preview": history_record_preview.duplicate(true),
		"history_timeline_preview": {
			"title": "历史战绩 timeline preview",
			"module": "个人资历",
			"state": "display_only",
			"records": [long_term_history_preview.duplicate(true)],
			"message": "SettlementSnapshot -> HistoryRecordSnapshot -> LongTerm history preview only.",
			"read_only": true,
			"display_only": true,
			"preview": true,
		},
		"content_framework_preview": {
			"title": "G24 长期系统内容框架 preview",
			"state": "framework",
			"module_count": content_framework_modules.size(),
			"module_summaries": LongTermContentFrameworkScript.module_summaries(content_framework_modules),
			"message": "只记录六模块内容框架、二级分组、卡片和 slot 预留，不实现真实长期系统。",
			"read_only": true,
			"display_only": true,
			"preview": true,
		},
		"content_slot_preview": {
			"title": "G24 preview slot 汇总",
			"state": "display_only",
			"slots": content_preview_slots.duplicate(true),
			"message": "objective / reward / claimable / red dot / codex / research / gacha / collection / history / asset event slots only.",
			"read_only": true,
			"display_only": true,
			"preview": true,
		},
		"art_slot_preview": {
			"title": "G24 美术 slot 预留",
			"state": "display_only",
			"message": "程序当前只消费 key 与 placeholder id，不接真实 Texture2D 或导入资源。",
			"module_icon_key": "long_term.module_icon",
			"tab_icon_key": "long_term.tab_icon",
			"group_icon_key": "long_term.group_icon",
			"card_icon_key": "long_term.card_icon",
			"reward_icon_key": "long_term.reward_icon",
			"rarity_frame_key": "long_term.rarity_frame",
			"gacha_pool_art_key": "long_term.gacha_pool_art",
			"collection_slot_art_key": "long_term.collection_slot_art",
			"art_placeholder_id": "placeholder.long_term.content_framework",
			"read_only": true,
			"display_only": true,
			"preview": true,
		},
		"data_key_preview": {
			"title": "G24 数据 key 预留",
			"state": "display_only",
			"localization_key": "ui.long_term.module.title",
			"description_key": "ui.long_term.module.description",
			"ui_group_key": "long_term.module",
			"future_data_ref": "future.long_term.content_framework",
			"data_source_ref": "preview.long_term.content_framework",
			"read_only": true,
			"display_only": true,
			"preview": true,
		},
		"overview_summary": {
			"title": "长期系统总览",
			"state": "preview",
			"module_count": module_summaries.size(),
			"message": "G24 只建立长期系统内容框架、preview slot 和只读 key 预留。",
		},
		"module_summaries": module_summaries.duplicate(true),
		"asset_projection_preview": {
			"title": "资产投影预览",
			"state": "display_only",
			"message": "只预留长期页需要展示的资产摘要位置，不生成真实资产投影。",
		},
		"event_flow_preview": {
			"title": "事件流预览",
			"state": "display_only",
			"message": "只说明后续长期事件如何展示，不创建或消费事件。",
		},
		"reward_preview": {
			"title": "奖励接口预览",
			"state": "display_only",
			"message": "只展示奖励入口说明，不发放任何奖励。",
		},
		"red_dot_preview": {
			"title": "提示标记预览",
			"state": "display_only",
			"message": "只展示提示标记的接口位置，不改变提示标记状态。",
		},
		"inventory_link_preview": {
			"title": "仓库跳转预览",
			"state": "display_only",
			"message": "只展示未来跳转说明，不打开仓库本体。",
		},
		"codex_link_preview": {
			"title": "图鉴跳转预览",
			"state": "display_only",
			"message": "只展示未来跳转说明，不打开图鉴本体。",
		},
		"history_link_preview": {
			"title": "历史战绩跳转预览",
			"state": "display_only",
			"message": "只展示未来跳转说明，不打开历史战绩本体。",
		},
		"source": source,
		"created_at_or_sequence": 0,
	}
