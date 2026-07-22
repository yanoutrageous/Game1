extends RefCounted
class_name M7ContentCatalog

const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")

const DEFAULT_UNLOCKED_MAPS := [
	"classic_7x7_simple",
	"classic_7x7_normal",
	"classic_10x10_easy",
	"classic_10x10_standard",
]


static func map_definitions() -> Array[Dictionary]:
	return [
		_map("classic_7x7_simple", "7×7 简单", "教学 / 低压入门", 7, 10, 5, 1, 0, true, 20),
		_map("classic_7x7_normal", "7×7 普通", "入门正式局", 7, 10, 5, 0, 1, false, 20),
		_map("classic_10x10_easy", "10×10 简单", "低压标准局", 10, 20, 10, 0, 3, false, 30),
		_map("classic_10x10_standard", "10×10 标准", "主展示标准局", 10, 20, 10, 0, 2, false, 30),
		_map("classic_10x10_hard", "10×10 困难", "高压标准局", 10, 20, 10, 0, 1, false, 30),
		_map("classic_13x13_normal", "13×13 普通", "大图普通", 13, 34, 17, 0, 4, false, 45),
		_map("classic_13x13_hard", "13×13 困难", "大图高压", 13, 34, 17, 0, 2, false, 45),
		_map("classic_13x13_hell", "13×13 地狱", "高失败挑战", 13, 34, 17, 0, 1, false, 45),
	]


static func map_definition(map_id: String) -> Dictionary:
	var exact := map_definition_exact(map_id)
	if not exact.is_empty():
		return exact
	# Historical callers rely on the 10x10 standard fallback. New selection and
	# projection paths must use map_definition_exact() so an unknown id cannot be
	# presented as another playable map.
	return map_definitions()[3].duplicate(true)


static func map_definition_exact(map_id: String) -> Dictionary:
	for definition in map_definitions():
		if str(definition.get("id", "")) == map_id:
			return definition.duplicate(true)
	return {}


static func map_runtime_config(map_id: String, seed_value: int, run_start_config: Dictionary = {}) -> Dictionary:
	var definition := map_definition(map_id)
	return {
		"id": StringName(map_id),
		"mode": &"standard",
		"map_config_id": map_id,
		"map_display_name": str(definition.get("display_name", map_id)),
		"difficulty": StringName(definition.get("difficulty", &"normal")),
		"difficulty_label": str(definition.get("difficulty_label", "普通")),
		"width": int(definition.get("width", 10)),
		"height": int(definition.get("height", 10)),
		"seed": seed_value,
		"mine_count": int(definition.get("mine_count", 20)),
		"event_room_count": int(definition.get("content_room_count", 10)),
		"monster_room_count": int(definition.get("content_room_count", 10)),
		"chest_room_count": int(definition.get("content_room_count", 10)),
		"visible_exit_count": int(definition.get("visible_exit_count", 0)),
		"random_exit_count": int(definition.get("hidden_exit_count", 2)),
		"visible_exit_position_known": bool(definition.get("visible_exit_position_known", false)),
		"mine_hits_are_fatal": false,
		"reveal_on_move": true,
		"move_requires_revealed": false,
		"backpack_capacity": 10,
		"failure_salvage_capacity": 4,
		"black_to_gold_rate": 1.0,
		"run_start_config": run_start_config.duplicate(true),
	}


static func commission_definitions() -> Array[Dictionary]:
	return [
		_commission("commission_recover_supply", "回收补给箱", "成功撤离时带回至少 2 件非消耗品。", &"recover_non_consumables", 2, 25, 25),
		_commission("commission_route_survey", "路线勘察", "本局探索 12 个不同房间。", &"unique_rooms", 12, 20, 20),
		_commission("commission_anomaly_cleanup", "异常清理", "击败 2 个怪物遭遇。", &"monsters_defeated", 2, 30, 30),
		_commission("commission_open_crates", "开箱记录", "打开 2 个宝箱。", &"chests_opened", 2, 25, 25),
		_commission("commission_event_evidence", "事件取证", "完成 2 个事件。", &"events_completed", 2, 25, 25),
		_commission("commission_critical_extract", "临界协议撤离", "在协议阶段 1 时成功撤离。", &"critical_extract", 1, 45, 40, ["classic_10x10_hard", "classic_13x13_normal", "classic_13x13_hard", "classic_13x13_hell"]),
	]


static func commission_definition(commission_id: String) -> Dictionary:
	for definition in commission_definitions():
		if str(definition.get("id", "")) == commission_id:
			return definition.duplicate(true)
	return commission_definitions()[0].duplicate(true)


