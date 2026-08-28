extends CanvasLayer


var overlay: ColorRect
var menu_panel: PanelContainer

var volume_slider: HSlider
var volume_value_label: Label
var mute_button: CheckButton

var is_open: bool = false
var escape_was_down: bool = false


func _ready() -> void:
	layer = 900

	process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	_build_ui()

	_set_menu_open(
		false
	)


func _process(
	_delta: float
) -> void:
	var escape_down: bool = Input.is_key_pressed(
		KEY_ESCAPE
	)

	var toggle_pressed: bool = (
		escape_down
		and not escape_was_down
	)

	escape_was_down = escape_down

	if toggle_pressed:
		_set_menu_open(
			not is_open
		)


func _build_ui() -> void:
	overlay = ColorRect.new()

	overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	overlay.color = Color(
		0.0,
		0.0,
		0.0,
		0.68
	)

	overlay.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	add_child(
		overlay
	)

	var center := CenterContainer.new()

	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	overlay.add_child(
		center
	)

	menu_panel = PanelContainer.new()

	menu_panel.custom_minimum_size = Vector2(
		340.0,
		330.0
	)

	center.add_child(
		menu_panel
	)

	var margin := MarginContainer.new()

	margin.add_theme_constant_override(
		"margin_left",
		28
	)

	margin.add_theme_constant_override(
		"margin_right",
		28
	)

	margin.add_theme_constant_override(
		"margin_top",
		24
	)

	margin.add_theme_constant_override(
		"margin_bottom",
		24
	)

	menu_panel.add_child(
		margin
	)

	var content := VBoxContainer.new()

	content.add_theme_constant_override(
		"separation",
		14
	)

	margin.add_child(
		content
	)

	var title := Label.new()

	title.text = "PAUSED"

	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.add_theme_font_size_override(
		"font_size",
		24
	)

	content.add_child(
		title
	)

	var subtitle := Label.new()

	subtitle.text = "SETTINGS"

	subtitle.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	subtitle.add_theme_font_size_override(
		"font_size",
		12
	)

	content.add_child(
		subtitle
	)

	content.add_child(
		HSeparator.new()
	)

	var volume_title := Label.new()

	volume_title.text = "MASTER VOLUME"

	content.add_child(
		volume_title
	)

	var volume_row := HBoxContainer.new()

	content.add_child(
		volume_row
	)

	volume_slider = HSlider.new()

	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0

	volume_slider.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	volume_slider.value = (
		_get_master_volume_percent()
	)

	volume_slider.value_changed.connect(
		_on_volume_changed
	)

	volume_row.add_child(
		volume_slider
	)

	volume_value_label = Label.new()

	volume_value_label.custom_minimum_size.x = 48.0

	volume_value_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	volume_row.add_child(
		volume_value_label
	)

	_update_volume_label()

	mute_button = CheckButton.new()

	mute_button.text = "Mute"

	mute_button.button_pressed = (
		AudioServer.is_bus_mute(
			0
		)
	)

	mute_button.toggled.connect(
		_on_mute_toggled
	)

	content.add_child(
		mute_button
	)

	content.add_child(
		HSeparator.new()
	)

	var resume_button := Button.new()

	resume_button.text = "RESUME"

	resume_button.custom_minimum_size.y = 42.0

	resume_button.pressed.connect(
		_on_resume_pressed
	)

	content.add_child(
		resume_button
	)

	var main_menu_button := Button.new()

	main_menu_button.text = "MAIN MENU"

	main_menu_button.custom_minimum_size.y = 42.0

	main_menu_button.pressed.connect(
		_on_main_menu_pressed
	)

	content.add_child(
		main_menu_button
	)

	var guide := Label.new()

	guide.text = (
		"Esc  •  Close"
	)

	guide.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	guide.add_theme_font_size_override(
		"font_size",
		10
	)

	content.add_child(
		guide
	)


func _set_menu_open(
	value: bool
) -> void:
	is_open = value

	if is_instance_valid(
		overlay
	):
		overlay.visible = is_open

	get_tree().paused = is_open

	if is_open:
		if is_instance_valid(
			volume_slider
		):
			volume_slider.grab_focus()


func _on_resume_pressed() -> void:
	_set_menu_open(
		false
	)


func _on_main_menu_pressed() -> void:
	get_tree().paused = false

	# Main scene hiện tại chứa main-menu overlay,
	# nên reload scene sẽ trở lại trạng thái menu ban đầu.
	get_tree().reload_current_scene()


func _on_volume_changed(
	value: float
) -> void:
	var linear_volume: float = clampf(
		value / 100.0,
		0.0,
		1.0
	)

	if linear_volume <= 0.0001:
		AudioServer.set_bus_volume_db(
			0,
			-80.0
		)

	else:
		AudioServer.set_bus_volume_db(
			0,
			linear_to_db(
				linear_volume
			)
		)

	_update_volume_label()


func _on_mute_toggled(
	value: bool
) -> void:
	AudioServer.set_bus_mute(
		0,
		value
	)


func _get_master_volume_percent() -> float:
	var volume_db: float = (
		AudioServer.get_bus_volume_db(
			0
		)
	)

	if volume_db <= -79.9:
		return 0.0

	return clampf(
		db_to_linear(
			volume_db
		) * 100.0,
		0.0,
		100.0
	)


func _update_volume_label() -> void:
	if not is_instance_valid(
		volume_value_label
	):
		return

	if not is_instance_valid(
		volume_slider
	):
		return

	volume_value_label.text = (
		str(
			roundi(
				volume_slider.value
			)
		)
		+ "%"
	)


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