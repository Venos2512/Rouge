extends SceneTree


const MAIN_SCENE_PATH := "res://gungeon_proto/main.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		failures.append("Không tải được main scene 3D.")
		_finish(failures)
		return

	var change_error: Error = change_scene_to_packed(packed)
	if change_error != OK:
		failures.append("Không chuyển được sang main scene 3D: %s" % change_error)
		_finish(failures)
		return

	for frame_index in range(5):
		await process_frame
	paused = false
	for frame_index in range(60):
		var loading_scene: Node = current_scene
		if (
			is_instance_valid(loading_scene)
			and typeof(loading_scene.get("rooms")) == TYPE_DICTIONARY
			and (loading_scene.get("rooms") as Dictionary).size() > 1
		):
			break
		await process_frame
	if (
		is_instance_valid(current_scene)
		and (current_scene.get("rooms") as Dictionary).is_empty()
	):
		current_scene.call("_start_floor")
		for frame_index in range(10):
			await process_frame

	var scene: Node = current_scene
	if not (scene is Node3D):
		failures.append("Root của main scene phải là Node3D.")

	var presenter := scene.get_node_or_null("Planar3DPresenter")
	if not (presenter is Node3D):
		failures.append("Thiếu Planar3DPresenter.")
	else:
		var camera := presenter.get_node_or_null("TopDownCamera3D")
		if not (camera is Camera3D) or not (camera as Camera3D).current:
			failures.append("Camera3D top-down chưa hoạt động.")
		elif absf((camera as Camera3D).rotation_degrees.x + 90.0) < 1.0:
			failures.append("Camera3D vẫn nhìn thẳng đứng, chưa có góc nghiêng.")

		var proxy_root := presenter.get_node_or_null("GameplayProxies")
		if not (proxy_root is Node3D):
			failures.append("Thiếu root chứa proxy gameplay 3D.")
		elif proxy_root.get_child_count() < 1:
			failures.append("Player chưa có proxy 3D sau 5 frame.")
		else:
			_validate_lookdev_nodes(presenter, failures)
			_validate_floor_weapon_pickup(scene, presenter, failures)
			_validate_mouse_projection(scene, presenter, failures)
			_validate_visible_door_alignment(scene, presenter, failures)
			_validate_player_weapon(scene, presenter, failures)
			_validate_screen_shake(scene, presenter, failures)
			_validate_combat_readability(scene, presenter, failures)
			await _validate_terrain_wall_visibility(presenter, failures)
			await _validate_many_proxy_lifecycle(scene, presenter, proxy_root, failures)
			await _validate_room_transition(scene, presenter, failures)

	var player := get_first_node_in_group("player") as Node2D
	if player == null:
		failures.append("Player 2D dùng làm mô phỏng không tồn tại.")
	elif player.visible:
		failures.append("Canvas gameplay cũ của player chưa được ẩn.")

	_finish(failures)


func _validate_player_weapon(
	scene: Node,
	presenter: Node,
	failures: Array[String]
) -> void:
	var player: Node2D = scene.get("player") as Node2D
	var proxy_map: Dictionary = presenter.get("proxies") as Dictionary
	if player == null or not proxy_map.has(player.get_instance_id()):
		failures.append("Player không có proxy để kiểm tra vũ khí 3D.")
		return
	var player_proxy := proxy_map[player.get_instance_id()] as Node3D
	var actor_model := player_proxy.get_node_or_null("ActorModel3D") as Node3D
	if (
		not is_instance_valid(actor_model)
		or actor_model.get_node_or_null("BodyCapsule") == null
		or actor_model.get_node_or_null("FaceDirection3D") == null
	):
		failures.append("Player chưa dùng capsule và box chỉ hướng.")
	var weapon_root := player_proxy.get_node_or_null("HeldWeapon3D") as Node3D
	if not is_instance_valid(weapon_root) or weapon_root.get_child_count() < 1:
		failures.append("Vũ khí đang trang bị chưa có mesh 3D.")
	elif weapon_root.get_node_or_null("WeaponModel3D") == null:
		failures.append("Vũ khí đang trang bị chưa dùng model FBX mới.")
	elif weapon_root.get_node_or_null("MuzzleLight") == null:
		failures.append("Vũ khí ranged chưa có muzzle light 3D.")
	presenter.call("_rebuild_weapon_mesh", weapon_root, "laser_rifle")
	if weapon_root.get_node_or_null("LaserBeam3D") == null:
		failures.append("Laser Rifle dùng model FBX nhưng chưa có beam 3D.")
	presenter.call("_rebuild_weapon_mesh", weapon_root, "sword")
	if weapon_root.get_node_or_null("SwordTrail3D") == null:
		failures.append("Sword dùng model FBX nhưng chưa có arc trail 3D.")
	if player_proxy.get_node_or_null("ContactShadow3D") == null:
		failures.append("Player model chưa có contact shadow.")
	if player_proxy.get_node_or_null("HitGlow3D") == null:
		failures.append("Player model chưa có hit glow.")


