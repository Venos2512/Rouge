class_name WeaponData
extends Resource


@export var id: String = ""
@export var display_name: String = ""

@export_enum(
	"ranged",
	"melee"
)
var weapon_type: String = "ranged"

@export var automatic: bool = false
@export var attack_provider: Script
@export var uses_ammo: bool = true

@export_group("Presentation")
@export var hud_icon_id: String = "pistol"
@export var icon_texture: Texture2D
@export var pickup_color: Color = Color(0.82, 0.67, 0.25, 1.0)

@export_group("Combat")
@export var damage: int = 1
@export_enum("physical", "fire", "shock", "poison", "void")
var damage_type: String = "physical"
@export var fire_interval: float = 0.2
@export var reload_time: float = 0.85
@export var recoil: float = 0.0

@export_group("Ranged")
@export var magazine_size: int = 10
@export var reserve_ammo: int = 50
@export var bullet_speed: float = 520.0
@export var pellets: int = 1
@export var spread_deg: float = 0.0

@export_group("Explosive Projectile")
@export var projectile_lifetime: float = 1.1
@export var explosion_radius: float = 0.0
@export var explosion_knockback: float = 0.0

@export_group("Melee")
@export_enum(
	"none",
	"slash",
	"thrust",
	"smash"
)
var melee_style: String = "none"

@export var melee_range: float = 0.0
@export var melee_arc_deg: float = 0.0
@export var knockback: float = 0.0
@export var lunge: float = 0.0

@export_group("Meta")
@export var tags: Array[String] = []


func to_runtime_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": display_name,
		"type": weapon_type,
		"automatic": automatic,
		"attack_provider": attack_provider,
		"uses_ammo": uses_ammo,
		"hud_icon_id": hud_icon_id,
		"pickup_color": pickup_color,

		"damage": damage,
		"damage_type": damage_type,
		"fire_interval": fire_interval,
		"reload_time": reload_time,
		"recoil": recoil,

		# Giữ key cũ để player/combat hiện tại không bị vỡ.
		"mag_size": magazine_size,
		"magazine_size": magazine_size,
		"reserve_ammo": reserve_ammo,
		"bullet_speed": bullet_speed,
		"pellets": pellets,
		"spread_deg": spread_deg,
		"projectile_lifetime": projectile_lifetime,
		"explosion_radius": explosion_radius,
		"explosion_knockback": explosion_knockback,

		"melee_style": melee_style,
		"range": melee_range,
		"arc_deg": melee_arc_deg,
		"knockback": knockback,
		"lunge": lunge,

		"tags": tags.duplicate(),
		"synergy_tags": tags.duplicate(),
	}
