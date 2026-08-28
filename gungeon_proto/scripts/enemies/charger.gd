extends "res://gungeon_proto/scripts/enemies/base/enemy_base.gd"


enum ChargeState {
	APPROACH,
	MELEE_WINDUP,
	MELEE_SLASH,
	WINDUP,
	CHARGING,
	STUNNED,
	RECOVERING,
}


const MELEE_TRIGGER_RANGE: float = 34.0
const MELEE_HIT_RANGE: float = 41.0
const MELEE_WINDUP_DURATION: float = 0.26
const MELEE_SLASH_DURATION: float = 0.16
const MELEE_DAMAGE: int = 1
const MELEE_COOLDOWN: float = 1.0
const POST_MELEE_CHARGE_LOCKOUT: float = 1.15
const CHARGE_TRIGGER_MIN_RANGE: float = 145.0
const CHARGE_TRIGGER_MAX_RANGE: float = 245.0
const CHARGE_WINDUP_DURATION: float = 0.70
const CHARGE_DURATION: float = 0.82
const CHARGE_START_SPEED: float = 135.0
const CHARGE_MAX_SPEED: float = 390.0
const CHARGE_ACCELERATION: float = 620.0
const CHARGE_DAMAGE: int = 2
const CHARGE_HIT_RANGE: float = 23.0
const CHARGE_COOLDOWN: float = 3.25
const CHARGE_DRIFT_DURATION: float = 0.30
const CHARGE_DRIFT_DECELERATION: float = 1050.0
const BREAK_THROUGH_SPEED_BONUS: float = 34.0
const WALL_STUN_DURATION: float = 1.35
const CHARGE_COLLISION_RADIUS: float = 12.0
const TELEGRAPH_LENGTH: float = 250.0
const GLANCING_IMPACT_THRESHOLD: float = 0.62
const WALL_REBOUND_DISTANCE: float = 10.0


var charge_state: ChargeState = ChargeState.APPROACH
var state_timer: float = 0.0
var charge_cooldown_timer: float = 0.65
var charge_direction := Vector2.RIGHT
var charge_visual_direction := Vector2.RIGHT
var charge_hit_player: bool = false
var charge_current_speed: float = 0.0
var melee_cooldown_timer: float = 0.0
var melee_direction := Vector2.RIGHT
var dash_hit_ids: Dictionary = {}
var cached_dash_props: Array[Node2D] = []


func _configure_enemy() -> void:
	enemy_type = "charger"
	max_health = 8
	health = max_health
	move_speed = 56.0
	preferred_distance = 128.0
	fire_interval = 99.0


func _process_ai(
	target: Node2D,
	delta: float
) -> void:
	charge_cooldown_timer = maxf(
		0.0,
		charge_cooldown_timer - delta
	)
	melee_cooldown_timer = maxf(
		0.0,
		melee_cooldown_timer - delta
	)

	match charge_state:
		ChargeState.MELEE_WINDUP:
			_process_melee_windup(target, delta)

		ChargeState.MELEE_SLASH:
			_process_melee_slash(target, delta)

		ChargeState.WINDUP:
			_process_windup(delta)

		ChargeState.CHARGING:
			_process_charge(target, delta)

		ChargeState.RECOVERING:
			_process_charge_drift(target, delta)

		ChargeState.STUNNED:
			_process_disabled_state(delta)

		_:
			_process_approach(target, delta)


func _process_approach(
	target: Node2D,
	delta: float
) -> void:
	var to_target: Vector2 = (
		target.global_position
		- global_position
	)
	var distance: float = to_target.length()

	# Giữ facing đồng bộ với player trước khi khóa hướng. Nếu không,
	# Charger hiển thị hướng mặc định Vector2.RIGHT và tạo cảm giác
	# nó vừa kiểm tra vị trí xong lại dash ngang.
	if to_target.length_squared() > 0.001:
		charge_direction = to_target.normalized()
		charge_visual_direction = charge_direction
		melee_direction = charge_direction

	if (
		distance <= MELEE_TRIGGER_RANGE
		and melee_cooldown_timer <= 0.0
	):
		_start_melee_windup()
		return

	if (
		charge_cooldown_timer <= 0.0
		and distance >= CHARGE_TRIGGER_MIN_RANGE
		and distance <= CHARGE_TRIGGER_MAX_RANGE
		and _has_line_of_sight(target)
	):
		_start_windup(to_target)
		return

	var direction: Vector2 = _navigate_to(target.global_position)
	direction = _apply_separation(direction)
	_move_safely(direction, move_speed, delta)


