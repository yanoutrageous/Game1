extends Control
class_name AppShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const PageRouterScript := preload("res://scripts/ui/app_shell/page_router.gd")
const NavigationTransitionCoordinatorScript := preload("res://scripts/ui/app_shell/navigation_transition_coordinator.gd")
const MainMenuShellScript := preload("res://scripts/ui/main_menu/main_menu_shell.gd")
const DeployPrepShellScript := preload("res://scripts/ui/deploy_prep/deploy_prep_shell.gd")
const LongTermShellScript := preload("res://scripts/ui/long_term/long_term_shell.gd")
const RunStartRouteAdapterScript := preload("res://scripts/core/run/run_start_route_adapter.gd")
const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const Art21UIPlacementContractScript := preload("res://scripts/presentation/art21_ui_placement_contract.gd")
const SettingsManagerScript := preload("res://scripts/core/settings/settings_manager.gd")
const SettingsPanelScript := preload("res://scripts/ui/settings/settings_panel.gd")

signal host_route_requested(intent: Dictionary)
signal page_changed(page_id: StringName, payload: Dictionary)
signal meta_action_requested(action: Dictionary)

var main_menu_shell: Control
var deploy_page: Control
var long_term_page: Control
var settings_page: Control
var settings_panel: PanelContainer
var settings_close_button: Button
var exit_confirm_panel: Control
var exit_confirm_body: Label
var settings_manager: Node
var _owned_settings_manager: Node
var current_snapshot: Dictionary = {}
var _has_snapshot := false
var _snapshot_revision := 0
var _meta_request_sequence := 0
var _last_meta_result_delivery: Dictionary = {}
var _current_page_id: StringName = PageRouterScript.PAGE_MAIN_MENU
var _shell_active := true
var _navigation_transition_coordinator: RefCounted
var _page_snapshot_revisions: Dictionary = {
	PageRouterScript.PAGE_MAIN_MENU: -1,
	PageRouterScript.PAGE_DEPLOY_PREP: -1,
	PageRouterScript.PAGE_LONG_TERM: -1,
}
var _snapshot_refresh_counts: Dictionary = {
	PageRouterScript.PAGE_MAIN_MENU: 0,
	PageRouterScript.PAGE_DEPLOY_PREP: 0,
	PageRouterScript.PAGE_LONG_TERM: 0,
}


func build() -> void:
	_cancel_active_navigation_transition(&"shell_rebuilt", false)
	_navigation_transition_coordinator = NavigationTransitionCoordinatorScript.new()
	_last_meta_result_delivery.clear()
	_clear_children()
	_reset_page_snapshot_revisions()
	if not visibility_changed.is_connected(_on_shell_visibility_changed):
		visibility_changed.connect(_on_shell_visibility_changed)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_main_menu()
	_build_deploy_prep()
	_build_long_term()
	_build_settings_overlay()
	_build_exit_confirm_layer()
	_ensure_settings_manager_bound()
	_apply_bound_runtime_settings()
	_shell_active = is_visible_in_tree()
	show_main()


func apply_snapshot(snapshot: Dictionary) -> void:
	current_snapshot = snapshot.duplicate(true)
	_has_snapshot = true
	_snapshot_revision += 1
	_refresh_visible_snapshot_page()
	if exit_confirm_panel != null and exit_confirm_panel.visible and is_visible_in_tree():
		_refresh_exit_confirm_text()


func get_snapshot_refresh_counts() -> Dictionary:
	return _snapshot_refresh_counts.duplicate(true)


func show_main() -> void:
	if not _cancel_navigation_transition_for_external_page_change():
		return
	_show_main_internal()


func _show_main_internal() -> void:
	_current_page_id = PageRouterScript.PAGE_MAIN_MENU
	_set_page_visible(main_menu_shell)
	_hide_settings(false)
	_hide_exit_confirm(false)


func show_deploy(_tab_id: StringName = &"overview") -> void:
	if not _cancel_navigation_transition_for_external_page_change():
		return
	_show_deploy_internal(_tab_id)


func _show_deploy_internal(tab_id: StringName = &"overview") -> void:
	_current_page_id = PageRouterScript.PAGE_DEPLOY_PREP
	_set_page_visible(deploy_page)
	_hide_settings(false)
	_hide_exit_confirm(false)
	if deploy_page != null and deploy_page.has_method("show_tab"):
		deploy_page.call("show_tab", tab_id)


func show_long_term(_entry_id: StringName = NavigationIntentScript.LONG_TERM_DEFAULT_MODULE) -> void:
	if not _cancel_navigation_transition_for_external_page_change():
		return
	_show_long_term_internal(_entry_id)


func _show_long_term_internal(entry_id: StringName = NavigationIntentScript.LONG_TERM_DEFAULT_MODULE) -> void:
	_current_page_id = PageRouterScript.PAGE_LONG_TERM
	_set_page_visible(long_term_page)
	_hide_settings(false)
	_hide_exit_confirm(false)
	if long_term_page != null and long_term_page.has_method("show_module"):
		long_term_page.call("show_module", NavigationIntentScript.normalize_long_term_module_id(entry_id))


func show_settings() -> bool:
	if not _cancel_navigation_transition_for_external_page_change():
		return false
	return _show_settings_internal()


func _show_settings_internal() -> bool:
	_current_page_id = PageRouterScript.PAGE_SETTINGS_PLACEHOLDER
	if settings_page != null:
		settings_page.visible = true
	_hide_exit_confirm(false)
	_set_page_visible(main_menu_shell)
	if settings_panel == null or not bool(settings_panel.call("open_panel")):
		_show_main_internal()
		_restore_main_menu_focus()
		return false
	return true


func set_shell_active(value: bool) -> void:
	if not value:
		_cancel_active_navigation_transition(&"shell_deactivated", false)
	_shell_active = value and is_visible_in_tree()
	_sync_page_lifecycle()


func get_visible_page_id() -> StringName:
	if not _shell_active or not is_visible_in_tree():
		return &""
	if settings_page != null and settings_page.visible:
		return PageRouterScript.PAGE_SETTINGS_PLACEHOLDER
	if exit_confirm_panel != null and exit_confirm_panel.visible:
		return PageRouterScript.PAGE_EXIT_CONFIRM
	return _current_page_id


func get_main_page() -> Control:
	return main_menu_shell


func get_deploy_page() -> Control:
	return deploy_page


func get_long_term_page() -> Control:
	return long_term_page


func get_navigation_transition_snapshot() -> Dictionary:
	if _navigation_transition_coordinator == null:
		return {}
	return _navigation_transition_coordinator.call("snapshot") as Dictionary


func get_settings_panel() -> PanelContainer:
	return settings_panel


func bind_settings_manager(manager: Node) -> void:
	if settings_manager == manager:
		if settings_manager == null:
			_ensure_settings_manager_bound()
			return
		_connect_settings_manager()
		_bind_settings_panel_to_manager()
		_apply_bound_runtime_settings()
		return
	var reopen_settings := (
		settings_panel != null
		and settings_page != null
		and settings_page.visible
		and settings_panel.visible
	)
	if settings_panel != null:
		settings_panel.call("close_panel", false)
		settings_panel.call("bind_settings_manager", null)
	_disconnect_settings_manager()
	settings_manager = manager
	if _owned_settings_manager != null and _owned_settings_manager != manager:
		var released_manager := _owned_settings_manager
		_owned_settings_manager = null
		if is_instance_valid(released_manager):
			if released_manager.get_parent() == self:
				remove_child(released_manager)
			released_manager.queue_free()
	_connect_settings_manager()
	_bind_settings_panel_to_manager()
	_apply_bound_runtime_settings()
	if settings_manager == null:
		_ensure_settings_manager_bound()
	if reopen_settings and settings_panel != null:
		settings_panel.call("open_panel")


func get_bound_settings_manager() -> Node:
	return settings_manager


func get_owned_settings_manager() -> Node:
	return _owned_settings_manager


func owns_bound_settings_manager() -> bool:
	return settings_manager != null and settings_manager == _owned_settings_manager


func _ensure_settings_manager_bound() -> void:
	if settings_manager != null and is_instance_valid(settings_manager) and not settings_manager.is_queued_for_deletion():
		_connect_settings_manager()
		_bind_settings_panel_to_manager()
		return
	settings_manager = null
	var autoload_manager := get_node_or_null("/root/SettingsManager")
	if autoload_manager != null:
		bind_settings_manager(autoload_manager)
		return
	var owned_manager := SettingsManagerScript.new() as Node
	owned_manager.name = "OwnedSettingsManager"
	_owned_settings_manager = owned_manager
	add_child(owned_manager)
	bind_settings_manager(owned_manager)


func _bind_settings_panel_to_manager() -> void:
	if settings_panel != null:
		settings_panel.call("bind_settings_manager", settings_manager)


func _connect_settings_manager() -> void:
	if settings_manager == null or not is_instance_valid(settings_manager):
		return
	var applied_callback := Callable(self, "_on_runtime_settings_applied")
	if settings_manager.has_signal("settings_applied") and not settings_manager.is_connected("settings_applied", applied_callback):
		settings_manager.connect("settings_applied", applied_callback)
	var reverted_callback := Callable(self, "_on_runtime_settings_reverted")
	if settings_manager.has_signal("settings_reverted") and not settings_manager.is_connected("settings_reverted", reverted_callback):
		settings_manager.connect("settings_reverted", reverted_callback)


func _disconnect_settings_manager() -> void:
	if settings_manager == null or not is_instance_valid(settings_manager):
		return
	var applied_callback := Callable(self, "_on_runtime_settings_applied")
	if settings_manager.has_signal("settings_applied") and settings_manager.is_connected("settings_applied", applied_callback):
		settings_manager.disconnect("settings_applied", applied_callback)
	var reverted_callback := Callable(self, "_on_runtime_settings_reverted")
	if settings_manager.has_signal("settings_reverted") and settings_manager.is_connected("settings_reverted", reverted_callback):
		settings_manager.disconnect("settings_reverted", reverted_callback)


func _apply_bound_runtime_settings() -> void:
	if settings_manager == null or not is_instance_valid(settings_manager) or not settings_manager.has_method("get_applied_settings"):
		return
	var runtime_settings: Dictionary = settings_manager.call("get_applied_settings")
	_apply_runtime_settings_to_pages(runtime_settings)


func _on_runtime_settings_applied(runtime_settings: Dictionary) -> void:
	_apply_runtime_settings_to_pages(runtime_settings)


func _on_runtime_settings_reverted(runtime_settings: Dictionary, _reason: StringName) -> void:
	_apply_runtime_settings_to_pages(runtime_settings)


func _apply_runtime_settings_to_pages(runtime_settings: Dictionary) -> void:
	var reduce_motion := bool(runtime_settings.get("reduce_motion", false))
	if _navigation_transition_coordinator != null and bool(_navigation_transition_coordinator.call("is_busy")):
		var active_token := int(_navigation_transition_coordinator.call("active_token"))
		_navigation_transition_coordinator.call("set_reduced_motion", active_token, reduce_motion)
	for page: Control in [main_menu_shell, deploy_page, long_term_page]:
		if page != null and page.has_method("set_reduced_motion_enabled"):
			page.call("set_reduced_motion_enabled", reduce_motion)


func _clear_children() -> void:
	for child in get_children():
		if child == _owned_settings_manager:
			continue
		remove_child(child)
		child.queue_free()


func _build_main_menu() -> void:
	main_menu_shell = MainMenuShellScript.new() as Control
	main_menu_shell.name = "MainMenuShell"
	add_child(main_menu_shell)
	main_menu_shell.call("build")
	main_menu_shell.connect("navigation_intent_requested", _on_navigation_intent_requested)
	if main_menu_shell.has_signal("navigation_transition_requested"):
		main_menu_shell.connect("navigation_transition_requested", _on_main_menu_navigation_transition_requested)
	if main_menu_shell.has_signal("navigation_transition_finished"):
		main_menu_shell.connect("navigation_transition_finished", _on_main_menu_navigation_transition_finished)
	if main_menu_shell.has_signal("navigation_transition_cancel_requested"):
		main_menu_shell.connect("navigation_transition_cancel_requested", _on_main_menu_navigation_transition_cancel_requested)


func _build_deploy_prep() -> void:
	deploy_page = DeployPrepShellScript.new() as Control
	deploy_page.name = "DeployPrepShell"
	add_child(deploy_page)
	deploy_page.call("build")
	if deploy_page.has_signal("navigation_intent_requested"):
		deploy_page.connect("navigation_intent_requested", _on_navigation_intent_requested)
	if deploy_page.has_signal("deploy_start_intent_requested"):
		deploy_page.connect("deploy_start_intent_requested", _on_deploy_start_intent_requested)
	if deploy_page.has_signal("meta_action_requested"):
		deploy_page.connect("meta_action_requested", _forward_meta_action.bind(PageRouterScript.PAGE_DEPLOY_PREP))


func _build_long_term() -> void:
	long_term_page = LongTermShellScript.new() as Control
	long_term_page.name = "LongTermShell"
	add_child(long_term_page)
	long_term_page.call("build")
	if long_term_page.has_signal("navigation_intent_requested"):
		long_term_page.connect("navigation_intent_requested", _on_navigation_intent_requested)
	if long_term_page.has_signal("meta_action_requested"):
		long_term_page.connect("meta_action_requested", _forward_meta_action.bind(PageRouterScript.PAGE_LONG_TERM))


func _forward_meta_action(action: Dictionary, source_page: StringName = &"") -> void:
	var forwarded := action.duplicate(true)
	if source_page.is_empty():
		source_page = StringName(forwarded.get("source_page", &""))
	forwarded["source_page"] = source_page
	if str(forwarded.get("request_id", "")).is_empty():
		_meta_request_sequence += 1
		forwarded["request_id"] = "app:%d:%d" % [get_instance_id(), _meta_request_sequence]
	if deploy_page != null and deploy_page.has_method("get_selected_instance_ids"):
		var selected: Dictionary = deploy_page.call("get_selected_instance_ids")
		forwarded["selected_equipment_ids"] = (selected.get("selected_equipment_ids", []) as Array).duplicate()
		forwarded["selected_consumable_ids"] = (selected.get("selected_consumable_ids", []) as Array).duplicate()
	meta_action_requested.emit(forwarded)


func apply_meta_action_result(envelope: Dictionary) -> bool:
	var source_page := StringName(envelope.get("source_page", &""))
	var target_page: Control
	match source_page:
		PageRouterScript.PAGE_DEPLOY_PREP:
			target_page = deploy_page
		PageRouterScript.PAGE_LONG_TERM:
			target_page = long_term_page
		_:
			return false
	if target_page == null or not target_page.has_method("apply_meta_action_result"):
		return false
	var accepted := bool(target_page.call("apply_meta_action_result", envelope))
	_last_meta_result_delivery = {
		"request_id": str(envelope.get("request_id", "")),
		"source_page": source_page,
		"action": StringName(envelope.get("action", &"")),
		"target_id": str(envelope.get("target_id", "")),
		"accepted": accepted,
		"snapshot_revision": _snapshot_revision,
		"page_snapshot_revision": int(_page_snapshot_revisions.get(source_page, -1)),
	}
	return accepted


func get_meta_result_delivery_snapshot() -> Dictionary:
	return {
		"current_snapshot_revision": _snapshot_revision,
		"last_delivery": _last_meta_result_delivery.duplicate(true),
	}


func _build_placeholder_page(page_name: String, title: String, body: String) -> Control:
	var page := Control.new()
	page.name = page_name
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	_add_color_rect(page, "%sBackdrop" % page_name, Rect2(0, 0, 1280, 720), Color(0.020, 0.040, 0.048, 1.0))
	_add_label(page, "%sTitle" % page_name, Rect2(80, 86, 620, 52), title, 34, PresentationTheme.color_for_key(&"ui.accent"))
	_add_label(page, "%sBody" % page_name, Rect2(84, 166, 720, 180), body, 18, PresentationTheme.text_color())
	_add_label(page, "%sBoundary" % page_name, Rect2(84, 382, 820, 110), "边界：设置入口只保留 route 占位。真实设置系统、持久化、资源配置和偏好保存后置。", 15, PresentationTheme.color_for_key(&"ui.muted"))
	_add_button(page, "%sBackButton" % page_name, Rect2(84, 548, 180, 44), "返回主菜单", func() -> void: show_main())
	return page


func _build_settings_overlay() -> void:
	settings_page = Control.new()
	settings_page.name = "SettingsOverlay"
	settings_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	UILayerContractScript.apply_layer(settings_page, &"overlay")
	settings_page.visible = false
	add_child(settings_page)
	var dim := _add_color_rect(settings_page, "SettingsOverlayDim", Rect2(0, 0, 1280, 720), Color(0.015, 0.025, 0.03, 0.72))
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_add_art21_texture(settings_page, "SettingsModalPanel", Rect2(232, 58, 816, 604), &"main_menu.scene.menu.modal.panel")
	settings_panel = SettingsPanelScript.new() as PanelContainer
	settings_panel.name = "SettingsPanel"
	settings_panel.position = Vector2(340, 96)
	settings_panel.size = Vector2(600, 462)
	settings_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	settings_page.add_child(settings_panel)
	settings_panel.connect("close_requested", _close_settings_to_main)
	settings_close_button = settings_panel.get("close_button") as Button
	if settings_close_button != null:
		var actions := settings_close_button.get_parent()
		actions.remove_child(settings_close_button)
		settings_page.add_child(settings_close_button)
		settings_close_button.name = "SettingsCloseButton"
		_add_art21_texture(settings_page, "SettingsCloseButtonTexture", Rect2(796, 584, 190, 58), &"main_menu.scene.menu.modal.button")
		settings_page.move_child(settings_close_button, settings_page.get_child_count() - 1)
		_style_art21_modal_button(settings_close_button, Rect2(796, 584, 190, 58))


func _build_exit_confirm_layer() -> void:
	exit_confirm_panel = Control.new()
	exit_confirm_panel.name = "ExitConfirmDialog"
	exit_confirm_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	UILayerContractScript.apply_layer(exit_confirm_panel, &"modal")
	exit_confirm_panel.visible = false
	add_child(exit_confirm_panel)
	var dim := _add_color_rect(exit_confirm_panel, "ExitConfirmDim", Rect2(0, 0, 1280, 720), Color(0.015, 0.02, 0.025, 0.76))
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_add_art21_texture(exit_confirm_panel, "ExitConfirmModalPanel", Rect2(232, 142, 816, 436), &"main_menu.scene.menu.modal.panel")
	_add_overlay_label(exit_confirm_panel, "ExitConfirmTitle", Rect2(350, 190, 580, 50), "退出游戏", 32, Color(0.97, 0.70, 0.35))
	exit_confirm_body = _add_overlay_label(exit_confirm_panel, "ExitConfirmBody", Rect2(350, 266, 580, 126), "", 17, Color(0.94, 0.90, 0.80))
	exit_confirm_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exit_confirm_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	exit_confirm_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_add_art21_modal_button(exit_confirm_panel, "ExitConfirmAccept", Rect2(392, 444, 190, 58), "确认退出", func() -> void: get_tree().quit())
	_add_art21_modal_button(exit_confirm_panel, "ExitConfirmCancel", Rect2(698, 444, 190, 58), "取消", func() -> void: _hide_exit_confirm())
	_refresh_exit_confirm_text()


