extends RefCounted
class_name ResultPresentationModel

const ItemRarityDescriptorScript := preload("res://scripts/presentation/item_rarity_descriptor.gd")
const RunUIViewModelScript := preload("res://scripts/ui/shell/run_ui_view_model.gd")

# Read-only projection for the production result panel.  Currency, item
# movement, failure reason, persistence and salvage state are copied only from
# the terminal RunResult/display snapshot; this model never settles or saves.


static func build(snapshot: Dictionary) -> Dictionary:
	var settlement := _dictionary(snapshot.get("settlement", {}))
	var result_state := _result_state(
		String(snapshot.get("outcome", "Running")),
		String(settlement.get("outcome", snapshot.get("settlement_outcome", "")))
	)
	var reason_code := StringName(snapshot.get("terminal_reason_code", &""))
	var reason_text := reason_text_for(result_state, reason_code)
	var awaiting_salvage := (
		bool(settlement.get("requires_salvage_selection", false))
		and not bool(settlement.get("finalized", false))
	)
	var persistence_state := _persistence_state(snapshot, awaiting_salvage)
	var normal_exit_allowed := bool(snapshot.get(
		"normal_exit_allowed",
		persistence_state in [&"committed", &"duplicate_ignored"]
	))
	var retry_save_allowed := bool(snapshot.get(
		"retry_save_allowed",
		not awaiting_salvage and not normal_exit_allowed
	))
	var discard_unsaved_allowed := bool(snapshot.get(
		"discard_unsaved_allowed",
		not awaiting_salvage and not normal_exit_allowed
	))
	# Salvage selection is the only legal next step while pending.  Ignore any
	# stale action flags carried by a legacy display snapshot.
	if awaiting_salvage:
		normal_exit_allowed = false
		retry_save_allowed = false
		discard_unsaved_allowed = false
	var consequence_text := _consequence_text(result_state, settlement, awaiting_salvage)
	return {
		"presentation_contract": &"i3.result.read_only.v1",
		"title": _title(result_state),
		"summary": "%s\n%s" % [reason_text, consequence_text],
		"result_state": result_state,
		"reason_text": reason_text,
		"consequence_text": consequence_text,
		"terminal_reason_code": reason_code,
		"currency_metrics": _currency_metrics(result_state, settlement),
		"item_sections": _item_sections(result_state, settlement),
		"awaiting_salvage": awaiting_salvage,
		"salvage_candidates": _item_models(_array(settlement.get("settlement_pool", []))),
		"salvage_capacity": int(settlement.get("salvage_capacity", 0)),
		"persistence_state": persistence_state,
		"persistence_text": _persistence_text(persistence_state),
		"normal_exit_allowed": normal_exit_allowed,
		"retry_save_allowed": retry_save_allowed,
		"discard_unsaved_allowed": discard_unsaved_allowed,
		"discard_unsaved_confirmation_count": int(snapshot.get("discard_unsaved_confirmation_count", 2)),
		"read_only": true,
		"authority": &"RunResult",
		"ui_recalculation_allowed": false,
	}


static func _result_state(outcome: String, settlement_outcome: String) -> StringName:
	if outcome in ["Extracted", "Training Complete"] or settlement_outcome == "success":
		return &"success"
	if outcome == "Failed" or settlement_outcome == "failure":
		return &"failure"
	if outcome == "Abandoned" or settlement_outcome == "abandon":
		return &"abandon"
	return &"unknown"


static func _title(result_state: StringName) -> String:
	match result_state:
		&"success":
			return "撤离成功"
		&"failure":
			return "探索失败"
		&"abandon":
			return "已放弃探索"
	return "探索结算"


static func reason_text_for(result_state: StringName, reason_code: StringName) -> String:
	if result_state == &"success":
		return "你已抵达撤离信标，本次探索完成。"
	if result_state == &"abandon":
		return "你主动结束了本次探索。"
	var reason := String(reason_code)
	if reason in ["mine", "fatal_mine", "mine_triggered"]:
		return "你在雷区受到致命伤害，未能完成撤离。"
	if reason == "hp_depleted":
		return "生命值归零，未能完成撤离。"
	if reason == "monster" or reason == "runtime_combat_defeat" or reason.begins_with("runtime_combat_"):
		return "你在与异常体的交战中失去行动能力。"
	if reason.begins_with("event_"):
		return "事件造成致命后果，本次探索中断。"
	return "探索信号中断，未能完成撤离。"


static func _consequence_text(result_state: StringName, settlement: Dictionary, awaiting_salvage: bool) -> String:
	var warehouse_count := _array(settlement.get("warehouse_items", [])).size()
	var salvaged_count := _array(settlement.get("salvaged_items", [])).size()
	var lost_count := _array(settlement.get("lost_items", [])).size()
	var floor_count := _array(settlement.get("room_floor_lost_items", [])).size()
	var cleared_count := _array(settlement.get("cleared_consumables", [])).size()
	if awaiting_salvage:
		var candidate_count := _array(settlement.get("settlement_pool", [])).size()
		return "黑资损失 %d，已锁定收益保留 %d；从 %d 件候选物资中选择可保全内容。" % [
			int(settlement.get("black_coin_lost", 0)),
			int(settlement.get("safe_yield_retained", settlement.get("safe_yield", 0))),
			candidate_count,
		]
	if result_state == &"success":
		return "带回 %d 件物资；现场遗留 %d 件，消耗或清除 %d 件。" % [warehouse_count, floor_count, cleared_count]
	return "保全 %d 件；未能带回 %d 件，现场遗留 %d 件，消耗或清除 %d 件。" % [
		salvaged_count,
		lost_count,
		floor_count,
		cleared_count,
	]


