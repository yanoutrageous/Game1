extends RefCounted
class_name RunContext

# TruthMap = real map truth.
# IntelMap = player-known intel.
# UI reads ViewModels/snapshots, never TruthMap directly.

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
var pressure: int = 0
var protocol_level: int = 5
var asset_ledger: RunAssetLedger
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
var visited_cells: Dictionary = {}
var explored_cells: Dictionary = {}
var searched_cells: Dictionary = {}
var entered_cells: Dictionary = {}
var interacted_cells: Dictionary = {}
var run_stats: Dictionary = {}
var result_snapshot: Dictionary = {}
var failure_salvage: Dictionary = {}
var tutorial_triggers: Dictionary = {}
var tutorial_shown: Dictionary = {}
var tutorial_popup: Dictionary = {}


func reset() -> void:
	run_id = &""
	mode = &""
	seed_value = 0
	phase = &"idle"
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
	pressure = 0
	protocol_level = 5
	asset_ledger = null
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
	visited_cells.clear()
	explored_cells.clear()
	searched_cells.clear()
	entered_cells.clear()
	interacted_cells.clear()
	run_stats.clear()
	result_snapshot.clear()
	failure_salvage.clear()
	tutorial_triggers.clear()
	tutorial_shown.clear()
	tutorial_popup.clear()


func start_run(config: Dictionary) -> void:
	reset()
	run_id = StringName(config.get("id", &"run"))
	mode = StringName(config.get("mode", &"standard"))
	seed_value = int(config.get("seed", 1001))
	phase = &"running"
	asset_ledger = RunAssetLedger.new()
	asset_ledger.setup(config)
	truth_map = TruthMap.new()
	truth_map.setup_from_config(config)
	width = truth_map.width
	height = truth_map.height
	intel_map = IntelMap.new()
	intel_map.setup(width, height)
	minefield_service = MinefieldService.new()
	player_pos = truth_map.spawn_pos
	current_pos = player_pos
	max_hp = int(config.get("max_hp", 100))
	hp = max_hp
	power = int(config.get("power", 5))
	mine_hits_are_fatal = bool(config.get("mine_hits_are_fatal", false))
	move_requires_revealed = bool(config.get("move_requires_revealed", false))
	reveal_on_move = bool(config.get("reveal_on_move", true))
	tutorial_triggers = config.get("tutorial_triggers", {}).duplicate(true)
	RunInventory.setup_stats(self)
	run_started = true
	run_active = true
	extracted = false
	failed = false
	outcome = "Running"
	last_message = "Run started: %s." % String(run_id)
	intel_map.reveal_cell(player_pos, truth_map)
	truth_map.mark_explored(player_pos)
	visited_cells[cell_key(player_pos)] = true
	explored_cells[cell_key(player_pos)] = true
	current_room_type = truth_map.get_room_type(player_pos)
	current_adjacent_mines = minefield_service.count_adjacent_mines(truth_map, player_pos)
	if asset_ledger != null:
		asset_ledger.sync_compat_fields(self)


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
	return run_active and not failed and not extracted and phase != &"idle" and not has_blocking_tutorial_popup()


func has_blocking_tutorial_popup() -> bool:
	return not tutorial_popup.is_empty() and bool(tutorial_popup.get("blocking", false))


func fail_run(reason: String) -> void:
	var settlement := RunRuleService.settle_failure(self)
	failure_salvage = settlement.duplicate(true)
	failed = true
	run_active = false
	phase = &"failed"
	outcome = "Failed"
	last_message = "Run failed: %s." % reason
	result_snapshot = build_result_snapshot()


func complete_extract() -> void:
	var settlement := RunRuleService.settle_success(self)
	var extracted_pending := int(settlement.get("black_coin_converted", 0))
	extracted = true
	run_active = false
	phase = &"extracted"
	outcome = "Extracted" if mode != &"tutorial" else "Training Complete"
	result_snapshot = build_result_snapshot()
	result_snapshot["extracted_pending_gold"] = extracted_pending
	result_snapshot["settlement"] = settlement


