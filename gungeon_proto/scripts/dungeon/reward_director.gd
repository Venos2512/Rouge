extends Node


func open_upgrade_choice(
	dungeon: Node,
	source_type: String
) -> bool:
	if not is_instance_valid(
		dungeon
	):
		return false

	var player: Node = _get_player(
		dungeon
	)

	if not is_instance_valid(
		player
	):
		return false

	var upgrade_choice_ui: Control = _get_upgrade_choice_ui(
		dungeon
	)

	if not is_instance_valid(
		upgrade_choice_ui
	):
		return false

	var system: Node = _get_upgrade_system(
		player
	)

	if not is_instance_valid(
		system
	):
		return false

	upgrade_choice_ui.call(
		"open_for_system",
		system,
		source_type
	)
	return bool(upgrade_choice_ui.visible)


func notify_upgrade_chest_opened(
	dungeon: Node
) -> void:
	_set_reward_claimed(
		dungeon,
		true
	)


func notify_weapon_picked(
	dungeon: Node
) -> void:
	if not is_instance_valid(
		dungeon
	):
		return

	var rooms_value: Variant = dungeon.get(
		"rooms"
	)

	if typeof(
		rooms_value
	) != TYPE_DICTIONARY:
		return

	var rooms: Dictionary = rooms_value

	var current_room_value: Variant = dungeon.get(
		"current_room"
	)

	if typeof(
		current_room_value
	) != TYPE_VECTOR2I:
		return

	var current_room: Vector2i = (
		current_room_value
	)

	if not rooms.has(
		current_room
	):
		return

	var data: Dictionary = rooms[
		current_room
	]

	if str(
		data.get(
			"type",
			""
		)
	) != "treasure":
		return

	data[
		"reward_claimed"
	] = true

	rooms[
		current_room
	] = data

	dungeon.set(
		"rooms",
		rooms
	)


func grant_elite_reward(
	dungeon: Node
) -> void:
	if not is_instance_valid(
		dungeon
	):
		return

	var player: Node = _get_player(
		dungeon
	)

	if not is_instance_valid(
		player
	):
		return

	var max_health: int = int(
		player.get(
			"max_health"
		)
	)

	var health: int = int(
		player.get(
			"health"
		)
	)

	health = mini(
		max_health,
		health + 1
	)

	player.set(
		"health",
		health
	)


func player_has_weapon(
	dungeon: Node,
	weapon_id: String
) -> bool:
	if not is_instance_valid(
		dungeon
	):
		return false

	var player: Node = _get_player(
		dungeon
	)

	if not is_instance_valid(
		player
	):
		return false

	var system: Node = _get_weapon_system(
		player
	)

	if not is_instance_valid(
		system
	):
		return false

	var unlocked_value: Variant = system.get(
		"unlocked"
	)

	if typeof(
		unlocked_value
	) != TYPE_DICTIONARY:
		return false

	var unlocked: Dictionary = (
		unlocked_value
	)

	return bool(
		unlocked.get(
			weapon_id,
			false
		)
	)


func _set_reward_claimed(
	dungeon: Node,
	claimed: bool
) -> void:
	if not is_instance_valid(
		dungeon
	):
		return

	var rooms_value: Variant = dungeon.get(
		"rooms"
	)

	if typeof(
		rooms_value
	) != TYPE_DICTIONARY:
		return

	var rooms: Dictionary = rooms_value

	var current_room_value: Variant = dungeon.get(
		"current_room"
	)

	if typeof(
		current_room_value
	) != TYPE_VECTOR2I:
		return

	var current_room: Vector2i = (
		current_room_value
	)

	if not rooms.has(
		current_room
	):
		return

	var data: Dictionary = rooms[
		current_room
	]

	data[
		"reward_claimed"
	] = claimed

	rooms[
		current_room
	] = data

	dungeon.set(
		"rooms",
		rooms
	)


func _get_player(
	dungeon: Node
) -> Node:
	var value: Variant = dungeon.get(
		"player"
	)

	if value == null:
		return null

	return value as Node


func _get_upgrade_system(
	player: Node
) -> Node:
	var value: Variant = player.get(
		"upgrade_system"
	)

	if value == null:
		return null

	return value as Node


func _get_upgrade_choice_ui(
	dungeon: Node
) -> Control:
	var direct_value: Variant = dungeon.get(
		"upgrade_choice_ui"
	)
	if direct_value is Control and is_instance_valid(direct_value):
		return direct_value as Control

	var node_value: Node = dungeon.get_node_or_null(
		"CoreRuntime/GameUI/DungeonHUD/UpgradeChoiceUI"
	)
	return node_value as Control


func _get_weapon_system(
	player: Node
) -> Node:
	var value: Variant = player.get(
		"weapon_system"
	)

	if value == null:
		return null

	return value as Node