static func _currency_metrics(result_state: StringName, settlement: Dictionary) -> Array[Dictionary]:
	if result_state == &"success":
		return [
			{"label": "黑资转化", "value": int(settlement.get("black_coin_converted", 0)), "tone": &"positive"},
			{"label": "已锁定收益", "value": int(settlement.get("safe_yield_retained", settlement.get("safe_yield", 0))), "tone": &"positive"},
			{"label": "结算收益", "value": int(settlement.get("gold_coin_gained", 0)), "tone": &"positive"},
		]
	return [
		{"label": "黑资损失", "value": int(settlement.get("black_coin_lost", 0)), "tone": &"negative"},
		{"label": "已锁定收益", "value": int(settlement.get("safe_yield_retained", settlement.get("safe_yield", 0))), "tone": &"positive"},
		{"label": "实际保留", "value": int(settlement.get("gold_coin_gained", settlement.get("safe_yield", 0))), "tone": &"positive"},
	]


static func _item_sections(result_state: StringName, settlement: Dictionary) -> Array[Dictionary]:
	var sections: Array[Dictionary] = []
	if result_state == &"success":
		sections.append(_item_section(&"warehouse_items", "带回仓库", _array(settlement.get("warehouse_items", []))))
	else:
		sections.append(_item_section(&"salvaged_items", "已保全", _array(settlement.get("salvaged_items", []))))
		sections.append(_item_section(&"lost_items", "未能带回", _array(settlement.get("lost_items", []))))
	sections.append(_item_section(&"room_floor_lost_items", "遗留在现场", _array(settlement.get("room_floor_lost_items", []))))
	sections.append(_item_section(&"cleared_consumables", "已消耗或清除", _array(settlement.get("cleared_consumables", []))))
	return sections


static func _item_section(section_id: StringName, title: String, items: Array) -> Dictionary:
	return {
		"section_id": section_id,
		"title": title,
		"items": _item_models(items),
		"count": items.size(),
	}


static func _item_models(items: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_item in items:
		if not raw_item is Dictionary:
			continue
		var item := raw_item as Dictionary
		var presentation := RunUIViewModelScript.item_presentation(item)
		result.append({
			"instance_id": String(item.get("instance_id", "")),
			"display_name": String(presentation.get("display_name", "未命名物资")),
			"short_description": String(presentation.get("short_description", "")),
			"weight": maxi(0, int(presentation.get("weight", 1))),
			"rarity": (presentation.get("rarity", ItemRarityDescriptorScript.describe(&"unknown")) as Dictionary).duplicate(true),
			"collectible_level": maxi(0, int(presentation.get("collectible_level", 0))),
			"collectible_level_text": String(presentation.get("collectible_level_text", "")),
			"detail_text": String(presentation.get("detail_text", "")),
		})
	return result


static func _persistence_state(snapshot: Dictionary, awaiting_salvage: bool) -> StringName:
	if awaiting_salvage:
		return &"awaiting_salvage_confirmation"
	var explicit := StringName(snapshot.get("persistence_state", &""))
	if explicit != &"":
		return explicit
	var commit := _dictionary(snapshot.get("meta_progress_commit", {}))
	var status := StringName(commit.get("status", &""))
	if status in [
		&"committed",
		&"duplicate_ignored",
		&"save_failed",
		&"write_blocked",
		&"meta_progress_adapter_missing",
		&"discarded_unsaved",
		&"tutorial_completed",
		&"tutorial_replay_complete",
		&"tutorial_incomplete_no_write",
	]:
		return status
	return &"missing"


static func _persistence_text(state: StringName) -> String:
	match state:
		&"committed":
			return "进度已保存。"
		&"duplicate_ignored":
			return "本次结果此前已保存，没有重复结算。"
		&"awaiting_salvage_confirmation":
			return "确认保全后才会保存本次结果。"
		&"save_failed", &"write_blocked":
			return "档案暂时无法写入；请重试保存，或明确放弃这份未保存结果。"
		&"meta_progress_adapter_missing":
			return "暂时无法连接进度存储；本次结果尚未保存。"
		&"discarded_unsaved":
			return "你已确认放弃这份未保存结果；本次进度不会写入档案。"
		&"tutorial_completed":
			return "教程完成状态已保存；训练收益不会写入正式档案。"
		&"tutorial_replay_complete":
			return "教程重播已完成；正式档案没有重复结算。"
		&"tutorial_incomplete_no_write":
			return "教程未完成；按训练规则未写入正式档案。"
	return "本次结果尚未保存，请重试。"


static func _array(value: Variant) -> Array:
	return (value as Array).duplicate(true) if value is Array else []


static func _dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}
