extends RefCounted
class_name G41MonsterCatalog

const TYPE_SLIME := &"slime"
const TYPE_SLIMELING := &"slimeling"
const TYPE_BAT := &"bat"
const TYPE_DRONE := &"drone"


static func definition(monster_type: StringName) -> Dictionary:
	match monster_type:
		TYPE_SLIME:
			return {
				"monster_type": TYPE_SLIME,
				"max_hp": 24,
				"move_speed": 0.18,
				"damage_multiplier": 1.30,
				"attack_radius": 0.20,
				"warning_seconds": 0.75,
				"active_seconds": 0.28,
				"cooldown_seconds": 0.55,
				"split_count": 2,
			}
		TYPE_SLIMELING:
			return {
				"monster_type": TYPE_SLIMELING,
				"max_hp": 9,
				"move_speed": 0.30,
				"damage_multiplier": 0.60,
				"attack_radius": 0.20,
				"warning_seconds": 0.38,
				"active_seconds": 0.18,
				"cooldown_seconds": 0.48,
				"split_count": 0,
			}
		TYPE_BAT:
			return {
				"monster_type": TYPE_BAT,
				"max_hp": 12,
				"move_speed": 0.28,
				"damage_multiplier": 1.0,
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
				"ideal_distance": 0.50,
				"aim_seconds": 0.50,
				"attack_interval": 2.50,
				"laser_seconds": 1.20,
				"laser_tick_seconds": 0.30,
				"laser_turn_speed": 24.0,
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
