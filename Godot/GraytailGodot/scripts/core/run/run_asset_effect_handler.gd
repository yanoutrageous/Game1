extends RefCounted
class_name RunAssetEffectHandler

# Applies the asset-related subset of EffectSpec dictionaries.
# RunAssetLedger remains the only owner of asset state.

const EFFECT_ADD_CURRENCY := &"asset.add_currency"
const EFFECT_SPEND_CURRENCY := &"asset.spend_currency"
const EFFECT_ADD_REWARD_ITEMS := &"asset.add_reward_items"
const EFFECT_ADD_STATUS_EFFECT := &"asset.add_status_effect"
const EFFECT_PICKUP_GROUND_ITEM := &"asset.pickup_ground_item"
const EFFECT_DROP_INVENTORY_ITEM := &"asset.drop_inventory_item"
const EFFECT_SELL_BEST_INVENTORY_ITEM := &"asset.sell_best_inventory_item"
const EFFECT_SETTLE_SUCCESS := &"asset.settle_success"
const EFFECT_SETTLE_FAILURE := &"asset.settle_failure"


static func apply_effects(context: RunContext, effects: Array) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {"ok": false, "status": &"no_ledger", "reason": "no_active_asset_ledger", "effect_results": []}
	var effect_results: Array[Dictionary] = []
	var produced_transactions: Array[Dictionary] = []
	var first_blocked_reason: String = ""
	for raw_effect in effects:
		var effect: Dictionary = raw_effect
		var result: Dictionary = apply_effect(context, effect)
		effect_results.append(result)
		produced_transactions.append_array(_array_from_variant(result.get("transactions", [])))
		if not bool(result.get("ok", true)):
			first_blocked_reason = String(result.get("reason", result.get("blocked_reason", "blocked")))
			break
	context.asset_ledger.sync_compat_fields(context)
	return {
		"ok": first_blocked_reason == "",
		"status": &"applied" if first_blocked_reason == "" else &"blocked",
		"reason": first_blocked_reason,
		"blocked_reason": first_blocked_reason,
		"effect_results": effect_results,
		"transactions": produced_transactions,
		"produced_transactions": produced_transactions,
		"last_result": {} if effect_results.is_empty() else effect_results[effect_results.size() - 1],
	}


static func apply_effect(context: RunContext, effect: Dictionary) -> Dictionary:
	var effect_type: StringName = StringName(effect.get("type", &""))
	var payload: Dictionary = _dictionary_from_variant(effect.get("payload", {}))
	var source: String = String(effect.get("source", payload.get("source", "")))
	var before: Dictionary = _asset_summary(context)
	var result: Dictionary = {}
	match effect_type:
		EFFECT_ADD_CURRENCY:
			result = _with_effect_type(context.asset_ledger.add_currency(StringName(payload.get("currency_id", &"")), int(payload.get("amount", 0)), source), effect_type, true)
		EFFECT_SPEND_CURRENCY:
			result = _with_effect_type(context.asset_ledger.spend_currency(StringName(payload.get("currency_id", &"")), int(payload.get("amount", 0)), source), effect_type)
		EFFECT_ADD_REWARD_ITEMS:
			var item_result: Dictionary = context.asset_ledger.add_reward_items(_array_from_variant(payload.get("item_defs", [])), StringName(payload.get("preferred_location", RunAssetLedger.LOCATION_INVENTORY)), payload.get("room_pos", context.get_current_pos()), source)
			item_result["ok"] = true
			item_result["effect_type"] = effect_type
			result = item_result
		EFFECT_ADD_STATUS_EFFECT:
			context.asset_ledger.add_status_effect(payload.get("effect", payload))
			result = {"ok": true, "effect_type": effect_type, "status": &"status_effect_added"}
		EFFECT_PICKUP_GROUND_ITEM:
			result = _with_effect_type(context.asset_ledger.pickup_ground_item(String(payload.get("instance_id", "")), payload.get("room_pos", context.get_current_pos())), effect_type)
		EFFECT_DROP_INVENTORY_ITEM:
			result = _with_effect_type(context.asset_ledger.drop_inventory_item(String(payload.get("instance_id", "")), payload.get("room_pos", context.get_current_pos())), effect_type)
		EFFECT_SELL_BEST_INVENTORY_ITEM:
			result = _with_effect_type(context.asset_ledger.sell_best_inventory_item(), effect_type)
		EFFECT_SETTLE_SUCCESS:
			result = _with_effect_type(context.asset_ledger.settle_success(), effect_type, true)
		EFFECT_SETTLE_FAILURE:
			result = _with_effect_type(context.asset_ledger.settle_failure(), effect_type, true)
		_:
			result = {"ok": false, "status": &"unknown_effect", "reason": "unknown_asset_effect", "effect_type": effect_type}
	var after: Dictionary = _asset_summary(context)
	var transaction: Dictionary = _record_transaction_for_effect(context, effect, effect_type, result, before, after)
	if not transaction.is_empty():
		result["transaction"] = transaction
		result["transactions"] = [transaction]
	_record_events_for_effect(context, effect, effect_type, result)
	return result


