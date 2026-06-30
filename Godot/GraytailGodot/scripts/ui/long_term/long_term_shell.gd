extends Control
class_name LongTermShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const LongTermModelScript := preload("res://scripts/ui/long_term/long_term_model.gd")
const LongTermTabModelScript := preload("res://scripts/ui/long_term/long_term_tab_model.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")

signal navigation_intent_requested(intent: Dictionary)

var current_model: Dictionary = {}
var current_app_snapshot: Dictionary = {}
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
	_apply_layer_order()
	_refresh_from_model()


func apply_snapshot(snapshot: Dictionary) -> void:
	current_app_snapshot = snapshot.duplicate(true)
	current_model = LongTermModelScript.build_from_snapshot(selected_module_id, current_app_snapshot, &"app_shell_snapshot_preview")
	_refresh_from_model()


func show_module(module_id: StringName = &"goals") -> void:
	selected_module_id = module_id
	if selected_module_id == &"":
		selected_module_id = LongTermTabModelScript.default_module_id()
	current_model = LongTermModelScript.build_from_snapshot(selected_module_id, current_app_snapshot, &"app_shell_snapshot_preview")
	_refresh_from_model()


func get_selected_module_id() -> StringName:
	return selected_module_id


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


func _build_static_layout() -> void:
	_add_color_rect(self, "LongTermBackdrop", Rect2(0, 0, 1280, 720), Color(0.016, 0.030, 0.036, 1.0))
	_add_texture_rect_from_ref(self, "LongTermRoomBackground", Rect2(0, 0, 1280, 720), Art09ManifestAssetMappingScript.asset_ref(&"room.background.normal", &"room.background.normal", &"room_background", &"archive"), 0.50)
	_add_color_rect(self, "LongTermBackdropShade", Rect2(0, 0, 1280, 720), Color(0.0, 0.0, 0.0, 0.20))
	_add_color_rect(self, "LongTermArchiveRoomGlow", Rect2(38, 112, 1202, 548), Color(0.13, 0.18, 0.20, 0.20))
	_add_color_rect(self, "LongTermArchiveWall", Rect2(326, 130, 564, 514), Color(0.06, 0.09, 0.09, 0.28))
	_add_color_rect(self, "LongTermProfileMask", Rect2(60, 170, 228, 450), Color(0.0, 0.0, 0.0, 0.20))
	_add_color_rect(self, "LongTermDetailMask", Rect2(928, 142, 286, 476), Color(0.0, 0.0, 0.0, 0.26))
	_add_color_rect(self, "LongTermShelfLineA", Rect2(342, 248, 526, 2), Color(0.94, 0.70, 0.28, 0.26))
	_add_color_rect(self, "LongTermShelfLineB", Rect2(342, 386, 526, 2), Color(0.94, 0.70, 0.28, 0.18))
	_add_color_rect(self, "LongTermShelfLineC", Rect2(342, 524, 526, 2), Color(0.94, 0.70, 0.28, 0.14))
	_add_color_rect(self, "LongTermDetailLamp", Rect2(912, 106, 326, 4), Art10UISkinKitScript.color(&"gold"))
	_add_panel(self, "LongTermProfileColumn", Art10UISkinKitScript.rect(&"long_term", "profile_column"), &"deep")
	_add_panel(self, "LongTermCardGridColumn", Art10UISkinKitScript.rect(&"long_term", "card_grid"), &"surface")
	_add_panel(self, "LongTermDetailColumn", Art10UISkinKitScript.rect(&"long_term", "detail_column"), &"summary")
	_add_texture_rect_from_ref(self, "Art15LongTermProfileTexture", Art10UISkinKitScript.rect(&"long_term", "profile_column"), Art09ManifestAssetMappingScript.panel_ref(&"terminal"), 0.16)
	_add_texture_rect_from_ref(self, "Art15LongTermArchiveTexture", Art10UISkinKitScript.rect(&"long_term", "card_grid"), Art09ManifestAssetMappingScript.panel_ref(&"terminal"), 0.20)
	_add_texture_rect_from_ref(self, "Art15LongTermDetailTexture", Art10UISkinKitScript.rect(&"long_term", "detail_column"), Art09ManifestAssetMappingScript.panel_ref(&"protocol"), 0.18)
	_add_label_token(self, "LongTermTitle", Rect2(44, 32, 360, 48), "长期系统", &"page_title", &"accent")
	_add_label_token(self, "LongTermSubtitle", Rect2(44, 80, 700, 28), "档案、图鉴、研究与收藏。", &"body_small", &"muted")
	_add_button(self, "LongTermBackButton", Rect2(1084, 36, 154, 38), "返回主菜单", Callable(self, "_request_back_to_main"))
	_add_button(self, "LongTermNavMainButton", Rect2(44, 84, 104, 34), "主菜单", Callable(self, "_request_back_to_main"))
	_add_button(self, "LongTermNavDeployButton", Rect2(158, 84, 120, 34), "出发探索", Callable(self, "_request_deploy"))
	var subtitle := get_node_or_null("LongTermSubtitle") as Label
	if subtitle != null:
		subtitle.text = ""
	var legacy_back := get_node_or_null("LongTermBackButton") as Button
	if legacy_back != null:
		legacy_back.visible = false
	_build_tab_buttons()

	_add_label_token(self, "LongTermProfileHeading", Rect2(66, 154, 220, 24), "角色外观", &"tab", &"accent")
	_add_color_rect(self, "LongTermAvatarGlow", Rect2(66, 184, 184, 246), Color(0.58, 0.93, 0.76, 0.08))
	_add_color_rect(self, "LongTermAvatarSilhouette", Rect2(116, 228, 72, 150), Color(0.18, 0.27, 0.24, 0.84))
	_add_texture_rect_from_ref(self, "LongTermPlayerSprite", Rect2(70, 196, 176, 206), Art09ManifestAssetMappingScript.player_sprite_ref(&"idle"), 1.0)
	_add_color_rect(self, "LongTermAvatarBase", Rect2(92, 414, 138, 6), Art10UISkinKitScript.color(&"accent", Color(0.58, 0.93, 0.76, 1.0)))
	_add_button(self, "LongTermAppearanceButton", Rect2(74, 448, 176, 40), "设置外观", Callable(self, "_request_appearance_settings"))
	_add_color_rect(self, "LongTermArchiveDivider", Rect2(66, 514, 214, 2), Art10UISkinKitScript.color(&"accent"))
	overview_label = _add_label_token(self, "LongTermOverview", Rect2(66, 528, 214, 38), "", &"body_small", &"text")
	child_preview_label = _add_label_token(self, "LongTermChildPreview", Rect2(66, 574, 214, 32), "", &"caption", &"text")
	history_preview_label = _add_label_token(self, "LongTermHistoryPreview", Rect2(66, 614, 214, 26), "", &"caption", &"muted")

	_add_label_token(self, "LongTermGridHeading", Rect2(348, 126, 320, 28), "收藏与记录", &"tab", &"warning")
	card_grid_container = GridContainer.new()
	card_grid_container.name = "LongTermCardGrid"
	card_grid_container.columns = 3
	card_grid_container.add_theme_constant_override("h_separation", 10)
	card_grid_container.add_theme_constant_override("v_separation", 10)
	_set_rect(card_grid_container, Rect2(348, 164, 516, 456))
	add_child(card_grid_container)
	next_stage_label = _add_label_token(self, "LongTermNextStage", Rect2(348, 626, 516, 20), "", &"caption", &"muted")

	_add_panel(self, "LongTermDetailStatusBlock", Rect2(936, 120, 258, 58), &"surface")
	_add_panel(self, "LongTermDetailInfoBlock", Rect2(936, 186, 258, 74), &"deep")
	_add_panel(self, "LongTermDetailUnlockBlock", Rect2(936, 268, 258, 58), &"warning")
	_add_panel(self, "LongTermDetailLinkBlock", Rect2(936, 334, 258, 116), &"surface")
	module_title_label = _add_label_token(self, "LongTermModuleTitle", Rect2(940, 84, 250, 30), "", &"section_title", &"warning")
	module_state_label = _add_label_token(self, "LongTermModuleState", Rect2(950, 132, 230, 32), "", &"body_small", &"muted")
	module_body_label = _add_label_token(self, "LongTermModuleBody", Rect2(950, 198, 230, 44), "", &"body_small", &"text")
	module_reason_label = _add_label_token(self, "LongTermModuleReason", Rect2(950, 280, 230, 32), "", &"caption", &"warning")
	snapshot_label = _add_label_token(self, "LongTermSnapshotPreview", Rect2(950, 350, 230, 42), "", &"caption", &"text")
	interface_preview_label = _add_label_token(self, "LongTermInterfacePreview", Rect2(950, 404, 230, 28), "", &"caption", &"muted")
	_compact_detail_column()


