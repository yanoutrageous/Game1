extends RefCounted
class_name CombatState

const BASE_MINE_DAMAGE := 30
const MIN_MINE_DAMAGE := 5


static func apply_damage(context: RunContext, amount: int, reason: String = "") -> int:
	if context == null:
		return 0
	var damage: int = maxi(0, amount)
	context.hp = maxi(0, context.hp - damage)
	if context.hp <= 0:
		context.fail_run(reason if reason != "" else "hp_depleted")
	return damage


static func take_mine_hit(context: RunContext) -> int:
	if context == null:
		return 0
	var damage: int = maxi(MIN_MINE_DAMAGE, BASE_MINE_DAMAGE - context.mine_dmg_reduce)
	if context.mine_immunity > 0:
		context.mine_immunity -= 1
		damage = 0
		context.run_stats["mine_immunity_used"] = int(context.run_stats.get("mine_immunity_used", 0)) + 1
	apply_damage(context, damage, "mine")
	return damage


static func fight_enemy(context: RunContext, pos: Vector2i, adjacent_mines: int) -> Dictionary:
	if context == null:
		return {"ok": false, "message": "No active run."}
	var enemy_state := build_enemy_state(context, pos, adjacent_mines)
	var enemy_power: int = int(enemy_state.get("enemy_power", 0))
	var player_power := context.power
	var damage: int = maxi(0, enemy_power - context.power)
	apply_damage(context, damage, "monster")
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
	var reward_gold: int = preview_reward_gold(context, pos)
	var reward_result := RunRuleService.apply_combat_reward(context, pos, reward_gold)
	context.run_stats["monsters_defeated"] = int(context.run_stats.get("monsters_defeated", 0)) + 1
	context.run_stats["combat_damage"] = int(context.run_stats.get("combat_damage", 0)) + damage
	if int(context.run_stats.get("monster_power_bonus", 0)) < 5:
		context.run_stats["monster_power_bonus"] = int(context.run_stats.get("monster_power_bonus", 0)) + 1
		context.power += 1
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
		"power_gain": int(context.run_stats.get("monster_power_bonus", 0)),
	}


static func build_enemy_state(context: RunContext, pos: Vector2i, adjacent_mines: int) -> Dictionary:
	if context == null:
		return {}
	var enemy_power: int = 4 + adjacent_mines + absi((pos.x * 17 + pos.y * 31 + context.seed_value) % 3)
	return {
		"enemy_name": "Anomaly %d,%d" % [pos.x, pos.y],
		"enemy_power": enemy_power,
		"player_power": context.power,
		"alive": true,
		"cleared": context.truth_map != null and context.truth_map.is_cleared(pos),
	}


static func preview_reward_gold(context: RunContext, pos: Vector2i) -> int:
	if context == null:
		return 0
	return absi((pos.x * 13 + pos.y * 7 + context.seed_value) % 4)


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
