extends RefCounted
class_name G41WorldObjectProjection

const ItemVisualCatalog := preload("res://scripts/presentation/art24/art24_item_visual_catalog.gd")

# Read-only projection from public run snapshots into stable room presentation
# descriptors.  This layer never resolves interactions, moves ledger items, or
# reads the hidden map.

const CHEST_LOCAL_POS := Vector2(0.68, 0.53)
const CHEST_BODY_SIZE := Vector2(0.12, 0.10)
const CHEST_INTERACTION_RADIUS := 0.18
const GROUND_INTERACTION_RADIUS := 0.14
const SPECIAL_INTERACTION_RADIUS := 0.18
const EVENT_LOCAL_POS := Vector2(0.50, 0.42)
const MINE_LOCAL_POS := Vector2(0.50, 0.51)
const EXIT_LOCAL_POS := Vector2(0.50, 0.45)

const DOOR_DIRECTIONS := [
	{"id": &"north", "delta": Vector2i.UP, "local_pos": Vector2(0.50, 0.04), "body_size": Vector2(0.16, 0.035)},
	{"id": &"east", "delta": Vector2i.RIGHT, "local_pos": Vector2(0.96, 0.50), "body_size": Vector2(0.035, 0.16)},
	{"id": &"south", "delta": Vector2i.DOWN, "local_pos": Vector2(0.50, 0.96), "body_size": Vector2(0.16, 0.035)},
	{"id": &"west", "delta": Vector2i.LEFT, "local_pos": Vector2(0.04, 0.50), "body_size": Vector2(0.035, 0.16)},
]


static func build(snapshot: Dictionary, combat_snapshot: Dictionary = {}) -> Dictionary:
	var room_pos: Vector2i = snapshot.get("position", snapshot.get("player_pos", Vector2i.ZERO))
	var room_type := StringName(snapshot.get("current_room", &"Unknown"))
	var room_key := "%d,%d" % [room_pos.x, room_pos.y]
	var world_objects: Array[Dictionary] = []
	var chest_contents: Array[Dictionary] = []
	var room_floor_items := _dictionary_array(snapshot.get("room_floor_items", []))

	if room_type == &"Chest":
		world_objects.append(_chest_projection(snapshot, room_key))
		# In a Chest room these ledger instances are container contents.  They
		# must not also become floor entities with a second interaction anchor.
		chest_contents = room_floor_items
	else:
		var special_projection := _special_room_projection(snapshot, room_type, room_key)
		if not special_projection.is_empty():
			world_objects.append(special_projection)
		for item in room_floor_items:
			world_objects.append(_ground_loot_projection(item))

	return {
		"projection_contract": &"i2.world_object_projection.v1",
		"room_key": room_key,
		"room_type": room_type,
		"world_objects": world_objects,
		"chest_contents": chest_contents,
		"doors": _door_projections(snapshot, combat_snapshot, room_pos, room_key),
		"read_only": true,
		"authority": &"public_snapshot_only",
	}


static func _special_room_projection(snapshot: Dictionary, room_type: StringName, room_key: String) -> Dictionary:
	match room_type:
		&"Event":
			return _event_projection(snapshot, room_key)
		&"Mine":
			return _mine_projection(snapshot, room_key)
		&"Exit":
			return _exit_projection(snapshot, room_key)
	return {}


static func _event_projection(snapshot: Dictionary, room_key: String) -> Dictionary:
	var event_state: Dictionary = snapshot.get("event_state", {})
	var encounter_view: Dictionary = snapshot.get("encounter_view_model", {})
	var encounter_state: Dictionary = encounter_view.get("state", {})
	var event_type := StringName(event_state.get("event_type", encounter_view.get("encounter_type", &"trader")))
	var completed := bool(event_state.get("completed", encounter_state.get("completed", StringName(encounter_state.get("state", &"available")) == &"completed")))
	var title := _event_title(event_type)
	return _descriptor({
		"projection_id": "event:%s" % room_key,
		"interaction_kind": &"event",
		"local_pos": EVENT_LOCAL_POS,
		"interaction_radius": SPECIAL_INTERACTION_RADIUS,
		"body_rect": _centered_rect(EVENT_LOCAL_POS, Vector2(0.085, 0.085)),
		"context_anchor_local": EVENT_LOCAL_POS + Vector2(0.0, -0.09),
		"visual_state": &"completed" if completed else &"available",
		"visual_key": StringName("ui.art25.long_term.event.%s" % String(event_type)),
		"depth_key": &"world.interactable.event",
		# A completed event remains inspectable, but display_only prevents a new
		# event command or a second settlement.
		"enabled": true,
		"prompt_text": "事件已处理" if completed else "查看%s" % title,
		"payload": {
			"room_key": room_key,
			"event_type": event_type,
			"completed": completed,
			"display_only": completed,
			"display_title": title,
			"summary": "已经处理，不会重复结算。" if completed else "靠近后可查看处理方式。",
		},
	})


