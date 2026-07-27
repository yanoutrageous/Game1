extends PanelContainer
class_name G41WorldContextPopup

signal pickup_requested(instance_id: String)
signal replace_requested(ground_instance_id: String, drop_instance_id: String)
signal chest_open_requested
signal event_open_requested(payload: Dictionary)
signal exit_requested(payload: Dictionary)

const POPUP_WIDTH := 308.0
const ROW_HEIGHT := 44.0
const ItemVisualCatalog := preload("res://scripts/presentation/art24/art24_item_visual_catalog.gd")
const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const SpecialRoomPresentationModelScript := preload("res://scripts/gameplay/interaction/i3_special_room_presentation_model.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const RuntimeInputProfileScript := preload("res://scripts/core/input/runtime_input_profile.gd")
const SemanticActionHintScript := preload("res://scripts/core/input/semantic_action_hint.gd")

var title_label: Label
var hint_label: Label
var item_list: VBoxContainer
var item_scroll: ScrollContainer
var primary_button: Button
var status_label: Label
var context_kind: StringName = &"none"
var context_items: Array[Dictionary] = []
var inventory_items: Array[Dictionary] = []
var anchor_world := Vector2.ZERO
var player_world := Vector2.ZERO
var has_player_world: bool = false
var room_bounds := Rect2(Vector2.ZERO, Vector2(1280, 720))
var gameplay_focus_rect := Rect2()
var reserved_rects: Array[Rect2] = []
var last_signature := ""
var current_context: Dictionary = {}
var replacement_ground_id := ""


func _ready() -> void:
	add_to_group(RuntimeInputProfileScript.HINT_CONSUMER_GROUP)
	_build()
	set_process(true)


func refresh_input_hints() -> void:
	if (
		hint_label != null
		and context_kind == &"chest"
		and not current_context.is_empty()
		and not bool(current_context.get("container_open", false))
	):
		hint_label.text = "使用 %s 打开" % SemanticActionHintScript.current_display_label(&"interact")


func apply_context(context: Dictionary) -> void:
	if context.is_empty():
		clear_context()
		return
	context_kind = StringName(context.get("interaction_kind", &"none"))
	anchor_world = Vector2(context.get("world_pos", Vector2.ZERO))
	has_player_world = context.has("player_world_pos")
	player_world = Vector2(context.get("player_world_pos", anchor_world))
	room_bounds = Rect2(context.get("room_bounds", room_bounds))
	gameplay_focus_rect = Rect2(context.get("gameplay_focus_rect", Rect2()))
	reserved_rects = _rect_array(context.get("reserved_rects", []))
	context_items = _dictionary_array(context.get("items", []))
	inventory_items = _dictionary_array(context.get("inventory_items", []))
	current_context = context.duplicate(true)
	if replacement_ground_id != "" and not _contains_instance(context_items, replacement_ground_id):
		replacement_ground_id = ""
	var signature := _context_signature(context)
	if signature != last_signature:
		last_signature = signature
		_rebuild(context)
	visible = true
	_place_near_anchor()


func clear_context() -> void:
	visible = false
	context_kind = &"none"
	context_items.clear()
	inventory_items.clear()
	current_context.clear()
	has_player_world = false
	gameplay_focus_rect = Rect2()
	reserved_rects.clear()
	replacement_ground_id = ""
	last_signature = ""
	if status_label != null:
		status_label.text = ""


func activate_primary() -> bool:
	if not visible:
		return false
	if context_kind == &"chest":
		if not bool(current_context.get("opened_once", false)):
			chest_open_requested.emit()
			return true
		if context_items.is_empty():
			return false
		var chest_item := context_items[0]
		if not _pickup_allowed(chest_item):
			return false
		if int(chest_item.get("weight", 0)) > int(current_context.get("backpack_remaining", 0)):
			_begin_replacement(String(chest_item.get("instance_id", "")))
		else:
			pickup_requested.emit(String(chest_item.get("instance_id", "")))
		return true
	if context_kind == &"ground_loot" and not context_items.is_empty():
		if replacement_ground_id != "":
			_cancel_replacement()
			return true
		var item := context_items[0]
		if not _pickup_allowed(item):
			return false
		if int(item.get("weight", 0)) > int(current_context.get("backpack_remaining", 0)):
			_begin_replacement(String(item.get("instance_id", "")))
		else:
			pickup_requested.emit(String(item.get("instance_id", "")))
		return true
	if context_kind == &"event":
		var event_payload: Dictionary = current_context.get("payload", {})
		if bool(event_payload.get("completed", false)) or bool(event_payload.get("display_only", false)):
			return false
		event_open_requested.emit(event_payload.duplicate(true))
		return true
	if context_kind == &"exit":
		var exit_payload: Dictionary = current_context.get("payload", {})
		exit_requested.emit(exit_payload.duplicate(true))
		return true
	return false


func show_command_result(result: Dictionary) -> void:
	if status_label == null:
		return
	var ok := bool(result.get("accepted", result.get("ok", false)))
	if ok:
		status_label.text = ""
	else:
		var reason := String(result.get("reason_code", result.get("blocked_reason", result.get("reason", ""))))
		status_label.text = RunUIViewModel.reason_label(reason)
	status_label.visible = not status_label.text.is_empty()
	status_label.add_theme_color_override("font_color", Color(0.55, 0.92, 0.72, 1.0) if ok else Color(1.0, 0.52, 0.34, 1.0))
	_request_content_fit()


func _process(_delta: float) -> void:
	if visible:
		_place_near_anchor()


func _build() -> void:
	name = "WorldContextPopup"
	Art10UISkinKitScript.apply_player_ui_theme(self)
	visible = false
	z_index = 80
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(POPUP_WIDTH, 0)
	var frame := Art10UISkinKitScript.style_box_from_asset_ref(
		Art21UIPlacementContractScript.panel_ref(&"tooltip"),
		12,
		12
	)
	if frame != null:
		add_theme_stylebox_override("panel", frame)
	else:
		var fallback_frame := StyleBoxFlat.new()
		fallback_frame.bg_color = Color(0.012, 0.025, 0.028, 0.98)
		fallback_frame.border_color = Color(0.72, 0.51, 0.20, 0.95)
		fallback_frame.set_border_width_all(2)
		fallback_frame.content_margin_left = 12
		fallback_frame.content_margin_top = 10
		fallback_frame.content_margin_right = 12
		fallback_frame.content_margin_bottom = 10
		add_theme_stylebox_override("panel", fallback_frame)

	var root := VBoxContainer.new()
	root.name = "ContextContent"
	root.add_theme_constant_override("separation", 6)
	add_child(root)
	title_label = Label.new()
	title_label.name = "ContextTitle"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.35, 1.0))
	root.add_child(title_label)
	hint_label = Label.new()
	hint_label.name = "ContextHint"
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.70, 0.80, 0.76, 1.0))
	root.add_child(hint_label)
	item_scroll = ScrollContainer.new()
	item_scroll.name = "ContextItemScroll"
	item_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	item_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(item_scroll)
	item_list = VBoxContainer.new()
	item_list.name = "ContextItemList"
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 4)
	item_scroll.add_child(item_list)
	primary_button = Button.new()
	primary_button.name = "ContextPrimaryButton"
	primary_button.custom_minimum_size = Vector2(0, 34)
	primary_button.pressed.connect(_on_primary_pressed)
	_style_button(primary_button, &"primary", 13)
	root.add_child(primary_button)
	status_label = Label.new()
	status_label.name = "ContextStatus"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.66, 0.76, 0.72, 1.0))
	status_label.visible = false
	root.add_child(status_label)


