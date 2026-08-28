extends "res://gungeon_proto/scripts/enemies/base/enemy_base.gd"


# Compatibility fallback enemy.
#
# Enemy gameplay chính sử dụng các scene/script riêng:
# gunner.gd, chaser.gd, spread.gd, elite.gd, suicide_bot.gd...
#
# Script này KHÔNG phải enemy base authoritative.
# `base/enemy_base.gd` mới là base class chung.
#
# Chỉ giữ script này cho fallback enemy scene và runtime warmup
# cho tới khi fallback route được loại bỏ hoàn toàn.


func _configure_enemy() -> void:
	match enemy_type:
		"chaser":
			max_health = 5
			move_speed = 95.0
			preferred_distance = 18.0
			fire_interval = 99.0

		"spread":
			max_health = 5
			move_speed = 27.0
			preferred_distance = 150.0
			fire_interval = 1.4

		"elite":
			max_health = 15
			move_speed = 58.0
			preferred_distance = 120.0
			fire_interval = 0.68

		_:
			enemy_type = "gunner"
			max_health = 4
			move_speed = 42.0
			preferred_distance = 105.0
			fire_interval = 1.15

	health = max_health


func _process_ai(
	target: Node2D,
	delta: float
) -> void:
	var distance: float = (
		global_position.distance_to(
			target.global_position
		)
	)

	if enemy_type == "chaser":
		var direction: Vector2 = (
			_navigate_to(
				target.global_position
			)
		)

		direction = (
			_apply_separation(
				direction
			)
		)

		if distance > preferred_distance:
			_move_safely(
				direction,
				move_speed,
				delta
			)

		if (
			distance < 19.0
			and contact_timer <= 0.0
		):
			DamageResolverScript.apply_simple_damage(
				target, 1, &"physical", [&"contact"],
				self, self, target.global_position
			)

			contact_timer = 0.8

		return

	var allow_strafe: bool = (
		enemy_type == "spread"
		or enemy_type == "elite"
	)

	var line_of_sight: bool = (
		_process_ranged_movement(
			target,
			distance,
			delta,
			allow_strafe
		)
	)

	if (
		fire_timer > 0.0
		or distance >= 360.0
		or not line_of_sight
	):
		return

	match enemy_type:
		"spread":
			_fire_spread(
				target,
				3,
				28.0,
				145.0
			)

		"elite":
			_fire_spread(
				target,
				5,
				42.0,
				180.0
			)

		_:
			_fire_spread(
				target,
				1,
				0.0,
				160.0
			)


func _currency_drop_amount() -> int:
	if enemy_type == "elite":
		return 8

	return super._currency_drop_amount()
