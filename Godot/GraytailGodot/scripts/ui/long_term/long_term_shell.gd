extends Control
class_name LongTermShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const LongTermModelScript := preload("res://scripts/ui/long_term/long_term_model.gd")
const LongTermTabModelScript := preload("res://scripts/ui/long_term/long_term_tab_model.gd")
const LongTermContentFrameworkScript := preload("res://scripts/ui/long_term/long_term_content_framework.gd")
const LongTermLayoutContractScript := preload("res://scripts/ui/long_term/long_term_layout_contract.gd")
const LongTermModuleProjectionScript := preload("res://scripts/ui/long_term/long_term_module_projection.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art23LongTermAssetContractScript := preload("res://scripts/presentation/art23_long_term_asset_contract.gd")
const Art25ContentAssetContractScript := preload("res://scripts/presentation/art25_content_asset_contract.gd")
const LongTermContentCardViewScript := preload("res://scripts/ui/long_term/long_term_content_card_view.gd")
const CharacterPresentationCatalogScript := preload("res://scripts/presentation/character/character_presentation_catalog.gd")
const MetaActionRequestIdScript := preload("res://scripts/core/progression/meta_action_request_id.gd")

signal navigation_intent_requested(intent: Dictionary)
signal meta_action_requested(action: Dictionary)

const STATE_CLOSED := &"CLOSED"
const STATE_OPENING := &"OPENING"
const STATE_OPEN := &"OPEN"
const STATE_CLOSING := &"CLOSING"
const STATE_SWITCHING := &"SWITCHING"

const MODULE_IDS: Array[StringName] = [
	&"task_archive", &"codex", &"research", &"talent", &"profile", &"collection_appearance",
]
const MODULE_LABELS := {
	&"task_archive": "任务档案",
	&"codex": "图鉴",
	&"research": "研究解锁",
	&"talent": "天赋",
	&"profile": "角色",
	&"collection_appearance": "收藏外观",
}
const LOCKED_MODULES: Dictionary = {}
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
	"research/unlock_interface": "沿前置关系逐项研究；节点使用现有课题条件和完成效果。",
	"research/research_entry": "查看课题条件后明确确认；材料若正在出勤配置中则不会被消耗。",
	"talent/tree": "沿整备、安全与勘探三条分支解锁；精确效果只进入之后确认出发的新一局。",
	"profile/qualification_level": "展示真实资历等级与绝对经验值；没有阈值时不伪造百分比。",
	"profile/history": "回看已经完成的探索记录；浏览不会改变历史。",
	"profile/statistics": "汇总探索、撤离、失败和长期金币等已存在统计。",
	"profile/milestone": "展示真实资历阈值及距离下一阶段所需经验。",
	"profile/title": "展示已经由资历等级永久授予的称号。",
	"profile/badge": "展示已经由资历等级永久授予的徽章。",
	"collection_appearance/unique_display": "展示三组真实藏品收集进度；出售物品不降低历史收集。",
	"collection_appearance/appearance_config": "当前没有外观拥有或装备数据；本页只说明收藏档案边界。",
	"collection_appearance/display_content": "展示三组各 8 件藏品的永久收集进度。",
	"collection_appearance/badge_title": "组合展示已经获得的徽章与称号。",
	"collection_appearance/settlement_display": "回看已经完成的探索结果与带回内容。",
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
var content_list_header_label: Label
var content_detail_header_label: Label
var content_record_title_label: Label
var content_record_state_label: Label
var content_record_body_label: Label
var content_record_facts_label: Label
var content_list_scroll: ScrollContainer
var card_grid_container: VBoxContainer
var content_action_button: Button
var content_previous_button: Button
var content_next_button: Button
var current_content_cards: Array[Dictionary] = []
var current_workspace: Dictionary = {}
var current_record_count := 0
var selected_content_card_index := 0
var selected_content_card_id_by_group: Dictionary = {}
var content_card_page_by_group: Dictionary = {}
var content_scroll_by_group: Dictionary = {}
var navigation_history: Array[Dictionary] = []
var restoring_navigation := false
var pending_meta_action: Dictionary = {}
var pending_background_meta_actions: Dictionary = {}
var last_meta_action_result: Dictionary = {}
var meta_request_sequence := 0

var profile_level_label: Label
var profile_role_label: Label
var profile_exp_value_label: Label
var profile_stat_labels: Array[Label] = []
var character_texture: TextureRect
var character_frames: Array[Texture2D] = []
var character_actor_id: StringName = CharacterPresentationCatalogScript.DEFAULT_ACTOR_ID
var character_appearance_id: StringName = CharacterPresentationCatalogScript.DEFAULT_APPEARANCE_ID
var character_clip_descriptors: Dictionary = {}
var character_clip_frames: Dictionary = {}
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
var ui_scale_factor := 1.0


func build(model: Dictionary = {}) -> void:
	_clear_children()
	navigation_history.clear()
	content_scroll_by_group.clear()
	restoring_navigation = false
	Art10UISkinKitScript.apply_player_ui_theme(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_scale_factor = Art10UISkinKitScript.runtime_ui_scale_factor()
	set_meta("runtime_ui_scale_factor", ui_scale_factor)
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


func set_ui_scale_factor(value: float) -> void:
	ui_scale_factor = Art10UISkinKitScript.normalize_runtime_ui_scale_factor(value)
	set_meta("runtime_ui_scale_factor", ui_scale_factor)
	_refresh_ui_scaled_copy()


func get_ui_scale_factor() -> float:
	return ui_scale_factor


func apply_snapshot(snapshot: Dictionary) -> void:
	current_app_snapshot = snapshot.duplicate(true)
	current_model = LongTermModelScript.build_from_snapshot(selected_module_id, current_app_snapshot, &"app_shell_snapshot")
	_refresh_profile()
	_refresh_content()
	_refresh_module_buttons()


func apply_meta_action_result(envelope: Dictionary) -> bool:
	if _meta_envelope_matches(envelope, pending_meta_action):
		pending_meta_action.clear()
		last_meta_action_result = envelope.duplicate(true)
		_refresh_content()
		if content_record_state_label != null:
			content_record_state_label.text = _meta_result_player_message(envelope)
		return true
	var request_id := str(envelope.get("request_id", ""))
	var background_value: Variant = pending_background_meta_actions.get(request_id, {})
	var background_request: Dictionary = background_value as Dictionary if background_value is Dictionary else {}
	if not _meta_envelope_matches(envelope, background_request):
		return false
	pending_background_meta_actions.erase(request_id)
	last_meta_action_result = envelope.duplicate(true)
	return true


func get_meta_transaction_snapshot() -> Dictionary:
	return {
		"pending": not pending_meta_action.is_empty(),
		"pending_request": pending_meta_action.duplicate(true),
		"pending_background_count": pending_background_meta_actions.size(),
		"last_result": last_meta_action_result.duplicate(true),
		"request_sequence": meta_request_sequence,
	}


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
		_apply_character_clip_pose(&"idle", 0)
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
	if not page_active or not is_inside_tree() or reduced_motion:
		_apply_module_immediately(normalized)
		return
	if normalized == displayed_module_id and transition_state == STATE_OPEN:
		_refresh_content()
		return
	if not switch_running:
		_run_switch_sequence()


func show_secondary(group_id: StringName) -> void:
	_remember_current_scroll()
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


func notification_route_for_module(module_id: StringName) -> Dictionary:
	var normalized := _normalize_module_id(module_id)
	var meta: Dictionary = current_model.get("meta_progress_summary", {})
	var red_dots: Dictionary = current_model.get("m7_red_dot_state", {})
	match normalized:
		&"task_archive":
			if bool(red_dots.get("claimable_rewards", false)):
				return _first_action_notification(normalized, &"claim_goal")
		&"codex":
			var unread_codex := meta.get("unread_codex_ids", []) as Array
			if not unread_codex.is_empty():
				return _notification_for_card(normalized, str(unread_codex[0]), &"codex")
		&"research":
			if bool(red_dots.get("research_available", false)):
				return _first_action_notification(normalized, &"complete_research")
		&"talent":
			if bool(red_dots.get("talent_available", false)):
				return _first_action_notification(normalized, &"unlock_talent")
		&"profile":
			var unread_history := meta.get("unread_history_ids", []) as Array
			if not unread_history.is_empty():
				return _notification_for_card(
					normalized,
					"profile_history_%s" % str(unread_history.back()),
					&"history",
					&"history"
				)
		&"collection_appearance":
			var unread_collection := meta.get("unread_collection_set_ids", []) as Array
			if not unread_collection.is_empty():
				return _notification_for_card(normalized, str(unread_collection[0]), &"collection", &"unique_display")
	return {}


func open_notification(notification: Dictionary) -> Dictionary:
	if notification.is_empty():
		return {"ok": false, "status": &"notification_missing"}
	var module_id := _normalize_module_id(StringName(notification.get("module_id", &"task_archive")))
	var secondary_id := _normalize_secondary_id(
		module_id,
		StringName(notification.get("secondary_id", &""))
	)
	var card_id := str(notification.get("card_id", notification.get("target_id", "")))
	_push_navigation_state()
	selected_secondary_by_module[module_id] = secondary_id
	var group_key := "%s/%s" % [String(module_id), String(secondary_id)]
	if card_id != "":
		selected_content_card_id_by_group[group_key] = card_id
	_apply_module_immediately(module_id)
	var card_index := _content_card_index(card_id)
	var card_found := card_id == "" or card_index >= 0
	if card_index >= 0:
		_select_long_term_card(card_index, true)
	elif not current_content_cards.is_empty():
		_select_long_term_card(0, true)
	if not card_found:
		if content_record_state_label != null:
			content_record_state_label.text = "目标条目当前不可用，已打开所属分类。"
		return {
			"ok": false,
			"status": &"notification_target_unavailable",
			"module_id": module_id,
			"secondary_id": secondary_id,
			"card_id": card_id,
			"history_depth": navigation_history.size(),
		}
	var pending_before := pending_background_meta_actions.size()
	var view_kind := str(notification.get("view_kind", ""))
	if view_kind != "":
		_mark_current_module_viewed(module_id)
	return {
		"ok": true,
		"status": &"notification_opened",
		"module_id": module_id,
		"secondary_id": secondary_id,
		"card_id": card_id,
		"unread_ack_requested": pending_background_meta_actions.size() > pending_before,
		"history_depth": navigation_history.size(),
	}


func get_navigation_snapshot() -> Dictionary:
	_remember_current_scroll()
	return {
		"current": _current_navigation_state(),
		"history": navigation_history.duplicate(true),
		"history_depth": navigation_history.size(),
		"scroll_by_group": content_scroll_by_group.duplicate(true),
	}


func clear_navigation_history() -> void:
	navigation_history.clear()


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


func handle_cancel_event(event: InputEvent) -> bool:
	if (
		event == null
		or event.is_echo()
		or not page_active
		or not is_visible_in_tree()
		or not (event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"))
	):
		return false
	# A single Windows Escape gesture can surface as multiple pressed events.
	# Keep it to one staged navigation step: expand -> secondary -> primary -> main.
	if _cancel_press_is_debounced(Time.get_ticks_msec()):
		return true
	_handle_cancel_focus_step()
	return true


func _input(event: InputEvent) -> void:
	if handle_cancel_event(event):
		get_viewport().set_input_as_handled()


func _cancel_press_is_debounced(now_msec: int) -> bool:
	if now_msec - last_cancel_press_msec < CANCEL_DEBOUNCE_MSEC:
		return true
	last_cancel_press_msec = now_msec
	return false


func _handle_cancel_focus_step() -> StringName:
	if _restore_previous_page():
		return &"history"
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
	if focus == content_action_button and not long_term_card_buttons.is_empty():
		long_term_card_buttons[clampi(selected_content_card_index, 0, long_term_card_buttons.size() - 1)].grab_focus()
		return &"record"
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
	# The audited parchment is the workspace surface here, not a thumbnail. Fill
	# the expanded contract rect so its readable region covers both list/detail.
	content_panel_texture.stretch_mode = TextureRect.STRETCH_SCALE
	content_detail_title_label = _add_label(module_group, "LongTermContentDetailTitle", LongTermLayoutContractScript.CONTENT_TITLE, "", 18, Color(0.26, 0.12, 0.05), HORIZONTAL_ALIGNMENT_LEFT, &"readable")
	content_detail_body_label = _add_label(module_group, "LongTermContentDetailBody", LongTermLayoutContractScript.CONTENT_SUMMARY, "", 16, Color(0.23, 0.14, 0.08), HORIZONTAL_ALIGNMENT_LEFT, &"readable")
	content_detail_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_detail_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	content_detail_meta_label = _add_label(module_group, "LongTermContentDetailMeta", LongTermLayoutContractScript.CONTENT_META, "", 12, Color(0.35, 0.22, 0.12), HORIZONTAL_ALIGNMENT_RIGHT, &"readable")
	content_list_header_label = _add_label(module_group, "LongTermContentListHeader", LongTermLayoutContractScript.CONTENT_LIST_HEADER, "档案条目", 14, Color(0.42, 0.24, 0.10), HORIZONTAL_ALIGNMENT_LEFT, &"readable")
	content_detail_header_label = _add_label(module_group, "LongTermContentRecordHeader", LongTermLayoutContractScript.CONTENT_DETAIL_HEADER, "档案详情", 14, Color(0.42, 0.24, 0.10), HORIZONTAL_ALIGNMENT_LEFT, &"readable")
	content_record_title_label = _add_label(module_group, "LongTermContentRecordTitle", LongTermLayoutContractScript.CONTENT_RECORD_TITLE, "", 19, Color(0.22, 0.12, 0.05), HORIZONTAL_ALIGNMENT_LEFT, &"readable")
	content_record_state_label = _add_label(module_group, "LongTermContentRecordState", LongTermLayoutContractScript.CONTENT_RECORD_STATE, "", 12, Color(0.34, 0.20, 0.10), HORIZONTAL_ALIGNMENT_RIGHT, &"readable")
	content_record_body_label = _add_label(module_group, "LongTermContentRecordBody", LongTermLayoutContractScript.CONTENT_RECORD_BODY, "", 14, Color(0.24, 0.15, 0.08), HORIZONTAL_ALIGNMENT_LEFT, &"readable")
	content_record_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_record_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	content_record_facts_label = _add_label(module_group, "LongTermContentRecordFacts", LongTermLayoutContractScript.CONTENT_RECORD_FACTS, "", 13, Color(0.31, 0.20, 0.11), HORIZONTAL_ALIGNMENT_LEFT, &"readable")
	content_record_facts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_record_facts_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_clear_label_shadow(content_detail_title_label)
	_clear_label_shadow(content_detail_body_label)
	_clear_label_shadow(content_detail_meta_label)
	_clear_label_shadow(content_list_header_label)
	_clear_label_shadow(content_detail_header_label)
	_clear_label_shadow(content_record_title_label)
	_clear_label_shadow(content_record_state_label)
	_clear_label_shadow(content_record_body_label)
	_clear_label_shadow(content_record_facts_label)
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

	content_list_scroll = ScrollContainer.new()
	content_list_scroll.name = "LongTermContentListScroll"
	content_list_scroll.position = LongTermLayoutContractScript.CONTENT_CARDS.position
	content_list_scroll.size = LongTermLayoutContractScript.CONTENT_CARDS.size
	content_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_list_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content_list_scroll.follow_focus = true
	module_group.add_child(content_list_scroll)
	card_grid_container = VBoxContainer.new()
	card_grid_container.name = "LongTermCardGrid"
	card_grid_container.custom_minimum_size = Vector2(LongTermLayoutContractScript.CONTENT_CARDS.size.x - 18.0, 0)
	card_grid_container.add_theme_constant_override("separation", 4)
	content_list_scroll.add_child(card_grid_container)
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
	content_previous_button.visible = false
	content_next_button.visible = false


func _build_profile_column() -> void:
	_add_texture(self, "LongTermProfileFrame", LongTermLayoutContractScript.PROFILE_FRAME, _texture(&"long_term.panel.profile"), false)
	_add_label(self, "LongTermProfileHeading", LongTermLayoutContractScript.PROFILE_HEADER, "角色档案", 23, Color(0.96, 0.75, 0.34), HORIZONTAL_ALIGNMENT_CENTER)
	character_frames.clear()
	character_clip_descriptors.clear()
	character_clip_frames.clear()
	var presentation_value: Variant = current_model.get("character_presentation", {})
	var presentation: Dictionary = (presentation_value as Dictionary).duplicate(true) if presentation_value is Dictionary else {}
	character_actor_id = StringName(presentation.get("actor_id", CharacterPresentationCatalogScript.DEFAULT_ACTOR_ID))
	character_appearance_id = StringName(presentation.get("appearance_id", CharacterPresentationCatalogScript.DEFAULT_APPEARANCE_ID))
	_load_character_clip(&"idle")
	_load_character_clip(&"look")
	character_frames.assign(character_clip_frames.get(&"idle", []) as Array)
	var initial := CharacterPresentationCatalogScript.frame_at(
		character_frames,
		character_clip_descriptors.get(&"idle", {}) as Dictionary,
		0
	)
	character_texture = _add_texture(self, "LongTermPlayerSprite", LongTermLayoutContractScript.PROFILE_CHARACTER, initial, true)
	profile_role_label = _add_label(self, "LongTermProfileRole", LongTermLayoutContractScript.PROFILE_ROLE, "回收员", 18, Color(0.95, 0.83, 0.57), HORIZONTAL_ALIGNMENT_CENTER)
	profile_level_label = _add_label(self, "LongTermProfileLevel", LongTermLayoutContractScript.PROFILE_LEVEL, "等级 --", 23, Color(0.97, 0.74, 0.30), HORIZONTAL_ALIGNMENT_CENTER, &"readable")
	_add_label(self, "LongTermProfileExpLabel", LongTermLayoutContractScript.PROFILE_EXP_LABEL, "经验", 14, Color(0.78, 0.68, 0.51), HORIZONTAL_ALIGNMENT_LEFT, &"readable")
	profile_exp_value_label = _add_label(self, "LongTermProfileExpValue", LongTermLayoutContractScript.PROFILE_EXP_VALUE, "0", 14, Color(0.88, 0.81, 0.66), HORIZONTAL_ALIGNMENT_RIGHT, &"readable")
	profile_stat_labels.clear()
	var stat_names := ["探索", "撤离率", "档案", "长期金币"]
	for index in range(stat_names.size()):
		var rect := Rect2(
			LongTermLayoutContractScript.PROFILE_STAT_ORIGIN + Vector2(0, index * (LongTermLayoutContractScript.PROFILE_STAT_SIZE.y + LongTermLayoutContractScript.PROFILE_STAT_GAP)),
			LongTermLayoutContractScript.PROFILE_STAT_SIZE
		)
		profile_stat_labels.append(_add_label(self, "LongTermProfileStat_%d" % index, rect, "%s  0" % stat_names[index], 15, Color(0.91, 0.80, 0.58), HORIZONTAL_ALIGNMENT_LEFT, &"readable"))
	_add_image_button(self, "LongTermAppearanceButton", LongTermLayoutContractScript.PROFILE_APPEARANCE, "查看收藏档案", &"nav", _request_appearance_settings, 16)


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
	current_model = LongTermModelScript.build_from_snapshot(displayed_module_id, current_app_snapshot, &"app_shell_snapshot")
	furniture_texture.position = LongTermLayoutContractScript.furniture_rect(displayed_module_id).position
	furniture_texture.size = LongTermLayoutContractScript.furniture_rect(displayed_module_id).size
	furniture_texture.texture = Art23LongTermAssetContractScript.furniture_texture(displayed_module_id)
	_rebuild_secondary_buttons()
	_refresh_content()
	_refresh_module_buttons()


func _rebuild_secondary_buttons() -> void:
	secondary_buttons.clear()
	secondary_button_order.clear()
	for child in secondary_row.get_children():
		secondary_row.remove_child(child)
		child.queue_free()
	var groups := _secondary_groups(displayed_module_id)
	var gap := float(secondary_row.get_theme_constant("separation"))
	var fitted_width := LongTermLayoutContractScript.SECONDARY_ROW_MIN.x
	if not groups.is_empty():
		fitted_width = floorf(
			(
				LongTermLayoutContractScript.SECONDARY_SCROLL.size.x
				- gap * maxf(0.0, groups.size() - 1.0)
			) / float(groups.size())
		)
		fitted_width = clampf(
			fitted_width,
			84.0,
			LongTermLayoutContractScript.SECONDARY_ROW_MIN.x
		)
	for group: Dictionary in groups:
		var group_id := StringName(group.get("group_id", group.get("id", &"")))
		var button := Button.new()
		button.name = "LongTermSecondary_%s_%s" % [String(displayed_module_id), String(group_id)]
		button.text = String(group.get("title", group_id))
		button.custom_minimum_size = Vector2(
			fitted_width,
			LongTermLayoutContractScript.SECONDARY_ROW_MIN.y
		)
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
	var group_key := "%s/%s" % [String(displayed_module_id), String(group_id)]
	current_workspace = LongTermModuleProjectionScript.build(
		displayed_module_id,
		group,
		current_model,
		String(PAGE_COPY.get(group_key, "当前档案只读展示。"))
	)
	content_detail_title_label.text = "%s · %s" % [module_label, String(group.get("title", "档案"))]
	content_detail_body_label.text = str(current_workspace.get("summary", "当前档案只读展示。"))
	current_record_count = int(current_workspace.get("record_count", 0))
	var workspace_kind := StringName(current_workspace.get("kind", &""))
	if workspace_kind == &"research_unlock_tree":
		var completed_count := 0
		for raw_card in current_workspace.get("records", []):
			if raw_card is Dictionary and str((raw_card as Dictionary).get("state", "")) == "已完成":
				completed_count += 1
		content_detail_meta_label.text = "节点 %d · 已完成 %d" % [current_record_count, completed_count]
	elif workspace_kind == &"talent_unlock_tree":
		var tree_contract: Dictionary = current_workspace.get("tree_contract", {})
		var unlocked_count := 0
		for raw_card in current_workspace.get("records", []):
			if raw_card is Dictionary and bool((raw_card as Dictionary).get("unlocked", false)):
				unlocked_count += 1
		content_detail_meta_label.text = "可用 %d 点 · 已解锁 %d / %d" % [
			int(tree_contract.get("points_available", 0)),
			unlocked_count,
			current_record_count,
		]
	else:
		content_detail_meta_label.text = "记录 %d" % current_record_count
	content_list_header_label.text = str(current_workspace.get("list_label", "档案条目"))
	content_detail_header_label.text = str(current_workspace.get("detail_label", "档案详情"))
	_rebuild_content_cards(group)
	_refresh_secondary_buttons()
	_refresh_ui_scaled_copy()
	call_deferred(
		"_restore_content_scroll",
		group_key,
		int(content_scroll_by_group.get(group_key, 0))
	)


func _rebuild_content_cards(group: Dictionary) -> void:
	long_term_card_buttons.clear()
	for child in card_grid_container.get_children():
		card_grid_container.remove_child(child)
		child.queue_free()
	current_content_cards = _cards_for_group(group)
	var group_key := "%s/%s" % [String(displayed_module_id), String(get_selected_secondary_id())]
	var selected_card_id := str(selected_content_card_id_by_group.get(group_key, ""))
	selected_content_card_index = 0
	for index in range(current_content_cards.size()):
		if selected_card_id != "" and str(current_content_cards[index].get("id", "")) == selected_card_id:
			selected_content_card_index = index
			break
	for index in range(current_content_cards.size()):
		var card: Dictionary = current_content_cards[index]
		var button := LongTermContentCardViewScript.new() as Button
		button.name = "LongTermCard_%s_%d" % [String(get_selected_secondary_id()), index]
		button.call("setup", card, LOCKED_MODULES.has(displayed_module_id), index == selected_content_card_index)
		button.set_meta("card_index", index)
		button.pressed.connect(Callable(self, "_set_long_term_card_selected").bind(index))
		button.focus_entered.connect(Callable(self, "_preview_long_term_card").bind(index))
		button.mouse_entered.connect(Callable(self, "_preview_long_term_card").bind(index))
		_apply_card_surface(button, &"locked" if LOCKED_MODULES.has(displayed_module_id) else (&"selected" if index == selected_content_card_index else &"normal"))
		button.call("set_ui_scale_factor", ui_scale_factor)
		card_grid_container.add_child(button)
		long_term_card_buttons.append(button)
	if not current_content_cards.is_empty():
		selected_content_card_id_by_group[group_key] = str(current_content_cards[selected_content_card_index].get("id", ""))
	_refresh_selected_content_card(false)
	_refresh_content_page_buttons(0, 1)
	_wire_long_term_card_focus()


func _cards_for_group(group: Dictionary) -> Array[Dictionary]:
	var group_id := StringName(group.get("group_id", group.get("id", &"")))
	var real_key := "%s/%s" % [String(displayed_module_id), String(group_id)]
	if current_workspace.is_empty() or str(current_workspace.get("group_key", "")) != real_key:
		current_workspace = LongTermModuleProjectionScript.build(
			displayed_module_id,
			group,
			current_model,
			String(PAGE_COPY.get(real_key, "当前档案只读展示。"))
		)
	var cards: Array[Dictionary] = []
	for raw_card in current_workspace.get("display_cards", []):
		if raw_card is Dictionary:
			cards.append((raw_card as Dictionary).duplicate(true))
	return _attach_content_visual_keys(cards, real_key)


func _attach_content_visual_keys(cards: Array[Dictionary], group_key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_card in cards:
		var card := raw_card.duplicate(true)
		card["visual_key"] = &"art25.long_term.unknown" if card.get("known", true) == false else Art25ContentAssetContractScript.long_term_visual_key(group_key, card)
		var presentation_kind := StringName(card.get("presentation_kind", &""))
		card["tree_view"] = (
			(group_key == "research/unlock_interface" and presentation_kind == &"research_unlock_node")
			or (group_key == "talent/tree" and presentation_kind == &"talent_unlock_node")
		)
		result.append(card)
	return result


func _profile_cards(group_id: StringName) -> Array[Dictionary]:
	var cards_by_group: Dictionary = current_model.get("m7_cards_by_group", {})
	var result: Array[Dictionary] = []
	for raw_card in cards_by_group.get("profile/%s" % String(group_id), []):
		if raw_card is Dictionary:
			result.append((raw_card as Dictionary).duplicate(true))
	return result


func _refresh_profile() -> void:
	if profile_level_label == null:
		return
	var runtime: Dictionary = current_model.get("profile_runtime_panel", {})
	profile_level_label.text = "等级 %02d" % maxi(1, int(runtime.get("profile_level", 1)))
	var titles := runtime.get("titles", []) as Array
	profile_role_label.text = str(runtime.get("current_title", titles[titles.size() - 1] if not titles.is_empty() else "回收员"))
	profile_exp_value_label.text = str(maxi(0, int(runtime.get("profile_exp", 0))))
	var next_level_exp := int(runtime.get("next_level_exp", -1))
	profile_exp_value_label.tooltip_text = (
		"距离下一等级还需 %d 经验" % int(runtime.get("exp_to_next_level", 0))
		if next_level_exp >= 0
		else "已达到当前资历上限"
	)
	var values := [
		_format_number(int(runtime.get("run_count", 0))),
		"%d%%" % int(runtime.get("extract_rate_percent", 0)),
		_format_number(int(runtime.get("history_record_count", 0))),
		_format_number(int(runtime.get("long_term_gold", runtime.get("gold", 0)))),
	]
	var names := ["探索", "撤离率", "档案", "长期金币"]
	for index in range(mini(profile_stat_labels.size(), values.size())):
		profile_stat_labels[index].text = "%s  %s" % [names[index], values[index]]
	_refresh_ui_scaled_copy()


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
	var notification := notification_route_for_module(module_id)
	if not notification.is_empty():
		open_notification(notification)
		return
	if module_id != displayed_module_id:
		_push_navigation_state()
	show_module(module_id)
	var button := tab_buttons.get(module_id, null) as Button
	if button != null:
		button.grab_focus()


func _on_secondary_pressed(group_id: StringName) -> void:
	if group_id != get_selected_secondary_id():
		_push_navigation_state()
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
	# Compatibility method name retained for existing routes. The project has no
	# appearance ownership/equip authority, so the fixed rail opens the honest
	# collection archive instead of pretending to configure a skin.
	selected_secondary_by_module[&"collection_appearance"] = &"unique_display"
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
		content_list_header_label,
		content_detail_header_label,
		content_record_title_label,
		content_record_state_label,
		content_record_body_label,
		content_record_facts_label,
		content_list_scroll,
	]:
		if node != null:
			nodes.append(node)
	return nodes


func _update_character(delta: float) -> void:
	if character_texture == null or character_frames.is_empty():
		return
	character_elapsed += delta
	var active_clip_id := &"look" if character_look_index >= 0 else &"idle"
	var descriptor_value: Variant = character_clip_descriptors.get(active_clip_id, {})
	var active_descriptor: Dictionary = descriptor_value as Dictionary if descriptor_value is Dictionary else {}
	var frame_seconds := maxf(0.01, float(active_descriptor.get("frame_seconds", 0.32)))
	if character_look_index >= 0:
		if character_elapsed < frame_seconds:
			return
		character_elapsed = fmod(character_elapsed, frame_seconds)
		_apply_character_clip_pose(&"look", character_look_index)
		character_look_index += 1
		var look_sequence := active_descriptor.get("sequence", []) as Array
		if look_sequence.is_empty() or character_look_index >= look_sequence.size():
			character_look_index = -1
			character_frame_index = 0
			next_character_look = ambient_elapsed + CHARACTER_LOOK_INTERVAL_SECONDS
		return
	if ambient_elapsed >= next_character_look:
		character_look_index = 0
		character_elapsed = 0.0
		_apply_character_clip_pose(&"look", 0)
		return
	if character_elapsed < frame_seconds:
		return
	character_elapsed = fmod(character_elapsed, frame_seconds)
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
	var descriptor_value: Variant = character_clip_descriptors.get(clip_id, {})
	var descriptor: Dictionary = descriptor_value as Dictionary if descriptor_value is Dictionary else {}
	var frames := character_clip_frames.get(clip_id, []) as Array
	var frame := CharacterPresentationCatalogScript.frame_at(frames, descriptor, step)
	if frame == null:
		return false
	character_texture.texture = frame
	character_texture.flip_h = bool(descriptor.get("flip_h", false))
	return true


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


func _notification_for_card(
	module_id: StringName,
	card_id: String,
	view_kind: StringName = &"",
	preferred_secondary_id: StringName = &""
) -> Dictionary:
	var secondary_id := _normalize_secondary_id(module_id, preferred_secondary_id)
	var cards_by_group: Dictionary = current_model.get("m7_cards_by_group", {})
	for group: Dictionary in _secondary_groups(module_id):
		var candidate_secondary_id := StringName(group.get("group_id", group.get("id", &"")))
		var group_key := "%s/%s" % [String(module_id), String(candidate_secondary_id)]
		if _model_group_has_card(cards_by_group, group_key, card_id):
			secondary_id = candidate_secondary_id
			break
	return {
		"module_id": module_id,
		"secondary_id": secondary_id,
		"card_id": card_id,
		"view_kind": view_kind,
		"notification_kind": &"unread",
	}


func _first_action_notification(module_id: StringName, action_id: StringName) -> Dictionary:
	var cards_by_group: Dictionary = current_model.get("m7_cards_by_group", {})
	for group: Dictionary in _secondary_groups(module_id):
		var secondary_id := StringName(group.get("group_id", group.get("id", &"")))
		var group_key := "%s/%s" % [String(module_id), String(secondary_id)]
		for raw_card in cards_by_group.get(group_key, []):
			if not (raw_card is Dictionary):
				continue
			var card := raw_card as Dictionary
			var action_value: Variant = card.get("action", {})
			var action: Dictionary = action_value as Dictionary if action_value is Dictionary else {}
			if StringName(action.get("action", &"")) == action_id:
				return {
					"module_id": module_id,
					"secondary_id": secondary_id,
					"card_id": str(card.get("id", "")),
					"view_kind": &"",
					"notification_kind": &"actionable",
				}
	return {}


func _model_group_has_card(cards_by_group: Dictionary, group_key: String, card_id: String) -> bool:
	for raw_card in cards_by_group.get(group_key, []):
		if raw_card is Dictionary and str((raw_card as Dictionary).get("id", "")) == card_id:
			return true
	return false


func _content_card_index(card_id: String) -> int:
	if card_id.is_empty():
		return -1
	for index in range(current_content_cards.size()):
		if str(current_content_cards[index].get("id", "")) == card_id:
			return index
	return -1


func _remember_current_scroll() -> void:
	if content_list_scroll == null or displayed_module_id == &"":
		return
	var group_key := "%s/%s" % [String(displayed_module_id), String(get_selected_secondary_id())]
	content_scroll_by_group[group_key] = content_list_scroll.scroll_vertical


func _current_navigation_state() -> Dictionary:
	var secondary_id := get_selected_secondary_id()
	var group_key := "%s/%s" % [String(displayed_module_id), String(secondary_id)]
	var card_id := str(selected_content_card_id_by_group.get(group_key, ""))
	var focus_zone := &"module"
	if is_inside_tree():
		var focus := get_viewport().gui_get_focus_owner()
		if focus in long_term_card_buttons or focus == content_action_button:
			focus_zone = &"card"
		elif focus in secondary_button_order:
			focus_zone = &"secondary"
		elif focus == lever_button:
			focus_zone = &"lever"
	return {
		"module_id": displayed_module_id,
		"secondary_id": secondary_id,
		"card_id": card_id,
		"scroll_vertical": int(content_scroll_by_group.get(group_key, 0)),
		"archive_collapsed": archive_collapsed,
		"focus_zone": focus_zone,
	}


func _push_navigation_state() -> void:
	if restoring_navigation or module_group == null:
		return
	_remember_current_scroll()
	var state := _current_navigation_state()
	if not navigation_history.is_empty() and navigation_history.back() == state:
		return
	navigation_history.append(state)
	while navigation_history.size() > 32:
		navigation_history.pop_front()


func _restore_previous_page() -> bool:
	if restoring_navigation or navigation_history.is_empty():
		return false
	_remember_current_scroll()
	var state := (navigation_history.pop_back() as Dictionary).duplicate(true)
	var module_id := _normalize_module_id(StringName(state.get("module_id", &"task_archive")))
	var secondary_id := _normalize_secondary_id(module_id, StringName(state.get("secondary_id", &"")))
	var group_key := "%s/%s" % [String(module_id), String(secondary_id)]
	restoring_navigation = true
	selected_secondary_by_module[module_id] = secondary_id
	selected_content_card_id_by_group[group_key] = str(state.get("card_id", ""))
	content_scroll_by_group[group_key] = int(state.get("scroll_vertical", 0))
	archive_collapsed = bool(state.get("archive_collapsed", false))
	_apply_module_immediately(module_id)
	if module_group != null:
		module_group.position = LongTermLayoutContractScript.COLLAPSED_OFFSET if archive_collapsed else Vector2.ZERO
	_update_lever()
	restoring_navigation = false
	call_deferred("_restore_navigation_focus", state)
	return true


func _restore_content_scroll(group_key: String, scroll_vertical: int) -> void:
	if content_list_scroll == null:
		return
	var current_group_key := "%s/%s" % [String(displayed_module_id), String(get_selected_secondary_id())]
	if current_group_key != group_key:
		return
	content_list_scroll.scroll_vertical = maxi(0, scroll_vertical)
	set_meta("last_scroll_restore_group", group_key)
	set_meta("last_scroll_restore_value", content_list_scroll.scroll_vertical)


func _restore_navigation_focus(state: Dictionary) -> void:
	if not page_active or not is_visible_in_tree():
		return
	match StringName(state.get("focus_zone", &"card")):
		&"secondary":
			var secondary := secondary_buttons.get(get_selected_secondary_id(), null) as Button
			if secondary != null:
				secondary.grab_focus()
				return
		&"module":
			var module_button := tab_buttons.get(displayed_module_id, null) as Button
			if module_button != null:
				module_button.grab_focus()
				return
		&"lever":
			if lever_button != null:
				lever_button.grab_focus()
				return
	if not long_term_card_buttons.is_empty():
		long_term_card_buttons[clampi(selected_content_card_index, 0, long_term_card_buttons.size() - 1)].grab_focus()


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
	var selected_secondary := secondary_buttons.get(get_selected_secondary_id(), null) as Button
	for index in range(count):
		var button := long_term_card_buttons[index]
		var card: Dictionary = current_content_cards[index] if index < current_content_cards.size() else {}
		var action_value: Variant = card.get("action", {})
		var action: Dictionary = action_value as Dictionary if action_value is Dictionary else {}
		var action_reachable := index == selected_content_card_index and not action.is_empty() and content_action_button.visible and not content_action_button.disabled
		button.focus_neighbor_left = button.get_path_to(button)
		button.focus_neighbor_right = button.get_path_to(content_action_button if action_reachable else button)
		button.focus_neighbor_top = button.get_path_to(long_term_card_buttons[index - 1]) if index > 0 else (button.get_path_to(selected_secondary) if selected_secondary != null else NodePath())
		button.focus_neighbor_bottom = button.get_path_to(long_term_card_buttons[index + 1]) if index + 1 < count else button.get_path_to(button)
	if content_action_button != null:
		var selected_button := long_term_card_buttons[clampi(selected_content_card_index, 0, count - 1)]
		content_action_button.focus_neighbor_left = content_action_button.get_path_to(selected_button)
		content_action_button.focus_neighbor_top = content_action_button.get_path_to(selected_button)
		content_action_button.focus_neighbor_bottom = content_action_button.get_path_to(selected_button)
	_wire_long_term_secondary_focus()


func _set_long_term_card_selected(card_index: int) -> void:
	_select_long_term_card(card_index, true)


func _preview_long_term_card(card_index: int) -> void:
	_select_long_term_card(card_index, false)


func _select_long_term_card(card_index: int, grab_focus: bool) -> void:
	if current_content_cards.is_empty():
		return
	selected_content_card_index = clampi(card_index, 0, maxi(0, current_content_cards.size() - 1))
	for button in long_term_card_buttons:
		var selected := int(button.get_meta("card_index", -1)) == selected_content_card_index
		button.button_pressed = selected
		_apply_card_surface(button, &"locked" if LOCKED_MODULES.has(displayed_module_id) else (&"selected" if selected else &"normal"))
		if selected and grab_focus:
			button.grab_focus()
		if selected and content_list_scroll != null:
			content_list_scroll.ensure_control_visible(button)
	var group_key := "%s/%s" % [String(displayed_module_id), String(get_selected_secondary_id())]
	selected_content_card_id_by_group[group_key] = str(current_content_cards[selected_content_card_index].get("id", ""))
	_refresh_selected_content_card(true)


func _refresh_selected_content_card(_from_input: bool) -> void:
	if current_content_cards.is_empty():
		if content_action_button != null:
			content_action_button.visible = false
		content_record_title_label.text = ""
		content_record_state_label.text = ""
		content_record_body_label.text = ""
		content_record_facts_label.text = ""
		return
	var card: Dictionary = current_content_cards[clampi(selected_content_card_index, 0, current_content_cards.size() - 1)]
	content_record_title_label.text = str(card.get("title", "档案条目"))
	content_record_state_label.text = str(card.get("state", "已登记"))
	content_record_body_label.text = str(card.get("description", "当前条目没有补充说明。"))
	var fact_lines: Array[String] = []
	for fact in card.get("facts", []):
		var text_value := str(fact).strip_edges()
		if text_value != "":
			fact_lines.append("• %s" % text_value)
	content_record_facts_label.text = "\n".join(fact_lines)
	var action: Dictionary = card.get("action", {})
	content_action_button.visible = not bool(card.get("empty_state", false)) and not action.is_empty() and not LOCKED_MODULES.has(displayed_module_id)
	content_action_button.disabled = action.is_empty() or not pending_meta_action.is_empty()
	content_action_button.text = "正在确认…" if not action.is_empty() and not pending_meta_action.is_empty() else str(card.get("action_label", "确认"))
	_wire_long_term_card_focus()


func _on_content_action_pressed() -> void:
	if current_content_cards.is_empty() or content_action_button.disabled or not pending_meta_action.is_empty():
		return
	var card: Dictionary = current_content_cards[clampi(selected_content_card_index, 0, current_content_cards.size() - 1)]
	var action: Dictionary = card.get("action", {})
	if action.is_empty():
		return
	var request := _prepare_meta_action(action)
	pending_meta_action = _meta_request_identity(request)
	content_record_state_label.text = "正在确认…"
	content_action_button.disabled = true
	content_action_button.text = "正在确认…"
	_wire_long_term_card_focus()
	meta_action_requested.emit(request)


func _prepare_meta_action(action: Dictionary) -> Dictionary:
	var request := action.duplicate(true)
	meta_request_sequence += 1
	request["request_id"] = MetaActionRequestIdScript.generate(&"long_term")
	request["source_page"] = &"long_term"
	return request


func _meta_request_identity(request: Dictionary) -> Dictionary:
	return {
		"request_id": str(request.get("request_id", "")),
		"source_page": StringName(request.get("source_page", &"")),
		"action": StringName(request.get("action", &"")),
		"target_id": _meta_action_target_id(request),
	}


func _meta_action_target_id(action: Dictionary) -> String:
	match StringName(action.get("action", &"")):
		&"complete_research": return str(action.get("research_id", ""))
		&"unlock_talent": return str(action.get("talent_id", ""))
		&"claim_goal": return "%s:%s" % [str(action.get("goal_kind", "")), str(action.get("goal_id", ""))]
		&"mark_viewed": return str(action.get("view_kind", ""))
	return ""


func _meta_envelope_matches(envelope: Dictionary, expected: Dictionary) -> bool:
	if expected.is_empty():
		return false
	return (
		str(envelope.get("request_id", "")) == str(expected.get("request_id", ""))
		and StringName(envelope.get("source_page", &"")) == StringName(expected.get("source_page", &""))
		and StringName(envelope.get("action", &"")) == StringName(expected.get("action", &""))
		and str(envelope.get("target_id", "")) == str(expected.get("target_id", ""))
	)


func _meta_result_player_message(envelope: Dictionary) -> String:
	var result_value: Variant = envelope.get("result", {})
	var result: Dictionary = result_value as Dictionary if result_value is Dictionary else {}
	var status := StringName(envelope.get("status", result.get("status", &"unknown")))
	if bool(envelope.get("ok", result.get("ok", false))):
		match status:
			&"claimed": return "奖励已领取并存入基地档案。"
			&"completed": return "研究完成，相关内容已经开放。"
			&"talent_unlocked": return "天赋已解锁，将从之后确认出发的新一局生效。"
			&"talent_already_unlocked": return "该天赋已经解锁，无需重复提交。"
			&"duplicate_ignored": return "该项操作已经完成，无需重复提交。"
		return "档案操作已完成。"
	match status:
		&"not_claimable": return "当前尚未满足领取条件。"
		&"unknown_goal": return "该任务档案暂不可用。"
		&"unknown_research": return "该研究课题暂不可用。"
		&"unknown_talent": return "该天赋节点不在当前权威目录中。"
		&"prerequisite_missing":
			return "请先解锁前置天赋。" if StringName(envelope.get("action", &"")) == &"unlock_talent" else "请先完成前置研究。"
		&"insufficient_talent_points": return "天赋点不足，本次解锁未发生。"
		&"insufficient_gold": return "金币不足，研究未开始。"
		&"material_missing_or_configured": return "所需材料不足，或正在出勤配置中。"
		&"write_blocked": return "当前档案不可写，本次操作未发生。"
		&"save_failed": return "保存失败，本次变更已撤回。"
		&"request_id_conflict": return "操作校验未通过，本次变更未发生。"
		&"meta_progress_adapter_missing": return "基地档案暂不可用。"
	return "本次操作未完成，请稍后重试。"


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
	if content_list_scroll == null:
		return
	content_list_scroll.scroll_vertical += int(page_delta * maxi(1.0, content_list_scroll.size.y - 24.0))


func _refresh_content_page_buttons(_page: int, _page_count: int) -> void:
	if content_previous_button == null or content_next_button == null:
		return
	content_previous_button.visible = false
	content_next_button.visible = false


func _module_has_red_dot(module_id: StringName, red_dots: Dictionary) -> bool:
	match module_id:
		&"task_archive": return int(red_dots.get("claimable_rewards", 0)) > 0
		&"codex": return int(red_dots.get("new_codex", 0)) > 0
		&"research": return int(red_dots.get("research_available", 0)) > 0
		&"talent": return int(red_dots.get("talent_available", 0)) > 0
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
		var request := _prepare_meta_action({"action": &"mark_viewed", "view_kind": view_kind})
		pending_background_meta_actions[str(request.get("request_id", ""))] = _meta_request_identity(request)
		meta_action_requested.emit(request)


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
	_apply_module_button_copy(button, text_color)


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
	button.set_meta("long_term_base_font_size", font_size)
	_apply_scaled_button_font(button)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.93, 0.68))
	button.add_theme_color_override("font_focus_color", Color(0.46, 1.0, 0.96))
	button.add_theme_color_override("font_pressed_color", Color(0.80, 0.61, 0.31))
	button.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.92))
	button.add_theme_constant_override("outline_size", 1)


