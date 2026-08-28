extends Node


const INTERACT_RANGE_FALLBACK: float = 52.0

const CONTROLLER_PROMPT_TIME: float = 3.0


var player: Node2D = null

var prompt_root: Node2D = null
var prompt_label: Label = null

var last_input_device: String = "keyboard"

var controller_prompt_timer: float = 0.0

var a_was_down: bool = false
var b_was_down: bool = false
var x_was_down: bool = false

var lb_was_down: bool = false
var rb_was_down: bool = false

var rt_was_down: bool = false


func _ready() -> void:
	process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	# Chạy sau phần lớn gameplay node để prompt trung tâm
	# không bị prompt cũ ghi đè.
	process_priority = 100

	call_deferred(
		"_create_world_prompt"
	)

	call_deferred(
		"_find_player"
	)


func _input(
	event: InputEvent
) -> void:
	if event is InputEventJoypadButton:
		var joy_button: InputEventJoypadButton = (
			event as InputEventJoypadButton
		)

		if joy_button.pressed:
			_mark_controller_active()

	elif event is InputEventJoypadMotion:
		var joy_motion: InputEventJoypadMotion = (
			event as InputEventJoypadMotion
		)

		if absf(
			joy_motion.axis_value
		) > 0.24:
			_mark_controller_active()

	elif event is InputEventMouse:
		_mark_keyboard_mouse_active()

	elif event is InputEventKey:
		var key_event: InputEventKey = (
			event as InputEventKey
		)

		if key_event.pressed:
			_mark_keyboard_mouse_active()


func _process(
	delta: float
) -> void:
	if not is_instance_valid(
		player
	):
		_find_player()

	if not is_instance_valid(
		player
	):
		_hide_prompt()
		return

	controller_prompt_timer = maxf(
		0.0,
		controller_prompt_timer - delta
	)

	var a_down: bool = (
		_any_joy_button_pressed(
			JOY_BUTTON_A
		)
	)

	var b_down: bool = (
		_any_joy_button_pressed(
			JOY_BUTTON_B
		)
	)

	var x_down: bool = (
		_any_joy_button_pressed(
			JOY_BUTTON_X
		)
	)

	var lb_down: bool = (
		_any_joy_button_pressed(
			JOY_BUTTON_LEFT_SHOULDER
		)
	)

	var rb_down: bool = (
		_any_joy_button_pressed(
			JOY_BUTTON_RIGHT_SHOULDER
		)
	)

	var rt_down: bool = (
		_any_trigger_pressed(
			JOY_AXIS_TRIGGER_RIGHT
		)
	)

	if (
		a_down
		and not a_was_down
	):
		_controller_interact()

	if (
		b_down
		and not b_was_down
	):
		_controller_dodge()

	if (
		x_down
		and not x_was_down
	):
		_controller_reload()

	if (
		lb_down
		and not lb_was_down
	):
		_controller_weapon_previous()

	if (
		rb_down
		and not rb_was_down
	):
		_controller_weapon_next()

	# Nếu đang cầm object, RT ưu tiên THROW.
	# Player.gd đã có suppress_fire_until_release nên
	# sau khi throw sẽ không bắn thêm một viên ngoài ý muốn.
	if (
		rt_down
		and not rt_was_down
	):
		_controller_throw_carried_object()

	a_was_down = a_down
	b_was_down = b_down
	x_was_down = x_down

	lb_was_down = lb_down
	rb_was_down = rb_down

	rt_was_down = rt_down

	_update_interaction_prompt()


func _mark_controller_active() -> void:
	last_input_device = "controller"

	controller_prompt_timer = (
		CONTROLLER_PROMPT_TIME
	)


func _mark_keyboard_mouse_active() -> void:
	last_input_device = "keyboard"

	controller_prompt_timer = 0.0


func _using_controller_prompt() -> bool:
	return (
		last_input_device == "controller"
		and controller_prompt_timer > 0.0
	)


func _find_player() -> void:
	var value: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)

	if not is_instance_valid(
		value
	):
		player = null
		return

	player = (
		value as Node2D
	)


# ============================================================
# INTERACT
# ============================================================

