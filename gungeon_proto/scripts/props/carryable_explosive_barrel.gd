@tool
extends StaticBody2D

const GameInputV2 = preload(
	"res://gungeon_proto/scripts/core/game_input_runtime.gd"
)
const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)

var prop_id: String = ""


@export_group("Barrel")
@export var hit_radius: float = 15.0
@export var interaction_radius: float = 44.0

@export var fuse_duration: float = 0.32
@export var explosion_radius: float = 95.0
@export var explosion_damage: int = 4
@export var player_knockback_force: float = 560.0
@export_range(0.0, 1.0, 0.05) var edge_knockback_ratio: float = 0.4
@export var armor: int = 0
@export var damage_multipliers: Dictionary = {
	&"physical": 1.0, &"fire": 1.5, &"shock": 1.0,
	&"poison": 1.0, &"void": 1.0,
}

@export_group("Throw")
@export var throw_speed: float = 580.0
@export var max_throw_time: float = 3.0


var collision_size: Vector2 = Vector2(
	22.0,
	28.0
)

var activated: bool = false
var explosion_started: bool = false

var fuse_timer: float = 0.0
var blink_timer: float = 0.0

var is_carried: bool = false
var is_thrown: bool = false

var carried_by: Node2D = null

var throw_velocity: Vector2 = Vector2.ZERO
var throw_timer: float = 0.0

var e_key_was_down: bool = false
var mouse_left_was_down: bool = false


@onready var collision_shape: CollisionShape2D = (
	get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
)

@onready var carry_offset: Marker2D = (
	get_node_or_null(
		"CarryOffset"
	) as Marker2D
)

@onready var prompt_label: Label = (
	get_node_or_null(
		"PromptAnchor/PromptLabel"
	) as Label
)

@onready var visual_root: Node2D = (
	get_node_or_null(
		"VisualRoot"
	) as Node2D
)

@onready var blink_overlay: CanvasItem = (
	get_node_or_null(
		"VisualRoot/BlinkOverlay"
	) as CanvasItem
)

@onready var fuse_ring: Line2D = (
	get_node_or_null(
		"FuseRing"
	) as Line2D
)

@onready var explosion_origin: Marker2D = (
	get_node_or_null(
		"ExplosionOrigin"
	) as Marker2D
)


func _ready() -> void:
	z_index = 6

	_sync_collision_size_from_scene()

	if Engine.is_editor_hint():
		queue_redraw()
		return

	throw_speed *= float(
		Engine.get_meta(
			"relic_throw_speed_mult",
			1.0
		)
	)

	explosion_radius *= float(
		Engine.get_meta(
			"relic_barrel_radius_mult",
			1.0
		)
	)

	explosion_damage += int(
		Engine.get_meta(
			"relic_barrel_damage_bonus",
			0
		)
	)

	add_to_group(
		"room_props"
	)

	add_to_group(
		"bullet_blockers"
	)

	add_to_group(
		"destructibles"
	)

	add_to_group(
		"explosive_barrels"
	)

	add_to_group(
		"carryable_objects"
	)

	if is_instance_valid(
		prompt_label
	):
		prompt_label.visible = false

	queue_redraw()


func _sync_collision_size_from_scene() -> void:
	if not is_instance_valid(
		collision_shape
	):
		return

	var rectangle_shape: RectangleShape2D = (
		collision_shape.shape
		as RectangleShape2D
	)

	if not is_instance_valid(
		rectangle_shape
	):
		return

	collision_size = rectangle_shape.size


