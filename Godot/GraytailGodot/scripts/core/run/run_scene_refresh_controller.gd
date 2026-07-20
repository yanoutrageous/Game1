extends RefCounted
class_name RunSceneRefreshController

const SCOPE_FULL := &"full"
const SCOPE_COMBAT := &"combat"

var _run_context: Variant
var _in_run_runtime: Variant
var _run_surface: Variant
var _hud: Variant
var _hud_view_model_builder: Callable
var _dev_diagnostics_panel: Variant
var _debug_log: Variant
var _shell_snapshot_provider: Callable
var _dev_diagnostics_apply: Callable
var _metrics: Dictionary = {}


func _init() -> void:
	reset_metrics()


func bind_targets(
	run_context: Variant,
	in_run_runtime: Variant,
	run_surface: Variant,
	hud: Variant,
	hud_view_model_builder: Callable,
	dev_diagnostics_panel: Variant,
	debug_log: Variant,
	shell_snapshot_provider: Callable,
	dev_diagnostics_apply: Callable
) -> void:
	_run_context = run_context
	_in_run_runtime = in_run_runtime
	_run_surface = run_surface
	_hud = hud
	_hud_view_model_builder = hud_view_model_builder
	_dev_diagnostics_panel = dev_diagnostics_panel
	_debug_log = debug_log
	_shell_snapshot_provider = shell_snapshot_provider
	_dev_diagnostics_apply = dev_diagnostics_apply


func route_state_change(status_snapshot: Dictionary, full_refresh: Callable) -> void:
	if StringName(status_snapshot.get("_change_scope", &"all")) == SCOPE_COMBAT:
		_apply_combat_refresh(status_snapshot)
		return
	run_full_refresh(full_refresh)


func run_full_refresh(full_refresh: Callable) -> void:
	if not full_refresh.is_valid():
		return
	var started_usec := Time.get_ticks_usec()
	full_refresh.call()
	_record_metric(SCOPE_FULL, Time.get_ticks_usec() - started_usec)


func get_metrics() -> Dictionary:
	return _metrics.duplicate(true)


func reset_metrics() -> void:
	_metrics = {
		"full_count": 0,
		"combat_count": 0,
		"full_total_usec": 0,
		"combat_total_usec": 0,
		"full_max_usec": 0,
		"combat_max_usec": 0,
		"last_scope": &"none",
	}


func describe_authority() -> Dictionary:
	return {
		"owner": &"RunSceneRefreshController",
		"routes_display_refresh_scope": true,
		"owns_refresh_metrics": true,
		"full_layout_refresh_owner": &"RunScene",
		"mutates_game_state": false,
	}


func _apply_combat_refresh(status_snapshot: Dictionary) -> void:
	if _run_context == null:
		return
	var started_usec := Time.get_ticks_usec()
	var snapshot := status_snapshot.duplicate(true)
	snapshot.erase("_change_scope")
	if _in_run_runtime != null and _in_run_runtime.has_method("build_read_only_snapshot"):
		snapshot["combat_runtime"] = _in_run_runtime.call("build_read_only_snapshot")
	if _is_visible_target(_run_surface) and _run_surface.has_method("apply_combat_snapshot"):
		_run_surface.call("apply_combat_snapshot", snapshot)
	if _is_visible_target(_hud) and _hud.has_method("apply_view_model") and _hud_view_model_builder.is_valid():
		_hud.call("apply_view_model", _hud_view_model_builder.call(snapshot))
	if _is_visible_target(_dev_diagnostics_panel) and _shell_snapshot_provider.is_valid() and _dev_diagnostics_apply.is_valid():
		_dev_diagnostics_apply.call(_shell_snapshot_provider.call())
	if _is_visible_target(_debug_log):
		_debug_log.set("text", String(snapshot.get("last_message", "")))
	_record_metric(SCOPE_COMBAT, Time.get_ticks_usec() - started_usec)


func _record_metric(scope: StringName, elapsed_usec: int) -> void:
	var prefix := "combat" if scope == SCOPE_COMBAT else "full"
	var count_key := "%s_count" % prefix
	var total_key := "%s_total_usec" % prefix
	var max_key := "%s_max_usec" % prefix
	_metrics[count_key] = int(_metrics.get(count_key, 0)) + 1
	_metrics[total_key] = int(_metrics.get(total_key, 0)) + maxi(0, elapsed_usec)
	_metrics[max_key] = maxi(int(_metrics.get(max_key, 0)), elapsed_usec)
	_metrics["last_scope"] = scope


static func _is_visible_target(target: Variant) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target is CanvasItem:
		return (target as CanvasItem).is_visible_in_tree()
	return true
