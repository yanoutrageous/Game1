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
const AppShellScript := preload("res://scripts/ui/app_shell/app_shell.gd")
const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory/inventory_panel.gd")
const GroundLootPanelScript := preload("res://scripts/ui/ground_loot/ground_loot_panel.gd")
const DevDiagnosticsPanelScript := preload("res://scripts/ui/dev/dev_diagnostics_panel.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")
const G10ArtSmokeRegistry := preload("res://scripts/presentation/g10_art_smoke_registry.gd")
const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const RunSurfaceScript := preload("res://scripts/ui/run_surface/run_surface.gd")
const RunSurfaceModel := preload("res://scripts/ui/run_surface/run_surface_model.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")

const SCREEN_MAIN_MENU := &"main_menu"
const SCREEN_DEPLOY := &"deploy_shell"
const SCREEN_LONG_TERM := &"long_term_shell"
const SCREEN_SETTINGS := &"settings_shell"
const SCREEN_RUN := &"run"
const M1_DEBUG_PANEL_ENABLED := true

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
var meta_progress_adapter: MetaProgressAdapter
var ui_root: Control
var ui_shell: Control
var main_menu_panel: Control
var deploy_shell_panel: Control
var long_term_shell_panel: Control
var run_overlay_root: Control
var run_surface
var room_badge: Label
var protocol_badge: Label
var command_result_label: Label
var debug_panel: PanelContainer
var debug_content: VBoxContainer
var debug_scroll: ScrollContainer
var debug_x_spin: SpinBox
var debug_y_spin: SpinBox
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
	meta_progress_adapter = MetaProgressAdapterScript.new()
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


func _input(event: InputEvent) -> void:
	if _handle_cancel_input(event):
		get_viewport().set_input_as_handled()
		return
	if _handle_run_action_input(event):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _handle_cancel_input(event):
		get_viewport().set_input_as_handled()
		return


func _handle_cancel_input(event: InputEvent) -> bool:
	if not (event.is_action_pressed("cancel") or _event_matches_key(event, [KEY_ESCAPE])):
		return false
	if _close_top_runtime_modal():
		return true
	if screen_state in [SCREEN_DEPLOY, SCREEN_LONG_TERM, SCREEN_SETTINGS]:
		_show_main_menu()
		return true
	if screen_state == SCREEN_RUN:
		_show_pause_panel()
		return true
	return false


func _handle_run_action_input(event: InputEvent) -> bool:
	if screen_state != SCREEN_RUN or run_context == null:
		return false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.echo:
			return false
	if run_context.has_blocking_tutorial_popup():
		return false
	if _is_runtime_modal_open():
		return false
	if map_overlay_panel != null and map_overlay_panel.visible:
		return false

	if event.is_action_pressed("interact") or _event_matches_key(event, [KEY_E]):
		_handle_interact_pressed()
		return true
	elif event.is_action_pressed("attack") or _event_matches_key(event, [KEY_SPACE, KEY_J]):
		_fight_and_show_result()
		return true
	elif event.is_action_pressed("flag_cell") or _event_matches_key(event, [KEY_F]):
		_dispatch_command(&"flag_current_cell")
		return true
	elif event.is_action_pressed("open_map") or _event_matches_key(event, [KEY_M, KEY_TAB]):
		_open_map_from_ui(&"keyboard")
		return true
	elif event.is_action_pressed("debug_restart_run"):
		_restart_run_from_ui()
		return true
	return false


func _event_matches_key(event: InputEvent, keycodes: Array) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	for keycode: int in keycodes:
		if key_event.physical_keycode == keycode or key_event.keycode == keycode:
			return true
	return false


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
	ui_shell = AppShellScript.new() as Control
	ui_shell.name = "AppShell"
	ui_root.add_child(ui_shell)
	ui_shell.call("build")
	ui_shell.connect("host_route_requested", _on_app_shell_host_route_requested)
	main_menu_panel = ui_shell.call("get_main_page") as Control
	deploy_shell_panel = ui_shell.call("get_deploy_page") as Control
	long_term_shell_panel = ui_shell.call("get_long_term_page") as Control


