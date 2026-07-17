extends Control
class_name DeployPrepCardView

const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art22DeployPrepAssetContractScript := preload("res://scripts/presentation/art22_deploy_prep_asset_contract.gd")

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


func setup(card: Dictionary, tab_id: StringName, is_selected: bool) -> void:
	card_data = card.duplicate(true)
	card_id = StringName(card_data.get("id", &""))
	selected = is_selected
	custom_minimum_size = Vector2(612, 112)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_nodes(tab_id)
	apply_selected(is_selected)


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
	if title_label != null:
		title_label.modulate = Color(1.08, 1.03, 0.90, 1.0) if selected else Color.WHITE
	if state_label != null:
		state_label.text = "已选" if selected else _display_state(state)
	if state_hint_label != null:
		state_hint_label.text = _state_hint()


func grab_card_focus() -> void:
	if button != null and not button.disabled:
		button.grab_focus()


func focus_button() -> Button:
	return button


func _build_nodes(tab_id: StringName) -> void:
	button = Button.new()
	button.name = "CardHitTarget"
	button.text = ""
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(func() -> void: card_pressed.emit(card_id))
	add_child(button)

	_add_color_rect("CardContentMatte", Rect2(164, 9, 320, 94), Color(0.015, 0.055, 0.060, 0.38))
	_add_color_rect("CardColumnDivider", Rect2(488, 18, 1, 76), Color(0.28, 0.72, 0.68, 0.34))
	_add_asset_panel("CardArtworkFrame", Rect2(14, 8, 146, 96), &"slot", &"normal")
	var art_ref := Art22DeployPrepAssetContractScript.card_art_ref(tab_id, card_id, StringName(card_data.get("filter_id", &"")))
	artwork = TextureRect.new()
	artwork.name = "CardArtwork"
	artwork.texture = Art09ManifestAssetMappingScript.resolve_texture(art_ref)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_rect := Rect2(20, 14, 134, 84) if tab_id == &"map" else Rect2(51, 24, 72, 64)
	_set_rect(artwork, art_rect)
	add_child(artwork)

	title_label = _add_label("CardTitle", Rect2(176, 13, 298, 28), _display_title(), 19, Color(0.96, 0.86, 0.63), HORIZONTAL_ALIGNMENT_LEFT)
	title_label.clip_text = true
	summary_label = _add_label("CardSummary", Rect2(176, 43, 296, 35), _summary_text(), 13, Color(0.76, 0.82, 0.76), HORIZONTAL_ALIGNMENT_LEFT)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_add_chip("CardCategoryChip", Rect2(176, 81, 142, 22), _category_chip_text())
	_add_chip("CardModeChip", Rect2(326, 81, 148, 22), _mode_chip_text())
	state_panel = _add_asset_panel("CardStatePanel", Rect2(501, 14, 96, 32), &"slot", &"normal")
	state_label = _add_label("CardState", Rect2(506, 17, 86, 26), "", 13, Color(0.42, 0.92, 0.86), HORIZONTAL_ALIGNMENT_CENTER)
	state_label.clip_text = true
	state_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_add_label("CardStateHeading", Rect2(506, 50, 86, 18), "状态", 12, Color(0.55, 0.69, 0.65), HORIZONTAL_ALIGNMENT_CENTER)
	state_hint_label = _add_label("CardStateHint", Rect2(499, 70, 100, 26), _state_hint(), 12, Color(0.80, 0.76, 0.62), HORIZONTAL_ALIGNMENT_CENTER)


func _display_title() -> String:
	match card_id:
		&"m3r_loadout_equipment": return "已选装备"
		&"m3r_loadout_consumables": return "携带消耗品"
		&"m3r_loadout_capacity": return "背包容量"
		&"m3r_profile_permission_protocol": return "档案 / 许可 / 协议"
		&"m3r_start_intent": return "开始常规探索"
		&"m3r_warehouse_status": return "仓库状态"
	return Art10UISkinKitScript.short_summary(String(card_data.get("title", "未命名项目")), 18)


func _summary_text() -> String:
	match card_id:
		&"m3r_loadout_equipment": return "已从真实仓库配置本次探索装备。"
		&"m3r_loadout_consumables": return "携带补给进入背包，未使用物按结果结算。"
		&"m3r_loadout_capacity": return "显示携带重量、背包上限与失败回收容量。"
		&"m3r_profile_permission_protocol": return "展示当前档案、许可等级与协议难度接口。"
		&"m3r_start_intent": return "使用当前地图、目标与携带配置进入现有路线。"
		&"m3r_warehouse_status": return "汇总真实仓库的装备、消耗品、藏品与特殊物。"
	if String(card_id).begins_with("m3r_"):
		return "%s已由真实仓库读取；本页仅显示配置状态。" % String(card_data.get("category", "物品"))
	var text := Art10UISkinKitScript.sanitize_player_copy(String(card_data.get("summary", "")))
	if text.is_empty():
		text = Art10UISkinKitScript.sanitize_player_copy(String(card_data.get("detail", "")))
	return Art10UISkinKitScript.short_summary(text, 36)


func _mode_chip_text() -> String:
	var locked := String(card_data.get("state", "")).to_lower().find("lock") >= 0
	if locked:
		return "后续开放"
	return "真实配置" if String(card_id).begins_with("m3r_") else "信息预览"


func _category_chip_text() -> String:
	var category := String(card_data.get("category", "项目")).strip_edges()
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
		return "当前选择"
	return "可切换"


func _display_state(state: StringName) -> String:
	var value := String(state).to_lower()
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
	return Art10UISkinKitScript.short_summary(Art10UISkinKitScript.status_label(state), 6)


func _card_surface_state(state: StringName) -> StringName:
	var value := String(state).to_lower()
	if value.find("lock") >= 0:
		return &"locked"
	if value.find("risk") >= 0 or value.find("warning") >= 0 or value.find("over") >= 0:
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
	Art10UISkinKitScript.apply_label(label, font_size, color)
	_set_rect(label, rect)
	add_child(label)
	return label


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
	var label := _add_label(node_name + "Label", Rect2(rect.position + Vector2(6, 1), rect.size - Vector2(12, 2)), text, 12, Color(0.80, 0.75, 0.62), HORIZONTAL_ALIGNMENT_CENTER)
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
