extends PanelContainer

signal close_requested

const FIELD_NAMES := [
	"window_mode",
	"resolution_id",
	"vsync_mode",
	"frame_limit",
	"reduce_motion",
]
const WINDOW_MODE_VALUES := ["windowed", "borderless", "exclusive"]
const RESOLUTION_VALUES := ["auto", "1280x720", "1366x768", "1600x900", "1920x1080", "2560x1440"]
const VSYNC_VALUES := ["enabled", "disabled", "adaptive"]
const FRAME_LIMIT_VALUES := [0, 60, 120, 144]

var settings_manager: Node
var window_mode_option: OptionButton
var resolution_option: OptionButton
var vsync_option: OptionButton
var frame_limit_option: OptionButton
var reduce_motion_check: CheckButton
var status_label: Label
var confirmation_box: VBoxContainer
var confirmation_label: Label
var apply_button: Button
var confirm_button: Button
var revert_button: Button
var reset_button: Button
var close_button: Button

var _content: VBoxContainer
var _built := false
var _opened := false
var _committing_controls := false


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


func open_panel() -> bool:
	_build_once()
	if settings_manager == null or not settings_manager.has_method("begin_transaction"):
		return false
	if _opened:
		show()
		_refresh_from_manager()
		window_mode_option.call_deferred("grab_focus")
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
	window_mode_option.call_deferred("grab_focus")
	return true


func close_panel(emit_request: bool = true) -> void:
	if _opened and settings_manager != null and settings_manager.has_method("close_transaction"):
		settings_manager.call("close_transaction")
	_opened = false
	hide()
	if emit_request:
		close_requested.emit()


func field_control_names() -> PackedStringArray:
	return PackedStringArray(FIELD_NAMES)


func _build_once() -> void:
	if _built:
		return
	_built = true
	name = "SettingsPanel"
	custom_minimum_size = Vector2(560.0, 0.0)
	_content = VBoxContainer.new()
	_content.name = "SettingsFields"
	_content.add_theme_constant_override("separation", 10)
	add_child(_content)

	var title := Label.new()
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)

	window_mode_option = _make_option("WindowMode", ["窗口", "无边框全屏", "独占全屏"])
	_add_field_row("显示模式", window_mode_option)
	resolution_option = _make_option("Resolution", ["自动推荐", "1280×720", "1366×768", "1600×900", "1920×1080", "2560×1440"])
	_add_field_row("分辨率", resolution_option)
	vsync_option = _make_option("VSync", ["开启", "关闭", "自适应"])
	_add_field_row("垂直同步", vsync_option)
	frame_limit_option = _make_option("FrameLimit", ["不限制", "60", "120", "144"])
	_add_field_row("帧率上限", frame_limit_option)
	reduce_motion_check = CheckButton.new()
	reduce_motion_check.name = "ReduceMotion"
	reduce_motion_check.text = "减少循环动画与位移动效"
	_add_field_row("减少动态效果", reduce_motion_check)

	status_label = Label.new()
	status_label.name = "Status"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(status_label)

	confirmation_box = VBoxContainer.new()
	confirmation_box.name = "DisplayConfirmation"
	_content.add_child(confirmation_box)
	confirmation_label = Label.new()
	confirmation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirmation_box.add_child(confirmation_label)
	var confirmation_actions := HBoxContainer.new()
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


func _add_field_row(label_text: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_content.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150.0
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)


func _make_option(control_name: String, labels: Array) -> OptionButton:
	var option := OptionButton.new()
	option.name = control_name
	for label in labels:
		option.add_item(String(label))
	return option


func _on_apply_pressed() -> void:
	if settings_manager == null:
		return
	var window_mode_value: String = WINDOW_MODE_VALUES[window_mode_option.selected]
	var resolution_value: String = RESOLUTION_VALUES[resolution_option.selected]
	var vsync_value: String = VSYNC_VALUES[vsync_option.selected]
	var frame_limit_value: int = FRAME_LIMIT_VALUES[frame_limit_option.selected]
	var reduce_motion_value := reduce_motion_check.button_pressed
	_committing_controls = true
	var accepted := true
	accepted = bool(settings_manager.call("set_draft_value", &"window_mode", window_mode_value)) and accepted
	accepted = bool(settings_manager.call("set_draft_value", &"resolution_id", resolution_value)) and accepted
	accepted = bool(settings_manager.call("set_draft_value", &"vsync_mode", vsync_value)) and accepted
	accepted = bool(settings_manager.call("set_draft_value", &"frame_limit", frame_limit_value)) and accepted
	accepted = bool(settings_manager.call("set_draft_value", &"reduce_motion", reduce_motion_value)) and accepted
	if accepted:
		accepted = bool(settings_manager.call("apply_draft"))
	_committing_controls = false
	if not accepted:
		status_label.text = "设置未能应用；已保留原有生效值。"
	_refresh_from_manager()


func _on_confirm_pressed() -> void:
	if settings_manager != null:
		settings_manager.call("confirm_pending_changes")
	_refresh_from_manager()


func _on_revert_pressed() -> void:
	if settings_manager != null:
		settings_manager.call("revert_pending_changes", &"user_reverted")
	_refresh_from_manager()


func _on_reset_pressed() -> void:
	if settings_manager != null:
		settings_manager.call("reset_draft_to_defaults")
	_refresh_from_manager()


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
	reduce_motion_check.button_pressed = bool(draft_settings.get("reduce_motion", false))
	var pending := StringName(snapshot.get("state", &"")) == &"awaiting_confirmation"
	var read_only := bool(snapshot.get("read_only", false))
	confirmation_box.visible = pending
	if pending:
		confirmation_label.text = "请在 %d 秒内确认，否则将恢复全部原设置。" % int(snapshot.get("confirmation_seconds", 0))
		status_label.text = "正在预览新的显示设置。"
	elif read_only:
		status_label.text = "设置文件来自更高版本；本版本仅可读取，不会覆盖。"
	else:
		status_label.text = "显示设置采用固定 16:9 档位。"
	apply_button.disabled = pending or read_only
	reset_button.disabled = pending or read_only
	set_process(pending)


func _select_string(option: OptionButton, values: Array, value: String) -> void:
	var index := values.find(value)
	option.select(maxi(0, index))


func _select_int(option: OptionButton, values: Array, value: int) -> void:
	var index := values.find(value)
	option.select(maxi(0, index))


func _process(_delta: float) -> void:
	_refresh_from_manager()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _opened or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		close_panel()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and _opened and not is_visible_in_tree():
		if settings_manager != null and settings_manager.has_method("close_transaction"):
			settings_manager.call("close_transaction")
		_opened = false
