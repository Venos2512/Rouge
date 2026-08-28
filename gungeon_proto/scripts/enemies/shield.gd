extends "res://gungeon_proto/scripts/enemies/base/enemy_base.gd"


const DamageTypesScript = preload(
	"res://gungeon_proto/scripts/combat/damage_types.gd"
)

const PROTECTED_TYPES: Array[String] = [
	"gunner",
	"support",
]
const GUARD_FRONT_DOT: float = 0.35
const GUARD_BREAK_FORCE: float = 250.0
const GUARD_BREAK_DURATION: float = 1.15
const HIT_SOURCE_MEMORY: float = 0.12
const COVER_DISTANCE: float = 30.0
const COVER_SEARCH_RADIUS: float = 260.0
const ALLY_SEARCH_INTERVAL: float = 0.25
const COVER_CATCH_UP_DISTANCE: float = 72.0
const COVER_CATCH_UP_MULTIPLIER: float = 1.25
const FACING_TURN_INTERVAL: float = 0.30
const FACING_DIRECTION_STEP: float = PI / 4.0
const GUARD_DIRECTIONS: Array[Vector2] = [
	Vector2.RIGHT,
	Vector2(0.70710678, 0.70710678),
	Vector2.DOWN,
	Vector2(-0.70710678, 0.70710678),
	Vector2.LEFT,
	Vector2(-0.70710678, -0.70710678),
	Vector2.UP,
	Vector2(0.70710678, -0.70710678),
]
const BASH_TRIGGER_RADIUS: float = 48.0
const BASH_ALLY_TRIGGER_RADIUS: float = 42.0
const BASH_MAX_REACH: float = 62.0
const BASH_ENGAGE_RADIUS: float = 105.0
const BASH_APPROACH_DISTANCE: float = 36.0
const BASH_FRONT_DOT: float = 0.15
const BASH_DAMAGE: int = 1
const BASH_KNOCKBACK: float = 245.0
const BASH_WINDUP: float = 1.0
const BASH_LUNGE_SPEED: float = 150.0
const BASH_LUNGE_DURATION: float = 0.12
const BASH_COOLDOWN: float = 1.75
const BASH_FLASH_DURATION: float = 0.16
const GUARD_OWNER_META: StringName = &"shield_guard_owner"
const SHIELD_SEPARATION_RADIUS: float = 42.0


var facing_direction: Vector2 = Vector2.RIGHT
var guard_break_timer: float = 0.0
var hit_source_position: Vector2 = Vector2.ZERO
var hit_source_timer: float = 0.0
var ally_search_timer: float = 0.0
var protected_ally: Node2D = null
var facing_index: int = 0
var facing_turn_timer: float = 0.0
var bash_windup_timer: float = 0.0
var bash_lunge_timer: float = 0.0
var bash_cooldown_timer: float = 0.7
var bash_flash_timer: float = 0.0


func _configure_enemy() -> void:
	enemy_type = "shield"

	max_health = 7
	health = max_health

	move_speed = 54.0
	preferred_distance = 56.0

	# Shield không tấn công tầm xa.
	fire_interval = 999.0
	fire_timer = fire_interval


