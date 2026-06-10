extends Node2D

const CommandBusScript := preload("res://scripts/core/command/command_bus.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")
const HUDScene := preload("res://scenes/ui/hud/hud.tscn")
const MiniMapScene := preload("res://scenes/ui/minimap/minimap_panel.tscn")
const ResultPanelScene := preload("res://scenes/ui/result/result_panel.tscn")
const MapOverlayScene := preload("res://scenes/ui/map_overlay/map_overlay_panel.tscn")
const TutorialPopupScene := preload("res://scenes/ui/tutorial/tutorial_popup_panel.tscn")
const RoomScene := preload("res://scenes/room/room_scene.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")

const SCREEN_MAIN_MENU := &"main_menu"
const SCREEN_DEPLOY := &"deploy_shell"
const SCREEN_RUN := &"run"
const LEGACY_GRAYBOX_VALIDATION_MARKERS := ["Start Tutorial 5x5", "Start Standard 10x10", "Controls: W/A/S/D or arrows move"]

var run_context: RunContext
var command_bus: CommandBus
var ui_root: Control
var main_menu_panel: Control
var deploy_shell_panel: Control
var run_overlay_root: Control
var room_badge: Label
var protocol_badge: Label
var debug_panel: VBoxContainer
var debug_toggle_button: Button
var debug_log: Label
var event_panel: PanelContainer
var event_title_label: Label
var event_body_label: Label
var event_options_box: VBoxContainer
var loot_panel: PanelContainer
var loot_title_label: Label
var loot_body_label: Label
var extract_panel: PanelContainer
var extract_body_label: Label
var hud: Hud
var minimap_panel: MiniMapPanel
var result_panel: ResultPanel
var map_overlay_panel: MapOverlayPanel
var tutorial_popup_panel: TutorialPopupPanel
var room_controller: RoomSceneController
var player_controller: PlayerController
var screen_state: StringName = SCREEN_MAIN_MENU


func _ready() -> void:
	ContentDB.load_asset_manifest()
	run_context = RunContextScript.new()
	command_bus = CommandBusScript.new()
	command_bus.bind_context(run_context)
	command_bus.state_changed.connect(_on_state_changed)
	command_bus.result_available.connect(_on_result_available)
	_build_playfield_visuals()
	_build_accessible_ui()
	_show_main_menu()


func _process(delta: float) -> void:
	if screen_state != SCREEN_RUN:
		return
	if player_controller == null or command_bus == null or run_context == null:
		return
	if _is_runtime_modal_open():
		return
	if map_overlay_panel != null and map_overlay_panel.visible:
		return
	if run_context.has_blocking_tutorial_popup():
		return
	var move_vector := player_controller.get_move_vector()
	var local_result := player_controller.move_local(move_vector, delta)
	if StringName(local_result.get("status", &"")) == &"transition":
		_attempt_room_transition(local_result.get("direction", Vector2i.ZERO))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		if _close_top_runtime_modal():
			get_viewport().set_input_as_handled()
			return
		if screen_state == SCREEN_DEPLOY:
			_show_main_menu()
			get_viewport().set_input_as_handled()
			return

	if screen_state != SCREEN_RUN or run_context == null:
		return
	if run_context.has_blocking_tutorial_popup():
		return

	if event.is_action_pressed("interact"):
		_handle_interact_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("attack"):
		_fight_and_show_result()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("flag_cell"):
		command_bus.dispatch(&"flag_current_cell")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_map"):
		command_bus.dispatch(&"open_map")
		_toggle_map_overlay()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_restart_run"):
		command_bus.dispatch(&"restart_run")
		if player_controller != null:
			player_controller.reset_local_position()
		get_viewport().set_input_as_handled()


func _build_playfield_visuals() -> void:
	var room_layer := get_node("RoomLayer") as Node2D
	var player_layer := get_node("PlayerLayer") as Node2D

	room_controller = RoomScene.instantiate() as RoomSceneController
	room_controller.name = "RoomSceneController"
	room_layer.add_child(room_controller)

	player_controller = PlayerScene.instantiate() as PlayerController
	player_controller.name = "PlayerController"
	player_layer.add_child(player_controller)


