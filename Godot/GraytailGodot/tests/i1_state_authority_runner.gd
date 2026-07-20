extends SceneTree

const RunContextScript := preload("res://scripts/core/run/run_context.gd")
const RunStateMachineScript := preload("res://scripts/core/run/run_state_machine.gd")

const PASS_MARKER := "I1_STATE_AUTHORITY=PASS"
const FAIL_MARKER := "I1_STATE_AUTHORITY=FAIL"
const STATE_MACHINE_PATH := "res://scripts/core/run/run_state_machine.gd"

var failures: Array[String] = []


func _init() -> void:
	_test_legal_lifecycle_paths()
	_test_illegal_transition_rejected()
	_test_context_compatibility_routes_through_authority()
	_test_no_phase_write_bypass()
	_finish()


func _test_legal_lifecycle_paths() -> void:
	var state_machine := RunStateMachineScript.new()
	var extraction_context := RunContextScript.new()
	var start_result: Dictionary = state_machine.start_tutorial_run(extraction_context)
	_require(bool(start_result.get("ok", false)), "tutorial start was rejected")
	_require_equal(extraction_context.phase, &"running", "start phase")
	var original_run_id: StringName = extraction_context.run_id
	var active_start: Dictionary = state_machine.start_demo_run(extraction_context)
	_require(not bool(active_start.get("ok", true)), "active run was overwritten by start")
	_require_equal(StringName(active_start.get("status", &"")), &"active_run_exists", "active start status")
	_require_equal(extraction_context.run_id, original_run_id, "active start run identity")

	var request_result: Dictionary = state_machine.request_extract(extraction_context, true, "i1_request", &"player")
	_require(bool(request_result.get("ok", false)), "extraction request was rejected")
	_require_equal(extraction_context.phase, &"confirm_extract", "request phase")
	var cancel_result: Dictionary = state_machine.cancel_extract(extraction_context)
	_require(bool(cancel_result.get("ok", false)), "extraction cancel was rejected")
	_require_equal(extraction_context.phase, &"running", "cancel phase")

	state_machine.request_extract(extraction_context, true, "i1_confirm", &"player")
	var extract_result: Dictionary = state_machine.confirm_extract(extraction_context, true)
	_require(bool(extract_result.get("ok", false)), "extraction confirmation was rejected")
	_require_equal(extraction_context.phase, &"extracted", "extracted phase")
	_require(extraction_context.extracted and not extraction_context.run_active, "extracted flags")
	var extracted_state: Dictionary = extraction_context.result_snapshot.get("RunState", {})
	_require_equal(StringName(extracted_state.get("phase", &"")), &"extracted", "extracted result snapshot phase")

	var failure_context := RunContextScript.new()
	state_machine.start_tutorial_run(failure_context)
	var failure_result: Dictionary = state_machine.fail_run(failure_context, "i1_state_authority")
	_require(bool(failure_result.get("ok", false)), "failure transition was rejected")
	_require_equal(failure_context.phase, &"failure_salvage", "failure salvage phase")
	var salvage_result: Dictionary = state_machine.confirm_failure_salvage(failure_context, [])
	_require(bool(salvage_result.get("ok", false)), "failure salvage confirmation was rejected")
	_require_equal(StringName(salvage_result.get("transition", &"")), &"confirm_failure_salvage", "failure salvage transition marker")
	_require_equal(failure_context.phase, &"failed", "failed phase")
	var failed_state: Dictionary = failure_context.result_snapshot.get("RunState", {})
	_require_equal(StringName(failed_state.get("phase", &"")), &"failed", "failed result snapshot phase")


func _test_illegal_transition_rejected() -> void:
	var state_machine := RunStateMachineScript.new()
	var context := RunContextScript.new()
	state_machine.start_tutorial_run(context)
	var no_request_result: Dictionary = state_machine.confirm_extract(context, true)
	_require(not bool(no_request_result.get("ok", true)), "confirm without request unexpectedly succeeded")
	_require_equal(StringName(no_request_result.get("status", &"")), &"no_extract_request", "confirm without request status")
	_require_equal(context.phase, &"running", "confirm without request phase")

	state_machine.request_extract(context, true)
	state_machine.confirm_extract(context, true)
	var terminal_outcome := context.outcome
	var terminal_result_id := String(context.result_snapshot.get("result_id", ""))
	var invalid_failure: Dictionary = state_machine.fail_run(context, "must_not_overwrite_terminal")
	_require(not bool(invalid_failure.get("ok", true)), "terminal-to-failure transition unexpectedly succeeded")
	_require_equal(StringName(invalid_failure.get("status", &"")), &"invalid_phase_transition", "terminal transition status")
	_require_equal(String(invalid_failure.get("transition_authority", "")), "RunStateMachine", "illegal transition authority")
	_require_equal(context.phase, &"extracted", "terminal phase after rejected failure")
	_require_equal(context.outcome, terminal_outcome, "terminal outcome after rejected failure")
	_require_equal(String(context.result_snapshot.get("result_id", "")), terminal_result_id, "terminal result after rejected failure")


func _test_context_compatibility_routes_through_authority() -> void:
	var context := RunContextScript.new()
	context.start_tutorial_run()
	_require_equal(context.phase, &"running", "RunContext compatibility start phase")
	context.reset()
	_require_equal(context.phase, &"idle", "RunContext compatibility reset phase")
	_require(not context.run_started and not context.run_active, "RunContext compatibility reset flags")


func _test_no_phase_write_bypass() -> void:
	var phase_write_regex := RegEx.new()
	var regex_error := phase_write_regex.compile("(?:[A-Za-z_][A-Za-z0-9_]*\\.)?phase\\s*=(?!=)")
	_require_equal(regex_error, OK, "phase write regex compile")
	if regex_error != OK:
		return
	var write_locations: Array[String] = []
	_collect_phase_writes("res://scripts", phase_write_regex, write_locations)
	_require(not write_locations.is_empty(), "phase authority has no discoverable write")
	for location in write_locations:
		_require(location.begins_with("%s:" % STATE_MACHINE_PATH), "phase write bypass: %s" % location)


func _collect_phase_writes(directory_path: String, phase_write_regex: RegEx, write_locations: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	_require(directory != null, "cannot scan %s" % directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var entry_path := "%s/%s" % [directory_path, entry]
			if directory.current_is_dir():
				_collect_phase_writes(entry_path, phase_write_regex, write_locations)
			elif entry.ends_with(".gd"):
				var source := FileAccess.get_file_as_string(entry_path)
				var lines := source.split("\n")
				for index in range(lines.size()):
					if phase_write_regex.search(lines[index]) != null:
						write_locations.append("%s:%d" % [entry_path, index + 1])
		entry = directory.get_next()
	directory.list_dir_end()


func _require_equal(actual: Variant, expected: Variant, label: String) -> void:
	_require(actual == expected, "%s expected=%s actual=%s" % [label, str(expected), str(actual)])


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print(PASS_MARKER)
		print("I1_STATE_AUTHORITY_DETAILS legal=start_request_cancel_extract_failure illegal=terminal_overwrite bypass=none authority=RunStateMachine")
		quit(0)
		return
	for failure in failures:
		print("I1_STATE_AUTHORITY_FAILURE %s" % failure)
	print(FAIL_MARKER)
	quit(1)