static func _with_effect_type(result: Dictionary, effect_type: StringName, default_ok: Variant = null) -> Dictionary:
	var next_result: Dictionary = result.duplicate(true)
	if default_ok != null and not next_result.has("ok"):
		next_result["ok"] = bool(default_ok)
	next_result["effect_type"] = effect_type
	return next_result


static func _record_transaction_for_effect(context: RunContext, effect: Dictionary, effect_type: StringName, result: Dictionary, before: Dictionary, after: Dictionary) -> Dictionary:
	if context == null or context.transaction_log == null:
		return {}
	var payload: Dictionary = _dictionary_from_variant(effect.get("payload", {}))
	var command_id: String = String(effect.get("command_id", ""))
	var effect_id: String = String(effect.get("effect_id", "%s_%s" % [String(effect_type).replace(".", "_"), command_id]))
	var actor_id: StringName = StringName(effect.get("actor_id", &"player"))
	var source: String = String(effect.get("source", payload.get("source", "")))
	var reason: String = String(result.get("reason", result.get("blocked_reason", "")))
	var currency_delta: Dictionary = _currency_delta_for_effect(effect_type, payload, result)
	var item_moves: Array = _item_moves_for_effect(effect_type, result)
	return context.transaction_log.record_transaction(command_id, effect_id, actor_id, source, effect_type, before, after, currency_delta, item_moves, reason)


static func _record_events_for_effect(context: RunContext, effect: Dictionary, effect_type: StringName, result: Dictionary) -> void:
	if context == null or context.run_event_log == null or not bool(result.get("ok", true)):
		return
	var payload: Dictionary = _dictionary_from_variant(effect.get("payload", {}))
	var command_id: String = String(effect.get("command_id", ""))
	var actor_id: StringName = StringName(effect.get("actor_id", &"player"))
	var source: String = String(effect.get("source", payload.get("source", "")))
	match effect_type:
		EFFECT_ADD_REWARD_ITEMS:
			var gained_items: Array = _item_moves_for_effect(effect_type, result)
			if not gained_items.is_empty():
				context.record_event(RunEventLog.EVENT_ITEM_GAINED, command_id, actor_id, source, {"items": gained_items})
		EFFECT_PICKUP_GROUND_ITEM:
			context.record_event(RunEventLog.EVENT_ITEM_PICKED_UP, command_id, actor_id, source, {"item": _dictionary_from_variant(result.get("item", {}))})
		EFFECT_DROP_INVENTORY_ITEM:
			context.record_event(RunEventLog.EVENT_ITEM_DROPPED, command_id, actor_id, source, {"item": _dictionary_from_variant(result.get("item", {}))})
		EFFECT_SETTLE_SUCCESS, EFFECT_SETTLE_FAILURE:
			context.record_event(RunEventLog.EVENT_SETTLEMENT_COMPLETED, command_id, actor_id, source, {"outcome": result.get("outcome", ""), "settlement": result.duplicate(true)})