static func commission_candidates(map_id: String, seed_value: int, count: int = 3) -> Array[Dictionary]:
	if map_id == "classic_7x7_simple":
		return [commission_definition("commission_recover_supply")]
	var legal: Array[Dictionary] = []
	for definition in commission_definitions():
		var map_ids: Array = definition.get("map_ids", [])
		if map_ids.is_empty() or map_ids.has(map_id):
			legal.append(definition.duplicate(true))
	var result: Array[Dictionary] = []
	var pool := legal.duplicate(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	while not pool.is_empty() and result.size() < maxi(1, count):
		var index := rng.randi_range(0, pool.size() - 1)
		result.append(pool[index].duplicate(true))
		pool.remove_at(index)
	return result


static func task_definitions() -> Array[Dictionary]:
	return [
		_goal("task_first_survey", "第一次踏勘", "打开小地图并探索 3 个不同房间。", {"gold": 20, "exp": 20}),
		_goal("task_risk_mark", "风险标记", "标记任意 1 个未探索房间。", {"items": ["con_scan_pin"], "exp": 15}),
		_goal("task_supply_recovery", "物资回收", "打开 1 个宝箱并拾取 1 件物品。", {"items": ["con_med_patch"], "exp": 20}),
		_goal("task_clear_anomaly", "清理异常", "击败 1 个怪物遭遇。", {"gold": 30, "exp": 25}),
		_goal("task_complete_commission", "完整委托", "完成本局委托并成功撤离。", {"gold": 40, "exp": 35}),
		_goal("task_prepared_deploy", "有备出勤", "购买 1 件物品，并把该实例带入之后的一局。", {"items": ["con_tape_roll"], "exp": 30}),
		_goal("task_sample_research", "样本研究", "带回 1 件怪物样本并完成任意研究。", {"gold": 60, "exp": 50}),
	]


static func optional_task_definitions() -> Array[Dictionary]:
	return [
		_goal("task_failure_salvage", "失败抢救", "失败后手动抢救至少 1 件物品并确认。", {"gold": 20, "exp": 20}),
	]


static func achievement_definitions() -> Array[Dictionary]:
	return [
		_goal("achievement_first_return", "首次归来", "第一次成功撤离。", {"gold": 30, "exp": 30}),
		_goal("achievement_clean_route", "清洁路线", "成功撤离且本局未触发雷房。", {"gold": 40, "exp": 35}),
		_goal("achievement_critical_return", "临界归来", "在协议阶段 1 成功撤离。", {"gold": 60, "exp": 50}),
		_goal("achievement_low_hp_return", "残血归来", "以不高于 10 生命成功撤离。", {"gold": 50, "exp": 45}),
		_goal("achievement_chest_expert", "开箱专家", "单局打开至少 4 个宝箱并成功撤离。", {"gold": 45, "exp": 40}),
		_goal("achievement_anomaly_sweep", "异常清扫", "单局击败至少 4 个怪物遭遇并成功撤离。", {"gold": 55, "exp": 45}),
		_goal("achievement_measured_greed", "贪而有度", "发现撤离点后继续探索至少 8 个新房间，再成功撤离。", {"gold": 55, "exp": 45}),
		_goal("achievement_four_events", "四类见证", "累计完成旅商、骰子局、祭坛、机关各 1 次。", {"gold": 70, "exp": 60}),
	]


static func research_definitions() -> Array[Dictionary]:
	return [
		_research("research_anomaly_structure", "异常结构分析", "", 40, "mon_old_gear_set", "开放稳定剂购买，并显示完整怪物档案。"),
		_research("research_protocol_formula", "协议稳定配方", "research_anomaly_structure", 60, "sp_altar_residue", "开放镇静糖购买，并显示协议压力规则详情。"),
		_research("research_extraction_signal", "撤离信号校准", "research_protocol_formula", 90, "mon_loader_black_box", "解锁 13×13 普通，并显示撤离权规则详情。"),
	]


static func research_definition(research_id: String) -> Dictionary:
	for definition in research_definitions():
		if str(definition.get("id", "")) == research_id:
			return definition.duplicate(true)
	return {}


static func shop_definitions() -> Array[Dictionary]:
	return [
		_shop("con_ration", 12),
		_shop("con_tape_roll", 16),
		_shop("con_scan_pin", 14),
		_shop("con_med_patch", 18),
		_shop("con_calm_candy", 20, "research", "research_protocol_formula"),
		_shop("con_stabilizer", 22, "research", "research_anomaly_structure"),
		_shop("eq_goggles", 36, "profile", "2"),
		_shop("eq_insulated_sleeve", 32, "profile", "2"),
		_shop("eq_old_vest", 42, "profile", "3"),
		_shop("eq_recovery_bag", 48, "profile", "4"),
	]


static func shop_definition(item_id: String) -> Dictionary:
	for definition in shop_definitions():
		if str(definition.get("item_id", "")) == item_id:
			return definition.duplicate(true)
	return {}


static func item_definition(item_id: String) -> Dictionary:
	for definition in M3ItemCatalogScript.all_items():
		if str(definition.get("item_id", "")) == item_id:
			return definition.duplicate(true)
	return {}


static func profile_levels() -> Array[Dictionary]:
	return [
		{"level": 1, "exp": 0, "title": "新进回收员"},
		{"level": 2, "exp": 100, "title": "初级回收员"},
		{"level": 3, "exp": 250, "title": "异常处理员", "badge": "异常处理员徽章"},
		{"level": 4, "exp": 450, "title": "高压路线回收员"},
		{"level": 5, "exp": 700, "title": "灰尾资深回收员", "badge": "阶段资历徽章"},
	]


static func profile_level_for_exp(exp_value: int) -> int:
	var level := 1
	for definition in profile_levels():
		if exp_value >= int(definition.get("exp", 0)):
			level = int(definition.get("level", 1))
	return level


static func collection_sets() -> Array[Dictionary]:
	return [
		{"id": "collection_old_work", "display_name": "旧作业痕迹", "item_ids": _collectible_ids(1, 8)},
		{"id": "collection_anomaly_machine", "display_name": "异常机械记录", "item_ids": _collectible_ids(9, 16)},
		{"id": "collection_deep_protocol", "display_name": "深层协议遗物", "item_ids": _collectible_ids(17, 24)},
	]


static func initial_codex_discoveries() -> Array[String]:
	return [
		"item:eq_goggles",
		"item:eq_insulated_sleeve",
		"item:con_ration",
		"item:con_tape_roll",
		"item:con_scan_pin",
		"rule:mines_and_movement",
		"rule:backpack_and_salvage",
		"rule:settlement_outcomes",
	]


static func all_codex_entry_ids() -> Array[String]:
	var result: Array[String] = []
	for definition in map_definitions():
		result.append("map:%s" % str(definition.get("id", "")))
	for monster_id in ["slime", "slimeling", "bat", "drone"]:
		result.append("monster:%s" % monster_id)
	for event_id in ["trader", "dice", "altar", "trap"]:
		result.append("event:%s" % event_id)
	for item in M3ItemCatalogScript.all_items():
		if not bool(item.get("is_virtual_record", false)):
			result.append("item:%s" % str(item.get("item_id", "")))
	for rule_id in ["mines_and_movement", "extraction_right", "protocol_pressure", "backpack_and_salvage", "settlement_outcomes"]:
		result.append("rule:%s" % rule_id)
	result.append("unique:locked_placeholder")
	return result


static func is_shop_unlocked(definition: Dictionary, meta: Dictionary) -> bool:
	match str(definition.get("unlock_kind", "default")):
		"research":
			return _array(meta.get("research_completed_ids", [])).has(str(definition.get("unlock_value", "")))
		"profile":
			return int(meta.get("profile_level", 1)) >= int(str(definition.get("unlock_value", "1")))
		_:
			return true


static func _map(id: String, display_name: String, role: String, size: int, mines: int, content_count: int, visible_exits: int, hidden_exits: int, visible_position_known: bool, success_exp: int) -> Dictionary:
	var difficulty := id.get_slice("_", id.get_slice_count("_") - 1)
	var labels := {"simple": "简单", "normal": "普通", "easy": "简单", "standard": "标准", "hard": "困难", "hell": "地狱"}
	return {
		"id": id,
		"display_name": display_name,
		"role": role,
		"width": size,
		"height": size,
		"mine_count": mines,
		"content_room_count": content_count,
		"visible_exit_count": visible_exits,
		"hidden_exit_count": hidden_exits,
		"visible_exit_position_known": visible_position_known,
		"difficulty": StringName(difficulty),
		"difficulty_label": str(labels.get(difficulty, difficulty)),
		"success_exp": success_exp,
	}


static func _commission(id: String, display_name: String, description: String, metric: StringName, target: int, gold: int, exp_value: int, map_ids: Array = []) -> Dictionary:
	return {"id": id, "display_name": display_name, "description": description, "metric": metric, "target": target, "reward": {"gold": gold, "exp": exp_value}, "map_ids": map_ids.duplicate()}


static func _goal(id: String, display_name: String, description: String, reward: Dictionary) -> Dictionary:
	return {"id": id, "display_name": display_name, "description": description, "reward": reward.duplicate(true)}


static func _research(id: String, display_name: String, prerequisite: String, gold: int, material_item_id: String, effect: String) -> Dictionary:
	return {"id": id, "display_name": display_name, "prerequisite": prerequisite, "gold_cost": gold, "material_item_id": material_item_id, "material_count": 1, "effect": effect}


static func _shop(item_id: String, price: int, unlock_kind: String = "default", unlock_value: String = "") -> Dictionary:
	var item := item_definition(item_id)
	return {"item_id": item_id, "display_name": str(item.get("display_name", item_id)), "price": price, "unlock_kind": unlock_kind, "unlock_value": unlock_value}


static func _collectible_ids(start_index: int, end_index: int) -> Array[String]:
	var result: Array[String] = []
	for index in range(start_index, end_index + 1):
		result.append("col_%02d" % index)
	return result


static func _array(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []
