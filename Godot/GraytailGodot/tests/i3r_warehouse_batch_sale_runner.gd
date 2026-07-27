extends SceneTree

const DeployPrepShellScript := preload("res://scripts/ui/deploy_prep/deploy_prep_shell.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")


class MemorySaveAdapter:
	extends SaveAdapter

	var fail_next_save := false
	var save_calls := 0
	var stored_data: Dictionary = {}

	func load_json_result(
		_path: String = M1_META_PROGRESS_PATH,
		default_data: Dictionary = {},
		_normalize_meta_progress: bool = true
	) -> Dictionary:
		var loaded := default_meta_progress() if default_data.is_empty() else default_data.duplicate(true)
		return {
			"ok": true,
			"status": "memory",
			"data": loaded,
			"read_only_fallback": false,
			"error": "",
		}

	func save_json(
		source_data: Dictionary,
		_path: String = M1_META_PROGRESS_PATH,
		_normalize_meta_progress: bool = true
	) -> bool:
		save_calls += 1
		if fail_next_save:
			fail_next_save = false
			last_error = "forced_save_failure"
			return false
		last_error = ""
		stored_data = source_data.duplicate(true)
		return true


var failures: Array[String] = []
var controllers: Array[RunRuntimeController] = []
var emitted_actions: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_atomic_domain_transaction()
	_test_save_failure_rollback()
	await _test_player_batch_sale_chain()
	_cleanup_controllers()
	if failures.is_empty():
		print("I3R_WAREHOUSE_BATCH_SALE=PASS atomic=all_or_nothing idempotency=request_id rollback=save_failure reasons=configured,unique UI=multi_select,strong_confirm,synchronized")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("I3R_WAREHOUSE_BATCH_SALE=FAIL count=%d" % failures.size())
	quit(1)


func _test_atomic_domain_transaction() -> void:
	var fixture := _adapter_fixture()
	var adapter := fixture.get("adapter") as MetaProgressAdapter
	var memory := fixture.get("save_adapter") as MemorySaveAdapter
	var controller := _controller(adapter)
	var before_failure := adapter.data.duplicate(true)
	var rejected := controller.execute_meta_action(_request(
		"batch-validation-1",
		["sale_b", "attendance", "unique", "sale_a"],
		["attendance"]
	))
	_expect(not bool(rejected.get("ok", true)), "Batch containing blocked and unique items did not fail closed")
	_expect(StringName(rejected.get("status", &"")) == &"batch_validation_failed", "Batch validation failure status was not propagated")
	var rejected_result := _dictionary(rejected.get("result", {}))
	_expect(StringName(rejected_result.get("atomicity", &"")) == &"all_or_nothing", "Rejected batch did not declare all-or-nothing semantics")
	_expect(_failure_reason(rejected_result, "attendance") == &"configured_item_blocked", "Configured item did not expose its blocking reason")
	_expect(_failure_reason(rejected_result, "unique") == &"item_not_sellable", "Unique item did not expose its unsellable reason")
	_expect(adapter.data == before_failure, "Rejected batch mutated balance or warehouse state")
	_expect(memory.save_calls == 0, "Rejected batch reached persistence")

	var success := controller.execute_meta_action(_request(
		"batch-success-1",
		["sale_b", "sale_a", "sale_a"],
		[]
	))
	_expect(bool(success.get("ok", false)), "Valid batch was rejected")
	_expect(StringName(success.get("status", &"")) == &"batch_sold", "Valid batch status was not batch_sold")
	_expect(str(success.get("target_id", "")) == "batch:sale_a,sale_b", "Batch target was not canonical and deterministic")
	var success_result := _dictionary(success.get("result", {}))
	_expect(success_result.get("requested_instance_ids", []) == ["sale_a", "sale_b"], "Batch instance IDs were not sorted and deduplicated")
	_expect(int(success_result.get("sold_count", -1)) == 2, "Batch sold count was not authoritative")
	_expect(int(success_result.get("gold_gained", -1)) == 30, "Batch gold total did not equal the selected item values")
	_expect(int(adapter.data.get("gold", -1)) == 130, "Successful batch did not update the authoritative balance once")
	_expect(_warehouse_ids(adapter.data) == ["attendance", "unique"], "Successful batch removed the wrong warehouse instances")
	_expect(memory.save_calls == 1 and memory.stored_data == adapter.data, "Successful batch was not persisted exactly once")
	var summary := _dictionary(success.get("meta_progress_summary", {}))
	_expect(int(summary.get("gold", -1)) == 130 and int(summary.get("warehouse_items_count", -1)) == 2, "Envelope summary did not match committed balance and warehouse")

	var duplicate := controller.execute_meta_action(_request(
		"batch-success-1",
		["sale_a", "sale_b"],
		[]
	))
	_expect(bool(duplicate.get("ok", false)) and bool(duplicate.get("duplicate", false)), "Same request_id and canonical payload did not return the cached result")
	_expect(memory.save_calls == 1 and int(adapter.data.get("gold", -1)) == 130, "Idempotent replay repeated the sale or save")
	var conflict := controller.execute_meta_action(_request(
		"batch-success-1",
		["attendance"],
		["attendance"]
	))
	_expect(not bool(conflict.get("ok", true)) and StringName(conflict.get("status", &"")) == &"request_id_conflict", "Changed payload reused under one request_id did not fail closed")
	_expect(memory.save_calls == 1 and _warehouse_ids(adapter.data) == ["attendance", "unique"], "request_id conflict mutated committed state")


func _test_save_failure_rollback() -> void:
	var fixture := _adapter_fixture()
	var adapter := fixture.get("adapter") as MetaProgressAdapter
	var memory := fixture.get("save_adapter") as MemorySaveAdapter
	var controller := _controller(adapter)
	var before := adapter.data.duplicate(true)
	memory.fail_next_save = true
	var failed := controller.execute_meta_action(_request(
		"batch-save-failure",
		["sale_a", "sale_b"],
		[]
	))
	var failed_result := _dictionary(failed.get("result", {}))
	_expect(not bool(failed.get("ok", true)) and StringName(failed.get("status", &"")) == &"save_failed", "Forced save failure did not propagate")
	_expect(bool(failed_result.get("rolled_back", false)), "Forced save failure did not report rollback")
	_expect(StringName(failed_result.get("atomicity", &"")) == &"all_or_nothing", "Save failure lost transaction atomicity")
	_expect(adapter.data == before, "Save failure did not restore balance, warehouse, and progression state")
	_expect(memory.save_calls == 1 and memory.stored_data.is_empty(), "Failed save was mistaken for a commit")
	var retry := controller.execute_meta_action(_request(
		"batch-save-retry",
		["sale_b", "sale_a"],
		[]
	))
	_expect(bool(retry.get("ok", false)) and StringName(retry.get("status", &"")) == &"batch_sold", "New request_id could not retry after a rolled-back save")
	_expect(memory.save_calls == 2 and int(adapter.data.get("gold", -1)) == 130, "Successful retry did not commit exactly once")


func _test_player_batch_sale_chain() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var fixture := _adapter_fixture()
	var adapter := fixture.get("adapter") as MetaProgressAdapter
	var controller := _controller(adapter)
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)
	var shell := DeployPrepShellScript.new() as Control
	shell.name = "I3RWarehouseBatchSaleShell"
	shell.size = Vector2(1280, 720)
	canvas.add_child(shell)
	emitted_actions.clear()
	shell.meta_action_requested.connect(func(action: Dictionary) -> void: emitted_actions.append(action.duplicate(true)))
	shell.build()
	shell.apply_snapshot(_snapshot(adapter.get_summary()))
	await _frames(8)
	shell.show_tab(&"warehouse")
	await _frames(4)

	var attendance_card := _find_card(shell, &"m3r_attendance")
	_expect(attendance_card != null, "Attendance fixture is missing from the warehouse UI")
	if attendance_card != null:
		(attendance_card.call("focus_button") as Button).emit_signal("pressed")
		await _frames(2)
		var attendance_action := shell.get("detail_primary_action_button") as Button
		_expect(attendance_action != null and attendance_action.text == "设为出勤" and not attendance_action.disabled, "Attendance item lacks its real configuration action")
		if attendance_action != null and not attendance_action.disabled:
			attendance_action.emit_signal("pressed")
			await _frames(3)
	var selected_before_sale := shell.call("get_selected_instance_ids") as Dictionary
	_expect((selected_before_sale.get("selected_equipment_ids", []) as Array).has("attendance"), "Attendance configuration was not established before batch sale")

	var entry := shell.get("warehouse_batch_entry_button") as Button
	_expect(entry != null and entry.visible and not entry.disabled, "Warehouse lacks an enabled quick multiselect entry")
	if entry != null and not entry.disabled:
		entry.emit_signal("pressed")
		await _frames(3)
	var initial_batch := shell.call("get_warehouse_batch_snapshot") as Dictionary
	_expect(bool(initial_batch.get("active", false)), "Quick multiselect did not enter batch mode")
	_expect(int(initial_batch.get("eligible_count", -1)) == 2, "Batch mode did not distinguish the two sale-eligible items")
	_expect(int((_dictionary(initial_batch.get("reason_counts", {}))).get(&"configured_item_blocked", 0)) == 1, "Configured warehouse item lacks a player-visible blocked category")
	_expect(int((_dictionary(initial_batch.get("reason_counts", {}))).get(&"unique_item", 0)) == 1, "Unique warehouse item lacks a player-visible blocked category")

	attendance_card = _find_card(shell, &"m3r_attendance")
	if attendance_card != null:
		(attendance_card.call("focus_button") as Button).emit_signal("pressed")
		await _frames(2)
	var configured_feedback := str((shell.call("get_warehouse_batch_snapshot") as Dictionary).get("feedback", ""))
	_expect(configured_feedback.contains("出勤"), "Clicking a configured item did not explain why it cannot be sold")
	_expect(int((shell.call("get_warehouse_batch_snapshot") as Dictionary).get("selected_count", -1)) == 0, "Configured item entered the batch selection")
	var unique_card := _find_card(shell, &"m3r_unique")
	if unique_card != null:
		(unique_card.call("focus_button") as Button).emit_signal("pressed")
		await _frames(2)
	_expect(str((shell.call("get_warehouse_batch_snapshot") as Dictionary).get("feedback", "")).contains("唯一"), "Clicking a unique item did not explain why it cannot be sold")

	var select_all := shell.get("warehouse_batch_select_all_button") as Button
	_expect(select_all != null and select_all.visible and not select_all.disabled, "Batch mode lacks an enabled select-all-sellable action")
	if select_all != null and not select_all.disabled:
		select_all.emit_signal("pressed")
		await _frames(2)
	var all_selected := shell.call("get_warehouse_batch_snapshot") as Dictionary
	_expect(all_selected.get("selected_instance_ids", []) == ["sale_a", "sale_b"], "Select all included blocked items or lost exact instance identity")
	_expect(int(all_selected.get("total_value", -1)) == 30, "Select-all preview total is not authoritative")
	var clear := shell.get("warehouse_batch_clear_button") as Button
	_expect(clear != null and clear.visible and not clear.disabled, "Batch mode lacks an enabled clear action after selection")
	if clear != null and not clear.disabled:
		clear.emit_signal("pressed")
		await _frames(2)
	_expect(int((shell.call("get_warehouse_batch_snapshot") as Dictionary).get("selected_count", -1)) == 0, "Clear did not remove all batch selections")

	for card_id in [&"m3r_sale_b", &"m3r_sale_a"]:
		var card := _find_card(shell, card_id)
		_expect(card != null, "Sale-eligible card is missing: %s" % str(card_id))
		if card != null:
			(card.call("focus_button") as Button).emit_signal("pressed")
			await _frames(2)
	var manual_selection := shell.call("get_warehouse_batch_snapshot") as Dictionary
	_expect(manual_selection.get("selected_instance_ids", []) == ["sale_a", "sale_b"], "Per-item toggles did not retain sorted exact instance IDs")
	_expect(int(manual_selection.get("selected_count", -1)) == 2 and int(manual_selection.get("total_value", -1)) == 30, "Per-item count or total preview is wrong")

	var confirm_detail := shell.get("detail_primary_action_button") as Button
	var actions_before_confirm := emitted_actions.size()
	_expect(confirm_detail != null and confirm_detail.text == "确认售卖" and not confirm_detail.disabled, "Batch detail lacks an explicit confirmation action")
	if confirm_detail != null and not confirm_detail.disabled:
		confirm_detail.emit_signal("pressed")
		await _frames(2)
	_expect(emitted_actions.size() == actions_before_confirm, "First batch confirmation click bypassed the strong-confirm modal")
	var batch_modal := shell.get("warehouse_batch_modal_layer") as Control
	_expect(batch_modal != null and batch_modal.visible, "Batch sale did not open the strong-confirm modal")
	var modal_stack = shell.get("modal_focus_stack")
	_expect(modal_stack != null and bool(modal_stack.call("contains", &"warehouse_batch_sell")), "Batch sale modal is outside the shared modal focus lifecycle")
	var modal_cancel := shell.get("warehouse_batch_modal_cancel_button") as Button
	if modal_cancel != null:
		modal_cancel.emit_signal("pressed")
		await _frames(2)
	_expect(batch_modal != null and not batch_modal.visible, "Returning from confirmation did not close the batch modal")
	_expect((shell.call("get_warehouse_batch_snapshot") as Dictionary).get("selected_instance_ids", []) == ["sale_a", "sale_b"], "Returning from confirmation discarded the player's checked items")
	confirm_detail = shell.get("detail_primary_action_button") as Button
	if confirm_detail != null and not confirm_detail.disabled:
		confirm_detail.emit_signal("pressed")
		await _frames(2)
	var modal_confirm := shell.get("warehouse_batch_modal_confirm_button") as Button
	if modal_confirm != null:
		modal_confirm.emit_signal("pressed")
		await _frames(2)
	_expect(emitted_actions.size() == actions_before_confirm + 1, "Strong confirmation did not emit exactly one batch action")
	if emitted_actions.size() != actions_before_confirm + 1:
		canvas.queue_free()
		await _frames(3)
		return
	var action: Dictionary = emitted_actions.back()
	_expect(StringName(action.get("action", &"")) == &"sell_collectibles_batch", "Batch UI emitted the wrong domain action")
	_expect(action.get("instance_ids", []) == ["sale_a", "sale_b"], "Batch UI action lost exact sorted instance IDs")
	_expect((action.get("selected_equipment_ids", []) as Array).has("attendance"), "Batch UI did not attach the live attendance configuration")
	_expect(not str(action.get("request_id", "")).is_empty() and StringName(action.get("source_page", &"")) == &"deploy_prep", "Batch action lacks MetaActionEnvelope correlation")
	_expect(bool((shell.call("get_warehouse_batch_snapshot") as Dictionary).get("pending", false)), "Batch action did not enter pending state before domain execution")

	var envelope := controller.execute_meta_action(action)
	_expect(bool(envelope.get("ok", false)) and StringName(envelope.get("status", &"")) == &"batch_sold", "Real UI action was not accepted by the runtime controller and adapter")
	shell.apply_snapshot(_snapshot(_dictionary(envelope.get("meta_progress_summary", {}))))
	await _frames(3)
	var selected_after_snapshot := shell.call("get_selected_instance_ids") as Dictionary
	_expect((selected_after_snapshot.get("selected_equipment_ids", []) as Array) == ["attendance"], "Authoritative warehouse refresh desynchronized the attendance configuration")
	_expect(_find_card(shell, &"m3r_sale_a") == null and _find_card(shell, &"m3r_sale_b") == null, "Committed sold items remained visible after the authoritative snapshot")
	_expect(str((shell.get("detail_gold_label") as Label).text).contains("130"), "Committed balance did not refresh in the warehouse UI")
	_expect(bool(shell.call("apply_meta_action_result", envelope)), "Batch result envelope was not correlated back to the Deploy page")
	await _frames(2)
	var completed_batch := shell.call("get_warehouse_batch_snapshot") as Dictionary
	_expect(not bool(completed_batch.get("active", true)) and not bool(completed_batch.get("pending", true)), "Successful result did not leave batch and pending modes")
	_expect(int(adapter.data.get("gold", -1)) == 130 and _warehouse_ids(adapter.data) == ["attendance", "unique"], "Player chain did not commit the same authoritative balance and warehouse as the domain transaction")
	canvas.queue_free()
	await _frames(4)


func _adapter_fixture() -> Dictionary:
	var memory := MemorySaveAdapter.new()
	var adapter := MetaProgressAdapterScript.new()
	adapter.save_adapter = memory
	adapter.write_blocked = false
	adapter.write_block_reason = ""
	adapter.last_error = ""
	adapter.data = memory.default_meta_progress()
	adapter.data["gold"] = 100
	adapter.data["warehouse_items"] = [
		_item("col_01", "sale_a", {"display_name": "旧铜线", "base_value": 11}),
		_item("col_02", "sale_b", {"display_name": "标准挂签", "base_value": 19}),
		_item("eq_goggles", "attendance", {"display_name": "出勤护目镜"}),
		_item("col_03", "unique", {
			"display_name": "唯一纪念章",
			"base_value": 99,
			"can_sell": false,
			"is_unique": true,
			"rarity": &"unique",
		}),
	]
	return {"adapter": adapter, "save_adapter": memory}


func _item(item_id: String, instance_id: String, overrides: Dictionary = {}) -> Dictionary:
	var item := M7ContentCatalogScript.item_definition(item_id)
	item["item_id"] = item_id
	item["instance_id"] = instance_id
	for key in overrides.keys():
		item[key] = overrides[key]
	return item


func _snapshot(summary: Dictionary) -> Dictionary:
	return {
		"run_active": false,
		"meta_progress_summary": summary.duplicate(true),
	}


func _request(
	request_id: String,
	instance_ids: Array,
	selected_equipment_ids: Array
) -> Dictionary:
	return {
		"request_id": request_id,
		"source_page": &"deploy_prep",
		"action": &"sell_collectibles_batch",
		"instance_ids": instance_ids.duplicate(),
		"selected_equipment_ids": selected_equipment_ids.duplicate(),
		"selected_consumable_ids": [],
	}


func _controller(adapter: MetaProgressAdapter) -> RunRuntimeController:
	var controller: RunRuntimeController = RunRuntimeControllerScript.new()
	controller.bind_meta_progress_adapter(adapter)
	controllers.append(controller)
	return controller


func _cleanup_controllers() -> void:
	for controller in controllers:
		controller.bind_meta_progress_adapter(null)
		controller.in_run_runtime.bind(null)
		controller.command_bus.bind_runtime_controller(null)
		var terminal_callback := Callable(controller, "_on_terminal_result_available")
		if controller.command_bus.result_available.is_connected(terminal_callback):
			controller.command_bus.result_available.disconnect(terminal_callback)
	controllers.clear()


func _failure_reason(result: Dictionary, instance_id: String) -> StringName:
	for raw_failure in result.get("item_failures", []) as Array:
		var failure := _dictionary(raw_failure)
		if str(failure.get("instance_id", "")) == instance_id:
			return StringName(failure.get("reason_code", &""))
	return &""


func _warehouse_ids(source: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for raw_item in source.get("warehouse_items", []) as Array:
		result.append(str(_dictionary(raw_item).get("instance_id", "")))
	result.sort()
	return result


func _find_card(shell: Control, card_id: StringName) -> Control:
	for raw_view in shell.get("card_views") as Array:
		var view := raw_view as Control
		if view != null and StringName(view.get("card_id")) == card_id:
			return view
	return null


func _dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
