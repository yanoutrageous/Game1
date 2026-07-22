extends "res://tests/i3_production_input_journey_runner.gd"

const BAG_PASS_MARKER := "I3_PRODUCTION_FULL_BAG_REPLACEMENT=PASS"
const BAG_FAIL_MARKER := "I3_PRODUCTION_FULL_BAG_REPLACEMENT=FAIL"

var replacement_completed := false
var searched_room_count := 0


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	evidence_dir = _option("evidence-dir", "user://tests/i3_production_full_bag_replacement")
	evidence_contract = "I3 production main.tscn genuine-input full-bag replacement journey"
	require_screenshots = _bool_option("require-screenshots", false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_dir))
	journey_started_msec = Time.get_ticks_msec()
	if not await _boot_run():
		_finish_bag()
		return

	# The route is an offline-audited seed-13 fixture. Runtime traversal still
	# occurs exclusively through held W/A/S/D input and public room feedback.
	_require(await _transition_room(Vector2i.RIGHT, Vector2i(3, 6), &"Chest"), "bag journey could not enter chest (3,6)")
	await _open_and_collect_chest("bag_03_chest_a")
	_require(await _transition_room(Vector2i.RIGHT, Vector2i(4, 6), &"Normal"), "bag journey could not enter normal (4,6)")
	await _search_and_collect_normal("bag_04_normal_a")
	_require(await _transition_room(Vector2i.RIGHT, Vector2i(5, 6), &"Normal"), "bag journey could not enter normal (5,6)")
	await _search_and_collect_normal("bag_05_normal_b")
	_require(await _transition_room(Vector2i.RIGHT, Vector2i(6, 6), &"Chest"), "bag journey could not enter chest (6,6)")
	await _open_and_collect_chest("bag_06_chest_b")
	_require(await _transition_room(Vector2i.UP, Vector2i(6, 5), &"Normal"), "bag journey could not enter normal (6,5)")
	await _search_and_collect_normal("bag_07_normal_c")
	if not replacement_completed:
		_require(await _transition_room(Vector2i.UP, Vector2i(6, 4), &"Chest"), "bag journey could not enter chest (6,4)")
		await _open_and_collect_chest("bag_08_chest_c")
	if not replacement_completed:
		_require(await _transition_room(Vector2i.DOWN, Vector2i(6, 5), &"Normal"), "bag journey could not return through normal (6,5)")
		_require(await _transition_room(Vector2i.LEFT, Vector2i(5, 5), &"Normal"), "bag journey could not enter normal (5,5)")
		await _search_and_collect_normal("bag_09_normal_d")
	if not replacement_completed:
		# Once the bag reaches exactly 10/10, follow already audited safe rooms
		# back to the unsearched normal cell at (1,6). Its search overflow must
		# stay on the floor and expose the replacement decision.
		_require(await _transition_room(Vector2i.DOWN, Vector2i(5, 6), &"Normal"), "bag journey could not return to normal (5,6)")
		_require(await _transition_room(Vector2i.LEFT, Vector2i(4, 6), &"Normal"), "bag journey could not return to normal (4,6)")
		_require(await _transition_room(Vector2i.LEFT, Vector2i(3, 6), &"Chest"), "bag journey could not return through chest (3,6)")
		_require(await _transition_room(Vector2i.LEFT, Vector2i(2, 6), &"Normal"), "bag journey could not return through spawn (2,6)")
		_require(await _transition_room(Vector2i.LEFT, Vector2i(1, 6), &"Normal"), "bag journey could not enter overflow normal (1,6)")
		await _search_and_collect_normal("bag_10_overflow_normal")

	_require(replacement_completed, "audited production route did not reach a full-bag replacement decision")
	await _checkpoint("bag_11_complete", "full-bag replacement settled through player input")
	_finish_bag()


func _boot_run() -> bool:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "bag journey could not load main.tscn")
	if packed == null:
		return false
	main = packed.instantiate()
	root.add_child(main)
	await _frames(12)
	run_scene = main.get_node_or_null("RunScene")
	_require(run_scene != null, "bag journey is missing production RunScene")
	if run_scene == null:
		return false
	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path("%s/meta_%d.json" % [evidence_dir, Time.get_ticks_usec()], "i3_production_full_bag")
	run_scene.get("runtime_controller").bind_meta_progress_adapter(adapter)
	run_scene.set("meta_progress_adapter", adapter)
	await _checkpoint("bag_01_main", "full-bag journey begins at main.tscn")
	_require(
		await _enter_deploy_through_cave_transition("bag_01b_enter_cave_motion"),
		"bag journey did not complete the measured enter-cave transition"
	)
	var deploy_page := _deploy_page()
	_require(deploy_page != null, "bag journey deploy page missing")
	if deploy_page == null:
		return false
	_set_only_fixed_seed(deploy_page)
	var start_button := deploy_page.find_child("DeployPrimaryAction", true, false) as Button
	_require(start_button != null, "bag journey start action missing")
	if start_button == null:
		return false
	await _click_control(start_button, "bag.deploy_confirm")
	_require(await _wait_screen(&"run", 6.0), "bag journey did not start through real pointer input")
	_require(int(run_scene.get("run_context").get("seed_value")) == FIXED_SEED, "bag journey lost fixed seed")
	await _checkpoint("bag_02_run", "fixed-seed run admitted")
	return StringName(run_scene.get("screen_state")) == &"run"


