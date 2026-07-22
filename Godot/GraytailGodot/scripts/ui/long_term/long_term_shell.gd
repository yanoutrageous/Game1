extends Control
class_name LongTermShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const LongTermModelScript := preload("res://scripts/ui/long_term/long_term_model.gd")
const LongTermTabModelScript := preload("res://scripts/ui/long_term/long_term_tab_model.gd")
const LongTermContentFrameworkScript := preload("res://scripts/ui/long_term/long_term_content_framework.gd")
const LongTermLayoutContractScript := preload("res://scripts/ui/long_term/long_term_layout_contract.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21MainMenuAssetContractScript := preload("res://scripts/presentation/art21_main_menu_asset_contract.gd")
const Art23LongTermAssetContractScript := preload("res://scripts/presentation/art23_long_term_asset_contract.gd")
const Art25ContentAssetContractScript := preload("res://scripts/presentation/art25_content_asset_contract.gd")
const LongTermContentCardViewScript := preload("res://scripts/ui/long_term/long_term_content_card_view.gd")
const LongTermReadableFont := preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

signal navigation_intent_requested(intent: Dictionary)
signal meta_action_requested(action: Dictionary)

const STATE_CLOSED := &"CLOSED"
const STATE_OPENING := &"OPENING"
const STATE_OPEN := &"OPEN"
const STATE_CLOSING := &"CLOSING"
const STATE_SWITCHING := &"SWITCHING"

const MODULE_IDS: Array[StringName] = [
	&"task_archive", &"codex", &"research", &"profile", &"collection_appearance",
]
const MODULE_LABELS := {
	&"task_archive": "任务档案",
	&"codex": "图鉴",
	&"research": "研究",
	&"profile": "角色",
	&"collection_appearance": "收藏外观",
}
const LOCKED_MODULES: Dictionary = {}
const CHARACTER_IDLE_SEQUENCE := [0, 0, 1, 1, 2, 1, 0, 0, 3, 3, 0, 4, 5, 4, 0, 0]
const CHARACTER_LOOK_SEQUENCE := [0, 6, 6, 7, 7, 6, 0]
const CHARACTER_IDLE_FRAME_SECONDS := 0.34
const CHARACTER_LOOK_FRAME_SECONDS := 0.42
const CHARACTER_FIRST_LOOK_SECONDS := 5.0
const CHARACTER_LOOK_INTERVAL_SECONDS := 10.0
const CANCEL_DEBOUNCE_MSEC := 600

const PAGE_COPY := {
	"task_archive/task": "当前任务按顺序推进；达成后在这里手动领取奖励。",
	"task_archive/achievement": "成就由真实探索记录判定；达成后在这里手动领取奖励。",
	"task_archive/commission_record": "回看每局真实委托结果；本页不改变下一局选择。",
	"codex/map": "永久归档已经进入过的地图；未知地图保持遮蔽。",
	"codex/monster": "永久归档已经遭遇或通过研究解析的怪物。",
	"codex/collectible": "按曾经成功回收的藏品登记，出售实体不会抹除发现。",
	"codex/equipment": "记录已经接触的装备；本页不改变出勤配置。",
	"codex/consumable": "记录已经接触的补给；本页不会消耗仓库物品。",
	"codex/event": "归档已经完成的旅商、骰子局、祭坛和机关遭遇。",
	"codex/rule": "显示已公开或通过研究解读的真实游戏规则。",
	"codex/lore": "保存世界背景与文本线索；未知条目维持未发现状态。",
	"research/unlock_interface": "研究会原子地消耗金币与一件指定仓库材料，并立即开放对应内容。",
	"research/research_entry": "选择课题后使用确认按钮提交；材料若正在出勤配置中则不会被消耗。",
	"profile/qualification_level": "展示真实资历等级与绝对经验值；没有阈值时不伪造百分比。",
	"profile/history": "读取最近结算与历史快照，不写入或重算历史记录。",
	"profile/statistics": "汇总探索、撤离、失败和长期金币等已存在统计。",
	"profile/milestone": "展示真实资历阈值及距离下一阶段所需经验。",
	"profile/title": "展示已经由资历等级永久授予的称号。",
	"profile/badge": "展示已经由资历等级永久授予的徽章。",
	"collection_appearance/unique_display": "展示三组真实藏品收集进度；出售物品不降低历史收集。",
	"collection_appearance/appearance_config": "外观配置入口已落位；真实换装保存未接入时保持只读。",
	"collection_appearance/display_content": "展示三组各 8 件藏品的永久收集进度。",
	"collection_appearance/badge_title": "组合展示已经获得的徽章与称号。",
	"collection_appearance/settlement_display": "预览结算卡面和历史引用，不修改结算快照。",
}

var current_model: Dictionary = {}
var current_app_snapshot: Dictionary = {}
var selected_module_id: StringName = &"task_archive"
var displayed_module_id: StringName = &"task_archive"
var selected_secondary_by_module: Dictionary = {}
var texture_cache: Dictionary = {}

var tab_buttons: Dictionary = {}
var tab_button_order: Array[Button] = []
var secondary_buttons: Dictionary = {}
var secondary_button_order: Array[Button] = []
var long_term_card_buttons: Array[Button] = []

var module_group: Control
var furniture_texture: TextureRect
var secondary_scroll: ScrollContainer
var secondary_row: HBoxContainer
var content_panel_texture: TextureRect
var content_detail_title_label: Label
var content_detail_body_label: Label
var content_detail_meta_label: Label
var module_title_label: Label
var module_state_label: Label
var module_body_label: Label
var module_reason_label: Label
var overview_label: Label
var child_preview_label: Label
var snapshot_label: Label
var interface_preview_label: Label
var history_preview_label: Label
var next_stage_label: Label
var card_grid_container: HBoxContainer
var content_action_button: Button
var content_previous_button: Button
var content_next_button: Button
var current_content_cards: Array[Dictionary] = []
var selected_content_card_index := 0
var content_card_page_by_group: Dictionary = {}

var profile_level_label: Label
var profile_exp_value_label: Label
var profile_stat_labels: Array[Label] = []
var character_texture: TextureRect
var character_frames: Array[Texture2D] = []
var lever_texture: TextureRect
var lever_button: Button
var lever_label: Label

var transition_state: StringName = STATE_OPEN
var requested_module_id: StringName = &"task_archive"
var switch_running := false
var archive_collapsed := false
var archive_context_module_id: StringName = &"task_archive"
var archive_context_secondary_id: StringName = &"task"
var reduced_motion := false
var module_tween: Tween
var collapse_tween: Tween
var content_tween: Tween
var page_active := true
var lifecycle_generation := 0
var character_elapsed := 0.0
var character_frame_index := 0
var character_look_index := -1
var next_character_look := CHARACTER_FIRST_LOOK_SECONDS
var ambient_elapsed := 0.0
var last_cancel_press_msec := -CANCEL_DEBOUNCE_MSEC
var warm_glow: ColorRect
var blue_glow: ColorRect
var ambient_particles: Array[CPUParticles2D] = []


func build(model: Dictionary = {}) -> void:
	_clear_children()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_model = model.duplicate(true) if not model.is_empty() else LongTermModelScript.build(selected_module_id)
	selected_module_id = _normalize_module_id(StringName(current_model.get("selected_module_id", selected_module_id)))
	displayed_module_id = selected_module_id
	requested_module_id = selected_module_id
	reduced_motion = Art10UISkinKitScript.reduce_motion_enabled()
	_seed_secondary_selection()
	_build_background()
	_build_ambient_motion()
	_build_navigation()
	_build_module_rail()
	_build_module_group()
	_build_profile_column()
	_build_archive_lever()
	_apply_module_immediately(displayed_module_id)
	_refresh_profile()
	set_page_active(true)
	call_deferred("_grab_long_term_initial_focus")


func apply_snapshot(snapshot: Dictionary) -> void:
	current_app_snapshot = snapshot.duplicate(true)
	current_model = LongTermModelScript.build_from_snapshot(selected_module_id, current_app_snapshot, &"app_shell_snapshot_preview")
	_refresh_profile()
	_refresh_content()


func set_page_active(value: bool) -> void:
	var was_active := page_active
	page_active = value
	if page_active:
		process_mode = Node.PROCESS_MODE_INHERIT
		set_process(not reduced_motion)
		set_process_input(true)
		set_process_unhandled_input(true)
		for particles in ambient_particles:
			if particles != null:
				particles.emitting = not reduced_motion
		if reduced_motion:
			_apply_reduced_motion_pose()
		if is_visible_in_tree():
			call_deferred("_grab_long_term_initial_focus")
		return
	set_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	if was_active:
		lifecycle_generation += 1
	if module_tween != null and module_tween.is_valid():
		module_tween.kill()
	if collapse_tween != null and collapse_tween.is_valid():
		collapse_tween.kill()
	if content_tween != null and content_tween.is_valid():
		content_tween.kill()
	if module_group != null:
		_apply_module_immediately(requested_module_id)
		module_group.position = LongTermLayoutContractScript.COLLAPSED_OFFSET if archive_collapsed else Vector2.ZERO
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
			_settle_motion_transitions()
		if page_active:
			set_process(not reduced_motion)
		for particles in ambient_particles:
			if particles != null:
				particles.emitting = page_active and not reduced_motion
		return
	reduced_motion = value
	if reduced_motion:
		lifecycle_generation += 1
		_settle_motion_transitions()
		_apply_reduced_motion_pose()
	if page_active:
		set_process(not reduced_motion)
	for particles in ambient_particles:
		if particles != null:
			particles.emitting = page_active and not reduced_motion


func is_reduced_motion_enabled() -> bool:
	return reduced_motion


func _settle_motion_transitions() -> void:
	if module_tween != null and module_tween.is_valid():
		module_tween.kill()
	if collapse_tween != null and collapse_tween.is_valid():
		collapse_tween.kill()
	if content_tween != null and content_tween.is_valid():
		content_tween.kill()
	if module_group != null:
		_apply_module_immediately(requested_module_id)
		module_group.position = LongTermLayoutContractScript.COLLAPSED_OFFSET if archive_collapsed else Vector2.ZERO
	for node in _content_transition_nodes():
		node.modulate = Color.WHITE


func _apply_reduced_motion_pose() -> void:
	if character_texture != null and not character_frames.is_empty():
		character_texture.texture = character_frames[0]
	if warm_glow != null:
		warm_glow.modulate.a = 0.52
	if blue_glow != null:
		blue_glow.modulate.a = 0.42
	for particles in ambient_particles:
		if particles != null:
			particles.emitting = false


func show_module(module_id: StringName = &"task_archive") -> void:
	var normalized := _normalize_module_id(module_id)
	selected_module_id = normalized
	requested_module_id = normalized
	_refresh_module_buttons()
	call_deferred("_mark_current_module_viewed", normalized)
	if not page_active or not is_inside_tree() or reduced_motion:
		_apply_module_immediately(normalized)
		return
	if normalized == displayed_module_id and transition_state == STATE_OPEN:
		_refresh_content()
		return
	if not switch_running:
		_run_switch_sequence()


func show_secondary(group_id: StringName) -> void:
	var normalized := _normalize_secondary_id(displayed_module_id, group_id)
	selected_secondary_by_module[displayed_module_id] = normalized
	_refresh_secondary_buttons()
	_refresh_content()
	if page_active and not reduced_motion and content_panel_texture != null:
		if content_tween != null and content_tween.is_valid():
			content_tween.kill()
		content_tween = create_tween()
		content_tween.set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		for node in _content_transition_nodes():
			node.modulate.a = 0.72
			content_tween.tween_property(node, "modulate:a", 1.0, 0.16)


func get_selected_module_id() -> StringName:
	return selected_module_id


func get_selected_secondary_id() -> StringName:
	return StringName(selected_secondary_by_module.get(displayed_module_id, &""))


func get_secondary_ids(module_id: StringName = &"") -> Array[StringName]:
	var target := displayed_module_id if module_id == &"" else _normalize_module_id(module_id)
	var result: Array[StringName] = []
	for group: Dictionary in _secondary_groups(target):
		result.append(StringName(group.get("group_id", group.get("id", &""))))
	return result


func set_archive_collapsed(value: bool, animate: bool = true) -> void:
	var was_collapsed := archive_collapsed
	if value and not was_collapsed:
		# Preserve the latest requested visual context, not merely the module that
		# happened to be on screen at an intermediate animation frame.
		archive_context_module_id = requested_module_id if switch_running else displayed_module_id
		archive_context_secondary_id = StringName(selected_secondary_by_module.get(
			archive_context_module_id,
			_normalize_secondary_id(archive_context_module_id, &"")
		))
	archive_collapsed = value
	if collapse_tween != null and collapse_tween.is_valid():
		collapse_tween.kill()
	var target := LongTermLayoutContractScript.COLLAPSED_OFFSET if value else Vector2.ZERO
	var duration := 0.0 if not page_active or reduced_motion or not animate else 0.30
	if duration <= 0.0:
		module_group.position = target
	else:
		collapse_tween = create_tween()
		collapse_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		collapse_tween.tween_property(module_group, "position", target, duration)
	_update_lever()
	if not value and was_collapsed:
		# Expanding must restore the exact module/page that was collapsed.  This
		# also reconciles routes initiated from the fixed profile column.
		selected_secondary_by_module[archive_context_module_id] = archive_context_secondary_id
		show_module(archive_context_module_id)
	if value and _focus_is_inside(module_group) and lever_button != null:
		lever_button.grab_focus()


func _process(delta: float) -> void:
	if not page_active or not is_visible_in_tree():
		return
	ambient_elapsed += delta
	_update_character(delta)
	if warm_glow != null:
		warm_glow.modulate.a = 0.52 + sin(ambient_elapsed * 2.1) * 0.10
	if blue_glow != null:
		blue_glow.modulate.a = 0.42 + sin(ambient_elapsed * 1.35 + 1.7) * 0.08


func _input(event: InputEvent) -> void:
	if not page_active or not is_visible_in_tree() or not event.is_action_pressed("ui_cancel"):
		return
	# A single Windows Escape gesture can surface as multiple pressed events.
	# Keep it to one staged navigation step: expand -> secondary -> primary -> main.
	if _cancel_press_is_debounced(Time.get_ticks_msec()):
		get_viewport().set_input_as_handled()
		return
	_handle_cancel_focus_step()
	get_viewport().set_input_as_handled()


func _cancel_press_is_debounced(now_msec: int) -> bool:
	if now_msec - last_cancel_press_msec < CANCEL_DEBOUNCE_MSEC:
		return true
	last_cancel_press_msec = now_msec
	return false


func _handle_cancel_focus_step() -> StringName:
	var focus := get_viewport().gui_get_focus_owner()
	if archive_collapsed:
		set_archive_collapsed(false)
		return &"expanded"
	if focus in long_term_card_buttons and not secondary_button_order.is_empty():
		var selected_secondary := get_selected_secondary_id()
		var secondary_button := secondary_buttons.get(selected_secondary, secondary_button_order[0]) as Button
		if secondary_button != null:
			secondary_button.grab_focus()
		return &"secondary"
	if focus in secondary_button_order:
		var module_button := tab_buttons.get(selected_module_id, null) as Button
		if module_button != null:
			module_button.grab_focus()
		return &"primary"
	_request_back_to_main()
	return &"main_menu"


func _build_background() -> void:
	_add_color_rect(self, "LongTermBackdrop", Rect2(0, 0, 1280, 720), Color(0.01, 0.01, 0.01, 1.0))
	_add_texture(self, "LongTermSceneCleanPlate", Rect2(0, 0, 1280, 720), _texture(&"long_term.scene.background.clean_plate"), false)


func _build_ambient_motion() -> void:
	warm_glow = _add_color_rect(self, "LongTermWarmLanternGlow", Rect2(1106, 137, 38, 70), Color(1.0, 0.50, 0.16, 0.09))
	blue_glow = _add_color_rect(self, "LongTermBlueResearchGlow", Rect2(506, 226, 34, 48), Color(0.14, 0.82, 0.94, 0.10))
	_add_particles("LongTermArchiveDust", Vector2(670, 414), Vector2(640, 330), 18, Color(0.86, 0.72, 0.47, 0.28), Vector2(2, -6), 7.0)
	_add_particles("LongTermBlueMotes", Vector2(520, 278), Vector2(90, 70), 8, Color(0.22, 0.84, 1.0, 0.34), Vector2(0, -9), 4.8)


func _build_navigation() -> void:
	_add_texture(self, "LongTermNavChain", LongTermLayoutContractScript.NAV_CHAIN, _texture(&"long_term.decoration.chain"), false)
	_add_image_button(self, "LongTermNavMainButton", LongTermLayoutContractScript.NAV_MAIN, "主菜单", &"nav", _request_back_to_main, 17)
	_add_image_button(self, "LongTermNavDeployButton", LongTermLayoutContractScript.NAV_DEPLOY, "出发探索", &"nav", _request_deploy, 17)


func _build_module_rail() -> void:
	_add_texture(self, "LongTermModuleRail", LongTermLayoutContractScript.MODULE_RAIL, _texture(&"long_term.decoration.rail"), false)
	tab_buttons.clear()
	tab_button_order.clear()
	for index in range(MODULE_IDS.size()):
		var module_id := MODULE_IDS[index]
		var button := Button.new()
		button.name = "LongTermTab_%s" % String(module_id)
		button.text = String(MODULE_LABELS.get(module_id, module_id))
		button.position = LongTermLayoutContractScript.module_button_rect(index).position
		button.size = LongTermLayoutContractScript.MODULE_BUTTON_SIZE
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(Callable(self, "_on_module_tab_pressed").bind(module_id))
		_apply_module_button_surface(button, module_id, false)
		add_child(button)
		tab_buttons[module_id] = button
		tab_button_order.append(button)
	_wire_long_term_tab_focus()


func _build_module_group() -> void:
	module_group = Control.new()
	module_group.name = "LongTermModuleGroup"
	module_group.position = Vector2.ZERO
	module_group.size = Vector2(1000, 720)
	module_group.pivot_offset = Vector2(500, 360)
	# This transparent root is created after the top module rail. Ignore hits on
	# the root itself so it cannot cover the six primary buttons; interactive
	# descendants retain their own mouse filters.
	module_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(module_group)

	furniture_texture = _add_texture(module_group, "LongTermModuleFurniture", LongTermLayoutContractScript.furniture_rect(displayed_module_id), null, true)
	secondary_scroll = ScrollContainer.new()
	secondary_scroll.name = "LongTermSecondaryScroll"
	secondary_scroll.position = LongTermLayoutContractScript.SECONDARY_SCROLL.position
	secondary_scroll.size = LongTermLayoutContractScript.SECONDARY_SCROLL.size
	secondary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	secondary_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	secondary_scroll.follow_focus = true
	module_group.add_child(secondary_scroll)
	secondary_row = HBoxContainer.new()
	secondary_row.name = "LongTermSecondaryRow"
	secondary_row.add_theme_constant_override("separation", 6)
	secondary_scroll.add_child(secondary_row)

	content_panel_texture = _add_texture(module_group, "LongTermContentDetailBlock", LongTermLayoutContractScript.CONTENT_PANEL, _texture(&"long_term.panel.content"), false)
	content_detail_title_label = _add_label(module_group, "LongTermContentDetailTitle", LongTermLayoutContractScript.CONTENT_TITLE, "", 21, Color(0.26, 0.12, 0.05), HORIZONTAL_ALIGNMENT_LEFT, &"readable")
	content_detail_body_label = _add_label(module_group, "LongTermContentDetailBody", LongTermLayoutContractScript.CONTENT_SUMMARY, "", 16, Color(0.23, 0.14, 0.08), HORIZONTAL_ALIGNMENT_LEFT, &"readable")
	content_detail_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_detail_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	content_detail_meta_label = _add_label(module_group, "LongTermContentDetailMeta", LongTermLayoutContractScript.CONTENT_META, "", 12, Color(0.35, 0.22, 0.12), HORIZONTAL_ALIGNMENT_RIGHT, &"readable")
	_clear_label_shadow(content_detail_title_label)
	_clear_label_shadow(content_detail_body_label)
	_clear_label_shadow(content_detail_meta_label)
	module_title_label = content_detail_title_label
	module_body_label = content_detail_body_label
	module_state_label = content_detail_meta_label
	module_reason_label = content_detail_meta_label
	overview_label = content_detail_title_label
	child_preview_label = content_detail_body_label
	snapshot_label = content_detail_meta_label
	interface_preview_label = content_detail_meta_label
	history_preview_label = content_detail_meta_label
	next_stage_label = content_detail_meta_label

	card_grid_container = HBoxContainer.new()
	card_grid_container.name = "LongTermCardGrid"
	card_grid_container.position = LongTermLayoutContractScript.CONTENT_CARDS.position
	card_grid_container.size = LongTermLayoutContractScript.CONTENT_CARDS.size
	card_grid_container.add_theme_constant_override("separation", 8)
	module_group.add_child(card_grid_container)
	content_action_button = Button.new()
	content_action_button.name = "LongTermContentAction"
	content_action_button.position = LongTermLayoutContractScript.CONTENT_ACTION.position
	content_action_button.size = LongTermLayoutContractScript.CONTENT_ACTION.size
	content_action_button.focus_mode = Control.FOCUS_ALL
	content_action_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	content_action_button.pressed.connect(_on_content_action_pressed)
	module_group.add_child(content_action_button)
	_apply_generic_button_surface(content_action_button, &"secondary", &"normal", 12)
	content_previous_button = _add_content_page_button("LongTermContentPrevious", LongTermLayoutContractScript.CONTENT_PREVIOUS, "上一页", -1)
	content_next_button = _add_content_page_button("LongTermContentNext", LongTermLayoutContractScript.CONTENT_NEXT, "下一页", 1)


func _build_profile_column() -> void:
	_add_texture(self, "LongTermProfileFrame", LongTermLayoutContractScript.PROFILE_FRAME, _texture(&"long_term.panel.profile"), false)
	_add_label(self, "LongTermProfileHeading", LongTermLayoutContractScript.PROFILE_HEADER, "角色档案", 23, Color(0.96, 0.75, 0.34), HORIZONTAL_ALIGNMENT_CENTER)
	character_frames.clear()
	for index in range(8):
		var frame := Art21MainMenuAssetContractScript.texture(StringName("main_menu.scene.character.idle.%02d" % index))
		if frame != null:
			character_frames.append(frame)
	var initial: Texture2D = character_frames[0] if not character_frames.is_empty() else null
	character_texture = _add_texture(self, "LongTermPlayerSprite", LongTermLayoutContractScript.PROFILE_CHARACTER, initial, true)
	_add_label(self, "LongTermProfileRole", LongTermLayoutContractScript.PROFILE_ROLE, "回收员", 18, Color(0.95, 0.83, 0.57), HORIZONTAL_ALIGNMENT_CENTER)
	profile_level_label = _add_label(self, "LongTermProfileLevel", LongTermLayoutContractScript.PROFILE_LEVEL, "等级 --", 23, Color(0.97, 0.74, 0.30), HORIZONTAL_ALIGNMENT_CENTER, &"readable")
	_add_label(self, "LongTermProfileExpLabel", LongTermLayoutContractScript.PROFILE_EXP_LABEL, "经验", 14, Color(0.78, 0.68, 0.51), HORIZONTAL_ALIGNMENT_LEFT, &"readable")
	profile_exp_value_label = _add_label(self, "LongTermProfileExpValue", LongTermLayoutContractScript.PROFILE_EXP_VALUE, "0", 14, Color(0.88, 0.81, 0.66), HORIZONTAL_ALIGNMENT_RIGHT, &"readable")
	profile_stat_labels.clear()
	var stat_names := ["探索", "撤离", "失败", "长期金币"]
	for index in range(stat_names.size()):
		var rect := Rect2(
			LongTermLayoutContractScript.PROFILE_STAT_ORIGIN + Vector2(0, index * (LongTermLayoutContractScript.PROFILE_STAT_SIZE.y + LongTermLayoutContractScript.PROFILE_STAT_GAP)),
			LongTermLayoutContractScript.PROFILE_STAT_SIZE
		)
		profile_stat_labels.append(_add_label(self, "LongTermProfileStat_%d" % index, rect, "%s  0" % stat_names[index], 15, Color(0.91, 0.80, 0.58), HORIZONTAL_ALIGNMENT_LEFT, &"readable"))
	_add_image_button(self, "LongTermAppearanceButton", LongTermLayoutContractScript.PROFILE_APPEARANCE, "设置外观", &"nav", _request_appearance_settings, 17)


func _build_archive_lever() -> void:
	lever_texture = _add_texture(self, "LongTermArchiveLeverTexture", LongTermLayoutContractScript.LEVER, null, false)
	lever_button = Button.new()
	lever_button.name = "LongTermArchiveLever"
	lever_button.text = ""
	lever_button.position = LongTermLayoutContractScript.LEVER.position
	lever_button.size = LongTermLayoutContractScript.LEVER.size
	lever_button.focus_mode = Control.FOCUS_ALL
	lever_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_transparent_button(lever_button, 13)
	lever_button.pressed.connect(func() -> void: set_archive_collapsed(not archive_collapsed))
	lever_button.focus_entered.connect(func() -> void: _set_lever_highlight(true))
	lever_button.focus_exited.connect(func() -> void: _set_lever_highlight(lever_button.is_hovered()))
	lever_button.mouse_entered.connect(func() -> void: _set_lever_highlight(true))
	lever_button.mouse_exited.connect(func() -> void: _set_lever_highlight(lever_button.has_focus()))
	add_child(lever_button)
	lever_label = _add_label(self, "LongTermArchiveLeverLabel", LongTermLayoutContractScript.LEVER_LABEL, "收起档案", 12, Color(0.97, 0.78, 0.38), HORIZONTAL_ALIGNMENT_CENTER)
	_clear_label_shadow(lever_label)
	_update_lever()


func _run_switch_sequence() -> void:
	if not page_active:
		_apply_module_immediately(requested_module_id)
		return
	var generation := lifecycle_generation
	switch_running = true
	while requested_module_id != displayed_module_id:
		transition_state = STATE_CLOSING
		if module_tween != null and module_tween.is_valid():
			module_tween.kill()
		module_tween = create_tween()
		module_tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		module_tween.tween_property(module_group, "modulate:a", 0.0, 0.24)
		module_tween.tween_property(module_group, "scale", Vector2(0.96, 0.96), 0.24)
		await get_tree().create_timer(0.24).timeout
		if not _switch_sequence_is_current(generation):
			return
		module_group.modulate.a = 0.0
		module_group.scale = Vector2(0.96, 0.96)
		transition_state = STATE_CLOSED
		await get_tree().create_timer(0.10).timeout
		if not _switch_sequence_is_current(generation):
			return
		transition_state = STATE_SWITCHING
		_apply_module_content(requested_module_id)
		module_group.modulate.a = 0.0
		module_group.scale = Vector2(0.96, 0.96)
		transition_state = STATE_OPENING
		module_tween = create_tween()
		module_tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		module_tween.tween_property(module_group, "modulate:a", 1.0, 0.34)
		module_tween.tween_property(module_group, "scale", Vector2.ONE, 0.34)
		await get_tree().create_timer(0.34).timeout
		if not _switch_sequence_is_current(generation):
			return
		module_group.modulate = Color.WHITE
		module_group.scale = Vector2.ONE
		transition_state = STATE_OPEN
	if _switch_sequence_is_current(generation):
		switch_running = false


func _switch_sequence_is_current(generation: int) -> bool:
	return page_active and generation == lifecycle_generation


func _apply_module_immediately(module_id: StringName) -> void:
	if module_tween != null and module_tween.is_valid():
		module_tween.kill()
	_apply_module_content(module_id)
	module_group.modulate = Color.WHITE
	module_group.scale = Vector2.ONE
	transition_state = STATE_OPEN
	switch_running = false


func _apply_module_content(module_id: StringName) -> void:
	displayed_module_id = _normalize_module_id(module_id)
	selected_module_id = displayed_module_id
	current_model = LongTermModelScript.build_from_snapshot(displayed_module_id, current_app_snapshot, &"app_shell_snapshot_preview")
	furniture_texture.position = LongTermLayoutContractScript.furniture_rect(displayed_module_id).position
	furniture_texture.size = LongTermLayoutContractScript.furniture_rect(displayed_module_id).size
	furniture_texture.texture = Art23LongTermAssetContractScript.texture(StringName("long_term.furniture.%s" % String(displayed_module_id)))
	_rebuild_secondary_buttons()
	_refresh_content()
	_refresh_module_buttons()


func _rebuild_secondary_buttons() -> void:
	secondary_buttons.clear()
	secondary_button_order.clear()
	for child in secondary_row.get_children():
		secondary_row.remove_child(child)
		child.queue_free()
	for group: Dictionary in _secondary_groups(displayed_module_id):
		var group_id := StringName(group.get("group_id", group.get("id", &"")))
		var button := Button.new()
		button.name = "LongTermSecondary_%s_%s" % [String(displayed_module_id), String(group_id)]
		button.text = String(group.get("title", group_id))
		button.custom_minimum_size = LongTermLayoutContractScript.SECONDARY_ROW_MIN
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(Callable(self, "_on_secondary_pressed").bind(group_id))
		secondary_row.add_child(button)
		secondary_buttons[group_id] = button
		secondary_button_order.append(button)
	_refresh_secondary_buttons()
	_wire_long_term_secondary_focus()


func _refresh_content() -> void:
	if content_detail_title_label == null:
		return
	var group := _selected_group()
	var group_id := StringName(group.get("group_id", group.get("id", &"")))
	var module_label := String(MODULE_LABELS.get(displayed_module_id, displayed_module_id))
	content_detail_title_label.text = "%s · %s" % [module_label, String(group.get("title", "档案"))]
	content_detail_body_label.text = String(PAGE_COPY.get("%s/%s" % [String(displayed_module_id), String(group_id)], "当前档案只读展示。"))
	content_detail_meta_label.text = "真实进度" if not LOCKED_MODULES.has(displayed_module_id) else "系统封存 · 仅展示接口预览"
	_rebuild_content_cards(group)
	_refresh_secondary_buttons()


func _rebuild_content_cards(group: Dictionary) -> void:
	long_term_card_buttons.clear()
	for child in card_grid_container.get_children():
		card_grid_container.remove_child(child)
		child.queue_free()
	current_content_cards = _cards_for_group(group)
	var cards := current_content_cards
	var group_key := "%s/%s" % [String(displayed_module_id), String(get_selected_secondary_id())]
	var page_count := maxi(1, ceili(float(cards.size()) / 3.0))
	var page := clampi(int(content_card_page_by_group.get(group_key, 0)), 0, page_count - 1)
	content_card_page_by_group[group_key] = page
	var page_start := page * 3
	selected_content_card_index = page_start
	for index in range(page_start, mini(page_start + 3, cards.size())):
		var card: Dictionary = cards[index]
		var button := LongTermContentCardViewScript.new() as Button
		button.name = "LongTermCard_%s_%d" % [String(get_selected_secondary_id()), index - page_start]
		button.call("setup", card, LOCKED_MODULES.has(displayed_module_id), index == page_start)
		button.set_meta("card_index", index)
		button.pressed.connect(Callable(self, "_set_long_term_card_selected").bind(index))
		_apply_card_surface(button, &"locked" if LOCKED_MODULES.has(displayed_module_id) else (&"selected" if index == page_start else &"normal"))
		card_grid_container.add_child(button)
		long_term_card_buttons.append(button)
	_refresh_selected_content_card(false)
	_refresh_content_page_buttons(page, page_count)
	_wire_long_term_card_focus()


func _cards_for_group(group: Dictionary) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var group_id := StringName(group.get("group_id", group.get("id", &"")))
	var cards_by_group: Dictionary = current_model.get("m7_cards_by_group", {})
	var real_key := "%s/%s" % [String(displayed_module_id), String(group_id)]
	if cards_by_group.has(real_key):
		for raw_card in cards_by_group.get(real_key, []):
			if raw_card is Dictionary:
				cards.append((raw_card as Dictionary).duplicate(true))
		if not cards.is_empty():
			while cards.size() < 3:
				cards.append({"title": "暂无更多记录", "state": "未登记", "description": "该分类当前没有更多真实记录。"})
			return _attach_content_visual_keys(cards, real_key)
	if displayed_module_id == &"codex" and group_id in [&"monster", &"collectible"]:
		var expected_kind := group_id
		var matching_cards: Array = (current_model.get("content_cards", []) as Array).filter(
			func(entry: Variant) -> bool:
				return entry is Dictionary and StringName((entry as Dictionary).get("codex_kind", &"collectible")) == expected_kind
		)
		for card_index in range(mini(3, matching_cards.size())):
			var card_variant: Variant = matching_cards[card_index]
			if card_variant is Dictionary:
				var card: Dictionary = card_variant
				var state_name := StringName(card.get("state", &"undiscovered"))
				var card_title := String(card.get("title", "未知条目"))
				if state_name != &"discovered":
					card_title = "%s %02d" % ["未发现怪物样本" if group_id == &"monster" else "未发现藏品", card_index + 1]
				cards.append({
					"title": card_title,
					"state": _state_label(state_name),
				})
		while cards.size() < 3:
			cards.append({
				"title": "%s %02d" % ["未发现怪物样本" if group_id == &"monster" else "未发现藏品", cards.size() + 1],
				"state": "未发现",
			})
	if displayed_module_id == &"profile":
		cards = _profile_cards(group_id)
	if cards.is_empty():
		for item_variant in (group.get("items", []) as Array).slice(0, 3):
			var item: Dictionary = item_variant if item_variant is Dictionary else {}
			cards.append({
				"title": String(item.get("title", "档案条目")),
				"state": "封存" if LOCKED_MODULES.has(displayed_module_id) else "已登记",
			})
	while cards.size() < 3:
		cards.append({"title": "预留档案位", "state": "封存" if LOCKED_MODULES.has(displayed_module_id) else "未发现"})
	return _attach_content_visual_keys(cards, real_key)


func _attach_content_visual_keys(cards: Array[Dictionary], group_key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_card in cards:
		var card := raw_card.duplicate(true)
		card["visual_key"] = Art25ContentAssetContractScript.long_term_visual_key(group_key, card)
		result.append(card)
	return result


func _profile_cards(group_id: StringName) -> Array[Dictionary]:
	var runtime: Dictionary = current_model.get("profile_runtime_panel", {})
	match group_id:
		&"qualification_level":
			return [
				{"title": "资历等级", "state": "Lv.%02d" % int(runtime.get("profile_level", 1))},
				{"title": "累计经验", "state": str(int(runtime.get("profile_exp", 0)))},
			]
		&"history":
			var records: Array = current_model.get("history_records", [])
			var cards: Array[Dictionary] = []
			for reverse_index in range(records.size() - 1, maxi(-1, records.size() - 4), -1):
				var record: Dictionary = records[reverse_index] if records[reverse_index] is Dictionary else {}
				cards.append({
					"title": String(record.get("outcome", "未知结局")),
					"state": String(record.get("result_id", record.get("history_id", "未登记"))),
				})
			if cards.is_empty():
				cards.append({"title": "暂无探索记录", "state": "完成一局后登记"})
			return cards
		&"statistics":
			return [
				{"title": "探索", "state": str(int(runtime.get("run_count", 0)))},
				{"title": "撤离", "state": str(int(runtime.get("extract_count", 0)))},
				{"title": "失败", "state": str(int(runtime.get("fail_count", 0)))},
			]
		_:
			return []


func _refresh_profile() -> void:
	if profile_level_label == null:
		return
	var runtime: Dictionary = current_model.get("profile_runtime_panel", {})
	profile_level_label.text = "等级 %02d" % maxi(1, int(runtime.get("profile_level", 1)))
	profile_exp_value_label.text = str(maxi(0, int(runtime.get("profile_exp", 0))))
	var values := [
		int(runtime.get("run_count", 0)),
		int(runtime.get("extract_count", 0)),
		int(runtime.get("fail_count", 0)),
		int(runtime.get("long_term_gold", runtime.get("gold", 0))),
	]
	var names := ["探索", "撤离", "失败", "长期金币"]
	for index in range(mini(profile_stat_labels.size(), values.size())):
		profile_stat_labels[index].text = "%s  %s" % [names[index], _format_number(values[index])]


func _refresh_module_buttons() -> void:
	var red_dots: Dictionary = current_model.get("m7_red_dot_state", {})
	for module_id_variant in tab_buttons.keys():
		var module_id := StringName(module_id_variant)
		var button := tab_buttons[module_id] as Button
		if button == null:
			continue
		button.button_pressed = module_id == selected_module_id
		var has_red_dot := _module_has_red_dot(module_id, red_dots)
		button.text = "%s%s" % ["● " if has_red_dot else "", String(MODULE_LABELS.get(module_id, module_id))]
		_apply_module_button_surface(button, module_id, button.button_pressed)


func _refresh_secondary_buttons() -> void:
	var selected := get_selected_secondary_id()
	for group_id_variant in secondary_buttons.keys():
		var group_id := StringName(group_id_variant)
		var button := secondary_buttons[group_id] as Button
		if button == null:
			continue
		button.button_pressed = group_id == selected
		_apply_generic_button_surface(button, &"secondary", &"selected" if button.button_pressed else &"normal", 14)
	if secondary_buttons.has(selected):
		secondary_scroll.ensure_control_visible(secondary_buttons[selected] as Control)


func _on_module_tab_pressed(module_id: StringName) -> void:
	show_module(module_id)
	var button := tab_buttons.get(module_id, null) as Button
	if button != null:
		button.grab_focus()


func _on_secondary_pressed(group_id: StringName) -> void:
	show_secondary(group_id)
	var button := secondary_buttons.get(group_id, null) as Button
	if button != null:
		button.grab_focus()


func _request_back_to_main() -> void:
	navigation_intent_requested.emit(NavigationIntentScript.make(
		NavigationIntentScript.TARGET_MAIN_MENU,
		&"long_term",
		{"source_page": &"long_term"}
	))


func _request_deploy() -> void:
	navigation_intent_requested.emit(NavigationIntentScript.make_deploy(
		&"long_term",
		{"tab": &"config", "source_page": &"long_term", "preview_only": false}
	))


func _request_appearance_settings() -> void:
	selected_secondary_by_module[&"collection_appearance"] = &"appearance_config"
	show_module(&"collection_appearance")


func _update_lever() -> void:
	if lever_texture == null or lever_button == null:
		return
	lever_texture.texture = _texture(&"long_term.control.lever.collapsed" if archive_collapsed else &"long_term.control.lever.expanded")
	lever_label.text = "展开档案" if archive_collapsed else "收起档案"


func _set_lever_highlight(active: bool) -> void:
	if lever_texture != null:
		lever_texture.modulate = Color(1.12, 1.05, 0.78, 1.0) if active else Color.WHITE
	if lever_label != null:
		lever_label.modulate = Color(0.48, 1.0, 0.96, 1.0) if active else Color.WHITE


func _content_transition_nodes() -> Array[CanvasItem]:
	var nodes: Array[CanvasItem] = []
	for node: CanvasItem in [
		content_panel_texture,
		content_detail_title_label,
		content_detail_body_label,
		content_detail_meta_label,
		card_grid_container,
	]:
		if node != null:
			nodes.append(node)
	return nodes


func _update_character(delta: float) -> void:
	if character_texture == null or character_frames.size() < 8:
		return
	character_elapsed += delta
	if character_look_index >= 0:
		if character_elapsed < CHARACTER_LOOK_FRAME_SECONDS:
			return
		character_elapsed = 0.0
		character_look_index += 1
		if character_look_index >= CHARACTER_LOOK_SEQUENCE.size():
			character_look_index = -1
			next_character_look = ambient_elapsed + CHARACTER_LOOK_INTERVAL_SECONDS
			character_texture.texture = character_frames[0]
			return
		character_texture.texture = character_frames[int(CHARACTER_LOOK_SEQUENCE[character_look_index])]
		return
	if ambient_elapsed >= next_character_look:
		character_look_index = 0
		character_elapsed = 0.0
		character_texture.texture = character_frames[int(CHARACTER_LOOK_SEQUENCE[0])]
		return
	if character_elapsed < CHARACTER_IDLE_FRAME_SECONDS:
		return
	character_elapsed = 0.0
	character_frame_index = (character_frame_index + 1) % CHARACTER_IDLE_SEQUENCE.size()
	character_texture.texture = character_frames[int(CHARACTER_IDLE_SEQUENCE[character_frame_index])]


func _seed_secondary_selection() -> void:
	for module_id in MODULE_IDS:
		var groups := _secondary_groups(module_id)
		if not groups.is_empty():
			selected_secondary_by_module[module_id] = StringName((groups[0] as Dictionary).get("group_id", &""))


func _secondary_groups(module_id: StringName) -> Array:
	var module := LongTermContentFrameworkScript.find_module(module_id)
	return (module.get("secondary_groups", []) as Array).duplicate(true)


func _selected_group() -> Dictionary:
	var selected := _normalize_secondary_id(displayed_module_id, get_selected_secondary_id())
	selected_secondary_by_module[displayed_module_id] = selected
	for group: Dictionary in _secondary_groups(displayed_module_id):
		if StringName(group.get("group_id", group.get("id", &""))) == selected:
			return group
	return {}


func _normalize_module_id(module_id: StringName) -> StringName:
	var canonical := &"task_archive" if module_id in [&"overview", &"goals", &"tasks"] else module_id
	if canonical in MODULE_IDS:
		return canonical
	var model_default := LongTermTabModelScript.default_module_id()
	if model_default in [&"overview", &"goals", &"tasks"]:
		return &"task_archive"
	return model_default if model_default in MODULE_IDS else &"task_archive"


func _normalize_secondary_id(module_id: StringName, group_id: StringName) -> StringName:
	var groups := _secondary_groups(module_id)
	for group: Dictionary in groups:
		var candidate := StringName(group.get("group_id", group.get("id", &"")))
		if candidate == group_id:
			return candidate
	return StringName((groups[0] as Dictionary).get("group_id", &"")) if not groups.is_empty() else &""


func _wire_long_term_tab_focus() -> void:
	var count := tab_button_order.size()
	for index in range(count):
		var button := tab_button_order[index]
		button.focus_neighbor_left = button.get_path_to(tab_button_order[(index - 1 + count) % count])
		button.focus_neighbor_right = button.get_path_to(tab_button_order[(index + 1) % count])


func _wire_long_term_secondary_focus() -> void:
	var count := secondary_button_order.size()
	if count <= 0:
		return
	var module_button := tab_buttons.get(displayed_module_id, null) as Button
	for index in range(count):
		var button := secondary_button_order[index]
		button.focus_neighbor_left = button.get_path_to(secondary_button_order[(index - 1 + count) % count])
		button.focus_neighbor_right = button.get_path_to(secondary_button_order[(index + 1) % count])
		if module_button != null:
			button.focus_neighbor_top = button.get_path_to(module_button)
		if not long_term_card_buttons.is_empty():
			button.focus_neighbor_bottom = button.get_path_to(long_term_card_buttons[index % long_term_card_buttons.size()])
	if module_button != null:
		module_button.focus_neighbor_bottom = module_button.get_path_to(secondary_button_order[0])


func _wire_long_term_card_focus() -> void:
	var count := long_term_card_buttons.size()
	if count <= 0:
		return
	for index in range(count):
		var button := long_term_card_buttons[index]
		button.focus_neighbor_left = button.get_path_to(long_term_card_buttons[(index - 1 + count) % count])
		button.focus_neighbor_right = button.get_path_to(long_term_card_buttons[(index + 1) % count])
		if not secondary_button_order.is_empty():
			button.focus_neighbor_top = button.get_path_to(secondary_button_order[index % secondary_button_order.size()])
	_wire_long_term_secondary_focus()


func _set_long_term_card_selected(card_index: int) -> void:
	selected_content_card_index = clampi(card_index, 0, maxi(0, current_content_cards.size() - 1))
	for button in long_term_card_buttons:
		var selected := int(button.get_meta("card_index", -1)) == card_index
		button.button_pressed = selected
		_apply_card_surface(button, &"locked" if LOCKED_MODULES.has(displayed_module_id) else (&"selected" if selected else &"normal"))
		if selected:
			button.grab_focus()
	_refresh_selected_content_card(true)


func _refresh_selected_content_card(_from_input: bool) -> void:
	if current_content_cards.is_empty():
		if content_action_button != null:
			content_action_button.visible = false
		return
	var card: Dictionary = current_content_cards[clampi(selected_content_card_index, 0, current_content_cards.size() - 1)]
	var description := str(card.get("description", ""))
	if description != "":
		content_detail_body_label.text = description
	content_detail_meta_label.text = str(card.get("state", "真实进度"))
	var action: Dictionary = card.get("action", {})
	content_action_button.visible = not action.is_empty() and not LOCKED_MODULES.has(displayed_module_id)
	content_action_button.disabled = action.is_empty()
	content_action_button.text = str(card.get("action_label", "确认"))


func _on_content_action_pressed() -> void:
	if current_content_cards.is_empty():
		return
	var card: Dictionary = current_content_cards[clampi(selected_content_card_index, 0, current_content_cards.size() - 1)]
	var action: Dictionary = card.get("action", {})
	if action.is_empty():
		return
	content_detail_meta_label.text = "正在提交……"
	content_action_button.disabled = true
	meta_action_requested.emit(action.duplicate(true))


func _add_content_page_button(node_name: String, rect: Rect2, text: String, page_delta: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.position = rect.position
	button.size = rect.size
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(Callable(self, "_change_content_page").bind(page_delta))
	module_group.add_child(button)
	_apply_generic_button_surface(button, &"secondary", &"normal", 12)
	return button


func _change_content_page(page_delta: int) -> void:
	if current_content_cards.size() <= 3:
		return
	var group_key := "%s/%s" % [String(displayed_module_id), String(get_selected_secondary_id())]
	var page_count := maxi(1, ceili(float(current_content_cards.size()) / 3.0))
	content_card_page_by_group[group_key] = clampi(int(content_card_page_by_group.get(group_key, 0)) + page_delta, 0, page_count - 1)
	_rebuild_content_cards(_selected_group())
	if not long_term_card_buttons.is_empty():
		long_term_card_buttons[0].grab_focus()


func _refresh_content_page_buttons(page: int, page_count: int) -> void:
	if content_previous_button == null or content_next_button == null:
		return
	var paged := page_count > 1
	content_previous_button.visible = paged
	content_next_button.visible = paged
	content_previous_button.disabled = page <= 0
	content_next_button.disabled = page >= page_count - 1
	content_previous_button.text = "上一页"
	content_next_button.text = "下一页 %d/%d" % [page + 1, page_count]


func _module_has_red_dot(module_id: StringName, red_dots: Dictionary) -> bool:
	match module_id:
		&"task_archive": return int(red_dots.get("claimable_rewards", 0)) > 0
		&"codex": return int(red_dots.get("new_codex", 0)) > 0
		&"research": return int(red_dots.get("research_available", 0)) > 0
		&"profile": return int(red_dots.get("new_history", 0)) > 0
		&"collection_appearance": return int(red_dots.get("collection_completed", 0)) > 0
	return false


func _mark_current_module_viewed(module_id: StringName) -> void:
	# Claimable task rewards are actions, not unread notices. Merely opening the
	# task archive must never acknowledge or clear them.
	if _normalize_module_id(module_id) == &"task_archive":
		return
	var red_dots: Dictionary = current_model.get("m7_red_dot_state", {})
	var view_kind := ""
	var count := 0
	match module_id:
		&"codex":
			view_kind = "codex"
			count = int(red_dots.get("new_codex", 0))
		&"profile":
			view_kind = "history"
			count = int(red_dots.get("new_history", 0))
		&"collection_appearance":
			view_kind = "collection"
			count = int(red_dots.get("collection_completed", 0))
	if view_kind != "" and count > 0:
		meta_action_requested.emit({"action": &"mark_viewed", "view_kind": view_kind})


func _grab_long_term_initial_focus() -> void:
	if not page_active or not is_visible_in_tree():
		return
	var selected := tab_buttons.get(selected_module_id, null) as Button
	if selected != null:
		selected.grab_focus()
	elif not tab_button_order.is_empty():
		tab_button_order[0].grab_focus()


func _apply_module_button_surface(button: Button, module_id: StringName, selected: bool) -> void:
	var base_state := &"selected" if selected else (&"locked" if LOCKED_MODULES.has(module_id) else &"normal")
	var focus_state := &"selected" if selected else &"focused"
	_apply_texture_style(button, Art23LongTermAssetContractScript.texture(StringName("long_term.control.module.%s.%s" % [String(module_id), String(base_state)])), "normal")
	_apply_texture_style(button, Art23LongTermAssetContractScript.texture(StringName("long_term.control.module.%s.%s" % [String(module_id), String(focus_state)])), "hover")
	_apply_texture_style(button, Art23LongTermAssetContractScript.texture(StringName("long_term.control.module.%s.%s" % [String(module_id), String(focus_state)])), "focus")
	var pressed_state := &"selected" if selected else &"pressed"
	_apply_texture_style(button, Art23LongTermAssetContractScript.texture(StringName("long_term.control.module.%s.%s" % [String(module_id), String(pressed_state)])), "pressed")
	var text_color := Color(0.44, 1.0, 0.96) if selected else Color(0.98, 0.80, 0.39)
	_apply_button_text(button, 16, text_color)
	if selected:
		_apply_selected_text_colors(button, text_color)


func _apply_generic_button_surface(button: Button, control_id: StringName, state: StringName, font_size: int) -> void:
	var focus_state := &"selected" if state == &"selected" else &"focused"
	_apply_texture_style(button, _texture(StringName("long_term.control.%s.%s" % [String(control_id), String(state)])), "normal")
	_apply_texture_style(button, _texture(StringName("long_term.control.%s.%s" % [String(control_id), String(focus_state)])), "hover")
	_apply_texture_style(button, _texture(StringName("long_term.control.%s.%s" % [String(control_id), String(focus_state)])), "focus")
	var pressed_state := &"selected" if state == &"selected" else &"pressed"
	_apply_texture_style(button, _texture(StringName("long_term.control.%s.%s" % [String(control_id), String(pressed_state)])), "pressed")
	_apply_texture_style(button, _texture(StringName("long_term.control.%s.locked" % String(control_id))), "disabled")
	var text_color := Color(0.42, 1.0, 0.96) if state == &"selected" else Color(0.96, 0.80, 0.48)
	_apply_button_text(button, font_size, text_color)
	if state == &"selected":
		_apply_selected_text_colors(button, text_color)


func _apply_card_surface(button: Button, state: StringName) -> void:
	_apply_generic_button_surface(button, &"card", state, 13)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	if button.has_method("apply_visual_state"):
		button.call("apply_visual_state", state)


func _add_image_button(parent: Control, node_name: String, rect: Rect2, text: String, control_id: StringName, callback: Callable, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	_apply_generic_button_surface(button, control_id, &"normal", font_size)
	parent.add_child(button)
	return button


func _apply_texture_style(button: Button, texture: Texture2D, state: String) -> void:
	if texture == null:
		return
	var style := StyleBoxTexture.new()
	style.texture = texture
	button.add_theme_stylebox_override(state, style)


func _apply_button_text(button: Button, font_size: int, color: Color) -> void:
	var font := _pixel_font_safe()
	if font is Font:
		button.add_theme_font_override("font", font as Font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.93, 0.68))
	button.add_theme_color_override("font_focus_color", Color(0.46, 1.0, 0.96))
	button.add_theme_color_override("font_pressed_color", Color(0.80, 0.61, 0.31))
	button.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.92))
	button.add_theme_constant_override("outline_size", 1)


func _apply_selected_text_colors(button: Button, color: Color) -> void:
	button.add_theme_color_override("font_hover_color", color)
	button.add_theme_color_override("font_focus_color", color)
	button.add_theme_color_override("font_pressed_color", color)


func _apply_transparent_button(button: Button, font_size: int) -> void:
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, empty)
	_apply_button_text(button, font_size, Color(0.97, 0.78, 0.38))


