extends RefCounted
class_name CommandBus

# All player and Debug UI commands go through CommandBus.

signal command_requested(command_name: StringName, payload: Dictionary)
signal state_changed(snapshot: Dictionary)
signal result_available(summary: Dictionary)

const DEFAULT_ACTOR_ID := &"player"
const REJECTION_EVENT_OPTION_UNAVAILABLE := "event_option_unavailable"
const REJECTION_CANNOT_EXTRACT := "cannot_extract"
const REJECTION_NO_EXTRACT_REQUEST := "no_extract_request"

var context: RunContext
var room_resolver: RoomResolver = RoomResolver.new()
var command_sequence: int = 0


func dispatch(command_name: StringName, payload: Dictionary = {}) -> Dictionary:
	var command: Dictionary = _normalize_command(command_name, payload)
	var command_payload: Dictionary = command.get("payload", {})
	if context == null and command_name in [&"start_demo_run", &"start_tutorial_run", &"start_standard_run"]:
		context = RunContext.new()
	var event_start: int = _event_count()
	var transaction_start: int = _transaction_count()
	if context != null:
		context.active_command = command.duplicate(true)
	command_requested.emit(command_name, command)
	var action_result: Dictionary = {}
	match command_name:
		&"start_demo_run":
			action_result = start_demo_run()
		&"start_tutorial_run":
			action_result = start_tutorial_run()
		&"start_standard_run":
			action_result = start_standard_run()
		&"move_by":
			action_result = move_by(command_payload.get("delta", Vector2i.ZERO))
		&"attempt_room_transition":
			action_result = attempt_room_transition(command_payload.get("direction", Vector2i.ZERO))
		&"toggle_flag_cell":
			action_result = toggle_flag_cell(command_payload.get("pos", null))
		&"flag_current_cell":
			action_result = flag_current_cell()
		&"search_current_room":
			action_result = search_current_room()
		&"interact_current_room":
			action_result = interact_current_room()
		&"interact":
			action_result = interact()
		&"fight_current_enemy":
			action_result = fight_current_enemy()
		&"teleport_to_explored":
			action_result = teleport_to_explored(command_payload.get("pos", Vector2i.ZERO))
		&"select_event_option":
			action_result = select_event_option(StringName(command_payload.get("option_id", &"default")))
		&"select_encounter_option":
			action_result = select_encounter_option(StringName(command_payload.get("option_id", &"default")))
		&"pickup_ground_item":
			action_result = pickup_ground_item(String(command_payload.get("instance_id", "")))
		&"drop_inventory_item":
			action_result = drop_inventory_item(String(command_payload.get("instance_id", "")))
		&"request_extract":
			action_result = request_extract()
		&"confirm_extract":
			action_result = confirm_extract()
		&"cancel_extract":
			action_result = cancel_extract()
		&"extract":
			action_result = extract()
		&"restart_run":
			action_result = restart_run()
		&"confirm_tutorial_popup":
			action_result = confirm_tutorial_popup()
		&"open_map":
			action_result = _mark_open_map_placeholder()
		_:
			action_result = _blocked(&"unknown_command", "unknown_command")
	if context != null:
		context.active_command.clear()
	var produced_events: Array[Dictionary] = _events_since(event_start)
	var produced_transactions: Array[Dictionary] = _transactions_since(transaction_start)
	return CommandResult.from_action(command, action_result, produced_events, produced_transactions, _snapshot_delta_for(action_result))


func bind_context(next_context: RunContext) -> void:
	context = next_context
	if context != null and context.run_active:
		room_resolver.enter_room(context)
		_emit_state()


func start_demo_run() -> Dictionary:
	if context == null:
		context = RunContext.new()
	context.reset_demo_run()
	room_resolver.enter_room(context)
	_emit_state()
	return {"ok": true, "status": &"run_started", "mode": context.mode, "actor_id": DEFAULT_ACTOR_ID}


func start_tutorial_run() -> Dictionary:
	if context == null:
		context = RunContext.new()
	context.start_tutorial_run()
	room_resolver.enter_room(context)
	_emit_state()
	return {"ok": true, "status": &"run_started", "mode": context.mode, "actor_id": DEFAULT_ACTOR_ID}


func start_standard_run() -> Dictionary:
	if context == null:
		context = RunContext.new()
	context.start_standard_run()
	room_resolver.enter_room(context)
	_emit_state()
	return {"ok": true, "status": &"run_started", "mode": context.mode, "actor_id": DEFAULT_ACTOR_ID}


func attempt_room_transition(direction: Vector2i) -> Dictionary:
	return move_by(direction)


