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
const G9ShellPanelScript := preload("res://scripts/ui/shell/g9_shell_panel.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory/inventory_panel.gd")
const GroundLootPanelScript := preload("res://scripts/ui/ground_loot/ground_loot_panel.gd")
const DevDiagnosticsPanelScript := preload("res://scripts/ui/dev/dev_diagnostics_panel.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")
const G10ArtSmokeRegistry := preload("res://scripts/presentation/g10_art_smoke_registry.gd")
const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")

const SCREEN_MAIN_MENU := &"main_menu"
const SCREEN_DEPLOY := &"deploy_shell"
const SCREEN_LONG_TERM := &"long_term_shell"
const SCREEN_SETTINGS := &"settings_shell"
const SCREEN_RUN := &"run"

const LEGACY_GRAYBOX_VALIDATION_MARKERS := ["Start Tutorial 5x5", "Start Standard 10x10", "Controls: W/A/S/D or arrows move"]
const G9_UI_NODE_VALIDATION_MARKERS := [
	"MainMenuPanel",
	"ModeEntryPanel",
	"DeployShellPanel",
	"DeployShellTabs",
	"StartStandard10x10Button",
	"LongTermSystemPanel",
	"InventoryPanel",
	"GroundLootPanel",
	"ResultPanel",
	"RunOverlayRoot",
	"LeftSidebar",
	"RightUtilityRail",
	"ProtocolStatusPanel",
	"BottomActionBar",
	"BottomActionBarButtons",
	"DebugToggleButton",
	"EventOptionPanel",
	"LootResultPanel",
	"ExtractConfirmPanel",
]

var run_context: RunContext
var command_bus: CommandBus
var ui_root: Control
var ui_shell: Control
var main_menu_panel: Control
var deploy_shell_panel: Control
var long_term_shell_panel: Control
var run_overlay_root: Control
var room_badge: Label
var protocol_badge: Label
var command_result_label: Label
var debug_panel: VBoxContainer
var debug_toggle_button: Button
var debug_log: Label
var layout_profile_label: Label
var pause_panel: PanelContainer
var pause_status_label: Label
var dev_diagnostics_panel: Control
var event_panel: PanelContainer
var event_title_label: Label
var event_body_label: Label
var event_options_box: VBoxContainer
var loot_panel: PanelContainer
var loot_title_label: Label
var loot_body_label: Label
var extract_panel: PanelContainer
var extract_body_label: Label
var inventory_panel: Control
var ground_loot_panel: Control
var hud: Hud
var minimap_panel: MiniMapPanel
var result_panel: ResultPanel
var map_overlay_panel: MapOverlayPanel
var tutorial_popup_panel: TutorialPopupPanel
var room_controller: RoomSceneController
var player_controller: PlayerController
var screen_state: StringName = SCREEN_MAIN_MENU
var current_layout_profile_id: StringName = &"desktop"
var last_command_result: Dictionary = {}


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
		if screen_state in [SCREEN_DEPLOY, SCREEN_LONG_TERM, SCREEN_SETTINGS]:
			_show_main_menu()
			get_viewport().set_input_as_handled()
			return
		if screen_state == SCREEN_RUN:
			_show_pause_panel()
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
		_dispatch_command(&"flag_current_cell")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_map"):
		_open_map_from_ui(&"keyboard")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_restart_run"):
		_restart_run_from_ui()
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
	ui_root.name = "G9FinalUIRoot"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(ui_root)
	_build_shell_pages()
	_build_run_overlay()
	_build_runtime_modals()


