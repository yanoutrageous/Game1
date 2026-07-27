extends "res://tests/i3_production_input_journey_runner.gd"

const BRANCH_PASS_MARKER := "I3_PRODUCTION_TERMINAL_BRANCHES=PASS"
const BRANCH_FAIL_MARKER := "I3_PRODUCTION_TERMINAL_BRANCHES=FAIL"

var selected_branch := "all"


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	evidence_dir = _option("evidence-dir", "user://tests/i3_production_terminal_branches")
	evidence_contract = "I3 production main.tscn genuine-input descend/abandon/failure journeys"
	require_screenshots = _bool_option("require-screenshots", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_dir))
	journey_started_msec = Time.get_ticks_msec()
	selected_branch = _option("branch", "all")
	_require(selected_branch in ["all", "abandon", "failure"], "unsupported terminal branch selection: %s" % selected_branch)
	if not failures.is_empty():
		await _finish_branches()
		return
	if await _boot_main_scene("descend"):
		await _exercise_descend_transition()
	await _dispose_main()
	if selected_branch in ["all", "abandon"]:
		if await _boot_production_run("abandon"):
			await _exercise_abandon_branch()
		await _dispose_main()
	if selected_branch in ["all", "failure"]:
		if await _boot_production_run("failure"):
			await _exercise_failure_branch()
	await _finish_branches()


func _boot_production_run(prefix: String) -> bool:
	if not await _boot_main_scene(prefix):
		return false
	await _checkpoint("%s_01_main" % prefix, "%s branch begins at main.tscn" % prefix)
	_require(StringName(run_scene.get("screen_state")) == &"main_menu", "%s branch did not begin on main menu" % prefix)
	_require(
		await _enter_deploy_through_cave_transition("%s_01b_enter_cave_motion" % prefix),
		"%s branch did not complete the measured enter-cave transition" % prefix
	)
	var deploy_page := _deploy_page()
	_require(deploy_page != null, "%s branch deploy page missing" % prefix)
	if deploy_page == null:
		return false
	_set_only_fixed_seed(deploy_page)
	var start_button := deploy_page.find_child("DeployPrimaryAction", true, false) as Button
	_require(start_button != null, "%s branch start button missing" % prefix)
	if start_button == null:
		return false
	await _click_control(start_button, "%s.deploy_confirm" % prefix)
	_require(await _wait_screen(&"run", 6.0), "%s branch did not start through real pointer input" % prefix)
	_require(int(run_scene.get("run_context").get("seed_value")) == FIXED_SEED, "%s branch lost fixed seed" % prefix)
	return StringName(run_scene.get("screen_state")) == &"run"


func _boot_main_scene(prefix: String) -> bool:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "%s branch could not load main.tscn" % prefix)
	if packed == null:
		return false
	main = packed.instantiate()
	root.add_child(main)
	await _frames(12)
	run_scene = main.get_node_or_null("RunScene")
	_require(run_scene != null, "%s branch is missing production RunScene" % prefix)
	if run_scene == null:
		return false
	var adapter = MetaProgressAdapterScript.new()
	var save_path := "%s/%s_meta_%d.json" % [evidence_dir, prefix, Time.get_ticks_usec()]
	adapter.set_active_profile_path(save_path, "i3_production_%s" % prefix)
	run_scene.get("runtime_controller").bind_meta_progress_adapter(adapter)
	run_scene.set("meta_progress_adapter", adapter)
	return true


func _exercise_descend_transition() -> void:
	await _checkpoint("descend_01_main", "long-term transition begins at production main")
	_require(StringName(run_scene.get("screen_state")) == &"main_menu", "descend contract did not begin on main menu")
	await _tap_key(KEY_DOWN, "descend.focus_long_term")
	_require(
		await _wait_until(func() -> bool: return _focus_name().begins_with("MainMenuEntry_long_term"), 2.0),
		"real directional input did not focus the long-term entry"
	)
	var app_shell = run_scene.get("ui_shell")
	var main_page := app_shell.call("get_main_page") as Control if app_shell != null else null
	var scene_root := main_page.get_node_or_null("BackgroundRoot") as Control if main_page != null else null
	_require(app_shell != null and main_page != null and scene_root != null, "descend transition surface is incomplete")
	if app_shell == null or main_page == null or scene_root == null:
		return

	var initial_position := scene_root.position
	var started_msec := Time.get_ticks_msec()
	var saw_playing := false
	var saw_expected_profile := false
	var mid_motion_recorded := false
	var max_downward_travel := 0.0
	await _tap_key(KEY_ENTER, "descend.accept_long_term")
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() <= deadline and StringName(run_scene.get("screen_state")) != &"long_term_shell":
		var transition_snapshot: Dictionary = app_shell.call("get_navigation_transition_snapshot")
		if bool(transition_snapshot.get("busy", false)):
			saw_playing = saw_playing or StringName(transition_snapshot.get("state", &"")) == &"playing"
			saw_expected_profile = saw_expected_profile or StringName(transition_snapshot.get("profile_id", &"")) == &"descend"
		var downward_travel := scene_root.position.y - initial_position.y
		max_downward_travel = maxf(max_downward_travel, downward_travel)
		if not mid_motion_recorded and downward_travel >= 60.0:
			mid_motion_recorded = true
			await _checkpoint("descend_02_motion", "main scene visibly descends before long-term route commit")
		await create_timer(FRAME_STEP).timeout

	var duration_msec := Time.get_ticks_msec() - started_msec
	var final_transition: Dictionary = app_shell.call("get_navigation_transition_snapshot")
	var last_result: Dictionary = final_transition.get("last_result", {})
	var measurement := {
		"profile": "descend",
		"duration_msec": duration_msec,
		"max_scene_downward_travel": max_downward_travel,
		"mid_motion_checkpoint": mid_motion_recorded,
		"saw_playing_state": saw_playing,
		"route_outcome": String(last_result.get("outcome", &"")),
		"route_page": String(last_result.get("page", &"")),
		"commit_count": int(last_result.get("commit_count", 0)),
	}
	transition_measurements.append(measurement.duplicate(true))
	var measurement_row := _evidence_snapshot("main.descend.measurement", "measurement")
	measurement_row["input"] = measurement.duplicate(true)
	measurement_row["visible_feedback"] = "strict full-scene displacement and timing measurement"
	evidence_rows.append(measurement_row)
	_require(saw_playing and saw_expected_profile, "descend playback/profile was not observed before routing")
	_require(mid_motion_recorded, "long-term route committed without an observable descend checkpoint")
	_require(max_downward_travel >= 150.0, "descend scene displacement was below 150 logical pixels")
	_require(duration_msec >= 620, "long-term route committed before a non-trivial descend duration")
	_require(duration_msec <= 3200, "descend transition exceeded the bounded presentation window")
	_require(StringName(run_scene.get("screen_state")) == &"long_term_shell", "descend transition did not route to long-term")
	_require(StringName(last_result.get("outcome", &"")) == &"committed", "descend route was not committed")
	_require(StringName(last_result.get("page", &"")) == &"long_term", "descend route committed to the wrong page")
	_require(int(last_result.get("commit_count", 0)) == 1, "descend route did not commit exactly once")
	await _checkpoint("descend_03_long_term", "long-term page visible only after descend playback")
	var long_term_page := app_shell.call("get_long_term_page") as Control
	var main_button := long_term_page.find_child("LongTermNavMainButton", true, false) as Button if long_term_page != null else null
	_require(main_button != null and main_button.visible and not main_button.disabled, "long-term page exposed no real return-to-main action")
	if main_button != null:
		await _click_control(main_button, "descend.return_main")
	_require(await _wait_screen(&"main_menu", 4.0), "real long-term navigation input did not return to main")
	await _checkpoint("descend_04_return_main", "descend contract returned outside long-term")


func _exercise_abandon_branch() -> void:
	await _checkpoint("abandon_02_run", "active run before pause")
	await _tap_key(KEY_ESCAPE, "abandon.pause_open")
	var pause_panel := run_scene.get("pause_panel") as Control
	_require(await _wait_until(func() -> bool: return pause_panel != null and pause_panel.visible, 2.0), "Esc did not open the production pause panel")
	var abandon_button := run_scene.get("pause_abandon_button") as Button
	await _click_control(abandon_button, "abandon.request")
	var abandon_confirm_panel := run_scene.get("abandon_confirm_panel") as Control
	_require(await _wait_until(func() -> bool: return abandon_confirm_panel != null and abandon_confirm_panel.visible, 2.0), "abandon did not require a second explicit decision")
	await _checkpoint("abandon_03_confirm", "abandon consequences and confirmation visible")
	var abandon_cancel := run_scene.get("abandon_confirm_cancel_button") as Button
	await _click_control(abandon_cancel, "abandon.cancel")
	_require(await _wait_until(func() -> bool: return abandon_confirm_panel != null and not abandon_confirm_panel.visible, 2.0), "abandon cancellation did not return to pause")
	_require(bool(_status().get("run_active", false)), "abandon cancellation ended the run")
	await _click_control(abandon_button, "abandon.request_again")
	_require(await _wait_until(func() -> bool: return abandon_confirm_panel != null and abandon_confirm_panel.visible, 2.0), "abandon confirmation could not be reopened")
	var abandon_confirm := run_scene.get("abandon_confirm_button") as Button
	await _click_control(abandon_confirm, "abandon.confirm")
	var result_panel := run_scene.get("result_panel") as Control
	_require(await _wait_until(func() -> bool: return result_panel != null and result_panel.visible, 5.0), "confirmed abandon did not open a result")
	var result_snapshot: Dictionary = run_scene.get("run_context").get("result_snapshot")
	_require(StringName(result_snapshot.get("outcome", &"")) == &"Abandoned", "abandon branch settled with the wrong outcome")
	_require(StringName(result_snapshot.get("terminal_reason_code", &"")) == &"player_pause_exit_current_run", "abandon result did not explain the player-initiated reason")
	await _checkpoint("abandon_04_result", "abandon reason and consequences visible")
	var return_main := result_panel.get("return_main_button") as Button
	_require(return_main != null and return_main.visible and not return_main.disabled, "committed abandon result did not expose return to main")
	await _click_control(return_main, "abandon.return_main")
	_require(await _wait_screen(&"main_menu", 4.0), "abandon result did not return outside the run")
	await _checkpoint("abandon_05_return_main", "abandon branch closed outside")