func _controller_interact() -> void:
	_mark_controller_active()

	var carried_object: Node = (
		_get_carried_object()
	)

	if is_instance_valid(
		carried_object
	):
		if carried_object.has_method(
			"_place_barrel"
		):
			carried_object.call(
				"_place_barrel"
			)

			return

		if carried_object.has_method(
			"_place_prop"
		):
			carried_object.call(
				"_place_prop"
			)

			return

		if carried_object.has_method(
			"_place_object"
		):
			carried_object.call(
				"_place_object"
			)

			return

	var candidate: Node2D = (
		_find_nearest_interactable()
	)

	if not is_instance_valid(
		candidate
	):
		return

	if candidate.has_method(
		"_pick_up"
	):
		candidate.call(
			"_pick_up"
		)

		return

	if candidate.has_method(
		"interact"
	):
		candidate.call(
			"interact",
			player
		)


func _controller_throw_carried_object() -> void:
	var carried_object: Node = (
		_get_carried_object()
	)

	if not is_instance_valid(
		carried_object
	):
		return

	_mark_controller_active()

	if carried_object.has_method(
		"_throw_barrel"
	):
		carried_object.call(
			"_throw_barrel"
		)

		return

	if carried_object.has_method(
		"_throw_prop"
	):
		carried_object.call(
			"_throw_prop"
		)

		return

	if carried_object.has_method(
		"_throw_object"
	):
		carried_object.call(
			"_throw_object"
		)


func _get_carried_object() -> Node:
	if not is_instance_valid(
		player
	):
		return null

	if not player.has_meta(
		"carried_object"
	):
		return null

	var value: Variant = player.get_meta(
		"carried_object"
	)

	if value == null:
		return null

	if typeof(
		value
	) != TYPE_OBJECT:
		return null

	if not is_instance_valid(
		value
	):
		return null

	return value as Node


func _find_nearest_interactable() -> Node2D:
	if not is_instance_valid(
		player
	):
		return null

	var best_object: Node2D = null
	var best_distance_sq: float = INF

	var groups: Array[String] = [
		"carryable_objects",
		"weapon_pickups",
		"interactables"
	]

	var checked_ids: Dictionary = {}

	for group_name: String in groups:
		for value: Node in get_tree().get_nodes_in_group(
			group_name
		):
			if not is_instance_valid(
				value
			):
				continue

			if value.is_queued_for_deletion():
				continue

			var object_node: Node2D = (
				value as Node2D
			)

			if not is_instance_valid(
				object_node
			):
				continue

			var object_id: int = (
				object_node.get_instance_id()
			)

			if checked_ids.has(
				object_id
			):
				continue

			checked_ids[
				object_id
			] = true

			if _object_is_already_carried(
				object_node
			):
				continue

			var interaction_radius: float = (
				_get_interaction_radius(
					object_node
				)
			)

			var distance_sq: float = (
				player.global_position.distance_squared_to(
					object_node.global_position
				)
			)

			if distance_sq > (
				interaction_radius
				* interaction_radius
			):
				continue

			if distance_sq >= best_distance_sq:
				continue

			best_distance_sq = distance_sq

			best_object = object_node

	return best_object


func _object_is_already_carried(
	target: Node
) -> bool:
	if _has_property(
		target,
		"is_carried"
	):
		var value: Variant = target.get(
			"is_carried"
		)

		if (
			typeof(value) == TYPE_BOOL
			and bool(value)
		):
			return true

	return false


func _get_interaction_radius(
	target: Node
) -> float:
	if _has_property(
		target,
		"interaction_radius"
	):
		var value: Variant = target.get(
			"interaction_radius"
		)

		if (
			typeof(value) == TYPE_FLOAT
			or typeof(value) == TYPE_INT
		):
			return maxf(
				1.0,
				float(value)
			)

	return INTERACT_RANGE_FALLBACK


# ============================================================
# DODGE
# ============================================================

