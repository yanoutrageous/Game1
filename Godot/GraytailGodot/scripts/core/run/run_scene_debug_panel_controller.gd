extends RefCounted
class_name RunSceneDebugPanelController

const RunSceneDebugBridgeScript := preload("res://scripts/core/run/run_scene_debug_bridge.gd")

var _enabled := false
var _run_context: Variant
var _meta_progress_adapter: Variant
var _player_controller: Variant
var _debug_panel: PanelContainer
var _debug_x_spin: SpinBox
var _debug_y_spin: SpinBox
var _debug_log: Label
var _ui_shell: Control
var _dispatch_command: Callable
var _show_command_feedback: Callable
var _shell_snapshot: Callable
var _show_loot_panel: Callable
var _runtime_modal_is_top: Callable
var _pop_runtime_modal: Callable
var _release_focus: Callable


func bind_targets(
	enabled: bool,
	run_context: Variant,
	meta_progress_adapter: Variant,
	player_controller: Variant,
	debug_panel: PanelContainer,
	debug_x_spin: SpinBox,
	debug_y_spin: SpinBox,
	debug_log: Label,
	ui_shell: Control,
	dispatch_command: Callable,
	show_command_feedback: Callable,
	shell_snapshot: Callable,
	show_loot_panel: Callable,
	runtime_modal_is_top: Callable,
	pop_runtime_modal: Callable,
	release_focus: Callable
) -> void:
	_enabled = enabled
	_run_context = run_context
	_meta_progress_adapter = meta_progress_adapter
	_player_controller = player_controller
	_debug_panel = debug_panel
	_debug_x_spin = debug_x_spin
	_debug_y_spin = debug_y_spin
	_debug_log = debug_log
	_ui_shell = ui_shell
	_dispatch_command = dispatch_command
	_show_command_feedback = show_command_feedback
	_shell_snapshot = shell_snapshot
	_show_loot_panel = show_loot_panel
	_runtime_modal_is_top = runtime_modal_is_top
	_pop_runtime_modal = pop_runtime_modal
	_release_focus = release_focus


func toggle_panel() -> void:
	if _debug_panel == null:
		return
	if not can_use_debug_tools():
		_debug_panel.visible = false
		_show_debug_disabled_feedback()
		_release_gui_focus()
		return
	_debug_panel.visible = not _debug_panel.visible
	_release_gui_focus()


func open_from_pause() -> void:
	if not _runtime_modal_is_top.is_valid() or not bool(_runtime_modal_is_top.call(&"pause")):
		return
	if _pop_runtime_modal.is_valid():
		_pop_runtime_modal.call(&"pause", false)
	open_panel()


func open_panel() -> void:
	if _debug_panel == null:
		return
	if not can_use_debug_tools():
		_debug_panel.visible = false
		_show_debug_disabled_feedback()
		_release_gui_focus()
		return
	_debug_panel.visible = true
	_release_gui_focus()


func close_panel() -> void:
	hide_panel()


func hide_panel(release_focus: bool = true) -> void:
	if _debug_panel != null:
		_debug_panel.visible = false
	if release_focus:
		_release_gui_focus()


func is_open() -> bool:
	return _debug_panel != null and _debug_panel.visible


func can_use_debug_tools() -> bool:
	return _enabled and RunSceneDebugBridgeScript.can_use_debug_tools()


func sync_coordinates() -> void:
	if _run_context == null:
		return
	if _debug_x_spin != null:
		_debug_x_spin.max_value = maxi(0, int(_run_context.get("width")) - 1)
		_debug_x_spin.value = clampi(
			int(_run_context.call("get_current_pos").x),
			0,
			maxi(0, int(_run_context.get("width")) - 1)
		)
	if _debug_y_spin != null:
		_debug_y_spin.max_value = maxi(0, int(_run_context.get("height")) - 1)
		_debug_y_spin.value = clampi(
			int(_run_context.call("get_current_pos").y),
			0,
			maxi(0, int(_run_context.get("height")) - 1)
		)


