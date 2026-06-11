extends Control
class_name G9ShellPanel

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")

signal main_entry_requested(entry_id: StringName)
signal deploy_entry_requested(entry_id: StringName)
signal long_term_entry_requested(entry_id: StringName)
signal start_tutorial_requested
signal start_standard_requested

const PAGE_MAIN := &"main"
const PAGE_DEPLOY := &"deploy"
const PAGE_LONG_TERM := &"long_term"
const PAGE_SETTINGS := &"settings"

var current_page: StringName = PAGE_MAIN
var current_deploy_tab: StringName = &"config"
var center_expanded: bool = true

var main_page: Control
var deploy_page: Control
var long_term_page: Control
var settings_page: Control
var deploy_title_label: Label
var deploy_body_label: Label
var deploy_summary_label: Label
var deploy_center_panel: Control
var long_term_body_label: Label
var long_term_summary_label: Label
var settings_body_label: Label


func _ready() -> void:
	if main_page == null:
		build()


func build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_main_page()
	_build_deploy_page()
	_build_long_term_page()
	_build_settings_page()
	show_main()


func show_main() -> void:
	current_page = PAGE_MAIN
	_set_page_visible(main_page)


func show_deploy(tab_id: StringName = &"config") -> void:
	current_page = PAGE_DEPLOY
	_set_page_visible(deploy_page)
	select_deploy_tab(tab_id)


func show_long_term(entry_id: StringName = &"tasks") -> void:
	current_page = PAGE_LONG_TERM
	_set_page_visible(long_term_page)
	_select_long_term_entry(entry_id)


func show_settings() -> void:
	current_page = PAGE_SETTINGS
	_set_page_visible(settings_page)


func apply_snapshot(snapshot: Dictionary) -> void:
	if deploy_summary_label != null:
		deploy_summary_label.text = RunUIViewModel.format_expedition_summary(snapshot)
	if long_term_summary_label != null:
		long_term_summary_label.text = RunUIViewModel.format_long_term_summary(snapshot)


func get_main_page() -> Control:
	return main_page


func get_deploy_page() -> Control:
	return deploy_page


func get_long_term_page() -> Control:
	return long_term_page


func select_deploy_tab(tab_id: StringName) -> void:
	current_deploy_tab = tab_id
	if deploy_title_label != null:
		deploy_title_label.text = _deploy_tab_title(tab_id)
	if deploy_body_label != null:
		deploy_body_label.text = _deploy_tab_body(tab_id)


func _set_page_visible(active_page: Control) -> void:
	for page: Control in [main_page, deploy_page, long_term_page, settings_page]:
		if page != null:
			page.visible = page == active_page


func _build_main_page() -> void:
	main_page = Control.new()
	main_page.name = "MainMenuPanel"
	main_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_page)

	_add_color_rect(main_page, "MainMenuBackdrop", Rect2(0, 0, 1280, 720), Color(0.025, 0.05, 0.055, 1.0))
	_add_color_rect(main_page, "BaseBackgroundLayer", Rect2(42, 66, 700, 560), Color(0.07, 0.11, 0.12, 0.94))
	_add_color_rect(main_page, "ThemeOverlayLayer", Rect2(68, 228, 640, 260), Color(0.12, 0.22, 0.21, 0.38))
	_add_color_rect(main_page, "CharacterLayer", Rect2(90, 184, 180, 332), Color(0.18, 0.24, 0.23, 0.65))
	_add_label(main_page, "MainMenuTitle", Rect2(76, 66, 560, 64), "灰尾回收", 44, PresentationTheme.color_for_key(&"ui.warning"))
	_add_label(main_page, "MainMenuSubtitle", Rect2(80, 136, 620, 48), "五四三二一 | 局内回收、风险探索、结算解释基线", 18)
	_add_label(main_page, "MainMenuSceneHint", Rect2(82, 526, 620, 78), "固定基地背景承载空间骨架；地图主题、角色、穿搭、装饰和特效以 Presentation Overlay 叠加。", 16)

	var mode_panel := VBoxContainer.new()
	mode_panel.name = "ModeEntryPanel"
	mode_panel.offset_left = 828.0
	mode_panel.offset_top = 96.0
	mode_panel.offset_right = 1190.0
	mode_panel.offset_bottom = 530.0
	mode_panel.add_theme_constant_override("separation", 12)
	main_page.add_child(mode_panel)

	_add_section_label(mode_panel, "主要入口")
	_add_menu_button(mode_panel, "出发探索", func() -> void: main_entry_requested.emit(&"deploy"))
	_add_menu_button(mode_panel, "长期系统", func() -> void: main_entry_requested.emit(&"long_term"))
	_add_menu_button(mode_panel, "设置", func() -> void: main_entry_requested.emit(&"settings"))
	_add_section_label(mode_panel, "低权重入口")
	_add_menu_button(mode_panel, "教学局", func() -> void: start_tutorial_requested.emit())
	_add_menu_button(mode_panel, "继续标准局", func() -> void: start_standard_requested.emit())

	var shortcut_panel := HBoxContainer.new()
	shortcut_panel.name = "ShortcutEntryPanel"
	shortcut_panel.offset_left = 76.0
	shortcut_panel.offset_top = 620.0
	shortcut_panel.offset_right = 744.0
	shortcut_panel.offset_bottom = 676.0
	shortcut_panel.add_theme_constant_override("separation", 10)
	main_page.add_child(shortcut_panel)
	_add_menu_button(shortcut_panel, "快速：确认出发", func() -> void: main_entry_requested.emit(&"deploy_config"))
	_add_menu_button(shortcut_panel, "快速：任务", func() -> void: long_term_entry_requested.emit(&"tasks"))
	_add_menu_button(shortcut_panel, "快速：图鉴", func() -> void: long_term_entry_requested.emit(&"codex"))


func _build_deploy_page() -> void:
	deploy_page = Control.new()
	deploy_page.name = "DeployShellPanel"
	deploy_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(deploy_page)

	_add_color_rect(deploy_page, "DeployBackdrop", Rect2(0, 0, 1280, 720), Color(0.02, 0.045, 0.052, 1.0))
	_add_button(deploy_page, "BackToMainMenu", Rect2(32, 28, 150, 40), "返回主界面", func() -> void: deploy_entry_requested.emit(&"back_main"))
	_add_label(deploy_page, "DeployTitle", Rect2(214, 30, 330, 42), "出发探索", 26, PresentationTheme.color_for_key(&"ui.accent"))

	var tabs := HBoxContainer.new()
	tabs.name = "DeployShellTabs"
	tabs.offset_left = 520.0
	tabs.offset_top = 28.0
	tabs.offset_right = 1210.0
	tabs.offset_bottom = 76.0
	tabs.add_theme_constant_override("separation", 6)
	deploy_page.add_child(tabs)
	for tab_data: Array in [
		[&"map", "地图"],
		[&"warehouse", "后勤仓库"],
		[&"claim", "后勤申领"],
		[&"config", "出勤配置"],
		[&"talents", "天赋"],
		[&"character", "角色/穿搭"],
	]:
		var tab_id: StringName = tab_data[0]
		var label := String(tab_data[1])
		_add_menu_button(tabs, label, func() -> void: select_deploy_tab(tab_id))

	_add_color_rect(deploy_page, "DeployContentBand", Rect2(32, 106, 912, 562), Color(0.05, 0.09, 0.105, 0.96))
	_add_color_rect(deploy_page, "DeploySummaryBand", Rect2(970, 116, 278, 494), Color(0.07, 0.085, 0.085, 0.96))
	deploy_center_panel = _add_color_rect(deploy_page, "DeployCenterPanel", Rect2(58, 150, 850, 398), Color(0.06, 0.105, 0.12, 0.92))
	deploy_title_label = _add_label(deploy_page, "DeployCurrentTab", Rect2(62, 120, 460, 34), "出勤配置", 20, PresentationTheme.color_for_key(&"ui.accent"))
	deploy_body_label = _add_label(deploy_page, "DeployBody", Rect2(82, 172, 790, 330), "", 16)
	deploy_summary_label = _add_label(deploy_page, "DeploySummary", Rect2(990, 142, 236, 350), "出勤摘要", 15)
	_add_button(deploy_page, "ToggleCenterPanelButton", Rect2(782, 558, 126, 36), "收放面板", func() -> void: _toggle_center_panel())
	_add_button(deploy_page, "StartTutorialButton", Rect2(990, 506, 110, 44), "教学局", func() -> void: start_tutorial_requested.emit())
	_add_button(deploy_page, "StartStandard10x10Button", Rect2(1110, 506, 118, 44), "标准局", func() -> void: start_standard_requested.emit())
	_add_button(deploy_page, "ConfirmDeployButton", Rect2(990, 566, 238, 56), "确认出发", func() -> void: start_standard_requested.emit())


func _build_long_term_page() -> void:
	long_term_page = Control.new()
	long_term_page.name = "LongTermSystemPanel"
	long_term_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(long_term_page)

	_add_color_rect(long_term_page, "LongTermBackdrop", Rect2(0, 0, 1280, 720), Color(0.025, 0.043, 0.05, 1.0))
	_add_button(long_term_page, "LongTermBackToMainMenu", Rect2(32, 28, 150, 40), "返回主界面", func() -> void: long_term_entry_requested.emit(&"back_main"))
	_add_label(long_term_page, "LongTermTitle", Rect2(214, 30, 360, 42), "长期系统", 26, PresentationTheme.color_for_key(&"ui.accent"))
	_add_color_rect(long_term_page, "LongTermContentBand", Rect2(32, 104, 912, 564), Color(0.05, 0.08, 0.10, 0.96))
	_add_color_rect(long_term_page, "LongTermSummaryBand", Rect2(970, 116, 278, 494), Color(0.07, 0.08, 0.085, 0.96))

	var nav := VBoxContainer.new()
	nav.name = "LongTermNavigationPanel"
	nav.offset_left = 60.0
	nav.offset_top = 130.0
	nav.offset_right = 260.0
	nav.offset_bottom = 620.0
	nav.add_theme_constant_override("separation", 8)
	long_term_page.add_child(nav)
	for entry_data: Array in [
		[&"tasks", "任务"],
		[&"codex", "图鉴"],
		[&"achievements", "成就"],
		[&"profile", "回收资历"],
		[&"research", "研究"],
	]:
		var entry_id: StringName = entry_data[0]
		var label := String(entry_data[1])
		_add_menu_button(nav, label, func() -> void: _select_long_term_entry(entry_id))

	long_term_body_label = _add_label(long_term_page, "LongTermBody", Rect2(300, 136, 590, 430), "", 16)
	long_term_summary_label = _add_label(long_term_page, "LongTermSummary", Rect2(992, 144, 232, 350), "长期摘要", 15)
	_add_button(long_term_page, "ShortcutToDeployButton", Rect2(990, 560, 238, 46), "快速跳转：出发探索", func() -> void: long_term_entry_requested.emit(&"deploy"))
	_select_long_term_entry(&"tasks")


func _build_settings_page() -> void:
	settings_page = Control.new()
	settings_page.name = "SettingsShellPanel"
	settings_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(settings_page)

	_add_color_rect(settings_page, "SettingsBackdrop", Rect2(0, 0, 1280, 720), Color(0.025, 0.045, 0.05, 1.0))
	_add_button(settings_page, "SettingsBackToMainMenu", Rect2(32, 28, 150, 40), "返回主界面", func() -> void: main_entry_requested.emit(&"main"))
	_add_label(settings_page, "SettingsTitle", Rect2(214, 30, 360, 42), "设置", 26, PresentationTheme.color_for_key(&"ui.accent"))
	settings_body_label = _add_label(settings_page, "SettingsBody", Rect2(80, 130, 980, 320), "本阶段保留设置入口与壳层，不写入本地持久化偏好。\n\n可后续接入音量、窗口、可访问性、UI 减法与 Debug 可见性策略。", 18)


func _toggle_center_panel() -> void:
	center_expanded = not center_expanded
	if deploy_center_panel != null:
		deploy_center_panel.visible = center_expanded
	if deploy_body_label != null:
		deploy_body_label.visible = center_expanded


func _select_long_term_entry(entry_id: StringName) -> void:
	if long_term_body_label == null:
		return
	match entry_id:
		&"tasks":
			long_term_body_label.text = "任务\n\n壳层占位：展示当前追踪目标、推荐出勤方向与后续任务系统入口。\n\nG9 不实现完整任务后端。"
		&"codex":
			long_term_body_label.text = "图鉴\n\n壳层占位：后续展示敌人、事件、藏品、地图主题与回收记录。\n\n当前只保留入口和接口。"
		&"achievements":
			long_term_body_label.text = "成就\n\n壳层占位：后续接入 EventLog / TransactionLog 派生统计。\n\nG9 不写持久化。"
		&"profile":
			long_term_body_label.text = "回收资历\n\n壳层占位：展示资历等级、经验、永久奖励预览。\n\n完整长期进度后置。"
		&"research":
			long_term_body_label.text = "研究\n\n壳层占位：后续接入研究树、资源消耗与解锁条件。\n\nG9 不实现研究后端。"
		_:
			long_term_body_label.text = "长期系统\n\n选择左侧入口查看占位说明。"


func _deploy_tab_title(tab_id: StringName) -> String:
	match tab_id:
		&"map":
			return "地图"
		&"warehouse":
			return "后勤仓库"
		&"claim":
			return "后勤申领"
		&"talents":
			return "天赋"
		&"character":
			return "角色/穿搭"
		&"settings":
			return "设置"
		_:
			return "出勤配置"


func _deploy_tab_body(tab_id: StringName) -> String:
	match tab_id:
		&"map":
			return "地图主题与路线预览\n\n当前显示为壳层：后续通过 ThemeProfile / PresentationLayerEntry 接入地图主题 overlay、路线推荐和危险等级表现。"
		&"warehouse":
			return "后勤仓库\n\n当前显示 Warehouse Lite 出口说明，不实现完整仓库经济、筛选、出售或强化。\n\n结算带出的非消耗品会在 ResultPanel 中解释。"
		&"claim":
			return "后勤申领\n\n当前保留申领入口与接口；不实现完整 Deploy 持久化、保险、托运或抽奖池。"
		&"talents":
			return "天赋\n\n当前展示天赋入口和壳层说明；规则接入应走 RulePipeline / ModifierSpec。"
		&"character":
			return "角色 / 穿搭\n\n当前保留 character_id、outfit_id、pose_id、equipment_overlay_ids 接入口；不实现完整角色制或个人穿搭。"
		&"settings":
			return "设置\n\n本阶段只保留设置壳层，不写本地持久化，不保存本地偏好。"
		_:
			return "出勤配置\n\n可选择教学局或标准局。右侧摘要来自当前 Run snapshot / ViewModel。\n\n正式 UI 只 dispatch command；状态读取走 snapshot。"


func _add_section_label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.muted"))
	label.add_theme_font_size_override("font_size", 14)
	parent.add_child(label)
	return label


func _add_menu_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 36)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


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


func _add_label(parent: Control, node_name: String, rect: Rect2, text: String, font_size: int = 16, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.offset_left = rect.position.x
	label.offset_top = rect.position.y
	label.offset_right = rect.position.x + rect.size.x
	label.offset_bottom = rect.position.y + rect.size.y
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var final_color := PresentationTheme.text_color() if color == Color.WHITE else color
	label.add_theme_color_override("font_color", final_color)
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