func _process(delta: float) -> void:
	var e_down: bool = (
		GameInputV2.interact_pressed()
	)

	var mouse_left_down: bool = (
		GameInputV2.attack_pressed()
	)

	if is_carried:
		_update_carried()

		# E = đặt/thả xuống.
		if (
			e_down
			and not e_key_was_down
		):
			_place_barrel()

		# Chuột trái = ném.
		elif (
			mouse_left_down
			and not mouse_left_was_down
		):
			_throw_barrel()

		_update_fuse(
			delta
		)

		if is_queued_for_deletion():
			return

		e_key_was_down = e_down
		mouse_left_was_down = mouse_left_down

		queue_redraw()

		return

	if is_thrown:
		_update_thrown(
			delta
		)

		if is_queued_for_deletion():
			return

		# Nếu barrel đã bị trigger khi còn trên tay,
		# fuse tiếp tục chạy trong lúc nó đang bay.
		_update_fuse(
			delta
		)

		if is_queued_for_deletion():
			return

		e_key_was_down = e_down
		mouse_left_was_down = mouse_left_down

		queue_redraw()

		return

	_update_prompt()

	if (
		not activated
		and e_down
		and not e_key_was_down
		and _can_pick_up()
	):
		_pick_up()

	_update_fuse(
		delta
	)

	e_key_was_down = e_down
	mouse_left_was_down = mouse_left_down


func _update_fuse(
	delta: float
) -> void:
	if not activated:
		_refresh_scene_visual_state()
		return

	fuse_timer -= delta
	blink_timer += delta

	_refresh_scene_visual_state()

	if fuse_timer <= 0.0:
		_explode()

		return

	queue_redraw()


func _refresh_scene_visual_state() -> void:
	if is_instance_valid(
		blink_overlay
	):
		var blink_on: bool = (
			activated
			and (
				int(
					blink_timer * 20.0
				) % 2
				== 0
			)
		)

		blink_overlay.visible = blink_on

	if not is_instance_valid(
		fuse_ring
	):
		return

	fuse_ring.visible = activated

	if not activated:
		return

	var safe_fuse_duration: float = maxf(
		fuse_duration,
		0.001
	)

	var fuse_progress: float = clampf(
		fuse_timer
		/ safe_fuse_duration,
		0.0,
		1.0
	)

	var ring_radius: float = lerpf(
		20.0,
		explosion_radius,
		1.0 - fuse_progress
	)

	var points := PackedVector2Array()

	var segment_count: int = 32

	for i in range(
		segment_count + 1
	):
		var angle: float = (
			TAU
			* float(i)
			/ float(segment_count)
		)

		points.append(
			Vector2(
				cos(angle),
				sin(angle)
			) * ring_radius
		)

	fuse_ring.points = points


func _get_player() -> Node2D:
	var player_value: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)

	if not is_instance_valid(
		player_value
	):
		return null

	return player_value as Node2D


func _get_aim_direction(
	player: Node2D
) -> Vector2:
	var aim_value: Variant = player.get(
		"aim_direction"
	)

	if typeof(aim_value) == TYPE_VECTOR2:
		var aim_direction: Vector2 = aim_value

		if (
			aim_direction.length_squared()
			> 0.001
		):
			return aim_direction.normalized()

	return Vector2.RIGHT


func _player_has_carried_object(
	player: Node2D
) -> bool:
	if not is_instance_valid(
		player
	):
		return false

	if not player.has_meta(
		"carried_object"
	):
		return false

	var value: Variant = player.get_meta(
		"carried_object"
	)

	if value == null:
		return false

	if typeof(
		value
	) != TYPE_OBJECT:
		return false

	return is_instance_valid(
		value
	)


func _is_nearest_carryable(
	player: Node2D
) -> bool:
	var my_distance: float = (
		global_position.distance_squared_to(
			player.global_position
		)
	)

	for object_value in get_tree().get_nodes_in_group(
		"carryable_objects"
	):
		if not is_instance_valid(
			object_value
		):
			continue

		if object_value == self:
			continue

		if object_value.is_queued_for_deletion():
			continue

		var object_node: Node2D = (
			object_value as Node2D
		)

		if not is_instance_valid(
			object_node
		):
			continue

		var other_carried: Variant = (
			object_node.get(
				"is_carried"
			)
		)

		if (
			other_carried != null
			and bool(other_carried)
		):
			continue

		var other_thrown: Variant = (
			object_node.get(
				"is_thrown"
			)
		)

		if (
			other_thrown != null
			and bool(other_thrown)
		):
			continue

		var distance: float = (
			object_node.global_position.distance_squared_to(
				player.global_position
			)
		)

		if distance < my_distance:
			return false

	return true


