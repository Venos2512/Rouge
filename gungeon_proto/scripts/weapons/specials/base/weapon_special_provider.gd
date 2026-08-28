class_name WeaponSpecialProvider
extends Node


func setup(
	_player: Node2D
) -> void:
	pass


func set_special_active(
	is_active: bool
) -> void:
	set_process(
		is_active
	)


func get_supported_weapon_ids() -> Array[String]:
	return []
