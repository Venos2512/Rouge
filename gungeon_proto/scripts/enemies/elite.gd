extends "res://gungeon_proto/scripts/enemies/base/enemy_base.gd"


func _configure_enemy() -> void:
	enemy_type = "elite"

	max_health = 15
	health = max_health

	move_speed = 58.0
	preferred_distance = 120.0

	fire_interval = 0.68
	fire_timer = 0.8


func _process_ai(
	target: Node2D,
	delta: float
) -> void:
	var distance: float = (
		global_position.distance_to(
			target.global_position
		)
	)

	var line_of_sight: bool = (
		_process_ranged_movement(
			target,
			distance,
			delta,
			true
		)
	)

	if (
		fire_timer <= 0.0
		and distance < 360.0
		and line_of_sight
	):
		_fire_spread(
			target,
			5,
			42.0,
			180.0
		)


func _currency_drop_amount() -> int:
	return 8


func _draw_body() -> void:
	var body_color := Color8(
		225,
		175,
		55
	)

	if hit_flash > 0.0:
		body_color = Color8(
			255,
			240,
			220
		)

	draw_rect(
		Rect2(
			-10.0,
			-10.0,
			20.0,
			21.0
		),
		body_color,
		true
	)

	draw_rect(
		Rect2(
			-11.0,
			-13.0,
			22.0,
			3.0
		),
		Color8(
			255,
			225,
			100
		),
		true
	)
