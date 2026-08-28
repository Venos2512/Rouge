class_name WeaponDatabase
extends Resource


const DamageTypesScript = preload(
	"res://gungeon_proto/scripts/combat/damage_types.gd"
)

@export var weapons: Array[Resource] = []


func get_by_id(
	weapon_id: String
) -> Resource:
	for weapon_data: Resource in weapons:
		if (
			weapon_data != null
			and str(weapon_data.get("id")) == weapon_id
		):
			return weapon_data

	return null


func validate() -> Array[String]:
	var errors: Array[String] = []
	var seen_ids: Dictionary = {}

	for weapon_data: Resource in weapons:
		if weapon_data == null:
			errors.append(
				"WeaponDatabase chứa resource null."
			)
			continue

		var weapon_id: String = str(
			weapon_data.get(
				"id"
			)
		)

		if weapon_id.is_empty():
			errors.append(
				"WeaponData thiếu id."
			)
			continue

		if seen_ids.has(
			weapon_id
		):
			errors.append(
				"Weapon id bị trùng: " + weapon_id
			)

		seen_ids[weapon_id] = true

		if weapon_data.get(
			"attack_provider"
		) == null:
			errors.append(
				"Weapon thiếu attack_provider: " + weapon_id
			)

		var damage_type := StringName(
			weapon_data.get("damage_type")
		)
		if not DamageTypesScript.is_valid_damage_type(damage_type):
			errors.append(
				"Weapon có damage_type không hợp lệ: " + weapon_id
			)

	return errors
