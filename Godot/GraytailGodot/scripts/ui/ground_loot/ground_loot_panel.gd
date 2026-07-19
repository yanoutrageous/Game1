extends PanelContainer
class_name GroundLootPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const PresentationMappingScript := preload("res://scripts/presentation/presentation_mapping.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")

signal pickup_item_requested(instance_id: String)
signal replace_item_requested(instance_id: String)
signal close_requested

var title_label: Label
var summary_label: Label
var item_list: VBoxContainer
var item_scroll: ScrollContainer
var tooltip_label: Label
var last_result_label: Label
var item_button_minimum_size: Vector2 = Vector2(360, 52)


func _ready() -> void:
	build()


func build() -> void:
	name = "GroundLootPanel"
	visible = false
	offset_left = 390.0
	offset_top = 116.0
	offset_right = 930.0
	offset_bottom = 610.0
	_apply_art21_panel_frame()
	if get_child_count() > 0:
		return
	var root := VBoxContainer.new()
	root.name = "GroundLootPanelContent"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var header_panel := PanelContainer.new()
	header_panel.name = "GroundLootTitlePlate"
	_apply_art21r2_modal_panel(header_panel, &"art21r2.modal.title_plate", 8, 34)
	root.add_child(header_panel)
	var header := HBoxContainer.new()
	header.name = "GroundLootPanelHeader"
	header.add_theme_constant_override("separation", 8)
	header_panel.add_child(header)
	title_label = Label.new()
	title_label.name = "GroundLootPanelTitle"
	title_label.text = "地面回收物"
	title_label.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Art10UISkinKitScript.apply_label(title_label, 20, PresentationTheme.color_for_key(&"ui.accent"))
	header.add_child(title_label)
	var close_button := Button.new()
	close_button.name = "GroundLootCloseButton"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(76, 34)
	_apply_art21r2_modal_button(close_button, &"art21r2.modal.button.secondary", &"secondary", 15)
	close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close_button)

	var summary_panel := PanelContainer.new()
	summary_panel.name = "GroundLootSummaryPanel"
	_apply_art21r2_modal_panel(summary_panel, &"art21r2.modal.section.panel", 8, 32)
	root.add_child(summary_panel)
	summary_label = Label.new()
	summary_label.name = "GroundLootSummary"
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_font_size_override("font_size", 15)
	summary_label.add_theme_constant_override("line_spacing", 2)
	summary_panel.add_child(summary_label)

	var item_list_panel := PanelContainer.new()
	item_list_panel.name = "GroundLootItemListPanel"
	item_list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_art21r2_modal_panel(item_list_panel, &"art21r2.modal.section.panel", 8, 32)
	root.add_child(item_list_panel)
	item_scroll = ScrollContainer.new()
	item_scroll.name = "GroundLootItemScroll"
	item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	item_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	item_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list_panel.add_child(item_scroll)
	item_list = VBoxContainer.new()
	item_list.name = "GroundLootItemList"
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 5)
	item_scroll.add_child(item_list)

	var tooltip_panel := PanelContainer.new()
	tooltip_panel.name = "GroundLootTooltipPanel"
	_apply_art21r2_modal_panel(tooltip_panel, &"art21r2.modal.section.panel", 8, 32)
	root.add_child(tooltip_panel)
	tooltip_label = Label.new()
	tooltip_label.name = "GroundLootItemTooltip"
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.custom_minimum_size = Vector2(500, 54)
	tooltip_label.add_theme_font_size_override("font_size", 15)
	tooltip_label.add_theme_constant_override("line_spacing", 2)
	tooltip_panel.add_child(tooltip_label)

	var result_panel := PanelContainer.new()
	result_panel.name = "GroundLootCommandResultPanel"
	_apply_art21r2_modal_panel(result_panel, &"art21r2.modal.section.panel", 8, 32)
	root.add_child(result_panel)
	last_result_label = Label.new()
	last_result_label.name = "GroundLootCommandResult"
	last_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	last_result_label.custom_minimum_size = Vector2(0, 22)
	last_result_label.add_theme_font_size_override("font_size", 14)
	result_panel.add_child(last_result_label)


