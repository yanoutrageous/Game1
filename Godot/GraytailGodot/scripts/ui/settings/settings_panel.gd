extends PanelContainer

signal close_requested
signal test_room_requested

const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const DebugGateScript := preload("res://scripts/core/debug/debug_gate.gd")

const FIELD_NAMES := [
	"window_mode",
	"resolution_id",
	"vsync_mode",
	"frame_limit",
	"ui_scale_percent",
	"master_volume",
	"effects_volume",
	"haptics_enabled",
	"reduce_motion",
]
const WINDOW_MODE_VALUES := ["windowed", "borderless", "exclusive"]
const RESOLUTION_VALUES := ["auto", "1280x720", "1366x768", "1600x900", "1920x1080", "2560x1440"]
const VSYNC_VALUES := ["enabled", "disabled", "adaptive"]
const FRAME_LIMIT_VALUES := [0, 60, 120, 144]
const UI_SCALE_PERCENT_VALUES := [100, 125, 150]

var settings_manager: Node
var window_mode_option: OptionButton
var resolution_option: OptionButton
var vsync_option: OptionButton
var frame_limit_option: OptionButton
var ui_scale_option: OptionButton
var master_volume_slider: HSlider
var master_volume_value_label: Label
var effects_volume_slider: HSlider
var effects_volume_value_label: Label
var haptics_enabled_check: CheckButton
var reduce_motion_check: CheckButton
var test_room_button: Button
var status_label: Label
var confirmation_box: VBoxContainer
var confirmation_label: Label
var apply_button: Button
var confirm_button: Button
var revert_button: Button
var reset_button: Button
var close_button: Button

var _content: VBoxContainer
var _fields_scroll: ScrollContainer
var _fields_grid: GridContainer
var _built := false
var _opened := false
var _committing_controls := false
var _external_cancel_authority := false
var _display_confirmation_active := false
var _ui_scale_factor := 1.0


func _ready() -> void:
	_build_once()
	hide()
	set_process(false)


func bind_settings_manager(manager: Node) -> void:
	var callback := Callable(self, "_on_transaction_changed")
	if settings_manager != null and settings_manager.has_signal("transaction_changed"):
		if settings_manager.is_connected("transaction_changed", callback):
			settings_manager.disconnect("transaction_changed", callback)
	settings_manager = manager
	if settings_manager != null and settings_manager.has_signal("transaction_changed"):
		settings_manager.connect("transaction_changed", callback)
	_refresh_from_manager()


func set_ui_scale_factor(value: float) -> void:
	_ui_scale_factor = Art10UISkinKitScript.normalize_runtime_ui_scale_factor(value)
	set_meta("runtime_ui_scale_factor", _ui_scale_factor)
	if _built:
		_refresh_ui_scale_metrics()


func get_ui_scale_factor() -> float:
	return _ui_scale_factor


func open_panel() -> bool:
	_build_once()
	set_ui_scale_factor(Art10UISkinKitScript.runtime_ui_scale_factor())
	if settings_manager == null or not settings_manager.has_method("begin_transaction"):
		return false
	if _opened:
		show()
		_refresh_from_manager()
		call_deferred("_focus_window_mode_option_if_valid")
		return true
	var transaction_began := bool(settings_manager.call("begin_transaction"))
	var read_only := (
		settings_manager.has_method("is_persistence_read_only")
		and bool(settings_manager.call("is_persistence_read_only"))
	)
	if not transaction_began and not read_only:
		return false
	_opened = true
	show()
	_refresh_from_manager()
	call_deferred("_focus_window_mode_option_if_valid")
	return true


func _focus_window_mode_option_if_valid() -> void:
	if _display_confirmation_active:
		_focus_confirm_button_if_valid()
		return
	if (
		_opened
		and visible
		and window_mode_option != null
		and is_instance_valid(window_mode_option)
		and not window_mode_option.is_queued_for_deletion()
		and window_mode_option.is_inside_tree()
		and window_mode_option.is_visible_in_tree()
	):
		window_mode_option.grab_focus()


func _focus_confirm_button_if_valid() -> void:
	if (
		_opened
		and visible
		and _display_confirmation_active
		and confirm_button != null
		and is_instance_valid(confirm_button)
		and not confirm_button.is_queued_for_deletion()
		and confirm_button.is_inside_tree()
		and confirm_button.is_visible_in_tree()
	):
		confirm_button.grab_focus()


