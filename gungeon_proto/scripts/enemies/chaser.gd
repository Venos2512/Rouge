extends "res://gungeon_proto/scripts/enemies/base/enemy_base.gd"


const MELEE_TRIGGER_RANGE: float = 30.0
const MELEE_HIT_RANGE: float = 36.0
const MELEE_WINDUP_DURATION: float = 0.24
const MELEE_SLASH_DURATION: float = 0.16
const MELEE_COOLDOWN: float = 0.90
const MELEE_DAMAGE: int = 1
const APPROACH_SLOT_COUNT: int = 8
const APPROACH_SLOT_RADIUS: float = 19.0
const CHASE_SEPARATION_WEIGHT: float = 0.28


var melee_windup_timer: float = 0.0
var melee_slash_timer: float = 0.0
var melee_target: Node2D = null
var melee_attack_direction := Vector2.RIGHT


func _configure_enemy() -> void:
	enemy_type = "chaser"

	max_health = 5
	health = max_health

	move_speed = 95.0
	preferred_distance = 24.0

	fire_interval = 99.0


func _process_ai(
	target: Node2D,
	delta: float
) -> void:
	if melee_slash_timer > 0.0:
		melee_slash_timer = maxf(
			0.0,
			melee_slash_timer - delta
		)
		return

	if melee_windup_timer > 0.0:
		_process_melee_windup(
			delta
		)
		return

	var distance: float = (
		global_position.distance_to(
			target.global_position
		)
	)

	if distance > preferred_distance:
		var direction: Vector2 = (
			_get_chase_direction(
				target
			)
		)

		_move_safely(
			direction,
			move_speed,
			delta
		)

	if distance <= MELEE_TRIGGER_RANGE and contact_timer <= 0.0:
		_start_melee_attack(
			target
		)


func _get_chase_direction(
	target: Node2D
) -> Vector2:
	var slot_index: int = int(
		get_instance_id()
		% APPROACH_SLOT_COUNT
	)
	var slot_angle: float = TAU * (
		float(slot_index)
		/ float(APPROACH_SLOT_COUNT)
	)
	var approach_position: Vector2 = (
		target.global_position
		+ Vector2.from_angle(slot_angle)
		* APPROACH_SLOT_RADIUS
	)
	var chase_direction: Vector2 = (
		_navigate_to(
			approach_position
		)
	)
	if separation_timer <= 0.0:
		cached_separation = _get_cached_separation()
		separation_timer = randf_range(
			0.08,
			0.13
		)

	var separation: Vector2 = cached_separation
	var combined_direction: Vector2 = (
		chase_direction
		+ separation
		* CHASE_SEPARATION_WEIGHT
	)

	if combined_direction.length_squared() <= 0.04:
		var direct_to_player: Vector2 = (
			target.global_position
			- global_position
		)

		if direct_to_player.length_squared() <= 0.001:
			return Vector2.ZERO

		return direct_to_player.normalized()

	return combined_direction.normalized()


func _start_melee_attack(
	target: Node2D
) -> void:
	melee_target = target

	var to_target: Vector2 = (
		target.global_position
		- global_position
	)

	if to_target.length_squared() > 0.001:
		melee_attack_direction = to_target.normalized()

	melee_windup_timer = MELEE_WINDUP_DURATION
	contact_timer = MELEE_COOLDOWN
	queue_redraw()


func _process_melee_windup(
	delta: float
) -> void:
	melee_windup_timer = maxf(
		0.0,
		melee_windup_timer - delta
	)

	if melee_windup_timer > 0.0:
		return

	if not is_instance_valid(
		melee_target
	):
		melee_target = null
		return

	var target: Node2D = melee_target
	melee_target = null
	melee_slash_timer = MELEE_SLASH_DURATION

	var target_in_range: bool = (
		global_position.distance_to(
			target.global_position
		) <= MELEE_HIT_RANGE
	)

	if (
		target_in_range
	):
		DamageResolverScript.apply_simple_damage(
			target,
			MELEE_DAMAGE,
			&"physical",
			[&"melee"],
			self,
			self,
			target.global_position,
			melee_attack_direction
		)

	var scene: Node = get_tree().current_scene

	if (
		is_instance_valid(scene)
		and scene.has_method("spawn_room_fx")
	):
		scene.call(
			"spawn_room_fx",
			global_position
				+ melee_attack_direction
				* MELEE_TRIGGER_RANGE,
			"impact"
		)


func _draw_body() -> void:
	var body_color := Color8(
		220,
		92,
		55
	)

	if hit_flash > 0.0:
		body_color = Color8(
			255,
			240,
			220
		)

	if melee_windup_timer > 0.0:
		var windup_progress: float = clampf(
			1.0
			- melee_windup_timer
			/ MELEE_WINDUP_DURATION,
			0.0,
			1.0
		)

		draw_circle(
			Vector2.ZERO,
			MELEE_TRIGGER_RANGE,
			Color(
				1.0,
				0.28,
				0.12,
				0.16 + windup_progress * 0.18
			),
			false,
			2.0
		)

	if melee_slash_timer > 0.0:
		var slash_progress: float = clampf(
			1.0
			- melee_slash_timer
			/ MELEE_SLASH_DURATION,
			0.0,
			1.0
		)
		var facing_angle: float = (
			melee_attack_direction.angle()
		)
		var sweep_angle: float = lerpf(
			-0.95,
			0.95,
			slash_progress
		)
		var blade_direction := Vector2.from_angle(
			facing_angle + sweep_angle
		)
		var blade_start: Vector2 = (
			blade_direction * 9.0
		)
		var blade_end: Vector2 = (
			blade_direction * MELEE_HIT_RANGE
		)

		draw_arc(
			Vector2.ZERO,
			MELEE_HIT_RANGE - 3.0,
			facing_angle - 1.0,
			facing_angle + sweep_angle,
			12,
			Color(1.0, 0.86, 0.52, 0.82),
			3.0,
			true
		)
		draw_line(
			blade_start,
			blade_end,
			Color(1.0, 0.96, 0.82, 1.0),
			4.0,
			true
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
			-5.0,
			-10.0,
			3.0,
			4.0
		),
		Color8(
			255,
			205,
			90
		),
		true
	)

	draw_rect(
		Rect2(
			2.0,
			-10.0,
			3.0,
			4.0
		),
		Color8(
			255,
			205,
			90
		),
		true
	)
