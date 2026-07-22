extends SceneTree

const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")

const PASS_MARKER := "I2_RUNTIME_MODAL_PRIORITY=PASS"
const FAIL_MARKER := "I2_RUNTIME_MODAL_PRIORITY=FAIL"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production main scene did not load")
	if packed == null:
		_finish()
		return
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(5)
	var run_scene := main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing")
	if run_scene == null:
		main.queue_free()
		await _frames(2)
		_finish()
		return
	var bus: Variant = run_scene.get("command_bus")
	_require(bus != null, "production CommandBus is missing")
	if bus == null:
		_finish()
		return
	var start_result: Dictionary = bus.dispatch(&"start_demo_run")
	_require(bool(start_result.get("ok", false)), "demo run fixture did not start")
	_require(bool(run_scene.call("_show_run_screen")), "production run screen did not open")
	await _frames(4)
	var exploration_fixture := _explore_adjacent_through_command(bus, run_scene)
	_require(bool(exploration_fixture.get("ok", false)), "could not lawfully move one room to create a real explored fast-return target")
	await _frames(4)

	var base_focus := Button.new()
	base_focus.name = "ModalPriorityBaseFocus"
	base_focus.text = "base"
	base_focus.focus_mode = Control.FOCUS_ALL
	(run_scene.get("run_overlay_root") as Control).add_child(base_focus)
	base_focus.grab_focus()
	await process_frame
	run_scene.call("_show_pause_panel")
	await _frames(3)
	var stack: Variant = run_scene.get("modal_focus_stack")
	_require(stack != null and stack.call("top_modal_id") == &"pause", "pause did not enter the runtime modal stack")
	var pause_panel := run_scene.get("pause_panel") as Control
	var input_shield := run_scene.get("runtime_modal_input_shield") as Control
	_assert_centered(pause_panel, Vector2(640, 360), "pause")
	_assert_shield_directly_below(input_shield, pause_panel, "pause")
	var settings_button := run_scene.get("pause_settings_button") as Button
	if settings_button != null:
		settings_button.grab_focus()
	await process_frame
	run_scene.call("_open_settings_from_pause")
	await _frames(4)
	_require(stack.call("top_modal_id") == &"settings" and int(stack.call("depth")) == 2, "settings did not nest above pause")
	var settings_panel := run_scene.get("runtime_settings_panel") as Control
	var shell: Variant = run_scene.get("ui_shell")
	_require(settings_panel != null and shell != null, "runtime settings fixture is missing")
	if settings_panel != null and shell != null:
		_require(settings_panel.get("settings_manager") == shell.call("get_bound_settings_manager"), "runtime settings created a second authority")
		_require(bool(settings_panel.call("is_panel_open")), "runtime settings did not open a real transaction")
		_assert_shield_directly_below(input_shield, settings_panel, "settings")
	_require(_send_escape(run_scene), "settings Esc was not consumed")
	await _frames(4)
	_require(stack.call("top_modal_id") == &"pause" and int(stack.call("depth")) == 1, "settings cancel closed more than the top modal")
	_require(settings_panel == null or not settings_panel.visible, "settings remained visible after top cancel")
	_require(root.gui_get_focus_owner() == settings_button, "settings close did not restore pause focus")
	if shell != null:
		var shared_manager: Variant = shell.call("get_bound_settings_manager")
		_require(shared_manager != null and StringName(shared_manager.call("get_transaction_state")) == &"idle", "settings Esc did not close the shared transaction")
	_require(_send_escape(run_scene), "pause Esc was not consumed")
	await _frames(3)
	_require(int(stack.call("depth")) == 0, "pause cancel did not settle an empty stack")
	_require(root.gui_get_focus_owner() == base_focus, "pause close did not restore base focus")
	_require(input_shield == null or not input_shield.visible, "runtime input shield remained after stack close")

	var sequence_before_map := int(bus.get("command_sequence"))
	var map_count_before := _map_open_count(run_scene)
	run_scene.call("_open_map_from_ui", &"test")
	await _frames(3)
	_require(stack.call("top_modal_id") == &"map", "map did not enter the runtime modal stack")
	_require(int(bus.get("command_sequence")) == sequence_before_map + 1, "successful hidden-to-visible map open did not dispatch exactly one command")
	_require(_map_open_count(run_scene) == map_count_before + 1, "successful hidden-to-visible map open did not increment map_open_count exactly once")
	_assert_no_map_open_toast(run_scene, "standalone map open")
	var map_panel := run_scene.get("map_overlay_panel") as Control
	_assert_shield_directly_below(input_shield, map_panel, "map")
	var sequence_after_map_open := int(bus.get("command_sequence"))
	var map_count_after_open := _map_open_count(run_scene)
	var inspect_button := _first_inspect_map_button(map_panel)
	_require(inspect_button != null, "expanded map lacks an inspect action focus fixture")
	if inspect_button != null:
		inspect_button.emit_signal("mouse_entered")
		inspect_button.grab_focus()
	await _frames(2)
	_require(int(bus.get("command_sequence")) == sequence_after_map_open, "map hover/focus submitted a command")
	_require(_map_open_count(run_scene) == map_count_after_open, "map hover/focus incremented map_open_count")
	if inspect_button != null:
		var inspected_pos := Vector2i(inspect_button.get_meta("map_pos", Vector2i(-1, -1)))
		inspect_button.pressed.emit()
		await _frames(3)
		var focus_after_action := root.gui_get_focus_owner()
		_require(
			focus_after_action != null
			and focus_after_action.has_meta("map_pos")
			and Vector2i(focus_after_action.get_meta("map_pos", Vector2i(-2, -2))) == inspected_pos,
			"explicit map action did not preserve focus by map_pos"
		)
		_require(int(bus.get("command_sequence")) == sequence_after_map_open, "inspect-only map action dispatched a domain command")
	await _assert_rejected_flag_focus(run_scene, bus, map_panel)
	var toggle_fixture := _first_enabled_map_action(map_panel, &"toggle_flag")
	var toggle_button := toggle_fixture.get("button") as Button
	var toggle_marker: Dictionary = toggle_fixture.get("marker", {})
	_require(toggle_button != null, "expanded KnownMap lacks an enabled toggle_flag action")
	var sequence_before_toggle := int(bus.get("command_sequence"))
	var map_count_before_toggle := _map_open_count(run_scene)
	var flags_before_toggle := _run_stat(run_scene, "flags_placed")
	if toggle_button != null:
		var toggle_pos := Vector2i(toggle_marker.get("pos", Vector2i(-1, -1)))
		_require(not bool(toggle_marker.get("revealed", true)), "toggle_flag fixture was not an unknown public KnownMap cell")
		toggle_button.grab_focus()
		toggle_button.pressed.emit()
		await _frames(4)
		_require(int(bus.get("command_sequence")) == sequence_before_toggle + 1, "explicit toggle_flag action did not dispatch exactly one command")
		_require(_map_open_count(run_scene) == map_count_before_toggle, "toggle_flag action incremented map_open_count")
		_require(_run_stat(run_scene, "flags_placed") == flags_before_toggle + 1, "toggle_flag action did not record exactly one new flag")
		var context_after_toggle: Variant = run_scene.get("run_context")
		_require(context_after_toggle != null and context_after_toggle.get("intel_map").is_flagged(toggle_pos), "toggle_flag action did not update IntelMap authority")
		_assert_map_focus_position(toggle_pos, "toggle_flag action")
	var sequence_after_map_actions := int(bus.get("command_sequence"))
	if map_panel != null:
		map_panel.call("hide_overlay")
	await _frames(3)
	_require(int(stack.call("depth")) == 0, "programmatic map close left a stale stack entry")
	_require(int(bus.get("command_sequence")) == sequence_after_map_actions, "closing map dispatched a domain command")
	_require(_map_open_count(run_scene) == map_count_after_open, "closing map incremented map_open_count")

	var sequence_before_return_map := int(bus.get("command_sequence"))
	var map_count_before_return_map := _map_open_count(run_scene)
	run_scene.call("_open_map_from_ui", &"test_fast_return")
	await _frames(3)
	_require(stack.call("top_modal_id") == &"map" and int(stack.call("depth")) == 1, "fast-return map did not enter the runtime modal stack")
	_require(int(bus.get("command_sequence")) == sequence_before_return_map + 1, "fast-return map open did not dispatch exactly one command")
	_require(_map_open_count(run_scene) == map_count_before_return_map + 1, "fast-return map open did not increment map_open_count exactly once")
	_assert_no_map_open_toast(run_scene, "fast-return map open")
	var return_target := Vector2i(exploration_fixture.get("return_pos", Vector2i(-1, -1)))
	var fast_return_fixture := _map_action_at_position(map_panel, &"fast_return", return_target)
	var fast_return_button := fast_return_fixture.get("button") as Button
	var fast_return_marker: Dictionary = fast_return_fixture.get("marker", {})
	_require(fast_return_button != null, "real KnownMap snapshot has no enabled fast_return action for the explored prior room")
	if fast_return_button != null:
		var return_eligibility: Dictionary = fast_return_marker.get("return_eligibility", {})
		_require(bool(fast_return_marker.get("explored", false)), "fast_return marker is not explicitly explored")
		_require(bool(return_eligibility.get("eligible", false)), "fast_return marker is not explicitly eligible")
		_require(_known_map_cell_is_explored_and_eligible(map_panel, return_target), "fast_return marker is not backed by an explored eligible KnownMap public cell")
		var sequence_before_fast_return := int(bus.get("command_sequence"))
		var map_count_before_fast_return := _map_open_count(run_scene)
		fast_return_button.grab_focus()
		fast_return_button.pressed.emit()
		await _frames(5)
		_require(int(bus.get("command_sequence")) == sequence_before_fast_return + 1, "fast_return action did not dispatch exactly one command")
		_require(_map_open_count(run_scene) == map_count_before_fast_return, "fast_return action incremented map_open_count")
		var context_after_return: Variant = run_scene.get("run_context")
		_require(context_after_return != null and Vector2i(context_after_return.call("get_current_pos")) == return_target, "fast_return command did not move authority to the selected explored room")
		_require(map_panel == null or not map_panel.visible, "successful fast_return did not close the map")
		_require(int(stack.call("depth")) == 0, "successful fast_return left a stale map modal")
	else:
		if map_panel != null:
			map_panel.call("hide_overlay")
		await _frames(3)

	var inventory_fixture := _seed_inventory_action_items(run_scene)
	_require(bool(inventory_fixture.get("ok", false)), "real inventory action fixture could not be added through RunAssetLedger")

	run_scene.call("_show_inventory_panel")
	await _frames(3)
	_require(stack.call("top_modal_id") == &"inventory", "inventory detail did not enter the runtime modal stack")
	var inventory_panel := run_scene.get("inventory_panel") as Control
	_assert_shield_directly_below(input_shield, inventory_panel, "inventory")
	await _assert_lower_layers_blocked(run_scene, bus, stack, &"inventory", true)
	var reject_use_instance_id := String(inventory_fixture.get("reject_use_instance_id", ""))
	await _assert_rejected_inventory_action_focus(
		run_scene,
		bus,
		inventory_panel,
		reject_use_instance_id,
		&"info",
		&"use_item_requested",
		reject_use_instance_id,
		&"use_item",
		"use"
	)
	await _assert_rejected_inventory_action_focus(
		run_scene,
		bus,
		inventory_panel,
		reject_use_instance_id,
		&"drop",
		&"drop_item_requested",
		"i2_modal_missing_drop_item",
		&"drop_inventory_item",
		"drop"
	)
	await _assert_inventory_action_refresh(
		run_scene,
		bus,
		inventory_panel,
		String(inventory_fixture.get("use_instance_id", "")),
		&"use",
		&"consumed"
	)
	await _assert_inventory_action_refresh(
		run_scene,
		bus,
		inventory_panel,
		String(inventory_fixture.get("drop_instance_id", "")),
		&"drop",
		&"room_floor"
	)
	var sequence_before_nested_map := int(bus.get("command_sequence"))
	var map_count_before_nested := _map_open_count(run_scene)
	_parse_key(KEY_M)
	await _frames(3)
	_require(stack.call("top_modal_id") == &"map" and int(stack.call("depth")) == 2, "real M input did not nest map above inventory detail")
	_require(inventory_panel != null and inventory_panel.visible, "real M input hid the lower inventory instead of nesting map")
	_require(int(bus.get("command_sequence")) == sequence_before_nested_map + 1, "real inventory-to-map M input did not dispatch exactly one command")
	_require(_map_open_count(run_scene) == map_count_before_nested + 1, "real inventory-to-map M input did not increment map_open_count exactly once")
	_assert_no_map_open_toast(run_scene, "nested map open")
	_assert_shield_directly_below(input_shield, map_panel, "map over inventory")
	await _assert_lower_layers_blocked(run_scene, bus, stack, &"map", false)
	var sequence_before_blocked_q := int(bus.get("command_sequence"))
	var depth_before_blocked_q := int(stack.call("depth"))
	_parse_key(KEY_Q)
	await _frames(3)
	_require(int(bus.get("command_sequence")) == sequence_before_blocked_q, "map-top Q input dispatched a lower inventory command")
	_require(int(stack.call("depth")) == depth_before_blocked_q and stack.call("top_modal_id") == &"map", "map-top Q input changed the modal stack")
	_require(inventory_panel != null and inventory_panel.visible, "map-top Q input hid the lower inventory")
	var sequence_before_real_escape := int(bus.get("command_sequence"))
	var map_count_before_real_escape := _map_open_count(run_scene)
	_parse_escape()
	await _frames(3)
	_require(stack.call("top_modal_id") == &"inventory" and int(stack.call("depth")) == 1, "nested map Esc closed more than the top modal")
	_require(int(bus.get("command_sequence")) == sequence_before_real_escape, "real Input.parse_input_event Esc dispatched a command")
	_require(_map_open_count(run_scene) == map_count_before_real_escape, "real Input.parse_input_event Esc incremented map_open_count")
	_require(_send_escape(run_scene), "inventory Esc was not consumed")
	await _frames(3)
	_require(int(stack.call("depth")) == 0, "inventory cancel left a stale stack entry")

	await _assert_event_modal_priority(run_scene, bus, stack, input_shield, base_focus)
	await _assert_extract_modal_priority(run_scene, bus, stack, input_shield, base_focus)

	run_scene.call("_show_pause_panel")
	await _frames(2)
	var sequence_before_abandon := int(bus.get("command_sequence"))
	run_scene.call("_request_abandon_from_pause")
	await _frames(2)
	_require(stack.call("top_modal_id") == &"abandon_confirm" and int(stack.call("depth")) == 2, "first abandon action did not open a separate confirmation")
	var abandon_panel := run_scene.get("abandon_confirm_panel") as Control
	_assert_shield_directly_below(input_shield, abandon_panel, "abandon confirmation")
	_require(int(bus.get("command_sequence")) == sequence_before_abandon, "first abandon action dispatched instead of confirming")
	_require(_send_escape(run_scene), "abandon confirmation Esc was not consumed")
	await _frames(2)
	_require(stack.call("top_modal_id") == &"pause", "abandon cancel did not return to pause")
	run_scene.call("_request_abandon_from_pause")
	await _frames(2)
	var confirm := run_scene.get("abandon_confirm_button") as Button
	_require(confirm != null, "abandon confirm button is missing")
	if confirm != null:
		confirm.pressed.emit()
		confirm.pressed.emit()
	await _frames(5)
	_require(int(bus.get("command_sequence")) == sequence_before_abandon + 1, "abandon confirm did not dispatch exactly once")
	_require(stack.call("top_modal_id") == &"result" and int(stack.call("depth")) == 1, "successful abandon did not replace confirmation with one result modal")
	var result_panel := run_scene.get("result_panel") as Control
	_require(result_panel != null and result_panel.visible, "successful abandon result is not visible")
	_assert_shield_directly_below(input_shield, result_panel, "result")
	await _assert_lower_layers_blocked(run_scene, bus, stack, &"result", false)
	await _assert_stale_modal_direct_calls_blocked(run_scene, bus, stack, &"result")
	var sequence_before_result_escape := int(bus.get("command_sequence"))
	var domain_before_result_escape := _run_domain_state_signature(run_scene)
	_require(_send_escape(run_scene), "result Esc was not consumed")
	await _frames(6)
	_require(int(bus.get("command_sequence")) == sequence_before_result_escape, "result Esc dispatched a domain command")
	_require(_run_domain_state_signature(run_scene) == domain_before_result_escape, "result Esc route mutated settled run domain state")
	_require(int(stack.call("depth")) == 0 and stack.call("top_modal_id") == &"", "result Esc did not close exactly the result stack top")
	_require(result_panel == null or not result_panel.visible, "result remained visible after Esc route")
	var deploy_panel := run_scene.get("deploy_shell_panel") as Control
	_require(deploy_panel != null and deploy_panel.is_visible_in_tree(), "result Esc did not route safely to deploy")
	_assert_focus_inside(deploy_panel, "result Esc deploy route")
	_require(input_shield == null or not input_shield.visible, "result Esc route left the runtime input shield visible")

	main.queue_free()
	await _frames(4)
	_finish()


