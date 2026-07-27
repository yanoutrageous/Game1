extends SceneTree

const EventServiceScript := preload("res://scripts/core/run/event_service.gd")
const ProjectionScript := preload("res://scripts/gameplay/runtime/g41_world_object_projection.gd")
const RoomViewScript := preload("res://scripts/gameplay/runtime/g41_room_runtime_view.gd")
const ActorViewScript := preload("res://scripts/gameplay/runtime/g41_runtime_actor_view.gd")
const RunSurfaceModelScript := preload("res://scripts/ui/run_surface/run_surface_model.gd")
const RunUIViewModelScript := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const HUDViewModelScript := preload("res://scripts/ui/hud/hud_view_model.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")

var failures: Array[String] = []
var context_actions: Array[Dictionary] = []
var room_entry_feedback: Array[Dictionary] = []
var production_command_counts: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check_structured_event_options()
	_check_event_room_entry_copy()
	_check_event_result_feedback()
	_check_player_copy_scrub()
	_check_special_room_projections()
	await _check_special_world_interactions()
	await _check_production_proximity_authority()
	await _check_monster_appearance_envelope()
	await _check_mine_authority_and_presentation()
	_check_exit_first_discovery_authority()
	_check_no_presentation_authority()
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _check_structured_event_options() -> void:
	for event_type: StringName in [&"trader", &"dice", &"altar", &"trap"]:
		var options := EventServiceScript.get_event_options(null, Vector2i(2, 2), event_type, false)
		_check(not options.is_empty(), "Event %s exposed no options" % event_type)
		for option in options:
			for field in ["player_title", "player_cost", "player_effect", "player_disabled_reason", "requires_confirmation"]:
				_check(option.has(field), "Event %s option omitted public field %s" % [event_type, field])
			var cost: Dictionary = option.get("player_cost", {})
			for cost_field in ["kind", "amount", "display_text"]:
				_check(cost.has(cost_field), "Event %s option omitted cost field %s" % [event_type, cost_field])
			var poisoned := option.duplicate(true)
			poisoned["label"] = "RAW_LEGACY_LABEL"
			poisoned["disabled_reason"] = "raw_disabled_reason"
			var label := RunSurfaceModelScript.event_option_label(event_type, poisoned)
			var detail := RunSurfaceModelScript.event_option_detail(poisoned)
			_check(not label.contains("RAW_LEGACY_LABEL") and not detail.contains("RAW_LEGACY_LABEL"), "Event presenter consumed legacy label")
			_check(not label.contains("raw_disabled_reason") and not detail.contains("raw_disabled_reason"), "Event presenter exposed raw disabled reason")
	var completed := EventServiceScript.get_event_options(null, Vector2i.ZERO, &"trader", true)
	_check(completed.size() == 1 and String((completed[0] as Dictionary).get("player_title", "")) == "返回探索", "Completed event lacks one player-facing return option")
	var controller = RunRuntimeControllerScript.new()
	var started: Dictionary = controller.command_bus.dispatch(&"start_standard_run", {"source": "i2_event_copy_fixture"})
	_check(bool(started.get("ok", false)), "Raw item-id copy fixture could not start")
	if bool(started.get("ok", false)):
		controller.context.asset_ledger.create_item_instance({
			"item_id": "RAW_INTERNAL_ITEM_ID",
			"base_value": 8,
			"can_sell": true,
		}, RunAssetLedger.LOCATION_INVENTORY)
		var trader_options := EventServiceScript.get_event_options(controller.context, Vector2i.ZERO, &"trader", false)
		var trader_copy := ""
		for option in trader_options:
			trader_copy += "%s\n%s\n" % [option.get("player_title", ""), option.get("player_effect", "")]
		_check(not trader_copy.contains("RAW_INTERNAL_ITEM_ID"), "Trader player copy exposed a raw item_id")
	_release_controller(controller)


func _check_event_room_entry_copy() -> void:
	var expected_labels := {
		&"trader": "旅商",
		&"dice": "骰局",
		&"altar": "祭坛",
		&"trap": "机关",
	}
	for event_type: StringName in expected_labels.keys():
		var controller = _event_controller_for(event_type)
		var context = controller.context
		var actual_entry_message := String(context.last_message)
		_check(actual_entry_message.begins_with("Event available: %s." % event_type), "Real %s room entry did not exercise the legacy Event available path: %s" % [event_type, actual_entry_message])
		var injected_messages: Array[String] = [actual_entry_message]
		if event_type == &"trader":
			# Historical/capture fixtures have also carried the traveler spelling.
			# The structured event_state, never this raw enum, must own the label.
			injected_messages.append("Event available: traveler.")
		for injected_message in injected_messages:
			context.last_message = injected_message
			var snapshot: Dictionary = context.get_status_snapshot()
			var model: Dictionary = RunSurfaceModelScript.build(snapshot, null, {}, {})
			var encounter: Dictionary = model.get("encounter_section", {})
			_check(
				StringName(encounter.get("encounter_type", &"none")) == event_type,
				"Real %s room lost its encounter type before presentation routing" % event_type
			)
			var hud = HUDViewModelScript.build_from_snapshot(snapshot)
			var visible_copy := "%s\n%s\n%s\n%s\n%s\n%s" % [
				model.get("command_feedback", ""),
				model.get("reward_summary", ""),
				model.get("event_summary", ""),
				model.get("event_panel_summary", ""),
				encounter.get("body", ""),
				hud.hint_text,
			]
			var lowered := visible_copy.to_lower()
			for token in ["event available", "trader", "traveler", "merchant", "dice", "altar", "trap", "event_type"]:
				_check(not lowered.contains(token), "Real %s room-entry presenter exposed English enum/token %s: %s" % [event_type, token, visible_copy])
			_check(visible_copy.contains(String(expected_labels[event_type])), "Real %s room-entry presenter lost its structured player label: %s" % [event_type, visible_copy])
		_release_controller(controller)


