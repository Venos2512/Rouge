class_name SpearSpecialHandler
extends RefCounted


static func process(
	controller: Node,
	pressed: bool,
	released: bool,
	delta: float
) -> void:
	if pressed:
		controller.call(
			"_start_spear_charge"
		)

	var charging: bool = bool(
		controller.get(
			"spear_charging"
		)
	)

	if charging:
		controller.call(
			"_update_spear_charge",
			delta
		)

	if (
		released
		and bool(
			controller.get(
				"spear_charging"
			)
		)
	):
		controller.call(
			"_release_spear"
		)
