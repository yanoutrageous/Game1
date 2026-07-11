extends SceneTree

const RESULT_MARKER := "I0_ENVIRONMENT_PROBE_JSON="


func _init() -> void:
	var arguments := _parse_user_arguments(OS.get_cmdline_user_args())
	var workspace_root := _normalize_path(String(arguments.get("workspace-root", "")))
	var mirror_root := _normalize_path(String(arguments.get("mirror-root", "")))
	var run_root := _normalize_path(String(arguments.get("run-root", "")))
	var res_root := _normalize_path(ProjectSettings.globalize_path("res://"))
	var user_root := _normalize_path(ProjectSettings.globalize_path("user://"))
	var failures: Array[String] = []

	if workspace_root.is_empty() or mirror_root.is_empty() or run_root.is_empty():
		failures.append("missing required workspace-root, mirror-root, or run-root argument")
	if not _is_within(run_root, workspace_root):
		failures.append("run root is outside workspace root")
	if not _is_within(mirror_root, run_root):
		failures.append("mirror root is outside run root")
	if not _is_within(res_root, mirror_root):
		failures.append("res:// is outside the isolated mirror")
	if not _is_within(res_root, run_root):
		failures.append("res:// is outside the I0 run root")
	if not _is_within(user_root, run_root):
		failures.append("user:// is outside the I0 run root")

	var write_probe_path := "user://i0_environment_probe_write.json"
	var write_probe_global_path := _normalize_path(ProjectSettings.globalize_path(write_probe_path))
	if not _is_within(write_probe_global_path, run_root):
		failures.append("user:// write probe path is outside the I0 run root")
	else:
		var output := FileAccess.open(write_probe_path, FileAccess.WRITE)
		if output == null:
			failures.append("user:// write probe could not be opened: %s" % FileAccess.get_open_error())
		else:
			output.store_string(JSON.stringify({
				"suite": "I0.2",
				"res_root": res_root,
				"user_root": user_root,
			}))
			output.close()

	var result := {
		"status": "PASS" if failures.is_empty() else "FAIL",
		"engine_version": Engine.get_version_info(),
		"workspace_root": workspace_root,
		"run_root": run_root,
		"mirror_root": mirror_root,
		"res_root": res_root,
		"user_root": user_root,
		"write_probe_global_path": write_probe_global_path,
		"failures": failures,
	}
	print(RESULT_MARKER + JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)


func _parse_user_arguments(raw_arguments: PackedStringArray) -> Dictionary:
	var result: Dictionary = {}
	var index := 0
	while index < raw_arguments.size():
		var argument := String(raw_arguments[index])
		if argument.begins_with("--") and index + 1 < raw_arguments.size():
			result[argument.trim_prefix("--")] = String(raw_arguments[index + 1])
			index += 2
			continue
		index += 1
	return result


func _normalize_path(path: String) -> String:
	var normalized := path.replace("\\", "/").simplify_path()
	while normalized.length() > 3 and normalized.ends_with("/"):
		normalized = normalized.trim_suffix("/")
	return normalized.to_lower()


func _is_within(path: String, root: String) -> bool:
	if path.is_empty() or root.is_empty():
		return false
	return path == root or path.begins_with(root + "/")
