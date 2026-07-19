extends RefCounted
class_name G41RuntimeVisualContract

# Program-owned contract for art-authored visual children. Gameplay code addresses
# stable states and anchors only; it never depends on a texture's dimensions.

const PLAYER_STATES := [&"idle", &"move", &"attack_windup", &"attack_active", &"attack_recovery", &"hurt", &"dead"]
const CHEST_STATES := [&"closed", &"opening", &"opened"]
const GROUND_LOOT_STATES := [&"idle", &"focused", &"pickup", &"blocked"]
const MELEE_MONSTER_STATES := [&"idle", &"move", &"warning", &"active", &"cooldown", &"hurt", &"dead", &"split"]
const RANGED_MONSTER_STATES := [&"idle", &"move", &"aim", &"fire", &"cooldown", &"hurt", &"dead"]
const PROJECTILE_STATES := [&"spawn", &"active", &"hit", &"despawn"]

const REQUIRED_ANCHORS := [
	&"VisualRoot",
	&"BodyAnchor",
	&"PromptAnchor",
	&"HealthBarAnchor",
	&"AttackOrigin",
	&"ProjectileOrigin",
	&"LootSpawnAnchor",
	&"ShadowAnchor",
]

const VISUAL_KEYS := {
	&"player": &"runtime.player.default",
	&"chest": &"runtime.chest.default",
	&"ground_loot": &"runtime.ground_loot.default",
	&"slime": &"runtime.monster.slime",
	&"slimeling": &"runtime.monster.slimeling",
	&"bat": &"runtime.monster.bat",
	&"drone": &"runtime.monster.drone",
	&"projectile": &"runtime.projectile.default",
	&"laser": &"runtime.laser.default",
}


static func states_for(subject: StringName) -> Array:
	match subject:
		&"player":
			return PLAYER_STATES.duplicate()
		&"chest":
			return CHEST_STATES.duplicate()
		&"ground_loot":
			return GROUND_LOOT_STATES.duplicate()
		&"slime", &"slimeling":
			return MELEE_MONSTER_STATES.duplicate()
		&"bat", &"drone":
			return RANGED_MONSTER_STATES.duplicate()
		&"projectile":
			return PROJECTILE_STATES.duplicate()
	return []


static func supports_state(subject: StringName, state: StringName) -> bool:
	return state in states_for(subject)


static func visual_key_for(subject: StringName) -> StringName:
	return StringName(VISUAL_KEYS.get(subject, &"runtime.missing"))


static func build_contract_snapshot() -> Dictionary:
	return {
		"contract_id": &"g41.runtime_visual.v1",
		"anchors": REQUIRED_ANCHORS.duplicate(),
		"states": {
			&"player": PLAYER_STATES.duplicate(),
			&"chest": CHEST_STATES.duplicate(),
			&"ground_loot": GROUND_LOOT_STATES.duplicate(),
			&"slime": MELEE_MONSTER_STATES.duplicate(),
			&"slimeling": MELEE_MONSTER_STATES.duplicate(),
			&"bat": RANGED_MONSTER_STATES.duplicate(),
			&"drone": RANGED_MONSTER_STATES.duplicate(),
			&"projectile": PROJECTILE_STATES.duplicate(),
		},
		"visual_keys": VISUAL_KEYS.duplicate(true),
		"collision_depends_on_texture_size": false,
		"missing_visual_policy": &"program_placeholder",
	}
