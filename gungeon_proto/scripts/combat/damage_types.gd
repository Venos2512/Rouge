class_name DamageTypes
extends RefCounted


const PHYSICAL: StringName = &"physical"
const FIRE: StringName = &"fire"
const SHOCK: StringName = &"shock"
const POISON: StringName = &"poison"
const VOID: StringName = &"void"

const MELEE: StringName = &"melee"
const PROJECTILE: StringName = &"projectile"
const EXPLOSION: StringName = &"explosion"
const CONTACT: StringName = &"contact"
const TRAP: StringName = &"trap"
const THROWN_PROP: StringName = &"thrown_prop"

const ALL_DAMAGE_TYPES: Array[StringName] = [
	PHYSICAL,
	FIRE,
	SHOCK,
	POISON,
	VOID,
]

const ALL_DELIVERY_TAGS: Array[StringName] = [
	MELEE,
	PROJECTILE,
	EXPLOSION,
	CONTACT,
	TRAP,
	THROWN_PROP,
]


static func is_valid_damage_type(value: StringName) -> bool:
	return value in ALL_DAMAGE_TYPES


static func is_valid_delivery_tag(value: StringName) -> bool:
	return value in ALL_DELIVERY_TAGS