func _build_shell_pages() -> void:
	ui_shell = G9ShellPanelScript.new() as Control
	ui_shell.name = "G9ShellPanel"
	ui_root.add_child(ui_shell)
	ui_shell.call("build")
	ui_shell.connect("main_entry_requested", _on_main_entry_requested)
	ui_shell.connect("deploy_entry_requested", _on_deploy_entry_requested)
	ui_shell.connect("long_term_entry_requested", _on_long_term_entry_requested)
	ui_shell.connect("start_tutorial_requested", _start_tutorial_from_ui)
	ui_shell.connect("start_standard_requested", _start_standard_from_ui)
	ui_shell.connect("dev_diagnostics_requested", _show_dev_diagnostics_panel)
	main_menu_panel = ui_shell.call("get_main_page") as Control
	deploy_shell_panel = ui_shell.call("get_deploy_page") as Control
	long_term_shell_panel = ui_shell.call("get_long_term_page") as Control


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
	minimap_panel.open_map_requested.connect(func() -> void: _open_map_from_ui(&"minimap"))
	run_overlay_root.add_child(minimap_panel)

	hud = HUDScene.instantiate() as Hud
	hud.name = "HUD"
	run_overlay_root.add_child(hud)

	room_badge = _add_label(run_overlay_root, "RoomAreaStatusBadge", Rect2(420, 22, 440, 74), "Room Area", 16)
	room_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_color_rect(run_overlay_root, "RoomBadgeBackdrop", Rect2(410, 18, 460, 82), Color(0.03, 0.06, 0.07, 0.62))
	run_overlay_root.move_child(run_overlay_root.get_node("RoomBadgeBackdrop"), room_badge.get_index())

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
	action_bar.add_theme_constant_override("separation", 6)
	run_overlay_root.add_child(action_bar)
	_add_label(run_overlay_root, "ControlsLabel", Rect2(410, 610, 540, 32), "WASD/方向键：房间内移动；走到门口切换房间。E 搜索/交互。", 14)
	_add_menu_button(action_bar, "E 搜索/交互", func() -> void: _handle_interact_pressed())
	_add_menu_button(action_bar, "背包", func() -> void: _show_inventory_panel())
	_add_menu_button(action_bar, "地面物品", func() -> void: _show_ground_loot_panel())
	_add_menu_button(action_bar, "M 地图", func() -> void: _open_map_from_ui(&"button"))
	_add_menu_button(action_bar, "Space/J 战斗", func() -> void: _fight_and_show_result())

	command_result_label = _add_label(run_overlay_root, "CommandResultReasonLabel", Rect2(982, 156, 238, 64), "操作提示：无", 13)

	layout_profile_label = _add_label(run_overlay_root, "LayoutProfileStatus", Rect2(982, 202, 238, 24), "Layout: desktop", 12)
	debug_toggle_button = _add_button(run_overlay_root, "DebugToggleButton", Rect2(1010, 226, 170, 34), "Dev Debug", func() -> void: _toggle_debug_panel())
	debug_toggle_button.visible = G9ShellPanelScript.DEV_DIAGNOSTICS_ENABLED
	debug_toggle_button.disabled = not G9ShellPanelScript.DEV_DIAGNOSTICS_ENABLED
	debug_toggle_button.tooltip_text = "dev_only=true; hidden outside dev build channel"
	debug_panel = VBoxContainer.new()
	debug_panel.name = "DebugOperationPanel"
	debug_panel.offset_left = 980.0
	debug_panel.offset_top = 270.0
	debug_panel.offset_right = 1220.0
	debug_panel.offset_bottom = 690.0
	debug_panel.visible = false
	run_overlay_root.add_child(debug_panel)
	var debug_title := Label.new()
	debug_title.text = "Debug / Grid Move"
	debug_panel.add_child(debug_title)
	_add_debug_button(debug_panel, "Tutorial", func() -> void: _start_tutorial_from_ui())
	_add_debug_button(debug_panel, "Standard", func() -> void: _start_standard_from_ui())
	_add_debug_button(debug_panel, "GridUp", func() -> void: _dispatch_command(&"move_by", {"delta": Vector2i(0, -1), "source": "debug"}))
	_add_debug_button(debug_panel, "GridDown", func() -> void: _dispatch_command(&"move_by", {"delta": Vector2i(0, 1), "source": "debug"}))
	_add_debug_button(debug_panel, "GridLeft", func() -> void: _dispatch_command(&"move_by", {"delta": Vector2i(-1, 0), "source": "debug"}))
	_add_debug_button(debug_panel, "GridRight", func() -> void: _dispatch_command(&"move_by", {"delta": Vector2i(1, 0), "source": "debug"}))
	_add_debug_button(debug_panel, "Flag", func() -> void: _dispatch_command(&"flag_current_cell", {"source": "debug"}))
	_add_debug_button(debug_panel, "Search", func() -> void: _search_and_show_loot())
	_add_debug_button(debug_panel, "PickupFloor", func() -> void: _pickup_floor_from_ui())
	_add_debug_button(debug_panel, "DropItem", func() -> void: _drop_inventory_from_ui())
	_add_debug_button(debug_panel, "ReqExtract", func() -> void: _request_extract_from_ui())
	_add_debug_button(debug_panel, "ConfirmExt", func() -> void: _dispatch_command(&"confirm_extract", {"source": "debug"}))
	debug_log = Label.new()
	debug_log.name = "DebugLastMessage"
	debug_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_panel.add_child(debug_log)

	inventory_panel = InventoryPanelScript.new() as Control
	inventory_panel.name = "InventoryPanel"
	inventory_panel.connect("drop_item_requested", _on_inventory_drop_requested)
	inventory_panel.connect("close_requested", func() -> void: inventory_panel.call("hide_panel"))
	run_overlay_root.add_child(inventory_panel)

	ground_loot_panel = GroundLootPanelScript.new() as Control
	ground_loot_panel.name = "GroundLootPanel"
	ground_loot_panel.connect("pickup_item_requested", _on_ground_loot_pickup_requested)
	ground_loot_panel.connect("close_requested", func() -> void: ground_loot_panel.call("hide_panel"))
	run_overlay_root.add_child(ground_loot_panel)

	result_panel = ResultPanelScene.instantiate() as ResultPanel
	result_panel.name = "ResultPanel"
	result_panel.return_main_requested.connect(_return_from_result_to_main)
	result_panel.return_deploy_requested.connect(_return_from_result_to_deploy)
	result_panel.hide_result()
	run_overlay_root.add_child(result_panel)

	dev_diagnostics_panel = DevDiagnosticsPanelScript.new() as Control
	dev_diagnostics_panel.name = "DevDiagnosticsPanel"
	dev_diagnostics_panel.connect("close_requested", func() -> void: dev_diagnostics_panel.call("hide_panel"))
	ui_root.add_child(dev_diagnostics_panel)

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
	event_content.add_theme_constant_override("separation", 8)
	event_panel.add_child(event_content)
	event_title_label = Label.new()
	event_title_label.text = "事件"
	event_title_label.add_theme_font_size_override("font_size", 20)
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
	loot_content.add_theme_constant_override("separation", 8)
	loot_panel.add_child(loot_content)
	loot_title_label = Label.new()
	loot_title_label.text = "回收结果"
	loot_title_label.add_theme_font_size_override("font_size", 20)
	loot_content.add_child(loot_title_label)
	loot_body_label = Label.new()
	loot_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	loot_body_label.custom_minimum_size = Vector2(390, 180)
	loot_content.add_child(loot_body_label)
	_add_menu_button(loot_content, "关闭", func() -> void: loot_panel.visible = false)

	extract_panel = _new_modal_panel("ExtractConfirmPanel", Rect2(430, 180, 430, 260))
	var extract_content := VBoxContainer.new()
	extract_content.name = "ExtractConfirmContent"
	extract_content.add_theme_constant_override("separation", 8)
	extract_panel.add_child(extract_content)
	var extract_title := Label.new()
	extract_title.text = "确认撤离"
	extract_title.add_theme_font_size_override("font_size", 20)
	extract_content.add_child(extract_title)
	extract_body_label = Label.new()
	extract_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	extract_body_label.custom_minimum_size = Vector2(390, 120)
	extract_content.add_child(extract_body_label)
	var extract_buttons := HBoxContainer.new()
	extract_content.add_child(extract_buttons)
	_add_menu_button(extract_buttons, "确认", func() -> void: _confirm_extract_from_ui())
	_add_menu_button(extract_buttons, "取消", func() -> void: _cancel_extract_from_ui())

	pause_panel = _new_modal_panel("PauseSettingsOverlayPanel", Rect2(440, 146, 400, 270))
	var pause_content := VBoxContainer.new()
	pause_content.name = "PauseSettingsOverlayContent"
	pause_content.add_theme_constant_override("separation", 8)
	pause_panel.add_child(pause_content)
	var pause_title := Label.new()
	pause_title.text = "暂停 / 设置"
	pause_title.add_theme_font_size_override("font_size", 20)
	pause_content.add_child(pause_title)
	pause_status_label = Label.new()
	pause_status_label.name = "PauseSettingsOverlayStatus"
	pause_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_status_label.text = "本面板只暂停 UI 并提供设置入口；继续会返回当前局，不写本地持久化偏好。"
	pause_content.add_child(pause_status_label)
	_add_menu_button(pause_content, "继续", func() -> void: pause_panel.visible = false)
	_add_menu_button(pause_content, "设置说明", func() -> void: _open_settings_from_pause())
	_add_menu_button(pause_content, "关闭", func() -> void: pause_panel.visible = false)


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
	ui_shell.call("show_main")
	run_overlay_root.visible = false
	_hide_runtime_popups()