func _controller_dodge() -> void:
	_mark_controller_active()

	if not is_instance_valid(
		player
	):
		return

	# Nếu project sau này có hàm dodge riêng thì ưu tiên gọi.
	var method_names: Array[String] = [
		"start_dodge",
		"_start_dodge",
		"start_roll",
		"_start_roll"
	]

	for method_name: String in method_names:
		if player.has_method(
			method_name
		):
			player.call(
				method_name
			)

			return

	# Fallback trực tiếp vào state roll hiện tại của player.gd.
	if not (
		_has_property(
			player,
			"is_rolling"
		)
		and _has_property(
			player,
			"roll_time_left"
		)
		and _has_property(
			player,
			"roll_duration"
		)
		and _has_property(
			player,
			"roll_cooldown_timer"
		)
		and _has_property(
			player,
			"roll_cooldown"
		)
		and _has_property(
			player,
			"roll_direction"
		)
	):
		return

	var cooldown_timer: float = float(
		player.get(
			"roll_cooldown_timer"
		)
	)

	if cooldown_timer > 0.0:
		return

	if bool(
		player.get(
			"is_rolling"
		)
	):
		return

	var dodge_direction: Vector2 = (
		_get_controller_move_vector()
	)

	if dodge_direction.length_squared() <= 0.001:
		if _has_property(
			player,
			"aim_direction"
		):
			var aim_value: Variant = player.get(
				"aim_direction"
			)

			if typeof(
				aim_value
			) == TYPE_VECTOR2:
				dodge_direction = (
					aim_value as Vector2
				)

	if dodge_direction.length_squared() <= 0.001:
		dodge_direction = Vector2.RIGHT

	dodge_direction = (
		dodge_direction.normalized()
	)

	player.set(
		"roll_direction",
		dodge_direction
	)

	player.set(
		"is_rolling",
		true
	)

	player.set(
		"roll_time_left",
		float(
			player.get(
				"roll_duration"
			)
		)
	)

	player.set(
		"roll_cooldown_timer",
		float(
			player.get(
				"roll_cooldown"
			)
		)
	)


# ============================================================
# RELOAD
# ============================================================

func _controller_reload() -> void:
	_mark_controller_active()

	var weapon_system: Object = (
		_get_weapon_system()
	)

	if not is_instance_valid(
		weapon_system
	):
		return

	if weapon_system.has_method(
		"start_reload"
	):
		weapon_system.call(
			"start_reload"
		)


# ============================================================
# WEAPON SWITCH
# ============================================================

func _controller_weapon_previous() -> void:
	_mark_controller_active()

	_switch_weapon(
		-1
	)


func _controller_weapon_next() -> void:
	_mark_controller_active()

	_switch_weapon(
		1
	)


func _switch_weapon(
	direction: int
) -> void:
	var weapon_system: Object = (
		_get_weapon_system()
	)

	if not is_instance_valid(
		weapon_system
	):
		return

	if direction > 0:
		var next_methods: Array[String] = [
			"select_next_weapon",
			"next_weapon",
			"cycle_next_weapon",
			"equip_next_weapon"
		]

		for method_name: String in next_methods:
			if weapon_system.has_method(
				method_name
			):
				weapon_system.call(
					method_name
				)

				return

	else:
		var previous_methods: Array[String] = [
			"select_previous_weapon",
			"previous_weapon",
			"prev_weapon",
			"cycle_previous_weapon",
			"equip_previous_weapon"
		]

		for method_name: String in previous_methods:
			if weapon_system.has_method(
				method_name
			):
				weapon_system.call(
					method_name
				)

				return

	# Fallback cho weapon system dùng cycle_weapon(direction).
	if weapon_system.has_method(
		"cycle_weapon"
	):
		var argument_count: int = (
			_get_method_argument_count(
				weapon_system,
				"cycle_weapon"
			)
		)

		if argument_count == 1:
			weapon_system.call(
				"cycle_weapon",
				direction
			)

			return

	# Fallback thêm cho API switch_weapon_relative().
	if weapon_system.has_method(
		"switch_weapon_relative"
	):
		weapon_system.call(
			"switch_weapon_relative",
			direction
		)


# ============================================================
# WORLD PROMPT
# ============================================================