func _check_event_result_feedback() -> void:
	var leave_controller = _event_controller_for(&"trader")
	var leave_context = leave_controller.context
	var leave_pos: Vector2i = leave_context.get_current_pos()
	leave_context.last_reward = {"event_type": &"dice", "option_id": &"bet_small", "message": "OLD_LAST_REWARD_SENTINEL"}
	var leave_result := EventServiceScript.execute_option(leave_context, leave_pos, &"leave")
	var leave_copy := RunSurfaceModelScript.event_result_feedback_text(leave_result)
	_check(bool(leave_result.get("ok", false)) and not bool(leave_result.get("completed", true)), "Event leave did not return a structured intermediate result")
	_check(StringName((leave_context.last_reward as Dictionary).get("option_id", &"")) == &"leave", "Event leave reused the previous last_reward")
	_check(leave_copy.contains("离开") and not leave_copy.contains("OLD_LAST_REWARD_SENTINEL") and not leave_copy.contains("处理完成"), "Event leave feedback was not based on its current structured result: %s" % leave_copy)
	_release_controller(leave_controller)

	var altar_controller = _event_controller_for(&"altar")
	var altar_context = altar_controller.context
	altar_context.hp = altar_context.max_hp
	var altar_result := EventServiceScript.execute_option(altar_context, altar_context.get_current_pos(), &"offer_hp")
	var altar_copy := RunSurfaceModelScript.event_result_feedback_text(altar_result)
	_check(bool(altar_result.get("ok", false)) and not bool(altar_result.get("completed", true)), "First altar stage did not remain intermediate")
	_check(int(altar_result.get("altar_stage", 0)) == 1 and int(altar_result.get("altar_stage_total", 0)) == 5, "Altar intermediate result omitted its structured stage")
	_check(altar_copy.contains("第 1/5 阶段") and altar_copy.contains("仍可继续"), "Altar intermediate feedback was presented as unconditional completion: %s" % altar_copy)
	_release_controller(altar_controller)

	for event_type: StringName in [&"trader", &"dice"]:
		var controller = _event_controller_for(event_type)
		var context = controller.context
		if event_type == &"trader":
			context.asset_ledger.create_item_instance({
				"item_id": "real_trader_fixture",
				"display_name": "旧徽章",
				"base_value": 8,
				"can_sell": true,
			}, RunAssetLedger.LOCATION_INVENTORY)
		else:
			context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, EventServiceScript.DICE_BET + 50, "i2_real_dice_fixture")
		var option_id := &"sell_best_item" if event_type == &"trader" else &"bet_small"
		var real_result := EventServiceScript.execute_option(context, context.get_current_pos(), option_id)
		_check(bool(real_result.get("ok", false)), "Real %s event fixture did not resolve" % event_type)
		context.last_reward["message"] = "MetaProgress black_coin RAW_RULE_MESSAGE"
		context.last_reward["messages"] = ["MetaProgress black_coin RAW_RULE_MESSAGE"]
		context.last_message = "MetaProgress black_coin RAW_RULE_MESSAGE"
		var model: Dictionary = RunSurfaceModelScript.build(context.get_status_snapshot(), null, {}, {})
		var encounter: Dictionary = model.get("encounter_section", {})
		var player_copy := "%s\n%s\n%s" % [encounter.get("result_summary", ""), model.get("command_feedback", ""), model.get("reward_summary", "")]
		for token in ["MetaProgress", "black_coin", "RAW_RULE_MESSAGE"]:
			_check(not player_copy.contains(token), "Real %s event exposed engineering token %s: %s" % [event_type, token, player_copy])
		_check(player_copy.contains("安全收益") if event_type == &"trader" else player_copy.contains("骰局"), "Real %s event lacked mapped player copy: %s" % [event_type, player_copy])
		_release_controller(controller)


func _event_controller_for(event_type: StringName):
	var controller = RunRuntimeControllerScript.new()
	var started: Dictionary = controller.command_bus.dispatch(&"start_standard_run", {"source": "i2_event_result_fixture"})
	_check(bool(started.get("ok", false)), "Event result fixture could not start")
	var context = controller.context
	var target := _find_event_position(context, event_type)
	_check(target.x >= 0, "Event result fixture contains no %s position" % event_type)
	if target.x >= 0:
		context.truth_map.set_room_type(target, &"Event")
		context.player_pos = target
		context.current_pos = target
		context.interacted_cells.erase(context.cell_key(target))
		context.intel_map.reveal_cell(target, context.truth_map)
		controller.command_bus.room_resolver.enter_room(context)
	return controller


func _find_event_position(context, event_type: StringName) -> Vector2i:
	for y in range(context.height):
		for x in range(context.width):
			var pos := Vector2i(x, y)
			if EventServiceScript.get_event_type(context, pos) == event_type:
				return pos
	return Vector2i(-1, -1)