func _assert_centered(control: Control, expected_center: Vector2, context: String) -> void:
	_require(control != null, "%s modal is missing" % context)
	if control == null:
		return
	_require(control.get_global_rect().get_center().distance_to(expected_center) <= 2.0, "%s modal is not centered" % context)


func _assert_shield_directly_below(shield: Control, top_modal: Control, context: String) -> void:
	_require(shield != null and top_modal != null, "%s shield/top modal fixture is missing" % context)
	if shield == null or top_modal == null:
		return
	_require(shield.visible, "%s input shield is not visible" % context)
	_require(shield.get_parent() == top_modal.get_parent(), "%s input shield and top modal do not share a parent" % context)
	if shield.get_parent() == top_modal.get_parent():
		_require(shield.get_index() + 1 == top_modal.get_index(), "%s input shield is not the immediate sibling below the top modal" % context)


func _assert_event_modal_priority(run_scene: Node, bus: Variant, stack: Variant, input_shield: Control, base_focus: Control) -> void:
	base_focus.grab_focus()
	await process_frame
	run_scene.call("_show_event_panel", {
		"event_type": &"dice",
		"completed": false,
		"options": [{"id": &"leave", "enabled": true}],
	})
	await _frames(4)
	var event_panel := run_scene.get("event_panel") as Control
	_require(stack.call("top_modal_id") == &"event" and int(stack.call("depth")) == 1, "event did not enter the runtime modal stack")
	_require(event_panel != null and event_panel.visible, "event modal is not visible")
	_assert_shield_directly_below(input_shield, event_panel, "event")
	_assert_focus_inside(event_panel, "event open")
	await _assert_lower_layers_blocked(run_scene, bus, stack, &"event", false)
	await _assert_stale_modal_direct_calls_blocked(run_scene, bus, stack, &"event")
	var sequence_before_escape := int(bus.get("command_sequence"))
	var domain_before_escape := _run_domain_state_signature(run_scene)
	_require(_send_escape(run_scene), "event Esc was not consumed")
	await _frames(4)
	_require(int(bus.get("command_sequence")) == sequence_before_escape, "event Esc dispatched a domain command")
	_require(_run_domain_state_signature(run_scene) == domain_before_escape, "event Esc mutated run domain state")
	_require(int(stack.call("depth")) == 0 and stack.call("top_modal_id") == &"", "event Esc did not close exactly the event stack top")
	_require(event_panel == null or not event_panel.visible, "event remained visible after Esc")
	_require(root.gui_get_focus_owner() == base_focus, "event Esc did not restore prior focus")


func _assert_extract_modal_priority(run_scene: Node, bus: Variant, stack: Variant, input_shield: Control, base_focus: Control) -> void:
	base_focus.grab_focus()
	await process_frame
	var extract_context: Variant = run_scene.get("run_context")
	_require(extract_context != null, "extract confirmation context is missing")
	if extract_context == null:
		return
	var extract_snapshot: Dictionary = extract_context.call("get_status_snapshot")
	extract_snapshot["phase"] = &"confirm_extract"
	run_scene.call("_show_extract_panel", extract_snapshot)
	await _frames(4)
	var extract_panel := run_scene.get("extract_panel") as Control
	_require(stack.call("top_modal_id") == &"extract_confirm" and int(stack.call("depth")) == 1, "extract confirmation did not enter the runtime modal stack")
	_require(extract_panel != null and extract_panel.visible, "extract confirmation is not visible")
	_assert_shield_directly_below(input_shield, extract_panel, "extract confirmation")
	_assert_focus_inside(extract_panel, "extract confirmation open")
	await _assert_lower_layers_blocked(run_scene, bus, stack, &"extract_confirm", false)
	await _assert_stale_modal_direct_calls_blocked(run_scene, bus, stack, &"extract_confirm")
	var sequence_before_escape := int(bus.get("command_sequence"))
	var domain_before_escape := _run_domain_state_signature(run_scene)
	_require(_send_escape(run_scene), "extract confirmation Esc was not consumed")
	await _frames(5)
	_require(int(bus.get("command_sequence")) == sequence_before_escape + 1, "extract confirmation Esc did not submit exactly one cancel_extract command")
	var result: Dictionary = run_scene.get("last_command_result")
	_require(StringName(result.get("command_name", &"")) == &"cancel_extract", "extract confirmation Esc used the wrong production command")
	_require(_run_domain_state_signature(run_scene) == domain_before_escape, "extract confirmation Esc mutated the running-domain fixture")
	_require(int(stack.call("depth")) == 0 and stack.call("top_modal_id") == &"", "extract confirmation Esc did not close exactly the stack top")
	_require(extract_panel == null or not extract_panel.visible, "extract confirmation remained visible after Esc")
	_require(root.gui_get_focus_owner() == base_focus, "extract confirmation Esc did not restore prior focus")


func _assert_stale_modal_direct_calls_blocked(run_scene: Node, bus: Variant, stack: Variant, expected_top: StringName) -> void:
	var sequence_before := int(bus.get("command_sequence"))
	var domain_before := _run_domain_state_signature(run_scene)
	var depth_before := int(stack.call("depth"))
	var screen_before: Variant = run_scene.get("screen_state")
	if expected_top != &"event":
		run_scene.call("_select_event_option", &"leave")
		run_scene.call("_cancel_event_modal", &"stale_test")
	if expected_top != &"extract_confirm":
		run_scene.call("_confirm_extract_from_ui")
		run_scene.call("_cancel_extract_from_ui")
	if expected_top != &"result":
		run_scene.call("_confirm_failure_salvage_from_result", [])
		run_scene.call("_cancel_result_modal", &"stale_test")
		run_scene.call("_return_from_result_to_main")
		run_scene.call("_return_from_result_to_deploy")
	await _frames(2)
	_require(int(bus.get("command_sequence")) == sequence_before, "%s stale modal direct call dispatched a command" % expected_top)
	_require(_run_domain_state_signature(run_scene) == domain_before, "%s stale modal direct call mutated run domain state" % expected_top)
	_require(run_scene.get("screen_state") == screen_before, "%s stale modal direct call changed the active screen" % expected_top)
	_require(int(stack.call("depth")) == depth_before and stack.call("top_modal_id") == expected_top, "%s stale modal direct call changed the modal stack" % expected_top)


