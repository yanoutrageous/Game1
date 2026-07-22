extends RefCounted
class_name DeployTabModel

const PresentationMappingScript := preload("res://scripts/presentation/presentation_mapping.gd")

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
			"在同一页选择地图规模与难度。",
			[
				"左侧选择地图名称与规模，右侧查看该规模对应的难度和详情。",
				"房间分布与撤离位置在进入探索后生成。",
			],
			[
				_filter(FILTER_ALL, "全部地图"),
				_filter(FILTER_MAP_UNLOCKED, "已解锁"),
			],
			[]
		),
		_tab(
			TAB_WAREHOUSE,
			"仓库",
			"查看拥有物、出勤状态、品质和可执行操作。",
			[
				"选择物品只更新右侧详情；出勤、使用和出售必须通过明确操作触发。",
				"品质、重量、价值与说明来自真实仓库实例。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_WAREHOUSE_EQUIPMENT, "装备"),
				_filter(FILTER_WAREHOUSE_CONSUMABLE, "补给"),
				_filter(FILTER_WAREHOUSE_COLLECTIBLE, "藏品"),
				_filter(FILTER_WAREHOUSE_SPECIAL, "特殊"),
			],
			[]
		),
		_tab(
			TAB_CLAIM,
			"申领",
			"查看补给价格、余额和解锁条件。",
			[
				"选择条目只查看详情；购买或领取通过右侧明确操作触发。",
				"本局应急补给在终局清空，不进入长期仓库。",
			],
			[
				_filter(FILTER_ALL, "全部"),
				_filter(FILTER_CLAIM_PURCHASE, "购买"),
				_filter(FILTER_CLAIM_RECEIVE, "领取"),
				_filter(FILTER_CLAIM_LOCKED, "锁定"),
			],
			[]
		),
		_tab(
			TAB_OBJECTIVE,
			"本局委托",
			"选择本次探索的委托，查看条件与奖励。",
			[
				"这里只显示本次地图实际可接的委托。",
				"达成条件并成功撤离后发放奖励。",
			],
			[
				_filter(FILTER_ALL, "可接委托"),
			],
			[]
		),
		_tab(
			TAB_LOADOUT,
			"携带清单",
			"核对地图、委托、携带物与容量。",
			[
				"清单逐项显示具体名称，不用数量代替内容。",
				"装备不占背包，携入补给计入容量。",
			],
			[
				_filter(FILTER_ALL, "全部清单"),
			],
			[]
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


static func normalize_filter_for(tab_id: StringName, filter_id: StringName) -> StringName:
	var tab := find_tab(tab_id)
	for raw_filter in _array_from(tab, "secondary_filters"):
		if raw_filter is Dictionary and StringName((raw_filter as Dictionary).get("id", FILTER_ALL)) == filter_id:
			return filter_id
	return default_filter_for(tab_id)


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
		"art09_asset_ref": PresentationMappingScript.deploy_tab_icon_ref(tab_id),
		"disabled": false,
		"preview": false,
		"display_only": false,
		"read_only": true,
	}


static func _filter(filter_id: StringName, label: String) -> Dictionary:
	return {
		"id": filter_id,
		"label": label,
		"preview": false,
		"display_only": false,
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
		"art09_asset_ref": PresentationMappingScript.deploy_card_asset_ref(card_id, category, filter_id if filter_id != &"" else _filter_for_category(category)),
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