func _create_world_prompt() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	prompt_root = Node2D.new()

	prompt_root.z_index = 150
	prompt_root.visible = false

	scene.add_child(
		prompt_root
	)

	prompt_label = Label.new()

	prompt_label.position = Vector2(
		-90.0,
		-48.0
	)

	prompt_label.size = Vector2(
		180.0,
		30.0
	)

	prompt_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	prompt_label.add_theme_font_size_override(
		"font_size",
		11
	)

	prompt_label.add_theme_color_override(
		"font_color",
		Color(
			1.0,
			0.92,
			0.62,
			1.0
		)
	)

	prompt_root.add_child(
		prompt_label
	)


func _update_interaction_prompt() -> void:
	if (
		not is_instance_valid(
			prompt_root
		)
		or not is_instance_valid(
			prompt_label
		)
	):
		return

	var carried_object: Node = (
		_get_carried_object()
	)

	if is_instance_valid(
		carried_object
	):
		var carried_2d: Node2D = (
			carried_object as Node2D
		)

		if not is_instance_valid(
			carried_2d
		):
			_hide_prompt()
			return

		prompt_root.global_position = (
			carried_2d.global_position
		)

		if _using_controller_prompt():
			prompt_label.text = (
				"[RT] THROW    [A] PLACE"
			)

		else:
			prompt_label.text = (
				"[LMB] THROW    [E] PLACE"
			)

		prompt_root.visible = true

		_hide_legacy_prompt(
			carried_object
		)

		return

	var candidate: Node2D = (
		_find_nearest_interactable()
	)

	if not is_instance_valid(
		candidate
	):
		_hide_prompt()
		return

	prompt_root.global_position = (
		candidate.global_position
	)

	if _using_controller_prompt():
		prompt_label.text = "[A] PICK UP"

	else:
		prompt_label.text = "[E] PICK UP"

	prompt_root.visible = true

	_hide_legacy_prompt(
		candidate
	)


func _hide_prompt() -> void:
	if is_instance_valid(
		prompt_root
	):
		prompt_root.visible = false


func _hide_legacy_prompt(
	target: Node
) -> void:
	if not _has_property(
		target,
		"prompt_label"
	):
		return

	var value: Variant = target.get(
		"prompt_label"
	)

	if typeof(
		value
	) != TYPE_OBJECT:
		return

	if not is_instance_valid(
		value
	):
		return

	var canvas_item: CanvasItem = (
		value as CanvasItem
	)

	if is_instance_valid(
		canvas_item
	):
		canvas_item.visible = false


# ============================================================
# HELPERS
# ============================================================

func _get_weapon_system() -> Object:
	if not is_instance_valid(
		player
	):
		return null

	if not _has_property(
		player,
		"weapon_system"
	):
		return null

	var value: Variant = player.get(
		"weapon_system"
	)

	if typeof(
		value
	) != TYPE_OBJECT:
		return null

	if not is_instance_valid(
		value
	):
		return null

	return value as Object


func _get_controller_move_vector() -> Vector2:
	var joypads: Array[int] = (
		Input.get_connected_joypads()
	)

	for device_id: int in joypads:
		var result: Vector2 = Vector2(
			Input.get_joy_axis(
				device_id,
				JOY_AXIS_LEFT_X
			),
			Input.get_joy_axis(
				device_id,
				JOY_AXIS_LEFT_Y
			)
		)

		if result.length() > 0.22:
			return result.normalized()

	return Vector2.ZERO


func _any_joy_button_pressed(
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


func _any_trigger_pressed(
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

		if value > 0.20:
			return true

	return false


func _get_method_argument_count(
	target: Object,
	method_name: String
) -> int:
	for method_data: Dictionary in target.get_method_list():
		if str(
			method_data.get(
				"name",
				""
			)
		) != method_name:
			continue

		var args_value: Variant = method_data.get(
			"args",
			[]
		)

		if typeof(
			args_value
		) != TYPE_ARRAY:
			return -1

		var args: Array = (
			args_value
		)

		return args.size()

	return -1


func _has_property(
	target: Object,
	property_name: String
) -> bool:
	for property_data: Dictionary in target.get_property_list():
		if str(
			property_data.get(
				"name",
				""
			)
		) == property_name:
			return true

	return false
