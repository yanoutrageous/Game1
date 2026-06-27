extends Control
class_name LongTermShell

const LongTermModelScript := preload("res://scripts/ui/long_term/long_term_model.gd")
const LongTermTabModelScript := preload("res://scripts/ui/long_term/long_term_tab_model.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")

var current_model: Dictionary = {}
var selected_module_id: StringName = &"goals"
var tab_buttons: Dictionary = {}
var overview_label: Label
var module_title_label: Label
var module_state_label: Label
var module_body_label: Label
var module_reason_label: Label
var child_preview_label: Label
var snapshot_label: Label
var interface_preview_label: Label
var history_preview_label: Label
var next_stage_label: Label
var card_grid_container: GridContainer


func build(model: Dictionary = {}) -> void:
	_clear_children()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	current_model = model.duplicate(true) if not model.is_empty() else LongTermModelScript.build(selected_module_id)
	selected_module_id = StringName(current_model.get("selected_module_id", selected_module_id))
	_build_static_layout()
	_refresh_from_model()


func apply_snapshot(_snapshot: Dictionary) -> void:
	current_model = LongTermModelScript.build(selected_module_id, &"app_shell_snapshot_preview")
	_refresh_from_model()


func show_module(module_id: StringName = &"goals") -> void:
	selected_module_id = module_id
	if selected_module_id == &"":
		selected_module_id = LongTermTabModelScript.default_module_id()
	current_model = LongTermModelScript.build(selected_module_id)
	_refresh_from_model()


func get_selected_module_id() -> StringName:
	return selected_module_id


func _build_static_layout() -> void:
	_add_color_rect(self, "LongTermBackdrop", Rect2(0, 0, 1280, 720), Color(0.016, 0.030, 0.036, 1.0))
	_add_color_rect(self, "LongTermArchiveRoomGlow", Rect2(38, 122, 1202, 530), Color(0.13, 0.18, 0.20, 0.20))
	_add_color_rect(self, "LongTermArchiveWall", Rect2(318, 146, 584, 492), Color(0.06, 0.09, 0.09, 0.28))
	_add_color_rect(self, "LongTermProfileMask", Rect2(60, 200, 228, 398), Color(0.0, 0.0, 0.0, 0.20))
	_add_color_rect(self, "LongTermDetailMask", Rect2(928, 178, 286, 422), Color(0.0, 0.0, 0.0, 0.26))
	_add_color_rect(self, "LongTermShelfLineA", Rect2(326, 204, 564, 2), Color(0.94, 0.70, 0.28, 0.26))
	_add_color_rect(self, "LongTermShelfLineB", Rect2(326, 336, 564, 2), Color(0.94, 0.70, 0.28, 0.18))
	_add_color_rect(self, "LongTermShelfLineC", Rect2(326, 468, 564, 2), Color(0.94, 0.70, 0.28, 0.14))
	_add_color_rect(self, "LongTermDetailLamp", Rect2(914, 132, 322, 4), Art10UISkinKitScript.color(&"gold"))
	_add_panel(self, "LongTermProfileColumn", Art10UISkinKitScript.rect(&"long_term", "profile_column"), &"deep")
	_add_panel(self, "LongTermCardGridColumn", Art10UISkinKitScript.rect(&"long_term", "card_grid"), &"surface")
	_add_panel(self, "LongTermDetailColumn", Art10UISkinKitScript.rect(&"long_term", "detail_column"), &"summary")
	_add_label_token(self, "LongTermTitle", Rect2(44, 32, 360, 48), "长期系统", &"page_title", &"accent")
	_add_label_token(self, "LongTermSubtitle", Rect2(44, 80, 700, 28), "档案、图鉴、研究与收藏。", &"body_small", &"muted")
	_add_button(self, "LongTermBackButton", Rect2(1084, 36, 154, 38), "返回主菜单", Callable(self, "_request_back_to_main"))
	_build_tab_buttons()

	_add_label_token(self, "LongTermProfileHeading", Rect2(66, 178, 220, 24), "角色档案", &"tab", &"accent")
	_add_color_rect(self, "LongTermAvatarGlow", Rect2(72, 210, 116, 116), Color(0.58, 0.93, 0.76, 0.08))
	_add_color_rect(self, "LongTermAvatarSilhouette", Rect2(104, 226, 52, 78), Color(0.18, 0.27, 0.24, 0.84))
	_add_color_rect(self, "LongTermAvatarBase", Rect2(88, 306, 84, 6), Art10UISkinKitScript.color(&"accent", Color(0.58, 0.93, 0.76, 1.0)))
	_add_color_rect(self, "LongTermArchiveDivider", Rect2(66, 314, 214, 2), Art10UISkinKitScript.color(&"accent"))
	overview_label = _add_label_token(self, "LongTermOverview", Rect2(66, 334, 214, 58), "", &"body_small", &"text")
	child_preview_label = _add_label_token(self, "LongTermChildPreview", Rect2(66, 408, 214, 64), "", &"caption", &"text")
	history_preview_label = _add_label_token(self, "LongTermHistoryPreview", Rect2(66, 496, 214, 58), "", &"caption", &"muted")

	_add_label_token(self, "LongTermGridHeading", Rect2(348, 176, 320, 28), "收藏与记录", &"tab", &"warning")
	card_grid_container = GridContainer.new()
	card_grid_container.name = "LongTermCardGrid"
	card_grid_container.columns = 3
	card_grid_container.add_theme_constant_override("h_separation", 10)
	card_grid_container.add_theme_constant_override("v_separation", 10)
	_set_rect(card_grid_container, Rect2(348, 216, 516, 370))
	add_child(card_grid_container)
	next_stage_label = _add_label_token(self, "LongTermNextStage", Rect2(348, 596, 516, 34), "", &"caption", &"muted")

	_add_panel(self, "LongTermDetailStatusBlock", Rect2(936, 212, 258, 52), &"surface")
	_add_panel(self, "LongTermDetailInfoBlock", Rect2(936, 274, 258, 78), &"deep")
	_add_panel(self, "LongTermDetailUnlockBlock", Rect2(936, 362, 258, 58), &"warning")
	_add_panel(self, "LongTermDetailLinkBlock", Rect2(936, 430, 258, 92), &"surface")
	module_title_label = _add_label_token(self, "LongTermModuleTitle", Rect2(940, 178, 250, 32), "", &"section_title", &"warning")
	module_state_label = _add_label_token(self, "LongTermModuleState", Rect2(950, 222, 230, 28), "", &"body_small", &"muted")
	module_body_label = _add_label_token(self, "LongTermModuleBody", Rect2(950, 284, 230, 52), "", &"caption", &"text")
	module_reason_label = _add_label_token(self, "LongTermModuleReason", Rect2(950, 372, 230, 32), "", &"caption", &"warning")
	snapshot_label = _add_label_token(self, "LongTermSnapshotPreview", Rect2(950, 440, 230, 44), "", &"caption", &"text")
	interface_preview_label = _add_label_token(self, "LongTermInterfacePreview", Rect2(950, 488, 230, 34), "", &"caption", &"muted")