func _build_accessible_ui() -> void:
	var ui_layer := get_node("UILayer") as CanvasLayer
	ui_root = Control.new()
	ui_root.name = "G7FlowRoot"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(ui_root)

	_build_main_menu()
	_build_deploy_shell()
	_build_run_overlay()
	_build_runtime_modals()


func _build_main_menu() -> void:
	main_menu_panel = Control.new()
	main_menu_panel.name = "MainMenuPanel"
	main_menu_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(main_menu_panel)

	_add_color_rect(main_menu_panel, "MainMenuBackdrop", Rect2(0, 0, 1280, 720), Color(0.03, 0.06, 0.07, 1.0))
	_add_texture_rect(main_menu_panel, "MainMenuRoomArt", Rect2(64, 224, 620, 350), &"room.background.normal", Color(1, 1, 1, 0.66))
	_add_color_rect(main_menu_panel, "MainMenuArtShade", Rect2(64, 224, 620, 350), Color(0.0, 0.0, 0.0, 0.18))
	var title := _add_label(main_menu_panel, "MainMenuTitle", Rect2(72, 72, 620, 96), "格外危除", 44)
	title.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.warning"))
	_add_label(main_menu_panel, "MainMenuSubtitle", Rect2(76, 164, 600, 56), "地牢入口已开启。选择出勤，或先完成新手教程。", 18)
	_add_label(main_menu_panel, "MainMenuSceneHint", Rect2(76, 520, 620, 80), "回收物、异常事件、地雷数字和撤离信标都在地下等你。", 16)

	var mode_panel := VBoxContainer.new()
	mode_panel.name = "ModeEntryPanel"
	mode_panel.offset_left = 850.0
	mode_panel.offset_top = 120.0
	mode_panel.offset_right = 1190.0
	mode_panel.offset_bottom = 520.0
	main_menu_panel.add_child(mode_panel)

	_add_menu_button(mode_panel, "出发探索", func() -> void: _show_deploy_shell())
	_add_menu_button(mode_panel, "新手教程", func() -> void: _start_tutorial_from_ui())
	_add_menu_button(mode_panel, "装备 / 天赋", func() -> void: _show_deploy_shell(&"talents"))
	_add_menu_button(mode_panel, "设置", func() -> void: _show_settings_shell())


func _build_deploy_shell() -> void:
	deploy_shell_panel = Control.new()
	deploy_shell_panel.name = "DeployShellPanel"
	deploy_shell_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(deploy_shell_panel)

	_add_color_rect(deploy_shell_panel, "DeployBackdrop", Rect2(0, 0, 1280, 720), Color(0.02, 0.05, 0.06, 1.0))
	_add_button(deploy_shell_panel, "BackToMainMenu", Rect2(32, 28, 180, 40), "返回主界面", func() -> void: _show_main_menu())
	_add_label(deploy_shell_panel, "DeployTitle", Rect2(260, 34, 440, 42), "出勤配置", 22)

	var tabs := HBoxContainer.new()
	tabs.name = "DeployShellTabs"
	tabs.offset_left = 640.0
	tabs.offset_top = 28.0
	tabs.offset_right = 1180.0
	tabs.offset_bottom = 72.0
	deploy_shell_panel.add_child(tabs)
	for tab_name in ["后勤仓库", "后勤申领", "出勤配置", "回收资历", "天赋", "设置"]:
		var captured_tab := String(tab_name)
		_add_menu_button(tabs, captured_tab, func() -> void: _select_deploy_tab(captured_tab))

	_add_color_rect(deploy_shell_panel, "DeployContentBand", Rect2(32, 108, 930, 560), Color(0.05, 0.09, 0.11, 0.96))
	_add_color_rect(deploy_shell_panel, "DeploySummaryBand", Rect2(990, 128, 250, 420), Color(0.07, 0.08, 0.08, 0.96))
	_add_label(deploy_shell_panel, "DeployCurrentTab", Rect2(56, 124, 420, 36), "当前模块：出勤配置", 20)
	_add_label(deploy_shell_panel, "DeployAccount", Rect2(720, 128, 240, 34), "后勤账本：结算币 0 | 物资 0", 16)
	_add_label(deploy_shell_panel, "DeploySummary", Rect2(1014, 156, 210, 220), "出勤摘要\n\n装备：未配置作业装备\n消耗品：未携带作业消耗品\n天赋：本局无额外加成", 16)
	_add_button(deploy_shell_panel, "StartStandard10x10Button", Rect2(1010, 590, 220, 58), "确认出发", func() -> void: _start_standard_from_ui())

	var card_data := [
		["area_sense", "区域感知", "区域扫描图 · 勘测", "进入房间时高亮周围 8 格风险。"],
		["thick_skin", "厚皮", "雷险区 · 防护", "雷伤降低 10 点。"],
		["pressure_clock", "威压", "异常体 · 防护", "异常体避让窗口增加。"],
		["salvage_clause", "抢救条款", "撤离 · 回收", "信号中断时额外保留回收物。"],
		["bargain", "议价", "事件 · 天赋", "旅商折价概率改善。"],
	]
	for index in range(card_data.size()):
		var row := index / 3
		var col := index % 3
		var rect := Rect2(56 + col * 300, 180 + row * 190, 270, 150)
		_add_deploy_card(deploy_shell_panel, card_data[index], rect)


func _build_run_overlay() -> void:
	run_overlay_root = Control.new()
	run_overlay_root.name = "RunOverlayRoot"
	run_overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(run_overlay_root)

	_add_color_rect(run_overlay_root, "LeftSidebar", Rect2(0, 0, 380, 720), Color(0.03, 0.06, 0.07, 0.94))
	_add_color_rect(run_overlay_root, "RightUtilityRail", Rect2(960, 0, 280, 720), Color(0.05, 0.05, 0.05, 0.78))
	_add_color_rect(run_overlay_root, "BottomActionBar", Rect2(390, 642, 560, 62), Color(0.03, 0.06, 0.07, 0.92))

	minimap_panel = MiniMapScene.instantiate() as MiniMapPanel
	minimap_panel.name = "MiniMapPanel"
	minimap_panel.offset_left = 18.0
	minimap_panel.offset_top = 22.0
	minimap_panel.offset_right = 358.0
	minimap_panel.offset_bottom = 238.0
	run_overlay_root.add_child(minimap_panel)

	hud = HUDScene.instantiate() as Hud
	hud.name = "HUD"
	run_overlay_root.add_child(hud)

	room_badge = _add_label(run_overlay_root, "RoomAreaStatusBadge", Rect2(420, 22, 440, 74), "Room Area", 16)
	room_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_color_rect(run_overlay_root, "RoomBadgeBackdrop", Rect2(410, 18, 460, 82), Color(0.03, 0.06, 0.07, 0.62))
	run_overlay_root.move_child(run_overlay_root.get_node("RoomBadgeBackdrop"), run_overlay_root.get_node("RoomAreaStatusBadge").get_index())

	protocol_badge = _add_label(run_overlay_root, "ProtocolStatusPanel", Rect2(980, 24, 238, 124), "Protocol", 18)
	protocol_badge.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
	_add_color_rect(run_overlay_root, "ProtocolBackdrop", Rect2(968, 16, 254, 140), Color(0.03, 0.07, 0.07, 0.94))
	run_overlay_root.move_child(run_overlay_root.get_node("ProtocolBackdrop"), protocol_badge.get_index())

	var action_bar := HBoxContainer.new()
	action_bar.name = "BottomActionBarButtons"
	action_bar.offset_left = 408.0
	action_bar.offset_top = 656.0
	action_bar.offset_right = 936.0
	action_bar.offset_bottom = 694.0
	run_overlay_root.add_child(action_bar)
	_add_label(run_overlay_root, "ControlsLabel", Rect2(410, 610, 540, 32), "WASD/方向键：房间内移动；走到门口才切换房间。", 14)
	_add_menu_button(action_bar, "E 搜索/交互", func() -> void: _handle_interact_pressed())
	_add_menu_button(action_bar, "F 标记", func() -> void: command_bus.dispatch(&"flag_current_cell"))
	_add_menu_button(action_bar, "Space/J 战斗", func() -> void: _fight_and_show_result())
	_add_menu_button(action_bar, "M 地图", func() -> void: _open_map_from_debug())
	_add_menu_button(action_bar, "R 重开", func() -> void: _restart_run_from_ui())

	debug_toggle_button = _add_button(run_overlay_root, "DebugToggleButton", Rect2(1010, 166, 170, 34), "调试 / 网格移动", func() -> void: _toggle_debug_panel())
	debug_panel = VBoxContainer.new()
	debug_panel.name = "DebugOperationPanel"
	debug_panel.offset_left = 980.0
	debug_panel.offset_top = 210.0
	debug_panel.offset_right = 1220.0
	debug_panel.offset_bottom = 690.0
	debug_panel.visible = false
	run_overlay_root.add_child(debug_panel)

	var debug_title := Label.new()
	debug_title.text = "Debug / Grid Move"
	debug_panel.add_child(debug_title)
	_add_debug_button(debug_panel, "Tutorial", func() -> void: _start_tutorial_from_ui())
	_add_debug_button(debug_panel, "Standard", func() -> void: _start_standard_from_ui())
	_add_debug_button(debug_panel, "GridUp", func() -> void: command_bus.dispatch(&"move_by", {"delta": Vector2i(0, -1), "source": "debug"}))
	_add_debug_button(debug_panel, "GridDown", func() -> void: command_bus.dispatch(&"move_by", {"delta": Vector2i(0, 1), "source": "debug"}))
	_add_debug_button(debug_panel, "GridLeft", func() -> void: command_bus.dispatch(&"move_by", {"delta": Vector2i(-1, 0), "source": "debug"}))
	_add_debug_button(debug_panel, "GridRight", func() -> void: command_bus.dispatch(&"move_by", {"delta": Vector2i(1, 0), "source": "debug"}))
	_add_debug_button(debug_panel, "Flag", func() -> void: command_bus.dispatch(&"flag_current_cell", {"source": "debug"}))
	_add_debug_button(debug_panel, "Search", func() -> void: _search_and_show_loot())
	_add_debug_button(debug_panel, "PickupFloor", func() -> void: _pickup_floor_from_ui())
	_add_debug_button(debug_panel, "DropItem", func() -> void: _drop_inventory_from_ui())
	_add_debug_button(debug_panel, "Interact", func() -> void: _handle_interact_pressed())
	_add_debug_button(debug_panel, "Fight", func() -> void: _fight_and_show_result())
	_add_debug_button(debug_panel, "Map", func() -> void: _open_map_from_debug())
	_add_debug_button(debug_panel, "ReqExtract", func() -> void: _request_extract_from_ui())
	_add_debug_button(debug_panel, "ConfirmExt", func() -> void: command_bus.dispatch(&"confirm_extract", {"source": "debug"}))
	_add_debug_button(debug_panel, "CancelExt", func() -> void: command_bus.dispatch(&"cancel_extract", {"source": "debug"}))

	debug_log = Label.new()
	debug_log.name = "DebugLastMessage"
	debug_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_log.custom_minimum_size = Vector2(220, 90)
	debug_panel.add_child(debug_log)

	result_panel = ResultPanelScene.instantiate() as ResultPanel
	result_panel.name = "ResultPanel"
	result_panel.hide_result()
	run_overlay_root.add_child(result_panel)

	map_overlay_panel = MapOverlayScene.instantiate() as MapOverlayPanel
	map_overlay_panel.name = "MapOverlayPanel"
	map_overlay_panel.cell_action_requested.connect(_on_map_overlay_cell_action_requested)
	run_overlay_root.add_child(map_overlay_panel)

	tutorial_popup_panel = TutorialPopupScene.instantiate() as TutorialPopupPanel
	tutorial_popup_panel.name = "TutorialPopupPanel"
	tutorial_popup_panel.confirmed.connect(_on_tutorial_popup_confirmed)
	run_overlay_root.add_child(tutorial_popup_panel)


