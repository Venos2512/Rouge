extends Node3D


const EnemyDatabaseResource = preload(
	"res://gungeon_proto/resources/enemies/enemy_database.tres"
)

const BossDefaultData = preload(
	"res://gungeon_proto/resources/enemies/boss_default.tres"
)

const MinimapTopRightAnchorScript = preload(
	"res://gungeon_proto/scripts/ui/minimap_top_right_anchor.gd"
)

const PauseRuntimeMenuScript = preload(
	"res://gungeon_proto/scenes/ui/pause_runtime_menu.tscn"
)

const MainMenuOverlayScene = preload(
	"res://gungeon_proto/scenes/ui/main_menu_overlay.tscn"
)

const GameplayRuntimeBootstrapScript = preload(
	"res://gungeon_proto/scripts/core/gameplay_runtime_bootstrap.gd"
)
const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)


const ROOM_RECT := Rect2(
	-384.0,
	-216.0,
	768.0,
	432.0
)

const RoomLayoutDatabaseResource = preload(
	"res://gungeon_proto/resources/dungeon/room_layout_database.tres"
)

const DungeonPatternMapper = preload(
	"res://gungeon_proto/scripts/dungeon/dungeon_pattern_mapper.gd"
)

const BiomeRoomGeometryBuilder = preload(
	"res://gungeon_proto/scripts/dungeon/biome_room_geometry.gd"
)

const LAYOUT_SPAWN_MAX_PER_FRAME: int = 4
const LAYOUT_SPAWN_TIME_BUDGET_USEC: int = 750

var floor_number: int = 1

var rooms: Dictionary = {}

var current_room := Vector2i.ZERO
var room_cleared: bool = true

var transition_cooldown: float = 0.0
var room_transition_in_progress: bool = false

var player: CharacterBody2D

var room_navigation: Node
var current_room_rect: Rect2 = ROOM_RECT
var layout_batch_started_usec: int = 0

func _ready() -> void:
	randomize()

	# Các service lõi giờ đã được setup trực tiếp
	# trong CoreRuntime scene.
	room_navigation = get_node_or_null(
		"CoreRuntime/RoomNavigation"
	)

	if not is_instance_valid(
		room_navigation
	):
		push_error(
			"CoreRuntime/RoomNavigation không tồn tại."
		)
		return

	room_navigation.call(
		"configure",
		ROOM_RECT
	)

	var encounter_director: Node = get_node_or_null(
		"CoreRuntime/EncounterDirector"
	)

	if not is_instance_valid(
		encounter_director
	):
		push_error(
			"CoreRuntime/EncounterDirector không tồn tại."
		)
		return

	encounter_director.call(
		"setup",
		self
	)

	var room_boundary_blocker: Node2D = (
		get_node_or_null(
			"CoreRuntime/RoomBoundaryBlocker"
		) as Node2D
	)

	if not is_instance_valid(
		room_boundary_blocker
	):
		push_error(
			"CoreRuntime/RoomBoundaryBlocker không tồn tại."
		)
		return

	room_boundary_blocker.call(
		"configure",
		ROOM_RECT
	)

	player = (
		get_node_or_null(
			"Player"
		) as CharacterBody2D
	)

	if not is_instance_valid(
		player
	):
		push_error(
			"Player scene không tồn tại trong main.tscn."
		)
		return

	player.set(
		"room_rect",
		ROOM_RECT.grow(-18.0)
	)

	player.position = Vector2.ZERO

	var combat_feedback_director: Node = (
		_get_combat_feedback_director()
	)

	if not is_instance_valid(
		combat_feedback_director
	):
		push_error(
			"CoreRuntime/CombatFeedbackDirector không tồn tại."
		)
		return

	combat_feedback_director.call(
		"setup",
		self,
		player
	)

	var presentation_director: Node = get_node_or_null(
		"CoreRuntime/DungeonPresentationDirector"
	)

	if not is_instance_valid(
		presentation_director
	):
		push_error(
			"CoreRuntime/DungeonPresentationDirector không tồn tại."
		)
		return

	presentation_director.call(
		"setup",
		self,
		player,
		_get_dungeon_hud()
	)

	var camera: Camera2D = (
		player.get_node_or_null(
			"Camera2D"
		) as Camera2D
	)

	if not is_instance_valid(
		camera
	):
		push_error(
			"Player/Camera2D không tồn tại."
		)
		return

	camera.enabled = true

	# Các hệ compatibility runtime còn lại.
	# Chúng không còn dựng các service gameplay lõi.
	var minimap_top_right_anchor: Node = (
		MinimapTopRightAnchorScript.new()
	)

	add_child(
		minimap_top_right_anchor
	)

	var main_menu_instance: Node = MainMenuOverlayScene.instantiate()

	add_child(
		main_menu_instance
	)

	var pause_menu_instance: Node = PauseRuntimeMenuScript.instantiate()

	pause_menu_instance.name = (
		"PauseRuntimeMenu"
	)

	add_child(
		pause_menu_instance
	)

	var core_runtime: Node = get_node_or_null(
		"CoreRuntime"
	)

	if not is_instance_valid(
		core_runtime
	):
		push_error(
			"CoreRuntime không tồn tại."
		)
		return

	var runtime_bootstrap: Node = (
		GameplayRuntimeBootstrapScript.new()
	)

	runtime_bootstrap.name = (
		"GameplayRuntimeBootstrap"
	)

	core_runtime.add_child(
		runtime_bootstrap
	)

	await runtime_bootstrap.call(
		"initialize",
		self
	)

	_start_floor()


