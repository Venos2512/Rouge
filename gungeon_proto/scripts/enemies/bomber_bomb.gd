extends Node2D

const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)
const DamageResolverScript = preload(
	"res://gungeon_proto/scripts/combat/damage_resolver.gd"
)


const TRAVEL_DURATION: float = 0.40
const WARNING_DURATION: float = 0.55

const EXPLOSION_RADIUS: float = 72.0
const EXPLOSION_DAMAGE: int = 1

var start_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO

var travel_timer: float = 0.0
var warning_timer: float = 0.0
var arc_height: float = 0.0

var landed: bool = false
var configured: bool = false

# Warning VFX không cần redraw ở physics/display FPS.
# 30 Hz vẫn đủ mượt nhưng giảm đáng kể draw command
# khi nhiều Bomber có bomb cùng lúc.
var redraw_timer: float = 0.0
const REDRAW_INTERVAL: float = 1.0 / 30.0

var cached_player: Node2D = null

var exploded: bool = false
var explosion_visual_timer: float = 0.0

const EXPLOSION_VISUAL_DURATION: float = 0.12


func _ready() -> void:
	z_index = 30

	add_to_group(
		"enemy_projectiles"
	)

	add_to_group(
		"enemy_bombs"
	)

	queue_redraw()


func setup(
	from_position: Vector2,
	to_position: Vector2
) -> void:
	start_position = from_position
	target_position = to_position

	global_position = from_position

	travel_timer = 0.0
	warning_timer = WARNING_DURATION

	landed = false
	configured = true

	exploded = false
	explosion_visual_timer = 0.0

	redraw_timer = 0.0

	cached_player = (
		get_tree().get_first_node_in_group(
			"player"
		) as Node2D
	)

	queue_redraw()


func _process(
	delta: float
) -> void:
	if not configured:
		return

	if exploded:
		explosion_visual_timer = maxf(
			0.0,
			explosion_visual_timer - delta
		)

		redraw_timer -= delta

		if redraw_timer <= 0.0:
			redraw_timer = REDRAW_INTERVAL
			queue_redraw()

		if explosion_visual_timer <= 0.0:
			queue_free()

		return

	if not landed:
		_process_travel(
			delta
		)

		return

	warning_timer = maxf(
		0.0,
		warning_timer - delta
	)

	redraw_timer -= delta

	if redraw_timer <= 0.0:
		redraw_timer = REDRAW_INTERVAL
		queue_redraw()

	if warning_timer <= 0.0:
		_explode()


func _process_travel(
	delta: float
) -> void:
	travel_timer += delta

	var progress: float = clampf(
		travel_timer / TRAVEL_DURATION,
		0.0,
		1.0
	)

	global_position = start_position.lerp(
		target_position,
		progress
	)

	arc_height = sin(
		progress * PI
	) * 46.0

	queue_redraw()

	if progress < 1.0:
		return

	landed = true
	GameAudio.play(self, "bomb_bounce", 0.055)
	arc_height = 0.0

	global_position = target_position

	queue_redraw()


func _explode() -> void:
	if is_queued_for_deletion():
		return

	if exploded:
		return

	exploded = true
	GameAudio.play(self, "bomb_explosion", 0.035)
	explosion_visual_timer = EXPLOSION_VISUAL_DURATION
	redraw_timer = 0.0

	var explosion_position: Vector2 = (
		global_position
	)

	if is_instance_valid(
		cached_player
	):
		var explosion_distance_sq: float = (
			explosion_position.distance_squared_to(
				cached_player.global_position
			)
		)

		if explosion_distance_sq <= (
			EXPLOSION_RADIUS
			* EXPLOSION_RADIUS
		):
			DamageResolverScript.apply_simple_damage(
				cached_player, EXPLOSION_DAMAGE, &"fire", [&"explosion"],
				self, self, explosion_position
			)

	# Bomber blast kích hoạt chain reaction của thùng ngay lập tức.
	for prop_value: Node in get_tree().get_nodes_in_group("destructibles"):
		if not is_instance_valid(prop_value):
			continue
		if prop_value.is_queued_for_deletion():
			continue
		var prop: Node2D = prop_value as Node2D
		if not is_instance_valid(prop):
			continue
		if explosion_position.distance_to(prop.global_position) > EXPLOSION_RADIUS:
			continue
		if prop.has_method("trigger_from_explosion"):
			prop.call("trigger_from_explosion")

	var scene: Node = (
		get_tree().current_scene
	)

	if is_instance_valid(
		scene
	):
		# Không gọi spawn_room_fx("explosion") ở đây.
		# FX chung hiện tại khá nặng và gây frame spike
		# khi Bomber phát nổ.
		if scene.has_method(
			"request_camera_shake"
		):
			scene.call(
				"request_camera_shake",
				3.5
			)

	queue_redraw()


func _draw() -> void:
	if not configured:
		return

	if exploded:
		var explosion_progress: float = clampf(
			1.0
			- explosion_visual_timer
			/ EXPLOSION_VISUAL_DURATION,
			0.0,
			1.0
		)

		var explosion_scale: float = lerpf(
			0.30,
			1.0,
			explosion_progress
		)

		var explosion_alpha: float = (
			1.0
			- explosion_progress
		)

		draw_circle(
			Vector2.ZERO,
			EXPLOSION_RADIUS
				* explosion_scale,
			Color(
				1.0,
				0.18,
				0.04,
				0.20
				* explosion_alpha
			)
		)

		draw_circle(
			Vector2.ZERO,
			30.0
				* explosion_scale,
			Color(
				1.0,
				0.62,
				0.12,
				0.80
				* explosion_alpha
			)
		)

		draw_circle(
			Vector2.ZERO,
			13.0
				* explosion_scale,
			Color(
				1.0,
				0.92,
				0.58,
				explosion_alpha
			)
		)

		return

	if not landed:
		draw_circle(
			Vector2.ZERO,
			7.0,
			Color(
				0.08,
				0.07,
				0.06,
				0.28
			)
		)

		var bomb_offset: Vector2 = Vector2(
			0.0,
			-arc_height
		)

		draw_circle(
			bomb_offset,
			8.0,
			Color(
				0.12,
				0.12,
				0.14,
				1.0
			)
		)

		draw_circle(
			bomb_offset
			+ Vector2(
				3.0,
				-3.0
			),
			2.3,
			Color(
				1.0,
				0.55,
				0.16,
				1.0
			)
		)

		return

	var progress: float = clampf(
		1.0
		- warning_timer
		/ WARNING_DURATION,
		0.0,
		1.0
	)

	var pulse: float = (
		0.55
		+ sin(
			progress
			* TAU
			* 3.0
		)
		* 0.12
	)

	draw_circle(
		Vector2.ZERO,
		EXPLOSION_RADIUS,
		Color(
			0.92,
			0.18,
			0.08,
			0.10 + progress * 0.13
		)
	)

	draw_arc(
		Vector2.ZERO,
		EXPLOSION_RADIUS,
		0.0,
		TAU,
		24,
		Color(
			1.0,
			0.30,
			0.10,
			pulse
		),
		2.5
	)

	draw_circle(
		Vector2.ZERO,
		9.0,
		Color(
			0.12,
			0.12,
			0.14,
			1.0
		)
	)

	draw_circle(
		Vector2(
			3.0,
			-4.0
		),
		2.5,
		Color(
			1.0,
			0.42 + progress * 0.45,
			0.08,
			1.0
		)
	)