func _check_player_copy_scrub() -> void:
	var legacy_item := {
		"instance_id": "legacy_raw_item",
		"item_id": "RAW_INTERNAL_ITEM_ID",
		"display_name": "RAW_INTERNAL_ITEM_ID",
		"rarity": &"tier_1",
		"weight": 1,
	}
	_check(not RunUIViewModelScript.item_display_line(legacy_item).contains("RAW_INTERNAL_ITEM_ID"), "Quick-backpack item line exposed a raw item_id")
	_check(not RunUIViewModelScript.item_tooltip(legacy_item).contains("RAW_INTERNAL_ITEM_ID"), "Item detail exposed a raw item_id")
	var legacy_result_item := RunUIViewModelScript.result_item_model(legacy_item)
	_check(not String(legacy_result_item.get("display_name", "")).contains("RAW_INTERNAL_ITEM_ID"), "Result item model exposed a raw item_id")
	var snapshot := _snapshot(&"Mine", Vector2i(1, 1))
	snapshot.merge({
		"run_active": true,
		"phase": &"running",
		"current_room_detail": {
			"room_type_key": &"mine",
			"known_state": &"revealed",
			"visibility": &"visible",
			"RoomPolicy": {"entry_policy": &"RAW_POLICY_SENTINEL"},
			"EncounterPreview": {"encounter_type": &"RAW_SCHEMA_SENTINEL"},
		},
		"encounter_view_model": {
			"encounter_type": &"RAW_TYPE_SENTINEL",
			"state": {"state": &"RAW_STATE_SENTINEL", "title": "RAW_TITLE_SENTINEL", "description": "RAW_DESCRIPTION_SENTINEL"},
			"options": [{
				"id": &"RAW_OPTION_ID_SENTINEL",
				"title": "RAW_OPTION_TITLE_SENTINEL",
				"command_name": &"RAW_COMMAND_SENTINEL",
				"command_payload": {},
				"disabled_reason": "RAW_DISABLED_SENTINEL",
			}],
		},
	}, true)
	var model: Dictionary = RunSurfaceModelScript.build(snapshot, null, {}, {})
	var encounter: Dictionary = model.get("encounter_section", {})
	var visible_copy := "%s\n%s\n%s" % [encounter.get("title", ""), encounter.get("body", ""), encounter.get("result_summary", "")]
	for raw_option in (encounter.get("options", []) as Array):
		if raw_option is Dictionary:
			visible_copy += "\n%s\n%s\n%s" % [(raw_option as Dictionary).get("title", ""), (raw_option as Dictionary).get("summary", ""), (raw_option as Dictionary).get("disabled_reason", "")]
	visible_copy += "\n%s\n%s" % [model.get("room_common_rule_summary", ""), model.get("encounter_preview_summary", "")]
	for sentinel in ["RAW_", "command", "schema", "policy", "option payload"]:
		_check(not visible_copy.to_lower().contains(sentinel.to_lower()), "Player-facing room copy exposed engineering token %s: %s" % [sentinel, visible_copy])


func _check_special_room_projections() -> void:
	for event_type: StringName in [&"trader", &"dice", &"altar", &"trap"]:
		var snapshot := _snapshot(&"Event", Vector2i(1, 1))
		snapshot["event_state"] = {"event_type": event_type, "completed": false}
		var event := _projection_of_kind(ProjectionScript.build(snapshot), &"event")
		_check(not event.is_empty(), "Event %s lacks a world projection" % event_type)
		_check(String(event.get("visual_key", "")) == "ui.art25.long_term.event.%s" % event_type, "Event %s does not use its ART25 badge" % event_type)
		_check(not bool((event.get("payload", {}) as Dictionary).get("display_only", true)), "Open Event %s became read-only" % event_type)
	var completed_snapshot := _snapshot(&"Event", Vector2i(1, 1))
	completed_snapshot["event_state"] = {"event_type": &"altar", "completed": true}
	var completed_event := _projection_of_kind(ProjectionScript.build(completed_snapshot), &"event")
	_check(bool((completed_event.get("payload", {}) as Dictionary).get("display_only", false)), "Completed Event remained actionable")
	var revisit_snapshot := _completed_event_revisit_snapshot()
	var revisited_event := _projection_of_kind(ProjectionScript.build(revisit_snapshot), &"event")
	var revisited_payload: Dictionary = revisited_event.get("payload", {})
	_check(bool(revisited_payload.get("completed", false)) and bool(revisited_payload.get("display_only", false)), "Completed Event became actionable after leaving and revisiting with an empty transient event_state")
	_check(StringName(revisited_payload.get("event_type", &"")) in [&"trader", &"dice", &"altar", &"trap"], "Completed Event lost its type after revisit")

	var mine_snapshot := _snapshot(&"Mine", Vector2i(2, 1))
	mine_snapshot["current_room_detail"] = {"triggered": true}
	var mine := _projection_of_kind(ProjectionScript.build(mine_snapshot), &"mine")
	_check(StringName(mine.get("visual_key", &"")) == &"visual.art24.prop.mine", "Mine does not reuse the approved mine asset")
	_check(bool((mine.get("payload", {}) as Dictionary).get("display_only", false)), "Mine projection is actionable")
	_check(StringName(mine.get("visual_state", &"")) == &"resolved", "Triggered Mine does not project a resolved state")

	var exit_snapshot := _snapshot(&"Exit", Vector2i(2, 2))
	exit_snapshot.merge({"black_coin": 31, "safe_yield": 9, "backpack_used": 4, "backpack_capacity": 10, "inventory_items": [{"instance_id": "a"}], "room_floor_item_count": 2}, true)
	var exit := _projection_of_kind(ProjectionScript.build(exit_snapshot), &"exit")
	var exit_payload: Dictionary = exit.get("payload", {})
	_check(StringName(exit.get("visual_key", &"")) == &"visual.art24.fx.beacon_pulse.0", "Exit does not reuse the approved beacon pulse")
	_check(int(exit_payload.get("black_coin", -1)) == 31 and int(exit_payload.get("safe_yield", -1)) == 9, "Exit summary drifted from public currency fields")
	_check(int(exit_payload.get("inventory_count", -1)) == 1 and int(exit_payload.get("backpack_used", -1)) == 4, "Exit summary drifted from public backpack fields")
	_check(int(exit_payload.get("room_floor_item_count", -1)) == 2, "Exit summary omitted current-room leftovers")


