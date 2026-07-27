extends SceneTree

const RuntimeInputProfileScript := preload("res://scripts/core/input/runtime_input_profile.gd")
const SemanticActionHintScript := preload("res://scripts/core/input/semantic_action_hint.gd")
const RunSceneInputRouterScript := preload("res://scripts/core/run/run_scene_input_router.gd")
const ModalFocusStackScript := preload("res://scripts/ui/shell/modal_focus_stack.gd")
const G41InteractableScript := preload("res://scripts/gameplay/interaction/g41_interactable.gd")
const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")

const PASS_MARKER := "I3R_INPUT_MODAL_AUTHORITY=PASS"
const FAIL_MARKER := "I3R_INPUT_MODAL_AUTHORITY=FAIL"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check_input_profile_and_router()
	_check_action_hint_descriptor()
	await _check_modal_priority_and_focus()
	await _check_production_authority()
	_finish()


func _check_input_profile_and_router() -> void:
	var first_install: Dictionary = RuntimeInputProfileScript.install()
	var counts_after_first := _action_event_counts()
	var second_install: Dictionary = RuntimeInputProfileScript.install()
	_require(int(second_install.get("events_added", -1)) == 0, "input profile install is not idempotent")
	_require(_action_event_counts() == counts_after_first, "second install changed InputMap event counts")
	_require(
		int(first_install.get("semantic_actions", 0)) == RuntimeInputProfileScript.semantic_action_names().size(),
		"semantic action count drifted"
	)

	_require(
		RunSceneInputRouterScript.run_action(_key_event(KEY_E)) == RunSceneInputRouterScript.ACTION_INTERACT,
		"keyboard interact did not route through InputMap"
	)
	_require(
		RunSceneInputRouterScript.run_action(_key_event(KEY_SPACE)) == RunSceneInputRouterScript.ACTION_FIGHT,
		"keyboard attack did not route through InputMap"
	)
	_require(
		RunSceneInputRouterScript.run_action(_mouse_button(MOUSE_BUTTON_LEFT)) == RunSceneInputRouterScript.ACTION_FIGHT,
		"primary mouse attack did not route through InputMap"
	)
	_require(
		RunSceneInputRouterScript.run_action(_key_event(KEY_M)) == RunSceneInputRouterScript.ACTION_OPEN_MAP,
		"keyboard map did not route through InputMap"
	)
	_require(
		RunSceneInputRouterScript.cancel_action(_key_event(KEY_ESCAPE)) == RunSceneInputRouterScript.ACTION_CANCEL,
		"keyboard cancel did not route through InputMap"
	)
	_require(
		RunSceneInputRouterScript.run_action(_joy_button(JOY_BUTTON_A)) == RunSceneInputRouterScript.ACTION_INTERACT,
		"virtual gamepad A did not route to interact"
	)
	_require(
		RunSceneInputRouterScript.run_action(_joy_button(JOY_BUTTON_X)) == RunSceneInputRouterScript.ACTION_FIGHT,
		"virtual gamepad X did not route to attack"
	)
	_require(
		RunSceneInputRouterScript.run_action(_joy_button(JOY_BUTTON_Y)) == RunSceneInputRouterScript.ACTION_OPEN_MAP,
		"virtual gamepad Y did not route to map"
	)
	_require(
		RunSceneInputRouterScript.run_action(_joy_button(JOY_BUTTON_LEFT_SHOULDER)) == RunSceneInputRouterScript.ACTION_OPEN_INVENTORY,
		"virtual gamepad LB did not route to inventory"
	)
	_require(
		RunSceneInputRouterScript.cancel_action(_joy_button(JOY_BUTTON_B)) == RunSceneInputRouterScript.ACTION_CANCEL,
		"virtual gamepad B did not route to cancel"
	)
	_require(
		RunSceneInputRouterScript.cancel_action(_joy_button(JOY_BUTTON_START)) == RunSceneInputRouterScript.ACTION_CANCEL,
		"virtual gamepad Start did not route to pause/cancel context"
	)
	_require(
		RunSceneInputRouterScript.movement_direction(_joy_button(JOY_BUTTON_DPAD_RIGHT)) == Vector2.RIGHT,
		"virtual D-pad did not route through the movement action"
	)
	var attack_counts := {
		"key": 0,
		"mouse": 0,
		"gamepad": 0,
	}
	for event in InputMap.action_get_events("attack"):
		if event is InputEventKey:
			attack_counts["key"] += 1
		elif event is InputEventMouseButton:
			attack_counts["mouse"] += 1
		elif event is InputEventJoypadButton:
			attack_counts["gamepad"] += 1
	_require(
		attack_counts == {"key": 2, "mouse": 1, "gamepad": 1},
		"attack bindings are not exactly Space/J, left mouse, and gamepad X: %s" % attack_counts
	)

	var interact_events := InputMap.action_get_events("interact").duplicate()
	InputMap.action_erase_events("interact")
	_require(
		RunSceneInputRouterScript.run_action(_key_event(KEY_E)) == RunSceneInputRouterScript.ACTION_NONE,
		"router retained a hard-coded E bypass after the InputMap action was cleared"
	)
	for event: InputEvent in interact_events:
		InputMap.action_add_event("interact", event)

	for source_path in [
		"res://scripts/core/run/run_scene_input_router.gd",
		"res://scripts/gameplay/player/player_controller.gd",
		"res://scripts/ui/map_overlay/map_overlay_panel.gd",
	]:
		var source := FileAccess.get_file_as_string(source_path)
		_require(not source.contains("_event_matches_key"), "%s retained a raw-key matcher" % source_path)
		_require(not source.contains("Input.is_key_pressed"), "%s retained logical-key polling" % source_path)
		_require(not source.contains("Input.is_physical_key_pressed"), "%s retained physical-key polling" % source_path)


