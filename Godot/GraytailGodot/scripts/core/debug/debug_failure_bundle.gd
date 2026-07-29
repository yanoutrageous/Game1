extends RefCounted
class_name DebugFailureBundle

const BUNDLE_SCHEMA := &"i4_debug_failure_bundle_v1"
const DEFAULT_ROOT := "user://debug_failure_bundles"


static func capture(
	viewport: Viewport,
	session_snapshot: Dictionary,
	run_snapshot: Dictionary,
	last_command: Dictionary,
	ui_snapshot: Dictionary,
	input_index: int,
	output_root: String = DEFAULT_ROOT
) -> Dictionary:
	var scenario_id := str(session_snapshot.get("scenario_id", "unknown"))
	var seed := int(session_snapshot.get("seed", 0))
	var stamp := Time.get_datetime_string_from_system(true, true).replace(":", "").replace("-", "")
	var bundle_id := "%s_%s_%d_%s" % [stamp, scenario_id, seed, input_index]
	var root_path := output_root.path_join(bundle_id)
	var absolute_root := ProjectSettings.globalize_path(root_path)
	var mkdir_error := DirAccess.make_dir_recursive_absolute(absolute_root)
	if mkdir_error != OK:
		return {
			"ok": false,
			"status": &"bundle_directory_failed",
			"error": error_string(mkdir_error),
			"path": root_path,
		}

	var screenshot_path := root_path.path_join("screenshot.png")
	var screenshot_status := &"unavailable"
	if viewport != null:
		var image := viewport.get_texture().get_image()
		if image != null and not image.is_empty():
			var screenshot_error := image.save_png(ProjectSettings.globalize_path(screenshot_path))
			screenshot_status = &"saved" if screenshot_error == OK else &"save_failed"

	var commit_id := _commit_id()
	var focus_path := ""
	if viewport != null:
		var focus_owner := viewport.gui_get_focus_owner()
		if focus_owner != null:
			focus_path = str(focus_owner.get_path())
	var bundle := {
		"schema": BUNDLE_SCHEMA,
		"bundle_id": bundle_id,
		"created_utc": Time.get_datetime_string_from_system(true, true),
		"commit": commit_id,
		"scenario_id": scenario_id,
		"seed": seed,
		"profile_id": str(session_snapshot.get("profile_id", "")),
		"save_target": str(session_snapshot.get("save_target", "")),
		"tainted": bool(session_snapshot.get("tainted", false)),
		"input_index": input_index,
		"focus_path": focus_path,
		"modal_stack": _array_copy(ui_snapshot.get("modal_stack", [])),
		"save_before": str(session_snapshot.get("production_hash_before", "")),
		"save_after": str(session_snapshot.get("production_hash_after", "")),
		"last_command": last_command.duplicate(true),
		"event_log": _array_copy(run_snapshot.get("event_log", [])),
		"transaction_log": _array_copy(run_snapshot.get("transaction_log", [])),
		"debug_commands": _array_copy(run_snapshot.get("debug_commands", [])),
		"ui_snapshot": ui_snapshot.duplicate(true),
		"screenshot": screenshot_path,
		"screenshot_status": screenshot_status,
		"reproduce": (
			"godot --headless --path <project> -s res://tests/i4_reproduction_runner.gd "
			+ "-- --scenario=%s --seed=%d --input-index=%d" % [scenario_id, seed, input_index]
		),
	}
	var json_path := root_path.path_join("bundle.json")
	var file := FileAccess.open(json_path, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"status": &"bundle_json_open_failed",
			"error": FileAccess.get_open_error(),
			"path": json_path,
		}
	file.store_string(JSON.stringify(bundle, "\t", false))
	file.close()
	return {
		"ok": true,
		"status": &"bundle_captured",
		"bundle": bundle,
		"bundle_path": root_path,
		"json_path": json_path,
		"screenshot_path": screenshot_path,
	}


static func validate(bundle: Dictionary) -> Dictionary:
	var required := [
		"commit", "scenario_id", "seed", "input_index", "focus_path",
		"modal_stack", "save_before", "save_after", "event_log",
		"transaction_log", "screenshot", "reproduce",
	]
	var missing: Array[String] = []
	for key in required:
		if not bundle.has(key):
			missing.append(key)
	return {
		"ok": missing.is_empty(),
		"missing_fields": missing,
		"schema": bundle.get("schema", &""),
	}


static func _commit_id() -> String:
	var configured := OS.get_environment("I4_EVIDENCE_COMMIT").strip_edges()
	if not configured.is_empty():
		return configured
	var output: Array = []
	var exit_code := OS.execute("git", ["rev-parse", "HEAD"], output, true, false)
	if exit_code == 0 and not output.is_empty():
		return str(output[0]).strip_edges()
	return "UNKNOWN_WORKTREE_HEAD"


static func _array_copy(value: Variant) -> Array:
	return (value as Array).duplicate(true) if value is Array else []
