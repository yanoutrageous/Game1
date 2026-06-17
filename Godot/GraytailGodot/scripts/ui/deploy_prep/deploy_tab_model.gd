extends RefCounted
class_name DeployTabModel

const TAB_MAP := &"map"
const TAB_WAREHOUSE := &"warehouse"
const TAB_CLAIM := &"claim"
const TAB_LOADOUT := &"loadout"
const TAB_PERMIT := &"permit"

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
const FILTER_WAREHOUSE_UNKNOWN := &"warehouse_unknown_state"
const FILTER_CLAIM_SUPPLY := &"claim_supply"
const FILTER_CLAIM_INTEL := &"claim_intel"
const FILTER_CLAIM_SERVICE := &"claim_service"
const FILTER_CLAIM_BASIC_EQUIPMENT := &"claim_basic_equipment"
const FILTER_LOADOUT_EQUIPPED := &"loadout_equipped"
const FILTER_LOADOUT_CARRIED := &"loadout_carried"
const FILTER_LOADOUT_SERVICE := &"loadout_service"
const FILTER_LOADOUT_INTEL := &"loadout_intel"
const FILTER_LOADOUT_PERMIT := &"loadout_permit"
const FILTER_LOADOUT_BAG := &"loadout_bag"
const FILTER_LOADOUT_PRESET := &"loadout_preset"
const FILTER_PERMIT_EXPLORE := &"permit_explore"
const FILTER_PERMIT_COMBAT := &"permit_combat"
const FILTER_PERMIT_BAG := &"permit_bag"
const FILTER_PERMIT_EVAC := &"permit_evac"
const FILTER_PERMIT_EVENT := &"permit_event"
const FILTER_PERMIT_INTEL := &"permit_intel"


