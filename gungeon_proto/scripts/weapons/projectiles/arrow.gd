class_name PlayerArrow
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

const MAX_COLLISION_STEPS: int = 12

var direction: Vector2 = Vector2.RIGHT
var speed: float = 720.0
var lifetime: float = 1.25
var embedded_lifetime: float = 4.0
var damage: int = 5
var damage_type: StringName = DamageTypesScript.PHYSICAL
var hit_radius: float = 7.0

var embedded: bool = false
var crowd_service: Node = null
var blockers: Array[Node] = []


func _ready() -> void:
	add_to_group("player_bullets")
	add_to_group("player_projectiles")
	crowd_service = get_tree().get_first_node_in_group(
		"enemy_crowd_service"
	)
	for blocker: Node in get_tree().get_nodes_in_group(
		"bullet_blockers"
	):
		blockers.append(blocker)
	rotation = direction.angle()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if embedded:
		embedded_lifetime -= delta
		if embedded_lifetime <= 0.0:
			queue_free()
		return

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	var travel: Vector2 = direction * speed * delta
	var start_position: Vector2 = global_position
	var end_position: Vector2 = start_position + travel

	var enemy: Node2D = _find_enemy_hit(start_position, end_position)
	if is_instance_valid(enemy):
		global_position = _closest_point_on_segment(
			enemy.global_position,
			start_position,
			end_position
		)
		_embed_in_target(enemy, true)
		return

	var blocker: Node2D = _find_blocker_hit(
		start_position,
		end_position,
		travel.length()
	)
	if is_instance_valid(blocker):
		_embed_in_target(blocker, false)
		return

	global_position = end_position


func _find_enemy_hit(
	start_position: Vector2,
	end_position: Vector2
) -> Node2D:
	var candidates: Array = []
	var query_radius: float = (
		start_position.distance_to(end_position)
		+ hit_radius
		+ 24.0
	)
	if (
		is_instance_valid(crowd_service)
		and crowd_service.has_method("get_enemies_near")
	):
		candidates = crowd_service.call(
			"get_enemies_near",
			(start_position + end_position) * 0.5,
			query_radius
		)
	else:
		candidates = get_tree().get_nodes_in_group("enemies")

	var closest_enemy: Node2D = null
	var closest_progress: float = INF
	for candidate: Node in candidates:
		var enemy: Node2D = candidate as Node2D
		if not is_instance_valid(enemy):
			continue
		var closest_point: Vector2 = _closest_point_on_segment(
			enemy.global_position,
			start_position,
			end_position
		)
		if (
			closest_point.distance_squared_to(enemy.global_position)
			> hit_radius * hit_radius
		):
			continue
		var progress: float = start_position.distance_squared_to(closest_point)
		if progress < closest_progress:
			closest_progress = progress
			closest_enemy = enemy

	return closest_enemy


func _find_blocker_hit(
	start_position: Vector2,
	end_position: Vector2,
	travel_distance: float
) -> Node2D:
	var step_count: int = clampi(
		ceili(travel_distance / maxf(hit_radius, 1.0)),
		1,
		MAX_COLLISION_STEPS
	)
	for step: int in range(1, step_count + 1):
		var sample_position: Vector2 = start_position.lerp(
			end_position,
			float(step) / float(step_count)
		)
		for blocker_value: Node in blockers:
			var blocker: Node2D = blocker_value as Node2D
			if (
				not is_instance_valid(blocker)
				or blocker.is_queued_for_deletion()
			):
				continue
			if _blocker_contains(blocker, sample_position):
				global_position = sample_position
				return blocker
	return null


func _blocker_contains(
	blocker: Node2D,
	point: Vector2
) -> bool:
	if blocker.has_method("contains_projectile_point"):
		return bool(blocker.call(
			"contains_projectile_point",
			point,
			hit_radius
		))
	var blocker_radius: float = float(blocker.get("hit_radius"))
	var combined_radius: float = hit_radius + blocker_radius
	return point.distance_squared_to(blocker.global_position) <= (
		combined_radius * combined_radius
	)


func _embed_in_target(
	target: Node2D,
	is_enemy: bool
) -> void:
	if is_enemy:
		GameAudio.play(self, "bullet_hit_enemy", 0.06)
		if target.has_method("apply_hit_knockback"):
			target.call("apply_hit_knockback", global_position, 125.0)
	else:
		GameAudio.play(self, "bullet_hit_wall", 0.055)

	_apply_projectile_damage(target)
	embedded = true
	speed = 0.0
	remove_from_group("player_bullets")
	remove_from_group("player_projectiles")
	if is_instance_valid(target) and not target.is_queued_for_deletion():
		reparent(target, true)


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


func _closest_point_on_segment(
	point: Vector2,
	segment_start: Vector2,
	segment_end: Vector2
) -> Vector2:
	var segment: Vector2 = segment_end - segment_start
	var length_squared: float = segment.length_squared()
	if length_squared <= 0.0001:
		return segment_start
	var progress: float = clampf(
		(point - segment_start).dot(segment) / length_squared,
		0.0,
		1.0
	)
	return segment_start + segment * progress


func _draw() -> void:
	draw_line(
		Vector2(-12.0, 0.0),
		Vector2(7.0, 0.0),
		Color8(119, 78, 43),
		2.0
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(11.0, 0.0),
			Vector2(5.0, -3.5),
			Vector2(5.0, 3.5),
		]),
		Color8(205, 215, 222)
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-12.0, 0.0),
			Vector2(-7.0, -3.0),
			Vector2(-7.0, 3.0),
		]),
		Color8(175, 56, 44)
	)
