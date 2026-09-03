extends Node3D


const WORLD_SCALE: float = 1.0
const VISUAL_UNIT_SCALE: float = 50.0
const ROOM_SIZE_2D := Vector2(768.0, 432.0)
const FLOOR_THICKNESS: float = 0.18 * VISUAL_UNIT_SCALE
const WALL_HEIGHT: float = 1.15 * VISUAL_UNIT_SCALE
const PROXY_SCAN_INTERVAL: float = 0.025
const CAMERA_HEIGHT: float = 13.5 * VISUAL_UNIT_SCALE
const CAMERA_DEPTH_OFFSET: float = 4.2 * VISUAL_UNIT_SCALE
const CAMERA_FOLLOW_SPEED: float = 11.0
const CAMERA_AIM_LOOKAHEAD_2D: float = 18.0
const CAMERA_NEAR: float = 2.0
const CAMERA_FAR: float = 5000.0
const ACTOR_VISUAL_FOLLOW_SPEED: float = 34.0
const DOOR_HALF_WIDTH_2D: float = 58.0
const CONTACT_SHADOW_ALPHA: float = 0.34
const ROOM_ACCENT_LIGHT_ENERGY: float = 0.42
const MAX_DYNAMIC_COMBAT_LIGHTS: int = 8
const LASER_BEAM_LENGTH: float = 12.4

const PLAYER_MODEL_PATH: String = "res://gungeon_proto/assets/models/pet/animal-cat.fbx"
const ENEMY_MODEL_PATHS: Dictionary = {
	"chaser": "res://gungeon_proto/assets/models/pet/animal-dog.fbx",
	"gunner": "res://gungeon_proto/assets/models/pet/animal-fox.fbx",
	"spread": "res://gungeon_proto/assets/models/pet/animal-bee.fbx",
	"elite": "res://gungeon_proto/assets/models/pet/animal-lion.fbx",
	"gunner_elite": "res://gungeon_proto/assets/models/pet/animal-monkey.fbx",
	"tactical_gunner": "res://gungeon_proto/assets/models/pet/animal-monkey.fbx",
	"shield": "res://gungeon_proto/assets/models/pet/animal-polar.fbx",
	"charger": "res://gungeon_proto/assets/models/pet/animal-cow.fbx",
	"suicide": "res://gungeon_proto/assets/models/pet/animal-crab.fbx",
	"suicide_bot": "res://gungeon_proto/assets/models/pet/animal-crab.fbx",
	"bomber": "res://gungeon_proto/assets/models/pet/animal-penguin.fbx",
	"boss": "res://gungeon_proto/assets/models/pet/animal-elephant.fbx",
}
const WEAPON_MODEL_PATHS: Dictionary = {
	"pistol": "res://gungeon_proto/assets/models/weapons/Blaster/blaster-a.fbx",
	"shotgun": "res://gungeon_proto/assets/models/weapons/Blaster/blaster-f.fbx",
	"machine_gun": "res://gungeon_proto/assets/models/weapons/Blaster/blaster-r.fbx",
	"laser_rifle": "res://gungeon_proto/assets/models/weapons/Blaster/blaster-n.fbx",
	"grenade_launcher": "res://gungeon_proto/assets/models/weapons/Blaster/blaster-j.fbx",
	"sword": "res://gungeon_proto/assets/models/weapons/Medieval/sword-a.fbx",
	"spear": "res://gungeon_proto/assets/models/weapons/Medieval/spear-a.fbx",
	"hammer": "res://gungeon_proto/assets/models/weapons/Medieval/hammer-a.fbx",
}

const MIRRORED_GROUPS: PackedStringArray = [
	"player",
	"enemies",
	"player_bullets",
	"player_projectiles",
	"enemy_bullets",
	"enemy_projectiles",
	"room_props",
	"room_pickups",
	"room_hazards",
	"room_fx",
	"melee_fx",
]

var proxy_root: Node3D
var room_root: Node3D
var camera_3d: Camera3D
var proxies: Dictionary = {}
var source_refs: Dictionary = {}
var property_cache: Dictionary = {}
var scan_timer: float = 0.0
var elapsed_time: float = 0.0
var door_meshes: Dictionary = {}
var room_geometry_signature: int = -1
var smoothed_camera_position: Vector3 = Vector3.ZERO
var camera_position_initialized: bool = false
var player_fill_light: OmniLight3D
var active_dynamic_combat_lights: int = 0


func _ready() -> void:
	name = "Planar3DPresenter"
	_create_environment()
	_create_room_geometry()
	_create_camera()

	proxy_root = Node3D.new()
	proxy_root.name = "GameplayProxies"
	add_child(proxy_root)

	call_deferred("_initial_sync")


func _process(delta: float) -> void:
	elapsed_time += delta
	scan_timer -= delta

	if scan_timer <= 0.0:
		scan_timer = PROXY_SCAN_INTERVAL
		_discover_sources()

	_sync_proxies(delta)
	_sync_room_geometry()
	_sync_camera(delta)
	_sync_doors()


func _initial_sync() -> void:
	_hide_legacy_world_visuals(get_tree().current_scene)
	_discover_sources()
	_sync_proxies(0.0, true)
	_sync_room_geometry(true)
	_sync_camera(0.0, true)
	_sync_doors()


func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("090d17")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("7286b1")
	environment.ambient_light_energy = 0.34
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_set_if_property_exists(environment, "fog_enabled", true)
	_set_if_property_exists(environment, "fog_light_color", Color("1a2033"))
	_set_if_property_exists(environment, "fog_light_energy", 0.72)
	_set_if_property_exists(environment, "fog_density", 0.012 / VISUAL_UNIT_SCALE)
	_set_if_property_exists(environment, "fog_sky_affect", 0.42)
	_set_if_property_exists(environment, "glow_enabled", true)
	_set_if_property_exists(environment, "glow_intensity", 0.82)
	_set_if_property_exists(environment, "glow_strength", 0.88)
	_set_if_property_exists(environment, "ssao_enabled", false)
	_set_if_property_exists(environment, "ssao_radius", 1.4 * VISUAL_UNIT_SCALE)
	_set_if_property_exists(environment, "ssao_intensity", 1.6)
	world_environment.environment = environment
	add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.light_color = Color("ffe6c4")
	key_light.light_energy = 1.55
	key_light.shadow_enabled = true
	key_light.shadow_blur = 0.0
	key_light.light_angular_distance = 0.0
	key_light.directional_shadow_max_distance = 18.0 * VISUAL_UNIT_SCALE
	key_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	key_light.directional_shadow_blend_splits = false
	key_light.directional_shadow_split_1 = 0.08
	key_light.directional_shadow_split_2 = 0.22
	key_light.directional_shadow_split_3 = 0.48
	key_light.directional_shadow_pancake_size = 2.0 * VISUAL_UNIT_SCALE
	key_light.shadow_bias = 1.0
	key_light.shadow_normal_bias = 4.0
	key_light.shadow_reverse_cull_face = true
	key_light.rotation_degrees = Vector3(-58.0, -32.0, 0.0)
	add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.light_color = Color("6f8fe8")
	fill_light.light_energy = 0.52
	fill_light.rotation_degrees = Vector3(-72.0, 145.0, 0.0)
	add_child(fill_light)

	var rim_light := DirectionalLight3D.new()
	rim_light.name = "RimLight"
	rim_light.light_color = Color("b78cff")
	rim_light.light_energy = 0.38
	rim_light.rotation_degrees = Vector3(-38.0, 118.0, 0.0)
	add_child(rim_light)

	player_fill_light = OmniLight3D.new()
	player_fill_light.name = "PlayerFillLight"
	player_fill_light.light_color = Color("72c9ff")
	player_fill_light.light_energy = 0.44
	player_fill_light.omni_range = 4.8 * VISUAL_UNIT_SCALE
	player_fill_light.shadow_enabled = false
	add_child(player_fill_light)


func _create_room_geometry() -> void:
	room_root = Node3D.new()
	room_root.name = "RoomGeometry3D"
	add_child(room_root)


func _sync_room_geometry(force: bool = false) -> void:
	if not is_instance_valid(room_root):
		return

	var dungeon: Node = get_tree().current_scene
	if dungeon == null:
		return

	var room_rect := Rect2(-ROOM_SIZE_2D * 0.5, ROOM_SIZE_2D)
	var rect_value: Variant = dungeon.get("current_room_rect")
	if typeof(rect_value) == TYPE_RECT2:
		room_rect = rect_value as Rect2

	var rooms_value: Variant = dungeon.get("rooms")
	var current_room_value: Variant = dungeon.get("current_room")
	var rooms: Dictionary = rooms_value as Dictionary if typeof(rooms_value) == TYPE_DICTIONARY else {}
	var current_room: Vector2i = current_room_value as Vector2i if typeof(current_room_value) == TYPE_VECTOR2I else Vector2i.ZERO
	var door_offsets: Dictionary = {}
	if rooms.has(current_room):
		var room_data: Dictionary = rooms[current_room]
		door_offsets = room_data.get("door_offsets", {}) as Dictionary

	var signature: int = hash([room_rect, current_room, door_offsets, rooms.keys()])
	if not force and signature == room_geometry_signature:
		return
	room_geometry_signature = signature

	for child in room_root.get_children():
		child.queue_free()
	door_meshes.clear()

	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(
		room_rect.size.x * WORLD_SCALE,
		FLOOR_THICKNESS,
		room_rect.size.y * WORLD_SCALE
	)
	var floor_instance := MeshInstance3D.new()
	floor_instance.name = "Floor"
	floor_instance.mesh = floor_mesh
	floor_instance.position.y = -FLOOR_THICKNESS * 0.5
	var floor_material := _make_material(Color("202a3b"), 1.0)
	floor_material.metallic = 0.0
	floor_material.metallic_specular = 0.18
	floor_instance.material_override = floor_material
	# The floor receives actor shadows but must not cast its own large,
	# low-frequency shadow into the directional shadow map. At this world
	# scale that produces diagonal shadow acne bands across the room.
	floor_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	room_root.add_child(floor_instance)

	var min_x: float = room_rect.position.x * WORLD_SCALE
	var max_x: float = room_rect.end.x * WORLD_SCALE
	var min_z: float = room_rect.position.y * WORLD_SCALE
	var max_z: float = room_rect.end.y * WORLD_SCALE
	var wall_thickness: float = 0.22 * VISUAL_UNIT_SCALE
	var door_half_width: float = DOOR_HALF_WIDTH_2D * WORLD_SCALE

	_build_horizontal_side(dungeon, Vector2i.UP, min_x, max_x, min_z, wall_thickness, door_half_width)
	_build_horizontal_side(dungeon, Vector2i.DOWN, min_x, max_x, max_z, wall_thickness, door_half_width)
	_build_vertical_side(dungeon, Vector2i.LEFT, min_z, max_z, min_x, wall_thickness, door_half_width)
	_build_vertical_side(dungeon, Vector2i.RIGHT, min_z, max_z, max_x, wall_thickness, door_half_width)

	var inset := Vector2(78.0, 68.0) * WORLD_SCALE
	for corner in [
		Vector3(min_x + inset.x, 0.12 * VISUAL_UNIT_SCALE, min_z + inset.y),
		Vector3(max_x - inset.x, 0.12 * VISUAL_UNIT_SCALE, min_z + inset.y),
		Vector3(min_x + inset.x, 0.12 * VISUAL_UNIT_SCALE, max_z - inset.y),
		Vector3(max_x - inset.x, 0.12 * VISUAL_UNIT_SCALE, max_z - inset.y),
	]:
		_add_room_accent_light(corner)


