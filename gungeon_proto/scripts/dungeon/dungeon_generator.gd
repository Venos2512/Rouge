extends Node


const DIR_UP := Vector2i(0, -1)
const DIR_DOWN := Vector2i(0, 1)
const DIR_LEFT := Vector2i(-1, 0)
const DIR_RIGHT := Vector2i(1, 0)

const DIRECTIONS: Array[Vector2i] = [
	DIR_UP,
	DIR_DOWN,
	DIR_LEFT,
	DIR_RIGHT,
]

const ROOM_SIZES: Array[Vector2] = [
	Vector2(1056.0, 600.0),
	Vector2(1152.0, 648.0),
	Vector2(1344.0, 756.0),
	Vector2(1536.0, 864.0),
]

const TERRAIN_VARIANTS: Dictionary = {
	"moss": ["overgrown", "roots", "shallow_water", "ancient_tiles"],
	"ice": ["frost", "cracked_ice", "snow_drift", "frozen_stone"],
	"lava": ["molten_cracks", "ash", "forge_plate", "scorched_stone"],
	"void": ["cosmic_rift", "dark_crystal", "star_dust", "lost_tiles"],
	"stone": ["clean", "cracked", "dusty", "ruined"],
}


@export_group("Data")
@export var generation_data: Resource
@export var room_rules: Resource


func generate(
	floor_number: int
) -> Dictionary:
	var archetype: Resource = _get_archetype(floor_number)
	var generated_rooms: Dictionary = {}

	var start_data: Dictionary = {
		"type": "start",
		"visited": true,
		"cleared": true,
		"enemy_count": 0,
		"reward_claimed": false,
		"layout_id": 0,
		"broken_props": [],
		"dungeon_profile": _get_profile_id(archetype),
		"terrain": _get_terrain_id(archetype),
		"terrain_variant": _pick_terrain_variant(archetype),
		"room_size": _pick_room_size(true),
	}

	start_data = _apply_rule_defaults(
		start_data
	)

	generated_rooms[
		Vector2i.ZERO
	] = start_data

	var positions: Array[Vector2i] = [
		Vector2i.ZERO
	]

	var target_room_count: int = 8
	var attempt_limit: int = 500

	if is_instance_valid(archetype):
		target_room_count = int(archetype.call("get_room_count"))

	if is_instance_valid(
		generation_data
	):
		if (
			not is_instance_valid(archetype)
			and generation_data.has_method(
			"get_target_room_count"
			)
		):
			target_room_count = int(
				generation_data.call(
					"get_target_room_count",
					floor_number
				)
			)

		attempt_limit = int(
			generation_data.get(
				"generation_attempt_limit"
			)
		)

	var attempts: int = 0

	while (
		positions.size()
		< target_room_count
		and attempts < attempt_limit
	):
		attempts += 1

		var base_room: Vector2i = _pick_base_room(positions, archetype)

		var direction: Vector2i = _pick_direction(archetype)

		var candidate: Vector2i = (
			base_room + direction
		)

		if generated_rooms.has(
			candidate
		):
			continue

		if (
			is_instance_valid(archetype)
			and not bool(archetype.call("contains", candidate))
		):
			continue

		var distance: int = (
			abs(candidate.x)
			+ abs(candidate.y)
		)

		var room_size: Vector2 = _pick_room_size(false)
		var enemy_count: int = _get_enemy_count(floor_number, distance)
		if room_size == ROOM_SIZES[1]:
			enemy_count = mini(enemy_count + 1, 8)
		elif room_size == ROOM_SIZES[2]:
			enemy_count = mini(enemy_count + 2, 9)

		var layout_id: int = _pick_layout_id_for_archetype(archetype)

		var room_data: Dictionary = {
			"type": "combat",
			"visited": false,
			"cleared": false,
			"enemy_count": enemy_count,
			"reward_claimed": false,
			"layout_id": layout_id,
			"broken_props": [],
			"dungeon_profile": _get_profile_id(archetype),
			"terrain": _get_terrain_id(archetype),
			"terrain_variant": _pick_terrain_variant(archetype),
			"room_size": room_size,
		}

		room_data = _apply_rule_defaults(
			room_data
		)

		generated_rooms[
			candidate
		] = room_data

		positions.append(
			candidate
		)

	_assign_special_rooms(
		generated_rooms,
		positions
	)

	_assign_door_offsets(generated_rooms)

	return generated_rooms


