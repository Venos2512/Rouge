extends SceneTree


const GENERATOR_SCRIPT := preload(
	"res://gungeon_proto/scripts/dungeon/dungeon_generator.gd"
)
const GENERATION_DATA := preload(
	"res://gungeon_proto/resources/dungeon/dungeon_generation.tres"
)
const BIOME_GEOMETRY := preload(
	"res://gungeon_proto/scripts/dungeon/biome_room_geometry.gd"
)
const SAMPLE_LAYOUT := preload(
	"res://gungeon_proto/resources/dungeon/layout_combat_0.tres"
)
const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT,
]
const VALID_ROOM_SIZES: Array[Vector2] = [
	Vector2(1056.0, 600.0),
	Vector2(1152.0, 648.0),
	Vector2(1344.0, 756.0),
	Vector2(1536.0, 864.0),
]


func _init() -> void:
	var generator: Node = GENERATOR_SCRIPT.new()
	generator.generation_data = GENERATION_DATA
	root.add_child(generator)

	var failures: Array[String] = []
	var seen_profiles: Dictionary = {}

	for floor_number: int in range(1, 9):
		var archetype: Resource = GENERATION_DATA.get_archetype(floor_number)
		var rooms: Dictionary = generator.generate(floor_number)
		var profile_id: String = str(archetype.get("id"))
		seen_profiles[profile_id] = true

		var minimum_rooms: int = int(archetype.get("minimum_rooms"))
		var maximum_rooms: int = int(archetype.get("maximum_rooms"))
		if rooms.size() < minimum_rooms or rooms.size() > maximum_rooms:
			failures.append(
				"Floor %d có %d phòng, ngoài khoảng %d-%d."
				% [floor_number, rooms.size(), minimum_rooms, maximum_rooms]
			)

		_validate_rooms(rooms, profile_id, failures)

	if seen_profiles.size() != 4:
		failures.append("Không xoay vòng đủ bốn dungeon profile.")

	_validate_biome_geometry(failures)

	generator.free()

	if failures.is_empty():
		print("DUNGEON_VARIETY_TEST_OK")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
	quit(1)


func _validate_biome_geometry(failures: Array[String]) -> void:
	var base_rect := Rect2(-528.0, -300.0, 1056.0, 600.0)
	var base_wall_count: int = (SAMPLE_LAYOUT.get("walls") as Array).size()

	for terrain_id: String in ["moss", "ice", "lava", "void"]:
		var geometry: Dictionary = BIOME_GEOMETRY.build(
			SAMPLE_LAYOUT,
			{"terrain": terrain_id, "type": "combat"},
			base_rect
		)
		if (geometry.get("walls", []) as Array).size() < base_wall_count:
			failures.append("Biome làm mất wall cơ sở: " + terrain_id)
		if (
			(geometry.get("props", []) as Array).is_empty()
			and (geometry.get("spike_traps", []) as Array).is_empty()
			and (geometry.get("saw_traps", []) as Array).is_empty()
		):
			failures.append("Biome không tạo dấu ấn hình học: " + terrain_id)


func _validate_rooms(
	rooms: Dictionary,
	profile_id: String,
	failures: Array[String]
) -> void:
	for position_value: Variant in rooms:
		var position: Vector2i = position_value as Vector2i
		var data: Dictionary = rooms[position]
		if str(data.get("dungeon_profile", "")) != profile_id:
			failures.append("Room thiếu dungeon profile: " + str(position))

		if str(data.get("terrain_variant", "")).is_empty():
			failures.append("Room thiếu terrain variant: " + str(position))

		var room_size: Vector2 = data.get("room_size", Vector2.ZERO) as Vector2
		if not VALID_ROOM_SIZES.has(room_size):
			failures.append("Room có kích thước không hợp lệ: " + str(room_size))

		if position == Vector2i.ZERO:
			_validate_door_offsets(rooms, position, data, failures)
			continue

		var connected: bool = false
		for direction: Vector2i in DIRECTIONS:
			if rooms.has(position + direction):
				connected = true
				break

		if not connected:
			failures.append("Room bị cô lập: " + str(position))

		_validate_door_offsets(rooms, position, data, failures)


func _validate_door_offsets(
	rooms: Dictionary,
	position: Vector2i,
	data: Dictionary,
	failures: Array[String]
) -> void:
	var offsets: Dictionary = data.get("door_offsets", {}) as Dictionary
	var keys: Array[String] = ["up", "down", "left", "right"]
	var opposite_keys: Array[String] = ["down", "up", "right", "left"]

	for index: int in range(DIRECTIONS.size()):
		var neighbor: Vector2i = position + DIRECTIONS[index]
		if not rooms.has(neighbor):
			continue
		if not offsets.has(keys[index]):
			failures.append("Room thiếu offset cửa: " + str(position))
			continue

		var offset_value: float = float(offsets[keys[index]])
		if not (
			is_equal_approx(offset_value, -0.42)
			or is_zero_approx(offset_value)
			or is_equal_approx(offset_value, 0.42)
		):
			failures.append("Cửa không nằm trên một trong ba lane: " + str(position))

		var neighbor_data: Dictionary = rooms[neighbor]
		var neighbor_offsets: Dictionary = neighbor_data.get("door_offsets", {}) as Dictionary
		if not is_equal_approx(
			float(offsets[keys[index]]),
			float(neighbor_offsets.get(opposite_keys[index], 99.0))
		):
			failures.append("Hai đầu cửa không dùng cùng offset: " + str(position))
