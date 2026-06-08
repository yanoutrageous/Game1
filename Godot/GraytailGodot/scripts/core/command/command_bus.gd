extends RefCounted
class_name CommandBus

# TruthMap = 真实地图
# IntelMap = 玩家已知情报
# MiniMapViewModel = UI 可读数据
# UI 不得直接读取 TruthMap

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
		&"move_by":
			move_by(payload.get("delta", Vector2i.ZERO))
		&"flag_current_cell":
			flag_current_cell()
		&"interact":
			interact()
		&"extract":
			extract()
		&"restart_run":
			restart_run()
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
	context.player_pos = target
	context.current_pos = target
	room_resolver.enter_room(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.get_status_snapshot())


func flag_current_cell() -> void:
	if context == null or context.intel_map == null:
		return
	context.intel_map.flag_cell(context.get_current_pos())
	context.last_message = "Flag toggled at %s." % _format_pos(context.get_current_pos())
	_emit_state()


func interact() -> void:
	if context == null:
		return
	room_resolver.interact_current_room(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.get_status_snapshot())


func extract() -> void:
	if not _can_accept_command():
		return
	if context.current_room_type != &"Exit":
		context.last_message = "Extraction requires an Exit room."
		_emit_state()
		return
	context.extracted = true
	context.run_active = false
	context.outcome = "Extracted"
	context.last_message = "Extraction complete."
	_emit_state()
	result_available.emit(context.get_status_snapshot())


func restart_run() -> void:
	start_demo_run()


func _can_accept_command() -> bool:
	return context != null and context.run_active and not context.failed and not context.extracted


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