func _on_navigation_intent_requested(intent: Dictionary) -> void:
	if _navigation_transition_coordinator != null and bool(_navigation_transition_coordinator.call("is_busy")):
		return
	var commit_result := _commit_navigation_intent(intent)
	page_changed.emit(
		StringName(commit_result.get("page_id", PageRouterScript.PAGE_MAIN_MENU)),
		(commit_result.get("payload", {}) as Dictionary).duplicate(true)
	)


func _on_main_menu_navigation_transition_requested(intent: Dictionary, profile_id: StringName, entry_id: StringName) -> void:
	if _navigation_transition_coordinator == null or main_menu_shell == null:
		_restore_main_menu_entry_focus(entry_id)
		return
	var route := PageRouterScript.route_for_intent(intent)
	var target_page := StringName(route.get("page", PageRouterScript.PAGE_MAIN_MENU))
	if (
		_current_page_id != PageRouterScript.PAGE_MAIN_MENU
		or not _shell_active
		or not main_menu_shell.visible
		or _profile_for_page(target_page) != profile_id
	):
		_restore_main_menu_entry_focus(entry_id)
		return
	var reduced_motion := false
	if main_menu_shell.has_method("is_reduced_motion_enabled"):
		reduced_motion = bool(main_menu_shell.call("is_reduced_motion_enabled"))
	var requested: Dictionary = _navigation_transition_coordinator.call(
		"request_transition",
		PageRouterScript.PAGE_MAIN_MENU,
		target_page,
		profile_id,
		entry_id,
		reduced_motion,
		{"intent": intent.duplicate(true)}
	)
	if not bool(requested.get("ok", false)):
		_restore_main_menu_entry_focus(entry_id)
		return
	var token := int(requested.get("token", 0))
	if not _can_prepare_navigation_target(target_page):
		var prepare_failure: Dictionary = _navigation_transition_coordinator.call(
			"mark_prepared", token, false, &"target_prepare_failed"
		)
		_recover_main_menu_transition(prepare_failure, entry_id)
		return
	var prepared: Dictionary = _navigation_transition_coordinator.call("mark_prepared", token, true)
	if not bool(prepared.get("ok", false)):
		_recover_main_menu_transition(prepared, entry_id)
		return
	var playback_started := false
	if main_menu_shell.has_method("play_navigation_transition"):
		playback_started = bool(main_menu_shell.call(
			"play_navigation_transition", token, profile_id, entry_id, reduced_motion
		))
	if not playback_started:
		var playback_failure: Dictionary = _navigation_transition_coordinator.call(
			"fail_transition", token, &"presenter_start_failed"
		)
		_recover_main_menu_transition(playback_failure, entry_id)


func _on_main_menu_navigation_transition_finished(token: int) -> void:
	if _navigation_transition_coordinator == null:
		return
	var playback_result: Dictionary = _navigation_transition_coordinator.call("mark_playback_finished", token)
	if not bool(playback_result.get("ok", false)):
		return
	var commit_request_result: Dictionary = _navigation_transition_coordinator.call("take_commit", token)
	if not bool(commit_request_result.get("ok", false)):
		var take_failure: Dictionary = _navigation_transition_coordinator.call(
			"fail_transition", token, &"commit_request_failed"
		)
		_recover_main_menu_transition(take_failure)
		return
	var commit_request := commit_request_result.get("commit_request", {}) as Dictionary
	var request_payload := commit_request.get("payload", {}) as Dictionary
	var raw_intent: Variant = request_payload.get("intent", {})
	if not (raw_intent is Dictionary) or (raw_intent as Dictionary).is_empty():
		var intent_failure: Dictionary = _navigation_transition_coordinator.call(
			"resolve_commit", token, false, &"intent_missing"
		)
		_recover_main_menu_transition(intent_failure)
		page_changed.emit(PageRouterScript.PAGE_MAIN_MENU, {})
		return
	var intent := (raw_intent as Dictionary).duplicate(true)
	var commit_result := _commit_navigation_intent(intent)
	var committed := bool(commit_result.get("ok", false))
	var resolve_result: Dictionary = _navigation_transition_coordinator.call(
		"resolve_commit", token, committed, &"route_commit_failed"
	)
	if not committed:
		_recover_main_menu_transition(resolve_result)
	page_changed.emit(
		StringName(commit_result.get("page_id", PageRouterScript.PAGE_MAIN_MENU)),
		(commit_result.get("payload", {}) as Dictionary).duplicate(true)
	)


