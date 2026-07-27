extends Control
class_name DeployPrepCardView

const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art22DeployPrepAssetContractScript := preload("res://scripts/presentation/art22_deploy_prep_asset_contract.gd")
const Art25ContentAssetContractScript := preload("res://scripts/presentation/art25_content_asset_contract.gd")
const ItemRarityDescriptorScript := preload("res://scripts/presentation/item_rarity_descriptor.gd")

signal card_pressed(card_id: StringName)

var card_id: StringName = &""
var card_data: Dictionary = {}
var selected := false
var button: Button
var artwork: TextureRect
var title_label: Label
var summary_label: Label
var state_label: Label
var state_panel: Panel
var state_hint_label: Label
var batch_selection_active := false
var batch_checked := false
var batch_eligible := false
var batch_reason := ""
var ui_scale_factor := 1.0


func setup(card: Dictionary, tab_id: StringName, is_selected: bool) -> void:
	card_data = card.duplicate(true)
	card_id = StringName(card_data.get("id", &""))
	selected = is_selected
	ui_scale_factor = Art10UISkinKitScript.runtime_ui_scale_factor()
	set_meta("runtime_ui_scale_factor", ui_scale_factor)
	custom_minimum_size = Vector2(232, 76)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_nodes(tab_id)
	apply_selected(is_selected)
	_refresh_ui_scale_metrics()


func set_ui_scale_factor(value: float) -> void:
	ui_scale_factor = Art10UISkinKitScript.normalize_runtime_ui_scale_factor(value)
	set_meta("runtime_ui_scale_factor", ui_scale_factor)
	_refresh_ui_scale_metrics()


func get_ui_scale_factor() -> float:
	return ui_scale_factor


func apply_selected(value: bool) -> void:
	selected = value
	if button == null:
		return
	var state := StringName(card_data.get("state", &"normal"))
	var normal_state := &"selected" if selected else _card_surface_state(state)
	button.add_theme_stylebox_override("normal", _style(normal_state))
	button.add_theme_stylebox_override("hover", _style(&"focused"))
	button.add_theme_stylebox_override("focus", _style(&"focused"))
	button.add_theme_stylebox_override("pressed", _style(&"pressed"))
	button.add_theme_stylebox_override("hover_pressed", _style(&"pressed"))
	button.tooltip_text = Art10UISkinKitScript.sanitize_player_copy(String(card_data.get("detail", card_data.get("description", ""))))
	if title_label != null:
		title_label.modulate = Color(1.08, 1.03, 0.90, 1.0) if selected else Color.WHITE
	if state_label != null:
		state_label.text = _display_state(state)
	if state_hint_label != null:
		state_hint_label.text = _state_hint()
	if batch_selection_active:
		_apply_batch_selection_visual()


func apply_batch_selection(active: bool, checked: bool, eligible: bool, reason: String = "") -> void:
	batch_selection_active = active
	batch_checked = checked
	batch_eligible = eligible
	batch_reason = reason
	if not batch_selection_active:
		apply_selected(selected)
		return
	_apply_batch_selection_visual()


func grab_card_focus() -> void:
	if button != null and not button.disabled:
		button.grab_focus()


func focus_button() -> Button:
	return button


func _apply_batch_selection_visual() -> void:
	if button == null:
		return
	var surface := &"selected" if batch_checked else (&"normal" if batch_eligible else &"locked")
	button.add_theme_stylebox_override("normal", _style(surface))
	button.add_theme_stylebox_override("hover", _style(&"focused"))
	button.add_theme_stylebox_override("focus", _style(&"focused"))
	button.add_theme_stylebox_override("pressed", _style(&"pressed"))
	button.add_theme_stylebox_override("hover_pressed", _style(&"pressed"))
	button.tooltip_text = "点击取消勾选" if batch_checked else ("点击加入批量售卖" if batch_eligible else batch_reason)
	if title_label != null:
		title_label.modulate = Color(1.10, 1.04, 0.78, 1.0) if batch_checked else Color.WHITE
	if state_label != null:
		state_label.text = "✓ 已勾选" if batch_checked else ("□ 可售" if batch_eligible else "不可售")


