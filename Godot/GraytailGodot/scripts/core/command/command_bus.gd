extends RefCounted
class_name CommandBus

# All player and Debug UI commands go through CommandBus.

signal command_requested(command_name: StringName, payload: Dictionary)
signal state_changed(snapshot: Dictionary)
signal result_available(summary: Dictionary)

const DEFAULT_ACTOR_ID := &"player"
const REJECTION_EVENT_OPTION_UNAVAILABLE := "event_option_unavailable"
const REJECTION_CANNOT_EXTRACT := "cannot_extract"
const REJECTION_NO_EXTRACT_REQUEST := "no_extract_request"
const EncounterContractScript := preload("res://scripts/core/run/encounter/encounter_contract.gd")
const DebugGateScript := preload("res://scripts/core/debug/debug_gate.gd")
const RunEffectApplierScript := preload("res://scripts/core/run/run_effect_applier.gd")
const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")

var context: RunContext
var runtime_controller
var room_resolver: RoomResolver = RoomResolver.new()
var command_sequence: int = 0


func dispatch(command_name: StringName, payload: Dictionary = {}) -> Dictionary:
	var command: Dictionary = _normalize_command(command_name, payload)
	var command_payload: Dictionary = command.get("payload", {})
	if _is_debug_command_request(command_name, command_payload) and not DebugGateScript.is_debug_tools_enabled():
		var blocked := DebugGateScript.disabled_result(DEFAULT_ACTOR_ID)
		return CommandResult.from_action(command, blocked, [], [], _snapshot_delta_for(blocked))
	if context == null and runtime_controller != null:
		context = runtime_controller.context
	var event_start: int = _event_count()
	var transaction_start: int = _transaction_count()
	if context != null:
		context.active_command = command.duplicate(true)
		if _is_debug_command_request(command_name, command_payload):
			context.record_debug_command(String(command_name), command_payload)
	command_requested.emit(command_name, command)
	var action_result: Dictionary = {}
	match command_name:
		&"start_demo_run":
			action_result = start_demo_run()
		&"start_tutorial_run":
			action_result = start_tutorial_run()
		&"start_standard_run":
			action_result = start_standard_run(command_payload)
		&"move_by":
			action_result = move_by(command_payload.get("delta", Vector2i.ZERO))
		&"attempt_room_transition":
			action_result = attempt_room_transition(command_payload.get("direction", Vector2i.ZERO))
		&"toggle_flag_cell":
			action_result = toggle_flag_cell(command_payload.get("pos", null))
		&"flag_current_cell":
			action_result = flag_current_cell()
		&"search_current_room":
			action_result = search_current_room()
		&"interact_current_room":
			action_result = interact_current_room()
		&"interact":
			action_result = interact()
		&"fight_current_enemy":
			action_result = fight_current_enemy()
		&"teleport_to_explored":
			action_result = teleport_to_explored(command_payload.get("pos", Vector2i.ZERO))
		&"select_event_option":
			action_result = select_event_option(StringName(command_payload.get("option_id", &"default")))
		&"select_encounter_option":
			action_result = select_encounter_option(StringName(command_payload.get("option_id", &"default")))
		&"pickup_ground_item":
			action_result = pickup_ground_item(String(command_payload.get("instance_id", "")))
		&"drop_inventory_item":
			action_result = drop_inventory_item(String(command_payload.get("instance_id", "")))
		&"use_consumable", &"use_item":
			action_result = use_consumable(String(command_payload.get("instance_id", "")))
		&"equip_item":
			action_result = equip_item(String(command_payload.get("instance_id", "")))
		&"unequip_item":
			action_result = unequip_item(String(command_payload.get("instance_id", "")))
		&"abandon_run":
			action_result = abandon_run(String(command_payload.get("reason", "player_abandoned")))
		&"request_extract":
			action_result = request_extract()
		&"confirm_extract":
			action_result = confirm_extract()
		&"cancel_extract":
			action_result = cancel_extract()
		&"extract":
			action_result = extract()
		&"restart_run":
			action_result = restart_run()
		&"confirm_tutorial_popup":
			action_result = confirm_tutorial_popup()
		&"open_map":
			action_result = _mark_open_map_placeholder()
		&"debug_add_run_black_coin":
			action_result = debug_add_run_black_coin(int(command_payload.get("amount", 25)))
		&"debug_teleport_to_exit":
			action_result = debug_teleport_to_exit()
		&"debug_teleport_to":
			action_result = debug_teleport_to(_vector2i_from(command_payload.get("pos", Vector2i.ZERO)), bool(command_payload.get("enter_room", true)))
		&"debug_reveal_full_map":
			action_result = debug_reveal_full_map()
		&"debug_spawn_test_item_floor":
			action_result = debug_spawn_test_item(RunAssetLedger.LOCATION_ROOM_FLOOR)
		&"debug_spawn_test_item_backpack":
			action_result = debug_spawn_test_item(RunAssetLedger.LOCATION_INVENTORY)
		&"debug_heal_full":
			action_result = debug_heal_full()
		&"debug_force_extract":
			action_result = debug_force_extract()
		&"debug_force_fail":
			action_result = debug_force_fail(String(command_payload.get("reason", "debug_forced_failure")))
		_:
			action_result = _blocked(&"unknown_command", "unknown_command")
	if context != null:
		context.active_command.clear()
	var produced_events: Array[Dictionary] = _events_since(event_start)
	var produced_transactions: Array[Dictionary] = _transactions_since(transaction_start)
	return CommandResult.from_action(command, action_result, produced_events, produced_transactions, _snapshot_delta_for(action_result))


