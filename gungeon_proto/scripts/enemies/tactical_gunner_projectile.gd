extends Node2D

const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)


var direction: Vector2 = Vector2.RIGHT
var speed: float = 285.0
var damage: int = 1

var lifetime: float = 2.6
var hit_radius: float = 4.5

# Một projectile đã được dodge xuyên qua thì
# không được phép hit lại player ở frame sau.
var dodged_player: bool = false

var cached_player: Node2D = null
var cached_blockers: Array[Node] = []

var pool_active: bool = false


func _ready() -> void:
	z_index = 14

	visible = false
	set_physics_process(
		false
	)

	add_to_group(
		"tactical_projectile_pool"
	)

	queue_redraw()


func activate_projectile(
	spawn_position: Vector2,
	new_direction: Vector2,
	new_speed: float,
	new_damage: int
) -> void:
	global_position = spawn_position

	direction = new_direction

	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	direction = direction.normalized()

	speed = new_speed
	damage = new_damage

	lifetime = 2.6
	dodged_player = false

	cached_player = (
		get_tree().get_first_node_in_group(
			"player"
		) as Node2D
	)

	cached_blockers = (
		get_tree().get_nodes_in_group(
			"bullet_blockers"
		)
	)

	if is_in_group(
		"tactical_projectile_pool"
	):
		remove_from_group(
			"tactical_projectile_pool"
		)

	if not is_in_group(
		"enemy_bullets"
	):
		add_to_group(
			"enemy_bullets"
		)

	if not is_in_group(
		"enemy_projectiles"
	):
		add_to_group(
			"enemy_projectiles"
		)

	if not is_in_group(
		"room_entities"
	):
		add_to_group(
			"room_entities"
		)

	pool_active = true
	visible = true

	set_physics_process(
		true
	)

	queue_redraw()


func _release_to_pool() -> void:
	if not pool_active:
		return

	pool_active = false

	set_physics_process(
		false
	)

	visible = false

	if is_in_group(
		"enemy_bullets"
	):
		remove_from_group(
			"enemy_bullets"
		)

	if is_in_group(
		"enemy_projectiles"
	):
		remove_from_group(
			"enemy_projectiles"
		)

	if is_in_group(
		"room_entities"
	):
		remove_from_group(
			"room_entities"
		)

	if not is_in_group(
		"tactical_projectile_pool"
	):
		add_to_group(
			"tactical_projectile_pool"
		)

	cached_player = null
	cached_blockers.clear()

	direction = Vector2.RIGHT
	speed = 285.0
	damage = 1
	lifetime = 2.6
	dodged_player = false


func _physics_process(
	delta: float
) -> void:
	lifetime -= delta

	if lifetime <= 0.0:
		_release_to_pool()
		return

	var next_position: Vector2 = (
		global_position
		+ direction * speed * delta
	)

	if _check_world_impact(
		next_position
	):
		return

	if _check_player_impact(
		next_position
	):
		return

	global_position = next_position


func _check_player_impact(
	next_position: Vector2
) -> bool:
	if not is_instance_valid(
		cached_player
	):
		return false

	var player: Node2D = cached_player

	# Nếu projectile này đã được dodge thành công,
	# nó tiếp tục bay và không bao giờ bắt lại
	# chính player đó sau khi roll kết thúc.
	if dodged_player:
		return false

	var combined_radius: float = (
		hit_radius + 12.0
	)

	if next_position.distance_squared_to(
		player.global_position
	) > (
		combined_radius
		* combined_radius
	):
		return false

	var rolling_value: Variant = player.get(
		"is_rolling"
	)

	if (
		rolling_value != null
		and bool(rolling_value)
	):
		dodged_player = true

		return false

	global_position = next_position

	DamageResolverScript.apply_simple_damage(
		player, damage, &"physical", [&"projectile"],
		self, self, global_position, direction
	)

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
			next_position,
			"impact"
		)

	_release_to_pool()

	return true


func _check_world_impact(
	next_position: Vector2
) -> bool:
	for blocker_value: Node in cached_blockers:
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
			var blocker_radius: float = (
				_read_number_property(
					blocker,
					"hit_radius",
					0.0
				)
			)

			if blocker_radius > 0.0:
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

		if blocker.has_method(
			"trigger_from_enemy_bullet"
		):
			blocker.call(
				"trigger_from_enemy_bullet"
			)

		_release_to_pool()

		return true

	return false


func _read_number_property(
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
	draw_circle(
		Vector2.ZERO,
		4.5,
		Color(
			1.0,
			0.48,
			0.18,
			1.0
		)
	)

	draw_circle(
		Vector2.ZERO,
		2.0,
		Color(
			1.0,
			0.92,
			0.55,
			1.0
		)
	)
