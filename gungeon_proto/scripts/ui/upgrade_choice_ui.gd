extends Control

const GameHudIconScript = preload("res://gungeon_proto/scripts/ui/game_hud_icon.gd")
const GameAudio = preload("res://gungeon_proto/scripts/audio/game_audio.gd")

@onready var cards: Array[Button] = [$Panel/Box/Card1, $Panel/Box/Card2, $Panel/Box/Card3]
var upgrade_system: Node
var choices: Array[String] = []
var number_keys_were_down: Array[bool] = [false, false, false]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	for index in cards.size():
		cards[index].mouse_filter = Control.MOUSE_FILTER_STOP
		cards[index].focus_mode = Control.FOCUS_ALL
		cards[index].pressed.connect(_select_choice.bind(index))
		var icon := GameHudIconScript.new() as Control
		icon.name = "UpgradeIcon"
		icon.position = Vector2(8, 15)
		icon.size = Vector2(42, 42)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cards[index].add_child(icon)
	visible = false

func _process(_delta: float) -> void:
	if not visible:
		for index in number_keys_were_down.size():
			number_keys_were_down[index] = false
		return
	for index in number_keys_were_down.size():
		var is_down := Input.is_key_pressed(KEY_1 + index)
		if is_down and not number_keys_were_down[index]:
			_select_choice(index)
		number_keys_were_down[index] = is_down

func open_for_system(system: Node, source_type: String = "normal") -> void:
	if not is_instance_valid(system): return
	upgrade_system = system
	var result = system.call("get_random_choices", 3, source_type)
	if typeof(result) != TYPE_ARRAY: return
	choices.clear()
	for value in result: choices.append(str(value))
	if choices.is_empty(): return
	for index in cards.size():
		cards[index].visible = index < choices.size()
		if not cards[index].visible: continue
		var id := choices[index]
		var info: Dictionary = system.call("get_upgrade_info", id)
		var stacks := int(system.call("get_stack_count", id))
		cards[index].text = "     [%d] %s  -  %s\n     %s   STACK %d" % [index + 1, info.get("name", id), info.get("rarity", "COMMON"), info.get("description", ""), stacks]
		(cards[index].get_node("UpgradeIcon") as Control).call("configure", "upgrade", id, str(info.get("rarity", "COMMON")))
	visible = true
	if not cards.is_empty() and cards[0].visible:
		cards[0].grab_focus()
	GameAudio.play(self, "upgrade_choices_appear", 0.015)
	get_tree().paused = true

func _input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo: return
	var key_event := event as InputEventKey
	var pressed_key := key_event.keycode
	if pressed_key == KEY_NONE:
		pressed_key = key_event.physical_keycode
	if pressed_key in [KEY_1, KEY_2, KEY_3]:
		_select_choice(pressed_key - KEY_1)
		get_viewport().set_input_as_handled()

func _select_choice(index: int) -> void:
	if index < 0 or index >= choices.size() or not is_instance_valid(upgrade_system): return
	upgrade_system.call("apply_upgrade", choices[index])
	GameAudio.play(self, "upgrade_selected", 0.015)
	visible = false
	get_tree().paused = false
