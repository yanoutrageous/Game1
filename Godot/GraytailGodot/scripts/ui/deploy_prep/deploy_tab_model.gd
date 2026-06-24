extends RefCounted
class_name DeployTabModel

const TAB_MAP := &"map"
const TAB_WAREHOUSE := &"warehouse"
const TAB_CLAIM := &"claim"
const TAB_OBJECTIVE := &"objective"
const TAB_LOADOUT := &"loadout"

const DEFAULT_TAB := TAB_MAP

const FILTER_ALL := &"all"
const FILTER_MAP_CLASSIC := &"map_classic_minesweeper"
const FILTER_MAP_HONEYCOMB := &"map_honeycomb_minesweeper"
const FILTER_MAP_SPECIAL := &"map_special_rule"
const FILTER_MAP_UNLOCKED := &"map_unlocked"
const FILTER_MAP_RECOMMENDED := &"map_recommended"
const FILTER_WAREHOUSE_EQUIPMENT := &"warehouse_equipment"
const FILTER_WAREHOUSE_CONSUMABLE := &"warehouse_consumable"
const FILTER_WAREHOUSE_COLLECTIBLE := &"warehouse_collectible"
const FILTER_WAREHOUSE_SPECIAL := &"warehouse_special"
const FILTER_WAREHOUSE_STATUS := &"warehouse_status"
const FILTER_CLAIM_PURCHASE := &"claim_purchase"
const FILTER_CLAIM_RECEIVE := &"claim_receive"
const FILTER_CLAIM_RECYCLE := &"claim_recycle"
const FILTER_CLAIM_LOCKED := &"claim_locked"
const FILTER_CLAIM_RECOMMENDED := &"claim_recommended"
const FILTER_OBJECTIVE_AVAILABLE := &"objective_available"
const FILTER_OBJECTIVE_COMMISSION := &"objective_commission"
const FILTER_OBJECTIVE_MAP_MATCH := &"objective_map_match"
const FILTER_OBJECTIVE_LOCKED := &"objective_locked"
const FILTER_OBJECTIVE_REWARD := &"objective_reward"
const FILTER_LOADOUT_MAP := &"loadout_map"
const FILTER_LOADOUT_OBJECTIVE := &"loadout_objective"
const FILTER_LOADOUT_EQUIPMENT := &"loadout_equipment"
const FILTER_LOADOUT_CONSUMABLE := &"loadout_consumable"
const FILTER_LOADOUT_SPECIAL := &"loadout_special"
const FILTER_LOADOUT_BAG := &"loadout_bag"
const FILTER_LOADOUT_VALIDITY := &"loadout_validity"
const FILTER_LOADOUT_INTENT := &"loadout_intent"
const FILTER_LOADOUT_PERMISSION := &"loadout_permission_interface"


