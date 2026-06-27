extends RefCounted
class_name RunEffectApplier

# M2 effect-first runtime boundary.
# Gameplay-facing state changes pass through this helper or the existing
# RunAssetEffectHandler so UI messages correspond to real run state changes.

const EFFECT_HP_DELTA := &"hp_delta"
const EFFECT_PROTOCOL_PRESSURE_DELTA := &"protocol_pressure_delta"
const EFFECT_PENDING_GOLD_DELTA := &"pending_gold_delta"
const EFFECT_SAFE_GOLD_DELTA := &"safe_gold_delta"
const EFFECT_GROUND_LOOT_ADD := &"ground_loot_add"
const EFFECT_GROUND_LOOT_REMOVE := &"ground_loot_remove"
const EFFECT_BACKPACK_ITEM_ADD := &"backpack_item_add"
const EFFECT_BACKPACK_ITEM_REMOVE := &"backpack_item_remove"
const EFFECT_ROOM_MARK_EXPLORED := &"room_mark_explored"
const EFFECT_ROOM_MARK_CLEARED := &"room_mark_cleared"
const EFFECT_EVENT_MARK_COMPLETED := &"event_mark_completed"
const EFFECT_MONSTER_MARK_DEFEATED := &"monster_mark_defeated"
const EFFECT_MINE_MARK_TRIGGERED := &"mine_mark_triggered"
const EFFECT_RUN_FAIL := &"run_fail"
const EFFECT_RUN_EXTRACT := &"run_extract"
const EFFECT_DEBUG_MARKER := &"debug_marker"

const RunStateMachineScript := preload("res://scripts/core/run/run_state_machine.gd")


static func effect(effect_type: StringName, source: String, payload: Dictionary = {}, target: Variant = null) -> Dictionary:
	return {
		"type": effect_type,
		"source": source,
		"target": target,
		"payload": payload.duplicate(true),
		"read_only_preview": false,
	}


static func effect_hp_delta(amount: int, reason: String) -> Dictionary:
	return effect(EFFECT_HP_DELTA, reason, {"amount": amount, "reason": reason})


static func effect_protocol_pressure_delta(amount: int, reason: String) -> Dictionary:
	return effect(EFFECT_PROTOCOL_PRESSURE_DELTA, reason, {"amount": amount, "reason": reason})


static func effect_room_mark_explored(pos: Vector2i, reason: String = "room_enter") -> Dictionary:
	return effect(EFFECT_ROOM_MARK_EXPLORED, reason, {"position": pos}, pos)


static func effect_mine_mark_triggered(pos: Vector2i) -> Dictionary:
	return effect(EFFECT_MINE_MARK_TRIGGERED, "mine_triggered", {"position": pos}, pos)


static func apply_effects(context: RunContext, effects: Array, runtime_authority = null) -> Dictionary:
	if context == null:
		return {"ok": false, "reason": "no_active_run", "effect_results": []}
	var effect_results: Array[Dictionary] = []
	var produced_transactions: Array = []
	var ok := true
	var reason := ""
	for raw_effect in effects:
		var effect_dict: Dictionary = _dictionary(raw_effect)
		var effect_type := StringName(effect_dict.get("type", &""))
		var result := _apply_one(context, effect_type, effect_dict, runtime_authority)
		effect_results.append(result)
		produced_transactions.append_array(_array(result.get("produced_transactions", [])))
		if not bool(result.get("ok", true)):
			ok = false
			reason = String(result.get("reason", effect_type))
			break
	return {
		"ok": ok,
		"reason": reason,
		"effect_results": effect_results,
		"produced_transactions": produced_transactions,
		"transactions": produced_transactions,
		"last_result": effect_results[effect_results.size() - 1] if not effect_results.is_empty() else {},
	}


static func apply_damage(context: RunContext, amount: int, reason: String = "", runtime_authority = null) -> int:
	var damage := maxi(0, amount)
	apply_effects(context, [effect_hp_delta(-damage, reason if reason != "" else "damage")], runtime_authority)
	return damage


