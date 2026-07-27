extends Control
class_name LootResultPanel

const PresentationTheme := preload("res://scripts/presentation/presentation_theme.gd")
const PresentationMapping := preload("res://scripts/presentation/presentation_mapping.gd")
const Art24ItemVisualCatalog := preload("res://scripts/presentation/art24/art24_item_visual_catalog.gd")
const Art09ManifestAssetMapping := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const SemanticActionHintScript := preload("res://scripts/core/input/semantic_action_hint.gd")
const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")

signal close_requested

var dimmer: ColorRect
var result_panel: PanelContainer
var title_label: Label
var source_label: Label
var summary_label: Label
var item_list: VBoxContainer
var footer_label: Label
var close_button: Button
var built := false
var _ui_scale_factor := 1.0
var _last_layout_profile: Dictionary = {}


func _ready() -> void:
	_ui_scale_factor = Art10UISkinKitScript.runtime_ui_scale_factor()
	build()


func build() -> void:
	if built:
		return
	built = true
	name = "LootResultPanel"
	Art10UISkinKitScript.apply_player_ui_theme(self)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	dimmer = ColorRect.new()
	dimmer.name = "LootResultDimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.61)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	result_panel = PanelContainer.new()
	result_panel.name = "LootResultMetalPanel"
	result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	result_panel.add_theme_stylebox_override("panel", _textured_style("res://assets/art24/ui/modal_frame.png", 34, 28))
	add_child(result_panel)

	var root := VBoxContainer.new()
	root.name = "LootResultContent"
	root.add_theme_constant_override("separation", 8)
	result_panel.add_child(root)

	var header := HBoxContainer.new()
	header.name = "LootResultHeader"
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)

	var heading_stack := VBoxContainer.new()
	heading_stack.name = "LootResultHeadingStack"
	heading_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_stack.add_theme_constant_override("separation", 1)
	header.add_child(heading_stack)

	title_label = Label.new()
	title_label.name = "LootResultTitle"
	title_label.text = "回收记录"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color("f3d487"))
	heading_stack.add_child(title_label)

	source_label = Label.new()
	source_label.name = "LootResultSource"
	source_label.text = "搜索完成，物资已按容量规则分配"
	source_label.add_theme_font_size_override("font_size", 13)
	source_label.add_theme_color_override("font_color", Color("a9b6b1"))
	heading_stack.add_child(source_label)

	close_button = Button.new()
	close_button.name = "LootResultCloseButton"
	close_button.text = "确认"
	close_button.focus_mode = Control.FOCUS_ALL
	close_button.custom_minimum_size = Vector2(92, 38)
	_apply_button_style(close_button)
	close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close_button)

	var divider := HSeparator.new()
	divider.modulate = Color("a87b32")
	root.add_child(divider)

	summary_label = Label.new()
	summary_label.name = "LootResultSummary"
	summary_label.add_theme_font_size_override("font_size", 16)
	summary_label.add_theme_color_override("font_color", Color("f0c96c"))
	summary_label.custom_minimum_size = Vector2(0, 28)
	root.add_child(summary_label)

	var scroll := ScrollContainer.new()
	scroll.name = "LootResultScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 150)
	root.add_child(scroll)

	item_list = VBoxContainer.new()
	item_list.name = "LootResultItems"
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 7)
	scroll.add_child(item_list)

	var footer_divider := HSeparator.new()
	footer_divider.modulate = Color("795b2b")
	root.add_child(footer_divider)

	footer_label = Label.new()
	footer_label.name = "LootResultFooter"
	footer_label.text = "%s / %s  确认并返回探索" % [
		SemanticActionHintScript.display_label(&"ui_accept"),
		SemanticActionHintScript.display_label(&"cancel"),
	]
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer_label.add_theme_font_size_override("font_size", 13)
	footer_label.add_theme_color_override("font_color", Color("a8b4b0"))
	root.add_child(footer_label)
	_refresh_ui_scale_metrics()