func bind_context(next_context: RunContext) -> void:
	context = next_context
	room_resolver.bind_runtime_controller(null)
	if context != null and context.run_active:
		room_resolver.enter_room(context)
		_emit_state()


func bind_runtime_controller(next_controller) -> void:
	runtime_controller = next_controller
	context = runtime_controller.context if runtime_controller != null else null
	room_resolver.bind_runtime_controller(runtime_controller)
	if context != null and context.run_active:
		room_resolver.enter_room(context)
		_emit_state()


func start_demo_run() -> Dictionary:
	if runtime_controller == null:
		return _blocked(&"not_ready", "runtime_controller_missing")
	var result: Dictionary = runtime_controller.start_demo_run(room_resolver)
	_emit_state()
	return result


func start_tutorial_run() -> Dictionary:
	if runtime_controller == null:
		return _blocked(&"not_ready", "runtime_controller_missing")
	var result: Dictionary = runtime_controller.start_tutorial_run(room_resolver)
	_emit_state()
	return result


func start_standard_run(payload: Dictionary = {}) -> Dictionary:
	if runtime_controller == null:
		return _blocked(&"not_ready", "runtime_controller_missing")
	var result: Dictionary = runtime_controller.start_standard_run(room_resolver, payload.get("run_start_config", {}))
	_emit_state()
	return result


func attempt_room_transition(direction: Vector2i) -> Dictionary:
	return move_by(direction)


func move_by(delta: Vector2i) -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	if abs(delta.x) + abs(delta.y) != 1:
		context.blocked_reason = "invalid_direction"
		context.last_message = "Invalid move: only four-direction movement is allowed."
		_emit_state()
		return _blocked(&"invalid_direction", "invalid_direction")
	var target: Vector2i = context.get_current_pos() + delta
	if not context.is_inside(target):
		context.blocked_reason = "out_of_bounds"
		context.last_message = "Blocked by map boundary."
		_emit_state()
		return _blocked(&"out_of_bounds", "out_of_bounds")
	if context.intel_map.is_flagged(target):
		context.blocked_reason = "blocked_flagged"
		context.last_message = "Blocked by flag."
		_emit_state()
		return _blocked(&"blocked_flagged", "blocked_flagged")
	if context.move_requires_revealed and not context.intel_map.is_revealed(target):
		context.blocked_reason = "blocked_hidden"
		context.last_message = "Blocked: target is not revealed."
		_emit_state()
		return _blocked(&"blocked_hidden", "blocked_hidden")

	context.blocked_reason = ""
	context.player_pos = target
	context.current_pos = target
	RunInventory.record_move(context)
	room_resolver.enter_room(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)
	return {"ok": true, "status": &"moved", "position": target, "actor_id": DEFAULT_ACTOR_ID}


func toggle_flag_cell(pos = null) -> Dictionary:
	if context == null or context.intel_map == null:
		return _blocked(&"not_ready", "not_ready")
	var target: Vector2i = context.get_current_pos() if pos == null else pos
	context.intel_map.toggle_flag(target)
	context.last_message = "Flag toggled at %s." % _format_pos(target)
	_emit_state()
	return {"ok": true, "status": &"flag_toggled", "position": target, "actor_id": DEFAULT_ACTOR_ID}


func flag_current_cell() -> Dictionary:
	return toggle_flag_cell()


func search_current_room() -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", _current_blocked_reason())
	var result: Dictionary = room_resolver.search_current_room(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)
	return result


func interact_current_room() -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", _current_blocked_reason())
	if context.current_room_type == &"Exit":
		if context.phase == &"confirm_extract":
			return confirm_extract()
		else:
			return request_extract()
	var result: Dictionary = room_resolver.interact_current_room(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)
	return result


func interact() -> Dictionary:
	return interact_current_room()


func fight_current_enemy() -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", _current_blocked_reason())
	var result: Dictionary = room_resolver.fight_current_enemy(context)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)
	return result


func select_event_option(option_id: StringName = &"default") -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", _current_blocked_reason())
	var result: Dictionary = room_resolver.select_event_option(context, option_id)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)
	return result


func select_encounter_option(option_id: StringName = &"default") -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", _current_blocked_reason())
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	match context.current_room_type:
		&"Normal", &"Chest":
			if option_id in [&"default", &"search", &"open_chest"]:
				return search_current_room()
		&"Event":
			return select_event_option(option_id)
		&"Monster":
			if option_id in [&"default", EncounterContractScript.OPTION_ATTACK_BASIC]:
				return fight_current_enemy()
	context.blocked_reason = "encounter_option_unavailable"
	context.last_message = "Encounter option unavailable."
	_emit_state()
	return _blocked(&"encounter_option_unavailable", "encounter_option_unavailable")


func pickup_ground_item(instance_id: String = "") -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	var result: Dictionary = RunRuleService.pickup_ground_item(context, instance_id)
	context.last_reward = result.duplicate(true)
	if bool(result.get("ok", false)):
		context.blocked_reason = ""
		var item: Dictionary = result.get("item", {})
		context.last_message = "Picked up floor item: %s." % String(item.get("display_name", item.get("item_id", "item")))
	else:
		context.blocked_reason = String(result.get("reason", result.get("blocked_reason", "blocked")))
		context.last_message = "Pickup blocked: %s." % context.blocked_reason
	_emit_state()
	return result


func drop_inventory_item(instance_id: String = "") -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	var result: Dictionary = RunRuleService.drop_inventory_item(context, instance_id)
	context.last_reward = result.duplicate(true)
	if bool(result.get("ok", false)):
		context.blocked_reason = ""
		var item: Dictionary = result.get("item", {})
		context.last_message = "Dropped inventory item: %s." % String(item.get("display_name", item.get("item_id", "item")))
	else:
		context.blocked_reason = String(result.get("reason", result.get("blocked_reason", "blocked")))
		context.last_message = "Drop blocked: %s." % context.blocked_reason
	_emit_state()
	return result


func use_consumable(instance_id: String = "") -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	var result: Dictionary = RunRuleService.use_consumable(context, instance_id)
	context.last_reward = result.duplicate(true)
	if bool(result.get("ok", false)):
		context.blocked_reason = ""
		context.last_message = String(result.get("message", "Consumable used."))
	else:
		context.blocked_reason = String(result.get("reason", result.get("blocked_reason", "blocked")))
		context.last_message = "Use blocked: %s." % context.blocked_reason
	_emit_state()
	return result


func equip_item(instance_id: String = "") -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	if context == null or context.asset_ledger == null:
		return _blocked(&"not_ready", "not_ready")
	var result: Dictionary = context.asset_ledger.equip_inventory_item(instance_id)
	context.asset_ledger.sync_compat_fields(context)
	if bool(result.get("ok", false)):
		context.blocked_reason = ""
		var item: Dictionary = result.get("item", {})
		context.last_message = "Equipped item: %s." % String(item.get("display_name", item.get("item_id", "item")))
	else:
		context.blocked_reason = String(result.get("reason", result.get("blocked_reason", "blocked")))
		context.last_message = "Equip blocked: %s." % context.blocked_reason
	_emit_state()
	return result


func unequip_item(instance_id: String = "") -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	if context == null or context.asset_ledger == null:
		return _blocked(&"not_ready", "not_ready")
	var result: Dictionary = context.asset_ledger.unequip_item(instance_id)
	context.asset_ledger.sync_compat_fields(context)
	if bool(result.get("ok", false)):
		context.blocked_reason = ""
		var item: Dictionary = result.get("item", {})
		context.last_message = "Unequipped item: %s." % String(item.get("display_name", item.get("item_id", "item")))
	else:
		context.blocked_reason = String(result.get("reason", result.get("blocked_reason", "blocked")))
		context.last_message = "Unequip blocked: %s." % context.blocked_reason
	_emit_state()
	return result


func abandon_run(reason: String = "player_abandoned") -> Dictionary:
	if runtime_controller == null:
		return _blocked(&"not_ready", "runtime_controller_missing")
	var result: Dictionary = runtime_controller.abandon_run(reason)
	_emit_state()
	if bool(result.get("ok", false)) and context != null and context.result_snapshot.has("outcome"):
		result_available.emit(context.result_snapshot)
	return result


func teleport_to_explored(pos: Vector2i) -> Dictionary:
	if not _can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	if context.intel_map == null or context.truth_map == null:
		return _blocked(&"not_ready", "not_ready")
	if not context.is_inside(pos):
		context.blocked_reason = "out_of_bounds"
		context.last_message = "Teleport target is outside the map."
		_emit_state()
		return _blocked(&"out_of_bounds", "out_of_bounds")
	var eligibility: Dictionary = context.truth_map.get_return_eligibility(pos, context.intel_map)
	if bool(context.intel_map.get_cell_info(pos).get("flagged", false)):
		eligibility = {"eligible": false, "reason_code": "flagged", "intent": &"inspect_only"}
	if not bool(eligibility.get("eligible", false)):
		var reason := String(eligibility.get("reason_code", "not_return_eligible"))
		context.blocked_reason = reason
		context.last_message = "Return blocked: %s." % reason
		_emit_state()
		return _blocked(&"return_blocked", reason)

	context.blocked_reason = ""
	context.player_pos = pos
	context.current_pos = pos
	room_resolver.enter_room(context)
	context.last_message = "Teleported to explored room (%d,%d)." % [pos.x, pos.y]
	_emit_state()
	return {"ok": true, "status": &"teleported", "position": pos, "actor_id": DEFAULT_ACTOR_ID, "return_eligibility": eligibility}


func request_extract() -> Dictionary:
	if runtime_controller == null:
		return _blocked(&"not_ready", "runtime_controller_missing")
	var result: Dictionary = runtime_controller.request_extract(room_resolver, _active_command_id(), DEFAULT_ACTOR_ID)
	_emit_state()
	return result


func confirm_extract() -> Dictionary:
	if runtime_controller == null:
		return _blocked(&"not_ready", "runtime_controller_missing")
	var result: Dictionary = runtime_controller.confirm_extract(room_resolver)
	_emit_state()
	if bool(result.get("ok", false)) and context != null and context.extracted:
		result_available.emit(context.result_snapshot)
	return result


func cancel_extract() -> Dictionary:
	if runtime_controller == null:
		return _blocked(&"not_ready", "runtime_controller_missing")
	var result: Dictionary = runtime_controller.cancel_extract()
	_emit_state()
	return result


func extract() -> Dictionary:
	if runtime_controller == null:
		return _blocked(&"not_ready", "runtime_controller_missing")
	var result: Dictionary = runtime_controller.extract(room_resolver, _active_command_id(), DEFAULT_ACTOR_ID)
	_emit_state()
	if bool(result.get("ok", false)) and context != null and context.extracted:
		result_available.emit(context.result_snapshot)
	return result


func restart_run() -> Dictionary:
	if runtime_controller == null:
		return _blocked(&"not_ready", "runtime_controller_missing")
	var result: Dictionary = runtime_controller.restart_run(room_resolver)
	_emit_state()
	return result


func debug_add_run_black_coin(amount: int = 25) -> Dictionary:
	if not _has_active_run():
		return _blocked(&"not_ready", "not_ready")
	var clamped := maxi(0, amount)
	if clamped <= 0:
		return _blocked(&"invalid_amount", "invalid_amount")
	context.asset_ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, clamped, "debug_command")
	context.asset_ledger.sync_compat_fields(context)
	context.last_message = "Debug added %d run black coin through RunAssetLedger." % clamped
	context.record_event(RunEventLog.EVENT_ITEM_GAINED, _active_command_id(), DEFAULT_ACTOR_ID, "debug_command", {"currency_id": &"black_coin", "amount": clamped})
	_emit_state()
	return {"ok": true, "status": &"debug_black_coin_added", "amount": clamped, "actor_id": DEFAULT_ACTOR_ID}