func _can_pick_up() -> bool:
	if activated:
		return false

	if is_carried:
		return false

	if is_thrown:
		return false

	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		return false

	if _player_has_carried_object(
		player
	):
		return false

	if global_position.distance_to(
		player.global_position
	) > interaction_radius:
		return false

	return _is_nearest_carryable(
		player
	)


func _update_prompt() -> void:
	if not is_instance_valid(
		prompt_label
	):
		return

	prompt_label.visible = false

	if activated:
		return

	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		return

	if _player_has_carried_object(
		player
	):
		return

	if global_position.distance_to(
		player.global_position
	) > interaction_radius:
		return

	if not _is_nearest_carryable(
		player
	):
		return

	if not Input.get_connected_joypads().is_empty():
		prompt_label.text = "[A] PICK UP"

	else:
		prompt_label.text = "[E] PICK UP"

	prompt_label.visible = true


func _pick_up() -> void:
	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		return

	is_carried = true
	is_thrown = false

	carried_by = player

	throw_velocity = Vector2.ZERO
	throw_timer = 0.0

	rotation = 0.0
	z_index = 25

	player.set_meta(
		"carried_object",
		self
	)

	# Enemy bullet dùng group đặc biệt này để
	# vẫn bắn trúng barrel khi barrel nằm trên tay.
	add_to_group(
		"carried_explosives"
	)

	_remove_world_state()

	_update_carried()


func _remove_world_state() -> void:
	if is_in_group(
		"bullet_blockers"
	):
		remove_from_group(
			"bullet_blockers"
		)

	if is_in_group(
		"destructibles"
	):
		remove_from_group(
			"destructibles"
		)

	if is_instance_valid(
		collision_shape
	):
		collision_shape.set_deferred(
			"disabled",
			true
		)


func _update_carried() -> void:
	if not is_instance_valid(
		carried_by
	):
		_release_carrier()

		return

	# Barrel luôn nằm cố định trên đầu player.
	# Chuột chỉ quyết định hướng khi thực sự ném.
	var offset: Vector2 = Vector2(
		0.0,
		-40.0
	)

	if is_instance_valid(
		carry_offset
	):
		offset = carry_offset.position

	global_position = (
		carried_by.global_position
		+ offset
	)

	rotation = 0.0

	if is_instance_valid(
		prompt_label
	):
		if activated:
			if not Input.get_connected_joypads().is_empty():
				prompt_label.text = (
					"!!! LIVE !!!   [RT] THROW   [A] DROP"
				)

			else:
				prompt_label.text = (
					"!!! LIVE !!!   [LMB] THROW   [E] DROP"
				)

		else:
			if not Input.get_connected_joypads().is_empty():
				prompt_label.text = (
					"[RT] THROW   [A] PLACE"
				)

			else:
				prompt_label.text = (
					"[LMB] THROW   [E] PLACE"
				)

		prompt_label.visible = true


func _throw_barrel() -> void:
	if not is_instance_valid(
		carried_by
	):
		return

	var player: Node2D = carried_by

	var direction: Vector2 = (
		_get_aim_direction(
			player
		)
	)

	# LMB của frame này thuộc về hành động THROW.
	# Player chỉ được bắn lại sau khi LMB được nhả.
	player.set_meta(
		"suppress_fire_until_release",
		true
	)

	_release_carrier()

	is_carried = false
	is_thrown = true

	throw_velocity = (
		direction
		* throw_speed
	)

	throw_timer = 0.0

	rotation = 0.0
	z_index = 25

	if is_in_group(
		"carried_explosives"
	):
		remove_from_group(
			"carried_explosives"
		)

	if is_instance_valid(
		prompt_label
	):
		prompt_label.visible = false

	# QUAN TRỌNG:
	#
	# Ném barrel bình thường KHÔNG tự start fuse.
	#
	# Nó bay đến khi:
	# - trúng enemy
	# - trúng terrain
	# → EXPLODE.
	#
	# Nếu enemy đã bắn nó lúc còn trên tay,
	# activated đã true và fuse hiện tại tiếp tục chạy.


