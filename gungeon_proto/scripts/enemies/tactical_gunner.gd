extends CharacterBody2D


const GunnerProjectileScript = preload(
	"res://gungeon_proto/scripts/enemies/tactical_gunner_projectile.gd"
)
const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)
const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)


enum GunnerState {
	REPOSITION,
	AIM,
	BURST,
	COVER,
	DODGE
}


const ROOM_LEFT: float = -365.0
const ROOM_RIGHT: float = 365.0
const ROOM_TOP: float = -198.0
const ROOM_BOTTOM: float = 198.0

const DESIRED_DISTANCE: float = 185.0
const MIN_COMFORT_DISTANCE: float = 125.0
const MAX_COMFORT_DISTANCE: float = 245.0

const PANIC_DISTANCE: float = 95.0

const AIM_DURATION: float = 0.28
const BURST_INTERVAL: float = 0.20

const DODGE_DURATION: float = 0.22
const DODGE_SPEED: float = 315.0
const DODGE_COOLDOWN: float = 2.1


var enemy_type: String = "gunner_elite"
var enemy_data: Resource = null

var max_health: int = 3
var health: int = 3
@export var armor: int = 0
@export var damage_multipliers: Dictionary = {
	&"physical": 1.0, &"fire": 1.0, &"shock": 1.0,
	&"poison": 1.0, &"void": 1.0,
}

var move_speed: float = 88.0
var hit_radius: float = 13.0

var bullet_speed: float = 285.0
var bullet_damage: int = 1

var state: int = GunnerState.REPOSITION

var player: Node2D = null

var target_position: Vector2 = Vector2.ZERO
var has_target_position: bool = false
var seeking_cover: bool = false

var aim_timer: float = 0.0
var attack_cooldown: float = 0.0

var burst_shots_remaining: int = 0
var burst_shot_timer: float = 0.0

var cover_timer: float = 0.0

var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.RIGHT

var invulnerable_timer: float = 0.0

var hit_flash: float = 0.0
var muzzle_flash_timer: float = 0.0

var knockback_velocity: Vector2 = Vector2.ZERO

var panic_dodge_requested: bool = false

# Heavy AI queries không cần chạy ở physics FPS.
# Movement vẫn chạy mỗi frame bằng kết quả đã cache.
var navigation_query_timer: float = 0.0
var cached_navigation_destination: Vector2 = Vector2.ZERO
var cached_navigation_direction: Vector2 = Vector2.ZERO

var line_of_sight_query_timer: float = 0.0
var cached_line_of_sight: bool = true

var separation_query_timer: float = 0.0
var cached_separation_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	z_index = 8
	GameAudio.play(self, "elite_spawn", 0.035)

	add_to_group(
		"enemies"
	)

	add_to_group(
		"elite_enemies"
	)

	add_to_group(
		"gunner_elite"
	)

	add_to_group(
		"room_entities"
	)

	_apply_enemy_data()

	var collision_shape: CollisionShape2D = (
		CollisionShape2D.new()
	)

	var shape: CircleShape2D = (
		CircleShape2D.new()
	)

	shape.radius = hit_radius

	collision_shape.shape = shape

	add_child(
		collision_shape
	)

	collision_layer = 2
	collision_mask = 1

	player = _get_player()

	attack_cooldown = randf_range(
		0.35,
		0.75
	)

	dodge_cooldown_timer = randf_range(
		0.4,
		1.0
	)

	# Lệch nhịp AI giữa các enemy để tránh CPU spike.
	navigation_query_timer = randf_range(
		0.0,
		0.14
	)

	line_of_sight_query_timer = randf_range(
		0.0,
		0.12
	)

	separation_query_timer = randf_range(
		0.0,
		0.10
	)

	queue_redraw()


