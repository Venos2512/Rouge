class_name SwordSpecialProvider
extends "res://gungeon_proto/scripts/weapons/specials/base/melee_special_provider_base.gd"

const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)


func get_supported_weapon_ids() -> Array[String]:
	return [
		"sword",
	]


func _start_parry() -> void:
	parry_active = true
	parry_timer = PARRY_WINDOW

	_block_normal_attack(
		PARRY_WINDOW
	)

	_spawn_fx(
		"parry",
		player.global_position,
		_get_aim_direction(),
		72.0
	)


func _update_parry(
	delta: float
) -> void:
	if _try_parry_bullets():
		parry_active = false
		parry_timer = 0.0

		# Parry thành công:
		# không cooldown, không recovery.
		parry_penalty_timer = 0.0

		return

	parry_timer -= delta

	if parry_timer > 0.0:
		return

	parry_active = false
	parry_timer = 0.0

	# Parry hụt = recovery 0.75 giây.
	parry_penalty_timer = (
		PARRY_MISS_PENALTY
	)

	_block_normal_attack(
		PARRY_MISS_PENALTY
	)


func _try_parry_bullets() -> bool:
	var aim: Vector2 = (
		_get_aim_direction()
	)

	var range_value: float = 78.0
	var half_arc: float = deg_to_rad(
		72.0
	)

	var parried: int = 0

	for bullet_value: Node in get_tree().get_nodes_in_group(
		"enemy_bullets"
	):
		if not is_instance_valid(
			bullet_value
		):
			continue

		if bullet_value.is_queued_for_deletion():
			continue

		var bullet: Node2D = (
			bullet_value as Node2D
		)

		if not is_instance_valid(
			bullet
		):
			continue

		var offset: Vector2 = (
			bullet.global_position
			- player.global_position
		)

		var distance: float = (
			offset.length()
		)

		if (
			distance <= 0.001
			or distance > range_value
		):
			continue

		var bullet_direction: Vector2 = (
			offset / distance
		)

		var dot_value: float = clampf(
			aim.dot(
				bullet_direction
			),
			-1.0,
			1.0
		)

		if acos(
			dot_value
		) > half_arc:
			continue

		var counter_direction: Vector2 = (
			bullet_direction
		)

		if bullet.has_method(
			"reflect"
		):
			bullet.call(
				"reflect",
				counter_direction
			)

		else:
			var bullet_position: Vector2 = (
				bullet.global_position
			)

			bullet.queue_free()

			_spawn_counter_projectile(
				bullet_position,
				counter_direction
			)

		parried += 1

	if parried <= 0:
		return false

	GameAudio.play(player, "sword_parry_success", 0.015)
	GameAudio.play(player, "sword_counter_shot", 0.025)

	_spawn_fx(
		"parry",
		player.global_position,
		aim,
		88.0
	)

	_request_gamefeel(
		4.5,
		0.045,
		0.10
	)

	return true


func _spawn_counter_projectile(
	position_value: Vector2,
	direction: Vector2
) -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var projectile: Node2D = (
		ParryCounterProjectileScript.new()
		as Node2D
	)

	scene.add_child(
		projectile
	)

	projectile.call(
		"configure",
		position_value,
		direction
	)