func _rebuild(context: Dictionary) -> void:
	for child in item_list.get_children():
		child.queue_free()
	var backpack_remaining := int(context.get("backpack_remaining", 0))
	if context_kind == &"ground_loot" and replacement_ground_id != "":
		_build_replacement_view(context, backpack_remaining)
		return
	if context_kind == &"chest":
		var opened_once := bool(context.get("opened_once", false))
		var container_open := bool(context.get("container_open", false))
		title_label.text = "物资箱 · %d 件" % context_items.size() if opened_once else "物资箱"
		if container_open:
			hint_label.text = ""
			hint_label.visible = false
			primary_button.visible = false
			_build_item_rows(context_items, backpack_remaining)
		else:
			hint_label.text = "使用 %s 打开" % SemanticActionHintScript.current_display_label(&"interact")
			hint_label.visible = true
			primary_button.text = "打开物资箱"
			primary_button.visible = true
	elif context_kind == &"ground_loot":
		title_label.text = "附近回收物"
		hint_label.text = "附近 %d 件" % context_items.size()
		hint_label.visible = true
		primary_button.visible = false
		_build_item_rows(context_items, backpack_remaining)
	else:
		_rebuild_special_context(context)
	item_scroll.visible = (context_kind == &"ground_loot") or (context_kind == &"chest" and bool(context.get("container_open", false)))
	item_scroll.custom_minimum_size.y = minf(ROW_HEIGHT * maxf(1.0, float(context_items.size())), ROW_HEIGHT * 3.0)
	status_label.text = ""
	status_label.visible = false
	_request_content_fit()


