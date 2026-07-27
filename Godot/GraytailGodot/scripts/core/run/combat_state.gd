extends RefCounted
class_name CombatState

const RunStateMachineScript := preload("res://scripts/core/run/run_state_machine.gd")
const RunBalanceCatalogScript := preload("res://scripts/core/run/run_balance_catalog.gd")
const RunEffectApplierScript := preload("res://scripts/core/run/run_effect_applier.gd")

const BASE_MINE_DAMAGE := RunBalanceCatalogScript.BASE_MINE_DAMAGE
const MIN_MINE_DAMAGE := RunBalanceCatalogScript.MIN_MINE_DAMAGE
const ENEMY_POWER_MIN := 5
const ENEMY_POWER_MAX := 20
const MONSTER_REWARD_MIN := 0
const MONSTER_REWARD_MAX := 3
const MONSTER_POWER_GAIN_PER_CLEAR := 1
const MONSTER_POWER_GAIN_CAP := 5
const ENEMY_NAMES := [
	"滞留工偶",
	"空壳巡工",
	"失控搬运机",
	"头灯哨卫",
	"管道清理机",
]


static func apply_damage(context: RunContext, amount: int, reason: String = "", fail_authority = null) -> int:
	if context == null:
		return 0
	var damage: int = maxi(0, amount)
	RunEffectApplierScript.apply_damage(context, damage, reason if reason != "" else "hp_depleted", fail_authority)
	return damage


static func take_mine_hit(context: RunContext, fail_authority = null) -> int:
	if context == null:
		return 0
	var immune := context.mine_immunity > 0
	var damage: int = RunBalanceCatalogScript.mine_damage(context.mine_dmg_reduce, immune)
	if context.mine_immunity > 0:
		context.mine_immunity -= 1
		context.run_stats["mine_immunity_used"] = int(context.run_stats.get("mine_immunity_used", 0)) + 1
	apply_damage(context, damage, "mine", fail_authority)
	return damage


static func fight_enemy(context: RunContext, pos: Vector2i, adjacent_mines: int, fail_authority = null) -> Dictionary:
	if context == null:
		return {"ok": false, "message": "No active run."}
	var enemy_state := build_enemy_state(context, pos, adjacent_mines)
	var enemy_power: int = int(enemy_state.get("enemy_power", 0))
	var player_power := context.power
	var damage: int = maxi(0, enemy_power - context.power)
	apply_damage(context, damage, "monster", fail_authority)
	if context.failed:
		context.run_stats["combat_damage"] = int(context.run_stats.get("combat_damage", 0)) + damage
		return {
			"ok": true,
			"fought": true,
			"cleared": false,
			"player_win": false,
			"player_power": player_power,
			"enemy_power": enemy_power,
			"damage": damage,
			"hp": context.hp,
			"reward_gold": 0,
			"black_coin_delta": 0,
		}
	var reward_gold := reward_gold_for_enemy_power(enemy_power)
	var reward_result := RunRuleService.apply_combat_reward(context, pos, reward_gold)
	context.run_stats["combat_damage"] = int(context.run_stats.get("combat_damage", 0)) + damage
	var power_gain := grant_monster_clear_progress(context)
	return {
		"ok": true,
		"fought": true,
		"cleared": true,
		"player_win": player_power >= enemy_power,
		"player_power": player_power,
		"enemy_power": enemy_power,
		"damage": damage,
		"hp": context.hp,
		"reward_gold": reward_gold,
		"black_coin_delta": reward_result.get("black_coin_delta", reward_gold),
		"power_gain": power_gain,
	}


static func build_enemy_state(context: RunContext, pos: Vector2i, adjacent_mines: int) -> Dictionary:
	if context == null:
		return {}
	var identity_hash := enemy_identity_hash(context.seed_value, pos)
	var power_span := ENEMY_POWER_MAX - ENEMY_POWER_MIN + 1
	var base_power := ENEMY_POWER_MIN + identity_hash % power_span
	var adjacent_power_bonus := maxi(0, adjacent_mines) * 2
	var enemy_power := base_power + adjacent_power_bonus
	return {
		"identity_hash": identity_hash,
		"enemy_name": String(ENEMY_NAMES[identity_hash % ENEMY_NAMES.size()]),
		"base_power": base_power,
		"adjacent_power_bonus": adjacent_power_bonus,
		"adjacent_mines": adjacent_mines,
		"enemy_power": enemy_power,
		"player_power": context.power,
		"alive": true,
		"cleared": context.truth_map != null and context.truth_map.is_cleared(pos),
	}


