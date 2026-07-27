extends SceneTree

const DEPLOY_TAB_IDS: Array[StringName] = [
	&"map",
	&"warehouse",
	&"claim",
	&"objective",
	&"loadout",
]
const LONG_TERM_MODULE_IDS: Array[StringName] = [
	&"task_archive",
	&"codex",
	&"research",
	&"talent",
	&"profile",
	&"collection_appearance",
]
const DEV_ONLY_ROOT_NAMES := {
	&"DebugToggleButton": true,
	&"DebugOperationPanel": true,
	&"DevDiagnosticsPanel": true,
}
const LEAK_RULES := [
	{
		"id": "engineering_zh",
		"pattern": "(占位|后置|壳层|工程|调试|测试(?:用|中|版|入口|面板)?|开发(?:用|中|版|入口|面板)?|未实现|未接入|尚未接入|待接入|后续接入|接口|字段预览|只读展示|操作反馈|操作完成|运行状态|当前选择)",
	},
	{
		"id": "engineering_en",
		"pattern": "(?i)(\\bplaceholder\\b|\\bpreview(?:_only)?\\b|\\bdebug\\b|\\btest(?:ing)?\\b|\\bschema\\b|\\bstub\\b|\\bmock\\b|\\bprototype\\b|\\bdev[_ -]?only\\b|\\bdisplay[_ -]?only\\b|\\bread[_ -]?only\\b|\\bruntime\\b|\\binterface\\b|\\badapter\\b|\\bpipeline\\b|\\bcontract\\b|\\bframework\\b|\\bsnapshot\\b|\\broute\\b|\\bcommandbus\\b|\\bmetaprogress\\b|\\bcontentdb\\b|\\bhistoryrecordsnapshot\\b|\\bsettlementsnapshot\\b|\\btexture2d\\b|\\bwarehouse_items\\b|\\battack_(?:windup|active|recovery)\\b|res://)",
	},
	{
		"id": "stage_codename",
		"pattern": "(?i)(^|[^a-z0-9])((?:G|M|I)[0-9]+(?:R[0-9]*)?|ART[0-9]+(?:R[0-9]*)?)([^a-z0-9]|$)",
	},
]

