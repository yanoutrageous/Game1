extends PanelContainer
class_name InventoryPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const PresentationMappingScript := preload("res://scripts/presentation/presentation_mapping.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const Art24ItemVisualCatalogScript := preload("res://scripts/presentation/art24/art24_item_visual_catalog.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")

signal drop_item_requested(instance_id: String)
signal use_item_requested(instance_id: String)
signal close_requested

var title_label: Label
var summary_label: Label
var item_list: VBoxContainer
var item_scroll: ScrollContainer
var item_backdrop: TextureRect
var tooltip_label: Label
var last_result_label: Label
var item_button_minimum_size: Vector2 = Vector2(360, 52)


func _ready() -> void:
	build()


func build() -> void:
	name = "InventoryPanel"
	visible = false
	offset_left = 390.0
	offset_top = 98.0
	offset_right = 930.0
	offset_bottom = 610.0
	_apply_art21_panel_frame()
	if get_child_count() > 0:
		return
	var root := VBoxContainer.new()
	root.name = "InventoryPanelContent"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var header_panel := PanelContainer.new()
	header_panel.name = "InventoryTitlePlate"
	_apply_art21r2_modal_panel(header_panel, &"art21r2.modal.title_plate", 8, 34)
	root.add_child(header_panel)
	var header := HBoxContainer.new()
	header.name = "InventoryPanelHeader"
	header.add_theme_constant_override("separation", 8)
	header_panel.add_child(header)
	title_label = Label.new()
	title_label.name = "InventoryPanelTitle"
	title_label.text = "回收背包"
	title_label.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Art10UISkinKitScript.apply_label(title_label, 20, PresentationTheme.color_for_key(&"ui.accent"))
	header.add_child(title_label)
	var close_button := Button.new()
	close_button.name = "InventoryCloseButton"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(76, 34)
	_apply_art21r2_modal_button(close_button, &"art21r2.modal.button.secondary", &"secondary", 15)
	close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close_button)

	var summary_panel := PanelContainer.new()
	summary_panel.name = "InventorySummaryPanel"
	_apply_art21r2_modal_panel(summary_panel, &"art21r2.modal.section.panel", 8, 32)
	root.add_child(summary_panel)
	summary_label = Label.new()
	summary_label.name = "InventorySummary"
	summary_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	summary_label.clip_text = true
	summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_label.custom_minimum_size = Vector2(0, 44)
	summary_label.add_theme_font_size_override("font_size", 15)
	summary_label.add_theme_constant_override("line_spacing", 2)
	summary_panel.add_child(summary_label)

	var item_list_panel := PanelContainer.new()
	item_list_panel.name = "InventoryItemListPanel"
	item_list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_art21r2_modal_panel(item_list_panel, &"art21r2.modal.section.panel", 8, 32)
	root.add_child(item_list_panel)
	item_backdrop = TextureRect.new()
	item_backdrop.name = "InventoryBackpackWatermark"
	item_backdrop.texture = load("res://assets/art24/ui/ue/ui_icon_backpack.png") as Texture2D
	item_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_backdrop.modulate = Color(0.72, 0.96, 0.91, 0.12)
	item_list_panel.add_child(item_backdrop)
	item_scroll = ScrollContainer.new()
	item_scroll.name = "InventoryItemScroll"
	item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	item_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	item_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list_panel.add_child(item_scroll)
	item_list = VBoxContainer.new()
	item_list.name = "InventoryItemList"
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 5)
	item_scroll.add_child(item_list)

	var tooltip_panel := PanelContainer.new()
	tooltip_panel.name = "InventoryTooltipPanel"
	_apply_art21r2_modal_panel(tooltip_panel, &"art21r2.modal.section.panel", 8, 32)
	root.add_child(tooltip_panel)
	tooltip_label = Label.new()
	tooltip_label.name = "InventoryItemTooltip"
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	tooltip_label.clip_text = true
	tooltip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_label.custom_minimum_size = Vector2(500, 54)
	tooltip_label.add_theme_font_size_override("font_size", 15)
	tooltip_label.add_theme_constant_override("line_spacing", 2)
	tooltip_panel.add_child(tooltip_label)

	var result_panel := PanelContainer.new()
	result_panel.name = "InventoryCommandResultPanel"
	_apply_art21r2_modal_panel(result_panel, &"art21r2.modal.section.panel", 8, 32)
	root.add_child(result_panel)
	last_result_label = Label.new()
	last_result_label.name = "InventoryCommandResult"
	last_result_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	last_result_label.clip_text = true
	last_result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	last_result_label.custom_minimum_size = Vector2(0, 22)
	last_result_label.add_theme_font_size_override("font_size", 14)
	result_panel.add_child(last_result_label)