func set_ui_scale_factor(value: float) -> bool:
	_ui_scale_factor = Art10UISkinKitScript.normalize_runtime_ui_scale_factor(value)
	if not _last_layout_profile.is_empty():
		var profile := _last_layout_profile.duplicate(true)
		profile["ui_scale_factor"] = _ui_scale_factor
		apply_layout_profile(profile)
	else:
		_refresh_ui_scale_metrics()
	return is_equal_approx(_ui_scale_factor, Art10UISkinKitScript.normalize_runtime_ui_scale_factor(value))


func get_ui_scale_factor() -> float:
	return _ui_scale_factor


func apply_layout_profile(profile: Dictionary) -> void:
	if not built:
		build()
	_last_layout_profile = profile.duplicate(true)
	_ui_scale_factor = Art10UISkinKitScript.normalize_runtime_ui_scale_factor(
		float(profile.get("ui_scale_factor", _ui_scale_factor))
	)
	var raw_size: Variant = profile.get("actual_viewport_size", profile.get("supported_size", Vector2i(1280, 720)))
	var viewport_size := Vector2(float(raw_size.x), float(raw_size.y))
	var width := maxf(1.0, viewport_size.x)
	var height := maxf(1.0, viewport_size.y)
	var left_width := clampf(width * 0.235, 250.0, 430.0)
	var gameplay_left := left_width
	var gameplay_width := maxf(300.0, width - gameplay_left)
	var panel_width := clampf(gameplay_width * 0.69, 560.0, 760.0)
	panel_width = minf(panel_width, gameplay_width - 40.0)
	var panel_height := clampf(height * 0.57, 350.0, 520.0)
	panel_height = minf(panel_height, height - 72.0)
	var panel_x := gameplay_left + (gameplay_width - panel_width) * 0.5
	var panel_y := (height - panel_height) * 0.46
	_set_rect(result_panel, Rect2(panel_x, panel_y, panel_width, panel_height))
	_refresh_ui_scale_metrics()


func show_result(title: String, reward: Dictionary, last_message: String = "") -> void:
	if not built:
		build()
	title_label.text = title
	source_label.text = _source_copy(title, reward, last_message)
	var items := _collect_items(reward)
	var total_value := 0
	for item: Dictionary in items:
		total_value += maxi(0, int(item.get("base_value", item.get("value", 0))))
	var pending_delta := int(reward.get("black_coin_delta", reward.get("pending_gold_delta", reward.get("gold", 0))))
	var safe_delta := int(reward.get("safe_yield_delta", reward.get("gold_coin_delta", 0)))
	summary_label.text = "待结算 %+d    安全收益 %+d    回收物 %d 件    估值 +%d" % [pending_delta, safe_delta, items.size(), total_value]
	for child in item_list.get_children():
		child.queue_free()
	if items.is_empty():
		var empty := Label.new()
		empty.text = "本次没有新增物资。货币与状态变化已记入左侧作业摘要。"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(0, 88)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_set_scaled_font(empty, 15)
		empty.add_theme_color_override("font_color", Color("c4ccc8"))
		item_list.add_child(empty)
	else:
		for item: Dictionary in items:
			_add_item_card(item)
	visible = true
	close_button.grab_focus()


func hide_panel() -> void:
	visible = false
	get_viewport().gui_release_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or event == null or event.is_echo():
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()


