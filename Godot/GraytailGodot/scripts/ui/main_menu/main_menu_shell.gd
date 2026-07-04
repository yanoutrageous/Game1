extends Control
class_name MainMenuShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const MainMenuModelScript := preload("res://scripts/ui/main_menu/main_menu_model.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")

signal navigation_intent_requested(intent: Dictionary)

var current_model: Dictionary = {}
var current_snapshot: Dictionary = {}
var meta_summary_label: Label
var layout_profile: Dictionary = {}
var main_menu_entry_buttons: Array[Button] = []
var selected_main_menu_entry_id: StringName = &"deploy"


func build(model: Dictionary = {}) -> void:
	_clear_children()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	layout_profile = Art10UISkinKitScript.layout_profile_for(self)
	current_model = model.duplicate(true) if not model.is_empty() else MainMenuModelScript.build()
	_build_backdrop()
	_build_top_entrance_panel()
	_build_role_panel()
	_build_menu_panel()
	_build_notice_panel()
	_build_meta_summary_panel()
	_build_shortcut_panel()
	_apply_layer_order()
	call_deferred("_grab_main_menu_initial_focus")


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	meta_summary_label = null
	main_menu_entry_buttons.clear()
	selected_main_menu_entry_id = &"deploy"


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


func apply_snapshot(snapshot: Dictionary) -> void:
	current_snapshot = snapshot.duplicate(true)
	_refresh_meta_summary()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_F1:
			if _emit_shortcut_index(0):
				get_viewport().set_input_as_handled()
		KEY_F2:
			if _emit_shortcut_index(1):
				get_viewport().set_input_as_handled()


func _emit_shortcut_index(index: int) -> bool:
	var shortcuts := _array_from(current_model, "shortcuts")
	if index < 0 or index >= shortcuts.size():
		return false
	var raw_shortcut: Variant = shortcuts[index]
	if not (raw_shortcut is Dictionary):
		return false
	_emit_entry((raw_shortcut as Dictionary).duplicate(true))
	return true


func _build_backdrop() -> void:
	_add_color_rect(self, "MainMenuBackdrop", Rect2(0, 0, 1280, 720), Color(0.018, 0.035, 0.040, 1.0))
	var visuals := _dictionary_from(current_model.get("art09_visuals", {}))
	_add_texture_rect_from_ref(self, "Art09MainMenuBackground", Rect2(0, 0, 1280, 720), _dictionary_from(visuals.get("background", {})), 0.94)
	_add_color_rect(self, "MainMenuVignette", Rect2(0, 0, 1280, 720), Color(0.0, 0.0, 0.0, 0.08))
	_add_color_rect(self, "BaseHallWarmBacklight", Rect2(44, 176, 674, 348), Color(0.42, 0.30, 0.13, 0.035))
	_add_image_panel_from_ref(self, "MainMenuTitlePlate", Rect2(52, 52, 440, 112), Art21UIPlacementContractScript.component_ref(&"art21r2.modal.title_plate", &"ui.art19.panel.terminal_main", &"main_menu_title_plate"), 16, 18, 0.86)
	_add_label_token(self, "MainMenuTitle", Art10UISkinKitScript.rect(&"main_menu", "title"), String(current_model.get("title", "灰尾回收")), &"title", &"warning")
	_add_label_token(self, "MainMenuSubtitle", Rect2(78, 150, 360, 30), "基地门厅", &"body", &"text")


func _build_role_panel() -> void:
	_add_texture_rect_from_ref(self, "MainMenuPlayerSprite", Rect2(116, 244, 154, 172), Art09ManifestAssetMappingScript.player_sprite_ref(&"idle"), 1.0)


func _build_top_entrance_panel() -> void:
	return
	var top_panel := HBoxContainer.new()
	top_panel.name = "MainMenuTopEntrancePanel"
	_set_rect(top_panel, Art10UISkinKitScript.rect(&"main_menu", "top_shortcuts"))
	top_panel.add_theme_constant_override("separation", 8)
	add_child(top_panel)
	var shortcut_index := 1
	for raw_shortcut in _array_from(current_model, "shortcuts"):
		if not (raw_shortcut is Dictionary):
			continue
		var shortcut: Dictionary = (raw_shortcut as Dictionary).duplicate(true)
		if shortcut_index > 2:
			break
		_add_entry_button(top_panel, shortcut, false, "F%d" % shortcut_index)
		shortcut_index += 1
	for raw_entry in _array_from(current_model, "entries"):
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = (raw_entry as Dictionary).duplicate(true)
		var entry_id := StringName(entry.get("id", &""))
		if entry_id == &"settings" or entry_id == &"exit_game":
			_add_entry_button(top_panel, entry, false, "")


