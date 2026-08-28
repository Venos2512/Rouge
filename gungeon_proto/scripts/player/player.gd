extends CharacterBody2D

const GameInputV2 = preload(
	"res://gungeon_proto/scripts/core/game_input_runtime.gd"
)
const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)
const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)

var move_speed := 155.0
var move_acceleration: float = 2200.0
var move_deceleration: float = 2800.0
var move_turn_acceleration: float = 3600.0
var smoothed_move_velocity: Vector2 = Vector2.ZERO
var fire_interval := 0.11

var roll_speed := 360.0
var roll_duration := 0.20
var roll_cooldown := 0.42

var max_health := 5
var health := 5
@export var armor: int = 0
@export var damage_multipliers: Dictionary = {
	&"physical": 1.0,
	&"fire": 1.0,
	&"shock": 1.0,
	&"poison": 1.0,
	&"void": 1.0,
}

var room_rect := Rect2(-350, -190, 700, 380)

var aim_direction := Vector2.RIGHT
var fire_timer := 0.0

var is_rolling := false
var roll_direction := Vector2.RIGHT
var roll_time_left := 0.0
var roll_cooldown_timer := 0.0

var invulnerable_timer := 0.0
var hit_flash := 0.0

var roll_key_was_down := false
var reload_key_was_down := false
var fire_button_was_down := false
var god_mode_key_was_down := false

var god_mode: bool = true

var dead := false

var muzzle_flash_timer := 0.0

var cached_mouse_world_position: Vector2 = Vector2.ZERO
var has_cached_mouse_world_position: bool = false

var camera_shake_strength: float = 0.0
var footstep_timer: float = 0.0
var low_health_warning_played: bool = false

var melee_lunge_direction: Vector2 = Vector2.ZERO
var melee_lunge_speed: float = 0.0
var melee_lunge_time_left: float = 0.0
var melee_lunge_duration: float = 0.10
var hit_knockback_velocity: Vector2 = Vector2.ZERO

@onready var player_visual: Sprite2D = $Visual

@onready var weapon_system: Node = (
	$Systems/WeaponSystem
)

@onready var weapon_attack_controller: Node = (
	$Systems/WeaponAttackController
)

@onready var upgrade_system: Node = (
	$Systems/UpgradeSystem
)

@onready var currency_system: Node = (
	$Systems/CurrencySystem
)

@onready var weapon_label: Label = (
	$WorldWeaponLabel
)

@onready var weapon_list_label: Label = (
	get_node_or_null(
		"WeaponInventoryUI/Root/WeaponListPanel/WeaponListLabel"
	) as Label
)

@onready var weapon_list_panel: ColorRect = (
	get_node_or_null(
		"WeaponInventoryUI/Root/WeaponListPanel"
	) as ColorRect
)


func _ready() -> void:
	# Metadata dùng chung bởi carry / weapon / special systems.
	# Khởi tạo trước để Godot 4.7.2 không spam lỗi get_meta()
	# khi object chưa từng được cầm.
	if not has_meta("carried_object"):
		set_meta(
			"carried_object",
			null
		)

	if not has_meta("suppress_fire_until_release"):
		set_meta(
			"suppress_fire_until_release",
			false
		)
	z_index = 20

	add_to_group("player")

	_update_weapon_label()

	queue_redraw()


func _input(event: InputEvent) -> void:
	if (
		event is InputEventMouseMotion
		or event is InputEventMouseButton
	):
		var mouse_event: InputEventMouse = (
			event as InputEventMouse
		)

		var viewport: Viewport = get_viewport()

		if viewport != null:
			var inverse_canvas: Transform2D = (
				viewport.get_canvas_transform().affine_inverse()
			)

			cached_mouse_world_position = (
				inverse_canvas
				* mouse_event.position
			)

			has_cached_mouse_world_position = true

	if not is_instance_valid(weapon_system):
		return

	if (
		event is InputEventMouseButton
		and event.pressed
	):
		var mouse_button_event := (
			event as InputEventMouseButton
		)

		if (
			mouse_button_event.button_index
			== MOUSE_BUTTON_WHEEL_UP
		):
			weapon_system.cycle_weapon(-1)
			_update_weapon_label()

		elif (
			mouse_button_event.button_index
			== MOUSE_BUTTON_WHEEL_DOWN
		):
			weapon_system.cycle_weapon(1)
			_update_weapon_label()

	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
	):
		var key_event := event as InputEventKey

		var slot_index: int = _get_slot_from_key(
			key_event.keycode
		)

		if slot_index >= 0:
			weapon_system.equip_by_index(
				slot_index
			)

			_update_weapon_label()


