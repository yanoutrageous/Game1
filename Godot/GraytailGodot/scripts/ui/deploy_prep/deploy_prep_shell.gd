extends Control
class_name DeployPrepShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const DeployPrepModelScript := preload("res://scripts/ui/deploy_prep/deploy_prep_model.gd")
const DeployTabModelScript := preload("res://scripts/ui/deploy_prep/deploy_tab_model.gd")

signal deploy_start_intent_requested(intent: Dictionary)

var current_model: Dictionary = {}
var current_snapshot: Dictionary = {}
var tab_buttons: Dictionary = {}
var tab_title_label: Label
var tab_body_label: Label
var summary_label: Label
var config_label: Label
var effect_label: Label
var risk_label: Label
var preview_label: Label


func build(model: Dictionary = {}) -> void:
	_clear_children()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	current_model = model.duplicate(true) if not model.is_empty() else DeployPrepModelScript.build(current_snapshot)
	_build_backdrop()
	_build_tab_panel()
	_build_content_panel()
	_build_summary_panel()
	_build_action_panel()
	_refresh_view()


func apply_snapshot(snapshot: Dictionary) -> void:
	current_snapshot = snapshot.duplicate(true)
	current_model = DeployPrepModelScript.build(current_snapshot)
	_refresh_view()


func show_tab(tab_id: StringName) -> void:
	if current_model.is_empty():
		current_model = DeployPrepModelScript.build(current_snapshot)
	current_model = DeployPrepModelScript.model_with_tab(current_model, tab_id)
	_refresh_view()


func apply_route_payload(payload: Dictionary) -> void:
	var tab_id := StringName(payload.get("tab", current_model.get("active_tab", DeployTabModelScript.DEFAULT_TAB)))
	show_tab(tab_id)


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	tab_buttons.clear()
	tab_title_label = null
	tab_body_label = null
	summary_label = null
	config_label = null
	effect_label = null
	risk_label = null
	preview_label = null


func _build_backdrop() -> void:
	_add_color_rect(self, "DeployPrepBackdrop", Rect2(0, 0, 1280, 720), Color(0.018, 0.034, 0.040, 1.0))
	_add_color_rect(self, "DeployPrepLeftPanel", Rect2(52, 84, 290, 552), Color(0.055, 0.090, 0.100, 0.96))
	_add_color_rect(self, "DeployPrepCenterPanel", Rect2(372, 84, 498, 552), Color(0.044, 0.070, 0.080, 0.95))
	_add_color_rect(self, "DeployPrepSummaryPanel", Rect2(900, 84, 322, 552), Color(0.060, 0.085, 0.094, 0.97))
	_add_label(self, "DeployPrepTitle", Rect2(64, 30, 520, 42), String(current_model.get("title", "出发探索")), 32, PresentationTheme.color_for_key(&"ui.warning"))
	_add_label(self, "DeployPrepSubtitle", Rect2(380, 38, 620, 34), String(current_model.get("subtitle", "")), 15, PresentationTheme.color_for_key(&"ui.muted"))


func _build_tab_panel() -> void:
	_add_label(self, "DeployTabsHeading", Rect2(76, 104, 230, 28), "一级页签", 17, PresentationTheme.color_for_key(&"ui.accent"))
	var y := 146.0
	for raw_tab in _array_from(current_model, "tabs"):
		if raw_tab is Dictionary:
			var tab := raw_tab as Dictionary
			var tab_id := StringName(tab.get("id", DeployTabModelScript.DEFAULT_TAB))
			var button := Button.new()
			button.name = "DeployTab_%s" % String(tab_id)
			button.text = String(tab.get("label", tab_id))
			button.tooltip_text = String(tab.get("subtitle", ""))
			button.offset_left = 76.0
			button.offset_top = y
			button.offset_right = 316.0
			button.offset_bottom = y + 42.0
			button.pressed.connect(func() -> void: show_tab(tab_id))
			add_child(button)
			tab_buttons[tab_id] = button
			y += 52.0
	_add_label(self, "DeployBoundary", Rect2(76, 438, 236, 142), String(current_model.get("boundary", "")), 14, PresentationTheme.color_for_key(&"ui.muted"))