func _start_melee_windup() -> void:
	charge_state = ChargeState.MELEE_WINDUP
	state_timer = MELEE_WINDUP_DURATION
	queue_redraw()


func _process_melee_windup(
	target: Node2D,
	delta: float
) -> void:
	state_timer = maxf(0.0, state_timer - delta)

	var to_target: Vector2 = target.global_position - global_position

	if to_target.length_squared() > 0.001:
		melee_direction = to_target.normalized()
		charge_direction = melee_direction

	if state_timer > 0.0:
		return

	charge_state = ChargeState.MELEE_SLASH
	state_timer = MELEE_SLASH_DURATION
	melee_cooldown_timer = MELEE_COOLDOWN

	if (
		global_position.distance_to(target.global_position)
		<= MELEE_HIT_RANGE
	):
		DamageResolverScript.apply_simple_damage(
			target, MELEE_DAMAGE, &"physical", [&"melee"],
			self, self, target.global_position, melee_direction
		)
		_spawn_charge_impact(
			global_position + melee_direction * MELEE_TRIGGER_RANGE
		)

	queue_redraw()


func _process_melee_slash(
	_target: Node2D,
	delta: float
) -> void:
	state_timer = maxf(0.0, state_timer - delta)

	if state_timer > 0.0:
		return

	charge_state = ChargeState.APPROACH
	charge_cooldown_timer = maxf(
		charge_cooldown_timer,
		POST_MELEE_CHARGE_LOCKOUT
	)
	queue_redraw()


func _start_windup(to_target: Vector2) -> void:
	if to_target.length_squared() > 0.001:
		charge_direction = to_target.normalized()
		charge_visual_direction = charge_direction

	charge_state = ChargeState.WINDUP
	state_timer = CHARGE_WINDUP_DURATION
	charge_hit_player = false
	charge_cooldown_timer = CHARGE_COOLDOWN
	dash_hit_ids.clear()
	_refresh_dash_prop_cache()
	queue_redraw()


func _process_windup(delta: float) -> void:
	state_timer = maxf(0.0, state_timer - delta)

	if state_timer > 0.0:
		return

	charge_state = ChargeState.CHARGING
	state_timer = CHARGE_DURATION
	charge_current_speed = CHARGE_START_SPEED
	charge_visual_direction = charge_direction
	queue_redraw()


func _process_charge(
	target: Node2D,
	delta: float
) -> void:
	state_timer = maxf(0.0, state_timer - delta)

	charge_current_speed = move_toward(
		charge_current_speed,
		CHARGE_MAX_SPEED,
		CHARGE_ACCELERATION * delta
	)
	var travel_distance: float = charge_current_speed * delta
	var candidate: Vector2 = (
		global_position
		+ charge_direction * travel_distance
	)
	var broke_prop: bool = _damage_dash_targets(
		candidate,
		CHARGE_DAMAGE
	)

	if broke_prop:
		charge_current_speed = minf(
			CHARGE_MAX_SPEED,
			charge_current_speed + BREAK_THROUGH_SPEED_BONUS
		)

	if not _is_charge_position_walkable(candidate):
		if not _try_slide_along_wall(candidate, travel_distance):
			_enter_wall_stun()
			return
	else:
		global_position = candidate
		charge_visual_direction = charge_direction

	if (
		not charge_hit_player
		and is_instance_valid(target)
		and global_position.distance_to(target.global_position)
			<= CHARGE_HIT_RANGE
	):
		charge_hit_player = true
		_spawn_charge_impact(target.global_position)

	if state_timer <= 0.0:
		charge_state = ChargeState.RECOVERING
		state_timer = CHARGE_DRIFT_DURATION
		queue_redraw()


