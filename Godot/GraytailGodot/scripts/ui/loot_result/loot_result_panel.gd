extends Control
class_name LootResultPanel

const PresentationTheme := preload("res://scripts/presentation/presentation_theme.gd")
const PresentationMapping := preload("res://scripts/presentation/presentation_mapping.gd")
const Art09ManifestAssetMapping := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")

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


func _ready() -> void:
	build()


func build() -> void:
	if built:
		return
	built = true
	name = "LootResultPanel"
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
	footer_label.text = "Enter / F / Esc  确认并返回探索"
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer_label.add_theme_font_size_override("font_size", 13)
	footer_label.add_theme_color_override("font_color", Color("a8b4b0"))
	root.add_child(footer_label)


func apply_layout_profile(profile: Dictionary) -> void:
	if not built:
		build()
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
		empty.add_theme_font_size_override("font_size", 15)
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
	if not visible or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_F, KEY_ESCAPE]:
		close_requested.emit()
		get_viewport().set_input_as_handled()


func _add_item_card(item: Dictionary) -> void:
	var rarity := StringName(item.get("rarity", &"common"))
	var row_texture := "res://assets/art24/ui/item_row_normal.png"
	if rarity in [&"rare", &"tier_3", &"epic", &"tier_4", &"legendary", &"tier_5"]:
		row_texture = "res://assets/art24/ui/item_row_selected.png"
	var card := PanelContainer.new()
	card.name = "LootResultItemCard"
	card.custom_minimum_size = Vector2(0, 88)
	card.add_theme_stylebox_override("panel", _textured_style(row_texture, 15, 12))
	item_list.add_child(card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

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
	name_label.text = "%s  ×%d" % [String(item.get("display_name", item.get("item_id", "未知物资"))), maxi(1, int(item.get("count", 1)))]
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", _rarity_color(rarity))
	copy.add_child(name_label)

	var meta_label := Label.new()
	meta_label.text = "%s  ·  %s%s" % [_item_type_label(String(item.get("item_type", item.get("main_type", "collectible")))), _rarity_label(rarity), _effect_copy(item)]
	meta_label.add_theme_font_size_override("font_size", 12)
	meta_label.add_theme_color_override("font_color", Color("b7c4c0"))
	copy.add_child(meta_label)

	var description := Label.new()
	description.text = String(item.get("short_description", "可回收物资。撤离成功后按结算规则入库。"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	description.add_theme_font_size_override("font_size", 12)
	description.add_theme_color_override("font_color", Color("919d99"))
	copy.add_child(description)

	var value_label := Label.new()
	value_label.text = "估值\n%d" % maxi(0, int(item.get("base_value", item.get("value", 0))))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size = Vector2(70, 62)
	value_label.add_theme_font_size_override("font_size", 14)
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
	var mapped := Art09ManifestAssetMapping.resolve_texture(PresentationMapping.inventory_item_icon_ref(item))
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


func _rarity_label(value: StringName) -> String:
	match value:
		&"common", &"tier_1": return "普通"
		&"uncommon", &"tier_2": return "优良"
		&"rare", &"tier_3": return "稀有"
		&"epic", &"tier_4": return "珍贵"
		&"legendary", &"tier_5": return "传奇"
		&"unique": return "唯一"
		_: return "未鉴定"


func _rarity_color(value: StringName) -> Color:
	match value:
		&"uncommon", &"tier_2": return Color("9fdc9b")
		&"rare", &"tier_3": return Color("83c9ff")
		&"epic", &"tier_4": return Color("c9a2ff")
		&"legendary", &"tier_5", &"unique": return Color("f2c66d")
		_: return Color("e6e1cf")


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
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("f0d58e"))


func _set_rect(control: Control, rect: Rect2) -> void:
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y
