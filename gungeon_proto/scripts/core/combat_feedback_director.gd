class_name CombatFeedbackDirector
extends Node


var host: Node
var player: Node
var hit_stop_serial: int = 0


func setup(
	host_node: Node,
	player_node: Node
) -> void:
	host = host_node
	player = player_node


func spawn_damage_number(
	pos: Vector2,
	amount: int,
	is_player_damage: bool = false
) -> void:
	if not is_instance_valid(
		host
	):
		return

	var gameplay_spawner: Node = get_parent().get_node_or_null(
		"GameplaySpawner"
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		push_error(
			"CombatFeedbackDirector không tìm thấy GameplaySpawner."
		)
		return

	gameplay_spawner.call(
		"spawn_damage_number",
		host,
		pos,
		amount,
		is_player_damage
	)


func request_camera_shake(
	amount: float
) -> void:
	if not is_instance_valid(
		player
	):
		return

	if not player.has_method(
		"add_camera_shake"
	):
		return

	player.call(
		"add_camera_shake",
		amount
	)


func request_hit_stop(
	duration: float,
	slow_scale: float = 0.16
) -> void:
	hit_stop_serial += 1

	var serial: int = hit_stop_serial

	Engine.time_scale = minf(
		Engine.time_scale,
		slow_scale
	)

	await get_tree().create_timer(
		duration,
		true,
		false,
		true
	).timeout

	if serial == hit_stop_serial:
		Engine.time_scale = 1.0


func reset() -> void:
	hit_stop_serial += 1
	Engine.time_scale = 1.0


func _exit_tree() -> void:
	reset()
