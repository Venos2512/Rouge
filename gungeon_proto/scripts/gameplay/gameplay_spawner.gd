extends Node


const GunnerData = preload(
	"res://gungeon_proto/resources/enemies/gunner.tres"
)

const ChaserData = preload(
	"res://gungeon_proto/resources/enemies/chaser.tres"
)

const EliteData = preload(
	"res://gungeon_proto/resources/enemies/elite.tres"
)

const BomberData = preload(
	"res://gungeon_proto/resources/enemies/bomber.tres"
)

const GunnerEliteData = preload(
	"res://gungeon_proto/resources/enemies/gunner_elite.tres"
)

const ShieldData = preload(
	"res://gungeon_proto/resources/enemies/shield.tres"
)


@export_group("Actors")
@export var boss_scene: PackedScene

@export_group("Rewards")
@export var weapon_pickup_scene: PackedScene
@export var floor_exit_scene: PackedScene
@export var upgrade_chest_scene: PackedScene
@export var coin_pickup_scene: PackedScene
@export var shop_item_scene: PackedScene

@export_group("Feedback")
@export var room_fx_scene: PackedScene
@export var damage_number_scene: PackedScene

@export_group("Room Geometry")
@export var room_wall_scene: PackedScene
@export var spike_trap_scene: PackedScene
@export var saw_trap_scene: PackedScene

@export_group("Props")
@export var crate_scene: PackedScene
@export var pot_scene: PackedScene
@export var table_scene: PackedScene
@export var pillar_scene: PackedScene
@export var explosive_barrel_scene: PackedScene


func spawn_enemy_data(
	host: Node,
	pos: Vector2,
	enemy_data: Resource
) -> Node2D:
	if not is_instance_valid(
		host
	):
		return null

	if not is_instance_valid(
		enemy_data
	):
		return null

	var spawn_radius: float = float(
		enemy_data.get(
			"spawn_radius"
		)
	)

	var minimum_player_distance: float = float(
		enemy_data.get(
			"minimum_player_distance"
		)
	)

	var safe_position: Vector2 = pos

	if host.has_method(
		"find_safe_enemy_spawn_position"
	):
		safe_position = host.call(
			"find_safe_enemy_spawn_position",
			pos,
			spawn_radius,
			minimum_player_distance
		)

	var enemy_type: String = str(
		enemy_data.get(
			"enemy_type"
		)
	)

	var selected_scene: PackedScene = (
		enemy_data.get(
			"scene"
		) as PackedScene
	)

	var enemy: Node2D = _instantiate_node2d(
		selected_scene,
		"Enemy"
	)

	if not is_instance_valid(
		enemy
	):
		return null

	enemy.set_meta(
		"enemy_data",
		enemy_data
	)

	_set_if_property_exists(
		enemy,
		"enemy_type",
		str(
			enemy_data.get(
				"enemy_type"
			)
		)
	)

	host.add_child(
		enemy
	)

	enemy.global_position = (
		safe_position
	)

	return enemy


func spawn_enemy_type(
	host: Node,
	pos: Vector2,
	enemy_type: String,
	enemy_database: Resource = null
) -> Node2D:
	if is_instance_valid(
		enemy_database
	):
		if enemy_database.has_method(
			"get_by_id"
		):
			var enemy_data: Resource = (
				enemy_database.call(
					"get_by_id",
					enemy_type
				) as Resource
			)

			if is_instance_valid(
				enemy_data
			):
				return spawn_enemy_data(
					host,
					pos,
					enemy_data
				)

	push_error(
		"EnemyDatabase không chứa enemy_type: "
		+ enemy_type
	)
	return null