func apply_snapshot(snapshot: Dictionary) -> void:
	if summary_label == null:
		build()
	var ground_items: Array = _array_from(snapshot, "room_floor_items")
	summary_label.text = "当前房间地面回收物：%s | 背包容量：%s/%s | 剩余容量：%s" % [
		ground_items.size(),
		snapshot.get("backpack_used", 0),
		snapshot.get("backpack_capacity", 0),
		snapshot.get("backpack_remaining", 0),
	]
	Art10UISkinKitScript.apply_label(summary_label, 15, PresentationTheme.text_color())
	for child in item_list.get_children():
		child.queue_free()
	if ground_items.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.custom_minimum_size = Vector2(0, 96)
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_constant_override("line_spacing", 2)
		empty_label.text = "地面无可回收物。搜索房间、物资箱或处理异常体后，掉落会留在当前场景。"
		Art10UISkinKitScript.apply_label(empty_label, 15, PresentationTheme.text_color())
		item_list.add_child(empty_label)
	else:
		for item: Dictionary in ground_items:
			_add_item_row(item)
	if tooltip_label != null:
		tooltip_label.text = "选择物品查看效果；拾取会检查背包容量，容量不足时物品保留在地面。"
		Art10UISkinKitScript.apply_label(tooltip_label, 15, Color(0.75, 0.82, 0.78, 1.0))


func show_command_result(result: Dictionary) -> void:
	if last_result_label == null:
		return
	last_result_label.text = Art10UISkinKitScript.sanitize_player_copy(RunUIViewModel.command_result_text(result))
	Art10UISkinKitScript.apply_label(last_result_label, 14, PresentationTheme.color_for_key(&"ui.accent"))
	var pulse_state := &"ready"
	if not bool(result.get("accepted", result.get("ok", false))):
		pulse_state = &"warning"
	Art10UISkinKitScript.play_feedback_pulse(last_result_label, pulse_state)


func show_panel() -> void:
	visible = true
	Art10UISkinKitScript.play_panel_open(self)


func hide_panel() -> void:
	visible = false
	get_viewport().gui_release_focus()


func apply_layout_profile(profile: Dictionary) -> void:
	var is_low := bool(profile.get("is_low_resolution", false))
	var is_high := bool(profile.get("is_high_resolution", false))
	var rect := _main_game_modal_rect(profile, 10.0)
	offset_left = rect.position.x
	offset_top = rect.position.y
	offset_right = rect.position.x + rect.size.x
	offset_bottom = rect.position.y + rect.size.y
	var content_width: float = max(280.0, rect.size.x - 72.0)
	item_button_minimum_size = Vector2(
		max(210.0, content_width - (166.0 if is_low else 184.0)),
		46.0 if is_low else (56.0 if is_high else 52.0)
	)
	if item_scroll != null:
		item_scroll.custom_minimum_size = Vector2(content_width, 132.0 if is_low else (224.0 if is_high else 184.0))
	if tooltip_label != null:
		tooltip_label.custom_minimum_size = Vector2(content_width, 48.0 if is_low else (64.0 if is_high else 54.0))
	_apply_art21_panel_frame()


func _main_game_modal_rect(profile: Dictionary, y_shift: float = 0.0) -> Rect2:
	var viewport_size := UILayerContractScript.viewport_size_from_profile(profile)
	var width: float = maxf(1.0, viewport_size.x)
	var height: float = maxf(1.0, viewport_size.y)
	var margin: float = 18.0 if bool(profile.get("is_low_resolution", false)) else 24.0
	var left_width: float = min(UILayerContractScript.run_left_width(profile), width * 0.42)
	var gameplay_left: float = left_width + margin
	var gameplay_width: float = maxf(260.0, width - gameplay_left - margin)
	var modal_width: float = clampf(gameplay_width * 0.90, 520.0, 760.0)
	if modal_width > gameplay_width:
		modal_width = maxf(260.0, gameplay_width)
	var modal_height: float = clampf(height * 0.78, 390.0, 590.0)
	var bottom_reserve: float = 72.0 if bool(profile.get("is_low_resolution", false)) else 92.0
	modal_height = min(modal_height, maxf(300.0, height - margin * 2.0 - bottom_reserve))
	var x: float = gameplay_left + maxf(0.0, (gameplay_width - modal_width) * 0.5)
	var y: float = margin + maxf(0.0, (height - bottom_reserve - modal_height) * 0.45) + y_shift
	y = clampf(y, margin + 36.0, maxf(margin + 36.0, height - bottom_reserve - modal_height))
	return Rect2(x, y, modal_width, modal_height)


