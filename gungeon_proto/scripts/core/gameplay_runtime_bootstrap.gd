extends Node


const EnemyCrowdServiceScript = preload(
	"res://gungeon_proto/scripts/enemies/enemy_crowd_service.gd"
)

const EnemyBulletPoolScript = preload(
	"res://gungeon_proto/scripts/weapons/projectiles/enemy_bullet.gd"
)

const EnemyWarmupScript = preload(
	"res://gungeon_proto/scripts/enemies/gunner.gd"
)

const TacticalGunnerWarmupScript = preload(
	"res://gungeon_proto/scripts/enemies/tactical_gunner.gd"
)

const BossWarmupScript = preload(
	"res://gungeon_proto/scripts/enemies/boss.gd"
)

const TacticalProjectileWarmupScript = preload(
	"res://gungeon_proto/scripts/enemies/tactical_gunner_projectile.gd"
)

const BomberBombWarmupScript = preload(
	"res://gungeon_proto/scripts/enemies/bomber_bomb.gd"
)

const EnemyBulletWarmupScript = preload(
	"res://gungeon_proto/scripts/weapons/projectiles/enemy_bullet.gd"
)


const ENEMY_BULLET_PREWARM_COUNT: int = 40


func initialize(
	host: Node
) -> void:
	if not is_instance_valid(
		host
	):
		return

	_ensure_enemy_crowd_service()

	_prewarm_enemy_bullet_pool(
		host
	)

	await _prewarm_gameplay_rendering(
		host
	)


func _ensure_enemy_crowd_service() -> void:
	if get_tree().get_first_node_in_group(
		"enemy_crowd_service"
	) != null:
		return

	var enemy_crowd_service: Node = (
		EnemyCrowdServiceScript.new()
	)

	enemy_crowd_service.name = (
		"EnemyCrowdService"
	)

	var parent_node: Node = get_parent()

	if not is_instance_valid(
		parent_node
	):
		return

	parent_node.add_child(
		enemy_crowd_service
	)


func _prewarm_enemy_bullet_pool(
	host: Node
) -> void:
	var existing_count: int = (
		get_tree().get_nodes_in_group(
			"enemy_bullet_pool"
		).size()
	)

	var needed: int = maxi(
		0,
		ENEMY_BULLET_PREWARM_COUNT
		- existing_count
	)

	for i: int in range(
		needed
	):
		var bullet: Node2D = (
			EnemyBulletPoolScript.new()
			as Node2D
		)

		if not is_instance_valid(
			bullet
		):
			continue

		host.add_child(
			bullet
		)


func _prewarm_gameplay_rendering(
	host: Node
) -> void:
	var loading_layer: CanvasLayer = (
		CanvasLayer.new()
	)

	loading_layer.layer = 5000

	host.add_child(
		loading_layer
	)

	var background: ColorRect = (
		ColorRect.new()
	)

	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background.color = Color(
		0.015,
		0.015,
		0.02,
		1.0
	)

	background.mouse_filter = (
		Control.MOUSE_FILTER_STOP
	)

	loading_layer.add_child(
		background
	)

	var loading_label: Label = Label.new()

	loading_label.text = "LOADING"

	loading_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	loading_label.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	loading_label.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	loading_label.add_theme_font_size_override(
		"font_size",
		18
	)

	loading_layer.add_child(
		loading_label
	)

	var warmup_root: Node2D = Node2D.new()

	warmup_root.name = "ColdStartWarmup"

	host.add_child(
		warmup_root
	)

	_add_warmup_actor(
		warmup_root,
		EnemyWarmupScript,
		Vector2(-120.0, 0.0)
	)

	_add_warmup_actor(
		warmup_root,
		TacticalGunnerWarmupScript,
		Vector2(-60.0, 0.0)
	)

	_add_warmup_actor(
		warmup_root,
		BossWarmupScript,
		Vector2.ZERO
	)

	_add_warmup_actor(
		warmup_root,
		TacticalProjectileWarmupScript,
		Vector2(60.0, 0.0)
	)

	_add_warmup_actor(
		warmup_root,
		EnemyBulletWarmupScript,
		Vector2(100.0, 0.0)
	)

	var bomb: Node2D = (
		_add_warmup_actor(
			warmup_root,
			BomberBombWarmupScript,
			Vector2(140.0, 0.0)
		)
	)

	if (
		is_instance_valid(
			bomb
		)
		and bomb.has_method(
			"setup"
		)
	):
		bomb.call(
			"setup",
			bomb.global_position,
			bomb.global_position
		)

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	if is_instance_valid(
		warmup_root
	):
		warmup_root.free()

	if is_instance_valid(
		loading_layer
	):
		loading_layer.free()


func _add_warmup_actor(
	root: Node2D,
	script_resource: Script,
	position_value: Vector2
) -> Node2D:
	if not is_instance_valid(
		script_resource
	):
		return null

	var actor: Node2D = (
		script_resource.new()
		as Node2D
	)

	if not is_instance_valid(
		actor
	):
		return null

	actor.process_mode = (
		Node.PROCESS_MODE_DISABLED
	)

	actor.position = position_value

	root.add_child(
		actor
	)

	return actor