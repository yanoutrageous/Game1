extends SceneTree

const LongTermContentFrameworkScript := preload("res://scripts/ui/long_term/long_term_content_framework.gd")
const LongTermContentSlotModelScript := preload("res://scripts/ui/long_term/long_term_content_slot_model.gd")
const LongTermModelScript := preload("res://scripts/ui/long_term/long_term_model.gd")
const LongTermTabModelScript := preload("res://scripts/ui/long_term/long_term_tab_model.gd")

const PAGE_SIZE := 3

var failures: Array[String] = []


func _initialize() -> void:
	_test_canonical_module_and_aliases()
	_test_goal_authority_is_read_only()
	_test_complete_commission_projection()
	if failures.is_empty():
		print("I2_LONG_TERM_TASK_ARCHIVE=PASS canonical=task_archive aliases=goals,tasks,overview modules=5 commission_records=12 pages=4 authority=read_only")
		quit(0)
		return
	for failure in failures:
		push_error("I2_LONG_TERM_TASK_ARCHIVE:%s" % failure)
	print("I2_LONG_TERM_TASK_ARCHIVE=FAIL count=%d" % failures.size())
	quit(1)


func _test_canonical_module_and_aliases() -> void:
	var tab_modules: Array = LongTermTabModelScript.build_modules()
	var framework_modules: Array = LongTermContentFrameworkScript.build_modules()
	_check(_module_ids(tab_modules) == [&"task_archive", &"codex", &"research", &"profile", &"collection_appearance"], "tab_modules_not_canonical")
	_check(_module_ids(framework_modules) == [&"task_archive", &"codex", &"research", &"profile", &"collection_appearance"], "framework_modules_not_canonical")
	_check(not _module_ids(tab_modules).has(&"gacha"), "gacha_exposed_by_tab_model")
	_check(not _module_ids(framework_modules).has(&"gacha"), "gacha_exposed_by_content_framework")
	_check(not _module_ids(tab_modules).has(&"talent"), "talent_was_fabricated")

	var canonical_model: Dictionary = LongTermModelScript.build(&"task_archive", &"i2_task_archive_test")
	var snapshot: Dictionary = canonical_model.get("snapshot_preview", {})
	var interface_preview: Dictionary = snapshot.get("long_term_asset_interface_full_content_preview", {})
	_check((interface_preview.get("modules", []) as Array).size() == 5, "snapshot_module_count_not_five")
	_check(not (interface_preview.get("modules", []) as Array).has("抽奖"), "gacha_exposed_by_snapshot")
	for alias_id in [&"goals", &"tasks", &"overview", &"task_archive"]:
		var alias_model: Dictionary = LongTermModelScript.build(alias_id, &"i2_task_archive_test")
		_check(StringName(alias_model.get("selected_module_id", &"")) == &"task_archive", "alias_not_normalized_%s" % String(alias_id))
		_check(alias_model == canonical_model, "alias_projection_changed_%s" % String(alias_id))
		var framework_module: Dictionary = LongTermContentFrameworkScript.find_module(alias_id)
		_check(StringName(framework_module.get("module_id", &"")) == &"task_archive", "framework_alias_not_normalized_%s" % String(alias_id))
		_check(LongTermContentSlotModelScript.build_slots_for_module(alias_id) == LongTermContentSlotModelScript.build_slots_for_module(&"task_archive"), "slot_alias_not_lossless_%s" % String(alias_id))

	var unavailable_model: Dictionary = LongTermModelScript.build_from_snapshot(&"gacha", {})
	_check(StringName(unavailable_model.get("selected_module_id", &"")) == &"task_archive", "unavailable_gacha_did_not_fall_back")
	_check(not bool(unavailable_model.get("m7_real_module", true)), "unavailable_gacha_marked_real")


