extends RefCounted
class_name CombatState

const BASE_MINE_DAMAGE := 30
const MIN_MINE_DAMAGE := 5


static func apply_damage(context: RunContext, amount: int, reason: String = "") -> int:
	if context == null:
		return 0
	var damage := max(0, amount)
	context.hp = max(0, context.hp - damage)
	if context.hp <= 0:
		context.fail_run(reason if reason != "" else "hp_depleted")
	return damage


static func take_mine_hit(context: RunContext) -> int:
	if context == null:
		return 0
	var damage := max(MIN_MINE_DAMAGE, BASE_MINE_DAMAGE - context.mine_dmg_reduce)
	if context.mine_immunity > 0:
		context.mine_immunity -= 1
		damage = 0
		context.run_stats["mine_immunity_used"] = int(context.run_stats.get("mine_immunity_used", 0)) + 1
	apply_damage(context, damage, "mine")
	return damage


static func fight_enemy(context: RunContext, pos: Vector2i, adjacent_mines: int) -> Dictionary:
	if context == null:
		return {"ok": false, "message": "No active run."}
	var enemy_power := 4 + adjacent_mines + abs((pos.x * 17 + pos.y * 31 + context.seed_value) % 3)
	var damage := max(0, enemy_power - context.power)
	apply_damage(context, damage, "monster")
	var reward_gold := abs((pos.x * 13 + pos.y * 7 + context.seed_value) % 4)
	context.pending_gold += reward_gold
	context.run_stats["monsters_defeated"] = int(context.run_stats.get("monsters_defeated", 0)) + 1
	context.run_stats["combat_damage"] = int(context.run_stats.get("combat_damage", 0)) + damage
	if int(context.run_stats.get("monster_power_bonus", 0)) < 5:
		context.run_stats["monster_power_bonus"] = int(context.run_stats.get("monster_power_bonus", 0)) + 1
		context.power += 1
	return {
		"ok": true,
		"enemy_power": enemy_power,
		"damage": damage,
		"reward_gold": reward_gold,
	}
