extends Control
class_name DeployPrepShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const DeployPrepModelScript := preload("res://scripts/ui/deploy_prep/deploy_prep_model.gd")
const DeployTabModelScript := preload("res://scripts/ui/deploy_prep/deploy_tab_model.gd")
const RunStartRouteAdapterScript := preload("res://scripts/core/run/run_start_route_adapter.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")

signal deploy_start_intent_requested(intent: Dictionary)
signal navigation_intent_requested(intent: Dictionary)

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
	_normalize_static_copy()
	_apply_layer_order()
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


func _apply_layer_order() -> void:
	_establish_page_layer_roots()
	for root_name_variant in UILayerContractScript.PAGE_ROOT_ORDER:
		var root_name := StringName(root_name_variant)
		var root := get_node_or_null(String(root_name)) as Control
		if root == null:
			continue
		UILayerContractScript.configure_root(root, UILayerContractScript.page_root_role(root_name))
		for child in root.get_children():
			UILayerContractScript.apply_local_layer(child, _local_layer_for_node(child, root_name))


func _layer_for_node(node: Node) -> int:
	return UILayerContractScript.layer_for_page_node(node)


func _establish_page_layer_roots() -> void:
	for root_name_variant in UILayerContractScript.PAGE_ROOT_ORDER:
		var root_name := StringName(root_name_variant)
		UILayerContractScript.ensure_root(self, root_name, UILayerContractScript.page_root_role(root_name))
	for child in get_children().duplicate():
		if UILayerContractScript.is_page_root_name(StringName(child.name)):
			continue
		var target_root_name := UILayerContractScript.page_root_for_node(child)
		var target_root := get_node_or_null(String(target_root_name)) as Control
		if target_root == null:
			continue
		remove_child(child)
		target_root.add_child(child)
	for root_name_variant in UILayerContractScript.PAGE_ROOT_ORDER:
		var root_name := StringName(root_name_variant)
		var root := get_node_or_null(String(root_name)) as Control
		if root != null and root.get_parent() == self:
			move_child(root, get_child_count() - 1)


func _local_layer_for_node(node: Node, root_name: StringName) -> int:
	var root_layer := UILayerContractScript.layer(UILayerContractScript.page_root_role(root_name))
	return maxi(0, _layer_for_node(node) - root_layer)