func spawn_normal_wave(
	host: Node,
	enemy_count: int,
	enemy_database: Resource
) -> void:
	if not is_instance_valid(
		host
	):
		return

	var spawn_points: Array[Vector2] = _build_room_spawn_points(host)

	spawn_points.shuffle()

	var amount: int = mini(
		enemy_count,
		spawn_points.size()
	)

	for i: int in range(
		amount
	):
		# Wave có ít nhất hai enemy luôn tạo một cặp Shield + Gunner.
		# Shield cần đồng minh tuyến sau để vai trò che chắn được đọc rõ.
		if amount >= 2 and i == 0:
			spawn_enemy_data(
				host,
				spawn_points[i],
				ShieldData
			)
			continue

		if amount >= 2 and i == 1:
			spawn_enemy_data(
				host,
				spawn_points[i],
				GunnerData
			)
			continue

		if randf() < 0.22:
			spawn_bomber(
				host,
				spawn_points[i]
			)

			continue

		var enemy_data: Resource = null

		if (
			is_instance_valid(
				enemy_database
			)
			and enemy_database.has_method(
				"pick_normal"
			)
		):
			enemy_data = (
				enemy_database.call(
					"pick_normal"
				) as Resource
			)

		if not is_instance_valid(
			enemy_data
		):
			enemy_data = GunnerData

		spawn_enemy_data(
			host,
			spawn_points[i],
			enemy_data
		)


func _build_room_spawn_points(host: Node) -> Array[Vector2]:
	var room_rect := Rect2(-384.0, -216.0, 768.0, 432.0)
	var rect_value: Variant = host.get("current_room_rect")
	if typeof(rect_value) == TYPE_RECT2:
		room_rect = rect_value as Rect2

	var safe_rect: Rect2 = room_rect.grow(-120.0)
	var half_width: float = safe_rect.size.x * 0.5
	var half_height: float = safe_rect.size.y * 0.5
	var points: Array[Vector2] = [
		Vector2(-half_width * 0.72, -half_height * 0.65),
		Vector2(0.0, -half_height * 0.78),
		Vector2(half_width * 0.72, -half_height * 0.65),
		Vector2(-half_width * 0.82, half_height * 0.45),
		Vector2(half_width * 0.82, half_height * 0.45),
		Vector2(0.0, half_height * 0.72),
		Vector2(-half_width * 0.42, 0.0),
		Vector2(half_width * 0.42, 0.0),
		Vector2(-half_width * 0.62, half_height * 0.78),
		Vector2(half_width * 0.62, half_height * 0.78),
	]
	points.shuffle()
	return points


func spawn_elite_wave(
	host: Node
) -> void:
	if not is_instance_valid(
		host
	):
		return

	spawn_enemy_data(
		host,
		Vector2(0, -60),
		EliteData
	)

	spawn_enemy_data(
		host,
		Vector2(-180, 85),
		ChaserData
	)

	spawn_gunner_elite(
		host,
		Vector2(180, 85)
	)


func spawn_bomber(
	host: Node,
	pos: Vector2
) -> Node2D:
	return spawn_enemy_data(
		host,
		pos,
		BomberData
	)


func spawn_gunner_elite(
	host: Node,
	pos: Vector2
) -> Node2D:
	return spawn_enemy_data(
		host,
		pos,
		GunnerEliteData
	)


func spawn_boss(
	host: Node,
	pos: Vector2,
	floor_number: int,
	boss_data: Resource
) -> Node2D:
	if not is_instance_valid(
		host
	):
		return null

	var spawn_radius: float = 32.0
	var minimum_player_distance: float = 125.0

	if is_instance_valid(
		boss_data
	):
		spawn_radius = float(
			boss_data.get(
				"spawn_radius"
			)
		)

		minimum_player_distance = float(
			boss_data.get(
				"minimum_player_distance"
			)
		)

	var safe_position: Vector2 = pos

	if host.has_method(
		"find_safe_enemy_spawn_position"
	):
		safe_position = host.call(
			"find_safe_enemy_spawn_position",
			pos,
			spawn_radius,
			minimum_player_distance
		)

	var boss: Node2D = _instantiate_node2d(
		boss_scene,
		"Boss"
	)

	if not is_instance_valid(
		boss
	):
		return null

	if is_instance_valid(
		boss_data
	):
		boss.set_meta(
			"boss_data",
			boss_data
		)

	boss.set_meta(
		"boss_floor",
		floor_number
	)

	_set_if_property_exists(
		boss,
		"boss_floor",
		floor_number
	)

	host.add_child(
		boss
	)

	boss.global_position = (
		safe_position
	)

	return boss


