extends SceneTree

const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RunSceneResultControllerScript := preload("res://scripts/core/run/run_scene_result_controller.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const SaveAdapterScript := preload("res://scripts/core/save/save_adapter.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const MetaActionRequestIdScript := preload("res://scripts/core/progression/meta_action_request_id.gd")
const DeployPrepShellScript := preload("res://scripts/ui/deploy_prep/deploy_prep_shell.gd")
const LongTermShellScript := preload("res://scripts/ui/long_term/long_term_shell.gd")
const AppShellScript := preload("res://scripts/ui/app_shell/app_shell.gd")

const PERSISTENT_IDEMPOTENCY_PATH := "user://tests/i2_meta_action_persistent_idempotency.json"


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


class CountingSaveAdapter:
	extends SaveAdapter

	var load_calls := 0

	func load_json_result(
		path: String = M1_META_PROGRESS_PATH,
		default_data: Dictionary = {},
		normalize_meta_progress: bool = true
	) -> Dictionary:
		load_calls += 1
		return super.load_json_result(path, default_data, normalize_meta_progress)


class ToggleSaveAdapter:
	extends SaveAdapter

	var fail_saves := false

	func save_json(
		data: Dictionary,
		path: String = M1_META_PROGRESS_PATH,
		normalize_meta_progress: bool = true
	) -> bool:
		if fail_saves:
			last_error = "injected_terminal_save_failure"
			return false
		return super.save_json(data, path, normalize_meta_progress)


var failures: Array[String] = []
var controllers: Array[RunRuntimeController] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_purchase_idempotency_and_conflict()
	_test_all_action_payloads()
	_test_failure_propagation()
	_test_fail_closed_validation()
	_test_active_run_item_protection()
	_test_failure_salvage_real_adapter_protection()
	_test_adapter_rebind_cache_scope()
	_test_session_cache_retention()
	_test_persistent_idempotency_across_controller_rebuild()
	_test_persistent_receipt_retention_window()
	_test_dynamic_guard_persistent_fingerprint()
	_test_terminal_retry_instance_protection()
	_test_explicit_terminal_discard_transition()
	_test_production_request_id_generation()
	_cleanup_controllers()
	_remove_persistent_idempotency_files()
	if failures.is_empty():
		print("I2_DEPLOY_META_ACTION_TRANSACTION=PASS actions=5 duplicate=persisted conflict=fail_closed receipts=bounded512 request_ids=128bit guards=dynamic terminal=retry_or_explicit_discard authority=adapter")
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
			"blocked_instance_ids": ["different-runtime-lock"],
		}
	))
	_expect(bool(sell_duplicate.get("duplicate", false)) and adapter.calls.size() == 1, "dynamic blocked IDs changed the logical transaction fingerprint")
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
	_expect_status(
		controller.execute_meta_action(_request(
			"invalid-goal-kind",
			"long_term",
			&"claim_goal",
			{"goal_kind": "achievment", "goal_id": "achievement_safe_return"}
		)),
		&"invalid_goal_kind",
		"misspelled goal kind"
	)
	_expect(adapter.calls.is_empty() and adapter.revision == 0, "invalid request reached adapter authority")
	var unbound = _controller()
	_expect_status(unbound.execute_meta_action(_request("unbound", "deploy", &"purchase", {"item_id": "con_ration"})), &"meta_progress_adapter_missing", "missing adapter")


func _test_active_run_item_protection() -> void:
	var adapter := FakeMetaProgressAdapter.new()
	var controller = _controller()
	controller.bind_meta_progress_adapter(adapter)
	controller.context.run_active = true
	controller.context.run_start_config = {
		"selected_equipment_ids": ["active:eq"],
		"selected_consumable_ids": ["active:con"],
		"selected_equipment_items": [{"instance_id": "active:eq"}],
		"selected_consumable_items": [{"instance_id": "active:con"}],
	}
	var sell := controller.execute_meta_action(_request(
		"active-protection-sell",
		"deploy",
		&"sell_collectible",
		{"instance_id": "warehouse:other"}
	))
	_expect(bool(sell.get("ok", false)), "active protection sell probe did not reach adapter")
	var sell_call := adapter.calls.back() as Dictionary
	_expect(
		sell_call.get("blocked_instance_ids", []) == ["active:con", "active:eq"],
		"active run equipment/consumables were not derived into the sell lock"
	)
	var research := controller.execute_meta_action(_request(
		"active-protection-research",
		"long_term",
		&"complete_research",
		{"research_id": "research_anomaly_structure"}
	))
	_expect(bool(research.get("ok", false)), "active protection research probe did not reach adapter")
	var research_call := adapter.calls.back() as Dictionary
	_expect(
		research_call.get("blocked_instance_ids", []) == ["active:con", "active:eq"],
		"active run equipment/consumables were not derived into the research lock"
	)
	controller.context.run_active = false
	var inactive_sell := controller.execute_meta_action(_request(
		"inactive-protection-sell",
		"deploy",
		&"sell_collectible",
		{"instance_id": "warehouse:other"}
	))
	_expect(bool(inactive_sell.get("ok", false)), "inactive protection sell probe did not reach adapter")
	var inactive_call := adapter.calls.back() as Dictionary
	_expect(
		(inactive_call.get("blocked_instance_ids", []) as Array).is_empty(),
		"completed run kept stale transaction locks"
	)


func _test_failure_salvage_real_adapter_protection() -> void:
	_remove_persistent_idempotency_files()
	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(PERSISTENT_IDEMPOTENCY_PATH, "i2_failure_salvage_guard")
	adapter.data["gold"] = 100
	var material := M7ContentCatalogScript.item_definition("mon_old_gear_set")
	material["instance_id"] = "salvage:material"
	var warehouse := (adapter.data.get("warehouse_items", []) as Array).duplicate(true)
	warehouse.append(material)
	adapter.data["warehouse_items"] = warehouse
	_expect(adapter.save(), "failure-salvage protection fixture could not initialize")
	var controller = _controller()
	controller.bind_meta_progress_adapter(adapter)
	controller.context.run_active = false
	controller.context.phase = &"failure_salvage"
	controller.context.run_start_config = {
		"selected_equipment_ids": ["m6_starter:eq_goggles:1"],
		"selected_consumable_ids": ["salvage:material"],
	}
	var sell := controller.execute_meta_action(_request(
		"salvage-guard-sell",
		"deploy",
		&"sell_collectible",
		{"instance_id": "m6_starter:eq_goggles:1"}
	))
	_expect(
		not bool(sell.get("ok", true))
		and StringName(sell.get("status", &"")) == &"configured_item_blocked",
		"failure-salvage equipment reached the real adapter sell mutation"
	)
	var research := controller.execute_meta_action(_request(
		"salvage-guard-research",
		"long_term",
		&"complete_research",
		{"research_id": "research_anomaly_structure"}
	))
	_expect(
		not bool(research.get("ok", true))
		and StringName(research.get("status", &"")) == &"material_missing_or_configured",
		"failure-salvage consumable was consumed by the real adapter research mutation"
	)
	var retained_material := false
	for raw_item in adapter.data.get("warehouse_items", []) as Array:
		if (
			raw_item is Dictionary
			and str((raw_item as Dictionary).get("instance_id", "")) == "salvage:material"
		):
			retained_material = true
			break
	_expect(retained_material, "failure-salvage research removed the protected material")


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


