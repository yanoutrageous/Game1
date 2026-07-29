extends SceneTree

const SCHEMA_VERSION := 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_path := _argument_value(OS.get_cmdline_user_args(), "--output=")
	if output_path.is_empty():
		printerr("I4_DEVICE_PROBE=FAIL:missing --output")
		quit(2)
		return
	var joypads: Array = []
	for device_id in Input.get_connected_joypads():
		var info: Dictionary = {}
		if Input.has_method("get_joy_info"):
			var raw_info: Variant = Input.call("get_joy_info", device_id)
			if raw_info is Dictionary:
				info = (raw_info as Dictionary).duplicate(true)
		joypads.append({
			"device_id": int(device_id),
			"name": Input.get_joy_name(device_id),
			"guid": Input.get_joy_guid(device_id),
			"info": info,
		})
	var report := {
		"schema_version": SCHEMA_VERSION,
		"status": "PASS",
		"engine": Engine.get_version_info(),
		"os": {
			"name": OS.get_name(),
			"distribution": _call_or_default(OS, &"get_distribution_name", ""),
			"version": OS.get_version(),
			"model": OS.get_model_name(),
			"locale": OS.get_locale(),
		},
		"display": {
			"server": DisplayServer.get_name(),
			"window_size": _vector2i_record(DisplayServer.window_get_size()),
			"screen_size": _vector2i_record(DisplayServer.screen_get_size()),
			"screen_scale": DisplayServer.screen_get_scale(),
		},
		"renderer": {
			"method": _call_or_default(RenderingServer, &"get_current_rendering_method", ""),
			"driver": _call_or_default(RenderingServer, &"get_current_rendering_driver_name", ""),
			"adapter_name": _call_or_default(RenderingServer, &"get_video_adapter_name", ""),
			"adapter_vendor": _call_or_default(RenderingServer, &"get_video_adapter_vendor", ""),
			"adapter_type": _call_or_default(RenderingServer, &"get_video_adapter_type", -1),
			"adapter_api_version": _call_or_default(RenderingServer, &"get_video_adapter_api_version", ""),
		},
		"audio": {
			"driver": _call_or_default(AudioServer, &"get_driver_name", ""),
			"output_device": AudioServer.output_device,
		},
		"joypads": joypads,
		"joypad_count": joypads.size(),
	}
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		printerr(
			"I4_DEVICE_PROBE=FAIL:cannot write report error=%s"
			% error_string(FileAccess.get_open_error())
		)
		quit(3)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print(
		"I4_DEVICE_PROBE=PASS display=%s renderer=%s driver=%s joypads=%d audio=%s"
		% [
			report.display.server,
			report.renderer.method,
			report.renderer.driver,
			joypads.size(),
			report.audio.driver,
		]
	)
	quit(0)


func _call_or_default(singleton: Object, method: StringName, fallback: Variant) -> Variant:
	if singleton != null and singleton.has_method(method):
		return singleton.call(method)
	return fallback


func _argument_value(arguments: PackedStringArray, prefix: String) -> String:
	for argument in arguments:
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return ""


func _vector2i_record(value: Vector2i) -> Dictionary:
	return {"x": value.x, "y": value.y}