func _show_deploy_shell(selected_tab: StringName = &"config") -> void:
	screen_state = SCREEN_DEPLOY
	_set_gameplay_visible(false)
	ui_shell.call("show_deploy", _normalize_deploy_tab(selected_tab))
	run_overlay_root.visible = false
	_hide_runtime_popups()


func _show_long_term_shell(entry_id: StringName = &"tasks") -> void:
	screen_state = SCREEN_LONG_TERM
	_set_gameplay_visible(false)
	ui_shell.call("show_long_term", entry_id)
	run_overlay_root.visible = false
	_hide_runtime_popups()


func _show_settings_shell() -> void:
	screen_state = SCREEN_SETTINGS
	_set_gameplay_visible(false)
	ui_shell.call("show_settings")
	run_overlay_root.visible = false
	_hide_runtime_popups()


func _show_run_screen() -> void:
	screen_state = SCREEN_RUN
	_set_gameplay_visible(true)
	ui_shell.visible = false
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
	if ui_shell != null:
		ui_shell.visible = not visible


func _show_pause_panel() -> void:
	if pause_panel == null:
		return
	if pause_status_label != null and run_context != null:
		var snapshot: Dictionary = run_context.get_status_snapshot()
		pause_status_label.text = "暂停中。当前阶段=%s，房间=%s。点击继续返回当前局；设置入口不保存偏好。" % [
			snapshot.get("phase", ""),
			snapshot.get("current_room", ""),
		]
	pause_panel.visible = true


func _open_settings_from_pause() -> void:
	if pause_status_label != null:
		pause_status_label.text = "设置说明：后续可接入音量、可访问性和 UI 减法；本阶段不写本地持久化偏好。"


func _return_from_result_to_main() -> void:
	if result_panel != null:
		result_panel.hide_result()
	_show_main_menu()


func _return_from_result_to_deploy() -> void:
	if result_panel != null:
		result_panel.hide_result()
	_show_deploy_shell(&"config")


func _normalize_deploy_tab(tab_id: StringName) -> StringName:
	match tab_id:
		&"loadout":
			return &"config"
		&"settings":
			return &"settings"
		_:
			return tab_id


func _on_main_entry_requested(entry_id: StringName) -> void:
	match entry_id:
		&"deploy", &"deploy_config":
			_show_deploy_shell(&"config")
		&"long_term":
			_show_long_term_shell()
		&"settings":
			_show_settings_shell()
		_:
			_show_main_menu()


func _on_deploy_entry_requested(entry_id: StringName) -> void:
	match entry_id:
		&"back_main":
			_show_main_menu()
		&"long_term":
			_show_long_term_shell()


func _on_long_term_entry_requested(entry_id: StringName) -> void:
	match entry_id:
		&"back_main":
			_show_main_menu()
		&"deploy":
			_show_deploy_shell()
		_:
			_show_long_term_shell(entry_id)


func _handle_interact_pressed() -> void:
	if command_bus == null or run_context == null or _is_runtime_modal_open():
		return
	var snapshot := run_context.get_status_snapshot()
	var current_room: StringName = StringName(snapshot.get("current_room", &"Unknown"))
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
	var result := _dispatch_command(&"interact_current_room")
	_show_command_feedback(result)


func _search_and_show_loot() -> void:
	var result := _dispatch_command(&"search_current_room")
	var snapshot := run_context.get_status_snapshot()
	var reward: Dictionary = snapshot.get("last_reward", {})
	if not reward.is_empty():
		_show_loot_panel("回收结果", reward)
	else:
		_show_command_feedback(result)


func _fight_and_show_result() -> void:
	var result := _dispatch_command(&"fight_current_enemy")
	var snapshot := run_context.get_status_snapshot()
	var reward: Dictionary = snapshot.get("last_reward", {})
	if not reward.is_empty():
		_show_loot_panel("战斗结果", reward)
	else:
		_show_command_feedback(result)


func _pickup_floor_from_ui(instance_id: String = "") -> void:
	var payload: Dictionary = {"source": "ui"}
	if instance_id != "":
		payload["instance_id"] = instance_id
	var result := _dispatch_command(&"pickup_ground_item", payload)
	if ground_loot_panel != null:
		ground_loot_panel.call("show_command_result", result)
	if inventory_panel != null:
		inventory_panel.call("show_command_result", result)
	_refresh_view_models()


func _drop_inventory_from_ui(instance_id: String = "") -> void:
	var payload: Dictionary = {"source": "ui"}
	if instance_id != "":
		payload["instance_id"] = instance_id
	var result := _dispatch_command(&"drop_inventory_item", payload)
	if inventory_panel != null:
		inventory_panel.call("show_command_result", result)
	if ground_loot_panel != null:
		ground_loot_panel.call("show_command_result", result)
	_refresh_view_models()


func _show_inventory_panel() -> void:
	if inventory_panel == null:
		return
	inventory_panel.call("apply_snapshot", run_context.get_status_snapshot())
	inventory_panel.call("show_panel")
	if ground_loot_panel != null:
		ground_loot_panel.call("hide_panel")


func _show_ground_loot_panel() -> void:
	if ground_loot_panel == null:
		return
	ground_loot_panel.call("apply_snapshot", run_context.get_status_snapshot())
	ground_loot_panel.call("show_panel")
	if inventory_panel != null:
		inventory_panel.call("hide_panel")


func _on_inventory_drop_requested(instance_id: String) -> void:
	_drop_inventory_from_ui(instance_id)


func _on_ground_loot_pickup_requested(instance_id: String) -> void:
	_pickup_floor_from_ui(instance_id)


func _show_event_panel(event_state: Dictionary) -> void:
	if event_panel == null:
		return
	event_title_label.text = "事件：%s" % _event_type_label(StringName(event_state.get("event_type", &"event")))
	event_body_label.text = "选择处理方式。事件完成后不会重复结算奖励。"
	for child in event_options_box.get_children():
		child.queue_free()
	var options: Array = event_state.get("options", [])
	for option: Dictionary in options:
		var option_id: StringName = StringName(option.get("id", &"leave"))
		var option_label: String = String(option.get("label", String(option_id)))
		var button := _add_menu_button(event_options_box, option_label, func() -> void: _select_event_option(option_id))
		button.disabled = not bool(option.get("enabled", true))
	event_panel.visible = true


func _select_event_option(option_id: StringName) -> void:
	event_panel.visible = false
	var result := _dispatch_command(&"select_event_option", {"option_id": option_id, "source": "ui"})
	var snapshot := run_context.get_status_snapshot()
	var reward: Dictionary = snapshot.get("last_reward", {})
	if not reward.is_empty():
		_show_loot_panel("事件结果", reward)
	else:
		_show_command_feedback(result)