func _build_run_overlay() -> void:
	run_overlay_root = Control.new()
	run_overlay_root.name = "RunOverlayRoot"
	run_overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(run_overlay_root)

	run_surface = RunSurfaceScript.new()
	run_surface.name = "RunSurface"
	run_surface.build()
	run_surface.interact_requested.connect(_handle_interact_pressed)
	run_surface.inventory_requested.connect(_show_inventory_panel)
	run_surface.ground_loot_requested.connect(_show_ground_loot_panel)
	run_surface.map_requested.connect(_open_map_from_ui)
	run_surface.combat_requested.connect(_fight_and_show_result)
	run_surface.extract_requested.connect(_request_extract_from_ui)
	run_surface.pause_requested.connect(_show_pause_panel)
	run_surface.encounter_option_selected.connect(_on_encounter_option_selected)
	run_overlay_root.add_child(run_surface)

	hud = run_surface.get_hud()
	minimap_panel = run_surface.get_minimap_panel()
	var surface_overlay_slot: Control = run_surface.get_overlay_slot()

	debug_toggle_button = _add_button(run_overlay_root, "DebugToggleButton", Rect2(1010, 226, 170, 34), "Dev Debug", func() -> void: _toggle_debug_panel())
	debug_toggle_button.visible = M1_DEBUG_PANEL_ENABLED
	debug_toggle_button.disabled = not M1_DEBUG_PANEL_ENABLED
	debug_toggle_button.tooltip_text = "m1_debug_panel=true; dev/test-only cheat panel"
	debug_panel = PanelContainer.new()
	debug_panel.name = "DebugOperationPanel"
	debug_panel.offset_left = 980.0
	debug_panel.offset_top = 270.0
	debug_panel.offset_right = 1220.0
	debug_panel.offset_bottom = 690.0
	debug_panel.visible = false
	run_overlay_root.add_child(debug_panel)
	var debug_outer := VBoxContainer.new()
	debug_outer.name = "DebugOperationContent"
	debug_outer.add_theme_constant_override("separation", 8)
	debug_panel.add_child(debug_outer)
	var debug_header := HBoxContainer.new()
	debug_header.name = "DebugOperationHeader"
	debug_outer.add_child(debug_header)
	var debug_title := Label.new()
	debug_title.text = "M1 Debug Cheats"
	debug_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_header.add_child(debug_title)
	_add_debug_button(debug_header, "Close", func() -> void: _close_debug_panel())
	var debug_note := Label.new()
	debug_note.text = "dev_only=true | commands go through CommandBus / MetaProgressAdapter"
	debug_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_outer.add_child(debug_note)
	var coord_row := HBoxContainer.new()
	coord_row.name = "DebugCoordinateRow"
	coord_row.add_theme_constant_override("separation", 6)
	debug_outer.add_child(coord_row)
	var coord_label := Label.new()
	coord_label.text = "XY"
	coord_row.add_child(coord_label)
	debug_x_spin = SpinBox.new()
	debug_x_spin.name = "DebugTeleportX"
	debug_x_spin.min_value = 0
	debug_x_spin.max_value = 99
	debug_x_spin.step = 1
	debug_x_spin.custom_minimum_size = Vector2(70, 28)
	coord_row.add_child(debug_x_spin)
	debug_y_spin = SpinBox.new()
	debug_y_spin.name = "DebugTeleportY"
	debug_y_spin.min_value = 0
	debug_y_spin.max_value = 99
	debug_y_spin.step = 1
	debug_y_spin.custom_minimum_size = Vector2(70, 28)
	coord_row.add_child(debug_y_spin)
	debug_scroll = ScrollContainer.new()
	debug_scroll.name = "DebugOperationScroll"
	debug_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	debug_scroll.custom_minimum_size = Vector2(260, 360)
	debug_outer.add_child(debug_scroll)
	debug_content = VBoxContainer.new()
	debug_content.name = "DebugOperationButtons"
	debug_content.add_theme_constant_override("separation", 6)
	debug_scroll.add_child(debug_content)
	_add_debug_section(debug_content, "Run Debug")
	_add_debug_button(debug_content, "Tutorial Run", func() -> void: _start_tutorial_from_ui())
	_add_debug_button(debug_content, "Standard Run", func() -> void: _start_standard_from_ui())
	_add_debug_button(debug_content, "Teleport Exit", func() -> void: _debug_teleport_to_exit())
	_add_debug_button(debug_content, "Move XY no trigger", func() -> void: _debug_teleport_xy(false))
	_add_debug_button(debug_content, "Enter XY trigger", func() -> void: _debug_teleport_xy(true))
	_add_debug_button(debug_content, "+100 Run Black Coin", func() -> void: _dispatch_command(&"debug_add_run_black_coin", {"amount": 100, "source": "debug"}))
	_add_debug_button(debug_content, "Reveal Full Map", func() -> void: _dispatch_command(&"debug_reveal_full_map", {"source": "debug"}))
	_add_debug_button(debug_content, "Spawn Floor Item", func() -> void: _dispatch_command(&"debug_spawn_test_item_floor", {"source": "debug"}))
	_add_debug_button(debug_content, "Spawn Backpack Item", func() -> void: _dispatch_command(&"debug_spawn_test_item_backpack", {"source": "debug"}))
	_add_debug_button(debug_content, "Full HP", func() -> void: _dispatch_command(&"debug_heal_full", {"source": "debug"}))
	_add_debug_button(debug_content, "Force Extract Success", func() -> void: _dispatch_command(&"debug_force_extract", {"source": "debug"}))
	_add_debug_button(debug_content, "Force Fail", func() -> void: _dispatch_command(&"debug_force_fail", {"reason": "debug_forced_failure", "source": "debug"}))
	_add_debug_section(debug_content, "Run Utility")
	_add_debug_button(debug_content, "Grid Up", func() -> void: _dispatch_command(&"move_by", {"delta": Vector2i(0, -1), "source": "debug"}))
	_add_debug_button(debug_content, "Grid Down", func() -> void: _dispatch_command(&"move_by", {"delta": Vector2i(0, 1), "source": "debug"}))
	_add_debug_button(debug_content, "Grid Left", func() -> void: _dispatch_command(&"move_by", {"delta": Vector2i(-1, 0), "source": "debug"}))
	_add_debug_button(debug_content, "Grid Right", func() -> void: _dispatch_command(&"move_by", {"delta": Vector2i(1, 0), "source": "debug"}))
	_add_debug_button(debug_content, "Flag Current", func() -> void: _dispatch_command(&"flag_current_cell", {"source": "debug"}))
	_add_debug_button(debug_content, "Search Current", func() -> void: _debug_search_and_show_loot())
	_add_debug_button(debug_content, "Pickup Floor", func() -> void: _pickup_floor_from_ui())
	_add_debug_button(debug_content, "Drop Item", func() -> void: _drop_inventory_from_ui())
	_add_debug_button(debug_content, "Request Extract", func() -> void: _request_extract_from_ui())
	_add_debug_button(debug_content, "Confirm Extract", func() -> void: _dispatch_command(&"confirm_extract", {"source": "debug"}))
	_add_debug_section(debug_content, "Meta Debug")
	_add_debug_button(debug_content, "+1000 Meta Gold", func() -> void: _debug_meta_add_gold())
	_add_debug_button(debug_content, "Set Meta Gold 0", func() -> void: _debug_meta_set_gold(0))
	_add_debug_button(debug_content, "Clear Meta Gold", func() -> void: _debug_meta_clear_gold())
	_add_debug_button(debug_content, "Add Warehouse Test Item", func() -> void: _debug_meta_add_warehouse_item())
	_add_debug_button(debug_content, "Clear Warehouse", func() -> void: _debug_meta_clear_warehouse())
	_add_debug_button(debug_content, "Save Meta Now", func() -> void: _debug_meta_save())
	_add_debug_button(debug_content, "Clear Save", func() -> void: _debug_meta_clear_save())
	_add_debug_button(debug_content, "Read Save Summary", func() -> void: _debug_meta_summary())
	debug_log = Label.new()
	debug_log.name = "DebugLastMessage"
	debug_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_outer.add_child(debug_log)

	inventory_panel = InventoryPanelScript.new() as Control
	inventory_panel.name = "InventoryPanel"
	inventory_panel.connect("drop_item_requested", _on_inventory_drop_requested)
	inventory_panel.connect("close_requested", func() -> void: inventory_panel.call("hide_panel"))
	surface_overlay_slot.add_child(inventory_panel)

	ground_loot_panel = GroundLootPanelScript.new() as Control
	ground_loot_panel.name = "GroundLootPanel"
	ground_loot_panel.connect("pickup_item_requested", _on_ground_loot_pickup_requested)
	ground_loot_panel.connect("close_requested", func() -> void: ground_loot_panel.call("hide_panel"))
	surface_overlay_slot.add_child(ground_loot_panel)

	result_panel = ResultPanelScene.instantiate() as ResultPanel
	result_panel.name = "ResultPanel"
	result_panel.return_main_requested.connect(_return_from_result_to_main)
	result_panel.return_deploy_requested.connect(_return_from_result_to_deploy)
	result_panel.hide_result()
	surface_overlay_slot.add_child(result_panel)

	dev_diagnostics_panel = DevDiagnosticsPanelScript.new() as Control
	dev_diagnostics_panel.name = "DevDiagnosticsPanel"
	dev_diagnostics_panel.connect("close_requested", func() -> void: dev_diagnostics_panel.call("hide_panel"))
	ui_root.add_child(dev_diagnostics_panel)

	map_overlay_panel = MapOverlayScene.instantiate() as MapOverlayPanel
	map_overlay_panel.name = "MapOverlayPanel"
	map_overlay_panel.cell_action_requested.connect(_on_map_overlay_cell_action_requested)
	surface_overlay_slot.add_child(map_overlay_panel)

	tutorial_popup_panel = TutorialPopupScene.instantiate() as TutorialPopupPanel
	tutorial_popup_panel.name = "TutorialPopupPanel"
	tutorial_popup_panel.confirmed.connect(_on_tutorial_popup_confirmed)
	surface_overlay_slot.add_child(tutorial_popup_panel)


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
	event_body_label.custom_minimum_size = Vector2(250, 78)
	event_content.add_child(event_body_label)
	event_options_box = VBoxContainer.new()
	event_options_box.name = "EventOptionButtons"
	event_content.add_child(event_options_box)
	_add_menu_button(event_content, "关闭", func() -> void: event_panel.visible = false)

	if run_surface != null:
		run_surface.apply_legacy_modal_style(event_panel, &"mini.event")

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
	loot_body_label.custom_minimum_size = Vector2(250, 160)
	loot_content.add_child(loot_body_label)
	_add_menu_button(loot_content, "关闭", func() -> void: loot_panel.visible = false)

	if run_surface != null:
		run_surface.apply_legacy_modal_style(loot_panel, &"mini.chest")

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
	extract_body_label.custom_minimum_size = Vector2(250, 120)
	extract_content.add_child(extract_body_label)
	var extract_buttons := HBoxContainer.new()
	extract_content.add_child(extract_buttons)
	_add_menu_button(extract_buttons, "确认", func() -> void: _confirm_extract_from_ui())
	_add_menu_button(extract_buttons, "取消", func() -> void: _cancel_extract_from_ui())

	if run_surface != null:
		run_surface.apply_legacy_modal_style(extract_panel, &"mini.exit")

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
	if M1_DEBUG_PANEL_ENABLED:
		_add_menu_button(pause_content, "Dev Debug Panel", func() -> void: _open_debug_panel_from_pause())
	_add_menu_button(pause_content, "继续", func() -> void: pause_panel.visible = false)
	_add_menu_button(pause_content, "设置说明", func() -> void: _open_settings_from_pause())
	_add_menu_button(pause_content, "关闭", func() -> void: pause_panel.visible = false)
	_apply_runtime_modal_layout(_current_layout_profile())


