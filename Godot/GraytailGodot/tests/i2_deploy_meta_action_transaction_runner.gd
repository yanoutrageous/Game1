extends SceneTree

const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")


class FakeMetaProgressAdapter:
	extends RefCounted

	var calls: Array[Dictionary] = []
	var failure_statuses: Dictionary = {}
	var gold: int = 500
	var revision: int = 0
	var summary_reads: int = 0

	func purchase_item(item_id: String, _source: String = "m7_base_shop") -> Dictionary:
		_record(&"purchase", item_id, [])
		return _resolve(&"purchase", item_id, -10)

	func sell_collectible(instance_id: String, blocked_instance_ids: Array = []) -> Dictionary:
		_record(&"sell_collectible", instance_id, blocked_instance_ids)
		return _resolve(&"sell_collectible", instance_id, 7)

	func complete_research(research_id: String, blocked_instance_ids: Array = []) -> Dictionary:
		_record(&"complete_research", research_id, blocked_instance_ids)
		return _resolve(&"complete_research", research_id, -25)

	func claim_goal_reward(goal_kind: String, goal_id: String) -> Dictionary:
		var target_id := "%s:%s" % [goal_kind, goal_id]
		_record(&"claim_goal", target_id, [])
		return _resolve(&"claim_goal", target_id, 30)

	func mark_long_term_viewed(view_kind: String) -> Dictionary:
		_record(&"mark_viewed", view_kind, [])
		return _resolve(&"mark_viewed", view_kind, 0)

	func get_summary() -> Dictionary:
		summary_reads += 1
		return _summary()

	func set_failure(action_id: StringName, target_id: String, status: StringName) -> void:
		failure_statuses[_failure_key(action_id, target_id)] = status

	func _record(action_id: StringName, target_id: String, blocked_instance_ids: Array) -> void:
		calls.append({
			"action": action_id,
			"target_id": target_id,
			"blocked_instance_ids": blocked_instance_ids.duplicate(true),
		})

	func _resolve(action_id: StringName, target_id: String, gold_delta: int) -> Dictionary:
		var failure_key := _failure_key(action_id, target_id)
		if failure_statuses.has(failure_key):
			return {
				"ok": false,
				"status": failure_statuses.get(failure_key, &"failed"),
				"target_id": target_id,
			}
		revision += 1
		gold += gold_delta
		return {
			"ok": true,
			"status": _success_status(action_id),
			"target_id": target_id,
			"summary": _summary(),
		}

	func _summary() -> Dictionary:
		return {"gold": gold, "revision": revision}

	func _failure_key(action_id: StringName, target_id: String) -> String:
		return "%s|%s" % [str(action_id), target_id]

	func _success_status(action_id: StringName) -> StringName:
		match action_id:
			&"purchase": return &"purchased"
			&"sell_collectible": return &"sold"
			&"complete_research": return &"completed"
			&"claim_goal": return &"claimed"
			&"mark_viewed": return &"viewed"
			_: return &"completed"


var failures: Array[String] = []
var controllers: Array[RunRuntimeController] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_purchase_idempotency_and_conflict()
	_test_all_action_payloads()
	_test_failure_propagation()
	_test_fail_closed_validation()
	_test_adapter_rebind_cache_scope()
	_test_session_cache_retention()
	_cleanup_controllers()
	if failures.is_empty():
		print("I2_DEPLOY_META_ACTION_TRANSACTION=PASS actions=5 duplicate=cached conflict=fail_closed cache=session authority=adapter")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("I2_DEPLOY_META_ACTION_TRANSACTION=FAIL count=%d" % failures.size())
	quit(1)