func _add_texture(parent: Control, node_name: String, rect: Rect2, texture: Texture2D, nearest: bool) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.texture = texture
	texture_rect.position = rect.position
	texture_rect.size = rect.size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if rect.size != Vector2(1280, 720) else TextureRect.STRETCH_SCALE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if nearest else CanvasItem.TEXTURE_FILTER_LINEAR
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


func _add_label(parent: Control, node_name: String, rect: Rect2, text: String, font_size: int, color: Color, alignment: HorizontalAlignment, font_role: StringName = &"display") -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font: Font = LongTermReadableFont if font_role == &"readable" else _pixel_font_safe()
	if font == null:
		font = _pixel_font_safe()
	if font is Font:
		label.add_theme_font_override("font", font as Font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.04, 0.02, 0.01, 0.68))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	return label


func _add_color_rect(parent: Control, node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.name = node_name
	color_rect.color = color
	color_rect.position = rect.position
	color_rect.size = rect.size
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(color_rect)
	return color_rect


func _clear_label_shadow(label: Label) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)


func _add_particles(node_name: String, position: Vector2, extents: Vector2, amount: int, color: Color, gravity: Vector2, lifetime: float) -> void:
	var particles := CPUParticles2D.new()
	particles.name = node_name
	particles.position = position
	particles.amount = amount
	particles.lifetime = lifetime
	particles.randomness = 0.85
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = extents * 0.5
	particles.gravity = gravity
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 4.0
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.5
	particles.color = color
	particles.emitting = page_active and not reduced_motion
	add_child(particles)
	ambient_particles.append(particles)


