extends SceneTree

const PopupScript := preload("res://scripts/gameplay/interaction/g41_world_context_popup.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Control.new()
	world.size = Vector2(1280, 720)
	root.add_child(world)
	var popup: G41WorldContextPopup = PopupScript.new()
	world.add_child(popup)
	await process_frame
	popup.apply_context({
		"interaction_kind": &"chest",
		"world_pos": Vector2(719, 387),
		"room_bounds": Rect2(304, 72, 820, 560),
		"opened_once": false,
		"container_open": false,
		"items": [],
		"inventory_items": [],
		"backpack_remaining": 10,
	})
	await process_frame
	await process_frame
	_dump_control(popup, 0)
	var errors: Array[String] = []
	if popup.size.y > 150.0:
		errors.append("closed chest popup height %.1f exceeds compact 150px budget" % popup.size.y)
	if popup.size.x < 300.0 or popup.size.x > 332.0:
		errors.append("popup width %.1f escaped 300..332px budget" % popup.size.x)
	var popup_rect := Rect2(popup.position, popup.size * popup.scale)
	var target_clearance_screen := minf(absf(719.0 - popup_rect.end.x), absf(popup_rect.position.x - 719.0))
	if target_clearance_screen < 40.0 or target_clearance_screen > 72.0:
		errors.append("closed chest popup target clearance %.1f escaped 40..72px" % target_clearance_screen)
	var safe_rect := Rect2(Vector2(304, 72), Vector2(820, 560))
	if not safe_rect.encloses(popup_rect):
		errors.append("closed chest popup escaped the central UI lane: %s" % popup_rect)
	popup.apply_context({
		"interaction_kind": &"ground_loot",
		"world_pos": Vector2(720, 470),
		"room_bounds": safe_rect,
		"items": [{
			"instance_id": "probe_ground_item",
			"display_name": "温热条款",
			"rarity": &"tier_4",
			"weight": 2,
		}],
		"inventory_items": [],
		"backpack_remaining": 10,
	})
	await process_frame
	await process_frame
	var loot_rect := Rect2(popup.position, popup.size * popup.scale)
	var loot_anchor := Vector2(720, 470)
	if loot_rect.has_point(loot_anchor):
		errors.append("ground loot popup covers target anchor: rect=%s anchor=%s" % [loot_rect, loot_anchor])
	if not safe_rect.encloses(loot_rect):
		errors.append("ground loot popup escaped the central UI lane: %s" % loot_rect)
	var horizontal_clearance := maxf(loot_rect.position.x - loot_anchor.x, loot_anchor.x - loot_rect.end.x)
	var vertical_clearance := maxf(loot_rect.position.y - loot_anchor.y, loot_anchor.y - loot_rect.end.y)
	var target_gap_screen := maxf(horizontal_clearance, vertical_clearance)
	if target_gap_screen < 28.0:
		errors.append("ground loot popup target gap %.1f below 28px" % target_gap_screen)
	if errors.is_empty():
		print("ART24_WORLD_CONTEXT_POPUP_LAYOUT=PASS closed_chest=%s ground_loot_target_clear" % popup.size)
		quit(0)
		return
	for error in errors:
		push_error(error)
	quit(1)


func _dump_control(node: Node, depth: int) -> void:
	if node is Control:
		var control := node as Control
		print("%s%s visible=%s pos=%s size=%s min=%s custom=%s anchors=(%.1f,%.1f,%.1f,%.1f) offsets=(%.1f,%.1f,%.1f,%.1f) flags_v=%s" % [
			"  ".repeat(depth),
			control.name,
			control.visible,
			control.position,
			control.size,
			control.get_combined_minimum_size(),
			control.custom_minimum_size,
			control.anchor_left,
			control.anchor_top,
			control.anchor_right,
			control.anchor_bottom,
			control.offset_left,
			control.offset_top,
			control.offset_right,
			control.offset_bottom,
			control.size_flags_vertical,
		])
	for child in node.get_children():
		_dump_control(child, depth + 1)
