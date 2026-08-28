extends "res://gungeon_proto/scripts/enemies/base/enemy_base.gd"


func _configure_enemy() -> void:
	enemy_type = "spread"

	max_health = 5
	health = max_health

	move_speed = 27.0
	preferred_distance = 150.0

	fire_interval = 1.4
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
			3,
			28.0,
			145.0
		)


func _draw_body() -> void:
	var body_color := Color8(
		165,
		75,
		205
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

	draw_circle(
		Vector2(
			0.0,
			-3.0
		),
		4.0,
		Color8(
			235,
			150,
			255
		)
	)
