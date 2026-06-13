extends Control
class_name RunSurface

const HUDScene := preload("res://scenes/ui/hud/hud.tscn")
const MiniMapScene := preload("res://scenes/ui/minimap/minimap_panel.tscn")
const PresentationTheme := preload("res://scripts/presentation/presentation_theme.gd")

signal interact_requested
signal inventory_requested
signal ground_loot_requested
signal map_requested(source: StringName)
signal combat_requested
signal extract_requested
signal pause_requested

var hud: Hud
var minimap_panel: MiniMapPanel
var overlay_slot: Control
var modal_slot: Control
var feedback_slot: Control

var left_backdrop: PanelContainer
var center_backdrop: PanelContainer
var right_backdrop: PanelContainer
var bottom_backdrop: PanelContainer
var resource_backdrop: PanelContainer
var scanner_title_label: Label
var scanner_summary_label: Label
var scanner_legend_label: Label
var scanner_detail_label: Label
var room_title_label: Label
var room_body_label: Label
var objective_label: Label
var resource_label: Label
var right_title_label: Label
var right_body_label: Label
var event_label: Label
var reward_label: Label
var command_feedback_label: Label
var layout_label: Label
var action_hint_label: Label
var action_bar: HBoxContainer
var action_buttons: Dictionary = {}
var built := false


func build() -> void:
	if built:
		return
	built = true
	name = "RunSurface"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	left_backdrop = _add_panel("LegacyScannerRail", PresentationTheme.panel_color(), PresentationTheme.color_for_key(&"ui.accent"))
	center_backdrop = _add_panel("LegacyRoomMainPanel", Color(0.025, 0.045, 0.05, 0.78), PresentationTheme.color_for_key(&"mini.normal"))
	right_backdrop = _add_panel("LegacyProtocolRail", Color(0.035, 0.04, 0.042, 0.90), PresentationTheme.color_for_key(&"ui.warning"))
	bottom_backdrop = _add_panel("LegacyActionBarSurface", PresentationTheme.panel_color(), PresentationTheme.color_for_key(&"ui.accent"))
	resource_backdrop = _add_panel("LegacyResourcePocket", Color(0.035, 0.055, 0.055, 0.92), PresentationTheme.color_for_key(&"mini.chest"))

	scanner_title_label = _add_label("LegacyScannerTitle", "区域扫描器", 18, PresentationTheme.color_for_key(&"ui.accent"))
	scanner_summary_label = _add_label("LegacyScannerSummary", "扫描器：等待数据", 13, PresentationTheme.text_color())
	scanner_legend_label = _add_label("LegacyScannerLegend", "P 当前 | ? 未知 | F 标记 | X 撤离", 12, PresentationTheme.color_for_key(&"ui.muted"))

	scanner_detail_label = _add_label("LegacyScannerDetail", "图例：只显示已公开扫描信息。", 12, PresentationTheme.color_for_key(&"ui.muted"))

	minimap_panel = MiniMapScene.instantiate() as MiniMapPanel
	minimap_panel.name = "LegacyScannerMiniMap"
	minimap_panel.open_map_requested.connect(func() -> void: map_requested.emit(&"surface_minimap"))
	add_child(minimap_panel)

	room_title_label = _add_label("LegacyRoomTitle", "当前房间", 24, PresentationTheme.color_for_key(&"ui.accent"))
	room_body_label = _add_label("LegacyRoomBody", "等待 run snapshot。", 15, PresentationTheme.text_color())
	objective_label = _add_label("LegacyObjectiveLine", "目标：等待输入。", 15, PresentationTheme.color_for_key(&"ui.warning"))

	resource_label = _add_label("LegacyResourceSummary", "资源：等待数据", 13, PresentationTheme.text_color())

	right_title_label = _add_label("LegacyProtocolTitle", "协议 / 危险 / 状态", 18, PresentationTheme.color_for_key(&"ui.warning"))
	right_body_label = _add_label("LegacyProtocolBody", "协议：--\n压力：--\n危险：--", 14, PresentationTheme.text_color())
	event_label = _add_label("LegacyEventStatus", "事件：无待处理事件。", 13, PresentationTheme.text_color())
	reward_label = _add_label("LegacyRewardSummary", "奖励：等待记录。", 12, PresentationTheme.color_for_key(&"ui.muted"))
	command_feedback_label = _add_label("LegacyCommandFeedback", "操作反馈：等待输入。", 13, PresentationTheme.color_for_key(&"ui.accent"))
	layout_label = _add_label("LegacyLayoutProfileStatus", "Layout: desktop", 11, PresentationTheme.color_for_key(&"ui.muted"))

	action_hint_label = _add_label("LegacyActionHint", "行动提示：可用按钮高亮，灰显按钮保留原因提示。", 12, PresentationTheme.color_for_key(&"ui.muted"))

	action_bar = HBoxContainer.new()
	action_bar.name = "LegacyBottomActionButtons"
	action_bar.add_theme_constant_override("separation", 6)
	add_child(action_bar)
	_add_action_button(&"interact", "搜索 / 交互", func() -> void: interact_requested.emit())
	_add_action_button(&"inventory", "背包", func() -> void: inventory_requested.emit())
	_add_action_button(&"ground_loot", "地面物品", func() -> void: ground_loot_requested.emit())
	_add_action_button(&"map", "区域扫描", func() -> void: map_requested.emit(&"surface_button"))
	_add_action_button(&"combat", "清理威胁", func() -> void: combat_requested.emit())
	_add_action_button(&"extract", "撤离", func() -> void: extract_requested.emit())
	_add_action_button(&"pause", "暂停", func() -> void: pause_requested.emit())

	hud = HUDScene.instantiate() as Hud
	hud.name = "LegacySurfaceHUD"
	add_child(hud)

	feedback_slot = _add_slot("LegacyFeedbackSlot")
	overlay_slot = _add_slot("LegacyOverlaySlot")
	modal_slot = _add_slot("LegacyModalSlot")