static func build_tabs() -> Array:
	return [
		_tab(
			TAB_MAP,
			"地图",
			"选择去哪、地图规则、难度和区域；真实地图内容 defer_until_run_start。",
			[
				"地图页只表达模式、难度、区域、解锁、模糊风险 / 收益和配置适配。",
				"seed_policy = defer_until_run_start；不提前生成真实地图布局、Boss、撤离点或房间内容。",
				"地图拓扑可影响消耗品说明，例如相邻房间由矩形 / 蜂窝 / 特殊规则解释。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_MAP_CLASSIC, "常规扫雷"),
				_filter(FILTER_MAP_HONEYCOMB, "蜂窝扫雷"),
				_filter(FILTER_MAP_SPECIAL, "特殊规则"),
				_filter(FILTER_MAP_UNLOCKED, "已解锁"),
				_filter(FILTER_MAP_RECOMMENDED, "推荐"),
			],
			[
				_card("map_classic_edge", "灰尾外围 / 常规扫雷", "地图", "preview", "当前默认可选地图模式。", "显示地图模式、难度、区域、基础规则和 seed policy；不生成真实地图内容。", ["模式：常规扫雷", "难度：普通", "区域：灰尾外围", "seed_policy = defer_until_run_start"], ["查看出勤配置"], FILTER_MAP_CLASSIC),
				_card("map_honeycomb_trial", "蜂窝扫雷 / 拓扑预留", "地图", "locked", "蜂窝邻接规则 display-only。", "只说明消耗品相邻房间效果将按 6 邻域解释，不披露真实房间分布。", ["模式：蜂窝扫雷", "状态：后续开放", "探测说明：相邻房间由拓扑解释"], ["查看消耗品效果"], FILTER_MAP_HONEYCOMB),
				_card("map_special_rule_fog", "雾区规则 / 特殊规则", "地图", "locked", "特殊规则后续开放。", "只显示特殊条件、风险倾向和收益倾向，不生成事件房或怪物房。", ["解锁：未满足", "风险倾向：较高", "收益倾向：较高"], ["查看目标匹配"], FILTER_MAP_SPECIAL),
				_card("map_unlocked_route", "已解锁区域", "地图", "preview", "区域解锁状态 preview。", "只显示是否可选；不写长期解锁或真实地图状态。", ["已解锁：灰尾外围", "未解锁：深层矿脉", "后续开放：雾区 / 多层地图"], ["查看图鉴说明"], FILTER_MAP_UNLOCKED),
				_card("map_target_match", "地图 / 目标适配", "地图", "preview", "根据已选目标给出匹配提示。", "地图页只提示支持的目标类型；目标选择在目标页完成。", ["目标匹配：回收类可用", "配置适配：中", "缺口：保障类消耗品不足"], ["前往目标"], FILTER_MAP_RECOMMENDED),
			]
		),
		_tab(
			TAB_WAREHOUSE,
			"仓库",
			"ownership-first：查看已拥有资产，并以 preview 表达出售、带入、装备状态。",
			[
				"仓库主分类固定为：装备 / 消耗品 / 藏品 / 特殊物。",
				"唯一、样本、任务物、委托物、未判断价值只作为 rarity、state、tag 或 source。",
				"出售、装备、加入出勤和移出出勤在本轮都是 preview / in-memory intent，不写真实仓库。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_WAREHOUSE_EQUIPMENT, "装备"),
				_filter(FILTER_WAREHOUSE_CONSUMABLE, "消耗品"),
				_filter(FILTER_WAREHOUSE_COLLECTIBLE, "藏品"),
				_filter(FILTER_WAREHOUSE_SPECIAL, "特殊物"),
				_filter(FILTER_WAREHOUSE_STATUS, "状态"),
			],
			[
				_card("field_knife", "野外短刀 / 已拥有", "装备", "owned", "可出勤、可装备 preview。", "只显示装备 / 卸下 intent，不做真实装备 mutation。", ["主类型：装备", "状态：可出勤 / 已配置", "动作：装备 / 卸下 preview"], ["查看出勤配置"], FILTER_WAREHOUSE_EQUIPMENT),
				_card("patched_vest", "补丁防护背心 / 已配置", "装备", "configured", "防护位装备 preview。", "已配置状态只存在于 DeployPrep draft，不写 AssetLedger。", ["主类型：装备", "状态：已配置", "出售：需先移出出勤"], ["移出出勤 preview"], FILTER_WAREHOUSE_EQUIPMENT),
				_card("first_aid", "简易急救包 / 消耗品", "消耗品", "owned", "可加入出勤 draft。", "本局携带消耗品将在本局结束后默认清空。", ["主类型：消耗品", "数量：2", "状态：可出勤 / 可出售"], ["加入出勤 preview"], FILTER_WAREHOUSE_CONSUMABLE),
				_card("sealed_relic", "封存藏品 / 唯一", "藏品", "locked", "唯一是藏品稀有档，不是主类型。", "唯一藏品不可通过常规出售逻辑出售；只保留收藏 / 图鉴关联。", ["主类型：藏品", "rarity：唯一", "出售：禁止"], ["前往收藏说明"], FILTER_WAREHOUSE_COLLECTIBLE),
				_card("commission_token", "委托标记物 / 特殊物", "特殊物", "owned", "委托来源用 tag/source 表示。", "特殊物可作为目标条件提示，不实现真实目标系统。", ["主类型：特殊物", "source：委托", "目标相关：是"], ["前往目标"], FILTER_WAREHOUSE_SPECIAL),
				_card("warehouse_status", "仓库状态摘要", "状态", "preview", "ownership-first 状态汇总。", "展示可出勤、可出售、已配置、锁定、新获得等标签，不执行任何仓库写入。", ["可出勤：3", "可出售：2", "已配置：2", "未判断：1"], ["查看右侧摘要"], FILTER_WAREHOUSE_STATUS),
			]
		),
		_tab(
			TAB_CLAIM,
			"申领",
			"catalog-first：展示可购买、可领取、可回收、未解锁和推荐目录。",
			[
				"申领页从“当前能提供什么”出发，不替代仓库 ownership 视角。",
				"购买 / 领取 / 回收 / 购买并加入出勤在本轮只表达 preview intent。",
				"购买或领取的规则目标是入长期仓库；不得绕过仓库创建临时本局物资。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_CLAIM_PURCHASE, "可购买"),
				_filter(FILTER_CLAIM_RECEIVE, "可领取"),
				_filter(FILTER_CLAIM_RECYCLE, "可回收"),
				_filter(FILTER_CLAIM_LOCKED, "未解锁"),
				_filter(FILTER_CLAIM_RECOMMENDED, "推荐"),
			],
			[
				_card("purchase_first_aid", "简易急救包 / 可购买", "申领", "preview", "购买事件 preview。", "显示资源需求和入仓结果，但不扣费、不发放、不入仓。", ["需求：金币 x40", "结果：进入长期仓库", "快捷：购买并加入出勤需拆成两个事件"], ["查看仓库"], FILTER_CLAIM_PURCHASE),
				_card("claim_starter_gear", "基础装备 / 可领取", "申领", "preview", "基础装备领取 preview。", "基础装备默认进入长期仓库，除非明确标记临时租借。", ["领取条件：教学完成", "结果：装备入仓", "临时租借：否"], ["查看出勤配置"], FILTER_CLAIM_RECEIVE),
				_card("recycle_relic", "后勤回收 / 可回收目录", "申领", "preview", "回收目录 preview。", "申领页只展示可回收类型；出售仍需玩家拥有且未加入当前出勤。", ["接受：普通藏品", "拒绝：唯一藏品", "冲突：已配置需先移出"], ["查看仓库状态"], FILTER_CLAIM_RECYCLE),
				_card("locked_supply", "高级保障物 / 未解锁", "申领", "locked", "未解锁预览。", "只显示条件，不创建服务或情报独立系统。", ["条件：后续接口", "标签：保障类消耗品", "许可：后续开放"], ["查看开放事项"], FILTER_CLAIM_LOCKED),
				_card("recommended_for_target", "目标相关推荐", "申领", "preview", "按地图 / 目标 / 仓库缺口推荐。", "推荐只读显示，不写购买清单。", ["推荐：探测类消耗品", "原因：目标需要探索房间", "状态：display_only"], ["前往目标"], FILTER_CLAIM_RECOMMENDED),
			]
		),
		_tab(
			TAB_OBJECTIVE,
			"目标",
			"选择本局目标 / 委托；替代旧作业许可的当前可见位置。",
			[
				"目标页只处理本局目标 / 委托选择，不管理长期目标总览。",
				"目标可显示地图匹配、难度匹配、完成 / 失败条件和奖励类型摘要。",
				"作业许可降级为 locked interface，不再作为当前一级页签。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_OBJECTIVE_AVAILABLE, "可接"),
				_filter(FILTER_OBJECTIVE_COMMISSION, "委托"),
				_filter(FILTER_OBJECTIVE_MAP_MATCH, "地图匹配"),
				_filter(FILTER_OBJECTIVE_LOCKED, "未解锁"),
				_filter(FILTER_OBJECTIVE_REWARD, "奖励类型"),
			],
			[
				_card("objective_recover_cache", "回收补给箱 / 本局目标", "目标", "selected", "默认选中目标 preview。", "选择只写 DeployPrep local draft，不写长期目标或 runtime progress。", ["类型：回收类", "完成：带回目标记录物", "失败：目标奖励失效"], ["查看出勤配置"], FILTER_OBJECTIVE_AVAILABLE),
				_card("commission_scan_route", "路线扫描 / 委托", "目标", "preview", "委托池目标 preview。", "显示地图和消耗品需求，不触发接取事件。", ["类型：探索类", "需要：探测类消耗品", "地图匹配：常规扫雷"], ["查看地图"], FILTER_OBJECTIVE_COMMISSION),
				_card("objective_map_match", "地图匹配提示", "目标", "preview", "当前目标与地图适配。", "地图页可提示目标支持性；目标选择仍在本页。", ["地图：灰尾外围", "匹配：可用", "风险：保障不足"], ["查看地图"], FILTER_OBJECTIVE_MAP_MATCH),
				_card("objective_locked_high_risk", "高危委托 / 未解锁", "目标", "locked", "高危目标后续开放。", "只显示锁定条件，不实现高危目标惩罚。", ["条件：长期解锁", "许可：后续接口", "状态：locked"], ["查看未决事项"], FILTER_OBJECTIVE_LOCKED),
				_card("objective_reward_summary", "奖励类型摘要", "目标", "preview", "只显示奖励类型，不发放奖励。", "奖励发放和结算后置到真实结算 / 奖励系统。", ["奖励类型：资源 / 藏品引用", "失败：失去目标奖励", "发放：未接入"], ["查看风险"], FILTER_OBJECTIVE_REWARD),
			]
		),
		_tab(
			TAB_LOADOUT,
			"出勤配置",
			"最终收口页：地图、目标、资产、背包容量、合法性和开始 / 继续 / 放弃 intent。",
			[
				"出勤配置只汇总当前 draft，不重新展开完整选择器。",
				"背包容量统一表达本次出勤携带物占用；仓库库存本身不占出勤背包容量。",
				"开始 / 继续 / 放弃只保留按钮状态、强确认和 intent 边界，不接真实 RunBootstrapper。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_LOADOUT_MAP, "地图"),
				_filter(FILTER_LOADOUT_OBJECTIVE, "目标"),
				_filter(FILTER_LOADOUT_EQUIPMENT, "装备"),
				_filter(FILTER_LOADOUT_CONSUMABLE, "消耗品"),
				_filter(FILTER_LOADOUT_SPECIAL, "特殊物"),
				_filter(FILTER_LOADOUT_BAG, "背包容量"),
				_filter(FILTER_LOADOUT_VALIDITY, "合法性"),
				_filter(FILTER_LOADOUT_INTENT, "开始 / 继续 / 放弃"),
				_filter(FILTER_LOADOUT_PERMISSION, "许可接口"),
			],
			[
				_card("loadout_map_summary", "地图摘要", "配置", "preview", "地图 / 难度 / 区域汇总。", "真实地图内容仍在开始探索后生成。", ["地图：常规扫雷", "难度：普通", "区域：灰尾外围"], ["返回地图"], FILTER_LOADOUT_MAP),
				_card("loadout_objective_summary", "目标摘要", "配置", "preview", "已选目标 / 委托汇总。", "只显示本局目标 draft，不写长期目标系统。", ["目标：回收补给箱", "匹配：可用", "奖励类型：资源 / 藏品引用"], ["返回目标"], FILTER_LOADOUT_OBJECTIVE),
				_card("loadout_equipment_summary", "装备摘要", "配置", "preview", "已带装备汇总。", "装备合法性只在 preview 中显示，不执行真实装备锁定。", ["野外短刀", "补丁防护背心", "冲突：无"], ["返回仓库"], FILTER_LOADOUT_EQUIPMENT),
				_card("loadout_consumable_summary", "消耗品摘要", "配置", "preview", "已带消耗品和地图拓扑说明。", "消耗品本局结束默认清空；探测相邻房间由地图拓扑解释。", ["简易急救包 x2", "照明棒组 x1", "拓扑：常规扫雷 8 邻域说明"], ["返回仓库"], FILTER_LOADOUT_CONSUMABLE),
				_card("loadout_special_summary", "特殊物摘要", "配置", "preview", "特殊物 / 委托物引用。", "只显示目标相关状态，不写仓库或目标进度。", ["委托标记物", "目标相关：是", "状态：已配置"], ["返回目标"], FILTER_LOADOUT_SPECIAL),
				_card("loadout_bag_capacity", "背包容量", "配置", "preview", "统一使用背包容量口径。", "不新增补给容量；购买但未带入的物品不计入本局配置。", ["背包容量：3 / 12", "购买未带入：1", "超限：否"], ["查看风险"], FILTER_LOADOUT_BAG),
				_card("loadout_validity", "配置合法性", "配置", "preview", "开始探索前合法性摘要。", "只做 display-only 校验提示，不启动真实 RunFlow。", ["地图：已选", "目标：可用", "不可出勤物：无", "需要二次确认：否"], ["查看摘要"], FILTER_LOADOUT_VALIDITY),
				_card("loadout_intents", "开始 / 继续 / 放弃 intent", "配置", "preview", "主操作边界。", "开始、继续、放弃都只产生 preview intent；放弃必须强确认。", ["开始：preview", "继续：按 active_run 状态", "放弃：强确认 preview"], ["查看按钮"], FILTER_LOADOUT_INTENT),
				_card("permission_interface", "作业许可 / 后续接口", "配置", "locked", "作业许可降级为接口。", "当前不设置许可槽、容量、主动启用、消耗或互斥，只显示 locked state。", ["required_permission：预留", "future_permission_hook：预留", "状态：后续开放"], ["查看未决事项"], FILTER_LOADOUT_PERMISSION),
			]
		),
	]