func _build_runtime_modals() -> void:
	event_panel = _new_modal_panel("EventOptionPanel", Rect2(420, 140, 450, 360))
	var event_content := VBoxContainer.new()
	event_content.name = "EventOptionContent"
	event_panel.add_child(event_content)
	event_title_label = Label.new()
	event_title_label.text = "事件"
	event_content.add_child(event_title_label)
	event_body_label = Label.new()
	event_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_body_label.custom_minimum_size = Vector2(400, 78)
	event_content.add_child(event_body_label)
	event_options_box = VBoxContainer.new()
	event_options_box.name = "EventOptionButtons"
	event_content.add_child(event_options_box)
	_add_menu_button(event_content, "关闭", func() -> void: event_panel.visible = false)

	loot_panel = _new_modal_panel("LootResultPanel", Rect2(430, 160, 430, 300))
	var loot_content := VBoxContainer.new()
	loot_content.name = "LootResultContent"
	loot_panel.add_child(loot_content)
	loot_title_label = Label.new()
	loot_title_label.text = "回收结果"
	loot_content.add_child(loot_title_label)
	loot_body_label = Label.new()
	loot_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_body_label.custom_minimum_size = Vector2(390, 180)
	loot_content.add_child(loot_body_label)
	_add_menu_button(loot_content, "关闭", func() -> void: loot_panel.visible = false)

	extract_panel = _new_modal_panel("ExtractConfirmPanel", Rect2(430, 180, 430, 260))
	var extract_content := VBoxContainer.new()
	extract_content.name = "ExtractConfirmContent"
	extract_panel.add_child(extract_content)
	var extract_title := Label.new()
	extract_title.text = "确认撤离"
	extract_content.add_child(extract_title)
	extract_body_label = Label.new()
	extract_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	extract_body_label.custom_minimum_size = Vector2(390, 120)
	extract_content.add_child(extract_body_label)
	var extract_buttons := HBoxContainer.new()
	extract_content.add_child(extract_buttons)
	_add_menu_button(extract_buttons, "确认", func() -> void: _confirm_extract_from_ui())
	_add_menu_button(extract_buttons, "取消", func() -> void: _cancel_extract_from_ui())


