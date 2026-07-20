extends RefCounted
class_name ItemCommandHandler

# Owns item-command rule invocation and the resulting RunContext presentation
# fields. CommandBus remains the acceptance, signal, and CommandResult facade.

const DEFAULT_ACTOR_ID := &"player"
const RunRuleServiceScript := preload("res://scripts/core/run/run_rule_service.gd")

const ACTION_PICKUP := &"pickup_ground_item"
const ACTION_REPLACE := &"replace_ground_item"
const ACTION_DROP := &"drop_inventory_item"
const ACTION_USE := &"use_consumable"
const ACTION_EQUIP := &"equip_item"
const ACTION_UNEQUIP := &"unequip_item"


func execute(context: RunContext, action: StringName, payload: Dictionary = {}) -> Dictionary:
	match action:
		ACTION_PICKUP:
			return _rule_outcome(
				context,
				RunRuleServiceScript.pickup_ground_item(context, String(payload.get("instance_id", ""))),
				&"pickup"
			)
		ACTION_REPLACE:
			return _rule_outcome(
				context,
				RunRuleServiceScript.replace_ground_item(
					context,
					String(payload.get("ground_instance_id", payload.get("instance_id", ""))),
					String(payload.get("drop_instance_id", ""))
				),
				&"replace"
			)
		ACTION_DROP:
			return _rule_outcome(
				context,
				RunRuleServiceScript.drop_inventory_item(context, String(payload.get("instance_id", ""))),
				&"drop"
			)
		ACTION_USE:
			return _rule_outcome(
				context,
				RunRuleServiceScript.use_consumable(context, String(payload.get("instance_id", ""))),
				&"use"
			)
		ACTION_EQUIP:
			return _equipment_outcome(context, String(payload.get("instance_id", "")), true)
		ACTION_UNEQUIP:
			return _equipment_outcome(context, String(payload.get("instance_id", "")), false)
	return {
		"action_result": _blocked(&"unknown_item_command", "unknown_item_command"),
		"emit_state": false,
	}


func _rule_outcome(context: RunContext, result: Dictionary, operation: StringName) -> Dictionary:
	context.last_reward = result.duplicate(true)
	if bool(result.get("ok", false)):
		context.blocked_reason = ""
		context.last_message = _success_message(operation, result)
	else:
		context.blocked_reason = String(result.get("reason", result.get("blocked_reason", "blocked")))
		context.last_message = "%s blocked: %s." % [_operation_label(operation), context.blocked_reason]
	return {"action_result": result, "emit_state": true}


func _equipment_outcome(context: RunContext, instance_id: String, equip: bool) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {"action_result": _blocked(&"not_ready", "not_ready"), "emit_state": false}
	var result: Dictionary
	if equip:
		result = context.asset_ledger.equip_inventory_item(instance_id)
	else:
		result = context.asset_ledger.unequip_item(instance_id)
	context.asset_ledger.sync_compat_fields(context)
	if bool(result.get("ok", false)):
		context.blocked_reason = ""
		var item: Dictionary = result.get("item", {})
		context.last_message = "%s item: %s." % [
			"Equipped" if equip else "Unequipped",
			String(item.get("display_name", item.get("item_id", "item"))),
		]
	else:
		context.blocked_reason = String(result.get("reason", result.get("blocked_reason", "blocked")))
		context.last_message = "%s blocked: %s." % [
			"Equip" if equip else "Unequip",
			context.blocked_reason,
		]
	return {"action_result": result, "emit_state": true}


func _success_message(operation: StringName, result: Dictionary) -> String:
	var item: Dictionary = result.get("item", {})
	var display_name := String(item.get("display_name", item.get("item_id", "item")))
	match operation:
		&"pickup":
			return "Picked up floor item: %s." % display_name
		&"replace":
			var dropped: Dictionary = result.get("dropped_item", {})
			return "Replaced floor item: picked %s, dropped %s." % [
				display_name,
				String(dropped.get("display_name", dropped.get("item_id", "item"))),
			]
		&"drop":
			return "Dropped inventory item: %s." % display_name
		&"use":
			return String(result.get("message", "Consumable used."))
	return "Item command completed."


func _operation_label(operation: StringName) -> String:
	match operation:
		&"pickup":
			return "Pickup"
		&"replace":
			return "Replace"
		&"drop":
			return "Drop"
		&"use":
			return "Use"
	return "Item command"


func _blocked(status: StringName, reason: String) -> Dictionary:
	return {
		"ok": false,
		"status": status,
		"reason": reason,
		"blocked_reason": reason,
		"reason_code": reason,
		"message_key": "command.rejected.%s" % reason,
		"actor_id": DEFAULT_ACTOR_ID,
	}
