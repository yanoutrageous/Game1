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
	var source_label := String(item.get("source_label", item.get("source", "unknown")))
	return "%s | type %s | tier %s | weight %s | value %s | source %s" % [display_name, item_type, rarity, weight, value, source_label]


static func item_tooltip(item: Dictionary) -> String:
	if item.is_empty():
		return "No item selected."
	var tags: Array = _array_from(item, "tags")
	var lines: Array[String] = []
	lines.append(item_display_line(item))
	if String(item.get("short_description", "")) != "":
		lines.append(String(item.get("short_description", "")))
	lines.append("instance_id: %s" % String(item.get("instance_id", "")))
	lines.append("location: %s" % String(item.get("location_state", "")))
	lines.append("source: %s" % String(item.get("source_label", item.get("source", "unknown"))))
	if int(item.get("collectible_level", 0)) > 0:
		lines.append("collectible level: %s" % item.get("collectible_level", 0))
	if bool(item.get("can_consume", false)):
		lines.append("consumable effect: %s %s" % [String(item.get("effect_kind", "")), item.get("effect_amount", 0)])
	if bool(item.get("can_equip", false)):
		lines.append("equipment slot: %s" % String(item.get("equipment_slot", "unassigned")))
	lines.append("tags: %s" % _join_variants(tags, ", "))
	return _join_lines(lines)


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
			return "Action complete: %s." % String(item.get("display_name", item.get("item_id", "item")))
		return "Action complete."
	return "Action blocked: %s." % reason_label(reason)


static func player_message(message: String) -> String:
	return _player_message(message)


static func reason_label(reason_code: String) -> String:
	var normalized := reason_code.strip_edges()
	if normalized == "":
		return "No interactable target here."
	if normalized.find("search") >= 0:
		return "Current room cannot be searched."
	if normalized.find("bound") >= 0 or normalized.find("position") >= 0:
		return "Move to a valid map position first."
	match normalized:
		"tutorial_lock":
			return "Tutorial popup must be confirmed first."
		"invalid_direction":
			return "Only four-direction movement is allowed."
		"out_of_bounds":
			return "Target is outside the map."
		"blocked_hidden":
			return "Target room is not revealed."
		"blocked_flagged":
			return "Target is flagged."
		"blocked_capacity":
			return "Backpack capacity is not enough."
		"no_room_floor_items":
			return "No GroundLoot in this room."
		"no_inventory_items":
			return "No backpack item is available."
		"no_consumable_item":
			return "No consumable item is in the backpack."
		"item_not_consumable":
			return "This item is not consumable."
		"item_not_in_inventory":
			return "This item is not in the backpack."
		"room_unrevealed":
			return "The room is not revealed."
		"room_not_searchable":
			return "The room cannot be searched."
		"spawn_not_searchable":
			return "The spawn room cannot be searched."
		"cannot_extract":
			return "Extraction is only available from an exit room."
		"no_extract_request":
			return "No extraction request is active."
		"event_option_unavailable":
			return "This event option is unavailable."
		"combat_unavailable":
			return "No combat is available here."
		"no_active_asset_ledger":
			return "Run asset ledger is not available."
		_:
			return normalized


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
	var title := "Run Result"
	if outcome == "Extracted" or settlement_outcome == "success":
		title = "Extraction Success"
	elif outcome == "Failed" or settlement_outcome == "failure":
		title = "Run Failed"
	elif outcome == "Abandoned" or settlement_outcome == "abandon":
		title = "Run Abandoned"
	var lines: Array[String] = []
	lines.append("outcome: %s" % outcome)
	lines.append("settlement_outcome: %s" % settlement_outcome)
	lines.append("mode: %s" % String(snapshot.get("mode", &"")))
	lines.append("run_black_coin: %s | safe_yield: %s | long_term_gold_gained: %s" % [
		snapshot.get("run_black_coin", snapshot.get("black_coin", 0)),
		settlement.get("safe_yield", snapshot.get("safe_yield", snapshot.get("gold_coin", 0))),
		settlement.get("long_term_gold_gained", snapshot.get("long_term_gold_gained", 0)),
	])
	lines.append("Backpack: %s/%s | GroundLoot lost: %s" % [
		snapshot.get("backpack_used", 0),
		snapshot.get("backpack_capacity", 0),
		_array_from(settlement, "room_floor_lost_items").size(),
	])
	lines.append("warehouse_items: %s | salvaged_items: %s | lost_items: %s" % [
		_array_from(settlement, "warehouse_lite").size(),
		_array_from(settlement, "salvaged_items").size(),
		_array_from(settlement, "lost_items").size(),
	])
	if bool(settlement.get("safe_yield_pending", false)) or String(settlement.get("safe_yield_state", "")) != "":
		lines.append("safe_yield_state: %s" % String(settlement.get("safe_yield_state", "pending_undecided")))
	lines.append("Debug used: %s" % ("yes" if bool(snapshot.get("debug_used", snapshot.get("debug_command_used", false))) else "no"))
	var meta_commit: Dictionary = _dict_from(snapshot, "meta_progress_commit")
	if not meta_commit.is_empty():
		var commit_state := "duplicate ignored" if bool(meta_commit.get("duplicate", false)) else "committed"
		lines.append("MetaProgress: %s | result_id=%s" % [commit_state, String(meta_commit.get("result_id", ""))])
	lines.append("")
	lines.append("Event log")
	lines.append_array(compact_event_log(snapshot))
	lines.append("")
	lines.append("Asset transactions")
	lines.append_array(compact_transaction_log(snapshot))
	return {
		"title": title,
		"summary": _join_lines(lines),
	}