static func find_tab(tab_id: StringName) -> Dictionary:
	var tabs := build_tabs()
	for raw_tab in tabs:
		var tab := raw_tab as Dictionary
		if StringName(tab.get("id", DEFAULT_TAB)) == tab_id:
			return tab.duplicate(true)
	return (tabs[0] as Dictionary).duplicate(true)


static func default_filter_for(tab_id: StringName) -> StringName:
	var tab := find_tab(tab_id)
	var filters := _array_from(tab, "secondary_filters")
	if filters.is_empty():
		return FILTER_ALL
	var first_filter := filters[0] as Dictionary
	return StringName(first_filter.get("id", FILTER_ALL))


static func default_card_for(tab_id: StringName) -> StringName:
	var tab := find_tab(tab_id)
	var cards := _array_from(tab, "cards")
	if cards.is_empty():
		return &""
	var first_card := cards[0] as Dictionary
	return StringName(first_card.get("id", &""))


static func filter_cards(tab_id: StringName, filter_id: StringName) -> Array:
	var tab := find_tab(tab_id)
	var cards := _array_from(tab, "cards")
	if filter_id == FILTER_ALL:
		return cards
	var result := []
	for raw_card in cards:
		if raw_card is Dictionary:
			var card := raw_card as Dictionary
			if StringName(card.get("filter_id", FILTER_ALL)) == filter_id:
				result.append(card.duplicate(true))
	return result