func _build_menu_panel() -> void:
	_build_physical_menu_panel()
	return
	_add_panel(self, "MainMenuEntryBoard", Rect2(732, 126, 486, 426), &"deep")
	_add_texture_rect_from_ref(self, "Art21MainMenuActionDeckTexture", Rect2(738, 132, 474, 414), Art21UIPlacementContractScript.slot_ref(&"main_menu", &"action_deck_frame", &"ui.art19.panel.terminal_main"), 0.82)
	_add_color_rect(self, "MainMenuEntryBoardTopRail", Rect2(748, 142, 444, 4), Art10UISkinKitScript.color(&"gold"))
	_add_color_rect(self, "MainMenuEntryBoardGlow", Rect2(760, 150, 430, 372), Color(0.94, 0.70, 0.28, 0.045))
	_add_label_token(self, "MainMenuBoardHeader", Rect2(780, 154, 360, 34), "灰尾公司", &"hud", &"warning")
	var panel := VBoxContainer.new()
	panel.name = "MainMenuFixedEntries"
	_set_rect(panel, Rect2(780, 198, 380, 310))
	panel.add_theme_constant_override("separation", 14)
	add_child(panel)
	for raw_entry in _array_from(current_model, "entries"):
		if raw_entry is Dictionary:
			var entry: Dictionary = (raw_entry as Dictionary).duplicate(true)
			_add_entry_button(panel, entry, true, "")


func _build_notice_panel() -> void:
	return
	var notice_panel := VBoxContainer.new()
	notice_panel.name = "MainMenuNoticePanel"
	_set_rect(notice_panel, Rect2(80, 556, 528, 42))
	notice_panel.add_theme_constant_override("separation", 4)
	add_child(notice_panel)
	_add_panel(self, "MainMenuNoticeFrame", Art10UISkinKitScript.rect(&"main_menu", "notice"), &"summary")
	_add_texture_rect_from_ref(self, "Art21MainMenuNoticeTexture", Art10UISkinKitScript.rect(&"main_menu", "notice"), Art21UIPlacementContractScript.panel_ref(&"bar_summary"), 0.82)
	move_child(notice_panel, get_child_count() - 1)
	_add_section_label(notice_panel, "公告")
	for notice in _array_from(current_model, "notices").slice(0, 1):
		var label := Label.new()
		label.text = _shorten_copy(String(notice), 22)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		Art10UISkinKitScript.apply_label_token(label, &"caption", &"text")
		notice_panel.add_child(label)


func _build_meta_summary_panel() -> void:
	return
	_add_panel(self, "MainMenuMetaFrame", Art10UISkinKitScript.rect(&"main_menu", "meta"), &"soft")
	_add_texture_rect_from_ref(self, "Art21MainMenuMetaTexture", Art10UISkinKitScript.rect(&"main_menu", "meta"), Art21UIPlacementContractScript.panel_ref(&"summary"), 0.62)
	_add_label_token(self, "MainMenuMetaSummaryHeading", Rect2(384, 446, 220, 20), "行动记录", &"caption", &"muted")
	meta_summary_label = _add_label_token(self, "MainMenuMetaSummary", Rect2(384, 468, 272, 28), "", &"caption", &"text")
	_refresh_meta_summary()


func _build_shortcut_panel() -> void:
	return
	var shortcut_panel := HBoxContainer.new()
	shortcut_panel.name = "MainMenuShortcutPanel"
	var key_bar_rect := Art10UISkinKitScript.rect(&"main_menu", "bottom_key_bar")
	_set_rect(shortcut_panel, key_bar_rect)
	shortcut_panel.add_theme_constant_override("separation", 8)
	add_child(shortcut_panel)
	_add_panel(self, "MainMenuKeyBarFrame", key_bar_rect.grow(8.0), &"surface")
	move_child(shortcut_panel, get_child_count() - 1)
	var key_index := 1
	for raw_shortcut in _array_from(current_model, "shortcuts"):
		if raw_shortcut is Dictionary:
			var shortcut: Dictionary = (raw_shortcut as Dictionary).duplicate(true)
			_add_entry_button(shortcut_panel, shortcut, false, "F%d" % key_index)
			key_index += 1


