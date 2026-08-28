extends CanvasLayer

const WeaponPickupScript = preload(
	"res://gungeon_proto/scripts/weapons/weapon_pickup.gd"
)
const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)

const ASSET_LIBRARY: Array[Dictionary] = [
	{"name": "Crate", "path": "res://gungeon_proto/scenes/props/crate.tscn"},
	{"name": "Pot", "path": "res://gungeon_proto/scenes/props/pot.tscn"},
	{"name": "Table", "path": "res://gungeon_proto/scenes/props/table.tscn"},
	{"name": "Pillar", "path": "res://gungeon_proto/scenes/props/pillar.tscn"},
	{"name": "Explosive Barrel", "path": "res://gungeon_proto/scenes/props/explosive_barrel.tscn"},
	{"name": "Spike Trap", "path": "res://gungeon_proto/scenes/gameplay/spike_trap.tscn"},
	{"name": "Saw Trap", "path": "res://gungeon_proto/scenes/gameplay/saw_trap.tscn"},
	{"name": "Upgrade Chest", "path": "res://gungeon_proto/scenes/gameplay/upgrade_chest.tscn"},
	{"name": "Enemy Chaser", "path": "res://gungeon_proto/scenes/enemies/chaser.tscn"},
	{"name": "Enemy Gunner", "path": "res://gungeon_proto/scenes/enemies/gunner.tscn"},
	{"name": "Enemy Spread", "path": "res://gungeon_proto/scenes/enemies/spread.tscn"},
	{"name": "Enemy Charger", "path": "res://gungeon_proto/scenes/enemies/charger.tscn"},
	{"name": "Enemy Shield", "path": "res://gungeon_proto/scenes/enemies/shield.tscn"},
	{"name": "Enemy Bomber", "path": "res://gungeon_proto/scenes/enemies/bomber.tscn"},
	{"name": "Enemy Suicide Bot", "path": "res://gungeon_proto/scenes/enemies/suicide_bot.tscn"},
	{"name": "Enemy Tactical Gunner", "path": "res://gungeon_proto/scenes/enemies/tactical_gunner.tscn"},
]

const EDITABLE_GROUPS: Array[StringName] = [
	&"dev_editable_assets",
	&"room_props",
	&"room_pickups",
	&"room_hazards",
	&"enemies",
]

const LIBRARY_WIDTH: float = 450.0
const SELECT_RADIUS: float = 30.0

var panel_root: Control
var weapon_list: VBoxContainer
var status_label: Label
var selection_rect: ReferenceRect

var f1_was_down: bool = false
var f2_was_down: bool = false
var escape_was_down: bool = false

var tool_open: bool = false
var selected_asset: Node2D = null
var dragging_asset: bool = false
var drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	layer = 500

	process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)

	_build_ui()


func _process(
	_delta: float
) -> void:
	var f1_down: bool = Input.is_key_pressed(
		KEY_F1
	)

	var f2_down: bool = Input.is_key_pressed(
		KEY_F2
	)

	var escape_down: bool = Input.is_key_pressed(
		KEY_ESCAPE
	)

	if (
		f1_down
		and not f1_was_down
	):
		_kill_all_enemies()

	if (
		f2_down
		and not f2_was_down
	):
		_toggle_tool()

	if (
		tool_open
		and escape_down
		and not escape_was_down
	):
		_close_tool()

	f1_was_down = f1_down
	f2_was_down = f2_down
	escape_was_down = escape_down

	_update_selection_indicator()


