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
var filter_buttons: Array[Button] = []
var card_buttons: Array[Button] = []
var tab_title_label: Label
var tab_body_label: Label
var filter_heading_label: Label
var card_heading_label: Label
var card_scroll: ScrollContainer
var card_list_container: VBoxContainer
var detail_label: Label
var summary_label: Label
var config_label: Label
var effect_label: Label
var risk_label: Label
var preview_label: Label
var action_message_label: Label
var start_button: Button
var continue_button: Button
var abandon_button: Button


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
	filter_buttons.clear()
	card_buttons.clear()
	tab_title_label = null
	tab_body_label = null
	filter_heading_label = null
	card_heading_label = null
	card_scroll = null
	card_list_container = null
	detail_label = null
	summary_label = null
	config_label = null
	effect_label = null
	risk_label = null
	preview_label = null
	action_message_label = null
	start_button = null
	continue_button = null
	abandon_button = null


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
			var captured_tab := tab_id
			button.pressed.connect(func() -> void: show_tab(captured_tab))
			add_child(button)
			tab_buttons[tab_id] = button
			y += 52.0
	_add_label(self, "DeployBoundary", Rect2(76, 438, 236, 142), String(current_model.get("boundary", "")), 14, PresentationTheme.color_for_key(&"ui.muted"))


func _build_content_panel() -> void:
	tab_title_label = _add_label(self, "DeployTabTitle", Rect2(404, 104, 416, 34), "", 23, PresentationTheme.color_for_key(&"ui.accent"))
	tab_body_label = _add_label(self, "DeployTabBody", Rect2(406, 144, 414, 92), "", 14, PresentationTheme.text_color())
	filter_heading_label = _add_label(self, "DeployFilterHeading", Rect2(406, 246, 420, 24), "二级标签 / 筛选 preview", 15, PresentationTheme.color_for_key(&"ui.warning"))
	card_heading_label = _add_label(self, "DeployCardHeading", Rect2(406, 320, 420, 24), "出勤内容卡片 preview", 15, PresentationTheme.color_for_key(&"ui.warning"))
	card_scroll = ScrollContainer.new()
	card_scroll.name = "DeployCardScroll"
	card_scroll.offset_left = 406.0
	card_scroll.offset_top = 350.0
	card_scroll.offset_right = 604.0
	card_scroll.offset_bottom = 520.0
	card_scroll.clip_contents = true
	add_child(card_scroll)
	card_list_container = VBoxContainer.new()
	card_list_container.name = "DeployCardList"
	card_list_container.add_theme_constant_override("separation", 6)
	card_scroll.add_child(card_list_container)
	detail_label = _add_label(self, "DeployCardDetail", Rect2(622, 350, 214, 170), "", 13, PresentationTheme.text_color())
	_add_label(self, "DeployConfigPreviewHeading", Rect2(406, 538, 390, 24), "RunStartConfig draft / read_only", 15, PresentationTheme.color_for_key(&"ui.warning"))
	preview_label = _add_label(self, "DeployConfigPreview", Rect2(406, 566, 420, 42), "", 12, PresentationTheme.color_for_key(&"ui.muted"))


func _build_summary_panel() -> void:
	_add_label(self, "DeploySummaryHeading", Rect2(930, 106, 240, 30), "右侧摘要 / 配置 / 效果 / 风险", 20, PresentationTheme.color_for_key(&"ui.accent"))
	summary_label = _add_label(self, "DeploySummaryText", Rect2(930, 146, 250, 92), "", 13, PresentationTheme.text_color())
	config_label = _add_label(self, "DeployConfigText", Rect2(930, 248, 250, 92), "", 13, PresentationTheme.text_color())
	effect_label = _add_label(self, "DeployEffectText", Rect2(930, 350, 250, 92), "", 13, PresentationTheme.text_color())
	risk_label = _add_label(self, "DeployRiskText", Rect2(930, 452, 250, 104), "", 13, PresentationTheme.text_color())


func _build_action_panel() -> void:
	start_button = _add_button(self, "DeployStartPreviewButton", Rect2(930, 568, 254, 34), "开始探索 preview", _on_start_preview_pressed)
	continue_button = _add_button(self, "DeployContinuePreviewButton", Rect2(930, 610, 122, 34), "继续 preview", _on_continue_preview_pressed)
	abandon_button = _add_button(self, "DeployAbandonPreviewButton", Rect2(1062, 610, 122, 34), "放弃 preview", _on_abandon_preview_pressed)
	action_message_label = _add_label(self, "DeployActionMessage", Rect2(930, 652, 254, 42), "", 12, PresentationTheme.color_for_key(&"ui.muted"))