func _texture(visual_key: StringName) -> Texture2D:
	if texture_cache.has(visual_key):
		return texture_cache[visual_key]
	var texture := Art23LongTermAssetContractScript.texture(visual_key)
	texture_cache[visual_key] = texture
	return texture


func _pixel_font_safe() -> Font:
	if get_node_or_null("/root/AssetCatalog") == null:
		return null
	return Art10UISkinKitScript.pixel_font()


func _state_label(state: StringName) -> String:
	match state:
		&"discovered": return "已发现"
		&"owned_or_obtained": return "已获得"
		&"completed": return "已完成"
		&"empty": return "暂无记录"
		_: return "未发现"


func _format_number(value: int) -> String:
	var text := str(maxi(0, value))
	var result := ""
	while text.length() > 3:
		result = ",%s%s" % [text.right(3), result]
		text = text.left(text.length() - 3)
	return "%s%s" % [text, result]


func _focus_is_inside(root: Control) -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	return focus != null and (focus == root or root.is_ancestor_of(focus))


func _clear_children() -> void:
	if module_tween != null and module_tween.is_valid():
		module_tween.kill()
	if collapse_tween != null and collapse_tween.is_valid():
		collapse_tween.kill()
	if content_tween != null and content_tween.is_valid():
		content_tween.kill()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	tab_buttons.clear()
	tab_button_order.clear()
	secondary_buttons.clear()
	secondary_button_order.clear()
	long_term_card_buttons.clear()
	texture_cache.clear()
	ambient_particles.clear()