func get_enemy_navigation_direction(
	from_position: Vector2,
	target_position: Vector2,
	agent_radius: float = 10.0
) -> Vector2:
	if not is_instance_valid(
		room_navigation
	):
		var direct: Vector2 = (
			target_position
			- from_position
		)

		if direct.length_squared() <= 1.0:
			return Vector2.ZERO

		return direct.normalized()

	var result = room_navigation.call(
		"get_move_direction",
		from_position,
		target_position,
		agent_radius
	)

	if typeof(result) == TYPE_VECTOR2:
		return result

	return Vector2.ZERO


func enemy_has_line_of_sight(
	from_position: Vector2,
	target_position: Vector2,
	radius: float = 6.0
) -> bool:
	if not is_instance_valid(
		room_navigation
	):
		return true

	return bool(
		room_navigation.call(
			"has_line_of_sight",
			from_position,
			target_position,
			radius
		)
	)


func is_enemy_position_walkable(
	position_value: Vector2,
	radius: float = 10.0
) -> bool:
	if not is_instance_valid(
		room_navigation
	):
		return true

	return bool(
		room_navigation.call(
			"is_position_walkable",
			position_value,
			radius
		)
	)


func get_enemy_tactical_position(
	from_position: Vector2,
	target_position: Vector2,
	desired_distance: float,
	radius: float = 10.0
) -> Vector2:
	if not is_instance_valid(
		room_navigation
	):
		return target_position

	var result = room_navigation.call(
		"find_tactical_position",
		from_position,
		target_position,
		desired_distance,
		radius
	)

	if typeof(result) == TYPE_VECTOR2:
		return result

	return target_position


func find_nearest_walkable_enemy_position(
	position_value: Vector2,
	radius: float = 10.0
) -> Vector2:
	if not is_instance_valid(
		room_navigation
	):
		return position_value

	var result = room_navigation.call(
		"find_nearest_walkable_position",
		position_value,
		radius
	)

	if typeof(result) == TYPE_VECTOR2:
		return result

	return position_value


func find_safe_enemy_spawn_position(
	desired_position: Vector2,
	radius: float = 12.0,
	minimum_player_distance: float = 65.0
) -> Vector2:
	var candidates: Array[Vector2] = [
		desired_position
	]

	var ring_distances := [
		30.0,
		55.0,
		85.0,
		115.0
	]

	for ring_value in ring_distances:
		var ring: float = float(
			ring_value
		)

		for i in range(12):
			var angle: float = (
				TAU
				* float(i)
				/ 12.0
			)

			candidates.append(
				desired_position
				+ Vector2(
					cos(angle),
					sin(angle)
				) * ring
			)

	for candidate in candidates:
		if not is_enemy_position_walkable(
			candidate,
			radius
		):
			continue

		if (
			is_instance_valid(player)
			and minimum_player_distance > 0.0
		):
			if candidate.distance_to(
				player.global_position
			) < minimum_player_distance:
				continue

		var occupied: bool = false

		for enemy_value in get_tree().get_nodes_in_group(
			"enemies"
		):
			if not is_instance_valid(enemy_value):
				continue

			if enemy_value.is_queued_for_deletion():
				continue

			var enemy: Node2D = (
				enemy_value as Node2D
			)

			if not is_instance_valid(enemy):
				continue

			if candidate.distance_to(
				enemy.global_position
			) < radius * 2.6:
				occupied = true
				break

		if not occupied:
			return candidate

	return find_nearest_walkable_enemy_position(
		desired_position,
		radius
	)


func spawn_damage_number(
	pos: Vector2,
	amount: int,
	is_player_damage: bool = false
) -> void:
	var feedback_director: Node = (
		_get_combat_feedback_director()
	)

	if not is_instance_valid(
		feedback_director
	):
		return

	feedback_director.call(
		"spawn_damage_number",
		pos,
		amount,
		is_player_damage
	)


func request_camera_shake(
	amount: float
) -> void:
	var feedback_director: Node = (
		_get_combat_feedback_director()
	)

	if not is_instance_valid(
		feedback_director
	):
		return

	feedback_director.call(
		"request_camera_shake",
		amount
	)


func request_hit_stop(
	duration: float,
	slow_scale: float = 0.16
) -> void:
	var feedback_director: Node = (
		_get_combat_feedback_director()
	)

	if not is_instance_valid(
		feedback_director
	):
		return

	feedback_director.call(
		"request_hit_stop",
		duration,
		slow_scale
	)


func _exit_tree() -> void:
	var feedback_director: Node = (
		_get_combat_feedback_director()
	)

	if is_instance_valid(
		feedback_director
	):
		feedback_director.call(
			"reset"
		)
		return

	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	var room_director: Node = (
		_get_room_director()
	)

	if not is_instance_valid(
		room_director
	):
		push_error(
			"CoreRuntime/RoomDirector không tồn tại."
		)
		return

	room_director.call(
		"process_room",
		self,
		delta
	)


func _get_dungeon_generator() -> Node:
	return _get_core_service(
		"DungeonGenerator"
	)


func _get_room_director() -> Node:
	return _get_core_service(
		"RoomDirector"
	)


func _start_floor() -> void:
	_clear_room_entities()

	var dungeon_generator: Node = (
		_get_dungeon_generator()
	)

	if not is_instance_valid(
		dungeon_generator
	):
		push_error(
			"CoreRuntime/DungeonGenerator không tồn tại."
		)
		return

	var result: Variant = (
		dungeon_generator.call(
			"generate",
			floor_number
		)
	)

	if typeof(
		result
	) != TYPE_DICTIONARY:
		push_error(
			"DungeonGenerator.generate() phải trả Dictionary."
		)
		return

	var generated_rooms: Dictionary = result

	if generated_rooms.is_empty():
		push_error(
			"DungeonGenerator tạo dungeon rỗng."
		)
		return

	generated_rooms = DungeonPatternMapper.remap(
		generated_rooms,
		floor_number
	)

	rooms = generated_rooms
	current_room = Vector2i.ZERO

	if not is_instance_valid(
		player
	):
		push_error(
			"Player không tồn tại khi bắt đầu floor."
		)
		return

	player.position = Vector2.ZERO

	_enter_room(
		Vector2i.ZERO,
		Vector2i.ZERO
	)

	print(
		"ENTER FLOOR ",
		floor_number
	)