func _test_persistent_idempotency_across_controller_rebuild() -> void:
	_remove_persistent_idempotency_files()
	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(PERSISTENT_IDEMPOTENCY_PATH, "i2_meta_action_idempotency")
	adapter.data["gold"] = 100
	_expect(adapter.save(), "persistent idempotency fixture could not initialize its save")
	var controller = _controller()
	controller.bind_meta_progress_adapter(adapter)
	var request := _request(
		"persistent-purchase-1",
		"deploy",
		&"purchase",
		{"item_id": "con_ration"}
	)
	var first := controller.execute_meta_action(request)
	_expect(bool(first.get("ok", false)), "persistent purchase did not commit")
	var gold_after_first := int(adapter.data.get("gold", -1))
	var warehouse_count_after_first := (adapter.data.get("warehouse_items", []) as Array).size()
	_expect(gold_after_first == 88, "persistent purchase debited an unexpected amount")

	var raw_save: Variant = JSON.parse_string(FileAccess.get_file_as_string(PERSISTENT_IDEMPOTENCY_PATH))
	_expect(raw_save is Dictionary, "persistent purchase did not leave a readable atomic save")
	var raw_receipts: Variant = (
		(raw_save as Dictionary).get("meta_action_receipts", {})
		if raw_save is Dictionary
		else {}
	)
	_expect(
		raw_receipts is Dictionary and (raw_receipts as Dictionary).has("persistent-purchase-1"),
		"business mutation and request receipt were not committed to the same save"
	)
	var normalized_save := SaveAdapterScript.new().load_json_result(
		PERSISTENT_IDEMPOTENCY_PATH,
		SaveAdapterScript.new().default_meta_progress()
	)
	_expect(
		((normalized_save.get("data", {}) as Dictionary).get("meta_action_receipts", {}) as Dictionary).has(
			"persistent-purchase-1"
		),
		"SaveAdapter normalization dropped meta-action receipts"
	)

	var reloaded = MetaProgressAdapterScript.new()
	reloaded.set_active_profile_path(PERSISTENT_IDEMPOTENCY_PATH, "i2_meta_action_idempotency")
	var counting_save := CountingSaveAdapter.new()
	reloaded.save_adapter = counting_save
	reloaded.load_or_create_default()
	_expect(counting_save.load_calls == 1, "MetaProgressAdapter performed duplicate reads to recover receipts")
	var rebuilt_controller = _controller()
	rebuilt_controller.bind_meta_progress_adapter(reloaded)
	var duplicate := rebuilt_controller.execute_meta_action(request)
	_expect(
		bool(duplicate.get("ok", false)) and bool(duplicate.get("duplicate", false)),
		"controller rebuild did not recover the persisted duplicate result"
	)
	_expect(
		int(reloaded.data.get("gold", -1)) == gold_after_first
		and (reloaded.data.get("warehouse_items", []) as Array).size() == warehouse_count_after_first,
		"persisted duplicate repeated the debit or item grant"
	)
	var conflict := rebuilt_controller.execute_meta_action(_request(
		"persistent-purchase-1",
		"deploy",
		&"purchase",
		{"item_id": "con_stabilizer"}
	))
	_expect(
		not bool(conflict.get("ok", true))
		and StringName(conflict.get("status", &"")) == &"request_id_conflict",
		"reloaded request receipt did not fail closed on a changed payload"
	)
	_expect(
		int(reloaded.data.get("gold", -1)) == gold_after_first
		and (reloaded.data.get("warehouse_items", []) as Array).size() == warehouse_count_after_first,
		"reloaded request-id conflict mutated authoritative progress"
	)

	reloaded.add_gold(1, "receipt_retention_probe")
	var after_unrelated_save := int(reloaded.data.get("gold", -1))
	var reloaded_again = MetaProgressAdapterScript.new()
	reloaded_again.set_active_profile_path(PERSISTENT_IDEMPOTENCY_PATH, "i2_meta_action_idempotency")
	var second_rebuild_controller = _controller()
	second_rebuild_controller.bind_meta_progress_adapter(reloaded_again)
	var retained_duplicate := second_rebuild_controller.execute_meta_action(request)
	_expect(
		bool(retained_duplicate.get("duplicate", false))
		and int(reloaded_again.data.get("gold", -1)) == after_unrelated_save,
		"an unrelated later save dropped the persisted request receipt"
	)


func _test_persistent_receipt_retention_window() -> void:
	_remove_persistent_idempotency_files()
	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(PERSISTENT_IDEMPOTENCY_PATH, "i2_receipt_retention")
	var legacy_receipts := adapter.call("_validated_meta_action_receipts", {
		"legacy-request": {
			"schema_version": 1,
			"fingerprint": "{\"action\":\"legacy\"}",
			"result": {"ok": true, "status": "legacy"},
		},
	}) as Dictionary
	_expect(
		legacy_receipts.has("legacy-request")
		and int((legacy_receipts.get("legacy-request", {}) as Dictionary).get("committed_sequence", 0)) == 1,
		"receipt retention rejected a valid pre-sequence schema-1 receipt"
	)

	var receipt_limit := int(MetaProgressAdapterScript.META_ACTION_RECEIPT_LIMIT)
	var receipts := {}
	for index in range(receipt_limit + 3):
		receipts["retained-%04d" % index] = {
			"schema_version": 1,
			"committed_sequence": index + 1,
			"fingerprint": "{\"request\":%d}" % index,
			"result": {"ok": true, "status": "synthetic"},
		}
	adapter.data[MetaProgressAdapterScript.META_ACTION_RECEIPTS_KEY] = receipts
	var transaction := adapter.execute_idempotent_meta_action(
		"retention-newest",
		{"source_page": "long_term", "action": &"mark_viewed", "view_kind": "history"},
		Callable(adapter, "mark_long_term_viewed").bind("history")
	)
	_expect(
		StringName(transaction.get("idempotency_status", &"")) == &"executed",
		"bounded receipt fixture did not commit its newest transaction"
	)
	var bounded := adapter.data.get(MetaProgressAdapterScript.META_ACTION_RECEIPTS_KEY, {}) as Dictionary
	_expect(bounded.size() == receipt_limit, "persisted receipt window exceeded its hard limit")
	_expect(not bounded.has("retained-0000"), "persisted receipt window retained its oldest entry")
	_expect(bounded.has("retained-%04d" % (receipt_limit + 2)), "persisted receipt window dropped a recent entry")
	_expect(bounded.has("retention-newest"), "persisted receipt window dropped the transaction being committed")

	var reloaded = MetaProgressAdapterScript.new()
	reloaded.set_active_profile_path(PERSISTENT_IDEMPOTENCY_PATH, "i2_receipt_retention")
	var reloaded_receipts := reloaded.data.get(MetaProgressAdapterScript.META_ACTION_RECEIPTS_KEY, {}) as Dictionary
	_expect(
		reloaded_receipts.size() == receipt_limit
		and reloaded_receipts.has("retention-newest")
		and not reloaded_receipts.has("retained-0000"),
		"receipt retention boundary was not stable after reload"
	)


func _test_dynamic_guard_persistent_fingerprint() -> void:
	_remove_persistent_idempotency_files()
	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(PERSISTENT_IDEMPOTENCY_PATH, "i2_dynamic_guard_fingerprint")
	var first_fingerprint := str(adapter.call(
		"_meta_action_fingerprint",
		{"action": &"sell_collectible", "instance_id": "same", "blocked_instance_ids": ["first"]}
	))
	var changed_guard_fingerprint := str(adapter.call(
		"_meta_action_fingerprint",
		{"action": &"sell_collectible", "instance_id": "same", "blocked_instance_ids": ["changed"]}
	))
	_expect(
		not first_fingerprint.is_empty() and first_fingerprint == changed_guard_fingerprint,
		"MetaProgressAdapter included dynamic blocked IDs in its persisted fingerprint"
	)
	var collectible := M7ContentCatalogScript.item_definition("col_01")
	collectible["instance_id"] = "dynamic:sale-target"
	var warehouse := (adapter.data.get("warehouse_items", []) as Array).duplicate(true)
	warehouse.append(collectible)
	adapter.data["warehouse_items"] = warehouse
	_expect(adapter.save(), "dynamic guard fingerprint fixture could not initialize")
	var request := _request(
		"dynamic-guard-sale",
		"deploy",
		&"sell_collectible",
		{"instance_id": "dynamic:sale-target"}
	)
	var controller = _controller()
	controller.bind_meta_progress_adapter(adapter)
	controller.context.run_active = true
	controller.context.run_start_config = {"selected_equipment_ids": ["guard:first"]}
	var first := controller.execute_meta_action(request)
	_expect(bool(first.get("ok", false)), "dynamic guard fingerprint sale did not commit")
	var gold_after_first := int(adapter.data.get("gold", -1))

	var reloaded = MetaProgressAdapterScript.new()
	reloaded.set_active_profile_path(PERSISTENT_IDEMPOTENCY_PATH, "i2_dynamic_guard_fingerprint")
	var rebuilt = _controller()
	rebuilt.bind_meta_progress_adapter(reloaded)
	rebuilt.context.run_active = true
	rebuilt.context.run_start_config = {"selected_consumable_ids": ["guard:changed"]}
	var duplicate := rebuilt.execute_meta_action(request)
	_expect(
		bool(duplicate.get("duplicate", false))
		and int(reloaded.data.get("gold", -1)) == gold_after_first,
		"changed runtime guards invalidated a persisted logical transaction"
	)


func _test_terminal_retry_instance_protection() -> void:
	_remove_persistent_idempotency_files()
	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(PERSISTENT_IDEMPOTENCY_PATH, "i2_terminal_retry_guard")
	var collectible := M7ContentCatalogScript.item_definition("col_01")
	collectible["instance_id"] = "terminal-retry:collectible"
	var warehouse := (adapter.data.get("warehouse_items", []) as Array).duplicate(true)
	warehouse.append(collectible)
	adapter.data["warehouse_items"] = warehouse
	_expect(adapter.save(), "terminal retry protection fixture could not initialize")

	var toggle_save := ToggleSaveAdapter.new()
	toggle_save.fail_saves = true
	adapter.save_adapter = toggle_save
	var controller = _controller()
	controller.bind_meta_progress_adapter(adapter)
	var run_start_config := {
		"selected_consumable_ids": ["terminal-retry:collectible"],
		"selected_consumable_items": [collectible.duplicate(true)],
	}
	var result_snapshot := {
		"result_id": "terminal-retry-protection",
		"outcome": "Failed",
		"run_start_config": run_start_config.duplicate(true),
		"settlement": {
			"outcome": "failure",
			"requires_salvage_selection": false,
			"finalized": true,
			"salvaged_items": [collectible.duplicate(true)],
			"gold_coin_gained": 0,
		},
	}
	controller.context.run_active = false
	controller.context.phase = &"failed"
	controller.context.run_start_config = run_start_config.duplicate(true)
	controller.context.result_snapshot = result_snapshot.duplicate(true)
	controller.call("_on_terminal_result_available", result_snapshot)
	_expect(
		StringName(controller.last_meta_commit.get("status", &"")) == &"save_failed",
		"terminal retry fixture did not enter the persistence-failed state"
	)
	var blocked_sale := controller.execute_meta_action(_request(
		"terminal-retry-blocked-sale",
		"deploy",
		&"sell_collectible",
		{"instance_id": "terminal-retry:collectible"}
	))
	_expect(
		not bool(blocked_sale.get("ok", true))
		and StringName(blocked_sale.get("status", &"")) == &"configured_item_blocked",
		"terminal save failure released a carry-in instance before retry"
	)

	toggle_save.fail_saves = false
	var retry := controller.retry_terminal_commit()
	_expect(
		bool(retry.get("ok", false))
		and StringName(retry.get("status", &"")) == &"committed",
		"terminal persistence retry did not commit the same result snapshot"
	)
	var released_sale := controller.execute_meta_action(_request(
		"terminal-retry-released-sale",
		"deploy",
		&"sell_collectible",
		{"instance_id": "terminal-retry:collectible"}
	))
	_expect(
		bool(released_sale.get("ok", false))
		and StringName(released_sale.get("status", &"")) == &"sold",
		"successful terminal retry did not release the recovered instance"
	)


