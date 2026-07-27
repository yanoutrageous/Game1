extends RefCounted

const CURRENT_SCHEMA_VERSION := 4
const DEFAULT_PATH := "user://settings.cfg"

const KEY_WINDOW_MODE := "window_mode"
const KEY_RESOLUTION_ID := "resolution_id"
const KEY_VSYNC_MODE := "vsync_mode"
const KEY_FRAME_LIMIT := "frame_limit"
const KEY_UI_SCALE_PERCENT := "ui_scale_percent"
const KEY_MASTER_VOLUME := "master_volume"
const KEY_EFFECTS_VOLUME := "effects_volume"
const KEY_HAPTICS_ENABLED := "haptics_enabled"
const KEY_REDUCE_MOTION := "reduce_motion"

const WINDOW_MODES := ["windowed", "borderless", "exclusive"]
const RESOLUTION_IDS := ["auto", "1280x720", "1366x768", "1600x900", "1920x1080", "2560x1440"]
const VSYNC_MODES := ["enabled", "disabled", "adaptive"]
const FRAME_LIMITS := [0, 60, 120, 144]
const UI_SCALE_PERCENT_VALUES := [100, 125, 150]
const MASTER_VOLUME_MIN := 0
const MASTER_VOLUME_MAX := 100
const EFFECTS_VOLUME_MIN := 0
const EFFECTS_VOLUME_MAX := 100

const META_SECTION := "meta"
const DISPLAY_SECTION := "display"
const AUDIO_SECTION := "audio"
const ACCESSIBILITY_SECTION := "accessibility"
const SCHEMA_KEY := "schema_version"

var primary_path: String


func _init(custom_path: String = DEFAULT_PATH) -> void:
	primary_path = custom_path if not custom_path.is_empty() else DEFAULT_PATH


static func default_settings() -> Dictionary:
	return {
		KEY_WINDOW_MODE: "windowed",
		KEY_RESOLUTION_ID: "auto",
		KEY_VSYNC_MODE: "enabled",
		KEY_FRAME_LIMIT: 0,
		KEY_UI_SCALE_PERCENT: 100,
		KEY_MASTER_VOLUME: 80,
		KEY_EFFECTS_VOLUME: 80,
		KEY_HAPTICS_ENABLED: true,
		KEY_REDUCE_MOTION: false,
	}


static func field_names() -> PackedStringArray:
	return PackedStringArray([
		KEY_WINDOW_MODE,
		KEY_RESOLUTION_ID,
		KEY_VSYNC_MODE,
		KEY_FRAME_LIMIT,
		KEY_UI_SCALE_PERCENT,
		KEY_MASTER_VOLUME,
		KEY_EFFECTS_VOLUME,
		KEY_HAPTICS_ENABLED,
		KEY_REDUCE_MOTION,
	])


static func is_known_field(field_name: String) -> bool:
	return field_names().has(field_name)


static func is_valid_field_value(field_name: String, value: Variant) -> bool:
	match field_name:
		KEY_WINDOW_MODE:
			return typeof(value) in [TYPE_STRING, TYPE_STRING_NAME] and WINDOW_MODES.has(String(value))
		KEY_RESOLUTION_ID:
			return typeof(value) in [TYPE_STRING, TYPE_STRING_NAME] and RESOLUTION_IDS.has(String(value))
		KEY_VSYNC_MODE:
			return typeof(value) in [TYPE_STRING, TYPE_STRING_NAME] and VSYNC_MODES.has(String(value))
		KEY_FRAME_LIMIT:
			return typeof(value) == TYPE_INT and FRAME_LIMITS.has(int(value))
		KEY_UI_SCALE_PERCENT:
			return typeof(value) == TYPE_INT and UI_SCALE_PERCENT_VALUES.has(int(value))
		KEY_MASTER_VOLUME:
			return typeof(value) == TYPE_INT and int(value) >= MASTER_VOLUME_MIN and int(value) <= MASTER_VOLUME_MAX
		KEY_EFFECTS_VOLUME:
			return typeof(value) == TYPE_INT and int(value) >= EFFECTS_VOLUME_MIN and int(value) <= EFFECTS_VOLUME_MAX
		KEY_HAPTICS_ENABLED, KEY_REDUCE_MOTION:
			return typeof(value) == TYPE_BOOL
	return false


