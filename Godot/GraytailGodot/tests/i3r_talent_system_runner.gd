extends SceneTree

const SaveAdapterScript := preload("res://scripts/core/save/save_adapter.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const M7ProgressionServiceScript := preload("res://scripts/core/progression/m7_progression_service.gd")
const M7TalentCatalogScript := preload("res://scripts/core/progression/m7_talent_catalog.gd")
const M3RItemUsabilityModelScript := preload("res://scripts/core/content/m3r_item_usability_model.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const RunStartConfigScript := preload("res://scripts/core/run/run_start_config.gd")
const RunConfigScript := preload("res://scripts/core/run/run_config.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")
const RunRuntimeControllerScript := preload("res://scripts/core/run/run_runtime_controller.gd")
const CombatStateScript := preload("res://scripts/core/run/combat_state.gd")
const RunEffectApplierScript := preload("res://scripts/core/run/run_effect_applier.gd")
const RunRuleServiceScript := preload("res://scripts/core/run/run_rule_service.gd")
const TutorialMapCatalogScript := preload("res://scripts/core/run/tutorial_map_catalog.gd")
const LongTermModelScript := preload("res://scripts/ui/long_term/long_term_model.gd")
const LongTermTabModelScript := preload("res://scripts/ui/long_term/long_term_tab_model.gd")
const LongTermContentFrameworkScript := preload("res://scripts/ui/long_term/long_term_content_framework.gd")
const LongTermModuleProjectionScript := preload("res://scripts/ui/long_term/long_term_module_projection.gd")


class MemorySaveAdapter:
	extends SaveAdapter

	var fail_next_save := false
	var save_calls := 0
	var stored_data: Dictionary = {}

	func load_json_result(
		_path: String = M1_META_PROGRESS_PATH,
		default_data: Dictionary = {},
		_normalize_meta_progress: bool = true
	) -> Dictionary:
		var loaded := default_meta_progress() if default_data.is_empty() else default_data.duplicate(true)
		return {
			"ok": true,
			"status": "memory",
			"data": loaded,
			"read_only_fallback": false,
			"error": "",
		}

	func save_json(
		source_data: Dictionary,
		_path: String = M1_META_PROGRESS_PATH,
		_normalize_meta_progress: bool = true
	) -> bool:
		save_calls += 1
		if fail_next_save:
			fail_next_save = false
			last_error = "forced_talent_save_failure"
			return false
		last_error = ""
		stored_data = source_data.duplicate(true)
		return true


const TALENT_IDS := [
	M7TalentCatalogScript.TALENT_CARRY_RIGGING,
	M7TalentCatalogScript.TALENT_SALVAGE_CLAUSE,
	M7TalentCatalogScript.TALENT_SHOCK_TRAINING,
	M7TalentCatalogScript.TALENT_PRESSURE_READING,
	M7TalentCatalogScript.TALENT_SCAN_DISCIPLINE,
	M7TalentCatalogScript.TALENT_TRADER_NOTES,
]

const EXPECTED_RUN_FIELDS := {
	"backpack_capacity": 11,
	"failure_salvage_capacity": 5,
	"mine_dmg_reduce": 5,
	"protocol_pressure_reduce": 2,
	"search_reward_bonus": 1,
	"scan_hint_bonus": 1,
}

var failures: Array[String] = []
var controllers: Array[RunRuntimeController] = []
var migration_save_path := "user://tests/i3r_talent_system_%d.json" % Time.get_ticks_usec()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_migration_save()
	_test_schema4_migration_and_level_budgets()
	_test_catalog_contract()
	_test_envelope_idempotency_and_conflict()
	_test_save_failure_full_rollback()
	_test_run_start_fields_and_deploy_recalculation()
	_test_six_runtime_consumers()
	_test_new_run_snapshot_isolation()
	_test_tutorial_zero_pollution()
	_test_long_term_talent_workspace()
	_cleanup_controllers()
	_cleanup_migration_save()
	if failures.is_empty():
		print("I3R_TALENT_SYSTEM=PASS schema4=topup,preserve levels=1-5 nodes=6 branches=3 envelope=idempotent,conflict rollback=save_failure run_start=6 deploy=recalc_snapshot tutorial=zero_pollution long_term=talent_tree")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("I3R_TALENT_SYSTEM=FAIL count=%d" % failures.size())
	quit(1)


func _test_schema4_migration_and_level_budgets() -> void:
	var parent_path := ProjectSettings.globalize_path(migration_save_path.get_base_dir())
	_expect(DirAccess.make_dir_recursive_absolute(parent_path) == OK, "Could not create the schema-4 migration fixture directory")
	var old_save := {
		"schema_version": 4,
		"profile_level": 4,
		"profile_exp": 450,
		"talent_points": 1,
		"talent_flags": [
			M7TalentCatalogScript.TALENT_CARRY_RIGGING,
			"legacy_unknown_talent",
			M7TalentCatalogScript.TALENT_CARRY_RIGGING,
		],
	}
	var file := FileAccess.open(migration_save_path, FileAccess.WRITE)
	_expect(file != null, "Could not write the schema-4 migration fixture")
	if file == null:
		return
	file.store_string(JSON.stringify(old_save))
	file.close()

	var save_adapter := SaveAdapterScript.new()
	var loaded := save_adapter.load_json_result(migration_save_path, save_adapter.default_meta_progress())
	_expect(bool(loaded.get("ok", false)), "Schema-4 save did not load")
	var migrated := _dictionary(loaded.get("data", {}))
	var migrated_flags: Array = migrated.get("talent_flags", [])
	_expect(int(migrated.get("schema_version", 0)) == 5, "Schema-4 save did not migrate to schema 5")
	_expect(int(migrated.get("profile_level", 0)) == 4, "Schema-4 migration changed the authoritative profile level")
	_expect(int(migrated.get("talent_budget_granted", -1)) == 3, "Schema-4 migration did not grant the level-4 budget")
	_expect(int(migrated.get("talent_points", -1)) == 2, "Schema-4 migration did not preserve one point and top up the missing budget")
	_expect(migrated_flags.has(M7TalentCatalogScript.TALENT_CARRY_RIGGING), "Schema-4 migration lost an existing known talent flag")
	_expect(migrated_flags.has("legacy_unknown_talent"), "Schema-4 migration lost an unknown legacy talent flag")
	_expect(migrated_flags.count(M7TalentCatalogScript.TALENT_CARRY_RIGGING) == 1, "Schema-4 migration did not deduplicate talent flags")

	var excess_points := {
		"profile_level": 3,
		"talent_points": 5,
		"talent_flags": [],
	}
	M7TalentCatalogScript.sync_progress(excess_points, true)
	_expect(int(excess_points.get("talent_points", -1)) == 5, "Legacy migration reduced already-unspent talent points")
	_expect(int(excess_points.get("talent_budget_granted", -1)) == 5, "Legacy migration did not account for preserved excess points")

	var progression := save_adapter.default_meta_progress()
	progression["talent_points"] = 0
	progression["talent_flags"] = []
	progression["talent_budget_granted"] = 0
	var level_experience := [0, 100, 250, 450, 700]
	for index in range(level_experience.size()):
		progression["profile_exp"] = int(level_experience[index])
		progression = M7ProgressionServiceScript.normalize_meta(progression)
		var expected_level := index + 1
		var expected_budget := expected_level - 1
		_expect(int(progression.get("profile_level", 0)) == expected_level, "Profile level did not follow the level threshold: %d" % expected_level)
		_expect(int(progression.get("talent_points", -1)) == expected_budget, "Level %d did not grant exactly one cumulative point per level after level 1" % expected_level)
		_expect(int(progression.get("talent_budget_granted", -1)) == expected_budget, "Level %d budget accounting is not exact" % expected_level)


func _test_catalog_contract() -> void:
	var expected := {
		M7TalentCatalogScript.TALENT_CARRY_RIGGING: {
			"branch_id": &"preparation",
			"tier": 1,
			"prerequisite_ids": [],
			"effect_kind": &"backpack_capacity",
			"effect_amount": 1,
			"effect_label": "背包负重上限 +1",
		},
		M7TalentCatalogScript.TALENT_SALVAGE_CLAUSE: {
			"branch_id": &"preparation",
			"tier": 2,
			"prerequisite_ids": [M7TalentCatalogScript.TALENT_CARRY_RIGGING],
			"effect_kind": &"salvage_capacity",
			"effect_amount": 1,
			"effect_label": "失败结算可抢救重量上限 +1",
		},
		M7TalentCatalogScript.TALENT_SHOCK_TRAINING: {
			"branch_id": &"safety",
			"tier": 1,
			"prerequisite_ids": [],
			"effect_kind": &"mine_damage_reduce",
			"effect_amount": 5,
			"effect_label": "每次雷险伤害减少 5 点",
		},
		M7TalentCatalogScript.TALENT_PRESSURE_READING: {
			"branch_id": &"safety",
			"tier": 2,
			"prerequisite_ids": [M7TalentCatalogScript.TALENT_SHOCK_TRAINING],
			"effect_kind": &"protocol_pressure_reduce",
			"effect_amount": 2,
			"effect_label": "每次协议压力增量减少 2 点",
		},
		M7TalentCatalogScript.TALENT_SCAN_DISCIPLINE: {
			"branch_id": &"exploration",
			"tier": 1,
			"prerequisite_ids": [],
			"effect_kind": &"scan_hint",
			"effect_amount": 1,
			"effect_label": "扫描道具额外揭示 1 个对角格",
		},
		M7TalentCatalogScript.TALENT_TRADER_NOTES: {
			"branch_id": &"exploration",
			"tier": 2,
			"prerequisite_ids": [M7TalentCatalogScript.TALENT_SCAN_DISCIPLINE],
			"effect_kind": &"search_reward",
			"effect_amount": 1,
			"effect_label": "每次搜索黑币收益 +1",
		},
	}
	var definitions := M7TalentCatalogScript.definitions()
	_expect(definitions.size() == 6, "Talent catalog does not contain exactly six executable nodes")
	var branch_counts := {}
	var actual_ids: Array[String] = []
	for raw_definition in definitions:
		var definition := _dictionary(raw_definition)
		var talent_id := str(definition.get("talent_id", ""))
		actual_ids.append(talent_id)
		_expect(expected.has(talent_id), "Talent catalog contains an unauthorized node: %s" % talent_id)
		if not expected.has(talent_id):
			continue
		var expected_node: Dictionary = expected[talent_id]
		_expect(int(definition.get("cost", 0)) == 1, "Talent node cost is not exactly one point: %s" % talent_id)
		_expect(StringName(definition.get("runtime_scope", &"")) == &"new_run_start_config", "Talent node does not declare new-run snapshot scope: %s" % talent_id)
		for field in ["branch_id", "tier", "prerequisite_ids", "effect_kind", "effect_amount", "effect_label"]:
			_expect(definition.get(field) == expected_node.get(field), "Talent node field mismatch: %s.%s" % [talent_id, field])
		var branch_id := StringName(definition.get("branch_id", &""))
		branch_counts[branch_id] = int(branch_counts.get(branch_id, 0)) + 1
	actual_ids.sort()
	var expected_ids: Array[String] = []
	for raw_id in expected.keys():
		expected_ids.append(str(raw_id))
	expected_ids.sort()
	_expect(actual_ids == expected_ids, "Talent catalog IDs differ from the six authorized runtime consumers")
	for branch_id in [&"preparation", &"safety", &"exploration"]:
		_expect(int(branch_counts.get(branch_id, 0)) == 2, "Talent branch is not exactly two tiers: %s" % str(branch_id))

	var projected_meta := {
		"profile_level": 5,
		"talent_points": 4,
		"talent_budget_granted": 4,
		"talent_flags": [],
	}
	var projection := M7TalentCatalogScript.projection(projected_meta)
	for raw_node in projection:
		var node := _dictionary(raw_node)
		_expect(not str(node.get("reason", "")).is_empty(), "Talent node lacks a player-visible availability reason: %s" % str(node.get("talent_id", "")))
		if int(node.get("tier", 0)) == 1:
			_expect(bool(node.get("available", false)), "Root talent is not available with sufficient points: %s" % str(node.get("talent_id", "")))
		else:
			_expect(StringName(node.get("reason_code", &"")) == &"prerequisite_missing", "Tier-2 talent does not expose its missing prerequisite")


func _test_envelope_idempotency_and_conflict() -> void:
	var fixture := _meta_fixture(700)
	var adapter := fixture.get("adapter") as MetaProgressAdapter
	var memory := fixture.get("save_adapter") as MemorySaveAdapter
	var controller := _controller(adapter)
	var blocked := controller.execute_meta_action(_talent_request(
		"talent-prerequisite",
		M7TalentCatalogScript.TALENT_SALVAGE_CLAUSE
	))
	_expect(not bool(blocked.get("ok", true)), "Tier-2 talent unlocked without its prerequisite")
	_expect(StringName(blocked.get("status", &"")) == &"prerequisite_missing", "Tier-2 prerequisite failure did not propagate through MetaActionEnvelope")
	_expect(memory.save_calls == 0, "Rejected prerequisite reached persistence")

	var first := controller.execute_meta_action(_talent_request(
		"talent-idempotent",
		M7TalentCatalogScript.TALENT_CARRY_RIGGING
	))
	_expect(bool(first.get("ok", false)), "Valid talent unlock failed")
	_expect(StringName(first.get("status", &"")) == &"talent_unlocked", "Talent unlock status did not propagate")
	_expect(str(first.get("target_id", "")) == M7TalentCatalogScript.TALENT_CARRY_RIGGING, "Talent envelope lost its exact target")
	var first_result := _dictionary(first.get("result", {}))
	_expect(int(first_result.get("cost", -1)) == 1, "Talent transaction did not debit the exact node cost")
	_expect(int(adapter.data.get("talent_points", -1)) == 3, "Talent transaction debited the wrong number of points")
	_expect((adapter.data.get("talent_flags", []) as Array).has(M7TalentCatalogScript.TALENT_CARRY_RIGGING), "Talent transaction did not persist its flag")
	_expect(memory.save_calls == 1 and memory.stored_data == adapter.data, "Talent transaction did not save exactly once")

	var duplicate_request := _talent_request("talent-idempotent", M7TalentCatalogScript.TALENT_CARRY_RIGGING)
	duplicate_request["presentation_noise"] = "ignored"
	var duplicate := controller.execute_meta_action(duplicate_request)
	_expect(bool(duplicate.get("ok", false)) and bool(duplicate.get("duplicate", false)), "Same talent request_id did not return a cached duplicate")
	_expect(memory.save_calls == 1 and int(adapter.data.get("talent_points", -1)) == 3, "Idempotent talent replay repeated the debit or save")

	var conflict := controller.execute_meta_action(_talent_request(
		"talent-idempotent",
		M7TalentCatalogScript.TALENT_SHOCK_TRAINING
	))
	_expect(not bool(conflict.get("ok", true)), "Changed talent payload reused under one request_id")
	_expect(StringName(conflict.get("status", &"")) == &"request_id_conflict", "Changed talent payload did not fail closed as a request_id conflict")
	_expect(memory.save_calls == 1 and int(adapter.data.get("talent_points", -1)) == 3, "Talent request_id conflict mutated authoritative progress")


func _test_save_failure_full_rollback() -> void:
	var fixture := _meta_fixture(250)
	var adapter := fixture.get("adapter") as MetaProgressAdapter
	var memory := fixture.get("save_adapter") as MemorySaveAdapter
	var controller := _controller(adapter)
	adapter.data["talent_points"] = 0
	adapter.data["talent_flags"] = []
	adapter.data.erase("talent_budget_granted")
	adapter.data.erase("talent_catalog_version")
	var before := adapter.data.duplicate(true)
	memory.fail_next_save = true
	var failed := controller.execute_meta_action(_talent_request(
		"talent-save-failure",
		M7TalentCatalogScript.TALENT_CARRY_RIGGING
	))
	var failed_result := _dictionary(failed.get("result", {}))
	_expect(not bool(failed.get("ok", true)), "Forced talent save failure unexpectedly succeeded")
	_expect(StringName(failed.get("status", &"")) == &"save_failed", "Forced talent save failure did not propagate")
	_expect(bool(failed_result.get("rolled_back", false)), "Forced talent save failure did not report rollback")
	_expect(adapter.data == before, "Talent save failure did not restore the complete pre-transaction data, including migration fields")
	_expect(memory.save_calls == 1 and memory.stored_data.is_empty(), "Failed talent save was mistaken for a commit")

	var retry := controller.execute_meta_action(_talent_request(
		"talent-save-retry",
		M7TalentCatalogScript.TALENT_CARRY_RIGGING
	))
	_expect(bool(retry.get("ok", false)), "A new request_id could not retry a rolled-back talent unlock")
	_expect(memory.save_calls == 2, "Talent retry did not perform exactly one additional save")
	_expect(int(adapter.data.get("talent_points", -1)) == 1, "Talent retry did not top up the level budget and debit exactly one point")
	_expect((adapter.data.get("talent_flags", []) as Array).has(M7TalentCatalogScript.TALENT_CARRY_RIGGING), "Talent retry did not commit its flag")


func _test_run_start_fields_and_deploy_recalculation() -> void:
	var meta := _all_talents_meta()
	var m3r_fields := M3RItemUsabilityModelScript.build_run_start_fields(meta)
	_expect((m3r_fields.get("active_talent_effects", []) as Array).size() == 6, "M3R profile did not project all six active talents")
	_expect_run_fields(m3r_fields, EXPECTED_RUN_FIELDS, "M3R run-start fields")

	var deploy_config := _classic_deploy_config(meta, 71)
	_expect_run_fields(deploy_config, EXPECTED_RUN_FIELDS, "Deploy baseline")
	var equipment := [
		_equipment("eq_edge_opener", "i3r_talent:search"),
		_equipment("eq_goggles", "i3r_talent:scan"),
	]
	var first_recalculation := DeployConfigScript._recalculate_loadout(deploy_config, equipment, [])
	_expect(bool(first_recalculation.get("valid", false)), "Deploy recalculation rejected a valid two-item fixture")
	var equipped_config := _dictionary(first_recalculation.get("config", {}))
	var equipped_expected := EXPECTED_RUN_FIELDS.duplicate(true)
	equipped_expected["search_reward_bonus"] = 2
	equipped_expected["scan_hint_bonus"] = 2
	_expect_run_fields(equipped_config, equipped_expected, "Deploy recalculation with equipment")

	var second_recalculation := DeployConfigScript._recalculate_loadout(equipped_config, equipment, [])
	_expect(bool(second_recalculation.get("valid", false)), "Repeated Deploy recalculation rejected an unchanged loadout")
	var repeated_config := _dictionary(second_recalculation.get("config", {}))
	_expect_run_fields(repeated_config, equipped_expected, "Repeated Deploy recalculation")

	var removed_recalculation := DeployConfigScript._recalculate_loadout(repeated_config, [], [])
	_expect(bool(removed_recalculation.get("valid", false)), "Deploy recalculation rejected equipment removal")
	var talent_only_config := _dictionary(removed_recalculation.get("config", {}))
	_expect_run_fields(talent_only_config, EXPECTED_RUN_FIELDS, "Deploy recalculation after equipment removal")

	var run_start := DeployConfigScript.build_run_start_config(repeated_config)
	_expect_run_fields(run_start, equipped_expected, "Deploy RunStartConfig")
	var validation := RunStartConfigScript.validate(run_start)
	_expect(bool(validation.get("ok", false)), "Talent-bearing RunStartConfig failed validation: %s" % str(validation.get("issues", [])))
	_expect_run_fields(_dictionary(validation.get("config", {})), equipped_expected, "Normalized RunStartConfig")


func _test_six_runtime_consumers() -> void:
	var baseline_meta := SaveAdapterScript.new().default_meta_progress()
	baseline_meta["profile_exp"] = 700
	baseline_meta["profile_level"] = 5
	baseline_meta["talent_flags"] = []
	baseline_meta["talent_points"] = 4
	baseline_meta["talent_budget_granted"] = 4
	var baseline := _runtime_context(baseline_meta, 103, 424242)
	var talented := _runtime_context(_all_talents_meta(), 107, 424242)

	var baseline_fit := baseline.asset_ledger.can_fit_item({"weight": 11})
	var talented_fit := talented.asset_ledger.can_fit_item({"weight": 11})
	_expect(not bool(baseline_fit.get("ok", true)) and bool(talented_fit.get("ok", false)), "Backpack talent is not consumed by RunAssetLedger capacity checks")
	_expect(int((talented.asset_ledger.build_failure_preview() as Dictionary).get("salvage_capacity", 0)) == 5, "Salvage talent is not consumed by failure settlement preview")

	var baseline_mine_damage := CombatStateScript.take_mine_hit(baseline)
	var talented_mine_damage := CombatStateScript.take_mine_hit(talented)
	_expect(baseline_mine_damage - talented_mine_damage == 5, "Mine-reduction talent does not reduce each real mine hit by exactly 5")

	RunEffectApplierScript.apply_effects(baseline, [RunEffectApplierScript.effect_protocol_pressure_delta(10, "i3r_talent_consumer")])
	RunEffectApplierScript.apply_effects(talented, [RunEffectApplierScript.effect_protocol_pressure_delta(10, "i3r_talent_consumer")])
	_expect(baseline.pressure == 10 and talented.pressure == 8, "Pressure talent is not consumed by positive protocol-pressure effects")

	var center := Vector2i(4, 4)
	baseline.current_pos = center
	baseline.player_pos = center
	talented.current_pos = center
	talented.player_pos = center
	var baseline_scan := RunRuleServiceScript._reveal_nearby_for_consumable(baseline)
	var talented_scan := RunRuleServiceScript._reveal_nearby_for_consumable(talented)
	_expect(talented_scan.size() == baseline_scan.size() + 1, "Scan talent does not reveal exactly one additional diagonal cell")

	var search_pos := Vector2i(3, 3)
	var baseline_search := RunRuleServiceScript.apply_search_reward(baseline, search_pos, 2, false)
	var talented_search := RunRuleServiceScript.apply_search_reward(talented, search_pos, 2, false)
	_expect(
		int(talented_search.get("black_coin_delta", 0)) == int(baseline_search.get("black_coin_delta", 0)) + 1,
		"Search-yield talent is not consumed by the real search reward transaction"
	)


func _test_new_run_snapshot_isolation() -> void:
	var fixture := _meta_fixture(100)
	var adapter := fixture.get("adapter") as MetaProgressAdapter
	var controller := _controller(adapter)
	var before_start := DeployConfigScript.build_run_start_config(_classic_deploy_config(adapter.get_summary(), 83))
	var active_context := RunContextScript.new() as RunContext
	active_context.start_run(RunConfigScript.m7_map(before_start))
	_expect(active_context.mine_dmg_reduce == 0, "Pre-unlock active run unexpectedly contained the shock talent")
	_expect((active_context.active_talent_effects as Array).is_empty(), "Pre-unlock active run unexpectedly contained talent effects")

	var unlock := controller.execute_meta_action(_talent_request(
		"talent-new-run-isolation",
		M7TalentCatalogScript.TALENT_SHOCK_TRAINING
	))
	_expect(bool(unlock.get("ok", false)), "Shock talent could not be unlocked for snapshot isolation")
	_expect(active_context.mine_dmg_reduce == 0, "Unlocking a talent rewrote an already-active RunContext")
	_expect(int(active_context.run_start_config.get("mine_dmg_reduce", -1)) == 0, "Unlocking a talent rewrote the active run_start_config snapshot")

	var next_start := DeployConfigScript.build_run_start_config(_classic_deploy_config(adapter.get_summary(), 89))
	_expect(int(next_start.get("mine_dmg_reduce", 0)) == 5, "New Deploy snapshot did not include the newly unlocked talent")
	var next_context := RunContextScript.new() as RunContext
	next_context.start_run(RunConfigScript.m7_map(next_start))
	_expect(next_context.mine_dmg_reduce == 5, "The next new RunContext did not receive the unlocked talent")
	_expect((next_context.active_talent_effects as Array).size() == 1, "The next new RunContext did not snapshot its active talent list")


func _test_tutorial_zero_pollution() -> void:
	var all_talent_start := DeployConfigScript.build_run_start_config(_classic_deploy_config(_all_talents_meta(), 97))
	all_talent_start["map_config_id"] = TutorialMapCatalogScript.MAP_ID
	var tutorial_runtime := TutorialMapCatalogScript.runtime_config(all_talent_start)
	var tutorial_expected := {
		"backpack_capacity": 10,
		"failure_salvage_capacity": 4,
		"mine_dmg_reduce": 0,
		"protocol_pressure_reduce": 0,
		"search_reward_bonus": 0,
		"scan_hint_bonus": 0,
	}
	_expect_run_fields(tutorial_runtime, tutorial_expected, "Tutorial runtime")
	var sanitized_start := _dictionary(tutorial_runtime.get("run_start_config", {}))
	_expect_run_fields(sanitized_start, tutorial_expected, "Tutorial run-start snapshot")
	_expect((tutorial_runtime.get("active_talent_effects", []) as Array).is_empty(), "Tutorial runtime retained active talent effects")
	_expect((sanitized_start.get("talent_interface", []) as Array).is_empty(), "Tutorial run-start retained the formal talent interface")
	_expect(not bool(tutorial_runtime.get("apply_meta_progress", true)), "Tutorial runtime still applies formal meta progression")

	var fixture := _meta_fixture(700)
	var adapter := fixture.get("adapter") as MetaProgressAdapter
	var memory := fixture.get("save_adapter") as MemorySaveAdapter
	adapter.data["talent_flags"] = TALENT_IDS.duplicate()
	adapter.data["talent_points"] = 2
	adapter.data["talent_budget_granted"] = 8
	adapter.data["tutorial_completed"] = false
	M7ProgressionServiceScript.refresh_red_dots(adapter.data)
	var before := adapter.data.duplicate(true)
	var commit := adapter.apply_settlement({
		"result_id": "i3r_talent_tutorial_completion",
		"mode": &"tutorial",
		"outcome": "Training Complete",
		"settlement": {"outcome": "success", "gold_coin": 999, "experience": 999},
		"run_start_config": {"map_config_id": TutorialMapCatalogScript.MAP_ID},
	})
	_expect(bool(commit.get("ok", false)) and str(commit.get("status", "")) == "tutorial_completed", "Tutorial completion marker did not commit")
	var after := adapter.data.duplicate(true)
	after["tutorial_completed"] = false
	_expect(after == before, "Tutorial settlement polluted talent points, flags, experience, economy, or formal records")
	_expect(memory.save_calls == 1, "Tutorial completion marker was not saved exactly once")


func _test_long_term_talent_workspace() -> void:
	var fixture := _meta_fixture(700)
	var adapter := fixture.get("adapter") as MetaProgressAdapter
	var summary := adapter.get_summary()
	var modules := LongTermTabModelScript.build_modules()
	var module_ids: Array[StringName] = []
	for raw_module in modules:
		var module := _dictionary(raw_module)
		module_ids.append(StringName(module.get("id", &"")))
	_expect(module_ids.count(&"talent") == 1, "LongTerm does not expose exactly one independent talent module")
	_expect(module_ids.has(&"research"), "LongTerm talent work replaced the independent research module")

	var talent_framework := LongTermContentFrameworkScript.find_module(&"talent")
	_expect(StringName(talent_framework.get("module_id", &"")) == &"talent", "LongTerm content framework did not resolve the talent module")
	var talent_group := _group_by_id(talent_framework.get("secondary_groups", []), &"tree")
	_expect(not talent_group.is_empty(), "LongTerm talent module lacks the independent talent/tree group")
	_expect(_group_by_id(talent_framework.get("secondary_groups", []), &"unlock_interface").is_empty(), "LongTerm talent module reused the research group identity")

	var model := LongTermModelScript.build_from_snapshot(
		&"talent",
		{"run_active": false, "meta_progress_summary": summary},
		&"i3r_talent_system"
	)
	_expect(StringName(model.get("selected_module_id", &"")) == &"talent", "LongTerm model did not select the talent module")
	_expect(bool(model.get("m7_real_module", false)), "LongTerm model treated talent as a fabricated module")
	var cards_by_group := _dictionary(model.get("m7_cards_by_group", {}))
	var talent_cards: Array = cards_by_group.get("talent/tree", [])
	var research_cards: Array = cards_by_group.get("research/unlock_interface", [])
	_expect(talent_cards.size() == 6, "LongTerm talent/tree does not contain the six authoritative nodes")
	for raw_card in talent_cards:
		var card := _dictionary(raw_card)
		_expect(StringName(card.get("presentation_kind", &"")) == &"talent_unlock_node", "Talent tree contains a non-talent card")
		_expect(StringName(card.get("tree_source", &"")) == &"m7_talent_catalog", "Talent card does not read the authoritative catalog")
		_expect(bool(card.get("adds_talent_rules", false)), "Talent card does not declare its real talent authority")
		_expect((card.get("facts", []) as Array).size() >= 4, "Talent card omits prerequisite, cost, exact effect, or scope facts")
	for raw_research_card in research_cards:
		_expect(not bool(_dictionary(raw_research_card).get("adds_talent_rules", true)), "Research tree was merged into talent authority")
	var tree_contract := _dictionary(model.get("talent_tree_contract", {}))
	_expect(StringName(tree_contract.get("source", &"")) == &"m7_talent_catalog", "Talent tree contract has the wrong source")
	_expect(int(tree_contract.get("node_count", 0)) == 6, "Talent tree contract has the wrong node count")
	_expect(int(tree_contract.get("branch_count", 0)) == 3, "Talent tree contract has the wrong branch count")
	_expect(int(tree_contract.get("edge_count", 0)) == 3, "Talent tree contract has the wrong prerequisite edge count")

	var workspace := LongTermModuleProjectionScript.build(&"talent", talent_group, model, "talent contract")
	_expect(StringName(workspace.get("kind", &"")) == &"talent_unlock_tree", "LongTerm talent/tree did not project its own tree workspace")
	_expect(str(workspace.get("group_key", "")) == "talent/tree", "LongTerm talent workspace lost its independent group key")
	_expect(int(workspace.get("record_count", 0)) == 6, "LongTerm talent workspace did not receive all six cards")


func _meta_fixture(profile_exp: int) -> Dictionary:
	var memory := MemorySaveAdapter.new()
	var adapter := MetaProgressAdapterScript.new()
	adapter.save_adapter = memory
	adapter.write_blocked = false
	adapter.write_block_reason = ""
	adapter.last_error = ""
	var data := memory.default_meta_progress()
	data["profile_exp"] = profile_exp
	data["profile_level"] = M7ContentCatalogScript.profile_level_for_exp(profile_exp)
	data["talent_points"] = 0
	data["talent_flags"] = []
	data["talent_budget_granted"] = 0
	adapter.data = M7ProgressionServiceScript.normalize_meta(data)
	memory.save_calls = 0
	memory.stored_data.clear()
	return {"adapter": adapter, "save_adapter": memory}


func _all_talents_meta() -> Dictionary:
	var meta := SaveAdapterScript.new().default_meta_progress()
	meta["profile_level"] = 5
	meta["profile_exp"] = 700
	meta["talent_points"] = 0
	meta["talent_flags"] = TALENT_IDS.duplicate()
	meta["talent_budget_granted"] = 6
	M7TalentCatalogScript.sync_progress(meta)
	M7ProgressionServiceScript.refresh_red_dots(meta)
	return meta


func _classic_deploy_config(meta: Dictionary, sequence: int) -> Dictionary:
	var config := DeployConfigScript.default_config(sequence, meta)
	var selected := DeployConfigScript.select_map(config, "classic_10x10_standard")
	_expect(bool(selected.get("ok", false)), "Classic map could not be selected for the talent fixture")
	return _dictionary(selected.get("config", config))


func _runtime_context(meta: Dictionary, sequence: int, seed_value: int) -> RunContext:
	var run_start := DeployConfigScript.build_run_start_config(_classic_deploy_config(meta, sequence))
	run_start["seed_value"] = seed_value
	var context := RunContextScript.new() as RunContext
	context.start_run(RunConfigScript.m7_map(run_start))
	return context


func _equipment(item_id: String, instance_id: String) -> Dictionary:
	var item := M3RItemUsabilityModelScript.normalize_item(M3RItemUsabilityModelScript.item_definition(item_id))
	item["instance_id"] = instance_id
	return item


func _talent_request(request_id: String, talent_id: String) -> Dictionary:
	return {
		"request_id": request_id,
		"source_page": &"long_term",
		"action": &"unlock_talent",
		"talent_id": talent_id,
	}


func _controller(adapter: MetaProgressAdapter) -> RunRuntimeController:
	var controller := RunRuntimeControllerScript.new() as RunRuntimeController
	controller.bind_meta_progress_adapter(adapter)
	controllers.append(controller)
	return controller


func _cleanup_controllers() -> void:
	for controller in controllers:
		controller.bind_meta_progress_adapter(null)
		controller.in_run_runtime.bind(null)
		controller.command_bus.bind_runtime_controller(null)
		var terminal_callback := Callable(controller, "_on_terminal_result_available")
		if controller.command_bus.result_available.is_connected(terminal_callback):
			controller.command_bus.result_available.disconnect(terminal_callback)
	controllers.clear()


func _cleanup_migration_save() -> void:
	for suffix in [
		"",
		SaveAdapterScript.ATOMIC_TEMP_SUFFIX,
		SaveAdapterScript.LAST_VALID_BACKUP_SUFFIX,
		SaveAdapterScript.CORRUPT_RECOVERY_SUFFIX,
	]:
		var path := migration_save_path + str(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect_run_fields(source: Dictionary, expected: Dictionary, scope: String) -> void:
	for field in expected.keys():
		_expect(int(source.get(field, -999)) == int(expected[field]), "%s changed %s: expected %d, got %d" % [scope, field, int(expected[field]), int(source.get(field, -999))])


func _group_by_id(groups_value: Variant, group_id: StringName) -> Dictionary:
	if groups_value is not Array:
		return {}
	for raw_group in groups_value as Array:
		var group := _dictionary(raw_group)
		if StringName(group.get("group_id", group.get("id", &""))) == group_id:
			return group
	return {}


func _dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
