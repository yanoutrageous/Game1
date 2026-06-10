extends RefCounted
class_name CommandBus

# All player and Debug UI commands go through CommandBus.

signal command_requested(command_name: StringName, payload: Dictionary)
signal state_changed(snapshot: Dictionary)
signal result_available(summary: Dictionary)

const DEFAULT_ACTOR_ID := &"player"

var context: RunContext
var room_resolver := RoomResolver.new()
var command_sequence: int = 0


func dispatch(command_name: StringName, payload: Dictionary = {}) -> void:
	var command := _normalize_command(command_name, payload)
	var command_payload: Dictionary = command.get("payload", {})
	command_requested.emit(command_name, command)
	match command_name:
		&"start_demo_run":
			start_demo_run()
		&"start_tutorial_run":
			start_tutorial_run()
		&"start_standard_run":
			start_standard_run()
		&"move_by":
			move_by(command_payload.get("delta", Vector2i.ZERO))
		&"attempt_room_transition":
			attempt_room_transition(command_payload.get("direction", Vector2i.ZERO))
		&"toggle_flag_cell":
			toggle_flag_cell(command_payload.get("pos", null))
		&"flag_current_cell":
			flag_current_cell()
		&"search_current_room":
			search_current_room()
		&"interact_current_room":
			interact_current_room()
		&"interact":
			interact()
		&"fight_current_enemy":
			fight_current_enemy()
		&"teleport_to_explored":
			teleport_to_explored(command_payload.get("pos", Vector2i.ZERO))
		&"select_event_option":
			select_event_option(StringName(command_payload.get("option_id", &"default")))
		&"pickup_ground_item":
			pickup_ground_item(String(command_payload.get("instance_id", "")))
		&"drop_inventory_item":
			drop_inventory_item(String(command_payload.get("instance_id", "")))
		&"request_extract":
			request_extract()
		&"confirm_extract":
			confirm_extract()
		&"cancel_extract":
			cancel_extract()
		&"extract":
			extract()
		&"restart_run":
			restart_run()
		&"confirm_tutorial_popup":
			confirm_tutorial_popup()
		&"open_map":
			_mark_open_map_placeholder()


func bind_context(next_context: RunContext) -> void:
	context = next_context
	if context != null and context.run_active:
		room_resolver.enter_room(context)
		_emit_state()


func start_demo_run() -> void:
	if context == null:
		context = RunContext.new()
	context.reset_demo_run()
	room_resolver.enter_room(context)
	_emit_state()


func start_tutorial_run() -> void:
	if context == null:
		context = RunContext.new()
	context.start_tutorial_run()
	room_resolver.enter_room(context)
	_emit_state()


func start_standard_run() -> void:
	if context == null:
		context = RunContext.new()
	context.start_standard_run()
	room_resolver.enter_room(context)
	_emit_state()


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
	var target := context.get_current_pos() + delta
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


func toggle_flag_cell(pos = null) -> void:
	if context == null or context.intel_map == null:
		return
	var target: Vector2i = context.get_current_pos() if pos == null else pos
	context.intel_map.toggle_flag(target)
	context.last_message = "Flag toggled at %s." % _format_pos(target)
	_emit_state()


func flag_current_cell() -> void:
	toggle_flag_cell()


func search_current_room() -> void:
	if not _can_accept_command():
		return
	room_resolver.search_current_room(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)


func interact_current_room() -> void:
	if not _can_accept_command():
		return
	if context.current_room_type == &"Exit":
		if context.phase == &"confirm_extract":
			confirm_extract()
		else:
			request_extract()
		return
	room_resolver.interact_current_room(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)


func interact() -> void:
	interact_current_room()


func fight_current_enemy() -> void:
	if not _can_accept_command():
		return
	room_resolver.fight_current_enemy(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)


func select_event_option(option_id: StringName = &"default") -> void:
	if not _can_accept_command():
		return
	room_resolver.select_event_option(context, option_id)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)


func pickup_ground_item(instance_id: String = "") -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	var result := RunRuleService.pickup_ground_item(context, instance_id)
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
	var result := RunRuleService.drop_inventory_item(context, instance_id)
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
	var cell := context.intel_map.get_cell_info(pos)
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


func request_extract() -> void:
	if not _can_accept_command():
		return
	if not room_resolver.can_extract(context):
		context.last_message = "Extraction requires an exit room."
		_emit_state()
		return
	context.phase = &"confirm_extract"
	context.last_message = "Extraction requested. Confirm or cancel."
	_emit_state()


func confirm_extract() -> void:
	if context == null:
		return
	if context.phase != &"confirm_extract":
		context.last_message = "No extraction request is active."
		_emit_state()
		return
	if not room_resolver.can_extract(context):
		context.phase = &"running"
		context.last_message = "Extraction cancelled: not on exit."
		_emit_state()
		return
	context.complete_extract()
	context.last_message = "Extraction complete."
	_emit_state()
	result_available.emit(context.result_snapshot)


func cancel_extract() -> void:
	if context == null:
		return
	if context.phase == &"confirm_extract":
		context.phase = &"running"
		context.last_message = "Extraction cancelled."
	_emit_state()


func extract() -> void:
	request_extract()
	if context != null and context.phase == &"confirm_extract":
		confirm_extract()


func restart_run() -> void:
	if context != null and context.mode == &"standard":
		start_standard_run()
	else:
		start_tutorial_run()


func confirm_tutorial_popup() -> void:
	TutorialService.confirm_popup(context)
	_emit_state()


func _can_accept_command() -> bool:
	return context != null and context.can_accept_command()


func _mark_open_map_placeholder() -> void:
	if context == null:
		return
	context.last_message = "Map overlay placeholder opened."
	_emit_state()


func _emit_state() -> void:
	if context != null:
		state_changed.emit(context.get_status_snapshot())


func _format_pos(pos: Vector2i) -> String:
	return "(%d,%d)" % [pos.x, pos.y]


func _normalize_command(command_name: StringName, payload: Dictionary) -> Dictionary:
	command_sequence += 1
	var actor_id := StringName(payload.get("actor_id", DEFAULT_ACTOR_ID))
	var source := String(payload.get("source", "ui"))
	return {
		"command_id": "cmd_%04d_%s" % [command_sequence, String(command_name)],
		"command_name": command_name,
		"actor_id": actor_id,
		"source": source,
		"payload": payload.duplicate(true),
		"sequence": command_sequence,
	}


func _blocked(status: StringName, reason: String) -> Dictionary:
	return {"ok": false, "status": status, "reason": reason, "blocked_reason": reason, "actor_id": DEFAULT_ACTOR_ID}
