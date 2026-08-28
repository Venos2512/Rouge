@tool
extends Node2D

@export var title: String = "ZONE"

@export var width: float = 200.0


func _ready() -> void:
	z_index = -5
	queue_redraw()


func _process(
	_delta: float
) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	draw_line(
		Vector2(
			-width * 0.5,
			0.0
		),
		Vector2(
			width * 0.5,
			0.0
		),
		Color(
			0.38,
			0.38,
			0.42,
			0.7
		),
		2.0
	)