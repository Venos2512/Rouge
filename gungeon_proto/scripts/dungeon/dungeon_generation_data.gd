class_name DungeonGenerationData
extends Resource


@export_group("Floor")
@export var base_room_count: int = 8
@export var max_bonus_rooms: int = 3
@export var generation_attempt_limit: int = 500

@export_group("Combat")
@export var base_enemy_count: int = 2
@export var enemy_count_per_distance: int = 1
@export var floor_difficulty_divisor: float = 2.0
@export var random_enemy_bonus_max: int = 1
@export var minimum_enemy_count: int = 2
@export var maximum_enemy_count: int = 7

@export_group("Layouts")
@export var combat_layout_count: int = 6

@export_group("Dungeon Variety")
@export var archetypes: Array[Resource] = []


func get_archetype(
	floor_number: int
) -> Resource:
	if archetypes.is_empty():
		return null

	var safe_floor: int = maxi(floor_number, 1)
	return archetypes[(safe_floor - 1) % archetypes.size()]


func get_target_room_count(
	floor_number: int
) -> int:
	return (
		base_room_count
		+ mini(
			maxi(
				floor_number - 1,
				0
			),
			max_bonus_rooms
		)
	)


func get_enemy_count(
	floor_number: int,
	distance: int
) -> int:
	var difficulty_bonus: int = int(
		float(floor_number)
		/ maxf(
			floor_difficulty_divisor,
			0.001
		)
	)

	var random_bonus: int = 0

	if random_enemy_bonus_max > 0:
		random_bonus = randi_range(
			0,
			random_enemy_bonus_max
		)

	return clampi(
		base_enemy_count
		+ distance * enemy_count_per_distance
		+ difficulty_bonus
		+ random_bonus,
		minimum_enemy_count,
		maximum_enemy_count
	)


func pick_combat_layout_id() -> int:
	if combat_layout_count <= 1:
		return 0

	return randi_range(
		0,
		combat_layout_count - 1
	)
