extends RefCounted
class_name Art21R2RunSmokeSeeder

const DebugGateScript := preload("res://scripts/core/debug/debug_gate.gd")

const ART21R2_MODAL_ITEM_SMOKE_FLAG := "--art21r2-seed-modal-items"
const ART21R2_MAP_MARKER_SMOKE_FLAG := "--art21r2-seed-map-markers"
const ART21R2_MAP_SPARSE_MARKER_SMOKE_FLAG := "--art21r2-seed-map-sparse-markers"


static func seed_if_requested(start_result: Dictionary, command_bus, run_context) -> void:
	_seed_art21r2_modal_smoke_items_if_requested(start_result, command_bus, run_context)
	_seed_art21r2_map_marker_smoke_if_requested(start_result, command_bus, run_context)
	_seed_art21r2_map_sparse_marker_smoke_if_requested(start_result, run_context)


static func _seed_art21r2_modal_smoke_items_if_requested(start_result: Dictionary, command_bus, run_context) -> void:
	if not bool(start_result.get("ok", false)):
		return
	if not DebugGateScript.is_debug_tools_enabled():
		return
	if not _has_cmdline_flag(ART21R2_MODAL_ITEM_SMOKE_FLAG):
		return
	if command_bus == null or run_context == null or not bool(run_context.get_status_snapshot().get("run_active", false)):
		return
	command_bus.dispatch(&"debug_spawn_test_item_floor", {"source": "debug", "art21r2_smoke": true})
	command_bus.dispatch(&"debug_spawn_test_item_backpack", {"source": "debug", "art21r2_smoke": true})


static func _seed_art21r2_map_marker_smoke_if_requested(start_result: Dictionary, command_bus, run_context) -> void:
	if not bool(start_result.get("ok", false)):
		return
	if not DebugGateScript.is_debug_tools_enabled():
		return
	if not _has_cmdline_flag(ART21R2_MAP_MARKER_SMOKE_FLAG):
		return
	if command_bus == null or run_context == null or not bool(run_context.get_status_snapshot().get("run_active", false)):
		return
	var current_pos: Vector2i = run_context.get_current_pos()
	var event_pos := Vector2i(mini(2, maxi(0, run_context.width - 1)), 0)
	if event_pos == current_pos:
		event_pos = Vector2i(mini(2, maxi(0, run_context.width - 1)), mini(1, maxi(0, run_context.height - 1)))
	if event_pos == current_pos:
		event_pos = Vector2i(0, mini(2, maxi(0, run_context.height - 1)))
	if run_context.truth_map != null and run_context.is_inside(event_pos) and event_pos != current_pos:
		run_context.truth_map.set_room_type(event_pos, &"Event")
	command_bus.dispatch(&"debug_reveal_full_map", {"source": "debug", "art21r2_map_marker_smoke": true})
	var flag_pos := Vector2i(mini(4, maxi(0, run_context.width - 1)), mini(4, maxi(0, run_context.height - 1)))
	if flag_pos == current_pos or flag_pos == event_pos:
		flag_pos = Vector2i(mini(3, maxi(0, run_context.width - 1)), mini(4, maxi(0, run_context.height - 1)))
	if flag_pos == current_pos or flag_pos == event_pos:
		flag_pos = Vector2i(mini(4, maxi(0, run_context.width - 1)), mini(3, maxi(0, run_context.height - 1)))
	if (
		run_context.intel_map != null
		and run_context.is_inside(flag_pos)
		and flag_pos != current_pos
		and flag_pos != event_pos
		and not run_context.intel_map.is_flagged(flag_pos)
	):
		run_context.intel_map.toggle_flag(flag_pos)


static func _seed_art21r2_map_sparse_marker_smoke_if_requested(start_result: Dictionary, run_context) -> void:
	if not bool(start_result.get("ok", false)):
		return
	if not DebugGateScript.is_debug_tools_enabled():
		return
	if not _has_cmdline_flag(ART21R2_MAP_SPARSE_MARKER_SMOKE_FLAG):
		return
	if run_context == null or run_context.intel_map == null or run_context.truth_map == null or not bool(run_context.get_status_snapshot().get("run_active", false)):
		return
	var current_pos: Vector2i = run_context.get_current_pos()
	var event_pos := _art21r2_map_smoke_pos(2, 1, run_context)
	var flag_pos := _art21r2_map_smoke_pos(4, 4, run_context)
	var reveal_positions := [
		current_pos,
		_art21r2_map_smoke_pos(1, 0, run_context),
		_art21r2_map_smoke_pos(1, 1, run_context),
		_art21r2_map_smoke_pos(2, 0, run_context),
		event_pos,
	]
	for pos: Vector2i in reveal_positions:
		if run_context.is_inside(pos):
			run_context.intel_map.reveal_cell(pos, run_context.truth_map)
	if run_context.is_inside(event_pos) and event_pos != current_pos:
		run_context.truth_map.set_room_type(event_pos, &"Event")
		run_context.intel_map.reveal_cell(event_pos, run_context.truth_map)
	for scan_pos: Vector2i in [_art21r2_map_smoke_pos(3, 1, run_context), _art21r2_map_smoke_pos(3, 2, run_context), _art21r2_map_smoke_pos(4, 2, run_context)]:
		if run_context.is_inside(scan_pos) and scan_pos != event_pos and scan_pos != flag_pos:
			run_context.intel_map.scan_cell(scan_pos, run_context.truth_map, &"limited", 0.70)
	if run_context.is_inside(flag_pos) and flag_pos != current_pos and flag_pos != event_pos and not run_context.intel_map.is_flagged(flag_pos):
		run_context.intel_map.toggle_flag(flag_pos)


static func _art21r2_map_smoke_pos(x: int, y: int, run_context) -> Vector2i:
	if run_context == null:
		return Vector2i.ZERO
	return Vector2i(clampi(x, 0, maxi(0, run_context.width - 1)), clampi(y, 0, maxi(0, run_context.height - 1)))


static func _has_cmdline_flag(flag: String) -> bool:
	for arg in OS.get_cmdline_args():
		if String(arg) == flag or String(arg).begins_with("%s=" % flag):
			return true
	for arg in OS.get_cmdline_user_args():
		if String(arg) == flag or String(arg).begins_with("%s=" % flag):
			return true
	return false
