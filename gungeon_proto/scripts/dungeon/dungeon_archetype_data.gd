class_name DungeonArchetypeData
extends Resource


enum GrowthStyle {
	BALANCED,
	HORIZONTAL,
	VERTICAL,
	BRANCHING,
}


@export_group("Identity")
@export var id: String = "stone_keep"
@export var terrain_id: String = "stone"

@export_group("Size")
@export_range(6, 40, 1) var minimum_rooms: int = 8
@export_range(6, 40, 1) var maximum_rooms: int = 11
@export_range(1, 12, 1) var half_width: int = 4
@export_range(1, 12, 1) var half_height: int = 4

@export_group("Shape")
@export var growth_style: GrowthStyle = GrowthStyle.BALANCED
@export_range(0.0, 1.0, 0.05) var branch_from_latest_chance: float = 0.35

@export_group("Room Layouts")
@export var combat_layout_ids: Array[int] = [0, 1, 2, 3, 4, 5]


func get_room_count() -> int:
	return randi_range(
		mini(minimum_rooms, maximum_rooms),
		maxi(minimum_rooms, maximum_rooms)
	)


func contains(position: Vector2i) -> bool:
	return (
		absi(position.x) <= half_width
		and absi(position.y) <= half_height
	)


func pick_layout_id() -> int:
	if combat_layout_ids.is_empty():
		return 0

	return combat_layout_ids.pick_random()
