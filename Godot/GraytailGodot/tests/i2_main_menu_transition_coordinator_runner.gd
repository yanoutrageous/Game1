extends SceneTree

const CoordinatorScript := preload("res://scripts/ui/app_shell/navigation_transition_coordinator.gd")

const SOURCE_PAGE := &"main_menu"
const PROFILE_CASES := [
	[CoordinatorScript.PROFILE_ENTER_CAVE, &"deploy_prep", &"deploy"],
	[CoordinatorScript.PROFILE_DESCEND, &"long_term", &"long_term"],
	[CoordinatorScript.PROFILE_OPEN_OVERLAY, &"settings_placeholder", &"settings"],
	[CoordinatorScript.PROFILE_OPEN_CONFIRM, &"exit_confirm", &"exit_game"],
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	_expect_four_profiles_and_single_commit(failures)
	_expect_busy_request_does_not_replace_or_consume_token(failures)
	_expect_stale_callbacks_do_not_mutate_current(failures)
	_expect_cancel_recovers_source_and_focus(failures)
	_expect_prepare_failure_recovers_source_and_focus(failures)
	_expect_commit_failure_recovers_source_and_focus(failures)
	_expect_midflight_reduced_motion_is_profile_only(failures)
	if failures.is_empty():
		print("I2_MAIN_MENU_TRANSITION_COORDINATOR=PASS profiles=4 duplicate=rejected stale=ignored cancel=recovered prepare_fail=recovered commit_fail=recovered reduced_midflight=profile_only commit_once=true")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("I2_MAIN_MENU_TRANSITION_COORDINATOR=FAIL count=%d" % failures.size())
	quit(1)


func _expect_four_profiles_and_single_commit(failures: Array[String]) -> void:
	var coordinator = CoordinatorScript.new()
	var previous_token := 0
	_expect(CoordinatorScript.profile_ids().size() == 4, "coordinator must expose exactly four main-menu profiles", failures)
	for raw_case in PROFILE_CASES:
		var profile_id := StringName(raw_case[0])
		var target_page := StringName(raw_case[1])
		var focus_id := StringName(raw_case[2])
		var requested: Dictionary = coordinator.request_transition(
			SOURCE_PAGE,
			target_page,
			profile_id,
			focus_id,
			false,
			{"intent_id": focus_id}
		)
		var token := int(requested.get("token", 0))
		_expect(bool(requested.get("ok", false)), "profile %s request must be accepted" % profile_id, failures)
		_expect(token > previous_token, "transition tokens must increase monotonically", failures)
		_expect(StringName(coordinator.snapshot().get("state", &"")) == CoordinatorScript.STATE_PREPARING, "profile %s must enter PREPARING" % profile_id, failures)
		_expect(StringName(coordinator.snapshot().get("profile_id", &"")) == profile_id, "profile %s must remain semantic data" % profile_id, failures)
		_expect(bool(coordinator.mark_prepared(token).get("ok", false)), "profile %s prepare callback must be accepted" % profile_id, failures)
		_expect(StringName(coordinator.snapshot().get("state", &"")) == CoordinatorScript.STATE_PLAYING, "profile %s must enter PLAYING" % profile_id, failures)
		_expect(bool(coordinator.mark_playback_finished(token).get("ok", false)), "profile %s playback callback must be accepted" % profile_id, failures)
		_expect(StringName(coordinator.snapshot().get("state", &"")) == CoordinatorScript.STATE_COMMITTING, "profile %s must enter COMMITTING" % profile_id, failures)
		var first_commit: Dictionary = coordinator.take_commit(token)
		var repeated_commit: Dictionary = coordinator.take_commit(token)
		_expect(bool(first_commit.get("ok", false)), "profile %s must expose one commit request" % profile_id, failures)
		_expect(StringName((first_commit.get("commit_request", {}) as Dictionary).get("target_page", &"")) == target_page, "profile %s commit must preserve target" % profile_id, failures)
		_expect(not bool(repeated_commit.get("ok", true)) and StringName(repeated_commit.get("reason_code", &"")) == &"commit_already_issued", "profile %s must reject a second commit" % profile_id, failures)
		var resolved: Dictionary = coordinator.resolve_commit(token, true)
		var last_result: Dictionary = resolved.get("last_result", {})
		_expect(bool(resolved.get("ok", false)) and StringName(resolved.get("outcome", &"")) == CoordinatorScript.OUTCOME_COMMITTED, "profile %s commit must resolve" % profile_id, failures)
		_expect(StringName(coordinator.snapshot().get("state", &"")) == CoordinatorScript.STATE_IDLE, "profile %s must return to IDLE" % profile_id, failures)
		_expect(StringName(coordinator.snapshot().get("current_page", &"")) == target_page, "profile %s must finish at its target" % profile_id, failures)
		_expect(int(last_result.get("commit_count", 0)) == 1, "profile %s token must commit exactly once" % profile_id, failures)
		previous_token = token


func _expect_busy_request_does_not_replace_or_consume_token(failures: Array[String]) -> void:
	var coordinator = CoordinatorScript.new()
	var first: Dictionary = coordinator.request_transition(SOURCE_PAGE, &"deploy_prep", CoordinatorScript.PROFILE_ENTER_CAVE, &"deploy")
	var first_token := int(first.get("token", 0))
	var before: Dictionary = coordinator.snapshot()
	var duplicate: Dictionary = coordinator.request_transition(SOURCE_PAGE, &"long_term", CoordinatorScript.PROFILE_DESCEND, &"long_term")
	_expect(not bool(duplicate.get("ok", true)) and StringName(duplicate.get("reason_code", &"")) == &"transition_busy", "busy request must be rejected", failures)
	_expect(coordinator.snapshot() == before, "busy request must not replace the active transition", failures)
	coordinator.cancel(first_token, &"test_cleanup")
	var next: Dictionary = coordinator.request_transition(SOURCE_PAGE, &"long_term", CoordinatorScript.PROFILE_DESCEND, &"long_term")
	_expect(int(next.get("token", 0)) == first_token + 1, "rejected busy request must not consume a token", failures)


func _expect_stale_callbacks_do_not_mutate_current(failures: Array[String]) -> void:
	var coordinator = CoordinatorScript.new()
	var old_request: Dictionary = coordinator.request_transition(SOURCE_PAGE, &"deploy_prep", CoordinatorScript.PROFILE_ENTER_CAVE, &"deploy")
	var old_token := int(old_request.get("token", 0))
	coordinator.cancel(old_token, &"superseded_test")
	var current_request: Dictionary = coordinator.request_transition(SOURCE_PAGE, &"long_term", CoordinatorScript.PROFILE_DESCEND, &"long_term")
	var current_token := int(current_request.get("token", 0))
	var before: Dictionary = coordinator.snapshot()
	var stale_results := [
		coordinator.mark_prepared(old_token),
		coordinator.mark_playback_finished(old_token),
		coordinator.set_reduced_motion(old_token, true),
		coordinator.cancel(old_token),
		coordinator.fail_transition(old_token, &"late_failure"),
		coordinator.resolve_commit(old_token, true),
	]
	for result in stale_results:
		_expect(not bool((result as Dictionary).get("ok", true)) and StringName((result as Dictionary).get("reason_code", &"")) == &"stale_transition_token", "stale callback must be rejected with a stable reason", failures)
	_expect(coordinator.snapshot() == before, "stale callbacks must not mutate the current transition", failures)
	_expect(coordinator.active_token() == current_token, "stale callbacks must preserve the current token", failures)


func _expect_cancel_recovers_source_and_focus(failures: Array[String]) -> void:
	var coordinator = CoordinatorScript.new()
	var requested: Dictionary = coordinator.request_transition(SOURCE_PAGE, &"deploy_prep", CoordinatorScript.PROFILE_ENTER_CAVE, &"deploy")
	var token := int(requested.get("token", 0))
	coordinator.mark_prepared(token)
	var cancelled: Dictionary = coordinator.cancel(token, &"player_cancelled")
	_expect_recovery(cancelled, CoordinatorScript.OUTCOME_CANCELLED, &"player_cancelled", &"deploy", "cancel", failures)


func _expect_prepare_failure_recovers_source_and_focus(failures: Array[String]) -> void:
	var coordinator = CoordinatorScript.new()
	var requested: Dictionary = coordinator.request_transition(SOURCE_PAGE, &"long_term", CoordinatorScript.PROFILE_DESCEND, &"long_term")
	var failed: Dictionary = coordinator.mark_prepared(int(requested.get("token", 0)), false, &"target_prepare_failed")
	_expect_recovery(failed, CoordinatorScript.OUTCOME_FAILED, &"target_prepare_failed", &"long_term", "prepare failure", failures)


func _expect_commit_failure_recovers_source_and_focus(failures: Array[String]) -> void:
	var coordinator = CoordinatorScript.new()
	var requested: Dictionary = coordinator.request_transition(SOURCE_PAGE, &"settings_placeholder", CoordinatorScript.PROFILE_OPEN_OVERLAY, &"settings")
	var token := int(requested.get("token", 0))
	coordinator.mark_prepared(token)
	coordinator.mark_playback_finished(token)
	coordinator.take_commit(token)
	var failed: Dictionary = coordinator.resolve_commit(token, false, &"route_commit_failed")
	_expect_recovery(failed, CoordinatorScript.OUTCOME_FAILED, &"route_commit_failed", &"settings", "commit failure", failures)
	var after_failure: Dictionary = coordinator.snapshot()
	var late_success: Dictionary = coordinator.resolve_commit(token, true)
	_expect(not bool(late_success.get("ok", true)), "late commit success must be stale after failure recovery", failures)
	_expect(coordinator.snapshot() == after_failure, "late commit success must not undo failure recovery", failures)


func _expect_midflight_reduced_motion_is_profile_only(failures: Array[String]) -> void:
	var coordinator = CoordinatorScript.new()
	var requested: Dictionary = coordinator.request_transition(SOURCE_PAGE, &"exit_confirm", CoordinatorScript.PROFILE_OPEN_CONFIRM, &"exit_game", false)
	var token := int(requested.get("token", 0))
	coordinator.mark_prepared(token)
	var changed: Dictionary = coordinator.set_reduced_motion(token, true)
	var after_change: Dictionary = coordinator.snapshot()
	_expect(bool(changed.get("ok", false)) and bool(changed.get("profile_changed", false)), "mid-flight reduced-motion update must be accepted", failures)
	_expect(StringName(after_change.get("state", &"")) == CoordinatorScript.STATE_PLAYING, "reduced-motion update must not advance PLAYING", failures)
	_expect(StringName(after_change.get("profile_id", &"")) == CoordinatorScript.PROFILE_OPEN_CONFIRM and bool(after_change.get("reduced_motion", false)), "reduced-motion update must only alter profile data", failures)
	_expect(not bool(after_change.get("commit_issued", true)) and int(after_change.get("commit_count", -1)) == 0, "reduced-motion update must not commit", failures)
	var early_commit: Dictionary = coordinator.take_commit(token)
	_expect(not bool(early_commit.get("ok", true)) and StringName(early_commit.get("reason_code", &"")) == &"invalid_transition_state", "reduced-motion must still wait for presenter completion", failures)
	coordinator.mark_playback_finished(token)
	var commit: Dictionary = coordinator.take_commit(token)
	_expect(bool(commit.get("ok", false)) and bool(((commit.get("commit_request", {}) as Dictionary).get("reduced_motion", false))), "presenter completion must preserve reduced-motion profile in commit data", failures)
	coordinator.resolve_commit(token, true)


func _expect_recovery(
	result: Dictionary,
	expected_outcome: StringName,
	expected_reason: StringName,
	expected_focus: StringName,
	context: String,
	failures: Array[String]
) -> void:
	var last_result: Dictionary = result.get("last_result", {})
	var recovery: Dictionary = last_result.get("recovery", {})
	_expect(bool(result.get("ok", false)), "%s callback must be accepted" % context, failures)
	_expect(StringName(last_result.get("outcome", &"")) == expected_outcome, "%s must preserve outcome" % context, failures)
	_expect(StringName(last_result.get("reason_code", &"")) == expected_reason, "%s must preserve reason" % context, failures)
	_expect(bool(recovery.get("available", false)), "%s must expose recovery" % context, failures)
	_expect(StringName(recovery.get("page", &"")) == SOURCE_PAGE, "%s must recover source page" % context, failures)
	_expect(StringName(recovery.get("focus_id", &"")) == expected_focus, "%s must recover source focus" % context, failures)
	_expect(StringName((result.get("snapshot", {}) as Dictionary).get("state", &"")) == CoordinatorScript.STATE_IDLE, "%s must return to IDLE" % context, failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
