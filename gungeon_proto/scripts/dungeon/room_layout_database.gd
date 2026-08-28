class_name RoomLayoutDatabase
extends Resource


@export_group("Special Rooms")
@export var start_layout: Resource
@export var shop_layout: Resource
@export var treasure_layout: Resource
@export var elite_layout: Resource
@export var boss_layout: Resource

@export_group("Combat Rooms")
@export var combat_layouts: Array[Resource] = []


func get_layout(
	room_type: String,
	layout_id: int
) -> Resource:
	match room_type:
		"start":
			return start_layout

		"shop":
			return shop_layout

		"treasure":
			return treasure_layout

		"elite":
			return elite_layout

		"boss":
			return boss_layout

	if combat_layouts.is_empty():
		return null

	var safe_index: int = (
		layout_id
		% combat_layouts.size()
	)

	if safe_index < 0:
		safe_index += combat_layouts.size()

	return combat_layouts[
		safe_index
	]