var failures: Array[String] = []
var leaks: Array[Dictionary] = []
var seen_leaks: Dictionary = {}
var compiled_rules: Array[Dictionary] = []
var checked_fragments := 0
var checked_states := 0
var excluded_dev_roots := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_compile_rules()
	if not failures.is_empty():
		_finish()
		return

	# Load the production scene after autoloads enter the tree. RunScene resolves
	# the SettingsManager autoload identifier while compiling.
	var main_scene := load("res://scenes/main/main.tscn") as PackedScene
	_require(main_scene != null, "production main scene is unavailable")
	if main_scene == null:
		_finish()
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	for _index in range(4):
		await process_frame

	var run_scene := main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing")
	if run_scene == null:
		main.free()
		_finish()
		return
	var app_shell := run_scene.get("ui_shell") as Control
	var main_menu := run_scene.get("main_menu_panel") as Control
	var deploy := run_scene.get("deploy_shell_panel") as Control
	var long_term := run_scene.get("long_term_shell_panel") as Control
	_require(app_shell != null, "production AppShell is missing")
	_require(main_menu != null, "production MainMenuShell is missing")
	_require(deploy != null, "production DeployPrepShell is missing")
	_require(long_term != null, "production LongTermShell is missing")

	_check_dev_only_gates(run_scene)
	_check_player_runtime_copy_gate(run_scene)
	if app_shell != null and main_menu != null:
		app_shell.call("show_main")
		await process_frame
		_scan_surface(main_menu, "main")

	if deploy != null:
		deploy.call("set_reduced_motion_enabled", true)
		deploy.call("set_page_active", false)
		for tab_id in DEPLOY_TAB_IDS:
			deploy.call("show_tab", tab_id)
			await process_frame
			_scan_surface(deploy, "deploy/%s" % String(tab_id))

	if long_term != null:
		long_term.call("set_reduced_motion_enabled", true)
		long_term.call("set_page_active", false)
		for module_id in LONG_TERM_MODULE_IDS:
			long_term.call("show_module", module_id)
			await process_frame
			var secondary_ids: Array = long_term.call("get_secondary_ids", module_id)
			if secondary_ids.is_empty():
				_scan_surface(long_term, "long_term/%s" % String(module_id))
				continue
			for secondary_id_variant in secondary_ids:
				var secondary_id := StringName(secondary_id_variant)
				long_term.call("show_secondary", secondary_id)
				await process_frame
				_scan_surface(
					long_term,
					"long_term/%s/%s" % [String(module_id), String(secondary_id)]
				)

	if app_shell != null:
		var settings_opened := bool(app_shell.call("show_settings"))
		_require(settings_opened, "production settings route did not open")
		await process_frame
		var settings := app_shell.get("settings_panel") as Control
		_require(settings != null, "production SettingsPanel is missing")
		if settings != null:
			_scan_surface(settings, "settings")
			_scan_popup_items(settings, "settings")

	await _materialize_run_surfaces(run_scene)
	for entry in [
		["run", run_scene.get("run_surface") as Control],
		["runtime_settings", run_scene.get("runtime_settings_panel") as Control],
		["inventory", run_scene.get("inventory_panel") as Control],
		["map", run_scene.get("map_overlay_panel") as Control],
		["result", run_scene.get("result_panel") as Control],
		["tutorial", run_scene.get("tutorial_popup_panel") as Control],
		["loot_result", run_scene.get("loot_panel") as Control],
	]:
		var surface_name := String(entry[0])
		var surface := entry[1] as Control
		_require(surface != null, "%s production surface is missing" % surface_name)
		if surface != null:
			_scan_surface(surface, surface_name)

	var room_runtime_view := run_scene.get("room_runtime_view") as Node
	_require(room_runtime_view != null, "production room runtime view is missing")
	if room_runtime_view != null:
		var context_popup := room_runtime_view.get("context_popup") as Control
		_require(context_popup != null, "production world context popup is missing")
		if context_popup != null:
			_scan_surface(context_popup, "world_popup")
		var door_prompt := room_runtime_view.get_node_or_null("DoorPrompt") as Control
		if door_prompt != null:
			_scan_surface(door_prompt, "world_door_prompt")

	main.free()
	await process_frame
	await process_frame
	_finish()


func _compile_rules() -> void:
	for definition in LEAK_RULES:
		var regex := RegEx.new()
		var error := regex.compile(String(definition.get("pattern", "")))
		if error != OK:
			failures.append("leak rule %s did not compile: %s" % [definition.get("id", ""), error])
			continue
		compiled_rules.append({
			"id": String(definition.get("id", "")),
			"regex": regex,
		})


func _check_dev_only_gates(run_scene: Node) -> void:
	for root_name_variant in DEV_ONLY_ROOT_NAMES.keys():
		var root_name := StringName(root_name_variant)
		var node := _find_descendant_named(run_scene, root_name)
		_require(node != null, "expected dev-only root %s is missing" % String(root_name))
		if node == null:
			continue
		excluded_dev_roots += 1
		if node is CanvasItem:
			_require(
				not (node as CanvasItem).visible,
				"dev-only root %s is player-visible" % String(root_name)
			)


func _check_player_runtime_copy_gate(run_scene: Node) -> void:
	var player := run_scene.get("player_controller") as Node
	_require(player != null, "production PlayerController is missing")
	if player == null:
		return
	var state_label := player.get_node_or_null("PromptAnchor/RuntimeState") as Label
	_require(state_label != null, "player RuntimeState diagnostic label is missing")
	if state_label == null:
		return
	for state in [&"attack_windup", &"attack_active", &"attack_recovery", &"hurt", &"dead"]:
		player.call("set_runtime_visual_state", state)
		if state_label.visible:
			_check_fragment(
				"world_player/%s" % String(state),
				"PromptAnchor/RuntimeState",
				"text",
				state_label.text
			)
			failures.append("internal player combat state %s is player-visible" % String(state))
	player.call("set_runtime_visual_state", &"idle")