static func _mine_projection(snapshot: Dictionary, room_key: String) -> Dictionary:
	var room_detail: Dictionary = snapshot.get("current_room_detail", {})
	var triggered := bool(room_detail.get("triggered", false))
	return _descriptor({
		"projection_id": "mine:%s" % room_key,
		"interaction_kind": &"mine",
		"local_pos": MINE_LOCAL_POS,
		"interaction_radius": SPECIAL_INTERACTION_RADIUS,
		"body_rect": _centered_rect(MINE_LOCAL_POS, Vector2(0.075, 0.065)),
		"context_anchor_local": MINE_LOCAL_POS + Vector2(0.0, -0.075),
		"visual_state": &"resolved" if triggered else &"armed",
		"visual_key": &"visual.art24.prop.mine",
		"depth_key": &"world.interactable.mine",
		"enabled": true,
		"prompt_text": "",
		"payload": {
			"room_key": room_key,
			"triggered": triggered,
			"display_only": true,
			"display_title": "雷区机关",
			"summary": "已失效，不会再次造成伤害。" if triggered else "保持距离，留意地面机关。",
		},
	})


static func _exit_projection(snapshot: Dictionary, room_key: String) -> Dictionary:
	var inventory_items: Array = snapshot.get("inventory_items", [])
	var safe_yield := int(snapshot.get("safe_yield", snapshot.get("gold_coin", snapshot.get("safe_gold", 0))))
	var black_coin := int(snapshot.get("black_coin", snapshot.get("run_black_coin", snapshot.get("pending_gold", 0))))
	var backpack_used := int(snapshot.get("backpack_used", 0))
	var backpack_capacity := int(snapshot.get("backpack_capacity", 0))
	var room_floor_item_count := int(snapshot.get("room_floor_item_count", (snapshot.get("room_floor_items", []) as Array).size()))
	var objective_summary := _objective_summary(snapshot)
	return _descriptor({
		"projection_id": "exit:%s" % room_key,
		"interaction_kind": &"exit",
		"local_pos": EXIT_LOCAL_POS,
		"interaction_radius": 0.20,
		"body_rect": _centered_rect(EXIT_LOCAL_POS, Vector2(0.10, 0.10)),
		"context_anchor_local": EXIT_LOCAL_POS + Vector2(0.0, -0.10),
		"visual_state": &"available",
		"visual_key": &"visual.art24.fx.beacon_pulse.0",
		"depth_key": &"world.interactable.exit",
		"enabled": true,
		"prompt_text": "查看撤离摘要",
		"payload": {
			"room_key": room_key,
			"display_title": "撤离信标",
			"summary": "黑币 %d · 安全收益 %d · 背包 %d/%d · 当前房间遗留 %d" % [black_coin, safe_yield, backpack_used, backpack_capacity, room_floor_item_count],
			"safe_yield": safe_yield,
			"black_coin": black_coin,
			"inventory_count": inventory_items.size(),
			"backpack_used": backpack_used,
			"backpack_capacity": backpack_capacity,
			"room_floor_item_count": room_floor_item_count,
			"objective_summary": objective_summary,
		},
	})


static func _event_title(event_type: StringName) -> String:
	match event_type:
		&"trader":
			return "旅商"
		&"dice":
			return "骰局"
		&"altar":
			return "祭坛"
		&"trap":
			return "机关"
	return "异常事件"


static func _objective_summary(snapshot: Dictionary) -> String:
	for raw_summary in [
		snapshot.get("selected_objective_summary", ""),
		snapshot.get("objective_summary", ""),
		(snapshot.get("objective_context_preview", {}) as Dictionary).get("selected_objective_summary", ""),
	]:
		var configured := String(raw_summary).strip_edges()
		if configured != "":
			return configured
	var run_start: Dictionary = snapshot.get("run_start_config", {})
	var configured_start_summary := String(run_start.get("selected_objective_summary", "")).strip_edges()
	if configured_start_summary != "":
		return configured_start_summary
	var label := String(run_start.get("selected_objective_label", "")).strip_edges()
	if label == "":
		return "本次探索未设置额外委托。"
	return label


static func _chest_projection(snapshot: Dictionary, room_key: String) -> Dictionary:
	var search_state: Dictionary = snapshot.get("search_state_data", {})
	var opened := bool(search_state.get("searched", false))
	return _descriptor({
		"projection_id": "chest:%s" % room_key,
		"interaction_kind": &"chest",
		"local_pos": CHEST_LOCAL_POS,
		"interaction_radius": CHEST_INTERACTION_RADIUS,
		"body_rect": _centered_rect(CHEST_LOCAL_POS, CHEST_BODY_SIZE),
		"context_anchor_local": CHEST_LOCAL_POS + Vector2(0.0, -0.075),
		"visual_state": &"opened" if opened else &"closed",
		"visual_key": &"visual.art24.prop.chest_open_state" if opened else &"visual.art24.prop.chest_closed",
		"depth_key": &"world.interactable.chest",
		"enabled": true,
		"prompt_text": "查看物资" if opened else "打开物资箱",
		"payload": {"room_key": room_key, "opened": opened},
	})


