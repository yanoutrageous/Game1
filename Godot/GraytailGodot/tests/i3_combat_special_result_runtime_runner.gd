extends SceneTree

const ActorViewScript := preload("res://scripts/gameplay/runtime/g41_runtime_actor_view.gd")
const SpecialPresentationScript := preload("res://scripts/gameplay/interaction/i3_special_room_presentation_model.gd")
const WorldContextPopupScript := preload("res://scripts/gameplay/interaction/g41_world_context_popup.gd")
const ResultPresentationScript := preload("res://scripts/ui/result/result_presentation_model.gd")
const RunSceneResultControllerScript := preload("res://scripts/core/run/run_scene_result_controller.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")

const PASS_MARKER := "I3_COMBAT_SPECIAL_RESULT_RUNTIME=PASS"
const FAIL_MARKER := "I3_COMBAT_SPECIAL_RESULT_RUNTIME=FAIL"

var failures: Array[String] = []
var exit_request_count := 0
var flee_command_count := 0
var result_signal_count := 0
var blocker_path := "user://i3_combat_special_result/not_a_directory"
var blocked_save_path := blocker_path + "/meta_progress.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	await _check_combat_presentation_sequence()
	await _check_public_special_room_input()
	_check_combat_flee_is_never_double_charged()
	_check_terminal_save_retry_and_result_projection()
	_cleanup()
	for _unused in range(10):
		await process_frame
	_finish()


func _check_combat_presentation_sequence() -> void:
	var had_reduce_setting := ProjectSettings.has_setting("accessibility/reduce_motion")
	var previous_reduce := bool(ProjectSettings.get_setting("accessibility/reduce_motion", false))
	ProjectSettings.set_setting("accessibility/reduce_motion", false)
	var actor = ActorViewScript.new()
	root.add_child(actor)
	actor.set_process(false)
	var base_snapshot := {"enemy_id": "i3-sequence", "state": &"idle", "hp": 8, "max_hp": 8, "pos": Vector2(0.5, 0.5)}
	var unchanged := base_snapshot.duplicate(true)
	actor.configure(&"bat", base_snapshot)
	_require(StringName(actor.presentation_snapshot().get("phase", &"")) == &"arrival", "enemy entry did not expose an arrival phase")
	_require(bool(actor.appearance_snapshot().get("cue_visible", false)), "enemy entry cue was not visible on the first frame")
	actor._process(0.19)
	actor.configure(&"bat", _actor_snapshot(&"warning", 8))
	_require(StringName(actor.presentation_snapshot().get("phase", &"")) == &"anticipation", "warning/aim did not project anticipation")
	actor.configure(&"bat", _actor_snapshot(&"fire", 8))
	_require(StringName(actor.presentation_snapshot().get("phase", &"")) == &"impact", "active/fire did not project impact")
	actor.configure(&"bat", _actor_snapshot(&"cooldown", 8))
	_require(StringName(actor.presentation_snapshot().get("phase", &"")) == &"impact", "one-tick fire pose was not held for readability")
	_require(StringName(actor.presentation_snapshot().get("queued_authority_state", &"")) == &"cooldown", "recovery state was not queued behind the visible impact")
	actor._process(0.11)
	_require(StringName(actor.presentation_snapshot().get("phase", &"")) == &"recovery", "cooldown did not project recovery after impact")
	actor.configure(&"bat", _actor_snapshot(&"hurt", 5))
	_require(StringName(actor.presentation_snapshot().get("phase", &"")) == &"hit", "damage did not interrupt into a readable hit phase")
	actor.configure(&"bat", _actor_snapshot(&"move", 5))
	_require(StringName(actor.presentation_snapshot().get("phase", &"")) == &"hit", "hit pose disappeared before its presentation minimum")
	actor._process(0.15)
	_require(StringName(actor.presentation_snapshot().get("phase", &"")) == &"locomotion", "hit did not return to the queued movement state")
	actor.configure(&"bat", _actor_snapshot(&"dead", 0))
	_require(StringName(actor.presentation_snapshot().get("phase", &"")) == &"death", "death did not override the transient presentation queue")
	_require(base_snapshot == unchanged, "combat presentation mutated the authoritative actor snapshot")
	actor.free()

	ProjectSettings.set_setting("accessibility/reduce_motion", true)
	var reduced_actor = ActorViewScript.new()
	root.add_child(reduced_actor)
	reduced_actor.set_process(false)
	reduced_actor.configure(&"drone", {"enemy_id": "i3-reduced", "state": &"warning", "hp": 6, "max_hp": 6, "pos": Vector2(0.5, 0.5)})
	var reduced := reduced_actor.presentation_snapshot()
	_require(bool(reduced.get("reduced_motion", false)), "reduced-motion combat presentation was not selected")
	_require(StringName(reduced.get("phase", &"")) == &"anticipation", "reduced motion erased the static attack warning")
	_require(not bool(reduced_actor.appearance_snapshot().get("cue_visible", true)), "reduced motion retained the animated entry cue")
	reduced_actor.free()
	if had_reduce_setting:
		ProjectSettings.set_setting("accessibility/reduce_motion", previous_reduce)
	else:
		ProjectSettings.clear("accessibility/reduce_motion")
	await process_frame


