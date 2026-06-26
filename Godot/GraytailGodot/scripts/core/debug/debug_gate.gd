extends RefCounted
class_name DebugGate

const ENABLE_SETTING := "application/run/m1_debug_tools_enabled"
const DEBUG_DISABLED_REASON := "debug_tools_disabled"
const DEBUG_SOURCES := ["debug", "debug_panel", "m1_debug_panel"]


static func is_debug_tools_enabled() -> bool:
	if not OS.is_debug_build():
		return false
	if OS.has_feature("editor"):
		return true
	return bool(ProjectSettings.get_setting(ENABLE_SETTING, false))


static func is_debug_command(command_name: StringName, payload: Dictionary = {}) -> bool:
	var source := String(payload.get("source", ""))
	return String(command_name).begins_with("debug_") or source in DEBUG_SOURCES


static func disabled_result(actor_id: StringName = &"player") -> Dictionary:
	return {
		"ok": false,
		"status": &"debug_tools_disabled",
		"reason": DEBUG_DISABLED_REASON,
		"blocked_reason": DEBUG_DISABLED_REASON,
		"reason_code": DEBUG_DISABLED_REASON,
		"message_key": "command.rejected.debug_tools_disabled",
		"actor_id": actor_id,
	}