func _rebuild_special_context(context: Dictionary) -> void:
	var payload: Dictionary = context.get("payload", {})
	item_scroll.visible = false
	hint_label.visible = true
	var presentation := SpecialRoomPresentationModelScript.build(context_kind, payload)
	title_label.text = String(presentation.get("title", "附近目标"))
	hint_label.text = String(presentation.get("body", "靠近后查看。"))
	primary_button.text = String(presentation.get("primary_text", ""))
	primary_button.visible = bool(presentation.get("primary_visible", false))


func _build_replacement_view(context: Dictionary, backpack_remaining: int) -> void:
	var incoming := _item_by_instance(context_items, replacement_ground_id)
	var incoming_presentation := RunUIViewModel.item_presentation(incoming)
	title_label.text = "选择要放下的物品"
	hint_label.text = "换入：%s　%s　重量 %d。只有释放后容量足够的物品可选。" % [
		String(incoming_presentation.get("display_name", "未命名物资")),
		String(incoming_presentation.get("rarity_text", "[?] 未鉴定")),
		int(incoming_presentation.get("weight", 0)),
	]
	primary_button.text = "取消替换"
	primary_button.visible = true
	_build_replacement_rows(incoming, backpack_remaining)
	item_scroll.visible = true
	item_scroll.custom_minimum_size.y = minf(ROW_HEIGHT * maxf(1.0, float(inventory_items.size())), ROW_HEIGHT * 3.0)
	status_label.text = ""
	status_label.visible = false
	_request_content_fit()


func _request_content_fit() -> void:
	# Rebuilding queues old item rows for deletion. Fit on the deferred pass so
	# those rows cannot leave a stale oversized interaction panel behind.
	call_deferred("_fit_content_and_place")


func _fit_content_and_place() -> void:
	if not is_inside_tree():
		return
	var fitted := get_combined_minimum_size()
	fitted.x = maxf(fitted.x, POPUP_WIDTH)
	size = fitted
	_place_near_anchor()


func _build_replacement_rows(incoming: Dictionary, backpack_remaining: int) -> void:
	if inventory_items.is_empty():
		var empty := Label.new()
		empty.text = "背包中没有可放下的物品。"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", Color(0.88, 0.48, 0.34, 1.0))
		item_list.add_child(empty)
		return
	var incoming_weight := int(RunUIViewModel.item_presentation(incoming).get("weight", 0))
	for item in inventory_items:
		var presentation := RunUIViewModel.item_presentation(item)
		var rarity: Dictionary = presentation.get("rarity", {})
		var row := HBoxContainer.new()
		row.name = "ReplacementCandidateRow"
		row.add_theme_constant_override("separation", 4)
		item_list.add_child(row)
		var item_button := Button.new()
		item_button.name = "ReplacementCandidateInfo"
		item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_button.custom_minimum_size = Vector2(156, ROW_HEIGHT)
		item_button.text = ""
		item_button.tooltip_text = String(presentation.get("detail_text", "尚未选择物品。"))
		_style_button(item_button, &"secondary", 13)
		_apply_rarity_style(item_button, rarity)
		_build_replacement_candidate_content(item_button, item, presentation, rarity)
		row.add_child(item_button)
		var candidate_id := String(item.get("instance_id", ""))
		var candidate_weight := int(presentation.get("weight", 0))
		var eligible := backpack_remaining + candidate_weight >= incoming_weight
		var choose := Button.new()
		choose.name = "ReplacementCandidateButton"
		choose.text = "放下" if eligible else "容量不足"
		choose.custom_minimum_size = Vector2(56, ROW_HEIGHT)
		choose.disabled = not eligible
		choose.tooltip_text = "放下该物品并拾取地面物。" if eligible else "即使放下该物品，背包容量仍不足。"
		_style_button(choose, &"warning" if eligible else &"secondary", 12)
		choose.pressed.connect(func() -> void: replace_requested.emit(replacement_ground_id, candidate_id))
		row.add_child(choose)


