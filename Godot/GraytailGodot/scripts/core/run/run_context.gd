extends RefCounted
class_name RunContext

# TruthMap = real map truth.
# IntelMap = player-known intel.
# UI reads ViewModels/snapshots, never TruthMap directly.

const RunTextCatalogScript := preload("res://scripts/core/run/run_text_catalog.gd")
const RUN_STATE_MACHINE_PATH := "res://scripts/core/run/run_state_machine.gd"

var run_id: StringName = &""
var mode: StringName = &""
var seed_value: int = 0
var phase: StringName = &"idle"
var turn: int = 0
var truth_map: TruthMap
var intel_map: IntelMap
var minefield_service: MinefieldService
var run_started: bool = false
var width: int = 0
var height: int = 0
var player_pos: Vector2i = Vector2i.ZERO
var current_pos: Vector2i = Vector2i.ZERO
var exit_id: StringName = &""
var mine_hits_are_fatal: bool = false
var move_requires_revealed: bool = false
var reveal_on_move: bool = true
var hp: int = 100
var max_hp: int = 100
var power: int = 5
var mine_immunity: int = 0
var mine_dmg_reduce: int = 0
var protocol_pressure_reduce: int = 0
var search_reward_bonus: int = 0
var scan_hint_bonus: int = 0
var pressure: int = 0
var protocol_level: int = 5
var asset_ledger: RunAssetLedger
var query_facade: RunQueryFacade
var run_event_log: RunEventLog
var transaction_log: RunTransactionLog
var rule_pipeline: RunRulePipeline
var content_defs: ContentDefRegistry
var active_command: Dictionary = {}
var pending_gold: int = 0
var safe_gold: int = 0
var parts: int = 0
var carried_items: Array[Dictionary] = []
var encounter_type: StringName = &"none"
var encounter_tags: Array = []
var blocked_reason: String = ""
var current_room_type: StringName = &"Unknown"
var current_adjacent_mines: int = 0
var last_message: String = ""
var last_reward: Dictionary = {}
var event_state: Dictionary = {}
var enemy_state: Dictionary = {}
var outcome: String = "Idle"
var run_active: bool = false
var extracted: bool = false
var failed: bool = false
var abandoned: bool = false
var visited_cells: Dictionary = {}
var explored_cells: Dictionary = {}
var searched_cells: Dictionary = {}
var entered_cells: Dictionary = {}
var interacted_cells: Dictionary = {}
var run_stats: Dictionary = {}
var result_snapshot: Dictionary = {}
var settlement_result: Dictionary = {}
var failure_salvage: Dictionary = {}
var tutorial_triggers: Dictionary = {}
var tutorial_shown: Dictionary = {}
var tutorial_popup: Dictionary = {}
var run_instance_sequence: int = 0
var debug_used: bool = false
var debug_commands: Array[Dictionary] = []
var run_start_config: Dictionary = {}
var profile_fields: Dictionary = {}
var profile_level: int = 1
var profile_exp: int = 0
var permit_level: int = 1
var protocol_difficulty: int = 5
var talent_interface: Array = []
var active_talent_effects: Array = []


func reset() -> void:
	_new_lifecycle_authority().reset_context(self)