static func find_card(tab_id: StringName, card_id: StringName) -> Dictionary:
	var tab := find_tab(tab_id)
	for raw_card in _array_from(tab, "cards"):
		if raw_card is Dictionary:
			var card := raw_card as Dictionary
			if StringName(card.get("id", &"")) == card_id:
				return card.duplicate(true)
	return {}


static func _tab(tab_id: StringName, label: String, subtitle: String, lines: Array, filters: Array, cards: Array) -> Dictionary:
	return {
		"id": tab_id,
		"label": label,
		"subtitle": subtitle,
		"lines": lines.duplicate(true),
		"secondary_filters": filters.duplicate(true),
		"cards": cards.duplicate(true),
		"disabled": false,
		"preview": true,
		"display_only": true,
		"read_only": true,
	}


static func _filter(filter_id: StringName, label: String) -> Dictionary:
	return {
		"id": filter_id,
		"label": label,
		"preview": true,
		"display_only": true,
		"read_only": true,
	}


static func _card(
	card_id: StringName,
	title: String,
	category: String,
	state,
	summary: String,
	detail: String,
	lines: Array,
	links: Array,
	filter_id: StringName = &""
) -> Dictionary:
	return {
		"id": card_id,
		"filter_id": filter_id if filter_id != &"" else _filter_for_category(category),
		"title": title,
		"category": category,
		"state": state,
		"summary": summary,
		"detail": detail,
		"lines": lines.duplicate(true),
		"link_preview": links.duplicate(true),
		"preview": true,
		"display_only": true,
		"read_only": true,
	}


static func _filter_for_category(category: String) -> StringName:
	match category:
		"装备":
			return FILTER_WAREHOUSE_EQUIPMENT
		"消耗品":
			return FILTER_WAREHOUSE_CONSUMABLE
		"藏品":
			return FILTER_WAREHOUSE_COLLECTIBLE
		"特殊物":
			return FILTER_WAREHOUSE_SPECIAL
		"申领":
			return FILTER_CLAIM_PURCHASE
		"目标":
			return FILTER_OBJECTIVE_AVAILABLE
		"配置":
			return FILTER_LOADOUT_VALIDITY
		"地图":
			return FILTER_MAP_CLASSIC
		_:
			return FILTER_ALL


static func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []
