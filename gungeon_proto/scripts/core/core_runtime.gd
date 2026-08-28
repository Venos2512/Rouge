class_name CoreRuntime
extends Node


var services: Dictionary = {}


func _ready() -> void:
	rebuild_service_cache()


func rebuild_service_cache() -> void:
	services.clear()

	for child: Node in get_children():
		services[child.name] = child


func get_service(
	service_name: String
) -> Node:
	var service_value: Variant = services.get(
		service_name
	)

	if is_instance_valid(
		service_value
	):
		return service_value as Node

	var service: Node = get_node_or_null(
		service_name
	)

	if is_instance_valid(
		service
	):
		services[service_name] = service

	return service
