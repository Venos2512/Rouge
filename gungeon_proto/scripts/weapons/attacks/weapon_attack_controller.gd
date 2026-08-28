class_name WeaponAttackController
extends Node


var providers: Dictionary = {}


func tick(
	delta: float
) -> void:
	for provider_value: Variant in providers.values():
		if (
			typeof(provider_value) != TYPE_OBJECT
			or not is_instance_valid(provider_value)
		):
			continue

		var provider: Node = provider_value as Node
		provider.call(
			"tick",
			delta
		)


func attack_current(
	player: Node2D,
	weapon_system: Node,
	aim_direction: Vector2,
	god_mode: bool
) -> Dictionary:
	if not is_instance_valid(
		weapon_system
	):
		return {"performed": false}

	if (
		not god_mode
		and not bool(weapon_system.call("can_fire"))
	):
		if int(weapon_system.call("get_ammo_in_mag")) <= 0:
			weapon_system.call("start_reload")

		return {"performed": false}

	var weapon: Dictionary = weapon_system.call(
		"get_current_weapon"
	)
	var provider_script: Script = weapon.get(
		"attack_provider"
	) as Script

	if provider_script == null:
		push_error(
			"Weapon thiếu attack_provider: "
			+ str(weapon.get("id", "unknown"))
		)
		return {"performed": false}

	var provider: Node = _get_or_create_provider(
		provider_script,
		str(weapon.get("id", ""))
	)

	if not is_instance_valid(
		provider
	):
		return {"performed": false}

	return provider.call(
		"perform_attack",
		player,
		weapon,
		aim_direction,
		weapon_system,
		god_mode
	)


func draw_current(
	player: Node2D,
	weapon_system: Node,
	aim_direction: Vector2
) -> void:
	if not is_instance_valid(weapon_system):
		return

	var weapon: Dictionary = weapon_system.call(
		"get_current_weapon"
	)
	var provider_script: Script = weapon.get(
		"attack_provider"
	) as Script

	if provider_script == null:
		return

	var provider: Node = _get_or_create_provider(
		provider_script,
		str(weapon.get("id", ""))
	)

	if is_instance_valid(provider):
		provider.call(
			"draw_held_weapon",
			player,
			weapon,
			aim_direction
		)


func _get_or_create_provider(
	provider_script: Script,
	weapon_id: String
) -> Node:
	var provider_key: String = weapon_id

	if provider_key.is_empty():
		provider_key = provider_script.resource_path

	if providers.has(
		provider_key
	):
		var existing_value: Variant = providers[provider_key]

		if (
			typeof(existing_value) == TYPE_OBJECT
			and is_instance_valid(existing_value)
		):
			var existing: Node = existing_value as Node
			return existing

		providers.erase(provider_key)

	var provider: Node = provider_script.new() as Node

	if not provider is WeaponAttackProvider:
		push_error(
			"attack_provider phải kế thừa WeaponAttackProvider."
		)
		provider.free()
		return null

	provider.name = "AttackProvider" + str(providers.size())
	add_child(
		provider
	)
	providers[provider_key] = provider
	return provider
