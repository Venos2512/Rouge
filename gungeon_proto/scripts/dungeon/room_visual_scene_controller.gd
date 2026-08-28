extends Node2D


const DIR_UP := Vector2i(
	0,
	-1
)

const DIR_DOWN := Vector2i(
	0,
	1
)

const DIR_LEFT := Vector2i(
	-1,
	0
)

const DIR_RIGHT := Vector2i(
	1,
	0
)


@export_group("Theme")
@export var theme_data: Resource


@onready var world_background: Polygon2D = (
	$WorldBackground
)

@onready var room_floor: Polygon2D = (
	$RoomFloor
)

@onready var grid: Node2D = (
	$Grid
)

@onready var outer_border: Line2D = (
	$OuterBorder
)

@onready var inner_border: Line2D = (
	$InnerBorder
)

@onready var door_up: Node2D = (
	$DoorUp
)

@onready var door_down: Node2D = (
	$DoorDown
)

@onready var door_left: Node2D = (
	$DoorLeft
)

@onready var door_right: Node2D = (
	$DoorRight
)


var dungeon: Node = null
var last_signature: int = -1
var terrain_details: Node2D


func _ready() -> void:
	terrain_details = Node2D.new()
	terrain_details.name = "TerrainDetails"
	terrain_details.z_index = 1
	add_child(terrain_details)

	_apply_static_theme()

	call_deferred(
		"_bind_dungeon"
	)


func _process(
	_delta: float
) -> void:
	if not is_instance_valid(
		dungeon
	):
		_bind_dungeon()

	if not is_instance_valid(
		dungeon
	):
		return

	var signature: int = (
		_build_signature()
	)

	if signature == last_signature:
		return

	last_signature = signature

	_update_visual_state()


func refresh(
	dungeon_node: Node = null
) -> void:
	if is_instance_valid(
		dungeon_node
	):
		dungeon = dungeon_node

	last_signature = -1

	_update_visual_state()
	last_signature = _build_signature()


func _bind_dungeon() -> void:
	var tree: SceneTree = get_tree()

	if tree == null:
		return

	var current_scene: Node = (
		tree.current_scene
	)

	if not is_instance_valid(
		current_scene
	):
		return

	dungeon = current_scene
	last_signature = -1

	_update_visual_state()


func _apply_static_theme() -> void:
	if not is_instance_valid(
		theme_data
	):
		return

	world_background.color = (
		_get_theme_color(
			"world_background",
			world_background.color
		)
	)
	world_background.texture = theme_data.get(
		"world_background_texture"
	) as Texture2D
	world_background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	room_floor.texture = theme_data.get(
		"floor_texture"
	) as Texture2D
	room_floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	outer_border.default_color = (
		_get_theme_color(
			"outer_border_color",
			outer_border.default_color
		)
	)

	inner_border.default_color = (
		_get_theme_color(
			"inner_border_color",
			inner_border.default_color
		)
	)

	var grid_color: Color = (
		_get_theme_color(
			"grid_color",
			Color.WHITE
		)
	)

	for child: Node in grid.get_children():
		if child is Line2D:
			var line: Line2D = (
				child as Line2D
			)

			line.default_color = (
				grid_color
			)

	_apply_door_theme(
		door_up
	)

	_apply_door_theme(
		door_down
	)

	_apply_door_theme(
		door_left
	)

	_apply_door_theme(
		door_right
	)


func _apply_door_theme(
	door: Node2D
) -> void:
	var open_cover: Polygon2D = (
		door.get_node(
			"OpenCover"
		) as Polygon2D
	)

	var open_marker: Polygon2D = (
		door.get_node(
			"OpenMarker"
		) as Polygon2D
	)

	var locked: Polygon2D = (
		door.get_node(
			"Locked"
		) as Polygon2D
	)

	open_cover.color = (
		_get_theme_color(
			"floor_default",
			open_cover.color
		)
	)

	open_marker.color = (
		_get_theme_color(
			"door_open_color",
			open_marker.color
		)
	)

	locked.color = (
		_get_theme_color(
			"door_locked_color",
			locked.color
		)
	)