func _add_room_accent_light(light_position: Vector3) -> void:
	var accent := OmniLight3D.new()
	accent.name = "RoomAccentLight"
	accent.position = light_position + Vector3(0.0, 0.42 * VISUAL_UNIT_SCALE, 0.0)
	accent.light_color = Color("5bbfff")
	accent.light_energy = ROOM_ACCENT_LIGHT_ENERGY
	accent.omni_range = 3.1 * VISUAL_UNIT_SCALE
	accent.shadow_enabled = false
	room_root.add_child(accent)


func _build_horizontal_side(
	dungeon: Node,
	direction: Vector2i,
	min_x: float,
	max_x: float,
	z: float,
	wall_thickness: float,
	door_half_width: float
) -> void:
	if not _has_room_neighbor(dungeon, direction):
		_add_wall(room_root, Vector3((min_x + max_x) * 0.5, WALL_HEIGHT * 0.5, z), Vector3(max_x - min_x, WALL_HEIGHT, wall_thickness))
		return

	var door_center: float = _get_door_offset(dungeon, direction) * WORLD_SCALE
	_add_wall_segment_x(min_x, door_center - door_half_width, z, wall_thickness)
	_add_wall_segment_x(door_center + door_half_width, max_x, z, wall_thickness)
	door_meshes[direction] = _add_door(
		room_root,
		Vector3(door_center, WALL_HEIGHT * 0.42, z),
		Vector3(door_half_width * 2.0, WALL_HEIGHT * 0.84, wall_thickness * 1.2)
	)


func _build_vertical_side(
	dungeon: Node,
	direction: Vector2i,
	min_z: float,
	max_z: float,
	x: float,
	wall_thickness: float,
	door_half_width: float
) -> void:
	if not _has_room_neighbor(dungeon, direction):
		_add_wall(room_root, Vector3(x, WALL_HEIGHT * 0.5, (min_z + max_z) * 0.5), Vector3(wall_thickness, WALL_HEIGHT, max_z - min_z))
		return

	var door_center: float = _get_door_offset(dungeon, direction) * WORLD_SCALE
	_add_wall_segment_z(min_z, door_center - door_half_width, x, wall_thickness)
	_add_wall_segment_z(door_center + door_half_width, max_z, x, wall_thickness)
	door_meshes[direction] = _add_door(
		room_root,
		Vector3(x, WALL_HEIGHT * 0.42, door_center),
		Vector3(wall_thickness * 1.2, WALL_HEIGHT * 0.84, door_half_width * 2.0)
	)


func _add_wall_segment_x(from_x: float, to_x: float, z: float, thickness: float) -> void:
	if to_x - from_x <= 0.01:
		return
	_add_wall(room_root, Vector3((from_x + to_x) * 0.5, WALL_HEIGHT * 0.5, z), Vector3(to_x - from_x, WALL_HEIGHT, thickness))


func _add_wall_segment_z(from_z: float, to_z: float, x: float, thickness: float) -> void:
	if to_z - from_z <= 0.01:
		return
	_add_wall(room_root, Vector3(x, WALL_HEIGHT * 0.5, (from_z + to_z) * 0.5), Vector3(thickness, WALL_HEIGHT, to_z - from_z))


func _has_room_neighbor(dungeon: Node, direction: Vector2i) -> bool:
	var rooms_value: Variant = dungeon.get("rooms")
	var current_room_value: Variant = dungeon.get("current_room")
	if typeof(rooms_value) != TYPE_DICTIONARY or typeof(current_room_value) != TYPE_VECTOR2I:
		return false
	return (rooms_value as Dictionary).has((current_room_value as Vector2i) + direction)


func _get_door_offset(dungeon: Node, direction: Vector2i) -> float:
	var rooms: Dictionary = dungeon.get("rooms") as Dictionary
	var current_room: Vector2i = dungeon.get("current_room") as Vector2i
	var room_rect: Rect2 = dungeon.get("current_room_rect") as Rect2
	if not rooms.has(current_room):
		return 0.0

	var data: Dictionary = rooms[current_room]
	var offsets: Dictionary = data.get("door_offsets", {}) as Dictionary
	var key: String = "right"
	if direction == Vector2i.UP:
		key = "up"
	elif direction == Vector2i.DOWN:
		key = "down"
	elif direction == Vector2i.LEFT:
		key = "left"

	var normalized: float = float(offsets.get(key, 0.0))
	var usable_half_extent: float = (
		room_rect.size.x * 0.5 - 96.0
		if direction.y != 0
		else room_rect.size.y * 0.5 - 96.0
	)
	return normalized * maxf(usable_half_extent, 0.0)


func _add_wall(parent: Node3D, wall_position: Vector3, wall_size: Vector3) -> void:
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = wall_size
	var wall := MeshInstance3D.new()
	wall.mesh = wall_mesh
	wall.position = wall_position
	wall.material_override = _make_material(Color("536079"), 0.72)
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(wall)


func _add_door(
	parent: Node3D,
	door_position: Vector3,
	door_size: Vector3
) -> MeshInstance3D:
	var door_mesh := BoxMesh.new()
	door_mesh.size = door_size
	var door := MeshInstance3D.new()
	door.mesh = door_mesh
	door.position = door_position
	door.material_override = _make_material(Color("9d5361"), 0.52)
	parent.add_child(door)
	return door


func _create_camera() -> void:
	camera_3d = Camera3D.new()
	camera_3d.name = "TopDownCamera3D"
	camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera_3d.keep_aspect = Camera3D.KEEP_HEIGHT
	camera_3d.near = CAMERA_NEAR
	camera_3d.far = CAMERA_FAR
	camera_3d.position = Vector3(0.0, CAMERA_HEIGHT, CAMERA_DEPTH_OFFSET)
	add_child(camera_3d)
	camera_3d.look_at(Vector3.ZERO, Vector3.UP)
	_update_perspective_fov(get_viewport().get_visible_rect().size.y)
	camera_3d.current = true


func _update_perspective_fov(viewport_height: float) -> void:
	if not is_instance_valid(camera_3d) or viewport_height <= 1.0:
		return
	# Match the former one-world-unit-per-pixel framing at the focus plane while
	# retaining perspective depth and foreshortening.
	var focus_distance: float = Vector2(
		CAMERA_HEIGHT,
		CAMERA_DEPTH_OFFSET
	).length()
	var half_angle: float = atan(viewport_height * WORLD_SCALE / (2.0 * focus_distance))
	camera_3d.fov = clampf(rad_to_deg(half_angle * 2.0), 35.0, 75.0)


func _discover_sources() -> void:
	var discovered: Dictionary = {}

	for group_name in MIRRORED_GROUPS:
		for value in get_tree().get_nodes_in_group(group_name):
			if value is Node2D:
				var source := value as Node2D
				if not _should_mirror(source):
					continue
				var source_id: int = source.get_instance_id()
				discovered[source_id] = source
				if not proxies.has(source_id):
					_create_proxy(source)

	for source_id_value in proxies.keys():
		var source_id: int = int(source_id_value)
		if not discovered.has(source_id):
			_remove_proxy(source_id)

	_hide_legacy_world_visuals(get_tree().current_scene)


func _create_proxy(source: Node2D) -> void:
	var source_id: int = source.get_instance_id()
	var proxy := Node3D.new()
	proxy.name = "%s_3D" % source.name
	proxy.scale = Vector3.ONE * VISUAL_UNIT_SCALE

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	if _is_damage_number(source):
		_add_damage_number_label(proxy, source)
	else:
		mesh_instance.mesh = _make_mesh_for(source)
	if source.is_in_group("melee_fx"):
		mesh_instance.position.x = (
			_get_float_property(source, "attack_range", 70.0)
			* WORLD_SCALE
			/ VISUAL_UNIT_SCALE
			* 0.5
		)
	var base_color: Color = _color_for(source)
	if not _is_damage_number(source):
		var is_projectile: bool = (
			source.is_in_group("player_bullets")
			or source.is_in_group("player_projectiles")
			or source.is_in_group("enemy_bullets")
			or source.is_in_group("enemy_projectiles")
		)
		mesh_instance.material_override = (
			_make_projectile_material(base_color, 5.5)
			if is_projectile
			else _make_material(base_color, 0.55)
		)
		mesh_instance.set_meta("base_color", base_color)
		proxy.add_child(mesh_instance)
		if is_projectile:
			_add_projectile_halo(proxy, base_color)
	if source.is_in_group("player") or source.is_in_group("enemies"):
		if _add_actor_model(proxy, source):
			mesh_instance.visible = false
		_add_actor_lookdev(proxy, source)
	if _is_weapon_pickup(source):
		_add_floor_weapon_model(proxy, source)
		mesh_instance.visible = false
	if source.is_in_group("room_fx") or "bomb" in source.name.to_lower():
		_add_effect_light(proxy)
	if source.is_in_group("player"):
		_add_player_weapon_root(proxy)
	if source.is_in_group("enemies"):
		_add_enemy_health_bar(proxy)
		_add_enemy_indicator(proxy)
	proxy_root.add_child(proxy)

	proxies[source_id] = proxy
	source_refs[source_id] = weakref(source)


func _remove_proxy(source_id: int) -> void:
	var proxy_value: Variant = proxies.get(source_id)
	if is_instance_valid(proxy_value):
		(proxy_value as Node).queue_free()
	proxies.erase(source_id)
	source_refs.erase(source_id)
	property_cache.erase(source_id)


