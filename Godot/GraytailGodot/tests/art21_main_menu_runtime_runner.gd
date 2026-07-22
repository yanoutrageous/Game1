extends SceneTree

const CharacterPresentationCatalogScript := preload("res://scripts/presentation/character/character_presentation_catalog.gd")
const MainMenuLayoutContractScript := preload("res://scripts/ui/main_menu/main_menu_layout_contract.gd")
const DESCEND_CHECKPOINT_MIN_OFFSET := 48.0

var failures: Array[String] = []
var host_route_count := 0
var page_change_count := 0
var last_changed_page: StringName = &""


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var canvas := Control.new()
	canvas.name = "Art21RuntimeCanvas"
	canvas.position = Vector2.ZERO
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)

	var app_shell_script := load("res://scripts/ui/app_shell/app_shell.gd")
	_check(app_shell_script != null, "AppShell could not be loaded")
	if app_shell_script == null:
		_finish()
		return
	var shell := app_shell_script.new() as Control
	shell.name = "Art21RuntimeAppShell"
	canvas.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.connect("host_route_requested", _on_host_route_requested)
	shell.connect("page_changed", _on_page_changed)
	shell.call("build")
	for _index in range(8):
		await process_frame

	var main := shell.call("get_main_page") as Control
	_check(main != null, "Main menu page was not built")
	if main == null:
		_finish()
		return
	_check(main.size == Vector2(1280, 720), "Main menu does not fill the 1280x720 design canvas")
	for root_name in [
		"BackgroundRoot", "DecorationRoot", "CharacterRoot", "MainContentRoot",
		"SideStatusRoot", "PrimaryActionRoot", "FloatingInfoRoot", "OverlayRoot", "ModalRoot"
	]:
		_check(main.get_node_or_null(root_name) != null, "Missing UI layer root: " + root_name)

	var entry_ids := [&"deploy", &"long_term", &"settings", &"exit_game"]
	for entry_id in entry_ids:
		var prefix := "PrimaryActionRoot/"
		_check(main.get_node_or_null(prefix + "MainMenuEntry_" + String(entry_id)) is Button, "Missing entry button: " + String(entry_id))
		_check(main.get_node_or_null(prefix + "MainMenuBoard_" + String(entry_id)) is TextureRect, "Clean-plate menu board is missing: " + String(entry_id))
		_check(main.get_node_or_null(prefix + "MainMenuBoardLabel_" + String(entry_id)) is Label, "Engine-rendered menu label is missing: " + String(entry_id))

	_check(main.get_node_or_null("BackgroundRoot/MainMenuSceneCleanPlate") is TextureRect, "Master-matched clean plate is absent")
	_check(main.get_node_or_null("BackgroundRoot/MainMenuIntegratedSceneMaster") == null, "Text-baked integrated master is still mounted")
	_check(main.get_node_or_null("DecorationRoot/MainMenuDungeonArchitecture") == null, "Split dungeon is stacked over the integrated scene")
	_check(main.get_node_or_null("DecorationRoot/MainMenuCompanyArchitecture") == null, "Split company is stacked over the integrated scene")
	_check(main.get_node_or_null("CharacterRoot/MainMenuCharacter") is TextureRect, "Layered character is missing from the clean plate")
	_check(main.get_node_or_null("SideStatusRoot/MainMenuNoticeFrame") == null, "Split notice board is stacked over the integrated scene")
	_check(main.get_node_or_null("PrimaryActionRoot/MainMenuSignpostStructure") == null, "Split signpost is stacked over the integrated scene")
	_check(main.get_node_or_null("MainContentRoot/MainMenuTitle") is Label, "Engine-rendered brand title is missing")
	_check(main.get_node_or_null("SideStatusRoot/MainMenuNoticeTitle") is Label, "Engine-rendered notice title is missing")
	_check(main.get_node_or_null("SideStatusRoot/MainMenuNoticeText") is Label, "Engine-rendered notice text is missing")
	_check(main.get_node_or_null("MainContentRoot/MainMenuActionDeck") == null, "Legacy action deck is still mounted")
	_check_texture_size(main, "BackgroundRoot/MainMenuSceneCleanPlate", Vector2(1280, 720))
	_check(main.get_node_or_null("OverlayRoot/MainMenuSceneTransition") is ColorRect, "Prototype transition texture still creates a pasted rectangular mask")

	var ambient_groups := main.get("animated_groups") as Array
	_check(ambient_groups.size() == 10, "Clean-plate scene should mount seven persistent and three ambient motion groups")
	var ambient_names: Array[String] = []
	var ambient_cadences: Array[float] = []
	for raw_group in ambient_groups:
		if not (raw_group is Dictionary):
			continue
		var group := raw_group as Dictionary
		ambient_names.append(String(group.get("name", "")))
		ambient_cadences.append(float(group.get("frame_seconds", 0.0)))
	_check(ambient_names.has("MainMenuChimneySmoke"), "Smoke motion group is missing")
	_check(ambient_names.has("MainMenuBirds"), "Bird motion group is missing")
	_check(ambient_names.has("MainMenuFallingLeaves"), "Leaf motion group is missing")
	_check(ambient_names.has("MainMenuDungeonFlag"), "Dungeon flag loop is missing")
	_check(ambient_names.has("MainMenuCompanyBanner"), "Company banner loop is missing")
	_check(ambient_names.has("MainMenuCompanySideBannerLeft"), "Left company side-banner loop is missing")
	_check(ambient_names.has("MainMenuCompanySideBannerRight"), "Right company side-banner loop is missing")
	for flame_index in range(3):
		_check(ambient_names.has("MainMenuLanternFlame%d" % flame_index), "Lantern flame loop is missing: %d" % flame_index)
	_check(not ambient_names.has("MainMenuPuddleShimmer"), "Puddle patch should remain prototype-only until a clean plate exists")
	ambient_cadences.sort()
	var unique_cadence_count := 0
	var last_cadence := -1.0
	for cadence in ambient_cadences:
		if not is_equal_approx(cadence, last_cadence):
			unique_cadence_count += 1
			last_cadence = cadence
	_check(unique_cadence_count >= 3, "Ambient groups still share a synchronized cadence")
	var birds_group := _find_motion_group(ambient_groups, "MainMenuBirds")
	var leaves_group := _find_motion_group(ambient_groups, "MainMenuFallingLeaves")
	_check(StringName(birds_group.get("kind", &"")) == &"event_travel", "Birds should be an occasional travelling event")
	_check(float(birds_group.get("cooldown_seconds", 0.0)) >= 8.0, "Bird event repeats too frequently")
	_check(StringName(leaves_group.get("kind", &"")) == &"event", "Leaves should be an occasional event")
	_check(float(leaves_group.get("cooldown_seconds", 0.0)) >= 4.0, "Leaf event repeats too frequently")

	main.call("_set_focus_state", &"deploy")
	await process_frame
	var cave_focus := main.get_node_or_null("FloatingInfoRoot/MainMenuCaveFocusGlow") as TextureRect
	var company_focus := main.get_node_or_null("FloatingInfoRoot/MainMenuCompanyFocusGlow") as TextureRect
	var utility_focus := main.get_node_or_null("FloatingInfoRoot/MainMenuUtilityFocusOutline") as Panel
	var character := main.get_node_or_null("CharacterRoot/MainMenuCharacter") as TextureRect
	_check(cave_focus != null and cave_focus.visible, "Deploy focus does not activate the cave")
	_check(company_focus != null and not company_focus.visible, "Company focus response should be mounted but inactive for deploy")
	_check(character != null and character.flip_h, "Deploy focus does not turn the character toward the dungeon")
	main.call("_set_focus_state", &"long_term")
	await process_frame
	_check(cave_focus != null and not cave_focus.visible, "Long-term focus leaves the cave active")
	_check(company_focus != null and company_focus.visible, "Long-term focus does not activate the company")
	_check(character != null and not character.flip_h, "Long-term focus leaves the character facing the dungeon")
	_check(utility_focus != null and utility_focus.visible, "Long-term focus does not highlight its board")
	_check(utility_focus != null and utility_focus.get_theme_stylebox("panel") is StyleBoxFlat, "Utility focus still depends on the misaligned hanging-ring texture")
	_check(utility_focus != null and utility_focus.position == Vector2(857, 325), "Utility focus outline is not aligned with the four-pixel focused-board offset")
	_check(utility_focus != null and utility_focus.size == Vector2(257, 104), "Utility focus outline no longer hugs the long-term board")
	var utility_focus_contract := {
		&"settings": Rect2(879, 430, 229, 92),
		&"exit_game": Rect2(889, 524, 219, 83),
	}
	for utility_id in utility_focus_contract:
		main.call("_set_focus_state", utility_id)
		await process_frame
		var expected_focus_rect := utility_focus_contract[utility_id] as Rect2
		_check(utility_focus.position == expected_focus_rect.position, "Utility focus position is misaligned for " + String(utility_id))
		_check(utility_focus.size == expected_focus_rect.size, "Utility focus size is misaligned for " + String(utility_id))

	main.call("_set_focus_state", &"deploy")
	var deploy_button := main.get_node_or_null("PrimaryActionRoot/MainMenuEntry_deploy") as Button
	var walk_descriptor := CharacterPresentationCatalogScript.resolve_descriptor(
		CharacterPresentationCatalogScript.DEFAULT_ACTOR_ID,
		CharacterPresentationCatalogScript.DEFAULT_APPEARANCE_ID,
		&"walk_dungeon"
	)
	_check(not walk_descriptor.is_empty() and not bool(walk_descriptor.get("fallback_used", true)), "walk_dungeon did not resolve to its audited semantic clip")
	_check((walk_descriptor.get("visual_keys", []) as Array).size() == 4, "walk_dungeon does not expose all four audited runtime frames")
	var cancelled_character_position := character.position
	var cancelled_character_scale := character.scale
	var cancelled_character_modulate := character.modulate
	var cancelled_character_pivot := character.pivot_offset
	var cancelled_character_texture := character.texture
	var cancelled_character_flip := character.flip_h
	var page_count_before := page_change_count
	deploy_button.emit_signal("pressed")
	var cancelled_token := int((shell.call("get_navigation_transition_snapshot") as Dictionary).get("active_token", 0))
	main.call("_process", 0.30)
	var cave_inside := MainMenuLayoutContractScript.logical_anchor(&"character_cave_inside")
	_check(character.position != cancelled_character_position, "enter_cave did not move the character")
	_check(character.position.distance_to(cave_inside) < cancelled_character_position.distance_to(cave_inside), "enter_cave moved the character away from the cave interior")
	_check(character.scale.x < cancelled_character_scale.x and character.scale.y < cancelled_character_scale.y, "enter_cave did not scale the character into the cave")
	_check(character.modulate.a < cancelled_character_modulate.a, "enter_cave did not fade the character while crossing the gate")
	_check(character.texture != null and character.texture.resource_path.contains("/walk_dungeon_"), "enter_cave did not consume an audited walk_dungeon runtime frame")
	_check(page_change_count == page_count_before, "enter_cave committed its route before presentation completion")
	var cancel_event := InputEventAction.new()
	cancel_event.action = &"ui_cancel"
	cancel_event.pressed = true
	main.call("_unhandled_input", cancel_event)
	await process_frame
	var cancelled_snapshot: Dictionary = shell.call("get_navigation_transition_snapshot")
	var cancelled_result := cancelled_snapshot.get("last_result", {}) as Dictionary
	_check(cancelled_token > 0 and StringName(cancelled_snapshot.get("state", &"")) == &"idle", "Cancel did not settle the active transition")
	_check(StringName(cancelled_result.get("outcome", &"")) == &"cancelled", "Cancel did not record a cancelled outcome")
	_check(int(cancelled_result.get("commit_count", -1)) == 0, "Cancel committed a route")
	_check(page_change_count == page_count_before and main.visible, "Cancel changed the visible route")
	_check(StringName(main.get("current_focus")) == &"deploy", "Cancel did not restore the source focus")
	_check(character.position == cancelled_character_position, "Cancel did not restore the character position exactly")
	_check(character.scale == cancelled_character_scale, "Cancel did not restore the character scale exactly")
	_check(character.modulate == cancelled_character_modulate, "Cancel did not restore the character alpha/modulate exactly")
	_check(character.pivot_offset == cancelled_character_pivot, "Cancel did not restore the character pivot exactly")
	_check(character.texture == cancelled_character_texture, "Cancel did not restore the character texture exactly")
	_check(character.flip_h == cancelled_character_flip, "Cancel did not restore the character facing exactly")

	var settings_button := main.get_node_or_null("PrimaryActionRoot/MainMenuEntry_settings") as Button
	page_count_before = page_change_count
	settings_button.emit_signal("pressed")
	var transition_snapshot: Dictionary = shell.call("get_navigation_transition_snapshot")
	_check(StringName(transition_snapshot.get("state", &"")) == &"playing", "Settings transition did not enter coordinator PLAYING")
	_check(StringName(transition_snapshot.get("profile_id", &"")) == &"open_overlay", "Settings did not request open_overlay")
	_check(_intent_profile_is_clean(transition_snapshot), "Settings transition profile leaked into NavigationIntent payload")
	main.call("_process", 0.25)
	await process_frame
	var settings_overlay := shell.get_node_or_null("SettingsOverlay") as Control
	_check(settings_overlay != null and settings_overlay.visible, "Settings route did not open the scene overlay")
	_check(main.visible, "Settings route replaced the scene instead of overlaying it")
	_check(page_change_count == page_count_before + 1 and last_changed_page == &"settings_placeholder", "Settings route was not committed exactly once")
	_check_committed_transition(shell, &"settings_placeholder", "Settings")
	shell.call("_close_settings_to_main")
	await process_frame

	var exit_button := main.get_node_or_null("PrimaryActionRoot/MainMenuEntry_exit_game") as Button
	page_count_before = page_change_count
	exit_button.emit_signal("pressed")
	transition_snapshot = shell.call("get_navigation_transition_snapshot")
	_check(StringName(transition_snapshot.get("state", &"")) == &"playing", "Exit transition did not enter coordinator PLAYING")
	_check(StringName(transition_snapshot.get("profile_id", &"")) == &"open_confirm", "Exit did not request open_confirm")
	_check(_intent_profile_is_clean(transition_snapshot), "Exit transition profile leaked into NavigationIntent payload")
	main.call("_process", 0.25)
	await process_frame
	var exit_dialog := shell.get_node_or_null("ExitConfirmDialog") as Control
	_check(exit_dialog != null and exit_dialog.visible, "Exit route did not open the confirmation overlay")
	_check(main.visible, "Exit route replaced the scene instead of overlaying it")
	_check(page_change_count == page_count_before + 1 and last_changed_page == &"exit_confirm", "Exit route was not committed exactly once")
	_check_committed_transition(shell, &"exit_confirm", "Exit")
	shell.call("_hide_exit_confirm")

	shell.call("show_main")
	main.call("_set_focus_state", &"deploy")
	page_count_before = page_change_count
	deploy_button.emit_signal("pressed")
	_check(bool(main.get("transition_active")), "Deploy did not start its scene transition")
	transition_snapshot = shell.call("get_navigation_transition_snapshot")
	_check(StringName(transition_snapshot.get("state", &"")) == &"playing", "Deploy transition did not enter coordinator PLAYING")
	_check(StringName(transition_snapshot.get("profile_id", &"")) == &"enter_cave", "Deploy did not request enter_cave")
	_check(_intent_profile_is_clean(transition_snapshot), "Deploy transition profile leaked into NavigationIntent payload")
	main.call("_process", 0.30)
	_check(bool(main.get("transition_active")), "Deploy transition is too fast to read at the presentation checkpoint")
	var deploy_page := shell.call("get_deploy_page") as Control
	_check(deploy_page != null and not deploy_page.visible, "Deploy route committed before presentation completion")
	main.call("_process", 0.50)
	await process_frame
	_check(deploy_page != null and deploy_page.visible, "Deploy transition did not preserve TARGET_DEPLOY routing")
	_check(page_change_count == page_count_before + 1 and last_changed_page == &"deploy_prep", "Deploy route was not committed exactly once")
	_check_committed_transition(shell, &"deploy_prep", "Deploy")

	shell.call("show_main")
	main.call("_set_focus_state", &"long_term")
	var long_term_button := main.get_node_or_null("PrimaryActionRoot/MainMenuEntry_long_term") as Button
	var descend_roots := ["BackgroundRoot", "DecorationRoot", "CharacterRoot", "MainContentRoot", "SideStatusRoot", "PrimaryActionRoot", "FloatingInfoRoot"]
	var descend_bases: Dictionary = {}
	for root_name in descend_roots:
		descend_bases[root_name] = (main.get_node(root_name) as Control).position
	page_count_before = page_change_count
	long_term_button.emit_signal("pressed")
	_check(bool(main.get("transition_active")), "Long-term did not start its scene transition")
	transition_snapshot = shell.call("get_navigation_transition_snapshot")
	_check(StringName(transition_snapshot.get("state", &"")) == &"playing", "Long-term transition did not enter coordinator PLAYING")
	_check(StringName(transition_snapshot.get("profile_id", &"")) == &"descend", "Long-term did not request descend")
	_check(_intent_profile_is_clean(transition_snapshot), "Long-term transition profile leaked into NavigationIntent payload")
	main.call("_process", 0.30)
	var observed_descend_offset: Variant = null
	for root_name in descend_roots:
		var offset := (main.get_node(root_name) as Control).position - (descend_bases[root_name] as Vector2)
		if observed_descend_offset == null:
			observed_descend_offset = offset
		else:
			_check(offset == (observed_descend_offset as Vector2), "Long-term descend split the non-overlay scene roots")
	_check(observed_descend_offset != null and (observed_descend_offset as Vector2).y >= DESCEND_CHECKPOINT_MIN_OFFSET, "Long-term descend did not reach the minimum readable scene displacement")
	var long_term_page := shell.call("get_long_term_page") as Control
	_check(long_term_page != null and not long_term_page.visible, "Long-term route committed before presentation completion")
	main.call("_process", 0.55)
	await process_frame
	_check(long_term_page != null and long_term_page.visible, "Long-term transition did not preserve TARGET_LONG_TERM routing")
	_check(page_change_count == page_count_before + 1 and last_changed_page == &"long_term", "Long-term route was not committed exactly once")
	_check_committed_transition(shell, &"long_term", "Long-term")
	for root_name in descend_roots:
		_check((main.get_node(root_name) as Control).position == (descend_bases[root_name] as Vector2), "Long-term descend did not restore root " + root_name)

	shell.call("show_main")
	var shortcut_ok := bool(main.call("_emit_shortcut_index", 0))
	await process_frame
	_check(shortcut_ok, "F1-compatible shortcut index 0 was not preserved")
	_check(host_route_count == 1, "F1-compatible run shortcut did not reach the host route exactly once")

	shell.call("show_main")
	var warehouse_shortcut_ok := bool(main.call("_emit_shortcut_index", 1))
	await process_frame
	_check(warehouse_shortcut_ok, "F2-compatible shortcut index 1 was not preserved")
	_check(deploy_page != null and deploy_page.visible, "F2-compatible warehouse shortcut no longer opens Deploy")
	_check(StringName(deploy_page.call("_active_tab")) == &"warehouse", "F2-compatible shortcut did not select warehouse")

	shell.call("show_main")
	main.call("set_reduced_motion_enabled", true)
	main.call("_process", 0.1)
	for raw_group in ambient_groups:
		if raw_group is Dictionary:
			var motion_group := raw_group as Dictionary
			var motion_node := motion_group.get("node") as TextureRect
			var reduce_behavior := StringName(motion_group.get("reduce_motion_behavior", &"hide"))
			if reduce_behavior == &"freeze":
				_check(motion_node != null and motion_node.visible, "Reduce-motion hides a persistent scene layer")
			else:
				_check(motion_node != null and not motion_node.visible, "Reduce-motion leaves an ambient event visible")
	main.call("_set_focus_state", &"deploy")
	page_count_before = page_change_count
	deploy_button.emit_signal("pressed")
	await process_frame
	_check(not bool(main.get("transition_active")), "Reduce-motion still starts the animated transition")
	_check(deploy_page != null and deploy_page.visible, "Reduce-motion did not preserve immediate deploy routing")
	_check(page_change_count == page_count_before + 1, "Reduce-motion deploy did not commit exactly once")
	_check_committed_transition(shell, &"deploy_prep", "Reduce-motion deploy")

	_finish()


