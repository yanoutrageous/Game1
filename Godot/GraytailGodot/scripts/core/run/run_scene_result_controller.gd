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
	display_snapshot["meta_progress_summary"] = meta_progress_summary.duplicate(true)
	display_snapshot["commit_authority"] = "RunRuntimeController"
	display_snapshot["read_only_result_source"] = "result_snapshot"
	return display_snapshot