func _process_ai(
	target: Node2D,
	delta: float
) -> void:
	guard_break_timer = maxf(
		0.0,
		guard_break_timer - delta
	)
	hit_source_timer = maxf(
		0.0,
		hit_source_timer - delta
	)
	ally_search_timer = maxf(
		0.0,
		ally_search_timer - delta
	)
	facing_turn_timer = maxf(
		0.0,
		facing_turn_timer - delta
	)
	bash_cooldown_timer = maxf(
		0.0,
		bash_cooldown_timer - delta
	)
	bash_flash_timer = maxf(
		0.0,
		bash_flash_timer - delta
	)

	var to_player: Vector2 = (
		target.global_position - global_position
	)
	if (
		to_player.length_squared() > 0.001
		and facing_turn_timer <= 0.0
		and bash_windup_timer <= 0.0
		and bash_lunge_timer <= 0.0
	):
		var desired_index: int = _get_guard_direction_index(to_player)
		if desired_index != facing_index:
			var clockwise_steps: int = posmod(
				desired_index - facing_index,
				GUARD_DIRECTIONS.size()
			)
			if clockwise_steps <= 4:
				facing_index = posmod(
					facing_index + 1,
					GUARD_DIRECTIONS.size()
				)
			else:
				facing_index = posmod(
					facing_index - 1,
					GUARD_DIRECTIONS.size()
				)

			facing_direction = GUARD_DIRECTIONS[facing_index]
			facing_turn_timer = FACING_TURN_INTERVAL

	if (
		ally_search_timer <= 0.0
		or not is_instance_valid(protected_ally)
	):
		_set_protected_ally(
			_find_protected_ally()
		)
		ally_search_timer = ALLY_SEARCH_INTERVAL

	if bash_windup_timer > 0.0:
		bash_windup_timer = maxf(
			0.0,
			bash_windup_timer - delta
		)
		if bash_windup_timer <= 0.0:
			_start_shield_bash()
		return

	if bash_lunge_timer > 0.0:
		_process_shield_bash_lunge(
			target,
			delta
		)
		return

	if (
		bash_cooldown_timer <= 0.0
		and _player_threatens_guard_line(target)
	):
		bash_windup_timer = BASH_WINDUP
		bash_cooldown_timer = BASH_COOLDOWN
		queue_redraw()
		return

	var desired_position: Vector2
	var should_attack: bool = _should_advance_to_attack(target)

	if should_attack:
		desired_position = (
			target.global_position
			- facing_direction * BASH_APPROACH_DISTANCE
		)
	elif is_instance_valid(protected_ally):
		var ally_to_player: Vector2 = (
			target.global_position
			- protected_ally.global_position
		)
		if ally_to_player.length_squared() <= 0.001:
			ally_to_player = facing_direction

		desired_position = (
			protected_ally.global_position
			+ ally_to_player.normalized()
			* COVER_DISTANCE
		)
	else:
		desired_position = (
			target.global_position
			- facing_direction * preferred_distance
		)

	var distance_to_post: float = global_position.distance_to(
		desired_position
	)
	if distance_to_post > 8.0:
		var movement_direction: Vector2 = _navigate_to(
			desired_position
		)
		movement_direction = _apply_separation(
			movement_direction
		)
		var movement_speed: float = move_speed
		if (
			is_instance_valid(protected_ally)
			and distance_to_post > COVER_CATCH_UP_DISTANCE
		):
			movement_speed *= COVER_CATCH_UP_MULTIPLIER

		_move_safely(
			movement_direction,
			movement_speed,
			delta
		)


func _get_guard_direction_index(direction: Vector2) -> int:
	var snapped_step: int = roundi(
		direction.angle() / FACING_DIRECTION_STEP
	)
	return posmod(
		snapped_step,
		GUARD_DIRECTIONS.size()
	)


func _player_threatens_guard_line(player: Node2D) -> bool:
	if global_position.distance_to(player.global_position) <= BASH_TRIGGER_RADIUS:
		return true

	return (
		is_instance_valid(protected_ally)
		and protected_ally.global_position.distance_to(
			player.global_position
		) <= BASH_ALLY_TRIGGER_RADIUS
		and global_position.distance_to(
			player.global_position
		) <= BASH_MAX_REACH
	)


func _should_advance_to_attack(player: Node2D) -> bool:
	if not is_instance_valid(protected_ally):
		return true

	return global_position.distance_to(
		player.global_position
	) <= BASH_ENGAGE_RADIUS


func _start_shield_bash() -> void:
	bash_lunge_timer = BASH_LUNGE_DURATION
	bash_flash_timer = BASH_FLASH_DURATION
	queue_redraw()


func _process_shield_bash_lunge(
	player: Node2D,
	delta: float
) -> void:
	_move_safely(
		facing_direction,
		BASH_LUNGE_SPEED,
		delta
	)

	bash_lunge_timer = maxf(
		0.0,
		bash_lunge_timer - delta
	)
	if bash_lunge_timer <= 0.0:
		_perform_shield_bash(player)


