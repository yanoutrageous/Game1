extends Control
class_name MainMenuShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const MainMenuModelScript := preload("res://scripts/ui/main_menu/main_menu_model.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")

signal navigation_intent_requested(intent: Dictionary)

const ENTRY_RECTS := {
	&"deploy": Rect2(790, 181, 370, 146),
	&"long_term": Rect2(865, 329, 249, 96),
	&"settings": Rect2(887, 434, 221, 84),
	&"exit_game": Rect2(897, 528, 211, 75),
}

const ENTRY_TEXT_RECTS := {
	&"deploy": Rect2(881, 222, 230, 54),
	&"long_term": Rect2(904, 350, 172, 42),
	&"settings": Rect2(944, 453, 108, 38),
	&"exit_game": Rect2(929, 543, 147, 36),
}

const ENTRY_HIT_RECTS := {
	&"deploy": Rect2(776, 168, 395, 171),
	&"long_term": Rect2(852, 318, 274, 119),
	&"settings": Rect2(875, 424, 245, 105),
	&"exit_game": Rect2(884, 518, 236, 96),
}

const ENTRY_BOARD_NAMES := {
	&"deploy": "explore",
	&"long_term": "long_term",
	&"settings": "settings",
	&"exit_game": "exit",
}

const ENTRY_FONT_SIZES := {
	&"deploy": 44,
	&"long_term": 32,
	&"settings": 32,
	&"exit_game": 29,
}

const TRANSITION_FRAME_MARKS := [0.0, 0.25, 0.50, 0.78]
const TRANSITION_DURATION := 1.10
const CHARACTER_IDLE_FRAME_SECONDS := 0.32
const CHARACTER_IDLE_SEQUENCE := [0, 0, 1, 1, 2, 1, 0, 0, 0, 3, 3, 0, 0, 4, 5, 4, 0, 0]
const AMBIENT_PROFILES := {
	&"smoke": {
		"kind": &"loop",
		"sequence": [0, 1, 2, 3],
		"frame_seconds": 0.62,
		"alpha_sequence": [0.12, 0.22, 0.18, 0.08],
	},
	&"birds": {
		"kind": &"event_travel",
		"sequence": [0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1],
		"frame_seconds": 0.28,
		"initial_delay": 2.20,
		"cooldown_seconds": 9.0,
		"active_seconds": 3.36,
		"travel": Vector2(96, -6),
		"base_alpha": 0.68,
	},
	&"leaves": {
		"kind": &"event",
		"sequence": [0, 1, 2, 3],
		"frame_seconds": 0.52,
		"initial_delay": 1.10,
		"cooldown_seconds": 6.0,
		"active_seconds": 2.08,
		"base_alpha": 0.62,
	},
}
const PERSISTENT_MOTION_PROFILES := {
	&"dungeon_flag": {"kind": &"loop", "sequence": [0, 1, 2, 3, 2, 1], "frame_seconds": 0.32, "reduce_motion_behavior": &"freeze"},
	&"company_banner": {"kind": &"loop", "sequence": [0, 1, 2, 3, 2, 1], "frame_seconds": 0.38, "reduce_motion_behavior": &"freeze"},
	&"company_side_left": {"kind": &"loop", "sequence": [0, 1, 2, 3, 2, 1], "frame_seconds": 0.44, "reduce_motion_behavior": &"freeze"},
	&"company_side_right": {"kind": &"loop", "sequence": [2, 3, 2, 1, 0, 1], "frame_seconds": 0.44, "reduce_motion_behavior": &"freeze"},
	&"lantern_flame": {"kind": &"loop", "sequence": [0, 1, 2, 3, 2, 1], "frame_seconds": 0.22, "reduce_motion_behavior": &"freeze"},
}

var current_model: Dictionary = {}
var current_snapshot: Dictionary = {}
var texture_cache: Dictionary = {}
var entry_nodes: Dictionary = {}
var entry_by_id: Dictionary = {}
var current_focus: StringName = &"deploy"

var character_texture: TextureRect
var character_idle_frames: Array[Texture2D] = []
var character_focus_frames: Array[Texture2D] = []
var character_walk_dungeon_frames: Array[Texture2D] = []
var character_walk_company_frames: Array[Texture2D] = []
var cave_interior_texture: TextureRect
var dungeon_gate_texture: TextureRect
var company_door_texture: TextureRect
var company_window_nodes: Array[TextureRect] = []
var cave_activation_texture: TextureRect
var company_activation_texture: TextureRect
var generic_focus_texture: Panel
var explore_focus_texture: TextureRect
var transition_texture: ColorRect

