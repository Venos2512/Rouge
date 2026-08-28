class_name LaserBeamAttackProvider
extends "res://gungeon_proto/scripts/weapons/attacks/weapon_attack_provider.gd"


const DamageInfoScript = preload(
	"res://gungeon_proto/scripts/combat/damage_info.gd"
)
const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)
const DamageTypesScript = preload(
	"res://gungeon_proto/scripts/combat/damage_types.gd"
)

const MAX_BLOCKER_SAMPLES: int = 96
const BLOCKER_CACHE_INTERVAL: float = 0.5

var beam_visible_timer: float = 0.0
var beam_start: Vector2 = Vector2.ZERO
var beam_end: Vector2 = Vector2.ZERO
var beam_width: float = 6.0
var blocker_cache_timer: float = 0.0
var blockers: Array[Node] = []
var crowd_service: Node = null


func tick(delta: float) -> void:
	beam_visible_timer = maxf(beam_visible_timer - delta, 0.0)
	blocker_cache_timer = maxf(blocker_cache_timer - delta, 0.0)


func perform_attack(
	player: Node2D,
	weapon: Dictionary,
	aim_direction: Vector2,
	weapon_system: Node,
	god_mode: bool
) -> Dictionary:
	var direction: Vector2 = aim_direction.normalized()
	var beam_range: float = float(weapon.get("beam_range", 620.0))
	beam_width = float(weapon.get("beam_width", 7.0))
	_refresh_runtime_cache(player)
	beam_start = player.global_position + direction * 18.0
	beam_end = beam_start + direction * beam_range

	var blocker_distance: float = _find_blocker_distance(
		beam_start,
		direction,
		beam_range
	)
	var enemy: Node2D = _find_first_enemy(
		player,
		beam_start,
		direction,
		blocker_distance
	)
	if is_instance_valid(enemy):
		var hit_distance: float = clampf(
			(enemy.global_position - beam_start).dot(direction),
			0.0,
			blocker_distance
		)
		beam_end = beam_start + direction * hit_distance
		_apply_beam_damage(player, enemy, weapon, direction)
	else:
		beam_end = beam_start + direction * blocker_distance

	beam_visible_timer = (
		float(weapon.get("fire_interval", 0.08))
		+ 0.035
	)
	player.queue_redraw()

	if not god_mode:
		weapon_system.call("consume_round")

	return {
		"performed": true,
		"cooldown": float(weapon.get("fire_interval", 0.08)),
		"recoil": float(weapon.get("recoil", 0.35)),
		"muzzle_flash": 0.025,
	}


func draw_held_weapon(
	player: Node2D,
	_weapon: Dictionary,
	aim_direction: Vector2
) -> void:
	var side: Vector2 = aim_direction.orthogonal()
	player.draw_line(
		aim_direction * 6.0,
		aim_direction * 19.0,
		Color8(73, 91, 112),
		5.0
	)
	player.draw_line(
		aim_direction * 11.0 + side * 5.0,
		aim_direction * 11.0 - side * 5.0,
		Color8(80, 232, 255),
		2.0
	)

	if beam_visible_timer <= 0.0:
		return

	var local_start: Vector2 = player.to_local(beam_start)
	var local_end: Vector2 = player.to_local(beam_end)
	player.draw_line(
		local_start,
		local_end,
		Color8(35, 104, 158, 135),
		beam_width + 5.0
	)
	player.draw_line(
		local_start,
		local_end,
		Color8(77, 230, 255),
		beam_width
	)
	player.draw_line(
		local_start,
		local_end,
		Color.WHITE,
		maxf(beam_width * 0.28, 1.0)
	)
	player.draw_circle(
		local_end,
		beam_width * 0.75,
		Color8(126, 244, 255, 210)
	)


func _find_first_enemy(
	player: Node2D,
	start: Vector2,
	direction: Vector2,
	maximum_distance: float
) -> Node2D:
	var candidates: Array = []
	if (
		is_instance_valid(crowd_service)
		and crowd_service.has_method("get_enemies_near")
	):
		candidates = crowd_service.call(
			"get_enemies_near",
			start + direction * maximum_distance * 0.5,
			maximum_distance * 0.55 + beam_width
		)
	else:
		candidates = player.get_tree().get_nodes_in_group("enemies")

	var closest_enemy: Node2D = null
	var closest_distance: float = maximum_distance + 1.0
	for candidate: Node in candidates:
		var enemy: Node2D = candidate as Node2D
		if not is_instance_valid(enemy):
			continue
		var offset: Vector2 = enemy.global_position - start
		var forward_distance: float = offset.dot(direction)
		if forward_distance < 0.0 or forward_distance > maximum_distance:
			continue
		var perpendicular_distance: float = absf(
			offset.cross(direction)
		)
		if perpendicular_distance > beam_width + 7.0:
			continue
		if forward_distance < closest_distance:
			closest_distance = forward_distance
			closest_enemy = enemy

	return closest_enemy


func _find_blocker_distance(
	start: Vector2,
	direction: Vector2,
	maximum_distance: float
) -> float:
	var sample_spacing: float = maxf(beam_width, 6.0)
	var sample_count: int = mini(
		ceili(maximum_distance / sample_spacing),
		MAX_BLOCKER_SAMPLES
	)
	for sample_index: int in range(1, sample_count + 1):
		var distance: float = (
			maximum_distance
			* float(sample_index)
			/ float(sample_count)
		)
		var point: Vector2 = start + direction * distance
		for blocker_value: Node in blockers:
			var blocker: Node2D = blocker_value as Node2D
			if (
				not is_instance_valid(blocker)
				or blocker.is_queued_for_deletion()
			):
				continue
			if _blocker_contains(blocker, point):
				return distance
	return maximum_distance


func _refresh_runtime_cache(player: Node2D) -> void:
	if not is_instance_valid(crowd_service):
		crowd_service = player.get_tree().get_first_node_in_group(
			"enemy_crowd_service"
		)
	if blocker_cache_timer > 0.0 and not blockers.is_empty():
		return
	blockers.clear()
	for blocker: Node in player.get_tree().get_nodes_in_group(
		"bullet_blockers"
	):
		blockers.append(blocker)
	blocker_cache_timer = BLOCKER_CACHE_INTERVAL


func _blocker_contains(
	blocker: Node2D,
	point: Vector2
) -> bool:
	if blocker.has_method("contains_projectile_point"):
		return bool(blocker.call(
			"contains_projectile_point",
			point,
			beam_width * 0.5
		))
	var blocker_radius: float = float(blocker.get("hit_radius"))
	var combined_radius: float = blocker_radius + beam_width * 0.5
	return point.distance_squared_to(blocker.global_position) <= (
		combined_radius * combined_radius
	)


func _apply_beam_damage(
	player: Node2D,
	target: Node,
	weapon: Dictionary,
	direction: Vector2
) -> void:
	var info: RefCounted = DamageInfoScript.create(
		int(weapon.get("damage", 1)),
		StringName(weapon.get("damage_type", "shock")),
		[DamageTypesScript.PROJECTILE]
	)
	info.source = player
	info.instigator = player
	info.hit_position = beam_end
	info.hit_direction = direction
	DamageResolverScript.apply_damage(target, info)
