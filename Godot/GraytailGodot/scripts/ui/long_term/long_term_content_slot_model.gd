extends RefCounted
class_name LongTermContentSlotModel

const STATE_PREVIEW := &"preview"
const STATE_DISABLED := &"disabled"

const SLOT_OBJECTIVE := &"objective_preview_slot"
const SLOT_REWARD_EVENT := &"reward_event_preview_slot"
const SLOT_CLAIMABLE := &"claimable_preview_slot"
const SLOT_RED_DOT := &"red_dot_preview_slot"
const SLOT_CODEX_UNLOCK := &"codex_unlock_preview_slot"
const SLOT_RESEARCH_UNLOCK := &"research_unlock_preview_slot"
const SLOT_GACHA_POOL := &"gacha_pool_preview_slot"
const SLOT_GACHA_COST := &"gacha_cost_preview_slot"
const SLOT_GACHA_RESULT := &"gacha_result_preview_slot"
const SLOT_COLLECTION_DISPLAY := &"collection_display_preview_slot"
const SLOT_COSMETIC := &"cosmetic_preview_slot"
const SLOT_UNIQUE_COLLECTIBLE := &"unique_collectible_preview_slot"
const SLOT_HISTORY_RECORD := &"history_record_preview_slot"
const SLOT_QUALIFICATION := &"qualification_preview_slot"
const SLOT_ASSET_EVENT := &"asset_event_preview_slot"


static func build_all_preview_slots() -> Array:
	return [
		objective_preview_slot(),
		reward_event_preview_slot(),
		claimable_preview_slot(),
		red_dot_preview_slot(),
		codex_unlock_preview_slot(),
		research_unlock_preview_slot(),
		gacha_pool_preview_slot(),
		gacha_cost_preview_slot(),
		gacha_result_preview_slot(),
		collection_display_preview_slot(),
		cosmetic_preview_slot(),
		unique_collectible_preview_slot(),
		history_record_preview_slot(),
		qualification_preview_slot(),
		asset_event_preview_slot(),
	]


static func build_slots_for_module(module_id: StringName) -> Array:
	match module_id:
		&"goals":
			return _clone_slots([
				objective_preview_slot(),
				reward_event_preview_slot(),
				claimable_preview_slot(),
				red_dot_preview_slot(),
				asset_event_preview_slot(),
			])
		&"codex":
			return _clone_slots([
				codex_unlock_preview_slot(),
				asset_event_preview_slot(),
				red_dot_preview_slot(),
			])
		&"research":
			return _clone_slots([
				research_unlock_preview_slot(),
				asset_event_preview_slot(),
				red_dot_preview_slot(),
			])
		&"profile":
			return _clone_slots([
				history_record_preview_slot(),
				qualification_preview_slot(),
				reward_event_preview_slot(),
				red_dot_preview_slot(),
			])
		&"gacha":
			return _clone_slots([
				gacha_pool_preview_slot(),
				gacha_cost_preview_slot(),
				gacha_result_preview_slot(),
				reward_event_preview_slot(),
			])
		&"collection_appearance":
			return _clone_slots([
				collection_display_preview_slot(),
				cosmetic_preview_slot(),
				unique_collectible_preview_slot(),
				codex_unlock_preview_slot(),
			])
		_:
			return []


static func objective_preview_slot() -> Dictionary:
	return _slot(
		SLOT_OBJECTIVE,
		&"objective",
		"目标进度接口 preview",
		"预留任务、成就、委托记录的只读目标槽位；不计算进度，不写目标状态。"
	)


static func reward_event_preview_slot() -> Dictionary:
	return _slot(
		SLOT_REWARD_EVENT,
		&"reward_event",
		"奖励事件接口 preview",
		"预留奖励展示和来源说明；不发放奖励，不改变资产。"
	)


static func claimable_preview_slot() -> Dictionary:
	return _slot(
		SLOT_CLAIMABLE,
		&"claimable",
		"可领取状态 preview",
		"预留领取入口状态；不执行领取，不修改任何奖励记录。"
	)


static func red_dot_preview_slot() -> Dictionary:
	return _slot(
		SLOT_RED_DOT,
		&"notice",
		"提示标记 preview",
		"预留提示标记展示；不清除提示，不写状态。"
	)


