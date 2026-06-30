extends RefCounted
class_name RunBalanceCatalog

# M2 effect-first balance boundary.
# Placeholder numbers live here until a future content/balance table stage replaces them.

const DEFAULT_MAX_HP := 100
const DEFAULT_POWER := 5
const DEFAULT_BACKPACK_CAPACITY := 10
const BASE_MINE_DAMAGE := 30
const MIN_MINE_DAMAGE := 5
const EXPLORE_PRESSURE_DELTA := 2
const MINE_PRESSURE_DELTA := 10
const TRAP_PRESSURE_DELTA := 5
const ALTAR_HP_COST := 10
const ALTAR_BLACK_COIN_REWARD := 8
const ALTAR_HP_COSTS := [10, 15, 25, 35, 50]
const ALTAR_BLACK_COIN_REWARDS := [2, 5, 8, 10, 15]
const TRAP_POWER_REQUIREMENT := 8
const TRAP_FAILURE_DAMAGE := 1
const DICE_BET := 20
const TRADER_TREATMENT_COST := 12
const TRADER_INFO_COST := 6
const TRADER_HIGH_VALUE_CONFIRM_THRESHOLD := 60
const PROTOCOL_PRESSURE_MAX := 100


static func altar_hp_cost_for_stage(stage_index: int) -> int:
	var clamped := clampi(stage_index, 0, ALTAR_HP_COSTS.size() - 1)
	return int(ALTAR_HP_COSTS[clamped])


static func altar_black_coin_reward_for_stage(stage_index: int) -> int:
	var clamped := clampi(stage_index, 0, ALTAR_BLACK_COIN_REWARDS.size() - 1)
	return int(ALTAR_BLACK_COIN_REWARDS[clamped])


static func mine_damage(mine_damage_reduce: int, immune: bool) -> int:
	if immune:
		return 0
	return maxi(MIN_MINE_DAMAGE, BASE_MINE_DAMAGE - mine_damage_reduce)


static func protocol_level_for_pressure(pressure: int) -> int:
	if pressure >= 80:
		return 1
	if pressure >= 60:
		return 2
	if pressure >= 40:
		return 3
	if pressure >= 20:
		return 4
	return 5


static func search_black_coin(context: RunContext, pos: Vector2i, adjacent_mines: int, is_chest: bool) -> int:
	var seed_value := 0 if context == null else context.seed_value
	var turn := 0 if context == null else context.turn
	var base: int = absi((pos.x * 19 + pos.y * 23 + seed_value + turn) % 3)
	if is_chest:
		return mini(11, 3 + absi((pos.x * 29 + pos.y * 11 + seed_value) % 5) + adjacent_mines)
	return mini(4, base + int(floor(float(adjacent_mines) / 2.0)))


static func monster_reward_black_coin(context: RunContext, pos: Vector2i) -> int:
	if context == null:
		return 0
	return absi((pos.x * 13 + pos.y * 7 + context.seed_value) % 4)
