extends RefCounted


const STICK_DEADZONE: float = 0.22
const TRIGGER_DEADZONE: float = 0.20


static func attack_pressed() -> bool:
	# Mouse luôn hoạt động.
	if Input.is_mouse_button_pressed(
		MOUSE_BUTTON_LEFT
	):
		return true

	# InputMap vẫn được hỗ trợ nếu đã setup.
	if (
		InputMap.has_action(
			"attack"
		)
		and Input.is_action_pressed(
			"attack"
		)
	):
		return true

	return _right_trigger_pressed()


static func special_pressed() -> bool:
	if Input.is_mouse_button_pressed(
		MOUSE_BUTTON_RIGHT
	):
		return true

	if (
		InputMap.has_action(
			"special"
		)
		and Input.is_action_pressed(
			"special"
		)
	):
		return true

	return _left_trigger_pressed()


static func interact_pressed() -> bool:
	if Input.is_key_pressed(
		KEY_E
	):
		return true

	if (
		InputMap.has_action(
			"interact"
		)
		and Input.is_action_pressed(
			"interact"
		)
	):
		return true

	return _any_joy_button_pressed(
		JOY_BUTTON_A
	)


static func dodge_pressed() -> bool:
	if Input.is_key_pressed(
		KEY_SPACE
	):
		return true

	if (
		InputMap.has_action(
			"dodge"
		)
		and Input.is_action_pressed(
			"dodge"
		)
	):
		return true

	return _any_joy_button_pressed(
		JOY_BUTTON_B
	)


static func reload_pressed() -> bool:
	if Input.is_key_pressed(
		KEY_R
	):
		return true

	if (
		InputMap.has_action(
			"reload"
		)
		and Input.is_action_pressed(
			"reload"
		)
	):
		return true

	return _any_joy_button_pressed(
		JOY_BUTTON_X
	)


static func weapon_prev_pressed() -> bool:
	if (
		InputMap.has_action(
			"weapon_prev"
		)
		and Input.is_action_pressed(
			"weapon_prev"
		)
	):
		return true

	return _any_joy_button_pressed(
		JOY_BUTTON_LEFT_SHOULDER
	)


static func weapon_next_pressed() -> bool:
	if (
		InputMap.has_action(
			"weapon_next"
		)
		and Input.is_action_pressed(
			"weapon_next"
		)
	):
		return true

	return _any_joy_button_pressed(
		JOY_BUTTON_RIGHT_SHOULDER
	)


static func get_move_vector() -> Vector2:
	# Keyboard.
	var keyboard_vector: Vector2 = Vector2.ZERO

	if Input.is_key_pressed(
		KEY_A
	):
		keyboard_vector.x -= 1.0

	if Input.is_key_pressed(
		KEY_D
	):
		keyboard_vector.x += 1.0

	if Input.is_key_pressed(
		KEY_W
	):
		keyboard_vector.y -= 1.0

	if Input.is_key_pressed(
		KEY_S
	):
		keyboard_vector.y += 1.0

	if keyboard_vector.length_squared() > 0.001:
		return keyboard_vector.normalized()

	# Controller.
	var joypads: Array[int] = (
		Input.get_connected_joypads()
	)

	for device_id: int in joypads:
		var stick: Vector2 = Vector2(
			Input.get_joy_axis(
				device_id,
				JOY_AXIS_LEFT_X
			),
			Input.get_joy_axis(
				device_id,
				JOY_AXIS_LEFT_Y
			)
		)

		if stick.length() >= STICK_DEADZONE:
			var stick_length: float = minf(stick.length(), 1.0)
			var remapped_strength: float = inverse_lerp(
				STICK_DEADZONE,
				1.0,
				stick_length
			)
			return stick.normalized() * remapped_strength

	return Vector2.ZERO


static func get_aim_vector() -> Vector2:
	var joypads: Array[int] = (
		Input.get_connected_joypads()
	)

	for device_id: int in joypads:
		var stick: Vector2 = Vector2(
			Input.get_joy_axis(
				device_id,
				JOY_AXIS_RIGHT_X
			),
			Input.get_joy_axis(
				device_id,
				JOY_AXIS_RIGHT_Y
			)
		)

		if stick.length() >= STICK_DEADZONE:
			return stick.normalized()

	return Vector2.ZERO


static func has_gamepad_aim() -> bool:
	return (
		get_aim_vector().length_squared()
		> 0.001
	)


static func using_gamepad() -> bool:
	return not Input.get_connected_joypads().is_empty()


static func _right_trigger_pressed() -> bool:
	return _any_trigger_pressed(
		JOY_AXIS_TRIGGER_RIGHT
	)


static func _left_trigger_pressed() -> bool:
	return _any_trigger_pressed(
		JOY_AXIS_TRIGGER_LEFT
	)


static func _any_trigger_pressed(
	axis: JoyAxis
) -> bool:
	var joypads: Array[int] = (
		Input.get_connected_joypads()
	)

	for device_id: int in joypads:
		var value: float = Input.get_joy_axis(
			device_id,
			axis
		)

		# Godot/controller driver có thể báo trigger:
		# -1 → 1 hoặc 0 → 1.
		# Ngưỡng này hỗ trợ cả hai kiểu phổ biến.
		if value > TRIGGER_DEADZONE:
			return true

	return false


static func _any_joy_button_pressed(
	button: JoyButton
) -> bool:
	var joypads: Array[int] = (
		Input.get_connected_joypads()
	)

	for device_id: int in joypads:
		if Input.is_joy_button_pressed(
			device_id,
			button
		):
			return true

	return false
