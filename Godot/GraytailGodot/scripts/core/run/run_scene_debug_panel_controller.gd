extends RefCounted
class_name RunSceneDebugPanelController

const RunSceneDebugBridgeScript := preload("res://scripts/core/run/run_scene_debug_bridge.gd")
const DebugFailureBundleScript := preload("res://scripts/core/debug/debug_failure_bundle.gd")
const DebugSandboxSessionScript := preload("res://scripts/core/debug/debug_sandbox_session.gd")
const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const RunSceneRouteControllerScript := preload("res://scripts/core/run/run_scene_route_controller.gd")
const RunUIViewModelScript := preload("res://scripts/ui/shell/run_ui_view_model.gd")

var _enabled := false
var _run_context: Variant
var _meta_progress_adapter: Variant
var _save_manager: Variant
var _command_bus: Variant
var _player_controller: Variant
var _debug_panel: PanelContainer
var _session_banner: Label
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
var _show_pause: Callable
var _sandbox_session = DebugSandboxSessionScript.new()
var _debug_input_index := 0
var _last_debug_command: Dictionary = {}
var _session_commit_id := ""
var _focus_before_panel: Control
var _opened_from_pause := false


func bind_targets(
	enabled: bool,
	run_context: Variant,
	meta_progress_adapter: Variant,
	save_manager: Variant,
	command_bus: Variant,
	player_controller: Variant,
	run_overlay_root: Control,
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
	release_focus: Callable,
	show_pause: Callable
) -> void:
	_enabled = enabled
	_run_context = run_context
	_meta_progress_adapter = meta_progress_adapter
	_save_manager = save_manager
	_command_bus = command_bus
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
	_show_pause = show_pause
	_ensure_session_banner(run_overlay_root)
	_update_session_banner()


func start_test_room_if_requested(
	intent: Dictionary,
	admission_check: Callable,
	show_run: Callable,
	show_main: Callable
) -> bool:
	var payload := NavigationIntentScript.payload(intent)
	if not bool(payload.get("debug_test_room", false)):
		return false
	if not can_use_debug_tools():
		_show_debug_disabled_feedback()
		if show_main.is_valid():
			show_main.call()
		return true
	var began: Dictionary = _sandbox_session.begin(
		_save_manager,
		_meta_progress_adapter,
		_run_context != null and bool(_run_context.get("run_active")),
		StringName(payload.get("scenario_id", DebugSandboxSessionScript.DEFAULT_SCENARIO_ID)),
		int(payload.get("seed_value", DebugSandboxSessionScript.DEFAULT_SEED))
	)
	if not bool(began.get("ok", false)):
		_show_feedback(began)
		if show_main.is_valid():
			show_main.call()
		return true
	var route_result := RunSceneRouteControllerScript.start_from_intent(
		intent,
		_command_bus,
		admission_check
	)
	if bool(route_result.get("player_reset_requested", false)) and _player_controller != null:
		_player_controller.call("reset_local_position")
	if bool(route_result.get("run_screen_requested", false)) and show_run.is_valid():
		show_run.call()
	else:
		_sandbox_session.end(_save_manager, _meta_progress_adapter, false)
		_show_feedback(route_result)
		if show_main.is_valid():
			show_main.call()
	_update_session_banner()
	return true


func end_test_room_if_ready() -> Dictionary:
	if not _sandbox_session.active:
		return {"ok": true, "status": &"debug_sandbox_not_active"}
	var active_run := _run_context != null and bool(_run_context.get("run_active"))
	var result: Dictionary = _sandbox_session.end(
		_save_manager,
		_meta_progress_adapter,
		active_run
	)
	_update_session_banner()
	if not bool(result.get("ok", false)):
		_show_feedback(result)
	_refresh_shell()
	return result


func is_test_room_active() -> bool:
	return _sandbox_session.active


func test_room_snapshot() -> Dictionary:
	_sandbox_session.refresh_taint(_run_context, _meta_progress_adapter)
	return _sandbox_session.snapshot()


func toggle_panel() -> void:
	if _debug_panel == null:
		return
	if not can_use_debug_tools():
		_debug_panel.visible = false
		_show_debug_disabled_feedback()
		_release_gui_focus()
		return
	if _debug_panel.visible:
		close_panel()
	else:
		open_panel()


