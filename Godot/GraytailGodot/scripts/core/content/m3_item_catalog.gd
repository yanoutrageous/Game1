extends RefCounted
class_name M3ItemCatalog

# M5 minimum item pack. Data is centralized so tuning later does not scatter
# display names, weights, value placeholders, source labels, flavor, or drop tables.

const TYPE_EQUIPMENT := &"equipment"
const TYPE_CONSUMABLE := &"consumable"
const TYPE_COLLECTIBLE := &"collectible"
const TYPE_SPECIAL := &"special"

const SOURCE_SEARCH := "search_drop"
const SOURCE_CHEST := "chest_drop"
const SOURCE_MONSTER := "monster_drop"
const SOURCE_EVENT := "event_drop"
const SOURCE_ALTAR := "altar_special_event"
const SOURCE_DEBUG := "debug_drop"


static func all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.append_array(equipment_items())
	result.append_array(consumable_items())
	result.append_array(collectible_items())
	result.append_array(monster_drop_items())
	result.append_array(special_items())
	return result


static func equipment_items() -> Array[Dictionary]:
	return [
		item("eq_old_vest", "旧背心", TYPE_EQUIPMENT, "带回后可登记；下局降低触雷伤害。", 3, 42, &"tier_3", ["equipment", "mine", "armor"], SOURCE_MONSTER, {"can_equip": true, "equipment_slot": "armor", "effect_kind": "mine_damage_reduce", "effect_amount": 10, "flavor": "内衬被烧过三次，仍然能挡住最坏的一下。"}),
		item("eq_edge_opener", "开刃器", TYPE_EQUIPMENT, "带回后可登记；下局提高搜索收益判断。", 2, 34, &"tier_2", ["equipment", "search", "tool"], SOURCE_CHEST, {"can_equip": true, "equipment_slot": "tool", "effect_kind": "search_reward", "effect_amount": 1, "flavor": "边缘磨得很薄，适合撬开旧封条。"}),
		item("eq_recovery_bag", "回收袋", TYPE_EQUIPMENT, "带回后可登记；下局背包容量 +2。", 3, 48, &"tier_3", ["equipment", "capacity", "bag"], SOURCE_ALTAR, {"can_equip": true, "equipment_slot": "rig", "effect_kind": "backpack_capacity", "effect_amount": 2, "flavor": "袋口有旧编号，容量比看起来更大。"}),
		item("eq_goggles", "护目镜", TYPE_EQUIPMENT, "带回后可登记；下局增加扫描提示。", 2, 36, &"tier_2", ["equipment", "scanner"], SOURCE_CHEST, {"can_equip": true, "equipment_slot": "head", "effect_kind": "scan_hint", "effect_amount": 1, "flavor": "镜片里残留着上一支队伍的路线。"}),
		item("eq_signal_pin", "信号针", TYPE_EQUIPMENT, "带回后可登记；下局提高失败抢救容量。", 1, 44, &"tier_3", ["equipment", "salvage"], SOURCE_EVENT, {"can_equip": true, "equipment_slot": "device", "effect_kind": "salvage_capacity", "effect_amount": 1, "flavor": "针头仍会向安全出口轻微偏转。"}),
		item("eq_insulated_sleeve", "绝缘套", TYPE_EQUIPMENT, "带回后可登记；下局降低协议压力突增。", 2, 32, &"tier_2", ["equipment", "pressure"], SOURCE_SEARCH, {"can_equip": true, "equipment_slot": "gear", "effect_kind": "protocol_pressure_reduce", "effect_amount": 3, "flavor": "套口写着一行褪色的安全条款。"}),
	]


