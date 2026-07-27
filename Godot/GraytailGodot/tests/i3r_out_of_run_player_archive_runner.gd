extends SceneTree

const SaveAdapterScript := preload("res://scripts/core/save/save_adapter.gd")
const MetaProgressAdapterScript := preload("res://scripts/core/save/meta_progress_adapter.gd")
const LongTermModelScript := preload("res://scripts/ui/long_term/long_term_model.gd")
const LongTermShellScript := preload("res://scripts/ui/long_term/long_term_shell.gd")
const ResultPresentationModelScript := preload("res://scripts/ui/result/result_presentation_model.gd")


class MemorySaveAdapter:
	extends SaveAdapter

	var save_calls := 0
	var stored_data: Dictionary = {}

	func load_json_result(
		_path: String = M1_META_PROGRESS_PATH,
		default_data: Dictionary = {},
		_normalize_meta_progress: bool = true
	) -> Dictionary:
		return {
			"ok": true,
			"status": "memory",
			"data": default_meta_progress() if default_data.is_empty() else default_data.duplicate(true),
			"read_only_fallback": false,
			"error": "",
		}

	func save_json(
		source_data: Dictionary,
		_path: String = M1_META_PROGRESS_PATH,
		_normalize_meta_progress: bool = true
	) -> bool:
		save_calls += 1
		stored_data = source_data.duplicate(true)
		last_error = ""
		return true


var failures: Array[String] = []
var archived_summary: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_terminal_facts_persist_to_history()
	_test_history_player_projection()
	await _test_profile_shell_summary()
	if failures.is_empty():
		print("I3R_OUT_OF_RUN_PLAYER_ARCHIVE=PASS persistence=terminal_reason+item_flow+currency profile=rate+history_count archive=player_facts")
		quit(0)
		return
	for failure in failures:
		push_error("I3R_OUT_OF_RUN_PLAYER_ARCHIVE:%s" % failure)
	print("I3R_OUT_OF_RUN_PLAYER_ARCHIVE=FAIL count=%d" % failures.size())
	quit(1)


func _test_terminal_facts_persist_to_history() -> void:
	var memory := MemorySaveAdapter.new()
	var adapter := MetaProgressAdapterScript.new() as MetaProgressAdapter
	adapter.save_adapter = memory
	adapter.data = memory.default_meta_progress()
	adapter.write_blocked = false
	var result := {
		"result_id": "i3r_archive_combat_failure",
		"run_id": "archive-run-1",
		"outcome": "Failed",
		"terminal_reason_code": &"runtime_combat_defeat",
		"run_start_config": {
			"map_config_id": "classic_10x10_standard",
			"map_display_name": "标准矿区",
			"difficulty": "standard",
			"difficulty_label": "标准",
			"selected_objective_id": "commission_recover_supply",
			"selected_objective_label": "补给回收",
			"selected_equipment_items": [_item("eq_goggles", "护目镜")],
			"selected_consumable_items": [_item("con_ration", "应急压缩饼")],
		},
		"settlement": {
			"outcome": "failure",
			"finalized": true,
			"requires_salvage_selection": false,
			"salvaged_items": [_item("mat_scrap", "旧零件")],
			"lost_items": [_item("collectible_brass", "黄铜印章")],
			"room_floor_lost_items": [_item("con_bandage", "止血贴")],
			"cleared_consumables": [_item("con_ration", "应急压缩饼")],
			"black_coin_lost": 17,
			"safe_yield_retained": 6,
			"gold_coin_gained": 6,
			"settlement_log": [{"type": &"settle_failure", "salvaged_item_count": 1}],
		},
	}
	var commit := adapter.apply_settlement(result)
	_expect(bool(commit.get("ok", false)), "failed settlement did not commit to the memory adapter")
	_expect(memory.save_calls == 1, "failed settlement did not save exactly once")
	archived_summary = adapter.get_summary()
	var records := archived_summary.get("history_records", []) as Array
	_expect(records.size() == 1, "committed settlement did not create exactly one history record")
	if records.is_empty():
		return
	var record := records[0] as Dictionary
	_expect(StringName(record.get("terminal_reason_code", &"")) == &"runtime_combat_defeat", "terminal reason was discarded before archive persistence")
	_expect((record.get("room_floor_lost_items", []) as Array).size() == 1, "floor loss was discarded before archive persistence")
	_expect(int(record.get("safe_yield_retained", -1)) == 6, "retained safe yield was discarded before archive persistence")
	_expect((record.get("salvaged_items", []) as Array).size() == 1, "salvaged item flow was not persisted")
	_expect((record.get("lost_items", []) as Array).size() == 1, "lost item flow was not persisted")


