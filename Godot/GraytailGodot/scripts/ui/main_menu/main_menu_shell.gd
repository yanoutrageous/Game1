extends Control
class_name MainMenuShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const MainMenuModelScript := preload("res://scripts/ui/main_menu/main_menu_model.gd")
const MainMenuLayoutContractScript := preload("res://scripts/ui/main_menu/main_menu_layout_contract.gd")
const MainMenuTransitionPresenterScript := preload("res://scripts/ui/main_menu/main_menu_transition_presenter.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const Art23LongTermAssetContractScript := preload("res://scripts/presentation/art23_long_term_asset_contract.gd")
const CharacterPresentationCatalogScript := preload("res://scripts/presentation/character/character_presentation_catalog.gd")

signal navigation_intent_requested(intent: Dictionary)
signal navigation_transition_requested(intent: Dictionary, profile_id: StringName, entry_id: StringName)
signal navigation_transition_finished(token: int)
signal navigation_transition_cancel_requested(token: int, reason_code: StringName)

const LOGICAL_VIEWPORT_SIZE := Vector2i(1280, 720)
const ENTRY_BOARD_NAMES := {
	&"deploy": "explore",
	&"long_term": "long_term",
	&"settings": "settings",
	&"exit_game": "exit",
}

const ENTRY_TRANSITION_PROFILES := {
	&"deploy": &"enter_cave",
	&"long_term": &"descend",
	&"settings": &"open_overlay",
	&"exit_game": &"open_confirm",
}

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
var character_shadow_texture: TextureRect
var character_idle_frames: Array[Texture2D] = []
var character_focus_frames: Array[Texture2D] = []
var character_actor_id: StringName = CharacterPresentationCatalogScript.DEFAULT_ACTOR_ID
var character_appearance_id: StringName = CharacterPresentationCatalogScript.DEFAULT_APPEARANCE_ID
var character_clip_descriptors: Dictionary = {}
var character_clip_frames: Dictionary = {}
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
var transition_token := 0
var transition_profile_id: StringName = &""
var transition_entry_id: StringName = &""
var transition_origin_focus: StringName = &"deploy"
var transition_finished_emitted := false
var transition_root_base_positions: Dictionary = {}
var transition_character_base_state: Dictionary = {}
var transition_presenter = MainMenuTransitionPresenterScript.new()
var reduced_motion := false
var page_active := true
var ui_scale_factor := 1.0


func build(model: Dictionary = {}) -> void:
	_clear_children()
	Art10UISkinKitScript.apply_player_ui_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_scale_factor = Art10UISkinKitScript.runtime_ui_scale_factor()
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
	set_page_active(true)
	call_deferred("_grab_default_focus")


func set_ui_scale_factor(value: float) -> void:
	var resolved := Art10UISkinKitScript.normalize_runtime_ui_scale_factor(value)
	if is_equal_approx(ui_scale_factor, resolved):
		set_meta("runtime_ui_scale_factor", resolved)
		return
	ui_scale_factor = resolved
	set_meta("runtime_ui_scale_factor", resolved)
	_refresh_ui_scaled_copy()


func apply_snapshot(snapshot: Dictionary) -> void:
	current_snapshot = snapshot.duplicate(true)


func set_page_active(value: bool) -> void:
	page_active = value
	if page_active:
		process_mode = Node.PROCESS_MODE_INHERIT
		set_process(transition_active or not reduced_motion)
		set_process_input(true)
		set_process_unhandled_input(true)
		if reduced_motion:
			_apply_reduced_motion_pose()
		if is_visible_in_tree():
			call_deferred("_grab_default_focus")
		return
	set_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	_reset_navigation_transition(false)
	if is_inside_tree():
		var focus := get_viewport().gui_get_focus_owner()
		if focus != null and (focus == self or is_ancestor_of(focus)):
			get_viewport().gui_release_focus()
	process_mode = Node.PROCESS_MODE_DISABLED


func is_page_active() -> bool:
	return page_active


func set_reduced_motion_enabled(value: bool) -> void:
	reduced_motion = value
	if reduced_motion:
		_apply_reduced_motion_pose()
		if transition_active and transition_token > 0:
			var terminal_pose: Dictionary = transition_presenter.snap_to_end(transition_token)
			if bool(terminal_pose.get("ok", false)):
				_apply_transition_pose(terminal_pose)
				_finish_navigation_transition()
	elif page_active:
		_update_cloud_drift()
		_update_ambient_motion(0.0)
	if page_active:
		set_process(transition_active or not reduced_motion)


func is_reduced_motion_enabled() -> bool:
	return reduced_motion


func play_navigation_transition(token: int, profile_id: StringName, entry_id: StringName, reduced_motion_enabled: bool) -> bool:
	if not page_active or token <= 0 or transition_token > 0:
		return false
	if not ENTRY_TRANSITION_PROFILES.has(entry_id):
		return false
	if StringName(ENTRY_TRANSITION_PROFILES[entry_id]) != profile_id:
		return false
	transition_origin_focus = current_focus
	transition_token = token
	transition_profile_id = profile_id
	transition_entry_id = entry_id
	transition_finished_emitted = false
	_capture_transition_root_positions()
	var initial_pose: Dictionary = transition_presenter.begin(token, profile_id, reduced_motion_enabled)
	if not bool(initial_pose.get("ok", false)):
		_reset_navigation_transition(false)
		return false
	transition_active = not bool(initial_pose.get("complete", false))
	_set_entry_visual_state(entry_id, &"pressed")
	_apply_transition_pose(initial_pose)
	if transition_active:
		set_process(true)
	else:
		_finish_navigation_transition()
	return true


func cancel_navigation_transition(token: int, restore_focus: bool = true) -> bool:
	if token <= 0 or token != transition_token:
		return false
	var result: Dictionary = transition_presenter.cancel(token)
	if not bool(result.get("ok", false)):
		return false
	var focus_to_restore := transition_origin_focus
	_reset_navigation_transition(false)
	if entry_nodes.has(focus_to_restore):
		current_focus = focus_to_restore
		_set_focus_state(focus_to_restore)
		if restore_focus and page_active and is_visible_in_tree():
			var button := _dictionary_from(entry_nodes[focus_to_restore]).get("button") as Button
			if button != null and is_instance_valid(button):
				button.grab_focus()
	return true


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
	character_clip_descriptors.clear()
	character_clip_frames.clear()
	character_actor_id = CharacterPresentationCatalogScript.DEFAULT_ACTOR_ID
	character_appearance_id = CharacterPresentationCatalogScript.DEFAULT_APPEARANCE_ID
	character_texture = null
	character_shadow_texture = null
	transition_texture = null
	transition_presenter.reset()
	transition_active = false
	transition_token = 0
	transition_profile_id = &""
	transition_entry_id = &""
	transition_finished_emitted = false
	transition_root_base_positions.clear()
	transition_character_base_state.clear()


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
	var fixed_fallback := _add_color_rect(self, "MainMenuFixedTransitionFallback", Rect2(0, 0, 1280, 720), Color(0.012, 0.014, 0.018, 1.0))
	fixed_fallback.z_as_relative = false
	fixed_fallback.z_index = UILayerContractScript.BACKGROUND - 2
	var fixed_underlay := _add_texture_from_texture(
		self,
		"MainMenuFixedTransitionUnderlay",
		Rect2(0, 0, 1280, 720),
		Art23LongTermAssetContractScript.texture(&"long_term.scene.background.clean_plate"),
		UILayerContractScript.BACKGROUND - 1
	)
	if fixed_underlay != null:
		fixed_underlay.z_as_relative = false
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
	character_shadow_texture = _add_texture(character_root, "MainMenuCharacterShadow", Rect2(286, 594, 196, 24), &"main_menu.scene.character.shadow", 0)
	var presentation := _dictionary_from(current_model.get("character_presentation", {}))
	character_actor_id = StringName(presentation.get("actor_id", CharacterPresentationCatalogScript.DEFAULT_ACTOR_ID))
	character_appearance_id = StringName(presentation.get("appearance_id", CharacterPresentationCatalogScript.DEFAULT_APPEARANCE_ID))
	_load_character_clip(&"idle")
	_load_character_clip(&"focus_deploy")
	_load_character_clip(&"focus_long_term")
	_load_character_clip(&"walk_dungeon")
	character_idle_frames.assign(character_clip_frames.get(&"idle", []) as Array)
	for focus_clip_id in [&"focus_deploy", &"focus_long_term"]:
		for frame in character_clip_frames.get(focus_clip_id, []) as Array:
			if frame is Texture2D:
				character_focus_frames.append(frame as Texture2D)
	var initial := CharacterPresentationCatalogScript.frame_at(
		character_idle_frames,
		_dictionary_from(character_clip_descriptors.get(&"idle", {})),
		0
	)
	character_texture = _add_texture_from_texture(character_root, "MainMenuCharacter", Rect2(286, 408, 190, 216), initial, 1)


func _build_notice_board() -> void:
	var notice_root := _root(&"SideStatusRoot")
	var notice: Dictionary = _dictionary_from(current_model.get("notice", {}))
	var title_text := String(notice.get("title", "回收站简报"))
	var body_text := String(notice.get("body", ""))
	var text_fit: Dictionary = MainMenuLayoutContractScript.fit_notice(title_text, body_text, ui_scale_factor)
	var title_fit: Dictionary = _dictionary_from(text_fit.get("title", {}))
	var body_fit: Dictionary = _dictionary_from(text_fit.get("description", {}))
	var heading_size := mini(28, Art10UISkinKitScript.scaled_font_size(22, ui_scale_factor))
	_add_scene_label(notice_root, "MainMenuNoticeHeading", _layout_rect(&"notice.heading"), "公告", heading_size, Color(0.95, 0.75, 0.35), 2, 2)
	var title := _add_scene_label(
		notice_root,
		"MainMenuNoticeTitle",
		_layout_rect(&"notice.title"),
		String(title_fit.get("display_text", title_text)),
		int(title_fit.get("font_size", 20)),
		Color(0.38, 0.22, 0.10),
		3,
		0
	)
	if title != null:
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var body := _add_scene_label(
		notice_root,
		"MainMenuNoticeText",
		_layout_rect(&"notice.description"),
		String(body_fit.get("display_text", body_text)),
		int(body_fit.get("font_size", 16)),
		Color(0.24, 0.15, 0.09),
		3,
		0
	)
	if body != null:
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		body.autowrap_mode = TextServer.AUTOWRAP_OFF
		body.add_theme_constant_override("line_spacing", 0)


func _build_menu_signpost() -> void:
	var action_root := _root(&"PrimaryActionRoot")
	explore_focus_texture = _add_texture(_root(&"FloatingInfoRoot"), "MainMenuExploreFocusOutline", _entry_component_rect(&"deploy", &"focus"), &"main_menu.scene.fx.focus_explore", 3)
	generic_focus_texture = _add_focus_outline(_root(&"FloatingInfoRoot"), "MainMenuUtilityFocusOutline", _entry_component_rect(&"long_term", &"focus"), 3)
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
	if not ENTRY_BOARD_NAMES.has(entry_id):
		return
	var board_name := String(ENTRY_BOARD_NAMES[entry_id])
	var label_text := String(entry.get("label", ""))
	var text_fit: Dictionary = MainMenuLayoutContractScript.fit_entry_text(entry_id, label_text, ui_scale_factor)
	var board_rect := _entry_component_rect(entry_id, &"board")
	var text_rect := _entry_component_rect(entry_id, &"text")
	var hit_rect := _entry_component_rect(entry_id, &"hit")
	var board := _add_texture(parent, "MainMenuBoard_" + String(entry_id), board_rect, StringName("main_menu.scene.menu.%s.normal" % board_name), 1)
	var label := _add_scene_label(
		parent,
		"MainMenuBoardLabel_" + String(entry_id),
		text_rect,
		String(text_fit.get("display_text", label_text)),
		int(text_fit.get("font_size", 24)),
		Color(0.98, 0.79, 0.39),
		2
	)
	var button := Button.new()
	button.name = "MainMenuEntry_%s" % String(entry_id)
	button.text = ""
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_set_rect(button, hit_rect)
	_apply_transparent_button_style(button)
	button.focus_entered.connect(func() -> void: _set_focus_state(entry_id))
	button.mouse_entered.connect(func() -> void:
		button.grab_focus()
		_set_focus_state(entry_id)
	)
	button.button_down.connect(func() -> void: _set_entry_visual_state(entry_id, &"pressed"))
	button.button_up.connect(func() -> void: _set_entry_visual_state(entry_id, &"focused"))
	button.pressed.connect(func() -> void: _activate_entry(entry))
	button.set_meta("runtime_ui_scale_factor", ui_scale_factor)
	parent.add_child(button)
	entry_nodes[entry_id] = {
		"board": board,
		"label": label,
		"button": button,
		"base_board_rect": board_rect,
		"base_label_rect": text_rect,
		"base_hit_rect": hit_rect,
		"board_name": board_name,
	}


func _refresh_ui_scaled_copy() -> void:
	var notice: Dictionary = _dictionary_from(current_model.get("notice", {}))
	var notice_title_text := String(notice.get("title", "回收站简报"))
	var notice_body_text := String(notice.get("body", ""))
	var notice_fit: Dictionary = MainMenuLayoutContractScript.fit_notice(
		notice_title_text,
		notice_body_text,
		ui_scale_factor
	)
	var title_fit := _dictionary_from(notice_fit.get("title", {}))
	var body_fit := _dictionary_from(notice_fit.get("description", {}))
	var notice_heading := get_node_or_null("SideStatusRoot/MainMenuNoticeHeading") as Label
	var notice_title := get_node_or_null("SideStatusRoot/MainMenuNoticeTitle") as Label
	var notice_body := get_node_or_null("SideStatusRoot/MainMenuNoticeText") as Label
	_apply_scaled_copy_label(
		notice_heading,
		&"title",
		mini(28, Art10UISkinKitScript.scaled_font_size(22, ui_scale_factor)),
		notice_heading.text if notice_heading != null else "公告"
	)
	_apply_scaled_copy_label(
		notice_title,
		&"title",
		int(title_fit.get("font_size", 20)),
		String(title_fit.get("display_text", notice_title_text))
	)
	_apply_scaled_copy_label(
		notice_body,
		&"body",
		int(body_fit.get("font_size", 16)),
		String(body_fit.get("display_text", notice_body_text))
	)
	if notice_body != null:
		notice_body.autowrap_mode = TextServer.AUTOWRAP_OFF
		notice_body.add_theme_constant_override("line_spacing", 0)
	for entry_id in entry_nodes:
		var nodes := _dictionary_from(entry_nodes[entry_id])
		var entry := _dictionary_from(entry_by_id.get(entry_id, {}))
		var label_text := String(entry.get("label", ""))
		var text_fit := MainMenuLayoutContractScript.fit_entry_text(
			StringName(entry_id),
			label_text,
			ui_scale_factor
		)
		var label := nodes.get("label") as Label
		_apply_scaled_copy_label(
			label,
			&"button",
			int(text_fit.get("font_size", 24)),
			String(text_fit.get("display_text", label_text))
		)
		var button := nodes.get("button") as Button
		if button != null:
			button.set_meta("runtime_ui_scale_factor", ui_scale_factor)


func _apply_scaled_copy_label(label: Label, role: StringName, font_size_value: int, text: String) -> void:
	if label == null:
		return
	label.text = text
	Art10UISkinKitScript.apply_composition_label(label, role, font_size_value)
	label.set_meta("runtime_ui_scale_factor", ui_scale_factor)


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
	if page_active and is_visible_in_tree() and entry_nodes.has(&"deploy"):
		var button := _dictionary_from(entry_nodes[&"deploy"]).get("button") as Button
		if button != null and is_instance_valid(button):
			button.grab_focus()


func _set_focus_state(entry_id: StringName) -> void:
	if not entry_nodes.has(entry_id) or transition_token > 0:
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
		if explore_focused:
			_set_rect(explore_focus_texture, _entry_component_rect(entry_id, &"focus", &"focused"))
	if generic_focus_texture != null:
		generic_focus_texture.visible = not explore_focused
		if not explore_focused:
			_set_rect(generic_focus_texture, _entry_component_rect(entry_id, &"focus", &"focused"))
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
	var button := node_set.get("button") as Button
	var board_name := String(node_set.get("board_name", ""))
	if board != null:
		board.texture = _texture(StringName("main_menu.scene.menu.%s.%s" % [board_name, String(state)]))
		_set_rect(board, _entry_component_rect(entry_id, &"board", state))
	if label != null:
		_set_rect(label, _entry_component_rect(entry_id, &"text", state))
		label.modulate = Color(1.10, 1.06, 0.92, 1.0) if state == &"focused" else Color.WHITE
	if button != null:
		_set_rect(button, _entry_component_rect(entry_id, &"hit", state))
	if entry_id == current_focus:
		var focus_rect := _entry_component_rect(entry_id, &"focus", state)
		if entry_id == &"deploy" and explore_focus_texture != null:
			_set_rect(explore_focus_texture, focus_rect)
		elif entry_id != &"deploy" and generic_focus_texture != null:
			_set_rect(generic_focus_texture, focus_rect)


func _update_character_focus_texture() -> void:
	if character_texture == null or transition_token > 0:
		return
	if current_focus == &"deploy" and _apply_character_clip_pose(&"focus_deploy"):
		return
	if current_focus == &"long_term" and _apply_character_clip_pose(&"focus_long_term"):
		return
	_apply_character_clip_pose(&"idle", idle_frame_index)


func _activate_entry(entry: Dictionary) -> void:
	if not page_active or transition_token > 0:
		return
	var entry_id := StringName(entry.get("id", &""))
	var intent := _intent_from_entry(entry)
	var profile_id := StringName(ENTRY_TRANSITION_PROFILES.get(entry_id, &""))
	if profile_id != &"" and not navigation_transition_requested.get_connections().is_empty():
		navigation_transition_requested.emit(intent, profile_id, entry_id)
		return
	navigation_intent_requested.emit(intent)


func _process(delta: float) -> void:
	if not page_active or not is_visible_in_tree():
		return
	scene_elapsed += delta
	if not reduced_motion:
		_update_cloud_drift()
	if transition_active:
		_update_transition(delta)
		return
	if transition_token > 0:
		return
	if not reduced_motion:
		idle_elapsed += delta
		var idle_descriptor := _dictionary_from(character_clip_descriptors.get(&"idle", {}))
		var idle_sequence := idle_descriptor.get("sequence", []) as Array
		var idle_frame_seconds := maxf(0.01, float(idle_descriptor.get("frame_seconds", 0.32)))
		if not idle_sequence.is_empty() and idle_elapsed >= idle_frame_seconds:
			idle_elapsed = fmod(idle_elapsed, idle_frame_seconds)
			idle_frame_index = (idle_frame_index + 1) % idle_sequence.size()
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


func _apply_reduced_motion_pose() -> void:
	for group in animated_groups:
		var node := group.get("node") as TextureRect
		if node == null:
			continue
		var reduce_behavior := StringName(group.get("reduce_motion_behavior", &"hide"))
		node.visible = reduce_behavior == &"freeze"
		if reduce_behavior == &"freeze":
			var frames := group.get("frames", []) as Array
			if not frames.is_empty():
				node.texture = frames[0]
		var kind := StringName(group.get("kind", &"frames"))
		if kind in [&"drift_far", &"drift_near"]:
			node.position = group.get("base", node.position)
	if cave_activation_texture != null and cave_activation_texture.visible:
		cave_activation_texture.modulate = Color(1, 1, 1, 0.30)
	if company_activation_texture != null and company_activation_texture.visible:
		company_activation_texture.modulate = Color(1, 1, 1, 0.30)


func _finish_navigation_transition() -> void:
	transition_active = false
	if transition_finished_emitted or transition_token <= 0:
		return
	transition_finished_emitted = true
	var finished_token := transition_token
	navigation_transition_finished.emit(finished_token)
	if page_active:
		set_process(not reduced_motion)


func _apply_transition_pose(pose: Dictionary) -> void:
	if int(pose.get("token", 0)) != transition_token:
		return
	_apply_transition_scene_offset(pose.get("scene_offset", Vector2.ZERO) as Vector2)
	var overlay_color := pose.get("overlay_color", Color(0.018, 0.024, 0.032, 0.0)) as Color
	overlay_color.a = clampf(float(pose.get("overlay_alpha", 0.0)), 0.0, 1.0)
	if transition_texture != null:
		transition_texture.color = overlay_color
		transition_texture.visible = overlay_color.a > 0.001
	_apply_activation_alpha(cave_activation_texture, float(pose.get("cave_activation_alpha", 0.0)))
	_apply_activation_alpha(company_activation_texture, float(pose.get("company_activation_alpha", 0.0)))
	_apply_character_transition_pose(
		StringName(pose.get("character_pose", &"idle")),
		int(pose.get("character_clip_step", 0))
	)
	_apply_character_transition_transform(pose)
	if character_shadow_texture != null:
		character_shadow_texture.modulate = Color(1, 1, 1, clampf(float(pose.get("shadow_alpha", 1.0)), 0.0, 1.0))


func _apply_activation_alpha(texture_rect: TextureRect, alpha: float) -> void:
	if texture_rect == null:
		return
	var safe_alpha := clampf(alpha, 0.0, 1.0)
	texture_rect.visible = safe_alpha > 0.001
	texture_rect.modulate = Color(1, 1, 1, safe_alpha)


func _apply_character_transition_pose(pose_id: StringName, step: int = 0) -> void:
	if character_texture == null:
		return
	if pose_id in [&"focus_deploy", &"focus_long_term", &"walk_dungeon"] and _apply_character_clip_pose(pose_id, step):
		return
	_apply_character_clip_pose(&"idle", idle_frame_index)


func _apply_character_transition_transform(pose: Dictionary) -> void:
	if character_texture == null or transition_character_base_state.is_empty():
		return
	var base_position := transition_character_base_state.get("position", character_texture.position) as Vector2
	var base_scale := transition_character_base_state.get("scale", character_texture.scale) as Vector2
	var base_modulate := transition_character_base_state.get("modulate", character_texture.modulate) as Color
	var base_pivot := transition_character_base_state.get("pivot_offset", character_texture.pivot_offset) as Vector2
	if not bool(pose.get("character_transition_active", false)):
		character_texture.position = base_position
		character_texture.scale = base_scale
		character_texture.modulate = base_modulate
		character_texture.pivot_offset = base_pivot
		return

	var travel_progress := clampf(float(pose.get("character_travel_progress", 0.0)), 0.0, 1.0)
	var target_position := MainMenuLayoutContractScript.logical_anchor(&"character_cave_inside")
	var scale_factor := clampf(float(pose.get("character_scale_factor", 1.0)), 0.1, 1.0)
	var alpha := clampf(float(pose.get("character_alpha", 1.0)), 0.0, 1.0)
	character_texture.pivot_offset = character_texture.size * 0.5
	character_texture.position = base_position.lerp(target_position, travel_progress).round()
	character_texture.scale = Vector2(base_scale.x * scale_factor, base_scale.y * scale_factor)
	character_texture.modulate = Color(base_modulate.r, base_modulate.g, base_modulate.b, base_modulate.a * alpha)


func _load_character_clip(clip_id: StringName) -> void:
	var descriptor := CharacterPresentationCatalogScript.resolve_descriptor(
		character_actor_id,
		character_appearance_id,
		clip_id
	)
	character_clip_descriptors[clip_id] = descriptor
	character_clip_frames[clip_id] = CharacterPresentationCatalogScript.load_frames(descriptor)


func _apply_character_clip_pose(clip_id: StringName, step: int = 0) -> bool:
	if character_texture == null:
		return false
	var descriptor := _dictionary_from(character_clip_descriptors.get(clip_id, {}))
	var frames := character_clip_frames.get(clip_id, []) as Array
	var frame := CharacterPresentationCatalogScript.frame_at(frames, descriptor, step)
	if frame == null:
		return false
	character_texture.texture = frame
	character_texture.flip_h = bool(descriptor.get("flip_h", false))
	return true


func _capture_transition_root_positions() -> void:
	transition_root_base_positions.clear()
	for root_name_variant in UILayerContractScript.PAGE_ROOT_ORDER:
		var root_name := StringName(root_name_variant)
		if root_name == &"OverlayRoot" or root_name == &"ModalRoot":
			continue
		var scene_root := get_node_or_null(String(root_name)) as Control
		if scene_root != null:
			transition_root_base_positions[root_name] = scene_root.position
	_capture_transition_character_state()


func _capture_transition_character_state() -> void:
	transition_character_base_state.clear()
	if character_texture == null:
		return
	transition_character_base_state = {
		"position": character_texture.position,
		"scale": character_texture.scale,
		"modulate": character_texture.modulate,
		"pivot_offset": character_texture.pivot_offset,
		"texture": character_texture.texture,
		"flip_h": character_texture.flip_h,
	}


func _apply_transition_scene_offset(scene_offset: Vector2) -> void:
	for raw_root_name in transition_root_base_positions.keys():
		var root_name := StringName(raw_root_name)
		var scene_root := get_node_or_null(String(root_name)) as Control
		if scene_root != null:
			var base_position := transition_root_base_positions[root_name] as Vector2
			scene_root.position = (base_position + scene_offset).round()


func _restore_transition_root_positions() -> void:
	for raw_root_name in transition_root_base_positions.keys():
		var root_name := StringName(raw_root_name)
		var scene_root := get_node_or_null(String(root_name)) as Control
		if scene_root != null:
			scene_root.position = transition_root_base_positions[root_name] as Vector2
	transition_root_base_positions.clear()


func _restore_transition_character_state() -> void:
	if character_texture != null and not transition_character_base_state.is_empty():
		character_texture.position = transition_character_base_state.get("position", character_texture.position) as Vector2
		character_texture.scale = transition_character_base_state.get("scale", character_texture.scale) as Vector2
		character_texture.modulate = transition_character_base_state.get("modulate", character_texture.modulate) as Color
		character_texture.pivot_offset = transition_character_base_state.get("pivot_offset", character_texture.pivot_offset) as Vector2
		character_texture.texture = transition_character_base_state.get("texture", character_texture.texture) as Texture2D
		character_texture.flip_h = bool(transition_character_base_state.get("flip_h", character_texture.flip_h))
	transition_character_base_state.clear()


func _reset_navigation_transition(restore_focus_owner: bool) -> void:
	var focus_to_restore := transition_origin_focus if transition_token > 0 else current_focus
	_restore_transition_root_positions()
	_restore_transition_character_state()
	if transition_texture != null:
		transition_texture.color = Color(0.018, 0.024, 0.032, 0.0)
		transition_texture.visible = false
	if character_shadow_texture != null:
		character_shadow_texture.modulate = Color.WHITE
	if cave_activation_texture != null:
		cave_activation_texture.modulate = Color(1, 1, 1, 0.30)
	if company_activation_texture != null:
		company_activation_texture.modulate = Color(1, 1, 1, 0.30)
	transition_presenter.reset()
	transition_active = false
	transition_token = 0
	transition_profile_id = &""
	transition_entry_id = &""
	transition_finished_emitted = false
	if entry_nodes.has(focus_to_restore):
		current_focus = focus_to_restore
		_set_focus_state(focus_to_restore)
		if restore_focus_owner and page_active and is_visible_in_tree():
			var button := _dictionary_from(entry_nodes[focus_to_restore]).get("button") as Button
			if button != null and is_instance_valid(button):
				button.grab_focus()


func _update_transition(delta: float) -> void:
	var pose: Dictionary = transition_presenter.advance(delta)
	if not bool(pose.get("ok", false)):
		var failed_token := transition_token
		_reset_navigation_transition(true)
		if failed_token > 0:
			navigation_transition_cancel_requested.emit(failed_token, &"presentation_failed")
		return
	_apply_transition_pose(pose)
	transition_active = not bool(pose.get("complete", false))
	if not transition_active:
		_finish_navigation_transition()


func handle_cancel_event(event: InputEvent) -> bool:
	if not page_active or not is_visible_in_tree():
		return false
	if transition_active:
		if event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
			var active_token := transition_token
			navigation_transition_cancel_requested.emit(active_token, &"user_cancel")
			if transition_token == active_token:
				cancel_navigation_transition(active_token, true)
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if handle_cancel_event(event):
		get_viewport().set_input_as_handled()
		return
	if not page_active or not is_visible_in_tree() or transition_active or transition_token > 0 or event.is_echo():
		return
	if event.is_action_pressed("menu_shortcut_primary"):
		if _emit_shortcut_index(0):
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_shortcut_secondary"):
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
	navigation_intent_requested.emit(_intent_from_entry(entry))


func _intent_from_entry(entry: Dictionary) -> Dictionary:
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
	return intent


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
	var composition_role := &"body"
	if node_name in ["MainMenuTitle", "MainMenuNoticeHeading", "MainMenuNoticeTitle"]:
		composition_role = &"title"
	elif node_name.begins_with("MainMenuBoardLabel_"):
		composition_role = &"button"
	Art10UISkinKitScript.apply_composition_label(label, composition_role, font_size, color)
	if outline_size > 0:
		label.add_theme_color_override("font_outline_color", Color(0.10, 0.055, 0.025, 0.92))
		label.add_theme_constant_override("outline_size", outline_size)
	label.set_meta("runtime_ui_scale_factor", ui_scale_factor)
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


func _layout_rect(element_id: StringName, active_focus: StringName = &"") -> Rect2:
	return MainMenuLayoutContractScript.rect(element_id, LOGICAL_VIEWPORT_SIZE, active_focus)


func _entry_component_rect(entry_id: StringName, component_id: StringName, state: StringName = &"normal") -> Rect2:
	var active_focus := entry_id if state == &"focused" else &""
	var element_id := StringName("entry.%s.%s" % [String(entry_id), String(component_id)])
	var rect := _layout_rect(element_id, active_focus)
	if state == &"pressed":
		rect.position += Vector2(2, 2)
	return rect


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