func _reset_data() -> void:
	run_id = &""
	mode = &""
	seed_value = 0
	turn = 0
	truth_map = null
	intel_map = null
	minefield_service = null
	run_started = false
	width = 0
	height = 0
	player_pos = Vector2i.ZERO
	current_pos = Vector2i.ZERO
	exit_id = &""
	mine_hits_are_fatal = false
	move_requires_revealed = false
	reveal_on_move = true
	hp = 100
	max_hp = 100
	power = 5
	mine_immunity = 0
	mine_dmg_reduce = 0
	protocol_pressure_reduce = 0
	search_reward_bonus = 0
	scan_hint_bonus = 0
	pressure = 0
	protocol_level = 5
	asset_ledger = null
	query_facade = null
	run_event_log = null
	transaction_log = null
	rule_pipeline = null
	content_defs = null
	active_command.clear()
	pending_gold = 0
	safe_gold = 0
	parts = 0
	carried_items.clear()
	encounter_type = &"none"
	encounter_tags.clear()
	blocked_reason = ""
	current_room_type = &"Unknown"
	current_adjacent_mines = 0
	last_message = ""
	last_reward = {}
	event_state.clear()
	enemy_state.clear()
	outcome = "Idle"
	run_active = false
	extracted = false
	failed = false
	abandoned = false
	visited_cells.clear()
	explored_cells.clear()
	searched_cells.clear()
	entered_cells.clear()
	interacted_cells.clear()
	run_stats.clear()
	result_snapshot.clear()
	settlement_result.clear()
	failure_salvage.clear()
	tutorial_triggers.clear()
	tutorial_shown.clear()
	tutorial_popup.clear()
	debug_used = false
	debug_commands.clear()
	run_start_config.clear()
	profile_fields.clear()
	profile_level = 1
	profile_exp = 0
	permit_level = 1
	protocol_difficulty = 5
	talent_interface.clear()
	active_talent_effects.clear()


func start_run(config: Dictionary) -> void:
	_new_lifecycle_authority().start_run(self, config)


func _initialize_run(config: Dictionary) -> void:
	var command_before_reset := active_command.duplicate(true)
	_reset_data()
	active_command = command_before_reset
	var run_template_id := String(config.get("id", &"run"))
	run_instance_sequence += 1
	var run_nonce := Crypto.new().generate_random_bytes(16).hex_encode()
	run_id = StringName("%s_%d_%d_%s" % [run_template_id, Time.get_ticks_msec(), run_instance_sequence, run_nonce])
	mode = StringName(config.get("mode", &"standard"))
	seed_value = int(config.get("seed", 1001))
	run_event_log = RunEventLog.new()
	transaction_log = RunTransactionLog.new()
	rule_pipeline = RunRulePipeline.new()
	_register_run_modifiers(config)
	content_defs = ContentDefRegistry.new()
	content_defs.setup_defaults()
	run_start_config = config.get("run_start_config", {}).duplicate(true) if config.get("run_start_config", {}) is Dictionary else {}
	profile_fields = config.get("profile_fields", {}).duplicate(true) if config.get("profile_fields", {}) is Dictionary else {}
	profile_level = int(config.get("profile_level", profile_fields.get("profile_level", 1)))
	profile_exp = int(config.get("profile_exp", profile_fields.get("profile_exp", 0)))
	permit_level = int(config.get("permit_level", profile_fields.get("permit_level", 1)))
	protocol_difficulty = int(config.get("protocol_difficulty", profile_fields.get("protocol_difficulty", 5)))
	talent_interface = config.get("talent_interface", []).duplicate(true) if config.get("talent_interface", []) is Array else []
	active_talent_effects = config.get("active_talent_effects", []).duplicate(true) if config.get("active_talent_effects", []) is Array else []
	asset_ledger = RunAssetLedger.new()
	asset_ledger.setup(config)
	query_facade = RunQueryFacade.new()
	truth_map = TruthMap.new()
	truth_map.setup_from_config(config)
	width = truth_map.width
	height = truth_map.height
	intel_map = IntelMap.new()
	intel_map.setup(width, height)
	for visible_exit_pos in truth_map.get_visible_exits(null):
		intel_map.register_visible_exit(visible_exit_pos, truth_map.get_exit_id(visible_exit_pos))
	minefield_service = MinefieldService.new()
	player_pos = truth_map.spawn_pos
	current_pos = player_pos
	max_hp = int(config.get("max_hp", 100))
	hp = max_hp
	power = int(config.get("power", 5))
	mine_immunity = int(config.get("mine_immunity", 0))
	mine_dmg_reduce = int(config.get("mine_dmg_reduce", 0))
	protocol_pressure_reduce = int(config.get("protocol_pressure_reduce", 0))
	search_reward_bonus = int(config.get("search_reward_bonus", 0))
	scan_hint_bonus = int(config.get("scan_hint_bonus", 0))
	protocol_level = int(config.get("protocol_level", config.get("protocol_difficulty", 5)))
	mine_hits_are_fatal = bool(config.get("mine_hits_are_fatal", false))
	move_requires_revealed = bool(config.get("move_requires_revealed", false))
	reveal_on_move = bool(config.get("reveal_on_move", true))
	tutorial_triggers = config.get("tutorial_triggers", {}).duplicate(true)
	RunInventory.setup_stats(self)
	run_started = true
	run_active = true
	extracted = false
	failed = false
	abandoned = false
	outcome = "Running"
	last_message = RunTextCatalogScript.run_started(run_id)
	intel_map.reveal_cell(player_pos, truth_map)
	truth_map.mark_explored(player_pos)
	visited_cells[cell_key(player_pos)] = true
	explored_cells[cell_key(player_pos)] = true
	current_room_type = truth_map.get_room_type(player_pos)
	current_adjacent_mines = minefield_service.count_adjacent_mines(truth_map, player_pos)
	if asset_ledger != null:
		asset_ledger.sync_compat_fields(self)
	record_event(RunEventLog.EVENT_RUN_STARTED, String(active_command.get("command_id", "")), StringName(active_command.get("actor_id", &"system")), "run_context", {"mode": mode, "position": player_pos})


func _register_run_modifiers(config: Dictionary) -> void:
	if rule_pipeline == null:
		return
	var configured_modifiers: Array = config.get("rule_modifiers", [])
	for modifier in configured_modifiers:
		if modifier is Dictionary:
			rule_pipeline.register_modifier(modifier)


func start_tutorial_run() -> void:
	start_run(RunConfig.tutorial_5x5())


func start_standard_run() -> void:
	start_run(RunConfig.standard_10x10())


func reset_demo_run() -> void:
	start_run({
		"id": &"demo_s1",
		"mode": &"demo",
		"seed": 1001,
		"width": 7,
		"height": 7,
		"mine_hits_are_fatal": false,
		"reveal_on_move": true,
		"move_requires_revealed": false,
		"manual_map": {
			"spawn": Vector2i(3, 3),
			"mines": [Vector2i(2, 2), Vector2i(4, 2), Vector2i(5, 5)],
			"events": [Vector2i(5, 1)],
			"monsters": [Vector2i(1, 5)],
			"chests": [Vector2i(1, 1)],
			"exits": [{"pos": Vector2i(6, 6), "exit_id": &"demo_exit", "random_exit": false}],
		},
	})


func is_inside(pos: Vector2i) -> bool:
	return truth_map != null and truth_map.is_inside(pos)


func get_current_pos() -> Vector2i:
	return player_pos


func can_accept_command() -> bool:
	return run_active and not failed and not extracted and not abandoned and phase != &"idle" and not has_blocking_tutorial_popup()


func has_blocking_tutorial_popup() -> bool:
	return not tutorial_popup.is_empty() and bool(tutorial_popup.get("blocking", false))


func fail_run(reason: String) -> void:
	_new_lifecycle_authority().fail_run(self, reason)


func _apply_failure(reason: String) -> void:
	record_event(RunEventLog.EVENT_RUN_FAILED, String(active_command.get("command_id", "")), StringName(active_command.get("actor_id", &"system")), "run_context", {"reason": reason, "position": player_pos})
	var preview := asset_ledger.build_failure_preview() if asset_ledger != null else {}
	settlement_result = preview.duplicate(true)
	failure_salvage = preview.duplicate(true)
	failed = true
	run_active = false
	outcome = "Failed"
	last_message = "Run failed: %s. Select the items to salvage." % reason
	result_snapshot = build_result_snapshot()
	result_snapshot["settlement"] = preview


func confirm_failure_salvage(selected_instance_ids: Array) -> Dictionary:
	var result: Dictionary = _new_lifecycle_authority().confirm_failure_salvage(self, selected_instance_ids)
	if bool(result.get("ok", false)):
		return result.get("settlement", {}).duplicate(true)
	return result


