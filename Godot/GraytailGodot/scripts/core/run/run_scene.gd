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

var run_context: RunContext
var command_bus: CommandBus
var mode_label: Label
var room_label: Label
var controls_label: Label
var debug_log: Label
var hud: Hud
var minimap_panel: MiniMapPanel
var result_panel: ResultPanel
var map_overlay_panel: MapOverlayPanel
var tutorial_popup_panel: TutorialPopupPanel
var room_controller: RoomSceneController
var player_controller: PlayerController


func _ready() -> void:
	ContentDB.load_asset_manifest()
	run_context = RunContextScript.new()
	command_bus = CommandBusScript.new()
	command_bus.bind_context(run_context)
	command_bus.state_changed.connect(_on_state_changed)
	command_bus.result_available.connect(_on_result_available)
	_build_playfield_visuals()
	_build_accessible_ui()
	command_bus.start_tutorial_run()
	if player_controller != null:
		player_controller.reset_local_position()


func _process(delta: float) -> void:
	if player_controller == null or command_bus == null or run_context == null:
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
	if event.is_action_pressed("interact"):
		command_bus.interact_current_room()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("attack"):
		command_bus.fight_current_enemy()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("flag_cell"):
		command_bus.flag_current_cell()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_map"):
		command_bus.dispatch(&"open_map")
		_toggle_map_overlay()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_restart_run"):
		command_bus.restart_run()
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
	var root := Control.new()
	root.name = "S1AccessibleRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(root)

	var mode_panel := VBoxContainer.new()
	mode_panel.name = "ModeEntryPanel"
	mode_panel.offset_left = 400.0
	mode_panel.offset_top = 16.0
	mode_panel.offset_right = 880.0
	mode_panel.offset_bottom = 120.0
	root.add_child(mode_panel)

	mode_label = Label.new()
	mode_label.name = "ModeEntryLabel"
	mode_label.text = "Choose a mode"
	mode_panel.add_child(mode_label)
	_add_mode_button(mode_panel, "Start Tutorial 5x5", func() -> void: _start_tutorial_from_ui())
	_add_mode_button(mode_panel, "Start Standard 10x10", func() -> void: _start_standard_from_ui())

	var room_panel := PanelContainer.new()
	room_panel.name = "RoomArea"
	room_panel.offset_left = 400.0
	room_panel.offset_top = 136.0
	room_panel.offset_right = 880.0
	room_panel.offset_bottom = 308.0
	root.add_child(room_panel)

	room_label = Label.new()
	room_label.name = "RoomAreaLabel"
	room_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	room_label.text = "Room Area"
	room_panel.add_child(room_label)

	controls_label = Label.new()
	controls_label.name = "ControlsLabel"
	controls_label.offset_left = 400.0
	controls_label.offset_top = 320.0
	controls_label.offset_right = 880.0
	controls_label.offset_bottom = 404.0
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_label.text = "Controls: W/A/S/D or arrows move inside the room. Reach a door to change rooms. E searches, interacts, or extracts. Space/J fights. F flags current room. M/Tab map. R restarts."
	root.add_child(controls_label)

	hud = HUDScene.instantiate() as Hud
	hud.name = "HUD"
	root.add_child(hud)

	minimap_panel = MiniMapScene.instantiate() as MiniMapPanel
	minimap_panel.name = "MiniMapPanel"
	minimap_panel.offset_left = 1010.0
	minimap_panel.offset_top = 24.0
	minimap_panel.offset_right = 1260.0
	minimap_panel.offset_bottom = 300.0
	root.add_child(minimap_panel)

	var debug_panel := VBoxContainer.new()
	debug_panel.name = "DebugOperationPanel"
	debug_panel.offset_left = 1010.0
	debug_panel.offset_top = 320.0
	debug_panel.offset_right = 1260.0
	debug_panel.offset_bottom = 690.0
	root.add_child(debug_panel)

	var debug_title := Label.new()
	debug_title.text = "Debug / Grid Move"
	debug_panel.add_child(debug_title)
	_add_debug_button(debug_panel, "Tutorial", func() -> void: _start_tutorial_from_ui())
	_add_debug_button(debug_panel, "Standard", func() -> void: _start_standard_from_ui())
	_add_debug_button(debug_panel, "GridUp", func() -> void: command_bus.move_by(Vector2i(0, -1)))
	_add_debug_button(debug_panel, "GridDown", func() -> void: command_bus.move_by(Vector2i(0, 1)))
	_add_debug_button(debug_panel, "GridLeft", func() -> void: command_bus.move_by(Vector2i(-1, 0)))
	_add_debug_button(debug_panel, "GridRight", func() -> void: command_bus.move_by(Vector2i(1, 0)))
	_add_debug_button(debug_panel, "Flag", func() -> void: command_bus.flag_current_cell())
	_add_debug_button(debug_panel, "Search", func() -> void: command_bus.search_current_room())
	_add_debug_button(debug_panel, "Interact", func() -> void: command_bus.interact_current_room())
	_add_debug_button(debug_panel, "Fight", func() -> void: command_bus.fight_current_enemy())
	_add_debug_button(debug_panel, "Map", func() -> void: _open_map_from_debug())
	_add_debug_button(debug_panel, "ReqExtract", func() -> void: command_bus.request_extract())
	_add_debug_button(debug_panel, "ConfirmExt", func() -> void: command_bus.confirm_extract())
	_add_debug_button(debug_panel, "CancelExt", func() -> void: command_bus.cancel_extract())
	_add_debug_button(debug_panel, "Restart", func() -> void: command_bus.restart_run())

	debug_log = Label.new()
	debug_log.name = "DebugLastMessage"
	debug_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_panel.add_child(debug_log)

	result_panel = ResultPanelScene.instantiate() as ResultPanel
	result_panel.name = "ResultPanel"
	result_panel.hide_result()
	root.add_child(result_panel)

	map_overlay_panel = MapOverlayScene.instantiate() as MapOverlayPanel
	map_overlay_panel.name = "MapOverlayPanel"
	map_overlay_panel.cell_action_requested.connect(_on_map_overlay_cell_action_requested)
	root.add_child(map_overlay_panel)

	tutorial_popup_panel = TutorialPopupScene.instantiate() as TutorialPopupPanel
	tutorial_popup_panel.name = "TutorialPopupPanel"
	tutorial_popup_panel.confirmed.connect(_on_tutorial_popup_confirmed)
	root.add_child(tutorial_popup_panel)


