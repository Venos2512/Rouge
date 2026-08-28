class_name AudioDirector
extends Node


const SFX_ROOT := "res://gungeon_proto/assets/audio/sfx"
const MAX_ACTIVE_SFX := 32
const EVENT_COOLDOWN_SECONDS := 0.025

var streams_by_event: Dictionary = {}
var active_players: Array[Node] = []
var last_play_time_by_event: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("audio_director")
	_ensure_bus("SFX")
	_scan_directory(SFX_ROOT)


func play_sfx(
	event_name: String,
	world_position: Vector2 = Vector2.INF,
	pitch_variation: float = 0.04
) -> void:
	var variants: Array = streams_by_event.get(event_name, [])
	if variants.is_empty():
		return

	var now_msec: int = Time.get_ticks_msec()
	var previous_msec: int = int(
		last_play_time_by_event.get(event_name, -100000)
	)
	if now_msec - previous_msec < int(EVENT_COOLDOWN_SECONDS * 1000.0):
		return
	last_play_time_by_event[event_name] = now_msec

	_prune_players()
	if active_players.size() >= MAX_ACTIVE_SFX:
		var oldest: Node = active_players.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var stream: AudioStream = variants.pick_random() as AudioStream
	if not is_instance_valid(stream):
		return

	var player: Node
	if world_position != Vector2.INF:
		var spatial_player := AudioStreamPlayer2D.new()
		spatial_player.global_position = world_position
		spatial_player.max_distance = 900.0
		spatial_player.attenuation = 0.7
		player = spatial_player
	else:
		player = AudioStreamPlayer.new()

	player.set("stream", stream)
	player.set("bus", "SFX")
	player.set_meta("sfx_event", event_name)
	player.set(
		"pitch_scale",
		randf_range(
			1.0 - maxf(pitch_variation, 0.0),
			1.0 + maxf(pitch_variation, 0.0)
		)
	)
	add_child(player)
	active_players.append(player)
	player.connect("finished", _on_player_finished.bind(player))
	player.call("play")


func stop_sfx(event_name: String) -> void:
	for player: Node in active_players.duplicate():
		if not is_instance_valid(player):
			continue
		if str(player.get_meta("sfx_event", "")) == event_name:
			player.queue_free()
			active_players.erase(player)


func _scan_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		push_warning("Không thể đọc thư mục SFX: " + path)
		return

	for directory_name: String in directory.get_directories():
		_scan_directory(path.path_join(directory_name))

	for file_name: String in directory.get_files():
		if file_name.get_extension().to_lower() not in ["wav", "ogg", "mp3"]:
			continue

		var resource_path: String = path.path_join(file_name)
		var stream: AudioStream = load(resource_path) as AudioStream
		if not is_instance_valid(stream):
			continue

		var event_name: String = _base_event_name(
			file_name.get_basename()
		)
		if not streams_by_event.has(event_name):
			streams_by_event[event_name] = []
		streams_by_event[event_name].append(stream)


func _base_event_name(file_stem: String) -> String:
	var parts: PackedStringArray = file_stem.split("_")
	if parts.size() > 1 and parts[-1].is_valid_int():
		parts.remove_at(parts.size() - 1)
	return "_".join(parts)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)


func _prune_players() -> void:
	for player: Node in active_players.duplicate():
		if not is_instance_valid(player):
			active_players.erase(player)


func _on_player_finished(player: Node) -> void:
	active_players.erase(player)
	if is_instance_valid(player):
		player.queue_free()
