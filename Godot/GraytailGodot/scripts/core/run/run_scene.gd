extends Node2D

const CommandBusScript := preload("res://scripts/core/command/command_bus.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")
const HUDScene := preload("res://scenes/ui/hud/hud.tscn")
const MiniMapScene := preload("res://scenes/ui/minimap/minimap_panel.tscn")
const ResultPanelScene := preload("res://scenes/ui/result/result_panel.tscn")

var run_context: RunContext
var command_bus: CommandBus
var room_label: Label
var debug_log: Label
var hud: Hud
var minimap_panel: MiniMapPanel
var result_panel: ResultPanel


func _ready() -> void:
	ContentDB.load_asset_manifest()
	run_context = RunContextScript.new()
	command_bus = CommandBusScript.new()
	command_bus.bind_context(run_context)
	command_bus.state_changed.connect(_on_state_changed)
	command_bus.result_available.connect(_on_result_available)
	_build_accessible_ui()
	command_bus.start_tutorial_run()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up"):
		command_bus.move_by(Vector2i(0, -1))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		command_bus.move_by(Vector2i(0, 1))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left"):
		command_bus.move_by(Vector2i(-1, 0))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		command_bus.move_by(Vector2i(1, 0))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
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
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_restart_run"):
		command_bus.restart_run()
		get_viewport().set_input_as_handled()


func _build_accessible_ui() -> void:
	var ui_layer := get_node("UILayer") as CanvasLayer
	var root := Control.new()
	root.name = "S1AccessibleRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(root)

	var room_panel := PanelContainer.new()
	room_panel.name = "RoomArea"
	room_panel.offset_left = 400.0
	room_panel.offset_top = 48.0
	room_panel.offset_right = 880.0
	room_panel.offset_bottom = 220.0
	root.add_child(room_panel)

	room_label = Label.new()
	room_label.name = "RoomAreaLabel"
	room_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	room_label.text = "Room Area"
	room_panel.add_child(room_label)

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
	debug_title.text = "Debug"
	debug_panel.add_child(debug_title)
	_add_debug_button(debug_panel, "Tutorial", func() -> void: command_bus.start_tutorial_run())
	_add_debug_button(debug_panel, "Standard", func() -> void: command_bus.start_standard_run())
	_add_debug_button(debug_panel, "MoveUp", func() -> void: command_bus.move_by(Vector2i(0, -1)))
	_add_debug_button(debug_panel, "MoveDown", func() -> void: command_bus.move_by(Vector2i(0, 1)))
	_add_debug_button(debug_panel, "MoveLeft", func() -> void: command_bus.move_by(Vector2i(-1, 0)))
	_add_debug_button(debug_panel, "MoveRight", func() -> void: command_bus.move_by(Vector2i(1, 0)))
	_add_debug_button(debug_panel, "Flag", func() -> void: command_bus.flag_current_cell())
	_add_debug_button(debug_panel, "Search", func() -> void: command_bus.search_current_room())
	_add_debug_button(debug_panel, "Interact", func() -> void: command_bus.interact_current_room())
	_add_debug_button(debug_panel, "Fight", func() -> void: command_bus.fight_current_enemy())
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


func _add_debug_button(parent: Control, label: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(180, 28)
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
	if room_label != null:
		room_label.text = "Room Area\nMode: %s\nPhase: %s\nType: %s\nPosition: (%d,%d)\nAdjacent Mines: %s\nUse W/A/S/D, E, F, Space/J, Tab/M, R." % [
			String(snapshot.get("mode", &"")),
			String(snapshot.get("phase", &"")),
			String(snapshot.get("current_room", &"Unknown")),
			pos.x,
			pos.y,
			snapshot.get("adjacent_mines", 0),
		]

	if hud != null:
		hud.apply_view_model(HUDViewModel.build_status(run_context))
	if minimap_panel != null:
		minimap_panel.apply_view_model(MiniMapViewModel.build_from_intel(run_context.intel_map, run_context.get_current_pos()))
	if debug_log != null:
		debug_log.text = String(snapshot.get("last_message", ""))
	if result_panel != null and bool(snapshot.get("run_active", false)):
		result_panel.hide_result()