static func consumable_items() -> Array[Dictionary]:
	return [
		item("con_ration", "压缩饼", TYPE_CONSUMABLE, "使用：恢复少量 HP。", 1, 12, &"tier_1", ["consumable", "heal"], SOURCE_SEARCH, {"can_consume": true, "effect_kind": "heal", "effect_amount": 12, "flavor": "硬得像条款，但能顶住一段路。"}),
		item("con_med_patch", "急救贴", TYPE_CONSUMABLE, "使用：恢复 HP。", 1, 18, &"tier_2", ["consumable", "heal"], SOURCE_CHEST, {"can_consume": true, "effect_kind": "heal", "effect_amount": 24, "flavor": "贴上去会发热，像有人在背后按住伤口。"}),
		item("con_tape_roll", "胶带卷", TYPE_CONSUMABLE, "使用：获得一次触雷缓冲。", 1, 16, &"tier_2", ["consumable", "mine_immunity"], SOURCE_SEARCH, {"can_consume": true, "effect_kind": "mine_immunity", "effect_amount": 1, "flavor": "万能，但只在还没炸的时候万能。"}),
		item("con_scan_pin", "扫描针", TYPE_CONSUMABLE, "使用：扫描周边房间。", 1, 14, &"tier_1", ["consumable", "scan"], SOURCE_CHEST, {"can_consume": true, "effect_kind": "scan", "effect_amount": 1, "flavor": "针尖会在危险方向轻轻颤动。"}),
		item("con_calm_candy", "镇静糖", TYPE_CONSUMABLE, "使用：恢复少量 HP 并降低协议压力。", 1, 20, &"tier_3", ["consumable", "heal", "pressure_reduce"], SOURCE_EVENT, {"can_consume": true, "effect_kind": "heal_pressure_reduce", "effect_amount": 8, "pressure_amount": 6, "flavor": "糖纸上写着：不要数门。"}),
		item("con_stabilizer", "稳定剂", TYPE_CONSUMABLE, "使用：降低协议压力。", 1, 22, &"tier_3", ["consumable", "pressure_reduce"], SOURCE_MONSTER, {"can_consume": true, "effect_kind": "pressure_reduce", "effect_amount": 10, "flavor": "瓶身很冷，能让协议噪声安静片刻。"}),
	]


static func collectible_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var names := [
		"旧螺母", "半张工牌", "裂纹灯片", "旧标签纸",
		"断线螺丝", "断电池", "空白条款", "完整齿轮",
		"标准封签", "旧工具头", "反针罗盘", "自拧螺母",
		"吃字机", "温热条款", "旧巡逻牌", "无刻尺",
		"无主钥", "异常电池", "低语灯芯", "过热驱动核",
		"停五钟", "活页图", "签收遗书", "压缩核心",
	]
	for index in range(names.size()):
		var level := int(floor(float(index) / 4.0)) + 1
		level = clampi(level, 1, 6)
		result.append(item(
			"col_%02d" % [index + 1],
			names[index],
			TYPE_COLLECTIBLE,
			"%d 级藏品；可出售，也可带回仓库登记。" % level,
			1 + int(level >= 4),
			6 + level * 7,
			StringName("tier_%d" % level),
			["collectible", "level_%d" % level],
			SOURCE_SEARCH,
			{"collectible_level": level, "can_sell": true, "flavor": "灰尾回收记录：%s。" % names[index]}
		))
	return result


static func monster_drop_items() -> Array[Dictionary]:
	return [
		item("mon_old_gear_set", "旧齿轮组", TYPE_SPECIAL, "怪物专属掉落；记录异常体内部结构。", 1, 28, &"tier_2", ["monster", "sample"], SOURCE_MONSTER, {"flavor": "齿轮仍在自己寻找缺口。"}),
		item("mon_broken_patrol_badge", "断裂巡逻牌", TYPE_SPECIAL, "怪物专属掉落；来源只来自战斗。", 1, 34, &"tier_3", ["monster", "trophy"], SOURCE_MONSTER, {"flavor": "牌面一半写着名字，一半写着警告。"}),
		item("mon_overheated_core", "过热驱动核", TYPE_SPECIAL, "怪物专属掉落；高价值但不是 unique。", 2, 48, &"tier_3", ["monster", "core"], SOURCE_MONSTER, {"flavor": "摸上去像刚停下的心脏。"}),
		item("mon_loader_black_box", "搬运机黑箱", TYPE_SPECIAL, "怪物专属掉落；后续图鉴/研究接口材料。", 2, 58, &"tier_4", ["monster", "record"], SOURCE_MONSTER, {"flavor": "黑箱里循环播放一条撤离路线。"}),
		item("mon_abnormal_instruction", "异常指令片", TYPE_SPECIAL, "怪物专属掉落；只作为战斗来源材料。", 1, 64, &"tier_4", ["monster", "instruction"], SOURCE_MONSTER, {"flavor": "指令片上的字会避开视线。"}),
	]


static func special_items() -> Array[Dictionary]:
	return [
		item("sp_altar_residue", "祭坛残渣", TYPE_SPECIAL, "祭坛事件材料；不会产出 unique。", 1, 28, &"tier_3", ["special", "altar"], SOURCE_ALTAR, {"flavor": "像灰，又像被折碎的条款。"}),
		item("sp_trader_receipt", "旅商收据", TYPE_SPECIAL, "旅商安全收益来源记录。", 0, 1, &"tier_1", ["special", "trader"], "trader", {"flavor": "收据没有金额，只有一句：已经保管。"}),
	]


