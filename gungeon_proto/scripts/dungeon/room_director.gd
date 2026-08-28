extends Node


const DIR_UP := Vector2i(0, -1)
const DIR_DOWN := Vector2i(0, 1)
const DIR_LEFT := Vector2i(-1, 0)
const DIR_RIGHT := Vector2i(1, 0)

const ROOM_TRANSITION_COOLDOWN: float = 0.28


func process_room(
	dungeon: Node,
	delta: float
) -> void:
	if not is_instance_valid(
		dungeon
	):
		return

	if bool(dungeon.get("room_transition_in_progress")):
		return

	var transition_cooldown: float = maxf(
		0.0,
		float(
			dungeon.get(
				"transition_cooldown"
			)
		) - delta
	)

	dungeon.set(
		"transition_cooldown",
		transition_cooldown
	)

	var room_cleared: bool = bool(
		dungeon.get(
			"room_cleared"
		)
	)

	if not room_cleared:
		var alive_count: int = get_alive_enemy_count(
			dungeon.get_tree()
		)

		if alive_count <= 0:
			complete_current_room(
				dungeon
			)

	room_cleared = bool(
		dungeon.get(
			"room_cleared"
		)
	)

	if room_cleared:
		check_room_transition(
			dungeon
		)


func enter_room(
	dungeon: Node,
	room_position: Vector2i,
	entry_from: Vector2i
) -> void:
	if not is_instance_valid(
		dungeon
	):
		return

	var rooms_value: Variant = (
		dungeon.get(
			"rooms"
		)
	)

	if typeof(
		rooms_value
	) != TYPE_DICTIONARY:
		return

	var rooms: Dictionary = rooms_value

	if not rooms.has(
		room_position
	):
		return

	if bool(dungeon.get("room_transition_in_progress")):
		return

	dungeon.set("room_transition_in_progress", true)

	clear_room_entities(
		dungeon
	)

	dungeon.set(
		"current_room",
		room_position
	)

	var data: Dictionary = rooms[
		room_position
	]

	data["visited"] = true

	rooms[
		room_position
	] = data

	dungeon.set(
		"rooms",
		rooms
	)

	var is_cleared: bool = bool(
		data.get(
			"cleared",
			false
		)
	)

	if dungeon.has_method("configure_room_geometry"):
		dungeon.call("configure_room_geometry", data)

	dungeon.set(
		"room_cleared",
		is_cleared
	)

	if entry_from != Vector2i.ZERO:
		place_player_at_entry(
			dungeon,
			entry_from
		)

	# Cho SceneTree và physics server giải phóng toàn bộ entity của
	# phòng cũ trước khi thêm collision/prop của phòng mới. Nếu làm
	# cả hai trong cùng frame, số node sống tạm thời tăng gần gấp đôi
	# và tạo spike rõ rệt ngay lúc bước qua cửa.
	await dungeon.get_tree().process_frame

	dungeon.call(
		"_spawn_room_layout",
		data
	)

	# Tách dựng hình học phòng khỏi spawn encounter. Enemy vừa spawn
	# thường chạy setup AI/collision trong frame đầu tiên, nên gom cùng
	# layout sẽ làm frame chuyển phòng quá nặng.
	await dungeon.get_tree().process_frame

	if is_cleared:
		dungeon.call(
			"_spawn_room_rewards"
		)
	else:
		dungeon.call(
			"_spawn_room_encounter",
			data
		)

	dungeon.set(
		"transition_cooldown",
		ROOM_TRANSITION_COOLDOWN
	)

	dungeon.set("room_transition_in_progress", false)

	dungeon.call(
		"_update_ui"
	)

	_queue_redraw(
		dungeon
	)


func complete_current_room(
	dungeon: Node
) -> void:
	if not is_instance_valid(
		dungeon
	):
		return

	if bool(
		dungeon.get(
			"room_cleared"
		)
	):
		return

	var rooms_value: Variant = (
		dungeon.get(
			"rooms"
		)
	)

	if typeof(
		rooms_value
	) != TYPE_DICTIONARY:
		return

	var rooms: Dictionary = rooms_value

	var current_room: Vector2i = (
		dungeon.get(
			"current_room"
		) as Vector2i
	)

	if not rooms.has(
		current_room
	):
		return

	dungeon.set(
		"room_cleared",
		true
	)

	var data: Dictionary = rooms[
		current_room
	]

	data["cleared"] = true

	rooms[
		current_room
	] = data

	dungeon.set(
		"rooms",
		rooms
	)

	print(
		"ROOM CLEAR: ",
		current_room
	)

	dungeon.call(
		"spawn_room_fx",
		Vector2.ZERO,
		"clear"
	)

	dungeon.call(
		"_spawn_room_rewards"
	)

	dungeon.call(
		"_update_ui"
	)

	_queue_redraw(
		dungeon
	)