func _check_special_world_interactions() -> void:
	var overlay := Control.new()
	overlay.size = Vector2(1280, 720)
	root.add_child(overlay)
	var view = RoomViewScript.new()
	root.add_child(view)
	view.attach_context_popup(overlay)
	view.context_action_requested.connect(func(action: StringName, payload: Dictionary) -> void:
		context_actions.append({"action": action, "payload": payload.duplicate(true)})
	)

	var event_snapshot := _snapshot(&"Event", Vector2i(1, 1))
	event_snapshot["event_state"] = {"event_type": &"dice", "completed": false}
	var event_before := event_snapshot.duplicate(true)
	view.configure_room(event_snapshot)
	view.advance(0.0, ProjectionScript.EVENT_LOCAL_POS)
	await _frames(2)
	_check(event_snapshot == event_before, "Event proximity mutated its public snapshot")
	_check(view.context_popup.visible and view.context_popup.context_kind == &"event", "Event proximity did not show its context card")
	var event_request: Dictionary = view.request_nearest_interaction(ProjectionScript.EVENT_LOCAL_POS)
	_check(bool(event_request.get("accepted", false)) and StringName(event_request.get("interaction_kind", &"")) == &"event", "Event E request does not use interaction_kind=event")
	_check(context_actions.is_empty(), "Event proximity emitted a command without explicit input")
	_check(view.activate_context_primary(), "Event context primary did not accept explicit input")
	_check(context_actions.size() == 1 and StringName(context_actions[0].get("action", &"")) == &"event_open", "Event context action is not event_open")

	context_actions.clear()
	var completed_snapshot := event_snapshot.duplicate(true)
	completed_snapshot["event_state"] = {"event_type": &"dice", "completed": true}
	view.configure_room(completed_snapshot)
	view.advance(0.0, ProjectionScript.EVENT_LOCAL_POS)
	_check(view.context_popup.visible, "Completed Event cannot be inspected")
	var completed_request: Dictionary = view.request_nearest_interaction(ProjectionScript.EVENT_LOCAL_POS)
	_check(not bool(completed_request.get("accepted", false)), "Completed Event accepted another action")
	_check(not view.activate_context_primary() and context_actions.is_empty(), "Completed Event context emitted another action")

	var mine_snapshot := _snapshot(&"Mine", Vector2i(1, 2))
	mine_snapshot["current_room_detail"] = {"triggered": true}
	view.configure_room(mine_snapshot)
	view.advance(0.0, ProjectionScript.MINE_LOCAL_POS)
	_check(view.context_popup.visible and view.context_popup.context_kind == &"mine", "Mine proximity did not show its read-only context")
	var mine_request: Dictionary = view.request_nearest_interaction(ProjectionScript.MINE_LOCAL_POS)
	_check(not bool(mine_request.get("accepted", false)), "Mine proximity became a room command")
	_check(not view.activate_context_primary() and context_actions.is_empty(), "Mine context emitted a command")

	var exit_snapshot := _snapshot(&"Exit", Vector2i(2, 2))
	exit_snapshot.merge({"black_coin": 22, "safe_yield": 7, "backpack_used": 3, "backpack_capacity": 10}, true)
	view.configure_room(exit_snapshot)
	view.advance(0.0, ProjectionScript.EXIT_LOCAL_POS)
	_check(view.context_popup.visible and view.context_popup.context_kind == &"exit", "Exit proximity did not show its summary")
	var exit_request: Dictionary = view.request_nearest_interaction(ProjectionScript.EXIT_LOCAL_POS)
	_check(bool(exit_request.get("accepted", false)) and StringName(exit_request.get("interaction_kind", &"")) == &"exit", "Exit E request does not use interaction_kind=exit")
	_check(context_actions.is_empty(), "Exit proximity emitted a command without explicit input")
	_check(view.activate_context_primary(), "Exit context primary did not accept explicit input")
	_check(context_actions.size() == 1 and StringName(context_actions[0].get("action", &"")) == &"exit_request", "Exit context action is not exit_request")
	var refreshed_exit := exit_snapshot.duplicate(true)
	refreshed_exit["inventory_items"] = [{"instance_id": "live-exit-item"}]
	refreshed_exit["selected_objective_summary"] = "现场委托 1/2"
	view.configure_room(refreshed_exit)
	view.advance(0.0, ProjectionScript.EXIT_LOCAL_POS)
	_check(String(view.context_popup.hint_label.text).contains("携带 1 件") and String(view.context_popup.hint_label.text).contains("现场委托 1/2"), "Exit popup did not live-refresh inventory_count/objective_summary for the same projection")
	var exit_prompt := _special_prompt_for_kind(view, &"exit")
	_check(exit_prompt != null and not exit_prompt.visible, "Visible Exit context card did not suppress its duplicate world prompt")
	view.context_popup.clear_context()
	_check(exit_prompt != null and exit_prompt.visible, "Closing the Exit context card did not restore its world prompt")
	view.advance(0.0, ProjectionScript.EXIT_LOCAL_POS)
	_check(view.context_popup.visible and exit_prompt != null and not exit_prompt.visible, "Reopening the Exit context card did not reclaim its prompt")
	view.set_context_ui_suppressed(true)
	_check(not view.context_popup.visible, "Opening a modal did not hide the Exit context card")
	_check(exit_prompt != null and not exit_prompt.visible, "Opening a modal left the duplicate Exit world prompt visible")
	view.set_context_ui_suppressed(false)
	_check(view.context_popup.visible and exit_prompt != null and not exit_prompt.visible, "Closing a modal did not restore the Exit context card as the sole nearby guidance")

	var centered_door_snapshot: Dictionary = view.build_read_only_snapshot()
	_check(Vector2i(centered_door_snapshot.get("nearby_available_door", Vector2i.ZERO)) == Vector2i.ZERO, "Available door cue is visible while the player is away from every door")
	view.advance(0.0, Vector2(0.50, 0.06), {})
	_check(Vector2i(view.build_read_only_snapshot().get("nearby_available_door", Vector2i.ZERO)) == Vector2i.UP, "Approaching a valid door did not reveal its bounded cue")
	view.apply_combat_snapshot({"door_locked": true, "active": true, "enemies": [], "projectiles": []})
	var locked_snapshot: Dictionary = view.build_read_only_snapshot()
	_check(Vector2i(locked_snapshot.get("nearby_available_door", Vector2i.ZERO)) == Vector2i.ZERO, "Combat lock retained a non-combat cyan door cue")
	var restricted_count := 0
	for door in (locked_snapshot.get("doors", []) as Array):
		if door is Dictionary and StringName((door as Dictionary).get("visual_state", &"")) == &"combat_restricted":
			restricted_count += 1
	_check(restricted_count > 0, "Combat lock no longer projects Monster red door seals")
	view.free()
	overlay.free()


func _check_production_proximity_authority() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_check(packed != null, "Production Main scene could not be loaded for proximity authority")
	if packed == null:
		return
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(2)
	var run_scene = main.get_node_or_null("RunScene")
	_check(run_scene != null, "Production RunScene is missing for proximity authority")
	if run_scene == null:
		main.queue_free()
		await _frames(4)
		return
	var context = run_scene.get("run_context")
	var bus = run_scene.get("command_bus")
	var player = run_scene.get("player_controller")
	var run_surface = run_scene.get("run_surface")
	var room_view = run_scene.get("room_runtime_view")
	_check(context != null and bus != null and player != null and run_surface != null and room_view != null, "Production proximity fixture did not initialize runtime authority")
	if context == null or bus == null or player == null or run_surface == null or room_view == null:
		main.queue_free()
		await _frames(4)
		return
	var started: Dictionary = bus.dispatch(&"start_demo_run", {"source": "i2_special_proximity"})
	_check(bool(started.get("ok", false)), "Production proximity fixture could not start")
	run_scene.call("_show_run_screen")
	production_command_counts.clear()
	bus.command_requested.connect(_on_production_command_requested)

	var target := Vector2i(2, 2)
	context.truth_map.set_room_type(target, &"Event")
	context.player_pos = target
	context.current_pos = target
	context.interacted_cells.erase(context.cell_key(target))
	context.intel_map.reveal_cell(target, context.truth_map)
	bus.room_resolver.enter_room(context)
	player.set_local_position(Vector2(0.05, 0.05))
	run_scene.call("_apply_full_view_models")
	await process_frame
	_check(
		(run_surface.get("encounter_option_buttons") as Array).is_empty()
		and not (run_surface.get("encounter_backdrop") as Control).visible,
		"Event decision was duplicated in the steady RunSurface"
	)
	# A stale world-card callback is another UI entry and must revalidate range.
	run_scene.call("_on_world_context_action_requested", &"event_open", {})
	_check(not bool(run_scene.call("_runtime_modal_is_top", &"event")), "Far stale Event world action opened the option modal")
	_check(_production_count(&"select_encounter_option") == 0 and _production_count(&"select_event_option") == 0, "Far Event action submitted a domain command")

	player.set_local_position(ProjectionScript.EVENT_LOCAL_POS)
	room_view.advance(0.0, player.get_local_position(), {})
	await process_frame
	var event_popup = room_view.get("context_popup")
	_check(
		event_popup != null and event_popup.visible and event_popup.context_kind == &"event",
		"Near Event did not expose its world-context entry"
	)
	var event_opened := bool(event_popup.activate_primary()) if event_popup != null else false
	await process_frame
	_check(event_opened and bool(run_scene.call("_runtime_modal_is_top", &"event")), "Near Event world context did not open its focused modal")
	_check(_production_count(&"select_encounter_option") == 0 and _production_count(&"select_event_option") == 0, "Opening Event modal submitted a decision")
	var event_options_box = run_scene.get("event_options_box") as Control
	var event_modal_buttons: Array[Button] = []
	if event_options_box != null:
		for child in event_options_box.get_children():
			if child is Button:
				event_modal_buttons.append(child as Button)
	var expected_event_options: Array = (context.event_state as Dictionary).get("options", [])
	_check(
		event_modal_buttons.size() == expected_event_options.size(),
		"Event modal did not preserve all authoritative options: expected=%d actual=%d"
		% [expected_event_options.size(), event_modal_buttons.size()]
	)
	var leave_button: Button = event_modal_buttons.back() if not event_modal_buttons.is_empty() else null
	_check(
		leave_button != null and not leave_button.disabled and String(leave_button.text).contains("离开"),
		"Event modal did not retain its legal leave decision"
	)
	if leave_button != null and not leave_button.disabled:
		leave_button.pressed.emit()
	await process_frame
	_check(
		_production_count(&"select_event_option") == 1
		and _production_count(&"select_encounter_option") == 0,
		"Near Event modal did not submit exactly one authoritative event command"
	)

	var exit_positions: Array[Vector2i] = context.truth_map.get_exits()
	_check(not exit_positions.is_empty(), "Production proximity fixture contains no governed Exit")
	var exit_target: Vector2i = exit_positions[0] if not exit_positions.is_empty() else target
	context.player_pos = exit_target
	context.current_pos = exit_target
	context.intel_map.reveal_cell(exit_target, context.truth_map)
	bus.room_resolver.enter_room(context)
	player.set_local_position(Vector2(0.05, 0.05))
	run_scene.call("_apply_full_view_models")
	await process_frame
	var extract_button := (run_surface.get("action_buttons") as Dictionary).get(&"extract") as Button
	_check(extract_button != null and not extract_button.disabled, "Legacy RunSurface exposed no Exit action")
	if extract_button != null and not extract_button.disabled:
		extract_button.pressed.emit()
	run_scene.call("_on_world_context_action_requested", &"exit_request", {})
	_check(_production_count(&"request_extract") == 0 and StringName(context.phase) == &"running", "Far legacy/stale Exit entry submitted extraction")

	player.set_local_position(ProjectionScript.EXIT_LOCAL_POS)
	room_view.advance(0.0, player.get_local_position(), {})
	await process_frame
	var production_exit_prompt := _special_prompt_for_kind(room_view, &"exit")
	var production_exit_popup = room_view.get("context_popup")
	_check(production_exit_popup != null and production_exit_popup.visible and production_exit_popup.context_kind == &"exit", "Production Exit proximity did not open its context card")
	_check(production_exit_prompt != null and not production_exit_prompt.visible, "Production Exit context card left its duplicate world prompt visible")
	if extract_button != null and not extract_button.disabled:
		extract_button.pressed.emit()
	await process_frame
	_check(_production_count(&"request_extract") == 1 and StringName(context.phase) == &"confirm_extract", "Near Exit action did not submit exactly one legal request: count=%d phase=%s in_range=%s modal=%s" % [_production_count(&"request_extract"), context.phase, run_scene.call("_world_interaction_in_range", &"exit"), run_scene.call("_is_runtime_modal_open")])
	_check(production_exit_prompt != null and not production_exit_prompt.visible, "Production extraction confirmation left the duplicate Exit world prompt visible")
	player.set_local_position(Vector2(0.05, 0.05))
	run_scene.call("_confirm_extract_from_ui")
	_check(_production_count(&"confirm_extract") == 0 and StringName(context.phase) == &"confirm_extract", "Far Exit confirmation bypassed world proximity: count=%d phase=%s modal=%s" % [_production_count(&"confirm_extract"), context.phase, run_scene.call("_is_runtime_modal_open")])
	player.set_local_position(ProjectionScript.EXIT_LOCAL_POS)
	run_scene.call("_cancel_extract_from_ui")
	await process_frame
	_check(StringName(context.phase) == &"running", "Exit proximity fixture did not return to running after cancellation")
	_check(production_exit_popup != null and production_exit_popup.visible and production_exit_prompt != null and not production_exit_prompt.visible, "Closing production extraction confirmation did not restore the context card as the sole Exit guidance")
	var exit_focus_margin_position := ProjectionScript.EXIT_LOCAL_POS + Vector2(0.212, 0.0)
	player.set_local_position(exit_focus_margin_position)
	room_view.advance(0.0, player.get_local_position(), {})
	await process_frame
	_check(
		production_exit_popup != null and production_exit_popup.visible and production_exit_popup.context_kind == &"exit",
		"Exit context card did not remain visible inside its focus margin"
	)
	_check(
		not bool(room_view.request_nearest_interaction(player.get_local_position()).get("accepted", false)),
		"Strict Exit domain query accepted a player outside the interaction radius"
	)
	run_scene.call("_handle_interact_pressed")
	await process_frame
	_check(
		_production_count(&"request_extract") == 2 and StringName(context.phase) == &"confirm_extract",
		"Keyboard Exit interaction lost its already-authorized visible-focus grace"
	)
	run_scene.call("_cancel_extract_from_ui")
	await process_frame
	player.set_local_position(exit_focus_margin_position)
	room_view.advance(0.0, player.get_local_position(), {})
	run_scene.call("_request_extract_from_ui")
	_check(
		_production_count(&"request_extract") == 2 and StringName(context.phase) == &"running",
		"Legacy/UI Exit entry inherited keyboard-only focus grace"
	)

	if bus.command_requested.is_connected(_on_production_command_requested):
		bus.command_requested.disconnect(_on_production_command_requested)
	main.queue_free()
	run_scene = null
	context = null
	bus = null
	player = null
	run_surface = null
	main = null
	await _frames(10)