func _update_visual_state() -> void:
	if not is_node_ready():
		return

	var rooms: Dictionary = (
		_get_rooms()
	)

	var current_room: Vector2i = (
		_get_current_room()
	)

	var room_type: String = (
		"combat"
	)
	var terrain_id: String = "stone"
	var terrain_variant: String = "clean"

	if rooms.has(
		current_room
	):
		var data: Dictionary = rooms[
			current_room
		]

		room_type = str(
			data.get(
				"type",
				"combat"
			)
		)
		terrain_id = str(data.get("terrain", "stone"))
		terrain_variant = str(data.get("terrain_variant", "clean"))

	var room_rect: Rect2 = _get_room_rect(current_room)
	_update_room_geometry(room_rect)
	_rebuild_terrain_details(room_rect, terrain_id)

	room_floor.color = (
		_apply_terrain_variant(
			_get_floor_color(room_type, terrain_id),
			terrain_variant
		)
	)
	for door: Node2D in [door_up, door_down, door_left, door_right]:
		var cover: Polygon2D = door.get_node("OpenCover") as Polygon2D
		cover.color = room_floor.color

	var is_open: bool = (
		_get_room_cleared()
	)

	_update_door(
		door_up,
		_has_neighbor(
			DIR_UP
		),
		is_open
	)

	_update_door(
		door_down,
		_has_neighbor(
			DIR_DOWN
		),
		is_open
	)

	_update_door(
		door_left,
		_has_neighbor(
			DIR_LEFT
		),
		is_open
	)

	_update_door(
		door_right,
		_has_neighbor(
			DIR_RIGHT
		),
		is_open
	)


func _get_room_rect(room_position: Vector2i) -> Rect2:
	var rooms: Dictionary = _get_rooms()
	var size: Vector2 = Vector2(768.0, 432.0)
	if rooms.has(room_position):
		var data: Dictionary = rooms[room_position]
		size = data.get("room_size", size) as Vector2
	return Rect2(-size * 0.5, size)


func _rect_points(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])


func _update_room_geometry(room_rect: Rect2) -> void:
	# Phòng lớn có thể vượt xa nền 4000x4000 cũ.
	# Nền được nới theo phòng hiện tại để camera không nhìn ra vùng trống.
	world_background.polygon = _rect_points(room_rect.grow(8192.0))
	room_floor.polygon = _rect_points(room_rect)
	outer_border.points = _rect_points(room_rect)
	inner_border.points = _rect_points(room_rect.grow(-12.0))

	for child: Node in grid.get_children():
		child.queue_free()

	for x: int in range(int(room_rect.position.x), int(room_rect.end.x) + 1, 32):
		_add_grid_line(Vector2(x, room_rect.position.y), Vector2(x, room_rect.end.y))
	for y: int in range(int(room_rect.position.y), int(room_rect.end.y) + 1, 32):
		_add_grid_line(Vector2(room_rect.position.x, y), Vector2(room_rect.end.x, y))

	_update_door_geometry(door_up, DIR_UP, room_rect)
	_update_door_geometry(door_down, DIR_DOWN, room_rect)
	_update_door_geometry(door_left, DIR_LEFT, room_rect)
	_update_door_geometry(door_right, DIR_RIGHT, room_rect)