static func reward_text(reward: Dictionary, last_message: String = "") -> String:
	var lines: Array[String] = []
	if last_message != "":
		lines.append("Log: %s" % _player_message(last_message))
	if reward.has("black_coin_delta"):
		lines.append("run_black_coin delta: %s" % reward.get("black_coin_delta", 0))
	if reward.has("safe_yield_delta"):
		lines.append("safe_yield delta: %s" % reward.get("safe_yield_delta", 0))
	elif reward.has("gold_coin_delta"):
		lines.append("safe_yield delta: %s" % reward.get("gold_coin_delta", 0))
	if reward.has("pending_gold_delta"):
		lines.append("pending run reward: %s" % reward.get("pending_gold_delta", 0))
	if reward.has("safe_yield"):
		lines.append("safe_yield total: %s" % reward.get("safe_yield", 0))
	elif reward.has("safe_gold"):
		lines.append("safe_yield total: %s" % reward.get("safe_gold", 0))
	if reward.has("damage"):
		lines.append("damage: %s" % reward.get("damage", 0))
	if reward.has("hp_delta"):
		lines.append("HP delta: %s" % reward.get("hp_delta", 0))
	if reward.has("effect_kind"):
		lines.append("consumable effect: %s %s" % [reward.get("effect_kind", ""), reward.get("effect_amount", 0)])
	var inventory_items: Array = _array_from(reward, "inventory_items")
	var equipped_items: Array = _array_from(reward, "equipped_items")
	var ground_items: Array = _array_from(reward, "ground_items")
	if not inventory_items.is_empty():
		lines.append("Moved to backpack: %s item(s)." % inventory_items.size())
	if not equipped_items.is_empty():
		lines.append("Equipped: %s item(s)." % equipped_items.size())
	if not ground_items.is_empty():
		lines.append("GroundLoot created: %s item(s)." % ground_items.size())
	var items: Array = _array_from(reward, "items")
	if not items.is_empty() and inventory_items.is_empty() and equipped_items.is_empty() and ground_items.is_empty():
		lines.append("Item result: %s item(s)." % items.size())
	if reward.has("capacity"):
		var capacity: Dictionary = _dict_from(reward, "capacity")
		lines.append("Backpack: %s/%s" % [capacity.get("used", 0), capacity.get("capacity", 0)])
	var reason: String = String(reward.get("blocked_reason", reward.get("reason", "")))
	if reason != "":
		lines.append("Blocked reason: %s" % reason_label(reason))
	if reward.has("roll"):
		lines.append("Dice roll: %s" % reward.get("roll", 0))
	if lines.is_empty():
		lines.append("No visible reward change.")
	return _join_lines(lines)


static func _player_message(message: String) -> String:
	var text := message.strip_edges()
	if text == "":
		return ""
	text = text.replace("black coin", "run_black_coin")
	text = text.replace("gold_coin", "safe_yield")
	text = text.replace("gold coin", "safe_yield")
	text = text.replace("on room floor", "as GroundLoot")
	text = text.replace("Search complete:", "Search complete:")
	text = text.replace("Monster cleared:", "Monster cleared:")
	text = text.replace("Mine triggered:", "Mine triggered:")
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
