class_name GameAudio
extends RefCounted


static func play(
	source: Node,
	event_name: String,
	pitch_variation: float = 0.04
) -> void:
	if not is_instance_valid(source):
		return

	var tree: SceneTree = source.get_tree()
	if not is_instance_valid(tree):
		return

	var director: Node = tree.get_first_node_in_group(
		"audio_director"
	)
	if not is_instance_valid(director):
		return

	var world_position := Vector2.INF
	if source is Node2D:
		world_position = (source as Node2D).global_position

	director.call(
		"play_sfx",
		event_name,
		world_position,
		pitch_variation
	)


static func stop(source: Node, event_name: String) -> void:
	if not is_instance_valid(source):
		return

	var director: Node = source.get_tree().get_first_node_in_group(
		"audio_director"
	)
	if is_instance_valid(director):
		director.call("stop_sfx", event_name)