func _check_public_special_room_input() -> void:
	var payload := {
		"display_title": "撤离信标",
		"black_coin": 42,
		"safe_yield": 9,
		"inventory_count": 3,
		"backpack_used": 5,
		"backpack_capacity": 8,
		"room_floor_item_count": 2,
		"objective_summary": "完成样本回收",
		"debug_token": "MUST_NOT_LEAK",
	}
	var unchanged := payload.duplicate(true)
	var presentation := SpecialPresentationScript.build(&"exit", payload)
	_require(payload == unchanged, "special-room projection mutated its public payload")
	_require(bool(presentation.get("read_only", false)) and not bool(presentation.get("command_allowed", true)), "special-room projection became a command authority")
	var body := String(presentation.get("body", ""))
	_require(body.contains("预计带回") and body.contains("现场遗留") and body.contains("目标"), "Exit summary omitted benefit, left-behind, or objective information")
	_require(not body.contains("MUST_NOT_LEAK"), "special-room projection leaked an unlisted diagnostic field")

	var popup = WorldContextPopupScript.new()
	root.add_child(popup)
	popup.exit_requested.connect(func(_payload: Dictionary) -> void: exit_request_count += 1)
	await process_frame
	popup.apply_context({
		"interaction_kind": &"exit",
		"world_pos": Vector2(640, 360),
		"player_world_pos": Vector2(600, 360),
		"room_bounds": Rect2(0, 0, 1280, 720),
		"payload": payload,
	})
	await process_frame
	_require(exit_request_count == 0, "Exit proximity/presentation emitted a command")
	_require(popup.primary_button.visible and popup.primary_button.text == "查看并确认撤离", "Exit public action did not describe the confirmation step")
	_require(popup.activate_primary(), "Exit public primary input was not accepted")
	_require(exit_request_count == 1, "Exit public primary input did not emit exactly one request")
	popup.free()
	await process_frame


func _check_combat_flee_is_never_double_charged() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	bus.command_requested.connect(func(command_name: StringName, _payload: Dictionary) -> void:
		if command_name == &"flee_runtime_combat":
			flee_command_count += 1
	)
	_require(bool(controller.start_demo_run(bus.room_resolver).get("ok", false)), "combat flee fixture could not start")
	var pos: Vector2i = controller.context.get_current_pos()
	controller.context.truth_map.set_room_type(pos, &"Monster")
	controller.context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, 100, "i3_flee_fixture")
	bus.room_resolver.enter_room(controller.context)
	controller.in_run_runtime.sync_room(Vector2(0.5, 0.5))
	_require(controller.in_run_runtime.has_active_combat(), "combat flee fixture did not start combat")
	var before := int(controller.context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK))
	var first: Dictionary = controller.in_run_runtime.request_flee()
	var after_first := int(controller.context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK))
	var second: Dictionary = controller.in_run_runtime.request_flee()
	var after_second := int(controller.context.asset_ledger.get_currency(RunAssetLedger.CURRENCY_BLACK))
	_require(bool(first.get("ok", false)), "first explicit combat flee was rejected")
	_require(not bool(second.get("ok", false)), "second combat flee was accepted after authorization")
	_require(after_first == before - int(floor(float(before) * 0.10)), "first combat flee did not apply the existing ten-percent rule")
	_require(after_second == after_first and flee_command_count == 1, "combat flee was charged or dispatched twice")
	controller.restart_run(bus.room_resolver)


