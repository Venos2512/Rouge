extends Node


const ACTION_ATTACK: StringName = &"attack"
const ACTION_SPECIAL: StringName = &"special"
const ACTION_INTERACT: StringName = &"interact"
const ACTION_DODGE: StringName = &"dodge"
const ACTION_RELOAD: StringName = &"reload"

const ACTION_WEAPON_PREV: StringName = &"weapon_prev"
const ACTION_WEAPON_NEXT: StringName = &"weapon_next"

const ACTION_MOVE_LEFT: StringName = &"move_left"
const ACTION_MOVE_RIGHT: StringName = &"move_right"
const ACTION_MOVE_UP: StringName = &"move_up"
const ACTION_MOVE_DOWN: StringName = &"move_down"

const ACTION_AIM_LEFT: StringName = &"aim_left"
const ACTION_AIM_RIGHT: StringName = &"aim_right"
const ACTION_AIM_UP: StringName = &"aim_up"
const ACTION_AIM_DOWN: StringName = &"aim_down"

const ACTION_PAUSE: StringName = &"pause_game"


static func ensure_actions() -> void:
	_ensure_action(
		ACTION_ATTACK,
		0.20
	)

	_ensure_action(
		ACTION_SPECIAL,
		0.20
	)

	_ensure_action(
		ACTION_INTERACT,
		0.20
	)

	_ensure_action(
		ACTION_DODGE,
		0.20
	)

	_ensure_action(
		ACTION_RELOAD,
		0.20
	)

	_ensure_action(
		ACTION_WEAPON_PREV,
		0.20
	)

	_ensure_action(
		ACTION_WEAPON_NEXT,
		0.20
	)

	_ensure_action(
		ACTION_MOVE_LEFT,
		0.18
	)

	_ensure_action(
		ACTION_MOVE_RIGHT,
		0.18
	)

	_ensure_action(
		ACTION_MOVE_UP,
		0.18
	)

	_ensure_action(
		ACTION_MOVE_DOWN,
		0.18
	)

	_ensure_action(
		ACTION_AIM_LEFT,
		0.24
	)

	_ensure_action(
		ACTION_AIM_RIGHT,
		0.24
	)

	_ensure_action(
		ACTION_AIM_UP,
		0.24
	)

	_ensure_action(
		ACTION_AIM_DOWN,
		0.24
	)

	_ensure_action(
		ACTION_PAUSE,
		0.20
	)

	_bind_keyboard_mouse()
	_bind_gamepad()


static func is_gamepad_active() -> bool:
	return not Input.get_connected_joypads().is_empty()


static func get_move_vector() -> Vector2:
	return Input.get_vector(
		ACTION_MOVE_LEFT,
		ACTION_MOVE_RIGHT,
		ACTION_MOVE_UP,
		ACTION_MOVE_DOWN
	)


static func get_aim_vector() -> Vector2:
	return Input.get_vector(
		ACTION_AIM_LEFT,
		ACTION_AIM_RIGHT,
		ACTION_AIM_UP,
		ACTION_AIM_DOWN
	)


static func get_interact_prompt() -> String:
	if is_gamepad_active():
		return "[A]"

	return "[E]"


static func get_attack_prompt() -> String:
	if is_gamepad_active():
		return "[RT]"

	return "[LMB]"


static func get_special_prompt() -> String:
	if is_gamepad_active():
		return "[LT]"

	return "[RMB]"


static func _ensure_action(
	action: StringName,
	deadzone: float
) -> void:
	if not InputMap.has_action(
		action
	):
		InputMap.add_action(
			action,
			deadzone
		)

	else:
		InputMap.action_set_deadzone(
			action,
			deadzone
		)


static func _bind_keyboard_mouse() -> void:
	_add_key(
		ACTION_MOVE_LEFT,
		KEY_A
	)

	_add_key(
		ACTION_MOVE_RIGHT,
		KEY_D
	)

	_add_key(
		ACTION_MOVE_UP,
		KEY_W
	)

	_add_key(
		ACTION_MOVE_DOWN,
		KEY_S
	)

	_add_mouse_button(
		ACTION_ATTACK,
		MOUSE_BUTTON_LEFT
	)

	_add_mouse_button(
		ACTION_SPECIAL,
		MOUSE_BUTTON_RIGHT
	)

	_add_key(
		ACTION_INTERACT,
		KEY_E
	)

	_add_key(
		ACTION_DODGE,
		KEY_SPACE
	)

	_add_key(
		ACTION_RELOAD,
		KEY_R
	)

	_add_key(
		ACTION_PAUSE,
		KEY_ESCAPE
	)


static func _bind_gamepad() -> void:
	# Left stick.
	_add_joy_axis(
		ACTION_MOVE_LEFT,
		JOY_AXIS_LEFT_X,
		-1.0
	)

	_add_joy_axis(
		ACTION_MOVE_RIGHT,
		JOY_AXIS_LEFT_X,
		1.0
	)

	_add_joy_axis(
		ACTION_MOVE_UP,
		JOY_AXIS_LEFT_Y,
		-1.0
	)

	_add_joy_axis(
		ACTION_MOVE_DOWN,
		JOY_AXIS_LEFT_Y,
		1.0
	)

	# Right stick.
	_add_joy_axis(
		ACTION_AIM_LEFT,
		JOY_AXIS_RIGHT_X,
		-1.0
	)

	_add_joy_axis(
		ACTION_AIM_RIGHT,
		JOY_AXIS_RIGHT_X,
		1.0
	)

	_add_joy_axis(
		ACTION_AIM_UP,
		JOY_AXIS_RIGHT_Y,
		-1.0
	)

	_add_joy_axis(
		ACTION_AIM_DOWN,
		JOY_AXIS_RIGHT_Y,
		1.0
	)

	# RT / R2.
	_add_joy_axis(
		ACTION_ATTACK,
		JOY_AXIS_TRIGGER_RIGHT,
		1.0
	)

	# LT / L2.
	_add_joy_axis(
		ACTION_SPECIAL,
		JOY_AXIS_TRIGGER_LEFT,
		1.0
	)

	# Xbox A / PlayStation Cross.
	_add_joy_button(
		ACTION_INTERACT,
		JOY_BUTTON_A
	)

	# Xbox B / PlayStation Circle.
	_add_joy_button(
		ACTION_DODGE,
		JOY_BUTTON_B
	)

	# Xbox X / PlayStation Square.
	_add_joy_button(
		ACTION_RELOAD,
		JOY_BUTTON_X
	)

	_add_joy_button(
		ACTION_WEAPON_PREV,
		JOY_BUTTON_LEFT_SHOULDER
	)

	_add_joy_button(
		ACTION_WEAPON_NEXT,
		JOY_BUTTON_RIGHT_SHOULDER
	)

	_add_joy_button(
		ACTION_PAUSE,
		JOY_BUTTON_START
	)


static func _add_key(
	action: StringName,
	keycode: Key
) -> void:
	var event: InputEventKey = (
		InputEventKey.new()
	)

	event.physical_keycode = keycode

	_add_event_if_missing(
		action,
		event
	)


static func _add_mouse_button(
	action: StringName,
	button: MouseButton
) -> void:
	var event: InputEventMouseButton = (
		InputEventMouseButton.new()
	)

	event.button_index = button

	_add_event_if_missing(
		action,
		event
	)


static func _add_joy_button(
	action: StringName,
	button: JoyButton
) -> void:
	var event: InputEventJoypadButton = (
		InputEventJoypadButton.new()
	)

	event.button_index = button

	_add_event_if_missing(
		action,
		event
	)


static func _add_joy_axis(
	action: StringName,
	axis: JoyAxis,
	axis_value: float
) -> void:
	var event: InputEventJoypadMotion = (
		InputEventJoypadMotion.new()
	)

	event.axis = axis
	event.axis_value = axis_value

	_add_event_if_missing(
		action,
		event
	)


static func _add_event_if_missing(
	action: StringName,
	event: InputEvent
) -> void:
	for existing: InputEvent in InputMap.action_get_events(
		action
	):
		if existing.as_text() == event.as_text():
			return

	InputMap.action_add_event(
		action,
		event
	)