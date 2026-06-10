extends RefCounted
class_name SaveAdapter

# G8.1 persistence boundary placeholder.
# This adapter only defines snapshot contracts; it does not read or write storage.


func build_run_save_snapshot(context: RunContext) -> Dictionary:
	if context == null:
		return {}
	return {
		"adapter_id": &"save_adapter_g8_1",
		"schema_version": 1,
		"run_id": context.run_id,
		"seed": context.seed_value,
		"mode": context.mode,
		"status_snapshot": context.get_status_snapshot(),
	}


func can_write_persistence() -> bool:
	return false


func describe_boundary() -> Dictionary:
	return {
		"adapter_id": &"save_adapter_g8_1",
		"writes_storage": false,
		"scope": &"contract_only",
	}