func _refresh_meta_summary() -> void:
	if meta_summary_label == null:
		return
	var summary: Dictionary = {}
	var raw: Variant = current_snapshot.get("meta_progress_summary", {})
	if raw is Dictionary:
		summary = (raw as Dictionary).duplicate(true)
	meta_summary_label.text = "探索 %s | 撤离 %s | 金币 %s" % [
		summary.get("run_count", 0),
		summary.get("extract_count", 0),
		summary.get("gold", 0),
	]
	meta_summary_label.text = Art10UISkinKitScript.sanitize_player_copy(meta_summary_label.text)


func _add_entry_button(parent: Control, entry: Dictionary, large: bool = false, key_label: String = "") -> Button:
	var raw_label := String(entry.get("label", "入口")).replace("快捷：", "")
	var button := Art10UISkinKitScript.make_large_nav_button(raw_label, _entry_subtitle(entry)) if large else Art10UISkinKitScript.make_bottom_key_button(raw_label, key_label)
	button.tooltip_text = ""
	button.text = Art10UISkinKitScript.sanitize_player_copy(button.text)
	button.custom_minimum_size = _layout_size(Vector2(410, 76) if large else Vector2(104, 36))
	button.focus_mode = Control.FOCUS_ALL
	_apply_art09_button_icon(button, _dictionary_from(entry.get("art09_asset_ref", {})), &"large_nav" if large else &"key")
	var entry_id := StringName(entry.get("id", &""))
	var tone := &"gold" if large and entry_id == &"deploy" else (&"primary" if large or bool(entry.get("primary", false)) else &"secondary")
	Art10UISkinKitScript.apply_button_token(button, tone, &"main_button" if large else &"key_prompt", &"large_nav" if large else &"key")
	button.pressed.connect(func() -> void: _emit_entry(entry))
	parent.add_child(button)
	return button


func _build_physical_menu_panel() -> void:
	_add_image_panel_from_ref(self, "MainMenuBoardHeaderPlate", Rect2(912, 96, 316, 72), Art21UIPlacementContractScript.component_ref(&"art21r2.modal.section.panel", &"ui.art19.panel.deploy_summary", &"main_menu_board_header"), 10, 18, 0.78)
	_add_label_token(self, "MainMenuBoardHeader", Rect2(934, 108, 274, 34), "GRAYTAIL", &"hud", &"warning")
	_add_label_token(self, "MainMenuBoardSubHeader", Rect2(934, 140, 274, 24), "GRAYTAIL CO.", &"caption", &"text")
	var entry_index := 0
	for raw_entry in _array_from(current_model, "entries"):
		if raw_entry is Dictionary:
			var entry: Dictionary = (raw_entry as Dictionary).duplicate(true)
			var rect := _main_menu_entry_rect(entry_index)
			_add_main_menu_entry_plate(self, entry, rect)
			_add_physical_entry_button(self, entry, rect)
			entry_index += 1
	_wire_main_menu_entry_focus()
	_set_main_menu_entry_selected(selected_main_menu_entry_id)


func _add_physical_entry_button(parent: Control, entry: Dictionary, rect: Rect2) -> Button:
	var raw_label := String(entry.get("label", "Entry"))
	var button := Art10UISkinKitScript.make_large_nav_button(raw_label, _entry_subtitle(entry), &"primary")
	button.name = "MainMenuPhysicalEntry_%s" % String(entry.get("id", &"entry"))
	button.tooltip_text = ""
	button.text = Art10UISkinKitScript.sanitize_player_copy(button.text)
	button.custom_minimum_size = _layout_size(rect.size)
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_art09_button_icon(button, _dictionary_from(entry.get("art09_asset_ref", {})), &"large_nav")
	var entry_id := StringName(entry.get("id", &""))
	button.set_meta("entry_id", entry_id)
	var tone := &"gold" if entry_id == &"deploy" else &"secondary"
	Art10UISkinKitScript.apply_transparent_button_token(button, tone, &"main_button", &"large_nav", 0)
	button.add_theme_color_override("font_color", Color(0.92, 0.82, 0.62, 1.0) if entry_id == &"deploy" else Color(0.86, 0.78, 0.64, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.88, 0.50, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.95, 0.68, 0.28, 1.0))
	button.focus_entered.connect(func() -> void: _set_main_menu_entry_selected(entry_id))
	button.mouse_entered.connect(func() -> void: _set_main_menu_entry_selected(entry_id))
	button.pressed.connect(func() -> void: _emit_entry(entry))
	parent.add_child(button)
	_set_rect(button, rect)
	main_menu_entry_buttons.append(button)
	return button


