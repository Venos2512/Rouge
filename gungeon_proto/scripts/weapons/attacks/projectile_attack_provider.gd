class_name ProjectileAttackProvider
extends "res://gungeon_proto/scripts/weapons/attacks/weapon_attack_provider.gd"


const BulletScript = preload(
	"res://gungeon_proto/scripts/weapons/projectiles/bullet.gd"
)


func perform_attack(
	player: Node2D,
	weapon: Dictionary,
	aim_direction: Vector2,
	weapon_system: Node,
	god_mode: bool
) -> Dictionary:
	var pellet_count: int = int(
		weapon.get(
			"pellets",
			1
		)
	)
	var spread_deg: float = float(
		weapon.get(
			"spread_deg",
			0.0
		)
	)

	for _pellet: int in range(
		pellet_count
	):
		var spread_offset_deg: float = randf_range(
			-spread_deg * 0.5,
			spread_deg * 0.5
		)
		var shot_direction: Vector2 = aim_direction.rotated(
			deg_to_rad(
				spread_offset_deg
			)
		)
		var bullet: Node2D = BulletScript.new() as Node2D

		bullet.set(
			"direction",
			shot_direction
		)
		bullet.set(
			"speed",
			float(weapon.get("bullet_speed", 520.0))
		)
		bullet.set(
			"damage",
			int(weapon.get("damage", 1))
		)
		bullet.set(
			"damage_type",
			StringName(weapon.get("damage_type", "physical"))
		)

		player.get_tree().current_scene.add_child(
			bullet
		)
		bullet.global_position = (
			player.global_position
			+ shot_direction * 17.0
		)

	if not god_mode:
		weapon_system.call(
			"consume_round"
		)

	return {
		"performed": true,
		"cooldown": float(weapon.get("fire_interval", 0.2)),
		"recoil": float(weapon.get("recoil", 0.0)),
		"muzzle_flash": 0.055,
	}


func draw_held_weapon(
	player: Node2D,
	_weapon: Dictionary,
	aim_direction: Vector2
) -> void:
	player.draw_line(
		aim_direction * 7.0,
		aim_direction * 17.0,
		Color8(235, 222, 178),
		4.0
	)

	if float(player.get("muzzle_flash_timer")) > 0.0:
		var muzzle_position: Vector2 = aim_direction * 20.0
		player.draw_circle(
			muzzle_position,
			5.0,
			Color8(255, 215, 95)
		)
		player.draw_circle(
			muzzle_position,
			2.0,
			Color8(255, 250, 220)
		)
