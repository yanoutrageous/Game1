extends "res://scripts/gameplay/interaction/g41_interactable.gd"
class_name G41GroundLootEntity

var item: Dictionary = {}


func configure_item(item_snapshot: Dictionary, spawn_local_pos: Vector2) -> void:
	item = item_snapshot.duplicate(true)
	var instance_id := String(item.get("instance_id", "missing_instance"))
	configure_interactable({
		"interaction_id": instance_id,
		"interaction_kind": &"ground_loot",
		"local_pos": spawn_local_pos,
		"interaction_radius": 0.14,
		"enabled": true,
		"visual_state": &"focused" if focused else &"idle",
		"prompt_text": "Pick up %s" % String(item.get("display_name", item.get("item_id", "item"))),
		"payload": {"instance_id": instance_id},
	})
	var placeholder := get_node_or_null("VisualRoot/ProgramPlaceholder") as Polygon2D
	if placeholder != null:
		placeholder.polygon = PackedVector2Array([Vector2(0, -9), Vector2(11, -2), Vector2(7, 9), Vector2(-7, 9), Vector2(-11, -2)])


func set_pickup_result(ok: bool) -> void:
	visual_state = &"pickup" if ok else &"blocked"
	_apply_visual_state()


func _placeholder_color() -> Color:
	if visual_state == &"blocked":
		return Color(0.92, 0.28, 0.25, 1.0)
	if focused:
		return Color(1.0, 0.88, 0.32, 1.0)
	return Color(0.34, 0.88, 0.78, 1.0)