func _test_purchase_idempotency_and_conflict() -> void:
	var adapter := FakeMetaProgressAdapter.new()
	var controller = _controller()
	controller.bind_meta_progress_adapter(adapter)
	var first := controller.execute_meta_action(_request(
		"purchase-1",
		"deploy",
		&"purchase",
		{"item_id": "con_ration", "card_id": "presentation-only"}
	))
	_expect(bool(first.get("ok", false)), "purchase success was not propagated")
	_expect(StringName(first.get("status", &"")) == &"purchased", "purchase status was not propagated")
	_expect(str(first.get("target_id", "")) == "con_ration", "purchase target was not exact")
	_expect(_has_envelope_fields(first), "purchase envelope is incomplete")
	_expect(adapter.calls.size() == 1 and adapter.revision == 1 and adapter.gold == 490, "purchase did not use adapter authority exactly once")
	(first.get("result", {}) as Dictionary)["status"] = &"caller_mutated"
	var duplicate := controller.execute_meta_action(_request(
		"purchase-1",
		"deploy",
		&"purchase",
		{"item_id": "con_ration", "different_presentation_noise": true}
	))
	_expect(bool(duplicate.get("ok", false)) and bool(duplicate.get("duplicate", false)), "same request did not return a cached duplicate")
	_expect(StringName((duplicate.get("result", {}) as Dictionary).get("status", &"")) == &"purchased", "cached envelope was mutable through the caller")
	_expect(adapter.calls.size() == 1 and adapter.revision == 1 and adapter.gold == 490, "cached duplicate called or mutated the adapter")
	var conflict := controller.execute_meta_action(_request(
		"purchase-1",
		"deploy",
		&"purchase",
		{"item_id": "con_stabilizer"}
	))
	_expect(not bool(conflict.get("ok", true)) and StringName(conflict.get("status", &"")) == &"request_id_conflict", "changed payload did not fail closed on request-id conflict")
	_expect(not bool(conflict.get("duplicate", true)), "request-id conflict was incorrectly labelled duplicate")
	_expect(adapter.calls.size() == 1 and adapter.revision == 1 and adapter.gold == 490, "request-id conflict called or mutated the adapter")
	var second_request := controller.execute_meta_action(_request(
		"purchase-2",
		"deploy",
		&"purchase",
		{"item_id": "con_stabilizer"}
	))
	_expect(bool(second_request.get("ok", false)) and adapter.calls.size() == 2, "different request id did not execute independently")
	_expect(adapter.revision == 2 and adapter.gold == 480, "different request id bypassed adapter-owned state")


func _test_all_action_payloads() -> void:
	var adapter := FakeMetaProgressAdapter.new()
	var controller = _controller()
	controller.bind_meta_progress_adapter(adapter)
	var sell := controller.execute_meta_action(_request(
		"sell-1",
		"deploy",
		&"sell_collectible",
		{
			"instance_id": "warehouse:old-gear:7",
			"blocked_instance_ids": ["zulu", "alpha", "alpha", 42],
			"selected_equipment_ids": ["bravo", "zulu"],
			"selected_consumable_ids": ["charlie", ""],
		}
	))
	_expect(bool(sell.get("ok", false)) and str(sell.get("target_id", "")) == "warehouse:old-gear:7", "sell target/result was not propagated")
	var sell_call: Dictionary = adapter.calls.back()
	_expect(sell_call.get("blocked_instance_ids", []) == ["alpha", "bravo", "charlie", "zulu"], "sell blocked IDs were not sorted and deduplicated")
	var sell_duplicate := controller.execute_meta_action(_request(
		"sell-1",
		"deploy",
		&"sell_collectible",
		{
			"instance_id": "warehouse:old-gear:7",
			"blocked_instance_ids": ["charlie", "alpha"],
			"selected_equipment_ids": ["zulu", "bravo", "alpha"],
		}
	))
	_expect(bool(sell_duplicate.get("duplicate", false)) and adapter.calls.size() == 1, "equivalent reordered blocked IDs were not normalized to one transaction")
	var research := controller.execute_meta_action(_request(
		"research-1",
		"long_term",
		&"complete_research",
		{
			"research_id": "research_anomaly_structure",
			"selected_equipment_ids": ["material-b", "material-a", "material-b"],
		}
	))
	_expect(bool(research.get("ok", false)) and str(research.get("target_id", "")) == "research_anomaly_structure", "research target/result was not propagated")
	var research_call: Dictionary = adapter.calls.back()
	_expect(research_call.get("blocked_instance_ids", []) == ["material-a", "material-b"], "research blocked IDs were not normalized")
	var claim := controller.execute_meta_action(_request(
		"claim-1",
		"long_term",
		&"claim_goal",
		{"goal_kind": "achievement", "goal_id": "achievement_safe_return"}
	))
	_expect(bool(claim.get("ok", false)) and str(claim.get("target_id", "")) == "achievement:achievement_safe_return", "claim did not retain exact goal kind/id")
	var claim_call: Dictionary = adapter.calls.back()
	_expect(str(claim_call.get("target_id", "")) == "achievement:achievement_safe_return", "claim adapter target was not exact")
	var viewed := controller.execute_meta_action(_request(
		"view-1",
		"long_term",
		&"mark_viewed",
		{"view_kind": "codex"}
	))
	_expect(bool(viewed.get("ok", false)) and str(viewed.get("target_id", "")) == "codex", "mark-viewed target/result was not propagated")
	_expect(adapter.calls.size() == 4 and adapter.revision == 4, "supported actions did not execute exactly once each")


func _test_failure_propagation() -> void:
	var adapter := FakeMetaProgressAdapter.new()
	adapter.set_failure(&"purchase", "too_expensive", &"insufficient_gold")
	adapter.set_failure(&"sell_collectible", "configured", &"configured_item_blocked")
	adapter.set_failure(&"complete_research", "locked_research", &"prerequisite_missing")
	adapter.set_failure(&"claim_goal", "task:not_ready", &"not_claimable")
	adapter.set_failure(&"mark_viewed", "unsupported", &"unknown_view_kind")
	var controller = _controller()
	controller.bind_meta_progress_adapter(adapter)
	var cases: Array[Dictionary] = [
		{"request_id": "failure-purchase", "action": &"purchase", "payload": {"item_id": "too_expensive"}, "status": &"insufficient_gold"},
		{"request_id": "failure-sell", "action": &"sell_collectible", "payload": {"instance_id": "configured"}, "status": &"configured_item_blocked"},
		{"request_id": "failure-research", "action": &"complete_research", "payload": {"research_id": "locked_research"}, "status": &"prerequisite_missing"},
		{"request_id": "failure-claim", "action": &"claim_goal", "payload": {"goal_kind": "task", "goal_id": "not_ready"}, "status": &"not_claimable"},
		{"request_id": "failure-view", "action": &"mark_viewed", "payload": {"view_kind": "unsupported"}, "status": &"unknown_view_kind"},
	]
	for case_data in cases:
		var result := controller.execute_meta_action(_request(
			str(case_data.get("request_id", "")),
			"failure_probe",
			StringName(case_data.get("action", &"")),
			case_data.get("payload", {})
		))
		var expected_status := StringName(case_data.get("status", &""))
		_expect(not bool(result.get("ok", true)) and StringName(result.get("status", &"")) == expected_status, "adapter failure status %s was not propagated" % str(expected_status))
		_expect(StringName((result.get("result", {}) as Dictionary).get("status", &"")) == expected_status, "nested adapter result lost status %s" % str(expected_status))
	_expect(adapter.calls.size() == cases.size() and adapter.revision == 0 and adapter.gold == 500, "failed actions changed adapter-owned economic state")


func _test_fail_closed_validation() -> void:
	var adapter := FakeMetaProgressAdapter.new()
	var controller = _controller()
	controller.bind_meta_progress_adapter(adapter)
	_expect_status(controller.execute_meta_action({}), &"missing_request_id", "empty request")
	_expect_status(controller.execute_meta_action({"request_id": "missing-page"}), &"missing_source_page", "missing source page")
	_expect_status(controller.execute_meta_action({"request_id": "missing-action", "source_page": "deploy"}), &"missing_action", "missing action")
	_expect_status(controller.execute_meta_action({"request_id": "unknown", "source_page": "deploy", "action": &"delete_everything", "item_id": "x"}), &"unknown_meta_action", "unknown action")
	_expect_status(controller.execute_meta_action({"request_id": "missing-target", "source_page": "deploy", "action": &"purchase"}), &"missing_target_id", "missing target")
	_expect_status(controller.execute_meta_action({"request_id": "typed-target", "source_page": "deploy", "action": &"purchase", "item_id": 17}), &"missing_target_id", "non-string target")
	_expect_status(controller.execute_meta_action({"request_id": "partial-claim", "source_page": "long_term", "action": &"claim_goal", "goal_id": "goal"}), &"missing_target_id", "partial claim target")
	_expect(adapter.calls.is_empty() and adapter.revision == 0, "invalid request reached adapter authority")
	var unbound = _controller()
	_expect_status(unbound.execute_meta_action(_request("unbound", "deploy", &"purchase", {"item_id": "con_ration"})), &"meta_progress_adapter_missing", "missing adapter")


func _test_adapter_rebind_cache_scope() -> void:
	var controller = _controller()
	var first_adapter := FakeMetaProgressAdapter.new()
	controller.bind_meta_progress_adapter(first_adapter)
	var request := _request("adapter-scope", "long_term", &"mark_viewed", {"view_kind": "history"})
	controller.execute_meta_action(request)
	controller.bind_meta_progress_adapter(first_adapter)
	var same_adapter := controller.execute_meta_action(request)
	_expect(bool(same_adapter.get("duplicate", false)) and first_adapter.calls.size() == 1, "rebinding the same adapter unnecessarily cleared transaction cache")
	var second_adapter := FakeMetaProgressAdapter.new()
	controller.bind_meta_progress_adapter(second_adapter)
	var different_adapter := controller.execute_meta_action(request)
	_expect(not bool(different_adapter.get("duplicate", true)) and second_adapter.calls.size() == 1, "binding a different adapter retained stale transaction cache")


func _test_session_cache_retention() -> void:
	var adapter := FakeMetaProgressAdapter.new()
	var controller = _controller()
	controller.bind_meta_progress_adapter(adapter)
	for index in range(65):
		controller.execute_meta_action(_request(
			"cache-%02d" % index,
			"long_term",
			&"mark_viewed",
			{"view_kind": "view-%02d" % index}
		))
	_expect(adapter.calls.size() == 65, "cache population did not execute 65 distinct requests")
	var newest_duplicate := controller.execute_meta_action(_request("cache-64", "long_term", &"mark_viewed", {"view_kind": "view-64"}))
	_expect(bool(newest_duplicate.get("duplicate", false)) and adapter.calls.size() == 65, "newest request was not retained for the controller session")
	var oldest_duplicate := controller.execute_meta_action(_request("cache-00", "long_term", &"mark_viewed", {"view_kind": "view-00"}))
	_expect(bool(oldest_duplicate.get("duplicate", false)) and adapter.calls.size() == 65, "oldest request could execute again within the controller session")


func _request(request_id: String, source_page: String, action_id: StringName, payload: Dictionary) -> Dictionary:
	var request := payload.duplicate(true)
	request["request_id"] = request_id
	request["source_page"] = source_page
	request["action"] = action_id
	return request


func _controller() -> RunRuntimeController:
	var controller: RunRuntimeController = RunRuntimeControllerScript.new()
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


func _has_envelope_fields(result: Dictionary) -> bool:
	for key in ["request_id", "source_page", "action", "target_id", "ok", "status", "duplicate", "result", "meta_progress_summary"]:
		if not result.has(key):
			return false
	return true


func _expect_status(result: Dictionary, status: StringName, label: String) -> void:
	_expect(not bool(result.get("ok", true)) and StringName(result.get("status", &"")) == status, "%s did not fail with %s" % [label, str(status)])
	_expect(_has_envelope_fields(result), "%s returned an incomplete envelope" % label)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