func apply_surface_model(model: Dictionary) -> void:
	if not built:
		build()
	scanner_legend_label.text = _lines_text(model.get("scanner_legend_lines", []), "P 当前 | ? 未知 | F 标记 | X 撤离")
	scanner_detail_label.text = String(model.get("scanner_detail", "图例：只显示已公开扫描信息。"))
	scanner_summary_label.text = String(model.get("scanner_summary", "扫描器：等待公开地图数据。"))
	room_title_label.text = "%s | %s" % [String(model.get("room_title", "当前房间")), String(model.get("room_coordinate", "(0,0)"))]
	room_body_label.text = String(model.get("room_summary", "等待 run snapshot。"))
	objective_label.text = "目标：%s" % String(model.get("current_objective", "继续探索。"))
	resource_label.text = "%s\n%s" % [String(model.get("resource_summary", "")), String(model.get("backpack_summary", ""))]
	var danger_key := StringName(model.get("danger_theme_key", &"ui.warning"))
	right_title_label.add_theme_color_override("font_color", PresentationTheme.color_for_key(danger_key, PresentationTheme.color_for_key(&"ui.warning")))
	right_body_label.text = "协议：%s\n压力：%s / 100\n危险：%s\n搜索：%s" % [
		model.get("protocol_level", "--"),
		model.get("pressure", "--"),
		String(model.get("danger_label", "--")),
		String(model.get("search_summary", "")),
	]
	event_label.text = String(model.get("event_summary", "事件：无待处理事件。"))
	reward_label.text = String(model.get("reward_summary", "奖励：等待记录。"))
	command_feedback_label.text = String(model.get("command_feedback", "操作反馈：等待输入。"))

	var status_text := _lines_text(model.get("status_lines", []), "")
	if status_text != "":
		right_body_label.text = status_text
	event_label.text = String(model.get("event_panel_summary", model.get("event_summary", event_label.text)))
	reward_label.text = String(model.get("loot_panel_summary", model.get("reward_summary", reward_label.text)))
	action_hint_label.text = String(model.get("action_hint", "行动提示：可用按钮高亮，灰显按钮保留原因提示。"))

	var profile: Dictionary = model.get("layout_profile", {})
	layout_label.text = "Layout: %s / %s" % [
		String(profile.get("profile_id", "desktop")),
		String(profile.get("resolution_id", "unknown")),
	]
	_apply_actions(model.get("action_buttons", []))