func _apply_enemy_data() -> void:
	max_health = int(
		_read_enemy_number(
			[
				"max_health",
				"health"
			],
			3.0
		)
	)

	# Gunner Elite bền hơn Gunner thường,
	# nhưng sức mạnh chính vẫn đến từ AI.
	max_health = maxi(
		max_health,
		6
	)

	health = max_health

	move_speed = _read_enemy_number(
		[
			"move_speed",
			"speed"
		],
		88.0
	)

	bullet_speed = _read_enemy_number(
		[
			"bullet_speed",
			"projectile_speed"
		],
		285.0
	)

	# Gunner cố tình damage thấp.
	# Vai trò của nó là ép player di chuyển,
	# không phải burst damage.
	bullet_damage = 1


func _physics_process(
	delta: float
) -> void:
	if health <= 0:
		velocity = Vector2.ZERO
		return

	_update_timers(
		delta
	)

	if not is_instance_valid(
		player
	):
		player = _get_player()

	if not is_instance_valid(
		player
	):
		velocity = Vector2.ZERO
		return

	knockback_velocity = (
		knockback_velocity.move_toward(
			Vector2.ZERO,
			760.0 * delta
		)
	)

	var to_player: Vector2 = (
		player.global_position
		- global_position
	)

	var player_distance: float = (
		to_player.length()
	)

	if (
		panic_dodge_requested
		and dodge_cooldown_timer <= 0.0
		and player_distance <= 175.0
	):
		panic_dodge_requested = false

		_start_dodge()

	if state == GunnerState.DODGE:
		_process_dodge()

		queue_redraw()

		return

	if (
		player_distance < PANIC_DISTANCE
		and dodge_cooldown_timer <= 0.0
	):
		_start_dodge()

		_process_dodge()

		queue_redraw()

		return

	var steering: Vector2 = (
		_update_state(
			player_distance
		)
	)

	var separation: Vector2 = (
		_get_separation_direction()
	)

	steering += separation * 0.35

	if steering.length_squared() > 1.0:
		steering = steering.normalized()

	velocity = (
		steering * move_speed
		+ knockback_velocity
	)

	move_and_slide()

	_clamp_to_room()

	queue_redraw()


func _update_timers(
	delta: float
) -> void:
	aim_timer = maxf(
		0.0,
		aim_timer - delta
	)

	attack_cooldown = maxf(
		0.0,
		attack_cooldown - delta
	)

	burst_shot_timer = maxf(
		0.0,
		burst_shot_timer - delta
	)

	cover_timer = maxf(
		0.0,
		cover_timer - delta
	)

	dodge_timer = maxf(
		0.0,
		dodge_timer - delta
	)

	dodge_cooldown_timer = maxf(
		0.0,
		dodge_cooldown_timer - delta
	)

	invulnerable_timer = maxf(
		0.0,
		invulnerable_timer - delta
	)

	hit_flash = maxf(
		0.0,
		hit_flash - delta
	)

	muzzle_flash_timer = maxf(
		0.0,
		muzzle_flash_timer - delta
	)

	navigation_query_timer = maxf(
		0.0,
		navigation_query_timer - delta
	)

	line_of_sight_query_timer = maxf(
		0.0,
		line_of_sight_query_timer - delta
	)

	separation_query_timer = maxf(
		0.0,
		separation_query_timer - delta
	)


func _update_state(
	player_distance: float
) -> Vector2:
	match state:
		GunnerState.AIM:
			return _update_aim_state(
				player_distance
			)

		GunnerState.BURST:
			return _update_burst_state(
				player_distance
			)

		GunnerState.COVER:
			return _update_cover_state(
				player_distance
			)

		_:
			return _update_reposition_state(
				player_distance
			)