func _open_and_collect_chest(checkpoint_id: String) -> void:
	searched_room_count += 1
	await _move_axis(&"x", 0.30)
	await _move_axis(&"y", 0.53)
	await _move_axis(&"x", 0.53)
	_require(await _wait_context(&"chest", 2.0), "chest search did not expose proximity context")
	if not bool((_status().get("search_state_data", {}) as Dictionary).get("searched", false)):
		await _tap_key(KEY_E, "%s.open" % checkpoint_id)
		_require(await _wait_until(func() -> bool: return bool((_status().get("search_state_data", {}) as Dictionary).get("searched", false)), 3.0), "chest did not open through real E")
		await _frames(18)
	await _checkpoint(checkpoint_id, "chest contents visible; capacity governed")
	for _index in range(8):
		if _context_kind() != &"chest" or _context_item_count() <= 0:
			break
		var popup = _context_popup()
		var items: Array = popup.get("context_items")
		var first_item: Dictionary = items[0] if not items.is_empty() and items[0] is Dictionary else {}
		var remaining := int(_status().get("backpack_capacity", 0)) - int(_status().get("backpack_used", 0))
		if int(first_item.get("weight", 0)) > remaining:
			break
		var before_count := (_status().get("inventory_items", []) as Array).size()
		await _tap_key(KEY_G, "%s.pickup" % checkpoint_id)
		if not await _wait_until(func() -> bool: return (_status().get("inventory_items", []) as Array).size() > before_count, 2.0):
			break


func _search_and_collect_normal(checkpoint_id: String) -> void:
	searched_room_count += 1
	var search_state: Dictionary = _status().get("search_state_data", {})
	if bool(search_state.get("can_search", false)):
		await _tap_key(KEY_E, "%s.search" % checkpoint_id)
		_require(await _wait_until(func() -> bool: return bool((_status().get("search_state_data", {}) as Dictionary).get("searched", false)), 3.0), "normal room did not search through real E")
		await _close_optional_runtime_modal("%s.reward_close" % checkpoint_id)
	await _checkpoint(checkpoint_id, "normal search settled; floor overflow remains in world")
	for _pass in range(8):
		var ground := _first_ground_descriptor()
		if ground.is_empty():
			break
		var target := Vector2(ground.get("local_pos", Vector2(-1, -1)))
		await _move_axis(&"x", 0.22)
		await _move_axis(&"y", 0.84)
		await _move_axis(&"x", target.x)
		await _move_axis(&"y", minf(0.86, target.y + 0.10))
		_require(await _wait_context(&"ground_loot", 2.0), "ground overflow did not auto-display on approach")
		var payload: Dictionary = ground.get("payload", {})
		var item: Dictionary = payload.get("item", {})
		var used := int(_status().get("backpack_used", 0))
		var capacity := int(_status().get("backpack_capacity", 0))
		var remaining := capacity - used
		if int(item.get("weight", 0)) > remaining:
			if used != capacity:
				# Preserve the authoritative item and continue searching for an exact
				# fill; insufficient capacity is not mislabeled as a full bag.
				break
			await _tap_key(KEY_G, "%s.open_replacement" % checkpoint_id)
			var popup = _context_popup()
			_require(await _wait_until(func() -> bool: return String(popup.get("replacement_ground_id")) != "", 2.0), "full bag did not open replacement candidates")
			var replacement_button := popup.find_child("ReplacementCandidateButton", true, false) as Button
			_require(replacement_button != null and not replacement_button.disabled, "replacement view exposed no eligible carried item")
			if replacement_button != null:
				var incoming_id := String(item.get("instance_id", ""))
				await _checkpoint("%s_replacement" % checkpoint_id, "incoming item and carried replacement candidates visible")
				await _click_control(replacement_button, "%s.confirm_replacement" % checkpoint_id)
				_require(await _wait_until(func() -> bool: return _inventory_has(incoming_id), 3.0), "real replacement input did not move the incoming item into the bag")
				replacement_completed = _inventory_has(incoming_id)
			return
		var before_id := String(item.get("instance_id", ""))
		await _tap_key(KEY_G, "%s.pickup_ground" % checkpoint_id)
		if not await _wait_until(func() -> bool: return _inventory_has(before_id), 3.0):
			break


func _first_ground_descriptor() -> Dictionary:
	var view = run_scene.get("room_runtime_view") if run_scene != null else null
	if view == null:
		return {}
	var snapshot: Dictionary = view.call("build_read_only_snapshot")
	for raw in snapshot.get("interactables", []) as Array:
		if raw is Dictionary and StringName((raw as Dictionary).get("interaction_kind", &"")) == &"ground_loot":
			return (raw as Dictionary).duplicate(true)
	return {}


func _inventory_has(instance_id: String) -> bool:
	for raw in _status().get("inventory_items", []) as Array:
		if raw is Dictionary and String((raw as Dictionary).get("instance_id", "")) == instance_id:
			return true
	return false


func _finish_bag() -> void:
	if require_screenshots:
		_require(screenshot_count >= 9, "full-bag journey emitted fewer than nine screenshots")
	var final_status := _status()
	var final_used := int(final_status.get("backpack_used", 0))
	var final_capacity := int(final_status.get("backpack_capacity", 0))
	var evidence_path := _write_evidence()
	_dispose_main_immediately()
	if failures.is_empty():
		print("%s seed=%d searched_rooms=%d capacity=%d replacement=real_input screenshots=%d inputs=%d evidence=%s csv=%s" % [BAG_PASS_MARKER, FIXED_SEED, searched_room_count, final_capacity, screenshot_count, evidence_rows.size(), evidence_path, ProjectSettings.globalize_path("%s/journey.csv" % evidence_dir)])
		_schedule_quit(0)
		return
	for failure in failures:
		push_error("I3 production full-bag journey failure: " + failure)
	print("%s failures=%d used=%d capacity=%d screenshots=%d evidence=%s csv=%s" % [BAG_FAIL_MARKER, failures.size(), final_used, final_capacity, screenshot_count, evidence_path, ProjectSettings.globalize_path("%s/journey.csv" % evidence_dir)])
	_schedule_quit(1)
