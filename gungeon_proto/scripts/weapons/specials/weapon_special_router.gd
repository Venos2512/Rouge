class_name WeaponSpecialRouter
extends RefCounted


const SwordHandler = preload(
	"res://gungeon_proto/scripts/weapons/specials/sword_special_handler.gd"
)
const SpearHandler = preload(
	"res://gungeon_proto/scripts/weapons/specials/spear_special_handler.gd"
)
const HammerHandler = preload(
	"res://gungeon_proto/scripts/weapons/specials/hammer_special_handler.gd"
)


static func process(
	controller: Node,
	weapon_id: String,
	pressed: bool,
	released: bool,
	delta: float
) -> void:
	match weapon_id:
		"sword":
			SwordHandler.process(
				controller,
				pressed
			)

		"spear":
			SpearHandler.process(
				controller,
				pressed,
				released,
				delta
			)

		"hammer":
			HammerHandler.process(
				controller,
				pressed,
				released,
				delta
			)
