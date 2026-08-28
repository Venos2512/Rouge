extends Node2D


const EnemyBulletScript = preload(
	"res://gungeon_proto/scripts/weapons/projectiles/enemy_bullet.gd"
)
const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)
const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)


var enemy_type: String = "enemy"

var health: int = 4
var max_health: int = 4
@export var armor: int = 0
@export var damage_multipliers: Dictionary = {
	&"physical": 1.0,
	&"fire": 1.0,
	&"shock": 1.0,
	&"poison": 1.0,
	&"void": 1.0,
}

var move_speed: float = 42.0
var preferred_distance: float = 105.0

var fire_interval: float = 1.15
var fire_timer: float = 0.8

var contact_timer: float = 0.0
var hit_flash: float = 0.0

var spawn_duration: float = 0.45
var spawn_timer: float = 0.45

var navigation_timer: float = 0.0
var cached_navigation_target := Vector2.ZERO
var cached_navigation_direction := Vector2.ZERO

var line_of_sight_timer: float = 0.0
var cached_line_of_sight: bool = true

var separation_timer: float = 0.0
var cached_separation := Vector2.ZERO

var strafe_sign: float = 1.0
var strafe_timer: float = 1.0

var stuck_timer: float = 0.0

var knockback_velocity := Vector2.ZERO


func _ready() -> void:
	z_index = 20
	GameAudio.play(self, "enemy_spawn", 0.07)

	add_to_group(
		"enemies"
	)

	_configure_enemy()

	fire_timer += randf_range(
		0.0,
		0.55
	)

	if randf() < 0.5:
		strafe_sign = -1.0

	else:
		strafe_sign = 1.0

	strafe_timer = randf_range(
		0.8,
		1.6
	)

	line_of_sight_timer = randf_range(
		0.0,
		0.14
	)

	separation_timer = randf_range(
		0.0,
		0.12
	)

	queue_redraw()


func _configure_enemy() -> void:
	pass


func _process(
	delta: float
) -> void:
	spawn_timer = maxf(
		0.0,
		spawn_timer - delta
	)

	if spawn_timer > 0.0:
		queue_redraw()
		return

	hit_flash = maxf(
		0.0,
		hit_flash - delta
	)

	fire_timer = maxf(
		0.0,
		fire_timer - delta
	)

	contact_timer = maxf(
		0.0,
		contact_timer - delta
	)

	navigation_timer = maxf(
		0.0,
		navigation_timer - delta
	)

	line_of_sight_timer = maxf(
		0.0,
		line_of_sight_timer - delta
	)

	separation_timer = maxf(
		0.0,
		separation_timer - delta
	)

	strafe_timer -= delta

	if strafe_timer <= 0.0:
		strafe_sign *= -1.0

		strafe_timer = randf_range(
			0.8,
			1.6
		)

	_process_knockback(
		delta
	)

	var target: Node2D = _get_player()

	if is_instance_valid(
		target
	):
		_process_ai(
			target,
			delta
		)

	_clamp_to_room()

	queue_redraw()


func _process_ai(
	_target: Node2D,
	_delta: float
) -> void:
	pass


func _process_knockback(
	delta: float
) -> void:
	if knockback_velocity.length_squared() <= 1.0:
		return

	_move_safely(
		knockback_velocity.normalized(),
		knockback_velocity.length(),
		delta
	)

	knockback_velocity = (
		knockback_velocity.move_toward(
			Vector2.ZERO,
			720.0 * delta
		)
	)


func _get_player() -> Node2D:
	var crowd_service: Node = (
		get_tree().get_first_node_in_group(
			"enemy_crowd_service"
		)
	)

	if (
		is_instance_valid(
			crowd_service
		)
		and crowd_service.has_method(
			"get_player"
		)
	):
		var cached_player: Variant = (
			crowd_service.call(
				"get_player"
			)
		)

		if is_instance_valid(
			cached_player
		):
			return cached_player as Node2D

	var value: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)

	if not is_instance_valid(
		value
	):
		return null

	return value as Node2D