func _build_tab_buttons() -> void:
	tab_buttons.clear()
	var tab_row := HBoxContainer.new()
	tab_row.name = "LongTermTopTabRow"
	_set_rect(tab_row, Art10UISkinKitScript.rect(&"long_term", "tab_row"))
	tab_row.add_theme_constant_override("separation", 8)
	add_child(tab_row)
	var modules: Array = current_model.get("modules", [])
	for module: Dictionary in modules:
		var module_id := StringName(module.get("id", &""))
		var title := String(module.get("title", ""))
		var button := Button.new()
		button.name = "LongTermTab_%s" % String(module_id)
		button.text = title
		button.tooltip_text = String(module.get("reason", ""))
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(110, 40)
		button.pressed.connect(Callable(self, "_on_module_tab_pressed").bind(module_id))
		Art10UISkinKitScript.apply_button_token(button, &"secondary", &"tab", &"tab")
		tab_row.add_child(button)
		tab_buttons[module_id] = button


func _on_module_tab_pressed(module_id: StringName) -> void:
	show_module(module_id)


func _request_back_to_main() -> void:
	if get_parent() != null and get_parent().has_method("show_main"):
		get_parent().call("show_main")


func _refresh_from_model() -> void:
	if overview_label == null:
		return
	selected_module_id = StringName(current_model.get("selected_module_id", selected_module_id))
	var overview: Dictionary = current_model.get("overview_summary", {})
	overview_label.text = "%s\n%s" % [
		_shorten_copy(String(overview.get("title", "长期系统")), 12),
		"档案 / 图鉴 / 研究 / 收藏",
	]
	var panel: Dictionary = current_model.get("placeholder_panel", {})
	var content_preview: Dictionary = current_model.get("current_content_preview", panel.get("content_preview", {}))
	module_title_label.text = _shorten_copy(String(panel.get("title", "")), 12)
	module_state_label.text = "状态  %s" % Art10UISkinKitScript.status_label(panel.get("state", "preview"))
	module_body_label.text = _detail_module_copy(String(panel.get("description", "")), content_preview.get("detail_preview", {}))
	module_reason_label.text = "解锁  %s" % _shorten_copy(String(panel.get("reason", "")), 14)
	child_preview_label.text = "记录\n%s" % _format_child_groups(panel.get("child_preview_groups", []) as Array)
	var snapshot: Dictionary = current_model.get("snapshot_preview", {})
	snapshot_label.text = "档案  %s" % _format_snapshot_section(snapshot.get("profile_snapshot", {}))
	interface_preview_label.text = "联动  奖励 / 事件 / 跳转"
	var history_preview: Dictionary = current_model.get("history_preview_panel", {})
	history_preview_label.text = _format_history_preview(history_preview)
	next_stage_label.text = "后续内容已收起到详情。"
	_refresh_card_grid(content_preview.get("cards", []) as Array)
	_apply_art10_text_refresh()
	_refresh_tab_buttons()