func move_by(delta: Vector2i) -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	if abs(delta.x) + abs(delta.y) != 1:
		context.blocked_reason = "invalid_direction"
		context.last_message = "Invalid move: only four-direction movement is allowed."
		_emit_state()
		return _blocked(&"invalid_direction", "invalid_direction")
	var target: Vector2i = context.get_current_pos() + delta
	if not context.is_inside(target):
		context.blocked_reason = "out_of_bounds"
		context.last_message = "Blocked by map boundary."
		_emit_state()
		return _blocked(&"out_of_bounds", "out_of_bounds")
	if context.intel_map.is_flagged(target):
		context.blocked_reason = "blocked_flagged"
		context.last_message = "Blocked by flag."
		_emit_state()
		return _blocked(&"blocked_flagged", "blocked_flagged")
	if context.move_requires_revealed and not context.intel_map.is_revealed(target):
		context.blocked_reason = "blocked_hidden"
		context.last_message = "Blocked: target is not revealed."
		_emit_state()
		return _blocked(&"blocked_hidden", "blocked_hidden")

	context.blocked_reason = ""
	context.player_pos = target
	context.current_pos = target
	RunInventory.record_move(context)
	room_resolver.enter_room(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)
	return {"ok": true, "status": &"moved", "position": target, "actor_id": DEFAULT_ACTOR_ID}


func toggle_flag_cell(pos = null) -> Dictionary:
	if context == null or context.intel_map == null:
		return _blocked(&"not_ready", "not_ready")
	var target: Vector2i = context.get_current_pos() if pos == null else pos
	context.intel_map.toggle_flag(target)
	context.last_message = "Flag toggled at %s." % _format_pos(target)
	_emit_state()
	return {"ok": true, "status": &"flag_toggled", "position": target, "actor_id": DEFAULT_ACTOR_ID}


func flag_current_cell() -> Dictionary:
	return toggle_flag_cell()


func search_current_room() -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", _current_blocked_reason())
	var result: Dictionary = room_resolver.search_current_room(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)
	return result


func interact_current_room() -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", _current_blocked_reason())
	if context.current_room_type == &"Exit":
		if context.phase == &"confirm_extract":
			return confirm_extract()
		else:
			return request_extract()
	var result: Dictionary = room_resolver.interact_current_room(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)
	return result


func interact() -> Dictionary:
	return interact_current_room()


func fight_current_enemy() -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", _current_blocked_reason())
	var result: Dictionary = room_resolver.fight_current_enemy(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)
	return result


func select_event_option(option_id: StringName = &"default") -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", _current_blocked_reason())
	var result: Dictionary = room_resolver.select_event_option(context, option_id)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)
	return result


func select_encounter_option(option_id: StringName = &"default") -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", _current_blocked_reason())
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	match context.current_room_type:
		&"Normal", &"Chest":
			if option_id in [&"default", &"search", &"open_chest"]:
				return search_current_room()
		&"Event":
			return select_event_option(option_id)
	context.blocked_reason = "encounter_option_unavailable"
	context.last_message = "Encounter option unavailable."
	_emit_state()
	return _blocked(&"encounter_option_unavailable", "encounter_option_unavailable")


func pickup_ground_item(instance_id: String = "") -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	var result: Dictionary = RunRuleService.pickup_ground_item(context, instance_id)
	context.last_reward = result.duplicate(true)
	if bool(result.get("ok", false)):
		context.blocked_reason = ""
		var item: Dictionary = result.get("item", {})
		context.last_message = "Picked up floor item: %s." % String(item.get("display_name", item.get("item_id", "item")))
	else:
		context.blocked_reason = String(result.get("reason", result.get("blocked_reason", "blocked")))
		context.last_message = "Pickup blocked: %s." % context.blocked_reason
	_emit_state()
	return result


func drop_inventory_item(instance_id: String = "") -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	var result: Dictionary = RunRuleService.drop_inventory_item(context, instance_id)
	context.last_reward = result.duplicate(true)
	if bool(result.get("ok", false)):
		context.blocked_reason = ""
		var item: Dictionary = result.get("item", {})
		context.last_message = "Dropped inventory item: %s." % String(item.get("display_name", item.get("item_id", "item")))
	else:
		context.blocked_reason = String(result.get("reason", result.get("blocked_reason", "blocked")))
		context.last_message = "Drop blocked: %s." % context.blocked_reason
	_emit_state()
	return result


func teleport_to_explored(pos: Vector2i) -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	if context.intel_map == null or context.truth_map == null:
		return _blocked(&"not_ready", "not_ready")
	if not context.is_inside(pos):
		context.blocked_reason = "out_of_bounds"
		context.last_message = "Teleport target is outside the map."
		_emit_state()
		return _blocked(&"out_of_bounds", "out_of_bounds")
	var cell: Dictionary = context.intel_map.get_cell_info(pos)
	if not bool(cell.get("explored", false)) or bool(cell.get("mine", false)) or bool(cell.get("flagged", false)):
		context.blocked_reason = "not_explored_safe"
		context.last_message = "Teleport requires an explored safe room."
		_emit_state()
		return _blocked(&"not_explored_safe", "not_explored_safe")

	context.blocked_reason = ""
	context.player_pos = pos
	context.current_pos = pos
	room_resolver.enter_room(context)
	context.last_message = "Teleported to explored room (%d,%d)." % [pos.x, pos.y]
	_emit_state()
	return {"ok": true, "status": &"teleported", "position": pos, "actor_id": DEFAULT_ACTOR_ID}