func _build_ui() -> void:
	panel_root = Control.new()

	panel_root.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	panel_root.visible = false
	panel_root.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	add_child(
		panel_root
	)

	var dimmer: ColorRect = ColorRect.new()

	dimmer.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	dimmer.color = Color(
		0.0,
		0.0,
		0.0,
		0.10
	)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel_root.add_child(
		dimmer
	)

	var center: CenterContainer = (
		CenterContainer.new()
	)

	center.set_anchors_and_offsets_preset(
		Control.PRESET_LEFT_WIDE
	)
	center.offset_right = LIBRARY_WIDTH
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel_root.add_child(
		center
	)

	var panel: PanelContainer = (
		PanelContainer.new()
	)

	panel.custom_minimum_size = Vector2(
		410.0,
		520.0
	)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	center.add_child(
		panel
	)

	var layout: VBoxContainer = (
		VBoxContainer.new()
	)

	layout.add_theme_constant_override(
		"separation",
		10
	)

	panel.add_child(
		layout
	)

	var title: Label = Label.new()

	title.text = "DEV TOOLS"

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

	var subtitle: Label = Label.new()

	subtitle.text = (
		"F2 CLOSE  |  DRAG ASSET  |  DELETE REMOVE"
	)

	subtitle.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	subtitle.add_theme_font_size_override(
		"font_size",
		11
	)

	subtitle.add_theme_color_override(
		"font_color",
		Color(
			0.62,
			0.62,
			0.66,
			1.0
		)
	)

	layout.add_child(
		subtitle
	)

	var separator: HSeparator = (
		HSeparator.new()
	)

	layout.add_child(
		separator
	)

	var weapon_title: Label = Label.new()

	weapon_title.text = "SPAWN WEAPON"

	weapon_title.add_theme_font_size_override(
		"font_size",
		16
	)

	layout.add_child(
		weapon_title
	)

	var scroll: ScrollContainer = (
		ScrollContainer.new()
	)

	scroll.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	layout.add_child(
		scroll
	)

	weapon_list = VBoxContainer.new()

	weapon_list.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	weapon_list.add_theme_constant_override(
		"separation",
		6
	)

	scroll.add_child(
		weapon_list
	)

	status_label = Label.new()

	status_label.text = ""

	status_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	status_label.add_theme_font_size_override(
		"font_size",
		11
	)

	layout.add_child(
		status_label
	)

	var close_button: Button = Button.new()

	close_button.text = "CLOSE"

	close_button.custom_minimum_size = Vector2(
		1.0,
		42.0
	)

	close_button.pressed.connect(
		_close_tool
	)

	layout.add_child(
		close_button
	)

	selection_rect = ReferenceRect.new()
	selection_rect.custom_minimum_size = Vector2(34.0, 34.0)
	selection_rect.size = Vector2(34.0, 34.0)
	selection_rect.border_color = Color(0.25, 0.95, 1.0, 1.0)
	selection_rect.border_width = 2.0
	selection_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_rect.visible = false
	add_child(selection_rect)


func _toggle_tool() -> void:
	if tool_open:
		_close_tool()

	else:
		_open_tool()


func _open_tool() -> void:
	tool_open = true

	panel_root.visible = true

	_refresh_weapon_buttons()

	get_tree().paused = true


func _close_tool() -> void:
	tool_open = false
	dragging_asset = false
	selected_asset = null

	panel_root.visible = false

	get_tree().paused = false


func _refresh_weapon_buttons() -> void:
	for child: Node in weapon_list.get_children():
		child.queue_free()

	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		status_label.text = "PLAYER NOT FOUND"

		return

	var weapon_system: Object = (
		_get_weapon_system(
			player
		)
	)

	if not is_instance_valid(
		weapon_system
	):
		status_label.text = "WEAPON SYSTEM NOT FOUND"

		return

	var weapon_ids: Array[String] = (
		_find_weapon_ids(
			weapon_system
		)
	)

	if weapon_ids.is_empty():
		status_label.text = "NO WEAPONS FOUND"

		return

	status_label.text = (
		str(
			weapon_ids.size()
		)
		+ " WEAPONS"
	)

	for weapon_id: String in weapon_ids:
		var button: Button = Button.new()

		button.text = (
			_format_weapon_name(
				weapon_id
			)
		)

		button.custom_minimum_size = Vector2(
			1.0,
			42.0
		)

		button.pressed.connect(
			_spawn_weapon.bind(
				weapon_id
			)
		)

		weapon_list.add_child(
			button
		)

	var asset_title := Label.new()
	asset_title.text = "ASSET LIBRARY"
	asset_title.add_theme_font_size_override("font_size", 16)
	weapon_list.add_child(asset_title)

	for asset_data: Dictionary in ASSET_LIBRARY:
		var asset_button := Button.new()
		asset_button.text = str(asset_data.get("name", "Asset")).to_upper()
		asset_button.custom_minimum_size = Vector2(1.0, 38.0)
		asset_button.pressed.connect(
			_spawn_asset.bind(
				str(asset_data.get("path", "")),
				str(asset_data.get("name", "Asset"))
			)
		)
		weapon_list.add_child(asset_button)