func _build_item_rows(items: Array[Dictionary], backpack_remaining: int) -> void:
	if items.is_empty():
		var empty := Label.new()
		empty.text = "箱内已空。"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", Color(0.62, 0.68, 0.65, 1.0))
		item_list.add_child(empty)
		return
	for item in items:
		var presentation := RunUIViewModel.item_presentation(item)
		var rarity: Dictionary = presentation.get("rarity", {})
		var row := HBoxContainer.new()
		row.name = "ContextItemRow"
		row.add_theme_constant_override("separation", 4)
		item_list.add_child(row)
		var item_button := Button.new()
		item_button.name = "ContextItemInfo"
		item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_button.custom_minimum_size = Vector2(156, ROW_HEIGHT)
		item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item_button.clip_text = true
		item_button.text = _context_item_text(presentation)
		item_button.tooltip_text = String(presentation.get("detail_text", "尚未选择物品。"))
		_apply_item_icon(item_button, item)
		_style_button(item_button, &"secondary", 13)
		_apply_rarity_style(item_button, rarity)
		row.add_child(item_button)
		var instance_id := String(item.get("instance_id", ""))
		var action_allowed := _pickup_allowed(item)
		var blocked := int(presentation.get("weight", 0)) > backpack_remaining
		var action := Button.new()
		action.name = "ContextBlockedButton" if not action_allowed else ("ContextReplaceButton" if blocked else "ContextPickupButton")
		action.text = "不可拾取" if not action_allowed else ("替换" if blocked else "拾取")
		action.custom_minimum_size = Vector2(58, ROW_HEIGHT)
		action.tooltip_text = _pickup_blocked_text(item) if not action_allowed else ("背包空间不足，选择一件背包物品进行替换。" if blocked else "拾取当前物品。")
		action.disabled = not action_allowed
		_style_button(action, &"warning" if blocked else &"primary", 13)
		if not action_allowed:
			pass
		elif blocked:
			action.pressed.connect(func() -> void: _begin_replacement(instance_id))
		else:
			action.pressed.connect(func() -> void: pickup_requested.emit(instance_id))
		row.add_child(action)


func _pickup_allowed(item: Dictionary) -> bool:
	if item.has("pickup_allowed"):
		return bool(item.get("pickup_allowed", false))
	return bool(current_context.get("pickup_allowed", true))


func _pickup_blocked_text(item: Dictionary) -> String:
	var reason := String(item.get("pickup_blocked_reason", current_context.get("pickup_blocked_reason", ""))).strip_edges()
	return reason if reason != "" else "当前物品不可拾取。"


func _apply_item_icon(button: Button, item: Dictionary) -> void:
	var texture := ItemVisualCatalog.texture_for(item)
	if texture == null:
		return
	button.icon = texture
	button.expand_icon = true


func _style_button(button: Button, tone: StringName, font_size: int) -> void:
	button.focus_mode = Control.FOCUS_ALL
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.055, 0.058, 0.96)
	normal.border_color = Color(0.24, 0.50, 0.46, 0.86)
	if tone == &"primary":
		normal.border_color = Color(0.88, 0.68, 0.28, 0.96)
	elif tone == &"warning":
		normal.border_color = Color(0.94, 0.40, 0.24, 0.96)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	normal.content_margin_left = 8
	normal.content_margin_top = 5
	normal.content_margin_right = 8
	normal.content_margin_bottom = 5
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.06, 0.13, 0.13, 0.99)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.92, 0.94, 0.86, 1.0))


