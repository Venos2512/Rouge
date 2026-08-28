class_name EnemyData
extends Resource


@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var enemy_type: String = ""
@export var scene: PackedScene
@export var icon_texture: Texture2D

@export_group("Encounter")
@export_range(0.0, 100.0, 0.1)
var spawn_weight: float = 1.0

@export var spawn_radius: float = 13.0
@export var minimum_player_distance: float = 72.0

@export_group("Runtime Overrides")
@export var property_overrides: Dictionary = {}


func apply_to(
	target: Node
) -> void:
	if not is_instance_valid(
		target
	):
		return

	_set_if_property_exists(
		target,
		"enemy_type",
		enemy_type
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