func _update_reposition_state(
	player_distance: float
) -> Vector2:
	if player_distance < PANIC_DISTANCE:
		_choose_escape_target()

	elif not has_target_position:
		_choose_reposition_target(
			false
		)

	var distance_to_target: float = (
		global_position.distance_to(
			target_position
		)
	)

	if (
		has_target_position
		and distance_to_target <= 12.0
	):
		has_target_position = false

		if seeking_cover:
			seeking_cover = false

			state = GunnerState.COVER

			cover_timer = randf_range(
				0.55,
				0.85
			)

			return Vector2.ZERO

		if (
			attack_cooldown <= 0.0
			and player_distance >= MIN_COMFORT_DISTANCE
			and player_distance <= MAX_COMFORT_DISTANCE
			and _has_line_of_sight()
		):
			_begin_aim()

			return Vector2.ZERO

		_choose_reposition_target(
			true
		)

	if (
		attack_cooldown <= 0.0
		and player_distance >= MIN_COMFORT_DISTANCE
		and player_distance <= MAX_COMFORT_DISTANCE
		and _has_line_of_sight()
		and (
			not has_target_position
			or distance_to_target < 38.0
		)
	):
		_begin_aim()

		return Vector2.ZERO

	if not has_target_position:
		return Vector2.ZERO

	return _get_navigation_direction(
		target_position
	)


func _update_aim_state(
	player_distance: float
) -> Vector2:
	if player_distance < PANIC_DISTANCE:
		state = GunnerState.REPOSITION

		has_target_position = false

		return Vector2.ZERO

	if not _has_line_of_sight():
		state = GunnerState.REPOSITION

		has_target_position = false

		_choose_reposition_target(
			true
		)

		return Vector2.ZERO

	if aim_timer > 0.0:
		return Vector2.ZERO

	state = GunnerState.BURST

	burst_shots_remaining = 2
	burst_shot_timer = 0.0

	return Vector2.ZERO


func _update_burst_state(
	player_distance: float
) -> Vector2:
	if player_distance < PANIC_DISTANCE:
		state = GunnerState.REPOSITION

		has_target_position = false

		return Vector2.ZERO

	if not _has_line_of_sight():
		_finish_burst()

		return Vector2.ZERO

	if (
		burst_shots_remaining > 0
		and burst_shot_timer <= 0.0
	):
		_fire_at_player()

		burst_shots_remaining -= 1

		burst_shot_timer = BURST_INTERVAL

	if burst_shots_remaining <= 0:
		_finish_burst()

		return Vector2.ZERO

	# Trong burst chỉ strafe rất nhẹ.
	var to_player: Vector2 = (
		player.global_position
		- global_position
	)

	if to_player.length_squared() <= 0.001:
		return Vector2.ZERO

	var tangent: Vector2 = (
		to_player.normalized().orthogonal()
	)

	if int(
		get_instance_id()
	) % 2 == 0:
		tangent = -tangent

	return tangent * 0.24


func _update_cover_state(
	player_distance: float
) -> Vector2:
	if player_distance < PANIC_DISTANCE:
		if dodge_cooldown_timer <= 0.0:
			_start_dodge()

			return Vector2.ZERO

		state = GunnerState.REPOSITION

		_choose_escape_target()

		return _get_navigation_direction(
			target_position
		)

	if cover_timer > 0.0:
		return Vector2.ZERO

	state = GunnerState.REPOSITION

	has_target_position = false

	# Ra khỏi cover theo góc mới thay vì
	# đứng tại chỗ bắn lại ngay.
	_choose_reposition_target(
		true
	)

	return Vector2.ZERO


func _begin_aim() -> void:
	state = GunnerState.AIM

	aim_timer = AIM_DURATION

	velocity = Vector2.ZERO


func _finish_burst() -> void:
	attack_cooldown = randf_range(
		1.05,
		1.35
	)

	burst_shots_remaining = 0

	var wants_cover: bool = (
		randf() < 0.62
	)

	if wants_cover:
		var cover_position: Variant = (
			_find_cover_position()
		)

		if typeof(
			cover_position
		) == TYPE_VECTOR2:
			target_position = (
				cover_position as Vector2
			)

			has_target_position = true
			seeking_cover = true
			state = GunnerState.REPOSITION

			return

	state = GunnerState.REPOSITION

	has_target_position = false

	_choose_reposition_target(
		true
	)