func _apply_rarity_style(button: Button, rarity: Dictionary) -> void:
	var rarity_color := Color(rarity.get("color", Color(0.66, 0.70, 0.68, 1.0)))
	button.set_meta("rarity_border_token", rarity.get("border_token", &"rarity.border.unknown"))
	var marker := ColorRect.new()
	marker.name = "WorldContextItemRarityMarker"
	marker.color = rarity_color
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.anchor_bottom = 1.0
	marker.offset_left = 3.0
	marker.offset_top = 5.0
	marker.offset_right = 7.0
	marker.offset_bottom = -5.0
	marker.set_meta("rarity_border_token", rarity.get("border_token", &"rarity.border.unknown"))
	button.add_child(marker)


func _build_replacement_candidate_content(
	button: Button,
	item: Dictionary,
	presentation: Dictionary,
	rarity: Dictionary
) -> void:
	var collectible_level := maxi(0, int(presentation.get("collectible_level", 0)))
	button.set_meta("replacement_layout", &"two_line")
	button.set_meta("item_instance_id", String(item.get("instance_id", "")))
	button.set_meta("collectible_level", collectible_level)

	var content := HBoxContainer.new()
	content.name = "ReplacementCandidateContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10.0
	content.offset_top = 4.0
	content.offset_right = -4.0
	content.offset_bottom = -4.0
	content.add_theme_constant_override("separation", 4)
	button.add_child(content)

	var texture := ItemVisualCatalog.texture_for(item)
	if texture != null:
		var icon := TextureRect.new()
		icon.name = "ReplacementCandidateIcon"
		icon.custom_minimum_size = Vector2(26, 26)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = texture
		content.add_child(icon)

	var text_stack := VBoxContainer.new()
	text_stack.name = "ReplacementCandidateTextStack"
	text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", -2)
	content.add_child(text_stack)

	var name_line := Label.new()
	name_line.name = "ReplacementCandidateName"
	name_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_line.add_theme_font_size_override("font_size", 12)
	name_line.add_theme_color_override("font_color", Color(0.92, 0.94, 0.86, 1.0))
	name_line.text = "%s ×%d" % [
		String(presentation.get("display_name", "未命名物资")),
		int(presentation.get("quantity", 1)),
	]
	text_stack.add_child(name_line)

	var meta_line := Label.new()
	meta_line.name = "ReplacementCandidateMeta"
	meta_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	meta_line.add_theme_font_size_override("font_size", 11)
	meta_line.add_theme_color_override(
		"font_color",
		Color(rarity.get("color", Color(0.70, 0.80, 0.76, 1.0)))
	)
	meta_line.text = _replacement_candidate_meta_text(presentation)
	meta_line.set_meta("collectible_level", collectible_level)
	text_stack.add_child(meta_line)


func _replacement_candidate_meta_text(presentation: Dictionary) -> String:
	var rarity_text := String(presentation.get("rarity_text", "[?] 未鉴定")).replace("] ", "]")
	var item_meta: Array[String] = [rarity_text]
	var collectible_level_text := String(presentation.get("collectible_level_text", "")).replace(" ", "")
	if collectible_level_text != "":
		item_meta.append(collectible_level_text)
	item_meta.append("重%s" % presentation.get("weight", 0))
	return "·".join(item_meta)


func _context_item_text(presentation: Dictionary) -> String:
	var item_meta: Array[String] = [String(presentation.get("rarity_text", "[?] 未鉴定"))]
	var collectible_level_text := String(presentation.get("collectible_level_text", ""))
	if collectible_level_text != "":
		item_meta.append(collectible_level_text)
	item_meta.append("重%s" % presentation.get("weight", 0))
	return "%s ×%d\n%s" % [
		String(presentation.get("display_name", "未命名物资")),
		int(presentation.get("quantity", 1)),
		" · ".join(item_meta),
	]