func _on_production_command_requested(command_name: StringName, _payload: Dictionary) -> void:
	production_command_counts[command_name] = int(production_command_counts.get(command_name, 0)) + 1


func _production_count(command_name: StringName) -> int:
	return int(production_command_counts.get(command_name, 0))


func _check_monster_appearance_envelope() -> void:
	var had_reduce_setting := ProjectSettings.has_setting("accessibility/reduce_motion")
	var previous_reduce := bool(ProjectSettings.get_setting("accessibility/reduce_motion", false))
	ProjectSettings.set_setting("accessibility/reduce_motion", false)
	var actor = ActorViewScript.new()
	root.add_child(actor)
	var snapshot := {"enemy_id": "appearance-a", "state": &"idle", "visual_variant": &"base", "hp": 8, "max_hp": 8, "pos": Vector2(0.5, 0.5)}
	var unchanged := snapshot.duplicate(true)
	actor.configure(&"slime", snapshot)
	var first: Dictionary = actor.appearance_snapshot()
	var sprite := actor.get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	_check(float(first.get("duration", 0.0)) >= 0.30 and float(first.get("duration", 1.0)) <= 0.34, "Monster appearance is outside the 0.30-0.34s readable envelope")
	_check(float(first.get("progress", -1.0)) == 0.0, "Monster appearance did not start at the first presentation frame")
	_check(sprite != null and sprite.modulate.a >= 0.70, "Monster first presentation frame is invisible")
	actor._process(0.16)
	var middle: Dictionary = actor.appearance_snapshot()
	_check(float(middle.get("progress", 0.0)) > 0.0 and float(middle.get("progress", 1.0)) < 1.0, "Monster appearance skipped its presentation envelope")
	actor._process(0.18)
	_check(is_equal_approx(float(actor.appearance_snapshot().get("progress", 0.0)), 1.0), "Monster appearance did not finish by 0.34s")
	_check(snapshot == unchanged, "Monster presentation mutated its authoritative snapshot")
	actor.free()

	ProjectSettings.set_setting("accessibility/reduce_motion", true)
	var reduced_actor = ActorViewScript.new()
	root.add_child(reduced_actor)
	reduced_actor.configure(&"bat", {"enemy_id": "appearance-reduced", "state": &"idle", "hp": 4, "max_hp": 4, "pos": Vector2(0.5, 0.5)})
	var reduced: Dictionary = reduced_actor.appearance_snapshot()
	_check(bool(reduced.get("reduced_motion", false)) and is_equal_approx(float(reduced.get("progress", 0.0)), 1.0), "Reduced motion did not select a static monster entry state")
	reduced_actor._process(0.09)
	_check(is_equal_approx(float(reduced_actor.appearance_snapshot().get("progress", 0.0)), 1.0), "Reduced-motion monster entry started an animation")
	reduced_actor.free()
	if had_reduce_setting:
		ProjectSettings.set_setting("accessibility/reduce_motion", previous_reduce)
	else:
		ProjectSettings.clear("accessibility/reduce_motion")


