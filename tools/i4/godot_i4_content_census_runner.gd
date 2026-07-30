extends SceneTree

const DebugScenarioCatalogScript := preload("res://scripts/core/debug/debug_scenario_catalog.gd")
const DeployTabModelScript := preload("res://scripts/ui/deploy_prep/deploy_tab_model.gd")
const LongTermContentFrameworkScript := preload("res://scripts/ui/long_term/long_term_content_framework.gd")
const TruthMapScript := preload("res://scripts/core/map/truth_map.gd")

const PASS_MARKER := "I4_CONTENT_CENSUS=PASS"
const FAIL_MARKER := "I4_CONTENT_CENSUS=FAIL"
const MAIN_SCENE := "res://scenes/main/main.tscn"
const ASSET_MANIFEST := "res://data/assets/asset_manifest.csv"
const DEFAULT_OUTPUT := "user://tests/i4_content_census/content_census.json"
const SUMMARY_PAGES := [&"overview", &"config", &"effect", &"objective"]
const ROOM_TYPES := [
	TruthMapScript.ROOM_NORMAL,
	TruthMapScript.ROOM_MINE,
	TruthMapScript.ROOM_MONSTER,
	TruthMapScript.ROOM_CHEST,
	TruthMapScript.ROOM_EVENT,
	TruthMapScript.ROOM_EXIT,
]

var failures: Array[String] = []
var rows: Array[Dictionary] = []
var output_path := DEFAULT_OUTPUT
var source_mode := "worktree"
var commit_id := ""
var tree_id := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_read_arguments()
	_require(ResourceLoader.exists(MAIN_SCENE), "production main.tscn is not loadable")
	_add_main_and_settings_rows()
	_add_deploy_rows()
	_add_long_term_rows()
	_add_long_term_asset_rows()
	_add_in_run_rows()
	_add_modal_and_result_rows()
	_add_debug_scenario_rows()
	_validate_rows()
	var report := _build_report()
	var write_ok := _write_report(report)
	_require(write_ok, "could not write census report")
	if failures.is_empty():
		var summary := report.get("summary", {}) as Dictionary
		var marker_format := (
			"%s rows=%d deploy_tabs=%d deploy_filters=%d summaries=%d "
			+ "long_term_modules=%d long_term_pages=%d long_term_assets=%d "
			+ "room_types=%d scenarios=%d output=%s"
		)
		print(marker_format % [
			PASS_MARKER,
			rows.size(),
			int(summary.get("deploy_tabs", 0)),
			int(summary.get("deploy_filters", 0)),
			int(summary.get("deploy_summaries", 0)),
			int(summary.get("long_term_modules", 0)),
			int(summary.get("long_term_pages", 0)),
			int(summary.get("long_term_assets", 0)),
			int(summary.get("room_types", 0)),
			int(summary.get("scenarios", 0)),
			output_path,
		])
		quit(0)
		return
	for failure in failures:
		printerr("%s:%s" % [FAIL_MARKER, failure])
	quit(1)


func _read_arguments() -> void:
	for raw_argument in OS.get_cmdline_user_args():
		var argument := String(raw_argument)
		if argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
		elif argument.begins_with("--source-mode="):
			source_mode = argument.trim_prefix("--source-mode=")
		elif argument.begins_with("--commit="):
			commit_id = argument.trim_prefix("--commit=")
		elif argument.begins_with("--tree="):
			tree_id = argument.trim_prefix("--tree=")


func _add_main_and_settings_rows() -> void:
	_add_row(
		"main_menu/default",
		"main.tscn → 主菜单",
		"default_profile/clean",
		"main_menu_primary",
		[&"focus_restore", &"transition"],
		"Godot/GraytailGodot/tests/art21_main_menu_runtime_runner.gd",
		&"main_menu"
	)
	_add_row(
		"settings/general",
		"main.tscn → 主菜单 → 设置",
		"default_profile/settings",
		"settings_primary",
		[&"modal", &"focus_restore", &"save_failure"],
		"Godot/GraytailGodot/tests/i4_debug_sandbox_runner.gd",
		&"settings"
	)


