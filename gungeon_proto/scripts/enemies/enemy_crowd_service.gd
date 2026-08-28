extends Node


const UPDATE_INTERVAL: float = 0.08
const CELL_SIZE: float = 64.0

var update_timer: float = 0.0

var player: Node2D = null

var spatial_cells: Dictionary = {}


func _ready() -> void:
	add_to_group(
		"enemy_crowd_service"
	)

	_refresh_cache()


func _process(
	delta: float
) -> void:
	update_timer -= delta

	if update_timer > 0.0:
		return

	update_timer = UPDATE_INTERVAL

	_refresh_cache()


func _refresh_cache() -> void:
	if not is_instance_valid(
		player
	):
		player = (
			get_tree().get_first_node_in_group(
				"player"
			) as Node2D
		)

	spatial_cells.clear()

	var enemies: Array[Node] = (
		get_tree().get_nodes_in_group(
			"enemies"
		)
	)

	for enemy_value: Node in enemies:
		if not is_instance_valid(
			enemy_value
		):
			continue

		if enemy_value.is_queued_for_deletion():
			continue

		var enemy: Node2D = (
			enemy_value as Node2D
		)

		if not is_instance_valid(
			enemy
		):
			continue

		var cell: Vector2i = (
			_world_to_cell(
				enemy.global_position
			)
		)

		if not spatial_cells.has(
			cell
		):
			spatial_cells[
				cell
			] = []

		var bucket: Array = spatial_cells[
			cell
		]

		bucket.append(
			enemy
		)


func get_player() -> Node2D:
	if is_instance_valid(
		player
	):
		return player

	player = (
		get_tree().get_first_node_in_group(
			"player"
		) as Node2D
	)

	return player


func get_enemies_near(
	position_value: Vector2,
	radius: float
) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var center_cell: Vector2i = _world_to_cell(
		position_value
	)
	var cell_radius: int = maxi(
		1,
		ceili(
			radius / CELL_SIZE
		)
	)
	var radius_squared: float = radius * radius

	for offset_y: int in range(
		-cell_radius,
		cell_radius + 1
	):
		for offset_x: int in range(
			-cell_radius,
			cell_radius + 1
		):
			var cell := Vector2i(
				center_cell.x + offset_x,
				center_cell.y + offset_y
			)

			if not spatial_cells.has(
				cell
			):
				continue

			var bucket: Array = spatial_cells[
				cell
			]

			for enemy_value: Variant in bucket:
				if not is_instance_valid(
					enemy_value
				):
					continue

				var enemy: Node2D = enemy_value as Node2D

				if not is_instance_valid(
					enemy
				):
					continue

				if enemy.is_queued_for_deletion():
					continue

				if position_value.distance_squared_to(
					enemy.global_position
				) > radius_squared:
					continue

				result.append(
					enemy
				)

	return result


func get_separation(
	enemy: Node2D,
	radius: float = 30.0
) -> Vector2:
	if not is_instance_valid(
		enemy
	):
		return Vector2.ZERO

	var center_cell: Vector2i = (
		_world_to_cell(
			enemy.global_position
		)
	)

	var result := Vector2.ZERO

	var radius_squared: float = (
		radius * radius
	)

	for offset_y: int in range(
		-1,
		2
	):
		for offset_x: int in range(
			-1,
			2
		):
			var cell := Vector2i(
				center_cell.x + offset_x,
				center_cell.y + offset_y
			)

			if not spatial_cells.has(
				cell
			):
				continue

			var bucket: Array = spatial_cells[
				cell
			]

			for other_value: Variant in bucket:
				if not is_instance_valid(
					other_value
				):
					continue

				var other: Node2D = (
					other_value as Node2D
				)

				if not is_instance_valid(
					other
				):
					continue

				if other == enemy:
					continue

				if other.is_queued_for_deletion():
					continue

				var away: Vector2 = (
					enemy.global_position
					- other.global_position
				)

				var distance_squared: float = (
					away.length_squared()
				)

				if distance_squared <= 0.001:
					# Hai bot trùng đúng tâm vẫn phải có hướng tách nhau.
					# instance_id tạo hướng ổn định, không rung ngẫu nhiên mỗi frame.
					var separation_sign: float = (
						1.0
						if enemy.get_instance_id() > other.get_instance_id()
						else -1.0
					)
					result += Vector2(
						separation_sign,
						separation_sign * 0.5
					).normalized()
					continue

				if distance_squared > radius_squared:
					continue

				var distance: float = sqrt(
					distance_squared
				)

				result += (
					away
					/ distance
					* (
						1.0
						- distance
						/ radius
					)
				)

	return result


func _world_to_cell(
	position_value: Vector2
) -> Vector2i:
	return Vector2i(
		floori(
			position_value.x
			/ CELL_SIZE
		),
		floori(
			position_value.y
			/ CELL_SIZE
		)
	)
