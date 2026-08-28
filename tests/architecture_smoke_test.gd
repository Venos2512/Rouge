extends SceneTree


const ENEMY_DATABASE_PATH := (
	"res://gungeon_proto/resources/enemies/enemy_database.tres"
)
const CORE_RUNTIME_PATH := (
	"res://gungeon_proto/scenes/gameplay/core_runtime.tscn"
)
const SPECIAL_CATALOG_PATH := (
	"res://gungeon_proto/resources/weapons/weapon_special_catalog.tres"
)
const WEAPON_RESOURCE_PATHS: Array[String] = [
	"res://gungeon_proto/resources/weapons/pistol.tres",
	"res://gungeon_proto/resources/weapons/shotgun.tres",
	"res://gungeon_proto/resources/weapons/machine_gun.tres",
	"res://gungeon_proto/resources/weapons/sword.tres",
	"res://gungeon_proto/resources/weapons/spear.tres",
	"res://gungeon_proto/resources/weapons/hammer.tres",
]
const WEAPON_DATABASE_PATH := (
	"res://gungeon_proto/resources/weapons/weapon_database.tres"
)
const ENEMY_CROWD_SERVICE_SCRIPT_PATH := (
	"res://gungeon_proto/scripts/enemies/enemy_crowd_service.gd"
)
const REQUIRED_CORE_SERVICES: Array[String] = [
	"GameplaySpawner",
	"RoomDirector",
	"RoomFlowDirector",
	"EncounterDirector",
	"RewardDirector",
	"ShopDirector",
	"CombatFeedbackDirector",
	"DungeonPresentationDirector",
	"RuntimeValidator",
]
const REMOVED_SHIMS: Array[String] = [
	"res://gungeon_proto/scripts/core/game_input_v2.gd",
	"res://gungeon_proto/scripts/ui/weapon_stack_hud_v2.gd",
	"res://gungeon_proto/scripts/props/carryable_prop_v3.gd",
	"res://gungeon_proto/scripts/props/carryable_explosive_barrel_v3.gd",
	"res://gungeon_proto/scripts/debug/training/training_dummy_v2.gd",
	"res://gungeon_proto/scripts/debug/training/training_room_controller_v2.gd",
]

const SpecialRouter = preload(
	"res://gungeon_proto/scripts/weapons/specials/weapon_special_router.gd"
)


class FakeSpecialController:
	extends Node

	var parry_active: bool = false
	var parry_penalty_timer: float = 0.0
	var spear_charging: bool = false
	var hammer_charging: bool = false
	var calls: Array[String] = []

	func _start_parry() -> void:
		parry_active = true
		calls.append("start_parry")

	func _start_spear_charge() -> void:
		spear_charging = true
		calls.append("start_spear")

	func _update_spear_charge(
		_delta: float
	) -> void:
		calls.append("update_spear")

	func _release_spear() -> void:
		spear_charging = false
		calls.append("release_spear")

	func _start_hammer_charge() -> void:
		hammer_charging = true
		calls.append("start_hammer")

	func _update_hammer_charge(
		_delta: float
	) -> void:
		calls.append("update_hammer")

	func _release_hammer() -> void:
		hammer_charging = false
		calls.append("release_hammer")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []

	_validate_enemy_database(
		failures
	)
	_validate_enemy_instantiation(
		failures
	)
	_validate_core_runtime(
		failures
	)
	_validate_removed_shims(
		failures
	)
	_validate_special_router(
		failures
	)
	_validate_special_catalog(
		failures
	)
	_validate_weapon_attack_architecture(
		failures
	)
	_validate_primary_attack_execution(
		failures
	)
	_validate_freed_enemy_spatial_query(
		failures
	)

	if failures.is_empty():
		print(
			"ARCHITECTURE_SMOKE_TEST_OK"
		)
		quit(0)
		return

	for failure: String in failures:
		push_error(
			failure
		)

	quit(1)


func _validate_freed_enemy_spatial_query(
	failures: Array[String]
) -> void:
	var service_script: Script = load(
		ENEMY_CROWD_SERVICE_SCRIPT_PATH
	) as Script
	var service: Node = service_script.new() as Node
	root.add_child(service)

	var enemy := Node2D.new()
	root.add_child(enemy)
	var stale_reference: Variant = enemy
	enemy.free()
	service.set(
		"spatial_cells",
		{Vector2i.ZERO: [stale_reference]}
	)

	var nearby: Array = service.call(
		"get_enemies_near",
		Vector2.ZERO,
		32.0
	)

	if not nearby.is_empty():
		failures.append(
			"Spatial query trả về enemy đã bị giải phóng."
		)

	service.free()