func _find_weapon_ids(
	weapon_system: Object
) -> Array[String]:
	var result: Array[String] = []

	for property_data: Dictionary in weapon_system.get_property_list():
		var property_name: String = str(
			property_data.get(
				"name",
				""
			)
		)

		if property_name.is_empty():
			continue

		var value: Variant = weapon_system.get(
			property_name
		)

		if typeof(
			value
		) != TYPE_DICTIONARY:
			continue

		var dictionary: Dictionary = value

		for key_value: Variant in dictionary.keys():
			var weapon_id: String = str(
				key_value
			)

			var weapon_value: Variant = dictionary[
				key_value
			]

			if typeof(
				weapon_value
			) != TYPE_DICTIONARY:
				continue

			var weapon_data: Dictionary = (
				weapon_value
			)

			# Dictionary weapon definition của project
			# đều có ít nhất một vài field này.
			if not (
				weapon_data.has(
					"damage"
				)
				and weapon_data.has(
					"fire_interval"
				)
			):
				continue

			if not result.has(
				weapon_id
			):
				result.append(
					weapon_id
				)

	result.sort()

	# Giữ các weapon cơ bản theo thứ tự dễ test.
	var preferred_order: Array[String] = [
		"pistol",
		"shotgun",
		"machine_gun",
		"crossbow",
		"sword",
		"spear",
		"hammer"
	]

	var sorted_result: Array[String] = []

	for weapon_id: String in preferred_order:
		if result.has(
			weapon_id
		):
			sorted_result.append(
				weapon_id
			)

	for weapon_id: String in result:
		if sorted_result.has(
			weapon_id
		):
			continue

		sorted_result.append(
			weapon_id
		)

	return sorted_result


func _spawn_weapon(
	weapon_id: String
) -> void:
	var player: Node2D = _get_player()

	if not is_instance_valid(
		player
	):
		status_label.text = "PLAYER NOT FOUND"

		return

	var pickup: Node2D = (
		WeaponPickupScript.new()
		as Node2D
	)

	if not is_instance_valid(
		pickup
	):
		status_label.text = "PICKUP CREATE FAILED"

		return

	var configured: bool = (
		_set_weapon_id_on_pickup(
			pickup,
			weapon_id
		)
	)

	if not configured:
		status_label.text = (
			"COULD NOT CONFIGURE "
			+ weapon_id.to_upper()
		)

		pickup.queue_free()

		return

	var scene: Node = (
		get_tree().current_scene
	)

	scene.add_child(
		pickup
	)

	var spawn_direction: Vector2 = (
		_get_player_aim_direction(
			player
		)
	)

	pickup.global_position = (
		player.global_position
		+ spawn_direction * 64.0
	)
	_register_editable_asset(pickup)

	status_label.text = (
		"SPAWNED "
		+ _format_weapon_name(
			weapon_id
		)
	)


func _spawn_asset(scene_path: String, display_name: String) -> void:
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		status_label.text = "ASSET LOAD FAILED: " + display_name.to_upper()
		return

	var asset: Node2D = packed.instantiate() as Node2D
	if not is_instance_valid(asset):
		status_label.text = "ASSET CREATE FAILED: " + display_name.to_upper()
		return

	var scene: Node = get_tree().current_scene
	var player: Node2D = _get_player()
	if not is_instance_valid(scene) or not is_instance_valid(player):
		asset.queue_free()
		status_label.text = "SCENE OR PLAYER NOT FOUND"
		return

	scene.add_child(asset)
	asset.global_position = (
		player.global_position
		+ _get_player_aim_direction(player) * 64.0
	)
	_register_editable_asset(asset)
	status_label.text = "SPAWNED " + display_name.to_upper() + " — DRAG TO MOVE"


func _register_editable_asset(asset: Node2D) -> void:
	if not asset.is_in_group("dev_editable_assets"):
		asset.add_to_group("dev_editable_assets")
	selected_asset = asset
	dragging_asset = false