func _build_backdrop() -> void:
	_add_color_rect(self, "DeployPrepBackdrop", Rect2(0, 0, 1280, 720), Color(0.016, 0.032, 0.038, 1.0))
	_add_texture_rect_from_ref(self, "DeployPrepRoomBackground", Rect2(0, 0, 1280, 720), Art09ManifestAssetMappingScript.asset_ref(&"room.background.normal", &"room.background.normal", &"room_background", &"deploy"), 0.52)
	_add_color_rect(self, "DeployPrepBackdropShade", Rect2(0, 0, 1280, 720), Color(0.0, 0.0, 0.0, 0.18))
	_add_color_rect(self, "DeployControlRoomGlow", Rect2(32, 88, 1206, 596), Color(0.10, 0.26, 0.30, 0.08))
	_add_color_rect(self, "DeployConsoleHorizon", Rect2(340, 150, 590, 3), Art10UISkinKitScript.color(&"accent"))
	_add_color_rect(self, "DeployMapGridA", Rect2(86, 258, 178, 2), Color(0.58, 0.93, 0.76, 0.24))
	_add_color_rect(self, "DeployMapGridB", Rect2(86, 336, 178, 2), Color(0.58, 0.93, 0.76, 0.16))
	_add_color_rect(self, "DeployMapGridC", Rect2(174, 232, 2, 190), Color(0.58, 0.93, 0.76, 0.16))
	_add_panel(self, "DeployLeftVisualFrame", Art10UISkinKitScript.rect(&"deploy", "left_column"), &"deep")
	_add_panel(self, "DeployCenterCardFrame", Art10UISkinKitScript.rect(&"deploy", "center_column"), &"surface")
	_add_panel(self, "DeploySummaryFrame", Art10UISkinKitScript.rect(&"deploy", "summary_column"), &"summary")
	var art09_refs := _art09_asset_refs()
	_add_texture_rect_from_ref(self, "Art19DeployMainPanel", Rect2(340, 160, 590, 380), Art09ManifestAssetMappingScript.art19_skin_ref(&"panel_deploy_main"), 0.60)
	_add_texture_rect_from_ref(self, "Art19DeploySummaryPanel", Rect2(952, 88, 286, 396), Art09ManifestAssetMappingScript.art19_skin_ref(&"panel_summary"), 0.68)
	_add_color_rect(self, "DeployMapAtmosphere", Rect2(64, 206, 226, 286), Color(0.12, 0.20, 0.19, 0.26))
	_add_color_rect(self, "DeployCharacterReadiness", Rect2(74, 176, 186, 330), Color(0.54, 0.84, 0.68, 0.08))
	_add_color_rect(self, "DeployCharacterSilhouette", Rect2(112, 222, 94, 214), Color(0.16, 0.24, 0.22, 0.44))
	_add_texture_rect_from_ref(self, "DeployPlayerSprite", Rect2(70, 202, 184, 206), Art09ManifestAssetMappingScript.player_sprite_ref(&"idle"), 1.0)
	_add_color_rect(self, "DeployMapHorizon", Rect2(72, 452, 204, 3), Art10UISkinKitScript.color(&"gold"))
	_add_label_token(self, "DeployPrepTitle", Rect2(46, 34, 250, 48), "出发探索", &"page_title", &"warning")
	_add_label_token(self, "DeployPrepSubtitle", Rect2(304, 36, 620, 32), "", &"body", &"caption")
	_add_button(self, "DeployNavMainButton", Rect2(46, 86, 104, 34), "主菜单", Callable(self, "_request_back_to_main"))
	_add_button(self, "DeployNavLongTermButton", Rect2(160, 86, 120, 34), "长期系统", Callable(self, "_request_long_term"))
	_trim_intro_copy()


func _request_back_to_main() -> void:
	navigation_intent_requested.emit(NavigationIntentScript.make(
		NavigationIntentScript.TARGET_MAIN_MENU,
		&"deploy_prep",
		{"source_page": &"deploy_prep"}
	))


func _request_long_term() -> void:
	navigation_intent_requested.emit(NavigationIntentScript.make_long_term(
		&"deploy_prep",
		&"goals",
		{"source_page": &"deploy_prep", "preview_only": false}
	))


func _build_tab_panel() -> void:
	var tab_row := HBoxContainer.new()
	tab_row.name = "DeployTopTabRow"
	_set_rect(tab_row, Art10UISkinKitScript.rect(&"deploy", "tab_row"))
	tab_row.add_theme_constant_override("separation", 6)
	add_child(tab_row)
	for raw_tab in _array_from(current_model, "tabs"):
		if raw_tab is Dictionary:
			var tab := raw_tab as Dictionary
			var tab_id := StringName(tab.get("id", DeployTabModelScript.DEFAULT_TAB))
			var button := Button.new()
			button.name = "DeployTab_%s" % String(tab_id)
			button.text = String(tab.get("label", tab_id))
			button.tooltip_text = String(tab.get("subtitle", ""))
			button.toggle_mode = true
			button.custom_minimum_size = Vector2(100, 42)
			_apply_art09_button_icon(button, _dictionary_from(tab.get("art09_asset_ref", {})), &"tab")
			var captured_tab := tab_id
			button.pressed.connect(func() -> void: show_tab(captured_tab))
			Art10UISkinKitScript.apply_button_token(button, &"secondary", &"tab", &"tab")
			tab_row.add_child(button)
			tab_buttons[tab_id] = button


