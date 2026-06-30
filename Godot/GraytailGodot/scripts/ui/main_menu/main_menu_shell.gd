extends Control
class_name MainMenuShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const MainMenuModelScript := preload("res://scripts/ui/main_menu/main_menu_model.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")

signal navigation_intent_requested(intent: Dictionary)

var current_model: Dictionary = {}
var current_snapshot: Dictionary = {}
var meta_summary_label: Label
var layout_profile: Dictionary = {}


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


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	meta_summary_label = null


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
	_add_texture_rect_from_ref(self, "Art09MainMenuBackground", Rect2(0, 0, 1280, 720), _dictionary_from(visuals.get("background", {})), 0.64)
	_add_color_rect(self, "MainMenuVignette", Rect2(0, 0, 1280, 720), Color(0.0, 0.0, 0.0, 0.24))
	_add_color_rect(self, "BaseHallWarmBacklight", Rect2(58, 178, 666, 336), Color(0.42, 0.30, 0.13, 0.10))
	_add_color_rect(self, "BaseHallDoorGlow", Rect2(86, 186, 176, 326), Color(0.54, 0.86, 0.68, 0.10))
	_add_color_rect(self, "BaseHallEntryMask", Rect2(62, 158, 650, 368), Color(0.0, 0.0, 0.0, 0.28))
	_add_color_rect(self, "BaseHallHeroMask", Rect2(78, 166, 254, 376), Color(0.02, 0.05, 0.05, 0.68))
	_add_color_rect(self, "BaseHallDoorLeft", Rect2(76, 188, 5, 302), Art10UISkinKitScript.color(&"gold", Color(0.94, 0.70, 0.28, 1.0)))
	_add_color_rect(self, "BaseHallDoorRight", Rect2(282, 188, 5, 302), Art10UISkinKitScript.color(&"gold", Color(0.94, 0.70, 0.28, 1.0)))
	_add_color_rect(self, "BaseHallForegroundRail", Rect2(56, 512, 642, 3), Art10UISkinKitScript.color(&"accent", Color(0.58, 0.93, 0.76, 1.0)))
	_add_color_rect(self, "BaseAtmosphereLayer", Rect2(70, 210, 640, 266), Color(0.10, 0.19, 0.17, 0.28))
	_add_color_rect(self, "BaseFloorLine", Rect2(86, 486, 598, 4), PresentationTheme.color_for_key(&"ui.warning", Color(0.94, 0.7, 0.28, 1.0)))
	_add_label_token(self, "MainMenuTitle", Art10UISkinKitScript.rect(&"main_menu", "title"), String(current_model.get("title", "灰尾回收")), &"title", &"warning")
	_add_label_token(self, "MainMenuSubtitle", Rect2(78, 126, 320, 30), "基地门厅", &"body", &"text")


func _build_role_panel() -> void:
	_add_panel(self, "CharacterDisplayLayer", Art10UISkinKitScript.rect(&"main_menu", "role"), &"card")
	_add_color_rect(self, "CharacterPodBacklight", Rect2(96, 188, 190, 318), Color(0.58, 0.93, 0.76, 0.10))
	_add_color_rect(self, "CharacterCapeLayer", Rect2(112, 242, 160, 226), Color(0.10, 0.18, 0.16, 0.92))
	_add_color_rect(self, "CharacterSilhouette", Rect2(132, 210, 122, 258), Color(0.20, 0.31, 0.27, 0.94))
	_add_color_rect(self, "CharacterHead", Rect2(146, 184, 92, 82), Color(0.23, 0.34, 0.30, 0.94))
	_add_texture_rect_from_ref(self, "MainMenuPlayerSprite", Rect2(110, 236, 150, 168), Art09ManifestAssetMappingScript.player_sprite_ref(&"idle"), 1.0)
	_add_color_rect(self, "CharacterTool", Rect2(248, 250, 10, 210), Art10UISkinKitScript.color(&"gold"))
	_add_color_rect(self, "CharacterEquipmentLine", Rect2(104, 462, 188, 3), Art10UISkinKitScript.color(&"accent"))
	_add_label_token(self, "CharacterDisplayLabel", Rect2(110, 474, 184, 28), "探索员整备", &"tab", &"text")


func _build_top_entrance_panel() -> void:
	var top_panel := HBoxContainer.new()
	top_panel.name = "MainMenuTopEntrancePanel"
	_set_rect(top_panel, Rect2(770, 36, 428, 42))
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
	var panel := VBoxContainer.new()
	panel.name = "MainMenuFixedEntries"
	_set_rect(panel, Rect2(770, 122, 428, 378))
	panel.add_theme_constant_override("separation", 14)
	add_child(panel)
	for raw_entry in _array_from(current_model, "entries"):
		if raw_entry is Dictionary:
			var entry: Dictionary = (raw_entry as Dictionary).duplicate(true)
			_add_entry_button(panel, entry, true, "")


func _build_notice_panel() -> void:
	var notice_panel := VBoxContainer.new()
	notice_panel.name = "MainMenuNoticePanel"
	_set_rect(notice_panel, Rect2(90, 550, 530, 46))
	notice_panel.add_theme_constant_override("separation", 4)
	add_child(notice_panel)
	_add_panel(self, "MainMenuNoticeFrame", Art10UISkinKitScript.rect(&"main_menu", "notice"), &"summary")
	_add_texture_rect_from_ref(self, "Art15MainMenuNoticeTexture", Art10UISkinKitScript.rect(&"main_menu", "notice"), Art09ManifestAssetMappingScript.feedback_panel_ref(&"event"), 0.24)
	move_child(notice_panel, get_child_count() - 1)
	_add_section_label(notice_panel, "公告")
	for notice in _array_from(current_model, "notices").slice(0, 1):
		var label := Label.new()
		label.text = _shorten_copy(String(notice), 22)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		Art10UISkinKitScript.apply_label_token(label, &"caption", &"text")
		notice_panel.add_child(label)


func _build_meta_summary_panel() -> void:
	_add_panel(self, "MainMenuMetaFrame", Rect2(354, 414, 320, 82), &"soft")
	_add_texture_rect_from_ref(self, "Art15MainMenuMetaTexture", Rect2(354, 414, 320, 82), Art09ManifestAssetMappingScript.panel_ref(&"terminal"), 0.18)
	_add_label_token(self, "MainMenuMetaSummaryHeading", Rect2(372, 430, 220, 22), "行动记录", &"caption", &"muted")
	meta_summary_label = _add_label_token(self, "MainMenuMetaSummary", Rect2(372, 454, 282, 36), "", &"caption", &"text")
	_refresh_meta_summary()


func _build_shortcut_panel() -> void:
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
	button.tooltip_text = _entry_tooltip(entry)
	button.text = Art10UISkinKitScript.sanitize_player_copy(button.text)
	button.tooltip_text = Art10UISkinKitScript.sanitize_player_copy(button.tooltip_text)
	button.custom_minimum_size = _layout_size(Vector2(410, 78) if large else Vector2(104, 36))
	_apply_art09_button_icon(button, _dictionary_from(entry.get("art09_asset_ref", {})), &"large_nav" if large else &"key")
	Art10UISkinKitScript.apply_button_token(button, &"primary" if large or bool(entry.get("primary", false)) else &"secondary", &"main_button" if large else &"key_prompt", &"large_nav" if large else &"key")
	button.pressed.connect(func() -> void: _emit_entry(entry))
	parent.add_child(button)
	return button


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