func _add_deploy_rows() -> void:
	for raw_tab in DeployTabModelScript.build_tabs():
		var tab := raw_tab as Dictionary
		var tab_id := StringName(tab.get("id", &""))
		var layout_class := &"deploy_map_split" if tab_id == DeployTabModelScript.TAB_MAP else &"deploy_equal_split"
		var filters := tab.get("secondary_filters", []) as Array
		_require(not String(tab_id).is_empty(), "Deploy tab has an empty id")
		_require(not filters.is_empty(), "Deploy tab %s has no public filter" % String(tab_id))
		for raw_filter in filters:
			var filter := raw_filter as Dictionary
			var filter_id := StringName(filter.get("id", &""))
			_add_row(
				"deploy/%s/filter/%s" % [String(tab_id), String(filter_id)],
				"main.tscn → 出发探索 → %s → %s" % [
					String(tab.get("label", tab_id)),
					String(filter.get("label", filter_id)),
				],
				"deploy/current_registry/%s/%s" % [String(tab_id), String(filter_id)],
				String(layout_class),
				_deploy_risks(tab_id),
				"Godot/GraytailGodot/tests/i4_deploy_information_layout_runner.gd",
				&"deploy_filter",
				{"tab_id": String(tab_id), "filter_id": String(filter_id)}
			)
	for summary_id in SUMMARY_PAGES:
		_add_row(
			"deploy/summary/%s" % String(summary_id),
			"main.tscn → 出发探索 → 出发摘要 → %s" % String(summary_id),
			"deploy/summary_extreme/%s" % String(summary_id),
			"deploy_summary_scroll",
			[&"long_text", &"max_numeric", &"overflow", &"scroll_end", &"ui_150"],
			"Godot/GraytailGodot/tests/i4_deploy_information_layout_runner.gd",
			&"deploy_summary",
			{"summary_id": String(summary_id)}
		)


func _deploy_risks(tab_id: StringName) -> Array[StringName]:
	var risks: Array[StringName] = [&"long_text", &"max_numeric", &"overflow", &"scroll_end", &"ui_150"]
	if tab_id in [DeployTabModelScript.TAB_WAREHOUSE, DeployTabModelScript.TAB_CLAIM]:
		risks.append(&"domain_rejection")
		risks.append(&"save_failure")
	if tab_id == DeployTabModelScript.TAB_LOADOUT:
		risks.append(&"focus_restore")
	return risks


func _add_long_term_rows() -> void:
	var modules := LongTermContentFrameworkScript.build_modules()
	for raw_module in modules:
		var module := raw_module as Dictionary
		var module_id := StringName(module.get("module_id", &""))
		_add_row(
			"long_term/module/%s" % String(module_id),
			"main.tscn → 长期系统 → %s" % String(module.get("display_name", module_id)),
			"long_term/current/%s" % String(module_id),
			"long_term_module",
			[&"transition", &"focus_restore", &"ui_150"],
			"Godot/GraytailGodot/tests/i4_long_term_navigation_runner.gd",
			&"long_term_module",
			{"module_id": String(module_id)}
		)
		for raw_group in module.get("secondary_groups", []) as Array:
			var group := raw_group as Dictionary
			var group_id := StringName(group.get("group_id", &""))
			_add_row(
				"long_term/page/%s/%s" % [String(module_id), String(group_id)],
				"main.tscn → 长期系统 → %s → %s" % [
					String(module.get("display_name", module_id)),
					String(group.get("title", group_id)),
				],
				"long_term/current/%s/%s" % [String(module_id), String(group_id)],
				"long_term_secondary_page",
				[&"long_text", &"overflow", &"scroll_end", &"focus_restore", &"ui_150"],
				"Godot/GraytailGodot/tests/i4_long_term_navigation_runner.gd",
				&"long_term_page",
				{"module_id": String(module_id), "page_id": String(group_id)}
			)


