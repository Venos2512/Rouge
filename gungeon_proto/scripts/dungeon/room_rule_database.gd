class_name RoomRuleDatabase
extends Resource


@export var rules: Array[Resource] = []


func get_rule(
	room_type: String
) -> Resource:
	for rule: Resource in rules:
		if rule == null:
			continue

		if str(
			rule.get(
				"room_type"
			)
		) == room_type:
			return rule

	return null