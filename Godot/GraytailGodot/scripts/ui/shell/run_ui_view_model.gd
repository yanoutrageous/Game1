extends RefCounted
class_name RunUIViewModel


static func format_expedition_summary(snapshot: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Run Summary")
	lines.append("")
	lines.append("run_black_coin: %s | safe_yield: %s | long_term_gold preview: %s" % [
		snapshot.get("run_black_coin", snapshot.get("black_coin", 0)),
		snapshot.get("safe_yield", snapshot.get("gold_coin", 0)),
		snapshot.get("long_term_gold_preview", snapshot.get("long_term_gold", 0)),
	])
	lines.append("Backpack: %s/%s | GroundLoot: %s" % [
		snapshot.get("backpack_used", 0),
		snapshot.get("backpack_capacity", 0),
		snapshot.get("room_floor_item_count", 0),
	])
	lines.append("HP: %s/%s | protocol pressure: %s | protocol level: %s" % [
		snapshot.get("hp", 0),
		snapshot.get("max_hp", 0),
		snapshot.get("pressure", 0),
		snapshot.get("protocol_level", 0),
	])
	lines.append("Current block: %s" % reason_label(String(snapshot.get("blocked_reason", ""))))
	return _join_lines(lines)


static func format_long_term_summary(snapshot: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Meta / Warehouse Summary")
	lines.append("")
	lines.append("long_term_gold: %s" % snapshot.get("long_term_gold", snapshot.get("gold", 0)))
	lines.append("warehouse_items: %s" % snapshot.get("warehouse_items_count", _array_from(snapshot, "warehouse_items").size()))
	lines.append("run_count: %s | extract_count: %s | fail_count: %s | abandon_count: %s" % [
		snapshot.get("run_count", 0),
		snapshot.get("extract_count", 0),
		snapshot.get("fail_count", 0),
		snapshot.get("abandon_count", 0),
	])
	lines.append("M3 reads MetaProgress and warehouse_items; this view does not recalculate settlement.")
	return _join_lines(lines)


static func item_display_line(item: Dictionary) -> String:
	var display_name: String = String(item.get("display_name", item.get("item_id", "item")))
	var item_type: String = String(item.get("item_type", item.get("main_type", "item")))
	var rarity: String = String(item.get("rarity", "tier_1"))
	var weight: Variant = item.get("weight", 1)
	var value: Variant = item.get("base_value", 0)
	return "%s  %s  %s  重%s  值%s" % [display_name, _item_type_label(item_type), _rarity_label(rarity), weight, value]


static func item_tooltip(item: Dictionary) -> String:
	if item.is_empty():
		return "尚未选择物品。"
	var tags: Array = _array_from(item, "tags")
	var lines: Array[String] = []
	lines.append(item_display_line(item))
	if String(item.get("short_description", "")) != "":
		lines.append(String(item.get("short_description", "")))
	if int(item.get("collectible_level", 0)) > 0:
		lines.append("收藏等级：%s" % item.get("collectible_level", 0))
	if bool(item.get("can_consume", false)):
		lines.append("可使用：%s %s" % [_effect_kind_label(String(item.get("effect_kind", ""))), item.get("effect_amount", 0)])
	if bool(item.get("can_equip", false)):
		lines.append("可装备：%s" % _equipment_slot_label(String(item.get("equipment_slot", ""))))
	if not tags.is_empty():
		lines.append("标签：%s" % _join_variants(tags, " / "))
	return _join_lines(lines)


static func _item_type_label(item_type: String) -> String:
	match item_type:
		"consumable":
			return "消耗品"
		"equipment":
			return "装备"
		"recovered", "treasure":
			return "回收物"
		"currency":
			return "货币"
		_:
			return "物资"


static func _rarity_label(rarity: String) -> String:
	match rarity:
		"tier_1", "common":
			return "普通"
		"tier_2", "uncommon":
			return "优良"
		"tier_3", "rare":
			return "稀有"
		"tier_4", "epic":
			return "珍贵"
		"tier_5", "legendary":
			return "传奇"
		_:
			return "未鉴定"


static func _effect_kind_label(effect_kind: String) -> String:
	match effect_kind:
		"heal":
			return "恢复生命"
		"pressure_down":
			return "降低压力"
		"power_up":
			return "提升战力"
		_:
			return "效果"


static func _equipment_slot_label(slot: String) -> String:
	match slot:
		"weapon":
			return "武器位"
		"armor":
			return "护甲位"
		"trinket":
			return "饰品位"
		_:
			return "装备位"


static func command_result_text(result: Dictionary) -> String:
	if result.is_empty():
		return ""
	var accepted: bool = bool(result.get("accepted", result.get("ok", false)))
	var reason: String = String(result.get("reason_code", result.get("blocked_reason", result.get("reason", ""))))
	if accepted:
		var message := String(result.get("message", ""))
		if message != "":
			return _player_message(message)
		if result.has("item"):
			var item: Dictionary = _dict_from(result, "item")
			return "操作完成：%s。" % String(item.get("display_name", item.get("item_id", "item")))
		return "操作完成。"
	return "操作受阻：%s" % reason_label(reason)


static func player_message(message: String) -> String:
	return _player_message(message)


static func reason_label(reason_code: String) -> String:
	var normalized := reason_code.strip_edges()
	if normalized == "":
		return "这里暂时没有可交互目标。"
	if normalized.find("search") >= 0:
		return "当前位置不可搜索。"
	if normalized.find("bound") >= 0 or normalized.find("position") >= 0:
		return "请先移动到有效位置。"
	match normalized:
		"tutorial_lock":
			return "请先确认当前提示。"
		"invalid_direction":
			return "只能向四个方向移动。"
		"out_of_bounds":
			return "目标超出地图范围。"
		"blocked_hidden":
			return "目标房间尚未公开。"
		"blocked_flagged":
			return "目标已被标记为风险。"
		"blocked_capacity":
			return "背包容量不足。"
		"no_room_floor_items":
			return "当前房间没有可拾取物。"
		"no_inventory_items":
			return "背包中没有可用物品。"
		"no_consumable_item":
			return "背包中没有可使用消耗品。"
		"item_not_consumable":
			return "该物品不能直接使用。"
		"item_not_in_inventory":
			return "该物品不在背包中。"
		"room_unrevealed":
			return "目标房间尚未公开。"
		"room_not_searchable":
			return "当前位置不可搜索。"
		"spawn_not_searchable":
			return "出生点不可搜索。"
		"cannot_extract":
			return "只有撤离点可以撤离。"
		"no_extract_request":
			return "尚未发起撤离请求。"
		"event_option_unavailable":
			return "当前事件选项不可用。"
		"combat_unavailable":
			return "这里没有可清理威胁。"
		"no_active_asset_ledger":
			return "当前物资记录不可用。"
		_:
			return "当前操作暂时不可执行。"


static func compact_event_log(snapshot: Dictionary, max_count: int = 5) -> Array[String]:
	var events: Array = _array_from(snapshot, "event_log")
	var lines: Array[String] = []
	var start_index: int = max(0, events.size() - max_count)
	for index in range(start_index, events.size()):
		var event: Dictionary = events[index]
		lines.append("#%s event %s / source %s" % [event.get("sequence", index), event.get("event_type", "event"), event.get("source", "")])
	return lines


static func compact_transaction_log(snapshot: Dictionary, max_count: int = 5) -> Array[String]:
	var transactions: Array = _array_from(snapshot, "transaction_log")
	var lines: Array[String] = []
	var start_index: int = max(0, transactions.size() - max_count)
	for index in range(start_index, transactions.size()):
		var transaction: Dictionary = transactions[index]
		var currency_delta: Dictionary = _dict_from(transaction, "currency_delta")
		var moves: Array = _array_from(transaction, "item_moves")
		lines.append("#%s action %s | currency %s | item moves %s" % [
			transaction.get("sequence", index),
			transaction.get("action", "transaction"),
			currency_delta,
			moves.size(),
		])
	return lines


static func result_summary(snapshot: Dictionary) -> Dictionary:
	var outcome: String = String(snapshot.get("outcome", "Running"))
	var settlement: Dictionary = _dict_from(snapshot, "settlement")
	var settlement_outcome := String(settlement.get("outcome", snapshot.get("settlement_outcome", "")))
	var title := "探索结算"
	if outcome == "Extracted" or settlement_outcome == "success":
		title = "撤离成功"
	elif outcome == "Failed" or settlement_outcome == "failure":
		title = "探索失败"
	elif outcome == "Abandoned" or settlement_outcome == "abandon":
		title = "探索中止"
	var lines: Array[String] = []
	lines.append("状态：%s" % _outcome_label(outcome, settlement_outcome))
	lines.append("本局黑币：%s | 安全收益：%s | 长期金币：%s" % [
		snapshot.get("run_black_coin", snapshot.get("black_coin", 0)),
		settlement.get("safe_yield", snapshot.get("safe_yield", snapshot.get("gold_coin", 0))),
		settlement.get("long_term_gold_gained", snapshot.get("long_term_gold_gained", 0)),
	])
	lines.append("背包：%s/%s | 地面遗留：%s" % [
		snapshot.get("backpack_used", 0),
		snapshot.get("backpack_capacity", 0),
		_array_from(settlement, "room_floor_lost_items").size(),
	])
	lines.append("入库：%s | 抢救：%s | 损失：%s" % [
		_array_from(settlement, "warehouse_lite").size(),
		_array_from(settlement, "salvaged_items").size(),
		_array_from(settlement, "lost_items").size(),
	])
	if bool(settlement.get("safe_yield_pending", false)) or String(settlement.get("safe_yield_state", "")) != "":
		lines.append("安全收益：%s" % _settlement_state_label(String(settlement.get("safe_yield_state", "pending_undecided"))))
	var meta_commit: Dictionary = _dict_from(snapshot, "meta_progress_commit")
	if not meta_commit.is_empty():
		lines.append("长期记录：%s" % ("已记录" if not bool(meta_commit.get("duplicate", false)) else "已存在记录"))
	lines.append("")
	lines.append("事件记录")
	lines.append_array(compact_event_log(snapshot))
	lines.append("")
	lines.append("物资流转")
	lines.append_array(compact_transaction_log(snapshot))
	return {
		"title": title,
		"summary": _join_lines(lines),
	}


static func reward_text(reward: Dictionary, last_message: String = "") -> String:
	var lines: Array[String] = []
	if last_message != "":
		lines.append(_player_message(last_message))
	if reward.has("black_coin_delta"):
		lines.append("本局黑币 %s" % _signed_value(reward.get("black_coin_delta", 0)))
	if reward.has("safe_yield_delta"):
		lines.append("安全收益 %s" % _signed_value(reward.get("safe_yield_delta", 0)))
	elif reward.has("gold_coin_delta"):
		lines.append("安全收益 %s" % _signed_value(reward.get("gold_coin_delta", 0)))
	if reward.has("pending_gold_delta"):
		lines.append("待结算收益 %s" % _signed_value(reward.get("pending_gold_delta", 0)))
	if reward.has("safe_yield"):
		lines.append("安全收益合计：%s" % reward.get("safe_yield", 0))
	elif reward.has("safe_gold"):
		lines.append("安全收益合计：%s" % reward.get("safe_gold", 0))
	if reward.has("damage"):
		lines.append("受到伤害：%s" % reward.get("damage", 0))
	if reward.has("hp_delta"):
		lines.append("生命 %s" % _signed_value(reward.get("hp_delta", 0)))
	if reward.has("effect_kind"):
		lines.append("%s %s" % [_effect_kind_label(String(reward.get("effect_kind", ""))), _signed_value(reward.get("effect_amount", 0))])
	var inventory_items: Array = _array_from(reward, "inventory_items")
	var equipped_items: Array = _array_from(reward, "equipped_items")
	var ground_items: Array = _array_from(reward, "ground_items")
	if not inventory_items.is_empty():
		lines.append("进入背包：%s 件" % inventory_items.size())
	if not equipped_items.is_empty():
		lines.append("已装备：%s 件" % equipped_items.size())
	if not ground_items.is_empty():
		lines.append("落在地面：%s 件" % ground_items.size())
	var items: Array = _array_from(reward, "items")
	if not items.is_empty() and inventory_items.is_empty() and equipped_items.is_empty() and ground_items.is_empty():
		lines.append("物品变化：%s 件" % items.size())
	if reward.has("capacity"):
		var capacity: Dictionary = _dict_from(reward, "capacity")
		lines.append("背包：%s/%s" % [capacity.get("used", 0), capacity.get("capacity", 0)])
	var reason: String = String(reward.get("blocked_reason", reward.get("reason", "")))
	if reason != "":
		lines.append("操作受阻：%s" % reason_label(reason))
	if reward.has("roll"):
		lines.append("判定点数：%s" % reward.get("roll", 0))
	if lines.is_empty():
		lines.append("暂无新的回收记录。")
	return _join_lines(lines)


static func _player_message(message: String) -> String:
	var text := message.strip_edges()
	if text == "":
		return ""
	if text.find("Map overlay") >= 0 and text.find("opened") >= 0:
		return "已打开大地图。"
	text = text.replace("black coin", "本局黑币")
	text = text.replace("gold_coin", "安全收益")
	text = text.replace("gold coin", "安全收益")
	text = text.replace("on room floor", "留在地面")
	text = text.replace("Search complete:", "搜索完成：")
	text = text.replace("Monster cleared:", "威胁已清理：")
	text = text.replace("Mine triggered:", "触发陷阱：")
	text = text.replace("Extraction requires an exit room.", "只有撤离点可以撤离。")
	text = text.replace("Current room cannot be searched.", "当前位置不可搜索。")
	text = text.replace("Spawn room cannot be searched.", "出发点不可搜索。")
	text = text.replace("Entered Spawn room. Adjacent mines:", "进入出发点。周边雷险：")
	text = text.replace("Entered Normal room. Adjacent mines:", "进入普通房间。周边雷险：")
	text = text.replace("Entered Mine room. Adjacent mines:", "进入雷险房间。周边雷险：")
	text = text.replace("Entered Chest room. Adjacent mines:", "进入物资房间。周边雷险：")
	text = text.replace("Entered Event room. Adjacent mines:", "进入事件房间。周边雷险：")
	text = text.replace("Entered Monster room. Adjacent mines:", "进入威胁房间。周边雷险：")
	text = text.replace("Entered Exit room. Adjacent mines:", "进入撤离点。周边雷险：")
	return text


static func _outcome_label(outcome: String, settlement_outcome: String) -> String:
	if outcome == "Extracted" or settlement_outcome == "success":
		return "撤离成功"
	if outcome == "Failed" or settlement_outcome == "failure":
		return "探索失败"
	if outcome == "Abandoned" or settlement_outcome == "abandon":
		return "探索中止"
	return "探索中"


static func _settlement_state_label(state: String) -> String:
	match state:
		"pending_undecided", "pending":
			return "待结算"
		"safe", "confirmed":
			return "已结算"
		_:
			return "待确认"


static func _signed_value(value: Variant) -> String:
	var number := int(value)
	return "+%d" % number if number > 0 else "%d" % number


static func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


static func _dict_from(source: Dictionary, key: String) -> Dictionary:
	var raw: Variant = source.get(key, {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return {}


static func _join_lines(lines: Array[String]) -> String:
	var text := ""
	for index in range(lines.size()):
		if index > 0:
			text += "\n"
		text += lines[index]
	return text


static func _join_variants(values: Array, separator: String) -> String:
	var text := ""
	for index in range(values.size()):
		if index > 0:
			text += separator
		text += String(values[index])
	return text