static func _asset_summary(context: RunContext) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {}
	return {
		"black_coin": context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK),
		"gold_coin": context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_GOLD),
		"backpack_used": context.asset_ledger.get_backpack_used(),
		"inventory_count": context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_INVENTORY).size(),
		"equipped_count": context.asset_ledger.get_items_by_location(RunAssetLedger.LOCATION_EQUIPPED).size(),
		"room_floor_item_count": context.asset_ledger.get_room_floor_items(context.get_current_pos()).size(),
	}


static func _currency_delta_for_effect(effect_type: StringName, payload: Dictionary, result: Dictionary) -> Dictionary:
	match effect_type:
		EFFECT_ADD_CURRENCY:
			return {String(payload.get("currency_id", "")): int(payload.get("amount", 0))}
		EFFECT_SPEND_CURRENCY:
			var spend_delta: int = -int(payload.get("amount", 0)) if bool(result.get("ok", false)) else 0
			return {String(payload.get("currency_id", "")): spend_delta}
		EFFECT_SELL_BEST_INVENTORY_ITEM:
			return {"gold_coin": int(result.get("gold_coin", 0))}
		EFFECT_SETTLE_SUCCESS:
			return _dictionary_from_variant(result.get("currency_delta", {}))
		EFFECT_SETTLE_FAILURE:
			return {"black_coin": -int(result.get("black_coin_lost", 0)), "gold_coin": 0}
	return {}


static func _item_moves_for_effect(effect_type: StringName, result: Dictionary) -> Array:
	var moves: Array = []
	match effect_type:
		EFFECT_ADD_REWARD_ITEMS:
			for location_key in ["inventory_items", "equipped_items", "ground_items"]:
				for item in result.get(location_key, []):
					moves.append({"instance_id": item.get("instance_id", ""), "to": item.get("location_state", ""), "item_id": item.get("item_id", "")})
		EFFECT_PICKUP_GROUND_ITEM:
			var pickup_item: Dictionary = result.get("item", {})
			if not pickup_item.is_empty():
				moves.append({"instance_id": pickup_item.get("instance_id", ""), "from": RunAssetLedger.LOCATION_ROOM_FLOOR, "to": RunAssetLedger.LOCATION_INVENTORY})
		EFFECT_DROP_INVENTORY_ITEM:
			var drop_item: Dictionary = result.get("item", {})
			if not drop_item.is_empty():
				moves.append({"instance_id": drop_item.get("instance_id", ""), "from": RunAssetLedger.LOCATION_INVENTORY, "to": RunAssetLedger.LOCATION_ROOM_FLOOR})
		EFFECT_SELL_BEST_INVENTORY_ITEM:
			var sold_item: Dictionary = result.get("sold_item", {})
			if not sold_item.is_empty():
				moves.append({"instance_id": sold_item.get("instance_id", ""), "from": RunAssetLedger.LOCATION_INVENTORY, "to": RunAssetLedger.LOCATION_LOST})
		EFFECT_SETTLE_SUCCESS:
			for item in result.get("extracted_items", []):
				moves.append({"instance_id": item.get("instance_id", ""), "to": RunAssetLedger.LOCATION_WAREHOUSE})
			for item in result.get("room_floor_lost_items", []):
				moves.append({"instance_id": item.get("instance_id", ""), "from": RunAssetLedger.LOCATION_ROOM_FLOOR, "to": RunAssetLedger.LOCATION_LOST})
		EFFECT_SETTLE_FAILURE:
			for item in result.get("salvaged_items", []):
				moves.append({"instance_id": item.get("instance_id", ""), "to": RunAssetLedger.LOCATION_WAREHOUSE})
			for item in result.get("lost_items", []):
				moves.append({"instance_id": item.get("instance_id", ""), "to": RunAssetLedger.LOCATION_LOST})
			for item in result.get("room_floor_lost_items", []):
				moves.append({"instance_id": item.get("instance_id", ""), "from": RunAssetLedger.LOCATION_ROOM_FLOOR, "to": RunAssetLedger.LOCATION_LOST})
	return moves


static func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}


static func _array_from_variant(value: Variant) -> Array:
	if value is Array:
		return value.duplicate(true)
	return []
