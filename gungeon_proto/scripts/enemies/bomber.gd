extends CharacterBody2D


const BomberBombScript = preload(
	"res://gungeon_proto/scripts/enemies/bomber_bomb.gd"
)
const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)
const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)


enum BomberState {
	READY,
	WINDUP,
	RECOVER,
}


const MOVE_SPEED: float = 62.0

const RETREAT_DISTANCE: float = 105.0
const APPROACH_DISTANCE: float = 255.0
const ATTACK_RANGE: float = 300.0

const WINDUP_DURATION: float = 0.35
const RECOVER_DURATION: float = 0.55

const ATTACK_COOLDOWN_MIN: float = 2.15
const ATTACK_COOLDOWN_MAX: float = 2.65

const PREDICTION_TIME: float = 0.25


var max_health: int = 3
var health: int = 3
@export var armor: int = 0
@export var damage_multipliers: Dictionary = {
	&"physical": 1.0, &"fire": 1.0, &"shock": 1.0,
	&"poison": 1.0, &"void": 1.0,
}

var state: BomberState = BomberState.READY

var attack_timer: float = 0.0
var windup_timer: float = 0.0
var recover_timer: float = 0.0

var pending_target: Vector2 = Vector2.ZERO

var player: Node2D = null

var knockback_velocity: Vector2 = Vector2.ZERO

var damage_flash_timer: float = 0.0

# Navigation BFS không cần chạy mỗi physics frame.
var navigation_timer: float = 0.0
var cached_navigation_target: Vector2 = Vector2.ZERO
var cached_navigation_direction: Vector2 = Vector2.ZERO

# Visual của Bomber rất đơn giản, 30 Hz là đủ.
var redraw_timer: float = 0.0
const REDRAW_INTERVAL: float = 1.0 / 30.0


func _ready() -> void:
	z_index = 12
	GameAudio.play(self, "enemy_spawn", 0.07)

	add_to_group(
		"enemies"
	)

	attack_timer = randf_range(
		0.8,
		1.35
	)

	# Lệch nhịp giữa nhiều Bomber để chúng không
	# cùng chạy pathfinding trong một frame.
	navigation_timer = randf_range(
		0.0,
		0.18
	)

	redraw_timer = randf_range(
		0.0,
		REDRAW_INTERVAL
	)

	queue_redraw()


func _physics_process(
	delta: float
) -> void:
	if health <= 0:
		velocity = Vector2.ZERO
		return

	if not is_instance_valid(
		player
	):
		player = _get_player()

	damage_flash_timer = maxf(
		0.0,
		damage_flash_timer - delta
	)

	navigation_timer = maxf(
		0.0,
		navigation_timer - delta
	)

	redraw_timer -= delta

	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		620.0 * delta
	)

	if not is_instance_valid(
		player
	):
		velocity = knockback_velocity

		move_and_slide()

		queue_redraw()

		return

	match state:
		BomberState.READY:
			_process_ready(
				delta
			)

		BomberState.WINDUP:
			_process_windup(
				delta
			)

		BomberState.RECOVER:
			_process_recover(
				delta
			)

	move_and_slide()

	if redraw_timer <= 0.0:
		redraw_timer = REDRAW_INTERVAL
		queue_redraw()


func _process_ready(
	delta: float
) -> void:
	attack_timer = maxf(
		0.0,
		attack_timer - delta
	)

	var to_player: Vector2 = (
		player.global_position
		- global_position
	)

	var distance_to_player: float = (
		to_player.length()
	)

	var move_direction: Vector2 = (
		Vector2.ZERO
	)

	if distance_to_player < RETREAT_DISTANCE:
		if distance_to_player > 1.0:
			move_direction = (
				-to_player.normalized()
			)

	elif distance_to_player > APPROACH_DISTANCE:
		move_direction = (
			_get_navigation_direction(
				player.global_position
			)
		)

	velocity = (
		move_direction * MOVE_SPEED
		+ knockback_velocity
	)

	if attack_timer > 0.0:
		return

	if distance_to_player > ATTACK_RANGE:
		return

	_start_windup()


