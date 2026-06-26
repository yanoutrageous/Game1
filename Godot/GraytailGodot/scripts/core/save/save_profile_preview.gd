extends RefCounted
class_name SaveProfilePreview

const SaveProfileManifestScript := preload("res://scripts/core/save/save_profile_manifest.gd")


static func build_profile_preview(profile_id: String, manifest: Dictionary = {}) -> Dictionary:
	var normalized := SaveProfileManifestScript.normalize_manifest(manifest)
	var profiles: Dictionary = normalized.get("profiles", {})
	var clean_id := SaveProfileManifestScript.sanitize_profile_id(profile_id)
	var entry: Dictionary = profiles.get(clean_id, SaveProfileManifestScript.default_profile_entry(clean_id))
	return {
		"profile_id": clean_id,
		"display_name": str(entry.get("display_name", clean_id)),
		"state": str(entry.get("state", "available")),
		"paths": SaveProfileManifestScript.profile_paths(clean_id),
		"active": clean_id == str(normalized.get("active_profile_id", SaveProfileManifestScript.DEFAULT_PROFILE_ID)),
		"import_export_ready": true,
		"switch_requires_no_active_run": true,
		"read_only": bool(normalized.get("read_only", false)),
		"display_only": false,
		"preview": true,
	}


static func build_manifest_preview(manifest: Dictionary = {}) -> Dictionary:
	var normalized := SaveProfileManifestScript.normalize_manifest(manifest)
	var previews: Array[Dictionary] = []
	var profiles: Dictionary = normalized.get("profiles", {})
	for key in profiles.keys():
		previews.append(build_profile_preview(str(key), normalized))
	return {
		"schema_version": int(normalized.get("schema_version", 1)),
		"active_profile_id": str(normalized.get("active_profile_id", SaveProfileManifestScript.DEFAULT_PROFILE_ID)),
		"profiles": previews,
		"manifest_path": SaveProfileManifestScript.MANIFEST_PATH,
		"read_only": bool(normalized.get("read_only", false)),
		"display_only": true,
		"preview": true,
	}
