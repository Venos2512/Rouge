class_name CrossbowAttackProvider
extends "res://gungeon_proto/scripts/weapons/attacks/weapon_attack_provider.gd"

const ArrowProjectileScript = preload("res://gungeon_proto/scripts/weapons/projectiles/arrow_projectile.gd")


func perform_attack(player: Node2D, weapon: Dictionary, aim_direction: Vector2, weapon_system: Node, god_mode: bool) -> Dictionary:
	var arrow: Node2D = ArrowProjectileScript.new() as Node2D
	arrow.set("direction", aim_direction)
	arrow.set("speed", float(weapon.get("bullet_speed", 720.0)))
	arrow.set("damage", int(weapon.get("damage", 4)))
	arrow.set("damage_type", StringName(weapon.get("damage_type", "physical")))
	arrow.set("lifetime", float(weapon.get("projectile_lifetime", 1.6)))
	player.get_tree().current_scene.add_child(arrow)
	arrow.global_position = player.global_position + aim_direction * 20.0
	if not god_mode:
		weapon_system.call("consume_round")
	return {
		"performed": true,
		"cooldown": float(weapon.get("fire_interval", 0.72)),
		"recoil": float(weapon.get("recoil", 3.5)),
		"muzzle_flash": 0.0,
	}


func draw_held_weapon(player: Node2D, _weapon: Dictionary, aim_direction: Vector2) -> void:
	var side: Vector2 = aim_direction.orthogonal()
	var bow_center: Vector2 = aim_direction * 15.0
	player.draw_line(aim_direction * 5.0, aim_direction * 20.0, Color8(126, 79, 43), 4.0)
	player.draw_line(bow_center - side * 8.0, bow_center + side * 8.0, Color8(214, 185, 116), 3.0)
	player.draw_line(bow_center - side * 8.0, aim_direction * 20.0, Color8(225, 225, 210), 1.0)
	player.draw_line(bow_center + side * 8.0, aim_direction * 20.0, Color8(225, 225, 210), 1.0)