func _add_long_term_asset_rows() -> void:
	var file := FileAccess.open(ASSET_MANIFEST, FileAccess.READ)
	if file == null:
		failures.append("asset manifest could not be opened")
		return
	var headers := file.get_csv_line(",")
	var header_index := {}
	for index in range(headers.size()):
		header_index[String(headers[index])] = index
	for required_header in [
		"asset_id",
		"godot_path",
		"linked_scene",
		"theme_key",
		"state",
		"variant",
		"source_status",
	]:
		_require(header_index.has(required_header), "asset manifest lacks %s" % required_header)
	while not file.eof_reached():
		var values := file.get_csv_line(",")
		if values.is_empty() or String(values[0]).is_empty():
			continue
		var asset_id := _csv_value(values, header_index, "asset_id")
		if not asset_id.begins_with("ui.art23.long_term."):
			continue
		if (
			_csv_value(values, header_index, "linked_scene") != "scripts/ui/long_term/long_term_shell.gd"
			or _csv_value(values, header_index, "source_status")
			!= "i3r_current_generated_from_audited_source"
		):
			continue
		var godot_path := _csv_value(values, header_index, "godot_path")
		_require(ResourceLoader.exists(godot_path), "LongTerm runtime asset is not loadable: %s" % godot_path)
		_add_row(
			"long_term/asset/%s" % asset_id,
			"main.tscn → 长期系统 → 运行资产 %s" % asset_id,
			"asset_manifest/%s/%s" % [
				_csv_value(values, header_index, "state"),
				_csv_value(values, header_index, "variant"),
			],
			"long_term_runtime_asset",
			[&"missing_asset", &"transition"],
			"Godot/GraytailGodot/data/assets/asset_manifest.csv",
			&"long_term_asset",
			{
				"asset_id": asset_id,
				"godot_path": godot_path,
				"theme_key": _csv_value(values, header_index, "theme_key"),
				"consumer": _csv_value(values, header_index, "linked_scene"),
			}
		)


func _csv_value(values: PackedStringArray, header_index: Dictionary, key: String) -> String:
	var index := int(header_index.get(key, -1))
	return String(values[index]) if index >= 0 and index < values.size() else ""


func _add_in_run_rows() -> void:
	var surfaces := [
		["hud", "局内 → HUD", "run_hud", [&"max_numeric", &"ui_150"]],
		["minimap", "局内 → 折叠小地图", "run_minimap", [&"missing_asset", &"ui_150"]],
		["map_overlay", "局内 → 展开地图", "run_map_overlay", [&"modal", &"focus_restore", &"ui_150"]],
		["inventory", "局内 → 背包", "run_inventory_modal", [&"overflow", &"scroll_end", &"modal", &"focus_restore"]],
		["ground_loot", "局内 → 地面掉落与就地拾取", "run_ground_loot_world", [&"missing_asset", &"domain_rejection", &"transition"]],
		["interaction", "局内 → 世界交互提示", "run_world_interaction", [&"long_text", &"transition"]],
		["quick_bag_empty", "局内 → 左下物品簇 → 空包", "run_quick_bag", [&"ui_150"]],
		["quick_bag_one", "局内 → 左下物品簇 → 1 件", "run_quick_bag", [&"long_text", &"ui_150"]],
		["quick_bag_three", "局内 → 左下物品簇 → 3 件", "run_quick_bag", [&"overflow", &"ui_150"]],
		["quick_bag_overflow", "局内 → 左下物品簇 → 4 件/满包", "run_quick_bag", [&"overflow", &"scroll_end", &"ui_150"]],
	]
	for surface in surfaces:
		_add_row(
			"run/surface/%s" % String(surface[0]),
			String(surface[1]),
			"run/current/%s" % String(surface[0]),
			String(surface[2]),
			surface[3] as Array,
			"Godot/GraytailGodot/tests/i4_in_run_visual_physics_runner.gd",
			&"run_surface"
		)
	for room_type in ROOM_TYPES:
		_add_row(
			"run/room/%s" % String(room_type).to_lower(),
			"main.tscn → 确认出发 → %s 房" % String(room_type),
			"scenario/room_type/%s" % String(room_type),
			"run_room",
			[&"missing_asset", &"transition", &"domain_rejection"],
			"Godot/GraytailGodot/tests/i4_in_run_visual_physics_runner.gd",
			&"room_type",
			{"room_type": String(room_type)}
		)