func _test_explicit_terminal_discard_transition() -> void:
	_remove_persistent_idempotency_files()
	var empty_controller = _controller()
	var missing_result: Dictionary = empty_controller.command_bus.dispatch(
		&"discard_unsaved_terminal_commit",
		{"confirmed": true}
	)
	_expect(
		not bool(missing_result.get("ok", true))
		and StringName(missing_result.get("status", &"")) == &"terminal_result_missing",
		"terminal discard was accepted without a terminal result"
	)

	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(PERSISTENT_IDEMPOTENCY_PATH, "i2_terminal_discard")
	var collectible := M7ContentCatalogScript.item_definition("col_01")
	collectible["instance_id"] = "terminal-discard:collectible"
	var warehouse := (adapter.data.get("warehouse_items", []) as Array).duplicate(true)
	warehouse.append(collectible)
	adapter.data["warehouse_items"] = warehouse
	_expect(adapter.save(), "terminal discard fixture could not initialize")
	var controller = _controller()
	controller.bind_meta_progress_adapter(adapter)
	var run_start_config := {
		"selected_consumable_ids": ["terminal-discard:collectible"],
		"selected_consumable_items": [collectible.duplicate(true)],
	}
	var result_snapshot := {
		"result_id": "terminal-discard-result",
		"outcome": "Failed",
		"run_start_config": run_start_config.duplicate(true),
		"settlement": {
			"outcome": "failure",
			"requires_salvage_selection": false,
			"finalized": true,
			"salvaged_items": [collectible.duplicate(true)],
		},
	}
	controller.context.run_active = false
	controller.context.phase = &"failed"
	controller.context.run_start_config = run_start_config.duplicate(true)
	controller.context.result_snapshot = result_snapshot.duplicate(true)
	controller.last_meta_commit = {
		"ok": false,
		"status": &"save_failed",
		"committed": false,
		"result_id": "terminal-discard-result",
	}

	var implicit_confirmation: Dictionary = controller.command_bus.dispatch(
		&"discard_unsaved_terminal_commit",
		{"confirmed": "true"}
	)
	_expect(
		not bool(implicit_confirmation.get("ok", true))
		and StringName(implicit_confirmation.get("status", &"")) == &"discard_confirmation_required"
		and StringName(controller.last_meta_commit.get("status", &"")) == &"save_failed",
		"terminal discard accepted a non-boolean confirmation"
	)
	var pending_snapshot := result_snapshot.duplicate(true)
	pending_snapshot["settlement"] = {
		"outcome": "failure",
		"requires_salvage_selection": true,
		"finalized": false,
	}
	controller.context.result_snapshot = pending_snapshot
	var premature: Dictionary = controller.command_bus.dispatch(
		&"discard_unsaved_terminal_commit",
		{"confirmed": true}
	)
	_expect(
		not bool(premature.get("ok", true))
		and StringName(premature.get("status", &"")) == &"terminal_result_not_finalized"
		and StringName(controller.last_meta_commit.get("status", &"")) == &"save_failed",
		"terminal discard cleared a pending salvage result"
	)
	controller.context.result_snapshot = result_snapshot.duplicate(true)
	controller.last_meta_commit = {
		"ok": true,
		"status": &"committed",
		"committed": true,
		"result_id": "terminal-discard-result",
	}
	var committed_discard: Dictionary = controller.command_bus.dispatch(
		&"discard_unsaved_terminal_commit",
		{"confirmed": true}
	)
	_expect(
		not bool(committed_discard.get("ok", true))
		and StringName(committed_discard.get("status", &"")) == &"terminal_commit_discard_not_pending",
		"terminal discard rewrote an already committed result"
	)
	controller.last_meta_commit = {
		"ok": false,
		"status": &"save_failed",
		"committed": false,
		"result_id": "terminal-discard-result",
	}
	var protected_sale := controller.execute_meta_action(_request(
		"terminal-discard-protected-sale",
		"deploy",
		&"sell_collectible",
		{"instance_id": "terminal-discard:collectible"}
	))
	_expect(
		not bool(protected_sale.get("ok", true))
		and StringName(protected_sale.get("status", &"")) == &"configured_item_blocked",
		"terminal discard fixture did not protect the carry-in instance before confirmation"
	)

	var discarded: Dictionary = controller.command_bus.dispatch(
		&"discard_unsaved_terminal_commit",
		{"confirmed": true}
	)
	_expect(
		bool(discarded.get("ok", false))
		and StringName(discarded.get("status", &"")) == &"discarded_unsaved",
		"explicit terminal discard did not complete its core state transition"
	)
	_expect(
		not bool(controller.last_meta_commit.get("ok", true))
		and not bool(controller.last_meta_commit.get("committed", true))
		and bool(controller.last_meta_commit.get("discarded", false))
		and StringName(controller.last_meta_commit.get("status", &"")) == &"discarded_unsaved",
		"terminal discard state falsely represented the result as persisted"
	)
	var display := RunSceneResultControllerScript.build_result_display_snapshot(
		result_snapshot,
		adapter.get_summary(),
		controller.last_meta_commit
	)
	_expect(
		StringName(display.get("persistence_state", &"")) == &"discarded_unsaved"
		and bool(display.get("normal_exit_allowed", false))
		and not bool(display.get("retry_save_allowed", true))
		and not bool(display.get("discard_unsaved_allowed", true)),
		"discarded terminal projection did not expose only normal exit"
	)
	var repeated: Dictionary = controller.command_bus.dispatch(
		&"discard_unsaved_terminal_commit",
		{"confirmed": true}
	)
	_expect(
		not bool(repeated.get("ok", true))
		and StringName(repeated.get("status", &"")) == &"terminal_commit_already_discarded"
		and StringName(controller.last_meta_commit.get("status", &"")) == &"discarded_unsaved",
		"repeated terminal discard changed the discarded state"
	)
	var rejected_retry: Dictionary = controller.command_bus.dispatch(&"retry_terminal_commit")
	_expect(
		not bool(rejected_retry.get("ok", true))
		and StringName(rejected_retry.get("status", &"")) == &"terminal_commit_discarded"
		and StringName(controller.last_meta_commit.get("status", &"")) == &"discarded_unsaved",
		"terminal retry resumed after the unsaved result was explicitly discarded"
	)
	var released_sale := controller.execute_meta_action(_request(
		"terminal-discard-released-sale",
		"deploy",
		&"sell_collectible",
		{"instance_id": "terminal-discard:collectible"}
	))
	_expect(
		bool(released_sale.get("ok", false))
		and StringName(released_sale.get("status", &"")) == &"sold",
		"explicit terminal discard did not release its carry-in instance"
	)


func _test_production_request_id_generation() -> void:
	var pattern := RegEx.new()
	_expect(pattern.compile("^(deploy|long_term|app):[0-9a-f]{32}$") == OK, "request-id format probe regex did not compile")
	var generated := {}
	for prefix in [&"deploy", &"long_term", &"app"]:
		for _index in range(32):
			var request_id := MetaActionRequestIdScript.generate(prefix)
			_expect(pattern.search(request_id) != null, "production request id has an invalid format: %s" % request_id)
			_expect(not generated.has(request_id), "production request id generator repeated a nonce")
			generated[request_id] = true

	var deploy := DeployPrepShellScript.new()
	var deploy_requests: Array[Dictionary] = []
	deploy.meta_action_requested.connect(
		func(action: Dictionary) -> void:
			deploy_requests.append(action.duplicate(true))
	)
	deploy.call("_submit_meta_action", {"action": &"purchase", "item_id": "con_ration"})
	_expect(
		deploy_requests.size() == 1
		and pattern.search(str(deploy_requests[0].get("request_id", ""))) != null,
		"deploy production path did not use the shared high-entropy request id"
	)

	var long_term := LongTermShellScript.new()
	var long_term_request := long_term.call(
		"_prepare_meta_action",
		{"action": &"mark_viewed", "view_kind": "history"}
	) as Dictionary
	_expect(
		pattern.search(str(long_term_request.get("request_id", ""))) != null,
		"long-term production path did not use the shared high-entropy request id"
	)

	var app := AppShellScript.new()
	var app_requests: Array[Dictionary] = []
	app.meta_action_requested.connect(
		func(action: Dictionary) -> void:
			app_requests.append(action.duplicate(true))
	)
	app.call("_forward_meta_action", {"action": &"mark_viewed", "view_kind": "codex"}, &"app")
	app.call(
		"_forward_meta_action",
		{"request_id": "pending:retry-id", "action": &"mark_viewed", "view_kind": "codex"},
		&"app"
	)
	_expect(
		app_requests.size() == 2
		and pattern.search(str(app_requests[0].get("request_id", ""))) != null,
		"app fallback production path did not use the shared high-entropy request id"
	)
	_expect(
		str(app_requests[1].get("request_id", "")) == "pending:retry-id",
		"app forwarding replaced the pending request id during retry"
	)
	deploy.free()
	long_term.free()
	app.free()


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


func _remove_persistent_idempotency_files() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		var path: String = PERSISTENT_IDEMPOTENCY_PATH + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


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