func _navigate_to(
	target_position: Vector2
) -> Vector2:
	var target_moved: bool = (
		cached_navigation_target.distance_squared_to(
			target_position
		)
		> 40.0 * 40.0
	)

	if (
		navigation_timer <= 0.0
		or target_moved
	):
		var scene: Node = (
			get_tree().current_scene
		)

		var result: Variant = null

		if (
			is_instance_valid(scene)
			and scene.has_method(
				"get_enemy_navigation_direction"
			)
		):
			result = scene.call(
				"get_enemy_navigation_direction",
				global_position,
				target_position,
				11.0
			)

		if typeof(result) == TYPE_VECTOR2:
			cached_navigation_direction = (
				result as Vector2
			)

		else:
			var direct: Vector2 = (
				target_position
				- global_position
			)

			if direct.length_squared() > 1.0:
				cached_navigation_direction = (
					direct.normalized()
				)

			else:
				cached_navigation_direction = (
					Vector2.ZERO
				)

		cached_navigation_target = (
			target_position
		)

		navigation_timer = randf_range(
			0.12,
			0.20
		)

	return cached_navigation_direction


func _has_line_of_sight(
	target: Node2D
) -> bool:
	if line_of_sight_timer > 0.0:
		return cached_line_of_sight

	var scene: Node = (
		get_tree().current_scene
	)

	if (
		not is_instance_valid(scene)
		or not scene.has_method(
			"enemy_has_line_of_sight"
		)
	):
		cached_line_of_sight = true

	else:
		cached_line_of_sight = bool(
			scene.call(
				"enemy_has_line_of_sight",
				global_position,
				target.global_position,
				6.0
			)
		)

	line_of_sight_timer = randf_range(
		0.10,
		0.16
	)

	return cached_line_of_sight


func _get_tactical_position(
	target: Node2D
) -> Vector2:
	var scene: Node = (
		get_tree().current_scene
	)

	if (
		not is_instance_valid(scene)
		or not scene.has_method(
			"get_enemy_tactical_position"
		)
	):
		return target.global_position

	var result: Variant = scene.call(
		"get_enemy_tactical_position",
		global_position,
		target.global_position,
		preferred_distance,
		11.0
	)

	if typeof(result) == TYPE_VECTOR2:
		return result as Vector2

	return target.global_position


func _apply_separation(
	base_direction: Vector2
) -> Vector2:
	if separation_timer <= 0.0:
		cached_separation = (
			_get_cached_separation()
		)

		separation_timer = randf_range(
			0.08,
			0.13
		)

	var result: Vector2 = (
		base_direction
		+ cached_separation * 0.85
	)

	if result.length_squared() <= 0.001:
		return Vector2.ZERO

	return result.normalized()


func _get_cached_separation() -> Vector2:
	var crowd_service: Node = (
		get_tree().get_first_node_in_group(
			"enemy_crowd_service"
		)
	)

	if not is_instance_valid(
		crowd_service
	):
		return Vector2.ZERO

	if not crowd_service.has_method(
		"get_separation"
	):
		return Vector2.ZERO

	var result: Variant = (
		crowd_service.call(
			"get_separation",
			self,
			30.0
		)
	)

	if typeof(result) != TYPE_VECTOR2:
		return Vector2.ZERO

	return result as Vector2


