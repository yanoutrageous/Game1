extends PanelContainer
class_name GroundLootPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const PresentationMappingScript := preload("res://scripts/presentation/presentation_mapping.gd")
const Art24ItemVisualCatalogScript := preload("res://scripts/presentation/art24/art24_item_visual_catalog.gd")
const ItemRarityDescriptorScript := preload("res://scripts/presentation/item_rarity_descriptor.gd")
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
var detail_column: VBoxContainer
var detail_scroll: ScrollContainer
var tooltip_label: Label
var last_result_label: Label
var close_button: Button
var first_item_button: Button
var item_button_minimum_size: Vector2 = Vector2(360, 52)
var _ui_scale_factor := 1.0
var _last_layout_profile: Dictionary = {}


func _ready() -> void:
	_ui_scale_factor = Art10UISkinKitScript.runtime_ui_scale_factor()
	build()


func build() -> void:
	name = "GroundLootPanel"
	Art10UISkinKitScript.apply_player_ui_theme(self)
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
	Art10UISkinKitScript.apply_composition_label(title_label, &"title", 20, PresentationTheme.color_for_key(&"ui.accent"))
	header.add_child(title_label)
	close_button = Button.new()
	close_button.name = "GroundLootCloseButton"
	close_button.focus_mode = Control.FOCUS_ALL
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
	detail_column = VBoxContainer.new()
	detail_column.name = "GroundLootDetailColumn"
	detail_column.add_theme_constant_override("separation", 5)
	tooltip_panel.add_child(detail_column)
	detail_scroll = ScrollContainer.new()
	detail_scroll.name = "GroundLootItemDetailScroll"
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.custom_minimum_size.y = 112.0
	detail_column.add_child(detail_scroll)
	tooltip_label = Label.new()
	tooltip_label.name = "GroundLootItemTooltip"
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.clip_text = false
	tooltip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_label.custom_minimum_size = Vector2(500, 54)
	tooltip_label.add_theme_font_size_override("font_size", 15)
	tooltip_label.add_theme_constant_override("line_spacing", 2)
	detail_scroll.add_child(tooltip_label)

	last_result_label = Label.new()
	last_result_label.name = "GroundLootCommandResult"
	last_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	last_result_label.clip_text = false
	last_result_label.custom_minimum_size = Vector2(0, 22)
	last_result_label.add_theme_font_size_override("font_size", 14)
	last_result_label.hide()
	detail_column.add_child(last_result_label)
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
	_set_scaled_font(summary_label, 15)
	for child in item_list.get_children():
		child.queue_free()
	first_item_button = null
	if ground_items.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.custom_minimum_size = Vector2(0, 96)
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_constant_override("line_spacing", 2)
		empty_label.text = "附近没有可拾取物资。"
		Art10UISkinKitScript.apply_label(empty_label, 15, PresentationTheme.text_color())
		_set_scaled_font(empty_label, 15)
		item_list.add_child(empty_label)
	else:
		for item: Dictionary in ground_items:
			_add_item_row(item)
	if tooltip_label != null:
		tooltip_label.text = "聚焦任一物品即可查看名称、品质、重量、数量与说明。"
		Art10UISkinKitScript.apply_label(tooltip_label, 15, Color(0.75, 0.82, 0.78, 1.0))
		_set_scaled_font(tooltip_label, 15)


func show_command_result(result: Dictionary) -> void:
	if last_result_label == null:
		return
	last_result_label.text = _command_result_text(result)
	last_result_label.visible = last_result_label.text.strip_edges() != ""
	Art10UISkinKitScript.apply_label(last_result_label, 14, PresentationTheme.color_for_key(&"ui.accent"))
	_set_scaled_font(last_result_label, 14)
	var pulse_state := &"ready"
	if not bool(result.get("accepted", result.get("ok", false))):
		pulse_state = &"warning"
	Art10UISkinKitScript.play_feedback_pulse(last_result_label, pulse_state)


func show_panel() -> void:
	visible = true
	Art10UISkinKitScript.play_panel_open(self)
	call_deferred("_grab_preferred_focus_if_valid")


func _grab_preferred_focus_if_valid() -> void:
	if not visible:
		return
	var target := preferred_focus_control()
	if (
		target != null
		and is_instance_valid(target)
		and not target.is_queued_for_deletion()
		and target.is_inside_tree()
		and target.is_visible_in_tree()
		and target.focus_mode != Control.FOCUS_NONE
	):
		target.grab_focus()


func hide_panel() -> void:
	visible = false
	get_viewport().gui_release_focus()


func preferred_focus_control() -> Control:
	if first_item_button != null and is_instance_valid(first_item_button) and not first_item_button.is_queued_for_deletion():
		return first_item_button
	return close_button


