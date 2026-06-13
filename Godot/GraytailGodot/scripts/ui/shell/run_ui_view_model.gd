extends RefCounted
class_name RunUIViewModel


static func format_expedition_summary(snapshot: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("出勤摘要")
	lines.append("")
	lines.append("黑币：%s | 金币：%s" % [snapshot.get("black_coin", 0), snapshot.get("gold_coin", 0)])
	lines.append("背包：%s/%s" % [snapshot.get("backpack_used", 0), snapshot.get("backpack_capacity", 0)])
	lines.append("地面物品：%s" % snapshot.get("room_floor_item_count", 0))
	lines.append("状态效果：%s" % _array_from(snapshot, "status_effects").size())
	lines.append("当前阻塞：%s" % reason_label(String(snapshot.get("blocked_reason", ""))))
	lines.append("")
	lines.append("推荐路线：探索安全房间，发现撤离点后确认带出背包与装备物品。")
	return _join_lines(lines)


static func format_long_term_summary(snapshot: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("长期摘要")
	lines.append("")
	lines.append("资历等级：1")
	lines.append("资历经验：0")
	lines.append("任务进度：占位")
	lines.append("图鉴进度：占位")
	lines.append("成就进度：占位")
	lines.append("研究进度：占位")
	lines.append("")
	lines.append("后续通过长期进度适配器接入，不在 G9 写持久化。")
	return _join_lines(lines)


static func item_display_line(item: Dictionary) -> String:
	var display_name: String = String(item.get("display_name", item.get("item_id", "item")))
	var item_type: String = String(item.get("item_type", "item"))
	var rarity: String = String(item.get("rarity", "common"))
	var weight: Variant = item.get("weight", 1)
	var value: Variant = item.get("base_value", 0)
	return "%s | 类型 %s | 品质 %s | 重量 %s | 估值 %s" % [display_name, item_type, rarity, weight, value]


static func item_tooltip(item: Dictionary) -> String:
	if item.is_empty():
		return "未选择物品。"
	var tags: Array = _array_from(item, "tags")
	var source: Dictionary = _dict_from(item, "source")
	var lines: Array[String] = []
	lines.append(item_display_line(item))
	lines.append("物品编号：%s" % String(item.get("instance_id", "")))
	lines.append("当前位置：%s" % String(item.get("location_state", "")))
	lines.append("来源记录：%s" % String(source.get("kind", source.get("source_id", "unknown"))))
	lines.append("标签：%s" % _join_variants(tags, ", "))
	return _join_lines(lines)


static func command_result_text(result: Dictionary) -> String:
	if result.is_empty():
		return ""
	var accepted: bool = bool(result.get("accepted", result.get("ok", false)))
	var reason: String = String(result.get("reason_code", result.get("blocked_reason", result.get("reason", ""))))
	var message_key: String = String(result.get("message_key", ""))
	if accepted:
		if message_key == "":
			return "操作完成。"
		return "操作完成：%s" % message_key
	if message_key == "":
		return "操作受阻：%s" % reason_label(reason)
	return "操作受阻：%s（%s）" % [reason_label(reason), message_key]


static func reason_label(reason_code: String) -> String:
	match reason_code:
		"":
			return "无"
		"tutorial_lock":
			return "教程提示需要先确认"
		"invalid_direction":
			return "非法移动方向"
		"out_of_bounds":
			return "超出地图边界"
		"blocked_hidden":
			return "目标房间尚未揭示"
		"blocked_flagged":
			return "目标已被标记"
		"blocked_capacity":
			return "背包容量不足"
		"no_room_floor_items":
			return "当前房间没有地面物品"
		"no_inventory_items":
			return "背包没有可丢弃物品"
		"room_unrevealed":
			return "当前房间尚未揭示"
		"room_not_searchable":
			return "当前房间不可搜索"
		"spawn_not_searchable":
			return "出发点不可搜索"
		"cannot_extract":
			return "当前位置不能撤离"
		"no_extract_request":
			return "没有待确认的撤离请求"
		"event_option_unavailable":
			return "事件选项不可用"
		"combat_unavailable":
			return "当前没有可处理的战斗"
		"no_active_asset_ledger":
			return "资产记录暂不可用"
		_:
			return reason_code


static func compact_event_log(snapshot: Dictionary, max_count: int = 5) -> Array[String]:
	var events: Array = _array_from(snapshot, "event_log")
	var lines: Array[String] = []
	var start_index: int = max(0, events.size() - max_count)
	for index in range(start_index, events.size()):
		var event: Dictionary = events[index]
		lines.append("#%s 事件：%s / 来源：%s" % [event.get("sequence", index), event.get("event_type", "event"), event.get("source", "")])
	return lines


static func compact_transaction_log(snapshot: Dictionary, max_count: int = 5) -> Array[String]:
	var transactions: Array = _array_from(snapshot, "transaction_log")
	var lines: Array[String] = []
	var start_index: int = max(0, transactions.size() - max_count)
	for index in range(start_index, transactions.size()):
		var transaction: Dictionary = transactions[index]
		var currency_delta: Dictionary = _dict_from(transaction, "currency_delta")
		var moves: Array = _array_from(transaction, "item_moves")
		lines.append("#%s 动作：%s | 货币变化 %s | 物品移动 %s" % [
			transaction.get("sequence", index),
			transaction.get("action", "transaction"),
			currency_delta,
			moves.size(),
		])
	return lines


static func result_summary(snapshot: Dictionary) -> Dictionary:
	var outcome: String = String(snapshot.get("outcome", "Running"))
	var title: String = "成功撤离" if outcome == "Extracted" else "信号中断"
	var lines: Array[String] = []
	lines.append("结果：%s" % outcome)
	lines.append("模式：%s" % String(snapshot.get("mode", &"")))
	lines.append("黑币：%s | 金币：%s" % [snapshot.get("black_coin", 0), snapshot.get("gold_coin", 0)])
	lines.append("背包：%s/%s" % [snapshot.get("backpack_used", 0), snapshot.get("backpack_capacity", 0)])
	lines.append("带出物品：%s | 装备：%s" % [_array_from(snapshot, "inventory_items").size(), _array_from(snapshot, "equipped_items").size()])
	lines.append("地面遗留：%s" % snapshot.get("room_floor_item_count", 0))
	lines.append("临时仓库记录：%s" % _array_from(snapshot, "warehouse_lite").size())
	var salvage: Dictionary = _dict_from(snapshot, "failure_salvage")
	if not salvage.is_empty():
		lines.append("失败抢救：保留 %s / 丢失 %s" % [salvage.get("salvaged_item_count", 0), salvage.get("lost_item_count", 0)])
	var settlement_log: Array = _array_from(snapshot, "settlement_log")
	lines.append("结算日志：%s 条" % settlement_log.size())
	lines.append("")
	lines.append("事件记录")
	lines.append_array(compact_event_log(snapshot))
	lines.append("")
	lines.append("资产记录")
	lines.append_array(compact_transaction_log(snapshot))
	return {
		"title": title,
		"summary": _join_lines(lines),
	}


static func reward_text(reward: Dictionary, last_message: String = "") -> String:
	var lines: Array[String] = []
	if last_message != "":
		lines.append("记录：%s" % _player_message(last_message))
	if reward.has("black_coin_delta"):
		lines.append("黑币变化：%s" % reward.get("black_coin_delta", 0))
	if reward.has("gold_coin_delta"):
		lines.append("金币变化：%s" % reward.get("gold_coin_delta", 0))
	if reward.has("pending_gold_delta"):
		lines.append("待结算收益：%s" % reward.get("pending_gold_delta", 0))
	if reward.has("safe_gold"):
		lines.append("安全收益：%s" % reward.get("safe_gold", 0))
	if reward.has("damage"):
		lines.append("受到伤害：%s" % reward.get("damage", 0))
	if reward.has("hp_delta"):
		lines.append("生命变化：%s" % reward.get("hp_delta", 0))
	var items: Array = _array_from(reward, "items")
	var ground_items: Array = _array_from(reward, "ground_items")
	if not items.is_empty():
		lines.append("进入背包：%s 件" % items.size())
	if not ground_items.is_empty():
		lines.append("落在地面：%s 件" % ground_items.size())
	if reward.has("capacity"):
		var capacity: Dictionary = _dict_from(reward, "capacity")
		lines.append("背包：%s/%s" % [capacity.get("used", 0), capacity.get("capacity", 0)])
	var reason: String = String(reward.get("blocked_reason", reward.get("reason", "")))
	if reason != "":
		lines.append("阻塞原因：%s" % reason_label(reason))
	if reward.has("roll"):
		lines.append("骰子点数：%s" % reward.get("roll", 0))
	if lines.is_empty():
		lines.append("没有新的奖励或变动。")
	return _join_lines(lines)


static func _player_message(message: String) -> String:
	var text := message.strip_edges()
	if text == "":
		return ""
	text = text.replace("Exit room ready. Request extraction.", "撤离点已就绪：可请求撤离。")
	text = text.replace("Exit ready. Request extraction.", "撤离点可用：再次确认后撤离。")
	text = text.replace("Monster present. Fight is available.", "发现异常体：可执行清理。")
	text = text.replace("Monster requires fight command.", "异常体活动中：需要清理指令。")
	text = text.replace("Monster already cleared.", "异常体已清理。")
	text = text.replace("No monster to fight here.", "当前房间没有可清理的异常体。")
	text = text.replace("Chest can be searched.", "发现未登记物资箱：可搜索。")
	text = text.replace("This room was already searched.", "当前房间已搜索。")
	text = text.replace("Cannot search unrevealed room.", "未揭示房间不可搜索。")
	text = text.replace("This room cannot be searched.", "当前房间不可搜索。")
	text = text.replace("Spawn cannot be searched.", "出发点不可搜索。")
	text = text.replace("No event option is available here.", "当前房间没有可用事件选项。")
	text = text.replace("Event already resolved.", "事件已处理。")
	text = text.replace("Event left unresolved.", "事件已暂时搁置。")
	text = text.replace("Event option unavailable.", "事件选项不可用。")
	text = text.replace("Mine room has no safe interaction.", "雷险房间没有安全交互。")
	text = text.replace("Nothing to interact with here.", "当前房间暂无可交互目标。")
	text = text.replace("Triggered mine re-entered; no damage.", "已确认雷险再次经过，不重复伤害。")
	text = text.replace("Search complete:", "搜索完成：")
	text = text.replace("Monster cleared:", "异常体已清理：")
	text = text.replace("Mine triggered:", "雷险触发：")
	text = text.replace("Event available:", "发现事件：")
	text = text.replace("Entered ", "进入")
	text = text.replace(" room. Adjacent mines:", "房间；周围雷险：")
	text = text.replace("black coin", "待结算黑币")
	text = text.replace("items", "物品")
	text = text.replace("on room floor", "留在地面")
	text = text.replace("damage", "伤害")
	text = text.replace("reward", "奖励")
	text = text.replace("pressure", "压力")
	text = text.replace("HP", "生命")
	return text


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