func _sync_proxies(delta: float, force_snap: bool = false) -> void:
	active_dynamic_combat_lights = 0
	for source_id_value in proxies.keys():
		var source_id: int = int(source_id_value)
		var source_ref_value: Variant = source_refs.get(source_id)
		if source_ref_value == null:
			_remove_proxy(source_id)
			continue

		var source_value: Variant = source_ref_value.get_ref()
		if not is_instance_valid(source_value):
			_remove_proxy(source_id)
			continue

		var source := source_value as Node2D
		var proxy := proxies[source_id] as Node3D
		var height: float = _height_for(source)
		var target_position := Vector3(
			source.global_position.x * WORLD_SCALE,
			(height * 0.5 + _vertical_offset_for(source)) * VISUAL_UNIT_SCALE,
			source.global_position.y * WORLD_SCALE
		)
		var should_snap: bool = force_snap or not proxy.has_meta("position_initialized")
		var knockback_velocity: Vector2 = _get_knockback_velocity(source)
		if knockback_velocity.length_squared() > 4.0:
			should_snap = true
		if (
			source.is_in_group("player_bullets")
			or source.is_in_group("player_projectiles")
			or source.is_in_group("enemy_bullets")
			or source.is_in_group("enemy_projectiles")
			or source.is_in_group("room_fx")
			or source.is_in_group("melee_fx")
		):
			should_snap = true
		if should_snap:
			proxy.position = target_position
			proxy.set_meta("position_initialized", true)
		else:
			var follow_weight: float = 1.0 - exp(-ACTOR_VISUAL_FOLLOW_SPEED * delta)
			proxy.position = proxy.position.lerp(target_position, follow_weight)

		var facing_rotation: float = -source.global_rotation
		if source.is_in_group("player") and _has_property(source, "aim_direction"):
			var aim_value: Variant = source.get("aim_direction")
			if typeof(aim_value) == TYPE_VECTOR2 and (aim_value as Vector2).length_squared() > 0.001:
				facing_rotation = -(aim_value as Vector2).angle()
		elif source.is_in_group("enemies"):
			var facing_direction: Vector2 = _enemy_facing_direction(source)
			if facing_direction.length_squared() > 0.001:
				facing_rotation = -facing_direction.angle()
		proxy.rotation.y = facing_rotation
		proxy.visible = source.is_inside_tree() and not source.is_queued_for_deletion()
		_update_proxy_feedback(source, proxy, delta)
		if source.is_in_group("player"):
			_update_player_weapon(source, proxy)
		elif source.is_in_group("enemies"):
			_update_enemy_presentation(source, proxy)
		_update_billboards(proxy)


func _sync_camera(delta: float, force_snap: bool = false) -> void:
	if not is_instance_valid(camera_3d):
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.y > 1.0:
		_update_perspective_fov(viewport_size.y)

	var player_value: Node = get_tree().get_first_node_in_group("player")
	if not (player_value is Node2D):
		return

	var player := player_value as Node2D
	var focus_2d: Vector2 = player.global_position
	if _has_property(player, "aim_direction"):
		var aim_value: Variant = player.get("aim_direction")
		if typeof(aim_value) == TYPE_VECTOR2:
			focus_2d += (aim_value as Vector2) * CAMERA_AIM_LOOKAHEAD_2D
	var legacy_camera := player.get_node_or_null("Camera2D") as Camera2D
	var shake_2d := Vector2.ZERO
	if is_instance_valid(legacy_camera):
		shake_2d = legacy_camera.offset

	var focus_3d := Vector3(
		focus_2d.x * WORLD_SCALE,
		0.0,
		focus_2d.y * WORLD_SCALE
	)
	if is_instance_valid(player_fill_light):
		player_fill_light.position = Vector3(
			player.global_position.x * WORLD_SCALE,
			1.15 * VISUAL_UNIT_SCALE,
			player.global_position.y * WORLD_SCALE
		)
	var target := focus_3d + Vector3(0.0, CAMERA_HEIGHT, CAMERA_DEPTH_OFFSET)
	if force_snap or not camera_position_initialized:
		smoothed_camera_position = target
		camera_position_initialized = true
	else:
		var follow_weight: float = 1.0 - exp(-CAMERA_FOLLOW_SPEED * delta)
		smoothed_camera_position = smoothed_camera_position.lerp(target, follow_weight)
	var shake_3d := Vector3(shake_2d.x * WORLD_SCALE, 0.0, shake_2d.y * WORLD_SCALE)
	camera_3d.position = smoothed_camera_position + shake_3d
	var actual_focus := smoothed_camera_position - Vector3(0.0, CAMERA_HEIGHT, CAMERA_DEPTH_OFFSET) + shake_3d
	camera_3d.look_at(actual_focus, Vector3.UP)


func screen_to_gameplay(screen_position: Vector2) -> Vector2:
	if not is_instance_valid(camera_3d):
		return Vector2.ZERO

	var ray_origin: Vector3 = camera_3d.project_ray_origin(screen_position)
	var ray_direction: Vector3 = camera_3d.project_ray_normal(screen_position)
	if absf(ray_direction.y) <= 0.0001:
		return Vector2.ZERO

	var distance_to_plane: float = -ray_origin.y / ray_direction.y
	var world_point: Vector3 = ray_origin + ray_direction * distance_to_plane
	return Vector2(world_point.x, world_point.z) / WORLD_SCALE


func _sync_doors() -> void:
	var dungeon: Node = get_tree().current_scene
	if dungeon == null:
		return

	var rooms_value: Variant = dungeon.get("rooms")
	var current_room_value: Variant = dungeon.get("current_room")
	if typeof(rooms_value) != TYPE_DICTIONARY or typeof(current_room_value) != TYPE_VECTOR2I:
		return

	var rooms: Dictionary = rooms_value as Dictionary
	var current_room: Vector2i = current_room_value as Vector2i
	var room_cleared: bool = bool(dungeon.get("room_cleared"))

	for direction_value in door_meshes.keys():
		var direction: Vector2i = direction_value as Vector2i
		var door := door_meshes[direction] as MeshInstance3D
		var has_neighbor: bool = rooms.has(current_room + direction)
		door.visible = not has_neighbor or not room_cleared


func _should_mirror(source: Node2D) -> bool:
	if source.is_in_group("enemy_bullet_pool") and not source.is_in_group("enemy_bullets"):
		return false
	if source.is_in_group("tactical_projectile_pool") and not source.is_in_group("enemy_bullets"):
		return false
	if (
		source.is_in_group("melee_fx")
		and _has_property(source, "attack_style")
		and str(source.get("attack_style")) == "slash"
	):
		# Sword owns a dedicated curved SwordTrail3D. Mirroring the generic
		# melee proxy would add a long BoxMesh streak through that arc.
		return false
	return true


func _is_damage_number(source: Node2D) -> bool:
	var source_script: Script = source.get_script() as Script
	return (
		is_instance_valid(source_script)
		and source_script.resource_path.ends_with("damage_number.gd")
	)


func _is_weapon_pickup(source: Node2D) -> bool:
	var source_script: Script = source.get_script() as Script
	return (
		is_instance_valid(source_script)
		and source_script.resource_path.ends_with("weapon_pickup.gd")
		and _has_property(source, "weapon_id")
	)


func _add_floor_weapon_model(proxy: Node3D, source: Node2D) -> void:
	var pickup_root := Node3D.new()
	pickup_root.name = "FloorWeapon3D"
	pickup_root.rotation_degrees.y = -18.0
	proxy.add_child(pickup_root)

	var weapon_id: String = str(source.get("weapon_id"))
	_rebuild_weapon_mesh(pickup_root, weapon_id)
	var imported_model := pickup_root.get_node_or_null("WeaponModel3D") as Node3D
	if is_instance_valid(imported_model):
		imported_model.position.x = 0.0
	var muzzle_flash := pickup_root.get_node_or_null("MuzzleFlash") as MeshInstance3D
	if is_instance_valid(muzzle_flash):
		muzzle_flash.visible = false
	var muzzle_light := pickup_root.get_node_or_null("MuzzleLight") as OmniLight3D
	if is_instance_valid(muzzle_light):
		muzzle_light.light_energy = 0.0

	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.48
	ring_mesh.outer_radius = 0.54
	var ring := MeshInstance3D.new()
	ring.name = "PickupRing3D"
	ring.mesh = ring_mesh
	ring.position.y = -0.20
	ring.material_override = _make_glow_material(Color("ffd76b"), 1.2)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	proxy.add_child(ring)


func _add_actor_model(proxy: Node3D, source: Node2D) -> bool:
	var visual_root := Node3D.new()
	visual_root.name = "ActorModel3D"
	proxy.add_child(visual_root)

	var height: float = _height_for(source)
	var radius: float = 0.26
	if source.is_in_group("boss"):
		radius = 0.56
	elif source.is_in_group("enemies"):
		radius = 0.30

	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = radius
	body_mesh.height = maxf(height, radius * 2.0)
	var body := MeshInstance3D.new()
	body.name = "BodyCapsule"
	body.mesh = body_mesh
	body.material_override = _make_material(_color_for(source), 0.58)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	visual_root.add_child(body)

	var face_mesh := BoxMesh.new()
	face_mesh.size = Vector3(radius * 0.72, height * 0.24, radius * 0.82)
	var face := MeshInstance3D.new()
	face.name = "FaceDirection3D"
	face.mesh = face_mesh
	face.position = Vector3(radius * 1.05, height * 0.08, 0.0)
	var face_color: Color = (
		Color("dff7ff") if source.is_in_group("player") else Color("ffdf8a")
	)
	face.material_override = _make_material(face_color, 0.42)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	visual_root.add_child(face)
	return true


func _add_actor_lookdev(proxy: Node3D, source: Node2D) -> void:
	var height: float = _height_for(source)
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.34 if source.is_in_group("player") else 0.38
	shadow_mesh.bottom_radius = shadow_mesh.top_radius
	shadow_mesh.height = 0.018
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadow3D"
	shadow.mesh = shadow_mesh
	shadow.position = Vector3(0.0, -height * 0.5 + 0.018, 0.0)
	shadow.scale.z = 0.72
	var shadow_color := Color("070910")
	shadow_color.a = CONTACT_SHADOW_ALPHA
	shadow.material_override = _make_transparent_material(shadow_color, false)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	proxy.add_child(shadow)

	var hit_glow := OmniLight3D.new()
	hit_glow.name = "HitGlow3D"
	hit_glow.position.y = 0.18
	hit_glow.light_color = Color("fff0d2")
	hit_glow.light_energy = 0.0
	hit_glow.omni_range = 1.55 * VISUAL_UNIT_SCALE
	hit_glow.shadow_enabled = false
	proxy.add_child(hit_glow)

	var spawn_mesh := TorusMesh.new()
	spawn_mesh.inner_radius = 0.42
	spawn_mesh.outer_radius = 0.50
	var spawn_ring := MeshInstance3D.new()
	spawn_ring.name = "SpawnRing3D"
	spawn_ring.mesh = spawn_mesh
	spawn_ring.position.y = -height * 0.5 + 0.032
	spawn_ring.material_override = _make_glow_material(
		Color("69caff") if source.is_in_group("player") else Color("ff735c"),
		1.4
	)
	spawn_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spawn_ring.visible = false
	proxy.add_child(spawn_ring)