func _get_slot_from_key(
	keycode: Key
) -> int:
	match keycode:
		KEY_1:
			return 0

		KEY_2:
			return 1

		KEY_3:
			return 2

		KEY_4:
			return 3

		KEY_5:
			return 4

		KEY_6:
			return 5

		KEY_7:
			return 6

		KEY_8:
			return 7

		KEY_9:
			return 8

	return -1


func add_camera_shake(
	amount: float
) -> void:
	camera_shake_strength = maxf(
		camera_shake_strength,
		amount
	)


func _update_camera_shake(
	delta: float
) -> void:
	camera_shake_strength = maxf(
		0.0,
		camera_shake_strength
		- 22.0 * delta
	)

	var camera := get_node_or_null(
		"Camera2D"
	) as Camera2D

	if not is_instance_valid(camera):
		return

	if camera_shake_strength <= 0.05:
		camera.offset = Vector2.ZERO
		return

	camera.offset = Vector2(
		randf_range(
			-camera_shake_strength,
			camera_shake_strength
		),
		randf_range(
			-camera_shake_strength,
			camera_shake_strength
		)
	)


func request_melee_lunge(
	direction: Vector2,
	distance: float
) -> void:
	if distance <= 0.0:
		return

	if is_rolling:
		return

	if direction.length_squared() <= 0.001:
		return

	melee_lunge_direction = direction.normalized()

	melee_lunge_time_left = (
		melee_lunge_duration
	)

	# Cao hơn distance / duration một chút vì
	# impulse sẽ fade dần về 0.
	melee_lunge_speed = (
		distance
		/ melee_lunge_duration
		* 1.5
	)


func apply_hit_knockback(
	source_position: Vector2,
	force: float
) -> void:
	if dead or is_rolling:
		return

	var away: Vector2 = global_position - source_position
	if away.length_squared() <= 0.001:
		return

	hit_knockback_velocity += away.normalized() * force


