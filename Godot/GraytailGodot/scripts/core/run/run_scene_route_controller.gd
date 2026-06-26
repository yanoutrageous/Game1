extends RefCounted
class_name RunSceneRouteController

const RunStartRouteAdapterScript := preload("res://scripts/core/run/run_start_route_adapter.gd")


static func start_from_intent(intent: Dictionary, command_bus) -> Dictionary:
	var payload := RunStartRouteAdapterScript.payload_from_intent(intent)
	return start_from_payload(payload, command_bus)


static func start_from_payload(payload: Dictionary, command_bus) -> Dictionary:
	if command_bus == null:
		return {
			"ok": false,
			"command_id": &"start_run_route",
			"reason_code": &"command_bus_missing",
			"run_screen_requested": false,
			"player_reset_requested": false,
		}
	var command_id := RunStartRouteAdapterScript.route_command_from_payload(payload)
	var result: Dictionary = command_bus.dispatch(command_id)
	return {
		"ok": bool(result.get("ok", false)),
		"command_id": command_id,
		"route_payload": payload.duplicate(true),
		"command_result": result.duplicate(true),
		"run_screen_requested": true,
		"player_reset_requested": true,
		"boundary": "existing_run_route_only_no_run_bootstrapper",
	}
