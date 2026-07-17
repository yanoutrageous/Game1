extends Control
class_name DeployPrepShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const DeployPrepModelScript := preload("res://scripts/ui/deploy_prep/deploy_prep_model.gd")
const DeployTabModelScript := preload("res://scripts/ui/deploy_prep/deploy_tab_model.gd")
const DeployPrepCardViewScript := preload("res://scripts/ui/deploy_prep/deploy_prep_card_view.gd")
const DeployPrepLayoutContractScript := preload("res://scripts/ui/deploy_prep/deploy_prep_layout_contract.gd")
const RunStartRouteAdapterScript := preload("res://scripts/core/run/run_start_route_adapter.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21MainMenuAssetContractScript := preload("res://scripts/presentation/art21_main_menu_asset_contract.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const Art22DeployPrepAssetContractScript := preload("res://scripts/presentation/art22_deploy_prep_asset_contract.gd")

signal deploy_start_intent_requested(intent: Dictionary)
signal navigation_intent_requested(intent: Dictionary)

const SUMMARY_PAGES := [
	{"id": &"summary", "label": "摘要"},
	{"id": &"config", "label": "配置"},
	{"id": &"effect", "label": "效果"},
	{"id": &"risk", "label": "风险"},
]
const CHARACTER_IDLE_SEQUENCE := [0, 0, 1, 1, 2, 1, 0, 0, 3, 3, 0, 4, 5, 4, 0, 0]
const CHARACTER_LOOK_SEQUENCE := [0, 6, 6, 7, 7, 6, 0]
const CHARACTER_IDLE_FRAME_SECONDS := 0.34
const CHARACTER_LOOK_FRAME_SECONDS := 0.42
const CHARACTER_FIRST_LOOK_SECONDS := 5.0
const CHARACTER_LOOK_INTERVAL_SECONDS := 10.0

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
var result_hint_panel: Panel
var result_hint_label: Label
var collapse_button: Button
var primary_action_button: Button
var cancel_action_button: Button
var summary_body_label: Label
var summary_message_label: Label
var summary_row_labels: Array[Label] = []
var modal_layer: Control
var modal_cancel_button: Button
var modal_confirm_button: Button
var character_texture: TextureRect
var character_frames: Array[Texture2D] = []
var ambient_animations: Array[Dictionary] = []
var ambient_particles: Array[CPUParticles2D] = []
var summary_chain_bases: Dictionary = {}

var active_summary_page: StringName = &"summary"
var parchment_collapsed := false
var reduced_motion := false
var scene_elapsed := 0.0
var character_elapsed := 0.0
var character_frame_index := 0
var character_look_index := -1
var next_character_look := CHARACTER_FIRST_LOOK_SECONDS
var focus_before_modal: Control
var collapse_tween: Tween


func build(model: Dictionary = {}) -> void:
	_clear_children()
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
	_refresh_all(true)
	set_process(not reduced_motion)
	set_process_unhandled_input(true)
	call_deferred("_grab_initial_focus")


func apply_snapshot(snapshot: Dictionary) -> void:
	_save_active_view_state()
	current_snapshot = snapshot.duplicate(true)
	var previous_tab := _active_tab()
	current_model = DeployPrepModelScript.build(current_snapshot)
	current_model = DeployPrepModelScript.model_with_tab(current_model, previous_tab)
	_restore_model_state(previous_tab)
	_refresh_all(true)


func show_tab(tab_id: StringName) -> void:
	var normalized := _normalize_tab_id(tab_id)
	if current_model.is_empty():
		current_model = DeployPrepModelScript.build(current_snapshot)
	if normalized == _active_tab():
		_refresh_all(false)
		return
	_save_active_view_state()
	current_model = DeployPrepModelScript.model_with_tab(current_model, normalized)
	_restore_model_state(normalized)
	_refresh_all(true)
	if not reduced_motion and card_scroll != null:
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
	var duration := 0.0 if reduced_motion or not animate else 0.28
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
	character_texture = null
	focus_before_modal = null
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
	for index in range(8):
		var frame := Art21MainMenuAssetContractScript.texture(StringName("main_menu.scene.character.idle.%02d" % index))
		if frame != null:
			character_frames.append(frame)
	var initial: Texture2D = character_frames[0] if not character_frames.is_empty() else null
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
	card_list.custom_minimum_size.x = 612
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


func _build_summary_board() -> void:
	var root := _root(&"SideStatusRoot")
	summary_button_group.allow_unpress = false
	_add_texture(root, "DeploySummaryBoard", DeployPrepLayoutContractScript.SUMMARY_BOARD, &"deploy_prep.panel.summary_board", 0)
	_add_label(root, "DeploySummaryTitle", Rect2(1006, 64, 208, 34), "出发摘要", 21, Color(0.96, 0.77, 0.38), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 1)
	var tab_rect := DeployPrepLayoutContractScript.SUMMARY_TABS
	var width := tab_rect.size.x / float(SUMMARY_PAGES.size())
	for index in range(SUMMARY_PAGES.size()):
		var page := SUMMARY_PAGES[index] as Dictionary
		var page_id := StringName(page.get("id", &"summary"))
		var rect := Rect2(tab_rect.position + Vector2(index * width, 0), Vector2(width, tab_rect.size.y))
		var captured := page_id
		var button := _add_image_button(root, "DeploySummaryTab_%s" % String(page_id), rect, String(page.get("label", page_id)), &"filter", func() -> void: _show_summary_page(captured), 13)
		button.toggle_mode = true
		button.button_group = summary_button_group
		summary_buttons[page_id] = button
	for index in range(DeployPrepLayoutContractScript.SUMMARY_ROW_RECTS.size()):
		var row_rect := DeployPrepLayoutContractScript.SUMMARY_ROW_RECTS[index] as Rect2
		_add_image_panel(root, "DeploySummaryRowPanel%d" % index, row_rect, &"slot", &"normal", 1)
		var row_label := _add_label(root, "DeploySummaryRow%d" % index, Rect2(row_rect.position + Vector2(12, 8), row_rect.size - Vector2(24, 16)), "", 14, Color(0.94, 0.87, 0.72), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 2)
		row_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row_label.clip_text = true
		summary_row_labels.append(row_label)
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
	var body := _add_label(modal_layer, "DeployCancelModalBody", DeployPrepLayoutContractScript.MODAL_BODY, "当前运行的真实结算与放弃接口尚未接入。\n本窗口只展示强确认边界，不会删除进度。", 16, Color(0.94, 0.88, 0.76), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 2)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_confirm_button = _add_image_button(modal_layer, "DeployCancelModalConfirm", DeployPrepLayoutContractScript.MODAL_CONFIRM, "尚未接入", &"danger", Callable(), 16)
	modal_confirm_button.disabled = true
	_apply_image_button_surface(modal_confirm_button, &"danger", &"disabled")
	modal_cancel_button = _add_image_button(modal_layer, "DeployCancelModalBack", DeployPrepLayoutContractScript.MODAL_CANCEL, "返回", &"nav", _hide_cancel_modal, 16)


func _refresh_all(rebuild_lists: bool) -> void:
	if current_model.is_empty() or parchment_group == null:
		return
	_refresh_tab_buttons()
	if rebuild_lists:
		_rebuild_filters()
		_rebuild_cards()
	else:
		_refresh_filter_buttons()
		_refresh_card_selection()
	_refresh_summary()
	_refresh_actions()
	_refresh_modal_state()
	_wire_focus_neighbors()


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
	_clear_container(filter_row)
	filter_buttons.clear()
	filter_button_group = ButtonGroup.new()
	filter_button_group.allow_unpress = false
	var tab := _dictionary_from(current_model.get("active_tab_data", {}))
	var filters := _array_from(tab, "secondary_filters")
	var filter_width := DeployPrepLayoutContractScript.FILTER_WIDTH
	if filters.size() <= 6 and not filters.is_empty():
		filter_width = floor((DeployPrepLayoutContractScript.FILTER_SCROLL.size.x - float((filters.size() - 1) * DeployPrepLayoutContractScript.FILTER_GAP)) / float(filters.size()))
	for raw_filter in filters:
		var filter := _dictionary_from(raw_filter)
		var filter_id := StringName(filter.get("id", DeployTabModelScript.FILTER_ALL))
		var filter_label := String(filter.get("label", filter_id))
		var captured := filter_id
		var resolved_width := filter_width if filters.size() <= 6 else _long_filter_width(filter_label)
		var button := _add_container_image_button(filter_row, "DeployFilter_%s" % String(filter_id), Vector2(resolved_width, 34), filter_label, &"filter", func() -> void: _on_filter_pressed(captured), 13 if filters.size() > 6 else 14)
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
	for raw_card in _array_from(current_model, "visible_cards"):
		var card := _dictionary_from(raw_card)
		var card_id := StringName(card.get("id", &""))
		var view := DeployPrepCardViewScript.new() as Control
		view.name = "DeployCard_%s" % String(card_id)
		card_list.add_child(view)
		view.call("setup", card, active, card_id == selected_card)
		view.connect("card_pressed", _on_card_pressed)
		card_views.append(view)
	if result_hint_panel != null and result_hint_label != null:
		var show_hint := card_views.size() <= 1
		result_hint_panel.visible = show_hint
		result_hint_label.visible = show_hint
		result_hint_label.text = "当前筛选显示 %d 项 · 可切换上方分类" % card_views.size()
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
	for index in range(summary_row_labels.size()):
		summary_row_labels[index].text = String(blocks[index]) if index < blocks.size() else ""
	if summary_message_label != null:
		var message := Art10UISkinKitScript.short_summary(String(current_model.get("action_message", "")), 24)
		if message.is_empty():
			message = "运行状态\n%s" % ("探索进行中" if _has_active_run() else "可确认出发")
		summary_message_label.text = message


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
	if button != null:
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
	current_model = DeployPrepModelScript.model_with_card(current_model, card_id)
	var state := _state_for_tab(_active_tab())
	state["card"] = card_id
	state["scroll"] = scroll_value
	view_state_by_tab[String(_active_tab())] = state
	_refresh_all(false)
	for view in card_views:
		if view != null and is_instance_valid(view) and StringName(view.get("card_id")) == card_id:
			Art10UISkinKitScript.play_feedback_pulse(view, &"success", 0.22)
			break
	if card_scroll != null:
		card_scroll.scroll_vertical = scroll_value


func _on_primary_action_pressed() -> void:
	if _has_active_run():
		current_model = DeployPrepModelScript.model_with_action_message(current_model, "已检测到进行中的探索；继续接口尚未连接到持久化运行。")
		_refresh_summary()
		Art10UISkinKitScript.play_feedback_pulse(primary_action_button, &"warning", 0.7)
		return
	var config := _config()
	current_model["run_start_config"] = DeployConfigScript.build_run_start_config(config)
	current_model["preview_lines"] = DeployConfigScript.build_preview_lines(config)
	current_model["action_message"] = "已使用当前携带配置进入探索。"
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
	current_model = DeployPrepModelScript.model_with_action_message(current_model, "取消探索需要强确认；当前不会执行真实结算。", true)
	_refresh_modal_state()
	_refresh_summary()


func _hide_cancel_modal() -> void:
	current_model = DeployPrepModelScript.model_with_action_message(current_model, "已关闭取消确认，没有修改当前运行。", false)
	_refresh_modal_state()
	_refresh_summary()


func _show_cancel_modal_visual() -> void:
	if modal_layer == null:
		return
	focus_before_modal = get_viewport().gui_get_focus_owner()
	modal_layer.visible = true
	Art10UISkinKitScript.play_panel_open(modal_layer)
	if modal_cancel_button != null:
		modal_cancel_button.grab_focus()


func _hide_cancel_modal_visual() -> void:
	if modal_layer == null:
		return
	modal_layer.visible = false
	if focus_before_modal != null and is_instance_valid(focus_before_modal) and focus_before_modal.is_visible_in_tree():
		focus_before_modal.grab_focus()
	elif cancel_action_button != null and cancel_action_button.visible:
		cancel_action_button.grab_focus()


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
		&"goals",
		{"source_page": &"deploy_prep", "preview_only": false}
	))