func _place_near_anchor() -> void:
	var popup_size := get_combined_minimum_size()
	if popup_size.x <= 0.0:
		popup_size.x = POPUP_WIDTH
	var parent_scale := Vector2.ONE
	var parent_canvas := get_parent() as CanvasItem
	if parent_canvas != null:
		parent_scale = parent_canvas.get_global_transform().get_scale().abs()
	scale = Vector2(1.0 / maxf(parent_scale.x, 0.001), 1.0 / maxf(parent_scale.y, 0.001))
	var effective_size := popup_size * scale
	var safe_left := room_bounds.position.x + 8.0
	var safe_right := room_bounds.end.x - 8.0
	var safe_top := room_bounds.position.y + 8.0
	var safe_bottom := room_bounds.end.y - 8.0
	var max_x := maxf(safe_left, safe_right - effective_size.x)
	var max_y := maxf(safe_top, safe_bottom - effective_size.y)

	# Keep both the interacted object and the player inside a hard visual-focus
	# exclusion zone, then prefer a nearby contextual placement. Edge docks are
	# retained only as fallbacks for crowded corners.
	var object_half_extent := Vector2(70.0, 64.0) if context_kind == &"chest" else Vector2(48.0, 48.0)
	var object_clearance := Rect2(
		anchor_world - object_half_extent * scale,
		object_half_extent * 2.0 * scale
	)
	var player_clearance := Rect2(
		player_world - Vector2(48.0, 66.0) * scale,
		Vector2(96.0, 132.0) * scale
	)
	var avoid_rects: Array[Rect2] = [object_clearance]
	if has_player_world:
		avoid_rects.append(player_clearance)
	var near_y := clampf(anchor_world.y - effective_size.y * 0.5, safe_top, max_y)
	var context_gap := 14.0
	var candidates: Array[Vector2] = [
		Vector2(
			anchor_world.x + object_half_extent.x * scale.x + context_gap,
			anchor_world.y - effective_size.y * 0.5
		),
		Vector2(
			anchor_world.x - object_half_extent.x * scale.x - context_gap - effective_size.x,
			anchor_world.y - effective_size.y * 0.5
		),
		Vector2(
			anchor_world.x - effective_size.x * 0.5,
			anchor_world.y - object_half_extent.y * scale.y - context_gap - effective_size.y
		),
		Vector2(
			anchor_world.x - effective_size.x * 0.5,
			anchor_world.y + object_half_extent.y * scale.y + context_gap
		),
		Vector2(safe_left, near_y),
		Vector2(max_x, near_y),
		Vector2(safe_left, safe_top),
		Vector2(max_x, safe_top),
		Vector2(safe_left, max_y),
		Vector2(max_x, max_y),
	]
	var gameplay_rect := gameplay_focus_rect if gameplay_focus_rect.has_area() else room_bounds
	var focal_rect := Rect2(
		gameplay_rect.position + gameplay_rect.size * Vector2(0.22, 0.18),
		gameplay_rect.size * Vector2(0.56, 0.64)
	)
	var best_position := candidates[0]
	var best_score := INF
	for candidate in candidates:
		var clamped_candidate := Vector2(
			clampf(candidate.x, safe_left, max_x),
			clampf(candidate.y, safe_top, max_y)
		)
		var candidate_rect := Rect2(clamped_candidate, effective_size)
		var score := _placement_score(candidate_rect, avoid_rects, reserved_rects, gameplay_rect, focal_rect, anchor_world)
		if score < best_score:
			best_score = score
			best_position = clamped_candidate
	position = Vector2(
		clampf(best_position.x, safe_left, max_x),
		clampf(best_position.y, safe_top, max_y)
	)
	size = popup_size
	set_meta("placement_mode", &"contextual_anchor")
	set_meta("placement_rect", Rect2(position, effective_size))
	set_meta("placement_safe_rect", room_bounds)
	set_meta("gameplay_focus_rect", gameplay_rect)
	set_meta("reserved_rects", reserved_rects.duplicate())
	set_meta("object_clearance_rect", object_clearance)
	set_meta("player_clearance_rect", player_clearance if has_player_world else Rect2())


func _placement_score(
	candidate_rect: Rect2,
	avoid_rects: Array[Rect2],
	exclusion_rects: Array[Rect2],
	gameplay_rect: Rect2,
	focal_rect: Rect2,
	anchor: Vector2
) -> float:
	var score := candidate_rect.get_center().distance_to(anchor) * 2.0
	for avoid_rect in avoid_rects:
		if candidate_rect.intersects(avoid_rect):
			score += 10000000.0 + candidate_rect.intersection(avoid_rect).get_area() * 10000.0
	for exclusion_rect in exclusion_rects:
		if candidate_rect.intersects(exclusion_rect):
			score += 10000000.0 + candidate_rect.intersection(exclusion_rect).get_area() * 10000.0
	if candidate_rect.intersects(gameplay_rect):
		score += candidate_rect.intersection(gameplay_rect).get_area() * 0.02
	if candidate_rect.intersects(focal_rect):
		score += candidate_rect.intersection(focal_rect).get_area() * 0.08
	return score


