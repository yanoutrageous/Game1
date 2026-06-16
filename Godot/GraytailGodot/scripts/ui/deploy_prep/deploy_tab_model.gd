extends RefCounted
class_name DeployTabModel

const TAB_MAP := &"map"
const TAB_WAREHOUSE := &"warehouse"
const TAB_CLAIM := &"claim"
const TAB_LOADOUT := &"loadout"
const TAB_PERMIT := &"permit"

const DEFAULT_TAB := TAB_MAP

const FILTER_ALL := &"all"
const FILTER_MAP_ROUTE := &"map_route"
const FILTER_MAP_RISK := &"map_risk"
const FILTER_WAREHOUSE_EQUIPMENT := &"warehouse_equipment"
const FILTER_WAREHOUSE_CONSUMABLE := &"warehouse_consumable"
const FILTER_WAREHOUSE_COLLECTIBLE := &"warehouse_collectible"
const FILTER_WAREHOUSE_SPECIAL := &"warehouse_special"
const FILTER_WAREHOUSE_UNKNOWN := &"warehouse_unknown"
const FILTER_CLAIM_SUPPLY := &"claim_supply"
const FILTER_CLAIM_SERVICE := &"claim_service"
const FILTER_CLAIM_INTEL := &"claim_intel"
const FILTER_CLAIM_BASIC_EQUIPMENT := &"claim_basic_equipment"
const FILTER_LOADOUT_EQUIPPED := &"loadout_equipped"
const FILTER_LOADOUT_CARRIED := &"loadout_carried"
const FILTER_LOADOUT_PRESET := &"loadout_preset"
const FILTER_PERMIT_UNLOCKED := &"permit_unlocked"
const FILTER_PERMIT_LOCKED := &"permit_locked"
const FILTER_PERMIT_ENABLED := &"permit_enabled"


