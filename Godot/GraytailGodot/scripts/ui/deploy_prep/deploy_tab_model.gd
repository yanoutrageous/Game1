extends RefCounted
class_name DeployTabModel

const TAB_MAP := &"map"
const TAB_WAREHOUSE := &"warehouse"
const TAB_CLAIM := &"claim"
const TAB_LOADOUT := &"loadout"
const TAB_PERMIT := &"permit"

const DEFAULT_TAB := TAB_MAP


static func build_tabs() -> Array:
	return [
		_tab(TAB_MAP, "地图", "选择区域与地图规则", [
			"本轮只保留地图页签入口。",
			"真实地图生成、路线预览和 seed 写入后置。",
			"当前 RunStartConfig 使用 defer_until_run_start。",
		]),
		_tab(TAB_WAREHOUSE, "仓库", "查看可携带物资占位", [
			"仓库实例、容量规则和拖拽装载后置。",
			"当前背包预览固定为 0 / 12。",
			"不会读取或写入真实仓库数据。",
		]),
		_tab(TAB_CLAIM, "申领", "申领补给与服务占位", [
			"申领经济、价格、库存和领取记录后置。",
			"当前 enabled_claims 为空数组。",
			"不会产生资源或交易。",
		]),
		_tab(TAB_LOADOUT, "出勤配置", "配置随身物资占位", [
			"装备、消耗品和角色配置后置。",
			"当前 selected_loadout 与 carried_consumables 均为空。",
			"不会启动探索或校验真实装载合法性。",
		]),
		_tab(TAB_PERMIT, "作业许可", "许可与风险提示占位", [
			"作业许可、保险、托运和情报标记规则后置。",
			"当前 selected_permits 与 selected_services 均为空。",
			"风险只显示占位说明。",
		]),
	]


static func find_tab(tab_id: StringName) -> Dictionary:
	var tabs := build_tabs()
	for raw_tab in tabs:
		var tab := raw_tab as Dictionary
		if StringName(tab.get("id", DEFAULT_TAB)) == tab_id:
			return tab.duplicate(true)
	return (tabs[0] as Dictionary).duplicate(true)


static func _tab(tab_id: StringName, label: String, subtitle: String, lines: Array) -> Dictionary:
	return {
		"id": tab_id,
		"label": label,
		"subtitle": subtitle,
		"lines": lines.duplicate(true),
		"disabled": false,
	}