func _validate_lookdev_nodes(presenter: Node, failures: Array[String]) -> void:
	if presenter.get_node_or_null("WorldEnvironment") == null:
		failures.append("Lookdev 3D thiếu WorldEnvironment.")
	if presenter.get_node_or_null("KeyLight") == null or presenter.get_node_or_null("RimLight") == null:
		failures.append("Lookdev 3D thiếu key/rim lighting.")
	if presenter.get_node_or_null("PlayerFillLight") == null:
		failures.append("Lookdev 3D thiếu player fill light.")
	var room_root := presenter.get_node_or_null("RoomGeometry3D") as Node3D
	var accent_count := 0
	if is_instance_valid(room_root):
		for child in room_root.get_children():
			if child is OmniLight3D:
				accent_count += 1
	if accent_count != 4:
		failures.append("Phòng 3D phải có đúng 4 accent lights, hiện có %d." % accent_count)


func _validate_floor_weapon_pickup(
	scene: Node,
	presenter: Node,
	failures: Array[String]
) -> void:
	var pickup_scene := load("res://gungeon_proto/scenes/weapons/weapon_pickup.tscn") as PackedScene
	if pickup_scene == null:
		failures.append("Không tải được weapon pickup để kiểm tra model trên sàn.")
		return
	var pickup := pickup_scene.instantiate() as Node2D
	pickup.process_mode = Node.PROCESS_MODE_DISABLED
	pickup.set("weapon_id", "shotgun")
	pickup.position = Vector2(-100.0, 45.0)
	scene.add_child(pickup)
	presenter.call("_discover_sources")
	presenter.call("_sync_proxies", 0.0, true)
	var proxy_map: Dictionary = presenter.get("proxies") as Dictionary
	var pickup_proxy := proxy_map.get(pickup.get_instance_id()) as Node3D
	if not is_instance_valid(pickup_proxy):
		failures.append("Weapon pickup chưa có proxy 3D.")
	else:
		var floor_weapon := pickup_proxy.get_node_or_null("FloorWeapon3D") as Node3D
		if not is_instance_valid(floor_weapon):
			failures.append("Weapon pickup chưa hiển thị model trên mặt sàn.")
		elif floor_weapon.get_node_or_null("WeaponModel3D") == null:
			failures.append("Weapon pickup chưa dùng FBX đúng theo weapon_id.")
		var fallback_mesh := pickup_proxy.get_node_or_null("Mesh") as MeshInstance3D
		if is_instance_valid(fallback_mesh) and fallback_mesh.visible:
			failures.append("Weapon pickup vẫn hiện cylinder fallback cùng model súng.")
	pickup.free()
	presenter.call("_discover_sources")


func _validate_screen_shake(
	scene: Node,
	presenter: Node,
	failures: Array[String]
) -> void:
	var player: Node2D = scene.get("player") as Node2D
	var legacy_camera := player.get_node_or_null("Camera2D") as Camera2D
	var camera_3d := presenter.get_node_or_null("TopDownCamera3D") as Camera3D
	if not is_instance_valid(legacy_camera) or not is_instance_valid(camera_3d):
		failures.append("Thiếu camera để kiểm tra screen shake 3D.")
		return
	legacy_camera.offset = Vector2(10.0, -6.0)
	presenter.call("_sync_camera", 1.0 / 60.0, false)
	var smooth_position: Vector3 = presenter.get("smoothed_camera_position") as Vector3
	var shake_delta: Vector3 = camera_3d.position - smooth_position
	if Vector2(shake_delta.x, shake_delta.z).length() < 0.1:
		failures.append("Screen shake 2D chưa truyền sang camera 3D.")
	legacy_camera.offset = Vector2.ZERO