func _trim_intro_copy() -> void:
	var subtitle := get_node_or_null("DeployPrepSubtitle") as Label
	if subtitle != null:
		subtitle.text = ""


func _build_content_panel() -> void:
	_add_label_token(self, "DeployLeftHeading", Rect2(66, 154, 220, 26), "探索整备", &"tab", &"accent")
	tab_body_label = _add_label_token(self, "DeployTabBody", Rect2(66, 486, 224, 42), "", &"body_small", &"text")
	_add_label_token(self, "DeployLoadoutHeading", Rect2(66, 554, 220, 22), "携带槽", &"caption", &"muted")
	_add_icon_slot(self, "DeployLoadoutSlotA", Rect2(66, 580, 48, 48), "装备")
	_add_icon_slot(self, "DeployLoadoutSlotB", Rect2(124, 580, 48, 48), "药剂")
	_add_icon_slot(self, "DeployLoadoutSlotC", Rect2(182, 580, 48, 48), "工具")
	tab_title_label = _add_label_token(self, "DeployTabTitle", Rect2(340, 154, 300, 30), "", &"section_title", &"accent")
	filter_heading_label = _add_label_token(self, "DeployFilterHeading", Rect2(372, 110, 52, 24), "筛选", &"caption", &"warning")
	card_heading_label = _add_label_token(self, "DeployCardHeading", Rect2(350, 192, 240, 24), "路线 / 目标", &"tab", &"warning")
	card_heading_label.text = "路线 / 目标"
	_add_color_rect(self, "DeployRouteMapPlateA", Rect2(362, 228, 148, 58), Color(0.58, 0.93, 0.76, 0.055))
	_add_color_rect(self, "DeployRouteMapPlateB", Rect2(518, 306, 164, 54), Color(0.94, 0.70, 0.28, 0.055))
	_add_color_rect(self, "DeployRouteMapPlateC", Rect2(692, 390, 148, 58), Color(0.58, 0.93, 0.76, 0.045))
	card_scroll = ScrollContainer.new()
	card_scroll.name = "DeployCardScroll"
	_set_rect(card_scroll, Rect2(350, 222, 548, 292))
	card_scroll.clip_contents = true
	add_child(card_scroll)
	card_list_container = VBoxContainer.new()
	card_list_container.name = "DeployCardList"
	card_list_container.add_theme_constant_override("separation", 8)
	card_scroll.add_child(card_list_container)
	_add_panel(self, "DeployDetailFrame", Art10UISkinKitScript.rect(&"deploy", "center_detail"), &"card")
	detail_label = _add_label_token(self, "DeployCardDetail", Rect2(356, 566, 560, 50), "", &"body_small", &"text")
	preview_label = _add_label_token(self, "DeployConfigPreview", Rect2(356, 620, 560, 20), "", &"caption", &"muted")
	_add_label_token(self, "DeployLeftStatus", Rect2(66, 548, 220, 36), "整备完成", &"caption", &"muted")
	for node_name in [
		"DeployLoadoutHeading",
		"DeployLoadoutSlotA",
		"DeployLoadoutSlotB",
		"DeployLoadoutSlotC",
		"DeployLoadoutSlotALabel",
		"DeployLoadoutSlotBLabel",
		"DeployLoadoutSlotCLabel",
	]:
		var node := get_node_or_null(node_name)
		if node is CanvasItem:
			(node as CanvasItem).visible = false