static func _apply_one(context: RunContext, effect_type: StringName, effect_dict: Dictionary, runtime_authority = null) -> Dictionary:
	var payload: Dictionary = _dictionary(effect_dict.get("payload", {}))
	match effect_type:
		EFFECT_HP_DELTA:
			return _apply_hp_delta(context, payload, runtime_authority)
		EFFECT_PROTOCOL_PRESSURE_DELTA:
			return _apply_pressure_delta(context, payload)
		EFFECT_PENDING_GOLD_DELTA:
			return _apply_currency_delta(context, RunAssetLedger.CURRENCY_BLACK, payload, effect_dict)
		EFFECT_SAFE_GOLD_DELTA:
			return _apply_currency_delta(context, RunAssetLedger.CURRENCY_GOLD, payload, effect_dict)
		EFFECT_GROUND_LOOT_ADD:
			return _apply_item_add(context, RunAssetLedger.LOCATION_ROOM_FLOOR, payload, effect_dict)
		EFFECT_BACKPACK_ITEM_ADD:
			return _apply_item_add(context, RunAssetLedger.LOCATION_INVENTORY, payload, effect_dict)
		EFFECT_GROUND_LOOT_REMOVE, EFFECT_BACKPACK_ITEM_REMOVE:
			return _apply_item_remove(context, payload, effect_dict)
		EFFECT_ROOM_MARK_EXPLORED:
			return _mark_room_state(context, payload, "explored")
		EFFECT_ROOM_MARK_CLEARED:
			return _mark_room_state(context, payload, "cleared")
		EFFECT_EVENT_MARK_COMPLETED:
			return _mark_event_completed(context, payload)
		EFFECT_MONSTER_MARK_DEFEATED:
			return _mark_room_state(context, payload, "monster_defeated")
		EFFECT_MINE_MARK_TRIGGERED:
			return _mark_room_state(context, payload, "mine_triggered")
		EFFECT_RUN_FAIL:
			return _apply_run_fail(context, payload, runtime_authority)
		EFFECT_RUN_EXTRACT:
			return _apply_run_extract(context, runtime_authority)
		EFFECT_DEBUG_MARKER:
			return _apply_debug_marker(context, payload)
	return _result(effect_type, false, "unknown_effect_type", {}, {})


static func _apply_hp_delta(context: RunContext, payload: Dictionary, runtime_authority = null) -> Dictionary:
	var before := context.hp
	var amount := int(payload.get("amount", 0))
	context.hp = clampi(context.hp + amount, 0, context.max_hp)
	var fail_result: Dictionary = {}
	if context.hp <= 0 and context.run_active and not context.failed:
		fail_result = _apply_run_fail(context, {"reason": String(payload.get("reason", "hp_depleted"))}, runtime_authority)
	return _result(EFFECT_HP_DELTA, true, "", {"hp": before}, {"hp": context.hp, "amount": amount, "fail_result": fail_result})


static func _apply_pressure_delta(context: RunContext, payload: Dictionary) -> Dictionary:
	var before := {"pressure": context.pressure, "protocol_level": context.protocol_level}
	var amount := int(payload.get("amount", 0))
	var pressure_result := ProtocolService.add_pressure(context, amount)
	return _result(EFFECT_PROTOCOL_PRESSURE_DELTA, true, "", before, pressure_result)


static func _apply_currency_delta(context: RunContext, currency_id: StringName, payload: Dictionary, effect_dict: Dictionary) -> Dictionary:
	var amount := int(payload.get("amount", 0))
	var asset_effect := _asset_effect(
		RunAssetEffectHandler.EFFECT_ADD_CURRENCY,
		String(effect_dict.get("source", "run_effect_applier")),
		effect_dict.get("target", context.get_current_pos()),
		{"currency_id": currency_id, "amount": amount}
	)
	var applied := RunAssetEffectHandler.apply_effects(context, [asset_effect])
	return _result(StringName(effect_dict.get("type", &"currency_delta")), bool(applied.get("ok", false)), String(applied.get("reason", "")), {}, applied)


static func _apply_item_add(context: RunContext, preferred_location: StringName, payload: Dictionary, effect_dict: Dictionary) -> Dictionary:
	var item_defs: Array = _array(payload.get("item_defs", []))
	if item_defs.is_empty() and payload.has("item_def"):
		item_defs = [_dictionary(payload.get("item_def", {}))]
	var asset_effect := _asset_effect(
		RunAssetEffectHandler.EFFECT_ADD_REWARD_ITEMS,
		String(effect_dict.get("source", "run_effect_applier")),
		effect_dict.get("target", context.get_current_pos()),
		{"item_defs": item_defs, "preferred_location": preferred_location, "room_pos": context.get_current_pos()}
	)
	var applied := RunAssetEffectHandler.apply_effects(context, [asset_effect])
	return _result(StringName(effect_dict.get("type", &"item_add")), bool(applied.get("ok", false)), String(applied.get("reason", "")), {}, applied)


