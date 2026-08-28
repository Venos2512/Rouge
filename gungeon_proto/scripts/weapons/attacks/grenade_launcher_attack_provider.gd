class_name GrenadeLauncherAttackProvider
extends "res://gungeon_proto/scripts/weapons/attacks/weapon_attack_provider.gd"


const GrenadeProjectile = preload(
	"res://gungeon_proto/scripts/weapons/projectiles/player_grenade.gd"
)


func perform_attack(
	player: Node2D,
	weapon: Dictionary,
	aim_direction: Vector2,
	weapon_system: Node,
	god_mode: bool
) -> Dictionary:
	var grenade: Node2D = GrenadeProjectile.new() as Node2D
	grenade.set("direction", aim_direction)
	grenade.set("speed", float(weapon.get("bullet_speed", 330.0)))
	grenade.set("damage", int(weapon.get("damage", 5)))
	grenade.set(
		"damage_type",
		StringName(weapon.get("damage_type", "physical"))
	)
	grenade.set(
		"lifetime",
		float(weapon.get("projectile_lifetime", 1.1))
	)
	grenade.set(
		"explosion_radius",
		float(weapon.get("explosion_radius", 78.0))
	)
	grenade.set(
		"explosion_knockback",
		float(weapon.get("explosion_knockback", 220.0))
	)

	player.get_tree().current_scene.add_child(grenade)
	grenade.global_position = player.global_position + aim_direction * 19.0

	if not god_mode:
		weapon_system.call("consume_round")

	return {
		"performed": true,
		"cooldown": float(weapon.get("fire_interval", 0.9)),
		"recoil": float(weapon.get("recoil", 8.0)),
		"muzzle_flash": 0.075,
	}


func draw_held_weapon(
	player: Node2D,
	_weapon: Dictionary,
	aim_direction: Vector2
) -> void:
	var side: Vector2 = aim_direction.orthogonal()
	player.draw_line(
		aim_direction * 5.0,
		aim_direction * 18.0,
		Color8(93, 67, 44),
		5.0
	)
	player.draw_line(
		side * 9.0 + aim_direction * 10.0,
		-side * 9.0 + aim_direction * 10.0,
		Color8(206, 151, 61),
		3.0
	)

	if float(player.get("muzzle_flash_timer")) > 0.0:
		player.draw_circle(
			aim_direction * 21.0,
			6.0,
			Color8(255, 151, 48)
		)
