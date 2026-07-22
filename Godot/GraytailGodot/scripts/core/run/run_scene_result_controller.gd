extends RefCounted
class_name RunSceneResultController

static func build_result_display_snapshot(result_snapshot: Dictionary, meta_progress_summary: Dictionary = {}, meta_progress_commit: Dictionary = {}) -> Dictionary:
	var display_snapshot := result_snapshot.duplicate(true)
	var settlement: Dictionary = result_snapshot.get("settlement", {})
	var awaiting_salvage := bool(settlement.get("requires_salvage_selection", false)) and not bool(settlement.get("finalized", false))
	if awaiting_salvage:
		display_snapshot["meta_progress_commit"] = {"ok": false, "status": &"awaiting_salvage_confirmation", "committed": false}
	else:
		display_snapshot["meta_progress_commit"] = meta_progress_commit.duplicate(true)
	var persistence_state := _persistence_state(awaiting_salvage, display_snapshot.get("meta_progress_commit", {}))
	var normal_exit_allowed := persistence_state in [&"committed", &"duplicate_ignored"]
	display_snapshot["persistence_state"] = persistence_state
	display_snapshot["normal_exit_allowed"] = normal_exit_allowed
	display_snapshot["retry_save_allowed"] = not awaiting_salvage and not normal_exit_allowed
	display_snapshot["discard_unsaved_allowed"] = not awaiting_salvage and not normal_exit_allowed
	display_snapshot["discard_unsaved_confirmation_count"] = 2
	display_snapshot["meta_progress_summary"] = meta_progress_summary.duplicate(true)
	display_snapshot["commit_authority"] = "RunRuntimeController"
	display_snapshot["read_only_result_source"] = "result_snapshot"
	return display_snapshot


static func _persistence_state(awaiting_salvage: bool, commit_variant: Variant) -> StringName:
	if awaiting_salvage:
		return &"awaiting_salvage_confirmation"
	var commit: Dictionary = commit_variant if commit_variant is Dictionary else {}
	var status := StringName(commit.get("status", &""))
	match status:
		&"committed", &"duplicate_ignored", &"save_failed", &"write_blocked", &"meta_progress_adapter_missing":
			return status
		&"awaiting_salvage_selection", &"awaiting_salvage_confirmation":
			return &"awaiting_salvage_confirmation"
		&"terminal_result_missing", &"terminal_result_not_finalized":
			return status
		_:
			return &"missing"
