extends RefCounted
class_name RunSceneResultController

const RunSceneMetaCommitterScript := preload("res://scripts/core/run/run_scene_meta_committer.gd")


static func meta_summary(adapter: MetaProgressAdapter) -> Dictionary:
	return RunSceneMetaCommitterScript.summary(adapter)


static func build_result_display_snapshot(adapter: MetaProgressAdapter, result_snapshot: Dictionary) -> Dictionary:
	var display_snapshot := result_snapshot.duplicate(true)
	display_snapshot["meta_progress_commit"] = RunSceneMetaCommitterScript.commit_result(adapter, result_snapshot)
	display_snapshot["meta_progress_summary"] = RunSceneMetaCommitterScript.summary(adapter)
	display_snapshot["commit_authority"] = "RunSceneResultController"
	display_snapshot["read_only_result_source"] = "result_snapshot"
	return display_snapshot
