extends Control
class_name AppShell

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const PageRouterScript := preload("res://scripts/ui/app_shell/page_router.gd")
const MainMenuShellScript := preload("res://scripts/ui/main_menu/main_menu_shell.gd")
const DeployPrepShellScript := preload("res://scripts/ui/deploy_prep/deploy_prep_shell.gd")
const LongTermShellScript := preload("res://scripts/ui/long_term/long_term_shell.gd")

signal host_route_requested(intent: Dictionary)

var main_menu_shell: Control
var deploy_page: Control
var long_term_page: Control
var settings_page: Control
var exit_confirm_panel: PanelContainer
var exit_confirm_body: Label
var current_snapshot: Dictionary = {}


func build() -> void:
	_clear_children()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_main_menu()
	_build_deploy_prep()
	_build_long_term()
	settings_page = _build_placeholder_page(
		"SettingsPlaceholderPage",
		"设置",
		"当前仅为设置入口占位，完整设置系统未实现。\n\n本页不读取配置、不写入偏好、不改变分辨率。"
	)
	_build_exit_confirm_layer()
	show_main()


func apply_snapshot(snapshot: Dictionary) -> void:
	current_snapshot = snapshot.duplicate(true)
	if deploy_page != null and deploy_page.has_method("apply_snapshot"):
		deploy_page.call("apply_snapshot", current_snapshot)
	if long_term_page != null and long_term_page.has_method("apply_snapshot"):
		long_term_page.call("apply_snapshot", current_snapshot)
	_refresh_exit_confirm_text()


func show_main() -> void:
	_set_page_visible(main_menu_shell)
	_hide_exit_confirm()


func show_deploy(_tab_id: StringName = &"overview") -> void:
	_set_page_visible(deploy_page)
	if deploy_page != null and deploy_page.has_method("show_tab"):
		deploy_page.call("show_tab", _tab_id)
	_hide_exit_confirm()


func show_long_term(_entry_id: StringName = &"overview") -> void:
	_set_page_visible(long_term_page)
	if long_term_page != null and long_term_page.has_method("show_module"):
		long_term_page.call("show_module", _entry_id)
	_hide_exit_confirm()


func show_settings() -> void:
	_set_page_visible(settings_page)
	_hide_exit_confirm()


func get_main_page() -> Control:
	return main_menu_shell


func get_deploy_page() -> Control:
	return deploy_page


func get_long_term_page() -> Control:
	return long_term_page


func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _build_main_menu() -> void:
	main_menu_shell = MainMenuShellScript.new() as Control
	main_menu_shell.name = "MainMenuShell"
	add_child(main_menu_shell)
	main_menu_shell.call("build")
	main_menu_shell.connect("navigation_intent_requested", _on_navigation_intent_requested)


func _build_deploy_prep() -> void:
	deploy_page = DeployPrepShellScript.new() as Control
	deploy_page.name = "DeployPrepShell"
	add_child(deploy_page)
	deploy_page.call("build")
	if deploy_page.has_signal("deploy_start_intent_requested"):
		deploy_page.connect("deploy_start_intent_requested", _on_deploy_start_intent_requested)


func _build_long_term() -> void:
	long_term_page = LongTermShellScript.new() as Control
	long_term_page.name = "LongTermShell"
	add_child(long_term_page)
	long_term_page.call("build")


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


func _build_exit_confirm_layer() -> void:
	exit_confirm_panel = PanelContainer.new()
	exit_confirm_panel.name = "ExitConfirmDialog"
	exit_confirm_panel.offset_left = 390.0
	exit_confirm_panel.offset_top = 210.0
	exit_confirm_panel.offset_right = 890.0
	exit_confirm_panel.offset_bottom = 470.0
	exit_confirm_panel.visible = false
	add_child(exit_confirm_panel)
	var content := VBoxContainer.new()
	content.name = "ExitConfirmContent"
	content.add_theme_constant_override("separation", 12)
	exit_confirm_panel.add_child(content)
	var title := Label.new()
	title.name = "ExitConfirmTitle"
	title.text = "退出游戏"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.warning"))
	content.add_child(title)
	exit_confirm_body = Label.new()
	exit_confirm_body.name = "ExitConfirmBody"
	exit_confirm_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exit_confirm_body.add_theme_font_size_override("font_size", 16)
	exit_confirm_body.add_theme_color_override("font_color", PresentationTheme.text_color())
	content.add_child(exit_confirm_body)
	var actions := HBoxContainer.new()
	actions.name = "ExitConfirmActions"
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)
	_add_menu_button(actions, "确认退出", func() -> void: get_tree().quit())
	_add_menu_button(actions, "取消", func() -> void: _hide_exit_confirm())
	_refresh_exit_confirm_text()


func _on_navigation_intent_requested(intent: Dictionary) -> void:
	var route := PageRouterScript.route_for_intent(intent)
	var page_id := StringName(route.get("page", PageRouterScript.PAGE_MAIN_MENU))
	match page_id:
		PageRouterScript.PAGE_DEPLOY_PLACEHOLDER:
			var deploy_payload := NavigationIntentScript.payload(intent)
			show_deploy(StringName(deploy_payload.get("tab", &"overview")))
		PageRouterScript.PAGE_LONG_TERM:
			var long_term_payload := NavigationIntentScript.payload(intent)
			show_long_term(StringName(long_term_payload.get("module_id", long_term_payload.get("entry_id", &"goals"))))
		PageRouterScript.PAGE_SETTINGS_PLACEHOLDER:
			show_settings()
		PageRouterScript.PAGE_EXIT_CONFIRM:
			_show_exit_confirm()
		PageRouterScript.PAGE_RUN:
			host_route_requested.emit(intent)
		_:
			show_main()


func _on_deploy_start_intent_requested(_intent: Dictionary) -> void:
	# DeployPrep remains preview-only; use main menu quick start for the current playable route.
	pass


func _set_page_visible(active_page: Control) -> void:
	for page: Control in [main_menu_shell, deploy_page, long_term_page, settings_page]:
		if page != null:
			page.visible = page == active_page


func _show_exit_confirm() -> void:
	_refresh_exit_confirm_text()
	if exit_confirm_panel != null:
		exit_confirm_panel.visible = true


func _hide_exit_confirm() -> void:
	if exit_confirm_panel != null:
		exit_confirm_panel.visible = false


func _refresh_exit_confirm_text() -> void:
	if exit_confirm_body == null:
		return
	var has_active_run := bool(current_snapshot.get("run_active", false))
	if has_active_run:
		exit_confirm_body.text = "检测到当前可能存在进行中探索。退出游戏不等于放弃探索；下次进入后应从出发探索页继续。若要放弃探索，需要进入出发探索页执行强确认。"
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