func _refresh_view() -> void:
	if current_model.is_empty() or tab_title_label == null:
		return
	var active_tab := StringName(current_model.get("active_tab", DeployTabModelScript.DEFAULT_TAB))
	var tab := _dictionary_from(current_model.get("active_tab_data", DeployTabModelScript.find_tab(active_tab)))
	for tab_id in tab_buttons.keys():
		var button := tab_buttons[tab_id] as Button
		if button != null:
			button.disabled = StringName(tab_id) == active_tab
	tab_title_label.text = "%s / %s" % [String(tab.get("label", active_tab)), String(tab.get("subtitle", ""))]
	tab_body_label.text = _lines_text(_array_from(tab, "lines"))
	_refresh_filter_buttons(tab)
	_refresh_card_buttons()
	_refresh_detail()
	var preview := _preview()
	summary_label.text = _section_text("摘要", _array_from(preview, "summary"), 3)
	config_label.text = _section_text("配置", _array_from(preview, "config"), 3)
	effect_label.text = _section_text("效果", _array_from(preview, "effect"), 3)
	risk_label.text = _section_text("风险", _array_from(preview, "risk"), 4)
	preview_label.text = _run_start_preview_text(DeployConfigScript.build_run_start_config(_config()))
	_refresh_actions()


func _refresh_filter_buttons(tab: Dictionary) -> void:
	for button in filter_buttons:
		if button != null:
			remove_child(button)
			button.queue_free()
	filter_buttons.clear()
	var x := 406.0
	var y := 276.0
	var selected_filter := StringName(current_model.get("selected_filter", DeployTabModelScript.FILTER_ALL))
	for raw_filter in _array_from(tab, "secondary_filters"):
		if raw_filter is Dictionary:
			var filter := raw_filter as Dictionary
			var filter_id := StringName(filter.get("id", DeployTabModelScript.FILTER_ALL))
			var captured_filter := filter_id
			var button := _add_button(self, "DeployFilter_%s" % String(filter_id), Rect2(x, y, 92, 28), String(filter.get("label", filter_id)), func() -> void: _on_filter_pressed(captured_filter))
			button.disabled = filter_id == selected_filter
			filter_buttons.append(button)
			x += 98.0
			if x > 760.0:
				x = 406.0
				y += 32.0


func _refresh_card_buttons() -> void:
	for button in card_buttons:
		if button != null:
			if button.get_parent() != null:
				button.get_parent().remove_child(button)
			button.queue_free()
	card_buttons.clear()
	if card_list_container == null:
		return
	var selected_card := StringName(current_model.get("selected_card", &""))
	for raw_card in _array_from(current_model, "visible_cards"):
		if raw_card is Dictionary:
			var card := raw_card as Dictionary
			var card_id := StringName(card.get("id", &""))
			var label := "%s\n%s / %s" % [String(card.get("title", card_id)), String(card.get("category", "")), String(card.get("state", &"preview"))]
			var captured_card := card_id
			var button := Button.new()
			button.name = "DeployCard_%s" % String(card_id)
			button.text = label
			button.tooltip_text = String(card.get("summary", ""))
			button.custom_minimum_size = Vector2(180, 44)
			button.clip_text = true
			button.pressed.connect(func() -> void: _on_card_pressed(captured_card))
			card_list_container.add_child(button)
			button.disabled = card_id == selected_card
			card_buttons.append(button)


func _refresh_detail() -> void:
	var detail := _dictionary_from(current_model.get("selected_card_detail", {}))
	if detail.is_empty():
		detail_label.text = "卡片详情\n- 当前筛选下没有可显示卡片。"
		return
	var lines := [
		"状态：%s / preview=%s / display_only=%s / read_only=%s" % [
			String(detail.get("state", "preview")),
			str(bool(detail.get("preview", true))),
			str(bool(detail.get("display_only", true))),
			str(bool(detail.get("read_only", true))),
		],
		String(detail.get("summary", "")),
		String(detail.get("detail", "")),
	]
	for line in _array_from(detail, "lines"):
		lines.append(String(line))
	var links := _array_from(detail, "link_preview")
	if not links.is_empty():
		lines.append("只读跳转：%s" % _join_array(links, "无"))
	detail_label.text = _section_text("卡片详情", lines, 6)