func _refresh_card_grid(cards: Array) -> void:
	if card_grid_container == null:
		return
	for child in card_grid_container.get_children():
		card_grid_container.remove_child(child)
		child.queue_free()
	var visible_cards := cards.slice(0, 9)
	if visible_cards.is_empty():
		var placeholder := Label.new()
		placeholder.text = "当前模块尚无可展示卡片。"
		placeholder.custom_minimum_size = Vector2(500, 60)
		Art10UISkinKitScript.apply_label_token(placeholder, &"body", &"muted")
		card_grid_container.add_child(placeholder)
		return
	var index := 0
	for card: Dictionary in visible_cards:
		var button := Button.new()
		button.name = "LongTermCard_%s" % str(card.get("id", index))
		button.text = "%s  %s\n[%s]" % [
			_card_marker(index),
			_shorten_copy(String(card.get("title", "")), 10),
			Art10UISkinKitScript.status_label(card.get("state", "preview")),
		]
		button.tooltip_text = String(card.get("description", ""))
		button.custom_minimum_size = Vector2(160, 104)
		button.toggle_mode = true
		button.button_pressed = index == 0
		Art10UISkinKitScript.apply_button_token(button, Art10UISkinKitScript.visual_state_tone(&"selected" if index == 0 else &"normal"), &"caption", &"slot")
		card_grid_container.add_child(button)
		index += 1


func _refresh_tab_buttons() -> void:
	for module_id in tab_buttons.keys():
		var button := tab_buttons[module_id] as Button
		if button != null:
			button.button_pressed = StringName(module_id) == selected_module_id
			Art10UISkinKitScript.apply_button_token(button, Art10UISkinKitScript.visual_state_tone(&"selected" if button.button_pressed else &"normal"), &"tab", &"tab")


func _format_child_groups(groups: Array) -> String:
	var lines := []
	var visible_groups := groups.slice(0, 2)
	for group: Dictionary in visible_groups:
		lines.append(String(group.get("title", "")))
	if groups.size() > visible_groups.size():
		lines.append("%d 项已收起" % (groups.size() - visible_groups.size()))
	return Art10UISkinKitScript.budgeted_lines_text(lines, 3, 12, true)


func _format_detail_preview(detail: Variant) -> String:
	var preview: Dictionary = detail if detail is Dictionary else {}
	return Art10UISkinKitScript.sanitize_player_copy("%s\n%s" % [
		_shorten_copy(String(preview.get("title", "详情")), 12),
		_shorten_copy(String(preview.get("message", "展示信息")), 14),
	])


func _format_slots(slots: Array) -> String:
	var lines := []
	for slot: Dictionary in slots.slice(0, 2):
		lines.append("- %s" % _shorten_copy(String(slot.get("display_name", "")), 14))
	return Art10UISkinKitScript.sanitize_player_copy("\n".join(lines)) if not lines.is_empty() else "事件位：待开放"


func _format_art_slots(slots: Array) -> String:
	var labels := []
	for slot: Dictionary in slots:
		labels.append(String(slot.get("art_key", "")))
	return "美术位：模块图标 / 横幅"


func _format_cross_links(links: Array) -> String:
	var labels := []
	for link: Dictionary in links:
		labels.append(String(link.get("target", "")))
	return ", ".join(labels) if not labels.is_empty() else "待接入"


func _format_g30_interface_preview(model: Dictionary, content_preview: Dictionary) -> String:
	return Art10UISkinKitScript.sanitize_player_copy("奖励与事件：待开放")


func _format_jump_targets(targets: Array) -> String:
	var labels := []
	for target: Dictionary in targets.slice(0, 4):
		labels.append("%s" % _safe_display_text(target.get("target_id", "")))
	return ", ".join(labels) if not labels.is_empty() else "跳转待接入"