func _process_windup(
	delta: float
) -> void:
	velocity = knockback_velocity

	windup_timer = maxf(
		0.0,
		windup_timer - delta
	)

	if windup_timer > 0.0:
		return

	_throw_bomb()

	state = BomberState.RECOVER

	recover_timer = RECOVER_DURATION


func _process_recover(
	delta: float
) -> void:
	velocity = knockback_velocity

	recover_timer = maxf(
		0.0,
		recover_timer - delta
	)

	if recover_timer > 0.0:
		return

	state = BomberState.READY

	attack_timer = randf_range(
		ATTACK_COOLDOWN_MIN,
		ATTACK_COOLDOWN_MAX
	)


func _start_windup() -> void:
	if not is_instance_valid(
		player
	):
		return

	pending_target = player.global_position

	if player is CharacterBody2D:
		var player_body: CharacterBody2D = (
			player as CharacterBody2D
		)

		pending_target += (
			player_body.velocity
			* PREDICTION_TIME
		)

	state = BomberState.WINDUP
	GameAudio.play(self, "bomber_fuse", 0.025)

	windup_timer = WINDUP_DURATION

	velocity = Vector2.ZERO


func _throw_bomb() -> void:
	GameAudio.play(self, "bomber_throw", 0.035)
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var bomb: Node2D = (
		BomberBombScript.new()
		as Node2D
	)

	if not is_instance_valid(
		bomb
	):
		return

	scene.add_child(
		bomb
	)

	bomb.call(
		"setup",
		global_position,
		pending_target
	)


func _get_navigation_direction(
	target_position: Vector2
) -> Vector2:
	var direct: Vector2 = target_position - global_position
	if direct.length_squared() <= 1.0:
		return Vector2.ZERO

	var target_changed: bool = (
		cached_navigation_target.distance_squared_to(
			target_position
		) > 48.0 * 48.0
	)

	if navigation_timer > 0.0 and not target_changed:
		return cached_navigation_direction

	var scene: Node = get_tree().current_scene
	# Phần lớn phòng là không gian mở. Bomber không cần chạy BFS chỉ để
	# tiến thẳng tới player; nhiều Bomber trước đây cùng tạo cache đường
	# đi mới mỗi 0,14-0,20 giây và gây tụt FPS kéo dài.
	if (
		is_instance_valid(scene)
		and scene.has_method("enemy_has_line_of_sight")
		and bool(scene.call(
			"enemy_has_line_of_sight",
			global_position,
			target_position,
			14.0
		))
	):
		cached_navigation_direction = direct.normalized()
		cached_navigation_target = target_position
		navigation_timer = randf_range(0.28, 0.42)
		return cached_navigation_direction

	if (
		is_instance_valid(
			scene
		)
		and scene.has_method(
			"get_enemy_navigation_direction"
		)
	):
		var result: Variant = scene.call(
			"get_enemy_navigation_direction",
			global_position,
			target_position,
			14.0
		)

		if typeof(
			result
		) == TYPE_VECTOR2:
			cached_navigation_direction = (
				result as Vector2
			)

			cached_navigation_target = (
				target_position
			)

			navigation_timer = randf_range(0.28, 0.42)

			return cached_navigation_direction

	cached_navigation_direction = direct.normalized()

	cached_navigation_target = target_position

	navigation_timer = randf_range(0.28, 0.42)

	return cached_navigation_direction


func receive_damage(info: RefCounted) -> RefCounted:
	return DamageResolverScript.receive_with_legacy_handler(
		self, info, damage_multipliers, armor
	)