func _new_modal_panel(node_name: String, rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.offset_left = rect.position.x
	panel.offset_top = rect.position.y
	panel.offset_right = rect.position.x + rect.size.x
	panel.offset_bottom = rect.position.y + rect.size.y
	panel.visible = false
	var modal_parent: Control = run_overlay_root
	if run_surface != null:
		modal_parent = run_surface.get_modal_slot()
	modal_parent.add_child(panel)
	return panel


func _apply_runtime_modal_layout(profile: Dictionary) -> void:
	var supported_size: Vector2 = profile.get("supported_size", Vector2(1366, 768))
	var actual_size: Vector2i = profile.get("actual_viewport_size", Vector2i(int(supported_size.x), int(supported_size.y)))
	var width: float = float(max(1, actual_size.x))
	var height: float = float(max(1, actual_size.y))
	var margin: float = 24.0
	var left_width: float = clamp(width * 0.29, 360.0, 420.0)
	var right_width: float = clamp(width * 0.20, 268.0, 330.0)
	var modal_width: float = min(max(300.0, right_width - 16.0), max(260.0, width - left_width - margin * 3.0))
	var modal_left: float = width - modal_width - margin
	var modal_top: float = margin + 80.0
	var available_height: float = max(220.0, height - modal_top - margin)
	_set_control_rect(event_panel, Rect2(modal_left, modal_top, modal_width, min(360.0, available_height)))
	_set_control_rect(loot_panel, Rect2(modal_left, modal_top, modal_width, min(300.0, available_height)))
	_set_control_rect(extract_panel, Rect2(modal_left, modal_top, modal_width, min(260.0, available_height)))
	_set_control_rect(pause_panel, Rect2(modal_left, modal_top, modal_width, min(270.0, available_height)))
	_apply_debug_panel_layout(profile)


func _apply_debug_panel_layout(profile: Dictionary) -> void:
	if debug_panel == null:
		return
	var supported_size: Vector2 = profile.get("supported_size", Vector2(1366, 768))
	var actual_size: Vector2i = profile.get("actual_viewport_size", Vector2i(int(supported_size.x), int(supported_size.y)))
	var width: float = float(max(1, actual_size.x))
	var height: float = float(max(1, actual_size.y))
	var margin: float = 24.0
	var panel_width: float = clamp(width * 0.24, 300.0, 380.0)
	var top: float = margin + 70.0
	var panel_height: float = max(380.0, height - top - margin)
	_set_control_rect(debug_panel, Rect2(width - panel_width - margin, top, panel_width, panel_height))
	if debug_scroll != null:
		debug_scroll.custom_minimum_size = Vector2(panel_width - 32.0, max(240.0, panel_height - 170.0))


func _shell_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	if run_context != null:
		snapshot = run_context.get_status_snapshot()
	snapshot["meta_progress_summary"] = _meta_progress_summary()
	return snapshot


func _meta_progress_summary() -> Dictionary:
	if meta_progress_adapter == null:
		return {}
	return meta_progress_adapter.get_summary()


func _commit_result_to_meta(result_snapshot: Dictionary) -> Dictionary:
	if meta_progress_adapter == null:
		return {"ok": false, "reason": "meta_progress_adapter_missing"}
	return meta_progress_adapter.apply_settlement(result_snapshot)


func _show_main_menu() -> void:
	screen_state = SCREEN_MAIN_MENU
	_set_gameplay_visible(false)
	ui_shell.call("show_main")
	ui_shell.call("apply_snapshot", _shell_snapshot())
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
	get_viewport().gui_release_focus()
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
	_apply_runtime_modal_layout(_current_layout_profile())
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


func _on_app_shell_host_route_requested(intent: Dictionary) -> void:
	var target := NavigationIntentScript.target(intent)
	match target:
		NavigationIntentScript.TARGET_RUN:
			_start_run_from_route(intent)
		_:
			_show_main_menu()


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
	event_body_label.text = RunSurfaceModel.event_modal_text(event_state)
	for child in event_options_box.get_children():
		child.queue_free()
	var options: Array = event_state.get("options", [])
	for option: Dictionary in options:
		var option_id: StringName = StringName(option.get("id", &"leave"))
		var option_label: String = String(option.get("label", String(option_id)))
		var button := _add_menu_button(event_options_box, option_label, func() -> void: _select_event_option(option_id))
		button.disabled = not bool(option.get("enabled", true))
		button.tooltip_text = "事件选项：仍通过既有 select_event_option 命令处理。"
		if run_surface != null:
			run_surface.apply_legacy_button_style(button, &"primary" if not button.disabled else &"secondary")
	_apply_runtime_modal_layout(_current_layout_profile())
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


func _on_encounter_option_selected(_option_id: StringName, command_payload: Dictionary) -> void:
	var payload := command_payload.duplicate(true)
	if not payload.has("option_id"):
		_show_command_feedback({
			"ok": false,
			"accepted": false,
			"reason_code": &"encounter_option_payload_missing",
			"message_key": &"ui.encounter.option_payload_missing",
			"command_id": &"select_encounter_option",
		})
		return
	payload["source"] = "ui"
	var result := _dispatch_command(&"select_encounter_option", payload)
	var snapshot := run_context.get_status_snapshot()
	var reward: Dictionary = snapshot.get("last_reward", {})
	if not reward.is_empty():
		_show_loot_panel("遭遇结果", reward)
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
	extract_body_label.text = RunSurfaceModel.extract_modal_text(snapshot)
	if run_surface != null:
		run_surface.apply_legacy_modal_style(extract_panel, &"mini.exit")
	_apply_runtime_modal_layout(_current_layout_profile())
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
	loot_body_label.text = RunSurfaceModel.loot_modal_text(reward, String(run_context.last_message))
	if run_surface != null:
		run_surface.apply_legacy_modal_style(loot_panel, &"mini.chest")
	_apply_runtime_modal_layout(_current_layout_profile())
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
	if debug_panel != null and debug_panel.visible:
		_close_debug_panel()
		return true
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
	if debug_panel != null:
		debug_panel.visible = false
	if map_overlay_panel != null:
		map_overlay_panel.hide_overlay()


func _on_state_changed(_snapshot: Dictionary) -> void:
	_refresh_view_models()


func _on_result_available(snapshot: Dictionary) -> void:
	var display_snapshot := snapshot.duplicate(true)
	display_snapshot["meta_progress_commit"] = _commit_result_to_meta(snapshot)
	display_snapshot["meta_progress_summary"] = _meta_progress_summary()
	_refresh_view_models()
	_hide_runtime_popups()
	if result_panel != null:
		result_panel.show_summary(display_snapshot)


func _refresh_view_models() -> void:
	if run_context == null:
		return
	var snapshot := _shell_snapshot()
	var layout_profile: Dictionary = _current_layout_profile()
	_apply_runtime_modal_layout(layout_profile)
	var pos: Vector2i = snapshot.get("position", Vector2i.ZERO)
	var minimap_vm := MiniMapViewModel.build_from_run_map_snapshot(snapshot.get("run_map_snapshot", {}))
	if minimap_vm.room_markers.is_empty():
		minimap_vm = MiniMapViewModel.build_from_intel(run_context.intel_map, run_context.get_current_pos())
	if run_surface != null:
		var surface_model := RunSurfaceModel.build(snapshot, minimap_vm, layout_profile, last_command_result)
		run_surface.apply_layout_profile(layout_profile)
		run_surface.apply_surface_model(surface_model)
	if ui_shell != null:
		ui_shell.call("apply_snapshot", snapshot)
	if run_surface == null and room_badge != null:
		room_badge.text = "模式：%s | 阶段：%s | 房间：%s\n坐标：(%d,%d) | 周围雷险：%s" % [
			String(snapshot.get("mode", &"")),
			String(snapshot.get("phase", &"")),
			String(snapshot.get("current_room", &"Unknown")),
			pos.x,
			pos.y,
			snapshot.get("adjacent_mines", 0),
		]
	if run_surface == null and protocol_badge != null:
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
	if run_surface == null and layout_profile_label != null:
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
	if debug_panel != null and debug_panel.visible:
		_sync_debug_coordinates()
	if result_panel != null and bool(snapshot.get("run_active", false)):
		result_panel.hide_result()


func _current_layout_profile() -> Dictionary:
	var viewport_size: Vector2 = get_viewport_rect().size
	var window := get_window()
	if window != null and window.size.x > 0 and window.size.y > 0:
		var window_size := Vector2(float(window.size.x), float(window.size.y))
		viewport_size = Vector2(min(viewport_size.x, window_size.x), min(viewport_size.y, window_size.y))
	var requested_resolution_size := Vector2i.ZERO
	if SettingsManager != null:
		requested_resolution_size = SettingsManager.get_current_resolution_size()
	var profile: Dictionary = UILayoutProfileScript.profile_for_size(viewport_size)
	profile["actual_viewport_size"] = Vector2i(int(viewport_size.x), int(viewport_size.y))
	profile["requested_resolution_size"] = requested_resolution_size
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
	get_viewport().gui_release_focus()
	return result


func _show_command_feedback(result: Dictionary) -> void:
	if run_surface != null:
		run_surface.show_command_feedback(result)
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
	if not M1_DEBUG_PANEL_ENABLED:
		return
	if debug_panel != null:
		if not debug_panel.visible:
			_sync_debug_coordinates()
			_apply_debug_panel_layout(_current_layout_profile())
		debug_panel.visible = not debug_panel.visible


func _open_debug_panel_from_pause() -> void:
	if pause_panel != null:
		pause_panel.visible = false
	_open_debug_panel()


func _open_debug_panel() -> void:
	if not M1_DEBUG_PANEL_ENABLED or debug_panel == null:
		return
	_sync_debug_coordinates()
	_apply_debug_panel_layout(_current_layout_profile())
	debug_panel.visible = true


func _close_debug_panel() -> void:
	if debug_panel != null:
		debug_panel.visible = false
	get_viewport().gui_release_focus()


func _sync_debug_coordinates() -> void:
	if run_context == null:
		return
	if debug_x_spin != null:
		debug_x_spin.max_value = maxi(0, run_context.width - 1)
		debug_x_spin.value = clampi(run_context.get_current_pos().x, 0, maxi(0, run_context.width - 1))
	if debug_y_spin != null:
		debug_y_spin.max_value = maxi(0, run_context.height - 1)
		debug_y_spin.value = clampi(run_context.get_current_pos().y, 0, maxi(0, run_context.height - 1))


func _debug_target_pos() -> Vector2i:
	var x := 0
	var y := 0
	if debug_x_spin != null:
		x = int(debug_x_spin.value)
	if debug_y_spin != null:
		y = int(debug_y_spin.value)
	return Vector2i(x, y)


func _debug_teleport_to_exit() -> void:
	var result := _dispatch_command(&"debug_teleport_to_exit", {"source": "debug"})
	if bool(result.get("ok", false)) and player_controller != null:
		player_controller.reset_local_position()
	_sync_debug_coordinates()


func _debug_teleport_xy(enter_room: bool) -> void:
	var result := _dispatch_command(&"debug_teleport_to", {"pos": _debug_target_pos(), "enter_room": enter_room, "source": "debug"})
	if bool(result.get("ok", false)) and player_controller != null:
		player_controller.reset_local_position()
	_sync_debug_coordinates()


func _debug_search_and_show_loot() -> void:
	var result := _dispatch_command(&"search_current_room", {"source": "debug"})
	var snapshot := run_context.get_status_snapshot()
	var reward: Dictionary = snapshot.get("last_reward", {})
	if not reward.is_empty():
		_show_loot_panel("Debug Search Result", reward)
	else:
		_show_command_feedback(result)


func _debug_meta_add_gold() -> void:
	if meta_progress_adapter == null:
		return
	var summary := meta_progress_adapter.add_gold(1000, "m1_debug_panel")
	if debug_log != null:
		debug_log.text = "Meta debug: +1000 gold. Total=%s" % summary.get("gold", 0)
	if ui_shell != null:
		ui_shell.call("apply_snapshot", _shell_snapshot())


func _debug_meta_set_gold(amount: int) -> void:
	if meta_progress_adapter == null:
		return
	var summary := meta_progress_adapter.set_gold(amount, "m1_debug_panel")
	if debug_log != null:
		debug_log.text = "Meta debug: set gold=%s." % summary.get("gold", 0)
	if ui_shell != null:
		ui_shell.call("apply_snapshot", _shell_snapshot())


func _debug_meta_clear_gold() -> void:
	if meta_progress_adapter == null:
		return
	var summary := meta_progress_adapter.clear_gold()
	if debug_log != null:
		debug_log.text = "Meta debug: cleared gold. Total=%s" % summary.get("gold", 0)
	if ui_shell != null:
		ui_shell.call("apply_snapshot", _shell_snapshot())


func _debug_meta_add_warehouse_item() -> void:
	if meta_progress_adapter == null:
		return
	var summary := meta_progress_adapter.add_warehouse_item({
		"instance_id": "m1_debug_warehouse_item_%d" % Time.get_ticks_msec(),
		"item_id": "m1_debug_warehouse_item",
		"display_name": "M1 Debug Warehouse Item",
		"rarity": "rare",
		"base_value": 50,
		"source": "m1_debug_panel",
	})
	if debug_log != null:
		debug_log.text = "Meta debug: warehouse item added. Items=%s" % summary.get("warehouse_items_count", 0)
	if ui_shell != null:
		ui_shell.call("apply_snapshot", _shell_snapshot())


func _debug_meta_clear_warehouse() -> void:
	if meta_progress_adapter == null:
		return
	var summary := meta_progress_adapter.clear_warehouse("m1_debug_panel")
	if debug_log != null:
		debug_log.text = "Meta debug: warehouse cleared. Items=%s" % summary.get("warehouse_items_count", 0)
	if ui_shell != null:
		ui_shell.call("apply_snapshot", _shell_snapshot())


func _debug_meta_save() -> void:
	if meta_progress_adapter == null:
		return
	var summary := meta_progress_adapter.mark_debug_command("meta_save", {"source": "m1_debug_panel"})
	var saved := meta_progress_adapter.save()
	if debug_log != null:
		debug_log.text = "Meta debug: save=%s gold=%s items=%s" % [saved, summary.get("gold", 0), summary.get("warehouse_items_count", 0)]
	if ui_shell != null:
		ui_shell.call("apply_snapshot", _shell_snapshot())


func _debug_meta_clear_save() -> void:
	if meta_progress_adapter == null:
		return
	var summary := meta_progress_adapter.clear()
	summary = meta_progress_adapter.mark_debug_command("meta_clear_save", {"source": "m1_debug_panel"})
	if debug_log != null:
		debug_log.text = "Meta debug: save cleared. Total=%s" % summary.get("gold", 0)
	if ui_shell != null:
		ui_shell.call("apply_snapshot", _shell_snapshot())


func _debug_meta_summary() -> void:
	if meta_progress_adapter == null:
		return
	meta_progress_adapter.load_or_create_default()
	var summary := meta_progress_adapter.mark_debug_command("meta_read_save", {"source": "m1_debug_panel"})
	if debug_log != null:
		debug_log.text = "Meta summary: gold=%s runs=%s extracts=%s fails=%s items=%s" % [
			summary.get("gold", 0),
			summary.get("run_count", 0),
			summary.get("extract_count", 0),
			summary.get("fail_count", 0),
			summary.get("warehouse_items_count", 0),
		]
	if ui_shell != null:
		ui_shell.call("apply_snapshot", _shell_snapshot())


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


func _start_run_from_route(intent: Dictionary) -> void:
	var payload := NavigationIntentScript.payload(intent)
	var route_mode := StringName(payload.get("route_mode", &"standard_run"))
	match route_mode:
		&"tutorial_run":
			_start_tutorial_from_ui()
		&"demo_run":
			var result: Dictionary = command_bus.dispatch(&"start_demo_run")
			last_command_result = result.duplicate(true)
			_show_command_feedback(result)
			if player_controller != null:
				player_controller.reset_local_position()
			_show_run_screen()
		_:
			_start_standard_from_ui()


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
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _set_control_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y


func _add_menu_button(parent: Control, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(110, 34)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _add_debug_section(parent: Control, label: String) -> Label:
	var section := Label.new()
	section.text = label
	section.add_theme_font_size_override("font_size", 15)
	section.custom_minimum_size = Vector2(200, 24)
	parent.add_child(section)
	return section


func _add_debug_button(parent: Control, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(180, 28)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
