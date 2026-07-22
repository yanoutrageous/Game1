extends SceneTree

const PASS_MARKER := "I2_COMBAT_ROOM_EXPERIENCE=PASS"
const FAIL_MARKER := "I2_COMBAT_ROOM_EXPERIENCE=FAIL"

var failures: Array[String] = []
var command_counts: Dictionary = {}
var inject_transition_failure := false
var transition_failure_context
var transition_failure_target := Vector2i.ZERO


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production Main scene could not be loaded")
	if packed == null:
		_finish()
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var run_scene := main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing")
	if run_scene == null:
		main.queue_free()
		_finish()
		return
	var context = run_scene.get("run_context")
	var bus = run_scene.get("command_bus")
	var in_run_runtime = run_scene.get("in_run_runtime")
	var player = run_scene.get("player_controller")
	_require(context != null and bus != null and in_run_runtime != null and player != null, "production run authority was not initialized")
	if not failures.is_empty():
		main.queue_free()
		_finish()
		return
	var first_exit_notice := {
		"ok": true,
		"status": &"moved",
		"room_entry_result": {"room_type": &"Exit", "position": Vector2i(2, 2), "first_explore": true},
	}
	run_scene.call("_apply_room_entry_result", first_exit_notice)
	_require(StringName(first_exit_notice.get("status", &"")) == &"exit_discovered" and String(first_exit_notice.get("message", "")).contains("撤离信标"), "production RunScene did not project the authoritative first Exit notice")
	var revisit_exit_notice := {
		"ok": true,
		"status": &"moved",
		"room_entry_result": {"room_type": &"Exit", "position": Vector2i(2, 2), "first_explore": false},
	}
	run_scene.call("_apply_room_entry_result", revisit_exit_notice)
	_require(StringName(revisit_exit_notice.get("status", &"")) == &"moved" and not revisit_exit_notice.has("message"), "production RunScene repeated the first Exit notice on revisit")
	bus.command_requested.connect(_on_command_requested)
	var start_result: Dictionary = bus.dispatch(&"start_demo_run", {"source": "i2_combat_room_experience"})
	_require(bool(start_result.get("ok", false)), "demo run could not be started")
	run_scene.call("_show_run_screen")

	var source := Vector2i(1, 1)
	var target := Vector2i(2, 1)
	context.truth_map.set_room_type(source, &"Monster")
	context.truth_map.set_room_type(target, &"Normal")
	context.player_pos = source
	context.current_pos = source
	context.intel_map.reveal_cell(source, context.truth_map)
	context.intel_map.reveal_cell(target, context.truth_map)
	bus.room_resolver.enter_room(context)
	in_run_runtime.sync_room(Vector2(0.50, 0.50))
	player.set_local_position(Vector2(0.50, 0.50))
	player.set_facing_vector(Vector2.RIGHT)
	_require(in_run_runtime.has_active_combat(), "Monster room did not start combat")
	context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, 100, "i2_combat_flee_fixture")
	var black_before := int(context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK))
	run_scene.call("_apply_full_view_models")
	var run_surface = run_scene.get("run_surface")
	var extract_button := (run_surface.get("action_buttons") as Dictionary).get(&"extract") as Button if run_surface != null else null
	_require(extract_button != null and not extract_button.disabled, "Monster-room flee action is not available through the production mouse button")
	_press_button(extract_button)
	_require(_count(&"flee_runtime_combat") == 0 and _count(&"attempt_room_transition") == 0, "invalid-position mouse flee submitted a domain command")
	_require(not bool(run_scene.call("_runtime_modal_is_top", &"combat_flee_confirm")), "invalid-position mouse flee opened confirmation")
	player.set_local_position(Vector2(0.91, 0.50))

	# Touching a valid door is presentation-only and records the nearby exit.
	run_scene.call("_attempt_room_transition", Vector2i.RIGHT)
	_require(context.get_current_pos() == source, "combat door touch changed the authoritative room")
	_require(_count(&"flee_runtime_combat") == 0, "combat door touch submitted flee")
	_require(_count(&"attempt_room_transition") == 0, "combat door touch submitted transition")
	_require(int(context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK)) == black_before, "combat door touch changed black coin")
	_require(in_run_runtime.has_active_combat(), "combat door touch ended combat")

	# An unrelated modal blocks the shared keyboard/mouse flee action.
	run_scene.call("_show_pause_panel")
	_press_button(extract_button)
	_require(_count(&"flee_runtime_combat") == 0, "modal-open flee request reached the domain")
	run_scene.call("_continue_from_pause")

	# The production mouse button opens the same confirmation as the T action;
	# cancel remains zero-command.
	_press_button(extract_button)
	_require(bool(run_scene.call("_runtime_modal_is_top", &"combat_flee_confirm")), "valid combat door did not open flee confirmation")
	run_scene.call("_cancel_extract_from_ui")
	_require(_count(&"flee_runtime_combat") == 0, "cancel submitted flee")
	_require(_count(&"attempt_room_transition") == 0, "cancel submitted transition")

	# Re-open through the keyboard-equivalent action and confirm once. Inject a
	# deterministic transition failure only after the flee command is submitted;
	# the paid authorization must remain stable for the mouse retry.
	inject_transition_failure = true
	transition_failure_context = context
	transition_failure_target = target
	run_scene.call("_request_extract_from_ui")
	run_scene.call("_confirm_extract_from_ui")
	_require(_count(&"flee_runtime_combat") == 1, "confirmed flee did not submit exactly one flee command")
	_require(_count(&"attempt_room_transition") == 1, "confirmed flee did not submit exactly one transition command")
	_require(context.get_current_pos() == source, "injected transition failure changed the authoritative room")
	var expected_black := black_before - int(floor(float(black_before) * 0.10))
	_require(int(context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK)) == expected_black, "confirmed flee did not apply the existing ten-percent rule exactly once")
	_require(in_run_runtime.flee_authorized and not in_run_runtime.has_active_combat(), "failed transition did not preserve paid flee authorization")
	in_run_runtime.sync_room(player.get_local_position())
	_require(not in_run_runtime.has_active_combat(), "same-room sync restarted combat after paid flee")
	if context.intel_map.is_flagged(target):
		context.intel_map.toggle_flag(target)
	run_scene.call("_apply_full_view_models")
	_require(extract_button != null and not extract_button.disabled, "paid flee retry is not reachable through the production mouse button")
	_press_button(extract_button)
	_require(_count(&"flee_runtime_combat") == 1, "mouse retry charged flee a second time")
	_require(_count(&"attempt_room_transition") == 2, "mouse retry did not submit exactly one additional transition")
	_require(context.get_current_pos() == target, "mouse retry did not enter the selected adjacent room")
	_require(int(context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK)) == expected_black, "mouse retry charged the flee cost a second time")
	_require(not in_run_runtime.flee_authorized, "successful authoritative room change retained flee authorization")

	if bus.command_requested.is_connected(_on_command_requested):
		bus.command_requested.disconnect(_on_command_requested)
	main.queue_free()
	run_scene = null
	context = null
	bus = null
	in_run_runtime = null
	player = null
	main = null
	for _unused in range(10):
		await process_frame
	_finish()


func _on_command_requested(command_name: StringName, _payload: Dictionary) -> void:
	command_counts[command_name] = int(command_counts.get(command_name, 0)) + 1
	if command_name == &"flee_runtime_combat" and inject_transition_failure and transition_failure_context != null:
		inject_transition_failure = false
		transition_failure_context.intel_map.flag_cell(transition_failure_target)


func _count(command_name: StringName) -> int:
	return int(command_counts.get(command_name, 0))


func _press_button(button: Button) -> void:
	if button == null or button.disabled:
		return
	button.pressed.emit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("%s touch=zero_command mouse=enabled invalid=zero_command cancel=zero_command confirm=flee_1,transition_retry_2 modal=blocked" % PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		print("I2_COMBAT_ROOM_EXPERIENCE_FAILURE %s" % failure)
	print(FAIL_MARKER)
	quit(1)
