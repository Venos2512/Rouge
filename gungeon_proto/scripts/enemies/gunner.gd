extends "res://gungeon_proto/scripts/enemies/base/enemy_base.gd"


func _configure_enemy() -> void:
	enemy_type = "gunner"

	max_health = 4
	health = max_health

	move_speed = 42.0
	preferred_distance = 105.0

	fire_interval = 1.15
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
			false
		)
	)

	if (
		fire_timer <= 0.0
		and distance < 360.0
		and line_of_sight
	):
		_fire_spread(
			target,
			1,
			0.0,
			160.0
		)


func _draw_body() -> void:
	var body_color := Color8(
		190,
		55,
		62
	)

	if hit_flash > 0.0:
		body_color = Color8(
			255,
			240,
			220
		)

	draw_rect(
		Rect2(
			-8.0,
			-8.0,
			16.0,
			17.0
		),
		body_color,
		true
	)

	draw_rect(
		Rect2(
			7.0,
			-1.0,
			8.0,
			4.0
		),
		Color8(
			90,
			78,
			74
		),
		true
	)