func _build_summary_panel() -> void:
	_add_label_token(self, "DeploySummaryHeading", Rect2(970, 104, 236, 30), "出发摘要", &"tab", &"accent")
	_add_panel(self, "DeploySummaryBlockA", Rect2(964, 138, 256, 54), &"card")
	_add_panel(self, "DeploySummaryBlockB", Rect2(964, 198, 256, 54), &"card")
	_add_panel(self, "DeploySummaryBlockC", Rect2(964, 352, 256, 50), &"card")
	_add_panel(self, "DeploySummaryBlockD", Rect2(964, 410, 256, 50), &"warning")
	summary_label = _add_label_token(self, "DeploySummaryText", Rect2(976, 146, 232, 38), "", &"body_small", &"text")
	config_label = _add_label_token(self, "DeployConfigText", Rect2(976, 206, 232, 38), "", &"body_small", &"text")
	_add_label_token(self, "DeploySlotHeading", Rect2(976, 270, 232, 22), "装备 / 消耗品", &"caption", &"warning")
	_add_icon_slot(self, "DeployEquipSlotA", Rect2(976, 298, 50, 50), "武器")
	_add_icon_slot(self, "DeployEquipSlotB", Rect2(1036, 298, 50, 50), "护具")
	_add_icon_slot(self, "DeployItemSlotA", Rect2(1096, 298, 50, 50), "补给")
	_add_icon_slot(self, "DeployItemSlotB", Rect2(1156, 298, 50, 50), "钥匙")
	effect_label = _add_label_token(self, "DeployEffectText", Rect2(976, 358, 232, 38), "", &"body_small", &"text")
	risk_label = _add_label_token(self, "DeployRiskText", Rect2(976, 416, 232, 38), "", &"caption", &"warning")
	_compact_summary_column()


func _build_action_panel() -> void:
	_add_color_rect(self, "DeployStartButtonGlow", Rect2(948, 584, 298, 104), Color(0.94, 0.70, 0.28, 0.14))
	var art09_refs := _art09_asset_refs()
	_add_texture_rect_from_ref(self, "Art19DeployStartButtonTexture", Rect2(958, 602, 278, 76), Art09ManifestAssetMappingScript.art19_skin_ref(&"button_confirm"), 0.88)
	start_button = _add_button(self, "DeployStartButton", Rect2(958, 610, 278, 72), "开始探索", _on_start_preview_pressed)
	continue_button = _add_button(self, "DeployContinueButton", Rect2(966, 548, 126, 42), "继续", _on_continue_preview_pressed)
	abandon_button = _add_button(self, "DeployAbandonButton", Rect2(1102, 548, 126, 42), "终止", _on_abandon_preview_pressed)
	action_message_label = _add_label_token(self, "DeployActionMessage", Rect2(630, 642, 304, 38), "", &"caption", &"muted")
	_set_rect(start_button, Rect2(958, 610, 278, 72))
	_set_rect(continue_button, Rect2(966, 548, 126, 42))
	_set_rect(abandon_button, Rect2(1102, 548, 126, 42))
	_set_rect(action_message_label, Rect2(362, 640, 520, 38))
	continue_button.text = "继续"
	abandon_button.text = "终止"


func _compact_summary_column() -> void:
	var rects := {
		"DeploySummaryHeading": Rect2(970, 104, 236, 30),
		"DeploySummaryBlockA": Rect2(964, 138, 256, 54),
		"DeploySummaryBlockB": Rect2(964, 198, 256, 54),
		"DeploySummaryBlockC": Rect2(964, 352, 256, 50),
		"DeploySummaryBlockD": Rect2(964, 410, 256, 50),
		"DeploySummaryText": Rect2(976, 146, 232, 38),
		"DeployConfigText": Rect2(976, 206, 232, 38),
		"DeploySlotHeading": Rect2(976, 270, 232, 22),
		"DeployEquipSlotA": Rect2(976, 298, 50, 50),
		"DeployEquipSlotB": Rect2(1036, 298, 50, 50),
		"DeployItemSlotA": Rect2(1096, 298, 50, 50),
		"DeployItemSlotB": Rect2(1156, 298, 50, 50),
		"DeployEquipSlotALabel": Rect2(976, 351, 50, 16),
		"DeployEquipSlotBLabel": Rect2(1036, 351, 50, 16),
		"DeployItemSlotALabel": Rect2(1096, 351, 50, 16),
		"DeployItemSlotBLabel": Rect2(1156, 351, 50, 16),
		"DeployEffectText": Rect2(976, 358, 232, 38),
		"DeployRiskText": Rect2(976, 416, 232, 38),
	}
	for node_name in rects.keys():
		var node := get_node_or_null(String(node_name)) as Control
		if node != null:
			_set_rect(node, rects[node_name])