func _on_main_menu_navigation_transition_cancel_requested(token: int, reason_code: StringName) -> void:
	if _navigation_transition_coordinator == null:
		return
	var cancelled: Dictionary = _navigation_transition_coordinator.call("cancel", token, reason_code)
	if not bool(cancelled.get("ok", false)):
		return
	if main_menu_shell != null and main_menu_shell.has_method("cancel_navigation_transition"):
		main_menu_shell.call("cancel_navigation_transition", token, false)
	_recover_main_menu_transition(cancelled)


func _commit_navigation_intent(intent: Dictionary) -> Dictionary:
	var route := PageRouterScript.route_for_intent(intent)
	var page_id := StringName(route.get("page", PageRouterScript.PAGE_MAIN_MENU))
	var committed_page_id := page_id
	var page_payload := NavigationIntentScript.payload(intent)
	var committed := true
	match page_id:
		PageRouterScript.PAGE_DEPLOY_PLACEHOLDER:
			if deploy_page == null:
				committed = false
				committed_page_id = PageRouterScript.PAGE_MAIN_MENU
				_show_main_internal()
			else:
				var deploy_payload := page_payload
				_show_deploy_internal(StringName(deploy_payload.get("tab", &"overview")))
				if deploy_page.has_method("apply_route_payload"):
					deploy_page.call("apply_route_payload", deploy_payload)
		PageRouterScript.PAGE_LONG_TERM:
			if long_term_page == null:
				committed = false
				committed_page_id = PageRouterScript.PAGE_MAIN_MENU
				_show_main_internal()
			else:
				var long_term_payload := page_payload
				var long_term_module_id := NavigationIntentScript.normalize_long_term_module_id(StringName(
					long_term_payload.get("module_id", long_term_payload.get("entry_id", NavigationIntentScript.LONG_TERM_DEFAULT_MODULE))
				))
				long_term_payload["module_id"] = long_term_module_id
				long_term_payload["entry_id"] = long_term_module_id
				page_payload = long_term_payload
				_show_long_term_internal(long_term_module_id)
		PageRouterScript.PAGE_SETTINGS_PLACEHOLDER:
			if not _show_settings_internal():
				committed = false
				committed_page_id = PageRouterScript.PAGE_MAIN_MENU
		PageRouterScript.PAGE_EXIT_CONFIRM:
			if exit_confirm_panel == null:
				committed = false
				committed_page_id = PageRouterScript.PAGE_MAIN_MENU
				_show_main_internal()
			else:
				_show_exit_confirm()
		PageRouterScript.PAGE_RUN:
			host_route_requested.emit(intent)
		_:
			_show_main_internal()
	return {
		"ok": committed,
		"page_id": committed_page_id,
		"payload": page_payload,
	}


func _profile_for_page(page_id: StringName) -> StringName:
	match page_id:
		PageRouterScript.PAGE_DEPLOY_PLACEHOLDER:
			return NavigationTransitionCoordinatorScript.PROFILE_ENTER_CAVE
		PageRouterScript.PAGE_LONG_TERM:
			return NavigationTransitionCoordinatorScript.PROFILE_DESCEND
		PageRouterScript.PAGE_SETTINGS_PLACEHOLDER:
			return NavigationTransitionCoordinatorScript.PROFILE_OPEN_OVERLAY
		PageRouterScript.PAGE_EXIT_CONFIRM:
			return NavigationTransitionCoordinatorScript.PROFILE_OPEN_CONFIRM
		_:
			return &""


func _can_prepare_navigation_target(page_id: StringName) -> bool:
	match page_id:
		PageRouterScript.PAGE_DEPLOY_PLACEHOLDER:
			return deploy_page != null
		PageRouterScript.PAGE_LONG_TERM:
			return long_term_page != null
		PageRouterScript.PAGE_SETTINGS_PLACEHOLDER:
			return settings_page != null and settings_panel != null and settings_manager != null
		PageRouterScript.PAGE_EXIT_CONFIRM:
			return exit_confirm_panel != null
		_:
			return false


func _recover_main_menu_transition(result: Dictionary, fallback_focus: StringName = &"") -> void:
	var last_result := result.get("last_result", {}) as Dictionary
	if last_result.is_empty():
		var result_snapshot := result.get("snapshot", {}) as Dictionary
		last_result = result_snapshot.get("last_result", {}) as Dictionary
	var recovery := last_result.get("recovery", {}) as Dictionary
	var focus_id := StringName(recovery.get("focus_id", fallback_focus))
	var finished_token := int(last_result.get("token", 0))
	if main_menu_shell != null and main_menu_shell.has_method("cancel_navigation_transition") and finished_token > 0:
		main_menu_shell.call("cancel_navigation_transition", finished_token, false)
	if _shell_active and is_visible_in_tree() and StringName(recovery.get("page", PageRouterScript.PAGE_MAIN_MENU)) == PageRouterScript.PAGE_MAIN_MENU:
		show_main()
		_restore_main_menu_entry_focus(focus_id)


