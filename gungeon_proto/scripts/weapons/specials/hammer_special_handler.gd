class_name HammerSpecialHandler
extends RefCounted


static func process(
	controller: Node,
	pressed: bool,
	released: bool,
	delta: float
) -> void:
	if pressed:
		controller.call(
			"_start_hammer_charge"
		)

	var charging: bool = bool(
		controller.get(
			"hammer_charging"
		)
	)

	if charging:
		controller.call(
			"_update_hammer_charge",
			delta
		)

	if (
		released
		and bool(
			controller.get(
				"hammer_charging"
			)
		)
	):
		controller.call(
			"_release_hammer"
		)