func _perform_shield_bash(player: Node2D) -> void:
	if not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) > BASH_MAX_REACH:
		return

	var to_player: Vector2 = player.global_position - global_position
	if (
		to_player.length_squared() <= 0.001
		or facing_direction.dot(to_player.normalized()) < BASH_FRONT_DOT
	):
		# Người chơi đã dodge qua lưng trong lúc telegraph.
		return

	if player.has_method("apply_hit_knockback"):
		player.call(
			"apply_hit_knockback",
			global_position,
			BASH_KNOCKBACK
		)

	DamageResolverScript.apply_simple_damage(
		player, BASH_DAMAGE, &"physical", [&"melee"],
		self, self, player.global_position, facing_direction
	)

	var scene: Node = get_tree().current_scene
	if is_instance_valid(scene):
		if scene.has_method("spawn_room_fx"):
			scene.call(
				"spawn_room_fx",
				global_position + facing_direction * 20.0,
				"impact"
			)
		if scene.has_method("request_camera_shake"):
			scene.call("request_camera_shake", 3.5)
		if scene.has_method("request_hit_stop"):
			scene.call("request_hit_stop", 0.035, 0.14)

	queue_redraw()


func _find_protected_ally() -> Node2D:
	var crowd_service: Node = get_tree().get_first_node_in_group(
		"enemy_crowd_service"
	)
	var candidates: Array = []

	if (
		is_instance_valid(crowd_service)
		and crowd_service.has_method("get_enemies_near")
	):
		candidates = crowd_service.call(
			"get_enemies_near",
			global_position,
			COVER_SEARCH_RADIUS
		)
	else:
		candidates = get_tree().get_nodes_in_group("enemies")

	var closest: Node2D = null
	var closest_distance_squared: float = INF

	for candidate_value: Node in candidates:
		if candidate_value == self:
			continue
		if not is_instance_valid(candidate_value):
			continue
		if candidate_value.is_queued_for_deletion():
			continue
		if not candidate_value is Node2D:
			continue

		var candidate_type: String = str(
			candidate_value.get("enemy_type")
		)
		if not PROTECTED_TYPES.has(candidate_type):
			continue

		if candidate_value.has_meta(GUARD_OWNER_META):
			var owner_value: Variant = candidate_value.get_meta(
				GUARD_OWNER_META
			)
			if (
				typeof(owner_value) == TYPE_OBJECT
				and is_instance_valid(owner_value)
			):
				if owner_value != self:
					continue
			else:
				candidate_value.remove_meta(GUARD_OWNER_META)

		var candidate: Node2D = candidate_value as Node2D
		var distance_squared: float = global_position.distance_squared_to(
			candidate.global_position
		)
		if distance_squared >= closest_distance_squared:
			continue

		closest = candidate
		closest_distance_squared = distance_squared

	return closest


func _set_protected_ally(new_ally: Node2D) -> void:
	if protected_ally == new_ally:
		return

	_release_protected_ally()
	protected_ally = new_ally

	if is_instance_valid(protected_ally):
		protected_ally.set_meta(
			GUARD_OWNER_META,
			self
		)


func _release_protected_ally() -> void:
	if not is_instance_valid(protected_ally):
		protected_ally = null
		return

	if protected_ally.has_meta(GUARD_OWNER_META):
		var owner_value: Variant = protected_ally.get_meta(
			GUARD_OWNER_META
		)
		if owner_value == self:
			protected_ally.remove_meta(GUARD_OWNER_META)

	protected_ally = null


func _exit_tree() -> void:
	_release_protected_ally()


func _get_cached_separation() -> Vector2:
	var crowd_service: Node = get_tree().get_first_node_in_group(
		"enemy_crowd_service"
	)
	if (
		not is_instance_valid(crowd_service)
		or not crowd_service.has_method("get_separation")
	):
		return Vector2.ZERO

	var result: Variant = crowd_service.call(
		"get_separation",
		self,
		SHIELD_SEPARATION_RADIUS
	)
	if typeof(result) != TYPE_VECTOR2:
		return Vector2.ZERO

	return result as Vector2


func apply_hit_knockback(
	source_position: Vector2,
	force: float
) -> void:
	hit_source_position = source_position
	hit_source_timer = HIT_SOURCE_MEMORY

	var hit_from_front: bool = _is_source_in_front(
		source_position
	)
	if hit_from_front and guard_break_timer <= 0.0:
		if force < GUARD_BREAK_FORCE:
			# Guard hấp thụ cả lực đẩy của đòn nhẹ từ phía trước.
			return

		guard_break_timer = GUARD_BREAK_DURATION

	super.apply_hit_knockback(
		source_position,
		force
	)