func _test_history_player_projection() -> void:
	var source_before := archived_summary.duplicate(true)
	var model := LongTermModelScript.build_from_snapshot(
		&"profile",
		{"meta_progress_summary": archived_summary},
		&"i3r_out_of_run_player_archive"
	)
	_expect(archived_summary == source_before, "long-term archive projection mutated authoritative progress")
	var runtime := model.get("profile_runtime_panel", {}) as Dictionary
	var module := model.get("current_module", {}) as Dictionary
	var content_module := model.get("current_content_preview", {}) as Dictionary
	_expect(StringName(module.get("state", &"")) == &"archive" and not bool(module.get("preview", true)), "real profile tab is still classified as a placeholder preview")
	_expect(StringName(content_module.get("preview_state", &"")) == &"archive" and not bool(content_module.get("preview", true)), "real profile content framework is still classified as a placeholder preview")
	_expect(str(runtime.get("title", "")) == "角色档案", "profile runtime still exposes an engineering title")
	_expect(StringName(runtime.get("authority", &"")) == &"meta_progress_summary", "profile runtime does not declare its real read authority")
	_expect(not bool(runtime.get("preview", true)), "real character archive is still marked as preview")
	_expect(int(runtime.get("extract_rate_percent", -1)) == 0, "failed-only profile projected the wrong extraction rate")
	_expect(int(runtime.get("history_record_count", 0)) == 1, "profile summary lost the real archive count")
	var cards_by_group := model.get("m7_cards_by_group", {}) as Dictionary
	var history_cards := cards_by_group.get("profile/history", []) as Array
	_expect(history_cards.size() == 1, "profile history did not project the persisted record")
	if history_cards.is_empty():
		return
	var card := history_cards[0] as Dictionary
	_expect(str(card.get("state", "")) == "撤离失败", "capitalized production outcome leaked as engineering text")
	_expect(str(card.get("description", "")).contains("异常体"), "combat defeat reason was not translated into player-facing copy")
	_expect(int(card.get("carried_item_count", -1)) == 2, "archive lost the exact carried-item count")
	_expect(int(card.get("salvaged_item_count", -1)) == 1, "archive lost the exact salvaged-item count")
	_expect(int(card.get("lost_item_count", -1)) == 2, "archive did not combine carried loss and floor loss")
	var facts := card.get("facts", []) as Array
	var fact_text := "\n".join(facts)
	_expect(not facts.is_empty() and str(facts[0]).length() <= 21, "archive timestamp is too long for the player detail column")
	for expected in ["护目镜", "应急压缩饼", "旧零件", "黄铜印章", "止血贴", "黑资损失 17", "锁定收益 6", "金币 +6"]:
		_expect(fact_text.contains(expected), "archive detail omitted player fact: %s" % expected)

	var result_projection := ResultPresentationModelScript.build({
		"outcome": "Failed",
		"terminal_reason_code": &"runtime_combat_defeat",
		"settlement": {"outcome": "failure", "finalized": true},
	})
	_expect(str(result_projection.get("reason_text", "")) == str(card.get("description", "")), "result screen and permanent archive disagree on the same failure reason")


func _test_profile_shell_summary() -> void:
	var shell := LongTermShellScript.new() as LongTermShell
	root.add_child(shell)
	shell.build()
	shell.set_reduced_motion_enabled(true)
	var profile_summary := archived_summary.duplicate(true)
	profile_summary["run_count"] = 5
	profile_summary["extract_count"] = 2
	profile_summary["profile_level"] = 2
	profile_summary["profile_exp"] = 250
	profile_summary["long_term_gold"] = 1234
	profile_summary["gold"] = 1234
	profile_summary["titles"] = ["新进回收员", "矿道行者"]
	shell.apply_snapshot({"meta_progress_summary": profile_summary})
	shell.show_module(&"profile")
	shell.show_secondary(&"history")
	await _frames(3)
	var stat_labels := shell.get("profile_stat_labels") as Array
	_expect((shell.get("profile_role_label") as Label).text == "矿道行者", "character card did not show the real current title")
	_expect((stat_labels[0] as Label).text.contains("5"), "character card did not show total runs")
	_expect((stat_labels[1] as Label).text == "撤离率  40%", "character card did not show the derived extraction rate")
	_expect((stat_labels[2] as Label).text.contains("1"), "character card did not show the permanent archive count")
	_expect((stat_labels[3] as Label).text.contains("1,234"), "character card lost formatted long-term gold")
	_expect(not (shell.get("profile_exp_value_label") as Label).tooltip_text.is_empty(), "experience value does not explain the next progression threshold")
	_expect((shell.get("content_record_body_label") as Label).text.contains("异常体"), "production history detail did not show the failure cause")
	_expect((shell.get("content_record_facts_label") as Label).text.contains("旧零件"), "production history detail did not show salvaged contents")
	root.remove_child(shell)
	shell.queue_free()
	await _frames(2)


func _item(item_id: String, display_name: String) -> Dictionary:
	return {
		"instance_id": "i3r:%s" % item_id,
		"item_id": item_id,
		"display_name": display_name,
		"weight": 1,
	}


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
