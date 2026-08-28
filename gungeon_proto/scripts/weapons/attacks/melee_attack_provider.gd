class_name MeleeAttackProvider
extends "res://gungeon_proto/scripts/weapons/attacks/weapon_attack_provider.gd"


const MeleeAttackSystemScript = preload(
	"res://gungeon_proto/scripts/weapons/melee/melee_attack_system.gd"
)
const Milestone14CombatScript = preload(
	"res://gungeon_proto/scripts/weapons/melee/milestone14_combat.gd"
)
const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)


func perform_attack(
	player: Node2D,
	weapon: Dictionary,
	aim_direction: Vector2,
	_weapon_system: Node,
	_god_mode: bool
) -> Dictionary:
	var weapon_id: String = str(weapon.get("id", ""))
	if weapon_id == "spear":
		GameAudio.play(player, "spear_thrust", 0.045)
	elif weapon_id == "hammer":
		GameAudio.play(player, "hammer_swing", 0.035)

	Milestone14CombatScript.record_attack_tags(
		player,
		weapon
	)
	MeleeAttackSystemScript.perform_attack(
		player,
		weapon,
		aim_direction
	)

	return {
		"performed": true,
		"cooldown": float(weapon.get("fire_interval", 0.2)),
		"recoil": 0.0,
		"muzzle_flash": 0.0,
	}


func draw_held_weapon(
	player: Node2D,
	weapon: Dictionary,
	aim_direction: Vector2
) -> void:
	var length: float = clampf(
		float(weapon.get("range", 45.0)) * 0.5,
		20.0,
		38.0
	)
	player.draw_line(
		aim_direction * 7.0,
		aim_direction * length,
		Color8(205, 214, 224),
		4.0
	)