func _restore_main_menu_entry_focus(entry_id: StringName) -> void:
	if not _shell_active or main_menu_shell == null or not main_menu_shell.visible:
		return
	var target_entry := entry_id if entry_id != &"" else &"deploy"
	if main_menu_shell.has_method("_set_focus_state"):
		main_menu_shell.call("_set_focus_state", target_entry)
	var button := main_menu_shell.get_node_or_null("PrimaryActionRoot/MainMenuEntry_%s" % String(target_entry)) as Button
	if button != null and is_instance_valid(button):
		button.call_deferred("grab_focus")


func _cancel_active_navigation_transition(reason_code: StringName, restore_focus: bool = true) -> bool:
	if _navigation_transition_coordinator == null or not bool(_navigation_transition_coordinator.call("is_busy")):
		return true
	var token := int(_navigation_transition_coordinator.call("active_token"))
	var cancelled: Dictionary = _navigation_transition_coordinator.call("cancel", token, reason_code)
	if not bool(cancelled.get("ok", false)):
		return false
	if main_menu_shell != null and main_menu_shell.has_method("cancel_navigation_transition"):
		main_menu_shell.call("cancel_navigation_transition", token, restore_focus)
	if restore_focus:
		_recover_main_menu_transition(cancelled)
	return true


func _cancel_navigation_transition_for_external_page_change() -> bool:
	if _navigation_transition_coordinator == null or not bool(_navigation_transition_coordinator.call("is_busy")):
		return true
	return _cancel_active_navigation_transition(&"external_page_change", false)


func _on_deploy_start_intent_requested(intent: Dictionary) -> void:
	var payload := NavigationIntentScript.payload(intent)
	payload = RunStartRouteAdapterScript.payload_from_route_payload(payload)
	if NavigationIntentScript.target(intent) == NavigationIntentScript.TARGET_RUN and bool(payload.get("uses_existing_route", false)):
		intent["payload"] = payload
		host_route_requested.emit(intent)


func _set_page_visible(active_page: Control) -> void:
	for page: Control in [main_menu_shell, deploy_page, long_term_page]:
		if page != null:
			page.visible = page == active_page
	_refresh_snapshot_page(active_page)
	_sync_page_lifecycle()


func _sync_page_lifecycle() -> void:
	var shell_visible := _shell_active and is_visible_in_tree()
	var overlay_visible := (settings_page != null and settings_page.visible) or (exit_confirm_panel != null and exit_confirm_panel.visible)
	var active_page: Control = null
	if shell_visible and not overlay_visible:
		for page: Control in [main_menu_shell, deploy_page, long_term_page]:
			if page != null and page.visible:
				active_page = page
				break
	for page: Control in [main_menu_shell, deploy_page, long_term_page]:
		if page == null:
			continue
		var page_active := page == active_page
		if page.has_method("set_page_active"):
			page.call("set_page_active", page_active)
		else:
			page.process_mode = Node.PROCESS_MODE_INHERIT if page_active else Node.PROCESS_MODE_DISABLED
	if settings_page != null:
		settings_page.process_mode = Node.PROCESS_MODE_INHERIT if shell_visible and settings_page.visible else Node.PROCESS_MODE_DISABLED
	if exit_confirm_panel != null:
		exit_confirm_panel.process_mode = Node.PROCESS_MODE_INHERIT if shell_visible and exit_confirm_panel.visible else Node.PROCESS_MODE_DISABLED
	if not shell_visible and is_inside_tree():
		var focus := get_viewport().gui_get_focus_owner()
		if focus != null and (focus == self or is_ancestor_of(focus)):
			get_viewport().gui_release_focus()


func _on_shell_visibility_changed() -> void:
	if not is_visible_in_tree():
		_cancel_active_navigation_transition(&"shell_hidden", false)
	_shell_active = is_visible_in_tree()
	_sync_page_lifecycle()


func _refresh_visible_snapshot_page() -> void:
	if not is_visible_in_tree():
		return
	for page: Control in [main_menu_shell, deploy_page, long_term_page]:
		if page != null and page.visible:
			_refresh_snapshot_page(page)
			return


func _refresh_snapshot_page(page: Control) -> void:
	if not _has_snapshot or page == null or not page.visible or not is_visible_in_tree():
		return
	var page_id := _snapshot_page_id(page)
	if page_id == &"" or int(_page_snapshot_revisions.get(page_id, -1)) == _snapshot_revision:
		return
	if not page.has_method("apply_snapshot"):
		return
	page.call("apply_snapshot", current_snapshot)
	_page_snapshot_revisions[page_id] = _snapshot_revision
	_snapshot_refresh_counts[page_id] = int(_snapshot_refresh_counts.get(page_id, 0)) + 1


