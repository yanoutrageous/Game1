extends RefCounted
class_name UILayerContract

const BACKGROUND := 0
const GAMEPLAY_VIEWPORT := 12
const CONTENT_PANEL := 36
const PANEL_TEXTURE := 44
const CHARACTER_DISPLAY := 52
const CONTENT_TEXT := 60
const STATUS_CARD := 72
const FLOATING_INFO := 84
const ACTION_BAR := 96
const OVERLAY := 124
const MODAL := 160

const RUN_LEFT_RATIO := 0.245
const RUN_LEFT_MIN := 292.0
const RUN_LEFT_MAX := 392.0
const RUN_STATUS_WIDTH_LOW := 210.0
const RUN_STATUS_WIDTH_STANDARD := 244.0
const RUN_STATUS_WIDTH_HIGH := 270.0


static func layer(role: StringName, fallback: int = CONTENT_PANEL) -> int:
	match role:
		&"background":
			return BACKGROUND
		&"gameplay_viewport":
			return GAMEPLAY_VIEWPORT
		&"character_display":
			return CHARACTER_DISPLAY
		&"content_panel":
			return CONTENT_PANEL
		&"panel_texture":
			return PANEL_TEXTURE
		&"content_text":
			return CONTENT_TEXT
		&"status_card":
			return STATUS_CARD
		&"floating_info":
			return FLOATING_INFO
		&"action_bar":
			return ACTION_BAR
		&"overlay":
			return OVERLAY
		&"modal":
			return MODAL
		_:
			return fallback


static func apply_layer(item: Variant, role: StringName, offset: int = 0) -> void:
	if not (item is CanvasItem):
		return
	var canvas_item := item as CanvasItem
	canvas_item.z_as_relative = false
	canvas_item.z_index = layer(role) + offset


static func layer_for_page_node(node: Node, fallback: int = CONTENT_PANEL) -> int:
	var node_name := String(node.name)
	if node_name.find("Backdrop") >= 0 or node_name.find("Background") >= 0:
		return layer(&"background")
	if node_name.find("Vignette") >= 0 or node_name.find("Glow") >= 0 or node_name.find("Atmosphere") >= 0 or node_name.find("Mask") >= 0 or node_name.find("Grid") >= 0 or node_name.find("Wall") >= 0 or node_name.find("ShelfLine") >= 0 or node_name.find("Lamp") >= 0:
		return layer(&"gameplay_viewport")
	if node_name.find("Character") >= 0 or node_name.find("Avatar") >= 0 or node_name.find("PlayerSprite") >= 0:
		return layer(&"character_display")
	if node_name.find("Frame") >= 0 or node_name.find("Panel") >= 0 or node_name.find("Column") >= 0 or node_name.find("Block") >= 0 or node_name.find("Texture") >= 0:
		return layer(&"content_panel")
	if node_name.find("TopEntrance") >= 0 or node_name.find("TopTabRow") >= 0 or node_name.find("TabRow") >= 0 or node_name.find("CardScroll") >= 0 or node_name.find("CardGrid") >= 0:
		return layer(&"content_text")
	if node_name.find("Status") >= 0 or node_name.find("Summary") >= 0 or node_name.find("Notice") >= 0 or node_name.find("Meta") >= 0:
		return layer(&"status_card")
	if node_name.find("StartButton") >= 0 or node_name.find("ContinueButton") >= 0 or node_name.find("AbandonButton") >= 0 or node_name.find("AppearanceButton") >= 0 or node_name.find("Nav") >= 0:
		return layer(&"action_bar")
	if node_name.find("Shortcut") >= 0:
		return layer(&"action_bar") + 4
	if node is Label or node is Button:
		return layer(&"content_text")
	if node is Container:
		return layer(&"content_text") - 2
	return fallback


static func viewport_size_from_profile(profile: Dictionary) -> Vector2:
	var actual: Variant = profile.get("actual_viewport_size", Vector2i.ZERO)
	if actual is Vector2i and (actual as Vector2i).x > 0 and (actual as Vector2i).y > 0:
		return Vector2(float((actual as Vector2i).x), float((actual as Vector2i).y))
	var supported: Variant = profile.get("supported_size", Vector2i(1280, 720))
	if supported is Vector2i:
		return Vector2(float((supported as Vector2i).x), float((supported as Vector2i).y))
	if supported is Vector2:
		return supported
	return Vector2(1280, 720)


static func run_left_width(profile: Dictionary) -> float:
	var viewport_size := viewport_size_from_profile(profile)
	return clamp(viewport_size.x * RUN_LEFT_RATIO, RUN_LEFT_MIN, RUN_LEFT_MAX)


static func run_status_card_size(profile: Dictionary) -> Vector2:
	var is_low := bool(profile.get("is_low_resolution", false))
	var is_high := bool(profile.get("is_high_resolution", false))
	var width := RUN_STATUS_WIDTH_LOW if is_low else (RUN_STATUS_WIDTH_HIGH if is_high else RUN_STATUS_WIDTH_STANDARD)
	var height := 96.0 if is_low else (126.0 if is_high else 110.0)
	return Vector2(width, height)