func _format_snapshot_section(raw_section: Variant) -> String:
	var section: Dictionary = raw_section if raw_section is Dictionary else {}
	var lines: Array = section.get("lines", [])
	return Art10UISkinKitScript.sanitize_player_copy("%s / %s" % [_shorten_copy(String(section.get("title", "")), 8), _shorten_copy(" / ".join(lines.slice(0, 1)), 14)])


func _format_preview_line(snapshot: Dictionary, key: String) -> String:
	var section: Dictionary = snapshot.get(key, {})
	return Art10UISkinKitScript.sanitize_player_copy("%s：%s" % [_shorten_copy(String(section.get("title", key)), 14), _shorten_copy(String(section.get("message", "")), 22)])


func _format_history_preview(history_preview: Dictionary) -> String:
	if history_preview.is_empty():
		return "历史战绩：待接入"
	return Art10UISkinKitScript.sanitize_player_copy("战绩\n%s" % [
		_shorten_copy(String(history_preview.get("summary", "")), 16),
	])


func _format_summary_dictionary(value: Variant) -> String:
	if value is Dictionary:
		var summary: Dictionary = value
		var lines := []
		for key in summary.keys().slice(0, 3):
			lines.append("- %s: %s" % [_shorten_copy(_safe_display_text(key), 14), _shorten_copy(_safe_display_text(summary.get(key, "")), 18)])
		return Art10UISkinKitScript.sanitize_player_copy("\n".join(lines))
	return _safe_display_text(value)


func _safe_display_text(value: Variant) -> String:
	if value == null:
		return "-"
	if value is Dictionary:
		return "多项内容"
	if value is Array:
		return "列表内容"
	return Art10UISkinKitScript.sanitize_player_copy(str(value))


func _apply_art10_text_refresh() -> void:
	for label in [
		overview_label,
		child_preview_label,
		history_preview_label,
		next_stage_label,
	]:
		if label is Label:
			Art10UISkinKitScript.apply_label_token(label, &"caption", &"text")
			label.clip_text = false
	if module_title_label is Label:
		Art10UISkinKitScript.apply_label_token(module_title_label, &"section_title", &"warning")
	if module_state_label is Label:
		Art10UISkinKitScript.apply_label_token(module_state_label, &"body_small", &"muted")
	if module_body_label is Label:
		Art10UISkinKitScript.apply_label_token(module_body_label, &"caption", &"text")
	if module_reason_label is Label:
		Art10UISkinKitScript.apply_label_token(module_reason_label, &"caption", &"warning")
	if snapshot_label is Label:
		Art10UISkinKitScript.apply_label_token(snapshot_label, &"caption", &"text")
	if interface_preview_label is Label:
		Art10UISkinKitScript.apply_label_token(interface_preview_label, &"caption", &"muted")


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _add_button(parent: Control, node_name: String, rect: Rect2, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	_set_rect(button, rect)
	Art10UISkinKitScript.apply_button_token(button, &"secondary", &"caption", &"button")
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_label_token(parent: Control, node_name: String, rect: Rect2, text: String, token: StringName, color_token: StringName) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	_set_rect(label, rect)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Art10UISkinKitScript.apply_label_token(label, token, color_token)
	label.clip_text = true
	parent.add_child(label)
	return label


func _add_panel(parent: Control, node_name: String, rect: Rect2, tone: StringName) -> PanelContainer:
	var panel := Art10UISkinKitScript.make_frame_panel(node_name, rect, tone)
	parent.add_child(panel)
	return panel


func _add_color_rect(parent: Control, node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.name = node_name
	color_rect.color = color
	_set_rect(color_rect, rect)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(color_rect)
	return color_rect


func _set_rect(control: Control, rect: Rect2) -> void:
	Art10UISkinKitScript.set_rect(control, rect)


func _shorten_copy(text: String, max_chars: int) -> String:
	return Art10UISkinKitScript.short_summary(text, max_chars)


func _detail_module_copy(description: String, detail: Variant) -> String:
	var preview: Dictionary = detail if detail is Dictionary else {}
	var lines: Array = [
		description,
		String(preview.get("title", "")),
		String(preview.get("message", "")),
	]
	return "说明\n%s" % Art10UISkinKitScript.budgeted_lines_text(lines, 2, 13, false)


func _card_marker(index: int) -> String:
	var markers := ["◆", "◇", "▣", "□", "◈", "○", "●", "△", "▲"]
	return markers[index % markers.size()]