func set_log_text(message: String) -> void:
	if _debug_log != null:
		_debug_log.text = message


func teleport_to_exit() -> void:
	var result := _dispatch(&"debug_teleport_to_exit", {"source": "debug"})
	if bool(result.get("ok", false)) and _player_controller != null:
		_player_controller.call("reset_local_position")
	sync_coordinates()


func teleport_to_room_type(room_type: StringName) -> void:
	if _run_context == null or _run_context.get("truth_map") == null:
		_show_feedback({
			"ok": false,
			"accepted": false,
			"reason_code": &"not_ready",
			"command_id": &"debug_find_room",
		})
		return
	var target := RunSceneDebugBridgeScript.nearest_room_of_type(_run_context, room_type)
	if target.x < 0:
		_show_feedback({
			"ok": false,
			"accepted": false,
			"reason_code": &"debug_target_missing",
			"command_id": &"debug_find_room",
		})
		return
	var result := _dispatch(&"debug_teleport_to", {
		"pos": target,
		"enter_room": true,
		"source": "debug",
		"target_room_type": room_type,
	})
	if bool(result.get("ok", false)) and _player_controller != null:
		# Acceptance helpers seed a real room snapshot, then put the avatar at a
		# deterministic walkable inspection point inside the chest interaction
		# radius when the requested room is a chest.
		if room_type == &"Chest":
			_player_controller.call("set_local_position", Vector2(0.56, 0.53))
		else:
			_player_controller.call("reset_local_position")
	sync_coordinates()


func teleport_xy(enter_room: bool) -> void:
	var result := _dispatch(&"debug_teleport_to", {
		"pos": _target_pos(),
		"enter_room": enter_room,
		"source": "debug",
	})
	if bool(result.get("ok", false)) and _player_controller != null:
		_player_controller.call("reset_local_position")
	sync_coordinates()


func search_and_show_loot() -> void:
	var result := _dispatch(&"search_current_room", {"source": "debug"})
	if _run_context == null:
		_show_feedback(result)
		return
	var snapshot_variant: Variant = _run_context.call("get_status_snapshot")
	var snapshot: Dictionary = snapshot_variant if snapshot_variant is Dictionary else {}
	var reward: Dictionary = snapshot.get("last_reward", {})
	if not reward.is_empty():
		hide_panel()
		if _show_loot_panel.is_valid():
			_show_loot_panel.call("Debug Search Result", reward)
	else:
		_show_feedback(result)


func toggle_reduced_motion() -> void:
	var enabled := not bool(ProjectSettings.get_setting("accessibility/reduce_motion", false))
	ProjectSettings.set_setting("accessibility/reduce_motion", enabled)
	_show_feedback({
		"ok": true,
		"message": "减弱动态已开启：动画冻结在可辨识姿态。" if enabled else "完整动态已开启：恢复循环动画与脉冲反馈。",
	})


func meta_add_gold() -> void:
	if not _meta_debug_ready():
		return
	var summary := RunSceneDebugBridgeScript.debug_add_gold(
		_meta_progress_adapter,
		1000,
		"m1_debug_panel"
	)
	set_log_text(RunSceneDebugBridgeScript.debug_result_message(
		"Meta debug: +1000 gold.",
		summary
	))
	_refresh_shell()


func meta_set_gold(amount: int) -> void:
	if not _meta_debug_ready():
		return
	var summary := RunSceneDebugBridgeScript.debug_set_gold(
		_meta_progress_adapter,
		amount,
		"m1_debug_panel"
	)
	set_log_text(RunSceneDebugBridgeScript.debug_result_message(
		"Meta debug: set gold.",
		summary
	))
	_refresh_shell()


func meta_clear_gold() -> void:
	if not _meta_debug_ready():
		return
	var summary := RunSceneDebugBridgeScript.debug_clear_gold(_meta_progress_adapter)
	set_log_text(RunSceneDebugBridgeScript.debug_result_message(
		"Meta debug: cleared gold.",
		summary
	))
	_refresh_shell()


