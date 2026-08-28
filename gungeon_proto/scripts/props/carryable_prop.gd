@tool
extends StaticBody2D


const GameInputV2 = preload(
	"res://gungeon_proto/scripts/core/game_input_runtime.gd"
)
const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)


@export_group("Prop")
@export_enum(
	"crate",
	"pot",
	"table",
	"pillar"
)
var prop_type: String = "crate"

var prop_id: String = ""

@export var health: int = 3
@export var destructible: bool = true
@export var carryable: bool = true
@export var armor: int = 0
@export var damage_multipliers: Dictionary = {
	&"physical": 1.0, &"fire": 1.5, &"shock": 1.0,
	&"poison": 1.0, &"void": 1.0,
}

@export var hit_radius: float = 16.0
@export var interaction_radius: float = 44.0

@export_group("Throw")
@export var throw_speed: float = 560.0
@export var max_throw_time: float = 3.0
@export var throw_impact_damage: int = 2


var collision_size: Vector2 = Vector2(
	26.0,
	22.0
)

var hit_flash: float = 0.0

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

@onready var flash_overlay: CanvasItem = (
	get_node_or_null(
		"VisualRoot/FlashOverlay"
	) as CanvasItem
)


func _ready() -> void:
	z_index = 5

	_sync_collision_size_from_scene()

	if Engine.is_editor_hint():
		queue_redraw()
		return

	add_to_group(
		"room_props"
	)

	add_to_group(
		"bullet_blockers"
	)

	throw_speed *= float(
		Engine.get_meta(
			"relic_throw_speed_mult",
			1.0
		)
	)

	throw_impact_damage += int(
		Engine.get_meta(
			"relic_throw_damage_bonus",
			0
		)
	)

	if destructible:
		add_to_group(
			"destructibles"
		)

	if carryable:
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
	hit_flash = maxf(
		0.0,
		hit_flash - delta
	)

	_refresh_scene_visual_state()

	var e_down: bool = (
		GameInputV2.interact_pressed()
	)

	var mouse_left_down: bool = (
		GameInputV2.attack_pressed()
	)

	if is_carried:
		_update_carried()

		# E = đặt xuống.
		if (
			e_down
			and not e_key_was_down
		):
			_place_prop()

		# Chuột trái = ném.
		elif (
			mouse_left_down
			and not mouse_left_was_down
		):
			_throw_prop()

		e_key_was_down = e_down
		mouse_left_was_down = mouse_left_down

		queue_redraw()

		return

	if is_thrown:
		_update_thrown(
			delta
		)

		e_key_was_down = e_down
		mouse_left_was_down = mouse_left_down

		queue_redraw()

		return

	_update_prompt()

	if (
		e_down
		and not e_key_was_down
		and _can_pick_up()
	):
		_pick_up()

	e_key_was_down = e_down
	mouse_left_was_down = mouse_left_down

	if hit_flash > 0.0:
		queue_redraw()


func _refresh_scene_visual_state() -> void:
	if is_instance_valid(
		flash_overlay
	):
		flash_overlay.visible = (
			hit_flash > 0.0
		)


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
	if not carryable:
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

	if not carryable:
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

	prompt_label.text = "[E] PICK UP"
	prompt_label.visible = true