func apply_snapshot(snapshot: Dictionary) -> void:
	if summary_label == null:
		build()
	var inventory_items: Array = _array_from(snapshot, "inventory_items")
	var equipped_items: Array = _array_from(snapshot, "equipped_items")
	if item_backdrop != null:
		var visible_item_count := inventory_items.size() + equipped_items.size()
		item_backdrop.visible = item_backdrop.texture != null and visible_item_count < 6
		var watermark_alpha := 0.12 if visible_item_count == 0 else (0.075 if visible_item_count <= 2 else 0.04)
		item_backdrop.modulate = Color(0.72, 0.96, 0.91, watermark_alpha)
	summary_label.text = "背包 %s/%s　黑色资源 %s　金色资源 %s\n物品 %s　装备 %s" % [
		snapshot.get("backpack_used", 0),
		snapshot.get("backpack_capacity", 0),
		snapshot.get("run_black_coin", snapshot.get("black_coin", 0)),
		snapshot.get("gold_coin", snapshot.get("safe_yield", 0)),
		inventory_items.size(),
		equipped_items.size(),
	]
	Art10UISkinKitScript.apply_label(summary_label, 15, PresentationTheme.text_color())
	for child in item_list.get_children():
		child.queue_free()
	if inventory_items.is_empty() and equipped_items.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		empty_label.clip_text = true
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_label.custom_minimum_size = Vector2(0, 72)
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_constant_override("line_spacing", 2)
		empty_label.text = "背包为空。\n搜索、物资箱或事件可能获得物品。\n空间不足时物品会留在地面。"
		Art10UISkinKitScript.apply_label(empty_label, 15, PresentationTheme.text_color())
		item_list.add_child(empty_label)
	else:
		for item: Dictionary in inventory_items:
			_add_item_row(item, true)
		for item: Dictionary in equipped_items:
			_add_item_row(item, false)
	if tooltip_label != null:
		tooltip_label.text = "选择物品查看效果。\n背包物品可丢弃；消耗品可直接使用。"
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
	var rect := _main_game_modal_rect(profile, 0.0)
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
	var is_low := bool(profile.get("is_low_resolution", false))
	var is_high := bool(profile.get("is_high_resolution", false))
	var margin: float = 18.0 if is_low else 24.0
	var left_width: float = min(UILayerContractScript.run_left_width(profile), width * 0.42)
	var gameplay_left: float = left_width + margin
	var gameplay_width: float = maxf(260.0, width - gameplay_left - margin)
	# UE keeps inventory authority in the left rail. The expanded Godot view adds
	# item actions that UE does not have, so present it as a field-bag drawer next
	# to that rail instead of a generic modal covering almost the entire room.
	var modal_min_width := 500.0 if is_low else 540.0
	var modal_max_width := 620.0 if is_low else (760.0 if is_high else 680.0)
	var modal_width: float = clampf(gameplay_width * 0.58, modal_min_width, modal_max_width)
	if modal_width > gameplay_width:
		modal_width = maxf(260.0, gameplay_width)
	var modal_height: float = clampf(height * 0.65, 420.0 if is_low else 460.0, 480.0 if is_low else (580.0 if is_high else 540.0))
	var bottom_reserve: float = 72.0 if is_low else 92.0
	modal_height = min(modal_height, maxf(300.0, height - margin * 2.0 - bottom_reserve))
	var x: float = gameplay_left
	var y: float = margin + maxf(0.0, (height - bottom_reserve - modal_height) * 0.45) + y_shift
	y = clampf(y, margin + 36.0, maxf(margin + 36.0, height - bottom_reserve - modal_height))
	return Rect2(x, y, modal_width, modal_height)


func _apply_art21_panel_frame() -> void:
	var texture := load("res://assets/art24/ui/modal_frame.png") as Texture2D
	if texture == null:
		texture = Art21UIPlacementContractScript.texture_for_slot(&"inventory", &"inventory_panel_frame", &"ui.art19.panel.terminal_main")
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


func _add_item_row(item: Dictionary, can_drop: bool) -> void:
	var row := HBoxContainer.new()
	row.name = "InventoryItemRow"
	row.add_theme_constant_override("separation", 6)
	item_list.add_child(row)
	var item_button := Button.new()
	item_button.name = "InventoryItemButton"
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
	var drop_button := Button.new()
	drop_button.name = "InventoryDropButton"
	drop_button.focus_mode = Control.FOCUS_NONE
	drop_button.text = "丢弃"
	drop_button.custom_minimum_size = Vector2(72, item_button_minimum_size.y)
	drop_button.disabled = not can_drop
	drop_button.tooltip_text = "丢弃到当前房间地面，稍后可从地面物品重新拾取。" if can_drop else "已装备物品暂不可从此面板丢弃。"
	_apply_art21r2_modal_button(drop_button, &"art21r2.modal.button.danger" if can_drop else &"art21r2.modal.button.secondary", &"danger" if can_drop else &"secondary", 14)
	var instance_id: String = String(item.get("instance_id", ""))
	var use_button := Button.new()
	use_button.name = "InventoryUseButton"
	use_button.focus_mode = Control.FOCUS_NONE
	use_button.text = "使用"
	use_button.custom_minimum_size = Vector2(72, item_button_minimum_size.y)
	var can_use := can_drop and bool(item.get("can_consume", false))
	use_button.disabled = not can_use
	use_button.tooltip_text = "使用当前消耗品。" if can_use else "只有背包中的消耗品可使用。"
	_apply_art21r2_modal_button(use_button, &"art21r2.modal.button.primary" if can_use else &"art21r2.modal.button.secondary", &"primary" if can_use else &"secondary", 14)
	use_button.pressed.connect(func() -> void: use_item_requested.emit(instance_id))
	row.add_child(use_button)
	drop_button.pressed.connect(func() -> void: drop_item_requested.emit(instance_id))
	row.add_child(drop_button)


func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


func _apply_art09_item_icon(button: Button, item: Dictionary) -> void:
	var texture := Art24ItemVisualCatalogScript.texture_for(item)
	if texture == null:
		var asset_ref := PresentationMappingScript.inventory_item_icon_ref(item)
		texture = Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
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