func _process_ranged_movement(
	target: Node2D,
	distance: float,
	delta: float,
	allow_strafe: bool
) -> bool:
	var to_player: Vector2 = (
		target.global_position
		- global_position
	)

	if to_player.length_squared() <= 0.001:
		return false

	var direct_direction: Vector2 = (
		to_player.normalized()
	)

	var line_of_sight: bool = (
		_has_line_of_sight(
			target
		)
	)

	var desired_position: Vector2 = (
		global_position
	)

	var should_move: bool = false

	if not line_of_sight:
		desired_position = (
			_get_tactical_position(
				target
			)
		)

		should_move = true

	elif distance > preferred_distance * 1.12:
		desired_position = (
			target.global_position
		)

		should_move = true

	elif distance < preferred_distance * 0.62:
		desired_position = (
			global_position
			- direct_direction * 100.0
		)

		should_move = true

	elif allow_strafe:
		var tangent := Vector2(
			-direct_direction.y,
			direct_direction.x
		)

		tangent *= strafe_sign

		desired_position = (
			global_position
			+ tangent * 90.0
		)

		should_move = true

	if should_move:
		var movement_direction: Vector2 = (
			_navigate_to(
				desired_position
			)
		)

		movement_direction = (
			_apply_separation(
				movement_direction
			)
		)

		var speed_multiplier: float = 1.0

		if distance < preferred_distance * 0.62:
			speed_multiplier = 0.72

		_move_safely(
			movement_direction,
			move_speed * speed_multiplier,
			delta
		)

	return line_of_sight


func _move_safely(
	direction: Vector2,
	speed: float,
	delta: float
) -> void:
	if direction.length_squared() <= 0.001:
		return

	var scene: Node = (
		get_tree().current_scene
	)

	var base_direction: Vector2 = (
		direction.normalized()
	)

	var candidate: Vector2 = (
		global_position
		+ base_direction
		* speed
		* delta
	)

	var can_move: bool = true

	if (
		is_instance_valid(scene)
		and scene.has_method(
			"is_enemy_position_walkable"
		)
	):
		can_move = bool(
			scene.call(
				"is_enemy_position_walkable",
				candidate,
				11.0
			)
		)

	if can_move:
		global_position = candidate
		stuck_timer = 0.0
		return

	var side_angle: float = deg_to_rad(
		45.0
	)

	var side_directions: Array[Vector2] = [
		base_direction.rotated(
			side_angle
		),
		base_direction.rotated(
			-side_angle
		),
		base_direction.rotated(
			PI * 0.5
		),
		base_direction.rotated(
			-PI * 0.5
		)
	]

	for side_direction: Vector2 in side_directions:
		var side_candidate: Vector2 = (
			global_position
			+ side_direction
			* speed
			* delta
		)

		var side_walkable: bool = true

		if (
			is_instance_valid(scene)
			and scene.has_method(
				"is_enemy_position_walkable"
			)
		):
			side_walkable = bool(
				scene.call(
					"is_enemy_position_walkable",
					side_candidate,
					11.0
				)
			)

		if not side_walkable:
			continue

		global_position = side_candidate
		stuck_timer = 0.0
		return

	stuck_timer += delta

	if stuck_timer < 0.30:
		return

	stuck_timer = 0.0
	navigation_timer = 0.0


func apply_hit_knockback(
	source_position: Vector2,
	force: float
) -> void:
	var away: Vector2 = (
		global_position
		- source_position
	)

	if away.length_squared() <= 0.001:
		return

	knockback_velocity += (
		away.normalized()
		* force
	)


func take_explosion_damage(
	amount: int,
	source_position: Vector2,
	knockback_force: float
) -> void:
	apply_hit_knockback(
		source_position,
		knockback_force
	)
	take_damage(amount)


func _fire_spread(
	target: Node2D,
	count: int,
	total_spread: float,
	projectile_speed: float
) -> void:
	if count > 1:
		GameAudio.play(self, "spread_enemy_fire", 0.04)
	else:
		GameAudio.play(self, "enemy_gun_fire", 0.045)
	var base_direction: Vector2 = (
		target.global_position
		- global_position
	).normalized()

	if count <= 1:
		_spawn_bullet(
			base_direction,
			projectile_speed
		)

		fire_timer = fire_interval
		return

	for i: int in range(
		count
	):
		var ratio: float = (
			float(i)
			/ float(count - 1)
		)

		var angle_deg: float = lerpf(
			-total_spread * 0.5,
			total_spread * 0.5,
			ratio
		)

		_spawn_bullet(
			base_direction.rotated(
				deg_to_rad(
					angle_deg
				)
			),
			projectile_speed
		)

	fire_timer = fire_interval