var animated_groups: Array[Dictionary] = []
var idle_elapsed := 0.0
var scene_elapsed := 0.0
var idle_frame_index := 0
var transition_active := false
var transition_elapsed := 0.0
var transition_frame_index := 0
var pending_transition_entry: Dictionary = {}
var reduced_motion := false


func build(model: Dictionary = {}) -> void:
	_clear_children()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_model = model.duplicate(true) if not model.is_empty() else MainMenuModelScript.build()
	reduced_motion = Art10UISkinKitScript.reduce_motion_enabled()
	_create_layer_roots()
	_build_background_scene()
	_build_brand_sign()
	_build_character_scene()
	_build_notice_board()
	_build_environment_motion()
	_build_menu_signpost()
	_build_ambient_fx()
	_build_transition_layer()
	_index_entries()
	_connect_focus_neighbors()
	_set_focus_state(&"deploy")
	set_process(true)
	call_deferred("_grab_default_focus")


func apply_snapshot(snapshot: Dictionary) -> void:
	current_snapshot = snapshot.duplicate(true)


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	texture_cache.clear()
	entry_nodes.clear()
	entry_by_id.clear()
	animated_groups.clear()
	company_window_nodes.clear()
	character_idle_frames.clear()
	character_focus_frames.clear()
	character_walk_dungeon_frames.clear()
	character_walk_company_frames.clear()
	transition_active = false
	pending_transition_entry.clear()


func _create_layer_roots() -> void:
	for root_name_variant in UILayerContractScript.PAGE_ROOT_ORDER:
		var root_name := StringName(root_name_variant)
		UILayerContractScript.ensure_root(self, root_name, UILayerContractScript.page_root_role(root_name))
	for index in range(UILayerContractScript.PAGE_ROOT_ORDER.size()):
		var root_name := String(UILayerContractScript.PAGE_ROOT_ORDER[index])
		var root := get_node_or_null(root_name)
		if root != null:
			move_child(root, index)


func _root(root_name: StringName) -> Control:
	return get_node(String(root_name)) as Control


func _build_background_scene() -> void:
	var background_root := _root(&"BackgroundRoot")
	_add_color_rect(background_root, "MainMenuSceneBackdrop", Rect2(0, 0, 1280, 720), Color(0.035, 0.12, 0.20, 1.0))
	_add_texture(background_root, "MainMenuSceneCleanPlate", Rect2(0, 0, 1280, 720), &"main_menu.scene.background.scene_clean_plate", 1)


func _build_environment_motion() -> void:
	var decoration_root := _root(&"DecorationRoot")
	_register_animation(decoration_root, "MainMenuDungeonFlag", Rect2(398, 18, 112, 94), "main_menu.scene.fx.dungeon_flag", 4, 7, PERSISTENT_MOTION_PROFILES[&"dungeon_flag"])
	_register_animation(decoration_root, "MainMenuCompanyBanner", Rect2(794, 88, 92, 174), "main_menu.scene.fx.company_banner", 4, 7, PERSISTENT_MOTION_PROFILES[&"company_banner"])
	_register_animation(decoration_root, "MainMenuCompanySideBannerLeft", Rect2(674, 174, 42, 112), "main_menu.scene.fx.company_side_banner", 4, 7, PERSISTENT_MOTION_PROFILES[&"company_side_left"])
	_register_animation(decoration_root, "MainMenuCompanySideBannerRight", Rect2(930, 174, 42, 112), "main_menu.scene.fx.company_side_banner", 4, 7, PERSISTENT_MOTION_PROFILES[&"company_side_right"])
	var flame_rects := [Rect2(212, 329, 36, 36), Rect2(435, 331, 36, 36), Rect2(1214, 289, 36, 36)]
	for index in range(flame_rects.size()):
		_register_animation(decoration_root, "MainMenuLanternFlame%d" % index, flame_rects[index], "main_menu.scene.fx.lantern_flame", 4, 10, PERSISTENT_MOTION_PROFILES[&"lantern_flame"])


