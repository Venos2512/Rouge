class_name DamageResolver
extends RefCounted


const DamageResultScript = preload(
	"res://gungeon_proto/scripts/combat/damage_result.gd"
)
const DamageInfoScript = preload(
	"res://gungeon_proto/scripts/combat/damage_info.gd"
)
const DamageTypesScript = preload(
	"res://gungeon_proto/scripts/combat/damage_types.gd"
)

static func apply_damage(
	target: Node,
	info: RefCounted
) -> RefCounted:
	var result: RefCounted = DamageResultScript.new()
	result.requested_amount = info.amount
	result.damage_type = info.damage_type
	result.critical = info.critical

	if not is_instance_valid(target) or info.amount <= 0:
		result.blocked = true
		return result

	if target.has_method("receive_damage"):
		var receiver_result: Variant = target.call(
			"receive_damage",
			info
		)
		if receiver_result is RefCounted:
			return receiver_result as RefCounted

	# Tương thích các receiver chưa được migrate.
	if not target.has_method("take_damage"):
		result.blocked = true
		return result

	var health_before: int = _read_health(target)
	target.call("take_damage", info.amount)
	var health_after: int = _read_health(target)

	result.final_amount = info.amount
	result.used_legacy_receiver = true
	result.killed = health_before > 0 and health_after == 0
	return result


static func apply_simple_damage(
	target: Node,
	amount: int,
	damage_type: StringName = DamageTypesScript.PHYSICAL,
	delivery_tags: Array[StringName] = [],
	source: Node = null,
	instigator: Node = null,
	hit_position: Vector2 = Vector2.ZERO,
	hit_direction: Vector2 = Vector2.ZERO
) -> RefCounted:
	var info: RefCounted = DamageInfoScript.create(
		amount,
		damage_type,
		delivery_tags
	)
	info.source = source
	info.instigator = instigator
	info.hit_position = hit_position
	info.hit_direction = hit_direction
	return apply_damage(target, info)


static func resolve_amount(
	target: Node,
	info: RefCounted,
	damage_multipliers: Dictionary,
	armor: int = 0
) -> RefCounted:
	var result: RefCounted = DamageResultScript.new()
	result.requested_amount = info.amount
	result.damage_type = info.damage_type
	result.critical = info.critical

	var multiplier: float = float(
		damage_multipliers.get(info.damage_type, 1.0)
	)
	var scaled_amount: float = float(info.amount) * maxf(multiplier, 0.0)
	var effective_armor: float = maxf(
		float(armor) * (1.0 - clampf(info.armor_pierce, 0.0, 1.0)),
		0.0
	)
	result.final_amount = maxi(
		ceili(scaled_amount - effective_armor),
		0
	)
	result.blocked = result.final_amount <= 0
	return result


static func receive_with_legacy_handler(
	target: Node,
	info: RefCounted,
	damage_multipliers: Dictionary = {},
	armor: int = 0
) -> RefCounted:
	var active_multipliers: Dictionary = damage_multipliers
	if active_multipliers.is_empty():
		active_multipliers = default_multipliers()

	var result: RefCounted = resolve_amount(
		target,
		info,
		active_multipliers,
		armor
	)
	if result.blocked or not target.has_method("take_damage"):
		result.blocked = true
		return result

	var health_before: int = _read_health(target)
	target.call("take_damage", result.final_amount)
	var health_after: int = _read_health(target)
	result.killed = health_before > 0 and health_after == 0
	return result


static func default_multipliers() -> Dictionary:
	return {
		DamageTypesScript.PHYSICAL: 1.0,
		DamageTypesScript.FIRE: 1.0,
		DamageTypesScript.SHOCK: 1.0,
		DamageTypesScript.POISON: 1.0,
		DamageTypesScript.VOID: 1.0,
	}


static func _read_health(target: Node) -> int:
	var has_health: bool = false
	for property: Dictionary in target.get_property_list():
		if StringName(property.get("name", "")) == &"health":
			has_health = true
			break
	if not has_health:
		return -1

	var value: Variant = target.get("health")
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return maxi(int(value), 0)
	return -1