func _request_extract_from_ui() -> void:
	var result := _dispatch_command(&"request_extract")
	if bool(result.get("ok", false)):
		_show_extract_panel(run_context.get_status_snapshot())
	else:
		_show_command_feedback(result)


func _show_extract_panel(snapshot: Dictionary) -> void:
	if StringName(snapshot.get("phase", &"running")) != &"confirm_extract":
		return
	extract_body_label.text = "待结算黑币：%s\n安全金币：%s\n背包：%s/%s\n当前房间地面遗留：%s\n\n确认从该出口撤离？" % [
		snapshot.get("black_coin", snapshot.get("pending_gold", 0)),
		snapshot.get("gold_coin", snapshot.get("safe_gold", 0)),
		snapshot.get("backpack_used", 0),
		snapshot.get("backpack_capacity", 0),
		snapshot.get("room_floor_item_count", 0),
	]
	extract_panel.visible = true


func _confirm_extract_from_ui() -> void:
	extract_panel.visible = false
	_dispatch_command(&"confirm_extract")


func _cancel_extract_from_ui() -> void:
	extract_panel.visible = false
	_dispatch_command(&"cancel_extract")


func _show_loot_panel(title: String, reward: Dictionary) -> void:
	if loot_panel == null:
		return
	loot_title_label.text = title
	loot_body_label.text = RunUIViewModel.reward_text(reward, String(run_context.last_message))
	loot_panel.visible = true
	_refresh_view_models()


func _restart_run_from_ui() -> void:
	_dispatch_command(&"restart_run")
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
	return (
		(event_panel != null and event_panel.visible)
		or (loot_panel != null and loot_panel.visible)
		or (extract_panel != null and extract_panel.visible)
		or (inventory_panel != null and inventory_panel.visible)
		or (ground_loot_panel != null and ground_loot_panel.visible)
		or (result_panel != null and result_panel.visible)
		or (pause_panel != null and pause_panel.visible)
		or (dev_diagnostics_panel != null and dev_diagnostics_panel.visible)
	)


func _close_top_runtime_modal() -> bool:
	if inventory_panel != null and inventory_panel.visible:
		inventory_panel.call("hide_panel")
		return true
	if ground_loot_panel != null and ground_loot_panel.visible:
		ground_loot_panel.call("hide_panel")
		return true
	if event_panel != null and event_panel.visible:
		event_panel.visible = false
		return true
	if loot_panel != null and loot_panel.visible:
		loot_panel.visible = false
		return true
	if extract_panel != null and extract_panel.visible:
		_cancel_extract_from_ui()
		return true
	if pause_panel != null and pause_panel.visible:
		pause_panel.visible = false
		return true
	if dev_diagnostics_panel != null and dev_diagnostics_panel.visible:
		dev_diagnostics_panel.call("hide_panel")
		return true
	return false


func _hide_runtime_popups() -> void:
	if event_panel != null:
		event_panel.visible = false
	if loot_panel != null:
		loot_panel.visible = false
	if extract_panel != null:
		extract_panel.visible = false
	if inventory_panel != null:
		inventory_panel.call("hide_panel")
	if ground_loot_panel != null:
		ground_loot_panel.call("hide_panel")
	if result_panel != null:
		result_panel.hide_result()
	if pause_panel != null:
		pause_panel.visible = false
	if dev_diagnostics_panel != null:
		dev_diagnostics_panel.call("hide_panel")
	if map_overlay_panel != null:
		map_overlay_panel.hide_overlay()


func _on_state_changed(_snapshot: Dictionary) -> void:
	_refresh_view_models()


func _on_result_available(snapshot: Dictionary) -> void:
	_refresh_view_models()
	_hide_runtime_popups()
	if result_panel != null:
		result_panel.show_summary(snapshot)


