extends Control
class_name LongTermShell

const LongTermModelScript := preload("res://scripts/ui/long_term/long_term_model.gd")
const LongTermTabModelScript := preload("res://scripts/ui/long_term/long_term_tab_model.gd")

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
var next_stage_label: Label


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
	_add_color_rect(self, "LongTermBackdrop", Rect2(0, 0, 1280, 720), Color(0.018, 0.032, 0.038, 1.0))
	_add_label(self, "LongTermTitle", Rect2(64, 42, 520, 42), "长期系统", 31, PresentationTheme.color_for_key(&"ui.accent"))
	_add_label(self, "LongTermSubtitle", Rect2(66, 84, 760, 42), "G19 foundation：六个一级模块、placeholder 状态和只读接口预览。", 15, PresentationTheme.color_for_key(&"ui.muted"))
	overview_label = _add_label(self, "LongTermOverview", Rect2(64, 132, 1120, 72), "", 15, PresentationTheme.text_color())
	_build_tab_buttons()
	module_title_label = _add_label(self, "LongTermModuleTitle", Rect2(64, 268, 400, 34), "", 24, PresentationTheme.color_for_key(&"ui.warning"))
	module_state_label = _add_label(self, "LongTermModuleState", Rect2(470, 272, 260, 28), "", 16, PresentationTheme.color_for_key(&"ui.muted"))
	module_body_label = _add_label(self, "LongTermModuleBody", Rect2(64, 316, 500, 112), "", 15, PresentationTheme.text_color())
	module_reason_label = _add_label(self, "LongTermModuleReason", Rect2(64, 432, 500, 62), "", 14, PresentationTheme.color_for_key(&"ui.warning"))
	child_preview_label = _add_label(self, "LongTermChildPreview", Rect2(610, 268, 290, 294), "", 14, PresentationTheme.text_color())
	snapshot_label = _add_label(self, "LongTermSnapshotPreview", Rect2(930, 146, 270, 220), "", 13, PresentationTheme.color_for_key(&"ui.muted"))
	interface_preview_label = _add_label(self, "LongTermInterfacePreview", Rect2(930, 384, 270, 162), "", 13, PresentationTheme.color_for_key(&"ui.muted"))
	next_stage_label = _add_label(self, "LongTermNextStage", Rect2(64, 582, 1136, 72), "", 13, PresentationTheme.color_for_key(&"ui.muted"))
	_add_button(self, "LongTermBackButton", Rect2(64, 656, 170, 40), "返回主菜单", Callable(self, "_request_back_to_main"))


func _build_tab_buttons() -> void:
	tab_buttons.clear()
	var modules: Array = current_model.get("modules", [])
	var index := 0
	for module: Dictionary in modules:
		var module_id := StringName(module.get("id", &""))
		var title := String(module.get("title", ""))
		var state := String(module.get("state", "preview"))
		var button := _add_button(self, "LongTermTab_%s" % String(module_id), Rect2(64 + index * 184, 214, 170, 42), "%s\n%s" % [title, state], Callable(self, "_on_module_tab_pressed").bind(module_id))
		button.toggle_mode = true
		tab_buttons[module_id] = button
		index += 1


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
	overview_label.text = "%s\n%s\n模块：%s" % [
		String(overview.get("title", "长期系统壳层")),
		String(overview.get("message", "")),
		", ".join(overview.get("modules", []) as Array),
	]
	var panel: Dictionary = current_model.get("placeholder_panel", {})
	module_title_label.text = String(panel.get("title", ""))
	module_state_label.text = "状态：%s" % String(panel.get("state", "preview"))
	module_body_label.text = "%s\n\n摘要：\n%s" % [
		String(panel.get("description", "")),
		_format_dictionary(panel.get("summary", {})),
	]
	module_reason_label.text = "边界：%s" % String(panel.get("reason", ""))
	child_preview_label.text = "内部 preview\n\n%s" % _format_child_groups(panel.get("child_preview_groups", []) as Array)
	var snapshot: Dictionary = current_model.get("snapshot_preview", {})
	snapshot_label.text = "只读快照预览\n\n%s\n%s\n%s" % [
		_format_snapshot_section(snapshot.get("profile_snapshot", {})),
		_format_snapshot_section(snapshot.get("unlock_snapshot", {})),
		_format_snapshot_section(snapshot.get("history_snapshot", {})),
	]
	interface_preview_label.text = "接口 preview\n\n%s\n%s\n%s\n%s" % [
		_format_preview_line(snapshot, "asset_projection_preview"),
		_format_preview_line(snapshot, "event_flow_preview"),
		_format_preview_line(snapshot, "reward_preview"),
		_format_preview_line(snapshot, "red_dot_preview"),
	]
	next_stage_label.text = "链接 preview：%s / %s / %s\n下一阶段：%s" % [
		_format_preview_line(snapshot, "inventory_link_preview"),
		_format_preview_line(snapshot, "codex_link_preview"),
		_format_preview_line(snapshot, "history_link_preview"),
		String(panel.get("next_stage_note", "")),
	]
	_refresh_tab_buttons()


func _refresh_tab_buttons() -> void:
	for module_id in tab_buttons.keys():
		var button := tab_buttons[module_id] as Button
		if button != null:
			button.button_pressed = StringName(module_id) == selected_module_id


func _format_child_groups(groups: Array) -> String:
	var lines := []
	for group: Dictionary in groups:
		lines.append("[%s]" % String(group.get("title", "")))
		for item in group.get("items", []):
			lines.append("- %s" % String(item))
	return "\n".join(lines)


func _format_snapshot_section(raw_section: Variant) -> String:
	var section: Dictionary = raw_section if raw_section is Dictionary else {}
	var lines: Array = section.get("lines", [])
	return "%s：%s" % [String(section.get("title", "")), " / ".join(lines)]


func _format_preview_line(snapshot: Dictionary, key: String) -> String:
	var section: Dictionary = snapshot.get(key, {})
	return "%s：%s" % [String(section.get("title", key)), String(section.get("message", ""))]


func _format_dictionary(value: Variant) -> String:
	if value is Dictionary:
		return JSON.stringify(value, "\t")
	return String(value)


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _add_button(parent: Control, node_name: String, rect: Rect2, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.offset_left = rect.position.x
	button.offset_top = rect.position.y
	button.offset_right = rect.position.x + rect.size.x
	button.offset_bottom = rect.position.y + rect.size.y
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_label(parent: Control, node_name: String, rect: Rect2, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.offset_left = rect.position.x
	label.offset_top = rect.position.y
	label.offset_right = rect.position.x + rect.size.x
	label.offset_bottom = rect.position.y + rect.size.y
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _add_color_rect(parent: Control, node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.name = node_name
	color_rect.color = color
	color_rect.offset_left = rect.position.x
	color_rect.offset_top = rect.position.y
	color_rect.offset_right = rect.position.x + rect.size.x
	color_rect.offset_bottom = rect.position.y + rect.size.y
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(color_rect)
	return color_rect