static func build_tabs() -> Array:
	return [
		_tab(
			TAB_MAP,
			"地图",
			"去哪、选什么难度、承担哪些模糊风险的 preview。",
			[
				"地图页只表达出发前地图模式、难度、区域、基础规则和模糊风险收益。",
				"seed_policy = defer_until_run_start；真实随机结果必须等到开始探索后才生成。",
				"不展示真实地图布局、Boss 房位置、撤离点、怪物房、宝箱、事件房或房间分布。",
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
				_card("map_classic_edge", "灰尾外围 / 常规扫雷", "地图", "preview", "标准出发模式 preview。", "显示模式、难度、区域和基础规则，不生成真实地图布局。", ["模式：常规扫雷", "难度：普通", "区域：灰尾外围", "seed_policy = defer_until_run_start"], ["查看风险摘要"], FILTER_MAP_CLASSIC),
				_card("map_honeycomb_trial", "蜂窝扫雷 / 预留", "地图", "preview", "蜂窝规则入口 preview。", "只展示未来可选模式，不暴露房间分布或真实随机结果。", ["模式：蜂窝扫雷", "基础规则：邻接结构不同", "状态：display_only"], ["查看规则说明"], FILTER_MAP_HONEYCOMB),
				_card("map_special_rule_fog", "雾区规则 / 特殊规则", "地图", "disabled", "特殊规则 preview。", "只显示特殊条件与模糊风险倾向，不生成具体事件房或怪物房。", ["特殊条件：视野受限", "收益倾向：较高", "风险倾向：较高"], ["查看长期系统说明"], FILTER_MAP_SPECIAL),
				_card("map_unlocked_route", "已解锁区域 / 预览", "地图", "preview", "已解锁区域列表 preview。", "只显示区域是否可被选择，不写长期解锁状态。", ["已解锁：灰尾外围", "未解锁：深层矿脉", "Boss 房支持：仅显示是否支持"], ["查看图鉴说明"], FILTER_MAP_UNLOCKED),
				_card("map_recommended_loadout", "推荐匹配 / 当前配置", "地图", "preview", "根据当前出勤包给出推荐提示 preview。", "只说明是否适合当前配置，不做正式数值平衡。", ["适合度：中", "服务缺口：侦察能力不足", "建议：补充情报或许可"], ["查看出勤配置"], FILTER_MAP_RECOMMENDED),
				_card("map_recon_boundary", "侦察能力 / 边界", "地图", "preview", "侦察能力只影响说明文案。", "可以提示 Boss 侦察边界，但不展示 Boss 类型、位置或档案。", ["侦察：未启用", "Boss 信息：不披露", "撤离点：不披露"], ["查看作业许可"], FILTER_MAP_RECOMMENDED),
			]
		),
		_tab(
			TAB_WAREHOUSE,
			"仓库",
			"只服务本局出勤准备的仓库资产视角。",
			[
				"实体物品主类型只使用：装备 / 消耗品 / 藏品 / 特殊物。",
				"唯一、样本、任务物、委托物、未判断价值只作为 rarity、state、tag 或 source 展示。",
				"本局携带消耗品将在本局结束后默认清空；这里不出售、不整理、不写真实仓库。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_WAREHOUSE_EQUIPMENT, "装备"),
				_filter(FILTER_WAREHOUSE_CONSUMABLE, "消耗品"),
				_filter(FILTER_WAREHOUSE_COLLECTIBLE, "藏品"),
				_filter(FILTER_WAREHOUSE_SPECIAL, "特殊物"),
				_filter(FILTER_WAREHOUSE_UNKNOWN, "未判断价值"),
			],
			[
				_card("field_knife", "野外短刀 / 示例", "装备", "preview", "可穿戴 draft。", "展示穿戴/卸下入口，但只改变本页 preview 文案。", ["主类型：装备", "动作：穿戴 / 卸下 preview", "真实装备合法性：未验证"], ["前往图鉴", "前往研究"], FILTER_WAREHOUSE_EQUIPMENT),
				_card("patched_vest", "补丁防护背心 / 示例", "装备", "preview", "防护位装备 preview。", "只显示出勤视角卡片，不读取真实库存。", ["主类型：装备", "位置：防护", "状态：display_only"], ["查看配置"], FILTER_WAREHOUSE_EQUIPMENT),
				_card("first_aid", "简易急救包 / 示例", "消耗品", "preview", "可加入本局出勤 draft。", "展示携带容量占用，不发放或消耗物品。", ["主类型：消耗品", "数量：2", "本局携带消耗品将在本局结束后默认清空。"], ["查看详情"], FILTER_WAREHOUSE_CONSUMABLE),
				_card("flare_pack", "照明棒组 / 示例", "消耗品", "preview", "事件和探索辅助物 preview。", "只显示携带建议，不扣除物品。", ["主类型：消耗品", "容量：1", "结束处理：默认清空"], ["查看风险"], FILTER_WAREHOUSE_CONSUMABLE),
				_card("sealed_relic", "封存藏品 / 示例", "藏品", "preview", "可展示，不提供局内数值收益。", "唯一属于藏品的特殊稀有档或特殊种类，不作为主类型。", ["主类型：藏品", "rarity：唯一", "出售：禁止"], ["前往长期系统"], FILTER_WAREHOUSE_COLLECTIBLE),
				_card("commission_token", "委托标记物 / 示例", "特殊物", "preview", "委托来源只作为 source/tag。", "任务物、委托物、样本都只能落在特殊物或藏品视角，不新建主类型。", ["主类型：特殊物", "source：委托", "tag：记录提示"], ["查看委托说明"], FILTER_WAREHOUSE_SPECIAL),
				_card("unknown_sample", "未判断样本 / 示例", "特殊物", "preview", "识别状态预留。", "未判断价值是 identification/state，不是物品主类型。", ["主类型：特殊物", "state：未判断价值", "真实鉴定系统：未实现"], ["前往研究"], FILTER_WAREHOUSE_UNKNOWN),
			]
		),
		_tab(
			TAB_CLAIM,
			"申领",
			"补给、情报、服务与基础装备的出发前入口 preview。",
			[
				"申领页不是商店，也不是完整奖励领取系统。",
				"领取、购买、购买并加入出勤、启用服务都只显示 preview 状态。",
				"显示金币 / 凭证 / 服务券需求，但不扣费、不发奖、不写领取记录。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_CLAIM_SUPPLY, "补给"),
				_filter(FILTER_CLAIM_INTEL, "情报"),
				_filter(FILTER_CLAIM_SERVICE, "服务"),
				_filter(FILTER_CLAIM_BASIC_EQUIPMENT, "基础装备"),
			],
			[
				_card("basic_supply", "基础补给包 / 领取", "补给", "preview", "领取按钮 preview。", "不创建资源，不写领取记录。", ["需求：凭证 x1", "动作：领取 preview", "发奖：未接入"], ["查看配置摘要"], FILTER_CLAIM_SUPPLY),
				_card("field_ration", "应急口粮 / 购买", "补给", "preview", "购买状态 preview。", "显示金币需求但不扣金币。", ["需求：金币 x40", "动作：购买 preview", "真实扣费：未接入"], ["查看背包占用"], FILTER_CLAIM_SUPPLY),
				_card("route_intel", "路线情报 / 启用", "情报", "preview", "情报入口 preview。", "只显示未来信息入口，不打开真实情报系统。", ["需求：情报凭证 x1", "动作：启用情报 preview", "Boss 类型：不披露"], ["前往研究说明"], FILTER_CLAIM_INTEL),
				_card("logistics_service", "后勤服务 / 启用服务", "服务", "preview", "服务影响进入右侧效果预览。", "显示服务券需求，但不扣券、不写服务状态。", ["需求：服务券 x1", "动作：启用服务 preview", "状态：read_only"], ["查看效果"], FILTER_CLAIM_SERVICE),
				_card("starter_gear", "基础装备 / 购买并加入出勤", "基础装备", "preview", "购买并加入出勤 preview。", "不购买、不入仓、不写出勤包，只显示 draft 口径。", ["需求：金币 x80", "动作：购买并加入出勤 preview", "资产入仓：未接入"], ["查看仓库视角"], FILTER_CLAIM_BASIC_EQUIPMENT),
			]
		),
		_tab(
			TAB_LOADOUT,
			"出勤配置",
			"本局装备、消耗品、服务、情报、许可和背包占用的 draft 摘要。",
			[
				"出勤配置页汇总已穿戴装备、本局携带消耗品、启用服务、启用情报和启用许可。",
				"预设、清空和重置只作为 preview 文案保留，不保存真实配置。",
				"不验证真实装备合法性，不写背包，不启动探索。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_LOADOUT_EQUIPPED, "已穿戴装备"),
				_filter(FILTER_LOADOUT_CARRIED, "本局携带消耗品"),
				_filter(FILTER_LOADOUT_SERVICE, "启用服务"),
				_filter(FILTER_LOADOUT_INTEL, "启用情报"),
				_filter(FILTER_LOADOUT_PERMIT, "启用许可"),
				_filter(FILTER_LOADOUT_BAG, "背包占用"),
				_filter(FILTER_LOADOUT_PRESET, "预设 / 清空 / 重置"),
			],
			[
				_card("equipped_summary", "已穿戴装备", "配置", "preview", "显示装备 draft 摘要。", "来源于本页示例数据，不读取真实仓库。", ["主手：野外短刀", "防护：补丁防护背心", "合法性验证：未接入"], ["查看仓库视角"], FILTER_LOADOUT_EQUIPPED),
				_card("carry_summary", "本局携带消耗品", "配置", "preview", "显示本局携带 draft。", "只改变 RunStartConfig preview 的携带摘要。", ["急救包：2", "照明棒：1", "本局结束后默认清空"], ["查看风险"], FILTER_LOADOUT_CARRIED),
				_card("service_summary", "启用服务", "配置", "preview", "服务接口 preview。", "只显示服务对右侧效果的说明，不启用真实服务。", ["后勤服务：未启用", "医疗支援：未启用", "服务券：不扣除"], ["查看申领"], FILTER_LOADOUT_SERVICE),
				_card("intel_summary", "启用情报", "配置", "preview", "情报接口 preview。", "只显示侦察能力与风险提示，不展示 Boss 档案。", ["路线情报：未启用", "Boss 侦察：边界提示", "真实情报记录：未写入"], ["查看地图"], FILTER_LOADOUT_INTEL),
				_card("permit_summary", "启用许可", "配置", "preview", "许可摘要 preview。", "只显示启用许可列表，不应用规则引擎。", ["基础作业许可：启用", "容量：1 / 2", "真实规则：未应用"], ["查看作业许可"], FILTER_LOADOUT_PERMIT),
				_card("bag_summary", "背包占用", "配置", "preview", "背包容量 preview。", "只显示本页草案占用，不写真实背包。", ["占用：3 / 12", "风险：容量仍充足", "结算：未接入"], ["查看风险"], FILTER_LOADOUT_BAG),
				_card("preset_summary", "预设 / 清空 / 重置", "配置", "disabled", "预设系统后置。", "清空和重置只保留 preview 口径，不保存真实配置。", ["预设：未接入", "清空：preview", "重置：preview"], ["查看说明"], FILTER_LOADOUT_PRESET),
			]
		),
		_tab(
			TAB_PERMIT,
			"作业许可",
			"出发前规则配置、容量、条件、风险和效果的 preview。",
			[
				"作业许可是出发前规则配置，不是仓库物品。",
				"可以展示已解锁、未解锁、已启用、容量、启用条件、风险和效果。",
				"不实现真实许可规则引擎、长期解锁、Boss 情报档案、失败保护、保险或托运。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_PERMIT_EXPLORE, "探索"),
				_filter(FILTER_PERMIT_COMBAT, "战斗"),
				_filter(FILTER_PERMIT_BAG, "背包"),
				_filter(FILTER_PERMIT_EVAC, "撤离"),
				_filter(FILTER_PERMIT_EVENT, "事件"),
				_filter(FILTER_PERMIT_INTEL, "情报"),
			],
			[
				_card("permit_explore_basic", "基础探索许可", "许可", "preview", "已解锁 / 已启用 preview。", "显示探索规则摘要，不应用真实规则。", ["分类：探索", "状态：已解锁 / 已启用", "容量：1 / 2"], ["查看效果"], FILTER_PERMIT_EXPLORE),
				_card("permit_combat_focus", "战斗准备许可", "许可", "disabled", "战斗许可 preview。", "只说明战斗效果入口，不修改战斗系统。", ["分类：战斗", "状态：未解锁", "风险：高强度房间提示"], ["查看长期系统"], FILTER_PERMIT_COMBAT),
				_card("permit_bag_expand", "背包扩容许可", "许可", "preview", "背包效果 preview。", "只显示容量影响，不写真实背包。", ["分类：背包", "效果：容量 +2 preview", "条件：基础许可启用"], ["查看出勤配置"], FILTER_PERMIT_BAG),
				_card("permit_evac_scout", "撤离侦察许可", "许可", "disabled", "撤离边界 preview。", "可以提示撤离点未探明，不显示真实撤离点位置。", ["分类：撤离", "状态：未解锁", "失败保护：未实现"], ["查看地图"], FILTER_PERMIT_EVAC),
				_card("permit_event_filter", "事件筛选许可", "许可", "preview", "事件倾向 preview。", "只显示事件风险说明，不生成具体事件房内容。", ["分类：事件", "风险：未知事件", "效果：display_only"], ["查看风险"], FILTER_PERMIT_EVENT),
				_card("permit_boss_recon", "Boss 侦察许可", "许可", "disabled", "Boss 侦察边界 preview。", "可以显示是否支持 Boss 侦察，但不实现 Boss 情报档案。", ["分类：情报", "Boss 侦察：边界提示", "Boss 类型：不披露"], ["查看情报"], FILTER_PERMIT_INTEL),
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
		"补给":
			return FILTER_CLAIM_SUPPLY
		"服务":
			return FILTER_CLAIM_SERVICE
		"情报":
			return FILTER_CLAIM_INTEL
		"基础装备":
			return FILTER_CLAIM_BASIC_EQUIPMENT
		"配置":
			return FILTER_LOADOUT_EQUIPPED
		"许可":
			return FILTER_PERMIT_EXPLORE
		"地图":
			return FILTER_MAP_CLASSIC
		_:
			return FILTER_ALL


static func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []
