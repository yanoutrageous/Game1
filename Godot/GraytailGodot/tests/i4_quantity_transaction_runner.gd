extends SceneTree

const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const SaveAdapterScript := preload("res://scripts/core/save/save_adapter.gd")


class MemorySaveAdapter:
	extends SaveAdapter

	var fail_next_save := false
	var save_calls := 0
	var stored_data: Dictionary = {}

	func save_json(
		source_data: Dictionary,
		_path: String = M1_META_PROGRESS_PATH,
		_normalize_meta_progress: bool = true
	) -> bool:
		save_calls += 1
		if fail_next_save:
			fail_next_save = false
			last_error = "i4_forced_save_failure"
			return false
		last_error = ""
		stored_data = source_data.duplicate(true)
		return true


var failures: Array[String] = []
var controllers: Array[RunRuntimeController] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_atomic_multi_purchase()
	_test_purchase_failure_rollback()
	_cleanup()
	if failures.is_empty():
		print("I4_QUANTITY_TRANSACTION=PASS purchase=N_instances save=once rollback=exact idempotency=PASS")
		quit(0)
		return
	for failure in failures:
		printerr("I4_QUANTITY_TRANSACTION=FAIL:%s" % failure)
	quit(1)


func _test_atomic_multi_purchase() -> void:
	var fixture := _fixture(100)
	var adapter := fixture.adapter as MetaProgressAdapter
	var memory := fixture.memory as MemorySaveAdapter
	var controller := _controller(adapter)
	var request := _purchase_request("i4-purchase-three", "con_ration", 3)
	var envelope := controller.execute_meta_action(request)
	var result: Dictionary = envelope.get("result", {})
	_expect(bool(envelope.get("ok", false)), "valid quantity purchase was rejected")
	_expect(StringName(envelope.get("status", &"")) == &"batch_purchased", "quantity purchase status drifted")
	_expect(int(result.get("created_count", 0)) == 3, "quantity purchase did not create N instances")
	_expect((result.get("instance_ids", []) as Array).size() == 3, "quantity purchase omitted exact IDs")
	_expect(_unique_count(result.get("instance_ids", [])) == 3, "quantity purchase generated duplicate IDs")
	_expect(int(adapter.data.get("gold", -1)) == 64, "quantity purchase charged the wrong total")
	_expect((adapter.data.get("warehouse_items", []) as Array).size() == 3, "quantity purchase warehouse count is wrong")
	_expect(memory.save_calls == 1 and memory.stored_data == adapter.data, "quantity purchase did not save exactly once")
	var replay := controller.execute_meta_action(request)
	_expect(bool(replay.get("duplicate", false)), "same request did not return idempotent receipt")
	_expect(memory.save_calls == 1 and int(adapter.data.get("gold", -1)) == 64, "idempotent replay charged or saved again")
	var conflict := controller.execute_meta_action(_purchase_request("i4-purchase-three", "con_ration", 2))
	_expect(StringName(conflict.get("status", &"")) == &"request_id_conflict", "quantity change under same request ID was not rejected")
	_expect(memory.save_calls == 1 and (adapter.data.get("warehouse_items", []) as Array).size() == 3, "request conflict mutated state")


func _test_purchase_failure_rollback() -> void:
	var fixture := _fixture(100)
	var adapter := fixture.adapter as MetaProgressAdapter
	var memory := fixture.memory as MemorySaveAdapter
	var controller := _controller(adapter)
	var before := adapter.data.duplicate(true)
	memory.fail_next_save = true
	var failed := controller.execute_meta_action(_purchase_request("i4-purchase-fail", "con_ration", 4))
	var result: Dictionary = failed.get("result", {})
	_expect(not bool(failed.get("ok", true)), "forced persistence failure was reported as success")
	_expect(StringName(failed.get("status", &"")) == &"save_failed", "forced persistence failure status drifted")
	_expect(bool(result.get("rolled_back", false)), "forced persistence failure omitted rollback evidence")
	_expect(adapter.data == before, "forced persistence failure left partial gold or instances")
	_expect(memory.save_calls == 1 and memory.stored_data.is_empty(), "failed persistence was mistaken for a commit")
	var invalid := controller.execute_meta_action(_purchase_request("i4-purchase-invalid", "con_ration", 0))
	_expect(StringName(invalid.get("status", &"")) == &"invalid_quantity", "zero quantity was not rejected before mutation")
	_expect(memory.save_calls == 1 and adapter.data == before, "invalid quantity reached persistence or mutated data")


func _fixture(gold: int) -> Dictionary:
	var memory := MemorySaveAdapter.new()
	var adapter := MetaProgressAdapterScript.new()
	adapter.save_adapter = memory
	adapter.data = memory.default_meta_progress()
	adapter.data["gold"] = gold
	adapter.data["warehouse_items"] = []
	adapter.data["purchased_instance_ids"] = []
	return {"adapter": adapter, "memory": memory}


func _purchase_request(request_id: String, item_id: String, quantity: int) -> Dictionary:
	return {
		"request_id": request_id,
		"source_page": &"deploy_prep",
		"action": &"purchase",
		"item_id": item_id,
		"quantity": quantity,
	}


func _controller(adapter: MetaProgressAdapter) -> RunRuntimeController:
	var controller: RunRuntimeController = RunRuntimeControllerScript.new()
	controller.bind_meta_progress_adapter(adapter)
	controllers.append(controller)
	return controller


func _unique_count(value: Variant) -> int:
	var seen := {}
	for raw_id in value as Array:
		seen[str(raw_id)] = true
	return seen.size()


func _cleanup() -> void:
	for controller in controllers:
		controller.bind_meta_progress_adapter(null)
		controller.in_run_runtime.bind(null)
		controller.command_bus.bind_runtime_controller(null)
		var callback := Callable(controller, "_on_terminal_result_available")
		if controller.command_bus.result_available.is_connected(callback):
			controller.command_bus.result_available.disconnect(callback)
	controllers.clear()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
