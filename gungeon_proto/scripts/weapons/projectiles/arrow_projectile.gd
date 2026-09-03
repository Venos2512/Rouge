class_name ArrowProjectile
extends Node2D

const GameAudio = preload("res://gungeon_proto/scripts/audio/game_audio.gd")
const DamageInfoScript = preload("res://gungeon_proto/scripts/combat/damage_info.gd")
const DamageResolverScript = preload("res://gungeon_proto/scripts/combat/damage_resolver.gd")
const DamageTypesScript = preload("res://gungeon_proto/scripts/combat/damage_types.gd")

const MAX_TRAVEL_STEP: float = 6.0
const MAX_EMBEDDED_ARROWS: int = 32

var direction: Vector2 = Vector2.RIGHT
var speed: float = 720.0
var lifetime: float = 1.6
var embedded_lifetime: float = 6.0
var damage: int = 4
var damage_type: StringName = DamageTypesScript.PHYSICAL
var hit_radius: float = 7.0
var crowd_service: Node = null
var embedded: bool = false


func _ready() -> void:
	add_to_group("player_bullets")
	crowd_service = get_tree().get_first_node_in_group("enemy_crowd_service")
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

	var travel_distance: float = speed * delta
	var step_count: int = maxi(1, int(ceil(travel_distance / MAX_TRAVEL_STEP)))
	var step_vector: Vector2 = direction * travel_distance / float(step_count)
	for _step: int in range(step_count):
		global_position += step_vector
		if _try_hit_enemy() or _try_hit_blocker():
			return


func _try_hit_enemy() -> bool:
	var enemy_candidates: Array = []
	if is_instance_valid(crowd_service) and crowd_service.has_method("get_enemies_near"):
		enemy_candidates = crowd_service.call("get_enemies_near", global_position, hit_radius + 24.0)
	else:
		enemy_candidates = get_tree().get_nodes_in_group("enemies")

	for enemy_value: Node in enemy_candidates:
		var enemy: Node2D = enemy_value as Node2D
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if global_position.distance_squared_to(enemy.global_position) > hit_radius * hit_radius:
			continue

		GameAudio.play(self, "bullet_hit_enemy", 0.06)
		if enemy.has_method("apply_hit_knockback"):
			enemy.call("apply_hit_knockback", global_position, 115.0)
		_apply_projectile_damage(enemy)
		_request_hit_feedback()
		_embed_in(enemy)
		return true

	return false


func _try_hit_blocker() -> bool:
	for blocker_value: Node in get_tree().get_nodes_in_group("bullet_blockers"):
		var blocker: Node2D = blocker_value as Node2D
		if not is_instance_valid(blocker) or blocker.is_queued_for_deletion():
			continue

		var projectile_hit: bool = false
		if blocker.has_method("contains_projectile_point"):
			projectile_hit = bool(blocker.call("contains_projectile_point", global_position, hit_radius))
		else:
			var blocker_radius: float = float(blocker.get("hit_radius"))
			var combined_radius: float = hit_radius + blocker_radius
			projectile_hit = global_position.distance_squared_to(blocker.global_position) <= combined_radius * combined_radius

		if projectile_hit:
			GameAudio.play(self, "bullet_hit_wall", 0.055)
			_apply_projectile_damage(blocker)
			_embed_in(blocker)
			return true

	return false


func _apply_projectile_damage(target: Node) -> void:
	var info: RefCounted = DamageInfoScript.create(damage, damage_type, [DamageTypesScript.PROJECTILE])
	info.source = self
	info.instigator = get_parent()
	info.hit_position = global_position
	info.hit_direction = direction
	DamageResolverScript.apply_damage(target, info)


func _embed_in(target: Node2D) -> void:
	embedded = true
	remove_from_group("player_bullets")
	add_to_group("embedded_arrows")
	if is_instance_valid(target) and not target.is_queued_for_deletion():
		reparent(target, true)

	var arrows: Array[Node] = get_tree().get_nodes_in_group("embedded_arrows")
	if arrows.size() > MAX_EMBEDDED_ARROWS:
		var oldest_arrow: Node = arrows.front()
		if is_instance_valid(oldest_arrow) and oldest_arrow != self:
			oldest_arrow.queue_free()


func _request_hit_feedback() -> void:
	var scene: Node = get_tree().current_scene
	if scene.has_method("request_hit_stop"):
		scene.call("request_hit_stop", 0.028, 0.2)
	if scene.has_method("request_camera_shake"):
		scene.call("request_camera_shake", 1.6)


func _draw() -> void:
	draw_line(Vector2(-12.0, 0.0), Vector2(9.0, 0.0), Color8(139, 91, 52), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(12.0, 0.0), Vector2(7.0, -3.0), Vector2(7.0, 3.0)]), Color8(214, 222, 226))
	draw_line(Vector2(-10.0, 0.0), Vector2(-14.0, -4.0), Color8(224, 196, 126), 2.0)
	draw_line(Vector2(-10.0, 0.0), Vector2(-14.0, 4.0), Color8(224, 196, 126), 2.0)