func receive_damage(info: RefCounted) -> RefCounted:
	if not info.has_delivery_tag(DamageTypesScript.EXPLOSION):
		return super.receive_damage(info)

	# Sóng nổ vòng qua mặt khiên: giảm nửa damage nhưng không chặn lực hất.
	var explosion_multipliers: Dictionary = damage_multipliers.duplicate()
	explosion_multipliers[info.damage_type] = (
		float(explosion_multipliers.get(info.damage_type, 1.0)) * 0.5
	)
	var result: RefCounted = DamageResolverScript.resolve_amount(
		self,
		info,
		explosion_multipliers,
		armor
	)
	if result.blocked or health <= 0:
		result.blocked = true
		return result

	hit_source_timer = 0.0
	var health_before: int = health
	super.take_damage(result.final_amount)
	result.killed = health_before > 0 and health <= 0
	return result


func take_damage(amount: int) -> void:
	if (
		guard_break_timer <= 0.0
		and hit_source_timer > 0.0
		and _is_source_in_front(hit_source_position)
	):
		_show_guard_impact()
		hit_source_timer = 0.0
		return

	hit_source_timer = 0.0
	super.take_damage(amount)


func take_explosion_damage(
	amount: int,
	source_position: Vector2,
	knockback_force: float
) -> void:
	# Sóng nổ vòng qua mặt khiên: giảm nửa damage nhưng không chặn lực hất.
	var reduced_damage: int = maxi(
		1,
		ceili(float(amount) * 0.5)
	)
	hit_source_timer = 0.0
	super.apply_hit_knockback(
		source_position,
		knockback_force
	)
	super.take_damage(reduced_damage)


func _is_source_in_front(source_position: Vector2) -> bool:
	var to_source: Vector2 = source_position - global_position
	if to_source.length_squared() <= 0.001:
		return true

	return facing_direction.dot(to_source.normalized()) >= GUARD_FRONT_DOT


func _show_guard_impact() -> void:
	var scene: Node = get_tree().current_scene
	if (
		is_instance_valid(scene)
		and scene.has_method("spawn_room_fx")
	):
		scene.call(
			"spawn_room_fx",
			global_position + facing_direction * 12.0,
			"impact"
		)

	queue_redraw()


func _draw_body() -> void:
	var body_color := Color8(78, 104, 126)
	if hit_flash > 0.0:
		body_color = Color8(255, 240, 220)

	draw_circle(Vector2.ZERO, 13.0, body_color)
	draw_circle(Vector2.ZERO, 7.0, Color8(42, 53, 66))

	var shield_center: Vector2 = facing_direction * 16.0
	var tangent := Vector2(-facing_direction.y, facing_direction.x)
	var shield_color := Color8(84, 180, 210)
	if guard_break_timer > 0.0:
		shield_color = Color8(196, 105, 70)
	elif bash_windup_timer > 0.0:
		shield_color = Color8(255, 210, 72)
	elif bash_lunge_timer > 0.0 or bash_flash_timer > 0.0:
		shield_color = Color8(255, 245, 220)

	# Mũi tên luôn trùng với hướng dùng để kiểm tra guard.
	# Nhờ vậy người chơi đọc được chính xác mặt trước có thể chặn đòn.
	var indicator_start: Vector2 = facing_direction * 3.0
	var indicator_tip: Vector2 = facing_direction * 26.0
	var indicator_color := Color8(255, 224, 92, 235)
	if guard_break_timer > 0.0:
		indicator_color = Color8(255, 126, 82, 235)

	draw_line(
		indicator_start,
		indicator_tip - facing_direction * 6.0,
		indicator_color,
		2.0
	)

	if bash_windup_timer > 0.0:
		var windup_progress: float = 1.0 - bash_windup_timer / BASH_WINDUP
		draw_arc(
			Vector2.ZERO,
			18.0 + windup_progress * 7.0,
			facing_direction.angle() - PI * 0.5,
			facing_direction.angle() + PI * 0.5,
			18,
			Color8(255, 198, 62, 220),
			2.0
		)
	draw_colored_polygon(
		PackedVector2Array([
			indicator_tip,
			indicator_tip - facing_direction * 9.0 + tangent * 5.0,
			indicator_tip - facing_direction * 9.0 - tangent * 5.0,
		]),
		indicator_color
	)

	draw_line(
		shield_center - tangent * 13.0,
		shield_center + tangent * 13.0,
		shield_color,
		7.0
	)
	draw_line(
		shield_center - tangent * 10.0,
		shield_center + tangent * 10.0,
		Color8(205, 238, 240),
		2.0
	)