func advance_floor() -> void:
	floor_number += 1

	_heal_player_between_floors()

	_start_floor()


func _heal_player_between_floors() -> void:
	GameAudio.play(self, "player_heal", 0.015)
	var max_health_value: int = int(
		player.get("max_health")
	)

	var health_value: int = int(
		player.get("health")
	)

	health_value = mini(
		max_health_value,
		health_value + 1
	)

	player.set(
		"health",
		health_value
	)


func _enter_room(
	room_position: Vector2i,
	entry_from: Vector2i
) -> void:
	GameAudio.play(self, "room_enter", 0.025)
	var room_director: Node = (
		_get_room_director()
	)

	if not is_instance_valid(
		room_director
	):
		push_error(
			"CoreRuntime/RoomDirector không tồn tại."
		)

		return

	room_director.call(
		"enter_room",
		self,
		room_position,
		entry_from
	)


func configure_room_geometry(data: Dictionary) -> void:
	var room_size: Vector2 = data.get("room_size", ROOM_RECT.size) as Vector2
	room_size.x = maxf(room_size.x, 640.0)
	room_size.y = maxf(room_size.y, 360.0)
	current_room_rect = Rect2(-room_size * 0.5, room_size)

	if is_instance_valid(room_navigation):
		room_navigation.call("configure", current_room_rect)

	var boundary: Node = _get_core_service("RoomBoundaryBlocker")
	if is_instance_valid(boundary):
		boundary.call("configure", current_room_rect)

	if is_instance_valid(player):
		player.set("room_rect", current_room_rect.grow(-18.0))


func _get_room_flow_director() -> Node:
	return _get_core_service(
		"RoomFlowDirector"
	)


func _get_gameplay_spawner() -> Node:
	return _get_core_service(
		"GameplaySpawner"
	)


func _get_combat_feedback_director() -> Node:
	return _get_core_service(
		"CombatFeedbackDirector"
	)


func _get_shop_director() -> Node:
	return _get_core_service(
		"ShopDirector"
	)


func _get_reward_director() -> Node:
	return _get_core_service(
		"RewardDirector"
	)


func _get_core_service(
	service_name: String
) -> Node:
	var core_runtime: Node = get_node_or_null(
		"CoreRuntime"
	)

	if not is_instance_valid(
		core_runtime
	):
		return null

	if core_runtime.has_method(
		"get_service"
	):
		return core_runtime.call(
			"get_service",
			service_name
		) as Node

	return core_runtime.get_node_or_null(
		service_name
	)


func _spawn_room_encounter(
	data: Dictionary
) -> void:
	var room_flow_director: Node = (
		_get_room_flow_director()
	)

	if not is_instance_valid(
		room_flow_director
	):
		push_error(
			"CoreRuntime/RoomFlowDirector không tồn tại."
		)

		return

	room_flow_director.call(
		"spawn_encounter",
		self,
		data
	)


func _spawn_wave(
	enemy_count: int
) -> void:
	GameAudio.play(self, "combat_room_lock", 0.015)
	GameAudio.play(self, "combat_wave_start", 0.015)
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		push_error(
			"GameplaySpawner không tồn tại."
		)
		return

	gameplay_spawner.call(
		"spawn_normal_wave",
		self,
		enemy_count,
		EnemyDatabaseResource
	)



func _spawn_elite_wave() -> void:
	GameAudio.play(self, "elite_spawn", 0.015)
	GameAudio.play(self, "combat_room_lock", 0.015)
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		push_error(
			"GameplaySpawner không tồn tại."
		)
		return

	gameplay_spawner.call(
		"spawn_elite_wave",
		self
	)


func spawn_director_enemy(
	pos: Vector2,
	enemy_type: String
) -> void:
	_spawn_enemy(
		pos,
		enemy_type
	)


func _spawn_enemy(
	pos: Vector2,
	enemy_type: String
) -> void:
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		push_error(
			"GameplaySpawner không tồn tại."
		)
		return

	gameplay_spawner.call(
		"spawn_enemy_type",
		self,
		pos,
		enemy_type,
		EnemyDatabaseResource
	)

