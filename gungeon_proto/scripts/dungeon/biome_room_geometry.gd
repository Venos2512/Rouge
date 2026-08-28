class_name BiomeRoomGeometry
extends RefCounted


const BASE_ROOM_SIZE := Vector2(768.0, 432.0)


static func build(
	layout: Resource,
	room_data: Dictionary,
	room_rect: Rect2
) -> Dictionary:
	var result: Dictionary = {
		"walls": _duplicate_array(layout.get("walls")),
		"props": _duplicate_array(layout.get("props")),
		"explosive_barrels": _duplicate_array(layout.get("explosive_barrels")),
		"spike_traps": _duplicate_array(layout.get("spike_traps")),
		"saw_traps": _duplicate_array(layout.get("saw_traps")),
	}

	_scale_base_layout(result, room_rect.size)
	var room_type: String = str(room_data.get("type", "combat"))
	if room_type != "combat" and room_type != "elite":
		return result

	match str(room_data.get("terrain", "stone")):
		"moss":
			_add_moss_geometry(result, room_rect)
		"ice":
			_add_ice_geometry(result, room_rect)
		"lava":
			_add_lava_geometry(result, room_rect)
		"void":
			_add_void_geometry(result, room_rect)

	return result


static func _duplicate_array(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	return (value as Array).duplicate(true)


static func _scale_base_layout(result: Dictionary, room_size: Vector2) -> void:
	var scale_value := Vector2(
		clampf(room_size.x / BASE_ROOM_SIZE.x, 1.0, 1.55),
		clampf(room_size.y / BASE_ROOM_SIZE.y, 1.0, 1.55)
	)

	for key: String in ["walls", "props", "explosive_barrels"]:
		for entry_value: Variant in result[key]:
			if typeof(entry_value) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = entry_value
			entry["position"] = (entry.get("position", Vector2.ZERO) as Vector2) * scale_value

	for index: int in range((result["spike_traps"] as Array).size()):
		var spike: Vector2 = (result["spike_traps"] as Array)[index] as Vector2
		(result["spike_traps"] as Array)[index] = spike * scale_value

	for saw_value: Variant in result["saw_traps"]:
		if typeof(saw_value) != TYPE_DICTIONARY:
			continue
		var saw: Dictionary = saw_value
		saw["from"] = (saw.get("from", Vector2.ZERO) as Vector2) * scale_value
		saw["to"] = (saw.get("to", Vector2.ZERO) as Vector2) * scale_value


static func _add_moss_geometry(result: Dictionary, room_rect: Rect2) -> void:
	var half: Vector2 = room_rect.size * 0.5
	var props: Array = result["props"]
	for index: int in range(4):
		var x_sign: float = -1.0 if index % 2 == 0 else 1.0
		var y_sign: float = -1.0 if index < 2 else 1.0
		props.append({
			"position": Vector2(half.x * 0.30 * x_sign, half.y * 0.34 * y_sign),
			"type": "pillar" if index < 2 else "pot",
			"id": "biome_moss_%d" % index,
		})


static func _add_ice_geometry(result: Dictionary, room_rect: Rect2) -> void:
	var half: Vector2 = room_rect.size * 0.5
	var walls: Array = result["walls"]
	walls.append({"position": Vector2(-half.x * 0.24, 0.0), "size": Vector2(26.0, half.y * 0.72)})
	walls.append({"position": Vector2(half.x * 0.24, 0.0), "size": Vector2(26.0, half.y * 0.72)})
	(result["saw_traps"] as Array).append({
		"from": Vector2(-half.x * 0.14, 0.0),
		"to": Vector2(half.x * 0.14, 0.0),
	})


static func _add_lava_geometry(result: Dictionary, room_rect: Rect2) -> void:
	var half: Vector2 = room_rect.size * 0.5
	var segment_width: float = half.x * 0.30
	var walls: Array = result["walls"]
	for y_sign: float in [-1.0, 1.0]:
		for x_sign: float in [-1.0, 1.0]:
			walls.append({
				"position": Vector2(half.x * 0.34 * x_sign, half.y * 0.22 * y_sign),
				"size": Vector2(segment_width, 28.0),
			})

	var spikes: Array = result["spike_traps"]
	spikes.append(Vector2(-half.x * 0.16, -half.y * 0.22))
	spikes.append(Vector2(half.x * 0.16, half.y * 0.22))


static func _add_void_geometry(result: Dictionary, room_rect: Rect2) -> void:
	var half: Vector2 = room_rect.size * 0.5
	var walls: Array = result["walls"]
	walls.append({"position": Vector2(-half.x * 0.27, -half.y * 0.20), "size": Vector2(32.0, half.y * 0.34)})
	walls.append({"position": Vector2(half.x * 0.14, half.y * 0.24), "size": Vector2(half.x * 0.30, 26.0)})
	walls.append({"position": Vector2(half.x * 0.31, -half.y * 0.08), "size": Vector2(28.0, half.y * 0.22)})

	var props: Array = result["props"]
	props.append({"position": Vector2(-half.x * 0.08, half.y * 0.12), "type": "pillar", "id": "biome_void_a"})
	props.append({"position": Vector2(half.x * 0.24, half.y * 0.31), "type": "pillar", "id": "biome_void_b"})