func _build_architecture_scene() -> void:
	var decoration_root := _root(&"DecorationRoot")
	cave_interior_texture = _add_texture(decoration_root, "MainMenuCaveInterior", Rect2(203, 246, 230, 286), &"main_menu.scene.architecture.cave.normal", 0)
	_add_texture(decoration_root, "MainMenuDungeonArchitecture", Rect2(0, 34, 610, 604), &"main_menu.scene.architecture.dungeon_base", 1)
	_add_texture(decoration_root, "MainMenuCompanyArchitecture", Rect2(590, 42, 460, 500), &"main_menu.scene.architecture.company_base", 1)
	dungeon_gate_texture = _add_texture(decoration_root, "MainMenuDungeonGate", Rect2(213, 258, 218, 232), &"main_menu.scene.architecture.dungeon_gate.normal", 2)
	company_door_texture = _add_texture(decoration_root, "MainMenuCompanyDoor", Rect2(772, 342, 96, 140), &"main_menu.scene.architecture.company_door.normal", 2)
	_add_texture(decoration_root, "MainMenuCompanyGuardianLeft", Rect2(706, 420, 52, 72), &"main_menu.scene.architecture.company_guardian", 3)
	var guardian_right := _add_texture(decoration_root, "MainMenuCompanyGuardianRight", Rect2(878, 420, 52, 72), &"main_menu.scene.architecture.company_guardian", 3)
	if guardian_right != null:
		guardian_right.flip_h = true

	_add_texture(decoration_root, "MainMenuDungeonLanternLeft", Rect2(192, 274, 76, 131), &"main_menu.scene.environment.lantern.wall", 6)
	_add_texture(decoration_root, "MainMenuDungeonLanternRight", Rect2(419, 276, 71, 124), &"main_menu.scene.environment.lantern.wall", 6)
	_add_texture(decoration_root, "MainMenuSignpostLantern", Rect2(1191, 228, 82, 158), &"main_menu.scene.environment.lantern.hanging", 6)

	_register_animation(decoration_root, "MainMenuDungeonFlag", Rect2(398, 18, 112, 94), "main_menu.scene.fx.dungeon_flag", 4, 7)
	_register_animation(decoration_root, "MainMenuCompanyBanner", Rect2(794, 88, 92, 174), "main_menu.scene.fx.company_banner", 4, 7)
	_register_animation(decoration_root, "MainMenuCompanySideBannerLeft", Rect2(674, 174, 42, 112), "main_menu.scene.fx.company_side_banner", 4, 7)
	_register_animation(decoration_root, "MainMenuCompanySideBannerRight", Rect2(930, 174, 42, 112), "main_menu.scene.fx.company_side_banner", 4, 7)

	for index in range(4):
		var rects := [Rect2(706, 250, 18, 54), Rect2(902, 250, 18, 54), Rect2(770, 183, 18, 54), Rect2(852, 183, 18, 54)]
		var window := _add_texture(decoration_root, "MainMenuCompanyWindow%d" % index, rects[index], &"main_menu.scene.fx.company_window.00", 7)
		if window != null:
			company_window_nodes.append(window)

	_register_animation(decoration_root, "MainMenuDungeonIvyBack", Rect2(42, 72, 430, 166), "main_menu.scene.fx.ivy_back", 4, 8)
	_register_animation(decoration_root, "MainMenuDungeonIvyFront", Rect2(164, 174, 126, 208), "main_menu.scene.fx.ivy_front", 4, 9)
	for index in range(3):
		var flame_rects := [Rect2(212, 329, 36, 36), Rect2(435, 331, 36, 36), Rect2(1214, 289, 36, 36)]
		_register_animation(decoration_root, "MainMenuLanternFlame%d" % index, flame_rects[index], "main_menu.scene.fx.lantern_flame", 4, 10)

	cave_activation_texture = _add_texture(_root(&"FloatingInfoRoot"), "MainMenuCaveFocusGlow", Rect2(230, 245, 218, 286), &"main_menu.scene.fx.cave_activation", 1)
	company_activation_texture = _add_texture(_root(&"FloatingInfoRoot"), "MainMenuCompanyFocusGlow", Rect2(687, 287, 224, 126), &"main_menu.scene.fx.company_activation", 1)
	if cave_activation_texture != null:
		cave_activation_texture.visible = false
	if company_activation_texture != null:
		company_activation_texture.visible = false


func _build_brand_sign() -> void:
	var content_root := _root(&"MainContentRoot")
	_add_scene_label(content_root, "MainMenuTitle", Rect2(170, 104, 330, 90), String(current_model.get("title", "灰尾回收")), 58, Color(0.98, 0.79, 0.39), 1, 3)