func _check_action_hint_descriptor() -> void:
	var interact := SemanticActionHintScript.descriptor(&"interact")
	_require(StringName(interact.get("descriptor_type", &"")) == &"action_hint", "ActionHintDescriptor type is missing")
	_require(int(interact.get("schema_version", 0)) == 1, "ActionHintDescriptor schema version drifted")
	_require(StringName(interact.get("action_id", &"")) == &"interact", "ActionHintDescriptor action ID drifted")
	_require(StringName(interact.get("source", &"")) == &"input_map", "ActionHintDescriptor bypassed InputMap")
	_require(String(interact.get("keyboard_mouse_label", "")).contains("E"), "keyboard hint omitted the mapped E key")
	_require(String(interact.get("gamepad_label", "")).contains("A"), "gamepad hint omitted the mapped A button")
	_require(String(interact.get("display_label", "")).contains("E"), "combined hint omitted keyboard")
	_require(String(interact.get("display_label", "")).contains("A"), "combined hint omitted gamepad")
	var gamepad_hint := SemanticActionHintScript.descriptor(&"interact", SemanticActionHintScript.DEVICE_GAMEPAD)
	_require(String(gamepad_hint.get("display_label", "")).contains("手柄 A"), "gamepad-preferred hint did not select gamepad copy")
	_require(not String(gamepad_hint.get("display_label", "")).contains(" · E"), "gamepad-preferred hint leaked keyboard copy")
	for action_fixture in [
		{"action": &"open_map", "label": "手柄 Y"},
		{"action": &"open_inventory", "label": "手柄 LB"},
		{"action": &"cancel", "label": "手柄 B"},
		{"action": &"pause", "label": "手柄菜单键"},
	]:
		var descriptor_data := SemanticActionHintScript.descriptor(
			StringName(action_fixture["action"]),
			SemanticActionHintScript.DEVICE_GAMEPAD
		)
		_require(
			String(descriptor_data.get("display_label", "")).contains(String(action_fixture["label"])),
			"%s gamepad hint drifted from InputMap" % String(action_fixture["action"])
		)
	var rendered := SemanticActionHintScript.replace_tokens(
		"按 {interact} 处理",
		[&"interact"],
		SemanticActionHintScript.DEVICE_KEYBOARD_MOUSE
	)
	_require(rendered == "按 E 处理", "semantic hint token did not resolve from the keyboard InputMap")
	var attack_hint := SemanticActionHintScript.descriptor(&"attack", SemanticActionHintScript.DEVICE_KEYBOARD_MOUSE)
	_require(
		String(attack_hint.get("display_label", "")).begins_with("鼠标左键"),
		"pointer attack is not presented as the primary PC combat gesture"
	)