func _spawn_enemy_data(
	pos: Vector2,
	enemy_data: Resource
) -> void:
	# EnemyData "gunner" giờ tiếp tục đi qua
	# GameplaySpawner như enemy thường.
	#
	# Gunner Elite chỉ spawn explicit bằng
	# enemy_type "gunner_elite".
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		push_error(
			"GameplaySpawner không tồn tại."
		)
		return

	gameplay_spawner.call(
		"spawn_enemy_data",
		self,
		pos,
		enemy_data
	)
func _spawn_boss() -> void:
	GameAudio.play(self, "boss_room_enter", 0.0)
	GameAudio.play(self, "boss_intro", 0.0)
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		push_error(
			"GameplaySpawner không tồn tại."
		)
		return

	gameplay_spawner.call(
		"spawn_boss",
		self,
		Vector2(
			0.0,
			-70.0
		),
		floor_number,
		BossDefaultData
	)
func _spawn_weapon_pickup(
	weapon_id: String,
	pos: Vector2
) -> void:
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		push_error(
			"GameplaySpawner không tồn tại."
		)
		return

	gameplay_spawner.call(
		"spawn_weapon_pickup",
		self,
		weapon_id,
		pos
	)
func _spawn_floor_exit(
	pos: Vector2 = Vector2.ZERO
) -> void:
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		push_error(
			"GameplaySpawner không tồn tại."
		)
		return

	gameplay_spawner.call(
		"spawn_floor_exit",
		self,
		pos
	)
func _spawn_upgrade_chest(
	pos: Vector2,
	source_type: String
) -> void:
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		push_error(
			"GameplaySpawner không tồn tại."
		)
		return

	gameplay_spawner.call(
		"spawn_upgrade_chest",
		self,
		pos,
		source_type
	)
func spawn_room_fx(
	pos: Vector2,
	fx_type: String
) -> void:
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		push_error(
			"GameplaySpawner không tồn tại."
		)
		return

	gameplay_spawner.call(
		"spawn_room_fx",
		self,
		pos,
		fx_type
	)
func _spawn_room_layout(
	data: Dictionary
) -> void:
	var room_type: String = str(
		data.get(
			"type",
			"combat"
		)
	)

	var layout_id: int = int(
		data.get(
			"layout_id",
			0
		)
	)

	var layout_resource: Resource = (
		RoomLayoutDatabaseResource.call(
			"get_layout",
			room_type,
			layout_id
		) as Resource
	)

	if not is_instance_valid(
		layout_resource
	):
		push_error(
			"Không tìm thấy RoomLayoutData: "
			+ room_type
			+ " / "
			+ str(layout_id)
		)
		return

	await _spawn_layout_resource(
		layout_resource,
		data
	)