func _build_character_scene() -> void:
	var character_root := _root(&"CharacterRoot")
	_add_texture(character_root, "MainMenuCharacterShadow", Rect2(286, 594, 196, 24), &"main_menu.scene.character.shadow", 0)
	character_idle_frames = _texture_sequence("main_menu.scene.character.idle", 8)
	character_focus_frames = _texture_sequence("main_menu.scene.character.focus", 4)
	character_walk_dungeon_frames = _texture_sequence("main_menu.scene.character.walk_dungeon", 4)
	character_walk_company_frames = _texture_sequence("main_menu.scene.character.walk_company", 4)
	character_texture = _add_texture(character_root, "MainMenuCharacter", Rect2(286, 408, 190, 216), &"main_menu.scene.character.idle.00", 1)


func _build_notice_board() -> void:
	var notice_root := _root(&"SideStatusRoot")
	_add_scene_label(notice_root, "MainMenuNoticeTitle", Rect2(72, 378, 146, 34), "公告", 24, Color(0.95, 0.75, 0.35), 2, 2)
	var notices := _array_from(current_model, "notices")
	var body_text := ""
	for index in range(mini(4, notices.size())):
		if index > 0:
			body_text += "\n"
		body_text += String(notices[index])
	var body := _add_scene_label(notice_root, "MainMenuNoticeText", Rect2(92, 446, 124, 120), body_text, 16, Color(0.24, 0.15, 0.09), 3, 0)
	if body != null:
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		body.add_theme_constant_override("line_spacing", 7)


func _build_menu_signpost() -> void:
	var action_root := _root(&"PrimaryActionRoot")
	explore_focus_texture = _add_texture(_root(&"FloatingInfoRoot"), "MainMenuExploreFocusOutline", Rect2(784, 175, 382, 158), &"main_menu.scene.fx.focus_explore", 3)
	generic_focus_texture = _add_focus_outline(_root(&"FloatingInfoRoot"), "MainMenuUtilityFocusOutline", Rect2(862, 326, 255, 102), 3)
	cave_activation_texture = _add_texture(_root(&"FloatingInfoRoot"), "MainMenuCaveFocusGlow", Rect2(230, 245, 218, 286), &"main_menu.scene.fx.cave_activation", 1)
	company_activation_texture = _add_texture(_root(&"FloatingInfoRoot"), "MainMenuCompanyFocusGlow", Rect2(687, 287, 224, 126), &"main_menu.scene.fx.company_activation", 1)
	if explore_focus_texture != null:
		explore_focus_texture.visible = false
		explore_focus_texture.modulate = Color(1, 1, 1, 0.22)
	if generic_focus_texture != null:
		generic_focus_texture.visible = false
	if cave_activation_texture != null:
		cave_activation_texture.visible = false
	if company_activation_texture != null:
		company_activation_texture.visible = false

	for raw_entry in _array_from(current_model, "entries"):
		if raw_entry is Dictionary:
			_build_entry(action_root, (raw_entry as Dictionary).duplicate(true))


func _build_entry(parent: Control, entry: Dictionary) -> void:
	var entry_id := StringName(entry.get("id", &""))
	if not ENTRY_RECTS.has(entry_id):
		return
	var board_name := String(ENTRY_BOARD_NAMES[entry_id])
	var board := _add_texture(parent, "MainMenuBoard_" + String(entry_id), ENTRY_RECTS[entry_id], StringName("main_menu.scene.menu.%s.normal" % board_name), 1)
	var label := _add_scene_label(parent, "MainMenuBoardLabel_" + String(entry_id), ENTRY_TEXT_RECTS[entry_id], String(entry.get("label", "")), int(ENTRY_FONT_SIZES[entry_id]), Color(0.98, 0.79, 0.39), 2)
	var button := Button.new()
	button.name = "MainMenuEntry_%s" % String(entry_id)
	button.text = ""
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_set_rect(button, ENTRY_HIT_RECTS[entry_id])
	_apply_transparent_button_style(button)
	button.focus_entered.connect(func() -> void: _set_focus_state(entry_id))
	button.mouse_entered.connect(func() -> void:
		button.grab_focus()
		_set_focus_state(entry_id)
	)
	button.button_down.connect(func() -> void: _set_entry_visual_state(entry_id, &"pressed"))
	button.button_up.connect(func() -> void: _set_entry_visual_state(entry_id, &"focused"))
	button.pressed.connect(func() -> void: _activate_entry(entry))
	parent.add_child(button)
	entry_nodes[entry_id] = {
		"board": board,
		"label": label,
		"button": button,
		"base_board_rect": ENTRY_RECTS[entry_id],
		"base_label_rect": ENTRY_TEXT_RECTS[entry_id],
		"board_name": board_name,
	}


