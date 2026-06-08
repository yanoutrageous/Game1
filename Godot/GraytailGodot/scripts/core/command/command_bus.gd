extends RefCounted
class_name CommandBus

# All player and Debug UI commands go through CommandBus.

signal command_requested(command_name: StringName, payload: Dictionary)
signal state_changed(snapshot: Dictionary)
signal result_available(summary: Dictionary)

var context: RunContext
var room_resolver := RoomResolver.new()


func dispatch(command_name: StringName, payload: Dictionary = {}) -> void:
	command_requested.emit(command_name, payload)
	match command_name:
		&"start_demo_run":
			start_demo_run()
		&"start_tutorial_run":
			start_tutorial_run()
		&"start_standard_run":
			start_standard_run()
		&"move_by":
			move_by(payload.get("delta", Vector2i.ZERO))
		&"toggle_flag_cell":
			toggle_flag_cell(payload.get("pos", null))
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


func move_by(delta: Vector2i) -> void:
	if not _can_accept_command():
		return
	if abs(delta.x) + abs(delta.y) != 1:
		context.last_message = "Invalid move: only four-direction movement is allowed."
		_emit_state()
		return
	var target := context.get_current_pos() + delta
	if not context.is_inside(target):
		context.last_message = "Blocked by map boundary."
		_emit_state()
		return
	if context.intel_map.is_flagged(target):
		context.last_message = "Blocked by flag."
		_emit_state()
		return
	if context.move_requires_revealed and not context.intel_map.is_revealed(target):
		context.last_message = "Blocked: target is not revealed."
		_emit_state()
		return

	context.player_pos = target
	context.current_pos = target
	RunInventory.record_move(context)
	room_resolver.enter_room(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)


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