func _add_item_card(item: Dictionary) -> void:
	var presentation := RunUIViewModel.item_presentation(item)
	var rarity: Dictionary = presentation.get("rarity", {})
	var row_texture := "res://assets/art24/ui/item_row_normal.png"
	var card := PanelContainer.new()
	card.name = "LootResultItemCard"
	_set_scaled_minimum(card, Vector2(0, 88))
	card.set_meta("rarity_border_token", rarity.get("border_token", &"rarity.border.unknown"))
	card.set_meta("collectible_level", int(presentation.get("collectible_level", 0)))
	card.tooltip_text = String(presentation.get("detail_text", ""))
	card.add_theme_stylebox_override("panel", _textured_style(row_texture, 15, 12))
	item_list.add_child(card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var rarity_edge := ColorRect.new()
	rarity_edge.name = "LootResultRarityEdge"
	_set_scaled_minimum(rarity_edge, Vector2(4, 62))
	rarity_edge.color = Color(rarity.get("color", Color("a9b0ad")))
	rarity_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rarity_edge.set_meta("rarity_border_token", rarity.get("border_token", &"rarity.border.unknown"))
	row.add_child(rarity_edge)

	var icon := TextureRect.new()
	icon.name = "LootResultItemIcon"
	icon.custom_minimum_size = Vector2(62, 62)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _item_texture(item)
	row.add_child(icon)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	row.add_child(copy)

	var name_label := Label.new()
	name_label.text = "%s  ×%d" % [
		String(presentation.get("display_name", "未知物资")),
		maxi(1, int(presentation.get("quantity", 1))),
	]
	_set_scaled_font(name_label, 18)
	name_label.add_theme_color_override("font_color", Color(rarity.get("color", Color("a9b0ad"))))
	copy.add_child(name_label)

	var meta_label := Label.new()
	meta_label.name = "LootResultRarityMeta"
	var meta_parts: Array[String] = [
		String(presentation.get("type_label", _item_type_label(String(item.get("item_type", item.get("main_type", "collectible")))))),
		String(rarity.get("display_text", "[?] 未鉴定")),
	]
	var collectible_level_text := String(presentation.get("collectible_level_text", ""))
	if collectible_level_text != "":
		meta_parts.append(collectible_level_text)
	meta_label.text = "  ·  ".join(meta_parts) + _effect_copy(item)
	_set_scaled_font(meta_label, 13)
	meta_label.add_theme_color_override("font_color", Color("b7c4c0"))
	copy.add_child(meta_label)

	var description := Label.new()
	description.text = String(item.get("short_description", "可回收物资。撤离成功后按结算规则入库。"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	_set_scaled_font(description, 13)
	description.add_theme_color_override("font_color", Color("919d99"))
	copy.add_child(description)

	var value_label := Label.new()
	value_label.text = "估值\n%d" % maxi(0, int(item.get("base_value", item.get("value", 0))))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_set_scaled_minimum(value_label, Vector2(70, 62))
	_set_scaled_font(value_label, 14)
	value_label.add_theme_color_override("font_color", Color("f0c96c"))
	row.add_child(value_label)


func _collect_items(reward: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in ["inventory_items", "ground_items", "equipped_items", "items"]:
		var raw: Variant = reward.get(key, [])
		if not (raw is Array):
			continue
		for value in raw:
			if value is Dictionary:
				result.append((value as Dictionary).duplicate(true))
	return result


func _item_texture(item: Dictionary) -> Texture2D:
	var mapped := Art24ItemVisualCatalog.texture_for(item)
	if mapped == null:
		mapped = Art09ManifestAssetMapping.resolve_texture(PresentationMapping.inventory_item_icon_ref(item))
	if mapped != null:
		return mapped
	var item_id := String(item.get("item_id", "salvage_satchel")).to_lower()
	var aliases := {
		"access_key": "access_key",
		"anomaly_shard": "anomaly_shard",
		"armor_plate": "armor_plate",
		"coin_cache": "coin_cache",
		"copper_coil": "copper_coil",
		"emergency_bandage": "emergency_bandage",
		"salvage_satchel": "salvage_satchel",
		"scanner_probe": "scanner_probe",
	}
	var selected := "salvage_satchel"
	for token in aliases:
		if item_id.find(token) >= 0:
			selected = String(aliases[token])
			break
	return load("res://assets/art24/items/world/%s.png" % selected) as Texture2D


func _source_copy(title: String, reward: Dictionary, last_message: String) -> String:
	var placement := "物资已放入临时回收包"
	if not _array_from(reward, "ground_items").is_empty():
		placement = "背包容量不足的物资已留在当前房间地面"
	if title.find("战斗") >= 0:
		return "威胁清除完成，%s" % placement
	if title.find("事件") >= 0 or title.find("遭遇") >= 0:
		return "事件结算完成，%s" % placement
	if last_message.strip_edges() != "":
		return "房间搜索完成，%s" % placement
	return "物资结算完成，%s" % placement


func _effect_copy(item: Dictionary) -> String:
	var kind := String(item.get("effect_kind", ""))
	var amount := int(item.get("effect_amount", 0))
	if kind == "":
		return ""
	var label := "效果"
	match kind:
		"heal": label = "恢复生命"
		"pressure_down": label = "降低压力"
		"power_up": label = "提升战力"
	return "  ·  %s %+d" % [label, amount]


func _item_type_label(value: String) -> String:
	match value:
		"consumable": return "消耗品"
		"equipment": return "装备"
		"recovered", "treasure", "collectible": return "回收物"
		"currency": return "货币"
		_: return "物资"


func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	return raw as Array if raw is Array else []


func _textured_style(path: String, texture_margin: int, content_margin: int) -> StyleBox:
	var texture := load(path) as Texture2D
	if texture == null:
		var fallback := StyleBoxFlat.new()
		fallback.bg_color = Color("071114")
		fallback.border_color = Color("a97931")
		fallback.set_border_width_all(2)
		fallback.set_content_margin_all(float(content_margin))
		return fallback
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = texture_margin
	style.texture_margin_top = texture_margin
	style.texture_margin_right = texture_margin
	style.texture_margin_bottom = texture_margin
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	style.draw_center = true
	return style


func _apply_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("173032")
	normal.border_color = Color("a87b32")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(3)
	normal.set_content_margin_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("244548")
	hover.border_color = Color("e2ba61")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	_set_scaled_font(button, 15)
	_set_scaled_minimum(button, Vector2(92, 38))
	button.add_theme_color_override("font_color", Color("f0d58e"))


func _set_scaled_font(control: Control, base_size: int) -> void:
	control.set_meta("ui_scale_base_font_size", base_size)
	control.add_theme_font_size_override(
		"font_size",
		Art10UISkinKitScript.scaled_font_size(base_size, _ui_scale_factor)
	)


func _set_scaled_minimum(control: Control, base_size: Vector2) -> void:
	control.set_meta("ui_scale_base_minimum_size", base_size)
	control.custom_minimum_size = Art10UISkinKitScript.scaled_control_minimum(
		base_size,
		minf(_ui_scale_factor, 1.25)
	)


func _refresh_ui_scale_metrics(node: Node = self) -> void:
	if node is Control:
		var control := node as Control
		if control.has_meta("ui_scale_base_font_size"):
			_set_scaled_font(control, int(control.get_meta("ui_scale_base_font_size")))
		if control.has_meta("ui_scale_base_minimum_size"):
			var base_minimum: Vector2 = control.get_meta("ui_scale_base_minimum_size")
			_set_scaled_minimum(control, base_minimum)
	if node == self:
		if title_label != null:
			_set_scaled_font(title_label, 24)
		if source_label != null:
			_set_scaled_font(source_label, 13)
		if summary_label != null:
			_set_scaled_font(summary_label, 16)
		if footer_label != null:
			_set_scaled_font(footer_label, 13)
		if close_button != null:
			_set_scaled_font(close_button, 15)
			_set_scaled_minimum(close_button, Vector2(92, 38))
	for child in node.get_children():
		_refresh_ui_scale_metrics(child)


func _set_rect(control: Control, rect: Rect2) -> void:
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y
