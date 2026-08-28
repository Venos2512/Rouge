class_name DamageInfo
extends RefCounted


const DamageTypesScript = preload(
	"res://gungeon_proto/scripts/combat/damage_types.gd"
)

var amount: int = 1
var damage_type: StringName = DamageTypesScript.PHYSICAL
var delivery_tags: Array[StringName] = []

var source: Node = null
var instigator: Node = null
var hit_position: Vector2 = Vector2.ZERO
var hit_direction: Vector2 = Vector2.ZERO

var armor_pierce: float = 0.0
var critical: bool = false
var can_trigger_status: bool = true
var friendly_fire: bool = false


static func create(
	new_amount: int,
	new_damage_type: StringName = DamageTypesScript.PHYSICAL,
	new_delivery_tags: Array[StringName] = []
) -> RefCounted:
	var info: RefCounted = new()
	info.amount = maxi(new_amount, 0)
	info.damage_type = (
		new_damage_type
		if DamageTypesScript.is_valid_damage_type(new_damage_type)
		else DamageTypesScript.PHYSICAL
	)
	for tag: StringName in new_delivery_tags:
		if DamageTypesScript.is_valid_delivery_tag(tag):
			info.delivery_tags.append(tag)
	return info


func has_delivery_tag(tag: StringName) -> bool:
	return tag in delivery_tags