static func _apply_item_remove(context: RunContext, payload: Dictionary, effect_dict: Dictionary) -> Dictionary:
	var instance_id := String(payload.get("instance_id", ""))
	var effect_type := RunAssetEffectHandler.EFFECT_PICKUP_GROUND_ITEM if StringName(effect_dict.get("type", &"")) == EFFECT_GROUND_LOOT_REMOVE else RunAssetEffectHandler.EFFECT_DROP_INVENTORY_ITEM
	var asset_effect := _asset_effect(
		effect_type,
		String(effect_dict.get("source", "run_effect_applier")),
		effect_dict.get("target", context.get_current_pos()),
		{"instance_id": instance_id, "room_pos": context.get_current_pos()}
	)
	var applied := RunAssetEffectHandler.apply_effects(context, [asset_effect])
	return _result(StringName(effect_dict.get("type", &"item_remove")), bool(applied.get("ok", false)), String(applied.get("reason", "")), {}, applied)


static func _mark_room_state(context: RunContext, payload: Dictionary, mark_type: String) -> Dictionary:
	var pos: Vector2i = payload.get("position", context.get_current_pos())
	if context.truth_map == null:
		return _result(StringName("room_mark_%s" % mark_type), false, "no_truth_map", {}, {})
	match mark_type:
		"explored":
			context.truth_map.mark_explored(pos)
			context.explored_cells[context.cell_key(pos)] = true
		"cleared", "monster_defeated":
			context.truth_map.mark_cleared(pos)
		"mine_triggered":
			context.truth_map.mark_triggered(pos)
	if context.intel_map != null:
		context.intel_map.refresh_revealed_cell(pos, context.truth_map)
	return _result(StringName("room_mark_%s" % mark_type), true, "", {"position": pos}, {"position": pos})


static func _mark_event_completed(context: RunContext, payload: Dictionary) -> Dictionary:
	var pos: Vector2i = payload.get("position", context.get_current_pos())
	context.interacted_cells[context.cell_key(pos)] = true
	return _result(EFFECT_EVENT_MARK_COMPLETED, true, "", {"position": pos}, {"position": pos})


static func _apply_run_fail(context: RunContext, payload: Dictionary, runtime_authority = null) -> Dictionary:
	var fail_reason := String(payload.get("reason", "forced_failure"))
	var transition_result: Dictionary
	if runtime_authority != null and runtime_authority.has_method("fail_run"):
		transition_result = runtime_authority.fail_run(fail_reason)
	else:
		var fallback_state_machine = RunStateMachineScript.new()
		transition_result = fallback_state_machine.fail_run(context, fail_reason)
	return _result(EFFECT_RUN_FAIL, true, "", {}, transition_result)


static func _apply_run_extract(context: RunContext, runtime_authority = null) -> Dictionary:
	var transition_result: Dictionary
	if runtime_authority != null and runtime_authority.has_method("debug_force_extract"):
		transition_result = runtime_authority.debug_force_extract()
	else:
		var fallback_state_machine = RunStateMachineScript.new()
		transition_result = fallback_state_machine.force_extract(context)
	return _result(EFFECT_RUN_EXTRACT, true, "", {}, transition_result)


static func _apply_debug_marker(context: RunContext, payload: Dictionary) -> Dictionary:
	var command := String(payload.get("command", "debug_marker"))
	var marker := context.record_debug_command(command, payload)
	return _result(EFFECT_DEBUG_MARKER, true, "", {}, marker)


static func _result(effect_type: StringName, ok: bool, reason: String, before: Dictionary, after: Dictionary) -> Dictionary:
	return {
		"ok": ok,
		"effect_type": effect_type,
		"reason": reason,
		"before": before.duplicate(true),
		"after": after.duplicate(true),
		"produced_transactions": _array(after.get("produced_transactions", after.get("transactions", []))),
	}


static func _asset_effect(effect_type: StringName, source: String, target: Variant, payload: Dictionary) -> Dictionary:
	return {
		"effect_id": "run_effect_%s" % String(effect_type).replace(".", "_"),
		"type": effect_type,
		"source": source,
		"target": target,
		"payload": payload.duplicate(true),
		"actor_id": &"player",
		"command_id": "",
		"rule_request_id": "run_effect_applier",
	}


static func _dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}


static func _array(value: Variant) -> Array:
	if value is Array:
		return value.duplicate(true)
	return []
