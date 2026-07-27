extends RefCounted
class_name DeployMapProjection

const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")

const PAGE_ID := &"deploy_prep"
const TAB_ID := &"map"
const FAMILY_ID := &"classic_minesweeper"
const FAMILY_DISPLAY_NAME := "常规扫雷"
const SCALE_IDS := [&"5x5", &"7x7", &"10x10", &"13x13"]


static func project(config: Dictionary) -> Dictionary:
	var unlocked_map_ids := _array_copy(config.get("unlocked_map_ids", []))
	var tutorial_completed := bool(config.get("tutorial_completed", false))
	var selected_map_id := str(config.get("map_config_id", ""))
	var active_run_locked := bool(config.get("active_run_locked", false))
	var selected_definition := M7ContentCatalogScript.map_definition_exact(selected_map_id)
	var selected_scale := scale_for_map(selected_map_id)
	var selected_scale_id := StringName(selected_scale.get("scale_id", &""))
	var known_unlocked_count := 0
	for raw_map_id in unlocked_map_ids:
		if not M7ContentCatalogScript.map_definition_exact(str(raw_map_id)).is_empty():
			known_unlocked_count += 1
	var scale_options: Array[Dictionary] = []
	var difficulty_options: Array[Dictionary] = []
	var selected_detail: Dictionary = {}
	for raw_group in scale_groups(unlocked_map_ids):
		var group := raw_group.duplicate(true)
		var maps: Array[Dictionary] = []
		var unlocked_count := 0
		for raw_projection in group.get("maps", []):
			var map_projection := (raw_projection as Dictionary).duplicate(true)
			var map_id := str(map_projection.get("map_config_id", ""))
			if map_id == "tutorial_5x5":
				map_projection["tutorial_completed"] = tutorial_completed
				map_projection["completion_label"] = "已完成 · 可重播" if tutorial_completed else "未完成"
			var is_unlocked := bool(map_projection.get("unlocked", false))
			var is_selected := map_id == selected_map_id
			if is_unlocked:
				unlocked_count += 1
			var reason_code := &"ok"
			if active_run_locked:
				reason_code = &"active_run_locked"
			elif known_unlocked_count == 0:
				reason_code = &"no_maps_available"
			elif not is_unlocked:
				reason_code = &"map_locked"
			map_projection["selected"] = is_selected
			map_projection["select_action"] = {
				"action": &"select_map",
				"map_config_id": map_id,
				"enabled": reason_code == &"ok",
				"reason_code": reason_code,
			}
			maps.append(map_projection)
			if is_selected:
				selected_detail = map_projection.duplicate(true)
		group["maps"] = maps
		group["map_ids"] = _map_ids(maps)
		group["unlocked_count"] = unlocked_count
		group["selected"] = StringName(group.get("scale_id", &"")) == selected_scale_id
		group["enabled"] = unlocked_count > 0 and not active_run_locked
		scale_options.append(group)
		if bool(group.get("selected", false)):
			difficulty_options = maps.duplicate(true)
	var expected_difficulty := StringName(selected_definition.get("difficulty", &""))
	var configured_difficulty := StringName(config.get("difficulty", &""))
	var selected_difficulty := StringName(config.get("selected_difficulty", configured_difficulty))
	return {
		"page_id": PAGE_ID,
		"tab_id": TAB_ID,
		"family_id": FAMILY_ID,
		"family_display_name": FAMILY_DISPLAY_NAME,
		"route_page_id": PAGE_ID,
		"fallback_policy": &"fail_closed",
		"selected_map_id": selected_map_id,
		"selected_scale_id": selected_scale_id,
		"selection_exact": not selected_definition.is_empty(),
		"selection_unlocked": not selected_definition.is_empty() and unlocked_map_ids.has(selected_map_id),
		"difficulty_matches": not selected_definition.is_empty() and configured_difficulty == expected_difficulty and selected_difficulty == expected_difficulty,
		"active_run_locked": active_run_locked,
		"scale_options": scale_options,
		"difficulty_options": difficulty_options,
		"selected_detail": selected_detail,
	}


static func build(config: Dictionary) -> Dictionary:
	return project(config)