func _new_modal_panel(node_name: String, rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.offset_left = rect.position.x
	panel.offset_top = rect.position.y
	panel.offset_right = rect.position.x + rect.size.x
	panel.offset_bottom = rect.position.y + rect.size.y
	panel.visible = false
	run_overlay_root.add_child(panel)
	return panel


func _show_main_menu() -> void:
	screen_state = SCREEN_MAIN_MENU
	_set_gameplay_visible(false)
	main_menu_panel.visible = true
	deploy_shell_panel.visible = false
	run_overlay_root.visible = false
	_hide_runtime_popups()


func _show_deploy_shell(selected_tab: StringName = &"loadout") -> void:
	screen_state = SCREEN_DEPLOY
	_set_gameplay_visible(false)
	main_menu_panel.visible = false
	deploy_shell_panel.visible = true
	run_overlay_root.visible = false
	_hide_runtime_popups()
	match selected_tab:
		&"talents":
			_select_deploy_tab("天赋")
		&"settings":
			_select_deploy_tab("设置")
		_:
			_select_deploy_tab("出勤配置")


func _show_settings_shell() -> void:
	_show_deploy_shell(&"settings")


func _show_run_screen() -> void:
	screen_state = SCREEN_RUN
	_set_gameplay_visible(true)
	main_menu_panel.visible = false
	deploy_shell_panel.visible = false
	run_overlay_root.visible = true
	_hide_runtime_popups()
	if debug_panel != null:
		debug_panel.visible = false
	_refresh_view_models()


func _set_gameplay_visible(visible: bool) -> void:
	var room_layer := get_node_or_null("RoomLayer") as Node2D
	var player_layer := get_node_or_null("PlayerLayer") as Node2D
	if room_layer != null:
		room_layer.visible = visible
	if player_layer != null:
		player_layer.visible = visible


func _select_deploy_tab(tab_name: String) -> void:
	var label := deploy_shell_panel.get_node_or_null("DeployCurrentTab") as Label
	if label != null:
		label.text = "当前模块：%s" % tab_name


func _add_deploy_card(parent: Control, data: Array, rect: Rect2) -> void:
	_add_color_rect(parent, "DeployCard_%s" % String(data[0]), rect, Color(0.08, 0.11, 0.14, 1.0))
	_add_label(parent, "DeployCardTitle_%s" % String(data[0]), Rect2(rect.position.x + 16, rect.position.y + 14, rect.size.x - 32, 28), String(data[1]), 18)
	_add_label(parent, "DeployCardType_%s" % String(data[0]), Rect2(rect.position.x + 16, rect.position.y + 48, rect.size.x - 32, 24), String(data[2]), 14)
	_add_label(parent, "DeployCardBody_%s" % String(data[0]), Rect2(rect.position.x + 16, rect.position.y + 78, rect.size.x - 32, 48), String(data[3]), 14)


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


func _add_texture_rect(parent: Control, node_name: String, rect: Rect2, asset_id: StringName, modulate_color: Color = Color.WHITE) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.offset_left = rect.position.x
	texture_rect.offset_top = rect.position.y
	texture_rect.offset_right = rect.position.x + rect.size.x
	texture_rect.offset_bottom = rect.position.y + rect.size.y
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.modulate = modulate_color
	var asset_ref := ContentDB.get_asset_ref(asset_id)
	if asset_ref is Texture2D:
		texture_rect.texture = asset_ref
	parent.add_child(texture_rect)
	return texture_rect


func _add_label(parent: Control, node_name: String, rect: Rect2, text: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.offset_left = rect.position.x
	label.offset_top = rect.position.y
	label.offset_right = rect.position.x + rect.size.x
	label.offset_bottom = rect.position.y + rect.size.y
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", PresentationTheme.text_color())
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


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


func _add_menu_button(parent: Control, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(150, 34)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_debug_button(parent: Control, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(200, 28)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _handle_interact_pressed() -> void:
	if command_bus == null or run_context == null or _is_runtime_modal_open():
		return
	var snapshot := run_context.get_status_snapshot()
	var current_room := StringName(snapshot.get("current_room", &"Unknown"))
	var search_data: Dictionary = snapshot.get("search_state_data", {})
	if current_room == &"Event":
		var event_state: Dictionary = snapshot.get("event_state", {})
		if not event_state.is_empty() and not bool(event_state.get("completed", false)):
			_show_event_panel(event_state)
			return
	if current_room == &"Exit":
		if StringName(snapshot.get("phase", &"running")) == &"confirm_extract":
			_show_extract_panel(snapshot)
		else:
			_request_extract_from_ui()
		return
	if bool(search_data.get("can_search", false)):
		_search_and_show_loot()
		return
	command_bus.dispatch(&"interact_current_room")


func _search_and_show_loot() -> void:
	if command_bus == null:
		return
	command_bus.dispatch(&"search_current_room")
	var snapshot := run_context.get_status_snapshot()
	var reward: Dictionary = snapshot.get("last_reward", {})
	if not reward.is_empty():
		_show_loot_panel("回收结果", reward)


func _fight_and_show_result() -> void:
	if command_bus == null:
		return
	command_bus.dispatch(&"fight_current_enemy")
	var snapshot := run_context.get_status_snapshot()
	var reward: Dictionary = snapshot.get("last_reward", {})
	if not reward.is_empty():
		_show_loot_panel("战斗结果", reward)


func _pickup_floor_from_ui() -> void:
	if command_bus == null:
		return
	var result := command_bus.dispatch(&"pickup_ground_item")
	_show_loot_panel("Floor Command", result)


func _drop_inventory_from_ui() -> void:
	if command_bus == null:
		return
	var result := command_bus.dispatch(&"drop_inventory_item")
	_show_loot_panel("Floor Command", result)


func _show_event_panel(event_state: Dictionary) -> void:
	if event_panel == null:
		return
	event_title_label.text = "事件：%s" % _event_type_label(StringName(event_state.get("event_type", &"event")))
	event_body_label.text = "选择处理方式。事件完成后不会重复结算奖励。"
	for child in event_options_box.get_children():
		child.queue_free()
	var options: Array = event_state.get("options", [])
	for option in options:
		var option_id := StringName(option.get("id", &"leave"))
		var option_label := String(option.get("label", String(option_id)))
		var button := _add_menu_button(event_options_box, option_label, func() -> void: _select_event_option(option_id))
		button.disabled = not bool(option.get("enabled", true))
	event_panel.visible = true


func _select_event_option(option_id: StringName) -> void:
	event_panel.visible = false
	command_bus.dispatch(&"select_event_option", {"option_id": option_id})
	var snapshot := run_context.get_status_snapshot()
	var reward: Dictionary = snapshot.get("last_reward", {})
	if not reward.is_empty():
		_show_loot_panel("事件结果", reward)


func _request_extract_from_ui() -> void:
	command_bus.dispatch(&"request_extract")
	_show_extract_panel(run_context.get_status_snapshot())


func _show_extract_panel(snapshot: Dictionary) -> void:
	if StringName(snapshot.get("phase", &"running")) != &"confirm_extract":
		return
	extract_body_label.text = "待结算：%s\n安全回收：%s\n回收物：%s\n协议等级：%s\n确认从该出口撤离？" % [
		snapshot.get("pending_gold", 0),
		snapshot.get("safe_gold", 0),
		snapshot.get("parts", 0),
		snapshot.get("protocol_level", 5),
	]
	extract_body_label.text += "\nBlack Coin: %s\nGold Coin: %s\nBag: %s/%s\nFloor left behind: %s" % [
		snapshot.get("black_coin", snapshot.get("pending_gold", 0)),
		snapshot.get("gold_coin", snapshot.get("safe_gold", 0)),
		snapshot.get("backpack_used", 0),
		snapshot.get("backpack_capacity", 0),
		snapshot.get("room_floor_item_count", 0),
	]
	extract_panel.visible = true


func _confirm_extract_from_ui() -> void:
	extract_panel.visible = false
	command_bus.dispatch(&"confirm_extract")


func _cancel_extract_from_ui() -> void:
	extract_panel.visible = false
	command_bus.dispatch(&"cancel_extract")


func _show_loot_panel(title: String, reward: Dictionary) -> void:
	if loot_panel == null:
		return
	loot_title_label.text = title
	loot_body_label.text = _format_reward(reward)
	loot_panel.visible = true


func _format_reward(reward: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("记录：%s" % String(run_context.last_message))
	if reward.has("gold"):
		lines.append("待结算 +%s" % reward.get("gold", 0))
	if reward.has("pending_gold_delta"):
		lines.append("待结算变化：%s" % reward.get("pending_gold_delta", 0))
	if reward.has("safe_gold"):
		lines.append("安全回收 +%s" % reward.get("safe_gold", 0))
	if reward.has("reward_gold"):
		lines.append("战斗回收 +%s" % reward.get("reward_gold", 0))
	if reward.has("black_coin_delta"):
		lines.append("Black Coin delta: %s" % reward.get("black_coin_delta", 0))
	if reward.has("gold_coin_delta"):
		lines.append("Gold Coin delta: %s" % reward.get("gold_coin_delta", 0))
	if reward.has("damage"):
		lines.append("受伤：%s" % reward.get("damage", 0))
	if reward.has("hp_delta"):
		lines.append("生命变化：%s" % reward.get("hp_delta", 0))
	var items: Array = reward.get("items", [])
	if not items.is_empty():
		lines.append("回收物：%s 件" % items.size())
	var ground_items: Array = reward.get("ground_items", [])
	if not ground_items.is_empty():
		lines.append("Ground items: %s" % ground_items.size())
	if reward.has("capacity"):
		var capacity: Dictionary = reward.get("capacity", {})
		lines.append("Bag: %s/%s" % [capacity.get("used", 0), capacity.get("capacity", 0)])
	if String(reward.get("blocked_reason", reward.get("reason", ""))) != "":
		lines.append("Blocked: %s" % String(reward.get("blocked_reason", reward.get("reason", ""))))
	if reward.has("roll"):
		lines.append("骰子点数：%s" % reward.get("roll", 0))
	var text := ""
	for line in lines:
		text += line + "\n"
	return text.strip_edges()


func _restart_run_from_ui() -> void:
	command_bus.dispatch(&"restart_run")
	if player_controller != null:
		player_controller.reset_local_position()


func _event_type_label(event_type: StringName) -> String:
	match event_type:
		&"trader":
			return "旅商"
		&"dice":
			return "骰局"
		&"altar":
			return "祭坛"
		&"trap":
			return "机关"
		_:
			return "异常事件"


func _is_runtime_modal_open() -> bool:
	return (event_panel != null and event_panel.visible) or (loot_panel != null and loot_panel.visible) or (extract_panel != null and extract_panel.visible)


func _close_top_runtime_modal() -> bool:
	if event_panel != null and event_panel.visible:
		event_panel.visible = false
		return true
	if loot_panel != null and loot_panel.visible:
		loot_panel.visible = false
		return true
	if extract_panel != null and extract_panel.visible:
		_cancel_extract_from_ui()
		return true
	return false


func _hide_runtime_popups() -> void:
	if event_panel != null:
		event_panel.visible = false
	if loot_panel != null:
		loot_panel.visible = false
	if extract_panel != null:
		extract_panel.visible = false
	if result_panel != null:
		result_panel.hide_result()
	if map_overlay_panel != null:
		map_overlay_panel.hide_overlay()


func _on_state_changed(_snapshot: Dictionary) -> void:
	_refresh_view_models()


func _on_result_available(snapshot: Dictionary) -> void:
	_refresh_view_models()
	if result_panel != null:
		result_panel.show_summary(snapshot)


func _refresh_view_models() -> void:
	if run_context == null:
		return

	var snapshot := run_context.get_status_snapshot()
	var pos: Vector2i = snapshot.get("position", Vector2i.ZERO)
	var minimap_vm := MiniMapViewModel.build_from_intel(run_context.intel_map, run_context.get_current_pos())
	if room_badge != null:
		room_badge.text = "模式：%s | 阶段：%s | 房间：%s\n坐标：(%d,%d) | 周围雷险：%s" % [
			String(snapshot.get("mode", &"")),
			String(snapshot.get("phase", &"")),
			String(snapshot.get("current_room", &"Unknown")),
			pos.x,
			pos.y,
			snapshot.get("adjacent_mines", 0),
		]
	if protocol_badge != null:
		protocol_badge.text = "协议 %s\n压力：%s / 100\n状态：%s" % [
			snapshot.get("protocol_level", 5),
			snapshot.get("pressure", 0),
			snapshot.get("outcome", "Running"),
		]

	if room_controller != null:
		room_controller.configure(PresentationMapping.room_visual_from_snapshot(snapshot))
	if player_controller != null:
		player_controller.set_visual_asset(&"sprite.player.default")
	if hud != null:
		hud.apply_view_model(HUDViewModel.build_from_snapshot(snapshot))
	if minimap_panel != null:
		minimap_panel.apply_view_model(minimap_vm)
	if map_overlay_panel != null:
		map_overlay_panel.apply_view_model(minimap_vm)
	if tutorial_popup_panel != null:
		tutorial_popup_panel.apply_popup(snapshot.get("tutorial_popup", {}))
	if debug_log != null:
		debug_log.text = String(snapshot.get("last_message", ""))
	if result_panel != null and bool(snapshot.get("run_active", false)):
		result_panel.hide_result()


func _toggle_map_overlay() -> void:
	if map_overlay_panel != null:
		map_overlay_panel.toggle_overlay()


func _toggle_debug_panel() -> void:
	if debug_panel != null:
		debug_panel.visible = not debug_panel.visible


func _open_map_from_debug() -> void:
	command_bus.dispatch(&"open_map")
	_toggle_map_overlay()


func _on_tutorial_popup_confirmed() -> void:
	if command_bus != null:
		command_bus.dispatch(&"confirm_tutorial_popup")


func _start_tutorial_from_ui() -> void:
	command_bus.dispatch(&"start_tutorial_run")
	if player_controller != null:
		player_controller.reset_local_position()
	_show_run_screen()


func _start_standard_from_ui() -> void:
	command_bus.dispatch(&"start_standard_run")
	if player_controller != null:
		player_controller.reset_local_position()
	_show_run_screen()


func _attempt_room_transition(direction: Vector2i) -> void:
	var before := run_context.get_current_pos()
	var result := command_bus.dispatch(&"attempt_room_transition", {"direction": direction})
	var moved := bool(result.get("ok", false)) and run_context.get_current_pos() != before
	if moved:
		player_controller.place_from_entry(direction)
	else:
		player_controller.block_transition(direction)


func _on_map_overlay_cell_action_requested(marker: Dictionary) -> void:
	if command_bus == null or run_context == null:
		return
	var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
	var state := StringName(marker.get("state", &"hidden"))
	if state == &"hidden" or state == &"flagged":
		command_bus.dispatch(&"toggle_flag_cell", {"pos": pos})
		return
	if bool(marker.get("explored", false)) and not bool(marker.get("mine", false)):
		var result := command_bus.dispatch(&"teleport_to_explored", {"pos": pos})
		if bool(result.get("ok", false)):
			if player_controller != null:
				player_controller.reset_local_position()
			if map_overlay_panel != null:
				map_overlay_panel.hide_overlay()
