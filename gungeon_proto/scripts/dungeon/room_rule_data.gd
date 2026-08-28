class_name RoomRuleData
extends Resource


@export_group("Identity")
@export var room_type: String = "combat"

@export_group("Room State")
@export var auto_cleared: bool = false
@export var enemy_count_override: int = -1

@export_group("Encounter")
@export_enum(
	"none",
	"normal",
	"elite",
	"boss"
)
var encounter_mode: String = "normal"

@export_group("Reward")
@export_enum(
	"none",
	"start_loadout",
	"shop",
	"chest",
	"priority_weapon_or_chest",
	"boss_chest_exit"
)
var reward_mode: String = "none"

@export var chest_source: String = "normal"
@export var chest_position: Vector2 = Vector2.ZERO

@export var weapon_rewards: Array = []

@export var spawn_floor_exit: bool = false
@export var floor_exit_position: Vector2 = Vector2.ZERO