func _start_dodge() -> void:
	if not is_instance_valid(
		player
	):
		return

	var away: Vector2 = (
		global_position
		- player.global_position
	)

	if away.length_squared() <= 0.001:
		away = Vector2.RIGHT

	away = away.normalized()

	var tangent: Vector2 = away.orthogonal()

	if randf() < 0.5:
		tangent = -tangent

	var candidate_direction: Vector2 = (
		away * 0.72
		+ tangent * 0.70
	).normalized()

	var projected_position: Vector2 = (
		global_position
		+ candidate_direction * 68.0
	)

	if not _is_position_walkable(
		projected_position
	):
		candidate_direction = (
			away * 0.72
			- tangent * 0.70
		).normalized()

		projected_position = (
			global_position
			+ candidate_direction * 68.0
		)

	if not _is_position_walkable(
		projected_position
	):
		candidate_direction = away

	dodge_direction = candidate_direction

	dodge_timer = DODGE_DURATION
	dodge_cooldown_timer = DODGE_COOLDOWN

	# I-frame chỉ nằm ở phần đầu roll.
	invulnerable_timer = 0.13

	state = GunnerState.DODGE

	has_target_position = false
	seeking_cover = false


func _process_dodge() -> void:
	if dodge_timer <= 0.0:
		state = GunnerState.REPOSITION

		velocity = knockback_velocity

		_choose_reposition_target(
			true
		)

		return

	velocity = (
		dodge_direction * DODGE_SPEED
		+ knockback_velocity
	)

	move_and_slide()

	_clamp_to_room()


func _choose_escape_target() -> void:
	if not is_instance_valid(
		player
	):
		return

	var away: Vector2 = (
		global_position
		- player.global_position
	)

	if away.length_squared() <= 0.001:
		away = Vector2.RIGHT

	away = away.normalized()

	var tangent: Vector2 = away.orthogonal()

	target_position = (
		global_position
		+ away * 105.0
		+ tangent * randf_range(
			-45.0,
			45.0
		)
	)

	target_position = (
		_find_nearest_walkable(
			target_position
		)
	)

	has_target_position = true
	seeking_cover = false


func _choose_reposition_target(
	force_side_move: bool
) -> void:
	if not is_instance_valid(
		player
	):
		return

	var away: Vector2 = (
		global_position
		- player.global_position
	)

	if away.length_squared() <= 0.001:
		away = Vector2.RIGHT

	away = away.normalized()

	var tangent: Vector2 = away.orthogonal()

	var side_amount: float = randf_range(
		-58.0,
		58.0
	)

	if force_side_move:
		var side_sign: float = 1.0

		if randf() < 0.5:
			side_sign = -1.0

		side_amount = (
			side_sign
			* randf_range(
				52.0,
				92.0
			)
		)

	var desired_position: Vector2 = (
		player.global_position
		+ away * DESIRED_DISTANCE
		+ tangent * side_amount
	)

	target_position = (
		_find_nearest_walkable(
			desired_position
		)
	)

	has_target_position = true
	seeking_cover = false


