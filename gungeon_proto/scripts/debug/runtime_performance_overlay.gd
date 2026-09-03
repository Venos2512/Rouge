class_name RuntimePerformanceOverlay
extends CanvasLayer


const SAMPLE_INTERVAL: float = 0.25
const SPIKE_THRESHOLD_MS: float = 25.0
const DIP_THRESHOLD_MS: float = 6.0
const HISTORY_SIZE: int = 12

var panel: PanelContainer
var metrics_label: Label
var visible_by_user: bool = true
var sample_elapsed: float = 0.0
var worst_frame_ms: float = 0.0
var spike_count: int = 0
var last_spike_ms: float = 0.0
var dip_count: int = 0
var last_dip_ms: float = 0.0
var phase_started_usec: Dictionary = {}
var phase_results_ms: Dictionary = {}
var recent_spikes: Array[float] = []


func _ready() -> void:
	layer = 4900
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _process(delta: float) -> void:
	var frame_ms: float = delta * 1000.0
	worst_frame_ms = maxf(worst_frame_ms, frame_ms)
	if frame_ms >= DIP_THRESHOLD_MS:
		dip_count += 1
		last_dip_ms = frame_ms
	if frame_ms >= SPIKE_THRESHOLD_MS:
		spike_count += 1
		last_spike_ms = frame_ms
		recent_spikes.push_front(frame_ms)
		if recent_spikes.size() > HISTORY_SIZE:
			recent_spikes.pop_back()

	if Input.is_key_pressed(KEY_F3) and not bool(get_meta("f3_down", false)):
		visible_by_user = not visible_by_user
		panel.visible = visible_by_user
	set_meta("f3_down", Input.is_key_pressed(KEY_F3))

	sample_elapsed += delta
	if sample_elapsed < SAMPLE_INTERVAL:
		return
	sample_elapsed = 0.0
	_refresh_text()


func begin_phase(phase_name: StringName) -> void:
	phase_started_usec[phase_name] = Time.get_ticks_usec()


func end_phase(phase_name: StringName) -> float:
	if not phase_started_usec.has(phase_name):
		return 0.0
	var elapsed_ms: float = float(Time.get_ticks_usec() - int(phase_started_usec[phase_name])) / 1000.0
	phase_started_usec.erase(phase_name)
	phase_results_ms[phase_name] = elapsed_ms
	return elapsed_ms


func reset_transition_metrics() -> void:
	phase_started_usec.clear()
	phase_results_ms.clear()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(12.0, 12.0)
	panel.custom_minimum_size = Vector2(310.0, 0.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	metrics_label = Label.new()
	metrics_label.add_theme_font_size_override("font_size", 13)
	metrics_label.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0))
	metrics_label.text = "PERFORMANCE MONITOR\nĐang lấy mẫu...\nF3: ẩn/hiện"
	panel.add_child(metrics_label)


func _refresh_text() -> void:
	if not is_instance_valid(metrics_label):
		return
	var fps: int = Engine.get_frames_per_second()
	var frame_ms: float = 1000.0 / maxf(float(fps), 1.0)
	var tree: SceneTree = get_tree()
	var node_count: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var object_count: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var memory_mb: float = float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
	var enemies: int = tree.get_node_count_in_group(&"enemies")
	var bullets: int = tree.get_node_count_in_group(&"enemy_bullets") + tree.get_node_count_in_group(&"player_bullets")
	var effects: int = tree.get_node_count_in_group(&"room_fx")
	var bombs: int = tree.get_node_count_in_group(&"enemy_bombs")
	var phase_text: String = _format_phases()
	metrics_label.text = (
		"PERFORMANCE  [F3 ẩn/hiện]\n"
		+ "FPS %d | %.2f ms | worst %.1f ms\n" % [fps, frame_ms, worst_frame_ms]
		+ "Dip >= %.0f ms: %d | last %.1f ms\n" % [DIP_THRESHOLD_MS, dip_count, last_dip_ms]
		+ "Spike >= %.0f ms: %d | last %.1f ms\n" % [SPIKE_THRESHOLD_MS, spike_count, last_spike_ms]
		+ "Node %d | Object %d | RAM %.1f MB\n" % [node_count, object_count, memory_mb]
		+ "Enemy %d | Bullet %d | Bomb %d | FX %d" % [enemies, bullets, bombs, effects]
		+ phase_text
	)
	worst_frame_ms = 0.0


func _format_phases() -> String:
	if phase_results_ms.is_empty():
		return ""
	var result: String = "\nROOM"
	for phase_name: Variant in phase_results_ms:
		result += " | %s %.1f" % [str(phase_name), float(phase_results_ms[phase_name])]
	return result + " ms"
