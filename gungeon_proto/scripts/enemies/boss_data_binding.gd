extends Node


func _ready() -> void:
	var boss: Node = get_parent()

	if not is_instance_valid(
		boss
	):
		return

	if not boss.has_meta(
		"boss_data"
	):
		return

	var value: Variant = boss.get_meta(
		"boss_data"
	)

	if value == null:
		return

	if typeof(value) != TYPE_OBJECT:
		return

	var boss_data: Resource = (
		value as Resource
	)

	if not is_instance_valid(
		boss_data
	):
		return

	var floor_number: int = int(
		boss.get_meta(
			"boss_floor",
			1
		)
	)

	if boss_data.has_method(
		"apply_to"
	):
		boss_data.call(
			"apply_to",
			boss,
			floor_number
		)