func _validate_combat_readability(
	scene: Node,
	presenter: Node,
	failures: Array[String]
) -> void:
	var shield_scene := load("res://gungeon_proto/scenes/enemies/shield.tscn") as PackedScene
	if shield_scene == null:
		failures.append("Không tải được Shield để kiểm tra presentation 3D.")
		return
	var shield := shield_scene.instantiate() as Node2D
	shield.process_mode = Node.PROCESS_MODE_DISABLED
	shield.position = Vector2(120.0, 40.0)
	scene.add_child(shield)
	shield.set("spawn_timer", 0.0)
	presenter.call("_discover_sources")
	presenter.call("_sync_proxies", 0.0, true)

	var proxy_map: Dictionary = presenter.get("proxies") as Dictionary
	var shield_proxy := proxy_map.get(shield.get_instance_id()) as Node3D
	if not is_instance_valid(shield_proxy):
		failures.append("Shield không có proxy 3D.")
	else:
		var health_bar := shield_proxy.get_node_or_null("HealthBar3D") as Node3D
		if not is_instance_valid(health_bar) or not health_bar.visible:
			failures.append("Enemy chưa hiện health bar 3D.")
		elif (
			(health_bar.get_node_or_null("Fill") as Node3D).position.z
			<= (health_bar.get_node_or_null("Background") as Node3D).position.z
		):
			failures.append("Fill health bar đang bị background che khỏi camera.")
		var shield_actor := shield_proxy.get_node_or_null("ActorModel3D") as Node3D
		if (
			not is_instance_valid(shield_actor)
			or shield_actor.get_node_or_null("BodyCapsule") == null
			or shield_actor.get_node_or_null("FaceDirection3D") == null
		):
			failures.append("Shield enemy chưa dùng capsule và box chỉ hướng.")
		shield.set("bash_windup_timer", 0.5)
		presenter.call("_sync_proxies", 0.0, true)
		var indicator := shield_proxy.get_node_or_null("Indicator3D") as Node3D
		if not is_instance_valid(indicator) or not indicator.visible:
			failures.append("Shield wind-up chưa hiện indicator 3D.")

	var damage_scene := load("res://gungeon_proto/scenes/gameplay/damage_number.tscn") as PackedScene
	if damage_scene == null:
		failures.append("Không tải được damage number để kiểm tra billboard.")
	else:
		var damage_number := damage_scene.instantiate() as Node2D
		damage_number.process_mode = Node.PROCESS_MODE_DISABLED
		damage_number.set("amount", 17)
		damage_number.position = Vector2(80.0, -20.0)
		scene.add_child(damage_number)
		presenter.call("_discover_sources")
		presenter.call("_sync_proxies", 0.0, true)
		proxy_map = presenter.get("proxies") as Dictionary
		var damage_proxy := proxy_map.get(damage_number.get_instance_id()) as Node3D
		var damage_label := damage_proxy.get_node_or_null("DamageLabel") as Label3D if is_instance_valid(damage_proxy) else null
		var camera := presenter.get_node_or_null("TopDownCamera3D") as Camera3D
		if not is_instance_valid(damage_label):
			failures.append("Damage number chưa có Label3D.")
		elif not damage_label.top_level or absf(damage_label.global_basis.z.dot(camera.global_basis.z)) < 0.99:
			failures.append("Damage number 3D chưa luôn hướng theo camera.")
		damage_number.free()

	shield.free()
	presenter.call("_discover_sources")


func _validate_terrain_wall_visibility(
	presenter: Node,
	failures: Array[String]
) -> void:
	presenter.set("scan_timer", 0.0)
	await process_frame
	await process_frame
	var proxy_map: Dictionary = presenter.get("proxies") as Dictionary
	for wall in get_nodes_in_group("terrain_walls"):
		if not proxy_map.has(wall.get_instance_id()):
			failures.append("Terrain wall có collision nhưng không có mesh 3D.")
			break


func _validate_mouse_projection(
	scene: Node,
	presenter: Node,
	failures: Array[String]
) -> void:
	var viewport_size: Vector2 = root.get_visible_rect().size
	var projected: Variant = presenter.call("screen_to_gameplay", viewport_size * 0.5)
	var player: Node2D = scene.get("player") as Node2D
	if typeof(projected) != TYPE_VECTOR2 or player == null:
		failures.append("Không chiếu được chuột từ camera nghiêng xuống gameplay.")
		return
	var expected_focus: Vector2 = player.global_position
	var aim_value: Variant = player.get("aim_direction")
	if typeof(aim_value) == TYPE_VECTOR2:
		expected_focus += (aim_value as Vector2) * 18.0
	if (projected as Vector2).distance_to(expected_focus) > 3.0:
		failures.append("Tâm camera nghiêng không khớp look-ahead gameplay.")


func _validate_visible_door_alignment(
	scene: Node,
	presenter: Node,
	failures: Array[String]
) -> void:
	var rooms: Dictionary = scene.get("rooms") as Dictionary
	var current_room: Vector2i = scene.get("current_room") as Vector2i
	var door_meshes: Dictionary = presenter.get("door_meshes") as Dictionary
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if not rooms.has(current_room + direction):
			continue
		if not door_meshes.has(direction):
			failures.append("Thiếu cửa 3D cho phòng kề hướng %s." % direction)
			continue
		var expected_offset: float = float(presenter.call("_get_door_offset", scene, direction)) * 1.0
		var door := door_meshes[direction] as Node3D
		var actual_offset: float = door.position.x if direction.y != 0 else door.position.z
		if absf(actual_offset - expected_offset) > 0.01:
			failures.append("Cửa 3D lệch khỏi cửa gameplay hướng %s." % direction)