func _test_goal_authority_is_read_only() -> void:
	var meta_summary := {
		"task_definitions": [
			{"id": "task_claimable", "display_name": "可领取任务", "description": "任务说明", "reward": {"gold": 20}},
			{"id": "task_claimed", "display_name": "已领取任务", "description": "任务说明", "reward": {"gold": 30}},
		],
		"achievement_definitions": [
			{"id": "achievement_claimable", "display_name": "可领取成就", "description": "成就说明", "reward": {"gold": 40}},
			{"id": "achievement_claimed", "display_name": "已领取成就", "description": "成就说明", "reward": {"gold": 50}},
		],
		"task_states": {
			"task_claimable": {"status": "claimable", "progress": 2, "target": 2},
			"task_claimed": {"status": "claimed", "progress": 3, "target": 3},
		},
		"achievement_states": {
			"achievement_claimable": {"status": "claimable", "progress": 1, "target": 1},
			"achievement_claimed": {"status": "claimed", "progress": 1, "target": 1},
		},
		"claimed_reward_ids": ["task:task_claimed", "achievement:achievement_claimed"],
		"granted_reward_ids": ["task:task_claimed", "achievement:achievement_claimed"],
		"red_dot_state": {"claimable_rewards": true},
		"commission_history": [],
	}
	var before := meta_summary.duplicate(true)
	var model: Dictionary = LongTermModelScript.build_from_snapshot(&"tasks", {"meta_progress_summary": meta_summary})
	var projected_meta: Dictionary = model.get("meta_progress_summary", {})
	var groups: Dictionary = model.get("m7_cards_by_group", {})

	_check(meta_summary == before, "source_meta_was_mutated")
	_check(projected_meta.get("task_states", {}) == before.get("task_states", {}), "task_states_changed")
	_check(projected_meta.get("achievement_states", {}) == before.get("achievement_states", {}), "achievement_states_changed")
	_check(projected_meta.get("claimed_reward_ids", []) == before.get("claimed_reward_ids", []), "claimed_ids_changed")
	_check(projected_meta.get("granted_reward_ids", []) == before.get("granted_reward_ids", []), "granted_ids_changed")
	_check(bool((model.get("m7_red_dot_state", {}) as Dictionary).get("claimable_rewards", false)), "claimable_red_dot_was_cleared")
	_check(groups.has("task_archive/task") and groups.has("task_archive/achievement"), "canonical_goal_groups_missing")
	_check(not groups.has("goals/task") and not groups.has("tasks/task"), "legacy_goal_group_leaked")

	var task_cards: Array = groups.get("task_archive/task", [])
	var achievement_cards: Array = groups.get("task_archive/achievement", [])
	_check(_card_action(task_cards, "task_claimable") == &"claim_goal", "task_claimable_action_missing")
	_check(_card_action(task_cards, "task_claimed") == &"", "claimed_task_still_actionable")
	_check(_card_action(achievement_cards, "achievement_claimable") == &"claim_goal", "achievement_claimable_action_missing")
	_check(_card_action(achievement_cards, "achievement_claimed") == &"", "claimed_achievement_still_actionable")


func _test_complete_commission_projection() -> void:
	var history: Array = []
	for index in range(12):
		history.append({
			"commission_id": "commission_record_%02d" % index,
			"map_id": "map_%02d" % index,
			"outcome": "Extracted" if index % 2 == 0 else "Failed",
			"completed": index % 2 == 0,
		})
	var original_history := history.duplicate(true)
	var model: Dictionary = LongTermModelScript.build_from_snapshot(&"task_archive", {
		"meta_progress_summary": {"commission_history": history},
	})
	var groups: Dictionary = model.get("m7_cards_by_group", {})
	var cards: Array = groups.get("task_archive/commission_record", [])
	var pages := _paginate(cards, PAGE_SIZE)
	var projected_ids: Array[String] = []
	for page in pages:
		for raw_card in page as Array:
			projected_ids.append(str((raw_card as Dictionary).get("id", "")))

	var expected_ids: Array[String] = []
	for reverse_index in range(11, -1, -1):
		expected_ids.append("commission_record_%d" % reverse_index)
	_check(history == original_history, "commission_history_was_mutated")
	_check(cards.size() == history.size(), "commission_history_was_truncated")
	_check(pages.size() == 4, "commission_page_count_wrong")
	_check(projected_ids == expected_ids, "commission_page_projection_lost_or_reordered_records")


func _module_ids(modules: Array) -> Array[StringName]:
	var ids: Array[StringName] = []
	for raw_module in modules:
		if raw_module is Dictionary:
			ids.append(StringName((raw_module as Dictionary).get("id", &"")))
	return ids


func _card_action(cards: Array, card_id: String) -> StringName:
	for raw_card in cards:
		if not raw_card is Dictionary:
			continue
		var card: Dictionary = raw_card
		if str(card.get("id", "")) == card_id:
			return StringName((card.get("action", {}) as Dictionary).get("action", &""))
	return &""


func _paginate(cards: Array, page_size: int) -> Array:
	var pages: Array = []
	for page_start in range(0, cards.size(), page_size):
		pages.append(cards.slice(page_start, mini(cards.size(), page_start + page_size)))
	return pages


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