func check_room_transition(
	dungeon: Node
) -> void:
	if not is_instance_valid(
		dungeon
	):
		return

	if float(
		dungeon.get(
			"transition_cooldown"
		)
	) > 0.0:
		return

	var player_value: Variant = (
		dungeon.get(
			"player"
		)
	)

	if player_value == null:
		return

	var player: Node2D = (
		player_value as Node2D
	)

	if not is_instance_valid(
		player
	):
		return

	var position_value: Vector2 = (
		player.position
	)
	var room_rect: Rect2 = dungeon.get("current_room_rect") as Rect2
	var horizontal_trigger: float = room_rect.size.x * 0.5 - 34.0
	var vertical_trigger: float = room_rect.size.y * 0.5 - 34.0
	var door_half_width: float = 52.0

	if (
		position_value.x > horizontal_trigger
		and absf(position_value.y - _get_door_offset(dungeon, DIR_RIGHT, room_rect)) <= door_half_width
		and (
			Input.is_key_pressed(
				KEY_D
			)
			or Input.is_key_pressed(
				KEY_RIGHT
			)
		)
	):
		if try_move_room(
			dungeon,
			DIR_RIGHT
		):
			return

	if (
		position_value.x < -horizontal_trigger
		and absf(position_value.y - _get_door_offset(dungeon, DIR_LEFT, room_rect)) <= door_half_width
		and (
			Input.is_key_pressed(
				KEY_A
			)
			or Input.is_key_pressed(
				KEY_LEFT
			)
		)
	):
		if try_move_room(
			dungeon,
			DIR_LEFT
		):
			return

	if (
		position_value.y > vertical_trigger
		and absf(position_value.x - _get_door_offset(dungeon, DIR_DOWN, room_rect)) <= door_half_width
		and (
			Input.is_key_pressed(
				KEY_S
			)
			or Input.is_key_pressed(
				KEY_DOWN
			)
		)
	):
		if try_move_room(
			dungeon,
			DIR_DOWN
		):
			return

	if (
		position_value.y < -vertical_trigger
		and absf(position_value.x - _get_door_offset(dungeon, DIR_UP, room_rect)) <= door_half_width
		and (
			Input.is_key_pressed(
				KEY_W
			)
			or Input.is_key_pressed(
				KEY_UP
			)
		)
	):
		try_move_room(
			dungeon,
			DIR_UP
		)


func try_move_room(
	dungeon: Node,
	direction: Vector2i
) -> bool:
	var rooms_value: Variant = (
		dungeon.get(
			"rooms"
		)
	)

	if typeof(
		rooms_value
	) != TYPE_DICTIONARY:
		return false

	var rooms: Dictionary = rooms_value

	var current_room: Vector2i = (
		dungeon.get(
			"current_room"
		) as Vector2i
	)

	var target_room: Vector2i = (
		current_room
		+ direction
	)

	if not rooms.has(
		target_room
	):
		return false

	enter_room(
		dungeon,
		target_room,
		-direction
	)

	return true


func place_player_at_entry(
	dungeon: Node,
	entry_from: Vector2i
) -> void:
	var player_value: Variant = (
		dungeon.get(
			"player"
		)
	)

	if player_value == null:
		return

	var player: Node2D = (
		player_value as Node2D
	)

	if not is_instance_valid(
		player
	):
		return

	var room_rect: Rect2 = dungeon.get("current_room_rect") as Rect2
	var entry_x: float = room_rect.size.x * 0.5 - 54.0
	var entry_y: float = room_rect.size.y * 0.5 - 54.0
	var door_offset: float = _get_door_offset(dungeon, entry_from, room_rect)

	match entry_from:
		DIR_LEFT:
			player.position = Vector2(
				-entry_x,
				door_offset
			)

		DIR_RIGHT:
			player.position = Vector2(
				entry_x,
				door_offset
			)

		DIR_UP:
			player.position = Vector2(
				door_offset,
				-entry_y
			)

		DIR_DOWN:
			player.position = Vector2(
				door_offset,
				entry_y
			)


func _get_door_offset(
	dungeon: Node,
	direction: Vector2i,
	room_rect: Rect2
) -> float:
	var rooms: Dictionary = dungeon.get("rooms") as Dictionary
	var current_room: Vector2i = dungeon.get("current_room") as Vector2i
	if not rooms.has(current_room):
		return 0.0

	var data: Dictionary = rooms[current_room]
	var offsets: Dictionary = data.get("door_offsets", {}) as Dictionary
	var key: String = "right"
	if direction == DIR_UP:
		key = "up"
	elif direction == DIR_DOWN:
		key = "down"
	elif direction == DIR_LEFT:
		key = "left"

	var normalized: float = float(offsets.get(key, 0.0))
	var usable_half_extent: float
	if direction == DIR_UP or direction == DIR_DOWN:
		usable_half_extent = room_rect.size.x * 0.5 - 96.0
	else:
		usable_half_extent = room_rect.size.y * 0.5 - 96.0

	return normalized * maxf(usable_half_extent, 0.0)


func clear_room_entities(
	dungeon: Node
) -> void:
	if not is_instance_valid(
		dungeon
	):
		return

	var tree: SceneTree = (
		dungeon.get_tree()
	)

	var groups: Array[String] = [
		"enemies",
		"enemy_bullets",
		"player_bullets",
		"room_pickups",
		"room_props",
		"room_hazards",
		"room_fx",
	]

	for group_name: String in groups:
		for node: Node in tree.get_nodes_in_group(
			group_name
		):
			if not is_instance_valid(
				node
			):
				continue

			node.queue_free()


func get_alive_enemy_count(
	tree: SceneTree
) -> int:
	var count: int = 0

	for enemy: Node in tree.get_nodes_in_group(
		"enemies"
	):
		if not is_instance_valid(
			enemy
		):
			continue

		if enemy.is_queued_for_deletion():
			continue

		count += 1

	return count


func _queue_redraw(
	dungeon: Node
) -> void:
	if not is_instance_valid(
		dungeon
	):
		return

	if dungeon.has_method(
		"refresh_room_visuals"
	):
		dungeon.call(
			"refresh_room_visuals"
		)

		return

	if dungeon is CanvasItem:
		var canvas_item: CanvasItem = (
			dungeon as CanvasItem
		)

		canvas_item.queue_redraw()
