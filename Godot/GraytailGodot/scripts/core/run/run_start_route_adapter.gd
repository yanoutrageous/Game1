extends RefCounted
class_name RunStartRouteAdapter

const RunStartConfigScript := preload("res://scripts/core/run/run_start_config.gd")
const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")


static func payload_from_intent(intent: Dictionary) -> Dictionary:
	var payload := NavigationIntentScript.payload(intent)
	return payload_from_route_payload(payload)


static func payload_from_route_payload(payload: Dictionary) -> Dictionary:
	var normalized := RunStartConfigScript.normalize(payload)
	var result := payload.duplicate(true)
	result["run_start_config"] = normalized
	result["route_mode"] = normalized.get("route_mode", &"standard_run")
	result["uses_existing_route"] = true
	result["unsupported_config_fields"] = normalized.get("unsupported_config_fields", [])
	result["fallback_reason"] = normalized.get("fallback_reason", "")
	result["boundary"] = "existing_run_route_only_no_run_bootstrapper"
	result["read_only"] = true
	result["display_only"] = true
	result["preview"] = true
	return result


static func payload_from_deploy_preview(run_start_config_preview: Dictionary, source_payload: Dictionary = {}) -> Dictionary:
	var payload := source_payload.duplicate(true)
	payload["source_page"] = &"deploy_prep"
	payload["run_start_config_preview"] = run_start_config_preview.duplicate(true)
	payload["route_mode"] = source_payload.get("route_mode", &"standard_run")
	payload["preview_only"] = false
	return payload_from_route_payload(payload)


static func route_command_from_payload(payload: Dictionary) -> StringName:
	var normalized := RunStartConfigScript.normalize(payload)
	match StringName(normalized.get("route_mode", &"standard_run")):
		&"tutorial_run":
			return &"start_tutorial_run"
		&"demo_run":
			return &"start_demo_run"
		_:
			return &"start_standard_run"


static func route_status(payload: Dictionary) -> Dictionary:
	var normalized := RunStartConfigScript.normalize(payload)
	return {
		"ok": true,
		"route_mode": normalized.get("route_mode", &"standard_run"),
		"command": route_command_from_payload(payload),
		"uses_existing_route": true,
		"unsupported_config_fields": normalized.get("unsupported_config_fields", []),
		"fallback_reason": normalized.get("fallback_reason", ""),
		"read_only": true,
		"display_only": true,
		"preview": true,
	}