func _place_barrel() -> void:
	if not is_instance_valid(
		carried_by
	):
		return

	var player: Node2D = carried_by

	var direction: Vector2 = (
		_get_aim_direction(
			player
		)
	)

	var desired_position: Vector2 = (
		player.global_position
		+ direction * 46.0
	)

	var safe_position: Vector2 = (
		_find_safe_place_position(
			player,
			desired_position
		)
	)

	_release_carrier()

	is_carried = false
	is_thrown = false

	global_position = safe_position

	throw_velocity = Vector2.ZERO
	throw_timer = 0.0

	rotation = 0.0
	z_index = 6

	if is_in_group(
		"carried_explosives"
	):
		remove_from_group(
			"carried_explosives"
		)

	_restore_world_state()

	if is_instance_valid(
		prompt_label
	):
		prompt_label.visible = false


func _find_safe_place_position(
	player: Node2D,
	desired_position: Vector2
) -> Vector2:
	var scene: Node = (
		get_tree().current_scene
	)

	if not scene.has_method(
		"is_enemy_position_walkable"
	):
		return desired_position

	var direction: Vector2 = (
		desired_position
		- player.global_position
	)

	if (
		direction.length_squared()
		<= 0.001
	):
		direction = Vector2.RIGHT

	direction = direction.normalized()

	var side: Vector2 = Vector2(
		-direction.y,
		direction.x
	)

	var candidates: Array[Vector2] = [
		desired_position,

		player.global_position
			+ direction * 38.0
			+ side * 26.0,

		player.global_position
			+ direction * 38.0
			- side * 26.0,

		player.global_position
			- direction * 40.0
	]

	for candidate: Vector2 in candidates:
		var walkable: bool = bool(
			scene.call(
				"is_enemy_position_walkable",
				candidate,
				hit_radius
			)
		)

		if walkable:
			return candidate

	return desired_position


func _update_thrown(
	delta: float
) -> void:
	if not is_thrown:
		return

	throw_timer += delta

	var next_position: Vector2 = (
		global_position
		+ throw_velocity * delta
	)

	if _check_enemy_impact(
		next_position
	):
		return

	if _check_world_impact(
		next_position
	):
		_explode()

		return

	global_position = next_position

	rotation += (
		12.0 * delta
	)

	# Chỉ để tránh object bay vô hạn nếu nó somehow
	# thoát khỏi room.
	if throw_timer >= max_throw_time:
		_explode()


func _check_enemy_impact(
	next_position: Vector2
) -> bool:
	for enemy_value in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(
			enemy_value
		):
			continue

		if enemy_value.is_queued_for_deletion():
			continue

		var enemy: Node2D = (
			enemy_value as Node2D
		)

		if not is_instance_valid(
			enemy
		):
			continue

		var combined_radius: float = (
			hit_radius + 15.0
		)

		if next_position.distance_squared_to(
			enemy.global_position
		) > (
			combined_radius
			* combined_radius
		):
			continue

		global_position = next_position

		_explode()

		return true

	return false