static func enemy_identity_hash(run_seed: int, pos: Vector2i) -> int:
	var raw_hash := int(pos.x) * 131 + int(pos.y) * 97 + run_seed * 41
	return ((raw_hash % 1000) + 1000) % 1000


static func reward_gold_for_enemy_power(enemy_power: int) -> int:
	var span := MONSTER_REWARD_MAX - MONSTER_REWARD_MIN + 1
	return MONSTER_REWARD_MIN + (maxi(0, enemy_power) % span if span > 0 else 0)


static func grant_monster_clear_progress(context: RunContext) -> int:
	if context == null:
		return 0
	context.run_stats["monsters_defeated"] = int(context.run_stats.get("monsters_defeated", 0)) + 1
	var current_bonus := int(context.run_stats.get("monster_power_bonus", 0))
	var power_gain := mini(MONSTER_POWER_GAIN_PER_CLEAR, maxi(0, MONSTER_POWER_GAIN_CAP - current_bonus))
	if power_gain > 0:
		context.run_stats["monster_power_bonus"] = current_bonus + power_gain
		context.power += power_gain
	return power_gain


static func preview_reward_gold(context: RunContext, pos: Vector2i) -> int:
	if context == null:
		return 0
	var adjacent_mines := context.current_adjacent_mines
	if context.truth_map != null and context.minefield_service != null:
		adjacent_mines = context.minefield_service.count_adjacent_mines(context.truth_map, pos)
	var enemy_state := build_enemy_state(context, pos, adjacent_mines)
	return reward_gold_for_enemy_power(int(enemy_state.get("enemy_power", 0)))


static func build_monster_summary(context: RunContext, pos: Vector2i, adjacent_mines: int) -> Dictionary:
	if context == null:
		return {}
	var enemy_state := build_enemy_state(context, pos, adjacent_mines)
	var enemy_power := int(enemy_state.get("enemy_power", 0))
	var player_power := int(enemy_state.get("player_power", 0))
	var expected_damage := maxi(0, enemy_power - player_power)
	var survives := context.hp > expected_damage
	var cleared := bool(enemy_state.get("cleared", false))
	var power_gain_available := int(context.run_stats.get("monster_power_bonus", 0)) < 5 and not cleared and survives
	return {
		"monster_id": "monster_%d_%d" % [pos.x, pos.y],
		"display_name": String(enemy_state.get("enemy_name", "Anomaly")),
		"tags": [&"monster_basic", &"combat_basic", &"melee_basic"],
		"base_power": 4 + adjacent_mines,
		"current_power": enemy_power,
		"enemy_power": enemy_power,
		"player_power": player_power,
		"cleared": cleared,
		"alive": not cleared,
		"reward_preview": build_combat_reward_preview(context, pos, power_gain_available, survives),
		"risk_summary": build_combat_risk_summary(context, pos, adjacent_mines),
		"codex_ref": "future_codex_monster_basic",
	}


static func build_combat_reward_preview(context: RunContext, pos: Vector2i, power_gain_available: bool = false, reward_available: bool = true) -> Dictionary:
	return {
		"black_coin": preview_reward_gold(context, pos) if reward_available else 0,
		"items": "none",
		"power_gain": 1 if power_gain_available else 0,
		"blocked_if_defeated": not reward_available,
	}


static func build_combat_risk_summary(context: RunContext, pos: Vector2i, adjacent_mines: int) -> Dictionary:
	if context == null:
		return {}
	var enemy_state := build_enemy_state(context, pos, adjacent_mines)
	var enemy_power := int(enemy_state.get("enemy_power", 0))
	var player_power := int(enemy_state.get("player_power", 0))
	return {
		"hp_loss": maxi(0, enemy_power - player_power),
		"enemy_power": enemy_power,
		"player_power": player_power,
		"adjacent_danger": adjacent_mines,
	}


static func _fail_run(context: RunContext, reason: String, fail_authority = null) -> Dictionary:
	var fail_reason := reason if reason != "" else "hp_depleted"
	if fail_authority != null and fail_authority.has_method("fail_run"):
		return fail_authority.fail_run(fail_reason)
	var fallback_state_machine = RunStateMachineScript.new()
	return fallback_state_machine.fail_run(context, fail_reason)
