extends SceneTree

const BACKGROUND_ASSET_ID := &"ui.main_menu.background.no_text"
const BUILDER_PATH := "res://../../tools/art21_build_main_menu_runtime.py"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var contract := load("res://scripts/presentation/art21_main_menu_asset_contract.gd")
	var placement := load("res://scripts/presentation/art21_ui_placement_contract.gd")
	_require(contract != null, "ART21 main-menu asset contract did not load")
	_require(placement != null, "ART21 UI placement contract did not load")
	if contract == null or placement == null:
		_finish()
		return

	var registered_cases := {
		&"character": {
			"visual_key": &"main_menu.scene.character.idle.00",
			"asset_id": &"ui.art21.main_menu.scene.character.idle.00",
		},
		&"flag": {
			"visual_key": &"main_menu.scene.fx.dungeon_flag.00",
			"asset_id": &"ui.art21.main_menu.scene.fx.dungeon_flag.00",
		},
		&"transition": {
			"visual_key": &"main_menu.scene.transition.cave.00",
			"asset_id": &"ui.art21.main_menu.scene.transition.cave.00",
		},
	}
	for case_name in registered_cases:
		var case_data := registered_cases[case_name] as Dictionary
		_check_registered_exact(contract, placement, case_name, case_data)

	var missing_cases := {
		&"character": &"main_menu.scene.character.idle.99",
		&"flag": &"main_menu.scene.fx.dungeon_flag.99",
		&"transition": &"main_menu.scene.transition.cave.99",
		&"unknown": &"main_menu.scene.unknown.not_registered",
	}
	for case_name in missing_cases:
		_check_missing_exact(contract, placement, case_name, missing_cases[case_name])
	_check_builder_recipe()

	_finish()


func _check_registered_exact(contract: Script, placement: Script, case_name: StringName, case_data: Dictionary) -> void:
	var visual_key := StringName(case_data.get("visual_key", &""))
	var expected_asset_id := StringName(case_data.get("asset_id", &""))
	var ref: Dictionary = contract.component_ref(visual_key)
	var placement_ref: Dictionary = placement.main_menu_scene_ref(visual_key)
	var texture := contract.texture(visual_key) as Texture2D
	var placement_texture := placement.main_menu_scene_texture(visual_key) as Texture2D
	var content_db := root.get_node_or_null("ContentDB")
	var manifest_texture: Texture2D = null
	if content_db != null:
		manifest_texture = content_db.call("get_asset_ref", expected_asset_id) as Texture2D

	_require(StringName(ref.get("asset_id", &"")) == expected_asset_id, "%s registered key changed asset id" % String(case_name))
	_require(StringName(ref.get("fallback_asset_id", &"")) == &"", "%s registered key still carries a screen-background fallback" % String(case_name))
	_require(placement_ref == ref, "%s placement wrapper changed the exact component ref" % String(case_name))
	_require(manifest_texture != null, "%s registered manifest texture did not resolve" % String(case_name))
	_require(texture == manifest_texture, "%s registered key did not return its original manifest texture" % String(case_name))
	_require(placement_texture == manifest_texture, "%s placement wrapper did not return the original manifest texture" % String(case_name))


func _check_missing_exact(contract: Script, placement: Script, case_name: StringName, visual_key: StringName) -> void:
	var ref: Dictionary = contract.component_ref(visual_key)
	var placement_ref: Dictionary = placement.main_menu_scene_ref(visual_key)
	_require(StringName(ref.get("asset_id", &"")) == &"", "%s missing key unexpectedly resolved an asset" % String(case_name))
	_require(StringName(ref.get("fallback_asset_id", &"")) == &"", "%s missing key carries a fallback asset" % String(case_name))
	_require(StringName(ref.get("fallback_asset_id", &"")) != BACKGROUND_ASSET_ID, "%s missing key can still fall back to the full-screen background" % String(case_name))
	_require(placement_ref == ref, "%s placement wrapper changed the missing exact ref" % String(case_name))
	_require(contract.texture(visual_key) == null, "%s missing key did not return null texture" % String(case_name))
	_require(placement.main_menu_scene_texture(visual_key) == null, "%s placement wrapper did not return null texture" % String(case_name))
	_require(StringName(contract.load_group(visual_key)) == &"", "%s missing key unexpectedly resolved a load group" % String(case_name))


func _check_builder_recipe() -> void:
	var global_path := ProjectSettings.globalize_path(BUILDER_PATH)
	_require(FileAccess.file_exists(global_path), "ART21 runtime builder source is missing")
	if not FileAccess.file_exists(global_path):
		return
	var builder_source := FileAccess.get_file_as_string(global_path)
	_require(builder_source.contains("'\\t\\t&\"\",'"), "ART21 builder does not generate an exact null fallback")
	_require(
		not builder_source.contains("'\\t\\t&\"ui.main_menu.background.no_text\",'"),
		"ART21 builder can regenerate the retired full-screen background fallback"
	)


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("I2_MAIN_MENU_TRANSITION_FALLBACK=PASS registered=3 missing_character=null missing_flag=null missing_transition=null unknown=null builder_fallback=null")
		quit(0)
		return
	for failure in failures:
		push_error("I2 main-menu fallback failure: " + failure)
	print("I2_MAIN_MENU_TRANSITION_FALLBACK=FAIL count=%d" % failures.size())
	quit(1)
