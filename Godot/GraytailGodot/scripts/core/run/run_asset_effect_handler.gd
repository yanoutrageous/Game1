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
	var first_blocked_reason := ""
	for raw_effect in effects:
		var effect: Dictionary = raw_effect
		var result := apply_effect(context, effect)
		effect_results.append(result)
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
		"last_result": {} if effect_results.is_empty() else effect_results[effect_results.size() - 1],
	}


static func apply_effect(context: RunContext, effect: Dictionary) -> Dictionary:
	var effect_type := StringName(effect.get("type", &""))
	var payload: Dictionary = effect.get("payload", {})
	var source := String(effect.get("source", payload.get("source", "")))
	match effect_type:
		EFFECT_ADD_CURRENCY:
			return _with_effect_type(context.asset_ledger.add_currency(StringName(payload.get("currency_id", &"")), int(payload.get("amount", 0)), source), effect_type, true)
		EFFECT_SPEND_CURRENCY:
			return _with_effect_type(context.asset_ledger.spend_currency(StringName(payload.get("currency_id", &"")), int(payload.get("amount", 0)), source), effect_type)
		EFFECT_ADD_REWARD_ITEMS:
			var item_result := context.asset_ledger.add_reward_items(payload.get("item_defs", []), StringName(payload.get("preferred_location", RunAssetLedger.LOCATION_INVENTORY)), payload.get("room_pos", context.get_current_pos()), source)
			item_result["ok"] = true
			item_result["effect_type"] = effect_type
			return item_result
		EFFECT_ADD_STATUS_EFFECT:
			context.asset_ledger.add_status_effect(payload.get("effect", payload))
			return {"ok": true, "effect_type": effect_type, "status": &"status_effect_added"}
		EFFECT_PICKUP_GROUND_ITEM:
			return _with_effect_type(context.asset_ledger.pickup_ground_item(String(payload.get("instance_id", "")), payload.get("room_pos", context.get_current_pos())), effect_type)
		EFFECT_DROP_INVENTORY_ITEM:
			return _with_effect_type(context.asset_ledger.drop_inventory_item(String(payload.get("instance_id", "")), payload.get("room_pos", context.get_current_pos())), effect_type)
		EFFECT_SELL_BEST_INVENTORY_ITEM:
			return _with_effect_type(context.asset_ledger.sell_best_inventory_item(), effect_type)
		EFFECT_SETTLE_SUCCESS:
			return _with_effect_type(context.asset_ledger.settle_success(), effect_type, true)
		EFFECT_SETTLE_FAILURE:
			return _with_effect_type(context.asset_ledger.settle_failure(), effect_type, true)
	return {"ok": false, "status": &"unknown_effect", "reason": "unknown_asset_effect", "effect_type": effect_type}


static func _with_effect_type(result: Dictionary, effect_type: StringName, default_ok: Variant = null) -> Dictionary:
	var next_result := result.duplicate(true)
	if default_ok != null and not next_result.has("ok"):
		next_result["ok"] = bool(default_ok)
	next_result["effect_type"] = effect_type
	return next_result