func _assert_focus_inside(control: Control, context: String) -> void:
	var focus_owner := root.gui_get_focus_owner()
	_require(control != null and focus_owner != null and (focus_owner == control or control.is_ancestor_of(focus_owner)), "%s focus is outside the expected surface" % context)
	if focus_owner != null:
		_require(_is_reachable_focus(focus_owner as Control), "%s focus target is not reachable" % context)


func _assert_lower_layers_blocked(run_scene: Node, bus: Variant, stack: Variant, expected_top: StringName, map_under_inventory: bool) -> void:
	var sequence_before := int(bus.get("command_sequence"))
	var map_count_before := _map_open_count(run_scene)
	var domain_before := _run_domain_state_signature(run_scene)
	var depth_before := int(stack.call("depth"))
	var run_surface: Variant = run_scene.get("run_surface")
	if run_surface != null:
		for signal_name in [
			&"interact_requested",
			&"inventory_requested",
			&"ground_loot_requested",
			&"combat_requested",
			&"extract_requested",
			&"pause_requested",
		]:
			run_surface.emit_signal(signal_name)
		run_surface.emit_signal("encounter_option_selected", &"i2_modal_probe", {
			"command_name": &"select_event_option",
			"option_id": &"i2_modal_probe",
		})

	var room_runtime_view: Variant = run_scene.get("room_runtime_view")
	var context_popup: Variant = room_runtime_view.get("context_popup") if room_runtime_view != null else null
	_require(context_popup != null, "%s world-popup lower-layer probe is missing" % expected_top)
	if context_popup != null:
		context_popup.emit_signal("pickup_requested", "i2_modal_blocked_world_item")
		context_popup.emit_signal("replace_requested", "i2_modal_blocked_world_item", "i2_modal_blocked_inventory_item")
		context_popup.emit_signal("chest_open_requested")

	if map_under_inventory:
		var map_panel: Variant = run_scene.get("map_overlay_panel")
		if map_panel != null:
			map_panel.emit_signal("cell_action_requested", {
				"pos": Vector2i.ZERO,
				"action_id": &"toggle_flag",
			})
	else:
		var inventory_panel: Variant = run_scene.get("inventory_panel")
		if inventory_panel != null:
			inventory_panel.emit_signal("drop_item_requested", "i2_modal_blocked_inventory_item")
			inventory_panel.emit_signal("use_item_requested", "i2_modal_blocked_inventory_item")

	# The full-screen shield must make leaked RunSurface map signals inert. The
	# separately tested real keyboard M route is the only audited inventory -> map
	# nesting exception.
	if run_surface != null:
		run_surface.emit_signal("map_requested", &"surface_button")
	await _frames(2)

	_require(int(bus.get("command_sequence")) == sequence_before, "%s lower-layer signal dispatched a command" % expected_top)
	_require(_map_open_count(run_scene) == map_count_before, "%s lower-layer signal incremented map_open_count" % expected_top)
	_require(_run_domain_state_signature(run_scene) == domain_before, "%s lower-layer signal mutated run domain state" % expected_top)
	_require(int(stack.call("depth")) == depth_before and stack.call("top_modal_id") == expected_top, "%s lower-layer signal changed the modal stack" % expected_top)

	# Keep the runner able to report all remaining contracts when production is
	# temporarily defective; this recovery is never entered on a passing build.
	if stack.call("top_modal_id") != expected_top:
		if expected_top == &"inventory" and stack.call("top_modal_id") == &"map":
			run_scene.call("_cancel_map_modal", &"test_recovery")
		elif expected_top == &"map":
			_parse_key(KEY_M)
		await _frames(2)


func _map_open_count(run_scene: Node) -> int:
	var context: Variant = run_scene.get("run_context")
	if context == null:
		return -1
	var stats: Dictionary = context.get("run_stats")
	return int(stats.get("map_open_count", 0))


func _run_stat(run_scene: Node, key: String) -> int:
	var context: Variant = run_scene.get("run_context")
	if context == null:
		return -1
	var stats: Dictionary = context.get("run_stats")
	return int(stats.get(key, 0))


func _assert_no_map_open_toast(run_scene: Node, context: String) -> void:
	var run_surface: Variant = run_scene.get("run_surface")
	var feedback_label := run_surface.get("command_feedback_label") as Label if run_surface != null else null
	_require(feedback_label != null, "%s RunSurface feedback label is missing" % context)
	if feedback_label == null:
		return
	var feedback_text := feedback_label.text.strip_edges().to_lower()
	for forbidden: String in ["已确认", "操作完成", "map overlay", "已打开大地图"]:
		_require(not feedback_text.contains(forbidden.to_lower()), "%s leaked redundant RunSurface toast: %s" % [context, forbidden])


func _explore_adjacent_through_command(bus: Variant, run_scene: Node) -> Dictionary:
	var context: Variant = run_scene.get("run_context")
	if context == null or context.get("truth_map") == null or context.get("intel_map") == null:
		return {}
	var origin := Vector2i(context.call("get_current_pos"))
	var preferred_directions: Array[Vector2i] = []
	var fallback_directions: Array[Vector2i] = []
	for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		var target := origin + direction
		if not bool(context.call("is_inside", target)):
			continue
		var room_type := StringName(context.get("truth_map").get_room_type(target))
		if room_type == &"Normal":
			preferred_directions.append(direction)
		elif room_type == &"Chest":
			fallback_directions.append(direction)
	for direction: Vector2i in preferred_directions + fallback_directions:
		var sequence_before := int(bus.get("command_sequence"))
		var move_result: Dictionary = bus.dispatch(&"move_by", {"delta": direction, "source": "i2_runtime_modal_fixture"})
		_require(int(bus.get("command_sequence")) == sequence_before + 1, "lawful exploration move did not dispatch exactly one command")
		if not bool(move_result.get("ok", false)):
			continue
		var destination := origin + direction
		var runtime: Variant = run_scene.get("in_run_runtime")
		_require(runtime == null or not bool(runtime.call("has_active_combat")), "lawful fast-return fixture entered active combat")
		_require(bool(context.get("intel_map").is_revealed(origin)), "prior room was not retained in IntelMap after lawful movement")
		_require(bool(context.get("intel_map").is_revealed(destination)), "destination was not revealed by lawful movement")
		return {
			"ok": true,
			"return_pos": origin,
			"moved_pos": destination,
		}
	return {}