func _add_debug_button(parent: Control, label: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(180, 28)
	button.pressed.connect(callback)
	parent.add_child(button)


func _add_mode_button(parent: Control, label: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(360, 34)
	button.pressed.connect(callback)
	parent.add_child(button)


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
	if mode_label != null:
		mode_label.text = "Mode: %s | Phase: %s | Outcome: %s" % [
			String(snapshot.get("mode", &"")),
			String(snapshot.get("phase", &"")),
			String(snapshot.get("outcome", "Running")),
		]
	if room_label != null:
		room_label.text = "Room Area\nMode: %s\nPhase: %s\nType: %s\nPosition: (%d,%d)\nAdjacent Mines: %s\nUse W/A/S/D, E, F, Space/J, Tab/M, R." % [
			String(snapshot.get("mode", &"")),
			String(snapshot.get("phase", &"")),
			String(snapshot.get("current_room", &"Unknown")),
			pos.x,
			pos.y,
			snapshot.get("adjacent_mines", 0),
		]

	if room_controller != null:
		room_controller.configure(PresentationMapping.room_visual_from_snapshot(snapshot))
	if player_controller != null:
		player_controller.set_visual_asset(&"sprite.player.default")
	if hud != null:
		hud.apply_view_model(HUDViewModel.build_status(run_context))
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


func _open_map_from_debug() -> void:
	command_bus.dispatch(&"open_map")
	_toggle_map_overlay()


func _on_tutorial_popup_confirmed() -> void:
	if command_bus != null:
		command_bus.confirm_tutorial_popup()


func _start_tutorial_from_ui() -> void:
	command_bus.start_tutorial_run()
	if player_controller != null:
		player_controller.reset_local_position()


func _start_standard_from_ui() -> void:
	command_bus.start_standard_run()
	if player_controller != null:
		player_controller.reset_local_position()


func _attempt_room_transition(direction: Vector2i) -> void:
	var before := run_context.get_current_pos()
	var result := command_bus.attempt_room_transition(direction)
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
		command_bus.toggle_flag_cell(pos)
		return
	if bool(marker.get("explored", false)) and not bool(marker.get("mine", false)):
		var result := command_bus.teleport_to_explored(pos)
		if bool(result.get("ok", false)):
			if player_controller != null:
				player_controller.reset_local_position()
			if map_overlay_panel != null:
				map_overlay_panel.hide_overlay()
