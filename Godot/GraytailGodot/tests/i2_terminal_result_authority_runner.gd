extends SceneTree

const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const RunSceneResultControllerScript := preload("res://scripts/core/run/run_scene_result_controller.gd")
const RunUIViewModelScript := preload("res://scripts/ui/shell/run_ui_view_model.gd")

var failures: Array[String] = []
var save_path := "user://i2_terminal_result_authority/meta_progress.json"


func _init() -> void:
	_cleanup()
	_validate_success_breakdown()
	_validate_failure_lifecycle()
	_validate_abandon_breakdown()
	_cleanup()
	if failures.is_empty():
		print("I2_TERMINAL_RESULT_AUTHORITY=PASS outcomes=success,failure_pending,failure_finalized,abandon reason=lifecycle_event items=authoritative_arrays floor_loss=visible pending_meta_writes=0")
		quit(0)
		return
	for failure in failures:
		printerr("I2_TERMINAL_RESULT_AUTHORITY=FAIL:%s" % failure)
	quit(1)


func _validate_success_breakdown() -> void:
	var controller = RunRuntimeControllerScript.new()
	_require(bool(controller.start_demo_run(null).get("ok", false)), "success fixture did not start")
	var ledger = controller.context.asset_ledger
	ledger.create_item_instance(_item("success_keep", "密封记录盒", &"tier_5", 2), RunAssetLedger.LOCATION_INVENTORY)
	ledger.create_item_instance({
		"instance_id": "success_legacy_raw",
		"item_id": "RAW_INTERNAL_ITEM_ID",
		"rarity": &"tier_1",
		"weight": 1,
		"base_value": 1,
		"can_store": true,
	}, RunAssetLedger.LOCATION_INVENTORY)
	ledger.create_item_instance(_item("success_floor", "遗落线圈", &"tier_2", 1), RunAssetLedger.LOCATION_ROOM_FLOOR, controller.context.get_current_pos())
	ledger.create_item_instance(_consumable("success_consumable", "应急药剂", &"tier_1", 1), RunAssetLedger.LOCATION_INVENTORY)
	ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, 12, "i2_success")
	ledger.add_currency(RunAssetLedger.CURRENCY_GOLD, 3, "i2_success")
	_require(bool(controller.debug_force_extract().get("ok", false)), "success fixture did not settle")
	var snapshot: Dictionary = controller.context.result_snapshot
	_require(StringName(snapshot.get("terminal_reason_code", &"")) == &"extracted", "success terminal reason was not frozen")
	var settlement: Dictionary = snapshot.get("settlement", {})
	_require(_ids(settlement.get("warehouse_items", [])) == ["success_keep", "success_legacy_raw"], "success warehouse authority changed")
	_require(_ids(settlement.get("room_floor_lost_items", [])) == ["success_floor"], "success floor loss authority changed")
	_require(_ids(settlement.get("cleared_consumables", [])) == ["success_consumable"], "success consumable authority changed")
	var display := RunSceneResultControllerScript.build_result_display_snapshot(snapshot, {}, {"ok": true, "status": &"committed"})
	var model := RunUIViewModelScript.result_summary(display)
	_assert_section_matches(model, settlement, &"warehouse_items", "success warehouse section")
	_assert_section_matches(model, settlement, &"room_floor_lost_items", "success floor section")
	_assert_section_matches(model, settlement, &"cleared_consumables", "success consumable section")
	var floor_model := _first_section_item(model, &"room_floor_lost_items")
	_require(StringName((floor_model.get("rarity", {}) as Dictionary).get("normalized_key", &"")) == &"tier_2", "success floor rarity was not projected")
	_require(int(floor_model.get("weight", -1)) == 1, "success floor weight was not projected")
	var legacy_item_model := _section_item_by_instance(model, &"warehouse_items", "success_legacy_raw")
	_require(not String(legacy_item_model.get("display_name", "")).contains("RAW_INTERNAL_ITEM_ID"), "success result player copy exposed a raw item_id")
	_require(bool(model.get("normal_exit_allowed", false)), "committed success did not allow normal exit")


func _validate_failure_lifecycle() -> void:
	var adapter = MetaProgressAdapterScript.new()
	adapter.set_active_profile_path(save_path, "i2_terminal_result_authority")
	var controller = RunRuntimeControllerScript.new()
	controller.bind_meta_progress_adapter(adapter)
	_require(bool(controller.start_demo_run(null).get("ok", false)), "failure fixture did not start")
	var ledger = controller.context.asset_ledger
	ledger.create_item_instance(_item("failure_keep", "稀有测绘仪", &"tier_4", 2), RunAssetLedger.LOCATION_INVENTORY)
	ledger.create_item_instance(_item("failure_lose", "旧式继电器", &"tier_2", 1), RunAssetLedger.LOCATION_INVENTORY)
	ledger.create_item_instance(_item("failure_floor", "遗落样本", &"tier_3", 1), RunAssetLedger.LOCATION_ROOM_FLOOR, controller.context.get_current_pos())
	ledger.create_item_instance(_consumable("failure_consumable", "一次性针剂", &"tier_1", 1), RunAssetLedger.LOCATION_INVENTORY)
	ledger.add_currency(RunAssetLedger.CURRENCY_BLACK, 19, "i2_failure")
	ledger.add_currency(RunAssetLedger.CURRENCY_GOLD, 4, "i2_failure")
	var before_runs := int(adapter.get_summary().get("run_count", 0))
	_require(bool(controller.fail_run("fatal_mine").get("ok", false)), "failure fixture did not enter salvage")
	controller.command_bus.result_available.emit(controller.context.result_snapshot)
	var pending: Dictionary = controller.context.result_snapshot
	_require(StringName(pending.get("terminal_reason_code", &"")) == &"fatal_mine", "pending failure reason was not frozen from lifecycle event")
	_require(str(controller.last_meta_commit.get("status", "")) == "awaiting_salvage_confirmation", "pending failure did not block meta commit")
	_require(int(adapter.get_summary().get("run_count", 0)) == before_runs, "pending failure wrote meta progress")
	var pending_display := RunSceneResultControllerScript.build_result_display_snapshot(pending, adapter.get_summary(), controller.last_meta_commit)
	var pending_model := RunUIViewModelScript.result_summary(pending_display)
	_require(not bool(pending_model.get("normal_exit_allowed", true)), "pending failure allowed normal exit")
	_require(String(pending_model.get("summary", "")).find("不会保存") >= 0, "pending failure copy claimed or implied persistence")

	_require(bool(controller.confirm_failure_salvage(["failure_keep"]).get("ok", false)), "failure salvage confirmation failed")
	controller.command_bus.result_available.emit(controller.context.result_snapshot)
	var finalized: Dictionary = controller.context.result_snapshot
	_require(StringName(finalized.get("terminal_reason_code", &"")) == &"fatal_mine", "failure reason changed after salvage confirmation")
	var settlement: Dictionary = finalized.get("settlement", {})
	_require(_ids(settlement.get("salvaged_items", [])) == ["failure_keep"], "failure salvaged authority changed")
	_require(_ids(settlement.get("lost_items", [])) == ["failure_lose"], "failure lost authority changed")
	_require(_ids(settlement.get("room_floor_lost_items", [])) == ["failure_floor"], "failure floor authority changed")
	_require(_ids(settlement.get("cleared_consumables", [])) == ["failure_consumable"], "failure consumable authority changed")
	_require(str(controller.last_meta_commit.get("status", "")) == "committed", "finalized failure did not commit")
	_require(int(adapter.get_summary().get("run_count", 0)) == before_runs + 1, "finalized failure meta count mismatch")
	var display := RunSceneResultControllerScript.build_result_display_snapshot(finalized, adapter.get_summary(), controller.last_meta_commit)
	var model := RunUIViewModelScript.result_summary(display)
	_assert_section_matches(model, settlement, &"salvaged_items", "failure salvaged section")
	_assert_section_matches(model, settlement, &"lost_items", "failure lost section")
	_assert_section_matches(model, settlement, &"room_floor_lost_items", "failure floor section")
	_assert_section_matches(model, settlement, &"cleared_consumables", "failure consumable section")
	_require(String(model.get("reason_text", "")).find("雷险") >= 0, "failure cause was not player-facing")