func apply_layout_profile(profile: Dictionary) -> void:
	_last_layout_profile = profile.duplicate(true)
	_ui_scale_factor = Art10UISkinKitScript.normalize_runtime_ui_scale_factor(
		float(profile.get("ui_scale_factor", _ui_scale_factor))
	)
	var is_low := bool(profile.get("is_low_resolution", false))
	var is_high := bool(profile.get("is_high_resolution", false))
	var rect := _main_game_modal_rect(profile, 10.0)
	offset_left = rect.position.x
	offset_top = rect.position.y
	offset_right = rect.position.x + rect.size.x
	offset_bottom = rect.position.y + rect.size.y
	var content_width: float = max(280.0, rect.size.x - 96.0)
	item_button_minimum_size = Vector2(
		max(210.0, content_width - (166.0 if is_low else 184.0)),
		Art10UISkinKitScript.scaled_control_minimum(
			Vector2(0.0, 46.0 if is_low else (56.0 if is_high else 52.0)),
			minf(_ui_scale_factor, 1.25)
		).y
	)
	if item_scroll != null:
		item_scroll.custom_minimum_size = Vector2(content_width, 132.0 if is_low else (224.0 if is_high else 184.0))
	if tooltip_label != null:
		tooltip_label.custom_minimum_size = Vector2(content_width, 48.0 if is_low else (64.0 if is_high else 54.0))
	if detail_scroll != null:
		detail_scroll.custom_minimum_size = Vector2(content_width, 54.0 if is_low else (82.0 if is_high else 68.0))
	_apply_art21_panel_frame()
	_refresh_ui_scale_metrics()


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
	var style := Art10UISkinKitScript.style_box_from_texture_with_insets(
		texture,
		Vector4(18.0, 18.0, 18.0, 18.0),
		Vector4(46.0, 46.0, 46.0, 46.0)
	)
	add_theme_stylebox_override("panel", style)