func _check_world_impact(
	next_position: Vector2
) -> bool:
	for blocker_value in get_tree().get_nodes_in_group(
		"bullet_blockers"
	):
		if not is_instance_valid(
			blocker_value
		):
			continue

		if blocker_value == self:
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

		var hit: bool = false

		if blocker.has_method(
			"contains_projectile_point"
		):
			hit = bool(
				blocker.call(
					"contains_projectile_point",
					next_position,
					hit_radius
				)
			)

		else:
			var radius_value: Variant = blocker.get(
				"hit_radius"
			)

			if radius_value != null:
				var blocker_radius: float = float(
					radius_value
				)

				var combined_radius: float = (
					hit_radius
					+ blocker_radius
				)

				hit = (
					next_position.distance_squared_to(
						blocker.global_position
					)
					<= combined_radius
					* combined_radius
				)

		if not hit:
			continue

		global_position = next_position

		return true

	return false


func _activate() -> void:
	if activated:
		return

	activated = true

	fuse_timer = fuse_duration
	blink_timer = 0.0

	_refresh_scene_visual_state()


func receive_damage(info: RefCounted) -> RefCounted:
	if activated:
		var blocked: RefCounted = DamageResolverScript.resolve_amount(
			self, info, {}, 0
		)
		blocked.blocked = true
		blocked.final_amount = 0
		return blocked
	return DamageResolverScript.receive_with_legacy_handler(
		self, info, damage_multipliers, armor
	)


func take_damage(
	_amount: int
) -> void:
	if activated:
		return

	_activate()


func trigger_from_enemy_bullet() -> void:
	if activated:
		return

	_activate()


func trigger_from_explosion() -> void:
	if explosion_started or is_queued_for_deletion():
		return

	_explode()


func _explode() -> void:
	if is_queued_for_deletion() or explosion_started:
		return

	explosion_started = true

	var explosion_position: Vector2 = (
		global_position
	)

	_release_carrier()

	is_carried = false
	is_thrown = false

	if is_in_group(
		"carried_explosives"
	):
		remove_from_group(
			"carried_explosives"
		)

	var scene: Node = (
		get_tree().current_scene
	)

	# Damage enemy + boss.
	for enemy_value in get_tree().get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(
			enemy_value
		):
			continue

		if enemy_value.is_queued_for_deletion():
			continue

		var enemy: Node2D = (
			enemy_value as Node2D
		)

		if not is_instance_valid(
			enemy
		):
			continue

		if explosion_position.distance_to(
			enemy.global_position
		) > explosion_radius:
			continue

		if enemy.has_method(
			"apply_hit_knockback"
		):
			enemy.call(
				"apply_hit_knockback",
				explosion_position,
				280.0
			)

		DamageResolverScript.apply_simple_damage(
			enemy, explosion_damage, &"fire", [&"explosion"],
			self, self, explosion_position
		)

	# Damage player.
	var player_value: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)

	if is_instance_valid(
		player_value
	):
		var player: Node2D = (
			player_value as Node2D
		)

		if is_instance_valid(
			player
		):
			var player_distance: float = explosion_position.distance_to(
				player.global_position
			)

			if player_distance <= explosion_radius:
				if player.has_method(
					"apply_hit_knockback"
				):
					var knockback_source: Vector2 = explosion_position
					if player_distance <= 0.001:
						var fallback_direction: Vector2 = Vector2.UP
						if throw_velocity.length_squared() > 0.001:
							fallback_direction = throw_velocity.normalized()
						knockback_source = (
							player.global_position - fallback_direction
						)
					var distance_ratio: float = clampf(
						player_distance / maxf(explosion_radius, 1.0),
						0.0,
						1.0
					)
					var knockback_scale: float = lerpf(
						1.0,
						edge_knockback_ratio,
						distance_ratio
					)
					player.call(
						"apply_hit_knockback",
						knockback_source,
						player_knockback_force * knockback_scale
					)

				DamageResolverScript.apply_simple_damage(
					player, explosion_damage, &"fire", [&"explosion"],
					self, self, explosion_position
				)

	# Damage props + chain reaction.
	for prop_value in get_tree().get_nodes_in_group(
		"destructibles"
	):
		if not is_instance_valid(
			prop_value
		):
			continue

		if prop_value == self:
			continue

		if prop_value.is_queued_for_deletion():
			continue

		var prop: Node2D = (
			prop_value as Node2D
		)

		if not is_instance_valid(
			prop
		):
			continue

		if explosion_position.distance_to(
			prop.global_position
		) > explosion_radius:
			continue

		if prop.has_method("trigger_from_explosion"):
			prop.call("trigger_from_explosion")
		else:
			DamageResolverScript.apply_simple_damage(
				prop, explosion_damage, &"fire", [&"explosion"],
				self, self, explosion_position
			)

	if scene.has_method(
		"notify_prop_destroyed"
	):
		scene.call(
			"notify_prop_destroyed",
			prop_id
		)

	if scene.has_method(
		"spawn_room_fx"
	):
		scene.call(
			"spawn_room_fx",
			explosion_position,
			"explosion"
		)

	if scene.has_method(
		"request_camera_shake"
	):
		scene.call(
			"request_camera_shake",
			11.0
		)

	if scene.has_method(
		"request_hit_stop"
	):
		scene.call(
			"request_hit_stop",
			0.075,
			0.08
		)

	queue_free()