func _add_grid_line(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.width = 1.0
	line.default_color = _get_theme_color("grid_color", Color8(48, 51, 63))
	line.points = PackedVector2Array([from, to])
	grid.add_child(line)


func _update_door_geometry(door: Node2D, direction: Vector2i, room_rect: Rect2) -> void:
	var center := Vector2.ZERO
	var door_offset: float = _get_door_offset_for_room(
		_get_current_room(),
		direction,
		room_rect
	)
	if direction == DIR_UP:
		center.x = door_offset
		center.y = room_rect.position.y
	elif direction == DIR_DOWN:
		center.x = door_offset
		center.y = room_rect.end.y
	elif direction == DIR_LEFT:
		center.x = room_rect.position.x
		center.y = door_offset
	else:
		center.x = room_rect.end.x
		center.y = door_offset

	var horizontal: bool = direction == DIR_UP or direction == DIR_DOWN
	var cover_rect := Rect2(center - Vector2(31.0, 11.0), Vector2(62.0, 22.0))
	var marker_rect := Rect2(center - Vector2(24.0, 2.0), Vector2(48.0, 4.0))
	var locked_rect := Rect2(center - Vector2(30.0, 8.5), Vector2(60.0, 17.0))
	if not horizontal:
		cover_rect = Rect2(center - Vector2(11.0, 31.0), Vector2(22.0, 62.0))
		marker_rect = Rect2(center - Vector2(2.0, 24.0), Vector2(4.0, 48.0))
		locked_rect = Rect2(center - Vector2(8.5, 30.0), Vector2(17.0, 60.0))

	(door.get_node("OpenCover") as Polygon2D).polygon = _rect_points(cover_rect)
	(door.get_node("OpenMarker") as Polygon2D).polygon = _rect_points(marker_rect)
	(door.get_node("Locked") as Polygon2D).polygon = _rect_points(locked_rect)


func _get_door_offset_for_room(
	room_position: Vector2i,
	direction: Vector2i,
	room_rect: Rect2
) -> float:
	var rooms: Dictionary = _get_rooms()
	if not rooms.has(room_position):
		return 0.0

	var data: Dictionary = rooms[room_position]
	var offsets: Dictionary = data.get("door_offsets", {}) as Dictionary
	var key: String = "right"
	if direction == DIR_UP:
		key = "up"
	elif direction == DIR_DOWN:
		key = "down"
	elif direction == DIR_LEFT:
		key = "left"

	var normalized: float = float(offsets.get(key, 0.0))
	var usable_half_extent: float = room_rect.size.y * 0.5 - 96.0
	if direction == DIR_UP or direction == DIR_DOWN:
		usable_half_extent = room_rect.size.x * 0.5 - 96.0

	return normalized * maxf(usable_half_extent, 0.0)


func _rebuild_terrain_details(room_rect: Rect2, terrain_id: String) -> void:
	for child: Node in terrain_details.get_children():
		child.queue_free()

	var data: Dictionary = _get_rooms().get(_get_current_room(), {}) as Dictionary
	var variant_id: String = str(data.get("terrain_variant", "clean"))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(_get_current_room()) + variant_id)
	var detail_color: Color = _get_floor_color("combat", terrain_id).lightened(0.12)
	detail_color.a = 0.32

	for _index: int in range(12):
		var line := Line2D.new()
		line.width = rng.randf_range(2.0, 6.0)
		line.default_color = detail_color
		var start := Vector2(
			rng.randf_range(room_rect.position.x + 40.0, room_rect.end.x - 40.0),
			rng.randf_range(room_rect.position.y + 40.0, room_rect.end.y - 40.0)
		)
		var length := rng.randf_range(18.0, 58.0)
		var angle := rng.randf_range(0.0, TAU)
		line.points = PackedVector2Array([start, start + Vector2.from_angle(angle) * length])
		terrain_details.add_child(line)


func _update_door(
	door: Node2D,
	has_neighbor: bool,
	is_open: bool
) -> void:
	door.visible = has_neighbor

	if not has_neighbor:
		return

	var open_cover: CanvasItem = (
		door.get_node(
			"OpenCover"
		) as CanvasItem
	)

	var open_marker: CanvasItem = (
		door.get_node(
			"OpenMarker"
		) as CanvasItem
	)

	var locked: CanvasItem = (
		door.get_node(
			"Locked"
		) as CanvasItem
	)

	open_cover.visible = is_open
	open_marker.visible = is_open
	locked.visible = not is_open


