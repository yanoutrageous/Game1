extends RefCounted
class_name Art24StateCatalog

const STATES := [
	{"primary_id": &"room", "secondary_id": &"room.normal.idle", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"none", "protocol_level": 5, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.normal.searching", "room_type": &"normal", "visual_state": &"searching", "active_modal": &"none", "protocol_level": 5, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.normal.loot_spawned", "room_type": &"normal", "visual_state": &"loot_spawned", "active_modal": &"none", "protocol_level": 5, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.normal.depleted", "room_type": &"normal", "visual_state": &"depleted", "active_modal": &"none", "protocol_level": 5, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.mine.hidden", "room_type": &"mine", "visual_state": &"hidden", "active_modal": &"none", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.mine.warning", "room_type": &"mine", "visual_state": &"warning", "active_modal": &"none", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.mine.triggered", "room_type": &"mine", "visual_state": &"triggered", "active_modal": &"none", "protocol_level": 2, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.mine.resolved", "room_type": &"mine", "visual_state": &"resolved", "active_modal": &"none", "protocol_level": 2, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.chest.closed", "room_type": &"chest", "visual_state": &"closed", "active_modal": &"none", "protocol_level": 5, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.chest.context_nearby", "room_type": &"chest", "visual_state": &"closed", "active_modal": &"chest_context_closed", "protocol_level": 5, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.chest.opening", "room_type": &"chest", "visual_state": &"opening", "active_modal": &"none", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.chest.container_open", "room_type": &"chest", "visual_state": &"container_open", "active_modal": &"chest_context_open", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.chest.container_closed", "room_type": &"chest", "visual_state": &"container_closed", "active_modal": &"chest_context_closed_after_open", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.chest.reopened", "room_type": &"chest", "visual_state": &"reopened", "active_modal": &"chest_context_reopened", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.chest.empty", "room_type": &"chest", "visual_state": &"empty", "active_modal": &"chest_context_empty", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.event.idle", "room_type": &"event", "visual_state": &"idle", "active_modal": &"none", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.event.active", "room_type": &"event", "visual_state": &"active", "active_modal": &"none", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.event.resolved", "room_type": &"event", "visual_state": &"resolved", "active_modal": &"none", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.monster.appear", "room_type": &"monster", "visual_state": &"appear", "active_modal": &"none", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.monster.idle", "room_type": &"monster", "visual_state": &"idle", "active_modal": &"none", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.monster.attack", "room_type": &"monster", "visual_state": &"attack", "active_modal": &"none", "protocol_level": 2, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.monster.hit", "room_type": &"monster", "visual_state": &"hit", "active_modal": &"none", "protocol_level": 2, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.monster.defeated", "room_type": &"monster", "visual_state": &"defeated", "active_modal": &"none", "protocol_level": 2, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.exit.inactive", "room_type": &"exit", "visual_state": &"inactive", "active_modal": &"none", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.exit.active", "room_type": &"exit", "visual_state": &"active", "active_modal": &"none", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"room", "secondary_id": &"room.exit.confirm", "room_type": &"exit", "visual_state": &"confirm", "active_modal": &"extract", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"protocol", "secondary_id": &"protocol.level.5", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"none", "protocol_level": 5, "reduce_motion": false},
	{"primary_id": &"protocol", "secondary_id": &"protocol.level.4", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"none", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"protocol", "secondary_id": &"protocol.level.3", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"none", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"protocol", "secondary_id": &"protocol.level.2", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"none", "protocol_level": 2, "reduce_motion": false},
	{"primary_id": &"protocol", "secondary_id": &"protocol.level.1", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"none", "protocol_level": 1, "reduce_motion": false},
	{"primary_id": &"map", "secondary_id": &"map.overview", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"map", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"map", "secondary_id": &"map.cell_selected", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"map_selected", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"map", "secondary_id": &"map.marked", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"map_marked", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"map", "secondary_id": &"map.return_available", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"map_return", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"inventory", "secondary_id": &"inventory.empty", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"inventory_empty", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"inventory", "secondary_id": &"inventory.populated", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"inventory", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"inventory", "secondary_id": &"inventory.selected", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"inventory_selected", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"inventory", "secondary_id": &"inventory.full", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"inventory_full", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"inventory", "secondary_id": &"inventory.tooltip", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"inventory_tooltip", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"loot", "secondary_id": &"loot.floor_visible", "room_type": &"normal", "visual_state": &"loot_spawned", "active_modal": &"none", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"loot", "secondary_id": &"loot.context_nearby", "room_type": &"normal", "visual_state": &"loot_hover", "active_modal": &"world_loot_context", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"loot", "secondary_id": &"loot.context_multi", "room_type": &"normal", "visual_state": &"loot_hover", "active_modal": &"world_loot_context_multi", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"loot", "secondary_id": &"loot.pickup", "room_type": &"normal", "visual_state": &"pickup_fly", "active_modal": &"none", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"loot", "secondary_id": &"loot.capacity_blocked", "room_type": &"normal", "visual_state": &"loot_hover", "active_modal": &"world_loot_blocked", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"loot", "secondary_id": &"loot.replace_select", "room_type": &"normal", "visual_state": &"loot_hover", "active_modal": &"world_loot_replace", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"loot", "secondary_id": &"loot.replace_confirm", "room_type": &"normal", "visual_state": &"pickup_fly", "active_modal": &"world_loot_replace_confirm", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"loot", "secondary_id": &"loot.context_hidden_after_leave", "room_type": &"normal", "visual_state": &"loot_departed", "active_modal": &"none", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"overlay", "secondary_id": &"overlay.tutorial", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"tutorial", "protocol_level": 5, "reduce_motion": false},
	{"primary_id": &"overlay", "secondary_id": &"overlay.event_choice", "room_type": &"event", "visual_state": &"active", "active_modal": &"event", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"overlay", "secondary_id": &"overlay.pause", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"pause", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"overlay", "secondary_id": &"overlay.extract_safe", "room_type": &"exit", "visual_state": &"active", "active_modal": &"extract_safe", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"overlay", "secondary_id": &"overlay.extract_risky", "room_type": &"exit", "visual_state": &"active", "active_modal": &"extract_risky", "protocol_level": 1, "reduce_motion": false},
	{"primary_id": &"result", "secondary_id": &"result.success", "room_type": &"exit", "visual_state": &"confirmed", "active_modal": &"result_success", "protocol_level": 3, "reduce_motion": false},
	{"primary_id": &"result", "secondary_id": &"result.failure_salvage_select", "room_type": &"mine", "visual_state": &"salvage_select", "active_modal": &"result_failure_salvage_select", "protocol_level": 1, "reduce_motion": false},
	{"primary_id": &"result", "secondary_id": &"result.failure_salvage_selected", "room_type": &"mine", "visual_state": &"salvage_selected", "active_modal": &"result_failure_salvage_selected", "protocol_level": 1, "reduce_motion": false},
	{"primary_id": &"result", "secondary_id": &"result.failure_salvage_capacity_blocked", "room_type": &"mine", "visual_state": &"salvage_blocked", "active_modal": &"result_failure_salvage_capacity_blocked", "protocol_level": 1, "reduce_motion": false},
	{"primary_id": &"result", "secondary_id": &"result.failure", "room_type": &"mine", "visual_state": &"triggered", "active_modal": &"result_failure", "protocol_level": 1, "reduce_motion": false},
	{"primary_id": &"result", "secondary_id": &"result.abandoned", "room_type": &"normal", "visual_state": &"idle", "active_modal": &"result_abandoned", "protocol_level": 2, "reduce_motion": false},
	{"primary_id": &"motion", "secondary_id": &"motion.full", "room_type": &"normal", "visual_state": &"loot_spawned", "active_modal": &"none", "protocol_level": 4, "reduce_motion": false},
	{"primary_id": &"motion", "secondary_id": &"motion.reduced", "room_type": &"normal", "visual_state": &"loot_spawned", "active_modal": &"none", "protocol_level": 4, "reduce_motion": true},
]

static func state_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for entry: Dictionary in STATES:
		result.append(StringName(entry.secondary_id))
	return result

static func state_for(state_id: StringName) -> Dictionary:
	for entry: Dictionary in STATES:
		if StringName(entry.secondary_id) == state_id:
			return entry.duplicate(true)
	return (STATES[0] as Dictionary).duplicate(true)

static func first_index_for_primary(primary_id: StringName) -> int:
	for index in range(STATES.size()):
		if StringName((STATES[index] as Dictionary).primary_id) == primary_id:
			return index
	return 0