func _check_modal_priority_and_focus() -> void:
	var host := Control.new()
	host.name = "I3RModalHost"
	root.add_child(host)
	var base_focus := _button("BaseFocus")
	host.add_child(base_focus)
	var pause := _modal(host, "Pause", "PauseFocus")
	var settings := _modal(host, "Settings", "SettingsFocus")
	var map := _modal(host, "Map", "MapFocus")
	var abandon := _modal(host, "Abandon", "AbandonFocus")
	var stack = ModalFocusStackScript.new()

	base_focus.grab_focus()
	await process_frame
	_require(root.gui_get_focus_owner() == base_focus, "base focus fixture did not settle")
	_require(stack.push(&"pause", pause["root"], pause["focus"]), "pause push failed")
	await process_frame
	_require(root.gui_get_focus_owner() == pause["focus"], "pause did not own focus")
	_require(stack.blocks_gameplay_input(), "blocking modal did not block gameplay input")
	_require(stack.push(&"settings", settings["root"], settings["focus"]), "settings did not nest above pause")
	await process_frame
	_require(stack.top_modal_id() == &"settings" and stack.depth() == 2, "nested modal order drifted")
	_require(root.gui_get_focus_owner() == settings["focus"], "nested settings did not own focus")
	_require(not bool((pause["root"] as Control).visible), "nested settings left the pause frame visible underneath")
	_require(not stack.push(&"map", map["root"], map["focus"]), "lower-priority map opened above settings")
	_require(stack.request_cancel_top(&"escape"), "nested settings Esc was not consumed")
	await process_frame
	_require(stack.top_modal_id() == &"pause" and stack.depth() == 1, "Esc closed more than the top modal")
	_require(bool((pause["root"] as Control).visible), "closing nested settings did not restore the pause frame")
	_require(root.gui_get_focus_owner() == pause["focus"], "nested close did not restore parent focus")
	_require(stack.push(&"abandon_confirm", abandon["root"], abandon["focus"]), "destructive confirmation did not nest above pause")
	await process_frame
	_require(not bool((pause["root"] as Control).visible), "destructive confirmation left the pause frame visible underneath")
	var policy_snapshot: Dictionary = stack.snapshot()
	_require(StringName(policy_snapshot.get("top_modal_id", &"")) == &"abandon_confirm", "modal policy snapshot lost top")
	_require(bool(policy_snapshot.get("blocks_gameplay_input", false)), "modal policy snapshot lost gameplay block")
	_require(ModalFocusStackScript.requires_confirmation(&"abandon_confirm"), "abandon is not marked for confirmation")
	_require(ModalFocusStackScript.requires_confirmation(&"combat_flee_confirm"), "combat flee is not marked for confirmation")
	_require(ModalFocusStackScript.requires_confirmation(&"warehouse_batch_sell"), "warehouse batch sale is not marked for confirmation")
	_require(not ModalFocusStackScript.requires_confirmation(&"event"), "reversible event modal gained a second confirmation")
	_require(not ModalFocusStackScript.requires_confirmation(&"settings"), "settings shell gained a generic second confirmation")
	var cancel := InputEventAction.new()
	cancel.action = &"cancel"
	cancel.pressed = true
	_require(stack.handle_cancel_event(cancel), "canonical cancel action was not consumed")
	await process_frame
	_require(stack.top_modal_id() == &"pause", "cancel action did not close the destructive top only")
	_require(bool((pause["root"] as Control).visible), "destructive cancel did not restore the pause frame")
	_require(stack.handle_cancel_event(cancel), "pause cancel was not consumed")
	await process_frame
	_require(stack.depth() == 0, "modal stack did not settle empty")
	_require(root.gui_get_focus_owner() == base_focus, "modal stack did not restore exact base focus")
	host.queue_free()
	await process_frame