func _spawn_layout_resource(
	layout: Resource,
	room_data: Dictionary
) -> void:
	if not is_instance_valid(
		layout
	):
		return

	var geometry: Dictionary = BiomeRoomGeometryBuilder.build(
		layout,
		room_data,
		current_room_rect
	)
	var spawned_this_frame: int = 0
	layout_batch_started_usec = Time.get_ticks_usec()

	var walls_value: Variant = geometry.get("walls", [])

	if typeof(walls_value) == TYPE_ARRAY:
		for wall_value: Variant in walls_value:
			if typeof(wall_value) != TYPE_DICTIONARY:
				continue

			var wall: Dictionary = wall_value
			var wall_position: Vector2 = wall.get("position", Vector2.ZERO) as Vector2
			var wall_size: Vector2 = wall.get("size", Vector2.ZERO) as Vector2
			if _is_in_door_approach(
				wall_position,
				maxf(wall_size.x, wall_size.y) * 0.5 + 44.0
			):
				continue

			_spawn_wall(
				wall_position,
				wall_size
			)
			spawned_this_frame = await _yield_layout_budget(spawned_this_frame)

	var props_value: Variant = geometry.get("props", [])

	if typeof(props_value) == TYPE_ARRAY:
		for prop_value: Variant in props_value:
			if typeof(prop_value) != TYPE_DICTIONARY:
				continue

			var prop: Dictionary = prop_value
			var prop_position: Vector2 = prop.get("position", Vector2.ZERO) as Vector2
			if _is_in_door_approach(prop_position, 62.0):
				continue

			_spawn_prop(
				prop_position,
				str(
					prop.get(
						"type",
						"crate"
					)
				),
				str(
					prop.get(
						"id",
						""
					)
				)
			)
			spawned_this_frame = await _yield_layout_budget(spawned_this_frame)

	var barrels_value: Variant = geometry.get("explosive_barrels", [])

	if typeof(barrels_value) == TYPE_ARRAY:
		for barrel_value: Variant in barrels_value:
			if typeof(barrel_value) != TYPE_DICTIONARY:
				continue

			var barrel: Dictionary = barrel_value
			var barrel_position: Vector2 = barrel.get("position", Vector2.ZERO) as Vector2
			if _is_in_door_approach(barrel_position, 68.0):
				continue

			_spawn_explosive_barrel(
				barrel_position,
				str(
					barrel.get(
						"id",
						""
					)
				)
			)
			spawned_this_frame = await _yield_layout_budget(spawned_this_frame)

	var spikes_value: Variant = geometry.get("spike_traps", [])

	if typeof(spikes_value) == TYPE_ARRAY:
		for spike_value: Variant in spikes_value:
			if typeof(spike_value) != TYPE_VECTOR2:
				continue

			if _is_in_door_approach(spike_value as Vector2, 54.0):
				continue

			_spawn_spike_trap(
				spike_value
			)
			spawned_this_frame = await _yield_layout_budget(spawned_this_frame)

	var saws_value: Variant = geometry.get("saw_traps", [])

	if typeof(saws_value) == TYPE_ARRAY:
		for saw_value: Variant in saws_value:
			if typeof(saw_value) != TYPE_DICTIONARY:
				continue

			var saw: Dictionary = saw_value
			var saw_from: Vector2 = saw.get("from", Vector2.ZERO) as Vector2
			var saw_to: Vector2 = saw.get("to", Vector2.ZERO) as Vector2
			if (
				_is_in_door_approach(saw_from, 64.0)
				or _is_in_door_approach(saw_to, 64.0)
			):
				continue

			_spawn_saw_trap(
				saw_from,
				saw_to
			)
			spawned_this_frame = await _yield_layout_budget(spawned_this_frame)


func _yield_layout_budget(spawned_this_frame: int) -> int:
	var next_count: int = spawned_this_frame + 1
	var batch_elapsed_usec: int = Time.get_ticks_usec() - layout_batch_started_usec
	if (
		next_count < LAYOUT_SPAWN_MAX_PER_FRAME
		and batch_elapsed_usec < LAYOUT_SPAWN_TIME_BUDGET_USEC
	):
		return next_count

	# Việc tạo scene kích hoạt _ready, collision và upload canvas item.
	# Nhường một frame sau mỗi batch giữ đỉnh frame time ổn định khi
	# layout được bổ sung thêm prop/trap trong các update sau.
	await get_tree().process_frame
	layout_batch_started_usec = Time.get_ticks_usec()
	return 0


func _is_in_door_approach(position_value: Vector2, padding: float) -> bool:
	if not rooms.has(current_room):
		return false

	var data: Dictionary = rooms[current_room]
	var offsets: Dictionary = data.get("door_offsets", {}) as Dictionary
	var half_size: Vector2 = current_room_rect.size * 0.5
	var approach_depth: float = 210.0

	for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if not rooms.has(current_room + direction):
			continue

		var key: String = "right"
		if direction == Vector2i.UP:
			key = "up"
		elif direction == Vector2i.DOWN:
			key = "down"
		elif direction == Vector2i.LEFT:
			key = "left"

		var normalized: float = float(offsets.get(key, 0.0))
		if direction.y != 0:
			var door_x: float = normalized * maxf(half_size.x - 96.0, 0.0)
			var near_edge_y: bool = position_value.y < -half_size.y + approach_depth if direction.y < 0 else position_value.y > half_size.y - approach_depth
			if near_edge_y and absf(position_value.x - door_x) <= padding:
				return true
		else:
			var door_y: float = normalized * maxf(half_size.y - 96.0, 0.0)
			var near_edge_x: bool = position_value.x < -half_size.x + approach_depth if direction.x < 0 else position_value.x > half_size.x - approach_depth
			if near_edge_x and absf(position_value.y - door_y) <= padding:
				return true

	return false