func _validate_room_transition(
	scene: Node,
	presenter: Node,
	failures: Array[String]
) -> void:
	var rooms: Dictionary = scene.get("rooms") as Dictionary
	var from_room: Vector2i = scene.get("current_room") as Vector2i
	var direction := Vector2i.ZERO
	for candidate in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if not rooms.has(from_room + candidate):
			continue
		var target_data: Dictionary = rooms[from_room + candidate]
		if str(target_data.get("type", "combat")) in ["combat", "elite", "boss"]:
			direction = candidate
			break
	for candidate in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if direction != Vector2i.ZERO:
			break
		if rooms.has(from_room + candidate):
			direction = candidate
			break
	if direction == Vector2i.ZERO:
		failures.append(
			"Dungeon test không có phòng kề từ %s; rooms=%s."
			% [from_room, rooms.keys()]
		)
		return

	scene.set("room_cleared", true)
	var moved: bool = bool(scene.call("_try_move_room", direction))
	await process_frame
	await process_frame
	if not moved or (scene.get("current_room") as Vector2i) != from_room + direction:
		failures.append("Không chuyển qua được cửa sang phòng kề.")
		return

	var entered_data: Dictionary = rooms[from_room + direction]
	if str(entered_data.get("type", "combat")) not in ["combat", "elite", "boss"]:
		return

	for frame_index in range(180):
		if get_node_count_in_group("enemies") > 0:
			break
		await process_frame

	presenter.set("scan_timer", 0.0)
	await process_frame
	await process_frame
	var real_enemies: Array[Node] = get_nodes_in_group("enemies")
	if real_enemies.is_empty():
		failures.append("Encounter thật không spawn enemy trong phòng combat.")
		return

	var proxy_map: Dictionary = presenter.get("proxies") as Dictionary
	for enemy in real_enemies:
		if not proxy_map.has(enemy.get_instance_id()):
			failures.append("Enemy thật đã spawn nhưng không có mesh 3D.")
			break

	var knockback_enemy := real_enemies[0] as Node2D
	var player := scene.get("player") as Node2D
	if (
		is_instance_valid(knockback_enemy)
		and is_instance_valid(player)
		and knockback_enemy.has_method("apply_hit_knockback")
	):
		for frame_index in range(35):
			await physics_frame
		var before_position: Vector2 = knockback_enemy.global_position
		var source_position: Vector2 = player.global_position
		if source_position.distance_squared_to(before_position) <= 1.0:
			source_position = before_position - Vector2.RIGHT * 20.0
		knockback_enemy.call("apply_hit_knockback", source_position, 300.0)
		for frame_index in range(5):
			await physics_frame
		var away: Vector2 = (before_position - source_position).normalized()
		var displacement: Vector2 = knockback_enemy.global_position - before_position
		if displacement.dot(away) <= 0.5:
			failures.append(
				"Enemy %s nhận hit nhưng không dịch chuyển theo knockback; displacement=%s velocity=%s."
				% [
					knockback_enemy.name,
					displacement,
					knockback_enemy.get("knockback_velocity"),
				]
			)


func _validate_many_proxy_lifecycle(
	scene: Node,
	presenter: Node,
	proxy_root: Node3D,
	failures: Array[String]
) -> void:
	paused = false
	var dummy_sources: Array[Node2D] = []
	var dummy_ids: Array[int] = []

	for index in range(64):
		var dummy := Node2D.new()
		dummy.name = "LoadTestEnemy%02d" % index
		dummy.add_to_group("enemies")
		dummy.position = Vector2(index * 2.0, index * 1.5)
		scene.add_child(dummy)
		dummy_sources.append(dummy)
		dummy_ids.append(dummy.get_instance_id())

	presenter.set("scan_timer", 0.0)
	await process_frame
	await process_frame

	var proxy_map: Dictionary = presenter.get("proxies") as Dictionary
	for dummy_id in dummy_ids:
		if not proxy_map.has(dummy_id):
			failures.append("Presenter không tạo đủ proxy khi có nhiều enemy.")
			break

	for dummy in dummy_sources:
		dummy.free()

	presenter.set("scan_timer", 0.0)
	await process_frame
	await process_frame

	proxy_map = presenter.get("proxies") as Dictionary
	for dummy_id in dummy_ids:
		if proxy_map.has(dummy_id):
			failures.append("Proxy 3D không được giải phóng cùng gameplay source.")
			break


func _finish(failures: Array[String]) -> void:
	if is_instance_valid(current_scene):
		current_scene.free()
	for frame_index in range(3):
		await process_frame

	if failures.is_empty():
		print("TOP_DOWN_3D_SMOKE_TEST_OK")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