func debug_teleport_to_exit() -> Dictionary:
	if not _has_active_run():
		return _blocked(&"not_ready", "not_ready")
	var exits := context.truth_map.get_exits()
	if exits.is_empty():
		return _blocked(&"no_exit", "no_exit")
	return debug_teleport_to(exits[0], true)


func debug_teleport_to(pos: Vector2i, enter_room: bool = true) -> Dictionary:
	if not _has_active_run():
		return _blocked(&"not_ready", "not_ready")
	if not context.is_inside(pos):
		return _blocked(&"out_of_bounds", "out_of_bounds")
	var debug_mode := &"debug_enter" if enter_room else &"debug_move"
	context.player_pos = pos
	context.current_pos = pos
	context.last_message = "Debug teleport to %s (%s)." % [_format_pos(pos), String(debug_mode)]
	context.record_event(RunEventLog.EVENT_ROOM_ENTERED, _active_command_id(), DEFAULT_ACTOR_ID, "debug_command", {"position": pos, "mode": debug_mode})
	if enter_room:
		room_resolver.enter_room(context)
	else:
		context.intel_map.reveal_cell(pos, context.truth_map)
		context.current_room_type = context.truth_map.get_room_type(pos)
		context.current_adjacent_mines = context.minefield_service.count_adjacent_mines(context.truth_map, pos)
	_emit_state()
	if context.failed:
		result_available.emit(context.result_snapshot)
	return {"ok": true, "status": &"debug_teleported", "position": pos, "enter_room": enter_room, "actor_id": DEFAULT_ACTOR_ID}


func debug_reveal_full_map() -> Dictionary:
	if not _has_active_run():
		return _blocked(&"not_ready", "not_ready")
	if context.intel_map == null or context.truth_map == null:
		return _blocked(&"not_ready", "not_ready")
	for x in range(context.width):
		for y in range(context.height):
			context.intel_map.reveal_cell(Vector2i(x, y), context.truth_map)
	context.last_message = "Debug revealed the full known map through IntelMap."
	context.record_event(&"debug_command", _active_command_id(), DEFAULT_ACTOR_ID, "debug_command", {"command": "debug_reveal_full_map", "width": context.width, "height": context.height})
	_emit_state()
	return {"ok": true, "status": &"debug_map_revealed", "width": context.width, "height": context.height, "actor_id": DEFAULT_ACTOR_ID}


func debug_spawn_test_item(preferred_location: StringName) -> Dictionary:
	if not _has_active_run():
		return _blocked(&"not_ready", "not_ready")
	var location := preferred_location
	if not (location in [RunAssetLedger.LOCATION_ROOM_FLOOR, RunAssetLedger.LOCATION_INVENTORY]):
		location = RunAssetLedger.LOCATION_ROOM_FLOOR
	var item_def := M3ItemCatalogScript.debug_item()
	item_def["source"] = "debug_command"
	var result: Dictionary = context.asset_ledger.add_reward_items([item_def], location, context.get_current_pos(), "debug_command")
	context.asset_ledger.sync_compat_fields(context)
	context.last_reward = result.duplicate(true)
	context.last_message = "Debug spawned a test item to %s through RunAssetLedger." % String(location)
	context.record_event(RunEventLog.EVENT_ITEM_GAINED, _active_command_id(), DEFAULT_ACTOR_ID, "debug_command", {"command": "debug_spawn_test_item", "location": location, "result": result.duplicate(true)})
	_emit_state()
	return {"ok": true, "status": &"debug_test_item_spawned", "location": location, "result": result, "actor_id": DEFAULT_ACTOR_ID}


func debug_heal_full() -> Dictionary:
	if not _has_active_run():
		return _blocked(&"not_ready", "not_ready")
	var hp_delta := context.max_hp - context.hp
	var applied: Dictionary = RunEffectApplierScript.apply_effects(context, [
		RunEffectApplierScript.effect_hp_delta(hp_delta, "debug_heal_full"),
	], runtime_controller)
	context.last_message = "Debug restored HP to full through RunEffectApplier."
	context.record_event(&"debug_command", _active_command_id(), DEFAULT_ACTOR_ID, "debug_command", {"command": "debug_heal_full", "hp": context.hp, "max_hp": context.max_hp, "hp_delta": hp_delta, "effect_results": applied.get("effect_results", [])})
	_emit_state()
	return {"ok": bool(applied.get("ok", false)), "status": &"debug_healed_full", "hp": context.hp, "max_hp": context.max_hp, "hp_delta": hp_delta, "effect_results": applied.get("effect_results", []), "actor_id": DEFAULT_ACTOR_ID}