func _refresh_actions() -> void:
	var start_action := _action("start")
	var continue_action := _action("continue")
	var abandon_action := _action("abandon")
	start_button.text = String(start_action.get("label", "生成出勤 preview"))
	start_button.disabled = bool(start_action.get("disabled", false))
	start_button.tooltip_text = String(start_action.get("tooltip", ""))
	continue_button.text = String(continue_action.get("label", "继续探索"))
	continue_button.disabled = bool(continue_action.get("disabled", true))
	continue_button.tooltip_text = String(continue_action.get("tooltip", ""))
	abandon_button.text = String(abandon_action.get("label", "放弃探索"))
	abandon_button.disabled = bool(abandon_action.get("disabled", true))
	abandon_button.tooltip_text = String(abandon_action.get("tooltip", ""))
	var message := String(current_model.get("action_message", ""))
	if bool(current_model.get("abandon_confirm_visible", false)):
		message = String(abandon_action.get("confirm_copy", "强确认 preview：再次点击只会关闭提示，不执行放弃。"))
	action_message_label.text = message


func _on_filter_pressed(filter_id: StringName) -> void:
	current_model = DeployPrepModelScript.model_with_filter(current_model, filter_id)
	_refresh_view()


func _on_card_pressed(card_id: StringName) -> void:
	current_model = DeployPrepModelScript.model_with_card(current_model, card_id)
	_refresh_view()


func _on_start_preview_pressed() -> void:
	var config := _config()
	current_model["run_start_config"] = DeployConfigScript.build_run_start_config(config)
	current_model["preview_lines"] = DeployConfigScript.build_preview_lines(config)
	current_model["action_message"] = "开始探索 preview 已刷新；完整出发配置启动未接入。请从主菜单“快速开始 / Demo Run”进入当前可玩探索。"
	_refresh_view()
	var start_action := _action("start")
	var run_payload := _dictionary_from(start_action.get("run_intent", {}))
	run_payload["source_page"] = &"deploy_prep"
	run_payload["preview_only"] = false
	run_payload["run_start_config_preview"] = current_model.get("run_start_config", {})
	run_payload["boundary"] = "existing_run_route_only_no_run_bootstrapper"
	var intent := NavigationIntentScript.make_run(&"deploy_prep", run_payload)
	deploy_start_intent_requested.emit(intent)


func _on_continue_preview_pressed() -> void:
	current_model = DeployPrepModelScript.model_with_action_message(current_model, "继续探索入口仅为 preview / read_only；真实继续流程后置。")
	_refresh_view()


func _on_abandon_preview_pressed() -> void:
	if bool(current_model.get("abandon_confirm_visible", false)):
		current_model = DeployPrepModelScript.model_with_action_message(current_model, "已关闭放弃强确认 preview；没有执行放弃。", false)
	else:
		current_model = DeployPrepModelScript.model_with_action_message(current_model, "放弃当前探索需要强确认 preview；本轮不执行真实放弃。", true)
	_refresh_view()


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


func _section_text(title: String, lines: Array, max_lines: int = 4) -> String:
	return "%s\n%s" % [title, _lines_text(lines, max_lines)]


func _lines_text(lines: Array, max_lines: int = 6) -> String:
	var parts := []
	var visible := lines.slice(0, max_lines)
	for line in visible:
		parts.append("- %s" % String(line))
	if lines.size() > visible.size():
		parts.append("- 还有 %d 项 preview 已收起" % (lines.size() - visible.size()))
	return "\n".join(parts)


func _run_start_preview_text(run_start: Dictionary) -> String:
	return "id=%s  bag=%d/%d  seed=%s  projection=%s" % [
		String(run_start.get("config_id", "")),
		int(run_start.get("bag_used", 0)),
		int(run_start.get("bag_limit", 0)),
		String(run_start.get("seed_policy", "")),
		String((_dictionary_from(run_start.get("deploy_prep_projection", {}))).get("projection_type", &"")),
	]


func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _join_array(items: Array, fallback: String) -> String:
	if items.is_empty():
		return fallback
	var parts := []
	for item in items:
		parts.append(String(item))
	return "、".join(parts)


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
	label.clip_text = true
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