func _input(event: InputEvent) -> void:
	if not tool_open:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if (
			key_event.pressed
			and not key_event.echo
			and key_event.keycode == KEY_DELETE
			and is_instance_valid(selected_asset)
		):
			selected_asset.queue_free()
			selected_asset = null
			dragging_asset = false
			status_label.text = "ASSET REMOVED"
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if not mouse_button.pressed:
			dragging_asset = false
			return
		if mouse_button.position.x <= LIBRARY_WIDTH:
			return

		var world_position := _screen_to_world(mouse_button.position)
		selected_asset = _find_editable_asset(world_position)
		if is_instance_valid(selected_asset):
			drag_offset = selected_asset.global_position - world_position
			dragging_asset = true
			status_label.text = "EDITING " + selected_asset.name.to_upper()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and dragging_asset:
		if not is_instance_valid(selected_asset):
			dragging_asset = false
			return
		var mouse_motion := event as InputEventMouseMotion
		selected_asset.global_position = (
			_screen_to_world(mouse_motion.position) + drag_offset
		)
		get_viewport().set_input_as_handled()


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


func _find_editable_asset(world_position: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance_sq: float = SELECT_RADIUS * SELECT_RADIUS
	var seen: Dictionary = {}

	for group_name: StringName in EDITABLE_GROUPS:
		for candidate_value: Node in get_tree().get_nodes_in_group(group_name):
			var candidate := candidate_value as Node2D
			if not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
				continue
			var candidate_id: int = candidate.get_instance_id()
			if seen.has(candidate_id):
				continue
			seen[candidate_id] = true
			var distance_sq := candidate.global_position.distance_squared_to(world_position)
			if distance_sq <= best_distance_sq:
				best_distance_sq = distance_sq
				best = candidate

	return best


func _update_selection_indicator() -> void:
	if not is_instance_valid(selection_rect):
		return
	if not tool_open or not is_instance_valid(selected_asset):
		selection_rect.visible = false
		return

	var screen_position: Vector2 = (
		get_viewport().get_canvas_transform() * selected_asset.global_position
	)
	selection_rect.position = screen_position - selection_rect.size * 0.5
	selection_rect.visible = true


func _set_weapon_id_on_pickup(
	pickup: Node,
	weapon_id: String
) -> bool:
	var property_names: Array[String] = [
		"weapon_id",
		"weapon_type",
		"weapon_name",
		"pickup_weapon_id"
	]

	for property_name: String in property_names:
		if not _has_property(
			pickup,
			property_name
		):
			continue

		pickup.set(
			property_name,
			weapon_id
		)

		return true

	# Fallback cho pickup script dùng setup/configure.
	var method_names: Array[String] = [
		"setup",
		"configure",
		"set_weapon"
	]

	for method_name: String in method_names:
		if not pickup.has_method(
			method_name
		):
			continue

		var argument_count: int = (
			_get_method_argument_count(
				pickup,
				method_name
			)
		)

		if argument_count != 1:
			continue

		pickup.call(
			method_name,
			weapon_id
		)

		return true

	return false


func _kill_all_enemies() -> void:
	var enemies: Array[Node] = (
		get_tree().get_nodes_in_group(
			"enemies"
		)
	)

	var killed_count: int = 0

	for enemy: Node in enemies:
		if not is_instance_valid(
			enemy
		):
			continue

		if enemy.is_queued_for_deletion():
			continue

		var result: RefCounted = DamageResolverScript.apply_simple_damage(
			enemy, 999999, &"void", [], self, self,
			enemy.global_position
		)
		if result.blocked:
			enemy.queue_free()

		killed_count += 1

	if is_instance_valid(
		status_label
	):
		status_label.text = (
			"KILLED "
			+ str(killed_count)
			+ " ENEMIES"
		)


func _get_player_aim_direction(
	player: Node2D
) -> Vector2:
	var aim_value: Variant = player.get(
		"aim_direction"
	)

	if typeof(
		aim_value
	) == TYPE_VECTOR2:
		var aim_direction: Vector2 = (
			aim_value
		)

		if (
			aim_direction.length_squared()
			> 0.001
		):
			return aim_direction.normalized()

	var mouse_direction: Vector2 = (
		player.get_global_mouse_position()
		- player.global_position
	)

	if (
		mouse_direction.length_squared()
		> 0.001
	):
		return mouse_direction.normalized()

	return Vector2.RIGHT


func _get_weapon_system(
	player: Node2D
) -> Object:
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


func _get_player() -> Node2D:
	var player_value: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)

	if not is_instance_valid(
		player_value
	):
		return null

	return player_value as Node2D


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

		var args: Array = args_value

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


func _format_weapon_name(
	weapon_id: String
) -> String:
	return (
		weapon_id
		.replace(
			"_",
			" "
		)
		.to_upper()
	)
