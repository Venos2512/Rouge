extends Node2D

const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)
const DamageInfoScript = preload(
	"res://gungeon_proto/scripts/combat/damage_info.gd"
)
const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)
const DamageTypesScript = preload(
	"res://gungeon_proto/scripts/combat/damage_types.gd"
)

var direction := Vector2.RIGHT

var speed: float = 480.0
var lifetime: float = 1.4

var damage: int = 1
var damage_type: StringName = DamageTypesScript.PHYSICAL

var hit_radius: float = 9.0

var crowd_service: Node = null


func _ready() -> void:
	add_to_group("player_bullets")
	crowd_service = get_tree().get_first_node_in_group(
		"enemy_crowd_service"
	)
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()
		return

	var enemy_candidates: Array = []

	if (
		is_instance_valid(
			crowd_service
		)
		and crowd_service.has_method(
			"get_enemies_near"
		)
	):
		enemy_candidates = crowd_service.call(
			"get_enemies_near",
			global_position,
			hit_radius + 24.0
		)
	else:
		enemy_candidates = get_tree().get_nodes_in_group(
			"enemies"
		)

	for enemy: Node in enemy_candidates:
		if not is_instance_valid(enemy):
			continue

		var distance_sq := global_position.distance_squared_to(
			enemy.global_position
		)

		if distance_sq <= hit_radius * hit_radius:
			GameAudio.play(self, "bullet_hit_enemy", 0.06)
			if enemy.has_method(
				"apply_hit_knockback"
			):
				enemy.call(
					"apply_hit_knockback",
					global_position,
					90.0
				)

			_apply_projectile_damage(enemy)

			var scene: Node = (
				get_tree().current_scene
			)

			if scene.has_method(
				"request_hit_stop"
			):
				scene.call(
					"request_hit_stop",
					0.022,
					0.18
				)

			if scene.has_method(
				"request_camera_shake"
			):
				scene.call(
					"request_camera_shake",
					1.3
				)

			queue_free()
			return

	for blocker_value in get_tree().get_nodes_in_group(
		"bullet_blockers"
	):
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
			GameAudio.play(self, "bullet_hit_wall", 0.055)
			_apply_projectile_damage(blocker)

			queue_free()
			return


func _apply_projectile_damage(target: Node) -> void:
	var info: RefCounted = DamageInfoScript.create(
		damage,
		damage_type,
		[DamageTypesScript.PROJECTILE]
	)
	info.source = self
	info.instigator = get_parent()
	info.hit_position = global_position
	info.hit_direction = direction
	DamageResolverScript.apply_damage(target, info)


func _draw() -> void:
	draw_rect(
		Rect2(-4, -2, 8, 4),
		Color8(255, 225, 102),
		true
	)

	draw_rect(
		Rect2(-2, -1, 4, 2),
		Color8(255, 250, 205),
		true
	)
