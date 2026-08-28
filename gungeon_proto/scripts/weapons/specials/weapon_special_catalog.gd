class_name WeaponSpecialCatalog
extends Resource


@export var providers: Array[Resource] = []


func validate() -> Array[String]:
	var errors: Array[String] = []
	var registered_ids: Dictionary = {}

	for provider_data: Resource in providers:
		if provider_data == null:
			errors.append(
				"Catalog chứa provider null."
			)
			continue

		if not bool(
			provider_data.call(
				"is_valid_provider"
			)
		):
			errors.append(
				"Provider data thiếu weapon_ids hoặc script."
			)
			continue

		var weapon_ids: Array = provider_data.get(
			"weapon_ids"
		)

		for weapon_id_value: Variant in weapon_ids:
			var weapon_id: String = str(
				weapon_id_value
			)

			if registered_ids.has(
				weapon_id
			):
				errors.append(
					"Special provider bị trùng weapon_id: "
					+ weapon_id
				)

			registered_ids[weapon_id] = true

	return errors