func take_damage(
	amount: int
) -> void:
	if health <= 0:
		return

	health -= amount
	GameAudio.play(self, "enemy_hurt", 0.07)

	damage_flash_timer = 0.10

	var scene: Node = (
		get_tree().current_scene
	)

	if (
		is_instance_valid(
			scene
		)
		and scene.has_method(
			"spawn_damage_number"
		)
	):
		scene.call(
			"spawn_damage_number",
			global_position,
			amount,
			false
		)

	if health <= 0:
		_die()

	queue_redraw()


func apply_hit_knockback(
	source_position: Vector2,
	force: float
) -> void:
	var away: Vector2 = (
		global_position
		- source_position
	)

	if away.length_squared() <= 1.0:
		away = Vector2.RIGHT

	knockback_velocity += (
		away.normalized()
		* force
	)


func _die() -> void:
	if is_queued_for_deletion():
		return

	health = 0
	GameAudio.play(self, "enemy_death", 0.08)

	velocity = Vector2.ZERO

	var scene: Node = (
		get_tree().current_scene
	)

	if is_instance_valid(
		scene
	):
		if scene.has_method(
			"spawn_currency_drop"
		):
			scene.call(
				"spawn_currency_drop",
				global_position,
				randi_range(
					1,
					2
				)
			)

		if scene.has_method(
			"spawn_room_fx"
		):
			scene.call(
				"spawn_room_fx",
				global_position,
				"enemy_death"
			)

	queue_free()


func _get_player() -> Node2D:
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


func _draw() -> void:
	var body_color: Color = Color(
		0.78,
		0.25,
		0.12,
		1.0
	)

	if damage_flash_timer > 0.0:
		body_color = Color(
			1.0,
			0.88,
			0.72,
			1.0
		)

	draw_circle(
		Vector2(
			0.0,
			4.0
		),
		15.0,
		Color(
			0.05,
			0.04,
			0.05,
			0.28
		)
	)

	draw_circle(
		Vector2.ZERO,
		14.0,
		body_color
	)

	draw_circle(
		Vector2(
			-5.0,
			-3.0
		),
		3.0,
		Color(
			0.12,
			0.09,
			0.08,
			1.0
		)
	)

	draw_circle(
		Vector2(
			5.0,
			-3.0
		),
		3.0,
		Color(
			0.12,
			0.09,
			0.08,
			1.0
		)
	)

	draw_circle(
		Vector2(
			0.0,
			10.0
		),
		8.0,
		Color(
			0.13,
			0.13,
			0.15,
			1.0
		)
	)

	draw_circle(
		Vector2(
			3.0,
			6.0
		),
		2.0,
		Color(
			1.0,
			0.48,
			0.12,
			1.0
		)
	)

	if state == BomberState.WINDUP:
		var windup_progress: float = clampf(
			1.0
			- windup_timer
			/ WINDUP_DURATION,
			0.0,
			1.0
		)

		var held_height: float = (
			24.0
			+ windup_progress * 8.0
		)

		draw_circle(
			Vector2(
				0.0,
				-held_height
			),
			7.0,
			Color(
				0.11,
				0.11,
				0.13,
				1.0
			)
		)

		draw_circle(
			Vector2(
				3.0,
				-held_height - 3.0
			),
			2.0,
			Color(
				1.0,
				0.55,
				0.12,
				1.0
			)
		)

	if health < max_health:
		var health_ratio: float = clampf(
			float(
				health
			)
			/ float(
				max_health
			),
			0.0,
			1.0
		)

		draw_rect(
			Rect2(
				Vector2(
					-16.0,
					-25.0
				),
				Vector2(
					32.0,
					4.0
				)
			),
			Color(
				0.05,
				0.05,
				0.06,
				0.85
			),
			true
		)

		draw_rect(
			Rect2(
				Vector2(
					-15.0,
					-24.0
				),
				Vector2(
					30.0 * health_ratio,
					2.0
				)
			),
			Color(
				0.90,
				0.28,
				0.14,
				1.0
			),
			true
		)