func _materialize_run_surfaces(run_scene: Node) -> void:
	var item := {
		"instance_id": "i3r_copy_probe_item",
		"item_id": "i3r_copy_probe_item",
		"display_name": "旧矿区急救包",
		"item_type": "consumable",
		"rarity": &"tier_3",
		"weight": 2,
		"quantity": 1,
		"short_description": "恢复少量生命，带入探索会占用背包容量。",
		"base_value": 16,
		"can_consume": true,
	}
	var inventory := run_scene.get("inventory_panel") as Control
	if inventory != null:
		inventory.call("apply_snapshot", {
			"inventory_items": [item],
			"equipped_items": [],
			"backpack_used": 2,
			"backpack_capacity": 10,
			"black_coin": 3,
			"gold_coin": 8,
		})
		inventory.call("show_panel")
	var result := run_scene.get("result_panel") as Control
	if result != null:
		result.call("show_summary", {
			"outcome": "Extracted",
			"persistence_state": &"committed",
			"normal_exit_allowed": true,
			"settlement": {
				"outcome": "success",
				"warehouse_items": [item],
				"room_floor_lost_items": [],
				"cleared_consumables": [],
				"black_coin_converted": 3,
				"safe_yield_retained": 8,
				"gold_coin_gained": 11,
			},
		})
	var map_overlay := run_scene.get("map_overlay_panel") as Control
	if map_overlay != null:
		map_overlay.call("show_overlay")
		map_overlay.call("show_open_feedback", &"keyboard")
	var tutorial := run_scene.get("tutorial_popup_panel") as Control
	if tutorial != null:
		tutorial.call("apply_popup", {
			"id": &"i3r_copy_probe",
			"title": "搜索与回收",
			"message": "靠近箱子或地面物资即可查看内容；确认后拾取。",
			"blocking": true,
			"confirm_text": "继续",
			"confirm_action": &"ui_accept",
			"confirm_action_hint": {"display_label": "Enter / A"},
		})
	var room_runtime_view := run_scene.get("room_runtime_view") as Node
	if room_runtime_view != null:
		var popup := room_runtime_view.get("context_popup") as Control
		if popup != null:
			popup.call("apply_context", {
				"interaction_kind": &"ground_loot",
				"world_pos": Vector2(640, 360),
				"player_world_pos": Vector2(620, 360),
				"room_bounds": Rect2(300, 0, 980, 720),
				"gameplay_focus_rect": Rect2(300, 0, 980, 560),
				"reserved_rects": [],
				"items": [item],
				"inventory_items": [],
				"backpack_remaining": 10,
			})
	await process_frame
	await process_frame


func _scan_surface(surface: Control, surface_name: String) -> void:
	checked_states += 1
	_scan_node(surface, surface, surface_name)


func _scan_node(node: Node, surface: Control, surface_name: String) -> void:
	if _is_dev_only_node(node):
		return
	var relative_path := String(surface.get_path_to(node))
	if node is RichTextLabel:
		_check_fragment(surface_name, relative_path, "rich_text", (node as RichTextLabel).text)
	elif node is Label:
		_check_fragment(surface_name, relative_path, "text", (node as Label).text)
	elif node is Button:
		_check_fragment(surface_name, relative_path, "text", (node as Button).text)
	elif node is LineEdit:
		var line_edit := node as LineEdit
		_check_fragment(surface_name, relative_path, "text", line_edit.text)
		_check_fragment(surface_name, relative_path, "placeholder_text", line_edit.placeholder_text)
	elif node is TextEdit:
		var text_edit := node as TextEdit
		_check_fragment(surface_name, relative_path, "text", text_edit.text)
		_check_fragment(surface_name, relative_path, "placeholder_text", text_edit.placeholder_text)
	elif node is ItemList:
		var item_list := node as ItemList
		for index in range(item_list.item_count):
			_check_fragment(
				surface_name,
				relative_path,
				"item_%d" % index,
				item_list.get_item_text(index)
			)
	elif node is TabBar:
		var tab_bar := node as TabBar
		for index in range(tab_bar.tab_count):
			_check_fragment(
				surface_name,
				relative_path,
				"tab_%d" % index,
				tab_bar.get_tab_title(index)
			)
	if node is Control:
		_check_fragment(
			surface_name,
			relative_path,
			"tooltip",
			(node as Control).tooltip_text
		)
	if node is OptionButton:
		var option := node as OptionButton
		for index in range(option.item_count):
			_check_fragment(
				surface_name,
				relative_path,
				"option_%d" % index,
				option.get_item_text(index)
			)
	elif node is MenuButton:
		_scan_popup_menu((node as MenuButton).get_popup(), surface_name, relative_path)
	for child in node.get_children():
		_scan_node(child, surface, surface_name)


