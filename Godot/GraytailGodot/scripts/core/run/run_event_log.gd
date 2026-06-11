extends RefCounted
class_name RunEventLog

# G8.2 fact event log. Events are audit facts, not a mutation entry point.

const EVENT_RUN_STARTED := &"run_started"
const EVENT_ROOM_ENTERED := &"room_entered"
const EVENT_ROOM_SEARCHED := &"room_searched"
const EVENT_ITEM_GAINED := &"item_gained"
const EVENT_ITEM_PICKED_UP := &"item_picked_up"
const EVENT_ITEM_DROPPED := &"item_dropped"
const EVENT_COMBAT_RESOLVED := &"combat_resolved"
const EVENT_EVENT_OPTION_SELECTED := &"event_option_selected"
const EVENT_EXTRACTION_FOUND := &"extraction_found"
const EVENT_EXTRACTION_SUCCESS := &"extraction_success"
const EVENT_RUN_FAILED := &"run_failed"
const EVENT_SETTLEMENT_COMPLETED := &"settlement_completed"

var events: Array[Dictionary] = []
var next_sequence: int = 1


func reset() -> void:
	events.clear()
	next_sequence = 1


func record_event(event_type: StringName, command_id: String = "", actor_id: StringName = &"player", source: String = "", payload: Dictionary = {}) -> Dictionary:
	var sequence: int = next_sequence
	next_sequence += 1
	var event: Dictionary = {
		"event_id": "evt_%04d_%s" % [sequence, String(event_type)],
		"event_type": event_type,
		"command_id": command_id,
		"actor_id": actor_id,
		"source": source,
		"payload": payload.duplicate(true),
		"sequence": sequence,
	}
	events.append(event)
	return event.duplicate(true)


func get_events_since(start_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in range(maxi(0, start_index), events.size()):
		result.append(events[index].duplicate(true))
	return result


func snapshot() -> Array[Dictionary]:
	return events.duplicate(true)


func size() -> int:
	return events.size()
