class_name EnemyDatabase
extends Resource


@export_group("Pools")
@export var normal_pool: Array[Resource] = []
@export var elite_pool: Array[Resource] = []


func pick_normal() -> Resource:
	return _pick_weighted(
		normal_pool
	)


func pick_elite() -> Resource:
	return _pick_weighted(
		elite_pool
	)


func get_by_id(
	enemy_id: String
) -> Resource:
	for resource: Resource in normal_pool:
		if _resource_matches_id(
			resource,
			enemy_id
		):
			return resource

	for resource: Resource in elite_pool:
		if _resource_matches_id(
			resource,
			enemy_id
		):
			return resource

	return null


func _resource_matches_id(
	resource: Resource,
	enemy_id: String
) -> bool:
	if resource == null:
		return false

	var resource_id: String = str(
		resource.get(
			"id"
		)
	)

	var runtime_type: String = str(
		resource.get(
			"enemy_type"
		)
	)

	return (
		resource_id == enemy_id
		or runtime_type == enemy_id
	)


func _pick_weighted(
	pool: Array[Resource]
) -> Resource:
	if pool.is_empty():
		return null

	var valid_resources: Array[Resource] = []
	var total_weight: float = 0.0

	for resource: Resource in pool:
		if resource == null:
			continue

		var weight: float = maxf(
			0.0,
			float(
				resource.get(
					"spawn_weight"
				)
			)
		)

		if weight <= 0.0:
			continue

		valid_resources.append(
			resource
		)

		total_weight += weight

	if valid_resources.is_empty():
		return null

	if total_weight <= 0.0:
		return valid_resources.pick_random()

	var roll: float = randf_range(
		0.0,
		total_weight
	)

	var accumulated: float = 0.0

	for resource: Resource in valid_resources:
		accumulated += maxf(
			0.0,
			float(
				resource.get(
					"spawn_weight"
				)
			)
		)

		if roll <= accumulated:
			return resource

	return valid_resources[
		valid_resources.size() - 1
	]