func _refresh_view() -> void:
	if current_model.is_empty() or tab_title_label == null:
		return
	var active_tab := StringName(current_model.get("active_tab", DeployTabModelScript.DEFAULT_TAB))
	var tab := _dictionary_from(current_model.get("active_tab_data", DeployTabModelScript.find_tab(active_tab)))
	for tab_id in tab_buttons.keys():
		var button := tab_buttons[tab_id] as Button
		if button != null:
			var selected := StringName(tab_id) == active_tab
			button.button_pressed = selected
			Art10UISkinKitScript.apply_button_token(button, Art10UISkinKitScript.visual_state_tone(&"selected" if selected else &"normal"), &"tab", &"tab")
	tab_title_label.text = String(tab.get("label", active_tab))
	tab_body_label.text = _lines_text(_array_from(tab, "lines"), 1, 12)
	_refresh_filter_buttons(tab)
	_refresh_card_buttons()
	_refresh_detail()
	_apply_player_summary_copy()
	preview_label.text = _run_start_preview_text(DeployConfigScript.build_run_start_config(_config()))
	_refresh_actions()
	_normalize_static_copy()
	_apply_art10_text_refresh()
	_apply_layer_order()


func _apply_player_summary_copy() -> void:
	var detail := _dictionary_from(current_model.get("selected_card_detail", {}))
	var route_title := _shorten_copy(String(detail.get("summary", "标准探索")), 8)
	if route_title.is_empty():
		route_title = "标准探索"
	summary_label.text = "摘要\n%s" % route_title
	config_label.text = "配置\n地图已确认"
	effect_label.text = "效果\n装备本局生效"
	risk_label.text = "风险\n进入后确认"


func _normalize_static_copy() -> void:
	_set_label_text("DeployLeftHeading", "出勤角色")
	_set_label_text("DeployLoadoutHeading", "携带栏")
	_set_label_text("DeployLoadoutSlotALabel", "装备")
	_set_label_text("DeployLoadoutSlotBLabel", "药剂")
	_set_label_text("DeployLoadoutSlotCLabel", "工具")
	_set_label_text("DeployFilterHeading", "筛选")
	_set_label_text("DeployCardHeading", "路线 / 目标")
	_set_label_text("DeployLeftStatus", "整备完成")
	_set_label_text("DeploySummaryHeading", "出发摘要")
	_set_label_text("DeploySlotHeading", "装备 / 消耗品")
	_set_label_text("DeployEquipSlotALabel", "武器")
	_set_label_text("DeployEquipSlotBLabel", "护具")
	_set_label_text("DeployItemSlotALabel", "补给")
	_set_label_text("DeployItemSlotBLabel", "钥匙")
	_set_button_text("DeployStartButton", "开始探索")
	_set_button_text("DeployContinueButton", "继续")
	_set_button_text("DeployAbandonButton", "终止")
	_normalize_dynamic_summary_copy()


func _normalize_dynamic_summary_copy() -> void:
	var detail := _dictionary_from(current_model.get("selected_card_detail", {}))
	if summary_label != null:
		summary_label.text = "摘要\n普通房间"
	if config_label != null:
		config_label.text = "配置\n地图已确认"
	if effect_label != null:
		effect_label.text = "效果\n装备本局生效"
	if risk_label != null:
		risk_label.text = "风险\n进入后确认"
	if detail_label != null:
		detail_label.text = "详情\n普通房间 / 标准地图 / 进入后确认。"
	if action_message_label != null and action_message_label.text.strip_edges() != "":
		action_message_label.text = "出发操作已记录。"