func _check_mine_authority_and_presentation() -> void:
	var fixture := _mine_command_fixture(false)
	var first_envelope: Dictionary = fixture.get("first_envelope", {})
	var revisit_envelope: Dictionary = fixture.get("revisit_envelope", {})
	var first: Dictionary = first_envelope.get("room_entry_result", {})
	var revisit: Dictionary = revisit_envelope.get("room_entry_result", {})
	_check(not first.is_empty() and first == (first_envelope.get("action_result", {}) as Dictionary).get("room_entry_result", {}), "CommandBus did not copy first Mine entry result to the top-level envelope")
	_check(StringName(first.get("cause", &"")) == &"mine_triggered" and bool(first.get("first_trigger", false)), "First Mine entry result is not mine_triggered")
	_check(int(first.get("hp_delta", 0)) < 0 and int(first.get("pressure_delta", 0)) > 0 and not bool(first.get("fatal", true)), "First Mine entry lacks exact nonfatal damage/pressure")
	_check(StringName(revisit.get("cause", &"")) == &"mine_inactive" and not bool(revisit.get("first_trigger", true)), "Mine revisit result is not mine_inactive")
	_check(int(revisit.get("hp_delta", 1)) == 0 and int(revisit.get("pressure_delta", 1)) == 0, "Mine revisit repeated damage or pressure")

	var view = RoomViewScript.new()
	root.add_child(view)
	view.room_entry_feedback_requested.connect(func(feedback: Dictionary) -> void: room_entry_feedback.append(feedback.duplicate(true)))
	view.configure_room(fixture.get("snapshot", {}))
	view.apply_room_entry_result(first)
	_check(bool(view.build_read_only_snapshot().get("mine_feedback_active", false)), "First Mine damage did not start presentation feedback")
	_check(room_entry_feedback.size() == 1 and bool(room_entry_feedback[0].get("presentation_only", false)), "Mine entry did not emit one presentation-only feedback signal")
	view.advance(0.30, ProjectionScript.MINE_LOCAL_POS)
	_check(not bool(view.build_read_only_snapshot().get("mine_feedback_active", true)), "Mine feedback outlived its presentation duration")
	view.apply_room_entry_result(revisit)
	_check(not bool(view.build_read_only_snapshot().get("mine_feedback_active", true)), "Mine revisit replayed damage feedback")
	_check(room_entry_feedback.size() == 2, "Mine revisit did not update static presentation state")
	view.apply_room_entry_result(revisit)
	_check(room_entry_feedback.size() == 2, "Duplicate Mine entry result replayed presentation")
	view.free()
	room_entry_feedback.clear()

	var immune_fixture := _mine_command_fixture(false, true)
	var immune_envelope: Dictionary = immune_fixture.get("first_envelope", {})
	var immune: Dictionary = immune_envelope.get("room_entry_result", {})
	_check(bool(immune.get("first_trigger", false)) and int(immune.get("hp_delta", -1)) == 0 and int(immune.get("pressure_delta", 0)) > 0, "Immune Mine entry did not preserve its exact no-damage result")
	var immune_view = RoomViewScript.new()
	root.add_child(immune_view)
	immune_view.configure_room(immune_fixture.get("snapshot", {}))
	immune_view.apply_room_entry_result(immune)
	_check(not bool(immune_view.build_read_only_snapshot().get("mine_feedback_active", true)), "No-damage Mine entry played hit feedback")
	immune_view.free()

	var fatal_fixture := _mine_command_fixture(true)
	var fatal_envelope: Dictionary = fatal_fixture.get("first_envelope", {})
	var fatal: Dictionary = fatal_envelope.get("room_entry_result", {})
	_check(bool(fatal.get("fatal", false)) and int(fatal.get("hp_delta", 0)) < 0, "Fatal Mine result omitted fatal or damage")
	var fatal_view = RoomViewScript.new()
	root.add_child(fatal_view)
	fatal_view.configure_room(fatal_fixture.get("snapshot", {}))
	fatal_view.apply_room_entry_result(fatal)
	_check(bool(fatal_view.build_read_only_snapshot().get("mine_feedback_active", false)), "Fatal Mine did not reuse damage presentation feedback: room=%s result=%s snapshot_room=%s" % [fatal_view.room_type, fatal, (fatal_fixture.get("snapshot", {}) as Dictionary).get("current_room", &"missing")])
	fatal_view.free()


func _mine_command_fixture(fatal: bool, immune: bool = false) -> Dictionary:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	var start: Dictionary = bus.dispatch(&"start_standard_run", {"run_start_config": {"mine_hits_are_fatal": fatal}})
	_check(bool(start.get("ok", false)), "Mine command fixture could not start")
	var context = controller.context
	context.mine_hits_are_fatal = fatal
	context.mine_immunity = 1 if immune else 0
	var target := _find_room(context, &"Mine")
	_check(target.x >= 0, "Mine command fixture contains no Mine")
	if target.x < 0:
		_release_controller(controller)
		return {}
	var neighbor := _neighbor_for(context, target)
	context.player_pos = neighbor
	context.current_pos = neighbor
	context.entered_cells.erase(context.cell_key(target))
	context.intel_map.reveal_cell(target, context.truth_map)
	var delta := target - neighbor
	var first_envelope: Dictionary = bus.dispatch(&"move_by", {"delta": delta, "source": "i2_special_room_runner"})
	var first_result: Dictionary = first_envelope.get("room_entry_result", {})
	# Presenters consume only the result. The fixture repositions outside the
	# room between explicit move commands so the second entry exercises revisit.
	var revisit_envelope: Dictionary = {}
	if not fatal:
		context.player_pos = neighbor
		context.current_pos = neighbor
		context.intel_map.reveal_cell(target, context.truth_map)
		revisit_envelope = bus.dispatch(&"move_by", {"delta": delta, "source": "i2_special_room_runner"})
	var fixture_snapshot: Dictionary = context.get_status_snapshot()
	_release_controller(controller)
	return {
		"first_envelope": first_envelope,
		"revisit_envelope": revisit_envelope,
		"first_result": first_result,
		"snapshot": fixture_snapshot,
	}