func _process_charge_drift(
	target: Node2D,
	delta: float
) -> void:
	state_timer = maxf(0.0, state_timer - delta)
	charge_current_speed = move_toward(
		charge_current_speed,
		0.0,
		CHARGE_DRIFT_DECELERATION * delta
	)

	var travel_distance: float = charge_current_speed * delta

	if travel_distance > 0.01:
		var candidate: Vector2 = (
			global_position
			+ charge_direction * travel_distance
		)
		_damage_dash_targets(candidate, CHARGE_DAMAGE)

		if _is_charge_position_walkable(candidate):
			global_position = candidate
			charge_visual_direction = charge_direction
		elif not _try_slide_along_wall(candidate, travel_distance):
			charge_current_speed = 0.0

	if (
		not charge_hit_player
		and is_instance_valid(target)
		and global_position.distance_to(target.global_position)
			<= CHARGE_HIT_RANGE
	):
		charge_hit_player = true
		_spawn_charge_impact(target.global_position)

	if state_timer <= 0.0 or charge_current_speed <= 1.0:
		charge_current_speed = 0.0
		charge_state = ChargeState.APPROACH
		queue_redraw()


func _is_charge_position_walkable(candidate: Vector2) -> bool:
	var scene: Node = get_tree().current_scene

	if (
		not is_instance_valid(scene)
		or not scene.has_method("is_enemy_position_walkable")
	):
		return true

	return bool(
		scene.call(
			"is_enemy_position_walkable",
			candidate,
			CHARGE_COLLISION_RADIUS
		)
	)


func _try_slide_along_wall(
	blocked_candidate: Vector2,
	travel_distance: float
) -> bool:
	var x_candidate := Vector2(
		blocked_candidate.x,
		global_position.y
	)
	var y_candidate := Vector2(
		global_position.x,
		blocked_candidate.y
	)
	var x_blocked: bool = not _is_charge_position_walkable(x_candidate)
	var y_blocked: bool = not _is_charge_position_walkable(y_candidate)

	# Kẹt đúng góc hoặc đâm vào một mặt không thể suy ra pháp tuyến:
	# coi là impact thật thay vì đoán hướng trượt.
	if x_blocked == y_blocked:
		return false

	var wall_normal := Vector2.ZERO

	if x_blocked:
		wall_normal = Vector2(-signf(charge_direction.x), 0.0)
	else:
		wall_normal = Vector2(0.0, -signf(charge_direction.y))

	var impact_strength: float = absf(
		charge_direction.dot(wall_normal)
	)

	# Góc gần vuông: đây là cú đâm, không phải lướt cạnh tường.
	if impact_strength >= GLANCING_IMPACT_THRESHOLD:
		return false

	var slide_direction: Vector2 = (
		charge_direction
		- wall_normal * charge_direction.dot(wall_normal)
	)

	if slide_direction.length_squared() <= 0.001:
		return false

	slide_direction = slide_direction.normalized()
	var slide_candidate: Vector2 = (
		global_position
		+ slide_direction * travel_distance
	)

	if not _is_charge_position_walkable(slide_candidate):
		return false

	global_position = slide_candidate
	charge_visual_direction = slide_direction
	return true


func _damage_dash_targets(
	position_value: Vector2,
	damage_amount: int
) -> bool:
	var targets: Array[Node2D] = []
	var broke_prop: bool = false
	var player: Node2D = _get_player()

	if is_instance_valid(player):
		targets.append(player)

	var crowd_service: Node = get_tree().get_first_node_in_group(
		"enemy_crowd_service"
	)

	if (
		is_instance_valid(crowd_service)
		and crowd_service.has_method("get_enemies_near")
	):
		var nearby_enemies: Array = crowd_service.call(
			"get_enemies_near",
			position_value,
			CHARGE_HIT_RANGE + 8.0
		)

		for enemy_value: Variant in nearby_enemies:
			var enemy: Node2D = enemy_value as Node2D

			if is_instance_valid(enemy):
				targets.append(enemy)

	for prop: Node2D in cached_dash_props:
		if is_instance_valid(prop):
			targets.append(prop)

	for target: Node2D in targets:
		if (
			target == self
			or not is_instance_valid(target)
			or target.is_queued_for_deletion()
			or target.is_in_group("terrain_walls")
		):
			continue

		var instance_id: int = target.get_instance_id()

		if dash_hit_ids.has(instance_id):
			continue

		if not _dash_target_overlaps(target, position_value):
			continue

		dash_hit_ids[instance_id] = true

		DamageResolverScript.apply_simple_damage(
			target, damage_amount, &"physical", [&"contact"],
			self, self, position_value, charge_direction
		)

		# Cú charge xuyên dứt điểm mọi room prop không phải tường cứng.
		# Không phụ thuộc HP/destructible để prop nhiều máu không bị hiểu
		# nhầm thành wall impact trong cùng frame.
		if (
			target.is_in_group("room_props")
			and not target.is_queued_for_deletion()
		):
			if target.has_method("_break_prop"):
				target.call("_break_prop")
				broke_prop = true
			elif target.has_method("_explode"):
				target.call("_explode")
				broke_prop = true

	return broke_prop