func _find_cover_position() -> Variant:
	if not is_instance_valid(
		player
	):
		return null

	var best_position: Vector2 = Vector2.ZERO
	var best_score: float = INF
	var found: bool = false

	var lateral_offsets: Array[float] = [
		-28.0,
		0.0,
		28.0
	]

	var distance_offsets: Array[float] = [
		34.0,
		46.0,
		60.0
	]

	for blocker_value: Node in get_tree().get_nodes_in_group(
		"bullet_blockers"
	):
		if not is_instance_valid(
			blocker_value
		):
			continue

		if blocker_value.is_queued_for_deletion():
			continue

		var blocker: Node2D = (
			blocker_value as Node2D
		)

		if not is_instance_valid(
			blocker
		):
			continue

		if blocker.has_method(
			"is_outer_boundary"
		):
			if bool(
				blocker.call(
					"is_outer_boundary"
				)
			):
				continue

		var away_from_player: Vector2 = (
			blocker.global_position
			- player.global_position
		)

		if away_from_player.length_squared() <= 0.001:
			continue

		away_from_player = (
			away_from_player.normalized()
		)

		var tangent: Vector2 = (
			away_from_player.orthogonal()
		)

		var blocker_radius: float = (
			_read_object_number(
				blocker,
				"hit_radius",
				20.0
			)
		)

		for distance_offset: float in distance_offsets:
			for lateral_offset: float in lateral_offsets:
				var candidate: Vector2 = (
					blocker.global_position
					+ away_from_player
					* (
						blocker_radius
						+ distance_offset
					)
					+ tangent * lateral_offset
				)

				if not _is_position_walkable(
					candidate
				):
					continue

				var player_distance: float = (
					candidate.distance_to(
						player.global_position
					)
				)

				if player_distance < 110.0:
					continue

				if player_distance > 285.0:
					continue

				if _scene_has_line_of_sight(
					candidate,
					player.global_position
				):
					continue

				var score: float = (
					global_position.distance_to(
						candidate
					)
					+ absf(
						player_distance
						- DESIRED_DISTANCE
					) * 0.30
				)

				if score >= best_score:
					continue

				best_score = score
				best_position = candidate
				found = true

	if not found:
		return null

	return best_position


func _fire_at_player() -> void:
	GameAudio.play(self, "enemy_gun_fire", 0.04)
	if not is_instance_valid(
		player
	):
		return

	var shot_direction: Vector2 = (
		player.global_position
		- global_position
	)

	if shot_direction.length_squared() <= 0.001:
		return

	shot_direction = shot_direction.normalized()

	# Một chút sai số để Gunner gây áp lực
	# nhưng không trở thành hitscan chính xác tuyệt đối.
	shot_direction = shot_direction.rotated(
		deg_to_rad(
			randf_range(
				-2.8,
				2.8
			)
		)
	)

	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var projectile: Node2D = (
		get_tree().get_first_node_in_group(
			"tactical_projectile_pool"
		) as Node2D
	)

	if not is_instance_valid(
		projectile
	):
		projectile = (
			GunnerProjectileScript.new()
			as Node2D
		)

		if not is_instance_valid(
			projectile
		):
			return

		scene.add_child(
			projectile
		)

	if projectile.has_method(
		"activate_projectile"
	):
		projectile.call(
			"activate_projectile",
			global_position
				+ shot_direction * 19.0,
			shot_direction,
			bullet_speed,
			bullet_damage
		)

	muzzle_flash_timer = 0.07


func _has_line_of_sight() -> bool:
	if not is_instance_valid(
		player
	):
		return false

	if line_of_sight_query_timer > 0.0:
		return cached_line_of_sight

	cached_line_of_sight = (
		_scene_has_line_of_sight(
			global_position,
			player.global_position
		)
	)

	line_of_sight_query_timer = randf_range(
		0.10,
		0.15
	)

	return cached_line_of_sight


func _scene_has_line_of_sight(
	from_position: Vector2,
	to_position: Vector2
) -> bool:
	var scene: Node = (
		get_tree().current_scene
	)

	if (
		is_instance_valid(scene)
		and scene.has_method(
			"enemy_has_line_of_sight"
		)
	):
		return bool(
			scene.call(
				"enemy_has_line_of_sight",
				from_position,
				to_position,
				6.0
			)
		)

	return true


