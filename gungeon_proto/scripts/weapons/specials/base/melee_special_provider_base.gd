extends "res://gungeon_proto/scripts/weapons/specials/base/weapon_special_provider.gd"

const ProgressScript = preload(
	"res://gungeon_proto/scripts/ui/weapon_special_progress.gd"
)

const GameInputV2 = preload(
	"res://gungeon_proto/scripts/core/game_input_runtime.gd"
)

const HammerSpinFxScript = preload(
	"res://gungeon_proto/scripts/weapons/melee/hammer_spin_fx.gd"
)

const HammerAirborneActorScript = preload(
	"res://gungeon_proto/scripts/weapons/melee/hammer_airborne_actor.gd"
)

const SpearProjectileScript = preload(
	"res://gungeon_proto/scripts/weapons/projectiles/spear_special_projectile.gd"
)

const ParryCounterProjectileScript = preload(
	"res://gungeon_proto/scripts/weapons/projectiles/parry_counter_projectile.gd"
)

const Milestone14FxScript = preload(
	"res://gungeon_proto/scripts/weapons/melee/milestone14_fx.gd"
)

const SpecialRouter = preload(
	"res://gungeon_proto/scripts/weapons/specials/weapon_special_router.gd"
)


const PARRY_WINDOW: float = 0.16
const PARRY_MISS_PENALTY: float = 0.75

const SPEAR_MAX_CHARGE: float = 1.35

const HAMMER_MAX_CHARGE: float = 1.50


var player: Node2D = null

var progress_bar: Node2D = null
var hammer_spin_fx: Node2D = null

var rmb_was_down: bool = false

var active_weapon_id: String = ""

var parry_active: bool = false
var parry_timer: float = 0.0
var parry_penalty_timer: float = 0.0

var spear_charging: bool = false
var spear_charge_time: float = 0.0

var hammer_charging: bool = false
var hammer_charge_time: float = 0.0

var provider_active: bool = false


func _ready() -> void:
	set_process(
		false
	)


func setup(
	player_node: Node2D
) -> void:
	player = player_node

	if is_instance_valid(
		player
	):
		_create_helper_nodes()


func set_special_active(
	is_active: bool
) -> void:
	if provider_active == is_active:
		return

	provider_active = is_active

	if not provider_active:
		_cancel_special()

	rmb_was_down = GameInputV2.special_pressed()
	set_process(
		provider_active
	)


func get_supported_weapon_ids() -> Array[String]:
	return []


func _process(
	delta: float
) -> void:
	if not is_instance_valid(
		player
	):
		_find_player()

		if not is_instance_valid(
			player
		):
			return

	parry_penalty_timer = maxf(
		0.0,
		parry_penalty_timer - delta
	)

	var weapon: Dictionary = (
		_get_current_weapon()
	)

	if weapon.is_empty():
		_cancel_special()
		return

	var weapon_id: String = (
		_get_special_weapon_id(
			weapon
		)
	)

	if (
		not active_weapon_id.is_empty()
		and weapon_id != active_weapon_id
	):
		_cancel_special()

	active_weapon_id = weapon_id

	var rmb_down: bool = (
		GameInputV2.special_pressed()
	)

	var rmb_pressed: bool = (
		rmb_down
		and not rmb_was_down
	)

	var rmb_released: bool = (
		not rmb_down
		and rmb_was_down
	)

	if parry_active:
		_update_parry(
			delta
		)

	SpecialRouter.process(
		self,
		weapon_id,
		rmb_pressed,
		rmb_released,
		delta
	)

	rmb_was_down = rmb_down


# Optional lifecycle hook overridden by the sword provider.
func _update_parry(
	_delta: float
) -> void:
	parry_active = false


func _find_player() -> void:
	var player_value: Node = (
		get_tree().get_first_node_in_group(
			"player"
		)
	)

	if not is_instance_valid(
		player_value
	):
		return

	player = (
		player_value as Node2D
	)

	if not is_instance_valid(
		player
	):
		return

	_create_helper_nodes()


func _create_helper_nodes() -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	if not is_instance_valid(
		progress_bar
	):
		progress_bar = (
			ProgressScript.new()
			as Node2D
		)

		scene.add_child(
			progress_bar
		)

		progress_bar.call(
			"set_target",
			player
		)

	if (
		get_supported_weapon_ids().has(
			"hammer"
		)
		and not is_instance_valid(
			hammer_spin_fx
		)
	):
		hammer_spin_fx = (
			HammerSpinFxScript.new()
			as Node2D
		)

		scene.add_child(
			hammer_spin_fx
		)

		hammer_spin_fx.call(
			"set_target",
			player
		)


