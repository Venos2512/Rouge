class_name WeaponSpecialProviderData
extends Resource


@export var weapon_ids: Array[String] = []
@export var provider_script: Script


func is_valid_provider() -> bool:
	return (
		not weapon_ids.is_empty()
		and provider_script != null
	)