static func normalize_settings(candidate: Dictionary, fallback: Dictionary = {}) -> Dictionary:
	var safe_fallback := default_settings()
	for field_name in field_names():
		var fallback_value: Variant = fallback.get(field_name, safe_fallback[field_name])
		if is_valid_field_value(field_name, fallback_value):
			safe_fallback[field_name] = _canonical_value(field_name, fallback_value)
	var normalized: Dictionary = {}
	for field_name in field_names():
		var candidate_value: Variant = candidate.get(field_name, safe_fallback[field_name])
		normalized[field_name] = (
			_canonical_value(field_name, candidate_value)
			if is_valid_field_value(field_name, candidate_value)
			else safe_fallback[field_name]
		)
	return normalized


static func _canonical_value(field_name: String, value: Variant) -> Variant:
	match field_name:
		KEY_WINDOW_MODE, KEY_RESOLUTION_ID, KEY_VSYNC_MODE:
			return String(value)
		KEY_FRAME_LIMIT, KEY_UI_SCALE_PERCENT, KEY_MASTER_VOLUME, KEY_EFFECTS_VOLUME:
			return int(value)
		KEY_HAPTICS_ENABLED, KEY_REDUCE_MOTION:
			return bool(value)
	return value


static func settings_are_valid(candidate: Dictionary) -> bool:
	var fields := field_names()
	if candidate.size() != fields.size():
		return false
	for raw_key in candidate.keys():
		if not is_known_field(String(raw_key)):
			return false
	for field_name in fields:
		if not candidate.has(field_name) or not is_valid_field_value(field_name, candidate[field_name]):
			return false
	return true


func backup_path() -> String:
	return primary_path + ".bak"


func temporary_path() -> String:
	return primary_path + ".tmp"


func corrupt_path() -> String:
	return primary_path + ".corrupt"


func load_settings() -> Dictionary:
	var defaults := default_settings()
	var primary_result := _read_file(primary_path)
	if bool(primary_result.get("future_schema", false)):
		return _future_schema_result(primary_result, primary_path, defaults)
	if bool(primary_result.get("ok", false)):
		var primary_schema := int(primary_result.get("schema_version", CURRENT_SCHEMA_VERSION))
		return {
			"ok": true,
			"status": &"migrated" if primary_schema < CURRENT_SCHEMA_VERSION else &"loaded",
			"settings": primary_result["settings"],
			"schema_version": primary_schema,
			"read_only": false,
			"recovery_required": primary_schema < CURRENT_SCHEMA_VERSION,
			"source_path": primary_path,
		}

	var backup_result := _read_file(backup_path())
	if bool(backup_result.get("future_schema", false)):
		return _future_schema_result(backup_result, backup_path(), defaults)
	if bool(backup_result.get("ok", false)):
		return {
			"ok": true,
			"status": &"recovered_from_backup",
			"settings": backup_result["settings"],
			"schema_version": int(backup_result["schema_version"]),
			"read_only": false,
			"recovery_required": true,
			"source_path": backup_path(),
			"error": String(primary_result.get("error", "primary settings unavailable")),
		}

	var primary_missing := StringName(primary_result.get("status", &"")) == &"missing"
	var backup_missing := StringName(backup_result.get("status", &"")) == &"missing"
	return {
		"ok": true,
		"status": &"missing_defaults" if primary_missing and backup_missing else &"recovered_defaults",
		"settings": defaults,
		"schema_version": CURRENT_SCHEMA_VERSION,
		"read_only": false,
		"recovery_required": not primary_missing,
		"source_path": "",
		"error": "" if primary_missing and backup_missing else String(primary_result.get("error", "settings files invalid")),
	}


