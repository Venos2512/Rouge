extends CanvasLayer

const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)


const SETTINGS_PATH := "user://settings.cfg"

var root: Control
var master_slider: HSlider
var volume_value_label: Label
var mute_button: CheckButton

var master_volume: float = 1.0
var master_muted: bool = false


func _ready() -> void:
	layer = 2000
	transform = Transform2D.IDENTITY.scaled(Vector2(0.82, 0.82))

	process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	_build_ui()
	_load_audio_settings()
	_apply_audio_settings()

	root.visible = false


func _input(
	event: InputEvent
) -> void:
	if not (
		event is InputEventKey
	):
		return

	var key_event := (
		event as InputEventKey
	)

	if not key_event.pressed:
		return

	if key_event.echo:
		return

	if key_event.keycode != KEY_ESCAPE:
		return

	if (
		is_instance_valid(root)
		and root.visible
	):
		_close_menu()

		get_viewport().set_input_as_handled()
		return

	# Không mở chồng lên Upgrade UI,
	# DevTools hoặc Main Menu nếu hệ khác
	# đang pause game.
	if get_tree().paused:
		return

	_open_menu()

	get_viewport().set_input_as_handled()


func _build_ui() -> void:
	root = Control.new()

	root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	root.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	add_child(
		root
	)

	var dimmer := ColorRect.new()

	dimmer.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	dimmer.color = Color(
		0.0,
		0.0,
		0.0,
		0.72
	)

	dimmer.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	root.add_child(
		dimmer
	)

	var center := CenterContainer.new()

	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	root.add_child(
		center
	)

	var panel := PanelContainer.new()

	panel.custom_minimum_size = Vector2(
		430.0,
		410.0
	)

	center.add_child(
		panel
	)

	var margin := MarginContainer.new()

	margin.add_theme_constant_override(
		"margin_left",
		32
	)

	margin.add_theme_constant_override(
		"margin_right",
		32
	)

	margin.add_theme_constant_override(
		"margin_top",
		28
	)

	margin.add_theme_constant_override(
		"margin_bottom",
		28
	)

	panel.add_child(
		margin
	)

	var layout := VBoxContainer.new()

	layout.add_theme_constant_override(
		"separation",
		14
	)

	margin.add_child(
		layout
	)

	var title := Label.new()

	title.text = "PAUSED"

	title.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	title.add_theme_font_size_override(
		"font_size",
		26
	)

	layout.add_child(
		title
	)

	var hint := Label.new()

	hint.text = "ESC  -  RESUME"

	hint.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	hint.add_theme_font_size_override(
		"font_size",
		11
	)

	layout.add_child(
		hint
	)

	var separator := HSeparator.new()

	layout.add_child(
		separator
	)

	var audio_title := Label.new()

	audio_title.text = "AUDIO"

	audio_title.add_theme_font_size_override(
		"font_size",
		16
	)

	layout.add_child(
		audio_title
	)

	var volume_header := HBoxContainer.new()

	layout.add_child(
		volume_header
	)

	var volume_label := Label.new()

	volume_label.text = "MASTER VOLUME"

	volume_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	volume_header.add_child(
		volume_label
	)

	volume_value_label = Label.new()

	volume_value_label.text = "100%"

	volume_header.add_child(
		volume_value_label
	)

	master_slider = HSlider.new()

	master_slider.min_value = 0.0
	master_slider.max_value = 100.0
	master_slider.step = 1.0
	master_slider.value = 100.0

	master_slider.custom_minimum_size = Vector2(
		1.0,
		34.0
	)

	master_slider.value_changed.connect(
		_on_master_volume_changed
	)

	layout.add_child(
		master_slider
	)

	mute_button = CheckButton.new()

	mute_button.text = "MUTE ALL AUDIO"

	mute_button.toggled.connect(
		_on_master_mute_toggled
	)

	layout.add_child(
		mute_button
	)

	var button_separator := HSeparator.new()

	layout.add_child(
		button_separator
	)

	var resume_button := Button.new()

	resume_button.text = "RESUME"

	resume_button.custom_minimum_size = Vector2(
		1.0,
		48.0
	)

	resume_button.pressed.connect(
		_close_menu
	)

	layout.add_child(
		resume_button
	)

	var main_menu_button := Button.new()

	main_menu_button.text = "MAIN MENU"

	main_menu_button.custom_minimum_size = Vector2(
		1.0,
		48.0
	)

	main_menu_button.pressed.connect(
		_return_to_main_menu
	)

	layout.add_child(
		main_menu_button
	)


func _open_menu() -> void:
	if not is_instance_valid(
		root
	):
		return

	root.visible = true
	GameAudio.play(self, "ui_pause_open", 0.0)

	get_tree().paused = true


func _close_menu() -> void:
	if not is_instance_valid(
		root
	):
		return

	root.visible = false
	GameAudio.play(self, "ui_pause_close", 0.0)

	get_tree().paused = false


func _return_to_main_menu() -> void:
	_save_audio_settings()

	if is_instance_valid(
		root
	):
		root.visible = false

	get_tree().paused = false

	Engine.time_scale = 1.0

	get_tree().reload_current_scene()


func _on_master_volume_changed(
	value: float
) -> void:
	master_volume = clampf(
		value / 100.0,
		0.0,
		1.0
	)

	_apply_audio_settings()
	_save_audio_settings()


func _on_master_mute_toggled(
	muted: bool
) -> void:
	master_muted = muted

	_apply_audio_settings()
	_save_audio_settings()


func _apply_audio_settings() -> void:
	var master_bus: int = (
		AudioServer.get_bus_index(
			"Master"
		)
	)

	if master_bus < 0:
		return

	var safe_volume: float = maxf(
		master_volume,
		0.0001
	)

	AudioServer.set_bus_volume_db(
		master_bus,
		linear_to_db(
			safe_volume
		)
	)

	AudioServer.set_bus_mute(
		master_bus,
		master_muted
	)

	_update_volume_label()


func _update_volume_label() -> void:
	if not is_instance_valid(
		volume_value_label
	):
		return

	volume_value_label.text = (
		str(
			roundi(
				master_volume * 100.0
			)
		)
		+ "%"
	)


func _load_audio_settings() -> void:
	var config := ConfigFile.new()

	var error: Error = config.load(
		SETTINGS_PATH
	)

	if error == OK:
		master_volume = clampf(
			float(
				config.get_value(
					"audio",
					"master_volume",
					1.0
				)
			),
			0.0,
			1.0
		)

		master_muted = bool(
			config.get_value(
				"audio",
				"master_muted",
				false
			)
		)

	if is_instance_valid(
		master_slider
	):
		master_slider.value = (
			master_volume * 100.0
		)

	if is_instance_valid(
		mute_button
	):
		mute_button.button_pressed = (
			master_muted
		)

	_update_volume_label()


func _save_audio_settings() -> void:
	var config := ConfigFile.new()

	config.set_value(
		"audio",
		"master_volume",
		master_volume
	)

	config.set_value(
		"audio",
		"master_muted",
		master_muted
	)

	config.save(
		SETTINGS_PATH
	)