func _spawn_wall(
	pos: Vector2,
	size: Vector2
) -> void:
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		return

	gameplay_spawner.call(
		"spawn_wall",
		self,
		pos,
		size
	)


func _spawn_spike_trap(
	pos: Vector2
) -> void:
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		return

	gameplay_spawner.call(
		"spawn_spike_trap",
		self,
		pos
	)


func _spawn_saw_trap(
	from_pos: Vector2,
	to_pos: Vector2
) -> void:
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		return

	gameplay_spawner.call(
		"spawn_saw_trap",
		self,
		from_pos,
		to_pos
	)


func _spawn_explosive_barrel(
	pos: Vector2,
	prop_id: String
) -> void:
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		return

	gameplay_spawner.call(
		"spawn_explosive_barrel",
		self,
		pos,
		prop_id
	)


func _spawn_prop(
	pos: Vector2,
	prop_type: String,
	prop_id: String
) -> void:
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		return

	gameplay_spawner.call(
		"spawn_prop",
		self,
		pos,
		prop_type,
		prop_id
	)


func notify_prop_destroyed(
	prop_id: String
) -> void:
	if prop_id == "":
		return

	if not rooms.has(current_room):
		return

	var data: Dictionary = rooms[
		current_room
	]

	var broken: Array = []

	var broken_value = data.get(
		"broken_props",
		[]
	)

	if typeof(broken_value) == TYPE_ARRAY:
		broken = broken_value

	if not broken.has(prop_id):
		broken.append(prop_id)

	data["broken_props"] = broken

	rooms[current_room] = data


func spawn_currency_drop(
	pos: Vector2,
	amount: int
) -> void:
	var gameplay_spawner: Node = (
		_get_gameplay_spawner()
	)

	if not is_instance_valid(
		gameplay_spawner
	):
		return

	gameplay_spawner.call(
		"spawn_currency_drop",
		self,
		pos,
		amount
	)


func _spawn_shop() -> void:
	var shop_director: Node = (
		_get_shop_director()
	)

	if not is_instance_valid(
		shop_director
	):
		push_error(
			"CoreRuntime/ShopDirector không tồn tại."
		)
		return

	shop_director.call(
		"spawn_shop",
		self
	)


func _get_shop_price(
	rarity: String
) -> int:
	var shop_director: Node = (
		_get_shop_director()
	)

	if not is_instance_valid(
		shop_director
	):
		return 15

	return int(
		shop_director.call(
			"get_shop_price",
			rarity,
			floor_number
		)
	)


func try_purchase_upgrade(
	upgrade_id: String,
	cost: int
) -> bool:
	var shop_director: Node = (
		_get_shop_director()
	)

	if not is_instance_valid(
		shop_director
	):
		return false

	return bool(
		shop_director.call(
			"try_purchase_upgrade",
			self,
			upgrade_id,
			cost
		)
	)


func open_upgrade_choice(
	source_type: String = "normal"
) -> bool:
	var reward_director: Node = (
		_get_reward_director()
	)

	if not is_instance_valid(
		reward_director
	):
		return false

	return bool(reward_director.call(
		"open_upgrade_choice",
		self,
		source_type
	))


func notify_upgrade_chest_opened() -> void:
	var reward_director: Node = (
		_get_reward_director()
	)

	if not is_instance_valid(
		reward_director
	):
		return

	reward_director.call(
		"notify_upgrade_chest_opened",
		self
	)