func _refresh_dash_prop_cache() -> void:
	cached_dash_props.clear()

	for prop_value: Node in get_tree().get_nodes_in_group("room_props"):
		var prop: Node2D = prop_value as Node2D

		if is_instance_valid(prop):
			cached_dash_props.append(prop)


func _dash_target_overlaps(
	target: Node2D,
	position_value: Vector2
) -> bool:
	if target.has_method("contains_projectile_point"):
		return bool(
			target.call(
				"contains_projectile_point",
				position_value,
				CHARGE_COLLISION_RADIUS
			)
		)

	var target_radius: float = 13.0

	for property_info: Dictionary in target.get_property_list():
		if str(property_info.get("name", "")) != "hit_radius":
			continue

		target_radius = float(target.get("hit_radius"))
		break

	var total_radius: float = CHARGE_COLLISION_RADIUS + target_radius
	return position_value.distance_squared_to(target.global_position) <= (
		total_radius * total_radius
	)


func take_damage(amount: int) -> void:
	if (
		charge_state == ChargeState.CHARGING
		or charge_state == ChargeState.RECOVERING
	):
		return

	super.take_damage(amount)


func _clamp_to_room() -> void:
	# EnemyBase còn dùng biên cứng Y -180..180. Với Charger đang lao ở
	# nửa dưới phòng, clamp đó xóa chuyển động theo Y nhưng vẫn giữ X,
	# khiến vector lao chéo/xuống bị biến thành dash ngang.
	#
	# Charger đã kiểm tra từng candidate qua RoomNavigation ở trên;
	# khi chạm biên thật hoặc blocker, nó vào WALL_STUN thay vì cần clamp.
	pass


func _enter_wall_stun() -> void:
	charge_state = ChargeState.STUNNED
	state_timer = WALL_STUN_DURATION
	charge_cooldown_timer = CHARGE_COOLDOWN
	charge_current_speed = 0.0

	var rebound_candidate: Vector2 = (
		global_position
		- charge_direction * WALL_REBOUND_DISTANCE
	)

	if _is_charge_position_walkable(rebound_candidate):
		global_position = rebound_candidate

	knockback_velocity = -charge_direction * 70.0
	_spawn_charge_impact(global_position + charge_direction * 12.0)
	queue_redraw()


func _process_disabled_state(delta: float) -> void:
	state_timer = maxf(0.0, state_timer - delta)

	if state_timer > 0.0:
		return

	charge_state = ChargeState.APPROACH
	queue_redraw()


func _spawn_charge_impact(position_value: Vector2) -> void:
	var scene: Node = get_tree().current_scene

	if (
		is_instance_valid(scene)
		and scene.has_method("spawn_room_fx")
	):
		scene.call(
			"spawn_room_fx",
			position_value,
			"impact"
		)