func _add_effect_light(proxy: Node3D) -> void:
	var effect_light := OmniLight3D.new()
	effect_light.name = "EffectLight3D"
	effect_light.position.y = 0.22
	effect_light.light_color = Color("ff784e")
	effect_light.light_energy = 0.0
	effect_light.omni_range = 4.4 * VISUAL_UNIT_SCALE
	effect_light.shadow_enabled = false
	proxy.add_child(effect_light)


func _tune_imported_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mesh_instance.mesh != null:
			for surface_index in range(mesh_instance.mesh.get_surface_count()):
				var source_material := mesh_instance.mesh.surface_get_material(surface_index)
				if source_material is StandardMaterial3D:
					var tuned := (source_material as StandardMaterial3D).duplicate() as StandardMaterial3D
					tuned.roughness = clampf(tuned.roughness * 0.82, 0.28, 0.84)
					tuned.metallic_specular = maxf(tuned.metallic_specular, 0.34)
					mesh_instance.set_surface_override_material(surface_index, tuned)
	for child in node.get_children():
		_tune_imported_meshes(child)


func _fit_imported_model(imported: Node3D, target_height: float) -> void:
	var bounds: AABB = _collect_model_bounds(imported, imported, Transform3D.IDENTITY)
	if bounds.size.y <= 0.001:
		return
	var uniform_scale: float = target_height / bounds.size.y
	imported.scale = Vector3.ONE * uniform_scale
	var center := bounds.position + bounds.size * 0.5
	imported.position = Vector3(
		-center.x * uniform_scale,
		-target_height * 0.5 - bounds.position.y * uniform_scale,
		-center.z * uniform_scale
	)


func _collect_model_bounds(root_node: Node3D, node: Node, accumulated: Transform3D) -> AABB:
	var node_transform := accumulated
	if node is Node3D and node != root_node:
		node_transform = accumulated * (node as Node3D).transform
	var found := false
	var result := AABB()
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh != null:
			result = node_transform * mesh_node.mesh.get_aabb()
			found = true
	for child in node.get_children():
		var child_bounds: AABB = _collect_model_bounds(root_node, child, node_transform)
		if child_bounds.size.length_squared() <= 0.0:
			continue
		result = result.merge(child_bounds) if found else child_bounds
		found = true
	return result


func _add_damage_number_label(proxy: Node3D, source: Node2D) -> void:
	var label := Label3D.new()
	label.name = "DamageLabel"
	label.text = str(int(source.get("amount")))
	label.font_size = 32
	label.outline_size = 7
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.top_level = true
	label.modulate = (
		Color("ff5555")
		if _get_bool_property(source, "is_player_damage")
		else Color("ffdc57")
	)
	proxy.add_child(label)


func _add_enemy_health_bar(proxy: Node3D) -> void:
	var bar_root := Node3D.new()
	bar_root.name = "HealthBar3D"
	bar_root.top_level = true
	bar_root.set_meta("height", 1.08)

	var background_mesh := BoxMesh.new()
	background_mesh.size = Vector3(0.82, 0.12, 0.025)
	var background := MeshInstance3D.new()
	background.name = "Background"
	background.mesh = background_mesh
	background.material_override = _make_material(Color("241e29"), 1.0, true)
	background.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar_root.add_child(background)

	var fill_mesh := BoxMesh.new()
	fill_mesh.size = Vector3(0.74, 0.07, 0.032)
	var fill := MeshInstance3D.new()
	fill.name = "Fill"
	fill.mesh = fill_mesh
	# Health bar copies the camera basis. Local +Z is therefore the side
	# facing the camera; placing the fill on -Z let the background occlude it.
	fill.position.z = 0.02
	fill.material_override = _make_material(Color("58e071"), 1.0, true)
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar_root.add_child(fill)
	proxy.add_child(bar_root)


func _add_enemy_identity_parts(proxy: Node3D, source: Node2D) -> void:
	var kind: String = _enemy_kind(source)
	var parts := Node3D.new()
	parts.name = "EnemyIdentity3D"
	proxy.add_child(parts)
	if bool(proxy.get_meta("uses_authored_visual", false)):
		return

	match kind:
		"chaser":
			_add_enemy_box(parts, "LeftClaw", Vector3(0.38, 0.12, 0.10), Vector3(0.25, 0.10, -0.25), Color("f3c25f"))
			_add_enemy_box(parts, "RightClaw", Vector3(0.38, 0.12, 0.10), Vector3(0.25, 0.10, 0.25), Color("f3c25f"))
		"gunner":
			_add_enemy_box(parts, "Rifle", Vector3(0.58, 0.12, 0.13), Vector3(0.36, 0.10, 0.0), Color("303744"))
		"spread":
			for barrel_index in range(3):
				_add_enemy_box(parts, "SpreadBarrel%d" % barrel_index, Vector3(0.48, 0.09, 0.08), Vector3(0.34, 0.12, (barrel_index - 1) * 0.14), Color("e5a85d"))
		"elite", "gunner_elite", "tactical_gunner":
			_add_enemy_box(parts, "EliteRifle", Vector3(0.70, 0.14, 0.15), Vector3(0.40, 0.14, 0.0), Color("332940"))
			_add_enemy_box(parts, "EliteVisor", Vector3(0.10, 0.13, 0.42), Vector3(0.23, 0.28, 0.0), Color("ff6bf2"), true)
		"shield":
			_add_enemy_box(parts, "Shield3D", Vector3(0.13, 0.78, 0.72), Vector3(0.37, 0.05, 0.0), Color("62d5ef"), true)
			_add_enemy_box(parts, "ShieldRim", Vector3(0.08, 0.88, 0.82), Vector3(0.35, 0.05, 0.0), Color("d3f5ff"))
		"charger":
			_add_enemy_box(parts, "LeftHorn", Vector3(0.52, 0.13, 0.12), Vector3(0.35, 0.25, -0.27), Color("f2dc9e"))
			_add_enemy_box(parts, "RightHorn", Vector3(0.52, 0.13, 0.12), Vector3(0.35, 0.25, 0.27), Color("f2dc9e"))
		"suicide", "suicide_bot":
			_add_enemy_sphere(parts, "FuseCore", 0.15, Vector3(0.0, 0.42, 0.0), Color("ffef64"), true)
		"bomber":
			_add_enemy_sphere(parts, "BombPack", 0.25, Vector3(-0.22, 0.24, 0.0), Color("252832"))
		_:
			_add_enemy_box(parts, "RoleMark", Vector3(0.12, 0.18, 0.36), Vector3(0.22, 0.22, 0.0), Color("ffd27a"))
	_add_enemy_asset_equipment(parts, kind)


func _add_enemy_indicator(proxy: Node3D) -> void:
	var indicator := Node3D.new()
	indicator.name = "Indicator3D"
	indicator.position.y = -0.40

	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.43
	ring_mesh.outer_radius = 0.50
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	ring.mesh = ring_mesh
	ring.material_override = _make_indicator_material(Color("ffbd45"))
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	indicator.add_child(ring)

	var lane_mesh := BoxMesh.new()
	lane_mesh.size = Vector3(2.8, 0.025, 0.34)
	var lane := MeshInstance3D.new()
	lane.name = "Lane"
	lane.mesh = lane_mesh
	lane.position = Vector3(1.55, 0.015, 0.0)
	lane.material_override = _make_indicator_material(Color("ff504c"))
	lane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	indicator.add_child(lane)
	indicator.visible = false
	proxy.add_child(indicator)


func _add_enemy_box(
	parent: Node3D,
	part_name: String,
	size: Vector3,
	part_position: Vector3,
	color: Color,
	emissive: bool = false
) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.position = part_position
	part.material_override = _make_material(color, 0.42, emissive)
	parent.add_child(part)


func _add_enemy_sphere(
	parent: Node3D,
	part_name: String,
	radius: float,
	part_position: Vector3,
	color: Color,
	emissive: bool = false
) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = mesh
	part.position = part_position
	part.material_override = _make_material(color, 0.42, emissive)
	parent.add_child(part)


func _add_enemy_asset_equipment(parts: Node3D, kind: String) -> void:
	var model_path := ""
	var target_length := 0.66
	var part_position := Vector3(0.34, 0.15, 0.0)
	var part_rotation := Vector3(0.0, -90.0, 0.0)
	var part_name := "EnemyWeaponModel3D"
	match kind:
		"gunner":
			model_path = "res://gungeon_proto/assets/models/weapons/Blaster/blaster-b.fbx"
		"spread":
			model_path = "res://gungeon_proto/assets/models/weapons/Blaster/blaster-k.fbx"
		"elite", "gunner_elite", "tactical_gunner":
			model_path = "res://gungeon_proto/assets/models/weapons/Blaster/blaster-r.fbx"
			target_length = 0.78
		"shield":
			model_path = "res://gungeon_proto/assets/models/weapons/Medieval/shield-round-a.fbx"
			target_length = 0.82
			part_position = Vector3(0.39, 0.05, 0.0)
			part_rotation = Vector3(0.0, 90.0, 0.0)
			part_name = "ShieldModel3D"
		"bomber":
			model_path = "res://gungeon_proto/assets/models/weapons/Blaster/grenade-a.fbx"
			target_length = 0.34
			part_position = Vector3(-0.18, 0.43, 0.0)
			part_rotation = Vector3.ZERO
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		return
	var packed := load(model_path) as PackedScene
	if packed == null:
		return
	var imported := packed.instantiate() as Node3D
	if not is_instance_valid(imported):
		return
	var asset_root := Node3D.new()
	asset_root.name = part_name
	asset_root.position = part_position
	asset_root.rotation_degrees = part_rotation
	asset_root.set_meta("model_path", model_path)
	asset_root.add_child(imported)
	parts.add_child(asset_root)
	_fit_weapon_model(imported, target_length)
	_tune_imported_meshes(imported)
	var fallback_names: PackedStringArray = []
	match kind:
		"gunner":
			fallback_names = ["Rifle"]
		"spread":
			fallback_names = ["SpreadBarrel0", "SpreadBarrel1", "SpreadBarrel2"]
		"elite", "gunner_elite", "tactical_gunner":
			fallback_names = ["EliteRifle"]
		"shield":
			fallback_names = ["Shield3D", "ShieldRim"]
		"bomber":
			fallback_names = ["BombPack"]
	for fallback_name in fallback_names:
		var fallback_part := parts.get_node_or_null(fallback_name) as Node3D
		if is_instance_valid(fallback_part):
			fallback_part.visible = false


