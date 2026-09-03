extends SceneTree


const MODEL_PATHS: PackedStringArray = [
	"res://gungeon_proto/assets/models/pet/animal-cat.fbx",
	"res://gungeon_proto/assets/models/pet/animal-dog.fbx",
	"res://gungeon_proto/assets/models/pet/animal-fox.fbx",
	"res://gungeon_proto/assets/models/pet/animal-bee.fbx",
	"res://gungeon_proto/assets/models/pet/animal-lion.fbx",
	"res://gungeon_proto/assets/models/pet/animal-polar.fbx",
	"res://gungeon_proto/assets/models/pet/animal-cow.fbx",
	"res://gungeon_proto/assets/models/pet/animal-crab.fbx",
	"res://gungeon_proto/assets/models/pet/animal-penguin.fbx",
	"res://gungeon_proto/assets/models/pet/animal-monkey.fbx",
	"res://gungeon_proto/assets/models/pet/animal-elephant.fbx",
	"res://gungeon_proto/assets/models/weapons/Blaster/blaster-a.fbx",
	"res://gungeon_proto/assets/models/weapons/Blaster/blaster-b.fbx",
	"res://gungeon_proto/assets/models/weapons/Blaster/blaster-f.fbx",
	"res://gungeon_proto/assets/models/weapons/Blaster/blaster-j.fbx",
	"res://gungeon_proto/assets/models/weapons/Blaster/blaster-k.fbx",
	"res://gungeon_proto/assets/models/weapons/Blaster/blaster-n.fbx",
	"res://gungeon_proto/assets/models/weapons/Blaster/blaster-r.fbx",
	"res://gungeon_proto/assets/models/weapons/Medieval/sword-a.fbx",
	"res://gungeon_proto/assets/models/weapons/Medieval/spear-a.fbx",
	"res://gungeon_proto/assets/models/weapons/Medieval/hammer-a.fbx",
	"res://gungeon_proto/assets/models/weapons/Medieval/shield-round-a.fbx",
	"res://gungeon_proto/assets/models/weapons/Blaster/grenade-a.fbx",
]
const AUTHORED_ENEMY_SCENES: PackedStringArray = [
	"res://gungeon_proto/scenes/enemies/chaser.tscn",
	"res://gungeon_proto/scenes/enemies/gunner.tscn",
	"res://gungeon_proto/scenes/enemies/spread.tscn",
	"res://gungeon_proto/scenes/enemies/elite.tscn",
	"res://gungeon_proto/scenes/enemies/shield.tscn",
	"res://gungeon_proto/scenes/enemies/charger.tscn",
	"res://gungeon_proto/scenes/enemies/suicide_bot.tscn",
	"res://gungeon_proto/scenes/enemies/bomber.tscn",
	"res://gungeon_proto/scenes/enemies/tactical_gunner.tscn",
	"res://gungeon_proto/scenes/enemies/bosses/boss.tscn",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failure_count := 0
	for path in MODEL_PATHS:
		var scene := load(path) as PackedScene
		if scene == null:
			push_error("MODEL_LOAD_FAILED %s" % path)
			failure_count += 1
			continue
		var instance := scene.instantiate() as Node3D
		root.add_child(instance)
		var bounds: AABB = _collect_bounds(instance, instance, Transform3D.IDENTITY)
		if bounds.size.length_squared() <= 0.001:
			push_error("MODEL_HAS_NO_VISIBLE_MESH %s" % path)
			failure_count += 1
		instance.free()
	for scene_path in AUTHORED_ENEMY_SCENES:
		var enemy_scene := load(scene_path) as PackedScene
		if enemy_scene == null:
			push_error("ENEMY_SCENE_LOAD_FAILED %s" % scene_path)
			failure_count += 1
			continue
		var enemy := enemy_scene.instantiate()
		var authored_visual := enemy.get_node_or_null("Visual3D") as Node3D
		if not is_instance_valid(authored_visual) or authored_visual.get_node_or_null("AnimalModel") == null:
			push_error("ENEMY_SCENE_HAS_NO_AUTHORED_VISUAL %s" % scene_path)
			failure_count += 1
		enemy.free()
	if failure_count == 0:
		print("MODEL_ASSET_INSPECTION_OK")
	quit(0 if failure_count == 0 else 1)


func _collect_bounds(root_node: Node3D, node: Node, accumulated: Transform3D) -> AABB:
	var node_transform := accumulated
	if node is Node3D and node != root_node:
		node_transform = accumulated * (node as Node3D).transform
	var found := false
	var result := AABB()
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh != null:
			result = node_transform * mesh_node.mesh.get_aabb()
			found = true
	for child in node.get_children():
		var child_bounds: AABB = _collect_bounds(root_node, child, node_transform)
		if child_bounds.size.length_squared() <= 0.0:
			continue
		result = result.merge(child_bounds) if found else child_bounds
		found = true
	return result