func _request_appearance() -> void:
	navigation_intent_requested.emit(NavigationIntentScript.make_long_term(
		&"deploy_prep",
		&"collection_appearance",
		{"source_page": &"deploy_prep", "preview_only": false}
	))


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if reduced_motion:
		_freeze_motion()
		return
	scene_elapsed += delta
	_update_character_motion(delta)
	_update_ambient_animations(delta)
	_update_summary_sway()


func _update_character_motion(delta: float) -> void:
	if character_texture == null or character_frames.size() < 8:
		return
	if character_look_index < 0 and scene_elapsed >= next_character_look:
		character_look_index = 0
		character_elapsed = 0.0
	character_elapsed += delta
	var frame_seconds := CHARACTER_LOOK_FRAME_SECONDS if character_look_index >= 0 else CHARACTER_IDLE_FRAME_SECONDS
	if character_elapsed < frame_seconds:
		return
	character_elapsed = fmod(character_elapsed, frame_seconds)
	if character_look_index >= 0:
		var look_frame := int(CHARACTER_LOOK_SEQUENCE[character_look_index])
		character_texture.texture = character_frames[look_frame]
		character_look_index += 1
		if character_look_index >= CHARACTER_LOOK_SEQUENCE.size():
			character_look_index = -1
			character_frame_index = 0
			next_character_look = scene_elapsed + CHARACTER_LOOK_INTERVAL_SECONDS
		return
	character_frame_index = (character_frame_index + 1) % CHARACTER_IDLE_SEQUENCE.size()
	var idle_frame := int(CHARACTER_IDLE_SEQUENCE[character_frame_index])
	character_texture.texture = character_frames[idle_frame]


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
		character_texture.texture = character_frames[0]
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


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event.is_action_pressed("ui_cancel"):
		return
	if modal_layer != null and modal_layer.visible:
		_hide_cancel_modal()
	else:
		_request_back_to_main()
	get_viewport().set_input_as_handled()


