extends Node2D


const ROOM_RECT := Rect2(
	-384.0,
	-216.0,
	768.0,
	432.0
)

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


var dungeon: Node = null
var last_signature: int = -1


func _ready() -> void:
	z_index = -100

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

	queue_redraw()


func refresh(
	dungeon_node: Node = null
) -> void:
	if is_instance_valid(
		dungeon_node
	):
		dungeon = dungeon_node

	last_signature = -1

	queue_redraw()


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

	queue_redraw()


func _build_signature() -> int:
	var rooms: Dictionary = (
		_get_rooms()
	)

	var current_room: Vector2i = (
		_get_current_room()
	)

	var room_cleared: bool = (
		_get_room_cleared()
	)

	var room_type: String = ""

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

	var signature_text: String = (
		str(current_room)
		+ "|"
		+ room_type
		+ "|"
		+ str(room_cleared)
		+ "|"
		+ str(neighbor_mask)
	)

	return hash(
		signature_text
	)


func _get_rooms() -> Dictionary:
	if not is_instance_valid(
		dungeon
	):
		return {}

	var value: Variant = dungeon.get(
		"rooms"
	)

	if typeof(value) != TYPE_DICTIONARY:
		return {}

	return value


func _get_current_room() -> Vector2i:
	if not is_instance_valid(
		dungeon
	):
		return Vector2i.ZERO

	var value: Variant = dungeon.get(
		"current_room"
	)

	if typeof(value) != TYPE_VECTOR2I:
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

	var current_room: Vector2i = (
		_get_current_room()
	)

	return rooms.has(
		current_room
		+ direction
	)


func _draw() -> void:
	var rooms: Dictionary = (
		_get_rooms()
	)

	var current_room: Vector2i = (
		_get_current_room()
	)

	var room_cleared: bool = (
		_get_room_cleared()
	)

	draw_rect(
		Rect2(
			-2000.0,
			-2000.0,
			4000.0,
			4000.0
		),
		Color8(
			12,
			12,
			18
		),
		true
	)

	var floor_color: Color = Color8(
		39,
		42,
		52
	)

	if rooms.has(
		current_room
	):
		var data: Dictionary = rooms[
			current_room
		]

		match str(
			data.get(
				"type",
				"combat"
			)
		):
			"treasure":
				floor_color = Color8(
					49,
					45,
					39
				)

			"elite":
				floor_color = Color8(
					50,
					38,
					35
				)

			"boss":
				floor_color = Color8(
					45,
					30,
					37
				)

			"shop":
				floor_color = Color8(
					31,
					48,
					46
				)

	draw_rect(
		ROOM_RECT,
		floor_color,
		true
	)

	var grid_size: int = 32

	for x: int in range(
		int(
			ROOM_RECT.position.x
		),
		int(
			ROOM_RECT.end.x
		) + 1,
		grid_size
	):
		draw_line(
			Vector2(
				float(x),
				ROOM_RECT.position.y
			),
			Vector2(
				float(x),
				ROOM_RECT.end.y
			),
			Color8(
				48,
				51,
				63
			),
			1.0
		)

	for y: int in range(
		int(
			ROOM_RECT.position.y
		),
		int(
			ROOM_RECT.end.y
		) + 1,
		grid_size
	):
		draw_line(
			Vector2(
				ROOM_RECT.position.x,
				float(y)
			),
			Vector2(
				ROOM_RECT.end.x,
				float(y)
			),
			Color8(
				48,
				51,
				63
			),
			1.0
		)

	draw_rect(
		ROOM_RECT,
		Color8(
			102,
			91,
			84
		),
		false,
		12.0
	)

	draw_rect(
		ROOM_RECT.grow(
			-12.0
		),
		Color8(
			58,
			54,
			58
		),
		false,
		4.0
	)

	if _has_neighbor(
		DIR_UP
	):
		_draw_door(
			DIR_UP,
			room_cleared
		)

	if _has_neighbor(
		DIR_DOWN
	):
		_draw_door(
			DIR_DOWN,
			room_cleared
		)

	if _has_neighbor(
		DIR_LEFT
	):
		_draw_door(
			DIR_LEFT,
			room_cleared
		)

	if _has_neighbor(
		DIR_RIGHT
	):
		_draw_door(
			DIR_RIGHT,
			room_cleared
		)


func _draw_door(
	direction: Vector2i,
	is_open: bool
) -> void:
	var locked_color: Color = Color8(
		112,
		54,
		45
	)

	var open_color: Color = Color8(
		225,
		184,
		78
	)

	var floor_color: Color = Color8(
		39,
		42,
		52
	)

	if direction == DIR_UP:
		if is_open:
			draw_rect(
				Rect2(
					-31.0,
					ROOM_RECT.position.y - 9.0,
					62.0,
					22.0
				),
				floor_color,
				true
			)

			draw_rect(
				Rect2(
					-24.0,
					ROOM_RECT.position.y + 3.0,
					48.0,
					4.0
				),
				open_color,
				true
			)
		else:
			draw_rect(
				Rect2(
					-30.0,
					ROOM_RECT.position.y - 7.0,
					60.0,
					17.0
				),
				locked_color,
				true
			)

	elif direction == DIR_DOWN:
		if is_open:
			draw_rect(
				Rect2(
					-31.0,
					ROOM_RECT.end.y - 13.0,
					62.0,
					22.0
				),
				floor_color,
				true
			)

			draw_rect(
				Rect2(
					-24.0,
					ROOM_RECT.end.y - 7.0,
					48.0,
					4.0
				),
				open_color,
				true
			)
		else:
			draw_rect(
				Rect2(
					-30.0,
					ROOM_RECT.end.y - 10.0,
					60.0,
					17.0
				),
				locked_color,
				true
			)

	elif direction == DIR_LEFT:
		if is_open:
			draw_rect(
				Rect2(
					ROOM_RECT.position.x - 9.0,
					-31.0,
					22.0,
					62.0
				),
				floor_color,
				true
			)

			draw_rect(
				Rect2(
					ROOM_RECT.position.x + 3.0,
					-24.0,
					4.0,
					48.0
				),
				open_color,
				true
			)
		else:
			draw_rect(
				Rect2(
					ROOM_RECT.position.x - 7.0,
					-30.0,
					17.0,
					60.0
				),
				locked_color,
				true
			)

	elif direction == DIR_RIGHT:
		if is_open:
			draw_rect(
				Rect2(
					ROOM_RECT.end.x - 13.0,
					-31.0,
					22.0,
					62.0
				),
				floor_color,
				true
			)

			draw_rect(
				Rect2(
					ROOM_RECT.end.x - 7.0,
					-24.0,
					4.0,
					48.0
				),
				open_color,
				true
			)
		else:
			draw_rect(
				Rect2(
					ROOM_RECT.end.x - 10.0,
					-30.0,
					17.0,
					60.0
				),
				locked_color,
				true
			)