func _pick_up() -> void:
	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		return

	if _player_has_carried_object(
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

	_remove_world_state()

	if is_instance_valid(
		prompt_label
	):
		prompt_label.text = (
			"[LMB] THROW   [E] PLACE"
		)

		prompt_label.visible = true

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

	# Object luôn nằm cố định trên đầu player.
	# Không di chuyển theo hướng chuột khi đang cầm.
	var offset: Vector2 = Vector2(
		0.0,
		-38.0
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
		prompt_label.text = (
			"[LMB] THROW   [E] PLACE"
		)

		prompt_label.visible = true


func _throw_prop() -> void:
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

	# Object bay được xử lý bằng custom collision.
	# Không bật lại StaticBody collision trong lúc bay.

	if is_instance_valid(
		prompt_label
	):
		prompt_label.visible = false


func _place_prop() -> void:
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
	z_index = 5

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
		_break_prop()

		return

	global_position = next_position

	rotation += (
		10.0 * delta
	)

	# Không giảm tốc.
	# Bay thẳng cho đến khi va chạm.
	if throw_timer >= max_throw_time:
		_break_prop()


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

		if enemy.has_method(
			"apply_hit_knockback"
		):
			var source_position: Vector2 = (
				global_position
				- throw_velocity.normalized()
				* 18.0
			)

			enemy.call(
				"apply_hit_knockback",
				source_position,
				230.0
			)

		DamageResolverScript.apply_simple_damage(
			enemy, throw_impact_damage, &"physical", [&"thrown_prop"],
			self, carried_by, enemy.global_position, throw_velocity.normalized()
		)

		var scene: Node = (
			get_tree().current_scene
		)

		if scene.has_method(
			"spawn_room_fx"
		):
			scene.call(
				"spawn_room_fx",
				next_position,
				"impact"
			)

		if scene.has_method(
			"request_camera_shake"
		):
			scene.call(
				"request_camera_shake",
				4.0
			)

		if scene.has_method(
			"request_hit_stop"
		):
			scene.call(
				"request_hit_stop",
				0.045,
				0.12
			)

		_break_prop()

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

		DamageResolverScript.apply_simple_damage(
			blocker, 1, &"physical", [&"thrown_prop"],
			self, carried_by, blocker.global_position, throw_velocity.normalized()
		)

		var scene: Node = (
			get_tree().current_scene
		)

		if scene.has_method(
			"spawn_room_fx"
		):
			scene.call(
				"spawn_room_fx",
				next_position,
				"impact"
			)

		return true

	return false


func _restore_world_state() -> void:
	if not is_in_group(
		"bullet_blockers"
	):
		add_to_group(
			"bullet_blockers"
		)

	if (
		destructible
		and not is_in_group(
			"destructibles"
		)
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


func receive_damage(info: RefCounted) -> RefCounted:
	if not destructible or is_carried:
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
	amount: int
) -> void:
	if not destructible:
		return

	# Đồ trên tay player không nhận bullet damage.
	if is_carried:
		return

	health -= amount

	hit_flash = 0.08

	if health <= 0:
		_break_prop()

	else:
		queue_redraw()


func _break_prop() -> void:
	_release_carrier()

	var scene: Node = (
		get_tree().current_scene
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
			global_position,
			"break"
		)

	queue_free()


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
	var flash_color: Color = Color8(
		255,
		245,
		220
	)

	if prop_type == "pillar":
		draw_rect(
			Rect2(
				-14,
				-20,
				28,
				40
			),
			Color8(
				78,
				74,
				82
			),
			true
		)

		draw_rect(
			Rect2(
				-17,
				-20,
				34,
				7
			),
			Color8(
				105,
				99,
				105
			),
			true
		)

		draw_rect(
			Rect2(
				-17,
				13,
				34,
				7
			),
			Color8(
				55,
				53,
				60
			),
			true
		)

		return

	if prop_type == "table":
		var table_color: Color = Color8(
			103,
			66,
			45
		)

		if hit_flash > 0.0:
			table_color = flash_color

		draw_rect(
			Rect2(
				-22,
				-9,
				44,
				18
			),
			table_color,
			true
		)

		draw_rect(
			Rect2(
				-20,
				-7,
				40,
				5
			),
			Color8(
				145,
				92,
				55
			),
			true
		)

		draw_rect(
			Rect2(
				-18,
				8,
				5,
				6
			),
			Color8(
				65,
				43,
				35
			),
			true
		)

		draw_rect(
			Rect2(
				13,
				8,
				5,
				6
			),
			Color8(
				65,
				43,
				35
			),
			true
		)

		return

	if prop_type == "pot":
		var pot_color: Color = Color8(
			145,
			82,
			55
		)

		if hit_flash > 0.0:
			pot_color = flash_color

		draw_rect(
			Rect2(
				-6,
				-7,
				12,
				14
			),
			pot_color,
			true
		)

		draw_rect(
			Rect2(
				-8,
				-8,
				16,
				4
			),
			Color8(
				185,
				110,
				70
			),
			true
		)

		return

	var crate_color: Color = Color8(
		129,
		83,
		49
	)

	if hit_flash > 0.0:
		crate_color = flash_color

	draw_rect(
		Rect2(
			-13,
			-11,
			26,
			22
		),
		crate_color,
		true
	)

	draw_rect(
		Rect2(
			-11,
			-9,
			22,
			18
		),
		Color8(
			158,
			103,
			58
		),
		false,
		2.0
	)

	draw_line(
		Vector2(
			-10,
			-8
		),
		Vector2(
			10,
			8
		),
		Color8(
			91,
			57,
			42
		),
		3.0
	)

	draw_line(
		Vector2(
			10,
			-8
		),
		Vector2(
			-10,
			8
		),
		Color8(
			91,
			57,
			42
		),
		3.0
	)
