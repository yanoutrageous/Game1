extends RefCounted
class_name Art10UISkinKit

# ART-10R UI skin kit is presentation-only. It owns shared pixel UI styling,
# player-visible copy cleanup, and Base confirmed draft layout metrics.

const FONT_ASSET_ID := &"ui.font.fusion_pixel"
const CANVAS_SIZE := Vector2(1280, 720)

const FONT_TOKENS := {
	&"title": 54,
	&"page_title": 36,
	&"main_button": 24,
	&"tab": 16,
	&"body": 15,
	&"caption": 12,
	&"numeric": 18,
	&"key_prompt": 12,
}

const ICON_SIZES := {
	&"large_nav": 54,
	&"button": 28,
	&"slot": 44,
	&"key": 22,
	&"tab": 24,
}

const COLORS := {
	&"text": Color(0.89, 0.94, 0.88, 1.0),
	&"muted": Color(0.56, 0.67, 0.62, 1.0),
	&"caption": Color(0.68, 0.76, 0.70, 1.0),
	&"panel": Color(0.020, 0.041, 0.046, 0.93),
	&"panel_deep": Color(0.010, 0.022, 0.028, 0.97),
	&"panel_soft": Color(0.050, 0.078, 0.074, 0.88),
	&"slot": Color(0.038, 0.064, 0.064, 0.95),
	&"gold": Color(0.94, 0.70, 0.28, 1.0),
	&"gold_dark": Color(0.28, 0.18, 0.06, 0.96),
	&"accent": Color(0.58, 0.93, 0.76, 1.0),
	&"warning": Color(0.95, 0.72, 0.30, 1.0),
	&"danger": Color(0.94, 0.34, 0.28, 1.0),
	&"shadow": Color(0.0, 0.0, 0.0, 0.42),
	&"disabled": Color(0.27, 0.32, 0.31, 0.76),
}

const MAIN_MENU_RECTS := {
	"title": Rect2(72, 48, 620, 78),
	"role": Rect2(82, 178, 238, 352),
	"entry_stack": Rect2(760, 122, 438, 372),
	"notice": Rect2(76, 532, 584, 84),
	"bottom_key_bar": Rect2(72, 638, 704, 50),
}

const DEPLOY_RECTS := {
	"left_column": Rect2(42, 150, 272, 472),
	"center_column": Rect2(334, 150, 600, 472),
	"summary_column": Rect2(958, 150, 278, 472),
	"tab_row": Rect2(330, 84, 720, 48),
	"bottom_key_bar": Rect2(334, 642, 600, 48),
}

const LONG_TERM_RECTS := {
	"profile_column": Rect2(44, 158, 260, 470),
	"card_grid": Rect2(326, 158, 564, 470),
	"detail_column": Rect2(912, 158, 326, 470),
	"tab_row": Rect2(300, 88, 760, 48),
}

const RUN_RECTS := {
	"left_scanner": Rect2(0, 0, 374, 720),
	"right_status": Rect2(990, 0, 290, 720),
	"center_room": Rect2(398, 18, 570, 112),
	"bottom_key_bar": Rect2(404, 634, 560, 58),
}


static func pixel_font() -> Resource:
	var resource := ContentDB.get_asset_ref(FONT_ASSET_ID)
	if resource is Font:
		return resource
	return null


static func font_size(token: StringName, fallback: int = 15) -> int:
	var value: Variant = FONT_TOKENS.get(token, fallback)
	return int(value) if value is int else fallback


static func icon_size(token: StringName, fallback: int = 28) -> int:
	var value: Variant = ICON_SIZES.get(token, fallback)
	return int(value) if value is int else fallback


static func color(token: StringName, fallback: Color = Color.WHITE) -> Color:
	var value: Variant = COLORS.get(token, fallback)
	return value if value is Color else fallback


static func sanitize_player_copy(text: String) -> String:
	var result := text
	var replacements := {
		"DEBUG": "诊断",
		"Debug": "诊断",
		"debug": "诊断",
		"Legacy": "",
		"legacy": "",
		"draft": "配置草案",
		"Draft": "配置草案",
		"preview_only": "预览",
		"preview": "预览",
		"Preview": "预览",
		"display_only": "展示",
		"read_only": "只读",
		"no_persistence": "不写入存档",
		"G24 foundation": "长期系统基础",
		"RunStartConfig": "出发配置",
		"local draft": "本地配置",
		"M1 验证摘要": "近期行动记录",
	}
	for key in replacements.keys():
		result = result.replace(String(key), String(replacements[key]))
	while result.find("  ") >= 0:
		result = result.replace("  ", " ")
	return result.strip_edges()


