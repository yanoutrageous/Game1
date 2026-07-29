extends RefCounted
class_name SaveProfileManifest

const ROOT_DIR := "user://saves"
const MANIFEST_PATH := "user://saves/manifest.json"
const PROFILES_DIR := "user://saves/profiles"
const DEFAULT_PROFILE_ID := "default"
const DEBUG_SANDBOX_PROFILE_ID := "dev_sandbox"
const PROFILE_SCHEMA_VERSION := 1


static func default_manifest() -> Dictionary:
	return {
		"schema_version": PROFILE_SCHEMA_VERSION,
		"active_profile_id": DEFAULT_PROFILE_ID,
		"profiles": {
			DEFAULT_PROFILE_ID: default_profile_entry(DEFAULT_PROFILE_ID),
		},
		"read_only": false,
		"display_only": false,
		"preview": false,
	}


static func default_profile_entry(profile_id: String = DEFAULT_PROFILE_ID) -> Dictionary:
	var clean_id := sanitize_profile_id(profile_id)
	return {
		"profile_id": clean_id,
		"display_name": "Default Profile" if clean_id == DEFAULT_PROFILE_ID else clean_id,
		"paths": profile_paths(clean_id),
		"state": "active" if clean_id == DEFAULT_PROFILE_ID else "available",
		"created_by": "save_profile_manifest",
	}


static func profile_paths(profile_id: String = DEFAULT_PROFILE_ID) -> Dictionary:
	var clean_id := sanitize_profile_id(profile_id)
	var profile_root := "%s/%s" % [PROFILES_DIR, clean_id]
	return {
		"profile_id": clean_id,
		"profile_root": profile_root,
		"meta_progress": "%s/meta_progress.json" % profile_root,
		"run_checkpoint": "%s/run_checkpoint.json" % profile_root,
		"preview": "%s/preview.json" % profile_root,
	}


static func default_meta_progress_path() -> String:
	return str(profile_paths(DEFAULT_PROFILE_ID).get("meta_progress", ""))


static func normalize_manifest(data: Dictionary) -> Dictionary:
	var result := default_manifest()
	result["schema_version"] = int(data.get("schema_version", PROFILE_SCHEMA_VERSION))
	var active_id := sanitize_profile_id(str(data.get("active_profile_id", DEFAULT_PROFILE_ID)))
	result["active_profile_id"] = active_id
	var profiles := {}
	var source_profiles: Dictionary = _dictionary_from(data.get("profiles", {}))
	for key in source_profiles.keys():
		var profile_id := sanitize_profile_id(str(key))
		if profile_id == "":
			continue
		profiles[profile_id] = normalize_profile_entry(profile_id, _dictionary_from(source_profiles[key]))
	if profiles.is_empty():
		profiles[DEFAULT_PROFILE_ID] = default_profile_entry(DEFAULT_PROFILE_ID)
	if not profiles.has(active_id):
		profiles[active_id] = default_profile_entry(active_id)
	result["profiles"] = profiles
	result["read_only"] = bool(data.get("read_only", false))
	result["display_only"] = bool(data.get("display_only", false))
	result["preview"] = bool(data.get("preview", false))
	return result


static func normalize_profile_entry(profile_id: String, data: Dictionary) -> Dictionary:
	var clean_id := sanitize_profile_id(profile_id)
	var result := default_profile_entry(clean_id)
	result["display_name"] = str(data.get("display_name", result.get("display_name", clean_id)))
	result["state"] = str(data.get("state", result.get("state", "available")))
	result["created_by"] = str(data.get("created_by", result.get("created_by", "save_profile_manifest")))
	result["paths"] = profile_paths(clean_id)
	return result


static func validate_manifest(data: Dictionary) -> Dictionary:
	var normalized := normalize_manifest(data)
	var issues: Array[String] = []
	if int(normalized.get("schema_version", 0)) > PROFILE_SCHEMA_VERSION:
		issues.append("future_manifest_schema")
	if str(normalized.get("active_profile_id", "")) == "":
		issues.append("missing_active_profile_id")
	if _dictionary_from(normalized.get("profiles", {})).is_empty():
		issues.append("missing_profiles")
	return {
		"ok": issues.is_empty(),
		"issues": issues,
		"manifest": normalized,
		"read_only": bool(normalized.get("read_only", false)),
		"display_only": bool(normalized.get("display_only", false)),
		"preview": bool(normalized.get("preview", false)),
	}


static func sanitize_profile_id(profile_id: String) -> String:
	var result := profile_id.strip_edges().to_lower()
	if result == "":
		result = DEFAULT_PROFILE_ID
	result = result.replace("\\", "_")
	result = result.replace("/", "_")
	result = result.replace(":", "_")
	result = result.replace("..", "_")
	return result


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