func _exercise_failure_branch() -> void:
	_require(await _transition_room(Vector2i.RIGHT, Vector2i(3, 6), &"Chest"), "failure branch could not traverse the chest route")
	_require(await _transition_room(Vector2i.UP, Vector2i(3, 5), &"Event"), "failure branch could not traverse the event route")
	_require(await _transition_room(Vector2i.UP, Vector2i(3, 4), &"Normal"), "failure branch could not traverse the normal route")
	# Seed 13's audited combat room contains one bat. At full health its genuine
	# production damage cadence cannot defeat the player inside this journey's
	# bounded terminal window. Prepare the failure through three real, one-shot
	# mine entries on the production map, then let combat deliver the terminal
	# hit. No health, result or context field is written by this runner.
	var context = run_scene.get("run_context")
	var hp_before_mines := int(context.get("hp")) if context != null else -1
	_require(await _transition_room(Vector2i.RIGHT, Vector2i(4, 4), &"Mine"), "failure branch could not enter the first audited mine")
	_require(await _transition_room(Vector2i.RIGHT, Vector2i(5, 4), &"Mine"), "failure branch could not enter the second audited mine")
	_require(await _transition_room(Vector2i.LEFT, Vector2i(4, 4), &"Mine"), "failure branch could not leave the second audited mine")
	_require(await _transition_room(Vector2i.LEFT, Vector2i(3, 4), &"Normal"), "failure branch could not return to the audited route")
	_require(await _transition_room(Vector2i.UP, Vector2i(3, 3), &"Chest"), "failure branch could not reach the north chest route")
	_require(await _transition_room(Vector2i.LEFT, Vector2i(2, 3), &"Mine"), "failure branch could not enter the third audited mine")
	var hp_after_mines := int(context.get("hp")) if context != null else -1
	_require(hp_before_mines > 0 and hp_after_mines > 0 and hp_after_mines < hp_before_mines, "real mine entries did not prepare a survivable combat-failure state")
	_record_failure_observation("failure.mine_preparation", {
		"hp_before": hp_before_mines,
		"hp_after": hp_after_mines,
		"damage_source": "production_mine_entry",
		"mine_entries": 3,
	})
	_require(await _transition_room(Vector2i.DOWN, Vector2i(2, 4), &"Monster"), "failure branch could not enter the monster room")
	_require(await _wait_until(func() -> bool: return _combat_active(), 3.0), "failure branch did not start combat")
	await _checkpoint("failure_02_combat", "combat threat active before defeat")
	var hp_before_combat_damage := int(context.get("hp")) if context != null else -1
	# Choose an exposed corner lane from the authoritative read-only enemy
	# snapshot. Moving on the enemy's side of the altar prevents solid cover
	# from invalidating the natural ranged-damage proof.
	var combat_before := _combat_read_only_snapshot()
	var enemies: Array = combat_before.get("enemies", [])
	_require(not enemies.is_empty(), "failure combat exposed no authoritative enemy snapshot")
	var enemy: Dictionary = enemies[0] if not enemies.is_empty() else {}
	var enemy_pos := Vector2(enemy.get("simulation_pos", enemy.get("pos", Vector2(0.70, 0.50))))
	var exposure_target := Vector2(
		0.82 if enemy_pos.x >= 0.50 else 0.18,
		0.20 if enemy_pos.y <= 0.50 else 0.80
	)
	await _move_axis(&"x", exposure_target.x)
	await _move_axis(&"y", exposure_target.y)
	_record_failure_observation("failure.combat_exposure", {
		"enemy_id": String(enemy.get("enemy_id", "")),
		"monster_type": String(enemy.get("monster_type", &"")),
		"enemy_position": enemy_pos,
		"player_target": exposure_target,
		"player_position": _player_local_pos(),
		"snapshot_authority": String(combat_before.get("authority", &"")),
	})
	var result_panel := run_scene.get("result_panel") as Control
	var saw_natural_combat_damage := context != null and int(context.get("hp")) < hp_before_combat_damage
	var combat_deadline := Time.get_ticks_msec() + 14000
	while Time.get_ticks_msec() <= combat_deadline and (result_panel == null or not result_panel.visible):
		if context != null and int(context.get("hp")) < hp_before_combat_damage:
			saw_natural_combat_damage = true
		await create_timer(FRAME_STEP).timeout
	_require(saw_natural_combat_damage, "exposed production combat applied no natural player damage")
	_require(result_panel != null and result_panel.visible, "production combat did not naturally reach a failure result")
	if result_panel == null or not result_panel.visible:
		return
	var result_snapshot: Dictionary = run_scene.get("run_context").get("result_snapshot")
	_require(StringName(result_snapshot.get("outcome", &"")) == &"Failed", "combat defeat branch settled with the wrong outcome")
	var terminal_reason := StringName(result_snapshot.get("terminal_reason_code", &""))
	_require(
		terminal_reason in [&"runtime_combat_melee", &"runtime_combat_projectile", &"runtime_combat_laser", &"runtime_combat_defeat"],
		"failure result did not explain its production combat cause: actual=%s" % String(terminal_reason)
	)
	await _checkpoint("failure_03_result", "failure reason, loss and salvage state visible")
	if bool(result_panel.call("requires_salvage_confirmation")):
		var salvage_confirm := result_panel.get("salvage_confirm_button") as Button
		_require(salvage_confirm != null and not salvage_confirm.disabled, "failure salvage could not be explicitly finalized")
		if salvage_confirm != null:
			await _click_control(salvage_confirm, "failure.confirm_salvage")
		_require(await _wait_until(func() -> bool: return not bool(result_panel.call("requires_salvage_confirmation")), 5.0), "real salvage confirmation did not finalize failure settlement")
	var return_main := result_panel.get("return_main_button") as Button
	_require(return_main != null and return_main.visible and not return_main.disabled, "finalized failure result did not expose return to main")
	if return_main != null and return_main.visible and not return_main.disabled:
		await _click_control(return_main, "failure.return_main")
		_require(await _wait_screen(&"main_menu", 4.0), "failure result did not return outside the run")
		await _checkpoint("failure_04_return_main", "failure branch closed outside")


