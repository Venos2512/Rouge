class_name SwordComboAttackProvider
extends "res://gungeon_proto/scripts/weapons/attacks/weapon_attack_provider.gd"


const MeleeAttackSystemScript = preload(
	"res://gungeon_proto/scripts/weapons/melee/melee_attack_system.gd"
)
const Milestone14CombatScript = preload(
	"res://gungeon_proto/scripts/weapons/melee/milestone14_combat.gd"
)
const GameAudio = preload(
	"res://gungeon_proto/scripts/audio/game_audio.gd"
)


var player: Node2D
var aim_direction: Vector2 = Vector2.RIGHT
var sword_combo_step: int = 0
var sword_combo_reset_timer: float = 0.0
var sword_combo_reset_duration: float = 0.86
var sword_swing_timer: float = 0.0
var sword_swing_duration: float = 0.14
var sword_attack_direction: Vector2 = Vector2.RIGHT
var sword_swing_from_angle: float = -0.95
var sword_swing_to_angle: float = 0.95
var pending_hit_timer: float = 0.0
var pending_hit_weapon: Dictionary = {}
var pending_hit_direction: Vector2 = Vector2.RIGHT


func tick(
	delta: float
) -> void:
	if pending_hit_timer > 0.0:
		pending_hit_timer = maxf(0.0, pending_hit_timer - delta)
		if pending_hit_timer <= 0.0:
			_commit_pending_hit()
	sword_swing_timer = maxf(
		0.0,
		sword_swing_timer - delta
	)
	sword_combo_reset_timer = maxf(
		0.0,
		sword_combo_reset_timer - delta
	)

	if sword_combo_reset_timer <= 0.0:
		sword_combo_step = 0


func perform_attack(
	player_node: Node2D,
	weapon: Dictionary,
	aim_direction_value: Vector2,
	_weapon_system: Node,
	_god_mode: bool
) -> Dictionary:
	player = player_node
	aim_direction = aim_direction_value
	Milestone14CombatScript.record_attack_tags(
		player,
		weapon
	)

	var interval: float = _swing_sword(
		weapon
	)

	return {
		"performed": true,
		"cooldown": interval,
		"recoil": 0.0,
		"muzzle_flash": 0.0,
		"sword_combo_step": sword_combo_step if sword_combo_step > 0 else 3,
		"sword_swing_duration": sword_swing_duration,
		"sword_swing_from_angle": sword_swing_from_angle,
		"sword_swing_to_angle": sword_swing_to_angle,
		"sword_attack_direction": sword_attack_direction,
	}


