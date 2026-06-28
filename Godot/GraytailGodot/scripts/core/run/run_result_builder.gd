extends RefCounted
class_name RunResultBuilder

# M2 settlement input boundary.
# Result UI and MetaProgress read this snapshot; they must not recalculate rewards.

const SCHEMA_VERSION := 1


static func build(context: RunContext, ledger_snapshot: Dictionary = {}, run_map_snapshot: Dictionary = {}, map_result: Dictionary = {}, run_flow_snapshot: Dictionary = {}) -> Dictionary:
	if context == null:
		return default_result()
	var terminal := bool(context.extracted or context.failed or context.abandoned or not context.run_active)
	var settlement: Dictionary = context.settlement_result.duplicate(true)
	var carried_items: Array = _array(ledger_snapshot.get("inventory_items", []))
	var room_floor_items: Array = _array(ledger_snapshot.get("room_floor_items", []))
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"RunResult",
		"result_id": "%s:%s:%s" % [String(context.run_id), context.outcome, context.turn],
		"run_id": context.run_id,
		"mode": context.mode,
		"outcome": context.outcome,
		"settlement_outcome": settlement.get("outcome", ""),
		"extracted": context.extracted,
		"failed": context.failed,
		"abandoned": context.abandoned,
		"terminal": terminal,
		"authoritative_when_terminal": terminal,
		"settlement_single_input": terminal,
		"settlement_reads_run_result_only": true,
		"position": context.player_pos,
		"hp": context.hp,
		"max_hp": context.max_hp,
		"pressure": context.pressure,
		"protocol_level": context.protocol_level,
		"pending_gold": context.pending_gold,
		"safe_gold": context.safe_gold,
		"black_coin": ledger_snapshot.get("black_coin", context.pending_gold),
		"gold_coin": ledger_snapshot.get("gold_coin", context.safe_gold),
		"run_black_coin": ledger_snapshot.get("run_black_coin", context.pending_gold),
		"safe_yield": ledger_snapshot.get("safe_yield", context.safe_gold),
		"long_term_gold": ledger_snapshot.get("long_term_gold", 0),
		"long_term_gold_gained": settlement.get("long_term_gold_gained", 0),
		"safe_yield_retained": settlement.get("safe_yield_retained", settlement.get("safe_yield", 0)),
		"backpack_capacity": ledger_snapshot.get("backpack_capacity", 0),
		"backpack_used": ledger_snapshot.get("backpack_used", carried_items.size()),
		"carried_items": carried_items,
		"room_floor_items": room_floor_items,
		"warehouse_lite": _array(ledger_snapshot.get("warehouse_lite", [])),
		"settlement": settlement,
		"map_result": map_result.duplicate(true),
		"run_map_snapshot_ref": &"RunMapSnapshot" if not run_map_snapshot.is_empty() else &"unavailable",
		"run_flow_snapshot_ref": &"RunFlowSnapshot" if not run_flow_snapshot.is_empty() else &"unavailable",
		"run_stats": context.run_stats.duplicate(true),
		"debug_used": context.debug_used,
		"debug_commands": context.debug_commands.duplicate(true),
		"failure_salvage": context.failure_salvage.duplicate(true),
		"settlement_source": &"RunAssetLedger.settle_success_or_failure",
		"ui_recalculation_allowed": false,
		"meta_progress_input": true,
		"read_only": true,
		"display_only": false,
		"preview": false,
		"no_persistence": false,
	}


static func default_result() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"RunResult",
		"terminal": false,
		"settlement_single_input": false,
		"settlement_reads_run_result_only": true,
		"ui_recalculation_allowed": false,
		"read_only": true,
	}


static func _array(value: Variant) -> Array:
	if value is Array:
		return value.duplicate(true)
	return []
