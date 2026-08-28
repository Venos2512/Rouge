extends CanvasLayer


@onready var minimap: Control = (
	get_node_or_null(
		"Minimap"
	) as Control
)

@onready var room_label: Label = (
	get_node_or_null(
		"RoomLabel"
	) as Label
)

@onready var boss_label: Label = (
	get_node_or_null(
		"BossLabel"
	) as Label
)

@onready var boss_bar: ProgressBar = (
	get_node_or_null(
		"BossBar"
	) as ProgressBar
)

@onready var gold_label: Label = (
	get_node_or_null(
		"GoldLabel"
	) as Label
)

@onready var health_bar: ProgressBar = $PlayerStatus/HealthBar
@onready var health_label: Label = $PlayerStatus/HealthLabel
@onready var weapon_hint: Label = $WeaponHint

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node
	if not is_instance_valid(player):
		return
	var hp := int(player.get("health"))
	var max_hp := maxi(1, int(player.get("max_health")))
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_label.text = "HP  %d / %d" % [hp, max_hp]


func update_room_state(
	rooms: Dictionary,
	current_room: Vector2i,
	room_cleared: bool,
	floor_number: int
) -> void:
	if is_instance_valid(
		minimap
	):
		if minimap.has_method(
			"set_dungeon_state"
		):
			minimap.call(
				"set_dungeon_state",
				rooms,
				current_room
			)

	if not is_instance_valid(
		room_label
	):
		return

	if not rooms.has(
		current_room
	):
		room_label.text = ""
		return

	var data: Dictionary = rooms[
		current_room
	]

	var room_type: String = str(
		data.get(
			"type",
			"combat"
		)
	).to_upper()

	var state_text: String = "OPEN"

	if not room_cleared:
		state_text = "LOCKED"

	room_label.text = (
		"FLOOR "
		+ str(floor_number)
		+ "  |  "
		+ room_type
		+ " ROOM "
		+ str(current_room)
		+ "\n"
		+ state_text
	)


func update_gold(
	player: Node
) -> void:
	var gold: int = 0

	if (
		is_instance_valid(
			player
		)
		and player.has_method(
			"get_gold"
		)
	):
		gold = int(
			player.call(
				"get_gold"
			)
		)

	update_gold_value(
		gold
	)


func update_gold_value(
	gold: int
) -> void:
	if not is_instance_valid(
		gold_label
	):
		return

	gold_label.text = (
		"GOLD  "
		+ str(gold)
	)


func update_boss(
	tree: SceneTree,
	floor_number: int
) -> void:
	update_boss_actor(
		tree.get_first_node_in_group(
			"boss"
		),
		floor_number
	)


func update_boss_actor(
	boss_value: Node,
	floor_number: int
) -> void:
	if not is_instance_valid(
		boss_bar
	):
		return

	if not is_instance_valid(
		boss_label
	):
		return

	if not is_instance_valid(
		boss_value
	):
		boss_bar.visible = false
		boss_label.visible = false
		return

	var max_hp: int = int(
		boss_value.get(
			"max_health"
		)
	)

	var hp: int = int(
		boss_value.get(
			"health"
		)
	)

	boss_bar.visible = true
	boss_label.visible = true

	boss_bar.max_value = float(
		max_hp
	)

	boss_bar.value = float(
		hp
	)

	boss_label.text = (
		"FLOOR "
		+ str(floor_number)
		+ " BOSS"
	)
