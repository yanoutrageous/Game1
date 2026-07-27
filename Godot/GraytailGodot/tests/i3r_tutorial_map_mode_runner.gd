extends SceneTree

const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const DeployMapProjectionScript := preload("res://scripts/ui/deploy_prep/deploy_map_projection.gd")
const RunStartConfigScript := preload("res://scripts/core/run/run_start_config.gd")
const RunStartRouteAdapterScript := preload("res://scripts/core/run/run_start_route_adapter.gd")
const RunConfigScript := preload("res://scripts/core/run/run_config.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RunSceneRouteControllerScript := preload("res://scripts/core/run/run_scene_route_controller.gd")
const RunSceneResultControllerScript := preload("res://scripts/core/run/run_scene_result_controller.gd")
const TutorialMapCatalogScript := preload("res://scripts/core/run/tutorial_map_catalog.gd")
const TutorialServiceScript := preload("res://scripts/core/run/tutorial_service.gd")
const SemanticActionHintScript := preload("res://scripts/core/input/semantic_action_hint.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")
const RunStateMachineScript := preload("res://scripts/core/run/run_state_machine.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const ResultPresentationModelScript := preload("res://scripts/ui/result/result_presentation_model.gd")

var failures: Array[String] = []
var save_path := "user://tests/i3r_tutorial_map_mode_%d.json" % Time.get_ticks_usec()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_deploy_map_route()
	_test_run_start_meta_authority()
	_test_tutorial_content_and_semantic_actions()
	_test_persistence_isolation_and_replay()
	_cleanup()
	if failures.is_empty():
		print("I3R_TUTORIAL_EVENT_DIVERSITY=PASS production=CommandBus>RoomResolver>EventService popups=TutorialService order=trap,dice,altar,trader popup_order=trap_rule,dice_rule,altar_rule,event_rule")
		print("I3R_TUTORIAL_MAP_MODE=PASS deploy=same_page route=standard dedicated_interface=retired authority=meta map=tutorial_5x5 content=13 persistence=completion_only replay=PASS")
		quit(0)
		return
	for failure in failures:
		push_error("I3R tutorial map mode failure: " + failure)
	quit(1)


func _test_deploy_map_route() -> void:
	var definition := M7ContentCatalogScript.map_definition_exact("tutorial_5x5")
	_check(not definition.is_empty(), "tutorial_map_missing")
	_check(StringName(definition.get("mode", &"")) == &"tutorial", "tutorial_map_mode")
	_check(bool(definition.get("tutorial_map", false)), "tutorial_map_flag")
	_check(int(definition.get("width", 0)) == 5 and int(definition.get("height", 0)) == 5, "tutorial_map_dimensions")

	var config := DeployConfigScript.default_config(17, {
		"unlocked_map_ids": ["classic_7x7_simple"],
		"tutorial_completed": false,
	})
	_check((config.get("unlocked_map_ids", []) as Array).has("tutorial_5x5"), "tutorial_not_always_available")
	var projection := DeployMapProjectionScript.project(config)
	var tutorial_group := _scale_group(projection, &"5x5")
	_check(not tutorial_group.is_empty(), "tutorial_not_in_deploy_scale_catalog")
	_check((tutorial_group.get("maps", []) as Array).size() == 1, "tutorial_not_single_5x5_option")

	var selected := DeployConfigScript.select_map(config, "tutorial_5x5")
	_check(bool(selected.get("ok", false)), "tutorial_deploy_selection_failed")
	var selected_config := selected.get("config", {}) as Dictionary
	_check(str(selected_config.get("map_config_id", "")) == "tutorial_5x5", "tutorial_selection_id")
	var run_start := DeployConfigScript.build_run_start_config(selected_config)
	_check(str(run_start.get("map_config_id", "")) == "tutorial_5x5", "tutorial_run_start_id")
	_check(bool(run_start.get("tutorial_map", false)), "tutorial_run_start_flag")
	_check(StringName(run_start.get("persistence_policy", &"")) == &"tutorial_completion_only", "tutorial_persistence_policy")
	_check(int(run_start.get("seed_value", 0)) == TutorialMapCatalogScript.FIXED_SEED, "tutorial_seed_not_fixed")
	for field in ["selected_equipment_items", "selected_consumable_items", "selected_equipment_ids", "selected_consumable_ids", "commission_candidates"]:
		_check((run_start.get(field, []) as Array).is_empty(), "tutorial_carry_not_isolated:%s" % field)

	var route_payload := RunStartRouteAdapterScript.payload_from_deploy_preview(run_start, {
		"route_mode": &"standard_run",
		"entry_id": &"deploy_prep_start_bridge",
	})
	_check(StringName(route_payload.get("route_mode", &"")) == &"standard_run", "tutorial_used_independent_route")
	_check(RunStartRouteAdapterScript.route_command_from_payload(route_payload) == &"start_standard_run", "tutorial_used_independent_command")
	_check(not RunStartConfigScript.SUPPORTED_ROUTE_MODES.has(&"tutorial_run"), "tutorial_route_still_supported")
	var runtime := RunConfigScript.m7_map(route_payload.get("run_start_config", {}) as Dictionary)
	_check(StringName(runtime.get("mode", &"")) == &"tutorial", "tutorial_runtime_mode")
	_check(str(runtime.get("map_config_id", "")) == "tutorial_5x5", "tutorial_runtime_map_id")
	_check((runtime.get("manual_map", {}) as Dictionary).size() == 6, "tutorial_manual_map_missing")
	_check((runtime.get("tutorial_triggers", {}) as Dictionary).size() == 25, "tutorial_trigger_grid_not_25")
	var expected_manual_map: Dictionary = {
		"spawn": Vector2i(0, 0),
		"mines": [Vector2i(0, 2), Vector2i(1, 1), Vector2i(2, 0), Vector2i(3, 3)],
		"events": [Vector2i(0, 3), Vector2i(1, 2), Vector2i(2, 1), Vector2i(3, 0)],
		"monsters": [Vector2i(0, 4), Vector2i(1, 3), Vector2i(2, 2), Vector2i(3, 1), Vector2i(4, 0)],
		"chests": [Vector2i(1, 4), Vector2i(2, 3), Vector2i(3, 2), Vector2i(4, 1)],
		"exits": [{"pos": Vector2i(4, 4), "exit_id": &"tutorial_exit", "random_exit": false}],
	}
	var expected_triggers: Dictionary = {
		"0,0": &"spawn_intro",
		"0,1": &"number_rule",
		"1,0": &"number_rule",
		"0,2": &"mine_rule",
		"1,1": &"mine_rule",
		"2,0": &"mine_rule",
		"0,3": &"event_rule",
		"1,2": &"event_rule",
		"2,1": &"event_rule",
		"3,0": &"event_rule",
		"0,4": &"monster_rule",
		"1,3": &"monster_rule",
		"2,2": &"monster_rule",
		"3,1": &"monster_rule",
		"4,0": &"monster_rule",
		"1,4": &"chest_rule",
		"2,3": &"chest_rule",
		"3,2": &"chest_rule",
		"4,1": &"chest_rule",
		"2,4": &"map_rule",
		"4,2": &"map_rule",
		"3,3": &"mine_review",
		"3,4": &"route_rule",
		"4,3": &"route_rule",
		"4,4": &"exit_goal",
	}
	_check(
		(runtime.get("manual_map", {}) as Dictionary) == expected_manual_map,
		"tutorial_manual_map_coordinate_drift"
	)
	_check(
		(runtime.get("tutorial_triggers", {}) as Dictionary) == expected_triggers,
		"tutorial_trigger_coordinate_drift"
	)
	var runtime_controller := RunRuntimeControllerScript.new()
	var route_result := RunSceneRouteControllerScript.start_from_payload(route_payload, runtime_controller.command_bus)
	_check(bool(route_result.get("ok", false)), "deploy_tutorial_route_not_started")
	_check(StringName(route_result.get("command_id", &"")) == &"start_standard_run", "deploy_tutorial_dispatched_wrong_command")
	_check(StringName(runtime_controller.context.mode) == &"tutorial", "deploy_tutorial_context_mode")
	_check(runtime_controller.context.width == 5 and runtime_controller.context.height == 5, "deploy_tutorial_context_dimensions")
	_check(StringName(runtime_controller.context.tutorial_popup.get("id", &"")) == &"spawn_intro", "deploy_tutorial_spawn_instruction_missing")
	_check(runtime_controller.context.last_message.find("Tutorial popup:") < 0, "tutorial_internal_trigger_leaked_to_player_feedback")
	_check(runtime_controller.context.last_message.find("spawn_intro") < 0, "tutorial_internal_id_leaked_to_player_feedback")
	_test_production_tutorial_event_diversity(runtime_controller)
	var retired_command: Dictionary = runtime_controller.command_bus.dispatch(&"start_tutorial_run")
	_check(
		StringName(retired_command.get("status", &"")) == &"unknown_command",
		"retired_tutorial_command_still_dispatchable"
	)
	runtime_controller.command_bus = null
	runtime_controller.in_run_runtime = null
	runtime_controller.context = null
	runtime_controller = null

	var legacy_shell := FileAccess.get_file_as_string("res://scripts/ui/shell/g9_shell_panel.gd")
	_check(legacy_shell.find("start_tutorial_requested") < 0, "legacy_tutorial_signal_visible")
	_check(legacy_shell.find("StartTutorialButton") < 0, "legacy_tutorial_button_visible")
	for production_path in [
		"res://scripts/core/command/command_bus.gd",
		"res://scripts/core/run/run_runtime_controller.gd",
		"res://scripts/core/run/run_state_machine.gd",
		"res://scripts/core/run/run_context.gd",
		"res://scripts/core/run/run_scene.gd",
	]:
		var production_source := FileAccess.get_file_as_string(production_path)
		_check(
			production_source.find("start_tutorial_run") < 0
			and production_source.find("restart_tutorial_run") < 0,
			"independent_tutorial_interface_visible:%s" % production_path
		)
	var run_scene_source := FileAccess.get_file_as_string("res://scripts/core/run/run_scene.gd")
	for retired_surface in [
		"_start_tutorial_from_ui",
		"debug_tutorial_map",
		"\"Tutorial Run\"",
		"Start Tutorial 5x5",
	]:
		_check(
			run_scene_source.find(retired_surface) < 0,
			"dedicated_tutorial_surface_visible:%s" % retired_surface
		)


func _test_production_tutorial_event_diversity(runtime_controller) -> void:
	var command_bus = runtime_controller.command_bus
	var context = runtime_controller.context
	var confirm_result: Dictionary = command_bus.dispatch(&"confirm_tutorial_popup")
	_check(bool(confirm_result.get("ok", false)), "tutorial_spawn_confirmation_failed_before_event_route")

	var expected_events := {
		Vector2i(0, 3): {"event_type": &"trap", "popup_id": &"trap_rule"},
		Vector2i(1, 2): {"event_type": &"dice", "popup_id": &"dice_rule"},
		Vector2i(2, 1): {"event_type": &"altar", "popup_id": &"altar_rule"},
		Vector2i(3, 0): {"event_type": &"trader", "popup_id": &"event_rule"},
	}
	var production_route := [
		Vector2i.DOWN,
		Vector2i.DOWN,
		Vector2i.DOWN,
		Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.RIGHT,
	]
	var observed_types: Array[StringName] = []
	var observed_popups: Array[StringName] = []
	for delta in production_route:
		var move_result: Dictionary = command_bus.dispatch(&"move_by", {"delta": delta})
		_check(bool(move_result.get("ok", false)), "production_tutorial_event_route_move_failed:%s" % delta)
		if not bool(move_result.get("ok", false)):
			return
		var pos: Vector2i = context.get_current_pos()
		if not expected_events.has(pos):
			continue
		var expected := expected_events[pos] as Dictionary
		var actual_event_type := StringName(context.event_state.get("event_type", &""))
		var actual_popup_id := StringName(context.tutorial_popup.get("id", &""))
		_check(context.current_room_type == &"Event", "production_tutorial_event_room_missing:%s" % pos)
		_check(
			actual_event_type == StringName(expected.get("event_type", &"")),
			"production_tutorial_event_type_wrong:%s:%s" % [pos, String(actual_event_type)]
		)
		_check(
			actual_popup_id == StringName(expected.get("popup_id", &"")),
			"production_tutorial_event_popup_wrong:%s:%s" % [pos, String(actual_popup_id)]
		)
		observed_types.append(actual_event_type)
		observed_popups.append(actual_popup_id)
	_check(
		observed_types == [&"trap", &"dice", &"altar", &"trader"],
		"production_tutorial_event_order_wrong:%s" % [observed_types]
	)
	_check(
		observed_popups == [&"trap_rule", &"dice_rule", &"altar_rule", &"event_rule"],
		"production_tutorial_event_popup_order_wrong:%s" % [observed_popups]
	)
	var distinct_types := {}
	for event_type in observed_types:
		distinct_types[event_type] = true
	_check(distinct_types.size() == 4, "production_tutorial_event_diversity_missing:%s" % [observed_types])


func _test_run_start_meta_authority() -> void:
	var adapter := MetaProgressAdapterScript.new()
	adapter.data = adapter.save_adapter.default_meta_progress()
	adapter.data["unlocked_map_ids"] = [
		"tutorial_5x5",
		"classic_7x7_simple",
		"classic_7x7_normal",
		"classic_10x10_standard",
	]
	adapter.data["run_count"] = 12
	adapter.data["gold"] = 50
	adapter.data["warehouse_items"] = [
		{"instance_id": "authority:eq", "item_id": "eq_recovery_bag"},
		{"instance_id": "authority:eq_same_slot", "item_id": "eq_recovery_bag"},
		{"instance_id": "authority:con", "item_id": "con_ration"},
		{"instance_id": "authority:heavy_1", "item_id": "con_ration", "weight": 4},
		{"instance_id": "authority:heavy_2", "item_id": "con_med_patch", "weight": 4},
		{"instance_id": "authority:heavy_3", "item_id": "con_tape_roll", "weight": 4},
	]
	var authority_meta := adapter.get_summary()

	var deploy_config := DeployConfigScript.default_config(17, authority_meta)
	var map_selection := DeployConfigScript.select_map(
		deploy_config,
		"classic_10x10_standard"
	)
	_check(bool(map_selection.get("ok", false)), "authority_offer_map_selection_failed")
	var displayed_config := map_selection.get("config", {}) as Dictionary
	var displayed_candidates := (
		displayed_config.get("commission_candidates", []) as Array
	).duplicate(true)
	var expected_seed := M7ContentCatalogScript.commission_offer_seed(
		"classic_10x10_standard",
		int(authority_meta.get("run_count", 0))
	)
	_check(
		int(displayed_config.get("commission_candidate_seed", 0)) == expected_seed,
		"deploy_offer_seed_not_map_and_run_count_authority"
	)
	var displayed_run_start := DeployConfigScript.build_run_start_config(displayed_config)
	var displayed_authorization := RunStartConfigScript.authorize_with_meta(
		displayed_run_start,
		authority_meta
	)
	_check(bool(displayed_authorization.get("ok", false)), "displayed_offer_rejected_by_authorizer")
	if bool(displayed_authorization.get("ok", false)):
		var authorized_displayed := displayed_authorization.get("config", {}) as Dictionary
		_check(
			authorized_displayed.get("commission_candidates", []) == displayed_candidates,
			"authorizer_candidates_differ_from_deploy_offer"
		)
		_check(
			int(authorized_displayed.get("commission_candidate_seed", 0)) == expected_seed,
			"authorizer_offer_seed_differed_from_deploy"
		)

	var purchased_meta: Dictionary = authority_meta.duplicate(true)
	purchased_meta["gold"] = 9999
	(purchased_meta.get("warehouse_items", []) as Array).append({
		"instance_id": "authority:purchase",
		"item_id": "con_scan_pin",
	})
	var refreshed_after_purchase := DeployConfigScript.refresh_from_meta(
		displayed_config,
		purchased_meta
	)
	var resequenced := DeployConfigScript.default_config(999, purchased_meta)
	resequenced = (
		DeployConfigScript.select_map(
			resequenced,
			"classic_10x10_standard"
		).get("config", resequenced) as Dictionary
	)
	_check(
		refreshed_after_purchase.get("commission_candidates", []) == displayed_candidates,
		"gold_or_purchase_refresh_changed_commission_offer"
	)
	_check(
		resequenced.get("commission_candidates", []) == displayed_candidates,
		"deploy_sequence_changed_commission_offer"
	)
	var refreshed_authorization := RunStartConfigScript.authorize_with_meta(
		DeployConfigScript.build_run_start_config(refreshed_after_purchase),
		purchased_meta
	)
	_check(
		bool(refreshed_authorization.get("ok", false))
		and (
			(refreshed_authorization.get("config", {}) as Dictionary).get(
				"commission_candidates",
				[]
			)
			== displayed_candidates
		),
		"refreshed_offer_and_authorizer_diverged"
	)

	var offered_ids := _candidate_ids(displayed_candidates)
	var legal_not_offered := ""
	for definition in M7ContentCatalogScript.commission_definitions():
		var definition_id := str(definition.get("id", ""))
		var map_ids := definition.get("map_ids", []) as Array
		if not offered_ids.has(definition_id) and map_ids.is_empty():
			legal_not_offered = definition_id
			break
	_check(legal_not_offered != "", "offer_fixture_has_no_legal_non_candidate")
	if legal_not_offered != "":
		var forged_offer := displayed_run_start.duplicate(true)
		forged_offer["selected_objective_id"] = legal_not_offered
		_check_authority_issue(
			forged_offer,
			authority_meta,
			"objective_not_in_commission_offer",
			"legal_but_unoffered_commission_was_accepted"
		)

	var mismatch_config := _authority_config(
		"classic_7x7_simple",
		&"normal",
		"commission_recover_supply"
	)
	_check_authority_issue(
		mismatch_config,
		authority_meta,
		"difficulty_mismatch",
		"difficulty_mismatch_was_accepted"
	)

	var category_config := _authority_config(
		"classic_7x7_simple",
		&"simple",
		"commission_recover_supply"
	)
	category_config["selected_equipment_ids"] = ["authority:con"]
	_check_authority_issue(
		category_config,
		authority_meta,
		"warehouse_instance_not_equipment:authority:con",
		"consumable_was_accepted_as_equipment"
	)

	var cross_category_config := _authority_config(
		"classic_7x7_simple",
		&"simple",
		"commission_recover_supply"
	)
	cross_category_config["selected_equipment_ids"] = ["authority:eq"]
	cross_category_config["selected_consumable_ids"] = ["authority:eq"]
	_check_authority_issue(
		cross_category_config,
		authority_meta,
		"duplicate_selected_instance:authority:eq",
		"cross_category_duplicate_instance_was_accepted"
	)

	var duplicate_slot_config := _authority_config(
		"classic_7x7_simple",
		&"simple",
		"commission_recover_supply"
	)
	duplicate_slot_config["selected_equipment_ids"] = [
		"authority:eq",
		"authority:eq_same_slot",
	]
	_check_authority_issue(
		duplicate_slot_config,
		authority_meta,
		"duplicate_equipment_slot:rig",
		"duplicate_equipment_slot_was_accepted"
	)

	var capacity_config := _authority_config(
		"classic_7x7_simple",
		&"simple",
		"commission_recover_supply"
	)
	capacity_config["selected_consumable_ids"] = [
		"authority:heavy_1",
		"authority:heavy_2",
		"authority:heavy_3",
	]
	_check_authority_issue(
		capacity_config,
		authority_meta,
		"carry_weight_exceeds_authoritative_capacity",
		"authoritative_capacity_overflow_was_accepted"
	)

	var illegal_commission_config := _authority_config(
		"classic_7x7_normal",
		&"normal",
		"commission_critical_extract"
	)
	_check_authority_issue(
		illegal_commission_config,
		authority_meta,
		"objective_not_legal_for_map",
		"map_illegal_commission_was_accepted"
	)

	var empty_id_meta: Dictionary = authority_meta.duplicate(true)
	empty_id_meta["warehouse_items"] = [{"item_id": "eq_goggles"}]
	var synthetic_id_config := _authority_config(
		"classic_7x7_simple",
		&"simple",
		"commission_recover_supply"
	)
	synthetic_id_config["selected_equipment_ids"] = ["eq_goggles"]
	_check_authority_issue(
		synthetic_id_config,
		empty_id_meta,
		"warehouse_instance_id_empty:0",
		"normalized_synthetic_warehouse_id_was_accepted"
	)

	var duplicate_id_meta: Dictionary = authority_meta.duplicate(true)
	duplicate_id_meta["warehouse_items"] = [
		{"instance_id": "authority:duplicate", "item_id": "eq_goggles"},
		{"instance_id": "authority:duplicate", "item_id": "eq_goggles"},
	]
	var duplicate_id_config := _authority_config(
		"classic_7x7_simple",
		&"simple",
		"commission_recover_supply"
	)
	duplicate_id_config["selected_equipment_ids"] = ["authority:duplicate"]
	_check_authority_issue(
		duplicate_id_config,
		duplicate_id_meta,
		"warehouse_instance_id_duplicate:authority:duplicate",
		"duplicate_raw_warehouse_id_was_accepted"
	)

	var tutorial_selection := DeployConfigScript.select_map(
		DeployConfigScript.default_config(31, authority_meta),
		"tutorial_5x5"
	)
	var tutorial_authorization := RunStartConfigScript.authorize_with_meta(
		DeployConfigScript.build_run_start_config(
			tutorial_selection.get("config", {}) as Dictionary
		),
		authority_meta
	)
	_check(
		bool(tutorial_authorization.get("ok", false))
		and str(
			(tutorial_authorization.get("config", {}) as Dictionary).get(
				"map_config_id",
				""
			)
		)
		== "tutorial_5x5",
		"tutorial_standard_route_failed_meta_authority"
	)

	var controller := RunRuntimeControllerScript.new()
	controller.bind_meta_progress_adapter(adapter)

	var locked_candidates := M7ContentCatalogScript.commission_offer_candidates(
		"classic_13x13_hell",
		int(authority_meta.get("run_count", 0))
	)
	var locked_objective := str((locked_candidates[0] as Dictionary).get("id", ""))
	var locked_config := _authority_config(
		"classic_13x13_hell",
		&"hell",
		locked_objective
	)
	locked_config["backpack_capacity"] = 999
	locked_config["mine_dmg_reduce"] = 999
	var locked: Dictionary = controller.command_bus.dispatch(
		&"start_standard_run",
		{"run_start_config": locked_config}
	)
	_check(
		not bool(locked.get("ok", true))
		and StringName(locked.get("status", &"")) == &"invalid_run_start_authority",
		"locked_map_bypassed_meta_authority"
	)
	_check(
		((locked.get("action_result", {}) as Dictionary).get("issues", []) as Array).has(
			"map_not_unlocked"
		),
		"locked_map_rejection_lost_reason"
	)

	var forged_item_config := _authority_config(
		"classic_7x7_simple",
		&"simple",
		"commission_recover_supply"
	)
	forged_item_config["selected_equipment_ids"] = ["authority:missing"]
	forged_item_config["selected_equipment_items"] = [{
		"instance_id": "authority:missing",
		"item_id": "eq_recovery_bag",
		"can_equip": true,
		"effect_amount": 999,
	}]
	var forged_item: Dictionary = controller.command_bus.dispatch(
		&"start_standard_run",
		{"run_start_config": forged_item_config}
	)
	_check(
		not bool(forged_item.get("ok", true))
		and (
			(forged_item.get("action_result", {}) as Dictionary).get("issues", []) as Array
		).has(
			"equipment_instance_not_in_warehouse:authority:missing"
		),
		"forged_warehouse_instance_bypassed_meta_authority"
	)

	var trusted_config := _authority_config(
		"classic_7x7_simple",
		&"simple",
		"commission_recover_supply"
	)
	trusted_config["selected_equipment_ids"] = ["authority:eq"]
	trusted_config["selected_consumable_ids"] = ["authority:con"]
	trusted_config["selected_equipment_items"] = [{
		"instance_id": "authority:eq",
		"item_id": "eq_old_vest",
		"can_equip": true,
		"effect_amount": 999,
	}]
	trusted_config["selected_consumable_items"] = [{
		"instance_id": "authority:con",
		"item_id": "con_ration",
		"can_consume": true,
		"weight": 0,
	}]
	trusted_config["backpack_capacity"] = 999
	trusted_config["failure_salvage_capacity"] = 999
	trusted_config["mine_dmg_reduce"] = 999
	var trusted_start: Dictionary = controller.command_bus.dispatch(
		&"start_standard_run",
		{"run_start_config": trusted_config}
	)
	_check(bool(trusted_start.get("ok", false)), "trusted_meta_start_was_rejected")
	if bool(trusted_start.get("ok", false)):
		var authoritative := controller.context.run_start_config as Dictionary
		_check(
			int(authoritative.get("backpack_capacity", -1)) == 12,
			"forged_backpack_capacity_was_not_recomputed"
		)
		_check(
			int(authoritative.get("failure_salvage_capacity", -1)) == 4,
			"forged_salvage_capacity_was_not_recomputed"
		)
		_check(
			int(authoritative.get("mine_dmg_reduce", -1)) == 0,
			"forged_damage_reduction_was_not_recomputed"
		)
		var equipment := authoritative.get("selected_equipment_items", []) as Array
		_check(
			equipment.size() == 1
			and str((equipment[0] as Dictionary).get("item_id", "")) == "eq_recovery_bag",
			"selected_equipment_was_not_rebuilt_from_warehouse"
		)
		var consumables := authoritative.get("selected_consumable_items", []) as Array
		_check(
			consumables.size() == 1
			and int((consumables[0] as Dictionary).get("weight", 0)) > 0,
			"selected_consumable_was_not_rebuilt_from_warehouse"
		)
	controller.bind_meta_progress_adapter(null)
	controller.in_run_runtime.bind(null)
	controller.command_bus.bind_runtime_controller(null)


func _authority_config(
	map_id: String,
	difficulty: StringName,
	objective_id: String
) -> Dictionary:
	var config := RunStartConfigScript.default_config()
	config["map_config_id"] = map_id
	config["difficulty"] = difficulty
	config["selected_difficulty"] = difficulty
	config["selected_objective_id"] = objective_id
	config["selected_equipment_items"] = []
	config["selected_consumable_items"] = []
	config["selected_equipment_ids"] = []
	config["selected_consumable_ids"] = []
	return config


func _check_authority_issue(
	config: Dictionary,
	meta_summary: Dictionary,
	expected_issue: String,
	message: String
) -> void:
	var authorization := RunStartConfigScript.authorize_with_meta(config, meta_summary)
	var issues := authorization.get("issues", []) as Array
	_check(not bool(authorization.get("ok", true)) and issues.has(expected_issue), message)


func _candidate_ids(candidates: Array) -> Array[String]:
	var result: Array[String] = []
	for raw_candidate in candidates:
		result.append(str((raw_candidate as Dictionary).get("id", "")))
	return result


func _test_tutorial_content_and_semantic_actions() -> void:
	var definitions := TutorialServiceScript.popup_definitions()
	_check(definitions.size() == 13, "tutorial_content_count_not_13")
	var expected_contracts: Dictionary = {
		&"spawn_intro": _tutorial_popup_contract(
			"新员工说明",
			true,
			true,
			false,
			false,
			[&"move_up", &"move_down", &"move_left", &"move_right"],
			"开始作业",
			&"ui_accept"
		),
		&"number_rule": _tutorial_popup_contract("区域扫描图", false, false, true, false, []),
		&"mine_rule": _tutorial_popup_contract("雷险区", false, false, true, true, []),
		&"event_rule": _tutorial_popup_contract("狐狸旅商", false, false, true, false, [&"interact"]),
		&"dice_rule": _tutorial_popup_contract("赌徒", false, false, true, false, [&"interact"]),
		&"altar_rule": _tutorial_popup_contract("异常祭坛", false, false, true, false, [&"interact"]),
		&"trap_rule": _tutorial_popup_contract("机关装置", false, false, true, false, [&"interact"]),
		&"monster_rule": _tutorial_popup_contract("异常体区域", false, false, true, false, [&"attack"]),
		&"chest_rule": _tutorial_popup_contract("物资箱", false, false, true, false, [&"interact"]),
		&"map_rule": _tutorial_popup_contract("区域扫描图操作", false, false, true, false, [&"open_map", &"ui_accept"]),
		&"mine_review": _tutorial_popup_contract("雷险复查", false, false, true, true, [&"open_map"]),
		&"route_rule": _tutorial_popup_contract("路线规划", false, false, true, false, [&"open_map"]),
		&"exit_goal": _tutorial_popup_contract(
			"撤离信标",
			true,
			true,
			false,
			false,
			[&"request_extract"],
			"我知道了",
			&"ui_accept"
		),
	}
	var semantic_contract_ok := definitions.size() == expected_contracts.size()
	for raw_id in definitions.keys():
		var popup_id := StringName(raw_id)
		if (
			not expected_contracts.has(popup_id)
			or _normalized_tutorial_popup_contract(definitions[raw_id] as Dictionary)
			!= (expected_contracts[popup_id] as Dictionary)
		):
			semantic_contract_ok = false
			break
	_check(semantic_contract_ok, "tutorial_popup_semantic_contract_drift")
	var map_rule := definitions.get(&"map_rule", {}) as Dictionary
	var map_rule_template := str(map_rule.get("message_template", ""))
	_check(map_rule_template.contains("左键单击未知格"), "tutorial_map_pointer_activation_guidance_missing")
	_check(map_rule_template.contains("{ui_accept}"), "tutorial_map_semantic_activation_guidance_missing")
	_check(map_rule_template.contains("已探索且可回传"), "tutorial_map_return_eligibility_guidance_missing")
	_check(not map_rule_template.contains("{flag_cell}"), "tutorial_map_guidance_still_routes_to_current_cell_flag_action")
	var mine_review_template := str((definitions.get(&"mine_review", {}) as Dictionary).get("message_template", ""))
	var route_rule_template := str((definitions.get(&"route_rule", {}) as Dictionary).get("message_template", ""))
	_check(mine_review_template.contains("已探索且可回传的安全格"), "tutorial_mine_review_overstates_fast_return_eligibility")
	_check(route_rule_template.contains("已探索且可回传的安全格"), "tutorial_route_rule_overstates_fast_return_eligibility")
	var definitions_fingerprint := JSON.stringify(definitions).sha256_text().to_upper()
	_check(
		definitions_fingerprint == "3D4B5AF22BF82AD72813CE61BA2CEF1155647B368620C14B36B34E6AEEDC3067",
		"tutorial_popup_copy_fingerprint_drift:%s" % definitions_fingerprint
	)
	var blocking_ids: Array[StringName] = []
	for raw_id in definitions.keys():
		var popup_id := StringName(raw_id)
		var definition := definitions[raw_id] as Dictionary
		if bool(definition.get("blocking", false)):
			blocking_ids.append(popup_id)
		else:
			_check(bool(definition.get("room_scoped", false)), "nonblocking_not_room_scoped:%s" % String(popup_id))
		var template := str(definition.get("message_template", ""))
		for forbidden in ["按 F", "按 E", "按 M", "WASD", "Space/J"]:
			_check(template.find(forbidden) < 0, "hardcoded_key_copy:%s:%s" % [String(popup_id), forbidden])
	blocking_ids.sort()
	_check(blocking_ids.size() == 2 and blocking_ids.has(&"exit_goal") and blocking_ids.has(&"spawn_intro"), "blocking_contract_not_spawn_exit")
	_check(bool((definitions.get(&"mine_rule", {}) as Dictionary).get("show_after_room_effect", false)), "mine_hint_not_after_effect")
	_check(bool((definitions.get(&"mine_review", {}) as Dictionary).get("show_after_room_effect", false)), "mine_review_not_after_effect")

	var context := RunContextScript.new()
	context.mode = &"tutorial"
	context.tutorial_triggers = {"0,0": &"event_rule", "1,0": &"spawn_intro", "2,0": &"exit_goal"}
	context.event_state = {"event_type": &"dice"}
	var event_id := TutorialServiceScript.trigger_for(context, Vector2i(0, 0))
	_check(event_id == &"dice_rule", "event_variant_not_dice")
	_check(not bool(context.tutorial_popup.get("blocking", true)), "event_variant_blocking")
	_check(str(context.tutorial_popup.get("message", "")).find("{interact}") < 0, "semantic_token_not_resolved")
	var hints := context.tutorial_popup.get("action_hints", []) as Array
	_check(not hints.is_empty() and StringName((hints[0] as Dictionary).get("action_id", &"")) == &"interact", "semantic_action_descriptor_missing")
	_check(str((hints[0] as Dictionary).get("display_label", "")).find(SemanticActionHintScript.display_label(&"interact")) >= 0, "semantic_action_label_not_input_map")

	TutorialServiceScript.trigger_for(context, Vector2i(1, 0))
	_check(bool(context.tutorial_popup.get("blocking", false)), "spawn_not_blocking")
	TutorialServiceScript.confirm_popup(context)
	_check(context.tutorial_shown.has("spawn_intro"), "spawn_once_not_recorded")
	TutorialServiceScript.trigger_for(context, Vector2i(2, 0))
	_check(bool(context.tutorial_popup.get("blocking", false)), "exit_not_blocking")


func _tutorial_popup_contract(
	title: String,
	blocking: bool,
	once: bool,
	room_scoped: bool,
	show_after_room_effect: bool,
	action_ids: Array,
	confirm_text: String = "继续",
	confirm_action: StringName = &"ui_accept"
) -> Dictionary:
	return {
		"title": title,
		"blocking": blocking,
		"once": once,
		"room_scoped": room_scoped,
		"show_after_room_effect": show_after_room_effect,
		"action_ids": action_ids.duplicate(),
		"confirm_text": confirm_text,
		"confirm_action": confirm_action,
	}


func _normalized_tutorial_popup_contract(definition: Dictionary) -> Dictionary:
	return _tutorial_popup_contract(
		str(definition.get("title", "")),
		bool(definition.get("blocking", false)),
		bool(definition.get("once", false)),
		bool(definition.get("room_scoped", true)),
		bool(definition.get("show_after_room_effect", false)),
		definition.get("action_ids", []) as Array,
		str(definition.get("confirm_text", "继续")),
		StringName(definition.get("confirm_action", &"ui_accept"))
	)


func _test_persistence_isolation_and_replay() -> void:
	var adapter := MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(save_path, "i3r_tutorial_map_mode")
	adapter.clear()
	adapter.data["gold"] = 123
	adapter.data["run_count"] = 7
	adapter.data["extract_count"] = 2
	adapter.data["fail_count"] = 3
	adapter.data["abandon_count"] = 2
	adapter.data["history_records"] = [{"history_id": "before"}]
	adapter.data["commission_history"] = [{"result_id": "before"}]
	adapter.data["map_success_counts"] = {"classic_7x7_simple": 2}
	_check(adapter.save(), "tutorial_fixture_save_failed")
	var before := adapter.data.duplicate(true)

	var failure_snapshot := _tutorial_terminal_result(&"failure", "tutorial_failure")
	var failed_commit := adapter.apply_settlement(failure_snapshot)
	_check(str(failed_commit.get("status", "")) == "tutorial_incomplete_no_write", "tutorial_failure_status")
	_check(adapter.data == before, "tutorial_failure_polluted_meta")
	_check_terminal_result_actions(
		failure_snapshot,
		failed_commit,
		&"tutorial_incomplete_no_write",
		"tutorial_failure"
	)

	var abandon_snapshot := _tutorial_terminal_result(&"abandon", "tutorial_abandon")
	var abandon_commit := adapter.apply_settlement(abandon_snapshot)
	_check(str(abandon_commit.get("status", "")) == "tutorial_incomplete_no_write", "tutorial_abandon_status")
	_check(adapter.data == before, "tutorial_abandon_polluted_meta")
	_check_terminal_result_actions(
		abandon_snapshot,
		abandon_commit,
		&"tutorial_incomplete_no_write",
		"tutorial_abandon"
	)

	var success_snapshot := _tutorial_terminal_result(&"success", "tutorial_success")
	var success_commit := adapter.apply_settlement(success_snapshot)
	_check(bool(success_commit.get("ok", false)), "tutorial_completion_save_failed")
	_check(str(success_commit.get("status", "")) == "tutorial_completed", "tutorial_completion_status")
	_check_terminal_result_actions(
		success_snapshot,
		success_commit,
		&"tutorial_completed",
		"tutorial_success"
	)
	var after := adapter.data.duplicate(true)
	_check(bool(after.get("tutorial_completed", false)), "tutorial_completion_marker_missing")
	var normalized_after := after.duplicate(true)
	normalized_after["tutorial_completed"] = false
	_check(normalized_after == before, "tutorial_completion_changed_non_marker_state")

	var replay_before := adapter.data.duplicate(true)
	var replay_snapshot := _tutorial_terminal_result(&"success", "tutorial_replay")
	var replay_commit := adapter.apply_settlement(replay_snapshot)
	_check(str(replay_commit.get("status", "")) == "tutorial_replay_complete", "tutorial_replay_status")
	_check(adapter.data == replay_before, "tutorial_replay_polluted_meta")
	_check_terminal_result_actions(
		replay_snapshot,
		replay_commit,
		&"tutorial_replay_complete",
		"tutorial_replay"
	)
	_check_ordinary_result_actions()

	var reloaded := MetaProgressAdapterScript.new()
	reloaded.set_active_profile_path(save_path, "i3r_tutorial_map_mode")
	var summary := reloaded.get_summary()
	_check(bool(summary.get("tutorial_completed", false)), "tutorial_completion_not_persisted")
	_check(int(summary.get("gold", -1)) == 123, "tutorial_gold_pollution")
	_check(int(summary.get("run_count", -1)) == 7, "tutorial_run_count_pollution")
	_check(int(summary.get("extract_count", -1)) == 2, "tutorial_success_count_pollution")
	_check(int(summary.get("fail_count", -1)) == 3, "tutorial_fail_count_pollution")
	_check((summary.get("history_records", []) as Array).size() == 1, "tutorial_history_pollution")
	_check((summary.get("commission_history", []) as Array).size() == 1, "tutorial_commission_pollution")
	_check(int((summary.get("map_success_counts", {}) as Dictionary).get("classic_7x7_simple", 0)) == 2, "tutorial_map_success_pollution")
	_check(not (summary.get("map_success_counts", {}) as Dictionary).has("tutorial_5x5"), "tutorial_success_catalog_pollution")

	var replay_config := DeployConfigScript.default_config(18, summary)
	var replay_projection := DeployMapProjectionScript.project(replay_config)
	var replay_map := _projected_map(replay_projection, "tutorial_5x5")
	_check(bool(replay_map.get("tutorial_completed", false)), "deploy_completion_status_missing")
	_check(str(replay_map.get("completion_label", "")).find("可重播") >= 0, "deploy_replay_status_missing")


func _check_terminal_result_actions(result_snapshot: Dictionary, commit: Dictionary, expected_state: StringName, label: String) -> void:
	var display := RunSceneResultControllerScript.build_result_display_snapshot(result_snapshot, {}, commit)
	_check(StringName(display.get("persistence_state", &"")) == expected_state, "%s_persistence_state" % label)
	_check(bool(display.get("normal_exit_allowed", false)), "%s_exit_blocked" % label)
	_check(not bool(display.get("retry_save_allowed", true)), "%s_retry_exposed" % label)
	_check(not bool(display.get("discard_unsaved_allowed", true)), "%s_discard_exposed" % label)
	var presentation := ResultPresentationModelScript.build(display)
	var persistence_text := str(presentation.get("persistence_text", ""))
	_check(persistence_text.find("尚未保存，请重试") < 0, "%s_false_retry_copy" % label)
	match expected_state:
		&"tutorial_completed":
			_check(persistence_text.find("完成状态已保存") >= 0, "%s_completion_copy" % label)
		&"tutorial_replay_complete":
			_check(persistence_text.find("没有重复结算") >= 0, "%s_replay_copy" % label)
		&"tutorial_incomplete_no_write":
			_check(persistence_text.find("未写入正式档案") >= 0, "%s_incomplete_copy" % label)


func _check_ordinary_result_actions() -> void:
	var result_snapshot := _ordinary_result_fixture()
	for completed_state in [&"committed", &"duplicate_ignored"]:
		var completed := RunSceneResultControllerScript.build_result_display_snapshot(
			result_snapshot,
			{},
			{"ok": true, "status": completed_state}
		)
		_check(bool(completed.get("normal_exit_allowed", false)), "ordinary_%s_exit_blocked" % String(completed_state))
		_check(not bool(completed.get("retry_save_allowed", true)), "ordinary_%s_retry_exposed" % String(completed_state))
	var failed := RunSceneResultControllerScript.build_result_display_snapshot(
		result_snapshot,
		{},
		{"ok": false, "status": &"save_failed"}
	)
	_check(not bool(failed.get("normal_exit_allowed", true)), "ordinary_save_failed_exit_allowed")
	_check(bool(failed.get("retry_save_allowed", false)), "ordinary_save_failed_retry_missing")
	_check(bool(failed.get("discard_unsaved_allowed", false)), "ordinary_save_failed_discard_missing")


func _tutorial_terminal_result(branch: StringName, label: String) -> Dictionary:
	var state_machine := RunStateMachineScript.new()
	var context := RunContextScript.new()
	var start_result := state_machine.start_standard_run(context, {"map_config_id": "tutorial_5x5"})
	_check(bool(start_result.get("ok", false)), "%s_start_failed" % label)
	if not bool(start_result.get("ok", false)):
		return {}
	TutorialServiceScript.confirm_popup(context)
	context.asset_ledger.add_currency(&"black_coin", 999, "tutorial_settlement_test")
	context.asset_ledger.add_currency(&"gold_coin", 77, "tutorial_settlement_test")
	context.asset_ledger.create_item_instance({
		"instance_id": "%s_item" % label,
		"item_id": "col_tutorial_test",
		"display_name": "教学测试物资",
		"item_type": &"collectible",
		"rarity": &"tier_3",
		"weight": 1,
		"base_value": 99,
	}, &"inventory")
	_check(context.asset_ledger.get_currency(&"black_coin") == 999, "%s_seed_black_coin" % label)
	_check(context.asset_ledger.get_currency(&"gold_coin") == 77, "%s_seed_gold_coin" % label)

	var terminal_result: Dictionary = {}
	match branch:
		&"success":
			var request_result := state_machine.request_extract(context, true, "%s_extract" % label, &"player")
			_check(bool(request_result.get("ok", false)), "%s_extract_request_failed" % label)
			terminal_result = state_machine.confirm_extract(context, true)
			_check(context.phase == &"extracted", "%s_not_extracted" % label)
			_check(context.outcome == "Training Complete", "%s_outcome_not_training_complete" % label)
		&"failure":
			terminal_result = state_machine.fail_run(context, "runtime_combat_defeat")
			_check(StringName(terminal_result.get("status", &"")) == &"failed", "%s_not_directly_failed" % label)
			_check(context.phase == &"failed", "%s_failure_salvage_phase_exposed" % label)
		&"abandon":
			terminal_result = state_machine.abandon_run(context, "player_abandoned")
			_check(context.phase == &"abandoned", "%s_not_abandoned" % label)
		_:
			_check(false, "%s_unknown_branch" % label)
	_check(bool(terminal_result.get("ok", false)), "%s_terminal_transition_failed" % label)

	var snapshot := context.result_snapshot.duplicate(true)
	var settlement := snapshot.get("settlement", {}) as Dictionary
	_check(bool(settlement.get("tutorial_completion_only", false)), "%s_policy_not_consumed" % label)
	_check(bool(settlement.get("finalized", false)), "%s_settlement_not_finalized" % label)
	_check(not bool(settlement.get("requires_salvage_selection", true)), "%s_salvage_still_required" % label)
	for field in [
		"gold_coin",
		"run_black_coin",
		"black_coin_lost",
		"pending_gold_lost",
		"black_coin_converted",
		"run_black_coin_converted",
		"safe_yield",
		"safe_yield_retained",
		"gold_coin_retained",
		"gold_coin_gained",
		"long_term_gold_gained",
	]:
		_check(int(settlement.get(field, -1)) == 0, "%s_nonzero_currency:%s" % [label, field])
	for field in [
		"settlement_pool",
		"salvaged_items",
		"lost_items",
		"extracted_items",
		"warehouse_items",
		"warehouse_lite",
		"room_floor_lost_items",
		"cleared_consumables",
	]:
		var items: Variant = settlement.get(field, null)
		_check(items is Array and (items as Array).is_empty(), "%s_nonempty_items:%s" % [label, field])
	return snapshot


func _ordinary_result_fixture() -> Dictionary:
	return {
		"result_id": "ordinary_result",
		"mode": "standard",
		"outcome": "Extracted",
		"run_start_config": {"map_config_id": "classic_7x7_simple"},
		"settlement": {
			"outcome": &"success",
			"finalized": true,
		},
	}


func _scale_group(projection: Dictionary, scale_id: StringName) -> Dictionary:
	for raw_group in projection.get("scale_options", []):
		var group := raw_group as Dictionary
		if StringName(group.get("scale_id", &"")) == scale_id:
			return group
	return {}


func _projected_map(projection: Dictionary, map_id: String) -> Dictionary:
	for raw_group in projection.get("scale_options", []):
		for raw_map in (raw_group as Dictionary).get("maps", []):
			var map_data := raw_map as Dictionary
			if str(map_data.get("map_config_id", "")) == map_id:
				return map_data
	return {}


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = save_path + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
