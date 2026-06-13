extends Node

# TruthMap = 真实地图
# IntelMap = 玩家已知情报
# MiniMapViewModel = UI 可读数据
# UI 不得直接读取 TruthMap

var values: Dictionary = {}
var current_resolution_id: StringName = &"1280x720"
var current_resolution_size: Vector2i = Vector2i(1280, 720)
var current_resolution_source: StringName = &"auto"
var display_notice: String = ""

const DISPLAY_RESOLUTION_KEY := &"display.resolution_id"
const DISPLAY_RESOLUTION_SOURCE_KEY := &"display.resolution_source"
const MIN_SUPPORTED_RESOLUTION := Vector2i(1280, 720)
const SUPPORTED_RESOLUTIONS := [
	{"id": &"1280x720", "label": "1280x720", "size": Vector2i(1280, 720)},
	{"id": &"1366x768", "label": "1366x768", "size": Vector2i(1366, 768)},
	{"id": &"1600x900", "label": "1600x900", "size": Vector2i(1600, 900)},
	{"id": &"1920x1080", "label": "1920x1080", "size": Vector2i(1920, 1080)},
	{"id": &"2560x1440", "label": "2560x1440", "size": Vector2i(2560, 1440)},
]


func _ready() -> void:
	apply_startup_display_settings()
	print_verbose("SettingsManager ready")


func get_value(key: StringName, default_value: Variant = null) -> Variant:
	return values.get(key, default_value)


func set_value(key: StringName, value: Variant) -> void:
	values[key] = value


func reset_to_defaults() -> void:
	values.clear()
	apply_auto_recommended_resolution()


func apply_startup_display_settings() -> void:
	_lock_window_resize()
	var stored_resolution_id := StringName(values.get(DISPLAY_RESOLUTION_KEY, &""))
	if is_supported_resolution_id(stored_resolution_id):
		apply_resolution_id(stored_resolution_id, &"manual")
	else:
		apply_auto_recommended_resolution()


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
	var notice_suffix := "" if display_notice == "" else "\n" + display_notice
	return "当前分辨率：%s（%s）\n仅支持固定 16:9 档位；窗口不可拖拽自由缩放。%s" % [
		String(current_resolution_id),
		source_label,
		notice_suffix,
	]


func apply_resolution_id(resolution_id: StringName, source: StringName = &"manual") -> bool:
	var entry := _entry_for_id(resolution_id)
	if entry.is_empty():
		return false
	_apply_resolution_entry(entry, source)
	return true


func apply_auto_recommended_resolution() -> void:
	var entry := recommended_resolution_for_current_screen()
	_apply_resolution_entry(entry, &"auto")


func reset_display_resolution_to_auto() -> void:
	values.erase(DISPLAY_RESOLUTION_KEY)
	values.erase(DISPLAY_RESOLUTION_SOURCE_KEY)
	apply_auto_recommended_resolution()


func recommended_resolution_for_current_screen() -> Dictionary:
	var available_size := MIN_SUPPORTED_RESOLUTION
	if DisplayServer.window_can_draw():
		var screen := DisplayServer.window_get_current_screen()
		var usable_rect := DisplayServer.screen_get_usable_rect(screen)
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


func _entry_for_id(resolution_id: StringName) -> Dictionary:
	for entry in SUPPORTED_RESOLUTIONS:
		if StringName(entry.get("id", &"")) == resolution_id:
			return entry
	return {}


func _apply_resolution_entry(entry: Dictionary, source: StringName) -> void:
	current_resolution_id = StringName(entry.get("id", &"1280x720"))
	current_resolution_size = entry.get("size", MIN_SUPPORTED_RESOLUTION)
	current_resolution_source = source
	values[DISPLAY_RESOLUTION_SOURCE_KEY] = source
	if source == &"manual":
		values[DISPLAY_RESOLUTION_KEY] = current_resolution_id
	var recommended: Dictionary = recommended_resolution_for_current_screen()
	display_notice = ""
	if StringName(recommended.get("id", &"")) == &"1280x720":
		var available_size := MIN_SUPPORTED_RESOLUTION
		if DisplayServer.window_can_draw():
			available_size = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).size
		if available_size.x < MIN_SUPPORTED_RESOLUTION.x or available_size.y < MIN_SUPPORTED_RESOLUTION.y:
			display_notice = "当前显示区域低于最低支持 1280x720，已使用最低档。"
	_lock_window_resize()
	if DisplayServer.window_can_draw():
		DisplayServer.window_set_min_size(MIN_SUPPORTED_RESOLUTION)
		DisplayServer.window_set_max_size(_largest_supported_resolution_size())
		DisplayServer.window_set_size(current_resolution_size)
		DisplayServer.window_set_min_size(current_resolution_size)
		DisplayServer.window_set_max_size(current_resolution_size)
		_center_window_in_current_screen()


func _lock_window_resize() -> void:
	if DisplayServer.window_can_draw():
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, true)


func _largest_supported_resolution_size() -> Vector2i:
	var entry: Dictionary = SUPPORTED_RESOLUTIONS[SUPPORTED_RESOLUTIONS.size() - 1]
	return entry.get("size", MIN_SUPPORTED_RESOLUTION)


func _center_window_in_current_screen() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	if usable_rect.size.x <= 0 or usable_rect.size.y <= 0:
		return
	var centered_offset := Vector2i(
		max(0, int((usable_rect.size.x - current_resolution_size.x) / 2)),
		max(0, int((usable_rect.size.y - current_resolution_size.y) / 2))
	)
	var centered_position := usable_rect.position + centered_offset
	DisplayServer.window_set_position(centered_position)