func _add_player_weapon_root(proxy: Node3D) -> void:
	var weapon_root := Node3D.new()
	weapon_root.name = "HeldWeapon3D"
	weapon_root.position = Vector3(0.20, 0.18, 0.0)
	proxy.add_child(weapon_root)


func _update_player_weapon(source: Node2D, proxy: Node3D) -> void:
	var weapon_system := source.get_node_or_null("Systems/WeaponSystem")
	var weapon_root := proxy.get_node_or_null("HeldWeapon3D") as Node3D
	if not is_instance_valid(weapon_system) or not is_instance_valid(weapon_root):
		return

	var weapon_id: String = str(weapon_system.get("current_weapon"))
	if str(weapon_root.get_meta("weapon_id", "")) != weapon_id:
		_rebuild_weapon_mesh(weapon_root, weapon_id)
		weapon_root.set_meta("weapon_id", weapon_id)
	weapon_root.rotation.y = 0.0
	var sword_trail := weapon_root.get_node_or_null("SwordTrail3D") as MeshInstance3D
	if is_instance_valid(sword_trail):
		sword_trail.visible = false
	if weapon_id == "sword":
		var swing_timer: float = _get_float_property(source, "sword_visual_timer", 0.0)
		var swing_duration: float = maxf(
			_get_float_property(source, "sword_visual_duration", 0.14),
			0.01
		)
		if swing_timer > 0.0:
			var swing_progress: float = clampf(
				1.0 - swing_timer / swing_duration,
				0.0,
				1.0
			)
			var from_angle: float = _get_float_property(
				source,
				"sword_visual_from_angle",
				-0.9
			)
			var to_angle: float = _get_float_property(
				source,
				"sword_visual_to_angle",
				0.9
			)
			var swing_angle: float
			var trail_progress: float = 0.0
			var trail_opacity: float = 0.0
			if swing_progress < 0.20:
				var windup_weight: float = smoothstep(0.0, 0.20, swing_progress)
				swing_angle = lerpf(from_angle * 0.62, from_angle, windup_weight)
			elif swing_progress < 0.64:
				var active_weight: float = smoothstep(0.20, 0.64, swing_progress)
				swing_angle = lerpf(from_angle, to_angle, active_weight)
				trail_progress = active_weight
				trail_opacity = smoothstep(0.0, 0.22, active_weight)
			elif swing_progress < 0.84:
				var follow_weight: float = smoothstep(0.64, 0.84, swing_progress)
				swing_angle = lerpf(to_angle, to_angle * 0.92, follow_weight)
				trail_progress = 1.0
				trail_opacity = 1.0 - follow_weight * 0.72
			else:
				var recovery_weight: float = smoothstep(0.84, 1.0, swing_progress)
				swing_angle = lerpf(to_angle * 0.92, 0.0, recovery_weight)
				trail_progress = 1.0
				trail_opacity = (1.0 - recovery_weight) * 0.28
			var attack_direction_value: Variant = source.get("sword_visual_direction")
			if typeof(attack_direction_value) == TYPE_VECTOR2:
				var visual_direction: Vector2 = (
					attack_direction_value as Vector2
				).rotated(swing_angle)
				weapon_root.rotation.y = -visual_direction.angle() - proxy.rotation.y
				if is_instance_valid(sword_trail):
					var swing_delta: float = (
						_get_float_property(source, "sword_visual_to_angle", 0.9)
						- _get_float_property(source, "sword_visual_from_angle", -0.9)
					)
					sword_trail.visible = trail_opacity > 0.01
					_update_sword_trail_mesh(
						sword_trail,
						trail_progress,
						absf(swing_delta),
						signf(swing_delta),
						trail_opacity
					)
	var laser_beam := weapon_root.get_node_or_null("LaserBeam3D") as Node3D
	if is_instance_valid(laser_beam):
		var laser_active: bool = _get_float_property(source, "muzzle_flash_timer", 0.0) > 0.0
		laser_beam.visible = laser_active
		laser_beam.position.x = LASER_BEAM_LENGTH * 0.5 + 0.72
		var beam_scale := laser_beam.get_node_or_null("BeamCore") as MeshInstance3D
		var beam_halo := laser_beam.get_node_or_null("BeamHalo") as MeshInstance3D
		if is_instance_valid(beam_scale):
			beam_scale.scale.x = 1.0
		if is_instance_valid(beam_halo):
			beam_halo.scale.x = 1.0
		var beam_light := laser_beam.get_node_or_null("BeamLight") as OmniLight3D
		if is_instance_valid(beam_light):
			beam_light.light_energy = 2.4 if laser_active else 0.0

	var muzzle_flash := weapon_root.get_node_or_null("MuzzleFlash") as MeshInstance3D
	if is_instance_valid(muzzle_flash):
		var muzzle_active: bool = _get_float_property(source, "muzzle_flash_timer", 0.0) > 0.0
		muzzle_flash.visible = muzzle_active
		var muzzle_light := weapon_root.get_node_or_null("MuzzleLight") as OmniLight3D
		if is_instance_valid(muzzle_light):
			muzzle_light.light_energy = 4.5 if muzzle_active else 0.0


func _update_enemy_presentation(source: Node2D, proxy: Node3D) -> void:
	var health_bar := proxy.get_node_or_null("HealthBar3D") as Node3D
	if is_instance_valid(health_bar):
		var maximum: float = maxf(_get_float_property(source, "max_health", 1.0), 1.0)
		var current: float = clampf(_get_float_property(source, "health", maximum), 0.0, maximum)
		var health_ratio: float = current / maximum
		var fill := health_bar.get_node_or_null("Fill") as MeshInstance3D
		if is_instance_valid(fill):
			fill.scale.x = maxf(health_ratio, 0.001)
			fill.position.x = -0.37 * (1.0 - health_ratio)
			var fill_material := fill.material_override as StandardMaterial3D
			if is_instance_valid(fill_material):
				fill_material.albedo_color = Color("58e071").lerp(Color("ff4949"), 1.0 - health_ratio)
		health_bar.visible = current > 0.0 and _get_float_property(source, "spawn_timer", 0.0) <= 0.0

	var kind: String = _enemy_kind(source)
	if kind == "shield":
		var shield := proxy.get_node_or_null("EnemyIdentity3D/Shield3D") as MeshInstance3D
		var shield_rim := proxy.get_node_or_null("EnemyIdentity3D/ShieldRim") as MeshInstance3D
		var shield_model := proxy.get_node_or_null("EnemyIdentity3D/ShieldModel3D") as Node3D
		if not is_instance_valid(shield_model):
			shield_model = proxy.get_node_or_null("ActorModel3D/ShieldModel3D") as Node3D
		var guard_broken: bool = _get_float_property(source, "guard_break_timer", 0.0) > 0.0
		if is_instance_valid(shield_model):
			shield_model.visible = not guard_broken
			if is_instance_valid(shield):
				shield.visible = false
			if is_instance_valid(shield_rim):
				shield_rim.visible = false
		else:
			if is_instance_valid(shield):
				shield.visible = not guard_broken
			if is_instance_valid(shield_rim):
				shield_rim.visible = not guard_broken

	var fuse_core := proxy.get_node_or_null("EnemyIdentity3D/FuseCore") as MeshInstance3D
	if is_instance_valid(fuse_core):
		var fuse_active: bool = _get_float_property(source, "fuse_timer", 0.0) > 0.0
		var pulse: float = 1.0 + sin(elapsed_time * 22.0) * 0.22 if fuse_active else 1.0
		fuse_core.scale = Vector3.ONE * pulse

	_update_enemy_indicator(source, proxy, kind)


func _update_enemy_indicator(source: Node2D, proxy: Node3D, kind: String) -> void:
	var indicator := proxy.get_node_or_null("Indicator3D") as Node3D
	if not is_instance_valid(indicator):
		return
	var ring := indicator.get_node_or_null("Ring") as MeshInstance3D
	var lane := indicator.get_node_or_null("Lane") as MeshInstance3D
	var show_ring := false
	var show_lane := false
	var urgency := 0.0

	match kind:
		"chaser":
			var melee_windup: float = _get_float_property(source, "melee_windup_timer", 0.0)
			show_ring = melee_windup > 0.0
			show_lane = show_ring
			urgency = 1.0 - clampf(melee_windup / 0.24, 0.0, 1.0)
		"shield":
			var bash_windup: float = _get_float_property(source, "bash_windup_timer", 0.0)
			show_ring = bash_windup > 0.0
			show_lane = show_ring
			urgency = 1.0 - clampf(bash_windup / 1.0, 0.0, 1.0)
		"charger":
			var charge_state: int = int(source.get("charge_state")) if _has_property(source, "charge_state") else 0
			show_ring = charge_state == 3
			show_lane = charge_state == 3
			urgency = 1.0 - clampf(_get_float_property(source, "state_timer", 0.0) / 0.72, 0.0, 1.0)
		"suicide", "suicide_bot":
			var fuse_timer: float = _get_float_property(source, "fuse_timer", 0.0)
			show_ring = fuse_timer > 0.0
			urgency = 1.0 - clampf(fuse_timer / 0.85, 0.0, 1.0)
		"bomber":
			var bomb_windup: float = _get_float_property(source, "windup_timer", 0.0)
			show_ring = bomb_windup > 0.0
			urgency = 1.0 - clampf(bomb_windup / 0.35, 0.0, 1.0)
		"elite", "gunner_elite", "tactical_gunner":
			var aim_timer: float = _get_float_property(source, "aim_timer", 0.0)
			var gunner_state: int = int(source.get("state")) if _has_property(source, "state") else -1
			show_ring = gunner_state == 1 and aim_timer > 0.0
			show_lane = show_ring
			urgency = 1.0 - clampf(aim_timer / 0.72, 0.0, 1.0)

	indicator.visible = show_ring or show_lane
	if is_instance_valid(ring):
		ring.visible = show_ring
		ring.scale = Vector3.ONE * lerpf(0.84, 1.18, urgency)
	if is_instance_valid(lane):
		lane.visible = show_lane
		var lane_length: float = 4.2 if kind == "charger" else 2.3
		lane.scale.x = lane_length / 2.8
		lane.position.x = 0.42 + lane_length * 0.5


