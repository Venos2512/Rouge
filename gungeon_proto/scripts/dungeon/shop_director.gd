extends Node


func spawn_shop(
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

	var system: Node = _get_upgrade_system(
		player
	)

	if not is_instance_valid(
		system
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

	var offers: Array[String] = []

	var stored_value: Variant = data.get(
		"shop_offers",
		[]
	)

	if typeof(
		stored_value
	) == TYPE_ARRAY:
		for offer_value: Variant in stored_value:
			offers.append(
				str(
					offer_value
				)
			)

	var room_flow_director: Node = (
		_get_room_flow_director()
	)

	if offers.is_empty():
		var choice_count: int = 3

		if is_instance_valid(
			room_flow_director
		):
			choice_count = int(
				room_flow_director.call(
					"get_shop_choice_count"
				)
			)

		var result: Variant = system.call(
			"get_random_choices",
			choice_count,
			"shop"
		)

		if typeof(
			result
		) == TYPE_ARRAY:
			for offer_value: Variant in result:
				offers.append(
					str(
						offer_value
					)
				)

		data[
			"shop_offers"
		] = offers

		rooms[
			current_room
		] = data

		dungeon.set(
			"rooms",
			rooms
		)

	var positions: Array[Vector2] = []

	if is_instance_valid(
		room_flow_director
	):
		var positions_value: Variant = (
			room_flow_director.call(
				"get_shop_positions"
			)
		)

		if typeof(
			positions_value
		) == TYPE_ARRAY:
			for position_value: Variant in positions_value:
				if typeof(
					position_value
				) != TYPE_VECTOR2:
					continue

				positions.append(
					position_value
				)

	if positions.is_empty():
		positions = [
			Vector2(
				-145.0,
				20.0
			),
			Vector2(
				0.0,
				20.0
			),
			Vector2(
				145.0,
				20.0
			),
		]

	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		push_error(
			"ShopDirector: GameplaySpawner không tồn tại."
		)
		return

	for i: int in range(
		offers.size()
	):
		if i >= positions.size():
			break

		var upgrade_id: String = (
			offers[i]
		)

		if upgrade_id.is_empty():
			continue

		var info_value: Variant = system.call(
			"get_upgrade_info",
			upgrade_id
		)

		if typeof(
			info_value
		) != TYPE_DICTIONARY:
			continue

		var info: Dictionary = info_value

		var rarity: String = str(
			info.get(
				"rarity",
				"COMMON"
			)
		)

		var cost: int = get_shop_price(
			rarity,
			int(
				dungeon.get(
					"floor_number"
				)
			)
		)

		gameplay_spawner.call(
			"spawn_shop_item",
			dungeon,
			upgrade_id,
			str(
				info.get(
					"name",
					upgrade_id
				)
			),
			rarity,
			cost,
			positions[i]
		)


func get_shop_price(
	rarity: String,
	floor_number: int
) -> int:
	var room_flow_director: Node = (
		_get_room_flow_director()
	)

	if not is_instance_valid(
		room_flow_director
	):
		return 15

	return int(
		room_flow_director.call(
			"get_shop_price",
			rarity,
			floor_number
		)
	)


func try_purchase_upgrade(
	dungeon: Node,
	upgrade_id: String,
	cost: int
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

	if not player.has_method(
		"spend_gold"
	):
		return false

	var paid: bool = bool(
		player.call(
			"spend_gold",
			cost
		)
	)

	if not paid:
		print(
			"NOT ENOUGH GOLD"
		)

		return false

	var system: Node = _get_upgrade_system(
		player
	)

	if not is_instance_valid(
		system
	):
		if player.has_method(
			"add_gold"
		):
			player.call(
				"add_gold",
				cost
			)

		return false

	system.call(
		"apply_upgrade",
		upgrade_id
	)

	_remove_purchased_offer(
		dungeon,
		upgrade_id
	)

	return true


func _remove_purchased_offer(
	dungeon: Node,
	upgrade_id: String
) -> void:
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

	var offers_value: Variant = data.get(
		"shop_offers",
		[]
	)

	if typeof(
		offers_value
	) != TYPE_ARRAY:
		return

	var offers: Array = offers_value

	for i: int in range(
		offers.size()
	):
		if str(
			offers[i]
		) != upgrade_id:
			continue

		offers[i] = ""
		break

	data[
		"shop_offers"
	] = offers

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
	if not is_instance_valid(
		player
	):
		return null

	var value: Variant = player.get(
		"upgrade_system"
	)

	if value == null:
		return null

	return value as Node


func _get_room_flow_director() -> Node:
	var parent_node: Node = get_parent()

	if not is_instance_valid(
		parent_node
	):
		return null

	return parent_node.get_node_or_null(
		"RoomFlowDirector"
	)


func _get_gameplay_spawner() -> Node:
	var parent_node: Node = get_parent()

	if not is_instance_valid(
		parent_node
	):
		return null

	return parent_node.get_node_or_null(
		"GameplaySpawner"
	)