func _build_ambient_fx() -> void:
	var floating_root := _root(&"FloatingInfoRoot")
	_register_animation(floating_root, "MainMenuChimneySmoke", Rect2(958, 32, 128, 128), "main_menu.scene.fx.smoke", 4, 1, AMBIENT_PROFILES[&"smoke"])
	_register_animation(floating_root, "MainMenuBirds", Rect2(606, 66, 160, 80), "main_menu.scene.fx.birds", 4, 1, AMBIENT_PROFILES[&"birds"])
	_register_animation(floating_root, "MainMenuFallingLeaves", Rect2(1040, 286, 120, 120), "main_menu.scene.fx.leaves", 4, 1, AMBIENT_PROFILES[&"leaves"])
	# The puddle frames contain a complete stone patch. Mounting them over the
	# integrated master creates a visible pasted rectangle, so they remain
	# prototype-only until the master receives a matching clean plate.


func _build_transition_layer() -> void:
	var overlay_root := _root(&"OverlayRoot")
	transition_texture = ColorRect.new()
	transition_texture.name = "MainMenuSceneTransition"
	transition_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_texture.color = Color(0.018, 0.024, 0.032, 0.0)
	transition_texture.visible = false
	_set_rect(transition_texture, Rect2(0, 0, 1280, 720))
	overlay_root.add_child(transition_texture)


func _index_entries() -> void:
	entry_by_id.clear()
	for raw_entry in _array_from(current_model, "entries"):
		if raw_entry is Dictionary:
			var entry := (raw_entry as Dictionary).duplicate(true)
			entry_by_id[StringName(entry.get("id", &""))] = entry


func _connect_focus_neighbors() -> void:
	var order: Array[StringName] = [&"deploy", &"long_term", &"settings", &"exit_game"]
	for index in range(order.size()):
		var id := order[index]
		if not entry_nodes.has(id):
			continue
		var button := _dictionary_from(entry_nodes[id]).get("button") as Button
		if button == null:
			continue
		var previous := order[maxi(0, index - 1)]
		var next := order[mini(order.size() - 1, index + 1)]
		button.focus_neighbor_top = button.get_path_to(_dictionary_from(entry_nodes[previous]).get("button") as Button)
		button.focus_neighbor_bottom = button.get_path_to(_dictionary_from(entry_nodes[next]).get("button") as Button)
		button.focus_neighbor_left = button.focus_neighbor_top
		button.focus_neighbor_right = button.focus_neighbor_bottom


func _grab_default_focus() -> void:
	if entry_nodes.has(&"deploy"):
		var button := _dictionary_from(entry_nodes[&"deploy"]).get("button") as Button
		if button != null and is_instance_valid(button):
			button.grab_focus()


func _set_focus_state(entry_id: StringName) -> void:
	if not entry_nodes.has(entry_id) or transition_active:
		return
	current_focus = entry_id
	for raw_id in entry_nodes.keys():
		var id := StringName(raw_id)
		_set_entry_visual_state(id, &"focused" if id == entry_id else &"normal")

	var explore_focused := entry_id == &"deploy"
	var company_focused := entry_id == &"long_term"
	if cave_activation_texture != null:
		cave_activation_texture.visible = explore_focused
	if company_activation_texture != null:
		company_activation_texture.visible = company_focused
	if explore_focus_texture != null:
		explore_focus_texture.visible = explore_focused
	if generic_focus_texture != null:
		generic_focus_texture.visible = not explore_focused
		var focus_rect := ENTRY_RECTS.get(entry_id, ENTRY_RECTS[&"long_term"]) as Rect2
		# Utility boards slide four pixels left when focused. Keep the outline on
		# the moved board instead of leaving it on the baked, unfocused position.
		focus_rect.position.x -= 4.0
		_set_rect(generic_focus_texture, focus_rect.grow(4.0))
	if cave_interior_texture != null:
		cave_interior_texture.texture = _texture(&"main_menu.scene.architecture.cave.focused" if explore_focused else &"main_menu.scene.architecture.cave.normal")
	if dungeon_gate_texture != null:
		dungeon_gate_texture.texture = _texture(&"main_menu.scene.architecture.dungeon_gate.focused" if explore_focused else &"main_menu.scene.architecture.dungeon_gate.normal")
	if company_door_texture != null:
		company_door_texture.texture = _texture(&"main_menu.scene.architecture.company_door.focused" if company_focused else &"main_menu.scene.architecture.company_door.normal")
	for window in company_window_nodes:
		window.texture = _texture(&"main_menu.scene.fx.company_window.01" if company_focused else &"main_menu.scene.fx.company_window.00")
	_update_character_focus_texture()