func _add_modal_and_result_rows() -> void:
	var modals := [
		["pause", "局内 → 暂停", "run_pause_modal", [&"modal", &"focus_restore"]],
		["settings", "局内 → 暂停 → 设置", "run_settings_modal", [&"modal", &"focus_restore", &"save_failure"]],
		["confirm", "生产动作 → 二次确认", "production_confirm_modal", [&"modal", &"focus_restore", &"domain_rejection"]],
		["failure", "保存/领域拒绝 → 失败提示", "failure_modal", [&"modal", &"save_failure", &"domain_rejection"]],
	]
	for modal in modals:
		_add_row(
			"modal/%s" % String(modal[0]),
			String(modal[1]),
			"modal/current/%s" % String(modal[0]),
			String(modal[2]),
			modal[3] as Array,
			"Godot/GraytailGodot/tests/i2_runtime_modal_priority_runner.gd",
			&"modal"
		)
	var outcomes := [
		["success", "局内 → 撤离成功 → 结算", [&"transition"]],
		["failure", "局内 → 探索失败 → 结算", [&"transition", &"domain_rejection"]],
		["abandon", "局内/Deploy → 放弃 → 结算", [&"modal", &"transition"]],
		["save_failure", "结算 → 保存失败", [&"save_failure", &"domain_rejection", &"modal"]],
	]
	for outcome in outcomes:
		_add_row(
			"result/%s" % String(outcome[0]),
			String(outcome[1]),
			"result/current/%s" % String(outcome[0]),
			"result_panel",
			outcome[2] as Array,
			"Godot/GraytailGodot/tests/i3_production_terminal_branches_runner.gd",
			&"result"
		)


func _add_debug_scenario_rows() -> void:
	for scenario in DebugScenarioCatalogScript.all():
		var scenario_id := StringName(scenario.get("id", &""))
		for taint_state in [&"clean", &"tainted"]:
			for panel_state in [&"collapsed", &"expanded"]:
				var risks: Array[StringName] = [&"debug_overlay", &"focus_restore", &"ui_150"]
				if taint_state == &"tainted":
					risks.append(&"save_failure")
				if panel_state == &"expanded":
					risks.append(&"modal")
				_add_row(
					"debug/%s/%s/%s" % [
						String(scenario_id),
						String(taint_state),
						String(panel_state),
					],
					"main.tscn → 设置 → 开发与测试 → %s" % String(scenario.get("label", scenario_id)),
					"debug/%s/seed_%d/%s/%s" % [
						String(scenario_id),
						int(scenario.get("seed", 0)),
						String(taint_state),
						String(panel_state),
					],
					"debug_production_overlay",
					risks,
					"Godot/GraytailGodot/tests/i4_debug_sandbox_runner.gd",
					&"debug_scenario",
					{
						"scenario_id": String(scenario_id),
						"seed": int(scenario.get("seed", 0)),
						"taint_state": String(taint_state),
						"panel_state": String(panel_state),
					}
				)


func _add_row(
	state_id: String,
	public_entry_path: String,
	fixture: String,
	layout_class: String,
	risk_flags: Array,
	evidence_path: String,
	category: StringName,
	extra: Dictionary = {}
) -> void:
	var normalized_risks: Array[String] = []
	for risk in risk_flags:
		normalized_risks.append(String(risk))
	var row := {
		"state_id": state_id,
		"category": String(category),
		"public_entry_path": public_entry_path,
		"fixture": fixture,
		"layout_class": layout_class,
		"risk_flags": normalized_risks,
		"evidence_path": evidence_path,
		"route_status": "production_or_same-source_test_route",
	}
	for key in extra.keys():
		row[key] = extra[key]
	rows.append(row)


