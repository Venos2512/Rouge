extends Camera2D


@export var pan_speed: float = 620.0

@export var zoom_step: float = 0.12

@export var min_zoom: float = 0.45
@export var max_zoom: float = 2.0

var default_position: Vector2
var default_zoom: Vector2

var dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0

	default_position = global_position
	default_zoom = zoom


func _process(
	delta: float
) -> void:
	_handle_keyboard_pan(
		delta
	)

	_handle_mouse_camera()


func _handle_keyboard_pan(
	delta: float
) -> void:
	# Camera debug chỉ dùng phím mũi tên,
	# không tranh WASD với player.
	var input_direction: Vector2 = Vector2.ZERO

	if Input.is_key_pressed(
		KEY_LEFT
	):
		input_direction.x -= 1.0

	if Input.is_key_pressed(
		KEY_RIGHT
	):
		input_direction.x += 1.0

	if Input.is_key_pressed(
		KEY_UP
	):
		input_direction.y -= 1.0

	if Input.is_key_pressed(
		KEY_DOWN
	):
		input_direction.y += 1.0

	if input_direction.length_squared() > 0.001:
		global_position += (
			input_direction.normalized()
			* pan_speed
			* delta
			/ maxf(
				zoom.x,
				0.01
			)
		)

	if Input.is_key_pressed(
		KEY_HOME
	):
		global_position = (
			default_position
		)

		zoom = (
			default_zoom
		)


func _handle_mouse_camera() -> void:
	var mouse_position: Vector2 = (
		get_viewport().get_mouse_position()
	)

	var middle_down: bool = (
		Input.is_mouse_button_pressed(
			MOUSE_BUTTON_MIDDLE
		)
	)

	if (
		middle_down
		and not dragging
	):
		dragging = true
		last_mouse_position = (
			mouse_position
		)

	elif (
		not middle_down
		and dragging
	):
		dragging = false

	if dragging:
		var mouse_delta: Vector2 = (
			mouse_position
			- last_mouse_position
		)

		global_position -= (
			mouse_delta
			/ maxf(
				zoom.x,
				0.01
			)
		)

		last_mouse_position = (
			mouse_position
		)


func _unhandled_input(
	event: InputEvent
) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = (
			event as InputEventMouseButton
		)

		if not mouse_event.pressed:
			return

		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_change_zoom(
				zoom_step
			)

		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_change_zoom(
				-zoom_step
			)


func _change_zoom(
	amount: float
) -> void:
	var next_zoom: float = clampf(
		zoom.x + amount,
		min_zoom,
		max_zoom
	)

	zoom = Vector2(
		next_zoom,
		next_zoom
	)