func _compact_detail_column() -> void:
	var rects := {
		"LongTermDetailStatusBlock": Rect2(936, 120, 258, 58),
		"LongTermDetailInfoBlock": Rect2(936, 186, 258, 74),
		"LongTermDetailUnlockBlock": Rect2(936, 268, 258, 58),
		"LongTermDetailLinkBlock": Rect2(936, 334, 258, 116),
		"LongTermModuleTitle": Rect2(940, 84, 250, 30),
		"LongTermModuleState": Rect2(950, 132, 230, 32),
		"LongTermModuleBody": Rect2(950, 198, 230, 44),
		"LongTermModuleReason": Rect2(950, 280, 230, 32),
		"LongTermSnapshotPreview": Rect2(950, 350, 230, 42),
		"LongTermInterfacePreview": Rect2(950, 404, 230, 28),
	}
	for node_name in rects.keys():
		var node := get_node_or_null(String(node_name)) as Control
		if node != null:
			_set_rect(node, rects[node_name])


func _build_tab_buttons() -> void:
	tab_buttons.clear()
	var tab_row := HBoxContainer.new()
	tab_row.name = "LongTermTopTabRow"
	_set_rect(tab_row, Rect2(326, 78, 564, 48))
	tab_row.add_theme_constant_override("separation", 6)
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
		button.custom_minimum_size = Vector2(86, 40)
		button.pressed.connect(Callable(self, "_on_module_tab_pressed").bind(module_id))
		Art10UISkinKitScript.apply_button_token(button, &"secondary", &"tab", &"tab")
		tab_row.add_child(button)
		tab_buttons[module_id] = button


