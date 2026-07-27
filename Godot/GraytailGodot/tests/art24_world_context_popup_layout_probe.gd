extends SceneTree

const PopupScript := preload("res://scripts/gameplay/interaction/g41_world_context_popup.gd")
const RuntimeLayoutScript := preload("res://scripts/gameplay/runtime/g41_runtime_layout.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Control.new()
	world.size = Vector2(1280, 720)
	root.add_child(world)
	var popup: G41WorldContextPopup = PopupScript.new()
	world.add_child(popup)
	await process_frame
	var safe_rect := RuntimeLayoutScript.context_ui_rect_for_viewport(Vector2(1280, 720))
	var reserved_rects := RuntimeLayoutScript.context_reserved_rects_for_viewport(Vector2(1280, 720))
	var gameplay_rect := Rect2(Vector2(515, 8), Vector2(545, 545))
	var feedback_reserve_rect := Rect2(
		Vector2(safe_rect.position.x, safe_rect.end.y),
		Vector2(safe_rect.size.x, RuntimeLayoutScript.CONTEXT_FEEDBACK_RESERVE_HEIGHT)
	)
	popup.apply_context({
		"interaction_kind": &"chest",
		"world_pos": Vector2(719, 387),
		"player_world_pos": Vector2(752, 394),
		"room_bounds": safe_rect,
		"gameplay_focus_rect": gameplay_rect,
		"reserved_rects": reserved_rects,
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
	if not safe_rect.encloses(popup_rect):
		errors.append("closed chest popup escaped the central UI lane: %s" % popup_rect)
	var object_clearance: Rect2 = popup.get_meta("object_clearance_rect", Rect2())
	var player_clearance: Rect2 = popup.get_meta("player_clearance_rect", Rect2())
	if popup_rect.intersects(object_clearance):
		errors.append("closed chest popup obscures its object focus: %s" % popup_rect)
	if popup_rect.intersects(player_clearance):
		errors.append("closed chest popup obscures the player focus: %s" % popup_rect)
	if not (popup.get_theme_stylebox(&"panel") is StyleBoxTexture):
		errors.append("closed chest popup retained a flat plastic frame")
	popup.apply_context({
		"interaction_kind": &"chest",
		"world_pos": Vector2(719, 387),
		"player_world_pos": Vector2(752, 394),
		"room_bounds": safe_rect,
		"gameplay_focus_rect": gameplay_rect,
		"reserved_rects": reserved_rects,
		"opened_once": true,
		"container_open": true,
		"items": [{
			"instance_id": "probe_open_chest_item",
			"display_name": "温热条款",
			"rarity": &"tier_4",
			"weight": 2,
		}],
		"inventory_items": [],
		"backpack_remaining": 10,
	})
	await process_frame
	await process_frame
	var open_chest_rect := Rect2(popup.position, popup.size * popup.scale)
	if not safe_rect.encloses(open_chest_rect):
		errors.append("opened chest popup escaped the central UI lane: %s" % open_chest_rect)
	var open_chest_object_clearance: Rect2 = popup.get_meta("object_clearance_rect", Rect2())
	var open_chest_player_clearance: Rect2 = popup.get_meta("player_clearance_rect", Rect2())
	if open_chest_rect.intersects(open_chest_object_clearance):
		errors.append("opened chest popup obscures its object focus: %s" % open_chest_rect)
	if open_chest_rect.intersects(open_chest_player_clearance):
		errors.append("opened chest popup obscures the player focus: %s" % open_chest_rect)
	if open_chest_rect.intersects(feedback_reserve_rect):
		errors.append("opened chest popup entered the bottom feedback reserve lane: %s" % open_chest_rect)
	popup.apply_context({
		"interaction_kind": &"ground_loot",
		"world_pos": Vector2(720, 470),
		"player_world_pos": Vector2(752, 474),
		"room_bounds": safe_rect,
		"gameplay_focus_rect": gameplay_rect,
		"reserved_rects": reserved_rects,
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
	var loot_object_clearance: Rect2 = popup.get_meta("object_clearance_rect", Rect2())
	var loot_player_clearance: Rect2 = popup.get_meta("player_clearance_rect", Rect2())
	if loot_rect.intersects(loot_object_clearance):
		errors.append("ground loot popup overlaps target clearance: %s" % loot_rect)
	if loot_rect.intersects(loot_player_clearance):
		errors.append("ground loot popup overlaps player clearance: %s" % loot_rect)
	if errors.is_empty():
		print("ART24_WORLD_CONTEXT_POPUP_LAYOUT=PASS closed_chest_compact opened_chest_focus_clear ground_loot_target_clear")
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