func _set_entry_visual_state(entry_id: StringName, state: StringName) -> void:
	if not entry_nodes.has(entry_id):
		return
	var node_set := _dictionary_from(entry_nodes[entry_id])
	var board := node_set.get("board") as TextureRect
	var label := node_set.get("label") as Label
	var board_name := String(node_set.get("board_name", ""))
	if board != null:
		board.texture = _texture(StringName("main_menu.scene.menu.%s.%s" % [board_name, String(state)]))
		var rect := node_set.get("base_board_rect", Rect2()) as Rect2
		if state == &"focused":
			rect.position.x -= 4.0
		elif state == &"pressed":
			rect.position += Vector2(2, 2)
		_set_rect(board, rect)
	if label != null:
		var label_rect := node_set.get("base_label_rect", Rect2()) as Rect2
		if state == &"focused":
			label_rect.position.x -= 4.0
		elif state == &"pressed":
			label_rect.position += Vector2(2, 2)
		_set_rect(label, label_rect)
		label.modulate = Color(1.10, 1.06, 0.92, 1.0) if state == &"focused" else Color.WHITE


func _update_character_focus_texture() -> void:
	if character_texture == null or transition_active:
		return
	if current_focus == &"deploy" and character_focus_frames.size() >= 2:
		character_texture.texture = character_focus_frames[1]
		character_texture.flip_h = true
	elif current_focus == &"long_term" and character_focus_frames.size() >= 3:
		character_texture.texture = character_focus_frames[2]
		character_texture.flip_h = false
	elif not character_idle_frames.is_empty():
		var frame_index := int(CHARACTER_IDLE_SEQUENCE[idle_frame_index % CHARACTER_IDLE_SEQUENCE.size()])
		character_texture.texture = character_idle_frames[frame_index % character_idle_frames.size()]
		character_texture.flip_h = false


func _activate_entry(entry: Dictionary) -> void:
	if transition_active:
		return
	var entry_id := StringName(entry.get("id", &""))
	if entry_id == &"deploy" or entry_id == &"long_term":
		if reduced_motion:
			_emit_entry(entry)
			return
		transition_active = true
		pending_transition_entry = entry.duplicate(true)
		transition_elapsed = 0.0
		transition_frame_index = 0
		if transition_texture != null:
			transition_texture.color = Color(0.018, 0.024, 0.032, 0.0) if entry_id == &"deploy" else Color(0.13, 0.075, 0.025, 0.0)
			transition_texture.visible = true
		_set_entry_visual_state(entry_id, &"pressed")
		return
	_emit_entry(entry)


func _process(delta: float) -> void:
	scene_elapsed += delta
	if not reduced_motion:
		_update_cloud_drift()
	if transition_active:
		_update_transition(delta)
		return
	if not reduced_motion:
		idle_elapsed += delta
		if idle_elapsed >= CHARACTER_IDLE_FRAME_SECONDS:
			idle_elapsed -= CHARACTER_IDLE_FRAME_SECONDS
			idle_frame_index = (idle_frame_index + 1) % CHARACTER_IDLE_SEQUENCE.size()
			if current_focus != &"deploy" and current_focus != &"long_term":
				_update_character_focus_texture()
		_update_ambient_motion(delta)
	else:
		for group in animated_groups:
			var motion_node := group.get("node") as TextureRect
			if motion_node != null:
				var reduce_behavior := StringName(group.get("reduce_motion_behavior", &"hide"))
				motion_node.visible = reduce_behavior == &"freeze"
				if reduce_behavior == &"freeze":
					var frozen_frames := group.get("frames", []) as Array
					if not frozen_frames.is_empty():
						motion_node.texture = frozen_frames[0]
	var pulse := 0.30 if reduced_motion else 0.30 + sin(scene_elapsed * 1.65) * 0.025
	if cave_activation_texture != null and cave_activation_texture.visible:
		cave_activation_texture.modulate = Color(1, 1, 1, pulse)
	if company_activation_texture != null and company_activation_texture.visible:
		company_activation_texture.modulate = Color(1, 1, 1, pulse)


