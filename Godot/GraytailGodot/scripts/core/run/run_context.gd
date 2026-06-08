extends RefCounted
class_name RunContext

# TruthMap = 真实地图
# IntelMap = 玩家已知情报
# MiniMapViewModel = UI 可读数据
# UI 不得直接读取 TruthMap

var run_id: StringName = &""
var seed_value: int = 0
var truth_map: TruthMap
var intel_map: IntelMap
var minefield_service: MinefieldService
var run_started: bool = false
var width: int = 0
var height: int = 0
var player_pos: Vector2i = Vector2i.ZERO
var current_pos: Vector2i = Vector2i.ZERO
var hp: int = 100
var max_hp: int = 100
var pressure: int = 0
var pending_gold: int = 0
var current_room_type: StringName = &"Unknown"
var current_adjacent_mines: int = 0
var last_message: String = ""
var outcome: String = "Running"
var run_active: bool = false
var extracted: bool = false
var failed: bool = false
var entered_cells: Dictionary = {}
var interacted_cells: Dictionary = {}


func reset() -> void:
	run_id = &""
	seed_value = 0
	truth_map = null
	intel_map = null
	minefield_service = null
	run_started = false
	width = 0
	height = 0
	player_pos = Vector2i.ZERO
	current_pos = Vector2i.ZERO
	hp = 100
	max_hp = 100
	pressure = 0
	pending_gold = 0
	current_room_type = &"Unknown"
	current_adjacent_mines = 0
	last_message = ""
	outcome = "Running"
	run_active = false
	extracted = false
	failed = false
	entered_cells.clear()
	interacted_cells.clear()


func reset_demo_run() -> void:
	reset()
	run_id = &"demo_s1"
	seed_value = 1001
	truth_map = TruthMap.new()
	truth_map.setup_demo_map()
	width = truth_map.width
	height = truth_map.height
	intel_map = IntelMap.new()
	intel_map.setup(width, height)
	minefield_service = MinefieldService.new()
	run_started = true
	player_pos = truth_map.spawn_pos
	current_pos = player_pos
	max_hp = 100
	hp = max_hp
	run_active = true
	last_message = "Demo run started."
	intel_map.reveal_cell(player_pos, truth_map)
	current_room_type = truth_map.get_room_type(player_pos)
	current_adjacent_mines = minefield_service.count_adjacent_mines(truth_map, player_pos)


func is_inside(pos: Vector2i) -> bool:
	return truth_map != null and truth_map.is_inside(pos)


func get_current_pos() -> Vector2i:
	return player_pos


func get_status_snapshot() -> Dictionary:
	return {
		"run_id": run_id,
		"run_started": run_started,
		"width": width,
		"height": height,
		"player_pos": player_pos,
		"hp": hp,
		"max_hp": max_hp,
		"pressure": pressure,
		"pending_gold": pending_gold,
		"position": player_pos,
		"current_room": current_room_type,
		"adjacent_mines": current_adjacent_mines,
		"last_message": last_message,
		"outcome": outcome,
		"run_active": run_active,
		"extracted": extracted,
		"failed": failed,
	}


func cell_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]
