extends RefCounted
class_name M7TalentCatalog

const CATALOG_VERSION := 1
const TALENT_COST := 1

const TALENT_CARRY_RIGGING := "talent_carry_rigging"
const TALENT_SALVAGE_CLAUSE := "talent_salvage_clause"
const TALENT_SHOCK_TRAINING := "talent_shock_training"
const TALENT_PRESSURE_READING := "talent_pressure_reading"
const TALENT_SCAN_DISCIPLINE := "talent_scan_discipline"
const TALENT_TRADER_NOTES := "talent_trader_notes"


static func definitions() -> Array[Dictionary]:
	return [
		_talent(
			TALENT_CARRY_RIGGING,
			&"preparation",
			"整备",
			1,
			"负重整备",
			[],
			&"backpack_capacity",
			1,
			"背包负重上限 +1"
		),
		_talent(
			TALENT_SALVAGE_CLAUSE,
			&"preparation",
			"整备",
			2,
			"失败抢救",
			[TALENT_CARRY_RIGGING],
			&"salvage_capacity",
			1,
			"失败结算可抢救重量上限 +1"
		),
		_talent(
			TALENT_SHOCK_TRAINING,
			&"safety",
			"安全",
			1,
			"绝缘训练",
			[],
			&"mine_damage_reduce",
			5,
			"每次雷险伤害减少 5 点"
		),
		_talent(
			TALENT_PRESSURE_READING,
			&"safety",
			"安全",
			2,
			"协议缓冲",
			[TALENT_SHOCK_TRAINING],
			&"protocol_pressure_reduce",
			2,
			"每次协议压力增量减少 2 点"
		),
		_talent(
			TALENT_SCAN_DISCIPLINE,
			&"exploration",
			"勘探",
			1,
			"扫描扩展",
			[],
			&"scan_hint",
			1,
			"扫描道具额外揭示 1 个对角格"
		),
		_talent(
			TALENT_TRADER_NOTES,
			&"exploration",
			"勘探",
			2,
			"搜索收益",
			[TALENT_SCAN_DISCIPLINE],
			&"search_reward",
			1,
			"每次搜索黑币收益 +1"
		),
	]


static func definition(talent_id: String) -> Dictionary:
	for raw_definition in definitions():
		if str(raw_definition.get("talent_id", "")) == talent_id:
			return raw_definition.duplicate(true)
	return {}


static func point_budget_for_level(profile_level: int) -> int:
	return maxi(0, profile_level - 1)


static func sync_progress(data: Dictionary, legacy_budget_missing: bool = false) -> Dictionary:
	var flags := _unique_strings(data.get("talent_flags", []))
	var points := maxi(0, int(data.get("talent_points", 0)))
	var target_budget := point_budget_for_level(maxi(1, int(data.get("profile_level", 1))))
	var spent_cost := _spent_cost(flags)
	var granted := maxi(0, int(data.get("talent_budget_granted", 0)))
	if legacy_budget_missing:
		var accounted_budget := spent_cost + points
		if accounted_budget < target_budget:
			points += target_budget - accounted_budget
		granted = maxi(target_budget, accounted_budget)
	elif target_budget > granted:
		points += target_budget - granted
		granted = target_budget
	else:
		granted = maxi(granted, spent_cost + points)
	data["talent_flags"] = flags
	data["talent_points"] = points
	data["talent_budget_granted"] = granted
	data["talent_catalog_version"] = CATALOG_VERSION
	return data


static func projection(meta: Dictionary) -> Array[Dictionary]:
	var normalized := meta.duplicate(true)
	sync_progress(normalized, not normalized.has("talent_budget_granted"))
	var flags := _unique_strings(normalized.get("talent_flags", []))
	var points := maxi(0, int(normalized.get("talent_points", 0)))
	var result: Array[Dictionary] = []
	for raw_definition in definitions():
		var node := raw_definition.duplicate(true)
		var talent_id := str(node.get("talent_id", ""))
		var unlocked := flags.has(talent_id)
		var missing_prerequisites: Array[String] = []
		for raw_prerequisite in node.get("prerequisite_ids", []) as Array:
			var prerequisite_id := str(raw_prerequisite)
			if not flags.has(prerequisite_id):
				missing_prerequisites.append(prerequisite_id)
		var cost := maxi(1, int(node.get("cost", TALENT_COST)))
		var reason_code := &"available"
		var reason := "可消耗 %d 点解锁" % cost
		var available := true
		if unlocked:
			available = false
			reason_code = &"already_unlocked"
			reason = "已解锁并将在新一局生效"
		elif not missing_prerequisites.is_empty():
			available = false
			reason_code = &"prerequisite_missing"
			reason = "需先解锁：%s" % _talent_names(missing_prerequisites)
		elif points < cost:
			available = false
			reason_code = &"insufficient_talent_points"
			reason = "天赋点不足：需要 %d，当前 %d" % [cost, points]
		node["unlocked"] = unlocked
		node["available"] = available
		node["reason_code"] = reason_code
		node["reason"] = reason
		node["missing_prerequisite_ids"] = missing_prerequisites
		node["current_talent_points"] = points
		node["state"] = &"unlocked" if unlocked else (&"available" if available else &"blocked")
		result.append(node)
	return result


