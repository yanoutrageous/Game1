extends RefCounted
class_name Art10UISkinKit

# ART-10 UI skin kit is presentation-only. It owns shared pixel UI styling,
# player-visible copy cleanup, and reference layout metrics.

const FONT_ASSET_ID := &"ui.font.fusion_pixel"
const CANVAS_SIZE := Vector2(1280, 720)

const COLORS := {
	&"text": Color(0.88, 0.94, 0.90, 1.0),
	&"muted": Color(0.58, 0.67, 0.64, 1.0),
	&"panel": Color(0.020, 0.042, 0.048, 0.92),
	&"panel_deep": Color(0.012, 0.026, 0.032, 0.96),
	&"panel_soft": Color(0.046, 0.072, 0.078, 0.88),
	&"accent": Color(0.62, 0.94, 0.80, 1.0),
	&"warning": Color(0.96, 0.72, 0.30, 1.0),
	&"danger": Color(0.94, 0.34, 0.28, 1.0),
	&"shadow": Color(0.0, 0.0, 0.0, 0.34),
}

const MAIN_MENU_RECTS := {
	"title": Rect2(76, 58, 590, 72),
	"role": Rect2(92, 188, 184, 324),
	"entry_stack": Rect2(820, 120, 392, 360),
	"notice": Rect2(820, 500, 392, 112),
	"bottom_key_bar": Rect2(76, 624, 700, 52),
}

const DEPLOY_RECTS := {
	"left_column": Rect2(32, 90, 260, 552),
	"center_column": Rect2(316, 90, 620, 552),
	"summary_column": Rect2(960, 90, 288, 552),
	"tab_row": Rect2(320, 96, 600, 48),
	"bottom_key_bar": Rect2(316, 652, 632, 40),
}

const LONG_TERM_RECTS := {
	"profile_column": Rect2(32, 136, 252, 492),
	"card_grid": Rect2(306, 136, 590, 492),
	"detail_column": Rect2(920, 136, 318, 492),
	"tab_row": Rect2(304, 86, 620, 44),
}

const RUN_RECTS := {
	"left_scanner": Rect2(0, 0, 380, 720),
	"right_status": Rect2(984, 0, 296, 720),
	"center_room": Rect2(400, 20, 564, 150),
	"bottom_key_bar": Rect2(400, 630, 564, 70),
}


static func pixel_font() -> Resource:
	var resource := ContentDB.get_asset_ref(FONT_ASSET_ID)
	if resource is Font:
		return resource
	return null


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
		"draft": "配置",
		"Draft": "配置",
		"preview_only": "本轮不写入",
		"preview": "待确认",
		"Preview": "待确认",
		"display_only": "只读展示",
		"read_only": "只读",
		"no_persistence": "不写入存档",
		"G24 foundation": "长期系统基础",
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


static func apply_label(label: Label, font_size: int = -1, font_color: Color = Color(-1, -1, -1, -1)) -> void:
	if label == null:
		return
	label.text = sanitize_player_copy(label.text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	var font := pixel_font()
	if font is Font:
		label.add_theme_font_override("font", font as Font)
	if font_size > 0:
		label.add_theme_font_size_override("font_size", font_size)
	if font_color.a >= 0.0:
		label.add_theme_color_override("font_color", font_color)
	label.add_theme_constant_override("line_spacing", 2)


static func apply_button(button: Button, tone: StringName = &"secondary", font_size: int = 14) -> void:
	if button == null:
		return
	button.text = sanitize_player_copy(button.text)
	button.tooltip_text = sanitize_player_copy(button.tooltip_text)
	var font := pixel_font()
	if font is Font:
		button.add_theme_font_override("font", font as Font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", color(&"text"))
	button.add_theme_color_override("font_disabled_color", color(&"muted"))
	button.add_theme_stylebox_override("normal", button_style(tone, false, false))
	button.add_theme_stylebox_override("hover", button_style(tone, true, false))
	button.add_theme_stylebox_override("pressed", button_style(tone, false, true))
	button.add_theme_stylebox_override("disabled", button_style(&"disabled", false, false))
	button.modulate = Color(1, 1, 1, 1) if not button.disabled else Color(0.72, 0.76, 0.74, 1.0)
	button.clip_text = true


static func apply_panel(panel: PanelContainer, tone: StringName = &"surface") -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", panel_style(tone))


static func panel_style(tone: StringName = &"surface") -> StyleBoxFlat:
	var bg := color(&"panel")
	var border := color(&"accent")
	match tone:
		&"deep":
			bg = color(&"panel_deep")
			border = color(&"muted")
		&"summary":
			bg = Color(0.040, 0.058, 0.062, 0.96)
			border = color(&"warning")
		&"danger":
			bg = Color(0.060, 0.032, 0.032, 0.92)
			border = color(&"danger")
		&"soft":
			bg = color(&"panel_soft")
			border = color(&"muted")
		_:
			bg = color(&"panel")
			border = color(&"accent")
	return _style_box(bg, border, 1, 8)


static func button_style(tone: StringName = &"secondary", hover: bool = false, pressed: bool = false) -> StyleBoxFlat:
	var bg := Color(0.030, 0.054, 0.060, 0.94)
	var border := color(&"muted")
	match tone:
		&"primary":
			border = color(&"accent")
		&"warning":
			border = color(&"warning")
		&"danger":
			border = color(&"danger")
		&"disabled":
			bg = Color(0.020, 0.028, 0.030, 0.70)
			border = color(&"muted")
		_:
			border = color(&"muted")
	if hover:
		bg = bg.lightened(0.08)
	if pressed:
		bg = bg.darkened(0.12)
	return _style_box(bg, border, 1 if not pressed else 2, 6)


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


static func _style_box(bg: Color, border: Color, border_width: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style
