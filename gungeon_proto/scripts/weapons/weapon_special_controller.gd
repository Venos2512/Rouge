class_name WeaponSpecialController
extends Node


@export var provider_catalog: Resource

var player: Node2D
var providers: Array[Node] = []
var provider_by_weapon_id: Dictionary = {}
var active_provider: Node
var active_weapon_id: String = ""


func _ready() -> void:
	_build_providers()
	call_deferred(
		"_find_player"
	)


func _process(
	_delta: float
) -> void:
	if not is_instance_valid(
		player
	):
		_find_player()

		if not is_instance_valid(
			player
		):
			return

	var weapon_id: String = _get_current_weapon_id()

	if weapon_id == active_weapon_id:
		return

	_activate_provider_for_weapon(
		weapon_id
	)


func _build_providers() -> void:
	if not is_instance_valid(
		provider_catalog
	):
		push_error(
			"WeaponSpecialController thiếu provider_catalog."
		)
		return

	var catalog_errors: Array = provider_catalog.call(
		"validate"
	)

	for error_value: Variant in catalog_errors:
		push_error(
			str(error_value)
		)

	if not catalog_errors.is_empty():
		return

	var provider_entries: Array = provider_catalog.get(
		"providers"
	)

	for provider_data: Resource in provider_entries:
		var provider_script: Script = provider_data.get(
			"provider_script"
		) as Script
		var provider: Node = provider_script.new() as Node

		if not is_instance_valid(
			provider
		):
			push_error(
				"Không thể tạo weapon special provider."
			)
			continue

		if not provider is WeaponSpecialProvider:
			push_error(
				"Special provider phải kế thừa WeaponSpecialProvider."
			)
			provider.free()
			continue

		provider.name = (
			"SpecialProvider"
			+ str(providers.size())
		)
		provider.set_process(
			false
		)
		add_child(
			provider
		)
		providers.append(
			provider
		)

		var weapon_ids: Array = provider_data.get(
			"weapon_ids"
		)
		var supported_ids: Array[String] = provider.call(
			"get_supported_weapon_ids"
		)
		var declared_ids: Array[String] = []

		for weapon_id_value: Variant in weapon_ids:
			declared_ids.append(
				str(weapon_id_value)
			)

		declared_ids.sort()
		supported_ids.sort()

		if declared_ids != supported_ids:
			push_error(
				"Catalog weapon_ids không khớp provider: "
				+ str(declared_ids)
				+ " != "
				+ str(supported_ids)
			)
			provider.queue_free()
			providers.erase(
				provider
			)
			continue

		for weapon_id_value: Variant in weapon_ids:
			provider_by_weapon_id[
				str(weapon_id_value)
			] = provider


func _find_player() -> void:
	player = get_tree().get_first_node_in_group(
		"player"
	) as Node2D

	if not is_instance_valid(
		player
	):
		return

	for provider: Node in providers:
		if provider.has_method(
			"setup"
		):
			provider.call(
				"setup",
				player
			)

	_activate_provider_for_weapon(
		_get_current_weapon_id()
	)


func _get_current_weapon_id() -> String:
	if not is_instance_valid(
		player
	):
		return ""

	var weapon_system: Object = player.get(
		"weapon_system"
	)

	if not is_instance_valid(
		weapon_system
	):
		return ""

	return str(
		weapon_system.get(
			"current_weapon"
		)
	)


func _activate_provider_for_weapon(
	weapon_id: String
) -> void:
	if is_instance_valid(
		active_provider
	):
		active_provider.call(
			"set_special_active",
			false
		)

	active_weapon_id = weapon_id
	active_provider = provider_by_weapon_id.get(
		weapon_id
	) as Node

	if not is_instance_valid(
		active_provider
	):
		return

	active_provider.call(
		"set_special_active",
		true
	)


func get_registered_weapon_ids() -> Array[String]:
	var result: Array[String] = []

	for weapon_id_value: Variant in provider_by_weapon_id.keys():
		result.append(
			str(weapon_id_value)
		)

	result.sort()
	return result