func _update_billboards(proxy: Node3D) -> void:
	if not is_instance_valid(camera_3d):
		return
	var damage_label := proxy.get_node_or_null("DamageLabel") as Label3D
	if is_instance_valid(damage_label):
		damage_label.global_position = proxy.global_position
		damage_label.global_basis = camera_3d.global_basis.scaled(
			Vector3.ONE * VISUAL_UNIT_SCALE
		)
	var health_bar := proxy.get_node_or_null("HealthBar3D") as Node3D
	if is_instance_valid(health_bar):
		var bar_height: float = float(health_bar.get_meta("height", 1.08))
		health_bar.global_position = proxy.global_position + Vector3(
			0.0,
			bar_height * VISUAL_UNIT_SCALE,
			0.0
		)
		health_bar.global_basis = camera_3d.global_basis.scaled(
			Vector3.ONE * VISUAL_UNIT_SCALE
		)


func _enemy_facing_direction(source: Node2D) -> Vector2:
	for property_name in ["facing_direction", "charge_visual_direction", "melee_attack_direction", "cached_navigation_direction"]:
		if _has_property(source, property_name):
			var value: Variant = source.get(property_name)
			if typeof(value) == TYPE_VECTOR2 and (value as Vector2).length_squared() > 0.001:
				return (value as Vector2).normalized()
	return Vector2.from_angle(source.global_rotation)


func _enemy_kind(source: Node2D) -> String:
	var source_script: Script = source.get_script() as Script
	var script_path: String = source_script.resource_path.to_lower() if is_instance_valid(source_script) else ""
	for specialized_type in ["tactical_gunner", "suicide_bot", "shield", "charger", "bomber"]:
		if specialized_type in script_path:
			return specialized_type
	if _has_property(source, "enemy_type"):
		var configured_type: String = str(source.get("enemy_type")).to_lower()
		if not configured_type.is_empty():
			return configured_type
	var source_name: String = source.name.to_lower()
	for known_type in ["tactical_gunner", "suicide_bot", "shield", "charger", "bomber", "chaser", "spread", "elite", "gunner"]:
		if known_type in source_name:
			return known_type
	return "enemy"


func _rebuild_weapon_mesh(weapon_root: Node3D, weapon_id: String) -> void:
	for child in weapon_root.get_children():
		child.free()
	if _add_weapon_model(weapon_root, weapon_id):
		if weapon_id not in ["sword", "spear", "hammer"]:
			_add_weapon_muzzle_flash(weapon_root, float(weapon_root.get_meta("model_length", 0.82)))
		if weapon_id == "laser_rifle":
			_add_laser_beam(weapon_root)
		if weapon_id == "sword":
			_add_sword_trail(weapon_root)
		return

	var metal := Color("cbd5df")
	var dark := Color("394454")
	match weapon_id:
		"sword":
			_add_weapon_box(weapon_root, Vector3(0.58, 0.045, 0.11), Vector3(0.36, 0.0, 0.0), metal)
			_add_weapon_box(weapon_root, Vector3(0.10, 0.12, 0.32), Vector3(0.08, 0.0, 0.0), Color("d7aa58"))
		"spear":
			_add_weapon_box(weapon_root, Vector3(0.92, 0.055, 0.07), Vector3(0.48, 0.0, 0.0), Color("8b6747"))
			_add_weapon_box(weapon_root, Vector3(0.24, 0.07, 0.16), Vector3(0.99, 0.0, 0.0), metal)
		"hammer":
			_add_weapon_box(weapon_root, Vector3(0.58, 0.07, 0.08), Vector3(0.32, 0.0, 0.0), Color("805b3d"))
			_add_weapon_box(weapon_root, Vector3(0.22, 0.24, 0.38), Vector3(0.66, 0.0, 0.0), Color("657181"))
		"shotgun":
			_add_weapon_box(weapon_root, Vector3(0.78, 0.12, 0.16), Vector3(0.45, 0.0, 0.0), Color("7b5437"))
			_add_weapon_box(weapon_root, Vector3(0.62, 0.07, 0.08), Vector3(0.62, 0.09, 0.0), dark)
		"machine_gun":
			_add_weapon_box(weapon_root, Vector3(0.72, 0.14, 0.18), Vector3(0.42, 0.0, 0.0), dark)
			_add_weapon_box(weapon_root, Vector3(0.16, 0.28, 0.15), Vector3(0.30, -0.17, 0.0), Color("55606c"))
		"laser_rifle":
			_add_weapon_box(weapon_root, Vector3(0.82, 0.13, 0.15), Vector3(0.46, 0.0, 0.0), Color("4e607f"))
			_add_weapon_box(weapon_root, Vector3(0.42, 0.05, 0.17), Vector3(0.56, 0.09, 0.0), Color("56e4ff"), true)
		"grenade_launcher":
			_add_weapon_cylinder(weapon_root, 0.13, 0.62, Vector3(0.42, 0.0, 0.0), Color("52634d"))
		"crossbow":
			_add_weapon_box(weapon_root, Vector3(0.74, 0.08, 0.10), Vector3(0.43, 0.0, 0.0), Color("79583c"))
			_add_weapon_box(weapon_root, Vector3(0.10, 0.07, 0.62), Vector3(0.58, 0.0, 0.0), metal)
		_:
			_add_weapon_box(weapon_root, Vector3(0.48, 0.15, 0.18), Vector3(0.31, 0.0, 0.0), dark)
			_add_weapon_box(weapon_root, Vector3(0.30, 0.07, 0.08), Vector3(0.67, 0.05, 0.0), metal)

	if weapon_id not in ["sword", "spear", "hammer"]:
		_add_weapon_muzzle_flash(weapon_root, 0.82)
	if weapon_id == "laser_rifle":
		_add_laser_beam(weapon_root)
	if weapon_id == "sword":
		_add_sword_trail(weapon_root)


func _add_weapon_model(weapon_root: Node3D, weapon_id: String) -> bool:
	var model_path: String = str(WEAPON_MODEL_PATHS.get(weapon_id, ""))
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		return false
	var packed := load(model_path) as PackedScene
	if packed == null:
		return false
	var imported := packed.instantiate() as Node3D
	if not is_instance_valid(imported):
		return false

	var asset_root := Node3D.new()
	asset_root.name = "WeaponModel3D"
	asset_root.set_meta("model_path", model_path)
	var is_medieval: bool = weapon_id in ["sword", "spear", "hammer"]
	asset_root.rotation_degrees = Vector3(0.0, 0.0, -90.0) if is_medieval else Vector3(0.0, -90.0, 0.0)
	asset_root.add_child(imported)
	weapon_root.add_child(asset_root)

	var target_length: float = 0.76
	match weapon_id:
		"shotgun", "machine_gun", "laser_rifle":
			target_length = 0.92
		"grenade_launcher":
			target_length = 0.82
		"sword":
			target_length = 0.88
		"spear":
			target_length = 1.18
		"hammer":
			target_length = 0.92
	_fit_weapon_model(imported, target_length)
	_tune_imported_meshes(imported)
	asset_root.position.x = target_length * 0.52
	weapon_root.set_meta("model_length", target_length)
	return true


func _fit_weapon_model(imported: Node3D, target_length: float) -> void:
	var bounds: AABB = _collect_model_bounds(imported, imported, Transform3D.IDENTITY)
	var longest_dimension: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if longest_dimension <= 0.001:
		return
	var uniform_scale: float = target_length / longest_dimension
	var center := bounds.position + bounds.size * 0.5
	imported.scale = Vector3.ONE * uniform_scale
	imported.position = -center * uniform_scale


func _add_weapon_muzzle_flash(weapon_root: Node3D, model_length: float) -> void:
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.11
	flash_mesh.height = 0.22
	var flash := MeshInstance3D.new()
	flash.name = "MuzzleFlash"
	flash.mesh = flash_mesh
	flash.position = Vector3(model_length + 0.12, 0.04, 0.0)
	flash.material_override = _make_projectile_material(Color("fff0a0"), 7.0)
	flash.visible = false
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	weapon_root.add_child(flash)

	var halo_mesh := SphereMesh.new()
	halo_mesh.radius = 0.22
	halo_mesh.height = 0.44
	var halo := MeshInstance3D.new()
	halo.name = "MuzzleHalo"
	halo.mesh = halo_mesh
	halo.material_override = _make_transparent_glow_material(
		Color(1.0, 0.68, 0.18, 0.32),
		3.5
	)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.add_child(halo)

	var muzzle_light := OmniLight3D.new()
	muzzle_light.name = "MuzzleLight"
	muzzle_light.position = flash.position
	muzzle_light.light_color = Color("ffd37a")
	muzzle_light.light_energy = 0.0
	muzzle_light.omni_range = 2.4 * VISUAL_UNIT_SCALE
	muzzle_light.shadow_enabled = false
	weapon_root.add_child(muzzle_light)


func _add_laser_beam(weapon_root: Node3D) -> void:
	var beam_root := Node3D.new()
	beam_root.name = "LaserBeam3D"
	beam_root.position.y = 0.04
	beam_root.visible = false

	var halo_mesh := CylinderMesh.new()
	halo_mesh.top_radius = 0.075
	halo_mesh.bottom_radius = 0.075
	halo_mesh.height = LASER_BEAM_LENGTH
	var halo := MeshInstance3D.new()
	halo.name = "BeamHalo"
	halo.mesh = halo_mesh
	halo.rotation_degrees.z = 90.0
	var halo_material := _make_material(Color(0.08, 0.52, 0.8, 0.24), 0.32)
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.emission_enabled = true
	halo_material.emission = Color(0.04, 0.32, 0.55)
	halo_material.emission_energy_multiplier = 0.7
	halo.material_override = halo_material
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam_root.add_child(halo)

	var core_mesh := CylinderMesh.new()
	core_mesh.top_radius = 0.026
	core_mesh.bottom_radius = 0.026
	core_mesh.height = LASER_BEAM_LENGTH
	var core := MeshInstance3D.new()
	core.name = "BeamCore"
	core.mesh = core_mesh
	core.rotation_degrees.z = 90.0
	var core_material := _make_material(Color(0.65, 0.9, 1.0), 0.28)
	core_material.emission_enabled = true
	core_material.emission = Color(0.25, 0.72, 0.95)
	core_material.emission_energy_multiplier = 1.4
	core.material_override = core_material
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam_root.add_child(core)

	var impact_mesh := SphereMesh.new()
	impact_mesh.radius = 0.11
	impact_mesh.height = 0.22
	var impact := MeshInstance3D.new()
	impact.name = "BeamImpact"
	impact.mesh = impact_mesh
	impact.position.x = LASER_BEAM_LENGTH * 0.5
	impact.material_override = _make_material(Color(0.45, 0.92, 1.0), 0.24, true)
	var impact_material := impact.material_override as StandardMaterial3D
	impact_material.emission_enabled = true
	impact_material.emission = Color(0.2, 0.75, 1.0)
	impact_material.emission_energy_multiplier = 1.8
	impact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam_root.add_child(impact)

	var beam_light := OmniLight3D.new()
	beam_light.name = "BeamLight"
	beam_light.position.x = 0.0
	beam_light.light_color = Color(0.18, 0.7, 1.0)
	beam_light.light_energy = 0.0
	beam_light.omni_range = 4.2 * VISUAL_UNIT_SCALE
	beam_light.shadow_enabled = false
	beam_root.add_child(beam_light)
	weapon_root.add_child(beam_root)