func _build_nodes(tab_id: StringName) -> void:
	button = Button.new()
	button.name = "CardHitTarget"
	button.text = ""
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = Art10UISkinKitScript.sanitize_player_copy(String(card_data.get("detail", card_data.get("description", ""))))
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(func() -> void: card_pressed.emit(card_id))
	add_child(button)

	var rarity_edge := _add_color_rect("CardRarityEdge", Rect2(2, 5, 3, 66), _rarity_color())
	rarity_edge.set_meta("rarity_border_token", _rarity_descriptor().get("border_token", &"rarity.border.unknown"))
	_add_color_rect("CardContentMatte", Rect2(68, 7, 156, 62), Color(0.015, 0.055, 0.060, 0.38))
	_add_asset_panel("CardArtworkFrame", Rect2(7, 8, 56, 60), &"slot", &"normal")
	var art_filter_id := StringName(card_data.get("art_filter_id", card_data.get("filter_id", &"")))
	var art_ref := Art09ManifestAssetMappingScript.inventory_item_icon_ref(card_data) if card_data.has("item_id") else (Art25ContentAssetContractScript.deploy_card_ref(card_id) if Art25ContentAssetContractScript.handles_deploy_card(card_id) else Art22DeployPrepAssetContractScript.card_art_ref(tab_id, card_id, art_filter_id))
	artwork = TextureRect.new()
	artwork.name = "CardArtwork"
	artwork.texture = Art09ManifestAssetMappingScript.resolve_texture(art_ref)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_rect := Rect2(11, 12, 48, 52)
	_set_rect(artwork, art_rect)
	add_child(artwork)

	title_label = _add_label("CardTitle", Rect2(72, 8, 148, 23), _display_title(), 15, Color(0.96, 0.86, 0.63), HORIZONTAL_ALIGNMENT_LEFT)
	title_label.clip_text = true
	summary_label = _add_label("CardSummary", Rect2(72, 31, 148, 18), _summary_text(), 11, Color(0.76, 0.82, 0.76), HORIZONTAL_ALIGNMENT_LEFT)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	summary_label.clip_text = true
	_add_chip("CardCategoryChip", Rect2(72, 51, 70, 18), _category_chip_text())
	_add_chip("CardModeChip", Rect2(146, 51, 74, 18), _mode_chip_text())
	state_panel = _add_asset_panel("CardStatePanel", Rect2(7, 49, 56, 19), &"slot", &"normal")
	state_label = _add_label("CardState", Rect2(9, 50, 52, 17), "", 10, Color(0.42, 0.92, 0.86), HORIZONTAL_ALIGNMENT_CENTER)
	state_label.clip_text = true
	state_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	state_hint_label = null


func _display_title() -> String:
	match card_id:
		&"m3r_loadout_equipment": return "已选装备"
		&"m3r_loadout_consumables": return "携带消耗品"
		&"m3r_loadout_capacity": return "背包容量"
		&"m3r_profile_permission_protocol": return "档案 / 许可 / 协议"
		&"m3r_start_intent": return "开始常规探索"
		&"m3r_warehouse_status": return "仓库状态"
	return Art10UISkinKitScript.short_summary(String(card_data.get("title", "未命名项目")), 14)


func _summary_text() -> String:
	match card_id:
		&"m3r_loadout_equipment": return "已从真实仓库配置本次探索装备。"
		&"m3r_loadout_consumables": return "携带补给进入背包，未使用物按结果结算。"
		&"m3r_loadout_capacity": return "显示携带重量、背包上限与失败回收容量。"
		&"m3r_profile_permission_protocol": return "展示当前档案、许可等级与协议难度接口。"
		&"m3r_start_intent": return "使用当前地图、目标与携带配置进入现有路线。"
		&"m3r_warehouse_status": return "汇总真实仓库的装备、消耗品、藏品与特殊物。"
	var text := Art10UISkinKitScript.sanitize_player_copy(String(card_data.get("secondary", card_data.get("summary", ""))))
	if text.is_empty():
		text = Art10UISkinKitScript.sanitize_player_copy(String(card_data.get("detail", "")))
	return Art10UISkinKitScript.short_summary(text, 18)


func _mode_chip_text() -> String:
	if card_data.has("rarity"):
		var rarity := _rarity_descriptor()
		var badge := String(rarity.get("badge", "?"))
		var label := "锁定" if bool(rarity.get("locked", false)) else String(rarity.get("label", "未鉴定"))
		return Art10UISkinKitScript.short_summary("%s %s" % [badge, label], 7)
	var locked := String(card_data.get("state", "")).to_lower().find("lock") >= 0
	if locked:
		return "未解锁"
	return _state_hint()