func _scan_popup_items(surface: Control, surface_name: String) -> void:
	for node in _descendants(surface):
		if node is OptionButton:
			var option := node as OptionButton
			_scan_popup_menu(
				option.get_popup(),
				surface_name,
				String(surface.get_path_to(option))
			)
		elif node is MenuButton:
			var menu_button := node as MenuButton
			_scan_popup_menu(
				menu_button.get_popup(),
				surface_name,
				String(surface.get_path_to(menu_button))
			)


func _scan_popup_menu(menu: PopupMenu, surface_name: String, owner_path: String) -> void:
	if menu == null:
		return
	for index in range(menu.item_count):
		_check_fragment(
			surface_name,
			owner_path,
			"popup_item_%d" % index,
			menu.get_item_text(index)
		)


func _check_fragment(surface_name: String, node_path: String, source_kind: String, value: String) -> void:
	var text := value.strip_edges()
	if text.is_empty():
		return
	checked_fragments += 1
	for definition in compiled_rules:
		var regex := definition.get("regex") as RegEx
		if regex == null or regex.search(text) == null:
			continue
		var key := "%s|%s|%s|%s|%s" % [
			surface_name,
			node_path,
			source_kind,
			definition.get("id", ""),
			text,
		]
		if seen_leaks.has(key):
			continue
		seen_leaks[key] = true
		leaks.append({
			"surface": surface_name,
			"path": node_path,
			"source": source_kind,
			"rule": String(definition.get("id", "")),
			"text": text,
		})


func _is_dev_only_node(node: Node) -> bool:
	var cursor: Node = node
	while cursor != null:
		if DEV_ONLY_ROOT_NAMES.has(StringName(cursor.name)):
			return true
		cursor = cursor.get_parent()
	return false


func _find_descendant_named(node: Node, target_name: StringName) -> Node:
	if StringName(node.name) == target_name:
		return node
	for child in node.get_children():
		var match_node := _find_descendant_named(child, target_name)
		if match_node != null:
			return match_node
	return null


func _descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child in node.get_children():
		result.append_array(_descendants(child))
	return result


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if not leaks.is_empty():
		for leak in leaks:
			push_error(
				"I3R player-copy leak [%s] %s %s (%s): %s"
				% [
					leak.get("surface", ""),
					leak.get("path", ""),
					leak.get("source", ""),
					leak.get("rule", ""),
					leak.get("text", ""),
				]
			)
		failures.append("%d player-visible engineering-copy leaks remain" % leaks.size())
	if failures.is_empty():
		print(
			"I3R_PLAYER_COPY_LEAKAGE=PASS states=%d fragments=%d dev_only_excluded=%d leaks=0"
			% [checked_states, checked_fragments, excluded_dev_roots]
		)
		quit(0)
		return
	for failure in failures:
		push_error("I3R player-copy leakage: " + failure)
	print(
		"I3R_PLAYER_COPY_LEAKAGE=FAIL failures=%d leaks=%d states=%d fragments=%d dev_only_excluded=%d"
		% [
			failures.size(),
			leaks.size(),
			checked_states,
			checked_fragments,
			excluded_dev_roots,
		]
	)
	quit(1)
