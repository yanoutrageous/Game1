extends Control
class_name MainMenuShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const MainMenuModelScript := preload("res://scripts/ui/main_menu/main_menu_model.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")

signal navigation_intent_requested(intent: Dictionary)

var current_model: Dictionary = {}
var current_snapshot: Dictionary = {}
var meta_summary_label: Label


func build(model: Dictionary = {}) -> void:
	_clear_children()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	current_model = model.duplicate(true) if not model.is_empty() else MainMenuModelScript.build()
	_build_backdrop()
	_build_top_entrance_panel()
	_build_role_panel()
	_build_menu_panel()
	_build_notice_panel()
	_build_meta_summary_panel()
	_build_shortcut_panel()


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	meta_summary_label = null


func apply_snapshot(snapshot: Dictionary) -> void:
	current_snapshot = snapshot.duplicate(true)
	_refresh_meta_summary()


func _build_backdrop() -> void:
	_add_color_rect(self, "MainMenuBackdrop", Rect2(0, 0, 1280, 720), Color(0.018, 0.035, 0.040, 1.0))
	var visuals := _dictionary_from(current_model.get("art09_visuals", {}))
	_add_texture_rect_from_ref(self, "Art09MainMenuBackground", Rect2(0, 0, 1280, 720), _dictionary_from(visuals.get("background", {})), 0.64)
	_add_color_rect(self, "MainMenuVignette", Rect2(0, 0, 1280, 720), Color(0.0, 0.0, 0.0, 0.24))
	_add_panel(self, "MainMenuNarrativeFrame", Rect2(46, 66, 690, 548), &"deep")
	_add_color_rect(self, "BaseAtmosphereLayer", Rect2(70, 210, 640, 266), Color(0.10, 0.19, 0.17, 0.28))
	_add_color_rect(self, "BaseFloorLine", Rect2(86, 486, 598, 4), PresentationTheme.color_for_key(&"ui.warning", Color(0.94, 0.7, 0.28, 1.0)))
	_add_label_token(self, "MainMenuTitle", Art10UISkinKitScript.rect(&"main_menu", "title"), String(current_model.get("title", "灰尾回收")), &"title", &"warning")
	_add_label_token(self, "MainMenuSubtitle", Rect2(78, 126, 610, 42), "基地门厅 / 任务入口", &"body", &"text")
	_add_label_token(self, "MainMenuSceneHint", Rect2(354, 202, 330, 92), "整备区灯箱已亮起。右侧选择行动入口，底部快捷键保留当前可玩探索。", &"body", &"caption")


func _build_role_panel() -> void:
	_add_panel(self, "CharacterDisplayLayer", Art10UISkinKitScript.rect(&"main_menu", "role"), &"card")
	_add_color_rect(self, "CharacterSilhouette", Rect2(122, 220, 128, 248), Color(0.18, 0.27, 0.23, 0.82))
	_add_color_rect(self, "CharacterHighlight", Rect2(152, 188, 70, 330), Color(0.62, 0.94, 0.80, 0.08))
	_add_label_token(self, "CharacterDisplayLabel", Rect2(112, 474, 178, 36), "探索员整备", &"tab", &"text")
	_add_label_token(self, "OutfitShortcutHint", Rect2(354, 312, 318, 82), "装备外观、背包和长期记录仍由后续系统接管；主菜单只保留入口和状态提示。", &"caption", &"muted")


func _build_top_entrance_panel() -> void:
	var top_panel := HBoxContainer.new()
	top_panel.name = "MainMenuTopEntrancePanel"
	top_panel.offset_left = 770.0
	top_panel.offset_top = 36.0
	top_panel.offset_right = 1198.0
	top_panel.offset_bottom = 78.0
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
	panel.offset_left = 770.0
	panel.offset_top = 122.0
	panel.offset_right = 1198.0
	panel.offset_bottom = 500.0
	panel.add_theme_constant_override("separation", 14)
	add_child(panel)
	for raw_entry in _array_from(current_model, "entries"):
		if raw_entry is Dictionary:
			var entry: Dictionary = (raw_entry as Dictionary).duplicate(true)
			_add_entry_button(panel, entry, true, "")