func _validate_abandon_breakdown() -> void:
	var controller = RunRuntimeControllerScript.new()
	_require(bool(controller.start_demo_run(null).get("ok", false)), "abandon fixture did not start")
	var ledger = controller.context.asset_ledger
	ledger.create_item_instance(_item("abandon_lost", "未回收组件", &"tier_3", 2), RunAssetLedger.LOCATION_INVENTORY)
	ledger.create_item_instance(_item("abandon_floor", "现场残片", &"tier_2", 1), RunAssetLedger.LOCATION_ROOM_FLOOR, controller.context.get_current_pos())
	ledger.create_item_instance(_consumable("abandon_consumable", "临时补给", &"tier_1", 1), RunAssetLedger.LOCATION_INVENTORY)
	_require(bool(controller.abandon_run("player_pause_exit_current_run").get("ok", false)), "abandon fixture did not settle")
	var snapshot: Dictionary = controller.context.result_snapshot
	_require(StringName(snapshot.get("terminal_reason_code", &"")) == &"player_pause_exit_current_run", "abandon reason was not frozen from lifecycle event")
	var settlement: Dictionary = snapshot.get("settlement", {})
	var display := RunSceneResultControllerScript.build_result_display_snapshot(snapshot, {}, {"ok": true, "status": &"duplicate_ignored", "duplicate": true})
	var model := RunUIViewModelScript.result_summary(display)
	_assert_section_matches(model, settlement, &"lost_items", "abandon lost section")
	_assert_section_matches(model, settlement, &"room_floor_lost_items", "abandon floor section")
	_assert_section_matches(model, settlement, &"cleared_consumables", "abandon consumable section")
	_require(String(model.get("reason_text", "")).find("主动结束") >= 0, "abandon reason was not player-facing")
	_require(String(model.get("persistence_text", "")).find("未重复结算") >= 0, "duplicate commit copy was inaccurate")


func _item(instance_id: String, display_name: String, rarity: StringName, weight: int) -> Dictionary:
	return {
		"instance_id": instance_id,
		"item_id": instance_id,
		"display_name": display_name,
		"short_description": "局终权威夹具物资。",
		"item_type": &"collectible",
		"rarity": rarity,
		"weight": weight,
		"base_value": 20,
		"can_store": true,
	}


func _consumable(instance_id: String, display_name: String, rarity: StringName, weight: int) -> Dictionary:
	var item := _item(instance_id, display_name, rarity, weight)
	item["item_type"] = &"consumable"
	item["can_consume"] = true
	return item


func _assert_section_matches(model: Dictionary, settlement: Dictionary, section_id: StringName, label: String) -> void:
	var expected := _ids(settlement.get(String(section_id), []))
	var actual: Array[String] = []
	for section in model.get("item_sections", []):
		if section is Dictionary and StringName(section.get("section_id", &"")) == section_id:
			for item in section.get("items", []):
				if item is Dictionary:
					actual.append(String(item.get("instance_id", "")))
	_require(actual == expected, "%s ids=%s expected=%s" % [label, actual, expected])


func _first_section_item(model: Dictionary, section_id: StringName) -> Dictionary:
	for section in model.get("item_sections", []):
		if section is Dictionary and StringName(section.get("section_id", &"")) == section_id:
			var items: Array = section.get("items", [])
			return items[0] if not items.is_empty() and items[0] is Dictionary else {}
	return {}


func _section_item_by_instance(model: Dictionary, section_id: StringName, instance_id: String) -> Dictionary:
	for section in model.get("item_sections", []):
		if section is Dictionary and StringName(section.get("section_id", &"")) == section_id:
			for item in section.get("items", []):
				if item is Dictionary and String(item.get("instance_id", "")) == instance_id:
					return item
	return {}


func _ids(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for raw_item in value:
			if raw_item is Dictionary:
				result.append(String(raw_item.get("instance_id", "")))
	return result


func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		var path: String = save_path + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