func _seed_inventory_action_items(run_scene: Node) -> Dictionary:
	var context: Variant = run_scene.get("run_context")
	if context == null or context.get("asset_ledger") == null:
		return {}
	var consumables: Array[Dictionary] = M3ItemCatalogScript.consumable_items()
	if consumables.size() < 2:
		return {}
	var use_item := consumables[0].duplicate(true)
	use_item["instance_id"] = "i2_modal_use_item"
	use_item["reward_location"] = &"inventory"
	var drop_item := consumables[1].duplicate(true)
	drop_item["instance_id"] = "i2_modal_drop_item"
	drop_item["reward_location"] = &"inventory"
	var reject_use_item := M3ItemCatalogScript.collectible_items()[0].duplicate(true)
	reject_use_item["instance_id"] = "i2_modal_reject_use_item"
	reject_use_item["reward_location"] = &"inventory"
	var ledger: Variant = context.get("asset_ledger")
	var seed_result: Dictionary = ledger.add_reward_items(
		[use_item, drop_item, reject_use_item],
		&"inventory",
		Vector2i(context.call("get_current_pos")),
		"i2_runtime_modal_fixture"
	)
	ledger.sync_compat_fields(context)
	var added: Array = seed_result.get("inventory_items", [])
	return {
		"ok": added.size() == 3,
		"use_instance_id": "i2_modal_use_item",
		"drop_instance_id": "i2_modal_drop_item",
		"reject_use_instance_id": "i2_modal_reject_use_item",
	}


func _assert_rejected_inventory_action_focus(
	run_scene: Node,
	bus: Variant,
	inventory_panel: Control,
	focus_instance_id: String,
	focus_action: StringName,
	request_signal: StringName,
	requested_instance_id: String,
	expected_command: StringName,
	context_label: String
) -> void:
	var focus_button := _inventory_action_button(inventory_panel, focus_instance_id, focus_action)
	_require(focus_button != null, "rejected inventory %s focus fixture is missing" % context_label)
	if focus_button == null:
		return
	focus_button.grab_focus()
	await process_frame
	var domain_before := _run_domain_state_signature(run_scene)
	var sequence_before := int(bus.get("command_sequence"))
	inventory_panel.emit_signal(request_signal, requested_instance_id)
	await _frames(5)
	_require(int(bus.get("command_sequence")) == sequence_before + 1, "rejected inventory %s did not enter CommandBus exactly once" % context_label)
	var result: Dictionary = run_scene.get("last_command_result")
	_require(not bool(result.get("ok", true)), "inventory %s rejection unexpectedly succeeded" % context_label)
	_require(StringName(result.get("command_name", &"")) == expected_command, "inventory %s rejection used the wrong production command" % context_label)
	_require(_run_domain_state_signature(run_scene) == domain_before, "inventory %s rejection mutated run domain state" % context_label)
	_assert_inventory_focus_key(inventory_panel, focus_instance_id, focus_action, "rejected inventory %s" % context_label)
	var stack: Variant = run_scene.get("modal_focus_stack")
	_require(stack != null and stack.call("top_modal_id") == &"inventory" and int(stack.call("depth")) == 1, "inventory %s rejection changed the modal stack" % context_label)


func _assert_rejected_flag_focus(run_scene: Node, bus: Variant, map_panel: Control) -> void:
	var context: Variant = run_scene.get("run_context")
	_require(context != null and context.get("intel_map") != null, "rejected flag authority fixture is missing")
	if context == null or context.get("intel_map") == null:
		return
	var intel_map: Variant = context.get("intel_map")
	var current_pos := Vector2i(context.call("get_current_pos"))
	var current_fixture := _map_marker_at_position(map_panel, current_pos)
	var current_button := current_fixture.get("button") as Button
	var current_marker: Dictionary = current_fixture.get("marker", {})
	_require(current_button != null, "rejected flag focus fixture lacks the real current-cell button")
	if current_button == null:
		return
	current_button.grab_focus()
	await process_frame
	var cell_before: Dictionary = intel_map.get_cell_info(current_pos).duplicate(true)
	var flags_before := _run_stat(run_scene, "flags_placed")
	var sequence_before := int(bus.get("command_sequence"))
	var rejected_marker := current_marker.duplicate(true)
	rejected_marker["action_id"] = &"toggle_flag"
	rejected_marker["action_enabled"] = true
	# CommandBus has no player-state flag rejection beyond a missing IntelMap.
	# Remove that authority only for the synchronous submission, then restore the
	# exact object before yielding so no frame can observe the fixture gap.
	context.set("intel_map", null)
	map_panel.emit_signal("cell_action_requested", rejected_marker)
	context.set("intel_map", intel_map)
	await _frames(5)
	_require(context.get("intel_map") == intel_map, "rejected flag fixture did not restore IntelMap authority")
	_require(int(bus.get("command_sequence")) == sequence_before + 1, "rejected flag did not enter CommandBus exactly once")
	var result: Dictionary = run_scene.get("last_command_result")
	_require(not bool(result.get("ok", true)), "flag not-ready rejection unexpectedly succeeded")
	_require(StringName(result.get("command_name", &"")) == &"toggle_flag_cell", "flag rejection used the wrong production command")
	var cell_after: Dictionary = intel_map.get_cell_info(current_pos).duplicate(true)
	_require(cell_after == cell_before, "flag rejection mutated IntelMap state")
	_require(_run_stat(run_scene, "flags_placed") == flags_before, "flag rejection changed flags_placed")
	_assert_map_focus_position(current_pos, "rejected flag")
	var stack: Variant = run_scene.get("modal_focus_stack")
	_require(stack != null and stack.call("top_modal_id") == &"map" and int(stack.call("depth")) == 1, "flag rejection changed the modal stack")