func _route_card_button_text(card: Dictionary, state: StringName, selected: bool, index: int = 0) -> String:
	var route_names: Array[String] = ["普通房间", "路线扫描", "雾区规则", "已解锁区域", "撤离点"]
	var title: String = route_names[index % route_names.size()]
	var prefix: String = "◆" if selected else "◇"
	var state_text: String = Art10UISkinKitScript.status_label(state)
	return "%s  %s\n%s" % [prefix, title, state_text]


func _set_label_text(node_name: String, text: String) -> void:
	var node := get_node_or_null(node_name)
	if node is Label:
		(node as Label).text = text


func _set_button_text(node_name: String, text: String) -> void:
	var node := get_node_or_null(node_name)
	if node is Button:
		(node as Button).text = text


func _refresh_filter_buttons(tab: Dictionary) -> void:
	for button in filter_buttons:
		if button != null:
			if button.get_parent() != null:
				button.get_parent().remove_child(button)
			button.queue_free()
	filter_buttons.clear()
	var x := 424.0
	var y := 110.0
	var selected_filter := StringName(current_model.get("selected_filter", DeployTabModelScript.FILTER_ALL))
	for raw_filter in _array_from(tab, "secondary_filters"):
		if raw_filter is Dictionary:
			var filter := raw_filter as Dictionary
			var filter_id := StringName(filter.get("id", DeployTabModelScript.FILTER_ALL))
			var captured_filter := filter_id
			var button := _add_button(self, "DeployFilter_%s" % String(filter_id), Rect2(x, y, 68, 30), String(filter.get("label", filter_id)), func() -> void: _on_filter_pressed(captured_filter))
			button.toggle_mode = true
			button.button_pressed = filter_id == selected_filter
			Art10UISkinKitScript.apply_button_token(button, Art10UISkinKitScript.visual_state_tone(&"selected" if button.button_pressed else &"normal"), &"caption", &"tab")
			filter_buttons.append(button)
			x += 72.0


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
	var card_index := 0
	for raw_card in _array_from(current_model, "visible_cards"):
		if raw_card is Dictionary:
			var card := raw_card as Dictionary
			var card_id := StringName(card.get("id", &""))
			var state := StringName(card.get("state", &"preview"))
			var selected := card_id == selected_card
			var label := "%s  %s\n%s" % [
				"◆" if selected else "◇",
				_shorten_copy(String(card.get("title", card_id)), 14),
				Art10UISkinKitScript.status_label(state),
			]
			var captured_card := card_id
			var button := Button.new()
			button.name = "DeployCard_%s" % String(card_id)
			button.text = label
			button.text = _route_card_button_text(card, state, selected, card_index)
			button.tooltip_text = String(card.get("summary", ""))
			button.custom_minimum_size = Vector2(500, 88 if selected else 72)
			button.toggle_mode = true
			button.button_pressed = selected
			_apply_art09_button_icon(button, _dictionary_from(card.get("art09_asset_ref", {})), &"slot")
			Art10UISkinKitScript.apply_button_token(button, Art10UISkinKitScript.visual_state_tone(state, button.button_pressed), &"body", &"slot")
			button.pressed.connect(func() -> void: _on_card_pressed(captured_card))
			card_list_container.add_child(button)
			card_buttons.append(button)
			card_index += 1


func _refresh_detail() -> void:
	var detail := _dictionary_from(current_model.get("selected_card_detail", {}))
	if detail.is_empty():
		detail_label.text = "当前筛选下没有可显示卡片。"
		return
	var lines := [
		String(detail.get("summary", "")),
		String(detail.get("detail", "")),
	]
	for line in _array_from(detail, "lines").slice(0, 2):
		lines.append(String(line))
	detail_label.text = _section_text("详情", lines, 1, 12)