func _add_sword_trail(weapon_root: Node3D) -> void:
	var trail := MeshInstance3D.new()
	trail.name = "SwordTrail3D"
	trail.mesh = ImmediateMesh.new()
	trail.position.y = 0.035
	trail.material_override = _make_transparent_glow_material(
		Color(0.48, 0.86, 1.0, 0.58),
		3.2
	)
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trail.visible = false
	weapon_root.add_child(trail)


func _update_sword_trail_mesh(
	trail: MeshInstance3D,
	swing_progress: float,
	total_arc: float,
	swing_direction: float,
	opacity: float
) -> void:
	var immediate := trail.mesh as ImmediateMesh
	if not is_instance_valid(immediate):
		return
	immediate.clear_surfaces()
	var visible_arc: float = minf(total_arc * clampf(swing_progress, 0.16, 1.0), 1.25)
	var segment_count: int = 14
	var inner_radius: float = 0.24
	var outer_radius: float = 1.02
	immediate.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for segment_index in range(segment_count + 1):
		var weight: float = float(segment_index) / float(segment_count)
		var angle: float = lerpf(-visible_arc * swing_direction, 0.0, weight)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		immediate.surface_set_color(Color(0.30, 0.75, 1.0, 0.08 + weight * 0.52))
		immediate.surface_add_vertex(direction * inner_radius)
		immediate.surface_set_color(Color(0.78, 0.96, 1.0, 0.04 + weight * 0.72))
		immediate.surface_add_vertex(direction * outer_radius)
	immediate.surface_end()
	var trail_material := trail.material_override as StandardMaterial3D
	if is_instance_valid(trail_material):
		trail_material.vertex_color_use_as_albedo = true
		trail_material.albedo_color.a = clampf(opacity, 0.0, 1.0)


func _add_weapon_box(
	parent: Node3D,
	size: Vector3,
	part_position: Vector3,
	color: Color,
	emissive: bool = false
) -> void:
	var box := BoxMesh.new()
	box.size = size
	var part := MeshInstance3D.new()
	part.mesh = box
	part.position = part_position
	part.material_override = _make_material(color, 0.38, emissive)
	parent.add_child(part)


func _add_weapon_cylinder(
	parent: Node3D,
	radius: float,
	length: float,
	part_position: Vector3,
	color: Color
) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	var part := MeshInstance3D.new()
	part.mesh = cylinder
	part.position = part_position
	part.rotation_degrees.z = 90.0
	part.material_override = _make_material(color, 0.42)
	parent.add_child(part)


func _update_proxy_feedback(source: Node2D, proxy: Node3D, delta: float) -> void:
	var target_scale := Vector3.ONE
	var knockback_velocity: Vector2 = _get_knockback_velocity(source)
	var hit_flash: float = _get_float_property(source, "hit_flash", 0.0)
	if knockback_velocity.length_squared() > 4.0:
		target_scale = Vector3(1.14, 0.88, 0.82)
	elif hit_flash > 0.0:
		target_scale = Vector3(1.09, 1.04, 1.09)
	if _get_bool_property(source, "is_rolling"):
		target_scale = Vector3(1.18, 0.66, 1.18)

	var explosion_timer: float = _get_float_property(source, "explosion_visual_timer", 0.0)
	if explosion_timer > 0.0:
		var duration: float = 0.12 if source.is_in_group("enemy_bombs") else 0.14
		var progress: float = clampf(1.0 - explosion_timer / duration, 0.0, 1.0)
		var explosion_radius: float = _get_float_property(source, "explosion_radius", 72.0)
		var mesh_diameter: float = 0.48
		var target_diameter: float = lerpf(18.0, explosion_radius * 2.0, progress) * WORLD_SCALE
		var explosion_scale: float = target_diameter / (mesh_diameter * VISUAL_UNIT_SCALE)
		target_scale = Vector3.ONE * explosion_scale
	elif source.is_in_group("enemy_bombs"):
		var warning_timer: float = _get_float_property(source, "warning_timer", 0.0)
		if warning_timer > 0.0:
			var warning_pulse: float = 1.0 + sin(elapsed_time * 28.0) * 0.16
			target_scale = Vector3.ONE * warning_pulse

	if source.is_in_group("room_fx") or source.is_in_group("melee_fx"):
		var age: float = _get_float_property(source, "age", _get_float_property(source, "life_timer", 0.0))
		var duration: float = maxf(
			_get_float_property(source, "duration", _get_float_property(source, "life_time", 0.2)),
			0.01
		)
		var progress: float = clampf(age / duration, 0.0, 1.0)
		var effect_scale: float = lerpf(0.3, 4.5, progress)
		if (
			_has_property(source, "fx_type")
			and str(source.get("fx_type")) == "explosion"
		):
			effect_scale = lerpf(0.8, 11.0, progress)
		target_scale = Vector3(effect_scale, 1.0, effect_scale)

	target_scale *= VISUAL_UNIT_SCALE
	var scale_weight: float = 1.0 - exp(-18.0 * maxf(delta, 0.001))
	proxy.scale = proxy.scale.lerp(target_scale, scale_weight)

	var hit_glow := proxy.get_node_or_null("HitGlow3D") as OmniLight3D
	if is_instance_valid(hit_glow):
		if hit_flash > 0.0 and active_dynamic_combat_lights < MAX_DYNAMIC_COMBAT_LIGHTS:
			hit_glow.light_energy = 2.2
			active_dynamic_combat_lights += 1
		else:
			hit_glow.light_energy = 0.0
	var projectile_light := proxy.get_node_or_null(
		"ProjectileEmissionLight3D"
	) as OmniLight3D
	if is_instance_valid(projectile_light):
		if active_dynamic_combat_lights < MAX_DYNAMIC_COMBAT_LIGHTS:
			projectile_light.light_energy = 1.35
			active_dynamic_combat_lights += 1
		else:
			projectile_light.light_energy = 0.0
	var spawn_ring := proxy.get_node_or_null("SpawnRing3D") as MeshInstance3D
	if is_instance_valid(spawn_ring):
		var spawn_timer: float = _get_float_property(source, "spawn_timer", 0.0)
		spawn_ring.visible = spawn_timer > 0.0
		if spawn_ring.visible:
			var spawn_pulse: float = 0.78 + sin(elapsed_time * 15.0) * 0.12
			spawn_ring.scale = Vector3.ONE * spawn_pulse
	var effect_light := proxy.get_node_or_null("EffectLight3D") as OmniLight3D
	if is_instance_valid(effect_light):
		var warning_timer_for_light: float = _get_float_property(source, "warning_timer", 0.0)
		var is_room_effect: bool = source.is_in_group("room_fx")
		var room_effect_progress: float = clampf(
			_get_float_property(source, "age", 0.0)
			/ maxf(_get_float_property(source, "duration", 0.2), 0.01),
			0.0,
			1.0
		)
		var room_fx_type: String = str(source.get("fx_type")) if is_room_effect and _has_property(source, "fx_type") else ""
		effect_light.light_color = _color_for(source)
		if explosion_timer > 0.0 and active_dynamic_combat_lights < MAX_DYNAMIC_COMBAT_LIGHTS:
			effect_light.light_energy = 3.8
			effect_light.omni_range = maxf(
				_get_float_property(source, "explosion_radius", 72.0) * WORLD_SCALE * 1.8,
				3.2 * VISUAL_UNIT_SCALE
			)
			active_dynamic_combat_lights += 1
		elif is_room_effect and active_dynamic_combat_lights < MAX_DYNAMIC_COMBAT_LIGHTS:
			effect_light.light_energy = (4.2 if room_fx_type == "explosion" else 1.1) * (1.0 - room_effect_progress)
			effect_light.omni_range = (
				4.8 * VISUAL_UNIT_SCALE
				if room_fx_type == "explosion"
				else 2.2 * VISUAL_UNIT_SCALE
			)
			active_dynamic_combat_lights += 1
		elif warning_timer_for_light > 0.0 and active_dynamic_combat_lights < MAX_DYNAMIC_COMBAT_LIGHTS:
			effect_light.light_energy = 0.65 + sin(elapsed_time * 28.0) * 0.22
			active_dynamic_combat_lights += 1
		else:
			effect_light.light_energy = 0.0

	var mesh := proxy.get_node_or_null("Mesh") as MeshInstance3D
	if not is_instance_valid(mesh):
		var damage_label := proxy.get_node_or_null("DamageLabel") as Label3D
		if is_instance_valid(damage_label):
			var label_progress: float = clampf(
				_get_float_property(source, "age", 0.0)
				/ maxf(_get_float_property(source, "duration", 0.62), 0.01),
				0.0,
				1.0
			)
			damage_label.modulate.a = 1.0 - label_progress
		return
	var material := mesh.material_override as StandardMaterial3D
	if not is_instance_valid(material):
		return

	var base_color: Color = mesh.get_meta("base_color", Color.WHITE) as Color
	var is_effect: bool = (
		source.is_in_group("room_fx")
		or source.is_in_group("melee_fx")
		or explosion_timer > 0.0
		or (source.is_in_group("enemy_bombs") and _get_float_property(source, "warning_timer", 0.0) > 0.0)
	)
	material.albedo_color = Color.WHITE if hit_flash > 0.0 else base_color
	if is_effect:
		var effect_progress: float = clampf(
			_get_float_property(source, "age", _get_float_property(source, "life_timer", 0.0))
			/ maxf(_get_float_property(source, "duration", _get_float_property(source, "life_time", 0.2)), 0.01),
			0.0,
			1.0
		)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 1.0 - effect_progress
	material.emission_enabled = hit_flash > 0.0 or is_effect
	material.emission = Color.WHITE if hit_flash > 0.0 else base_color
	material.emission_energy_multiplier = 2.4 if hit_flash > 0.0 else 1.35


func _has_property(object: Object, property_name: String) -> bool:
	if not is_instance_valid(object):
		return false
	var object_id: int = object.get_instance_id()
	if property_cache.has(object_id):
		return (property_cache[object_id] as Dictionary).has(property_name)

	var property_names: Dictionary = {}
	for property_data: Dictionary in object.get_property_list():
		property_names[str(property_data.get("name", ""))] = true
	property_cache[object_id] = property_names
	return property_names.has(property_name)