func close_panel(emit_request: bool = true) -> void:
	if _opened and settings_manager != null and settings_manager.has_method("close_transaction"):
		settings_manager.call("close_transaction")
	_opened = false
	hide()
	if emit_request:
		_emit_player_feedback(&"ui_confirm", {"surface": &"settings", "action": &"close"})
		close_requested.emit()


func field_control_names() -> PackedStringArray:
	return PackedStringArray(FIELD_NAMES)


func preferred_focus_control() -> Control:
	_build_once()
	if _display_confirmation_active and confirm_button != null:
		return confirm_button
	return window_mode_option


func set_external_cancel_authority(enabled: bool) -> void:
	_external_cancel_authority = enabled


func is_panel_open() -> bool:
	return _opened


func _build_once() -> void:
	if _built:
		return
	_built = true
	name = "SettingsPanel"
	_ui_scale_factor = Art10UISkinKitScript.runtime_ui_scale_factor()
	set_meta("runtime_ui_scale_factor", _ui_scale_factor)
	Art10UISkinKitScript.apply_player_ui_theme(self)
	custom_minimum_size = Vector2(560.0, 0.0)
	_content = VBoxContainer.new()
	_content.name = "SettingsFields"
	_content.add_theme_constant_override("separation", 10)
	add_child(_content)

	var title := Label.new()
	title.name = "SettingsTitle"
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)
	_fields_scroll = ScrollContainer.new()
	_fields_scroll.name = "SettingsFieldScroll"
	_fields_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_fields_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_fields_scroll.clip_contents = true
	_fields_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fields_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fields_scroll.custom_minimum_size.y = 300.0
	_content.add_child(_fields_scroll)
	_fields_grid = GridContainer.new()
	_fields_grid.name = "SettingsFieldGrid"
	_fields_grid.columns = 2
	_fields_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fields_grid.add_theme_constant_override("h_separation", 14)
	_fields_grid.add_theme_constant_override("v_separation", 6)
	_fields_scroll.add_child(_fields_grid)

	window_mode_option = _make_option("WindowMode", ["窗口", "无边框全屏", "独占全屏"])
	_add_field_row("显示模式", window_mode_option)
	resolution_option = _make_option("Resolution", ["自动推荐", "1280×720", "1366×768", "1600×900", "1920×1080", "2560×1440"])
	_add_field_row("分辨率", resolution_option)
	vsync_option = _make_option("VSync", ["开启", "关闭", "自适应"])
	_add_field_row("垂直同步", vsync_option)
	frame_limit_option = _make_option("FrameLimit", ["不限制", "60", "120", "144"])
	_add_field_row("帧率上限", frame_limit_option)
	ui_scale_option = _make_option("UIScale", ["100%", "125%", "150%"])
	_add_field_row("界面缩放", ui_scale_option)
	var master_volume_control := HBoxContainer.new()
	master_volume_control.name = "MasterVolumeControl"
	master_volume_control.add_theme_constant_override("separation", 10)
	master_volume_slider = HSlider.new()
	master_volume_slider.name = "MasterVolume"
	master_volume_slider.min_value = 0.0
	master_volume_slider.max_value = 100.0
	master_volume_slider.step = 5.0
	master_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	master_volume_control.add_child(master_volume_slider)
	master_volume_value_label = Label.new()
	master_volume_value_label.name = "MasterVolumeValue"
	master_volume_value_label.custom_minimum_size.x = 52.0
	master_volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	master_volume_control.add_child(master_volume_value_label)
	_add_field_row("主音量", master_volume_control)
	var effects_volume_control := HBoxContainer.new()
	effects_volume_control.name = "EffectsVolumeControl"
	effects_volume_control.add_theme_constant_override("separation", 10)
	effects_volume_slider = HSlider.new()
	effects_volume_slider.name = "EffectsVolume"
	effects_volume_slider.min_value = 0.0
	effects_volume_slider.max_value = 100.0
	effects_volume_slider.step = 5.0
	effects_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effects_volume_slider.value_changed.connect(_on_effects_volume_changed)
	effects_volume_control.add_child(effects_volume_slider)
	effects_volume_value_label = Label.new()
	effects_volume_value_label.name = "EffectsVolumeValue"
	effects_volume_value_label.custom_minimum_size.x = 52.0
	effects_volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	effects_volume_control.add_child(effects_volume_value_label)
	_add_field_row("效果音量", effects_volume_control)
	haptics_enabled_check = CheckButton.new()
	haptics_enabled_check.name = "HapticsEnabled"
	haptics_enabled_check.text = "手柄震动反馈"
	_add_field_row("震动", haptics_enabled_check)
	reduce_motion_check = CheckButton.new()
	reduce_motion_check.name = "ReduceMotion"
	reduce_motion_check.text = "减少循环动画与位移动效"
	_add_field_row("减少动态效果", reduce_motion_check)
	if DebugGateScript.is_debug_tools_enabled():
		test_room_button = Button.new()
		test_room_button.name = "EnterDebugTestRoom"
		test_room_button.text = "进入隔离测试场"
		test_room_button.tooltip_text = "使用 dev_sandbox 独立存档和固定 7×7 场景。"
		test_room_button.pressed.connect(_on_test_room_pressed)
		_add_field_row("开发与测试", test_room_button)

	status_label = Label.new()
	status_label.name = "Status"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(status_label)

	confirmation_box = VBoxContainer.new()
	confirmation_box.name = "DisplayConfirmation"
	confirmation_box.alignment = BoxContainer.ALIGNMENT_CENTER
	confirmation_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirmation_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	confirmation_box.add_theme_constant_override("separation", 16)
	_content.add_child(confirmation_box)
	confirmation_label = Label.new()
	confirmation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirmation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	confirmation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirmation_label.clip_text = false
	confirmation_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	confirmation_box.add_child(confirmation_label)
	var confirmation_actions := HBoxContainer.new()
	confirmation_actions.name = "DisplayConfirmationActions"
	confirmation_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	confirmation_box.add_child(confirmation_actions)
	confirm_button = Button.new()
	confirm_button.text = "保留显示设置"
	confirm_button.pressed.connect(_on_confirm_pressed)
	confirmation_actions.add_child(confirm_button)
	revert_button = Button.new()
	revert_button.text = "恢复原设置"
	revert_button.pressed.connect(_on_revert_pressed)
	confirmation_actions.add_child(revert_button)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	_content.add_child(actions)
	reset_button = Button.new()
	reset_button.text = "恢复默认"
	reset_button.pressed.connect(_on_reset_pressed)
	actions.add_child(reset_button)
	apply_button = Button.new()
	apply_button.text = "应用"
	apply_button.pressed.connect(_on_apply_pressed)
	actions.add_child(apply_button)
	close_button = Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(close_panel)
	actions.add_child(close_button)
	confirmation_box.hide()
	_apply_material_and_safe_zones(title)
	_refresh_ui_scale_metrics()