func _check_production_authority() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production main scene did not load")
	if packed == null:
		return
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(5)
	var run_scene := main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing")
	if run_scene == null:
		main.queue_free()
		await _frames(2)
		return
	var bus: Variant = run_scene.get("command_bus")
	_require(bus != null, "production CommandBus is missing")
	if bus == null:
		main.queue_free()
		await _frames(2)
		return
	var start_result: Dictionary = bus.dispatch(&"start_demo_run")
	_require(bool(start_result.get("ok", false)), "production run fixture did not start")
	_require(bool(run_scene.call("_show_run_screen")), "production run screen did not open")
	await _frames(4)

	var player := run_scene.get("player_controller") as Node
	var inventory := run_scene.get("inventory_panel") as Control
	var runtime_stack: Variant = run_scene.get("modal_controller")
	var in_run_runtime: Variant = run_scene.get("in_run_runtime")
	_require(player != null and inventory != null and runtime_stack != null, "production input/modal fixtures are missing")
	var production_surface: Variant = run_scene.get("run_surface")
	var production_minimap := run_scene.get("minimap_panel") as Control
	var interaction_probe := G41InteractableScript.new()
	interaction_probe.name = "I3RInputHintInteractable"
	run_scene.add_child(interaction_probe)
	interaction_probe.configure_interactable({
		"interaction_id": "i3r_input_hint_probe",
		"interaction_kind": &"event",
		"prompt_text": "查看",
		"enabled": true,
	})
	interaction_probe.set_focused(true)
	await process_frame

	Input.parse_input_event(_key_event(KEY_SHIFT))
	await _frames(3)
	_require(
		RuntimeInputProfileScript.current_input_device() == RuntimeInputProfileScript.DEVICE_KEYBOARD_MOUSE,
		"real keyboard event did not select keyboard_mouse context"
	)
	_require(_surface_action_text(production_surface, &"interact").contains("E"), "keyboard context did not refresh the production interact action")
	var keyboard_minimap_hint := production_minimap.tooltip_text if production_minimap != null else ""
	_require(
		keyboard_minimap_hint.contains("Tab") or keyboard_minimap_hint.contains("M"),
		"keyboard context did not refresh the production minimap hint"
	)
	_require(_interactable_prompt_text(interaction_probe).contains("E"), "keyboard context did not refresh the production interactable hint")

	Input.parse_input_event(_joy_button(JOY_BUTTON_GUIDE))
	await _frames(3)
	_require(
		RuntimeInputProfileScript.current_input_device() == RuntimeInputProfileScript.DEVICE_GAMEPAD,
		"real joypad event did not select gamepad context"
	)
	_require(_surface_action_text(production_surface, &"interact").contains("手柄 A"), "gamepad context did not refresh the production interact action")
	_require(not _surface_action_text(production_surface, &"interact").contains(" E "), "gamepad interact action retained a keyboard key")
	_require(production_minimap != null and production_minimap.tooltip_text.contains("手柄 Y"), "gamepad context did not refresh the production minimap hint")
	_require(production_minimap == null or not production_minimap.tooltip_text.contains("Enter"), "production minimap retained its hard-coded Enter hint")
	_require(_interactable_prompt_text(interaction_probe).contains("手柄 A"), "gamepad context did not refresh the production interactable hint")
	_require(not _interactable_prompt_text(interaction_probe).contains("[E]"), "production interactable retained its hard-coded [E] hint")

	Input.parse_input_event(_key_event(KEY_SHIFT))
	await _frames(3)
	_require(
		RuntimeInputProfileScript.current_input_device() == RuntimeInputProfileScript.DEVICE_KEYBOARD_MOUSE,
		"later keyboard event did not restore keyboard_mouse context"
	)
	_require(_surface_action_text(production_surface, &"interact").contains("E"), "keyboard return did not restore the production interact action")
	_require(_interactable_prompt_text(interaction_probe).contains("E"), "keyboard return did not restore the production interactable hint")
	if player != null:
		player.call("set_local_position", Vector2(0.25, 0.25))
		_require(bool(player.get("input_enabled")), "production player input did not start enabled")
	if in_run_runtime == null or not bool(in_run_runtime.call("has_active_combat")):
		var facing_before_pointer: Vector2 = player.call("get_facing_vector") if player != null else Vector2.ZERO
		var room_center := Vector2(640.0, 360.0)
		_require(
			not bool(run_scene.call("_handle_run_action_input", _mouse_button(MOUSE_BUTTON_LEFT, room_center))),
			"non-combat room consumed a pointer attack"
		)
		_require(
			player == null or (player.call("get_facing_vector") as Vector2).is_equal_approx(facing_before_pointer),
			"non-combat pointer attack turned the player"
		)
	_require(bool(run_scene.call("_handle_run_action_input", _key_event(KEY_Q))), "production Q action was not consumed")
	await _frames(2)
	_require(inventory != null and inventory.visible, "production Q action did not open inventory")
	_require(runtime_stack != null and runtime_stack.call("top_modal_id") == &"inventory", "inventory did not enter the authoritative modal stack")
	if player != null:
		_require(not bool(player.get("input_enabled")), "inventory modal left PlayerController polling movement")
		var modal_facing: Vector2 = player.call("get_facing_vector")
		Input.action_press("move_right")
		player.call("_process", 0.20)
		Input.action_release("move_right")
		_require(
			(player.call("get_facing_vector") as Vector2).is_equal_approx(modal_facing),
			"held movement changed the background player facing under inventory"
		)
	var inventory_focus := root.gui_get_focus_owner()
	_require(
		bool(run_scene.call("_handle_run_action_input", _joy_button(JOY_BUTTON_Y))),
		"virtual gamepad Y did not open the map above inventory"
	)
	await _frames(3)
	_require(
		runtime_stack.call("top_modal_id") == &"map" and int(runtime_stack.call("depth")) == 2,
		"nested map did not become the top modal"
	)
	if player != null:
		_require(not bool(player.get("input_enabled")), "expanded map re-enabled PlayerController behind its modal")
	_require(bool(run_scene.call("_handle_cancel_input", _joy_button(JOY_BUTTON_B))), "map B cancel was not consumed")
	await _frames(3)
	_require(
		runtime_stack.call("top_modal_id") == &"inventory" and int(runtime_stack.call("depth")) == 1,
		"map B cancel closed more than the map"
	)
	_require(inventory == null or inventory.visible, "map B cancel hid the parent inventory")
	_require(inventory_focus == null or root.gui_get_focus_owner() == inventory_focus, "map B cancel did not restore inventory focus")
	_require(bool(run_scene.call("_handle_cancel_input", _joy_button(JOY_BUTTON_B))), "virtual gamepad B did not close inventory")
	await _frames(2)
	_require(inventory == null or not inventory.visible, "virtual gamepad B left inventory visible")
	if player != null:
		_require(bool(player.get("input_enabled")), "PlayerController input did not resume after inventory and map closed")

	_require(bool(run_scene.call("_handle_cancel_input", _joy_button(JOY_BUTTON_START))), "virtual gamepad Start did not open pause")
	await _frames(2)
	_require(runtime_stack.call("top_modal_id") == &"pause", "pause did not become the top modal")
	if player != null:
		_require(not bool(player.get("input_enabled")), "pause modal left PlayerController input enabled")
		var paused_position: Vector2 = player.call("get_local_position")
		Input.action_press("move_right")
		run_scene.call("_process", 0.25)
		Input.action_release("move_right")
		_require(
			(player.call("get_local_position") as Vector2).is_equal_approx(paused_position),
			"paused gameplay accepted movement input"
		)
	var settings_button := run_scene.get("pause_settings_button") as Button
	if settings_button != null:
		settings_button.grab_focus()
	run_scene.call("_open_settings_from_pause")
	await _frames(3)
	_require(runtime_stack.call("top_modal_id") == &"settings", "settings did not nest above pause")
	if player != null:
		_require(not bool(player.get("input_enabled")), "runtime settings re-enabled PlayerController behind pause")
	_require(bool(run_scene.call("_handle_cancel_input", _joy_button(JOY_BUTTON_B))), "settings B cancel was not consumed")
	await _frames(3)
	_require(runtime_stack.call("top_modal_id") == &"pause", "settings B cancel closed the pause parent")
	_require(settings_button == null or root.gui_get_focus_owner() == settings_button, "settings close did not restore pause focus")
	_require(bool(run_scene.call("_handle_cancel_input", _key_event(KEY_ESCAPE))), "pause Esc was not consumed")
	await _frames(2)
	_require(int(runtime_stack.call("depth")) == 0, "pause Esc left a stale runtime modal")
	if player != null:
		var active_position: Vector2 = player.call("get_local_position")
		Input.action_press("move_right")
		run_scene.call("_process", 0.25)
		Input.action_release("move_right")
		_require(
			(player.call("get_local_position") as Vector2).x > active_position.x,
			"gameplay movement did not resume after the modal stack closed"
		)
		_require(bool(player.get("input_enabled")), "modal stack closed without restoring PlayerController input")

	var context: Variant = run_scene.get("run_context")
	if context != null and player != null:
		context.tutorial_popup = {
			"id": &"i3r_input_authority_probe",
			"blocking": true,
			"title": "Input authority probe",
			"body": "Blocking tutorial copy owns input.",
			"confirm_label": "Continue",
		}
		run_scene.call("_sync_player_input_enabled")
		_require(not bool(player.get("input_enabled")), "blocking tutorial left PlayerController input enabled")
		var tutorial_facing: Vector2 = player.call("get_facing_vector")
		Input.action_press("move_left")
		player.call("_process", 0.20)
		Input.action_release("move_left")
		_require(
			(player.call("get_facing_vector") as Vector2).is_equal_approx(tutorial_facing),
			"held movement changed the background player facing under a blocking tutorial"
		)
		context.tutorial_popup.clear()
		run_scene.call("_sync_player_input_enabled")
		_require(bool(player.get("input_enabled")), "tutorial close did not restore PlayerController input")

	run_scene.call("reset_refresh_metrics")
	run_scene.call("_pickup_floor_from_ui", "__i3r_missing_pickup__")
	run_scene.call("_replace_floor_from_ui", "__i3r_missing_ground__", "__i3r_missing_drop__")
	run_scene.call("_drop_inventory_from_ui", "__i3r_missing_drop__")
	run_scene.call("_use_inventory_item_from_ui", "__i3r_missing_use__")
	var item_refresh_metrics: Dictionary = run_scene.call("get_refresh_metrics")
	_require(
		int(item_refresh_metrics.get("full_count", -1)) == 4,
		"four signaled item commands did not produce exactly four full refreshes"
	)
	if context != null:
		context.tutorial_popup = {
			"id": &"i3r_unsignaled_refresh_probe",
			"blocking": true,
			"title": "Refresh fallback probe",
			"body": "A blocked command emits no state signal.",
			"confirm_label": "Continue",
		}
		run_scene.call("_sync_player_input_enabled")
		run_scene.call("reset_refresh_metrics")
		run_scene.call("_pickup_floor_from_ui", "__i3r_blocked_pickup__")
		var fallback_refresh_metrics: Dictionary = run_scene.call("get_refresh_metrics")
		_require(
			int(fallback_refresh_metrics.get("full_count", -1)) == 1,
			"unsignaled blocked item command did not receive exactly one fallback refresh"
		)
		context.tutorial_popup.clear()
		run_scene.call("_sync_player_input_enabled")

	var feedback_service: Variant = run_scene.get("player_feedback_service")
	if feedback_service != null:
		feedback_service.call("clear_history_and_deduplication")
		run_scene.call("_reset_transition_rejection_debounce")
		var combat_lock_feedback := {
			"ok": false,
			"accepted": false,
			"status": &"combat_door_locked",
			"reason": &"combat_door_locked",
			"message": "Combat door locked.",
		}
		_require(
			bool(run_scene.call("_present_transition_rejection", Vector2i.RIGHT, combat_lock_feedback)),
			"first combat-door rejection was suppressed"
		)
		_require(
			not bool(run_scene.call("_present_transition_rejection", Vector2i.RIGHT, combat_lock_feedback)),
			"held combat-door rejection repeated without an input edge"
		)
		run_scene.call("_advance_transition_rejection_debounce", 0.50, Vector2.RIGHT)
		_require(
			not bool(run_scene.call("_present_transition_rejection", Vector2i.RIGHT, combat_lock_feedback)),
			"cooldown expiry bypassed the held-direction edge latch"
		)
		run_scene.call("_advance_transition_rejection_debounce", 0.0, Vector2.ZERO)
		_require(
			bool(run_scene.call("_present_transition_rejection", Vector2i.RIGHT, combat_lock_feedback)),
			"released combat-door direction could not produce a later legal retry feedback"
		)
		_require(
			(feedback_service.call("history") as Array).size() == 2,
			"combat-door debounce did not suppress duplicate audio/haptic feedback"
		)
		run_scene.call("_reset_transition_rejection_debounce")

	run_scene.call("_show_deploy_shell", &"config")
	await _frames(4)
	var deploy := run_scene.get("deploy_shell_panel") as Control
	_require(deploy != null, "production Deploy page is missing")
	if deploy != null:
		var deploy_intents: Array[Dictionary] = []
		var deploy_meta_actions: Array[Dictionary] = []
		deploy.deploy_start_intent_requested.connect(
			func(intent: Dictionary) -> void: deploy_intents.append(intent)
		)
		deploy.meta_action_requested.connect(
			func(action: Dictionary) -> void: deploy_meta_actions.append(action)
		)
		var deploy_focus := deploy.get("primary_action_button") as Button
		if deploy_focus != null:
			deploy_focus.grab_focus()
		deploy.call("_show_cancel_modal")
		await _frames(3)
		var deploy_stack: Variant = deploy.get("modal_focus_stack")
		_require(deploy_stack != null and deploy_stack.call("top_modal_id") == &"deploy_abandon", "Deploy destructive confirmation did not enter its modal stack")
		_require(bool(run_scene.call("_handle_cancel_input", _key_event(KEY_ESCAPE))), "RunScene did not delegate Deploy Esc")
		await _frames(3)
		_require(deploy_stack != null and int(deploy_stack.call("depth")) == 0, "Deploy Esc left a stale destructive modal")
		_require(StringName(run_scene.get("screen_state")) == &"deploy_shell", "Deploy modal Esc jumped to another page")
		_require(deploy_focus == null or root.gui_get_focus_owner() == deploy_focus, "Deploy modal Esc did not restore exact focus")
		var deploy_intent_count_after_cancel := deploy_intents.size()
		deploy.call("_confirm_cancel_active_run")
		await _frames(2)
		_require(
			deploy_intents.size() == deploy_intent_count_after_cancel,
			"stale Deploy abandon confirmation emitted after cancellation"
		)
		_require(
			deploy_stack != null and int(deploy_stack.call("depth")) == 0,
			"stale Deploy abandon confirmation changed the empty modal stack"
		)
		deploy.set("warehouse_batch_active", true)
		deploy.set("warehouse_batch_selected_ids", ["i3r_stale_sell_probe"])
		deploy.call("_show_warehouse_batch_confirmation")
		await _frames(2)
		_require(
			deploy_stack != null and deploy_stack.call("top_modal_id") == &"warehouse_batch_sell",
			"warehouse destructive confirmation bypassed the Deploy modal stack"
		)
		deploy.call("_confirm_cancel_active_run")
		await _frames(2)
		_require(
			deploy_intents.size() == deploy_intent_count_after_cancel,
			"Deploy abandon confirmation submitted under the wrong top modal"
		)
		_require(
			deploy_stack != null and deploy_stack.call("top_modal_id") == &"warehouse_batch_sell",
			"wrong-top Deploy abandon confirmation closed the warehouse modal"
		)
		_require(bool(run_scene.call("_handle_cancel_input", _joy_button(JOY_BUTTON_B))), "warehouse B cancel was not consumed")
		await _frames(3)
		_require(deploy_stack != null and int(deploy_stack.call("depth")) == 0, "warehouse B cancel left a stale modal")
		_require(StringName(run_scene.get("screen_state")) == &"deploy_shell", "warehouse modal B jumped to another page")
		_require(deploy_focus == null or root.gui_get_focus_owner() == deploy_focus, "warehouse B cancel did not restore Deploy focus")
		var deploy_meta_count_after_cancel := deploy_meta_actions.size()
		deploy.call("_confirm_warehouse_batch_sell")
		await _frames(2)
		_require(
			deploy_meta_actions.size() == deploy_meta_count_after_cancel,
			"stale warehouse confirmation submitted after cancellation"
		)
		_require(
			deploy_stack != null and int(deploy_stack.call("depth")) == 0,
			"stale warehouse confirmation changed the empty modal stack"
		)
		deploy.call("_show_cancel_modal")
		await _frames(2)
		_require(
			deploy_stack != null and deploy_stack.call("top_modal_id") == &"deploy_abandon",
			"Deploy abandon fixture did not own the top before wrong-top warehouse confirmation"
		)
		deploy.call("_confirm_warehouse_batch_sell")
		await _frames(2)
		_require(
			deploy_meta_actions.size() == deploy_meta_count_after_cancel,
			"warehouse confirmation submitted under the wrong top modal"
		)
		_require(
			deploy_stack != null and deploy_stack.call("top_modal_id") == &"deploy_abandon",
			"wrong-top warehouse confirmation closed the Deploy abandon modal"
		)
		_require(bool(run_scene.call("_handle_cancel_input", _key_event(KEY_ESCAPE))), "wrong-top Deploy fixture Esc was not consumed")
		await _frames(3)
		_require(deploy_stack != null and int(deploy_stack.call("depth")) == 0, "wrong-top Deploy fixture left a stale modal")

		var unconfirmed_abandon := NavigationIntentScript.make_run(
			&"deploy_prep",
			{
				"entry_id": &"i3r_unconfirmed_deploy_abandon",
				"uses_existing_route": true,
				"abandon_active_run": true,
				"reason": "i3r_unconfirmed_deploy_abandon",
				"confirmed": false,
			}
		)
		deploy.emit_signal("deploy_start_intent_requested", unconfirmed_abandon)
		await _frames(3)
		_require(StringName(run_scene.get("screen_state")) == &"deploy_shell", "unconfirmed Deploy abandon left the Deploy screen")
		_require(context != null and bool(context.get("run_active")), "unconfirmed Deploy abandon changed the active run")
		_require(StringName((run_scene.get("last_command_result") as Dictionary).get("status", &"")) == &"abandon_confirmation_required", "unconfirmed Deploy abandon bypassed the CommandBus gate")
		var deploy_feedback := deploy.get("summary_message_label") as Label
		_require(
			deploy_feedback != null and deploy_feedback.is_visible_in_tree() and deploy_feedback.text.contains("再次确认"),
			"rejected Deploy abandon did not leave player-visible feedback on Deploy"
		)

		var abandoning_run_id := String(context.get("run_id")) if context != null else ""
		deploy.call("_show_cancel_modal")
		await _frames(2)
		var deploy_abandon_confirm := deploy.get("modal_confirm_button") as Button
		_require(deploy_stack != null and deploy_stack.call("top_modal_id") == &"deploy_abandon", "real Deploy abandon confirmation did not own the top")
		_require(deploy_abandon_confirm != null and not deploy_abandon_confirm.disabled, "real Deploy abandon confirmation is not actionable")
		if deploy_abandon_confirm != null:
			deploy_abandon_confirm.emit_signal("pressed")
		await _frames(6)
		var deploy_result_panel := run_scene.get("result_panel") as Control
		var run_overlay := run_scene.get("run_overlay_root") as Control
		var production_shell := run_scene.get("ui_shell") as Control
		_require(StringName(run_scene.get("screen_state")) == &"run", "successful Deploy abandon did not switch to the result screen")
		_require(run_overlay != null and run_overlay.is_visible_in_tree(), "successful Deploy abandon left the result overlay hidden")
		_require(production_shell != null and not production_shell.visible, "successful Deploy abandon left the Deploy shell above the result")
		_require(deploy_result_panel != null and deploy_result_panel.is_visible_in_tree(), "successful Deploy abandon result is not player-visible")
		_require(runtime_stack.call("top_modal_id") == &"result" and int(runtime_stack.call("depth")) == 1, "successful Deploy abandon did not enter the result modal lifecycle")
		var deploy_result_focus := root.gui_get_focus_owner()
		_require(deploy_result_focus != null and deploy_result_panel.is_ancestor_of(deploy_result_focus), "successful Deploy abandon result did not capture focus")
		_require(context != null and not bool(context.get("run_active")) and String(context.get("run_id")) == abandoning_run_id, "Deploy abandon fell through into a new run")
		_require(bool(run_scene.call("_handle_cancel_input", _key_event(KEY_ESCAPE))), "Deploy-origin result Esc was not consumed")
		await _frames(6)
		_require(StringName(run_scene.get("screen_state")) == &"deploy_shell", "Deploy-origin result Esc did not return to Deploy")
		_require(int(runtime_stack.call("depth")) == 0 and (deploy_result_panel == null or not deploy_result_panel.visible), "Deploy-origin result Esc left a stale result modal")
		_require(run_overlay != null and not run_overlay.visible and deploy.is_visible_in_tree(), "Deploy-origin result Esc restored inconsistent screen layers")

	var restart_result: Dictionary = bus.dispatch(&"start_demo_run")
	_require(bool(restart_result.get("ok", false)), "pause-abandon fixture could not start after the Deploy result closed")
	_require(bool(run_scene.call("_show_run_screen")), "active run did not resume for terminal modal validation")
	await _frames(3)
	run_scene.call("_show_pause_panel")
	run_scene.call("_request_abandon_from_pause")
	await _frames(2)
	_require(runtime_stack.call("top_modal_id") == &"abandon_confirm", "abandon confirmation did not own the top")
	run_scene.call("_confirm_abandon_from_pause")
	await _frames(5)
	_require(runtime_stack.call("top_modal_id") == &"result", "terminal result did not replace abandon confirmation")
	_require(bool(run_scene.call("_handle_cancel_input", _joy_button(JOY_BUTTON_B))), "result B cancel was not consumed")
	await _frames(6)
	_require(int(runtime_stack.call("depth")) == 0, "result B cancel left a stale runtime modal")
	_require(StringName(run_scene.get("screen_state")) == &"deploy_shell", "result B cancel did not route to Deploy")

	run_scene.call("_show_main_menu")
	await _frames(3)
	var shell := run_scene.get("ui_shell") as Control
	var main_page := run_scene.get("main_menu_panel") as Control
	var main_focus := _first_focusable(main_page)
	if main_focus != null:
		main_focus.grab_focus()
	await process_frame
	if shell != null:
		shell.call("_show_exit_confirm")
	await _frames(2)
	_require(shell != null and StringName((shell.call("modal_policy_snapshot") as Dictionary).get("top_modal_id", &"")) == &"exit_confirm", "AppShell exit confirmation bypassed modal authority")
	_require(bool(run_scene.call("_handle_cancel_input", _joy_button(JOY_BUTTON_B))), "AppShell exit B cancel was not consumed")
	await _frames(3)
	_require(shell != null and int((shell.call("modal_policy_snapshot") as Dictionary).get("depth", -1)) == 0, "AppShell exit cancel left a stale modal")
	_require(main_focus == null or root.gui_get_focus_owner() == main_focus, "AppShell exit cancel did not restore exact main-menu focus")

	main.queue_free()
	await _frames(4)


