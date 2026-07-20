extends SceneTree

const M3ItemCatalogScript := preload("res://scripts/core/content/m3_item_catalog.gd")
const RunAssetLedgerScript := preload("res://scripts/core/run/run_asset_ledger.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")

const ITEM_ACTIONS := [
	&"pickup_ground_item",
	&"replace_ground_item",
	&"drop_inventory_item",
	&"use_consumable",
	&"equip_item",
	&"unequip_item",
]

var failures: Array[String] = []
var requested_commands: Array[StringName] = []
var emitted_snapshots: Array[Dictionary] = []


class RecordingItemHandler extends ItemCommandHandler:
	var calls: Array[Dictionary] = []


	func execute(_context: RunContext, action: StringName, payload: Dictionary = {}) -> Dictionary:
		calls.append({"action": action, "payload": payload.duplicate(true)})
		return {
			"action_result": {
				"ok": true,
				"status": &"delegated",
				"handler_action": action,
				"handler_payload": payload.duplicate(true),
			},
			"emit_state": true,
		}


func _init() -> void:
	_validate_delegation_and_bus_facade()
	_validate_current_item_semantics()
	_validate_static_boundary()
	if failures.is_empty():
		print("I1_COMMAND_MODULE=PASS")
		quit(0)
	else:
		for failure: String in failures:
			printerr("I1_COMMAND_MODULE=FAIL:%s" % failure)
		quit(1)


func _validate_delegation_and_bus_facade() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	_require_ok(bus.dispatch(&"start_standard_run"), "delegation start")
	requested_commands.clear()
	emitted_snapshots.clear()
	bus.command_requested.connect(_on_command_requested)
	bus.state_changed.connect(_on_state_changed)
	var handler := RecordingItemHandler.new()
	bus.item_command_handler = handler
	var commands: Array[Dictionary] = [
		{"command": &"pickup_ground_item", "action": ITEM_ACTIONS[0], "payload": {"instance_id": "pickup_probe"}},
		{"command": &"replace_ground_item", "action": ITEM_ACTIONS[1], "payload": {"ground_instance_id": "ground_probe", "drop_instance_id": "drop_probe"}},
		{"command": &"drop_inventory_item", "action": ITEM_ACTIONS[2], "payload": {"instance_id": "drop_probe"}},
		{"command": &"use_item", "action": ITEM_ACTIONS[3], "payload": {"instance_id": "use_probe"}},
		{"command": &"equip_item", "action": ITEM_ACTIONS[4], "payload": {"instance_id": "equip_probe"}},
		{"command": &"unequip_item", "action": ITEM_ACTIONS[5], "payload": {"instance_id": "unequip_probe"}},
	]
	var command_ids: Dictionary = {}
	for index in range(commands.size()):
		var probe: Dictionary = commands[index]
		var payload: Dictionary = probe.get("payload", {}).duplicate(true)
		payload["source"] = "i1_command_module"
		var result: Dictionary = bus.dispatch(StringName(probe.get("command", &"")), payload)
		_require_ok(result, "delegated command %d" % index)
		if not bool(result.get("accepted", false)):
			_fail("delegated result was not normalized as accepted: %s" % JSON.stringify(result))
		if StringName(result.get("command_name", &"")) != StringName(probe.get("command", &"")):
			_fail("CommandResult lost original command name for probe %d" % index)
		if String(result.get("source", "")) != "i1_command_module":
			_fail("CommandResult lost normalized source for probe %d" % index)
		var command_id := String(result.get("command_id", ""))
		if command_id == "" or command_ids.has(command_id):
			_fail("CommandResult command_id was empty or duplicated: %s" % command_id)
		command_ids[command_id] = true
		var action_result: Dictionary = result.get("action_result", {})
		if StringName(action_result.get("handler_action", &"")) != StringName(probe.get("action", &"")):
			_fail("handler action mismatch for probe %d: %s" % [index, JSON.stringify(result)])
	if handler.calls.size() != commands.size():
		_fail("CommandBus did not delegate exactly once per item command")
	else:
		for index in range(handler.calls.size()):
			var call: Dictionary = handler.calls[index]
			if StringName(call.get("action", &"")) != StringName(commands[index].get("action", &"")):
				_fail("delegation order/action mismatch at %d" % index)
	if requested_commands.size() != commands.size():
		_fail("CommandBus command_requested signal count changed: %d" % requested_commands.size())
	if emitted_snapshots.size() != commands.size():
		_fail("CommandBus state_changed signal count changed: %d" % emitted_snapshots.size())
	for snapshot: Dictionary in emitted_snapshots:
		if StringName(snapshot.get("_change_scope", &"")) != &"all":
			_fail("item command state signal did not use full refresh scope")

	controller.context.tutorial_popup = {"blocking": true}
	var call_count_before := handler.calls.size()
	var signal_count_before := emitted_snapshots.size()
	var blocked: Dictionary = bus.dispatch(&"pickup_ground_item", {"instance_id": "blocked_probe"})
	if bool(blocked.get("ok", true)) or String(blocked.get("reason", "")) != "command_blocked":
		_fail("bus acceptance gate did not preserve blocked command semantics: %s" % JSON.stringify(blocked))
	if handler.calls.size() != call_count_before:
		_fail("blocked item command escaped the CommandBus acceptance gate")
	if emitted_snapshots.size() != signal_count_before:
		_fail("blocked item command emitted state after acceptance rejection")


func _validate_current_item_semantics() -> void:
	var controller = RunRuntimeControllerScript.new()
	var bus = controller.command_bus
	var equipment: Dictionary = M3ItemCatalogScript.equipment_items()[2].duplicate(true)
	equipment["instance_id"] = "i1_registered_equipment"
	var start_payload := {
		"run_start_config": {
			"selected_equipment_items": [equipment],
			"selected_consumable_items": [],
			"backpack_capacity": 10,
			"failure_salvage_capacity": 2,
		}
	}
	_require_ok(bus.dispatch(&"start_standard_run", start_payload), "semantic start")
	var context = controller.context
	var ledger = context.asset_ledger

	context.last_reward = {"sentinel": "equipment_does_not_replace_last_reward"}
	var unequip: Dictionary = bus.dispatch(&"unequip_item", {"instance_id": "i1_registered_equipment"})
	_require_item_outcome(unequip, &"unequipped", context, "Unequipped item:", "unequip")
	_assert_location(ledger, "i1_registered_equipment", RunAssetLedgerScript.LOCATION_INVENTORY, "unequip")
	if context.last_reward != {"sentinel": "equipment_does_not_replace_last_reward"}:
		_fail("unequip changed last_reward")
	var equip: Dictionary = bus.dispatch(&"equip_item", {"instance_id": "i1_registered_equipment"})
	_require_item_outcome(equip, &"equipped", context, "Equipped item:", "equip")
	_assert_location(ledger, "i1_registered_equipment", RunAssetLedgerScript.LOCATION_EQUIPPED, "equip")
	if context.last_reward != {"sentinel": "equipment_does_not_replace_last_reward"}:
		_fail("equip changed last_reward")

	var pickup_def: Dictionary = M3ItemCatalogScript.collectible_items()[0].duplicate(true)
	pickup_def["instance_id"] = "i1_pickup_drop_item"
	ledger.add_reward_items([pickup_def], RunAssetLedgerScript.LOCATION_ROOM_FLOOR, context.get_current_pos(), "i1_command_module")
	var pickup: Dictionary = bus.dispatch(&"pickup_ground_item", {"instance_id": "i1_pickup_drop_item"})
	_require_item_outcome(pickup, &"picked_up", context, "Picked up floor item:", "pickup")
	_assert_location(ledger, "i1_pickup_drop_item", RunAssetLedgerScript.LOCATION_INVENTORY, "pickup")
	_assert_last_reward(context, pickup, "pickup")
	var drop: Dictionary = bus.dispatch(&"drop_inventory_item", {"instance_id": "i1_pickup_drop_item"})
	_require_item_outcome(drop, &"dropped", context, "Dropped inventory item:", "drop")
	_assert_location(ledger, "i1_pickup_drop_item", RunAssetLedgerScript.LOCATION_ROOM_FLOOR, "drop")
	_assert_last_reward(context, drop, "drop")

	var carried_def: Dictionary = M3ItemCatalogScript.collectible_items()[1].duplicate(true)
	carried_def["instance_id"] = "i1_replace_carried"
	carried_def["reward_location"] = RunAssetLedgerScript.LOCATION_INVENTORY
	var ground_def: Dictionary = M3ItemCatalogScript.collectible_items()[2].duplicate(true)
	ground_def["instance_id"] = "i1_replace_ground"
	ledger.backpack_capacity = 10
	ledger.add_reward_items([carried_def], RunAssetLedgerScript.LOCATION_INVENTORY, context.get_current_pos(), "i1_command_module")
	ledger.add_reward_items([ground_def], RunAssetLedgerScript.LOCATION_ROOM_FLOOR, context.get_current_pos(), "i1_command_module")
	ledger.backpack_capacity = ledger.get_backpack_used()
	var replace: Dictionary = bus.dispatch(&"replace_ground_item", {
		"ground_instance_id": "i1_replace_ground",
		"drop_instance_id": "i1_replace_carried",
	})
	_require_item_outcome(replace, &"replaced", context, "Replaced floor item:", "replace")
	_assert_location(ledger, "i1_replace_ground", RunAssetLedgerScript.LOCATION_INVENTORY, "replace picked")
	_assert_location(ledger, "i1_replace_carried", RunAssetLedgerScript.LOCATION_ROOM_FLOOR, "replace dropped")
	_assert_last_reward(context, replace, "replace")

	ledger.backpack_capacity = 100
	var consumable_def: Dictionary = M3ItemCatalogScript.consumable_items()[0].duplicate(true)
	consumable_def["instance_id"] = "i1_use_consumable"
	consumable_def["reward_location"] = RunAssetLedgerScript.LOCATION_INVENTORY
	ledger.add_reward_items([consumable_def], RunAssetLedgerScript.LOCATION_INVENTORY, context.get_current_pos(), "i1_command_module")
	var use: Dictionary = bus.dispatch(&"use_consumable", {"instance_id": "i1_use_consumable"})
	_require_item_outcome(use, &"use_consumable", context, "", "use")
	var use_action: Dictionary = use.get("action_result", {})
	if context.last_message != String(use_action.get("message", "Consumable used.")):
		_fail("use did not preserve rule-provided last_message")
	_assert_location(ledger, "i1_use_consumable", RunAssetLedgerScript.LOCATION_CONSUMED, "use")
	_assert_last_reward(context, use, "use")

	var blocked: Dictionary = bus.dispatch(&"pickup_ground_item", {"instance_id": "missing_item"})
	if bool(blocked.get("ok", true)) or context.blocked_reason != "item_not_found":
		_fail("blocked pickup did not preserve reason/context policy: %s" % JSON.stringify(blocked))
	if context.last_message != "Pickup blocked: item_not_found.":
		_fail("blocked pickup message changed: %s" % context.last_message)


func _validate_static_boundary() -> void:
	var bus_source := FileAccess.get_file_as_string("res://scripts/core/command/command_bus.gd")
	var handler_source := FileAccess.get_file_as_string("res://scripts/core/command/item_command_handler.gd")
	for forbidden: String in [
		"RunRuleService.pickup_ground_item",
		"RunRuleService.replace_ground_item",
		"RunRuleService.drop_inventory_item",
		"RunRuleService.use_consumable",
		"asset_ledger.equip_inventory_item",
		"asset_ledger.unequip_item",
	]:
		if bus_source.contains(forbidden):
			_fail("CommandBus retained item mutation dependency: %s" % forbidden)
	if not bus_source.contains("CommandResult.from_action") or not bus_source.contains("state_changed.emit"):
		_fail("CommandBus no longer owns normalization/state signal facade")
	if handler_source.contains("CommandResult.from_action") or handler_source.contains("state_changed.emit") or handler_source.contains("signal state_changed"):
		_fail("ItemCommandHandler crossed into CommandBus facade ownership")


func _on_command_requested(command_name: StringName, _command: Dictionary) -> void:
	requested_commands.append(command_name)


func _on_state_changed(snapshot: Dictionary) -> void:
	emitted_snapshots.append(snapshot.duplicate(true))


func _require_item_outcome(result: Dictionary, expected_status: StringName, context: RunContext, message_prefix: String, label: String) -> void:
	_require_ok(result, label)
	var action_result: Dictionary = result.get("action_result", {})
	if StringName(action_result.get("status", &"")) != expected_status:
		_fail("%s action status changed: %s" % [label, JSON.stringify(action_result)])
	if message_prefix != "" and not context.last_message.begins_with(message_prefix):
		_fail("%s last_message changed: %s" % [label, context.last_message])
	if not result.has("action_result"):
		_fail("%s lost action_result facade" % label)
	if not bool(result.get("accepted", false)) or String(result.get("reason", "")) != "":
		_fail("%s CommandResult normalization changed: %s" % [label, JSON.stringify(result)])


func _assert_last_reward(context: RunContext, command_result: Dictionary, label: String) -> void:
	var action_result: Dictionary = command_result.get("action_result", {})
	if context.last_reward != action_result:
		_fail("%s did not copy action result into last_reward" % label)
	if context.blocked_reason != "":
		_fail("%s left blocked_reason after success: %s" % [label, context.blocked_reason])


func _assert_location(ledger, instance_id: String, expected: StringName, label: String) -> void:
	var item: Dictionary = ledger.item_instances.get(instance_id, {})
	if StringName(item.get("location_state", &"")) != expected:
		_fail("%s location changed: expected %s got %s" % [label, expected, item.get("location_state", &"")])


func _require_ok(result: Dictionary, label: String) -> void:
	if not bool(result.get("ok", false)):
		_fail("%s failed: %s" % [label, JSON.stringify(result)])


func _fail(message: String) -> void:
	failures.append(message)
