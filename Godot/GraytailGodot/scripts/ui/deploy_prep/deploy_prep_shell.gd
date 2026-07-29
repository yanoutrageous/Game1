extends Control
class_name DeployPrepShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const DeployPrepModelScript := preload("res://scripts/ui/deploy_prep/deploy_prep_model.gd")
const DeployTabModelScript := preload("res://scripts/ui/deploy_prep/deploy_tab_model.gd")
const DeployPrepCardViewScript := preload("res://scripts/ui/deploy_prep/deploy_prep_card_view.gd")
const DeployPrepLayoutContractScript := preload("res://scripts/ui/deploy_prep/deploy_prep_layout_contract.gd")
const DeployMapSplitViewScript := preload("res://scripts/ui/deploy_prep/deploy_map_split_view.gd")
const RunStartRouteAdapterScript := preload("res://scripts/core/run/run_start_route_adapter.gd")
const MetaActionRequestIdScript := preload("res://scripts/core/progression/meta_action_request_id.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const ModalFocusStackScript := preload("res://scripts/ui/shell/modal_focus_stack.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21MainMenuAssetContractScript := preload("res://scripts/presentation/art21_main_menu_asset_contract.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const Art22DeployPrepAssetContractScript := preload("res://scripts/presentation/art22_deploy_prep_asset_contract.gd")
const Art25ContentAssetContractScript := preload("res://scripts/presentation/art25_content_asset_contract.gd")
const CharacterPresentationCatalogScript := preload("res://scripts/presentation/character/character_presentation_catalog.gd")

signal deploy_start_intent_requested(intent: Dictionary)
signal navigation_intent_requested(intent: Dictionary)
signal meta_action_requested(action: Dictionary)

const SUMMARY_PAGES := [
	{"id": &"overview", "label": "速览"},
	{"id": &"config", "label": "携带"},
	{"id": &"effect", "label": "本局"},
	{"id": &"objective", "label": "目标"},
]
const CHARACTER_FIRST_LOOK_SECONDS := 5.0
const CHARACTER_LOOK_INTERVAL_SECONDS := 10.0
const META_DETAIL_ACTION_IDS := [&"purchase", &"sell", &"confirm_batch_sell"]
const SUMMARY_INITIAL_ROWS := 8

var current_model: Dictionary = {}
var current_snapshot: Dictionary = {}
var view_state_by_tab: Dictionary = {}
var texture_cache: Dictionary = {}

var tab_buttons: Dictionary = {}
var filter_buttons: Dictionary = {}
var card_views: Array = []
var summary_buttons: Dictionary = {}
var primary_tab_button_group := ButtonGroup.new()
var filter_button_group := ButtonGroup.new()
var summary_button_group := ButtonGroup.new()

var parchment_group: Control
var filter_scroll: ScrollContainer
var filter_row: HBoxContainer
var filter_previous_button: Button
var filter_next_button: Button
var card_scroll: ScrollContainer
var card_list: VBoxContainer
var warehouse_batch_entry_button: Button
var warehouse_batch_select_all_button: Button
var warehouse_batch_clear_button: Button
var map_split_view: Control
var detail_panel: Panel
var detail_gold_panel: Panel
var detail_gold_icon: TextureRect
var detail_gold_label: Label
var detail_artwork: TextureRect
var detail_title_label: Label
var detail_badge_label: Label
var detail_body_scroll: ScrollContainer
var detail_body_content: VBoxContainer
var detail_description_label: Label
var detail_fact_labels: Array[Label] = []
var detail_feedback_panel: Panel
var detail_feedback_label: Label
var detail_primary_action_button: Button
var detail_secondary_action_button: Button
var detail_actions: Array[Dictionary] = []
var pending_meta_action: Dictionary = {}
var last_meta_action_result: Dictionary = {}
var meta_request_sequence := 0
var result_hint_panel: Panel
var result_hint_label: Label
var collapse_button: Button
var primary_action_button: Button
var cancel_action_button: Button
var summary_body_label: Label
var summary_message_label: Label
var summary_row_labels: Array[Label] = []
var summary_scroll: ScrollContainer
var summary_scroll_content: VBoxContainer
var modal_layer: Control
var modal_cancel_button: Button
var modal_confirm_button: Button
var warehouse_batch_modal_layer: Control
var warehouse_batch_modal_body: Label
var warehouse_batch_modal_cancel_button: Button
var warehouse_batch_modal_confirm_button: Button
var character_texture: TextureRect
var character_frames: Array[Texture2D] = []
var character_actor_id: StringName = CharacterPresentationCatalogScript.DEFAULT_ACTOR_ID
var character_appearance_id: StringName = CharacterPresentationCatalogScript.DEFAULT_APPEARANCE_ID
var character_clip_descriptors: Dictionary = {}
var character_clip_frames: Dictionary = {}
var ambient_animations: Array[Dictionary] = []
var ambient_particles: Array[CPUParticles2D] = []
var summary_chain_bases: Dictionary = {}
var modal_focus_stack = ModalFocusStackScript.new()

var active_summary_page: StringName = &"overview"
var parchment_collapsed := false
var reduced_motion := false
var ui_scale_factor := 1.0
var scene_elapsed := 0.0
var character_elapsed := 0.0
var character_frame_index := 0
var character_look_index := -1
var next_character_look := CHARACTER_FIRST_LOOK_SECONDS
var collapse_tween: Tween
var page_active := true
var warehouse_batch_active := false
var warehouse_batch_selected_ids: Array[String] = []
var warehouse_batch_feedback := ""


func build(model: Dictionary = {}) -> void:
	modal_focus_stack.clear(false)
	_clear_children()
	ui_scale_factor = Art10UISkinKitScript.runtime_ui_scale_factor()
	set_meta("runtime_ui_scale_factor", ui_scale_factor)
	Art10UISkinKitScript.apply_player_ui_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_model = model.duplicate(true) if not model.is_empty() else DeployPrepModelScript.build(current_snapshot)
	reduced_motion = Art10UISkinKitScript.reduce_motion_enabled()
	_create_layer_roots()
	_build_background()
	_build_decorations()
	_build_ambient_motion()
	_build_character()
	_build_navigation()
	_build_parchment_content()
	_build_summary_board()
	_build_primary_actions()
	_build_cancel_modal()
	_build_warehouse_batch_confirm_modal()
	_refresh_all(true)
	_refresh_ui_scale_metrics()
	set_page_active(true)
	call_deferred("_grab_initial_focus")


func apply_snapshot(snapshot: Dictionary) -> void:
	_save_active_view_state()
	current_snapshot = snapshot.duplicate(true)
	var previous_tab := _active_tab()
	current_model = DeployPrepModelScript.refresh_from_snapshot(current_model, current_snapshot)
	current_model = DeployPrepModelScript.model_with_tab(current_model, previous_tab)
	_restore_model_state(previous_tab)
	_refresh_all(true)


func apply_meta_action_result(envelope: Dictionary) -> bool:
	if pending_meta_action.is_empty():
		return false
	if str(envelope.get("request_id", "")) != str(pending_meta_action.get("request_id", "")):
		return false
	if StringName(envelope.get("source_page", &"")) != &"deploy_prep":
		return false
	if StringName(envelope.get("action", &"")) != StringName(pending_meta_action.get("action", &"")):
		return false
	if str(envelope.get("target_id", "")) != str(pending_meta_action.get("target_id", "")):
		return false
	var completed_action := StringName(envelope.get("action", &""))
	pending_meta_action.clear()
	last_meta_action_result = envelope.duplicate(true)
	var player_message := _meta_result_player_message(envelope)
	if completed_action == &"sell_collectibles_batch":
		if bool(envelope.get("ok", false)) and StringName(envelope.get("status", &"")) == &"batch_sold":
			warehouse_batch_active = false
			warehouse_batch_selected_ids.clear()
			warehouse_batch_feedback = ""
		else:
			warehouse_batch_feedback = player_message
		_hide_warehouse_batch_confirmation()
	current_model = DeployPrepModelScript.model_with_action_message(current_model, player_message)
	_refresh_all(false)
	return true


func show_action_message(message: String) -> void:
	current_model = DeployPrepModelScript.model_with_action_message(current_model, message)
	_refresh_all(false)


func get_meta_transaction_snapshot() -> Dictionary:
	return {
		"pending": not pending_meta_action.is_empty(),
		"pending_request": pending_meta_action.duplicate(true),
		"last_result": last_meta_action_result.duplicate(true),
		"request_sequence": meta_request_sequence,
		"warehouse_batch": get_warehouse_batch_snapshot(),
	}


func set_page_active(value: bool) -> void:
	page_active = value
	if page_active:
		process_mode = Node.PROCESS_MODE_INHERIT
		set_process(not reduced_motion)
		set_process_input(true)
		set_process_unhandled_input(true)
		for particles in ambient_particles:
			if particles != null:
				particles.emitting = not reduced_motion
		if map_split_view != null:
			map_split_view.call("set_active", _active_tab() == DeployTabModelScript.TAB_MAP)
		if reduced_motion:
			_freeze_motion()
		if is_visible_in_tree():
			call_deferred("_grab_initial_focus")
		return
	if warehouse_batch_active:
		_cancel_warehouse_batch_sell(false)
	modal_focus_stack.clear(false)
	if modal_layer != null:
		modal_layer.hide()
	if warehouse_batch_modal_layer != null:
		warehouse_batch_modal_layer.hide()
	set_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	if map_split_view != null:
		map_split_view.call("set_active", false)
	if collapse_tween != null and collapse_tween.is_valid():
		collapse_tween.kill()
	if parchment_group != null:
		parchment_group.position = DeployPrepLayoutContractScript.COLLAPSED_OFFSET if parchment_collapsed else Vector2.ZERO
	for particles in ambient_particles:
		if particles != null:
			particles.emitting = false
	if is_inside_tree():
		var focus := get_viewport().gui_get_focus_owner()
		if focus != null and (focus == self or is_ancestor_of(focus)):
			get_viewport().gui_release_focus()
	process_mode = Node.PROCESS_MODE_DISABLED


func is_page_active() -> bool:
	return page_active


func set_reduced_motion_enabled(value: bool) -> void:
	if reduced_motion == value:
		if reduced_motion:
			_freeze_motion()
		if page_active:
			set_process(not reduced_motion)
		for particles in ambient_particles:
			if particles != null:
				particles.emitting = page_active and not reduced_motion
		return
	reduced_motion = value
	if map_split_view != null:
		map_split_view.call("set_reduced_motion_enabled", value)
	if collapse_tween != null and collapse_tween.is_valid():
		collapse_tween.kill()
	if parchment_group != null:
		parchment_group.position = DeployPrepLayoutContractScript.COLLAPSED_OFFSET if parchment_collapsed else Vector2.ZERO
	if reduced_motion:
		_freeze_motion()
		if card_scroll != null:
			card_scroll.modulate = Color.WHITE
		if modal_layer != null:
			modal_layer.modulate = Color.WHITE
		if warehouse_batch_modal_layer != null:
			warehouse_batch_modal_layer.modulate = Color.WHITE
	if page_active:
		set_process(not reduced_motion)
	for particles in ambient_particles:
		if particles != null:
			particles.emitting = page_active and not reduced_motion


func is_reduced_motion_enabled() -> bool:
	return reduced_motion


func set_ui_scale_factor(value: float) -> void:
	ui_scale_factor = Art10UISkinKitScript.normalize_runtime_ui_scale_factor(value)
	set_meta("runtime_ui_scale_factor", ui_scale_factor)
	_refresh_ui_scale_metrics()
	if map_split_view != null and map_split_view.has_method("set_ui_scale_factor"):
		map_split_view.call("set_ui_scale_factor", ui_scale_factor)
	for view in card_views:
		if view != null and is_instance_valid(view) and view.has_method("set_ui_scale_factor"):
			view.call("set_ui_scale_factor", ui_scale_factor)
	if not current_model.is_empty():
		_refresh_wallet()
		_refresh_detail_projection()
		_refresh_summary()
		_refresh_actions()


func get_ui_scale_factor() -> float:
	return ui_scale_factor


func show_tab(tab_id: StringName) -> void:
	var normalized := _normalize_tab_id(tab_id)
	if current_model.is_empty():
		current_model = DeployPrepModelScript.build(current_snapshot)
	if normalized == _active_tab():
		return
	if warehouse_batch_active:
		_cancel_warehouse_batch_sell(false)
	_save_active_view_state()
	current_model = DeployPrepModelScript.model_with_tab(current_model, normalized)
	_restore_model_state(normalized)
	_refresh_all(true)
	if page_active and not reduced_motion and card_scroll != null:
		Art10UISkinKitScript.play_panel_open(card_scroll)


func apply_route_payload(payload: Dictionary) -> void:
	show_tab(StringName(payload.get("tab", DeployTabModelScript.DEFAULT_TAB)))


func set_parchment_collapsed(value: bool, animate: bool = true) -> void:
	if parchment_group == null:
		return
	parchment_collapsed = value
	if collapse_tween != null and collapse_tween.is_valid():
		collapse_tween.kill()
	var target := DeployPrepLayoutContractScript.COLLAPSED_OFFSET if value else Vector2.ZERO
	var duration := 0.0 if not page_active or reduced_motion or not animate else 0.28
	if duration <= 0.0:
		parchment_group.position = target
	else:
		collapse_tween = create_tween()
		collapse_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		collapse_tween.tween_property(parchment_group, "position", target, duration)
	if collapse_button != null:
		collapse_button.text = "展开内容" if value else "收起内容"
		_apply_image_button_surface(collapse_button, &"handle", &"normal")
	if value and _focus_is_inside(parchment_group) and collapse_button != null:
		collapse_button.grab_focus()


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	texture_cache.clear()
	tab_buttons.clear()
	filter_buttons.clear()
	card_views.clear()
	summary_buttons.clear()
	character_frames.clear()
	character_clip_descriptors.clear()
	character_clip_frames.clear()
	character_actor_id = CharacterPresentationCatalogScript.DEFAULT_ACTOR_ID
	character_appearance_id = CharacterPresentationCatalogScript.DEFAULT_APPEARANCE_ID
	ambient_animations.clear()
	ambient_particles.clear()
	summary_chain_bases.clear()
	parchment_group = null
	filter_scroll = null
	filter_row = null
	filter_previous_button = null
	filter_next_button = null
	card_scroll = null
	card_list = null
	warehouse_batch_entry_button = null
	warehouse_batch_select_all_button = null
	warehouse_batch_clear_button = null
	map_split_view = null
	detail_panel = null
	detail_gold_panel = null
	detail_gold_icon = null
	detail_gold_label = null
	detail_artwork = null
	detail_title_label = null
	detail_badge_label = null
	detail_description_label = null
	detail_fact_labels.clear()
	detail_feedback_panel = null
	detail_feedback_label = null
	detail_primary_action_button = null
	detail_secondary_action_button = null
	detail_actions.clear()
	pending_meta_action.clear()
	last_meta_action_result.clear()
	result_hint_panel = null
	result_hint_label = null
	collapse_button = null
	primary_action_button = null
	cancel_action_button = null
	summary_body_label = null
	summary_message_label = null
	summary_row_labels.clear()
	modal_layer = null
	modal_cancel_button = null
	modal_confirm_button = null
	warehouse_batch_modal_layer = null
	warehouse_batch_modal_body = null
	warehouse_batch_modal_cancel_button = null
	warehouse_batch_modal_confirm_button = null
	warehouse_batch_active = false
	warehouse_batch_selected_ids.clear()
	warehouse_batch_feedback = ""
	character_texture = null
	scene_elapsed = 0.0
	character_elapsed = 0.0
	character_frame_index = 0
	character_look_index = -1
	next_character_look = CHARACTER_FIRST_LOOK_SECONDS


func _create_layer_roots() -> void:
	for root_name_variant in UILayerContractScript.PAGE_ROOT_ORDER:
		var root_name := StringName(root_name_variant)
		UILayerContractScript.ensure_root(self, root_name, UILayerContractScript.page_root_role(root_name))
	for index in range(UILayerContractScript.PAGE_ROOT_ORDER.size()):
		var root := get_node_or_null(String(UILayerContractScript.PAGE_ROOT_ORDER[index]))
		if root != null:
			move_child(root, index)


func _root(root_name: StringName) -> Control:
	return get_node(String(root_name)) as Control


func _build_background() -> void:
	var root := _root(&"BackgroundRoot")
	_add_color_rect(root, "DeployPrepBackdrop", Rect2(Vector2.ZERO, DeployPrepLayoutContractScript.LOGICAL_SIZE), Color(0.025, 0.035, 0.04, 1.0))
	_add_texture(root, "DeployPrepSceneCleanPlate", Rect2(Vector2.ZERO, DeployPrepLayoutContractScript.LOGICAL_SIZE), &"deploy_prep.scene.background.clean_plate", 0, false)
	_add_color_rect(root, "DeployPrepReadableVignette", Rect2(0, 0, 1280, 720), Color(0.01, 0.015, 0.02, 0.055))


func _build_decorations() -> void:
	var root := _root(&"DecorationRoot")
	_add_texture(root, "DeployNavChainTop", DeployPrepLayoutContractScript.NAV_CHAIN_TOP, &"deploy_prep.decoration.chain.vertical", 0)
	_add_texture(root, "DeployNavChainMiddle", DeployPrepLayoutContractScript.NAV_CHAIN_MIDDLE, &"deploy_prep.decoration.chain.vertical", 0)
	var summary_left := _add_texture(root, "DeploySummaryChainLeft", DeployPrepLayoutContractScript.SUMMARY_CHAIN_LEFT, &"deploy_prep.decoration.chain.vertical", 0)
	var summary_right := _add_texture(root, "DeploySummaryChainRight", DeployPrepLayoutContractScript.SUMMARY_CHAIN_RIGHT, &"deploy_prep.decoration.chain.vertical", 0)
	if summary_left != null:
		summary_chain_bases[summary_left.name] = summary_left.position
	if summary_right != null:
		summary_chain_bases[summary_right.name] = summary_right.position


func _build_ambient_motion() -> void:
	var root := _root(&"DecorationRoot")
	_register_art21_loop(root, "DeployLeftLanternFlame", Rect2(400, 307, 24, 30), "main_menu.scene.fx.lantern_flame", [0, 1, 2, 3, 2, 1], 0.22, Color(1.0, 0.72, 0.34), 0.36)
	_register_art21_loop(root, "DeployLeftTableFlame", Rect2(184, 448, 20, 24), "main_menu.scene.fx.lantern_flame", [1, 2, 3, 2, 1, 0], 0.24, Color(1.0, 0.67, 0.28), 0.30)
	_register_art21_loop(root, "DeployRightLanternFlame", Rect2(939, 357, 22, 28), "main_menu.scene.fx.lantern_flame", [2, 3, 2, 1, 0, 1], 0.20, Color(1.0, 0.62, 0.24), 0.32)
	_register_art21_loop(root, "DeployFarLanternFlame", Rect2(1252, 188, 20, 26), "main_menu.scene.fx.lantern_flame", [0, 1, 2, 3, 2, 1], 0.26, Color(1.0, 0.58, 0.22), 0.26)
	_register_art21_loop(root, "DeployBlueWispNear", Rect2(565, 158, 18, 26), "main_menu.scene.fx.lantern_flame", [0, 1, 2, 3, 2, 1], 0.28, Color(0.28, 0.82, 1.0), 0.22)
	_register_art21_loop(root, "DeployBlueWispFar", Rect2(793, 158, 18, 26), "main_menu.scene.fx.lantern_flame", [2, 3, 2, 1, 0, 1], 0.31, Color(0.22, 0.72, 1.0), 0.20)
	_register_art21_loop(root, "DeployBlueGroundFlame", Rect2(568, 460, 20, 25), "main_menu.scene.fx.lantern_flame", [1, 2, 3, 2, 1, 0], 0.25, Color(0.20, 0.78, 1.0), 0.24)
	_register_art21_loop(root, "DeployWorkshopSmoke", Rect2(170, 382, 54, 68), "main_menu.scene.fx.smoke", [0, 1, 2, 3], 0.64, Color(0.72, 0.76, 0.78), 0.08)
	_add_ambient_particles(root, "DeployBlueDust", Vector2(680, 386), Vector2(250, 170), 18, Color(0.28, 0.78, 0.95, 0.42), Vector2(0, -7), 5.4)
	_add_ambient_particles(root, "DeployWarmEmbers", Vector2(205, 438), Vector2(82, 72), 10, Color(1.0, 0.52, 0.20, 0.48), Vector2(5, -18), 3.6)


func _build_character() -> void:
	var root := _root(&"CharacterRoot")
	_add_art21_texture(root, "DeployCharacterShadow", DeployPrepLayoutContractScript.CHARACTER_SHADOW, &"main_menu.scene.character.shadow", 0)
	var presentation := _dictionary_from(current_model.get("character_presentation", {}))
	character_actor_id = StringName(presentation.get("actor_id", CharacterPresentationCatalogScript.DEFAULT_ACTOR_ID))
	character_appearance_id = StringName(presentation.get("appearance_id", CharacterPresentationCatalogScript.DEFAULT_APPEARANCE_ID))
	_load_character_clip(&"idle")
	_load_character_clip(&"look")
	character_frames.assign(character_clip_frames.get(&"idle", []) as Array)
	var initial := CharacterPresentationCatalogScript.frame_at(
		character_frames,
		_dictionary_from(character_clip_descriptors.get(&"idle", {})),
		0
	)
	character_texture = _add_texture_from_texture(root, "DeployCharacter", DeployPrepLayoutContractScript.CHARACTER, initial, 1, true)


func _build_navigation() -> void:
	var root := _root(&"PrimaryActionRoot")
	_add_image_button(root, "DeployNavMain", DeployPrepLayoutContractScript.NAV_MAIN, "返回主菜单", &"nav", _request_back_to_main, 17)
	_add_image_button(root, "DeployNavLongTerm", DeployPrepLayoutContractScript.NAV_LONG_TERM, "长期系统", &"nav", _request_long_term, 17)
	_add_image_button(root, "DeployAppearanceButton", DeployPrepLayoutContractScript.APPEARANCE_BUTTON, "外观", &"handle", _request_appearance, 15)
	_add_image_button(root, "DeployCharacterButton", DeployPrepLayoutContractScript.CHARACTER_BUTTON, "时装", &"handle", _request_appearance, 15)


func _build_parchment_content() -> void:
	var root := _root(&"MainContentRoot")
	parchment_group = Control.new()
	parchment_group.name = "DeployParchmentGroup"
	parchment_group.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parchment_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(parchment_group)
	_add_texture(parchment_group, "DeployParchment", DeployPrepLayoutContractScript.PARCHMENT, &"deploy_prep.panel.parchment", 0)
	_build_primary_tabs()
	_build_filter_row()
	_build_card_list()
	_build_warehouse_batch_controls()
	_build_map_split_view()
	_build_detail_panel()
	collapse_button = _add_image_button(root, "DeployCollapseHandle", DeployPrepLayoutContractScript.COLLAPSE_HANDLE, "收起内容", &"handle", _toggle_parchment, 15)


func _build_primary_tabs() -> void:
	primary_tab_button_group.allow_unpress = false
	var tabs := _array_from(current_model, "tabs")
	var base := DeployPrepLayoutContractScript.PRIMARY_TABS
	for index in range(tabs.size()):
		var tab := _dictionary_from(tabs[index])
		var tab_id := StringName(tab.get("id", DeployTabModelScript.DEFAULT_TAB))
		var rect := Rect2(
			base.position + Vector2(index * (DeployPrepLayoutContractScript.TAB_WIDTH + DeployPrepLayoutContractScript.TAB_GAP), 0),
			Vector2(DeployPrepLayoutContractScript.TAB_WIDTH, base.size.y)
		)
		var captured := tab_id
		var button := _add_image_button(parchment_group, "DeployTab_%s" % String(tab_id), rect, String(tab.get("label", tab_id)), &"tab", func() -> void: show_tab(captured), 16)
		button.toggle_mode = true
		button.button_group = primary_tab_button_group
		tab_buttons[tab_id] = button


func _build_filter_row() -> void:
	filter_scroll = ScrollContainer.new()
	filter_scroll.name = "DeployFilterScroll"
	filter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	filter_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	filter_scroll.clip_contents = true
	_set_rect(filter_scroll, DeployPrepLayoutContractScript.FILTER_SCROLL)
	parchment_group.add_child(filter_scroll)
	_style_filter_scrollbar()
	filter_row = HBoxContainer.new()
	filter_row.name = "DeployFilterRow"
	filter_row.add_theme_constant_override("separation", DeployPrepLayoutContractScript.FILTER_GAP)
	filter_scroll.add_child(filter_row)
	filter_previous_button = _add_image_button(parchment_group, "DeployFilterPrevious", DeployPrepLayoutContractScript.FILTER_PREVIOUS, "‹", &"filter", func() -> void: _scroll_filters(-1), 18)
	filter_next_button = _add_image_button(parchment_group, "DeployFilterNext", DeployPrepLayoutContractScript.FILTER_NEXT, "›", &"filter", func() -> void: _scroll_filters(1), 18)
	var bar := filter_scroll.get_h_scroll_bar()
	if bar != null:
		bar.value_changed.connect(func(_value: float) -> void: _update_filter_navigation())


func _build_card_list() -> void:
	_add_image_panel(parchment_group, "DeploySelectionPane", DeployPrepLayoutContractScript.SELECTION_PANE, &"slot", &"normal", 0)
	var well := Panel.new()
	well.name = "DeployCardWell"
	well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var well_style := StyleBoxFlat.new()
	well_style.bg_color = Color(0.12, 0.075, 0.035, 0.055)
	well_style.border_color = Color(0.30, 0.20, 0.10, 0.18)
	well_style.set_border_width_all(1)
	well_style.set_corner_radius_all(3)
	well.add_theme_stylebox_override("panel", well_style)
	_set_rect(well, DeployPrepLayoutContractScript.CARD_SCROLL)
	parchment_group.add_child(well)
	card_scroll = ScrollContainer.new()
	card_scroll.name = "DeployCardScroll"
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	card_scroll.clip_contents = true
	_set_rect(card_scroll, DeployPrepLayoutContractScript.CARD_SCROLL)
	parchment_group.add_child(card_scroll)
	card_list = VBoxContainer.new()
	card_list.name = "DeployCardList"
	card_list.custom_minimum_size.x = 232
	card_list.add_theme_constant_override("separation", DeployPrepLayoutContractScript.CARD_GAP)
	card_scroll.add_child(card_list)
	result_hint_panel = Panel.new()
	result_hint_panel.name = "DeployResultHintPanel"
	result_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_hint_panel.z_index = 2
	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Color(0.035, 0.075, 0.068, 0.90)
	hint_style.border_color = Color(0.47, 0.38, 0.22, 0.72)
	hint_style.set_border_width_all(1)
	hint_style.set_corner_radius_all(2)
	result_hint_panel.add_theme_stylebox_override("panel", hint_style)
	_set_rect(result_hint_panel, DeployPrepLayoutContractScript.RESULT_HINT)
	parchment_group.add_child(result_hint_panel)
	result_hint_label = _add_label(parchment_group, "DeployResultHint", DeployPrepLayoutContractScript.RESULT_HINT, "", 13, Color(0.78, 0.72, 0.58), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 3)


func _build_warehouse_batch_controls() -> void:
	warehouse_batch_entry_button = _add_image_button(
		parchment_group,
		"DeployWarehouseBatchEntry",
		DeployPrepLayoutContractScript.WAREHOUSE_BATCH_ENTRY,
		"快捷多选售卖",
		&"action",
		_enter_warehouse_batch_sell,
		14
	)
	warehouse_batch_select_all_button = _add_image_button(
		parchment_group,
		"DeployWarehouseBatchSelectAll",
		DeployPrepLayoutContractScript.WAREHOUSE_BATCH_SELECT_ALL,
		"全选可售",
		&"action",
		_select_all_warehouse_batch_sellable,
		13
	)
	warehouse_batch_clear_button = _add_image_button(
		parchment_group,
		"DeployWarehouseBatchClear",
		DeployPrepLayoutContractScript.WAREHOUSE_BATCH_CLEAR,
		"清除",
		&"nav",
		_clear_warehouse_batch_selection,
		13
	)


func _build_map_split_view() -> void:
	map_split_view = DeployMapSplitViewScript.new() as Control
	map_split_view.name = "DeployMapSplitView"
	map_split_view.call("build", _dictionary_from(current_model.get("map_projection", {})))
	map_split_view.connect("scale_requested", _on_map_scale_requested)
	map_split_view.connect("map_requested", _on_map_requested)
	map_split_view.call("set_ui_scale_factor", ui_scale_factor)
	map_split_view.call("set_reduced_motion_enabled", reduced_motion)
	parchment_group.add_child(map_split_view)


func _build_detail_panel() -> void:
	detail_panel = _add_image_panel(parchment_group, "DeployDetailPane", DeployPrepLayoutContractScript.DETAIL_PANE, &"slot", &"normal", 1)
	_add_image_panel(parchment_group, "DeployDetailArtFrame", DeployPrepLayoutContractScript.DETAIL_ART_FRAME, &"slot", &"normal", 2)
	detail_artwork = TextureRect.new()
	detail_artwork.name = "DeployDetailArtwork"
	detail_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_artwork.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_artwork.z_index = 3
	_set_rect(detail_artwork, DeployPrepLayoutContractScript.DETAIL_ART)
	parchment_group.add_child(detail_artwork)
	detail_title_label = _add_label(parchment_group, "DeployDetailTitle", DeployPrepLayoutContractScript.DETAIL_TITLE, "", 20, Color(0.96, 0.83, 0.56), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 3)
	detail_badge_label = _add_label(parchment_group, "DeployDetailBadges", DeployPrepLayoutContractScript.DETAIL_BADGE, "", 13, Color(0.70, 0.83, 0.78), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, 3)
	detail_badge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add_image_panel(parchment_group, "DeployDetailBodyPanel", DeployPrepLayoutContractScript.DETAIL_BODY_PANEL, &"slot", &"normal", 2)
	detail_body_scroll = ScrollContainer.new()
	detail_body_scroll.name = "DeployDetailBodyScroll"
	detail_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	detail_body_scroll.focus_mode = Control.FOCUS_ALL
	detail_body_scroll.z_index = 3
	_set_rect(detail_body_scroll, Rect2(620, 282, 278, 236))
	parchment_group.add_child(detail_body_scroll)
	detail_body_content = VBoxContainer.new()
	detail_body_content.name = "DeployDetailBodyContent"
	detail_body_content.custom_minimum_size = Vector2(270, 0)
	detail_body_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_body_content.add_theme_constant_override("separation", 6)
	detail_body_scroll.add_child(detail_body_content)
	detail_description_label = _add_label(detail_body_content, "DeployDetailDescription", Rect2(0, 0, 270, 64), "", 14, Color(0.91, 0.86, 0.75), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, 0)
	detail_description_label.custom_minimum_size = Vector2(270, 64)
	detail_description_label.set_meta("deploy_scroll_content", true)
	_apply_label_flow_policy(detail_description_label)
	for index in range(DeployPrepLayoutContractScript.DETAIL_FACT_RECTS.size()):
		var rect := DeployPrepLayoutContractScript.DETAIL_FACT_RECTS[index] as Rect2
		var label := _add_label(detail_body_content, "DeployDetailFact%d" % index, Rect2(0, 0, 270, rect.size.y), "", 13, Color(0.74, 0.72, 0.64), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 0)
		label.custom_minimum_size = Vector2(270, rect.size.y)
		label.set_meta("deploy_scroll_content", true)
		_apply_label_flow_policy(label)
		detail_fact_labels.append(label)
	detail_feedback_panel = _add_image_panel(parchment_group, "DeployDetailFeedbackPanel", DeployPrepLayoutContractScript.DETAIL_FEEDBACK, &"slot", &"normal", 2)
	detail_feedback_label = _add_label(parchment_group, "DeployDetailFeedback", DeployPrepLayoutContractScript.DETAIL_FEEDBACK, "", 12, Color(0.58, 0.86, 0.80), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 3)
	detail_primary_action_button = _add_image_button(parchment_group, "DeployDetailPrimaryAction", DeployPrepLayoutContractScript.DETAIL_PRIMARY_ACTION, "", &"action", func() -> void: _on_detail_action_pressed(0), 16)
	detail_secondary_action_button = _add_image_button(parchment_group, "DeployDetailSecondaryAction", DeployPrepLayoutContractScript.DETAIL_SECONDARY_ACTION, "", &"nav", func() -> void: _on_detail_action_pressed(1), 14)

	detail_gold_panel = _add_image_panel(parchment_group, "DeployGoldPanel", DeployPrepLayoutContractScript.DETAIL_GOLD_PANEL, &"slot", &"normal", 5)
	var gold_ref := Art09ManifestAssetMappingScript.asset_ref(&"ui.common.gold_icon", &"icon.minimap.explored", &"currency", &"gold")
	detail_gold_icon = _add_texture_from_texture(parchment_group, "DeployGoldIcon", DeployPrepLayoutContractScript.DETAIL_GOLD_ICON, Art09ManifestAssetMappingScript.resolve_texture(gold_ref), 6, true)
	detail_gold_label = _add_label(parchment_group, "DeployGoldValue", DeployPrepLayoutContractScript.DETAIL_GOLD_VALUE, "—", 17, Color(0.96, 0.76, 0.36), HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_CENTER, 6)


func _build_summary_board() -> void:
	var root := _root(&"SideStatusRoot")
	summary_button_group.allow_unpress = false
	_add_texture(root, "DeploySummaryBoard", DeployPrepLayoutContractScript.SUMMARY_BOARD, &"deploy_prep.panel.summary_board", 0)
	_add_label(root, "DeploySummaryTitle", Rect2(1006, 64, 208, 34), "出发摘要", 21, Color(0.96, 0.77, 0.38), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 1)
	var tab_rect := DeployPrepLayoutContractScript.SUMMARY_TABS
	var width := tab_rect.size.x / float(SUMMARY_PAGES.size())
	for index in range(SUMMARY_PAGES.size()):
		var page := SUMMARY_PAGES[index] as Dictionary
		var page_id := StringName(page.get("id", &"overview"))
		var rect := Rect2(tab_rect.position + Vector2(index * width, 0), Vector2(width, tab_rect.size.y))
		var captured := page_id
		var button := _add_image_button(root, "DeploySummaryTab_%s" % String(page_id), rect, String(page.get("label", page_id)), &"filter", func() -> void: _show_summary_page(captured), 13)
		button.toggle_mode = true
		button.button_group = summary_button_group
		summary_buttons[page_id] = button
	summary_scroll = ScrollContainer.new()
	summary_scroll.name = "DeploySummaryScroll"
	summary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	summary_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	summary_scroll.focus_mode = Control.FOCUS_ALL
	summary_scroll.z_index = 1
	_set_rect(summary_scroll, DeployPrepLayoutContractScript.SUMMARY_BODY)
	root.add_child(summary_scroll)
	summary_scroll_content = VBoxContainer.new()
	summary_scroll_content.name = "DeploySummaryScrollContent"
	summary_scroll_content.custom_minimum_size = Vector2(208, 0)
	summary_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_scroll_content.add_theme_constant_override("separation", 4)
	summary_scroll.add_child(summary_scroll_content)
	for index in range(SUMMARY_INITIAL_ROWS):
		_append_summary_row(index)
	_add_image_panel(root, "DeploySummaryMessagePanel", DeployPrepLayoutContractScript.SUMMARY_MESSAGE_PANEL, &"slot", &"normal", 1)
	summary_message_label = _add_label(root, "DeploySummaryMessage", DeployPrepLayoutContractScript.SUMMARY_MESSAGE, "", 13, Color(0.56, 0.87, 0.83), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 2)
	summary_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_message_label.clip_text = true


func _build_primary_actions() -> void:
	var root := _root(&"PrimaryActionRoot")
	primary_action_button = _add_image_button(root, "DeployPrimaryAction", DeployPrepLayoutContractScript.PRIMARY_ACTION, "确认出发", &"action", _on_primary_action_pressed, 22)
	cancel_action_button = _add_image_button(root, "DeployCancelAction", DeployPrepLayoutContractScript.CANCEL_ACTION, "取消当前探索", &"danger", _show_cancel_modal, 16)
	cancel_action_button.visible = false


func _build_cancel_modal() -> void:
	var root := _root(&"ModalRoot")
	modal_layer = Control.new()
	modal_layer.name = "DeployCancelModal"
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.visible = false
	root.add_child(modal_layer)
	var scrim := _add_color_rect(modal_layer, "DeployCancelModalScrim", Rect2(0, 0, 1280, 720), Color(0.01, 0.015, 0.02, 0.76))
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_add_texture(modal_layer, "DeployCancelModalBoard", DeployPrepLayoutContractScript.MODAL_BOARD, &"deploy_prep.panel.modal_board", 1)
	_add_label(modal_layer, "DeployCancelModalTitle", DeployPrepLayoutContractScript.MODAL_TITLE, "取消当前探索", 26, Color(0.97, 0.72, 0.38), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 2)
	var body := _add_label(modal_layer, "DeployCancelModalBody", DeployPrepLayoutContractScript.MODAL_BODY, "放弃后，本局黑色资源与全部物品都会失去；已直接获得的金色资源保留。\n该操作不可撤销。", 16, Color(0.94, 0.88, 0.76), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 2)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_confirm_button = _add_image_button(modal_layer, "DeployCancelModalConfirm", DeployPrepLayoutContractScript.MODAL_CONFIRM, "确认放弃", &"danger", _confirm_cancel_active_run, 16)
	modal_confirm_button.disabled = false
	_apply_image_button_surface(modal_confirm_button, &"danger", &"normal")
	modal_cancel_button = _add_image_button(modal_layer, "DeployCancelModalBack", DeployPrepLayoutContractScript.MODAL_CANCEL, "返回", &"nav", _hide_cancel_modal, 16)


func _build_warehouse_batch_confirm_modal() -> void:
	var root := _root(&"ModalRoot")
	warehouse_batch_modal_layer = Control.new()
	warehouse_batch_modal_layer.name = "DeployWarehouseBatchSellModal"
	warehouse_batch_modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	warehouse_batch_modal_layer.visible = false
	root.add_child(warehouse_batch_modal_layer)
	var scrim := _add_color_rect(
		warehouse_batch_modal_layer,
		"DeployWarehouseBatchSellScrim",
		Rect2(0, 0, 1280, 720),
		Color(0.01, 0.015, 0.02, 0.76)
	)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_add_texture(warehouse_batch_modal_layer, "DeployWarehouseBatchSellBoard", DeployPrepLayoutContractScript.MODAL_BOARD, &"deploy_prep.panel.modal_board", 1)
	_add_label(warehouse_batch_modal_layer, "DeployWarehouseBatchSellTitle", DeployPrepLayoutContractScript.MODAL_TITLE, "确认批量售卖", 26, Color(0.97, 0.72, 0.38), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 2)
	warehouse_batch_modal_body = _add_label(
		warehouse_batch_modal_layer,
		"DeployWarehouseBatchSellBody",
		DeployPrepLayoutContractScript.MODAL_BODY,
		"",
		16,
		Color(0.94, 0.88, 0.76),
		HORIZONTAL_ALIGNMENT_CENTER,
		VERTICAL_ALIGNMENT_CENTER,
		2
	)
	warehouse_batch_modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warehouse_batch_modal_confirm_button = _add_image_button(
		warehouse_batch_modal_layer,
		"DeployWarehouseBatchSellConfirm",
		DeployPrepLayoutContractScript.MODAL_CONFIRM,
		"确认出售",
		&"danger",
		_confirm_warehouse_batch_sell,
		16
	)
	warehouse_batch_modal_cancel_button = _add_image_button(
		warehouse_batch_modal_layer,
		"DeployWarehouseBatchSellBack",
		DeployPrepLayoutContractScript.MODAL_CANCEL,
		"返回检查",
		&"nav",
		_hide_warehouse_batch_confirmation,
		16
	)


func _refresh_all(rebuild_lists: bool) -> void:
	if current_model.is_empty() or parchment_group == null:
		return
	_sanitize_warehouse_batch_selection()
	_refresh_tab_buttons()
	var map_active := _active_tab() == DeployTabModelScript.TAB_MAP
	if map_active:
		_clear_generic_selection()
	elif rebuild_lists:
		_rebuild_filters()
		_rebuild_cards()
	else:
		_refresh_filter_buttons()
		_refresh_card_selection()
	_refresh_map_workspace()
	_refresh_wallet()
	_refresh_warehouse_batch_controls()
	_refresh_detail_projection()
	_refresh_workspace_visibility(map_active)
	_refresh_summary()
	_refresh_actions()
	_refresh_modal_state()
	_wire_focus_neighbors()


func _clear_generic_selection() -> void:
	_clear_container(filter_row)
	filter_buttons.clear()
	_clear_container(card_list)
	card_views.clear()
	if result_hint_panel != null:
		result_hint_panel.visible = false
	if result_hint_label != null:
		result_hint_label.visible = false


func _refresh_workspace_visibility(map_active: bool) -> void:
	for node in [
		filter_scroll,
		card_scroll,
		get_node_or_null("MainContentRoot/DeployParchmentGroup/DeploySelectionPane"),
		get_node_or_null("MainContentRoot/DeployParchmentGroup/DeployCardWell"),
	]:
		if node is CanvasItem:
			(node as CanvasItem).visible = not map_active
	if map_active:
		for node in [filter_previous_button, filter_next_button, result_hint_panel, result_hint_label]:
			if node is CanvasItem:
				(node as CanvasItem).visible = false
	else:
		_update_filter_navigation()
	if map_split_view != null:
		map_split_view.call("set_active", map_active and page_active)
	if map_active:
		for node in _generic_detail_nodes():
			if node != null:
				node.visible = false
	else:
		for node in [
			detail_panel,
			get_node_or_null("MainContentRoot/DeployParchmentGroup/DeployDetailBodyPanel"),
			get_node_or_null("MainContentRoot/DeployParchmentGroup/DeployDetailArtFrame"),
			detail_body_scroll,
			detail_artwork,
			detail_title_label,
			detail_badge_label,
			detail_description_label,
		]:
			if node is CanvasItem:
				(node as CanvasItem).visible = true
		for label in detail_fact_labels:
			if label != null:
				label.visible = true
	var transaction_context := _transaction_context_active()
	if detail_gold_panel != null:
		detail_gold_panel.visible = transaction_context
	if detail_gold_icon != null:
		detail_gold_icon.visible = transaction_context
	if detail_gold_label != null:
		detail_gold_label.visible = transaction_context


func _transaction_context_active() -> bool:
	if _active_tab() == DeployTabModelScript.TAB_CLAIM:
		return true
	if _active_tab() != DeployTabModelScript.TAB_WAREHOUSE:
		return false
	if warehouse_batch_active:
		return true
	var row := _dictionary_from(current_model.get("selected_card_detail", {}))
	return bool(row.get("batch_sell_eligible", false))


func _generic_detail_nodes() -> Array[CanvasItem]:
	var result: Array[CanvasItem] = []
	for node in [
		detail_panel,
		get_node_or_null("MainContentRoot/DeployParchmentGroup/DeployDetailBodyPanel"),
		get_node_or_null("MainContentRoot/DeployParchmentGroup/DeployDetailArtFrame"),
		detail_body_scroll,
		detail_artwork,
		detail_title_label,
		detail_badge_label,
		detail_description_label,
		detail_feedback_panel,
		detail_feedback_label,
		detail_primary_action_button,
		detail_secondary_action_button,
	]:
		if node is CanvasItem:
			result.append(node as CanvasItem)
	for label in detail_fact_labels:
		if label != null:
			result.append(label)
	return result


func _refresh_map_workspace() -> void:
	if map_split_view == null:
		return
	map_split_view.call("set_reduced_motion_enabled", reduced_motion)
	map_split_view.call("set_ui_scale_factor", ui_scale_factor)
	map_split_view.call("apply_projection", _dictionary_from(current_model.get("map_projection", {})))


func _refresh_wallet() -> void:
	if detail_gold_label == null:
		return
	var wallet := _dictionary_from(current_model.get("wallet_projection", {}))
	var available := bool(wallet.get("available", false))
	var display := str(wallet.get("display", "—")) if available else "—"
	detail_gold_label.text = "%s 金币" % display
	detail_gold_label.tooltip_text = str(wallet.get("display_text", "金币 —"))
	_apply_scaled_control_font(detail_gold_label)


func _refresh_warehouse_batch_controls() -> void:
	var warehouse_tab := _active_tab() == DeployTabModelScript.TAB_WAREHOUSE
	var transaction_pending := not pending_meta_action.is_empty()
	if card_scroll != null:
		_set_rect(
			card_scroll,
			DeployPrepLayoutContractScript.WAREHOUSE_CARD_SCROLL
			if warehouse_tab
			else DeployPrepLayoutContractScript.CARD_SCROLL
		)
	if warehouse_batch_entry_button != null:
		warehouse_batch_entry_button.visible = warehouse_tab and not warehouse_batch_active
		warehouse_batch_entry_button.disabled = _has_active_run() or transaction_pending
		warehouse_batch_entry_button.tooltip_text = (
			"探索进行中，仓库交易暂不可用"
			if _has_active_run()
			else ("正在等待上一项基地操作" if transaction_pending else "进入逐项勾选与批量售卖")
		)
		_apply_image_button_surface(warehouse_batch_entry_button, &"action", &"disabled" if warehouse_batch_entry_button.disabled else &"normal")
	var projection := _warehouse_batch_projection()
	if warehouse_batch_select_all_button != null:
		warehouse_batch_select_all_button.visible = warehouse_tab and warehouse_batch_active
		warehouse_batch_select_all_button.disabled = transaction_pending or int(projection.get("eligible_count", 0)) == 0
		warehouse_batch_select_all_button.tooltip_text = "选择仓库内全部可售且未出勤的物品"
		_apply_image_button_surface(warehouse_batch_select_all_button, &"action", &"disabled" if warehouse_batch_select_all_button.disabled else &"normal")
	if warehouse_batch_clear_button != null:
		warehouse_batch_clear_button.visible = warehouse_tab and warehouse_batch_active
		warehouse_batch_clear_button.disabled = transaction_pending or warehouse_batch_selected_ids.is_empty()
		warehouse_batch_clear_button.tooltip_text = "清除当前全部勾选"
		_apply_image_button_surface(warehouse_batch_clear_button, &"nav", &"disabled" if warehouse_batch_clear_button.disabled else &"normal")
	_apply_warehouse_batch_card_states()


func _refresh_detail_projection() -> void:
	if detail_title_label == null:
		return
	if _active_tab() == DeployTabModelScript.TAB_WAREHOUSE and warehouse_batch_active:
		_refresh_warehouse_batch_detail_projection()
		return
	var detail := _dictionary_from(current_model.get("detail_projection", {}))
	var empty := bool(detail.get("empty", detail.is_empty()))
	_refresh_detail_artwork(empty)
	detail_title_label.text = str(detail.get("title", "暂无可查看内容"))
	var badges := PackedStringArray()
	for value in [detail.get("rarity_label", ""), detail.get("subtitle", ""), _player_detail_state(StringName(detail.get("state", &"")))]:
		var text_value := Art10UISkinKitScript.sanitize_player_copy(str(value)).strip_edges()
		if not text_value.is_empty() and not badges.has(text_value):
			badges.append(text_value)
	detail_badge_label.text = " · ".join(badges)
	detail_description_label.text = Art10UISkinKitScript.sanitize_player_copy(str(detail.get("description", "")))
	_resize_scroll_label(detail_description_label, 64.0, 18)
	var facts := _array_from(detail, "facts")
	for index in range(detail_fact_labels.size()):
		var fact_label := detail_fact_labels[index]
		if index >= facts.size():
			fact_label.text = ""
			fact_label.visible = false
			continue
		fact_label.visible = true
		var fact := _dictionary_from(facts[index])
		var fact_name := Art10UISkinKitScript.sanitize_player_copy(str(fact.get("label", ""))).strip_edges()
		var fact_value := Art10UISkinKitScript.sanitize_player_copy(str(fact.get("value", ""))).strip_edges()
		fact_label.text = "%s  %s" % [fact_name, fact_value] if not fact_name.is_empty() else fact_value
		_resize_scroll_label(fact_label, 34.0, 20)
	var projected_actions: Array[Dictionary] = []
	for raw_action in _array_from(detail, "actions"):
		var action := _dictionary_from(raw_action)
		if not action.is_empty():
			projected_actions.append(action)
	detail_actions = _detail_actions_for_display(projected_actions)
	_refresh_detail_action_button(detail_primary_action_button, 0, &"action")
	_refresh_detail_action_button(detail_secondary_action_button, 1, &"nav")
	var message := Art10UISkinKitScript.short_summary(str(current_model.get("action_message", "")), 34)
	var show_feedback := not message.is_empty()
	detail_feedback_panel.visible = show_feedback and _active_tab() != DeployTabModelScript.TAB_MAP
	detail_feedback_label.visible = show_feedback and _active_tab() != DeployTabModelScript.TAB_MAP
	detail_feedback_label.text = message
	if empty:
		detail_description_label.text = ""
	_refit_detail_controls()


func _refresh_warehouse_batch_detail_projection() -> void:
	var projection := _warehouse_batch_projection()
	if detail_artwork != null:
		detail_artwork.texture = null
	detail_title_label.text = "快捷多选售卖"
	detail_badge_label.text = "已选 %d 件 · 预计 %d 金币" % [
		int(projection.get("selected_count", 0)),
		int(projection.get("total_value", 0)),
	]
	detail_description_label.text = "逐项点击左侧物品进行勾选。当前出勤、唯一物品与不可售物不会加入交易；确认后整批一次提交。"
	var fact_values := [
		"可售且未出勤  %d 件" % int(projection.get("eligible_count", 0)),
		"已勾选  %d 件" % int(projection.get("selected_count", 0)),
		"预计获得  %d 金币" % int(projection.get("total_value", 0)),
		"事务规则  全部成功或全部不变",
	]
	for index in range(detail_fact_labels.size()):
		detail_fact_labels[index].text = fact_values[index] if index < fact_values.size() else ""
		detail_fact_labels[index].visible = index < fact_values.size()
		if index < fact_values.size():
			_resize_scroll_label(detail_fact_labels[index], 34.0, 20)
	_resize_scroll_label(detail_description_label, 64.0, 18)
	var selected_count := int(projection.get("selected_count", 0))
	var transaction_pending := not pending_meta_action.is_empty()
	detail_actions = [
		{
			"id": &"confirm_batch_sell",
			"label": "确认售卖",
			"enabled": selected_count > 0 and not transaction_pending,
			"destructive": true,
			"requires_confirm": true,
			"reason_code": &"empty_batch" if selected_count == 0 else (&"transaction_pending" if transaction_pending else &"ok"),
			"payload": {},
		},
		{
			"id": &"cancel_batch_sell",
			"label": "取消多选",
			"enabled": not transaction_pending,
			"destructive": false,
			"requires_confirm": false,
			"reason_code": &"transaction_pending" if transaction_pending else &"ok",
			"payload": {},
		},
	]
	_refresh_detail_action_button(detail_primary_action_button, 0, &"danger")
	_refresh_detail_action_button(detail_secondary_action_button, 1, &"nav")
	var message := Art10UISkinKitScript.short_summary(warehouse_batch_feedback, 38)
	detail_feedback_panel.visible = not message.is_empty()
	detail_feedback_label.visible = not message.is_empty()
	detail_feedback_label.text = message
	_refit_detail_controls()


func get_warehouse_batch_snapshot() -> Dictionary:
	var projection := _warehouse_batch_projection()
	projection["active"] = warehouse_batch_active
	projection["selected_instance_ids"] = warehouse_batch_selected_ids.duplicate()
	projection["confirmation_visible"] = warehouse_batch_modal_layer != null and warehouse_batch_modal_layer.visible
	projection["pending"] = not pending_meta_action.is_empty() and StringName(pending_meta_action.get("action", &"")) == &"sell_collectibles_batch"
	projection["feedback"] = warehouse_batch_feedback
	return projection


func _warehouse_batch_projection() -> Dictionary:
	var selected_lookup := {}
	for instance_id in warehouse_batch_selected_ids:
		selected_lookup[instance_id] = true
	var eligible_ids: Array[String] = []
	var selected_items: Array[Dictionary] = []
	var reason_counts := {}
	var total_value := 0
	for row in _all_warehouse_rows():
		var eligible := bool(row.get("batch_sell_eligible", false))
		var row_instance_ids := _normalized_string_ids(
			row.get("instance_ids", [row.get("instance_id", "")])
		)
		for instance_id in row_instance_ids:
			if eligible:
				eligible_ids.append(instance_id)
			else:
				var reason_code := StringName(row.get("batch_sell_reason_code", &"item_not_sellable"))
				reason_counts[reason_code] = int(reason_counts.get(reason_code, 0)) + 1
			if selected_lookup.has(instance_id):
				var selected_item := row.duplicate(true)
				selected_item["instance_id"] = instance_id
				selected_items.append(selected_item)
				total_value += maxi(0, int(row.get("value", 0)))
	eligible_ids.sort()
	return {
		"atomicity": &"all_or_nothing",
		"eligible_instance_ids": eligible_ids,
		"eligible_count": eligible_ids.size(),
		"selected_count": selected_items.size(),
		"selected_items": selected_items,
		"total_value": total_value,
		"reason_counts": reason_counts,
	}


func _all_warehouse_rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if current_model.is_empty() or _active_tab() != DeployTabModelScript.TAB_WAREHOUSE:
		return result
	var all_model := DeployPrepModelScript.model_with_filter(current_model, DeployTabModelScript.FILTER_ALL)
	for raw_row in _array_from(all_model, "selection_rows"):
		var row := _dictionary_from(raw_row)
		if StringName(row.get("detail_kind", &"")) == &"warehouse_item":
			result.append(row)
	return result


func _warehouse_row_for_instance(instance_id: String) -> Dictionary:
	for row in _all_warehouse_rows():
		if _normalized_string_ids(
			row.get("instance_ids", [row.get("instance_id", "")])
		).has(instance_id):
			return row
	return {}


func _row_for_card_id(card_id: StringName) -> Dictionary:
	for raw_row in _array_from(current_model, "selection_rows"):
		var row := _dictionary_from(raw_row)
		if StringName(row.get("id", &"")) == card_id:
			return row
	return {}


func _sanitize_warehouse_batch_selection() -> void:
	if not warehouse_batch_active:
		return
	var eligible_lookup := {}
	for row in _all_warehouse_rows():
		if bool(row.get("batch_sell_eligible", false)):
			for instance_id in _normalized_string_ids(
				row.get("instance_ids", [row.get("instance_id", "")])
			):
				eligible_lookup[instance_id] = true
	var retained: Array[String] = []
	for instance_id in warehouse_batch_selected_ids:
		if eligible_lookup.has(instance_id) and not retained.has(instance_id):
			retained.append(instance_id)
	retained.sort()
	warehouse_batch_selected_ids = retained


func _apply_warehouse_batch_card_states() -> void:
	var batch_visible := warehouse_batch_active and _active_tab() == DeployTabModelScript.TAB_WAREHOUSE
	for view in card_views:
		if view == null or not is_instance_valid(view):
			continue
		var row := _dictionary_from(view.get("card_data"))
		var instance_ids := _normalized_string_ids(
			row.get("instance_ids", [row.get("instance_id", "")])
		)
		var checked_count := 0
		for instance_id in instance_ids:
			if warehouse_batch_selected_ids.has(instance_id):
				checked_count += 1
		view.call(
			"apply_batch_selection",
			batch_visible,
			checked_count > 0,
			bool(row.get("batch_sell_eligible", false)),
			str(row.get("batch_sell_reason", "该物品不可出售"))
		)
		if bool(row.get("quantity_capable", false)):
			var quantity_enabled := (
				bool(row.get("batch_sell_eligible", false))
				if batch_visible
				else bool(row.get("quantity_enabled", true))
			)
			view.call(
				"apply_quantity_state",
				&"sale" if batch_visible else StringName(row.get("quantity_mode", &"none")),
				checked_count if batch_visible else int(row.get("quantity_current", 0)),
				(
					instance_ids.size()
					if batch_visible and bool(row.get("batch_sell_eligible", false))
					else int(row.get("quantity_limit", instance_ids.size()))
				),
				quantity_enabled and pending_meta_action.is_empty(),
				str(row.get("quantity_category", row.get("category", "物品")))
			)


func _refresh_detail_artwork(empty: bool) -> void:
	if detail_artwork == null:
		return
	if empty:
		detail_artwork.texture = null
		return
	var row := _dictionary_from(current_model.get("selected_card_detail", {}))
	var card_id := StringName(row.get("id", current_model.get("selected_card", &"")))
	var art_ref: Dictionary
	if row.has("item_id"):
		art_ref = Art09ManifestAssetMappingScript.inventory_item_icon_ref(row)
	elif Art25ContentAssetContractScript.handles_deploy_card(card_id):
		art_ref = Art25ContentAssetContractScript.deploy_card_ref(card_id)
	else:
		art_ref = Art22DeployPrepAssetContractScript.card_art_ref(_active_tab(), card_id, StringName(row.get("art_filter_id", row.get("filter_id", &""))))
	detail_artwork.texture = Art09ManifestAssetMappingScript.resolve_texture(art_ref)


func _player_detail_state(state: StringName) -> String:
	var value := String(state).to_lower()
	if value in ["selected", "configured"]: return "已选择"
	if value == "owned": return "已拥有"
	if value in ["ready", "minimal_real", "valid"]: return "可用"
	if value.find("lock") >= 0: return "未解锁"
	if value.find("unaffordable") >= 0: return "金币不足"
	if value.find("over") >= 0: return "已超限"
	return ""


func _detail_actions_for_display(projected_actions: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action in projected_actions:
		if bool(action.get("enabled", false)) and not bool(action.get("destructive", false)):
			result.append(action)
			break
	for action in projected_actions:
		if bool(action.get("destructive", false)):
			result.append(action)
			break
	for action in projected_actions:
		if result.size() >= 2:
			break
		if not result.has(action):
			result.append(action)
	return result


func _refresh_detail_action_button(button: Button, index: int, control_id: StringName) -> void:
	if button == null:
		return
	if index >= detail_actions.size():
		button.visible = false
		button.disabled = true
		return
	var action := detail_actions[index]
	var action_id := StringName(action.get("id", action.get("action", &"")))
	var meta_blocked := not pending_meta_action.is_empty() and action_id in META_DETAIL_ACTION_IDS
	var enabled := bool(action.get("enabled", false)) and not meta_blocked
	button.visible = true
	button.disabled = not enabled
	button.text = "处理中…" if meta_blocked and _pending_matches_detail_action(action_id) else str(action.get("label", "查看"))
	button.tooltip_text = "正在等待基地确认" if meta_blocked else _detail_action_reason(action)
	_apply_image_button_surface(button, &"danger" if bool(action.get("destructive", false)) else control_id, &"normal" if enabled else &"disabled")


func _detail_action_reason(action: Dictionary) -> String:
	if bool(action.get("enabled", false)):
		return "需要确认" if bool(action.get("requires_confirm", false)) else ""
	match StringName(action.get("reason_code", &"")):
		&"active_run_locked": return "探索进行中，本局配置不可更改"
		&"already_selected": return "当前已采用"
		&"map_locked", &"claim_locked": return "尚未解锁"
		&"insufficient_gold": return "金币不足"
		&"balance_unavailable": return "金币余额暂不可用"
		&"remove_from_attendance_first": return "请先移出出勤"
		&"configured_item_blocked": return "当前出勤项不可出售，请先移出出勤"
		&"unique_item": return "唯一物品不可出售"
		&"item_not_sellable": return "该物品不可出售"
		&"empty_batch": return "请先勾选至少一件可售物品"
		&"transaction_pending": return "上一项基地操作仍在确认"
		&"only_available_in_run": return "只能在探索中使用"
		&"supply_slots_full": return "携带栏已满"
	return "当前不可操作"


func _pending_matches_detail_action(action_id: StringName) -> bool:
	var pending_action := StringName(pending_meta_action.get("action", &""))
	return (
		(action_id == &"purchase" and pending_action == &"purchase")
		or (action_id == &"sell" and pending_action == &"sell_collectible")
		or (action_id == &"confirm_batch_sell" and pending_action == &"sell_collectibles_batch")
	)


func _refresh_tab_buttons() -> void:
	var active := _active_tab()
	for raw_id in tab_buttons.keys():
		var tab_id := StringName(raw_id)
		var button := tab_buttons[tab_id] as Button
		if button == null:
			continue
		var selected := tab_id == active
		button.set_pressed_no_signal(selected)
		_apply_image_button_surface(button, &"tab", &"selected" if selected else &"normal")


func _rebuild_filters() -> void:
	var previous_scroll := filter_scroll.scroll_horizontal if filter_scroll != null else 0
	if filter_scroll != null:
		_set_rect(filter_scroll, DeployPrepLayoutContractScript.FILTER_SCROLL)
	_clear_container(filter_row)
	filter_buttons.clear()
	filter_button_group = ButtonGroup.new()
	filter_button_group.allow_unpress = false
	var tab := _dictionary_from(current_model.get("active_tab_data", {}))
	var filters := _array_from(tab, "secondary_filters")
	var fitted_width := 0.0
	if not filters.is_empty() and filters.size() <= 5:
		fitted_width = floor((DeployPrepLayoutContractScript.FILTER_SCROLL.size.x - float((filters.size() - 1) * DeployPrepLayoutContractScript.FILTER_GAP)) / float(filters.size()))
	for raw_filter in filters:
		var filter := _dictionary_from(raw_filter)
		var filter_id := StringName(filter.get("id", DeployTabModelScript.FILTER_ALL))
		var filter_label := String(filter.get("label", filter_id))
		var captured := filter_id
		var resolved_width := fitted_width if fitted_width > 0.0 else _long_filter_width(filter_label)
		var button := _add_container_image_button(filter_row, "DeployFilter_%s" % String(filter_id), Vector2(resolved_width, 34), filter_label, &"filter", func() -> void: _on_filter_pressed(captured), 12)
		button.toggle_mode = true
		button.button_group = filter_button_group
		button.focus_entered.connect(func() -> void: _ensure_filter_visible(button))
		filter_buttons[filter_id] = button
	_refresh_filter_buttons()
	call_deferred("_restore_filter_scroll", previous_scroll)
	call_deferred("_update_filter_navigation")


func _refresh_filter_buttons() -> void:
	var selected_filter := StringName(current_model.get("selected_filter", DeployTabModelScript.FILTER_ALL))
	for raw_id in filter_buttons.keys():
		var filter_id := StringName(raw_id)
		var button := filter_buttons[filter_id] as Button
		if button == null:
			continue
		var selected := filter_id == selected_filter
		button.set_pressed_no_signal(selected)
		_apply_image_button_surface(button, &"filter", &"selected" if selected else &"normal")


func _rebuild_cards() -> void:
	var active := _active_tab()
	var selected_card := StringName(current_model.get("selected_card", &""))
	var target_scroll := _stored_scroll_for(active)
	_clear_container(card_list)
	card_views.clear()
	for raw_card in _array_from(current_model, "selection_rows"):
		var card := _dictionary_from(raw_card)
		var card_id := StringName(card.get("id", &""))
		var view := DeployPrepCardViewScript.new() as Control
		view.name = "DeployCard_%s" % String(card_id)
		card_list.add_child(view)
		view.call("setup", card, active, card_id == selected_card)
		view.call("set_ui_scale_factor", ui_scale_factor)
		view.connect("card_pressed", _on_card_pressed)
		view.connect("quantity_delta_requested", _on_card_quantity_delta_requested)
		card_views.append(view)
	if result_hint_panel != null and result_hint_label != null:
		var show_hint := card_views.is_empty()
		result_hint_panel.visible = show_hint
		result_hint_label.visible = show_hint
		result_hint_label.text = str(_dictionary_from(current_model.get("active_tab_data", {})).get("empty_state", "暂无内容"))
	call_deferred("_restore_card_scroll", target_scroll)


func _refresh_card_selection() -> void:
	var selected_card := StringName(current_model.get("selected_card", &""))
	for view in card_views:
		if view == null or not is_instance_valid(view):
			continue
		view.call("apply_selected", StringName(view.get("card_id")) == selected_card)


func _refresh_summary() -> void:
	for raw_id in summary_buttons.keys():
		var page_id := StringName(raw_id)
		var button := summary_buttons[page_id] as Button
		var selected := page_id == active_summary_page
		button.set_pressed_no_signal(selected)
		_apply_image_button_surface(button, &"filter", &"selected" if selected else &"normal")
	var blocks := _summary_page_blocks(active_summary_page)
	_ensure_summary_row_count(blocks.size())
	for index in range(summary_row_labels.size()):
		var row_label := summary_row_labels[index]
		var full_text := String(blocks[index]) if index < blocks.size() else ""
		var show_row := not full_text.is_empty()
		row_label.text = full_text
		row_label.tooltip_text = full_text
		row_label.visible = show_row
		var row_panel := row_label.get_meta("deploy_summary_row_panel") as CanvasItem
		if row_panel != null:
			row_panel.visible = show_row
		_apply_scaled_control_font(row_label)
		_resize_scroll_label(row_label, 34.0, 18)
		var label_height := row_label.custom_minimum_size.y
		_set_rect(row_label, Rect2(8, 6, 192, label_height))
		if row_panel is Control:
			(row_panel as Control).custom_minimum_size = Vector2(208, label_height + 12.0)
	if summary_message_label != null:
		var full_message := Art10UISkinKitScript.sanitize_player_copy(String(current_model.get("action_message", ""))).strip_edges()
		var message := Art10UISkinKitScript.short_summary(full_message, _summary_message_budget())
		summary_message_label.text = message
		summary_message_label.tooltip_text = full_message
		_apply_scaled_control_font(summary_message_label)
		summary_message_label.visible = not message.is_empty()
		var message_panel := get_node_or_null("SideStatusRoot/DeploySummaryMessagePanel") as CanvasItem
		if message_panel != null:
			message_panel.visible = not message.is_empty()


func _refresh_actions() -> void:
	var active_run := _has_active_run()
	if primary_action_button != null:
		primary_action_button.text = "继续探索" if active_run else "确认出发"
		primary_action_button.disabled = false
		_apply_image_button_surface(primary_action_button, &"action", &"normal")
	if cancel_action_button != null:
		cancel_action_button.visible = active_run
		cancel_action_button.disabled = false
		_apply_image_button_surface(cancel_action_button, &"danger", &"normal")


func _refresh_modal_state() -> void:
	if modal_layer == null:
		return
	var should_show := bool(current_model.get("abandon_confirm_visible", false)) and _has_active_run()
	if should_show and not modal_layer.visible:
		_show_cancel_modal_visual()
	elif not should_show and modal_layer.visible:
		_hide_cancel_modal_visual()


func _show_summary_page(page_id: StringName) -> void:
	active_summary_page = page_id
	_refresh_summary()
	var button := summary_buttons.get(page_id) as Button
	if button != null and not reduced_motion:
		Art10UISkinKitScript.play_feedback_pulse(button, &"success", 0.30)


func _on_filter_pressed(filter_id: StringName) -> void:
	_save_active_view_state()
	current_model = DeployPrepModelScript.model_with_filter(current_model, filter_id)
	var state := _state_for_tab(_active_tab())
	state["filter"] = filter_id
	state["card"] = StringName(current_model.get("selected_card", &""))
	state["scroll"] = 0
	view_state_by_tab[String(_active_tab())] = state
	# Keep the filter row alive while its pressed/focus event is being dispatched.
	# Rebuilding the clicked button here can leave the replacement in a blank or
	# visually unpressed state after the old button receives button-up.
	_refresh_tab_buttons()
	_refresh_filter_buttons()
	_rebuild_cards()
	_refresh_summary()
	_refresh_actions()
	_refresh_modal_state()
	_wire_focus_neighbors()
	if not reduced_motion and card_scroll != null:
		Art10UISkinKitScript.play_panel_open(card_scroll)
	call_deferred("_focus_active_filter")


func _on_card_pressed(card_id: StringName) -> void:
	var scroll_value := card_scroll.scroll_vertical if card_scroll != null else 0
	if warehouse_batch_active and _active_tab() == DeployTabModelScript.TAB_WAREHOUSE:
		var instance_id := String(card_id).trim_prefix("m3r_")
		_toggle_warehouse_batch_item(instance_id)
		if card_scroll != null:
			card_scroll.scroll_vertical = scroll_value
		return
	current_model = DeployPrepModelScript.model_with_card(current_model, card_id)
	var state := _state_for_tab(_active_tab())
	state["card"] = card_id
	state["scroll"] = scroll_value
	view_state_by_tab[String(_active_tab())] = state
	_refresh_all(false)
	for view in card_views:
		if view != null and is_instance_valid(view) and StringName(view.get("card_id")) == card_id:
			if not reduced_motion:
				Art10UISkinKitScript.play_feedback_pulse(view, &"success", 0.22)
			break
	if card_scroll != null:
		card_scroll.scroll_vertical = scroll_value


func _on_card_quantity_delta_requested(card_id: StringName, delta: int) -> void:
	if delta == 0 or not pending_meta_action.is_empty():
		return
	var row := _row_for_card_id(card_id)
	if row.is_empty():
		return
	if warehouse_batch_active and _active_tab() == DeployTabModelScript.TAB_WAREHOUSE:
		_adjust_warehouse_batch_stack(row, delta)
		return
	var result := {}
	match _active_tab():
		DeployTabModelScript.TAB_WAREHOUSE:
			result = DeployConfigScript.adjust_warehouse_stack_quantity(
				_config(),
				_array_from(row.get("instance_ids", [row.get("instance_id", "")])),
				delta
			)
		DeployTabModelScript.TAB_CLAIM:
			if StringName(row.get("quantity_mode", &"")) == &"purchase":
				result = DeployConfigScript.adjust_purchase_quantity(
					_config(),
					str(row.get("item_id", "")),
					delta
				)
	if result.is_empty():
		return
	current_model = DeployPrepModelScript.model_with_config(
		current_model,
		_dictionary_from(result.get("config", _config())),
		card_id,
		str(result.get("message", ""))
	)
	_refresh_all(bool(result.get("changed", false)))


func _adjust_warehouse_batch_stack(row: Dictionary, delta: int) -> void:
	var instance_ids := _normalized_string_ids(
		row.get("instance_ids", [row.get("instance_id", "")])
	)
	var target_id := ""
	if delta > 0:
		for instance_id in instance_ids:
			if (
				bool(row.get("batch_sell_eligible", false))
				and not warehouse_batch_selected_ids.has(instance_id)
			):
				target_id = instance_id
				break
	else:
		for index in range(instance_ids.size() - 1, -1, -1):
			if warehouse_batch_selected_ids.has(instance_ids[index]):
				target_id = instance_ids[index]
				break
	if target_id.is_empty():
		warehouse_batch_feedback = "数量已达到当前可售边界。"
		_refresh_all(false)
		return
	_toggle_warehouse_batch_item(target_id)


func _enter_warehouse_batch_sell() -> void:
	if _active_tab() != DeployTabModelScript.TAB_WAREHOUSE:
		return
	if _has_active_run():
		warehouse_batch_feedback = "探索进行中，仓库交易暂不可用。"
		current_model = DeployPrepModelScript.model_with_action_message(current_model, warehouse_batch_feedback)
		_refresh_all(false)
		return
	if not pending_meta_action.is_empty():
		warehouse_batch_feedback = "上一项基地操作仍在确认，请稍候。"
		current_model = DeployPrepModelScript.model_with_action_message(current_model, warehouse_batch_feedback)
		_refresh_all(false)
		return
	warehouse_batch_active = true
	warehouse_batch_selected_ids.clear()
	warehouse_batch_feedback = "点击物品逐项勾选，或使用“全选可售”。"
	current_model = DeployPrepModelScript.model_with_action_message(current_model, warehouse_batch_feedback)
	_refresh_all(false)


func _select_all_warehouse_batch_sellable() -> void:
	if not warehouse_batch_active or not pending_meta_action.is_empty():
		return
	warehouse_batch_selected_ids.clear()
	for raw_instance_id in _array_from(_warehouse_batch_projection(), "eligible_instance_ids"):
		warehouse_batch_selected_ids.append(str(raw_instance_id))
	warehouse_batch_feedback = (
		"已选择全部 %d 件可售物品。" % warehouse_batch_selected_ids.size()
		if not warehouse_batch_selected_ids.is_empty()
		else "当前没有可售且未出勤的物品。"
	)
	_refresh_all(false)


func _clear_warehouse_batch_selection() -> void:
	if not warehouse_batch_active or not pending_meta_action.is_empty():
		return
	warehouse_batch_selected_ids.clear()
	warehouse_batch_feedback = "已清除全部勾选。"
	_refresh_all(false)


func _toggle_warehouse_batch_item(instance_id: String) -> void:
	if not warehouse_batch_active or not pending_meta_action.is_empty():
		return
	var row := _warehouse_row_for_instance(instance_id)
	if row.is_empty():
		warehouse_batch_feedback = "该物品已不在仓库中。"
	elif not bool(row.get("batch_sell_eligible", false)):
		warehouse_batch_feedback = str(row.get("batch_sell_reason", "该物品不可出售。"))
	elif warehouse_batch_selected_ids.has(instance_id):
		warehouse_batch_selected_ids.erase(instance_id)
		warehouse_batch_feedback = "已取消勾选 %s。" % str(row.get("title", "物品"))
	else:
		warehouse_batch_selected_ids.append(instance_id)
		warehouse_batch_selected_ids.sort()
		warehouse_batch_feedback = "已勾选 %s。" % str(row.get("title", "物品"))
	_refresh_all(false)


func _request_warehouse_batch_confirmation() -> void:
	_sanitize_warehouse_batch_selection()
	var projection := _warehouse_batch_projection()
	if int(projection.get("selected_count", 0)) <= 0:
		warehouse_batch_feedback = "请先勾选至少一件可售物品。"
		_refresh_all(false)
		return
	if not pending_meta_action.is_empty():
		warehouse_batch_feedback = "上一项基地操作仍在确认，请稍候。"
		_refresh_all(false)
		return
	if warehouse_batch_modal_body != null:
		warehouse_batch_modal_body.text = "将出售 %d 件物品，预计获得 %d 金币。\n交易按整批原子提交，确认后不可撤销。" % [
			int(projection.get("selected_count", 0)),
			int(projection.get("total_value", 0)),
		]
	_show_warehouse_batch_confirmation()


func _cancel_warehouse_batch_sell(refresh: bool = true) -> void:
	_hide_warehouse_batch_confirmation()
	warehouse_batch_active = false
	warehouse_batch_selected_ids.clear()
	warehouse_batch_feedback = ""
	if refresh and not current_model.is_empty():
		current_model = DeployPrepModelScript.model_with_action_message(current_model, "已取消批量售卖，仓库未发生变化。")
		_refresh_all(false)


func _on_map_scale_requested(_scale_id: StringName) -> void:
	# Scale selection is a view-only preview inside the single Deploy page.
	pass


func _on_map_requested(map_id: StringName) -> void:
	var result := DeployConfigScript.select_map(_config(), String(map_id))
	current_model = DeployPrepModelScript.model_with_config(
		current_model,
		_dictionary_from(result.get("config", _config())),
		StringName("m7_map_%s" % String(map_id)),
		str(result.get("message", ""))
	)
	_refresh_all(false)
	if not bool(result.get("changed", false)) and not reduced_motion:
		Art10UISkinKitScript.play_feedback_pulse(primary_action_button, &"warning", 0.45)


func _on_detail_action_pressed(index: int) -> void:
	if index < 0 or index >= detail_actions.size():
		return
	var action := detail_actions[index]
	if not bool(action.get("enabled", false)):
		return
	var action_id := StringName(action.get("id", action.get("action", &"")))
	if not pending_meta_action.is_empty() and action_id in META_DETAIL_ACTION_IDS:
		current_model = DeployPrepModelScript.model_with_action_message(current_model, "上一项基地操作仍在确认，请稍候。")
		_refresh_all(false)
		return
	var payload := _dictionary_from(action.get("payload", {}))
	match action_id:
		&"select_map":
			_on_map_requested(StringName(payload.get("map_config_id", &"")))
		&"open_map":
			show_tab(DeployTabModelScript.TAB_MAP)
		&"open_objective":
			show_tab(DeployTabModelScript.TAB_OBJECTIVE)
		&"remove_from_loadout":
			var instance_id := String(payload.get("instance_id", ""))
			_submit_explicit_card_action(DeployTabModelScript.TAB_WAREHOUSE, StringName("m3r_%s" % instance_id), StringName(current_model.get("selected_card", &"")))
		&"confirm_batch_sell":
			_request_warehouse_batch_confirmation()
		&"cancel_batch_sell":
			_cancel_warehouse_batch_sell()
		&"toggle_attendance", &"toggle_carry", &"sell", &"toggle_claim", &"purchase", &"select_objective":
			_submit_explicit_card_action(_active_tab(), StringName(current_model.get("selected_card", &"")), StringName(current_model.get("selected_card", &"")))


func _submit_explicit_card_action(domain_tab: StringName, domain_card_id: StringName, selected_card_id: StringName) -> void:
	var result := DeployConfigScript.apply_card_action(_config(), domain_tab, domain_card_id)
	var meta_action := _dictionary_from(result.get("meta_action", {}))
	if not meta_action.is_empty():
		_submit_meta_action(meta_action)
		return
	current_model = DeployPrepModelScript.model_with_config(
		current_model,
		_dictionary_from(result.get("config", _config())),
		selected_card_id,
		str(result.get("message", ""))
	)
	_refresh_all(bool(result.get("changed", false)))


func _submit_meta_action(action: Dictionary) -> void:
	if not pending_meta_action.is_empty():
		current_model = DeployPrepModelScript.model_with_action_message(current_model, "上一项基地操作仍在确认，请稍候。")
		_refresh_all(false)
		return
	var meta_action := action.duplicate(true)
	meta_action["selected_equipment_ids"] = _array_from(_config().get("selected_equipment_ids", []))
	meta_action["selected_consumable_ids"] = _array_from(_config().get("selected_consumable_ids", []))
	meta_request_sequence += 1
	meta_action["request_id"] = MetaActionRequestIdScript.generate(&"deploy")
	meta_action["source_page"] = &"deploy_prep"
	pending_meta_action = {
		"request_id": str(meta_action.get("request_id", "")),
		"source_page": &"deploy_prep",
		"action": StringName(meta_action.get("action", &"")),
		"target_id": _meta_action_target_id(meta_action),
	}
	current_model = DeployPrepModelScript.model_with_action_message(current_model, _meta_pending_player_message(meta_action))
	_refresh_all(false)
	meta_action_requested.emit(meta_action)


func _meta_action_target_id(action: Dictionary) -> String:
	match StringName(action.get("action", &"")):
		&"purchase": return str(action.get("item_id", ""))
		&"sell_collectible": return str(action.get("instance_id", ""))
		&"sell_collectibles_batch":
			return "batch:%s" % ",".join(_normalized_string_ids(action.get("instance_ids", [])))
	return ""


func _meta_pending_player_message(action: Dictionary) -> String:
	match StringName(action.get("action", &"")):
		&"purchase": return "正在确认购买…"
		&"sell_collectibles_batch": return "正在提交整批售卖…"
	return "正在确认出售…"


func _meta_result_player_message(envelope: Dictionary) -> String:
	var result := _dictionary_from(envelope.get("result", {}))
	var status := StringName(envelope.get("status", result.get("status", &"unknown")))
	if bool(envelope.get("ok", result.get("ok", false))):
		match status:
			&"purchased": return "购买成功，物品已进入仓库。"
			&"sold": return "出售成功，获得 %d 金币。" % int(result.get("gold_gained", 0))
			&"batch_sold": return "批量售卖成功：%d 件，共获得 %d 金币。" % [int(result.get("sold_count", 0)), int(result.get("gold_gained", 0))]
			&"duplicate_ignored": return "该操作已完成，无需重复提交。"
		return "基地操作已完成。"
	match status:
		&"insufficient_gold": return "金币不足，购买未发生。"
		&"locked": return "该物品尚未解锁，购买未发生。"
		&"write_blocked": return "当前存档不可写，余额与库存未改变。"
		&"save_failed": return "保存失败，余额与库存已恢复。"
		&"configured_item_blocked": return "该物品正在出勤配置中，请先移出后再出售。"
		&"instance_not_found": return "该物品已不存在，未发生出售。"
		&"item_not_sellable": return "该物品不可出售。"
		&"empty_batch": return "没有选择可售物品，仓库未发生变化。"
		&"batch_validation_failed": return _batch_validation_player_message(result)
		&"request_id_conflict": return "操作校验冲突，未发生交易。"
		&"unknown_shop_item", &"item_definition_missing": return "该商品暂不可购买。"
		&"meta_progress_adapter_missing": return "基地档案暂不可用，未发生交易。"
	return "基地操作未完成，请稍后重试。"


func _batch_validation_player_message(result: Dictionary) -> String:
	var failures := _array_from(result.get("item_failures", []))
	if failures.is_empty():
		return "批量售卖校验未通过，整批物品均未出售。"
	var first := _dictionary_from(failures[0])
	match StringName(first.get("reason_code", &"")):
		&"configured_item_blocked":
			return "所选物品中包含当前出勤项；请先移出出勤。整批均未出售。"
		&"instance_not_found":
			return "所选物品已发生变化；请重新勾选。整批均未出售。"
		&"item_not_sellable", &"duplicate_instance_record":
			return "所选物品中包含不可售项目；请重新勾选。整批均未出售。"
	return "批量售卖校验未通过，整批物品均未出售。"


func _on_primary_action_pressed() -> void:
	if _has_active_run():
		var continue_payload := {"target_route": &"run", "route_mode": &"continue_run", "entry_id": &"m6_continue_active_run", "uses_existing_route": true, "continue_active_run": true}
		deploy_start_intent_requested.emit(NavigationIntentScript.make_run(&"deploy_prep", continue_payload))
		return
	var config := _config()
	var validity := _dictionary_from(config.get("config_validity_preview", {}))
	if not bool(validity.get("can_start", true)):
		current_model = DeployPrepModelScript.model_with_action_message(current_model, "当前配置不合法，无法出发。")
		_refresh_summary()
		if not reduced_motion:
			Art10UISkinKitScript.play_feedback_pulse(primary_action_button, &"warning", 0.7)
		return
	current_model["run_start_config"] = DeployConfigScript.build_run_start_config(config)
	current_model["preview_lines"] = DeployConfigScript.build_preview_lines(config)
	current_model["action_message"] = "已使用玩家确认的携带配置进入探索。"
	_refresh_summary()
	var start_action := _action("start")
	var run_payload := _dictionary_from(start_action.get("run_intent", {}))
	run_payload["source_page"] = &"deploy_prep"
	run_payload["preview_only"] = false
	run_payload = RunStartRouteAdapterScript.payload_from_deploy_preview(current_model.get("run_start_config", {}), run_payload)
	deploy_start_intent_requested.emit(NavigationIntentScript.make_run(&"deploy_prep", run_payload))


func _show_cancel_modal() -> void:
	if not _has_active_run():
		return
	current_model = DeployPrepModelScript.model_with_action_message(current_model, "放弃探索需要再次确认。", true)
	_refresh_modal_state()
	_refresh_summary()


func _hide_cancel_modal() -> void:
	current_model = DeployPrepModelScript.model_with_action_message(current_model, "已取消放弃操作，当前探索保持不变。", false)
	_refresh_modal_state()
	_refresh_summary()


func _confirm_cancel_active_run() -> void:
	if modal_focus_stack.top_modal_id() != &"deploy_abandon":
		return
	if not _has_active_run():
		_hide_cancel_modal()
		return
	current_model = DeployPrepModelScript.model_with_action_message(current_model, "正在放弃当前探索并进入结算。", false)
	_hide_cancel_modal_visual()
	var payload := {"target_route": &"run", "route_mode": &"abandon_run", "entry_id": &"m6_abandon_active_run", "uses_existing_route": true, "abandon_active_run": true, "reason": "player_deploy_abandon", "confirmed": true}
	deploy_start_intent_requested.emit(NavigationIntentScript.make_run(&"deploy_prep", payload))


func _show_cancel_modal_visual() -> void:
	if modal_layer == null:
		return
	if modal_focus_stack.contains(&"deploy_abandon"):
		return
	if not modal_focus_stack.push(&"deploy_abandon", modal_layer, modal_cancel_button, _on_cancel_modal_requested):
		return
	if reduced_motion:
		modal_layer.modulate = Color.WHITE
	else:
		Art10UISkinKitScript.play_panel_open(modal_layer)


func _hide_cancel_modal_visual() -> void:
	if modal_layer == null:
		return
	if not modal_focus_stack.pop(&"deploy_abandon"):
		modal_layer.visible = false


func _on_cancel_modal_requested(_reason: StringName) -> void:
	_hide_cancel_modal()


func _show_warehouse_batch_confirmation() -> void:
	if warehouse_batch_modal_layer == null or warehouse_batch_modal_cancel_button == null:
		return
	if modal_focus_stack.contains(&"warehouse_batch_sell"):
		return
	if not modal_focus_stack.push(
		&"warehouse_batch_sell",
		warehouse_batch_modal_layer,
		warehouse_batch_modal_cancel_button,
		_on_warehouse_batch_modal_requested
	):
		return
	warehouse_batch_modal_layer.visible = true
	if reduced_motion:
		warehouse_batch_modal_layer.modulate = Color.WHITE
	else:
		Art10UISkinKitScript.play_panel_open(warehouse_batch_modal_layer)


func _hide_warehouse_batch_confirmation() -> void:
	if warehouse_batch_modal_layer == null:
		return
	if modal_focus_stack.contains(&"warehouse_batch_sell"):
		modal_focus_stack.pop(&"warehouse_batch_sell")
	else:
		warehouse_batch_modal_layer.visible = false


func _on_warehouse_batch_modal_requested(_reason: StringName) -> void:
	_hide_warehouse_batch_confirmation()


func _confirm_warehouse_batch_sell() -> void:
	if modal_focus_stack.top_modal_id() != &"warehouse_batch_sell":
		return
	if not warehouse_batch_active or warehouse_batch_selected_ids.is_empty() or not pending_meta_action.is_empty():
		_hide_warehouse_batch_confirmation()
		return
	var instance_ids := warehouse_batch_selected_ids.duplicate()
	_hide_warehouse_batch_confirmation()
	_submit_meta_action({
		"action": &"sell_collectibles_batch",
		"instance_ids": instance_ids,
	})


func _toggle_parchment() -> void:
	set_parchment_collapsed(not parchment_collapsed, true)


func _request_back_to_main() -> void:
	navigation_intent_requested.emit(NavigationIntentScript.make(
		NavigationIntentScript.TARGET_MAIN_MENU,
		&"deploy_prep",
		{"source_page": &"deploy_prep"}
	))


func _request_long_term() -> void:
	navigation_intent_requested.emit(NavigationIntentScript.make_long_term(
		&"deploy_prep",
		&"task_archive",
		{"source_page": &"deploy_prep", "preview_only": false}
	))


func _request_appearance() -> void:
	navigation_intent_requested.emit(NavigationIntentScript.make_long_term(
		&"deploy_prep",
		&"collection_appearance",
		{"source_page": &"deploy_prep", "preview_only": false}
	))


func _process(delta: float) -> void:
	if not page_active or not is_visible_in_tree():
		return
	if reduced_motion:
		_freeze_motion()
		return
	scene_elapsed += delta
	_update_character_motion(delta)
	_update_ambient_animations(delta)
	_update_summary_sway()


func _update_character_motion(delta: float) -> void:
	if character_texture == null or character_frames.is_empty():
		return
	if character_look_index < 0 and scene_elapsed >= next_character_look:
		character_look_index = 0
		character_elapsed = 0.0
	character_elapsed += delta
	var active_clip_id := &"look" if character_look_index >= 0 else &"idle"
	var active_descriptor := _dictionary_from(character_clip_descriptors.get(active_clip_id, {}))
	var frame_seconds := maxf(0.01, float(active_descriptor.get("frame_seconds", 0.32)))
	if character_elapsed < frame_seconds:
		return
	character_elapsed = fmod(character_elapsed, frame_seconds)
	if character_look_index >= 0:
		_apply_character_clip_pose(&"look", character_look_index)
		character_look_index += 1
		var look_sequence := active_descriptor.get("sequence", []) as Array
		if look_sequence.is_empty() or character_look_index >= look_sequence.size():
			character_look_index = -1
			character_frame_index = 0
			next_character_look = scene_elapsed + CHARACTER_LOOK_INTERVAL_SECONDS
		return
	var idle_sequence := active_descriptor.get("sequence", []) as Array
	if idle_sequence.is_empty():
		return
	character_frame_index = (character_frame_index + 1) % idle_sequence.size()
	_apply_character_clip_pose(&"idle", character_frame_index)


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


func _register_art21_loop(parent: Control, node_name: String, rect: Rect2, prefix: String, sequence: Array, frame_seconds: float, tint: Color, base_alpha: float) -> void:
	var frames: Array[Texture2D] = []
	for index in range(4):
		var texture := Art21MainMenuAssetContractScript.texture(StringName("%s.%02d" % [prefix, index]))
		if texture != null:
			frames.append(texture)
	if frames.size() != 4:
		return
	var node := _add_texture_from_texture(parent, node_name, rect, frames[0], 1, true)
	if node == null:
		return
	node.modulate = Color(tint.r, tint.g, tint.b, base_alpha)
	node.pivot_offset = rect.size * 0.5
	ambient_animations.append({
		"node": node,
		"frames": frames,
		"sequence": sequence.duplicate(),
		"frame_seconds": frame_seconds,
		"elapsed": 0.0,
		"cursor": 0,
		"tint": tint,
		"base_alpha": base_alpha,
		"phase": float(ambient_animations.size()) * 0.83,
	})


func _update_ambient_animations(delta: float) -> void:
	for index in range(ambient_animations.size()):
		var group := ambient_animations[index]
		var node := group.get("node") as TextureRect
		var frames := group.get("frames", []) as Array
		var sequence := group.get("sequence", []) as Array
		if node == null or frames.is_empty() or sequence.is_empty():
			continue
		var elapsed := float(group.get("elapsed", 0.0)) + delta
		var frame_seconds := maxf(0.08, float(group.get("frame_seconds", 0.3)))
		if elapsed >= frame_seconds:
			elapsed = fmod(elapsed, frame_seconds)
			var cursor := (int(group.get("cursor", 0)) + 1) % sequence.size()
			group["cursor"] = cursor
			node.texture = frames[int(sequence[cursor]) % frames.size()]
		group["elapsed"] = elapsed
		var tint := group.get("tint", Color.WHITE) as Color
		var base_alpha := float(group.get("base_alpha", 0.4))
		var phase := float(group.get("phase", 0.0))
		var pulse := 0.92 + sin(scene_elapsed * 2.4 + phase) * 0.08
		node.modulate = Color(tint.r, tint.g, tint.b, base_alpha * pulse)
		ambient_animations[index] = group


func _add_ambient_particles(parent: Control, node_name: String, center: Vector2, extents: Vector2, amount: int, color: Color, velocity: Vector2, lifetime: float) -> void:
	var particles := CPUParticles2D.new()
	particles.name = node_name
	particles.position = center
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	particles.randomness = 0.72
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = extents
	particles.direction = velocity.normalized()
	particles.spread = 38.0
	particles.gravity = Vector2(0, -1.5)
	particles.initial_velocity_min = velocity.length() * 0.45
	particles.initial_velocity_max = velocity.length()
	particles.scale_amount_min = 0.55
	particles.scale_amount_max = 1.25
	particles.color = color
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	particles.texture = ImageTexture.create_from_image(image)
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.emitting = not reduced_motion
	particles.z_index = 1
	parent.add_child(particles)
	ambient_particles.append(particles)


func _update_summary_sway() -> void:
	var offset := Vector2(round(sin(scene_elapsed * 0.72) * 1.2), round(sin(scene_elapsed * 0.51 + 0.8) * 0.7))
	var summary_root := _root(&"SideStatusRoot")
	if summary_root != null:
		summary_root.position = offset
	var decoration_root := _root(&"DecorationRoot")
	for node_name in summary_chain_bases.keys():
		var chain := decoration_root.get_node_or_null(String(node_name)) as TextureRect
		if chain != null:
			chain.position = (summary_chain_bases[node_name] as Vector2) + offset


func _freeze_motion() -> void:
	if character_texture != null and not character_frames.is_empty():
		_apply_character_clip_pose(&"idle", 0)
	for group in ambient_animations:
		var node := group.get("node") as TextureRect
		var frames := group.get("frames", []) as Array
		if node != null and not frames.is_empty():
			node.texture = frames[0]
	for particles in ambient_particles:
		if particles != null:
			particles.emitting = false
	var summary_root := _root(&"SideStatusRoot")
	if summary_root != null:
		summary_root.position = Vector2.ZERO
	var decoration_root := _root(&"DecorationRoot")
	if decoration_root != null:
		for node_name in summary_chain_bases.keys():
			var chain := decoration_root.get_node_or_null(String(node_name)) as TextureRect
			if chain != null:
				chain.position = summary_chain_bases[node_name] as Vector2


func handle_cancel_event(event: InputEvent) -> bool:
	if event == null or event.is_echo() or not page_active or not is_visible_in_tree():
		return false
	if modal_focus_stack.handle_cancel_event(event):
		return true
	if not (event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel")):
		return false
	if warehouse_batch_active:
		_cancel_warehouse_batch_sell()
		return true
	_request_back_to_main()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if handle_cancel_event(event):
		get_viewport().set_input_as_handled()


func _summary_page_blocks(page_id: StringName) -> Array[String]:
	var summary := _dictionary_from(current_model.get("summary_projection", {}))
	var pages := _dictionary_from(summary.get("pages", {}))
	var lines := _array_from(pages, String(page_id))
	var result: Array[String] = []
	for index in range(lines.size()):
		var line := Art10UISkinKitScript.sanitize_player_copy(str(lines[index])).strip_edges()
		result.append(line)
	return result


func _ensure_summary_row_count(required_count: int) -> void:
	for index in range(summary_row_labels.size(), maxi(0, required_count)):
		_append_summary_row(index)


func _append_summary_row(index: int) -> void:
	if summary_scroll_content == null:
		return
	var row_panel := Panel.new()
	row_panel.name = "DeploySummaryRowPanel%d" % index
	row_panel.custom_minimum_size = Vector2(208, 46)
	row_panel.add_theme_stylebox_override(
		"panel",
		Art10UISkinKitScript.style_box_from_asset_ref_with_insets(
			Art22DeployPrepAssetContractScript.control_ref(&"slot", &"normal"),
			Vector4.ZERO,
			Vector4(4, 4, 4, 4)
		)
	)
	summary_scroll_content.add_child(row_panel)
	var row_label := _add_label(
		row_panel,
		"DeploySummaryRow%d" % index,
		Rect2(8, 6, 192, 34),
		"",
		14,
		Color(0.94, 0.87, 0.72),
		HORIZONTAL_ALIGNMENT_LEFT,
		VERTICAL_ALIGNMENT_CENTER,
		0
	)
	row_label.custom_minimum_size = Vector2(192, 34)
	row_label.set_meta("deploy_scroll_content", true)
	row_label.set_meta("deploy_summary_row_panel", row_panel)
	_apply_label_flow_policy(row_label)
	summary_row_labels.append(row_label)


func _summary_character_budget() -> int:
	if ui_scale_factor >= 1.5:
		return 9
	if ui_scale_factor >= 1.25:
		return 11
	return 13


func _summary_message_budget() -> int:
	if ui_scale_factor >= 1.5:
		return 10
	if ui_scale_factor >= 1.25:
		return 13
	return 18


func _wire_focus_neighbors() -> void:
	_wire_linear(_buttons_from_dictionary(tab_buttons), false)
	var active_tab_button := tab_buttons.get(_active_tab()) as Button
	if _active_tab() == DeployTabModelScript.TAB_MAP and map_split_view != null:
		var map_buttons: Array = map_split_view.call("focus_buttons")
		if active_tab_button != null and not map_buttons.is_empty():
			var first_map_button := map_buttons[0] as Button
			_set_neighbor(active_tab_button, "bottom", first_map_button)
			_set_neighbor(first_map_button, "top", active_tab_button)
	else:
		var filters := _buttons_from_dictionary(filter_buttons)
		var cards := _card_focus_buttons()
		_wire_linear(filters, false)
		_wire_linear(cards, true)
		if active_tab_button != null:
			if not filters.is_empty():
				_set_neighbor(active_tab_button, "bottom", filters[0] as Button)
			elif not cards.is_empty():
				_set_neighbor(active_tab_button, "bottom", cards[0] as Button)
		if not filters.is_empty() and not cards.is_empty():
			for filter_button in filters:
				_set_neighbor(filter_button as Button, "bottom", cards[0] as Button)
		var detail_focus := _first_detail_action_button()
		if detail_focus != null and not cards.is_empty():
			for card_button in cards:
				_set_neighbor(card_button as Button, "right", detail_focus)
			_set_neighbor(detail_focus, "left", cards[0] as Button)
		if detail_primary_action_button != null and detail_secondary_action_button != null and detail_primary_action_button.visible and detail_secondary_action_button.visible:
			_link_horizontal(detail_primary_action_button, detail_secondary_action_button)
	_wire_linear(_buttons_from_dictionary(summary_buttons), false)
	if modal_confirm_button != null and modal_cancel_button != null:
		_trap_modal_focus(modal_confirm_button, modal_cancel_button)
	if warehouse_batch_modal_confirm_button != null and warehouse_batch_modal_cancel_button != null:
		_trap_modal_focus(warehouse_batch_modal_confirm_button, warehouse_batch_modal_cancel_button)
	var nav_main := get_node_or_null("PrimaryActionRoot/DeployNavMain") as Button
	var nav_long := get_node_or_null("PrimaryActionRoot/DeployNavLongTerm") as Button
	var appearance := get_node_or_null("PrimaryActionRoot/DeployAppearanceButton") as Button
	if nav_main != null and nav_long != null:
		_link_vertical(nav_main, nav_long)
	if nav_long != null and appearance != null:
		_set_neighbor(nav_long, "bottom", appearance)
		_set_neighbor(appearance, "top", nav_long)
	if primary_action_button != null and cancel_action_button != null:
		_set_neighbor(primary_action_button, "bottom", cancel_action_button)
		_set_neighbor(cancel_action_button, "top", primary_action_button)


func _first_detail_action_button() -> Button:
	for button in [detail_primary_action_button, detail_secondary_action_button]:
		if button != null and button.visible and not button.disabled:
			return button
	return null


func _wire_linear(buttons: Array, vertical: bool) -> void:
	if buttons.size() < 2:
		return
	for index in range(buttons.size()):
		var button := buttons[index] as Button
		var previous := buttons[(index - 1 + buttons.size()) % buttons.size()] as Button
		var next := buttons[(index + 1) % buttons.size()] as Button
		if vertical:
			_set_neighbor(button, "top", previous)
			_set_neighbor(button, "bottom", next)
		else:
			_set_neighbor(button, "left", previous)
			_set_neighbor(button, "right", next)


func _set_neighbor(button: Button, direction: String, target: Button) -> void:
	if button == null or target == null:
		return
	var path := button.get_path_to(target)
	match direction:
		"top": button.focus_neighbor_top = path
		"bottom": button.focus_neighbor_bottom = path
		"left": button.focus_neighbor_left = path
		"right": button.focus_neighbor_right = path


func _link_horizontal(left: Button, right: Button) -> void:
	_set_neighbor(left, "right", right)
	_set_neighbor(right, "left", left)


func _link_vertical(top: Button, bottom: Button) -> void:
	_set_neighbor(top, "bottom", bottom)
	_set_neighbor(bottom, "top", top)


func _trap_modal_focus(first: Button, second: Button) -> void:
	if first == null or second == null:
		return
	for direction in ["top", "bottom", "left", "right"]:
		_set_neighbor(first, direction, second)
		_set_neighbor(second, direction, first)
	first.focus_next = first.get_path_to(second)
	first.focus_previous = first.get_path_to(second)
	second.focus_next = second.get_path_to(first)
	second.focus_previous = second.get_path_to(first)


func _grab_initial_focus() -> void:
	if not page_active or not is_visible_in_tree():
		return
	var active_button := tab_buttons.get(_active_tab()) as Button
	if active_button != null:
		active_button.grab_focus()


func _save_active_view_state() -> void:
	if current_model.is_empty():
		return
	var tab_id := _active_tab()
	view_state_by_tab[String(tab_id)] = {
		"filter": StringName(current_model.get("selected_filter", DeployTabModelScript.FILTER_ALL)),
		"card": StringName(current_model.get("selected_card", &"")),
		"scroll": card_scroll.scroll_vertical if card_scroll != null else 0,
		"filter_scroll": filter_scroll.scroll_horizontal if filter_scroll != null else 0,
	}


func _restore_model_state(tab_id: StringName) -> void:
	var state := _state_for_tab(tab_id)
	if state.is_empty():
		return
	var filter_id := StringName(state.get("filter", DeployTabModelScript.default_filter_for(tab_id)))
	current_model = DeployPrepModelScript.model_with_filter(current_model, filter_id)
	var card_id := StringName(state.get("card", &""))
	if _visible_cards_contain(card_id):
		current_model = DeployPrepModelScript.model_with_card(current_model, card_id)


func _state_for_tab(tab_id: StringName) -> Dictionary:
	var raw: Variant = view_state_by_tab.get(String(tab_id), {})
	return (raw as Dictionary).duplicate(true) if raw is Dictionary else {}


func _stored_scroll_for(tab_id: StringName) -> int:
	return int(_state_for_tab(tab_id).get("scroll", 0))


func _restore_filter_scroll(value: int) -> void:
	if filter_scroll != null:
		filter_scroll.scroll_horizontal = value


func _restore_card_scroll(value: int) -> void:
	if card_scroll != null:
		card_scroll.scroll_vertical = value


func _visible_cards_contain(card_id: StringName) -> bool:
	for raw_card in _array_from(current_model, "selection_rows"):
		if StringName(_dictionary_from(raw_card).get("id", &"")) == card_id:
			return true
	return false


func _normalize_tab_id(tab_id: StringName) -> StringName:
	for raw_tab in DeployTabModelScript.build_tabs():
		if StringName(_dictionary_from(raw_tab).get("id", &"")) == tab_id:
			return tab_id
	return DeployTabModelScript.DEFAULT_TAB


func _active_tab() -> StringName:
	return _normalize_tab_id(StringName(current_model.get("active_tab", DeployTabModelScript.DEFAULT_TAB)))


func _has_active_run() -> bool:
	var active := _dictionary_from(_config().get("active_run_preview", {}))
	return bool(active.get("has_active_run", false))


func _config() -> Dictionary:
	return _dictionary_from(current_model.get("config", DeployConfigScript.default_config()))


func get_selected_instance_ids() -> Dictionary:
	return {
		"selected_equipment_ids": _array_from(_config().get("selected_equipment_ids", [])),
		"selected_consumable_ids": _array_from(_config().get("selected_consumable_ids", [])),
	}


func _action(action_id: String) -> Dictionary:
	return _dictionary_from(_dictionary_from(current_model.get("actions", {})).get(action_id, {}))


func _add_image_button(parent: Control, node_name: String, rect: Rect2, text: String, control_id: StringName, callback: Callable, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.clip_text = true
	button.z_index = 3
	Art10UISkinKitScript.apply_button(button, &"secondary", font_size, &"button")
	button.set_meta("deploy_base_font_size", font_size)
	button.set_meta("deploy_max_font_size", maxi(font_size, int(floor(rect.size.y - 10.0))))
	button.set_meta("deploy_text_bounds", rect.size)
	_apply_scaled_control_font(button)
	_set_rect(button, rect)
	_apply_image_button_surface(button, control_id, &"normal")
	if callback.is_valid():
		button.pressed.connect(callback)
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			button.grab_focus()
	)
	parent.add_child(button)
	return button


func _add_container_image_button(parent: Container, node_name: String, minimum_size: Vector2, text: String, control_id: StringName, callback: Callable, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = minimum_size
	button.set_meta("deploy_base_minimum_size", minimum_size)
	button.set_meta(
		"deploy_max_minimum_size",
		Vector2(INF, DeployPrepLayoutContractScript.FILTER_SCROLL.size.y)
	)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.clip_text = true
	button.z_index = 3
	Art10UISkinKitScript.apply_button(button, &"secondary", font_size, &"button")
	button.set_meta("deploy_base_font_size", font_size)
	button.set_meta("deploy_text_bounds", minimum_size)
	_apply_scaled_control_font(button)
	_apply_scaled_control_minimum(button)
	_apply_image_button_surface(button, control_id, &"normal")
	if callback.is_valid():
		button.pressed.connect(callback)
	# Filter rows can move underneath a stationary pointer. Do not convert hover
	# into focus here: doing so can recursively focus later buttons while the row
	# auto-scrolls to the selected item. Mouse press and keyboard navigation still
	# assign focus normally.
	parent.add_child(button)
	return button


func _apply_image_button_surface(button: Button, control_id: StringName, normal_state: StringName) -> void:
	if button == null:
		return
	var normal := normal_state
	if button.disabled:
		normal = &"disabled"
	button.add_theme_stylebox_override("normal", _button_style(control_id, normal))
	var focused_state := &"selected" if normal_state == &"selected" else &"focused"
	button.add_theme_stylebox_override("hover", _button_style(control_id, focused_state))
	button.add_theme_stylebox_override("focus", _button_style(control_id, focused_state))
	var pressed_state := &"selected" if normal_state == &"selected" else &"pressed"
	button.add_theme_stylebox_override("pressed", _button_style(control_id, pressed_state))
	button.add_theme_stylebox_override("hover_pressed", _button_style(control_id, pressed_state))
	button.add_theme_stylebox_override("disabled", _button_style(control_id, &"disabled"))
	var dark_text := control_id in [&"tab", &"filter", &"handle"] and normal_state != &"selected"
	var color := Color(0.20, 0.12, 0.07) if dark_text else Color(0.98, 0.86, 0.58)
	var light_surface_text := Color(0.20, 0.12, 0.07) if control_id in [&"tab", &"filter", &"handle"] and normal_state != &"selected" else color.lightened(0.12)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", light_surface_text)
	button.add_theme_color_override("font_focus_color", light_surface_text)
	button.add_theme_color_override("font_pressed_color", color if normal_state == &"selected" else color.darkened(0.12))
	button.add_theme_color_override("font_disabled_color", Color(color.r, color.g, color.b, 0.46))


func _button_style(control_id: StringName, state: StringName) -> StyleBox:
	var content_inset := 6
	var texture_margin := 12
	match control_id:
		&"nav": texture_margin = 18
		&"action": texture_margin = 24
		&"danger": texture_margin = 18
		&"tab": texture_margin = 12
		&"filter": texture_margin = 10
		&"handle":
			content_inset = 4
			texture_margin = 12
	return Art10UISkinKitScript.style_box_from_asset_ref_with_insets(
		Art22DeployPrepAssetContractScript.control_ref(control_id, state),
		Vector4(content_inset, content_inset, content_inset, content_inset),
		Vector4(texture_margin, texture_margin, texture_margin, texture_margin)
	)


func _add_texture(parent: Control, node_name: String, rect: Rect2, visual_key: StringName, local_z: int, nearest: bool = true) -> TextureRect:
	var texture := _texture(visual_key)
	return _add_texture_from_texture(parent, node_name, rect, texture, local_z, nearest)


func _add_art21_texture(parent: Control, node_name: String, rect: Rect2, visual_key: StringName, local_z: int) -> TextureRect:
	return _add_texture_from_texture(parent, node_name, rect, Art21MainMenuAssetContractScript.texture(visual_key), local_z, true)


func _add_texture_from_texture(parent: Control, node_name: String, rect: Rect2, texture: Texture2D, local_z: int, nearest: bool) -> TextureRect:
	if texture == null:
		return null
	var node := TextureRect.new()
	node.name = node_name
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if nearest else CanvasItem.TEXTURE_FILTER_LINEAR
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.z_index = local_z
	_set_rect(node, rect)
	parent.add_child(node)
	return node


func _texture(visual_key: StringName) -> Texture2D:
	if texture_cache.has(visual_key):
		return texture_cache[visual_key] as Texture2D
	var texture := Art22DeployPrepAssetContractScript.texture(visual_key)
	if texture == null:
		match visual_key:
			&"deploy_prep.panel.parchment":
				texture = Art21UIPlacementContractScript.texture_for_slot(&"deploy_prep", &"center_route_wall")
			&"deploy_prep.panel.summary_board":
				texture = Art21UIPlacementContractScript.texture_for_slot(&"deploy_prep", &"right_summary_panel")
	if texture != null:
		texture_cache[visual_key] = texture
	return texture


func _add_label(parent: Control, node_name: String, rect: Rect2, text: String, font_size: int, color: Color, horizontal: HorizontalAlignment, vertical: VerticalAlignment, local_z: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.horizontal_alignment = horizontal
	label.vertical_alignment = vertical
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = local_z
	var composition_role := &"body"
	if node_name.ends_with("Title"):
		composition_role = &"title"
	elif node_name.ends_with("Badge") or node_name.ends_with("Badges") or node_name.ends_with("Hint") or node_name.ends_with("Feedback"):
		composition_role = &"status"
	Art10UISkinKitScript.apply_composition_label(label, composition_role, font_size, color)
	label.set_meta("deploy_base_font_size", font_size)
	label.set_meta("deploy_composition_role", composition_role)
	label.set_meta("deploy_max_font_size", maxi(font_size, int(floor(rect.size.y - 4.0))))
	var max_lines := _label_max_lines(node_name)
	label.set_meta("deploy_max_lines", max_lines)
	label.set_meta("deploy_multiline", max_lines > 1)
	label.set_meta("deploy_text_padding", Vector2(4, 2))
	label.set_meta("deploy_text_bounds", rect.size)
	_apply_label_flow_policy(label)
	_apply_scaled_control_font(label)
	_set_rect(label, rect)
	parent.add_child(label)
	return label


func _refresh_ui_scale_metrics() -> void:
	for control in _control_descendants(self):
		if control.has_meta("deploy_base_font_size"):
			_apply_scaled_control_font(control)
		if control.has_meta("deploy_base_minimum_size"):
			_apply_scaled_control_minimum(control)


func _apply_scaled_control_font(control: Control) -> void:
	if control == null or not control.has_meta("deploy_base_font_size"):
		return
	var base_font_size := int(control.get_meta("deploy_base_font_size", 0))
	var scaled_font_size := Art10UISkinKitScript.scaled_font_size(base_font_size, ui_scale_factor)
	var max_font_size := int(control.get_meta("deploy_max_font_size", scaled_font_size))
	var text := ""
	var multiline := false
	var alignment := HORIZONTAL_ALIGNMENT_LEFT
	var padding := Vector2(12, 8)
	if control is Label:
		var label := control as Label
		text = label.text
		multiline = bool(label.get_meta("deploy_multiline", false))
		alignment = label.horizontal_alignment
		padding = label.get_meta("deploy_text_padding", Vector2(4, 2))
	elif control is Button:
		var button := control as Button
		text = button.text
		multiline = text.contains("\n")
		alignment = button.alignment
	var fit := DeployPrepLayoutContractScript.fit_text(
		text,
		control.get_theme_font("font"),
		control.get_meta("deploy_text_bounds", control.size),
		base_font_size,
		ui_scale_factor,
		multiline,
		alignment,
		padding,
		max_font_size
	)
	scaled_font_size = int(fit.get("font_size", scaled_font_size))
	control.add_theme_font_size_override("font_size", scaled_font_size)
	control.set_meta("deploy_text_fit", fit)
	control.set_meta("runtime_ui_scale_factor", ui_scale_factor)
	if control is Label:
		_apply_label_flow_policy(control as Label)


func _refit_detail_controls() -> void:
	for control in [
		detail_title_label,
		detail_badge_label,
		detail_description_label,
		detail_feedback_label,
		detail_primary_action_button,
		detail_secondary_action_button,
	]:
		if control != null:
			_apply_scaled_control_font(control)
	for fact_label in detail_fact_labels:
		if fact_label != null:
			_apply_scaled_control_font(fact_label)


func _resize_scroll_label(label: Label, minimum_height: float, characters_per_line: int) -> void:
	if label == null:
		return
	var text := label.text.strip_edges()
	var estimated_lines := 1
	if not text.is_empty():
		estimated_lines = maxi(
			1,
			int(ceil(float(text.length()) / float(maxi(1, characters_per_line))))
			+ text.count("\n")
		)
	var font_size := label.get_theme_font_size("font_size")
	label.custom_minimum_size.y = maxf(
		minimum_height,
		float(estimated_lines * (font_size + 7) + 8)
	)


func _label_max_lines(node_name: String) -> int:
	match node_name:
		"DeployDetailBadges":
			return 2
		"DeployDetailDescription":
			return 3
		"DeployCancelModalBody", "DeployWarehouseBatchSellBody":
			return 3
		"DeploySummaryMessage":
			return 2
		_:
			return 1


func _apply_label_flow_policy(label: Label) -> void:
	if label == null:
		return
	if bool(label.get_meta("deploy_scroll_content", false)):
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = false
		label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		label.max_lines_visible = -1
		return
	var max_lines := int(label.get_meta("deploy_max_lines", 1))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if max_lines > 1 else TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.max_lines_visible = max_lines


func _apply_scaled_control_minimum(control: Control) -> void:
	if control == null or not control.has_meta("deploy_base_minimum_size"):
		return
	var base_minimum: Vector2 = control.get_meta("deploy_base_minimum_size", Vector2.ZERO)
	var scaled_minimum := Art10UISkinKitScript.scaled_control_minimum(base_minimum, ui_scale_factor)
	var max_minimum: Vector2 = control.get_meta(
		"deploy_max_minimum_size",
		Vector2(INF, INF)
	)
	control.custom_minimum_size = Vector2(
		minf(scaled_minimum.x, max_minimum.x),
		minf(scaled_minimum.y, max_minimum.y)
	)
	control.set_meta("runtime_ui_scale_factor", ui_scale_factor)


func _control_descendants(root_node: Node) -> Array[Control]:
	var result: Array[Control] = []
	for child in root_node.get_children():
		if child is Control:
			result.append(child as Control)
		result.append_array(_control_descendants(child))
	return result


func _add_color_rect(parent: Control, node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var node := ColorRect.new()
	node.name = node_name
	node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(node, rect)
	parent.add_child(node)
	return node


func _add_image_panel(parent: Control, node_name: String, rect: Rect2, control_id: StringName, state: StringName, local_z: int) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = local_z
	panel.add_theme_stylebox_override("panel", Art10UISkinKitScript.style_box_from_asset_ref(
		Art22DeployPrepAssetContractScript.control_ref(control_id, state),
		7,
		12
	))
	_set_rect(panel, rect)
	parent.add_child(panel)
	return panel


func _style_filter_scrollbar() -> void:
	if filter_scroll == null:
		return
	var bar := filter_scroll.get_h_scroll_bar()
	if bar == null:
		return
	bar.custom_minimum_size.y = 6
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.16, 0.10, 0.055, 0.72)
	track.set_corner_radius_all(2)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(0.62, 0.43, 0.20, 0.92)
	grabber.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("grabber", grabber)
	bar.add_theme_stylebox_override("grabber_highlight", grabber)
	bar.add_theme_stylebox_override("grabber_pressed", grabber)


func _long_filter_width(label: String) -> float:
	var length := label.strip_edges().length()
	if length >= 9:
		return 148.0
	if length >= 5:
		return 104.0
	return 82.0


func _ensure_filter_visible(button: Control) -> void:
	if filter_scroll == null or button == null or not button.is_inside_tree():
		return
	await get_tree().process_frame
	if button == null or not is_instance_valid(button) or not button.is_inside_tree():
		return
	var bar := filter_scroll.get_h_scroll_bar()
	var max_scroll := 0
	if bar != null:
		max_scroll = maxi(0, int(bar.max_value - bar.page))
	var current_scroll := float(filter_scroll.scroll_horizontal)
	var viewport_width := filter_scroll.size.x
	var margin := 10.0
	var target_scroll := current_scroll
	if button.position.x < current_scroll + margin:
		target_scroll = button.position.x - margin
	elif button.position.x + button.size.x > current_scroll + viewport_width - margin:
		target_scroll = button.position.x + button.size.x - viewport_width + margin
	filter_scroll.scroll_horizontal = clampi(int(round(target_scroll)), 0, max_scroll)
	_update_filter_navigation()


func _focus_active_filter() -> void:
	var selected := StringName(current_model.get("selected_filter", DeployTabModelScript.FILTER_ALL))
	var button := filter_buttons.get(selected) as Button
	if button != null:
		_ensure_filter_visible(button)


func _scroll_filters(direction: int) -> void:
	if filter_scroll == null:
		return
	var bar := filter_scroll.get_h_scroll_bar()
	var max_scroll := maxi(0, int(bar.max_value - bar.page)) if bar != null else 0
	filter_scroll.scroll_horizontal = clampi(filter_scroll.scroll_horizontal + direction * 260, 0, max_scroll)
	_update_filter_navigation()


func _update_filter_navigation() -> void:
	if filter_previous_button == null or filter_next_button == null or filter_scroll == null:
		return
	# The content minimum is independent of the current scroll value. Basing the
	# decision on it avoids both sticky arrows after a page switch and clamping
	# the last part of an overflowing row whenever value_changed fires.
	var content_width := filter_row.get_combined_minimum_size().x if filter_row != null else 0.0
	var show_navigation := content_width > DeployPrepLayoutContractScript.FILTER_SCROLL.size.x
	var target_rect := DeployPrepLayoutContractScript.FILTER_SCROLL_WITH_NAV if show_navigation else DeployPrepLayoutContractScript.FILTER_SCROLL
	if filter_scroll.position != target_rect.position or filter_scroll.size != target_rect.size:
		_set_rect(filter_scroll, target_rect)
	var bar := filter_scroll.get_h_scroll_bar()
	var max_scroll := maxi(0, int(bar.max_value - bar.page)) if bar != null else 0
	filter_previous_button.visible = show_navigation
	filter_next_button.visible = show_navigation
	if not show_navigation:
		return
	filter_previous_button.disabled = filter_scroll.scroll_horizontal <= 0
	filter_next_button.disabled = filter_scroll.scroll_horizontal >= max_scroll
	_apply_image_button_surface(filter_previous_button, &"filter", &"normal")
	_apply_image_button_surface(filter_next_button, &"filter", &"normal")


func _set_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position.round()
	control.size = rect.size.round()


func _clear_container(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _focus_is_inside(parent: Node) -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	return focus != null and parent.is_ancestor_of(focus)


func _buttons_from_dictionary(source: Dictionary) -> Array:
	var result := []
	for value in source.values():
		if value is Button:
			result.append(value)
	return result


func _card_focus_buttons() -> Array:
	var result := []
	for view in card_views:
		if view != null and is_instance_valid(view):
			var button: Variant = view.call("focus_button")
			if button is Button:
				result.append(button)
	return result


func _array_from(source: Variant, key: String = "") -> Array:
	var raw: Variant = source.get(key, []) if source is Dictionary and key != "" else source
	return (raw as Array).duplicate(true) if raw is Array else []


func _normalized_string_ids(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is not Array:
		return result
	for raw_id in value:
		var normalized := str(raw_id).strip_edges()
		if normalized.is_empty() or normalized in result:
			continue
		result.append(normalized)
	result.sort()
	return result


func _dictionary_from(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}