func _update_ambient_motion(delta: float) -> void:
	for index in range(animated_groups.size()):
		var group := animated_groups[index]
		var node := group.get("node") as TextureRect
		var frames := group.get("frames", []) as Array
		var sequence := group.get("sequence", []) as Array
		if node == null or frames.is_empty() or sequence.is_empty():
			continue

		var cooldown := float(group.get("cooldown", 0.0))
		if cooldown > 0.0:
			cooldown = maxf(0.0, cooldown - delta)
			group["cooldown"] = cooldown
			node.visible = false
			if cooldown <= 0.0:
				node.visible = true
				node.position = group.get("base_position", node.position) as Vector2
			animated_groups[index] = group
			continue

		var kind := StringName(group.get("kind", &"loop"))
		var active_elapsed := float(group.get("active_elapsed", 0.0)) + delta
		group["active_elapsed"] = active_elapsed
		if kind == &"event" or kind == &"event_travel":
			var active_seconds := float(group.get("active_seconds", 1.0))
			if active_elapsed >= active_seconds:
				node.visible = false
				group["active_elapsed"] = 0.0
				group["frame_elapsed"] = 0.0
				group["cursor"] = 0
				group["cooldown"] = float(group.get("cooldown_seconds", 4.0))
				node.position = group.get("base_position", node.position) as Vector2
				animated_groups[index] = group
				continue
			if kind == &"event_travel":
				var progress := clampf(active_elapsed / active_seconds, 0.0, 1.0)
				var eased := smoothstep(0.0, 1.0, progress)
				var base_position := group.get("base_position", node.position) as Vector2
				var travel := group.get("travel", Vector2.ZERO) as Vector2
				node.position = (base_position + travel * eased).round()

		var frame_seconds := maxf(0.05, float(group.get("frame_seconds", 0.30)))
		var frame_elapsed := float(group.get("frame_elapsed", 0.0)) + delta
		var cursor := int(group.get("cursor", 0))
		while frame_elapsed >= frame_seconds:
			frame_elapsed -= frame_seconds
			cursor = (cursor + 1) % sequence.size()
		group["frame_elapsed"] = frame_elapsed
		group["cursor"] = cursor
		var frame_index := int(sequence[cursor])
		if frame_index >= 0 and frame_index < frames.size():
			node.texture = frames[frame_index]
		var alpha_sequence := group.get("alpha_sequence", []) as Array
		var alpha := float(group.get("base_alpha", 1.0))
		if not alpha_sequence.is_empty():
			alpha = float(alpha_sequence[cursor % alpha_sequence.size()])
		node.modulate = Color(1, 1, 1, alpha)
		animated_groups[index] = group


func _update_cloud_drift() -> void:
	for group in animated_groups:
		var kind := StringName(group.get("kind", &"frames"))
		if kind != &"drift_far" and kind != &"drift_near":
			continue
		var node := group.get("node") as TextureRect
		if node == null:
			continue
		var base := group.get("base", Vector2.ZERO) as Vector2
		var speed := 0.075 if kind == &"drift_far" else 0.11
		var amplitude := 2.0 if kind == &"drift_far" else 3.0
		node.position = base + Vector2(round(sin(scene_elapsed * speed) * amplitude), 0)


func _update_transition(delta: float) -> void:
	transition_elapsed += delta
	var next_frame := 0
	for index in range(TRANSITION_FRAME_MARKS.size()):
		if transition_elapsed >= float(TRANSITION_FRAME_MARKS[index]):
			next_frame = index
	if next_frame != transition_frame_index:
		transition_frame_index = next_frame
	if transition_texture != null:
		var progress := clampf(transition_elapsed / TRANSITION_DURATION, 0.0, 1.0)
		transition_texture.color.a = smoothstep(0.0, 1.0, progress)
	if transition_elapsed >= TRANSITION_DURATION:
		var entry := pending_transition_entry.duplicate(true)
		transition_active = false
		pending_transition_entry.clear()
		if transition_texture != null:
			transition_texture.visible = false
		_emit_entry(entry)