func _add_field_row(label_text: String, control: Control) -> void:
	var row := VBoxContainer.new()
	row.name = "%sField" % control.name
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 3)
	_fields_grid.add_child(row)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)


func _make_option(control_name: String, labels: Array) -> OptionButton:
	var option := OptionButton.new()
	option.name = control_name
	option.alignment = HORIZONTAL_ALIGNMENT_LEFT
	option.fit_to_longest_item = false
	option.clip_text = true
	option.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	option.custom_minimum_size.y = 30.0
	_register_scaled_control(option, Art10UISkinKitScript.font_size(&"body"), option.custom_minimum_size)
	for label in labels:
		option.add_item(String(label))
	Art10UISkinKitScript.apply_option_button_theme(option)
	return option


func _apply_material_and_safe_zones(title: Label) -> void:
	set_meta("ui_composition_role", &"body")
	set_meta("ui_panel_safe_margin", 20)
	_content.add_theme_constant_override("separation", 6)
	_apply_scaled_composition_label(
		title,
		&"title",
		24,
		Art10UISkinKitScript.color(&"gold")
	)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.max_lines_visible = 1
	_apply_settings_text_tree(_fields_grid)
	for slider in [master_volume_slider, effects_volume_slider]:
		if slider != null:
			slider.custom_minimum_size.y = 26.0
			slider.focus_mode = Control.FOCUS_ALL
			_register_scaled_control(slider, -1, slider.custom_minimum_size)
	for value_label in [master_volume_value_label, effects_volume_value_label]:
		if value_label != null:
			_register_scaled_control(value_label, -1, value_label.custom_minimum_size)
			_apply_scaled_composition_label(
				value_label,
				&"status",
				15,
				Art10UISkinKitScript.color(&"accent")
			)
	for toggle in [haptics_enabled_check, reduce_motion_check]:
		if toggle != null:
			toggle.custom_minimum_size.y = 30.0
			toggle.focus_mode = Control.FOCUS_ALL
			toggle.clip_text = true
			toggle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			_register_scaled_control(
				toggle,
				Art10UISkinKitScript.font_size(&"body"),
				toggle.custom_minimum_size
			)
	_apply_scaled_composition_label(
		status_label,
		&"body",
		14,
		Art10UISkinKitScript.color(&"caption")
	)
	status_label.custom_minimum_size.y = 34.0
	_register_scaled_control(status_label, -1, status_label.custom_minimum_size)
	_apply_scaled_composition_label(
		confirmation_label,
		&"body",
		14,
		Art10UISkinKitScript.color(&"text")
	)
	for action in [confirm_button, revert_button, reset_button, apply_button, close_button]:
		if action != null:
			action.custom_minimum_size.y = 32.0
			_register_scaled_control(
				action,
				Art10UISkinKitScript.font_size(&"button"),
				action.custom_minimum_size
			)
			action.set_meta("ui_composition_role", &"button")
			action.set_meta("ui_panel_safe_margin", 22)
	if test_room_button != null:
		test_room_button.custom_minimum_size.y = 32.0
		test_room_button.set_meta("ui_composition_role", &"button")
		test_room_button.set_meta("ui_panel_safe_margin", 22)
		_register_scaled_control(
			test_room_button,
			Art10UISkinKitScript.font_size(&"button"),
			test_room_button.custom_minimum_size
		)
	var confirmation_actions := confirm_button.get_parent() as HBoxContainer
	if confirmation_actions != null:
		confirmation_actions.add_theme_constant_override("separation", 8)
	var actions := apply_button.get_parent() as HBoxContainer
	if actions != null:
		actions.add_theme_constant_override("separation", 8)


func _apply_settings_text_tree(node: Node) -> void:
	if node == null:
		return
	if node is Label:
		_apply_scaled_composition_label(
			node as Label,
			&"body",
			16,
			Art10UISkinKitScript.color(&"text")
		)
	for child in node.get_children():
		_apply_settings_text_tree(child)


func _apply_scaled_composition_label(
	label: Label,
	role: StringName,
	base_font_size: int,
	font_color: Color = Color(-1, -1, -1, -1)
) -> void:
	if label == null:
		return
	label.set_meta("settings_base_font_size", base_font_size)
	label.set_meta("settings_composition_role", role)
	Art10UISkinKitScript.apply_composition_label(
		label,
		role,
		Art10UISkinKitScript.scaled_font_size(base_font_size, _ui_scale_factor),
		font_color
	)
	label.set_meta("runtime_ui_scale_factor", _ui_scale_factor)


func _register_scaled_control(control: Control, base_font_size: int, base_minimum_size: Vector2) -> void:
	if control == null:
		return
	if base_font_size > 0:
		control.set_meta("settings_base_font_size", base_font_size)
	control.set_meta("settings_base_minimum_size", base_minimum_size)


func _refresh_ui_scale_metrics() -> void:
	for control in _control_descendants(self):
		_apply_registered_control_scale(control)
	# AppShell reparents the production close button into the modal art layer.
	# Keep it on the same scale contract even though it is no longer our child.
	if close_button != null and not is_ancestor_of(close_button):
		_apply_registered_control_scale(close_button)


func _apply_registered_control_scale(control: Control) -> void:
	if control == null:
		return
	if control.has_meta("settings_base_minimum_size"):
		var base_minimum: Vector2 = control.get_meta("settings_base_minimum_size", Vector2.ZERO)
		control.custom_minimum_size = Art10UISkinKitScript.scaled_control_minimum(
			base_minimum,
			_ui_scale_factor
		)
	if control.has_meta("settings_base_font_size"):
		var base_font_size := int(control.get_meta("settings_base_font_size", 0))
		var scaled_font_size := Art10UISkinKitScript.scaled_font_size(base_font_size, _ui_scale_factor)
		if control is Label:
			Art10UISkinKitScript.apply_composition_label(
				control as Label,
				StringName(control.get_meta("settings_composition_role", &"body")),
				scaled_font_size
			)
		else:
			control.add_theme_font_size_override("font_size", scaled_font_size)
	if control.name == "SettingsTitle" and control is Label:
		var title := control as Label
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.clip_text = true
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.max_lines_visible = 1
	control.set_meta("runtime_ui_scale_factor", _ui_scale_factor)


func _control_descendants(root_node: Node) -> Array[Control]:
	var result: Array[Control] = []
	for child in root_node.get_children():
		if child is Control:
			result.append(child as Control)
		result.append_array(_control_descendants(child))
	return result


func _on_apply_pressed() -> void:
	if settings_manager == null:
		return
	var window_mode_value: String = WINDOW_MODE_VALUES[window_mode_option.selected]
	var resolution_value: String = RESOLUTION_VALUES[resolution_option.selected]
	var vsync_value: String = VSYNC_VALUES[vsync_option.selected]
	var frame_limit_value: int = FRAME_LIMIT_VALUES[frame_limit_option.selected]
	var ui_scale_percent_value: int = UI_SCALE_PERCENT_VALUES[ui_scale_option.selected]
	var master_volume_value := int(round(master_volume_slider.value))
	var effects_volume_value := int(round(effects_volume_slider.value))
	var haptics_enabled_value := haptics_enabled_check.button_pressed
	var reduce_motion_value := reduce_motion_check.button_pressed
	_committing_controls = true
	var accepted := true
	accepted = bool(settings_manager.call("set_draft_value", &"window_mode", window_mode_value)) and accepted
	accepted = bool(settings_manager.call("set_draft_value", &"resolution_id", resolution_value)) and accepted
	accepted = bool(settings_manager.call("set_draft_value", &"vsync_mode", vsync_value)) and accepted
	accepted = bool(settings_manager.call("set_draft_value", &"frame_limit", frame_limit_value)) and accepted
	accepted = bool(settings_manager.call("set_draft_value", &"ui_scale_percent", ui_scale_percent_value)) and accepted
	accepted = bool(settings_manager.call("set_draft_value", &"master_volume", master_volume_value)) and accepted
	accepted = bool(settings_manager.call("set_draft_value", &"effects_volume", effects_volume_value)) and accepted
	accepted = bool(settings_manager.call("set_draft_value", &"haptics_enabled", haptics_enabled_value)) and accepted
	accepted = bool(settings_manager.call("set_draft_value", &"reduce_motion", reduce_motion_value)) and accepted
	if accepted:
		accepted = bool(settings_manager.call("apply_draft"))
	_committing_controls = false
	_emit_player_feedback(
		&"ui_confirm" if accepted else &"ui_reject",
		{"surface": &"settings", "action": &"apply"}
	)
	if not accepted:
		status_label.text = "设置未能应用；已保留原有生效值。"
	_refresh_from_manager()


func _on_confirm_pressed() -> void:
	var accepted := false
	if settings_manager != null:
		accepted = bool(settings_manager.call("confirm_pending_changes"))
	_emit_player_feedback(
		&"ui_confirm" if accepted else &"ui_reject",
		{"surface": &"settings", "action": &"confirm_display"}
	)
	_refresh_from_manager()


func _on_revert_pressed() -> void:
	var accepted := false
	if settings_manager != null:
		accepted = bool(settings_manager.call("revert_pending_changes", &"user_reverted"))
	_emit_player_feedback(
		&"ui_confirm" if accepted else &"ui_reject",
		{"surface": &"settings", "action": &"revert_display"}
	)
	_refresh_from_manager()


func _on_reset_pressed() -> void:
	var accepted := false
	if settings_manager != null:
		accepted = bool(settings_manager.call("reset_draft_to_defaults"))
	_emit_player_feedback(
		&"ui_confirm" if accepted else &"ui_reject",
		{"surface": &"settings", "action": &"reset_draft"}
	)
	_refresh_from_manager()


func _on_test_room_pressed() -> void:
	if not _opened or not DebugGateScript.is_debug_tools_enabled():
		return
	_emit_player_feedback(
		&"ui_confirm",
		{"surface": &"settings", "action": &"enter_debug_test_room"}
	)
	test_room_requested.emit()


func _on_transaction_changed(_snapshot: Dictionary) -> void:
	if _committing_controls:
		return
	_refresh_from_manager()


func _refresh_from_manager() -> void:
	if not _built or settings_manager == null or not settings_manager.has_method("transaction_snapshot"):
		return
	var snapshot: Dictionary = settings_manager.call("transaction_snapshot")
	var draft_settings: Dictionary = snapshot.get("draft", {})
	_select_string(window_mode_option, WINDOW_MODE_VALUES, String(draft_settings.get("window_mode", "windowed")))
	_select_string(resolution_option, RESOLUTION_VALUES, String(draft_settings.get("resolution_id", "auto")))
	_select_string(vsync_option, VSYNC_VALUES, String(draft_settings.get("vsync_mode", "enabled")))
	_select_int(frame_limit_option, FRAME_LIMIT_VALUES, int(draft_settings.get("frame_limit", 0)))
	_select_int(ui_scale_option, UI_SCALE_PERCENT_VALUES, int(draft_settings.get("ui_scale_percent", 100)))
	master_volume_slider.set_value_no_signal(float(draft_settings.get("master_volume", 80)))
	_update_master_volume_label()
	effects_volume_slider.set_value_no_signal(float(draft_settings.get("effects_volume", 80)))
	_update_effects_volume_label()
	haptics_enabled_check.button_pressed = bool(draft_settings.get("haptics_enabled", true))
	reduce_motion_check.button_pressed = bool(draft_settings.get("reduce_motion", false))
	var pending := StringName(snapshot.get("state", &"")) == &"awaiting_confirmation"
	var entered_confirmation := pending and not _display_confirmation_active
	var exited_confirmation := not pending and _display_confirmation_active
	_display_confirmation_active = pending
	var read_only := bool(snapshot.get("read_only", false))
	confirmation_box.visible = pending
	_fields_scroll.visible = not pending
	_fields_grid.visible = not pending
	var action_row := apply_button.get_parent() as HBoxContainer
	if action_row != null:
		action_row.visible = not pending
	status_label.visible = not pending
	if pending:
		confirmation_label.text = "请在 %d 秒内确认，否则将恢复全部原设置。" % int(snapshot.get("confirmation_seconds", 0))
		status_label.text = "正在预览新的显示设置。"
	elif read_only:
		status_label.text = "设置文件来自更高版本；本版本仅可读取，不会覆盖。"
	else:
		status_label.text = "画面、声音与动态效果会按当前值应用；显示模式与分辨率变更需确认。"
	apply_button.disabled = pending or read_only
	reset_button.disabled = pending or read_only
	set_process(pending)
	if entered_confirmation:
		call_deferred("_focus_confirm_button_if_valid")
	elif exited_confirmation:
		call_deferred("_focus_window_mode_option_if_valid")


func _select_string(option: OptionButton, values: Array, value: String) -> void:
	var index := values.find(value)
	option.select(maxi(0, index))


func _select_int(option: OptionButton, values: Array, value: int) -> void:
	var index := values.find(value)
	option.select(maxi(0, index))


func _on_master_volume_changed(_value: float) -> void:
	_update_master_volume_label()


func _update_master_volume_label() -> void:
	if master_volume_value_label != null and master_volume_slider != null:
		master_volume_value_label.text = "%d%%" % int(round(master_volume_slider.value))


func _on_effects_volume_changed(_value: float) -> void:
	_update_effects_volume_label()


func _update_effects_volume_label() -> void:
	if effects_volume_value_label != null and effects_volume_slider != null:
		effects_volume_value_label.text = "%d%%" % int(round(effects_volume_slider.value))


func _emit_player_feedback(cue_id: StringName, metadata: Dictionary) -> void:
	if not is_inside_tree():
		return
	var service := get_tree().get_first_node_in_group("player_feedback_service")
	if service != null and service.has_method("emit_cue"):
		service.call("emit_cue", cue_id, "", metadata)


func _process(_delta: float) -> void:
	_refresh_from_manager()


func _unhandled_key_input(event: InputEvent) -> void:
	if _external_cancel_authority or not _opened or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		close_panel()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and _opened and not is_visible_in_tree():
		if settings_manager != null and settings_manager.has_method("close_transaction"):
			settings_manager.call("close_transaction")
		_opened = false
