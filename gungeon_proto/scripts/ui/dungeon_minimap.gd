extends Control

var rooms: Dictionary = {}
var current_room: Vector2i = Vector2i.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

	size = Vector2(
		170,
		105
	)

	queue_redraw()


func set_dungeon_state(
	new_rooms: Dictionary,
	new_current_room: Vector2i
) -> void:
	rooms = new_rooms.duplicate(true)
	current_room = new_current_room

	queue_redraw()


func _is_room_visible(
	room_pos: Vector2i
) -> bool:
	if not rooms.has(
		room_pos
	):
		return false

	var data: Dictionary = rooms[
		room_pos
	]

	if bool(
		data.get(
			"visited",
			false
		)
	):
		return true

	var neighbors: Array[Vector2i] = [
		room_pos + Vector2i.UP,
		room_pos + Vector2i.DOWN,
		room_pos + Vector2i.LEFT,
		room_pos + Vector2i.RIGHT
	]

	for neighbor_pos: Vector2i in neighbors:
		if not rooms.has(
			neighbor_pos
		):
			continue

		var neighbor_data: Dictionary = rooms[
			neighbor_pos
		]

		if bool(
			neighbor_data.get(
				"visited",
				false
			)
		):
			return true

	return false


func _draw() -> void:
	draw_rect(
		Rect2(
			Vector2.ZERO,
			size
		),
		Color8(8, 9, 14, 205),
		true
	)

	draw_rect(
		Rect2(
			Vector2.ZERO,
			size
		),
		Color8(110, 105, 115),
		false,
		2.0
	)

	var step := Vector2(20, 17)
	# Luôn giữ phòng hiện tại ở tâm minimap. Toàn bộ sơ đồ dịch
	# ngược với vị trí người chơi thay vì tiếp tục trôi khỏi khung.
	var origin := (
		Vector2(size.x * 0.5, size.y * 0.5)
		- Vector2(current_room.x * step.x, current_room.y * step.y)
	)
	var room_size := Vector2(13, 9)

	for room_key in rooms.keys():
		var room_pos: Vector2i = room_key

		var data: Dictionary = rooms[
			room_pos
		]

		if not _is_room_visible(
			room_pos
		):
			continue

		var center := (
			origin
			+ Vector2(
				room_pos.x * step.x,
				room_pos.y * step.y
			)
		)

		var right_pos := (
			room_pos
			+ Vector2i.RIGHT
		)

		var down_pos := (
			room_pos
			+ Vector2i.DOWN
		)

		if (
			rooms.has(right_pos)
			and _is_room_visible(
				right_pos
			)
		):
			var right_data: Dictionary = rooms[
				right_pos
			]

			var right_line_color := Color8(
				68,
				70,
				80,
				125
			)

			if (
				bool(
					data.get(
						"visited",
						false
					)
				)
				and bool(
					right_data.get(
						"visited",
						false
					)
				)
			):
				right_line_color = Color8(
					110,
					105,
					115
				)

			draw_line(
				center,
				center + Vector2(step.x, 0),
				right_line_color,
				3.0
			)

		if (
			rooms.has(down_pos)
			and _is_room_visible(
				down_pos
			)
		):
			var down_data: Dictionary = rooms[
				down_pos
			]

			var down_line_color := Color8(
				68,
				70,
				80,
				125
			)

			if (
				bool(
					data.get(
						"visited",
						false
					)
				)
				and bool(
					down_data.get(
						"visited",
						false
					)
				)
			):
				down_line_color = Color8(
					110,
					105,
					115
				)

			draw_line(
				center,
				center + Vector2(0, step.y),
				down_line_color,
				3.0
			)

	for room_key in rooms.keys():
		var room_pos: Vector2i = room_key

		var data: Dictionary = rooms[
			room_pos
		]

		if not _is_room_visible(
			room_pos
		):
			continue

		var center := (
			origin
			+ Vector2(
				room_pos.x * step.x,
				room_pos.y * step.y
			)
		)

		var room_color := Color8(
			92,
			92,
			105
		)

		# Phòng chưa bước vào chỉ preview silhouette,
		# không tiết lộ treasure / elite / boss / shop.
		if not bool(
			data.get(
				"visited",
				false
			)
		):
			room_color = Color8(
				58,
				60,
				68,
				150
			)

		draw_rect(
			Rect2(
				center - room_size * 0.5,
				room_size
			),
			Color8(18, 18, 24),
			true
		)

		draw_rect(
			Rect2(
				center
				- room_size * 0.5
				+ Vector2.ONE,
				room_size
				- Vector2(2, 2)
			),
			room_color,
			true
		)

		if bool(data.get("visited", false)):
			_draw_special_icon(center, str(data.get("type", "combat")))

		if room_pos == current_room:
			draw_rect(
				Rect2(center - room_size * 0.5 - Vector2.ONE, room_size + Vector2(2, 2)),
				Color8(95, 190, 230),
				false,
				2.0
			)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(7, 14),
		"MAP",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color8(220, 220, 225)
	)


func _draw_special_icon(center: Vector2, room_type: String) -> void:
	match room_type:
		"treasure":
			draw_colored_polygon(
				PackedVector2Array([
					center + Vector2(0, -3),
					center + Vector2(3, 0),
					center + Vector2(0, 3),
					center + Vector2(-3, 0),
				]),
				Color8(230, 190, 65)
			)
		"elite":
			draw_colored_polygon(
				PackedVector2Array([
					center + Vector2(0, -3),
					center + Vector2(3, 3),
					center + Vector2(-3, 3),
				]),
				Color8(235, 125, 55)
			)
		"boss":
			draw_circle(center, 3.2, Color8(195, 65, 85))
			draw_circle(center + Vector2(-1.2, -0.5), 0.7, Color8(25, 20, 26))
			draw_circle(center + Vector2(1.2, -0.5), 0.7, Color8(25, 20, 26))
		"shop":
			draw_circle(center, 3.0, Color8(75, 200, 175), false, 1.5)
			draw_circle(center, 0.8, Color8(75, 200, 175))