func save_settings(candidate: Dictionary) -> Dictionary:
	if not settings_are_valid(candidate):
		return _failure(&"invalid_settings", "settings contain unsupported fields or values")
	var normalized := normalize_settings(candidate)

	var future_guard := _find_future_schema()
	if not future_guard.is_empty():
		return {
			"ok": false,
			"status": &"future_schema_protected",
			"read_only": true,
			"error": "settings schema %d is newer than supported schema %d" % [
				int(future_guard.get("schema_version", -1)),
				CURRENT_SCHEMA_VERSION,
			],
			"source_path": String(future_guard.get("source_path", "")),
		}

	var directory_error := _ensure_parent_directory()
	if directory_error != OK:
		return _failure(&"directory_error", error_string(directory_error))
	_remove_file_if_present(temporary_path())

	var staged_config := _encode_config(normalized)
	var save_error := staged_config.save(temporary_path())
	if save_error != OK:
		_remove_file_if_present(temporary_path())
		return _failure(&"temporary_write_failed", error_string(save_error))
	var staged_result := _read_file(temporary_path())
	if not bool(staged_result.get("ok", false)) or staged_result.get("settings", {}) != normalized:
		_remove_file_if_present(temporary_path())
		return _failure(&"temporary_validation_failed", String(staged_result.get("error", "staged settings mismatch")))

	var moved_primary_to := ""
	if FileAccess.file_exists(primary_path):
		var primary_result := _read_file(primary_path)
		if bool(primary_result.get("future_schema", false)):
			_remove_file_if_present(temporary_path())
			return _failure(&"future_schema_protected", "newer primary settings appeared during save", true)
		moved_primary_to = backup_path() if bool(primary_result.get("ok", false)) else corrupt_path()
		_remove_file_if_present(moved_primary_to)
		var rotate_error := _rename_file(primary_path, moved_primary_to)
		if rotate_error != OK:
			_remove_file_if_present(temporary_path())
			return _failure(&"backup_rotation_failed", error_string(rotate_error))

	var promote_error := _rename_file(temporary_path(), primary_path)
	if promote_error != OK:
		if not moved_primary_to.is_empty() and FileAccess.file_exists(moved_primary_to):
			_rename_file(moved_primary_to, primary_path)
		_remove_file_if_present(temporary_path())
		return _failure(&"atomic_promote_failed", error_string(promote_error))
	return {
		"ok": true,
		"status": &"saved",
		"read_only": false,
		"schema_version": CURRENT_SCHEMA_VERSION,
		"settings": normalized,
		"path": primary_path,
	}


func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "status": &"missing", "error": "file does not exist"}
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error != OK:
		return {"ok": false, "status": &"invalid", "error": error_string(load_error)}
	var schema_value: Variant = config.get_value(META_SECTION, SCHEMA_KEY, null)
	if typeof(schema_value) != TYPE_INT:
		return {"ok": false, "status": &"invalid", "error": "schema_version is missing or invalid"}
	var schema_version := int(schema_value)
	if schema_version > CURRENT_SCHEMA_VERSION:
		return {
			"ok": false,
			"status": &"future_schema",
			"future_schema": true,
			"schema_version": schema_version,
		}
	if schema_version <= 0:
		return {"ok": false, "status": &"invalid", "error": "schema_version must be positive"}
	var decoded := {
		KEY_WINDOW_MODE: config.get_value(DISPLAY_SECTION, KEY_WINDOW_MODE, null),
		KEY_RESOLUTION_ID: config.get_value(DISPLAY_SECTION, KEY_RESOLUTION_ID, null),
		KEY_VSYNC_MODE: config.get_value(DISPLAY_SECTION, KEY_VSYNC_MODE, null),
		KEY_FRAME_LIMIT: config.get_value(DISPLAY_SECTION, KEY_FRAME_LIMIT, null),
		KEY_UI_SCALE_PERCENT: (
			_config_value_or_null(config, ACCESSIBILITY_SECTION, KEY_UI_SCALE_PERCENT)
			if schema_version >= 4
			else default_settings()[KEY_UI_SCALE_PERCENT]
		),
		KEY_MASTER_VOLUME: (
			config.get_value(AUDIO_SECTION, KEY_MASTER_VOLUME, null)
			if schema_version >= 2
			else default_settings()[KEY_MASTER_VOLUME]
		),
		KEY_EFFECTS_VOLUME: (
			_config_value_or_null(config, AUDIO_SECTION, KEY_EFFECTS_VOLUME)
			if schema_version >= 3
			else default_settings()[KEY_EFFECTS_VOLUME]
		),
		KEY_HAPTICS_ENABLED: (
			_config_value_or_null(config, ACCESSIBILITY_SECTION, KEY_HAPTICS_ENABLED)
			if schema_version >= 3
			else default_settings()[KEY_HAPTICS_ENABLED]
		),
		KEY_REDUCE_MOTION: config.get_value(ACCESSIBILITY_SECTION, KEY_REDUCE_MOTION, null),
	}
	if not settings_are_valid(decoded):
		return {"ok": false, "status": &"invalid", "error": "settings fields are missing or invalid"}
	return {
		"ok": true,
		"status": &"valid",
		"future_schema": false,
		"schema_version": schema_version,
		"settings": normalize_settings(decoded),
	}


static func _config_value_or_null(config: ConfigFile, section: String, key: String) -> Variant:
	if not config.has_section_key(section, key):
		return null
	return config.get_value(section, key)


func _encode_config(settings: Dictionary) -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value(META_SECTION, SCHEMA_KEY, CURRENT_SCHEMA_VERSION)
	config.set_value(DISPLAY_SECTION, KEY_WINDOW_MODE, String(settings[KEY_WINDOW_MODE]))
	config.set_value(DISPLAY_SECTION, KEY_RESOLUTION_ID, String(settings[KEY_RESOLUTION_ID]))
	config.set_value(DISPLAY_SECTION, KEY_VSYNC_MODE, String(settings[KEY_VSYNC_MODE]))
	config.set_value(DISPLAY_SECTION, KEY_FRAME_LIMIT, int(settings[KEY_FRAME_LIMIT]))
	config.set_value(ACCESSIBILITY_SECTION, KEY_UI_SCALE_PERCENT, int(settings[KEY_UI_SCALE_PERCENT]))
	config.set_value(AUDIO_SECTION, KEY_MASTER_VOLUME, int(settings[KEY_MASTER_VOLUME]))
	config.set_value(AUDIO_SECTION, KEY_EFFECTS_VOLUME, int(settings[KEY_EFFECTS_VOLUME]))
	config.set_value(ACCESSIBILITY_SECTION, KEY_HAPTICS_ENABLED, bool(settings[KEY_HAPTICS_ENABLED]))
	config.set_value(ACCESSIBILITY_SECTION, KEY_REDUCE_MOTION, bool(settings[KEY_REDUCE_MOTION]))
	return config


func _find_future_schema() -> Dictionary:
	for path in [primary_path, backup_path()]:
		var result := _read_file(path)
		if bool(result.get("future_schema", false)):
			result["source_path"] = path
			return result
	return {}


func _future_schema_result(file_result: Dictionary, source_path: String, defaults: Dictionary) -> Dictionary:
	return {
		"ok": false,
		"status": &"future_schema_protected",
		"settings": defaults,
		"schema_version": int(file_result.get("schema_version", -1)),
		"read_only": true,
		"recovery_required": false,
		"source_path": source_path,
		"error": "settings schema is newer than this build",
	}


func _failure(status: StringName, message: String, read_only: bool = false) -> Dictionary:
	return {"ok": false, "status": status, "error": message, "read_only": read_only}


func _ensure_parent_directory() -> Error:
	var base_directory := primary_path.get_base_dir()
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(base_directory)):
		return OK
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_directory))


func _rename_file(from_path: String, to_path: String) -> Error:
	if from_path.get_base_dir() != to_path.get_base_dir():
		return ERR_INVALID_PARAMETER
	var directory := DirAccess.open(from_path.get_base_dir())
	if directory == null:
		return ERR_CANT_OPEN
	return directory.rename(from_path.get_file(), to_path.get_file())


func _remove_file_if_present(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return OK
	var directory := DirAccess.open(path.get_base_dir())
	if directory == null:
		return ERR_CANT_OPEN
	return directory.remove(path.get_file())
