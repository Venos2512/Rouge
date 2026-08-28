extends RefCounted


const PATTERNS: Array = [
	[
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 1),
		Vector2i(-1, 1),
		Vector2i(1, -1),
		Vector2i(-1, -1),
		Vector2i(2, 0),
		Vector2i(-2, 0)
	],
	[
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(2, 1),
		Vector2i(1, 1),
		Vector2i(0, 1),
		Vector2i(-1, 1),
		Vector2i(-1, 2),
		Vector2i(0, 2),
		Vector2i(1, 2),
		Vector2i(2, 2)
	],
	[
		Vector2i(0, 0),
		Vector2i(0, -1),
		Vector2i(0, -2),
		Vector2i(-1, -2),
		Vector2i(1, -2),
		Vector2i(-2, -2),
		Vector2i(2, -2),
		Vector2i(-2, -1),
		Vector2i(2, -1),
		Vector2i(-2, 0),
		Vector2i(2, 0)
	],
	[
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(1, -1),
		Vector2i(2, -1),
		Vector2i(2, -2),
		Vector2i(1, -2),
		Vector2i(0, -2),
		Vector2i(0, -1),
		Vector2i(-1, -1),
		Vector2i(-1, -2),
		Vector2i(-2, -2)
	],
	[
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
		Vector2i(3, 0),
		Vector2i(3, 1),
		Vector2i(2, 1),
		Vector2i(1, 1),
		Vector2i(0, 1),
		Vector2i(-1, 1),
		Vector2i(-2, 1),
		Vector2i(-3, 1)
	],
	[
		Vector2i(0, 0),
		Vector2i(0, -1),
		Vector2i(0, -2),
		Vector2i(1, -2),
		Vector2i(1, -1),
		Vector2i(1, 0),
		Vector2i(1, 1),
		Vector2i(1, 2),
		Vector2i(0, 2),
		Vector2i(-1, 2),
		Vector2i(-1, 1)
	]
]


const SPECIAL_TYPES: Array[String] = [
	"boss",
	"treasure",
	"elite",
	"shop"
]


static func remap(
	source_rooms: Dictionary,
	floor_number: int
) -> Dictionary:
	if source_rooms.is_empty():
		return {}

	var start_value: Variant = source_rooms.get(Vector2i.ZERO, {})
	if (
		typeof(start_value) == TYPE_DICTIONARY
		and (start_value as Dictionary).has("dungeon_profile")
	):
		return source_rooms.duplicate(true)

	if source_rooms.size() < 6:
		return source_rooms.duplicate(true)

	var rng := RandomNumberGenerator.new()

	rng.randomize()

	var source_data: Array[Dictionary] = []

	var start_data: Dictionary = {}

	for key_value: Variant in source_rooms.keys():
		var data_value: Variant = source_rooms[
			key_value
		]

		if typeof(
			data_value
		) != TYPE_DICTIONARY:
			continue

		var data: Dictionary = (
			data_value as Dictionary
		).duplicate(
			true
		)

		var room_type: String = str(
			data.get(
				"type",
				"combat"
			)
		)

		if (
			room_type == "start"
			or key_value == Vector2i.ZERO
		):
			start_data = data
			continue

		source_data.append(
			data
		)

	if start_data.is_empty():
		start_data = {
			"type": "start",
			"visited": true,
			"cleared": true,
			"enemy_count": 0,
			"reward_claimed": false,
			"layout_id": 0,
			"broken_props": []
		}

	var minimum_count: int = mini(
		7,
		source_rooms.size()
	)

	var shrink_budget: int = maxi(
		0,
		source_rooms.size()
		- minimum_count
	)

	var shrink_amount: int = 0

	if shrink_budget > 0:
		shrink_amount = rng.randi_range(
			0,
			mini(
				2,
				shrink_budget
			)
		)

	var target_count: int = (
		source_rooms.size()
		- shrink_amount
	)

	var required_specials: int = 1

	for room_data: Dictionary in source_data:
		if SPECIAL_TYPES.has(
			str(
				room_data.get(
					"type",
					""
				)
			)
		):
			required_specials += 1

	target_count = maxi(
		target_count,
		required_specials
	)

	target_count = clampi(
		target_count,
		1,
		11
	)

	var pattern_index: int = rng.randi_range(
		0,
		PATTERNS.size() - 1
	)

	var pattern: Array = PATTERNS[
		pattern_index
	]

	target_count = mini(
		target_count,
		pattern.size()
	)

	var positions: Array[Vector2i] = []

	for i: int in range(
		target_count
	):
		positions.append(
			pattern[i] as Vector2i
		)

	var result: Dictionary = {}

	start_data["visited"] = true
	start_data["cleared"] = true
	start_data["map_pattern"] = pattern_index

	result[
		Vector2i.ZERO
	] = start_data

	var available: Array[Vector2i] = []

	for room_position: Vector2i in positions:
		if room_position == Vector2i.ZERO:
			continue

		available.append(
			room_position
		)

	# Đưa các phòng đặc biệt ra các nhánh xa.
	for special_type: String in SPECIAL_TYPES:
		var special_data: Dictionary = (
			_take_room_type(
				source_data,
				special_type
			)
		)

		if special_data.is_empty():
			continue

		if available.is_empty():
			break

		var target_position: Vector2i = (
			_take_farthest_position(
				available
			)
		)

		special_data["map_pattern"] = (
			pattern_index
		)

		result[
			target_position
		] = special_data

	# Trộn combat room để layout / enemy count
	# không luôn xuất hiện ở cùng vị trí.
	source_data.shuffle()

	for room_data: Dictionary in source_data:
		if available.is_empty():
			break

		var target_position: Vector2i = (
			available.pop_front()
		)

		room_data["map_pattern"] = (
			pattern_index
		)

		result[
			target_position
		] = room_data

	print(
		"DUNGEON PATTERN ",
		pattern_index,
		" | FLOOR ",
		floor_number,
		" | ROOMS ",
		result.size()
	)

	return result


static func _take_room_type(
	source_data: Array[Dictionary],
	room_type: String
) -> Dictionary:
	for i: int in range(
		source_data.size()
	):
		var data: Dictionary = source_data[i]

		if str(
			data.get(
				"type",
				""
			)
		) != room_type:
			continue

		source_data.remove_at(
			i
		)

		return data

	return {}


static func _take_farthest_position(
	positions: Array[Vector2i]
) -> Vector2i:
	var best_index: int = 0
	var best_distance: int = -1

	for i: int in range(
		positions.size()
	):
		var position_value: Vector2i = (
			positions[i]
		)

		var distance: int = (
			abs(
				position_value.x
			)
			+ abs(
				position_value.y
			)
		)

		if distance <= best_distance:
			continue

		best_distance = distance
		best_index = i

	var result: Vector2i = positions[
		best_index
	]

	positions.remove_at(
		best_index
	)

	return result