func _unhandled_input(event: InputEvent) -> void:
	if transition_active or not (event is InputEventKey):
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


func _register_animation(parent: Control, node_name: String, rect: Rect2, key_prefix: String, frame_count: int, local_z: int, profile: Dictionary = {}) -> TextureRect:
	var frames := _texture_sequence(key_prefix, frame_count)
	if frames.is_empty():
		return null
	var node := _add_texture_from_texture(parent, node_name, rect, frames[0], local_z)
	if node != null:
		var sequence: Array = profile.get("sequence", range(frames.size())) as Array
		var initial_delay := float(profile.get("initial_delay", 0.0))
		var base_alpha := float(profile.get("base_alpha", 1.0))
		var reduce_behavior := StringName(profile.get("reduce_motion_behavior", &"hide"))
		node.visible = reduce_behavior == &"freeze" if reduced_motion else initial_delay <= 0.0
		node.modulate = Color(1, 1, 1, base_alpha)
		animated_groups.append({
			"name": node_name,
			"kind": StringName(profile.get("kind", &"loop")),
			"node": node,
			"frames": frames,
			"sequence": sequence.duplicate(),
			"frame_seconds": float(profile.get("frame_seconds", 0.30)),
			"frame_elapsed": 0.0,
			"cursor": 0,
			"active_elapsed": 0.0,
			"active_seconds": float(profile.get("active_seconds", 0.0)),
			"initial_delay": initial_delay,
			"cooldown": initial_delay,
			"cooldown_seconds": float(profile.get("cooldown_seconds", 0.0)),
			"base_position": rect.position.round(),
			"travel": profile.get("travel", Vector2.ZERO) as Vector2,
			"base_alpha": base_alpha,
			"alpha_sequence": (profile.get("alpha_sequence", []) as Array).duplicate(),
			"reduce_motion_behavior": reduce_behavior,
		})
	return node


func _texture_sequence(prefix: String, frame_count: int) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for index in range(frame_count):
		var key := StringName("%s.%02d" % [prefix, index])
		var texture := _texture(key)
		if texture != null:
			frames.append(texture)
	return frames


func _texture(visual_key: StringName) -> Texture2D:
	if texture_cache.has(visual_key):
		return texture_cache[visual_key] as Texture2D
	var texture := Art21UIPlacementContractScript.main_menu_scene_texture(visual_key)
	if texture != null:
		texture_cache[visual_key] = texture
	return texture


func _add_texture(parent: Control, node_name: String, rect: Rect2, visual_key: StringName, local_z: int) -> TextureRect:
	return _add_texture_from_texture(parent, node_name, rect, _texture(visual_key), local_z)


func _add_texture_from_texture(parent: Control, node_name: String, rect: Rect2, texture: Texture2D, local_z: int) -> TextureRect:
	if texture == null:
		return null
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.z_index = local_z
	_set_rect(texture_rect, rect)
	parent.add_child(texture_rect)
	return texture_rect


func _add_scene_label(parent: Control, node_name: String, rect: Rect2, text: String, font_size: int, color: Color, local_z: int, outline_size: int = 2) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = local_z
	label.add_theme_color_override("font_shadow_color", Color(0.06, 0.035, 0.02, 0.82))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	Art10UISkinKitScript.apply_label(label, font_size, color)
	if outline_size > 0:
		label.add_theme_color_override("font_outline_color", Color(0.10, 0.055, 0.025, 0.92))
		label.add_theme_constant_override("outline_size", outline_size)
	_set_rect(label, rect)
	parent.add_child(label)
	return label


func _add_color_rect(parent: Control, node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.name = node_name
	color_rect.color = color
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(color_rect, rect)
	parent.add_child(color_rect)
	return color_rect


func _add_focus_outline(parent: Control, node_name: String, rect: Rect2, local_z: int) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = local_z
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color(1.0, 0.76, 0.32, 0.78)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	style.shadow_color = Color(0.98, 0.58, 0.14, 0.22)
	style.shadow_size = 3
	panel.add_theme_stylebox_override("panel", style)
	_set_rect(panel, rect)
	parent.add_child(panel)
	return panel


func _apply_transparent_button_style(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, empty)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0))
	button.add_theme_color_override("font_focus_color", Color(1, 1, 1, 0))


func _set_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position.round()
	control.size = rect.size.round()


func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(false)
	return {}