func _add_main_menu_entry_plate(parent: Control, entry: Dictionary, rect: Rect2) -> void:
	var entry_id := StringName(entry.get("id", &"entry"))
	var visual_key := &"art21r2.modal.button.primary" if entry_id == &"deploy" else &"art21r2.modal.button.secondary"
	var plate_name := "MainMenuPhysicalEntryPlate_%s" % String(entry_id)
	var plate_rect := rect.grow_individual(10.0, 8.0, 10.0, 8.0)
	_add_image_panel_from_ref(parent, plate_name, plate_rect, Art21UIPlacementContractScript.component_ref(visual_key, &"ui.art19.button.dark", &"main_menu_entry_plate"), 10, 18, 0.58)
	var arrow := _add_label_token(parent, "MainMenuPhysicalEntryArrow_%s" % String(entry_id), Rect2(rect.position.x + rect.size.x - 32.0, rect.position.y + 18.0, 26.0, 34.0), "▶", &"section_title", &"warning")
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _wire_main_menu_entry_focus() -> void:
	var count := main_menu_entry_buttons.size()
	if count <= 0:
		return
	for index in range(count):
		var button := main_menu_entry_buttons[index]
		var previous := main_menu_entry_buttons[(index - 1 + count) % count]
		var next := main_menu_entry_buttons[(index + 1) % count]
		button.focus_neighbor_top = button.get_path_to(previous)
		button.focus_neighbor_bottom = button.get_path_to(next)
		button.focus_neighbor_left = button.get_path_to(previous)
		button.focus_neighbor_right = button.get_path_to(next)


func _set_main_menu_entry_selected(entry_id: StringName) -> void:
	selected_main_menu_entry_id = entry_id
	for button in main_menu_entry_buttons:
		if button == null:
			continue
		var raw_id: Variant = button.get_meta("entry_id", &"")
		var button_entry_id := StringName(raw_id)
		var selected := button_entry_id == entry_id
		var plate := get_node_or_null("MainMenuPhysicalEntryPlate_%s" % String(button_entry_id)) as CanvasItem
		if plate != null:
			plate.modulate = Color(1.18, 1.06, 0.74, 0.90) if selected else Color(0.86, 0.88, 0.78, 0.54)
		var arrow := get_node_or_null("MainMenuPhysicalEntryArrow_%s" % String(button_entry_id)) as Label
		if arrow != null:
			arrow.add_theme_color_override("font_color", Color(1.0, 0.78, 0.30, 1.0) if selected else Color(0.58, 0.50, 0.38, 0.78))
		button.add_theme_color_override("font_color", Color(1.0, 0.90, 0.58, 1.0) if selected else Color(0.86, 0.78, 0.64, 1.0))


func _grab_main_menu_initial_focus() -> void:
	for button in main_menu_entry_buttons:
		if button == null:
			continue
		if StringName(button.get_meta("entry_id", &"")) == &"deploy":
			button.grab_focus()
			_set_main_menu_entry_selected(&"deploy")
			return
	if not main_menu_entry_buttons.is_empty() and main_menu_entry_buttons[0] != null:
		main_menu_entry_buttons[0].grab_focus()


func _main_menu_entry_rect(index: int) -> Rect2:
	var rects := [
		Rect2(932, 218, 290, 74),
		Rect2(936, 328, 288, 72),
		Rect2(942, 434, 282, 72),
		Rect2(948, 540, 272, 70),
	]
	if index >= 0 and index < rects.size():
		return rects[index]
	return Rect2(948, 540 + float(index - 3) * 74.0, 272, 70)