func apply_layout_profile(profile: Dictionary) -> void:
	if not built:
		build()
	var supported_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
	if supported_size.x <= 0 or supported_size.y <= 0:
		supported_size = Vector2i(1280, 720)
	var is_low := bool(profile.get("is_low_resolution", false))
	var is_high := bool(profile.get("is_high_resolution", false))
	var width := float(supported_size.x)
	var height := float(supported_size.y)
	var margin := 16.0 if is_low else 20.0
	var left_width := 352.0 if is_low else (420.0 if is_high else 380.0)
	var right_width := 268.0 if is_low else (330.0 if is_high else 296.0)
	var bottom_height := 62.0 if is_low else 70.0
	var pocket_height := 118.0 if is_low else 128.0
	var center_left := left_width + margin
	var center_right := width - right_width - margin
	var center_width := max(360.0, center_right - center_left)
	var scanner_map_height := min(240.0 if is_low else 276.0, height * 0.34)
	var scanner_legend_top := margin + 84.0 + scanner_map_height

	_set_rect(left_backdrop, Rect2(0, 0, left_width, height))
	_set_rect(right_backdrop, Rect2(width - right_width, 0, right_width, height))
	_set_rect(center_backdrop, Rect2(center_left, margin, center_width, 132.0 if is_low else 150.0))
	_set_rect(bottom_backdrop, Rect2(center_left, height - bottom_height - margin, center_width, bottom_height))
	_set_rect(resource_backdrop, Rect2(margin, height - pocket_height - margin, left_width - margin * 2.0, pocket_height))

	_set_rect(scanner_title_label, Rect2(margin, margin, left_width - margin * 2.0, 28))
	_set_rect(scanner_summary_label, Rect2(margin, margin + 30.0, left_width - margin * 2.0, 42))
	_set_rect(minimap_panel, Rect2(margin, margin + 78.0, left_width - margin * 2.0, scanner_map_height))
	_set_rect(scanner_legend_label, Rect2(margin, scanner_legend_top, left_width - margin * 2.0, 62))
	_set_rect(scanner_detail_label, Rect2(margin, scanner_legend_top + 66.0, left_width - margin * 2.0, 86))

	_set_rect(room_title_label, Rect2(center_left + 18.0, margin + 12.0, center_width - 36.0, 34))
	_set_rect(room_body_label, Rect2(center_left + 18.0, margin + 52.0, center_width - 36.0, 62))
	_set_rect(objective_label, Rect2(center_left + 18.0, margin + 112.0, center_width - 36.0, 30))
	_set_rect(resource_label, Rect2(margin * 1.5, height - pocket_height + 2.0, left_width - margin * 3.0, pocket_height - 28.0))

	_set_rect(right_title_label, Rect2(width - right_width + margin, margin, right_width - margin * 2.0, 30))
	_set_rect(right_body_label, Rect2(width - right_width + margin, margin + 38.0, right_width - margin * 2.0, 118))
	_set_rect(event_label, Rect2(width - right_width + margin, margin + 164.0, right_width - margin * 2.0, 62))
	_set_rect(reward_label, Rect2(width - right_width + margin, margin + 232.0, right_width - margin * 2.0, 180))
	_set_rect(command_feedback_label, Rect2(width - right_width + margin, height - 122.0, right_width - margin * 2.0, 66))
	_set_rect(layout_label, Rect2(width - right_width + margin, height - 46.0, right_width - margin * 2.0, 24))

	_set_rect(action_hint_label, Rect2(center_left + 18.0, height - bottom_height - margin - 30.0, center_width - 36.0, 24))
	_set_rect(action_bar, Rect2(center_left + 14.0, height - bottom_height - margin + 13.0, center_width - 28.0, bottom_height - 22.0))
	_set_rect(feedback_slot, Rect2(0, 0, width, height))
	_set_rect(overlay_slot, Rect2(0, 0, width, height))
	_set_rect(modal_slot, Rect2(0, 0, width, height))


func show_command_feedback(result: Dictionary) -> void:
	if command_feedback_label == null or result.is_empty():
		return
	var accepted := bool(result.get("accepted", result.get("ok", false)))
	var key := String(result.get("message_key", result.get("reason_code", "")))
	if key == "":
		key = "accepted" if accepted else "blocked"
	command_feedback_label.text = "操作反馈：%s" % key
	if not accepted:
		var tween := create_tween()
		tween.tween_property(command_feedback_label, "modulate", Color(1.0, 0.55, 0.35, 1.0), 0.06)
		tween.tween_property(command_feedback_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)