func _run_domain_state_signature(run_scene: Node) -> Dictionary:
	var context: Variant = run_scene.get("run_context")
	if context == null or context.get("asset_ledger") == null:
		return {}
	var ledger: Variant = context.get("asset_ledger")
	var item_instances: Dictionary = ledger.get("item_instances")
	var instance_ids: Array[String] = []
	for raw_instance_id in item_instances.keys():
		instance_ids.append(String(raw_instance_id))
	instance_ids.sort()
	var items: Array[Dictionary] = []
	for instance_id: String in instance_ids:
		var item: Dictionary = item_instances.get(instance_id, {})
		items.append({
			"instance_id": instance_id,
			"location_state": StringName(item.get("location_state", &"")),
			"room_pos": Vector2i(item.get("room_pos", Vector2i(-999, -999))),
			"quantity": int(item.get("quantity", item.get("stack_count", 1))),
		})
	return {
		"items": items,
		"backpack_used": int(ledger.call("get_backpack_used")),
		"hp": int(context.get("hp")),
		"protocol_pressure": int(context.get("pressure")),
		"pending_gold": int(context.get("pending_gold")),
		"safe_gold": int(context.get("safe_gold")),
		"run_active": bool(context.get("run_active")),
		"phase": StringName(context.get("phase")),
		"current_pos": Vector2i(context.call("get_current_pos")),
		"map_open_count": _map_open_count(run_scene),
		"flags_placed": _run_stat(run_scene, "flags_placed"),
	}


func _assert_inventory_focus_key(inventory_panel: Control, instance_id: String, action_id: StringName, context: String) -> void:
	var focus_owner := root.gui_get_focus_owner()
	_require(focus_owner != null and inventory_panel != null and inventory_panel.is_ancestor_of(focus_owner), "%s focus left the inventory" % context)
	if focus_owner == null:
		return
	_require(String(focus_owner.get_meta("item_instance_id", "")) == instance_id, "%s did not preserve item_instance_id" % context)
	_require(StringName(focus_owner.get_meta("item_action", &"")) == action_id, "%s did not preserve item_action" % context)
	_require(_is_reachable_focus(focus_owner as Control), "%s focus target is not reachable" % context)


func _assert_inventory_action_refresh(
	run_scene: Node,
	bus: Variant,
	inventory_panel: Control,
	instance_id: String,
	action_id: StringName,
	expected_location: StringName
) -> void:
	var action_button := _inventory_action_button(inventory_panel, instance_id, action_id)
	_require(action_button != null, "inventory %s action button is missing for the real fixture" % String(action_id))
	if action_button == null:
		return
	action_button.grab_focus()
	await process_frame
	var sequence_before_refresh := int(bus.get("command_sequence"))
	run_scene.call("_refresh_view_models")
	await _frames(4)
	_require(int(bus.get("command_sequence")) == sequence_before_refresh, "inventory %s production snapshot refresh dispatched a command" % String(action_id))
	var stable_focus := root.gui_get_focus_owner()
	_require(
		stable_focus != null
		and inventory_panel.is_ancestor_of(stable_focus)
		and String(stable_focus.get_meta("item_instance_id", "")) == instance_id
		and StringName(stable_focus.get_meta("item_action", &"")) == action_id,
		"inventory %s production snapshot refresh did not restore the stable item action" % String(action_id)
	)
	action_button = _inventory_action_button(inventory_panel, instance_id, action_id)
	_require(action_button != null, "inventory %s action disappeared during non-destructive production refresh" % String(action_id))
	if action_button == null:
		return
	var sequence_before := int(bus.get("command_sequence"))
	action_button.pressed.emit()
	await _frames(5)
	_require(int(bus.get("command_sequence")) == sequence_before + 1, "inventory %s action did not dispatch exactly one command" % String(action_id))
	var command_result: Dictionary = run_scene.get("last_command_result")
	_require(bool(command_result.get("ok", false)), "inventory %s production command was rejected" % String(action_id))
	var expected_command := &"use_item" if action_id == &"use" else &"drop_inventory_item"
	_require(StringName(command_result.get("command_name", &"")) == expected_command, "inventory %s action dispatched the wrong production command" % String(action_id))
	var context: Variant = run_scene.get("run_context")
	var ledger: Variant = context.get("asset_ledger") if context != null else null
	_require(ledger != null and not _ledger_location_contains(ledger, &"inventory", instance_id), "inventory %s target remained in inventory after production refresh" % String(action_id))
	_require(ledger != null and _ledger_location_contains(ledger, expected_location, instance_id), "inventory %s target did not reach %s" % [String(action_id), String(expected_location)])
	var stack: Variant = run_scene.get("modal_focus_stack")
	_require(stack != null and stack.call("top_modal_id") == &"inventory" and int(stack.call("depth")) == 1, "inventory %s action changed the modal stack" % String(action_id))
	var preferred := inventory_panel.call("preferred_focus_control") as Control if inventory_panel != null else null
	var focus_owner := root.gui_get_focus_owner()
	_require(preferred != null and focus_owner == preferred, "removed inventory %s target did not focus the refreshed preferred control" % String(action_id))
	_require(_is_reachable_focus(preferred), "inventory %s preferred fallback is not reachable" % String(action_id))