static func project_catalog(unlocked_map_ids: Array = []) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in M7ContentCatalogScript.map_definitions():
		var map_id := str(definition.get("id", ""))
		var projection := project_map(map_id, unlocked_map_ids)
		if not projection.is_empty():
			result.append(projection)
	return result


static func project_map(map_id: String, unlocked_map_ids: Array = []) -> Dictionary:
	var definition := M7ContentCatalogScript.map_definition_exact(map_id)
	if definition.is_empty():
		return {}
	var scale := scale_for_map(map_id)
	if scale.is_empty():
		return {}
	return {
		"map_config_id": map_id,
		"page_id": PAGE_ID,
		"tab_id": TAB_ID,
		"family_id": FAMILY_ID,
		"family_display_name": FAMILY_DISPLAY_NAME,
		"scale_id": StringName(scale.get("scale_id", &"")),
		"scale_label": str(scale.get("scale_label", "")),
		"width": int(definition.get("width", 0)),
		"height": int(definition.get("height", 0)),
		"display_name": str(definition.get("display_name", map_id)),
		"role": str(definition.get("role", "")),
		"difficulty": StringName(definition.get("difficulty", &"")),
		"difficulty_label": str(definition.get("difficulty_label", "")),
		"mine_count": int(definition.get("mine_count", 0)),
		"content_room_count": int(definition.get("content_room_count", 0)),
		"event_room_count": int(definition.get("event_room_count", definition.get("content_room_count", 0))),
		"monster_room_count": int(definition.get("monster_room_count", definition.get("content_room_count", 0))),
		"chest_room_count": int(definition.get("chest_room_count", definition.get("content_room_count", 0))),
		"visible_exit_count": int(definition.get("visible_exit_count", 0)),
		"hidden_exit_count": int(definition.get("hidden_exit_count", 0)),
		"visible_exit_position_known": bool(definition.get("visible_exit_position_known", false)),
		"success_exp": int(definition.get("success_exp", 0)),
		"mode": StringName(definition.get("mode", &"standard")),
		"map_mode": StringName(definition.get("map_mode", &"classic_minesweeper")),
		"tutorial_map": bool(definition.get("tutorial_map", false)),
		"persistent_progression": bool(definition.get("persistent_progression", true)),
		"unlocked": unlocked_map_ids.has(map_id),
	}


static func scale_groups(unlocked_map_ids: Array = []) -> Array[Dictionary]:
	var catalog := project_catalog(unlocked_map_ids)
	var result: Array[Dictionary] = []
	for scale_id in SCALE_IDS:
		var scale := _scale_definition(scale_id)
		var maps: Array[Dictionary] = []
		for projection in catalog:
			if StringName(projection.get("scale_id", &"")) == scale_id:
				maps.append(projection.duplicate(true))
		scale["maps"] = maps
		scale["map_count"] = maps.size()
		result.append(scale)
	return result


static func scale_for_map(map_id: String) -> Dictionary:
	var definition := M7ContentCatalogScript.map_definition_exact(map_id)
	if definition.is_empty():
		return {}
	var width := int(definition.get("width", 0))
	var height := int(definition.get("height", 0))
	if width != height:
		return {}
	return _scale_definition(StringName("%dx%d" % [width, height]))


static func _scale_definition(scale_id: StringName) -> Dictionary:
	if not SCALE_IDS.has(scale_id):
		return {}
	var side := int(String(scale_id).get_slice("x", 0))
	return {
		"page_id": PAGE_ID,
		"tab_id": TAB_ID,
		"family_id": FAMILY_ID,
		"family_display_name": FAMILY_DISPLAY_NAME,
		"scale_id": scale_id,
		"scale_label": "%d×%d" % [side, side],
		"display_name": "%d×%d" % [side, side],
		"map_name": "教学演练" if scale_id == &"5x5" else FAMILY_DISPLAY_NAME,
		"width": side,
		"height": side,
	}


static func _map_ids(maps: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for map_projection in maps:
		result.append(str(map_projection.get("map_config_id", "")))
	return result


static func _array_copy(value: Variant) -> Array:
	return (value as Array).duplicate(true) if value is Array else []
