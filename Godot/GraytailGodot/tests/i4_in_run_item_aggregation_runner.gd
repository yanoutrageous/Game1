extends SceneTree

const RunAssetLedgerScript := preload("res://scripts/core/run/run_asset_ledger.gd")
const RunUIViewModelScript := preload("res://scripts/ui/shell/run_ui_view_model.gd")
const RunSurfaceModelScript := preload("res://scripts/ui/run_surface/run_surface_model.gd")
const InventoryPanelScript := preload("res://scripts/ui/inventory/inventory_panel.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")

const PASS_MARKER := "I4_IN_RUN_ITEM_AGGREGATION=PASS"
const FAIL_MARKER := "I4_IN_RUN_ITEM_AGGREGATION=FAIL"

var failures: Array[String] = []
var emitted_use_instance_id := ""
var emitted_drop_instance_id := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var compatible_items := [
		_item("ration_c", 20),
		_item("ration_a", 20),
		_item("ration_b", 20),
	]
	var variant_item := _item("ration_variant", 35)
	var raw_items: Array = compatible_items.duplicate(true)
	raw_items.append(variant_item)
	var stacks := RunUIViewModelScript.aggregate_item_projection(raw_items)
	_expect(stacks.size() == 2, "semantically incompatible items were merged")
	var compatible_stack := _stack_with_quantity(stacks, 3)
	_expect(not compatible_stack.is_empty(), "compatible duplicate items did not aggregate")
	_expect(
		(compatible_stack.get("instance_ids", []) as Array) == ["ration_a", "ration_b", "ration_c"],
		"aggregated stack lost deterministic exact instance IDs"
	)
	_expect(String(compatible_stack.get("instance_id", "")) == "ration_a", "representative instance is not deterministic")
	_expect(int(compatible_stack.get("total_weight", 0)) == 3, "aggregate total weight is incorrect")

	var snapshot := _snapshot(raw_items)
	var surface_model := RunSurfaceModelScript.build(snapshot, null, _profile(), {})
	var backpack_stacks := surface_model.get("backpack_items", []) as Array
	_expect(backpack_stacks.size() == 2, "HUD projection did not reuse display-only aggregation")
	_expect((backpack_stacks[0] as Dictionary).has("instance_ids"), "HUD projection dropped exact instance identity")

	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var inventory := InventoryPanelScript.new()
	host.add_child(inventory)
	inventory.use_item_requested.connect(_on_use_requested)
	inventory.drop_item_requested.connect(_on_drop_requested)
	inventory.apply_layout_profile(_profile())
	inventory.apply_snapshot(snapshot)
	inventory.show_panel()
	await _wait_until(
		func() -> bool:
			var list := inventory.get("item_list") as VBoxContainer
			return (
				list != null
				and list.get_child_count() == 2
				and inventory.find_child("InventoryUseButton", true, false) is Button
			),
		"initial aggregate rows and use action"
	)
	var item_list := inventory.get("item_list") as VBoxContainer
	_expect(item_list != null and item_list.get_child_count() == 2, "inventory rendered one row per instance instead of one row per compatible stack")
	var use_button := inventory.find_child("InventoryUseButton", true, false) as Button
	_expect(use_button != null, "inventory stack use action is missing")
	if use_button != null:
		_expect(String(use_button.get_meta("item_instance_id", "")) == "ration_a", "use action did not target the deterministic representative")
		_expect(
			(use_button.get_meta("item_instance_ids", []) as Array) == ["ration_a", "ration_b", "ration_c"],
			"use action metadata lost exact stack membership"
		)
		use_button.grab_focus()
		use_button.pressed.emit()
	_expect(emitted_use_instance_id == "ration_a", "one use action did not emit exactly one exact instance")

	var after_use_items := [
		_item("ration_c", 20),
		_item("ration_b", 20),
		variant_item,
	]
	inventory.apply_snapshot(_snapshot(after_use_items))
	await _wait_until(
		func() -> bool:
			var focus := inventory.get_viewport().gui_get_focus_owner()
			return (
				focus != null
				and String(focus.get_meta("item_instance_id", "")) == "ration_b"
				and StringName(focus.get_meta("item_action", &"")) == &"use"
			),
		"focus restoration after one exact use"
	)
	var focus_after_use := inventory.get_viewport().gui_get_focus_owner()
	_expect(focus_after_use != null and String(focus_after_use.get_meta("item_instance_id", "")) == "ration_b", "stack focus was lost after consuming its representative")
	_expect(focus_after_use == null or StringName(focus_after_use.get_meta("item_action", &"")) == &"use", "stack action focus changed after consuming one item")

	var ledger := RunAssetLedgerScript.new()
	ledger.setup({
		"backpack_capacity": 20,
		"selected_consumable_items": raw_items,
	})
	var use_result := ledger.consume_inventory_item(emitted_use_instance_id)
	_expect(bool(use_result.get("ok", false)), "ledger rejected the exact representative use")
	_expect(ledger.get_items_by_location(RunAssetLedgerScript.LOCATION_CONSUMED).size() == 1, "one use changed more than one ledger instance")
	_expect(_ids(ledger.get_items_by_location(RunAssetLedgerScript.LOCATION_INVENTORY)) == ["ration_b", "ration_c", "ration_variant"], "one use changed the wrong ledger instances")

	inventory.apply_snapshot(_snapshot(ledger.get_items_by_location(RunAssetLedgerScript.LOCATION_INVENTORY)))
	await _wait_until(
		func() -> bool:
			var candidate := inventory.find_child("InventoryDropButton", true, false) as Button
			return (
				candidate != null
				and String(candidate.get_meta("item_instance_id", "")) == "ration_b"
			),
		"drop action after exact-ledger refresh"
	)
	var drop_button := inventory.find_child("InventoryDropButton", true, false) as Button
	_expect(drop_button != null, "inventory stack drop action is missing")
	if drop_button != null:
		drop_button.pressed.emit()
	_expect(emitted_drop_instance_id == "ration_b", "one drop action did not advance to the next exact instance")
	var drop_result := ledger.drop_inventory_item(emitted_drop_instance_id, Vector2i(2, 3))
	_expect(bool(drop_result.get("ok", false)), "ledger rejected the exact representative drop")
	_expect(_ids(ledger.get_items_by_location(RunAssetLedgerScript.LOCATION_ROOM_FLOOR)) == ["ration_b"], "one drop changed more than one ledger instance")
	_expect(_ids(ledger.get_items_by_location(RunAssetLedgerScript.LOCATION_INVENTORY)) == ["ration_c", "ration_variant"], "one drop changed the wrong ledger instances")

	ledger.create_item_instance(_collectible("core_a"), RunAssetLedgerScript.LOCATION_INVENTORY)
	ledger.create_item_instance(_collectible("core_b"), RunAssetLedgerScript.LOCATION_INVENTORY)
	var collectible_stacks := RunUIViewModelScript.aggregate_item_projection(
		ledger.get_items_by_location(RunAssetLedgerScript.LOCATION_INVENTORY)
	)
	_expect(not _stack_with_ids(collectible_stacks, ["core_a", "core_b"]).is_empty(), "settlement candidates did not retain both exact IDs behind one display stack")
	var settlement := ledger.settle_success()
	_expect(bool(settlement.get("ok", false)), "success settlement failed after aggregated display actions")
	var warehouse_ids := _ids(settlement.get("warehouse_items", []))
	_expect(warehouse_ids.has("core_a") and warehouse_ids.has("core_b"), "settlement collapsed or lost exact item instances")

	host.queue_free()
	await host.tree_exited
	_finish()


func _item(instance_id: String, effect_amount: int) -> Dictionary:
	return {
		"instance_id": instance_id,
		"item_id": "con_ration",
		"display_name": "压缩饼",
		"short_description": "恢复少量生命。",
		"item_type": &"consumable",
		"main_type": &"consumable",
		"rarity": &"tier_1",
		"weight": 1,
		"base_value": 12,
		"can_sell": true,
		"can_store": true,
		"can_equip": false,
		"can_consume": true,
		"effect_kind": "heal",
		"effect_amount": effect_amount,
		"equipment_slot": "",
		"is_unique": false,
	}


func _collectible(instance_id: String) -> Dictionary:
	return {
		"instance_id": instance_id,
		"item_id": "col_core",
		"display_name": "异常核心碎片",
		"item_type": &"collectible",
		"main_type": &"collectible",
		"rarity": &"tier_4",
		"weight": 1,
		"base_value": 24,
		"can_sell": true,
		"can_store": true,
		"can_equip": false,
		"can_consume": false,
		"is_unique": false,
		"acquired_in_run": true,
	}


func _snapshot(items: Array) -> Dictionary:
	return {
		"run_active": true,
		"inventory_items": items.duplicate(true),
		"equipped_items": [],
		"backpack_used": items.size(),
		"backpack_capacity": 20,
		"run_black_coin": 0,
		"gold_coin": 0,
		"position": Vector2i.ZERO,
		"current_room": &"Spawn",
		"adjacent_mines": 0,
		"protocol_level": 5,
		"pressure": 0,
	}


func _profile() -> Dictionary:
	var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(&"1280x720")
	profile["actual_viewport_size"] = Vector2i(1280, 720)
	return profile


func _stack_with_quantity(stacks: Array, quantity: int) -> Dictionary:
	for raw_stack in stacks:
		var stack := raw_stack as Dictionary
		if int(stack.get("quantity", 0)) == quantity:
			return stack.duplicate(true)
	return {}


func _stack_with_ids(stacks: Array, expected_ids: Array) -> Dictionary:
	for raw_stack in stacks:
		var stack := raw_stack as Dictionary
		if (stack.get("instance_ids", []) as Array) == expected_ids:
			return stack.duplicate(true)
	return {}


func _ids(items_variant: Variant) -> Array[String]:
	var result: Array[String] = []
	if items_variant is Array:
		for raw_item in items_variant:
			if raw_item is Dictionary:
				result.append(String((raw_item as Dictionary).get("instance_id", "")))
	result.sort()
	return result


func _on_use_requested(instance_id: String) -> void:
	emitted_use_instance_id = instance_id


func _on_drop_requested(instance_id: String) -> void:
	emitted_drop_instance_id = instance_id


func _wait_until(predicate: Callable, label: String, timeout_ms: int = 5000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while Time.get_ticks_msec() <= deadline:
		if bool(predicate.call()):
			return true
		await process_frame
	failures.append("timed out waiting for semantic state: %s" % label)
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("%s display=aggregate ledger=exact action=one_instance settlement=preserved" % PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("%s count=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