static func unique_concept_items() -> Array[Dictionary]:
	return [
		{
			"item_id": "unique_gacha_only_01",
			"display_name": "唯一物占位",
			"item_type": TYPE_SPECIAL,
			"main_type": TYPE_SPECIAL,
			"rarity": &"unique",
			"collectible_level": 7,
			"is_unique": true,
			"unique_drop_allowed": false,
			"ordinary_drop_allowed": false,
			"source_label": "抽奖专属；M5 普通掉落禁用",
			"short_description": "仅用于图鉴 locked display；搜索/宝箱/怪物/事件/祭坛不会产出。",
			"flavor": "这件物品只在后续抽奖规则中开放。",
		},
	]


static func drop_table(table_id: StringName) -> Array[Dictionary]:
	match table_id:
		&"search":
			return _take([collectible_items()[0], collectible_items()[4], consumable_items()[0], equipment_items()[2]], 4)
		&"chest":
			return _take([collectible_items()[8], collectible_items()[12], consumable_items()[1], consumable_items()[5], equipment_items()[0]], 5)
		&"monster":
			return monster_drop_items()
		&"event":
			return _take([collectible_items()[5], collectible_items()[9], consumable_items()[3], equipment_items()[4]], 4)
		&"altar":
			return [special_items()[0], consumable_items()[4], equipment_items()[5]]
		&"debug":
			return [debug_item()]
	return []


static func deterministic_drop(table_id: StringName, pos: Vector2i, seed_value: int, count: int = 1) -> Array[Dictionary]:
	var table := drop_table(table_id)
	var result: Array[Dictionary] = []
	if table.is_empty():
		return result
	for index in range(maxi(1, count)):
		var pick_index := absi(pos.x * 131 + pos.y * 71 + seed_value * 17 + index * 29 + String(table_id).hash()) % table.size()
		var picked := table[pick_index].duplicate(true)
		picked["drop_table_id"] = table_id
		picked["source"] = source_for_table(table_id)
		picked["reward_location"] = &"room_floor"
		result.append(picked)
	return result


static func debug_item() -> Dictionary:
	return item("debug_m5_test_cache", "调试回收箱", TYPE_COLLECTIBLE, "Debug 生成测试物；默认进入 GroundLoot。", 1, 25, &"tier_2", ["debug", "collectible"], SOURCE_DEBUG, {"collectible_level": 2, "flavor": "只用于验证拾取、丢弃、结算链路。"})


static func item(item_id: String, display_name: String, item_type: StringName, short_description: String, weight: int, base_value: int, rarity: StringName, tags: Array, source: String, extra: Dictionary = {}) -> Dictionary:
	var result := {
		"item_id": item_id,
		"display_name": display_name,
		"short_description": short_description,
		"icon_fallback": "icon.%s.%s" % [String(item_type), item_id],
		"item_type": item_type,
		"main_type": item_type,
		"rarity": rarity,
		"collectible_level": int(extra.get("collectible_level", 0)),
		"weight": maxi(0, weight),
		"value_state": &"known_value",
		"base_value": maxi(0, base_value),
		"tags": tags.duplicate(true),
		"source": source,
		"source_label": source,
		"flavor": String(extra.get("flavor", short_description)),
		"category_label": category_label(item_type),
		"m5_content_pack": true,
		"can_sell": bool(extra.get("can_sell", item_type == TYPE_COLLECTIBLE)),
		"can_store": true,
		"can_equip": bool(extra.get("can_equip", item_type == TYPE_EQUIPMENT)),
		"can_consume": bool(extra.get("can_consume", item_type == TYPE_CONSUMABLE)),
		"effect_kind": String(extra.get("effect_kind", "")),
		"effect_amount": int(extra.get("effect_amount", 0)),
		"is_unique": false,
		"unique_drop_allowed": false,
		"reward_location": &"room_floor",
	}
	for key in extra.keys():
		result[key] = extra[key]
	result["is_unique"] = false
	result["unique_drop_allowed"] = false
	return result


static func source_for_table(table_id: StringName) -> String:
	match table_id:
		&"search":
			return SOURCE_SEARCH
		&"chest":
			return SOURCE_CHEST
		&"monster":
			return SOURCE_MONSTER
		&"event":
			return SOURCE_EVENT
		&"altar":
			return SOURCE_ALTAR
		&"debug":
			return SOURCE_DEBUG
	return "unknown_drop"


static func category_label(item_type: StringName) -> String:
	match item_type:
		TYPE_EQUIPMENT:
			return "作业装备"
		TYPE_CONSUMABLE:
			return "作业消耗品"
		TYPE_COLLECTIBLE:
			return "藏品"
		TYPE_SPECIAL:
			return "特殊物"
	return "未知类型"


static func _take(items: Array, _count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_value in items:
		if item_value is Dictionary:
			result.append((item_value as Dictionary).duplicate(true))
	return result
