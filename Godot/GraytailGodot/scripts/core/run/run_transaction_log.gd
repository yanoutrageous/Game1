extends RefCounted
class_name RunTransactionLog

# G8.2 asset transaction log. Transactions describe applied changes after ledger/effect handling.

var entries: Array[Dictionary] = []
var next_sequence: int = 1


func reset() -> void:
	entries.clear()
	next_sequence = 1


func record_transaction(command_id: String, effect_id: String, actor_id: StringName, source: String, action: StringName, before: Dictionary = {}, after: Dictionary = {}, currency_delta: Dictionary = {}, item_moves: Array = [], reason: String = "") -> Dictionary:
	var sequence: int = next_sequence
	next_sequence += 1
	var entry: Dictionary = {
		"transaction_id": "txn_%04d_%s" % [sequence, String(action)],
		"command_id": command_id,
		"effect_id": effect_id,
		"actor_id": actor_id,
		"source": source,
		"action": action,
		"before": before.duplicate(true),
		"after": after.duplicate(true),
		"currency_delta": currency_delta.duplicate(true),
		"item_moves": item_moves.duplicate(true),
		"reason": reason,
		"sequence": sequence,
	}
	entries.append(entry)
	return entry.duplicate(true)


func get_entries_since(start_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(maxi(0, start_index), entries.size()):
		result.append(entries[index].duplicate(true))
	return result


func snapshot() -> Array[Dictionary]:
	return entries.duplicate(true)


func size() -> int:
	return entries.size()