func build_result_snapshot() -> Dictionary:
	var ledger_snapshot := _asset_snapshot()
	return {
		"outcome": outcome,
		"mode": mode,
		"position": player_pos,
		"hp": hp,
		"max_hp": max_hp,
		"power": power,
		"pressure": pressure,
		"protocol_level": protocol_level,
		"black_coin": ledger_snapshot.get("black_coin", pending_gold),
		"gold_coin": ledger_snapshot.get("gold_coin", safe_gold),
		"pending_gold": pending_gold,
		"safe_gold": safe_gold,
		"parts": parts,
		"backpack_capacity": ledger_snapshot.get("backpack_capacity", 0),
		"backpack_used": ledger_snapshot.get("backpack_used", 0),
		"backpack_remaining": ledger_snapshot.get("backpack_remaining", 0),
		"carried_item_count": carried_items.size(),
		"carried_item_value": RunInventory.get_carried_item_value(self),
		"carried_items": carried_items.duplicate(true),
		"inventory_items": ledger_snapshot.get("inventory_items", []),
		"equipped_items": ledger_snapshot.get("equipped_items", []),
		"room_floor_items": ledger_snapshot.get("room_floor_items", []),
		"room_floor_item_count": ledger_snapshot.get("room_floor_item_count", 0),
		"warehouse_lite": ledger_snapshot.get("warehouse_lite", []),
		"settlement_log": ledger_snapshot.get("settlement_log", []),
		"status_effects": ledger_snapshot.get("status_effects", []),
		"failure_salvage": failure_salvage.duplicate(true),
		"stats": run_stats.duplicate(true),
		"final_room": current_room_type,
		"encounter_type": encounter_type,
		"encounter_tags": encounter_tags.duplicate(true),
		"blocked_reason": blocked_reason,
		"turn": turn,
	}


func get_status_snapshot() -> Dictionary:
	var ledger_snapshot := _asset_snapshot()
	return {
		"run_id": run_id,
		"mode": mode,
		"phase": phase,
		"run_started": run_started,
		"width": width,
		"height": height,
		"player_pos": player_pos,
		"hp": hp,
		"max_hp": max_hp,
		"power": power,
		"pressure": pressure,
		"protocol_level": protocol_level,
		"black_coin": ledger_snapshot.get("black_coin", pending_gold),
		"gold_coin": ledger_snapshot.get("gold_coin", safe_gold),
		"pending_gold": pending_gold,
		"safe_gold": safe_gold,
		"parts": parts,
		"backpack_capacity": ledger_snapshot.get("backpack_capacity", 0),
		"backpack_used": ledger_snapshot.get("backpack_used", 0),
		"backpack_remaining": ledger_snapshot.get("backpack_remaining", 0),
		"inventory_items": ledger_snapshot.get("inventory_items", []),
		"equipped_items": ledger_snapshot.get("equipped_items", []),
		"room_floor_items": ledger_snapshot.get("room_floor_items", []),
		"room_floor_item_count": ledger_snapshot.get("room_floor_item_count", 0),
		"warehouse_lite": ledger_snapshot.get("warehouse_lite", []),
		"settlement_log": ledger_snapshot.get("settlement_log", []),
		"status_effects": ledger_snapshot.get("status_effects", []),
		"position": player_pos,
		"current_room": current_room_type,
		"encounter_type": encounter_type,
		"encounter_tags": encounter_tags.duplicate(true),
		"blocked_reason": blocked_reason,
		"adjacent_mines": current_adjacent_mines,
		"search_state": get_search_state_label(),
		"search_state_data": get_search_state_data(),
		"event_state": event_state.duplicate(true),
		"enemy_state": enemy_state.duplicate(true),
		"last_message": last_message,
		"last_reward": last_reward.duplicate(true),
		"outcome": outcome,
		"run_active": run_active,
		"extracted": extracted,
		"failed": failed,
		"exit_id": exit_id,
		"tutorial_popup": tutorial_popup.duplicate(true),
		"result_snapshot": result_snapshot.duplicate(true),
		"failure_salvage": failure_salvage.duplicate(true),
		"stats": run_stats.duplicate(true),
	}


func get_search_state_label() -> String:
	if searched_cells.has(cell_key(player_pos)):
		return "searched"
	match current_room_type:
		&"Normal":
			return "searchable"
		&"Chest":
			return "chest"
		_:
			return "blocked"


func get_search_state_data() -> Dictionary:
	if truth_map == null:
		return {"can_search": false, "searched": false, "reason": "not_ready", "is_chest": false}
	var key := cell_key(player_pos)
	var searched := searched_cells.has(key)
	var can_search := false
	var reason := "blocked"
	var is_chest := false
	if searched:
		reason = "searched"
	elif player_pos == truth_map.spawn_pos:
		reason = "spawn"
	elif current_room_type == &"Normal":
		can_search = true
		reason = "searchable"
	elif current_room_type == &"Chest":
		can_search = true
		reason = "chest"
		is_chest = true
	elif current_room_type == &"Event":
		reason = "event"
	elif current_room_type == &"Monster":
		reason = "monster"
	elif current_room_type == &"Exit":
		reason = "exit"
	elif current_room_type == &"Mine":
		reason = "mine"
	return {
		"can_search": can_search,
		"searched": searched,
		"reason": reason,
		"is_chest": is_chest,
	}


func cell_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]


func _asset_snapshot() -> Dictionary:
	if asset_ledger == null:
		return {}
	return asset_ledger.get_public_snapshot(player_pos)
