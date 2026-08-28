extends Node

const GameInput = preload(
	"res://gungeon_proto/scripts/core/game_input.gd"
)


func _ready() -> void:
	GameInput.ensure_actions()