func _assign_door_offsets(generated_rooms: Dictionary) -> void:
	var processed_edges: Dictionary = {}

	for position_value: Variant in generated_rooms.keys():
		var room_position: Vector2i = position_value as Vector2i
		for direction: Vector2i in DIRECTIONS:
			var neighbor_position: Vector2i = room_position + direction
			if not generated_rooms.has(neighbor_position):
				continue

			var edge_key: String = _get_edge_key(room_position, neighbor_position)
			if processed_edges.has(edge_key):
				continue

			processed_edges[edge_key] = true
			var normalized_offset: float = _pick_door_lane()
			_set_door_offset(generated_rooms, room_position, direction, normalized_offset)
			_set_door_offset(generated_rooms, neighbor_position, -direction, normalized_offset)


func _get_edge_key(a: Vector2i, b: Vector2i) -> String:
	if a.x < b.x or (a.x == b.x and a.y <= b.y):
		return str(a) + "|" + str(b)
	return str(b) + "|" + str(a)


func _set_door_offset(
	generated_rooms: Dictionary,
	room_position: Vector2i,
	direction: Vector2i,
	normalized_offset: float
) -> void:
	var data: Dictionary = generated_rooms[room_position]
	var offsets: Dictionary = data.get("door_offsets", {}) as Dictionary
	offsets[_direction_key(direction)] = normalized_offset
	data["door_offsets"] = offsets
	generated_rooms[room_position] = data


func _direction_key(direction: Vector2i) -> String:
	if direction == DIR_UP:
		return "up"
	if direction == DIR_DOWN:
		return "down"
	if direction == DIR_LEFT:
		return "left"
	return "right"


func _pick_door_lane() -> float:
	var roll: float = randf()
	if roll < 0.25:
		return -0.42
	if roll < 0.75:
		return 0.0
	return 0.42


func _get_enemy_count(
	floor_number: int,
	distance: int
) -> int:
	if (
		is_instance_valid(
			generation_data
		)
		and generation_data.has_method(
			"get_enemy_count"
		)
	):
		return int(
			generation_data.call(
				"get_enemy_count",
				floor_number,
				distance
			)
		)

	return clampi(
		2
		+ distance
		+ int(
			float(floor_number)
			/ 2.0
		)
		+ randi_range(
			0,
			1
		),
		2,
		7
	)


func _pick_layout_id() -> int:
	if (
		is_instance_valid(
			generation_data
		)
		and generation_data.has_method(
			"pick_combat_layout_id"
		)
	):
		return int(
			generation_data.call(
				"pick_combat_layout_id"
			)
		)

	return randi_range(
		0,
		5
	)


func _pick_layout_id_for_archetype(archetype: Resource) -> int:
	if (
		is_instance_valid(archetype)
		and archetype.has_method("pick_layout_id")
	):
		return int(archetype.call("pick_layout_id"))

	return _pick_layout_id()


func _get_archetype(floor_number: int) -> Resource:
	if (
		is_instance_valid(generation_data)
		and generation_data.has_method("get_archetype")
	):
		return generation_data.call("get_archetype", floor_number) as Resource

	return null


func _get_profile_id(archetype: Resource) -> String:
	if not is_instance_valid(archetype):
		return "classic"

	return str(archetype.get("id"))


func _get_terrain_id(archetype: Resource) -> String:
	if not is_instance_valid(archetype):
		return "stone"

	return str(archetype.get("terrain_id"))


func _pick_terrain_variant(archetype: Resource) -> String:
	var terrain_id: String = _get_terrain_id(archetype)
	var variants: Array = TERRAIN_VARIANTS.get(terrain_id, TERRAIN_VARIANTS["stone"])
	return str(variants.pick_random())


func _pick_room_size(is_start: bool) -> Vector2:
	if is_start:
		return ROOM_SIZES[0]

	var roll: float = randf()
	if roll < 0.70:
		return ROOM_SIZES[0]
	if roll < 0.95:
		return ROOM_SIZES[1]
	return ROOM_SIZES[2]