func _validate_enemy_database(
	failures: Array[String]
) -> void:
	var database: Resource = load(
		ENEMY_DATABASE_PATH
	)

	if database == null:
		failures.append(
			"Không load được EnemyDatabase."
		)
		return

	var seen_ids: Dictionary = {}

	for pool_name: String in [
		"normal_pool",
		"elite_pool",
	]:
		var pool: Array = database.get(
			pool_name
		)

		for enemy_data: Resource in pool:
			if enemy_data == null:
				failures.append(
					pool_name + " chứa resource null."
				)
				continue

			var enemy_id: String = str(
				enemy_data.get(
					"id"
				)
			)

			if enemy_id.is_empty():
				failures.append(
					pool_name + " chứa enemy thiếu id."
				)
				continue

			if seen_ids.has(
				enemy_id
			):
				failures.append(
					"Enemy id bị trùng: " + enemy_id
				)

			seen_ids[enemy_id] = true

			if enemy_data.get(
				"scene"
			) == null:
				failures.append(
					"Enemy thiếu scene: " + enemy_id
				)


func _validate_core_runtime(
	failures: Array[String]
) -> void:
	var packed_scene: PackedScene = load(
		CORE_RUNTIME_PATH
	) as PackedScene

	if packed_scene == null:
		failures.append(
			"Không load được CoreRuntime scene."
		)
		return

	var runtime: Node = packed_scene.instantiate()

	if not runtime.has_method(
		"get_service"
	):
		failures.append(
			"CoreRuntime thiếu service registry API."
		)

	for service_name: String in REQUIRED_CORE_SERVICES:
		var service: Node = runtime.get_node_or_null(
			service_name
		)

		if service == null:
			failures.append(
				"CoreRuntime thiếu service: " + service_name
			)

	runtime.free()


func _validate_enemy_instantiation(
	failures: Array[String]
) -> void:
	var database: Resource = load(
		ENEMY_DATABASE_PATH
	)

	if database == null:
		return

	var enemy_resources: Array = []
	enemy_resources.append_array(
		database.get(
			"normal_pool"
		)
	)
	enemy_resources.append_array(
		database.get(
			"elite_pool"
		)
	)

	for count: int in [
		1,
		5,
		40,
	]:
		var instances: Array[Node] = []

		for index: int in range(
			count
		):
			var enemy_data: Resource = enemy_resources[
				index % enemy_resources.size()
			]
			var enemy_scene: PackedScene = enemy_data.get(
				"scene"
			) as PackedScene
			var enemy: Node = enemy_scene.instantiate()

			if not enemy is Node2D:
				failures.append(
					"Enemy scene không tạo Node2D: "
					+ str(enemy_data.get("id"))
				)

			instances.append(
				enemy
			)

		for enemy: Node in instances:
			enemy.free()


func _validate_removed_shims(
	failures: Array[String]
) -> void:
	for path: String in REMOVED_SHIMS:
		if ResourceLoader.exists(
			path
		):
			failures.append(
				"Compatibility shim đã quay lại: " + path
			)


func _validate_special_router(
	failures: Array[String]
) -> void:
	var controller := FakeSpecialController.new()

	SpecialRouter.process(
		controller,
		"sword",
		true,
		false,
		0.016
	)

	if controller.calls != [
		"start_parry",
	]:
		failures.append(
			"Sword special router sai contract."
		)

	controller.calls.clear()
	controller.parry_active = false

	SpecialRouter.process(
		controller,
		"spear",
		true,
		false,
		0.016
	)
	SpecialRouter.process(
		controller,
		"spear",
		false,
		true,
		0.016
	)

	if controller.calls != [
		"start_spear",
		"update_spear",
		"update_spear",
		"release_spear",
	]:
		failures.append(
			"Spear special router sai charge/release contract."
		)

	controller.calls.clear()

	SpecialRouter.process(
		controller,
		"hammer",
		true,
		false,
		0.016
	)
	SpecialRouter.process(
		controller,
		"hammer",
		false,
		true,
		0.016
	)

	if controller.calls != [
		"start_hammer",
		"update_hammer",
		"update_hammer",
		"release_hammer",
	]:
		failures.append(
			"Hammer special router sai charge/release contract."
		)

	controller.free()


func _validate_special_catalog(
	failures: Array[String]
) -> void:
	var catalog: Resource = load(
		SPECIAL_CATALOG_PATH
	)

	if catalog == null:
		failures.append(
			"Không load được WeaponSpecialCatalog."
		)
		return

	var catalog_errors: Array = catalog.call(
		"validate"
	)

	for error_value: Variant in catalog_errors:
		failures.append(
			str(error_value)
		)

	var controller_script: Script = load(
		"res://gungeon_proto/scripts/weapons/weapon_special_controller.gd"
	) as Script
	var controller: Node = controller_script.new() as Node
	controller.set(
		"provider_catalog",
		catalog
	)
	controller.call(
		"_build_providers"
	)

	var registered_ids: Array[String] = controller.call(
		"get_registered_weapon_ids"
	)

	if registered_ids != [
		"hammer",
		"spear",
		"sword",
	]:
		failures.append(
			"Special catalog đăng ký sai weapon IDs."
		)

	var providers: Array = controller.get(
		"providers"
	)

	if providers.size() != 3:
		failures.append(
			"Controller không tạo đúng ba special provider riêng."
		)
	else:
		var supported_sets: Array[String] = []

		for provider: Node in providers:
			supported_sets.append(
				str(
					provider.call(
						"get_supported_weapon_ids"
					)
				)
			)

		if supported_sets != [
			'["sword"]',
			'["spear"]',
			'["hammer"]',
		]:
			failures.append(
				"Ba provider không sở hữu weapon ID độc lập."
			)

	controller.free()