func _category_chip_text() -> String:
	var category := String(card_data.get("category", "项目")).strip_edges()
	var collectible_level := maxi(0, int(card_data.get("collectible_level", 0)))
	if collectible_level > 0:
		return "藏品 Lv.%d" % collectible_level
	match category.to_lower():
		"warehouse": return "仓库"
		"loadout": return "出勤配置"
		"equipment": return "装备"
		"consumable": return "消耗品"
		"collectible": return "藏品"
		"special": return "特殊物"
	return Art10UISkinKitScript.short_summary(category, 8)


func _state_hint() -> String:
	var state := String(card_data.get("state", "")).to_lower()
	if state.find("lock") >= 0:
		return "仍可查看"
	if selected:
		return "当前条目"
	return "可切换"


func _display_state(state: StringName) -> String:
	var value := String(state).to_lower()
	if value.find("unaffordable") >= 0:
		return "金币不足"
	if value.find("over_limit") >= 0 or value.find("overweight") >= 0:
		return "已超限"
	if value.find("lock") >= 0:
		return "未开放"
	if value.find("selected") >= 0:
		return "已选"
	if value.find("configured") >= 0:
		return "已配置"
	if value.find("owned") >= 0:
		return "已拥有"
	if value.find("valid") >= 0 or value.find("ready") >= 0 or value.find("real") >= 0:
		return "可用"
	return "查看"


func _rarity_color() -> Color:
	if not card_data.has("rarity"):
		return Color(0.58, 0.62, 0.58, 0.86)
	return Color(_rarity_descriptor().get("color", Color(0.58, 0.62, 0.58, 0.86)))


func _rarity_descriptor() -> Dictionary:
	return ItemRarityDescriptorScript.describe(card_data.get("rarity", &"unknown"))


func _card_surface_state(state: StringName) -> StringName:
	var value := String(state).to_lower()
	if value.find("lock") >= 0:
		return &"locked"
	if value.find("risk") >= 0 or value.find("warning") >= 0 or value.find("over") >= 0 or value.find("unaffordable") >= 0 or value.find("insufficient") >= 0:
		return &"warning"
	return &"normal"


func _style(state: StringName) -> StyleBox:
	return Art10UISkinKitScript.style_box_from_asset_ref(
		Art22DeployPrepAssetContractScript.control_ref(&"card", state),
		10,
		24
	)


func _add_label(node_name: String, rect: Rect2, text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var composition_role := &"body"
	if node_name == "CardTitle":
		composition_role = &"title"
	elif node_name != "CardSummary":
		composition_role = &"status"
	Art10UISkinKitScript.apply_composition_label(label, composition_role, font_size, color)
	label.set_meta("deploy_card_base_font_size", font_size)
	label.set_meta("deploy_card_composition_role", composition_role)
	label.set_meta("deploy_card_max_font_size", maxi(font_size, int(floor(rect.size.y - 2.0))))
	_apply_scaled_label_font(label)
	_set_rect(label, rect)
	add_child(label)
	return label


func _refresh_ui_scale_metrics() -> void:
	for child in get_children():
		if child is Label and child.has_meta("deploy_card_base_font_size"):
			_apply_scaled_label_font(child as Label)


func _apply_scaled_label_font(label: Label) -> void:
	if label == null or not label.has_meta("deploy_card_base_font_size"):
		return
	var base_font_size := int(label.get_meta("deploy_card_base_font_size", 0))
	var scaled_font_size := Art10UISkinKitScript.scaled_font_size(base_font_size, ui_scale_factor)
	scaled_font_size = mini(
		scaled_font_size,
		int(label.get_meta("deploy_card_max_font_size", scaled_font_size))
	)
	label.add_theme_font_size_override("font_size", scaled_font_size)
	label.set_meta("runtime_ui_scale_factor", ui_scale_factor)


func _add_chip(node_name: String, rect: Rect2, text: String) -> void:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.085, 0.083, 0.92)
	style.border_color = Color(0.55, 0.46, 0.28, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	panel.add_theme_stylebox_override("panel", style)
	_set_rect(panel, rect)
	add_child(panel)
	var label := _add_label(node_name + "Label", Rect2(rect.position + Vector2(4, 1), rect.size - Vector2(8, 2)), text, 10, Color(0.80, 0.75, 0.62), HORIZONTAL_ALIGNMENT_CENTER)
	label.clip_text = true


func _add_asset_panel(node_name: String, rect: Rect2, control_id: StringName, state: StringName) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", Art10UISkinKitScript.style_box_from_asset_ref(
		Art22DeployPrepAssetContractScript.control_ref(control_id, state),
		5,
		12
	))
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


func _set_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position.round()
	control.size = rect.size.round()
