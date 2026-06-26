extends RefCounted
class_name SaveImportStaging

const SaveProfileManifestScript := preload("res://scripts/core/save/save_profile_manifest.gd")


static func default_stage(profile_id: String = SaveProfileManifestScript.DEFAULT_PROFILE_ID) -> Dictionary:
	var clean_id := SaveProfileManifestScript.sanitize_profile_id(profile_id)
	return {
		"stage_id": "import_stage_%s" % clean_id,
		"profile_id": clean_id,
		"paths": SaveProfileManifestScript.profile_paths(clean_id),
		"state": "staged_preview",
		"requires_user_confirm": true,
		"writes_profile": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func build_import_stage(profile_id: String, source_path: String, manifest: Dictionary = {}) -> Dictionary:
	var stage := default_stage(profile_id)
	stage["source_path"] = source_path
	stage["manifest_preview"] = manifest.duplicate(true)
	stage["operation"] = "import_profile"
	stage["blocked_mid_run"] = true
	return stage


static func build_export_stage(profile_id: String, target_path: String, manifest: Dictionary = {}) -> Dictionary:
	var stage := default_stage(profile_id)
	stage["target_path"] = target_path
	stage["manifest_preview"] = manifest.duplicate(true)
	stage["operation"] = "export_profile"
	stage["blocked_mid_run"] = true
	return stage


static func blocked_mid_run_result(operation: String) -> Dictionary:
	return {
		"ok": false,
		"status": "blocked",
		"reason": "profile_switch_or_import_blocked_mid_run",
		"operation": operation,
		"writes_profile": false,
		"read_only": true,
		"display_only": true,
		"preview": false,
	}