func _get_navigation_direction(
	destination: Vector2
) -> Vector2:
	var destination_changed: bool = (
		cached_navigation_destination.distance_squared_to(
			destination
		) > 52.0 * 52.0
	)

	if (
		navigation_query_timer > 0.0
		and not destination_changed
	):
		return cached_navigation_direction

	var scene: Node = (
		get_tree().current_scene
	)

	if (
		is_instance_valid(scene)
		and scene.has_method(
			"get_enemy_navigation_direction"
		)
	):
		var result: Variant = scene.call(
			"get_enemy_navigation_direction",
			global_position,
			destination,
			hit_radius
		)

		if typeof(
			result
		) == TYPE_VECTOR2:
			cached_navigation_direction = (
				result as Vector2
			)

			cached_navigation_destination = (
				destination
			)

			navigation_query_timer = randf_range(
				0.12,
				0.18
			)

			return cached_navigation_direction

	var direct: Vector2 = (
		destination
		- global_position
	)

	if direct.length_squared() <= 0.001:
		cached_navigation_direction = Vector2.ZERO

	else:
		cached_navigation_direction = (
			direct.normalized()
		)

	cached_navigation_destination = destination

	navigation_query_timer = randf_range(
		0.12,
		0.18
	)

	return cached_navigation_direction


func _is_position_walkable(
	position_value: Vector2
) -> bool:
	var scene: Node = (
		get_tree().current_scene
	)

	if (
		is_instance_valid(scene)
		and scene.has_method(
			"is_enemy_position_walkable"
		)
	):
		return bool(
			scene.call(
				"is_enemy_position_walkable",
				position_value,
				hit_radius
			)
		)

	return true


func _find_nearest_walkable(
	position_value: Vector2
) -> Vector2:
	var scene: Node = (
		get_tree().current_scene
	)

	if (
		is_instance_valid(scene)
		and scene.has_method(
			"find_nearest_walkable_enemy_position"
		)
	):
		var result: Variant = scene.call(
			"find_nearest_walkable_enemy_position",
			position_value,
			hit_radius
		)

		if typeof(
			result
		) == TYPE_VECTOR2:
			return (
				result as Vector2
			)

	return position_value


func _get_separation_direction() -> Vector2:
	if separation_query_timer > 0.0:
		return cached_separation_direction

	var separation: Vector2 = Vector2.ZERO

	for enemy_value: Node in get_tree().get_nodes_in_group(
		"enemies"
	):
		if enemy_value == self:
			continue

		if not is_instance_valid(
			enemy_value
		):
			continue

		var enemy: Node2D = (
			enemy_value as Node2D
		)

		if not is_instance_valid(
			enemy
		):
			continue

		var away: Vector2 = (
			global_position
			- enemy.global_position
		)

		var distance_squared: float = (
			away.length_squared()
		)

		if distance_squared <= 0.001:
			continue

		if distance_squared > 34.0 * 34.0:
			continue

		separation += (
			away.normalized()
			* (
				1.0
				- sqrt(
					distance_squared
				) / 34.0
			)
		)

	if separation.length_squared() > 1.0:
		separation = separation.normalized()

	cached_separation_direction = separation

	separation_query_timer = randf_range(
		0.08,
		0.12
	)

	return cached_separation_direction


func apply_hit_knockback(
	source_position: Vector2,
	strength: float
) -> void:
	var away: Vector2 = (
		global_position
		- source_position
	)

	if away.length_squared() <= 0.001:
		away = Vector2.RIGHT

	knockback_velocity = (
		away.normalized()
		* strength
	)


func receive_damage(info: RefCounted) -> RefCounted:
	return DamageResolverScript.receive_with_legacy_handler(
		self, info, damage_multipliers, armor
	)


func take_damage(
	amount: int
) -> void:
	if amount <= 0:
		return

	if invulnerable_timer > 0.0:
		return

	health -= amount
	GameAudio.play(self, "enemy_hurt", 0.06)

	hit_flash = 0.12

	panic_dodge_requested = true

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
				-22.0
			),
			amount,
			false
		)

	if health <= 0:
		_die()