func _get_float_property(source: Object, property_name: String, fallback: float) -> float:
	if not _has_property(source, property_name):
		return fallback
	return float(source.get(property_name))


func _get_bool_property(source: Object, property_name: String) -> bool:
	if not _has_property(source, property_name):
		return false
	return bool(source.get(property_name))


func _get_knockback_velocity(source: Object) -> Vector2:
	for property_name in ["knockback_velocity", "hit_knockback_velocity"]:
		if _has_property(source, property_name):
			var value: Variant = source.get(property_name)
			if typeof(value) == TYPE_VECTOR2:
				return value as Vector2
	return Vector2.ZERO


func _hide_legacy_world_visuals(node: Node) -> void:
	if node == null:
		return

	for child in node.get_children():
		if child is CanvasLayer or child is Control:
			continue

		if child is Camera2D:
			continue

		if child is CanvasItem:
			(child as CanvasItem).visible = false

		_hide_legacy_world_visuals(child)


func _make_mesh_for(source: Node2D) -> PrimitiveMesh:
	var source_name: String = source.name.to_lower()

	if source.is_in_group("player"):
		var player_mesh := CapsuleMesh.new()
		player_mesh.radius = 0.22
		player_mesh.height = 0.78
		return player_mesh

	if source.is_in_group("enemies"):
		if source.is_in_group("boss"):
			var boss_mesh := CylinderMesh.new()
			boss_mesh.top_radius = 0.72
			boss_mesh.bottom_radius = 0.86
			boss_mesh.height = 1.55
			return boss_mesh

		var kind: String = _enemy_kind(source)
		match kind:
			"chaser":
				var chaser_mesh := BoxMesh.new()
				chaser_mesh.size = Vector3(0.52, 0.72, 0.52)
				return chaser_mesh
			"spread":
				var spread_mesh := CylinderMesh.new()
				spread_mesh.top_radius = 0.34
				spread_mesh.bottom_radius = 0.40
				spread_mesh.height = 0.72
				return spread_mesh
			"shield":
				var shield_mesh := CylinderMesh.new()
				shield_mesh.top_radius = 0.27
				shield_mesh.bottom_radius = 0.31
				shield_mesh.height = 0.92
				return shield_mesh
			"charger":
				var charger_mesh := BoxMesh.new()
				charger_mesh.size = Vector3(0.82, 0.68, 0.66)
				return charger_mesh
			"suicide", "suicide_bot", "bomber":
				var explosive_mesh := SphereMesh.new()
				explosive_mesh.radius = 0.34 if kind == "bomber" else 0.29
				explosive_mesh.height = explosive_mesh.radius * 2.0
				return explosive_mesh
			"elite", "gunner_elite", "tactical_gunner":
				var elite_mesh := CapsuleMesh.new()
				elite_mesh.radius = 0.31
				elite_mesh.height = 1.05
				return elite_mesh
			_:
				var enemy_mesh := CapsuleMesh.new()
				enemy_mesh.radius = 0.25
				enemy_mesh.height = 0.86
				return enemy_mesh

	if source.is_in_group("melee_fx"):
		var melee_mesh := BoxMesh.new()
		var attack_range: float = _get_float_property(source, "attack_range", 70.0)
		melee_mesh.size = Vector3(
			maxf(attack_range * WORLD_SCALE / VISUAL_UNIT_SCALE, 0.5),
			0.08,
			0.16
		)
		return melee_mesh

	if source.is_in_group("room_fx"):
		var effect_mesh := TorusMesh.new()
		effect_mesh.inner_radius = 0.11
		effect_mesh.outer_radius = 0.18
		return effect_mesh

	if source.is_in_group("terrain_walls"):
		var terrain_mesh := BoxMesh.new()
		var wall_size := Vector2(100.0, 24.0)
		if _has_property(source, "wall_size"):
			var wall_size_value: Variant = source.get("wall_size")
			if typeof(wall_size_value) == TYPE_VECTOR2:
				wall_size = wall_size_value as Vector2
		terrain_mesh.size = Vector3(
			wall_size.x * WORLD_SCALE / VISUAL_UNIT_SCALE,
			0.82,
			wall_size.y * WORLD_SCALE / VISUAL_UNIT_SCALE
		)
		return terrain_mesh

	if (
		source.is_in_group("player_bullets")
		or source.is_in_group("player_projectiles")
		or source.is_in_group("enemy_bullets")
		or source.is_in_group("enemy_projectiles")
	):
		var projectile_mesh := SphereMesh.new()
		projectile_mesh.radius = 0.09 if "bomb" not in source_name else 0.24
		projectile_mesh.height = projectile_mesh.radius * 2.0
		return projectile_mesh

	if source.is_in_group("room_pickups"):
		var pickup_mesh := CylinderMesh.new()
		pickup_mesh.top_radius = 0.22
		pickup_mesh.bottom_radius = 0.28
		pickup_mesh.height = 0.42
		return pickup_mesh

	if source.is_in_group("room_hazards"):
		var hazard_mesh := CylinderMesh.new()
		hazard_mesh.top_radius = 0.34
		hazard_mesh.bottom_radius = 0.42
		hazard_mesh.height = 0.12
		return hazard_mesh

	if "barrel" in source_name or "pot" in source_name or "pillar" in source_name:
		var cylinder_mesh := CylinderMesh.new()
		cylinder_mesh.top_radius = 0.28
		cylinder_mesh.bottom_radius = 0.31
		cylinder_mesh.height = 0.72
		return cylinder_mesh

	var prop_mesh := BoxMesh.new()
	if "table" in source_name:
		prop_mesh.size = Vector3(1.05, 0.5, 0.62)
	elif "wall" in source_name:
		prop_mesh.size = Vector3(1.0, WALL_HEIGHT, 0.22)
	else:
		prop_mesh.size = Vector3(0.62, 0.62, 0.62)
	return prop_mesh


func _height_for(source: Node2D) -> float:
	if source.is_in_group("terrain_walls"):
		return 0.82
	if source.is_in_group("room_fx") or source.is_in_group("melee_fx"):
		return 0.08
	if source.is_in_group("player"):
		return 0.78
	if source.is_in_group("boss"):
		return 1.55
	if source.is_in_group("enemies"):
		return 0.86
	if source.is_in_group("room_hazards"):
		return 0.12
	if source.is_in_group("room_pickups"):
		return 0.42
	if source.is_in_group("room_props"):
		return 0.72
	return 0.18


func _vertical_offset_for(source: Node2D) -> float:
	if _is_damage_number(source):
		return 1.15
	if _is_weapon_pickup(source):
		return 0.0
	if source.is_in_group("room_fx") or source.is_in_group("melee_fx"):
		return 0.12
	if (
		source.is_in_group("player_bullets")
		or source.is_in_group("player_projectiles")
		or source.is_in_group("enemy_bullets")
		or source.is_in_group("enemy_projectiles")
	):
		return 0.34

	if source.is_in_group("room_pickups"):
		return 0.08 + sin(elapsed_time * 3.2 + float(source.get_instance_id() % 7)) * 0.06

	return 0.0


func _color_for(source: Node2D) -> Color:
	var source_name: String = source.name.to_lower()

	if source.is_in_group("player"):
		return Color("49b8ff")
	if source.is_in_group("melee_fx"):
		return Color("d9f7ff")
	if source.is_in_group("room_fx"):
		var fx_type: String = str(source.get("fx_type")) if _has_property(source, "fx_type") else "impact"
		match fx_type:
			"explosion":
				return Color("ff542e")
			"clear":
				return Color("58d9f2")
			"portal":
				return Color("9275ff")
			"break":
				return Color("bf7340")
		return Color("ffe08a")
	if source.is_in_group("boss"):
		return Color("b54cff")
	if source.is_in_group("enemies"):
		match _enemy_kind(source):
			"chaser":
				return Color("e94f55")
			"gunner":
				return Color("d88742")
			"spread":
				return Color("e5bf55")
			"shield":
				return Color("4e7897")
			"charger":
				return Color("b84c38")
			"suicide", "suicide_bot":
				return Color("ff4b32")
			"bomber":
				return Color("d46b2f")
			"elite", "gunner_elite", "tactical_gunner":
				return Color("b84ddd")
		return Color("ef5b65")
	if source.is_in_group("player_bullets") or source.is_in_group("player_projectiles"):
		return Color("7ef7ff")
	if source.is_in_group("enemy_bullets") or source.is_in_group("enemy_projectiles"):
		return Color("ff4a52")
	if source.is_in_group("room_hazards"):
		return Color("ff6638")
	if source.is_in_group("room_pickups"):
		return Color("ffd65a")
	if "barrel" in source_name:
		return Color("cf3e32")
	if "crate" in source_name or "table" in source_name:
		return Color("8f6846")
	return Color("8792a8")


func _make_material(
	color: Color,
	roughness: float,
	unshaded: bool = false
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.08
	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
		if unshaded
		else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	)
	return material


func _make_glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _make_material(color, 0.46, false)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _make_projectile_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _make_glow_material(color, energy)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _make_transparent_glow_material(
	color: Color,
	energy: float
) -> StandardMaterial3D:
	var material := _make_projectile_material(color, energy)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _add_projectile_halo(proxy: Node3D, color: Color) -> void:
	var halo_mesh := SphereMesh.new()
	halo_mesh.radius = 0.16
	halo_mesh.height = 0.32
	var halo := MeshInstance3D.new()
	halo.name = "ProjectileHalo3D"
	halo.mesh = halo_mesh
	var halo_color := color
	halo_color.a = 0.28
	halo.material_override = _make_transparent_glow_material(halo_color, 2.8)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	proxy.add_child(halo)

	var emission_light := OmniLight3D.new()
	emission_light.name = "ProjectileEmissionLight3D"
	emission_light.light_color = color
	emission_light.light_energy = 0.0
	emission_light.omni_range = 1.45 * VISUAL_UNIT_SCALE
	emission_light.shadow_enabled = false
	proxy.add_child(emission_light)


func _make_transparent_material(color: Color, receive_light: bool) -> StandardMaterial3D:
	var material := _make_material(color, 1.0, not receive_light)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_PER_PIXEL
		if receive_light
		else BaseMaterial3D.SHADING_MODE_UNSHADED
	)
	return material


func _set_if_property_exists(object: Object, property_name: String, value: Variant) -> void:
	if _has_property(object, property_name):
		object.set(property_name, value)


func _make_indicator_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = _make_material(color, 1.0, true)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.72
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.8
	material.no_depth_test = true
	return material