func debug_force_extract() -> Dictionary:
	if not _has_active_run():
		return _blocked(&"not_ready", "not_ready")
	if runtime_controller == null:
		return _blocked(&"not_ready", "runtime_controller_missing")
	var result: Dictionary = runtime_controller.debug_force_extract()
	_emit_state()
	result_available.emit(context.result_snapshot)
	return result


func debug_force_fail(reason: String = "debug_forced_failure") -> Dictionary:
	if not _has_active_run():
		return _blocked(&"not_ready", "not_ready")
	if runtime_controller == null:
		return _blocked(&"not_ready", "runtime_controller_missing")
	var result: Dictionary = runtime_controller.debug_force_fail(reason)
	_emit_state()
	result_available.emit(context.result_snapshot)
	return result


func confirm_tutorial_popup() -> Dictionary:
	TutorialService.confirm_popup(context)
	_emit_state()
	return {"ok": true, "status": &"tutorial_popup_confirmed", "actor_id": DEFAULT_ACTOR_ID}


func _can_accept_command() -> bool:
	return context != null and context.can_accept_command()


func _has_active_run() -> bool:
	return context != null and context.run_started and context.run_active and context.asset_ledger != null


func _current_blocked_reason() -> String:
	if context == null:
		return "not_ready"
	if context.has_blocking_tutorial_popup():
		return "tutorial_lock"
	return "command_blocked"


func _is_debug_command_request(command_name: StringName, payload: Dictionary) -> bool:
	return DebugGateScript.is_debug_command(command_name, payload)


func _mark_open_map_placeholder() -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	context.last_message = "Map overlay placeholder opened."
	_emit_state()
	return {"ok": true, "status": &"map_opened", "actor_id": DEFAULT_ACTOR_ID}


func _emit_state() -> void:
	if context != null:
		state_changed.emit(context.get_status_snapshot())


func _format_pos(pos: Vector2i) -> String:
	return "(%d,%d)" % [pos.x, pos.y]


func _normalize_command(command_name: StringName, payload: Dictionary) -> Dictionary:
	command_sequence += 1
	var actor_id: StringName = StringName(payload.get("actor_id", DEFAULT_ACTOR_ID))
	var source: String = String(payload.get("source", "ui"))
	return {
		"command_id": "cmd_%04d_%s" % [command_sequence, String(command_name)],
		"command_name": command_name,
		"actor_id": actor_id,
		"source": source,
		"payload": payload.duplicate(true),
		"sequence": command_sequence,
	}


func _blocked(status: StringName, reason: String) -> Dictionary:
	return {"ok": false, "status": status, "reason": reason, "blocked_reason": reason, "reason_code": reason, "message_key": "command.rejected.%s" % reason, "actor_id": DEFAULT_ACTOR_ID}


func _event_count() -> int:
	if context == null or context.run_event_log == null:
		return 0
	return context.run_event_log.size()


func _transaction_count() -> int:
	if context == null or context.transaction_log == null:
		return 0
	return context.transaction_log.size()


func _events_since(start_index: int) -> Array[Dictionary]:
	if context == null or context.run_event_log == null:
		return []
	return context.run_event_log.get_events_since(start_index)


func _transactions_since(start_index: int) -> Array[Dictionary]:
	if context == null or context.transaction_log == null:
		return []
	return context.transaction_log.get_entries_since(start_index)


func _snapshot_delta_for(action_result: Dictionary) -> Dictionary:
	return {
		"status": action_result.get("status", &""),
		"reason_code": String(action_result.get("reason", action_result.get("blocked_reason", ""))),
		"refresh": &"run_status",
	}


func _active_command_id() -> String:
	if context == null:
		return ""
	return String(context.active_command.get("command_id", ""))


func _vector2i_from(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		var vector := value as Vector2
		return Vector2i(int(vector.x), int(vector.y))
	if value is Dictionary:
		var dict := value as Dictionary
		return Vector2i(int(dict.get("x", 0)), int(dict.get("y", 0)))
	return Vector2i.ZERO