func _apply_art21_panel_frame() -> void:
	var texture := load("res://assets/art24/ui/modal_frame.png") as Texture2D
	if texture == null:
		texture = Art21UIPlacementContractScript.texture_for_slot(&"ground_loot", &"ground_loot_panel_frame", &"ui.art19.panel.terminal_main")
	if texture == null:
		Art10UISkinKitScript.apply_panel(self, &"modal")
		return
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 46
	style.texture_margin_top = 46
	style.texture_margin_right = 46
	style.texture_margin_bottom = 46
	style.content_margin_left = 24
	style.content_margin_top = 24
	style.content_margin_right = 24
	style.content_margin_bottom = 24
	style.draw_center = true
	add_theme_stylebox_override("panel", style)


func _add_item_row(item: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.name = "GroundLootItemRow"
	row.add_theme_constant_override("separation", 6)
	item_list.add_child(row)
	var item_button := Button.new()
	item_button.name = "GroundLootItemButton"
	item_button.focus_mode = Control.FOCUS_NONE
	item_button.text = RunUIViewModel.item_display_line(item)
	item_button.custom_minimum_size = item_button_minimum_size
	item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_button.clip_text = true
	item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_art09_item_icon(item_button, item)
	_apply_art21r2_modal_button(item_button, &"art21r2.modal.item_row.normal", &"secondary", 15, 10, 18)
	item_button.pressed.connect(func() -> void:
		tooltip_label.text = Art10UISkinKitScript.sanitize_player_copy(RunUIViewModel.item_tooltip(item))
		Art10UISkinKitScript.apply_label(tooltip_label, 15, Color(0.75, 0.82, 0.78, 1.0))
	)
	row.add_child(item_button)
	var pickup_button := Button.new()
	pickup_button.name = "GroundLootPickupButton"
	pickup_button.focus_mode = Control.FOCUS_NONE
	pickup_button.text = "拾取"
	pickup_button.custom_minimum_size = Vector2(72, item_button_minimum_size.y)
	pickup_button.tooltip_text = "拾取到背包；容量不足时保留在地面。"
	_apply_art21r2_modal_button(pickup_button, &"art21r2.modal.button.primary", &"primary", 14)
	var instance_id: String = String(item.get("instance_id", ""))
	pickup_button.pressed.connect(func() -> void: pickup_item_requested.emit(instance_id))
	row.add_child(pickup_button)
	var replace_button := Button.new()
	replace_button.name = "GroundLootReplaceButton"
	replace_button.focus_mode = Control.FOCUS_NONE
	replace_button.text = "替换"
	replace_button.custom_minimum_size = Vector2(72, item_button_minimum_size.y)
	replace_button.tooltip_text = "容量不足时，放下能够腾出空间的最低价值物品，再拾取此物。"
	_apply_art21r2_modal_button(replace_button, &"art21r2.modal.button.secondary", &"secondary", 14)
	replace_button.pressed.connect(func() -> void: replace_item_requested.emit(instance_id))
	row.add_child(replace_button)


func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


func _apply_art09_item_icon(button: Button, item: Dictionary) -> void:
	var asset_ref := PresentationMappingScript.inventory_item_icon_ref(item)
	var texture := Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
	if texture == null:
		return
	button.icon = texture
	Art10UISkinKitScript.controlled_button_icon(button, &"slot")


func _apply_art21r2_modal_panel(panel: PanelContainer, visual_key: StringName, padding: int = 8, texture_margin: int = 32) -> void:
	var style := StyleBoxFlat.new()
	var is_title := String(visual_key).find("title") >= 0
	style.bg_color = Color(0.018, 0.040, 0.043, 0.96) if is_title else Color(0.010, 0.027, 0.030, 0.88)
	style.border_color = Color(0.78, 0.55, 0.22, 0.90) if is_title else Color(0.18, 0.48, 0.45, 0.72)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	panel.add_theme_stylebox_override("panel", style)


func _apply_art21r2_modal_button(button: Button, visual_key: StringName, tone: StringName, font_size_value: int, padding: int = 8, texture_margin: int = 18) -> void:
	Art10UISkinKitScript.apply_button(button, tone, font_size_value)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.065, 0.068, 0.96)
	style.border_color = Color(0.22, 0.56, 0.51, 0.84)
	if tone == &"primary":
		style.border_color = Color(0.90, 0.68, 0.25, 0.94)
	elif tone == &"danger":
		style.border_color = Color(0.78, 0.30, 0.22, 0.94)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.05, 0.12, 0.12, 0.98)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("disabled", style.duplicate())
	button.add_theme_stylebox_override("focus", Art10UISkinKitScript.transparent_style_box(padding))
	button.add_theme_color_override("font_color", Color(0.92, 0.95, 0.88, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.54, 0.51, 1.0))