func open_from_pause() -> void:
	if not _runtime_modal_is_top.is_valid() or not bool(_runtime_modal_is_top.call(&"pause")):
		return
	_focus_before_panel = _debug_panel.get_viewport().gui_get_focus_owner() if _debug_panel != null else null
	_opened_from_pause = true
	if _pop_runtime_modal.is_valid():
		_pop_runtime_modal.call(&"pause", false)
	_open_panel_internal()


func open_panel() -> void:
	_opened_from_pause = false
	_focus_before_panel = _debug_panel.get_viewport().gui_get_focus_owner() if _debug_panel != null else null
	_open_panel_internal()


func _open_panel_internal() -> void:
	if _debug_panel == null:
		return
	if not can_use_debug_tools():
		_debug_panel.visible = false
		_show_debug_disabled_feedback()
		_release_gui_focus()
		return
	_debug_panel.visible = true
	call_deferred("_focus_first_panel_control")


func close_panel() -> void:
	if _debug_panel != null:
		_debug_panel.visible = false
	if _opened_from_pause and _show_pause.is_valid():
		_show_pause.call()
		call_deferred("_restore_previous_focus")
	else:
		call_deferred("_restore_previous_focus")
	_opened_from_pause = false


func hide_panel(release_focus: bool = true) -> void:
	if _debug_panel != null:
		_debug_panel.visible = false
	_opened_from_pause = false
	if release_focus:
		_release_gui_focus()


func is_open() -> bool:
	return _debug_panel != null and _debug_panel.visible


func _focus_first_panel_control() -> void:
	if _debug_panel == null or not _debug_panel.is_visible_in_tree():
		return
	for candidate in _debug_panel.find_children("*", "Button", true, false):
		var button := candidate as Button
		if (
			button != null
			and button.focus_mode == Control.FOCUS_ALL
			and button.is_visible_in_tree()
			and not button.disabled
		):
			button.grab_focus()
			return
	_release_gui_focus()


func _restore_previous_focus() -> void:
	if (
		_focus_before_panel != null
		and is_instance_valid(_focus_before_panel)
		and _focus_before_panel.is_inside_tree()
		and _focus_before_panel.is_visible_in_tree()
		and _focus_before_panel.focus_mode != Control.FOCUS_NONE
	):
		_focus_before_panel.grab_focus()
	else:
		_release_gui_focus()
	_focus_before_panel = null


func can_use_debug_tools() -> bool:
	return _enabled and RunSceneDebugBridgeScript.can_use_debug_tools()


func sync_coordinates() -> void:
	_update_session_banner()
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
		_debug_log.text = RunUIViewModelScript.player_message(message)


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


func capture_failure_bundle() -> void:
	if not _meta_debug_ready():
		return
	var run_snapshot := {}
	if _run_context != null and _run_context.has_method("get_status_snapshot"):
		var snapshot_variant: Variant = _run_context.call("get_status_snapshot")
		if snapshot_variant is Dictionary:
			run_snapshot = (snapshot_variant as Dictionary).duplicate(true)
	var ui_snapshot := {}
	if _shell_snapshot.is_valid():
		var shell_variant: Variant = _shell_snapshot.call()
		if shell_variant is Dictionary:
			ui_snapshot = (shell_variant as Dictionary).duplicate(true)
	var result := DebugFailureBundleScript.capture(
		_debug_panel.get_viewport() if _debug_panel != null else null,
		test_room_snapshot(),
		run_snapshot,
		_last_debug_command,
		ui_snapshot,
		_debug_input_index
	)
	set_log_text(
		"Failure bundle: %s" % str(result.get("bundle_path", result.get("status", "failed")))
	)


static func add_section(parent: Control, label: String) -> Label:
	var section := Label.new()
	section.text = label
	section.add_theme_font_size_override("font_size", 15)
	section.add_theme_color_override("font_color", Color(0.45, 0.92, 0.86, 1.0))
	section.custom_minimum_size = Vector2(200, 24)
	parent.add_child(section)
	return section


static func add_button(
	parent: Control,
	label: String,
	callback: Callable,
	dangerous_write: bool = true
) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(180, 28)
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("debug_operation_kind", &"write" if dangerous_write else &"read")
	button.tooltip_text = (
		"写命令：会将隔离测试会话标记为 TAINTED"
		if dangerous_write
		else "只读诊断：不修改运行或存档状态"
	)
	var normal := _debug_button_style(dangerous_write, false, false)
	var hover := _debug_button_style(dangerous_write, true, false)
	var pressed := _debug_button_style(dangerous_write, true, true)
	var focus := _debug_button_style(dangerous_write, true, false)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", normal)
	var text_color := Color(1.0, 0.72, 0.46, 1.0) if dangerous_write else Color(0.78, 0.96, 0.92, 1.0)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


