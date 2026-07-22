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
const ItemRarityDescriptor := preload("res://scripts/presentation/item_rarity_descriptor.gd")
const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const ReadableFont := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

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
var last_signature := ""
var current_context: Dictionary = {}
var replacement_ground_id := ""


func _ready() -> void:
	_build()
	set_process(true)


func apply_context(context: Dictionary) -> void:
	if context.is_empty():
		clear_context()
		return
	context_kind = StringName(context.get("interaction_kind", &"none"))
	anchor_world = Vector2(context.get("world_pos", Vector2.ZERO))
	has_player_world = context.has("player_world_pos")
	player_world = Vector2(context.get("player_world_pos", anchor_world))
	room_bounds = Rect2(context.get("room_bounds", room_bounds))
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
	visible = false
	z_index = 80
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(POPUP_WIDTH, 0)
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.012, 0.025, 0.028, 0.965)
	frame.border_color = Color(0.72, 0.51, 0.20, 0.95)
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(4)
	frame.content_margin_left = 12
	frame.content_margin_top = 10
	frame.content_margin_right = 12
	frame.content_margin_bottom = 10
	add_theme_stylebox_override("panel", frame)

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
	hint_label.add_theme_font_override("font", ReadableFont)
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
	status_label.add_theme_font_override("font", ReadableFont)
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
			hint_label.text = "按 E 打开"
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
	primary_button.visible = false
	hint_label.visible = true
	match context_kind:
		&"event":
			var completed := bool(payload.get("completed", false))
			title_label.text = "%s · 已处理" % String(payload.get("display_title", "异常事件")) if completed else String(payload.get("display_title", "异常事件"))
			hint_label.text = String(payload.get("summary", "已经处理，不会重复结算。" if completed else "靠近后可查看处理方式。"))
			if not completed and not bool(payload.get("display_only", false)):
				primary_button.text = "查看处理方式"
				primary_button.visible = true
		&"mine":
			var triggered := bool(payload.get("triggered", false))
			title_label.text = "雷区机关 · 已失效" if triggered else "雷区机关 · 警戒"
			var result: Dictionary = payload.get("entry_result", {})
			if not result.is_empty() and bool(result.get("first_trigger", false)):
				var hp_loss := absi(int(result.get("hp_delta", 0)))
				var pressure_gain := maxi(0, int(result.get("pressure_delta", 0)))
				hint_label.text = "生命 -%d · 压力 +%d%s" % [hp_loss, pressure_gain, " · 本次伤害致命" if bool(result.get("fatal", false)) else ""]
			elif triggered:
				hint_label.text = "已触发，不会再次造成伤害。"
			else:
				hint_label.text = String(payload.get("summary", "保持距离，留意地面机关。"))
		&"exit":
			title_label.text = String(payload.get("display_title", "撤离信标"))
			var objective := String(payload.get("objective_summary", "")).strip_edges()
			var lines: Array[String] = [
				"黑币 %d · 安全收益 %d" % [int(payload.get("black_coin", 0)), int(payload.get("safe_yield", 0))],
				"背包 %d/%d · 携带 %d 件" % [int(payload.get("backpack_used", 0)), int(payload.get("backpack_capacity", 0)), int(payload.get("inventory_count", 0))],
				"当前房间遗留 %d 件" % int(payload.get("room_floor_item_count", 0)),
			]
			if objective != "":
				lines.append("目标 · %s" % objective)
			hint_label.text = "\n".join(lines)
			primary_button.text = "请求撤离"
			primary_button.visible = true
		_:
			title_label.text = "附近目标"
			hint_label.text = "靠近后查看。"


