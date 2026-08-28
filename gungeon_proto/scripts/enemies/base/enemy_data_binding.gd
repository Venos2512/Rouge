extends Node


func _ready() -> void:
	var enemy: Node = get_parent()

	if not is_instance_valid(
		enemy
	):
		return

	if not enemy.has_meta(
		"enemy_data"
	):
		return

	var value: Variant = enemy.get_meta(
		"enemy_data"
	)

	if value == null:
		return

	if typeof(value) != TYPE_OBJECT:
		return

	var enemy_data: Resource = (
		value as Resource
	)

	if not is_instance_valid(
		enemy_data
	):
		return

	if enemy_data.has_method(
		"apply_to"
	):
		enemy_data.call(
			"apply_to",
			enemy
		)