func _on_host_route_requested(_intent: Dictionary) -> void:
	host_route_count += 1


func _on_page_changed(page_id: StringName, _payload: Dictionary) -> void:
	page_change_count += 1
	last_changed_page = page_id


func _intent_profile_is_clean(snapshot: Dictionary) -> bool:
	var coordinator_payload := snapshot.get("payload", {}) as Dictionary
	var intent := coordinator_payload.get("intent", {}) as Dictionary
	var payload := intent.get("payload", {}) as Dictionary
	return not payload.has("profile_id") and not payload.has("transition_profile") and not payload.has("transition_profile_id")


func _check_committed_transition(shell: Control, expected_page: StringName, context: String) -> void:
	var snapshot: Dictionary = shell.call("get_navigation_transition_snapshot")
	var last_result := snapshot.get("last_result", {}) as Dictionary
	_check(StringName(snapshot.get("state", &"")) == &"idle", context + " coordinator did not settle to IDLE")
	_check(StringName(last_result.get("outcome", &"")) == &"committed", context + " coordinator did not record committed")
	_check(StringName(last_result.get("page", &"")) == expected_page, context + " coordinator recorded the wrong page")
	_check(int(last_result.get("commit_count", 0)) == 1, context + " coordinator did not record exactly one commit")


func _check_texture_size(parent: Node, node_path: String, expected: Vector2) -> void:
	var texture_rect := parent.get_node_or_null(node_path) as TextureRect
	if texture_rect == null or texture_rect.texture == null:
		failures.append("Texture is absent: " + node_path)
		return
	_check(texture_rect.texture.get_size() == expected, "Imported texture mismatch for %s: expected %s, got %s" % [node_path, expected, texture_rect.texture.get_size()])


func _find_motion_group(groups: Array, node_name: String) -> Dictionary:
	for raw_group in groups:
		if raw_group is Dictionary and String((raw_group as Dictionary).get("name", "")) == node_name:
			return (raw_group as Dictionary).duplicate(true)
	return {}


func _finish() -> void:
	if failures.is_empty():
		print("ART21_MAIN_MENU_RUNTIME=PASS entries=4 overlays=2 transitions=4 shortcuts=2 motion_groups=10")
		quit(0)
		return
	for failure in failures:
		push_error("ART21 runtime failure: " + failure)
	print("ART21_MAIN_MENU_RUNTIME=FAIL count=%d" % failures.size())
	quit(1)
