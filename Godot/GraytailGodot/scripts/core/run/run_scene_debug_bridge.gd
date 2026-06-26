extends RefCounted
class_name RunSceneDebugBridge

const DebugGateScript := preload("res://scripts/core/debug/debug_gate.gd")


static func can_use_debug_tools() -> bool:
	return DebugGateScript.is_debug_tools_enabled()


static func disabled_feedback(actor_id: StringName = &"player") -> Dictionary:
	return DebugGateScript.disabled_result(actor_id)


static func nearest_room_of_type(context: RunContext, room_type: StringName) -> Vector2i:
	if context == null or context.truth_map == null:
		return Vector2i(-1, -1)
	var current := context.get_current_pos()
	var best := Vector2i(-1, -1)
	var best_distance := 999999
	for y in range(context.truth_map.height):
		for x in range(context.truth_map.width):
			var pos := Vector2i(x, y)
			if context.truth_map.get_room_type(pos) != room_type:
				continue
			var distance: int = abs(pos.x - current.x) + abs(pos.y - current.y)
			if distance < best_distance:
				best_distance = distance
				best = pos
	return best


static func debug_result_message(prefix: String, summary: Dictionary) -> String:
	if bool(summary.get("write_blocked", false)):
		return "%s blocked: %s" % [prefix, summary.get("write_block_reason", "write_blocked")]
	return "%s gold=%s items=%s" % [prefix, summary.get("gold", 0), summary.get("warehouse_items_count", 0)]