func _check_exit_first_discovery_authority() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	var started: Dictionary = bus.dispatch(&"start_standard_run", {"source": "i2_special_exit_discovery"})
	_check(bool(started.get("ok", false)), "Exit discovery fixture could not start")
	var context = controller.context
	var target := _find_room(context, &"Exit")
	_check(target.x >= 0, "Exit discovery fixture contains no Exit")
	if target.x < 0:
		_release_controller(controller)
		return
	var neighbor := _neighbor_for(context, target)
	context.player_pos = neighbor
	context.current_pos = neighbor
	context.explored_cells.erase(context.cell_key(target))
	context.intel_map.reveal_cell(target, context.truth_map)
	var delta := target - neighbor
	var first_envelope: Dictionary = bus.dispatch(&"move_by", {"delta": delta, "source": "i2_special_exit_discovery"})
	var first_entry: Dictionary = first_envelope.get("room_entry_result", {})
	_check(StringName(first_entry.get("room_type", &"Unknown")) == &"Exit" and bool(first_entry.get("first_explore", false)), "Exit first entry omitted authoritative discovery state")
	context.player_pos = neighbor
	context.current_pos = neighbor
	context.intel_map.reveal_cell(target, context.truth_map)
	var revisit_envelope: Dictionary = bus.dispatch(&"move_by", {"delta": delta, "source": "i2_special_exit_revisit"})
	var revisit_entry: Dictionary = revisit_envelope.get("room_entry_result", {})
	_check(not bool(revisit_entry.get("first_explore", true)), "Exit revisit was reported as a first discovery")
	_release_controller(controller)



func _find_room(context, room_type: StringName) -> Vector2i:
	for y in range(context.height):
		for x in range(context.width):
			var pos := Vector2i(x, y)
			if context.truth_map.get_room_type(pos) == room_type:
				return pos
	return Vector2i(-1, -1)


func _completed_event_revisit_snapshot() -> Dictionary:
	var controller = RunRuntimeControllerScript.new()
	var start: Dictionary = controller.command_bus.dispatch(&"start_standard_run")
	_check(bool(start.get("ok", false)), "Completed Event revisit fixture could not start")
	var context = controller.context
	var target := _find_room(context, &"Event")
	_check(target.x >= 0, "Completed Event revisit fixture contains no Event")
	if target.x < 0:
		_release_controller(controller)
		return _snapshot(&"Event", Vector2i.ZERO)
	context.player_pos = target
	context.current_pos = target
	context.interacted_cells[context.cell_key(target)] = true
	controller.command_bus.room_resolver.enter_room(context)
	controller.command_bus.room_resolver.enter_room(context)
	var snapshot: Dictionary = context.get_status_snapshot()
	_check((snapshot.get("event_state", {}) as Dictionary).is_empty() or bool((snapshot.get("event_state", {}) as Dictionary).get("completed", false)), "Completed Event revisit fixture exposed an inconsistent transient event_state")
	_release_controller(controller)
	return snapshot


func _release_controller(controller) -> void:
	if controller == null:
		return
	var context = controller.context
	var bus = controller.command_bus
	var in_run_runtime = controller.in_run_runtime
	if bus != null:
		var callback := Callable(controller, "_on_terminal_result_available")
		if bus.result_available.is_connected(callback):
			bus.result_available.disconnect(callback)
		bus.bind_runtime_controller(null)
	if in_run_runtime != null:
		in_run_runtime.bind(null)
	controller.command_bus = null
	controller.in_run_runtime = null
	controller.context = null
	# All of these objects extend RefCounted. Breaking the controller graph is
	# sufficient; calling free() on them is invalid and hides fixture leaks behind
	# shutdown errors.


func _neighbor_for(context, target: Vector2i) -> Vector2i:
	for delta in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var candidate: Vector2i = target + delta
		if context.is_inside(candidate):
			return candidate
	return target


func _check_no_presentation_authority() -> void:
	var projection_source := FileAccess.get_file_as_string("res://scripts/gameplay/runtime/g41_world_object_projection.gd")
	var room_view_source := FileAccess.get_file_as_string("res://scripts/gameplay/runtime/g41_room_runtime_view.gd")
	var actor_source := FileAccess.get_file_as_string("res://scripts/gameplay/runtime/g41_runtime_actor_view.gd")
	_check(not projection_source.contains("dispatch(") and not room_view_source.contains("CommandBus") and not room_view_source.contains("dispatch("), "Special-room presentation owns command authority")
	_check(not actor_source.contains("physics_process") and not actor_source.contains("Engine.time_scale"), "Monster appearance changes simulation timing")
	_check(not projection_source.contains("assets/props/art07") and not room_view_source.contains("assets/props/art07"), "Special-room presentation reintroduced forbidden ART07 props")


func _snapshot(room_type: StringName, position: Vector2i) -> Dictionary:
	return {
		"position": position,
		"player_pos": position,
		"width": 4,
		"height": 4,
		"current_room": room_type,
		"current_room_detail": {"room_type_key": String(room_type).to_lower(), "triggered": false},
		"event_state": {},
		"room_floor_items": [],
		"inventory_items": [],
		"backpack_used": 0,
		"backpack_capacity": 10,
		"backpack_remaining": 10,
		"run_start_config": {},
		"stats": {},
		"run_map_snapshot": {"KnownMap": {"width": 4, "height": 4, "public_cells": []}},
	}


func _projection_of_kind(projection: Dictionary, kind: StringName) -> Dictionary:
	for raw_object in (projection.get("world_objects", []) as Array):
		if raw_object is Dictionary and StringName((raw_object as Dictionary).get("interaction_kind", &"")) == kind:
			return (raw_object as Dictionary).duplicate(true)
	return {}


func _special_prompt_for_kind(view, kind: StringName) -> Label:
	if view == null:
		return null
	for entity in view.special_entities.values():
		if entity != null and StringName(entity.interaction_kind) == kind:
			return entity.get_node_or_null("PromptAnchor/InteractionPrompt") as Label
	return null


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("I2_SPECIAL_ROOM_PLAYER_EXPERIENCE=PASS event=structured,proximity_gated,room_entry_scrub,stage_feedback,token_scrub world=proximity_only mine=entry_result monster=0.32s exit=public_summary,proximity_gated")
		quit(0)
		return
	for failure in failures:
		push_error("I2 special-room failure: " + failure)
	print("I2_SPECIAL_ROOM_PLAYER_EXPERIENCE=FAIL failures=%d" % failures.size())
	quit(1)
