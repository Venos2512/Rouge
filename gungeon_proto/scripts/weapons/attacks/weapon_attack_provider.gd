class_name WeaponAttackProvider
extends Node


func tick(
	_delta: float
) -> void:
	pass


func perform_attack(
	_player: Node2D,
	_weapon: Dictionary,
	_aim_direction: Vector2,
	_weapon_system: Node,
	_god_mode: bool
) -> Dictionary:
	return {
		"performed": false,
	}


func draw_held_weapon(
	_player: Node2D,
	_weapon: Dictionary,
	_aim_direction: Vector2
) -> void:
	pass