func _refresh_view_models() -> void:
	if run_context == null:
		return
	var snapshot := run_context.get_status_snapshot()
	var layout_profile: Dictionary = _current_layout_profile()
	var pos: Vector2i = snapshot.get("position", Vector2i.ZERO)
	var minimap_vm := MiniMapViewModel.build_from_intel(run_context.intel_map, run_context.get_current_pos())
	if ui_shell != null:
		ui_shell.call("apply_snapshot", snapshot)
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
		protocol_badge.text = "协议 %s\n压力：%s / 100\n状态：%s\n地面物品：%s" % [
			snapshot.get("protocol_level", 5),
			snapshot.get("pressure", 0),
			snapshot.get("outcome", "Running"),
			snapshot.get("room_floor_item_count", 0),
		]
	if room_controller != null:
		room_controller.configure(PresentationMapping.room_visual_from_snapshot(snapshot))
	if player_controller != null:
		player_controller.set_visual_asset(&"sprite.player.default")
	if hud != null:
		hud.apply_layout_profile(layout_profile)
		hud.apply_view_model(HUDViewModel.build_from_snapshot(snapshot))
	if minimap_panel != null:
		minimap_panel.apply_layout_profile(layout_profile)
		minimap_panel.apply_view_model(minimap_vm)
	if map_overlay_panel != null:
		map_overlay_panel.apply_layout_profile(layout_profile)
		map_overlay_panel.apply_view_model(minimap_vm)
	if layout_profile_label != null:
		layout_profile_label.text = "Layout: %s" % current_layout_profile_id
	if tutorial_popup_panel != null:
		tutorial_popup_panel.apply_popup(snapshot.get("tutorial_popup", {}))
	if inventory_panel != null:
		inventory_panel.call("apply_layout_profile", layout_profile)
		inventory_panel.call("apply_snapshot", snapshot)
	if ground_loot_panel != null:
		ground_loot_panel.call("apply_layout_profile", layout_profile)
		ground_loot_panel.call("apply_snapshot", snapshot)
	if result_panel != null:
		result_panel.apply_layout_profile(layout_profile)
	if dev_diagnostics_panel != null and dev_diagnostics_panel.visible:
		_apply_dev_diagnostics(snapshot)
	if debug_log != null:
		debug_log.text = String(snapshot.get("last_message", ""))
	if result_panel != null and bool(snapshot.get("run_active", false)):
		result_panel.hide_result()


func _current_layout_profile() -> Dictionary:
	var viewport_size: Vector2 = get_viewport_rect().size
	if SettingsManager != null:
		var resolution_size: Vector2i = SettingsManager.get_current_resolution_size()
		if resolution_size.x > 0 and resolution_size.y > 0:
			viewport_size = Vector2(resolution_size.x, resolution_size.y)
	var profile: Dictionary = UILayoutProfileScript.profile_for_size(viewport_size)
	current_layout_profile_id = StringName(profile.get("profile_id", &"desktop"))
	return profile


func _show_dev_diagnostics_panel() -> void:
	var policy: Dictionary = DevDiagnosticsPanelScript.DEV_ONLY_POLICY
	var enabled: bool = G9ShellPanelScript.DEV_DIAGNOSTICS_ENABLED and bool(policy.get("dev_only", false)) and StringName(policy.get("unlock_condition", &"")) == &"dev_channel"
	if not enabled:
		_show_command_feedback({
			"ok": false,
			"accepted": false,
			"reason_code": &"dev_diagnostics_hidden",
			"message_key": &"ui.dev_diagnostics.hidden",
			"command_id": &"open_dev_diagnostics",
		})
		return
	if dev_diagnostics_panel == null:
		return
	var snapshot: Dictionary = {}
	if run_context != null:
		snapshot = run_context.get_status_snapshot()
	_apply_dev_diagnostics(snapshot)
	dev_diagnostics_panel.call("show_panel")


func _apply_dev_diagnostics(snapshot: Dictionary) -> void:
	if dev_diagnostics_panel == null:
		return
	var ui_state: Dictionary = {
		"page": screen_state,
		"panel": "DevDiagnosticsPanel",
		"layout_profile": current_layout_profile_id,
	}
	var art_report: Dictionary = G10ArtSmokeRegistry.build_smoke_report()
	dev_diagnostics_panel.call("apply_diagnostics", snapshot, last_command_result, ui_state, art_report)


