class_name DamageResult
extends RefCounted


const DamageTypesScript = preload(
	"res://gungeon_proto/scripts/combat/damage_types.gd"
)

var requested_amount: int = 0
var final_amount: int = 0
var damage_type: StringName = DamageTypesScript.PHYSICAL
var blocked: bool = false
var critical: bool = false
var killed: bool = false
var used_legacy_receiver: bool = false
