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

const RUN_LEFT_RATIO := 0.30
const RUN_LEFT_MIN := 340.0
const RUN_LEFT_MAX := 580.0
const RUN_STATUS_WIDTH_LOW := 210.0
const RUN_STATUS_WIDTH_STANDARD := 244.0
const RUN_STATUS_WIDTH_HIGH := 270.0

const PAGE_ROOT_ORDER := [
	&"BackgroundRoot",
	&"DecorationRoot",
	&"CharacterRoot",
	&"MainContentRoot",
	&"SideStatusRoot",
	&"PrimaryActionRoot",
	&"FloatingInfoRoot",
	&"OverlayRoot",
	&"ModalRoot",
]

const RUN_ROOT_ORDER := [
	&"RunGameStageRoot",
	&"RunLeftInfoRailRoot",
	&"RunTopRightStatusRoot",
	&"RunFloatingInfoRoot",
	&"RunInteractionPromptRoot",
	&"RunActionOverlayRoot",
	&"RunOverlayRoot",
	&"RunModalRoot",
]


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


static func apply_local_layer(item: Variant, local_index: int = 0) -> void:
	if not (item is CanvasItem):
		return
	var canvas_item := item as CanvasItem
	canvas_item.z_as_relative = true
	canvas_item.z_index = local_index


static func ensure_root(parent: Control, root_name: StringName, role: StringName, offset: int = 0) -> Control:
	var root := parent.get_node_or_null(String(root_name)) as Control
	if root == null:
		root = Control.new()
		root.name = String(root_name)
		parent.add_child(root)
	configure_root(root, role, offset)
	return root


static func configure_root(root: Control, role: StringName, offset: int = 0) -> void:
	if root == null:
		return
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 0.0
	root.offset_top = 0.0
	root.offset_right = 0.0
	root.offset_bottom = 0.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	apply_layer(root, role, offset)


static func is_page_root_name(root_name: StringName) -> bool:
	return PAGE_ROOT_ORDER.has(root_name)


static func page_root_role(root_name: StringName) -> StringName:
	match root_name:
		&"BackgroundRoot":
			return &"background"
		&"DecorationRoot":
			return &"gameplay_viewport"
		&"CharacterRoot":
			return &"character_display"
		&"SideStatusRoot":
			return &"status_card"
		&"PrimaryActionRoot":
			return &"action_bar"
		&"FloatingInfoRoot":
			return &"floating_info"
		&"OverlayRoot":
			return &"overlay"
		&"ModalRoot":
			return &"modal"
		_:
			return &"content_panel"


static func page_root_for_node(node: Node) -> StringName:
	var resolved_layer := layer_for_page_node(node)
	if resolved_layer <= BACKGROUND:
		return &"BackgroundRoot"
	if resolved_layer < CONTENT_PANEL:
		return &"DecorationRoot"
	if resolved_layer == CHARACTER_DISPLAY:
		return &"CharacterRoot"
	if resolved_layer >= MODAL:
		return &"ModalRoot"
	if resolved_layer >= OVERLAY:
		return &"OverlayRoot"
	if resolved_layer >= ACTION_BAR:
		return &"PrimaryActionRoot"
	if resolved_layer >= FLOATING_INFO:
		return &"FloatingInfoRoot"
	if resolved_layer >= STATUS_CARD:
		return &"SideStatusRoot"
	return &"MainContentRoot"


static func is_run_root_name(root_name: StringName) -> bool:
	return RUN_ROOT_ORDER.has(root_name) or root_name == &"RunRoomViewportRoot"


static func run_root_role(root_name: StringName) -> StringName:
	match root_name:
		&"RunGameStageRoot", &"RunRoomViewportRoot":
			return &"gameplay_viewport"
		&"RunLeftInfoRailRoot":
			return &"content_panel"
		&"RunTopRightStatusRoot":
			return &"status_card"
		&"RunFloatingInfoRoot", &"RunInteractionPromptRoot":
			return &"floating_info"
		&"RunActionOverlayRoot":
			return &"action_bar"
		&"RunOverlayRoot":
			return &"overlay"
		&"RunModalRoot":
			return &"modal"
		_:
			return &"gameplay_viewport"


static func run_root_for_node(node: Node) -> StringName:
	var node_name := String(node.name)
	if node_name.find("Modal") >= 0:
		return &"RunModalRoot"
	if node_name.find("Overlay") >= 0 or node_name.find("FeedbackSlot") >= 0:
		return &"RunOverlayRoot"
	if node_name.find("Bottom") >= 0 or node_name.find("Action") >= 0 or node_name.find("Key") >= 0:
		return &"RunActionOverlayRoot"
	if node_name.find("Encounter") >= 0 or node_name.find("PlayerTag") >= 0:
		return &"RunInteractionPromptRoot"
	if node_name.find("CommandFeedback") >= 0 or node_name.find("RoomText") >= 0 or node_name.find("RoomTitle") >= 0 or node_name.find("RoomBody") >= 0 or node_name.find("Objective") >= 0:
		return &"RunFloatingInfoRoot"
	if node_name.find("Protocol") >= 0 or node_name.find("Threat") >= 0 or node_name.find("Event") >= 0 or node_name.find("Reward") >= 0 or node_name.find("Right") >= 0:
		return &"RunTopRightStatusRoot"
	if node_name.find("Scanner") >= 0 or node_name.find("MiniMap") >= 0 or node_name.find("Resource") >= 0 or node_name.find("Left") >= 0:
		return &"RunLeftInfoRailRoot"
	return &"RunRoomViewportRoot"


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
