extends Node


const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)


@export_group("Weapon Database")
@export var weapon_database: Resource
@export var weapon_resources: Array[Resource] = []


var weapons: Dictionary = {}

var ammo: Dictionary = {}

var reserve_ammo: Dictionary = {}

var unlocked: Dictionary = {}

# Weapon slots follow pickup order.
# Pistol is always the starting slot.
var weapon_order: Array[String] = [
	"pistol"
]

var current_weapon: String = "pistol"

var reloading: bool = false
var reload_timer: float = 0.0
var reload_weapon_id: String = ""


func _ready() -> void:
	_load_weapon_resources()


func _load_weapon_resources() -> void:
	weapons.clear()
	ammo.clear()
	reserve_ammo.clear()
	unlocked.clear()

	var source_resources: Array[Resource] = weapon_resources

	if is_instance_valid(
		weapon_database
	):
		var database_errors: Array = weapon_database.call(
			"validate"
		)

		for error_value: Variant in database_errors:
			push_error(
				str(error_value)
			)

		if database_errors.is_empty():
			source_resources = weapon_database.get(
				"weapons"
			)

	for resource: Resource in source_resources:
		if resource == null:
			continue

		if not resource.has_method(
			"to_runtime_dictionary"
		):
			continue

		var weapon: Dictionary = (
			resource.call(
				"to_runtime_dictionary"
			)
		)

		var weapon_id: String = str(
			weapon.get(
				"id",
				""
			)
		)

		if weapon_id.is_empty():
			continue

		if weapon.get(
			"attack_provider"
		) == null:
			push_error(
				"Weapon thiếu attack_provider: "
				+ weapon_id
			)
			continue

		weapons[weapon_id] = weapon

		var uses_ammo: bool = bool(
			weapon.get(
				"uses_ammo",
				true
			)
		)

		if not uses_ammo:
			ammo[weapon_id] = 0
			reserve_ammo[weapon_id] = 0
		else:
			ammo[weapon_id] = int(
				weapon.get(
					"mag_size",
					0
				)
			)

			reserve_ammo[weapon_id] = int(
				weapon.get(
					"reserve_ammo",
					0
				)
			)

		unlocked[weapon_id] = (
			weapon_id == "pistol"
		)

	# Pistol luôn là weapon khởi đầu.
	weapon_order.clear()

	if weapons.has(
		"pistol"
	):
		weapon_order.append(
			"pistol"
		)

		current_weapon = "pistol"


func _process(delta: float) -> void:
	if not reloading:
		return

	reload_timer -= delta

	if reload_timer <= 0.0:
		_finish_reload()


func get_current_weapon() -> Dictionary:
	return weapons[current_weapon]


func get_weapon(
	weapon_id: String
) -> Dictionary:
	return weapons.get(weapon_id, {})


func get_weapon_name() -> String:
	return str(weapons[current_weapon]["name"])


func get_ammo_in_mag() -> int:
	return int(ammo[current_weapon])


func get_reserve_ammo() -> int:
	return int(reserve_ammo[current_weapon])


func can_fire() -> bool:
	var weapon: Dictionary = weapons[current_weapon]

	if not bool(weapon.get("uses_ammo", true)):
		return not reloading

	return (
		not reloading
		and int(ammo[current_weapon]) > 0
	)


func consume_round() -> void:
	var weapon: Dictionary = weapons[current_weapon]

	if not bool(weapon.get("uses_ammo", true)):
		return

	if int(ammo[current_weapon]) <= 0:
		return

	ammo[current_weapon] = int(ammo[current_weapon]) - 1


func start_reload() -> void:
	if reloading:
		return

	var weapon: Dictionary = weapons[current_weapon]

	if not bool(weapon.get("uses_ammo", true)):
		return

	var mag_size: int = int(
		weapon["mag_size"]
	)

	var current_ammo: int = int(
		ammo[current_weapon]
	)

	var reserve: int = int(
		reserve_ammo[current_weapon]
	)

	if current_ammo >= mag_size:
		return

	if reserve <= 0:
		return

	reloading = true
	GameAudio.play(self, "gun_reload_start", 0.02)
	reload_weapon_id = current_weapon
	reload_timer = float(
		weapon["reload_time"]
	)


func _finish_reload() -> void:
	if reload_weapon_id == "":
		reloading = false
		return

	var weapon: Dictionary = weapons[
		reload_weapon_id
	]

	var mag_size: int = int(
		weapon["mag_size"]
	)

	var current_ammo: int = int(
		ammo[reload_weapon_id]
	)

	var reserve: int = int(
		reserve_ammo[reload_weapon_id]
	)

	var needed: int = mag_size - current_ammo
	var amount: int = mini(
		needed,
		reserve
	)

	ammo[reload_weapon_id] = (
		current_ammo
		+ amount
	)

	reserve_ammo[reload_weapon_id] = (
		reserve
		- amount
	)

	reloading = false
	GameAudio.play(self, "gun_reload_finish", 0.02)
	reload_timer = 0.0
	reload_weapon_id = ""


func unlock_and_equip(
	weapon_id: String
) -> void:
	if not weapons.has(weapon_id):
		return

	unlocked[weapon_id] = true

	# First pickup decides inventory slot order.
	if not weapon_order.has(weapon_id):
		weapon_order.append(weapon_id)

	equip_if_unlocked(
		weapon_id
	)


func equip_if_unlocked(
	weapon_id: String
) -> void:
	if not weapons.has(weapon_id):
		return

	if not bool(unlocked[weapon_id]):
		return

	if current_weapon == weapon_id:
		return

	reloading = false
	reload_timer = 0.0
	reload_weapon_id = ""

	current_weapon = weapon_id
	GameAudio.play(self, "weapon_switch", 0.025)


func equip_by_index(index: int) -> void:
	if index < 0:
		return

	if index >= weapon_order.size():
		return

	var weapon_id: String = weapon_order[index]

	equip_if_unlocked(
		weapon_id
	)


func cycle_weapon(direction: int) -> void:
	if weapon_order.size() <= 1:
		return

	var current_index: int = weapon_order.find(
		current_weapon
	)

	if current_index < 0:
		current_index = 0

	var next_index: int = current_index + direction

	if next_index < 0:
		next_index = weapon_order.size() - 1

	if next_index >= weapon_order.size():
		next_index = 0

	equip_by_index(
		next_index
	)


func get_weapon_order() -> Array[String]:
	return weapon_order
