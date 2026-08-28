@tool
extends Node2D

@export var room_size: Vector2 = Vector2(
	1100.0,
	700.0
)


func _ready() -> void:
	z_index = -20
	queue_redraw()


func _process(
	_delta: float
) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	var room_rect: Rect2 = Rect2(
		-room_size * 0.5,
		room_size
	)

	draw_rect(
		room_rect,
		Color(
			0.075,
			0.078,
			0.088,
			1.0
		),
		true
	)

	var grid_size: float = 50.0

	var x_value: float = room_rect.position.x

	while x_value <= room_rect.end.x:
		draw_line(
			Vector2(
				x_value,
				room_rect.position.y
			),
			Vector2(
				x_value,
				room_rect.end.y
			),
			Color(
				0.14,
				0.145,
				0.16,
				0.45
			),
			1.0
		)

		x_value += grid_size

	var y_value: float = room_rect.position.y

	while y_value <= room_rect.end.y:
		draw_line(
			Vector2(
				room_rect.position.x,
				y_value
			),
			Vector2(
				room_rect.end.x,
				y_value
			),
			Color(
				0.14,
				0.145,
				0.16,
				0.45
			),
			1.0
		)

		y_value += grid_size

	draw_rect(
		room_rect,
		Color(
			0.48,
			0.43,
			0.31,
			1.0
		),
		false,
		8.0
	)

	draw_rect(
		room_rect.grow(
			-12.0
		),
		Color(
			0.20,
			0.19,
			0.18,
			1.0
		),
		false,
		3.0
	)