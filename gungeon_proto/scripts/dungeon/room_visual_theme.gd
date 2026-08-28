class_name RoomVisualTheme
extends Resource


@export_group("World")
@export var world_background_texture: Texture2D
@export var world_background: Color = Color8(
	12,
	12,
	18
)

@export_group("Floor")
@export var floor_texture: Texture2D
@export var floor_default: Color = Color8(
	39,
	42,
	52
)

@export var floor_treasure: Color = Color8(
	49,
	45,
	39
)

@export var floor_elite: Color = Color8(
	50,
	38,
	35
)

@export var floor_boss: Color = Color8(
	45,
	30,
	37
)

@export var floor_shop: Color = Color8(
	31,
	48,
	46
)

@export_group("Terrain")
@export var floor_moss: Color = Color8(39, 57, 43)
@export var floor_ice: Color = Color8(39, 55, 68)
@export var floor_lava: Color = Color8(68, 39, 32)
@export var floor_void: Color = Color8(42, 34, 62)

@export_group("Grid")
@export var grid_color: Color = Color8(
	48,
	51,
	63
)

@export_group("Borders")
@export var outer_border_color: Color = Color8(
	102,
	91,
	84
)

@export var inner_border_color: Color = Color8(
	58,
	54,
	58
)

@export_group("Doors")
@export var door_locked_color: Color = Color8(
	112,
	54,
	45
)

@export var door_open_color: Color = Color8(
	225,
	184,
	78
)
