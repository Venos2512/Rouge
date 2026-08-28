extends Node2D

const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)
const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)

var direction := Vector2.RIGHT

var speed := 150.0
var lifetime := 5.0

var hit_radius := 10.0

var pool_active: bool = false

var cached_player: Node2D = null
var cached_carried_explosives: Array[Node] = []
var cached_bullet_blockers: Array[Node] = []


func _ready() -> void:
	visible = false

	set_physics_process(
		false
	)

	add_to_group(
		"enemy_bullet_pool"
	)

	queue_redraw()


func activate_bullet(
	spawn_position: Vector2,
	new_direction: Vector2,
	new_speed: float
) -> void:
	global_position = spawn_position

	direction = new_direction

	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	direction = direction.normalized()

	speed = new_speed
	lifetime = 5.0

	cached_player = (
		get_tree().get_first_node_in_group(
			"player"
		) as Node2D
	)

	cached_carried_explosives = (
		get_tree().get_nodes_in_group(
			"carried_explosives"
		)
	)

	cached_bullet_blockers = (
		get_tree().get_nodes_in_group(
			"bullet_blockers"
		)
	)

	if is_in_group(
		"enemy_bullet_pool"
	):
		remove_from_group(
			"enemy_bullet_pool"
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
		"enemy_bullet_pool"
	):
		add_to_group(
			"enemy_bullet_pool"
		)

	cached_player = null
	cached_carried_explosives.clear()
	cached_bullet_blockers.clear()

	direction = Vector2.RIGHT
	speed = 150.0
	lifetime = 5.0


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	lifetime -= delta

	if lifetime <= 0.0:
		_release_to_pool()
		return

	if is_instance_valid(
		cached_player
	):
		var distance_sq := global_position.distance_squared_to(
			cached_player.global_position
		)

		if distance_sq <= hit_radius * hit_radius:
			GameAudio.play(self, "enemy_bullet_hit_player", 0.04)
			DamageResolverScript.apply_simple_damage(
				cached_player, 1, &"physical", [&"projectile"],
				self, self, global_position, direction
			)

			_release_to_pool()
			return

	# Explosive barrel đang nằm trên tay player không còn là
	# bullet_blocker vật lý, nhưng enemy bullet vẫn có thể bắn trúng.
	for explosive_value in cached_carried_explosives:
		if not is_instance_valid(
			explosive_value
		):
			continue

		if explosive_value.is_queued_for_deletion():
			continue

		var explosive: Node2D = (
			explosive_value as Node2D
		)

		if not is_instance_valid(
			explosive
		):
			continue

		var explosive_radius_value = explosive.get(
			"hit_radius"
		)

		if explosive_radius_value == null:
			continue

		var explosive_radius: float = float(
			explosive_radius_value
		)

		# Tăng nhẹ vùng intercept khi đang cầm để barrel
		# thực sự có thể đỡ viên đạn bay về phía player.
		var combined_explosive_radius: float = (
			explosive_radius
			+ hit_radius
			+ 5.0
		)

		var explosive_distance_sq: float = (
			global_position.distance_squared_to(
				explosive.global_position
			)
		)

		if explosive_distance_sq > (
			combined_explosive_radius
			* combined_explosive_radius
		):
			continue

		if explosive.has_method(
			"trigger_from_enemy_bullet"
		):
			explosive.call(
				"trigger_from_enemy_bullet"
			)

		else:
			DamageResolverScript.apply_simple_damage(
				explosive, 1, &"physical", [&"projectile"],
				self, self, global_position, direction
			)

		_release_to_pool()

		return

	for blocker_value in cached_bullet_blockers:
		if not is_instance_valid(blocker_value):
			continue

		if blocker_value.is_queued_for_deletion():
			continue

		var blocker: Node2D = (
			blocker_value as Node2D
		)

		if not is_instance_valid(blocker):
			continue

		var projectile_hit: bool = false

		if blocker.has_method(
			"contains_projectile_point"
		):
			projectile_hit = bool(
				blocker.call(
					"contains_projectile_point",
					global_position,
					hit_radius
				)
			)

		else:
			var blocker_radius: float = float(
				blocker.get("hit_radius")
			)

			var combined_radius: float = (
				hit_radius
				+ blocker_radius
			)

			var blocker_distance_sq: float = (
				global_position.distance_squared_to(
					blocker.global_position
				)
			)

			projectile_hit = (
				blocker_distance_sq
				<= combined_radius
				* combined_radius
			)

		if projectile_hit:
			DamageResolverScript.apply_simple_damage(
				blocker, 1, &"physical", [&"projectile"],
				self, self, global_position, direction
			)

			_release_to_pool()
			return


func _draw() -> void:
	# Dark outline.
	draw_circle(
		Vector2.ZERO,
		5.0,
		Color8(76, 18, 25)
	)

	draw_circle(
		Vector2.ZERO,
		3.0,
		Color8(244, 70, 76)
	)

	draw_circle(
		Vector2(-1, -1),
		1.0,
		Color8(255, 190, 156)
	)