func _spawn_bullet(
	direction: Vector2,
	projectile_speed: float
) -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var bullet: Node2D = (
		get_tree().get_first_node_in_group(
			"enemy_bullet_pool"
		) as Node2D
	)

	if not is_instance_valid(
		bullet
	):
		bullet = (
			EnemyBulletScript.new()
			as Node2D
		)

		if not is_instance_valid(
			bullet
		):
			return

		scene.add_child(
			bullet
		)

	if bullet.has_method(
		"activate_bullet"
	):
		bullet.call(
			"activate_bullet",
			global_position
				+ direction * 15.0,
			direction,
			projectile_speed
		)


func _clamp_to_room() -> void:
	global_position.x = clampf(
		global_position.x,
		-350.0,
		350.0
	)

	global_position.y = clampf(
		global_position.y,
		-180.0,
		180.0
	)


func receive_damage(info: RefCounted) -> RefCounted:
	var result: RefCounted = DamageResolverScript.resolve_amount(
		self,
		info,
		damage_multipliers,
		armor
	)
	if result.blocked or health <= 0:
		result.blocked = true
		return result

	var health_before: int = health
	take_damage(result.final_amount)
	result.killed = health_before > 0 and health <= 0
	return result


func take_damage(
	amount: int
) -> void:
	health -= amount
	GameAudio.play(self, "enemy_hurt", 0.07)

	hit_flash = 0.08

	var scene: Node = (
		get_tree().current_scene
	)

	if (
		is_instance_valid(scene)
		and scene.has_method(
			"spawn_damage_number"
		)
	):
		scene.call(
			"spawn_damage_number",
			global_position
				+ Vector2(
					0.0,
					-17.0
				),
			amount,
			false
		)

	if (
		is_instance_valid(scene)
		and scene.has_method(
			"spawn_room_fx"
		)
	):
		scene.call(
			"spawn_room_fx",
			global_position,
			"impact"
		)

	if health > 0:
		queue_redraw()
		return

	if (
		is_instance_valid(scene)
		and scene.has_method(
			"spawn_room_fx"
		)
	):
		scene.call(
			"spawn_room_fx",
			global_position,
			"death"
		)

	_drop_currency()
	GameAudio.play(self, "enemy_death", 0.08)

	queue_free()


func _currency_drop_amount() -> int:
	return randi_range(
		1,
		3
	)


func _drop_currency() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if (
		not is_instance_valid(scene)
		or not scene.has_method(
			"spawn_currency_drop"
		)
	):
		return

	scene.call(
		"spawn_currency_drop",
		global_position,
		_currency_drop_amount()
	)


func _draw() -> void:
	if spawn_timer > 0.0:
		var progress: float = (
			1.0
			- spawn_timer
			/ spawn_duration
		)

		var box_size: float = lerpf(
			30.0,
			14.0,
			progress
		)

		draw_rect(
			Rect2(
				-box_size * 0.5,
				-box_size * 0.5,
				box_size,
				box_size
			),
			Color(
				0.75,
				0.35,
				0.95,
				1.0 - progress * 0.5
			),
			false,
			2.0
		)

		draw_rect(
			Rect2(
				-3.0,
				-3.0,
				6.0,
				6.0
			),
			Color8(
				245,
				210,
				255
			),
			true
		)

		return

	draw_rect(
		Rect2(
			-9.0,
			8.0,
			18.0,
			5.0
		),
		Color8(
			10,
			10,
			14,
			150
		),
		true
	)

	_draw_body()

	var pip_count: int = mini(
		health,
		8
	)

	for i: int in range(
		pip_count
	):
		draw_rect(
			Rect2(
				-10.0 + float(i) * 3.0,
				-17.0,
				2.0,
				2.0
			),
			Color8(
				108,
				220,
				112
			),
			true
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