func _build_content_panel() -> void:
	tab_title_label = _add_label(self, "DeployTabTitle", Rect2(404, 112, 416, 36), "", 24, PresentationTheme.color_for_key(&"ui.accent"))
	tab_body_label = _add_label(self, "DeployTabBody", Rect2(406, 168, 414, 254), "", 17, PresentationTheme.text_color())
	_add_label(self, "DeployConfigPreviewHeading", Rect2(406, 450, 390, 24), "RunStartConfig preview", 16, PresentationTheme.color_for_key(&"ui.warning"))
	preview_label = _add_label(self, "DeployConfigPreview", Rect2(406, 482, 420, 116), "", 13, PresentationTheme.color_for_key(&"ui.muted"))


func _build_summary_panel() -> void:
	_add_label(self, "DeploySummaryHeading", Rect2(930, 106, 240, 30), "右侧出勤准备", 20, PresentationTheme.color_for_key(&"ui.accent"))
	summary_label = _add_label(self, "DeploySummaryText", Rect2(930, 154, 250, 82), "", 14, PresentationTheme.text_color())
	config_label = _add_label(self, "DeployConfigText", Rect2(930, 250, 250, 88), "", 14, PresentationTheme.text_color())
	effect_label = _add_label(self, "DeployEffectText", Rect2(930, 352, 250, 88), "", 14, PresentationTheme.text_color())
	risk_label = _add_label(self, "DeployRiskText", Rect2(930, 454, 250, 104), "", 14, PresentationTheme.text_color())


func _build_action_panel() -> void:
	var start_action := _action("start")
	var start_button := _add_button(self, "DeployStartPreviewButton", Rect2(930, 574, 254, 38), String(start_action.get("label", "生成出勤预览")), _on_start_preview_pressed)
	start_button.tooltip_text = String(start_action.get("tooltip", ""))
	var continue_button := _add_button(self, "DeployContinuePlaceholderButton", Rect2(930, 620, 122, 36), "继续探索", _on_placeholder_action_pressed)
	continue_button.disabled = true
	continue_button.tooltip_text = "继续探索后置，当前仅预留入口。"
	var abandon_button := _add_button(self, "DeployAbandonPlaceholderButton", Rect2(1062, 620, 122, 36), "放弃探索", _on_placeholder_action_pressed)
	abandon_button.disabled = true
	abandon_button.tooltip_text = "放弃探索结算后置，当前不执行。"


func _refresh_view() -> void:
	if current_model.is_empty() or tab_title_label == null:
		return
	var active_tab := StringName(current_model.get("active_tab", DeployTabModelScript.DEFAULT_TAB))
	var tab := DeployTabModelScript.find_tab(active_tab)
	for tab_id in tab_buttons.keys():
		var button := tab_buttons[tab_id] as Button
		if button != null:
			button.disabled = StringName(tab_id) == active_tab
	tab_title_label.text = "%s / %s" % [String(tab.get("label", active_tab)), String(tab.get("subtitle", ""))]
	tab_body_label.text = _lines_text(_array_from(tab, "lines"))
	var preview := _preview()
	summary_label.text = _section_text("摘要", _array_from(preview, "summary"))
	config_label.text = _section_text("配置", _array_from(preview, "config"))
	effect_label.text = _section_text("效果", _array_from(preview, "effect"))
	risk_label.text = _section_text("风险", _array_from(preview, "risk"))
	preview_label.text = JSON.stringify(DeployConfigScript.build_run_start_config(_config()), "\t")


func _on_start_preview_pressed() -> void:
	var config := _config()
	current_model["run_start_config"] = DeployConfigScript.build_run_start_config(config)
	current_model["preview_lines"] = DeployConfigScript.build_preview_lines(config)
	_refresh_view()
	var intent := NavigationIntentScript.make_deploy(
		&"deploy_prep",
		{
			"preview_only": true,
			"deploy_start_intent": true,
			"config": current_model.get("run_start_config", {}),
		}
	)
	deploy_start_intent_requested.emit(intent)


func _on_placeholder_action_pressed() -> void:
	pass


func _config() -> Dictionary:
	var raw: Variant = current_model.get("config", {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return DeployConfigScript.default_config()


func _preview() -> Dictionary:
	var raw: Variant = current_model.get("preview_lines", {})
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return DeployConfigScript.build_preview_lines(_config())


func _action(action_id: String) -> Dictionary:
	var actions: Variant = current_model.get("actions", {})
	if actions is Dictionary:
		var action: Variant = (actions as Dictionary).get(action_id, {})
		if action is Dictionary:
			return action as Dictionary
	return {}


func _section_text(title: String, lines: Array) -> String:
	return "%s\n%s" % [title, _lines_text(lines)]


func _lines_text(lines: Array) -> String:
	var parts := []
	for line in lines:
		parts.append("- %s" % String(line))
	return "\n".join(parts)


func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


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