func _snapshot_page_id(page: Control) -> StringName:
	if page == main_menu_shell:
		return PageRouterScript.PAGE_MAIN_MENU
	if page == deploy_page:
		return PageRouterScript.PAGE_DEPLOY_PREP
	if page == long_term_page:
		return PageRouterScript.PAGE_LONG_TERM
	return &""


func _reset_page_snapshot_revisions() -> void:
	for page_id: StringName in _page_snapshot_revisions:
		_page_snapshot_revisions[page_id] = -1


func _show_exit_confirm() -> void:
	_refresh_exit_confirm_text()
	_hide_settings(false)
	if exit_confirm_panel != null:
		exit_confirm_panel.visible = true
		_sync_page_lifecycle()
		var cancel_button := exit_confirm_panel.get_node_or_null("ExitConfirmCancel") as Button
		if _shell_active and cancel_button != null:
			cancel_button.grab_focus()


func _hide_exit_confirm(restore_focus: bool = true) -> void:
	if exit_confirm_panel != null:
		exit_confirm_panel.visible = false
	_sync_page_lifecycle()
	if restore_focus:
		_restore_main_menu_focus()


func _hide_settings(restore_focus: bool = true) -> void:
	if settings_panel != null:
		settings_panel.call("close_panel", false)
	if settings_page != null:
		settings_page.visible = false
	_sync_page_lifecycle()
	if restore_focus:
		_restore_main_menu_focus()


func _close_settings_to_main() -> void:
	show_main()
	_restore_main_menu_focus()
	page_changed.emit(PageRouterScript.PAGE_MAIN_MENU, {"source_page": PageRouterScript.PAGE_SETTINGS_PLACEHOLDER})


func _restore_main_menu_focus() -> void:
	if _shell_active and _current_page_id == PageRouterScript.PAGE_MAIN_MENU and main_menu_shell != null and main_menu_shell.visible and main_menu_shell.has_method("_grab_default_focus"):
		main_menu_shell.call_deferred("_grab_default_focus")


func _refresh_exit_confirm_text() -> void:
	if exit_confirm_body == null:
		return
	var has_active_run := bool(current_snapshot.get("run_active", false))
	if has_active_run:
		exit_confirm_body.text = "检测到当前存在进行中探索。退出游戏只会关闭程序，不执行探索放弃、结算或资源变动；当前不保证重新启动后能够恢复本次探索。若要放弃探索，请进入出发探索页执行强确认。"
	else:
		exit_confirm_body.text = "确认退出游戏？本操作只关闭程序，不执行探索放弃、结算或资源变动。"


func _add_button(parent: Control, node_name: String, rect: Rect2, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.offset_left = rect.position.x
	button.offset_top = rect.position.y
	button.offset_right = rect.position.x + rect.size.x
	button.offset_bottom = rect.position.y + rect.size.y
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_menu_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 40)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_art21_texture(parent: Control, node_name: String, rect: Rect2, visual_key: StringName) -> TextureRect:
	var texture := Art21UIPlacementContractScript.main_menu_scene_texture(visual_key)
	if texture == null:
		return null
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.texture = texture
	texture_rect.position = rect.position.round()
	texture_rect.size = rect.size.round()
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


func _add_overlay_label(parent: Control, node_name: String, rect: Rect2, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = rect.position.round()
	label.size = rect.size.round()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_shadow_color", Color(0.05, 0.03, 0.02, 0.82))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	Art10UISkinKitScript.apply_label(label, font_size, color)
	parent.add_child(label)
	return label


func _add_art21_modal_button(parent: Control, node_name: String, rect: Rect2, text: String, callback: Callable) -> Button:
	_add_art21_texture(parent, "%sTexture" % node_name, rect, &"main_menu.scene.menu.modal.button")
	var button := Button.new()
	button.name = node_name
	button.text = text
	_style_art21_modal_button(button, rect)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _style_art21_modal_button(button: Button, rect: Rect2) -> void:
	button.position = rect.position.round()
	button.size = rect.size.round()
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, empty)
	var font := Art10UISkinKitScript.pixel_font()
	if font is Font:
		button.add_theme_font_override("font", font as Font)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color(0.96, 0.81, 0.48))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.93, 0.68))
	button.add_theme_color_override("font_pressed_color", Color(0.82, 0.64, 0.35))


func _add_label(parent: Control, node_name: String, rect: Rect2, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.offset_left = rect.position.x
	label.offset_top = rect.position.y
	label.offset_right = rect.position.x + rect.size.x
	label.offset_bottom = rect.position.y + rect.size.y
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _add_color_rect(parent: Control, node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var color_rect := ColorRect.new()
	color_rect.name = node_name
	color_rect.color = color
	color_rect.offset_left = rect.position.x
	color_rect.offset_top = rect.position.y
	color_rect.offset_right = rect.position.x + rect.size.x
	color_rect.offset_bottom = rect.position.y + rect.size.y
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(color_rect)
	return color_rect