func _add_item_row(item: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.name = "GroundLootItemRow"
	row.add_theme_constant_override("separation", 6)
	item_list.add_child(row)
	var item_button := Button.new()
	item_button.name = "GroundLootItemButton"
	item_button.focus_mode = Control.FOCUS_ALL
	item_button.text = _item_summary_text(item)
	item_button.custom_minimum_size = item_button_minimum_size
	item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_button.clip_text = true
	item_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_art09_item_icon(item_button, item)
	_apply_art21r2_modal_button(item_button, &"art21r2.modal.item_row.normal", &"secondary", 15, 10, 18)
	_apply_rarity_row_style(item_button, item)
	var show_detail := func() -> void: _show_item_detail(item)
	item_button.pressed.connect(show_detail)
	item_button.mouse_entered.connect(show_detail)
	item_button.focus_entered.connect(show_detail)
	item_button.tooltip_text = _item_detail_text(item)
	if first_item_button == null:
		first_item_button = item_button
	row.add_child(item_button)
	var pickup_button := Button.new()
	pickup_button.name = "GroundLootPickupButton"
	pickup_button.focus_mode = Control.FOCUS_ALL
	pickup_button.text = "拾取"
	pickup_button.custom_minimum_size = Vector2(
		Art10UISkinKitScript.scaled_control_minimum(Vector2(72, 0), minf(_ui_scale_factor, 1.25)).x,
		item_button_minimum_size.y
	)
	pickup_button.tooltip_text = "拾取到背包；容量不足时保留在地面。"
	_apply_art21r2_modal_button(pickup_button, &"art21r2.modal.button.primary", &"primary", 14)
	var instance_id: String = String(item.get("instance_id", ""))
	pickup_button.pressed.connect(func() -> void: pickup_item_requested.emit(instance_id))
	pickup_button.mouse_entered.connect(show_detail)
	pickup_button.focus_entered.connect(show_detail)
	row.add_child(pickup_button)
	var replace_button := Button.new()
	replace_button.name = "GroundLootReplaceButton"
	replace_button.focus_mode = Control.FOCUS_ALL
	replace_button.text = "替换"
	replace_button.custom_minimum_size = Vector2(
		Art10UISkinKitScript.scaled_control_minimum(Vector2(72, 0), minf(_ui_scale_factor, 1.25)).x,
		item_button_minimum_size.y
	)
	replace_button.tooltip_text = "容量不足时，放下能够腾出空间的最低价值物品，再拾取此物。"
	_apply_art21r2_modal_button(replace_button, &"art21r2.modal.button.secondary", &"secondary", 14)
	replace_button.pressed.connect(func() -> void: replace_item_requested.emit(instance_id))
	replace_button.mouse_entered.connect(show_detail)
	replace_button.focus_entered.connect(show_detail)
	row.add_child(replace_button)


func _show_item_detail(item: Dictionary) -> void:
	if tooltip_label == null:
		return
	tooltip_label.text = _item_detail_text(item)
	Art10UISkinKitScript.apply_label(tooltip_label, 15, Color(0.86, 0.90, 0.84, 1.0))
	_set_scaled_font(tooltip_label, 15)
	if detail_scroll != null:
		detail_scroll.scroll_vertical = 0


func _item_summary_text(item: Dictionary) -> String:
	return String(RunUIViewModel.item_presentation(item).get("summary_text", "暂无物资"))


func _item_detail_text(item: Dictionary) -> String:
	return Art10UISkinKitScript.sanitize_player_copy(
		String(RunUIViewModel.item_presentation(item).get("detail_text", "尚未选择物品。"))
	)


func _command_result_text(result: Dictionary) -> String:
	if result.is_empty():
		return ""
	var accepted := bool(result.get("accepted", result.get("ok", false)))
	if not accepted:
		var blocked := RunUIViewModel.command_result_text(result).replace("操作受阻：", "无法执行：")
		return Art10UISkinKitScript.sanitize_player_copy(blocked)
	var message := String(result.get("message", "")).strip_edges()
	if message != "":
		return Art10UISkinKitScript.sanitize_player_copy(RunUIViewModel.player_message(message))
	return "附近物资已更新。"


func _apply_rarity_row_style(button: Button, item: Dictionary) -> void:
	var descriptor: Dictionary = ItemRarityDescriptorScript.describe_item(item)
	var rarity_color: Color = descriptor.get("color", Color(0.64, 0.72, 0.68, 1.0))
	button.set_meta("rarity_border_token", StringName(descriptor.get("border_token", &"rarity.unknown")))
	button.set_meta("rarity_display_text", String(descriptor.get("display_text", "[?] 未鉴定")))
	var marker := ColorRect.new()
	marker.name = "GroundLootItemRarityMarker"
	marker.color = rarity_color
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.z_index = 2
	marker.anchor_top = 0.0
	marker.anchor_bottom = 1.0
	marker.offset_left = 7.0
	marker.offset_top = 8.0
	marker.offset_right = 12.0
	marker.offset_bottom = -8.0
	marker.set_meta("rarity_border_token", button.get_meta("rarity_border_token"))
	button.add_child(marker)


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
	var texture := Art21UIPlacementContractScript.texture_for_visual_key(visual_key, &"ui.art19.panel.terminal_main")
	var content_insets := Vector4(40.0, 16.0, 18.0, 14.0)
	if String(visual_key).contains("title"):
		content_insets = Vector4(28.0, 18.0, 28.0, 18.0)
	var slice := float(maxi(texture_margin, padding))
	var style := Art10UISkinKitScript.style_box_from_texture_with_insets(
		texture,
		content_insets,
		Vector4(slice, slice, slice, slice)
	)
	if style != null:
		panel.add_theme_stylebox_override("panel", style)
		return
	var is_title := String(visual_key).find("title") >= 0
	Art10UISkinKitScript.apply_panel(panel, &"notice" if is_title else &"deep")


func _apply_art21r2_modal_button(button: Button, visual_key: StringName, tone: StringName, font_size_value: int, padding: int = 8, texture_margin: int = 18) -> void:
	var font_role := &"readable" if visual_key == &"art21r2.modal.item_row.normal" else &"display"
	Art10UISkinKitScript.apply_button(
		button,
		tone,
		Art10UISkinKitScript.scaled_font_size(font_size_value, _ui_scale_factor),
		&"button",
		font_role
	)
	button.set_meta("ui_scale_base_font_size", font_size_value)
	var style := Art21UIPlacementContractScript.style_box_for_visual_key(visual_key, &"ui.art19.button.dark", padding, texture_margin)
	if style != null:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			button.add_theme_stylebox_override(state, style.duplicate() as StyleBoxTexture)
	button.add_theme_color_override("font_color", Color(0.92, 0.95, 0.88, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.54, 0.51, 1.0))


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
			_set_scaled_font(title_label, 20)
		if close_button != null:
			_set_scaled_font(close_button, 15)
			_set_scaled_minimum(close_button, Vector2(76, 34))
		if summary_label != null:
			_set_scaled_font(summary_label, 15)
		if tooltip_label != null:
			_set_scaled_font(tooltip_label, 15)
		if last_result_label != null:
			_set_scaled_font(last_result_label, 14)
	for child in node.get_children():
		_refresh_ui_scale_metrics(child)