func meta_add_warehouse_item() -> void:
	if not _meta_debug_ready():
		return
	var summary := RunSceneDebugBridgeScript.debug_add_warehouse_item(
		_meta_progress_adapter,
		{
			"instance_id": "m1_debug_warehouse_item_%d" % Time.get_ticks_msec(),
			"item_id": "m1_debug_warehouse_item",
			"display_name": "M1 Debug Warehouse Item",
			"rarity": "rare",
			"base_value": 50,
			"source": "m1_debug_panel",
		}
	)
	set_log_text(RunSceneDebugBridgeScript.debug_result_message(
		"Meta debug: warehouse item added.",
		summary
	))
	_refresh_shell()


func meta_clear_warehouse() -> void:
	if not _meta_debug_ready():
		return
	var summary := RunSceneDebugBridgeScript.debug_clear_warehouse(
		_meta_progress_adapter,
		"m1_debug_panel"
	)
	set_log_text(RunSceneDebugBridgeScript.debug_result_message(
		"Meta debug: warehouse cleared.",
		summary
	))
	_refresh_shell()


func meta_save() -> void:
	if not _meta_debug_ready():
		return
	var result := RunSceneDebugBridgeScript.debug_mark_and_save(
		_meta_progress_adapter,
		"meta_save",
		{"source": "m1_debug_panel"}
	)
	var summary: Dictionary = result.get("summary", {})
	set_log_text("Meta debug: save=%s gold=%s items=%s" % [
		bool(result.get("saved", false)),
		summary.get("gold", 0),
		summary.get("warehouse_items_count", 0),
	])
	_refresh_shell()


func meta_clear_save() -> void:
	if not _meta_debug_ready():
		return
	var summary := RunSceneDebugBridgeScript.debug_clear_save(
		_meta_progress_adapter,
		"m1_debug_panel"
	)
	set_log_text(RunSceneDebugBridgeScript.debug_result_message(
		"Meta debug: save cleared.",
		summary
	))
	_refresh_shell()


func meta_summary() -> void:
	if not _meta_debug_ready():
		return
	var summary := RunSceneDebugBridgeScript.debug_read_summary(
		_meta_progress_adapter,
		"m1_debug_panel"
	)
	set_log_text("Meta summary: gold=%s runs=%s extracts=%s fails=%s items=%s" % [
		summary.get("gold", 0),
		summary.get("run_count", 0),
		summary.get("extract_count", 0),
		summary.get("fail_count", 0),
		summary.get("warehouse_items_count", 0),
	])
	_refresh_shell()


static func add_section(parent: Control, label: String) -> Label:
	var section := Label.new()
	section.text = label
	section.add_theme_font_size_override("font_size", 15)
	section.custom_minimum_size = Vector2(200, 24)
	parent.add_child(section)
	return section


static func add_button(parent: Control, label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(180, 28)
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _target_pos() -> Vector2i:
	var x := int(_debug_x_spin.value) if _debug_x_spin != null else 0
	var y := int(_debug_y_spin.value) if _debug_y_spin != null else 0
	return Vector2i(x, y)


func _meta_debug_ready() -> bool:
	if not can_use_debug_tools():
		_show_debug_disabled_feedback()
		return false
	return _meta_progress_adapter != null


func _show_debug_disabled_feedback() -> void:
	_show_feedback(RunSceneDebugBridgeScript.disabled_feedback())


func _dispatch(command_name: StringName, payload: Dictionary = {}) -> Dictionary:
	if not _dispatch_command.is_valid():
		return {}
	var result_variant: Variant = _dispatch_command.call(command_name, payload)
	return result_variant if result_variant is Dictionary else {}


func _show_feedback(result: Dictionary) -> void:
	if _show_command_feedback.is_valid():
		_show_command_feedback.call(result)


func _refresh_shell() -> void:
	if _ui_shell != null and _shell_snapshot.is_valid():
		_ui_shell.call("apply_snapshot", _shell_snapshot.call())


func _release_gui_focus() -> void:
	if _release_focus.is_valid():
		_release_focus.call()