func spawn_damage_number(
	host: Node,
	pos: Vector2,
	amount: int,
	is_player_damage: bool
) -> Node2D:
	var number: Node2D = _instantiate_node2d(
		damage_number_scene,
		"DamageNumber"
	)

	if not is_instance_valid(
		number
	):
		return null

	_set_if_property_exists(
		number,
		"amount",
		amount
	)

	_set_if_property_exists(
		number,
		"is_player_damage",
		is_player_damage
	)

	host.add_child(
		number
	)

	number.global_position = pos

	return number


func spawn_weapon_pickup(
	host: Node,
	weapon_id: String,
	pos: Vector2
) -> Node2D:
	var pickup: Node2D = _instantiate_node2d(
		weapon_pickup_scene,
		"WeaponPickup"
	)

	if not is_instance_valid(
		pickup
	):
		return null

	_set_if_property_exists(
		pickup,
		"weapon_id",
		weapon_id
	)

	host.add_child(
		pickup
	)

	pickup.position = pos

	return pickup


func spawn_floor_exit(
	host: Node,
	pos: Vector2
) -> Node2D:
	var exit_node: Node2D = _instantiate_node2d(
		floor_exit_scene,
		"FloorExit"
	)

	if not is_instance_valid(
		exit_node
	):
		return null

	host.add_child(
		exit_node
	)

	exit_node.position = pos

	spawn_room_fx(
		host,
		pos,
		"portal"
	)

	return exit_node


func spawn_upgrade_chest(
	host: Node,
	pos: Vector2,
	source_type: String
) -> Node2D:
	var chest: Node2D = _instantiate_node2d(
		upgrade_chest_scene,
		"UpgradeChest"
	)

	if not is_instance_valid(
		chest
	):
		return null

	_set_if_property_exists(
		chest,
		"source_type",
		source_type
	)

	host.add_child(
		chest
	)

	chest.position = pos

	spawn_room_fx(
		host,
		pos,
		"reward"
	)

	return chest


func spawn_room_fx(
	host: Node,
	pos: Vector2,
	fx_type: String
) -> Node2D:
	var fx: Node2D = _instantiate_node2d(
		room_fx_scene,
		"RoomFX"
	)

	if not is_instance_valid(
		fx
	):
		return null

	_set_if_property_exists(
		fx,
		"fx_type",
		fx_type
	)

	host.add_child(
		fx
	)

	fx.global_position = pos

	return fx


func spawn_wall(
	host: Node,
	pos: Vector2,
	size: Vector2
) -> Node2D:
	var wall: Node2D = _instantiate_node2d(
		room_wall_scene,
		"RoomWall"
	)

	if not is_instance_valid(
		wall
	):
		return null

	_set_if_property_exists(
		wall,
		"wall_size",
		size
	)

	host.add_child(
		wall
	)

	wall.position = pos

	return wall


func spawn_spike_trap(
	host: Node,
	pos: Vector2
) -> Node2D:
	var trap: Node2D = _instantiate_node2d(
		spike_trap_scene,
		"SpikeTrap"
	)

	if not is_instance_valid(
		trap
	):
		return null

	host.add_child(
		trap
	)

	trap.position = pos

	return trap


func spawn_saw_trap(
	host: Node,
	from_pos: Vector2,
	to_pos: Vector2
) -> Node2D:
	var trap: Node2D = _instantiate_node2d(
		saw_trap_scene,
		"SawTrap"
	)

	if not is_instance_valid(
		trap
	):
		return null

	_set_if_property_exists(
		trap,
		"start_position",
		from_pos
	)

	_set_if_property_exists(
		trap,
		"end_position",
		to_pos
	)

	host.add_child(
		trap
	)

	return trap


func spawn_prop(
	host: Node,
	pos: Vector2,
	prop_type: String,
	prop_id: String
) -> Node2D:
	if _is_prop_broken(
		host,
		prop_id
	):
		return null

	var scene: PackedScene = (
		_get_prop_scene(
			prop_type
		)
	)

	var prop: Node2D = _instantiate_node2d(
		scene,
		"Prop"
	)

	if not is_instance_valid(
		prop
	):
		return null

	_set_if_property_exists(
		prop,
		"prop_type",
		prop_type
	)

	_set_if_property_exists(
		prop,
		"prop_id",
		prop_id
	)

	host.add_child(
		prop
	)

	prop.position = pos

	return prop


