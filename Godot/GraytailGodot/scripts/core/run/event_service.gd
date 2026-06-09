extends RefCounted
class_name EventService

const EVENT_TYPES := [&"trader", &"dice", &"altar", &"trap"]
const DICE_BET := 20
const TRAP_POWER_REQ := 8


static func get_event_type(context: RunContext, pos: Vector2i) -> StringName:
	if context == null:
		return &"trader"
	var index := absi((pos.x * 73 + pos.y * 137 + context.seed_value * 31) % EVENT_TYPES.size())
	return EVENT_TYPES[index]


static func get_event_state(context: RunContext, pos: Vector2i) -> Dictionary:
	var event_type := get_event_type(context, pos)
	var completed := context != null and context.interacted_cells.has(context.cell_key(pos))
	return {
		"event_type": event_type,
		"completed": completed,
		"options": get_event_options(context, pos, event_type, completed),
	}


static func get_event_options(context: RunContext, pos: Vector2i, event_type: StringName, completed: bool) -> Array[Dictionary]:
	if completed:
		return [{"id": &"leave", "label": "关闭", "enabled": true}]
	match event_type:
		&"trader":
			return [
				{"id": &"sell_best_item", "label": "出售最高价值回收物", "enabled": context != null and context.carried_items.size() > 0},
				{"id": &"leave", "label": "离开旅商", "enabled": true},
			]
		&"dice":
			return [
				{"id": &"bet_small", "label": "押注 20 待结算币", "enabled": context != null and context.pending_gold >= DICE_BET},
				{"id": &"leave", "label": "离开骰局", "enabled": true},
			]
		&"altar":
			return [
				{"id": &"offer_hp", "label": "献上 10 点生命", "enabled": context != null and context.hp > 10},
				{"id": &"leave", "label": "离开祭坛", "enabled": true},
			]
		&"trap":
			return [
				{"id": &"disarm", "label": "尝试拆除机关", "enabled": true},
				{"id": &"leave", "label": "离开机关", "enabled": true},
			]
	return [{"id": &"leave", "label": "离开事件", "enabled": true}]


static func execute_default(context: RunContext, pos: Vector2i) -> Dictionary:
	var event_type := get_event_type(context, pos)
	match event_type:
		&"trader":
			return execute_option(context, pos, &"sell_best_item")
		&"dice":
			return execute_option(context, pos, &"bet_small")
		&"altar":
			return execute_option(context, pos, &"offer_hp")
		&"trap":
			return execute_option(context, pos, &"disarm")
	return execute_option(context, pos, &"leave")


static func execute_option(context: RunContext, pos: Vector2i, option_id: StringName) -> Dictionary:
	if context == null:
		return {"ok": false, "message": "没有进行中的出勤。"}
	var key := context.cell_key(pos)
	var event_type := get_event_type(context, pos)
	if context.interacted_cells.has(key):
		context.event_state = get_event_state(context, pos)
		context.last_message = "事件已经处理完毕。"
		return {"ok": true, "completed": true, "message": context.last_message}
	if option_id == &"leave":
		context.last_message = "已离开事件。"
		context.event_state = get_event_state(context, pos)
		return {"ok": true, "completed": false, "message": context.last_message}

	var result := {}
	match event_type:
		&"trader":
			result = _execute_trader(context, option_id)
		&"dice":
			result = _execute_dice(context, pos, option_id)
		&"altar":
			result = _execute_altar(context, option_id)
		&"trap":
			result = _execute_trap(context, option_id)
		_:
			result = {"ok": false, "message": "未知事件类型。"}

	if bool(result.get("completed", false)):
		context.interacted_cells[key] = true
		context.run_stats["events_completed"] = int(context.run_stats.get("events_completed", 0)) + 1
		context.run_stats["events_%s" % String(event_type)] = int(context.run_stats.get("events_%s" % String(event_type), 0)) + 1
	context.event_state = get_event_state(context, pos)
	context.last_reward = result.duplicate(true)
	context.last_message = String(result.get("message", "事件已处理。"))
	return result


static func _execute_trader(context: RunContext, option_id: StringName) -> Dictionary:
	if option_id != &"sell_best_item":
		return {"ok": false, "message": "未知旅商选项。"}
	if context.carried_items.is_empty():
		return {"ok": false, "message": "没有可出售的回收物。"}
	var best_index := 0
	var best_value := -1
	for index in range(context.carried_items.size()):
		var value := int(context.carried_items[index].get("value", 0))
		if value > best_value:
			best_index = index
			best_value = value
	var item := context.carried_items[best_index]
	context.carried_items.remove_at(best_index)
	context.parts = maxi(0, context.parts - 1)
	var price := maxi(1, int(floor(float(best_value) * 0.75)))
	context.safe_gold += price
	return {"ok": true, "completed": true, "event_type": &"trader", "safe_gold": price, "sold_item": item, "message": "旅商收走回收物，安全回收 +%d。" % price}


static func _execute_dice(context: RunContext, pos: Vector2i, option_id: StringName) -> Dictionary:
	if option_id != &"bet_small":
		return {"ok": false, "message": "未知骰局选项。"}
	if context.pending_gold < DICE_BET:
		return {"ok": false, "message": "骰局需要 20 待结算币。"}
	var roll := absi((pos.x * 197 + pos.y * 83 + context.seed_value * 59 + context.pending_gold) % 6) + 1
	var delta := -DICE_BET
	if roll == 5:
		delta = 20
	elif roll == 6:
		delta = 60
	context.pending_gold = maxi(0, context.pending_gold + delta)
	return {"ok": true, "completed": true, "event_type": &"dice", "roll": roll, "pending_gold_delta": delta, "message": "骰子落在 %d，待结算变化 %d。" % [roll, delta]}


static func _execute_altar(context: RunContext, option_id: StringName) -> Dictionary:
	if option_id != &"offer_hp":
		return {"ok": false, "message": "未知祭坛选项。"}
	if context.hp <= 10:
		return {"ok": false, "message": "生命不足，无法献祭。"}
	context.hp -= 10
	context.pending_gold += 8
	var item := {"id": "altar_relic_%d" % context.turn, "value": 8}
	context.carried_items.append(item)
	context.parts += 1
	return {"ok": true, "completed": true, "event_type": &"altar", "hp_delta": -10, "pending_gold_delta": 8, "items": [item], "message": "祭坛回应：生命 -10，待结算 +8，回收物 +1。"}


static func _execute_trap(context: RunContext, option_id: StringName) -> Dictionary:
	if option_id != &"disarm":
		return {"ok": false, "message": "未知机关选项。"}
	if context.power >= TRAP_POWER_REQ:
		context.pending_gold += 25
		var items: Array[Dictionary] = [
			{"id": "trap_cache_common_%d" % context.turn, "value": 4},
			{"id": "trap_cache_low_%d" % context.turn, "value": 2},
		]
		context.carried_items.append_array(items)
		context.parts += items.size()
		return {"ok": true, "completed": true, "event_type": &"trap", "pending_gold_delta": 25, "items": items, "message": "机关解除：待结算 +25，回收物 +2。"}
	CombatState.apply_damage(context, 1, "event_trap")
	ProtocolService.add_pressure(context, 5)
	return {"ok": true, "completed": true, "event_type": &"trap", "hp_delta": -1, "pressure_delta": 5, "message": "机关触发：生命 -1，压力 +5。"}
