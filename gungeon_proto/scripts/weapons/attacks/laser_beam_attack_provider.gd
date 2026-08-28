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

const MUZZLE_DISTANCE: float = 18.0
const BEAM_VISIBLE_TIME: float = 0.11

var beam_time_left: float = 0.0
var beam_start_local: Vector2 = Vector2.ZERO
var beam_end_local: Vector2 = Vector2.ZERO


func tick(delta: float) -> void:
	beam_time_left = maxf(0.0, beam_time_left - delta)


func perform_attack(
	player: Node2D,
	weapon: Dictionary,
	aim_direction: Vector2,
	weapon_system: Node,
	god_mode: bool
) -> Dictionary:
	var direction: Vector2 = aim_direction.normalized()
	if direction.is_zero_approx():
		return {"performed": false}

	var beam_range: float = float(weapon.get("beam_range", 620.0))
	var origin: Vector2 = player.global_position + direction * MUZZLE_DISTANCE
	var target: Vector2 = origin + direction * beam_range
	var query := PhysicsRayQueryParameters2D.create(origin, target)
	query.exclude = [player.get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var hit: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		target = hit.get("position", target) as Vector2
		var collider_value: Variant = hit.get("collider")
		# Collider có thể đã queue_free trong cùng physics frame (ví dụ
		# beam tick kết liễu enemy lúc scene đang chuyển phòng). Kiểm tra
		# Variant trước khi cast để Godot không cast một freed Object.
		if (
			typeof(collider_value) == TYPE_OBJECT
			and is_instance_valid(collider_value)
		):
			var collider: Node = collider_value as Node
			_apply_beam_damage(player, collider, weapon, target, direction)

	beam_start_local = origin - player.global_position
	beam_end_local = target - player.global_position
	beam_time_left = BEAM_VISIBLE_TIME

	if not god_mode:
		weapon_system.call("consume_round")

	return {
		"performed": true,
		"cooldown": float(weapon.get("fire_interval", 0.1)),
		"recoil": float(weapon.get("recoil", 0.0)),
		"muzzle_flash": BEAM_VISIBLE_TIME,
	}


func draw_held_weapon(
	player: Node2D,
	weapon: Dictionary,
	aim_direction: Vector2
) -> void:
	player.draw_line(
		aim_direction * 7.0,
		aim_direction * MUZZLE_DISTANCE,
		Color8(75, 96, 125),
		5.0
	)
	if beam_time_left <= 0.0:
		return

	var width: float = float(weapon.get("beam_width", 5.0))
	player.draw_line(beam_start_local, beam_end_local, Color(0.12, 0.72, 1.0, 0.3), width + 6.0)
	player.draw_line(beam_start_local, beam_end_local, Color8(48, 205, 255), width)
	player.draw_line(beam_start_local, beam_end_local, Color.WHITE, maxf(1.0, width * 0.28))
	player.draw_circle(beam_end_local, width + 2.0, Color(0.3, 0.88, 1.0, 0.65))


func _apply_beam_damage(
	player: Node2D,
	target: Node,
	weapon: Dictionary,
	hit_position: Vector2,
	direction: Vector2
) -> void:
	var info: RefCounted = DamageInfoScript.create(
		int(weapon.get("damage", 1)),
		StringName(weapon.get("damage_type", "shock")),
		[DamageTypesScript.PROJECTILE]
	)
	info.source = self
	info.instigator = player
	info.hit_position = hit_position
	info.hit_direction = direction
	DamageResolverScript.apply_damage(target, info)