func _surface_action_text(surface: Variant, action_id: StringName) -> String:
	if surface == null:
		return ""
	var buttons: Dictionary = surface.get("action_buttons")
	var button := buttons.get(action_id) as Button
	return button.text if button != null else ""


func _interactable_prompt_text(interactable: Node) -> String:
	if interactable == null:
		return ""
	var prompt := interactable.get_node_or_null("PromptAnchor/InteractionPrompt") as Label
	return prompt.text if prompt != null else ""


func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.device = 0
	event.physical_keycode = keycode
	event.pressed = true
	return event


func _joy_button(button_index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button_index
	event.pressed = true
	event.pressure = 1.0
	return event


func _mouse_button(button_index: MouseButton, position := Vector2.ZERO) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.device = 0
	event.button_index = button_index
	event.position = position
	event.pressed = true
	return event


func _action_event_counts() -> Dictionary:
	var result := {}
	for action_name in RuntimeInputProfileScript.semantic_action_names():
		result[action_name] = InputMap.action_get_events(action_name).size()
	return result


func _button(control_name: String) -> Button:
	var button := Button.new()
	button.name = control_name
	button.text = control_name
	button.focus_mode = Control.FOCUS_ALL
	return button


func _modal(host: Control, modal_name: String, focus_name: String) -> Dictionary:
	var modal := Control.new()
	modal.name = modal_name
	host.add_child(modal)
	var focus := _button(focus_name)
	modal.add_child(focus)
	modal.hide()
	return {"root": modal, "focus": focus}


func _first_focusable(node: Node) -> Control:
	if node == null:
		return null
	if node is Control:
		var control := node as Control
		if (
			control.focus_mode != Control.FOCUS_NONE
			and control.is_visible_in_tree()
			and not (control is BaseButton and (control as BaseButton).disabled)
		):
			return control
	for child in node.get_children():
		var found := _first_focusable(child)
		if found != null:
			return found
	return null


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("%s input=input_map_only hints=descriptor_v1 devices=keyboard,virtual_gamepad modal=lifo,priority,focus pause=blocked shell=delegated destructive=explicit" % PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error("I3R input/modal authority failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
