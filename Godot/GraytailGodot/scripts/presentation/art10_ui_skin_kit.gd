extends RefCounted
class_name Art10UISkinKit

const ContentDBAccessScript := preload("res://scripts/core/content/content_db_access.gd")

# ART-10R UI skin kit is presentation-only. It owns shared pixel UI styling,
# player-visible copy cleanup, and Base confirmed draft layout metrics.

const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")

const DISPLAY_FONT_ASSET_ID := &"ui.font.fusion_pixel"
const READABLE_FONT_ASSET_ID := &"ui.art23.long_term.font.body"
const CANVAS_SIZE := Vector2(1280, 720)
const MIN_RUNTIME_UI_SCALE := 1.0
const MAX_RUNTIME_UI_SCALE := 1.5

static var _display_font_cache: Font
static var _readable_font_cache: Font
static var _player_ui_theme_cache: Theme
static var _runtime_ui_scale_factor := 1.0

const CONTROL_SLICE_INSETS := Vector4(18.0, 6.0, 18.0, 6.0)
const CONTROL_CONTENT_INSETS := Vector4(22.0, 5.0, 22.0, 5.0)
const POPUP_SLICE_INSETS := Vector4(20.0, 14.0, 20.0, 14.0)
const POPUP_CONTENT_INSETS := Vector4(24.0, 16.0, 24.0, 16.0)
const CONTROL_INSET_PROFILES := {
	&"compact": {
		"slice": Vector4(12.0, 5.0, 12.0, 5.0),
		"content": Vector4(12.0, 4.0, 12.0, 4.0),
		"minimum_size": Vector2(64.0, 32.0),
	},
	&"regular": {
		"slice": CONTROL_SLICE_INSETS,
		"content": CONTROL_CONTENT_INSETS,
		"minimum_size": Vector2(104.0, 38.0),
	},
	&"large": {
		"slice": Vector4(24.0, 9.0, 24.0, 9.0),
		"content": Vector4(28.0, 8.0, 28.0, 8.0),
		"minimum_size": Vector2(180.0, 50.0),
	},
}

const FONT_TOKENS := {
	&"title": 54,
	&"page_title": 38,
	&"section_title": 22,
	&"main_button": 26,
	&"button": 18,
	&"tab": 17,
	&"body": 16,
	&"body_small": 14,
	&"caption": 13,
	&"numeric": 18,
	&"key_prompt": 13,
	&"hud": 15,
	&"hud_small": 13,
}

const TEXT_BUDGETS := {
	&"page_title": {"lines": 1, "chars": 18},
	&"section_title": {"lines": 1, "chars": 16},
	&"main_button": {"lines": 2, "chars": 10},
	&"button": {"lines": 1, "chars": 10},
	&"tab": {"lines": 1, "chars": 8},
	&"body": {"lines": 3, "chars": 18},
	&"body_small": {"lines": 3, "chars": 16},
	&"caption": {"lines": 2, "chars": 14},
	&"key_prompt": {"lines": 1, "chars": 8},
	&"hud": {"lines": 3, "chars": 16},
	&"hud_small": {"lines": 2, "chars": 14},
}

const LABEL_SAFE_PADDING := {
	&"page_title": Vector2(10, 8),
	&"section_title": Vector2(10, 7),
	&"main_button": Vector2(12, 8),
	&"button": Vector2(10, 6),
	&"tab": Vector2(8, 6),
	&"body": Vector2(10, 7),
	&"body_small": Vector2(9, 6),
	&"caption": Vector2(8, 6),
	&"key_prompt": Vector2(6, 4),
	&"hud": Vector2(9, 6),
	&"hud_small": Vector2(7, 5),
}

const DISPLAY_FONT_TOKENS := [
	&"numeric",
	&"key_prompt",
	&"hud",
	&"hud_small",
]

# Shared semantic contract for text laid over framed art. Consumers may keep
# their own geometry, but must choose one of these roles instead of treating
# every label as the same font and padding case.
const COMPOSITION_DESCRIPTORS := {
	&"title": {
		"font_role": &"readable",
		"font_token": &"page_title",
		"text_budget_token": &"page_title",
		"max_lines": 1,
		"panel_safe_margin": 20,
		"label_safe_padding": Vector2(10, 8),
	},
	&"body": {
		"font_role": &"readable",
		"font_token": &"body",
		"text_budget_token": &"body",
		"max_lines": 3,
		"panel_safe_margin": 16,
		"label_safe_padding": Vector2(10, 7),
	},
	&"button": {
		"font_role": &"readable",
		"font_token": &"button",
		"text_budget_token": &"button",
		"max_lines": 1,
		"panel_safe_margin": 14,
		"label_safe_padding": Vector2(10, 6),
	},
	&"status": {
		"font_role": &"readable",
		"font_token": &"hud",
		"text_budget_token": &"hud_small",
		"max_lines": 1,
		"panel_safe_margin": 12,
		"label_safe_padding": Vector2(7, 5),
	},
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
	&"panel": Color(0.020, 0.041, 0.046, 0.48),
	&"panel_deep": Color(0.010, 0.022, 0.028, 0.58),
	&"panel_soft": Color(0.050, 0.078, 0.074, 0.32),
	&"slot": Color(0.038, 0.064, 0.064, 0.58),
	&"gold": Color(0.94, 0.70, 0.28, 1.0),
	&"gold_dark": Color(0.28, 0.18, 0.06, 0.96),
	&"accent": Color(0.58, 0.93, 0.76, 1.0),
	&"warning": Color(0.95, 0.72, 0.30, 1.0),
	&"danger": Color(0.94, 0.34, 0.28, 1.0),
	&"shadow": Color(0.0, 0.0, 0.0, 0.42),
	&"disabled": Color(0.27, 0.32, 0.31, 0.76),
}

const VISUAL_STATE_TONES := {
	&"normal": &"secondary",
	&"hover": &"primary",
	&"selected": &"selected",
	&"disabled": &"disabled",
	&"locked": &"locked",
	&"warning": &"warning",
	&"danger": &"danger",
	&"new": &"new",
	&"reward": &"reward",
	&"ready": &"ready",
	&"preview": &"secondary",
	&"owned": &"primary",
	&"configured": &"selected",
	&"pending": &"warning",
}

const MOTION_FALLBACKS := {
	&"feedback_pulse": &"static_state_tint",
	&"panel_open": &"instant_visible",
	&"pickup_feedback": &"static_state_tint",
	&"capacity_blocked": &"warning_tint",
	&"reward_feedback": &"accent_tint",
}

const MAIN_MENU_RECTS := {
	"title": Rect2(64, 58, 420, 116),
	"role": Rect2(64, 200, 280, 320),
	"top_shortcuts": Rect2(760, 62, 430, 44),
	"entry_stack": Rect2(760, 148, 430, 390),
	"notice": Rect2(64, 540, 560, 74),
	"meta": Rect2(366, 436, 310, 68),
	"bottom_key_bar": Rect2(64, 642, 380, 58),
}

const DEPLOY_RECTS := {
	"left_column": Rect2(32, 88, 280, 596),
	"mode_switch_buttons": Rect2(32, 28, 280, 42),
	"center_column": Rect2(340, 160, 590, 380),
	"center_detail": Rect2(340, 554, 590, 88),
	"summary_column": Rect2(952, 88, 286, 396),
	"action_cluster": Rect2(952, 506, 286, 160),
	"tab_row": Rect2(398, 34, 470, 58),
	"filter_row": Rect2(372, 104, 526, 44),
	"bottom_key_bar": Rect2(340, 642, 590, 48),
}

const LONG_TERM_RECTS := {
	"profile_column": Rect2(32, 88, 280, 596),
	"mode_switch_buttons": Rect2(32, 28, 280, 42),
	"card_grid": Rect2(340, 116, 590, 520),
	"detail_column": Rect2(952, 88, 286, 548),
	"tab_row": Rect2(398, 34, 470, 58),
	"appearance_button": Rect2(86, 596, 170, 46),
}

const RUN_RECTS := {
	"left_info_rail": Rect2(0, 0, 292, 720),
	"gameplay_viewport": Rect2(292, 0, 988, 720),
	"right_status": Rect2(1054, 24, 202, 108),
	"bottom_info": Rect2(412, 590, 620, 44),
	"bottom_key_bar": Rect2(320, 656, 928, 64),
	"map_overlay": Rect2(0, 0, 1280, 720),
}


static func pixel_font() -> Resource:
	if _display_font_cache != null:
		return _display_font_cache
	var display_font := _font_asset(DISPLAY_FONT_ASSET_ID)
	if display_font == null:
		return null
	var readable_fallback := _font_asset(READABLE_FONT_ASSET_ID)
	_apply_player_font_runtime_policy(display_font, true)
	_apply_player_font_runtime_policy(readable_fallback, false)
	var font_stack := FontVariation.new()
	font_stack.resource_name = "FusionPixelDisplayWithNotoGlyphFallback"
	font_stack.base_font = display_font
	if readable_fallback != null:
		font_stack.fallbacks = [readable_fallback]
	_display_font_cache = font_stack
	return _display_font_cache


static func readable_font() -> Resource:
	if _readable_font_cache != null:
		return _readable_font_cache
	var readable_base := _font_asset(DISPLAY_FONT_ASSET_ID)
	if readable_base == null:
		return pixel_font()
	_apply_player_font_runtime_policy(readable_base, true)
	var glyph_fallback := _font_asset(READABLE_FONT_ASSET_ID)
	_apply_player_font_runtime_policy(glyph_fallback, false)
	var font_stack := FontVariation.new()
	font_stack.resource_name = "FusionPixelReadableWithNotoGlyphFallback"
	font_stack.base_font = readable_base
	if glyph_fallback != null:
		font_stack.fallbacks = [glyph_fallback]
	_readable_font_cache = font_stack
	return _readable_font_cache


static func font_for_role(role: StringName) -> Resource:
	return pixel_font() if role == &"display" else readable_font()


static func set_runtime_ui_scale_factor(value: float) -> float:
	var resolved := normalize_runtime_ui_scale_factor(value)
	_runtime_ui_scale_factor = resolved
	if _player_ui_theme_cache != null:
		_apply_runtime_ui_scale_to_theme(_player_ui_theme_cache)
	return _runtime_ui_scale_factor


static func runtime_ui_scale_factor() -> float:
	return _runtime_ui_scale_factor


static func normalize_runtime_ui_scale_factor(value: float) -> float:
	return clampf(value, MIN_RUNTIME_UI_SCALE, MAX_RUNTIME_UI_SCALE)


static func scaled_font_size(base_size: int, factor: float = -1.0) -> int:
	var resolved_factor := _runtime_ui_scale_factor if factor <= 0.0 else normalize_runtime_ui_scale_factor(factor)
	return maxi(1, int(round(float(base_size) * resolved_factor)))


static func scaled_control_minimum(base_size: Vector2, factor: float = -1.0) -> Vector2:
	var resolved_factor := _runtime_ui_scale_factor if factor <= 0.0 else normalize_runtime_ui_scale_factor(factor)
	return (base_size * resolved_factor).round()


static func player_ui_font() -> Font:
	return readable_font() as Font


static func _apply_player_font_runtime_policy(font: Font, pixel_primary: bool) -> void:
	if not (font is FontFile):
		return
	var font_file := font as FontFile
	font_file.allow_system_fallback = false
	if pixel_primary:
		font_file.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		font_file.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	else:
		font_file.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		font_file.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO


static func player_ui_theme() -> Theme:
	if _player_ui_theme_cache != null:
		return _player_ui_theme_cache
	var readable := readable_font()
	var shared_theme := Theme.new()
	shared_theme.resource_name = "I4RoleSeparatedPlayerUITheme"
	shared_theme.set_type_variation(&"TooltipLabel", &"Label")
	shared_theme.set_type_variation(&"TooltipPanel", &"PopupPanel")
	if readable is Font:
		shared_theme.default_font = readable as Font
	shared_theme.default_font_size = font_size(&"body")
	for theme_type in [
		&"Label",
		&"CheckBox",
		&"CheckButton",
		&"OptionButton",
		&"PopupMenu",
		&"TooltipLabel",
		&"LineEdit",
		&"TextEdit",
		&"ItemList",
		&"Tree",
	]:
		if readable is Font:
			shared_theme.set_font(&"font", theme_type, readable as Font)
	for theme_type in [&"Button", &"MenuButton", &"TabBar"]:
		if readable is Font:
			shared_theme.set_font(&"font", theme_type, readable as Font)
	for rich_font_name in [
		&"normal_font",
		&"bold_font",
		&"italics_font",
		&"bold_italics_font",
		&"mono_font",
	]:
		if readable is Font:
			shared_theme.set_font(rich_font_name, &"RichTextLabel", readable as Font)
	shared_theme.set_font_size(&"font_size", &"TooltipLabel", font_size(&"body_small"))
	shared_theme.set_color(&"font_color", &"TooltipLabel", color(&"text"))
	shared_theme.set_color(&"font_color", &"PopupMenu", color(&"text"))
	_configure_shared_control_theme(shared_theme)
	_apply_runtime_ui_scale_to_theme(shared_theme)
	var tooltip_style := style_box_from_asset_ref(
		Art21UIPlacementContractScript.panel_ref(&"tooltip"),
		12,
		12
	)
	if tooltip_style != null:
		shared_theme.set_stylebox(&"panel", &"TooltipPanel", tooltip_style)
	_player_ui_theme_cache = shared_theme
	return _player_ui_theme_cache


static func _apply_runtime_ui_scale_to_theme(shared_theme: Theme) -> void:
	if shared_theme == null:
		return
	shared_theme.default_font_size = scaled_font_size(font_size(&"body"))
	var type_tokens := {
		&"Label": &"body",
		&"Button": &"button",
		&"CheckBox": &"body",
		&"CheckButton": &"body",
		&"MenuButton": &"button",
		&"OptionButton": &"body",
		&"PopupMenu": &"body",
		&"TooltipLabel": &"body_small",
		&"LineEdit": &"body",
		&"TextEdit": &"body",
		&"ItemList": &"body",
		&"Tree": &"body",
		&"TabBar": &"tab",
	}
	for theme_type_variant in type_tokens:
		var theme_type := StringName(theme_type_variant)
		var token := StringName(type_tokens[theme_type_variant])
		shared_theme.set_font_size(&"font_size", theme_type, scaled_font_size(font_size(token)))
	for rich_font_size_name in [
		&"normal_font_size",
		&"bold_font_size",
		&"italics_font_size",
		&"bold_italics_font_size",
		&"mono_font_size",
	]:
		shared_theme.set_font_size(
			rich_font_size_name,
			&"RichTextLabel",
			scaled_font_size(font_size(&"body"))
		)
	shared_theme.set_meta("runtime_ui_scale_factor", _runtime_ui_scale_factor)


static func apply_player_ui_theme(root_control: Control) -> void:
	if root_control == null:
		return
	root_control.theme = player_ui_theme()


static func apply_player_ui_font(control: Control, role: StringName = &"readable") -> void:
	if control == null:
		return
	var font := font_for_role(role)
	if not (font is Font):
		return
	if control is RichTextLabel:
		for rich_font_name in [
			&"normal_font",
			&"bold_font",
			&"italics_font",
			&"bold_italics_font",
			&"mono_font",
		]:
			control.add_theme_font_override(rich_font_name, font as Font)
		control.set_meta("ui_font_role", role)
		return
	control.add_theme_font_override(&"font", font as Font)
	control.set_meta("ui_font_role", role)


static func apply_option_button_theme(option: OptionButton) -> void:
	if option == null:
		return
	var shared_theme := player_ui_theme()
	option.theme = shared_theme
	var popup := option.get_popup()
	if popup != null:
		popup.theme = shared_theme


static func _configure_shared_control_theme(shared_theme: Theme) -> void:
	if shared_theme == null:
		return
	var normal := registered_control_style(&"secondary")
	var hover := registered_control_style(&"primary")
	var pressed := registered_control_style(&"primary")
	var disabled := registered_control_style(&"disabled")
	var focus := registered_control_style(&"focus")
	for theme_type in [&"Button", &"MenuButton", &"OptionButton", &"CheckBox", &"CheckButton"]:
		shared_theme.set_stylebox(&"normal", theme_type, normal)
		shared_theme.set_stylebox(&"hover", theme_type, hover)
		shared_theme.set_stylebox(&"pressed", theme_type, pressed)
		shared_theme.set_stylebox(&"hover_pressed", theme_type, pressed)
		shared_theme.set_stylebox(&"disabled", theme_type, disabled)
		shared_theme.set_stylebox(&"focus", theme_type, focus)
		shared_theme.set_color(&"font_color", theme_type, color(&"text"))
		shared_theme.set_color(&"font_hover_color", theme_type, color(&"accent"))
		shared_theme.set_color(&"font_pressed_color", theme_type, color(&"gold"))
		shared_theme.set_color(&"font_focus_color", theme_type, color(&"accent"))
		shared_theme.set_color(&"font_disabled_color", theme_type, color(&"muted"))
		shared_theme.set_constant(&"h_separation", theme_type, 10)
		shared_theme.set_constant(&"outline_size", theme_type, 0)
	shared_theme.set_constant(&"arrow_margin", &"OptionButton", 12)

	var popup_panel := registered_popup_style()
	var popup_row := registered_control_style(&"row")
	var popup_row_hover := registered_control_style(&"primary")
	shared_theme.set_stylebox(&"panel", &"PopupMenu", popup_panel)
	shared_theme.set_stylebox(&"panel", &"PopupPanel", popup_panel)
	shared_theme.set_stylebox(&"hover", &"PopupMenu", popup_row_hover)
	shared_theme.set_stylebox(&"separator", &"PopupMenu", popup_row)
	shared_theme.set_stylebox(&"labeled_separator_left", &"PopupMenu", popup_row)
	shared_theme.set_stylebox(&"labeled_separator_right", &"PopupMenu", popup_row)
	shared_theme.set_color(&"font_hover_color", &"PopupMenu", color(&"gold"))
	shared_theme.set_color(&"font_disabled_color", &"PopupMenu", color(&"muted"))
	shared_theme.set_color(&"font_accelerator_color", &"PopupMenu", color(&"caption"))
	shared_theme.set_color(&"font_separator_color", &"PopupMenu", color(&"muted"))
	shared_theme.set_constant(&"item_start_padding", &"PopupMenu", 12)
	shared_theme.set_constant(&"item_end_padding", &"PopupMenu", 12)
	shared_theme.set_constant(&"v_separation", &"PopupMenu", 4)
	shared_theme.set_constant(&"outline_size", &"PopupMenu", 0)

	var slider_track := registered_slider_style(&"secondary")
	var slider_fill := registered_slider_style(&"primary")
	shared_theme.set_stylebox(&"slider", &"HSlider", slider_track)
	shared_theme.set_stylebox(&"grabber_area", &"HSlider", slider_fill)
	shared_theme.set_stylebox(&"grabber_area_highlight", &"HSlider", slider_fill)
	shared_theme.set_constant(&"center_grabber", &"HSlider", 1)
	shared_theme.set_constant(&"grabber_offset", &"HSlider", 0)

	var off_icon := _shared_arrow_icon(false, false)
	var on_icon := _shared_arrow_icon(true, true)
	var hover_icon := _shared_arrow_icon(true, false)
	if off_icon != null and on_icon != null:
		for icon_name in [&"unchecked", &"unchecked_disabled", &"unchecked_hover", &"unchecked_pressed", &"unchecked_hover_pressed"]:
			shared_theme.set_icon(icon_name, &"CheckButton", off_icon)
			shared_theme.set_icon(icon_name, &"CheckBox", off_icon)
		for icon_name in [&"checked", &"checked_disabled", &"checked_hover", &"checked_pressed", &"checked_hover_pressed"]:
			shared_theme.set_icon(icon_name, &"CheckButton", on_icon)
			shared_theme.set_icon(icon_name, &"CheckBox", on_icon)
		shared_theme.set_icon(&"arrow", &"OptionButton", hover_icon if hover_icon != null else on_icon)
		shared_theme.set_icon(&"arrow_mirrored", &"OptionButton", off_icon)
		shared_theme.set_icon(&"checked", &"PopupMenu", on_icon)
		shared_theme.set_icon(&"unchecked", &"PopupMenu", off_icon)
		shared_theme.set_icon(&"radio_checked", &"PopupMenu", on_icon)
		shared_theme.set_icon(&"radio_unchecked", &"PopupMenu", off_icon)
		shared_theme.set_icon(&"submenu", &"PopupMenu", hover_icon if hover_icon != null else on_icon)
		shared_theme.set_icon(&"submenu_mirrored", &"PopupMenu", off_icon)
		shared_theme.set_icon(&"grabber", &"HSlider", hover_icon if hover_icon != null else on_icon)
		shared_theme.set_icon(&"grabber_highlight", &"HSlider", on_icon)
		shared_theme.set_icon(&"grabber_disabled", &"HSlider", off_icon)


static func control_inset_profile(size_class: StringName = &"regular") -> Dictionary:
	var value: Variant = CONTROL_INSET_PROFILES.get(size_class, CONTROL_INSET_PROFILES[&"regular"])
	return (value as Dictionary).duplicate(true)


static func registered_control_style(state: StringName = &"secondary", size_class: StringName = &"regular") -> StyleBox:
	var visual_key := &"art21r2.modal.button.secondary"
	match state:
		&"primary", &"selected":
			visual_key = &"art21r2.modal.button.primary"
		&"danger":
			visual_key = &"art21r2.modal.button.danger"
		&"row":
			visual_key = &"art21r2.modal.item_row.normal"
	var inset_profile := control_inset_profile(size_class)
	var slice_insets: Vector4 = inset_profile.get("slice", CONTROL_SLICE_INSETS)
	var content_insets: Vector4 = inset_profile.get("content", CONTROL_CONTENT_INSETS)
	var style := _registered_texture_style(
		visual_key,
		&"ui.art19.button.dark",
		slice_insets,
		content_insets
	)
	if style == null:
		return button_style(&"primary" if state == &"primary" else &"secondary")
	if state == &"focus" and style is StyleBoxTexture:
		(style as StyleBoxTexture).draw_center = false
	if style != null:
		style.set_meta("ui_control_size_class", size_class)
	return style


static func registered_popup_style() -> StyleBox:
	var style := _registered_texture_style(
		&"art21r2.modal.section.panel",
		&"ui.art19.panel.terminal_main",
		POPUP_SLICE_INSETS,
		POPUP_CONTENT_INSETS
	)
	return style if style != null else panel_style(&"deep")


static func registered_slider_style(state: StringName = &"secondary") -> StyleBox:
	var visual_key := &"art21r2.modal.button.primary" if state == &"primary" else &"art21r2.modal.button.secondary"
	var style := _registered_texture_style(
		visual_key,
		&"ui.art19.button.dark",
		Vector4(18.0, 7.0, 18.0, 7.0),
		Vector4(2.0, 6.0, 2.0, 6.0)
	)
	return style if style != null else transparent_style_box(2)


static func _registered_texture_style(
	visual_key: StringName,
	fallback_asset_id: StringName,
	slice_insets: Vector4,
	content_insets: Vector4
) -> StyleBoxTexture:
	var texture := Art21UIPlacementContractScript.texture_for_visual_key(visual_key, fallback_asset_id)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = slice_insets.x
	style.texture_margin_top = slice_insets.y
	style.texture_margin_right = slice_insets.z
	style.texture_margin_bottom = slice_insets.w
	style.content_margin_left = content_insets.x
	style.content_margin_top = content_insets.y
	style.content_margin_right = content_insets.z
	style.content_margin_bottom = content_insets.w
	style.draw_center = true
	return style


static func _shared_arrow_icon(selected: bool, point_right: bool) -> Texture2D:
	var visual_key := &"shared.button.secondary.selected" if selected else &"shared.button.secondary.normal"
	var fallback_asset_id := &"ui.art19.button.selected_tab" if selected else &"ui.art19.button.dark"
	var texture := Art21UIPlacementContractScript.texture_for_visual_key(visual_key, fallback_asset_id)
	if texture == null:
		return null
	var width := float(texture.get_width())
	var height := float(texture.get_height())
	if width < 52.0 or height < 24.0:
		return texture
	var icon := AtlasTexture.new()
	icon.atlas = texture
	var icon_width := 28.0
	var icon_height := minf(28.0, height)
	var x := width - icon_width - 6.0 if point_right else 6.0
	icon.region = Rect2(x, (height - icon_height) * 0.5, icon_width, icon_height)
	return icon


static func _font_asset(asset_id: StringName) -> Font:
	var resource := ContentDBAccessScript.get_asset_ref(asset_id)
	if resource is Font:
		return resource as Font
	return null


static func font_role_for_token(token: StringName) -> StringName:
	return &"display" if DISPLAY_FONT_TOKENS.has(token) else &"readable"


static func composition_descriptor(role: StringName) -> Dictionary:
	var value: Variant = COMPOSITION_DESCRIPTORS.get(role, COMPOSITION_DESCRIPTORS[&"body"])
	return (value as Dictionary).duplicate(true) if value is Dictionary else COMPOSITION_DESCRIPTORS[&"body"].duplicate(true)


static func composition_panel_safe_margin(role: StringName) -> int:
	return int(composition_descriptor(role).get("panel_safe_margin", 16))


static func art19_texture(role: StringName) -> Texture2D:
	return Art09ManifestAssetMappingScript.resolve_texture(Art09ManifestAssetMappingScript.art19_skin_ref(role))


static func art21_texture(role: StringName) -> Texture2D:
	var asset_ref: Dictionary
	match role:
		&"button_confirm", &"button_primary", &"button_primary_hover", &"button_primary_pressed", &"button_primary_disabled", &"button_dark", &"button_secondary", &"button_selected_tab", &"tab_normal", &"tab_selected":
			asset_ref = Art21UIPlacementContractScript.button_ref(role)
		_:
			asset_ref = Art21UIPlacementContractScript.panel_ref(role)
	return Art09ManifestAssetMappingScript.resolve_texture(asset_ref)


static func font_size(token: StringName, fallback: int = 15) -> int:
	var value: Variant = FONT_TOKENS.get(token, fallback)
	return int(value) if value is int else fallback


static func font_line_height(token: StringName) -> int:
	var resolved_size := font_size(token)
	return resolved_size + _line_spacing_for(resolved_size)


static func text_budget(token: StringName) -> Dictionary:
	var value: Variant = TEXT_BUDGETS.get(token, TEXT_BUDGETS[&"body"])
	return (value as Dictionary).duplicate(true) if value is Dictionary else TEXT_BUDGETS[&"body"].duplicate(true)


static func label_safe_padding(token: StringName) -> Vector2:
	var value: Variant = LABEL_SAFE_PADDING.get(token, Vector2(8, 6))
	return value if value is Vector2 else Vector2(8, 6)


static func icon_size(token: StringName, fallback: int = 28) -> int:
	var value: Variant = ICON_SIZES.get(token, fallback)
	return int(value) if value is int else fallback


static func color(token: StringName, fallback: Color = Color.WHITE) -> Color:
	var value: Variant = COLORS.get(token, fallback)
	return value if value is Color else fallback


static func visual_state_tone(value: Variant, selected: bool = false) -> StringName:
	if selected:
		return &"selected"
	var key := StringName(String(value).to_lower())
	var tone: Variant = VISUAL_STATE_TONES.get(key, &"secondary")
	return tone if tone is StringName else &"secondary"


static func sanitize_player_copy(text: String) -> String:
	var result := text
	result = _sanitize_engineering_copy(result)
	while result.find("  ") >= 0:
		result = result.replace("  ", " ")
	return result.strip_edges()


static func short_summary(text: String, max_chars: int = 18) -> String:
	var safe := sanitize_player_copy(text)
	safe = safe.replace("\r", " ")
	safe = safe.replace("\n", " ")
	while safe.find("  ") >= 0:
		safe = safe.replace("  ", " ")
	safe = safe.strip_edges()
	if max_chars <= 0 or safe.length() <= max_chars:
		return safe
	for separator in ["。", "；", "，", "、", "/", "|", " "]:
		var index := safe.find(separator)
		if index > 4 and index <= max_chars:
			return safe.substr(0, index).strip_edges()
	return safe.substr(0, max_chars).strip_edges()


static func budgeted_lines_text(lines: Array, max_lines: int = -1, max_chars: int = -1, bullet: bool = true) -> String:
	var resolved_lines := max_lines
	var resolved_chars := max_chars
	if resolved_lines <= 0 or resolved_chars <= 0:
		var budget := text_budget(&"body")
		if resolved_lines <= 0:
			resolved_lines = int(budget.get("lines", 3))
		if resolved_chars <= 0:
			resolved_chars = int(budget.get("chars", 18))
	var parts: Array[String] = []
	var visible_count: int = int(min(lines.size(), resolved_lines))
	for index in range(visible_count):
		var line := short_summary(String(lines[index]), resolved_chars)
		if line == "":
			continue
		parts.append("- %s" % line if bullet else line)
	if lines.size() > visible_count:
		parts.append("更多内容已收起")
	return sanitize_player_copy("\n".join(parts))


static func readable_section_text(title: String, lines: Array, max_lines: int = 2, max_chars: int = 16) -> String:
	var body := budgeted_lines_text(lines, max_lines, max_chars, true)
	if body == "":
		return sanitize_player_copy(title)
	return "%s\n%s" % [sanitize_player_copy(title), body]


static func status_label(value: Variant) -> String:
	var raw := String(value)
	var lowered_raw := raw.to_lower()
	var labels := {
		"preview": "可查看",
		"preview_only": "可查看",
		"display_only": "展示",
		"read_only": "查看",
		"pending": "待确认",
		"selected": "已选择",
		"configured": "已配置",
		"owned": "已拥有",
		"locked": "未开放",
		"disabled": "未开放",
		"normal": "可用",
		"ready": "就绪",
		"reward": "奖励",
		"new": "新",
		"warning": "需注意",
		"danger": "高风险",
	}
	if labels.has(lowered_raw):
		return String(labels[lowered_raw])
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


static func _sanitize_engineering_copy(text: String) -> String:
	var result := text
	var replacements := {
		"DEBUG": "诊断",
		"Debug": "诊断",
		"debug": "诊断",
		"Legacy": "",
		"legacy": "",
		"draft": "整备",
		"Draft": "整备",
		"preview_only": "可查看",
		"preview": "可查看",
		"Preview": "可查看",
		"display-only": "展示",
		"display_only": "展示",
		"read_only": "查看",
		"no_persistence": "本轮不保存",
		"schema": "结构",
		"interface": "联动",
		"Interface": "联动",
		"G24": "长期系统",
		"G30": "内容接口",
		"preview cards": "展示条目",
		"slot": "位置",
		"Slot": "位置",
		"card": "条目",
		"Card": "条目",
		"tab_icon_key": "标签图标",
		"module_icon_key": "模块图标",
		"module_banner_key": "模块横幅",
		"description_key": "说明文本",
		"localization_key": "文本",
		"ui_group_key": "分组",
		"art_key": "美术标记",
		"_key": "标记",
		" key": " 标记",
		"enum": "类型",
		"locked": "未开放",
		"Locked": "未开放",
		"spawn": "出现",
		"eligible": "可处理",
		"not_ready": "未就绪",
		"blocked_capacity": "容量不足",
		"command.accepted": "操作已确认",
		"intent": "操作",
		"RunStartConfig": "出发配置",
		"Deploy Prep full module content": "出发整备内容",
		"seed_policy": "路线生成",
		"defer_until_run_start": "开始时确定",
		"deploy_prep_projection": "出发摘要",
		"projection_type": "路线摘要",
		"standard_10x10": "标准探索",
		"M3R minimal": "标准探索",
		"selected_equ": "装备已选",
		"no full dep": "待确认",
		"full dep": "完整配置",
		"RewardBundle": "奖励包",
		"events": "事件",
		"required_permission": "许可条件",
		"future_permission_hook": "后续许可",
		"runtime progress": "探索进度",
		"reward grant": "奖励发放",
		"long-term objective write": "目标记录",
		"active_run_persistence": "探索存档",
		"RunBootstrapper": "探索启动器",
		"SettlementSnapshot": "结算记录",
		"detail": "详情",
		"Normal": "普通",
		"standard": "标准",
		"running": "探索中",
	}
	for key in replacements.keys():
		result = result.replace(String(key), String(replacements[key]))
	return result


static func apply_visual_state(control: Control, state: Variant, selected: bool = false) -> void:
	if control == null:
		return
	var tone := visual_state_tone(state, selected)
	if control is Button:
		apply_button_token(control as Button, tone, &"body", &"button")
	elif control is PanelContainer:
		apply_panel(control as PanelContainer, tone)


static func apply_label(label: Label, font_size_value: int = -1, font_color: Color = Color(-1, -1, -1, -1)) -> void:
	_apply_label_with_font(label, readable_font(), font_size_value, font_color)
	if label != null:
		label.set_meta("ui_composition_role", &"body")
		label.set_meta("ui_font_role", &"readable")
		label.set_meta("ui_font_token", &"body" if font_size_value <= 0 or font_size_value >= font_size(&"body") else &"body_small")


static func apply_composition_label(label: Label, role: StringName, font_size_value: int = -1, font_color: Color = Color(-1, -1, -1, -1)) -> void:
	if label == null:
		return
	var descriptor := composition_descriptor(role)
	var token := StringName(descriptor.get("font_token", &"body"))
	var resolved_size := font_size_value if font_size_value > 0 else font_size(token)
	_apply_label_with_font(label, font_for_role(StringName(descriptor.get("font_role", &"readable"))), resolved_size, font_color)
	label.set_meta("ui_composition_role", role)
	label.set_meta("ui_font_role", StringName(descriptor.get("font_role", &"readable")))
	label.set_meta("ui_font_token", token)
	label.set_meta("ui_panel_safe_margin", int(descriptor.get("panel_safe_margin", 16)))
	label.set_meta("ui_label_safe_padding", descriptor.get("label_safe_padding", Vector2(8, 6)))


static func _apply_label_with_font(label: Label, font_resource: Resource, font_size_value: int, font_color: Color) -> void:
	if label == null:
		return
	label.text = sanitize_player_copy(label.text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	if font_resource is Font:
		label.add_theme_font_override("font", font_resource as Font)
	var resolved_size := font_size_value if font_size_value > 0 else font_size(&"body")
	label.add_theme_font_size_override("font_size", resolved_size)
	label.add_theme_constant_override("line_spacing", _line_spacing_for(resolved_size))
	if font_color.a >= 0.0:
		label.add_theme_color_override("font_color", font_color)


static func apply_label_token(label: Label, token: StringName, color_token: StringName = &"text") -> void:
	if label == null:
		return
	_apply_label_with_font(label, font_for_role(font_role_for_token(token)), font_size(token), color(color_token))
	label.set_meta("ui_composition_role", &"title" if font_role_for_token(token) == &"display" else &"body")
	label.set_meta("ui_font_role", font_role_for_token(token))
	label.set_meta("ui_font_token", token)


static func apply_button(button: Button, tone: StringName = &"secondary", font_size_value: int = -1, icon_token: StringName = &"button", font_role: StringName = &"readable") -> void:
	if button == null:
		return
	button.focus_mode = Control.FOCUS_ALL
	button.text = sanitize_player_copy(button.text)
	button.tooltip_text = sanitize_player_copy(button.tooltip_text)
	var font := font_for_role(font_role)
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
	button.add_theme_stylebox_override("focus", button_style(tone, true, false))
	button.add_theme_stylebox_override("disabled", button_style(&"disabled", false, false))
	button.modulate = Color(1, 1, 1, 1) if not button.disabled else Color(0.72, 0.76, 0.74, 1.0)
	button.set_meta("ui_composition_role", &"button")
	button.set_meta("ui_font_role", font_role)
	button.set_meta("ui_font_token", &"button")
	button.set_meta("ui_panel_safe_margin", composition_panel_safe_margin(&"button"))


static func apply_transparent_button(button: Button, tone: StringName = &"secondary", font_size_value: int = -1, icon_token: StringName = &"button", padding: int = 2, font_role: StringName = &"readable") -> void:
	if button == null:
		return
	apply_button(button, tone, font_size_value, icon_token, font_role)
	button.add_theme_stylebox_override("normal", transparent_style_box(padding))
	button.add_theme_stylebox_override("hover", transparent_style_box(padding))
	button.add_theme_stylebox_override("pressed", transparent_style_box(padding))
	button.add_theme_stylebox_override("disabled", transparent_style_box(padding))


static func apply_button_token(button: Button, tone: StringName, token: StringName, icon_token: StringName = &"button") -> void:
	apply_button(button, tone, font_size(token), icon_token)
	if button != null:
		button.set_meta("ui_font_token", token)


static func apply_transparent_button_token(button: Button, tone: StringName, token: StringName, icon_token: StringName = &"button", padding: int = 2) -> void:
	apply_transparent_button(button, tone, font_size(token), icon_token, padding)
	if button != null:
		button.set_meta("ui_font_token", token)


static func style_box_from_asset_ref(asset_ref: Dictionary, padding: int = 8, texture_margin: int = 16) -> StyleBoxTexture:
	var texture := Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
	return style_box_from_texture(texture, padding, texture_margin)


static func style_box_from_asset_ref_with_insets(
	asset_ref: Dictionary,
	content_insets: Vector4,
	slice_insets: Vector4
) -> StyleBoxTexture:
	var texture := Art09ManifestAssetMappingScript.resolve_texture(asset_ref)
	return style_box_from_texture_with_insets(texture, content_insets, slice_insets)


static func style_box_from_texture(texture: Texture2D, padding: int = 8, texture_margin: int = 16) -> StyleBoxTexture:
	if texture == null:
		return null
	var slice_margin := maxi(texture_margin, 0)
	var content_inset := safe_content_margin(padding, slice_margin)
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = slice_margin
	style.texture_margin_top = slice_margin
	style.texture_margin_right = slice_margin
	style.texture_margin_bottom = slice_margin
	style.content_margin_left = content_inset
	style.content_margin_top = content_inset
	style.content_margin_right = content_inset
	style.content_margin_bottom = content_inset
	style.draw_center = true
	return style


static func style_box_from_texture_with_insets(
	texture: Texture2D,
	content_insets: Vector4,
	slice_insets: Vector4
) -> StyleBoxTexture:
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = maxf(0.0, slice_insets.x)
	style.texture_margin_top = maxf(0.0, slice_insets.y)
	style.texture_margin_right = maxf(0.0, slice_insets.z)
	style.texture_margin_bottom = maxf(0.0, slice_insets.w)
	style.content_margin_left = maxf(0.0, content_insets.x)
	style.content_margin_top = maxf(0.0, content_insets.y)
	style.content_margin_right = maxf(0.0, content_insets.z)
	style.content_margin_bottom = maxf(0.0, content_insets.w)
	style.draw_center = true
	style.set_meta("ui_content_insets_decoupled_from_slice", true)
	style.set_meta("ui_content_safe_insets", content_insets)
	style.set_meta("ui_texture_slice_insets", slice_insets)
	return style


static func safe_content_margin(padding: int, texture_margin: int) -> int:
	return maxi(maxi(padding, 0), maxi(texture_margin, 0))


static func apply_image_button_ref(button: Button, asset_ref: Dictionary, tone: StringName, token: StringName, icon_token: StringName = &"button", padding: int = 8, texture_margin: int = 16) -> void:
	if button == null:
		return
	apply_button_token(button, tone, token, icon_token)
	var normal := style_box_from_asset_ref(asset_ref, padding, texture_margin)
	if normal == null:
		return
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", style_box_from_asset_ref(asset_ref, padding, texture_margin))
	button.add_theme_stylebox_override("pressed", style_box_from_asset_ref(asset_ref, padding, texture_margin))
	button.add_theme_stylebox_override("disabled", style_box_from_asset_ref(asset_ref, padding, texture_margin))


static func apply_image_panel_ref(panel: PanelContainer, asset_ref: Dictionary, padding: int = 10, texture_margin: int = 18) -> void:
	if panel == null:
		return
	var style := style_box_from_asset_ref(asset_ref, padding, texture_margin)
	if style == null:
		return
	panel.add_theme_stylebox_override("panel", style)


static func make_image_frame_panel(node_name: String, rect: Rect2, asset_ref: Dictionary, padding: int = 10, texture_margin: int = 18) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_rect(panel, rect)
	apply_image_panel_ref(panel, asset_ref, padding, texture_margin)
	return panel


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


static func make_small_button(text: String, tone: StringName = &"secondary") -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(92, 32)
	button.focus_mode = Control.FOCUS_ALL
	apply_button_token(button, tone, &"caption", &"button")
	return button


static func make_tab_button(text: String, selected: bool = false, state: Variant = &"normal") -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_pressed = selected
	button.custom_minimum_size = Vector2(112, 40)
	button.focus_mode = Control.FOCUS_ALL
	apply_button_token(button, visual_state_tone(state, selected), &"tab", &"tab")
	return button


static func make_icon_slot(node_name: String, size: Vector2 = Vector2(52, 52), tone: StringName = &"slot") -> PanelContainer:
	var panel := make_frame_panel(node_name, Rect2(Vector2.ZERO, size), tone)
	panel.custom_minimum_size = size
	return panel


static func make_card_frame(node_name: String, rect: Rect2 = Rect2(), selected: bool = false) -> PanelContainer:
	return make_frame_panel(node_name, rect, &"selected" if selected else &"card")


static func make_summary_panel(node_name: String, rect: Rect2 = Rect2()) -> PanelContainer:
	return make_frame_panel(node_name, rect, &"summary")


static func make_notice_box(node_name: String, rect: Rect2 = Rect2()) -> PanelContainer:
	return make_frame_panel(node_name, rect, &"notice")


static func make_locked_overlay(node_name: String, rect: Rect2) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.name = node_name
	overlay.color = Color(0.0, 0.0, 0.0, 0.46)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_rect(overlay, rect)
	return overlay


static func make_badge(text: String, state: Variant = &"normal") -> Label:
	var label := Label.new()
	label.text = sanitize_player_copy(text)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(64, 24)
	apply_label_token(label, &"key_prompt", &"text")
	label.add_theme_stylebox_override("normal", panel_style(visual_state_tone(state)))
	return label


static func make_state_badge(state: Variant, text: String = "") -> Label:
	var label_text := text if text != "" else status_label(state)
	return make_badge(label_text, state)


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
	button.focus_mode = Control.FOCUS_ALL
	apply_button_token(button, &"secondary", &"key_prompt", &"key")
	return button


static func make_bottom_key_bar(node_name: String, rect: Rect2 = Rect2()) -> PanelContainer:
	return make_frame_panel(node_name, rect, &"surface")


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


static func viewport_size_for(owner: Control) -> Vector2:
	if owner == null:
		return CANVAS_SIZE
	var viewport_rect := owner.get_viewport_rect()
	if viewport_rect.size.x < 1.0 or viewport_rect.size.y < 1.0:
		return CANVAS_SIZE
	return viewport_rect.size


static func layout_profile_for(owner: Control) -> Dictionary:
	return UILayoutProfileScript.profile_for_size(viewport_size_for(owner))


static func layout_scale_for(owner: Control) -> float:
	var viewport_size := viewport_size_for(owner)
	return min(viewport_size.x / CANVAS_SIZE.x, viewport_size.y / CANVAS_SIZE.y)


static func layout_origin_for(owner: Control) -> Vector2:
	var viewport_size := viewport_size_for(owner)
	var scale := layout_scale_for(owner)
	var content_size := CANVAS_SIZE * scale
	return (viewport_size - content_size) * 0.5


static func layout_rect_for(owner: Control, base_rect: Rect2) -> Rect2:
	var scale := layout_scale_for(owner)
	return Rect2(layout_origin_for(owner) + base_rect.position * scale, base_rect.size * scale)


static func layout_size_for(owner: Control, base_size: Vector2) -> Vector2:
	var scale := layout_scale_for(owner)
	return base_size * scale


static func page_rect(owner: Control, group: StringName, key: String) -> Rect2:
	return layout_rect_for(owner, rect(group, key))


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


static func reduce_motion_enabled() -> bool:
	if ProjectSettings.has_setting("accessibility/reduce_motion"):
		return bool(ProjectSettings.get_setting("accessibility/reduce_motion"))
	if ProjectSettings.has_setting("display/window/reduce_motion"):
		return bool(ProjectSettings.get_setting("display/window/reduce_motion"))
	return false


static func motion_duration(default_duration: float, reduced_duration: float = 0.0) -> float:
	return reduced_duration if reduce_motion_enabled() else default_duration


static func feedback_color(state: StringName = &"warning") -> Color:
	match state:
		&"success", &"ready", &"reward":
			return color(&"accent")
		&"danger", &"blocked":
			return color(&"danger")
		&"warning":
			return color(&"warning")
		_:
			return color(&"accent")


static func animation_fallback_key(animation_key: StringName) -> StringName:
	return MOTION_FALLBACKS.get(animation_key, &"instant_visible")


static func play_feedback_pulse(control: Control, state: StringName = &"warning", strength: float = 1.0) -> void:
	if control == null:
		return
	var target := Color(1.0, 1.0, 1.0, 1.0).lerp(feedback_color(state), clampf(strength, 0.0, 1.0))
	if reduce_motion_enabled():
		control.modulate = target
		return
	var tween := control.create_tween()
	tween.tween_property(control, "modulate", target, motion_duration(0.06))
	tween.tween_property(control, "modulate", Color(1.0, 1.0, 1.0, 1.0), motion_duration(0.18))


static func play_panel_open(control: Control) -> void:
	if control == null:
		return
	if reduce_motion_enabled():
		control.modulate = Color(1.0, 1.0, 1.0, 1.0)
		return
	control.modulate.a = 0.0
	var tween := control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, motion_duration(0.12))


static func panel_style(tone: StringName = &"surface") -> StyleBox:
	var bg := color(&"panel")
	var border := color(&"accent")
	var border_width := 1
	var padding := 10
	var texture_role := &"panel_terminal"
	match tone:
		&"deep":
			bg = color(&"panel_deep")
			border = color(&"muted")
			border_width = 2
			padding = 12
			texture_role = &"panel_terminal"
		&"summary":
			bg = Color(0.044, 0.058, 0.058, 0.58)
			border = color(&"warning")
			border_width = 2
			padding = 12
			texture_role = &"panel_summary"
		&"notice":
			bg = Color(0.052, 0.061, 0.048, 0.54)
			border = color(&"gold")
			border_width = 2
			padding = 10
			texture_role = &"panel_summary"
		&"card":
			bg = Color(0.030, 0.052, 0.056, 0.56)
			border = Color(0.24, 0.36, 0.34, 1.0)
			border_width = 2
			padding = 12
			texture_role = &"panel_deploy_main"
		&"selected":
			bg = Color(0.050, 0.078, 0.066, 0.70)
			border = color(&"accent")
			border_width = 3
			padding = 12
			texture_role = &"panel_highlight"
		&"slot":
			bg = color(&"slot")
			border = Color(0.30, 0.46, 0.42, 1.0)
			border_width = 2
			padding = 6
			texture_role = &"button_dark"
		&"gold":
			bg = color(&"gold_dark")
			border = color(&"gold")
			border_width = 3
			padding = 12
			texture_role = &"button_confirm"
		&"reward":
			bg = Color(0.20, 0.13, 0.04, 0.68)
			border = color(&"gold")
			border_width = 2
			texture_role = &"button_confirm"
		&"ready":
			bg = Color(0.044, 0.078, 0.052, 0.66)
			border = color(&"accent")
			border_width = 2
			texture_role = &"button_selected_tab"
		&"new":
			bg = Color(0.050, 0.066, 0.088, 0.66)
			border = Color(0.55, 0.78, 0.96, 1.0)
			texture_role = &"button_selected_tab"
		&"locked":
			bg = Color(0.020, 0.026, 0.028, 0.52)
			border = color(&"disabled")
			texture_role = &"button_dark"
		&"warning":
			bg = Color(0.068, 0.050, 0.026, 0.68)
			border = color(&"warning")
			border_width = 2
			texture_role = &"panel_summary"
		&"danger":
			bg = Color(0.060, 0.032, 0.032, 0.68)
			border = color(&"danger")
			border_width = 2
			texture_role = &"button_dark"
		&"soft":
			bg = color(&"panel_soft")
			border = color(&"muted")
			padding = 8
			texture_role = &"panel_summary"
		_:
			bg = color(&"panel")
			border = color(&"accent")
	var textured := _texture_style_box(texture_role, padding, _texture_margin_for(texture_role))
	if textured != null:
		return textured
	return _style_box(bg, border, border_width, padding, 3)


static func button_style(tone: StringName = &"secondary", hover: bool = false, pressed: bool = false) -> StyleBox:
	var bg := Color(0.032, 0.056, 0.060, 0.95)
	var border := color(&"muted")
	var border_width := 1
	var padding := 8
	var texture_role := &"button_dark"
	match tone:
		&"primary":
			bg = Color(0.052, 0.082, 0.074, 0.99)
			border = color(&"accent")
			border_width = 2
			padding = 12
			texture_role = &"button_selected_tab"
		&"selected":
			bg = Color(0.066, 0.100, 0.082, 1.0)
			border = color(&"accent")
			border_width = 3
			padding = 12
			texture_role = &"button_selected_tab"
		&"gold":
			bg = color(&"gold_dark")
			border = color(&"gold")
			border_width = 3
			padding = 12
			texture_role = &"button_confirm"
		&"reward":
			bg = Color(0.20, 0.13, 0.04, 0.96)
			border = color(&"gold")
			border_width = 3
			padding = 10
			texture_role = &"button_confirm"
		&"ready":
			bg = Color(0.045, 0.080, 0.052, 0.96)
			border = color(&"accent")
			border_width = 2
			padding = 10
			texture_role = &"button_selected_tab"
		&"new":
			bg = Color(0.050, 0.066, 0.088, 0.96)
			border = Color(0.55, 0.78, 0.96, 1.0)
			border_width = 2
			texture_role = &"button_selected_tab"
		&"locked":
			bg = Color(0.020, 0.028, 0.030, 0.72)
			border = color(&"disabled")
			texture_role = &"button_dark"
		&"warning":
			border = color(&"warning")
			border_width = 2
			texture_role = &"button_dark"
		&"danger":
			border = color(&"danger")
			border_width = 2
			texture_role = &"button_dark"
		&"disabled":
			bg = Color(0.020, 0.028, 0.030, 0.70)
			border = color(&"disabled")
			texture_role = &"button_dark"
		_:
			border = color(&"muted")
	if hover:
		bg = bg.lightened(0.10)
		border_width = max(border_width, 2)
	if pressed:
		bg = bg.darkened(0.12)
		border_width = max(border_width, 2)
	var textured := _texture_style_box(texture_role, padding, _texture_margin_for(texture_role))
	if textured != null:
		return textured
	return _style_box(bg, border, border_width, padding, 3)


static func transparent_style_box(padding: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.content_margin_left = padding
	style.content_margin_top = padding
	style.content_margin_right = padding
	style.content_margin_bottom = padding
	return style


static func _texture_style_box(role: StringName, padding: int, texture_margin: int) -> StyleBoxTexture:
	var texture := art21_texture(role)
	if texture == null:
		texture = art19_texture(role)
	return style_box_from_texture(texture, padding, texture_margin)


static func _texture_margin_for(role: StringName) -> int:
	match role:
		&"panel_terminal":
			return 32
		&"panel_deploy_main":
			return 28
		&"panel_summary":
			return 16
		&"panel_highlight":
			return 16
		&"button_confirm":
			return 20
		&"button_selected_tab":
			return 14
		&"button_dark":
			return 14
		&"bar_summary":
			return 18
		_:
			return 12


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
	if font_size_value >= font_size(&"section_title"):
		return 5
	if font_size_value >= font_size(&"main_button"):
		return 5
	if font_size_value >= font_size(&"body"):
		return 4
	return 3