func _refresh_actions() -> void:
	var start_action := _action("start")
	var continue_action := _action("continue")
	var abandon_action := _action("abandon")
	start_button.text = "开始探索"
	start_button.disabled = bool(start_action.get("disabled", false))
	start_button.tooltip_text = String(start_action.get("tooltip", ""))
	continue_button.text = "继续"
	continue_button.disabled = bool(continue_action.get("disabled", true))
	continue_button.tooltip_text = String(continue_action.get("tooltip", ""))
	abandon_button.text = "终止"
	abandon_button.disabled = bool(abandon_action.get("disabled", true))
	abandon_button.tooltip_text = String(abandon_action.get("tooltip", ""))
	var art09_refs := _art09_asset_refs()
	_apply_art09_button_icon(start_button, _asset_ref_from(art09_refs, "buttons", "confirm"), &"large_nav")
	_apply_art09_button_icon(continue_button, _asset_ref_from(art09_refs, "buttons", "loadout"), &"button")
	_apply_art09_button_icon(abandon_button, _asset_ref_from(art09_refs, "buttons", "back_main"), &"button")
	Art10UISkinKitScript.apply_button_token(start_button, &"gold", &"main_button", &"large_nav")
	Art10UISkinKitScript.apply_button_token(continue_button, &"primary" if not continue_button.disabled else &"secondary", &"caption", &"button")
	Art10UISkinKitScript.apply_button_token(abandon_button, &"warning" if not abandon_button.disabled else &"danger", &"caption", &"button")
	continue_button.modulate = Color(1.0, 1.0, 1.0, 0.96)
	abandon_button.modulate = Color(1.0, 0.94, 0.84, 0.96)
	var message := String(current_model.get("action_message", ""))
	if bool(current_model.get("abandon_confirm_visible", false)):
		message = String(abandon_action.get("confirm_copy", "再次点击只会关闭提示，不执行放弃。"))
	action_message_label.text = message
	Art10UISkinKitScript.apply_label_token(action_message_label, &"caption", &"muted")


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
	current_model["action_message"] = "开始探索：已使用当前携带配置。"
	_refresh_view()
	var start_action := _action("start")
	var run_payload := _dictionary_from(start_action.get("run_intent", {}))
	run_payload["source_page"] = &"deploy_prep"
	run_payload["preview_only"] = false
	run_payload = RunStartRouteAdapterScript.payload_from_deploy_preview(current_model.get("run_start_config", {}), run_payload)
	var intent := NavigationIntentScript.make_run(&"deploy_prep", run_payload)
	deploy_start_intent_requested.emit(intent)


func _on_continue_preview_pressed() -> void:
	current_model = DeployPrepModelScript.model_with_action_message(current_model, "继续探索入口尚未开放到当前配置。")
	_refresh_view()


func _on_abandon_preview_pressed() -> void:
	if bool(current_model.get("abandon_confirm_visible", false)):
		current_model = DeployPrepModelScript.model_with_action_message(current_model, "已关闭放弃确认；没有执行放弃。", false)
	else:
		current_model = DeployPrepModelScript.model_with_action_message(current_model, "放弃当前探索需要确认；本轮不执行真实放弃。", true)
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


func _section_text(title: String, lines: Array, max_lines: int = 4, max_chars: int = 16) -> String:
	return Art10UISkinKitScript.readable_section_text(title, lines, min(max_lines, 2), max_chars)


func _lines_text(lines: Array, max_lines: int = 6, max_chars: int = 16) -> String:
	var parts := []
	var visible := lines.slice(0, max_lines)
	for line in visible:
		parts.append("- %s" % _shorten_copy(String(line), max_chars))
	if lines.size() > visible.size():
		parts.append("- 还有 %d 项已收起" % (lines.size() - visible.size()))
	return Art10UISkinKitScript.sanitize_player_copy("\n".join(parts))


func _run_start_preview_text(run_start: Dictionary) -> String:
	return Art10UISkinKitScript.sanitize_player_copy("出发整备 | 背包 %d/%d | 路线已确认" % [
		int(run_start.get("bag_used", 0)),
		int(run_start.get("bag_limit", 0)),
	])