func _rect_array(value: Variant) -> Array[Rect2]:
	var result: Array[Rect2] = []
	if not (value is Array):
		return result
	for entry in value as Array:
		if entry is Rect2:
			result.append(entry as Rect2)
	return result


func _context_signature(context: Dictionary) -> String:
	var ids: Array[String] = []
	for item in context_items:
		var presentation := RunUIViewModel.item_presentation(item)
		ids.append("%s:%s:%s:%s:%s:%s:%s:%s" % [
			String(item.get("instance_id", "")),
			String(presentation.get("display_name", "未命名物资")),
			int(presentation.get("weight", 0)),
			int(presentation.get("quantity", 1)),
			String(presentation.get("rarity_text", "[?] 未鉴定")),
			String(presentation.get("short_description", "")),
			str(item.get("pickup_allowed", context.get("pickup_allowed", true))),
			String(item.get("pickup_blocked_reason", context.get("pickup_blocked_reason", ""))),
		])
	var inventory_ids: Array[String] = []
	for item in inventory_items:
		var presentation := RunUIViewModel.item_presentation(item)
		inventory_ids.append("%s:%s:%s:%s:%s:%s" % [
			String(item.get("instance_id", "")),
			String(presentation.get("display_name", "未命名物资")),
			int(presentation.get("weight", 0)),
			int(presentation.get("quantity", 1)),
			String(presentation.get("rarity_text", "[?] 未鉴定")),
			String(presentation.get("short_description", "")),
		])
	var payload: Dictionary = context.get("payload", {})
	var parts: Array[String] = [
		String(context_kind),
		str(context.get("opened_once", false)),
		str(context.get("container_open", false)),
		str(context.get("backpack_remaining", 0)),
		",".join(ids),
		",".join(inventory_ids),
		replacement_ground_id,
		String(payload.get("visual_state", "")),
		String(payload.get("event_type", "")),
		String(payload.get("display_title", "")),
		str(payload.get("completed", false)),
		str(payload.get("display_only", false)),
		str(payload.get("triggered", false)),
		String(payload.get("summary", "")),
		str(payload.get("entry_result", {})),
		str(payload.get("black_coin", 0)),
		str(payload.get("safe_yield", 0)),
		str(payload.get("inventory_count", 0)),
		str(payload.get("backpack_used", 0)),
		str(payload.get("backpack_capacity", 0)),
		str(payload.get("room_floor_item_count", 0)),
		String(payload.get("objective_summary", "")),
	]
	return "|".join(parts)


func _on_primary_pressed() -> void:
	if replacement_ground_id != "":
		_cancel_replacement()
	elif context_kind == &"chest" and not bool(current_context.get("opened_once", false)):
		chest_open_requested.emit()
	elif context_kind == &"event":
		var event_payload: Dictionary = current_context.get("payload", {})
		if not bool(event_payload.get("completed", false)) and not bool(event_payload.get("display_only", false)):
			event_open_requested.emit(event_payload.duplicate(true))
	elif context_kind == &"exit":
		var exit_payload: Dictionary = current_context.get("payload", {})
		exit_requested.emit(exit_payload.duplicate(true))


func _begin_replacement(instance_id: String) -> void:
	if instance_id == "":
		return
	replacement_ground_id = instance_id
	last_signature = ""
	_rebuild(current_context)
	_place_near_anchor()


func _cancel_replacement() -> void:
	replacement_ground_id = ""
	last_signature = ""
	_rebuild(current_context)
	_place_near_anchor()


func _contains_instance(items: Array[Dictionary], instance_id: String) -> bool:
	return not _item_by_instance(items, instance_id).is_empty()


func _item_by_instance(items: Array[Dictionary], instance_id: String) -> Dictionary:
	for item in items:
		if String(item.get("instance_id", "")) == instance_id:
			return item
	return {}


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for raw_item in value as Array:
			if raw_item is Dictionary:
				result.append((raw_item as Dictionary).duplicate(true))
	return result