func get_hud() -> Hud:
	if not built:
		build()
	return hud


func get_minimap_panel() -> MiniMapPanel:
	if not built:
		build()
	return minimap_panel


func get_overlay_slot() -> Control:
	if not built:
		build()
	return overlay_slot


func get_modal_slot() -> Control:
	if not built:
		build()
	return modal_slot


func get_feedback_slot() -> Control:
	if not built:
		build()
	return feedback_slot


func apply_legacy_modal_style(panel: PanelContainer, theme_key: StringName = &"ui.accent") -> void:
	if panel == null:
		return
	var accent := PresentationTheme.color_for_key(theme_key, PresentationTheme.color_for_key(&"ui.accent"))
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.028, 0.032, 0.96), accent, 2))
	_style_modal_children(panel)


func apply_legacy_button_style(button: Button, tone: StringName = &"secondary") -> void:
	if button == null:
		return
	_apply_action_button_style(button, tone, not button.disabled)


func _add_panel(node_name: String, color: Color, border_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(color, border_color, 1))
	add_child(panel)
	return panel


func _add_label(node_name: String, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _add_action_button(action_id: StringName, label: String, callback: Callable) -> void:
	var button := Button.new()
	button.name = "LegacyAction_%s" % String(action_id)
	button.text = label
	button.custom_minimum_size = Vector2(96, 34)
	button.pressed.connect(callback)
	button.add_theme_font_size_override("font_size", 13)
	_apply_action_button_style(button, &"secondary", true)
	action_bar.add_child(button)
	action_buttons[action_id] = button


func _add_slot(node_name: String) -> Control:
	var slot := Control.new()
	slot.name = node_name
	slot.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(slot)
	return slot


func _apply_actions(actions: Variant) -> void:
	if not (actions is Array):
		return
	for action in actions:
		if not (action is Dictionary):
			continue
		var action_data: Dictionary = action
		var action_id := StringName(action_data.get("id", &""))
		if not action_buttons.has(action_id):
			continue
		var button: Button = action_buttons[action_id]
		button.text = String(action_data.get("label", button.text))
		var enabled := bool(action_data.get("enabled", true))
		var description := String(action_data.get("description", ""))
		var disabled_reason := String(action_data.get("disabled_reason", ""))
		button.disabled = not enabled
		button.tooltip_text = description if enabled or disabled_reason == "" else "%s\n禁用：%s" % [description, disabled_reason]
		_apply_action_button_style(button, StringName(action_data.get("tone", &"secondary")), enabled)


func _panel_style(color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _apply_action_button_style(button: Button, tone: StringName, enabled: bool) -> void:
	var accent := _tone_color(tone)
	button.add_theme_color_override("font_color", PresentationTheme.text_color())
	button.add_theme_color_override("font_disabled_color", PresentationTheme.color_for_key(&"ui.muted"))
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.035, 0.06, 0.064, 0.92), accent, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.055, 0.09, 0.092, 0.98), accent, 1))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.02, 0.04, 0.045, 0.98), accent, 2))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.025, 0.032, 0.034, 0.72), PresentationTheme.color_for_key(&"ui.muted"), 1))
	button.modulate = Color(1, 1, 1, 1) if enabled else Color(0.74, 0.78, 0.76, 1)


func _tone_color(tone: StringName) -> Color:
	match tone:
		&"primary":
			return PresentationTheme.color_for_key(&"ui.accent")
		&"danger":
			return PresentationTheme.color_for_key(&"ui.danger")
		&"warning":
			return PresentationTheme.color_for_key(&"ui.warning")
		_:
			return PresentationTheme.color_for_key(&"ui.muted")


func _style_modal_children(node: Node) -> void:
	if node is Label:
		var label := node as Label
		label.add_theme_color_override("font_color", PresentationTheme.text_color())
	elif node is Button:
		var button := node as Button
		_apply_action_button_style(button, &"secondary", not button.disabled)
	for child in node.get_children():
		_style_modal_children(child)


func _lines_text(lines: Variant, fallback: String) -> String:
	if not (lines is Array):
		return fallback
	var typed_lines: Array = lines
	if typed_lines.is_empty():
		return fallback
	var text := ""
	for index in range(typed_lines.size()):
		if index > 0:
			text += "\n"
		text += String(typed_lines[index])
	return text


func _set_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y