func _build_replacement_view(context: Dictionary, backpack_remaining: int) -> void:
	var incoming := _item_by_instance(context_items, replacement_ground_id)
	var incoming_rarity := ItemRarityDescriptor.describe_item(incoming)
	title_label.text = "选择要放下的物品"
	hint_label.text = "换入：%s　%s　重量 %d。只有释放后容量足够的物品可选。" % [
		RunUIViewModel.item_display_name(incoming),
		String(incoming_rarity.get("display_text", "[?] 未鉴定")),
		int(incoming.get("weight", 0)),
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
		empty.add_theme_font_override("font", ReadableFont)
		empty.add_theme_color_override("font_color", Color(0.88, 0.48, 0.34, 1.0))
		item_list.add_child(empty)
		return
	var incoming_weight := int(incoming.get("weight", 0))
	for item in inventory_items:
		var rarity := ItemRarityDescriptor.describe_item(item)
		var row := HBoxContainer.new()
		row.name = "ReplacementCandidateRow"
		row.add_theme_constant_override("separation", 4)
		item_list.add_child(row)
		var item_button := Button.new()
		item_button.name = "ReplacementCandidateInfo"
		item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_button.custom_minimum_size = Vector2(156, ROW_HEIGHT)
		item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item_button.clip_text = true
		item_button.text = "%s  ·  %s  ·  重%d" % [
			RunUIViewModel.item_display_name(item),
			String(rarity.get("display_text", "[?] 未鉴定")),
			int(item.get("weight", 0)),
		]
		item_button.tooltip_text = String(item.get("short_description", ""))
		_apply_item_icon(item_button, item)
		_style_button(item_button, &"secondary", 13)
		_apply_rarity_style(item_button, rarity)
		item_button.add_theme_font_override("font", ReadableFont)
		row.add_child(item_button)
		var candidate_id := String(item.get("instance_id", ""))
		var candidate_weight := int(item.get("weight", 0))
		var eligible := backpack_remaining + candidate_weight >= incoming_weight
		var choose := Button.new()
		choose.name = "ReplacementCandidateButton"
		choose.text = "放下" if eligible else "容量不足"
		choose.custom_minimum_size = Vector2(72, ROW_HEIGHT)
		choose.disabled = not eligible
		choose.tooltip_text = "放下该物品并拾取地面物。" if eligible else "即使放下该物品，背包容量仍不足。"
		_style_button(choose, &"warning" if eligible else &"secondary", 13)
		choose.pressed.connect(func() -> void: replace_requested.emit(replacement_ground_id, candidate_id))
		row.add_child(choose)


func _build_item_rows(items: Array[Dictionary], backpack_remaining: int) -> void:
	if items.is_empty():
		var empty := Label.new()
		empty.text = "箱内已空。"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_font_override("font", ReadableFont)
		empty.add_theme_color_override("font_color", Color(0.62, 0.68, 0.65, 1.0))
		item_list.add_child(empty)
		return
	for item in items:
		var rarity := ItemRarityDescriptor.describe_item(item)
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
		item_button.text = "%s  ·  %s  ·  重%d" % [
			RunUIViewModel.item_display_name(item),
			String(rarity.get("display_text", "[?] 未鉴定")),
			int(item.get("weight", 0)),
		]
		item_button.tooltip_text = String(item.get("short_description", ""))
		_apply_item_icon(item_button, item)
		_style_button(item_button, &"secondary", 13)
		_apply_rarity_style(item_button, rarity)
		item_button.add_theme_font_override("font", ReadableFont)
		row.add_child(item_button)
		var instance_id := String(item.get("instance_id", ""))
		var action_allowed := _pickup_allowed(item)
		var blocked := int(item.get("weight", 0)) > backpack_remaining
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
	button.add_theme_color_override("font_color", rarity_color)
	for state in [&"normal", &"hover", &"pressed", &"focus"]:
		var base := button.get_theme_stylebox(StringName(state))
		if not (base is StyleBoxFlat):
			continue
		var styled := (base as StyleBoxFlat).duplicate() as StyleBoxFlat
		styled.border_color = rarity_color
		styled.border_width_left = 3
		button.add_theme_stylebox_override(StringName(state), styled)


func _place_near_anchor() -> void:
	var popup_size := get_combined_minimum_size()
	if popup_size.x <= 0.0:
		popup_size.x = POPUP_WIDTH
	# The room world is scaled to fill the gameplay viewport. Cancel only that
	# presentation scale so the contextual UI keeps a stable readable pixel size.
	var parent_scale := Vector2.ONE
	var parent_canvas := get_parent() as CanvasItem
	if parent_canvas != null:
		parent_scale = parent_canvas.get_global_transform().get_scale().abs()
	scale = Vector2(1.0 / maxf(parent_scale.x, 0.001), 1.0 / maxf(parent_scale.y, 0.001))
	var effective_size := popup_size * scale
	# Clearance is measured from the interaction anchor at the visual centre.
	# Keep enough room for the sprite/animation, but preserve the gun-game-style
	# relationship between a world object and its temporary interaction card.
	var clearance_screen := 72.0 if context_kind == &"chest" else 36.0
	var horizontal_gap := clearance_screen * scale.x
	var safe_left := room_bounds.position.x + 8.0
	var safe_right := room_bounds.end.x - 8.0
	var right_x := anchor_world.x + horizontal_gap
	var left_x := anchor_world.x - effective_size.x - horizontal_gap
	var right_fits := right_x + effective_size.x <= safe_right
	var left_fits := left_x >= safe_left
	var x := right_x
	var y := anchor_world.y - effective_size.y * 0.55
	var player_clearance := Rect2()
	if has_player_world:
		player_clearance = Rect2(
			player_world - Vector2(44.0, 64.0) * scale,
			Vector2(88.0, 128.0) * scale
		)
	if right_fits and left_fits:
		var right_avoids_player := true
		var left_avoids_player := true
		if has_player_world:
			right_avoids_player = not Rect2(Vector2(right_x, y), effective_size).intersects(player_clearance)
			left_avoids_player = not Rect2(Vector2(left_x, y), effective_size).intersects(player_clearance)
		if right_avoids_player != left_avoids_player:
			x = right_x if right_avoids_player else left_x
		else:
			var right_margin := safe_right - (right_x + effective_size.x)
			var left_margin := left_x - safe_left
			x = right_x if right_margin >= left_margin else left_x
	elif left_fits:
		x = left_x
	elif not right_fits and context_kind == &"ground_loot":
		# A centered floor item can leave too little room for a readable 308 px
		# card on either side of the scaled room. In that case a clamped side card
		# would cover the very entity the player is inspecting. Fall back above or
		# below the entity, keeping a real screen-space gap around the target.
		x = anchor_world.x - effective_size.x * 0.5
		var vertical_gap := 30.0 * scale.y
		var above_y := anchor_world.y - effective_size.y - vertical_gap
		var below_y := anchor_world.y + vertical_gap
		var top_safe := room_bounds.position.y + 8.0
		var bottom_safe := room_bounds.end.y - 8.0
		var above_fits := above_y >= top_safe
		var below_fits := below_y + effective_size.y <= bottom_safe
		if above_fits and below_fits:
			var above_margin := above_y - top_safe
			var below_margin := bottom_safe - (below_y + effective_size.y)
			y = above_y if above_margin >= below_margin else below_y
		elif above_fits:
			y = above_y
		else:
			y = below_y
	if has_player_world and Rect2(Vector2(x, y), effective_size).intersects(player_clearance):
		# If the only horizontal side covers the nearby character, prefer a true
		# above/below card. This keeps both the player and the projected object
		# readable instead of treating screen-edge clamping as successful layout.
		var vertical_gap := (46.0 if context_kind == &"chest" else 30.0) * scale.y
		var vertical_x := clampf(anchor_world.x - effective_size.x * 0.5, safe_left, safe_right - effective_size.x)
		var above_y := anchor_world.y - effective_size.y - vertical_gap
		var below_y := anchor_world.y + vertical_gap
		var top_safe := room_bounds.position.y + 8.0
		var bottom_safe := room_bounds.end.y - 8.0
		var above_rect := Rect2(Vector2(vertical_x, above_y), effective_size)
		var below_rect := Rect2(Vector2(vertical_x, below_y), effective_size)
		var above_clear := above_y >= top_safe and not above_rect.intersects(player_clearance)
		var below_clear := below_y + effective_size.y <= bottom_safe and not below_rect.intersects(player_clearance)
		if above_clear or below_clear:
			x = vertical_x
			if above_clear and below_clear:
				y = above_y if above_y - top_safe >= bottom_safe - (below_y + effective_size.y) else below_y
			else:
				y = above_y if above_clear else below_y
	x = clampf(x, safe_left, safe_right - effective_size.x)
	y = clampf(y, room_bounds.position.y + 8.0, room_bounds.end.y - effective_size.y - 8.0)
	position = Vector2(x, y)
	# A Control positioned directly under the room Node2D can retain its former
	# right/bottom offsets when moved. Reassert the fitted content size after the
	# move so those offsets never stretch the panel down to the action bar.
	size = popup_size


func _context_signature(context: Dictionary) -> String:
	var ids: Array[String] = []
	for item in context_items:
		ids.append("%s:%s:%s:%s:%s" % [
			String(item.get("instance_id", "")),
			int(item.get("weight", 0)),
			String(ItemRarityDescriptor.normalize(item.get("rarity", &"unknown"))),
			str(item.get("pickup_allowed", context.get("pickup_allowed", true))),
			String(item.get("pickup_blocked_reason", context.get("pickup_blocked_reason", ""))),
		])
	var inventory_ids: Array[String] = []
	for item in inventory_items:
		inventory_ids.append("%s:%s:%s" % [
			String(item.get("instance_id", "")),
			int(item.get("weight", 0)),
			String(ItemRarityDescriptor.normalize(item.get("rarity", &"unknown"))),
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