func _get_floor_color(
	room_type: String,
	terrain_id: String = "stone"
) -> Color:
	match room_type:
		"treasure":
			return _get_theme_color(
				"floor_treasure",
				Color8(
					49,
					45,
					39
				)
			)

		"elite":
			return _get_theme_color(
				"floor_elite",
				Color8(
					50,
					38,
					35
				)
			)

		"boss":
			return _get_theme_color(
				"floor_boss",
				Color8(
					45,
					30,
					37
				)
			)

		"shop":
			return _get_theme_color(
				"floor_shop",
				Color8(
					31,
					48,
					46
				)
			)

	match terrain_id:
		"moss":
			return _get_theme_color("floor_moss", Color8(39, 57, 43))
		"ice":
			return _get_theme_color("floor_ice", Color8(39, 55, 68))
		"lava":
			return _get_theme_color("floor_lava", Color8(68, 39, 32))
		"void":
			return _get_theme_color("floor_void", Color8(42, 34, 62))

	return _get_theme_color("floor_default", Color8(39, 42, 52))


func _apply_terrain_variant(base_color: Color, variant_id: String) -> Color:
	match variant_id:
		"shallow_water", "frost", "star_dust":
			return base_color.lightened(0.10)
		"roots", "ash", "scorched_stone", "lost_tiles":
			return base_color.darkened(0.10)
		"molten_cracks", "cosmic_rift":
			return base_color.lerp(Color(0.42, 0.16, 0.12), 0.16)
		"snow_drift", "frozen_stone":
			return base_color.lerp(Color(0.62, 0.76, 0.86), 0.10)

	return base_color


func _get_theme_color(
	property_name: String,
	fallback: Color
) -> Color:
	if not is_instance_valid(
		theme_data
	):
		return fallback

	var value: Variant = (
		theme_data.get(
			property_name
		)
	)

	if typeof(value) != TYPE_COLOR:
		return fallback

	return value


func _get_rooms() -> Dictionary:
	if not is_instance_valid(
		dungeon
	):
		return {}

	var value: Variant = (
		dungeon.get(
			"rooms"
		)
	)

	if typeof(
		value
	) != TYPE_DICTIONARY:
		return {}

	return value


func _get_current_room() -> Vector2i:
	if not is_instance_valid(
		dungeon
	):
		return Vector2i.ZERO

	var value: Variant = (
		dungeon.get(
			"current_room"
		)
	)

	if typeof(
		value
	) != TYPE_VECTOR2I:
		return Vector2i.ZERO

	return value


func _get_room_cleared() -> bool:
	if not is_instance_valid(
		dungeon
	):
		return true

	return bool(
		dungeon.get(
			"room_cleared"
		)
	)


func _has_neighbor(
	direction: Vector2i
) -> bool:
	var rooms: Dictionary = (
		_get_rooms()
	)

	return rooms.has(
		_get_current_room()
		+ direction
	)


func _build_signature() -> int:
	var rooms: Dictionary = (
		_get_rooms()
	)

	var current_room: Vector2i = (
		_get_current_room()
	)

	var room_type: String = ""
	var terrain_id: String = ""
	var terrain_variant: String = ""
	var room_size: Vector2 = Vector2.ZERO
	var door_offsets: Dictionary = {}

	if rooms.has(
		current_room
	):
		var data: Dictionary = rooms[
			current_room
		]

		room_type = str(
			data.get(
				"type",
				"combat"
			)
		)
		terrain_id = str(data.get("terrain", "stone"))
		terrain_variant = str(data.get("terrain_variant", "clean"))
		room_size = data.get("room_size", Vector2(768.0, 432.0)) as Vector2
		door_offsets = data.get("door_offsets", {}) as Dictionary

	var neighbor_mask: int = 0

	if _has_neighbor(
		DIR_UP
	):
		neighbor_mask |= 1

	if _has_neighbor(
		DIR_DOWN
	):
		neighbor_mask |= 2

	if _has_neighbor(
		DIR_LEFT
	):
		neighbor_mask |= 4

	if _has_neighbor(
		DIR_RIGHT
	):
		neighbor_mask |= 8

	return hash(
		str(current_room)
		+ "|"
		+ room_type
		+ "|"
		+ terrain_id
		+ "|"
		+ terrain_variant
		+ "|"
		+ str(room_size)
		+ "|"
		+ str(door_offsets)
		+ "|"
		+ str(
			_get_room_cleared()
		)
		+ "|"
		+ str(
			neighbor_mask
		)
	)
