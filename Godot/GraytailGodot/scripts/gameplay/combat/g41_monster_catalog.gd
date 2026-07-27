extends RefCounted
class_name G41MonsterCatalog

const TYPE_SLIME := &"slime"
const TYPE_SLIMELING := &"slimeling"
const TYPE_BAT := &"bat"
const TYPE_DRONE := &"drone"
const ENTRY_GRACE_SECONDS := 0.45


static func definition(monster_type: StringName) -> Dictionary:
	match monster_type:
		TYPE_SLIME:
			return {
				"monster_type": TYPE_SLIME,
				"max_hp": 24,
				"move_speed": 0.18,
				"damage_multiplier": 1.30,
				"body_radius": 0.036,
				"attack_radius": 0.20,
				"idle_seconds": 1.10,
				"warning_seconds": 0.75,
				"active_seconds": 0.28,
				"cooldown_seconds": 0.55,
				"split_count": 2,
				"split_power_multiplier": 0.45,
			}
		TYPE_SLIMELING:
			return {
				"monster_type": TYPE_SLIMELING,
				"max_hp": 9,
				"move_speed": 0.30,
				"damage_multiplier": 0.60,
				"body_radius": 0.023,
				"attack_radius": 0.20,
				"idle_seconds": 1.10,
				"warning_seconds": 0.75,
				"active_seconds": 0.28,
				"cooldown_seconds": 0.55,
				"split_count": 0,
			}
		TYPE_BAT:
			return {
				"monster_type": TYPE_BAT,
				"max_hp": 12,
				"move_speed": 0.28,
				"damage_multiplier": 1.0,
				"body_radius": 0.038,
				"ideal_distance": 0.34,
				"aim_seconds": 0.50,
				"attack_interval": 1.50,
				"spread_count": 3,
				"spread_half_angle_degrees": 25.0,
			}
		TYPE_DRONE:
			return {
				"monster_type": TYPE_DRONE,
				"max_hp": 28,
				"move_speed": 0.10,
				"damage_multiplier": 1.50,
				"body_radius": 0.034,
				"ideal_distance": 0.50,
				"aim_seconds": 0.50,
				"attack_interval": 2.50,
				"laser_seconds": 1.20,
				"laser_tick_seconds": 0.30,
				"laser_turn_speed_degrees": 24.0,
				"dash_seconds": 0.50,
				"dash_speed_multiplier": 2.0,
			}
	return {}


static func default_encounter() -> Array[StringName]:
	return [TYPE_SLIME, TYPE_BAT, TYPE_DRONE]


static func all_runtime_types() -> Array[StringName]:
	return [TYPE_SLIME, TYPE_SLIMELING, TYPE_BAT, TYPE_DRONE]


static func base_damage(_player_power: int, monster_type: StringName) -> int:
	var multiplier := float(definition(monster_type).get("damage_multiplier", 1.0))
	return maxi(1, int(round(5.0 * multiplier)))


static func damage_for_power(enemy_power: int, monster_type: StringName) -> int:
	var damage_base := maxi(4, maxi(0, enemy_power) / 3)
	var multiplier := float(definition(monster_type).get("damage_multiplier", 1.0))
	return maxi(1, int(round(float(damage_base) * multiplier)))


static func runtime_profile(monster_type: StringName, enemy_power: int, enemy_name: String) -> Dictionary:
	var monster_definition := definition(monster_type)
	var clamped_power := maxi(0, enemy_power)
	return {
		"monster_type": monster_type,
		"enemy_name": enemy_name,
		"enemy_power": clamped_power,
		"max_hp": int(monster_definition.get("max_hp", 1)) + clamped_power,
		"damage": damage_for_power(clamped_power, monster_type),
	}


static func pick_type_for_cell(run_seed: int, pos: Vector2i, _adjacent_mines: int = 0) -> StringName:
	var hash := ((run_seed & 0xffffffff) * 2654435761) & 0xffffffff
	hash = (hash ^ (((int(pos.x) & 0xffffffff) * 73856093) & 0xffffffff)) & 0xffffffff
	hash = (hash ^ (((int(pos.y) & 0xffffffff) * 19349663) & 0xffffffff)) & 0xffffffff
	match hash % 3:
		0:
			return TYPE_SLIME
		1:
			return TYPE_BAT
		_:
			return TYPE_DRONE