static func status_label(value: Variant) -> String:
	var text := sanitize_player_copy(String(value))
	var lowered := text.to_lower()
	if lowered == "pending" or lowered == "待确认":
		return "待确认"
	if lowered == "selected":
		return "已选择"
	if lowered == "configured":
		return "已配置"
	if lowered == "owned":
		return "已拥有"
	return text


static func apply_label(label: Label, font_size_value: int = -1, font_color: Color = Color(-1, -1, -1, -1)) -> void:
	if label == null:
		return
	label.text = sanitize_player_copy(label.text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	var font := pixel_font()
	if font is Font:
		label.add_theme_font_override("font", font as Font)
	var resolved_size := font_size_value if font_size_value > 0 else font_size(&"body")
	label.add_theme_font_size_override("font_size", resolved_size)
	label.add_theme_constant_override("line_spacing", _line_spacing_for(resolved_size))
	if font_color.a >= 0.0:
		label.add_theme_color_override("font_color", font_color)


static func apply_label_token(label: Label, token: StringName, color_token: StringName = &"text") -> void:
	apply_label(label, font_size(token), color(color_token))


static func apply_button(button: Button, tone: StringName = &"secondary", font_size_value: int = -1, icon_token: StringName = &"button") -> void:
	if button == null:
		return
	button.text = sanitize_player_copy(button.text)
	button.tooltip_text = sanitize_player_copy(button.tooltip_text)
	var font := pixel_font()
	if font is Font:
		button.add_theme_font_override("font", font as Font)
	var resolved_size := font_size_value if font_size_value > 0 else font_size(&"body")
	button.add_theme_font_size_override("font_size", resolved_size)
	button.add_theme_color_override("font_color", color(&"text"))
	button.add_theme_color_override("font_disabled_color", color(&"muted"))
	button.add_theme_constant_override("h_separation", 10)
	button.add_theme_constant_override("icon_max_width", icon_size(icon_token))
	button.expand_icon = false
	button.clip_text = true
	button.add_theme_stylebox_override("normal", button_style(tone, false, false))
	button.add_theme_stylebox_override("hover", button_style(tone, true, false))
	button.add_theme_stylebox_override("pressed", button_style(tone, false, true))
	button.add_theme_stylebox_override("disabled", button_style(&"disabled", false, false))
	button.modulate = Color(1, 1, 1, 1) if not button.disabled else Color(0.72, 0.76, 0.74, 1.0)


static func apply_button_token(button: Button, tone: StringName, token: StringName, icon_token: StringName = &"button") -> void:
	apply_button(button, tone, font_size(token), icon_token)


static func apply_panel(panel: PanelContainer, tone: StringName = &"surface") -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", panel_style(tone))


static func make_frame_panel(node_name: String, rect: Rect2 = Rect2(), tone: StringName = &"surface") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_rect(panel, rect)
	apply_panel(panel, tone)
	return panel


static func make_large_nav_button(text: String, subtitle: String = "", tone: StringName = &"primary") -> Button:
	var button := Button.new()
	button.text = text if subtitle == "" else "%s\n%s" % [text, subtitle]
	button.custom_minimum_size = Vector2(410, 76)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	apply_button_token(button, tone, &"main_button", &"large_nav")
	return button


static func make_icon_slot(node_name: String, size: Vector2 = Vector2(52, 52), tone: StringName = &"slot") -> PanelContainer:
	var panel := make_frame_panel(node_name, Rect2(Vector2.ZERO, size), tone)
	panel.custom_minimum_size = size
	return panel


static func make_card_frame(node_name: String, rect: Rect2 = Rect2(), selected: bool = false) -> PanelContainer:
	return make_frame_panel(node_name, rect, &"selected" if selected else &"card")


static func make_selected_glow(node_name: String, rect: Rect2, glow_color: Color = Color(0.58, 0.93, 0.76, 0.20)) -> ColorRect:
	var glow := ColorRect.new()
	glow.name = node_name
	glow.color = glow_color
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_rect(glow, rect)
	return glow


static func make_bottom_key_button(text: String, key_label: String = "", icon: Texture2D = null) -> Button:
	var button := Button.new()
	button.text = text if key_label == "" else "%s  %s" % [key_label, text]
	button.icon = icon
	button.custom_minimum_size = Vector2(126, 36)
	button.focus_mode = Control.FOCUS_NONE
	apply_button_token(button, &"secondary", &"key_prompt", &"key")
	return button


static func rect(group: StringName, key: String) -> Rect2:
	var table := {}
	match group:
		&"main_menu":
			table = MAIN_MENU_RECTS
		&"deploy":
			table = DEPLOY_RECTS
		&"long_term":
			table = LONG_TERM_RECTS
		&"run":
			table = RUN_RECTS
		_:
			table = {}
	var value: Variant = table.get(key, Rect2())
	return value if value is Rect2 else Rect2()


static func set_rect(control: Control, target_rect: Rect2) -> void:
	if control == null:
		return
	if target_rect == Rect2():
		return
	control.offset_left = target_rect.position.x
	control.offset_top = target_rect.position.y
	control.offset_right = target_rect.position.x + target_rect.size.x
	control.offset_bottom = target_rect.position.y + target_rect.size.y


static func controlled_button_icon(button: Button, icon_token: StringName = &"button") -> void:
	if button == null:
		return
	button.expand_icon = false
	button.add_theme_constant_override("icon_max_width", icon_size(icon_token))


static func panel_style(tone: StringName = &"surface") -> StyleBoxFlat:
	var bg := color(&"panel")
	var border := color(&"accent")
	var border_width := 1
	var padding := 10
	match tone:
		&"deep":
			bg = color(&"panel_deep")
			border = color(&"muted")
			padding = 12
		&"summary":
			bg = Color(0.044, 0.058, 0.058, 0.96)
			border = color(&"warning")
			padding = 12
		&"card":
			bg = Color(0.030, 0.052, 0.056, 0.94)
			border = Color(0.24, 0.36, 0.34, 1.0)
			padding = 10
		&"selected":
			bg = Color(0.050, 0.078, 0.066, 0.98)
			border = color(&"accent")
			border_width = 2
			padding = 10
		&"slot":
			bg = color(&"slot")
			border = Color(0.30, 0.46, 0.42, 1.0)
			padding = 6
		&"gold":
			bg = color(&"gold_dark")
			border = color(&"gold")
			border_width = 2
			padding = 12
		&"danger":
			bg = Color(0.060, 0.032, 0.032, 0.92)
			border = color(&"danger")
		&"soft":
			bg = color(&"panel_soft")
			border = color(&"muted")
		_:
			bg = color(&"panel")
			border = color(&"accent")
	return _style_box(bg, border, border_width, padding, 3)


static func button_style(tone: StringName = &"secondary", hover: bool = false, pressed: bool = false) -> StyleBoxFlat:
	var bg := Color(0.032, 0.056, 0.060, 0.95)
	var border := color(&"muted")
	var border_width := 1
	var padding := 8
	match tone:
		&"primary":
			bg = Color(0.044, 0.075, 0.070, 0.97)
			border = color(&"accent")
		&"gold":
			bg = color(&"gold_dark")
			border = color(&"gold")
			border_width = 2
			padding = 12
		&"warning":
			border = color(&"warning")
		&"danger":
			border = color(&"danger")
		&"disabled":
			bg = Color(0.020, 0.028, 0.030, 0.70)
			border = color(&"disabled")
		_:
			border = color(&"muted")
	if hover:
		bg = bg.lightened(0.08)
	if pressed:
		bg = bg.darkened(0.12)
		border_width = max(border_width, 2)
	return _style_box(bg, border, border_width, padding, 3)


static func _style_box(bg: Color, border: Color, border_width: int, padding: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style


static func _line_spacing_for(font_size_value: int) -> int:
	if font_size_value >= font_size(&"title"):
		return 7
	if font_size_value >= font_size(&"page_title"):
		return 6
	if font_size_value >= font_size(&"main_button"):
		return 5
	return 3