func _settle_failure_salvage(selected_instance_ids: Array) -> Dictionary:
	var settlement := RunRuleService.settle_failure(self, selected_instance_ids)
	if not bool(settlement.get("ok", false)):
		failure_salvage = settlement.duplicate(true)
		last_message = "Salvage selection blocked: %s." % String(settlement.get("reason", "invalid_selection"))
		return settlement
	settlement_result = settlement.duplicate(true)
	failure_salvage = settlement.duplicate(true)
	last_message = "Failure settlement confirmed."
	record_event(&"failure_salvage_confirmed", String(active_command.get("command_id", "")), StringName(active_command.get("actor_id", &"player")), "run_context", {"selected_instance_ids": selected_instance_ids.duplicate(true), "selected_weight": settlement.get("selected_salvage_weight", 0)})
	return settlement


func _finalize_failure_salvage(settlement: Dictionary) -> void:
	result_snapshot = build_result_snapshot()
	result_snapshot["settlement"] = settlement


func complete_extract() -> void:
	_new_lifecycle_authority().complete_extract(self)


func _apply_extract() -> void:
	record_event(RunEventLog.EVENT_EXTRACTION_SUCCESS, String(active_command.get("command_id", "")), StringName(active_command.get("actor_id", &"player")), "command_bus", {"position": player_pos, "exit_id": exit_id})
	var settlement := RunRuleService.settle_success(self)
	settlement_result = settlement.duplicate(true)
	var extracted_pending := int(settlement.get("black_coin_converted", 0))
	extracted = true
	run_active = false
	outcome = "Extracted" if mode != &"tutorial" else "Training Complete"
	result_snapshot = build_result_snapshot()
	result_snapshot["extracted_pending_gold"] = extracted_pending
	result_snapshot["settlement"] = settlement


func abandon_run(reason: String = "player_abandoned") -> void:
	_new_lifecycle_authority().abandon_run(self, reason)


func _apply_abandon(reason: String = "player_abandoned") -> void:
	record_event(&"run_abandoned", String(active_command.get("command_id", "")), StringName(active_command.get("actor_id", &"player")), "run_context", {"reason": reason, "position": player_pos})
	var settlement := RunRuleService.settle_abandon(self, reason)
	settlement_result = settlement.duplicate(true)
	abandoned = true
	run_active = false
	outcome = "Abandoned"
	last_message = "Run abandoned: %s." % reason
	result_snapshot = build_result_snapshot()
	result_snapshot["settlement"] = settlement


func build_result_snapshot() -> Dictionary:
	return _query().build_result_snapshot(self)


func get_status_snapshot() -> Dictionary:
	return _query().build_status_snapshot(self)


func get_run_flow_snapshot() -> Dictionary:
	return _query().build_run_flow_snapshot(self)


func get_search_state_label() -> String:
	return _query().get_search_state_label(self)


func get_search_state_data() -> Dictionary:
	return _query().get_search_state_data(self)


func record_event(event_type: StringName, command_id: String = "", actor_id: StringName = &"player", source: String = "", payload: Dictionary = {}) -> Dictionary:
	if run_event_log == null:
		run_event_log = RunEventLog.new()
	return run_event_log.record_event(event_type, command_id, actor_id, source, payload)


func record_debug_command(command: String, payload: Dictionary = {}) -> Dictionary:
	debug_used = true
	var entry := {
		"command": command,
		"payload": _json_safe(payload),
		"command_id": String(active_command.get("command_id", "")),
		"source": String(active_command.get("source", payload.get("source", "debug"))),
		"index": debug_commands.size() + 1,
	}
	debug_commands.append(entry)
	return entry.duplicate(true)


func cell_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]


func _query() -> RunQueryFacade:
	if query_facade == null:
		query_facade = RunQueryFacade.new()
	return query_facade


func _new_lifecycle_authority():
	var state_machine_script := load(RUN_STATE_MACHINE_PATH)
	return state_machine_script.new()


func _json_safe(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		var dict_value := value as Dictionary
		for key in dict_value.keys():
			result[str(key)] = _json_safe(dict_value[key])
		return result
	if value is Array:
		var result: Array = []
		var array_value := value as Array
		for item in array_value:
			result.append(_json_safe(item))
		return result
	if value is Vector2i:
		var pos := value as Vector2i
		return {"x": pos.x, "y": pos.y}
	if value is Vector2:
		var vector := value as Vector2
		return {"x": vector.x, "y": vector.y}
	if value is StringName:
		return str(value)
	return value
