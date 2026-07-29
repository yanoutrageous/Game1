extends RefCounted
class_name DebugSandboxSession

const DebugGateScript := preload("res://scripts/core/debug/debug_gate.gd")
const DebugScenarioCatalogScript := preload("res://scripts/core/debug/debug_scenario_catalog.gd")
const SaveProfileManifestScript := preload("res://scripts/core/save/save_profile_manifest.gd")

const PROFILE_ID := "dev_sandbox"
const DEFAULT_SCENARIO_ID := &"demo_7x7"
const DEFAULT_SEED := 1001

var active := false
var tainted := false
var previous_profile_id := SaveProfileManifestScript.DEFAULT_PROFILE_ID
var scenario_id: StringName = DEFAULT_SCENARIO_ID
var seed := DEFAULT_SEED
var mutation_count := 0
var production_hash_before := ""
var production_hash_after := ""


func begin(
	save_manager,
	meta_progress_adapter,
	active_run: bool = false,
	next_scenario_id: StringName = DEFAULT_SCENARIO_ID,
	next_seed: int = DEFAULT_SEED
) -> Dictionary:
	if not DebugGateScript.is_debug_tools_enabled():
		return _blocked(&"debug_tools_disabled")
	if active:
		return _blocked(&"debug_sandbox_session_already_active")
	if active_run:
		return _blocked(&"debug_sandbox_requires_main_menu")
	if save_manager == null or meta_progress_adapter == null:
		return _blocked(&"debug_sandbox_save_boundary_missing")

	previous_profile_id = str(save_manager.get("active_profile_id"))
	production_hash_before = profile_storage_hash(previous_profile_id)
	var switch_result: Dictionary = save_manager.call("switch_profile", PROFILE_ID, false)
	if not bool(switch_result.get("ok", false)):
		return switch_result
	var configure_result: Dictionary = save_manager.call(
		"configure_meta_adapter",
		meta_progress_adapter
	)
	if not bool(configure_result.get("ok", false)):
		save_manager.call("switch_profile", previous_profile_id, false)
		return configure_result

	# A test-room entry is a deterministic sandbox reset.  It never clears or
	# rewrites the previous production profile.
	meta_progress_adapter.call("clear")
	active = true
	tainted = false
	mutation_count = 0
	scenario_id = DebugScenarioCatalogScript.normalize_id(
		next_scenario_id if next_scenario_id != &"" else DEFAULT_SCENARIO_ID
	)
	seed = DebugScenarioCatalogScript.seed_for(scenario_id, next_seed)
	return {
		"ok": true,
		"status": &"debug_sandbox_started",
		"profile_id": PROFILE_ID,
		"previous_profile_id": previous_profile_id,
		"scenario_id": scenario_id,
		"seed": seed,
		"production_hash_before": production_hash_before,
		"manifest_persisted": false,
	}


func mark_tainted(command_name: StringName = &"", payload: Dictionary = {}) -> Dictionary:
	if not active:
		return _blocked(&"debug_sandbox_session_not_active")
	tainted = true
	mutation_count += 1
	return {
		"ok": true,
		"status": &"debug_sandbox_tainted",
		"command_name": command_name,
		"payload": payload.duplicate(true),
		"mutation_count": mutation_count,
	}


func refresh_taint(run_context, meta_progress_adapter) -> bool:
	if not active:
		return false
	var context_tainted := run_context != null and bool(run_context.get("debug_used"))
	var meta_tainted := false
	if meta_progress_adapter != null:
		var summary: Dictionary = meta_progress_adapter.call("get_summary")
		meta_tainted = bool(summary.get("debug_used", false))
	if context_tainted or meta_tainted:
		tainted = true
	return tainted


func end(save_manager, meta_progress_adapter, active_run: bool = false) -> Dictionary:
	if not active:
		return {
			"ok": true,
			"status": &"debug_sandbox_not_active",
			"production_unchanged": true,
		}
	if active_run:
		return _blocked(&"debug_sandbox_exit_blocked_mid_run")
	if save_manager == null or meta_progress_adapter == null:
		return _blocked(&"debug_sandbox_save_boundary_missing")

	var restored_profile_id := previous_profile_id
	var switch_result: Dictionary = save_manager.call(
		"switch_profile",
		restored_profile_id,
		false
	)
	if not bool(switch_result.get("ok", false)):
		return switch_result
	var configure_result: Dictionary = save_manager.call(
		"configure_meta_adapter",
		meta_progress_adapter
	)
	if not bool(configure_result.get("ok", false)):
		return configure_result
	production_hash_after = profile_storage_hash(restored_profile_id)
	var production_unchanged := production_hash_before == production_hash_after
	var result := {
		"ok": production_unchanged,
		"status": (
			&"debug_sandbox_closed"
			if production_unchanged
			else &"production_profile_changed_during_debug"
		),
		"profile_id": restored_profile_id,
		"sandbox_profile_id": PROFILE_ID,
		"tainted": tainted,
		"mutation_count": mutation_count,
		"production_hash_before": production_hash_before,
		"production_hash_after": production_hash_after,
		"production_unchanged": production_unchanged,
	}
	active = false
	tainted = false
	mutation_count = 0
	return result


func snapshot() -> Dictionary:
	return {
		"active": active,
		"tainted": tainted,
		"profile_id": PROFILE_ID if active else previous_profile_id,
		"previous_profile_id": previous_profile_id,
		"scenario_id": scenario_id,
		"seed": seed,
		"mutation_count": mutation_count,
		"save_target": SaveProfileManifestScript.profile_paths(
			PROFILE_ID if active else previous_profile_id
		).get("meta_progress", ""),
		"production_hash_before": production_hash_before,
		"production_hash_after": production_hash_after,
	}


static func profile_storage_hash(profile_id: String) -> String:
	var path := str(
		SaveProfileManifestScript.profile_paths(profile_id).get("meta_progress", "")
	)
	if path.is_empty() or not FileAccess.file_exists(path):
		return "MISSING"
	var bytes := FileAccess.get_file_as_bytes(path)
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	return hashing.finish().hex_encode()


func _blocked(reason: StringName) -> Dictionary:
	return {
		"ok": false,
		"status": &"blocked",
		"reason": reason,
	}
