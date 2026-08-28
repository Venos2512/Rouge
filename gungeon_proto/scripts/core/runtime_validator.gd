extends Node


const REQUIRED_NODES: Array[String] = [
	"GameInputBootstrap",
	"ControllerGameplayBridge",
	"WeaponSpecialController",
	"RoomNavigation",
	"RelicSystem",
	"EncounterDirector",
	"RoomFlowDirector",
	"DungeonGenerator",
	"RoomDirector",
	"RoomVisualRenderer",
	"GameplaySpawner",
	"ShopDirector",
	"RewardDirector",
	"CombatFeedbackDirector",
	"DungeonPresentationDirector",
	"RoomBoundaryBlocker",
	"ReloadProgressWorld",
]

const REQUIRED_SPAWNER_SCENES: Array[String] = [
	"boss_scene",
	"weapon_pickup_scene",
	"floor_exit_scene",
	"upgrade_chest_scene",
	"coin_pickup_scene",
	"shop_item_scene",
	"damage_number_scene",
]


func _ready() -> void:
	call_deferred(
		"_validate_runtime"
	)


func _validate_runtime() -> void:
	var parent_node: Node = get_parent()

	if not is_instance_valid(
		parent_node
	):
		return

	var missing: Array[String] = []

	for node_name: String in REQUIRED_NODES:
		if parent_node.get_node_or_null(
			node_name
		) != null:
			continue

		missing.append(
			node_name
		)

	if missing.is_empty():
		_validate_spawner_configuration(
			parent_node
		)
		return

	push_error(
		"CoreRuntime thiếu service: "
		+ ", ".join(
			missing
		)
	)


func _validate_spawner_configuration(
	parent_node: Node
) -> void:
	var special_controller: Node = parent_node.get_node_or_null(
		"WeaponSpecialController"
	)

	if (
		not is_instance_valid(
			special_controller
		)
		or special_controller.get(
			"provider_catalog"
		) == null
	):
		push_error(
			"WeaponSpecialController thiếu provider_catalog."
		)
		return

	var spawner: Node = parent_node.get_node_or_null(
		"GameplaySpawner"
	)

	if not is_instance_valid(
		spawner
	):
		return

	var missing_scenes: Array[String] = []

	for property_name: String in REQUIRED_SPAWNER_SCENES:
		if spawner.get(
			property_name
		) != null:
			continue

		missing_scenes.append(
			property_name
		)

	if not missing_scenes.is_empty():
		push_error(
			"GameplaySpawner thiếu scene bắt buộc: "
			+ ", ".join(
				missing_scenes
			)
		)
		return

	print(
		"CoreRuntime OK — ",
		REQUIRED_NODES.size(),
		" services; spawn configuration OK."
	)