func _pick_base_room(
	positions: Array[Vector2i],
	archetype: Resource
) -> Vector2i:
	if is_instance_valid(archetype):
		var chance: float = float(archetype.get("branch_from_latest_chance"))
		if randf() < chance:
			return positions.back()

	return positions.pick_random()


func _pick_direction(archetype: Resource) -> Vector2i:
	if not is_instance_valid(archetype):
		return DIRECTIONS.pick_random()

	match int(archetype.get("growth_style")):
		DungeonArchetypeData.GrowthStyle.HORIZONTAL:
			return [DIR_LEFT, DIR_RIGHT, DIR_LEFT, DIR_RIGHT, DIR_UP, DIR_DOWN].pick_random()
		DungeonArchetypeData.GrowthStyle.VERTICAL:
			return [DIR_UP, DIR_DOWN, DIR_UP, DIR_DOWN, DIR_LEFT, DIR_RIGHT].pick_random()

	return DIRECTIONS.pick_random()


func _assign_special_rooms(
	generated_rooms: Dictionary,
	positions: Array[Vector2i]
) -> void:
	var boss_room: Vector2i = (
		_find_farthest_room(
			positions,
			[]
		)
	)

	var treasure_room: Vector2i = (
		_find_farthest_room(
			positions,
			[
				boss_room
			]
		)
	)

	var elite_room: Vector2i = (
		_find_farthest_room(
			positions,
			[
				boss_room,
				treasure_room,
			]
		)
	)

	var shop_room: Vector2i = (
		_find_farthest_room(
			positions,
			[
				boss_room,
				treasure_room,
				elite_room,
			]
		)
	)

	_set_room_type(
		generated_rooms,
		boss_room,
		"boss"
	)

	_set_room_type(
		generated_rooms,
		treasure_room,
		"treasure"
	)

	_set_room_type(
		generated_rooms,
		elite_room,
		"elite"
	)

	_set_room_type(
		generated_rooms,
		shop_room,
		"shop"
	)

	if generated_rooms.has(
		shop_room
	):
		var shop_data: Dictionary = (
			generated_rooms[
				shop_room
			]
		)

		if not shop_data.has(
			"shop_offers"
		):
			shop_data[
				"shop_offers"
			] = []

		generated_rooms[
			shop_room
		] = shop_data


func _find_farthest_room(
	positions: Array[Vector2i],
	excluded: Array
) -> Vector2i:
	var best_room: Vector2i = (
		Vector2i.ZERO
	)

	var best_distance: int = -1

	for room_position: Vector2i in positions:
		if (
			room_position
			== Vector2i.ZERO
		):
			continue

		if excluded.has(
			room_position
		):
			continue

		var distance: int = (
			abs(room_position.x)
			+ abs(room_position.y)
		)

		if distance <= best_distance:
			continue

		best_distance = distance
		best_room = room_position

	return best_room


func _set_room_type(
	generated_rooms: Dictionary,
	room_position: Vector2i,
	room_type: String
) -> void:
	if not generated_rooms.has(
		room_position
	):
		return

	var data: Dictionary = (
		generated_rooms[
			room_position
		]
	)

	data["type"] = room_type

	if room_type == "boss":
		data["room_size"] = ROOM_SIZES[2]
	elif room_type == "elite":
		data["room_size"] = ROOM_SIZES[1]
	elif room_type == "shop" or room_type == "treasure":
		data["room_size"] = ROOM_SIZES[0]

	data = _apply_rule_defaults(
		data
	)

	generated_rooms[
		room_position
	] = data


func _apply_rule_defaults(
	data: Dictionary
) -> Dictionary:
	if not is_instance_valid(
		room_rules
	):
		return data

	if not room_rules.has_method(
		"get_rule"
	):
		return data

	var room_type: String = str(
		data.get(
			"type",
			"combat"
		)
	)

	var rule: Resource = (
		room_rules.call(
			"get_rule",
			room_type
		) as Resource
	)

	if not is_instance_valid(
		rule
	):
		return data

	var result: Dictionary = (
		data.duplicate(
			true
		)
	)

	if bool(
		rule.get(
			"auto_cleared"
		)
	):
		result["cleared"] = true

	var enemy_count_override: int = int(
		rule.get(
			"enemy_count_override"
		)
	)

	if enemy_count_override >= 0:
		result[
			"enemy_count"
		] = enemy_count_override

	return result