func _inventory_action_button(inventory_panel: Control, instance_id: String, action_id: StringName) -> Button:
	if inventory_panel == null:
		return null
	for child in inventory_panel.find_children("*", "Button", true, false):
		var button := child as Button
		if button == null:
			continue
		if String(button.get_meta("item_instance_id", "")) == instance_id and StringName(button.get_meta("item_action", &"")) == action_id:
			return button
	return null


func _ledger_location_contains(ledger: Variant, location: StringName, instance_id: String) -> bool:
	for raw_item in ledger.get_items_by_location(location):
		if raw_item is Dictionary and String((raw_item as Dictionary).get("instance_id", "")) == instance_id:
			return true
	return false


func _is_reachable_focus(control: Control) -> bool:
	if control == null or not is_instance_valid(control) or control.is_queued_for_deletion():
		return false
	if not control.is_visible_in_tree() or control.focus_mode == Control.FOCUS_NONE:
		return false
	return not (control is BaseButton and (control as BaseButton).disabled)


func _first_enabled_map_action(map_panel: Control, action_id: StringName) -> Dictionary:
	if map_panel == null:
		return {}
	var view_model: Variant = map_panel.get("view_model")
	if view_model == null:
		return {}
	for raw_marker in view_model.get("room_markers"):
		if not (raw_marker is Dictionary):
			continue
		var marker := raw_marker as Dictionary
		if StringName(marker.get("action_id", &"inspect")) != action_id or not bool(marker.get("action_enabled", false)):
			continue
		return _map_action_fixture(map_panel, marker)
	return {}


func _map_action_at_position(map_panel: Control, action_id: StringName, pos: Vector2i) -> Dictionary:
	if map_panel == null:
		return {}
	var view_model: Variant = map_panel.get("view_model")
	if view_model == null:
		return {}
	for raw_marker in view_model.get("room_markers"):
		if not (raw_marker is Dictionary):
			continue
		var marker := raw_marker as Dictionary
		if Vector2i(marker.get("pos", Vector2i(-1, -1))) != pos:
			continue
		if StringName(marker.get("action_id", &"inspect")) != action_id or not bool(marker.get("action_enabled", false)):
			return {"marker": marker.duplicate(true)}
		return _map_action_fixture(map_panel, marker)
	return {}


func _map_action_fixture(map_panel: Control, marker: Dictionary) -> Dictionary:
	var pos := Vector2i(marker.get("pos", Vector2i(-1, -1)))
	var button := map_panel.get_node_or_null("Panel/Content/Grid/MapCell_%d_%d" % [pos.x, pos.y]) as Button
	return {
		"marker": marker.duplicate(true),
		"button": button,
	}


func _map_marker_at_position(map_panel: Control, pos: Vector2i) -> Dictionary:
	if map_panel == null:
		return {}
	var view_model: Variant = map_panel.get("view_model")
	if view_model == null:
		return {}
	for raw_marker in view_model.get("room_markers"):
		if not (raw_marker is Dictionary):
			continue
		var marker := raw_marker as Dictionary
		if Vector2i(marker.get("pos", Vector2i(-1, -1))) == pos:
			return _map_action_fixture(map_panel, marker)
	return {}


func _known_map_cell_is_explored_and_eligible(map_panel: Control, pos: Vector2i) -> bool:
	if map_panel == null:
		return false
	var view_model: Variant = map_panel.get("view_model")
	if view_model == null:
		return false
	var snapshot: Dictionary = view_model.get("map_snapshot")
	var known_map: Dictionary = snapshot.get("KnownMap", {})
	for raw_cell in known_map.get("public_cells", []):
		if not (raw_cell is Dictionary):
			continue
		var cell := raw_cell as Dictionary
		if Vector2i(cell.get("pos", Vector2i(-1, -1))) != pos:
			continue
		var eligibility: Dictionary = cell.get("return_eligibility", {})
		return bool(cell.get("explored", false)) and bool(eligibility.get("eligible", false))
	return false


func _assert_map_focus_position(pos: Vector2i, context: String) -> void:
	var focus_owner := root.gui_get_focus_owner()
	_require(
		focus_owner != null
		and focus_owner.has_meta("map_pos")
		and Vector2i(focus_owner.get_meta("map_pos", Vector2i(-2, -2))) == pos,
		"%s did not preserve focus by map_pos" % context
	)
	if focus_owner != null:
		_require(_is_reachable_focus(focus_owner as Control), "%s map focus target is not reachable" % context)


func _first_inspect_map_button(map_panel: Control) -> Button:
	if map_panel == null:
		return null
	var view_model: Variant = map_panel.get("view_model")
	if view_model == null:
		return null
	var markers: Array = view_model.get("room_markers")
	for raw_marker in markers:
		if not (raw_marker is Dictionary):
			continue
		var marker := raw_marker as Dictionary
		if StringName(marker.get("action_id", &"inspect")) != &"inspect":
			continue
		var pos := Vector2i(marker.get("pos", Vector2i(-1, -1)))
		var button := map_panel.get_node_or_null("Panel/Content/Grid/MapCell_%d_%d" % [pos.x, pos.y]) as Button
		if button != null and not button.disabled:
			return button
	return null


func _parse_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	event.physical_keycode = keycode
	Input.parse_input_event(event)


func _parse_escape() -> void:
	_parse_key(KEY_ESCAPE)


func _send_escape(run_scene: Node) -> bool:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	return bool(run_scene.call("_handle_cancel_input", event))


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("%s stack=top_only nested=map_over_inventory shield=immediate_top_sibling settings=shared map_open_commands=3 map_actions=toggle_flag:1,fast_return:1 lower_layers=blocked real_input=M,Q,Esc map_focus=map_pos inventory_actions=use:1,drop:1 inventory_focus=preferred abandon_commands=1 failure_focus=use,drop,flag" % PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error("I2 runtime modal priority failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
