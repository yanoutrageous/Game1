extends Control
class_name DeployMapSplitView

const DeployPrepLayoutContractScript := preload("res://scripts/ui/deploy_prep/deploy_prep_layout_contract.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art22DeployPrepAssetContractScript := preload("res://scripts/presentation/art22_deploy_prep_asset_contract.gd")
const Art25ContentAssetContractScript := preload("res://scripts/presentation/art25_content_asset_contract.gd")

signal scale_requested(scale_id: StringName)
signal map_requested(map_config_id: StringName)

const EXPECTED_SCALE_IDS := [&"7x7", &"10x10", &"13x13"]

var current_projection: Dictionary = {}
var scale_options: Array = []
var difficulty_options: Array = []
var selected_detail: Dictionary = {}
var selected_scale_id: StringName = &""
var selected_map_id: StringName = &""
var active_run_locked := false
var selection_exact := false
var reduced_motion := false
var page_active := true
var built := false
var last_focus_key: StringName = &""

var scale_button_group := ButtonGroup.new()
var difficulty_button_group := ButtonGroup.new()
var scale_buttons: Dictionary = {}
var difficulty_buttons: Dictionary = {}
var focus_button_by_key: Dictionary = {}

var scale_status_label: Label
var detail_title_label: Label
var detail_artwork: TextureRect
var detail_name_label: Label
var detail_role_label: Label
var detail_state_label: Label
var detail_description_label: Label
var detail_metric_labels: Dictionary = {}
var select_action_button: Button
var empty_state_panel: Panel
var empty_state_title: Label
var empty_state_body: Label
var detail_content_nodes: Array[Control] = []


func _ready() -> void:
	if not built:
		build()


func build(projection: Dictionary = {}) -> void:
	built = true
	_clear_children()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_add_panel("MapScaleColumn", DeployPrepLayoutContractScript.MAP_SCALE_COLUMN, &"surface")
	_add_panel("MapDetailColumn", DeployPrepLayoutContractScript.MAP_DETAIL_COLUMN, &"surface")
	_add_color_rect("MapSplitDivider", Rect2(484, 120, 1, 522), Color(0.46, 0.36, 0.20, 0.42))
	_add_label("MapScaleTitle", DeployPrepLayoutContractScript.MAP_SCALE_TITLE, "地图规模", 20, Art10UISkinKitScript.color(&"gold"))
	var caption := _add_label("MapScaleCaption", DeployPrepLayoutContractScript.MAP_SCALE_CAPTION, "同页查看地图与难度", 13, Art10UISkinKitScript.color(&"caption"))
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scale_status_label = _add_label("MapScaleStatus", DeployPrepLayoutContractScript.MAP_SCALE_STATUS, "", 13, Art10UISkinKitScript.color(&"caption"))
	scale_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scale_status_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	detail_title_label = _add_label("MapDetailTitle", DeployPrepLayoutContractScript.MAP_DETAIL_TITLE, "难度与地图详情", 20, Art10UISkinKitScript.color(&"gold"))
	_add_panel("MapDetailArtFrame", DeployPrepLayoutContractScript.MAP_DETAIL_ART_FRAME, &"slot")
	detail_artwork = TextureRect.new()
	detail_artwork.name = "MapDetailArtwork"
	detail_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_artwork.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(detail_artwork, DeployPrepLayoutContractScript.MAP_DETAIL_ART)
	add_child(detail_artwork)
	detail_content_nodes.append(detail_artwork)

	detail_name_label = _add_label("MapDetailName", DeployPrepLayoutContractScript.MAP_DETAIL_NAME, "", 19, Art10UISkinKitScript.color(&"text"))
	detail_name_label.clip_text = true
	detail_role_label = _add_label("MapDetailRole", DeployPrepLayoutContractScript.MAP_DETAIL_ROLE, "", 13, Art10UISkinKitScript.color(&"caption"))
	detail_role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_role_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	detail_state_label = _add_label("MapDetailState", DeployPrepLayoutContractScript.MAP_DETAIL_STATE, "", 14, Art10UISkinKitScript.color(&"accent"))

	_add_panel("MapDetailMetricsPanel", DeployPrepLayoutContractScript.MAP_DETAIL_METRICS, &"slot")
	_add_metric_label(&"difficulty", "MapMetricDifficulty", Rect2(522, 384, 168, 32))
	_add_metric_label(&"mine", "MapMetricMine", Rect2(704, 384, 176, 32))
	_add_metric_label(&"content", "MapMetricContent", Rect2(522, 426, 168, 52))
	_add_metric_label(&"exit", "MapMetricExit", Rect2(704, 426, 176, 52))
	_add_metric_label(&"experience", "MapMetricExperience", Rect2(522, 482, 358, 30))

	detail_description_label = _add_label("MapDetailDescription", DeployPrepLayoutContractScript.MAP_DETAIL_DESCRIPTION, "", 13, Art10UISkinKitScript.color(&"caption"))
	detail_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	select_action_button = _add_button("MapSelectAction", DeployPrepLayoutContractScript.MAP_DETAIL_ACTION, "采用此难度", &"primary", &"button")
	select_action_button.pressed.connect(_on_select_action_pressed)
	_register_focus_button(select_action_button, &"action:select_map")

	empty_state_panel = _add_panel("MapEmptyState", DeployPrepLayoutContractScript.MAP_EMPTY_STATE, &"deep")
	empty_state_title = _add_label("MapEmptyStateTitle", Rect2(536, 330, 332, 44), "暂无地图", 21, Art10UISkinKitScript.color(&"warning"))
	empty_state_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_state_body = _add_label("MapEmptyStateBody", Rect2(536, 380, 332, 100), "", 14, Art10UISkinKitScript.color(&"caption"))
	empty_state_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_state_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	empty_state_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	for node in [detail_name_label, detail_role_label, detail_state_label, detail_description_label, select_action_button]:
		detail_content_nodes.append(node as Control)
	for raw_label in detail_metric_labels.values():
		detail_content_nodes.append(raw_label as Control)
	var art_frame := get_node_or_null("MapDetailArtFrame") as Control
	var metrics_panel := get_node_or_null("MapDetailMetricsPanel") as Control
	if art_frame != null:
		detail_content_nodes.append(art_frame)
	if metrics_panel != null:
		detail_content_nodes.append(metrics_panel)

	apply_projection(projection)
	set_active(page_active)


func apply_projection(projection: Dictionary) -> void:
	if not built:
		build(projection)
		return
	var focus_was_inside := _focus_is_inside()
	current_projection = _normalize_projection(projection)
	scale_options = _array_copy(current_projection.get("scale_options", []))
	selected_scale_id = StringName(current_projection.get("selected_scale_id", &""))
	selected_map_id = StringName(current_projection.get("selected_map_id", &""))
	active_run_locked = bool(current_projection.get("active_run_locked", false))
	selection_exact = bool(current_projection.get("selection_exact", true))
	difficulty_options = _array_copy(current_projection.get("difficulty_options", []))
	selected_detail = _dictionary_copy(current_projection.get("selected_detail", {}))
	if not selection_exact:
		selected_detail.clear()
	elif selected_detail.is_empty() and not selected_map_id.is_empty():
		selected_detail = _find_map_option(difficulty_options, selected_map_id)
	_rebuild_scale_buttons()
	_rebuild_difficulty_buttons()
	_refresh_detail()
	_wire_focus_neighbors()
	if focus_was_inside:
		call_deferred("restore_focus", last_focus_key)


func set_active(value: bool) -> void:
	page_active = value
	visible = value
	process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
	if not value and _focus_is_inside() and is_inside_tree():
		get_viewport().gui_release_focus()


func is_active() -> bool:
	return page_active


func set_reduced_motion_enabled(value: bool) -> void:
	reduced_motion = value
	if reduced_motion:
		modulate = Color.WHITE


func is_reduced_motion_enabled() -> bool:
	return reduced_motion


func focus_buttons() -> Array[Button]:
	var result: Array[Button] = []
	for scale_id in EXPECTED_SCALE_IDS:
		var scale_button := scale_buttons.get(scale_id) as Button
		if _is_focus_candidate(scale_button):
			result.append(scale_button)
	for raw_option in difficulty_options:
		var option := _dictionary_copy(raw_option)
		var map_id := StringName(option.get("map_config_id", option.get("id", &"")))
		var difficulty_button := difficulty_buttons.get(map_id) as Button
		if _is_focus_candidate(difficulty_button):
			result.append(difficulty_button)
	if _is_focus_candidate(select_action_button):
		result.append(select_action_button)
	return result


func restore_focus(preferred_key: StringName = &"") -> bool:
	if not page_active or not is_visible_in_tree():
		return false
	var key := preferred_key if not preferred_key.is_empty() else last_focus_key
	var preferred := focus_button_by_key.get(key) as Button
	if preferred == null and not key.is_empty():
		preferred = focus_button_by_key.get(StringName("scale:%s" % String(key))) as Button
	if preferred == null and not key.is_empty():
		preferred = focus_button_by_key.get(StringName("map:%s" % String(key))) as Button
	if _is_focus_candidate(preferred):
		preferred.grab_focus()
		return true
	var candidates := focus_buttons()
	if candidates.is_empty():
		return false
	candidates[0].grab_focus()
	return true


func get_selected_scale_id() -> StringName:
	return selected_scale_id


func get_preview_map_id() -> StringName:
	return StringName(selected_detail.get("map_config_id", selected_detail.get("id", &"")))


func is_empty_state_visible() -> bool:
	return empty_state_panel != null and empty_state_panel.visible


func projection_snapshot() -> Dictionary:
	return {
		"selected_scale_id": selected_scale_id,
		"selected_map_id": selected_map_id,
		"preview_map_id": get_preview_map_id(),
		"active_run_locked": active_run_locked,
		"selection_exact": selection_exact,
		"scale_count": scale_options.size(),
		"difficulty_count": difficulty_options.size(),
		"empty": is_empty_state_visible(),
	}


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	scale_buttons.clear()
	difficulty_buttons.clear()
	focus_button_by_key.clear()
	detail_metric_labels.clear()
	detail_content_nodes.clear()
	scale_button_group = ButtonGroup.new()
	difficulty_button_group = ButtonGroup.new()
	scale_button_group.allow_unpress = false
	difficulty_button_group.allow_unpress = false
	scale_status_label = null
	detail_title_label = null
	detail_artwork = null
	detail_name_label = null
	detail_role_label = null
	detail_state_label = null
	detail_description_label = null
	select_action_button = null
	empty_state_panel = null
	empty_state_title = null
	empty_state_body = null


func _rebuild_scale_buttons() -> void:
	for raw_button in scale_buttons.values():
		var old_button := raw_button as Button
		if old_button != null:
			focus_button_by_key.erase(StringName("scale:%s" % String(_button_scale_id(old_button))))
			remove_child(old_button)
			old_button.queue_free()
	scale_buttons.clear()
	scale_button_group = ButtonGroup.new()
	scale_button_group.allow_unpress = false
	for index in range(mini(scale_options.size(), DeployPrepLayoutContractScript.MAP_SCALE_BUTTON_RECTS.size())):
		var option := _dictionary_copy(scale_options[index])
		var scale_id := StringName(option.get("scale_id", &""))
		if scale_id.is_empty():
			continue
		var button := _add_button(
			"MapScale_%s" % String(scale_id),
			DeployPrepLayoutContractScript.MAP_SCALE_BUTTON_RECTS[index],
			_scale_button_text(option),
			&"selected" if scale_id == selected_scale_id else &"secondary",
			&"body_small"
		)
		button.toggle_mode = true
		button.button_group = scale_button_group
		button.set_meta("scale_id", scale_id)
		button.set_pressed_no_signal(scale_id == selected_scale_id)
		button.tooltip_text = "查看%s的%d个难度" % [_scale_label(option), _maps_for_scale(option).size()]
		button.pressed.connect(_on_scale_pressed.bind(scale_id))
		scale_buttons[scale_id] = button
		_register_focus_button(button, StringName("scale:%s" % String(scale_id)))
	_refresh_scale_status()


func _rebuild_difficulty_buttons() -> void:
	for raw_button in difficulty_buttons.values():
		var old_button := raw_button as Button
		if old_button != null:
			var old_map_id := StringName(old_button.get_meta("map_config_id", &""))
			focus_button_by_key.erase(StringName("map:%s" % String(old_map_id)))
			remove_child(old_button)
			old_button.queue_free()
	difficulty_buttons.clear()
	difficulty_button_group = ButtonGroup.new()
	difficulty_button_group.allow_unpress = false
	var preview_map_id := get_preview_map_id()
	for index in range(difficulty_options.size()):
		var option := _dictionary_copy(difficulty_options[index])
		var map_id := StringName(option.get("map_config_id", option.get("id", &"")))
		if map_id.is_empty():
			continue
		var is_previewed := map_id == preview_map_id
		var button := _add_button(
			"MapDifficulty_%s" % String(map_id),
			DeployPrepLayoutContractScript.map_difficulty_button_rect(index, difficulty_options.size()),
			_difficulty_button_text(option),
			_difficulty_tone(option, is_previewed),
			&"body_small"
		)
		button.toggle_mode = true
		button.button_group = difficulty_button_group
		button.set_meta("map_config_id", map_id)
		button.set_pressed_no_signal(is_previewed)
		button.tooltip_text = _difficulty_tooltip(option)
		button.pressed.connect(_on_difficulty_pressed.bind(map_id))
		difficulty_buttons[map_id] = button
		_register_focus_button(button, StringName("map:%s" % String(map_id)))


func _refresh_scale_buttons() -> void:
	for raw_option in scale_options:
		var option := _dictionary_copy(raw_option)
		var scale_id := StringName(option.get("scale_id", &""))
		var button := scale_buttons.get(scale_id) as Button
		if button == null:
			continue
		var selected := scale_id == selected_scale_id
		button.set_pressed_no_signal(selected)
		_apply_button_skin(button, &"selected" if selected else &"secondary", &"body_small", &"filter", &"selected" if selected else &"normal")


func _refresh_difficulty_buttons() -> void:
	var preview_map_id := get_preview_map_id()
	for raw_option in difficulty_options:
		var option := _dictionary_copy(raw_option)
		var map_id := StringName(option.get("map_config_id", option.get("id", &"")))
		var button := difficulty_buttons.get(map_id) as Button
		if button == null:
			continue
		var previewed := map_id == preview_map_id
		button.set_pressed_no_signal(previewed)
		_apply_button_skin(button, _difficulty_tone(option, previewed), &"body_small", &"filter", &"selected" if previewed else (&"locked" if not _map_unlocked(option) else &"normal"))


func _refresh_scale_status() -> void:
	if scale_status_label == null:
		return
	if scale_options.is_empty():
		scale_status_label.text = "地图资料暂不可用。"
		return
	if active_run_locked:
		scale_status_label.text = "探索进行中\n可查看全部地图，本局配置不可更改。"
		return
	if not selection_exact:
		scale_status_label.text = "地图记录无法识别\n请重新选择已解锁地图。"
		return
	var selected_map := _find_map_across_scales(selected_map_id)
	var selected_name := String(selected_map.get("display_name", ""))
	scale_status_label.text = "本次出发\n%s" % (selected_name if not selected_name.is_empty() else "请选择地图难度")


func _refresh_detail() -> void:
	var empty := selected_detail.is_empty()
	if empty_state_panel != null:
		empty_state_panel.visible = empty
	if empty_state_title != null:
		empty_state_title.visible = empty
	if empty_state_body != null:
		empty_state_body.visible = empty
	for node in detail_content_nodes:
		if node != null:
			node.visible = not empty
	if empty:
		_refresh_empty_copy()
		_refresh_scale_status()
		return

	var map_id := StringName(selected_detail.get("map_config_id", selected_detail.get("id", &"")))
	var unlocked := _map_unlocked(selected_detail)
	var is_selected := map_id == selected_map_id
	detail_artwork.texture = _resolve_map_texture(map_id, selected_detail)
	detail_name_label.text = String(selected_detail.get("display_name", map_id))
	detail_role_label.text = String(selected_detail.get("role", "常规扫雷地图"))
	detail_state_label.text = _detail_state_text(unlocked, is_selected)
	detail_state_label.add_theme_color_override("font_color", _detail_state_color(unlocked, is_selected))

	var has_exit_data := selected_detail.has("exit_count") or selected_detail.has("visible_exit_count") or selected_detail.has("hidden_exit_count") or selected_detail.has("random_exit_count")
	var visible_exits := int(selected_detail.get("visible_exit_count", 0))
	var hidden_exits := int(selected_detail.get("hidden_exit_count", selected_detail.get("random_exit_count", 0)))
	var total_exits := int(selected_detail.get("exit_count", visible_exits + hidden_exits))
	_set_metric(&"difficulty", "难度  %s" % String(selected_detail.get("difficulty_label", selected_detail.get("difficulty", "—"))))
	_set_metric(&"mine", "雷房  %d" % int(selected_detail.get("mine_count", 0)) if selected_detail.has("mine_count") else "雷房  —")
	_set_metric(&"content", "内容房\n事件 / 怪物 / 箱 各 %d" % int(selected_detail.get("content_room_count", 0)) if selected_detail.has("content_room_count") else "内容房  —")
	_set_metric(&"exit", "出口  %d\n固定 %d · 隐藏 %d" % [total_exits, visible_exits, hidden_exits] if has_exit_data else "出口  —")
	var has_experience := selected_detail.has("success_exp") or selected_detail.has("experience")
	_set_metric(&"experience", "成功经验  +%d" % int(selected_detail.get("success_exp", selected_detail.get("experience", 0))) if has_experience else "成功经验  —")
	detail_description_label.text = _detail_description(selected_detail, unlocked)

	var action := _dictionary_copy(selected_detail.get("select_action", {}))
	var action_enabled := bool(action.get("enabled", false)) and unlocked and not active_run_locked and not is_selected
	select_action_button.disabled = not action_enabled
	select_action_button.text = _action_text(unlocked, is_selected)
	select_action_button.tooltip_text = _action_tooltip(action, unlocked, is_selected)
	_apply_button_skin(select_action_button, &"primary" if action_enabled else &"disabled", &"button", &"action", &"normal" if action_enabled else &"disabled")
	_refresh_difficulty_buttons()
	_refresh_scale_status()


func _refresh_empty_copy() -> void:
	if empty_state_title == null or empty_state_body == null:
		return
	if scale_options.is_empty():
		empty_state_title.text = "暂无地图资料"
		empty_state_body.text = "地图列表尚未准备好。\n返回后可重新进入出发探索。"
	elif not selection_exact:
		empty_state_title.text = "地图记录无法识别"
		empty_state_body.text = "不会用其他地图替代该记录。\n请选择左侧规模，再查看可用难度。"
	elif difficulty_options.is_empty():
		empty_state_title.text = "该规模暂无难度"
		empty_state_body.text = "请选择左侧其他地图规模。"
	else:
		empty_state_title.text = "请选择地图难度"
		empty_state_body.text = "先查看上方难度，再用右下按钮确认。"


func _on_scale_pressed(scale_id: StringName) -> void:
	var option := _find_scale_option(scale_id)
	if option.is_empty():
		return
	selected_scale_id = scale_id
	difficulty_options = _maps_for_scale(option)
	var selected_in_scale := _find_map_option(difficulty_options, selected_map_id)
	selected_detail = selected_in_scale if not selected_in_scale.is_empty() else (_dictionary_copy(difficulty_options[0]) if not difficulty_options.is_empty() else {})
	_refresh_scale_buttons()
	_rebuild_difficulty_buttons()
	_refresh_detail()
	_wire_focus_neighbors()
	scale_requested.emit(scale_id)
	if not reduced_motion:
		Art10UISkinKitScript.play_feedback_pulse(scale_buttons.get(scale_id) as Control, &"success", 0.20)


func _on_difficulty_pressed(map_id: StringName) -> void:
	var option := _find_map_option(difficulty_options, map_id)
	if option.is_empty():
		return
	selected_detail = option
	_refresh_detail()
	if not reduced_motion:
		Art10UISkinKitScript.play_feedback_pulse(difficulty_buttons.get(map_id) as Control, &"success" if _map_unlocked(option) else &"warning", 0.18)


func _on_select_action_pressed() -> void:
	if active_run_locked or selected_detail.is_empty() or not _map_unlocked(selected_detail):
		return
	var map_id := StringName(selected_detail.get("map_config_id", selected_detail.get("id", &"")))
	if map_id.is_empty() or map_id == selected_map_id:
		return
	var action := _dictionary_copy(selected_detail.get("select_action", {}))
	if action.is_empty() or not bool(action.get("enabled", false)):
		return
	if StringName(action.get("action", action.get("id", &""))) != &"select_map" or not action.has("map_config_id"):
		return
	var action_map_id := StringName(action.get("map_config_id", &""))
	if action_map_id != map_id:
		return
	map_requested.emit(map_id)
	if not reduced_motion:
		Art10UISkinKitScript.play_feedback_pulse(select_action_button, &"success", 0.32)


func _normalize_projection(projection: Dictionary) -> Dictionary:
	var source := projection.duplicate(true)
	for key in [&"map_projection", &"deploy_map_projection", &"map_split_projection"]:
		var nested := _dictionary_copy(source.get(key, {}))
		if not nested.is_empty():
			source = nested
			break
	if source.has("config"):
		var config := _dictionary_copy(source.get("config", {}))
		for key in [&"deploy_map_projection", &"map_projection"]:
			var nested_config := _dictionary_copy(config.get(key, {}))
			if not nested_config.is_empty():
				source = nested_config
				break

	var normalized := source.duplicate(true)
	var normalized_scales := _array_copy(source.get("scale_options", []))
	if normalized_scales.is_empty():
		var flat_maps := _array_copy(source.get("map_definitions", source.get("maps", source.get("options", []))))
		normalized_scales = _group_flat_maps(flat_maps)
	normalized["scale_options"] = normalized_scales
	normalized["selected_map_id"] = StringName(source.get("selected_map_id", source.get("map_config_id", &"")))
	normalized["selected_scale_id"] = StringName(source.get("selected_scale_id", source.get("scale_id", &"")))
	normalized["active_run_locked"] = bool(source.get("active_run_locked", source.get("locked", false)))
	normalized["selection_exact"] = bool(source.get("selection_exact", false))
	var options := _array_copy(source.get("difficulty_options", []))
	if options.is_empty() and not StringName(normalized["selected_scale_id"]).is_empty():
		for raw_scale in normalized_scales:
			var scale := _dictionary_copy(raw_scale)
			if StringName(scale.get("scale_id", &"")) == StringName(normalized["selected_scale_id"]):
				options = _maps_for_scale(scale)
				break
	normalized["difficulty_options"] = options
	normalized["selected_detail"] = _dictionary_copy(source.get("selected_detail", source.get("detail", {})))
	return normalized


func _group_flat_maps(maps: Array) -> Array:
	var result: Array = []
	for expected_id in EXPECTED_SCALE_IDS:
		var grouped: Array = []
		for raw_map in maps:
			var map := _dictionary_copy(raw_map)
			if _scale_id_for(map) == expected_id:
				grouped.append(map)
		if grouped.is_empty():
			continue
		result.append({
			"scale_id": expected_id,
			"scale_label": String(expected_id).replace("x", "×"),
			"map_name": "常规扫雷",
			"display_name": "常规扫雷",
			"maps": grouped,
			"map_count": grouped.size(),
		})
	return result


func _scale_id_for(map: Dictionary) -> StringName:
	var explicit := StringName(map.get("scale_id", &""))
	if not explicit.is_empty():
		return explicit
	var width := int(map.get("width", 0))
	var height := int(map.get("height", width))
	return StringName("%dx%d" % [width, height]) if width > 0 and height > 0 else &""


func _find_scale_option(scale_id: StringName) -> Dictionary:
	for raw_option in scale_options:
		var option := _dictionary_copy(raw_option)
		if StringName(option.get("scale_id", &"")) == scale_id:
			return option
	return {}


func _find_map_option(options: Array, map_id: StringName) -> Dictionary:
	for raw_option in options:
		var option := _dictionary_copy(raw_option)
		if StringName(option.get("map_config_id", option.get("id", &""))) == map_id:
			return option
	return {}


func _find_map_across_scales(map_id: StringName) -> Dictionary:
	for raw_scale in scale_options:
		var found := _find_map_option(_maps_for_scale(_dictionary_copy(raw_scale)), map_id)
		if not found.is_empty():
			return found
	return {}


func _maps_for_scale(option: Dictionary) -> Array:
	return _array_copy(option.get("maps", option.get("difficulty_options", option.get("options", []))))


func _scale_label(option: Dictionary) -> String:
	var label := String(option.get("scale_label", ""))
	if label.is_empty():
		label = String(option.get("scale_id", "")).replace("x", "×")
	return label


func _scale_button_text(option: Dictionary) -> String:
	var map_name := String(option.get("map_name", option.get("display_name", "常规扫雷"))).strip_edges()
	var count := int(option.get("map_count", _maps_for_scale(option).size()))
	return "%s\n%s · %d 个难度" % [map_name, _scale_label(option), count]


func _difficulty_button_text(option: Dictionary) -> String:
	var label := String(option.get("difficulty_label", option.get("difficulty", "难度")))
	if not _map_unlocked(option):
		return "%s · 未开放" % label
	var map_id := StringName(option.get("map_config_id", option.get("id", &"")))
	return "%s · 已采用" % label if map_id == selected_map_id else label


func _difficulty_tooltip(option: Dictionary) -> String:
	var name := String(option.get("display_name", option.get("map_config_id", "地图")))
	if not _map_unlocked(option):
		return "查看%s详情；该难度尚未解锁" % name
	if active_run_locked:
		return "查看%s详情；探索进行中不可更改" % name
	return "查看%s详情；右下角确认采用" % name


func _difficulty_tone(option: Dictionary, previewed: bool) -> StringName:
	if previewed:
		return &"selected"
	return &"secondary" if _map_unlocked(option) else &"locked"


func _map_unlocked(option: Dictionary) -> bool:
	if option.has("unlocked"):
		return bool(option.get("unlocked", false))
	var action := _dictionary_copy(option.get("select_action", {}))
	return bool(action.get("enabled", false)) if action.has("enabled") else false


func _detail_state_text(unlocked: bool, is_selected: bool) -> String:
	if active_run_locked:
		return "探索进行中 · 配置锁定"
	if not unlocked:
		return "尚未解锁 · 可查看"
	if is_selected:
		return "本次出发已采用"
	return "可用于本次出发"


func _detail_state_color(unlocked: bool, is_selected: bool) -> Color:
	if active_run_locked or not unlocked:
		return Art10UISkinKitScript.color(&"warning")
	return Art10UISkinKitScript.color(&"gold") if is_selected else Art10UISkinKitScript.color(&"accent")


func _detail_description(detail: Dictionary, unlocked: bool) -> String:
	var provided := Art10UISkinKitScript.sanitize_player_copy(String(detail.get("detail", detail.get("description", ""))))
	if not provided.is_empty():
		return provided
	if not unlocked:
		return "满足对应研究、资历或成就条件后开放。"
	if bool(detail.get("visible_exit_position_known", false)):
		return "固定出口位置可见；实际房间在确认出发后生成。"
	return "实际房间与出口位置在确认出发后生成。"


func _action_text(unlocked: bool, is_selected: bool) -> String:
	if active_run_locked:
		return "探索中锁定"
	if not unlocked:
		return "尚未解锁"
	if is_selected:
		return "已用于出发"
	return "采用此难度"


func _action_tooltip(action: Dictionary, unlocked: bool, is_selected: bool) -> String:
	if active_run_locked:
		return "探索进行中，本局地图不可更改"
	if not unlocked:
		return "该难度尚未解锁，可继续查看详情"
	if is_selected:
		return "该地图已用于本次出发"
	var reason := String(action.get("reason", ""))
	return reason if not reason.is_empty() else "确认把该地图难度用于本次出发"


func _resolve_map_texture(map_id: StringName, detail: Dictionary) -> Texture2D:
	var explicit_ref := _dictionary_copy(detail.get("asset_ref", detail.get("art_ref", {})))
	if not explicit_ref.is_empty():
		var explicit_texture := Art09ManifestAssetMappingScript.resolve_texture(explicit_ref)
		if explicit_texture != null:
			return explicit_texture
	if not map_id.is_empty():
		var exact_ref := Art25ContentAssetContractScript.deploy_card_ref(StringName("m7_map_%s" % String(map_id)))
		var exact_texture := Art09ManifestAssetMappingScript.resolve_texture(exact_ref)
		if exact_texture != null:
			return exact_texture
	return Art09ManifestAssetMappingScript.resolve_texture(Art22DeployPrepAssetContractScript.route_ref(&"map_unlocked_route"))


func _set_metric(metric_id: StringName, text: String) -> void:
	var label := detail_metric_labels.get(metric_id) as Label
	if label != null:
		label.text = text


func _add_metric_label(metric_id: StringName, node_name: String, rect: Rect2) -> void:
	var label := _add_label(node_name, rect, "", 14, Art10UISkinKitScript.color(&"text"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_metric_labels[metric_id] = label


func _add_panel(node_name: String, rect: Rect2, tone: StringName) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", Art10UISkinKitScript.panel_style(tone))
	_set_rect(panel, rect)
	add_child(panel)
	return panel


func _add_color_rect(node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var node := ColorRect.new()
	node.name = node_name
	node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(node, rect)
	add_child(node)
	return node


func _add_label(node_name: String, rect: Rect2, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	Art10UISkinKitScript.apply_label(label, font_size, color)
	_set_rect(label, rect)
	add_child(label)
	return label


func _add_button(node_name: String, rect: Rect2, text: String, tone: StringName, token: StringName) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_set_rect(button, rect)
	add_child(button)
	_apply_button_skin(button, tone, token, &"filter", &"normal")
	return button


func _apply_button_skin(button: Button, tone: StringName, token: StringName, control_id: StringName, state: StringName) -> void:
	if button == null:
		return
	var normal_state := state if state in [&"normal", &"selected", &"disabled"] else &"disabled"
	Art10UISkinKitScript.apply_image_button_ref(
		button,
		Art22DeployPrepAssetContractScript.control_ref(control_id, normal_state),
		tone,
		token,
		&"button",
		8,
		16
	)
	button.add_theme_stylebox_override("normal", Art10UISkinKitScript.style_box_from_asset_ref(Art22DeployPrepAssetContractScript.control_ref(control_id, normal_state), 8, 16))
	button.add_theme_stylebox_override("hover", Art10UISkinKitScript.style_box_from_asset_ref(Art22DeployPrepAssetContractScript.control_ref(control_id, &"focused"), 8, 16))
	button.add_theme_stylebox_override("focus", Art10UISkinKitScript.style_box_from_asset_ref(Art22DeployPrepAssetContractScript.control_ref(control_id, &"focused"), 8, 16))
	button.add_theme_stylebox_override("pressed", Art10UISkinKitScript.style_box_from_asset_ref(Art22DeployPrepAssetContractScript.control_ref(control_id, &"pressed"), 8, 16))
	button.add_theme_stylebox_override("hover_pressed", Art10UISkinKitScript.style_box_from_asset_ref(Art22DeployPrepAssetContractScript.control_ref(control_id, &"pressed"), 8, 16))
	button.add_theme_stylebox_override("disabled", Art10UISkinKitScript.style_box_from_asset_ref(Art22DeployPrepAssetContractScript.control_ref(control_id, &"disabled"), 8, 16))
	if control_id == &"filter":
		# ART22 filter/focus plates are parchment-light; the generic tone applies
		# pale text and loses contrast on the map scale/difficulty controls.
		var ink := Color(0.20, 0.12, 0.07)
		button.add_theme_color_override("font_color", ink)
		button.add_theme_color_override("font_hover_color", ink.darkened(0.08))
		button.add_theme_color_override("font_focus_color", ink.darkened(0.08))
		button.add_theme_color_override("font_pressed_color", ink.darkened(0.12))
		button.add_theme_color_override("font_hover_pressed_color", ink.darkened(0.12))
		button.add_theme_color_override("font_disabled_color", Color(ink.r, ink.g, ink.b, 0.55))


func _register_focus_button(button: Button, key: StringName) -> void:
	if button == null:
		return
	focus_button_by_key[key] = button
	button.focus_entered.connect(_remember_focus.bind(key))


func _remember_focus(key: StringName) -> void:
	last_focus_key = key


func _wire_focus_neighbors() -> void:
	var scales: Array[Button] = []
	for scale_id in EXPECTED_SCALE_IDS:
		var button := scale_buttons.get(scale_id) as Button
		if button != null:
			scales.append(button)
	var difficulties: Array[Button] = []
	for raw_option in difficulty_options:
		var option := _dictionary_copy(raw_option)
		var button := difficulty_buttons.get(StringName(option.get("map_config_id", option.get("id", &"")))) as Button
		if button != null:
			difficulties.append(button)
	var selected_scale_button := scale_buttons.get(selected_scale_id) as Button
	if selected_scale_button == null and not scales.is_empty():
		selected_scale_button = scales[0]
	for index in range(scales.size()):
		var scale_button := scales[index]
		scale_button.focus_neighbor_top = scale_button.get_path_to(scales[maxi(0, index - 1)])
		scale_button.focus_neighbor_bottom = scale_button.get_path_to(scales[mini(scales.size() - 1, index + 1)])
		if not difficulties.is_empty():
			scale_button.focus_neighbor_right = scale_button.get_path_to(difficulties[0])
	for index in range(difficulties.size()):
		var difficulty_button := difficulties[index]
		difficulty_button.focus_neighbor_left = difficulty_button.get_path_to(difficulties[maxi(0, index - 1)] if index > 0 else (selected_scale_button if selected_scale_button != null else difficulty_button))
		var right_target := select_action_button if index == difficulties.size() - 1 and _is_focus_candidate(select_action_button) else difficulties[mini(difficulties.size() - 1, index + 1)]
		difficulty_button.focus_neighbor_right = difficulty_button.get_path_to(right_target)
		if select_action_button != null and not select_action_button.disabled:
			difficulty_button.focus_neighbor_bottom = difficulty_button.get_path_to(select_action_button)
	if select_action_button != null:
		if not difficulties.is_empty():
			var preview_button := difficulty_buttons.get(get_preview_map_id()) as Button
			select_action_button.focus_neighbor_top = select_action_button.get_path_to(preview_button if preview_button != null else difficulties[0])
		if selected_scale_button != null:
			select_action_button.focus_neighbor_left = select_action_button.get_path_to(selected_scale_button)


func _button_scale_id(button: Button) -> StringName:
	return StringName(button.get_meta("scale_id", &"")) if button != null else &""


func _focus_is_inside() -> bool:
	if not is_inside_tree():
		return false
	var focus := get_viewport().gui_get_focus_owner()
	return focus != null and (focus == self or is_ancestor_of(focus))


func _is_focus_candidate(button: Button) -> bool:
	return button != null and is_instance_valid(button) and button.visible and not button.disabled and button.focus_mode != Control.FOCUS_NONE


func _set_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position.round()
	control.size = rect.size.round()


func _array_copy(value: Variant) -> Array:
	return (value as Array).duplicate(true) if value is Array else []


func _dictionary_copy(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}
