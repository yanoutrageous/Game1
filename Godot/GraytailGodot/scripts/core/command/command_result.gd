extends RefCounted
class_name CommandResult

# G8.2 command result protocol.
# UI consumes reason/message fields and never infers rejection causes from core state.


static func accepted(command: Dictionary, produced_events: Array = [], produced_transactions: Array = [], snapshot_delta: Dictionary = {}) -> Dictionary:
	return _base_result(command, true, "", "command.accepted", produced_events, produced_transactions, snapshot_delta)


static func rejected(command: Dictionary, reason_code: String, message_key: String = "", produced_events: Array = [], produced_transactions: Array = [], snapshot_delta: Dictionary = {}) -> Dictionary:
	var key := message_key if message_key != "" else "command.rejected.%s" % reason_code
	return _base_result(command, false, reason_code, key, produced_events, produced_transactions, snapshot_delta)


static func from_action(command: Dictionary, action_result: Dictionary, produced_events: Array = [], produced_transactions: Array = [], snapshot_delta: Dictionary = {}) -> Dictionary:
	var accepted_result := bool(action_result.get("ok", false))
	var reason_code := "" if accepted_result else String(action_result.get("reason", action_result.get("blocked_reason", "blocked")))
	var default_message_key := "command.accepted" if accepted_result else "command.rejected.%s" % reason_code
	var default_status := &"accepted" if accepted_result else &"blocked"
	var message_key := String(action_result.get("message_key", default_message_key))
	var result := _base_result(command, accepted_result, reason_code, message_key, produced_events, produced_transactions, snapshot_delta)
	result["action_result"] = action_result.duplicate(true)
	result["status"] = StringName(action_result.get("status", default_status))
	result["ok"] = accepted_result
	result["blocked_reason"] = reason_code
	return result


static func _base_result(command: Dictionary, accepted_value: bool, reason_code: String, message_key: String, produced_events: Array, produced_transactions: Array, snapshot_delta: Dictionary) -> Dictionary:
	var status_value := &"accepted" if accepted_value else &"blocked"
	return {
		"accepted": accepted_value,
		"ok": accepted_value,
		"status": status_value,
		"reason_code": reason_code,
		"reason": reason_code,
		"blocked_reason": reason_code,
		"message_key": message_key,
		"command_id": String(command.get("command_id", "")),
		"command_name": StringName(command.get("command_name", &"")),
		"actor_id": StringName(command.get("actor_id", &"player")),
		"source": String(command.get("source", "")),
		"produced_events": produced_events.duplicate(true),
		"produced_transactions": produced_transactions.duplicate(true),
		"snapshot_delta": snapshot_delta.duplicate(true),
	}