func _combat_read_only_snapshot() -> Dictionary:
	var runtime = run_scene.get("in_run_runtime") if run_scene != null else null
	return runtime.call("build_read_only_snapshot") as Dictionary if runtime != null else {}


func _record_failure_observation(action: String, observation: Dictionary) -> void:
	var row := _evidence_snapshot(action, "measurement")
	row["input"] = observation.duplicate(true)
	row["visible_feedback"] = "read-only production damage-path observation"
	evidence_rows.append(row)


func _dispose_main() -> void:
	if main != null and is_instance_valid(main):
		main.queue_free()
	await _frames(12)
	main = null
	run_scene = null


func _finish_branches() -> void:
	if require_screenshots:
		var expected_screenshots := 15 if selected_branch == "all" else (10 if selected_branch == "abandon" else 9)
		_require(screenshot_count >= expected_screenshots, "terminal branches emitted fewer than %d screenshots" % expected_screenshots)
	var evidence_path := _write_evidence()
	_dispose_main_immediately()
	if failures.is_empty():
		var outcomes := "Abandoned,Failed" if selected_branch == "all" else ("Abandoned" if selected_branch == "abandon" else "Failed")
		print("%s seed=%d outcomes=%s confirmations=cancel_then_confirm,salvage return=main screenshots=%d inputs=%d evidence=%s csv=%s" % [BRANCH_PASS_MARKER, FIXED_SEED, outcomes, screenshot_count, evidence_rows.size(), evidence_path, ProjectSettings.globalize_path("%s/journey.csv" % evidence_dir)])
		_schedule_quit(0)
		return
	for failure in failures:
		push_error("I3 production terminal branch failure: " + failure)
	print("%s failures=%d screenshots=%d evidence=%s csv=%s" % [BRANCH_FAIL_MARKER, failures.size(), screenshot_count, evidence_path, ProjectSettings.globalize_path("%s/journey.csv" % evidence_dir)])
	_schedule_quit(1)