func _check_terminal_save_retry_and_result_projection() -> void:
	var base_dir := blocker_path.get_base_dir()
	_require(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_dir)) == OK, "could not create I3 save-retry fixture directory")
	var blocker := FileAccess.open(blocker_path, FileAccess.WRITE)
	_require(blocker != null, "could not create I3 save blocker")
	if blocker == null:
		return
	blocker.store_string("blocks the settlement save parent")
	blocker.close()

	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(blocked_save_path, "i3_combat_special_result")
	var controller = RunRuntimeControllerScript.new()
	controller.bind_meta_progress_adapter(adapter)
	controller.command_bus.result_available.connect(func(_snapshot: Dictionary) -> void: result_signal_count += 1)
	_require(bool(controller.start_demo_run(controller.command_bus.room_resolver).get("ok", false)), "save-retry fixture could not start")
	var pos := Vector2i(6, 6)
	controller.context.player_pos = pos
	controller.context.current_pos = pos
	controller.command_bus.room_resolver.enter_room(controller.context)
	controller.context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, 13, "i3_save_retry")
	controller.context.asset_ledger.create_item_instance({
		"instance_id": "i3-result-item",
		"item_id": "i3-result-item",
		"display_name": "密封回收样本",
		"short_description": "撤离后带回仓库。",
		"item_type": &"collectible",
		"rarity": &"tier_3",
		"weight": 2,
		"base_value": 20,
		"can_store": true,
	}, RunAssetLedger.LOCATION_INVENTORY)
	var request: Dictionary = controller.command_bus.dispatch(&"request_extract", {"source": "i3_public_runner"})
	var confirm: Dictionary = controller.command_bus.dispatch(&"confirm_extract", {"source": "i3_public_runner"})
	_require(bool(request.get("ok", false)) and bool(confirm.get("ok", false)), "real extraction commands did not reach a terminal result: request=%s confirm=%s room=%s phase=%s" % [request, confirm, controller.context.current_room_type, controller.context.phase])
	_require(StringName(controller.last_meta_commit.get("status", &"")) == &"save_failed", "blocked terminal save did not expose save_failed")
	var terminal_snapshot: Dictionary = controller.context.result_snapshot.duplicate(true)
	var failed_display := RunSceneResultControllerScript.build_result_display_snapshot(terminal_snapshot, adapter.get_summary(), controller.last_meta_commit)
	var unchanged := failed_display.duplicate(true)
	var failed_model := ResultPresentationScript.build(failed_display)
	_require(failed_display == unchanged, "result presentation mutated the terminal display snapshot")
	_require(StringName(failed_model.get("presentation_contract", &"")) == &"i3.result.read_only.v1", "production result did not use the I3 read-only contract")
	_require(not bool(failed_model.get("normal_exit_allowed", true)) and bool(failed_model.get("retry_save_allowed", false)), "save failure did not lock normal exit and expose retry")
	_require(String(failed_model.get("summary", "")).contains("带回 1 件物资"), "result summary did not explain what the player can take back")
	_require(_section_ids(failed_model, &"warehouse_items") == ["i3-result-item"], "result item projection changed the authoritative warehouse list")
	_require(result_signal_count == 1, "terminal extraction emitted an unexpected result count")

	_require(DirAccess.remove_absolute(ProjectSettings.globalize_path(blocker_path)) == OK, "could not release I3 save blocker")
	var recovered: Dictionary = controller.command_bus.dispatch(&"retry_terminal_commit", {"source": "i3_public_runner"})
	_require(bool(recovered.get("ok", false)) and StringName(recovered.get("status", &"")) == &"committed", "public save retry did not recover the same terminal snapshot")
	var committed_data: Dictionary = adapter.data.duplicate(true)
	var duplicate: Dictionary = controller.command_bus.dispatch(&"retry_terminal_commit", {"source": "i3_public_runner"})
	_require(StringName(duplicate.get("status", &"")) == &"duplicate_ignored", "second save retry was not idempotent")
	_require(adapter.data == committed_data, "duplicate save retry changed meta progress")
	_require(result_signal_count == 1, "save retry re-emitted the terminal result")


func _actor_snapshot(state: StringName, hp: int) -> Dictionary:
	return {"enemy_id": "i3-sequence", "state": state, "hp": hp, "max_hp": 8, "pos": Vector2(0.5, 0.5)}


func _section_ids(model: Dictionary, section_id: StringName) -> Array[String]:
	var ids: Array[String] = []
	for raw_section in (model.get("item_sections", []) as Array):
		if not raw_section is Dictionary or StringName((raw_section as Dictionary).get("section_id", &"")) != section_id:
			continue
		for raw_item in ((raw_section as Dictionary).get("items", []) as Array):
			if raw_item is Dictionary:
				ids.append(String((raw_item as Dictionary).get("instance_id", "")))
	return ids


func _cleanup() -> void:
	for path in [blocked_save_path, blocked_save_path + ".tmp", blocked_save_path + ".bak", blocked_save_path + ".corrupt", blocker_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var blocked_dir := ProjectSettings.globalize_path(blocker_path)
	if DirAccess.dir_exists_absolute(blocked_dir):
		DirAccess.remove_absolute(blocked_dir)


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("%s phases=arrival,anticipation,impact,recovery,hit,death special=public_only exit=benefit,left_behind,objective flee=single_charge result=reason,consequence,persistence save_retry=idempotent reduced_motion=static" % PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		printerr("I3_COMBAT_SPECIAL_RESULT_FAILURE %s" % failure)
	print(FAIL_MARKER)
	quit(1)