func _draw_body() -> void:
	var body_color := Color8(148, 68, 48)

	if hit_flash > 0.0:
		body_color = Color8(255, 240, 220)
	elif charge_state == ChargeState.STUNNED:
		body_color = Color8(118, 128, 145)
	elif charge_state == ChargeState.CHARGING:
		body_color = Color8(235, 92, 44)

	if charge_state == ChargeState.MELEE_WINDUP:
		var melee_progress: float = clampf(
			1.0 - state_timer / MELEE_WINDUP_DURATION,
			0.0,
			1.0
		)
		draw_arc(
			Vector2.ZERO,
			MELEE_HIT_RANGE,
			melee_direction.angle() - 0.70,
			melee_direction.angle() + 0.70,
			12,
			Color(1.0, 0.48, 0.16, 0.22 + melee_progress * 0.38),
			2.0,
			true
		)

	if charge_state == ChargeState.MELEE_SLASH:
		var slash_progress: float = clampf(
			1.0 - state_timer / MELEE_SLASH_DURATION,
			0.0,
			1.0
		)
		var slash_angle: float = lerpf(-0.85, 0.85, slash_progress)
		var slash_direction: Vector2 = melee_direction.rotated(slash_angle)
		draw_arc(
			Vector2.ZERO,
			MELEE_HIT_RANGE - 3.0,
			melee_direction.angle() - 0.9,
			melee_direction.angle() + slash_angle,
			12,
			Color(1.0, 0.86, 0.52, 0.9),
			3.0,
			true
		)
		draw_line(
			slash_direction * 10.0,
			slash_direction * MELEE_HIT_RANGE,
			Color(1.0, 0.96, 0.82, 1.0),
			4.0,
			true
		)

	if charge_state == ChargeState.WINDUP:
		var windup_progress: float = clampf(
			1.0 - state_timer / CHARGE_WINDUP_DURATION,
			0.0,
			1.0
		)
		draw_line(
			charge_direction * 15.0,
			charge_direction * TELEGRAPH_LENGTH,
			Color(1.0, 0.28, 0.10, 0.35 + windup_progress * 0.45),
			2.0 + windup_progress * 2.0,
			true
		)
		draw_circle(
			Vector2.ZERO,
			14.0 + windup_progress * 4.0,
			Color(1.0, 0.20, 0.08, 0.18),
			false,
			2.0
		)

	if charge_state == ChargeState.STUNNED:
		var stun_phase: float = Time.get_ticks_msec() * 0.008

		for index: int in range(3):
			var spark_angle: float = stun_phase + TAU * float(index) / 3.0
			var spark_position: Vector2 = Vector2.from_angle(spark_angle) * 18.0
			draw_circle(spark_position, 2.5, Color8(255, 220, 80), true)

	if (
		charge_state == ChargeState.CHARGING
		or charge_state == ChargeState.RECOVERING
	):
		var speed_ratio: float = clampf(
			charge_current_speed / CHARGE_MAX_SPEED,
			0.0,
			1.0
		)
		var trail_side := Vector2(
			-charge_visual_direction.y,
			charge_visual_direction.x
		)

		for trail_index: int in range(3):
			var side_offset: float = float(trail_index - 1) * 6.0
			var trail_start: Vector2 = (
				-charge_visual_direction * 10.0
				+ trail_side * side_offset
			)
			var trail_end: Vector2 = (
				trail_start
				- charge_visual_direction * (14.0 + speed_ratio * 18.0)
			)
			draw_line(
				trail_start,
				trail_end,
				Color(1.0, 0.50, 0.20, 0.18 + speed_ratio * 0.34),
				2.0,
				true
			)

	draw_rect(Rect2(-11.0, -9.0, 22.0, 19.0), body_color, true)

	var horn_direction: Vector2 = charge_direction

	if (
		charge_state == ChargeState.CHARGING
		or charge_state == ChargeState.RECOVERING
	):
		horn_direction = charge_visual_direction

	if (
		charge_state == ChargeState.MELEE_WINDUP
		or charge_state == ChargeState.MELEE_SLASH
	):
		horn_direction = melee_direction
	var horn_side := Vector2(-horn_direction.y, horn_direction.x)
	var horn_base: Vector2 = horn_direction * 8.0

	draw_colored_polygon(
		PackedVector2Array([
			horn_base + horn_side * 6.0,
			horn_base - horn_side * 6.0,
			horn_direction * 20.0,
		]),
		Color8(238, 210, 145)
	)

	draw_rect(Rect2(-8.0, -11.0, 4.0, 4.0), Color8(255, 142, 55), true)
	draw_rect(Rect2(4.0, -11.0, 4.0, 4.0), Color8(255, 142, 55), true)