func _summary_page_blocks(page_id: StringName) -> Array[String]:
	var preview := _dictionary_from(current_model.get("preview_lines", {}))
	var config := _config()
	match page_id:
		&"summary":
			return [
				"当前选择\n%s" % Art10UISkinKitScript.short_summary(String(_dictionary_from(current_model.get("selected_card_detail", {})).get("title", "当前选择")), 16),
				"路线 / 难度\n%s · %s" % [_localized_route(String(config.get("map_mode_label", ""))), _localized_difficulty(String(config.get("difficulty_label", "")))],
				"区域 / 目标\n%s · %s" % [_localized_region(String(config.get("region_label", ""))), _localized_objective(String(config.get("selected_objective_label", "")))],
				"携带状态\n背包 %d / %d" % [int(config.get("bag_used", 0)), int(config.get("bag_limit", 0))],
			]
		&"config":
			var warehouse := _dictionary_from(config.get("warehouse_attendance_preview", {}))
			return [
				"装备\n%d 件已配置" % _array_from(config.get("selected_equipment_items", [])).size(),
				"消耗品\n%d 件已携带" % _array_from(config.get("selected_consumable_items", [])).size(),
				"背包 / 仓库\n%d / %d · 仓库 %d 件" % [int(config.get("bag_used", 0)), int(config.get("bag_limit", 0)), int(warehouse.get("item_count", 0))],
				"档案接口\n许可 %d · 协议 %d" % [int(config.get("permit_level", 1)), int(config.get("protocol_difficulty", 0))],
			]
		&"effect":
			return _summary_blocks_from_preview("本局效果", _array_from(preview, "effect"))
		&"risk":
			return _summary_blocks_from_preview("风险确认", _array_from(preview, "risk"))
	return ["暂无信息", "", "", ""]


