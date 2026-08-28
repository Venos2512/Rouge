class_name BossData
extends Resource


@export_group("Identity")
@export var id: String = "default_boss"
@export var display_name: String = "Boss"

@export_group("Encounter")
@export var spawn_radius: float = 32.0
@export var minimum_player_distance: float = 125.0

@export_group("Runtime Overrides")
@export var property_overrides: Dictionary = {}


func apply_to(
	target: Node,
	floor_number: int
) -> void:
	if not is_instance_valid(
		target
	):
		return

	_set_if_property_exists(
		target,
		"boss_floor",
		floor_number
	)

	for key_value: Variant in property_overrides.keys():
		var property_name: String = str(
			key_value
		)

		_set_if_property_exists(
			target,
			property_name,
			property_overrides[key_value]
		)


func _set_if_property_exists(
	target: Object,
	property_name: String,
	value: Variant
) -> void:
	for property_info: Dictionary in target.get_property_list():
		if str(
			property_info.get(
				"name",
				""
			)
		) != property_name:
			continue

		target.set(
			property_name,
			value
		)

		return