func _validate_weapon_attack_architecture(
	failures: Array[String]
) -> void:
	var database: Resource = load(
		WEAPON_DATABASE_PATH
	)

	if database == null:
		failures.append(
			"Không load được WeaponDatabase."
		)
	else:
		var database_errors: Array = database.call(
			"validate"
		)

		for error_value: Variant in database_errors:
			failures.append(
				str(error_value)
			)

		var database_weapons: Array = database.get(
			"weapons"
		)

		if database_weapons.size() != WEAPON_RESOURCE_PATHS.size():
			failures.append(
				"WeaponDatabase chưa chứa đủ weapon resources."
			)

	var seen_ids: Dictionary = {}

	for path: String in WEAPON_RESOURCE_PATHS:
		var weapon_data: Resource = load(
			path
		)

		if weapon_data == null:
			failures.append(
				"Không load được weapon resource: " + path
			)
			continue

		var weapon_id: String = str(
			weapon_data.get(
				"id"
			)
		)

		if weapon_id.is_empty():
			failures.append(
				"Weapon resource thiếu id: " + path
			)
		elif seen_ids.has(
			weapon_id
		):
			failures.append(
				"Weapon id bị trùng: " + weapon_id
			)

		seen_ids[weapon_id] = true

		var provider_script: Script = weapon_data.get(
			"attack_provider"
		) as Script

		if provider_script == null:
			failures.append(
				"Weapon thiếu attack_provider: " + weapon_id
			)
			continue

		var provider: Node = provider_script.new() as Node

		if not provider is WeaponAttackProvider:
			failures.append(
				"Weapon provider sai contract: " + weapon_id
			)

		provider.free()

	var player_scene: PackedScene = load(
		"res://gungeon_proto/scenes/actors/player.tscn"
	) as PackedScene
	var player: Node = player_scene.instantiate()

	if player.get_node_or_null(
		"Systems/WeaponAttackController"
	) == null:
		failures.append(
			"Player thiếu WeaponAttackController."
		)

	player.free()

	var controller_script: Script = load(
		"res://gungeon_proto/scripts/weapons/attacks/weapon_attack_controller.gd"
	) as Script
	var projectile_script: Script = load(
		"res://gungeon_proto/scripts/weapons/attacks/projectile_attack_provider.gd"
	) as Script
	var controller: Node = controller_script.new() as Node
	var provider_a: Node = controller.call(
		"_get_or_create_provider",
		projectile_script,
		"weapon_a"
	) as Node
	var provider_b: Node = controller.call(
		"_get_or_create_provider",
		projectile_script,
		"weapon_b"
	) as Node

	if provider_a == provider_b:
		failures.append(
			"Hai weapon ID đang dùng chung provider state instance."
		)

	controller.free()


func _validate_primary_attack_execution(
	failures: Array[String]
) -> void:
	var arena := Node2D.new()
	arena.name = "WeaponAttackTestArena"
	root.add_child(
		arena
	)
	current_scene = arena

	var player_scene: PackedScene = load(
		"res://gungeon_proto/scenes/actors/player.tscn"
	) as PackedScene
	var player: Node2D = player_scene.instantiate() as Node2D
	arena.add_child(
		player
	)

	var weapon_system: Node = player.get_node(
		"Systems/WeaponSystem"
	)
	var attack_controller: Node = player.get_node(
		"Systems/WeaponAttackController"
	)
	# SceneTree chưa phát _ready trong cùng tick khởi tạo test.
	weapon_system.call("_load_weapon_resources")
	var ranged_ids: Array[String] = [
		"pistol",
		"shotgun",
		"machine_gun",
	]
	var melee_ids: Array[String] = [
		"sword",
		"spear",
		"hammer",
	]

	for weapon_id: String in ranged_ids + melee_ids:
		weapon_system.call(
			"unlock_and_equip",
			weapon_id
		)

		var bullets_before: int = get_nodes_in_group(
			"player_bullets"
		).size()
		var result: Dictionary = attack_controller.call(
			"attack_current",
			player,
			weapon_system,
			Vector2.RIGHT,
			true
		)

		if not bool(result.get("performed", false)):
			failures.append(
				"Primary attack không chạy: " + weapon_id
			)

		var bullets_after: int = get_nodes_in_group(
			"player_bullets"
		).size()

		if (
			ranged_ids.has(weapon_id)
			and bullets_after <= bullets_before
		):
			failures.append(
				"Ranged provider không tạo projectile: " + weapon_id
			)

		if (
			melee_ids.has(weapon_id)
			and bullets_after != bullets_before
		):
			failures.append(
				"Melee provider tạo projectile ngoài ý muốn: " + weapon_id
			)

	for bullet: Node in get_nodes_in_group(
		"player_bullets"
	):
		if is_instance_valid(
			bullet
		):
			bullet.free()

	current_scene = null
	arena.free()