static func active_effects(meta: Dictionary) -> Array[Dictionary]:
	var flags := _unique_strings(meta.get("talent_flags", []))
	var result: Array[Dictionary] = []
	for raw_definition in definitions():
		var talent_id := str(raw_definition.get("talent_id", ""))
		if not flags.has(talent_id):
			continue
		result.append({
			"talent_id": talent_id,
			"branch_id": StringName(raw_definition.get("branch_id", &"")),
			"branch_label": str(raw_definition.get("branch_label", "")),
			"display_name": str(raw_definition.get("display_name", talent_id)),
			"effect_kind": StringName(raw_definition.get("effect_kind", &"")),
			"effect_amount": int(raw_definition.get("effect_amount", 0)),
			"effect_label": str(raw_definition.get("effect_label", "")),
		})
	return result


static func summary(meta: Dictionary) -> Dictionary:
	var normalized := meta.duplicate(true)
	sync_progress(normalized, not normalized.has("talent_budget_granted"))
	var flags := _unique_strings(normalized.get("talent_flags", []))
	var known_unlocked := 0
	for raw_definition in definitions():
		if flags.has(str(raw_definition.get("talent_id", ""))):
			known_unlocked += 1
	var available_count := 0
	for node in projection(normalized):
		if bool(node.get("available", false)):
			available_count += 1
	return {
		"catalog_version": CATALOG_VERSION,
		"profile_level": maxi(1, int(normalized.get("profile_level", 1))),
		"budget_total": point_budget_for_level(maxi(1, int(normalized.get("profile_level", 1)))),
		"budget_granted": maxi(0, int(normalized.get("talent_budget_granted", 0))),
		"points_available": maxi(0, int(normalized.get("talent_points", 0))),
		"known_unlocked_count": known_unlocked,
		"available_count": available_count,
		"node_count": definitions().size(),
		"branch_count": 3,
	}


static func unlock_evaluation(meta: Dictionary, talent_id: String) -> Dictionary:
	var node := definition(talent_id)
	if node.is_empty():
		return {"ok": false, "status": &"unknown_talent", "talent_id": talent_id}
	for projected in projection(meta):
		if str(projected.get("talent_id", "")) != talent_id:
			continue
		if bool(projected.get("unlocked", false)):
			return {
				"ok": true,
				"status": &"talent_already_unlocked",
				"talent_id": talent_id,
				"duplicate": true,
			}
		if not bool(projected.get("available", false)):
			return {
				"ok": false,
				"status": StringName(projected.get("reason_code", &"talent_blocked")),
				"talent_id": talent_id,
				"reason": str(projected.get("reason", "")),
				"missing_prerequisite_ids": (projected.get("missing_prerequisite_ids", []) as Array).duplicate(),
				"cost": int(projected.get("cost", TALENT_COST)),
			}
		return {
			"ok": true,
			"status": &"available",
			"talent_id": talent_id,
			"cost": int(projected.get("cost", TALENT_COST)),
		}
	return {"ok": false, "status": &"unknown_talent", "talent_id": talent_id}


static func _talent(
	talent_id: String,
	branch_id: StringName,
	branch_label: String,
	tier: int,
	display_name: String,
	prerequisite_ids: Array,
	effect_kind: StringName,
	effect_amount: int,
	effect_label: String
) -> Dictionary:
	return {
		"catalog_version": CATALOG_VERSION,
		"talent_id": talent_id,
		"id": talent_id,
		"branch_id": branch_id,
		"branch_label": branch_label,
		"tier": tier,
		"display_name": display_name,
		"prerequisite_ids": prerequisite_ids.duplicate(),
		"cost": TALENT_COST,
		"effect_kind": effect_kind,
		"effect_amount": effect_amount,
		"effect_label": effect_label,
		"runtime_scope": &"new_run_start_config",
	}


static func _spent_cost(flags: Array[String]) -> int:
	var total := 0
	for raw_definition in definitions():
		if flags.has(str(raw_definition.get("talent_id", ""))):
			total += maxi(1, int(raw_definition.get("cost", TALENT_COST)))
	return total


static func _talent_names(talent_ids: Array[String]) -> String:
	var names := PackedStringArray()
	for talent_id in talent_ids:
		var source := definition(talent_id)
		names.append(str(source.get("display_name", talent_id)))
	return "、".join(names)


static func _unique_strings(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is not Array:
		return result
	for raw_value in value as Array:
		if not (raw_value is String or raw_value is StringName):
			continue
		var text := str(raw_value).strip_edges()
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result