static func build_tabs() -> Array:
	return [
		_tab(
			TAB_MAP,
			"地图",
			"选择本局探索入口与风险视角",
			[
				"地图页只表达出发前路线和风险预览。",
				"真实地图生成、路线锁定和 seed 写入仍后置。",
				"当前只输出 RunStartConfig draft，不启动探索。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_MAP_ROUTE, "路线"),
				_filter(FILTER_MAP_RISK, "风险"),
			],
			[
				_card("map_preview", "灰尾外围 / 预览", "地图", "preview", "本局地图入口占位。", "显示区域、难度和风险缺口；不生成真实地图。", ["区域：未指定", "难度：普通", "Seed：开始时再确定"], ["查看风险摘要"]),
				_card("route_preview", "路线规划 / 预留", "路线", "disabled", "路线选择后置。", "只说明未来路线筛选和深层跳转；不锁定路径。", ["节点：未生成", "撤离点：未生成"], ["前往图鉴说明"]),
			]
		),
		_tab(
			TAB_WAREHOUSE,
			"仓库",
			"只服务本局出勤准备的仓库视角",
			[
				"这里不是完整仓库系统，只展示出勤相关资产视角。",
				"允许表达加入/移出出勤、穿戴/卸下的 draft 状态。",
				"不出售、不批量整理、不写真实仓库。",
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
				_card("field_knife", "野外短刀 / 示例", "装备", "preview", "可穿戴 draft。", "展示穿戴/卸下入口，但只改变本页 preview 文案。", ["位置：出勤仓库视角", "规则：可穿戴 / 可移出"], ["前往图鉴", "前往研究"]),
				_card("first_aid", "简易急救包 / 示例", "消耗品", "preview", "可加入本局出勤 draft。", "展示携带容量占用，不发放或消耗物品。", ["数量：2", "容量：1"], ["查看详情"]),
				_card("sealed_relic", "封存藏品 / 示例", "藏品", "preview", "可展示，不提供局内数值收益。", "唯一或高价值藏品仍属于藏品视角，不作为主类型。", ["出售：禁止", "图鉴：可跳转说明"], ["前往长期系统"]),
				_card("unknown_sample", "未判断样本 / 示例", "未判断价值", "preview", "识别状态预留。", "只显示样本和识别状态，不展开鉴定系统。", ["状态：未判断", "来源：出勤前记录"], ["前往研究"]),
			]
		),
		_tab(
			TAB_CLAIM,
			"申领",
			"补给、服务、情报与基础装备入口",
			[
				"申领是出发前资源入口，不是商店。",
				"当前只显示补给、服务、情报和基础装备 preview。",
				"不发奖、不扣费、不写领取记录。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_CLAIM_SUPPLY, "补给"),
				_filter(FILTER_CLAIM_SERVICE, "服务"),
				_filter(FILTER_CLAIM_INTEL, "情报"),
				_filter(FILTER_CLAIM_BASIC_EQUIPMENT, "基础装备"),
			],
			[
				_card("basic_supply", "基础补给包 / 预览", "补给", "preview", "显示可申领口径。", "不创建资源，不写领取记录。", ["内容：占位", "限制：待接入"], ["查看配置摘要"]),
				_card("logistics_service", "后勤服务 / 预览", "服务", "preview", "显示服务接口。", "服务影响只进入右侧效果预览。", ["服务：未启用", "费用：不结算"], ["查看效果"]),
				_card("route_intel", "路线情报 / 预览", "情报", "disabled", "情报入口后置。", "只保留未来信息入口，不打开真实情报系统。", ["来源：未接入", "可信度：待定"], ["前往研究说明"]),
			]
		),
		_tab(
			TAB_LOADOUT,
			"出勤配置",
			"本局携带、穿戴、许可和服务的 draft 摘要",
			[
				"配置页汇总已穿戴装备、本局携带消耗品、许可和服务。",
				"预设、清空和重置只作为 preview 文案保留。",
				"不验证真实装备合法性，不启动探索。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_LOADOUT_EQUIPPED, "已穿戴"),
				_filter(FILTER_LOADOUT_CARRIED, "携带物"),
				_filter(FILTER_LOADOUT_PRESET, "预设"),
			],
			[
				_card("equipped_summary", "已穿戴装备", "配置", "preview", "显示装备 draft 摘要。", "来源于本页示例数据，不读取真实仓库。", ["主手：野外短刀", "防护：未选择"], ["查看仓库视角"]),
				_card("carry_summary", "携带消耗品", "配置", "preview", "显示本局携带 draft。", "只改变 RunStartConfig preview 的携带摘要。", ["急救包：2", "背包：2 / 12"], ["查看风险"]),
				_card("preset_summary", "配置预设 / 预留", "配置", "disabled", "预设系统后置。", "只保留清空/重置口径，不写配置。", ["预设：未接入", "重置：preview"], ["查看说明"]),
			]
		),
		_tab(
			TAB_PERMIT,
			"作业许可",
			"出发前规则配置与容量摘要",
			[
				"作业许可是出发前规则配置，不是仓库物品。",
				"显示已解锁、未解锁、已启用、容量和效果摘要。",
				"不写长期解锁，不修改真实许可状态。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_PERMIT_UNLOCKED, "已解锁"),
				_filter(FILTER_PERMIT_LOCKED, "未解锁"),
				_filter(FILTER_PERMIT_ENABLED, "已启用"),
			],
			[
				_card("permit_basic", "基础作业许可", "许可", "preview", "默认许可 preview。", "显示容量和效果摘要，不应用真实规则。", ["状态：已解锁", "容量：1 / 2"], ["查看效果"]),
				_card("permit_deep_route", "深层作业许可", "许可", "disabled", "解锁条件后置。", "只显示未解锁原因和长期系统跳转说明。", ["状态：未解锁", "原因：长期系统后置"], ["前往长期系统"]),
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
	}


static func _filter(filter_id: StringName, label: String) -> Dictionary:
	return {
		"id": filter_id,
		"label": label,
		"display_only": true,
	}


static func _card(
	card_id: StringName,
	title: String,
	category: String,
	state,
	summary: String,
	detail: String,
	lines: Array,
	links: Array
) -> Dictionary:
	return {
		"id": card_id,
		"filter_id": _filter_for_category(category),
		"title": title,
		"category": category,
		"state": state,
		"summary": summary,
		"detail": detail,
		"lines": lines.duplicate(true),
		"link_preview": links.duplicate(true),
		"display_only": true,
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
		"未判断价值":
			return FILTER_WAREHOUSE_UNKNOWN
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
			return FILTER_PERMIT_UNLOCKED
		"路线":
			return FILTER_MAP_ROUTE
		"风险":
			return FILTER_MAP_RISK
		_:
			return FILTER_ALL


static func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []
