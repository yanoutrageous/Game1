extends Button
class_name LongTermContentCardView

const Art23LongTermAssetContractScript := preload("res://scripts/presentation/art23_long_term_asset_contract.gd")
const Art25ContentAssetContractScript := preload("res://scripts/presentation/art25_content_asset_contract.gd")
const ReadableFont := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

var card_data: Dictionary = {}
var artwork: TextureRect
var title_label: Label
var state_label: Label
var status_bar: ColorRect
var art_frame: Panel


func setup(card: Dictionary, locked: bool, selected: bool) -> void:
	card_data = card.duplicate(true)
	# Keep the localized semantic text on the actual Button for accessibility,
	# focus diagnostics and compatibility tests. Child labels own the rendering.
	text = "%s\n%s" % [String(card_data.get("title", "档案条目")), String(card_data.get("state", "已登记"))]
	custom_minimum_size = Vector2(272, 68)
	size = custom_minimum_size
	toggle_mode = true
	button_pressed = selected
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_build_content()
	apply_visual_state(&"locked" if locked else (&"selected" if selected else &"normal"))


func apply_visual_state(state: StringName) -> void:
	var selected := state == &"selected"
	var locked := state == &"locked"
	var accent := Color(0.32, 0.95, 0.88, 1.0) if selected else (Color(0.43, 0.45, 0.43, 1.0) if locked else Color(0.90, 0.66, 0.25, 1.0))
	if art_frame != null:
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color(0.018, 0.075, 0.078, 0.96) if selected else Color(0.012, 0.043, 0.046, 0.94)
		frame_style.border_color = accent
		frame_style.set_border_width_all(2 if selected else 1)
		frame_style.set_corner_radius_all(2)
		art_frame.add_theme_stylebox_override("panel", frame_style)
	if artwork != null:
		artwork.modulate = Color(1.08, 1.08, 1.02, 1.0) if selected else (Color(0.48, 0.52, 0.50, 0.82) if locked else Color.WHITE)
	if title_label != null:
		title_label.add_theme_color_override(
			"font_color",
			Color(0.57, 1.0, 0.95, 1.0) if selected else (Color(0.66, 0.69, 0.65, 1.0) if locked else Color(1.0, 0.84, 0.54, 1.0))
		)
	if state_label != null:
		state_label.add_theme_color_override("font_color", Color(0.68, 0.72, 0.68) if locked else Color(0.84, 0.88, 0.80))
	if status_bar != null:
		status_bar.color = accent
	add_theme_font_size_override("font_size", 1)
	for color_name in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		add_theme_color_override(color_name, Color(1, 1, 1, 0))


func _build_content() -> void:
	art_frame = Panel.new()
	art_frame.name = "ContentArtFrame"
	# The artwork remains a strong semantic cue, but no longer consumes a third
	# of the card. The former 54 px well left only a one-pixel visual gutter
	# before the title and made every page feel like a row of oversized icons.
	art_frame.position = Vector2(7, 8)
	art_frame.size = Vector2(46, 48)
	# Map thumbnails are wider than the square semantic icons. Keep every asset
	# inside the same reserved well so wide sources cannot cover card copy.
	art_frame.clip_contents = true
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art_frame)

	artwork = TextureRect.new()
	artwork.name = "ContentArtwork"
	artwork.texture = Art25ContentAssetContractScript.texture_for_long_term_card(card_data)
	artwork.position = Vector2(3, 4)
	artwork.size = Vector2(40, 40)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(artwork)
	# Reassert the texture rect after it has a parent. Wide thumbnails otherwise
	# keep their imported width during the first minimum-size pass and are merely
	# clipped instead of being fitted into the icon well.
	artwork.set_anchors_preset(Control.PRESET_FULL_RECT)
	artwork.offset_left = 3.0
	artwork.offset_top = 4.0
	artwork.offset_right = -3.0
	artwork.offset_bottom = -4.0

	title_label = _label("ContentTitle", Rect2(60, 7, 132, 48), String(card_data.get("title", "档案条目")), 13)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	state_label = _label("ContentState", Rect2(196, 10, 68, 42), String(card_data.get("state", "已登记")), 11)
	state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	status_bar = ColorRect.new()
	status_bar.name = "ContentStateBar"
	status_bar.position = Vector2(7, 60)
	status_bar.size = Vector2(257, 3)
	status_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status_bar)


func _label(node_name: String, rect: Rect2, value: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", ReadableFont)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	return label