func _apply_module_button_copy(button: Button, color: Color) -> void:
	var label := button.get_node_or_null("LongTermModuleButtonLabel") as Label
	if label == null:
		var copy_band := Panel.new()
		copy_band.name = "LongTermModuleCopyBand"
		copy_band.position = Vector2(4, 56)
		copy_band.size = Vector2(118, 28)
		copy_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var band_style := StyleBoxFlat.new()
		band_style.bg_color = Color(0.025, 0.055, 0.05, 0.84)
		band_style.border_color = Color(0.65, 0.43, 0.15, 0.56)
		band_style.set_border_width_all(1)
		copy_band.add_theme_stylebox_override("panel", band_style)
		button.add_child(copy_band)
		label = Label.new()
		label.name = "LongTermModuleButtonLabel"
		label.position = Vector2(6, 58)
		label.size = Vector2(114, 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var font := _pixel_font_safe()
		if font is Font:
			label.add_theme_font_override("font", font as Font)
		label.set_meta("long_term_base_font_size", 16)
		label.set_meta("long_term_max_font_size", 18)
		label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.94))
		label.add_theme_constant_override("outline_size", 1)
		button.add_child(label)
	label.text = button.text
	label.add_theme_color_override("font_color", color)
	_apply_scaled_label_font(label)
	button.remove_meta("long_term_base_font_size")
	button.remove_meta("runtime_text_fit")
	button.add_theme_font_size_override("font_size", 1)
	for color_name in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, Color(1, 1, 1, 0))


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
	var font := Art10UISkinKitScript.font_for_role(font_role)
	if font is Font:
		label.add_theme_font_override("font", font as Font)
	label.set_meta("ui_font_role", font_role)
	label.set_meta("long_term_base_font_size", font_size)
	match node_name:
		"LongTermContentDetailTitle":
			label.set_meta("long_term_max_font_size", 20)
		"LongTermContentDetailBody":
			label.set_meta("long_term_max_font_size", 16)
		"LongTermContentDetailMeta":
			label.set_meta("long_term_max_font_size", 12)
		"LongTermProfileRole":
			label.set_meta("long_term_max_font_size", 18)
	_apply_scaled_label_font(label)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.04, 0.02, 0.01, 0.68))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	return label


