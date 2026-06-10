extends RefCounted
class_name MetaProgressAdapter

# G8.1 meta progression boundary placeholder.
# It exposes adapter contracts only; full MetaProgress is a later stage.


func build_settlement_export(result_snapshot: Dictionary) -> Dictionary:
	return {
		"adapter_id": &"meta_progress_adapter_g8_1",
		"schema_version": 1,
		"writes_storage": false,
		"settlement": result_snapshot.get("settlement", {}),
		"warehouse_lite": result_snapshot.get("warehouse_lite", []),
		"gold_coin": result_snapshot.get("gold_coin", 0),
		"black_coin": result_snapshot.get("black_coin", 0),
	}


func can_write_persistence() -> bool:
	return false


func describe_boundary() -> Dictionary:
	return {
		"adapter_id": &"meta_progress_adapter_g8_1",
		"writes_storage": false,
		"scope": &"contract_only",
	}
