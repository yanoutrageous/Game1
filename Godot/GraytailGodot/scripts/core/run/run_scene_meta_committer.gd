extends RefCounted
class_name RunSceneMetaCommitter


static func summary(adapter: MetaProgressAdapter) -> Dictionary:
	if adapter == null:
		return {}
	return adapter.get_summary()


static func commit_result(adapter: MetaProgressAdapter, result_snapshot: Dictionary) -> Dictionary:
	if adapter == null:
		return {"ok": false, "reason": "meta_progress_adapter_missing"}
	return adapter.apply_settlement(result_snapshot)


static func debug_add_gold(adapter: MetaProgressAdapter, amount: int, source: String) -> Dictionary:
	if adapter == null:
		return {}
	return adapter.add_gold(amount, source)


static func debug_set_gold(adapter: MetaProgressAdapter, amount: int, source: String) -> Dictionary:
	if adapter == null:
		return {}
	return adapter.set_gold(amount, source)


static func debug_clear_gold(adapter: MetaProgressAdapter) -> Dictionary:
	if adapter == null:
		return {}
	return adapter.clear_gold()


static func debug_add_warehouse_item(adapter: MetaProgressAdapter, item: Dictionary) -> Dictionary:
	if adapter == null:
		return {}
	return adapter.add_warehouse_item(item)


static func debug_clear_warehouse(adapter: MetaProgressAdapter, source: String) -> Dictionary:
	if adapter == null:
		return {}
	return adapter.clear_warehouse(source)


static func debug_mark_and_save(adapter: MetaProgressAdapter, command: String, payload: Dictionary) -> Dictionary:
	if adapter == null:
		return {"summary": {}, "saved": false}
	if not adapter.is_debug_sandbox_profile():
		return {"summary": _sandbox_required(adapter), "saved": false}
	var summary := adapter.mark_debug_command(command, payload)
	var saved := adapter.save()
	return {"summary": summary, "saved": saved}


static func debug_clear_save(adapter: MetaProgressAdapter, source: String) -> Dictionary:
	if adapter == null:
		return {}
	if not adapter.is_debug_sandbox_profile():
		return _sandbox_required(adapter)
	var summary := adapter.clear()
	if not bool(summary.get("write_blocked", false)):
		summary = adapter.mark_debug_command("meta_clear_save", {"source": source})
	return summary


static func debug_read_summary(adapter: MetaProgressAdapter, source: String) -> Dictionary:
	if adapter == null:
		return {}
	adapter.load_or_create_default()
	var summary := adapter.get_summary()
	summary["debug_read_source"] = source
	summary["read_only_diagnostic"] = true
	return summary


static func _sandbox_required(adapter: MetaProgressAdapter) -> Dictionary:
	var summary := adapter.get_summary()
	summary["write_blocked"] = true
	summary["write_block_reason"] = "debug_sandbox_profile_required"
	summary["required_profile_id"] = "dev_sandbox"
	return summary