func _summary_blocks_from_preview(heading: String, source: Array) -> Array[String]:
	var lines := _compact_preview_lines(source)
	var result: Array[String] = []
	for index in range(4):
		var label := heading if index == 0 else "第 %d 项" % (index + 1)
		var value := lines[index].trim_prefix("· ") if index < lines.size() else "暂无"
		result.append("%s\n%s" % [label, value])
	return result


func _compact_preview_lines(source: Array) -> Array[String]:
	var result: Array[String] = []
	for raw_line in source.slice(0, 5):
		var line := Art10UISkinKitScript.sanitize_player_copy(String(raw_line)).strip_edges()
		if not line.is_empty():
			result.append("· %s" % Art10UISkinKitScript.short_summary(line, 22))
	return result


func _localized_route(value: String) -> String:
	return "常规扫雷" if value.to_lower().find("classic") >= 0 else Art10UISkinKitScript.short_summary(value, 12)


func _localized_difficulty(value: String) -> String:
	return "普通" if value.to_lower() == "normal" else Art10UISkinKitScript.short_summary(value, 8)


func _localized_region(value: String) -> String:
	return "灰尾外围" if value.to_lower().find("graytail") >= 0 else Art10UISkinKitScript.short_summary(value, 10)


func _localized_objective(value: String) -> String:
	return "回收补给箱" if value.to_lower().find("recover") >= 0 else Art10UISkinKitScript.short_summary(value, 10)


