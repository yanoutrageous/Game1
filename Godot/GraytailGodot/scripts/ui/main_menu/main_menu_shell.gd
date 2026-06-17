extends Control
class_name MainMenuShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const MainMenuModelScript := preload("res://scripts/ui/main_menu/main_menu_model.gd")

signal navigation_intent_requested(intent: Dictionary)

var current_model: Dictionary = {}


func build(model: Dictionary = {}) -> void:
	_clear_children()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	current_model = model.duplicate(true) if not model.is_empty() else MainMenuModelScript.build()
	_build_backdrop()
	_build_role_panel()
	_build_menu_panel()
	_build_notice_panel()
	_build_shortcut_panel()


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _build_backdrop() -> void:
	_add_color_rect(self, "MainMenuBackdrop", Rect2(0, 0, 1280, 720), Color(0.018, 0.035, 0.040, 1.0))
	_add_color_rect(self, "BaseStaticLayer", Rect2(42, 64, 708, 562), Color(0.060, 0.095, 0.105, 0.96))
	_add_color_rect(self, "BaseAtmosphereLayer", Rect2(70, 226, 650, 266), Color(0.10, 0.19, 0.18, 0.35))
	_add_label(self, "MainMenuTitle", Rect2(76, 66, 560, 64), String(current_model.get("title", "灰尾回收")), 44, PresentationTheme.color_for_key(&"ui.warning"))
	_add_label(self, "MainMenuSubtitle", Rect2(80, 136, 620, 42), String(current_model.get("subtitle", "基地入口")), 18, PresentationTheme.text_color())
	_add_label(self, "MainMenuSceneHint", Rect2(82, 522, 620, 84), String(current_model.get("scene_hint", "")), 16, PresentationTheme.color_for_key(&"ui.muted"))


func _build_role_panel() -> void:
	_add_color_rect(self, "CharacterDisplayLayer", Rect2(92, 188, 184, 324), Color(0.16, 0.22, 0.21, 0.70))
	_add_label(self, "CharacterDisplayLabel", Rect2(112, 310, 144, 72), "角色展示\n占位", 18, PresentationTheme.text_color())
	_add_label(self, "OutfitShortcutHint", Rect2(116, 456, 230, 44), String(current_model.get("role_hint", "")), 13, PresentationTheme.color_for_key(&"ui.muted"))


func _build_menu_panel() -> void:
	var panel := VBoxContainer.new()
	panel.name = "MainMenuFixedEntries"
	panel.offset_left = 828.0
	panel.offset_top = 92.0
	panel.offset_right = 1192.0
	panel.offset_bottom = 430.0
	panel.add_theme_constant_override("separation", 12)
	add_child(panel)
	_add_section_label(panel, "当前可玩入口 / 固定入口")
	for raw_entry in _array_from(current_model, "entries"):
		if raw_entry is Dictionary:
			var entry: Dictionary = (raw_entry as Dictionary).duplicate(true)
			_add_entry_button(panel, entry)


func _build_notice_panel() -> void:
	var notice_panel := VBoxContainer.new()
	notice_panel.name = "MainMenuNoticePanel"
	notice_panel.offset_left = 828.0
	notice_panel.offset_top = 462.0
	notice_panel.offset_right = 1192.0
	notice_panel.offset_bottom = 604.0
	notice_panel.add_theme_constant_override("separation", 6)
	add_child(notice_panel)
	_add_section_label(notice_panel, "公告栏")
	for notice in _array_from(current_model, "notices"):
		var label := Label.new()
		label.text = String(notice)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", PresentationTheme.text_color())
		notice_panel.add_child(label)


func _build_shortcut_panel() -> void:
	var shortcut_panel := HBoxContainer.new()
	shortcut_panel.name = "MainMenuShortcutPanel"
	shortcut_panel.offset_left = 76.0
	shortcut_panel.offset_top = 620.0
	shortcut_panel.offset_right = 744.0
	shortcut_panel.offset_bottom = 676.0
	shortcut_panel.add_theme_constant_override("separation", 10)
	add_child(shortcut_panel)
	for raw_shortcut in _array_from(current_model, "shortcuts"):
		if raw_shortcut is Dictionary:
			var shortcut: Dictionary = (raw_shortcut as Dictionary).duplicate(true)
			_add_entry_button(shortcut_panel, shortcut)


func _add_entry_button(parent: Control, entry: Dictionary) -> Button:
	var button := Button.new()
	button.text = String(entry.get("label", "入口"))
	button.tooltip_text = String(entry.get("description", ""))
	button.custom_minimum_size = Vector2(168, 40)
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
	label.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
	label.add_theme_font_size_override("font_size", 14)
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


func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []
