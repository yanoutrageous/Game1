extends SceneTree

const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const SaveAdapterScript := preload("res://scripts/core/save/save_adapter.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const M7ProgressionServiceScript := preload("res://scripts/core/progression/m7_progression_service.gd")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var width := int(options.get("width", 1280))
	var height := int(options.get("height", 720))
	var state := StringName(options.get("state", "deploy_map"))
	var output := String(options.get("output", "res://artifacts/m7/m7_meta_visibility.png"))

	root.size = Vector2i(width, height)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.transparent_bg = false
	var design_root := Control.new()
	design_root.name = "M7MetaVisibilityCanvas"
	design_root.size = Vector2(1280, 720)
	design_root.scale = Vector2(float(width) / 1280.0, float(height) / 720.0)
	root.add_child(design_root)

	var app_shell_script := load("res://scripts/ui/app_shell/app_shell.gd")
	if app_shell_script == null:
		push_error("M7_META_VISIBILITY:app_shell_load_failed")
		quit(2)
		return
	var app_shell := app_shell_script.new() as Control
	app_shell.name = "M7MetaVisibilityAppShell"
	app_shell.size = Vector2(1280, 720)
	design_root.add_child(app_shell)
	app_shell.call("build")
	app_shell.call("apply_snapshot", {"meta_progress_summary": _representative_summary()})
	await _frames(18)

	match state:
		&"deploy_map":
			app_shell.call("show_deploy", &"map")
			var deploy := app_shell.call("get_deploy_page") as Control
			deploy.call("_on_card_pressed", &"m7_map_classic_13x13_normal")
			await _frames(5)
			var scroll := deploy.get("card_scroll") as ScrollContainer
			if scroll != null:
				scroll.scroll_vertical = 560
		&"goals":
			app_shell.call("show_long_term", &"goals")
			var goals := app_shell.call("get_long_term_page") as Control
			goals.call("_apply_module_immediately", &"goals")
			goals.call("show_secondary", &"task")
		&"research":
			app_shell.call("show_long_term", &"research")
			var research := app_shell.call("get_long_term_page") as Control
			research.call("_apply_module_immediately", &"research")
			research.call("show_secondary", &"research_entry")
		&"collection":
			app_shell.call("show_long_term", &"collection_appearance")
			var collection := app_shell.call("get_long_term_page") as Control
			collection.call("_apply_module_immediately", &"collection_appearance")
			collection.call("show_secondary", &"unique_display")
		_:
			push_error("M7_META_VISIBILITY:unknown_state:%s" % String(state))
			quit(2)
			return
	await _frames(16)

	var image := root.get_texture().get_image()
	if image == null:
		push_error("M7_META_VISIBILITY:renderer_returned_no_image")
		quit(2)
		return
	var output_path := output if output.is_absolute_path() else ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var result := image.save_png(output_path)
	if result != OK:
		push_error("M7_META_VISIBILITY:capture_failed:%s" % error_string(result))
		quit(2)
		return
	print("M7_META_VISIBILITY:PASS state=%s size=%dx%d output=%s" % [String(state), image.get_width(), image.get_height(), output_path])
	quit(0)


func _representative_summary() -> Dictionary:
	var save_adapter := SaveAdapterScript.new()
	var data := M7ProgressionServiceScript.normalize_meta(save_adapter.default_meta_progress())
	data["gold"] = 500
	data["profile_exp"] = 475
	data["unlocked_map_ids"] = []
	for definition in M7ContentCatalogScript.map_definitions():
		(data["unlocked_map_ids"] as Array).append(str(definition.get("id", "")))

	var task_definitions := M7ContentCatalogScript.task_definitions()
	if not task_definitions.is_empty():
		var task_id := str(task_definitions[0].get("id", ""))
		(data["task_states"] as Dictionary)[task_id] = {
			"status": "claimable", "progress": 1, "achieved": true,
			"claimed": false, "newly_claimable_result_id": "m7_visual_result",
		}
	var achievements := M7ContentCatalogScript.achievement_definitions()
	if not achievements.is_empty():
		var achievement_id := str(achievements[0].get("id", ""))
		(data["achievement_states"] as Dictionary)[achievement_id] = {
			"status": "claimable", "progress": 1, "achieved": true,
			"claimed": false, "newly_claimable_result_id": "m7_visual_result",
		}

	var research_definitions := M7ContentCatalogScript.research_definitions()
	if not research_definitions.is_empty():
		M7ProgressionServiceScript.add_item_instance(data, str(research_definitions[0].get("material_item_id", "")), "m7_visual_research")

	var collection_sets := M7ContentCatalogScript.collection_sets()
	if not collection_sets.is_empty():
		var first_set: Dictionary = collection_sets[0]
		for item_id in first_set.get("item_ids", []):
			(data["collection_discoveries"] as Array).append(str(item_id))
		(data["completed_collection_set_ids"] as Array).append(str(first_set.get("id", "")))
		(data["unread_collection_set_ids"] as Array).append(str(first_set.get("id", "")))

	data["commission_history"] = [{
		"result_id": "m7_visual_result",
		"map_id": "classic_13x13_normal",
		"commission_id": "commission_route_survey",
		"completed": true,
		"outcome": "Extracted",
	}]
	data = M7ProgressionServiceScript.normalize_meta(data)
	var adapter := MetaProgressAdapterScript.new()
	adapter.data = data
	return adapter.get_summary()


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var result := {}
	for argument in arguments:
		var token := String(argument)
		if not token.begins_with("--") or not token.contains("="):
			continue
		var separator := token.find("=")
		result[token.substr(2, separator - 2)] = token.substr(separator + 1)
	return result
