extends Node


@export_group("Data")
@export var room_rules: Resource
@export var shop_config: Resource


func get_rule(
	room_type: String
) -> Resource:
	if not is_instance_valid(
		room_rules
	):
		return null

	if not room_rules.has_method(
		"get_rule"
	):
		return null

	return (
		room_rules.call(
			"get_rule",
			room_type
		) as Resource
	)


func apply_room_defaults(
	data: Dictionary
) -> Dictionary:
	var result: Dictionary = data.duplicate(
		true
	)

	var room_type: String = str(
		result.get(
			"type",
			"combat"
		)
	)

	var rule: Resource = get_rule(
		room_type
	)

	if not is_instance_valid(
		rule
	):
		return result

	if bool(
		rule.get(
			"auto_cleared"
		)
	):
		result["cleared"] = true

	var enemy_count_override: int = int(
		rule.get(
			"enemy_count_override"
		)
	)

	if enemy_count_override >= 0:
		result["enemy_count"] = (
			enemy_count_override
		)

	return result


func spawn_encounter(
	dungeon: Node,
	data: Dictionary
) -> void:
	if not is_instance_valid(
		dungeon
	):
		return

	var room_type: String = str(
		data.get(
			"type",
			"combat"
		)
	)

	var rule: Resource = get_rule(
		room_type
	)

	if not is_instance_valid(
		rule
	):
		push_warning(
			"Không có RoomRule cho room type: %s"
			% room_type
		)

		return

	var encounter_mode: String = str(
		rule.get(
			"encounter_mode"
		)
	)

	match encounter_mode:
		"normal":
			if dungeon.has_method(
				"_spawn_wave"
			):
				dungeon.call(
					"_spawn_wave",
					int(
						data.get(
							"enemy_count",
							0
						)
					)
				)

		"elite":
			if dungeon.has_method(
				"_spawn_elite_wave"
			):
				dungeon.call(
					"_spawn_elite_wave"
				)

		"boss":
			if dungeon.has_method(
				"_spawn_boss"
			):
				dungeon.call(
					"_spawn_boss"
				)

		_:
			pass


func spawn_rewards(
	dungeon: Node,
	data: Dictionary
) -> void:
	if not is_instance_valid(
		dungeon
	):
		return

	var room_type: String = str(
		data.get(
			"type",
			"combat"
		)
	)

	var rule: Resource = get_rule(
		room_type
	)

	if not is_instance_valid(
		rule
	):
		return

	var reward_mode: String = str(
		rule.get(
			"reward_mode"
		)
	)

	match reward_mode:
		"start_loadout":
			_spawn_missing_weapons(
				dungeon,
				rule,
				false
			)

		"shop":
			if dungeon.has_method(
				"_spawn_shop"
			):
				dungeon.call(
					"_spawn_shop"
				)

		"chest":
			if not bool(
				data.get(
					"reward_claimed",
					false
				)
			):
				_spawn_rule_chest(
					dungeon,
					rule
				)

		"priority_weapon_or_chest":
			if bool(
				data.get(
					"reward_claimed",
					false
				)
			):
				return

			var spawned_weapon: bool = (
				_spawn_missing_weapons(
					dungeon,
					rule,
					true
				)
			)

			if not spawned_weapon:
				_spawn_rule_chest(
					dungeon,
					rule
				)

		"boss_chest_exit":
			if not bool(
				data.get(
					"reward_claimed",
					false
				)
			):
				_spawn_rule_chest(
					dungeon,
					rule
				)

			if bool(
				rule.get(
					"spawn_floor_exit"
				)
			):
				if dungeon.has_method(
					"_spawn_floor_exit"
				):
					dungeon.call(
						"_spawn_floor_exit",
						rule.get(
							"floor_exit_position"
						)
					)

		_:
			pass


func _spawn_missing_weapons(
	dungeon: Node,
	rule: Resource,
	stop_after_first: bool
) -> bool:
	var rewards_value: Variant = rule.get(
		"weapon_rewards"
	)

	if typeof(
		rewards_value
	) != TYPE_ARRAY:
		return false

	var rewards: Array = rewards_value

	for reward_value: Variant in rewards:
		if typeof(
			reward_value
		) != TYPE_DICTIONARY:
			continue

		var reward: Dictionary = reward_value

		var weapon_id: String = str(
			reward.get(
				"weapon_id",
				""
			)
		)

		if weapon_id.is_empty():
			continue

		var already_has_weapon: bool = false

		if dungeon.has_method(
			"_player_has_weapon"
		):
			already_has_weapon = bool(
				dungeon.call(
					"_player_has_weapon",
					weapon_id
				)
			)

		if already_has_weapon:
			continue

		if dungeon.has_method(
			"_spawn_weapon_pickup"
		):
			dungeon.call(
				"_spawn_weapon_pickup",
				weapon_id,
				reward.get(
					"position",
					Vector2.ZERO
				)
			)

			if stop_after_first:
				return true

	return false


func _spawn_rule_chest(
	dungeon: Node,
	rule: Resource
) -> void:
	if not dungeon.has_method(
		"_spawn_upgrade_chest"
	):
		return

	dungeon.call(
		"_spawn_upgrade_chest",
		rule.get(
			"chest_position"
		),
		str(
			rule.get(
				"chest_source"
			)
		)
	)


func get_shop_choice_count() -> int:
	if not is_instance_valid(
		shop_config
	):
		return 3

	return maxi(
		1,
		int(
			shop_config.get(
				"choice_count"
			)
		)
	)


func get_shop_positions() -> Array:
	if not is_instance_valid(
		shop_config
	):
		return [
			Vector2(-145.0, 20.0),
			Vector2(0.0, 20.0),
			Vector2(145.0, 20.0),
		]

	var positions_value: Variant = (
		shop_config.get(
			"offer_positions"
		)
	)

	if typeof(
		positions_value
	) != TYPE_ARRAY:
		return []

	return positions_value


func get_shop_price(
	rarity: String,
	floor_number: int
) -> int:
	if not is_instance_valid(
		shop_config
	):
		return 15

	if not shop_config.has_method(
		"get_price"
	):
		return 15

	return int(
		shop_config.call(
			"get_price",
			rarity,
			floor_number
		)
	)