func _entry_subtitle(entry: Dictionary) -> String:
	var entry_id := StringName(entry.get("id", &""))
	match entry_id:
		&"deploy":
			return "整备出发"
		&"long_term":
			return "档案收藏"
		&"settings":
			return "画面音量"
		&"exit_game":
			return "确认退出"
		_:
			return _shorten_copy(String(entry.get("description", "")), 12)


func _entry_tooltip(entry: Dictionary) -> String:
	var entry_id := StringName(entry.get("id", &""))
	match entry_id:
		&"shortcut_standard_10x10":
			return "进入当前可玩探索。"
		&"shortcut_warehouse":
			return "查看仓库入口。"
		&"shortcut_codex":
			return "查看图鉴入口。"
		&"deploy":
			return "查看出勤配置并开始探索。"
		&"long_term":
			return "查看任务、图鉴和收藏。"
		&"settings":
			return "调整画面与音量。"
		&"exit_game":
			return "打开退出确认。"
		_:
			return _shorten_copy(String(entry.get("description", "")), 24)


func _emit_entry(entry: Dictionary) -> void:
	var target := StringName(entry.get("target", NavigationIntentScript.TARGET_MAIN_MENU))
	var payload: Dictionary = {}
	var raw_payload: Variant = entry.get("payload", {})
	if raw_payload is Dictionary:
		payload = (raw_payload as Dictionary).duplicate(true)
	var intent := NavigationIntentScript.make_run(&"main_menu", payload) if target == NavigationIntentScript.TARGET_RUN else NavigationIntentScript.make(
		target,
		&"main_menu",
		payload,
		bool(entry.get("requires_confirm", false))
	)
	navigation_intent_requested.emit(intent)


func _add_section_label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	Art10UISkinKitScript.apply_label_token(label, &"caption", &"muted")
	parent.add_child(label)
	return label


func _add_label(parent: Control, node_name: String, rect: Rect2, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	_set_rect(label, rect)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Art10UISkinKitScript.apply_label(label, font_size, color)
	parent.add_child(label)
	return label


func _add_label_token(parent: Control, node_name: String, rect: Rect2, text: String, token: StringName, color_token: StringName) -> Label:
	var label := _add_label(parent, node_name, rect, text, Art10UISkinKitScript.font_size(token), Art10UISkinKitScript.color(color_token, PresentationTheme.text_color()))
	return label


func _add_panel(parent: Control, node_name: String, rect: Rect2, tone: StringName) -> PanelContainer:
	var panel := Art10UISkinKitScript.make_frame_panel(node_name, rect, tone)
	parent.add_child(panel)
	_set_rect(panel, rect)
	return panel


func _add_image_panel_from_ref(parent: Control, node_name: String, rect: Rect2, asset_ref: Dictionary, padding: int = 8, texture_margin: int = 18, alpha: float = 1.0) -> PanelContainer:
	var style := Art10UISkinKitScript.style_box_from_asset_ref(asset_ref, padding, texture_margin)
	if style == null:
		return null
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", style)
	panel.modulate = Color(1.0, 1.0, 1.0, alpha)
	parent.add_child(panel)
	_set_rect(panel, rect)
	return panel


func _add_color_rect(parent: Control, node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.name = node_name
	color_rect.color = color
	_set_rect(color_rect, rect)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(color_rect)
	return color_rect


func _add_texture_rect_from_ref(parent: Control, node_name: String, rect: Rect2, asset_ref: Dictionary, alpha: float = 1.0) -> TextureRect:
	var texture := Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
	if texture == null:
		return null
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.texture = texture
	_set_rect(texture_rect, rect)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.modulate = Color(1.0, 1.0, 1.0, alpha)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


func _apply_art09_button_icon(button: Button, asset_ref: Dictionary, icon_token: StringName = &"button") -> void:
	var texture := Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
	if texture == null:
		return
	button.icon = texture
	Art10UISkinKitScript.controlled_button_icon(button, icon_token)


func _set_rect(control: Control, rect: Rect2) -> void:
	Art10UISkinKitScript.set_rect(control, Art10UISkinKitScript.layout_rect_for(self, rect))


func _layout_size(base_size: Vector2) -> Vector2:
	return Art10UISkinKitScript.layout_size_for(self, base_size)


func _shorten_copy(text: String, max_chars: int) -> String:
	return Art10UISkinKitScript.short_summary(text, max_chars)


func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
