class_name SwordSpecialHandler
extends RefCounted


static func process(
	controller: Node,
	pressed: bool
) -> void:
	if not pressed:
		return

	if bool(
		controller.get(
			"parry_active"
		)
	):
		return

	if float(
		controller.get(
			"parry_penalty_timer"
		)
	) > 0.0:
		return

	controller.call(
		"_start_parry"
	)