func _build_notice_panel() -> void:
	var notice_panel := VBoxContainer.new()
	notice_panel.name = "MainMenuNoticePanel"
	notice_panel.offset_left = 86.0
	notice_panel.offset_top = 540.0
	notice_panel.offset_right = 646.0
	notice_panel.offset_bottom = 608.0
	notice_panel.add_theme_constant_override("separation", 4)
	add_child(notice_panel)
	_add_panel(self, "MainMenuNoticeFrame", Art10UISkinKitScript.rect(&"main_menu", "notice"), &"summary")
	move_child(notice_panel, get_child_count() - 1)
	_add_section_label(notice_panel, "公告")
	for notice in _array_from(current_model, "notices").slice(0, 2):
		var label := Label.new()
		label.text = _shorten_copy(String(notice), 46)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		Art10UISkinKitScript.apply_label_token(label, &"caption", &"text")
		notice_panel.add_child(label)


func _build_meta_summary_panel() -> void:
	_add_panel(self, "MainMenuMetaFrame", Rect2(354, 414, 320, 82), &"soft")
	_add_label_token(self, "MainMenuMetaSummaryHeading", Rect2(372, 430, 220, 22), "行动记录", &"caption", &"muted")
	meta_summary_label = _add_label_token(self, "MainMenuMetaSummary", Rect2(372, 454, 282, 36), "", &"caption", &"text")
	_refresh_meta_summary()


func _build_shortcut_panel() -> void:
	var shortcut_panel := HBoxContainer.new()
	shortcut_panel.name = "MainMenuShortcutPanel"
	var key_bar_rect := Art10UISkinKitScript.rect(&"main_menu", "bottom_key_bar")
	shortcut_panel.offset_left = key_bar_rect.position.x
	shortcut_panel.offset_top = key_bar_rect.position.y
	shortcut_panel.offset_right = key_bar_rect.position.x + key_bar_rect.size.x
	shortcut_panel.offset_bottom = key_bar_rect.position.y + key_bar_rect.size.y
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
	meta_summary_label.text = "探索 %s | 撤离 %s | 失败 %s\n金币 %s | 仓库物品 %s" % [
		summary.get("run_count", 0),
		summary.get("extract_count", 0),
		summary.get("fail_count", 0),
		summary.get("gold", 0),
		summary.get("warehouse_items_count", 0),
	]
	meta_summary_label.text = Art10UISkinKitScript.sanitize_player_copy(meta_summary_label.text)


func _add_entry_button(parent: Control, entry: Dictionary, large: bool = false, key_label: String = "") -> Button:
	var raw_label := String(entry.get("label", "入口")).replace("快捷：", "")
	var button := Art10UISkinKitScript.make_large_nav_button(raw_label, _shorten_copy(String(entry.get("description", "")), 28)) if large else Art10UISkinKitScript.make_bottom_key_button(raw_label, key_label)
	button.tooltip_text = String(entry.get("description", ""))
	button.text = Art10UISkinKitScript.sanitize_player_copy(button.text)
	button.tooltip_text = Art10UISkinKitScript.sanitize_player_copy(button.tooltip_text)
	button.custom_minimum_size = Vector2(410, 78) if large else Vector2(118, 36)
	_apply_art09_button_icon(button, _dictionary_from(entry.get("art09_asset_ref", {})))
	Art10UISkinKitScript.apply_button_token(button, &"primary" if large or bool(entry.get("primary", false)) else &"secondary", &"main_button" if large else &"key_prompt", &"large_nav" if large else &"key")
	button.pressed.connect(func() -> void: _emit_entry(entry))
	parent.add_child(button)
	return button


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
	label.offset_left = rect.position.x
	label.offset_top = rect.position.y
	label.offset_right = rect.position.x + rect.size.x
	label.offset_bottom = rect.position.y + rect.size.y
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
	return panel


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


func _add_texture_rect_from_ref(parent: Control, node_name: String, rect: Rect2, asset_ref: Dictionary, alpha: float = 1.0) -> TextureRect:
	var texture := Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
	if texture == null:
		return null
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.texture = texture
	texture_rect.offset_left = rect.position.x
	texture_rect.offset_top = rect.position.y
	texture_rect.offset_right = rect.position.x + rect.size.x
	texture_rect.offset_bottom = rect.position.y + rect.size.y
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.modulate = Color(1.0, 1.0, 1.0, alpha)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


func _apply_art09_button_icon(button: Button, asset_ref: Dictionary) -> void:
	var texture := Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
	if texture == null:
		return
	button.icon = texture
	Art10UISkinKitScript.controlled_button_icon(button, &"large_nav")


func _shorten_copy(text: String, max_chars: int) -> String:
	var safe := Art10UISkinKitScript.sanitize_player_copy(text)
	if safe.length() <= max_chars:
		return safe
	return "%s..." % safe.substr(0, max_chars)


func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