func _get_current_weapon() -> Dictionary:
	var weapon_system: Object = (
		_get_weapon_system()
	)

	if not is_instance_valid(
		weapon_system
	):
		return {}

	if not weapon_system.has_method(
		"get_current_weapon"
	):
		return {}

	var weapon_value: Variant = (
		weapon_system.call(
			"get_current_weapon"
		)
	)

	if typeof(
		weapon_value
	) != TYPE_DICTIONARY:
		return {}

	return weapon_value as Dictionary


func _get_special_weapon_id(
	weapon: Dictionary
) -> String:
	var weapon_name: String = str(
		weapon.get(
			"name",
			""
		)
	).to_lower()

	var style: String = str(
		weapon.get(
			"melee_style",
			""
		)
	).to_lower()

	if (
		"sword" in weapon_name
		or style == "slash"
	):
		return "sword"

	if (
		"spear" in weapon_name
		or style == "thrust"
	):
		return "spear"

	if (
		"hammer" in weapon_name
		or style == "smash"
	):
		return "hammer"

	return ""


func _cancel_special() -> void:
	parry_active = false

	spear_charging = false
	spear_charge_time = 0.0

	hammer_charging = false
	hammer_charge_time = 0.0

	active_weapon_id = ""

	_hide_progress()

	if is_instance_valid(
		hammer_spin_fx
	):
		hammer_spin_fx.call(
			"set_active",
			false
		)


func _show_progress(
	value: float
) -> void:
	if not is_instance_valid(
		progress_bar
	):
		return

	progress_bar.call(
		"show_progress",
		value
	)


func _hide_progress() -> void:
	if not is_instance_valid(
		progress_bar
	):
		return

	progress_bar.call(
		"hide_progress"
	)


func _block_normal_attack(
	duration: float
) -> void:
	if not _has_property(
		player,
		"fire_timer"
	):
		return

	var current_value: float = float(
		player.get(
			"fire_timer"
		)
	)

	player.set(
		"fire_timer",
		maxf(
			current_value,
			duration
		)
	)


func _get_aim_direction() -> Vector2:
	if _has_property(
		player,
		"aim_direction"
	):
		var aim_value: Variant = player.get(
			"aim_direction"
		)

		if typeof(
			aim_value
		) == TYPE_VECTOR2:
			var result: Vector2 = (
				aim_value
			)

			if result.length_squared() > 0.001:
				return result.normalized()

	var mouse_direction: Vector2 = (
		player.get_global_mouse_position()
		- player.global_position
	)

	if mouse_direction.length_squared() > 0.001:
		return mouse_direction.normalized()

	return Vector2.RIGHT


func _get_weapon_system() -> Object:
	if not _has_property(
		player,
		"weapon_system"
	):
		return null

	var weapon_system_value: Variant = (
		player.get(
			"weapon_system"
		)
	)

	if typeof(
		weapon_system_value
	) != TYPE_OBJECT:
		return null

	if not is_instance_valid(
		weapon_system_value
	):
		return null

	return weapon_system_value as Object


func _spawn_fx(
	effect_type: String,
	position_value: Vector2,
	direction: Vector2,
	radius: float
) -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if not is_instance_valid(
		scene
	):
		return

	var fx: Node2D = (
		Milestone14FxScript.new()
		as Node2D
	)

	scene.add_child(
		fx
	)

	fx.global_position = (
		position_value
	)

	fx.call(
		"configure",
		effect_type,
		direction,
		radius
	)


func _request_gamefeel(
	shake: float,
	hit_stop: float,
	slow_scale: float
) -> void:
	var scene: Node = (
		get_tree().current_scene
	)

	if player.has_method(
		"add_camera_shake"
	):
		player.call(
			"add_camera_shake",
			shake
		)

	elif (
		is_instance_valid(
			scene
		)
		and scene.has_method(
			"request_camera_shake"
		)
	):
		scene.call(
			"request_camera_shake",
			shake
		)

	if (
		is_instance_valid(
			scene
		)
		and scene.has_method(
			"request_hit_stop"
		)
	):
		scene.call(
			"request_hit_stop",
			hit_stop,
			slow_scale
		)


func _has_property(
	target: Object,
	property_name: String
) -> bool:
	for property_data: Dictionary in target.get_property_list():
		if str(
			property_data.get(
				"name",
				""
			)
		) == property_name:
			return true

	return false