static func _debug_button_style(
	dangerous_write: bool,
	emphasized: bool,
	pressed: bool
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = (
		Color(0.20, 0.08, 0.04, 0.98)
		if dangerous_write
		else Color(0.035, 0.105, 0.115, 0.98)
	)
	if emphasized:
		style.bg_color = style.bg_color.lightened(0.10)
	if pressed:
		style.bg_color = style.bg_color.darkened(0.08)
	style.border_color = (
		Color(0.96, 0.50, 0.22, 0.95)
		if dangerous_write
		else Color(0.28, 0.82, 0.76, 0.95)
	)
	var border := 2 if emphasized else 1
	style.border_width_left = border
	style.border_width_top = border
	style.border_width_right = border
	style.border_width_bottom = border
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style


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
	_debug_input_index += 1
	var result_variant: Variant = _dispatch_command.call(command_name, payload)
	var result: Dictionary = result_variant if result_variant is Dictionary else {}
	_last_debug_command = {
		"index": _debug_input_index,
		"command": command_name,
		"payload": payload.duplicate(true),
		"result": result.duplicate(true),
	}
	_update_session_banner()
	return result


func _show_feedback(result: Dictionary) -> void:
	if _show_command_feedback.is_valid():
		_show_command_feedback.call(result)


func _refresh_shell() -> void:
	if _ui_shell != null and _shell_snapshot.is_valid():
		_ui_shell.call("apply_snapshot", _shell_snapshot.call())
	_update_session_banner()


func _release_gui_focus() -> void:
	if _release_focus.is_valid():
		_release_focus.call()


func _ensure_session_banner(parent: Control) -> void:
	if parent == null or _session_banner != null:
		return
	_session_banner = Label.new()
	_session_banner.name = "DebugSandboxBanner"
	_session_banner.position = Vector2(288.0, 6.0)
	_session_banner.size = Vector2(720.0, 62.0)
	_session_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_session_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_session_banner.autowrap_mode = TextServer.AUTOWRAP_OFF
	_session_banner.clip_text = true
	_session_banner.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_session_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_session_banner.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32, 1.0))
	_session_banner.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.02, 1.0))
	_session_banner.add_theme_constant_override("outline_size", 3)
	_session_banner.add_theme_font_size_override("font_size", 13)
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(0.015, 0.035, 0.04, 0.94)
	banner_style.border_color = Color(0.84, 0.58, 0.20, 0.95)
	banner_style.border_width_left = 1
	banner_style.border_width_top = 1
	banner_style.border_width_right = 1
	banner_style.border_width_bottom = 1
	banner_style.corner_radius_top_left = 3
	banner_style.corner_radius_top_right = 3
	banner_style.corner_radius_bottom_left = 3
	banner_style.corner_radius_bottom_right = 3
	banner_style.content_margin_left = 8.0
	banner_style.content_margin_right = 8.0
	banner_style.content_margin_top = 4.0
	banner_style.content_margin_bottom = 4.0
	_session_banner.add_theme_stylebox_override("normal", banner_style)
	_session_banner.visible = false
	parent.add_child(_session_banner)
	_session_commit_id = DebugFailureBundleScript.commit_id()


func _update_session_banner() -> void:
	if _session_banner == null:
		return
	_sandbox_session.refresh_taint(_run_context, _meta_progress_adapter)
	var snapshot := _sandbox_session.snapshot()
	_session_banner.visible = bool(snapshot.get("active", false))
	if not _session_banner.visible:
		return
	var commit_short := _session_commit_id.substr(0, mini(8, _session_commit_id.length()))
	_session_banner.text = "DEBUG/TEST · %s · commit=%s\nprofile=%s · scenario=%s · seed=%s\nsave=%s" % [
		"TAINTED" if bool(snapshot.get("tainted", false)) else "CLEAN",
		commit_short,
		snapshot.get("profile_id", ""),
		snapshot.get("scenario_id", ""),
		snapshot.get("seed", 0),
		snapshot.get("save_target", ""),
	]
