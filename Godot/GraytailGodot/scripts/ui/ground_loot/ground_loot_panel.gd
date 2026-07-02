extends PanelContainer
class_name GroundLootPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const PresentationMappingScript := preload("res://scripts/presentation/presentation_mapping.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")

signal pickup_item_requested(instance_id: String)
signal replace_item_requested(instance_id: String)
signal close_requested

var title_label: Label
var summary_label: Label
var item_list: VBoxContainer
var tooltip_label: Label
var last_result_label: Label
var item_button_minimum_size: Vector2 = Vector2(380, 30)


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
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header := HBoxContainer.new()
	header.name = "GroundLootPanelHeader"
	root.add_child(header)
	title_label = Label.new()
	title_label.name = "GroundLootPanelTitle"
	title_label.text = "地面回收物"
	title_label.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
	title_label.add_theme_font_size_override("font_size", 20)
	Art10UISkinKitScript.apply_label(title_label, 20, PresentationTheme.color_for_key(&"ui.accent"))
	header.add_child(title_label)
	var close_button := Button.new()
	close_button.name = "GroundLootCloseButton"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.text = "关闭"
	Art10UISkinKitScript.apply_button(close_button, &"secondary", 13)
	close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close_button)

	summary_label = Label.new()
	summary_label.name = "GroundLootSummary"
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_font_size_override("font_size", 13)
	summary_label.add_theme_constant_override("line_spacing", 2)
	root.add_child(summary_label)

	item_list = VBoxContainer.new()
	item_list.name = "GroundLootItemList"
	item_list.custom_minimum_size = Vector2(500, 210)
	root.add_child(item_list)

	tooltip_label = Label.new()
	tooltip_label.name = "GroundLootItemTooltip"
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.custom_minimum_size = Vector2(500, 120)
	tooltip_label.add_theme_font_size_override("font_size", 13)
	tooltip_label.add_theme_constant_override("line_spacing", 2)
	root.add_child(tooltip_label)

	last_result_label = Label.new()
	last_result_label.name = "GroundLootCommandResult"
	last_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(last_result_label)


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
	Art10UISkinKitScript.apply_label(summary_label, 13, PresentationTheme.text_color())
	for child in item_list.get_children():
		child.queue_free()
	if ground_items.is_empty():
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_constant_override("line_spacing", 2)
		empty_label.text = "当前房间没有地面回收物。搜索、物资箱、异常体或事件奖励可能把物品留在地面。"
		Art10UISkinKitScript.apply_label(empty_label, 13, PresentationTheme.text_color())
		item_list.add_child(empty_label)
	else:
		for item: Dictionary in ground_items:
			_add_item_row(item)
	if tooltip_label != null:
		tooltip_label.text = "选择物品查看效果；拾取会检查背包容量，容量不足时物品保留在地面。"
		Art10UISkinKitScript.apply_label(tooltip_label, 13, PresentationTheme.color_for_key(&"ui.muted"))


func show_command_result(result: Dictionary) -> void:
	if last_result_label == null:
		return
	last_result_label.text = Art10UISkinKitScript.sanitize_player_copy(RunUIViewModel.command_result_text(result))
	Art10UISkinKitScript.apply_label(last_result_label, 13, PresentationTheme.color_for_key(&"ui.accent"))
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
	var profile_id: StringName = StringName(profile.get("profile_id", &"desktop"))
	if profile_id == &"narrow" or is_low:
		offset_left = 20.0
		offset_top = 88.0
		offset_right = 600.0
		offset_bottom = 650.0
		item_button_minimum_size = Vector2(360, 30)
		if item_list != null:
			item_list.custom_minimum_size = Vector2(500, 190)
		if tooltip_label != null:
			tooltip_label.custom_minimum_size = Vector2(500, 104)
	elif is_high:
		offset_left = 350.0
		offset_top = 98.0
		offset_right = 970.0
		offset_bottom = 636.0
		item_button_minimum_size = Vector2(430, 34)
		if item_list != null:
			item_list.custom_minimum_size = Vector2(560, 236)
		if tooltip_label != null:
			tooltip_label.custom_minimum_size = Vector2(560, 138)
	else:
		offset_left = 390.0
		offset_top = 116.0
		offset_right = 930.0
		offset_bottom = 610.0
		item_button_minimum_size = Vector2(380, 30)
		if item_list != null:
			item_list.custom_minimum_size = Vector2(500, 210)
		if tooltip_label != null:
			tooltip_label.custom_minimum_size = Vector2(500, 120)
	_apply_art21_panel_frame()


func _apply_art21_panel_frame() -> void:
	var texture := Art21UIPlacementContractScript.texture_for_slot(&"ground_loot", &"ground_loot_panel_frame", &"ui.art19.panel.terminal_main")
	if texture == null:
		Art10UISkinKitScript.apply_panel(self, &"modal")
		return
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 28
	style.texture_margin_top = 28
	style.texture_margin_right = 28
	style.texture_margin_bottom = 28
	style.content_margin_left = 18
	style.content_margin_top = 18
	style.content_margin_right = 18
	style.content_margin_bottom = 18
	style.draw_center = true
	add_theme_stylebox_override("panel", style)


func _add_item_row(item: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.name = "GroundLootItemRow"
	item_list.add_child(row)
	var item_button := Button.new()
	item_button.name = "GroundLootItemButton"
	item_button.focus_mode = Control.FOCUS_NONE
	item_button.text = RunUIViewModel.item_display_line(item)
	item_button.custom_minimum_size = item_button_minimum_size
	_apply_art09_item_icon(item_button, item)
	Art10UISkinKitScript.apply_button(item_button, &"secondary", 13)
	item_button.pressed.connect(func() -> void:
		tooltip_label.text = Art10UISkinKitScript.sanitize_player_copy(RunUIViewModel.item_tooltip(item))
		Art10UISkinKitScript.apply_label(tooltip_label, 13, PresentationTheme.color_for_key(&"ui.muted"))
	)
	row.add_child(item_button)
	var pickup_button := Button.new()
	pickup_button.name = "GroundLootPickupButton"
	pickup_button.focus_mode = Control.FOCUS_NONE
	pickup_button.text = "拾取"
	pickup_button.tooltip_text = "拾取到背包；容量不足时保留在地面。"
	Art10UISkinKitScript.apply_button(pickup_button, &"primary", 13)
	var instance_id: String = String(item.get("instance_id", ""))
	pickup_button.pressed.connect(func() -> void: pickup_item_requested.emit(instance_id))
	row.add_child(pickup_button)
	var replace_button := Button.new()
	replace_button.name = "GroundLootReplaceButton"
	replace_button.focus_mode = Control.FOCUS_NONE
	replace_button.text = "Replace"
	replace_button.tooltip_text = "Drop the lowest-value backpack item that makes room, then pick up this floor item."
	Art10UISkinKitScript.apply_button(replace_button, &"secondary", 13)
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