static func _ground_loot_projection(item: Dictionary) -> Dictionary:
	var instance_id := String(item.get("instance_id", "missing_instance"))
	var local_pos := _loot_position_for(instance_id)
	var item_id := String(item.get("item_id", item.get("definition_id", "回收物")))
	return _descriptor({
		"projection_id": instance_id,
		"interaction_kind": &"ground_loot",
		"local_pos": local_pos,
		"interaction_radius": GROUND_INTERACTION_RADIUS,
		"body_rect": _centered_rect(local_pos, Vector2(0.055, 0.055)),
		"context_anchor_local": local_pos + Vector2(0.0, -0.06),
		"visual_state": &"idle",
		"visual_key": ItemVisualCatalog.visual_key(item),
		"depth_key": &"world.interactable.loot",
		"enabled": true,
		"prompt_text": "拾取 %s" % String(item.get("display_name", item_id)),
		"payload": {"instance_id": instance_id, "item": item.duplicate(true)},
	})


static func _door_projections(snapshot: Dictionary, combat_snapshot: Dictionary, room_pos: Vector2i, room_key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var width := int(snapshot.get("width", 0))
	var height := int(snapshot.get("height", 0))
	var run_start_config: Dictionary = snapshot.get("run_start_config", {})
	var requires_revealed := bool(snapshot.get("move_requires_revealed", run_start_config.get("move_requires_revealed", false)))
	var combat_restricted := bool(combat_snapshot.get("door_locked", false))
	var known_cells := _known_public_cells(snapshot)
	for door in DOOR_DIRECTIONS:
		var direction: Vector2i = door.get("delta", Vector2i.ZERO)
		var target := room_pos + direction
		var state := &"available"
		var public_cell := _public_cell_at(known_cells, target)
		if target.x < 0 or target.y < 0 or target.x >= width or target.y >= height:
			state = &"blocked_out_of_bounds"
		elif bool(public_cell.get("flagged", false)):
			state = &"blocked_flagged"
		elif requires_revealed and not bool(public_cell.get("revealed", false)):
			state = &"blocked_hidden"
		elif combat_restricted:
			state = &"combat_restricted"
		var local_pos: Vector2 = door.get("local_pos", Vector2(0.5, 0.5))
		var body_size: Vector2 = door.get("body_size", Vector2(0.04, 0.12))
		result.append(_descriptor({
			"projection_id": "door:%s:%s" % [room_key, String(door.get("id", &"unknown"))],
			"interaction_kind": &"door_projection",
			"local_pos": local_pos,
			"interaction_radius": 0.0,
			"body_rect": _centered_rect(local_pos, body_size),
			"context_anchor_local": local_pos,
			"visual_state": state,
			"visual_key": StringName("runtime.door.%s" % String(state)),
			"depth_key": &"world.door",
			"enabled": false,
			"prompt_text": "",
			"payload": {"direction": direction, "target": target},
		}))
	return result


static func _descriptor(values: Dictionary) -> Dictionary:
	return {
		"projection_id": String(values.get("projection_id", "")),
		"interaction_kind": StringName(values.get("interaction_kind", &"unknown")),
		"local_pos": Vector2(values.get("local_pos", Vector2.ZERO)),
		"interaction_radius": maxf(0.0, float(values.get("interaction_radius", 0.0))),
		"body_rect": Rect2(values.get("body_rect", Rect2())),
		"context_anchor_local": Vector2(values.get("context_anchor_local", values.get("local_pos", Vector2.ZERO))),
		"visual_state": StringName(values.get("visual_state", &"idle")),
		"visual_key": StringName(values.get("visual_key", &"runtime.missing")),
		"depth_key": StringName(values.get("depth_key", &"world.default")),
		"enabled": bool(values.get("enabled", false)),
		"prompt_text": String(values.get("prompt_text", "")),
		"payload": (values.get("payload", {}) as Dictionary).duplicate(true),
	}


static func _known_public_cells(snapshot: Dictionary) -> Array:
	var run_map_snapshot: Dictionary = snapshot.get("run_map_snapshot", {})
	var known_map: Dictionary = run_map_snapshot.get("KnownMap", snapshot.get("KnownMap", {}))
	var cells: Variant = known_map.get("public_cells", [])
	return cells if cells is Array else []


static func _public_cell_at(cells: Array, target: Vector2i) -> Dictionary:
	for raw_cell in cells:
		if raw_cell is Dictionary and Vector2i((raw_cell as Dictionary).get("pos", Vector2i(-1, -1))) == target:
			return raw_cell as Dictionary
	return {}


static func _loot_position_for(instance_id: String) -> Vector2:
	var hash_value := absi(instance_id.hash())
	var column := hash_value % 4
	var row := (hash_value / 4) % 3
	return Vector2(0.38 + float(column) * 0.085, 0.58 + float(row) * 0.075)


static func _centered_rect(center: Vector2, size: Vector2) -> Rect2:
	return Rect2(center - size * 0.5, size)


static func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for raw_item in value as Array:
			if raw_item is Dictionary:
				result.append((raw_item as Dictionary).duplicate(true))
	return result
