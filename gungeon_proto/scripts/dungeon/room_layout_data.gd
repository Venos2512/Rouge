class_name RoomLayoutData
extends Resource


@export_group("Identity")
@export var id: String = ""
@export var room_type: String = "combat"
@export var layout_id: int = 0

@export_group("Geometry")
@export var walls: Array = []
@export var props: Array = []

@export_group("Hazards")
@export var explosive_barrels: Array = []
@export var spike_traps: Array = []
@export var saw_traps: Array = []