func _spawn_room_rewards() -> void:
	GameAudio.play(self, "reward_spawn", 0.025)
	if not rooms.has(
		current_room
	):
		return

	var room_flow_director: Node = (
		_get_room_flow_director()
	)

	if not is_instance_valid(
		room_flow_director
	):
		push_error(
			"CoreRuntime/RoomFlowDirector không tồn tại."
		)

		return

	var data: Dictionary = rooms[
		current_room
	]

	room_flow_director.call(
		"spawn_rewards",
		self,
		data
	)


func _grant_elite_reward() -> void:
	var reward_director: Node = (
		_get_reward_director()
	)

	if not is_instance_valid(
		reward_director
	):
		return

	reward_director.call(
		"grant_elite_reward",
		self
	)


func _player_has_weapon(
	weapon_id: String
) -> bool:
	var reward_director: Node = (
		_get_reward_director()
	)

	if not is_instance_valid(
		reward_director
	):
		return false

	return bool(
		reward_director.call(
			"player_has_weapon",
			self,
			weapon_id
		)
	)


func notify_weapon_picked(
	_weapon_id: String
) -> void:
	var reward_director: Node = (
		_get_reward_director()
	)

	if not is_instance_valid(
		reward_director
	):
		return

	reward_director.call(
		"notify_weapon_picked",
		self
	)


func _complete_current_room() -> void:
	GameAudio.play(self, "combat_wave_clear", 0.02)
	GameAudio.play(self, "room_clear", 0.02)
	GameAudio.play(self, "room_unlock", 0.02)
	var room_director: Node = (
		_get_room_director()
	)

	if not is_instance_valid(
		room_director
	):
		return

	room_director.call(
		"complete_current_room",
		self
	)


func _get_alive_enemy_count() -> int:
	var room_director: Node = _get_room_director()

	if not is_instance_valid(
		room_director
	):
		return 0

	return int(
		room_director.call(
			"get_alive_enemy_count",
			get_tree()
		)
	)


func _get_dungeon_hud() -> Node:
	return get_node_or_null(
		"CoreRuntime/GameUI/DungeonHUD"
	)


func _check_room_transition() -> void:
	var room_director: Node = (
		_get_room_director()
	)

	if not is_instance_valid(
		room_director
	):
		return

	room_director.call(
		"check_room_transition",
		self
	)


func _try_move_room(
	direction: Vector2i
) -> bool:
	var room_director: Node = (
		_get_room_director()
	)

	if not is_instance_valid(
		room_director
	):
		return false

	return bool(
		room_director.call(
			"try_move_room",
			self,
			direction
		)
	)


func _place_player_at_entry(
	entry_from: Vector2i
) -> void:
	var room_director: Node = (
		_get_room_director()
	)

	if not is_instance_valid(
		room_director
	):
		return

	room_director.call(
		"place_player_at_entry",
		self,
		entry_from
	)


func _clear_room_entities() -> void:
	var room_director: Node = (
		_get_room_director()
	)

	if not is_instance_valid(
		room_director
	):
		push_error(
			"CoreRuntime/RoomDirector không tồn tại."
		)
		return

	room_director.call(
		"clear_room_entities",
		self
	)


func _update_ui() -> void:
	var dungeon_hud: Node = (
		_get_dungeon_hud()
	)

	if is_instance_valid(
		dungeon_hud
	):
		if dungeon_hud.has_method(
			"update_room_state"
		):
			dungeon_hud.call(
				"update_room_state",
				rooms,
				current_room,
				room_cleared,
				floor_number
			)

	refresh_room_visuals()


func refresh_room_visuals() -> void:
	var renderer: Node2D = (
		get_node_or_null(
			"CoreRuntime/RoomVisualRenderer"
		) as Node2D
	)

	if not is_instance_valid(
		renderer
	):
		return

	if renderer.has_method(
		"refresh"
	):
		renderer.call(
			"refresh",
			self
		)