func _wire_focus_neighbors() -> void:
	_wire_linear(_buttons_from_dictionary(tab_buttons), false)
	_wire_linear(_buttons_from_dictionary(filter_buttons), false)
	_wire_linear(_card_focus_buttons(), true)
	_wire_linear(_buttons_from_dictionary(summary_buttons), false)
	if modal_confirm_button != null and modal_cancel_button != null:
		_link_horizontal(modal_confirm_button, modal_cancel_button)
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


func _grab_initial_focus() -> void:
	if not is_visible_in_tree():
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
	for raw_card in _array_from(current_model, "visible_cards"):
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
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.clip_text = true
	button.z_index = 3
	Art10UISkinKitScript.apply_button(button, &"secondary", font_size, &"button")
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
	button.add_theme_stylebox_override("hover", _button_style(control_id, &"focused"))
	button.add_theme_stylebox_override("focus", _button_style(control_id, &"focused"))
	var pressed_state := &"selected" if normal_state == &"selected" else &"pressed"
	button.add_theme_stylebox_override("pressed", _button_style(control_id, pressed_state))
	button.add_theme_stylebox_override("hover_pressed", _button_style(control_id, pressed_state))
	button.add_theme_stylebox_override("disabled", _button_style(control_id, &"disabled"))
	var dark_text := control_id in [&"tab", &"filter", &"handle"] and normal_state != &"selected"
	var color := Color(0.20, 0.12, 0.07) if dark_text else Color(0.98, 0.86, 0.58)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color.lightened(0.12))
	button.add_theme_color_override("font_focus_color", color.lightened(0.12))
	button.add_theme_color_override("font_pressed_color", color if normal_state == &"selected" else color.darkened(0.12))
	button.add_theme_color_override("font_disabled_color", Color(color.r, color.g, color.b, 0.46))


func _button_style(control_id: StringName, state: StringName) -> StyleBox:
	var padding := 7
	var texture_margin := 12
	match control_id:
		&"nav": texture_margin = 18
		&"action": texture_margin = 24
		&"danger": texture_margin = 18
		&"tab": texture_margin = 12
		&"filter": texture_margin = 10
		&"handle": texture_margin = 12
	return Art10UISkinKitScript.style_box_from_asset_ref(
		Art22DeployPrepAssetContractScript.control_ref(control_id, state),
		padding,
		texture_margin
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
	Art10UISkinKitScript.apply_label(label, font_size, color)
	_set_rect(label, rect)
	parent.add_child(label)
	return label


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
	var show_navigation := filter_buttons.size() > 6
	filter_previous_button.visible = show_navigation
	filter_next_button.visible = show_navigation
	if not show_navigation:
		return
	var bar := filter_scroll.get_h_scroll_bar()
	var max_scroll := maxi(0, int(bar.max_value - bar.page)) if bar != null else 0
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


func _dictionary_from(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}
