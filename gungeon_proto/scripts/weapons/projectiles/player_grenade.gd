class_name PlayerGrenade
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

const EXPLOSION_VISUAL_DURATION: float = 0.14
const HIT_RADIUS: float = 8.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = 330.0
var lifetime: float = 1.1
var damage: int = 5
var damage_type: StringName = DamageTypesScript.PHYSICAL
var explosion_radius: float = 78.0
var explosion_knockback: float = 220.0

var crowd_service: Node = null
var exploded: bool = false
var explosion_visual_timer: float = 0.0


func _ready() -> void:
	z_index = 28
	add_to_group("player_bullets")
	add_to_group("player_projectiles")
	crowd_service = get_tree().get_first_node_in_group(
		"enemy_crowd_service"
	)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if exploded:
		explosion_visual_timer -= delta
		queue_redraw()
		if explosion_visual_timer <= 0.0:
			queue_free()
		return

	global_position += direction * speed * delta
	rotation += delta * 9.0
	lifetime -= delta

	if lifetime <= 0.0 or _touches_enemy() or _touches_blocker():
		_explode()
		return

	queue_redraw()


func _touches_enemy() -> bool:
	var candidates: Array = []
	if (
		is_instance_valid(crowd_service)
		and crowd_service.has_method("get_enemies_near")
	):
		candidates = crowd_service.call(
			"get_enemies_near",
			global_position,
			HIT_RADIUS + 24.0
		)
	else:
		candidates = get_tree().get_nodes_in_group("enemies")

	for enemy_value: Variant in candidates:
		var enemy: Node2D = enemy_value as Node2D
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_squared_to(enemy.global_position) <= HIT_RADIUS * HIT_RADIUS:
			return true

	return false


func _touches_blocker() -> bool:
	for blocker_value: Variant in get_tree().get_nodes_in_group(
		"bullet_blockers"
	):
		var blocker: Node2D = blocker_value as Node2D
		if not is_instance_valid(blocker) or blocker.is_queued_for_deletion():
			continue

		if blocker.has_method("contains_projectile_point"):
			if bool(blocker.call(
				"contains_projectile_point",
				global_position,
				HIT_RADIUS
			)):
				return true
			continue

		var blocker_radius: float = float(blocker.get("hit_radius"))
		var combined_radius: float = HIT_RADIUS + blocker_radius
		if global_position.distance_squared_to(blocker.global_position) <= combined_radius * combined_radius:
			return true

	return false


func _explode() -> void:
	if exploded:
		return

	exploded = true
	explosion_visual_timer = EXPLOSION_VISUAL_DURATION
	GameAudio.play(self, "bomb_explosion", 0.035)

	var candidates: Array = []
	if (
		is_instance_valid(crowd_service)
		and crowd_service.has_method("get_enemies_near")
	):
		candidates = crowd_service.call(
			"get_enemies_near",
			global_position,
			explosion_radius
		)
	else:
		candidates = get_tree().get_nodes_in_group("enemies")

	var radius_squared: float = explosion_radius * explosion_radius
	for enemy_value: Variant in candidates:
		var enemy: Node2D = enemy_value as Node2D
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_squared_to(enemy.global_position) > radius_squared:
			continue
		if enemy.has_method("apply_hit_knockback"):
			enemy.call(
				"apply_hit_knockback",
				global_position,
				explosion_knockback
			)
		_apply_explosion_damage(enemy)

	_damage_destructibles()

	var scene: Node = get_tree().current_scene
	if is_instance_valid(scene):
		if scene.has_method("request_hit_stop"):
			scene.call("request_hit_stop", 0.035, 0.16)
		if scene.has_method("request_camera_shake"):
			scene.call("request_camera_shake", 3.2)

	queue_redraw()


func _damage_destructibles() -> void:
	var radius_squared: float = explosion_radius * explosion_radius
	for prop_value: Variant in get_tree().get_nodes_in_group(
		"destructibles"
	):
		var prop: Node2D = prop_value as Node2D
		if not is_instance_valid(prop) or prop.is_queued_for_deletion():
			continue
		if global_position.distance_squared_to(prop.global_position) > radius_squared:
			continue
		_apply_explosion_damage(prop)


func _apply_explosion_damage(target: Node) -> void:
	var info: RefCounted = DamageInfoScript.create(
		damage,
		damage_type,
		[DamageTypesScript.PROJECTILE, DamageTypesScript.EXPLOSION]
	)
	info.source = self
	info.instigator = get_parent()
	info.hit_position = global_position
	DamageResolverScript.apply_damage(target, info)


func _draw() -> void:
	if exploded:
		var progress: float = clampf(
			1.0 - explosion_visual_timer / EXPLOSION_VISUAL_DURATION,
			0.0,
			1.0
		)
		var alpha: float = 1.0 - progress
		var blast_radius: float = lerpf(12.0, explosion_radius, progress)
		draw_circle(
			Vector2.ZERO,
			blast_radius,
			Color(1.0, 0.24, 0.04, 0.22 * alpha)
		)
		draw_circle(
			Vector2.ZERO,
			lerpf(7.0, 25.0, progress),
			Color(1.0, 0.72, 0.18, 0.85 * alpha)
		)
		return

	draw_circle(Vector2.ZERO, 7.0, Color8(54, 61, 47))
	draw_circle(Vector2(-2.0, -2.0), 2.0, Color8(171, 198, 91))
	draw_line(
		Vector2(4.0, -5.0),
		Vector2(8.0, -9.0),
		Color8(255, 170, 55),
		2.0
	)