func request_extract() -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", _current_blocked_reason())
	if not room_resolver.can_extract(context):
		context.blocked_reason = "cannot_extract"
		context.last_message = "Extraction requires an exit room."
		_emit_state()
		return _blocked(&"cannot_extract", "cannot_extract")
	context.phase = &"confirm_extract"
	context.last_message = "Extraction requested. Confirm or cancel."
	context.record_event(RunEventLog.EVENT_EXTRACTION_FOUND, _active_command_id(), DEFAULT_ACTOR_ID, "command_bus", {"position": context.get_current_pos(), "exit_id": context.exit_id})
	_emit_state()
	return {"ok": true, "status": &"extract_requested", "actor_id": DEFAULT_ACTOR_ID}


func confirm_extract() -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	if context.phase != &"confirm_extract":
		context.last_message = "No extraction request is active."
		_emit_state()
		return _blocked(&"no_extract_request", "no_extract_request")
	if not room_resolver.can_extract(context):
		context.phase = &"running"
		context.last_message = "Extraction cancelled: not on exit."
		_emit_state()
		return _blocked(&"cannot_extract", "cannot_extract")
	context.complete_extract()
	context.last_message = "Extraction complete."
	_emit_state()
	result_available.emit(context.result_snapshot)
	return {"ok": true, "status": &"extracted", "actor_id": DEFAULT_ACTOR_ID, "result_snapshot": context.result_snapshot.duplicate(true)}


func cancel_extract() -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	if context.phase == &"confirm_extract":
		context.phase = &"running"
		context.last_message = "Extraction cancelled."
	_emit_state()
	return {"ok": true, "status": &"extract_cancelled", "actor_id": DEFAULT_ACTOR_ID}


func extract() -> Dictionary:
	var request_result: Dictionary = request_extract()
	if context != null and context.phase == &"confirm_extract":
		return confirm_extract()
	return request_result


func restart_run() -> Dictionary:
	if context != null and context.mode == &"standard":
		return start_standard_run()
	else:
		return start_tutorial_run()


func confirm_tutorial_popup() -> Dictionary:
	TutorialService.confirm_popup(context)
	_emit_state()
	return {"ok": true, "status": &"tutorial_popup_confirmed", "actor_id": DEFAULT_ACTOR_ID}


func _can_accept_command() -> bool:
	return context != null and context.can_accept_command()


func _current_blocked_reason() -> String:
	if context == null:
		return "not_ready"
	if context.has_blocking_tutorial_popup():
		return "tutorial_lock"
	return "command_blocked"


func _mark_open_map_placeholder() -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	context.last_message = "Map overlay placeholder opened."
	_emit_state()
	return {"ok": true, "status": &"map_opened", "actor_id": DEFAULT_ACTOR_ID}


func _emit_state() -> void:
	if context != null:
		state_changed.emit(context.get_status_snapshot())


func _format_pos(pos: Vector2i) -> String:
	return "(%d,%d)" % [pos.x, pos.y]


func _normalize_command(command_name: StringName, payload: Dictionary) -> Dictionary:
	command_sequence += 1
	var actor_id: StringName = StringName(payload.get("actor_id", DEFAULT_ACTOR_ID))
	var source: String = String(payload.get("source", "ui"))
	return {
		"command_id": "cmd_%04d_%s" % [command_sequence, String(command_name)],
		"command_name": command_name,
		"actor_id": actor_id,
		"source": source,
		"payload": payload.duplicate(true),
		"sequence": command_sequence,
	}


func _blocked(status: StringName, reason: String) -> Dictionary:
	return {"ok": false, "status": status, "reason": reason, "blocked_reason": reason, "reason_code": reason, "message_key": "command.rejected.%s" % reason, "actor_id": DEFAULT_ACTOR_ID}


func _event_count() -> int:
	if context == null or context.run_event_log == null:
		return 0
	return context.run_event_log.size()


func _transaction_count() -> int:
	if context == null or context.transaction_log == null:
		return 0
	return context.transaction_log.size()


func _events_since(start_index: int) -> Array[Dictionary]:
	if context == null or context.run_event_log == null:
		return []
	return context.run_event_log.get_events_since(start_index)


func _transactions_since(start_index: int) -> Array[Dictionary]:
	if context == null or context.transaction_log == null:
		return []
	return context.transaction_log.get_entries_since(start_index)


func _snapshot_delta_for(action_result: Dictionary) -> Dictionary:
	return {
		"status": action_result.get("status", &""),
		"reason_code": String(action_result.get("reason", action_result.get("blocked_reason", ""))),
		"refresh": &"run_status",
	}


func _active_command_id() -> String:
	if context == null:
		return ""
	return String(context.active_command.get("command_id", ""))
