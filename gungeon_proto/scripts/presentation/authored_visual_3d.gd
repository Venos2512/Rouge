@tool
extends Node3D


func _enter_tree() -> void:
	# Authored visual is visible while editing its mixed 2D/3D actor scene.
	# Runtime uses a duplicate owned by Planar3DPresenter, so the source copy
	# must stay hidden at the 3D origin.
	visible = Engine.is_editor_hint()
