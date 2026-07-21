extends Node

signal transaction_changed(snapshot: Dictionary)
signal settings_applied(settings: Dictionary)
signal settings_persisted(settings: Dictionary)
signal settings_reverted(settings: Dictionary, reason: StringName)
signal confirmation_required(seconds_remaining: int)
signal confirmation_tick(seconds_remaining: int)
signal persistence_failed(message: String)

const SettingsStoreScript := preload("res://scripts/core/settings/settings_store.gd")
const RuntimeInputProfileScript := preload("res://scripts/core/input/runtime_input_profile.gd")

const SETTINGS_PATH := "user://settings.cfg"
const CONFIRMATION_SECONDS := 15
const CONFIRMATION_MSEC := CONFIRMATION_SECONDS * 1000

const KEY_WINDOW_MODE := "window_mode"
const KEY_RESOLUTION_ID := "resolution_id"
const KEY_VSYNC_MODE := "vsync_mode"
const KEY_FRAME_LIMIT := "frame_limit"
const KEY_REDUCE_MOTION := "reduce_motion"
const DISPLAY_RESOLUTION_KEY := &"display.resolution_id"
const DISPLAY_RESOLUTION_SOURCE_KEY := &"display.resolution_source"
const REDUCE_MOTION_PROJECT_KEY := "accessibility/reduce_motion"

const STATE_IDLE := &"idle"
const STATE_EDITING := &"editing"
const STATE_AWAITING_CONFIRMATION := &"awaiting_confirmation"
const STATE_READ_ONLY := &"read_only"

const MIN_SUPPORTED_RESOLUTION := Vector2i(1280, 720)
const SUPPORTED_RESOLUTIONS := [
	{"id": &"1280x720", "label": "1280x720", "size": Vector2i(1280, 720)},
	{"id": &"1366x768", "label": "1366x768", "size": Vector2i(1366, 768)},
	{"id": &"1600x900", "label": "1600x900", "size": Vector2i(1600, 900)},
	{"id": &"1920x1080", "label": "1920x1080", "size": Vector2i(1920, 1080)},
	{"id": &"2560x1440", "label": "2560x1440", "size": Vector2i(2560, 1440)},
]

var persisted: Dictionary = {}
var applied: Dictionary = {}
var draft: Dictionary = {}
var rollback: Dictionary = {}

var current_resolution_id: StringName = &"1280x720"
var current_resolution_size := MIN_SUPPORTED_RESOLUTION
var current_resolution_source := &"auto"
var display_notice := ""
var load_status := &"not_loaded"
var persistence_read_only := false
var last_persistence_error := ""

var store_path := SETTINGS_PATH
var display_adapter: Variant
var _store: RefCounted
var _clock: Callable
var _initialized := false
var _transaction_state := STATE_IDLE
var _confirmation_deadline_msec := 0
var _last_confirmation_tick := -1


class RuntimeDisplayAdapter:
	extends RefCounted

	func apply_settings(settings: Dictionary, resolution_size: Vector2i) -> Dictionary:
		Engine.max_fps = int(settings.get(KEY_FRAME_LIMIT, 0))
		if not DisplayServer.window_can_draw():
			return {"ok": true}
		var vsync_mode := DisplayServer.VSYNC_ENABLED
		match String(settings.get(KEY_VSYNC_MODE, "enabled")):
			"disabled":
				vsync_mode = DisplayServer.VSYNC_DISABLED
			"adaptive":
				vsync_mode = DisplayServer.VSYNC_ADAPTIVE
		DisplayServer.window_set_vsync_mode(vsync_mode)
		match String(settings.get(KEY_WINDOW_MODE, "windowed")):
			"exclusive":
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			"borderless":
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			_:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_min_size(MIN_SUPPORTED_RESOLUTION)
				DisplayServer.window_set_max_size(_largest_resolution())
				DisplayServer.window_set_size(resolution_size)
				_center_window(resolution_size)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, true)
		return {"ok": true}

	func _largest_resolution() -> Vector2i:
		var entry: Dictionary = SUPPORTED_RESOLUTIONS[SUPPORTED_RESOLUTIONS.size() - 1]
		return entry.get("size", MIN_SUPPORTED_RESOLUTION)

	func _center_window(resolution_size: Vector2i) -> void:
		var screen := DisplayServer.window_get_current_screen()
		var usable_rect := DisplayServer.screen_get_usable_rect(screen)
		if usable_rect.size.x <= 0 or usable_rect.size.y <= 0:
			return
		var centered_offset := Vector2i(
			maxi(0, int((usable_rect.size.x - resolution_size.x) / 2)),
			maxi(0, int((usable_rect.size.y - resolution_size.y) / 2))
		)
		DisplayServer.window_set_position(usable_rect.position + centered_offset)


