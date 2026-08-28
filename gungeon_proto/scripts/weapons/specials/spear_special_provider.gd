class_name SpearSpecialProvider
extends "res://gungeon_proto/scripts/weapons/specials/base/melee_special_provider_base.gd"

const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)


func get_supported_weapon_ids() -> Array[String]:
	return [
		"spear",
	]


func _start_spear_charge() -> void:
	GameAudio.play(player, "spear_charge_loop", 0.0)
	spear_charging = true
	spear_charge_time = 0.0

	_show_progress(
		0.0
	)


func _update_spear_charge(
	delta: float
) -> void:
	spear_charge_time = minf(
		SPEAR_MAX_CHARGE,
		spear_charge_time + delta
	)

	var progress: float = (
		spear_charge_time
		/ SPEAR_MAX_CHARGE
	)

	_show_progress(
		progress
	)

	_block_normal_attack(
		0.08
	)


func _release_spear() -> void:
	GameAudio.stop(player, "spear_charge_loop")
	GameAudio.play(player, "spear_special_release", 0.025)
	spear_charging = false

	var progress: float = clampf(
		spear_charge_time
		/ SPEAR_MAX_CHARGE,
		0.0,
		1.0
	)

	_hide_progress()

	var power: float = float(
		pow(
			progress,
			0.72
		)
	)

	var throw_distance: float = lerpf(
		110.0,
		430.0,
		power
	)

	var damage_value: int = int(
		round(
			lerpf(
				4.0,
				8.0,
				power
			)
		)
	)

	var knockback_value: float = lerpf(
		110.0,
		260.0,
		power
	)

	var direction: Vector2 = (
		_get_aim_direction()
	)

	var scene: Node = (
		get_tree().current_scene
	)

	var spear: Node2D = (
		SpearProjectileScript.new()
		as Node2D
	)

	scene.add_child(
		spear
	)

	spear.global_position = (
		player.global_position
		+ direction * 25.0
	)

	spear.call(
		"configure",
		direction,
		throw_distance,
		damage_value,
		knockback_value
	)

	_block_normal_attack(
		0.20
	)

	spear_charge_time = 0.0