static func codex_unlock_preview_slot() -> Dictionary:
	return _slot(
		SLOT_CODEX_UNLOCK,
		&"codex_unlock",
		"图鉴解锁接口 preview",
		"预留图鉴解锁和条目展示字段；不解锁图鉴，不写条目。"
	)


static func research_unlock_preview_slot() -> Dictionary:
	return _slot(
		SLOT_RESEARCH_UNLOCK,
		&"research_unlock",
		"研究解锁接口 preview",
		"预留研究节点和条件展示；不解锁研究，不消耗资源。"
	)


static func gacha_pool_preview_slot() -> Dictionary:
	return _slot(
		SLOT_GACHA_POOL,
		&"gacha_pool",
		"奖池展示 preview",
		"预留奖池入口、主题和规则摘要；不计算概率。"
	)


static func gacha_cost_preview_slot() -> Dictionary:
	return _slot(
		SLOT_GACHA_COST,
		&"gacha_cost",
		"抽取消耗 preview",
		"预留票券、金币或其他消耗说明；不扣除资源。"
	)


static func gacha_result_preview_slot() -> Dictionary:
	return _slot(
		SLOT_GACHA_RESULT,
		&"gacha_result",
		"抽取结果入口 preview",
		"预留结果历史和展示入口；不生成结果，不发放物品。"
	)


static func collection_display_preview_slot() -> Dictionary:
	return _slot(
		SLOT_COLLECTION_DISPLAY,
		&"collection_display",
		"收藏展示 preview",
		"预留收藏墙、展示位和排序字段；不写收藏状态。"
	)


static func cosmetic_preview_slot() -> Dictionary:
	return _slot(
		SLOT_COSMETIC,
		&"cosmetic",
		"外观配置 preview",
		"预留外观库和展示配置入口；不应用外观。"
	)


static func unique_collectible_preview_slot() -> Dictionary:
	return _slot(
		SLOT_UNIQUE_COLLECTIBLE,
		&"unique_collectible",
		"唯一藏品 preview",
		"预留唯一藏品展示和特殊说明；唯一仍属于藏品，不作为一级模块。"
	)


static func history_record_preview_slot() -> Dictionary:
	return _slot(
		SLOT_HISTORY_RECORD,
		&"history_record",
		"历史战绩 preview",
		"预留历史记录卡片和筛选入口；历史战绩仍归入个人资历。"
	)


static func qualification_preview_slot() -> Dictionary:
	return _slot(
		SLOT_QUALIFICATION,
		&"qualification",
		"个人资历变化 preview",
		"预留资历等级、称号、徽章和里程碑展示；不升级资历。"
	)


static func asset_event_preview_slot() -> Dictionary:
	return _slot(
		SLOT_ASSET_EVENT,
		&"asset_event",
		"资产事件接口 preview",
		"预留资产来源、结果和跳转说明；不写资产事件，不修改仓库。"
	)


static func _slot(slot_id: StringName, slot_type: StringName, display_name: String, description: String) -> Dictionary:
	var slot_key := String(slot_id)
	return {
		"slot_id": slot_id,
		"slot_type": slot_type,
		"display_name": display_name,
		"description": description,
		"state": STATE_PREVIEW,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
		"no_reward_grant": true,
		"no_claim": true,
		"no_red_dot_clear": true,
		"no_roll": true,
		"no_asset_mutation": true,
		"future_data_ref": "future.long_term.%s" % slot_key,
		"data_source_ref": "preview.long_term.%s" % slot_key,
		"ui_keys": {
			"card_icon_key": "long_term.%s.card_icon" % slot_key,
			"reward_icon_key": "long_term.%s.reward_icon" % slot_key,
			"rarity_frame_key": "long_term.%s.rarity_frame" % slot_key,
			"art_placeholder_id": "placeholder.%s" % slot_key,
			"localization_key": "ui.long_term.%s.title" % slot_key,
			"description_key": "ui.long_term.%s.description" % slot_key,
			"ui_group_key": "long_term.slot.%s" % slot_key,
		},
	}


static func _clone_slots(slots: Array) -> Array:
	var cloned := []
	for slot: Dictionary in slots:
		cloned.append(slot.duplicate(true))
	return cloned