func _dispatch_command(command_name: StringName, payload: Dictionary = {}) -> Dictionary:
	if command_bus == null:
		return {}
	var result: Dictionary = command_bus.dispatch(command_name, payload)
	last_command_result = result.duplicate(true)
	_show_command_feedback(result)
	return result


func _show_command_feedback(result: Dictionary) -> void:
	if command_result_label != null:
		command_result_label.text = "操作提示：%s" % RunUIViewModel.command_result_text(result)
		var accepted: bool = bool(result.get("accepted", result.get("ok", true)))
		if not accepted:
			_flash_blocked_reason()
	if inventory_panel != null and inventory_panel.visible:
		inventory_panel.call("show_command_result", result)
	if ground_loot_panel != null and ground_loot_panel.visible:
		ground_loot_panel.call("show_command_result", result)

func _flash_blocked_reason() -> void:
	if command_result_label == null:
		return
	command_result_label.name = "BlockedReasonFlash"
	var tween: Tween = create_tween()
	tween.tween_property(command_result_label, "modulate", Color(1.0, 0.55, 0.35, 1.0), 0.06)
	tween.tween_property(command_result_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)


func _open_map_from_ui(source: StringName = &"button") -> void:
	_dispatch_command(&"open_map")
	if map_overlay_panel != null:
		map_overlay_panel.toggle_overlay()
		if map_overlay_panel.visible:
			map_overlay_panel.show_open_feedback(source)


func _toggle_debug_panel() -> void:
	if not G9ShellPanelScript.DEV_DIAGNOSTICS_ENABLED:
		return
	if debug_panel != null:
		debug_panel.visible = not debug_panel.visible


func _on_tutorial_popup_confirmed() -> void:
	_dispatch_command(&"confirm_tutorial_popup")


func _start_tutorial_from_ui() -> void:
	var result: Dictionary = command_bus.dispatch(&"start_tutorial_run")
	last_command_result = result.duplicate(true)
	_show_command_feedback(result)
	if player_controller != null:
		player_controller.reset_local_position()
	_show_run_screen()


func _start_standard_from_ui() -> void:
	var result: Dictionary = command_bus.dispatch(&"start_standard_run")
	last_command_result = result.duplicate(true)
	_show_command_feedback(result)
	if player_controller != null:
		player_controller.reset_local_position()
	_show_run_screen()


func _attempt_room_transition(direction: Vector2i) -> void:
	var before := run_context.get_current_pos()
	var result: Dictionary = command_bus.dispatch(&"attempt_room_transition", {"direction": direction})
	last_command_result = result.duplicate(true)
	_show_command_feedback(result)
	var moved: bool = bool(result.get("ok", false)) and run_context.get_current_pos() != before
	if moved:
		player_controller.place_from_entry(direction)
	else:
		player_controller.block_transition(direction)


func _on_map_overlay_cell_action_requested(marker: Dictionary) -> void:
	if command_bus == null or run_context == null:
		return
	var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
	var state: StringName = StringName(marker.get("state", &"hidden"))
	if state == &"hidden" or state == &"flagged":
		var flag_result: Dictionary = _dispatch_command(&"toggle_flag_cell", {"pos": pos})
		if map_overlay_panel != null:
			map_overlay_panel.show_action_feedback(marker, flag_result)
		return
	if bool(marker.get("explored", false)) and not bool(marker.get("mine", false)):
		var result: Dictionary = _dispatch_command(&"teleport_to_explored", {"pos": pos})
		if map_overlay_panel != null:
			map_overlay_panel.show_action_feedback(marker, result)
		if bool(result.get("ok", false)):
			if player_controller != null:
				player_controller.reset_local_position()
			if map_overlay_panel != null:
				map_overlay_panel.hide_overlay()


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
	button.custom_minimum_size = Vector2(110, 34)
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