func _restore_world_state() -> void:
	if not is_in_group(
		"bullet_blockers"
	):
		add_to_group(
			"bullet_blockers"
		)

	if not is_in_group(
		"destructibles"
	):
		add_to_group(
			"destructibles"
		)

	if is_instance_valid(
		collision_shape
	):
		collision_shape.set_deferred(
			"disabled",
			false
		)


func _release_carrier() -> void:
	if not is_instance_valid(
		carried_by
	):
		carried_by = null

		return

	var value: Variant = null

	if carried_by.has_meta(
		"carried_object"
	):
		value = carried_by.get_meta(
			"carried_object"
		)

	if value == self:
		carried_by.set_meta(
			"carried_object",
			null
		)

	carried_by = null


func contains_projectile_point(
	global_point: Vector2,
	projectile_radius: float
) -> bool:
	if is_carried:
		return false

	var local_point: Vector2 = to_local(
		global_point
	)

	var rect: Rect2 = Rect2(
		-collision_size * 0.5,
		collision_size
	)

	rect = rect.grow(
		projectile_radius
	)

	return rect.has_point(
		local_point
	)


func _exit_tree() -> void:
	_release_carrier()


func _legacy_draw() -> void:
	draw_rect(
		Rect2(
			-12,
			11,
			24,
			5
		),
		Color8(
			8,
			8,
			12,
			150
		),
		true
	)

	var barrel_color: Color = Color8(
		165,
		48,
		40
	)

	if activated:
		var blink_on: bool = (
			int(
				blink_timer * 20.0
			) % 2
			== 0
		)

		if blink_on:
			barrel_color = Color8(
				255,
				215,
				70
			)

	draw_rect(
		Rect2(
			-10,
			-14,
			20,
			28
		),
		barrel_color,
		true
	)

	draw_rect(
		Rect2(
			-11,
			-10,
			22,
			4
		),
		Color8(
			65,
			50,
			48
		),
		true
	)

	draw_rect(
		Rect2(
			-11,
			6,
			22,
			4
		),
		Color8(
			65,
			50,
			48
		),
		true
	)

	draw_rect(
		Rect2(
			-2,
			-7,
			4,
			10
		),
		Color8(
			255,
			220,
			90
		),
		true
	)

	draw_rect(
		Rect2(
			-2,
			6,
			4,
			3
		),
		Color8(
			255,
			220,
			90
		),
		true
	)

	if activated:
		var fuse_progress: float = clampf(
			fuse_timer
			/ fuse_duration,
			0.0,
			1.0
		)

		var ring_radius: float = lerpf(
			20.0,
			explosion_radius,
			1.0 - fuse_progress
		)

		draw_arc(
			Vector2.ZERO,
			ring_radius,
			0.0,
			TAU,
			32,
			Color(
				1.0,
				0.22,
				0.08,
				0.45
			),
			2.0
		)