func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		smoothed_move_velocity = Vector2.ZERO
		return

	var god_mode_key_down: bool = Input.is_key_pressed(
		KEY_G
	)

	var god_mode_pressed: bool = (
		god_mode_key_down
		and not god_mode_key_was_down
	)

	god_mode_key_was_down = god_mode_key_down

	if god_mode_pressed:
		god_mode = not god_mode

		print(
			"GOD MODE: ",
			"ON" if god_mode else "OFF"
		)

	fire_timer = maxf(0.0, fire_timer - delta)
	roll_cooldown_timer = maxf(0.0, roll_cooldown_timer - delta)
	invulnerable_timer = maxf(0.0, invulnerable_timer - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	muzzle_flash_timer = maxf(
		0.0,
		muzzle_flash_timer - delta
	)

	if is_instance_valid(player_visual):
		if hit_flash > 0.0:
			player_visual.modulate = Color8(255, 245, 220)
		elif is_rolling:
			player_visual.modulate = Color8(140, 235, 255)
		else:
			player_visual.modulate = Color.WHITE

	weapon_attack_controller.call(
		"tick",
		delta
	)

	_update_camera_shake(
		delta
	)

	var reload_key_down: bool = Input.is_key_pressed(
		KEY_R
	)

	var reload_pressed: bool = (
		reload_key_down
		and not reload_key_was_down
	)

	reload_key_was_down = reload_key_down

	if reload_pressed:
		weapon_system.start_reload()

	_update_weapon_label()

	# Mouse aim phải được tính từ world position hiện tại
	# mỗi physics frame.
	# Không phụ thuộc MouseMotion event, vì player/camera có thể
	# di chuyển trong khi con trỏ đang đứng yên.
	var mouse_aim: Vector2 = (
		get_global_mouse_position()
		- global_position
	)

	if mouse_aim.length_squared() > 1.0:
		aim_direction = mouse_aim.normalized()

	var input_vector := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0

	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_vector.y -= 1.0

	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_vector.y += 1.0

	if input_vector.length_squared() > 0.0:
		input_vector = input_vector.normalized()

	# Keyboard và controller chạy song song. Left Stick được đọc trước
	# roll để hướng né và hướng di chuyển dùng cùng một vector analog.
	var controller_move: Vector2 = GameInputV2.get_move_vector()
	if controller_move.length_squared() > 0.001:
		input_vector = controller_move

	var roll_key_down := Input.is_key_pressed(KEY_SPACE)
	var roll_pressed := roll_key_down and not roll_key_was_down

	roll_key_was_down = roll_key_down

	if (
		roll_pressed
		and not is_rolling
		and roll_cooldown_timer <= 0.0
	):
		if input_vector.length_squared() > 0.0:
			roll_direction = input_vector
		else:
			roll_direction = aim_direction

		is_rolling = true
		smoothed_move_velocity = Vector2.ZERO
		GameAudio.play(self, "player_roll_start")
		roll_time_left = roll_duration
		roll_cooldown_timer = roll_cooldown

	if is_rolling:
		melee_lunge_time_left = 0.0
		melee_lunge_speed = 0.0

		roll_time_left -= delta

		velocity = roll_direction * roll_speed

		move_and_slide()

		_clamp_to_room()

		if roll_time_left <= 0.0:
			is_rolling = false
			GameAudio.play(self, "player_roll_end")

		queue_redraw()
		return

	var target_move_velocity: Vector2 = input_vector * move_speed
	var smoothing_rate: float = move_acceleration
	if input_vector.length_squared() <= 0.001:
		smoothing_rate = move_deceleration
	elif (
		smoothed_move_velocity.length_squared() > 1.0
		and smoothed_move_velocity.normalized().dot(input_vector.normalized())
		< 0.82
	):
		smoothing_rate = move_turn_acceleration

	# Velocity tiến dần tới hướng input mới thay vì đổi vector tức thì.
	# Khi chuyển từ ngang sang dọc, quỹ đạo sẽ bo thành cung ngắn thay
	# vì gãy góc; analog stick vẫn giữ đầy đủ độ lớn đầu vào.
	smoothed_move_velocity = smoothed_move_velocity.move_toward(
		target_move_velocity,
		smoothing_rate * delta
	)

	var movement_velocity: Vector2 = smoothed_move_velocity

	if hit_knockback_velocity.length_squared() > 1.0:
		movement_velocity += hit_knockback_velocity
		hit_knockback_velocity = hit_knockback_velocity.move_toward(
			Vector2.ZERO,
			920.0 * delta
		)
	else:
		hit_knockback_velocity = Vector2.ZERO

	if melee_lunge_time_left > 0.0:
		var lunge_weight: float = clampf(
			melee_lunge_time_left
			/ melee_lunge_duration,
			0.0,
			1.0
		)

		movement_velocity += (
			melee_lunge_direction
			* melee_lunge_speed
			* lunge_weight
		)

		melee_lunge_time_left = maxf(
			0.0,
			melee_lunge_time_left - delta
		)

		if melee_lunge_time_left <= 0.0:
			melee_lunge_speed = 0.0

	velocity = movement_velocity

	move_and_slide()

	_clamp_to_room()

	if smoothed_move_velocity.length_squared() > 16.0:
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			GameAudio.play(self, "player_footstep", 0.075)
			footstep_timer = 0.28
	else:
		footstep_timer = 0.0

	# Right Stick chỉ override hướng ngắm khi stick thực sự được đẩy.
	# Khi thả stick, mouse vẫn tiếp tục hoạt động bình thường.
	var controller_aim: Vector2 = (
		GameInputV2.get_aim_vector()
	)

	if controller_aim.length_squared() > 0.001:
		aim_direction = (
			controller_aim.normalized()
		)

	var fire_button_down: bool = (
		GameInputV2.attack_pressed()
	)

	var carried_value: Variant = null

	if has_meta(
		"carried_object"
	):
		carried_value = get_meta(
			"carried_object"
		)

	var carrying_object: bool = (
		carried_value != null
		and typeof(
			carried_value
		) == TYPE_OBJECT
		and is_instance_valid(
			carried_value
		)
	)

	var suppress_fire: bool = bool(
		get_meta(
			"suppress_fire_until_release",
			false
		)
	)

	# Sau khi LMB được dùng để ném object,
	# không cho súng bắn cho tới khi người chơi
	# nhả nút chuột hoàn toàn.
	if (
		suppress_fire
		and not fire_button_down
	):
		remove_meta(
			"suppress_fire_until_release"
		)

		suppress_fire = false

	var weapon: Dictionary = (
		weapon_system.get_current_weapon()
	)

	var wants_fire: bool = false

	if (
		not carrying_object
		and not suppress_fire
	):
		if bool(weapon["automatic"]):
			wants_fire = fire_button_down
		else:
			wants_fire = (
				fire_button_down
				and not fire_button_was_down
			)

	if wants_fire and fire_timer <= 0.0:
		_shoot()

	fire_button_was_down = fire_button_down

	_update_weapon_label()

	queue_redraw()


func _clamp_to_room() -> void:
	position.x = clampf(
		position.x,
		room_rect.position.x,
		room_rect.end.x
	)

	position.y = clampf(
		position.y,
		room_rect.position.y,
		room_rect.end.y
	)


func add_gold(amount: int) -> void:
	if not is_instance_valid(currency_system):
		return

	currency_system.call(
		"add_gold",
		amount
	)


func get_gold() -> int:
	if not is_instance_valid(currency_system):
		return 0

	return int(
		currency_system.get("gold")
	)


func spend_gold(amount: int) -> bool:
	if not is_instance_valid(currency_system):
		return false

	return bool(
		currency_system.call(
			"spend_gold",
			amount
		)
	)


func receive_damage(info: RefCounted) -> RefCounted:
	var result: RefCounted = DamageResolverScript.resolve_amount(
		self,
		info,
		damage_multipliers,
		armor
	)
	if (
		result.blocked
		or dead
		or god_mode
		or is_rolling
		or invulnerable_timer > 0.0
	):
		result.blocked = true
		result.final_amount = 0
		return result

	var health_before: int = health
	take_damage(result.final_amount)
	result.killed = health_before > 0 and health <= 0
	return result


func take_damage(amount: int) -> void:
	if dead:
		return

	if god_mode:
		return

	if is_rolling:
		return

	if invulnerable_timer > 0.0:
		return

	health -= amount
	GameAudio.play(self, "player_hurt")
	if health <= 2 and not low_health_warning_played:
		low_health_warning_played = true
		GameAudio.play(self, "player_low_health", 0.0)

	invulnerable_timer = 0.75
	hit_flash = 0.12

	var scene: Node = (
		get_tree().current_scene
	)

	if scene.has_method(
		"spawn_damage_number"
	):
		scene.call(
			"spawn_damage_number",
			global_position + Vector2(0, -24),
			amount,
			true
		)

	if scene.has_method(
		"spawn_room_fx"
	):
		scene.call(
			"spawn_room_fx",
			global_position,
			"impact"
		)

	if scene.has_method(
		"request_camera_shake"
	):
		scene.call(
			"request_camera_shake",
			6.0
		)

	if scene.has_method(
		"request_hit_stop"
	):
		scene.call(
			"request_hit_stop",
			0.045,
			0.12
		)

	if health <= 0:
		_die()

	queue_redraw()


func _die() -> void:
	dead = true
	GameAudio.play(self, "player_death", 0.0)
	velocity = Vector2.ZERO

	var scene: Node = (
		get_tree().current_scene
	)

	if scene.has_method(
		"spawn_room_fx"
	):
		scene.call(
			"spawn_room_fx",
			global_position,
			"death"
		)

	if scene.has_method(
		"request_camera_shake"
	):
		scene.call(
			"request_camera_shake",
			10.0
		)

	await get_tree().create_timer(0.8).timeout

	get_tree().reload_current_scene()


func _shoot() -> void:
	var result: Dictionary = weapon_attack_controller.call(
		"attack_current",
		self,
		weapon_system,
		aim_direction,
		god_mode
	)

	if not bool(
		result.get(
			"performed",
			false
		)
	):
		var current_weapon: Dictionary = weapon_system.call(
			"get_current_weapon"
		)
		if bool(current_weapon.get("uses_ammo", true)):
			GameAudio.play(self, "gun_dry_fire", 0.02)
		return

	var weapon_id: String = str(
		weapon_system.get("current_weapon")
	)
	match weapon_id:
		"pistol":
			GameAudio.play(self, "pistol_fire", 0.035)
		"machine_gun":
			GameAudio.play(self, "machine_gun_fire", 0.025)
		"shotgun":
			GameAudio.play(self, "shotgun_fire", 0.02)
		"grenade_launcher":
			GameAudio.play(self, "shotgun_fire", 0.02)

	fire_timer = float(
		result.get(
			"cooldown",
			0.2
		)
	)

	var recoil: float = float(
		result.get(
			"recoil",
			0.0
		)
	)

	position -= aim_direction * recoil

	_clamp_to_room()

	muzzle_flash_timer = float(
		result.get(
			"muzzle_flash",
			0.0
		)
	)

	_update_weapon_label()




func equip_weapon_pickup(
	weapon_id: String
) -> void:
	weapon_system.unlock_and_equip(
		weapon_id
	)

	_update_weapon_label()

	print(
		"Picked up: ",
		weapon_system.get_weapon_name()
	)


func _update_weapon_label() -> void:
	if not is_instance_valid(weapon_label):
		return

	if not is_instance_valid(weapon_system):
		return

	var weapon_name: String = (
		weapon_system.get_weapon_name()
	)

	var weapon: Dictionary = (
		weapon_system.get_current_weapon()
	)

	if not bool(weapon.get("uses_ammo", true)):
		weapon_label.text = (
			weapon_name
			+ "  MELEE"
		)

	elif weapon_system.reloading:
		weapon_label.text = (
			weapon_name
			+ "  RELOAD..."
		)

	else:
		weapon_label.text = (
			weapon_name
			+ "  "
			+ str(
				weapon_system.get_ammo_in_mag()
			)
			+ "/"
			+ str(
				weapon_system.get_reserve_ammo()
			)
		)

	_update_weapon_list()


func _update_weapon_list() -> void:
	if not is_instance_valid(weapon_list_label):
		return

	if not is_instance_valid(weapon_system):
		return

	var order: Array[String] = (
		weapon_system.get_weapon_order()
	)

	var current_weapon_id: String = str(
		weapon_system.current_weapon
	)

	var list_text := "WEAPONS\n"

	for i in range(order.size()):
		var weapon_id: String = order[i]

		if not weapon_system.weapons.has(
			weapon_id
		):
			continue

		var weapon: Dictionary = (
			weapon_system.weapons[
				weapon_id
			]
		)

		var marker := "  "

		if weapon_id == current_weapon_id:
			marker = "> "

		var slot_text := (
			"["
			+ str(i + 1)
			+ "] "
		)

		var weapon_name: String = str(
			weapon["name"]
		)

		var status_text := ""

		if str(
			weapon.get(
				"type",
				"ranged"
			)
		) == "melee":
			status_text = "MELEE"

		else:
			status_text = (
				str(
					weapon_system.ammo[
						weapon_id
					]
				)
				+ "/"
				+ str(
					weapon_system.reserve_ammo[
						weapon_id
					]
				)
			)

		list_text += (
			marker
			+ slot_text
			+ weapon_name
			+ "  "
			+ status_text
			+ "\n"
		)

	weapon_list_label.text = list_text


func _draw() -> void:
	if is_instance_valid(weapon_attack_controller):
		weapon_attack_controller.call(
			"draw_current",
			self,
			weapon_system,
			aim_direction
		)

	# Small aiming marker.
	var crosshair := aim_direction * 30.0

	draw_rect(
		Rect2(
			crosshair - Vector2(2, 2),
			Vector2(4, 4)
		),
		Color8(244, 230, 140),
		false,
		1.0
	)

	# God mode indicator.
	if god_mode:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(-16, -23),
			"GOD",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			8,
			Color8(255, 225, 80)
		)

	# Health pips.
	for i in range(max_health):
		var health_color := Color8(55, 45, 48)

		if i < health:
			health_color = Color8(232, 70, 80)

		draw_rect(
			Rect2(
				-10 + i * 5,
				-17,
				4,
				3
			),
			health_color,
			true
		)