func _swing_sword(
	weapon: Dictionary
) -> float:
	var combo_step: int = sword_combo_step + 1

	if combo_step > 3:
		combo_step = 1

	sword_combo_step = combo_step
	GameAudio.play(player, "sword_swing", 0.045)
	if combo_step == 3:
		GameAudio.play(player, "sword_combo_finish", 0.02)
	sword_combo_reset_timer = (
		sword_combo_reset_duration
	)

	sword_attack_direction = aim_direction

	if (
		sword_attack_direction.length_squared()
		<= 0.001
	):
		sword_attack_direction = Vector2.RIGHT

	sword_attack_direction = (
		sword_attack_direction.normalized()
	)

	var combo_weapon: Dictionary = (
		weapon.duplicate(true)
	)

	var base_damage: int = int(
		weapon.get(
			"damage",
			3
		)
	)

	var base_range: float = float(
		weapon.get(
			"range",
			55.0
		)
	)

	var base_arc: float = float(
		weapon.get(
			"arc_deg",
			100.0
		)
	)

	var base_knockback: float = float(
		weapon.get(
			"knockback",
			165.0
		)
	)

	var base_lunge: float = float(
		weapon.get(
			"lunge",
			6.0
		)
	)

	var attack_interval: float = 0.24

	match combo_step:
		1:
			combo_weapon["range"] = base_range
			combo_weapon["arc_deg"] = (
				base_arc * 0.95
			)
			combo_weapon["damage"] = base_damage
			combo_weapon["knockback"] = (
				base_knockback * 0.85
			)
			combo_weapon["lunge"] = maxf(
				base_lunge,
				8.0
			)

			combo_weapon["camera_shake"] = 2.5
			combo_weapon["hit_stop_duration"] = 0.035
			combo_weapon["hit_stop_scale"] = 0.14

			sword_swing_duration = 0.34
			sword_swing_from_angle = -0.95
			sword_swing_to_angle = 0.88

			attack_interval = 0.36

		2:
			combo_weapon["range"] = (
				base_range + 3.0
			)
			combo_weapon["arc_deg"] = (
				base_arc * 1.05
			)
			combo_weapon["damage"] = base_damage
			combo_weapon["knockback"] = (
				base_knockback * 1.05
			)
			combo_weapon["lunge"] = maxf(
				base_lunge,
				10.0
			)

			combo_weapon["camera_shake"] = 3.5
			combo_weapon["hit_stop_duration"] = 0.045
			combo_weapon["hit_stop_scale"] = 0.12

			sword_swing_duration = 0.37
			sword_swing_from_angle = 0.95
			sword_swing_to_angle = -0.92

			attack_interval = 0.39

		3:
			combo_weapon["range"] = (
				base_range + 7.0
			)
			combo_weapon["arc_deg"] = (
				base_arc * 1.25
			)
			combo_weapon["damage"] = (
				base_damage + 1
			)
			combo_weapon["knockback"] = (
				base_knockback * 1.75
			)
			combo_weapon["lunge"] = maxf(
				base_lunge,
				15.0
			)

			combo_weapon["camera_shake"] = 6.0
			combo_weapon["hit_stop_duration"] = 0.075
			combo_weapon["hit_stop_scale"] = 0.08

			sword_swing_duration = 0.52
			sword_swing_from_angle = -1.12
			sword_swing_to_angle = 1.18

			attack_interval = 0.56

	# The actual hit lands when the blade enters the fast active sweep. Keeping
	# damage out of the anticipation frames makes contact match the animation.
	pending_hit_weapon = combo_weapon
	pending_hit_direction = sword_attack_direction
	pending_hit_timer = sword_swing_duration * 0.34

	sword_swing_timer = sword_swing_duration

	if combo_step == 3:
		sword_combo_step = 0


	return attack_interval


func _commit_pending_hit() -> void:
	if not is_instance_valid(player) or pending_hit_weapon.is_empty():
		pending_hit_weapon.clear()
		return
	MeleeAttackSystemScript.perform_attack(
		player,
		pending_hit_weapon,
		pending_hit_direction
	)
	pending_hit_weapon.clear()
	player.call("_clamp_to_room")


func draw_held_weapon(
	player_node: Node2D,
	_weapon: Dictionary,
	current_aim_direction: Vector2
) -> void:
	var direction: Vector2 = current_aim_direction

	if sword_swing_timer > 0.0:
		var progress: float = 1.0 - sword_swing_timer / sword_swing_duration
		var swing_angle: float = lerpf(
			sword_swing_from_angle,
			sword_swing_to_angle,
			progress
		)
		direction = sword_attack_direction.rotated(swing_angle)
		var current_angle: float = sword_attack_direction.angle() + swing_angle
		var trail_start: float = current_angle - 0.55
		player_node.draw_arc(
			Vector2.ZERO, 30.0, trail_start, current_angle, 14,
			Color(0.75, 0.90, 1.0, 0.48), 5.0
		)
		player_node.draw_arc(
			Vector2.ZERO, 25.0, trail_start - 0.10, current_angle, 12,
			Color(1.0, 0.88, 0.45, 0.28), 2.0
		)

	var handle_start: Vector2 = direction * 5.0
	var blade_start: Vector2 = direction * 10.0
	var tip: Vector2 = direction * 34.0
	var guard_direction := Vector2(-direction.y, direction.x)
	player_node.draw_line(handle_start, blade_start, Color8(118, 77, 45), 5.0)
	player_node.draw_line(
		blade_start - guard_direction * 5.0,
		blade_start + guard_direction * 5.0,
		Color8(225, 180, 65),
		3.0
	)
	player_node.draw_line(blade_start, tip, Color8(80, 88, 100), 6.0)
	player_node.draw_line(blade_start, tip, Color8(220, 230, 238), 3.0)
