class_name DungeonPresentationDirector
extends Node


const REFRESH_INTERVAL: float = 0.1


var host: Node
var player: Node
var dungeon_hud: Node
var refresh_timer: float = 0.0

var last_gold: int = -1
var last_boss_instance_id: int = -1
var last_boss_health: int = -1
var last_boss_max_health: int = -1
var last_boss_floor: int = -1


func setup(
	host_node: Node,
	player_node: Node,
	hud_node: Node
) -> void:
	host = host_node
	player = player_node
	dungeon_hud = hud_node
	refresh_timer = 0.0
	_refresh_presentation()


func _process(
	delta: float
) -> void:
	if not is_instance_valid(
		host
	):
		return

	refresh_timer -= delta

	if refresh_timer > 0.0:
		return

	refresh_timer = REFRESH_INTERVAL
	_refresh_presentation()


func _refresh_presentation() -> void:
	if not is_instance_valid(
		dungeon_hud
	):
		return

	_refresh_gold()
	_refresh_boss()


func _refresh_gold() -> void:
	var gold: int = 0

	if (
		is_instance_valid(
			player
		)
		and player.has_method(
			"get_gold"
		)
	):
		gold = int(
			player.call(
				"get_gold"
			)
		)

	if gold == last_gold:
		return

	last_gold = gold

	if dungeon_hud.has_method(
		"update_gold_value"
	):
		dungeon_hud.call(
			"update_gold_value",
			gold
		)


func _refresh_boss() -> void:
	var boss: Node = get_tree().get_first_node_in_group(
		"boss"
	)

	var floor_number: int = int(
		host.get(
			"floor_number"
		)
	)

	if not is_instance_valid(
		boss
	):
		if last_boss_instance_id == 0:
			return

		last_boss_instance_id = 0
		last_boss_health = -1
		last_boss_max_health = -1
		last_boss_floor = floor_number

		_update_boss_hud(
			null,
			floor_number
		)
		return

	var instance_id: int = boss.get_instance_id()
	var health: int = int(
		boss.get(
			"health"
		)
	)
	var max_health: int = int(
		boss.get(
			"max_health"
		)
	)

	if (
		instance_id == last_boss_instance_id
		and health == last_boss_health
		and max_health == last_boss_max_health
		and floor_number == last_boss_floor
	):
		return

	last_boss_instance_id = instance_id
	last_boss_health = health
	last_boss_max_health = max_health
	last_boss_floor = floor_number

	_update_boss_hud(
		boss,
		floor_number
	)


func _update_boss_hud(
	boss: Node,
	floor_number: int
) -> void:
	if not dungeon_hud.has_method(
		"update_boss_actor"
	):
		return

	dungeon_hud.call(
		"update_boss_actor",
		boss,
		floor_number
	)