func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _art09_asset_refs() -> Dictionary:
	var refs := _dictionary_from((_config()).get("art09_asset_refs", {}))
	var button_refs := _dictionary_from(refs.get("buttons", {}))
	var panel_refs := _dictionary_from(refs.get("panels", {}))
	if button_refs.has("confirm") and panel_refs.has("main"):
		return refs
	return Art09ManifestAssetMappingScript.deploy_prep_asset_refs()


func _asset_ref_from(source: Dictionary, group_id: String, entry_id: String) -> Dictionary:
	var group := _dictionary_from(source.get(group_id, {}))
	return _dictionary_from(group.get(entry_id, {}))


func _apply_art10_text_refresh() -> void:
	for label in [
		tab_title_label,
		tab_body_label,
		filter_heading_label,
		card_heading_label,
		detail_label,
		summary_label,
		config_label,
		effect_label,
		risk_label,
		preview_label,
		action_message_label,
	]:
		if label is Label:
			label.clip_text = false
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Art10UISkinKitScript.apply_label_token(tab_title_label, &"section_title", &"accent")
	Art10UISkinKitScript.apply_label_token(tab_body_label, &"body_small", &"text")
	Art10UISkinKitScript.apply_label_token(filter_heading_label, &"caption", &"warning")
	Art10UISkinKitScript.apply_label_token(card_heading_label, &"tab", &"warning")
	Art10UISkinKitScript.apply_label_token(detail_label, &"body_small", &"text")
	Art10UISkinKitScript.apply_label_token(summary_label, &"body_small", &"text")
	Art10UISkinKitScript.apply_label_token(config_label, &"body_small", &"text")
	Art10UISkinKitScript.apply_label_token(effect_label, &"body_small", &"text")
	Art10UISkinKitScript.apply_label_token(risk_label, &"caption", &"warning")
	Art10UISkinKitScript.apply_label_token(preview_label, &"caption", &"muted")
	Art10UISkinKitScript.apply_label_token(action_message_label, &"caption", &"muted")
	for button_id in tab_buttons.keys():
		var tab_button := tab_buttons[button_id] as Button
		Art10UISkinKitScript.apply_button_token(tab_button, Art10UISkinKitScript.visual_state_tone(&"selected" if tab_button != null and tab_button.button_pressed else &"normal"), &"tab", &"tab")
	for button in filter_buttons:
		Art10UISkinKitScript.apply_button_token(button, Art10UISkinKitScript.visual_state_tone(&"selected" if button != null and button.button_pressed else &"normal"), &"caption", &"tab")


func _apply_art09_button_icon(button: Button, asset_ref: Dictionary, icon_token: StringName = &"button") -> void:
	if button == null:
		return
	var texture := Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
	if texture == null:
		return
	button.icon = texture
	Art10UISkinKitScript.controlled_button_icon(button, icon_token)


func _add_texture_rect_from_ref(parent: Control, node_name: String, rect: Rect2, asset_ref: Dictionary, alpha: float = 1.0) -> TextureRect:
	var texture := Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
	if texture == null:
		return null
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.texture = texture
	_set_rect(texture_rect, rect)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.modulate = Color(1.0, 1.0, 1.0, alpha)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


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
	label.clip_text = false
	parent.add_child(label)
	return label


func _add_icon_slot(parent: Control, node_name: String, rect: Rect2, label_text: String) -> PanelContainer:
	var panel := Art10UISkinKitScript.make_icon_slot(node_name, rect.size, &"slot")
	_set_rect(panel, rect)
	parent.add_child(panel)
	var label := _add_label_token(parent, "%sLabel" % node_name, Rect2(rect.position.x, rect.position.y + rect.size.y + 3.0, rect.size.x, 16.0), label_text, &"key_prompt", &"muted")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return panel


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