func _init(
	custom_store_path: String = SETTINGS_PATH,
	custom_display_adapter: Variant = null,
	custom_clock: Callable = Callable()
) -> void:
	store_path = custom_store_path if not custom_store_path.is_empty() else SETTINGS_PATH
	display_adapter = custom_display_adapter if custom_display_adapter != null else RuntimeDisplayAdapter.new()
	_clock = custom_clock


func _ready() -> void:
	initialize_runtime()
	print_verbose("SettingsManager ready")


func initialize_runtime() -> void:
	if _initialized:
		return
	RuntimeInputProfileScript.install()
	_store = SettingsStoreScript.new(store_path)
	var load_result: Dictionary = _store.load_settings()
	load_status = StringName(load_result.get("status", &"load_failed"))
	persistence_read_only = bool(load_result.get("read_only", false))
	last_persistence_error = String(load_result.get("error", ""))
	var loaded_settings: Dictionary = load_result.get("settings", SettingsStoreScript.default_settings())
	persisted = SettingsStoreScript.normalize_settings(loaded_settings)
	applied = persisted.duplicate(true)
	draft = applied.duplicate(true)
	rollback.clear()
	_transaction_state = STATE_READ_ONLY if persistence_read_only else STATE_IDLE
	_initialized = true
	_apply_runtime_settings(applied)
	if bool(load_result.get("recovery_required", false)) and not persistence_read_only:
		var repair_result: Dictionary = _store.save_settings(persisted)
		if bool(repair_result.get("ok", false)):
			load_status = &"recovered_and_repaired"
		else:
			last_persistence_error = String(repair_result.get("error", "settings recovery could not be persisted"))
	set_process(false)
	_emit_transaction_changed()


func begin_transaction() -> bool:
	initialize_runtime()
	if persistence_read_only or _transaction_state == STATE_AWAITING_CONFIRMATION:
		return false
	draft = applied.duplicate(true)
	rollback.clear()
	_transaction_state = STATE_EDITING
	_emit_transaction_changed()
	return true


func set_draft_value(field_name: StringName, value: Variant) -> bool:
	initialize_runtime()
	var field := String(field_name)
	if persistence_read_only or not SettingsStoreScript.is_valid_field_value(field, value):
		return false
	if _transaction_state == STATE_IDLE:
		if not begin_transaction():
			return false
	if _transaction_state != STATE_EDITING:
		return false
	draft[field] = value
	_emit_transaction_changed()
	return true


func reset_draft_to_defaults() -> bool:
	if persistence_read_only:
		return false
	if _transaction_state == STATE_IDLE and not begin_transaction():
		return false
	if _transaction_state != STATE_EDITING:
		return false
	draft = SettingsStoreScript.default_settings()
	_emit_transaction_changed()
	return true


func apply_draft() -> bool:
	initialize_runtime()
	if persistence_read_only or _transaction_state != STATE_EDITING:
		return false
	var candidate: Dictionary = SettingsStoreScript.normalize_settings(draft, applied)
	if candidate == applied:
		draft = applied.duplicate(true)
		_emit_transaction_changed()
		return true
	rollback = applied.duplicate(true)
	if not _apply_runtime_settings(candidate):
		last_persistence_error = "display adapter rejected settings"
		_refresh_resolution_state(applied)
		rollback.clear()
		persistence_failed.emit(last_persistence_error)
		_emit_transaction_changed()
		return false
	applied = candidate
	draft = applied.duplicate(true)
	settings_applied.emit(applied.duplicate(true))
	if _has_dangerous_display_delta(rollback, applied):
		_transaction_state = STATE_AWAITING_CONFIRMATION
		_confirmation_deadline_msec = _now_msec() + CONFIRMATION_MSEC
		_last_confirmation_tick = CONFIRMATION_SECONDS
		set_process(true)
		confirmation_required.emit(CONFIRMATION_SECONDS)
		_emit_transaction_changed()
		return true
	return _persist_applied_or_rollback()


func confirm_pending_changes() -> bool:
	if _transaction_state != STATE_AWAITING_CONFIRMATION:
		return false
	var save_result: Dictionary = _store.save_settings(applied)
	if not bool(save_result.get("ok", false)):
		last_persistence_error = String(save_result.get("error", "settings save failed"))
		persistence_read_only = bool(save_result.get("read_only", false))
		persistence_failed.emit(last_persistence_error)
		_restore_rollback(&"persistence_failed")
		return false
	persisted = applied.duplicate(true)
	draft = applied.duplicate(true)
	rollback.clear()
	_confirmation_deadline_msec = 0
	_last_confirmation_tick = -1
	_transaction_state = STATE_EDITING
	set_process(false)
	settings_persisted.emit(persisted.duplicate(true))
	_emit_transaction_changed()
	return true


func revert_pending_changes(reason: StringName = &"cancelled") -> bool:
	if _transaction_state != STATE_AWAITING_CONFIRMATION:
		return false
	_restore_rollback(reason)
	return true


func close_transaction() -> void:
	if _transaction_state == STATE_AWAITING_CONFIRMATION:
		_restore_rollback(&"closed")
	draft = applied.duplicate(true)
	rollback.clear()
	_confirmation_deadline_msec = 0
	_last_confirmation_tick = -1
	_transaction_state = STATE_READ_ONLY if persistence_read_only else STATE_IDLE
	set_process(false)
	_emit_transaction_changed()


func cancel_transaction() -> void:
	close_transaction()


func get_persisted_settings() -> Dictionary:
	initialize_runtime()
	return persisted.duplicate(true)


func get_applied_settings() -> Dictionary:
	initialize_runtime()
	return applied.duplicate(true)


func get_draft_settings() -> Dictionary:
	initialize_runtime()
	return draft.duplicate(true)


func get_rollback_settings() -> Dictionary:
	return rollback.duplicate(true)


func get_transaction_state() -> StringName:
	return _transaction_state


func is_confirmation_pending() -> bool:
	return _transaction_state == STATE_AWAITING_CONFIRMATION


func is_draft_dirty() -> bool:
	return draft != applied


func is_persistence_read_only() -> bool:
	return persistence_read_only


func confirmation_seconds_remaining() -> int:
	if _transaction_state != STATE_AWAITING_CONFIRMATION:
		return 0
	var remaining_msec := maxi(0, _confirmation_deadline_msec - _now_msec())
	return ceili(float(remaining_msec) / 1000.0)


func transaction_snapshot() -> Dictionary:
	return {
		"state": _transaction_state,
		"persisted": persisted.duplicate(true),
		"applied": applied.duplicate(true),
		"draft": draft.duplicate(true),
		"rollback": rollback.duplicate(true),
		"dirty": is_draft_dirty(),
		"confirmation_seconds": confirmation_seconds_remaining(),
		"read_only": persistence_read_only,
		"load_status": load_status,
		"last_error": last_persistence_error,
	}


func _process(_delta: float) -> void:
	if _transaction_state != STATE_AWAITING_CONFIRMATION:
		set_process(false)
		return
	var seconds_remaining := confirmation_seconds_remaining()
	if seconds_remaining != _last_confirmation_tick:
		_last_confirmation_tick = seconds_remaining
		confirmation_tick.emit(seconds_remaining)
		_emit_transaction_changed()
	if seconds_remaining <= 0:
		_restore_rollback(&"timeout")


func _persist_applied_or_rollback() -> bool:
	var save_result: Dictionary = _store.save_settings(applied)
	if bool(save_result.get("ok", false)):
		persisted = applied.duplicate(true)
		draft = applied.duplicate(true)
		rollback.clear()
		_transaction_state = STATE_EDITING
		settings_persisted.emit(persisted.duplicate(true))
		_emit_transaction_changed()
		return true
	last_persistence_error = String(save_result.get("error", "settings save failed"))
	persistence_read_only = bool(save_result.get("read_only", false))
	persistence_failed.emit(last_persistence_error)
	_restore_rollback(&"persistence_failed")
	return false


func _restore_rollback(reason: StringName) -> void:
	var restored := rollback.duplicate(true) if not rollback.is_empty() else persisted.duplicate(true)
	_apply_runtime_settings(restored)
	applied = restored
	draft = restored.duplicate(true)
	rollback.clear()
	_confirmation_deadline_msec = 0
	_last_confirmation_tick = -1
	_transaction_state = STATE_READ_ONLY if persistence_read_only else STATE_EDITING
	set_process(false)
	settings_reverted.emit(applied.duplicate(true), reason)
	_emit_transaction_changed()


func _apply_runtime_settings(settings: Dictionary) -> bool:
	_refresh_resolution_state(settings)
	if display_adapter == null or not display_adapter.has_method("apply_settings"):
		return false
	var adapter_result: Variant = display_adapter.call("apply_settings", settings.duplicate(true), current_resolution_size)
	var adapter_ok := true
	if typeof(adapter_result) == TYPE_BOOL:
		adapter_ok = bool(adapter_result)
	elif typeof(adapter_result) == TYPE_DICTIONARY:
		adapter_ok = bool(adapter_result.get("ok", false))
	if not adapter_ok:
		return false
	ProjectSettings.set_setting(REDUCE_MOTION_PROJECT_KEY, bool(settings.get(KEY_REDUCE_MOTION, false)))
	return true


func _has_dangerous_display_delta(before: Dictionary, after: Dictionary) -> bool:
	return (
		String(before.get(KEY_WINDOW_MODE, "windowed")) != String(after.get(KEY_WINDOW_MODE, "windowed"))
		or String(before.get(KEY_RESOLUTION_ID, "auto")) != String(after.get(KEY_RESOLUTION_ID, "auto"))
	)


func _now_msec() -> int:
	if _clock.is_valid():
		return int(_clock.call())
	return Time.get_ticks_msec()


func _emit_transaction_changed() -> void:
	transaction_changed.emit(transaction_snapshot())


# Compatibility surface for the existing engineering settings page. It routes
# through the same transaction owner; it does not create a second settings store.
func get_value(key: StringName, default_value: Variant = null) -> Variant:
	initialize_runtime()
	var field_name := _field_name_for_legacy_key(key)
	if not field_name.is_empty():
		return draft.get(field_name, default_value)
	if key == DISPLAY_RESOLUTION_SOURCE_KEY:
		return current_resolution_source
	return default_value


func set_value(key: StringName, value: Variant) -> void:
	var field_name := _field_name_for_legacy_key(key)
	if not field_name.is_empty():
		set_draft_value(field_name, value)


func reset_to_defaults() -> void:
	if _transaction_state == STATE_IDLE:
		begin_transaction()
	if reset_draft_to_defaults():
		apply_draft()


func apply_startup_display_settings() -> void:
	initialize_runtime()
	_apply_runtime_settings(applied)


func supported_resolution_entries() -> Array:
	return SUPPORTED_RESOLUTIONS.duplicate(true)


func get_current_resolution_id() -> StringName:
	return current_resolution_id


func get_current_resolution_size() -> Vector2i:
	return current_resolution_size


func get_current_resolution_source() -> StringName:
	return current_resolution_source


func get_display_notice() -> String:
	return display_notice


func display_settings_summary() -> String:
	var source_label := "自动推荐" if current_resolution_source == &"auto" else "手动选择"
	var notice_suffix := "" if display_notice.is_empty() else "\n" + display_notice
	return "当前分辨率：%s（%s）\n仅支持固定 16:9 档位；窗口不可拖拽自由缩放。%s" % [
		String(current_resolution_id),
		source_label,
		notice_suffix,
	]


func apply_resolution_id(resolution_id: StringName, _source: StringName = &"manual") -> bool:
	if not is_supported_resolution_id(resolution_id):
		return false
	if _transaction_state == STATE_IDLE and not begin_transaction():
		return false
	return set_draft_value(KEY_RESOLUTION_ID, String(resolution_id)) and apply_draft()


func apply_auto_recommended_resolution() -> void:
	reset_display_resolution_to_auto()


func reset_display_resolution_to_auto() -> void:
	if _transaction_state == STATE_IDLE:
		begin_transaction()
	if set_draft_value(KEY_RESOLUTION_ID, "auto"):
		apply_draft()


func recommended_resolution_for_current_screen() -> Dictionary:
	var available_size := MIN_SUPPORTED_RESOLUTION
	if DisplayServer.window_can_draw():
		var usable_rect := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		if usable_rect.size.x > 0 and usable_rect.size.y > 0:
			available_size = usable_rect.size
	return recommended_resolution_for_size(available_size)


func recommended_resolution_for_size(available_size: Vector2i) -> Dictionary:
	var best: Dictionary = SUPPORTED_RESOLUTIONS[0]
	for index in range(SUPPORTED_RESOLUTIONS.size() - 1, -1, -1):
		var entry: Dictionary = SUPPORTED_RESOLUTIONS[index]
		var candidate_size: Vector2i = entry.get("size", MIN_SUPPORTED_RESOLUTION)
		if candidate_size.x <= available_size.x and candidate_size.y <= available_size.y:
			return entry
	return best


func is_supported_resolution_id(resolution_id: StringName) -> bool:
	return not _entry_for_id(resolution_id).is_empty()


func resolution_id_for_size(size: Vector2i) -> StringName:
	for entry in SUPPORTED_RESOLUTIONS:
		if entry.get("size", MIN_SUPPORTED_RESOLUTION) == size:
			return StringName(entry.get("id", &""))
	return &""


func _entry_for_id(resolution_id: StringName) -> Dictionary:
	for entry in SUPPORTED_RESOLUTIONS:
		if StringName(entry.get("id", &"")) == resolution_id:
			return entry
	return {}


func _refresh_resolution_state(settings: Dictionary) -> void:
	var requested_id := StringName(settings.get(KEY_RESOLUTION_ID, "auto"))
	var entry: Dictionary
	if requested_id == &"auto":
		entry = recommended_resolution_for_current_screen()
		current_resolution_source = &"auto"
	else:
		entry = _entry_for_id(requested_id)
		current_resolution_source = &"manual"
	if entry.is_empty():
		entry = SUPPORTED_RESOLUTIONS[0]
	current_resolution_id = StringName(entry.get("id", &"1280x720"))
	current_resolution_size = entry.get("size", MIN_SUPPORTED_RESOLUTION)
	display_notice = ""
	if DisplayServer.window_can_draw():
		var available_size := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).size
		if available_size.x < MIN_SUPPORTED_RESOLUTION.x or available_size.y < MIN_SUPPORTED_RESOLUTION.y:
			display_notice = "当前显示区域低于最低支持 1280x720，已使用最低档。"


func _field_name_for_legacy_key(key: StringName) -> String:
	match String(key):
		"window_mode", "display.window_mode":
			return KEY_WINDOW_MODE
		"resolution_id", "display.resolution_id":
			return KEY_RESOLUTION_ID
		"vsync_mode", "display.vsync_mode":
			return KEY_VSYNC_MODE
		"frame_limit", "display.frame_limit":
			return KEY_FRAME_LIMIT
		"reduce_motion", "accessibility.reduce_motion":
			return KEY_REDUCE_MOTION
	return ""
