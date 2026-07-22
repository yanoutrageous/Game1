extends SceneTree

const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const DeployMapProjectionScript := preload("res://scripts/ui/deploy_prep/deploy_map_projection.gd")
const RunStartConfigScript := preload("res://scripts/core/run/run_start_config.gd")
const RunConfigScript := preload("res://scripts/core/run/run_config.gd")

const MAP_IDS := [
	"classic_7x7_simple",
	"classic_7x7_normal",
	"classic_10x10_easy",
	"classic_10x10_standard",
	"classic_10x10_hard",
	"classic_13x13_normal",
	"classic_13x13_hard",
	"classic_13x13_hell",
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_exact_catalog_and_projection()
	_test_run_start_and_route_round_trip()
	_test_fail_closed_selection()
	_test_map_legality()
	_finish()


func _test_exact_catalog_and_projection() -> void:
	_check(M7ContentCatalogScript.map_definitions().size() == 8, "catalog_count")
	for map_id in MAP_IDS:
		var definition := M7ContentCatalogScript.map_definition_exact(map_id)
		_check(not definition.is_empty(), "exact_missing:%s" % map_id)
		_check(str(definition.get("id", "")) == map_id, "exact_wrong_id:%s" % map_id)
	_check(M7ContentCatalogScript.map_definition_exact("classic_unknown").is_empty(), "unknown_exact_not_empty")
	_check(
		str(M7ContentCatalogScript.map_definition("classic_unknown").get("id", "")) == "classic_10x10_standard",
		"historical_fallback_changed"
	)
	var simple := M7ContentCatalogScript.map_definition_exact("classic_7x7_simple")
	var easy := M7ContentCatalogScript.map_definition_exact("classic_10x10_easy")
	_check(StringName(simple.get("difficulty", &"")) == &"simple", "simple_difficulty_changed")
	_check(StringName(easy.get("difficulty", &"")) == &"easy", "easy_difficulty_changed")
	_check(simple.get("difficulty") != easy.get("difficulty"), "simple_collapsed_into_easy")

	var catalog := DeployMapProjectionScript.project_catalog(MAP_IDS)
	_check(catalog.size() == 8, "projection_count")
	var projected_ids: Array[String] = []
	var page_ids := {}
	for projection in catalog:
		var projected_map_id := str(projection.get("map_config_id", ""))
		projected_ids.append(projected_map_id)
		page_ids[StringName(projection.get("page_id", &""))] = true
		_check(StringName(projection.get("tab_id", &"")) == &"map", "projection_left_map_tab")
		var exact_definition := M7ContentCatalogScript.map_definition_exact(projected_map_id)
		for field in ["visible_exit_count", "hidden_exit_count", "visible_exit_position_known", "success_exp"]:
			_check(projection.get(field) == exact_definition.get(field), "projection_field:%s:%s" % [projected_map_id, field])
	_check(projected_ids == MAP_IDS, "projection_id_order_or_content")
	_check(page_ids.keys() == [&"deploy_prep"], "projection_added_route_page")
	var groups := DeployMapProjectionScript.scale_groups(MAP_IDS)
	_check(groups.size() == 3, "scale_group_count")
	var expected_counts := [2, 3, 3]
	var expected_scales := [&"7x7", &"10x10", &"13x13"]
	for index in range(groups.size()):
		var group := groups[index]
		_check(StringName(group.get("scale_id", &"")) == expected_scales[index], "scale_order:%d" % index)
		_check(int(group.get("map_count", -1)) == expected_counts[index], "scale_count:%d" % index)

	var base := DeployConfigScript.default_config(1, {"unlocked_map_ids": MAP_IDS})
	var view := DeployMapProjectionScript.project(base)
	_check((view.get("scale_options", []) as Array).size() == 3, "view_scale_options")
	_check((view.get("difficulty_options", []) as Array).size() == 2, "view_selected_scale_difficulties")
	_check(StringName(view.get("fallback_policy", &"")) == &"fail_closed", "view_fallback_policy")


func _test_run_start_and_route_round_trip() -> void:
	var base := DeployConfigScript.default_config(2, {"unlocked_map_ids": MAP_IDS})
	for map_id in MAP_IDS:
		var selected := DeployConfigScript.select_map(base, map_id)
		_check(bool(selected.get("ok", false)), "selection_failed:%s" % map_id)
		var selected_config := selected.get("config", {}) as Dictionary
		var definition := M7ContentCatalogScript.map_definition_exact(map_id)
		_check(str(selected_config.get("map_config_id", "")) == map_id, "selection_id:%s" % map_id)
		_check(
			StringName(selected_config.get("difficulty", &"")) == StringName(definition.get("difficulty", &"")),
			"selection_difficulty:%s" % map_id
		)
		var validity := selected_config.get("config_validity_preview", {}) as Dictionary
		_check(bool(validity.get("can_start", false)), "selection_legality:%s" % map_id)
		_check(bool(validity.get("map_exact", false)), "selection_not_exact:%s" % map_id)
		_check(bool(validity.get("map_unlocked", false)), "selection_not_unlocked:%s" % map_id)
		_check(bool(validity.get("difficulty_matches", false)), "selection_difficulty_invalid:%s" % map_id)

		var run_start := DeployConfigScript.build_run_start_config(selected_config)
		_check(str(run_start.get("map_config_id", "")) == map_id, "run_start_id:%s" % map_id)
		for forbidden_key in ["family_id", "family_display_name", "scale_id", "scale_label", "selected_scale_id"]:
			_check(not run_start.has(forbidden_key), "run_start_view_field:%s:%s" % [map_id, forbidden_key])
		var route_payload := {
			"source_page": &"deploy_prep",
			"route_mode": &"standard_run",
			"run_start_config_preview": run_start,
		}
		var route_validation := RunStartConfigScript.validate(route_payload)
		_check(bool(route_validation.get("ok", false)), "route_validation:%s" % map_id)
		var normalized := route_validation.get("config", {}) as Dictionary
		_check(str(normalized.get("map_config_id", "")) == map_id, "route_normalize_id:%s" % map_id)
		_check(StringName(normalized.get("source_page", &"")) == &"deploy_prep", "route_source_page:%s" % map_id)
		var runtime := RunConfigScript.m7_map(normalized)
		_check(str(runtime.get("map_config_id", "")) == map_id, "runtime_route_id:%s" % map_id)
		_check(StringName(runtime.get("id", &"")) == StringName(map_id), "runtime_truth_id:%s" % map_id)
		_check(
			str((runtime.get("run_start_config", {}) as Dictionary).get("map_config_id", "")) == map_id,
			"runtime_nested_round_trip:%s" % map_id
		)

	var delegated := DeployConfigScript.apply_card_action(base, &"map", &"m7_map_classic_13x13_hell")
	_check(bool(delegated.get("ok", false)), "legacy_card_not_delegated")
	_check(str((delegated.get("config", {}) as Dictionary).get("map_config_id", "")) == "classic_13x13_hell", "legacy_card_wrong_map")


func _test_fail_closed_selection() -> void:
	var unlocked := DeployConfigScript.default_config(3, {"unlocked_map_ids": MAP_IDS})
	_assert_rejected_without_mutation(unlocked, "classic_unknown", &"unknown_map_id", "unknown")

	var locked := DeployConfigScript.default_config(4, {"unlocked_map_ids": ["classic_7x7_simple"]})
	_assert_rejected_without_mutation(locked, "classic_10x10_hard", &"map_locked", "locked")

	var active := DeployConfigScript.with_active_run_preview(unlocked, true)
	_assert_rejected_without_mutation(active, "classic_10x10_standard", &"active_run_locked", "active")

	var no_maps := DeployConfigScript.default_config(5, {"unlocked_map_ids": []})
	_assert_rejected_without_mutation(no_maps, "classic_7x7_simple", &"no_maps_available", "empty")
	var empty_view := DeployMapProjectionScript.project(no_maps)
	_check(not bool(empty_view.get("selection_unlocked", true)), "empty_projection_unlocked")
	for raw_group in empty_view.get("scale_options", []):
		var group := raw_group as Dictionary
		_check(int(group.get("unlocked_count", -1)) == 0, "empty_projection_group_unlock")


func _test_map_legality() -> void:
	var base := DeployConfigScript.default_config(6, {"unlocked_map_ids": MAP_IDS})
	_check(bool(DeployConfigScript.config_validity(base).get("can_start", false)), "base_legality")

	var unknown := base.duplicate(true)
	unknown["map_config_id"] = "classic_unknown"
	unknown["unlocked_map_ids"] = MAP_IDS + ["classic_unknown"]
	var unknown_validity := DeployConfigScript.config_validity(unknown)
	_check(not bool(unknown_validity.get("can_start", true)), "unknown_legality_open")
	_check(StringName(unknown_validity.get("reason_code", &"")) == &"unknown_map_id", "unknown_legality_reason")
	var unknown_projection := DeployMapProjectionScript.project(unknown)
	_check(not bool(unknown_projection.get("selection_unlocked", true)), "unknown_projection_unlocked")

	var locked := base.duplicate(true)
	locked["unlocked_map_ids"] = ["classic_10x10_standard"]
	var locked_validity := DeployConfigScript.config_validity(locked)
	_check(not bool(locked_validity.get("can_start", true)), "locked_legality_open")
	_check(StringName(locked_validity.get("reason_code", &"")) == &"map_locked", "locked_legality_reason")

	var wrong_difficulty := base.duplicate(true)
	wrong_difficulty["difficulty"] = &"easy"
	wrong_difficulty["selected_difficulty"] = &"easy"
	var difficulty_validity := DeployConfigScript.config_validity(wrong_difficulty)
	_check(not bool(difficulty_validity.get("can_start", true)), "difficulty_legality_open")
	_check(StringName(difficulty_validity.get("reason_code", &"")) == &"difficulty_mismatch", "difficulty_legality_reason")
	var selected_only_mismatch := base.duplicate(true)
	selected_only_mismatch["selected_difficulty"] = &"hell"
	_check(not bool(DeployMapProjectionScript.project(selected_only_mismatch).get("difficulty_matches", true)), "projection_selected_difficulty_mismatch")


func _assert_rejected_without_mutation(config: Dictionary, map_id: String, reason_code: StringName, case_name: String) -> void:
	var before := config.duplicate(true)
	var result := DeployConfigScript.select_map(config, map_id)
	_check(not bool(result.get("ok", true)), "%s_not_rejected" % case_name)
	_check(not bool(result.get("changed", true)), "%s_changed" % case_name)
	_check(StringName(result.get("reason_code", &"")) == reason_code, "%s_reason" % case_name)
	_check((result.get("config", {}) as Dictionary) == before, "%s_result_mutated" % case_name)
	_check(config == before, "%s_source_mutated" % case_name)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("I2_DEPLOY_MAP_PROJECTION=PASS maps=8 scales=3 round_trip=8 route_pages=1 fallback=fail_closed")
		quit(0)
		return
	for failure in failures:
		push_error("I2 deploy map projection failure: " + failure)
	print("I2_DEPLOY_MAP_PROJECTION=FAIL count=%d" % failures.size())
	quit(1)
