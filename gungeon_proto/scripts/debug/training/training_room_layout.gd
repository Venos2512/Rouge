@tool
extends Node2D


@export var weapon_columns: int = 6

@export var weapon_spacing: Vector2 = Vector2(
	92.0,
	72.0
)

@export var prop_spacing: float = 86.0

@export_tool_button(
	"Arrange Training Slots"
)
var arrange_button: Callable = (
	_arrange_training_slots
)


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_arrange_training_slots()


func _arrange_training_slots() -> void:
	_arrange_weapon_slots()
	_arrange_prop_slots()


func _arrange_weapon_slots() -> void:
	var rack: Node = get_node_or_null(
		"WeaponRack"
	)

	if not is_instance_valid(
		rack
	):
		return

	var index: int = 0

	for child: Node in rack.get_children():
		if not child is Marker2D:
			continue

		var marker: Marker2D = (
			child as Marker2D
		)

		var column: int = (
			index % maxi(
				1,
				weapon_columns
			)
		)

		var row: int = (
			index / maxi(
				1,
				weapon_columns
			)
		)

		marker.position = Vector2(
			float(column)
				* weapon_spacing.x,
			float(row)
				* weapon_spacing.y
		)

		index += 1


func _arrange_prop_slots() -> void:
	var rack: Node = get_node_or_null(
		"PropZone"
	)

	if not is_instance_valid(
		rack
	):
		return

	var markers: Array[Marker2D] = []

	for child: Node in rack.get_children():
		if child is Marker2D:
			markers.append(
				child as Marker2D
			)

	var total_width: float = (
		float(
			maxi(
				0,
				markers.size() - 1
			)
		)
		* prop_spacing
	)

	for index: int in range(
		markers.size()
	):
		markers[index].position = Vector2(
			-total_width * 0.5
				+ float(index)
				* prop_spacing,
			0.0
		)