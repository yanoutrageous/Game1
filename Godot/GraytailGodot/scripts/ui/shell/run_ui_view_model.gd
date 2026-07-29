extends RefCounted
class_name RunUIViewModel

const ItemRarityDescriptorScript := preload("res://scripts/presentation/item_rarity_descriptor.gd")


static func format_expedition_summary(snapshot: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Run Summary")
	lines.append("")
	lines.append("run black resource: %s | gold resource: %s" % [
		snapshot.get("run_black_coin", snapshot.get("black_coin", 0)),
		snapshot.get("gold_coin", snapshot.get("safe_yield", 0)),
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


static func item_presentation(item: Dictionary) -> Dictionary:
	if item.is_empty():
		return {
			"display_name": "未命名物资",
			"rarity": ItemRarityDescriptorScript.describe(&"unknown"),
			"rarity_text": "[?] 未鉴定",
			"collectible_level": 0,
			"collectible_level_text": "",
			"quantity": 0,
			"weight": 0,
			"base_value": 0,
			"type_label": "物资",
			"short_description": "",
			"summary_text": "暂无物资",
			"display_line": "暂无物资",
			"detail_text": "尚未选择物品。",
			"read_only": true,
		}
	var display_name := item_display_name(item)
	var item_type := String(item.get("item_type", item.get("main_type", "item")))
	var type_label := _item_type_label(item_type)
	var rarity: Dictionary = ItemRarityDescriptorScript.describe_item(item)
	var rarity_text := String(rarity.get("display_text", "[?] 未鉴定"))
	var quantity := item_quantity(item)
	var weight: Variant = item.get("weight", 1)
	var base_value: Variant = item.get("base_value", 0)
	var short_description := String(item.get("short_description", item.get("description", ""))).strip_edges()
	var collectible_level := maxi(0, int(item.get("collectible_level", 0)))
	var collectible_level_text := "收藏等级 %d" % collectible_level if collectible_level > 0 else ""
	var collection_summary := "  %s" % collectible_level_text if collectible_level_text != "" else ""
	var summary_text := "%s  %s%s  ×%d  重%s" % [display_name, rarity_text, collection_summary, quantity, weight]
	var quantity_text := "  ×%d" % quantity if quantity > 1 else ""
	var display_line := "%s  %s  %s%s%s  重%s  值%s" % [
		display_name,
		type_label,
		rarity_text,
		collection_summary,
		quantity_text,
		weight,
		base_value,
	]
	var rarity_line := "品质：%s" % rarity_text
	if collectible_level > 0:
		rarity_line += "　收藏等级：%d" % collectible_level
	var detail_lines: Array[String] = [
		display_name,
		rarity_line,
		"重量：%s　数量：%d" % [weight, quantity],
	]
	if short_description != "":
		detail_lines.append(short_description)
	if bool(item.get("can_consume", false)):
		detail_lines.append("可使用：%s %s" % [_effect_kind_label(String(item.get("effect_kind", ""))), item.get("effect_amount", 0)])
	if bool(item.get("can_equip", false)):
		detail_lines.append("可装备：%s" % _equipment_slot_label(String(item.get("equipment_slot", ""))))
	return {
		"display_name": display_name,
		"rarity": rarity.duplicate(true),
		"rarity_text": rarity_text,
		"collectible_level": collectible_level,
		"collectible_level_text": collectible_level_text,
		"quantity": quantity,
		"weight": weight,
		"base_value": base_value,
		"type_label": type_label,
		"short_description": short_description,
		"summary_text": summary_text,
		"display_line": display_line,
		"detail_text": _join_lines(detail_lines),
		"read_only": true,
	}


static func item_display_line(item: Dictionary) -> String:
	return String(item_presentation(item).get("display_line", "暂无物资"))


static func item_display_name(item: Dictionary, fallback: String = "未命名物资") -> String:
	var display_name := String(item.get("display_name", "")).strip_edges()
	var item_id := String(item.get("item_id", "")).strip_edges()
	if display_name.is_empty() or (not item_id.is_empty() and display_name == item_id):
		return fallback
	return display_name


static func item_tooltip(item: Dictionary) -> String:
	# `tags` drive rules, drop tables and codex grouping.  They are not localized
	# player copy and must not leak strings such as `collectible / level_4` into
	# the in-run art surface. Type, rarity, description and explicit effects
	# already carry the useful information.
	return String(item_presentation(item).get("detail_text", "尚未选择物品。"))


static func item_quantity(item: Dictionary) -> int:
	for key: String in ["quantity", "stack_count", "count"]:
		if item.has(key):
			return maxi(1, int(item.get(key, 1)))
	return 1


static func aggregate_item_projection(items_variant: Variant) -> Array[Dictionary]:
	var items: Array = items_variant if items_variant is Array else []
	var stack_order: Array[String] = []
	var stacks: Dictionary = {}
	for raw_item in items:
		if not (raw_item is Dictionary):
			continue
		var item := (raw_item as Dictionary).duplicate(true)
		if item.is_empty():
			continue
		var stack_key := item_stack_key(item)
		if not stacks.has(stack_key):
			var first_ids := _item_instance_ids(item)
			var first_quantity := item_quantity(item)
			item["stack_key"] = stack_key
			item["instance_ids"] = first_ids
			item["instance_id"] = first_ids[0] if not first_ids.is_empty() else String(item.get("instance_id", ""))
			item["quantity"] = first_quantity
			item["stack_count"] = first_quantity
			item["exact_instance_count"] = first_ids.size()
			item["unit_weight"] = maxi(0, int(item.get("weight", 0)))
			item["total_weight"] = maxi(0, int(item.get("weight", 0))) * first_quantity
			stacks[stack_key] = item
			stack_order.append(stack_key)
			continue
		var stack := (stacks[stack_key] as Dictionary).duplicate(true)
		var next_ids: Array[String] = []
		for raw_instance_id in stack.get("instance_ids", []):
			var existing_id := String(raw_instance_id)
			if existing_id != "" and not next_ids.has(existing_id):
				next_ids.append(existing_id)
		for next_id in _item_instance_ids(item):
			if next_id != "" and not next_ids.has(next_id):
				next_ids.append(next_id)
		next_ids.sort()
		var next_quantity := int(stack.get("quantity", 0)) + item_quantity(item)
		stack["instance_ids"] = next_ids
		stack["instance_id"] = next_ids[0] if not next_ids.is_empty() else String(stack.get("instance_id", ""))
		stack["quantity"] = next_quantity
		stack["stack_count"] = next_quantity
		stack["exact_instance_count"] = next_ids.size()
		stack["total_weight"] = maxi(0, int(stack.get("unit_weight", stack.get("weight", 0)))) * next_quantity
		stacks[stack_key] = stack
	var result: Array[Dictionary] = []
	for stack_key in stack_order:
		var stack := (stacks[stack_key] as Dictionary).duplicate(true)
		var sorted_ids: Array[String] = []
		for raw_instance_id in stack.get("instance_ids", []):
			var instance_id := String(raw_instance_id)
			if instance_id != "" and not sorted_ids.has(instance_id):
				sorted_ids.append(instance_id)
		sorted_ids.sort()
		stack["instance_ids"] = sorted_ids
		stack["instance_id"] = sorted_ids[0] if not sorted_ids.is_empty() else String(stack.get("instance_id", ""))
		stack["exact_instance_count"] = sorted_ids.size()
		result.append(stack)
	return result


static func item_stack_key(item: Dictionary) -> String:
	var semantic_item := item.duplicate(true)
	for transient_key in [
		"instance_id",
		"instance_ids",
		"quantity",
		"stack_count",
		"count",
		"exact_instance_count",
		"total_weight",
		"stack_key",
		"room_pos",
	]:
		semantic_item.erase(transient_key)
	var key := _stable_variant_text(semantic_item)
	if bool(item.get("is_unique", false)):
		key += "|unique_instance=%s" % String(item.get("instance_id", ""))
	return key


static func _item_instance_ids(item: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var raw_ids: Variant = item.get("instance_ids", [])
	if raw_ids is Array:
		for raw_id in raw_ids:
			var instance_id := String(raw_id)
			if instance_id != "" and not result.has(instance_id):
				result.append(instance_id)
	var direct_id := String(item.get("instance_id", ""))
	if direct_id != "" and not result.has(direct_id):
		result.append(direct_id)
	result.sort()
	return result


static func _stable_variant_text(value: Variant) -> String:
	if value is Dictionary:
		var dictionary := value as Dictionary
		var keys: Array[String] = []
		for raw_key in dictionary.keys():
			keys.append(String(raw_key))
		keys.sort()
		var entries: Array[String] = []
		for key in keys:
			entries.append("%s:%s" % [JSON.stringify(key), _stable_variant_text(dictionary.get(key))])
		return "{%s}" % ",".join(entries)
	if value is Array:
		var entries: Array[String] = []
		for entry in value:
			entries.append(_stable_variant_text(entry))
		return "[%s]" % ",".join(entries)
	if value is StringName:
		return JSON.stringify(String(value))
	return JSON.stringify(value)


static func _item_type_label(item_type: String) -> String:
	match item_type:
		"consumable":
			return "消耗品"
		"equipment":
			return "装备"
		"collectible":
			return "藏品"
		"special":
			return "特殊物资"
		"recovered", "treasure":
			return "回收物"
		"currency":
			return "货币"
		_:
			return "物资"


static func _rarity_label(rarity: String) -> String:
	return String(ItemRarityDescriptorScript.describe(rarity).get("label", "未鉴定"))


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
	var action_result: Dictionary = result.get("action_result", {}) as Dictionary
	var detail := action_result if not action_result.is_empty() else result
	var reason: String = String(detail.get(
		"reason_code",
		detail.get("blocked_reason", detail.get("reason", result.get("reason_code", result.get("reason", ""))))
	))
	if accepted:
		var status := StringName(detail.get("status", detail.get("rule_result", result.get("status", &""))))
		var item: Dictionary = _dict_from(detail, "item")
		var item_name := item_display_name(item)
		match status:
			&"picked_up":
				return "已拾取：%s。" % item_name
			&"dropped":
				return "已放下：%s。" % item_name
			&"replaced":
				var dropped: Dictionary = _dict_from(detail, "dropped_item")
				return "已收起%s，放下%s。" % [
					item_name,
					item_display_name(dropped),
				]
			&"consumed":
				return "已使用：%s。" % item_name
			&"equipped":
				return "已装备：%s。" % item_name
			&"unequipped":
				return "已卸下：%s。" % item_name
		var message := String(detail.get("message", result.get("message", "")))
		if message != "":
			return _player_message(message)
		if not item.is_empty():
			return "已更新：%s。" % item_name
		return ""
	var blocked_message := String(detail.get("message", result.get("message", "")))
	if blocked_message != "":
		return _player_message(blocked_message)
	return "操作受阻：%s" % reason_label(reason)


static func player_message(message: String, event_state: Dictionary = {}) -> String:
	return _player_message(message, event_state)


static func event_room_entry_message(event_state: Dictionary) -> String:
	var event_type := StringName(event_state.get("event_type", &"event"))
	var event_label := "异常事件"
	match event_type:
		&"trader", &"traveler", &"merchant":
			event_label = "旅商"
		&"dice":
			event_label = "骰局"
		&"altar":
			event_label = "祭坛"
		&"trap":
			event_label = "机关"
	return "附近发现%s，靠近事件标记后可查看处理方式。" % event_label


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
			return "目标房间尚未探明。"
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
			return "目标房间尚未探明。"
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
	var outcome := String(snapshot.get("outcome", "Running"))
	var settlement := _dict_from(snapshot, "settlement")
	var settlement_outcome := String(settlement.get("outcome", snapshot.get("settlement_outcome", "")))
	var result_state := _result_state(outcome, settlement_outcome)
	var title := _result_title(result_state)
	var terminal_reason_code := StringName(snapshot.get("terminal_reason_code", &""))
	var reason_text := _terminal_reason_text(result_state, terminal_reason_code)
	var awaiting_salvage := bool(settlement.get("requires_salvage_selection", false)) and not bool(settlement.get("finalized", false))
	var persistence_state := _result_persistence_state(snapshot, awaiting_salvage)
	var normal_exit_allowed := bool(snapshot.get("normal_exit_allowed", persistence_state in [&"committed", &"duplicate_ignored"]))
	var retry_save_allowed := bool(snapshot.get("retry_save_allowed", not awaiting_salvage and not normal_exit_allowed))
	var discard_unsaved_allowed := bool(snapshot.get("discard_unsaved_allowed", not awaiting_salvage and not normal_exit_allowed))
	var currency_metrics := _result_currency_metrics(result_state, settlement)
	var item_sections := _result_item_sections(result_state, settlement)
	var salvage_candidates := result_item_models(_array_from(settlement, "settlement_pool"))
	var lines: Array[String] = []
	lines.append(reason_text)
	if awaiting_salvage:
		lines.append("请选择要带回的物资；确认前，本次结果不会保存。")
	else:
		lines.append(_persistence_text(persistence_state))
	return {
		"title": title,
		"summary": _join_lines(lines),
		"result_state": result_state,
		"reason_text": reason_text,
		"terminal_reason_code": terminal_reason_code,
		"currency_metrics": currency_metrics,
		"item_sections": item_sections,
		"awaiting_salvage": awaiting_salvage,
		"salvage_candidates": salvage_candidates,
		"salvage_capacity": int(settlement.get("salvage_capacity", 0)),
		"persistence_state": persistence_state,
		"persistence_text": _persistence_text(persistence_state),
		"normal_exit_allowed": normal_exit_allowed,
		"retry_save_allowed": retry_save_allowed,
		"discard_unsaved_allowed": discard_unsaved_allowed,
		"discard_unsaved_confirmation_count": int(snapshot.get("discard_unsaved_confirmation_count", 2)),
	}


static func result_item_models(items: Array) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	for raw_item in items:
		if raw_item is Dictionary:
			models.append(result_item_model(raw_item))
	return models


static func result_item_model(item: Dictionary) -> Dictionary:
	var presentation := item_presentation(item)
	return {
		"instance_id": String(item.get("instance_id", "")),
		"display_name": String(presentation.get("display_name", "未命名物资")),
		"short_description": String(presentation.get("short_description", "")),
		"weight": maxi(0, int(presentation.get("weight", 1))),
		"rarity": (presentation.get("rarity", {}) as Dictionary).duplicate(true),
		"collectible_level": maxi(0, int(presentation.get("collectible_level", 0))),
		"collectible_level_text": String(presentation.get("collectible_level_text", "")),
		"detail_text": String(presentation.get("detail_text", "")),
		"source_item": item.duplicate(true),
	}


static func _result_state(outcome: String, settlement_outcome: String) -> StringName:
	if outcome in ["Extracted", "Training Complete"] or settlement_outcome == "success":
		return &"success"
	if outcome == "Failed" or settlement_outcome == "failure":
		return &"failure"
	if outcome == "Abandoned" or settlement_outcome == "abandon":
		return &"abandon"
	return &"unknown"


static func _result_title(result_state: StringName) -> String:
	match result_state:
		&"success":
			return "撤离成功"
		&"failure":
			return "探索失败"
		&"abandon":
			return "已放弃探索"
		_:
			return "探索结算"


static func _terminal_reason_text(result_state: StringName, reason_code: StringName) -> String:
	if result_state == &"success":
		return "已抵达撤离点，带回的收益与物资如下。"
	if result_state == &"abandon":
		return "你主动结束了本次探索，未能带回的内容如下。"
	var reason := String(reason_code)
	if reason in ["mine", "fatal_mine", "mine_triggered"]:
		return "雷险使生命值归零，本次探索中断。"
	if reason == "hp_depleted":
		return "生命值归零，本次探索中断。"
	if reason == "monster" or reason == "runtime_combat_defeat" or reason.begins_with("runtime_combat_"):
		return "你在与异常体的交战中失去行动能力。"
	if reason.begins_with("event_"):
		return "事件造成致命后果，本次探索中断。"
	return "作业信号中断，本次探索未能完成。"


static func _result_currency_metrics(result_state: StringName, settlement: Dictionary) -> Array[Dictionary]:
	if result_state == &"success":
		return [
			{"label": "黑资转化", "value": int(settlement.get("black_coin_converted", 0)), "tone": &"positive"},
			{"label": "已锁定收益", "value": int(settlement.get("safe_yield_retained", settlement.get("safe_yield", 0))), "tone": &"positive"},
			{"label": "结算收益", "value": int(settlement.get("gold_coin_gained", 0)), "tone": &"positive"},
		]
	return [
		{"label": "黑资损失", "value": int(settlement.get("black_coin_lost", 0)), "tone": &"negative"},
		{"label": "已锁定收益", "value": int(settlement.get("safe_yield_retained", settlement.get("safe_yield", 0))), "tone": &"positive"},
		{"label": "可保留收益", "value": int(settlement.get("gold_coin_gained", settlement.get("safe_yield", 0))), "tone": &"positive"},
	]


static func _result_item_sections(result_state: StringName, settlement: Dictionary) -> Array[Dictionary]:
	var sections: Array[Dictionary] = []
	if result_state == &"success":
		sections.append(_result_item_section(&"warehouse_items", "带回仓库", _array_from(settlement, "warehouse_items")))
	else:
		sections.append(_result_item_section(&"salvaged_items", "已保全", _array_from(settlement, "salvaged_items")))
		sections.append(_result_item_section(&"lost_items", "未能带回", _array_from(settlement, "lost_items")))
	sections.append(_result_item_section(&"room_floor_lost_items", "遗留在现场", _array_from(settlement, "room_floor_lost_items")))
	sections.append(_result_item_section(&"cleared_consumables", "已消耗或清除", _array_from(settlement, "cleared_consumables")))
	return sections


static func _result_item_section(section_id: StringName, title: String, items: Array) -> Dictionary:
	return {
		"section_id": section_id,
		"title": title,
		"items": result_item_models(items),
		"count": items.size(),
	}


static func _result_persistence_state(snapshot: Dictionary, awaiting_salvage: bool) -> StringName:
	if awaiting_salvage:
		return &"awaiting_salvage_confirmation"
	var explicit_state := StringName(snapshot.get("persistence_state", &""))
	if explicit_state != &"":
		return explicit_state
	var commit := _dict_from(snapshot, "meta_progress_commit")
	var status := StringName(commit.get("status", &""))
	match status:
		&"committed", &"duplicate_ignored", &"save_failed", &"write_blocked", &"meta_progress_adapter_missing":
			return status
		_:
			return &"missing"


static func _persistence_text(state: StringName) -> String:
	match state:
		&"committed":
			return "进度已保存。"
		&"duplicate_ignored":
			return "本次结果此前已保存，且未重复结算。"
		&"awaiting_salvage_confirmation":
			return "确认保全后才会保存本次结果。"
		&"write_blocked":
			return "档案暂时无法写入，本次结果尚未保存。"
		&"meta_progress_adapter_missing":
			return "暂时无法连接进度存储，本次结果尚未保存。"
		_:
			return "本次结果尚未保存，请重试。"


static func _legacy_result_summary_m5(snapshot: Dictionary) -> Dictionary:
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


static func _player_message(message: String, event_state: Dictionary = {}) -> String:
	var text := message.strip_edges()
	if text == "":
		return ""
	if text.begins_with("Run started:"):
		return "探索已开始。"
	if text.begins_with("Run failed:"):
		return "本次探索失败。请在结算页选择要保全的物资。"
	if text.begins_with("Run abandoned:"):
		return "已结束本次探索。"
	if text.begins_with("Salvage selection blocked:"):
		var salvage_reason := text.trim_prefix("Salvage selection blocked:").trim_suffix(".").strip_edges()
		return "无法确认保全选择：%s" % reason_label(salvage_reason)
	if text.begins_with("Return blocked:"):
		var return_reason := text.trim_prefix("Return blocked:").trim_suffix(".").strip_edges()
		return "暂时无法返回：%s" % reason_label(return_reason)
	for blocked_prefix in ["Pickup blocked:", "Replace blocked:", "Drop blocked:", "Use blocked:", "Equip blocked:", "Unequip blocked:"]:
		if text.begins_with(blocked_prefix):
			var blocked_reason := text.trim_prefix(blocked_prefix).trim_suffix(".").strip_edges()
			return "操作受阻：%s" % reason_label(blocked_reason)
	# Legacy room-entry messages carry raw event enums. The enum in that string
	# is never presentation authority: use the structured EventService projection
	# when available, and a generic player-safe fallback otherwise.
	if text.begins_with("Event available:"):
		return event_room_entry_message(event_state)
	if text.find("Map overlay") >= 0 and text.find("opened") >= 0:
		# `open_map` is retained only for existing progression accounting. The
		# visible overlay and focus transfer are already the complete feedback;
		# surfacing the legacy placeholder creates a redundant engineering toast.
		return ""
	match text:
		"Exit room ready. Request extraction.", "Exit ready. Request extraction.":
			return "已抵达撤离点，可确认撤离。"
		"Monster present. Fight is available.", "Monster requires fight command.":
			return "发现异常体，可开始清理。"
		"Chest can be searched.":
			return "发现物资箱，靠近后可查看内容。"
		"This room was already searched.":
			return "当前房间已搜索。"
		"Cannot search unrevealed room.":
			return "请先探明当前房间。"
		"This room cannot be searched.", "Current room cannot be searched.":
			return "当前位置不可搜索。"
		"Spawn cannot be searched.", "Spawn room cannot be searched.":
			return "出发点无需搜索。"
		"Mine room has no safe interaction.":
			return "雷险房间没有可安全执行的交互。"
		"Nothing to interact with here.":
			return "这里暂时没有可交互目标。"
		"No event option is available here.", "Encounter option unavailable.", "Event option unavailable.":
			return "当前没有可用的事件选项。"
		"No monster to fight here.":
			return "这里没有可清理的异常体。"
		"Monster already cleared.":
			return "当前房间的威胁已清理。"
		"Triggered mine re-entered; no damage.":
			return "该雷险已触发，本次经过不会再次受伤。"
		"Event already resolved.", "Event resolved.":
			return "当前事件已处理。"
		"Event left unresolved.":
			return "已离开事件，事件仍未处理。"
		"Extraction requested. Confirm or cancel.":
			return "已准备撤离，请确认或取消。"
		"No extraction request is active.":
			return "当前没有待确认的撤离请求。"
		"Extraction cancelled: not on exit.":
			return "已离开撤离点，本次撤离请求已取消。"
		"Extraction cancelled.":
			return "已取消撤离。"
		"Extraction complete.":
			return "撤离完成。"
		"Failure settlement confirmed.":
			return "失败结算已确认。"
		"Invalid move: only four-direction movement is allowed.":
			return "只能向四个方向移动。"
		"Blocked by map boundary.", "Teleport target is outside the map.":
			return "目标超出地图范围。"
		"Blocked by flag.":
			return "目标已被标记，取消标记后才能进入。"
		"Blocked: target is not revealed.":
			return "目标房间尚未探明。"
		"Item command completed.":
			return "物品操作已完成。"
	if text.begins_with("Flag toggled at "):
		return "已更新房间标记。"
	if text.begins_with("Teleported to explored room "):
		return "已回到选定的已探索房间。"
	if text.begins_with("Equipped item:"):
		return "已装备：%s" % text.trim_prefix("Equipped item:").strip_edges()
	if text.begins_with("Unequipped item:"):
		return "已卸下：%s" % text.trim_prefix("Unequipped item:").strip_edges()
	text = text.replace("black coin", "本局黑币")
	text = text.replace("black_coin", "本局黑币")
	text = text.replace("gold_coin", "安全收益")
	text = text.replace("gold coin", "安全收益")
	text = text.replace("on room floor", "留在地面")
	text = text.replace("Search complete:", "搜索完成：")
	text = text.replace("Picked up floor item:", "已拾取：")
	text = text.replace("Dropped inventory item:", "已放下：")
	text = text.replace("Replaced floor item: picked", "已收起")
	text = text.replace(", dropped", "，放下")
	text = text.replace("Consumable used.", "物品已使用。")
	text = text.replace("Combat hit:", "受到攻击：")
	text = text.replace("Fled combat: lost", "已撤出战斗：损失")
	text = text.replace("pending", "尚未锁定的")
	text = text.replace("item(s) left on this room floor.", "件物资留在当前房间。")
	text = text.replace("Monster cleared:", "威胁已清理：")
	text = text.replace("Mine triggered:", "触发陷阱：")
	text = text.replace("Altar exchange complete:", "祭坛交换完成：")
	text = text.replace("Altar stage", "祭坛阶段")
	text = text.replace("Sequence complete.", "流程已完成。")
	text = text.replace("Sequence can continue.", "还可继续。")
	text = text.replace("Trader treatment:", "治疗完成：")
	text = text.replace("Trader info:", "情报交易完成：")
	text = text.replace("nearby clue recorded.", "已记录附近线索。")
	text = text.replace("Mechanism opened:", "机关已开启：")
	text = text.replace("Mechanism triggered:", "机关触发：")
	text = text.replace("reward", "获得")
	text = text.replace("damage", "伤害")
	text = text.replace("items", "物品")
	text = text.replace("item", "物品")
	text = text.replace("pressure", "压力")
	text = text.replace("HP", "生命")
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