func _refresh_ui_scaled_copy() -> void:
	for child in _control_descendants(self):
		if child == self:
			continue
		if child.has_method("set_ui_scale_factor") and child is LongTermContentCardView:
			child.call("set_ui_scale_factor", ui_scale_factor)
			continue
		if child is Label and child.has_meta("long_term_base_font_size"):
			_apply_scaled_label_font(child as Label)
		elif child is Button and child.has_meta("long_term_base_font_size"):
			_apply_scaled_button_font(child as Button)


func _control_descendants(root_control: Control) -> Array[Control]:
	var result: Array[Control] = [root_control]
	var cursor := 0
	while cursor < result.size():
		var parent := result[cursor]
		cursor += 1
		for child in parent.get_children():
			if child is Control:
				result.append(child as Control)
	return result


func _apply_scaled_button_font(button: Button) -> void:
	if button == null or not button.has_meta("long_term_base_font_size"):
		return
	var base_font_size := int(button.get_meta("long_term_base_font_size"))
	var fit := LongTermLayoutContractScript.fit_text(
		button.text,
		button.get_theme_font("font"),
		button.size,
		base_font_size,
		ui_scale_factor,
		false,
		button.alignment,
		Vector2(8, 4)
	)
	button.add_theme_font_size_override("font_size", int(fit.get("font_size", base_font_size)))
	button.clip_text = true
	button.set_meta("runtime_ui_scale_factor", ui_scale_factor)
	button.set_meta("runtime_text_fit", fit)


func _apply_scaled_label_font(label: Label) -> void:
	if label == null or not label.has_meta("long_term_base_font_size"):
		return
	var base_font_size := int(label.get_meta("long_term_base_font_size"))
	var fit := LongTermLayoutContractScript.fit_text(
		label.text,
		label.get_theme_font("font"),
		label.size,
		base_font_size,
		ui_scale_factor,
		label.autowrap_mode != TextServer.AUTOWRAP_OFF,
		label.horizontal_alignment,
		Vector2(2, 2),
		int(label.get_meta("long_term_max_font_size", -1))
	)
	label.add_theme_font_size_override("font_size", int(fit.get("font_size", base_font_size)))
	label.set_meta("runtime_ui_scale_factor", ui_scale_factor)
	label.set_meta("runtime_text_fit", fit)


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
	if get_node_or_null("/root/ContentDB") == null:
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
