extends RefCounted
class_name RunSceneRouteController

const RunStartRouteAdapterScript := preload("res://scripts/core/run/run_start_route_adapter.gd")


static func start_from_intent(intent: Dictionary, command_bus, admission_check: Callable = Callable()) -> Dictionary:
	var payload := RunStartRouteAdapterScript.payload_from_intent(intent)
	return start_from_payload(payload, command_bus, admission_check)


static func start_from_payload(payload: Dictionary, command_bus, admission_check: Callable = Callable()) -> Dictionary:
	if command_bus == null:
		return {
			"ok": false,
			"command_id": &"start_run_route",
			"reason_code": &"command_bus_missing",
			"command_dispatched": false,
			"run_screen_requested": false,
			"player_reset_requested": false,
		}
	if _runtime_has_active_run(command_bus):
		return {
			"ok": false,
			"command_id": &"start_run_route",
			"reason_code": &"active_run_start_already_committed",
			"command_dispatched": false,
			"route_payload": payload.duplicate(true),
			"run_screen_requested": false,
			"player_reset_requested": false,
		}
	var admission_result := _run_admission_check(admission_check)
	if not bool(admission_result.get("ok", false)):
		return {
			"ok": false,
			"command_id": &"start_run_route",
			"reason_code": StringName(admission_result.get("reason_code", &"run_admission_failed")),
			"command_dispatched": false,
			"route_payload": payload.duplicate(true),
			"admission_result": admission_result.duplicate(true),
			"run_screen_requested": false,
			"player_reset_requested": false,
		}
	var command_id := RunStartRouteAdapterScript.route_command_from_payload(payload)
	var result: Dictionary = command_bus.dispatch(command_id, {
		"run_start_config": payload.get("run_start_config", {}),
		"route_payload": payload.duplicate(true),
	})
	var command_ok := bool(result.get("ok", false))
	var runtime_running := command_ok and _runtime_is_running(command_bus)
	var route_reason := &"" if runtime_running else StringName(
		result.get("reason_code", result.get("reason", &"runtime_not_running_after_start"))
	)
	return {
		"ok": runtime_running,
		"command_id": command_id,
		"route_payload": payload.duplicate(true),
		"command_result": result.duplicate(true),
		"admission_result": admission_result.duplicate(true),
		"reason_code": route_reason,
		"command_dispatched": true,
		"run_screen_requested": runtime_running,
		"player_reset_requested": runtime_running,
		"boundary": "existing_run_route_only_no_run_bootstrapper",
	}


static func _run_admission_check(admission_check: Callable) -> Dictionary:
	if admission_check.is_null():
		return {"ok": true, "status": &"no_admission_check"}
	var raw_result: Variant = admission_check.call()
	if not (raw_result is Dictionary):
		return {
			"ok": false,
			"reason_code": &"invalid_run_admission_result",
		}
	var result := (raw_result as Dictionary).duplicate(true)
	if not result.has("ok"):
		result["ok"] = false
		result["reason_code"] = &"invalid_run_admission_result"
	return result


static func _runtime_is_running(command_bus) -> bool:
	if command_bus == null:
		return false
	var context: Variant = command_bus.get("context")
	if context == null:
		return false
	if context is Dictionary:
		return bool(context.get("run_active", false)) and StringName(context.get("phase", &"")) == &"running"
	return bool(context.get("run_active")) and StringName(context.get("phase")) == &"running"


static func _runtime_has_active_run(command_bus) -> bool:
	if command_bus == null:
		return false
	var context: Variant = command_bus.get("context")
	if context == null:
		return false
	if context is Dictionary:
		return bool(context.get("run_active", false))
	return bool(context.get("run_active"))