func _validate_rows() -> void:
	var ids := {}
	for row in rows:
		var state_id := String(row.get("state_id", ""))
		_require(not state_id.is_empty(), "census row has an empty state_id")
		_require(not ids.has(state_id), "duplicate census state_id: %s" % state_id)
		ids[state_id] = true
		for key in ["public_entry_path", "fixture", "layout_class", "evidence_path"]:
			_require(not String(row.get(key, "")).is_empty(), "%s lacks %s" % [state_id, key])
		_require(row.get("risk_flags", []) is Array, "%s risk_flags is not an array" % state_id)
	var summary := _summary()
	_require(int(summary.get("deploy_tabs", 0)) == 5, "Deploy tab census is not 5")
	_require(int(summary.get("deploy_summaries", 0)) == 4, "Deploy summary census is not 4")
	_require(int(summary.get("long_term_modules", 0)) == 6, "LongTerm module census is not 6")
	_require(int(summary.get("long_term_pages", 0)) == 25, "LongTerm page census is not 25")
	_require(int(summary.get("long_term_assets", 0)) == 58, "LongTerm asset census is not 58")
	_require(int(summary.get("room_types", 0)) == 6, "room-type census is not 6")
	_require(int(summary.get("scenarios", 0)) == 6, "debug scenario census is not 6")
	_require(int(summary.get("debug_states", 0)) == 24, "debug scenario state census is not 24")


func _summary() -> Dictionary:
	var deploy_tabs := {}
	var scenarios := {}
	for row in rows:
		if String(row.get("category", "")) == "deploy_filter":
			deploy_tabs[String(row.get("tab_id", ""))] = true
		if String(row.get("category", "")) == "debug_scenario":
			scenarios[String(row.get("scenario_id", ""))] = true
	return {
		"total_rows": rows.size(),
		"deploy_tabs": deploy_tabs.size(),
		"deploy_filters": _count_category(&"deploy_filter"),
		"deploy_summaries": _count_category(&"deploy_summary"),
		"long_term_modules": _count_category(&"long_term_module"),
		"long_term_pages": _count_category(&"long_term_page"),
		"long_term_assets": _count_category(&"long_term_asset"),
		"room_types": _count_category(&"room_type"),
		"scenarios": scenarios.size(),
		"debug_states": _count_category(&"debug_scenario"),
		"high_risk_rows": _count_high_risk_rows(),
	}


func _count_category(category: StringName) -> int:
	var count := 0
	for row in rows:
		if StringName(row.get("category", &"")) == category:
			count += 1
	return count


func _count_high_risk_rows() -> int:
	var count := 0
	for row in rows:
		if not (row.get("risk_flags", []) as Array).is_empty():
			count += 1
	return count


func _build_report() -> Dictionary:
	return {
		"schema_version": 1,
		"standard_id": "I4-QA-FROZEN-1",
		"status": "PASS" if failures.is_empty() else "FAIL",
		"source_mode": source_mode,
		"commit": commit_id,
		"tree": tree_id,
		"production_scene": MAIN_SCENE,
		"registry_sources": [
			"DeployTabModel.build_tabs",
			"LongTermContentFramework.build_modules",
			"data/assets/asset_manifest.csv",
			"DebugScenarioCatalog.all",
			"TruthMap room-type constants",
		],
		"summary": _summary(),
		"failures": failures.duplicate(),
		"rows": rows.duplicate(true),
	}


func _write_report(report: Dictionary) -> bool:
	var parent := output_path.get_base_dir()
	if not parent.is_empty():
		var absolute_parent := ProjectSettings.globalize_path(parent)
		if DirAccess.make_dir_recursive_absolute(absolute_parent) != OK and not DirAccess.dir_exists_absolute(absolute_parent):
			return false
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(report, "\t") + "\n")
	return true


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