func _die() -> void:
	if is_queued_for_deletion():
		return

	GameAudio.play(self, "enemy_death", 0.07)

	var scene: Node = (
		get_tree().current_scene
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

	if (
		is_instance_valid(scene)
		and scene.has_method(
			"spawn_currency_drop"
		)
		and randf() < 0.50
	):
		scene.call(
			"spawn_currency_drop",
			global_position,
			1
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


func _clamp_to_room() -> void:
	global_position = Vector2(
		clampf(
			global_position.x,
			ROOM_LEFT,
			ROOM_RIGHT
		),
		clampf(
			global_position.y,
			ROOM_TOP,
			ROOM_BOTTOM
		)
	)


func _read_enemy_number(
	property_names: Array[String],
	fallback: float
) -> float:
	if not is_instance_valid(
		enemy_data
	):
		return fallback

	for property_name: String in property_names:
		var value: float = (
			_read_object_number(
				enemy_data,
				property_name,
				NAN
			)
		)

		if not is_nan(
			value
		):
			return value

	return fallback


func _read_object_number(
	target: Object,
	property_name: String,
	fallback: float
) -> float:
	for property_data: Dictionary in target.get_property_list():
		if str(
			property_data.get(
				"name",
				""
			)
		) != property_name:
			continue

		var value: Variant = target.get(
			property_name
		)

		if (
			typeof(value) == TYPE_FLOAT
			or typeof(value) == TYPE_INT
		):
			return float(
				value
			)

		break

	return fallback


func _draw() -> void:
	var body_color: Color = Color(
		0.78,
		0.25,
		0.20,
		1.0
	)

	if state == GunnerState.COVER:
		body_color = Color(
			0.55,
			0.19,
			0.17,
			1.0
		)

	if hit_flash > 0.0:
		body_color = Color(
			1.0,
			0.92,
			0.80,
			1.0
		)

	# Vòng ngoài giúp đọc ngay đây là Gunner Elite.
	draw_arc(
		Vector2.ZERO,
		hit_radius + 4.0,
		0.0,
		TAU,
		24,
		Color(
			1.0,
			0.62,
			0.16,
			0.95
		),
		2.0
	)

	draw_circle(
		Vector2.ZERO,
		hit_radius,
		Color(
			0.12,
			0.08,
			0.08,
			1.0
		)
	)

	draw_circle(
		Vector2.ZERO,
		hit_radius - 2.0,
		body_color
	)

	var facing: Vector2 = Vector2.RIGHT

	if is_instance_valid(
		player
	):
		facing = (
			player.global_position
			- global_position
		)

		if facing.length_squared() > 0.001:
			facing = facing.normalized()

	if state == GunnerState.DODGE:
		draw_arc(
			Vector2.ZERO,
			hit_radius + 4.0,
			0.0,
			TAU,
			20,
			Color(
				0.45,
				0.82,
				1.0,
				0.75
			),
			2.0
		)

	draw_line(
		Vector2.ZERO,
		facing * 17.0,
		Color(
			0.20,
			0.12,
			0.10,
			1.0
		),
		4.0
	)

	if state == GunnerState.AIM:
		var aim_progress: float = clampf(
			1.0
			- aim_timer
			/ AIM_DURATION,
			0.0,
			1.0
		)

		draw_arc(
			Vector2.ZERO,
			18.0,
			-PI * 0.5,
			-PI * 0.5
			+ TAU * aim_progress,
			24,
			Color(
				1.0,
				0.72,
				0.20,
				0.95
			),
			2.0
		)

	if muzzle_flash_timer > 0.0:
		draw_circle(
			facing * 20.0,
			5.0,
			Color(
				1.0,
				0.82,
				0.30,
				1.0
			)
		)

	if health < max_health:
		var health_ratio: float = clampf(
			float(health)
			/ float(max_health),
			0.0,
			1.0
		)

		draw_rect(
			Rect2(
				Vector2(
					-14.0,
					-21.0
				),
				Vector2(
					28.0,
					3.0
				)
			),
			Color(
				0.08,
				0.06,
				0.06,
				0.90
			),
			true
		)

		draw_rect(
			Rect2(
				Vector2(
					-13.0,
					-20.0
				),
				Vector2(
					26.0
					* health_ratio,
					1.0
				)
			),
			Color(
				0.92,
				0.30,
				0.22,
				1.0
			),
			true
		)
