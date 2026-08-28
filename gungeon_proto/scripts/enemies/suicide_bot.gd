extends "res://gungeon_proto/scripts/enemies/base/enemy_base.gd"

const SuicideGameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)


const MOVE_SPEED: float = 108.0

const TRIGGER_DISTANCE: float = 58.0
const EXPLOSION_RADIUS: float = 76.0

const FUSE_DURATION: float = 0.55
const PLAYER_DAMAGE: int = 1
const ENEMY_DAMAGE: int = 3
const PLAYER_KNOCKBACK_FORCE: float = 520.0
const ENEMY_KNOCKBACK_FORCE: float = 380.0
const EDGE_KNOCKBACK_RATIO: float = 0.35

var fuse_active: bool = false
var fuse_timer: float = 0.0

var flash_timer: float = 0.0
var flash_state: bool = false


func _physics_process(
	delta: float
) -> void:
	var was_being_knocked_back: bool = (
		knockback_velocity.length_squared() > 1.0
	)
	_process_knockback(delta)

	# SuicideBot tự điều khiển movement nên không đi qua physics loop
	# của EnemyBase. Trong lúc nhận impulse, không cho chase movement
	# triệt tiêu hướng văng; fuse vẫn tiếp tục đếm nếu đã kích hoạt.
	if was_being_knocked_back and not fuse_active:
		queue_redraw()
		return

	var target: Node2D = (
		_get_suicide_target()
	)

	if not is_instance_valid(
		target
	):
		return

	if fuse_active:
		_process_fuse(
			delta,
			target
		)

		return

	var distance_to_target: float = (
		global_position.distance_to(
			target.global_position
		)
	)

	if distance_to_target <= TRIGGER_DISTANCE:
		_begin_fuse()

		return

	var direction: Vector2 = (
		target.global_position
		- global_position
	)

	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	else:
		direction = Vector2.ZERO

	var host: Node = get_parent()

	if (
		is_instance_valid(
			host
		)
		and host.has_method(
			"get_enemy_navigation_direction"
		)
	):
		var navigation_value: Variant = host.call(
			"get_enemy_navigation_direction",
			global_position,
			target.global_position,
			10.0
		)

		if typeof(
			navigation_value
		) == TYPE_VECTOR2:
			var navigation_direction: Vector2 = (
				navigation_value
			)

			if (
				navigation_direction.length_squared()
				> 0.01
			):
				direction = (
					navigation_direction.normalized()
				)

	global_position += (
		direction
		* MOVE_SPEED
		* delta
	)


func _begin_fuse() -> void:
	if fuse_active:
		return

	fuse_active = true
	SuicideGameAudio.play(self, "suicide_bot_warning", 0.02)
	SuicideGameAudio.play(self, "suicide_bot_charge", 0.025)
	fuse_timer = FUSE_DURATION

	flash_timer = 0.0
	flash_state = false


func _process_fuse(
	delta: float,
	target: Node2D
) -> void:
	fuse_timer -= delta
	flash_timer -= delta

	if flash_timer <= 0.0:
		flash_state = not flash_state

		var fuse_progress: float = clampf(
			1.0
			- fuse_timer
			/ FUSE_DURATION,
			0.0,
			1.0
		)

		flash_timer = lerpf(
			0.11,
			0.035,
			fuse_progress
		)

		if flash_state:
			modulate = Color(
				1.0,
				0.34,
				0.22,
				1.0
			)

		else:
			modulate = Color.WHITE

	if fuse_timer > 0.0:
		return

	_explode(
		target
	)


func _explode(
	target: Node2D
) -> void:
	if is_queued_for_deletion():
		return

	modulate = Color.WHITE
	SuicideGameAudio.play(self, "suicide_bot_explosion", 0.03)

	if is_instance_valid(
		target
	):
		var distance_to_target: float = (
			global_position.distance_to(
				target.global_position
			)
		)

		if distance_to_target <= EXPLOSION_RADIUS:
			_apply_explosion_knockback(
				target,
				distance_to_target,
				PLAYER_KNOCKBACK_FORCE
			)

			DamageResolverScript.apply_simple_damage(
				target, PLAYER_DAMAGE, &"fire", [&"explosion"],
				self, self, global_position
			)

	# Friendly fire: vụ nổ tác động lên mọi enemy khác trong bán kính.
	# Knockback được áp dụng trước damage để node vẫn còn hợp lệ nếu hit
	# này đủ mạnh để tiêu diệt mục tiêu.
	for enemy_value: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy_value):
			continue
		if enemy_value == self or enemy_value.is_queued_for_deletion():
			continue

		var enemy: Node2D = enemy_value as Node2D
		if not is_instance_valid(enemy):
			continue

		var enemy_distance: float = global_position.distance_to(
			enemy.global_position
		)
		if enemy_distance > EXPLOSION_RADIUS:
			continue

		_apply_explosion_knockback(
			enemy,
			enemy_distance,
			ENEMY_KNOCKBACK_FORCE
		)

		DamageResolverScript.apply_simple_damage(
			enemy, ENEMY_DAMAGE, &"fire", [&"explosion"],
			self, self, global_position
		)

	# Explosion damage kích thùng nổ ngay lập tức, không chạy fuse.
	for prop_value: Node in get_tree().get_nodes_in_group("destructibles"):
		if not is_instance_valid(prop_value):
			continue
		if prop_value.is_queued_for_deletion():
			continue
		var prop: Node2D = prop_value as Node2D
		if not is_instance_valid(prop):
			continue
		if global_position.distance_to(prop.global_position) > EXPLOSION_RADIUS:
			continue
		if prop.has_method("trigger_from_explosion"):
			prop.call("trigger_from_explosion")

	var host: Node = get_parent()

	if is_instance_valid(
		host
	):
		if host.has_method(
			"request_camera_shake"
		):
			host.call(
				"request_camera_shake",
				5.0
			)

		if host.has_method(
			"spawn_room_fx"
		):
			host.call(
				"spawn_room_fx",
				global_position,
				"explosion"
			)

	queue_free()


func _apply_explosion_knockback(
	target: Node2D,
	distance_to_target: float,
	maximum_force: float
) -> void:
	if not is_instance_valid(target):
		return
	if not target.has_method("apply_hit_knockback"):
		return

	var source_position: Vector2 = global_position
	if distance_to_target <= 0.001:
		source_position = target.global_position + Vector2.DOWN

	var distance_ratio: float = clampf(
		distance_to_target / maxf(EXPLOSION_RADIUS, 1.0),
		0.0,
		1.0
	)
	var force_scale: float = lerpf(
		1.0,
		EDGE_KNOCKBACK_RATIO,
		distance_ratio
	)
	target.call(
		"apply_hit_knockback",
		source_position,
		maximum_force * force_scale
	)


func _get_suicide_target() -> Node2D:
	var target_value: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)

	if not is_instance_valid(
		target_value
	):
		return null

	return target_value as Node2D