func _on_module_tab_pressed(module_id: StringName) -> void:
	show_module(module_id)


func _request_back_to_main() -> void:
	navigation_intent_requested.emit(NavigationIntentScript.make(
		NavigationIntentScript.TARGET_MAIN_MENU,
		&"long_term",
		{"source_page": &"long_term"}
	))


func _request_deploy() -> void:
	navigation_intent_requested.emit(NavigationIntentScript.make_deploy(
		&"long_term",
		{"tab": &"config", "source_page": &"long_term", "preview_only": false}
	))


func _request_appearance_settings() -> void:
	if overview_label != null:
		overview_label.text = "外观设置\n后续开放"


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
	var runtime_panel: Dictionary = current_model.get("profile_runtime_panel", {})
	history_preview_label.text = _format_history_preview(history_preview)
	if not runtime_panel.is_empty():
		history_preview_label.text += "\n%s" % _format_profile_runtime(runtime_panel)
	next_stage_label.text = "后续内容已收起到详情。"
	overview_label.text = "角色档案\n回收员 / 基地记录"
	child_preview_label.text = "当前模块\n%s" % _shorten_copy(String(panel.get("title", "")), 12)
	history_preview_label.text = "战绩\n探索记录已归档"
	module_title_label.text = "档案总览"
	module_state_label.text = "等级  01\n主线  已登记"
	module_body_label.text = "主线\n当前目标 / 关键节点"
	module_reason_label.text = "资历\n探索 / 回收 / 失败"
	snapshot_label.text = "资源\n金币 / 黑币 / 奖励"
	interface_preview_label.text = "奖励\n事件 / 图鉴 / 外观"
	next_stage_label.text = ""
	_refresh_card_grid(content_preview.get("cards", []) as Array)
	_apply_art10_text_refresh()
	_refresh_tab_buttons()
	_apply_layer_order()


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
	var display_cards := visible_cards.duplicate(true)
	while display_cards.size() < 9:
		display_cards.append({
			"id": "archive_slot_%d" % display_cards.size(),
			"title": _archive_slot_title(display_cards.size()),
			"state": "locked",
			"description": "档案位待解锁。",
		})
	var index := 0
	for card: Dictionary in display_cards.slice(0, 9):
		var button := Button.new()
		button.name = "LongTermCard_%s" % str(card.get("id", index))
		button.text = "%s  %s\n%s" % [
			_card_marker(index),
			_shorten_copy(String(card.get("title", "")), 10),
			_archive_card_state_label(StringName(card.get("state", "preview")), index),
		]
		button.tooltip_text = String(card.get("description", ""))
		button.custom_minimum_size = Vector2(164, 122)
		button.toggle_mode = true
		button.button_pressed = index == 0
		Art10UISkinKitScript.apply_button_token(button, Art10UISkinKitScript.visual_state_tone(&"selected" if index == 0 else &"normal"), &"caption", &"slot")
		card_grid_container.add_child(button)
		index += 1


func _archive_slot_title(index: int) -> String:
	var titles := ["主线", "图鉴", "研究", "资历", "收藏", "拍卖", "记录", "奖励", "外观"]
	return titles[index % titles.size()]


func _archive_card_state_label(state: StringName, index: int) -> String:
	if index == 0:
		return "当前档案"
	match state:
		&"locked":
			return "待解锁"
		&"new":
			return "新记录"
		&"reward":
			return "奖励"
		&"ready":
			return "可领取"
		_:
			return "收藏墙"


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


func _format_profile_runtime(runtime_panel: Dictionary) -> String:
	return Art10UISkinKitScript.sanitize_player_copy("Meta %dG / runs %d / ex %d / fail %d" % [
		int(runtime_panel.get("gold", 0)),
		int(runtime_panel.get("run_count", 0)),
		int(runtime_panel.get("extract_count", 0)),
		int(runtime_panel.get("fail_count", 0)),
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


func _add_texture_rect_from_ref(parent: Control, node_name: String, rect: Rect2, asset_ref: Dictionary, alpha: float = 1.0) -> TextureRect:
	var texture := Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
	if texture == null:
		return null
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.texture = texture
	_set_rect(texture_rect, rect)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.modulate = Color(1.0, 1.0, 1.0, alpha)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


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