func spawn_explosive_barrel(
	host: Node,
	pos: Vector2,
	prop_id: String
) -> Node2D:
	if _is_prop_broken(
		host,
		prop_id
	):
		return null

	var barrel: Node2D = _instantiate_node2d(
		explosive_barrel_scene,
		"ExplosiveBarrel"
	)

	if not is_instance_valid(
		barrel
	):
		return null

	_set_if_property_exists(
		barrel,
		"prop_id",
		prop_id
	)

	host.add_child(
		barrel
	)

	barrel.position = pos

	return barrel


func spawn_currency_drop(
	host: Node,
	pos: Vector2,
	amount: int
) -> Node2D:
	var coin: Node2D = _instantiate_node2d(
		coin_pickup_scene,
		"CoinPickup"
	)

	if not is_instance_valid(
		coin
	):
		return null

	_set_if_property_exists(
		coin,
		"amount",
		amount
	)

	host.add_child(
		coin
	)

	coin.global_position = (
		pos
		+ Vector2(
			randf_range(
				-8.0,
				8.0
			),
			randf_range(
				-8.0,
				8.0
			)
		)
	)

	return coin


func spawn_shop_item(
	host: Node,
	upgrade_id: String,
	display_name: String,
	rarity: String,
	cost: int,
	pos: Vector2
) -> Node2D:
	var item: Node2D = _instantiate_node2d(
		shop_item_scene,
		"ShopItem"
	)

	if not is_instance_valid(
		item
	):
		return null

	_set_if_property_exists(
		item,
		"upgrade_id",
		upgrade_id
	)

	_set_if_property_exists(
		item,
		"display_name",
		display_name
	)

	_set_if_property_exists(
		item,
		"rarity",
		rarity
	)

	_set_if_property_exists(
		item,
		"cost",
		cost
	)

	host.add_child(
		item
	)

	item.position = pos

	return item


func _get_prop_scene(
	prop_type: String
) -> PackedScene:
	match prop_type:
		"pot":
			return pot_scene

		"table":
			return table_scene

		"pillar":
			return pillar_scene

		_:
			return crate_scene


func _is_prop_broken(
	host: Node,
	prop_id: String
) -> bool:
	if prop_id.is_empty():
		return false

	if not is_instance_valid(
		host
	):
		return false

	var rooms_value: Variant = host.get(
		"rooms"
	)

	if typeof(
		rooms_value
	) != TYPE_DICTIONARY:
		return false

	var rooms: Dictionary = rooms_value

	var current_room_value: Variant = host.get(
		"current_room"
	)

	if typeof(
		current_room_value
	) != TYPE_VECTOR2I:
		return false

	var current_room: Vector2i = (
		current_room_value
	)

	if not rooms.has(
		current_room
	):
		return false

	var data: Dictionary = rooms[
		current_room
	]

	var broken_value: Variant = data.get(
		"broken_props",
		[]
	)

	if typeof(
		broken_value
	) != TYPE_ARRAY:
		return false

	for broken_id_value: Variant in broken_value:
		if str(
			broken_id_value
		) == prop_id:
			return true

	return false


func _instantiate_node2d(
	scene: PackedScene,
	label: String
) -> Node2D:
	if not is_instance_valid(
		scene
	):
		push_error(
			"GameplaySpawner thiếu scene: "
			+ label
		)

		return null

	var instance: Node = scene.instantiate()

	if not (
		instance is Node2D
	):
		push_error(
			"GameplaySpawner scene không phải Node2D: "
			+ label
		)

		if is_instance_valid(
			instance
		):
			instance.queue_free()

		return null

	return instance as Node2D


func _set_if_property_exists(
	target: Object,
	property_name: String,
	value: Variant
) -> void:
	if target == null:
		return

	for property_info: Dictionary in target.get_property_list():
		if str(
			property_info.get(
				"name",
				""
			)
		) != property_name:
			continue

		target.set(
			property_name,
			value
		)

		return
